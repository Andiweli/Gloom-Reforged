"""Actual initmain and repeated scriptplay load prefixes using repository assets.
Usage: python tests/phase2_allocations.py DLL game.hunk [bench.hunk]
Graphics/audio/interrupt/library calls are modelled; pause at player1_ok before
starting gameplay. This measures private header requests, not a hardware boot.
"""
from pathlib import Path
import ctypes,sys,struct,json
root=Path(__file__).resolve().parents[1]
from asm_regression import *
dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
class Scenario:
 def __init__(self,c):
  self.c=c;self.handles={};self.next_handle=1;self.top=0x300000;self.blocks={};self.peak=0;self.total=0;self.available=[(0x300000,0x400000)];self.attempts=0;self.fail_at=0
  for off,fn in [(-30,self.open),(-42,self.read),(-66,self.seek),(-36,self.close),(-84,lambda c:c.ret(0)),(-132,lambda c:c.ret(205))]:c.hook(DOS+off,fn)
  c.hook(EXEC-198,self.alloc);c.hook(EXEC-210,self.free)
 def open(self,c):
  n=c.bytes(c.get(D1),192).split(b'\0',1)[0].decode('latin1').replace('PROGDIR:','')
  p=root/'source'/n
  if not p.is_file():c.ret(0);return
  h=self.next_handle;self.next_handle+=1;self.handles[h]=[p.read_bytes(),0,n];c.ret(h)
 def read(self,c):
  b,pos,n=self.handles[c.get(D1)];chunk=b[pos:pos+c.get(D3)];c.put(c.get(D2),chunk);self.handles[c.get(D1)][1]+=len(chunk);c.ret(len(chunk))
 def seek(self,c):
  h=self.handles[c.get(D1)];old=h[1];h[1]=len(h[0]) if c.get(D3)==1 else 0;c.ret(old)
 def close(self,c):del self.handles[c.get(D1)];c.ret(1)
 def alloc(self,c):
  self.attempts+=1
  if self.attempts==self.fail_at:c.ret(0);return
  n=c.get(D0);size=(n+15)&~15
  for i,(a,capacity) in enumerate(self.available):
   if capacity>=size:
    self.available.pop(i)
    if capacity>size:self.available.append((a+size,capacity-size))
    break
  else:raise AssertionError(('host allocator exhausted',n))
  self.blocks[a]=(n,c.get(D1));self.total+=1;self.peak=max(self.peak,len(self.blocks));c.ret(a)
 def free(self,c):
  a=c.get(A1);n,flags=self.blocks.pop(a);assert n==c.get(D0)
  self.available.append((a,(n+15)&~15));self.available.sort();joined=[]
  for p,s in self.available:
   if joined and joined[-1][0]+joined[-1][1]==p:joined[-1]=(joined[-1][0],joined[-1][1]+s)
   else:joined.append((p,s))
  self.available=joined;c.ret()
 def snapshot(self,label):
  chip=sum(bool(flags&2) for _,flags in self.blocks.values());n=len(self.blocks)
  print(label,{'active_private_blocks':n,'chip_requests':chip,'fast_or_public_requests':n-chip,'extra_header_bytes':16*n,'requested_bytes':sum(x[0] for x in self.blocks.values()),'peak_blocks':self.peak,'successful_allocations':self.total})
def run(c,name,limit=3000000,until=None):
 c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,c.addr(name))
 pure=['g2crm_decode_checked','remapanim','remap','initdarktable','g2v36_clear_title_buffers','g2gun_prepare','initmap','g2require_actor_shape','g2validate_loaded_slot','g2require_core_tables','g2require_map_textures']
 for i in range(limit):
  pc=c.get(PC)
  if until and pc==c.addr(until):return
  if dll.test_faults():raise AssertionError((name,'first fault',hex(pc),max(((v,k) for k,v in c.syms.items() if v<=pc)),[hex(c.get(x)) for x in range(16)]))
  if pc==STOP:assert c.get(A7)==STACK+4 and dll.test_faults()==0,(name,hex(c.get(A7)),dll.test_faults(),[hex(c.get(x)) for x in range(16)]);return c.get(D0)
  if i%100==0:c.w16(c.addr('vbcounter'),0)
  if pc==c.addr('scriptplay'):assert dll.test_until(c.addr('permit'),10000000)
  elif pc in c.hooks:c.hooks[pc](c)
  elif pc in [c.syms[x] for x in pure if x in c.syms]:assert dll.test_until(c.r32(c.get(A7)),100000000),hex(pc)
  else:
   ret=c.r32(c.get(A7));assert BASE<=pc<BASE+len(c.code),(hex(pc),hex(ret),max(((v,k) for k,v in c.syms.items() if v<=ret)));dll.test_step()
 raise AssertionError(('instruction limit',name,hex(c.get(PC))))

def setup(path,mode):
 c=CPU(dll,path);io=Scenario(c)
 c.w16(c.addr('aga'),65535);c.w16(c.addr('os'),0);c.w16(c.addr('g2display_mode'),2 if mode=='P96' else 1)
 c.w32(EXEC+276,0x220000);c.w16(c.addr('p96target_width'),320);c.w16(c.addr('p96target_height'),240)
 c.w32(c.addr('p96modeid_rgbformat'),1)
 c.hook(EXEC-498,lambda c:c.ret(0x230000));c.hook(EXEC-408,lambda c:c.ret(GRAPHICS));c.hook(GRAPHICS-222,lambda c:c.ret())
 for n in ['flushc','initsfx','initvbint','dispoff','dispon','showpic','forbid','permit','vwait','initmed','g2detectprofile','g2p96_clut_clear_runtime_c87b78j','g2p96_select_source_backend_c87b79n','db_p96_source','g2kalms_startup_init','g2p96_req_show_easy_a1']:
  if n in c.syms:c.hook(n,lambda c:c.ret(c.get(D0),clobber=False))
 c.hook('g2p96_display_is_p96_capable',lambda c:c.ret(-1 if mode=='P96' else 0))
 return c,io

def scenario(path,mode):
 c,io=setup(path,mode)
 run(c,'initmain');io.snapshot(mode+' initmain')
 c.set(A0,c.addr('datafiles'));run(c,'loadfiles');scriptptr=c.r32(c.addr('script'))
 minima=[];active=[]
 maps=sorted((root/'source/maps').iterdir())
 for index,p in enumerate(maps+maps):
  c.put(c.addr('floortag'),b'1\0');run(c,'loadtile')
  command=('play_'+p.name+'\ndone_\n').encode();c.put(scriptptr,command);c.w32(c.addr('scriptat'),scriptptr)
  run(c,'g2script_next_command');run(c,'scriptplay',until='g2v10_player1_ok')
  assert c.r32(c.addr('player1')) and not c.r16(c.addr('g2fatal_state')),p.name
  active.append(len(io.blocks))
  if index==0:io.snapshot(mode+' '+p.name+' event1')
  # Execute the same ownership cleanup calls as mainexit/gameover.
  for fn in ['freeobjlist','freetxts','freemap','freetiles']:run(c,fn)
  assert not c.r32(c.addr('map_map')) and not any(c.r32(c.addr('textures')+4*i) for i in range(160))
  assert not io.handles
  node=c.r32(c.addr('memlist'));seen=set()
  while node:assert node in io.blocks and node not in seen;seen.add(node);node=c.r32(node)
  assert seen==set(io.blocks)
  minima.append(len(io.blocks))
 assert len(set(minima))==1,minima
 print(Path(path).name,mode,'84 load/cleanup cycles:',{'active_range':(min(active),max(active)),'post_cleanup':minima[0],'peak_blocks':io.peak,'peak_extra_bytes':io.peak*16})
 run(c,'freememlist');assert not io.blocks and not c.r32(c.addr('memlist'))
 return len(maps)*2+1


def oom(path):
 c,io=setup(path,'AGA');run(c,'initmain');attempts=io.attempts
 for failure in range(1,attempts+1):
  c,io=setup(path,'AGA');io.fail_at=failure
  c.w32(c.addr('g2menu_entry_sp'),STACK);c.hook('exittoos',lambda c:c.ret(c.get(D0)))
  run(c,'initmain');assert io.attempts>=failure and not io.handles
  run(c,'freememlist');assert not io.blocks and not c.r32(c.addr('memlist'))
 print(Path(path).name,attempts,'initmain AllocMem failure positions: no residual private blocks/handles')
 return attempts

total=sum(scenario(p,m) for p in sys.argv[2:] for m in ['AGA','P96'])
total+=sum(oom(p) for p in sys.argv[2:])
print(total,'lifecycle/OOM scenarios passed (68020; OS modelled)')
