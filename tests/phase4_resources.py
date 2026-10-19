"""Classify six original files/twelve binary observations, read-only.
Usage: python tests/phase4_resources.py DLL game.hunk bench.hunk DATA_ROOT JSON
Execute the actual attack-frame selector and eight-facing pointer consumer;
stop at drawshape before using the intentionally invalid resulting pointer.
"""
import ctypes,hashlib,json,re,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register
from phase2_resources import run_pure
from phase2_palettes import guarded

def offsets():
 text=(Path(__file__).parents[1]/'source/GloomBench.s').read_text(encoding='latin1')
 text=text[text.index('ob_next\trs.l'):];out={};pos=0
 for line in text.splitlines():
  m=re.match(r'(ob_\w+)\s+rs\.([bwl])\s+(\d+)',line)
  if m:
   out[m[1]]=pos;pos+=int(m[3])*{'b':1,'w':2,'l':4}[m[2]]
  if line.startswith('ob_size'):break
 assert all(n in out for n in ['ob_frame','ob_delay','ob_shape','ob_scale','ob_rot','ob_punchrate'])
 return out

def tests(dll,path,cpu,root):
 count=0;obs=[];ob=offsets()
 for name in ['baldy','demon','lizard','troll']:
  resource=root/'gloom3/objs'/name;b=resource.read_bytes()
  rot,frames,w,h,pal=struct.unpack_from('>4HI',b);entries=frames<<rot
  pointers=struct.unpack_from('>'+str(entries)+'I',b,12)
  assert rot==0 and min(pointers)==12+entries*4 and entries<48
  c=CPU(dll,path,cpu);p=register(c,b);c.w16(c.addr('g2_game_profile'),3)
  assert run_pure(c,'g2validate_anim')==0
  c.set(A2,c.addr(name));assert not guarded(c,'g2require_actor_shape')
  assert c.bytes(p,len(b))==b;count+=1
  # Real logic, with only unrelated target/collision/angle calculations hooked.
  c=CPU(dll,path,cpu);obj=0x400000;c.set(A5,obj)
  c.w16(obj+ob['ob_delay'],4 if name=='demon' else 1)
  c.w16(obj+ob['ob_punchrate'],8)
  if name=='demon':c.run('demonpause')
  else:
   c.hook('pickplayer',lambda c:c.ret(0,False))
   def collision(c):c.set(SR,c.get(SR)&~4);c.ret(0,False)
   c.hook('checkcoll',collision);c.hook('calcangle',lambda c:c.ret(0,False))
   c.run('baldypunch')
  assert c.r16(obj+ob['ob_frame'])==5;count+=1
  targets=[]
  for facing in range(8):
   c=CPU(dll,path,cpu);p=register(c,b);c.set(A5,obj)
   c.w32(obj+ob['ob_shape'],p);c.w16(obj+ob['ob_frame'],5);c.w16(obj+ob['ob_scale'],256)
   c.hook('calcangle2',lambda c,f=facing:c.ret(f*32-16,False))
   actual=[];c.hook('drawshape',lambda c:(actual.append(c.get(A0)),c.ret(0,False)))
   c.run('drawshape_8');index=40+facing;word=struct.unpack_from('>I',b,12+4*index)[0]
   assert actual==[(p+word)&0xffffffff]
   targets.append({'index':index,'table_entry_exists':index<entries,'consumed_long_hex':f'{word:08x}'})
   count+=1
  others=[]
  for profile,folder in [('gloom','objs'),('deluxe','objs'),('massacre','char')]:
   other=root/profile/folder/name
   if other.is_file():
    raw=other.read_bytes()
    # These actor files are uncompressed; do not guess metadata for CrM.
    if raw[:4] not in [b'CrM!',b'CrM2']:
     r,n=struct.unpack_from('>HH',raw);others.append({'resource':other.relative_to(root).as_posix(),'rot':r,'frames':n,'flat_entries':n<<r})
  obs.append({'profile':'Gloom 3','resource':resource.relative_to(root).as_posix(),'binary':Path(path).name,'file_bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),
   'expected_format':'animation header + flat frame*8+facing table + bounded shapes/palette',
   'actual_header':{'rotation_shift':rot,'frames':frames,'width':w,'height':h,'palette_offset':pal,'flat_entries':entries,'first_shape':min(pointers)},
   'rejecting_condition':f'g2require_actor_shape: {entries} < 48',
   'consumer':'baldypunch/demonpause choose frame 5; drawshape_8 reads 12+(40..47)*4',
   'cause':'table ends where first shape starts; missing entries are shape/pixel words, not hidden pointers',
   'classification':'B: correct rejection for this actual consumer; C: intended original frame mapping remains unverified',
   'attack_targets':targets,'other_profiles':others})
 for profile in ['gloom3','massacre']:
  resource=root/profile/'txts/test';b=resource.read_bytes();rot,n,w,h,pal,shape=struct.unpack_from('>4HII',b)
  assert (rot,n,w,h,pal,shape)==(0,1,320,255,81624,16)
  handles=struct.unpack_from('>4H',b,shape);assert handles==(1,254,320,255)
  assert shape+8+w*h==pal and pal+2<=len(b)
  c=CPU(dll,path,cpu);p=register(c,b);assert run_pure(c,'g2validate_texture')==0xffffffff
  assert c.bytes(p,len(b))==b;count+=1
  obs.append({'profile':'Gloom 3' if profile=='gloom3' else 'Zombie Massacre','resource':resource.relative_to(root).as_posix(),'binary':Path(path).name,
   'file_bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),
   'expected_format':'palette offset long + 1..20 complete 4160-byte texture columns + palette',
   'actual_header':{'format':'single animation-shaped graphic','rotation_shift':rot,'frames':n,'width':w,'height':h,'palette_offset':pal,'shape_offset':shape,'handles':handles[:2]},
   'rejecting_condition':'g2validate_texture: first long 1 < 4164',
   'consumer':'texture loader reads first long as palette offset; rendering assumes complete 64*65 columns',
   'cause':'different file format; not a truncated texture column',
   'classification':'B: correct rejection in texture path; standalone sprite usability is not asserted'})
 print(Path(path).name,'CPU',cpu,':',count,'original-resource consumer cases passed')
 return count,obs

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 total=0;rows=[]
 for path in sys.argv[2:4]:
  reference=None
  for cpu in [4,6,9]:
   count,obs=tests(dll,path,cpu,Path(sys.argv[4]));total+=count
   if reference is None:reference=obs
   else:assert obs==reference
  rows.extend(reference)
 assert len(rows)==12 and len({x['resource'] for x in rows})==6
 assert len({x['sha256'] for x in rows})==5
 Path(sys.argv[5]).write_text(json.dumps({'unique_pathnames':6,'unique_file_hashes':5,'binary_observations':12,'observations':rows},indent=2)+'\n')
 print(total,'Phase 4 resource consumer cases passed; six pathnames/five hashes/twelve classified observations')
