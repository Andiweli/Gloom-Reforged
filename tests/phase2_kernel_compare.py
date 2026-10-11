"""Compare assembled hot spans with Phase 1. Normalise absolute relocations;
when PC displacements change, verify opcodes/layout and symbol+offset targets.
Usage: python tests/phase2_kernel_compare.py DLL old-game new-game old-bench new-bench
"""
import struct,sys,hashlib,ctypes,re,bisect
from pathlib import Path
from asm_regression import load_hunk,BASE

def semantic(code,syms,labels,start,end):
    dll.test_reset(9);dll.test_memory.restype=ctypes.POINTER(ctypes.c_ubyte)
    ctypes.memmove(ctypes.addressof(dll.test_memory().contents)+BASE,bytes(code),len(code))
    anchors=sorted((syms[n],n) for n in labels)
    addresses=[a for a,_ in anchors]
    def target(hexadecimal):
        a=int(hexadecimal,16);i=bisect.bisect_right(addresses,a)-1
        if i<0 or a>=BASE+len(code):return '$'+hexadecimal
        at,name=anchors[i];return name+'+'+str(a-at)
    result=[];pc=syms[start];buffer=ctypes.create_string_buffer(256)
    while pc<syms[end]:
        size=dll.test_disassemble(pc,buffer);text=buffer.value.decode()
        # The disassembler reports the PC base target before the index in a
        # comment. Preserve its symbol+offset while removing only displacement.
        if ',PC' in text and re.search(r'; \(\$[0-9a-f]+\)',text):
            text=re.sub(r'\([-\$0-9a-f]+,PC', '(PC',text)
            text=re.sub(r'; \(\$([0-9a-f]+)\)',lambda m:'; ('+target(m[1])+')',text)
        elif re.match(r'^(?:b(?:ra|sr|cc|cs|eq|ge|gt|hi|le|ls|lt|mi|ne|pl|vc|vs)|db\w+)\s',text):
            text=re.sub(r'\$([0-9a-f]+)$',lambda m:target(m[1]),text)
        result.append((size,text,bytes(code[pc-BASE:pc-BASE+size])));pc+=size
    assert pc==syms[end],(start,end,hex(pc),hex(syms[end]))
    return result

def relocations(path):
    b=Path(path).read_bytes();pos=32+struct.unpack_from('>I',b,28)[0]*4;result=[]
    def word():
        nonlocal pos
        value=struct.unpack_from('>I',b,pos)[0];pos+=4;return value
    while pos<len(b):
        kind=word()&0x3fffffff
        if kind==1004:
            while True:
                n=word()
                if not n:break
                assert word()==0
                result.extend(word() for _ in range(n))
        elif kind==1008:
            while True:
                n=word()
                if not n:break
                pos+=n*4+4
        elif kind==1009:pos+=word()*4
        elif kind==1010:break
        else:raise AssertionError(kind)
    return result

def compare(before,after):
    old,os=load_hunk(before);new,ns=load_hunk(after)
    for code,path in [(old,before),(new,after)]:
        for off in relocations(path):code[off:off+4]=bytes(4)
    spans=[('presentation/flats/ADDX','predrawall','calcnormvec'),('doors/rotation','rotter','execevent'),('scene/objects/physics','calcscene','gridoffsf'),('walls','makewalls','data'),('C2P 020/030 8 planes','g2k_c2p1x1_8_c5_gen_init','g2k_c2p1x1_8_c5_gen_scroffs'),('C2P 020/030 6 planes','g2k_c2p1x1_6_c5_gen_init','g2k_c2p1x1_6_c5_gen_scroffs'),('C2P 040/060 8 planes','g2k_c2p1x1_8_c5_040_init','g2k_c2p1x1_8_c5_040_data'),('C2P 040/060 6 planes','g2k_c2p1x1_6_c5_040_init','g2k_c2p1x1_6_c5_040_data'),('P96 flip','g2p96_gameplay_dbuf_flip','g2p96_gameplay_dbuf_suspend_primary'),('Bayer lookup','g2wall_bayer_build','g2wall_bayer_rows')]
    total=0
    for title,start,end in spans:
        a=old[os[start]-BASE:os[end]-BASE];b=new[ns[start]-BASE:ns[end]-BASE]
        assert len(a)==len(b),(title,len(a),len(b))
        if a!=b:
            root=Path(__file__).parents[1]/'source'
            declared=set()
            for p in list((root/'modular').glob('gr_*.s'))+[root/'GloomBench.s']:
                for line in p.read_text(encoding='latin1').splitlines():
                    m=re.match(r'^([A-Za-z_]\w*)(?:\s+(?!equ\b)|$)',line,re.I)
                    if m:declared.add(m[1])
            labels=set(os)&set(ns)&declared
            x=semantic(old,os,labels,start,end);y=semantic(new,ns,labels,start,end)
            differences=[(i,u[:2],v[:2]) for i,(u,v) in enumerate(zip(x,y)) if u[2]!=v[2] and u[:2]!=v[:2]]
            assert len(x)==len(y) and not differences,(title,differences[:8])
            print(Path(after).name,title,len(a),'bytes: opcodes/PC targets agree; displacement bytes relocated')
        else:print(Path(after).name,title,len(a),'bytes identical',hashlib.sha256(a).hexdigest()[:16])
        total+=len(a)
    print(total,'bytes in',len(spans),'hot spans checked; absolute relocations normalised, PC destinations verified')

if __name__=='__main__':
    assert len(sys.argv)==6
    dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()))
    compare(*sys.argv[2:4]);compare(*sys.argv[4:6])
