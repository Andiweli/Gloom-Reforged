"""Supplied profile contracts, original asset hashes and real load/cleanup prefixes.
Usage: python tests/phase3_profiles.py DLL game.hunk bench.hunk DATA_ROOT OUTPUT_JSON
OS/audio/display modelled; does not boot hardware or simulate full gameplay.
Unsupported original contracts are recorded as blocked, never passed silently.
"""
import ctypes,hashlib,json,re,struct,sys
from pathlib import Path
from asm_regression import *
from phase2_events_scripts import register
from phase2_resources import run_pure
from phase2_palettes import guarded
from phase3_profile_music import decode
from phase3_legacy_resources import pixels
import phase2_allocations as life

def contracts(dll,path,root,name,profile):
 rows=[];references=set()
 def check(p,fn,kind):
  raw=p.read_bytes();b=decode(dll,path,raw);c=CPU(dll,path);ptr=register(c,b);c.w16(c.addr('g2_game_profile'),profile);c.w16(c.addr('aga'),65535)
  ok=run_pure(c,fn)==0;normalised=False
  if ok and kind=='map/events':
   names=struct.unpack_from('>I',b,16)[0]
   references.update(x.decode('latin1') for x in b[names:].split(b'\0')[:8])
  if not ok and kind=='picture' and profile in [2,3]:
   ok=run_pure(c,'g2normalize_legacy_iff')==0
   if ok:
    assert pixels(b)==pixels(c.bytes(ptr,len(b)))
    ok=run_pure(c,fn)==0;normalised=True
  record={'resource':p.relative_to(root).as_posix(),'kind':kind,'file_bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'decoded_bytes':len(b),'accepted':ok,'normalised':normalised}
  if ok and kind=='animation' and p.name in ['player','marine','baldy','terra','ghoul','demon','phantom','lizard','deathhead','dragon','troll','tokens']:
   c.set(A2,c.addr(p.name));record['fixed_actor_references_safe']=guarded(c,'g2require_actor_shape')
  rows.append(record)
 directory=root/name
 for p in sorted((directory/('lvls' if profile==2 else 'maps')).iterdir()):
  if p.is_file() and not p.suffix:check(p,'g2validate_map','map/events')
 for p in sorted((directory/'txts').iterdir()):
  if not p.is_file() or p.suffix:continue
  if p.name.startswith(('floor','roof')):
   raw=p.read_bytes();b=decode(dll,path,raw);c=CPU(dll,path);ptr=register(c,b)
   ok=guarded(c,'g2require_tile');rows.append({'resource':p.relative_to(root).as_posix(),'kind':'tile','sha256':hashlib.sha256(raw).hexdigest(),'accepted':ok})
  else:
   check(p,'g2validate_texture','texture');rows[-1]['referenced_by_maps']=p.name in references
 for p in sorted((directory/('char' if profile==2 else 'objs')).iterdir()):
  if p.is_file() and not p.suffix:check(p,'g2validate_anim','animation')
 for p in sorted((directory/('musi' if profile==2 else 'sfxs')).iterdir()):
  if p.is_file() and p.suffix=='.bin':check(p,'g2validate_sfx','sound')
 for p in sorted((directory/('pixs' if profile==2 else 'pics')).iterdir()):
  if not p.is_file() or p.suffix:continue
  raw=p.read_bytes();b=decode(dll,path,raw)
  if len(b)>=12:
   width,height,depth=struct.unpack_from('>3H',b)
   if 0<width<=320 and width%8==0 and 0<depth<=8 and height:
    check(p,'g2validate_iff','picture')
    pal=p.with_name(p.name+'.pal')
    if pal.is_file():
     data=decode(dll,path,pal.read_bytes());needed=min(1<<depth,256)*4
     rows.append({'resource':pal.relative_to(root).as_posix(),'kind':'AGA palette','sha256':hashlib.sha256(pal.read_bytes()).hexdigest(),'accepted':len(data)>=needed,'bytes':len(data),'needed':needed})
 script=directory/('stuf/stages' if profile==2 else 'misc/script');check(script,'g2validate_script','script')
 return rows

def lifecycle(path,root,name,profile,mode):
 c,io=life.setup(path,mode,root/name);del c.hooks[c.addr('g2detectprofile')]
 # The validator/loader can now call Exec for a legacy gun copy, so OS calls
 # are stepped at boundaries rather than executing this wrapper as pure code.
 c.w32(c.addr('g2menu_entry_sp'),STACK);c.hook('exittoos',lambda c:c.ret(c.get(D0),False))
 life.run(c,'initmain');assert c.r16(c.addr('g2_game_profile'))==profile and not c.r16(c.addr('g2fatal_state')) and not io.handles
 init=len(io.blocks);init_chip=sum(bool(f&2) for n,f in io.blocks.values());life.run(c,'freememlist');assert not io.blocks
 return {'profile':name,'mode':mode,'binary':Path(path).name,'startup_blocks':init,'startup_chip_requests':init_chip,'peak_blocks':io.peak,'peak_header_extra':16*io.peak,'successful_allocations':io.total}

if __name__=='__main__':
 dll=ctypes.CDLL(str(Path(sys.argv[1]).absolute()));dll.test_get.restype=ctypes.c_uint
 game,bench=sys.argv[2:4];root=Path(sys.argv[4]);results=[];boots=[]
 for name,profile in [('gloom',1),('deluxe',0),('gloom3',3),('massacre',2)]:
  a=contracts(dll,game,root,name,profile);b=contracts(dll,bench,root,name,profile);assert a==b
  results.extend(a)
  rejected=[x for x in a if not x['accepted'] or x.get('fixed_actor_references_safe')==False]
  print(name,len(a),'contracts x2; blocked:',json.dumps(rejected),flush=True)
  for path in [game,bench]:
   for mode in ['AGA','P96']:
    row=lifecycle(path,root,name,profile,mode);boots.append(row);print(json.dumps(row),flush=True)
 Path(sys.argv[5]).write_text(json.dumps({'assets':results,'startups':boots},indent=2)+'\n')
 print(len(results)*2,'original asset contract observations;',len(boots),'startup/free scenarios passed; see blocked contracts in JSON')
