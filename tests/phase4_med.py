"""Cold MED aliases/jumps/octave DMA and actual first-effect instructions.
Usage: python tests/phase4_med.py DLL phase3-game game.hunk bench.hunk
Beam/CIA/DMA are explicit models. Reproduced old faults are expected evidence,
not successful playback. This finite suite does not certify every MED state.
"""
import ctypes,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register
from phase2_resources import run_pure
from phase3_med import Player,fixture,call

def patterns(rows=(0,0),sequence=(0,1)):
 b=fixture();b.extend(bytes(5000-len(b)))
 struct.pack_into('>I',b,4,len(b));struct.pack_into('>I',b,16,1200)
 struct.pack_into('>HH',b,556,len(rows),len(sequence));b[560:560+len(sequence)]=bytes(sequence)
 for i,n in enumerate(rows):
  struct.pack_into('>I',b,1200+4*i,1300+600*i)
  struct.pack_into('>HH',b,1300+600*i,4,n)
 return b

def tests(dll,path,cpu):
 count=0
 def check(b,valid):
  nonlocal count
  c=CPU(dll,path,cpu);p=register(c,b)
  for reg in range(1,15):
   if reg!=A0:c.set(reg,0x7ad00000+reg)
  saved={reg:c.get(reg) for reg in range(1,15)}
  # Largest DIVU-overflow fixture spans the usual harness stack at $800000.
  # Place this call's stack above the complete input allocation instead.
  c.set(A7,0xf00000);c.w32(0xf00000,STOP);c.set(PC,c.addr('g2validate_med'))
  assert dll.test_until(STOP,20000000) and c.get(A7)==0xf00004
  assert (c.get(D0)==0)==valid,(path,b[848:872].hex(),b[872:878].hex(),valid)
  assert c.bytes(p,len(b))==b,'cold validation changed the module'
  assert all(c.get(reg)==v for reg,v in saved.items()),'validator register preservation'
  count+=1
 check(fixture(),True)
 b=fixture();struct.pack_into('>I',b,848,868);check(b,False)
 # Duplicate read-only blocks are legitimate; nonnull info relocation is not.
 for info in [0,1250]:
  b=fixture();struct.pack_into('>H',b,556,2);struct.pack_into('>I',b,16,1200)
  struct.pack_into('>II',b,1200,844,844);struct.pack_into('>I',b,848,info);check(b,info==0)
 for off in [52,840,868,872,894,1200]:
  b=fixture();struct.pack_into('>I',b,848,off);check(b,off in [894,1200])
 # Shared empty info is not relocated; shared nonempty info is relocated twice.
 for nonzero in [False,True]:
  b=patterns();struct.pack_into('>I',b,1304,2600);struct.pack_into('>I',b,1904,2600)
  if nonzero:struct.pack_into('>I',b,2600,2700)
  check(b,not nonzero)
 # Adjacent distinct records with nonzero, bounded pointers remain legal.
 b=patterns();struct.pack_into('>I',b,1304,2600);struct.pack_into('>I',b,1904,2608)
 struct.pack_into('>IIII',b,2600,2700,2710,2720,2730);check(b,True)
 # Sharing a read-only sample is legal, unlike overlap with structural data.
 b=fixture();b[839]=2;struct.pack_into('>I',b,24,1200);struct.pack_into('>II',b,1200,872,872);check(b,True)
 for cmd in [13,29,61]:
  for param in [0,1,7,255]:
   b=fixture();b[854:856]=bytes([cmd,param]);check(b,cmd==13 or param==0)
 # The last $1d wins. Command $0d is a volume slide, not a pattern break.
 b=fixture();b[854:856]=bytes([29,255]);b[858:860]=bytes([29,0]);check(b,True)
 b=fixture();b[854:856]=bytes([29,0]);b[858:860]=bytes([29,255]);check(b,False)
 # Destination is the real sequence successor, not minimum rows of all blocks.
 for rows,seq,param,valid in [((0,7),(0,1),7,True),((7,0),(0,1),7,False),((0,7,0),(0,1),7,True),((7,0),(0,),7,True),((0,7),(1,0,1),7,True)]:
  b=patterns(rows,seq);b[1310:1312]=bytes([29,param]);check(b,valid)
 # Bxx followed by $1d increments its target; reverse order does not.
 for first,second,valid in [((11,1),(29,7),False),((29,7),(11,1),True),((11,0),(29,7),True)]:
  b=patterns((0,7));b[1310:1312]=bytes(first);b[1314:1316]=bytes(second);check(b,valid)
 for param in [0,1,127,128,255]:
  for jump in [11,29]:
   b=fixture();b[854:856]=bytes([25,param]);b[858:860]=bytes([jump,0]);check(b,param==0)
 # Commands on MIDI tracks 4..15 are skipped by the actual $000f row mask.
 b=fixture();struct.pack_into('>H',b,844,16);struct.pack_into('>I',b,24,1200)
 b[852:916]=bytes(64)
 struct.pack_into('>I',b,1200,1300);struct.pack_into('>Ih',b,1300,16,0)
 b[870:872]=bytes([29,255]);check(b,True)
 # Mathematical DIVU overflow, zero Paula length, and all type tables.
 raw=(Path(__file__).parents[1]/'source/medplay').read_bytes()
 for kind in range(1,7):
  divisor=raw[0x2a9+kind]
  for quotient,valid in [(0,False),(1,kind==6),(2,True),(256,True),(65536,False)]:
   n=divisor*quotient;b=fixture();b.extend(bytes(max(0,878+n-len(b))))
   struct.pack_into('>I',b,4,len(b));struct.pack_into('>Ih',b,872,n,kind);check(b,valid)
 # Execute every multi-octave lookup branch with and without a loop. Inspect
 # every publication, including intermediate pointers replaced later in IRQ.
 for kind in range(1,7):
  for octave in range(6):
   for loop in [False,True]:
    n=raw[0x2a9+kind]*256;b=fixture();b.extend(bytes(max(0,878+n-len(b))))
    struct.pack_into('>I',b,4,len(b));struct.pack_into('>Ih',b,872,n,kind)
    if loop:struct.pack_into('>HH',b,52,1,2)
    b[852]=1+12*octave;check(b,True)
    p=Player(dll,path,cpu,blob=b);c=p.c;p.api(8,p.ptr);dll.test_hw_clear()
    call(c,p.base+0x3ee,a1=p.state);regs=bytearray(6);publications=[]
    for i in range(dll.test_hw_count()):
     a=dll.test_hw_address(i)
     if 0xdff0a0<=a<=0xdff0a5:
      regs[a-0xdff0a0]=dll.test_hw_value(i)
      if a==0xdff0a5:
       start,length=struct.unpack('>IH',regs);start&=~1;length=length or 65536
       assert any(lo<=start and start+length*2<=hi for lo,hi in [(p.ptr,p.ptr+len(b)),(0x1ff000,0x1ff002)])
       publications.append((start,length))
    index=raw[0x2a3+kind]+octave
    expected=(p.ptr+878+256*raw[0x34a+index])&~1
    assert publications and publications[0][0]==expected,(kind,octave,publications)
    p.api(12);assert not p.owners;count+=1
 # First-note consumers must use a bounded existing tuning table before any
 # ordinary PlayNote has set one. The IRQ instruction stream remains original.
 for command,param in [(3,1),(15,253)]:
  for channel in range(4):
   b=fixture();b[852:856]=bytes(4);b[852+channel*4:856+channel*4]=bytes([1,0,command,param])
   p=Player(dll,path,cpu,blob=b);c=p.c
   dll.test_guard(0,4,1);dll.test_guard(p.ptr+len(b),0x500000,3)
   p.api(8,p.ptr);call(c,p.base+0x3ee,a1=p.state);p.api(12);p.api(12)
   assert not p.owners and len(p.removes)==1;count+=1
 # Installer is idempotent, preserves established tuning and all MIDI records.
 p=Player(dll,path,cpu);c=p.c
 slots=[c.r32(p.state+0x2c8+4*i)+0x4e for i in range(4)]
 before=c.bytes(p.base+0x1128,240)
 for i,slot in enumerate(slots):c.w32(slot,p.base+0x132a+2*i)
 c.run('g2med_install_stop');assert c.bytes(p.base+0x1128,240)==before
 assert [c.r32(s) for s in slots]==[p.base+0x132a+2*i for i in range(4)];count+=1
 for depth in [0,1,2]:
  p=Player(dll,path,cpu);p.disable_depth=depth
  p.api(8,p.ptr);assert all(n==depth+1 for n in p.disabled_adds)
  assert p.c.r32(p.state+8)==p.ptr and p.c.r16(p.base+0x1c72)==1
  p.api(12);assert not p.owners and p.disable_depth==depth;count+=1
 # Real warm transition: retain index 2, then switch to a one-sample song.
 # Validate both files separately; only a note actually entering PlayNote
 # without an overriding instrument is rejected. IRQ dispatch is modelled;
 # all AddICRVector calls must occur inside the balanced cold Disable region.
 for channel in range(4):
  for note,inst,cmd,param,valid in [(24,0,0,0,False),(24,1,0,0,True),(0,0,0,0,True),(24,0,3,1,True),(24,0,31,0,True),(24,0,31,1,False),(24,0,15,253,True),(24,0,15,254,True),(24,0,0,0,'null-sample')]:
   first=fixture();first[839]=3;first[852:868]=bytes(16)
   struct.pack_into('>I',first,24,1200);struct.pack_into('>III',first,1200,872,872,872)
   first[852+4*channel:856+4*channel]=bytes([24,3,0,0])
   second=fixture();second[852:868]=bytes(16)
   second[852+4*channel:856+4*channel]=bytes([note,inst,cmd,param])
   if valid=='null-sample':
    second[839]=3;struct.pack_into('>I',second,24,1200);struct.pack_into('>III',second,1200,872,872,0);valid=False
   p=Player(dll,path,cpu,blob=first);c=p.c;q=0x180020;c.put(q,second);c.w32(c.addr('memlist'),q-32)
   for off,value in [(0,p.ptr-32),(4,len(second)+32),(8,32),(16,len(second))]:c.w32(q-32+off,value)
   for ptr in [p.ptr,q]:c.set(A0,ptr);assert run_pure(c,'g2validate_med')==0
   p.api(8,p.ptr);call(c,p.base+0x3ee,a1=p.state)
   c.w32(c.addr('g2menu_entry_sp'),STACK)
   c.hook('exittoos',lambda c:c.set(PC,p.base+12)) # actual Stop before owned free
   adds=len(p.adds);p.api(8,q)
   assert bool(c.r16(c.addr('g2fatal_state')))==(not valid)
   assert p.disable_depth==0 and all(depth==1 for depth in p.disabled_adds)
   if valid:call(c,p.base+0x3ee,a1=p.state);p.api(12)
   else:assert len(p.adds)==adds,'rejected Start acquired another timer'
   assert not p.owners,(channel,note,inst,cmd,param,valid,p.owners,c.bytes(p.base+0xf92,1).hex())
   frees=[];c.hook(EXEC-210,lambda c:(frees.append(c.get(A1)),c.ret()))
   c.run('freememlist');assert frees==[q-32,p.ptr-32] and not c.r32(c.addr('memlist'))
   count+=1
 print(Path(path).name,'CPU',cpu,':',count,'Phase 4 MED cases passed')
 return count

def old_faults(dll,path):
 blobs=[]
 b=fixture();struct.pack_into('>I',b,848,868);blobs.append(b)
 b=fixture();struct.pack_into('>H',b,556,2);struct.pack_into('>I',b,16,1200)
 struct.pack_into('>II',b,1200,844,844);struct.pack_into('>I',b,848,1250);blobs.append(b)
 b=fixture();b[854:856]=bytes([29,255]);blobs.append(b)
 b=fixture();b[852:856]=bytes([1,0,15,253]);blobs.append(b)
 b=fixture();b[852:856]=bytes([0,0,25,128]);b[858:860]=bytes([11,0]);blobs.append(b)
 for b in blobs:
  c=CPU(dll,path);register(c,b);assert run_pure(c,'g2validate_med')==0
  p=Player(dll,path,4,blob=b);c=p.c
  dll.test_guard(0,4,1);dll.test_guard(p.ptr+len(b),0x500000,3)
  dll.test_guard(p.ptr-65536,p.ptr,1)
  try:
   p.api(8,p.ptr)
   for _ in range(12):call(c,p.base+0x3ee,a1=p.state)
  except AssertionError:
   assert dll.test_faults(),'unexpected old-path failure'
  else:raise AssertionError('old unsafe path no longer reproduced')
 # Two valid standalone modules fail after a normal Stop/Start transition.
 first=fixture();first[839]=3;struct.pack_into('>I',first,24,1200)
 struct.pack_into('>III',first,1200,872,872,872);first[853]=3
 second=fixture();second[853]=0;second[878:880]=bytes(2)
 p=Player(dll,path,4,blob=first);c=p.c;q=0x180020;c.put(q,second);c.w32(c.addr('memlist'),q-32)
 for off,value in [(0,p.ptr-32),(4,len(second)+32),(8,32),(16,len(second))]:c.w32(q-32+off,value)
 for ptr in [p.ptr,q]:c.set(A0,ptr);assert run_pure(c,'g2validate_med')==0
 p.api(8,p.ptr);call(c,p.base+0x3ee,a1=p.state);p.api(12);p.api(8,q);dll.test_guard(0,16,1)
 try:call(c,p.base+0x3ee,a1=p.state)
 except AssertionError:assert dll.test_faults()
 else:raise AssertionError('old retained-instrument failure not reproduced')
 # Already-active Start loses its own timer ownership: independent lifecycle
 # counterexample, distinct from the six guarded CPU read/write failures.
 p=Player(dll,path,4);p.api(8,p.ptr);p.api(8,p.ptr);p.api(12)
 assert p.owners and p.c.bytes(p.base+0xf92,1)==b'\0'
 print(len(blobs)+1,'old accepted MED faults and 1 active-Start timer leak reproduced with actual player instructions')
 return len(blobs)+1

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 counterexamples=old_faults(dll,sys.argv[2])
 print(sum(tests(dll,p,cpu) for p in sys.argv[3:] for cpu in [4,6,9]),'new Phase 4 MED cases passed;',counterexamples,'separate baseline counterexamples')
