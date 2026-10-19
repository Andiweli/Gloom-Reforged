"""Actual 68k cold resource guards and interrupted AmigaDOS replacements.
Usage: python tests/phase2_palettes.py DLL game.hunk bench.hunk
AmigaDOS is modelled explicitly; these are not filesystem/hardware tests.
"""
import ctypes,sys
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register,words,synthetic_map
from phase2_resources import run_pure

def guarded(c,fn):
    c.w32(c.addr('g2menu_entry_sp'),STACK)
    c.hook('exittoos',lambda c:c.ret())
    c.run(fn)
    return c.r16(c.addr('g2fatal_state'))==0
def tests(dll,path,cpu):
    count=0
    for p in sorted((Path(__file__).parents[1]/'source/sfxs').glob('*.bin')):
        c=CPU(dll,path,cpu);register(c,p.read_bytes());assert run_pure(c,'g2validate_sfx')==0;count+=1
    for data,valid in [(b'',False),(words(320,1),False),(words(320,1)+b'xx',True),(words(320,0)+bytes(131071),False),(words(320,0)+bytes(131072),True)]:
        c=CPU(dll,path,cpu);register(c,data);assert (run_pure(c,'g2validate_sfx')==0)==valid;count+=1
    c=CPU(dll,path,cpu);c.set(A0,0);c.run('playsfx');count+=1
    for w,h,valid in [(1,1,True),(2,32767,True),(3,16384,False),(300,120,False),(32767,1,True),(32768,1,False),(1,32768,False)]:
        pixels=w*h;pal=24+pixels
        b=struct.pack('>4HI',0,1,w,h,pal)+struct.pack('>I4H',16,0,0,w,h)+bytes(pixels)+words(1,0x123)
        c=CPU(dll,path,cpu);register(c,b);assert (run_pure(c,'g2validate_anim')==0)==valid;count+=1
    for slot,minimum in [('panel',48),('gunpic',5)]:
        c=CPU(dll,path,cpu)
        if slot=='panel':
            io=FileDOS(c,(Path(__file__).parents[1]/'source/misc/smallfont2.bin').read_bytes());ptr=c.run('loadfile')
            n=c.r32(c.r32(c.addr('memlist'))+16);original=c.bytes(ptr,n)
        else:
            blob=c.bytes(c.addr('g2embed_gun'),c.addr('g2embed_gun_end')-c.addr('g2embed_gun'))
            io=FileDOS(c,blob);ptr=c.run('loadfile');original=c.bytes(ptr,c.r32(c.r32(c.addr('memlist'))+16))
        for changed in [False,True]:
            b=bytearray(original)
            if changed:struct.pack_into('>HH',b,0,0,minimum-1)
            c=CPU(dll,path,cpu);ptr=register(c,b);c.set(D0,ptr);c.set(A3,c.addr(slot))
            assert guarded(c,'g2validate_loaded_slot')==(not changed),(slot,changed,b[:16].hex());count+=1
    for p in sorted((Path(__file__).parents[1]/'source/objs').iterdir()):
        if p.name.endswith('2'):continue
        for changed in [False,True]:
            c=CPU(dll,path,cpu);b=bytearray(p.read_bytes())
            if changed:struct.pack_into('>H',b,2,struct.unpack_from('>H',b,2)[0]-1)
            register(c,b);c.set(A2,c.addr(p.name))
            assert guarded(c,'g2require_actor_shape')== (not changed),p.name;count+=1
    c=CPU(dll,path,cpu);io=FileDOS(c,(Path(__file__).parents[1]/'source/misc/bigfont2.bin').read_bytes());ptr=c.run('loadfile')
    n=c.r32(c.r32(c.addr('memlist'))+16);font=c.bytes(ptr,n)
    for offset,value,valid in [(None,None,True),(0,0xffffffff,False),(4,7,False),(4,0xffffffff,False),(164+0,0xffffffff,False),(164+4,0,False),(164+6,0,False),(164+8,0,False),(164+8,9,False)]:
        c=CPU(dll,path,cpu);b=bytearray(font)
        if offset is not None:struct.pack_into('>I' if offset in [0,4,164] else '>H',b,offset,value)
        register(c,b);c.set(D7,40);assert (run_pure(c,'g2validate_blit_shapes')==0)==valid;count+=1
    for offset,value in [(164+6,(11<<6)|2),(3444,2),(164+8,7)]:
        c=CPU(dll,path,cpu);b=bytearray(font);struct.pack_into('>H',b,offset,value)
        c.w16(c.addr('aga'),0)
        register(c,b);c.set(D7,40);assert run_pure(c,'g2validate_blit_shapes')==0xffffffff,(offset,value);count+=1
    for size in [0,1,63,64,1023,1024]:
        for aga in [0,65535]:
            c=CPU(dll,path,cpu);ptr=register(c,bytes(size));c.w16(c.addr('aga'),aga)
            c.set(D0,ptr);c.set(A3,c.addr('planar_palette'))
            assert guarded(c,'g2validate_loaded_slot')==(size>=(1024 if aga else 64));count+=1
    for size in [4095,4096]:
        c=CPU(dll,path,cpu);ptr=register(c,bytes(size));c.set(D0,ptr);c.set(A3,c.addr('planar_remap'))
        assert guarded(c,'g2validate_loaded_slot')==(size==4096);count+=1
    # Picture palette count comes from validated depth and backend, not 256.
    for depth in [1,6,7,8]:
        for aga in [0,65535]:
            colors=min(1<<depth,256 if aga else 32);needed=colors*(4 if aga else 2)
            for shortage in [0,1]:
                c=CPU(dll,path,cpu);ptr=register(c,bytes(needed-shortage));c.w16(c.addr('aga'),aga)
                # Registered second allocation contains one bounded ByteRun1 row per plane.
                b=struct.pack('>HHHHI',8,1,depth,0,0)+b'\0\0'*depth
                c.put(0x320020,b);c.w32(0x300000,0x320000)
                for off,v in [(0,0),(4,len(b)+32),(8,32),(16,len(b))]:c.w32(0x320000+off,v)
                c.set(A0,0x320020);c.set(A1,ptr)
                assert guarded(c,'g2require_picture_palette')==(shortage==0);count+=1
    for b,valid in [(bytes(16384),False),(bytes(16384)+words(0),False),(bytes(16384)+words(1,0x123),True),(bytes(16384)+words(255)+bytes(510),True),(bytes(16384)+words(256)+bytes(512),False)]:
        c=CPU(dll,path,cpu);register(c,b);assert guarded(c,'g2require_tile')==valid;count+=1
    for size in [4160,8319,8320]:
        c=CPU(dll,path,cpu);ptr=register(c,bytes(size));c.set(A1,ptr)
        assert guarded(c,'g2require_defender_texture')==(size>=8320);count+=1
    # addpal receives an interior pointer; count, source extent and pooled
    # destination capacity are all checked before a new colour is written.
    for palette,initial,valid in [(words(0),1,False),(words(1),1,False),(words(1,0x123),1,True),(words(1,0x123),256,False),(words(1,0x123),257,False),(words(1,0x123),-1,False)]:
        c=CPU(dll,path,cpu);ptr=register(c,b'xxxx'+palette);c.set(A0,ptr+4)
        c.w32(c.addr('map_rgbs'),0x350000);c.put(0x350000,words(-1)*257);c.w32(c.addr('map_rgbsat'),0x350000+initial*2)
        c.w32(c.addr('maptable'),0x360000);dll.test_guard(0x350200,0x350240,2)
        assert guarded(c,'addpal')==valid;count+=1
    # A framed map still must not publish a wall/event/animation NULL column.
    for b in [synthetic_map(words(5,0,0,0)),synthetic_map(animation=words(2,0,1,1,0))]:
        for available in [False,True]:
            c=CPU(dll,path,cpu);ptr=register(c,b);c.w32(c.addr('map_map'),ptr)
            if available:
                for i in range(160):c.w32(c.addr('textures')+i*4,0x350000)
            assert guarded(c,'g2require_map_textures')==available;count+=1
    print(Path(path).name,'CPU',cpu,':',count,'palette/resource fault-injection cases passed')
    return count
if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
    total=sum(tests(dll,path,cpu) for path in sys.argv[2:] for cpu in [4,6,9])
    print(total,'palette/resource instruction cases passed; OS/filesystem calls modelled')
