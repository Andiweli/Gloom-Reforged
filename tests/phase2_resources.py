"""Phase 2 tests on actual 68k code; OS calls are explicit stubs.

Usage: python tests/phase2_resources.py DLL baseline-game.hunk game.hunk bench.hunk
The baseline hunk is d825e91, including its original binary CrM decoder.
"""
import ctypes,random,struct,sys
from pathlib import Path
from asm_regression import *

def field(bits,value,n):bits.extend((value>>i)&1 for i in range(n))
def packed(magic,bits,size):
    # The original reverse bit reader seeds a long, then refills backwards.
    n=max(2,(len(bits)+15)//16);bits=bits+[0]*(16*n-len(bits))
    words=[sum(bits[i*16+j]<<j for j in range(16)) for i in range(n)]
    payload=b''.join(struct.pack('>H',w) for w in reversed(words[2:]))+struct.pack('>I',words[0]|words[1]<<16)+struct.pack('>H',16)
    return magic+struct.pack('>HII',0,size,len(payload))+payload
def fast_literal(data):
    bits=[]
    for b in data[::-1]:field(bits,1,1);field(bits,b,8)
    return packed(b'CrM!',bits,len(data))
def fast_reference(distance=1,size=4):
    bits=[]
    for v,n in [(1,1),(65,8),(0,1),(0,1),(1,1),(1,1),(0,1),(distance,5)]:field(bits,v,n)
    return packed(b'CrM!',bits,size)
def lzh_literal(size=3):
    bits=[]
    for v,n in [(1,4),(1,1),(321,9),(1,4),(1,1),(0,4),(size-1,16)]:field(bits,v,n)
    for _ in range(size):field(bits,0,1)
    field(bits,0,1)
    return packed(b'CrM2',bits,size)
def lzh_reference(first_match=False):
    bits=[]
    # Two length codes (00 literal A, 01 length-three), one distance code.
    for v,n in [(2,4),(0,1),(2,2),(321,9),(0,9),(1,4),(1,1),(0,4),(0 if first_match else 1,16)]:field(bits,v,n)
    if not first_match:bits.extend([0,0])
    bits.extend([0,1,0,0,0]) # match, distance symbol 0, distance bit 0, no block
    return packed(b'CrM2',bits,3 if first_match else 4)

def run_pure(c,name):
    c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,c.addr(name) if isinstance(name,str) else name)
    assert c.dll.test_until(STOP,20000000),'instruction budget / guarded memory access'
    assert c.get(A7)==STACK+4,'stack imbalance'
    assert c.dll.test_faults()==0,'out-of-resource memory access'
    return c.get(D0)

def crm_tests(dll,baseline,path,cpu):
    cases=0
    def check(data,expected_status=None,expected=None,inplace=False,capacity=None,src=0x280000,dst=0x350000):
        nonlocal cases
        c=CPU(dll,path,cpu);out=struct.unpack_from('>I',data,6)[0] if len(data)>=14 else 32
        if capacity is None:capacity=out if 0<out<1000000 else 64
        if inplace:dst=src+14+struct.unpack_from('>H',data,4)[0]
        c.put(src,data);c.set(A0,src);c.set(A1,dst);c.set(D0,len(data));c.set(D1,capacity)
        for r in [D2,D3,D4,D5,D6,D7,A2,A3,A4,A5,A6]:c.set(r,0x11220000+r)
        saved=[c.get(r) for r in range(1,15)]
        dll.test_guard(src-32,src,1)
        if not inplace:dll.test_guard(src+len(data),src+len(data)+32,1)
        dll.test_guard(dst-32,dst,2);dll.test_guard(dst+capacity,dst+capacity+32,2)
        result=run_pure(c,'g2crm_decode_checked')
        assert result in [0,0xffffffff]
        if expected_status is not None:assert result==expected_status,(data[:14].hex(),result)
        assert [c.get(r) for r in range(1,15)]==saved,'callee-saved register drift'
        if expected is not None:assert result==0 and c.bytes(dst,len(expected))==expected
        cases+=1
        return result
    zero_tail=b'CrM!'+struct.pack('>HII',0,1,6)+struct.pack('>IH',0x00830000,0)
    positives=[(fast_literal(b'ABC'),b'ABC'),(zero_tail,b'A'),(fast_reference(),b'AAAA'),(lzh_literal(),b'AAA'),(lzh_reference(),b'AAAA')]
    c=CPU(dll,baseline,cpu)
    for name in ['g2embed_bigfont2_crm','g2embed_smallfont2_crm','g2embed_palette8_crm','g2embed_remap8_crm']:
        blob=c.bytes(c.addr(name),c.addr(name+'_end')-c.addr(name));positives.append((blob,None))
    root=Path(__file__).resolve().parents[1]
    for folder in ['maps','txts','objs','misc','pics','pics_ehb','sfxs']:
        for p in sorted((root/'source'/folder).glob('*')):
            if p.is_file() and p.read_bytes()[:4] in [b'CrM!',b'CrM2']:positives.append((p.read_bytes(),None))
    for blob,expected in positives:
        c=CPU(dll,baseline,cpu);c.put(0x280000,blob);c.set(A0,0x280000);c.set(A1,0x350000)
        run_pure(c,c.addr('decrm')+32)
        original=c.bytes(0x350000,struct.unpack_from('>I',blob,6)[0])
        if expected is not None:assert original==expected
        for inplace in [False,True]:check(blob,0,original,inplace)
        c=CPU(dll,path,cpu);io=FileDOS(c,blob);result=c.run('loadfile');assert result and c.bytes(result,len(original))==original
        assert io.closes==1 and c.r32(c.r32(c.addr('memlist'))+16)==len(original);cases+=1
    invalid=[b'',b'CrM2',b'CrM!'+bytes(9),b'bad!'+bytes(20)]
    for magic in [b'CrM!',b'CrM2']:
        for out,length,tail in [(0,6,16),(0xffffffff,6,16),(64,5,16),(64,7,16),(64,6,0),(64,6,17),(64,6,65535)]:
            invalid.append(magic+struct.pack('>HII',0,out,length)+bytes(4)+struct.pack('>H',tail))
    invalid.extend([fast_reference(0),fast_reference(1,3),lzh_reference(True)])
    too_few=bytearray(fast_literal(b'ABC'));struct.pack_into('>H',too_few,len(too_few)-2,1);invalid.append(bytes(too_few))
    for blob in invalid:check(blob,0xffffffff)
    check(fast_literal(b'ABC'),0xffffffff,capacity=2)
    rng=random.Random(0xF004)
    rejected=0
    for i in range(180):
        magic=b'CrM!' if i%2 else b'CrM2';payload=bytes(rng.randrange(256) for _ in range(rng.randrange(6,65)))
        payload=payload[:-2]+struct.pack('>H',rng.randrange(1,17))
        blob=magic+struct.pack('>HII',0,rng.randrange(1,65),len(payload))+payload
        rejected+=check(blob)==0xffffffff
    assert rejected>150
    print(Path(path).name,'CPU',cpu,':',cases,'bounded CrM cases,',rejected,'random structures rejected')
    return cases

if __name__=='__main__':
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
    total=0
    for path in sys.argv[3:]:
        for cpu in [4,6,9]:total+=crm_tests(dll,sys.argv[2],path,cpu)
    print(total,'Phase 2 instruction cases passed; memory guard regions enabled')
