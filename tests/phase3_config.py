"""Two real 68k tasks sharing a DOS file model, interleaved at DOS boundaries.
Usage: python tests/phase3_config.py DLL game.hunk bench.hunk
Two DLL instances have separate CPU/memory globals. This is not filesystem
crash-durability testing or an exhaustive scheduler-state proof.
"""
import ctypes,shutil,sys,tempfile
from pathlib import Path
from asm_regression import *

class Writer:
 def __init__(self,dll,path,files,task,label):
  self.c=c=CPU(dll,path);self.io=io=ConfigDOS(c);io.files=files
  io.new=('new-complete-config-'+label).encode();c.put(0x290000,io.new);c.set(D0,len(io.new));c.w32(EXEC+276,task)
  c.set(A7,STACK);c.w32(STACK,STOP);c.set(PC,c.addr('g2save_config_checked'));self.done=False;self.operations=0
 def advance(self):
  if self.done:return
  c=self.c
  for i in range(10000):
   pc=c.get(PC)
   assert not c.dll.test_faults()
   if pc==STOP:
    assert c.get(A7)==STACK+4;self.done=True;return
   if pc in c.hooks:
    c.hooks[pc](c);self.operations+=1;return
   assert BASE<=pc<BASE+len(c.code);c.dll.test_step()
  raise AssertionError('writer step budget')
 def finish(self):
  for i in range(100):
   if self.done:return
   self.advance()
  raise AssertionError('writer completion budget')

def tests(dlls,path):
 count=0
 # Every DOS boundary of one writer, in both task orders, with and without
 # an old target, then the other writer, then resume the interrupted writer.
 for existing in [False,True]:
  for reverse in [False,True]:
   for pause in range(22):
    name='PROGDIR:test.cfg';files={name:b'old-complete-config'} if existing else {}
    a=Writer(dlls[0],path,files,0x112233,'A');b=Writer(dlls[1],path,files,0x445566,'B')
    first,second=(b,a) if reverse else (a,b)
    for i in range(pause):first.advance()
    second.finish();first.finish()
    complete={a.io.old,a.io.new,b.io.new}
    assert files.get(name) in complete or files.get(name+'.g2bak') in complete,(pause,existing,reverse,files)
    assert all(data in complete or data==b'' for data in files.values())
    count+=1
 for existing in [False,True]:
  for first in [0,1]:
   name='PROGDIR:test.cfg';files={name:b'old-complete-config'} if existing else {}
   tasks=[Writer(dlls[0],path,files,0x112233,'A'),Writer(dlls[1],path,files,0x445566,'B')]
   for step in range(100):
    tasks[(step+first)%2].advance()
    if all(t.done for t in tasks):break
   assert all(t.done for t in tasks)
   assert files.get(name) in {tasks[0].io.old,tasks[0].io.new,tasks[1].io.new}
   count+=1
 # Corrupt backups can be renamed into an absent target, but the real reader
 # must reject their framing and retain settings. Existing targets win.
 for corrupt in [b'',b'bad magic'+bytes(60),b'GLMCFG'+struct.pack('>H',9)+bytes(44),b'GLMCFG\0\4']:
  for existing in [False,True]:
   c=CPU(dlls[0],path);io=ConfigDOS(c);io.name='PROGDIR:gloom.cfg';backup=io.name+'.g2bak';io.files={backup:corrupt}
   if existing:io.files[io.name]=b'bad-but-existing-target'
   c.w16(c.addr('floorflag'),0x55aa);c.run('g2cfg_load')
   assert c.r16(c.addr('floorflag'))==0x55aa
   if existing:assert io.files[backup]==corrupt and io.files[io.name]==b'bad-but-existing-target'
   else:assert io.files[io.name]==corrupt
   count+=1
 print(Path(path).name,':',count,'concurrent/corrupt config cases passed (68020; DOS modelled)')
 return count

if __name__=='__main__':
 with tempfile.TemporaryDirectory(prefix='gloom-config-') as directory:
  dlls=[]
  for name in ['cpuA.dll','cpuB.dll']:
   target=Path(directory)/name;shutil.copyfile(sys.argv[1],target);dll=ctypes.CDLL(str(target));dll.test_get.restype=ctypes.c_uint;dlls.append(dll)
  total=sum(tests(dlls,path) for path in sys.argv[2:])
  # Windows keeps loaded DLLs locked. Release explicit handles before cleanup.
  import _ctypes
  for dll in dlls:
   (_ctypes.FreeLibrary if sys.platform=='win32' else _ctypes.dlclose)(dll._handle)
 print(total,'config cases passed; no power-loss/serialisability guarantee')
