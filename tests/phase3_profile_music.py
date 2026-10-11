"""Read-only supplied profile music: actual ticks, DMA publications and comparison.
Usage: python tests/phase3_profile_music.py DLL old-game new-game new-bench DATA_ROOT OUTPUT_JSON
Each module runs a fixed 30000 ticks; this is bounded state coverage, not a proof
of all effects, actual DMA, CIA interrupt timing, analogue sound or hardware.
"""
import ctypes,hashlib,json,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_resources import run_pure
from phase3_med import Player

def decode(dll,path,b):
 if b[:4] not in [b'CrM!',b'CrM2']:return b
 n=struct.unpack_from('>I',b,6)[0];c=CPU(dll,path)
 c.put(0x600000,b);c.set(A0,0x600000);c.set(A1,0x300020);c.set(D0,len(b));c.set(D1,n)
 c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,c.addr('g2crm_decode_checked'))
 assert dll.test_until(STOP,100000000),('CrM instruction budget',hex(c.get(PC)),dll.test_faults())
 assert c.get(D0)==0 and c.get(A7)==STACK+4
 return c.bytes(0x300020,n)

def trace(dll,path,blob,patched):
 p=Player(dll,path,4,blob=blob,patched=patched);c=p.c;c.set(A0,p.ptr)
 assert run_pure(c,'g2validate_med')==0
 p.api(8,p.ptr);regs=bytearray(c.bytes(0xdff000,0x200));digest=hashlib.sha256();writes=0;publications=0;maxseq=0
 for tick in range(30000):
  dll.test_hw_clear();c.set(A1,p.state);c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,p.base+0x40e-32)
  assert dll.test_until(STOP,1000000),(path,tick,hex(c.get(PC)),dll.test_faults())
  assert c.get(A7)==STACK+4 and c.get(D0)==1
  for i in range(dll.test_hw_count()):
   a,v=dll.test_hw_address(i),dll.test_hw_value(i);digest.update(struct.pack('>IB',a,v));writes+=1
   if 0xdff000<=a<0xdff200:
    regs[a-0xdff000]=v
    if a in [0xdff0a5,0xdff0b5,0xdff0c5,0xdff0d5]:
     off=(a-0xdff000)&~15;start=struct.unpack_from('>I',regs,off)[0]&~1;words=struct.unpack_from('>H',regs,off+4)[0] or 65536
     if start:
      assert any(lo<=start and start+2*words<=hi for lo,hi in [(p.ptr,p.ptr+len(blob)),(0x1ff000,0x1ff002)]),('DMA outside owned Chip model',path,tick,hex(start),words)
      assert start+2*words<=0x200000
      publications+=1
  maxseq=max(maxseq,c.r16(p.ptr+46))
 p.api(12)
 assert not p.owners
 if patched:p.api(12);assert len(p.removes)==1
 return {'ticks':30000,'writes':writes,'dma_publications':publications,'max_sequence':maxseq,'trace_sha256':digest.hexdigest()}

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 old,game,bench=sys.argv[2:5];root=Path(sys.argv[5]);results=[]
 paths=[root/n/'sfxs'/m for n in ['gloom','deluxe','gloom3'] for m in ['med1','med2']]+[root/'massacre/musi'/m for m in ['medA','medB']]
 for path in paths:
  raw=path.read_bytes();blob=decode(dll,game,raw);row={'resource':path.relative_to(root).as_posix(),'file_bytes':len(raw),'file_sha256':hashlib.sha256(raw).hexdigest(),'decoded_bytes':len(blob),'decoded_sha256':hashlib.sha256(blob).hexdigest()}
  reference=trace(dll,old,blob,False)
  for executable in [game,bench]:
   actual=trace(dll,executable,blob,True);assert actual==reference,(path,executable,reference,actual)
  row.update(reference);results.append(row);print(json.dumps(row),flush=True)
 Path(sys.argv[6]).write_text(json.dumps(results,indent=2)+'\n')
 print('24 original-music trace cases passed; 720000 ticks; equal MMIO streams, modelled DMA bounds')
