"""Bounded map programs and script cursors on production 68k instructions.
Usage: python tests/phase2_events_scripts.py DLL game.hunk bench.hunk
"""
import ctypes,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_resources import run_pure

def words(*v):return struct.pack('>'+str(len(v))+'H',*(x&65535 for x in v))
def synthetic_map(program=words(0),animation=words(0),event=2):
    grid=116;poly=grid+8192;points=poly+32;anim=points+2;names=anim+len(animation);end=names+8
    b=bytearray(struct.pack('>5I',grid,poly,points,anim,names)+struct.pack('>24I',*([end]*24)))
    b.extend(words(-1,0)*2048);b.extend(bytes(32));b.extend(words(0));b.extend(animation);b.extend(bytes(8));b.extend(words(0))
    struct.pack_into('>I',b,16+event*4,len(b));b.extend(program)
    return bytes(b)
def register(c,b):
    ptr=0x300020;c.put(ptr,b);c.w32(c.addr('memlist'),0x300000)
    for off,v in [(0,0),(4,len(b)+32),(8,32),(16,len(b))]:c.w32(0x300000+off,v)
    c.set(A0,ptr);c.dll.test_guard(ptr+len(b),ptr+len(b)+64,3)
    return ptr
def tests(dll,path,cpu):
    count=0
    def check(fn,b,valid):
        nonlocal count
        c=CPU(dll,path,cpu);register(c,b);assert (run_pure(c,fn)==0)==valid,(fn,b[-20:].hex());count+=1
    for stream in [words(0),words(1,0,0,0,0,0,0),words(2,0,0),words(3,0,0,0,0,0),words(4,0,23,-1,0),words(5,0,159,0),words(6,0,1,0,0,0)]:
        check('g2validate_map',synthetic_map(stream),True)
    for stream in [words(7,0),words(65535,0),words(1,24,0,0,0,0,0),words(2,1,0),words(4,24,-1,0),words(4,0,0),words(5,0,160,0),words(6,0,0,1,0,0),words(6,0,33,1,0,0),words(6,0,1,1,1,0)]:
        check('g2validate_map',synthetic_map(stream),False)
    for stream in [words(1,0,0,0,0,0),words(2,0),words(3,0,0,0,0),words(4,0),words(5,0),words(6,0,1,0)]:
        check('g2validate_map',synthetic_map(stream),False)
    check('g2validate_map',synthetic_map(words(3,0,0,0,0,0),event=1),False)
    for event_number,valid in [(24,True),(25,False),(65535,True)]:
        b=bytearray(synthetic_map());poly=struct.unpack_from('>I',b,4)[0];struct.pack_into('>H',b,poly+30,event_number)
        check('g2validate_map',b,valid)
    for record,valid in [(words(2,0,0,0,0),True),(words(2,158,2,2,0),True),(words(1,0,1,1,0),False),(words(161,0,1,1,0),False),(words(2,159,1,1,0),False),(words(2,0,1),False)]:
        check('g2validate_map',synthetic_map(animation=record),valid)
    # Every repository map is checked on every emulated CPU, with an EOF guard.
    for file in sorted((Path(__file__).parents[1]/'source/maps').iterdir()):
        check('g2validate_map',file.read_bytes(),True)
    scripts=[(b'done_',True),(b'; comment without EOL',False),(b'play_map\ndone_\n',True),(b'PLAY_map\r\nTEXT_hello\r\nDONE_\r\n',True),(b'play_map\rdone_\r',True),(b'wait_\nloop_\n',True),(b'loop_\n',False),(b'rest_marker\nloop_\n',False),(b'xxxx_\ndone_\n',False),(b'play map\ndone_\n',False),(b'play_\ndone_\n',False),(b'pict_'+b'a'*51+b'\ndone_\n',False),(b'tile_'+b'a'*32+b'\ndone_\n',False),(b'text_'+b'a'*64+b'\ndone_\n',False),(b'play_'+b'a'*64+b'\ndone_\n',False),(b'draw_parameter\ndone_\n',False),(b'play_map',False)]
    for n in range(5):scripts.append((b'play_'[:n],False))
    for b,valid in scripts:check('g2validate_script',b,valid)
    for text,valid in [(b'a'*63,True),(b'a'*8+b' '+b'a'*54,False),(b'a'*23+b' '+b'a'*23,True),(b'a'*41+b'\\b',False),(b'\\'*20+b'a',True),(b'\\'*21+b'a',False),(b'a'*40+b'\\b',True)]:
        check('g2validate_script',b'text_'+text+b'\ndone_',valid)
    for b in [b'text_question?\ndone_',b'text_under_score\ndone_']:
        check('g2validate_script',b,False)
    c=CPU(dll,path,cpu);io=FileDOS(c,(Path(__file__).parents[1]/'source/misc/script').read_bytes());ptr=c.run('loadfile')
    c.set(A0,ptr);assert run_pure(c,'g2validate_script')==0
    c.set(A0,ptr);c.run('g2v190i_parse_script');assert c.r16(c.addr('g2v190i_level_count'))==21;count+=1
    # Execute the actual parser + bounded copy for all line endings.
    for ending in [b'\n',b'\r',b'\r\n']:
        c=CPU(dll,path,cpu);ptr=register(c,b'TEXT_hello'+ending+b'done_');c.w32(c.addr('script'),ptr);c.w32(c.addr('scriptat'),ptr)
        assert run_pure(c,'g2script_next_command')==int.from_bytes(b'text','big')
        c.set(A1,c.addr('text'));assert run_pure(c,'fetchrest')==5
        assert c.bytes(c.addr('text'),6)==b'hello\0' and c.r32(c.addr('scriptat'))==ptr+10+len(ending)
        assert run_pure(c,'g2script_next_command')==int.from_bytes(b'done','big');count+=1
    # Scanner must neither peek beyond short headers nor accept truncated names.
    for b in [b'',b'P',b'PLAY',b'play_unterminated',b'; comment',b'play_one\nplay_two\rdone_']:
        c=CPU(dll,path,cpu);ptr=register(c,b);c.run('g2v190i_parse_script')
        assert c.r16(c.addr('g2v190i_level_count'))==(2 if b.startswith(b'play_one') else 0);count+=1
    # Pool exhaustion used to continue with stale a0. The operand is consumed.
    c=CPU(dll,path,cpu);c.put(0x290000,words(0,0));c.set(A6,0x290000);c.set(A0,0x2a0000)
    c.put(0x2a0000,bytes([0x55])*64);c.run('exec_opendoor')
    assert c.bytes(0x2a0000,64)==bytes([0x55])*64 and c.get(A6)==0x290004;count+=1
    c=CPU(dll,path,cpu);c.set(D0,0);c.run('execevent');count+=1
    print(Path(path).name,'CPU',cpu,':',count,'event/script instruction cases passed')
    return count
if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
    total=sum(tests(dll,path,cpu) for path in sys.argv[2:] for cpu in [4,6,9])
    print(total,'event/script cases passed; EOF memory guards enabled')
