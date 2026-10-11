"""Cold legacy artwork/gun/blank-frame regressions on assembled 68k code.
Usage: python tests/phase3_legacy_resources.py DLL game.hunk bench.hunk
Synthetic fixtures here prove error paths; original-data proof is separate.
"""
import ctypes,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register,words
from phase2_resources import run_pure
from phase2_palettes import guarded

def pixels(b):
 width,height,depth=struct.unpack_from('>3H',b);p=12;result=[]
 for _ in range(height*depth):
  row=bytearray()
  while len(row)<width//8:
   n=b[p];p+=1;n=n-256 if n>127 else n
   if n>=0:row.extend(b[p:p+n+1]);p+=n+1
   elif n!=-128:row.extend(bytes([b[p]])*(1-n));p+=1
  result.append(bytes(row[:width//8]))
 return result

def tests(dll,path,cpu):
 count=0
 for row,valid in [(b'\xd9\x61',True),(b'\xd8\x61',True),(b'\xd7\x61',False),(b'\x28'+bytes(range(41)),True),(b'\x27'+bytes(range(40)),True),(b'\x29'+bytes(range(42)),False),(b'\x80\xd8\x61',True),(b'\x80',False),(b'\xd8',False),(b'\x28'+bytes(40),False)]:
  b=words(320,1,1,0)+bytes(4)+row;c=CPU(dll,path,cpu);p=register(c,b)
  for reg in [D1,D2,D3,D4,D5,D6,D7]:c.set(reg,0x7bad0000+reg)
  saved={reg:c.get(reg) for reg in range(1,15)}
  assert (run_pure(c,'g2normalize_legacy_iff')==0)==valid
  assert all(c.get(reg)==v for reg,v in saved.items())
  if valid:
   out=c.bytes(p,len(b));assert pixels(b)==pixels(out)
   assert run_pure(c,'g2validate_iff')==0
  else:assert c.bytes(p,len(b))==b,'invalid input changed before full proof'
  count+=1
 for profile in [0,1,2,3]:
  c=CPU(dll,path,cpu);b=words(320,1,1,0)+bytes(4)+b'\xd8\x61';p=register(c,b)
  c.w16(c.addr('g2_game_profile'),profile);c.set(D0,p);c.set(A3,c.addr('magic'))
  assert guarded(c,'g2validate_loaded_slot')==(profile in [2,3]);count+=1
 # Zero-height G3 blank frame: exact 1x0 handles (0,-1), zero pixel area.
 # Preserve all bytes; no following pixel is consumed or manufactured.
 for profile,width,pixel,size,valid in [(3,1,0,30,True),(3,2,0,30,False),(3,1,1,30,True),(0,1,0,30,False),(3,1,0,24,False)]:
  b=bytearray(words(0,1,1,1)+struct.pack('>II',26 if size==30 else 22,16)+words(0,-1,width,0)+bytes([pixel,0])+words(1,0))
  if size==24:b=b[:24];struct.pack_into('>H',b,22,0)
  c=CPU(dll,path,cpu);register(c,b);c.w16(c.addr('g2_game_profile'),profile)
  assert (run_pure(c,'g2validate_anim')==0)==valid,(profile,width,pixel,size)
  assert c.bytes(0x300020,len(b))==b
  count+=1
 # Execute the real zero-height renderer branch. Invalid pixel/render targets
 # must never be reached; stock mode only skips unrelated reflection cover.
 c=CPU(dll,path,cpu);c.put(0x300000,words(0,-1,1,0))
 c.put(0x310000,bytes(26));c.w32(c.addr('shapelist'),0x310000)
 c.w16(0x310000+12,256);c.w32(0x310000+14,0x300000);c.w16(0x310000+18,256)
 c.w16(c.addr('g2stock_enabled'),65535)
 for name,value in [('width',320),('hite',240),('maxx',160),('maxy',120)]:c.w16(c.addr(name),value)
 c.w32(c.addr('chunky'),0xffffffff);c.w32(0x310000+22,0xffffffff)
 def unexpected(c):raise AssertionError('empty frame entered shadow/pixel rendering')
 c.hook('g2_setup_enemy_blob_column',unexpected);c.run('drawshapes',5000)
 assert c.bytes(0x300000,8)==words(0,-1,1,0);count+=1
 # Real allocator/free routines with explicitly modelled Exec and owned data.
 b=words(0,2,1,1)+struct.pack('>III',40,20,30)+words(0,0,1,1)+b'\x05\0'+words(0,0,1,1)+b'\x06\0'+words(6,0,1,2,3,4,5)
 for failure in [False,True]:
  c=CPU(dll,path,cpu);p=register(c,b);calls=[]
  c.w16(c.addr('g2_game_profile'),3);c.w32(c.addr('gunpic'),p)
  c.hook(EXEC-198,lambda c:(calls.append(('alloc',c.get(D0))),c.ret(0 if failure else 0x340000)))
  c.hook(EXEC-210,lambda c:(calls.append(('free',c.get(A1))),c.ret()))
  c.set(D0,p);c.set(A3,c.addr('gunpic'))
  assert guarded(c,'g2validate_loaded_slot')==(not failure)
  if not failure:
   q=c.r32(c.addr('gunpic'));assert q!=p and c.get(D0)==q
   assert c.bytes(q+20,12)==bytes(12) and c.r16(q+2)==2
   assert c.bytes(q+32,len(b)-20)==b[20:]
   assert [c.r32(q+i) for i in [8,12,16]]==[52,32,42]
   assert calls==[('alloc',len(b)+44),('free',0x300000)]
   c.set(D0,q);c.set(A3,c.addr('gunpic'));assert guarded(c,'g2validate_loaded_slot')
   assert len(calls)==2,'normalisation allocated twice'
  else:assert c.r32(c.addr('gunpic'))==p and not any(a=='free' for a,_ in calls)
  count+=1
 print(Path(path).name,'CPU',cpu,':',count,'legacy resource cases passed')
 return count
if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 print(sum(tests(dll,p,cpu) for p in sys.argv[2:] for cpu in [4,6,9]),'legacy resource cases passed')
