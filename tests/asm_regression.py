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
            else:
                assert BASE<=pc<BASE+len(self.code), f'unstubbed PC {pc:#x}'
                self.dll.test_step()
        raise AssertionError(f'instruction limit at {self.get(PC):#x}')

def tests(dll,path,cpu_type):
    count=0
    def new(): return CPU(dll,path,cpu_type)
    for size,flags,answers,expected in [(64,4,[0,0x300000],0x300010),(64,2,[0],0),(0x7fffffff,4,[],0),(0xffffffff,4,[],0)]:
        c=new();calls=[]
        def alloc(c):
            calls.append((c.get(D0),c.get(D1)));c.ret(answers[len(calls)-1])
        c.hook(EXEC-198,alloc);c.set(D0,size);c.set(D1,flags)
        assert c.run('allocmem_')==expected
        if expected:
            assert calls==[(80,4),(80,1)], calls
            assert c.r32(c.addr('memlist'))==0x300000 and c.r32(0x300004)==80
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
    print(Path(path).name, 'CPU',cpu_type,':',count,'instruction-level cases passed')
    return count

if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).resolve()));total=0
    for path in sys.argv[2:]:
        for cpu in [4,6,9]:total+=tests(dll,path,cpu)
    print(total,'cases passed; AmigaOS calls were stubbed')
