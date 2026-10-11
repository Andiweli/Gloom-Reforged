"""Execute the assembled production routines, with explicit OS call stubs.
Usage: python tests/asm_regression.py path/to/musashi_test.dll game.hunk bench.hunk
Build hunks with vasm -Fhunkexe -kick1hunks -devpac -m68020 -nocase.
This tests 68k instructions/register conventions, not AmigaOS or real hardware.
"""
import ctypes, struct, sys
from pathlib import Path
BASE, STOP, STACK = 0x10000, 0x7000, 0x800000
EXEC, DOS, GRAPHICS, INTUITION = 0x8000, 0x9000, 0xa000, 0xb000
D0, D1, D2, D3, D4, D5, D6, D7 = range(8)
A0, A1, A2, A3, A4, A5, A6, A7, PC, SR = range(8,18)

def load_hunk(path):
    b=Path(path).read_bytes(); pos=0
    def word():
        nonlocal pos
        v=struct.unpack_from('>I',b,pos)[0];pos+=4;return v
    assert word()==1011 and word()==0
    assert (word(),word(),word())==(1,0,0), 'single CODE hunk required'
    total=word()&0x3fffffff
    assert word()==1001
    n=word()*4; code=bytearray(b[pos:pos+n]);pos+=n
    code.extend(bytes(total*4-n));symbols={}
    while pos<len(b):
        kind=word()&0x3fffffff
        if kind==1004:
            while True:
                count=word()
                if not count: break
                assert word()==0
                for _ in range(count):
                    off=word();value=struct.unpack_from('>I',code,off)[0]
                    struct.pack_into('>I',code,off,value+BASE)
        elif kind==1008:
            while True:
                n=word()
                if not n: break
                name=b[pos:pos+n*4].rstrip(b'\0').decode('latin1');pos+=n*4
                symbols[name]=BASE+word()
        elif kind==1010: break
        elif kind==1009: pos+=word()*4
        else: raise AssertionError(f'unsupported hunk {kind}; use -kick1hunks')
    return code,symbols

class CPU:
    def __init__(self,dll,path,cpu=4):
        self.dll=dll;self.code,self.syms=load_hunk(path);dll.test_memory.restype=ctypes.POINTER(ctypes.c_ubyte)
        dll.test_reset(cpu);self.mem=dll.test_memory();self.put(BASE,self.code)
        self.w32(4,EXEC); self.w32(self.addr('dosbase'),DOS); self.w32(self.addr('grbase'),GRAPHICS);self.w32(self.addr('int'),INTUITION)
        self.hooks={};self.calls=[]
    def addr(self,n): return self.syms[n]
    def put(self,a,b): ctypes.memmove(ctypes.addressof(self.mem.contents)+a,bytes(b),len(b))
    def bytes(self,a,n): return ctypes.string_at(ctypes.addressof(self.mem.contents)+a,n)
    def w16(self,a,v): self.put(a,struct.pack('>H',v&0xffff))
    def w32(self,a,v): self.put(a,struct.pack('>I',v&0xffffffff))
    def r16(self,a): return struct.unpack('>H',self.bytes(a,2))[0]
    def r32(self,a): return struct.unpack('>I',self.bytes(a,4))[0]
    def set(self,r,v): self.dll.test_set(r,v&0xffffffff)
    def get(self,r): return self.dll.test_get(r)&0xffffffff
    def hook(self,n,callback): self.hooks[self.addr(n) if isinstance(n,str) else n]=callback
    def ret(self,value=0,clobber=True):
        self.set(D0,value)
        if clobber:
            self.set(D1,0xdead0001);self.set(A0,0xdead0008);self.set(A1,0xdead0009)
        sp=self.get(A7);self.set(PC,self.r32(sp));self.set(A7,sp+4)
    def run(self,n,limit=500000):
        self.set(A7,STACK);self.w32(STACK,STOP);self.set(PC,self.addr(n))
        for _ in range(limit):
            pc=self.get(PC)
            if pc==STOP:
                assert self.get(A7)==STACK+4, 'stack imbalance'
                assert self.dll.test_faults()==0, 'out of mapped memory'
                return self.get(D0)
            if pc in self.hooks: self.hooks[pc](self)
            elif pc==self.addr('decrm')+32:
                assert self.dll.test_until(self.r32(self.get(A7)),20000000), 'decrunch instruction limit'
            elif n in ['g2validate_map','g2validate_anim','g2validate_texture','g2validate_iff']:
                assert self.dll.test_until(STOP,20000000), 'validator instruction limit'
            else:
                assert BASE<=pc<BASE+len(self.code), f'unstubbed PC {pc:#x}'
                self.dll.test_step()
        raise AssertionError(f'instruction limit at {self.get(PC):#x}')

class FileDOS:
    def __init__(self,c,data,fault=None,capacity=None):
        self.data=data;self.pos=0;self.seeks=0;self.reads=0;self.allocs=0;self.frees=0;self.closes=0;self.fault=fault
        c.put(0x280000,b'test.bin\0');c.set(A0,0x280000);c.set(D1,1)
        if capacity is not None:c.set(A1,0x350000);c.set(D2,capacity)
        for off,method in [(-30,self.open),(-66,self.seek),(-42,self.read),(-36,self.close)]:c.hook(DOS+off,method)
        c.hook(EXEC-198,self.alloc);c.hook(EXEC-210,self.free)
        c.hook('flushc',lambda c:c.ret(c.get(D0),clobber=False))
    def open(self,c):c.ret(0 if self.fault=='open' else 1)
    def seek(self,c):
        self.seeks+=1
        if self.fault=='seek'+str(self.seeks):c.ret(-1);return
        old=self.pos;self.pos=len(self.data) if c.get(D3)==1 else 0;c.ret(old)
    def read(self,c):
        self.reads+=1;n=c.get(D3);chunk=self.data[self.pos:self.pos+n]
        if self.fault=='read'+str(self.reads):chunk=chunk[:-1]
        if self.fault=='read_error'+str(self.reads):c.ret(-1);return
        c.put(c.get(D2),chunk);self.pos+=len(chunk);c.ret(len(chunk))
    def close(self,c):self.closes+=1;c.ret(0 if self.fault=='close' else 1)
    def alloc(self,c):self.allocs+=1;c.ret(0 if self.fault=='alloc' else 0x300000)
    def free(self,c):self.frees+=1;assert c.get(A1)==0x300000;c.ret()


def tests(dll,path,cpu_type):
    count=0
    def new(): return CPU(dll,path,cpu_type)
    for size,flags,answers,expected in [(64,4,[0,0x300000],0x300020),(64,2,[0],0),(0x7fffffff,4,[],0),(0xffffffff,4,[],0)]:
        c=new();calls=[]
        def alloc(c):
            calls.append((c.get(D0),c.get(D1)));c.ret(answers[len(calls)-1])
        c.hook(EXEC-198,alloc);c.set(D0,size);c.set(D1,flags)
        assert c.run('allocmem_')==expected
        if expected:
            assert calls==[(96,4),(96,1)], calls
            assert c.r32(c.addr('memlist'))==0x300000 and c.r32(0x300004)==96
        else: assert c.r32(c.addr('memlist'))==0
        count+=1
    for extra in [0x7fffffff,0xffffffff]:
        c=new();c.set(D0,1);c.set(D1,4);c.set(D2,extra)
        assert c.run('allocmem2_')==0;count+=1
    for initialized in [0,1]:
        c=new();calls=[];c.w16(c.addr('g2exit_vb_owned'),initialized)
        c.hook(EXEC-174,lambda c:(calls.append('remove'),c.ret()))
        c.run('finitvbint');c.run('finitvbint')
        assert calls==(['remove'] if initialized else []) and c.r16(c.addr('g2exit_vb_owned'))==0;count+=1
    for dbi,window,screen in [(0,0,0),(0,0,0x330000),(0,0x320000,0x330000),(0x310000,0x320000,0x330000)]:
        c=new();calls=[];c.w16(c.addr('os'),0xffff)
        for n,v in [('dbufinfo',dbi),('oswindow',window),('screen',screen)]:c.w32(c.addr(n),v)
        def record(name,reg):
            def callback(c):calls.append((name,c.get(reg)));c.ret(1)
            return callback
        c.hook(GRAPHICS-0x3cc,record('dbi',A1));c.hook(INTUITION-72,record('window',A0));c.hook(INTUITION-66,record('screen',A0))
        c.hook('g2p96_display_shutdown',lambda c:c.ret())
        c.run('finitdisplay');c.run('finitdisplay')
        assert calls==[(n,v) for n,v in [('dbi',dbi),('window',window),('screen',screen)] if v], calls
        count+=1
    for colors in [0,1,31,32,33,64,128,255,256]:
        c=new();c.w32(c.addr('coplist'),0x300000);c.put(0x300000,bytes([0x55])*8192)
        palette=struct.pack('>'+str(colors*2)+'H',*range(colors*2));c.put(0x310000,palette)
        c.set(D0,colors);c.set(A1,0x310000);c.run('pokepal_aga')
        assert c.get(A1)==0x310000+colors*4, (colors,c.get(A1))
        assert c.bytes(0x302000,32)==bytes(32);count+=1
    for state in ['hardware','ring_full']:
        c=new();c.w16(0xdff018,0x8000 if state=='hardware' else 0x1234);c.w16(c.addr('rbfcnt'),128 if state=='ring_full' else 0)
        c.run('rbf',limit=100)
        assert c.r16(0xdff09c)==0x0800 and c.r16(c.addr('g2serial_overruns'))==1;count+=1
    for data in [b'abcde',bytes(range(256))*2]:
        for fault in [None,'open','seek1','seek2','seek3','read1','read_error1','alloc','read2','read_error2','close']:
            c=new();io=FileDOS(c,data,fault);result=c.run('loadfile')
            assert bool(result)==(fault is None),(fault,result)
            assert io.closes==(0 if fault=='open' else 1),(fault,io.closes)
            if result:assert result==0x300020 and c.bytes(result,len(data))==data
            else:assert c.r32(c.addr('memlist'))==0,(fault,'failed allocation still linked')
            if fault in ['read2','read_error2','close']:assert io.frees==1
            count+=1
    for capacity in [4,5,128]:
        c=new();io=FileDOS(c,b'abcde',capacity=capacity)
        result=c.run('loadfileabs');assert bool(result)==(capacity>=5)
        assert io.allocs==0 and io.closes==1
        if result:assert result==0x350000 and c.bytes(result,5)==b'abcde'
        count+=1
    c=new();start=c.addr('g2embed_bigfont2_crm');packed=c.bytes(start,c.addr('g2embed_bigfont2_crm_end')-start)
    for data in [b'CrM2',b'CrM!'+bytes(10),b'CrM2'+struct.pack('>HII',0,64,0xfffffff0)+bytes(6)]:
        c=new();io=FileDOS(c,data);assert c.run('loadfile')==0 and io.closes==1 and io.allocs==0;count+=1
    c=new();io=FileDOS(c,packed,capacity=8192);assert c.run('loadfileabs')==0 and io.allocs==0;count+=1
    c=new();c.hook(EXEC-198,lambda c:c.ret(0x300000));c.hook('flushc',lambda c:c.ret(c.get(D0),clobber=False))
    c.set(A0,c.addr('g2embed_bigfont2_crm'));c.set(A1,c.addr('g2embed_bigfont2_crm_end'));c.set(D1,4)
    result=c.run('g2embed_decrunch_asset');expected=c.bytes(result,struct.unpack_from('>I',packed,6)[0])
    c=new();io=FileDOS(c,packed);result=c.run('loadfile')
    assert result and c.bytes(result,len(expected))==expected and io.closes==1
    assert io.reads==2 and io.pos==len(packed);count+=1
    for routine in ['g2p96_gameplay_dbuf_flip','g2p96_gameplay_dbuf_suspend_primary']:
        c=new();c.w16(c.addr('p96gameplay_dbuf_active'),0xffff);c.w16(c.addr('p96gameplay_dbuf_current'),1)
        for n,v in [('p96gameplay_grbase',GRAPHICS),('p96gameplay_intbase',INTUITION),('p96winprobe_screen_ptr',0x330000),('p96gameplay_dbuf_sb0',0x310000),('p96gameplay_dbuf_sb1',0x320000)]:c.w32(c.addr(n),v)
        c.w32(0x310000,0x340000);c.w16(c.addr('p96gameplay_dbuf_draw'),1)
        for fn in ['g2p96_gameplay_dbuf_wait_safe','g2p96_gameplay_dbuf_wait_disp','g2p96_force_hide_screen_title','g2p96_gameplay_clear_bitmap_a2','g2p96_gameplay_dbuf_restore_rport_original']:c.hook(fn,lambda c:c.ret(-1))
        for off in [-228,-270]:c.hook(GRAPHICS+off,lambda c:c.ret())
        seen=[]
        def change(c):seen.append(c.get(A1));c.ret(int(len(seen)==3))
        c.hook(INTUITION-780,change);c.run(routine)
        assert seen==[0x320000 if routine.endswith('flip') else 0x310000]*3,seen;count+=1
    c=new();events=[]
    def wait(kind):
        def cb(c):events.append(kind);c.ret(-1 if events.count(kind)==3 else 0)
        return cb
    c.hook('g2p96_gameplay_dbuf_wait_safe',wait('safe'));c.hook('g2p96_gameplay_dbuf_wait_disp',wait('disp'))
    c.hook('g2p96_gameplay_dbuf_free_partial',lambda c:(events.append('free'),c.ret()))
    c.run('g2p96_gameplay_dbuf_free');assert events==['safe']*3+['disp']*3+['free'],events;count+=1
    def payload(data):
        c=new();io=FileDOS(c,data);ptr=c.run('loadfile');assert ptr
        c.set(A0,ptr);return c,ptr
    valid_iff=struct.pack('>HHHHI',320,1,1,0,0)+b'\xd9\x01'
    for data,valid in [(valid_iff,True),(valid_iff[:-1],False),(valid_iff[:12]+b'\xd8\x01',False),(valid_iff[:12]+b'\x28'+bytes(41),False),(valid_iff[:12]+b'\x80',False),(struct.pack('>HHHHI',0,1,1,0,0),False),(struct.pack('>HHHHI',320,1,9,0,0),False)]:
        c,ptr=payload(data);assert (c.run('g2validate_iff')==0)==valid;count+=1
    anim=struct.pack('>HHHHIIhhhhBHH',0,1,1,1,25,16,0,0,1,1,1,1,0x123)
    for pos,replacement in [(None,None),(0,b'\x00\x10'),(2,b'\0\0'),(8,b'\xff'*4),(12,b'\xff'*4),(20,b'\0\0'),(25,b'\0\0')]:
        data=anim if pos is None else anim[:pos]+replacement+anim[pos+len(replacement):]
        c,ptr=payload(data);assert (c.run('g2validate_anim')==0)==(pos is None),(pos,'anim');count+=1
    texture=struct.pack('>I',4164)+bytes(4160)+struct.pack('>HH',1,0x123)
    for data,valid in [(texture,True),(texture[:-1],False),(struct.pack('>I',4163)+texture[4:],False),(struct.pack('>I',0xffffffff)+texture[4:],False)]:
        c,ptr=payload(data);assert (c.run('g2validate_texture')==0)==valid;count+=1
    c=new();c.put(c.addr('textures'),bytes([0x55])*640);c.run('g2clear_texture_slots');assert c.bytes(c.addr('textures'),640)==bytes(640);count+=1
    # Empty first screen must leave the second in texture slot 20, and compact
    # screens publish only real columns. Exercise the actual mapping routine.
    c=new();c.put(0x280000,b'\0one\0'+bytes(6));c.w32(c.addr('map_txts'),0x280000)
    c.put(0x300020,texture);c.w32(c.addr('memlist'),0x300000)
    for off,v in [(4,len(texture)+32),(8,32),(16,len(texture))]:c.w32(0x300000+off,v)
    c.hook('loadfile',lambda c:c.ret(0x300020));c.hook('addpal',lambda c:c.ret(clobber=False));c.hook('remap',lambda c:c.ret(clobber=False))
    c.run('loadtxts')
    assert c.r32(c.addr('textures')+80)==0x300024
    assert c.bytes(c.addr('textures'),80)==bytes(80) and c.bytes(c.addr('textures')+84,640-84)==bytes(640-84);count+=1
    c.run('loadtxts');assert c.r32(c.addr('textures')+80)==0x300024;count+=1
    print(Path(path).name, 'CPU',cpu_type,':',count,'instruction-level cases passed')
    return count

def asset_tests(dll,path):
    root=Path(__file__).resolve().parents[1];counts={}
    for folder,fn in [('maps','g2validate_map'),('txts','g2validate_texture'),('objs','g2validate_anim'),('pics','g2validate_iff'),('pics_ehb','g2validate_iff')]:
        for file in sorted((root/'source'/folder).iterdir()):
            if file.name.endswith('.pal') or file.name.startswith(('floor','roof')):continue
            c=CPU(dll,path);io=FileDOS(c,file.read_bytes());ptr=c.run('loadfile');assert ptr,file
            c.set(A0,ptr);assert c.run(fn)==0,(file,fn)
            assert io.pos==len(file.read_bytes()) and io.closes==1
            counts[folder]=counts.get(folder,0)+1
    for n in ['bullet'+str(x) for x in range(1,6)]+['sparks'+str(x) for x in range(1,6)]:
        c=CPU(dll,path);c.set(A0,c.addr(n));assert c.run('g2validate_anim')==0,n
    print(Path(path).name,'retail/compiled resource fixtures:',counts,'plus 10 builtins')
    return sum(counts.values())+10

if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).resolve()));total=0
    for path in sys.argv[2:]:
        for cpu in [4,6,9]:total+=tests(dll,path,cpu)
        total+=asset_tests(dll,path)
    print(total,'cases passed; AmigaOS calls were stubbed')
