"""Structural checks only: MED sequencing, synth commands and DMA stay unaudited.
Usage: python tests/phase2_med.py DLL game.hunk bench.hunk
"""
import ctypes,sys,struct
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register
from phase2_resources import run_pure

def tests(dll,path,cpu):
    count=0
    root=Path(__file__).parents[1]/'source'
    for file in [root/'sfxs/med1',root/'sfxs/med2']:
        blob=file.read_bytes();song=struct.unpack_from('>I',blob,8)[0]
        blocks=struct.unpack_from('>I',blob,16)[0];block=struct.unpack_from('>I',blob,blocks)[0]
        samples=struct.unpack_from('>I',blob,24)[0];sample=struct.unpack_from('>I',blob,samples)[0]
        exp=struct.unpack_from('>I',blob,32)[0]
        changes=[(None,0,True),(0,b'MMD2',False),(4,len(blob)+1,False),(8,0,False),(8,53,False),(8,len(blob)-2,False),(16,len(blob),False),(blocks,len(blob)-1,False),(block,17,False),(block+2,65535,False),(song+504,0,False),(song+504,256,False),(song+506,0,False),(song+506,257,False),(song+508,255,False),(song+787,64,False),(samples,len(blob)-4,False),(sample,0xffffffff,False),(exp,len(blob)-52,False),(exp+52,52,False),(exp,0,True)]
        for offset,value,valid in changes:
            b=bytearray(blob)
            if offset is not None:
                if isinstance(value,bytes):b[offset:offset+len(value)]=value
                else:
                    fmt='B' if offset in [song+508,song+787] else 'H' if offset in [block,block+2,song+504,song+506] else 'I'
                    struct.pack_into('>'+fmt,b,offset,value)
            c=CPU(dll,path,cpu);register(c,b)
            assert (run_pure(c,'g2validate_med')==0)==valid,(file.name,offset,value);count+=1
        # A cyclic nextmod chain must terminate with rejection, not spin.
        b=bytearray(blob+blob[:52]);struct.pack_into('>I',b,4,len(b))
        struct.pack_into('>I',b,exp,len(blob));b[len(blob):len(blob)+4]=b'MCN1'
        c=CPU(dll,path,cpu);register(c,b);assert run_pure(c,'g2validate_med')==0xffffffff;count+=1
    for size in [0,1,51,52]:
        c=CPU(dll,path,cpu);register(c,bytes(size));assert run_pure(c,'g2validate_med')==0xffffffff;count+=1
    # Exercise both block encodings, optional structures and relative synth
    # wave pointers. No synthesis program or Paula DMA is executed here.
    for version in [0,1]:
        for kind in [0,-1,-2]:
            b=bytearray(1300);b[:4]=b'MMD'+str(version).encode()
            struct.pack_into('>III',b,4,len(b),52,0);struct.pack_into('>I',b,16,840);struct.pack_into('>I',b,24,868)
            struct.pack_into('>HH',b,52+504,1,1);b[52+787]=1
            struct.pack_into('>I',b,840,844)
            if version:struct.pack_into('>HH',b,844,4,0)
            else:b[844:846]=b'\4\0'
            struct.pack_into('>I',b,868,872);struct.pack_into('>Ih',b,872,4,kind)
            if kind<0:
                struct.pack_into('>HH',b,872+14,1,1);struct.pack_into('>H',b,872+20,1)
                struct.pack_into('>I',b,872+278,282)
                if kind==-1:struct.pack_into('>H',b,872+282,1)
                else:struct.pack_into('>Ih',b,872+282,4,0)
            c=CPU(dll,path,cpu);register(c,b);assert run_pure(c,'g2validate_med')==0;count+=1
            if kind<0:
                for off,value in [(872+14,129),(872+16,129),(872+20,0),(872+20,65),(872+278,0xffffffff)]:
                    bad=bytearray(b);struct.pack_into('>I' if off==872+278 else '>H',bad,off,value)
                    c=CPU(dll,path,cpu);register(c,bad);assert run_pure(c,'g2validate_med')==0xffffffff;count+=1
    for size in [1,40,41,42]:
        c=CPU(dll,path,cpu);ptr=register(c,bytes(size));c.w32(c.addr('planar_c2p'),ptr)
        c.w32(c.addr('g2menu_entry_sp'),STACK);c.hook('exittoos',lambda c:c.ret());c.run('g2require_external_c2p')
        assert bool(c.r16(c.addr('g2fatal_state')))==(size<42);count+=1
    print(Path(path).name,'CPU',cpu,':',count,'MED structure/C2P entry extent cases passed')
    return count

if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
    print(sum(tests(dll,path,cpu) for path in sys.argv[2:] for cpu in [4,6,9]),'cases passed; music playback is NOT certified')
