"""Guard released render code and benchmark measurement routines against drift."""
from pathlib import Path
import hashlib,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
# Exact audited object ID (keep this independent of the current branch).
BASE='c223cf5dce87dacbfb9591a6109e02bbee0df98c'
PHASE1='d825e918241f39e62451552114aa776e6ed154f6'
def old(path,base=BASE):return subprocess.check_output(['git','show',base+':'+path],cwd=ROOT).decode('latin1').replace('\r\n','\n')
def current(path):return (ROOT/path).read_text(encoding='latin1')
def body(s,label):
    lines=s.splitlines();start=next(i for i,l in enumerate(lines) if re.match(r'^'+re.escape(label)+r'(?:\s|$)',l))
    end=next((i for i in range(start+1,len(lines)) if re.match(r'^[A-Za-z_]\w*(?:\s|$)',lines[i])),len(lines))
    return '\n'.join(lines[start:end])
def instructions(s):return [re.sub(r'\s+',' ',l.split(';')[0].strip()).lower() for l in s.splitlines() if l.split(';')[0].strip()]
modules=sorted((ROOT/'source/modular').glob('gr_*.s'))
unchanged=[2,4,5,6,11,13,15,16,17,18,19,20,21,22,23,25,27,29]
for n in unchanged:
    p=next(p for p in modules if p.name.startswith(f'gr_{n:02}_'))
    path=p.relative_to(ROOT).as_posix();assert current(path)==old(path),p.name
print('18 complete modules: unchanged (C2P, MOVE16, walls, Bayer, physics, caches, modes, automap)')
p='source/modular/gr_03_presentation_hud_weapons.s'
for name in ['predrawall','drawall','loadanobj']:
    if name=='loadanobj':continue
    assert instructions(body(current(p),name))==instructions(body(old(p),name)),name
# The six cold event/asset/morph entries keep their original assembled
# footprint as JMP+NOP stubs. All other mixed-module instructions/data agree.
now=current(p);prior=old(p,PHASE1)
for label in ['loadanobj','calcnormvec','execevent','exec_opendoor','exec_teleport','exec_addobj']:
    now=now.replace(body(now,label),'');prior=prior.replace(body(prior,label),'')
assert instructions(now)==instructions(prior),'presentation module outside cold stubs'
for n in [7,14,26]:
    f=next(x for x in modules if x.name.startswith(f'gr_{n:02}_'))
    path=f.relative_to(ROOT).as_posix();assert current(path)==old(path,PHASE1),f.name
print('3 additional complete Phase 1 modules: unchanged (including P96 buffer ownership)')
p='source/modular/gr_07_slow_subs_assets.s'
assert instructions(body(current(p),'pokepal_os'))==instructions(body(old(p),'pokepal_os'))
bench=current('source/GloomBench.s');prior=old('source/GloomBench.s')
names=re.findall(r'^(g2bench2_\w+)(?:\s|$)',prior,re.M)
for name in names:assert instructions(body(bench,name))==instructions(body(prior,name)),name
print(len(names),'benchmark blocks: unchanged')
for module,label in [('gr_10_p96_native_display.s','loadtxts'),('gr_10_p96_native_display.s','allocmem_'),('gr_09_menus_config_displayselect.s','loadfile_'),('gr_08_serial_gameflow.s','rbf'),('gr_07_slow_subs_assets.s','pokepal_aga'),('gr_14_p96_static_intermission.s','g2p96_gameplay_dbuf_flip'),('gr_14_p96_static_intermission.s','g2p96_gameplay_dbuf_suspend_primary'),('gr_14_p96_static_intermission.s','g2p96_gameplay_dbuf_free')]:
    assert instructions(body(current('source/modular/'+module),label))==instructions(body(bench,label)),label
print('8 shared corrected routine blocks: game/benchmark match')
source=ROOT/'source';entries=re.findall(r'include\s+"([^"]+)"',current('source/GloomReforged_Modular.s'),re.I)
assert len(entries)==37 and len(set(entries))==37
manifest=source/'modular/SHA256SUMS.txt'
if manifest.exists():
    records=[l.split('  ',1) for l in manifest.read_text().splitlines() if l.strip()]
    for digest,path in records:assert hashlib.sha256((source/path).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==digest,path
    assert set(entries+['GloomReforged_Modular.s','GloomBench.s'])=={path for _,path in records}
    print(len(records),'SHA-256 entries: verified')

# Inspect all active INCBIN directives in the assembled include set. Their
# repository bytes must equal Phase 1; macros/conditional variants share files.
resources=set()
for path in entries+['GloomBench.s']:
    text=current('source/'+path)
    for line in text.splitlines():
        m=re.match(r'^\s*(?:[A-Za-z_]\w*\s+)?incbin\s+"?([^"\s;]+)',line.split(';')[0],re.I)
        if m:resources.add(m.group(1))
for path in sorted(resources):
    b=(ROOT/'source'/path).read_bytes()
    prior=subprocess.check_output(['git','show',PHASE1+':source/'+path],cwd=ROOT)
    assert b==prior,path
print(len(resources),'distinct active INCBIN assets: present and byte-identical to Phase 1')
