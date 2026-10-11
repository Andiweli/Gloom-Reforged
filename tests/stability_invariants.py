"""Guard released render code and benchmark measurement routines against drift."""
from pathlib import Path
import hashlib,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
# Exact audited object ID (keep this independent of the current branch).
BASE='c223cf5dce87dacbfb9591a6109e02bbee0df98c'
def old(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT).decode('latin1').replace('\r\n','\n')
def current(path):return (ROOT/path).read_text(encoding='latin1')
def body(s,label):
    lines=s.splitlines();start=next(i for i,l in enumerate(lines) if re.match(r'^'+re.escape(label)+r'(?:\s|$)',l))
    end=next((i for i in range(start+1,len(lines)) if re.match(r'^[A-Za-z_]\w*(?:\s|$)',lines[i])),len(lines))
    return '\n'.join(lines[start:end])
def instructions(s):return [re.sub(r'\s+',' ',l.split(';')[0].strip()).lower() for l in s.splitlines() if l.split(';')[0].strip()]
modules=sorted((ROOT/'source/modular').glob('gr_*.s'))
unchanged=[2,4,5,6,11,12,13,15,16,17,18,19,20,21,22,23,25,27,29]
for n in unchanged:
    p=next(p for p in modules if p.name.startswith(f'gr_{n:02}_'))
    path=p.relative_to(ROOT).as_posix();assert current(path)==old(path),p.name
print('19 complete modules: unchanged (C2P, MOVE16, walls, Bayer, physics, caches, modes, automap)')
p='source/modular/gr_03_presentation_hud_weapons.s'
for name in ['predrawall','drawall','loadanobj']:
    if name=='loadanobj':continue
    assert instructions(body(current(p),name))==instructions(body(old(p),name)),name
# Remove the one authorised cold loading routine before comparing the whole
# mixed presentation/weapon/event module, including ADDX/Carry instructions.
assert current(p).replace(body(current(p),'loadanobj'),'')==old(p).replace(body(old(p),'loadanobj'),'')
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
assert len(entries)==32 and len(set(entries))==32
manifest=source/'modular/SHA256SUMS.txt'
if manifest.exists():
    records=[l.split('  ',1) for l in manifest.read_text().splitlines() if l.strip()]
    for digest,path in records:assert hashlib.sha256((source/path).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==digest,path
    assert set(entries+['GloomReforged_Modular.s','GloomBench.s'])=={path for _,path in records}
    print(len(records),'SHA-256 entries: verified')
