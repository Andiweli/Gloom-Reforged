"""Compare all 64 supplied song pairs against the actual Phase 3 player.
Usage: python tests/phase4_song_switch.py DLL phase3-game game bench DATA_ROOT JSON
1000 actual ticks before and after each Stop/Start. Both songs stay owned,
as in production. CIA/beam/DMA are models; physical sound/timing is not tested.
"""
import ctypes,hashlib,json,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_resources import run_pure
from phase3_med import Player
from phase3_profile_music import decode

def switched(dll,path,first,second):
 p=Player(dll,path,4,blob=first,patched=True);c=p.c
 q=0x180020;c.put(q,second);c.w32(c.addr('memlist'),q-32)
 for off,value in [(0,p.ptr-32),(4,len(second)+32),(8,32),(16,len(second))]:c.w32(q-32+off,value)
 for ptr in [p.ptr,q]:c.set(A0,ptr);assert run_pure(c,'g2validate_med')==0
 digest=hashlib.sha256();writes=0;publications=0;regs=bytearray(c.bytes(0xdff000,0x200))
 for ptr in [p.ptr,q]:
  p.api(8,ptr)
  for tick in range(1000):
   dll.test_hw_clear();c.set(A1,p.state);c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,p.base+0x3ee)
   assert dll.test_until(STOP,1000000),(path,ptr,tick,hex(c.get(PC)),dll.test_faults())
   assert c.get(A7)==STACK+4 and c.get(D0)==1
   for i in range(dll.test_hw_count()):
    a,v=dll.test_hw_address(i),dll.test_hw_value(i);digest.update(struct.pack('>IB',a,v));writes+=1
    if 0xdff000<=a<0xdff200:
     regs[a-0xdff000]=v
     if a in [0xdff0a5,0xdff0b5,0xdff0c5,0xdff0d5]:
      off=(a-0xdff000)&~15;start=struct.unpack_from('>I',regs,off)[0]&~1;length=struct.unpack_from('>H',regs,off+4)[0] or 65536
      if start:
       assert any(lo<=start and start+2*length<=hi for lo,hi in [(p.ptr,p.ptr+len(first)),(q,q+len(second)),(0x1ff000,0x1ff002)]),(path,ptr,tick,hex(start),length)
       publications+=1
  p.api(12);p.api(12);assert not p.owners
 assert len(p.removes)==2
 return {'ticks':2000,'writes':writes,'dma_publications':publications,'trace_sha256':digest.hexdigest()}

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 old,game,bench=sys.argv[2:5];root=Path(sys.argv[5]);rows=[]
 names=[n+'/sfxs/'+m for n in ['gloom','deluxe','gloom3'] for m in ['med1','med2']]+['massacre/musi/'+m for m in ['medA','medB']]
 blobs={n:decode(dll,game,(root/n).read_bytes()) for n in names}
 for first in names:
  for second in names:
   reference=switched(dll,old,blobs[first],blobs[second])
   for path in [game,bench]:assert switched(dll,path,blobs[first],blobs[second])==reference,(path,first,second)
   rows.append({'first':first,'second':second,**reference})
  print(first,': 8 outgoing song pairs agree on all three binaries',flush=True)
 Path(sys.argv[6]).write_text(json.dumps(rows,indent=2)+'\n')
 print('192 original song-pair trace/lifecycle cases passed; 384000 actual ticks; equal MMIO streams, modelled DMA bounds')
