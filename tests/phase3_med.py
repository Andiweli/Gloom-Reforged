"""Actual embedded MED instructions and cold consumer guards.
Usage: python tests/phase3_med.py DLL game.hunk bench.hunk
CIA ownership and beam reads are explicit models; DMA is observed, not executed.
"""
import ctypes,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register
from phase2_resources import run_pure

PRESERVED=list(range(D2,D7+1))+list(range(A2,A6+1))

def fixture():
 b=bytearray(1400);b[:4]=b'MMD1'
 struct.pack_into('>III',b,4,len(b),52,0)
 struct.pack_into('>I',b,16,840);struct.pack_into('>I',b,24,868)
 struct.pack_into('>HH',b,556,1,1);b[839]=1
 struct.pack_into('>H',b,816,125);b[821]=1;b[822:838]=bytes([64])*16;b[838]=64;b[58]=64
 struct.pack_into('>I',b,840,844);struct.pack_into('>HH',b,844,4,0)
 b[852:856]=bytes([24,1,0,0]);struct.pack_into('>I',b,868,872)
 struct.pack_into('>Ih',b,872,16,0);b[878:894]=bytes(range(16))
 return b

def call(c,pc,a0=None,a1=None):
 if a0 is not None:c.set(A0,a0)
 if a1 is not None:c.set(A1,a1)
 c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,pc)
 for i in range(100000):
  pc=c.get(PC)
  assert not c.dll.test_faults(),('fault',hex(pc),i)
  if pc==STOP:
   assert c.get(A7)==STACK+4
   return c.get(D0)
  if pc in c.hooks:c.hooks[pc](c)
  else:c.dll.test_step()
 raise AssertionError(('instruction limit',hex(c.get(PC))))

class Player:
 def __init__(self,dll,path,cpu,busy=0,missing=0,blob=None,patched=True):
  self.c=c=CPU(dll,path,cpu);blob=fixture() if blob is None else blob
  # Explicit two-MiB Chip address model; this is not a Chip-RAM allocator.
  self.ptr=0x100020;c.put(self.ptr,blob);c.w32(c.addr('memlist'),0x100000)
  for off,value in [(0,0),(4,len(blob)+32),(8,32),(16,len(blob))]:c.w32(0x100000+off,value)
  dll.test_guard(self.ptr+len(blob),self.ptr+len(blob)+64,3)
  c.w32(c.addr('medat'),c.addr('medplayer'));c.hook('flushc',lambda c:c.ret(c.get(D0),False))
  c.set(A0,c.addr('medat'));c.run('relocate');self.base=c.r32(c.addr('medat'));self.state=self.base+0xf50
  self.owners={(res,bit):0x123400+res+bit for res in [0xc000,0xd000] for bit in [0,1] if busy&(1<<((res-0xc000)//0x1000*2+bit))}
  self.initial=self.owners.copy();self.adds=[];self.removes=[];self.missing=missing
  def resource(c):
   name=c.bytes(c.get(A1),16).split(b'\0',1)[0];res=0xc000 if name==b'ciaa.resource' else 0xd000
   c.ret(0 if missing&(1<<((res-0xc000)//0x1000)) else res)
  c.hook(EXEC-498,resource)
  self.disable_depth=0;self.disabled_adds=[]
  def disable(c):self.disable_depth+=1;c.ret()
  def enable(c):
   assert self.disable_depth>0,'unbalanced Enable'
   self.disable_depth-=1;c.ret()
  c.hook(EXEC-120,disable);c.hook(EXEC-126,enable)
  for res in [0xc000,0xd000]:
   def add(c,res=res):
    key=(res,c.get(D0));node=c.get(A1);self.adds.append(key)
    self.disabled_adds.append(self.disable_depth)
    if key in self.owners:c.ret(self.owners[key])
    else:self.owners[key]=node;c.ret(0)
   def remove(c,res=res):
    key=(res,c.get(D0));assert self.owners.get(key)==c.get(A1),('foreign/double remove',key)
    self.removes.append(key);del self.owners[key];c.ret()
   c.hook(res-6,add);c.hook(res-12,remove)
  dll.test_hw_mode(1);c.w32(c.addr('chipzero'),0x1ff000)
  call(c,self.base,0x1ff000)
  if patched:c.run('g2med_install_stop')
 def api(self,offset,a0=None):
  if offset==8 and 'g2med_start_checked' in self.c.syms:
   self.c.set(A1,self.base)
   initial_depth=self.disable_depth
   result=call(self.c,self.c.addr('g2med_start_checked'),a0)
   assert self.disable_depth==initial_depth,'Start changed caller interrupt nesting'
   return result
  return call(self.c,self.base+offset,a0)

def tests(dll,path,cpu):
 count=0
 def check(b,valid):
  nonlocal count
  c=CPU(dll,path,cpu);register(c,b);before=[0x45670000+i for i in range(1,15)]
  for i,v in enumerate(before,1):
   if i!=A0:c.set(i,v)
  saved={i:c.get(i) for i in range(1,15)}
  assert (run_pure(c,'g2validate_med')==0)==valid,b[:60].hex()
  assert all(c.get(i)==v for i,v in saved.items()),'validator register convention'
  count+=1
 base=fixture();check(base,True)
 for off,fmt,value in [(0,'4s',b'MMD0'),(0,'4s',b'MCN0'),(0,'4s',b'MCNT'),(876,'h',-1),(876,'h',-2),(876,'H',16),(876,'H',32),(853,'B',2),(853,'B',63),(868,'I',0),(846,'H',16384),(42,'B',1),(816,'H',0),(872,'I',0),(872,'I',1),(54,'H',65535)]:
  b=bytearray(base);struct.pack_into('>'+fmt,b,off,value);check(b,False)
 for value in [0,7,248,255,8,247]:
  b=bytearray(base);b[854:856]=bytes([21,value]);check(b,value in [0,7,248,255])
 for value in [0,1,255]:
  b=bytearray(base);b[854:856]=bytes([11,value]);check(b,value==0)
 b=bytearray(base);b[820]=33;struct.pack_into('>H',b,816,32768);check(b,False)
 # Finetune extensions: byte 3 is used only when the actual stride exceeds 3.
 for value in [0,7,248,255,8,247]:
  b=bytearray(base);struct.pack_into('>I',b,32,1200);struct.pack_into('>IHH',b,1204,1260,1,4);b[1263]=value;check(b,value in [0,7,248,255])
 # Legitimate odd-length loop may extend one byte into the owned module.
 b=bytearray(base);struct.pack_into('>I',b,872,15);struct.pack_into('>HH',b,52,0,8);check(b,True)
 # All timer choices, ownership failure, and reacquisition with foreign owners.
 for busy in range(16):
  p=Player(dll,path,cpu,busy);c=p.c
  c.run('g2med_install_stop') # installation is idempotent
  p.api(12);assert p.owners==p.initial
  for reg in PRESERVED:c.set(reg,0x500000+reg)
  saved={reg:c.get(reg) for reg in PRESERVED}
  p.api(8,p.ptr);assert all(c.get(reg)==v for reg,v in saved.items())
  acquired=len(p.owners)>len(p.initial)
  assert acquired==(busy!=15)
  if acquired:
   dll.test_hw_clear();call(c,p.base+0x40e-32,a1=p.state)
   # A one-row fixture also publishes the silent loop after its first DMA.
   # Replay the real byte writes to inspect each publication, not only the
   # final register state after the handler has installed the next loop.
   regs=bytearray(6);published=[]
   for i in range(dll.test_hw_count()):
    address=dll.test_hw_address(i)
    if 0xdff0a0<=address<=0xdff0a5:
     regs[address-0xdff0a0]=dll.test_hw_value(i)
     if address==0xdff0a5:published.append(struct.unpack('>IH',regs))
   assert (p.ptr+878,8) in published,published
   assert c.get(D0)==1,'Exec interrupt return convention'
   assert all(c.get(reg)==v for reg,v in saved.items())
  p.api(12);p.api(12);assert p.owners==p.initial and c.bytes(p.base+0xf92,1)==b'\0'
  assert len(p.removes)==int(acquired)
  # Next attempt fails after another client acquired all four timers.
  p.owners={(r,b):0x150000+r+b for r in [0xc000,0xd000] for b in [0,1]};foreign=p.owners.copy()
  p.api(8,p.ptr);p.api(12);assert p.owners==foreign
  count+=1
 for missing in [1,2,3]:
  p=Player(dll,path,cpu,missing=missing);p.api(8,p.ptr);p.api(12);p.api(12)
  assert p.owners==p.initial;count+=1
 p=Player(dll,path,cpu);c=p.c
 for i in range(16):c.set(i,0x600000+i)
 c.set(A7,STACK);saved={i:c.get(i) for i in range(15)}
 c.run('g2med_install_stop');assert all(c.get(i)==v for i,v in saved.items());count+=1
 for offset in [0x50,0xe98]:
  p=Player(dll,path,cpu);c=p.c;c.w16(p.base+offset,0x4e71)
  c.w32(c.addr('g2menu_entry_sp'),STACK);c.hook('exittoos',lambda c:c.ret())
  c.run('g2med_install_stop');assert c.r16(c.addr('g2fatal_state')) and not p.owners and not p.adds
  count+=1
 print(Path(path).name,'CPU',cpu,':',count,'MED consumer/timer cases passed (DMA writes observed; hardware modelled)')
 return count

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 print(sum(tests(dll,p,cpu) for p in sys.argv[2:] for cpu in [4,6,9]),'Phase 3 MED cases passed')
