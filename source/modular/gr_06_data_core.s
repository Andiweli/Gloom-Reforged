;************** DATA ***************************

data

active	dc.l	0	;is game input active?
temppal	dc.l	0
todb	dc.l	0
topokepal	dc.l	0
gloomcfg	dc.l	0
gloom	dc.l	0 ;incbin	title
gloompal	dc.l	0 ;incbin	title.pal
gloombrush	dc.l	0 ;AGA/P96 legacy overlay only
g2ecs_fast_title_base	dc.l	0	;Fast-EHB clean title used by ABOUT
g2ecs_fast_title_base_pal	dc.l	0
g2ecs_fast_assets_enabled	dc	0	;dataset follows the editor Fast-EHB contract
	even

panel	dc.l	0
gunpic	dc.l	0	;v20 optional misc/gun first-person weapon shape table
g2gun_firetimer	dc	0	;v65 short muzzle/firing-frame timer
g2gun_recoilflag	dc.b	0	;v68 nonzero while firing/recoil frame is active
	even
g2hud_pending	dc	0	;v190hx6 non-fullscreen HUD needs a late full-width C2P pass
g2hud_force_draw	dc	0	;v190hx6 force showstats during the late HUD pass
g2hud_pending_player	dc.l	0	;v190hx6 player pointer for deferred HUD draw
g2teleport_blackout	dc	0	;v103 black screen shown between teleport pixel effect and intermission
g2teleport_black_hold	dc	0	;v105 black hold countdown before intermission
g2teleport_black_finish	dc	0	;v105 delayed finished code after black hold
panelcnt	dc.l	0	;non zero = do c2p for panel.
offset	dc.l	0	;planar bitmap offset

os	dc	os_
aga	dc	aga_

bitplanes	dc	0
colours	dc	0
linemod	dc	0
linemodw	dc	320
bpmod	dc	0
bpmodw	dc	40

bmaphite	dc	240,0
bmapmem	dc.l	0

chunkymod	dc	0
chunkymodw	dc	320	;v44: fullscreen game render width by default
planar_c2p	dc.l	0	;routines!
c2p	dc.l	0	;the biggy
chunky	dc.l	0	;chunky buffer
bitmaps	dc.l	0	;bitmap memory
bitmaps2	dc.l	0	;second bitmap
showbitmap	dc.l	0	;bitmap displayed
drawbitmap	dc.l	0	;used bitmap
	;
magic	dc.l	0
magicpal	dc.l	0
combat	dc.l	0
combatpal	dc.l	0
	;
gloomdata	dc	0	;non-zero = datadisk there!
cheat	dc	0	;cheat mode on?
fontw	dc	0
fonth	dc	0
mode	dc	0
chatok	dc	0

lastgrunt	dc.l	0

grunttable	dc.l	gruntsfx,gruntsfx2,gruntsfx3,gruntsfx4

splatsfx	dc.l	0
diesfx	dc.l	0
footstepsfx	dc.l	0
doorsfx	dc.l	0
tokensfx	dc.l	0
gruntsfx	dc.l	0
gruntsfx2	dc.l	0
gruntsfx3	dc.l	0
gruntsfx4	dc.l	0
	;
shootsfx	dc.l	0
shootsfx2	dc.l	0
shootsfx3	dc.l	0
shootsfx4	dc.l	0
shootsfx5	dc.l	0
telesfx	dc.l	0
ghoulsfx	dc.l	0
lizsfx	dc.l	0
lizhitsfx	dc.l	0
trollsfx	dc.l	0
trollhitsfx	dc.l	0
robotsfx	dc.l	0
robodiesfx	dc.l	0
dragonsfx	dc.l	0

chipzero	dc.l	0

outhand	dc.l	0

	;starting positions!
	;
p1x	dc	0
p1z	dc	0
p1r	dc	0
	dc	0

p2x	dc	0
p2z	dc	0
p2r	dc	0
	dc	0

p1health	dc	0
p1weapon	dc	0
p1lives	dc	0
p1reload	dc	0

p2health	dc	0
p2weapon	dc	0
p2lives	dc	0
p2reload	dc	0

map_test	dc.l	0

	ifne	cd32
gloomgame	dc.l	gloomgame2
	elseif
gloomgame	dc.l	0
	endc

script	dc.l	0
scriptat	dc.l	0
minbpos	dc	0
maxbpos	dc	0
finished	dc	0
finished2	dc	0
	;
floorflag	dc	1	;-1 = (black), 0 = split, 1=txt 
roofflag	dc	1
	;
floorflag2	dc	-1
roofflag2	dc	-1
	;
floor	dc.l	0
roof	dc.l	0
	;
	dc	0
paused	dc	$ff00
gametype	dc	0	;0,1,2
linked	dc	0	;linked, 2 player modem game
twowins	dc	0,0
	;
font	dc.l	0
bigfont_	dc.l	0
smallfont_	dc.l	0
	;
	cnop	0,4

thermo	dc	0	;thermograph
infra	dc	0	;infrared
	;
maptable	dc.l	0
sqr	dc.l	sqrinc
darktable	dc.l	0
inlist	dc.l	0
inlistf	dc.l	inlist
outlist	dc.l	0
outlistf	dc.l	outlist

window	dc.l	0
dummy	dc.l	0

player_	dc.l	0	;current player!

; c54: saved render globals while drawing the 2P chunky split probe.
g2twop_saved_chunky	dc.l	0
g2twop_saved_offset	dc.l	0
g2twop_saved_width	dc	0
g2twop_saved_hite	dc	0
g2twop_saved_chunkymodw	dc	0
g2twop_saved_minx	dc	0
g2twop_saved_maxx	dc	0
g2twop_saved_miny	dc	0
g2twop_saved_maxy	dc	0
g2twop_view_width	dc	0	;c86l selected physical crop width per split half
g2twop_restore_pending	dc	0
g2twop_crop_mode	dc	0	;c86l nonzero while 2P renders like gloom.s crop/window path
; c86n TWO PLAYER menu full-C2P temporary globals
g2menu_saved_chunky	dc.l	0
g2menu_saved_offset	dc.l	0
g2menu_saved_width	dc	0
g2menu_saved_hite	dc	0
g2menu_saved_chunkymodw	dc	0
g2menu_saved_minx	dc	0
g2menu_saved_maxx	dc	0
g2menu_saved_miny	dc	0
g2menu_saved_maxy	dc	0

player1	dc.l	0
player2	dc.l	0
doneflag	dc	0
showflag	dc	0
memory	dc.l	0
memat	dc.l	0
shapelist	dc.l	0
bitmap	dc.l	0

planar_palette	dc.l	0
planar_remap	dc.l	0

palette	dc.l	palettes

palettes	ds.l	16	;16 shade palettes 
			;each 256 bytes long.
map_map	dc.l	0
map_grid	dc.l	0
map_poly	dc.l	0
map_ppnt	dc.l	0
map_rgbs	dc.l	0	;pointer to current RGB
map_txts	dc.l	0
map_anim	dc.l	0
map_events	dc.l	0

rgb_info	dc.l	0
rgb_rgbs	dc.l	0
	;
map_rgbsat	dc.l	0
map_rgbsat2	dc.l	0
map_rgbsfrom	dc.l	0
map_rgbsfrom2	dc.l	0
remapped	dc.l	0
	;
camx	dc	0
camz	dc	0
camy	dc	0
camr	dc	0

	;camera matrix...
cm1	dc	$7ffe
cm2	dc	0
cm3	dc	0
cm4	dc	$7ffe

	;inverse of camera matrix...
icm1	dc	$7ffe
icm2	dc	0
icm3	dc	0
icm4	dc	$7ffe

castrots	dc.l	castrotsinc+8*160
camrots	dc.l	camrotsinc
camrots2	dc.l	camrots2inc

vertdraws	dc.l	0

; c87w1: active source geometry. AGA, ECS, TWO PLAYER and non-WIDE P96 stay 320.
g2render_width	dc	320
g2render_center_x	dc	160
g2render_last_x	dc	319
g2render_stride	dc	320
g2wide_castrots	dc.l	g2wide_castrots_table+8*214

width	dc	320	;v44: fullscreen default
hite	dc	240	;v190gi: fullscreen default uses former statusbar area
minx	dc	-160	;v44: fullscreen default
midx	;
maxx	dc	160	;v44: fullscreen default
miny	dc	-120	;v190gi: fullscreen default
midy	;
maxy	dc	120	;v190gi: fullscreen default
wdiv32	dc	0
wrem32	dc	0

; v190hx7: fixed-point caster state for lower VIEW SIZE full-FOV render.
g2view_cast_xfp	dc.l	0
g2view_cast_step	dc.l	256

coplist	dc.l	0
slice1	dc.l	0
slice2	dc.l	0
copstop	dc.l	0

memlist	dc.l	0

dispnest	dc	0

coloffs	ds.l	g2render_max_width	;c87w1: 428 columns capacity, active geometry remains runtime selected

iffwindow	;
	dc.l	slice1
	dc.l	copstop
	;
	dc	0	;x
	dc	42	;y
	dc	320	;w
	dc	248	;h
	dc	1	;pw
	dc	1	;ph
	;
	dc	0,0
	dc.l	0
	dc.l	0
	;
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc	0
	dc.l	0,0,0

defwindow1_1p	;
	dc.l	slice1
	dc.l	copstop
	;
	;v14: use stable gloom.s fullscreen-style game window
	dc	160-159	;fullscreen window x
	dc	cy-120	;fullscreen window y
	dc	106	;318 pixels wide at 3x3
	dc	80	;240 pixels high at 3x3
	dc	3
	dc	3
	;elseif
	;
;	dc	160-90	;disabled alternate small 1P window
;	dc	cy-90
;	dc	90
;	dc	90
;	dc	2
;	dc	2
	;elseif
	;
	dc	0,0
	dc.l	0
	dc.l	0
	;
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc	0
	dc.l	0,0,0

defwindow1_2p	;
	dc.l	slice1
	dc.l	slice2
	;
	dc	160-33*2
	dc	cy-124
	dc	66	;max width for 2 high = 90!
	dc	60
	dc	2
	dc	2
	;
	dc	0,0
	dc.l	0
	dc.l	0
	;
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc	0
	dc.l	0,0,0

defwindow2_2p	;
	dc.l	slice2
	dc.l	copstop
	;
	dc	160-33*2
	dc	cy
	dc	66
	dc	60
	dc	2
	dc	2
	;
	dc	0,0
	dc.l	0
	dc.l	0
	;
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc	0
	dc.l	0,0,0

window1	;
	dc.l	slice1
	dc.l	slice2	;copstop here for 1 window
	;
	dc	160-33*2
	dc	42
	dc	66	;max width for 2 high = 90!
	dc	60
	dc	2
	dc	2
	;
	dc	0,0
	dc.l	0
	dc.l	0
	;
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc	0
	dc.l	0,0,0

window2	;
	dc.l	slice2
	dc.l	copstop
	;
	dc	160-33*2
	dc	165
	dc	66
	dc	60
	dc	2
	dc	2
	;
	dc	0,0
	dc.l	0
	dc.l	0
	;
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc	0
	dc.l	0,0,0

bigdata

textscrns	ds.l	8	;texture screens
textures	ds.l	160	;individual txts (20/screen)

