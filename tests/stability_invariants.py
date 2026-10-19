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
# 2.5.0 replaces single instructions by same-size jumps (menu flicker fixes,
# Gloom 3/ZM resources), widens the P96 glyph cache (gr_14 equates) and
# carries the 2.5.0 version text (gr_18).
# Reverting exactly these documented lines must give the audited module.
REVERT_250={
 'gr_02_menu_trainer.s':[(r'\tjsr\tg2menu_exit_to_game\t[^\n]*\n\tbra\.s\t\.findone\n\tdcb\.w\t14,\$4e71\t[^\n]*\n',
   '\tjsr\tdispoff\n\tjsr\tfinitmenu\n\tjsr\tg2v190aj_restore_game_palette\n\tjsr\tg2resolution_apply_after_menu\n\tjsr\tpredrawall\n\tjsr\tdispon\n')],
 'gr_11_kalm_c2p_grey_menu.s':[(r'\tjmp\tg2menu_grey_backdrop\t[^\n]*','\tmovem.l\td0-d7/a0-a6,-(a7)'),
   (r'\tdcb\.w\t3,\$4e71\t; ex-flickering[^\n]*','\tcmp\t#2,g2display_mode')],
 'gr_13_p96_menu_native.s':[(r'\tjsr\tg2menu_restore_(skip|curropt)\t[^\n]*','\tjsr\tg2p96_menu_restore_current_row_dispatch_c87b78p'),
   (r'\tjsr\tg2menu_stage_publish_gate\t[^\n]*','\tjsr\tg2p96_gameplay_copy_stage_to_draw_target')],
 'gr_14_p96_static_intermission.s':[(r'\tjsr\tg2menu_restore_(skip|curropt)\t[^\n]*','\tjsr\tg2p96_menu_restore_current_row_dispatch_c87b78p'),
   (r'p96menu_glyph_width\tequ\t9','p96menu_glyph_width\tequ\t8'),(r'p96menu_glyph_bytes\tequ\t90','p96menu_glyph_bytes\tequ\t80'),
   (r'p96menu_glyph_cache_bytes\tequ\t3600','p96menu_glyph_cache_bytes\tequ\t3200')],
 'gr_18_p96_requester_core.s':[(r"'Gloom Reforged 2\.5\.0 uses native direct-indexed'","'Gloom Reforged 2.4.0 uses native direct-indexed'"),
   (r"'2\.5\.0 c87b84c'","'2.4.0 c87b84b'"),(r"'Gloom Reforged v2\.5\.0'","'Gloom Reforged v2.4.0'")],
 'gr_21_p96_clut_backend.s':[(r'\tjmp\tg2menu_clut_apply_entry\t[^\n]*','\tmovem.l\td1-d2/a0-a2/a6,-(a7)\n\tmoveq\t#0,d0'),
   (r'\tjsr\tg2menu_overlay_cached\t[^\n]*','\tjsr\tg2p96_clut_overlay_menu_lut_c87b78y')],
}
def released(path):
    text=current(path)
    for pat,orig in REVERT_250.get(Path(path).name,[]):
        text,n=re.subn(pat,orig.replace('\\','\\\\'),text);assert n,(path,pat)
    return text
def same_as(path,base=BASE):
    if Path(path).name in REVERT_250:return instructions(released(path))==instructions(old(path,base))
    return current(path)==old(path,base)
unchanged=[2,4,5,6,11,13,15,16,17,18,19,20,21,22,23,25,27,29]
for n in unchanged:
    p=next(p for p in modules if p.name.startswith(f'gr_{n:02}_'))
    path=p.relative_to(ROOT).as_posix();assert same_as(path),p.name
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
    path=f.relative_to(ROOT).as_posix();assert same_as(path,PHASE1),f.name
print('3 additional complete Phase 1 modules: unchanged (including P96 buffer ownership)')
print(len(REVERT_250),'modules differ only by the documented 2.5.0 same-size hooks')
p='source/modular/gr_07_slow_subs_assets.s'
assert instructions(body(current(p),'pokepal_os'))==instructions(body(old(p),'pokepal_os'))
bench=current('source/GloomBench.s');prior=old('source/GloomBench.s')
names=re.findall(r'^(g2bench2_\w+)(?:\s|$)',prior,re.M)
def bench_block(name):
    text=body(bench,name)
    # 2.5.0 changes only the version texts of the benchmark blocks
    for a,b in (('c87b84c-perf2','c87b84b-perf2'),('REFORGED 2.5.0','REFORGED 2.4.0'),('Reforged v2.5.0','Reforged v2.4.0')):text=text.replace(a,b)
    return text
for name in names:assert instructions(bench_block(name))==instructions(body(prior,name)),name
print(len(names),'benchmark blocks: unchanged')
for module,label in [('gr_10_p96_native_display.s','loadtxts'),('gr_10_p96_native_display.s','allocmem_'),('gr_09_menus_config_displayselect.s','loadfile_'),('gr_08_serial_gameflow.s','rbf'),('gr_07_slow_subs_assets.s','pokepal_aga'),('gr_14_p96_static_intermission.s','g2p96_gameplay_dbuf_flip'),('gr_14_p96_static_intermission.s','g2p96_gameplay_dbuf_suspend_primary'),('gr_14_p96_static_intermission.s','g2p96_gameplay_dbuf_free')]:
    assert instructions(body(current('source/modular/'+module),label))==instructions(body(bench,label)),label
print('8 shared corrected routine blocks: game/benchmark match')
source=ROOT/'source';entries=re.findall(r'include\s+"([^"]+)"',current('source/GloomReforged_Modular.s'),re.I)
assert len(entries)==40 and len(set(entries))==40	# 2.5.0: + gr_46, gr_54, gr_55
bench_only=[e for e in re.findall(r'include\s+"(modular/[^"]+)"',current('source/GloomBench.s'),re.I) if e not in entries]
manifest=source/'modular/SHA256SUMS.txt'
if manifest.exists():
    records=[l.split('  ',1) for l in manifest.read_text().splitlines() if l.strip()]
    for digest,path in records:assert hashlib.sha256((source/path).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==digest,path
    assert set(entries+bench_only+['GloomReforged_Modular.s','GloomBench.s'])=={path for _,path in records}
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
