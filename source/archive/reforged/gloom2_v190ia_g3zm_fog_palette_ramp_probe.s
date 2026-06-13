
 	;*********
	;* GLOOM *
	;*********
	;
	;planar, 020+ version.
	;
	;6 bitplanes for ECS, 8 for AGA
	;
	;error codes
	;
	;red - allocmem failed
	;yel - freemem failed
	;orange - unknown script command
	;purp - unknown event command
	;cyn - can't open file in loadfile
	;blu - ran out of remap colours!

aga_	equ	-1
os_	equ	-1

testw	equ	128
testh	equ	128

cd32	equ	0	;cd32 version?
combatok	equ	-1	;include combat game?
ok	equ	750+125	;overkill level!
cy	equ	166

pl_eyey	equ	110
pl_firey	equ	60
pl_gutsy	equ	64

debugser	equ	0
debugmem	equ	0
	;
ireload	equ	5	;initial reload val.
maxobjects	equ	256	;max objects in game
maxdoors	equ	16	;max doors opening at once
maxblood	equ	128	;max droplets of bluuurd
maxgore	equ	128	;body parts on ground!
maxrotpolys	equ	32	;max rotating thingys.
	;
focshft	equ	7
grdshft	equ	8
darkshft	equ	7	;smaller=smaller range=faster!
maxz	equ	16<<darkshft	;16*128=2048*8=16384
g2deffogfar	equ	8<<grdshft	; v190fc: shared darktable cap; DEFAULT keeps original range, ADVANCED scales to it
g2advviewfar	equ	16<<grdshft	; v190fc: ADVANCED actual view/fog range = 16 texture widths
g2advshapez	equ	16<<grdshft	; v190fc: ADVANCED strips/objects match the 16-width range
	;
exshft	equ	3
exone	equ	1<<exshft
exhalf	equ	exone>>1

	jmp	entrypoint

	rsreset
	;
	;rotpoly details...
	;
rp_next	rs.l	1
rp_prev	rs.l	1
	;
rp_speed	rs.w	1
rp_rot	rs.w	1
rp_flags	rs.w	1	;what to do?
	;
rp_cx	rs.w	1	;only for rot
rp_cz	rs.w	1
rp_first	rs.l	1	;pointer to first!
rp_num	rs.w	1
	;
rp_vx	rs.w	0
rp_lx	rs.w	1
rp_vz	rs.w	0
rp_lz	rs.w	1
rp_ox	rs.w	0
rp_na	rs.w	1
rp_oz	rs.w	0
rp_nb	rs.w	1
	;
rp_more	rs.b	8*31	;=32 max verts!
	;
rp_size	rs.b	0

	rsreset
	;
	;sfx channel info
	;
fx_status	rs.w	1
fx_priority	rs.w	1
fx_sfx	rs.l	1
fx_vol	rs.w	1
fx_offset	rs.w	1
fx_dma	rs.w	1
fx_int	rs.w	1
	;
fx_size	rs.b	0

	rsreset
	;
	;blood!
	;
bl_next	rs.l	1
bl_prev	rs.l	1
bl_x	rs.l	1
bl_y	rs.l	1
bl_z	rs.l	1
bl_xvec	rs.l	1
bl_dest	rs.l	0
bl_yvec	rs.l	1
bl_zvec	rs.l	1
bl_color	rs.l	1	;colour and!
	;
bl_size	rs.b	0

	rsreset
	;
	;a texture
	;
te_pal	rs.l	1
	;
te_size	rs.b	0

	rsreset
	;
	;an opening/closing door!
	;
do_next	rs.l	1
do_prev	rs.l	1
do_poly	rs.l	1	;door polygon
do_lx	rs.w	1
do_lz	rs.w	1
do_rx	rs.w	1
do_rz	rs.w	1
do_frac	rs.w	1
do_fracadd	rs.w	1
	;
do_size	rs.b	0

	rsreset
	;
	;wall list...
	;
wl_next	rs.l	1
wl_lsx	rs.w	1	;leftmost screen X
wl_rsx	rs.w	1	;rightmost screen X
wl_nz	rs.w	1	;near Z!
wl_fz	rs.w	1	;far Z!
wl_lx	rs.w	1
wl_lz	rs.w	1
wl_rx	rs.w	1
wl_rz	rs.w	1
wl_a	rs.w	1
wl_b	rs.w	1
wl_c	rs.l	1
wl_sc	rs.w	1
wl_open	rs.w	1	;0=door shut, $4000=open!
wl_t	rs.b	8	;textures
	;
wl_size	rs.b	0

	rsreset
	;
	;a zone...
	;
zo_done	rs.w	1
zo_lx	rs.w	1
zo_lz	rs.w	1
zo_rx	rs.w	1
zo_rz	rs.w	1
	;
zo_a	rs.w	1
zo_b	rs.w	1
zo_na	rs.w	1
zo_nb	rs.w	1
zo_ln	rs.w	1
	;
zo_t	rs.b	8	;8 textures
	;
zo_sc	rs.w	1	;scale (how many txts on wall)
zo_open	rs.w	0	;for wall polys...
zo_ev	rs.w	1	;for events...
	;
zo_size	rs.b	0	;32!

	rsreset
	;
	;a shape to draw!
	;
sh_next	rs.l	1
sh_prev	rs.l	1
sh_x	rs.w	1
sh_y	rs.w	1
sh_z	rs.w	1
sh_shape	rs.l	1
sh_scale	rs.w	0
sh_strip	rs.l	1
sh_render	rs.l	1	;drawobjnorm or drawobjinvs
	;
sh_size	rs.b	0

	rsreset
	;
	;gore...body parts lying around!
	;
go_next	rs.l	1
go_prev	rs.l	1
go_x	rs.w	1
go_z	rs.w	1
go_shape	rs.l	1
	;
go_size	rs.b	0

	rsreset
	;
	;an object in the game (player/alien etc...)
	;
ob_next	rs.l	1
ob_prev	rs.l	1
ob_x	rs.l	1
ob_y	rs.l	1
ob_z	rs.l	1
ob_rot	rs.l	1
	;
	;start of info load by prog.
ob_info	rs.b	0
	;
ob_rotspeed	rs.l	1
ob_movspeed	rs.l	1
ob_shape	rs.l	1
ob_logic	rs.l	1
ob_render	rs.l	1
ob_hit	rs.l	1	;routine to do when damaged
ob_die	rs.l	1	;routine to do when killed
ob_eyey	rs.w	1	;eye height
ob_firey	rs.w	1	;where bullets come from
ob_gutsy	rs.w	1
ob_mega	rs.w	0
ob_othery	rs.w	1
ob_colltype	rs.w	1
ob_collwith	rs.w	1
ob_cntrl	rs.w	1
ob_damage	rs.w	1
ob_hitpoints	rs.w	1
ob_think	rs.w	1
ob_frame	rs.l	1	;anim frame
ob_framespeed	rs.l	1	;anim frame
ob_base	rs.w	1
ob_range	rs.w	1
ob_weapon	rs.w	1	;weapon meter (0...4)
ob_reload	rs.b	1	;weapon reload timer
ob_reloadcnt	rs.b	1	;counter
ob_hurtpause	rs.w	1
ob_firerate	rs.w	0
ob_punchrate	rs.w	1
ob_bouncecnt	rs.w	1	;how many times my bullets bounce!
ob_firecnt	rs.w	0
ob_something	rs.w	1
ob_scale	rs.w	1	;scale factor for drawing
ob_lastbut	rs.w	1
ob_blood	rs.w	1	;color AND for blood
ob_ypad	rs.w	1
	;
ob_oldlogic	rs.l	1
ob_oldlogic2	rs.l	1
ob_oldhit	rs.l	1
ob_olddie	rs.l	1
ob_oldrot	rs.w	1
ob_newrot	rs.w	1
ob_yvec	rs.l	1
ob_xvec	rs.l	1
ob_zvec	rs.l	1
ob_radsq	rs.l	1	;radius squared
ob_rad	rs.w	1
ob_delay	rs.w	1
ob_delay2	rs.w	0
ob_bounce	rs.w	1
ob_hurtwait	rs.w	1
	;
ob_washit	rs.l	1	;flag for un-hit coll detect!
ob_window	rs.l	1	;pointer back to window!
ob_nxvec	rs.w	0	;normalized X vec
ob_lives	rs.w	1
ob_nzvec	rs.w	0	;normalized z vec
ob_infra	rs.w	1
ob_thermo	rs.w	1
ob_invisible	rs.w	1
ob_hyper	rs.w	1
ob_update	rs.w	1	;update stats!
ob_mess	rs.l	1	;message
ob_messlen	rs.w	1
ob_messtimer	rs.w	1	;timer for messages
ob_palette	rs.l	1	;palette for window
ob_paltimer	rs.w	1	;timer before back to normal
ob_pixsize	rs.w	1
ob_pixsizeadd	rs.w	1
ob_telex	rs.w	1
ob_telez	rs.w	1
ob_telerot	rs.w	1
ob_chunks	rs.l	1
	;
ob_size	rs.b	0

	rsreset
	;
	;solid wall draw data
	;
vd_z	rs.w	1	;current Z
vd_pal	rs.w	1	;palette# (0...15)
vd_y	rs.w	1
vd_h	rs.w	1
vd_data	rs.l	1
vd_ystep	rs.l	1
	;
vd_size	rs.b	0

	rsreset
	;
	;palette file...
	;
pa_numcols	rs.w	1	;how many colours
pa_cols	rs.w	256	;the colours!

	rsreset
	;
	;anim file...
	;
an_rotshft	rs.w	1
an_frames	rs.w	1
an_maxw	rs.w	1
an_maxh	rs.w	1
an_pal	rs.l	1
	;
an_size	rs.b	0

	rsreset
	;
	;window
	;
wi_slice	rs.l	1	;slice window appears in!
wi_nslice	rs.l	1	;next slice to disp.
wi_x	rs	1
wi_y	rs	1
wi_w	rs	1	;how many chixels across
wi_h	rs	1	;how many down
wi_pw	rs	1	;width of 1 chixel
wi_ph	rs	1	;hite of 1 chixel
	;
wi_bw	rs	1	;bitmap width
wi_bh	rs	1	;bitmap height
	;
wi_bmapmem	rs.l	1
wi_copmem	rs.l	1
wi_bmap	rs.l	1
wi_cop	rs.l	1
wi_cop1	rs.l	1
wi_cop2	rs.l	1
wi_chunkymodw	rs.w	1
	;
wi_strip	rs.l	1
wi_iff	rs.l	1	;show iff instead!
wi_pal	rs.l	1	;palette for IFF!
	;
wi_size	rs.b	0

key	macro
	btst	#\1&7,\1>>3(a0)
	endm

keya1	macro
	btst	#\1&7,\1>>3(a1)
	endm

qkey	macro
	move.l	rawtable,a0
	key	\1
	endm

freemem	macro
	;
	ifne	debugmem
	lea	.fmem\@,a0
	jsr	freemem_
	bra	.fmemskip\@
.fmem\@	dc.b	'\1',0
	even
.fmemskip\@	;
	elseif
	jsr	freemem_
	endc
	;
	endm

allocmem	macro
	;
	ifne	debugmem
	;
	lea	.amem\@,a0
	jsr	allocmem_
	bra	.amemskip\@
.amem\@	dc.b	'\1',10,0
	even
.amemskip\@	;
	elseif
	;
	jsr	allocmem_
	;
	endc
	;
	endm

allocmem2	macro
	;
	ifne	debugmem
	;
	lea	.amem\@,a0
	jsr	allocmem2_
	bra	.amemskip\@
.amem\@	dc.b	'\1',10,0
	even
.amemskip\@	;
	elseif
	;
	jsr	allocmem2_
	;
	endc
	;
	endm

alloclist	macro	;alloclist listname,maxitems,itemsize
	;
	move.l	\2,d0
	move.l	\3,d1
	lea	\1(pc),a2
	jsr	k_alloclist
	bra.s	alskip\@
	;
\1	dc.l	0	;0
\1_last	dc.l	0	;4
	dc.l	0	;8
\1_free	dc.l	0	;12
alskip\@	;
	endm

k_alloclist	;a2=address of 'first' pointer
	;d0=max items, d1=item size
	;
	move.l	a2,8(a2)	;clear out used list
 	lea	4(a2),a0
	clr.l	(a0)
	move.l	a0,(a2)
	movem.l	d0-d1,-(a7)
	mulu	d1,d0
	move.l	#$10001,d1
	allocmem	alloclist
	move.l	d0,a0
	lea	12(a2),a2
	movem.l	(a7)+,d0-d1
	subq	#1,d0
.loop	move.l	a0,(a2)
	move.l	a0,a2
	add	d1,a0
	dbf	d0,.loop
	rts

addnext	macro
	;
	;addnext 'listname'
	;add after a5
	;return eq if none available else a0
	;
	move.l	\1_free,d0
	beq.s	.anskip\@
	move.l	d0,a0
	move.l	(a0),\1_free
	move.l	(a5),a1
	move.l	a1,(a0)
	move.l	a0,4(a1)
	move.l	a0,(a5)
	move.l	a5,4(a0)
.anskip\@	;
	endm

addfirst	macro
	;
	;addfirst 'listname'
	;return eq if none available else a0
	;
	move.l	\1_free,d0
	beq.s	.afskip\@
	move.l	d0,a0
	move.l	(a0),\1_free
	move.l	\1,a1	;current first
	move.l	a1,(a0)
	move.l	a0,4(a1)
	move.l	a0,\1
	move.l	#\1,4(a0)
.afskip\@	;
	endm

addlast	macro
	;
	;addlast 'listname'
	;return eq in none available else a0
	;
	move.l	\1_free,d0
	beq.s	.alskip\@
	move.l	d0,a0
	move.l	(a0),\1_free
	;
	move.l	\1_last+4,a1	;current last
	move.l	a0,(a1)
	move.l	a1,4(a0)
	move.l	a0,\1_last+4
	move.l	#\1_last,(a0)
.alskip\@	;
	endm

killitem	macro
	;
	;killitem listname
	;a0=item to kill, return a0=previous item.
	;
	move.l	(a0),a1	;next of me!
	move.l	4(a0),4(a1)
	move.l	4(a0),a1	;prev of me
	move.l	(a0),(a1)
	move.l	\1_free,(a0)
	move.l	a0,\1_free
	move.l	a1,a0
	endm
	
clearlist	macro
	;
	;clearlist listname
	;
.clloop\@	move.l	\1,a0
	tst.l	(a0)
	beq	.cldone\@
	killitem	\1
	bra	.clloop\@
.cldone\@	;
	endm

zerolist	macro	listname,size of item
	;
	;fill all list items with 0!
	;
	clearlist	\1
.zlloop\@	addlast	\1
	beq	.zlskip\@
	lea	8(a0),a1
	moveq	#0,d0
	move	#(\2-8)/2-1,d1
.zlloop2\@	move	d0,(a1)+
	dbf	d1,.zlloop2\@
	bra	.zlloop\@
.zlskip\@	clearlist	\1
	;
	endm

bwait	macro
	;
.bwait\@	btst	#6,$dff002
	beq.s	.bwait2\@
	bra.s	.bwait\@
.bwait2\@	;
	endm

printlong	macro
	move.l	\1,-(a7)
	jsr	printlong_
	endm

check	macro
	list
check	set	*-\1
	nolist
	endm

push	macro
	movem.l	d2-d7/a2-a6,-(a7)
	endm

pull	macro
	movem.l	(a7)+,d2-d7/a2-a6
	endm

col	macro
	move	#0,$dff106
	move	\1,$dff180
	endm

warn	macro
	move	d0,-(a7)
	move	#-1,d0
.wloop\@	col	\1
	dbf	d0,.wloop\@
	move	(a7)+,d0
	endm

tempfile	ds.b	64

wbmess	dc.l	0	;workbench message!

entrypoint	;
	clr.l	map_test
	move.l	4.w,a6
	move.l	276(a6),a5	;task
	tst.l	$ac(a5)	;cli?
	bne.s	cli
	;
	lea	$5c(a5),a0
	jsr	-384(a6)	;waitport
	lea	$5c(a5),a0
	jsr	-372(a6)	;get message
	move.l	d0,wbmess
	bra	wb
cli	;
	cmp.b	#'@',(a0)+
	bne.s	wb
	lea	tempfile,a1
	move.l	a1,map_test
.loop	move.b	(a0)+,(a1)
	beq.s	wb
	cmp.b	#10,(a1)+
	bne.s	.loop
	clr.b	-(a1)
wb	;
	lea	dosname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,dosbase
	;
	move.l	d0,a6
	jsr	-60(a6)
	move.l	d0,outhand
	jsr	g2log_open	;v22 diagnostic level/runtime log
	;
	move.l	wbmess(pc),d0
	beq.s	.nocd
	move.l	d0,a0
	move.l	$24(a0),a0
	move.l	(a0),d1
	move.l	dosbase,a6
	jsr	-126(a6)
.nocd	;
	move.l	4.w,a6
	moveq	#1,d1
	jsr	-216(a6)
	cmp.l	#$1a6548-$c000,d0 ;enough memory to run gloom?
	bcs	nomem
	;
	jsr	initmain
	jsr	g2cfg_load	;v141: load PROGDIR:gloom.cfg if present
	;
	bsr	g2v190ct_titlefont
	jsr	g2v190i_levelselect_loadscripts	; v190i: build START LEVEL list from script file before title menu
	;
	; v41x diagnostic: bigfont returned, continue to title music start.
	;
.intro	jsr	g2v190p_load_title_assets	; v190p: reload title art if gameplay freed it
	; v190go: Classic Gloom now uses embedded Gloom2 title/menu assets too,
	; so the old unsupported-profile title-music skip must not run anymore.
	move.l	medat,a1
	move.l	titlemed,d0	; v190cr: compatible installs may not have title MED
	beq.s	.g2v190cr_no_title_music
	move.l	d0,a0
	jsr	8(a1)	;start title music!
.g2v190cr_no_title_music
	;
.intro2	jsr	g2v36_clear_title_buffers	;v36: clear both OS bitmaps before returning to title menu
	jsr	dointro	;returns gametype
	; v08: previous diagnostic hold after dointro removed.
	; Continue into gametype handling after menu selection.
	;
	cmp	#3,gametype
	bcs.s	.play
	move.l	medat,a1
	jsr	12(a1)
	bra.s	exittoos
.play	;
	jsr	initnewgame
	tst	gametype
	bmi	.intro2
	jsr	g2v190p_free_title_assets	; v190p: free title art during gameplay to keep memory contiguous
	;
	;bsr	smallfont
	tst	twowins
	beq.s	.n2
	bsr	swaphflags
.n2	jsr	execscript_med
.wmf	tst	fadevol
	bne.s	.wmf
	tst	twowins
	beq.s	.n22
	bsr	swaphflags
.n22	bsr	g2v190ct_titlefont
	bra	.intro
	;
exittoos	jsr	inputoff	; v34: restore ciaa/rawkey vectors before OS exit/closewindow
	jsr	g2cfg_save	;v141: persist menu/options on clean exit
	jsr	freeobjlist2
	jsr	permit
	jsr	finitdisplay
	jsr	finitvbint
	jsr	finitsfx
	jsr	finitser
	jsr	freememlist
	ifeq	cd32
	jsr	undir
	endc
	;
nomem	move.l	wbmess(pc),d0
	beq.s	.bye
	;
	move.l	4.w,a6
	move.l	d0,a1
	jsr	-378(a6)
	clr.l	wbmess
	;
.bye	jsr	g2log_close
	rts

; ************* FAST SUBS ********************
	
fastsubs

swaphflags	movem.l	floorflag(pc),d0-d1
	move.l	d1,floorflag
	move.l	d0,floorflag2
	rts

smallfont	move	#6,fontw
	move	#8,fonth
	move.l	smallfont_,font
	rts

bigfont	move	#8,fontw
	move	#10,fonth
	move.l	bigfont_,font
	rts

; v190gl: all profiles, including Classic Gloom with embedded fallbacks,
; use the normal Gloom2 bigfont2 menu font path.
g2v190ct_titlefont
	bsr	bigfont
	rts

encodejoy	;a0=cntrl block to encode...
	;return d0 encoded
	;
	;bit:
	;0 = joyx -1
	;1 = joyx 1
	;2 = joyy -1
	;3 = joyy 1
	;4 = joyb true
	;5 = joys true
	;
	moveq	#0,d0
	;
	tst	(a0)
	beq.s	.skipx
	bpl.s	.x1
	bset	#0,d0
	bra.s	.skipx
.x1	bset	#1,d0
.skipx	tst	2(a0)
	beq.s	.skipy
	bpl.s	.y1
	bset	#2,d0
	bra.s	.skipy
.y1	bset	#3,d0
.skipy	tst	4(a0)
	beq.s	.skipb
	bset	#4,d0
.skipb	tst	6(a0)
	beq.s	.skipf
	bset	#5,d0
.skipf	;
	rts

decodejoy	;
	;d0.b = encoded byte...
	;a0 = block to fill
	;
	;0 = joyx -1
	;1 = joyx 1
	;2 = joyy -1
	;3 = joyy 1
	;4 = joyb true
	;5 = joys true
	;
	clr	(a0)
	move	d0,d1
	and	#3,d1
	beq.s	.skipx
	cmp	#1,d1
	bne.s	.x1
	move	#-1,(a0)
	bra.s	.skipx
.x1	move	#1,(a0)
.skipx	clr	2(a0)
	move	d0,d1
	and	#12,d1
	beq.s	.skipy
	cmp	#4,d1
	bne.s	.y1
	move	#-1,2(a0)
	bra.s	.skipy
.y1	move	#1,2(a0)
.skipy	btst	#4,d0
	sne	d1
	ext	d1
	move	d1,4(a0)
	btst	#5,d0
	sne	d1
	ext	d1
	move	d1,6(a0)
	rts

sfxs	;
sfx0	ds.b	fx_size
sfx1	ds.b	fx_size
sfx2	ds.b	fx_size
sfx3	ds.b	fx_size

sfxintserver0	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx0
	dc.l	sfxint

sfxintserver1	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx1
	dc.l	sfxint

sfxintserver2	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx2
	dc.l	sfxint

sfxintserver3	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx3
	dc.l	sfxint

initsfx	push
	move.l	4.w,a6
	;
	moveq	#7,d0
	lea	sfxintserver0,a1
	jsr	-162(a6)	;setintvector
	;
	moveq	#8,d0
	lea	sfxintserver1,a1
	jsr	-162(a6)
	;
	moveq	#9,d0
	lea	sfxintserver2,a1
	jsr	-162(a6)
	;
	moveq	#10,d0
	lea	sfxintserver3,a1
	jsr	-162(a6)
	;
	lea	sfxs(pc),a1
	move	#$80,d0
	moveq	#1,d1
	moveq	#0,d2
	moveq	#3,d3
.loop	bsr	.init
	lea	fx_size(a1),a1
	dbf	d3,.loop
	;
	pull
	rts
	;
.init	clr	fx_status(a1)
	move	d0,fx_int(a1)
	move	d1,fx_dma(a1)
	move	d2,fx_offset(a1)
	add	d0,d0
	add	d1,d1
	add	#16,d2
	rts

finitsfx	push
	move.l	4.w,a6
	;
	moveq	#7,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	move.l	4.w,a6
	moveq	#8,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	move.l	4.w,a6
	moveq	#9,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	move.l	4.w,a6
	moveq	#10,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	pull
	rts

; v190ep: exit safety for Paula SFX.  Some recent local-event sounds can still
; be active when the player leaves the game/menu.  Kill all four audio DMAs and
; their interrupt bits before config save/freeing, so Paula cannot keep reading
; sample memory during shutdown.
g2v190ep_stop_all_sfx
	movem.l	d0-d2/a1-a2,-(a7)
	lea	sfxs(pc),a1
	moveq	#3,d2
.g2v190ep_stop_loop
	clr	fx_status(a1)
	bsr	sfxoff
	lea	fx_size(a1),a1
	dbf	d2,.g2v190ep_stop_loop
	move	#$000f,$dff096	; clear AUD0..AUD3 DMA
	move	#$0780,$dff09a	; clear AUD0..AUD3 interrupt enable
	move	#$0780,$dff09c	; clear pending AUD0..AUD3 interrupt requests
	movem.l	(a7)+,d0-d2/a1-a2
	rts

waitquiet	bsr	vwait
	lea	sfxs(pc),a0
	moveq	#3,d0
.loop	tst	fx_status(a0)
	bne.s	waitquiet
	lea	fx_size(a0),a0
	dbf	d0,.loop
	rts

playsfx	;sfx file in a0, vol in d0, priority in d1
	;
	;move	#$4000,$dff09a	;snd/vb ints off
	;
	lea	sfxs(pc),a1
	moveq	#3,d2
.loop	tst	fx_status(a1)
	beq.s	makesfx
	lea	fx_size(a1),a1
	dbf	d2,.loop
	;
	;OK, none free...check priorities
	;
	lea	sfxs(pc),a1
	moveq	#3,d2
.loop2	cmp	fx_priority(a1),d1
	bgt.s	queuesfx
	lea	fx_size(a1),a1
	dbf	d2,.loop2
	;
	;no-can-do!
	;
	;move	#$c000,$dff09a
	rts
	;
queuesfx	;OK, turn off other and play US!
	;
	move	#1,fx_status(a1)
	move	d0,fx_vol(a1)
	move	d1,fx_priority(a1)
	move.l	a0,fx_sfx(a1)	;play me next!
	;
	bsr	sfxoff
	;
	;move	#$c000,$dff09a
	rts

sfxoff	lea	$dff0a0,a2
	add	fx_offset(a1),a2
	move.l	chipzero(pc),(a2)
	move	#1,4(a2)	;len
	move	#0,8(a2)	;vol
	move	fx_int(a1),$dff09a
	move	fx_dma(a1),$dff096
	rts

makesfx	;OK, play this SFX NOW!
	;
	move	d1,fx_priority(a1)
	move	d0,fx_vol(a1)
	bsr	playsfxnow
	;move	#$c000,$dff09a
	rts

playsfxnow	move	#-2,fx_status(a1)
	;
	lea	$dff0a0,a2
	add	fx_offset(a1),a2
	move	(a0)+,6(a2)	;period
	move	(a0)+,4(a2)	;len
	move	fx_vol(a1),8(a2)	;vol
	move.l	a0,(a2)	;data
	;
	move	fx_dma(a1),d0	;dma bits
	or	#$8000,d0
	move	fx_int(a1),d1	;int bits
	move	d1,d2
	or	#$8000,d1
	;
	move	d0,$dff096	;dma on!
	move	d1,$dff09a	;int en
	move	d2,$dff09c	;intreq clr
	;
	rts

sfxint	;interupt for sfx!
	;
	tst	fx_status(a1)
	bge.s	.skip
	addq	#1,fx_status(a1)
	blt.s	.skip
	;
	move.l	a2,-(a7)
	bsr	sfxoff
	move.l	(a7)+,a2
	;
.skip	move	fx_int(a1),$dff09c
	moveq	#0,d0
	rts

dogamemenu	;
	move	#$20,$dff09a
	;
	st	paused
	move	framecnt,-(a7)
	move	linked,-(a7)
	clr	linked
	;
	move	#$8020,$dff09a
	;
	jsr	g2v190aj_grey_menu_backdrop	; v190aj: grey current chunky frame for ESC menu, no full drawall call
	bsr	trainer_update_display_texts
	lea	gamemenu,a4
	jsr	initmenu
	move	#-1,game_menu_active
	; v17: entering the in-game menu via ESC leaves ESC/fire still held.
	; Wait until the trigger is released so CONTINUE is not auto-selected.
	jsr	g2v17_wait_menu_release
	;
.loop	jsr	selmenu
	move	d0,d7
	and	#$0300,d7	;v109: $0100=left, $0200=right in game menu
	and	#$00ff,d0
	tst	d7
	beq.s	.game_menu_fire
	cmp	#0,d0
	beq	.loop
	bra.s	.game_menu_adjust
.game_menu_fire
	cmp	#0,d0
	beq	.done
.game_menu_adjust
	cmp	#2,d0
	bne.s	.notwsize
	cmp	#$0100,d7
	beq.s	.wsize_left
	bsr	newwsize
	bra	.loop
.wsize_left	bsr	decwsize
	bra	.loop
.notwsize
	cmp	#3,d0
	bne.s	.notlwin
	bsr	largewin
	bra	.loop
.notlwin
	cmp	#4,d0
	bne.s	.notfloor
	tst	floorflag
	bgt.s	.floor_off
	move	#1,floorflag
	bra.s	.fskip
.floor_off	move	#-1,floorflag
.fskip	bsr	trainer_update_floor_text
	bsr	refresh
	bra	.loop
.notfloor
	cmp	#5,d0
	bne.s	.notroof
	tst	roofflag
	bgt.s	.roof_off
	move	#1,roofflag
	bra.s	.rskip
.roof_off	move	#-1,roofflag
.rskip	bsr	trainer_update_ceiling_text
	bsr	refresh
	bra	.loop
.notroof
	cmp	#7,d0
	bne.s	.notblob
	bsr	trainer_toggle_blobshadow
	jsr	opton
	bra	.loop
.notblob
	cmp	#8,d0
	bne.s	.notrefl
	bsr	trainer_toggle_reflections
	jsr	opton
	bra	.loop
.notrefl
	cmp	#9,d0
	bne.s	.notvis
	bsr	trainer_toggle_visibility
	jsr	opton
	bra	.loop
.notvis
	cmp	#11,d0
	bne.s	.notinv
	bsr	trainer_toggle_inv
	jsr	opton		;v109a: long-call buildfix for cheat-row redraw
	bra	.loop
.notinv
	cmp	#12,d0
	bne.s	.notbouncy
	bsr	trainer_toggle_bouncy
	jsr	opton
	bra	.loop
.notbouncy
	cmp	#13,d0
	bne.s	.notonehit
	bsr	trainer_toggle_onehit
	jsr	opton
	bra	.loop
.notonehit
	cmp	#14,d0
	bne.s	.notweapon
	cmp	#$0100,d7
	beq.s	.weapon_left
	bsr	trainer_next_weapon
	bra.s	.weapon_done
.weapon_left	bsr	trainer_prev_weapon
.weapon_done	jsr	opton
	bra	.loop
.notweapon
	cmp	#15,d0
	bne.s	.notboost
	cmp	#$0100,d7
	beq.s	.boost_left
	bsr	trainer_next_boost
	bra.s	.boost_done
.boost_left	bsr	trainer_prev_boost
.boost_done	jsr	opton
	bra	.loop
.notboost
	cmp	#17,d0
	bne	.loop
	tst	d7
	bne	.loop
	move	#1,finished
	;
.done	jsr	g2cfg_save	;v141: save ingame menu settings when leaving menu
	clr	game_menu_active
	cmp	#1,finished
	beq.s	.finish_exit
	; v190am: normal CONTINUE path stays display-on.  The visible
	; menu frame remains until predrawall has rendered and db-swapped
	; the restored game frame, avoiding the old black redraw flash.
	jsr	dispoff	; v190do: full cleanup after VIEW SIZE changes, no stale menu text
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette
	jsr	predrawall
	jsr	dispon
	bra.s	.findone
.finish_exit
	jsr	dispoff
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette	; restore gameplay palette after grey/font menu palette
	bsr	clspic
	bsr	clspic
	jsr	dispon
.findone
	;
	move	#$20,$dff09a
	;
	move	(a7)+,linked
	beq.s	.nolink
	move	finished(pc),d0
	beq.s	.nolink
	bset	#7,d0
	jsr	serput
.nolink	move	(a7)+,framecnt
	clr	paused
	;
	move	#$8020,$dff09a
	;
	rts

trainer_toggle_blobshadow
	tst	g2_blobshadow
	ble.s	.on
	move	#-1,g2_blobshadow
	bra.s	.done
.on	move	#1,g2_blobshadow
.done	bsr	trainer_update_blob_text
	rts

trainer_toggle_reflections
	tst	g2_reflections
	ble.s	.on
	move	#-1,g2_reflections
	bra.s	.done
.on	move	#1,g2_reflections
.done	bsr	trainer_update_reflection_text
	rts

trainer_toggle_visibility
	tst	g2_visibility
	bgt.s	.default
	move	#1,g2_visibility
	bra.s	.done
.default	move	#-1,g2_visibility
.done	bsr	trainer_update_visibility_text
	rts

trainer_toggle_inv
	tst	trainer_invincible
	beq.s	.on
	clr	trainer_invincible
	bra.s	.done
.on	move	#-1,trainer_invincible
.done	bsr	trainer_update_inv_text
	bra	trainer_apply

trainer_toggle_bouncy
	tst	trainer_bouncy
	beq.s	.on
	clr	trainer_bouncy
	bra.s	.done
.on	move	#-1,trainer_bouncy
.done	bsr	trainer_update_bouncy_text
	bra	trainer_apply

trainer_toggle_onehit
	tst	trainer_onehit
	beq.s	.on
	clr	trainer_onehit
	bra.s	.done
.on	move	#-1,trainer_onehit
.done	bsr	trainer_update_onehit_text
	rts

trainer_next_weapon
	; v117: WEAPON loops DEFAULT->1..5->DEFAULT for right/RETURN
	cmp	#5,trainer_weapon
	bcs.s	.inc
	clr	trainer_weapon
	bra.s	.ok
.inc	addq	#1,trainer_weapon
.ok	bsr	trainer_update_weapon_text
	bra	trainer_apply

trainer_prev_weapon
	; v117: WEAPON loops DEFAULT<-5<-... for left
	tst	trainer_weapon
	bne.s	.dec
	move	#5,trainer_weapon
	bra.s	.ok
.dec	subq	#1,trainer_weapon
.ok	bsr	trainer_update_weapon_text
	bra	trainer_apply

trainer_next_boost
	; v117: UPGRADE loops DEFAULT->1..5->DEFAULT for right/RETURN
	cmp	#5,trainer_boost
	bcs.s	.inc
	clr	trainer_boost
	bra.s	.ok
.inc	addq	#1,trainer_boost
.ok	bsr	trainer_update_boost_text
	bra	trainer_apply

trainer_prev_boost
	; v117: UPGRADE loops DEFAULT<-5<-... for left
	tst	trainer_boost
	bne.s	.dec
	move	#5,trainer_boost
	bra.s	.ok
.dec	subq	#1,trainer_boost
.ok	bsr	trainer_update_boost_text
	bra	trainer_apply

trainer_apply
	move.l	player1(pc),d0
	beq.s	.p2
	move.l	d0,a5
	bsr	trainer_apply_one
.p2	tst	twowins
	beq.s	.rts
	move.l	player2(pc),d0
	beq.s	.rts
	move.l	d0,a5
	bsr	trainer_apply_one
.rts	rts

trainer_apply_one
	move	trainer_weapon,d0
	beq.s	.weapon_default
	subq	#1,d0
	move	d0,ob_weapon(a5)
.weapon_default
	move	trainer_boost,d0
	beq.s	.boost_default
	moveq	#6,d0
	sub	trainer_boost,d0
	move.b	d0,ob_reload(a5)
.boost_default
	tst	trainer_bouncy
	beq.s	.no_bouncy
	move	#3,ob_bouncecnt(a5)
	bra.s	.bouncy_done
.no_bouncy	clr	ob_bouncecnt(a5)
.bouncy_done	tst	trainer_invincible
	beq.s	.no_inv
	move	#25,ob_hitpoints(a5)
.no_inv	st	ob_update(a5)
	rts

trainer_maintain_one	;v112: keep enabled trainer options permanent without forcing
			;status redraws every frame.  Only mark ob_update when a
			;visible value actually changed.
	moveq	#0,d7
	move	trainer_weapon,d0
	beq.s	.weapon_done
	subq	#1,d0
	cmp	ob_weapon(a5),d0
	beq.s	.weapon_done
	move	d0,ob_weapon(a5)
	moveq	#-1,d7
.weapon_done
	move	trainer_boost,d0
	beq.s	.boost_done
	moveq	#6,d0
	sub	trainer_boost,d0
	cmp.b	ob_reload(a5),d0
	beq.s	.boost_done
	move.b	d0,ob_reload(a5)
	moveq	#-1,d7
.boost_done
	tst	trainer_bouncy
	beq.s	.bouncy_done
	cmp	#3,ob_bouncecnt(a5)
	beq.s	.bouncy_done
	move	#3,ob_bouncecnt(a5)
	moveq	#-1,d7
.bouncy_done
	tst	trainer_invincible
	beq.s	.inv_done
	cmp	#25,ob_hitpoints(a5)
	beq.s	.inv_done
	move	#25,ob_hitpoints(a5)
	; do not set ob_update here: damage is cancelled visually, so the HUD
	; should not flash/flicker on every invincible hit.
.inv_done
	tst	d7
	beq.s	.rts
	st	ob_update(a5)
.rts	rts

trainer_update_yesno3
	; a0 points to YES/NO field, d0 flag (>0 = YES)
	tst	d0
	ble.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_blob_text
	lea	game_blob,a0
	lea	21(a0),a0
	move	g2_blobshadow,d0
	bra	trainer_update_yesno3

trainer_update_reflection_text
	lea	game_reflections,a0
	lea	21(a0),a0
	move	g2_reflections,d0
	bra	trainer_update_yesno3

trainer_update_visibility_text
	lea	game_visibility,a0
	lea	21(a0),a0
	moveq	#7,d1
.clear	move.b	#' ',(a0)+
	dbf	d1,.clear
	lea	game_visibility,a0
	lea	21(a0),a0
	tst	g2_visibility
	bgt.s	.advanced
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'F',(a0)+
	move.b	#'A',(a0)+
	move.b	#'U',(a0)+
	move.b	#'L',(a0)+
	move.b	#'T',(a0)+
	rts
.advanced
	move.b	#'A',(a0)+
	move.b	#'D',(a0)+
	move.b	#'V',(a0)+
	move.b	#'A',(a0)+
	move.b	#'N',(a0)+
	move.b	#'C',(a0)+
	move.b	#'E',(a0)+
	move.b	#'D',(a0)+
	rts

trainer_update_inv_text
	lea	game_inv,a0
	lea	21(a0),a0
	tst	trainer_invincible
	beq.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_bouncy_text
	lea	game_bouncy,a0
	lea	21(a0),a0
	tst	trainer_bouncy
	beq.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_onehit_text
	lea	game_onehit,a0
	lea	21(a0),a0
	tst	trainer_onehit
	beq.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_weapon_text
	lea	game_weapon,a0
	lea	21(a0),a0
	move	trainer_weapon,d0
	bra	trainer_write_default_or_digit

trainer_update_boost_text
	lea	game_boost,a0
	lea	21(a0),a0
	move	trainer_boost,d0
	bra	trainer_write_default_or_digit

trainer_write_default_or_digit
	move.l	a0,-(a7)
	moveq	#7,d1
.clear	move.b	#' ',(a0)+
	dbf	d1,.clear
	move.l	(a7)+,a0
	tst	d0
	bne.s	.digit
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'F',(a0)+
	move.b	#'A',(a0)+
	move.b	#'U',(a0)+
	move.b	#'L',(a0)+
	move.b	#'T',(a0)+
	rts
.digit	add	#'0',d0
	move.b	d0,(a0)
	rts

trainer_update_display_texts
	movem.l	d0-d7/a0-a6,-(a7)
	bsr	trainer_update_wsize_text
	bsr	trainer_update_full_text
	bsr	trainer_update_floor_text
	bsr	trainer_update_ceiling_text
	bsr	trainer_update_blob_text
	bsr	trainer_update_reflection_text
	bsr	trainer_update_visibility_text
	bsr	trainer_update_inv_text
	bsr	trainer_update_bouncy_text
	bsr	trainer_update_onehit_text
	bsr	trainer_update_weapon_text
	bsr	trainer_update_boost_text
	movem.l	(a7)+,d0-d7/a0-a6
	rts

trainer_update_wsize_text
	; v109: gloom.s-style view-size names for the gloom2 320x224 view field.
	move	width(pc),d0
	cmp	#320,d0
	bcs.s	.notfull
	cmp	#240,hite
	bcs.s	.notfull
	lea	trainer_txt_fullscreen,a1
	bra.s	.copy
.notfull
	cmp	#96,d0
	bcs.s	.tiny
	cmp	#128,d0
	bcs.s	.small
	cmp	#160,d0
	bcs.s	.medium
	cmp	#192,d0
	bcs.s	.large
	cmp	#224,d0
	bcs.s	.xlarge
	cmp	#256,d0
	bcs.s	.huge
	cmp	#288,d0
	bcs.s	.vhuge
	lea	trainer_txt_almost,a1
	bra.s	.copy
.tiny	lea	trainer_txt_tiny,a1
	bra.s	.copy
.small	lea	trainer_txt_small,a1
	bra.s	.copy
.medium	lea	trainer_txt_medium,a1
	bra.s	.copy
.large	lea	trainer_txt_large,a1
	bra.s	.copy
.xlarge	lea	trainer_txt_xlarge,a1
	bra.s	.copy
.huge	lea	trainer_txt_huge,a1
	bra.s	.copy
.vhuge	lea	trainer_txt_vhuge,a1
.copy	lea	game_wsize,a0
	lea	21(a0),a0
	moveq	#15,d1
.blank	move.b	#' ',(a0)+
	dbf	d1,.blank
	lea	game_wsize,a0
	lea	21(a0),a0
.cpy	move.b	(a1)+,d0
	beq.s	.done
	move.b	d0,(a0)+
	bra.s	.cpy
.done	rts

trainer_update_full_text
	lea	game_full,a0
	lea	21(a0),a0
	cmp	#320,width
	bne.s	.no
	cmp	#240,hite
	bne.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_floor_text
	lea	game_floor,a0
	lea	21(a0),a0
	move	floorflag(pc),d0
	bmi.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.shaded	move.b	#'S',(a0)+
	move.b	#'H',(a0)+
	move.b	#'A',(a0)+
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'D',(a0)+
	rts

trainer_update_ceiling_text
	lea	game_ceil,a0
	lea	21(a0),a0
	move	roofflag(pc),d0
	bmi.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.shaded	move.b	#'S',(a0)+
	move.b	#'H',(a0)+
	move.b	#'A',(a0)+
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'D',(a0)+
	rts


g2v17_wait_menu_release
	movem.l	d0,-(a7)
.g2v17_wmr_loop
	bsr	vwait
	jsr	readmenujoy
	bne.s	.g2v17_wmr_loop
	movem.l	(a7)+,d0
	rts

largewin	move	#320,width
	move	#240,hite
	bra	sizedone

; v115/v117: discrete view sizes from v114 ingame menu.
; v117: left/right/RETURN now loop between TINY and FULLSCREEN.
; ALMOST FULL keeps current width but uses VERY HUGE height.
newwsize	cmp	#320,width
	bne.s	.nf
	cmp	#240,hite
	bcc	.s64		;v117: FULLSCREEN -> TINY
.nf	move	width(pc),d0
	cmp	#96,d0
	bcs.s	.s96
	cmp	#128,d0
	bcs.s	.s128
	cmp	#160,d0
	bcs.s	.s160
	cmp	#192,d0
	bcs.s	.s192
	cmp	#224,d0
	bcs.s	.s224
	cmp	#256,d0
	bcs	.s256
	cmp	#288,d0
	bcs	.s288
	bra	.sfull
.s64	move	#64,width
	move	#64,hite
	bra	sizedone
.s96	move	#96,width
	move	#96,hite
	bra	sizedone
.s128	move	#128,width
	move	#128,hite
	bra	sizedone
.s160	move	#160,width
	move	#160,hite
	bra	sizedone
.s192	move	#192,width
	move	#192,hite
	bra	sizedone
.s224	move	#224,width
	move	#192,hite
	bra	sizedone
.s256	move	#256,width
	move	#192,hite
	bra	sizedone
.s288	move	#288,width
	move	#192,hite		;v115: ALMOST FULL same height as VERY HUGE
	bra	sizedone
.sfull	move	#320,width
	move	#240,hite
	bra	sizedone

decwsize	move	width(pc),d0
	cmp	#64,d0
	bls	.sfull		;v117: TINY -> FULLSCREEN
	cmp	#96,d0
	bls.s	.s64
	cmp	#128,d0
	bls.s	.s96
	cmp	#160,d0
	bls.s	.s128
	cmp	#192,d0
	bls.s	.s160
	cmp	#224,d0
	bls.s	.s192
	cmp	#256,d0
	bls.s	.s224
	cmp	#288,d0
	bls.s	.s256
	bra	.s288		;FULLSCREEN/320 -> ALMOST FULL
.s64	move	#64,width
	move	#64,hite
	bra	sizedone
.s96	move	#96,width
	move	#96,hite
	bra	sizedone
.s128	move	#128,width
	move	#128,hite
	bra	sizedone
.s160	move	#160,width
	move	#160,hite
	bra	sizedone
.s192	move	#192,width
	move	#192,hite
	bra	sizedone
.s224	move	#224,width
	move	#192,hite
	bra	sizedone
.s256	move	#256,width
	move	#192,hite
	bra	sizedone
.s288	move	#288,width
	move	#192,hite		;v115: ALMOST FULL same height as VERY HUGE
	bra	sizedone
.sfull	move	#320,width
	move	#240,hite
	; fall through to sizedone

sizedone	move	width(pc),d0
	move	d0,chunkymodw
	lsr	#1,d0
	move	d0,maxx
	neg	d0
	move	d0,minx
	move	hite(pc),d0
	lsr	#1,d0
	move	d0,maxy
	neg	d0
	move	d0,miny
	bsr	trainer_update_display_texts	;v112: rebuild menu text immediately
	bra	refresh

calcoffset	move	#320,d0
	sub	width(pc),d0
	lsr	#4,d0
	ext.l	d0
	;
	move	#240,d1
	sub	hite(pc),d1
	lsr	#1,d1
	mulu	linemodw(pc),d1
	add.l	d1,d0
	move.l	d0,offset
	;
	rts

refresh	jsr	dispoff
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette	; v190aj: leave font palette before drawing refreshed backdrop
	jsr	predrawall
	tst	game_menu_active
	beq.s	.g2v190aj_refresh_nogrey
	jsr	g2v190aj_grey_menu_backdrop
.g2v190aj_refresh_nogrey
	lea	gamemenu,a4
	jsr	initmenu2
	jsr	dispon
	rts

drawchunky	;draw a chunky shape on a 320 wide chunkymap
	;
	;d0=x,d1=y,d2=shape#,a0=shapetable
	;
	move.l	panel(pc),a0
	; fall through with panel as source table
g2drawchunky_a0	;a0=shapetable, d0=x,d1=y,d2=shape#
	add	#224,d1
	;
	movem.l	d2-d5/a2-a4,-(a7)
	;
	move.l	chunky(pc),a1
	mulu	#320,d1
	add.l	d1,a1	;left
	lea	coloffs,a2
	lea	0(a2,d0*4),a2	;coloff
	;
	add.l	12(a0,d2*4),a0	;start of shape!
	addq	#4,a0	;skip handles
	movem	(a0)+,d2-d3	;width, height
	subq	#1,d2
	subq	#1,d3
	move.l	#320,d5	;chunky mod
	moveq	#0,d0
	move.l	palettes(pc),a4
.hloop	move	d3,d4	;start of column
	move.l	a1,a3
	add.l	(a2)+,a3
.vloop	move.b	(a0)+,d0
	beq.s	.skip
	move.b	0(a4,d0),(a3)	;v64: normal shapes still need active palette remap
.skip	add.l	d5,a3
	dbf	d4,.vloop
	dbf	d2,.hloop
	;
	movem.l	(a7)+,d2-d5/a2-a4
	rts


; v47: final retail CrM2 smallfont2.bin has the full green statusbar
; background one entry later than the public source smallfont2.bin.  Public
; data:  #47 = 320px bar, #46 = middle clear.
; Retail: #48 = 320px bar, #49 = middle clear, #47/#46 are tiny pieces.
; Detect the shape width at runtime so both data sets work.
g2draw_statusbar_base
	; v190gi: lower smallfont2 statusbar background disabled.
	rts

g2draw_statusbar_clear
	; v190gi: lower smallfont2 statusbar clear strip disabled.
	rts

; v20: keep the original 224..239 chunky panel source deterministic.
; The real status strip is the 13-line shape #47; the remaining three
; visible lines are explicitly black so C2P never converts stale RAM.
g2clearpanelchunky
	movem.l	d0-d1/a0,-(a7)
	move.l	chunky(pc),a0
	add.l	#320*224,a0
	move	#(320*16/4)-1,d0
	moveq	#0,d1
.g2cpc_loop
	move.l	d1,(a0)+
	dbf	d0,.g2cpc_loop
	movem.l	(a7)+,d0-d1/a0
	rts

; v103: clear the whole chunky frame before C2P.  Used for teleport handoff:
; after the last visible blue/pixel frame we display black while the next
; intermission screen is loaded, instead of holding the final blue chamber view.
g2clearfullchunky
	movem.l	d0-d1/a0,-(a7)
	move.l	chunky(pc),a0
	move	#(320*240/4)-1,d0
	moveq	#0,d1
.g2cfc_loop
	move.l	d1,(a0)+
	dbf	d0,.g2cfc_loop
	movem.l	(a7)+,d0-d1/a0
	rts

; v61/v63: optional first-person gun overlay from CrM2 gun.bin.
; gun.bin is a normal anim/shape file with its own palette.  The loader
; remaps it once at startup.  Index 0 stays transparent; index 1 is
; kept as opaque black so the weapon body has no see-through holes.
; v67 draws the already-remapped gun indices through the active palettes table,
; just like drawchunky, while still using coloffs layout.  This keeps the gun
; in one piece and maps its colours into the current display palette.
g2drawgun
	movem.l	d0-d7/a0-a5,-(a7)
	; v190gl: Classic Gloom can use the embedded/physical Gloom2 gun.bin fallback.
	move.l	gunpic(pc),d0
	beq.w	.g2dg_done
	; v100: during the death fall, hide the first-person weapon completely.
	; ZGloom only leaves the red translucent screen / camera drop visible.
	move.l	player_(pc),a5
	tst.l	a5
	beq.s	.g2dg_player_ok
	tst	ob_hitpoints(a5)
	ble.w	.g2dg_done
.g2dg_player_ok
	move.l	d0,a0
	;
	; v68: ZGloom-style fire handling.  gun.bin shape #1 is the
	; recoil/firing weapon frame; shapes #2..#4 are muzzle flashes
	; selected by weapon group.  Draw the muzzle first, then the gun.
	clr.b	g2gun_recoilflag
	move	g2gun_firetimer(pc),d7
	beq.s	.g2dg_normal_shape
	st	g2gun_recoilflag
	subq	#1,g2gun_firetimer
	moveq	#1,d6		;shape #1 = firing/recoil gun frame
	bra.s	.g2dg_have_shape_index
.g2dg_normal_shape
	moveq	#0,d6		;shape #0 = normal gun frame
.g2dg_have_shape_index
	lsl	#2,d6
	add	#12,d6		;anim offset table entry
	move.l	0(a0,d6.w),d0
	beq.w	.g2dg_done
	cmp.l	#$20000,d0
	bcc.w	.g2dg_done
	add.l	d0,a0		;a0 = shape
	;
	; shape header: xhandle,yhandle,width,height then column-major pixels.
	; ZGloom placement: x = centre - xhandle.  We keep the higher
	; Gloom2Reforged baseline from v65, and add recoil downward when fired.
	move	(a0),d0		;x handle
	move	#160,d1
	sub	d0,d1		;x
	move	6(a0),d3		;height
	move	#266,d4		;v190gi: gun moved down by old statusbar height (~26px)
	sub	d3,d4		;cropped naturally at lower screen edge
	tst.b	g2gun_recoilflag
	beq.s	.g2dg_no_recoil_y
	add	#4,d4		;v71: shorter, lighter firing recoil
.g2dg_no_recoil_y
	;
	; ZGloom bob is only used when not firing.
	tst.b	g2gun_recoilflag
	bne.s	.g2dg_bob_done
	move.l	player_(pc),a5
	move	ob_bounce(a5),d0
	beq.s	.g2dg_bob_done
	lsr	#1,d0
	and	#255,d0
	move.l	camrots(pc),a2
	lea	0(a2,d0*8),a2
	move	2(a2),d0
	asr	#8,d0
	asr	#3,d0		;approx /2048 => about +/-16px
	add	d0,d1
	move	d0,d7
	bpl.s	.g2dg_bobpos
	neg	d7
.g2dg_bobpos
	lsr	#1,d7
	sub	d7,d4
.g2dg_bob_done
	; v71: draw animated muzzle flash first so the weapon sprite sits in front.
	tst.b	g2gun_recoilflag
	beq.s	.g2dg_no_muzzle
	bsr	g2drawgun_muzzle
.g2dg_no_muzzle
	bsr	g2drawgun_coloffs_shape_crop_left	;v99: hide stray left-edge non-transparent gun pixels
.g2dg_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Draw one gun.bin shape into the Gloom2 chunky/C2P column layout.
; In: a0 = shape, d1 = x, d4 = y.  Shape pixels are already remapped by
; remapanim, but still go through the active palettes table like drawchunky.
g2drawgun_coloffs_shape
	movem.l	d0-d7/a0-a5,-(a7)
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	tst	d2
	ble.w	.g2dgs_done
	cmp	#160,d2
	bhi.w	.g2dgs_done
	tst	d3
	ble.w	.g2dgs_done
	cmp	#128,d3
	bhi.w	.g2dgs_done
	cmp	#240,d4
	bge.w	.g2dgs_done
	move	#240,d5
	sub	d4,d5		;visible rows from y to bottom
	ble.w	.g2dgs_done
	cmp	d3,d5
	bls.s	.g2dgs_vhok
	move	d3,d5
.g2dgs_vhok
	move	d3,d6
	sub	d5,d6		;bytes to skip at bottom of every source column
	subq	#1,d5		;dbf visible height
	subq	#1,d2		;dbf width
	move.l	chunky(pc),a1
	mulu	#320,d4
	add.l	d4,a1		;destination row base
	ext.l	d1
	lea	coloffs,a2
	lea	0(a2,d1*4),a2	;C2P column layout, not linear x
	lea	8(a0),a0		;source pixels
	move.l	palettes(pc),a4
	moveq	#0,d0
.g2dgs_xloop
	move.l	a1,a3
	add.l	(a2)+,a3
	move	d5,d7
.g2dgs_yloop
	move.b	(a0)+,d0
	beq.s	.g2dgs_skip
	move.b	0(a4,d0),(a3)
.g2dgs_skip
	lea	320(a3),a3
	dbf	d7,.g2dgs_yloop
	adda.w	d6,a0
	dbf	d2,.g2dgs_xloop
.g2dgs_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; v99: draw the main first-person gun with a tiny left crop.  Some gun.bin
; variants contain a few non-zero pixels in the transparent left padding.  Do
; not restore the old index-1 transparency globally because that punched holes
; into the weapon body; crop the first four source columns for the gun.
g2drawgun_coloffs_shape_crop_left
	movem.l	d0-d7/a0-a5,-(a7)
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	cmp	#8,d2
	bls.w	.g2dgcl_done
	tst	d3
	ble.w	.g2dgcl_done
	cmp	#128,d3
	bhi.w	.g2dgcl_done
	cmp	#240,d4
	bge.w	.g2dgcl_done
	addq	#4,d1		;v105b: skip four transparent-padding columns on screen
	subq	#4,d2		;and in source width
	move	#240,d5
	sub	d4,d5
	ble.w	.g2dgcl_done
	cmp	d3,d5
	bls.s	.g2dgcl_vhok
	move	d3,d5
.g2dgcl_vhok
	move	d3,d6
	sub	d5,d6
	subq	#1,d5
	subq	#1,d2
	move.l	chunky(pc),a1
	mulu	#320,d4
	add.l	d4,a1
	ext.l	d1
	lea	coloffs,a2
	lea	0(a2,d1*4),a2
	lea	8(a0),a0
	move	d3,d0
	lsl	#2,d0
	adda.w	d0,a0		;v105b: skip four column-major source columns
	move.l	palettes(pc),a4
	moveq	#0,d0
.g2dgcl_xloop
	move.l	a1,a3
	add.l	(a2)+,a3
	move	d5,d7
.g2dgcl_yloop
	move.b	(a0)+,d0
	beq.s	.g2dgcl_skip
	move.b	0(a4,d0),(a3)
.g2dgcl_skip
	lea	320(a3),a3
	dbf	d7,.g2dgcl_yloop
	adda.w	d6,a0
	dbf	d2,.g2dgcl_xloop
.g2dgcl_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Draw one gun.bin shape scaled as solid pixel blocks in the same coloffs/C2P
; layout.  In: a0 = shape, d1 = x, d4 = y, d7 = integer scale factor 1..3.
g2drawgun_coloffs_shape_scaled
	cmp	#1,d7
	bhi.s	.g2dgss_go
	bra	g2drawgun_coloffs_shape
.g2dgss_go
	movem.l	d0-d7/a0-a6,-(a7)
	move	d7,d5		;scale
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	tst	d2
	ble.w	.g2dgss_done
	cmp	#160,d2
	bhi.w	.g2dgss_done
	tst	d3
	ble.w	.g2dgss_done
	cmp	#128,d3
	bhi.w	.g2dgss_done
	cmp	#240,d4
	bge.w	.g2dgss_done
	move	d2,d0
	mulu	d5,d0
	add	d1,d0
	cmp	#320,d0
	bgt.w	.g2dgss_done
	move	d3,d0
	mulu	d5,d0
	add	d4,d0
	cmp	#240,d0
	bgt.w	.g2dgss_done
	move.l	chunky(pc),a1
	mulu	#320,d4
	add.l	d4,a1		;base destination row
	ext.l	d1
	lea	coloffs,a6
	lea	8(a0),a5		;current source column
	move.l	palettes(pc),a4
	subq	#1,d2		;dbf width
.g2dgss_xsrc
	move	d5,d6		;repeat this source column scale times
.g2dgss_xrep
	move.l	a1,a3
	lea	0(a6,d1*4),a2
	add.l	(a2),a3
	move.l	a5,a2		;source pixel ptr for this column
	move	d3,d4
	subq	#1,d4		;dbf source height
.g2dgss_ysrc
	moveq	#0,d0
	move.b	(a2)+,d0
	beq.s	.g2dgss_zero
	move.b	0(a4,d0.w),d0
	move	d5,d7
	subq	#1,d7
.g2dgss_yrep_nz
	move.b	d0,(a3)
	lea	320(a3),a3
	dbf	d7,.g2dgss_yrep_nz
	bra.s	.g2dgss_ynext
.g2dgss_zero
	move	d5,d7
	subq	#1,d7
.g2dgss_yrep_z
	lea	320(a3),a3
	dbf	d7,.g2dgss_yrep_z
.g2dgss_ynext
	dbf	d4,.g2dgss_ysrc
	addq	#1,d1
	subq	#1,d6
	bne.s	.g2dgss_xrep
	adda.w	d3,a5		;next source column (column-major layout)
	dbf	d2,.g2dgss_xsrc
.g2dgss_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Draw one gun.bin shape with a fractional nearest-neighbour scale.
; In: a0 = shape, d1 = x, d4 = y, d6 = numerator, d7 = denominator.
; Used for smaller follow-up muzzle flashes than the old 2x/3x steps.
g2drawgun_coloffs_shape_scalefrac
	movem.l	d0-d7/a0-a6,-(a7)
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	tst	d2
	ble.w	.g2dgsf_done
	cmp	#160,d2
	bhi.w	.g2dgsf_done
	tst	d3
	ble.w	.g2dgsf_done
	cmp	#128,d3
	bhi.w	.g2dgsf_done
	cmp	#240,d4
	bge.w	.g2dgsf_done
	move	d2,d5
	mulu	d6,d5
	divu	d7,d5		;scaled width
	beq.w	.g2dgsf_done
	move	d3,d0
	mulu	d6,d0
	divu	d7,d0		;scaled height
	beq.w	.g2dgsf_done
	move	d5,d6
	add	d1,d6
	cmp	#320,d6
	bgt.w	.g2dgsf_done
	move	d0,d6
	add	d4,d6
	cmp	#240,d6
	bgt.w	.g2dgsf_done
	move.l	chunky(pc),a1
	mulu	#320,d4
	add.l	d4,a1		;base destination row
	move	d0,d4		;scaled height
	move	d1,d7		;base x
	ext.l	d7
	lea	coloffs,a6
	lea	8(a0),a5		;source base
	move.l	palettes(pc),a4
	moveq	#0,d6		;dest x index
.g2dgsf_xloop
	cmp	d5,d6
	bge.s	.g2dgsf_done
	move	d6,d0
	mulu	d2,d0
	divu	d5,d0		;source x = dx * srcw / dstw
	mulu	d3,d0
	lea	0(a5,d0.w),a0	;source column base
	move	d7,d0
	add	d6,d0
	move.l	a1,a3
	lea	0(a6,d0*4),a2
	add.l	(a2),a3
	moveq	#0,d1		;dest y index
.g2dgsf_yloop
	cmp	d4,d1
	bge.s	.g2dgsf_xnext
	move	d1,d0
	mulu	d3,d0
	divu	d4,d0		;source y = dy * srch / dsth
	move.b	0(a0,d0.w),d0
	andi.l	#$ff,d0
	beq.s	.g2dgsf_skip
	move.b	0(a4,d0),(a3)
.g2dgsf_skip
	lea	320(a3),a3
	addq	#1,d1
	bra.s	.g2dgsf_yloop
.g2dgsf_xnext
	addq	#1,d6
	bra.s	.g2dgsf_xloop
.g2dgsf_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Draw the muzzle-flash shape from gun.bin.  ZGloom uses shapes #2..#4,
; selected as 2 + ((weapon + 1) / 2), so weapon 0/1 share the first flash,
; 2/3 share the second, and 4 uses the largest flash.
g2drawgun_muzzle
	movem.l	d0-d7/a0-a5,-(a7)
	move.l	gunpic(pc),d0
	beq.w	.g2dm_done
	move.l	d0,a0
	; v73: match the muzzle flash to the current weapon upgrade like ZGloom:
	; shape = 2 + ((weapon + 1) / 2).  This gives matching flash art for
	; upgrades 0/1, 2/3 and 4, instead of cycling unrelated flash frames.
	move.l	player_(pc),a5
	moveq	#0,d7
	tst.l	a5
	beq.s	.g2dm_have_weapon
	move	ob_weapon(a5),d7
	cmp	#4,d7
	bls.s	.g2dm_weapon_ok
	moveq	#4,d7
.g2dm_weapon_ok
	addq	#1,d7
	asr	#1,d7
	addq	#2,d7
.g2dm_have_weapon
	move	d7,d6
	lsl	#2,d6
	add	#12,d6
	move.l	0(a0,d6.w),d0
	beq.w	.g2dm_done
	cmp.l	#$20000,d0
	bcc.w	.g2dm_done
	add.l	d0,a0
	; v72: keep the flash behind the gun, but raise it far enough so the
	; upper/sides remain visible.  Bottom-aligning at 240 hid it entirely
	; behind the gun/statusbar in the Gloom2 C2P layout.
	move	4(a0),d0		;width
	move	#320,d1
	sub	d0,d1
	asr	#1,d1		;centre by width, not xhandle
	move	6(a0),d3		;height
	move	#237,d4		;v190gi: muzzleflash follows gun moved down by 26px
	sub	d3,d4		;v76 base plus removed statusbar height
				;right at/just above the gun muzzle instead of being hidden too low
	; v79: keep the single-shape approach from v78, but reduce the follow-up
	; sizes by about 20%.  The 3-frame sequence is now 1x -> 1.6x -> 2.4x
	; instead of 1x -> 2x -> 3x.
	move	g2gun_firetimer(pc),d5
	cmp	#2,d5
	beq.s	.g2dm_scale1
	cmp	#1,d5
	beq.s	.g2dm_scale16
	; firetimer == 0 on the last visible flash frame after g2drawgun already
	; decremented it.  Draw the same flash shape one more step larger.
.g2dm_scale24
	move	d0,d6
	moveq	#12,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d0,d6
	lsr	#1,d6
	sub	d6,d1		;centre 2.4x flash around the same muzzle point
	move	d3,d6
	moveq	#12,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d3,d6
	lsr	#1,d6
	sub	d6,d4
	moveq	#12,d6
	moveq	#5,d7
	bsr	g2drawgun_coloffs_shape_scalefrac
	bra.s	.g2dm_done
.g2dm_scale16
	move	d0,d6
	moveq	#8,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d0,d6
	lsr	#1,d6
	sub	d6,d1		;centre 1.6x flash
	move	d3,d6
	moveq	#8,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d3,d6
	lsr	#1,d6
	sub	d6,d4
	moveq	#8,d6
	moveq	#5,d7
	bsr	g2drawgun_coloffs_shape_scalefrac
	bra.s	.g2dm_done
.g2dm_scale1
	bsr	g2drawgun_coloffs_shape
.g2dm_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Try all known Gloom/Gloom Deluxe/Zombie Massacre gun locations.
g2loadgunfallback
	movem.l	d0-d1/a0,-(a7)
	tst.l	gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_miscbin(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_stufbin(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_miscraw(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_stufraw(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
.g2lg_done
	movem.l	(a7)+,d0-d1/a0
	rts

; gun.bin uses raw palette index 1 as transparent.  drawchunky skips 0,
; therefore convert index 1 to 0 before remapanim destroys the raw indices.
g2gun_prepare
	; v73: keep gun palette index 1 as a real black gun colour.
	; Earlier builds converted raw index 1 to 0 before remapanim, which
	; created transparent holes inside the weapon graphic.  gun.bin already
	; uses index 0 as transparency; index 1 must remain opaque black.
	rts

g2gun_name_miscbin	dc.b	'misc/gun.bin',0
	even
g2gun_name_stufbin	dc.b	'stuf/gun.bin',0
	even
g2gun_name_miscraw	dc.b	'misc/gun',0
	even
g2gun_name_stufraw	dc.b	'stuf/gun',0
	even

predrawall	;draw up everything....
	;
	;status bar too...
	;
	bsr	clspic
	bsr	clspic
	bsr	calcoffset
	; v190gi: no lower statusbar background.
	move.l	player1(pc),a0
	st	ob_update(a0)
	tst	gametype
	beq.s	.skip
	move.l	player2(pc),a0
	st	ob_update(a0)
.skip	bsr	drawall_
	bra	drawall_

drawall	;
	jsr	g2v36_hide_pointer	;v36: keep Intuition pointer hidden during gameplay
	lea	g2log_msg_da_enter,a0
	jsr	g2log_drawstep
.wait	tst	doneflag
	bne.s	.waitskip
	bsr	vwait
	bra.s	.wait
.waitskip	clr	doneflag
	lea	g2log_msg_da_wait_ok,a0
	jsr	g2log_drawstep
	;
drawall_	move.l	player1(pc),player_
	move.l	memory(pc),memat
	;
	lea	g2log_msg_da_calc1_b,a0
	jsr	g2log_drawstep
	jsr	calcscene
	lea	g2log_msg_da_calc1_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_da_draw1_b,a0
	jsr	g2log_drawstep
	jsr	drawscene
	lea	g2log_msg_da_draw1_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_da_blit1_b,a0
	jsr	g2log_drawstep
	jsr	blitscene
	lea	g2log_msg_da_blit1_ok,a0
	jsr	g2log_drawstep
	;
	move	twowins(pc),d0
	beq.s	.show
	;
	move.l	player2(pc),player_
	move.l	memory(pc),memat
	lea	g2log_msg_da_calc2_b,a0
	jsr	g2log_drawstep
	jsr	calcscene
	lea	g2log_msg_da_calc2_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_da_draw2_b,a0
	jsr	g2log_drawstep
	jsr	drawscene
	lea	g2log_msg_da_draw2_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_da_blit2_b,a0
	jsr	g2log_drawstep
	jsr	blitscene
	lea	g2log_msg_da_blit2_ok,a0
	jsr	g2log_drawstep
.show	;
	lea	g2log_msg_da_wait2_b,a0
	jsr	g2log_drawstep
.wait2	tst	showflag
	bne.s	.waitskip2
	bsr	vwait
	bra.s	.wait2
.waitskip2	lea	g2log_msg_da_wait2_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_da_doc2p_b,a0
	jsr	g2log_drawstep
	jsr	doc2p
	lea	g2log_msg_da_doc2p_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_da_db_b,a0
	jsr	g2log_drawstep
	jsr	db
	lea	g2log_msg_da_db_ok,a0
	jsr	g2log_drawstep
	clr	showflag
	lea	g2log_msg_da_exit,a0
	jsr	g2log_drawstep
	rts

doc2p	;
	move.l	chunky(pc),a0		;src
	move.l	drawbitmap(pc),a1	;dest
	add.l	offset(pc),a1
	move	width(pc),d0
	move	hite(pc),d1
	move.l	bpmod(pc),d2		;bpmod
	move.l	linemod(pc),d3		;linemod
	move.l	c2p(pc),a2
	jsr	(a2)
	;nop	;v16: bottom clear disabled, restore compact 240-row plane layout first
	move	panelcnt(pc),d0
	beq.s	.rts
	;
	subq	#1,panelcnt
	move.l	drawbitmap(pc),a1
	move	#224,d1
	mulu	linemodw(pc),d1
	add.l	d1,a1
	;
	move.l	chunky(pc),a0
	add.l	#320*224,a0
	;
	move	#320,d0
	moveq	#16,d1	;v19: convert full 224..239 status/gun panel area
	move.l	bpmod(pc),d2
	move.l	linemod(pc),d3
	move.l	c2p(pc),a2
	jsr	(a2)
	;
.rts	rts


g2v15_clear_bottom16	;clear bottom 16 visible OS lines below the 240-line game render
	;Only active in OS/NewMode path. No-OS copper path keeps original layout.
	tst	os
	beq.s	g2v15_cb16_done
	movem.l	d0-d2/a0-a1,-(a7)
	move.l	drawbitmap(pc),a0
	move	bitplanes(pc),d1
	subq	#1,d1
g2v15_cb16_plane
	move.l	a0,a1
	add.l	#40*240,a1
	moveq	#16-1,d0
g2v15_cb16_line
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	dbf	d0,g2v15_cb16_line
	add.l	bpmod(pc),a0
	dbf	d1,g2v15_cb16_plane
	movem.l	(a7)+,d0-d2/a0-a1
g2v15_cb16_done
	rts

resetplayer	st	ob_update(a5)
	clr	ob_mega(a5)
	clr	ob_thermo(a5)
	clr	ob_infra(a5)
	clr	ob_invisible(a5)
	clr	ob_pixsize(a5)
	clr	ob_pixsizeadd(a5)
	clr	ob_bouncecnt(a5)
	move	#-1,ob_messtimer(a5)
	move.l	#palettes,ob_palette(a5)
	rts

message	;print up a message...player in a5
	;
	move.l	(a7),a0	;return address=message!
	move.l	a0,ob_mess(a5)
	;
	moveq	#-1,d0
.loop	addq	#1,d0
	tst.b	(a0)+
	bne.s	.loop
	;
	move	d0,ob_messlen(a5)
	move	#-127,ob_messtimer(a5)
	;
	move.l	a0,d0
	addq.l	#1,d0
	and	#$fffe,d0
	move.l	d0,(a7)
	rts

pdelay	dc	0	;non zero=wait between prints

printmess	;a5=object
	;
	move.l	ob_window(a5),a6
	move.l	ob_mess(a5),a4
	move	ob_messlen(a5),d0
	move	wi_bh(a6),d6
	lsr	#2,d6	;Y
	;
printmess2	;a4=message, d0=length of message, d6=Y
	;
	; v190gl: Classic Gloom now receives a Gloom2-compatible bigfont2
	; fallback, so keep the normal printmess2 renderer for every profile.
.g2v190cv_normal_printmess2
	move	fontw(pc),d2
	lsr	#1,d2
	mulu	d2,d0
	move	#160,d7
	sub	d0,d7	;X
	bpl.s	.g2v11_x_ok
	moveq	#0,d7	;v11: clamp long intermission/menu lines
.g2v11_x_ok
	;
	jsr	ownblitter
	;
.loop2	move.b	(a4)+,d2
	beq	.done
	cmp.b	#' ',d2
	beq.w	.spc
	cmp.b	#'\',d2	;v11: do not render script separators
	beq.w	.spc
	cmp.b	#'0',d2
	bcs.s	.nnum
	cmp.b	#'9',d2
	bhi.s	.nnum
	sub.b	#'0',d2
	ext	d2
	bra.s	.here
.nnum	cmp.b	#"'",d2
	bne.s	.notap
	bra.w	.spc		; v190z: apostrophe glyph is unsafe here, render it as space for test
.notap	cmp.b	#'!',d2
	bne.s	.notex
	moveq	#36,d2
	bra.s	.here
.notex	cmp.b	#'.',d2
	bne.s	.notfs
	moveq	#37,d2
	bra.s	.here
.notfs	cmp.b	#':',d2
	bne.s	.notcol
	moveq	#38,d2
	bra.s	.here
.notcol	cmp.b	#127,d2
	bne.s	.notcurs
	moveq	#39,d2
	bra.s	.here
.notcurs	and	#31,d2
	add	#9,d2
.here	move.l	font(pc),a0
	move.l	showbitmap(pc),a1
	move	d7,d0
	move	d6,d1
	bsr	blit
	;
	move	pdelay(pc),d2
	subq	#1,d2
	bmi.s	.spc
	;
.pdloop	bsr	vwait
	jsr	checkany
	beq.s	.none
	move	#-1,pdelay
	moveq	#0,d2
.none	dbf	d2,.pdloop
	;
.spc	add	fontw(pc),d7
	bra	.loop2
.done	;
	jmp	disownblitter

printhexnum	;d0=x,d1=y,d2=hex long,a5=window
	;
	move.l	ob_window(a5),a0
	move.l	wi_bmap(a0),a1
	;
	movem.l	d0-d2/a0-a1,-(a7)
	subq	#2,d0
	subq	#1,d1
	moveq	#55,d2
	move.l	font(pc),a0
	bsr	blit
	movem.l	(a7)+,d0-d2/a0-a1
	;
	move	#8,-(a7)
.loop	rol.l	#4,d2
	movem.l	d0-d2/a0-a1,-(a7)
	and	#15,d2
	move.l	font(pc),a0
	bsr	blit
	movem.l	(a7)+,d0-d2/a0-a1
	addq	#6,d0
	subq	#1,(a7)
	bne.s	.loop
	addq	#2,a7
	addq	#8,d1
	rts

showstats
	;a5=player
	; v190gi: clean restart from v190fy.
	; Draw the new top HUD inside the existing Gloom2 chunky/C2P render path.
	; No old Gloom planar blitter, no direct smallfont.bin parsing, no bitmap writes.
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	panel(pc),d0
	beq.w	.g2hud_done
	;
	; HEALTH / WEAPON labels at the original Gloom top-left positions.
	moveq	#2,d7
	moveq	#4,d6		;v190hm: HUD 2px lower
	lea	hud_health(pc),a4
	bsr	g2hud_draw_text_top
	moveq	#2,d7
	moveq	#14,d6		;v190hm: HUD 2px lower
	lea	hud_weapon(pc),a4
	bsr	g2hud_draw_text_top
	;
	; LIVES label and icons at the top-right.
	move	#236,d7
	moveq	#4,d6		;v190hm: HUD 2px lower
	lea	hud_lives(pc),a4
	bsr	g2hud_draw_text_top
	move	ob_lives(a5),d7
	ble.s	.g2hud_no_lives
	cmp	#5,d7
	ble.s	.g2hud_lives_ok
	moveq	#5,d7
.g2hud_lives_ok
	subq	#1,d7
	move	#276,d6
.g2hud_lives_loop
	move	d6,d0
	moveq	#4,d1		;v190hm: HUD 2px lower
	moveq	#44,d2		; existing Gloom2 life/skull/heart slot
	bsr	g2hud_draw_shape_top
	addq	#8,d6
	dbf	d7,.g2hud_lives_loop
.g2hud_no_lives
	;
	; Health bar: use proven Gloom2 statusbar cell shapes, but draw at top-left.
	move	ob_hitpoints(a5),d7
	ble.s	.g2hud_nohp
	cmp	#25,d7
	ble.s	.g2hud_hp_ok
	moveq	#25,d7
.g2hud_hp_ok
	moveq	#0,d3
	moveq	#44,d6
	subq	#1,d7
.g2hud_hploop
	moveq	#45,d2		; red/danger cells
	cmp	#10,d3
	blt.s	.g2hud_hpcol_ok
	moveq	#46,d2		; middle cells
	cmp	#18,d3
	blt.s	.g2hud_hpcol_ok
	moveq	#47,d2		; green cells
.g2hud_hpcol_ok
	move	d6,d0
	moveq	#4,d1		;v190hm: HUD 2px lower
	bsr	g2hud_draw_shape_top
	addq	#2,d6
	addq	#1,d3
	dbf	d7,.g2hud_hploop
.g2hud_nohp
	;
	; Weapon/upgrade bar: same shape family as existing Gloom2 HUD cells.
	moveq	#5,d7
	sub.b	ob_reload(a5),d7
	blt.s	.g2hud_done
	move	ob_weapon(a5),d2
	add	#39,d2
	moveq	#44,d6
.g2hud_wploop
	move	d6,d0
	moveq	#14,d1		;v190hm: HUD 2px lower
	bsr	g2hud_draw_shape_top
	add	#10,d6
	dbf	d7,.g2hud_wploop
.g2hud_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

hud_health	dc.b	'HEALTH',0
hud_weapon	dc.b	'WEAPON',0
hud_lives	dc.b	'LIVES',0
	even

g2hud_draw_text_top	;a4=zero-terminated text, d7=x, d6=y
	movem.l	d0-d2/d6-d7/a4,-(a7)
.g2hudt_loop
	move.b	(a4)+,d2
	beq.s	.g2hudt_done
	cmp.b	#' ',d2
	beq.s	.g2hudt_space
	cmp.b	#'0',d2
	bcs.s	.g2hudt_notnum
	cmp.b	#'9',d2
	bhi.s	.g2hudt_notnum
	sub.b	#'0',d2
	ext	d2
	bra.s	.g2hudt_draw
.g2hudt_notnum
	cmp.b	#'A',d2
	bcs.s	.g2hudt_space
	and	#31,d2
	add	#9,d2
.g2hudt_draw
	move	d7,d0
	move	d6,d1
	bsr	g2hud_draw_shape_top
.g2hudt_space
	addq	#6,d7
	bra.s	.g2hudt_loop
.g2hudt_done
	movem.l	(a7)+,d0-d2/d6-d7/a4
	rts

g2hud_draw_shape_top	;d0=x, d1=y, d2=shape# from panel/smallfont2; draw to chunky top area
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	panel(pc),a0
	tst.l	a0
	beq.w	.g2hds_done
	cmp	#0,d0
	blt.w	.g2hds_done
	cmp	#319,d0
	bgt.w	.g2hds_done
	cmp	#0,d1
	blt.w	.g2hds_done
	cmp	#239,d1
	bgt.w	.g2hds_done
	cmp	#0,d2
	blt.w	.g2hds_done
	cmp	#49,d2
	bgt.w	.g2hds_done
	move.l	12(a0,d2*4),d3
	beq.w	.g2hds_done
	add.l	d3,a0
	addq	#4,a0		; same Gloom2 shape layout as drawchunky
	movem	(a0)+,d2-d3	;width,height
	tst	d2
	ble.w	.g2hds_done
	tst	d3
	ble.w	.g2hds_done
	move	d0,d6
	add	d2,d6
	cmp	#320,d6
	bgt.w	.g2hds_done
	move	d1,d6
	add	d3,d6
	cmp	#240,d6
	bgt.w	.g2hds_done
	subq	#1,d2
	subq	#1,d3
	move.l	chunky(pc),a1
	mulu	#320,d1
	add.l	d1,a1
	lea	coloffs,a2
	lea	0(a2,d0*4),a2
	move.l	palettes(pc),a4
	moveq	#0,d0
.g2hds_xloop
	move	d3,d7
	move.l	a1,a3
	add.l	(a2)+,a3
.g2hds_yloop
	move.b	(a0)+,d0
	beq.s	.g2hds_skip
	move.b	0(a4,d0),(a3)
.g2hds_skip
	lea	320(a3),a3
	dbf	d7,.g2hds_yloop
	dbf	d2,.g2hds_xloop
.g2hds_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

; v190gi: lower statusbar message scroller removed with the bottom panel.
g2draw_statusbar_scroll
	rts

g2draw_statusbar_char
	rts

blit	;a0=shapetable to blit, a1=bitmap, d0=X, d1=Y, d2=char
	;
	add.l	4(a0,d2*4),a0
	;
	mulu	linemodw(pc),d1
	add.l	d1,a1
	move	d0,d2
	asr	#3,d2
	add	d2,a1	;dest!
	move.l	a0,a2
	add.l	(a0),a2
	lea	10(a0),a3
	addq	#4,a0
	and	#15,d0
	ror	#4,d0
	;
	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.s	.bwait
	;
	move.l	a3,$dff04c	;image
	move	d0,$dff042
	or	blitmode(pc),d0
	move	d0,$dff040
	move	d0,bltcon0
	move.l	#$ffff0000,$dff044
	moveq	#-2,d0
	move	d0,$dff064
	move	d0,$dff062
	move	linemodw(pc),d0
	subq	#2,d0
	sub	(a0)+,d0
	move	d0,$dff060
	move	d0,$dff066
	move	(a0)+,d0
	move	(a0),d1
	subq	#1,d1
	move.l	bpmod(pc),d2
	;
.bloop	btst	#6,$dff002
	btst	#6,$dff002
	bne.s	.bloop
	;
	move.l	a2,$dff050	;cookie
	move.l	a1,$dff048	;dest
	move.l	a1,$dff054
	move	d0,$dff058
	add.l	d2,a1
	;
	dbf	d1,.bloop
	;
	move	bitplanes(pc),d1
	sub	(a0),d1
	ble.s	.rts
	subq	#1,d1
	;clear excess planes
	and	#$fb0f,bltcon0
	;
	btst	#6,$dff002
.bwait2	btst	#6,$dff002
	bne.s	.bwait2
	move	bltcon0(pc),$dff040
	;
.bloop2	btst	#6,$dff002
	btst	#6,$dff002
	bne.s	.bloop2
	;
	move.l	a2,$dff050	;cookie
	move.l	a1,$dff048	;dest
	move.l	a1,$dff054
	move	d0,$dff058
	add.l	d2,a1
	;
	dbf	d1,.bloop2
	;
.rts	rts

bltcon0	dc	0
blitmode	dc	$fca

pixsize	dc	0	;pixel size...at least 2!

; v93: chunky pixelate effect for teleport/death transitions.
; Existing game logic already drives ob_pixsize/ob_pixsizeadd for teleport,
; exit and player death.  The original routine was stubbed out in this
; gloom2 path, so those animations never became visible.
;
; The chunky buffer uses the C2P column-offset layout: vertical rows are
; spaced by chunkymodw, while visible X positions must go through coloffs.
; This routine therefore samples/fills rectangular screen blocks in display
; coordinates but writes through coloffs, keeping the C2P layout intact.
pixelate	movem.l	d0-d7/a0-a5,-(a7)
	move	pixsize(pc),d6
	cmp	#2,d6
	blt.w	.done
	cmp	#24,d6
	ble.s	.sizeok
	move	#24,d6
.sizeok	moveq	#0,d4		;Y block start
.yloop	cmp	hite(pc),d4
	bge.w	.done
	move.l	chunky(pc),a5
	move	d4,d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a5		;top row base for this block row
	moveq	#0,d2		;X block start
.xloop	cmp	width(pc),d2
	bge.s	.nexty
	move	width(pc),d1
	sub	d2,d1		;remaining width
	cmp	d6,d1
	ble.s	.bwok
	move	d6,d1
.bwok	move	hite(pc),d5
	sub	d4,d5		;remaining height
	cmp	d6,d5
	ble.s	.bhok
	move	d6,d5
.bhok	lea	coloffs(pc),a1
	move.l	a5,a0
	move.l	0(a1,d2*4),d0
	add.l	d0,a0
	moveq	#0,d7
	move.b	(a0),d7		;sample colour
	move.l	a5,a2		;current destination row base
	subq	#1,d5		;DBF row count
.yfill	move	d1,d0
	subq	#1,d0		;DBF column count
	move	d2,d6		;current X inside this block
.xfill	move.l	0(a1,d6*4),d3
	move.b	d7,0(a2,d3.l)
	addq	#1,d6
	dbf	d0,.xfill
	adda.l	chunkymod(pc),a2
	dbf	d5,.yfill
	move	pixsize(pc),d6
	cmp	#24,d6
	ble.s	.addx
	move	#24,d6
.addx	add	d6,d2
	bra.s	.xloop
.nexty	move	pixsize(pc),d6
	cmp	#24,d6
	ble.s	.addy
	move	#24,d6
.addy	add	d6,d4
	bra.w	.yloop
.done	movem.l	(a7)+,d0-d7/a0-a5
	rts

; v99: ZGloom-style post-render tint helpers.  They build a 256-byte remap
; table from the current planar RGB palette, then remap only the game view
; through coloffs so the HUD/statusbar remains untouched.
g2apply_blue_tint
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	player_(pc),a0
	move	ob_pixsize(a0),d7
	ble.w	.g2t_done
	cmp	#24,d7
	ble.s	.g2bt_fok
	move	#24,d7
.g2bt_fok
	moveq	#24,d6
	sub	d7,d6		;old colour weight
	moveq	#8,d4		;target R/G = 8
	moveq	#15,d5		;target B = 15
	bsr	g2build_tint_lut
	bsr	g2apply_tint_lut
.g2t_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2apply_red_tint
	movem.l	d0-d7/a0-a6,-(a7)
	moveq	#12,d7		;transparent red strength
	moveq	#24,d6
	sub	d7,d6
	moveq	#15,d4		;target R = 15
	moveq	#0,d5		;target G/B = 0
	bsr	g2build_red_tint_lut
	bsr	g2apply_tint_lut
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Build blue tint LUT. In: d6=old weight, d7=tint weight, d4=target RG, d5=target B.
g2build_tint_lut
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	planar_palette(pc),a0
	move.l	planar_remap(pc),a1
	tst.l	a0
	beq.w	.g2bl_done
	tst.l	a1
	beq.w	.g2bl_done
	lea	g2tint_lut(pc),a2
	move	#255,d3
.g2bl_loop
	move	0(a0,d3*4),d0
	move	d0,d1
	move	d0,d2
	lsr	#8,d0
	and	#$f,d0
	mulu	d6,d0
	move	d4,d1
	mulu	d7,d1
	add	d1,d0
	divu	#24,d0
	and	#$f,d0
	lsl	#8,d0
	move	0(a0,d3*4),d1
	lsr	#4,d1
	and	#$f,d1
	mulu	d6,d1
	move	d4,d2
	mulu	d7,d2
	add	d2,d1
	divu	#24,d1
	and	#$f,d1
	lsl	#4,d1
	or	d1,d0
	move	0(a0,d3*4),d1
	and	#$f,d1
	mulu	d6,d1
	move	d5,d2
	mulu	d7,d2
	add	d2,d1
	divu	#24,d1
	and	#$f,d1
	or	d1,d0
	move.b	0(a1,d0.w),0(a2,d3.w)
	dbf	d3,.g2bl_loop
.g2bl_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

; Build red tint LUT. In: d6=old weight, d7=tint weight, d4=target R, d5=target GB.
g2build_red_tint_lut
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	planar_palette(pc),a0
	move.l	planar_remap(pc),a1
	tst.l	a0
	beq.w	.g2rl_done
	tst.l	a1
	beq.w	.g2rl_done
	lea	g2tint_lut(pc),a2
	move	#255,d3
.g2rl_loop
	move	0(a0,d3*4),d0
	move	d0,d1
	lsr	#8,d0
	and	#$f,d0
	mulu	d6,d0
	move	d4,d1
	mulu	d7,d1
	add	d1,d0
	divu	#24,d0
	and	#$f,d0
	lsl	#8,d0
	move	0(a0,d3*4),d1
	lsr	#4,d1
	and	#$f,d1
	mulu	d6,d1
	move	d5,d2
	mulu	d7,d2
	add	d2,d1
	divu	#24,d1
	and	#$f,d1
	lsl	#4,d1
	or	d1,d0
	move	0(a0,d3*4),d1
	and	#$f,d1
	mulu	d6,d1
	move	d5,d2
	mulu	d7,d2
	add	d2,d1
	divu	#24,d1
	and	#$f,d1
	or	d1,d0
	move.b	0(a1,d0.w),0(a2,d3.w)
	dbf	d3,.g2rl_loop
.g2rl_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

g2apply_tint_lut
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	chunky(pc),a0
	tst.l	a0
	beq.w	.g2atl_done
	lea	g2tint_lut(pc),a3
	lea	coloffs(pc),a1
	move	width(pc),d7
	ble.w	.g2atl_done
	subq	#1,d7
.g2atl_x
	move.l	(a1)+,d0
	move.l	a0,a2
	add.l	d0,a2
	move	hite(pc),d6
	ble.s	.g2atl_nextx
	subq	#1,d6
.g2atl_y
	moveq	#0,d1
	move.b	(a2),d1
	move.b	0(a3,d1.w),(a2)
	adda.l	chunkymod(pc),a2
	dbf	d6,.g2atl_y
.g2atl_nextx
	dbf	d7,.g2atl_x
.g2atl_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

g2fill_void_fog
	; v190bc: far portal fog uses a carried dark wall colour/span.
	; It propagates through long no-wall corridor openings, but never copies
	; texture rows and never reads neighbouring entries outside vertdraws.
	; Only very dark wall columns (distance shade >= 13) seed the carry, so
	; nearby doorways stay untouched and far openings fade into the wall fog.
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	chunky(pc),a0
	tst.l	a0
	beq.w	.g2fv_done
	move.l	vertdraws(pc),a6
	tst.l	a6
	beq.w	.g2fv_done
	move.l	chunkymod(pc),d4
	clr	g2fv_global_ok
	;
	; pass 1: left -> right.  Solid far wall columns update the carry;
	; following empty portal columns are filled from that carry until another
	; solid column changes or clears it.
	clr	g2fv_carry_ok
	lea	coloffs(pc),a1
	move	width(pc),d7
	ble.w	.g2fv_pass2
	subq	#1,d7
.g2fv_lx
	move.l	(a1),d0
	move.l	a0,a2
	add.l	d0,a2
	tst.l	vd_data(a6)
	beq.s	.g2fv_lempty
	move	vd_pal(a6),d0
	cmp	#13,d0
	blo.s	.g2fv_lclear
	move	vd_y(a6),d0
	add	midy(pc),d0
	move	vd_h(a6),d5
	bsr	g2fv_set_carry
	bra.s	.g2fv_lnext
.g2fv_lclear
	clr	g2fv_carry_ok
	bra.s	.g2fv_lnext
.g2fv_lempty
	tst	g2fv_carry_ok
	beq.s	.g2fv_lnext
	bsr	g2fv_fill_with_carry
.g2fv_lnext
	lea	vd_size(a6),a6
	addq.l	#4,a1
	dbf	d7,.g2fv_lx
	;
	; pass 2: right -> left.  This fills openings that have no far wall on
	; their left side, again using only a carried colour/span.
.g2fv_pass2
	clr	g2fv_carry_ok
	move	width(pc),d7
	ble.w	.g2fv_done
	subq	#1,d7
	lea	coloffs(pc),a1
	move	d7,d0
	ext.l	d0
	lsl.l	#2,d0
	add.l	d0,a1
	move.l	vertdraws(pc),a6
	move	d7,d0
	mulu	#vd_size,d0
	add.l	d0,a6
.g2fv_rx
	move.l	(a1),d0
	move.l	a0,a2
	add.l	d0,a2
	tst.l	vd_data(a6)
	beq.s	.g2fv_rempty
	move	vd_pal(a6),d0
	cmp	#13,d0
	blo.s	.g2fv_rclear
	move	vd_y(a6),d0
	add	midy(pc),d0
	move	vd_h(a6),d5
	bsr	g2fv_set_carry
	bra.s	.g2fv_rnext
.g2fv_rclear
	clr	g2fv_carry_ok
	bra.s	.g2fv_rnext
.g2fv_rempty
	tst	g2fv_carry_ok
	beq.s	.g2fv_rnext
	bsr	g2fv_fill_with_carry
.g2fv_rnext
	lea	-vd_size(a6),a6
	subq.l	#4,a1
	dbf	d7,.g2fv_rx
.g2fv_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; a2 = source solid wall column top
; d0 = wall top Y on screen, d4 = chunkymod, d5 = wall height
g2fv_set_carry
	movem.l	d0-d5/a2-a4,-(a7)
	clr	g2fv_carry_ok
	tst	d5
	ble.w	.g2fv_sc_done
	; clip top
	tst	d0
	bpl.s	.g2fv_sc_notopclip
	add	d0,d5
	ble.w	.g2fv_sc_done
	neg	d0
	move	d0,d1
	mulu.l	d4,d1
	add.l	d1,a2
	moveq	#0,d0
	bra.s	.g2fv_sc_clipbot
.g2fv_sc_notopclip
	beq.s	.g2fv_sc_clipbot
	move	d0,d1
	mulu.l	d4,d1
	add.l	d1,a2
.g2fv_sc_clipbot
	move	hite(pc),d2
	sub	d0,d2
	ble.w	.g2fv_sc_done
	cmp	d2,d5
	bls.s	.g2fv_sc_countok
	move	d2,d5
.g2fv_sc_countok
	subq	#1,d5
	bmi.s	.g2fv_sc_done
	move	d0,g2fv_carry_top
	move	d5,d1
	addq	#1,d1
	move	d1,g2fv_carry_h
	; sample near the middle of the clipped span first
	move	d5,d1
	lsr	#1,d1
	move.l	d1,d2
	mulu.l	d4,d2
	moveq	#0,d1
	move.b	0(a2,d2.l),d1
	bne.s	.g2fv_sc_havecol
	; fallback: first non-zero pixel in the clipped wall span
	move	d5,d2
	move.l	a2,a4
.g2fv_sc_find
	moveq	#0,d1
	move.b	(a4),d1
	bne.s	.g2fv_sc_havecol
	add.l	d4,a4
	dbf	d2,.g2fv_sc_find
	bra.s	.g2fv_sc_done
.g2fv_sc_havecol
	move	d1,g2fv_carry_col
	move	#1,g2fv_carry_ok
	; v190bi: do not seed the global long-corridor fallback from texture
	; pixels.  Some wall samples briefly remapped to red/white/green while
	; walking and caused coloured tunnel-end flicker.  Local carry may still
	; use the wall colour for neighbouring spans; the large no-wall fallback
	; below now always builds its stable neutral dark fog colour.
.g2fv_sc_done
	movem.l	(a7)+,d0-d5/a2-a4
	rts

; a2 = destination empty portal column top.  Uses carry vars only.
g2fv_fill_with_carry
	movem.l	d0-d5/a2-a4,-(a7)
	tst	g2fv_carry_ok
	beq.s	.g2fv_fc_done
	move	g2fv_carry_top(pc),d0
	move	g2fv_carry_h(pc),d5
	ble.s	.g2fv_fc_done
	move	g2fv_carry_col(pc),d1
	move	d0,d2
	mulu.l	d4,d2
	add.l	d2,a2
	subq	#1,d5
.g2fv_fc_loop
	tst.b	(a2)
	bne.s	.g2fv_fc_skip
	move.b	d1,(a2)
.g2fv_fc_skip
	add.l	d4,a2
	dbf	d5,.g2fv_fc_loop
.g2fv_fc_done
	movem.l	(a7)+,d0-d5/a2-a4
	rts

g2fv_carry_ok	dc	0
g2fv_carry_top	dc	0
g2fv_carry_h	dc	0
g2fv_carry_col	dc	0
g2fv_global_ok	dc	0
g2fv_global_col	dc	0

; Build a stable palette-correct fallback colour for long no-wall corridors.
; v190bi: this is deliberately neutral and not seeded from wall textures,
; avoiding rare coloured tunnel-end flicker from red/white/green samples.
g2fv_build_default_global
	movem.l	d0-d2/a3-a4,-(a7)
	move.l	planar_remap,a4
	tst.l	a4
	beq.s	.g2fv_bdg_done
	lea	paladjust,a3
	; v190bh: very dark fallback RGB.  v190bf used $211, which could remap
	; to a visibly grey/light grey palette entry while walking through long
	; corridors.  The fallback must stay almost black until a real far wall
	; is close enough to seed the normal textured fog.
	move	#$100,d0
	moveq	#0,d1
	move.b	0(a4,d0.w),d1
	and	#$00ff,d1
	moveq	#0,d2
	move.b	0(a3,d1.w),d2
	bne.s	.g2fv_bdg_have
	moveq	#1,d2
.g2fv_bdg_have
	move	d2,g2fv_global_col
	move	#1,g2fv_global_ok
.g2fv_bdg_done
	movem.l	(a7)+,d0-d2/a3-a4
	rts

; Fills still-empty pixels in no-wall columns after floor/ceiling rendering,
; using the stable neutral dark global fog colour.  This is the fallback for
; very long corridor openings that have no nearby dark wall column to carry
; a local span.
g2fill_void_fog_remaining
	movem.l	d0-d7/a0-a6,-(a7)
	; v190bi: always rebuild the stable neutral default colour for this
	; frame.  Do not reuse texture-sampled global colours; those caused rare
	; red/white/green flicker at the end of long tunnels.
	clr	g2fv_global_ok
	bsr.w	g2fv_build_default_global
	tst	g2fv_global_ok
	beq.w	.g2fvr_done
	move.l	chunky(pc),a0
	tst.l	a0
	beq.w	.g2fvr_done
	move.l	vertdraws(pc),a6
	tst.l	a6
	beq.w	.g2fvr_done
	move.l	chunkymod(pc),d4
	move	g2fv_global_col(pc),d1
	lea	coloffs(pc),a1
	move	width(pc),d7
	ble.w	.g2fvr_done
	subq	#1,d7
.g2fvr_x
	tst.l	vd_data(a6)
	bne.s	.g2fvr_next
	move.l	(a1),d0
	move.l	a0,a2
	add.l	d0,a2
	move	hite(pc),d6
	ble.s	.g2fvr_next
	subq	#1,d6
.g2fvr_y
	tst.b	(a2)
	bne.s	.g2fvr_skip
	move.b	d1,(a2)
.g2fvr_skip
	add.l	d4,a2
	dbf	d6,.g2fvr_y
.g2fvr_next
	lea	vd_size(a6),a6
	addq.l	#4,a1
	dbf	d7,.g2fvr_x
.g2fvr_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2tint_lut	ds.b	256
	even

; v190dm: when CEILING or FLOOR is set to NO, draw the same neutral
; distance-fog colour into the corresponding empty flat region instead of
; leaving black vertical void bars in deep corridors.  d7 = relative start Y
; as used by flat (miny or maxy-1), d1 = relative Y step (+1 roof, -1 floor).
g2fill_disabled_flat_fog
	movem.l	d0-d7/a0-a4,-(a7)
	clr	g2fv_global_ok
	bsr.w	g2fv_build_default_global
	tst	g2fv_global_ok
	beq.w	.g2fdff_done
	move.l	chunky(pc),a0
	tst.l	a0
	beq.w	.g2fdff_done
	move.l	chunkymod(pc),d4
	move	g2fv_global_col(pc),d3
	move	d1,d6
	muls	chunkymodw(pc),d6
	move	d7,d0
	add	midy(pc),d0
	bmi.w	.g2fdff_done
	cmp	hite(pc),d0
	bge.w	.g2fdff_done
	mulu	chunkymodw(pc),d0
	move.l	a0,a2
	add.l	d0,a2
.g2fdff_y
	tst	d7
	beq.w	.g2fdff_done
	lea	coloffs(pc),a1
	move	width(pc),d5
	ble.s	.g2fdff_step
	subq	#1,d5
.g2fdff_x
	move.l	(a1)+,d0
	move.l	a2,a3
	add.l	d0,a3
	tst.b	(a3)
	bne.s	.g2fdff_xskip
	move.b	d3,(a3)
.g2fdff_xskip
	dbf	d5,.g2fdff_x
.g2fdff_step
	add	d1,d7
	add.l	d6,a2
	bra.s	.g2fdff_y
.g2fdff_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

flatcam	dc.l	0
flatyadd	dc	0
flatyadd2	dc	0

flat	;
	;do flat above/below panel!
	;
	;d0=Y pos of flat
	;d1=Screen Y add
	;d7=first screen Y (miny or maxy-1)
	;
	;a0=panel to draw on!
	;
	ext.l	d0
	lsl.l	#focshft,d0
	move.l	d0,flatcam
	;
	move	d1,flatyadd
	muls	chunkymodw(pc),d1
	move	d1,flatyadd2
	;
	move	d7,d0
	add	midy(pc),d0
	mulu	chunkymodw(pc),d0
	add.l	chunky(pc),d0
	move.l	d0,a2
	lea	coloffs,a1
.vloop	;
	;find Z on this scanline...
	;
	tst	d7
	beq	.rts
	move.l	flatcam(pc),d6
	divs	d7,d6	;d6.w = Z
	tst	g2_visibility
	bgt.s	.g2v190ey_flat_adv
	cmp	#maxz,d6
	bcc	.rts
	move	d6,d5
	; v190ey: DEFAULT is back to the original short fog feel while the
	; shared v190ew darktable reaches its cap at 8 widths.  Keep near space
	; unchanged, but stretch the 4..6 DEFAULT fog ramp into the 4..8 table.
	cmp	#(4<<grdshft),d5
	blo.s	.g2v190ey_flat_default_scale_ok
	sub	#(4<<grdshft),d5
	add	d5,d5
	add	#(4<<grdshft),d5
	cmp	#maxz-1,d5
	bls.s	.g2v190ey_flat_default_scale_ok
	move	#maxz-1,d5
.g2v190ey_flat_default_scale_ok
	bra.s	.g2v190dw_flat_shade
.g2v190ey_flat_adv
	cmp	#g2advviewfar,d6	; v190fc: ADVANCED = smooth 16-width range
	bcc	.rts
	move	d6,d5
	lsr	#1,d5	; v190fc: 16 actual widths map exactly into the 8-width darktable cap
	cmp	#maxz-1,d5
	bls.s	.g2v190fc_flat_adv_scale_ok
	move	#maxz-1,d5
.g2v190fc_flat_adv_scale_ok
.g2v190dw_flat_shade
	;
	move	d5,d0	; v190ej: scaled shade-distance before darktable lookup
	move.l	darktable(pc),a5
	move	0(a5,d5*2),d5
	move.l	palette(pc),a5
	move.l	0(a5,d5*4),a5
	; v190em: true bright-side lead-in for each real shade-table
	; transition.  Look ahead inside the last quarter of the current
	; bright band: if the darktable becomes darker at +96/+72/+48/+24
	; distance units, mix a growing Bayer amount of the next darker
	; palette into the still-bright band.  No darker-side tail and no
	; geometry/clip dithering.
	clr	g2_bayer_thresh
	; v190eo: include the first and second visible shade bands too.
	; The v190em test skipped everything below 2 texture widths,
	; so the ordered lead-in only became visible in the third band.
	cmp	#14,d5
	bcc	.g2v190ej_flatblend_done
	movem.l	d1-d3/a4,-(a7)
	move.l	darktable(pc),a4
	moveq	#15,d2
	move	d0,d1
	add	#24,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_flatblend_24ok
	move	#maxz-1,d1
.g2v190em_flatblend_24ok
	move	0(a4,d1*2),d3
	cmp	d5,d3
	bhi	.g2v190em_flatblend_set
	moveq	#11,d2
	move	d0,d1
	add	#48,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_flatblend_48ok
	move	#maxz-1,d1
.g2v190em_flatblend_48ok
	move	0(a4,d1*2),d3
	cmp	d5,d3
	bhi	.g2v190em_flatblend_set
	moveq	#7,d2
	move	d0,d1
	add	#72,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_flatblend_72ok
	move	#maxz-1,d1
.g2v190em_flatblend_72ok
	move	0(a4,d1*2),d3
	cmp	d5,d3
	bhi	.g2v190em_flatblend_set
	; v190ep: softer beginning of the brighter-side lead-in.
	; Before the old first visible Bayer amount, add two sparse rows:
	; +96 = 4/16, +112 = 2/16, +128 = 1/16 darker pixels.
	moveq	#4,d2
	move	d0,d1
	add	#96,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_flatblend_96ok
	move	#maxz-1,d1
.g2v190em_flatblend_96ok
	move	0(a4,d1*2),d3
	cmp	d5,d3
	bhi	.g2v190em_flatblend_set
	moveq	#2,d2
	move	d0,d1
	add	#112,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190ep_flatblend_112ok
	move	#maxz-1,d1
.g2v190ep_flatblend_112ok
	move	0(a4,d1*2),d3
	cmp	d5,d3
	bhi	.g2v190em_flatblend_set
	moveq	#1,d2
	move	d0,d1
	add	#128,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190ep_flatblend_128ok
	move	#maxz-1,d1
.g2v190ep_flatblend_128ok
	move	0(a4,d1*2),d3
	cmp	d5,d3
	bls.s	.g2v190em_flatblend_restore
.g2v190em_flatblend_set
	move	d2,g2_bayer_thresh
	move	d5,d1
	addq	#1,d1
	cmp	#14,d1
	bls.s	.g2v190em_flatblend_palok
	moveq	#14,d1
.g2v190em_flatblend_palok
	move.l	palette(pc),a4
	move.l	0(a4,d1*4),g2_bayer_nextpal
.g2v190em_flatblend_restore
	movem.l	(a7)+,d1-d3/a4
.g2v190ej_flatblend_done
	;
	;Find leftmost X...
	;
	move	minx(pc),d5
	muls	d6,d5
	asr.l	#focshft,d5
	;
	move	maxx(pc),d4
	muls	d6,d4
	asr.l	#focshft,d4
	;
	;rotate X1,Z around camera...
	;
	move	d5,d0
	move	d6,d1
	;
	move	d0,d2
	move	d1,d3
	;
	muls	icm1(pc),d0
	add.l	d0,d0
	muls	icm2(pc),d3
	add.l	d3,d3
	add.l	d3,d0
	;
	muls	icm3(pc),d2
	add.l	d2,d2
	muls	icm4(pc),d1
	add.l	d1,d1
	add.l	d2,d1
	;
	;d0,d1.q = rotated x1,z
	;
	;rotate X2,Z around camera...
	;
	move	d4,d2
	move	d6,d3
	;
	muls	icm1(pc),d4
	add.l	d4,d4
	muls	icm2(pc),d3
	add.l	d3,d3
	add.l	d3,d4
	;
	muls	icm3(pc),d2
	add.l	d2,d2
	muls	icm4(pc),d6
	add.l	d6,d6
	add.l	d2,d6
	;
	;d4,d6.q = rotated x2,z
	;
	move	width(pc),d5
	ext.l	d5
	sub.l	d0,d4	;Xadd
	divs.l	d5,d4
	sub.l	d1,d6	;Zadd
	divs.l	d5,d6
	;
	;d0,d1.q=x,z
	;d4,d6.q=xadd,zadd
	;
	swap	d0
	add	camx(pc),d0
	swap	d1
	add	camz(pc),d1
	swap	d4
	swap	d6
	;
	move	d7,g2_bayer_ybase	; v190ej: scanline phase for flat Bayer blend
	lea	g2v190ej_bayer_xrows,a6
	move	d7,d2
	and	#3,d2
	lsl	#8,d2
	add	d2,d2	; *512 bytes per repeated Bayer row
	adda.w	d2,a6
	move.l	g2_bayer_nextpal,a1	; next darker palette, used only when threshold != 0
	move.l	d7,-(a7)
	moveq	#127,d7
	moveq	#0,d2
	moveq	#0,d3
	lea	coloffs(pc),a3
	;
	move	width(pc),d5
	subq	#1,d5
	;
.hloop	;get next column
	;
	move.l	(a3)+,a4	;coloff
	tst.b	0(a2,a4.l)
	bne.s	.skip
	;
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2v190ej_flat_base
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2v190ej_flat_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),0(a2,a4.l)
	bra.s	.g2v190ej_flat_advance
.g2v190ej_flat_base
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),0(a2,a4.l)
.g2v190ej_flat_advance
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6	; next Bayer X, does not disturb X flag
	dbf	d5,.hloop
	bra.s	.hhh
	;
.skip	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,.hloop
	;
.hhh	move.l	(a7)+,d7
	add	flatyadd(pc),d7
	add	flatyadd2(pc),a2
	bra	.vloop
	;
.rts	rts

doanims	move.l	map_anim(pc),a0
	lea	textures,a1
	;
.loop	move	(a0)+,d0	;how many frames
	beq.s	.done
	movem	(a0)+,d1-d2	;first, delay
	subq	#1,(a0)+
	bgt.s	.loop
	move	d2,-2(a0)
	lea	0(a1,d1*4),a2
	;
	;do the anim!
	;
	subq	#2,d0
	move.l	(a2),d2
.loop2	move.l	4(a2),(a2)+
	dbf	d0,.loop2
	move.l	d2,(a2)
	bra.s	.loop
	;
.done	rts

dorots	;
	move.l	camrots2(pc),a6
	lea	rotpolys(pc),a5	;header!
	;
rotloop	move.l	(a5),a5
	tst.l	(a5)
	beq	.done
	move	rp_speed(a5),d0
	beq.s	rotloop
	;
	add	d0,rp_rot(a5)
	move	rp_rot(a5),d0
	;
	move.l	rp_first(a5),a2	;first
	move	rp_num(a5),d5
	subq	#1,d5
	move	d5,d4
	lsl	#5,d4
	lea	0(a2,d4),a1	;previous
	lea	rp_lx(a5),a3
	;
	btst	#0,rp_flags+1(a5)
	bne.s	morph
	;
.rot	movem	rp_cx(a5),d6-d7	;centre x,z
	and	#1023,d0
	lea	0(a6,d0*8),a4	;rotation matrix.
	;
.loop	bsr	rotter
	add	d6,d0
	add	d7,d1
	movem	d0-d1,zo_lx(a2)
	movem	d0-d1,zo_rx(a1)
	bsr	rotter
	movem	d0-d1,zo_na(a2)
	exg	d0,d1
	neg	d0
	movem	d0-d1,zo_a(a2)
	move.l	a2,a1
	lea	32(a2),a2
	dbf	d5,.loop
	;
	bra	rotloop
	;
.done	rts
	;
morph	tst	d0
	bgt.s	.dp
	moveq	#0,d0
.neg	neg	rp_speed(a5)
	bra.s	.skip2
.dp	cmp	#$4000,d0
	blt.s	.skip
	move	#$4000,d0
	btst	#1,rp_flags+1(a5)
	bne.s	.neg
	clr	rp_speed(a5)
.skip2	move	d0,rp_rot(a5)
.skip	;
	move	d0,d4
	movem.l	a2/d5,-(a7)	;for calculating norms!
	;
.loop	movem	(a3)+,d0-d3
	muls	d4,d0
	lsl.l	#2,d0
	swap	d0
	add	d2,d0
	muls	d4,d1
	lsl.l	#2,d1
	swap	d1
	add	d3,d1
	movem	d0-d1,zo_lx(a2)
	movem	d0-d1,zo_rx(a1)
	move.l	a2,a1
	lea	32(a2),a2
	dbf	d5,.loop
	;
	movem.l	(a7)+,a2/d5
	;
.loop2	move	zo_rx(a2),d0
	sub	zo_lx(a2),d0
	move	zo_rz(a2),d1
	sub	zo_lz(a2),d1
	bsr	calcnormvec
	movem	d0-d1,zo_na(a2)
	exg	d0,d1
	neg	d0
	movem	d0-d1,zo_a(a2)
	lea	32(a2),a2
	dbf	d5,.loop2
	;
	bra	rotloop

calcnormvec	;d0,d1 = vector...normalize!
	;
	;OK, find vector length!
	;
	move	d0,d2
	muls	d2,d2
	move	d1,d3
	muls	d3,d3
	add.l	d3,d2	
	;
	;OK, sqr of d2.l!
	;
	move.l	#$10000,d3
	;
.fitit	cmp.l	#16384,d2	;fits?
	bcs.s	.ok
	asr.l	#1,d2
	mulu.l	#92681,d4:d3	;mult by sqr(2)
	move	d4,d3
	swap	d3
	bra.s	.fitit
	;
.ok	;OK to look up, but multiply the result.w by d3.q
	;
	move.l	sqr(pc),a0
	and	#$fffe,d2
	movem	0(a0,d2),d2	;sqr.l!
	mulu.l	d3,d2
	swap	d2	;length.w
	;
	;length should be >= both abs(xvec) AND abs(zvec)
	;
	move	d0,d3
	bpl.s	.xp
	neg	d3
.xp	move	d1,d4
	bpl.s	.zp
	neg	d4
.zp	;
	cmp	d4,d3
	bcc.s	.bg
	exg	d3,d4
.bg	;
	cmp	d3,d2
	bcc.s	.lo
	move	d3,d2
.lo	;
	ext.l	d2
	;
	swap	d0
	clr	d0
	divs.l	d2,d0
	muls.l	#32766,d0
	swap	d0
	;
	swap	d1
	clr	d1
	divs.l	d2,d1
	muls.l	#32766,d1
	swap	d1
	rts

rotter	movem	(a3)+,d0-d1	;this x,z
	move	d0,d2
	move	d1,d3
	;
	muls	(a4),d0
	muls	2(a4),d3
	add.l	d3,d0
	add.l	d0,d0
	swap	d0	;new x!
	;
	muls	4(a4),d2
	muls	6(a4),d1
	add.l	d2,d1
	add.l	d1,d1
	swap	d1
	;
	rts

dodoors	lea	doors(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq	.done
	;
	move.l	do_poly(a5),a0
	move	do_fracadd(a5),d0
	add	d0,do_frac(a5)
	move	do_frac(a5),d0
	move	d0,d1
	add	d1,d1
	move	d1,zo_open(a0)	;copy frac
	;
	move	do_rx(a5),d1
	sub	do_lx(a5),d1	;width
	move	d1,d2
	muls	d0,d2
	lsl.l	#2,d2
	swap	d2
	move	do_lx(a5),d3
	sub	d2,d3
	move	d3,zo_lx(a0)
	add	d1,d3
	move	d3,zo_rx(a0)
	;
	move	do_rz(a5),d1
	sub	do_lz(a5),d1
	move	d1,d2
	muls	d0,d2
	lsl.l	#2,d2
	swap	d2
	move	do_lz(a5),d3
	sub	d2,d3
	move	d3,zo_lz(a0)
	add	d1,d3
	move	d3,zo_rz(a0)
	;
	tst	d0
	beq.s	.kill
	cmp	#$4000,d0
	bne.s	.loop
	;
.kill	move.l	a5,a0
	killitem	doors
	move.l	a0,a5
	bra	.loop
	;
.done	rts

doorsfxflag	dc	0

execevent	;d0=event number to execute...1,2...
	;
	sf	doorsfxflag
	move.l	map_map(pc),a6
	move.l	map_events(pc),a0
	add.l	0(a0,d0*4),a6
	;
exec_loop	move	(a6)+,d0
	beq.s	.rts
	subq	#1,d0
	beq	exec_addobj	;1 - add an object (alien etc)
	subq	#1,d0
	beq	exec_opendoor	;2 - open a door
	subq	#1,d0
	beq	exec_teleport	;3 - teleport
	subq	#1,d0
	beq	exec_loadobjs	;4 - load objects
	subq	#1,d0
	beq	exec_changetxt	;5 - change texture
	subq	#1,d0
	beq	exec_rotpolys	;6 - start polygons rotating!
	;
	warn	#$f0f
	;
.rts	tst	doorsfxflag
	beq.s	.nodoor
	clr	doorsfxflag
	move.l	doorsfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr	playsfx
.nodoor	rts

changedtxt	dc	0
deftxt	dc.l	0
defgfxtxt	dc.l	0

exec_changetxt	;
	move	(a6)+,d0	;zone#
	move.l	map_poly(pc),a1
	lsl	#5,d0
	lea	0(a1,d0),a1	;polygon to change
	;
	move	(a6)+,d0	;new texture
	move	d0,changedtxt
	move.b	d0,zo_t(a1)
	bra	exec_loop

exec_opendoor	st	doorsfxflag
	addlast	doors	;a0=new door
	;
	move	(a6)+,d0	;door #
	move.l	map_poly(pc),a1
	lsl	#5,d0
	lea	0(a1,d0),a1	;polygon to open!
	;
	;calc lx add, lz add, rx add, rz add
	;
	move.l	a1,do_poly(a0)
	move.l	zo_lx(a1),do_lx(a0)
	move.l	zo_rx(a1),do_rx(a0)
	clr	do_frac(a0)
	move	#$100,do_fracadd(a0)
	bra	exec_loop

exec_teleport	move.l	eventobj(pc),a0
	;
	move	(a6)+,ob_telex(a0)
	addq	#2,a6
	move	(a6)+,ob_telez(a0)
	move	(a6)+,ob_telerot(a0)
	;
	move	finished(pc),d0
	or	finished2(pc),d0
	bne	exec_loop
	;
	tst	-6(a6)	;teleport? or lock!
	beq.s	.tele
	;
	;LOCK!
	cmp.l	#playerlogic,ob_logic(a0)
	bne	exec_loop
	;
	move	changedtxt(pc),d0
	lea	textures(pc),a1
	move.l	0(a1,d0*4),a1
	lea	65<<6+1(a1),a2
	lea	10*65+19(a1),a1
	movem.l	a1-a2,deftxt
	;
	move.l	#locklogic,ob_logic(a0)
	bra	exec_loop
.tele	;
	move	#2,ob_pixsizeadd(a0)
	bsr	dotelesfx
	bra	exec_loop

dotelesfx	move.l	telesfx(pc),a0
	moveq	#64,d0
	moveq	#10,d1
	bra	playsfx

exec_loadobjs	;
.loop	move	(a6)+,d0
	bmi	.done
	bsr	loadanobj
	bra.s	.loop
.done	;
	bra	exec_loop
	
loadanobj	;d0=object#...sys must be permitted
	;
	lea	objinfo,a2
	mulu	#objinfof-objinfo,d0
	move.l	_ob_shape-objinfo(a2,d0),a2
	lea	8(a2),a3	;filename
	;
	tst.l	(a2)
	bne.s	.skip
	move.l	a3,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,(a2)
	beq.s	.skip
	move.l	d0,a0
	jsr	remapanim
.skip	;
	tst.l	4(a2)
	bne.s	.rts
	move.l	a3,a0
.loop	tst.b	(a3)+
	bne.s	.loop
	move.b	#'2',-(a3)
	moveq	#1,d1
	jsr	loadfile
	clr.b	(a3)
	move.l	d0,4(a2)
	beq.s	.rts
	move.l	d0,a0
	jsr	remapanim
	;
.rts	rts

exec_rotpolys	;
	;could also be morphpolys depending on bit 0 of flags!
	;
	addlast	rotpolys
	bne.s	.ok
	addq	#8,a6
	bra	exec_loop
	;
.ok	st	doorsfxflag	; v190eg: rotating/morphing doors trigger delayed event sound
	movem	(a6)+,d0-d3	;polynum,count,speed,flags
	;
	clr	rp_rot(a0)
	move	d1,rp_num(a0)
	move	d2,rp_speed(a0)
	move	d3,rp_flags(a0)
	move	d1,d5
	subq	#1,d5
	move.l	map_poly(pc),a2	;polygons!
	lsl	#5,d0
	add	d0,a2
	move.l	a2,rp_first(a0)
	;
	btst	#0,d3
	beq	.rot
	;
	;OK, prepare for morph
	;
	lsl	#5,d1
	lea	0(a2,d1),a3
	lea	rp_vx(a0),a1
	;
.loop	movem	zo_lx(a3),d0-d1
	movem	zo_lx(a2),d2-d3
	sub	d2,d0
	sub	d3,d1
	movem	d0-d3,(a1)
	addq	#8,a1
	;
	lea	32(a2),a2
	lea	32(a3),a3
	dbf	d5,.loop
	;
	bra	exec_loop
	;
.rot	;First, calc centre X,Z into d6,d7
	;
	moveq	#0,d6
	moveq	#0,d7
	move.l	a2,a1
	;
.loop0	movem	zo_lx(a1),d0/d2
	add.l	d0,d6
	add.l	d2,d7
	lea	32(a1),a1
	dbf	d5,.loop0
	;
	divu	d1,d6
	divu	d1,d7
	movem	d6-d7,rp_cx(a0)
	;
	lea	rp_lx(a0),a1
	subq	#1,d1
	;
.loop2	movem	zo_lx(a2),d0/d2
	sub	d6,d0
	move	d0,(a1)+
	sub	d7,d2
	move	d2,(a1)+
	move.l	zo_na(a2),(a1)+
	;
	lea	32(a2),a2
	dbf	d1,.loop2
	;
	bra	exec_loop

exec_addobj	clr.l	dummy
	move	(a6)+,d0	;monster type
	lea	objinfo,a2
	mulu	#objinfof-objinfo,d0
	add.l	d0,a2
	move.l	(a2)+,a3
	tst.l	(a3)
	beq.s	.ok
.no	addq	#8,a6
	bra	exec_loop
.ok	cmp	#2,-2(a6)	;player?
	bcc.s	.notp
	addfirst	objects
	bra.s	.bum
.notp	addlast	objects
.bum	beq.s	.no
	move.l	a0,a5
	;
	move.l	a5,(a3)
	;
	move	(a6)+,ob_x(a5)
	move	(a6)+,ob_y(a5)
	move	(a6)+,ob_z(a5)
	move	(a6)+,ob_rot(a5)
	;
	lea	ob_info(a5),a3
	move	#(objinfof-objinfo-4)>>1-1,d0
.loop	move	(a2)+,(a3)+
	dbf	d0,.loop
	;
	tst	ob_blood(a5)	;hi bit of blood=1=invisible!
	smi	d0
	ext	d0
	move	d0,ob_invisible(a5)
	;
	bsr	calcvecs
	movem.l	d4-d5,ob_xvec(a5)
	;
	move.l	ob_shape(a5),a0
	move.l	4(a0),ob_chunks(a5)
	move.l	(a0),a0
	move.l	a0,ob_shape(a5)
	;
	move	an_maxw(a0),d0
	move	d0,ob_rad(a5)
	mulu	d0,d0
	move.l	d0,ob_radsq(a5)
	;
	clr.l	ob_washit(a5)
	;
	bsr	rnddelay
	;
	bra	exec_loop

rnddelay	move	ob_range(a5),d0
	bsr	rndn
	add	ob_base(a5),d0
	move	d0,ob_delay(a5)
	;
	rts

seedrnd	;seed number in d0.w
	;
	moveq	#54,d1
	lea	rndtable(pc),a0
	;
.loop	move	d0,(a0)+
	mulu	#$1efd,d0
	add	#$dff,d0
	dbf	d1,.loop
	;
	move.l	a0,k_index
	move.l	#rndtable+48,j_index
	rts

rndw	;return rnd number 0...65535 if d0.w
	;
	movem.l	a0/a1,-(a7)
	lea	rndtable(pc),a1
	move.l	j_index(pc),a0
	move	-(a0),d0
	cmp.l	a0,a1
	bne.s	.skip
	lea	rndtable+110(pc),a0
.skip	move.l	a0,j_index
	move.l	k_index(pc),a0
	add	-(a0),d0
	move	d0,(a0)
	cmp.l	a0,a1
	bne.s	.skip2
	lea	rndtable+110(pc),a0
.skip2	move.l	a0,k_index
	movem.l	(a7)+,a0/a1
	rts

rndtable	ds.w	55
k_index	dc.l	0
j_index	dc.l	0

rndl	bsr	rndw
	move	d0,d1
	bsr	rndw
	swap	d0
	move	d1,d0
	rts

rndn	move	d0,d1
	bsr	rndw
	mulu	d1,d0
	swap	d0
	rts

seedrnd2	;seed number in d0.w
	;
	moveq	#54,d1
	lea	rndtable2(pc),a0
	;
.loop	move	d0,(a0)+
	mulu	#$1efd,d0
	add	#$dff,d0
	dbf	d1,.loop
	;
	move.l	a0,k_index2
	move.l	#rndtable2+48,j_index2
	rts

rndw2	;return rnd number 0...65535 if d0.w
	;
	movem.l	a0/a1,-(a7)
	lea	rndtable2(pc),a1
	move.l	j_index2(pc),a0
	move	-(a0),d0
	cmp.l	a0,a1
	bne.s	.skip
	lea	rndtable2+110(pc),a0
.skip	move.l	a0,j_index2
	move.l	k_index2(pc),a0
	add	-(a0),d0
	move	d0,(a0)
	cmp.l	a0,a1
	bne.s	.skip2
	lea	rndtable2+110(pc),a0
.skip2	move.l	a0,k_index2
	movem.l	(a7)+,a0/a1
	rts

rndtable2	ds.w	55
k_index2	dc.l	0
j_index2	dc.l	0

rndl2	bsr	rndw2
	move	d0,d1
	bsr	rndw2
	swap	d0
	move	d1,d0
	rts

rndn2	move	d0,d1
	bsr	rndw2
	mulu	d1,d0
	swap	d0
	rts

calcangle2	;angle of camera to object in a5
	;
	move	camx(pc),d0
	sub	ob_x(a5),d0
	move	camz(pc),d1
	sub	ob_z(a5),d1
	bra.s	calcangle_

calcangle	;angle of object a5 to object a0...
	;
	move	ob_x(a0),d0
	sub	ob_x(a5),d0
	move	ob_z(a0),d1
	sub	ob_z(a5),d1
	;
calcangle_	;d0.w=x d1.w=y (dest-src)!
	;
	moveq	#0,d2
	tst	d1
	bpl.s	.hpos
	moveq	#16,d2
	neg	d1
.hpos	tst	d0
	bpl.s	.wpos
	eor	#8,d2
	neg	d0
.wpos	cmp	d1,d0
	bmi.s	.notsteep
	bne.s	.neq
	move	#$2000,d1
	bra.s	.flow
.neq	eor	#4,d2
	exg	d1,d0
.notsteep	tst	d1
	bne.s	.noflow
	moveq	#0,d1
	bra.s	.flow
.noflow	ext.l	d0
	swap	d0
	divu	d1,d0
	lsr	#6,d0
	and	#1022,d0
	move	.arc(pc,d0),d1
.flow	move.l	.oct(pc,d2),d0
	eor	d0,d1
	swap	d0
	add	d1,d0
	lsr	#8,d0
	rts
	;
.oct	dc	0,0,$4000,-1,0,-1,$c000,0
	dc	$8000,-1,$4000,0,$8000,0,$c000,-1
.arc	incbin	arc.bin

calcscene	;a5=player object
	;
	move	#$20,$dff09a
	;
	move.l	player_(pc),a0
	;
	move.l	ob_palette(a0),palette
	move	ob_thermo(a0),thermo
	move	ob_infra(a0),infra
	move	ob_pixsize(a0),pixsize
	;
	clr.l	shapelist
	bsr	calccamera
	bsr	makewalls
	;
	lea	objects(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.done
	cmp.l	player_(pc),a5
	beq.s	.loop
	move.l	ob_render(a5),a0
	tst	ob_invisible(a5)
	beq.s	.notinvs
	bpl.s	.hb
	move.l	#drawobjtrans,shaperender
	bra.s	.rit
.hb	move.l	#drawobjinvs,shaperender
.rit	move.l	a5,g2_shape_owner	;v126 owner for enemy blob shadow
	jsr	(a0)
	clr.l	g2_shape_owner
	move.l	#drawobjnorm,shaperender
	bra.s	.loop
.notinvs	move.l	a5,g2_shape_owner	;v126 owner for enemy blob shadow
	jsr	(a0)
	clr.l	g2_shape_owner
	bra.s	.loop
.done	;
	; v30: body-chunk/gore draw is enabled again.
	; Blood splats remain disabled for crash isolation.
	lea	gore(pc),a5
	;
.loop2	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.done2
	;
	movem	go_x(a5),d0/d2
	moveq	#0,d1
	move.l	go_shape(a5),a0
	move	#$200,d7
	clr.l	g2_shape_owner	;v126 gore/body chunks never get enemy shadows
	bsr	drawshape_q
	;
	bra.s	.loop2
	;
.done2	move	#$8020,$dff09a
	;
	rts

blitscene	;
	move.l	player_(pc),a5
	;
	; v103: teleport handoff blackout.  Once the last visible teleport pixel
	; frame has been reached, suppress gun/HUD/statusbar and C2P a clean black
	; frame.  The intermission is only shown after it has loaded.
	tst	g2teleport_blackout
	beq.s	.g2bs_not_blackout
	jsr	g2clearfullchunky
	clr	panelcnt
	rts
.g2bs_not_blackout
	;
	; v190gi: no lower statusbar/panel. Draw gun at the new bottom and
	; draw top HUD through the normal chunky/C2P path.
	bclr	#7,ob_update(a5)
	bsr	g2drawgun
	bsr	showstats
	clr	panelcnt
	rts

.noupdate	move	ob_messtimer(a5),d0
	bpl.s	.mskip
	addq	#1,d0
	beq.s	.mdone
	neg	ob_messtimer(a5)
	move.l	ob_window(a5),a0
	;bsr	putstrip
	bsr	printmess
	bra.s	.mskip
	;
.mdone	clr	ob_messtimer(a5)
	move.l	ob_window(a5),a0
	;bsr	putstrip
.mskip	;
	rts

drawscene	;a5=player
	; v28: pinpoint first-level crash inside drawscene.
	lea	g2log_msg_ds_enter,a0
	jsr	g2log_drawstep
	lea	g2log_msg_ds_cast_b,a0
	jsr	g2log_drawstep
	bsr	castwalls
	lea	g2log_msg_ds_cast_ok,a0
	jsr	g2log_drawstep
	lea	g2log_msg_ds_render_b,a0
	jsr	g2log_drawstep
	bsr	renderwalls
	lea	g2log_msg_ds_render_ok,a0
	jsr	g2log_drawstep
	; v190fx: real-Amiga safe order. Do not run the v190bb wallspan
	; void-fog pass before roof/floor; late neutral void-fog remains after flats.
	;
	move	roofflag(pc),d0
	ble.s	.g2v190dm_roof_fog
	lea	g2log_msg_ds_roof_b,a0
	jsr	g2log_drawstep
	move	#-255,d0
	sub	camy(pc),d0
	moveq	#1,d1
	move	miny(pc),d7
	move.l	roof(pc),a0
	bsr	flat
	lea	g2log_msg_ds_roof_ok,a0
	jsr	g2log_drawstep
	bra.s	.noroof
.g2v190dm_roof_fog
	moveq	#1,d1		; CEILING NO: fill ceiling area with neutral fog, not black bars
	move	miny(pc),d7
	jsr	g2fill_disabled_flat_fog
.noroof	;
	move	floorflag(pc),d0
	ble.s	.g2v190dm_floor_fog
	lea	g2log_msg_ds_floor_b,a0
	jsr	g2log_drawstep
	move	camy(pc),d0
	neg	d0
	moveq	#-1,d1
	move	maxy(pc),d7
	subq	#1,d7
	move.l	floor(pc),a0
	bsr	flat
	lea	g2log_msg_ds_floor_ok,a0
	jsr	g2log_drawstep
	bra.s	.nofloor
.g2v190dm_floor_fog
	moveq	#-1,d1		; FLOOR NO: fill floor area with neutral fog, not black bars
	move	maxy(pc),d7
	subq	#1,d7
	jsr	g2fill_disabled_flat_fog
.nofloor	;
	; v190bd: after floor/ceiling, fill any still-empty no-wall columns with
	; a global dark wall fog colour sampled earlier from a far wall.  This
	; keeps very long corridor openings dark instead of black, without
	; interfering with wall/floor rendering or copying texture rows.
	jsr	g2fill_void_fog_remaining
	lea	g2log_msg_ds_shapes_b,a0
	jsr	g2log_drawstep
	bsr	drawshapes
	lea	g2log_msg_ds_shapes_ok,a0
	jsr	g2log_drawstep
	; v17: original gloom2 had an early RTS here, making blood/pixelate reachable.
	lea	g2log_msg_ds_blood_b,a0
	jsr	g2log_drawstep
	; v31: safe chunky blood renderer re-enabled, legacy screen-splat disabled.
	bsr	drawblood
	lea	g2log_msg_ds_blood_ok,a0
	jsr	g2log_drawstep
	;
	; v99: ZGloom-style screen colour effects.  Teleport/exit uses pixsize
	; as a blue-white fade timer, then the existing pixelate pass runs.
	; Death/hit uses a transparent red screen tint while the eye-height death
	; animation already moves the view down.
	move.l	player_(pc),a0
	move	ob_pixsize(a0),d0
	beq.s	.g2ds_no_blue_tint
	jsr	g2apply_blue_tint
.g2ds_no_blue_tint
	move.l	player_(pc),a0
	tst	ob_paltimer(a0)
	bne.s	.g2ds_red_tint
	tst	ob_hitpoints(a0)
	bgt.s	.g2ds_no_red_tint
.g2ds_red_tint
	jsr	g2apply_red_tint
.g2ds_no_red_tint
	;
	move.l	player_(pc),a0
	move	ob_pixsize(a0),d0
	beq.s	.g2ds_no_pixel
	lea	g2log_msg_ds_pixel_b,a0
	jsr	g2log_drawstep
	jsr	pixelate
	lea	g2log_msg_ds_pixel_ok,a0
	jsr	g2log_drawstep
.g2ds_no_pixel
	lea	g2log_msg_ds_exit,a0
	jsr	g2log_drawstep
	rts

chatstuff	move	chatok(pc),d0
	beq.s	.rts
	;
	move	chatoutget,d0
	cmp	chatoutput,d0
	beq.s	.noout
	and	#31,d0
	lea	chatout,a0
	move.b	0(a0,d0),d0	;chat out character!
	addq	#1,chatoutget
	moveq	#1,d1
	move	d0,-(a7)
	bsr	chatprintout
	move	(a7)+,d0
	sub.b	#32,d0	;encode for chat
	bset	#6,d0
	bsr	serput
	;
.noout	move	chatcnt(pc),d0
	beq.s	.rts
	;
	move	chatinget,d0
	and	#31,d0
	lea	chatin,a0
	move.b	0(a0,d0),d0
	addq	#1,chatinget
	subq	#1,chatcnt
	moveq	#2,d1
	bsr	chatprintin
	;
.rts	rts

sfxvbint	lea	sfxs(pc),a1
	moveq	#3,d3
	;
.loop	tst	fx_status(a1)
	ble.s	.skip
	;
	;this one queued! gotta play it...
	;
	subq	#1,fx_status(a1)
	bgt.s	.skip
	move.l	fx_sfx(a1),a0
	bsr	playsfxnow
	;
.skip	lea	fx_size(a1),a1
	dbf	d3,.loop
	;
	;fade out song if nec.
	;
	move	fadevol(pc),d0
	beq.s	.nofade
	move.l	medat,a1
	sub	#$80,fadevol
	bgt.s	.setvol
	clr	fadevol
	jmp	12(a1)	;stop song
	bra.s	.nofade
	;
.setvol	move	fadevol(pc),d0
	lsr	#8,d0
	jmp	16(a1)	;set volume
	;
.nofade	rts

	dc.l	readmodem
; v34: KEYBMOUSE becomes control 0, matching stable gloom.s v29a/WAXD.
; joytable_end is used by inputon/inputoff so OS deactivation/EXIT cannot
; overwrite code while clearing the table.
joytable	dc.l	readnull,readnull,readnull,readnull,readnull,readnull
joytable_end
joytable2	dc.l	readkeymouse,readkeys,readjoy1,readjoy0,readcd321,readcd320

readjoy	;a0=player
	move	ob_cntrl(a0),d0
	bmi.s	readmodem
	;
	lea	joyx0,a0
	lea	0(a0,d0*8),a0
	move.l	joytable(pc,d0*4),a1
	jsr	(a1)
	move	linked(pc),d0
	bne.s	.send
	rts
.send	;
	;a0=cntrl block
	;
	bsr	encodejoy
	movem.l	d0/a0,-(a7)
	bsr	serput
	;movem.l	(a7),d0/a0
	;bsr	serput
	movem.l	(a7)+,d0/a0
	;
.noput	lea	pbuff(pc),a1
	;
	move	pput(pc),d1
	and	#127,d1
	move.b	d0,0(a1,d1)
	addq	#1,pput
	;
	move	pget(pc),d1
	and	#127,d1
	move.b	0(a1,d1),d0
	addq	#1,pget
	;
	bra	decodejoy
readmodem	;
	bsr	rbfchk
	bne.s	.serhere
	;
	;OK, do a vwait to allow other machine to catch up!
	;
	move	#$20,$dff09c
.vw	;
	ifne	debugser
	col	#$f0f
	endc
	;
	btst	#5,$dff01f
	beq.s	.vw
	;
	move	#$20,$dff09c
	bsr	chatstuff
	bra.s	readmodem
	;
.serhere	bsr	serget
	lea	joyxs,a0
	bclr	#7,d0
	beq.s	.djoy
	and	#$ff,d0
	move	d0,finished
	moveq	#0,d0
	;bra.s	.sgot
	;
.djoy	;movem.l	d0/a0,-(a7)
	;bsr	serwait
	;move	d0,d1
	;movem.l	(a7)+,d0/a0
	;cmp.b	d0,d1
	;beq.s	.sgot
	;
	;warn	#$fff
	;warn	#$00f
	;
.sgot	bsr	decodejoy
	move.l	(a0)+,joyx
	move.l	(a0),joyb
	rts

escape	dc	0

readjoys	;fill in appropriate 'joyxn' block...check escape
	;
	move	finished(pc),d0
	or	finished2(pc),d0
	bne.s	.rts
	;
	qkey	$45
	sne	escape
	;
	move.l	player1(pc),a0
	bsr	readjoy
	move	gametype(pc),d0
	beq.s	.rts
	move.l	player2(pc),a0
	bra	readjoy
	;
.rts	rts

lrnd	dc	0

vbhandler	movem.l	d2-d7/a2-a6,-(a7)
	;
	subq	#1,(a1)+	;inc/dec frame counters
	addq	#1,(a1)
	;
	; v34: sample/apply KEYBMOUSE mouse before drawing, as in stable v29a.
	jsr	sample_keymouse_vb
	;this done every frame!
	bsr	chatstuff
	bsr	sfxvbint
	;
	btst	#0,framecnt+1
	beq	exit_vb2
	tst	paused
	bne	exit_vb2
	;
	;OK, movement/animation stuff!
	;
	bsr	readjoys
	bsr	doanims
	bsr	dorots
	bsr	dodoors
	; v31: update blood particles again; draw path is guarded/chunky-safe.
	bsr	moveblood
	;
	ifne	debugser
	;
	;OK, kludge in a random number!
	move	framecnt(pc),d0
	and	#126,d0
	bne.s	.nornd
	;
	bsr	rndw
	move	lrnd(pc),d1
	move	d0,lrnd
	cmp	d0,d1
	bne.s	.hi
	warn	#$fff
	warn	#$00f
.hi	lea	.rndasc(pc),a0
	moveq	#3,d1
.loop	rol	#4,d0
	move	d0,d2
	and	#15,d2
	add	#48,d2
	cmp	#58,d2
	bcs.s	.rok
	addq	#7,d2
.rok	move.b	d2,(a0)+
	dbf	d1,.loop
	;
	move.l	player1(pc),a5
	bsr	message
.rndasc	dc.b	'aaaa',0
	even
	;
	endc
.nornd	;
	move.l	a7,obj_stack
	lea	objects(pc),a5
	;
obj_loop	move.l	(a5),a5
	tst.l	(a5)
	beq	exit_vb
	;
	move.l	ob_logic(a5),a0
	jsr	(a0)
	;
	;check collision!
	;
	move	ob_collwith(a5),d0
	beq.s	obj_loop
	;
	move	ob_rad(a5),d1
	move	ob_x(a5),d6
	move	ob_z(a5),d7
	;
	lea	objects(pc),a0
	;
.loop2	move.l	(a0),a0
	cmp.l	a5,a0
	bne.s	.this
	;
	clr.l	ob_washit(a5)	;not hit! can get hit next time...
	bra	obj_loop
.this	;
	move	ob_colltype(a0),d2
	and	d0,d2
	beq.s	.loop2
	;
	move	ob_rad(a0),d2
	add	d1,d2	;r sum
	;
	move	ob_x(a0),d3
	sub	d6,d3
	bpl.s	.xpl
	neg	d3
.xpl	cmp	d2,d3
	bcc.s	.loop2
	;
	move	ob_z(a0),d4
	sub	d7,d4
	bpl.s	.ypl
	neg	d4
.ypl	cmp	d2,d4
	bcc.s	.loop2
	;
	mulu	d2,d2
	mulu	d3,d3
	mulu	d4,d4
	add.l	d4,d3
	cmp.l	d2,d3
	bcc.s	.loop2
	;
	cmp.l	ob_washit(a5),a0
	beq	obj_loop
	move.l	a0,ob_washit(a5)
	;
	move	finished2(pc),d0
	bne	obj_loop
	;
	move.l	#killobject3,killjsr
	movem.l	a0/a5,obj_a0
	exg.l	a0,a5
	;
	move	ob_damage(a0),d0
	bsr	g2_onehit_damage
	move.l	ob_hit(a5),a1
	sub	d0,ob_hitpoints(a5)
	bgt.s	hit_skip
	move.l	ob_die(a5),a1
	;
hit_skip	jsr	(a1)
	;
hit_ret	move.l	#killobject2,killjsr
	movem.l	obj_a0(pc),a0/a5
	;
	move	ob_damage(a0),d0
	bsr	g2_onehit_damage
	move.l	ob_hit(a5),a1
	sub	d0,ob_hitpoints(a5)
	bgt.s	hit_skip2
	move.l	ob_die(a5),a1
	;
hit_skip2	jsr	(a1)
	bra	obj_loop

; v183: ONE-HIT-KILL cheat.  Only projectile objects get their damage
; raised to the target's remaining hitpoints, and players themselves are
; explicitly excluded so player/friendly damage is untouched.
g2_onehit_damage	; in/out d0=damage, a0=attacker, a5=victim
	tst	trainer_onehit
	beq.s	.rts
	tst	d0
	ble.s	.rts
	move.l	ob_logic(a0),d1
	cmp.l	#firelogic,d1
	beq.s	.projectile
	cmp.l	#homeinlogic,d1
	bne.s	.rts
.projectile
	move.l	player1(pc),d1
	cmp.l	d1,a5
	beq.s	.rts
	move.l	player2(pc),d1
	cmp.l	d1,a5
	beq.s	.rts
	move	ob_hitpoints(a5),d1
	ble.s	.rts
	move	d1,d0
.rts	rts
	;
exit_vb	st	doneflag
	;
exit_vb2	st	showflag
	;
	movem.l	(a7)+,d2-d7/a2-a6
	moveq	#0,d0
	;
rts	rts

obj_a0	dc.l	0
obj_a5	dc.l	0
obj_stack	dc.l	0
killjsr	dc.l	killobject2

killobject	;
	move.l	killjsr(pc),a0
	jmp	(a0)

killobject2	move.l	a5,a0
	killitem	objects
	move.l	a0,a5
	move.l	obj_stack(pc),a7
	bra	obj_loop

killobject3	move.l	a5,a0
	killitem	objects
	move.l	obj_stack(pc),a7
	bra	hit_ret

bloodspeed	bsr	rndw
	ext.l	d0
	lsl.l	#2,d0
	rts

bloodspeed2	bsr	rndw
	ext.l	d0
	lsl.l	#5,d0
	rts

bloodspeed3	bsr	rndw
	ext.l	d0
	lsl.l	#4,d0
	rts

makesparksq	move.l	ob_chunks(a5),a2
	;
makesparks	;a2=sparks
	;
	movem.l	ob_x(a5),d2-d4
	move	2(a2),d5
	subq	#1,d5
	;
.loop	addlast	objects
	beq	.rts
	movem.l	d2-d4,ob_x(a0)
	bsr	bloodspeed2
	move.l	d0,ob_xvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_yvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_zvec(a0)
	move.l	a2,ob_shape(a0)
	move	d5,ob_frame(a0)
	move.l	#sparkslogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	bsr	rndw
	and	#15,d0
	add	#15,d0
	move	d0,ob_delay(a0)
	dbf	d5,.loop
.rts	rts

sparkslogic	subq	#1,ob_delay(a5)
	ble	killobject
	movem.l	ob_x(a5),d0-d2
	add.l	ob_xvec(a5),d0
	add.l	ob_yvec(a5),d1
	add.l	ob_zvec(a5),d2
	movem.l	d0-d2,ob_x(a5)
	rts

bloodymess	;throw random blood splots everywhere!
	; v31: blood particles restored; drawblood uses safe chunky byte writes.
	bsr	bloodspeed2
	add.l	ob_x(a5),d0
	move.l	d0,d2
	bsr	bloodspeed2
	add.l	ob_gutsy(a5),d0
	move.l	d0,d3
	bsr	bloodspeed2
	add.l	ob_z(a5),d0
	move.l	d0,d4
	;
.loop	addlast	blood
	beq.s	.done
	;
	movem.l	d2-d4,bl_x(a0)
	bsr	bloodspeed
	move.l	d0,bl_xvec(a0)
	bsr	bloodspeed
	move.l	d0,bl_yvec(a0)
	bsr	bloodspeed
	move.l	d0,bl_zvec(a0)
	move	ob_blood(a5),bl_color(a0)
	;
	dbf	d7,.loop
	;
.done	rts

bloodymess2	;throw random blood splots everywhere!
	; v31: blood particles restored; drawblood uses safe chunky byte writes.
	bsr	bloodspeed2
	add.l	ob_x(a5),d0
	move.l	d0,d2
	bsr	bloodspeed2
	add.l	ob_gutsy(a5),d0
	move.l	d0,d3
	bsr	bloodspeed2
	add.l	ob_z(a5),d0
	move.l	d0,d4
	;
.loop	addlast	blood
	beq.s	.done
	;
	movem.l	d2-d4,bl_x(a0)
	bsr	bloodspeed3
	move.l	d0,bl_xvec(a0)
	bsr	bloodspeed3
	move.l	d0,bl_yvec(a0)
	bsr	bloodspeed3
	move.l	d0,bl_zvec(a0)
	move	ob_blood(a5),bl_color(a0)
	;
	dbf	d7,.loop
	;
.done	rts

chunklogic	move	mode(pc),d0
	beq	chunklogic2
	;
	add.l	#$8000,ob_yvec(a5)
	move.l	ob_yvec(a5),d0
	add.l	ob_y(a5),d0
	blt	.skip
	;
	;OK...hit ground!
	;
	bsr	splat
	addlast	gore
	bne.s	.gok
	;
	move.l	gore(pc),a0
	killitem	gore
	addlast	gore
	beq	killobject
	;
.gok	move	ob_x(a5),go_x(a0)
	move	ob_z(a5),go_z(a0)
	move.l	ob_shape(a5),a1
	move	ob_frame(a5),d0
	add.l	12(a1,d0*4),a1
	move.l	a1,go_shape(a0)
	;
	bra	killobject
	;
.skip	move.l	d0,ob_y(a5)
	bsr	checkvecs
	beq.s	.rts
	clr.l	ob_xvec(a5)
	clr.l	ob_zvec(a5)
.rts	rts

chunklogic2	add.l	#$8000,ob_yvec(a5)
	move.l	ob_yvec(a5),d0
	add.l	d0,ob_y(a5)
	blt.s	.ok
	;bsr	splat
	bra	killobject
.ok	movem.l	ob_xvec(a5),d0-d1
	add.l	d0,ob_x(a5)
	add.l	d1,ob_z(a5)
	rts

splat	move.l	splatsfx(pc),a0
	moveq	#32,d0
	moveq	#-1,d1
	bra	playsfx

blowterra	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#20,d1
	bsr	playsfx
	bra	blowquick

blowdragon	;same, but messier...
	;
	;loud!
	;
	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	;
	moveq	#63,d7
	bsr	bloodymess2
	;
	move.l	ob_chunks(a5),a4
	bsr	blowchunx
	bsr	blowchunx
	bsr	blowchunx
	bsr	blowchunx
	;
	move.l	#dragondead,ob_logic(a5)
	move.l	#rts,ob_render(a5)
	clr	ob_colltype(a5)
	clr	ob_collwith(a5)
	move	#127,ob_delay(a5)
	rts

dragondead	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	move	#3,finished
	;
.rts	rts

blowdeath	cmp.l	sucker(pc),a5
	bne.s	blowobject
	clr.l	sucker
	clr.l	sucking
	;
blowobject	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr	playsfx
blowquick	;
	moveq	#31,d7
	bsr	bloodymess2
	;
	move.l	ob_chunks(a5),d0
	bne.s	.chok
	;
	moveq	#15,d7
	bsr	bloodymess2
	bra	killobject
	;
.chok	move.l	d0,a4
	bsr	blowchunx
	bra	killobject

blowchunx	; v30: body chunks enabled again; blood particle creation remains disabled.
	move	2(a4),d7
	subq	#1,d7
	;
.loop	addlast	objects
	beq	killobject
	movem.l	ob_x(a5),d0-d2
	move.l	#-64<<16,d1
	movem.l	d0-d2,ob_x(a0)
	;
	bsr	bloodspeed3
	move.l	d0,ob_xvec(a0)
	bsr	bloodspeed3
	sub.l	#$40000,d0
	move.l	d0,ob_yvec(a0)
	bsr	bloodspeed3
	move.l	d0,ob_zvec(a0)
	;
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	move.l	#chunklogic,ob_logic(a0)
	move.l	a4,ob_shape(a0)
	move.l	#drawshape_1sc,ob_render(a0)
	move	d7,ob_frame(a0)
	move	ob_scale(a5),ob_scale(a0)
	;
	move	an_maxw(a4),d0
	move	d0,ob_rad(a0)
	mulu	d0,d0
	move.l	d0,ob_radsq(a0)
	;
	dbf	d7,.loop
	rts

hurtdeath	;OK! death head hit!
	;
	;point at player, and start to suck his soul!
	;
	move.l	sucking(pc),d0
	bne.s	.rts
	;
	bsr	pickplayer
	cmp.l	#playerlogic,ob_logic(a0)
	bne.s	.rts
	;
	move.l	a0,sucking
	move.l	a5,sucker
	;
	move	ob_rot(a5),ob_oldrot(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#deathsuck,ob_logic(a5)
	move.l	#rts,ob_hit(a5)
	move	#64,ob_delay(a5)
	bra.s	deathsuck
	;
.rts	rts

deathsuck	;death head sucking out a players soul!
	;
	bsr	deathbounce
	bsr	deathanim
	subq	#1,ob_delay(a5)
	bgt.s	.more
	move	ob_oldrot(a5),ob_rot(a5)
	move.l	ob_oldlogic(a5),ob_logic(a5)
	move.l	#hurtdeath,ob_hit(a5)
	clr.l	sucker
	clr.l	sucking
	bra	rnddelay
	;
.more	move.l	sucking(pc),a0
	move.l	a0,a2
	bsr	calcangle	;point at player!
	move	d0,ob_rot(a5)
	;
	add	#128,d0
	and	#255,d0
	move.l	camrots(pc),a3
	lea	0(a3,d0*8),a3
	;
	move.l	a3,suckangle
	;
	;calc x/z vecs
	;
	moveq	#3,d7
	bsr	addsoul
	;
.rts	rts

sucker	dc.l	0
sucking	dc.l	0
suckangle	dc.l	0

addsoul	;d7 times!
	;
	addlast	blood
	beq	.rts
	;
	move	2(a3),d2
	ext.l	d2
	lsl.l	#5,d2
	neg.l	d2
	move	6(a3),d3
	ext.l	d3
	lsl.l	#5,d3
	;
	move.l	d2,bl_xvec(a0)
	move.l	a5,bl_yvec(a0)
	move.l	d3,bl_zvec(a0)
	;
	swap	d2
	swap	d3
	add	d2,d2
	add	d3,d3
	add	ob_x(a2),d2
	add	ob_z(a2),d3
	;
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	d2,d0
	move	d0,bl_x(a0)
	;
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	#110,d0
	move	d0,bl_y(a0)	;>0= funny blood!
	;
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	d3,d0
	move	d0,bl_z(a0)
	;
	bsr	rndw
	and	#1,d0
	move	soulcols(pc,d0*2),bl_color(a0)
	;
	dbf	d7,addsoul
	;
.rts	rts

soulcols	dc	$0ff,$0f0

hurtghoul	moveq	#31,d7
	bsr	bloodymess
	rts

hurtterra	move.l	a0,-(a7)
	move.l	shootsfx2(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr	playsfx
	move.l	(a7)+,a0
	bra.s	hurtobject

hurtngrunt	move.l	a0,-(a7)
	bsr	rndw
	and	#3,d0
	cmp	lastgrunt(pc),d0
	bne.s	.new
	addq	#1,d0
	and	#3,d0
.new	move	d0,lastgrunt
	lea	grunttable(pc),a0
	move.l	0(a0,d0*4),a0
	move.l	(a0),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr	playsfx
	move.l	(a7)+,a0
	;
hurtobject	move	ob_colltype(a0),d0
	and	#24,d0
	bne.s	.rts
	;
	moveq	#23,d7
	bsr	bloodymess
	move	ob_hurtpause(a5),ob_hurtwait(a5)
	beq	.rts
	;
	move	#4,ob_frame(a5)
	move.l	ob_logic(a5),ob_oldlogic2(a5)
	move.l	ob_hit(a5),ob_oldhit(a5)
	move.l	#pauselogic2,ob_logic(a5)
	move.l	#rts,ob_hit(a5)
	;
.rts	rts

lizhurt	move.l	a0,-(a7)
	move.l	lizhitsfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr	playsfx
	move.l	(a7)+,a0
	bra	hurtobject

trollhurt	move.l	a0,-(a7)
	move.l	trollhitsfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr	playsfx
	move.l	(a7)+,a0
	bra	hurtobject

pauselogic2	subq	#1,ob_hurtwait(a5)
	bgt.s	.rts
	clr	ob_frame(a5)
	move.l	ob_oldlogic2(a5),ob_logic(a5)
	move.l	ob_oldhit(a5),ob_hit(a5)
.rts	rts

pauselogic	subq	#1,ob_delay(a5)
	bgt.s	.skip
	;
	bsr	rnddelay
	move.l	ob_oldlogic(a5),ob_logic(a5)
	;
	;if in front of player, continue on old course...
	;
	bsr	pickcalc
	;
	move	ob_rot(a0),d1
	and	#255,d1
	sub	d0,d1
	bpl.s	.pl
	neg	d1
.pl	cmp	#64,d1
	bcs.s	.skip
	cmp	#192,d1
	bcc.s	.skip
	;
.useold	move	ob_oldrot(a5),ob_rot(a5)
	bsr	calcvecs
	;
.skip	rts

g2apply_player_muzzle_origin
	movem.l	d0-d2/a1,-(a7)
	move.l	a5,d1
	move.l	player1(pc),d0
	cmp.l	d1,d0
	beq.s	.g2amo_do
	move.l	player2(pc),d0
	cmp.l	d1,d0
	bne.s	.g2amo_done
.g2amo_do
	; v68: ZGloom muzzle-origin approximation.  Spawn player bullets
	; slightly in front of the player so the projectile appears to leave
	; the weapon instead of emerging from behind the statusbar.
	move	ob_rot(a5),d0
	and	#255,d0
	move.l	camrots(pc),a1
	lea	0(a1,d0*8),a1
	move	#28,d0		;v120: restore original muzzle-origin base offset
	move	d0,d2
	muls	2(a1),d0
	add.l	d0,d0
	neg.l	d0
	add.l	d0,ob_x(a0)
	muls	6(a1),d2
	add.l	d2,d2
	add.l	d2,ob_z(a0)
	; v80: ZGloom keeps the shot y unchanged here.  The projectile height
	; already comes from ob_firey(a5) in shoot above; adding another negative
	; offset made the first projectile appear too high and huge on screen.
.g2amo_done
	movem.l	(a7)+,d0-d2/a1
	rts

g2player_bullet_visual_prestep
	movem.l	d0-d1,-(a7)
	move.l	a5,d0
	cmp.l	player1,d0
	beq.s	.do
	cmp.l	player2,d0
	bne.s	.done
.do	movem.l	ob_xvec(a0),d0-d1
	add.l	d0,ob_x(a0)
	add.l	d1,ob_z(a0)
	add.l	d0,ob_x(a0)
	add.l	d1,ob_z(a0)
	add.l	d0,ob_x(a0)
	add.l	d1,ob_z(a0)
.done	movem.l	(a7)+,d0-d1
	rts

shoot	;
	;fire off a bullet...
	;
	;d2 : colltype
	;d3 : collwith
	;d4 : hitpoints
	;d5 : damage
	;d6 : speed
	;a2=bullet shape
	;a3=sparks shape
	;
	addfirst	objects
	beq	.rts
	;
	move	ob_bouncecnt(a5),ob_bouncecnt(a0)
	move	ob_x(a5),ob_x(a0)
	move	ob_y(a5),d0
	add	ob_firey(a5),d0
	move	d0,ob_y(a0)
	move	ob_z(a5),ob_z(a0)
	bsr	g2apply_player_muzzle_origin
	move.l	#firelogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	move.l	#rts,ob_hit(a0)
	move.l	#killobject,ob_die(a0)
	move	d2,ob_colltype(a0)
	move	d3,ob_collwith(a0)
	move	d4,ob_hitpoints(a0)
	move	d5,ob_damage(a0)
	move	d6,ob_movspeed(a0)
	move.l	a2,ob_shape(a0)
	clr	ob_invisible(a0)
	clr	ob_frame(a0)
	move.l	a3,ob_chunks(a0)
	;
	move	ob_rot(a5),d0
	and	#255,d0
	move.l	camrots(pc),a1
	lea	0(a1,d0*8),a1
	;
	move	2(a1),d0
	move	d0,ob_nxvec(a0)
	neg	d0
	muls	d6,d0
	add.l	d0,d0
	move	6(a1),d1
	move	d1,ob_nzvec(a0)
	muls	d6,d1
	add.l	d1,d1
	;
	movem.l	d0-d1,ob_xvec(a0)
	; v120: player bullets need a visual pre-step after the real flight
	; vector is known.  The old #28/#34/#50 base offset alone was too
	; small visually for the big weapon-4/5 projectile sprites.
	bsr	g2player_bullet_visual_prestep
	;
	move	#32,ob_rad(a0)
	move.l	#32*32,ob_radsq(a0)
	;
.rts	rts

pickcalc	;pick a player and calculate angle to player!
	;
	bsr	pickplayer
	bsr	calcangle
	tst	ob_invisible(a0)
	beq.s	.rts
	move	d0,-(a7)
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	(a7)+,d0
	and	#255,d0
.rts	rts

fire1	bsr	pickcalc
	;
	;random noise for inaccuracy!
	;
	move	d0,-(a7)
	bsr	rndw
	and	#31,d0
	sub	#16,d0
	add	(a7)+,d0
	and	#255,d0
	;
	move	d0,ob_rot(a5)
	bsr	calcvecs
	move	#7,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#pauselogic,ob_logic(a5)
	clr.l	ob_frame(a5)
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#1,d5	;damage
	moveq	#20,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet1,a2
	lea	sparks1,a3
	;
	bsr	shoot
	;
	rts

pickplayer	;pick nearest player
	;
	move.l	player1(pc),a0
	move	gametype(pc),d0
	beq.s	.rts
	move.l	player2(pc),a1
	move	linked(pc),d0
	bpl.s	.nosw
	exg	a0,a1
.nosw	;
	tst	ob_hitpoints(a0)
	beq	.sw
	tst	ob_hitpoints(a1)
	beq.s	.rts
	;
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0	;dist to player a0
	;
	move	ob_x(a5),d1
	sub	ob_x(a1),d1
	muls	d1,d1
	move	ob_z(a5),d2
	sub	ob_z(a1),d2
	muls	d2,d2
	add.l	d2,d1	;dist to player a1
	;
	cmp.l	d1,d0
	bcs.s	.rts
	;
.sw	move.l	a1,a0
	;
.rts	rts

checkcoll	;check for collision between a5, and a0
	;
	move	ob_rad(a5),d1
	move	ob_rad(a0),d2
	add	d1,d2	;r sum
	;
	move	ob_x(a0),d3
	sub	ob_x(a5),d3
	bpl.s	.xpl
	neg	d3
.xpl	cmp	d2,d3
	bcc.s	.no
	;
	move	ob_z(a0),d4
	sub	ob_z(a5),d4
	bpl.s	.ypl
	neg	d4
.ypl	cmp	d2,d4
	bcc.s	.no
	;
	mulu	d2,d2
	mulu	d3,d3
	mulu	d4,d4
	add.l	d4,d3
	cmp.l	d2,d3
	bcc.s	.no
	;
	moveq	#-1,d0
	rts
	;
.no	moveq	#0,d0
	rts

baldycharge	;
	;baldy charging at player!
	;
	bsr	checkvecs
	beq	baldy_skip
	;
baldy_tonorm	move.l	ob_movspeed(a5),d0
	lsr.l	#2,d0
	move.l	d0,ob_movspeed(a5)
	;
	move.l	ob_framespeed(a5),d0
	lsr.l	#2,d0
	move.l	d0,ob_framespeed(a5)
	;
	move.l	ob_oldlogic(a5),ob_logic(a5)
	bsr	rnddelay
	;
	bra	monsterfix
	;
baldy_skip	;close to player? start throwing punches around!
	;
	bsr	pickcalc
	;
	sub	ob_rot(a5),d0
	cmp	#32,d0
	bgt	baldy_tonorm
	cmp	#-32,d0
	blt	baldy_tonorm
	;
	move.l	a0,ob_washit(a5)
	bsr	checkcoll
	beq	monsternew	;no collisions!
	;
	;go into punch mode!
	;
	move.l	#baldypunch,ob_logic(a5)
	move	ob_punchrate(a5),ob_delay(a5)
	clr.l	ob_frame(a5)
	rts

baldypunch	;
	bsr	pickplayer
	bsr	checkcoll
	bne.s	.doit
	;
	clr.l	ob_frame(a5)
	bra	baldy_tonorm
	;
.doit	subq	#1,ob_delay(a5)
	ble.s	.punch
	rts
.punch	move	ob_punchrate(a5),ob_delay(a5)
	moveq	#0,d0	;stand frame
	cmp	ob_frame(a5),d0
	bne	.skip
	;
	clr.l	ob_washit(a5)	;punch!
	bsr	calcangle
	move	d0,ob_rot(a5)
	moveq	#5,d0
.skip	move	d0,ob_frame(a5)
	rts

calcbangle	bsr	calcangle
	tst	ob_invisible(a0)
	beq.s	.notinv
	;
	;invisible, add some randomeness!
	;
	move	d0,-(a7)
	bsr	rndw
	and	#127,d0
	sub	#64,d0
	add	(a7)+,d0
	and	#255,d0
	;
.notinv	move	d0,ob_rot(a5)
	rts

trolllogic	move	ob_rad(a5),d0
	mulu	#$a000,d0
	swap	d0
	move	d0,ob_rad(a5)
	mulu	d0,d0
	move.l	d0,ob_radsq(a5)
	move.l	#trolllogic2,ob_logic(a5)
	;
trolllogic2	subq	#1,ob_delay(a5)
	bgt	monstermove	;charge?
	;
	bsr	pickcalc	;pic player in a0!
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#320*320,d0
	bcc	bl2
	;
	move.l	trollsfx(pc),a0
	moveq	#64,d0
	moveq	#5,d1
	bsr	playsfx
	;
	bra	bl2

lizardlogic	;
	subq	#1,ob_delay(a5)
	bgt	monstermove	;charge?
	;
	bsr	pickcalc	;pic player in a0!
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#256*256,d0
	bcc.s	bl2
	;
	move.l	lizsfx(pc),a0
	moveq	#32,d0
	moveq	#5,d1
	bsr	playsfx
	;
	bra	bl2

baldylogic	;
	;OK, what can baldy do...
	;
	;how about, walk around similar to the marine, but randomly 
	;charge at you?
	;
	;then, if he's close enough, he throws a punch!
	;
	subq	#1,ob_delay(a5)
	bgt	monstermove	;charge?
	;
bl2	bsr	pickcalc
	move	d0,ob_rot(a5)
	;
	move.l	ob_movspeed(a5),d0
	lsl.l	#2,d0
	move.l	d0,ob_movspeed(a5)
	move.l	ob_framespeed(a5),d0
	lsl.l	#2,d0
	move.l	d0,ob_framespeed(a5)
	;
	bsr	calcvecs
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#baldycharge,ob_logic(a5)
	;
	rts

terralogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	ble	.fire
	;
	move	ob_delay(a5),d0
	and	#31,d0
	bne	monstermove
	;
	move.l	robotsfx(pc),a0
	moveq	#64,d0
	moveq	#10,d1
	bsr	playsfx
	bra	monstermove
	;
.fire	;OK, terra goes apeshit! stand there firing off at player!
	;use punchrate as firedelay!
	;
	clr	ob_frame(a5)
	move	#1,ob_delay(a5)
	move	ob_firecnt(a5),ob_delay2(a5)
	move.l	#terralogic2,ob_logic(a5)
	rts

terralogic2	;
	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	move	ob_firerate(a5),ob_delay(a5)
	;
	;OK, to to face player and fire away!
	;
	bsr	pickcalc
	move	d0,ob_rot(a5)
	bsr	calcvecs
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#15,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet4,a2
	lea	sparks4,a3
	;
	bsr	shoot
	;
	move.l	shootsfx3(pc),a0
	moveq	#32,d0
	moveq	#5,d1
	bsr	playsfx
	;
	subq	#1,ob_delay2(a5)
	bgt.s	.rts
	;
	bsr	rnddelay
	move.l	#terralogic,ob_logic(a5)
	;
.rts	rts

ghoullogic	;
	addq	#8,ob_bounce(a5)
	move	ob_bounce(a5),d0
	move.l	camrots(pc),a0
	and	#255,d0
	move	0(a0,d0*8),d0
	ext.l	d0
	lsl.l	#5,d0	;+/- 32
	swap	d0
	add	#-32,d0
	move	d0,ob_y(a5)
	;
	bsr	pickcalc
	move	d0,ob_rot(a5)
	;
	subq	#1,ob_delay(a5)
	bgt.s	.skip
	;
	move	#1,ob_frame(a5)
	move.l	#$2000,ob_framespeed(a5)
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#20,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet2,a2
	lea	sparks2,a3
	;
	bsr	shoot
	bsr	rnddelay
	;
.skip	;OK, ghoul moves around ignoring walls!
	;
	;he's pointed at player...how about randomly selected to make 
	;this his new movement vector?
	;
	bsr	rndw
	move	ob_movspeed(a5),d1
	lsl	#8,d1
	cmp	d1,d0
	bcc.s	.no
	;
	bsr	calcvecs
	;
	move.l	ghoulsfx(pc),a0
	moveq	#32,d0
	moveq	#-5,d1
	bsr	playsfx
	;
.no	movem.l	ob_xvec(a5),d0-d1
	add.l	d0,ob_x(a5)
	add.l	d1,ob_z(a5)
	;
	move.l	ob_framespeed(a5),d0
	beq.s	.rts
	add.l	d0,ob_frame(a5)
	cmp	#3,ob_frame(a5)
	bcs.s	.rts
	;
	clr	ob_frame(a5)
	clr.l	ob_framespeed(a5)
	;
.rts	rts

demonpause	move	ob_delay(a5),d0
	move	d0,d1
	and	#4,d0
	sne	d0
	ext	d0
	and	#5,d0	;0 or 5
	move	d0,ob_frame(a5)
	;
	and	#7,d1	;do a fire?
	cmp	#7,d1
	bne.s	.nofire
	;
	move	ob_delay(a5),d0
	lsr	#3,d0
	mulu	#18,d0
	lea	wtable(pc),a0
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	movem	0(a0,d0),d4-d6	;hits,dam,speed
	mulu	#$c000,d5
	swap	d5	;3/4 damage!
	moveq	#0,d7	;acc
	movem.l	6(a0,d0),a2-a3	;bullets/sparks
	move.l	14(a0,d0),-(a7)	;sfx!
	;
	bsr	shoot
	;
	move.l	(a7)+,a0
	move.l	(a0),a0
	moveq	#32,d0
	moveq	#0,d1
	bsr	playsfx
	;
.nofire	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	bsr	rnddelay
	move.l	ob_oldlogic(a5),ob_logic(a5)
	;
.rts	rts

demonlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	bgt	monstermove
	;
	bsr	pickcalc
	;
	move	d0,ob_rot(a5)
	bsr	calcvecs
	move	#5<<3-1,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#demonpause,ob_logic(a5)
	;
	rts

phantomlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	bgt	monstermove
	;
	bsr	pickcalc
	;
	move	d0,ob_rot(a5)
	bsr	calcvecs
	move	#7,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#pauselogic,ob_logic(a5)
	move	#5,ob_frame(a5)
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#20,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet3,a2
	lea	sparks3,a3
	;
	bra	shoot

deathbounce	addq	#4,ob_bounce(a5)
	move	ob_bounce(a5),d0
	move.l	camrots(pc),a0
	and	#255,d0
	move	0(a0,d0*8),d0
	ext.l	d0
	lsl.l	#5,d0	;+/- 64
	swap	d0
	add	#-48,d0
	move	d0,ob_y(a5)
	rts

deathheadlogic	;
	;cruises around rotating at speed ob_delay
	;
	bsr	deathbounce
	;
	bsr	checkvecs
	bne.s	.hit
	;
	;charge player?
	;
	bsr	pickcalc	;find angle to player
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d0,d1	;am I near?
	bpl.s	.ansk
	neg	d1
.ansk	cmp	#16,d1
	bcc.s	.notnear
	;
	;OK! chargaroony!
	;
	move	d0,ob_rot(a5)
	move.l	#deathcharge,ob_logic(a5)
	bra	calcvecs
.hit	add	#128,ob_rot(a5)
	bsr	rnddelay
.notnear	move	ob_delay(a5),d0
	add	d0,ob_rot(a5)
	bsr	calcvecs
	rts

deathanim	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	cmp.l	#$8000,ob_frame(a5)
	blt.s	.fix
	cmp.l	#$28000,ob_frame(a5)
	blt.s	.fok
.fix	neg.l	d0
	add.l	d0,ob_frame(a5)
	move.l	d0,ob_framespeed(a5)
	;
.fok	rts

deathcharge	bsr	deathbounce
	bsr	deathanim
	;
	bsr	pickcalc
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d1,d0	;am I near?
	bpl.s	.ansk
	neg	d0
.ansk	cmp	#128,d0
	bcc.s	.hit
	bsr	checkvecs
	bne.s	.hit2
	rts
.hit2	add	#128,ob_rot(a5)
.hit	move.l	#deathheadlogic,ob_logic(a5)
	move.l	#$8000,ob_frame(a5)
	bra	rnddelay

monsterlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	;monster cruising around minding his own business...
	;
	subq	#1,ob_delay(a5)
	ble	fire1
	;
monstermove	bsr	checkvecs
	beq.s	monsternew
	;
	;OK, try 90/-90 degrees...
	;
monsterfix	bsr	rndw
	moveq	#64,d1
	tst	d0
	bpl.s	.umk
	moveq	#-64,d1
.umk	add	d1,ob_rot(a5)
	bsr	calcvecs
	bsr	checkvecs
	beq.s	monsternew
	;
	add	#128,ob_rot(a5)
	bsr	calcvecs
	bsr	checkvecs
	beq.s	monsternew
	;
	move	ob_oldrot(a5),d0
	add	#128,d0
	move	d0,ob_rot(a5)
	;
	bsr	calcvecs
	bsr	checkvecs
monsternew	;
	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

dragonfire	;dragon fires at you!
	;
	;d2 : colltype
	;d3 : collwith
	;d4 : hitpoints
	;d5 : damage
	;d6 : speed
	;a2=bullet shape
	;a3=sparks shape
	;
	subq	#1,ob_delay(a5)
	bpl	.rts
	move	ob_delay(a5),d0
	cmp	#-16*8,d0
	bgt.s	.try
	move	#47,ob_delay(a5)
	rts
.try	and	#7,d0
	bne	.rts
	;
.fire	moveq	#0,d2	;colltype
	moveq	#24+3,d3	;collwith - p1/p2/bullets
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#15,d6	;speed
	lea	bullet5,a2
	lea	sparks5,a3
	;
	addlast	objects
	beq	.rts
	;
	move	ob_bouncecnt(a5),ob_bouncecnt(a0)
	move	ob_x(a5),ob_x(a0)
	move	ob_y(a5),d0
	add	ob_firey(a5),d0
	move	d0,ob_y(a0)
	move	ob_z(a5),ob_z(a0)
	move.l	#homeinlogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	move.l	#makesparksq,ob_hit(a0)
	move.l	#blowdb,ob_die(a0)
	move	d2,ob_colltype(a0)
	move	d3,ob_collwith(a0)
	move	d4,ob_hitpoints(a0)
	move	d5,ob_damage(a0)
	move	d6,ob_movspeed(a0)
	move.l	a2,ob_shape(a0)
	clr	ob_invisible(a0)
	clr	ob_frame(a0)
	move.l	a3,ob_chunks(a0)
	;
	move	ob_rot(a5),d0
	and	#255,d0
	move.l	camrots(pc),a1
	lea	0(a1,d0*8),a1
	;
	move	2(a1),d0
	move	d0,ob_nxvec(a0)
	neg	d0
	muls	d6,d0
	add.l	d0,d0
	move	6(a1),d1
	move	d1,ob_nzvec(a0)
	muls	d6,d1
	add.l	d1,d1
	;
	movem.l	d0-d1,ob_xvec(a0)
	;
	move	#32,ob_rad(a0)
	move.l	#32*32,ob_radsq(a0)
	;
.rts	rts

blowdb	bsr	makesparksq
	bra	killobject

homeinlogic	bsr	checkvecs
	bne.s	blowdb
	bsr	pickcalc	;find angle to player!
	move.l	camrots(pc),a0
	lea	0(a0,d0*8),a0
	move	2(a0),d4	;x acc.
	neg	d4
	ext.l	d4
	lsl.l	#2,d4
	move	6(a0),d5	;z acc.
	ext.l	d5
	lsl.l	#2,d5
	;
	add.l	ob_xvec(a5),d4
	move.l	d4,d0
	bpl.s	.pl1
	neg.l	d0
.pl1	cmp.l	#$200000,d0	;max speed
	bcc.s	.sk1
	move.l	d4,ob_xvec(a5)
	;
.sk1	add.l	ob_zvec(a5),d5
	move.l	d5,d0
	bpl.s	.pl2
	neg.l	d0
.pl2	cmp.l	#$200000,d0
	bcc.s	.sk2
	move.l	d5,ob_zvec(a5)
.sk2	;
	bra	putfire

dragonanim	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

getobrot	move	ob_rotspeed(a5),d0
	bne.s	.addr
	;
	;OK, randomly left/rite!
	;
	bsr	rndw
	and	#1,d0
	bne.s	.addr2
	moveq	#-1,d0
	;
.addr2	lsl	#2,d0
	move	d0,ob_rotspeed(a5)
	;
.addr	rts

dragonlogic	;OK! end of game baddy!
	;
	;how about cruising around in a circle a-la
	;deathhead!
	;
	bsr	dragonanim
	bsr	dragonfire
	bsr	checkvecs
	beq.s	.nohit
	;
	;OK, dragon has hit a wall...rot him around till he's clear!
	;
	bsr	getobrot
	lsl	#2,d0
	add	d0,ob_rot(a5)
	bra	calcvecs
.nohit	;
	bsr	pickcalc
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d0,d1	;am I near?
	bpl.s	.ansk
	neg	d1
.ansk	moveq	#6,d0
	tst	ob_rotspeed(a5)
	bne.s	.sh
	moveq	#24,d0
.sh	cmp	d0,d1
	bcs.s	.near
	;
	;not pointed at player!
	bsr	getobrot
	add	d0,ob_rot(a5)
	bra	calcvecs
	;
.near	tst	ob_rotspeed(a5)
	beq.s	.near2
	clr	ob_rotspeed(a5)	;towards player!
	;
	move.l	dragonsfx(pc),a0
	moveq	#64,d0
	moveq	#20,d1
	bsr	playsfx
	;
.near2	rts

weaponlogic	;
	move.l	camrots(pc),a0
	;
	addq	#8,ob_movspeed(a5)
	move	ob_movspeed(a5),d0
	and	#127,d0
	move	2(a0,d0*8),d0
	asr	#8,d0
	move	d0,ob_y(a5)
	;
	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	move	ob_frame(a5),d0
	move.l	ob_shape(a5),a0
	cmp	2(a0),d0
	bcs.s	.skip
	clr	ob_frame(a5)
.skip	;
	subq	#1,ob_delay(a5)
	bgt	.rts
	bsr	rnddelay
	;
	addlast	objects
	beq.s	.rts
	;
	movem.l	ob_x(a5),d2-d4
	movem.l	d2-d4,ob_x(a0)
	bsr	bloodspeed2
	move.l	d0,ob_xvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_yvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_zvec(a0)
	move.l	ob_chunks(a5),a2
	move.l	a2,ob_shape(a0)
	move	2(a2),d0
	bsr	rndn
	move	d0,ob_frame(a0)
	move.l	#sparkslogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	bsr	rndw
	and	#15,d0
	add	#15,d0
	move	d0,ob_delay(a0)
.rts	rts

calcvecs	move	ob_rot(a5),d0
	;
	and	#255,d0
	move.l	camrots(pc),a0
	lea	0(a0,d0*8),a0
	;
	move	ob_movspeed(a5),d4
	move	d4,d5
	muls	2(a0),d4
	add.l	d4,d4
	neg.l	d4
	move.l	d4,ob_xvec(a5)
	muls	6(a0),d5
	add.l	d5,d5
	move.l	d5,ob_zvec(a5)
	rts

checkvecs	movem.l	ob_xvec(a5),d6-d7
	add.l	ob_x(a5),d6
	add.l	ob_z(a5),d7
	bsr	checknewslow	;ok to stand here?
	beq.s	.ok
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bsr	checknewslow
	bne.s	.fix
	moveq	#-1,d1	;use old pos, and report hit!
	rts
	;
.fix	bsr	adjustposq	;fixup!
	moveq	#-1,d1
	;
.ok	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	tst	d1
	rts

playerdead	; v102: dead-on-ground state is inert: no rotation/mouse drift.
	clr.l	ob_rotspeed(a5)
	;
	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	cmp	#2,gametype
	bne.s	.notcom
	;
	;combat game!
	;
	move	#4,finished2
	move	#1,ob_pixsizeadd(a5)
	move.l	#rts,ob_logic(a5)
	bsr	getother
	move	#1,ob_pixsizeadd(a0)
.rts	rts
	;
.notcom	;
	tst	ob_lives(a5)
	beq.s	.dead
	move.l	#waitrestart,ob_logic(a5)
	rts
	;
.dead	move.l	#rts,ob_logic(a5)
	tst	gametype
	bne.s	.not1p
.allover	move	#2,finished
	rts
	;
.not1p	;OK, I'm all out of lives...what about other guy...
	bsr	getother
	tst	ob_lives(a0)
	beq.s	.allover
	rts

waitrestart	bsr	getcntrl
	;
	bsr	checkfireb
	beq.s	.rts
	;
	move	ob_weapon(a5),-(a7)
	;
	lea	p1x(pc),a0
	lea	player1_+4,a1
	cmp.l	player1,a5
	beq.s	.got
	lea	p2x(pc),a0
	lea	player2_+4,a1
.got	lea	ob_info(a5),a2
	move	#(objinfof-objinfo-4)>>1-1,d0
.loop	move	(a1)+,(a2)+
	dbf	d0,.loop
	;
	clr.l	ob_colltype(a5)
	move	#75,ob_delay(a5)
	move.l	#playerlogic0,ob_logic(a5)
	;
	move	(a0)+,ob_x(a5)
	move	(a0)+,ob_z(a5)
	move	(a0)+,ob_rot(a5)
	;
	move	(a7)+,ob_weapon(a5)
	clr	ob_bounce(a5)
	;
	move.l	ob_shape(a5),a0
	move.l	4(a0),ob_chunks(a5)
	move.l	(a0),a0
	move.l	a0,ob_shape(a5)
	;
	bsr	resetplayer
	move	#-1,ob_update(a5)
	st	ob_lastbut(a5)
	;
.rts	rts

playerdeath	bsr	getcntrl
	;
	addq	#4,ob_rot(a5)
	addq	#4,ob_eyey(a5)
	cmp	#-32,ob_eyey(a5)
	blt	.rts
	;
	move	#-32,ob_eyey(a5)
	move.l	#playerdead,ob_logic(a5)
	move	#63,ob_delay(a5)
	;
	cmp	#2,gametype
	bne.s	.notcom
	;
	;death in combat game!
	;
	bsr	getother
	;
.win	move.l	a5,-(a7)
	;
	move.l	a0,a5
	clr	ob_collwith(a5)
	clr	ob_colltype(a5)
	bsr	message
	dc.b	'winner!',0
	even
	;
	move.l	(a7)+,a5
	subq	#1,ob_lives(a5)
	move	#-1,ob_update(a5) ;refresh 'lives'
	bsr	message
	dc.b	'loser!',0
	even
	;
	rts
.notcom	;
	subq	#1,ob_lives(a5)
	move	#-1,ob_update(a5)
	move	gametype(pc),d0
	beq.s	.one
	;
	;2 player game!
	;
	bsr	getother
	tst	ob_lives(a5)
	beq.s	.hmm
	move	ob_lives(a5),ob_lives(a0)
	move	#-1,ob_update(a0)
	rts
.hmm	tst	ob_lives(a0)
	beq.s	.go2
	rts
.one	tst	ob_lives(a5)
	beq.s	.go
	rts
.go2	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	message
	dc.b	'game over',0
	even
	move.l	(a7)+,a5
.go	bsr	message
	dc.b	'game over',0
	even
.rts	rts

getother	;get other player from a5!
	;
	move.l	player1(pc),a0
	cmp.l	a0,a5
	bne.s	.rts
	move.l	player2(pc),a0
.rts	rts

redpal	;move.l	#palettesr,ob_palette(a5)
	move	#2,ob_paltimer(a5)
	rts

playerhit	tst	ob_damage(a0)
	beq.s	.rts
	tst	trainer_invincible	;v115: unlimited health cancels visual hit/HUD flicker
	beq.s	.normal
	move	#25,ob_hitpoints(a5)
	rts
.normal	st	ob_update(a5)
	bsr	redpal
.rts	rts

playerdie	;v115: unlimited health also blocks lethal damage without HUD flash
	tst	trainer_invincible
	beq.s	.die
	move	#25,ob_hitpoints(a5)
	rts
.die	bsr	redpal
	clr	ob_hitpoints(a5)
	st	ob_update(a5)
	move.l	#playerdeath,ob_logic(a5)
	clr	ob_colltype(a5)
	clr	ob_collwith(a5)
	rts

inchealth	;inc health of a5
	;
	addq	#5,ob_hitpoints(a5)
	cmp	#25,ob_hitpoints(a5)
	ble.s	.skip
	move	#25,ob_hitpoints(a5)
.skip	st	ob_update(a5)
	bsr	message
	dc.b	'health bonus!',0
	even
	rts

healthgot	bsr	playtsfx
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	inchealth
	move.l	(a7)+,a5
	bra	killobject

playtsfx	move.l	a0,-(a7)
	move.l	tokensfx(pc),a0
	moveq	#64,d0
	moveq	#0,d1
	bsr	playsfx
	move.l	(a7)+,a0
	rts

weapongot	bsr	playtsfx
	move.l	a5,-(a7)
	move	ob_weapon(a5),d0	;weapon #!
	move.l	a0,a5
	bsr	weapond0
	move.l	(a7)+,a5
	bra	killobject

weapond0	tst	trainer_weapon	;v115: forced trainer weapon/upgrade must not flicker on pickups
	bne	.trainer_skip
	tst	trainer_boost
	bne	.trainer_skip
	st	ob_update(a5)
	cmp	ob_weapon(a5),d0
	bne	.new
	;
	subq.b	#1,ob_reload(a5)
	beq.s	.skip
	cmp.b	#1,ob_reload(a5)
	bne.s	.notfull
	bsr	message
	dc.b	'weapon boosted to full!',0
	even
	rts
	;
.notfull	bsr	message
	dc.b	'weapon boost!',0
	even
	rts
	;
.skip	addq.b	#1,ob_reload(a5)
	add	#250,ob_mega(a5)
	cmp	#ok,ob_mega(a5)
	bcs.s	.mwb
	;
	bsr	message
	dc.b	'ultra mega overkill!!!',0
	even
	rts
	;
.mwb	bsr	message
	dc.b	'mega weapon boost!',0
	even
	rts
	;
.new	move	d0,ob_weapon(a5)
	move.b	#ireload,ob_reload(a5)
	st	ob_update(a5)
	bsr	message
	dc.b	'new weapon!',0
	even
	rts
.trainer_skip	rts

invisigot	bsr	playtsfx
	move.l	a5,-(a7)
	move.l	a0,a5
	add	#1500,ob_invisible(a5)
	bsr	message
	dc.b	'invisibility!',0
	even
	move.l	(a7)+,a5
	bra	killobject

invincgot	bsr	playtsfx
	tst	ob_hyper(a0)
	bne.s	.rts
	move.l	a5,-(a7)
	move.l	a0,a5
	;
	move	#-$200,ob_hyper(a5)
	bsr	message
	dc.b	'hyper!',0
	even
	;
	move.l	(a7)+,a5
	bra	killobject
	;
.rts	rts

bouncylogic	addq	#1,ob_delay(a5)
	move	ob_delay(a5),d0
	lsr	#1,d0
	and	#3,d0
	move	.bnc(pc,d0*2),ob_frame(a5)
	rts
.bnc	dc	3,4,3,5

bouncygot	bsr	playtsfx
	cmp	#3,ob_bouncecnt(a0)
	bcc.s	.rts
	addq	#1,ob_bouncecnt(a0)
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	message
	dc.b	'bouncy bullets!',0
	even
	move.l	(a7)+,a5
	bra	killobject
.rts	rts

thermogot	bsr	playtsfx
	add	#1500,ob_thermo(a0)
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	message
	dc.b	'got the thermo glasses!',0
	even
	move.l	(a7)+,a5
	bra	killobject

maxsize	equ	$280

playertimers	tst	ob_mega(a5)
	beq.s	.nomega
	subq	#1,ob_mega(a5)
	bne.s	.nomout
	bsr	message
	dc.b	'mega weapon out...',0
	even
.nomout	move	ob_mega(a5),d0
	and	#31,d0
	bne.s	.nomega
	st	ob_update(a5)
	;
.nomega	tst	ob_thermo(a5)
	beq.s	.noth
	subq	#1,ob_thermo(a5)
	bne.s	.noth
	bsr	message
	dc.b	'thermo glasses out...',0
	even
	;
.noth	tst	ob_messtimer(a5)
	ble.s	.notm
	subq	#2,ob_messtimer(a5)
.notm	;
	tst	ob_invisible(a5)
	beq.s	.noti
	subq	#1,ob_invisible(a5)
	bne.s	.noti
	bsr	message
	dc.b	'invisibility out...',0
	even
.noti	;
	tst	ob_paltimer(a5)
	beq.s	.notp
	subq	#1,ob_paltimer(a5)
	bne.s	.notp
	move.l	#palettes,ob_palette(a5)
.notp	;
	move	ob_pixsizeadd(a5),d0
	beq.s	.notpix
	add	d0,ob_pixsize(a5)
	bne.s	.pixnz
	;
	clr	ob_pixsizeadd(a5)
	bra.s	.notpix
	;
.pixnz	cmp	#22,ob_pixsize(a5)	;v105c: keep teleport animation visible 10 frames longer before black hold
	blt.s	.notpix
	;
	; v104: level-exit teleport was still holding the final blue frame because
	; finished2 was copied to finished before the v103 blackout flag was set.
	; For exits/intermissions, first request a black C2P frame, clear pix/HUD
	; state, then let mainloop leave the level.  The loading/intermission wait
	; now sits on black instead of the last blue teleport chamber frame.
	move	finished2(pc),d0
	beq.s	.g2normal_teleport
	move	#1,g2teleport_blackout
	move	#17,g2teleport_black_hold	;v105b: shorter black hold, about one third of v105
	move	d0,g2teleport_black_finish
	clr	finished			;do not leave the level until the black hold elapsed
	clr	ob_pixsize(a5)
	clr	ob_pixsizeadd(a5)
	bra.s	.notpix
	;
.g2normal_teleport
	move	ob_telex(a5),ob_x(a5)
	move	ob_telez(a5),ob_z(a5)
	move	ob_telerot(a5),ob_rot(a5)
	clr	ob_pixsize(a5)
	clr	ob_pixsizeadd(a5)
.notpix	;
	move	ob_hyper(a5),d0
	beq.s	.nothyper
	bpl.s	.hplus
	;
	;hyper is minus! growing...
	;
	subq	#4,d0
	move	d0,d1
	neg	d1
	cmp	#maxsize,d1
	bne.s	.hdone
	move	#750<<2+maxsize,d0
	bra.s	.hdone
	;
.hplus	subq	#4,d0
	cmp	#maxsize,d0
	bhi.s	.hdone2
	bne.s	.noteq
	bsr	message
	dc.b	'hyper out...',0
	even
	move	#maxsize,d0
.noteq	move	d0,d1
	cmp	#$200,d0
	bne.s	.hdone
	moveq	#0,d0
	;
.hdone	move	d1,ob_scale(a5)
	;
	move	d1,d2
	mulu	#((pl_eyey<<16)/$200),d2
	swap	d2
	neg	d2
	move	d2,ob_eyey(a5)
	;
	move	d1,d2
	mulu	#((pl_firey<<16)/$200),d2
	swap	d2
	neg	d2
	move	d2,ob_firey(a5)
	;
	move	d1,d2
	mulu	#((pl_gutsy<<16)/$200),d2
	swap	d2
	neg	d2
	move	d2,ob_gutsy(a5)
	;
.hdone2	move	d0,ob_hyper(a5)
.nothyper	;
	rts

footstep	move.l	d0,-(a7)
	move.l	footstepsfx(pc),a0
	moveq	#16,d0
	moveq	#0,d1
	bsr	playsfx
	move.l	(a7)+,d0
	rts

pbuff	ds.b	128	;player controls to use!
pput	dc	0	;put new cntrl here
pget	dc	0	;read this for actual

getcntrl	move	ob_cntrl(a5),d0
	lea	joyx0,a0
	move.l	0(a0,d0*8),joyx
	move.l	4(a0,d0*8),joyb
	rts

maxrotsp	equ	$40000
rotacc	equ	$20000
rotrevacc	equ	$40000
rotsetacc	equ	$20000

rotplayer	;return rot in d0, leave a0
	;
	cmp	#0,ob_cntrl(a5)	; v34 KEYBMOUSE mouse rotation is applied in VBlank sampler
	bne.w	.notkmouse
	clr.l	ob_rotspeed(a5)
	rts
.notkmouse	move	joys(pc),d0	;strafing?
	bne.s	.norot
	move	joyx(pc),d0
	beq.s	.norot
	;
	move.l	#rotacc,d1	;rotacc
	move	ob_rotspeed(a5),d2
	beq.s	.useacc
	eor	d2,d0
	bpl.s	.useacc
	move.l	#rotrevacc,d1	;fast rev!
.useacc	move	joyx(pc),d0
	bpl.s	.plus
	neg.l	d1
.plus	add.l	d1,ob_rotspeed(a5)
	cmp.l	#maxrotsp,ob_rotspeed(a5)
	bgt.s	.fixaccpl
	cmp.l	#-maxrotsp,ob_rotspeed(a5)
	bge.s	.addrot
	move.l	#-maxrotsp,ob_rotspeed(a5)
	bra.s	.addrot
.fixaccpl	move.l	#maxrotsp,ob_rotspeed(a5)
	bra.s	.addrot
	;
.norot	tst.l	ob_rotspeed(a5)
	beq.s	.skip
	bpl.s	.orpl
	add.l	#rotsetacc,ob_rotspeed(a5)
	ble.s	.addrot
.clrrot	clr.l	ob_rotspeed(a5)
	bra.s	.skip
.orpl	sub.l	#rotsetacc,ob_rotspeed(a5)
	bmi.s	.clrrot
	;
.addrot	move.l	ob_rotspeed(a5),d0
	add.l	d0,ob_rot(a5)
	;
.skip	rts

unbounce	move	ob_bounce(a5),d1
	beq.s	.rts
	add	#30,ob_bounce(a5)
	move	ob_bounce(a5),d1
	and	#127,d1
	cmp	#30,d1
	bcc.s	.rts
	clr	ob_bounce(a5)
	clr	ob_frame(a5)
	bra	footstep
.rts	rts

moveplayer	;work out movement vector into d0/d1...check still/moving!
	;
	cmp	#0,ob_cntrl(a5)	; v34 KEYBMOUSE: W/X forward-back and A/D strafe, mouse turns
	bne	.normmove
	move	joyy(pc),d4	;forward/backward
	move	joyx(pc),d5	;strafe direction
	move	joys(pc),d0
	bne.s	.kmstrflag
	clr	d5
.kmstrflag	tst	d4
	bne.s	.kmmove
	tst	d5
	beq.w	.still
.kmmove	movem.l	d4-d5/a1,-(a7)
	move.l	camrots(pc),a1
	move	ob_rot(a5),d1
	and	#255,d1
	lea	0(a1,d1*8),a1
	move	d4,d0
	beq.s	.kmnostep
	neg	d0
	move	d0,d2
	bsr	g2_get_shift_movspeed	; v59: SHIFT run = 150% speed for KEYBMOUSE
	muls	d0,d2
	move	d2,d0
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
.kmnostep	move	d5,d0
	beq.s	.kmdonevec
	move.l	camrots(pc),a1	; v35: strafe uses camrot table base, not forward-rotated entry
	lsl	#6,d0
	add	ob_rot(a5),d0
	and	#255,d0
	lea	0(a1,d0*8),a1
	bsr	g2_get_shift_movspeed	; v59: SHIFT run = 150% speed for KEYBMOUSE strafe
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
.kmdonevec	movem.l	(a7)+,d4-d5/a1
	bra	.check
.normmove	move	joyy(pc),d0
	bne	.move
	move	joys(pc),d0
	beq.w	.still
	move	joyx(pc),d0
	bne.s	.strafe
	;
.still	bsr	unbounce
	move	ob_bounce(a5),d0
	bne	.fskip
	rts
	;
.strafe	;do strafe! X rot in d0
	;
	move.l	camrots(pc),a1
	lsl	#6,d0	;* ninety degrees
	add	ob_rot(a5),d0
	and	#255,d0
	lea	0(a1,d0*8),a1
	;
	move	ob_movspeed(a5),d0
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
	bra	.check
	;
.move	;and possibly strafe!
	;
	;work out move vec into d0/d1
	;
	neg	d0
	muls	ob_movspeed(a5),d0	;speed
	move.l	camrots(pc),a1
	move	ob_rot(a5),d1
	and	#255,d1
	lea	0(a1,d1*8),a1
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
	move	joys(pc),d0
	beq.s	.check
	move	joyx(pc),d0
	bne.s	.strafe
.check	;
	bsr	checknewslow
	beq.s	.newpos
	bsr	adjustpos
	beq.s	.newpos
	bsr	adjustpos
	beq.s	.newpos
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bra.s	.bounce
	;
.newpos	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	;
.bounce	move	ob_bounce(a5),d2
	; v190fy: SHIFT run is 150%, so advance the footstep/bob timer
	; by 30 instead of 20 while KEYBMOUSE SHIFT-run is active.
	moveq	#20,d0
	cmp	#0,ob_cntrl(a5)
	bne.s	.g2v190fy_stepadd
	move.l	rawtable,a0
	move.b	12(a0),d1	; raw $60/$61 = left/right SHIFT bits
	and.b	#3,d1
	beq.s	.g2v190fy_stepadd
	moveq	#30,d0
.g2v190fy_stepadd
	add	d0,ob_bounce(a5)
	move	ob_bounce(a5),d1
	and	#255,d2
	cmp	#64,d2
	bcc.s	.fskip
	and	#255,d1
	cmp	#64,d1
	bcs.s	.fskip
	;
	bsr	footstep
.fskip	;
	move.l	ob_framespeed(a5),d1
	add.l	d1,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

; v59: KEYBMOUSE run modifier.  Left or right SHIFT keeps the existing
; W/X/A/D and cursor movement logic, but raises the effective move speed
; to approximately 150%.  It reads the existing rawmatrix bits, so no new
; keyboard poller is introduced.
g2_get_shift_movspeed
	move	ob_movspeed(a5),d0
	movem.l	d1/a0,-(a7)
	move.l	rawtable,a0
	move.b	12(a0),d1	; raw $60/$61 = left/right SHIFT bits
	and.b	#3,d1
	beq.s	.g2gsm_done
	move	d0,d1
	asr	#1,d1
	add	d1,d0
.g2gsm_done
	movem.l	(a7)+,d1/a0
	rts

checkevent	bsr	checknew2
	beq.s	.rts
	;
	move	ob_pixsizeadd(a5),d0
	or	finished2(pc),d0
	bne	.rts
	;
	move	zo_ev(a4),d0	;poly->event
	bmi.s	.rts
	;
	cmp	#24,d0
	bne.s	.notexit
	;
	move	#3,finished2		;pattern done!
	move	#1,ob_pixsizeadd(a5)	;pixel out
	tst	gametype
	beq.s	.onewin
	bsr	getother
	move	#2,ob_pixsizeadd(a0)	;pixel out other player
.onewin	;
	bsr	dotelesfx
	moveq	#24,d0
	;
.notexit	cmp	#19,d0
	bcc.s	.noclr
	;
	;OK, gotta clear all 'event' zones with same type!
	;
	move.l	map_poly(pc),a0
	move.l	map_ppnt(pc),a1
	moveq	#32,d1
.loop2	cmp	zo_ev(a0),d0
	bne.s	.skip2
	neg	zo_ev(a0)
.skip2	add.l	d1,a0
	cmp.l	a1,a0
	bcs.s	.loop2
	;
.noclr	move.l	a5,eventobj
	movem.l	d6-d7,-(a7)
	jsr	execevent
	movem.l	(a7)+,d6-d7
	move.l	eventobj(pc),a5
	;
.rts	rts

	;these updated after a call to 'getcntrl'
	;
joyx	dc	0	;left/rite
joyy	dc	0	;for/back
joyb	dc	0	;fire
joys	dc	0	;strafe

checksuck	cmp.l	sucking(pc),a5
	bne.s	.nosuck
	;
	move.l	suckangle(pc),a0
	moveq	#25,d0
	move	d0,d1
	muls	2(a0),d0
	neg.l	d0
	add.l	d0,d6
	;
	muls	6(a0),d1
	add.l	d1,d7
	bsr	checknewslow
	beq.s	.newok
	bsr	adjustpos
	beq.s	.newok
	bsr	adjustpos
	beq.s	.newok
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bra.s	.nosuck
	;
.newok	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	;
.nosuck	rts

playerlogic0	;restart after death...2 seconds invincibility.
	;
	subq	#1,ob_delay(a5)
	bgt.s	playerlogic
	;
	;OK, fix colltype/collwith
	;
	lea	player1_,a1
	cmp.l	player1,a5
	beq.s	.got
	lea	player2_,a1
.got	lea	p1_ob_colltype-player1_(a1),a1
	move.l	(a1),ob_colltype(a5)
	move.l	#playerlogic,ob_logic(a5)
playerlogic	;
	bsr	playertimers	;do timer stuff...
	jsr	trainer_maintain_one	;v115: permanent trainer options, including level/pickup override
	; v100: once teleport/exit pixel-fade begins, freeze player control so
	; the player cannot keep walking while the blue teleport effect runs.
	move	ob_pixsize(a5),d0
	or	ob_pixsizeadd(a5),d0
	bne	rts		;v100a: generic return label, not checkfire's local .rts
	bsr	getcntrl	;player control
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	;
	;getting sucked?
	;
	;OK, are we getting pushed/squashed?
	;
	bsr	checknewslow
	beq.s	.newok
	bsr	adjustpos
	beq.s	.newok2
	bsr	adjustpos
	beq.s	.newok2
	;
	subq	#1,ob_hitpoints(a5)
	ble	playerdie
	st	ob_update(a5)
	bra	redpal
	;
.newok2	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
.newok	;
	bsr	checksuck
	bsr	checkevent	;in an event zone?
	; v100: checkevent can start teleport this same frame; do not still rotate,
	; move or fire after the transition has already started.
	move	ob_pixsize(a5),d0
	or	ob_pixsizeadd(a5),d0
	bne	rts		;v100a: generic return label, not checkfire's local .rts
	bsr	rotplayer	;rotate
	bsr	moveplayer	;forward/back/strafe
checkfire	;
	move	cheat(pc),d0
	beq.s	.nocheat
	;
	qkey	$5f	;help?????
	beq.s	.noend
	move	#3,finished
	rts
.noend	key	10
	beq.s	.nohealth
	bsr	inchealth
	bra.s	.nocheat
.nohealth	move.b	(a0),d1
	moveq	#5,d0
.loop	btst	d0,d1
	bne.s	.gotch
	subq	#1,d0
	bne.s	.loop
	bra.s	.nocheat
.gotch	;
	subq	#1,d0
	bsr	weapond0
	;
.nocheat	bsr	checkfireb
	beq	.nofire
	tst.b	ob_reloadcnt(a5)
	bne	.nofire2
	;
	move	ob_collwith(a5),d2
	and	#3,d2
	eor	#3,d2	;colltype
	moveq	#0,d3	;collwith!
	;
	move	ob_weapon(a5),d0
	mulu	#18,d0
	lea	wtable(pc),a0
	movem	0(a0,d0),d4-d6
	movem.l	6(a0,d0),a2-a3
	move.l	14(a0,d0),-(a7)
	;
	tst	ob_mega(a5)
	beq.s	.nomega
	;
	cmp	#ok,ob_mega(a5)
	bcc.s	.threeway
	;
	movem.l	d2-d6/a2-a3,-(a7)
	addq	#4,ob_rot(a5)
	bsr	shoot
	movem.l	(a7)+,d2-d6/a2-a3
	subq	#8,ob_rot(a5)
	bsr	shoot
	addq	#4,ob_rot(a5)
	bra.s	.shdone
.threeway	;
	movem.l	d2-d6/a2-a3,-(a7)
	addq	#8,ob_rot(a5)
	bsr	shoot
	movem.l	(a7),d2-d6/a2-a3
	sub	#16,ob_rot(a5)
	bsr	shoot
	movem.l	(a7)+,d2-d6/a2-a3
	addq	#8,ob_rot(a5)
	;
.nomega	bsr	shoot
	;
.shdone	move.l	(a7)+,a0
	move	#3,g2gun_firetimer	;v79: 3-frame single-shape flash 1x->1.6x->2.4x
	move.l	(a0),a0
	moveq	#32,d0
	moveq	#0,d1
	bsr	playsfx
	;
	; v84: make the already-slower base fire frequency another ~30% slower
	; again, while still leaving ob_reload itself untouched so the weapon /
	; statusbar upgrade display remains correct.  Keep upgrade speedups
	; intact by scaling the actual reload counter to about 3.4x ob_reload.
	moveq	#0,d0
	move.b	ob_reload(a5),d0
	mulu	#17,d0
	divu	#5,d0
	move.b	d0,ob_reloadcnt(a5)
	rts
	;
.nofire	tst.b	ob_reloadcnt(a5)
	beq.s	.rts
.nofire2	subq.b	#1,ob_reloadcnt(a5)
.rts	rts

	;
	;hitpoints
	;damage
	;speed
	;
wtable	dc	1,1,32
	dc.l	bullet1,sparks1,shootsfx3
	dc	5,2,36
	dc.l	bullet2,sparks2,shootsfx5
	dc	10,2,40
	dc.l	bullet3,sparks3,shootsfx
	dc	15,3,40
	dc.l	bullet4,sparks4,shootsfx4
	dc	20,5,24
	dc.l	bullet5,sparks5,shootsfx5

adjustposq	;
	neg	d0
	move	d0,d1
	;
	muls	zo_a(a4),d0
	add.l	d0,d0
	;
	muls	zo_b(a4),d1
	add.l	d1,d1
	;
	sub.l	d0,d6
	sub.l	d1,d7
	;
	rts

adjustpos	bsr	adjustposq
	;
	;addq	#1,(a4)
	;move.l	a4,-(a7)
	bsr	checknewslow
	;move.l	(a7)+,a3
	;addq	#1,(a3)
	tst	d1
	rts

checkfireb	move	joyb(pc),d0
	beq.s	.nofire
	cmp	#0,ob_cntrl(a5)	; v34 KEYBMOUSE keeps firing while held
	beq.s	.kmfire
	tst	ob_lastbut(a5)
	bne.s	.skip
	move	d0,ob_lastbut(a5)
	rts
.kmfire	move	d0,ob_lastbut(a5)
	rts
.skip	moveq	#0,d0
	rts
.nofire	clr	ob_lastbut(a5)
	rts

eventobj	dc.l	0

calcbounce	;calculate bounce vector...poly in a4, obj in a5
	;
	;R=2 N (N dot V) - V
	;
	;where R=reflect vector, N=normal to poly, V=original vector
	;
	subq	#1,ob_bouncecnt(a5)
	bge.s	.nok
	bsr	makesparksq
	bra	killobject
.nok	;
	move.l	closewall(pc),a4
	movem	ob_nxvec(a5),d0-d1	;normalized dir
	movem	zo_na(a4),d2-d3		;normal to poly
	neg	d2
	;
	;calc dot product:
	;
	move	d0,d4
	muls	d2,d4
	move	d1,d5
	muls	d3,d5
	add.l	d5,d4
	add.l	d4,d4
	swap	d4	;dot product?
	;
	muls	d4,d2
	lsl.l	#2,d2
	swap	d0
	clr	d0
	sub.l	d0,d2
	swap	d2
	;
	muls	d4,d3
	lsl.l	#2,d3
	swap	d1
	clr	d1
	sub.l	d1,d3
	swap	d3
	;
	movem	d2-d3,ob_nxvec(a5)
	;
	neg	d2
	muls	ob_movspeed(a5),d2
	add.l	d2,d2
	muls	ob_movspeed(a5),d3
	add.l	d3,d3
	;
	movem.l	d2-d3,ob_xvec(a5)
	;
	bsr	checkvecs
	beq.s	putfire
	bra	calcbounce

firelogic	;
	bsr	checkvecs
	bne	calcbounce
putfire	;
	addq	#1,ob_frame(a5)
	move	ob_frame(a5),d0
	move.l	ob_shape(a5),a0
	cmp	2(a0),d0
	bcs.s	.skip
	clr	ob_frame(a5)
.skip	;
	rts

moveblood	lea	blood(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq	.done
	;
	tst	bl_y(a5)
	ble.s	.do
	;
	move.l	sucking(pc),d0
	beq.s	.kill
	;
	move.l	bl_xvec(a5),d0
	add.l	d0,bl_x(a5)
	move.l	bl_zvec(a5),d1
	add.l	d1,bl_z(a5)
	;
	move.l	bl_dest(a5),a0
	move	bl_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	bl_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#64*64,d0
	bcc.s	.loop
	bra.s	.kill
	;
.do	add.l	#$8000,bl_yvec(a5)
	;
	movem.l	bl_xvec(a5),d0-d2
	add.l	d1,bl_y(a5)
	blt.s	.ok
	;
.kill	move.l	a5,a0
	killitem	blood
	move.l	a0,a5
	bra	.loop
	;
.ok	add.l	d0,bl_x(a5)
	add.l	d2,bl_z(a5)
	bra	.loop
	;
.done	rts

scrnblood	dc	0

drawblood	clr	scrnblood
	move	#$20,$dff09a
	lea	blood(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq	.done
	;
	move	bl_color(a5),d6
	beq.s	.loop	;already splatted on screen if 0!
	;
	move	bl_x(a5),d0
	sub	camx(pc),d0
	move	bl_y(a5),d1
	ble.s	.blok
	neg	d1
.blok	sub	camy(pc),d1
	move	bl_z(a5),d2
	sub	camz(pc),d2
	;
	;rotate x/z around cam...
	;
	move	d0,d3
	move	d2,d5
	muls	cm1(pc),d0
	muls	cm2(pc),d5
	add.l	d5,d0
	add.l	d0,d0
	swap	d0	;X
	;
	muls	cm3(pc),d3
	muls	cm4(pc),d2
	add.l	d3,d2
	add.l	d2,d2
	swap	d2	;Z
	;
	tst	d2
	beq	.loop
	tst	g2_visibility
	bgt.s	.g2v190dw_blood_far
	cmp	#maxz,d2	; v190ey: DEFAULT original cull
	bcc	.loop
	bra.s	.g2v190dw_blood_zok
.g2v190dw_blood_far
	cmp	#g2advviewfar,d2	; v190fc: ADVANCED uses smooth 16 texture widths
	bcc	.loop
.g2v190dw_blood_zok
	;
	ext.l	d0
	lsl.l	#focshft,d0
	divs	d2,d0
	cmp	minx(pc),d0
	blt	.loop
	cmp	maxx(pc),d0
	bge	.loop
	;
	ext.l	d1
	lsl.l	#focshft,d1
	divs	d2,d1
	cmp	miny(pc),d1
	blt	.loop
	cmp	maxy(pc),d1
	bge	.loop
	;
	; v34: same wall-occlusion test as stable gloom.s v45a.
	; Blood is drawn after walls, so reject droplets behind the nearest wall
	; in the projected screen column.
	move	d0,d4
	add	midx(pc),d4
	move.l	vertdraws(pc),a0
	mulu	#vd_size,d4
	lea	0(a0,d4),a0
	cmp	vd_z(a0),d2
	bcc	.loop
	;
	cmp	#40,d2
	bcc.s	.pix
	tst	bl_y(a5)
	bgt.s	.pix
	;
	;blood on screen!
	;
	st	scrnblood
	clr	bl_color(a5)
	bra	.loop
.pix	;
	move	d0,d4	;projected relative X for bounds of 2x2 splat
	move	d1,d5	;projected relative Y for bounds of 2x2 splat
	add	midx(pc),d0
	add	midy(pc),d1
	;
	move	d2,d3
	move	d6,-(a7)	; preserve blood colour mask during fog-distance scaling
	tst	g2_visibility
	bgt.s	.g2v190ey_blood_shade_adv
	cmp	#(4<<grdshft),d3
	blo.s	.g2v190ey_blood_shade_restore
	sub	#(4<<grdshft),d3
	add	d3,d3
	add	#(4<<grdshft),d3
	cmp	#maxz-1,d3
	bls.s	.g2v190ey_blood_shade_restore
	move	#maxz-1,d3
	bra.s	.g2v190ey_blood_shade_restore
.g2v190ey_blood_shade_adv
	move	d3,d6
	lsr	#1,d3
	lsr	#3,d6
	add	d6,d3
	lsr	#2,d6
	add	d6,d3
	lsr	#1,d6
	add	d6,d3
	cmp	#maxz-1,d3
	bls.s	.g2v190ey_blood_shade_restore
	move	#maxz-1,d3
.g2v190ey_blood_shade_restore
	move	(a7)+,d6
.g2v190dw_blood_shade_ok
	move.l	darktable(pc),a0
	move	0(a0,d3*2),d3
	;
	; v31: chunky blood must use byte writes.  The old planar/cop path
	; wrote a word through COP/wi_bmap and could corrupt the chunky/C2P
	; frame or hit the legacy screen-splat blit path.  Keep the original
	; particle projection, but draw a small guarded 2x2 block into chunky.
	;
	move.l	d1,d7
	mulu	chunkymodw(pc),d7	;row offset
	;
	lea	blcols,a0
	move	0(a0,d3*2),d3
	and	d6,d3
	;
	; v32: convert 12-bit RGB blood colour to the active 8-bit chunky
	; palette index.  v31 wrote the low byte of $f00/$c00/etc. directly,
	; which becomes 0 for red blood and therefore drew black splats.
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq.s	.v32_blood_fallback_red
	move.b	0(a0,d3.w),d3
	bra.s	.v32_blood_color_ok
.v32_blood_fallback_red
	moveq	#12,d3
.v32_blood_color_ok
	;
	move.l	chunky(pc),a1
	lea	coloffs,a2
	add.l	0(a2,d0*4),a1
	move.b	d3,0(a1,d7.l)
	;
	move	d4,d6	;relative X from before midx add
	addq	#1,d6
	cmp	maxx(pc),d6
	bge.s	.no_x2
	move	d0,d6
	addq	#1,d6
	move.l	chunky(pc),a3
	add.l	0(a2,d6*4),a3
	move.b	d3,0(a3,d7.l)
.no_x2	;
	move	d5,d6	;relative Y from before midy add
	addq	#1,d6
	cmp	maxy(pc),d6
	bge.s	.no_y2
	move.l	d7,d6
	move	chunkymodw(pc),d5
	ext.l	d5
	add.l	d5,d6
	move.b	d3,0(a1,d6.l)
	;
	move	d4,d5
	addq	#1,d5
	cmp	maxx(pc),d5
	bge.s	.no_y2
	move	d0,d5
	addq	#1,d5
	move.l	chunky(pc),a3
	add.l	0(a2,d5*4),a3
	move.b	d3,0(a3,d6.l)
.no_y2	bra	.loop
	;
.done	move	#$8020,$dff09a
	;
	; v31: disable legacy close-up screen splat blit for now.  It uses
	; font/wi_bmap planar drawing and was the likely crash path in the
	; new chunky/C2P renderer.  World blood and gore remain active.
	clr	scrnblood
	rts

blcols	dc	$ccc,$bbb,$aaa,$999,$888,$777,$666,$555
	dc	$444,$333,$222,$111,$111,$111,$111,$111

shaperender	dc.l	drawobjnorm	;default!

drawshape_1sc	;draw shape with one frame, scaled!
	;
	move.l	ob_shape(a5),a0
	move	ob_frame(a5),d0
	add.l	12(a0,d0*4),a0
	move	ob_scale(a5),d7
	bra	drawshape

drawshape_1	;
	move.l	ob_shape(a5),a0
	move	ob_frame(a5),d0
	add.l	12(a0,d0*4),a0
	move	#$200,d7	;scale
	bra	drawshape

drawshape_8	;
	;shape has 8 rotations, and a scale!
	;
	bsr	calcangle2
	add	#16,d0
	sub	ob_rot(a5),d0
	lsr	#5,d0
	and	#7,d0
	move	ob_frame(a5),d1
	lsl	#3,d1
	or	d1,d0
	move.l	ob_shape(a5),a0
	move	ob_scale(a5),d7
	add.l	12(a0,d0*4),a0
	;
drawshape	move	ob_x(a5),d0
	move	ob_y(a5),d1
	move	ob_z(a5),d2
drawshape_q	;
	;A0=shape
	;D0=X
	;D1=Y
	;D2=Z
	;D7=sclae factor
	;
	;rotate Z around camera!
	;
	sub	camx(pc),d0
	sub	camy(pc),d1
	sub	camz(pc),d2
	;
	move	d0,d3
	move	d2,d5
	muls	cm3(pc),d3
	muls	cm4(pc),d2
	add.l	d3,d2
	add.l	d2,d2
	swap	d2
	;
	tst	d2
	ble	.rts
	tst	g2_visibility
	bgt.s	.g2v190dw_shape_far
	cmp	#maxz,d2	; v190ey: DEFAULT original object/sprite distance
	bcc	.rts
	bra.s	.g2v190dw_shape_zok
.g2v190dw_shape_far
	cmp	#g2advshapez,d2	; v190fc: ADVANCED objects/sprites = 16 texture widths
	bcc	.rts
.g2v190dw_shape_zok
	;
	muls	cm1(pc),d0
	muls	cm2(pc),d5
	add.l	d5,d0
	add.l	d0,d0
	swap	d0
	;
	move.l	memat(pc),a1
	add.l	#sh_size,memat
	movem	d0-d2,sh_x(a1)
	move.l	g2_shape_owner,sh_prev(a1)	;v126 object owner copied into draw item
	move.l	a0,sh_shape(a1)
	move	d7,sh_scale(a1)
	move.l	shaperender(pc),sh_render(a1)
	;
	lea	shapelist(pc),a2
.loop	move.l	(a2),d0
	beq.s	.end
	move.l	a2,a3
	move.l	d0,a2
	cmp	sh_z(a2),d2	;nearer...further in list
	ble.s	.loop
	move.l	a2,(a1)
	move.l	a1,(a3)
	rts
.end	move.l	d0,(a1)
	move.l	a1,(a2)
.rts	rts

checknew2	;check trigger zone
	move.l	map_grid(pc),a0
	addq	#4,a0
	bra.s	checknew_

gs	equ	1<<grdshft

incframe	addq	#1,frame
	bne.s	.skip
	;
	movem.l	d0-d1/a0-a1,-(a7)
	moveq	#0,d0
	moveq	#32,d1
	move.l	map_poly(pc),a0
	move.l	map_ppnt(pc),a1
.loop	move	d0,(a0)
	add.l	d1,a0
	cmp.l	a1,a0
	bcs.s	.loop
	;
	addq	#1,frame
	movem.l	(a7)+,d0-d1/a0-a1
	;
.skip	rts

checkoffs	dc	0,0,-gs,0,gs,0,0,-gs,0,gs
	dc	-gs,-gs,gs,-gs,-gs,gs,gs,gs

checknew	;check wall zone
	;
	;d6.q=x, d7.q=z
	;
	;check for ob_radsq(a5)
	;
	move.l	map_grid(pc),a0
	;
checknew_	movem.l	d3-d7,-(a7)
	swap	d6
	swap	d7
	;
	lea	checkoffs(pc),a1	;where to check from
	move.l	map_poly(pc),a2
	bsr	incframe
	move	frame,d3
	moveq	#8,d5		;nine squares
	;
.loop	movem	(a1)+,d0-d1
	add	d6,d0
	cmp	#32<<grdshft,d0
	bcc	.next
	add	d7,d1
	cmp	#32<<grdshft,d1
	bcc	.next
	;
	;d0,d1=sq to check!
	;
	lsr	#grdshft,d0
	lsr	#grdshft,d1
	;
	lsl	#5,d1
	add	d1,d0
	lea	0(a0,d0*8),a3	;square to check!
	;
	move	(a3)+,d4	;how many in square
	bmi	.next
	move	(a3),d1
	;
	move.l	map_ppnt(pc),a3
	lea	0(a3,d1*2),a3
	;
.loop2	move	(a3)+,d0
	lsl	#5,d0
	lea	0(a2,d0),a4	;poly to check
	;
	cmp	(a4),d3
	beq.s	.next2
	move	d3,(a4)
	;
	bsr	findsegdist
	;
	sub	ob_rad(a5),d0
	bpl.s	.next2
	;
	movem.l	(a7)+,d3-d7
	moveq	#-1,d1	;coll!
	rts
	;
.next2	dbf	d4,.loop2
	;
.next	dbf	d5,.loop
	;
	movem.l	(a7)+,d3-d7
	moveq	#0,d1	;no coll!
	rts

closest	dc	0	;nearest so far!
closewall	dc.l	0

checknewslow	;check wall zone
	;
	;d6.q=x, d7.q=z
	;
	;check for ob_radsq(a5)
	;
	move.l	map_grid(pc),a0
	;
	movem.l	d3-d7,-(a7)
	swap	d6
	swap	d7
	;
	lea	checkoffs(pc),a1	;where to check from
	move.l	map_poly(pc),a2
	bsr	incframe
	move	frame,d3
	moveq	#8,d5		;nine squares
	move	#$3fff,closest
	;
.loop	movem	(a1)+,d0-d1
	add	d6,d0
	cmp	#32<<grdshft,d0
	bcc.s	.next
	add	d7,d1
	cmp	#32<<grdshft,d1
	bcc.s	.next
	;
	;d0,d1=sq to check!
	;
	lsr	#grdshft,d0
	lsr	#grdshft,d1
	;
	lsl	#5,d1
	add	d1,d0
	lea	0(a0,d0*8),a3	;square to check!
	;
	move	(a3)+,d4	;how many in square
	bmi.s	.next
	move	(a3),d1
	;
	move.l	map_ppnt(pc),a3
	lea	0(a3,d1*2),a3
	;
.loop2	move	(a3)+,d0	;grab poly#
	lsl	#5,d0
	lea	0(a2,d0),a4	;poly to check
	bsr	checkpolydist
	dbf	d4,.loop2
.next	dbf	d5,.loop
	;
	lea	rotpolys(pc),a3
	;
.loop3	move.l	(a3),a3
	tst.l	(a3)
	beq.s	.rpdone
	;
	move.l	rp_first(a3),a4
	move	rp_num(a3),d4
	subq	#1,d4
	;
.loop4	bsr	checkpolydist
	lea	32(a4),a4
	dbf	d4,.loop4
	;
	bra.s	.loop3
.rpdone	;
	movem.l	(a7)+,d3-d7
	move	closest(pc),d0
	sub	ob_rad(a5),d0
	bpl.s	.wallok
	move.l	closewall(pc),a4
	moveq	#-1,d1
	rts
.wallok	moveq	#0,d1
	rts

checkpolydist	;	
	cmp	(a4),d3
	beq	.rts
	move	d3,(a4)
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_na(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_nb(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0	;distance from end
	;
	cmp	zo_ln(a4),d0
	bcc.s	.rts
	;
	;find perpendicular dist.
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	bpl.s	.pl
	neg.l	d0
.pl	swap	d0	;perpendicular dist.w
	;
	cmp	closest(pc),d0
	bcc.s	.rts
	move	d0,closest
	move.l	a4,closewall
	;
.rts	rts

findsegdist	;find distance from d6,d7 to zone in a4...
	;
	;find end dist
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_na(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_nb(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0	;distance from end
	;
	cmp	zo_ln(a4),d0
	bcs.s	.perp	;use perpendicular distance!
	;
	move	#$3fff,d0
	rts
	;
.perp	;find perpendicular dist.
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	bpl.s	.pl
	neg.l	d0
.pl	swap	d0	;perpendicular dist.w
	rts

findsegdist2	;find distance from d6,d7 to zone in a4...
	;
	;find perpendicular dist.
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0	;perpendicular dist.w
	muls	d0,d0
	;
	;find distance from end
	;
	move	zo_rx(a4),d1
	sub	d6,d1
	muls	zo_na(a4),d1
	move	zo_rz(a4),d2
	sub	d7,d2
	muls	zo_nb(a4),d2
	add.l	d2,d1
	add.l	d1,d1
	swap	d1	;distance from end
	;
	cmp	zo_ln(a4),d1
	bcs.s	.perp	;use perpendicular distance!
	;
	;gotta find radial distance
	;
	blt.s	.min	;minus?
	sub	zo_ln(a4),d1
.min	muls	d1,d1
	add.l	d1,d0
	;
.perp	rts

calccamera	;a0=player object
	;	
	move.l	camrots(pc),a2
	;
	move	ob_x(a0),camx
	move	ob_y(a0),d0
	add	ob_eyey(a0),d0
	;
	;add bounce!
	;
	move	ob_bounce(a0),d1
	and	#255,d1
	move	2(a2,d1*8),d1
	muls	#20,d1
	swap	d1
	;
	add	d1,d0
	;
	move	d0,camy
	move	ob_z(a0),camz
	move	ob_rot(a0),d0
	and	#255,d0
	move	d0,camr
	move.l	camrots(pc),a1
	;
	lea	0(a1,d0*8),a1
	;
	move.l	(a1)+,cm1
	move.l	(a1),cm3
	;
	;calc inverse camera matrix!
	;
	move.l	camrots(pc),a1
	neg	d0
	and	#255,d0
	lea	0(a1,d0*8),a1
	;
	move.l	(a1)+,icm1
	move.l	(a1),icm3
	;
	rts

readnull	clr.l	(a0)
	clr.l	4(a0)
	rts

readjoydir	bsr	joydir
	move	d1,d0
	move	d2,d1
	add	d1,d1
	eor	d1,d2
	;
joydir	btst	#9,d2
	bne.s	.neg
	btst	#1,d2
	bne.s	.pos
	moveq	#0,d1
	rts
.neg	moveq	#-1,d1
	rts
.pos	moveq	#1,d1
	rts

readjoy0	;into a0 block
	;
	move	$dff00a,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	btst	#6,$bfe001
	seq	d0
	ext	d0
	move	d0,4(a0)
	btst	#2,$dff016
	seq	d0
	ext	d0
	move	d0,6(a0)
	rts

readjoy1	;into a0 block
	;
	move	$dff00c,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	btst	#7,$bfe001
	seq	d0
	ext	d0
	move	d0,4(a0)
	btst	#6,$dff016
	seq	d0
	ext	d0
	move	d0,6(a0)
	rts

readcd320	;into a0 block
	;
	move	$dff00a,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	;
	lea	$bfe001,a2
	lea	$dff016,a1
	;
	moveq	#6,d3
	move	#$400,d4
	bset	d3,$200(a2)
	bclr	d3,(a2)
	move	#$f200,$dff034
	moveq	#0,d0
	moveq	#6,d1
.loop	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	move	(a1),d2
	bset	d3,(a2)
	bclr	d3,(a2)
	and	d4,d2
	bne.s	.skip
	bset	d1,d0
.skip	dbf	d1,.loop
	move	#$f300,$dff034	;#0
	bclr	d3,$200(a2)
	;
handlecd32	btst	#5,d0
	sne	d1
	ext	d1
	move	d1,4(a0)	;fire button!
	clr	6(a0)
	;
	lsr	#1,d0	;btst	#0,d0
	bcc.s	.noesc
	st	escape
.noesc	;
	lsr	#1,d0	;btst	#1,d0
	bcc.s	.nolsh
	;
	;left should button!
	move	#-1,(a0)	;left/
	move	#-1,6(a0)	;strafe!
	rts
	;
.nolsh	lsr	#1,d0	;btst	#2,d0
	bcc.s	.norsh
	;
	;rite shoulder button
	move	#1,(a0)
	move	#-1,6(a0)
	;
.norsh	rts

readcd321	;into a0 block
	;
	move	$dff00c,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	;
	lea	$bfe001,a2
	lea	$dff016,a1
	;
	moveq	#7,d3
	move	#$4000,d4
	bset	d3,$200(a2)
	bclr	d3,(a2)
	move	#$2000,$dff034
	moveq	#0,d0
	moveq	#6,d1
.loop	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	move	(a1),d2
	bset	d3,(a2)
	bclr	d3,(a2)
	and	d4,d2
	bne.s	.skip
	bset	d1,d0
.skip	dbf	d1,.loop
	move	#$3000,$dff034
	bclr	d3,$200(a2)
	;
	bra	handlecd32

	;    00 : play/pause
	;    01 : reverse
	;    02 : forward
	;    03 : green
	;    04 : yellow
	;    05 : red
	;    06 : blue

readkeys	;into a0 block
	;
	move.l	rawtable,a1
	moveq	#0,d0
	keya1	$4f
	beq.s	.nleft
	moveq	#-1,d0
.nleft	keya1	$4e
	beq.s	.nrite
	moveq	#1,d0
.nrite	move	d0,(a0)
	moveq	#0,d0
	keya1	$63
	bne.s	.up
	keya1	$4c
	beq.s	.nup
.up	moveq	#-1,d0
.nup	keya1	$60
	bne.s	.down
	keya1	$4d
	beq.s	.ndown
.down	moveq	#1,d0
.ndown	move	d0,2(a0)
	moveq	#0,d0
	keya1	$66
	beq.s	.nbut
	moveq	#-1,d0
.nbut	move	d0,4(a0)
	moveq	#0,d0
	keya1	$64
	beq.s	.nstr
	moveq	#-1,d0
.nstr	move	d0,6(a0)
	rts

readkeymouse	;keyboard plus mouse into a0 block
	; v34: imported from stable gloom.s v29a/WAXD.
	; W/A/X/D are tracked in rawkeyread; X is backward, avoiding S+A/S+D rollover.
	movem.l	d1-d3/a1,-(a7)
	move.l	rawtable,a1
	clr	(a0)
	clr	2(a0)
	clr	4(a0)
	clr	6(a0)
	moveq	#0,d0
	keya1	$63	; cursor up
	bne.s	.km_up
	keya1	$4c	; numpad up
	bne.s	.km_up
	btst	#1,wasd_state	; W held
	beq.s	.km_nup
.km_up	moveq	#-1,d0
.km_nup	; v118: do not treat raw $60 as KEYBMOUSE down here.
	; $60 is left SHIFT in the raw matrix and is used as run modifier;
	; keeping it as down made SHIFT+W / SHIFT+cursor-up walk backward.
	keya1	$4d	; cursor/numpad down
	bne.s	.km_down
	btst	#3,wasd_state	; X held = backward
	beq.s	.km_ndown
.km_down	moveq	#1,d0
.km_ndown	move	d0,2(a0)
	moveq	#0,d0
	keya1	$4f	; cursor left
	bne.s	.km_left
	btst	#2,wasd_state	; A held
	beq.s	.km_nleft
.km_left	moveq	#-1,d0
.km_nleft	keya1	$4e	; cursor right
	bne.s	.km_rite
	btst	#4,wasd_state	; D held
	beq.s	.km_nrite
.km_rite	moveq	#1,d0
.km_nrite	tst	d0
	beq.s	.km_nostrafe
	move	d0,(a0)
	move	#-1,6(a0)
.km_nostrafe	moveq	#0,d0
	keya1	$66
	beq.s	.km_nkeyfire
	moveq	#-1,d0
.km_nkeyfire	move	d0,4(a0)
	btst	#6,$bfe001	; left mouse button = fire
	bne.s	.km_nolmfire
	move	#-1,4(a0)
.km_nolmfire	movem.l	(a7)+,d1-d3/a1
	rts

sample_keymouse_vb	;v34/v29a: VBlank direct mouse yaw for KEYBMOUSE, mid speed
	movem.l	d0-d2/a5,-(a7)
	move	$dff00a,d1
	move.b	d1,d0
	tst	mousexinit
	bne.s	.kmvb_have_last
	move.b	d0,mousexlast
	move	#-1,mousexinit
	bra.s	.kmvb_done
.kmvb_have_last	move.b	mousexlast,d2
	move.b	d0,mousexlast
	sub.b	d2,d0
	ext.w	d0
	beq.s	.kmvb_done
	cmp	#24,d0
	ble.s	.kmvb_pos_ok
	moveq	#24,d0
	bra.s	.kmvb_apply
.kmvb_pos_ok	cmp	#-24,d0
	bge.s	.kmvb_apply
	moveq	#-24,d0
.kmvb_apply	tst	paused
	bne.s	.kmvb_done
	move.l	player1,a5
	tst.l	a5
	beq.s	.kmvb_done
	; v102: while teleporting or dead, never apply live mouse yaw.  The death
	; animation may still spin/fall by script, but once the body is down the
	; player can no longer turn the camera.
	move	ob_pixsize(a5),d1
	or	ob_pixsizeadd(a5),d1
	bne.s	.kmvb_done
	tst	ob_hitpoints(a5)
	ble.s	.kmvb_done
	cmp	#0,ob_cntrl(a5)
	bne.s	.kmvb_done
	ext.l	d0
	swap	d0
	clr.w	d0
	move.l	d0,d1
	asr.l	#3,d0
	asr.l	#4,d1
	add.l	d1,d0
	add.l	d0,ob_rot(a5)
	clr.l	ob_rotspeed(a5)
.kmvb_done	movem.l	(a7)+,d0-d2/a5
	rts

gridoffs	incbin	gridoffs4.bin
gridoffsf

makewalls	;
	;New approach!
	;
	;use poly's line eq to test perpendicular distance to wall
	;produce nearest -> furthest wall list.
	;
	;optimizations...
	;check if both z's are negative after rotation
	;check if projected left/rite ends are on screen
	;
	bsr	incframe
	;
	clr.l	inlist
	move.l	#inlist,inlistf
	;
	move.l	map_poly(pc),a4
	move.l	map_ppnt(pc),a3
	move.l	map_grid(pc),a2
	movem	camx(pc),d6-d7	;x,z
	lsr	#grdshft,d6
	lsr	#grdshft,d7
	lea	gridoffs(pc),a6
	moveq	#(gridoffsf-gridoffs)>>2-1,d5
	;
.loop	movem	(a6)+,d0-d1
	add	d6,d0
	cmp	#32,d0
	bcc	.skip
	add	d7,d1
	cmp	#32,d1
	bcc	.skip
	;
	;d0,d1=x/z of map to check!
	;
	lsl	#5,d1	;Y*32...
	add	d1,d0	;+X
	lea	0(a2,d0*8),a0	;mapgrid
	move	(a0)+,d4	;how many polys here
	bmi	.skip
	move	(a0),d0	;poly data offset
	lea	0(a3,d0*2),a0
	;
.loop2	move	(a0)+,d0	;poly#
	lsl	#5,d0
	lea	0(a4,d0),a1	;actual poly
	;
	bsr	dothezone
	;
	dbf	d4,.loop2	;finish sq
	;
.skip	dbf	d5,.loop	;gridoffs
	;
	;now do rots/morphs...
	;
	lea	rotpolys(pc),a3
	;
.loop3	move.l	(a3),a3
	tst.l	(a3)
	beq.s	.rpdone
	;
	move.l	rp_first(a3),a4
	move	rp_num(a3),d4
	subq	#1,d4
	;
.loop4	move.l	a4,a1
	bsr	dothezone2
	;
	lea	32(a4),a4
	dbf	d4,.loop4
	;
	bra.s	.loop3
.rpdone	;
makeoutlist	;create outlist from inlist
	;
	clr.l	outlist
	move.l	#outlist,outlistf
	;
.loop	lea	inlist(pc),a0
	move.l	(a0),d0
	beq	.done
	move.l	a0,a2	;save previous!
	move.l	d0,a0
	;
	;OK, see if any are in front of a0...
	;
	lea	inlist(pc),a1
	;
.loop2	move.l	(a1),d0
	beq	.none
	move.l	a1,a3
	move.l	d0,a1
	cmp.l	a0,a1
	beq.s	.loop2	;don't compare with self!
	;
	;check screen pos overlap...
	;
	move	wl_rsx(a0),d0
	cmp	wl_lsx(a1),d0
	blt	.loop2
	;
	move	wl_lsx(a0),d1
	cmp	wl_rsx(a1),d1
	bgt	.loop2
	;
	;check near/far Z overlap
	;
	move	wl_nz(a1),d2
	cmp	wl_fz(a0),d2
	bge	.loop2	;behind!
	;
	move	wl_fz(a1),d2
	cmp	wl_nz(a0),d2
	ble	.swap
	;
	tst	wl_open(a1)
	bne	.swap	
	;
	;look at a0 points against a1 line...
	;
	movem	wl_a(a1),d5-d6
	move.l	wl_c(a1),d7
	;
	move	wl_lx(a1),d0
	sub	wl_lx(a0),d0
	muls	d5,d0
	move	wl_lz(a1),d1
	sub	wl_lz(a0),d1
	muls	d6,d1
	add.l	d1,d0
	eor.l	d7,d0
	;
	move	wl_lx(a1),d1
	sub	wl_rx(a0),d1
	muls	d5,d1
	move	wl_lz(a1),d2
	sub	wl_rz(a0),d2
	muls	d6,d2
	add.l	d2,d1
	eor.l	d7,d1
	;
	;if both a0 in front, no swap
	;
	move.l	d0,d4
	or.l	d1,d4
	bpl	.loop2	;both a0's in front of a1!
	;
	;if both a0 behind, swap
	;
	and.l	d1,d0
	bmi	.swap	;both a0's behind a1!
	;
	;look at a1 points against a0 line!
	;
	movem	wl_a(a0),d5-d6
	move.l	wl_c(a0),d7
	;
	move	wl_lx(a0),d2
	sub	wl_lx(a1),d2
	muls	d5,d2
	move	wl_lz(a0),d3
	sub	wl_lz(a1),d3
	muls	d6,d3
	add.l	d3,d2
	eor.l	d7,d2
	;
	move	wl_lx(a0),d3
	sub	wl_rx(a1),d3
	muls	d5,d3
	move	wl_lz(a0),d4
	sub	wl_rz(a1),d4
	muls	d6,d4
	add.l	d4,d3
	eor.l	d7,d3
	;
	move.l	d2,d4
	and.l	d3,d4
	bmi	.loop2	;both a1's behind a0!
	;
	or.l	d3,d2
	bmi	.loop2
	;
.swap	move.l	a1,a0
	move.l	a3,a2
	bra	.loop2
	;
.none	;OK, none in front of this (a0)
	;
	move.l	(a0),(a2)	;unlink from inlist
	clr.l	(a0)
	;
	move.l	outlistf(pc),a2
	move.l	a0,(a2)
	move.l	a0,outlistf
	bra	.loop
	;
.done	rts

dothezone2	;
	move	frame,d0
	cmp	zo_done(a1),d0
	beq.s	.rts
	move	d0,zo_done(a1)
	tst	zo_open(a1)
	bmi.s	.rts
	;
	movem	d4-d7,-(a7)
	;
	movem	zo_lx(a1),d0-d3	;x1,z1,x2,z2
	movem	camx(pc),d6-d7
	;
	move	#maxz,d4
	tst	g2_visibility
	ble.s	.g2v190dw_zone2_view_ok
	move	#g2advviewfar,d4	; v190fc: ADVANCED zone cull = 16 texture widths
.g2v190dw_zone2_view_ok
	move	d4,d5
	neg	d5
	;
	sub	d6,d0
	cmp	d4,d0
	bge.s	.rts2
	cmp	d5,d0
	ble.s	.rts2
	;
	sub	d7,d1
	cmp	d4,d1
	bge.s	.rts2
	cmp	d5,d1
	ble.s	.rts2
	;
	sub	d6,d2
	cmp	d4,d2
	bge.s	.rts2
	cmp	d5,d2
	ble.s	.rts2
	;
	sub	d7,d3
	cmp	d4,d3
	bge.s	.rts2
	cmp	d5,d3
	bgt	dothezone3 ;.rts2
	;
.rts2	movem	(a7)+,d4-d7
	;
.rts	rts

dothezone	;
	move	frame,d0
	cmp	zo_done(a1),d0
	beq	rts ;.skip3
	move	d0,zo_done(a1)
	tst	zo_open(a1)
	bmi	rts ;.skip3
	;
	;OK, setup:
	;
	;d0=lx,d1=lz,d2=rx,d3=rz
	;d4=t,d5=sc,d6=dist
	;
	;back face/dist check...
	;
	movem	d4-d7,-(a7)
	;
	movem	zo_lx(a1),d0-d3	;x1,z1,x2,z2
	movem	camx(pc),d6-d7
	;
	sub	d6,d0
	sub	d7,d1
	sub	d6,d2
	sub	d7,d3
	;
dothezone3	move	d0,d4
	move	d1,d5
	muls	cm1(pc),d0
	muls	cm2(pc),d5
	add.l	d5,d0
	add.l	d0,d0
	swap	d0
	;
	muls	cm3(pc),d4
	muls	cm4(pc),d1
	add.l	d4,d1
	add.l	d1,d1
	swap	d1	;LZ
	;
	move	d2,d4
	move	d3,d5
	muls	cm1(pc),d2
	muls	cm2(pc),d5
	add.l	d5,d2
	add.l	d2,d2
	swap	d2	;RX
	;
	muls	cm3(pc),d4
	muls	cm4(pc),d3
	add.l	d4,d3
	add.l	d3,d3
	swap	d3	;RZ
	;
	;check Z's...
	tst	d1
	bgt.s	.zok
	tst	d3
	ble	.skip2
.zok	;
	move	#maxz,d4
	tst	g2_visibility
	ble.s	.g2v190dw_wall_view_ok
	move	#g2advviewfar,d4	; v190fc: ADVANCED wall/zone cull = 16 texture widths
.g2v190dw_wall_view_ok
	cmp	d4,d1
	blt.s	.zok2
	cmp	d4,d3
	bge	.skip2
.zok2	;
	;do backface check...generate a,b,c...
	;
	rol.l	#exshft,d0
	rol.l	#exshft,d1
	rol.l	#exshft,d2
	rol.l	#exshft,d3
	;
	move	d1,d4
	sub	d3,d4	;a
	move	d2,d5
	sub	d0,d5	;b
	;
	move	d0,d6
	muls	d4,d6
	move	d1,d7
	muls	d5,d7
	add.l	d7,d6
	bpl.s	.front
	;
	;backface showing!...
	bra	.skip2
.front	;
	move.l	memat(pc),a5
	;
	movem	d0-d5,wl_lx(a5)
	move.l	d6,wl_c(a5)
	;
	;work out some screen positions!
	tst	d1
	bgt.s	.z1ok
	;
	;lz bad, rz must be OK...
	;
.ov1	move	minx(pc),wl_lsx(a5)
	bra.s	.z1sk
	;
.z1ok	ext.l	d0
	lsl.l	#focshft,d0
	divs	d1,d0
	bvs.s	.ov1
	subq	#1,d0
	cmp	maxx(pc),d0
	bge	.skip2
	move	d0,wl_lsx(a5)
.z1sk	;
	tst	d3
	bgt.s	.z2ok
	;
	;rz bad, lz must be OK...
	;
.ov2	move	maxx(pc),wl_rsx(a5)
	bra.s	.z2sk
	;
.z2ok	ext.l	d2
	lsl.l	#focshft,d2
	divs	d3,d2
	bvs.s	.ov2
	addq	#1,d2
	cmp	minx(pc),d2
	blt	.skip2
	move	d2,wl_rsx(a5)
.z2sk	;
	cmp	d1,d3
	bge.s	.zskp
	exg	d1,d3
.zskp	movem	d1/d3,wl_nz(a5)	;near/far Z
	;
	move.l	zo_t(a1),wl_t(a5)
	move.l	zo_t+4(a1),wl_t+4(a5)
	move	zo_sc(a1),wl_sc(a5)
	move	zo_open(a1),wl_open(a5)
	;
	;add to end of inlist...
	;
	clr.l	(a5)
	move.l	inlistf(pc),a1
	move.l	a5,(a1)
	move.l	a5,inlistf
	add.l	#wl_size,memat
	;
.skip2	movem	(a7)+,d4-d7
	;
.skip3	rts

	;elseif

makeoutlist2	;create outlist from inlist
	;
.loop0	lea	inlist(pc),a0
	;
.loop	move.l	(a0),d0
	beq	.done
	move.l	a0,a2	;save previous!
	move.l	d0,a0
	;
	;OK, see if any are in front of a0...
	;
	lea	inlist(pc),a1
	;
.loop2	move.l	(a1),d0
	beq	.none
	move.l	a1,a3
	move.l	d0,a1
	;
	cmp.l	a0,a1
	beq.s	.loop2	;don't compare with self!
	;
	;see if a1 is in front of a0
	;
	move	wl_nz(a1),d0
	cmp	wl_fz(a0),d0
	bge	.loop2	;behind!
	;
	move	wl_fz(a1),d0
	cmp	wl_nz(a0),d0
	ble	.swap
	;
	;now, compare screen x coords.....
	;
	move	wl_rsx(a0),d0
	cmp	wl_lsx(a1),d0
	blt	.loop2
	;
	move	wl_lsx(a0),d0
	cmp	wl_rsx(a1),d0
	bgt	.loop2
	;
	;look at a0 points against a1 line
	;
	;If Sgn((x3-x1)*a2+(y3-y1)*b2)<>Sgn(c2)
	;  If Sgn((x3-x2)*a2+(y3-y2)*b2)<>Sgn(c2)
	;    tr=-1:Return
	;  EndIf
	;EndIf
	;
	movem	wl_a(a1),d5-d6
	move.l	wl_c(a1),d7
	;
	move	wl_lx(a1),d0
	sub	wl_lx(a0),d0
	muls	d5,d0
	move	wl_lz(a1),d1
	sub	wl_lz(a0),d1
	muls	d6,d1
	add.l	d1,d0
	eor.l	d7,d0
	;
	move	wl_lx(a1),d1
	sub	wl_rx(a0),d1
	muls	d5,d1
	move	wl_lz(a1),d2
	sub	wl_rz(a0),d2
	muls	d6,d2
	add.l	d2,d1
	eor.l	d7,d1
	;
	;OK, screen X's overlap...
	;if both a0 in front, no swap
	;
	move.l	d0,d4
	or.l	d1,d4
	bpl	.loop2
	;
	;if both a0 behind, swap
	;
	move.l	d0,d4
	and.l	d1,d4
	bmi	.swap
	;
	;bra	.loop2
	;
	;elseif
	;look at a1 points against a0 line
	;
	;If Sgn((x1-x3)*a1+(y1-y3)*b1)=Sgn(c1)
	;  If Sgn((x1-x4)*a1+(y1-y4)*b1)=Sgn(c1)
	;    tr=-1:Return
	;  EndIf
	;EndIf
	;
	movem	wl_a(a0),d5-d6
	move.l	wl_c(a0),d7
	;
	move	wl_lx(a0),d2
	sub	wl_lx(a1),d2
	muls	d5,d2
	move	wl_lz(a0),d3
	sub	wl_lz(a1),d3
	muls	d6,d3
	add.l	d3,d2
	eor.l	d7,d2
	;
	move	wl_lx(a0),d3
	sub	wl_rx(a1),d3
	muls	d5,d3
	move	wl_lz(a0),d4
	sub	wl_rz(a1),d4
	muls	d6,d4
	add.l	d4,d3
	eor.l	d7,d3
	;
	;if both a1's behind, no swap
	;
	move.l	d2,d4
	and.l	d3,d4
	bmi	.loop2	;both a1's behind...
	;
	;if both a1's in front, swap
	move.l	d2,d4
	or.l	d3,d4
	bpl	.swap
	;
	bra	.loop2
	;
	;elseif
	;
.swap	;a1 is infront of a0! make a1 new frontmost
	bra	.loop
	move.l	a1,a0
	move.l	a3,a2
	bra	.loop2
	;
.none	;OK, none in front of this (a0)
	;
	move.l	(a0),(a2)	;unlink from inlist
	clr.l	(a0)
	move.l	outlistf(pc),a2
	move.l	a0,(a2)
	move.l	a0,outlistf
	bra	.loop0
	;
.done	;move.l	inlist(pc),d0
	;bne	.loop0
	rts

	;elseif

castwalls	;process 'walls' list
	;
	move.l	castrots(pc),a6
	move	minx(pc),d7
	lea	0(a6,d7*8),a6
	move.l	vertdraws(pc),a4
	;
.loop	;do this vert line!
	;
	lea	outlist(pc),a5
	;
.loop2	move.l	(a5),d0
	beq	.empty
	move.l	a5,a3	;previous
	move.l	d0,a5
	;
	cmp	wl_lsx(a5),d7
	blt.s	.loop2	;not up to left yet!
	;
	cmp	wl_rsx(a5),d7
	ble.s	.try
	;
	;past right! unlink!
	move.l	(a5),(a3)
	bra.s	.loop2	
.try	;
	movem	wl_lx(a5),d0-d1
	muls	(a6),d0
	muls	2(a6),d1
	add.l	d1,d0	;LX!
	bgt.s	.loop2
	;
	movem	wl_rx(a5),d1-d2
	muls	(a6),d1
	muls	2(a6),d2
	add.l	d2,d1	;RX!
	blt.s	.loop2
	;
	sub.l	d0,d1
	;
	swap	d1
	tst	d1
	ble.s	.dfix
	neg.l	d0
	divu	d1,d0
	bvc.s	.noov
.dfix	moveq	#-1,d0
.noov	lsr	#1,d0	;fraction -> unsigned
	;
	cmp	wl_open(a5),d0
	bcs.s	.loop2
	;
	movem	wl_lx(a5),d1-d2
	muls	4(a6),d1
	muls	6(a6),d2
	add.l	d2,d1
	add.l	d1,d1	;lz
	;
	movem	wl_rx(a5),d2-d3
	muls	4(a6),d2
	muls	6(a6),d3
	add.l	d3,d2
	add.l	d2,d2	;rz
	;
	sub.l	d1,d2
	swap	d2
	muls	d0,d2
	add.l	d2,d2
	add.l	d1,d2
	;
	swap	d2
	;
	cmp	#exone,d2
	blt	.loop2
	move	#maxz<<exshft,d6
	tst	g2_visibility
	ble.s	.g2v190dw_cast_view_ok
	move	#(g2advviewfar<<exshft)-8,d6	; v190fc: ADVANCED wall cast just below signed 16-bit edge, approx 16 widths
.g2v190dw_cast_view_ok
	cmp	d6,d2
	bcs.s	.zisok
	;
.empty	move	#32767,vd_z(a4)
	clr.l	vd_data(a4)
	bra	.next
.zisok	;
	;d0=frac, d2=z, a5=item
	;
	;calc column#
	;
	move.l	a4,a0	;do vd...
	;
	move	wl_sc(a5),d1
	bgt.s	.mul
	neg	d1
	ext.l	d0
	add.l	d0,d0
	lsr.l	d1,d0
	bra.s	.scdone
.mul	mulu	d1,d0
.scdone	move.l	d0,d1
	swap	d1	;0...sc-1
	and	#7,d1
	move.b	wl_t(a5,d1),d1
	;
	lea	textures(pc),a3
	move.l	0(a3,d1*4),a3	;texture!
	lsl.l	#6,d0	;*64
	swap	d0
	and	#63,d0	;0...w-1
	move	d0,d1
	lsl	#6,d0
	add	d1,d0
	add	d0,a3
	;
	lsr	#exshft,d2
	;
	; v190dz: ADVANCED must not hard-pop walls/doors at the
	; extended clip.  DEFAULT already fades into its fog before the
	; normal clip; for ADVANCED dissolve whole far columns with a
	; stable 4x4 Bayer mask from 8..16 texture widths, so geometry
	; approaches the final clip already mostly hidden.
	;
	tst	g2_visibility
	; v190ey: ADVANCED 12 now uses the same smooth scaled fog as v190ew DEFAULT-12.
	; Do not dissolve whole columns at the far end.
	bra	.g2v190dz_wallclip_done
	ble.s	.g2v190dz_wallclip_done
	cmp	#(8<<grdshft),d2
	blo.s	.g2v190dz_wallclip_done
	move	d2,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 0..15 over the 8..16 advanced far band
	cmp	#15,d6
	bls.s	.g2v190dz_wallclip_lvl_ok
	moveq	#15,d6
.g2v190dz_wallclip_lvl_ok
	move	d2,d5
	lsr	#8,d5
	and	#3,d5
	lsl	#2,d5
	move	d7,d4
	and	#3,d4
	add	d4,d5
	lea	g2v190dz_bayer4(pc),a2
	moveq	#0,d4
	move.b	0(a2,d5),d4
	cmp	d6,d4
	; v190ed: zero-distance branch removed; keep far wall alive for fog/shade fade
.g2v190dz_wallclip_done
	;
	;a3=texture column!
	;
	tst.b	(a3)+
	beq.s	.solid
	;
	bsr	makestrip	;do strip!
	;
.solid	move.l	a3,vd_data(a0)	;start column
	;
	;fill in vd struct...
	;
	move	d2,d6
	tst	g2_visibility
	bgt.s	.g2v190ey_wall_shade_adv
	cmp	#(4<<grdshft),d6
	blo.s	.g2v190dw_wall_shade_ok
	sub	#(4<<grdshft),d6
	add	d6,d6
	add	#(4<<grdshft),d6
	cmp	#maxz-1,d6
	bls.s	.g2v190dw_wall_shade_ok
	move	#maxz-1,d6
	bra.s	.g2v190dw_wall_shade_ok
.g2v190ey_wall_shade_adv
	move	d6,d0
	lsr	#1,d6
	move	d0,d5
	lsr	#3,d5
	add	d5,d6
	move	d0,d5
	lsr	#5,d5
	add	d5,d6
	move	d0,d5
	lsr	#6,d5
	add	d5,d6
	cmp	#maxz-1,d6
	bls.s	.g2v190dw_wall_shade_ok
	move	#maxz-1,d6
.g2v190dw_wall_shade_ok
	move.l	darktable(pc),a2
	move	0(a2,d6*2),d3
	; v190ec: ADVANCED keeps 12-width visibility but never lets far
	; walls/doors pop as bright solid columns at the advanced clip.
	; Keep the wall column alive and fade its palette through the same
	; fog logic as DEFAULT; only the last far band is Bayer-mixed to
	; the darkest fog palette instead of being removed from vertdraws.
	tst	g2_visibility
	; v190ey: no separate ADVANCED 8..12 far-dark/clip fade.
	; The scaled darktable path above is the confirmed smooth v190ew behavior.
	bra	.g2v190dy_wallfade_done
	ble.s	.g2v190dy_wallfade_done
	cmp	#(8<<grdshft),d2
	blo.s	.g2v190dy_wallfade_done
	move	d2,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 0..15 over the 8..12 texture-width advanced band
	cmp	#15,d6
	bls.s	.g2v190ec_wallfade_lvl_ok
	moveq	#15,d6
.g2v190ec_wallfade_lvl_ok
	move	d6,d0
	lsr	#2,d0	; gentle extra darkness before the final dither fog
	add	d0,d3
	cmp	#14,d3
	bls.s	.g2v190ec_wallfade_cap_ok
	moveq	#14,d3
.g2v190ec_wallfade_cap_ok
	move	d2,d5
	lsr	#8,d5
	and	#3,d5
	lsl	#2,d5
	move	d7,d0
	and	#3,d0
	add	d0,d5
	lea	g2v190dz_bayer4(pc),a2
	moveq	#0,d0
	move.b	0(a2,d5),d0
	cmp	d6,d0
	bcc.s	.g2v190dy_wallfade_done
	moveq	#15,d3	; darkest fog palette, not empty/no-wall
.g2v190dy_wallfade_done
	movem	d2-d3,vd_z(a0)
	;
	move	#-256,d3
	sub	camy(pc),d3
	move	d3,d5
	ext.l	d3
	lsl.l	#focshft,d3
	divs	d2,d3	;sc Y1
	;
	move	camy(pc),d4
	neg	d4
	ext.l	d4
	lsl.l	#focshft,d4
	divs	d2,d4	;sc y2
	;
	sub	d3,d4	;y1,hite
	movem	d3-d4,vd_y(a0)
	;
	;elseif
	;
	moveq	#64,d5
	swap	d5
	clr	d5
	ext.l	d4
	;
	add.l	d5,d5
	add.l	d4,d4
	addq	#1,d4
	;
	divu.l	d4,d5
	;
	;elseif
	;v14: disabled old alternate quarter wall texture step.
	;This is the same class of wall-texture fix as the stable gloom.s path.
;	neg	d3
;	neg	d5
;	cmp	#-128,camy
;	sle	d4
;	ext	d4
;	add	d4,d5
;	;
;	swap	d5
;	clr	d5
;	ext.l	d3
;	divu.l	d3,d5	;sc step
;	asr.l	#2,d5
	;
	;elseif
	;
	move.l	d5,vd_ystep(a0)
	;
	cmp.l	a0,a4
	bne	.loop2
	;
.next	;onto next display column
	;
	lea	vd_size(a4),a4
	addq	#8,a6
	addq	#1,d7
	cmp	maxx(pc),d7
	blt	.loop
	;
	check	.loop
	;
	rts

makestrip	;this wall strip has see through bits!
	;insert it into shape list instead of vd list!
	;
	move.l	memat(pc),a0
	add.l	#vd_size,memat
	;
	move.l	memat(pc),a1
	add.l	#sh_size,memat
	;
	clr.l	(a1)
	move	d7,sh_x(a1)
	move	d2,sh_z(a1)
	clr.l	sh_shape(a1)
	move.l	a0,sh_strip(a1)
	;
	;insert into drawlist!
	;
	movem.l	a2-a3,-(a7)
	lea	shapelist(pc),a2
.loop	move.l	(a2),d0
	beq.s	.end
	move.l	a2,a3
	move.l	d0,a2
	cmp	sh_z(a2),d2	;nearer...further in list
	blt.s	.loop
	move.l	a2,(a1)
	move.l	a1,(a3)
	bra.s	.ins
.end	move.l	d0,(a1)
	move.l	a1,(a2)
.ins	movem.l	(a7)+,a2-a3
	;
	rts

drawsolidstrip	macro
	;
	;a0=stripdata, a1=dest, a2=palettes
	;d0=chunkymod
	;
	move	hite(pc),d1	;remainder to CLS
	move.l	vd_data(a0),d2
	beq	.vertskip	;no data
	move.l	d2,a3	;source texture column.
	move	vd_y(a0),d2
	move.l	vd_ystep(a0),d3
	move	vd_h(a0),d4
	;
	add	midy(pc),d2
	move	d2,g2_bayer_ybase	; v190ej: wall start row for Bayer shade blend
	bpl.s	.notopclip
	clr	g2_bayer_ybase	; top-clipped columns start at row 0
	;
	;clip top Y
	;
	add	d2,d4	;reduce hite of texture
	ble	.vertskip
	neg	d2
	ext.l	d2
	mulu.l	d3,d2	;y step* y
	bra.s	.clipdone
.notopclip	;
	beq.s	.notopcls
	;
	sub	d2,d1	;reduce botcls
	subq	#1,d2
	moveq	#0,d5
.topcls	move.b	d5,(a1)
	add.l	d0,a1
	dbf	d2,.topcls
.notopcls	;
	moveq	#0,d2	;start position in texture
	;
.clipdone	;a1=correct start!
	;
	sub	d4,d1	;reduce bot cls
	bge.s	.hiteok
	add	d1,d4
	ble	.rts
	moveq	#0,d1
.hiteok	;
	;d2=starting texture Y,d3=step,d4=height,a1=dest
	;
	swap	d2
	swap	d3
	subq	#1,d4
	move	vd_pal(a0),d5	;0...15
	move.l	0(a2,d5*4),a4
	; v190em: true bright-side lead-in for each real shade-table
	; transition.  The current wall shade is kept as base; only in the
	; last quarter before the next darker darktable step are Bayer pixels
	; drawn with the next darker palette.  No darker-side tail, no clip
	; or column dithering.
	clr	g2_bayer_thresh
	move	vd_z(a0),d6
	tst	g2_visibility
	bgt.s	.g2v190ey_wallblend_adv
	cmp	#(4<<grdshft),d6
	blo.s	.g2v190ej_wallblend_dist_ok
	sub	#(4<<grdshft),d6
	add	d6,d6
	add	#(4<<grdshft),d6
	cmp	#maxz-1,d6
	bls.s	.g2v190ej_wallblend_dist_ok
	move	#maxz-1,d6
	bra.s	.g2v190ej_wallblend_dist_ok
.g2v190ey_wallblend_adv
	move	d7,-(a7)
	move	d6,d7
	lsr	#1,d6
	lsr	#3,d7
	add	d7,d6
	lsr	#2,d7
	add	d7,d6
	lsr	#1,d7
	add	d7,d6
	cmp	#maxz-1,d6
	bls.s	.g2v190ey_wallblend_scale_ok
	move	#maxz-1,d6
.g2v190ey_wallblend_scale_ok
	move	(a7)+,d7
.g2v190ej_wallblend_dist_ok
	; v190eo: no near-distance skip here either.  Every bright
	; shade band may now get its last-quarter darker Bayer lead-in.
	cmp	#14,d5
	bcc	.g2v190ej_wallblend_setup_done
	movem.l	d1/d6/d7/a2,-(a7)
	move.l	darktable(pc),a5
	moveq	#15,d7
	move	d6,d1
	add	#24,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_24ok
	move	#maxz-1,d1
.g2v190em_wallblend_24ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#11,d7
	move	d6,d1
	add	#48,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_48ok
	move	#maxz-1,d1
.g2v190em_wallblend_48ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#7,d7
	move	d6,d1
	add	#72,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_72ok
	move	#maxz-1,d1
.g2v190em_wallblend_72ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	; v190ep: softer sparse start before the normal wall shade lead-in.
	moveq	#4,d7
	move	d6,d1
	add	#96,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_96ok
	move	#maxz-1,d1
.g2v190em_wallblend_96ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#2,d7
	move	d6,d1
	add	#112,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190ep_wallblend_112ok
	move	#maxz-1,d1
.g2v190ep_wallblend_112ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#1,d7
	move	d6,d1
	add	#128,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190ep_wallblend_128ok
	move	#maxz-1,d1
.g2v190ep_wallblend_128ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bls.s	.g2v190em_wallblend_restore
.g2v190em_wallblend_set
	move	d7,g2_bayer_thresh
	addq	#1,d5
	cmp	#14,d5
	bls.s	.g2v190em_wallblend_palok
	moveq	#14,d5
.g2v190em_wallblend_palok
	move.l	0(a2,d5*4),a5
.g2v190em_wallblend_restore
	movem.l	(a7)+,d1/d6/d7/a2
.g2v190ej_wallblend_setup_done
	tst	g2_bayer_thresh
	bne.s	.g2v190ej_wall_dither_setup
	sub	d3,d2
	add.l	d3,d2
	;
.vertloop	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
	addx.l	d3,d2
	add.l	d0,a1
	dbf	d4,.vertloop
	bra.s	.vertskip
	;
.g2v190ej_wall_dither_setup
	movem.l	d1/d7/a2,-(a7)
	lea	g2v190ej_bayer_column_long,a2
	move	g2_bayer_x,d6
	and	#3,d6
	adda.w	d6,a2
	move	g2_bayer_ybase,d6
	and	#3,d6
	lsl	#2,d6
	adda.w	d6,a2
	move	g2_bayer_thresh,d7
	sub	d3,d2
	add.l	d3,d2	; set X flag immediately before the dither loop
.g2v190ej_wall_dither_loop
	moveq	#0,d1
	move.b	(a2),d1
	cmp	d7,d1
	bcc.s	.g2v190ej_wall_base
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2v190ej_wall_advance
.g2v190ej_wall_base
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2v190ej_wall_advance
	addx.l	d3,d2
	add.l	d0,a1
	lea	4(a2),a2	; next Bayer row, does not disturb X flag
	dbf	d4,.g2v190ej_wall_dither_loop
	movem.l	(a7)+,d1/d7/a2
.vertskip	;
	subq	#1,d1
	blt.s	.rts
	moveq	#0,d5
.botcls	move.b	d5,(a1)
	add.l	d0,a1
	dbf	d1,.botcls
.rts	;
	endm

drawshapes	lea	shapelist(pc),a6
	;
.drawloop	move.l	(a6),d0
	beq	.rts
	move.l	d0,a6
	; v190ay: beyond the hard far-fog distance, do not draw later
	; shape/wallstrip overlays at all.  They were rendered after the far
	; corridor fog and could appear as horizontal wrong-texture lines inside
	; the dark zone.  Real far walls/floors are already handled by the wall
	; renderer/fog; sprites and transparent strips should only fade in before
	; they reach this fully dark distance.
	move	#(6<<grdshft),d0
	tst	g2_visibility
	ble.s	.g2v190dw_shapelist_view_ok
	move	#g2advshapez,d0	; v190fc: ADVANCED strips/objects = 16 texture widths
.g2v190dw_shapelist_view_ok
	move	sh_z(a6),d1
	cmp	d0,d1
	bcc	.drawloop
	; v190dz: dissolve far transparent strips/objects in ADVANCED
	; with the same 8..12 texture-width Bayer band as solid walls,
	; otherwise switches/doors/strip overlays pop at their hard clip.
	tst	g2_visibility
	; v190ey: keep transparent strips/objects alive; no old far-end dissolve.
	bra	.g2v190dz_shapeclip_done
	ble.s	.g2v190dz_shapeclip_done
	cmp	#(8<<grdshft),d1
	blo.s	.g2v190dz_shapeclip_done
	move	d1,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 8..16 texture-width far band
	cmp	#15,d6
	bls.s	.g2v190dz_shapeclip_lvl_ok
	moveq	#15,d6
.g2v190dz_shapeclip_lvl_ok
	move	d1,d5
	lsr	#8,d5
	and	#3,d5
	lsl	#2,d5
	move	sh_x(a6),d4
	and	#3,d4
	add	d4,d5
	lea	g2v190dz_bayer4(pc),a2
	moveq	#0,d4
	move.b	0(a2,d5),d4
	cmp	d6,d4
	; v190ed: zero-distance branch removed; keep far strips/objects alive for fog fade
.g2v190dz_shapeclip_done
	move.l	sh_shape(a6),d0
	bne.s	.shape
	;
	;wall strip!
	;
	move	sh_x(a6),d0
	add	midx(pc),d0
	move.l	chunky(pc),a1
	lea	coloffs(pc),a5
	add.l	0(a5,d0*4),a1
	;
	move.l	palette(pc),a2
	move.l	sh_strip(a6),a4
	bsr	drawstrip2
	bra	.drawloop
	;
.shape	move.l	d0,a0
	movem	sh_x(a6),d0-d2
	move	sh_scale(a6),d7
	movem	(a0)+,d3-d4	;x,y handles
	;
	muls	d7,d3	;* scale
	asr.l	#8,d3
	sub.l	d3,d0
	;
	muls	d7,d4
	asr.l	#8,d4
	sub.l	d4,d1
	;
	;d0=rotated X, d1=Y, d2=Z
	;
	lsl.l	#focshft,d0
	divs	d2,d0	;Screen X
	cmp	maxx(pc),d0
	bge	.drawloop	;X too big!
	;
	lsl.l	#focshft,d1
	divs	d2,d1	;Screen Y
	cmp	maxy(pc),d1
	bge	.drawloop
	;
	movem	(a0),d3-d4	;width/hite
	;
	move.l	d3,d5
	muls	d7,d3
	;
	ifne	8-focshft
	asr.l	#8-focshft,d3
	endc
	;
	divs	d2,d3	;screen width
	ext.l	d3
	ble	.drawloop
	;
	move.l	d4,d6
	muls	d7,d4
	;
	ifne	8-focshft
	asr.l	#8-focshft,d4
	endc
	;
	divs	d2,d4	;hite
	ext.l	d4
	ble	.drawloop
	;
	swap	d5
	divu.l	d3,d5
	;
	add	midx(pc),d0
	bpl.s	.xcskip
	add	d0,d3	;reduce width
	ble	.drawloop
	neg	d0
	;
	ext.l	d0
	mulu.l	d5,d0	;start column in shape
	;
	moveq	#0,d7
	cmp	width(pc),d3
	ble.s	.xcdone
	move	width(pc),d3
	bra.s	.xcdone
	;
.xcskip	move	d0,d7	;sc X
	add	d3,d0
	sub	width(pc),d0
	ble.s	.xcdone2
	sub	d0,d3
	ble	.drawloop
.xcdone2	move.l	d5,d0
	lsr.l	#1,d0
.xcdone	;
	swap	d6
	divu.l	d4,d6	;y step
	;
	move.l	chunky(pc),a1
	;
	add	midy(pc),d1
	bpl.s	.ycskip
	add	d1,d4	;hite
	ble	.drawloop
	neg	d1
	ext.l	d1
	mulu.l	d6,d1
	;
	cmp	hite(pc),d4
	ble.s	.ycdone
	move	hite(pc),d4
	bra.s	.ycdone
	;
.ycskip	move	d1,-(a7)
	mulu	chunkymodw(pc),d1
	add.l	d1,a1
	move	(a7)+,d1
	add	d4,d1
	sub	hite(pc),d1
	ble.s	.ycdone2
	sub	d1,d4
	ble	.drawloop
.ycdone2	move.l	d6,d1
	lsr.l	#1,d1
.ycdone	;
	;draw bit...
	;
	;a0=src, a1=dest, a2=palette
	;
	;d0.q=src x
	;d1.q=src y
	;d2.w = Z!
	;d3.w=width
	;d4.w=height
	;d5.q=x step
	;d6.q=y step
	;d7.w=start screen column
	;a0.l=src
	;a1.l=dest
	;a2.l=palette
	;
	bsr	g2_setup_enemy_blob_column	;v126 hard-edged per-column shadow under enemies
	lea	coloffs,a5
	lea	0(a5,d7*4),a5
	;
	move.l	sh_render(a6),a3
	move.l	a6,-(a7)
	move.l	vertdraws(pc),a6
	mulu	#vd_size,d7
	lea	0(a6,d7),a6	;column for Z compare!
	;
	move	d2,d7
	tst	g2_visibility
	bgt.s	.g2v190ey_obj_shade_adv
	cmp	#(4<<grdshft),d7
	blo.s	.g2v190dw_obj_shade_ok
	move	d6,-(a7)
	sub	#(4<<grdshft),d7
	add	d7,d7
	add	#(4<<grdshft),d7
	cmp	#maxz-1,d7
	bls.s	.g2v190ey_obj_shade_restore_default
	move	#maxz-1,d7
.g2v190ey_obj_shade_restore_default
	move	(a7)+,d6
	bra.s	.g2v190dw_obj_shade_ok
.g2v190ey_obj_shade_adv
	move	d6,-(a7)
	move	d7,d6
	lsr	#1,d7
	lsr	#3,d6
	add	d6,d7
	lsr	#2,d6
	add	d6,d7
	lsr	#1,d6
	add	d6,d7
	cmp	#maxz-1,d7
	bls.s	.g2v190ey_obj_shade_restore_adv
	move	#maxz-1,d7
.g2v190ey_obj_shade_restore_adv
	move	(a7)+,d6
.g2v190dw_obj_shade_ok
	move.l	darktable(pc),a2
	move	0(a2,d7*2),d7
	; v190ec: keep ADVANCED far sprites/switch-like objects fogged
	; at the advanced clip instead of letting them appear fully at once.
	tst	g2_visibility
	; v190ey: no additional ADVANCED object fog clamp; scaled darktable handles it.
	bra	.g2v190ec_objfog_done
	ble.s	.g2v190ec_objfog_done
	cmp	#(8<<grdshft),d2
	blo.s	.g2v190ec_objfog_done
	movem.l	d0-d6,-(a7)
	move	d2,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 8..16 texture-width far band
	cmp	#15,d6
	bls.s	.g2v190ec_objfog_lvl_ok
	moveq	#15,d6
.g2v190ec_objfog_lvl_ok
	move	d6,d0
	lsr	#2,d0
	add	d0,d7
	cmp	#15,d7
	bls.s	.g2v190ec_objfog_cap_ok
	moveq	#15,d7
.g2v190ec_objfog_cap_ok
	movem.l	(a7)+,d0-d6
.g2v190ec_objfog_done
	move.l	palette(pc),a2
	move.l	0(a2,d7*4),a2
	;
	subq	#1,d3
	subq	#1,d4
	swap	d0
	swap	d1
	swap	d5
	swap	d6
	addq	#2,a0
	;
	jsr	(a3)	;drawobjnorm/invs
	clr	g2_shadow_active	;v126 shadow state belongs to this one sprite
	;
	move.l	(a7)+,a6
	bra	.drawloop
	;
.rts	rts

drawobjinvs	;draw invisible object (half brite background!)
	;
	rts
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcc.s	.zbad
	;
	movem.l	d0-d2/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	chunkymodw(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$eee,d2	;RGB and
	;
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	;
	move	(a4),d5
	and	d2,d5
	lsr	#1,d5
	move	d5,(a4)
	;
.skip	add.l	d6,d1	;next src Y
	addx	d0,d1
	add.l	d7,a4
	dbf	d4,.vloop
	;
	movem.l	(a7)+,d0-d2/d4-d5
	;
.zbad	add.l	d5,d0
	moveq	#0,d7
	addx.l	d7,d0	;next src X
	lea	vd_size(a6),a6
	;
	dbf	d3,.hloop
	;
	rts

drawobjtrans	;draw transparent object (merge both colours!)
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcc.s	.zbad
	;
	movem.l	d0-d5/a5-a6,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move.l	chunkymod(pc),d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$eee,d2	;RGB and
	;
	move.l	planar_remap(pc),a5	;remap RGB->LUT
	move.l	planar_palette,a6
	;
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	;
	move.b	0(a2,d5),d5	;ghost colour!
	move	0(a6,d5*4),d5	;to RGB
	and	d2,d5
	;
	moveq	#0,d3
	move.b	(a4),d3
	move	0(a6,d3*4),d3	;to RGB
	and	d2,d3
	;
	add	d3,d5
	lsr	#1,d5
	move.b	0(a5,d5),(a4)
	moveq	#0,d5
	;
.skip	add.l	d6,d1	;next src Y
	addx	d0,d1	;xtend
	add.l	d7,a4
	dbf	d4,.vloop
	bsr	g2_draw_enemy_blob_column	;v173 reflections below transparent/invisible pickups too
	;
	movem.l	(a7)+,d0-d5/a5-a6
	;
.zbad	tst	g2_shadow_active
	ble.s	.noshinc
	addq	#1,g2_shadow_curx
.noshinc	add.l	d5,d0
	moveq	#0,d7
	addx.l	d7,d0	;next src X
	lea	vd_size(a6),a6
	;
	dbf	d3,.hloop
	;
	rts

drawobjnorm	;normal draw object...
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcs.s	.zok
	;
	tst	thermo
	beq.s	.zbad
	;
	bsr	thermostrip
	bra.s	.zbad
	;
.zok	movem.l	d0-d1/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move.l	chunkymod(pc),d7
	moveq	#0,d5
	moveq	#0,d0
	;
	sub	d6,d1
	add.l	d6,d1
	;
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	move.b	0(a2,d5),(a4)
.skip	addx.l	d6,d1	;next src Y
	add.l	d7,a4
	dbf	d4,.vloop
	bsr	g2_draw_enemy_blob_column	;v126 hard-edged dark column below enemy feet
	;
	movem.l	(a7)+,d0-d1/d4-d5
	;
.zbad	tst	g2_shadow_active
	ble	.noshinc
	addq	#1,g2_shadow_curx
.noshinc	add.l	d5,d0
	moveq	#0,d7
	addx.l	d7,d0	;next src X
	lea	vd_size(a6),a6
	;
	dbf	d3,.hloop
	;
	rts

thermostrip	movem.l	d0-d2/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	chunkymodw(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$00f,d2
	;
	sub	d6,d1
	add.l	d6,d1
	;
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	;
	move	0(a2,d5*2),d5
	and	d2,d5
	move	d5,(a4)
	;
.skip	addx.l	d6,d1	;next src Y
	add.l	d7,a4
	dbf	d4,.vloop
	;
	movem.l	(a7)+,d0-d2/d4-d5
	;
	rts


; -----------------------------------------------------------------------------
; v137/v176/v190dq/v190ds enemy blob shadows + floor-anchored reflections.
; Blob shadows keep the confirmed hard-edged foot shadow path.  Reflections use
; one remapped colour only. v190ds keeps the clean one-colour look but widens
; the dithered edge bands for a softer test falloff without bright rims.
; -----------------------------------------------------------------------------
g2_setup_enemy_blob_column
	movem.l	d0-d7/a0-a2,-(a7)
	clr	g2_shadow_active
	move.l	sh_prev(a6),a2	;object owner copied when shape was queued
	tst.l	a2
	beq	.done
	move.l	player1(pc),d0
	cmp.l	d0,a2
	beq	.done
	move.l	player2(pc),d0
	cmp.l	d0,a2
	beq	.done
	;
	; v132: reflections first.  The accidental projectile shadows in v126 showed
	; that bullets also pass this same draw path, so use it deliberately now.
	tst	g2_reflections
	ble	.try_blob
	move.l	ob_logic(a2),d0
	cmp.l	#firelogic,d0
	beq	.setup_reflection
	cmp.l	#homeinlogic,d0
	beq	.setup_reflection
	cmp.l	#weaponlogic,d0
	beq	.setup_reflection
	; v169: minimal stationaere Powerup-Reflections, bewusst eng
	; gefiltert.  Nicht alle rts-Objekte reflektieren, nur bekannte
	; Upgrade-/Pickup-Hit-Handler plus Bouncy-Logic.
	cmp.l	#bouncylogic,d0
	beq	.setup_reflection
	move.l	ob_hit(a2),d0
	cmp.l	#bouncygot,d0
	beq	.setup_reflection
	cmp.l	#weapongot,d0
	beq	.setup_reflection
	cmp.l	#thermogot,d0
	beq	.setup_reflection
	cmp.l	#invisigot,d0
	beq	.setup_reflection
	cmp.l	#invincgot,d0
	beq	.setup_reflection
	bra	.try_blob
	;
.setup_reflection
	bsr	g2_prepare_reflection_column
	bra	.done
	;
.try_blob
	tst	g2_blobshadow
	ble	.done
	; v127: bullets use colltype 1/2/4 and were visible in v126.
	; Real monsters use colltype 0 here, so keep shadows enemy-only.
	tst	ob_colltype(a2)
	bne	.done
	tst	ob_hitpoints(a2)
	ble	.done
	; v128: keep blob shadows only in the near range.
	; Far floors are already heavily darkened by distance shading, and a fixed
	; palette blob can look brighter there.  About three map/texture widths
	; (=3*gs) is the visible cutoff.
	cmp	#3<<grdshft,d2
	bgt	.done
	; d7=start screen column, d3=visible clipped sprite width
	move	d7,g2_shadow_curx
	move	d7,d0
	move	d3,d1
	lsr	#1,d1
	add	d1,d0
	move	d0,g2_shadow_cx
	; v130: foot-width blob, not full body width.  Use about half the
	; visible sprite width as the total shadow width (radius = width/4).
	move	d3,d0
	lsr	#2,d0
	cmp	#3,d0
	bge	.rx_min_ok
	moveq	#3,d0
.rx_min_ok
	cmp	#16,d0
	ble	.rx_max_ok
	moveq	#16,d0
.rx_max_ok
	move	d0,g2_shadow_rx
	moveq	#1,d0	;v129 fallback: darker blob shadow
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq	.col_ok
	move	#$111,d1	;v129: darker shadow tone
	move.b	0(a0,d1.w),d0
	bne	.col_ok
	move	#$222,d1
	move.b	0(a0,d1.w),d0
	bne	.col_ok
	moveq	#1,d0
.col_ok	move	d0,g2_shadow_col
	move	#1,g2_shadow_active
.done	movem.l	(a7)+,d0-d7/a0-a2
	rts

; prepare coloured reflection under bullets or weapon pickups.
; active=2 means reflection, active=1 means enemy blob shadow.
g2_prepare_reflection_column
	; d7=start screen column, d3=visible clipped sprite width, a2=object
	; v170: projectiles now cast a reflection about as wide as the visible
	; projectile itself.  Stationary upgrade/pickup reflections stay anchored
	; on the floor and only pulse lightly at the low/bottom part of their
	; bobbing/animation phase.
	cmp	#3<<grdshft,d2
	bgt	.no_reflect
	move	d7,g2_shadow_curx
	move	d7,d0
	move	d3,d1
	lsr	#1,d1
	add	d1,d0
	move	d0,g2_shadow_cx
	clr	g2_reflect_pickup
	bsr	g2_reflect_owner_is_pickup
	tst	d0
	beq	.bullet_size
	move	#1,g2_reflect_pickup
	; v182: weapon upgrades should read more like projectile reflections:
	; still clearly visible, but smaller in the distance and less oversized.
	move.l	ob_hit(a2),d1
	cmp.l	#weapongot,d1
	bne.s	.pick_token_size
	move	d3,d0
	lsr	#1,d0
	cmp	#3,d0
	bge	.wp_min_ok
	moveq	#3,d0
.wp_min_ok
	cmp	#16,d0
	ble	.wp_pulse
	moveq	#16,d0
.wp_pulse
	; v185: weapon-upgrade reflections stay visible at their base size.
	; Only the brief floor-touch moment should make the oval swell.
	move	ob_y(a2),d1
	bpl.s	.wp_y_abs
	neg	d1
.wp_y_abs	cmp	#4,d1
	bgt.s	.pick_pulse_done
	move	d0,d1
	lsr	#1,d1
	add	d1,d0
	cmp	#24,d0
	ble.s	.pick_pulse_done
	moveq	#24,d0
	bra.s	.pick_pulse_done
.pick_token_size
	move	d3,d0
	; v182: token/powerup upgrades also use a projectile-like oval that can
	; shrink properly with distance instead of staying too large far away.
	lsr	#1,d0
	cmp	#2,d0
	bge	.up_min_ok
	moveq	#2,d0
.up_min_ok
	cmp	#14,d0
	ble	.pick_pulse
	moveq	#14,d0
.pick_pulse
	; v185: token/powerup reflections are always visible at their base size.
	; Only the brief floor-touch moment should increase the oval.
	move	ob_y(a2),d1
	bpl.s	.pick_y_abs
	neg	d1
.pick_y_abs	cmp	#4,d1
	bgt.s	.pick_pulse_done
	move	d0,d1
	lsr	#1,d1
	add	d1,d0
	cmp	#21,d0
	ble.s	.pick_pulse_done
	moveq	#21,d0
.pick_pulse_done
	bra	.rx_ok
.bullet_size
	move	d3,d0
	; v170: projectile reflection diameter ~= projectile width, so radius
	; ~= visible width / 2 instead of the older smaller width / 3 shadow.
	lsr	#1,d0
	cmp	#2,d0
	bge	.bul_min_ok
	moveq	#2,d0
.bul_min_ok
	cmp	#16,d0
	ble	.rx_ok
	moveq	#16,d0
.rx_ok
	move	d0,g2_shadow_rx
	; v181: pickups get an absolute projected floor row, so their reflection
	; can be anchored to the same floor plane as projectile reflections
	; without following the bobbing sprite bitmap.  Projectiles keep the old
	; relative y-offset path.
	clr	g2_shadow_yoff
	clr	g2_reflect_floorrow
	tst	g2_reflect_pickup
	beq.s	.projectile_floor_yoff
	move	camy(pc),d0
	neg	d0
	ext.l	d0
	asl.l	#focshft,d0
	divs	d2,d0
	add	midy(pc),d0
	addq	#2,d0		; v189: back to the v186 pickup reflection baseline, but about 2px higher
	cmp	#2,d0
	bge.s	.pick_row_min_ok
	moveq	#2,d0
.pick_row_min_ok
	move	hite(pc),d1
	sub	#12,d1
	cmp	d1,d0
	ble.s	.pick_row_max_ok
	move	d1,d0
.pick_row_max_ok	move	d0,g2_reflect_floorrow
	bra.s	.y_done
.projectile_floor_yoff
	move	ob_y(a2),d0
	neg	d0
.scale_yoff	ext.l	d0
	asl.l	#focshft,d0
	divs	d2,d0
	cmp	#30,d0
	ble	.ymax_ok
	moveq	#30,d0
.ymax_ok	cmp	#-16,d0
	bge	.ymin_ok
	move	#-16,d0
.ymin_ok	move	d0,g2_shadow_yoff
.y_done	bsr	g2_reflection_colour
	move	d0,g2_shadow_col
	move	#2,g2_shadow_active
	rts
.no_reflect	clr	g2_shadow_active
	rts

; v169: narrow pickup classifier used only by the reflection path.
g2_reflect_owner_is_pickup
	move.l	ob_logic(a2),d0
	cmp.l	#weaponlogic,d0
	beq.s	.yes
	cmp.l	#bouncylogic,d0
	beq.s	.yes
	move.l	ob_hit(a2),d0
	cmp.l	#bouncygot,d0
	beq.s	.yes
	cmp.l	#weapongot,d0
	beq.s	.yes
	cmp.l	#thermogot,d0
	beq.s	.yes
	cmp.l	#invisigot,d0
	beq.s	.yes
	cmp.l	#invincgot,d0
	beq.s	.yes
	moveq	#0,d0
	rts
.yes	moveq	#1,d0
	rts

g2_reflection_colour
	; v190dq: use one darker projectile/upgrade colour for the complete
	; reflection.  Edge dithering happens in the draw path, without the old
	; brighter rim colour that caused dirty/light borders.
	movem.l	d1-d3/a0,-(a7)
	moveq	#0,d2
	move.l	ob_shape(a2),d1
	cmp.l	#bullet1,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet2,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet3,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet4,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet5,d1
	beq	.got_weapon
	; v169/v174: colour stationary powerup reflections by pickup family.
	move.l	ob_logic(a2),d1
	cmp.l	#bouncylogic,d1
	beq	.got_bouncy
	move.l	ob_hit(a2),d1
	cmp.l	#thermogot,d1
	beq	.got_thermo
	cmp.l	#invisigot,d1
	beq	.got_invisi
	cmp.l	#invincgot,d1
	beq	.got_invinc
	move	ob_weapon(a2),d2
	bra	.got_weapon
.got_bouncy	moveq	#1,d2	; green-ish
	bra	.got_weapon
.got_thermo	moveq	#3,d2	; cyan-ish
	bra	.got_weapon
.got_invisi	moveq	#4,d2	; magenta-ish
	bra	.got_weapon
.got_invinc	moveq	#0,d2	; yellow-ish
.got_weapon
	and	#7,d2
	moveq	#2,d0	; dark centre/body fallback
	moveq	#15,d3	; bright sparse edge fallback
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq	.store_edge
	lea	g2_reflect_dark_rgb(pc),a0
	move	0(a0,d2*2),d1
	move.l	planar_remap(pc),a0
	move.b	0(a0,d1.w),d0
	bne	.edge_colour
	moveq	#2,d0
.edge_colour	lea	g2_reflect_rgb(pc),a0
	move	0(a0,d2*2),d1
	move.l	planar_remap(pc),a0
	move.b	0(a0,d1.w),d3
	bne	.store_edge
	moveq	#15,d3
.store_edge	move	d0,g2_reflect_edge_col	; v190dq: edge uses same colour as body
	movem.l	(a7)+,d1-d3/a0
	rts

; RGB12 colours, remapped to the active Gloom palette at runtime.
; v174 weapon/projectile colours: 1 yellow, 2 green, 3 green/white,
; 4 blue/white, 5 magenta.  Dark table is the visible reflection body.
; The bright table is retained for compatibility but v190dq no longer uses
; it as a separate visible rim colour.
g2_reflect_dark_rgb
	dc	$520,$040,$030,$404,$404,$520,$040,$030	; v190du: weapon 4 colour only matches weapon 5
g2_reflect_rgb
	dc	$960,$0a0,$6f6,$66f,$a0a,$960,$0a0,$6f6

g2_draw_enemy_blob_column
	; called from drawobjnorm/drawobjtrans after the current sprite column was drawn.
	; a4 points one row below the drawn/clipped sprite column.
	movem.l	d0-d7/a0-a1,-(a7)
	tst	g2_shadow_active
	ble	.rts
	cmp	#2,g2_shadow_active
	beq	.reflection
	move	g2_shadow_curx(pc),d0
	move	d0,d1
	sub	g2_shadow_cx(pc),d1
	bpl	.abs_ok
	neg	d1
.abs_ok	move	g2_shadow_rx(pc),d2
	cmp	d2,d1
	bgt	.rts
	; v130: narrower, more oval hard-edged foot shadow.  The centre is
	; a little thicker, but the outer columns stay 1 pixel high so the shape
	; reads as an ellipse instead of a wide flat diamond/karo.
	moveq	#2,d5	;outer edge vertical offset
	moveq	#0,d6	;dbf count: 1 row
	move	d2,d3
	mulu	#7,d3
	lsr	#3,d3	;7/8 radius: thin outer edge
	cmp	d3,d1
	bgt	.have_band
	moveq	#1,d5
	moveq	#1,d6	;2 rows in broad mid band
	move	d2,d3
	lsr	#1,d3	;1/2 radius
	cmp	d3,d1
	bgt	.have_band
	moveq	#0,d5
	moveq	#2,d6	;3 rows in centre
	move	d2,d3
	lsr	#2,d3	;1/4 radius
	cmp	d3,d1
	bgt	.have_band
	moveq	#0,d5
	moveq	#2,d6	;keep hard oval centre, no tall diamond peak
.have_band
	move.l	a4,a0
	move.l	chunkymod(pc),d7
	sub.l	d7,a0	;v132: one pixel lower than v131, still above v130
	sub.l	d7,a0
	sub.l	d7,a0
	; skip down by start offset
	tst	d5
	beq	.draw
.offloop	adda.l	d7,a0
	subq	#1,d5
	bne	.offloop
.draw	move	g2_shadow_col(pc),d4
.yloop	move.b	d4,(a0)
	adda.l	d7,a0
	dbf	d6,.yloop
	bra	.rts
	;
.reflection
	move	g2_shadow_curx(pc),d0
	move	d0,d1
	sub	g2_shadow_cx(pc),d1
	bpl	.rabs_ok
	neg	d1
.rabs_ok	move	g2_shadow_rx(pc),d2
	cmp	d2,d1
	bgt	.rts
	; v172: projectiles get a real oval instead of the too-flat one-line
	; stroke from v171.  Stationary pickups keep a floor oval and can pulse.
	clr	g2_reflect_softedge
	tst	g2_reflect_pickup
	bne.s	.pickup_band
	moveq	#2,d5	;projectile outer edge: low, wide oval
	moveq	#0,d6	;1 row
	move	d2,d3
	mulu	#3,d3
	lsr	#2,d3	;v190ds: 3/4 radius, wider sparse dither rim
	cmp	d3,d1
	bgt	.rsoft_outer
	moveq	#1,d5
	moveq	#1,d6	;2-row mid band
	move	d2,d3
	lsr	#2,d3	;v190ds: 1/4 radius, wider clean dither falloff
	cmp	d3,d1
	bgt	.rsoft_mid
	moveq	#0,d5
	moveq	#2,d6	;3-row solid centre, smaller than v190dr
	bra	.rband_ok
.pickup_band
	; v182/v190ds: draw pickup/upgrade reflections with the same oval profile
	; as projectile reflections, but with wider dithered falloff bands.
	moveq	#2,d5	;outer edge: low, wide oval
	moveq	#0,d6	;1 row
	move	d2,d3
	mulu	#3,d3
	lsr	#2,d3	;v190ds: 3/4 radius, wider sparse dither rim
	cmp	d3,d1
	bgt	.rsoft_outer
	moveq	#1,d5
	moveq	#1,d6	;2-row mid band
	move	d2,d3
	lsr	#2,d3	;v190ds: 1/4 radius, wider clean dither falloff
	cmp	d3,d1
	bgt	.rsoft_mid
	moveq	#0,d5
	moveq	#2,d6	;3-row solid centre, smaller than v190dr
	bra	.rband_ok
.rsoft_outer
	move	#2,g2_reflect_softedge	;outer edge: sparse dither
	bra	.rband_ok
.rsoft_mid
	move	#1,g2_reflect_softedge	;mid edge: light dither
.rband_ok
	move.l	chunkymod(pc),d7
	tst	g2_reflect_pickup
	bne.s	.pick_anchor_a
	move.l	a4,a0
	sub.l	d7,a0
	sub.l	d7,a0
	; projectile path: relative floor-anchor from sprite underside.
	move	g2_shadow_yoff(pc),d3
	beq	.yoff_done
	bmi	.yoff_up
.yoff_down	adda.l	d7,a0
	subq	#1,d3
	bne	.yoff_down
	bra	.yoff_done
.yoff_up	neg	d3
.yoff_up_loop	suba.l	d7,a0
	subq	#1,d3
	bne	.yoff_up_loop
	bra.s	.yoff_done
.pick_anchor_a
	move.l	chunky(pc),d0
	move	g2_shadow_curx(pc),d4
	lsl	#2,d4
	lea	coloffs(pc),a0
	add.l	0(a0,d4.w),d0
	move.l	d0,a0
	move	g2_reflect_floorrow(pc),d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a0
	sub.l	d7,a0
	sub.l	d7,a0
.yoff_done
	; safety: never let reflections write into the status/gun area.
	move.l	chunky(pc),a1
	move	g2_shadow_curx(pc),d4
	lsl	#2,d4
	lea	coloffs(pc),a0
	add.l	0(a0,d4.w),a1
	move	hite(pc),d4
	sub	#10,d4
	mulu	chunkymodw(pc),d4
	add.l	d4,a1
	tst	g2_reflect_pickup
	bne.s	.pick_anchor_b
	move.l	a4,a0
	sub.l	d7,a0
	sub.l	d7,a0
	move	g2_shadow_yoff(pc),d3
	beq	.clamp_yoff_done
	bmi	.clamp_yoff_up
.clamp_yoff_down	adda.l	d7,a0
	subq	#1,d3
	bne	.clamp_yoff_down
	bra	.clamp_yoff_done
.clamp_yoff_up	neg	d3
.clamp_yoff_up_loop	suba.l	d7,a0
	subq	#1,d3
	bne	.clamp_yoff_up_loop
	bra.s	.clamp_yoff_done
.pick_anchor_b
	move.l	chunky(pc),d0
	move	g2_shadow_curx(pc),d3
	lsl	#2,d3
	lea	coloffs(pc),a0
	add.l	0(a0,d3.w),d0
	move.l	d0,a0
	move	g2_reflect_floorrow(pc),d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a0
	sub.l	d7,a0
	sub.l	d7,a0
.clamp_yoff_done	cmp.l	a1,a0
	bhi	.rts
	tst	d5
	beq	.rdraw
.roffloop	adda.l	d7,a0
	subq	#1,d5
	bne	.roffloop
.rdraw	move	g2_shadow_col(pc),d4
		; v190dq one-colour pseudo-alpha: centre/body uses the remapped
		; projectile/upgrade colour, and only the outer ellipse bands dither
		; against the floor.  This removes the old bright reflection outline.
		move	g2_reflect_softedge(pc),d0
		beq	.centre_dither
		move	g2_reflect_edge_col(pc),d4
		move	g2_shadow_curx(pc),d3
		add	d6,d3
		cmp	#2,d0
		beq	.outer_dither
		btst	#0,d3	; mid edge: dither every second sample
		bne	.rts
		bra	.ryloop
.outer_dither
		and	#3,d3	; outer edge: keep one in four samples
		bne	.rts
		bra	.ryloop
.centre_dither
		; v190dq: solid one-colour centre/body; only edges are dithered.
		bra	.ryloop
.ryloop	move.b	d4,(a0)
	adda.l	d7,a0
	dbf	d6,.ryloop
.rts	movem.l	(a7)+,d0-d7/a0-a1
	rts

renderwalls	;
	move.l	chunkymod(pc),d0
	move.l	vertdraws(pc),a0
	move.l	palette(pc),a2
	lea	palettes,a2
	lea	coloffs(pc),a6
	;
	move	width(pc),d7
	subq	#1,d7
	;
.loop	move.l	(a6)+,a1
	add.l	chunky(pc),a1
	;
	; v190ej: screen-X phase for wall shade-step Bayer blend.
	move	width(pc),d6
	subq	#1,d6
	sub	d7,d6
	move	d6,g2_bayer_x
	;
	drawsolidstrip
	;
	lea	vd_size(a0),a0
	dbf	d7,.loop
	;
	rts

solidstrip	set	0
drawstrip2	; v190bz chunky-safe transparent wall strip overlay with green glass
	; a1=top of destination column, a2=palettes base, a4=strip/vd data
	; Non-zero texels are drawn through the current wall palette.  Zero texels
	; are normally transparent, except for the original Gloom strip flag -6
	; where zero texels apply a green transparent filter to the already-rendered
	; chunky pixel behind the strip.
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	vd_data(a4),d0
	beq	.rts
	move.l	d0,a0		; source texture column, byte -1 is the strip flag
	moveq	#0,d6		; 0 = plain transparency on texel 0
	move.b	-1(a0),d6
	; v190cb: handle all original coloured transparent strip flags, not only
	; -6.  The classic renderer uses -7..-2 as coloured glass/mask selectors
	; and -1 as neutral transparency.  Some Deluxe green windows do not arrive
	; as exactly -6 after texture remapping, so treat every coloured flag as
	; green-tinted for this focused green-glass restoration pass.
	cmp.b	#$f9,d6		; -7..-2 are coloured flags
	bcs.s	.g2st_plain
	cmp.b	#$ff,d6		; -1 = neutral transparent/white, keep plain
	beq.s	.g2st_plain
	lea	g2_strip_green_lut,a6
	moveq	#1,d6
	bra.s	.g2st_mode_done
.g2st_plain
	moveq	#0,d6
.g2st_mode_done
	move.l	chunkymod(pc),d7
	move	vd_y(a4),d2
	add	midy(pc),d2	; screen Y start
	move.l	vd_ystep(a4),d3
	move	vd_h(a4),d4
	moveq	#0,d0		; texture Y start, 16.16 style after swap below
	tst	d2
	bpl.s	.notopclip
	add	d2,d4
	ble	.rts
	neg	d2
	ext.l	d2
	mulu.l	d3,d2
	move.l	d2,d0
	moveq	#0,d2
	bra.s	.clipdone
.notopclip
	beq.s	.clipdone
	move	d2,d5
	ext.l	d5
	mulu.l	d7,d5
	add.l	d5,a1
.clipdone
	move	hite(pc),d5
	sub	d2,d5
	ble	.rts
	cmp	d5,d4
	ble.s	.hiteok
	move	d5,d4
.hiteok
	subq	#1,d4
	blt	.rts
	swap	d0
	swap	d3
	sub	d3,d0
	add.l	d3,d0
	move	vd_pal(a4),d5
	move.l	0(a2,d5*4),a5
.loop
	move.b	0(a0,d0),d5
	beq.s	.zero
	move.b	0(a5,d5),(a1)
	bra.s	.advance
.zero
	tst	d6
	beq.s	.advance
	moveq	#0,d5
	move.b	(a1),d5
	move.b	0(a6,d5.w),(a1)
.advance
	addx.l	d3,d0
	add.l	d7,a1
	dbf	d4,.loop
.rts	movem.l	(a7)+,d0-d7/a0-a6
	rts

	dc	$f0ff,$ff0f,$fff0
	dc	$f00f,$f0f0,$ff00
	dc	$ffff
	;
stripands	;red,green,blue,yel,pur,cyn,wht

vwait	tst	os
	bne.s	.osvwait
	move	#1,vbcounter
.loop	tst	vbcounter
	bgt.s	.loop
	rts
.osvwait	movem.l	d0-d1/a0-a1/a6,-(a7)
	move.l	grbase(pc),a6
	jsr	-270(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a6
	rts

;************** DATA ***************************

data

active	dc.l	0	;is game input active?
temppal	dc.l	0
todb	dc.l	0
topokepal	dc.l	0
gloomcfg	dc.l	0
gloom	dc.l	0 ;incbin	title
gloompal	dc.l	0 ;incbin	title.pal
gloombrush	dc.l	0 ;incbin	gloombrush

panel	dc.l	0
gunpic	dc.l	0	;v20 optional misc/gun first-person weapon shape table
g2gun_firetimer	dc	0	;v65 short muzzle/firing-frame timer
g2gun_recoilflag	dc.b	0	;v68 nonzero while firing/recoil frame is active
	even
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

coplist	dc.l	0
slice1	dc.l	0
slice2	dc.l	0
copstop	dc.l	0

memlist	dc.l	0

dispnest	dc	0

coloffs	ds.l	320	;320 columns max

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

;************** SLOW SUBS **********************

slowsubs

;MOVE d1,d4:LSL #8,d1:MOVE.b d4,d1:MOVE d1,d4:SWAP d1:MOVE d4,d1
;MOVE d2,d4:LSL #8,d2:MOVE.b d4,d2:MOVE d2,d4:SWAP d2:MOVE d4,d2
;MOVE d3,d4:LSL #8,d3:MOVE.b d4,d3:MOVE d3,d4:SWAP d3:MOVE d4,d3
;;EXT.l d0:MOVE.l (a0),a0:LEA 44(a0),a0:JMP -$354(a6)
;LEA table(pc),a1:MOVE.b d0,3(a1):MOVEM.l d1-d3,4(a1)
;MOVE.l (a0),a0:LEA 44(a0),a0:JMP -$372(a6)
;table:Dc.l $00010000,0,0,0,0

lastpal	dc.l	0

pokelastpal	move.l	lastpal(pc),a1
	;
pokepal	;a1=palette to poke
	;
	move.l	a1,lastpal
	move	colours(pc),d0
pokepal2	;
	move.l	topokepal(pc),a0
	jmp	(a0)

to32	macro
	move	\1,d5
	lsl	#8,\1
	move.b	d5,\1
	move	\1,d5
	swap	\1
	move	d5,\1
	endm

pokepal_os	;
	;OS version!
	;
	move.l	temppal(pc),a0
	move	d0,(a0)+	;how many
	clr	(a0)+	;first colour
	subq	#1,d0
	;
.loop	move	(a1)+,d1	;hi nyb
	move	d1,d2
	move	d1,d3
	move	d1,d4
	tst	aga
	beq.s	.skip
	move	(a1)+,d4
	;
.skip	move	d4,d5
	and	#$f00,d1
	lsr	#4,d1
	and	#$f00,d5
	lsr	#8,d5
	or	d5,d1
	to32	d1
	;
	move	d4,d5
	and	#$0f0,d2
	and	#$0f0,d5
	lsr	#4,d5
	or	d5,d2
	to32	d2
	;
	and	#$00f,d3
	lsl	#4,d3
	and	#$00f,d4
	or	d4,d3
	to32	d3
	;
	movem.l	d1-d3,(a0)
	lea	12(a0),a0
	dbf	d0,.loop
	clr.l	(a0)
	;
	move.l	viewport(pc),a0
	move.l	temppal(pc),a1
	move.l	grbase(pc),a6
	jmp	-$372(a6)

pokepal_ecs	move.l	coplist,a2
	lea	palette_ecs-copinit_ecs(a2),a2
	subq	#1,d0
.loop0	move	(a1)+,2(a2)
	addq	#4,a2
	dbf	d0,.loop0
	rts

pokepal_aga	move.l	coplist,a2
	lea	palette_aga-copinit_aga(a2),a2
	subq	#1,d0
	move	d0,d2
	and	#31,d2
.loop	move	d2,d1
.loop2	move	(a1)+,6(a2)
	move	(a1)+,132+6(a2)
	addq	#4,a2
	dbf	d1,.loop2
	lea	264-128(a2),a2
	dbf	d0,.loop
	rts

decodeiff	;
	;a0=trimmed IFF file
	;a1=dest bitmap
	;
	move.l	bpmod(pc),d7
	;
	move	(a0)+,d0	;pixel width
	lsr	#3,d0	;to byte width
	move	(a0)+,d1	;pixel height
	cmp	#240,d1
	bls.s	.hok
	move	#240,d1
.hok	subq	#1,d1	;to dbf
	move	(a0)+,d2	;depth
	subq	#1,d2	;to dbf
	addq	#6,a0	;skip header
	;
.loop5	move	d2,d5	;depth
	move.l	a1,-(a7)	;start of newline
	;
.loop4	move.l	a1,a2
	move	d0,d4	;how many bytes in line
	;
.loop	moveq	#0,d3
	move.b	(a0)+,d3
	bmi.s	.repeat
	sub	d3,d4
.loop3	move.b	(a0)+,(a2)+
	dbf	d3,.loop3
	bra.s	.skip
	;
.repeat	cmp.b	#-128,d3
	beq.s	.loop
	neg.b	d3
	sub	d3,d4
.loop2	move.b	(a0),(a2)+
	dbf	d3,.loop2
	addq	#1,a0
.skip	subq	#1,d4
	bgt.s	.loop
	;
	add.l	d7,a1
	dbf	d5,.loop4
	;
	move	bitplanes(pc),d3
	subq	#1,d3
	sub	d2,d3
	ble.s	.noxs
	subq	#1,d3
	moveq	#0,d5
.c	move.l	a1,a2
	moveq	#9,d4	;clear a line
.cc	move.l	d5,(a2)+
	dbf	d4,.cc
	add.l	d7,a1
	dbf	d3,.c
.noxs	;
	move.l	(a7)+,a1
	add.l	linemod(pc),a1
	dbf	d1,.loop5
	;
	rts

copypic	movem.l	showbitmap,a0-a1
	move.l	bmapmem(pc),d1
	lsr.l	#2,d1
	subq	#1,d1
.loop	move.l	(a0)+,(a1)+
	dbf	d1,.loop
	rts

clspic	move.l	drawbitmap,a1
	move.l	bmapmem(pc),d1
	lsr.l	#2,d1
	subq	#1,d1
	moveq	#0,d0
.loop	move.l	d0,(a1)+
	dbf	d1,.loop
	bra	db

showpic	;a0=trimmed IFF file, a1=palette
	;
	movem.l	a0-a1,-(a7)
	bsr	clspic	;show a blank bitmap
	bsr	vwait
	movem.l	(a7),a0-a1
	tst.l	a0	;v190cj: absent picture -> blank safe frame
	beq.s	.nopic
	move.l	drawbitmap(pc),a1
	bsr	decodeiff
.nopic	movem.l	(a7)+,a0-a1
	tst.l	a1	;v190cj: absent palette -> keep current palette
	beq.s	.nopal
	bsr	pokepal
.nopal	bsr	db
	bra	vwait

showpic_noclear	;a0=trimmed IFF file, a1=palette
	; redraw without the intermediate blank/black clear to avoid
	; visible flicker on title/about transitions.
	movem.l	a0-a1,-(a7)
	tst.l	a0
	beq.s	.nopic
	move.l	drawbitmap(pc),a1
	bsr	decodeiff
.nopic	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq.s	.nopal
	bsr	pokepal
.nopal	bsr	db
	bra	vwait

	ifne	cd32

applname	dc.b	'Gloom',0
	even
itemname	dc.b	'Games',0
	even

gloomgame2	dc.b	'gamegamegamegamegame'

nvname	dc.b	'nonvolatile.library',0
	cnop	0,4
nv	dc.l	0

savegloomgame	;
	move.l	nv,d0
	beq.s	.done
	;
	move.l	d0,a6
	lea	applname(pc),a0
	lea	itemname(pc),a1
	lea	gloomgame2(pc),a2
	moveq	#2,d0	;20 bytes
	moveq	#-1,d1
	jsr	-42(a6)	;storenv
	tst.l	d0
	bne.s	.done	;error!
	;
	lea	applname(pc),a0
	lea	itemname(pc),a1
	moveq	#-1,d1
	moveq	#1,d2
	jsr	-66(a6)	;setnvprotection
	;
.done	rts

loadgloomgame	move.l	nv,d0
	beq.s	.done
	;
	move.l	d0,a6
	lea	applname(pc),a0
	lea	itemname(pc),a1
	moveq	#-1,d1
	jsr	-30(a6)	;getcopnv
	tst.l	d0
	beq.s	.done
	;
	move.l	d0,a0
	lea	gloomgame2(pc),a1
	moveq	#4,d1	;5 longs=20 bytes
.loop	move.l	(a0)+,(a1)+
	dbf	d1,.loop
	;
	move.l	d0,a0
	jsr	-36(a6)	;freenvdata
	;
.done	rts

	endc

flushc	;flush cache!
	;
	movem.l	a0-a1/d0-d1/a6,-(a7)
	move.l	4.w,a6
	cmp	#636,16(a6)
	bcs.s	.skip
	jsr	-636(a6)
.skip	movem.l	(a7)+,a0-a1/d0-d1/a6
	rts

findanglesign	;d1=angle I'm at ; d0=angle I wanna be at...return sign
	;(bmi, bpl) of add to get there
	;return cc (mi,pl) and d0.w (for tst) of sign to get there!
	;
	and	#255,d0
	and	#255,d1
	sub	d0,d1
	bpl.s	.plus
	;
	moveq	#1,d0
	cmp	#-128,d1
	bgt.s	.rts
	neg	d0
.rts	neg	d0
	rts
	;
.plus	moveq	#1,d0	;+
	cmp	#128,d1
	bge.s	.rts2
	neg	d0
.rts2	neg	d0
	rts

checklock	cmp	#2,d0
	bgt.s	.max
	cmp	#-2,d0
	bge.s	.rts
	moveq	#-2,d0
.rts	rts
.max	moveq	#2,d0
	rts

locklogic	;locking on to defender machine
	;
	bsr	playertimers	;do timer stuff...
	bsr	getcntrl	;player control
	;
	moveq	#0,d2	;how many locked
	move	ob_x(a5),d0
	sub	ob_telex(a5),d0
	bne.s	.lockx
	addq	#1,d2
	bra.s	.lockx2
.lockx	bsr	checklock
	sub	d0,ob_x(a5)
.lockx2	;
	move	ob_z(a5),d0
	sub	ob_telez(a5),d0
	bne.s	.lockz
	addq	#1,d2
	bra.s	.lockz2
.lockz	bsr	checklock
	sub	d0,ob_z(a5)
.lockz2	;
	move	ob_rot(a5),d1
	move	ob_telerot(a5),d0
	bsr	findanglesign
	;
	move	ob_rot(a5),d1
	sub	ob_telerot(a5),d1
	and	#255,d1
	bne.s	.lockrot
	addq	#1,d2
	bra.s	.lockrot2
.lockrot	cmp	#4,d1
	bls.s	.skip
	cmp	#256-4,d1
	bcs.s	.four
	or	#$ff00,d1
	neg	d1
	bra.s	.skip
.four	moveq	#4,d1
.skip	tst	d0
	bmi.s	.skip2
	neg	d1
.skip2	add	d1,ob_rot(a5)
	;
.lockrot2	bsr	unbounce
	tst	ob_bounce(a5)
	bne.s	.rts
	;
	subq	#3,d2
	bne.s	.rts
	;
	clr	ob_rotspeed(a5)
	move.l	#playdefender,ob_logic(a5)
	;
	move.b	floortag(pc),d0
	sub.b	#49,d0	;'1'->0
	ext	d0
	move	ltk(pc,d0*2),landerstokill
	move	lnd(pc,d0*2),landerdelay
	;
	move	#3,playerlives
	;
	bra	initnewdef
	;
.rts	rts

ltk	dc	20,35,50
lnd	dc	25,20,15

playdefender	bsr	atmachine
	bsr	defender
	move	landerstokill(pc),d0
	ble.s	.win
	move	playerlives(pc),d0
	ble.s	.lose
	rts
.win	addq	#1,ob_lives(a5)
	move	#-1,ob_update(a5)
	tst	gametype
	beq.s	.lose
	jsr	getother
	tst	ob_lives(a0)
	beq.s	.lose
	addq	#1,ob_lives(a0)
	move	#-1,ob_update(a0)
.lose	move	#96,ob_delay(a5)
	move.l	#waittolive,ob_logic(a5)
	rts

waittolive	bsr	atmachine
	bsr	defender
	subq	#1,ob_delay(a5)
	bgt.s	.rts
	move.l	#playerlogic,ob_logic(a5)
.rts	rts

atmachine	;standing at machine logic
	;
	bsr	playertimers	;do timer stuff...
	bsr	getcntrl	;player control
	;
	;OK, rotate slightly in front of machine!
	;
	move	joyx(pc),d0
	bne.s	.rot
	move	ob_rotspeed(a5),d0
	bpl.s	.rp
	addq	#2,ob_rotspeed(a5)
	ble.s	.rotdone
	clr	ob_rotspeed(a5)
	bra.s	.rotdone
.rp	subq	#2,ob_rotspeed(a5)
	bge.s	.rotdone
	clr	ob_rotspeed(a5)
	bra.s	.rotdone
.rot	bgt.s	.rplus
	subq	#1,ob_rotspeed(a5)
	cmp	#-8,ob_rotspeed(a5)
	bge.s	.rotdone
	move	#-8,ob_rotspeed(a5)
	bra.s	.rotdone
.rplus	addq	#1,ob_rotspeed(a5)
	cmp	#8,ob_rotspeed(a5)
	ble.s	.rotdone
	move	#8,ob_rotspeed(a5)
.rotdone	;
	move	ob_rotspeed(a5),d0
	move	d0,d4
	add	ob_telerot(a5),d0
	move	d0,ob_rot(a5)
	;
	move	d4,d5
	add	d4,d4
	add	d5,d4
	add	d4,d4
	;
	sub	#64,d0
	and	#255,d0
	move.l	camrots(pc),a0
	lea	0(a0,d0*8),a0
	move	d4,d5
	muls	2(a0),d4
	neg.l	d4
	swap	d4
	muls	6(a0),d5
	swap	d5
	add	ob_telex(a5),d4
	add	ob_telez(a5),d5
	move	d4,ob_x(a5)
	move	d5,ob_z(a5)
	rts

maxdefobjects	equ	128

	rsreset
	;
de_next	rs.l	1
de_prev	rs.l	1
de_xa	rs.l	1
de_ya	rs.l	1
de_x	rs.l	1
de_y	rs.l	1
de_shape	rs.w	1
de_delay	rs.w	1
de_colltype	rs.w	1
de_collwith	rs.w	1
de_logic	rs.l	1
	;
de_size	rs.b	0

defshapes	;
	dc	65,36,6,3	;0
	dc	65,40,6,3	;1
	dc	66,44,3,1	;2
	dc	66,46,3,1	;3
	dc	72,37,5,5	;4
	dc	84,37,1,1	;5
	dc	86,39,1,1	;6
	dc	81,39,1,1	;7
	dc	79,37,1,1	;8
	dc	71,44,2,1	;9
	dc	65,49,15,12	;10
	dc	86,49,11,10	;11
	dc	79,42,2,5	;12
	dc	85,42,2,5	;13

landerstoadd	dc	10	;how manylanders left!
landerstokill	dc	10
landerdelay	dc	25	;wait between landers
landercnt	dc	1
	;
defstack	dc.l	0
deflbut	dc.l	0	;last button status!
playerxa	dc.l	0	;x speed!
playerx	dc	0,0
playery	dc	14,0
playershape	dc	0
playerlives	dc	0

movedefplayer	move	joyx(pc),d0
	beq.s	.nox
	bpl.s	.xrite
	move	#1,playershape
	sub.l	#$8000,playerxa
	bpl.s	.xmore
	cmp.l	#-$30000,playerxa
	bge.s	.xdone
	move.l	#-$30000,playerxa
	bra.s	.xdone
.xmore	sub.l	#$4000,playerxa
	bra.s	.xdone
	;
.xrite	clr	playershape
	add.l	#$8000,playerxa
	ble.s	.xmore2
	cmp.l	#$30000,playerxa
	ble.s	.xdone
	move.l	#$30000,playerxa
	bra.s	.xdone
.xmore2	add.l	#$4000,playerxa
	bra.s	.xdone
	;
.nox	;to rest!
	move.l	playerxa(pc),d0
	beq.s	.xdone
	bpl.s	.xp
	add.l	#$1000,playerxa
	ble.s	.xdone
	clr.l	playerxa
.xp	sub.l	#$1000,playerxa
	bge.s	.xdone
	clr.l	playerxa
.xdone	;
	move.l	playerxa(pc),d0
	add.l	d0,playerx
	and	#255,playerx
	;
	move	joyy(pc),d0
	add	d0,playery
	cmp	#1,playery
	blt.s	.yf
	cmp	#34,playery
	blt.s	.ydone
	move	#34,playery
	bra.s	.ydone
.yf	move	#1,playery
.ydone	;
	move	joyb(pc),d0
	beq	.nofire
	move	deflbut(pc),d0
	bne	.rts
	st	deflbut
	;
	addfirst	defobjects
	beq.s	.rts
	move.l	#$20000,d0	;bullet speed!
	move	playershape(pc),d1
	beq.s	.rite
	neg.l	d0
.rite	add.l	playerxa(pc),d0
	move.l	d0,de_xa(a0)
	move	playerx(pc),de_x(a0)
	move	playery(pc),de_y(a0)
	addq	#1,de_y(a0)
	move	playershape(pc),d0
	addq	#2,d0
	move	d0,de_shape(a0)
	move	#2,de_colltype(a0)
	move.l	#defbull,de_logic(a0)
	move	#12,de_delay(a0)
	move.l	shootsfx3(pc),a0
	moveq	#32,d0
	moveq	#0,d1
	jmp	playsfx	; v190ex: GenAm range-safe tail jump
	;
.nofire	clr	deflbut
.rts	rts

deffrag	add.l	#$1000,de_ya(a5)
	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	cmp	#36,de_y(a5)
	bge	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	rts

impfrag	subq	#1,de_delay(a5)
	ble	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	rts

blowuplander	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	jsr	playsfx
	subq	#1,landerstokill
	moveq	#7,d7	;8 pixel exp
.loop2	addlast	defobjects
	beq	killdefobject
	move	de_x(a5),de_x(a0)
	move	de_y(a5),de_y(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_xa(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_ya(a0)
	move	d7,d0
	and	#1,d0
	addq	#5,d0
	move	d0,de_shape(a0)
	move.l	#deffrag,de_logic(a0)
	move	#15,de_delay(a0)
	clr	de_colltype(a0)
	dbf	d7,.loop2
	bra	killdefobject

blowupplayer	moveq	#3,d7
	;
.loop	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	jsr	playsfx
	dbf	d7,.loop
	;
	moveq	#31,d7
.loop2	addlast	defobjects
	beq	.rts
	move	playerx(pc),de_x(a0)
	move	playery(pc),de_y(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_xa(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_ya(a0)
	move	d7,d0
	and	#1,d0
	addq	#7,d0
	move	d0,de_shape(a0)
	move.l	#deffrag,de_logic(a0)
	move	#15,de_delay(a0)
	clr	de_colltype(a0)
	dbf	d7,.loop2
.rts	move	#-1,playershape
	subq	#1,playerlives
	rts

landerwait	subq	#1,de_delay(a5)
	ble.s	.skip
	rts
.skip	move.l	#landerlogic,de_logic(a5)
	move	#4,de_shape(a5)
landerlogic	;
	move	playershape(pc),d0
	bmi	.done
	;
	move	de_x(a5),d0
	move	d0,d2
	move	de_y(a5),d1
	move	d1,d3
	;
	sub	playerx(pc),d0
	bpl.s	.skipn1
	neg	d0
.skipn1	cmp	#6,d0
	bcc.s	.chk
	sub	playery(pc),d1
	bpl.s	.skipn2
	neg	d1
.skipn2	cmp	#4,d1
	bcs	blowupplayer
	;
	;check if shot!
.chk	lea	defobjects(pc),a0
.loop	move.l	(a0),a0
	tst.l	(a0)
	beq	.done
	move	de_colltype(a0),d0
	beq.s	.loop
	;
	move	d2,d0
	sub	de_x(a0),d0
	bpl.s	.skip
	neg	d0
.skip	cmp	#6,d0
	bcc.s	.loop
	;
	move	d3,d1
	sub	de_y(a0),d1
	bpl.s	.skip2
	neg	d1
.skip2	cmp	#4,d1
	bcc.s	.loop
	;
	;BOOM!
	;
	bra	blowuplander
.done	;
	move	de_x(a5),d0
	sub	playerx(pc),d0
	and	#255,d0
	cmp	#128,d0
	bcs.s	.left
	;
	;go right-ish!
	;
	add.l	#$4000,de_xa(a5)
	cmp.l	#$10000,de_xa(a5)
	ble.s	.xdone
	move.l	#$10000,de_xa(a5)
	bra.s	.xdone
	;
.left	sub.l	#$4000,de_xa(a5)
	cmp.l	#-$10000,de_xa(a5)
	bge.s	.xdone
	move.l	#-$10000,de_xa(a5)
	;
.xdone	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	;
	move	de_y(a5),d0
	sub	playery(pc),d0
	bpl.s	.up
	;
	;down
	;
	add.l	#$2000,de_ya(a5)
	cmp.l	#$8000,de_ya(a5)
	ble.s	.ydone
	move.l	#$8000,de_ya(a5)
	bra.s	.ydone
	;
.up	sub.l	#$2000,de_ya(a5)
	cmp.l	#-$8000,de_ya(a5)
	bge.s	.ydone
	move.l	#-$8000,de_ya(a5)
	;
.ydone	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	;
	rts

defbull	subq	#1,de_delay(a5)
	ble.s	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	rts

killdefobject	move.l	a5,a0
	killitem	defobjects
	move.l	a0,a5
	move.l	defstack(pc),a7
	bra	def_loop

initnewdef	move	landerdelay(pc),landercnt
	move	landerstokill(pc),landerstoadd
	clearlist	defobjects
	clr.l	playerx
	clr.l	playerxa
	clr	playershape
	move	#18,playery
	rts

defender	;defender game!
	;
	move.l	a5,-(a7)
	;
	move	landerstoadd(pc),d0
	beq	.nolander
	subq	#1,landercnt
	bgt	.nolander
	;
	;add a lander!
	;
	addlast	defobjects
	beq	.nolander
	subq	#1,landerstoadd
	move	landerdelay(pc),landercnt
	;
	bsr	rndw
	and	#255,d0
	move	d0,d2
	move	d0,de_x(a0)
	moveq	#32,d0
	bsr	rndn
	move	d0,d3
	move	d0,de_y(a0)
	move	#5,de_shape(a0)
	clr.l	de_xa(a0)
	clr.l	de_ya(a0)
	move.l	#landerwait,de_logic(a0)
	move	#32,de_delay(a0)
	clr	de_colltype(a0)
	;
	;OK, now add lander fragments!
	;
	moveq	#7,d7
	;
.frloop	addlast	defobjects
	beq.s	.nolander
	;
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0	;xadd
	move.l	d0,d4
	move.l	d0,de_xa(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,d5
	move.l	d0,de_ya(a0)
	;
	neg.l	d4
	lsl.l	#5,d4
	swap	d4
	add	d2,d4
	and	#255,d4
	move	d4,de_x(a0)
	neg.l	d5
	lsl.l	#5,d5
	swap	d5
	add	d3,d5
	move	d5,de_y(a0)
	;
	move	d7,d0
	and	#1,d0
	addq	#5,d0
	move	d0,de_shape(a0)
	move.l	#impfrag,de_logic(a0)
	move	#32,de_delay(a0)
	clr	de_colltype(a0)
	dbf	d7,.frloop
	;
.nolander	move	playershape(pc),d0
	bmi.s	.dead
	bsr	movedefplayer
.dead	;
	move	playerx(pc),d0
	sub	#22,d0
	bsr	drawmounts
	;
	;OK, scanner time!
	;
	moveq	#5,d0
	moveq	#3,d1
	moveq	#12,d2
	bsr	drawsprite
	moveq	#39,d0
	moveq	#3,d1
	moveq	#13,d2
	bsr	drawsprite
	move	playery(pc),d1
	lsr	#3,d1
	addq	#1,d1
	moveq	#22,d0
	moveq	#7,d2
	bsr	drawsprite
	;
	lea	defobjects(pc),a5
.scanloop	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.scandone
	cmp	#4,de_shape(a5)
	bne.s	.scanloop
	move	de_x(a5),d0
	sub	playerx(pc),d0
	lsr	#3,d0
	move	de_y(a5),d1
	lsr	#3,d1
	add	#16,d0
	and	#31,d0
	addq	#6,d0
	addq	#1,d1
	moveq	#5,d2
	bsr	drawsprite
	bra.s	.scanloop
.scandone	;	
	move.l	a7,defstack
	lea	defobjects(pc),a5
	;
def_loop	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.done
	;
	move.l	de_logic(a5),a0
	jsr	(a0)
	;
	move	de_x(a5),d0
	sub	playerx(pc),d0
	and	#255,d0
	cmp	#128,d0
	bcs.s	.nob
	or	#$ff00,d0
.nob	add	#22,d0
	move	de_y(a5),d1
	move	de_shape(a5),d2
	bsr	drawsprite
	;
	bra.s	def_loop
.done	;
	move	playershape(pc),d0
	bmi.s	.dead
	;
	move	landerstokill(pc),d0
	bgt.s	.bye2
	subq	#1,landerstokill
	subq	#1,d0
	and	#$10,d0
	beq.s	.bye2
	moveq	#22,d0
	moveq	#18,d1
	moveq	#11,d2
	bsr	drawsprite
.bye2	;
	moveq	#22,d0
	move	playery(pc),d1
	move	playershape(pc),d2
	bsr	drawsprite
	bra.s	.bye
	;
.dead	subq	#1,playershape
	cmp	#-96,playershape
	bcc.s	.no
	move	playerlives(pc),d3
	beq.s	.gameover
	;
	bsr	initnewdef
	bra.s	.bye
	;
.no	move	playerlives(pc),d3
	bne.s	.showlives
.gameover	and	#$10,d2
	beq.s	.exit
	moveq	#22,d0
	moveq	#18,d1
	moveq	#10,d2
	bsr	drawsprite
	bra.s	.exit
	;
.bye	move	playerlives(pc),d3
	beq.s	.exit
.showlives	subq	#1,d3
	moveq	#1,d1
	;
.lives	moveq	#2,d0
	moveq	#9,d2
	movem	d1/d3,-(a7)
	bsr	drawsprite
	movem	(a7)+,d1/d3
	addq	#2,d1
	dbf	d3,.lives
	;
.exit	move.l	(a7)+,a5
	rts

drawsprite	;d0=x, d1=y, d2=shape
	;
	exg	d0,d2
	move	d1,d3
	lea	defshapes(pc),a0
	movem	0(a0,d0*8),d0-d1/d4-d5
	;
	;d0=src x, d1=src y, d2=dest x,d3=dest y,d4=w, d5=h
	;
	sub	#64,d0
	movem.l	deftxt(pc),a0-a1
	add	d0,d1
	lsl	#6,d0
	add	d0,d1
	add	d1,a1
	;
	;handles...
	move	d4,d0
	lsr	#1,d0
	sub	d0,d2
	move	d5,d1
	lsr	#1,d1
	sub	d1,d3
	;
	tst	d2
	bmi.s	.xmi
	move	d2,d0
	add	d4,d0
	sub	#44,d0
	ble.s	.xok
	sub	d0,d4
	bgt.s	.xok
.xrts	rts
.xmi	add	d2,d4	;reduce width
	ble.s	.xrts
	move	d2,d0
	lsl	#6,d2
	add	d0,d2
	sub	d2,a1
	bra.s	.xdone
.xok	move	d2,d0
	lsl	#6,d2
	add	d0,d2
	add	d2,a0
.xdone	;
	tst	d3
	bmi.s	.ymi
	move	d3,d0
	add	d5,d0
	sub	#36,d0
	ble.s	.yok
	sub	d0,d5
	bgt.s	.yok
.yrts	rts
.ymi	add	d3,d5	;reduce width
	ble.s	.yrts
	sub	d3,a1
	bra.s	.ydone
.yok	add	d3,a0
.ydone	;
	moveq	#65,d7
	sub	d5,d7
	subq	#1,d4	;w
	subq	#1,d5	;h
.loop	move	d5,d6
.loop2	move.b	(a1)+,d0
	beq.s	.col0
	move.b	d0,(a0)
.col0	addq	#1,a0
	dbf	d6,.loop2
	add.l	d7,a0
	add.l	d7,a1
	dbf	d4,.loop
	;
	rts

drawmounts	;d0=offset
	;
	;parallax top 25, bottom 11
	;
	move	d0,d2
	lsr	#1,d0
	;
	and	#63,d0
	movem.l	deftxt(pc),a0-a1
	move	d0,d1
	lsl	#6,d1
	add	d0,d1	;* 65
	add	d1,a1
	;
	;OK, draw mountains at d0
	;
	moveq	#65-25,d7
	move.l	#64*65,d6
	moveq	#43,d1	;w
	;
.loop	move.b	(a1)+,(a0)+	;to even address - 1
	move	(a1)+,(a0)+	;to long address - 3
	move.l	(a1)+,(a0)+	;7
	move.l	(a1)+,(a0)+	;11
	move.l	(a1)+,(a0)+	;15
	move.l	(a1)+,(a0)+	;19
	move.l	(a1)+,(a0)+	;23
	move	(a1)+,(a0)+	;25!
	;
	add.l	d7,a0
	add.l	d7,a1
	addq	#1,d0
	and	#63,d0
	bne.s	.skip
	sub.l	d6,a1
.skip	dbf	d1,.loop
	;
	move	d2,d0
	and	#63,d0
	;
	movem.l	deftxt(pc),a0-a1
	move	d0,d1
	lsl	#6,d1
	add	d0,d1	;* 65
	add	d1,a1
	lea	25(a0),a0	;bottom 25!
	lea	25(a1),a1
	;
	;OK, draw mountains at d0
	;
	moveq	#65-11,d7
	moveq	#43,d1	;w
	;
.loop2	move	(a1)+,(a0)+	;2
	move.l	(a1)+,(a0)+	;6
	move.l	(a1)+,(a0)+	;10
	move.b	(a1)+,(a0)+	;11
	;
	add.l	d7,a0
	add.l	d7,a1
	addq	#1,d0
	and	#63,d0
	bne.s	.skip2
	sub.l	d6,a1
.skip2	dbf	d1,.loop2
	;
	rts

chatmap	dc.l	0
chatxout	dc	0
chatxin	dc	0

chatontxt	dc.b	'CHAT MODE ENABLED',0
	even

chatcls	move.l	chatmap,a0
	moveq	#0,d0
	move	#20*2*5-1,d1
.loop	move.l	d0,(a0)+
	dbf	d1,.loop
	clr.l	chatxout
	rts

chaton	;enable chat mode!
	;
	tst	linked
	beq	.rts
	tst	chatok
	bne	.rts
	;
	bsr	chatcls
	lea	chatontxt(pc),a2
.loop	move.b	(a2)+,d0
	beq.s	.done
	moveq	#3,d1
	bsr	chatprintout
	bra.s	.loop
.done	clr	chatoutput
	clr	chatoutget
	clr	chatinput
	clr	chatinget
	st	chatok
	;
.rts	rts

chatoff	;disable chat mode
	;
	tst	linked
	beq.s	chatoffrts
	tst	chatok
	beq.s	chatoffrts
	;
dochatoff	sf	chatok
	bsr	chatcls
	;
chatoffrts	rts

chatscrollin	;scroll chatin window across a byte.
	;
	move	d2,-(a7)
	move.l	chatmap,a0
	lea	40(a0),a0
	bra.s	chatsc
	
chatscrollout	;scroll chatout window across a byte.
	;
	move	d2,-(a7)
	move.l	chatmap,a0
chatsc	moveq	#4,d0	;5 lines to scroll
.loop3	moveq	#1,d1	;2 bitpanes
.loop2	moveq	#38,d2	;39 chars to move...
.loop	move.b	1(a0),(a0)+
	dbf	d2,.loop
	clr.b	(a0)+
	lea	40(a0),a0
	dbf	d1,.loop2
	dbf	d0,.loop3
	move	(a7)+,d2
	rts

chatspcout	cmp	#40,chatxout
	bcc.s	chatscrollout
	addq	#1,chatxout
	rts

calcchar	ext	d0
	cmp	#'A',d0
	bcs.s	.notal
	and	#31,d0
	add	#9,d0
	rts
.notal	cmp	#'.',d0
	bne.s	.not1
	moveq	#36,d0
	rts
.not1	cmp	#'!',d0
	bne.s	.not2
	moveq	#37,d0
	rts
.not2	cmp	#'?',d0
	bne.s	.not3
	moveq	#38,d0
	rts
.not3	cmp	#',',d0
	bne.s	.not4
	moveq	#39,d0
	rts
.not4	sub	#48,d0
	rts

chatprintout	;d0.b=chr$() to print, d1=colour (1,2,3)
	;
	cmp.b	#32,d0
	beq.s	chatspcout
	bsr	calcchar
	;
	movem.l	d2/a2,-(a7)
	;
	cmp	#40,chatxout
	bcs.s	.nosc
	;
	movem	d0-d1,-(a7)
	bsr	chatscrollout
	movem	(a7)+,d0-d1
	subq	#1,chatxout
.nosc	;
	lea	chatfont,a0
	ext	d0
	add	d0,a0
	move.l	chatmap,a1	;bp1
	add	chatxout(pc),a1
	addq	#1,chatxout
	cmp	#1,d1
	beq.s	.skip
	lea	80(a1),a2
	cmp	#2,d1
	beq.s	.skip2
	move.l	a2,a1
.skip	move.l	a1,a2
.skip2	moveq	#4,d0	;5 lines
.loop	move.b	(a0),(a1)
	move.b	(a0),(a2)
	lea	40(a0),a0
	lea	160(a1),a1
	lea	160(a2),a2
	dbf	d0,.loop
	;
	movem.l	(a7)+,d2/a2
	rts

chatspcin	cmp	#40,chatxin
	bcc	chatscrollin
	addq	#1,chatxin
	rts

chatprintinhex	move	d0,-(a7)
	lsr	#4,d0
	bsr	.skip
	move	(a7)+,d0
	;
.skip	and	#15,d0
	add	#48,d0
	cmp	#58,d0
	bcs.s	chatprintin
	addq	#7,d0
	;
chatprintin	;d0.b=chr$() to print, d1=colour (1,2,3)
	;
	cmp.b	#32,d0
	beq.s	chatspcin
	bsr	calcchar
	;
	movem.l	d2/a2,-(a7)
	;
	cmp	#40,chatxin
	bcs.s	.nosc
	;
	movem	d0-d1,-(a7)
	bsr	chatscrollin
	movem	(a7)+,d0-d1
	subq	#1,chatxin
.nosc	;
	lea	chatfont,a0
	ext	d0
	add	d0,a0
	move.l	chatmap,a1	;bp1
	add	chatxin(pc),a1
	lea	40(a1),a1
	addq	#1,chatxin
	cmp	#1,d1
	beq.s	.skip
	lea	80(a1),a2
	cmp	#2,d1
	beq.s	.skip2
	move.l	a2,a1
.skip	move.l	a1,a2
.skip2	moveq	#4,d0	;5 lines
.loop	move.b	(a0),(a1)
	move.b	(a0),(a2)
	lea	40(a0),a0
	lea	160(a1),a1
	lea	160(a2),a2
	dbf	d0,.loop
	;
	movem.l	(a7)+,d2/a2
	rts

;-------------- serial stuff -------------------;

sblen	equ	128	;serial buffer length

initser	push
	;
	clr	rget
	clr	rput
	clr	rbfcnt
	clr	chatcnt
	;
	move.l	4.w,a6
	moveq	#11,d0
	lea	rbfintserver(pc),a1
	jsr	-162(a6)
	;
	move	#$0801,$dff09c
	move	#$0001,$dff09a	;no tbe int.
	move	#$8800,$dff09a	;rbf int only
	;
	pull
	rts

finitser	push
	;
	move	#$0801,$dff09a
	move	#$0801,$dff09c
	;
	move.l	4.w,a6
	moveq	#11,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	pull
	rts

serput	;send byte in d0
	;
;.wait	btst	#4,$dff018
;	beq.s	.wait
	;
	move	#1,$dff09c
	;
	and	#$ff,d0
	or	#$100,d0
	move	d0,$dff030
	;
.wait	btst	#0,$dff01f
	beq.s	.wait
	move	#1,$dff09c
	;
	rts

rbfchk	;return ne if something there!
	;
	move	rbfcnt(pc),d0
	rts

serwait	bsr	rbfchk
	beq.s	serwait
	;
serget	lea	rbuff(pc),a0
	move	rget(pc),d0
	and	#sblen-1,d0
	move.b	0(a0,d0),d0
	addq	#1,rget
	subq	#1,rbfcnt
	;
	rts

chatcnt	dc	0
rbfcnt	dc	0

rbf	;receive buffer full interupt
	;
	;a1=rbuff
	;
	movem.l	d0-d1/a0-a1,-(a7)
	;
	move	$dff018,d0	;ser byte
	bmi	.fuck
	move	#$800,$dff09c
	;
	move	chatok(pc),d1
	beq.s	.chskip
	bclr	#6,d0
	beq.s	.chskip
	add.b	#32,d0
	;
	lea	chatin,a1
	move	chatinput,d1
	and	#31,d1
	move.b	d0,0(a1,d1)
	addq	#1,chatinput
	addq	#1,chatcnt
	bra.s	.bye
	;
.chskip	lea	rbuff(pc),a1
	move	rput(pc),d1
	and	#sblen-1,d1
	move.b	d0,0(a1,d1)
	addq	#1,rput
	addq	#1,rbfcnt
	;
.bye	movem.l	(a7)+,d0-d1/a0-a1
	rts
	;
.fuck	warn	#$f00	;ser overflow error!
	warn	#$fff
	bra.s	.fuck

rbuff	ds.b	sblen
rput	dc	0
rget	dc	0

medat	dc.l	0
titlemed	dc.l	0
loadingmed	dc.l	0
fadevol	dc	0	;non-zero=fade to 0!

relocate	;a0=pointer to what to relocate
	;
	bsr	flushc
	;
	move.l	(a0),d0
	beq	.rts
	move.l	d0,a1
	add.l	#32,(a0)
	lea	28(a1),a0
	move.l	(a0)+,d0
	lea	0(a0,d0.l*4),a1
	cmp.l	#$3ec,(a1)+
	bne.s	.rts
	move.l	(a1)+,d0
	addq	#4,a1
	move.l	a0,d2
	;
.loop	move.l	(a1)+,d1	;offset
	add.l	d2,0(a0,d1)
	subq.l	#1,d0
	bne.s	.loop
	;
.rts	bsr	flushc
	;
	rts

initmed	lea	medat,a0
	tst.l	(a0)
	bne.s	.noreloc
	;
	move.l	#medplayer,(a0)
	bsr	relocate
	;
.noreloc	move.l	medat,a1
	move.l	chipzero(pc),a0
	jsr	(a1)
	;
	move.l	titlemed(pc),d0	; v190cp: some compatible installs have no title MED
	beq.s	.g2v190cp_no_titlemed
	move.l	d0,a0
	move.l	medat,a1
	jsr	4(a1)
.g2v190cp_no_titlemed
	;
	move.l	loadingmed(pc),d0
	beq.s	.no
	move.l	d0,a0
	move.l	medat,a1
	jsr	4(a1)
.no	;
	rts

agafiles	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	; v144: original overlay file is pics/gloom, not pics/gloombrush.
	; If it is absent, loadfile leaves gloombrush=0 and the safe overlay skips it.
	dc.b	'pics/gloom',0
	even
	dc.l	planar_palette
	dc.b	'misc/palette_8',0
	even
	dc.l	planar_remap
	dc.b	'misc/remap_8',0
	even
	dc.l	0

ecsfiles	dc.l	gloom
	dc.b	'pics_ehb/title',0
	even
	dc.l	gloompal
	dc.b	'pics_ehb/title.pal',0
	even
	dc.l	planar_palette
	dc.b	'misc/palette_6',0
	even
	dc.l	planar_remap
	dc.b	'misc/remap_6',0
	even
	dc.l	0

progfiles	dc.l	gloomcfg
	dc.b	'gloomcfg',0
	even
	dc.l	bigfont_+1
	dc.b	'misc/bigfont2.bin',0
	even
	dc.l	panel
	dc.b	'misc/smallfont2.bin',0
	even
	dc.l	gunpic
	dc.b	'misc/gun.bin',0	;v61 optional first-person gun
	even
	dc.l	titlemed+1
	dc.b	'sfxs/med1',0
	even
	dc.l	loadingmed+1
	dc.b	'sfxs/med2',0
	even
	dc.l	shootsfx+1
	dc.b	'sfxs/shoot.bin',0
	even
	dc.l	shootsfx2+1
	dc.b	'sfxs/shoot2.bin',0
	even
	dc.l	shootsfx3+1
	dc.b	'sfxs/shoot3.bin',0
	even
	dc.l	shootsfx4+1
	dc.b	'sfxs/shoot4.bin',0
	even
	dc.l	shootsfx5+1
	dc.b	'sfxs/shoot5.bin',0
	even
	dc.l	gruntsfx+1
	dc.b	'sfxs/grunt.bin',0
	even
	dc.l	gruntsfx2+1
	dc.b	'sfxs/grunt2.bin',0
	even
	dc.l	gruntsfx3+1
	dc.b	'sfxs/grunt3.bin',0
	even
	dc.l	gruntsfx4+1
	dc.b	'sfxs/grunt4.bin',0
	even
	dc.l	tokensfx+1
	dc.b	'sfxs/token.bin',0
	even
	dc.l	doorsfx+1
	dc.b	'sfxs/door.bin',0
	even
	dc.l	footstepsfx+1
	dc.b	'sfxs/footstep.bin',0
	even
	dc.l	diesfx+1
	dc.b	'sfxs/die.bin',0
	even
	dc.l	splatsfx+1
	dc.b	'sfxs/splat.bin',0
	even
	dc.l	telesfx+1
	dc.b	'sfxs/teleport.bin',0
	even
	dc.l	ghoulsfx+1
	dc.b	'sfxs/ghoul.bin',0
	even
	dc.l	lizsfx+1
	dc.b	'sfxs/lizard.bin',0
	even
	dc.l	lizhitsfx+1
	dc.b	'sfxs/lizhit.bin',0
	even
	dc.l	trollsfx+1
	dc.b	'sfxs/trollmad.bin',0
	even
	dc.l	trollhitsfx+1
	dc.b	'sfxs/trollhit.bin',0
	even
	dc.l	robotsfx+1
	dc.b	'sfxs/robot.bin',0
	even
	dc.l	robodiesfx+1
	dc.b	'sfxs/robodie.bin',0
	even
	dc.l	dragonsfx+1
	dc.b	'sfxs/dragon.bin',0
	even
	dc.l	0

datafiles	dc.l	script
scriptname	dc.b	'misc/script',0
	even
	;
	ifeq	cd32
	dc.l	gloomgame
gamename	dc.b	'gloomgame',0
	even
	endc
	;
	dc.l	0

loadfiles	;
	push
	move.l	a0,a2
	;
.loop	move.l	(a2)+,d0
	beq.s	.done
	moveq	#1,d1
	bclr	#0,d0
	beq.s	.nochip
	moveq	#2,d1
.nochip	move.l	d0,a3
	move.l	a2,a0
	bsr	loadfile
	move.l	d0,(a3)
.z	tst.b	(a2)+
	bne.s	.z
	exg	a2,d0
	addq.l	#1,d0
	bclr	#0,d0
	exg	a2,d0
	bra.s	.loop
	;
.done	pull
	rts

diskmenu	dc.b	1
	dc.b	'please insert gloom data disk',0
	even

magicfiles	dc.l	magic
	dc.b	'pics/blackmagic',0
	even
	dc.l	0

agamagicfiles	dc.l	magicpal
	dc.b	'pics/blackmagic.pal',0
	even
	dc.l	0

ecsmagicfiles	dc.l	magicpal
	dc.b	'pics_ehb/blackmagic.pal',0
	even
	dc.l	0

initmain	;
	;calc stuff from aga/os settings
	;
	moveq	#8,d0	;bitplanes
	move	#256,d1	;colours
	move.l	#320,d2	;linemod
	move.l	#40,d3	;bpmod
	lea	db_aga,a0
	lea	pokepal_aga,a1
	tst	aga
	bne.s	.aga1
	moveq	#6,d0
	moveq	#32,d1
	move.l	#240,d2
	lea	db_ecs,a0
	lea	pokepal_ecs,a1
.aga1	tst	os
	beq.s	.os1
	moveq	#40,d2	;linemod
	move.l	#40*240,d3	;bpmod ;v16: restore compact 240-line plane span
	lea	db_os,a0
	lea	pokepal_os,a1
.os1	;
	move	d0,bitplanes
	move	d1,colours
	move.l	d2,linemod
	move.l	d3,bpmod
	move.l	a0,todb
	move.l	a1,topokepal
	;
	move.l	4.w,a6
	move.l	276(a6),a0
	move.l	#-1,184(a0)	;requesters OFF for our task.
	;
	bsr	initrawmap	;init keyboard reader
	lea	ciaaname,a1
	jsr	-498(a6)
	move.l	d0,ciaa
	;
	tst	os
	beq.s	.osskipz
	move.l	#12*257,d0
	moveq	#1,d1
	allocmem	temppal
	move.l	d0,temppal
.osskipz	;
	move.l	#128,d0	;v38: enough chip RAM for a full blank 16x16 Intuition pointer
	move.l	#$10002,d1
	allocmem	chipzero
	move.l	d0,chipzero
	;
	move.l	#256,d0
	moveq	#1,d1
	allocmem	maptable
	move.l	d0,maptable
	;
	move.l	#32768,d0
	moveq	#1,d1
	allocmem	memory
	move.l	d0,memory
	;
	move.l	#320*vd_size,d0
	moveq	#1,d1
	allocmem	vertdraws
	move.l	d0,vertdraws
	;
	move.l	#maxz*2,d0
	moveq	#1,d1
	allocmem	darktable
	move.l	d0,darktable
	;
	move.l	#320*240,d0
	moveq	#1,d1
	allocmem	chunky
	move.l	d0,chunky	;chunky buffer
	;
	move.l	#256*16,d0
	moveq	#1,d1
	allocmem	palettes
	;
	;16 shades...
	lea	palettes(pc),a0
	moveq	#15,d1
.p_loop	move.l	d0,(a0)+
	add.l	#256,d0
	dbf	d1,.p_loop
	;
	move.l	#map_rgbs_,map_rgbs
	;
	st	paused
	clr	dispnest
	clr.l	font
	jsr	initsfx
	bsr	initvbint
	bsr	initdisplay
	;
	jsr	g2detectprofile	;v190cj: select Gloom/Gloom3/ZM data layout
	move.l	g2magicfiles_ptr,a0
	bsr	loadfiles
	move.l	g2agamagicfiles_ptr,a0
	tst	aga
	bne.s	.agaa
	move.l	g2ecsmagicfiles_ptr,a0
.agaa	bsr	loadfiles
	;
	move.l	magic,a0
	move.l	magicpal,a1
	jsr	showpic
	bsr	dispon
	;
	; v41h diagnostic: BlackMagic/showpic passed; continue to file-load stage.
	move	#50,vbcounter
	;
	move.l	g2progfiles_ptr,a0
	bsr	loadfiles
	move.l	g2agafiles_ptr,a0
	tst	aga
	bne.s	.lf
	move.l	g2ecsfiles_ptr,a0
.lf	bsr	loadfiles
	jsr	g2embed_apply_g1_fallbacks	;v190gl: missing Classic-Gloom modern assets
	jsr	g2loadgunfallback	;v61: optional misc/stuf gun.bin fallback
	jsr	g2embed_apply_g1_fallbacks	;v190gl: gun fallback if no file exists
	jsr	g2embed_apply_zm_title_overlay	;v190hu: embedded Zombie Massacre title overlay
	;
	; v41i diagnostic: progfiles/agafiles loaded OK.
	; Continue into gloomcfg/C2P filename + C2P load stage.
	;
		;load in c2p routine
		;
		; v13: use the known original path directly.  If the external
		; c2p/blackmagic_1 can not be opened for any reason, fall back
		; to the built-in blackmagic_1-compatible converter below.
		; This avoids the old bogus low-address c2p pointer and lets the
		; gameplay renderer continue even when the external helper is not
		; found from the current directory.
		;
		move.l	#g2v13_c2pname,a0
		moveq	#1,d1
		bsr	loadfile
		move.l	d0,planar_c2p
		;
		move.l	planar_c2p(pc),a2
		tst.l	a2
		bne.s	.g2v13_external_c2p
		tst	aga
		bne.s	.g2v13_internal_aga
		move.l	#g2v13_doc2p_1X1X6,a0
		bra.s	.g2v13_c2p_set
.g2v13_internal_aga
		move.l	#g2v13_doc2p_1X1X8,a0
		bra.s	.g2v13_c2p_set
.g2v13_external_c2p
		lea	36(a2),a0
		tst	aga
		bne.s	.g2v13_c2p_set
		lea	40(a2),a0
.g2v13_c2p_set
		move.l	a0,c2p
		;
	; v41j diagnostic: C2P file loaded and pointer set.
	; Continue into C2P inittables, then hold immediately after it returns.
	;
	lea	coloffs,a0	;columns table
	move	#320,d0	;320 columns
	lea	paladjust,a1
	;
	; v41l diagnostic: bypass external C2P inittables.
	; The external loaded C2P binary is still kept for doc2p later,
	; but its init-table entry at 32(a2) is not executed here.
	; This tells us whether the Guru sits in the external inittables call.
	jsr	g2_inline_c2p_init
	bra.w	g2_after_inline_c2p_init
	;
g2v08_dummy_c2p	;safe fallback if external c2p file did not load
	rts
	;
g2_inline_c2p_init	;blackmagic_1-compatible initc2p table builder
		;in: a0=coloffs, d0=columns, a1=paladjust
		move	#$ff,d1
.g2pal		move.b	d1,0(a1,d1)
		dbf	d1,.g2pal
		;
		lsr	#4,d0
		subq	#1,d0
		moveq	#0,d1
.g2col1		moveq	#7,d2
.g2col2		move.l	d1,(a0)+
		addq.l	#2,d1
		dbf	d2,.g2col2
		sub.l	#15,d1
		moveq	#7,d2
.g2col3		move.l	d1,(a0)+
		addq.l	#2,d1
		dbf	d2,.g2col3
		subq.l	#1,d1
		dbf	d0,.g2col1
		rts
	;
g2_after_inline_c2p_init
	bsr	initmed
	bsr	initser
	bsr	calcbaud
	bsr	initdarktable
	;
	; v41p diagnostic: C2P table init + med/serial/darktable init returned.
	; Continue into remapanim/remap table work, then hold after it.
	;
	tst.l	remapped
	bne.w	g2v62_noremap
	move.l	#-1,remapped
	;
	move.l	map_rgbs(pc),a0
	move	#-1,(a0)+
	move.l	a0,map_rgbsat
	;
	; v46: restore original panel remap path. Final CrM2 smallfont2.bin
	; is an anim file and must be remapped into the active game palette
	; before drawchunky uses palettes(pc).
	; v190gl: profile 1 now has physical/embedded smallfont2-compatible panel data.
	move.l	panel,d0
	beq.s	.g2v190cj_no_panel_remap
	move.l	d0,a0
	jsr	remapanim
.g2v190cj_no_panel_remap
	move.l	gunpic(pc),d0	;v61: gun.bin has its own palette
	beq.s	g2v61_no_gun_remap
	move.l	d0,a0
	jsr	g2gun_prepare
	move.l	gunpic(pc),a0
	jsr	remapanim
g2v61_no_gun_remap
	lea	bullet1,a0
	jsr	remapanim
	lea	bullet2,a0
	jsr	remapanim
	lea	bullet3,a0
	jsr	remapanim
	lea	bullet4,a0
	jsr	remapanim
	lea	bullet5,a0
	jsr	remapanim
	lea	sparks1,a0
	jsr	remapanim
	lea	sparks2,a0
	jsr	remapanim
	lea	sparks3,a0
	jsr	remapanim
	lea	sparks4,a0
	jsr	remapanim
	lea	sparks5,a0
	jsr	remapanim
	;
	move.l	map_rgbsat(pc),map_rgbsat2
g2v62_noremap	;
	move.l	map_rgbsat2(pc),map_rgbsat
	;
	; v41q diagnostic: remapanim/remap block returned.
	; Continue into initial object/anim loads, then hold after them.
	;
	moveq	#0,d0
	bsr	loadanobj	;load player1
	moveq	#1,d0
	bsr	loadanobj	;load player2
	moveq	#2,d0
	bsr	loadanobj	;load tokens (health)
	;
	; v41s diagnostic: player1/player2/token object loads returned.
	; Continue into map_rgb setup and alloclist block, then hold after it.
	;
	move.l	map_rgbsat(pc),map_rgbsfrom
	move.l	map_rgbsat(pc),map_rgbsfrom2
	;
	alloclist	objects,#maxobjects,#ob_size
	alloclist	doors,#maxdoors,#do_size
	alloclist	blood,#maxblood,#bl_size
	alloclist	gore,#maxgore,#go_size
	alloclist	rotpolys,#maxrotpolys,#rp_size
	alloclist	defobjects,#maxdefobjects,#de_size
	;
.w5sex	tst	vbcounter
	bgt	.w5sex
	;
	; v41t diagnostic: alloclist block returned.
	; Continue through display-off/free-magic/seed, then hold before forbid.
	;
	bsr	dispoff
	;
	move.l	magic,a1
	freemem	magic
	move.l	magicpal,a1
	freemem	magicpal
	;
	move	#$1234,d0
	bsr	seedrnd2
	;
	ifne	cd32
	lea	nvname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,nv
	bsr	loadgloomgame
	endc
	;
	; v41v diagnostic: allow initmain to return normally via forbid.
	bra	forbid

	ifeq	cd32

checkdatadisk	;return eq if gloomdata: found!
	;
	move.l	dosbase(pc),a0
	move.l	34(a0),a0
	move.l	24(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	addq	#4,a0
	;
.loop	move.l	(a0),d0
	beq.s	.done
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	40(a0),a1
	add.l	a1,a1
	add.l	a1,a1
	cmp.b	#9,(a1)+	;9 chars
	bne.s	.loop
	lea	lockname(pc),a2
	moveq	#8,d0	;check 9 chars!
.loop2	cmp.b	(a1)+,(a2)+
	bne.s	.loop
	dbf	d0,.loop2
	rts
	;
.done	moveq	#-1,d0
	rts

askdatadisk	;
	;make sure data disk is available...
	;
	;if 'gloomgame' is in CD, then use CD, else...
	;wait for 'gloomdata:' to get inserted!
	;
	bsr	permit
	move.l	g2dataprobe_name,d1	;v190cj: script/stages proves data is present
	move.l	#1005,d2
	move.l	dosbase(pc),a6
	jsr	-30(a6)
	move.l	d0,d1
	beq.s	.nolock
	jsr	-36(a6)	;close it!
	bra	.load
	;
.nolock	bsr	forbid
	bsr	checkdatadisk
	beq	.dataok	;already there?
	;
	lea	diskmenu,a0
	bsr	qmenu
	;
	;OK, gotta swap disks and pick up data files!
	;
.wfd	bsr	permit
	move.l	grbase(pc),a6
	jsr	-270(a6)
	bsr	forbid
	bsr	checkdatadisk
	bne.s	.wfd
	;
	bsr	finitqmenu
	;
.dataok	bsr	permit
	bsr	undir	;release old lock!
	move.l	#lockname,d1
	moveq	#-2,d2
	move.l	dosbase(pc),a6
	jsr	-84(a6)	;lock?
	move.l	d0,d1
	beq.s	.wfd
	jsr	-126(a6)	;make current dir!
	move.l	d0,oldlock
	;
.load	move.l	g2datafiles_ptr,a0
	bsr	loadfiles
	jsr	g2ensure_gloomgame_fallback
	bra	forbid

undir	move.l	oldlock(pc),d1
	beq.s	.rts
	clr	gloomdata
	clr.l	oldlock
	move.l	dosbase(pc),a6
	jsr	-126(a6)	;CD to old current dir
	move.l	d0,d1
	jsr	-90(a6)	;unlock old (mine!)
.rts	rts

oldlock	dc.l	0

lockname	dc.b	'gloomdata:',0
	even

	endc

lagtext	dc.b	'lAG?',0
	even

syncup	;time to calculate frame lag!
	;
	;master can establish lag time...
	;
	move	linked(pc),d0
	bne.s	.li
.rts	rts
.li	;
	;bsr	qsync
	bsr	qsync2
	;
	moveq	#31,d5
	;
	tst	linked
	bmi	.slave
	;
	;MASTER - average out 32 sends of random data!
	;
	moveq	#0,d6	;sum
	;
.mloop	moveq	#0,d7
	bsr	vwait
	bsr	serput
	;
.mwait	addq	#1,d7
	bsr	vwait
	bsr	rbfchk
	beq.s	.mwait
	;
	bsr	serget
	add	d7,d6
	dbf	d5,.mloop
	;
	add	#64,d6
	lsr	#7,d6	;/32 = avg. /2=half, /2=25 FPS
	addq	#1,d6	;safety...
	;
	move	d6,d0
	move	d0,lagtime
	bsr	serput
	bra	initlag
	;
.slave	;OK, bounce back 32 items...
	;
	moveq	#31,d5
.sloop	bsr	serwait
	bsr	serput
	dbf	d5,.sloop
	;
	;now, wait to get told lagtime!
	;
	bsr	serwait
	and	#255,d0
	move	d0,lagtime
	;
initlag	;what to do...
	;
	;stick 'lagtime' dummy 'noevents' into rec buff!
	;stick 'lagtime' dummy 'noevents' into pcntrl buffer
	;
	move	#$4000,$dff09a
	;
	lea	pbuff(pc),a0	;controller buffer
	lea	rbuff(pc),a1	;ser rec. buffer
	moveq	#31,d1	;32*4=128 bytes!
	moveq	#0,d0
.loop	move.l	d0,(a0)+
	move.l	d0,(a1)+
	dbf	d1,.loop
	;
	move	lagtime(pc),d0
	;
	clr	pget
	clr	rget
	clr	chatcnt
	move	d0,pput
	;add	d0,d0
	move	d0,rbfcnt
	move	d0,rput
	;
	move	#$c000,$dff09a
	;
	rts

syncmenu	dc.b	1
	dc.b	'waiting for other player',0
	even

lagtime	dc	0

qsync	;OK, quick sync up!
	;
	move	linked(pc),d0
	beq.s	.rts
	;
.more	bsr	rbfchk	;anything there?
	beq.s	.no
	bsr	serget
	cmp.b	#$8f,d0
	bne.s	.more
	move.b	#$8f,d0
	bra	serput
	;
.no	lea	syncmenu,a0
	bsr	qmenu
	move.b	#$8f,d0
	bsr	serput
	;
.loop	bsr	serwait
	cmp.b	#$8f,d0
	bne.s	.loop
	;
	bra	finitqmenu
	;
.rts	rts

qsync2	;OK, quick sync up, but now 'waiting' menu
	;
	move	linked(pc),d0
	beq.s	.rts
	;
	move.b	#$8f,d0
	bsr	serput
	;
.loop	bsr	serwait
	cmp.b	#$8f,d0
	bne.s	.loop
	;
.rts	rts

g2v10_showmsg	; a0 = one-item menu/message, wait for fire and close
	jsr	qmenu
	jsr	selmenu
	jsr	finitqmenu
	rts

g2v10_datafail_initnewgame
	lea	g2v10_datafailmenu(pc),a0
	jsr	g2v10_showmsg
	move	#-1,gametype
	rts

g2v10_datafailmenu	dc.b	1
	dc.b	'G2 DATA LOAD FAILED',0
	even
g2v10_mapfailmenu	dc.b	1
	dc.b	'G2 MAP LOAD FAILED',0
	even
g2v10_playerfailmenu	dc.b	1
	dc.b	'G2 PLAYER1 MISSING',0
	even
g2v11_c2pfailmenu	dc.b	1
	dc.b	'G2 C2P MISSING',0
	even

combatnokmenu	dc.b	1
	dc.b	'sorry...not available in demo',0
	even

initnewgame	;
	ifeq	combatok
	;
	cmp	#2,gametype
	bne.s	.skipnok
	lea	combatnokmenu(pc),a0
	bsr	qmenu
	;
	bsr	selmenu
	;
	bsr	finitqmenu
	move	#-1,gametype
	rts
.skipnok	;
	endc
	;
	move	gametype(pc),twowins
	beq.s	.skip
	tst	linked
	beq.s	.skip
	clr	cheat
	;
	nop
	;
	ifeq	debugser
	clr	twowins
	endc
.skip	;
	tst.l	map_test
	bne.s	.skhit
	;
	tst	gloomdata
	bne.s	.gotdata
	move	#-1,gloomdata
.skhit	;
	ifne	cd32
	bsr	permit
	move.l	g2datafiles_ptr,a0
	bsr	loadfiles
	jsr	g2ensure_gloomgame_fallback
	bsr	forbid
	elseif
	bsr	askdatadisk
	jsr	g2ensure_gloomgame_fallback
	endc
.gotdata	;
	; v10: guard script/gloomgame before normalgame scans them.
	; If the data files were not loaded, the original code dereferenced
	; null pointers immediately after selecting New Game.
	tst.l	script
	beq	g2v10_datafail_initnewgame
	tst.l	gloomgame
	beq	g2v10_datafail_initnewgame
	bsr	qsync
	;
	move.l	medat,a1
	jsr	12(a1)
	cmp	#2,gametype
	bne	normalgame
	;
	;combat type game!
	;
	move	#6,p1_ob_collwith
	move	#5,p2_ob_collwith
	;
	lea	combatmenu,a0
	bsr	qmenu
	;
.loop	bsr	selmenu
	cmp	#3,d0
	bcs	.play
	bne.s	.loop
	;
	;change number of wins...
	;
	addq.b	#1,comnum
	cmp.b	#'9',comnum
	bls	.loop
	move.b	#'2',comnum
	bra	.loop
	;
.play	add	#49,d0
	move.b	d0,comseriesnum
	;
	bsr	finitqmenu
	move.b	comnum(pc),d0
	sub.b	#'0',d0
	ext	d0
	move	d0,p1lives
	move	d0,p2lives
	;
	lea	combatfiles(pc),a0
	bsr	permit
	bsr	loadfiles
	bra	forbid
normalgame	;
	;check for continue offsets in 'gloomgame' file!
	;
	tst	linked
	bge.s	.master
	;
	bsr	qsync
	bsr	longget
	add.l	script(pc),d0
	move.l	d0,scriptat
	bra	initpstuff
.master	;
	move.l	script(pc),scriptat	;default
	cmp	#1,g2_game_profile	; v190cw: original Gloom gloomgame/continue path is unsafe here
	beq	initpstuff
	move.l	g2v190i_start_offset(pc),d0	; v190s: START LEVEL keeps script initialisation active
	bmi.s	.g2v190r_no_levelselect
	bra	initpstuff		; run script from start, but skip play_ entries until selected level
.g2v190r_no_levelselect
	move.l	gloomgame(pc),a0
	lea	conttxts(pc),a1
	lea	conts(pc),a2
	moveq	#0,d7
	;
.loop	move.l	(a0)+,d0
	cmp.l	#'game',d0
	beq.s	.done
	;
	;another!
	;
	addq	#1,d7
	add.l	script(pc),d0
	move.l	d0,(a2)+
	lea	context(pc),a3
.loop2	move.b	(a3)+,(a1)+
	bne.s	.loop2
	subq	#1,a1
	move.l	d0,a3
.loop3	move.b	(a3)+,(a1)
	cmp.b	#10,(a1)+
	bne.s	.loop3
	clr.b	-1(a1)
	bra.s	.loop
	;
.done	move	linked(pc),-(a7)
	tst	d7
	beq	.more
	addq	#1,d7
	move.b	d7,contmenu
	;
	;OK, need a continue game menu...
	;
	clr	linked
	move.l	gloom(pc),a0
	move.l	gloompal(pc),a1
	lea	contmenu,a2
	bsr	pmenu
	bsr	selmenu
	bsr	finitpmenu
	;
	move	curropt(pc),d0
	beq	.more
	lea	conts(pc),a0
	move.l	-4(a0,d0*4),a0
.leol	cmp.b	#10,(a0)+
	bne.s	.leol
	move.l	a0,scriptat
	;
.more	move	(a7)+,linked
	beq.s	initpstuff
	bsr	qsync
	move.l	scriptat(pc),d0
	sub.l	script(pc),d0
	bsr	longput
initpstuff	;
	move	#4,p1_ob_collwith
	move	#4,p2_ob_collwith
	move	#3,p1lives
	move	#3,p2lives
	move	#25,p1health
	move	#25,p2health
	move	#0,p1weapon
	move	#0,p2weapon
	move.b	#ireload,p1reload
	move.b	#ireload,p2reload
	;
	rts

combatfiles	dc.l	combat
	dc.b	'pics/combat',0
	even
	dc.l	combatpal
	dc.b	'pics/combat.pal',0
	even
	dc.l	0

conts	ds.l	8	;8 slots!

combatmenu	dc.b	4
	dc.b	'play spacehulk series',0
	dc.b	'play gothic tomb series',0
	dc.b	'play hell series',0
	dc.b	'start with '
comnum	dc.b	'3 lives',0
	even

context	dc.b	'CONTINUE FROM ',0
	even

contmenu	dc.b	1
	dc.b	'START NEW GAME',0
conttxts	ds.b	160
	even

execscript_med	;
	jsr	waitquiet
	;
	move.l	loadingmed(pc),d0
	beq.s	execscript
	move.l	d0,a0
	move.l	medat,a1
	jsr	8(a1)	;start loading music!
	;
execscript	cmp	#2,gametype
	beq	scriptplay	;no script for combat game!
	;
	move.l	scriptat(pc),a0
	;
.loop	move.b	(a0)+,d0
	cmp.b	#10,d0
	beq.s	.loop
	and	#31,d0
	bne.s	.more
.loop2	cmp.b	#10,(a0)+
	bne.s	.loop2
	bra.s	.loop
.more	cmp	#27,d0
	bcc.s	.loop2
	add	#96,d0
	;
	;command! fetch the rest...
	;
	move.b	(a0)+,d1
	and	#31,d1
	add	#96,d1
	lsl.l	#8,d0
	or	d1,d0
	;
	move.b	(a0)+,d1
	and	#31,d1
	add	#96,d1
	lsl.l	#8,d0
	or	d1,d0
	;
	move.b	(a0)+,d1
	and	#31,d1
	add	#96,d1
	lsl.l	#8,d0
	or	d1,d0
	;
	addq	#1,a0	;skip '_'
	move.l	a0,scriptat
	cmp.l	#'pict',d0
	beq	scriptpict
	cmp.l	#'draw',d0
	beq	scriptdraw
	cmp.l	#'text',d0
	beq	scripttext
	cmp.l	#'wait',d0
	beq	scriptwait
	cmp.l	#'play',d0
	beq	scriptplay
	cmp.l	#'done',d0
	beq	scriptdone
	cmp.l	#'dark',d0
	beq	scriptdark
	cmp.l	#'show',d0
	beq	scriptshow
	cmp.l	#'hide',d0
	beq	scripthide
	cmp.l	#'loop',d0
	beq	scriptloop
	cmp.l	#'rest',d0
	beq	scriptrest
	cmp.l	#'tile',d0
	beq	scripttile
	;
	warn	#$f80
	;
	;Hmmm....bad command
.fucked	;
	rts
	;
scriptdone	lea	g2log_msg_script_done,a0
	jsr	g2log
	bsr	dispoff
	move.l	loadingmed(pc),d0
	beq	gameover
	;
	move.l	medat,a1
	clr	fadevol
	jsr	12(a1)	;stop song
	bra	gameover

sccont	dc.b	'cont_'
	even

scriptrest	;restart point!
	move.l	a0,-(a7)
	lea	g2log_msg_script_rest,a0
	jsr	g2log
	move.l	(a7)+,a0
	;this changes...we add this to 'gloomgame' file now.
	;
	move.l	a0,d1
	sub.l	script(pc),d1	;offset from start of script!
.leol	cmp.b	#10,(a0)+
	bne.s	.leol
	move.l	a0,scriptat
	;
	move.l	gloomgame(pc),a1
.loop	move.l	(a1)+,d0
	cmp.l	#'game',d0
	beq.s	.add
	cmp.l	d0,d1
	bne.s	.loop
	;
	;already here!
	;
	bra	execscript
	;
.add	;OK, gotta add new scriptat position!
	;
	move.l	d1,-(a1)
	;
	;save it out!
	;
	bsr	permit
	ifne	cd32
	bsr	savegloomgame
	elseif
	lea	gamename,a0
	move.l	gloomgame,a1
	moveq	#32,d0
	bsr	savefile
	endc
	bsr	forbid
	;
	bra	execscript

scriptloop	lea	g2log_msg_script_loop,a0
	jsr	g2log
	move.l	script,scriptat
	bra	execscript

scripthide	lea	g2log_msg_script_hide,a0
	jsr	g2log
	bsr	dispoff
	bra	execscript

scriptshow	lea	g2log_msg_script_show,a0
	jsr	g2log
	tst.l	g2v190i_start_offset	; v190t: while skipping earlier levels, suppress old intermission screens
	bgt	execscript
	clr	pdelay
	bsr	dispon
	bra	execscript

scriptdraw	lea	g2log_msg_script_draw,a0
	jsr	g2log
	tst.l	g2v190i_start_offset	; v190t: skip draw_ before earlier play_ entries
	bgt	execscript
	tst	g2v190t_reload_pic_after_level	; v190t: reload intermission IFF after gameplay, if needed
	beq.s	.g2v190t_no_reload_pic
	clr	g2v190t_reload_pic_after_level
	bsr	g2v190t_reload_current_pic
.g2v190t_no_reload_pic
	move.l	picpal,a1
	move.l	pic,d0
	bne.s	.use
	move.l	gloompal,a1
	move.l	gloom,d0
.use	move.l	d0,a0
	jsr	showpic
	bsr	initfontpal
	bra	execscript

fetchrest	move.l	scriptat,a0
	moveq	#-1,d0
.loop	addq	#1,d0
	move.b	(a0)+,(a1)
	cmp.b	#10,(a1)+
	bne.s	.loop
	clr.b	-(a1)
	move.l	a0,scriptat
	rts

text	;
picname	ds.b	64
pic_pal	dc.b	'.pal',0
	even

pic	dc.l	0
picpal	dc.l	0

freeiff	push
	move.l	pic(pc),d0
	beq.s	.skip1
	clr.l	pic
	move.l	d0,a1
	freemem	pic
.skip1	move.l	picpal(pc),d0
	beq.s	.skip2
	clr.l	picpal
	move.l	d0,a1
	freemem	picpal
.skip2	pull
	rts

freetiles	push
	move.l	floor(pc),d0
	beq.s	.skip1
	clr.l	floor
	move.l	d0,a1
	freemem	floor
.skip1	move.l	roof(pc),d0
	beq.s	.skip2
	clr.l	roof
	move.l	d0,a1
	freemem	roof
.skip2	pull
	rts

floorname	dc.b	'txts/floor'
floortag	ds.b	32
	even

roofname	dc.b	'txts/roof'
rooftag	ds.b	32
	even

scripttile	;tile command...load in floor/roof tiles!
	lea	g2log_msg_script_tile,a0
	jsr	g2log
	;
	lea	floortag(pc),a1
	bsr	fetchrest
	lea	g2log_msg_tiletag,a0
	jsr	g2log
	lea	floortag,a0
	jsr	g2log
	bsr	loadtile
	bra	execscript

loadtile	;
	;floor tag=tile extension...
	;
	bsr	freetiles
	lea	floortag(pc),a0
	lea	rooftag(pc),a1
.loop	move.b	(a0)+,(a1)+
	bne.s	.loop
	;
	bsr	permit
	lea	floorname(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,floor
	lea	roofname(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,roof
	bsr	forbid
	;
	move.l	map_rgbsfrom,map_rgbsat
	;
	move.l	floor(pc),a2
	lea	128*128(a2),a2
	move.l	a2,a0
	bsr	addpal
	move.l	floor(pc),a0
	move.l	a2,a1
	bsr	remap
	;
	move.l	roof(pc),a2
	lea	128*128(a2),a2
	move.l	a2,a0
	bsr	addpal
	move.l	roof(pc),a0
	move.l	a2,a1
	bsr	remap
	;
	move.l	map_rgbsat,map_rgbsfrom2
	rts

agapicpath	dc.b	'pics/',0
ecspicpath	dc.b	'pics_ehb/',0
	even

scriptpict	;load an iff
	lea	g2log_msg_script_pict,a0
	jsr	g2log
	bsr	freeiff
	lea	agapicpath(pc),a0
	lea	picname,a1
	tst	aga
	bne.s	.aga
	lea	ecspicpath(pc),a0
.aga	move.b	(a0)+,(a1)+
	bne.s	.aga
	subq	#1,a1
	bsr	fetchrest
	lea	g2log_msg_picname,a0
	jsr	g2log
	lea	picname,a0
	jsr	g2log
	move.l	a1,-(a7)
	bsr	permit
	lea	picname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,pic
	beq.s	.nopic
	;
	; v190t: remember the base intermission picture name before .pal is appended.
	; This lets us reload the same IFF cleanly after a gameplay level if the
	; cached intermission buffer was disturbed.
	movem.l	a0-a2,-(a7)
	lea	picname,a0
	lea	g2v190t_lastpicname,a2
.g2v190t_piccopy
	move.b	(a0)+,(a2)+
	bne.s	.g2v190t_piccopy
	movem.l	(a7)+,a0-a2
	lea	pic_pal,a0
	move.l	(a7),a1
.loop	move.b	(a0)+,(a1)+
	bne.s	.loop
	lea	picname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,picpal
	;
.nopic	addq	#4,a7
	bsr	forbid
	bra	execscript

g2v190t_reload_current_pic
	; Reload the last intermission picture after returning from a gameplay level.
	; This avoids using a cached picture buffer if gameplay scribbled over it or
	; fragmented memory around it.  The base picture name is preserved by
	; scriptpict before it appends .pal to picname.
	tst.b	g2v190t_lastpicname
	beq.s	.rts
	bsr	freeiff
	bsr	permit
	lea	g2v190t_lastpicname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,pic
	beq.s	.close
	lea	g2v190t_lastpicname,a0
	lea	picname,a1
.copybase	move.b	(a0)+,(a1)+
	bne.s	.copybase
	subq.l	#1,a1
	lea	pic_pal,a0
.copypal	move.b	(a0)+,(a1)+
	bne.s	.copypal
	lea	picname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,picpal
.close	bsr	forbid
.rts	rts

scriptdark	;
	lea	g2log_msg_script_dark,a0
	jsr	g2log
	tst.l	g2v190i_start_offset	; v190t: suppress dark_ before skipped earlier levels
	bgt	execscript
	tst	os
	bne	execscript
	;
	move.l	coplist,a2
	tst	aga
	bne.s	.aga
	lea	palette_ecs-copinit_ecs(a2),a2
	moveq	#31,d0
.loop0	lsr	2(a2)
	and	#$777,2(a2)
	addq	#4,a2
	dbf	d0,.loop0
	bra	execscript
.aga	lea	palette_aga-copinit_aga(a2),a2
	moveq	#6,d0	;7 banks
.loop	moveq	#31,d1	;32 colours
.loop2	move	6(a2),d2
	move	d2,d4
	and	#$111,d4
	lsr	#1,d2
	and	#$777,d2
	move	132+6(a2),d3
	lsr	#1,d3
	and	#$777,d3
	lsl	#3,d4
	or	d4,d3
	move	d2,6(a2)
	move	d3,132+6(a2)
	addq	#4,a2
	dbf	d1,.loop2
	lea	264-128(a2),a2
	dbf	d0,.loop
	bra	execscript

scripttext	;print text on iff
	lea	g2log_msg_script_text,a0
	jsr	g2log
	;a6=window, a4=message, d0=length of message, d6=Y
	;
	tst.l	g2v190i_start_offset	; v190t: consume but do not show text_ for skipped earlier levels
	ble.s	.g2v190t_show_text
	lea	g2log_msg_text_skip_fetch_b,a0
	jsr	g2log
	lea	text,a1
	bsr	fetchrest
	lea	g2log_msg_text_skip_fetch_ok,a0
	jsr	g2log
	bra	execscript
.g2v190t_show_text
	move	#2,pdelay
	lea	g2log_msg_text_font_b,a0
	jsr	g2log
	cmp	#1,g2_game_profile	; v190cx: old Gloom intermission keeps picture palette
	beq.s	.g2v190cx_text_no_fontpal
	bsr	initfontpal
.g2v190cx_text_no_fontpal
	lea	g2log_msg_text_font_ok,a0
	jsr	g2log
	;
	lea	g2log_msg_text_fetch_b,a0
	jsr	g2log
	lea	text,a1
	bsr	fetchrest
	lea	g2log_msg_text_fetch_ok,a0
	jsr	g2log
	lea	text,a0
	jsr	g2log
	lea	g2log_msg_text_wrap_b,a0
	jsr	g2log
	bsr	g2v14_wrap_script_text
	lea	g2log_msg_text_wrap_ok,a0
	jsr	g2log
	;
	lea	text,a4
	move	bmaphite(pc),d6
	sub	#18,d6	;v57: move intermission text one line higher
	;
	move.l	a4,a0
	moveq	#0,d1
.loop	move.b	(a0)+,d2
	beq.s	.done
	addq	#1,d1
	cmp.b	#'\',d2
	bne.s	.loop
	sub	d1,d0
	movem.l	d0/d6/a0,-(a7)
	subq	#1,d1	;v15: first line length excludes separator
	move	d1,d0
	clr.b	-(a0)
	sub	#11,d6
	lea	g2log_msg_text_print1_b,a0
	jsr	g2log
	jsr	printmess2
	lea	g2log_msg_text_print1_ok,a0
	jsr	g2log
	movem.l	(a7)+,d0/d6/a4
	;
.done	lea	g2log_msg_text_printf_b,a0
	jsr	g2log
	jsr	printmess2
	lea	g2log_msg_text_printf_ok,a0
	jsr	g2log
	;
	tst	pdelay
	bmi	execscript
	clr	pdelay
	lea	g2log_msg_text_done,a0
	jsr	g2log
	bra	execscript

g2v14_wrap_script_text	;auto-wrap long text_ script lines at a word boundary
	; v17: choose a word break close to the visual middle instead of
	; always using the last blank before column 38. Existing script '\'
	; markers are respected and left untouched.
	; in: d0.w = text length, buffer at text. d0 is preserved.
	movem.l	d1-d7/a0,-(a7)
	cmp	#38,d0
	ble.s	g2v17_wst_done
	move	d0,d4
	lsr	#1,d4	;target split = roughly half the line
	moveq	#-1,d2	;best split offset
	move	#32767,d5	;best distance from target
	moveq	#0,d3	;current offset
	lea	text,a0
g2v17_wst_scan
	cmp	d0,d3
	bcc.s	g2v17_wst_apply
	move.b	0(a0,d3.w),d1
	beq.s	g2v17_wst_apply
	cmp.b	#'\',d1
	beq.s	g2v17_wst_done
	cmp.b	#' ',d1
	bne.s	g2v17_wst_next
	cmp	#8,d3
	blt.s	g2v17_wst_next
	cmp	#38,d3
	bgt.s	g2v17_wst_apply
	move	d3,d6
	sub	d4,d6
	bpl.s	g2v17_wst_diffok
	neg	d6
g2v17_wst_diffok
	cmp	d5,d6
	bge.s	g2v17_wst_next
	move	d6,d5
	move	d3,d2
g2v17_wst_next
	addq	#1,d3
	bra.s	g2v17_wst_scan
g2v17_wst_apply
	tst	d2
	bpl.s	g2v17_wst_have
	move	#38,d2	;last fallback if no useful blank exists
g2v17_wst_have
	lea	text,a0
	move.b	#'\',0(a0,d2.w)
g2v17_wst_done
	movem.l	(a7)+,d1-d7/a0
	rts

scriptwait	;
	lea	g2log_msg_script_wait,a0
	jsr	g2log
	tst.l	g2v190i_start_offset	; v190t: skip wait_ before skipped earlier levels
	bgt	execscript
	tst	pdelay
	bmi	execscript
	bsr	waitany
	bra	execscript

checkany	movem.l	d0-d7/a0-a6,-(a7)
	bsr	vwait
	bsr	readmenusel	; v188: restore original RETURN/ENTER title-menu opener
	and	#$10,d0	; set NE if fire/return selected
	movem.l	(a7)+,d0-d7/a0-a6
	rts

waitany	movem.l	d0-d7/a0-a6,-(a7)
.wait	bsr	checkany
	beq.s	.wait
.wait2	bsr	checkany
	bne.s	.wait2
	movem.l	(a7)+,d0-d7/a0-a6
	rts

copywin	moveq	#wi_size/2-1,d0
.loop	move	(a0)+,(a1)+
	dbf	d0,.loop
	rts

freeobjlist	lea	objlist,a2
	;
.loop	move.l	(a2)+,d0
	beq.s	.done
	move.l	d0,a3
	;
	move.l	(a3),d0
	beq.s	.skip
	move.l	d0,a1
	freemem	obj
	clr.l	(a3)
.skip	;
	move.l	4(a3),d0
	beq.s	.loop
	move.l	d0,a1
	freemem	objchunks
	clr.l	4(a3)
	bra.s	.loop
	;
.done	rts

freeobjlist2	lea	objlist,a2
	;
.loop	move.l	-(a2),d0
	beq.s	.done
	move.l	d0,a3
	;
	move.l	(a3),d0
	beq.s	.skip
	move.l	d0,a1
	freemem	obj2
	clr.l	(a3)
.skip	;
	move.l	4(a3),d0
	beq.s	.loop
	move.l	d0,a1
	freemem	objchunks2
	clr.l	4(a3)
	bra.s	.loop
	;
.done	rts

mappath	dc.b	'maps/'
mapname	ds.b	64
	even

linkswap	tst	linked
	bpl.s	.rts
	;
	movem.l	player1(pc),a0-a1
	exg	a0,a1
	movem.l	a0-a1,player1
	;
	move	ob_cntrl(a0),d0
	move	ob_cntrl(a1),d1
	move	d1,ob_cntrl(a0)
	move	d0,ob_cntrl(a1)
.rts	rts

pickcombat	;pick combat zone...
	;put name into a1...
	;
	move.l	a1,-(a7)
	;
	tst	linked
	bge.s	.doit
	;
	;OK, slave...get map# from other player!
	;
	bsr	serwait
	move.b	d0,d2
	bra.s	.gotmap
	;
.doit	move	$dff006,d0
	jsr	seedrnd
	;
	move	comsleft(pc),d0
	bne.s	.pick
	moveq	#7,d0
	move	d0,comsleft
.pick	bsr	rndn
	lea	commaps(pc),a0
	subq	#1,comsleft
	move	comsleft(pc),d1
	move.b	0(a0,d0),d2		;map to play!
	move.b	0(a0,d1),0(a0,d0)
	move.b	d2,0(a0,d1)
	;
	tst	linked
	beq.s	.gotmap
	;
	move.b	d2,d0
	bsr	serput
	;
.gotmap	move.l	(a7)+,a1
	add.b	#48,d2
	move.b	d2,comseriesmap
	;
	lea	comname(pc),a0
.loop	move.b	(a0)+,(a1)+
	bne.s	.loop
	;
	move.l	combat,a0
	move.l	combatpal,a1
	jsr	showpic
	move.b	comseriesnum(pc),floortag
	clr.b	floortag+1
	bra	loadtile

commaps	dc.b	1,2,3,4,5,6,7,8
comsleft	dc	7	;7 maps left!
comname	dc.b	'com'
comseriesnum	dc.b	'1_'
comseriesmap	dc.b	'1',0
	even

scriptplay	;
	;arrives here with dispon!
	;
	lea	g2log_msg_scriptplay(pc),a0
	jsr	g2log
	lea	mapname,a1
	;
	cmp	#2,gametype
	bne.s	.notcombat
	;
	;OK, combat game is a happening...
	;
	;select from on-screen maps.
	;
	bsr	pickcombat
	bra.s	.gotname
	;
.notcombat	;
	; v190t: Levelselect starts the script from the beginning so setup commands
	; like pict_ and tile_ still run.  Older play_ entries are skipped by a
	; counter; once the counter reaches zero the current intermission belongs
	; to the selected map and the selected map is played.
	move.l	g2v190i_start_offset(pc),d7
	bmi.s	.g2v190s_noskip
	tst.l	d7
	beq.s	.g2v190s_match
	subq.l	#1,g2v190i_start_offset
	bsr	fetchrest		; skip this earlier play_ entry, keep script chain running
	bra	execscript
.g2v190s_match
	move.l	#-1,g2v190i_start_offset
.g2v190s_noskip
	bsr	fetchrest
.gotname	;
	lea	g2log_msg_mapname,a0
	jsr	g2log
	lea	mapname,a0
	jsr	g2log
	; v11: if external C2P did not load, doc2p is a dummy and
	; gameplay would switch to a black screen. Show a readable
	; marker instead of entering the renderer blind.
	move.l	c2p(pc),d0
	lea	g2v08_dummy_c2p(pc),a0
	move.l	a0,d1
	cmp.l	d1,d0
	beq	g2v11_c2pfail_scriptplay
	zerolist	objects,ob_size
	zerolist	doors,do_size
	zerolist	blood,bl_size
	zerolist	gore,go_size
	zerolist	rotpolys,rp_size
	;
	clr.l	player1
	clr.l	player2
	tst	gametype
	bne.s	.p2
	not.l	player2	;no player 2!
.p2	;
	bsr	permit
	;
	move.l	map_test(pc),d0
	bne.s	.use
	move.l	#mappath,d0
.use	move.l	d0,a0
	lea	g2log_msg_mapload_before(pc),a0
	jsr	g2log
	move.l	map_test(pc),d0
	bne.s	.g2v22_use_again
	move.l	#mappath,d0
.g2v22_use_again
	move.l	d0,a0
	moveq	#1,d1
	bsr	loadfile
	move.l	d0,map_map
	bne.s	g2v10_map_loaded
	bsr	forbid
	lea	g2v10_mapfailmenu(pc),a0
	jsr	g2v10_showmsg
	bra	gameover
g2v11_c2pfail_scriptplay
	lea	g2v11_c2pfailmenu(pc),a0
	jsr	g2v10_showmsg
	bra	gameover
g2v10_map_loaded
	;
	lea	g2log_msg_mapload_ok(pc),a0
	jsr	g2log
	bsr	initmap
	lea	g2log_msg_initmap_ok(pc),a0
	jsr	g2log
	bsr	loadtxts
	lea	g2log_msg_loadtxts_ok(pc),a0
	jsr	g2log
	move	#$a3f7,d0
	jsr	seedrnd
	lea	g2log_msg_execevent_before(pc),a0
	jsr	g2log
	moveq	#1,d0
	jsr	execevent
	lea	g2log_msg_execevent_ok(pc),a0
	jsr	g2log
	jsr	g2v190cx_build_g1_tables	; v190cx: synthetic palette/remap for original Gloom
	bsr	forbid
	;
	; v10: execevent must create player1 before the player init
	; code below writes through a5. Avoid a Guru and show a readable
	; marker if the level/event path did not spawn the player.
	tst.l	player1
	bne.s	g2v10_player1_ok
	lea	g2v10_playerfailmenu(pc),a0
	jsr	g2v10_showmsg
	bra	gameover
g2v10_player1_ok
	;
	lea	g2log_msg_player_ok(pc),a0
	jsr	g2log
	move.l	planar_palette(pc),d0
	beq.s	.g2v190cj_no_game_pal
	move.l	d0,a1
	jsr	pokepal
.g2v190cj_no_game_pal
	bsr	calcpalettes
	bsr	dispoff
	;
	;
	;init player vars...
	;
	move.l	player1,a5
	;
	move	p1lives(pc),ob_lives(a5)
	;
	cmp	#2,gametype
	beq.s	.psk
	;
	move	p1health(pc),d0
	bne.s	.p1hok
	move	#25,p1health
	move.b	#ireload,p1reload
.p1hok	move	p1health(pc),ob_hitpoints(a5)
	move	p1weapon(pc),ob_weapon(a5)
	move.b	p1reload(pc),ob_reload(a5)
	;
.psk	jsr	resetplayer
	jsr	trainer_maintain_one	;v115: apply persistent trainer at level start
	;
	tst	gametype
	beq	.p1
	;
	move.l	player2,a5
	move	p2lives(pc),ob_lives(a5)
	;
	cmp	#2,gametype
	beq.s	.psk2
	;
	move	p2health(pc),d0
	bne.s	.p2hok
	move	#25,p2health
	move.b	#ireload,p2reload
.p2hok	move	p2health(pc),ob_hitpoints(a5)
	move	p2weapon(pc),ob_weapon(a5)
	move.b	p2reload(pc),ob_reload(a5)
	;
.psk2	jsr	resetplayer
	jsr	trainer_maintain_one	;v115: apply persistent trainer at level start
.p1	;
	bsr	linkswap
	;
	;save player positions at start of level!
	;
	move.l	player1(pc),a5
	move	ob_x(a5),p1x
	move	ob_z(a5),p1z
	move	ob_rot(a5),p1r
	tst	gametype
	beq.s	.shit
	move.l	player2(pc),a5
	move	ob_x(a5),p2x
	move	ob_z(a5),p2z
	move	ob_rot(a5),p2r
.shit	;
	;init windows...
	;
	move.l	loadingmed(pc),d0
	beq.s	.nolmed
	move.l	medat,a1
	clr	fadevol
	jsr	12(a1)	;stop song
.nolmed	;
	move	#$1f3a,d0
	jsr	seedrnd
	clr.l	sucker
	clr.l	sucking
	clr	finished
	clr	finished2
	clr	g2teleport_blackout
	clr	g2teleport_black_hold
	clr	g2teleport_black_finish
	clr	doneflag
	clr	showflag
	clr	escape
	clr	frame
	;
	bsr	syncup
	;
	clr	framecnt
	clr	paused
	lea	g2log_msg_predraw_before(pc),a0
	jsr	g2log
	jsr	predrawall
	lea	g2log_msg_predraw_ok(pc),a0
	jsr	g2log
	bsr	dispon
	bsr	chaton
	lea	g2log_msg_dispon_ok(pc),a0
	jsr	g2log
	;
mainloop	addq	#1,g2logframe
	lea	g2log_msg_mainloop,a0
	jsr	g2log
	jsr	drawall
	lea	g2log_msg_draw_ok,a0
	jsr	g2log
	lea	g2log_msg_after_draw,a0
	jsr	g2log
	move	escape(pc),d0
	beq.s	.noesc
	lea	g2log_msg_menu_before,a0
	jsr	g2log
	jsr	dogamemenu
	lea	g2log_msg_menu_ok,a0
	jsr	g2log
	clr	escape
.noesc	lea	g2log_msg_finish_check,a0
	jsr	g2log
	; v105b: after the visible exit teleport pixel frame, hold a real black
	; screen briefly before allowing the intermission screen.
	tst	g2teleport_black_hold
	beq.s	.g2no_tele_black_hold
	subq	#1,g2teleport_black_hold
	bgt	mainloop
	move	g2teleport_black_finish(pc),finished
	clr	g2teleport_black_finish
	clr	g2teleport_blackout
.g2no_tele_black_hold
	move	finished(pc),d0
	beq	mainloop
	;
mainexit	st	paused
	lea	g2log_msg_mainexit(pc),a0
	jsr	g2log
	bsr	chatoff
	bsr	dispoff
	bsr	qsync2
	bsr	linkswap
	bsr	freeobjlist
	bsr	freetxts
	bsr	freemap
	;
	;finished codes...
	;
	;1 : quit (esc/exit game)
	;2 : death (both players dead)
	;3 : pattern completed 
	;4 : combat game...someone died!
	;
	move	finished(pc),d0
	and	#127,d0
	subq	#1,d0
	beq	exitgame
	subq	#1,d0
	beq	gameover
	subq	#1,d0
	beq	levelover
	subq	#1,d0
	beq	combatwon
	;
.fuck	warn	#$f08
	warn	#$80f
	bra.s	.fuck
	;
exitgame	cmp	#2,gametype
	bne.s	gameover
combatover	move.l	combat,a1
	freemem	combat
	move.l	combatpal,a1
	freemem	combatpal
gameover	bsr	freeiff
	bra	freetiles
levelover	;
	move.l	player1,a5
	move	ob_hitpoints(a5),p1health
	move	ob_lives(a5),p1lives
	move	ob_weapon(a5),p1weapon
	move.b	ob_reload(a5),p1reload
	;
	tst	gametype
	beq.s	.p1p1
	;
	move.l	player2,a5
	move	ob_hitpoints(a5),p2health
	move	ob_lives(a5),p2lives
	move	ob_weapon(a5),p2weapon
	move.b	ob_reload(a5),p2reload
	;
	;shared lives!
	;
	move	p1lives(pc),d0
	move	p2lives(pc),d1
	cmp	d1,d0
	bcc.s	.used0
	move	d1,d0
.used0	move	d0,p1lives
	move	d0,p2lives
	;
.p1p1	tst.l	map_test
	bne	gameover
	move	#-1,g2v190t_reload_pic_after_level	; v190t: next intermission redraw reloads cached picture
	bra	execscript_med
	;
combatwon	move.l	player1(pc),a5
	move	ob_lives(a5),p1lives
	beq	.p1lost
	move.l	player2(pc),a5
	move	ob_lives(a5),p2lives
	beq	.p2lost
	;
	;combat game continues!
	;
	bra	execscript_med
	;
.p1lost	;player 1 lost the game
	;
	lea	p2wins(pc),a2
	tst	linked
	beq	.combatmess
	lea	ploses_(pc),a2
	bgt	.combatmess
	lea	pwins_(pc),a2
	bra	.combatmess
	;
.p2lost	;player 2 lost combat game
	;
	lea	p1wins(pc),a2
	tst	linked
	beq	.combatmess
	lea	ploses_(pc),a2
	blt	.combatmess
	lea	pwins_(pc),a2
	;
.combatmess	move.l	combat,a0
	move.l	combatpal,a1
	bsr	pmenu
	bsr	selmenu
	bsr	finitpmenu
	bra	combatover

p1wins	dc.b	1,'player one wins combat game!',0
	even
p2wins	dc.b	1,'player two wins combat game!',0
	even
pwins_	dc.b	1,'player wins combat game!',0
	even
ploses_	dc.b	1,'player loses combat game!',0
	even

freemap	move.l	map_map,d0
	beq.s	.done
	move.l	d0,a1
	freemem	map
	clr.l	map_map
.done	rts

; v166: PLAYER control selector.  PLAYER 1/2 may choose any input
; method, but never the method currently used by the other player.
; KEYBMOUSE and KEYBOARD count as the same keyboard method.  The visible
; menu field is fixed at 10 chars, so longer names cannot corrupt the
; following PLAYER/menu rows.
inccntrl	addq	#1,(a2)
	cmp	#6,(a2)
	bcs.s	g2v166_inc_pok
	clr	(a2)
g2v166_inc_pok	move	(a2),d0
	bsr	g2v166_cntrl_conflict
	beq.s	inccntrl
	bra.s	g2v166_cntrl_copy

deccntrl	subq	#1,(a2)
	bpl.s	g2v166_dec_pok
	move	#5,(a2)
g2v166_dec_pok	move	(a2),d0
	bsr	g2v166_cntrl_conflict
	beq.s	deccntrl
	;
g2v166_cntrl_copy
	movem.l	d0-d2/a0-a1,-(a7)
	move.l	a1,a4
	moveq	#9,d1
	moveq	#' ',d2
g2v166_clear_field	move.b	d2,(a4)+
	dbf	d1,g2v166_clear_field
	lea	popts(pc),a0
	move.l	0(a0,d0*4),a0
	moveq	#9,d1
g2v166_copy_field	move.b	(a0)+,d2
	beq.s	g2v166_copy_done
	move.b	d2,(a1)+
	dbf	d1,g2v166_copy_field
g2v166_copy_done	movem.l	(a7)+,d0-d2/a0-a1
	rts

g2v166_cntrl_conflict	; in: d0=candidate, a3=other player's cntrl. EQ=blocked
	move	(a3),d1
	cmp	#2,d0
	bcc.s	g2v166_nonkeyboard_candidate
	cmp	#2,d1
	bcs.s	g2v166_blocked	; KEYBMOUSE/KEYBOARD are one shared method
	bra.s	g2v166_ok
g2v166_nonkeyboard_candidate
	cmp	d1,d0
	beq.s	g2v166_blocked
g2v166_ok	moveq	#1,d1
	rts
g2v166_blocked	moveq	#0,d1
	rts

g2v36_clear_title_buffers	;clear both display bitmaps before rebuilding title/menu
	movem.l	d0-d1/a0,-(a7)
	move.l	bitmaps,d0
	beq.s	.rts
	move.l	d0,a0
	move.l	bmapmem,d1
	add.l	d1,d1	;two compact 240-line bitmaps
	beq.s	.rts
	lsr.l	#2,d1
	beq.s	.rts
	subq.l	#1,d1
	moveq	#0,d0
.loop	move.l	d0,(a0)+
	dbf	d1,.loop
.rts	movem.l	(a7)+,d0-d1/a0
	rts


g2v37_clear_title_topline	;clear the top few title lines in both compact OS bitmaps
	movem.l	d0-d7/a0-a2,-(a7)
	move.l	bitmaps,d0
	beq.s	.rts
	move.l	d0,a0
	move.l	bitmaps2,d0
	beq.s	.only1
	move.l	d0,a1
	bsr.s	.clearone
.only1	bsr.s	.clearone_a0
.rts	movem.l	(a7)+,d0-d7/a0-a2
	rts
.clearone	movem.l	a0-a1,-(a7)
	move.l	a1,a0
	bsr.s	.clearone_a0
	movem.l	(a7)+,a0-a1
	rts
.clearone_a0	; clear lines 0-3 over all active bitplanes
	move	bitplanes(pc),d7
	beq.s	.cdone
	subq	#1,d7
	move.l	bpmod(pc),d6
	moveq	#0,d5
.plane	move.l	a0,a2
	move.l	d5,d0
	mulu	d6,d0
	add.l	d0,a2
	moveq	#3,d4
.line	moveq	#9,d3
	moveq	#0,d0
.word	move.l	d0,(a2)+
	dbf	d3,.word
	dbf	d4,.line
	addq	#1,d5
	dbf	d7,.plane
.cdone	rts

g2v58_clear_title_lastline	;clear stale very bottom title/menu line in both compact OS bitmaps
	movem.l	d0-d7/a0-a2,-(a7)
	move.l	bitmaps,d0
	beq.s	.rts
	move.l	d0,a0
	move.l	bitmaps2,d0
	beq.s	.only1
	move.l	d0,a1
	bsr.s	.clearone
.only1	bsr.s	.clearone_a0
.rts	movem.l	(a7)+,d0-d7/a0-a2
	rts
.clearone	movem.l	a0-a1,-(a7)
	move.l	a1,a0
	bsr.s	.clearone_a0
	movem.l	(a7)+,a0-a1
	rts
.clearone_a0	; clear last visible line 239 over all active bitplanes
	move	bitplanes(pc),d7
	beq.s	.cdone
	subq	#1,d7
	move.l	bpmod(pc),d6
	moveq	#0,d5
.plane	move.l	a0,a2
	move.l	d5,d0
	mulu	d6,d0
	add.l	d0,a2
	move.l	linemod(pc),d0
	move	#239,d1
	mulu	d1,d0
	add.l	d0,a2
	moveq	#0,d4
.line	moveq	#9,d3
	moveq	#0,d0
.word	move.l	d0,(a2)+
	dbf	d3,.word
	dbf	d4,.line
	addq	#1,d5
	dbf	d7,.plane
.cdone	rts


; v151: safe main-menu gloombrush overlay.
; Draws optional pics/gloom at Y=168.  Important: linemod is stored as a
; longword split over linemod/linemodw, so word-sized mulu must use
; linemodw.  Using linemod as a word reads the high word 0 and draws at Y=0.
g2v142_draw_gloombrush_safe
	movem.l	d0-d4/a0-a2,-(a7)
	move.l	gloombrush,d0
	beq	.done
	move.l	d0,a2
	;
	; Basic trimmed-IFF header guard.
	move	(a2),d0		;pixel width
	beq	.done
	cmp	#320,d0
	bhi	.done
	move	2(a2),d2		;pixel height
	beq	.done
	move	4(a2),d3		;depth
	beq	.done
	move	bitplanes,d4
	cmp	d4,d3
	bhi	.done
	;
	; Clamp decode height to the remaining title area.
	; v190cx: Zombie Massacre g3-dc brush is drawn 2px higher, so the
	; normal 72-row title/footer area remains available.
	move	d2,-(a7)
	move	#72,d0
	cmp	#2,g2_game_profile
	bne.s	.g2v190ct_hlimit_ok
	move	#72,d0
.g2v190ct_hlimit_ok
	cmp	d0,d2
	bls	.heightok
	move	d0,2(a2)
.heightok
	move.l	showbitmap,d0
	beq	.skipshow
	move.l	d0,a1
	jsr	.g2v142_drawone
.skipshow
	move.l	drawbitmap,d0
	beq	.restore
	move.l	d0,a1
	jsr	.g2v142_drawone
.restore
	move	(a7)+,2(a2)
.done	movem.l	(a7)+,d0-d4/a0-a2
	rts

.g2v142_drawone
	movem.l	d0/a0-a1,-(a7)
	move	#168,d0
	cmp	#2,g2_game_profile	; v190do: Zombie Massacre g3-dc brush 1px down from v190dn
	bne.s	.g2v190ct_brush_y_ok
	subq	#1,d0
.g2v190ct_brush_y_ok
	mulu	linemodw(pc),d0
	add.l	d0,a1
	move.l	gloombrush,a0
	jsr	decodeiff
	movem.l	(a7)+,d0/a0-a1
	rts

; v145: draw the optional pics/gloom logo only for the main menu.
; ABOUT deliberately uses the clean title background without this overlay.
g2v145_draw_menu_gloombrush
	cmp	#2,g2_game_profile	; v190ht: Zombie Massacre g3-dc is allowed in title/menu even outside AGA guard
	beq.s	.draw
	tst	aga
	beq.s	.rts
	cmp	#3,g2_game_profile	; v190cr: Gloom3 title/about must not show pics/gloom overlay
	beq.s	.rts
.draw	jsr	g2v142_draw_gloombrush_safe	; no brush loaded = safe no-op for classic Gloom
.rts	rts

; v145: rebuild the clean title background.  The menu overlay is added
; separately, so ABOUT can stay free of the pics/gloom logo.
g2v145_show_clean_title
	move.l	gloom(pc),a0
	move.l	gloompal(pc),a1
	jsr	showpic_noclear	; v190l: restore pre-levelselect title redraw path, avoids pink top artefacts
	; v152: keep the full title picture visible again.  The old v37/v58
	; safety clears for top/bottom stale pixels are no longer applied here.
	jsr	g2v36_hide_pointer	;v37: re-apply chip-RAM blank pointer after title display
	rts

; v146: show the optional pics/gloom overlay immediately when the title
; screen loads.  ABOUT still uses g2v145_show_clean_title, so the overlay
; stays hidden there.  The overlay itself is still drawn at Y=168.
g2v146_show_title_with_gloom
	jsr	g2v145_show_clean_title
	jsr	g2v145_draw_menu_gloombrush
	rts


dointro	;
	; v190gl: Classic Gloom now uses embedded Gloom2 title/menu assets,
	; so do not show the old unsupported notice.
	jsr	g2v145_show_clean_title
	bsr	dispon
	jsr	g2v145_draw_menu_gloombrush	; v190hu: ZM title overlay is visible before the menu too
.g2v190ct_no_prebrush
	;
	bsr	chaton
	;
	; v149: draw pics/gloom directly onto the visible title screen after
	; the clean title has been shown, so it appears immediately at Y=168
	; and not at the very top.  ABOUT still stays clean.
	jsr	inputon
	jsr	waitany
	;
.redrawmenu
	jsr	g2v190ct_titlefont	; v190cu: far-call buildfix for Gloom Original smallfont title menu
	jsr	g2v145_draw_menu_gloombrush
	tst	linked
	bne.s	.use_linked_menu
	tst	g2_game_profile	; v190hp: all visible title menus stay classic, no START LEVEL row
	beq.s	.use_gloom2_startmenu
	lea	compat_startmenu,a4	; Gloom/Gloom3/ZM: classic menu without START LEVEL
	jsr	initmenu
	clr	curropt
	bra.s	.sel
.use_gloom2_startmenu
	lea	startmenu,a4
	jsr	initmenu
	clr	curropt	; default title selection is ONE PLAYER GAME
	bra.s	.sel
.use_linked_menu
	lea	startmenu2,a4
	jsr	initmenu
	;
.sel	jsr	selmenu
	;
	tst	linked
	beq.s	.notlinked
	;
	cmp	#2,d0
	bcs	.newgame2
	subq	#2,d0
	beq	.unlink
	subq	#1,d0
	beq	.about
	subq	#1,d0
	beq	.exitgloom
	bra	.sel
.unlink	;
	bsr	qsync2
	bsr	chatoff
	clr	linked
	lea	p2ctype(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr	inccntrl
	;
	bsr	finitpmenu
	bra	dointro
	;
.newgame2	addq	#1,d0
	move	d0,gametype
	bsr	qsync2
	bsr	chatoff
	bra	finitpmenu
	;
.notlinked
	move	d0,d7
	and	#$0300,d7	; $0100=left, $0200=right for PLAYER rows
	and	#$00ff,d0
	tst	g2_game_profile	; v190co: compatibility profiles use classic row mapping
	bne	.g2compat_notlinked
	tst	d7
	beq.s	.g2v166_notlinked_fire
	cmp	#4,d0		; v190hp: classic PLAYER 1 row after removing START LEVEL
	beq	.g2v166_p1lrsel
	cmp	#5,d0		; v190hp: classic PLAYER 2 row after removing START LEVEL
	beq	.g2v166_p2lrsel
	bra	.sel
.g2v166_notlinked_fire
	cmp	#3,d0		; v190hp: rows 0/1/2 -> gametype 0/1/2
	bcs	.newgame
	cmp	#4,d0
	beq	.g2v166_p1sel
	cmp	#5,d0
	beq	.g2v166_p2sel
	cmp	#7,d0
	beq	.linksel
	cmp	#8,d0
	beq	.vilesel
	cmp	#9,d0
	beq	.about
	cmp	#10,d0
	beq	.exitgloom
	bra	.sel
.g2compat_notlinked
	tst	d7
	beq.s	.g2compat_fire
	cmp	#4,d0		; classic PLAYER 1 row
	beq	.g2compat_p1lrsel
	cmp	#5,d0		; classic PLAYER 2 row
	beq	.g2compat_p2lrsel
	bra	.sel
.g2compat_fire
	cmp	#3,d0		; rows 0/1/2 -> gametype 0/1/2
	bcs	.newgame
	cmp	#4,d0
	beq	.g2compat_p1sel
	cmp	#5,d0
	beq	.g2compat_p2sel
	cmp	#7,d0
	beq	.linksel
	cmp	#8,d0
	beq	.vilesel
	cmp	#9,d0
	beq	.about
	cmp	#10,d0
	beq	.exitgloom
	bra	.sel
.g2compat_p1lrsel
	cmp	#$0100,d7
	beq.s	.g2compat_p1prevsel
.g2compat_p1sel	lea	p1ctypec(pc),a1
	lea	p1_ob_cntrl,a2
	lea	p2_ob_cntrl,a3
	bsr	inccntrl
	bra	.sel
.g2compat_p1prevsel	lea	p1ctypec(pc),a1
	lea	p1_ob_cntrl,a2
	lea	p2_ob_cntrl,a3
	bsr	deccntrl
	bra	.sel
.g2compat_p2lrsel
	cmp	#$0100,d7
	beq.s	.g2compat_p2prevsel
.g2compat_p2sel	lea	p2ctypec(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr	inccntrl
	bra	.sel
.g2compat_p2prevsel	lea	p2ctypec(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr	deccntrl
	bra	.sel
.g2v190f_level_lrsel
	bsr	optoff		; v190l: update only this menu row, no full title rebuild
	cmp	#$0100,d7
	beq.s	.g2v190f_level_prev
	bsr	g2v190f_level_next
	bra.s	.g2v190f_level_row_update
.g2v190f_level_prev	bsr	g2v190f_level_prev
.g2v190f_level_row_update
	bsr	opton
	bra	.sel
.g2v190f_level_start
	bsr	g2v190f_level_start
	moveq	#0,d0
	bra	.newgame_maptest
	;
.g2v166_p1lrsel	cmp	#$0100,d7
	beq.s	.g2v166_p1prevsel
.g2v166_p1sel	lea	p1ctype(pc),a1
	lea	p1_ob_cntrl,a2
	lea	p2_ob_cntrl,a3
	bsr	inccntrl
	bra	.sel
.g2v166_p1prevsel	lea	p1ctype(pc),a1
	lea	p1_ob_cntrl,a2
	lea	p2_ob_cntrl,a3
	bsr	deccntrl
	bra	.sel
	;
.g2v166_p2lrsel	cmp	#$0100,d7
	beq.s	.g2v166_p2prevsel
.g2v166_p2sel	lea	p2ctype(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr	inccntrl
	bra	.sel
.g2v166_p2prevsel	lea	p2ctype(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr	deccntrl
	bra	.sel
	;
.linksel	bsr	finitpmenu
	bsr	linkup
	bra	dointro
	;
.vilesel	addq	#1,mode
	and	#1,mode
	move	mode(pc),d0
	lea	modes,a0
	move.l	0(a0,d0*4),a0
	tst	g2_game_profile
	beq.s	.g2v190co_mode_main
	lea	modetxtc,a1
	bra.s	.g2v190co_mode_copy
.g2v190co_mode_main
	lea	modetxt,a1
.g2v190co_mode_copy
	move.b	(a0)+,(a1)+
	bne.s	.g2v190co_mode_copy
	;
	bra	.sel
	;	;
.about	;about text...
	;
	bsr	g2v147_finitmenu_soft
	move.l	gloom(pc),a0
	move.l	gloompal(pc),a1
	lea	abouttext,a2
	cmp	#2,g2_game_profile	; v190hs: Zombie Massacre has its own ABOUT text
	bne.s	.g2v190hs_not_zm_about_text
	lea	abouttext_zm,a2
	bra.s	.g2v190hs_about_text_ok
.g2v190hs_not_zm_about_text
	cmp	#3,g2_game_profile	; v190hs: Gloom3 has its own ABOUT text
	bne.s	.g2v190hs_about_text_ok
	lea	abouttext_g3,a2
.g2v190hs_about_text_ok
	cmp	#2,g2_game_profile	; v190hs: Zombie Massacre ABOUT uses clean title without g3-dc
	beq.s	.g2v190cs_about_zm
	cmp	#3,g2_game_profile	; v190dm: Gloom3 ABOUT opens through no-clear soft path
	beq.s	.g2v190dm_about_g3
	tst	g2_game_profile	; v190cp: main Gloom Deluxe ABOUT keeps its soft redraw path
	beq.s	.g2v190cp_about_soft
	bsr	pmenu
	bra.s	.g2v190cp_about_done
.g2v190dm_about_g3
	bsr	g2v147_pmenu_soft
	bra.s	.g2v190cp_about_done
.g2v190cs_about_zm
	bsr	dispoff
	; v190hv: Zombie Massacre ABOUT is title-only, without g3-dc/g3-zm overlay.
	jsr	g2v145_show_clean_title
	lea	abouttext_zm,a2		; show_clean_title clobbers a2, restore ZM ABOUT text/menu pointer
	bsr	g2v190cs_pmenu_precomposed
	bra.s	.g2v190cp_about_done
.g2v190cp_about_soft
	bsr	g2v147_pmenu_soft
.g2v190cp_about_done
	move	numopts(pc),-(a7)
	move	#1,numopts
	;
	bsr	selmenu
	;
	;cheat mode too?
	;
	qkey	$5f
	beq.s	.noch
	;
	warn	#$f0f
	move	#-1,cheat
	;
.noch	bsr	g2v147_finitmenu_soft
	move	(a7)+,numopts
	cmp	#2,g2_game_profile	; v190dp: Zombie ABOUT return is precomposed hidden to avoid brush flash
	beq.s	.g2v190dp_zm_about_return
	jsr	g2v145_show_clean_title
	bsr	dispon
	bra	.redrawmenu
.g2v190dp_zm_about_return
	bsr	dispoff
	jsr	g2embed_apply_zm_title_overlay	; v190hv: restore embedded ZM title image after ABOUT
	jsr	g2v145_show_clean_title
	jsr	g2v142_draw_gloombrush_safe
	bsr	dispon
	bra	.redrawmenu
	;
.notabout	subq	#1,d0
	bne	.sel
	;
.exitgloom	moveq	#4,d0
	;
.newgame	clr.l	map_test	; v190f: normal title starts are not forced-map tests
	move.l	#-1,g2v190i_start_offset	; v190r: normal menu start begins at script default
	cmp	#1,g2_game_profile	; v190cw: classic Gloom starts directly, no continue-scan crash path
	bne.s	.g2v190cw_ngofs_ok
	clr.l	g2v190i_start_offset	; script still runs from start, first play_ is selected
.g2v190cw_ngofs_ok
.newgame_maptest	move	d0,gametype
	bsr	qsync2
	bsr	chatoff
	bra	finitpmenu

linkup	;link up...
	;
	lea	linkupmenu,a0
	bsr	qmenu
	;
.loop	bsr	selmenu
	cmp	#3,d0
	bne.s	.notb
	bsr	optbaud
	bra.s	.loop
	;
.notb	bsr	finitqmenu
	move	curropt(pc),d0
	beq	nulllink
	cmp	#4,d0
	beq.s	.rts
	subq	#1,d0
	beq	dialup
	subq	#1,d0
	beq	answer
.rts	rts
	;
answer	lea	ata(pc),a0
	move	#-1,linked
	bra	doconnect

dialup	;
	lea	phonenum(pc),a0
	move.l	a0,a1
	move.l	a0,phoneat
.clr	tst.b	(a0)
	beq.s	.clrd
	move.b	#32,(a0)+
	bra.s	.clr
.clrd	move.b	#127,(a1)
	;
	lea	linkmenu0,a0
	bsr	qmenu
	;
	st	chatok
	;
.loop	qkey	$41,d0	;undel!
	bne.s	.loop
	;
.wkey	bsr	checkesc
	bne	.escout
	qkey	$44	;return?
	bne	.done
	key	$41,d0
	bne	.del	;del
	;
	move	chatoutget,d0
	cmp	chatoutput,d0
	beq.s	.wkey
	;
	and	#31,d0
	lea	chatout,a0
	move.b	0(a0,d0),d0	;chat out character!
	addq	#1,chatoutget
	;
	cmp	#48,d0
	bcs.s	.loop
	cmp	#58,d0
	bcc.s	.loop
	;
	move.l	phoneat(pc),a0
	move.b	d0,(a0)+
	tst.b	(a0)
	beq.s	.skinc
	move.b	#127,(a0)
	move.l	a0,phoneat
	;
.skinc	bsr	vwait
	bsr	optoff
	bsr	opton
	bra	.loop
	;
.del	move.l	phoneat(pc),a0
	cmp.l	#phonenum,a0
	beq	.loop
	cmp.b	#127,(a0)
	bne.s	.noc
	move.b	#32,(a0)
	subq	#1,a0
.noc	move.b	#127,(a0)
	move.l	a0,phoneat
	bra.s	.skinc
	;
.done	qkey	$44
	bne.s	.done
	;
	bsr	.escout
	;
	lea	pbuff(pc),a0	;use this for connect string!
	move.l	a0,a2
	;
	move.l	#'ATDT',(a2)+
	lea	phonenum(pc),a1
.cpn	move.b	(a1)+,(a2)
	beq.s	.null
	cmp.b	#32,(a2)+
	bne.s	.cpn
	subq	#1,a2
.null	move.b	#13,(a2)+
	move.b	#10,(a2)+
	clr.b	(a2)
	;
	move	#1,linked
	bra	doconnect
	;
.escout	bsr	finitqmenu
	clr	chatok
	clr	chatoutget
	clr	chatoutput
	rts

checkesc	qkey	$45
	ifne	cd32
	movem.l	d0-d7/a0-a6,-(a7)
	lea	cd32buff(pc),a0
	clr	escape
	bsr	readcd321
	tst	escape
	sf	escape
	movem.l	(a7)+,d0-d7/a0-a6
	endc
	rts

cd32buff	ds	8

phoneat	dc.l	phonenum

nulllink	;
	lea	connect(pc),a0
doconnect	;
	bsr	sendstring
	bsr	waitconnect
	beq	.calcmaster
	;
	clr	linked
	rts
	;
	;OK, randomly determine who is master and who is slave!
	;
	;faster computer SHOULD be master!
	;
	;let's try, number of rnd divs/frame...send as a long word!
	;
.calcmaster	tst	linked
	bne	.linked
	;
	move	linkdelay(pc),d0
	ext.l	d0
	move.l	d0,d2
	bsr	longput
	bsr	longget
	cmp.l	d0,d2
	beq.s	.itsatie
	bhi	.master
	bra	.slave
	;
.itsatie	;OK, both connected at same time! use faster machine...
	;
	moveq	#0,d7
	;
	move	#$20,$dff09a
	;
.vwloop	btst	#5,$dff01f
	beq.s	.vwloop
	move	#$20,$dff09c
.cmloop	;
	btst	#5,$dff01f
	bne.s	.cmdone
	jsr	rndw	;v135 buildfix: rndw out of bsr range after reflection code growth
	ext.l	d0
	divs	#$a5a5,d0
	addq.l	#1,d7
	bra.s	.cmloop
.cmdone	;
	move	#$20,$dff09c
	move	#$8020,$dff09a
	;
	move.l	d7,d0
	bsr	longput
	bsr	longget
	cmp.l	d0,d7
	beq.s	.calcmaster
	blt.s	.slave
	;
	;I'm player 1
.master	move	#1,linked
	bra.s	.linked
	;
.slave	;I'm actually player 2!
	move	#-1,linked
	;
.linked	move	#-1,p2_ob_cntrl
	;
	lea	incharge(pc),a0
	tst	linked
	bgt.s	.goz
	lea	notincharge(pc),a0
.goz	bsr	qmenu
	bsr	chaton
	bsr	selmenu
	bra	finitqmenu

longput	;send ser long in d0
	;
	moveq	#3,d1
.loop	rol.l	#8,d0
	movem.l	d0-d1,-(a7)
	bsr	vwait
	bsr	serput
	movem.l	(a7)+,d0-d1
	dbf	d1,.loop
	rts

longget	;get ser long in d0
	;
	move.l	d2,-(a7)
	moveq	#3,d1
.loop	movem.l	d1-d2,-(a7)
	bsr	serwait
	movem.l	(a7)+,d1-d2
	lsl.l	#8,d2
	move.b	d0,d2
	dbf	d1,.loop
	move.l	d2,d0
	move.l	(a7)+,d2
	rts

incharge	dc.b	1
	dc.b	'player selects options',0
	even

notincharge	dc.b	1
	dc.b	'other player selects options',0
	even

sendstring	;a0=string to send
	;
	move.l	a0,a2
.loop	bsr	vwait
	move.b	(a2)+,d0
	beq.s	.done
	bsr	serput
	bra.s	.loop
.done	rts

linkdelay	dc	0

waitconnect	;wait for 'CONNECT' to arrive...
	;return eq if OK, else ne if 'esc'ed or not received.
	;
	lea	linkmess,a0
	bsr	qmenu
	clr	linkdelay
	;
.retry	lea	wconnect(pc),a2
	;
.loop	bsr	vwait
	addq	#1,linkdelay
	bsr	checkesc
	bne	.notok
	bsr	rbfchk
	beq.s	.loop
	bsr	serget
	cmp.b	(a2)+,d0
	bne.s	.retry
	tst.b	(a2)
	bne.s	.loop
	;
.ok	;OK, connect xxxx ends with 13,10...
	;
.w10	bsr	vwait
	addq	#1,linkdelay
	bsr	checkesc
	bne	.notok
	bsr	rbfchk
	beq.s	.w10
	bsr	serget
	cmp.b	#10,d0
	bne.s	.w10
	;
	bsr	finitqmenu
	moveq	#0,d0
	rts
	;
.notok	bsr	finitqmenu
	moveq	#-1,d0
	rts

optbaud	addq	#1,baud
	cmp	#6,baud
	bcs.s	.ok
	clr	baud
.ok	;
calcbaud	move	baud(pc),d0
	lea	bauds(pc),a0
	move.l	4(a0,d0*8),a0	;baud text!
	lea	baudtext(pc),a1
.loop	move.b	(a0)+,(a1)+
	bne.s	.loop
	;
	move	baud(pc),d0
	lea	bauds(pc),a1
	move.l	0(a1,d0*8),d0	;2400 etc.
	move.l	baudconst(pc),d1
	divu	d0,d1
	subq	#1,d1
	move	d1,$dff032
	;
	rts

connect	dc.b	'CONNECT',13,10,0
	even

wconnect	dc.b	'CONNECT',0
	even

ata	dc.b	'ATA',13,10,0
	even

linkmenu0	dc.b	1
	dc.b	'DIAL: '
phonenum	dc.b	127,'               ',0
	even

linkmess	dc.b	1
	dc.b	'ATTEMPTING TO CONNECT...ESC TO ABORT',0
	even

linkupmenu	dc.b	5
	dc.b	'NULL LINK',0
	dc.b	'DIAL UP',0
	dc.b	'ANSWER',0
	dc.b	'BAUD RATE: '
baudtext	dc.b	'2400 ',0
	dc.b	'EXIT',0
	even

baudconst	dc.l	3546895	;pal
	dc.l	3579545	;ntsc

baud	dc	0

bauds	dc.l	2400,b1,4800,b2,9600,b3,14400,b4,28800,b5
	dc.l	38400,b6

b1	dc.b	'2400 ',0
b2	dc.b	'4800 ',0
b3	dc.b	'9600 ',0
b4	dc.b	'14400',0
b5	dc.b	'28800',0
b6	dc.b	'38400',0
	even

	dc.l	popt0
popts	dc.l	popt1,popt2,popt3,popt4,popt5,popt6
	;
popt0	dc.b	'NULL MODEM',0	;-1
popt1	dc.b	'KEYBMOUSE',0	;0
popt2	dc.b	' KEYBOARD',0	;1
popt3	dc.b	'JOYSTICK 1',0	;2
popt4	dc.b	'JOYSTICK 2',0	;3
popt5	dc.b	'CD32 PAD 1',0	;4
popt6	dc.b	'CD32 PAD 2',0	;5

joyxs	dc	0,0	;serial
joyys	dc	0,0
	;
joyx0	dc	0,0
joyb0	dc	0,0
joyx1	dc	0,0
joyb1	dc	0,0
joyx2	dc	0,0
joyb2	dc	0,0
joyx3	dc	0,0
joyb3	dc	0,0
joyx4	dc	0,0
joyb4	dc	0,0
joyx5	dc	0,0
joyb5	dc	0,0

	even

gamemenu	dc.b	18
	dc.b	'CONTINUE',0
	dc.b	92,0
	; v116c: ingame menu switches only; title menu remains v107.
	; Effect render hooks are intentionally disabled after v116/v116b guru.
game_wsize	dc.b	'          VIEW SIZE: FULLSCREEN                 ',0
game_full	dc.b	'        FULL SCREEN: YES                        ',0
game_floor	dc.b	'              FLOOR: YES                        ',0
game_ceil	dc.b	'            CEILING: YES                        ',0
	dc.b	92,0
game_blob	dc.b	'       BLOB SHADOWS: NO                         ',0
game_reflections	dc.b	'        REFLECTIONS: NO                         ',0
game_visibility	dc.b	'         VISIBILITY: DEFAULT                    ',0
	dc.b	92,0
game_inv	dc.b	'   UNLIMITED HEALTH: NO                         ',0
game_bouncy	dc.b	'     BOUNCY BULLETS: NO                         ',0
game_onehit	dc.b	'       ONE HIT KILL: NO                         ',0
game_weapon	dc.b	'             WEAPON: DEFAULT                    ',0
game_boost	dc.b	'            UPGRADE: DEFAULT                    ',0
	dc.b	92,0
	dc.b	'QUIT GAME',0
	even

g2_blobshadow	dc	-1	;v116c menu flag, v126 enables enemy blob shadow
g2_reflections	dc	-1	;v116c menu flag only, render code removed
g2_visibility	dc	-1	;v190fc -1=DEFAULT, +1=ADVANCED(16); saved in gloom.cfg
g2v190dz_bayer4	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	even
g2_bayer_x	dc	0	;v190ej screen X phase for ordered shade blend
g2_bayer_ybase	dc	0	;v190ej screen Y phase for ordered shade blend
g2_bayer_thresh	dc	0	;v190ep 0=no blend, 1..15 incl sparse shade-step lead-in
g2_bayer_nextpal	dc.l	0	;v190ej next darker palette LUT for flat blend
g2v190ej_bayer_column_long	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5
	even
g2v190ej_bayer_xrows	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	0,8,2,10,0,8,2,10,0,8,2,10,0,8,2,10
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	12,4,14,6,12,4,14,6,12,4,14,6,12,4,14,6
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	3,11,1,9,3,11,1,9,3,11,1,9,3,11,1,9
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	dc.b	15,7,13,5,15,7,13,5,15,7,13,5,15,7,13,5
	even
g2_shape_owner	dc.l	0	;v126 current object owner while queuing shapes
g2_shadow_active	dc	0	;v126 per-sprite shadow draw active
g2_shadow_curx	dc	0
g2_shadow_cx	dc	0
g2_shadow_rx	dc	0
g2_shadow_col	dc	0
g2_shadow_yoff	dc	0	;v133 projected floor offset for projectile reflections
g2_reflect_floorrow	dc	0	;v181 absolute floor row for pickup/upgrade reflections
g2_reflect_pickup	dc	0	;v169 current reflection owner is stationary pickup/powerup
g2_reflect_softedge	dc	0	;v135 reflection-only edge feather/dither flag
g2_reflect_edge_col	dc	0	;v137 lighter outer reflection colour
trainer_invincible	dc	0
trainer_bouncy	dc	0
trainer_onehit	dc	0	;0=NO, -1=YES one-shot enemy kills
trainer_weapon	dc	0	;0=DEFAULT, 1..5 forced weapon
trainer_boost	dc	0	;0=DEFAULT, 1..5 forced upgrade
game_menu_active	dc	0	;-1 while in in-game menu

trainer_txt_tiny	dc.b	'TINY',0
trainer_txt_small	dc.b	'SMALL',0
trainer_txt_medium	dc.b	'MEDIUM',0
trainer_txt_large	dc.b	'LARGE',0
trainer_txt_xlarge	dc.b	'EXTRA LARGE',0
trainer_txt_huge	dc.b	'HUGE',0
trainer_txt_vhuge	dc.b	'VERY HUGE',0
trainer_txt_almost	dc.b	'ALMOST FULL',0
trainer_txt_fullscreen	dc.b	'FULLSCREEN',0
	even

modes	dc.l	mode1,mode2

mode1	dc.b	'MEATY VIOLENCE MODE',0

mode2	dc.b	'MESSY VIOLENCE MODE',0

startmenu	dc.b	11		; v190hp: START LEVEL hidden again; scanner code is retained
	dc.b	'ONE PLAYER GAME',0	;0
	dc.b	'TWO PLAYER GAME',0	;1
	dc.b	'TWO PLAYER COMBAT',0	;2
	dc.b	0			;3 spacer/separator above PLAYER 1
	dc.b	'PLAYER 1 '
p1ctype
	ifne	cd32
	dc.b	'CD32 PAD 1',0	;4, fixed 10-char field
	elseif
	dc.b	'KEYBMOUSE  ',0		;4, fixed 10-char field
	endc
	;
	dc.b	'PLAYER 2 '
p2ctype
	ifne	cd32
	dc.b	'CD32 PAD 2',0	;5, fixed 10-char field
	elseif
	dc.b	'JOYSTICK 1 ',0		;5, fixed 10-char field
	endc
	;
	dc.b	0			;6 spacer/separator above REMOTE LINK OPTIONS
	dc.b	'REMOTE LINK OPTIONS',0	;7
	;
modetxt	dc.b	'MEATY VIOLENCE MODE',0	;8
	dc.b	'ABOUT GLOOM',0		;9
	dc.b	'EXIT GLOOM',0		;10
	even

g2v190f_level_text	dc.b	'MAP1.1',0	; hidden level selector text buffer; script/stages scan kept
	even

compat_startmenu	dc.b	11		; v190cp: classic compatibility menu, no START LEVEL
	dc.b	'ONE PLAYER GAME',0	;0
	dc.b	'TWO PLAYER GAME',0	;1
	dc.b	'TWO PLAYER COMBAT',0	;2
	dc.b	0			;3 spacer/dotted line above PLAYER rows
	dc.b	'PLAYER 1 '
p1ctypec
	ifne	cd32
	dc.b	'CD32 PAD 1',0	;4, fixed 10-char field
	elseif
	dc.b	'KEYBMOUSE  ',0		;4, fixed 10-char field
	endc
	;
	dc.b	'PLAYER 2 '
p2ctypec
	ifne	cd32
	dc.b	'CD32 PAD 2',0	;5, fixed 10-char field
	elseif
	dc.b	'JOYSTICK 1 ',0		;5, fixed 10-char field
	endc
	;
	dc.b	0			;6 spacer/dotted line above REMOTE LINK OPTIONS
	dc.b	'REMOTE LINK OPTIONS',0	;7
modetxtc	dc.b	'MEATY VIOLENCE MODE',0	;8
	dc.b	'ABOUT GLOOM',0		;9
	dc.b	'EXIT GLOOM',0		;10
	even

g2v190f_level_index dc 0

g2v190f_level_next
	move	g2v190i_level_count(pc),d1
	beq	g2v190f_level_update
	addq	#1,g2v190f_level_index
	move	g2v190f_level_index(pc),d0
	cmp	d1,d0
	bcs	g2v190f_level_update
	clr	g2v190f_level_index
	bra	g2v190f_level_update

g2v190f_level_prev
	move	g2v190i_level_count(pc),d1
	beq	g2v190f_level_update
	tst	g2v190f_level_index
	bne	.g2v190i_prevok
	subq	#1,d1
	move	d1,g2v190f_level_index
	bra	g2v190f_level_update
.g2v190i_prevok
	subq	#1,g2v190f_level_index
	bra	g2v190f_level_update

g2v190f_level_update
	movem.l	d0-d2/a0-a1,-(a7)
	tst	g2v190i_level_count
	bne	.g2v190i_have
	jsr	g2v190i_level_default
.g2v190i_have
	move	g2v190f_level_index(pc),d0
	cmp	g2v190i_level_count(pc),d0
	bcs	.g2v190i_idxok
	clr	g2v190f_level_index
	moveq	#0,d0
.g2v190i_idxok
	jsr	g2v190i_get_name_ptr
	lea	g2v190f_level_text(pc),a1
	moveq	#5,d1		; v190k: display field is MAPx.y, no brackets/trailing spaces
.g2v190i_copy
	move.b	(a0)+,d2
	beq.s	.g2v190i_copy_done
	move.b	d2,(a1)+
	dbf	d1,.g2v190i_copy
.g2v190i_copy_done
	clr.b	(a1)
	movem.l	(a7)+,d0-d2/a0-a1
	rts

g2v190f_level_start
	movem.l	d0/a0,-(a7)
	jsr	g2v190f_level_update
	move	g2v190f_level_index(pc),d0
	ext.l	d0
	move.l	d0,g2v190i_start_offset	; v190t: number of earlier play_ entries to skip
	clr.l	map_test			; no single-map test mode, continue with next script level
	movem.l	(a7)+,d0/a0
	rts

; v190i dynamic title-screen level select.  The list is built from the
; first available script file before the title menu is shown.  It recognises
; play_<mapname> lines and stores the playable maps in script order.
g2v190i_level_loaded dc 0
g2v190i_level_count dc 0
g2v190i_start_offset dc.l -1	; v190t: play_ skip counter for levelselect, -1 = none
g2v190i_scriptbuf dc.l 0	; kept for compatibility, no longer used by v190n static script loader
g2v190t_reload_pic_after_level dc 0	; v190t: reload current intermission IFF after gameplay
g2v190t_lastpicname ds.b 64	; v190t: base intermission picture path without .pal
	even

g2v190i_levelselect_loadscripts
	tst	g2v190i_level_loaded
	bne	.rts
	move	#-1,g2v190i_level_loaded
	clr	g2v190i_level_count
	clr	g2v190f_level_index
	bsr	permit
	lea	g2v190i_script_misc(pc),a0
	bsr	g2v190i_try_script
	tst	g2v190i_level_count
	bne	.doneio
	lea	g2v190i_script_stuf(pc),a0
	bsr	g2v190i_try_script
	tst	g2v190i_level_count
	bne	.doneio
	lea	g2v190i_script_stages(pc),a0
	bsr	g2v190i_try_script
	tst	g2v190i_level_count
	bne	.doneio
	lea	g2v190i_script_gd_misc(pc),a0
	bsr	g2v190i_try_script
	tst	g2v190i_level_count
	bne	.doneio
	lea	g2v190i_script_gd_stuf(pc),a0
	bsr	g2v190i_try_script
	tst	g2v190i_level_count
	bne	.doneio
	lea	g2v190i_script_gd_stages(pc),a0
	bsr	g2v190i_try_script
.doneio
	bsr	forbid
	tst	g2v190i_level_count
	bne	.update
	jsr	g2v190i_level_default
.update
	jsr	g2v190f_level_update
.rts	rts

g2v190i_try_script
	; v190n: read script into a bounded static buffer instead of using
	; loadfile/allocmem.  The old temporary allocation was safe most of the
	; time, but the title return artefact strongly points at a memlist/
	; overread side-effect.  This path never writes outside the fixed buffer
	; and always zero-terminates before parsing.
	movem.l	d0-d3/d7/a0/a6,-(a7)
	move.l	dosbase,a6
	move.l	a0,d1
	move.l	#1005,d2
	jsr	-30(a6)		; Open(oldfile)
	move.l	d0,d7
	beq.s	.done
	move.l	d7,d1
	lea	g2v190i_script_static,a0
	move.l	a0,d2
	move.l	#g2v190i_script_static_size-1,d3
	jsr	-42(a6)		; Read(handle, buffer, size-1)
	move.l	d0,d3
	move.l	d7,d1
	jsr	-36(a6)		; Close(handle)
	tst.l	d3
	ble.s	.done
	lea	g2v190i_script_static,a0
	clr.b	0(a0,d3.w)	; guaranteed terminator for parser
	jsr	g2v190i_parse_script
.done
	movem.l	(a7)+,d0-d3/d7/a0/a6
	rts

g2v190i_parse_script
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	a0,a6
.loop
	move.b	(a6),d0
	beq	.done
	cmp.b	#13,d0
	beq	.advance
	cmp.b	#10,d0
	beq	.advance
	cmp.b	#' ',d0
	beq	.advance
	cmp.b	#9,d0
	beq	.advance
	cmp.b	#';',d0
	beq	.skipline
	cmp.b	#'d',d0
	bne	.notdone
	cmp.b	#'o',1(a6)
	bne	.notdone
	cmp.b	#'n',2(a6)
	bne	.notdone
	cmp.b	#'e',3(a6)
	bne	.notdone
	cmp.b	#'_',4(a6)
	beq	.done
.notdone
	cmp.b	#'p',d0
	bne	.skipline
	cmp.b	#'l',1(a6)
	bne	.skipline
	cmp.b	#'a',2(a6)
	bne	.skipline
	cmp.b	#'y',3(a6)
	bne	.skipline
	cmp.b	#'_',4(a6)
	bne	.skipline
	move.l	a6,a5		; v190r: remember script command start for chain entry
	lea	5(a6),a0
	jsr	g2v190i_add_level
.skipline
	move.b	(a6)+,d0
	beq	.done
	cmp.b	#10,d0
	bne	.skipline
	bra	.loop
.advance
	addq.l	#1,a6
	bra	.loop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2v190i_level_default
	move.l	a0,-(a7)
	sub.l	a5,a5		; v190r: fallback entry has no script offset
	lea	g2v190i_default_map(pc),a0
	jsr	g2v190i_add_level
	move.l	(a7)+,a0
	rts

g2v190i_add_level ; a0 = map name after play_, terminated by CR/LF/0
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	a0,a4		; source map name from script line
	move	g2v190i_level_count(pc),d0
	cmp	#g2v190i_max_levels,d0
	bcc	.rts
	move.l	#-1,d7		; v190r: default no script offset
	tst.l	a5
	beq.s	.g2v190r_no_offset
	move.l	a5,d7
	sub.l	#g2v190i_script_static,d7
.g2v190r_no_offset
	move	d0,d1
	ext.l	d0
	lsl.l	#2,d0
	lea	g2v190i_level_offsets,a3
	add.l	d0,a3
	move.l	d7,(a3)		; store play_ command offset for continuing chain
	move	d1,d0
	jsr	g2v190i_get_name_ptr_d1
	move.l	a0,a1		; name field
	move	d1,d0
	jsr	g2v190i_get_path_ptr
	move.l	a0,a2		; path field
	; clear display field to zeroes; menu display is copied without trailing spaces
	move.l	a1,a3
	moveq	#0,d2
	moveq	#15,d3
.clrname
	move.b	d2,(a3)+
	dbf	d3,.clrname
	; path starts with maps/
	lea	g2v190i_map_prefix(pc),a3
.pfx
	move.b	(a3)+,d2
	move.b	d2,(a2)+
	bne	.pfx
	subq.l	#1,a2
	moveq	#0,d3		; visible chars copied
	moveq	#58,d4		; remaining path chars before null
.copy
	move.b	(a4)+,d2
	beq	.donecopy
	cmp.b	#13,d2
	beq	.donecopy
	cmp.b	#10,d2
	beq	.donecopy
	tst	d4
	beq	.nopath
	move.b	d2,(a2)+
	subq	#1,d4
.nopath
	cmp	#16,d3
	bcc	.copy
	move.b	d2,d5
	cmp.b	#'_',d5
	bne.s	.g2v190k_notunderscore
	move.b	#'.',d5		; v190k: display MAP1.7 instead of MAP1_7
	bra.s	.noupper
.g2v190k_notunderscore
	cmp.b	#'a',d5
	bcs	.noupper
	cmp.b	#'z',d5
	bhi	.noupper
	sub.b	#32,d5
.noupper
	move.b	d5,(a1)+
	addq	#1,d3
	bra	.copy
.donecopy
	clr.b	(a2)
	addq	#1,g2v190i_level_count
.rts
	movem.l	(a7)+,d0-d7/a0-a4
	rts

g2v190i_get_name_ptr ; d0.w = index, returns a0
	lea	g2v190i_level_names,a0
	ext.l	d0
	lsl.l	#4,d0
	add.l	d0,a0
	rts

g2v190i_get_name_ptr_d1 ; d1.w = index, returns a0 and preserves d1
	move	d1,d0
	bra	g2v190i_get_name_ptr

g2v190i_get_path_ptr ; d0.w = index, returns a0
	lea	g2v190i_level_paths,a0
	ext.l	d0
	lsl.l	#6,d0
	add.l	d0,a0
	rts

g2v190i_get_offset_ptr ; d0.w = index, returns a0 -> script offset long
	lea	g2v190i_level_offsets,a0
	ext.l	d0
	lsl.l	#2,d0
	add.l	d0,a0
	rts

g2v190i_script_misc dc.b 'misc/script',0
g2v190i_script_stuf dc.b 'stuf/script',0
g2v190i_script_stages dc.b 'stuf/stages',0
g2v190i_script_gd_misc dc.b 'gloomdata:misc/script',0
g2v190i_script_gd_stuf dc.b 'gloomdata:stuf/script',0
g2v190i_script_gd_stages dc.b 'gloomdata:stuf/stages',0
g2v190i_map_prefix dc.b 'maps/',0
g2v190i_default_map dc.b 'map1_1',0
	even

g2v190i_script_static_size equ 4096
g2v190i_max_levels equ 64

g2v158_title_credit	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

startmenu2	dc.b	5
	dc.b	'TWO PLAYER GAME',0	;0
	dc.b	'TWO PLAYER COMBAT GAME',0	;1
	dc.b	'UNLINK FROM REMOTE PLAYER',0	;2
	dc.b	'ABOUT GLOOM',0		;3
	dc.b	'EXIT GLOOM',0		;4
	even

menuwindow	dc.l	0
menubmap	dc.l	0

menuy	dc	0
numopts	dc	0	;how many menu options
curropt	dc	0	;current option
flashdelay	dc	0

menustrips	ds.l	32	;16 max!

qmenu	;quick menu in a0
	;on black screen
	;
	move.l	a0,-(a7)
	bsr	clspic
	move.l	(a7)+,a4
	bsr	initmenu
	bra	dispon

pmenu	;a0=iff, a1=palette, a2=menu
	;display off
	move.l	a2,-(a7)
	bsr	showpic
	move.l	(a7)+,a4
	bsr	initmenu
	bra	dispon

finitpmenu	;
finitqmenu	bsr	dispoff
	bra	finitmenu

; v147: soft menu teardown for title/about transitions.
; Frees menu strips and restores the font palette without clearing the
; full picture or switching the display off, so ABOUT can open/close
; without the previous visible flash.
g2v147_finitmenu_soft
	lea	menustrips(pc),a5
	move	numopts(pc),d2
	beq.s	.nostrips
	subq	#1,d2
.loop	addq	#4,a5
	move.l	(a5)+,a1
	freemem	menustrip
	dbf	d2,.loop
.nostrips	clr	numopts
	bra	finitfontpal

; v147: redraw a picture/menu pair without the showpic clear/dispoff path.
g2v147_pmenu_soft	;a0=iff, a1=palette, a2=menu
	move.l	a2,-(a7)
	bsr	showpic_noclear
	move.l	(a7)+,a4
	bsr	initmenu
	bra	dispon

g2v190cs_pmenu_precomposed	;a2=menu, title/overlay already present in show/draw bitmaps
	move.l	a2,a4
	bsr	initmenu
	bra	dispon

swapshow	movem.l	showbitmap(pc),d0-d1
	exg	d0,d1
	movem.l	d0-d1,showbitmap
	rts

finitfontpal	bra	pokelastpal

initfontpal	move.l	font(pc),a1
	add.l	(a1),a1
	move	(a1),-(a7)
	clr	(a1)
	; v107: bigfont2/smallfont2 are normal 4-colour 12-bit font
	; palettes.  Native AGA/OS-AGA palette pokers expect paired high/low
	; nibble words per colour, so convert the four 12-bit colours to
	; high-word + zero-low-word pairs before poking.  ECS remains unchanged.
	tst	aga
	beq.s	.normal12
	bsr.s	initfontpal_aga12
	bra.s	.restore12
.normal12	moveq	#4,d0
	bsr	pokepal2
.restore12	move.l	font(pc),a1
	add.l	(a1),a1
	move	(a7)+,(a1)
	rts

initfontpal_aga12	lea	fontpal_aga12,a0
	moveq	#3,d1
.loop	move	(a1)+,(a0)+	;high nibble/normal 12-bit colour
	clr	(a0)+		;low nibble = 0, makes font colours stable yellow on AGA
	dbf	d1,.loop
	lea	fontpal_aga12,a1
	moveq	#4,d0
	bsr	pokepal2
	rts

fontpal_aga12	ds.w	8	;v107 temporary 4-colour AGA high/low palette pairs

initmenu	clr	curropt
initmenu2	;
	;do a menu...menu in a4
	;
	bsr	copypic	;copy shown to draw
	bsr	swapshow
	; v190gl: Classic Gloom menu uses Gloom2-compatible bigfont2 now.
	bsr	initfontpal
	;
	move.b	(a4)+,d0	;how many
	ext	d0
	move	d0,numopts
	move	d0,-(a7)	;counter
	move	bmaphite(pc),d6	;bitmap hite
	move.l	showbitmap(pc),menubmap
	lsr	#1,d6
	move	fonth(pc),d2
	lsr	#1,d2
	mulu	d2,d0
	sub	d0,d6	;Y
	; v158: keep the v155 title-menu vertical layout, brighten the
	; separator lines a little, and add a centred footer credit in the
	; last black row below the image on title menus only.
	clr	g2v154_titlemenu_lines
	clr	g2v158_titlemenu_credit
	cmp.l	#startmenu+1,a4
	beq.s	.titlemenu_main
	cmp.l	#compat_startmenu+1,a4
	beq.s	.titlemenu_compat
	cmp.l	#startmenu2+1,a4
	beq.s	.titlemenu_y
	cmp.l	#gamemenu+1,a4
	bne.s	.titlemenu_y_done
	sub	fonth(pc),d6	; v186: move the in-game menu one full row higher
	bra.s	.titlemenu_y_done
.titlemenu_y	sub	fonth(pc),d6
	sub	fonth(pc),d6
	bra.s	.titlemenu_y_done
.titlemenu_main	move	#-1,g2v154_titlemenu_lines
	sub	fonth(pc),d6
	sub	fonth(pc),d6	; v190hq: Gloom Deluxe title menu one row lower again
	bra.s	.titlemenu_y_done
.titlemenu_compat	move	#2,g2v154_titlemenu_lines	; v190hb: compat menus keep dotted lines and move whole block two rows up
	sub	fonth(pc),d6	; v190hb: Gloom / Gloom3 / Zombie Massacre title menu up one row
	sub	fonth(pc),d6	; v190hb: Gloom / Gloom3 / Zombie Massacre title menu up second row
.titlemenu_y_done
	move	d6,menuy
	lea	menustrips(pc),a5
	;
.loop	;save strip!
	;
	move.l	a4,(a5)+
	;
	move	fonth(pc),d0
	mulu	#40,d0
	mulu	bitplanes(pc),d0
	moveq	#2,d1
	allocmem	menustrip
	move.l	d0,(a5)+
	move.l	d0,a1	;strip address
	;
	move	d6,d0
	mulu	linemodw(pc),d0
	move.l	menubmap(pc),a0
	add.l	d0,a0	;src
	;
	move	bitplanes(pc),d0
	subq	#1,d0
.sloop	move.l	a0,-(a7)
	move	fonth(pc),d1
	subq	#1,d1
.sloop2	move.l	a0,-(a7)
	moveq	#9,d2
.sloop3	move.l	(a0)+,(a1)+
	dbf	d2,.sloop3	;width
	move.l	(a7)+,a0
	add.l	linemod(pc),a0
	dbf	d1,.sloop2	;hite
	move.l	(a7)+,a0
	add.l	bpmod(pc),a0
	dbf	d0,.sloop	;depth
	;
	move.l	a4,a0
	moveq	#-1,d0
.cnt	addq	#1,d0
	tst.b	(a0)+
	bne.s	.cnt
	;
	jsr	printmess2
	;
	add	fonth(pc),d6
	subq	#1,(a7)
	bgt.s	.loop
	addq	#2,a7
	;
	ifne	debugmem
	bsr	showmem
	lea	memasc,a4
	moveq	#8,d0
	jsr	printmess2
	;
	move.l	freememerr,d0
	beq.s	.nomemerr
	clr.l	freememerr
	move.l	d0,a4
	move.l	d0,a0
	moveq	#-1,d0
.ccloop	addq	#1,d0
	tst.b	(a0)+
	bne.s	.ccloop
	add	fonth(pc),d6
	jsr	printmess2
.nomemerr	;
	endc
	;
	tst	g2v154_titlemenu_lines
	beq.s	.g2v154_no_title_lines
	bsr	g2v154_draw_titlemenu_lines
.g2v154_no_title_lines
	tst	g2v158_titlemenu_credit
	beq.s	.g2v158_no_title_credit
	bsr	g2v158_draw_title_credit
.g2v158_no_title_credit
	bsr	swapshow
	bsr	db
	bra	vwait

; v163: draw two thin 80px dotted separators into the blank title-menu
; rows, 1px higher than v154: one between TWO PLAYER COMBAT and PLAYER 1,
; one between PLAYER 2 and REMOTE LINK OPTIONS. Each dot uses a slightly
; brighter yellow from the existing palette, while every second pixel stays
; transparent so the title image remains visible in between.
g2v154_draw_titlemenu_lines
	movem.l	d0-d7/a0-a2,-(a7)
	move.l	showbitmap(pc),a0
	move	menuy(pc),d0
	move	fonth(pc),d1
	move	d1,d2
	lsr	#1,d2
	moveq	#3,d3	; v190hr: Gloom Deluxe dotted separator one row higher
	cmp	#2,g2v154_titlemenu_lines
	bne.s	.g2v190cp_line1row_ok
	moveq	#3,d3
.g2v190cp_line1row_ok
	mulu	d1,d3
	add	d3,d0
	add	d2,d0
	subq	#1,d0
	bsr.s	g2v154_draw_one_title_line
	move	menuy(pc),d0
	move	fonth(pc),d1
	move	d1,d2
	lsr	#1,d2
	moveq	#6,d3	; v190hr: Gloom Deluxe dotted separator one row higher
	cmp	#2,g2v154_titlemenu_lines
	bne.s	.g2v190cp_line2row_ok
	moveq	#6,d3
.g2v190cp_line2row_ok
	mulu	d1,d3
	add	d3,d0
	add	d2,d0
	subq	#1,d0
	bsr.s	g2v154_draw_one_title_line
	movem.l	(a7)+,d0-d7/a0-a2
	rts

g2v154_draw_one_title_line	; d0=Y, a0=bitmap base
	movem.l	d0-d5/a1-a2,-(a7)
	move	d0,d1
	mulu	linemodw(pc),d1
	move.l	a0,a1
	add.l	d1,a1
	adda.w	#15,a1		;x=120, centred 80px line -> 10 bytes
	move	bitplanes(pc),d5
	beq.s	.done
	subq	#1,d5
	moveq	#0,d2
.plane	move.l	a1,a2
	move.l	bpmod(pc),d0
	mulu	d2,d0
	add.l	d0,a2
	cmpi	#1,d2
	beq.s	.plane1
	moveq	#9,d1
.clearbyte	andi.b	#$55,(a2)+	; keep every second pixel transparent on all other planes
	dbf	d1,.clearbyte
	bra.s	.nextplane
.plane1	moveq	#9,d1
.setbyte	ori.b	#$AA,(a2)+	; set every other pixel on plane 1 -> slightly brighter yellow dots
	dbf	d1,.setbyte
.nextplane	addq	#1,d2
	dbf	d5,.plane
.done	movem.l	(a7)+,d0-d5/a1-a2
	rts

g2v158_draw_title_credit
	movem.l	d0-d1/a4,-(a7)
	lea	g2v158_title_credit(pc),a4
	moveq	#-1,d0
.g2v158_len	addq	#1,d0
	tst.b	(a4,d0.w)
	bne.s	.g2v158_len
	move	bmaphite(pc),d6
	sub	fonth(pc),d6	; last visible text row at the bottom
	jsr	printmess2
	movem.l	(a7)+,d0-d1/a4
	rts

; v160: ABOUT-screen footer draw.  The credit is no longer shown on the
; title screen because it caused display artefacts there.
g2v160_draw_about_credit_boot
	bsr	g2v158_draw_title_credit
	bsr	db
	bra	vwait

g2v154_titlemenu_lines	dc	0
g2v158_titlemenu_credit	dc	0

minmem	dc.l	$7fffffff

	ifne	debugmem
	;
showmem	push
	move.l	4.w,a6
	move.l	#$20001,d1
	jsr	-216(a6)
	cmp.l	minmem(pc),d0
	bge.s	.notmin
	move.l	d0,minmem
.notmin	move.l	minmem(pc),d0
	;
	lea	memasc,a0
	moveq	#7,d1
.loop	rol.l	#4,d0
	move	d0,d2
	and	#15,d2
	add	#48,d2
	cmp	#58,d2
	bcs.s	.skip
	addq	#7,d2
.skip	move.b	d2,(a0)+
	dbf	d1,.loop
	pull
	rts
	;
memasc	dc.b	'12345678',0
	even
	endc

optoff	;
	bsr	ownblitter
	move	curropt(pc),d6
	lea	menustrips(pc),a0
	move.l	4(a0,d6*8),a0	;address of strip
	mulu	fonth(pc),d6
	add	menuy(pc),d6
	mulu	linemodw(pc),d6
	move.l	menubmap(pc),a1
	add.l	d6,a1	;dest
	;
	move	fonth(pc),d0
	lsl	#6,d0
	or	#20,d0
	;
	move	bitplanes(pc),d1
	subq	#1,d1
	;
	move	linemodw(pc),d2
	sub	#40,d2
	;
	btst	#6,$dff002
.bwait0	btst	#6,$dff002
	bne.s	.bwait0
	;
	move.l	#$9f00000,$dff040	;D=A
	move.l	#-1,$dff044
	move	#0,$dff064
	move	d2,$dff066	;d mod
	move.l	a0,$dff050
	;
.loop	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.s	.bwait
	;
	move.l	a1,$dff054
	move	d0,$dff058
	add.l	bpmod(pc),a1
	dbf	d1,.loop
	;
	move	#13,flashdelay
	;
	bra	disownblitter

opton	move	curropt(pc),d6
	lea	menustrips(pc),a0
	move.l	0(a0,d6*8),a4	;text!
	mulu	fonth(pc),d6
	add	menuy(pc),d6
	;
	;a6=window, a4=message, d0=length of message, d6=Y
	;
	move.l	a4,a0
	moveq	#-1,d0
.loop	addq	#1,d0
	tst.b	(a0)+
	bne.s	.loop
	;
	move.l	menuwindow(pc),a6
	jsr	printmess2
	;
	move	#13,flashdelay
	;
	rts

readmenujoy	;encode to d0!
	;
	;OK, read joystick in port 2, and keyboard!
	;merge into joyx,joyy,joyb
	;
	tst	active
	bne.s	.doit
	lea	joyx,a0
	clr.l	(a0)
	clr.l	4(a0)
	moveq	#0,d0
	rts
.doit	lea	joyx,a0
	bsr	readjoy1
	lea	joyx0,a0
	bsr	readkeys
	move.l	joyx0(pc),d0
	or.l	d0,joyx
	move.l	joyb0(pc),d0
	or.l	d0,joyb
	;
	qkey	$45
	beq.s	.noesc
	tst	game_menu_active
	beq.s	.noesc
	moveq	#$20,d0	;v115 ESC cancels/back in game menu only
	rts
.noesc	qkey	$44
	bne.s	.fire
	bra.s	.encode
.fire	move	#-1,joyb
.encode	lea	joyx,a0
	jsr	encodejoy
	tst	game_menu_active
	beq.s	.normal_menu_mask
	and	#$1f,d0	;v115 game menu: left/right/up/down/fire
	rts
.normal_menu_mask	and	#$1f,d0	;v166 allow title PLAYER rows to see left/right
	rts

	;bit:
	;0 = joyx -1
	;1 = joyx 1
	;2 = joyy -1
	;3 = joyy 1
	;4 = joyb true
	;5 = joys true

unselmenu	move	d0,-(a7)
.loop	bsr	readmenujoy
	cmp	(a7),d0
	beq.s	.loop
	move	(a7)+,d0
	rts

readmenusel	;read menu selection!
	tst	linked
	bne.s	.link
	;
	;not linked...
	;
	bsr	readmenujoy
	bne	unselmenu
	rts
	;
.link	bmi.s	.slave
	;
	;master...
	;
	bsr	readmenujoy
	beq.s	.rts
	bsr	unselmenu
	bsr	serput
	bsr	serwait
	and	#255,d0
.rts	rts
	;
.slave	bsr	rbfchk
	beq.s	.rts
	bsr	serget
	bsr	serput
	and	#255,d0
	rts

menuskip	;return EQ if current item is a visual spacer/empty row
	move	curropt(pc),d0
	lea	menustrips(pc),a0
	move.l	0(a0,d0*8),a0
	move.b	(a0),d0
	beq.s	.rts
	cmp.b	#92,d0
.rts	rts

selmenu	;select a menu item...return item in d0
	;
	;flash selected option on/off
	;
	bsr	optoff
.loop1	bsr	vwait
	bsr	readmenusel
	bne.s	.joygot
	subq	#1,flashdelay
	bgt.s	.loop1
	;
	bsr	opton
.loop2	bsr	vwait
	bsr	readmenusel
	bne.s	.joygot2
	subq	#1,flashdelay
	bgt.s	.loop2
	bra	selmenu
	;
.joygot	move	d0,-(a7)
	bsr	opton
	move	(a7)+,d0
.joygot2	;
	btst	#5,d0	;v115 ESC cancel/back in game menu
	beq.s	.noescsel
	moveq	#0,d0
	rts
.noescsel	btst	#0,d0
	bne.s	g2v166_sel_left
	btst	#1,d0
	bne.s	g2v166_sel_right
	btst	#2,d0
	bne	g2v166_sel_up
	btst	#3,d0
	bne	g2v166_sel_down
	;
	;selected!
	;
	bsr	menuskip	;v115 visual spacer rows are never selectable
	beq	g2v166_sel_down
	move	curropt(pc),d0
	rts
	;
g2v166_sel_left	tst	game_menu_active
	bne.s	g2v166_leftret
	bsr.s	g2v166_title_player_lr
	beq	selmenu
g2v166_leftret	move	curropt(pc),d0
	or	#$0100,d0
	rts
g2v166_sel_right	tst	game_menu_active
	bne.s	g2v166_rightret
	bsr.s	g2v166_title_player_lr
	beq	selmenu
g2v166_rightret	move	curropt(pc),d0
	or	#$0200,d0
	rts

g2v166_title_player_lr	; NE only on title START LEVEL / PLAYER rows
	move	numopts(pc),d1
	cmp	#13,d1
	beq.s	g2v166_tplr_full
	cmp	#11,d1
	beq.s	g2v166_tplr_compat
	bra.s	g2v166_tplr_no
g2v166_tplr_full
	move	curropt(pc),d1
	cmp	#0,d1
	beq.s	g2v166_tplr_yes
	cmp	#6,d1
	beq.s	g2v166_tplr_yes
	cmp	#7,d1
	beq.s	g2v166_tplr_yes
	bra.s	g2v166_tplr_no
g2v166_tplr_compat
	move	curropt(pc),d1
	cmp	#4,d1
	beq.s	g2v166_tplr_yes
	cmp	#5,d1
	beq.s	g2v166_tplr_yes
g2v166_tplr_no	moveq	#0,d1
	rts
g2v166_tplr_yes	moveq	#1,d1
	rts

g2v166_sel_up	subq	#1,curropt
	bpl.s	g2v166_upchk
	move	numopts(pc),d0
	subq	#1,d0
	move	d0,curropt
g2v166_upchk	bsr	menuskip
	beq.s	g2v166_sel_up
	bra	selmenu
	;
g2v166_sel_down	addq	#1,curropt
	move	curropt(pc),d0
	cmp	numopts(pc),d0
	bcs.s	g2v166_downchk
	clr	curropt
g2v166_downchk	bsr	menuskip
	beq.s	g2v166_sel_down
	bra	selmenu

finitmenu	;clean up menu operation
	;
	bsr	clspic
	bsr	vwait
	lea	menustrips(pc),a5
	move	numopts(pc),d2
	subq	#1,d2
.loop	addq	#4,a5
	move.l	(a5)+,a1
	freemem	menustrip
	dbf	d2,.loop
	bra	finitfontpal

initdarktable	;
	; v190fc: shared darktable/fog table from the confirmed smooth path.
	; It reaches full fog at its 8-width table end; DEFAULT scales back
	; into the original short range, while ADVANCED scales 16 actual widths
	; into this smooth 8-width table.
	move	#maxz-1,d2
	move.l	sqr(pc),a0
	move.l	darktable(pc),a1
	;
.loop	move	d2,d3
	lsl	#3,d3
	move	0(a0,d3),d3
	lsr	#3,d3
	eor	#15,d3	; original shade 0..15
	;
	; Distance for the table entry.  The original loop fills darktable
	; backwards: table index 0 is near, index maxz-1 is far.
	move	#maxz-1,d4
	sub	d2,d4	; d4 = real distance index
	;
	; General one-step darker look, clipped to the darkest shade.
	cmp	#15,d3
	bcc.s	.g2v190aq_farboost
	addq	#1,d3
	;
.g2v190aq_farboost
	; From about four texture widths start a stronger fog ramp.
	cmp	#(4<<grdshft),d4
	blo.s	.g2v190aq_store
	;
	; v190ey: table cap remains the v190ew 8-width endpoint.
	cmp	#g2deffogfar,d4
	blo.s	.g2v190aq_ramp
	moveq	#14,d3
	bra.s	.g2v190aq_store
	;
.g2v190aq_ramp
	move	d4,d5
	sub	#(4<<grdshft),d5
	lsr	#7,d5	; v190ey: 0..7 extra darkness spread across 4..8 widths
	add	d5,d3
	cmp	#14,d3
	bls.s	.g2v190aq_store
	moveq	#14,d3
	;
.g2v190aq_store
	; In the far fog zone clamp the result to shade 14 so distant
	; geometry stays uniformly very dark instead of collapsing to pure black.
	cmp	#(4<<grdshft),d4
	blo.s	.g2v190aq_store2
	cmp	#14,d3
	bls.s	.g2v190aq_store2
	moveq	#14,d3
.g2v190aq_store2
	move	d3,(a1)+
	;
	dbf	d2,.loop
	;
	rts

initrawmap	lea	ascmap(pc),a0
	lea	rawmap(pc),a1
	bsr	.loop
	lea	ascmap2(pc),a0
	lea	shiftmap(pc),a1
	;
.loop	moveq	#0,d0
	move.b	(a0)+,d0
	cmp	#$ff,d0
	beq.s	.rts
.loop2	move.b	(a0)+,d1
	beq.s	.loop
	move.b	d1,0(a1,d0)
	addq	#1,d0
	bra.s	.loop2
.rts	rts

ascmap	dc.b	$1,'1234567890',0
	dc.b	$10,'QWERTYUIOP',0
	dc.b	$20,'ASDFGHJKL',0
	dc.b	$31,'ZXCVBNM',0
	dc.b	$40,' ',0
	dc.b	$38,',.',0
	dc.b	$ff
	even
	;
ascmap2	dc.b	$3a,'?',0
	dc.b	$01,'!',0
	dc.b	$ff
	even

rawmap	ds.b	128	;unshifted chars
shiftmap	ds.b	128	;shifted chars

chatout	ds.b	32
chatoutput	dc	0
chatoutget	dc	0

chatin	ds.b	32
chatinput	dc	0
chatinget	dc	0

shiftdown	dc	0	;shift key status

rawkeyread	;a1=matrix! hi bit of keycode=1 if key up!
	;
	move.l	d2,-(a7)
	;
	moveq	#0,d2
	move.b	$bfec01,d2
	not.b	d2
	ror.b	#1,d2
	or.b	#$40,$bfee01
	;
	move	d2,d0
	move	d2,d1
	and	#7,d1
	lsr	#3,d0
	bclr	#4,d0
	bne.s	.clrkey
	;
.setkey	bset	d1,0(a1,d0)	;key on!
	bsr	wasd_keydown_update
	;
	move	chatok(pc),d0
	beq.s	.skip
	;
	lea	rawmap(pc),a0
	move.b	$60>>3(a1),d0
	and	#7,d0
	beq.s	.unshft
	lea	shiftmap(pc),a0
.unshft	move.b	0(a0,d2),d0	;asc!
	beq.s	.skip
	;
	;ok, add to chat out buffer!
	;
	lea	chatout,a0
	move	chatoutput,d1
	and	#31,d1
	move.b	d0,0(a0,d1)
	addq	#1,chatoutput
	;
	bra.s	.skip
	;
.clrkey	bclr	d1,0(a1,d0)
	bsr	wasd_keyup_update
	;
.skip	moveq	#6,d0	;wait 6 scanlines?
	moveq	#-1,d1
.loop	move	d1,d2
.loop2	move.l	$dff004,d1
	lsr.l	#8,d1
	and	#$1ff,d1
	cmp	d2,d1
	beq.s	.loop2
	dbf	d0,.loop
	;
	and.b	#$bf,$bfee01
	;
	move.l	(a7)+,d2
	rts

rawtable	dc.l	rawmatrix
rawstuff	dc.l	0,0
ciaa	dc.l	0
ciaaname	dc.b	'ciaa.resource',0
	even
rawmatrix	dc.l	0,0,0,0	;128 key bits
wasd_state	dc.b	0	;bit1 W, bit2 A, bit3 X(back), bit4 D for KEYBMOUSE
	even

wasd_keydown_update	;maintain KEYBMOUSE WAXD state from raw keyboard events
	movem.l	d0-d3/a0,-(a7)
	move.w	d2,d3
	and.w	#$7f,d3
	bsr	wasd_map_rawcode
	tst.w	d0
	beq.s	.wkdu_done
	bset	d0,wasd_state
.wkdu_done	movem.l	(a7)+,d0-d3/a0
	rts

wasd_keyup_update	;clear KEYBMOUSE WAXD state from raw keyboard events
	movem.l	d0-d3/a0,-(a7)
	move.w	d2,d3
	and.w	#$7f,d3
	bsr	wasd_map_rawcode
	tst.w	d0
	beq.s	.wkuu_done
	bclr	d0,wasd_state
.wkuu_done	movem.l	(a7)+,d0-d3/a0
	rts

wasd_map_rawcode	;d3.w rawcode -> d0.w bit number, 0 if not WAXD
	cmp.w	#$11,d3	; W = forward
	beq.s	.wmap_w
	cmp.w	#$20,d3	; A = strafe left
	beq.s	.wmap_a
	cmp.w	#$32,d3	; X = backward
	beq.s	.wmap_x
	cmp.w	#$22,d3	; D = strafe right
	beq.s	.wmap_d
	lea	rawmap,a0
	move.b	0(a0,d3.w),d0
	cmp.b	#'W',d0
	beq.s	.wmap_w
	cmp.b	#'A',d0
	beq.s	.wmap_a
	cmp.b	#'X',d0
	beq.s	.wmap_x
	cmp.b	#'D',d0
	beq.s	.wmap_d
	moveq	#0,d0
	rts
.wmap_w	moveq	#1,d0
	rts
.wmap_a	moveq	#2,d0
	rts
.wmap_x	moveq	#3,d0
	rts
.wmap_d	moveq	#4,d0
	rts

mousexlast	dc.b	0
	dc.b	0
mousexinit	dc	0
keymouse_mx	dc	0

; v22/v94: old OS/DOS diagnostic logger for crash hunting.
; v94 disables it on real Amiga hardware to avoid missing-volume requesters.
g2log_open
	rts	; v190aa: logger disabled after apostrophe diagnosis, avoid DH3 IO side effects
	movem.l	d0-d3/a0-a1/a6,-(a7)
	tst.l	g2loghand
	bne.s	.g2lo_done
	tst	os
	beq.s	.g2lo_done
	move.l	dosbase(pc),a6
	lea	g2logname(pc),a0
	move.l	a0,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,g2loghand
	beq.s	.g2lo_done
	lea	g2log_msg_open(pc),a0
	jsr	g2log
.g2lo_done
	movem.l	(a7)+,d0-d3/a0-a1/a6
	rts

g2log_drawstep	;a0 = marker, v27 writes every frame for crash pinpointing
	rts	;v94: logger disabled, keep call sites harmless
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2log
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2log_close
	rts	; v190aa: logger disabled after apostrophe diagnosis
	movem.l	d0-d1/a6,-(a7)
	move.l	g2loghand(pc),d1
	beq.s	.g2lc_done
	clr.l	g2loghand
	move.l	dosbase(pc),a6
	jsr	-36(a6)
.g2lc_done
	movem.l	(a7)+,d0-d1/a6
	rts

g2log	;a0 = zero terminated marker string
	rts	; v190aa: logger disabled after apostrophe diagnosis
	movem.l	d0-d3/a0-a1/a6,-(a7)
	; v190u: keep the trace file small.  Skip per-frame messages, but keep
	; script/mapload/intermission transition markers.
	cmp.l	#'MAIN',(a0)
	bne.s	.g2lg_not_main
	cmp.l	#'LOOP',4(a0)
	beq.s	.g2lg_done
.g2lg_not_main
	cmp.l	#'FINI',(a0)
	bne.s	.g2lg_not_finish
	cmp.l	#'SHED',4(a0)
	beq.s	.g2lg_done
.g2lg_not_finish
	tst	os
	beq.s	.g2lg_done
	move.l	g2loghand(pc),d1
	beq.s	.g2lg_done
	move.l	a0,a1
	moveq	#0,d3
.g2lg_len
	tst.b	(a1)+
	beq.s	.g2lg_len_done
	addq.l	#1,d3
	bra.s	.g2lg_len
.g2lg_len_done
	move.l	a0,d2
	move.l	dosbase(pc),a6
	jsr	-48(a6)
	move.l	g2loghand(pc),d1
	lea	g2log_nl(pc),a0
	move.l	a0,d2
	moveq	#1,d3
	move.l	dosbase(pc),a6
	jsr	-48(a6)
.g2lg_done
	movem.l	(a7)+,d0-d3/a0-a1/a6
	rts

g2logname	dc.b	'dh3:gloom.log',0	;v190u transition trace log
g2log_nl	dc.b	10
g2loghand	dc.l	0
g2logframe	dc	0
g2log_msg_open	dc.b	'G2LOG OPEN v190u',0

g2log_msg_script_done	dc.b	'SCRIPT DONE',0
g2log_msg_script_rest	dc.b	'SCRIPT REST',0
g2log_msg_script_loop	dc.b	'SCRIPT LOOP',0
g2log_msg_script_hide	dc.b	'SCRIPT HIDE',0
g2log_msg_script_show	dc.b	'SCRIPT SHOW',0
g2log_msg_script_draw	dc.b	'SCRIPT DRAW',0
g2log_msg_script_tile	dc.b	'SCRIPT TILE',0
g2log_msg_script_pict	dc.b	'SCRIPT PICT',0
g2log_msg_script_dark	dc.b	'SCRIPT DARK',0
g2log_msg_script_text	dc.b	'SCRIPT TEXT',0
g2log_msg_text_skip_fetch_b	dc.b	'TEXT SKIP FETCH BEFORE',0
g2log_msg_text_skip_fetch_ok	dc.b	'TEXT SKIP FETCH OK',0
g2log_msg_text_font_b	dc.b	'TEXT INITFONT BEFORE',0
g2log_msg_text_font_ok	dc.b	'TEXT INITFONT OK',0
g2log_msg_text_fetch_b	dc.b	'TEXT FETCH BEFORE',0
g2log_msg_text_fetch_ok	dc.b	'TEXT FETCH OK',0
g2log_msg_text_wrap_b	dc.b	'TEXT WRAP BEFORE',0
g2log_msg_text_wrap_ok	dc.b	'TEXT WRAP OK',0
g2log_msg_text_print1_b	dc.b	'TEXT PRINT SPLIT BEFORE',0
g2log_msg_text_print1_ok	dc.b	'TEXT PRINT SPLIT OK',0
g2log_msg_text_printf_b	dc.b	'TEXT PRINT FINAL BEFORE',0
g2log_msg_text_printf_ok	dc.b	'TEXT PRINT FINAL OK',0
g2log_msg_text_done	dc.b	'TEXT DONE',0
g2log_msg_script_wait	dc.b	'SCRIPT WAIT',0
g2log_msg_mapname	dc.b	'MAPNAME',0
g2log_msg_tiletag	dc.b	'TILETAG',0
g2log_msg_picname	dc.b	'PICNAME',0
g2log_msg_scriptplay	dc.b	'SCRIPTPLAY ENTER',0
g2log_msg_mapload_before	dc.b	'MAP LOAD BEFORE',0
g2log_msg_mapload_ok	dc.b	'MAP LOAD OK',0
g2log_msg_initmap_ok	dc.b	'INITMAP OK',0
g2log_msg_loadtxts_ok	dc.b	'LOADTXTS OK',0
g2log_msg_execevent_before	dc.b	'EXECEVENT BEFORE',0
g2log_msg_execevent_ok	dc.b	'EXECEVENT OK',0
g2log_msg_player_ok	dc.b	'PLAYER1 OK',0
g2log_msg_predraw_before	dc.b	'PREDRAW BEFORE',0
g2log_msg_predraw_ok	dc.b	'PREDRAW OK',0
g2log_msg_dispon_ok	dc.b	'DISPON CHATON OK',0
g2log_msg_mainloop	dc.b	'MAINLOOP DRAWALL BEFORE',0
g2log_msg_draw_ok	dc.b	'MAINLOOP DRAWALL OK',0
g2log_msg_after_draw	dc.b	'MAINLOOP AFTER DRAWALL LOG OK',0
g2log_msg_menu_before	dc.b	'MENU BEFORE',0
g2log_msg_menu_ok	dc.b	'MENU OK',0
g2log_msg_finish_check	dc.b	'FINISHED CHECK',0
g2log_msg_mainexit	dc.b	'MAINEXIT',0
g2log_msg_da_enter	dc.b	'DA ENTER',0
g2log_msg_da_wait_ok	dc.b	'DA WAIT OK',0
g2log_msg_da_calc1_b	dc.b	'DA CALC1 BEFORE',0
g2log_msg_da_calc1_ok	dc.b	'DA CALC1 OK',0
g2log_msg_da_draw1_b	dc.b	'DA DRAW1 BEFORE',0
g2log_msg_da_draw1_ok	dc.b	'DA DRAW1 OK',0
g2log_msg_da_blit1_b	dc.b	'DA BLIT1 BEFORE',0
g2log_msg_da_blit1_ok	dc.b	'DA BLIT1 OK',0
g2log_msg_da_calc2_b	dc.b	'DA CALC2 BEFORE',0
g2log_msg_da_calc2_ok	dc.b	'DA CALC2 OK',0
g2log_msg_da_draw2_b	dc.b	'DA DRAW2 BEFORE',0
g2log_msg_da_draw2_ok	dc.b	'DA DRAW2 OK',0
g2log_msg_da_blit2_b	dc.b	'DA BLIT2 BEFORE',0
g2log_msg_da_blit2_ok	dc.b	'DA BLIT2 OK',0
g2log_msg_da_wait2_b	dc.b	'DA WAIT2 BEFORE',0
g2log_msg_da_wait2_ok	dc.b	'DA WAIT2 OK',0
g2log_msg_da_doc2p_b	dc.b	'DA DOC2P BEFORE',0
g2log_msg_da_doc2p_ok	dc.b	'DA DOC2P OK',0
g2log_msg_da_db_b	dc.b	'DA DB BEFORE',0
g2log_msg_da_db_ok	dc.b	'DA DB OK',0
g2log_msg_da_exit	dc.b	'DA EXIT',0
g2log_msg_ds_enter	dc.b	'DS ENTER',0
g2log_msg_ds_cast_b	dc.b	'DS CAST BEFORE',0
g2log_msg_ds_cast_ok	dc.b	'DS CAST OK',0
g2log_msg_ds_render_b	dc.b	'DS RENDER BEFORE',0
g2log_msg_ds_render_ok	dc.b	'DS RENDER OK',0
g2log_msg_ds_roof_b	dc.b	'DS ROOF BEFORE',0
g2log_msg_ds_roof_ok	dc.b	'DS ROOF OK',0
g2log_msg_ds_floor_b	dc.b	'DS FLOOR BEFORE',0
g2log_msg_ds_floor_ok	dc.b	'DS FLOOR OK',0
g2log_msg_ds_shapes_b	dc.b	'DS SHAPES BEFORE',0
g2log_msg_ds_shapes_ok	dc.b	'DS SHAPES OK',0
g2log_msg_ds_blood_b	dc.b	'DS BLOOD BEFORE',0
g2log_msg_ds_blood_ok	dc.b	'DS BLOOD OK',0
g2log_msg_ds_pixel_b	dc.b	'DS PIXEL BEFORE',0
g2log_msg_ds_pixel_ok	dc.b	'DS PIXEL OK',0
g2log_msg_ds_exit	dc.b	'DS EXIT',0
	even

	even

; v141: small binary PROGDIR:gloom.cfg persistence.
; Header is exactly "GLMCFG" followed by a version word. v190eb writes version 3.
; Missing/bad files are ignored so defaults remain safe.
g2cfg_load
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	dosbase,a6
	lea	g2cfg_name(pc),a0
	move.l	a0,d1
	move.l	#1005,d2	;MODE_OLDFILE
	jsr	-30(a6)	;Open
	move.l	d0,d7
	beq	.load_done
	move.l	d7,d1
	lea	g2cfg_buf(pc),a0
	move.l	a0,d2
	move.l	#g2cfg_len,d3
	jsr	-42(a6)	;Read
	move.l	d0,d6
	move.l	d7,d1
	jsr	-36(a6)	;Close
	cmp.l	#g2cfg_len,d6
	beq.s	.len_ok
	cmp.l	#g2cfg_len_v2,d6
	beq.s	.len_ok
	cmp.l	#g2cfg_len_old,d6
	bne	.load_done
.len_ok	lea	g2cfg_buf(pc),a0
	cmp.l	#'GLMC',(a0)+
	bne	.load_done
	cmp.b	#'F',(a0)+
	bne	.load_done
	cmp.b	#'G',(a0)+
	bne	.load_done
	move	(a0)+,d7
	cmp	#1,d7
	beq.s	.version_ok
	cmp	#2,d7
	beq.s	.version_ok
	cmp	#3,d7
	bne	.load_done
.version_ok	move	(a0)+,width
	move	(a0)+,hite
	move	(a0)+,floorflag
	move	(a0)+,roofflag
	move	(a0)+,g2_blobshadow
	move	(a0)+,g2_reflections
	move	(a0)+,trainer_invincible
	move	(a0)+,trainer_bouncy
	move	(a0)+,trainer_weapon
	move	(a0)+,trainer_boost
	clr	trainer_onehit
	cmp	#2,d7
	blt.s	.no_onehit_old_cfg
	move	(a0)+,trainer_onehit
.no_onehit_old_cfg	move	#-1,g2_visibility	; v190eb: old cfg defaults to DEFAULT visibility
	cmp	#3,d7
	bne.s	.no_visibility_old_cfg
	move	(a0)+,g2_visibility
.no_visibility_old_cfg	bsr	g2cfg_sanitize
	bsr	g2cfg_apply_view
.load_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2cfg_save
	movem.l	d0-d7/a0-a6,-(a7)
	lea	g2cfg_buf(pc),a0
	move.l	#'GLMC',(a0)+
	move.b	#'F',(a0)+
	move.b	#'G',(a0)+
	move	#3,(a0)+
	move	width,(a0)+
	move	hite,(a0)+
	move	floorflag,(a0)+
	move	roofflag,(a0)+
	move	g2_blobshadow,(a0)+
	move	g2_reflections,(a0)+
	move	trainer_invincible,(a0)+
	move	trainer_bouncy,(a0)+
	move	trainer_weapon,(a0)+
	move	trainer_boost,(a0)+
	move	trainer_onehit,(a0)+
	move	g2_visibility,(a0)+
	move.l	dosbase,a6
	lea	g2cfg_name(pc),a0
	move.l	a0,d1
	move.l	#1006,d2	;MODE_NEWFILE
	jsr	-30(a6)	;Open
	move.l	d0,d7
	beq	.save_done	;silent fail, no requester/menu loop
	move.l	d7,d1
	lea	g2cfg_buf(pc),a0
	move.l	a0,d2
	move.l	#g2cfg_len,d3
	jsr	-48(a6)	;Write
	move.l	d7,d1
	jsr	-36(a6)	;Close
.save_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2cfg_sanitize
	; floor/ceiling/blob/reflection: positive YES, non-positive NO
	move	floorflag,d0
	bgt	.floor_yes
	move	#-1,floorflag
	bra	.floor_ok
.floor_yes	move	#1,floorflag
.floor_ok	move	roofflag,d0
	bgt	.roof_yes
	move	#-1,roofflag
	bra	.roof_ok
.roof_yes	move	#1,roofflag
.roof_ok	move	g2_blobshadow,d0
	bgt	.blob_yes
	move	#-1,g2_blobshadow
	bra	.blob_ok
.blob_yes	move	#1,g2_blobshadow
.blob_ok	move	g2_reflections,d0
	bgt	.refl_yes
	move	#-1,g2_reflections
	bra	.refl_ok
.refl_yes	move	#1,g2_reflections
.refl_ok	move	g2_visibility,d0
	bgt	.visibility_yes
	move	#-1,g2_visibility
	bra	.visibility_ok
.visibility_yes	move	#1,g2_visibility
.visibility_ok
	; cheats: zero OFF/DEFAULT, non-zero ON or 1..5
	tst	trainer_invincible
	beq	.inv_ok
	move	#-1,trainer_invincible
.inv_ok	tst	trainer_bouncy
	beq	.bouncy_ok
	move	#-1,trainer_bouncy
.bouncy_ok	tst	trainer_onehit
	beq	.onehit_ok
	move	#-1,trainer_onehit
.onehit_ok
	move	trainer_weapon,d0
	bpl	.weapon_pos
	clr	trainer_weapon
	bra	.weapon_ok
.weapon_pos	cmp	#5,d0
	ble	.weapon_ok
	move	#5,trainer_weapon
.weapon_ok	move	trainer_boost,d0
	bpl	.boost_pos
	clr	trainer_boost
	bra	.boost_ok
.boost_pos	cmp	#5,d0
	ble	.boost_ok
	move	#5,trainer_boost
.boost_ok
	; view size: accept only known safe sizes, otherwise FULLSCREEN
	move	width,d0
	cmp	#64,d0
	beq	.size64
	cmp	#96,d0
	beq	.size96
	cmp	#128,d0
	beq	.size128
	cmp	#160,d0
	beq	.size160
	cmp	#192,d0
	beq	.size192
	cmp	#224,d0
	beq	.size224
	cmp	#256,d0
	beq	.size256
	cmp	#288,d0
	beq	.size288
	cmp	#320,d0
	beq	.sizefull
	bra	.sizefull
.size64	move	#64,hite
	rts
.size96	move	#96,hite
	rts
.size128	move	#128,hite
	rts
.size160	move	#160,hite
	rts
.size192	move	#192,hite
	rts
.size224	move	#192,hite
	rts
.size256	move	#192,hite
	rts
.size288	move	#192,hite	;ALMOST FULL height = VERY HUGE
	rts
.sizefull	move	#320,width
	move	#240,hite
	rts

g2cfg_apply_view
	move	width,d0
	move	d0,chunkymodw
	lsr	#1,d0
	move	d0,maxx
	neg	d0
	move	d0,minx
	move	hite,d0
	lsr	#1,d0
	move	d0,maxy
	neg	d0
	move	d0,miny
	rts

g2cfg_name	dc.b	'PROGDIR:gloom.cfg',0
	even
g2cfg_len_old	equ	6+2+(10*2)
g2cfg_len_v2	equ	6+2+(11*2)
g2cfg_len	equ	6+2+(12*2)
g2cfg_buf	ds.b	g2cfg_len
	even

savefile	;a0=name, a1=mem, d0=length
	push
	;
	movem.l	d0/a0-a1,-(a7)
	;
	move.l	dosbase,a6
	move.l	a0,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,d7
	bne.s	.ok
	;
	lea	wpmess(pc),a0
	bsr	qmenu
	;
.help	bsr	vwait
	;
	movem.l	(a7),d0/a0-a1
	move.l	dosbase,a6
	move.l	a0,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq.s	.help
	;
	move.l	d7,-(a7)
	bsr	finitqmenu
	move.l	(a7)+,d7
	;
.ok	move.l	d7,d1
	movem.l	(a7)+,d0/a0-a1
	move.l	a1,d2
	move.l	d0,d3
	jsr	-48(a6)
	;
	move.l	d7,d1
	jsr	-36(a6)
	;
.done	pull
	rts

wpmess	dc.b	1
	dc.b	'please write enable the gloom data disk!',0
	even

fileheader	ds.b	14
loadmem	dc.l	0

loadfileabs	move.l	a1,loadmem
	bra.s	loadfile_

loadfile	clr.l	loadmem
	;
loadfile_	;a0=name, d1=memtype
	;
	;decrunch file if nec.
	;
	;return d0=pointer
	;
	push
	;
	move.l	d1,d5	;save memtype
	move.l	dosbase,a6
	;
	move.l	a0,d1
	move.l	#1005,d2
	jsr	-30(a6)	;open it!
	move.l	d0,d7	;handle
	beq	.err
	;
	move.l	d7,d1
	moveq	#0,d2
	moveq	#1,d3
	jsr	-66(a6)	;seek to end
	;
	move.l	d7,d1
	moveq	#0,d2
	moveq	#-1,d3	;seek to start
	jsr	-66(a6)
	;
	move.l	d0,d4	;length=prev filepos
	;
	move.l	d7,d1
	move.l	#fileheader,d2
	moveq	#14,d3
	jsr	-42(a6)	;read!
	;
	move.l	d0,-(a7)	;how many bytes read!
	;
	move.l	d7,d1
	moveq	#0,d2
	moveq	#-1,d3	;back to start
	jsr	-66(a6)
	;
	cmp.l	#14,(a7)+
	bcs.s	.nocrunch
	;
	moveq	#0,d6
	move.l	fileheader(pc),d0
	cmp.l	#'CrM2',d0
	beq.s	.crunch
	cmp.l	#'CrM!',d0
	bne.s	.nocrunch
	;
.crunch	cmp.l	fileheader+6(pc),d4 ;loadlen>destlen?
	bcc.s	.skip
	move.l	fileheader+6(pc),d4 ;length to allocate
.skip	;
	moveq	#14,d6
	add	fileheader+4(pc),d6
	bsr	loadit
	move.l	d0,a0	;src
	add.l	d6,d0	;dest
	move.l	d0,a1
	;
	jsr	flushc
	jsr	decrm+32
	jsr	flushc
	;
	pull
	rts
.nocrunch	;
	bsr	loadit
	;
.err	pull
	rts

loadit	;d4=length to alloc/read, d5=memtype
	;seek to start, load, close and return base in d0.
	;
	move.l	loadmem(pc),d0
	bne.s	.noalloc
	;
	move.l	d4,d0
	move.l	d5,d1
	move.l	d6,d2	;offset XS
	allocmem2	loadfile
	sub.l	d6,d0
.noalloc	;
	move.l	d7,d1
	move.l	d0,d2
	move.l	d4,d3	;read len
	jsr	-42(a6)	;read
	move.l	d7,d1
	jsr	-36(a6)	;close
	move.l	d2,d0
	;
	rts

calcpalettes	;generate 16 versions of palette
	;
	lea	paladjust,a5
	move.l	map_rgbsat(pc),a4	;end
	; v190gl: Classic Gloom receives embedded palette_8/remap_8 fallbacks,
	; so it can use the same fog/shade path as Gloom Deluxe.
	move.l	planar_remap(pc),a1	;remap table
	tst.l	a1
	bne.s	.g2v190cj_have_remap
.g2v190cj_no_remap
	; v190cj/v190cx: original Gloom lacks misc/remap_8; use safe identity
	; shade tables through paladjust, but still provide a synthetic remap for
	; special effects and transparent-object code that dereference the pointers.
	lea	palettes(pc),a2
	moveq	#15,d7
.g2v190cj_shade_loop
	move.l	(a2)+,a3
	moveq	#0,d0
	move	#255,d1
.g2v190cj_id_loop
	move.b	0(a5,d0.w),(a3)+
	addq	#1,d0
	dbf	d1,.g2v190cj_id_loop
	dbf	d7,.g2v190cj_shade_loop
	jsr	g2build_strip_luts
	rts
.g2v190cj_have_remap
	lea	palettes(pc),a2
	moveq	#0,d7		;darkness
	;
.loop	move.l	(a2)+,a3
	move.l	map_rgbs(pc),a0		;original RGBs
	;
.loop2	move	(a0)+,d0	;RGB value 0,1,2...
	move	d0,d1
	move	d0,d2
	;
	lsr	#8,d0
	and	#$00f,d0	;R
	sub	d7,d0
	bgt.s	.rok
	moveq	#1,d0
.rok	;
	lsr	#4,d1
	and	#$00f,d1
	sub	d7,d1
	bpl.s	.gok
	moveq	#0,d1
.gok	;
	and	#$00f,d2
	sub	d7,d2
	bpl.s	.bok
	moveq	#0,d2
.bok	;
	lsl	#8,d0	;recombine
	lsl	#4,d1
	or	d1,d0
	or	d2,d0	;correct 4bit RGB!
	;
	move.b	0(a1,d0),d0	;map from RGB->LUT
	and	#$ff,d0
	move.b	0(a5,d0),(a3)+	;scrambled adjust
	;
	cmp.l	a4,a0
	bcs.s	.loop2
	;
	addq	#1,d7
	cmp	#16,d7
	bcs.s	.loop
	;
	; v190ia: Gloom3/Zombie-Massacre palette data has a harder first
	; visible far-fog step than Gloom/Gloom Deluxe.  Keep the common
	; renderer/distance path untouched and only soften the two farthest
	; generated shade tables before the strip LUTs are rebuilt.
	jsr	g2v190ia_g3zm_farshade_fix
	; v190bz: rebuild chunky transparent-strip colour filter LUTs whenever
	; the level palette/shade palettes are regenerated.
	jsr	g2build_strip_luts
	rts

; -----------------------------------------------------------------------------
; v190ia: Gloom3/Zombie-Massacre far-fog shade-table correction
; -----------------------------------------------------------------------------
; Renderer, visibility distances and darktable stay identical to v190hw/v190hm.
; For profiles 2/3 only, move the two farthest shade tables one step darker:
;   shade 14 <- old shade 15
;   shade 13 <- old shade 14
; This gives ADVANCED its missing first dark transition without touching
; Gloom/Gloom Deluxe or the draw/cull/fog-distance code.

g2v190ia_g3zm_farshade_fix
	cmp	#2,g2_game_profile	; Zombie Massacre
	beq.s	.g2v190ia_do
	cmp	#3,g2_game_profile	; Gloom3/compat
	bne.s	.g2v190ia_done
.g2v190ia_do
	movem.l	d0/a0-a2,-(a7)
	lea	palettes(pc),a0
	move.l	13*4(a0),a1	; destination shade 13
	move.l	14*4(a0),a2	; old shade 14 source
	move	#255,d0
.g2v190ia_copy14_to_13
	move.b	(a2)+,(a1)+
	dbf	d0,.g2v190ia_copy14_to_13
	lea	palettes(pc),a0
	move.l	14*4(a0),a1	; destination shade 14
	move.l	15*4(a0),a2	; old shade 15 source
	move	#255,d0
.g2v190ia_copy15_to_14
	move.b	(a2)+,(a1)+
	dbf	d0,.g2v190ia_copy15_to_14
	movem.l	(a7)+,d0/a0-a2
.g2v190ia_done
	rts

dispoff	tst	dispnest
	bne.s	.skip
	bsr	vwait
	tst	os
	bne.s	.skip
	move	#$01a0,$dff096	;bp/cop/spr off!
.skip	addq	#1,dispnest
	rts

dispon	subq	#1,dispnest
	bgt.s	.skip
	bsr	vwait
	tst	os
	bne.s	.skip
	move.l	coplist(pc),$dff080
	move	#0,$dff088
	move	#$8080,$dff096	;cop on!
	move	#0,$dff088
.skip	rts

forbid	tst	os
	bne.s	.rts
	;
	push
	moveq	#49,d0
.fl	bsr	vwait
	dbf	d0,.fl
	bsr	ownblitter
	move.l	4.w,a6
	jsr	-132(a6)
	move	#$8400,$dff096	;bltnasty!
	pull
	;
.rts	rts

permit	tst	os
	bne.s	.rts
	;
	push
	move.l	4.w,a6
	jsr	-138(a6)
	jsr	disownblitter
	pull
	;
.rts	rts

initvbint	push
	move.l	4.w,a6
	moveq	#5,d0
	lea	vbintserver,a1
	jsr	-168(a6)	;addintserver
	pull
	rts

vbcounter	dc	0
framecnt	dc	0

frame	dc	0,0

vbintserver	dc.l	0,0
	dc.b	2,0
	dc.l	0
vbintdata	dc.l	vbcounter
vbintcode	dc.l	vbhandler

rbfintserver	dc.l	0,0
	dc.b	2,0
	dc.l	0
rbfintdata	dc.l	rbuff
rbfintcode	dc.l	rbf

finitvbint	push
	move.l	4.w,a6
	moveq	#5,d0
	lea	vbintserver,a1
	jsr	-174(a6)
	pull
	rts

blitnest	dc	0

ownblitter	tst	blitnest
	bne.s	.skip
	move.l	grbase,a6
	jsr	-456(a6)
.skip	addq	#1,blitnest
	rts

disownblitter	subq	#1,blitnest
	bgt.s	.rts
	move.l	grbase,a6
	jmp	-462(a6)
.rts	rts

grname	dc.b	'graphics.library',0
	even
grbase	dc.l	0
oldview	dc.l	0
dosname	dc.b	'dos.library',0
	even
dosbase	dc.l	0

showwindow	;a0=window
	;
	push
	;
	;poke bitmaps...
	move.l	wi_slice(a0),a1
	move.l	(a1),a1
	move.l	wi_bmap(a0),d0
	moveq	#6,d1	;7 bitplanes
.loop	move	d0,6(a1)
	swap	d0
	move	d0,2(a1)
	swap	d0
	add.l	#40,d0
	addq	#8,a1
	dbf	d1,.loop
	;
	;create DIW
	;
	move.l	wi_slice(a0),a1
	move.l	(a1),a1
	;
	move	wi_y(a0),d0
	move	d0,d1
	add	wi_bh(a0),d1
	lsl	#8,d0
	or	#$81,d0
	move	d0,56+2(a1)
	lsl	#8,d1
	or	#$c1,d1
	move	d1,56+6(a1)
	;
	;create wait!
	;
	move	wi_y(a0),d0
	subq	#3,d0
	move.b	d0,64(a1)
	;
	;create link to next!
	move.l	wi_nslice(a0),a1
	move.l	(a1),d0
	move.l	wi_cop1(a0),a1
	add.l	wi_copmem(a0),a1
	move.l	wi_cop2(a0),a2
	add.l	wi_copmem(a0),a2
	move	d0,-6(a1)
	move	d0,-6(a2)
	swap	d0
	move	d0,-10(a1)
	move	d0,-10(a2)
	;
	pull
	;
showwindowq	;display coplist
	;
	move.l	wi_cop(a0),d0
	move.l	wi_slice(a0),a0
	move.l	(a0),a0
	;
	move	d0,72+6(a0)
	swap	d0
	move	d0,72+2(a0)
	;
	rts

finitdisplay	push
	;
	tst	os
	beq.w	.noos
	;
	move.l	dbufinfo(pc),a1
	move.l	grbase(pc),a6
	jsr	-$3cc(a6)	;free dbufinfo
	;
	move.l	screen(pc),a0
	move.l	int(pc),a6
	jsr	-66(a6)
	;
	pull
	rts
	;
.noos	move.l	grbase,a6
	move.l	oldview,a1
	jsr	-222(a6)	;load view
	jsr	-270(a6)
	jsr	-270(a6)
	move.l	38(a6),$dff080
	move	#$81a0,$dff096
	move	#0,$dff088
	;
	pull
	rts

initbitmap	;a0=bitmap struct, d0=bitplane 0
	;
	move	bitplanes(pc),d1
	move	#40,(a0)	;linemod
	move	#240,2(a0)	;v16: restore original compact bitmap rows
	move	d1,4(a0)
	clr	6(a0)
	lea	8(a0),a1
	subq	#1,d1
	move.l	#40*240,d2
.loop	move.l	d0,(a1)+
	add.l	d2,d0
	dbf	d1,.loop
	rts

intname	dc.b	'intuition.library',0
	even
int	dc.l	0

osbitmap1	ds.b	40
osbitmap2	ds.b	40

screen	dc.l	0
viewport	dc.l	0
dbufinfo	dc.l	0

newscreen	dc	0,0	;x,y ;v106: native PAL/WinUAE centering; no 40px right-shift
	dc	320,240	;w,h ;v17: keep compact 240-line bitmap, avoid bottom overread
newscreen_d	dc	8	;depth
	dc.b	0,0	;pens
newscreen_v	dc	0	;viewmode
	dc	$4f	;type
	dc.l	0	;font
	dc.l	0	;title
	dc.l	0	;gadgets
	dc.l	osbitmap1	;custombitmap

	;make a new task for this window...
	;simply wait for activate/deactive and 
	;modify input readers 
	;
newwindow	dc	0,0	;x,y
	dc	320,240	;w,h ;v17: keep compact 240-line window
	dc.b	0,0	;pens
	dc.l	$c0000	;idcmp flags! $40000=active,
	dc.l	$11940	;flags! (RMB trap)
	dc.l	0	;gadgets
	dc.l	0	;checkmark
	dc.l	0	;title
newwindow_s	dc.l	0	;screen
	dc.l	0	;bitmap
	dc	-1,-1,-1,-1	;mins/maxs
	dc	15	;type

oswindow	dc.l	0
msgport	dc.l	0

newtask	dcb.b	92,0

inputon	bsr	g2v36_hide_pointer	;v36: hide pointer even if input was already active
	tst	active
	bne.s	.rts
	;
	move	#$4000,$dff09a
	;
	lea	joytable,a2
	lea     joytable2,a3
	lea	joytable_end,a4
.loop	move.l	(a3)+,(a2)+
	cmp.l	a4,a2
	bcs.s	.loop
	;
	move.l	ciaa,a0
	movem.l	$64(a0),d0-d1
	movem.l	d0-d1,rawstuff
	move.l	rawtable,$64(a0)
	move.l	#rawkeyread,$68(a0)
	move	#$c000,$dff09a
	st	active
	;
	; v36: pointer hide is handled by g2v36_hide_pointer above.
.rts	rts

inputoff	tst	active
	beq.s	.rts
	;
	move	#$4000,$dff09a
	;
	lea	joytable,a2
	lea	readnull,a3
	lea	joytable_end,a4
.loop	move.l	a3,(a2)+
	cmp.l	a4,a2
	bcs.s	.loop
	;
	move.l	ciaa,a0
	movem.l	rawstuff,d0-d1
	movem.l	d0-d1,$64(a0)
	move	#$c000,$dff09a
	;
	; v36: restore normal Intuition pointer when game/input loses focus or exits.
	bsr	g2v36_show_pointer
	clr	active
	;
.rts	rts

g2v35_blank_pointer	dc.w	0,0,0,0

g2v36_hide_pointer	;force invisible pointer for the game screen/window
	movem.l	d0-d3/a0-a1/a6,-(a7)
	move	#$0020,$dff096	;v39: disable hardware sprite DMA so OS mouse sprite vanishes even without an Intuition window
	move.l	oswindow,d0
	beq.s	.rts
	move.l	int,d1
	beq.s	.rts
	move.l	chipzero(pc),a1	;v37: pointer image must live in chip RAM
	move.l	a1,d1
	beq.s	.rts
	move.l	d0,a0
	moveq	#1,d0	;v39: 1-line invisible pointer, system sprite is also disabled above
	moveq	#1,d1	;v39: 1-pixel/word minimal pointer
	moveq	#0,d2	;x offset
	moveq	#0,d3	;y offset
	move.l	int,a6
	jsr	-270(a6)	; Intuition SetPointer
.rts	movem.l	(a7)+,d0-d3/a0-a1/a6
	rts

g2v36_show_pointer	;restore normal pointer when inactive/exit
	movem.l	d0/a0/a6,-(a7)
	move	#$8020,$dff096	;v39: re-enable hardware sprite DMA for Workbench/OS pointer
	move.l	oswindow,d0
	beq.s	.rts
	move.l	int,d0
	beq.s	.rts
	move.l	oswindow,a0
	move.l	int,a6
	jsr	-60(a6)	; Intuition ClearPointer
.rts	movem.l	(a7)+,d0/a0/a6
	rts

windowtask	move.l	int(pc),a6	;intuition base
	lea	newwindow(pc),a0
	jsr	-204(a6)	;openwindow
	move.l	d0,oswindow
	bsr	g2v36_hide_pointer	;v36: hide pointer immediately after OpenWindow
	move.l	d0,a0
	move.l	86(a0),msgport
	;
	;now, simply wait for window events!
	;
	move.l	4.w,a6
.loop	move.l	msgport(pc),a0
	jsr	-384(a6)	;waitport!
	move.l	d0,-(a7)
	move.l	d0,a0
	move.l	20(a0),d0
	cmp.l	#$40000,d0
	beq.s	.activate
	cmp.l	#$80000,d0
	bne.s	.skip
	;
	bsr	inputoff
	bra.s	.skip
	;
.activate	;activate input handlers
	;
	bsr	inputon
	;
.skip	move.l	(a7)+,a1
	jsr	-378(a6)	;reply msg
	bra.s	.loop

initdisplay	;
	lea	grname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,grbase
	;
	;allocate 2 bitmaps!
	;
	move	#40*240,d2	;1 bitplane (DB), v16 compact plane span
	mulu	bitplanes(pc),d2
	move.l	d2,bmapmem
	move.l	d2,d0
	add.l	d0,d0	;2 for DB
	moveq	#2,d1
	allocmem	bitmaps
	move.l	d0,bitmaps
	add.l	d2,d0
	move.l	d0,bitmaps2
	;
	tst	os
	beq.w	.noos
	;
	;OK, OS version...
	;init bitmaps and open a screen!
	;
	move.l	4.w,a6
	lea	intname(pc),a1
	jsr	-408(a6)
	move.l	d0,int
	;
	move.l	bitmaps(pc),d0
	lea	osbitmap1(pc),a0
	bsr	initbitmap
	move.l	bitmaps2(pc),d0
	lea	osbitmap2(pc),a0
	bsr	initbitmap
	;
	move	bitplanes(pc),newscreen_d
	tst	aga
	bne.s	.agasc
	move	#$80,newscreen_v
	;
.agasc	move.l	int(pc),a6
	lea	newscreen(pc),a0
	jsr	-198(a6)
	move.l	d0,a0
	move.l	a0,screen
	jsr	g2v36_hide_pointer	;v39: hide OS mouse sprite immediately after custom screen opens
	lea	44(a0),a0
	;
	move.l	a0,viewport
	move.l	grbase(pc),a6
	jsr	-$3c6(a6)	;alocdbufinfo
	move.l	d0,dbufinfo
	bra	db
	;
.noos	move.l	grbase(pc),a6
	move.l	34(a6),oldview
	sub.l	a1,a1
	jsr	-222(a6)	;loadview 0.
	;
	bsr	dispoff
	lea	copinit_aga,a0
	lea	copfinit_aga,a1
	tst	aga
	bne	.aga	
	lea	copinit_ecs,a0
	lea	copfinit_ecs,a1
.aga	movem.l	a0-a1,-(a7)
	move.l	a1,d0
	sub.l	a0,d0
	move.l	d0,d2
	moveq	#2,d1
	allocmem	coplist
	move.l	d0,coplist
	move.l	d0,a2	;dest
	movem.l	(a7)+,a0-a1
	lsr.l	#2,d2
	subq	#1,d2
.loop	move.l	(a0)+,(a2)+
	cmp.l	a1,a0
	bcs.s	.loop
	;
db	;double buffering
	;
	movem.l	bitmaps(pc),d0-d1
	cmp.l	drawbitmap(pc),d0
	beq.s	.show
	exg	d0,d1
.show	movem.l	d0-d1,showbitmap
	move.l	todb(pc),a0
	jmp	(a0)

db_ecs	move.l	coplist(pc),a0
	moveq	#40,d2
	lea	bitplanes_ecs-copinit_ecs(a0),a0
	moveq	#5,d1	;6 bitplanes
.loop0	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	d2,d0
	addq	#8,a0
	dbf	d1,.loop0
	rts

db_aga	move.l	coplist(pc),a0
	moveq	#40,d2
	lea	bitplanes_aga-copinit_aga(a0),a0
	moveq	#7,d1	;8 bitplanes
.loop	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	d2,d0
	addq	#8,a0
	dbf	d1,.loop
	rts

db_os	move.l	viewport(pc),a0
	lea	osbitmap1(pc),a1
	cmp.l	8(a1),d0
	beq.s	.got
	lea	osbitmap2(pc),a1
.got	move.l	dbufinfo(pc),a2
	move.l	grbase(pc),a6
	jmp	-$3ae(a6)	;changevpbitmap
	
;a0=bitmap, a1=screen, a3=intution, a6=graphics
;
;.agashowbitmap
;  MOVE.l a0,d4:MOVE.l (a1),a2:MOVE.l 4(a1),d0:BNE gotdbuff
;  MOVEM.l a1-a2,-(a7):LEA 44(a2),a0:JSR -$3c6(a6):MOVEM.l (a7)+,a1-a2
;  ;_AllocDBufInfo(a6):
;  MOVE.l d0,4(a1)
;gotdbuff:
;  LEA 44(a2),a0:MOVE.l d4,a1:MOVE.l d0,a2:JSR -$3ae(a6) ;ChangeVPBitMap_
;  RTS

allocmem2_	;
	;as below, but d2.l = extra mem at start to set aside
	;
	push
	moveq	#16,d3
	add.l	d2,d3
	bra.s	amem_

allocmem_	;
	;d0=size, d1=requirements, a0=text field
	;
	;set up node before allocmem for quick freemem:
	;
	;00.l : next
	;04.l : real size
	;08.l : offset to user mem (normally 16, but CM fucks things up)
	;12.l : pointer to text field for debugging
	;
	push
	moveq	#16,d3	;offset
	;
amem_	move.l	a0,d4
	add.l	d3,d0
	;
	move.l	d0,d2	;len
	move.l	a0,d4	;text
	move.l	4.w,a6
	jsr	-198(a6)
	tst.l	d0
	bne.s	.skip
	;
	warn	#$f00
	clr.l	d0		; v190p: allocation failed, return 0 instead of writing through address 0
	pull
	rts
	;
.skip	move.l	d0,a0
	move.l	memlist,(a0)	;next
	move.l	a0,memlist
	movem.l	d2-d4,4(a0)
	add.l	d3,a0
	move.l	a0,d0
	;
	pull
	rts

freememlist	push
	;
.more	move.l	memlist,d0
	beq.s	.done
	move.l	d0,a2
	;
	ifne	debugmem
	move.l	12(a2),a0	;text field
	move.l	a0,d2
	moveq	#-1,d3
.loop	addq.l	#1,d3
	tst.b	(a0)+
	bne.s	.loop
	;
	move.l	outhand,d1
	move.l	dosbase,a6
	jsr	-48(a6)
	endc
	;
	move.l	a2,a1
	;
	move.l	(a1),memlist
	move.l	4(a1),d0
	move.l	4.w,a6
	jsr	-210(a6)
	bra.s	.more
	;
.done	pull
	rts

freemem_	;
	;a1=address to free!
	;
	push
	;
	ifne	debugmem
	move.l	a0,-(a7)	;error mess
	elseif
	endc
	;
	move.l	a1,a2	;mem to find!
	lea	memlist(pc),a1
	;
.more	move.l	a1,a0	;prev
	move.l	(a1),d0
	beq.s	.err
	move.l	d0,a1
	;
	move.l	a1,a3
	add.l	8(a3),a3
	cmp.l	a3,a2
	bne.s	.more
	;
	move.l	(a1),(a0)
	move.l	4(a1),d0
	move.l	4.w,a6
	jsr	-210(a6)
	bra.s	.done
	;
.err	warn	#$ff0
	ifne	debugmem
	move.l	(a7),freememerr
	endc
.done	;
	ifne	debugmem
	addq	#4,a7
	endc
	;
	pull
	rts

freememerr	dc.l	0

initmap	;map address in map_map...
	;load in textures, do colour mapping etc.
	;
	push
	;
	move.l	map_map,a0
	;
	move.l	a0,a1
	add.l	(a0),a1
	move.l	a1,map_grid
	;
	move.l	a0,a1
	add.l	4(a0),a1
	move.l	a1,map_poly
	;
	move.l	a0,a1
	add.l	8(a0),a1
	move.l	a1,map_ppnt
	;
	move.l	a0,a1
	add.l	12(a0),a1
	move.l	a1,map_anim
	;
	move.l	a0,a1
	add.l	16(a0),a1
	move.l	a1,map_txts
	;
	move.l	(a0),d0
	sub.l	#25*4,d0
	add.l	a0,d0
	move.l	d0,map_events
	;
	move.l	map_rgbsfrom2,map_rgbsat
	;
	pull
	rts

freetxts	lea	textscrns,a6
	moveq	#7,d7
.loop	move.l	(a6)+,d0
	beq.s	.skip
	move.l	d0,a1
	freemem	freetxts
	clr.l	-4(a6)
.skip	dbf	d7,.loop
	rts

loadtxts	push
	;
	lea	textures,a4
	move.l	map_txts,a5	;texture names
	lea	textscrns,a6
	moveq	#7,d7
	;
.ltl	lea	.temp(pc),a0
	;
.ltl2	move.b	(a5)+,(a0)+
	bne.s	.ltl2
	moveq	#0,d0
	cmp.l	#.temp+1,a0
	beq.s	.notext
	lea	.temp2(pc),a0
	moveq	#1,d1
	jsr	loadfile
	;
.notext	move.l	d0,(a6)+	;texture!
	beq.s	.skip
	;
	;do colour mapping stuff!
	;
	move.l	d0,-(a7)
	;
	move.l	d0,a0
	add.l	(a0),a0
	move.l	a0,a2
	bsr	addpal
	;
	move.l	(a7),a0
	addq	#4,a0
	move.l	a2,a1
	bsr	remap
	;
	move.l	(a7)+,a0
	addq	#4,a0
	moveq	#19,d0
	move.l	#64*65,d1
	;
.mtxt	move.l	a0,(a4)+
	add.l	d1,a0
	dbf	d0,.mtxt
.skip	;
	dbf	d7,.ltl
	;
	pull
	rts

.temp2	dc.b	'txts/'
.temp	ds.b	64 
	even

remapanim	;a0=anim to remap...
	;
	push
	;
	move.l	a0,a6
	movem	(a6),d6-d7
	lsl	d6,d7	;how many frames!
	subq	#1,d7
	;
	move.l	a6,a0
	add.l	an_pal(a0),a0
	bsr	addpal
	;
	lea	an_size(a6),a5
	;
.loop	move.l	a6,a0
	add.l	(a5)+,a0	;start of shape
	addq	#4,a0	;skip handles
	movem	(a0)+,d0-d1	;w/h
	mulu	d1,d0
	lea	0(a0,d0.l),a1	;end
	bsr	remap
	;
	dbf	d7,.loop
	;
	pull
	rts
	
remap	;a0=start of byte data, a1=end of byte data
	;
	push
	;
	moveq	#0,d0
	move.l	maptable,a2
	;
.loop	cmp.l	a1,a0
	bcc.s	.done
	move.b	(a0),d0
	move.b	0(a2,d0),(a0)+
	bra.s	.loop
.done	;
	pull
	rts

addpal	;add palette in a0 to end of map_rgb
	;
	push
	;
	move	(a0)+,d0
	subq	#1,d0
	move.l	map_rgbsat,a2	;end of rgbs
	move.l	maptable,a3
	;
	clr.b	(a3)	;0=0
	move.b	#255,255(a3)	;-1=-1
	move.b	#254,254(a3)	;-1=-1
	move.b	#253,253(a3)	;-1=-1
	move.b	#252,252(a3)	;-1=-1
	move.b	#251,251(a3)	;-1=-1
	move.b	#250,250(a3)	;-1=-1
	move.b	#249,249(a3)	;-1=-1
	;
	moveq	#1,d2	;colour 1!
	;
.loop	move	(a0)+,d1	;colour...does it exist?
	bmi.s	.next	;not used!
	move.l	map_rgbs,a1
	;
.loop2	cmp.l	a2,a1
	bcc.s	.no
	cmp	(a1)+,d1
	beq.s	.yes
	bra.s	.loop2
	;
.no	;colour doesn't exist!
	;may have to do a 'near match' routine if we run out of colours
	;
	move	d1,(a2)+
	move.l	a2,a1
	;
.yes	subq	#2,a1
	sub.l	map_rgbs,a1
	move.l	a1,d1
	lsr	#1,d1	;real colour
	;
	cmp	#256,d1
	bcs.s	.ok
	;
	warn	#$00f
	;
.ok	move.b	d1,0(a3,d2)
	;
.next	addq	#1,d2
	dbf	d0,.loop
	;
	move.l	a2,map_rgbsat
	;
	pull
	rts

	;coll types...
	;
	;1...bullet from player 1
	;2...bullet from player 2
	;4...bullet from monster
	;8...player 1
	;16..player 2
	;

	dc.l	0,player,tokens
	;
objlist	;list of objects to be freed...
	;
	dc.l	marine,baldy,terra,ghoul,demon,phantom
	dc.l	lizard,deathhead,dragon,troll,0

player	dc.l	0,0	;main, chunks
	dc.b	'objs/player',0,0
	even
tokens	dc.l	0,0
	dc.b	'objs/tokens',0,0
	even
marine	dc.l	0,0
	dc.b	'objs/marine',0,0
	even
baldy	dc.l	0,0
	dc.b	'objs/baldy',0,0
	even
terra	dc.l	0,0
	dc.b	'objs/terra',0,0
	even
ghoul	dc.l	0,0
	dc.b	'objs/ghoul',0,0
	even
demon	dc.l	0,0
	dc.b	'objs/demon',0,0
	even
phantom	dc.l	0,0
	dc.b	'objs/phantom',0,0
	even
lizard	dc.l	0,0
	dc.b	'objs/lizard',0,0
	even
deathhead	dc.l	0,0
	dc.b	'objs/deathhead',0,0
	even
dragon	dc.l	0,0
	dc.b	'objs/dragon',0,0
	even
troll	dc.l	0,0
	dc.b	'objs/troll',0,0
	even

objinfo
player1_	dc.l	player1
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	$d0000
_ob_shape	dc.l	player
.ob_logic	dc.l	playerlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	playerhit
.ob_die	dc.l	playerdie
	;
.ob_eyey	dc	-pl_eyey	;eye height
.ob_firey	dc	-pl_firey	;where bullets come from
.ob_gutsy	dc	-pl_gutsy
.ob_othery	dc	0
p1_ob_colltype	dc	8
p1_ob_collwith	dc	6	;6=combat, 4=game
p1_ob_cntrl
	ifne	cd32
	dc	4	;CD32 PAD 1 in v34 control table
	elseif
	dc	0	;KEYBMOUSE default
	endc
.ob_damage	dc	1
.ob_hitpoints	dc	25
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	1
.ob_range	dc	1
.ob_weapon	dc	0	;weapon type...0...25
.ob_reload	dc.b	ireload,0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0	;4!
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

objinfof

oilen	equ	objinfof-objinfo

player2_	dc.l	player2
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	$d0000
.ob_shape	dc.l	player
.ob_logic	dc.l	playerlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	playerhit
.ob_die	dc.l	playerdie
.ob_eyey	dc	-pl_eyey	;eye height
.ob_firey	dc	-pl_firey	;where bullets come from
.ob_gutsy	dc	-pl_gutsy
.ob_othery	dc	0
p2_ob_colltype	dc	16
p2_ob_collwith	dc	5	;5=combat, 4=game
p2_ob_cntrl
	ifne	cd32
	dc	5	;CD32 PAD 2 in v34 control table
	elseif
	dc	2	;v168 JOYSTICK 1 default is valid while P1 uses KEYBMOUSE
	endc

.ob_damage	dc	1
.ob_hitpoints	dc	25
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	1
.ob_range	dc	1
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc.b	ireload,0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0	;4!
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

health_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	healthgot
.ob_die	dc.l	healthgot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$20000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

weapon_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon2
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	1
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

thermo_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	thermogot
.ob_die	dc.l	thermogot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$00000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

infra_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	thermogot
.ob_die	dc.l	thermogot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$00000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

invisi_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	invisigot
.ob_die	dc.l	invisigot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$10000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

invinc_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	invincgot
.ob_die	dc.l	invincgot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$20000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

dragon_	dc.l	dummy
.ob_rotspeed	dc.l	$ffff0000
.ob_movspeed	dc.l	$c0000
.ob_shape	dc.l	dragon
.ob_logic	dc.l	dragonlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	rts	;hurtngrunt
.ob_die	dc.l	blowdragon	;object
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-144	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	10
.ob_hitpoints	dc	250
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	16
.ob_range	dc	32
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$300
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

bouncy_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	bouncylogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	bouncygot
.ob_die	dc.l	bouncygot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$30000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

marine_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$60000
.ob_shape	dc.l	marine
.ob_logic	dc.l	monsterlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	1
.ob_hitpoints	dc	5
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	16
.ob_range	dc	32
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

baldy_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$40000
.ob_shape	dc.l	baldy
.ob_logic	dc.l	baldylogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	2
.ob_hitpoints	dc	10
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	8
.ob_range	dc	16
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	3
.ob_punchrate	dc	4
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$220
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

terra_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$20000
.ob_shape	dc.l	terra
.ob_logic	dc.l	terralogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtterra ;ngrunt
.ob_die	dc.l	blowterra
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	1
.ob_hitpoints	dc	35
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	32
.ob_range	dc	48
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_firerate	dc	12	;how often terra fires
.ob_bouncecnt	dc	0	;how many times
.ob_firecnt	dc	5
.ob_scale	dc	$280
.ob_apad	dc	0
.ob_blood	dc	$fff	;color AND for blood
.ob_ypad	dc	1

ghoul_	dc.l	dummy
.ob_rotspeed	dc.l	$0
.ob_movspeed	dc.l	$80000
.ob_shape	dc.l	ghoul
.ob_logic	dc.l	ghoullogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtghoul
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-64	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	5
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	0
.ob_base	dc	32
.ob_range	dc	48
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_firerate	dc	12	;how often terra fires
.ob_bouncecnt	dc	0	;how many times
.ob_firecnt	dc	5
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$80f0	;color AND for blood
.ob_ypad	dc	1

phantom_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$a0000
.ob_shape	dc.l	phantom
.ob_logic	dc.l	phantomlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	3
.ob_hitpoints	dc	10
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$a000
.ob_base	dc	8
.ob_range	dc	16
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	7
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$280
.ob_apad	dc	0
.ob_blood	dc	$ff0	;color AND for blood
.ob_ypad	dc	1

demon_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$70000
.ob_shape	dc.l	demon
.ob_logic	dc.l	demonlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-90	;where bullets come from
.ob_gutsy	dc	-72
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	5
.ob_hitpoints	dc	25
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$7000
.ob_base	dc	32
.ob_range	dc	4
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$380
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

weapon1_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon1
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon2_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon2
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	1
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon3_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon3
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	2
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon4_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon4
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	3
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon5_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon5
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	4
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

lizard_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$60000
.ob_shape	dc.l	lizard
.ob_logic	dc.l	lizardlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	lizhurt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	2
.ob_hitpoints	dc	10
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	8
.ob_range	dc	8
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	2
.ob_punchrate	dc	3
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$240
.ob_apad	dc	0
.ob_blood	dc	$f0f	;color AND for blood
.ob_ypad	dc	1

deathhead_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	$c0000
.ob_shape	dc.l	deathhead
.ob_logic	dc.l	deathheadlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtdeath
.ob_die	dc.l	blowdeath
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-96
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	3
.ob_hitpoints	dc	35
.ob_think	dc	0
.ob_frame	dc.l	$8000
.ob_framespeed	dc.l	$6000
.ob_base	dc	-8
.ob_range	dc	16
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	10
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

troll_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$60000
.ob_shape	dc.l	troll
.ob_logic	dc.l	trolllogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	trollhurt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	3
.ob_hitpoints	dc	18
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	8
.ob_range	dc	8
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	2
.ob_punchrate	dc	3
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$240
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

abouttext	dc.b	16
	dc.b	'GLOOM',0
	dc.b	0
	dc.b	'A BLACK MAGIC GAME',0
	dc.b	0
	dc.b	'PROGRAMMED BY MARK SIBLY',0
	dc.b	'GRAPHICS BY THE BUTLER BROTHERS',0
	dc.b	'MUSIC BY KEV STANNARD',0
	dc.b	'AUDIO BY US',0
	dc.b	'PRODUCED BY US',0
	dc.b	'DESIGNED BY US',0
	dc.b	'GAME CODED IN DEVPAC2',0
	dc.b	'UTILITIES CODED IN BLITZ BASIC 2',0
	dc.b	'RENDERED IN DPAINT3 AND DPAINT4',0
	dc.b	'DECRUNCHING CODE BY THOMAS SCHWARZ',0
	dc.b	0
	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

abouttext_g3	dc.b	14
	dc.b	'GLOOM3 ZOMBIE EDITION',0
	dc.b	'A GAME BY GARETH MURFIN',0
	dc.b	0
	dc.b	'ADDITIONAL GFX AND SFX BY',0
	dc.b	'JAMES CAYGILL',0
	dc.b	'CHRIS BURNS',0
	dc.b	'RICHARD MURFIN',0
	dc.b	0
	dc.b	'STORY BY',0
	dc.b	'CHRIS MURFIN',0
	dc.b	0
	dc.b	'BASED ON GLOOM BY MARK SIBLY',0
	dc.b	0
	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

abouttext_zm	dc.b	8
	dc.b	'ALPHA SOFTWARE',0
	dc.b	'QUALITY AMIGA SOFTWARE',0
	dc.b	0
	dc.b	'FOUNDED BY GARETH MURFIN',0
	dc.b	0
	dc.b	'CHECK OUT THE BOOKLET NOW!',0
	dc.b	0
	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

sqrinc	incbin	sqr.bin

weapon1	dc.l	bullet1,sparks1
weapon2	dc.l	bullet2,sparks2
weapon3	dc.l	bullet3,sparks3
weapon4	dc.l	bullet4,sparks4
weapon5	dc.l	bullet5,sparks5

bullet1	incbin	bullet1.bin
bullet2	incbin	bullet2.bin
bullet3	incbin	bullet3.bin
bullet4	incbin	bullet4.bin
bullet5	incbin	bullet5.bin

sparks1	incbin	sparks1.bin
sparks2	incbin	sparks2.bin
sparks3	incbin	sparks3.bin
sparks4	incbin	sparks4.bin
sparks5	incbin	sparks5.bin

medplayer	incbin	medplay
decrm	incbin	decrm

castrotsinc	incbin	castrots128.bin
camrotsinc	incbin	camrots.bin	;256
camrots2inc	incbin	camrots2.bin	;1024
chatfont	incbin	chatfont.bin

copinit_ecs	dc	$096,$120
	;
	dc	$08e,$2ca1,$090,$1ce1	;v17: stronger 320x240 right-centering test
	dc	$092,$38,$094,$d0,$102,0,$104,0,$106,0
	dc	$100,$6200,$108,5*40,$10a,5*40,$10c,0
	;
	;palette layout:
	;
	;hinybs of first 32,lonybs,hinybs of second 32,lonybs
	;
palette_ecs	dc	$180,0,$182,0,$184,0,$186,0
	dc	$188,0,$18a,0,$18c,0,$18e,0
	dc	$190,0,$192,0,$194,0,$196,0
	dc	$198,0,$19a,0,$19c,0,$19e,0
	dc	$1a0,0,$1a2,0,$1a4,0,$1a6,0
	dc	$1a8,0,$1aa,0,$1ac,0,$1ae,0
	dc	$1b0,0,$1b2,0,$1b4,0,$1b6,0
	dc	$1b8,0,$1ba,0,$1bc,0,$1be,0
	;
bitplanes_ecs	dc	$e0,0,$e2,0
	dc	$e4,0,$e6,0
	dc	$e8,0,$ea,0
	dc	$ec,0,$ee,0
	dc	$f0,0,$f2,0
	dc	$f4,0,$f6,0
	;
	dc	26<<8+1,$fffe
	;
sprites_ecs	dc	$140,0,$142,0,$144,0,$146,0
	dc	$148,0,$14a,0,$14c,0,$14e,0
	dc	$150,0,$152,0,$154,0,$156,0
	dc	$158,0,$15a,0,$15c,0,$15e,0
	dc	$160,0,$162,0,$164,0,$166,0
	dc	$168,0,$16a,0,$16c,0,$16e,0
	dc	$170,0,$172,0,$174,0,$176,0
	dc	$178,0,$17a,0,$17c,0,$17e,0
	;
	dc	32<<8+1,$fffe,$096,$8100
	;
	dc.l	$fffffffe
copfinit_ecs	;

cols32	macro	;bank,losel
	dc	$106,(\1<<13)|(\2<<9)
	dc	$180,0,$182,0,$184,0,$186,0
	dc	$188,0,$18a,0,$18c,0,$18e,0
	dc	$190,0,$192,0,$194,0,$196,0
	dc	$198,0,$19a,0,$19c,0,$19e,0
	dc	$1a0,0,$1a2,0,$1a4,0,$1a6,0
	dc	$1a8,0,$1aa,0,$1ac,0,$1ae,0
	dc	$1b0,0,$1b2,0,$1b4,0,$1b6,0
	dc	$1b8,0,$1ba,0,$1bc,0,$1be,0
	endm

copinit_aga	;copperlist for AGA amigas
	;
	dc	$1fc,15,$096,$120
	;
	dc	$08e,$2ca1,$090,$1ce1	;v17: stronger right-centering test
	dc	$092,$38,$094,$a0,$102,0,$104,0,$106,0
	dc	$100,$7200,$108,7*40,$10a,7*40,$10c,0
	;
	;palette layout:
	;
	;hinybs of first 32,lonybs,hinybs of second 32,lonybs
	;
palette_aga	cols32	0,0
	cols32	0,1
	cols32	1,0
	cols32	1,1
	cols32	2,0
	cols32	2,1
	cols32	3,0
	cols32	3,1
	cols32	4,0
	cols32	4,1
	cols32	5,0
	cols32	5,1
	cols32	6,0
	cols32	6,1
	cols32	7,0
	cols32	7,1
	;
bitplanes_aga	dc	$e0,0,$e2,0
	dc	$e4,0,$e6,0
	dc	$e8,0,$ea,0
	dc	$ec,0,$ee,0
	dc	$f0,0,$f2,0
	dc	$f4,0,$f6,0
	dc	$f8,0,$fa,0
	dc	$fc,0,$fe,0
	;
	dc	26<<8+1,$fffe
	;
sprites_aga	dc	$140,0,$142,0,$144,0,$146,0
	dc	$148,0,$14a,0,$14c,0,$14e,0
	dc	$150,0,$152,0,$154,0,$156,0
	dc	$158,0,$15a,0,$15c,0,$15e,0
	dc	$160,0,$162,0,$164,0,$166,0
	dc	$168,0,$16a,0,$16c,0,$16e,0
	dc	$170,0,$172,0,$174,0,$176,0
	dc	$178,0,$17a,0,$17c,0,$17e,0
	;
	dc	32<<8+1,$fffe,$096,$8100
	;
	dc.l	$fffffffe
copfinit_aga	;



		even
		;
		; v13 built-in fallback C2P.  This is the original c2p/blackmagic_1
		; algorithm embedded as a safety net, so gameplay is not dependent on
		; the helper file being found through the current directory.
		;
g2v13_c2pname	dc.b	'c2p/blackmagic_1',0
		even

g2v13_rotbits	macro	;reg1,reg2,shift
		move.l	\1,d4
		and.l	d6,\1
		eor.l	\1,d4
		lsl.l	#\3,\1
		;
		move.l	\2,d5
		and.l	d6,d5
		eor.l	d5,\2
		lsr.l	#\3,\2
		or.l	d4,\2
		or.l	d5,\1
		endm

g2v13_doc2p_1X1X8
		move.l	#$0f0f0f0f,a2
		move.l	#$33333333,a3
		move.l	#$5555aaaa,a4
		move.l	d2,a5
		lsl.l	#3,d2
		move.l	d2,a6
		sub.l	a5,a6
		subq.l	#2,a6
		lsr	#4,d0
		move	d0,d2
		ext.l	d2
		add.l	d2,d2
		add.l	a6,d2
		sub.l	d2,d3
		move.l	d3,-(a7)
		subq	#1,d1
		move	d1,d7
		swap	d7
		subq	#1,d0
		move	d0,d7
		subq	#2,a7
		move	d7,-(a7)
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		bra.s	.g2v13_8_here
.g2v13_8_loop2
		swap	d7
		bra.s	.g2v13_8_here
.g2v13_8_loop
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		sub.l	a6,a1
.g2v13_8_here
	g2v13_rotbits	d0,d2,4
	g2v13_rotbits	d1,d3,4
		move.l	a3,d6
	g2v13_rotbits	d0,d1,2
		move.l	a4,d6
		move.l	d0,d4
		and.l	d6,d4
		eor.l	d4,d0
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d0
		move	d0,(a1)
		add.l	a5,a1
		move.l	d1,d4
		and.l	d6,d4
		eor.l	d4,d1
		swap	d0
		move	d0,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d1
		move	d1,(a1)
		add.l	a5,a1
		move.l	a3,d6
	g2v13_rotbits	d2,d3,2
		move.l	a4,d6
		move.l	d2,d4
		and.l	d6,d4
		eor.l	d4,d2
		swap	d1
		move	d1,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d2
		move	d2,(a1)
		add.l	a5,a1
		move.l	d3,d4
		and.l	d6,d4
		eor.l	d4,d3
		swap	d2
		move	d2,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d3,d4
		move	d4,(a1)
		add.l	a5,a1
		dbf	d7,.g2v13_8_loop
		move	(a7),d7
		swap	d7
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		add.l	4(a7),a1
		dbf	d7,.g2v13_8_loop2
		addq	#8,a7
		rts

g2v13_doc2p_1X1X6
		move.l	#$0f0f0f0f,a2
		move.l	#$33333333,a3
		move.l	#$5555aaaa,a4
		move.l	d2,a5
		lsl.l	#2,d2
		add.l	a5,d2
		move.l	d2,a6
		subq.l	#2,a6
		lsr	#4,d0
		move	d0,d2
		ext.l	d2
		add.l	d2,d2
		add.l	a6,d2
		sub.l	d2,d3
		move.l	d3,-(a7)
		subq	#1,d1
		move	d1,d7
		swap	d7
		subq	#1,d0
		move	d0,d7
		subq	#2,a7
		move	d7,-(a7)
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		bra.s	.g2v13_6_here
.g2v13_6_loop2
		swap	d7
		bra.s	.g2v13_6_here
.g2v13_6_loop
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		sub.l	a6,a1
.g2v13_6_here
	g2v13_rotbits	d0,d2,4
	g2v13_rotbits	d1,d3,4
		move.l	a3,d6
	g2v13_rotbits	d0,d1,2
		move.l	a4,d6
		move.l	d0,d4
		and.l	d6,d4
		eor.l	d4,d0
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d0
		move	d0,(a1)
		add.l	a5,a1
		move.l	d1,d4
		and.l	d6,d4
		eor.l	d4,d1
		swap	d0
		move	d0,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d1
		move	d1,(a1)
		add.l	a5,a1
		move.l	a3,d6
	g2v13_rotbits	d2,d3,2
		move.l	a4,d6
		move.l	d2,d4
		and.l	d6,d4
		eor.l	d4,d2
		swap	d1
		move	d1,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d2,d4
		move	d4,(a1)
		add.l	a5,a1
		dbf	d7,.g2v13_6_loop
		move	(a7),d7
		swap	d7
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		add.l	4(a7),a1
		dbf	d7,.g2v13_6_loop2
		addq	#8,a7
		rts

; v190p: title art memory pressure relief.  Direct START LEVEL tests show that
; later maps load when the title/intermission path has not accumulated extra
; large allocations.  Keep the title picture out of memory while playing, then
; reload it before returning to the title menu.  Palette/remap tables stay loaded.
g2v190p_load_title_assets
	movem.l	d0/a0,-(a7)
	tst.l	gloom
	bne.s	.done
	jsr	permit
	move.l	g2title_aga_ptr,a0
	tst	aga
	bne.s	.load
	move.l	g2title_ecs_ptr,a0
.load	jsr	loadfiles
	jsr	g2embed_apply_g1_fallbacks	;v190gl: title/brush/palette fallback after reload
	jsr	g2embed_apply_zm_title_overlay	;v190hu: embedded Zombie Massacre title overlay after reload
	jsr	forbid
.done	movem.l	(a7)+,d0/a0
	rts

g2v190p_free_title_assets
	movem.l	d0/a1,-(a7)
	move.l	gloom,d0
	beq.s	.skip_gloom
	cmp.l	#g2embed_title,d0
	beq.s	.skip_gloom
	clr.l	gloom
	move.l	d0,a1
	freemem	title
.skip_gloom
	move.l	gloompal,d0
	beq.s	.skip_pal
	cmp.l	#g2embed_title_pal,d0
	beq.s	.skip_pal
	cmp.l	#g2embed_zm_title_pal,d0	; v190hu: embedded ZM title palette is static
	beq.s	.skip_pal
	clr.l	gloompal
	move.l	d0,a1
	freemem	titlepal
.skip_pal
	move.l	gloombrush,d0
	beq.s	.skip_brush
	cmp.l	#g2embed_gloombrush,d0
	beq.s	.skip_brush
	cmp.l	#g2embed_zm_titlebrush,d0	; v190hu: embedded ZM title image is static
	beq.s	.skip_brush
	clr.l	gloombrush
	move.l	d0,a1
	freemem	titlebrush
.skip_brush
	movem.l	(a7)+,d0/a1
	rts

g2v190p_title_aga
	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	0

g2v190p_title_ecs
	dc.l	gloom
	dc.b	'pics_ehb/title',0
	even
	dc.l	gloompal
	dc.b	'pics_ehb/title.pal',0
	even
	dc.l	0

paladjust	ds.b	256	;remaping for scrambled bitplanes
map_rgbs_	ds.w	256*16	;v190p original-sized 4bit RGB palette pool

	even
; v190o: large levelselect/script buffers moved out of the middle of code/data so
; they do not push existing PC-relative references beyond GenAm's 32KB range.
g2v190i_script_static ds.b g2v190i_script_static_size
	even
g2v190i_level_names ds.b g2v190i_max_levels*16
g2v190i_level_paths ds.b g2v190i_max_levels*64
g2v190i_level_offsets ds.l g2v190i_max_levels	; v190r: script command offsets for START LEVEL chain mode
	even


	even

		even

	even
; v190an: resume from ESC in-game menu without the old predrawall blank
; frames.  predrawall clears and db-swaps both bitmaps via clspic, which is the
; visible black flash on real Amiga.  Here the grey/menu frame stays visible
; while a real gameplay frame is rendered into the hidden bitmap.  After the
; first db the screen is already back in-game; a second render fills the other
; buffer as well so the following frame cannot bounce back to the menu image.
g2v190an_resume_menu_noblank
	movem.l	d0/a0,-(a7)
	move.l	player1,a0
	st	ob_update(a0)
	tst	gametype
	beq.s	.g2v190an_one_player
	move.l	player2,a0
	st	ob_update(a0)
.g2v190an_one_player
	movem.l	(a7)+,d0/a0
	jsr	g2v190aj_restore_game_palette
	jsr	drawall_
	jsr	drawall_
	rts

; v190bz: transparent wall strip colour filter LUTs for chunky renderer.
; The original planar renderer used the byte before each transparent texture
; column as a colour-mask selector.  Flag -6 is the green glass/screen tint.
; In chunky mode we emulate that by remapping the already-rendered destination
; pixel through this palette-aware LUT when the transparent texel is zero.
g2build_strip_luts
	movem.l	d0-d7/a0-a6,-(a7)
	lea	g2_strip_green_lut,a0
	moveq	#0,d0
	move	#255,d7
.g2st_identity
	move.b	d0,(a0)+
	addq	#1,d0
	dbf	d7,.g2st_identity
	move.l	planar_palette,d0
	beq.w	.g2st_done
	move.l	d0,a2
	move.l	planar_remap,a3
	tst.l	a3
	beq.w	.g2st_done
	; build inverse paladjust: adjusted chunky index -> original palette index
	lea	g2_strip_invpal,a0
	moveq	#0,d0
	move	#255,d7
.g2st_clear_inv
	move.b	d0,(a0)+
	addq	#1,d0
	dbf	d7,.g2st_clear_inv
	lea	g2_strip_invpal,a0
	lea	paladjust,a1
	moveq	#0,d0
	move	#255,d7
.g2st_inv_loop
	moveq	#0,d1
	move.b	0(a1,d0.w),d1
	move.b	d0,0(a0,d1.w)
	addq	#1,d0
	dbf	d7,.g2st_inv_loop
	lea	g2_strip_green_lut,a4
	lea	g2_strip_invpal,a0
	lea	paladjust,a5
	moveq	#0,d3
	move	#255,d7
.g2st_lut_loop
	moveq	#0,d4
	move.b	0(a0,d3.w),d4	; real palette index before paladjust
	moveq	#0,d0
	cmp	colours,d4
	bcc.s	.g2st_make_green
	move	d4,d5
	tst	aga
	beq.s	.g2st_ecs_col
	lsl	#2,d5
	bra.s	.g2st_get_col
.g2st_ecs_col
	add	d5,d5
.g2st_get_col
	move	0(a2,d5.w),d0	; 12-bit RGB
.g2st_make_green
	; v190cf: realistic green glass.  Preserve the brightness of what is
	; already behind the pane instead of adding a fixed green boost.  Dark
	; walls therefore remain dark, while bright lamps/textures stay bright but
	; become green-tinted.
	move	d0,d1	; red
	lsr	#8,d1
	and	#$000f,d1
	move	d0,d2	; green
	lsr	#4,d2
	and	#$000f,d2
	move	d0,d6	; blue
	and	#$000f,d6
	move	d1,d5	; brightness = max(r,g,b)
	cmp	d2,d5
	bhs.s	.g2st_max_g_ok
	move	d2,d5
.g2st_max_g_ok
	cmp	d6,d5
	bhs.s	.g2st_max_b_ok
	move	d6,d5
.g2st_max_b_ok
	move	d5,d2	; green channel keeps background brightness
	move	d5,d1	; red/blue only a weak bleed-through
	lsr	#2,d1
	move	d1,d6
	lsl	#8,d1
	lsl	#4,d2
	or	d2,d1
	or	d6,d1
	moveq	#0,d0
	move.b	0(a3,d1.w),d0	; RGB -> nearest game palette entry
	move.b	0(a5,d0.w),d0	; paladjust -> active chunky index
	move.b	d0,0(a4,d3.w)
	addq	#1,d3
	dbf	d7,.g2st_lut_loop
.g2st_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2_strip_invpal	ds.b	256
g2_strip_green_lut	ds.b	256
	even

; v190aj: true grey in-game menu backdrop for the Gloom2 chunky/C2P path.
; Based on the original gloom.s idea of drawing the game through a temporary
; grey palette, but without calling the full drawall wait path from ESC.
; We remap the already-rendered chunky frame to safe grey indices 4..15,
; poke a matching temporary grey palette, C2P it once, then initmenu draws the
; yellow bigfont2 over this grey frame.  On leaving/refreshing the menu, the
; original gameplay palette is restored before normal rendering continues.
g2v190aj_grey_menu_backdrop
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	lastpal,d0
	move.l	d0,g2v190aj_saved_lastpal
	jsr	g2v190aj_build_grey_palette
	jsr	g2v190aj_build_grey_lut
	jsr	g2v190aj_apply_grey_lut
	lea	g2v190aj_grey_pal,a1
	jsr	pokepal
	jsr	doc2p
	jsr	db
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2v190aj_restore_game_palette
	movem.l	d0/a1,-(a7)
	move.l	g2v190aj_saved_lastpal,d0
	beq.s	.g2v190aj_rg_done
	move.l	d0,a1
	jsr	pokepal
	clr.l	g2v190aj_saved_lastpal
.g2v190aj_rg_done
	movem.l	(a7)+,d0/a1
	rts

g2v190aj_build_grey_palette
	movem.l	d0-d7/a0,-(a7)
	lea	g2v190aj_grey_pal,a0
	move	colours,d7
	beq.s	.g2v190aj_bgp_done
	subq	#1,d7
	moveq	#0,d0
	tst	aga
	beq.s	.g2v190aj_bgp_ecs
.g2v190aj_bgp_aga_loop
	bsr.s	g2v190aj_make_grey_rgb
	move	d1,(a0)+
	clr	(a0)+
	addq	#1,d0
	dbf	d7,.g2v190aj_bgp_aga_loop
	bra.s	.g2v190aj_bgp_done
.g2v190aj_bgp_ecs
	bsr.s	g2v190aj_make_grey_rgb
	move	d1,(a0)+
	addq	#1,d0
	dbf	d7,.g2v190aj_bgp_ecs
.g2v190aj_bgp_done
	movem.l	(a7)+,d0-d7/a0
	rts

; d0 = palette index, returns d1 = 12-bit RGB grey.  4..15 are the grey ramp;
; 1..3 are left for initfontpal/bigfont2 and are not used by the backdrop.
g2v190aj_make_grey_rgb
	moveq	#0,d1
	cmp	#4,d0
	bcs.s	.g2v190aj_mgr_done
	cmp	#15,d0
	bhi.s	.g2v190aj_mgr_done
	move	d0,d1
	subq	#4,d1
	mulu	#9,d1
	divu	#11,d1
	addq	#1,d1		; darker dim ramp 1..10, not full white
	move	d1,d2
	lsl	#8,d1
	move	d2,d3
	lsl	#4,d3
	or	d3,d1
	or	d2,d1
.g2v190aj_mgr_done
	rts

g2v190aj_build_grey_lut
	movem.l	d0-d7/a0-a5,-(a7)
	lea	g2v190aj_invpal,a0
	moveq	#0,d0
	move	#255,d7
.g2v190aj_clear_inv
	move.b	d0,(a0)+
	dbf	d7,.g2v190aj_clear_inv
	lea	g2v190aj_invpal,a0
	lea	paladjust,a1
	moveq	#0,d0
	move	#255,d7
.g2v190aj_inv_loop
	moveq	#0,d1
	move.b	0(a1,d0.w),d1
	move.b	d0,0(a0,d1.w)
	addq	#1,d0
	dbf	d7,.g2v190aj_inv_loop
	move.l	planar_palette,d0
	bne.s	.g2v190fy_havepal
	; v190fy: no source palette available, still build a deterministic
	; grey backdrop LUT instead of leaving stale LUT entries behind.
	lea	g2v190aj_lut,a3
	moveq	#0,d3
	move	#255,d7
.g2v190fy_fallback_lut
	move	d3,d0
	and	#15,d0
	mulu	#11,d0
	divu	#15,d0
	addq	#4,d0
	move.b	d0,0(a3,d3.w)
	addq	#1,d3
	dbf	d7,.g2v190fy_fallback_lut
	bra.w	.g2v190aj_lut_done
.g2v190fy_havepal
	move.l	d0,a2
	lea	g2v190aj_lut,a3
	lea	g2v190aj_invpal,a0
	lea	paladjust,a5
	moveq	#0,d3
	move	#255,d7
.g2v190aj_lut_loop
	moveq	#0,d4
	move.b	0(a0,d3.w),d4	; real display palette index before paladjust
	cmp	colours,d4
	bcc.s	.g2v190aj_lut_black
	move	d4,d5
	tst	aga
	beq.s	.g2v190aj_lut_ecscol
	lsl	#2,d5
	bra.s	.g2v190aj_lut_getcol
.g2v190aj_lut_ecscol
	add	d5,d5
.g2v190aj_lut_getcol
	move	0(a2,d5.w),d0	; 12-bit RGB
	move	d0,d1
	move	d0,d2
	and	#$0f00,d0
	lsr	#8,d0
	and	#$00f0,d1
	lsr	#4,d1
	and	#$000f,d2
	add	d1,d0
	add	d2,d0
	divu	#3,d0		; grey brightness 0..15
	mulu	#11,d0
	divu	#15,d0		; 0..11
	addq	#4,d0		; safe grey palette indices 4..15
	bra.s	.g2v190aj_lut_store
.g2v190aj_lut_black
	moveq	#4,d0
.g2v190aj_lut_store
	; v190fy: write direct safe grey palette indices 4..15 into the
	; static menu backdrop.  Do not pass these through paladjust here:
	; on some C2P/palette layouts that can land in font colour slots 1..3,
	; which initmenu later turns yellow for the menu text.
	move.b	d0,0(a3,d3.w)
	addq	#1,d3
	dbf	d7,.g2v190aj_lut_loop
.g2v190aj_lut_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

g2v190aj_apply_grey_lut
	movem.l	d0-d7/a0-a1,-(a7)
	move.l	chunky,d0
	beq.s	.g2v190aj_ag_done
	move.l	d0,a0
	lea	g2v190aj_lut,a1
	move	#239,d6
.g2v190aj_ag_y
	move	#319,d7
.g2v190aj_ag_x
	moveq	#0,d0
	move.b	(a0),d0
	move.b	0(a1,d0.w),(a0)+
	dbf	d7,.g2v190aj_ag_x
	dbf	d6,.g2v190aj_ag_y
.g2v190aj_ag_done
	movem.l	(a7)+,d0-d7/a0-a1
	rts

; v190aj grey menu temporary palette/LUT storage.  Kept at the file end so it
; does not disturb nearby PC-relative code/data ranges.
g2v190aj_saved_lastpal	dc.l	0
g2v190aj_grey_pal	ds.w	512
g2v190aj_invpal	ds.b	256
g2v190aj_lut	ds.b	256
	even


; -----------------------------------------------------------------------------
; v190cj Black Magic engine compatibility profile layer
; Appended deliberately at the end so existing PC-relative code/data ranges stay
; as stable as possible for GenAm.
; -----------------------------------------------------------------------------

g2_game_profile	dc	0	;0=gloom deluxe, 1=gloom original, 2=zombie massacre, 3=gloom3/compat
g2zm_g3dcbrush	dc.l	0	; v190hu: physical Zombie Massacre g3-dc kept for ABOUT
g2zm_old_title_pal	dc.l	0	; v190hu: physical Zombie Massacre title/g3-dc palette for ABOUT
g2magicfiles_ptr	dc.l	magicfiles
g2agamagicfiles_ptr	dc.l	agamagicfiles
g2ecsmagicfiles_ptr	dc.l	ecsmagicfiles
g2agafiles_ptr	dc.l	agafiles
g2ecsfiles_ptr	dc.l	ecsfiles
g2progfiles_ptr	dc.l	progfiles
g2datafiles_ptr	dc.l	datafiles
g2dataprobe_name	dc.l	scriptname
g2title_aga_ptr	dc.l	g2v190p_title_aga
g2title_ecs_ptr	dc.l	g2v190p_title_ecs

; Gloom original: v190gl uses the normal Gloom2 asset layout with
; physical-file-first / embedded-fallback behaviour for missing modern files.
g1agafiles	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	planar_palette
	dc.b	'misc/palette_8',0
	even
	dc.l	planar_remap
	dc.b	'misc/remap_8',0
	even
	dc.l	0

g1ecsfiles	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	planar_palette
	dc.b	'misc/palette_8',0
	even
	dc.l	planar_remap
	dc.b	'misc/remap_8',0
	even
	dc.l	0

g1progfiles	dc.l	gloomcfg
	dc.b	'gloomcfg',0
	even
	dc.l	bigfont_+1
	dc.b	'misc/bigfont2.bin',0
	even
	dc.l	panel
	dc.b	'misc/smallfont2.bin',0
	even
	dc.l	gunpic
	dc.b	'misc/gun.bin',0
	even
	dc.l	titlemed+1
	dc.b	'sfxs/med1',0
	even
	dc.l	loadingmed+1
	dc.b	'sfxs/med2',0
	even
	dc.l	shootsfx+1
	dc.b	'sfxs/shoot.bin',0
	even
	dc.l	shootsfx2+1
	dc.b	'sfxs/shoot2.bin',0
	even
	dc.l	shootsfx3+1
	dc.b	'sfxs/shoot3.bin',0
	even
	dc.l	shootsfx4+1
	dc.b	'sfxs/shoot4.bin',0
	even
	dc.l	shootsfx5+1
	dc.b	'sfxs/shoot5.bin',0
	even
	dc.l	gruntsfx+1
	dc.b	'sfxs/grunt.bin',0
	even
	dc.l	gruntsfx2+1
	dc.b	'sfxs/grunt2.bin',0
	even
	dc.l	gruntsfx3+1
	dc.b	'sfxs/grunt3.bin',0
	even
	dc.l	gruntsfx4+1
	dc.b	'sfxs/grunt4.bin',0
	even
	dc.l	tokensfx+1
	dc.b	'sfxs/token.bin',0
	even
	dc.l	doorsfx+1
	dc.b	'sfxs/door.bin',0
	even
	dc.l	footstepsfx+1
	dc.b	'sfxs/footstep.bin',0
	even
	dc.l	diesfx+1
	dc.b	'sfxs/die.bin',0
	even
	dc.l	splatsfx+1
	dc.b	'sfxs/splat.bin',0
	even
	dc.l	telesfx+1
	dc.b	'sfxs/teleport.bin',0
	even
	dc.l	ghoulsfx+1
	dc.b	'sfxs/ghoul.bin',0
	even
	dc.l	lizsfx+1
	dc.b	'sfxs/lizard.bin',0
	even
	dc.l	lizhitsfx+1
	dc.b	'sfxs/lizhit.bin',0
	even
	dc.l	trollsfx+1
	dc.b	'sfxs/trollmad.bin',0
	even
	dc.l	trollhitsfx+1
	dc.b	'sfxs/trollhit.bin',0
	even
	dc.l	robotsfx+1
	dc.b	'sfxs/robot.bin',0
	even
	dc.l	robodiesfx+1
	dc.b	'sfxs/robodie.bin',0
	even
	dc.l	dragonsfx+1
	dc.b	'sfxs/dragon.bin',0
	even
	dc.l	0

g1title_aga	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	0

g1title_ecs	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	0

; v190gl: retained aliases so older profile code/data references stay valid.
g1title_optional_aga	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	0

g1title_optional_ecs	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	0

; Zombie Massacre: pixs/stuf/musi/char/lvls layout.
zmmagicfiles	dc.l	magic
	dc.b	'pixs/alphasoftw',0
	even
	dc.l	0

zmagamagicfiles	dc.l	magicpal
	dc.b	'pixs/alphasoftw.pal',0
	even
	dc.l	0

zmecsmagicfiles	dc.l	magicpal
	dc.b	'pixs/alphasoftw.pal',0
	even
	dc.l	0

zmagafiles	dc.l	gloom
	dc.b	'pixs/title',0
	even
	dc.l	gloompal
	dc.b	'pixs/title.pal',0
	even
	dc.l	g2zm_g3dcbrush
	dc.b	'pixs/g3-dc',0
	even
	dc.l	planar_palette
	dc.b	'stuf/palette_8',0
	even
	dc.l	planar_remap
	dc.b	'stuf/remap_8',0
	even
	dc.l	0

zmecsfiles	dc.l	gloom
	dc.b	'pixs/title',0
	even
	dc.l	gloompal
	dc.b	'pixs/title.pal',0
	even
	dc.l	g2zm_g3dcbrush	; v190ht: keep Zombie Massacre g3-dc available for title/menu overlay on ECS/non-AGA paths too
	dc.b	'pixs/g3-dc',0
	even
	dc.l	planar_palette
	dc.b	'stuf/palette_6',0
	even
	dc.l	planar_remap
	dc.b	'stuf/remap_6',0
	even
	dc.l	0

zmprogfiles	dc.l	gloomcfg
	dc.b	'gloomcfg',0
	even
	dc.l	bigfont_+1
	dc.b	'stuf/bigfont2.bin',0
	even
	dc.l	panel
	dc.b	'stuf/smallfont2.bin',0
	even
	dc.l	gunpic
	dc.b	'stuf/gun.bin',0
	even
	dc.l	titlemed+1
	dc.b	'musi/medA',0
	even
	dc.l	loadingmed+1
	dc.b	'musi/medB',0
	even
	dc.l	shootsfx+1
	dc.b	'musi/shoot.bin',0
	even
	dc.l	shootsfx2+1
	dc.b	'musi/shoot2.bin',0
	even
	dc.l	shootsfx3+1
	dc.b	'musi/shoot3.bin',0
	even
	dc.l	shootsfx4+1
	dc.b	'musi/shoot4.bin',0
	even
	dc.l	shootsfx5+1
	dc.b	'musi/shoot5.bin',0
	even
	dc.l	gruntsfx+1
	dc.b	'musi/groan.bin',0
	even
	dc.l	gruntsfx2+1
	dc.b	'musi/groan2.bin',0
	even
	dc.l	gruntsfx3+1
	dc.b	'musi/groan3.bin',0
	even
	dc.l	gruntsfx4+1
	dc.b	'musi/groan4.bin',0
	even
	dc.l	tokensfx+1
	dc.b	'musi/pwrup.bin',0
	even
	dc.l	doorsfx+1
	dc.b	'musi/door.bin',0
	even
	dc.l	footstepsfx+1
	dc.b	'musi/footstep.bin',0
	even
	dc.l	diesfx+1
	dc.b	'musi/die.bin',0
	even
	dc.l	splatsfx+1
	dc.b	'musi/splat.bin',0
	even
	dc.l	telesfx+1
	dc.b	'musi/teleport.bin',0
	even
	dc.l	ghoulsfx+1
	dc.b	'musi/ghost.bin',0
	even
	dc.l	lizsfx+1
	dc.b	'musi/skinny.bin',0
	even
	dc.l	lizhitsfx+1
	dc.b	'musi/skihit.bin',0
	even
	dc.l	trollsfx+1
	dc.b	'musi/jamesmad.bin',0
	even
	dc.l	trollhitsfx+1
	dc.b	'musi/jameshit.bin',0
	even
	dc.l	robotsfx+1
	dc.b	'musi/fatzo.bin',0
	even
	dc.l	robodiesfx+1
	dc.b	'musi/fatzdie.bin',0
	even
	dc.l	dragonsfx+1
	dc.b	'musi/zombie.bin',0
	even
	dc.l	0

zmdatafiles	dc.l	script
zmstagesname	dc.b	'stuf/stages',0
	even
	dc.l	0

zmtitle_aga	dc.l	gloom
	dc.b	'pixs/title',0
	even
	dc.l	gloompal
	dc.b	'pixs/title.pal',0
	even
	dc.l	g2zm_g3dcbrush
	dc.b	'pixs/g3-dc',0
	even
	dc.l	0

zmtitle_ecs	dc.l	gloom
	dc.b	'pixs/title',0
	even
	dc.l	gloompal
	dc.b	'pixs/title.pal',0
	even
	dc.l	g2zm_g3dcbrush	; v190ht: keep Zombie Massacre g3-dc available for title/menu overlay on ECS/non-AGA paths too
	dc.b	'pixs/g3-dc',0
	even
	dc.l	0

g2probe_zm_stages	dc.b	'stuf/stages',0
	even
g2probe_zm_title	dc.b	'pixs/title',0
	even
g2probe_pics_title	dc.b	'pics/title',0
	even
g2probe_misc_script	dc.b	'misc/script',0
	even
g2probe_misc_palette8	dc.b	'misc/palette_8',0
	even
g2probe_pics_blackmagic	dc.b	'pics/blackmagic',0
	even

g2zm_map_prefix	dc.b	'lvls/',0
	even
g2zm_pic_prefix	dc.b	'pixs/',0
	even
g2zm_obj_player	dc.b	'char/kforee',0
	even
g2zm_obj_tokens	dc.b	'char/pwrups',0
	even
g2zm_obj_marine	dc.b	'char/troopr',0
	even
g2zm_obj_baldy	dc.b	'char/zombi',0
	even
g2zm_obj_terra	dc.b	'char/fatzo',0
	even
g2zm_obj_ghoul	dc.b	'char/ghost',0
	even
g2zm_obj_demon	dc.b	'char/zocom',0
	even
g2zm_obj_phantom	dc.b	'char/zomboid',0
	even
g2zm_obj_lizard	dc.b	'char/skinny',0
	even
g2zm_obj_deathhead	dc.b	'char/dows-head',0
	even
g2zm_obj_dragon	dc.b	'char/zombie',0
	even
g2zm_obj_troll	dc.b	'char/james',0
	even

g2fileexists	;in a0=file name, returns d0=0 and Z if present, -1 if absent
	movem.l	d1-d2/a0/a6,-(a7)
	move.l	dosbase,a6
	move.l	a0,d1
	move.l	#1005,d2
	jsr	-30(a6)
	tst.l	d0
	beq.s	.no
	move.l	d0,d1
	jsr	-36(a6)
	moveq	#0,d0
	bra.s	.done
.no	moveq	#-1,d0
.done	movem.l	(a7)+,d1-d2/a0/a6
	tst.l	d0
	rts

g2copystr	;in a0=src, a1=dst
	move.b	(a0)+,(a1)+
	bne.s	g2copystr
	rts

g2apply_zm_strings
	movem.l	a0-a1,-(a7)
	lea	g2zm_map_prefix,a0
	lea	mappath,a1
	bsr	g2copystr
	lea	g2zm_pic_prefix,a0
	lea	agapicpath,a1
	bsr	g2copystr
	lea	g2zm_pic_prefix,a0
	lea	ecspicpath,a1
	bsr	g2copystr
	lea	g2zm_obj_player,a0
	lea	player+8,a1
	bsr	g2copystr
	lea	g2zm_obj_tokens,a0
	lea	tokens+8,a1
	bsr	g2copystr
	lea	g2zm_obj_marine,a0
	lea	marine+8,a1
	bsr	g2copystr
	lea	g2zm_obj_baldy,a0
	lea	baldy+8,a1
	bsr	g2copystr
	lea	g2zm_obj_terra,a0
	lea	terra+8,a1
	bsr	g2copystr
	lea	g2zm_obj_ghoul,a0
	lea	ghoul+8,a1
	bsr	g2copystr
	lea	g2zm_obj_demon,a0
	lea	demon+8,a1
	bsr	g2copystr
	lea	g2zm_obj_phantom,a0
	lea	phantom+8,a1
	bsr	g2copystr
	lea	g2zm_obj_lizard,a0
	lea	lizard+8,a1
	bsr	g2copystr
	lea	g2zm_obj_deathhead,a0
	lea	deathhead+8,a1
	bsr	g2copystr
	lea	g2zm_obj_dragon,a0
	lea	dragon+8,a1
	bsr	g2copystr
	lea	g2zm_obj_troll,a0
	lea	troll+8,a1
	bsr	g2copystr
	movem.l	(a7)+,a0-a1
	rts

g2gloomgame_fallback	dc.b	'game'
	even

g2ensure_gloomgame_fallback
	tst.l	gloomgame
	bne.s	.rts
	move.l	#g2gloomgame_fallback,gloomgame
.rts	rts

g2detectprofile
	clr	g2_game_profile
	move.l	#magicfiles,g2magicfiles_ptr
	move.l	#agamagicfiles,g2agamagicfiles_ptr
	move.l	#ecsmagicfiles,g2ecsmagicfiles_ptr
	move.l	#agafiles,g2agafiles_ptr
	move.l	#ecsfiles,g2ecsfiles_ptr
	move.l	#progfiles,g2progfiles_ptr
	move.l	#datafiles,g2datafiles_ptr
	move.l	#scriptname,g2dataprobe_name
	move.l	#g2v190p_title_aga,g2title_aga_ptr
	move.l	#g2v190p_title_ecs,g2title_ecs_ptr
	lea	g2probe_zm_stages,a0
	jsr	g2fileexists
	bne	.not_zm
	lea	g2probe_zm_title,a0
	jsr	g2fileexists
	bne	.not_zm
	move	#2,g2_game_profile
	move.l	#zmmagicfiles,g2magicfiles_ptr
	move.l	#zmagamagicfiles,g2agamagicfiles_ptr
	move.l	#zmecsmagicfiles,g2ecsmagicfiles_ptr
	move.l	#zmagafiles,g2agafiles_ptr
	move.l	#zmecsfiles,g2ecsfiles_ptr
	move.l	#zmprogfiles,g2progfiles_ptr
	move.l	#zmdatafiles,g2datafiles_ptr
	move.l	#zmstagesname,g2dataprobe_name
	move.l	#zmtitle_aga,g2title_aga_ptr
	move.l	#zmtitle_ecs,g2title_ecs_ptr
	bsr	g2apply_zm_strings
	rts
.not_zm
	lea	g2probe_pics_title,a0
	jsr	g2fileexists
	bne.s	.check_g1
	lea	g2probe_misc_script,a0	; title+script = Gloom Deluxe, Gloom3, or repacked Gloom
	jsr	g2fileexists
	bne.s	.done
	lea	g2probe_misc_palette8,a0	; classic Gloom has no Gloom2/G3 remap/palette set
	jsr	g2fileexists
	beq.s	.g2_title_has_palette
	jsr	g2setup_g1_profile	; optional pics/title + pics/gloom, but old data layout
	rts
.g2_title_has_palette
	lea	gamename,a0		; Gloom Deluxe has gloomgame, Gloom3 usually does not
	jsr	g2fileexists
	beq.s	.done		; keep profile 0: Gloom Deluxe, visible title menu stays classic
	move	#3,g2_game_profile	; Gloom3 compatibility: classic menu without START LEVEL
	rts
.check_g1
	lea	g2probe_misc_script,a0
	jsr	g2fileexists
	bne.s	.done
	lea	g2probe_pics_blackmagic,a0
	jsr	g2fileexists
	bne.s	.done
	jsr	g2setup_g1_profile
.done	rts

g2setup_g1_profile
	move	#1,g2_game_profile
	move.l	#g1agafiles,g2agafiles_ptr
	move.l	#g1ecsfiles,g2ecsfiles_ptr
	move.l	#g1progfiles,g2progfiles_ptr
	move.l	#g1title_aga,g2title_aga_ptr
	move.l	#g1title_ecs,g2title_ecs_ptr
	rts


; -----------------------------------------------------------------------------
; v190cv: safe Gloom Original menu text path
; -----------------------------------------------------------------------------
; The original Gloom misc/smallfont.bin / bigfont.bin files use the older
; Black Magic blit-shape layout.  The Gloom2/Reforged title menu blitter expects
; the newer smallfont2/bigfont2 layout, so using the old font directly can jump
; through bogus glyph metadata as soon as the title menu is opened.  For profile
; 1 only, draw compact title/menu text from the built-in chatfont directly into
; the planar title bitmap.  Other profiles stay on the normal Gloom2 font path.

g2v190cv_printmess2_g1_safe
	movem.l	d0-d7/a0-a3/a5-a6,-(a7)
	move	fontw,d2
	lsr	#1,d2
	mulu	d2,d0
	move	#160,d7
	sub	d0,d7
	and	#$fff8,d7	; byte-align compact menu text for the 1-byte chatfont glyphs
.g2v190cv_loop
	move.b	(a4)+,d0
	beq.s	.g2v190cv_done
	cmp.b	#' ',d0
	beq.s	.g2v190cv_space
	jsr	calcchar
	tst	d0
	bmi.s	.g2v190cv_space
	cmp	#39,d0
	bhi.s	.g2v190cv_space
	move	d0,d2
	jsr	g2v190cv_drawchatglyph
.g2v190cv_space
	add	fontw,d7
	bra.s	.g2v190cv_loop
.g2v190cv_done
	movem.l	(a7)+,d0-d7/a0-a3/a5-a6
	rts

g2v190cv_drawchatglyph	; d2=glyph, d7=x pixel, d6=y pixel
	movem.l	d0-d7/a0-a3,-(a7)
	lea	chatfont,a0
	adda.w	d2,a0
	move.l	showbitmap,a1
	tst.l	a1
	beq.s	.g2v190cv_glyph_done
	move	d6,d0
	addq	#1,d0	; sit visually in the 8px menu strip
	mulu	linemodw,d0
	add.l	d0,a1
	move	d7,d0
	asr	#3,d0
	add.w	d0,a1
	move.l	bpmod,d4
	moveq	#4,d3	; chatfont is 5 scanlines high
.g2v190cv_line
	move.b	(a0),d0
	beq.s	.g2v190cv_nextline
	move.b	d0,d1
	not.b	d1
	move.l	a1,a2
	move	bitplanes,d5
	subq	#1,d5
.g2v190cv_clearplanes
	and.b	d1,(a2)
	add.l	d4,a2
	dbf	d5,.g2v190cv_clearplanes
	; v190cx: classic Gloom's BlackMagic/menu palette has the blue
	; small-font colour on the lower bitplane index, not the orange index 4.
	; After clearing all planes, draw into bitplane 1 -> colour index 2.
	move	bitplanes,d5
	cmp	#2,d5
	bcs.s	.g2v190cw_g1_blue_fallback
	move.l	a1,a2
	add.l	d4,a2	; plane 1 = classic blue-ish title palette entry
	or.b	d0,(a2)
	bra.s	.g2v190cv_nextline
.g2v190cw_g1_blue_fallback
	move.l	a1,a2
	or.b	d0,(a2)	; single-plane fallback
.g2v190cv_nextline
	lea	40(a0),a0
	adda.w	linemodw,a1
	dbf	d3,.g2v190cv_line
.g2v190cv_glyph_done
	movem.l	(a7)+,d0-d7/a0-a3
	rts


; -----------------------------------------------------------------------------
; v190dl: original Gloom unsupported notice
; -----------------------------------------------------------------------------
; This executable is deliberately scoped to Gloom Deluxe, Gloom3 and
; Zombie Massacre. Classic Gloom keeps its own gloom.s branch because it has
; no Gloom2 title/gloom/gun/statusbar assets and uses a different HUD.

g2v190dl_g1_not_supported_screen
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	showbitmap,-(a7)
	jsr	g2v145_show_clean_title	; v190dm: keep BlackMagic visible behind the notice
	jsr	g2v190dl_g1_draw_unsupported_text
	move.l	drawbitmap,d0
	beq.s	.g2v190dl_notice_skip_hidden
	move.l	d0,showbitmap
	jsr	g2v190dl_g1_draw_unsupported_text
.g2v190dl_notice_skip_hidden
	move.l	(a7)+,showbitmap
	jsr	dispon	; v190dn: far call buildfix
	jsr	inputon
	jsr	g2v190dm_wait_return
	movem.l	(a7)+,d0-d7/a0-a4
	rts

g2v190dm_wait_return
	qkey	$44
	bne.s	g2v190dm_wait_return
.g2v190dm_wr_down
	jsr	vwait	; v190dn: far call buildfix
	qkey	$44
	beq.s	.g2v190dm_wr_down
.g2v190dm_wr_up
	jsr	vwait	; v190dn: far call buildfix
	qkey	$44
	bne.s	.g2v190dm_wr_up
	rts

g2v190dl_g1_draw_unsupported_text
	move	#8,fontw	; v190do: byte-aligned glyph spacing, readable spaces/letters
	move	#8,fonth
	lea	g2v190dl_msg1,a4
	move	#22,d0
	move	#200,d6	; v190dp: 3 text lines lower, lower quarter over BlackMagic screen
	jsr	g2v190cv_printmess2_g1_safe
	rts

g2v190dl_msg1	dc.b	'GLOOM IS NOT SUPPORTED',0
	even

; -----------------------------------------------------------------------------
; v190cx: original Gloom compatibility palette/remap support
; -----------------------------------------------------------------------------
; Original Gloom has no misc/palette_8 or misc/remap_8.  The old renderer built
; its game palette from the palettes found in textures/objects after the script
; events had loaded a map.  The Gloom2 chunky path still needs non-zero
; planar_palette/planar_remap pointers for effects, transparent objects and
; colour lookups, so build a conservative exact RGB12 -> palette-index table from
; the live map_rgbs pool.  The normal shade table remains identity for profile 1
; in calcpalettes above, matching the already-remapped original data.

g2v190cx_build_g1_tables
	cmp	#1,g2_game_profile
	bne.s	.g2v190cx_done
	; v190gl: if embedded/physical Gloom2 remap_8 is available, keep the
	; normal Gloom Deluxe fog/shade path instead of replacing it with the old
	; synthetic Gloom1 identity tables.
	tst.l	planar_remap
	bne.s	.g2v190cx_done
	movem.l	d0-d7/a0-a4,-(a7)
	lea	g2v190cx_g1_remap,a0
	moveq	#0,d0
	move	#4095,d7
.g2v190cx_clear
	move.b	d0,(a0)+
	dbf	d7,.g2v190cx_clear
	move.l	map_rgbs,a0
	move.l	map_rgbsat,a1
	lea	g2v190cx_g1_palette,a2
	lea	g2v190cx_g1_remap,a3
	moveq	#0,d3
.g2v190cx_loop
	move.l	a0,d4
	cmp.l	a1,d4
	bcc.s	.g2v190cx_built
	move	(a0)+,d0
	and	#$0fff,d0
	; Store in the same 4-byte-per-entry layout used by the chunky helpers
	; (high 12-bit word, low word zero), matching AGA palette files.
	move	d0,(a2)+
	clr	(a2)+
.g2v190cx_store_remap
	cmp	#256,d3
	bcc.s	.g2v190cx_next
	move.b	d3,0(a3,d0.w)
.g2v190cx_next
	addq	#1,d3
	bra.s	.g2v190cx_loop
.g2v190cx_built
	move.l	#g2v190cx_g1_palette,planar_palette
	move.l	#g2v190cx_g1_remap,planar_remap
	movem.l	(a7)+,d0-d7/a0-a4
.g2v190cx_done
	rts

	ifne	0
	; alignment marker only
	endc
	
	even
g2v190cx_g1_palette	ds.w	512
	
	even
g2v190cx_g1_remap	ds.b	4096
	even



; -----------------------------------------------------------------------------
; v190gn embedded Gloom Deluxe asset fallbacks for Classic Gloom
; -----------------------------------------------------------------------------
; The physical files are still preferred.  Only profile 1 gets these pointers
; when the modern Gloom2-style files are missing from the Classic Gloom data set.

g2embed_apply_g1_fallbacks
	cmp	#1,g2_game_profile
	bne.w	.g2emb_done
	movem.l	d0-d1/a0-a1,-(a7)
	;
	tst.l	bigfont_
	bne.s	.g2emb_have_bigfont
	lea	g2embed_bigfont2_crm,a0
	lea	g2embed_bigfont2_crm_end,a1
	moveq	#2,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,bigfont_
.g2emb_have_bigfont
	tst.l	panel
	bne.s	.g2emb_have_panel
	lea	g2embed_smallfont2_crm,a0
	lea	g2embed_smallfont2_crm_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,panel
.g2emb_have_panel
	tst.l	gunpic
	bne.s	.g2emb_have_gun
	lea	g2embed_gun,a0
	lea	g2embed_gun_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,gunpic
.g2emb_have_gun
	tst.l	gloom
	bne.s	.g2emb_have_title
	lea	g2embed_title,a0
	lea	g2embed_title_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,gloom
.g2emb_have_title
	tst.l	gloompal
	bne.s	.g2emb_have_titlepal
	move.l	#g2embed_title_pal,gloompal
.g2emb_have_titlepal
	tst.l	gloombrush
	bne.s	.g2emb_have_brush
	lea	g2embed_gloombrush,a0
	lea	g2embed_gloombrush_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,gloombrush
.g2emb_have_brush
	tst.l	planar_palette
	bne.s	.g2emb_have_palette
	lea	g2embed_palette8_crm,a0
	lea	g2embed_palette8_crm_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,planar_palette
.g2emb_have_palette
	tst.l	planar_remap
	bne.s	.g2emb_have_remap
	lea	g2embed_remap8_crm,a0
	lea	g2embed_remap8_crm_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,planar_remap
.g2emb_have_remap
	movem.l	(a7)+,d0-d1/a0-a1
.g2emb_done
	rts

; v190hw: Zombie Massacre uses the embedded g3-zm image for the title/menu
; overlay.  Pixels that would be affected by the menu font palette are remapped
; to safe unused title-palette slots so blood colours stay red when text appears.
; ABOUT stays title-only without g3-dc/g3-zm.
g2embed_apply_zm_title_overlay
	cmp	#2,g2_game_profile
	bne.s	.rts
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	gloompal,d0
	beq.s	.no_oldpal
	cmp.l	#g2embed_zm_title_pal,d0
	beq.s	.no_oldpal
	move.l	d0,g2zm_old_title_pal
.no_oldpal
	lea	g2embed_zm_titlebrush,a0
	lea	g2embed_zm_titlebrush_end,a1
	moveq	#1,d1
	bsr.w	g2embed_decrunch_asset
	move.l	d0,gloombrush
	jsr	g2zm_patch_title_palette_safe_slots	; v190hw: keep g3-zm blood colours stable after menu font palette
	; v190hw: keep the original Zombie title palette active; g3-zm uses safe title-palette slots.
	movem.l	(a7)+,d0-d1/a0-a1
.rts	rts

; v190hw: initfontpal overwrites AGA colour slots 0..3 in several banks
; when menu text appears.  The embedded g3-zm overlay is remapped away from
; those slots; patch the unused title-palette slots with the original colours.
g2zm_patch_title_palette_safe_slots
	movem.l	d0/a0,-(a7)
	cmp	#2,g2_game_profile
	bne.s	.done
	move.l	gloompal,d0
	beq.s	.done
	move.l	d0,a0
	move	#$0010,208(a0)	; slot 52 <- old slot 1
	move	#$0010,210(a0)
	move	#$0f20,212(a0)	; slot 53 <- old slot 3 / blood red
	move	#$0f20,214(a0)
	move	#$0640,216(a0)	; slot 54 <- old slot 32
	move	#$0640,218(a0)
	move	#$0630,220(a0)	; slot 55 <- old slot 33
	move	#$0630,222(a0)
	move	#$0760,224(a0)	; slot 56 <- old slot 34
	move	#$0760,226(a0)
	move	#$0750,228(a0)	; slot 57 <- old slot 35
	move	#$0750,230(a0)
.done	movem.l	(a7)+,d0/a0
	rts

; v190hu: temporary ABOUT-screen restore for Zombie Massacre.
g2zm_prepare_about_g3dc
	cmp	#2,g2_game_profile
	bne.s	.rts
	move.l	g2zm_old_title_pal,d0
	beq.s	.no_pal
	move.l	d0,gloompal
.no_pal
	move.l	g2zm_g3dcbrush,d0
	beq.s	.rts
	move.l	d0,gloombrush
.rts	rts

; a0=start of embedded file, a1=end of embedded file, d1=memtype.
; Returns d0=usable pointer.  CrM2/CrM! files are decrunched through the same
; decrm routine as loadfile; raw files are returned directly.
; v190gn: gun/title/gloombrush are now also passed through this path, because
; the correct Gloom Deluxe uploads are CrM2-compressed on disk.
g2embed_decrunch_asset
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a2		; embedded source start
	move.l	a1,d5
	sub.l	a2,d5		; source length
	move.l	a2,a0
	cmp.l	#'CrM2',(a0)
	beq.s	.g2emb_crunched
	cmp.l	#'CrM!',(a0)
	beq.s	.g2emb_crunched
	move.l	a2,d0
	bra.w	.g2emb_return
.g2emb_crunched
	moveq	#0,d6
	move.w	4(a2),d6
	add.l	#14,d6
	move.l	6(a2),d4	; decrunched length from CrM header
	move.l	d4,d0
	move.l	d1,d1
	move.l	d6,d2
	allocmem2	g2embed
	tst.l	d0
	beq.w	.g2emb_return
	sub.l	d6,d0
	move.l	d0,a3		; base for crunched bytes
	move.l	a2,a0
	move.l	a3,a1
	move.l	d5,d7
	beq.s	.g2emb_copied
	subq.l	#1,d7
.g2emb_copy
	move.b	(a0)+,(a1)+
	dbf	d7,.g2emb_copy
.g2emb_copied
	move.l	a3,a0		; decrm source
	move.l	a3,a1
	add.l	d6,a1		; decrm destination
	jsr	flushc
	jsr	decrm+32
	jsr	flushc
	move.l	a3,d0
	add.l	d6,d0		; return decrunched pointer
.g2emb_return
	movem.l	(a7)+,d1-d7/a0-a6
	rts

	even
g2embed_bigfont2_crm
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$0d,$d2,$00,$00,$04,$42,$01,$76
	dc.b	$67,$9a,$65,$c0,$16,$73,$4d,$7c,$d1,$ae,$01,$fc,$4c,$d3,$2e,$68
	dc.b	$37,$00,$6b,$1e,$68,$56,$68,$b7,$02,$0e,$4f,$34,$eb,$9a,$58,$0d
	dc.b	$fa,$9e,$68,$a7,$34,$fb,$80,$bf,$b3,$cd,$26,$e6,$89,$40,$ea,$17
	dc.b	$9a,$2d,$cd,$05,$e0,$03,$c5,$e6,$9d,$66,$92,$f9,$a2,$5c,$0f,$bd
	dc.b	$33,$45,$7c,$d2,$ae,$03,$df,$9c,$d3,$8e,$69,$d7,$02,$7e,$17,$34
	dc.b	$93,$9a,$4d,$c0,$1f,$89,$e6,$8d,$73,$4d,$b8,$00,$71,$73,$44,$f8
	dc.b	$17,$71,$7a,$fb,$bf,$8e,$39,$71,$b7,$35,$05,$44,$55,$c6,$dc,$8a
	dc.b	$52,$ff,$fe,$59,$1a,$45,$95,$c6,$fc,$d6,$21,$a2,$4b,$f7,$ae,$31
	dc.b	$14,$af,$c2,$33,$bd,$1b,$1b,$ce,$b8,$46,$67,$12,$5b,$37,$c2,$5e
	dc.b	$b5,$4c,$19,$a5,$3a,$f2,$22,$8c,$86,$91,$1d,$b4,$c1,$1a,$3b,$34
	dc.b	$70,$bd,$e2,$f4,$09,$b5,$e8,$7b,$e7,$09,$d8,$1b,$15,$7b,$6f,$8b
	dc.b	$30,$52,$ba,$b3,$a6,$98,$13,$b7,$43,$b6,$3a,$b8,$44,$dc,$38,$b3
	dc.b	$6e,$7a,$27,$17,$08,$c9,$3b,$a2,$3e,$d0,$a5,$02,$74,$66,$d4,$7d
	dc.b	$6a,$1c,$73,$26,$71,$75,$e3,$49,$e2,$c2,$ec,$c2,$9d,$7c,$de,$a0
	dc.b	$71,$0f,$7f,$a8,$73,$4c,$f0,$6f,$e7,$0f,$50,$06,$1a,$ef,$e2,$cc
	dc.b	$14,$ad,$08,$d1,$5e,$fe,$8a,$1a,$d1,$3e,$6f,$7a,$df,$22,$4c,$59
	dc.b	$24,$4a,$91,$58,$fe,$63,$98,$48,$94,$38,$01,$f9,$91,$24,$00,$7e
	dc.b	$e1,$4a,$fc,$d0,$01,$fa,$1a,$3a,$43,$d0,$88,$f7,$64,$3d,$0e,$14
	dc.b	$a6,$c6,$c2,$3d,$0f,$f1,$ee,$cb,$02,$31,$1d,$30,$eb,$7a,$1e,$ec
	dc.b	$c2,$b4,$34,$db,$86,$3b,$24,$74,$c8,$f8,$87,$09,$1f,$b4,$4f,$dc
	dc.b	$eb,$83,$0a,$31,$ae,$27,$30,$24,$39,$93,$be,$eb,$85,$61,$46,$a6
	dc.b	$76,$b0,$a1,$d3,$3b,$42,$91,$e2,$82,$b9,$8d,$4c,$e5,$22,$74,$3d
	dc.b	$1a,$44,$98,$00,$ff,$11,$4a,$7f,$0c,$3d,$0b,$47,$35,$66,$39,$e9
	dc.b	$98,$20,$58,$cc,$a2,$cc,$cc,$62,$29,$40,$cd,$94,$4e,$cd,$33,$31
	dc.b	$ff,$0a,$37,$51,$e3,$ce,$fa,$cf,$75,$c1,$10,$46,$37,$b7,$88,$f1
	dc.b	$88,$a7,$27,$d0,$13,$c8,$f4,$84,$60,$99,$9b,$7e,$77,$66,$72,$95
	dc.b	$f8,$66,$67,$29,$14,$89,$77,$66,$99,$cb,$47,$1d,$54,$31,$87,$3f
	dc.b	$38,$70,$a1,$c5,$98,$29,$57,$30,$6a,$18,$24,$7e,$d1,$1c,$c9,$b0
	dc.b	$8f,$3c,$a7,$1f,$38,$77,$20,$32,$ca,$16,$60,$a5,$21,$b7,$ed,$d0
	dc.b	$6c,$49,$54,$96,$41,$54,$77,$68,$e1,$0f,$43,$bc,$76,$25,$11,$47
	dc.b	$a3,$11,$4a,$23,$7d,$34,$d2,$3d,$1e,$47,$11,$1e,$ec,$b7,$76,$51
	dc.b	$ee,$fc,$29,$59,$77,$c4,$48,$f7,$73,$51,$3a,$98,$8c,$3d,$c2,$87
	dc.b	$26,$42,$59,$da,$14,$4a,$22,$8b,$f0,$c2,$ee,$4c,$c2,$b4,$cd,$04
	dc.b	$db,$75,$c2,$31,$87,$8b,$be,$62,$11,$8a,$39,$98,$72,$e1,$0b,$4e
	dc.b	$7b,$72,$3e,$43,$eb,$c8,$a3,$ba,$eb,$da,$14,$a2,$35,$dd,$79,$48
	dc.b	$eb,$87,$33,$4f,$ce,$14,$74,$b7,$c2,$cc,$14,$a2,$34,$c2,$40,$91
	dc.b	$95,$1d,$9a,$8f,$b3,$0c,$6e,$db,$8e,$b3,$c8,$ee,$1e,$71,$8c,$51
	dc.b	$82,$cc,$14,$a1,$98,$d0,$5e,$c4,$3b,$8c,$0f,$a3,$bb,$57,$57,$29
	dc.b	$86,$3c,$c6,$18,$99,$c5,$27,$9d,$f4,$90,$94,$31,$cc,$ef,$0a,$55
	dc.b	$a7,$22,$77,$82,$ec,$65,$26,$72,$23,$98,$ba,$38,$97,$a3,$af,$3a
	dc.b	$1d,$cc,$ab,$d3,$af,$68,$52,$a3,$f1,$1d,$ad,$8c,$47,$66,$8e,$68
	dc.b	$82,$31,$4c,$7a,$03,$27,$77,$25,$98,$29,$52,$41,$d1,$27,$7c,$47
	dc.b	$a1,$14,$4b,$8f,$51,$f6,$d2,$c9,$23,$e7,$0a,$37,$e3,$ad,$dd,$22
	dc.b	$56,$9e,$d8,$f6,$d4,$f1,$9f,$1d,$fe,$70,$9e,$4a,$ac,$b0,$22,$95
	dc.b	$f8,$5b,$98,$36,$e1,$98,$fb,$47,$7c,$e9,$b0,$9b,$22,$5d,$ab,$12
	dc.b	$e3,$28,$89,$70,$a4,$48,$dd,$00,$41,$22,$54,$bb,$63,$b8,$93,$18
	dc.b	$f0,$17,$68,$ba,$cf,$3e,$ef,$4f,$d0,$67,$ce,$8f,$79,$a2,$24,$85
	dc.b	$23,$6b,$07,$25,$19,$c0,$b6,$7d,$44,$b9,$1c,$c2,$3a,$f4,$8b,$6b
	dc.b	$36,$d3,$6b,$7f,$38,$5f,$57,$a0,$98,$83,$5e,$85,$98,$29,$4f,$a0
	dc.b	$2d,$82,$af,$cc,$c4,$04,$e7,$ea,$3e,$db,$26,$d5,$f1,$26,$01,$e2
	dc.b	$8e,$3c,$e8,$f8,$20,$e0,$ec,$19,$82,$a0,$9e,$8f,$b1,$14,$88,$8e
	dc.b	$c3,$36,$d3,$1f,$a2,$c8,$3a,$11,$f2,$83,$32,$aa,$3b,$b5,$7e,$91
	dc.b	$d7,$0a,$31,$ae,$d2,$fc,$44,$ad,$34,$61,$ce,$b9,$cc,$68,$c2,$94
	dc.b	$d9,$aa,$51,$26,$27,$35,$50,$a7,$ce,$17,$cf,$19,$a1,$b4,$6d,$fa
	dc.b	$27,$70,$7a,$4d,$51,$2e,$6b,$10,$f7,$31,$66,$0a,$51,$91,$b9,$8e
	dc.b	$d8,$ca,$ac,$eb,$03,$46,$e5,$81,$a3,$99,$54,$55,$11,$fe,$75,$2d
	dc.b	$59,$d0,$b3,$11,$5e,$5a,$ef,$e2,$b0,$54,$2d,$ae,$11,$06,$34,$be
	dc.b	$06,$57,$db,$e3,$81,$69,$d9,$01,$d0,$bb,$42,$2c,$a1,$60,$a1,$40
	dc.b	$b1,$66,$03,$04,$82,$c2,$a1,$71,$48,$cc,$76,$41,$22,$93,$4a,$27
	dc.b	$73,$da,$05,$06,$91,$4c,$a7,$56,$2c,$56,$4b,$45,$a6,$e1,$71,$b9
	dc.b	$5c,$ee,$97,$6b,$bd,$ee,$fb,$82,$c5,$63,$32,$99,$6c,$f6,$83,$45
	dc.b	$a8,$d5,$6d,$37,$dc,$0e,$0f,$23,$95,$d0,$e9,$77,$3b,$de,$2f,$37
	dc.b	$bf,$ed,$fd,$09,$41,$e1,$10,$98,$6c,$3a,$1f,$10,$8d,$47,$a5,$d3
	dc.b	$09,$b4,$f2,$85,$6b,$ea,$7a,$3e,$5f,$3f,$d4,$72,$3f,$24,$9d,$4f
	dc.b	$e8,$96,$6b,$3d,$bf,$f2,$11,$81,$c3,$27,$d6,$3b,$cf,$d3,$f1,$fe
	dc.b	$ff,$83,$01,$a0,$e8,$14,$1a,$31,$34,$9c,$58,$2d,$97,$8f,$b8,$40
	dc.b	$11,$7c,$bf,$ff,$01,$57,$ef,$80,$18,$16,$04,$01,$01,$f0,$00,$90
	dc.b	$28,$3c,$06,$01,$00,$40,$07,$c4,$e5,$42,$39,$91,$25,$42,$00,$03
g2embed_bigfont2_crm_end

	even
g2embed_smallfont2_crm
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$23,$82,$00,$00,$07,$98,$32,$07
	dc.b	$b7,$e2,$f8,$44,$ab,$ed,$e8,$07,$1f,$b0,$cb,$ec,$15,$fd,$84,$9f
	dc.b	$61,$67,$a2,$3d,$fd,$f6,$06,$7b,$00,$7f,$61,$97,$a2,$69,$e1,$fb
	dc.b	$00,$7b,$01,$7f,$60,$d7,$a2,$43,$bc,$00,$49,$33,$e0,$df,$d8,$4e
	dc.b	$f6,$09,$7a,$20,$28,$7e,$c2,$af,$60,$4f,$ec,$2a,$f4,$4b,$84,$fd
	dc.b	$84,$3d,$85,$c0,$23,$d3,$ec,$02,$f4,$44,$69,$c0,$d0,$7f,$b0,$b3
	dc.b	$ec,$38,$e8,$9a,$63,$f6,$17,$bd,$84,$bf,$b0,$9b,$f6,$1a,$7a,$22
	dc.b	$d6,$de,$c0,$af,$60,$17,$d8,$2e,$d1,$05,$93,$f6,$17,$76,$1f,$7a
	dc.b	$24,$36,$60,$9d,$87,$6f,$60,$a7,$ec,$28,$f4,$42,$a0,$7a,$25,$9d
	dc.b	$ee,$b7,$a7,$70,$ed,$64,$b5,$4d,$d4,$4c,$d7,$c5,$31,$e5,$5f,$f6
	dc.b	$41,$b7,$91,$69,$01,$65,$09,$5b,$22,$dd,$2a,$ad,$d9,$4c,$2c,$87
	dc.b	$72,$f2,$28,$f5,$ce,$27,$57,$e0,$4d,$40,$f8,$2a,$ad,$a6,$ab,$8f
	dc.b	$23,$33,$e6,$17,$5e,$c7,$a2,$fc,$61,$2e,$35,$a2,$dc,$d4,$e8,$87
	dc.b	$16,$7a,$2e,$3c,$e4,$a5,$75,$16,$a5,$64,$b5,$4d,$90,$eb,$65,$b9
	dc.b	$a9,$c3,$aa,$8d,$32,$a1,$d8,$b2,$33,$90,$37,$20,$f8,$a4,$53,$2d
	dc.b	$cc,$0f,$cb,$33,$02,$4e,$2f,$22,$6f,$d4,$39,$4a,$fb,$23,$6e,$7d
	dc.b	$3a,$56,$a9,$bc,$ac,$fe,$dc,$ac,$f5,$48,$87,$42,$c8,$66,$29,$01
	dc.b	$11,$0d,$93,$e9,$a1,$c0,$a9,$10,$0b,$8b,$73,$94,$ae,$d2,$b5,$41
	dc.b	$c8,$76,$d2,$bb,$6a,$eb,$04,$25,$90,$97,$bb,$0b,$40,$de,$43,$34
	dc.b	$4c,$c6,$2c,$e1,$99,$08,$71,$76,$54,$83,$27,$25,$b9,$cd,$bc,$4c
	dc.b	$2c,$4e,$09,$35,$bd,$b6,$fd,$c8,$a5,$b7,$e7,$e8,$d8,$31,$75,$a7
	dc.b	$b9,$f4,$fe,$b4,$ee,$1d,$6a,$5b,$ce,$21,$d6,$f7,$e8,$8f,$89,$90
	dc.b	$43,$a1,$79,$cb,$6e,$14,$25,$2c,$eb,$e9,$08,$f0,$83,$45,$21,$62
	dc.b	$f9,$98,$2f,$7e,$20,$d3,$49,$d6,$ab,$be,$c0,$ac,$af,$96,$f4,$55
	dc.b	$1b,$04,$3b,$f4,$78,$6c,$fd,$44,$bc,$57,$36,$e0,$7a,$4b,$a2,$83
	dc.b	$bf,$23,$e4,$cd,$c1,$09,$26,$39,$61,$17,$88,$6d,$9d,$d6,$69,$f3
	dc.b	$98,$7c,$8c,$79,$c3,$a1,$fc,$85,$33,$a6,$35,$a9,$12,$01,$06,$84
	dc.b	$53,$e4,$58,$ba,$c3,$a1,$cd,$cc,$59,$47,$79,$10,$1d,$6c,$85,$bf
	dc.b	$21,$1e,$a9,$4f,$20,$d0,$50,$ac,$96,$ce,$8e,$c8,$46,$e0,$2f,$0a
	dc.b	$99,$26,$0a,$f2,$90,$31,$b3,$28,$91,$2c,$08,$72,$03,$40,$50,$b2
	dc.b	$04,$f8,$d5,$c4,$91,$16,$43,$8b,$92,$4c,$08,$9a,$3c,$b5,$e8,$af
	dc.b	$f6,$b0,$60,$07,$e8,$c4,$07,$81,$a7,$38,$2e,$06,$07,$69,$6e,$32
	dc.b	$86,$69,$cf,$e7,$e5,$78,$55,$fe,$ae,$1e,$bd,$5e,$35,$b5,$a1,$48
	dc.b	$8e,$00,$49,$58,$40,$31,$a1,$66,$ac,$01,$00,$18,$50,$0c,$1e,$00
	dc.b	$70,$f0,$4d,$0e,$06,$9c,$d1,$10,$14,$5e,$f8,$e6,$e7,$ad,$57,$c4
	dc.b	$73,$73,$73,$1c,$0a,$71,$e6,$2d,$45,$b7,$07,$1c,$49,$f1,$bb,$9b
	dc.b	$91,$72,$00,$51,$79,$d0,$01,$6b,$81,$b0,$2e,$14,$55,$a6,$62,$aa
	dc.b	$26,$33,$0e,$1a,$1d,$c9,$d9,$a7,$6e,$68,$0e,$41,$ce,$4a,$00,$51
	dc.b	$c2,$c5,$98,$23,$b8,$e3,$72,$10,$58,$a2,$87,$99,$de,$31,$ba,$eb
	dc.b	$a1,$90,$18,$07,$49,$98,$76,$2a,$32,$d8,$ae,$17,$15,$20,$85,$0c
	dc.b	$56,$00,$2a,$41,$13,$6b,$81,$d2,$a8,$d6,$3c,$15,$ca,$51,$de,$8c
	dc.b	$2a,$a5,$30,$18,$42,$0e,$a3,$30,$30,$43,$51,$60,$eb,$e7,$00,$67
	dc.b	$01,$7c,$32,$1d,$84,$15,$60,$95,$63,$20,$3f,$0f,$81,$80,$9c,$9b
	dc.b	$37,$90,$86,$76,$6c,$d9,$a7,$7b,$c4,$32,$a7,$4a,$d7,$c4,$48,$70
	dc.b	$c0,$9d,$01,$4d,$20,$a8,$f0,$31,$b5,$ab,$52,$b2,$c0,$38,$21,$5b
	dc.b	$ac,$c8,$6b,$ae,$43,$6c,$28,$9e,$65,$75,$97,$17,$60,$01,$b5,$06
	dc.b	$0d,$ae,$d8,$5f,$7e,$7b,$8d,$d7,$a0,$6d,$71,$9a,$fb,$68,$0a,$c0
	dc.b	$b5,$a8,$35,$ba,$6b,$8f,$5e,$ba,$5b,$48,$5e,$06,$ba,$07,$b7,$1b
	dc.b	$3b,$3d,$69,$6e,$de,$b5,$ad,$7a,$f6,$ed,$a4,$2c,$ec,$ee,$83,$d6
	dc.b	$81,$eb,$ad,$ab,$5d,$b4,$85,$9d,$70,$da,$d7,$69,$5e,$92,$11,$12
	dc.b	$ef,$5c,$67,$a3,$c6,$98,$f2,$7a,$b8,$da,$1e,$05,$1e,$5a,$47,$a9
	dc.b	$0a,$69,$a6,$b9,$1e,$2e,$1e,$5c,$a7,$1d,$16,$bd,$8b,$a0,$dc,$1e
	dc.b	$f1,$73,$f5,$d5,$f2,$8b,$07,$3c,$e0,$7f,$fa,$23,$7f,$fc,$61,$3f
	dc.b	$fe,$b9,$5f,$7e,$3f,$e9,$2d,$1e,$62,$3e,$a9,$7e,$99,$8f,$d8,$b0
	dc.b	$af,$f9,$1c,$83,$ff,$ff,$c7,$eb,$23,$3d,$e8,$ef,$4c,$fe,$16,$f5
	dc.b	$bf,$b3,$f7,$d3,$eb,$de,$d7,$19,$ef,$ef,$d5,$fb,$e9,$b7,$d4,$6f
	dc.b	$af,$df,$4a,$be,$b9,$63,$d5,$bc,$f5,$10,$3f,$fc,$6c,$2b,$fe,$8a
	dc.b	$1f,$7d,$21,$7d,$e1,$60,$ff,$f9,$fd,$7a,$81,$f2,$de,$72,$5e,$bf
	dc.b	$6b,$fb,$9f,$a9,$7a,$af,$f1,$f5,$12,$44,$63,$eb,$f1,$f5,$2c,$7d
	dc.b	$4d,$fc,$3a,$ef,$51,$3f,$29,$f8,$67,$f3,$37,$6e,$46,$39,$9e,$47
	dc.b	$cc,$5d,$b8,$00,$5d,$a4,$08,$37,$54,$38,$9e,$07,$18,$a8,$8c,$47
	dc.b	$87,$b1,$b8,$1a,$7d,$45,$5c,$31,$7b,$1b,$c0,$6f,$de,$61,$c1,$72
	dc.b	$33,$6c,$f8,$fc,$25,$29,$43,$85,$2e,$b1,$ce,$4a,$6f,$de,$70,$ef
	dc.b	$7c,$b9,$2b,$9a,$f7,$d2,$2f,$a9,$7e,$7c,$cb,$ef,$d9,$ba,$f9,$fd
	dc.b	$37,$9c,$ab,$e6,$57,$ef,$db,$7f,$05,$ff,$b6,$37,$9d,$5d,$0f,$bf
	dc.b	$2d,$e1,$1d,$eb,$1f,$af,$b5,$f5,$cf,$7d,$7a,$fa,$7a,$c1,$c3,$f7
	dc.b	$ee,$fd,$64,$fe,$74,$7f,$86,$45,$7b,$c4,$df,$a9,$7f,$d0,$de,$5e
	dc.b	$b4,$7e,$fd,$c7,$c9,$dd,$fa,$2b,$7d,$70,$fd,$fb,$96,$fa,$a3,$bd
	dc.b	$2d,$c6,$7b,$ed,$87,$a8,$bd,$f5,$23,$f5,$eb,$25,$fd,$fb,$7a,$14
	dc.b	$9e,$ac,$ff,$11,$de,$9a,$e3,$fb,$80,$fd,$f6,$6f,$d6,$0f,$fd,$0f
	dc.b	$f3,$7a,$c5,$f7,$ea,$bf,$ad,$eb,$6a,$fd,$4f,$78,$fd,$51,$37,$d7
	dc.b	$18,$be,$a7,$fb,$7e,$b9,$6b,$7a,$a5,$d7,$ea,$07,$33,$d6,$96,$fd
	dc.b	$62,$eb,$f5,$ab,$fc,$49,$bc,$62,$be,$58,$fe,$67,$3c,$41,$f1,$4f
	dc.b	$c3,$65,$7f,$ac,$9f,$3e,$78,$82,$49,$3e,$22,$10,$23,$f9,$9c,$39
	dc.b	$60,$bc,$fe,$00,$c3,$f9,$d8,$2a,$c3,$f9,$91,$cd,$e6,$2c,$5e,$2d
	dc.b	$30,$18,$a8,$74,$62,$2f,$d3,$66,$6e,$2b,$9e,$64,$df,$28,$9e,$24
	dc.b	$08,$30,$9b,$00,$19,$cc,$b8,$28,$7c,$dc,$1f,$9e,$02,$0c,$e0,$34
	dc.b	$38,$72,$e6,$43,$46,$cb,$57,$95,$fd,$92,$95,$88,$13,$1b,$56,$aa
	dc.b	$10,$07,$ac,$1a,$4c,$70,$0d,$12,$fe,$c5,$13,$78,$68,$e0,$78,$9f
	dc.b	$10,$3f,$49,$ef,$d8,$aa,$b3,$d6,$13,$1a,$f4,$b0,$1e,$ea,$f2,$7f
	dc.b	$f8,$43,$5e,$fc,$27,$ae,$93,$78,$c5,$13,$1b,$d7,$af,$9b,$d5,$54
	dc.b	$f1,$25,$0e,$0a,$bd,$5e,$ab,$77,$f0,$73,$2c,$5e,$aa,$49,$df,$36
	dc.b	$80,$be,$85,$57,$ad,$db,$df,$9d,$df,$3e,$bf,$8c,$38,$55,$27,$2f
	dc.b	$5e,$b8,$81,$9e,$a2,$9e,$25,$ab,$55,$80,$3f,$22,$fd,$19,$e2,$0b
	dc.b	$63,$f1,$19,$6a,$bf,$5f,$11,$42,$3e,$5b,$70,$97,$a3,$b9,$21,$63
	dc.b	$87,$c3,$bf,$42,$f4,$6d,$aa,$4f,$cf,$b1,$c1,$ab,$0f,$86,$08,$56
	dc.b	$0e,$90,$7c,$38,$03,$3f,$09,$47,$c5,$bc,$4d,$cc,$25,$e0,$20,$f9
	dc.b	$f5,$70,$7c,$30,$20,$ca,$a8,$ff,$61,$29,$f2,$4f,$01,$d8,$38,$33
	dc.b	$f4,$8d,$80,$f1,$98,$87,$39,$cf,$46,$43,$98,$f3,$ce,$62,$5a,$d9
	dc.b	$7f,$38,$4b,$f2,$12,$d3,$00,$02,$86,$ef,$00,$3d,$96,$e3,$88,$61
	dc.b	$86,$92,$70,$38,$94,$49,$f0,$c3,$8b,$15,$12,$2f,$36,$4b,$e7,$8b
	dc.b	$fb,$48,$f5,$65,$fd,$67,$f5,$25,$c0,$7a,$bf,$db,$f4,$4f,$03,$6b
	dc.b	$d5,$3f,$c4,$be,$fd,$a7,$9d,$bb,$f2,$93,$eb,$2f,$af,$b7,$a4,$3b
	dc.b	$f4,$cc,$fe,$d3,$bd,$1d,$d3,$f6,$97,$fd,$c7,$bd,$59,$3f,$59,$3e
	dc.b	$a5,$fc,$b7,$c6,$72,$75,$df,$d6,$13,$7d,$1c,$7c,$11,$3f,$d3,$21
	dc.b	$fb,$6f,$e8,$43,$d7,$df,$c6,$79,$51,$2b,$d5,$de,$e9,$ea,$4f,$c6
	dc.b	$6f,$96,$78,$87,$e5,$8f,$98,$f1,$6f,$e6,$3f,$3e,$fe,$09,$f8,$8d
	dc.b	$f0,$4f,$1f,$54,$49,$f3,$ee,$60,$97,$83,$b9,$25,$e3,$ee,$80,$73
	dc.b	$1f,$8e,$e6,$5f,$d1,$2c,$bc,$9d,$2b,$80,$72,$18,$87,$25,$c8,$89
	dc.b	$0e,$79,$e5,$4a,$e6,$e0,$43,$99,$29,$5c,$82,$b9,$c0,$41,$af,$12
	dc.b	$a8,$92,$49,$54,$b0,$c3,$0a,$7b,$e9,$0a,$23,$e9,$a1,$ff,$63,$fe
	dc.b	$c7,$6f,$ea,$d0,$ad,$38,$a6,$ac,$53,$6e,$52,$fc,$14,$72,$25,$92
	dc.b	$33,$b6,$06,$b0,$37,$88,$82,$4a,$6b,$fa,$42,$a8,$f2,$69,$9e,$c1
	dc.b	$9d,$a3,$8b,$d6,$be,$ef,$19,$bc,$bb,$7b,$b6,$f4,$1f,$0d,$bf,$a7
	dc.b	$bc,$a9,$9e,$f3,$1e,$1d,$de,$8c,$e5,$7c,$f7,$9b,$77,$18,$e7,$d0
	dc.b	$ec,$52,$bc,$ab,$9f,$34,$8f,$79,$8e,$8c,$cd,$6c,$5e,$1f,$9d,$f7
	dc.b	$8f,$a2,$42,$97,$26,$82,$20,$f7,$0f,$3e,$0c,$ef,$43,$74,$67,$af
	dc.b	$3e,$97,$6f,$6f,$70,$bb,$f7,$53,$fa,$1d,$bd,$eb,$0e,$ee,$e6,$7f
	dc.b	$46,$74,$47,$bd,$74,$ea,$e1,$dd,$82,$17,$b9,$ce,$8e,$cf,$a1,$dc
	dc.b	$23,$41,$26,$e2,$51,$99,$82,$82,$e5,$90,$0c,$c5,$1a,$3b,$2a,$25
	dc.b	$0a,$14,$0a,$8a,$c6,$c3,$82,$19,$4c,$ac,$81,$55,$2b,$1a,$cf,$c9
	dc.b	$34,$9e,$59,$31,$9a,$ce,$67,$53,$fa,$45,$3a,$a5,$53,$aa,$55,$ab
	dc.b	$96,$0b,$15,$a6,$d5,$6c,$bd,$df,$f0,$38,$5c,$3e,$23,$15,$8b,$c6
	dc.b	$65,$b3,$3a,$4d,$76,$db,$71,$b9,$dd,$ef,$37,$bc,$2e,$37,$2b,$a1
	dc.b	$d4,$ed,$77,$3b,$bd,$ef,$47,$c3,$e5,$f6,$fc,$7e,$82,$21,$a0,$e8
	dc.b	$78,$42,$24,$13,$8a,$45,$a3,$b2,$64,$3a,$43,$40,$a2,$54,$2a,$b6
	dc.b	$6b,$b5,$fb,$01,$82,$c4,$e8,$3f,$e0,$f0,$b0,$60,$3e,$22,$11,$bf
	dc.b	$61,$91,$49,$94,$ce,$e1,$74,$bb,$ec,$3f,$81,$00,$c8,$72,$2d,$19
	dc.b	$91,$4a,$02,$61,$70,$70,$6e,$27,$1a,$8f,$cc,$20,$40,$a9,$18,$4a
	dc.b	$0d,$0a,$8c,$02,$e0,$31,$28,$ac,$7a,$11,$0d,$88,$44,$62,$f2,$48
	dc.b	$5c,$96,$13,$1d,$06,$03,$64,$11,$b0,$4c,$0e,$08,$07,$87,$c1,$40
	dc.b	$c0,$80,$2c,$1e,$38,$04,$01,$80,$a0,$00,$10,$01,$10,$50,$22,$44
	dc.b	$e3,$20,$14,$44,$00,$07
g2embed_smallfont2_crm_end

	even
g2embed_gun
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$57,$cc,$00,$00,$11,$64,$48,$d4
	dc.b	$7b,$e2,$f7,$f9,$bf,$b7,$f1,$9e,$aa,$b9,$e3,$7e,$aa,$a9,$f6,$bf
	dc.b	$aa,$af,$31,$7f,$55,$49,$ff,$ce,$fb,$76,$8f,$7d,$bb,$47,$be,$dd
	dc.b	$a3,$df,$6e,$db,$fc,$eb,$3e,$dd,$bd,$f3,$b0,$7d,$bb,$c7,$ed,$2b
	dc.b	$60,$7d,$bb,$57,$8d,$c1,$f6,$ef,$1e,$a2,$c7,$db,$bc,$7f,$5c,$b9
	dc.b	$7e,$f5,$cb,$9f,$e3,$ed,$d8,$bf,$4e,$9b,$ed,$df,$5e,$3f,$7c,$fb
	dc.b	$76,$cf,$c1,$c2,$d1,$f6,$ed,$e6,$9f,$6e,$d5,$ca,$be,$dd,$dd,$c9
	dc.b	$be,$dd,$cb,$ed,$7d,$bb,$c7,$55,$2b,$47,$db,$b5,$79,$57,$db,$bc
	dc.b	$7a,$6f,$b7,$68,$f7,$db,$bd,$ff,$66,$47,$8e,$ae,$0e,$6e,$8f,$8d
	dc.b	$ec,$e2,$1b,$d9,$4a,$37,$b1,$a0,$6f,$61,$58,$e6,$fe,$e1,$9b,$ec
	dc.b	$45,$ee,$e8,$2f,$73,$71,$9b,$be,$85,$ed,$7a,$20,$ff,$28,$1d,$4a
	dc.b	$11,$86,$80,$15,$7e,$7b,$62,$18,$bd,$fc,$a7,$80,$c2,$0f,$f2,$b6
	dc.b	$03,$08,$b2,$4a,$4f,$f9,$4f,$63,$b3,$23,$0a,$2f,$ca,$79,$15,$f8
	dc.b	$9e,$51,$7e,$56,$db,$10,$48,$a2,$fc,$a5,$b6,$0a,$ab,$45,$f9,$52
	dc.b	$7d,$bb,$91,$86,$8b,$b6,$d5,$36,$27,$28,$36,$c2,$ea,$a9,$48,$17
	dc.b	$b9,$70,$fb,$de,$e9,$6c,$93,$92,$9a,$68,$7c,$a6,$69,$7e,$7e,$68
	dc.b	$79,$eb,$6b,$6a,$e7,$2e,$61,$68,$12,$c8,$68,$a7,$3c,$b2,$38,$d1
	dc.b	$1f,$98,$fe,$0f,$1c,$24,$e4,$96,$d6,$d5,$cd,$bb,$d7,$8f,$48,$0f
	dc.b	$01,$71,$b5,$33,$58,$fa,$22,$28,$6a,$ab,$6b,$68,$2f,$3d,$d6,$7a
	dc.b	$c6,$b1,$26,$d0,$f1,$8f,$cd,$39,$e0,$8c,$61,$6d,$7c,$21,$f2,$81
	dc.b	$8c,$0d,$39,$a9,$92,$ac,$9a,$64,$42,$a2,$d3,$4d,$2d,$b5,$b5,$b4
	dc.b	$4f,$80,$3e,$78,$1c,$1e,$51,$11,$e9,$8c,$dc,$13,$ef,$9a,$53,$cb
	dc.b	$97,$c1,$0b,$f5,$39,$47,$4d,$e4,$2f,$f3,$e6,$9c,$a2,$14,$f4,$74
	dc.b	$82,$61,$59,$5b,$7d,$2e,$02,$e7,$8c,$ec,$17,$64,$48,$bd,$b3,$f0
	dc.b	$89,$16,$74,$0b,$45,$73,$31,$27,$ca,$2b,$09,$1d,$a2,$d4,$3c,$eb
	dc.b	$6b,$29,$eb,$96,$2d,$13,$59,$aa,$3e,$dd,$bd,$d2,$46,$a9,$75,$7c
	dc.b	$06,$c0,$d1,$dd,$43,$9e,$09,$ca,$d8,$14,$0c,$b6,$af,$ad,$a2,$dc
	dc.b	$b1,$63,$35,$54,$50,$1b,$47,$db,$bd,$82,$45,$64,$c1,$62,$eb,$f1
	dc.b	$c1,$6c,$51,$21,$4b,$47,$db,$b5,$82,$52,$c7,$9a,$ee,$f8,$4d,$be
	dc.b	$dd,$ad,$e3,$00,$47,$45,$b2,$e5,$8d,$d5,$89,$f6,$ef,$ac,$34,$21
	dc.b	$f6,$ed,$5c,$ed,$7c,$04,$13,$11,$3e,$dd,$93,$da,$6c,$fb,$76,$af
	dc.b	$01,$0b,$7d,$bb,$57,$fe,$3d,$c2,$8c,$5f,$45,$fb,$46,$90,$32,$78
	dc.b	$32,$da,$3e,$dd,$e3,$fc,$09,$f6,$ec,$9f,$e2,$1b,$ed,$df,$df,$f4
	dc.b	$cf,$b7,$68,$f7,$db,$b4,$7b,$ed,$df,$7f,$fd,$b5,$10,$fb,$76,$3f
	dc.b	$ef,$3d,$6f,$7c,$17,$fd,$d8,$6f,$1e,$6f,$ce,$5c,$92,$ee,$f9,$bf
	dc.b	$29,$03,$0c,$d9,$78,$fe,$6f,$c1,$78,$c2,$95,$55,$57,$9a,$86,$d5
	dc.b	$6f,$f5,$1c,$7c,$7a,$80,$c3,$f7,$b0,$ec,$f8,$fd,$80,$e4,$fa,$86
	dc.b	$fe,$e5,$e0,$4f,$d8,$23,$ab,$d9,$e4,$6b,$c1,$5f,$b1,$64,$7a,$bf
	dc.b	$ff,$d9,$88,$a5,$44,$3d,$b7,$bc,$6f,$62,$c7,$8d,$62,$ff,$3e,$b9
	dc.b	$42,$6a,$22,$a7,$13,$72,$ff,$3e,$ad,$61,$d8,$d1,$75,$34,$cb,$fb
	dc.b	$c6,$fe,$ec,$c2,$b3,$9a,$3a,$d3,$2d,$2b,$3b,$3a,$c7,$25,$41,$b7
	dc.b	$1d,$4c,$a5,$4a,$e5,$eb,$d7,$81,$3f,$cf,$e0,$df,$de,$b9,$10,$af
	dc.b	$9e,$8e,$7d,$72,$ec,$4d,$3a,$43,$bd,$6b,$7f,$b5,$1a,$86,$3a,$f6
	dc.b	$5a,$00,$a9,$5e,$98,$54,$ad,$3e,$15,$75,$35,$38,$e3,$8a,$1f,$b9
	dc.b	$76,$a1,$46,$a6,$5e,$bd,$33,$a9,$52,$b9,$72,$fd,$fb,$c3,$ef,$e9
	dc.b	$c5,$43,$0e,$5e,$a0,$fe,$15,$f3,$a5,$94,$ae,$52,$bd,$7a,$65,$3d
	dc.b	$89,$f7,$98,$56,$df,$db,$52,$8a,$d8,$37,$e0,$c3,$a8,$5f,$a9,$c0
	dc.b	$7d,$a6,$57,$2b,$5c,$a5,$78,$13,$fd,$3a,$12,$9a,$f5,$fa,$57,$b4
	dc.b	$0e,$99,$78,$e1,$d6,$9f,$df,$b4,$f2,$b5,$01,$9b,$30,$0c,$ed,$9f
	dc.b	$4f,$60,$fb,$d5,$a8,$bf,$87,$87,$93,$36,$ac,$cd,$83,$83,$5f,$9c
	dc.b	$2d,$72,$fd,$eb,$96,$ff,$85,$6c,$33,$01,$32,$c2,$d6,$9b,$2c,$3d
	dc.b	$c9,$b5,$e1,$6b,$f7,$a9,$5c,$80,$f9,$6a,$43,$89,$a9,$34,$5a,$6b
	dc.b	$b1,$6e,$7e,$77,$7e,$65,$7e,$e5,$d8,$9d,$7e,$cb,$da,$46,$6f,$b9
	dc.b	$82,$b0,$e0,$ad,$d8,$fd,$97,$af,$d3,$81,$be,$7f,$83,$df,$9b,$5e
	dc.b	$96,$35,$6b,$97,$2d,$3e,$7d,$c5,$33,$4c,$a9,$5b,$9a,$fb,$ef,$33
	dc.b	$e6,$01,$b1,$4d,$ef,$d6,$12,$a1,$85,$af,$5a,$7f,$45,$52,$77,$ea
	dc.b	$7d,$66,$58,$36,$37,$df,$0e,$af,$9d,$38,$4e,$85,$ae,$88,$70,$23
	dc.b	$2b,$fb,$e3,$da,$a6,$88,$32,$7e,$70,$f5,$a7,$4f,$ae,$41,$a2,$0e
	dc.b	$5f,$e7,$09,$56,$ba,$25,$74,$4e,$58,$38,$f5,$e5,$4a,$fd,$b2,$86
	dc.b	$0e,$e8,$98,$b2,$87,$b7,$a3,$47,$8f,$28,$0f,$1e,$13,$1d,$de,$eb
	dc.b	$0f,$1d,$99,$1e,$3a,$b8,$39,$bc,$c1,$49,$a3,$e3,$bb,$d1,$fb,$fe
	dc.b	$87,$10,$c9,$e5,$28,$df,$fc,$68,$1c,$dc,$2b,$1c,$df,$dc,$2f,$7b
	dc.b	$11,$9b,$dd,$74,$19,$7f,$0d,$75,$59,$94,$dc,$4e,$f8,$5d,$cd,$c6
	dc.b	$4f,$a1,$57,$3a,$3e,$87,$ad,$7a,$20,$ff,$29,$e4,$00,$fd,$fc,$f6
	dc.b	$c4,$31,$7b,$f9,$4f,$01,$84,$1f,$e5,$6c,$24,$54,$c9,$28,$bf,$29
	dc.b	$ec,$76,$64,$61,$56,$67,$18,$50,$ce,$30,$b8,$ff,$29,$e4,$71,$69
	dc.b	$14,$f2,$c8,$78,$c6,$64,$f2,$ab,$f2,$b6,$d8,$82,$45,$17,$e5,$2d
	dc.b	$b0,$45,$55,$69,$3f,$e5,$49,$14,$5a,$e7,$84,$89,$26,$1b,$af,$6d
	dc.b	$aa,$7c,$0e,$79,$e5,$9b,$6d,$79,$f2,$40,$d8,$86,$1a,$38,$53,$fa
	dc.b	$58,$8b,$fe,$6c,$97,$55,$fa,$0f,$91,$ff,$09,$81,$e6,$9c,$31,$ad
	dc.b	$bf,$9a,$c7,$26,$49,$68,$c7,$a4,$6d,$08,$b9,$72,$88,$5b,$ae,$e7
	dc.b	$81,$94,$51,$23,$47,$ec,$4f,$0c,$1a,$50,$d2,$b8,$2c,$d6,$4c,$e0
	dc.b	$9d,$36,$ef,$5f,$4b,$06,$b9,$1e,$02,$e3,$68,$6d,$38,$fa,$24,$92
	dc.b	$91,$c6,$50,$59,$b6,$e6,$db,$9b,$37,$0c,$9b,$20,$a3,$1c,$7c,$f7
	dc.b	$5f,$45,$63,$eb,$f5,$c9,$8f,$4c,$49,$a5,$c8,$54,$69,$1b,$49,$3b
	dc.b	$b8,$4a,$63,$0d,$97,$08,$7c,$a0,$78,$ca,$29,$1e,$b8,$f4,$73,$73
	dc.b	$11,$0a,$8b,$32,$49,$44,$9f,$0c,$fa,$6e,$df,$cf,$b9,$1c,$f0,$c6
	dc.b	$ee,$00,$f9,$e0,$61,$71,$85,$72,$d2,$23,$d3,$1a,$78,$27,$5c,$9a
	dc.b	$51,$73,$c0,$4a,$fa,$38,$6c,$db,$0e,$51,$5c,$0c,$ed,$28,$1f,$8d
	dc.b	$62,$d4,$fc,$47,$a2,$63,$5b,$a3,$6d,$77,$53,$82,$0e,$b3,$86,$dc
	dc.b	$f0,$3b,$82,$e3,$d5,$a2,$e9,$b3,$4c,$fa,$f4,$f0,$d9,$07,$22,$c4
	dc.b	$78,$29,$07,$0e,$19,$ca,$33,$74,$cc,$25,$08,$24,$9d,$31,$9b,$39
	dc.b	$9a,$e9,$27,$07,$9c,$93,$e1,$2b,$b6,$67,$29,$3a,$0e,$19,$72,$2c
	dc.b	$03,$4f,$4a,$96,$4d,$f0,$30,$d4,$69,$93,$80,$73,$c0,$2d,$14,$13
	dc.b	$e0,$9c,$a9,$5c,$a9,$50,$67,$75,$db,$86,$73,$ea,$70,$90,$5e,$02
	dc.b	$c5,$c9,$30,$a1,$5c,$a3,$03,$1c,$0e,$09,$ab,$51,$1c,$ef,$d2,$fd
	dc.b	$bd,$b9,$56,$73,$68,$9a,$47,$08,$a3,$82,$1e,$14,$38,$4c,$5a,$67
	dc.b	$49,$4c,$12,$33,$bd,$26,$f8,$84,$3c,$26,$22,$83,$e7,$02,$b4,$19
	dc.b	$c1,$09,$d3,$c4,$78,$33,$7a,$4d,$be,$c2,$88,$14,$98,$e2,$8a,$28
	dc.b	$a8,$87,$01,$76,$d9,$40,$11,$9e,$07,$76,$65,$ff,$25,$fc,$39,$de
	dc.b	$12,$73,$8b,$a6,$ac,$77,$ba,$67,$0c,$d8,$f3,$46,$8b,$f8,$b0,$f8
	dc.b	$08,$2f,$b9,$5e,$01,$4b,$86,$cb,$05,$fc,$74,$1e,$1e,$17,$c4,$13
	dc.b	$9d,$91,$75,$60,$13,$d3,$65,$f2,$fe,$19,$b0,$ef,$05,$6e,$f8,$03
	dc.b	$c0,$80,$1a,$58,$a5,$45,$f6,$e9,$2b,$cb,$95,$0c,$ab,$9c,$ac,$94
	dc.b	$57,$f2,$f8,$65,$c6,$b2,$6a,$66,$8a,$ec,$e7,$4b,$83,$c5,$63,$b8
	dc.b	$2f,$c1,$07,$6c,$eb,$55,$85,$ab,$36,$df,$2d,$c1,$69,$82,$85,$0a
	dc.b	$4f,$e1,$5a,$b9,$50,$56,$97,$66,$cb,$d8,$2e,$9b,$7c,$96,$fd,$3c
	dc.b	$2f,$84,$b8,$01,$d0,$ea,$42,$e5,$4b,$fb,$d1,$f0,$40,$24,$f8,$2e
	dc.b	$fd,$60,$3a,$1d,$c4,$f7,$d3,$e4,$2f,$80,$f9,$67,$81,$74,$78,$04
	dc.b	$67,$e0,$e5,$35,$8b,$f8,$d6,$27,$13,$9c,$6e,$f4,$00,$69,$58,$08
	dc.b	$1f,$d3,$7d,$ca,$bb,$f0,$f3,$94,$56,$ca,$93,$40,$5d,$6d,$3a,$3e
	dc.b	$35,$dc,$9c,$72,$83,$7c,$20,$13,$5d,$ac,$3c,$55,$85,$b8,$ff,$90
	dc.b	$5a,$36,$21,$ce,$cc,$d3,$4d,$7c,$27,$45,$c9,$30,$bd,$13,$6c,$4d
	dc.b	$78,$47,$87,$c0,$9f,$c6,$2d,$95,$26,$dc,$47,$c0,$7a,$7c,$db,$81
	dc.b	$df,$e9,$89,$58,$70,$73,$6c,$4f,$d6,$1c,$5c,$09,$ff,$be,$3c,$36
	dc.b	$b1,$49,$37,$e9,$8e,$09,$a6,$9a,$46,$3b,$38,$3a,$fd,$38,$4b,$e1
	dc.b	$12,$a6,$43,$bb,$58,$93,$9a,$25,$2c,$cf,$09,$4d,$8b,$0b,$db,$c4
	dc.b	$c3,$33,$c1,$ef,$e6,$a6,$e1,$8f,$fa,$6c,$78,$63,$cd,$c1,$ed,$16
	dc.b	$a6,$e1,$77,$85,$69,$ae,$98,$ff,$86,$5d,$8b,$5f,$7c,$e0,$f6,$af
	dc.b	$f3,$f0,$e6,$6b,$1a,$38,$cd,$f1,$7a,$30,$56,$a1,$aa,$f3,$51,$30
	dc.b	$1f,$7a,$72,$15,$43,$5b,$bc,$45,$bc,$3e,$8c,$ef,$ac,$11,$55,$54
	dc.b	$6a,$a3,$09,$63,$15,$4e,$11,$b0,$7b,$8c,$1c,$8d,$2c,$d5,$51,$83
	dc.b	$0d,$cf,$e7,$a3,$f8,$b1,$6a,$c5,$46,$db,$03,$8b,$33,$10,$c6,$7a
	dc.b	$2a,$e7,$51,$8d,$7a,$d3,$8b,$8a,$80,$27,$4d,$88,$53,$15,$5a,$bc
	dc.b	$fc,$3a,$25,$88,$91,$00,$a1,$bd,$cd,$35,$17,$74,$0c,$37,$dc,$bf
	dc.b	$07,$13,$a3,$e7,$c8,$41,$f3,$12,$00,$e4,$6a,$71,$2d,$28,$ed,$ab
	dc.b	$56,$d8,$0e,$40,$8b,$68,$96,$46,$1a,$9e,$1b,$88,$82,$96,$f4,$57
	dc.b	$5b,$70,$72,$8c,$1a,$df,$82,$19,$42,$c8,$cb,$6c,$02,$d6,$19,$3a
	dc.b	$db,$b6,$18,$75,$d2,$22,$52,$2d,$66,$14,$32,$db,$0d,$88,$56,$c4
	dc.b	$d2,$cb,$68,$ec,$8d,$a2,$61,$a4,$20,$4b,$ac,$31,$fa,$3b,$34,$84
	dc.b	$b5,$cc,$26,$5a,$02,$b2,$28,$44,$b5,$6a,$de,$c2,$a3,$2b,$6d,$ab
	dc.b	$56,$b0,$33,$03,$1f,$e2,$8b,$b0,$91,$52,$85,$3e,$2d,$bc,$74,$30
	dc.b	$ae,$44,$e8,$c8,$45,$d6,$80,$81,$ba,$dd,$dd,$a7,$34,$44,$8f,$1d
	dc.b	$b5,$45,$30,$d6,$0c,$18,$0c,$37,$4e,$28,$3b,$c9,$96,$ba,$ed,$1d
	dc.b	$21,$46,$5d,$ba,$b6,$b7,$db,$54,$03,$7b,$9b,$61,$0c,$2b,$42,$dd
	dc.b	$b0,$b1,$cd,$7a,$c2,$99,$61,$60,$cb,$6b,$76,$9d,$b5,$f6,$ad,$76
	dc.b	$53,$cd,$02,$d8,$d4,$ef,$c5,$67,$ca,$54,$cb,$45,$45,$db,$b7,$f5
	dc.b	$5c,$a5,$4c,$ac,$b1,$6d,$6d,$d0,$98,$9e,$ae,$a6,$59,$e2,$8d,$e1
	dc.b	$ee,$da,$bc,$32,$c9,$22,$43,$c9,$e8,$6d,$26,$b7,$ad,$a8,$53,$28
	dc.b	$b2,$30,$de,$1c,$63,$ba,$85,$9f,$61,$f9,$4a,$b6,$5e,$65,$91,$bc
	dc.b	$9e,$a0,$6d,$56,$35,$9b,$2d,$3a,$85,$5d,$bb,$76,$02,$ab,$30,$27
	dc.b	$b2,$d1,$a8,$d6,$1b,$bf,$7c,$c4,$86,$07,$73,$d2,$8b,$30,$ed,$4f
	dc.b	$f4,$30,$97,$5d,$64,$5a,$76,$d2,$80,$da,$5d,$66,$43,$d3,$ad,$98
	dc.b	$d0,$76,$05,$6e,$10,$61,$86,$ea,$c5,$0c,$0e,$ea,$86,$c2,$2c,$3c
	dc.b	$27,$08,$ec,$db,$09,$bb,$31,$61,$d8,$0d,$a4,$38,$ce,$da,$58,$c3
	dc.b	$1a,$67,$dc,$57,$1a,$ba,$c1,$4e,$23,$03,$b6,$f0,$67,$1f,$69,$90
	dc.b	$61,$ae,$ad,$85,$83,$5e,$89,$26,$59,$59,$76,$e8,$c3,$2d,$71,$0b
	dc.b	$61,$85,$d9,$1a,$cc,$38,$dc,$65,$b7,$4f,$f9,$7d,$11,$6b,$21,$b7
	dc.b	$c0,$6b,$28,$f1,$56,$e9,$e9,$88,$c4,$77,$6b,$0e,$b6,$c1,$26,$45
	dc.b	$1b,$69,$c5,$1d,$b7,$6b,$02,$bd,$7c,$2c,$32,$74,$b2,$30,$d7,$76
	dc.b	$b4,$b3,$6f,$22,$f2,$e3,$ad,$ac,$61,$90,$dd,$5b,$0e,$d1,$f2,$51
	dc.b	$89,$97,$58,$e8,$d6,$6a,$d5,$ab,$64,$62,$a1,$19,$a6,$c8,$c1,$78
	dc.b	$e2,$98,$03,$1b,$16,$19,$b0,$1a,$ed,$96,$78,$ad,$76,$c5,$63,$0d
	dc.b	$1c,$c1,$9d,$0b,$3c,$56,$e3,$09,$95,$96,$51,$e9,$d6,$c2,$b5,$86
	dc.b	$18,$24,$47,$1c,$76,$d8,$46,$a9,$85,$dd,$5b,$37,$6c,$d9,$b2,$cf
	dc.b	$4e,$b6,$30,$d0,$b5,$33,$1d,$14,$51,$d0,$c3,$0a,$d5,$a3,$76,$12
	dc.b	$d0,$20,$d6,$6c,$8d,$66,$9e,$9e,$2c,$3b,$5d,$b8,$c1,$ed,$61,$db
	dc.b	$d1,$c7,$c5,$a3,$73,$d1,$b0,$3b,$50,$d7,$6e,$8c,$55,$9a,$b6,$7a
	dc.b	$64,$54,$74,$78,$b4,$fd,$3f,$15,$1e,$2b,$5f,$bf,$de,$11,$96,$ad
	dc.b	$1a,$2c,$58,$a9,$1a,$0f,$56,$a6,$73,$f3,$d9,$47,$e7,$c5,$71,$8c
	dc.b	$f9,$61,$fc,$58,$71,$86,$87,$67,$8a,$c2,$1f,$0d,$b1,$f2,$ad,$55
	dc.b	$79,$d1,$d8,$09,$1d,$cc,$56,$78,$b1,$59,$d2,$58,$c0,$1d,$66,$0d
	dc.b	$55,$5a,$b6,$62,$a3,$9c,$59,$73,$54,$58,$a8,$02,$80,$78,$d0,$61
	dc.b	$96,$6c,$8c,$8f,$ce,$cf,$a3,$e7,$e7,$46,$7f,$c4,$6c,$2a,$dc,$40
	dc.b	$6b,$35,$4e,$f8,$7d,$58,$7d,$1e,$34,$60,$af,$56,$ff,$87,$7c,$f1
	dc.b	$23,$68,$4f,$ac,$7b,$ab,$e0,$e3,$73,$fd,$7d,$7a,$a2,$d4,$0f,$a8
	dc.b	$1f,$d4,$16,$61,$dc,$3f,$5a,$65,$3c,$e6,$22,$90,$6f,$8d,$d0,$75
	dc.b	$03,$95,$68,$8c,$f7,$ac,$99,$c0,$d1,$3f,$04,$a2,$26,$18,$e6,$8e
	dc.b	$ee,$80,$0d,$22,$e1,$35,$2c,$80,$45,$0d,$12,$a5,$f9,$2c,$3f,$8b
	dc.b	$04,$fa,$e4,$5d,$d2,$82,$e4,$3a,$a2,$86,$9b,$2b,$dd,$81,$66,$26
	dc.b	$28,$23,$29,$8e,$01,$ad,$53,$3a,$ca,$19,$a1,$dd,$c5,$db,$16,$c8
	dc.b	$6e,$4c,$40,$82,$e4,$a9,$9c,$91,$09,$8b,$04,$18,$99,$21,$a2,$ec
	dc.b	$32,$19,$26,$b1,$45,$44,$c8,$52,$05,$f8,$e4,$14,$59,$4c,$37,$45
	dc.b	$07,$80,$bc,$68,$71,$dd,$05,$a3,$00,$db,$cd,$d1,$cd,$cc,$97,$c1
	dc.b	$76,$e8,$e3,$8e,$87,$85,$d6,$5a,$80,$db,$cc,$a1,$8b,$3b,$c8,$b1
	dc.b	$4a,$67,$ac,$77,$75,$8d,$cb,$9f,$2f,$da,$02,$c9,$bc,$4b,$4c,$1c
	dc.b	$96,$a5,$55,$43,$d2,$bc,$91,$65,$6e,$8a,$ea,$eb,$b1,$9d,$e4,$5d
	dc.b	$9a,$78,$e4,$ec,$84,$8f,$d1,$79,$05,$e8,$25,$ff,$27,$1d,$e8,$ef
	dc.b	$20,$ff,$32,$16,$94,$a8,$87,$f1,$a7,$d1,$53,$5f,$21,$eb,$db,$7c
	dc.b	$3f,$2e,$2b,$58,$4c,$cb,$0c,$ba,$ea,$80,$56,$62,$89,$80,$fc,$14
	dc.b	$7d,$74,$a1,$06,$53,$df,$28,$8b,$b6,$4c,$dc,$a4,$8c,$7c,$b6,$07
	dc.b	$70,$e5,$8a,$3d,$f2,$76,$38,$b0,$c3,$25,$0d,$dc,$db,$42,$49,$47
	dc.b	$ac,$09,$43,$4f,$58,$88,$aa,$62,$29,$10,$fb,$2a,$44,$57,$93,$14
	dc.b	$d5,$c8,$07,$e8,$e3,$97,$f7,$ec,$30,$30,$df,$6a,$f7,$cc,$4f,$2a
	dc.b	$33,$21,$95,$9e,$9c,$fb,$5a,$bf,$e2,$9d,$ff,$93,$e6,$3b,$d9,$c4
	dc.b	$ec,$80,$d1,$94,$e4,$2a,$3f,$86,$91,$02,$9a,$11,$e4,$9a,$2b,$32
	dc.b	$6b,$3d,$b1,$32,$98,$2b,$fe,$de,$fd,$52,$7f,$f6,$47,$98,$95,$2a
	dc.b	$5f,$3e,$57,$53,$29,$92,$d5,$98,$c8,$67,$0a,$46,$79,$06,$42,$59
	dc.b	$15,$24,$55,$c4,$94,$d9,$a9,$5e,$f9,$7a,$63,$59,$7f,$d5,$65,$18
	dc.b	$05,$e9,$ba,$8f,$2d,$ac,$07,$9f,$24,$2d,$c1,$07,$c8,$00,$64,$6c
	dc.b	$10,$51,$40,$f9,$e8,$e9,$8d,$ab,$90,$21,$4c,$8b,$98,$a8,$0d,$09
	dc.b	$52,$44,$bf,$9f,$26,$35,$58,$12,$ee,$b4,$31,$a5,$c1,$06,$22,$25
	dc.b	$4a,$f5,$ba,$a8,$63,$1d,$c8,$33,$45,$4c,$ee,$1e,$17,$80,$35,$66
	dc.b	$a2,$8a,$41,$be,$86,$48,$c8,$f4,$e0,$95,$b6,$bc,$bc,$2e,$56,$13
	dc.b	$70,$91,$9f,$b2,$3f,$32,$93,$d3,$a6,$34,$4a,$8d,$f7,$25,$43,$38
	dc.b	$4c,$b0,$d7,$7a,$e4,$4b,$ce,$d1,$1d,$54,$79,$eb,$a9,$10,$f9,$8c
	dc.b	$8a,$85,$07,$1c,$71,$21,$34,$7e,$41,$d1,$dc,$66,$fa,$9a,$74,$6e
	dc.b	$6a,$09,$68,$02,$87,$8f,$9a,$e8,$b6,$34,$4f,$4e,$74,$49,$f2,$44
	dc.b	$5b,$82,$17,$60,$4a,$e1,$67,$47,$1a,$d2,$df,$87,$57,$ab,$b2,$04
	dc.b	$17,$be,$6a,$59,$d7,$58,$ea,$52,$66,$63,$32,$52,$2c,$b9,$d0,$91
	dc.b	$80,$94,$50,$20,$fb,$fe,$75,$8f,$63,$9b,$dd,$38,$cd,$30,$6d,$62
	dc.b	$1a,$27,$b4,$25,$04,$ab,$98,$79,$eb,$af,$33,$2c,$88,$87,$1c,$d3
	dc.b	$3c,$94,$c9,$10,$b3,$9d,$40,$4b,$e4,$07,$ce,$fc,$39,$9d,$21,$40
	dc.b	$38,$e9,$02,$db,$db,$ab,$6e,$44,$57,$20,$cc,$fc,$f3,$d1,$5d,$40
	dc.b	$4f,$2b,$13,$73,$45,$d1,$c2,$c1,$24,$8c,$29,$7e,$1c,$77,$93,$ca
	dc.b	$f8,$0b,$dd,$dd,$96,$73,$48,$a4,$90,$32,$3f,$16,$f4,$5d,$83,$00
	dc.b	$ef,$b7,$6c,$a5,$81,$b5,$2f,$f8,$e2,$47,$42,$18,$f4,$a6,$3b,$70
	dc.b	$40,$bd,$29,$e8,$25,$59,$c0,$f8,$0b,$80,$54,$28,$02,$95,$e8,$32
	dc.b	$04,$4b,$3b,$67,$84,$b4,$51,$36,$f0,$87,$09,$66,$0a,$15,$86,$39
	dc.b	$1f,$85,$f1,$e4,$30,$5e,$bd,$7a,$89,$af,$1c,$4d,$aa,$78,$07,$e3
	dc.b	$38,$25,$26,$7c,$95,$2d,$e6,$c0,$c0,$50,$e1,$23,$3e,$9a,$64,$a9
	dc.b	$51,$39,$91,$aa,$b9,$05,$6b,$32,$69,$a9,$6a,$4a,$f0,$9c,$9f,$10
	dc.b	$35,$25,$4a,$94,$14,$a9,$66,$cd,$4a,$96,$68,$d5,$3c,$d6,$40,$52
	dc.b	$c4,$c9,$b3,$66,$fd,$23,$5e,$3d,$26,$c8,$57,$de,$66,$c8,$5c,$10
	dc.b	$41,$c7,$fa,$dc,$ac,$c8,$ff,$aa,$ed,$8b,$ff,$f3,$8c,$d4,$67,$e4
	dc.b	$b1,$91,$e9,$f8,$6e,$a4,$4d,$5e,$d4,$66,$4e,$4d,$80,$42,$5a,$94
	dc.b	$8b,$e4,$de,$eb,$f5,$78,$68,$d9,$18,$4d,$08,$c9,$24,$d3,$75,$3d
	dc.b	$76,$52,$d5,$01,$cf,$eb,$22,$68,$a9,$ad,$42,$14,$b3,$b1,$9b,$05
	dc.b	$38,$cd,$ae,$1a,$57,$8d,$61,$05,$15,$2c,$01,$e3,$af,$73,$ec,$ee
	dc.b	$1c,$a7,$09,$ca,$56,$46,$be,$68,$f2,$13,$78,$fe,$df,$e9,$83,$16
	dc.b	$63,$3f,$11,$2c,$e9,$67,$49,$34,$31,$a8,$18,$87,$06,$f4,$89,$bb
	dc.b	$38,$4d,$70,$e4,$4a,$7d,$34,$27,$e9,$90,$35,$47,$d7,$4a,$90,$d6
	dc.b	$fc,$45,$a0,$c4,$b1,$0a,$c6,$14,$2a,$30,$01,$70,$31,$39,$d3,$9b
	dc.b	$eb,$2c,$82,$a9,$8b,$08,$a6,$92,$b4,$9a,$6d,$6c,$78,$c5,$a0,$51
	dc.b	$58,$4a,$12,$dd,$04,$69,$91,$60,$82,$02,$62,$ed,$2a,$9d,$54,$09
	dc.b	$50,$c5,$61,$56,$b1,$94,$72,$ec,$09,$bb,$1a,$21,$43,$00,$90,$d2
	dc.b	$94,$2d,$74,$98,$b4,$eb,$b1,$24,$92,$81,$2c,$60,$ab,$39,$10,$87
	dc.b	$16,$dd,$9f,$a4,$05,$c3,$95,$85,$90,$09,$8b,$bb,$28,$f3,$b7,$72
	dc.b	$e2,$60,$cb,$39,$c9,$17,$44,$c0,$58,$11,$53,$5a,$67,$90,$83,$7b
	dc.b	$ae,$b4,$b3,$0c,$6f,$18,$ae,$1d,$c2,$e8,$ad,$e4,$0b,$d1,$40,$46
	dc.b	$5d,$06,$43,$1a,$c9,$1b,$52,$f4,$22,$02,$27,$7d,$95,$10,$7f,$82
	dc.b	$85,$15,$21,$1e,$c4,$f5,$49,$33,$7a,$4e,$fd,$49,$8a,$f6,$16,$fe
	dc.b	$0c,$a6,$25,$c6,$ed,$ee,$2a,$2b,$1b,$7b,$92,$13,$0a,$23,$ec,$a0
	dc.b	$37,$5e,$8f,$51,$64,$01,$fa,$11,$e3,$b1,$3d,$5a,$a9,$20,$8a,$c4
	dc.b	$bf,$08,$94,$9d,$8a,$58,$3f,$fa,$02,$3c,$ce,$d3,$75,$db,$da,$91
	dc.b	$e2,$40,$6e,$dc,$1b,$32,$b5,$d1,$7a,$97,$49,$d9,$42,$64,$77,$d6
	dc.b	$48,$01,$0c,$85,$a7,$e0,$04,$2c,$c4,$49,$1a,$94,$eb,$d4,$1c,$0a
	dc.b	$37,$61,$fa,$21,$b7,$0d,$ee,$d1,$63,$23,$ea,$b1,$12,$6c,$84,$49
	dc.b	$11,$21,$60,$de,$8e,$11,$5c,$81,$ff,$06,$e2,$d4,$58,$87,$f2,$d2
	dc.b	$96,$24,$3c,$3e,$93,$2c,$47,$91,$5f,$d4,$fb,$0b,$5e,$e8,$08,$4a
	dc.b	$53,$90,$58,$db,$a0,$64,$56,$10,$4f,$65,$ec,$6c,$d2,$94,$16,$48
	dc.b	$4b,$a9,$f6,$0c,$de,$54,$22,$c2,$e4,$77,$52,$19,$32,$52,$86,$1d
	dc.b	$5e,$ce,$da,$78,$a2,$ff,$94,$b5,$16,$0e,$ea,$19,$b8,$f8,$48,$c5
	dc.b	$64,$75,$bd,$4d,$99,$8d,$ba,$93,$e0,$d2,$6e,$b1,$b1,$d9,$f6,$16
	dc.b	$67,$52,$4b,$00,$68,$d1,$b6,$01,$9d,$ef,$51,$e1,$a9,$75,$4c,$38
	dc.b	$60,$95,$cc,$4f,$9a,$ea,$4b,$b0,$f6,$06,$84,$d8,$56,$b2,$1e,$6e
	dc.b	$a3,$c3,$6c,$42,$cd,$0e,$fd,$14,$dc,$b6,$a1,$4d,$b4,$d6,$59,$f6
	dc.b	$a7,$1e,$12,$f4,$80,$56,$af,$e2,$75,$65,$cc,$c4,$3b,$6d,$0b,$1c
	dc.b	$ec,$c1,$4a,$75,$6e,$eb,$42,$c6,$1a,$21,$50,$60,$16,$25,$5a,$93
	dc.b	$21,$66,$ed,$42,$43,$86,$7e,$9d,$5c,$16,$a1,$70,$58,$b1,$fb,$56
	dc.b	$a8,$56,$74,$b1,$9d,$0d,$25,$0b,$0f,$5c,$b0,$a2,$8a,$b1,$b5,$de
	dc.b	$cb,$27,$0e,$1f,$30,$a1,$b3,$c5,$2c,$b0,$71,$85,$14,$37,$a2,$ac
	dc.b	$65,$8d,$2b,$3a,$59,$37,$13,$4d,$6b,$29,$b8,$a2,$12,$75,$61,$62
	dc.b	$49,$1b,$77,$45,$34,$17,$07,$ea,$22,$c7,$49,$75,$25,$81,$0f,$a4
	dc.b	$41,$75,$cb,$03,$fc,$24,$6d,$37,$fc,$ea,$c0,$15,$92,$a5,$0c,$e4
	dc.b	$a2,$0f,$c5,$62,$1e,$a4,$26,$ee,$ba,$a4,$93,$a5,$dd,$14,$c3,$fd
	dc.b	$03,$95,$96,$57,$23,$3a,$44,$40,$ff,$95,$12,$c6,$58,$92,$63,$84
	dc.b	$58,$4a,$71,$5e,$09,$22,$26,$7f,$99,$f2,$2f,$c2,$49,$ea,$42,$15
	dc.b	$23,$16,$0b,$79,$03,$b4,$ce,$76,$8b,$ae,$eb,$ab,$8a,$a5,$9d,$2b
	dc.b	$b0,$8e,$13,$fc,$c1,$65,$33,$4d,$83,$2e,$b1,$37,$70,$de,$b5,$e0
	dc.b	$11,$29,$1e,$dd,$ae,$ea,$c6,$4f,$0c,$ee,$a6,$9a,$53,$6d,$a4,$03
	dc.b	$a2,$86,$ea,$5d,$0c,$b2,$eb,$a9,$a8,$2f,$4b,$58,$6b,$d4,$06,$27
	dc.b	$a8,$ce,$eb,$ae,$67,$4f,$d3,$58,$15,$0b,$be,$3e,$19,$f4,$27,$f3
	dc.b	$ab,$01,$7a,$52,$71,$1e,$cb,$72,$7d,$2c,$0b,$78,$3a,$1d,$d2,$99
	dc.b	$7d,$93,$e2,$b0,$f1,$c3,$c5,$9c,$7d,$c7,$e2,$bf,$e5,$56,$04,$f1
	dc.b	$5c,$3a,$7f,$ba,$8f,$97,$4f,$d9,$9b,$33,$99,$a9,$2f,$ea,$7f,$f5
	dc.b	$fa,$8a,$aa,$ad,$b4,$7e,$77,$d5,$2f,$cb,$35,$6e,$1f,$51,$de,$16
	dc.b	$1e,$0f,$e6,$e7,$fd,$43,$63,$75,$4d,$57,$c1,$ff,$0f,$37,$f1,$7d
	dc.b	$53,$4e,$fc,$df,$7c,$6e,$ef,$cd,$77,$d9,$fa,$b9,$f7,$7f,$f9,$5f
	dc.b	$ea,$bd,$fe,$7c,$1f,$c5,$fa,$ff,$ce,$a8,$7e,$df,$aa,$77,$c6,$d9
	dc.b	$ff,$e9,$7f,$46,$95,$1b,$3a,$37,$ac,$ff,$3f,$a3,$fb,$f3,$23,$f8
	dc.b	$bf,$ef,$fe,$eb,$f4,$6f,$7c,$6e,$9f,$da,$c7,$f4,$62,$fe,$2f,$5b
	dc.b	$e8,$c9,$fc,$5e,$f7,$f3,$43,$fd,$55,$be,$37,$cf,$d1,$dd,$fd,$55
	dc.b	$bf,$aa,$77,$e8,$c6,$fd,$1e,$df,$ab,$b7,$e8,$d2,$ff,$9d,$5f,$f3
	dc.b	$9b,$ed,$4d,$fe,$65,$7f,$cf,$2f,$d1,$8d,$f6,$82,$fd,$1e,$be,$17
	dc.b	$69,$a2,$68,$41,$97,$13,$4e,$ca,$42,$22,$ad,$40,$c8,$76,$56,$2f
	dc.b	$17,$cf,$27,$c4,$12,$cd,$6b,$18,$95,$d1,$28,$f4,$9a,$9d,$5a,$b5
	dc.b	$64,$b3,$5d,$2e,$f7,$bc,$06,$17,$11,$8c,$c8,$65,$73,$39,$cd,$2e
	dc.b	$a3,$55,$b0,$dd,$ef,$79,$3c,$ce,$87,$5f,$b1,$db,$ee,$f7,$bc,$1e
	dc.b	$6f,$77,$e0,$52,$2a,$15,$8d,$22,$32,$5a,$15,$42,$c1,$63,$c2,$6d
	dc.b	$b7,$3e,$bf,$e7,$fc,$4c,$2f,$18,$41,$61,$92,$f0,$e0,$78,$48,$25
	dc.b	$16,$8b,$86,$23,$78,$1c,$6c,$44,$28,$19,$c0,$a1,$51,$70,$b8,$8c
	dc.b	$6a,$36,$7e,$c1,$a6,$53,$80,$a0,$54,$3a,$27,$0d,$8e,$64,$f2,$80
	dc.b	$b0,$7c,$42,$2c,$8a,$48,$25,$41,$91,$c4,$7e,$46,$12,$0c,$0e,$81
	dc.b	$e2,$08,$0c,$c4,$23,$08,$09,$83,$83,$40,$c0,$68,$42,$1b,$15,$89
	dc.b	$cb,$67,$70,$f0,$50,$22,$25,$30,$9b,$82,$e7,$53,$48,$24,$f2,$33
	dc.b	$29,$85,$c7,$24,$51,$09,$0c,$ce,$73,$24,$8d,$02,$63,$d2,$e8,$b4
	dc.b	$76,$6b,$26,$83,$81,$e6,$d3,$d0,$30,$16,$13,$2c,$9f,$43,$a0,$13
	dc.b	$f0,$20,$0c,$00,$02,$00,$8c,$02,$01,$00,$c0,$b9,$e4,$84,$44,$61
	dc.b	$00,$0d
g2embed_gun_end

	even
g2embed_palette8_crm
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$04,$00,$00,$00,$02,$7a,$3f,$df
	dc.b	$5b,$b2,$43,$27,$32,$1d,$23,$32,$03,$26,$a4,$54,$94,$c9,$f4,$84
	dc.b	$c9,$69,$31,$91,$ed,$23,$bf,$bd,$54,$6b,$be,$62,$cb,$ae,$6a,$34
	dc.b	$30,$e2,$c8,$7e,$d4,$6e,$4c,$c5,$9c,$9d,$a8,$c7,$4d,$8b,$0e,$e7
	dc.b	$a8,$cc,$d5,$8b,$19,$07,$a8,$c0,$9d,$c5,$80,$b5,$d4,$6d,$79,$c5
	dc.b	$9a,$13,$a8,$ca,$30,$b0,$0a,$42,$72,$03,$90,$da,$fa,$9d,$93,$6c
	dc.b	$86,$c8,$8c,$97,$49,$f6,$4c,$72,$4b,$23,$d9,$11,$c8,$fd,$ff,$f5
	dc.b	$01,$6e,$df,$c4,$a1,$df,$81,$79,$ef,$89,$1c,$5f,$02,$b2,$1f,$12
	dc.b	$05,$6c,$0b,$a1,$78,$92,$91,$e0,$5a,$61,$e2,$5f,$5d,$c0,$a4,$ad
	dc.b	$c4,$ad,$17,$02,$e3,$a7,$12,$7a,$8e,$05,$bd,$7a,$88,$52,$13,$90
	dc.b	$1c,$8a,$c8,$76,$4d,$b2,$1b,$22,$32,$5d,$27,$d9,$31,$c9,$2c,$8f
	dc.b	$64,$47,$22,$9e,$91,$fe,$75,$cf,$94,$c8,$41,$8c,$e5,$51,$87,$1d
	dc.b	$18,$ce,$d1,$80,$9a,$33,$48,$8c,$55,$c3,$29,$fa,$33,$ec,$63,$09
	dc.b	$94,$65,$9e,$8c,$c5,$18,$c7,$94,$f7,$57,$f7,$a8,$bb,$e5,$05,$09
	dc.b	$31,$77,$20,$c0,$8e,$06,$2e,$65,$50,$20,$55,$17,$68,$e8,$12,$8e
	dc.b	$8b,$a9,$da,$05,$f6,$d1,$71,$26,$81,$58,$d1,$76,$28,$81,$3c,$8e
	dc.b	$a5,$c0,$5f,$be,$89,$77,$49,$8c,$fc,$3e,$61,$4f,$cb,$98,$27,$9d
	dc.b	$3f,$0b,$f6,$61,$c7,$5c,$1f,$b0,$b7,$a3,$31,$0a,$8c,$c6,$9d,$27
	dc.b	$61,$3f,$f3,$bc,$49,$c9,$9b,$18,$fb,$75,$87,$3c,$7a,$c5,$5d,$ea
	dc.b	$b0,$6f,$09,$60,$e1,$09,$ef,$94,$b1,$a1,$b3,$fa,$1f,$20,$ea,$c3
	dc.b	$9e,$c1,$5a,$cd,$d9,$c6,$07,$6e,$18,$7a,$1b,$16,$69,$ad,$e5,$aa
	dc.b	$2b,$b1,$a9,$d3,$fa,$1f,$d1,$6a,$c2,$4a,$e0,$ad,$b3,$9c,$e3,$62
	dc.b	$17,$0c,$37,$96,$8b,$3e,$51,$6f,$ca,$71,$fe,$50,$2f,$f2,$83,$73
	dc.b	$9e,$c4,$dd,$9b,$b0,$f7,$07,$6c,$65,$e8,$6c,$35,$a9,$9e,$15,$f4
	dc.b	$95,$8d,$7f,$da,$63,$de,$4c,$58,$af,$db,$2e,$07,$f8,$d9,$c5,$9b
	dc.b	$c1,$60,$fe,$16,$8b,$08,$42,$57,$7c,$c4,$a1,$b3,$12,$e4,$1c,$48
	dc.b	$e6,$f8,$93,$31,$f1,$20,$6d,$e2,$5a,$97,$ff,$e9,$4f,$12,$a7,$2c
	dc.b	$4b,$ef,$b8,$91,$3b,$71,$2b,$25,$c4,$b1,$33,$89,$3c,$c7,$dd,$44
	dc.b	$94,$77,$52,$ab,$68,$46,$93,$74,$ad,$26,$8c,$f9,$1d,$4b,$f5,$c1
	dc.b	$12,$7e,$e9,$52,$7e,$8c,$b6,$3d,$4b,$69,$42,$38,$bd,$d2,$b8,$bd
	dc.b	$18,$f2,$3d,$4a,$f2,$98,$44,$66,$95,$18,$31,$5f,$e2,$02,$76,$46
	dc.b	$79,$80,$51,$21,$16,$58,$0a,$fc,$8c,$47,$e5,$32,$f9,$8c,$d6,$73
	dc.b	$44,$a4,$d2,$a9,$94,$ea,$ad,$6a,$b9,$64,$b3,$5b,$6d,$f7,$2b,$bd
	dc.b	$ef,$09,$87,$c4,$62,$71,$78,$cc,$e6,$97,$55,$ac,$d6,$ed,$b7,$7b
	dc.b	$dd,$ff,$0f,$8b,$c6,$e3,$f2,$79,$5c,$ce,$77,$5b,$af,$da,$ed,$f7
	dc.b	$7b,$de,$2f,$27,$9f,$d3,$ee,$f7,$80,$a6,$53,$3a,$15,$0e,$a9,$63
	dc.b	$b2,$da,$ee,$97,$6c,$2e,$1b,$2b,$97,$cc,$e9,$b7,$3e,$b8,$8c,$86
	dc.b	$45,$53,$d4,$78,$22,$1a,$0e,$87,$d2,$41,$90,$e0,$40,$68,$15,$0f
	dc.b	$e5,$80,$03,$30,$d8,$7d,$e0,$70,$58,$4c,$2e,$1b,$70,$81,$41,$a1
	dc.b	$50,$ec,$04,$12,$19,$f8,$83,$c2,$3f,$f0,$0f,$80,$02,$1e,$3c,$18
	dc.b	$16,$89,$88,$89,$16,$89,$00,$00
g2embed_palette8_crm_end

	even
g2embed_remap8_crm
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$10,$00,$00,$00,$06,$7e,$7f,$fd
	dc.b	$48,$b3,$35,$50,$3f,$bf,$f7,$a4,$fb,$ed,$76,$be,$f2,$91,$7f,$e6
	dc.b	$6f,$3b,$9f,$f9,$9b,$ce,$73,$fe,$16,$f5,$ac,$ff,$85,$bd,$63,$4f
	dc.b	$cc,$de,$31,$a7,$e1,$6f,$51,$8f,$c2,$de,$23,$1f,$8e,$f3,$ff,$67
	dc.b	$e1,$b7,$81,$e7,$e1,$ab,$6b,$6b,$4f,$3f,$2d,$fc,$6f,$cb,$16,$99
	dc.b	$7e,$38,$df,$8b,$ca,$19,$57,$1d,$f8,$bd,$e9,$34,$f6,$be,$f4,$91
	dc.b	$7d,$5e,$af,$1b,$de,$7b,$9f,$1b,$fc,$1b,$ce,$73,$fe,$16,$f5,$ac
	dc.b	$ff,$85,$bd,$63,$3f,$e5,$6f,$1b,$4f,$f8,$6d,$ea,$34,$fc,$ad,$e2
	dc.b	$34,$fc,$ad,$e2,$34,$fc,$7a,$b4,$c7,$e5,$ab,$7f,$8b,$f1,$c5,$a5
	dc.b	$a7,$9f,$8e,$fe,$2f,$cf,$89,$f2,$7e,$2d,$8d,$8c,$c5,$6b,$5f,$17
	dc.b	$d8,$f7,$94,$d3,$d9,$f6,$3d,$e5,$24,$fa,$bf,$3f,$bd,$26,$37,$1b
	dc.b	$c3,$de,$79,$cf,$87,$87,$54,$de,$75,$9f,$0f,$f3,$37,$ac,$67,$33
	dc.b	$fe,$16,$f1,$b4,$ff,$86,$de,$a5,$3f,$e7,$d5,$12,$7f,$cb,$6f,$10
	dc.b	$9f,$f1,$db,$d8,$69,$f9,$6d,$e0,$69,$f8,$a4,$c7,$e7,$d0,$4c,$7e
	dc.b	$3c,$b7,$5b,$ad,$d8,$c9,$49,$75,$fa,$fa,$9b,$1e,$2b,$15,$92,$ef
	dc.b	$3d,$8f,$15,$fd,$f7,$94,$93,$d4,$fe,$fb,$d2,$5d,$60,$f0,$7e,$f2
	dc.b	$9c,$3c,$34,$39,$de,$f3,$c8,$68,$75,$4d,$ef,$90,$fc,$ea,$37,$ad
	dc.b	$a7,$e0,$15,$1b,$d4,$a7,$53,$fe,$56,$f5,$49,$ff,$2d,$bc,$42,$7f
	dc.b	$c7,$6f,$67,$1f,$f3,$ed,$e0,$c7,$fc,$7a,$0c,$18,$26,$9f,$8a,$4d
	dc.b	$3f,$14,$cd,$e6,$f3,$71,$59,$29,$29,$a5,$68,$0e,$07,$53,$25,$de
	dc.b	$78,$0e,$a6,$a6,$4a,$eb,$bd,$f3,$af,$03,$37,$9c,$eb,$75,$91,$7b
	dc.b	$ba,$ef,$3d,$6b,$43,$9d,$ce,$f7,$94,$a1,$f9,$ff,$0d,$e7,$79,$d5
	dc.b	$2c,$ef,$3b,$cc,$af,$5c,$de,$b7,$00,$a8,$de,$a9,$3f,$01,$55,$37
	dc.b	$88,$4f,$c0,$66,$d0,$3d,$ec,$e3,$f1,$ff,$1d,$bc,$18,$ff,$8f,$41
	dc.b	$fe,$1f,$8f,$45,$8b,$47,$fc,$92,$6a,$68,$37,$25,$75,$57,$ab,$cc
	dc.b	$54,$0d,$c6,$ea,$64,$5e,$fb,$df,$23,$d1,$e4,$48,$ba,$ef,$3c,$44
	dc.b	$89,$1e,$a6,$f5,$ad,$64,$40,$f6,$f7,$9e,$b5,$da,$c0,$f6,$f2,$d7
	dc.b	$77,$9e,$23,$e5,$e5,$e5,$ef,$3d,$e6,$57,$b3,$66,$ce,$f7,$c5,$78
	dc.b	$38,$38,$3a,$34,$77,$9d,$07,$f8,$3b,$77,$9c,$3b,$5a,$de,$ae,$02
	dc.b	$a8,$de,$2e,$03,$7e,$08,$31,$62,$b1,$f8,$2d,$f9,$91,$59,$ec,$ff
	dc.b	$c9,$34,$7f,$c9,$26,$a6,$33,$6e,$ae,$a6,$95,$2c,$de,$6f,$36,$44
	dc.b	$8b,$ae,$f3,$a5,$72,$b2,$20,$40,$ae,$ef,$3a,$57,$2b,$02,$07,$b7
	dc.b	$bc,$f0,$10,$3d,$cd,$e3,$77,$37,$be,$23,$91,$dc,$b9,$bb,$d9,$9d
	dc.b	$de,$f8,$d7,$66,$cd,$9a,$3b,$df,$1a,$e0,$ec,$d1,$a3,$47,$79,$d0
	dc.b	$63,$a3,$a3,$b8,$70,$ef,$38,$74,$76,$a3,$97,$7a,$dd,$bd,$b5,$2d
	dc.b	$e3,$70,$65,$46,$f1,$70,$1a,$a9,$bd,$9c,$0e,$fd,$dc,$14,$7e,$0f
	dc.b	$bf,$81,$88,$f8,$15,$d9,$7c,$be,$b4,$69,$1f,$02,$07,$79,$dd,$40
	dc.b	$2e,$57,$77,$9d,$0f,$87,$81,$ee,$6f,$3c,$e6,$ef,$bc,$ed,$3d,$37
	dc.b	$39,$2d,$ea,$ea,$6a,$f0,$0d,$e7,$92,$e8,$89,$d1,$ef,$3b,$0e,$ab
	dc.b	$46,$8e,$1d,$e7,$87,$68,$e1,$c3,$87,$7b,$ee,$de,$de,$dc,$3c,$bc
	dc.b	$bb,$ce,$ed,$a8,$8d,$8d,$de,$33,$6b,$6d,$4a,$4f,$7a,$b8,$32,$b9
	dc.b	$bc,$5c,$15,$51,$bd,$9c,$16,$fc,$c3,$c0,$fa,$e9,$a5,$48,$d0,$3e
	dc.b	$e5,$ca,$ee,$f5,$b4,$f3,$93,$bb,$d6,$d3,$d3,$72,$e7,$57,$56,$77
	dc.b	$7b,$ec,$01,$d4,$de,$b6,$ae,$aa,$aa,$5a,$5d,$1e,$f1,$8d,$66,$bd
	dc.b	$55,$55,$54,$bd,$e7,$61,$f0,$f8,$15,$bd,$6d,$58,$91,$22,$78,$77
	dc.b	$94,$e1,$ca,$6f,$7d,$67,$87,$0f,$2f,$2c,$6e,$f3,$9b,$5b,$5b,$7f
	dc.b	$06,$f5,$9b,$40,$ea,$9d,$ce,$37,$a8,$0c,$0e,$b8,$64,$ce,$f5,$70
	dc.b	$0a,$e0,$6e,$f6,$70,$57,$b0,$0a,$17,$c9,$92,$6e,$76,$3f,$34,$a8
	dc.b	$31,$54,$9d,$de,$32,$6d,$36,$9b,$34,$d5,$9d,$de,$37,$46,$52,$8f
	dc.b	$78,$df,$bf,$df,$ef,$00,$09,$ef,$3b,$00,$09,$ef,$5b,$02,$b7,$ac
	dc.b	$1e,$98,$03,$a9,$bc,$5a,$bd,$5e,$ac,$4c,$ab,$2b,$2b,$28,$5e,$f5
	dc.b	$ac,$e5,$65,$59,$79,$77,$9e,$b3,$95,$c8,$de,$71,$9f,$2f,$2f,$e0
	dc.b	$de,$70,$18,$1e,$f0,$33,$bd,$6c,$bd,$53,$b9,$f3,$78,$b2,$e1,$ba
	dc.b	$e1,$90,$d0,$dd,$e2,$e0,$1f,$59,$dc,$e0,$eb,$ae,$17,$0b,$85,$eb
	dc.b	$87,$9d,$7e,$e5,$70,$d3,$af,$ab,$54,$a3,$de,$ae,$e5,$52,$8f,$7a
	dc.b	$9f,$6f,$b7,$da,$aa,$a8,$91,$22,$7b,$d2,$44,$b2,$b6,$f7,$ab,$00
	dc.b	$db,$ce,$c0,$0c,$ac,$bb,$c6,$0f,$4a,$21,$bd,$f6,$e0,$a5,$a5,$dd
	dc.b	$23,$de,$f9,$36,$96,$37,$7b,$e3,$3e,$31,$b5,$1b,$ce,$8d,$8d,$93
	dc.b	$c8,$de,$b6,$5c,$37,$f8,$5b,$c6,$0d,$86,$ff,$7e,$b0,$f7,$7a,$8c
	dc.b	$7e,$fe,$67,$9c,$d3,$af,$7a,$a9,$a5,$41,$95,$53,$7a,$8c,$7b,$d5
	dc.b	$6a,$9b,$d4,$69,$90,$25,$b7,$bd,$57,$bb,$dd,$ec,$4e,$00,$e8,$de
	dc.b	$ac,$0c,$65,$0b,$de,$93,$4a,$17,$bc,$54,$46,$a5,$23,$de,$2b,$3b
	dc.b	$3c,$0a,$de,$ae,$a6,$01,$6f,$58,$cf,$00,$90,$df,$0e,$97,$1e,$3b
	dc.b	$b2,$68,$50,$d6,$f7,$8c,$ab,$15,$15,$ce,$6f,$59,$0f,$27,$27,$f9
	dc.b	$9b,$d6,$fd,$fc,$ad,$e3,$7e,$fe,$1b,$37,$34,$cc,$ef,$f3,$f9,$eb
	dc.b	$86,$55,$43,$15,$43,$0e,$f1,$35,$46,$de,$f1,$74,$09,$34,$95,$0b
	dc.b	$de,$23,$4c,$95,$2e,$f1,$1e,$cf,$67,$b9,$5c,$0c,$a5,$de,$b6,$06
	dc.b	$52,$ee,$91,$ef,$66,$03,$88,$f7,$ab,$00,$d5,$bd,$ec,$33,$33,$c0
	dc.b	$36,$f1,$75,$30,$06,$ee,$f1,$95,$6a,$b5,$5e,$01,$75,$37,$ab,$70
	dc.b	$19,$33,$a7,$49,$6f,$78,$c8,$75,$d9,$9a,$83,$dd,$e3,$41,$cc,$99
	dc.b	$c9,$6f,$1b,$f4,$37,$f2,$b3,$5c,$ce,$d6,$f3,$4a,$a1,$d5,$53,$78
	dc.b	$8f,$2d,$f9,$18,$43,$fa,$a5,$6a,$30,$84,$18,$3f,$c2,$54,$d1,$37
	dc.b	$89,$1e,$f6,$1a,$2b,$f4,$83,$a9,$bd,$9d,$18,$05,$bd,$6c,$0a,$de
	dc.b	$2c,$07,$5f,$0f,$ec,$c0,$c4,$28,$50,$96,$f7,$87,$f0,$c0,$cd,$ea
	dc.b	$ea,$60,$1b,$7b,$0d,$10,$f8,$15,$bd,$9d,$14,$40,$37,$d7,$d7,$d7
	dc.b	$6f,$bd,$50,$76,$39,$ad,$eb,$06,$86,$9e,$fd,$65,$ab,$99,$d8,$df
	dc.b	$5b,$5a,$68,$5a,$66,$37,$a6,$a6,$ef,$67,$f5,$26,$d5,$37,$b3,$f8
	dc.b	$93,$6a,$37,$b3,$fb,$33,$9b,$bb,$d9,$fc,$13,$4d,$38,$8a,$ee,$c5
	dc.b	$de,$06,$92,$fd,$20,$15,$15,$43,$5b,$de,$1d,$4a,$4c,$15,$ca,$6f
	dc.b	$0d,$de,$ef,$77,$80,$48,$50,$ef,$63,$eb,$eb,$ee,$01,$af,$87,$f0
	dc.b	$86,$1d,$4d,$3d,$1e,$6f,$6f,$6f,$70,$2d,$4f,$f9,$f3,$fd,$6d,$3b
	dc.b	$d4,$69,$07,$c0,$36,$f0,$ed,$65,$38,$f8,$ce,$f6,$b6,$ae,$66,$2d
	dc.b	$f6,$2c,$4f,$4f,$4d,$07,$76,$b6,$be,$b3,$73,$fe,$5a,$5b,$54,$33
	dc.b	$1f,$fc,$78,$96,$9a,$41,$3a,$df,$f2,$90,$60,$d5,$0c,$97,$fe,$35
	dc.b	$48,$26,$91,$4f,$27,$fe,$35,$08,$62,$c5,$35,$35,$30,$3f,$f1,$ae
	dc.b	$75,$0d,$4d,$4d,$3b,$f3,$4a,$84,$26,$a6,$a1,$42,$9a,$37,$f9,$2d
	dc.b	$3a,$4b,$61,$42,$85,$4b,$a5,$d2,$e2,$a2,$b5,$cd,$3a,$7d,$42,$85
	dc.b	$f2,$fa,$fa,$fa,$69,$51,$a7,$a3,$cc,$5e,$2f,$17,$5d,$ae,$f2,$6f
	dc.b	$3e,$73,$6f,$6f,$6f,$4f,$3a,$9e,$bd,$4c,$d3,$4a,$fc,$c3,$1f,$5a
	dc.b	$a6,$df,$35,$cc,$d0,$bf,$34,$63,$eb,$9c,$b5,$73,$31,$9f,$b1,$62
	dc.b	$c7,$8f,$8f,$8f,$29,$6b,$eb,$30,$9f,$b1,$62,$7a,$3b,$1d,$9a,$1d
	dc.b	$fd,$7e,$b0,$4c,$d4,$80,$37,$22,$d2,$01,$0f,$88,$48,$24,$32,$29
	dc.b	$1c,$92,$4b,$26,$96,$4b,$65,$d2,$f9,$9d,$02,$83,$50,$af,$58,$2c
	dc.b	$36,$cb,$6d,$c7,$05,$91,$d6,$40,$60,$d0,$88,$5c,$32,$1b,$0e,$98
	dc.b	$4c,$66,$54,$2a,$1d,$3a,$a3,$52,$b1,$59,$2c,$d8,$3c,$96,$4f,$2b
	dc.b	$9f,$d6,$c0,$a0,$70,$48,$54,$46,$25,$17,$8e,$ca,$25,$53,$49,$ad
	dc.b	$12,$8b,$46,$a4,$52,$69,$54,$ba,$65,$36,$9f,$55,$ab,$d7,$2b,$b6
	dc.b	$3b,$45,$a6,$d5,$6b,$b7,$5f,$b0,$98,$fc,$a6,$9f,$55,$ab,$82,$c2
	dc.b	$62,$71,$e9,$fd,$4e,$a9,$56,$ac,$56,$ec,$b7,$2c,$2e,$5b,$41,$a8
	dc.b	$8b,$4f,$ab,$35,$ab,$3d,$cf,$17,$97,$cf,$68,$74,$da,$98,$a4,$56
	dc.b	$31,$1c,$8f,$ca,$65,$78,$ec,$d6,$93,$4b,$19,$8d,$46,$e6,$d3,$79
	dc.b	$ed,$ef,$15,$8d,$ce,$e8,$f5,$d3,$ab,$bd,$e2,$f5,$7d,$c4,$e6,$33
	dc.b	$3a,$29,$cc,$ee,$79,$76,$c3,$63,$33,$80,$a0,$5d,$e6,$f9,$7f,$c3
	dc.b	$dd,$31,$19,$b9,$c5,$d4,$10,$09,$03,$81,$80,$a0,$40,$18,$08,$00
	dc.b	$01,$0e,$12,$8c,$09,$04,$34,$22,$89,$04,$00,$02
g2embed_remap8_crm_end

	even
g2embed_title
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$c3,$52,$00,$00,$86,$a6,$32,$e0
	dc.b	$04,$0c,$1d,$f8,$88,$94,$86,$1a,$65,$1f,$17,$c0,$99,$b9,$da,$26
	dc.b	$ce,$f7,$44,$1d,$93,$fb,$5a,$26,$de,$84,$8d,$0c,$f8,$ea,$97,$1a
	dc.b	$33,$e7,$ac,$8a,$22,$4d,$e5,$1d,$28,$90,$2f,$ac,$b3,$c4,$34,$55
	dc.b	$cf,$b0,$22,$86,$19,$87,$b3,$66,$8c,$e0,$30,$a0,$22,$88,$1e,$16
	dc.b	$b2,$7e,$dc,$d9,$eb,$43,$04,$0b,$3e,$1b,$30,$6f,$5f,$c4,$d3,$20
	dc.b	$ff,$1c,$40,$d9,$8d,$00,$77,$07,$78,$27,$67,$f4,$7f,$69,$12,$16
	dc.b	$9e,$4c,$d2,$24,$ae,$22,$3d,$fe,$90,$d3,$38,$f9,$70,$15,$1a,$80
	dc.b	$0a,$97,$bf,$7c,$a2,$f3,$49,$03,$54,$a6,$e9,$f5,$48,$ea,$18,$16
	dc.b	$62,$32,$7e,$fd,$2d,$20,$ee,$2e,$e0,$ef,$35,$7e,$ca,$8e,$f1,$90
	dc.b	$ff,$4a,$a6,$cd,$ce,$a8,$3b,$bf,$f9,$53,$19,$d1,$c6,$34,$0c,$3e
	dc.b	$b5,$c6,$77,$ed,$50,$0c,$96,$41,$be,$d3,$2c,$33,$b7,$1f,$23,$e2
	dc.b	$00,$c8,$12,$49,$90,$88,$0b,$29,$d9,$3d,$69,$f9,$88,$9a,$a1,$8f
	dc.b	$7d,$20,$32,$7e,$e9,$96,$69,$88,$83,$b7,$4a,$66,$d9,$af,$d8,$6a
	dc.b	$44,$a5,$37,$bf,$23,$70,$2b,$34,$bb,$9e,$40,$77,$cb,$b5,$c8,$19
	dc.b	$2d,$03,$a8,$d0,$c4,$dc,$eb,$8e,$60,$99,$b3,$6b,$81,$07,$e0,$88
	dc.b	$2e,$9e,$59,$10,$da,$1c,$12,$11,$10,$16,$88,$a4,$b4,$19,$73,$d1
	dc.b	$26,$18,$08,$b9,$d8,$76,$84,$08,$32,$de,$a4,$99,$d1,$0c,$a8,$23
	dc.b	$29,$23,$79,$64,$40,$d9,$8d,$2a,$40,$b4,$67,$61,$da,$da,$7c,$07
	dc.b	$65,$bd,$c7,$87,$62,$25,$f9,$cf,$27,$6d,$a7,$08,$76,$f3,$d1,$d9
	dc.b	$6f,$c1,$e2,$6f,$84,$34,$bf,$19,$15,$44,$89,$3b,$79,$23,$ca,$ce
	dc.b	$c6,$58,$76,$e6,$2c,$ec,$65,$b1,$7b,$54,$88,$1f,$09,$0a,$43,$b1
	dc.b	$29,$c4,$c2,$5b,$12,$76,$f3,$7a,$79,$a6,$56,$64,$43,$3e,$04,$4c
	dc.b	$9c,$61,$a7,$99,$da,$75,$c7,$8a,$b9,$ac,$4a,$ef,$ce,$79,$4d,$3b
	dc.b	$72,$70,$85,$a0,$69,$d4,$07,$14,$30,$1e,$66,$63,$38,$3c,$4d,$f0
	dc.b	$e7,$76,$fc,$22,$a6,$26,$e2,$2e,$b3,$37,$08,$d9,$b8,$27,$54,$66
	dc.b	$12,$f5,$f4,$49,$bb,$01,$56,$7a,$22,$17,$b5,$ed,$52,$25,$5d,$85
	dc.b	$92,$e0,$31,$20,$3e,$a7,$97,$11,$3d,$6c,$15,$d4,$f5,$e6,$1f,$c8
	dc.b	$05,$38,$c1,$4b,$e7,$1d,$03,$fd,$26,$e3,$34,$1c,$73,$d8,$ca,$91
	dc.b	$bf,$d0,$79,$0b,$ee,$7d,$01,$92,$d0,$14,$c6,$81,$72,$48,$cd,$1c
	dc.b	$d5,$0e,$82,$8d,$e5,$35,$6a,$84,$99,$3b,$65,$31,$cb,$d2,$dc,$d3
	dc.b	$d3,$95,$45,$b3,$e5,$c3,$15,$54,$44,$bd,$f4,$0a,$91,$45,$4b,$95
	dc.b	$ef,$82,$45,$65,$48,$ef,$e5,$04,$60,$d8,$ca,$63,$15,$7b,$76,$cd
	dc.b	$ca,$b2,$f2,$4b,$94,$14,$de,$0d,$74,$bb,$f8,$17,$a8,$b7,$e9,$6d
	dc.b	$cc,$0d,$bc,$22,$a7,$40,$3b,$ab,$ad,$b9,$a9,$e4,$b4,$30,$62,$9e
	dc.b	$63,$6c,$77,$f2,$70,$10,$43,$21,$91,$48,$51,$a6,$13,$78,$21,$3e
	dc.b	$ed,$81,$d9,$ff,$25,$82,$13,$d4,$a8,$27,$06,$43,$33,$44,$08,$62
	dc.b	$2d,$b7,$48,$47,$80,$9a,$05,$8c,$4b,$b9,$5c,$fb,$95,$e4,$4c,$1c
	dc.b	$cc,$83,$dc,$92,$0e,$83,$89,$cd,$2e,$05,$75,$1f,$71,$ad,$c8,$3b
	dc.b	$59,$83,$6f,$c9,$21,$08,$6e,$67,$7c,$38,$4b,$82,$e7,$49,$0f,$e0
	dc.b	$46,$5d,$41,$16,$67,$89,$f8,$2d,$ff,$02,$22,$50,$16,$72,$b2,$b6
	dc.b	$4d,$b9,$6d,$2e,$2b,$61,$cd,$25,$04,$44,$c6,$e1,$16,$ab,$8b,$c6
	dc.b	$09,$a7,$a4,$60,$9f,$7c,$f2,$f2,$a7,$0b,$ce,$71,$48,$b0,$52,$a2
	dc.b	$54,$89,$a7,$41,$0c,$ea,$68,$21,$87,$79,$87,$6a,$44,$86,$9d,$27
	dc.b	$97,$10,$f5,$05,$59,$b4,$d3,$74,$84,$70,$25,$a2,$01,$f8,$5f,$7c
	dc.b	$59,$95,$f8,$a2,$b7,$e0,$0c,$88,$47,$c5,$ff,$28,$92,$38,$fb,$7c
	dc.b	$4e,$f6,$eb,$01,$18,$57,$72,$40,$7e,$08,$9d,$fe,$f2,$df,$85,$bc
	dc.b	$b6,$c8,$3e,$13,$56,$7e,$32,$a0,$1b,$d3,$ae,$9a,$45,$2c,$4a,$02
	dc.b	$33,$43,$04,$a3,$77,$e2,$77,$03,$a3,$c6,$09,$c5,$08,$08,$95,$7e
	dc.b	$85,$b5,$8c,$e1,$58,$0b,$5f,$28,$52,$37,$ac,$04,$d8,$da,$19,$a7
	dc.b	$f2,$d4,$85,$36,$43,$9d,$99,$53,$f3,$2c,$08,$d4,$4a,$5b,$64,$50
	dc.b	$40,$1e,$62,$3e,$c8,$98,$c6,$17,$50,$6b,$08,$17,$87,$43,$e2,$92
	dc.b	$3f,$4b,$91,$d3,$2c,$87,$db,$3e,$b6,$a0,$a2,$89,$46,$7e,$72,$4e
	dc.b	$c1,$dd,$58,$9b,$fe,$4d,$b5,$7e,$74,$3e,$45,$bc,$b4,$74,$34,$ec
	dc.b	$80,$29,$03,$18,$27,$ad,$01,$5f,$9a,$37,$a2,$a4,$35,$b5,$75,$92
	dc.b	$50,$46,$8f,$4e,$1b,$69,$8f,$df,$74,$8a,$7f,$0c,$0a,$0e,$8b,$a3
	dc.b	$7b,$19,$83,$a8,$71,$a5,$be,$e9,$0a,$89,$49,$8d,$fc,$c9,$99,$0e
	dc.b	$a8,$34,$84,$e3,$9d,$e6,$ed,$f6,$e7,$d9,$b7,$5f,$b7,$05,$75,$0a
	dc.b	$33,$41,$fc,$92,$0c,$08,$22,$28,$c1,$78,$7f,$7c,$95,$d9,$e8,$c0
	dc.b	$32,$33,$48,$ed,$a2,$f3,$41,$12,$95,$c3,$b7,$62,$65,$f3,$78,$6b
	dc.b	$85,$b5,$8e,$bf,$f0,$d9,$b6,$9f,$ec,$7f,$0f,$3e,$be,$04,$05,$f0
	dc.b	$12,$fc,$a3,$43,$0c,$eb,$f7,$25,$00,$4e,$10,$81,$f8,$30,$24,$df
	dc.b	$49,$96,$c9,$73,$6d,$82,$de,$75,$e7,$b1,$57,$d1,$c3,$f7,$b1,$93
	dc.b	$88,$0a,$b7,$0e,$b4,$2b,$bf,$89,$a3,$14,$8c,$63,$47,$17,$f1,$24
	dc.b	$ea,$19,$4e,$d2,$3d,$24,$8e,$08,$72,$9a,$82,$67,$fc,$ed,$d7,$e6
	dc.b	$c1,$12,$e2,$da,$c5,$4f,$80,$08,$0d,$61,$97,$ca,$59,$80,$11,$89
	dc.b	$c2,$b7,$99,$8d,$2d,$75,$fc,$eb,$8b,$ea,$f3,$af,$c5,$2c,$38,$09
	dc.b	$63,$da,$fa,$e6,$19,$de,$09,$92,$a7,$40,$88,$35,$56,$47,$b1,$6f
	dc.b	$ff,$8d,$95,$65,$ff,$fb,$f8,$f3,$37,$91,$fc,$08,$b4,$75,$d7,$c0
	dc.b	$7c,$86,$19,$87,$85,$13,$09,$7c,$43,$1b,$51,$f7,$c5,$e4,$9f,$4f
	dc.b	$35,$60,$48,$8a,$fa,$85,$5d,$25,$46,$12,$25,$5f,$83,$6f,$4a,$7f
	dc.b	$5a,$f8,$51,$22,$c2,$88,$e4,$ae,$88,$e1,$43,$d8,$4d,$c4,$47,$e0
	dc.b	$d2,$38,$6a,$de,$68,$2a,$6f,$c4,$5a,$40,$2a,$74,$11,$22,$3a,$7b
	dc.b	$11,$ff,$81,$de,$d5,$7c,$6a,$ca,$80,$ee,$c2,$78,$8d,$05,$be,$42
	dc.b	$a2,$ff,$78,$95,$a5,$a5,$12,$67,$d7,$ca,$5b,$36,$a9,$06,$f1,$bf
	dc.b	$cf,$c0,$54,$e8,$ec,$9d,$17,$19,$0f,$c0,$69,$21,$70,$c7,$db,$fe
	dc.b	$c1,$5e,$6f,$41,$44,$83,$12,$df,$94,$04,$c1,$2c,$85,$00,$c7,$c1
	dc.b	$2c,$8d,$bb,$c1,$2e,$0a,$09,$37,$95,$c0,$88,$04,$57,$26,$9f,$74
	dc.b	$9d,$06,$5e,$8a,$e8,$a1,$1c,$f8,$18,$5a,$68,$62,$e0,$46,$58,$d2
	dc.b	$6e,$9e,$81,$6c,$ca,$45,$82,$06,$22,$70,$bd,$ac,$ca,$62,$e9,$04
	dc.b	$81,$d7,$e6,$d8,$89,$0b,$05,$63,$25,$03,$cc,$95,$a0,$3f,$8d,$5d
	dc.b	$9f,$11,$0a,$ce,$1a,$48,$c9,$fc,$40,$58,$93,$ae,$df,$81,$71,$9d
	dc.b	$a0,$cf,$a8,$0a,$53,$01,$d1,$3e,$c9,$90,$3c,$2f,$c4,$49,$31,$58
	dc.b	$cd,$4f,$d9,$10,$de,$bb,$10,$57,$78,$60,$2f,$2d,$0c,$ba,$fd,$bc
	dc.b	$6b,$76,$61,$15,$93,$64,$b8,$35,$33,$72,$18,$3a,$54,$15,$c1,$41
	dc.b	$2e,$f3,$b3,$35,$93,$f4,$29,$9f,$a1,$01,$09,$0a,$01,$75,$34,$20
	dc.b	$4b,$3f,$06,$9a,$e3,$03,$28,$67,$cf,$22,$0d,$54,$9b,$00,$e5,$0a
	dc.b	$58,$81,$1e,$b4,$3d,$82,$06,$18,$e0,$c6,$0b,$29,$65,$d4,$91,$40
	dc.b	$03,$c2,$e6,$aa,$90,$66,$33,$ad,$e9,$15,$6f,$f6,$99,$1e,$7d,$24
	dc.b	$c2,$04,$21,$62,$ec,$06,$99,$6d,$bd,$e2,$1b,$64,$43,$70,$eb,$ec
	dc.b	$7c,$92,$3f,$b6,$01,$19,$22,$e7,$d8,$fb,$1f,$7a,$13,$48,$b0,$dd
	dc.b	$e8,$80,$8c,$bf,$bc,$b4,$ca,$be,$2b,$9e,$6d,$24,$1a,$97,$18,$12
	dc.b	$9d,$3f,$06,$e0,$ca,$7c,$3e,$f3,$88,$39,$ae,$27,$b6,$91,$30,$6e
	dc.b	$07,$fe,$50,$cb,$22,$60,$dc,$03,$2c,$d1,$18,$81,$0c,$68,$7b,$06
	dc.b	$23,$19,$a0,$dc,$fb,$f7,$f1,$5c,$02,$2e,$17,$83,$6c,$c7,$fd,$7e
	dc.b	$22,$f9,$ac,$10,$f8,$99,$f8,$92,$89,$d0,$6d,$9b,$4c,$6d,$99,$ee
	dc.b	$47,$5e,$b7,$07,$9e,$6e,$93,$52,$01,$d6,$ee,$c9,$90,$57,$08,$b9
	dc.b	$f6,$3e,$67,$e5,$ec,$88,$0e,$94,$6e,$fa,$b3,$02,$bc,$a1,$b7,$e7
	dc.b	$b4,$09,$72,$af,$8b,$0e,$27,$4a,$73,$e2,$43,$dc,$86,$75,$57,$d4
	dc.b	$06,$36,$6a,$8c,$60,$8f,$29,$b9,$c4,$6f,$9b,$5d,$45,$15,$e6,$4d
	dc.b	$3f,$70,$43,$33,$3d,$e2,$f3,$e5,$0c,$e3,$16,$24,$a8,$26,$d4,$5b
	dc.b	$80,$40,$d4,$b8,$a2,$11,$1a,$94,$06,$5d,$88,$d6,$de,$fe,$22,$80
	dc.b	$0a,$56,$42,$df,$c3,$ff,$33,$81,$04,$d2,$25,$11,$78,$ba,$b7,$13
	dc.b	$bb,$71,$18,$f6,$94,$75,$e8,$5b,$df,$10,$6f,$c7,$94,$38,$2e,$a6
	dc.b	$13,$66,$bf,$65,$e4,$fe,$2e,$1d,$98,$4b,$92,$43,$f3,$ff,$77,$15
	dc.b	$f8,$44,$8b,$ad,$1a,$7d,$40,$25,$e5,$a0,$7e,$06,$95,$02,$c4,$be
	dc.b	$79,$58,$bb,$28,$52,$d4,$7c,$48,$79,$53,$a9,$92,$d5,$cc,$3e,$0e
	dc.b	$11,$4b,$2c,$70,$8e,$ba,$b5,$3a,$18,$cd,$22,$98,$33,$f0,$ad,$b4
	dc.b	$c5,$0d,$6e,$81,$7d,$81,$f9,$43,$1a,$85,$6d,$6b,$a7,$cc,$84,$58
	dc.b	$9c,$0e,$fd,$0a,$9a,$15,$b3,$16,$f8,$f9,$c5,$a4,$54,$6f,$b0,$d6
	dc.b	$7c,$13,$5e,$75,$fd,$de,$17,$d2,$2b,$da,$d8,$51,$27,$71,$1a,$43
	dc.b	$84,$84,$fd,$34,$a8,$84,$32,$4a,$d4,$1e,$dd,$94,$75,$d0,$90,$73
	dc.b	$59,$e1,$20,$5c,$8e,$55,$3a,$12,$da,$6f,$96,$ec,$72,$be,$11,$51
	dc.b	$03,$8d,$3e,$4e,$12,$e7,$5e,$0f,$c4,$bb,$2b,$86,$80,$b1,$26,$26
	dc.b	$c3,$8c,$64,$cc,$10,$2e,$b4,$d7,$3f,$92,$99,$ba,$8b,$b6,$82,$03
	dc.b	$1f,$48,$2d,$d9,$51,$fe,$09,$16,$9f,$50,$50,$29,$31,$25,$77,$06
	dc.b	$7c,$e7,$3c,$39,$9f,$ca,$52,$22,$f2,$a4,$65,$14,$f1,$e3,$2c,$7e
	dc.b	$85,$5d,$1e,$d8,$02,$ff,$ba,$98,$ff,$14,$f3,$24,$3e,$9c,$54,$82
	dc.b	$4c,$67,$31,$01,$6a,$a5,$07,$30,$56,$6e,$20,$20,$39,$83,$29,$73
	dc.b	$dd,$4c,$89,$5b,$43,$e4,$86,$cd,$e2,$95,$94,$74,$d4,$58,$96,$dd
	dc.b	$44,$b6,$60,$6d,$a2,$5c,$2d,$01,$72,$48,$23,$4d,$c0,$5c,$6d,$2a
	dc.b	$24,$45,$35,$5f,$ac,$98,$bb,$1c,$92,$13,$f8,$f2,$c0,$69,$01,$02
	dc.b	$32,$21,$ca,$de,$05,$ca,$d1,$3e,$fc,$5f,$31,$0c,$7a,$14,$87,$df
	dc.b	$8b,$48,$81,$11,$4b,$2c,$50,$47,$38,$16,$cd,$88,$10,$33,$a0,$8a
	dc.b	$32,$23,$c5,$4f,$ca,$82,$1f,$08,$13,$4e,$10,$bf,$16,$0d,$3e,$a1
	dc.b	$9d,$a8,$81,$f8,$fd,$a4,$b3,$9c,$88,$54,$18,$8a,$5f,$b7,$6c,$de
	dc.b	$08,$68,$6b,$3a,$ae,$fd,$a4,$ed,$1c,$bc,$ce,$c8,$14,$06,$d0,$a7
	dc.b	$e0,$ec,$fd,$09,$db,$3b,$fa,$6d,$37,$c1,$19,$9f,$f4,$32,$0f,$f8
	dc.b	$bb,$f6,$41,$05,$86,$0d,$8b,$bc,$46,$89,$f9,$53,$91,$d6,$90,$eb
	dc.b	$1c,$cb,$b0,$81,$3e,$7f,$7e,$29,$2e,$fe,$07,$e1,$01,$51,$91,$0e
	dc.b	$78,$25,$59,$01,$97,$5c,$2e,$e3,$2b,$b0,$48,$c0,$9d,$48,$45,$46
	dc.b	$5e,$53,$65,$04,$46,$02,$03,$74,$02,$6a,$03,$51,$03,$54,$54,$37
	dc.b	$7f,$6c,$c9,$50,$63,$55,$41,$12,$29,$f6,$34,$e7,$f2,$21,$59,$68
	dc.b	$13,$79,$71,$92,$6e,$1b,$bc,$70,$d9,$05,$e5,$ca,$38,$21,$a6,$dc
	dc.b	$7f,$e9,$73,$e2,$25,$ee,$95,$c8,$e8,$34,$61,$f0,$2d,$be,$39,$b2
	dc.b	$23,$3d,$17,$e1,$b1,$ac,$3a,$91,$f0,$e0,$99,$43,$8f,$29,$0b,$ed
	dc.b	$40,$b0,$c8,$39,$3f,$7b,$f3,$48,$32,$55,$80,$d7,$d4,$9f,$99,$b9
	dc.b	$bd,$ec,$10,$4e,$de,$08,$93,$19,$d8,$07,$14,$d8,$0c,$f8,$2d,$58
	dc.b	$fe,$14,$50,$85,$8a,$27,$ba,$bf,$08,$15,$9c,$73,$48,$86,$e4,$11
	dc.b	$95,$43,$2f,$a0,$d3,$50,$1b,$74,$08,$39,$50,$73,$a2,$f8,$21,$03
	dc.b	$02,$92,$97,$94,$32,$97,$db,$94,$3e,$c1,$d0,$46,$d8,$51,$50,$1a
	dc.b	$a8,$a1,$47,$ca,$25,$ff,$6a,$7b,$72,$cc,$10,$d3,$ed,$3f,$b2,$94
	dc.b	$74,$c4,$bc,$69,$d4,$d6,$03,$59,$02,$4d,$d7,$3b,$3e,$8e,$6a,$ff
	dc.b	$7a,$6f,$41,$19,$72,$a4,$fe,$fa,$0c,$d1,$bc,$c6,$cd,$01,$61,$8c
	dc.b	$4b,$ef,$09,$7c,$1a,$55,$72,$3a,$92,$08,$b5,$47,$c0,$82,$72,$e1
	dc.b	$04,$15,$9d,$b7,$84,$0b,$d4,$15,$33,$a1,$5e,$a1,$02,$55,$c0,$2a
	dc.b	$84,$35,$e4,$3e,$20,$20,$3e,$5e,$c9,$4e,$92,$94,$12,$fc,$4d,$a1
	dc.b	$6c,$fc,$1b,$d7,$00,$b7,$02,$37,$d0,$fc,$13,$cd,$5f,$62,$45,$1f
	dc.b	$62,$1a,$91,$e5,$09,$82,$b0,$e0,$aa,$fd,$ae,$75,$63,$f5,$1e,$f7
	dc.b	$88,$56,$0c,$0d,$f8,$ec,$88,$88,$4b,$cc,$fe,$eb,$27,$00,$86,$f0
	dc.b	$22,$4f,$a2,$67,$c3,$84,$ba,$ee,$8f,$0f,$fe,$e2,$3b,$df,$87,$0b
	dc.b	$40,$07,$ca,$81,$20,$fd,$68,$67,$5f,$22,$0f,$11,$4f,$ac,$d4,$4b
	dc.b	$f2,$8e,$60,$d4,$9f,$01,$09,$14,$10,$94,$5e,$d3,$c1,$08,$cb,$9e
	dc.b	$f8,$32,$da,$4e,$26,$b8,$08,$74,$21,$56,$8d,$2d,$a4,$5e,$34,$c6
	dc.b	$85,$39,$6a,$4c,$99,$79,$1f,$68,$6b,$f1,$4e,$f3,$ed,$54,$3b,$52
	dc.b	$78,$92,$4d,$de,$22,$12,$2f,$7c,$44,$a5,$8e,$e8,$db,$cb,$8c,$6a
	dc.b	$1b,$d5,$f9,$50,$3f,$f6,$94,$8d,$0d,$c6,$d7,$08,$84,$82,$5e,$ca
	dc.b	$c9,$2a,$30,$3b,$7a,$11,$6c,$99,$f4,$db,$b7,$a3,$b2,$42,$da,$af
	dc.b	$eb,$97,$a7,$28,$e0,$33,$17,$e8,$20,$5f,$c8,$84,$fc,$ce,$44,$ac
	dc.b	$86,$80,$96,$4f,$80,$53,$42,$06,$05,$19,$65,$82,$70,$8f,$e6,$08
	dc.b	$4b,$55,$5c,$bf,$e0,$85,$33,$29,$7e,$d2,$8d,$28,$1e,$c3,$04,$ee
	dc.b	$d9,$f6,$e4,$7d,$ba,$00,$ea,$fd,$ea,$45,$9b,$a9,$66,$07,$e3,$52
	dc.b	$00,$f2,$2f,$94,$8d,$7c,$30,$a5,$0f,$b2,$a2,$ae,$5b,$2b,$db,$f2
	dc.b	$0d,$60,$3e,$18,$a1,$83,$70,$c0,$bb,$6e,$08,$8d,$17,$bf,$cd,$c1
	dc.b	$9d,$4b,$37,$0b,$f6,$07,$fd,$69,$de,$8e,$05,$35,$cd,$73,$3c,$43
	dc.b	$3d,$d2,$81,$f4,$19,$42,$ab,$e8,$15,$68,$65,$ae,$25,$cb,$21,$14
	dc.b	$89,$b9,$0c,$53,$67,$d4,$29,$05,$8b,$a6,$ef,$2a,$19,$8c,$70,$a3
	dc.b	$dc,$e7,$40,$d0,$0e,$7d,$08,$08,$56,$79,$9d,$af,$bf,$23,$e6,$28
	dc.b	$26,$34,$cd,$72,$3e,$92,$05,$6b,$7a,$35,$21,$1c,$08,$03,$65,$94
	dc.b	$04,$fc,$e8,$e0,$1c,$c9,$10,$86,$25,$06,$09,$4d,$0f,$78,$d9,$a7
	dc.b	$3f,$94,$5e,$03,$8c,$b0,$ce,$8b,$55,$f8,$ff,$9f,$1a,$d5,$a3,$e5
	dc.b	$25,$12,$f5,$67,$ce,$05,$60,$29,$44,$25,$c2,$b6,$f8,$9d,$22,$c0
	dc.b	$ff,$62,$27,$d6,$a5,$73,$92,$d2,$fe,$36,$64,$12,$ef,$c0,$ab,$43
	dc.b	$35,$7e,$72,$e8,$4e,$80,$bd,$6d,$be,$0b,$bc,$81,$dd,$d6,$45,$34
	dc.b	$60,$e7,$22,$9c,$7b,$41,$87,$00,$cf,$fd,$22,$22,$ba,$4f,$65,$2b
	dc.b	$27,$ce,$db,$e7,$f4,$af,$c7,$9c,$ce,$09,$94,$5d,$5c,$ed,$ff,$a7
	dc.b	$7e,$4c,$ea,$38,$99,$32,$83,$33,$2e,$81,$e9,$d9,$47,$ab,$52,$64
	dc.b	$c4,$da,$17,$a0,$01,$81,$a8,$4a,$40,$56,$ca,$de,$d8,$24,$81,$b2
	dc.b	$ac,$96,$46,$99,$f3,$d5,$c0,$6f,$e3,$0e,$2d,$e6,$6f,$4e,$aa,$e6
	dc.b	$6f,$10,$a8,$2f,$43,$95,$af,$77,$fe,$81,$96,$d0,$dd,$69,$35,$56
	dc.b	$86,$06,$d0,$b8,$69,$16,$72,$19,$35,$d5,$02,$8c,$99,$fb,$8a,$36
	dc.b	$40,$0e,$7c,$a6,$e7,$f4,$69,$81,$37,$c4,$80,$aa,$53,$2d,$ce,$15
	dc.b	$e5,$b3,$53,$b9,$90,$14,$99,$ce,$90,$00,$d9,$83,$0e,$93,$6b,$55
	dc.b	$51,$ea,$40,$02,$2a,$e6,$58,$33,$b6,$05,$28,$fb,$08,$2e,$36,$fa
	dc.b	$20,$4d,$38,$31,$6c,$5a,$9e,$4d,$4f,$1b,$32,$d0,$19,$ae,$25,$2d
	dc.b	$bf,$14,$ce,$e7,$92,$42,$20,$30,$8e,$cd,$bf,$93,$3b,$d9,$b3,$af
	dc.b	$57,$b3,$95,$26,$ea,$ff,$61,$37,$73,$44,$9f,$46,$55,$e1,$71,$10
	dc.b	$0d,$c4,$4e,$84,$e0,$84,$2c,$fc,$10,$98,$ed,$fc,$e0,$21,$04,$f8
	dc.b	$92,$8d,$91,$d6,$10,$4e,$21,$4a,$72,$34,$c3,$25,$7a,$44,$9c,$91
	dc.b	$99,$d9,$99,$c5,$ca,$83,$4c,$a1,$2d,$cc,$00,$bf,$70,$b7,$b8,$2b
	dc.b	$98,$00,$ac,$a8,$6a,$2a,$5b,$e4,$67,$d2,$e0,$d3,$cd,$4a,$3e,$63
	dc.b	$4a,$dc,$81,$1c,$15,$75,$24,$8d,$46,$c5,$e1,$6d,$6d,$85,$17,$f9
	dc.b	$c8,$6a,$8f,$99,$cb,$60,$84,$28,$4a,$0c,$03,$ed,$46,$fe,$0c,$ef
	dc.b	$27,$3e,$74,$de,$4e,$56,$fa,$da,$ff,$21,$1e,$9d,$0a,$42,$59,$1c
	dc.b	$5b,$78,$98,$6e,$43,$0c,$22,$27,$e8,$22,$fd,$93,$55,$9c,$7c,$90
	dc.b	$73,$aa,$fe,$56,$00,$2a,$14,$00,$46,$ba,$5b,$ef,$00,$38,$1a,$61
	dc.b	$3f,$02,$35,$da,$d3,$a9,$4a,$f2,$d9,$92,$68,$e4,$7c,$cf,$d0,$a1
	dc.b	$02,$45,$7c,$fc,$66,$1d,$ac,$16,$25,$57,$df,$20,$67,$38,$21,$a9
	dc.b	$87,$4a,$f4,$8a,$40,$be,$d6,$86,$a8,$1a,$87,$06,$4d,$87,$bb,$c5
	dc.b	$bd,$b6,$45,$cc,$f4,$df,$c0,$98,$1b,$e4,$91,$77,$c9,$11,$cd,$e7
	dc.b	$1d,$ce,$81,$d4,$7e,$c7,$93,$ff,$9c,$7b,$d7,$0b,$f8,$4f,$3f,$f0
	dc.b	$4b,$15,$23,$e7,$bd,$2b,$43,$18,$f1,$d0,$c3,$24,$f4,$10,$1f,$df
	dc.b	$9d,$75,$e5,$01,$e6,$98,$4c,$cc,$1e,$ed,$87,$b5,$b4,$50,$95,$b2
	dc.b	$84,$c5,$05,$ea,$2e,$02,$9a,$64,$fb,$eb,$4b,$9b,$f2,$f2,$e4,$98
	dc.b	$25,$39,$0d,$55,$ff,$95,$90,$35,$94,$84,$16,$ae,$76,$3b,$9d,$04
	dc.b	$07,$69,$7b,$83,$ad,$28,$fb,$b6,$e5,$df,$c0,$6d,$c1,$ab,$be,$64
	dc.b	$39,$0d,$5f,$b4,$31,$cc,$8d,$48,$bf,$f1,$f4,$e2,$ee,$09,$3f,$44
	dc.b	$d5,$85,$da,$2b,$0a,$33,$f1,$b3,$5f,$91,$1f,$82,$44,$db,$5f,$84
	dc.b	$63,$28,$06,$df,$bd,$b6,$d7,$bb,$5a,$18,$b3,$a3,$a1,$86,$0c,$47
	dc.b	$05,$4f,$db,$ab,$5f,$96,$d4,$ea,$7c,$8b,$13,$0f,$2b,$14,$22,$ac
	dc.b	$4c,$0f,$72,$18,$91,$d6,$c4,$c6,$04,$dd,$c1,$f9,$f3,$25,$b6,$81
	dc.b	$c5,$e3,$43,$b6,$a8,$c1,$b9,$28,$90,$98,$d6,$d2,$58,$30,$48,$75
	dc.b	$a5,$0b,$03,$86,$79,$c2,$73,$0c,$24,$56,$69,$e9,$47,$c2,$69,$76
	dc.b	$bd,$0b,$38,$83,$35,$94,$00,$92,$3a,$a8,$77,$63,$c6,$64,$c0,$24
	dc.b	$42,$34,$97,$31,$ef,$e2,$f3,$32,$be,$dd,$31,$eb,$f2,$73,$cd,$93
	dc.b	$9d,$ed,$d9,$26,$1d,$ce,$c7,$b2,$2b,$a8,$d3,$7a,$60,$e2,$26,$bb
	dc.b	$f1,$22,$c3,$66,$45,$d1,$19,$6a,$40,$2e,$66,$44,$52,$d7,$f0,$e5
	dc.b	$7d,$ba,$0a,$26,$c0,$30,$f9,$d0,$c8,$97,$71,$35,$09,$30,$65,$b2
	dc.b	$f4,$a1,$08,$9a,$3a,$d8,$98,$e0,$90,$8c,$22,$2e,$dd,$eb,$ad,$7d
	dc.b	$5a,$8f,$2a,$4a,$fc,$16,$1a,$5c,$d2,$50,$d3,$18,$cb,$ef,$38,$02
	dc.b	$90,$d6,$8b,$b5,$30,$56,$33,$3d,$be,$da,$4f,$98,$c7,$08,$24,$37
	dc.b	$39,$fb,$52,$22,$56,$18,$d0,$44,$56,$65,$86,$35,$19,$9d,$9d,$97
	dc.b	$0e,$cf,$6a,$fc,$4c,$62,$7e,$f2,$55,$e4,$05,$b3,$9f,$f9,$51,$98
	dc.b	$32,$5d,$0e,$06,$e4,$ab,$65,$5c,$aa,$97,$73,$3a,$d9,$8c,$13,$4e
	dc.b	$8f,$49,$27,$9c,$e8,$cc,$1e,$96,$d8,$e0,$ac,$81,$e7,$5b,$2a,$ca
	dc.b	$04,$3b,$bf,$91,$8c,$eb,$66,$33,$78,$85,$c3,$f2,$74,$3b,$a4,$d3
	dc.b	$2a,$65,$74,$ea,$76,$0f,$b6,$43,$34,$61,$4b,$3a,$f3,$bb,$b2,$cd
	dc.b	$f6,$df,$c9,$d4,$12,$bd,$a0,$77,$2e,$67,$4f,$1a,$e9,$22,$59,$af
	dc.b	$42,$48,$fc,$6f,$a1,$e5,$b5,$de,$92,$14,$32,$df,$ab,$fa,$44,$0f
	dc.b	$d1,$fd,$22,$f7,$e7,$7b,$f7,$9c,$6c,$af,$5e,$65,$12,$b7,$9d,$f6
	dc.b	$69,$6a,$4e,$a4,$67,$04,$71,$83,$2c,$b8,$a3,$04,$f7,$f5,$8b,$7b
	dc.b	$5b,$96,$08,$4e,$1a,$6f,$73,$c7,$05,$47,$a7,$e0,$89,$11,$89,$1b
	dc.b	$de,$69,$43,$0d,$6a,$db,$76,$cd,$b8,$c9,$80,$6e,$ad,$3b,$2c,$b3
	dc.b	$0e,$95,$26,$bd,$98,$2b,$3a,$a0,$a5,$a9,$d8,$2d,$ae,$dc,$40,$49
	dc.b	$86,$e3,$68,$72,$ca,$15,$d1,$e4,$02,$68,$1c,$27,$c3,$75,$ff,$23
	dc.b	$3f,$09,$c4,$a2,$7b,$cb,$70,$5d,$35,$f4,$b0,$d1,$ea,$01,$49,$ba
	dc.b	$52,$46,$f6,$8c,$70,$87,$9b,$d9,$84,$08,$bb,$53,$c6,$ae,$94,$20
	dc.b	$4e,$d6,$32,$e1,$71,$01,$22,$ce,$94,$23,$df,$79,$a7,$98,$db,$6e
	dc.b	$99,$44,$4a,$64,$f8,$8e,$18,$67,$6c,$f1,$1f,$69,$41,$e1,$a3,$c8
	dc.b	$c8,$38,$45,$5b,$aa,$0a,$4d,$7d,$6b,$49,$76,$68,$20,$35,$87,$30
	dc.b	$4f,$2c,$60,$56,$62,$c1,$12,$e2,$85,$9c,$73,$a0,$bf,$37,$f1,$0d
	dc.b	$40,$20,$4c,$11,$d4,$a5,$6d,$61,$5a,$ab,$05,$5f,$6e,$99,$40,$23
	dc.b	$49,$8b,$e8,$ef,$a3,$58,$be,$18,$fc,$6b,$00,$d9,$69,$91,$1b,$98
	dc.b	$02,$56,$13,$aa,$14,$63,$5e,$b1,$bf,$6e,$f9,$f1,$8b,$01,$de,$dd
	dc.b	$2d,$2f,$95,$14,$0a,$e9,$95,$4f,$d2,$6d,$fe,$a8,$e6,$3e,$75,$a7
	dc.b	$4b,$75,$05,$43,$d4,$bc,$ae,$55,$30,$ca,$1d,$7e,$90,$bb,$5e,$5b
	dc.b	$42,$fd,$60,$f1,$96,$de,$8c,$41,$9f,$1a,$38,$d2,$c0,$ad,$85,$30
	dc.b	$a6,$c0,$23,$8f,$c8,$7b,$9d,$49,$f1,$27,$9b,$3c,$90,$84,$78,$f5
	dc.b	$21,$f0,$c0,$89,$34,$59,$74,$0b,$5f,$37,$d8,$28,$ad,$24,$84,$6d
	dc.b	$f8,$c3,$44,$54,$a0,$1a,$d1,$ec,$9a,$ba,$5a,$d9,$16,$a0,$1b,$22
	dc.b	$37,$33,$2f,$bc,$22,$86,$23,$02,$d3,$a5,$96,$83,$ad,$90,$60,$94
	dc.b	$7b,$46,$04,$30,$bf,$14,$70,$fe,$04,$63,$0f,$cf,$a6,$58,$bf,$10
	dc.b	$71,$4e,$85,$49,$d6,$ae,$2d,$e6,$01,$7a,$17,$04,$91,$d1,$ca,$39
	dc.b	$4a,$5b,$29,$b6,$3d,$2d,$51,$85,$d0,$bc,$de,$c4,$7f,$bc,$c6,$41
	dc.b	$30,$ec,$17,$03,$e4,$9c,$2b,$86,$ba,$f6,$bf,$38,$de,$69,$19,$5a
	dc.b	$6e,$26,$33,$87,$a1,$e9,$6f,$6f,$1a,$38,$91,$94,$2b,$6d,$16,$e8
	dc.b	$5b,$59,$81,$14,$4a,$72,$3a,$a2,$19,$64,$2e,$12,$10,$8f,$35,$40
	dc.b	$8f,$1e,$3d,$16,$72,$7d,$01,$9f,$9f,$a7,$32,$33,$37,$d8,$ed,$99
	dc.b	$f4,$90,$81,$6b,$78,$e7,$35,$34,$a0,$06,$c1,$1a,$72,$ed,$d2,$8e
	dc.b	$c3,$87,$5b,$b1,$42,$f6,$8a,$2f,$0b,$8b,$96,$4e,$89,$73,$54,$dc
	dc.b	$3c,$37,$82,$73,$ec,$cc,$31,$22,$59,$b1,$b3,$8a,$32,$68,$58,$be
	dc.b	$c3,$9e,$ad,$24,$78,$f1,$07,$4d,$84,$f7,$50,$e8,$4f,$53,$0b,$51
	dc.b	$6e,$b8,$7c,$43,$b1,$5d,$71,$b9,$eb,$9a,$56,$86,$20,$7d,$24,$46
	dc.b	$7a,$21,$99,$f9,$fe,$c9,$f9,$e0,$d8,$76,$f3,$bd,$93,$8b,$f4,$b8
	dc.b	$db,$51,$9b,$ae,$77,$1e,$5d,$e7,$1b,$19,$ad,$ef,$72,$6e,$4f,$63
	dc.b	$47,$17,$5c,$56,$76,$91,$63,$40,$2f,$bd,$20,$d6,$e7,$23,$a3,$55
	dc.b	$9a,$a4,$39,$12,$99,$a0,$a1,$fb,$b1,$52,$59,$3b,$f2,$6b,$67,$11
	dc.b	$f9,$35,$51,$f6,$09,$dc,$55,$74,$d8,$2a,$8c,$69,$a1,$30,$f6,$83
	dc.b	$d5,$84,$43,$3a,$db,$4c,$8c,$5a,$32,$ec,$75,$29,$0e,$ee,$6c,$8e
	dc.b	$6d,$26,$81,$17,$34,$89,$d2,$2f,$f6,$8c,$3d,$14,$d9,$82,$b2,$aa
	dc.b	$1f,$3b,$d0,$58,$03,$c9,$8e,$d4,$84,$66,$d0,$08,$57,$9e,$c8,$9a
	dc.b	$88,$3e,$2f,$c6,$db,$dc,$cd,$c9,$ec,$eb,$62,$d1,$c6,$66,$73,$8a
	dc.b	$0b,$a8,$6e,$bc,$ea,$03,$c6,$8f,$e9,$20,$50,$3a,$68,$fd,$24,$13
	dc.b	$4e,$c2,$ef,$78,$7f,$7b,$7f,$b3,$0e,$24,$7e,$42,$c7,$da,$c4,$c6
	dc.b	$7a,$f9,$e8,$28,$c6,$89,$5d,$30,$27,$f0,$69,$d3,$9f,$87,$6e,$4a
	dc.b	$20,$da,$45,$91,$46,$d8,$1b,$f8,$21,$4b,$9f,$85,$d1,$fd,$c9,$8c
	dc.b	$b5,$3e,$f9,$0e,$ad,$36,$1e,$67,$7f,$4f,$47,$c0,$f0,$25,$a7,$3d
	dc.b	$2a,$44,$c4,$5c,$4c,$45,$ea,$62,$2e,$85,$16,$f8,$08,$95,$a9,$40
	dc.b	$ee,$a8,$70,$2a,$2d,$9b,$d1,$20,$0e,$bd,$aa,$b0,$9d,$04,$4a,$a9
	dc.b	$44,$9f,$83,$e7,$5b,$d1,$8c,$df,$e8,$9f,$4c,$3b,$51,$9d,$00,$f1
	dc.b	$ad,$d1,$8c,$30,$59,$1e,$9a,$bb,$03,$89,$1f,$d5,$bd,$39,$3e,$c8
	dc.b	$5e,$e2,$8c,$87,$a0,$74,$86,$e9,$54,$ab,$72,$4e,$68,$5c,$f1,$47
	dc.b	$34,$83,$bb,$50,$7e,$24,$bd,$82,$04,$8b,$b6,$98,$96,$6b,$75,$2d
	dc.b	$e9,$6a,$b7,$d2,$52,$fc,$df,$69,$18,$b8,$cf,$46,$b8,$b8,$de,$2e
	dc.b	$34,$4a,$66,$70,$65,$54,$52,$c6,$50,$90,$e7,$4e,$59,$00,$8c,$33
	dc.b	$6f,$80,$7d,$bd,$79,$66,$04,$57,$e5,$51,$93,$75,$d5,$d6,$a7,$d4
	dc.b	$7b,$23,$3b,$9b,$06,$62,$63,$72,$23,$14,$06,$58,$8f,$c1,$99,$df
	dc.b	$bc,$85,$82,$14,$b2,$e4,$da,$a4,$c6,$3f,$2e,$1f,$33,$f0,$93,$59
	dc.b	$63,$c0,$4a,$8d,$31,$f9,$d2,$45,$7b,$04,$7a,$ae,$ca,$00,$11,$ff
	dc.b	$ee,$03,$ae,$a6,$ba,$a9,$a6,$07,$45,$b3,$61,$b5,$83,$33,$87,$71
	dc.b	$a8,$50,$22,$36,$2c,$f7,$12,$43,$ed,$d4,$15,$8a,$5f,$9f,$48,$61
	dc.b	$f8,$bf,$4d,$fb,$61,$3f,$8a,$fb,$b1,$c3,$20,$c3,$bf,$82,$bf,$0e
	dc.b	$e4,$d4,$15,$5a,$a2,$77,$9f,$4d,$cd,$ef,$db,$7e,$be,$95,$ba,$3a
	dc.b	$33,$7e,$27,$5f,$8d,$c7,$0e,$f8,$89,$63,$97,$fd,$e6,$70,$41,$22
	dc.b	$68,$be,$f3,$7c,$76,$d0,$5f,$55,$6b,$b9,$01,$99,$48,$8a,$07,$1d
	dc.b	$4b,$b6,$c1,$1f,$3c,$33,$26,$e5,$68,$75,$f9,$5b,$0d,$0a,$4c,$18
	dc.b	$8b,$23,$08,$c7,$72,$35,$03,$cc,$9a,$81,$16,$a8,$9c,$50,$ce,$b8
	dc.b	$ef,$3f,$0d,$59,$52,$64,$58,$92,$07,$1d,$c9,$de,$f6,$33,$f0,$8c
	dc.b	$c7,$2f,$b7,$c4,$71,$87,$e2,$f1,$26,$94,$ab,$4c,$a9,$f6,$df,$15
	dc.b	$53,$a9,$06,$25,$13,$9f,$f6,$b1,$02,$4a,$f2,$cb,$d4,$15,$54,$c9
	dc.b	$9b,$cf,$a6,$e9,$c3,$4a,$7c,$e2,$b5,$da,$96,$65,$49,$25,$19,$13
	dc.b	$bb,$ca,$76,$fd,$2c,$10,$af,$ca,$e4,$df,$83,$49,$83,$31,$18,$1f
	dc.b	$39,$9c,$da,$0b,$f9,$c6,$e3,$91,$3e,$9c,$8b,$4e,$70,$41,$75,$17
	dc.b	$de,$90,$3a,$a9,$a6,$c7,$4a,$9f,$55,$76,$fe,$9f,$e3,$72,$fc,$4a
	dc.b	$b0,$b8,$0e,$b6,$56,$62,$b9,$88,$82,$c1,$76,$2b,$cf,$9c,$92,$93
	dc.b	$72,$89,$90,$a4,$ad,$86,$35,$47,$db,$4a,$a9,$3a,$42,$83,$28,$73
	dc.b	$1f,$da,$2d,$96,$fb,$55,$50,$22,$a6,$4c,$c5,$0d,$a6,$4d,$54,$d3
	dc.b	$4d,$a5,$34,$c5,$14,$da,$85,$18,$c3,$5a,$18,$cf,$5d,$91,$38,$f9
	dc.b	$af,$cd,$30,$47,$d4,$61,$df,$f8,$f6,$49,$e8,$74,$ab,$b7,$e7,$46
	dc.b	$09,$f1,$b8,$9b,$30,$44,$23,$7e,$06,$c2,$f2,$e5,$8f,$87,$6a,$b2
	dc.b	$a8,$ab,$9e,$5e,$34,$c1,$d1,$6c,$21,$7d,$4b,$bf,$0f,$b6,$64,$b2
	dc.b	$3e,$40,$b8,$d1,$c5,$ef,$39,$8c,$dd,$08,$05,$e6,$65,$80,$1b,$99
	dc.b	$e1,$20,$d1,$2c,$f5,$9e,$09,$09,$e1,$0f,$75,$05,$59,$56,$ca,$a3
	dc.b	$27,$0e,$b8,$69,$04,$d7,$4a,$8a,$55,$a6,$ef,$4f,$61,$4c,$11,$d5
	dc.b	$28,$4d,$c6,$d5,$1e,$87,$91,$f2,$a1,$a9,$3e,$6a,$7c,$51,$cb,$03
	dc.b	$73,$82,$aa,$91,$92,$a1,$6e,$4d,$d4,$c4,$29,$26,$02,$89,$18,$a5
	dc.b	$88,$0b,$ee,$a9,$14,$d6,$d4,$14,$c9,$97,$28,$a1,$99,$55,$05,$55
	dc.b	$51,$8f,$18,$9a,$34,$58,$2a,$81,$aa,$28,$5a,$91,$97,$9f,$a7,$d2
	dc.b	$31,$f8,$3c,$df,$72,$a4,$9c,$3a,$a6,$a3,$42,$8a,$f1,$bc,$e4,$48
	dc.b	$2e,$bf,$f9,$d8,$7d,$e5,$56,$0e,$08,$53,$e2,$fe,$45,$27,$b9,$7c
	dc.b	$b9,$26,$bb,$4c,$b8,$fa,$75,$b5,$57,$30,$ec,$68,$e2,$c7,$86,$10
	dc.b	$db,$21,$70,$62,$2e,$d5,$e1,$26,$a5,$63,$89,$e1,$2e,$3c,$10,$af
	dc.b	$50,$7d,$83,$55,$c2,$6f,$ec,$aa,$0a,$39,$79,$60,$64,$9a,$e1,$b4
	dc.b	$38,$3d,$48,$34,$a4,$fd,$d2,$25,$dc,$fc,$cc,$ff,$88,$aa,$80,$9a
	dc.b	$3f,$3e,$7e,$b8,$92,$b4,$85,$26,$ea,$e6,$25,$5a,$d0,$b7,$4e,$da
	dc.b	$71,$1d,$40,$62,$5a,$3a,$18,$17,$cc,$52,$1a,$c2,$ea,$0a,$60,$cd
	dc.b	$fc,$14,$45,$76,$aa,$2c,$ea,$03,$4a,$4c,$24,$57,$47,$82,$11,$28
	dc.b	$37,$4a,$88,$d3,$0e,$ce,$e9,$3e,$67,$2c,$30,$0a,$ed,$3d,$75,$39
	dc.b	$43,$9e,$87,$b7,$b9,$ee,$94,$a3,$a6,$14,$5f,$fe,$76,$60,$7e,$44
	dc.b	$c7,$4a,$2f,$7c,$5d,$ad,$17,$7f,$5e,$8b,$f7,$c6,$7c,$73,$7d,$fa
	dc.b	$22,$e9,$d4,$a6,$b2,$71,$a0,$77,$b6,$f6,$c8,$bd,$64,$51,$59,$ac
	dc.b	$0a,$54,$cf,$06,$94,$fc,$0c,$0c,$e6,$8c,$8a,$0f,$33,$e0,$36,$73
	dc.b	$28,$bb,$96,$87,$47,$fa,$71,$d1,$65,$8d,$74,$b8,$85,$be,$d1,$74
	dc.b	$97,$71,$32,$ed,$95,$59,$cb,$12,$69,$c6,$08,$fa,$a7,$59,$26,$74
	dc.b	$3d,$ec,$12,$10,$2c,$89,$15,$07,$f4,$f6,$97,$3c,$fe,$05,$20,$6a
	dc.b	$0a,$58,$e7,$78,$29,$a5,$d8,$34,$d3,$38,$b7,$49,$a2,$fd,$fa,$5c
	dc.b	$10,$4a,$76,$ca,$67,$bf,$3b,$c9,$ba,$f4,$05,$80,$a5,$0b,$dd,$69
	dc.b	$56,$61,$76,$a7,$72,$b1,$74,$c3,$63,$73,$c2,$5a,$68,$d9,$e1,$32
	dc.b	$1e,$22,$6d,$68,$2b,$e8,$7e,$5c,$41,$e8,$49,$77,$39,$2f,$09,$13
	dc.b	$3c,$d7,$0f,$19,$93,$d9,$af,$b7,$31,$a0,$d5,$66,$f0,$19,$aa,$49
	dc.b	$61,$87,$30,$56,$5a,$1a,$62,$af,$99,$0a,$39,$14,$a0,$47,$7d,$9e
	dc.b	$18,$fe,$f1,$71,$07,$8e,$a1,$b9,$f0,$e8,$34,$fe,$32,$81,$74,$51
	dc.b	$c4,$33,$35,$9e,$74,$a0,$99,$bf,$18,$a9,$98,$49,$59,$76,$97,$36
	dc.b	$90,$95,$d0,$c5,$a6,$cd,$57,$3b,$5e,$74,$c0,$3a,$a8,$50,$f0,$81
	dc.b	$09,$00,$d4,$e0,$81,$3a,$eb,$45,$d2,$c5,$d2,$a6,$34,$fd,$e2,$e9
	dc.b	$cb,$dc,$4b,$0b,$e1,$1c,$92,$05,$a2,$bb,$bc,$5c,$d1,$05,$20,$54
	dc.b	$20,$02,$a3,$dc,$2a,$63,$ae,$5b,$b5,$9e,$72,$74,$b6,$4e,$3b,$bf
	dc.b	$ca,$df,$2b,$9c,$c4,$86,$e5,$e8,$3b,$d6,$92,$b9,$77,$98,$5f,$2a
	dc.b	$e0,$f1,$96,$15,$7d,$95,$12,$d0,$16,$44,$5a,$b8,$58,$1d,$34,$ef
	dc.b	$c4,$8a,$12,$4b,$43,$48,$61,$f8,$1c,$1d,$aa,$f2,$b0,$c7,$f7,$aa
	dc.b	$0e,$91,$6d,$95,$8b,$c3,$8b,$e0,$79,$55,$22,$00,$bb,$bc,$e0,$3e
	dc.b	$d1,$cf,$2d,$0a,$b7,$a5,$0a,$35,$61,$81,$36,$3c,$f2,$42,$da,$f3
	dc.b	$93,$37,$46,$ab,$da,$2b,$1e,$e2,$94,$74,$80,$4a,$a0,$41,$cc,$40
	dc.b	$22,$33,$98,$13,$22,$de,$94,$1a,$8b,$bb,$ba,$1d,$34,$d0,$22,$54
	dc.b	$10,$df,$0b,$08,$51,$7f,$ba,$35,$ee,$32,$08,$0a,$fa,$55,$7b,$cd
	dc.b	$6e,$03,$73,$57,$b9,$a6,$bd,$e4,$75,$3b,$1a,$70,$ad,$eb,$c6,$44
	dc.b	$91,$05,$0e,$a7,$6e,$65,$51,$63,$32,$d0,$17,$8d,$78,$cd,$1f,$5e
	dc.b	$47,$fd,$53,$f1,$36,$e2,$6e,$34,$91,$6b,$de,$4b,$46,$6c,$62,$7a
	dc.b	$d5,$01,$a6,$9c,$e8,$f6,$05,$1c,$1a,$5e,$52,$2d,$c8,$c8,$55,$58
	dc.b	$99,$48,$30,$d6,$b8,$1a,$3e,$9a,$52,$4a,$ea,$9b,$32,$66,$d8,$88
	dc.b	$f3,$a8,$75,$00,$21,$5f,$6d,$41,$56,$09,$c3,$4d,$88,$c9,$d0,$fc
	dc.b	$43,$a0,$7a,$80,$a6,$b6,$c4,$45,$5d,$88,$c8,$56,$04,$09,$29,$43
	dc.b	$e6,$3b,$60,$36,$53,$34,$f7,$21,$4f,$cc,$03,$64,$2d,$c3,$e1,$dd
	dc.b	$5f,$98,$5a,$f7,$7f,$16,$23,$72,$58,$9b,$9f,$9e,$08,$82,$87,$d3
	dc.b	$b7,$32,$a8,$b5,$d2,$d0,$6e,$0f,$c6,$34,$70,$1a,$65,$ae,$5d,$06
	dc.b	$01,$e0,$89,$64,$74,$aa,$85,$e8,$68,$26,$ea,$48,$11,$5c,$2f,$60
	dc.b	$4b,$71,$1b,$e1,$d4,$33,$63,$04,$75,$52,$48,$a4,$5f,$2e,$d4,$70
	dc.b	$64,$ba,$84,$88,$f8,$8a,$08,$55,$92,$50,$63,$51,$41,$17,$8b,$c1
	dc.b	$f8,$c9,$38,$22,$04,$66,$47,$98,$b7,$c4,$66,$73,$a9,$bf,$0a,$6b
	dc.b	$7e,$31,$b7,$30,$12,$d6,$2c,$49,$c3,$a0,$ce,$85,$32,$ad,$b7,$e0
	dc.b	$c0,$49,$e6,$74,$55,$56,$b4,$3d,$9a,$82,$16,$76,$79,$60,$92,$f0
	dc.b	$07,$6e,$1a,$5a,$a0,$0d,$f2,$b0,$63,$25,$5b,$e1,$92,$0f,$42,$ce
	dc.b	$39,$2b,$69,$dc,$30,$88,$65,$0e,$de,$6f,$86,$13,$8f,$e6,$18,$29
	dc.b	$12,$b6,$61,$be,$96,$b0,$fc,$fa,$5d,$ba,$91,$10,$d3,$b8,$21,$90
	dc.b	$bf,$55,$01,$d7,$a1,$89,$66,$ff,$de,$fc,$e8,$74,$a0,$24,$e0,$93
	dc.b	$14,$16,$62,$65,$07,$de,$dd,$58,$6c,$81,$b5,$44,$e0,$b6,$f7,$6b
	dc.b	$5d,$32,$2b,$e7,$53,$7d,$b0,$c1,$0b,$3a,$20,$e3,$2f,$02,$cc,$c1
	dc.b	$87,$81,$42,$ac,$de,$5d,$46,$e9,$56,$3d,$50,$e9,$89,$42,$8c,$31
	dc.b	$52,$50,$a1,$f3,$45,$0c,$32,$74,$c3,$aa,$18,$51,$4a,$bd,$02,$cb
	dc.b	$57,$f2,$45,$65,$b7,$d9,$b9,$26,$7c,$df,$9f,$7c,$02,$98,$58,$de
	dc.b	$64,$2a,$37,$a0,$ab,$fd,$6b,$cf,$19,$5a,$10,$52,$32,$c5,$d3,$a0
	dc.b	$05,$af,$fe,$12,$5d,$07,$f0,$22,$c1,$76,$cc,$b7,$bf,$ce,$0d,$8d
	dc.b	$0c,$52,$75,$41,$ab,$bd,$50,$d4,$07,$ee,$86,$24,$87,$36,$24,$4d
	dc.b	$5d,$c0,$d4,$29,$19,$27,$c0,$35,$c3,$ed,$f1,$1c,$c1,$fe,$1f,$87
	dc.b	$57,$a5,$69,$81,$d1,$c0,$94,$f0,$4b,$9d,$ce,$0d,$a8,$4a,$45,$0d
	dc.b	$58,$21,$66,$ea,$00,$d0,$b6,$f8,$84,$e9,$16,$70,$d5,$05,$56,$49
	dc.b	$54,$14,$d9,$c3,$6f,$c9,$11,$48,$86,$50,$52,$56,$53,$24,$1a,$85
	dc.b	$93,$50,$06,$03,$bb,$85,$d7,$c0,$45,$5e,$dc,$33,$f8,$d2,$c0,$ce
	dc.b	$7f,$f3,$ad,$78,$cf,$df,$8c,$2a,$d5,$c6,$3d,$f0,$18,$07,$a6,$20
	dc.b	$75,$eb,$0a,$54,$8a,$62,$8d,$24,$3b,$c6,$5c,$8e,$18,$78,$61,$18
	dc.b	$ff,$91,$01,$86,$11,$96,$db,$86,$32,$72,$3e,$4a,$d9,$91,$9e,$ac
	dc.b	$c2,$25,$ed,$d6,$95,$82,$54,$08,$89,$d3,$18,$d2,$7a,$d9,$ee,$d5
	dc.b	$06,$5b,$42,$43,$47,$04,$f5,$02,$40,$46,$ab,$56,$7d,$56,$d8,$bc
	dc.b	$66,$f5,$82,$9e,$88,$ae,$0c,$bb,$e3,$8c,$5e,$2c,$c4,$24,$d7,$22
	dc.b	$2a,$81,$00,$66,$36,$f8,$ab,$62,$42,$5c,$bd,$11,$1b,$b2,$77,$c4
	dc.b	$57,$c6,$69,$2e,$04,$42,$e3,$f0,$e1,$aa,$51,$4e,$64,$a8,$59,$b5
	dc.b	$c6,$ac,$9e,$d5,$a3,$15,$8c,$9c,$e0,$aa,$0d,$23,$7e,$54,$21,$7b
	dc.b	$55,$9b,$83,$f2,$94,$0e,$a9,$5d,$8e,$bc,$5a,$ef,$55,$47,$5f,$fa
	dc.b	$7b,$23,$19,$65,$82,$a0,$43,$36,$02,$11,$70,$c2,$29,$d6,$05,$45
	dc.b	$94,$93,$53,$b3,$dd,$40,$16,$d4,$5c,$8c,$3b,$a5,$d2,$d4,$67,$7b
	dc.b	$74,$24,$08,$58,$a4,$23,$f2,$11,$37,$1a,$b7,$0d,$25,$7e,$49,$87
	dc.b	$30,$f3,$34,$27,$ae,$04,$8f,$59,$47,$e4,$d4,$db,$5d,$66,$2b,$f8
	dc.b	$f1,$ce,$03,$e0,$0d,$56,$c3,$bf,$1b,$ec,$b5,$b8,$10,$90,$db,$04
	dc.b	$7d,$15,$b4,$3e,$69,$e2,$16,$d7,$40,$0f,$f5,$34,$21,$a7,$6c,$57
	dc.b	$f0,$56,$3f,$2a,$e0,$5f,$24,$8e,$e9,$28,$f4,$22,$59,$b2,$69,$35
	dc.b	$b5,$48,$e6,$99,$16,$7a,$29,$9f,$26,$d0,$0c,$94,$b4,$5d,$2d,$69
	dc.b	$5c,$a3,$4a,$0d,$7a,$93,$89,$9e,$69,$5f,$c3,$a1,$14,$4e,$4d,$ea
	dc.b	$db,$74,$04,$da,$be,$24,$75,$0c,$b8,$ab,$cc,$af,$48,$de,$d9,$13
	dc.b	$e5,$66,$22,$05,$79,$78,$a9,$1f,$ac,$e9,$1c,$8f,$53,$81,$e9,$c8
	dc.b	$7a,$d2,$52,$6c,$dd,$16,$d8,$12,$6c,$4b,$38,$e3,$a8,$31,$6b,$4f
	dc.b	$81,$23,$9f,$5a,$a8,$44,$fb,$68,$1f,$9e,$4a,$1a,$5f,$82,$03,$5a
	dc.b	$7c,$13,$40,$d4,$7f,$c1,$2e,$52,$2f,$81,$1c,$11,$f0,$ae,$00,$cc
	dc.b	$bc,$a8,$06,$17,$69,$0b,$28,$f6,$e9,$de,$f9,$04,$62,$cf,$ed,$a4
	dc.b	$c5,$02,$75,$14,$d2,$22,$da,$3f,$8c,$9a,$7d,$07,$5a,$b5,$5e,$3d
	dc.b	$8e,$a6,$63,$88,$f2,$ea,$46,$6e,$8a,$26,$ff,$4f,$d9,$97,$2c,$c1
	dc.b	$01,$62,$90,$8a,$f7,$ea,$90,$b8,$df,$a6,$3a,$1a,$3c,$d7,$de,$37
	dc.b	$b2,$10,$c4,$db,$1e,$be,$90,$0d,$c4,$5b,$3e,$f4,$9a,$b6,$bd,$9b
	dc.b	$9d,$a9,$5e,$56,$6f,$b5,$8f,$9d,$e0,$6d,$9d,$1a,$80,$d0,$4c,$7a
	dc.b	$cc,$28,$04,$4e,$0a,$4c,$2f,$a8,$da,$31,$14,$c2,$93,$32,$7e,$d9
	dc.b	$b9,$01,$bd,$d3,$ab,$5d,$bc,$a5,$9d,$10,$f0,$f4,$1a,$64,$48,$2b
	dc.b	$1b,$e1,$e3,$19,$12,$10,$eb,$36,$f2,$cb,$af,$e2,$dd,$e9,$8e,$c6
	dc.b	$86,$fb,$e4,$c0,$29,$c0,$de,$b9,$d4,$b1,$c1,$2a,$8a,$5c,$f6,$90
	dc.b	$0d,$42,$ce,$1c,$a8,$ea,$89,$b1,$b6,$47,$53,$db,$3a,$b0,$13,$d4
	dc.b	$74,$99,$ed,$33,$36,$e3,$c0,$82,$6d,$55,$38,$6f,$dd,$c0,$b6,$ee
	dc.b	$42,$94,$22,$4c,$bb,$5e,$16,$16,$33,$3d,$bc,$65,$ee,$5f,$dd,$e3
	dc.b	$2d,$f0,$c5,$5f,$aa,$ba,$94,$2d,$b3,$1d,$a8,$ec,$33,$db,$b3,$47
	dc.b	$1a,$d2,$e0,$52,$0d,$dd,$f8,$63,$3f,$1a,$a8,$d7,$64,$e2,$34,$f3
	dc.b	$fb,$e5,$91,$b2,$de,$82,$72,$c3,$05,$bf,$ef,$2b,$ff,$ea,$96,$42
	dc.b	$2c,$9b,$c2,$16,$b0,$89,$d0,$b6,$72,$5a,$8d,$16,$23,$55,$3a,$8d
	dc.b	$1e,$a1,$79,$b5,$81,$96,$38,$76,$41,$97,$e2,$60,$52,$49,$ea,$87
	dc.b	$1c,$3d,$c1,$a9,$26,$b3,$a2,$ce,$35,$20,$c6,$ec,$c4,$a1,$0e,$1e
	dc.b	$73,$1a,$17,$06,$83,$27,$6d,$43,$d6,$17,$1a,$95,$bb,$de,$8e,$e9
	dc.b	$ef,$9d,$d9,$72,$14,$f1,$c0,$d5,$b5,$59,$11,$19,$9d,$de,$35,$9f
	dc.b	$fd,$fc,$66,$c4,$38,$5e,$2f,$7e,$db,$1e,$ff,$c4,$5b,$3f,$5c,$fe
	dc.b	$70,$d3,$bb,$e6,$57,$07,$a1,$d5,$09,$09,$03,$79,$ec,$a1,$89,$11
	dc.b	$d2,$2e,$20,$e6,$2f,$39,$be,$65,$1b,$19,$d2,$82,$43,$0a,$68,$99
	dc.b	$ae,$41,$c6,$81,$76,$83,$52,$5e,$15,$dd,$0b,$60,$b4,$2e,$49,$a5
	dc.b	$54,$54,$e7,$50,$d6,$e5,$d6,$b6,$ac,$6f,$ce,$38,$52,$b1,$d4,$22
	dc.b	$35,$39,$ab,$78,$95,$13,$59,$c5,$7c,$d5,$c0,$28,$a6,$f0,$3c,$38
	dc.b	$91,$39,$e7,$42,$e7,$d0,$40,$51,$20,$33,$ac,$58,$1a,$50,$bd,$01
	dc.b	$63,$cc,$e7,$3e,$3b,$90,$a4,$08,$52,$f4,$ee,$7b,$11,$6c,$fd,$7f
	dc.b	$22,$97,$e4,$bc,$34,$5b,$1f,$ca,$b3,$4b,$e7,$b8,$7c,$7c,$45,$b3
	dc.b	$e9,$4f,$89,$91,$68,$1a,$e5,$61,$4f,$c0,$38,$dd,$42,$46,$b8,$5f
	dc.b	$8a,$a1,$89,$30,$08,$8a,$41,$c2,$59,$01,$10,$90,$09,$2d,$1c,$bd
	dc.b	$62,$b5,$72,$6d,$03,$f3,$da,$20,$e1,$42,$48,$44,$a4,$f8,$40,$f2
	dc.b	$81,$15,$82,$3a,$02,$03,$16,$aa,$84,$70,$a9,$c0,$d1,$35,$e5,$96
	dc.b	$00,$9d,$49,$50,$2b,$32,$ef,$29,$6a,$0f,$b2,$78,$06,$82,$94,$24
	dc.b	$06,$e9,$1a,$25,$c4,$e2,$1d,$bc,$93,$c0,$6b,$d1,$2e,$79,$74,$ef
	dc.b	$5a,$7c,$bf,$05,$8f,$cd,$9c,$3a,$75,$ce,$ae,$42,$91,$21,$e2,$7c
	dc.b	$1e,$32,$8b,$62,$7f,$f7,$c5,$67,$d8,$f8,$39,$ef,$77,$94,$69,$12
	dc.b	$fe,$7c,$7c,$3c,$3b,$63,$a6,$45,$ae,$29,$f2,$45,$75,$8b,$82,$f5
	dc.b	$09,$71,$13,$73,$ac,$68,$9c,$41,$07,$38,$d4,$11,$6c,$eb,$be,$28
	dc.b	$3e,$8c,$9f,$50,$8d,$c6,$8d,$35,$db,$fb,$55,$b0,$fe,$1c,$08,$fc
	dc.b	$3a,$0d,$59,$d5,$12,$f2,$06,$24,$4a,$6e,$e9,$bb,$4b,$e7,$2d,$44
	dc.b	$e5,$82,$74,$84,$58,$70,$91,$68,$96,$41,$11,$6a,$40,$8d,$e5,$6d
	dc.b	$42,$c9,$12,$b4,$85,$5e,$57,$d8,$d3,$7a,$9a,$ef,$0c,$fe,$1c,$06
	dc.b	$02,$06,$c2,$db,$b2,$14,$67,$d5,$0a,$6d,$c5,$1e,$fc,$ee,$7e,$35
	dc.b	$be,$92,$bc,$75,$49,$f8,$22,$5f,$f3,$66,$f6,$08,$88,$fc,$be,$1f
	dc.b	$52,$1e,$08,$ae,$30,$13,$df,$f7,$fc,$1d,$87,$fb,$32,$13,$1e,$a8
	dc.b	$68,$cc,$52,$c8,$be,$63,$7c,$4f,$c5,$a1,$af,$86,$b8,$60,$82,$7c
	dc.b	$60,$50,$b1,$81,$09,$dc,$87,$92,$cb,$1d,$47,$f1,$33,$de,$86,$98
	dc.b	$c7,$2c,$cc,$25,$32,$14,$d8,$97,$9c,$4d,$22,$c9,$a7,$b4,$c3,$a3
	dc.b	$1e,$5d,$de,$97,$87,$16,$8a,$5f,$66,$a8,$fd,$12,$e2,$58,$23,$e4
	dc.b	$d8,$0c,$e3,$2b,$ef,$81,$a4,$f4,$76,$27,$66,$c5,$b6,$98,$61,$98
	dc.b	$4b,$f6,$0e,$66,$eb,$db,$6e,$7e,$39,$1c,$7e,$35,$db,$e1,$f7,$a7
	dc.b	$e5,$76,$7c,$d8,$2a,$cc,$fb,$f3,$af,$c1,$01,$f1,$7b,$d2,$7e,$6d
	dc.b	$d0,$2e,$3a,$7f,$dd,$d3,$b0,$b1,$da,$e8,$b2,$f8,$6e,$bf,$c1,$d9
	dc.b	$53,$b7,$f1,$2c,$fa,$a6,$c1,$df,$74,$5b,$c9,$d6,$86,$80,$c6,$ad
	dc.b	$1c,$27,$11,$c2,$32,$c6,$45,$a7,$85,$e5,$fb,$1d,$91,$24,$bf,$a7
	dc.b	$c3,$ea,$a9,$63,$f2,$28,$d5,$8e,$08,$4c,$6b,$77,$99,$f6,$1c,$71
	dc.b	$91,$15,$19,$a6,$f0,$96,$e8,$6b,$2d,$b9,$0f,$00,$a0,$82,$ea,$4c
	dc.b	$94,$15,$4c,$8c,$29,$a0,$4c,$67,$5f,$50,$e3,$c7,$73,$a8,$ab,$d8
	dc.b	$5c,$e6,$54,$4e,$4b,$a0,$47,$f1,$0c,$5a,$f8,$7f,$0f,$77,$75,$ae
	dc.b	$bd,$04,$f9,$09,$14,$f7,$cf,$a3,$e5,$7c,$8b,$29,$e3,$57,$e0,$b2
	dc.b	$32,$29,$ff,$61,$2f,$90,$cd,$55,$22,$d3,$b1,$f2,$5e,$c3,$bb,$fa
	dc.b	$f4,$65,$e4,$b7,$26,$cc,$36,$36,$c1,$30,$84,$a8,$d8,$58,$70,$99
	dc.b	$31,$3a,$b4,$35,$c4,$66,$86,$10,$4f,$c1,$01,$78,$f8,$60,$89,$73
	dc.b	$b2,$be,$95,$4f,$d4,$21,$ee,$d7,$78,$e5,$14,$16,$2e,$12,$2a,$3d
	dc.b	$58,$cf,$2e,$a4,$c7,$e0,$b3,$d4,$38,$b6,$c1,$f0,$8d,$e7,$a1,$86
	dc.b	$d8,$81,$00,$43,$15,$80,$2a,$32,$26,$dc,$d0,$2e,$1d,$f0,$47,$d7
	dc.b	$b9,$e0,$97,$74,$55,$ce,$63,$27,$95,$9b,$47,$8f,$a0,$c6,$08,$63
	dc.b	$08,$c0,$04,$ab,$9d,$9b,$06,$33,$e0,$2b,$af,$7c,$79,$ea,$cc,$4a
	dc.b	$a9,$50,$08,$bc,$1a,$bd,$a8,$d9,$00,$5b,$0f,$fe,$4f,$24,$d2,$97
	dc.b	$c7,$d1,$a5,$1e,$4d,$60,$15,$2f,$db,$2d,$be,$07,$f1,$fc,$45,$e8
	dc.b	$c9,$84,$e9,$a3,$46,$8d,$7d,$ae,$6b,$e3,$02,$99,$8c,$09,$4f,$b6
	dc.b	$d5,$6d,$bd,$6a,$89,$a3,$11,$3b,$ac,$21,$18,$e2,$6d,$fd,$c4,$3b
	dc.b	$fb,$cb,$6d,$b3,$67,$e5,$1c,$37,$28,$78,$70,$81,$9a,$e0,$32,$df
	dc.b	$16,$fe,$34,$fa,$f2,$46,$10,$2a,$5d,$c0,$69,$ed,$b8,$ae,$a3,$a8
	dc.b	$77,$b0,$34,$5e,$e8,$31,$28,$01,$26,$af,$04,$72,$cb,$eb,$9f,$55
	dc.b	$c2,$4b,$b3,$73,$b6,$d5,$9d,$d7,$3a,$a5,$ce,$47,$f3,$b0,$42,$5d
	dc.b	$9e,$48,$e9,$b5,$3c,$93,$4a,$5d,$28,$a6,$b1,$82,$d6,$ec,$33,$52
	dc.b	$2a,$2b,$69,$13,$01,$bd,$22,$38,$a0,$24,$86,$ca,$8d,$54,$87,$f1
	dc.b	$97,$4d,$f0,$41,$1d,$9f,$8a,$09,$4f,$85,$59,$1e,$a6,$82,$5c,$8e
	dc.b	$f4,$b5,$38,$a6,$c4,$79,$75,$06,$bb,$7c,$bc,$1f,$29,$b4,$7b,$59
	dc.b	$f5,$67,$e5,$25,$19,$37,$86,$1a,$23,$32,$84,$f7,$ac,$97,$10,$8a
	dc.b	$f4,$a8,$41,$2e,$03,$c1,$0a,$a2,$7f,$68,$1a,$78,$8a,$da,$3b,$4b
	dc.b	$dc,$9e,$58,$2a,$78,$7d,$52,$0d,$23,$01,$11,$45,$15,$90,$b9,$b6
	dc.b	$a8,$06,$e9,$b2,$ee,$bb,$74,$e3,$f1,$80,$21,$54,$9f,$9b,$04,$35
	dc.b	$d8,$32,$47,$03,$d8,$10,$3e,$ca,$50,$2f,$a3,$ae,$ac,$29,$7c,$8f
	dc.b	$96,$33,$48,$92,$98,$62,$61,$0f,$da,$22,$12,$05,$2e,$8e,$5b,$b2
	dc.b	$9c,$10,$47,$b8,$df,$80,$db,$b0,$d7,$43,$af,$fa,$14,$bb,$5a,$b3
	dc.b	$c1,$9b,$71,$93,$4c,$8c,$46,$1e,$57,$d3,$7f,$38,$e1,$28,$0d,$30
	dc.b	$9a,$f5,$9c,$11,$91,$e1,$72,$06,$91,$44,$22,$14,$fd,$71,$56,$08
	dc.b	$55,$d5,$f1,$f8,$0e,$7b,$2a,$18,$6f,$2d,$ad,$44,$35,$ad,$6b,$bf
	dc.b	$9f,$94,$6c,$66,$55,$35,$94,$16,$53,$3a,$f4,$b8,$d5,$f6,$42,$db
	dc.b	$7a,$d0,$df,$39,$a4,$ae,$c2,$d2,$81,$9a,$63,$c8,$cf,$47,$9a,$df
	dc.b	$a0,$56,$7f,$a0,$95,$22,$a7,$1f,$e8,$33,$52,$46,$34,$72,$5a,$09
	dc.b	$61,$f8,$d6,$88,$a0,$80,$46,$da,$23,$42,$57,$71,$02,$76,$c5,$f8
	dc.b	$ae,$35,$69,$64,$7c,$9b,$75,$3d,$bb,$27,$88,$19,$13,$94,$d6,$e0
	dc.b	$6e,$58,$92,$bc,$e2,$15,$9c,$a9,$25,$26,$90,$20,$c2,$37,$20,$62
	dc.b	$2d,$6d,$80,$f1,$88,$0f,$f1,$88,$0f,$ef,$f8,$ae,$17,$79,$34,$a3
	dc.b	$6e,$8f,$49,$a5,$59,$a3,$e3,$32,$7d,$46,$d5,$a5,$c2,$ae,$bd,$01
	dc.b	$78,$9e,$fe,$21,$92,$c5,$82,$89,$ce,$c2,$c4,$a7,$20,$89,$88,$92
	dc.b	$dd,$bc,$f3,$30,$90,$60,$ba,$3c,$59,$fc,$c2,$54,$f3,$95,$b7,$5e
	dc.b	$76,$2b,$aa,$62,$94,$8c,$68,$e4,$0a,$28,$7c,$61,$c0,$7f,$60,$44
	dc.b	$c1,$2a,$43,$05,$06,$77,$e8,$f1,$ab,$49,$5e,$a0,$3a,$9e,$c2,$c6
	dc.b	$a7,$50,$ce,$51,$b9,$e4,$58,$da,$38,$bb,$66,$40,$d2,$c0,$d6,$2a
	dc.b	$84,$52,$1d,$6c,$80,$e0,$29,$42,$1f,$b8,$b1,$65,$d7,$a5,$4f,$d5
	dc.b	$83,$04,$8d,$04,$2a,$a9,$e5,$fa,$3c,$2e,$eb,$f8,$80,$e8,$f5,$29
	dc.b	$57,$1f,$87,$85,$75,$46,$82,$9a,$f0,$50,$27,$6f,$59,$06,$92,$75
	dc.b	$1f,$ae,$5b,$52,$1d,$67,$81,$1c,$2b,$1a,$de,$65,$39,$7e,$ca,$5d
	dc.b	$55,$36,$8b,$65,$2d,$19,$da,$f1,$b7,$24,$ec,$e0,$b2,$6b,$29,$a9
	dc.b	$50,$08,$53,$84,$45,$0d,$1c,$72,$d0,$a6,$40,$dc,$1f,$81,$93,$a8
	dc.b	$4d,$69,$f8,$55,$4d,$39,$6b,$7f,$a0,$cd,$af,$a0,$2a,$ea,$e5,$d8
	dc.b	$bd,$9f,$9d,$0a,$68,$34,$5a,$0d,$64,$74,$50,$2e,$c2,$1a,$f8,$cd
	dc.b	$b2,$b3,$ab,$6b,$23,$3e,$c3,$ae,$76,$fc,$db,$c5,$22,$a9,$af,$9e
	dc.b	$94,$29,$d2,$8b,$53,$f7,$49,$34,$14,$60,$1c,$95,$f5,$f8,$56,$5d
	dc.b	$78,$01,$9b,$b7,$9f,$0c,$05,$23,$48,$b9,$6e,$19,$bf,$81,$0d,$72
	dc.b	$08,$c9,$73,$d1,$e6,$21,$dd,$c8,$8f,$d8,$f4,$cf,$f8,$d2,$d5,$d5
	dc.b	$82,$e1,$e4,$32,$cd,$5e,$7c,$40,$40,$d8,$c3,$4c,$28,$34,$16,$08
	dc.b	$b0,$4a,$a9,$10,$dc,$73,$20,$61,$92,$3f,$75,$96,$3d,$2e,$f6,$3d
	dc.b	$17,$60,$d5,$f0,$60,$84,$80,$bb,$8a,$f7,$52,$a0,$d2,$16,$ab,$41
	dc.b	$a9,$50,$38,$86,$5c,$d0,$dd,$9a,$94,$80,$d5,$6a,$29,$3e,$d5,$5d
	dc.b	$b1,$e9,$51,$3f,$f8,$91,$49,$55,$05,$56,$1b,$f8,$37,$59,$93,$4c
	dc.b	$ff,$a7,$9f,$87,$06,$ac,$df,$af,$87,$80,$7f,$5c,$95,$dd,$1e,$7c
	dc.b	$0b,$c0,$21,$0c,$9e,$36,$b1,$b1,$f7,$80,$35,$c1,$0c,$ca,$ac,$d2
	dc.b	$66,$41,$79,$f6,$29,$77,$5a,$ac,$f6,$37,$72,$29,$3d,$8f,$2e,$bd
	dc.b	$59,$01,$a5,$56,$2c,$6d,$fb,$22,$2e,$a0,$2f,$5c,$82,$32,$93,$80
	dc.b	$c5,$35,$bf,$13,$26,$b7,$7f,$88,$9d,$69,$bd,$ad,$3c,$44,$56,$51
	dc.b	$25,$5e,$df,$86,$f5,$54,$18,$96,$37,$ad,$23,$f7,$f2,$4f,$39,$5c
	dc.b	$86,$a8,$30,$a4,$19,$e7,$da,$41,$71,$91,$36,$69,$93,$be,$44,$bb
	dc.b	$ed,$12,$a2,$ac,$f7,$8f,$17,$bb,$26,$f9,$d9,$0f,$05,$e8,$fb,$d8
	dc.b	$f7,$f1,$af,$48,$6b,$20,$24,$67,$83,$55,$17,$ba,$bc,$6d,$df,$63
	dc.b	$18,$a4,$64,$ee,$a7,$52,$67,$0f,$b8,$25,$80,$6f,$8f,$70,$87,$b6
	dc.b	$77,$07,$ac,$e6,$35,$22,$ea,$f4,$b7,$65,$f1,$a1,$3e,$cc,$73,$94
	dc.b	$9f,$1a,$60,$da,$d9,$01,$38,$cd,$3f,$2b,$a8,$76,$e1,$b6,$99,$6a
	dc.b	$db,$0b,$bb,$e8,$2f,$80,$4d,$c6,$c2,$f2,$e0,$02,$a4,$6e,$b4,$1a
	dc.b	$c8,$a1,$91,$0f,$5c,$5e,$c9,$06,$7e,$1a,$89,$00,$4b,$00,$95,$69
	dc.b	$4e,$b2,$56,$b0,$f5,$d5,$ce,$6c,$a1,$9c,$36,$07,$b0,$36,$db,$62
	dc.b	$d2,$e0,$f5,$fe,$dc,$ac,$d2,$f3,$fa,$10,$b6,$89,$2b,$e3,$53,$4b
	dc.b	$17,$46,$4a,$06,$62,$6e,$23,$50,$b7,$5e,$09,$95,$3f,$5b,$3c,$b0
	dc.b	$cf,$79,$22,$bc,$ce,$f7,$4b,$0b,$e3,$b9,$c6,$93,$70,$58,$3b,$69
	dc.b	$2d,$eb,$40,$dc,$82,$6d,$1f,$c5,$6b,$50,$03,$02,$c3,$4d,$31,$fa
	dc.b	$fe,$4c,$9a,$a1,$a3,$13,$3e,$ee,$8a,$e1,$e7,$f7,$e2,$fb,$9b,$81
	dc.b	$86,$7d,$ca,$b5,$06,$ba,$c2,$4b,$00,$14,$a6,$95,$13,$98,$87,$a0
	dc.b	$1b,$32,$a1,$4b,$04,$22,$58,$fe,$c4,$45,$27,$f7,$9e,$5a,$c3,$d4
	dc.b	$d6,$17,$2a,$3f,$b2,$7f,$76,$66,$d2,$f6,$fc,$10,$6b,$a4,$31,$0f
	dc.b	$55,$d1,$2f,$63,$0a,$49,$3a,$f4,$ad,$1c,$58,$50,$9b,$37,$ad,$ea
	dc.b	$c9,$78,$61,$9e,$04,$53,$85,$e1,$86,$96,$6a,$14,$85,$fa,$19,$35
	dc.b	$1b,$97,$24,$2f,$bd,$6d,$d6,$bc,$da,$ba,$fc,$f7,$73,$b4,$5b,$9d
	dc.b	$83,$ce,$34,$1a,$cc,$0f,$6e,$02,$6e,$90,$64,$ae,$50,$2c,$31,$8f
	dc.b	$f7,$14,$e6,$6e,$b0,$35,$eb,$e9,$6a,$b4,$06,$66,$9a,$1c,$fd,$3e
	dc.b	$b5,$41,$4e,$91,$20,$4f,$3e,$6f,$c6,$b0,$c5,$e9,$6c,$44,$b0,$e3
	dc.b	$28,$a2,$8f,$75,$ab,$a6,$1f,$1a,$a6,$7f,$3d,$70,$bd,$76,$1d,$dc
	dc.b	$2a,$74,$48,$75,$58,$76,$e3,$01,$00,$77,$ad,$ed,$95,$87,$ab,$a7
	dc.b	$c1,$40,$69,$a2,$f4,$50,$dd,$2f,$bd,$3f,$02,$1a,$f2,$b7,$26,$dc
	dc.b	$dc,$29,$e8,$c9,$80,$dc,$29,$18,$c7,$41,$45,$e8,$71,$34,$b6,$80
	dc.b	$8c,$a9,$c9,$36,$38,$f4,$d1,$d9,$bb,$0d,$e1,$fd,$d8,$f8,$24,$63
	dc.b	$83,$e6,$42,$0f,$1a,$08,$c5,$91,$1d,$c3,$ec,$dd,$40,$2d,$04,$0f
	dc.b	$9c,$86,$41,$de,$4a,$04,$3f,$58,$29,$b4,$84,$53,$96,$fb,$ed,$a1
	dc.b	$95,$f0,$cd,$e1,$c1,$46,$f8,$5e,$d2,$2e,$a8,$34,$d3,$18,$31,$2e
	dc.b	$bb,$4b,$c6,$01,$95,$27,$68,$56,$d5,$c2,$c7,$57,$4a,$81,$ab,$0e
	dc.b	$18,$51,$f5,$c0,$8c,$b5,$70,$ad,$d6,$18,$79,$3c,$d0,$43,$47,$83
	dc.b	$fa,$1b,$cd,$e7,$f6,$14,$03,$9e,$94,$d3,$45,$eb,$37,$f2,$9f,$90
	dc.b	$62,$29,$95,$96,$ac,$ae,$4f,$85,$65,$cd,$29,$ff,$4e,$79,$fc,$a8
	dc.b	$a2,$54,$19,$6b,$5b,$d2,$77,$4d,$8e,$b1,$6b,$ab,$4b,$9b,$03,$da
	dc.b	$c4,$4c,$8f,$82,$43,$b5,$65,$74,$89,$8d,$16,$e3,$47,$ac,$59,$6e
	dc.b	$dc,$1a,$65,$c1,$90,$b8,$21,$98,$54,$e3,$f8,$9d,$72,$a9,$43,$08
	dc.b	$e2,$02,$d3,$67,$42,$8b,$be,$af,$b5,$14,$87,$e1,$31,$37,$01,$4a
	dc.b	$1d,$88,$87,$25,$ca,$71,$0e,$51,$9b,$b5,$ca,$80,$41,$61,$58,$c5
	dc.b	$19,$8d,$6c,$25,$01,$80,$b8,$87,$6a,$41,$58,$4a,$61,$7a,$54,$11
	dc.b	$87,$62,$cd,$05,$9d,$30,$ee,$ce,$0b,$ba,$46,$8c,$c0,$65,$b0,$cd
	dc.b	$24,$0d,$90,$ee,$9d,$b2,$37,$6e,$82,$38,$94,$fb,$e6,$fa,$a5,$46
	dc.b	$1d,$5c,$31,$7a,$36,$c3,$d5,$7a,$0c,$be,$a1,$f6,$ad,$71,$9f,$41
	dc.b	$24,$37,$d3,$64,$40,$6b,$ef,$6c,$dc,$ef,$c4,$04,$6f,$c1,$09,$15
	dc.b	$5c,$b0,$43,$a6,$e6,$4c,$04,$99,$6c,$af,$7e,$22,$36,$72,$63,$e0
	dc.b	$df,$94,$4b,$8d,$94,$7b,$f5,$0f,$56,$2d,$70,$f0,$7e,$35,$f4,$a4
	dc.b	$d9,$43,$0f,$78,$d8,$88,$9d,$db,$3a,$ca,$91,$b3,$aa,$1c,$6d,$68
	dc.b	$f1,$52,$a2,$c8,$02,$44,$76,$15,$c1,$78,$20,$15,$e5,$0a,$69,$64
	dc.b	$10,$bf,$ac,$8b,$a6,$74,$3a,$a5,$44,$93,$86,$3a,$93,$7d,$50,$61
	dc.b	$cf,$ae,$4a,$8d,$ad,$5f,$3f,$07,$a0,$5d,$b2,$a8,$e9,$c4,$9a,$51
	dc.b	$05,$b6,$97,$d2,$3e,$8a,$5d,$93,$3c,$3d,$02,$0d,$13,$e9,$ce,$91
	dc.b	$ec,$8c,$e9,$56,$3f,$a1,$9a,$a7,$22,$c3,$ea,$42,$a8,$61,$af,$a4
	dc.b	$05,$28,$b9,$2f,$b2,$96,$62,$e2,$49,$ce,$2d,$40,$34,$4f,$66,$2c
	dc.b	$9c,$80,$dd,$28,$72,$c1,$a9,$84,$bd,$bc,$f5,$94,$74,$56,$54,$63
	dc.b	$2a,$a0,$fb,$75,$0a,$6d,$22,$22,$ae,$e6,$fc,$d2,$06,$9c,$2f,$1b
	dc.b	$e6,$0d,$80,$4a,$58,$47,$21,$09,$14,$8a,$41,$75,$d3,$a8,$e2,$c5
	dc.b	$54,$43,$fb,$51,$ee,$52,$01,$d2,$eb,$bb,$21,$67,$bf,$e7,$ef,$a0
	dc.b	$4d,$c6,$56,$3e,$74,$b5,$aa,$92,$39,$11,$cd,$e7,$83,$cb,$ee,$7f
	dc.b	$68,$96,$07,$7a,$51,$37,$8f,$ee,$04,$cb,$aa,$76,$5f,$0f,$7e,$cf
	dc.b	$ea,$0d,$5c,$87,$e7,$56,$c0,$34,$64,$5c,$6d,$3c,$ca,$17,$f5,$0f
	dc.b	$50,$37,$30,$cb,$dd,$97,$e2,$62,$21,$a9,$d4,$b7,$91,$ca,$3a,$6d
	dc.b	$62,$6d,$1f,$6a,$a7,$1e,$32,$47,$ce,$d6,$d6,$2f,$63,$de,$f9,$5c
	dc.b	$08,$d2,$ea,$f2,$5a,$23,$1c,$a0,$75,$77,$2e,$5c,$87,$71,$a9,$37
	dc.b	$13,$d1,$46,$85,$ba,$a8,$87,$2b,$c3,$4b,$9b,$cf,$e8,$35,$5d,$e7
	dc.b	$ea,$b9,$78,$e8,$fb,$68,$7c,$e9,$27,$55,$24,$72,$25,$41,$9d,$71
	dc.b	$f9,$36,$6f,$bf,$7c,$3a,$95,$9b,$17,$da,$c2,$27,$b1,$e2,$69,$76
	dc.b	$26,$b8,$d0,$1b,$64,$49,$9f,$82,$bf,$8e,$66,$be,$d0,$98,$92,$d2
	dc.b	$32,$c6,$7e,$3e,$aa,$e0,$4e,$15,$71,$4b,$1f,$36,$dc,$32,$f7,$6f
	dc.b	$6b,$7f,$7f,$fb,$95,$3f,$88,$ad,$3e,$ad,$34,$87,$b3,$5c,$02,$55
	dc.b	$18,$ba,$61,$aa,$9c,$6b,$40,$c7,$ce,$d6,$4e,$2f,$63,$de,$f0,$5c
	dc.b	$44,$55,$06,$29,$82,$08,$42,$81,$38,$6b,$4b,$13,$49,$0f,$ed,$18
	dc.b	$41,$73,$31,$45,$6a,$21,$72,$04,$09,$05,$69,$43,$27,$77,$3e,$08
	dc.b	$78,$1e,$c8,$c1,$b8,$53,$87,$81,$4d,$c9,$db,$80,$15,$f7,$36,$61
	dc.b	$6c,$f8,$e2,$17,$b2,$f2,$5e,$a7,$1e,$a7,$2a,$87,$c9,$af,$40,$bc
	dc.b	$04,$1a,$84,$31,$b4,$06,$87,$44,$4b,$40,$05,$09,$54,$81,$04,$60
	dc.b	$40,$82,$cd,$f7,$82,$93,$f1,$dd,$4e,$35,$cf,$71,$84,$60,$d9,$b2
	dc.b	$8e,$83,$59,$a4,$6d,$7e,$d2,$f2,$aa,$24,$d5,$65,$0e,$1b,$e1,$19
	dc.b	$8a,$ca,$0f,$16,$d4,$10,$90,$90,$8e,$c8,$ab,$fc,$11,$d3,$08,$0a
	dc.b	$91,$61,$9b,$d5,$14,$b8,$fe,$67,$93,$4a,$6e,$e4,$ca,$c2,$75,$0f
	dc.b	$e6,$1d,$bf,$32,$53,$48,$d9,$7b,$18,$83,$bd,$0e,$b6,$f9,$dc,$fc
	dc.b	$17,$e3,$c4,$d6,$ca,$c0,$9d,$67,$cd,$54,$e3,$cc,$41,$7c,$db,$12
	dc.b	$ea,$f7,$04,$37,$6d,$96,$a2,$f7,$38,$ec,$e9,$4c,$41,$46,$81,$90
	dc.b	$80,$bb,$94,$d3,$ab,$ce,$c6,$02,$08,$6f,$f2,$8f,$a6,$61,$af,$b4
	dc.b	$e2,$91,$68,$b7,$b3,$83,$5e,$d6,$d8,$40,$8e,$c4,$38,$76,$81,$37
	dc.b	$1d,$49,$94,$0e,$ea,$85,$2b,$b9,$30,$db,$98,$2b,$7d,$8f,$cc,$00
	dc.b	$de,$77,$92,$bb,$75,$86,$83,$1f,$57,$e0,$1e,$ae,$d5,$bc,$53,$77
	dc.b	$c9,$fc,$7a,$6f,$33,$6b,$f3,$66,$35,$a5,$06,$17,$98,$03,$00,$cb
	dc.b	$b4,$76,$cb,$d6,$4c,$dd,$18,$63,$00,$9a,$7e,$f3,$01,$ca,$d1,$37
	dc.b	$f3,$8b,$40,$30,$0e,$cf,$0d,$6c,$f0,$0d,$b3,$1c,$a6,$9b,$fc,$37
	dc.b	$82,$7b,$63,$85,$fa,$bd,$db,$24,$aa,$0f,$64,$5b,$ab,$b1,$87,$ce
	dc.b	$4c,$68,$1b,$a1,$8e,$a4,$69,$8f,$73,$72,$41,$d7,$8a,$59,$33,$79
	dc.b	$9d,$13,$f2,$5e,$a7,$7b,$05,$09,$6f,$ca,$1d,$0d,$9b,$87,$98,$69
	dc.b	$ec,$29,$d5,$e8,$f6,$11,$f8,$d2,$80,$23,$28,$04,$58,$ef,$94,$32
	dc.b	$e9,$31,$2c,$f8,$90,$2e,$f3,$89,$f4,$75,$c5,$f9,$66,$01,$08,$9d
	dc.b	$e8,$ed,$01,$29,$34,$04,$64,$fa,$c2,$5e,$a9,$65,$ba,$b4,$ce,$92
	dc.b	$4e,$fc,$ce,$1b,$a7,$55,$de,$75,$4c,$a7,$57,$53,$b2,$4d,$8f,$8c
	dc.b	$09,$37,$30,$2a,$d0,$df,$d7,$e3,$0a,$4a,$03,$48,$e1,$a9,$30,$97
	dc.b	$57,$e9,$bd,$ac,$2d,$43,$8f,$cc,$fd,$ca,$7b,$02,$4f,$bb,$de,$e1
	dc.b	$f7,$24,$80,$63,$26,$bb,$87,$9f,$2f,$dc,$cd,$f3,$52,$5c,$14,$b9
	dc.b	$22,$1a,$99,$4e,$0d,$6e,$81,$85,$6d,$18,$d7,$51,$0f,$c6,$61,$d3
	dc.b	$77,$3f,$db,$e7,$54,$9d,$80,$d9,$87,$05,$c7,$d2,$a4,$73,$85,$5c
	dc.b	$3d,$72,$fc,$2b,$2d,$66,$1d,$fc,$ef,$0b,$bd,$cf,$ae,$80,$90,$d6
	dc.b	$6c,$30,$49,$ef,$56,$0d,$0d,$33,$59,$46,$6e,$48,$69,$ef,$7d,$43
	dc.b	$0b,$d4,$e8,$7d,$4f,$dc,$0a,$26,$5a,$72,$e0,$16,$e9,$50,$c3,$26
	dc.b	$b0,$e8,$0c,$08,$cc,$2a,$08,$cd,$d2,$e6,$82,$f8,$5c,$0c,$8f,$33
	dc.b	$c9,$75,$0e,$e1,$77,$f5,$c6,$02,$19,$61,$aa,$09,$09,$a2,$f7,$80
	dc.b	$74,$40,$53,$78,$6b,$4e,$17,$d5,$cf,$7f,$3f,$ab,$ad,$ca,$87,$89
	dc.b	$30,$14,$7c,$08,$ee,$ca,$3c,$03,$90,$43,$de,$5a,$f2,$84,$9e,$b7
	dc.b	$77,$8f,$f7,$78,$3c,$9d,$d8,$7a,$76,$ce,$88,$b1,$6b,$3f,$85,$91
	dc.b	$c8,$f5,$f8,$0f,$a4,$17,$c1,$74,$be,$d6,$3e,$78,$29,$a3,$e0,$4d
	dc.b	$76,$69,$6d,$c6,$08,$77,$6f,$11,$8e,$5c,$50,$8a,$1b,$fe,$97,$fa
	dc.b	$7e,$b1,$ae,$7b,$18,$e3,$c0,$29,$55,$62,$50,$63,$17,$ac,$1a,$c2
	dc.b	$1a,$ca,$3d,$60,$e1,$ae,$3f,$9b,$ab,$2b,$d1,$e7,$6b,$ca,$eb,$00
	dc.b	$d1,$8e,$0d,$16,$e9,$53,$29,$e7,$fe,$44,$d5,$3b,$42,$8c,$df,$91
	dc.b	$36,$ca,$6a,$ff,$cb,$5c,$dc,$ef,$6d,$b9,$34,$b0,$2c,$aa,$b2,$87
	dc.b	$01,$9d,$61,$a6,$06,$2e,$bd,$23,$47,$a9,$1c,$34,$a6,$a7,$81,$be
	dc.b	$ec,$73,$79,$5f,$5b,$f8,$08,$8c,$91,$80,$88,$df,$2f,$c1,$1f,$95
	dc.b	$5d,$ac,$8b,$c5,$f3,$5b,$5e,$bb,$3d,$f0,$9d,$65,$fd,$53,$56,$4b
	dc.b	$6c,$60,$8c,$b6,$ff,$7f,$dc,$ed,$61,$b7,$78,$29,$92,$c6,$e6,$16
	dc.b	$f4,$86,$12,$e6,$07,$19,$03,$04,$54,$c5,$68,$d8,$d2,$9b,$ba,$dc
	dc.b	$6e,$f8,$61,$97,$d2,$b4,$f9,$c6,$1d,$38,$a0,$b3,$40,$51,$41,$51
	dc.b	$0d,$71,$f0,$3c,$7c,$17,$a9,$67,$27,$c9,$72,$50,$2c,$5d,$1e,$95
	dc.b	$1c,$94,$0a,$0d,$68,$7e,$24,$30,$46,$6d,$36,$60,$38,$1e,$07,$da
	dc.b	$ee,$6b,$3b,$3e,$9b,$24,$a1,$67,$0d,$43,$1c,$66,$19,$1a,$6a,$8c
	dc.b	$4c,$c1,$5d,$4a,$27,$ae,$98,$f5,$53,$ab,$fc,$f8,$d9,$af,$f5,$67
	dc.b	$73,$f3,$6a,$40,$d1,$02,$95,$ba,$84,$6c,$2a,$a1,$a5,$be,$57,$29
	dc.b	$65,$aa,$df,$fe,$36,$34,$37,$df,$f6,$57,$0f,$9a,$07,$f8,$75,$e1
	dc.b	$f4,$b5,$f4,$a3,$33,$7e,$57,$b9,$da,$c7,$17,$82,$92,$a9,$72,$96
	dc.b	$29,$b2,$41,$0b,$fa,$3e,$f8,$89,$09,$14,$a3,$dd,$9c,$6a,$9c,$d1
	dc.b	$60,$d0,$59,$f4,$ab,$3c,$c9,$6b,$26,$87,$bf,$a9,$1b,$2c,$12,$99
	dc.b	$aa,$44,$63,$84,$0e,$ea,$7b,$c1,$7e,$57,$5b,$0f,$c9,$f0,$4a,$02
	dc.b	$4b,$c5,$22,$dd,$a5,$1e,$63,$52,$22,$94,$5e,$16,$02,$82,$30,$43
	dc.b	$19,$25,$54,$a7,$bd,$85,$89,$fb,$dd,$6d,$ed,$f6,$52,$cf,$b4,$a3
	dc.b	$20,$a6,$03,$8a,$ad,$5b,$cb,$0a,$1d,$65,$01,$7d,$47,$4a,$7c,$1e
	dc.b	$6b,$15,$e8,$b7,$f4,$f8,$e5,$2c,$35,$45,$f1,$57,$f6,$52,$76,$47
	dc.b	$0d,$18,$9a,$97,$db,$e6,$75,$59,$e9,$4d,$73,$65,$e2,$7c,$9f,$e7
	dc.b	$95,$4f,$1e,$0d,$0b,$55,$66,$eb,$6c,$da,$b8,$d6,$f3,$7f,$08,$b0
	dc.b	$4f,$43,$dd,$76,$b1,$65,$c8,$23,$07,$2a,$8a,$6a,$8c,$ec,$a0,$49
	dc.b	$7d,$c1,$66,$51,$b7,$6c,$cc,$d7,$13,$2c,$ae,$68,$b3,$3e,$70,$c7
	dc.b	$9d,$85,$02,$22,$29,$42,$2e,$7e,$82,$66,$02,$59,$94,$61,$cc,$21
	dc.b	$d6,$a7,$bc,$27,$89,$d2,$fc,$3e,$fb,$d2,$ca,$a9,$e1,$29,$03,$2a
	dc.b	$a4,$9e,$83,$a4,$18,$20,$88,$6c,$52,$09,$5c,$8b,$36,$9b,$33,$22
	dc.b	$a7,$fc,$dc,$bc,$f0,$75,$af,$78,$b9,$54,$19,$da,$88,$31,$40,$05
	dc.b	$d2,$24,$91,$9f,$1b,$e5,$fb,$05,$b2,$2a,$fe,$b3,$5b,$ff,$9f,$86
	dc.b	$ef,$3d,$33,$bc,$ad,$31,$b1,$06,$0b,$27,$6f,$82,$50,$ae,$9f,$41
	dc.b	$1a,$b5,$d8,$da,$76,$57,$b5,$5a,$b7,$28,$eb,$cf,$ab,$a2,$f2,$78
	dc.b	$7f,$b5,$a0,$00,$80,$62,$7a,$70,$75,$ce,$f3,$61,$f0,$40,$1a,$3f
	dc.b	$9d,$38,$88,$4f,$cd,$b9,$d6,$c6,$1d,$c8,$fe,$2c,$34,$04,$68,$9c
	dc.b	$e0,$8d,$3f,$5b,$ce,$64,$94,$50,$91,$4c,$ed,$40,$19,$65,$72,$17
	dc.b	$ad,$05,$8d,$45,$92,$36,$19,$29,$51,$1b,$29,$27,$82,$08,$8c,$50
	dc.b	$e3,$48,$1f,$02,$ea,$8a,$ba,$7b,$0f,$a1,$f3,$ba,$ff,$7d,$ea,$2a
	dc.b	$ac,$2a,$bb,$25,$08,$93,$51,$a3,$d0,$42,$aa,$69,$42,$8e,$86,$87
	dc.b	$e1,$52,$6d,$48,$f2,$ff,$38,$3c,$7e,$af,$55,$ef,$8e,$d6,$5c,$05
	dc.b	$bf,$02,$d4,$24,$9b,$89,$0d,$4f,$89,$69,$99,$0d,$6a,$65,$9d,$bb
	dc.b	$a1,$5e,$4f,$ee,$fd,$df,$2b,$35,$0f,$29,$03,$4c,$e0,$60,$b1,$87
	dc.b	$f7,$cb,$13,$52,$f8,$b6,$02,$dd,$6f,$0c,$eb,$fe,$1b,$6f,$6f,$75
	dc.b	$ed,$56,$e9,$24,$92,$ae,$52,$eb,$97,$e4,$e2,$f8,$d5,$38,$c8,$84
	dc.b	$49,$66,$87,$fa,$d9,$c3,$9e,$e4,$11,$55,$a6,$bc,$38,$de,$89,$2c
	dc.b	$17,$c5,$09,$06,$2a,$96,$0a,$d5,$8c,$4d,$c8,$d6,$f7,$bf,$ac,$1a
	dc.b	$1a,$c1,$66,$08,$1b,$34,$97,$a5,$4f,$39,$e9,$7b,$c1,$04,$51,$7b
	dc.b	$17,$0e,$a8,$0e,$ee,$8a,$99,$6f,$3d,$f0,$7b,$bc,$af,$7d,$ea,$29
	dc.b	$63,$92,$c3,$da,$45,$61,$a2,$c4,$82,$92,$50,$c2,$4d,$01,$f8,$d5
	dc.b	$2b,$c4,$35,$b1,$b9,$cb,$76,$fe,$3b,$5e,$9e,$82,$81,$c1,$f6,$f5
	dc.b	$dc,$02,$d8,$89,$2e,$22,$91,$f3,$8a,$11,$6b,$fe,$e2,$0f,$8d,$95
	dc.b	$fd,$bf,$a5,$6b,$67,$04,$16,$9d,$d9,$ac,$8f,$85,$33,$f3,$02,$10
	dc.b	$6d,$b3,$33,$b3,$8d,$3f,$f2,$c1,$e4,$bf,$de,$af,$27,$dd,$f6,$ae
	dc.b	$41,$38,$f5,$99,$8a,$c9,$f1,$5f,$57,$a8,$d1,$c7,$34,$11,$86,$8e
	dc.b	$ff,$cd,$66,$e1,$f4,$f5,$c3,$f1,$0e,$7b,$44,$8f,$8f,$bc,$4e,$cb
	dc.b	$04,$5f,$e0,$6a,$c0,$55,$ca,$fe,$d7,$ed,$30,$7c,$ba,$86,$27,$fb
	dc.b	$23,$61,$50,$59,$b5,$d4,$68,$f4,$9f,$5b,$f4,$65,$c1,$04,$75,$7f
	dc.b	$72,$e6,$96,$bd,$df,$6f,$dd,$d5,$4f,$73,$c9,$fe,$ad,$f7,$a5,$a8
	dc.b	$15,$a3,$21,$7e,$4b,$d4,$0e,$96,$b8,$22,$0c,$b0,$54,$40,$93,$2b
	dc.b	$fb,$57,$a9,$92,$fd,$d9,$f9,$6c,$cf,$3d,$5e,$4f,$95,$a8,$69,$d5
	dc.b	$04,$2c,$e5,$f7,$c4,$33,$39,$8e,$25,$15,$48,$b3,$ea,$59,$7b,$21
	dc.b	$19,$7e,$e7,$15,$0f,$d6,$5b,$3b,$56,$67,$8a,$da,$c0,$64,$5f,$56
	dc.b	$98,$be,$e9,$df,$66,$df,$88,$85,$c8,$32,$16,$dc,$59,$a7,$85,$dd
	dc.b	$44,$fe,$d4,$3c,$99,$5d,$9f,$ae,$a6,$86,$72,$d6,$0f,$e6,$63,$c3
	dc.b	$ff,$ef,$1c,$bb,$f1,$32,$8f,$50,$22,$cf,$2a,$54,$fd,$ac,$3d,$d4
	dc.b	$66,$a5,$03,$21,$c9,$7a,$37,$15,$f5,$e1,$10,$44,$1d,$5f,$64,$d7
	dc.b	$f0,$4d,$df,$77,$fe,$fd,$31,$0e,$69,$aa,$6b,$ee,$d7,$b6,$e6,$fb
	dc.b	$ab,$a8,$b8,$3e,$64,$90,$a5,$04,$fd,$ae,$2e,$33,$73,$09,$c7,$f0
	dc.b	$5c,$09,$14,$9e,$14,$b9,$e6,$a1,$f0,$3c,$9f,$f7,$7b,$4f,$e0,$e6
	dc.b	$b0,$aa,$9d,$56,$fd,$fb,$7d,$26,$a8,$59,$65,$30,$b7,$94,$6e,$fb
	dc.b	$bf,$2f,$59,$92,$a3,$d5,$f4,$fe,$9b,$c5,$d2,$57,$1b,$8c,$0c,$aa
	dc.b	$82,$cb,$7e,$74,$46,$9e,$b1,$9b,$8a,$d9,$e7,$01,$4d,$67,$9f,$c2
	dc.b	$3d,$21,$f7,$b9,$8e,$5e,$2b,$ca,$1c,$51,$03,$c4,$b9,$3a,$76,$cf
	dc.b	$93,$b8,$b3,$6b,$17,$6a,$fe,$b9,$78,$6f,$ff,$c9,$c5,$de,$ef,$61
	dc.b	$b8,$b0,$35,$94,$c3,$34,$a9,$5b,$fb,$9f,$8e,$d8,$6b,$d0,$22,$70
	dc.b	$04,$97,$1b,$04,$48,$dc,$09,$bc,$0e,$38,$ee,$3f,$2b,$a6,$0e,$c1
	dc.b	$e3,$60,$97,$fe,$4c,$1e,$67,$b4,$08,$cf,$5c,$05,$5a,$c8,$c8,$24
	dc.b	$bc,$2a,$b9,$d9,$0b,$e8,$e0,$8c,$a1,$c1,$10,$ac,$de,$88,$d4,$52
	dc.b	$41,$ae,$ec,$9a,$a0,$01,$c1,$c7,$f4,$59,$81,$97,$45,$df,$97,$fe
	dc.b	$8d,$28,$31,$49,$1b,$27,$6e,$c4,$22,$c0,$92,$c2,$26,$02,$1f,$7f
	dc.b	$5c,$7a,$c3,$6c,$79,$b7,$a2,$29,$bd,$11,$84,$6e,$5d,$b9,$06,$00
	dc.b	$af,$0d,$53,$3c,$c5,$da,$bc,$8f,$af,$8e,$ec,$64,$36,$ed,$c0,$ce
	dc.b	$5c,$bc,$9c,$ca,$20,$66,$dc,$b9,$75,$ca,$97,$c5,$ca,$07,$3f,$1b
	dc.b	$77,$55,$91,$83,$b1,$bf,$59,$5f,$72,$db,$ee,$e5,$b0,$6d,$cb,$90
	dc.b	$7a,$aa,$36,$bf,$90,$79,$a9,$92,$f4,$38,$a9,$18,$e8,$f0,$ab,$d7
	dc.b	$c3,$85,$e9,$a5,$b6,$02,$48,$79,$bd,$35,$16,$ae,$c4,$22,$68,$64
	dc.b	$03,$2a,$55,$9a,$df,$5b,$af,$ea,$06,$d3,$6b,$b6,$bb,$6e,$4f,$4b
	dc.b	$ab,$da,$6d,$77,$3c,$bc,$8e,$6f,$3b,$a9,$d6,$eb,$b7,$be,$5f,$4c
	dc.b	$d6,$8b,$49,$aa,$d5,$ab,$56,$6b,$56,$27,$17,$9a,$d1,$75,$41,$72
	dc.b	$5a,$75,$97,$1b,$92,$ca,$e9,$b6,$3b,$6e,$6d,$2e,$c9,$69,$b6,$5d
	dc.b	$73,$3a,$4d,$3f,$b6,$53,$36,$a5,$55,$2d,$d8,$5c,$56,$5b,$2f,$a1
	dc.b	$e2,$f4,$fb,$52,$ea,$35,$4f,$55,$ba,$dd,$82,$64,$52,$ba,$e5,$9e
	dc.b	$ed,$a3,$d7,$f3,$3a,$5d,$bf,$5c,$ca,$69,$51,$af,$65,$36,$7b,$7e
	dc.b	$4f,$2b,$a9,$de,$93,$5c,$6e,$59,$ed,$66,$cb,$9d,$d1,$ee,$ca,$a7
	dc.b	$77,$a8,$ac,$b2,$5b,$47,$a4,$53,$2c,$58,$7c,$e7,$66,$7b,$42,$ab
	dc.b	$d8,$6f,$7a,$8e,$27,$b8,$15,$31,$a2,$5b,$ee,$97,$9c,$36,$22,$c7
	dc.b	$68,$c7,$71,$bb,$9e,$69,$cd,$62,$e7,$ec,$8b,$46,$a4,$f3,$79,$d7
	dc.b	$8f,$c9,$33,$c2,$73,$f7,$dc,$80,$44,$86,$ef,$90,$f3,$c6,$73,$1e
	dc.b	$2c,$fe,$e3,$79,$d8,$ef,$c8,$e9,$f5,$09,$7e,$c2,$49,$7d,$e1,$71
	dc.b	$e3,$be,$8f,$ac,$6e,$87,$8c,$e8,$01,$e2,$74,$1c,$7c,$4a,$29,$e1
	dc.b	$f9,$60,$bd,$f2,$8b,$e7,$0f,$ef,$17,$af,$fc,$62,$31,$ee,$0d,$fb
	dc.b	$06,$06,$86,$e8,$27,$9f,$4f,$b5,$c3,$7f,$f3,$84,$c2,$af,$18,$18
	dc.b	$5c,$fa,$39,$38,$fd,$fe,$ac,$10,$e0,$27,$e6,$30,$05,$98,$41,$6f
	dc.b	$f2,$08,$64,$3e,$7f,$06,$8f,$c2,$3f,$bf,$08,$87,$e2,$81,$e0,$01
	dc.b	$ff,$38,$10,$78,$24,$0b,$fd,$80,$81,$80,$00,$50,$1f,$f8,$06,$00
	dc.b	$04,$09,$0d,$08,$63,$72,$22,$a6,$18,$08,$d8,$df,$6d,$ed,$ac,$c9
	dc.b	$b6,$64,$e9,$18,$ef,$2a,$62,$d6,$3c,$00,$9a,$49,$a6,$d0,$ab,$84
	dc.b	$f9,$2c,$5f,$da,$49,$ff,$22,$eb,$65,$bc,$9e,$ce,$46,$5a,$74,$3c
	dc.b	$ad,$de,$9f,$44,$a4,$47,$fd,$d8,$32,$f3,$6d,$cc,$f6,$4b,$b9,$1f
	dc.b	$34,$bb,$e6,$b5,$a1,$cd,$3f,$5e,$21,$1b,$d3,$ec,$ea,$6f,$27,$59
	dc.b	$70,$68,$b4,$26,$eb,$d9,$fa,$db,$ee,$b7,$09,$64,$d8,$79,$d0,$70
	dc.b	$96,$58,$6d,$89,$0d,$d1,$32,$6b,$a2,$1a,$b8,$86,$9f,$17,$d8,$f0
	dc.b	$2d,$52,$86,$b5,$50,$c2,$eb,$0d,$83,$1c,$1c,$02,$22,$e1,$cb,$67
	dc.b	$28,$f3,$4a,$cf,$f6,$9f,$17,$de,$70,$71,$9f,$ae,$5b,$99,$20,$0e
	dc.b	$1f,$bd,$51,$23,$d9,$6d,$44,$36,$59,$32,$9e,$a3,$ca,$49,$08,$4d
	dc.b	$d9,$1c,$df,$e4,$6f,$e5,$fd,$b4,$b2,$72,$d9,$f6,$41,$a8,$87,$32
	dc.b	$d2,$88,$f6,$c1,$d1,$08,$d4,$44,$ae,$e0,$48,$d6,$9f,$ee,$92,$f3
	dc.b	$ff,$0f,$98,$b6,$2b,$4b,$a6,$a0,$52,$04,$ac,$bc,$aa,$7c,$ec,$c8
	dc.b	$47,$76,$24,$0e,$99,$89,$10,$35,$76,$3e,$d7,$ae,$5f,$b5,$99,$6d
	dc.b	$a1,$c3,$86,$86,$a9,$5d,$75,$8f,$f3,$1a,$b2,$07,$03,$f4,$46,$a4
	dc.b	$62,$25,$0f,$20,$f2,$be,$0e,$ef,$3c,$9f,$65,$4d,$d8,$c6,$8a,$0b
	dc.b	$5b,$1b,$86,$db,$d8,$6c,$32,$62,$06,$9d,$86,$96,$de,$80,$45,$f8
	dc.b	$6a,$99,$a9,$0d,$0d,$50,$50,$c9,$a4,$8c,$8d,$fa,$0f,$5b,$51,$0d
	dc.b	$56,$a0,$55,$0f,$34,$91,$13,$69,$ed,$ba,$df,$97,$67,$3f,$96,$19
	dc.b	$1c,$82,$35,$c8,$6c,$fb,$2b,$5a,$ab,$2b,$34,$05,$80,$8e,$b8,$b2
	dc.b	$ba,$ae,$f3,$b5,$9b,$d0,$cf,$7d,$6d,$bf,$79,$f6,$5c,$f8,$a8,$b6
	dc.b	$46,$cc,$b0,$0f,$61,$02,$ab,$34,$b5,$e6,$f0,$0e,$fa,$cc,$27,$e8
	dc.b	$f9,$5d,$37,$05,$37,$fb,$ec,$3e,$a2,$06,$5b,$bd,$87,$79,$fb,$3c
	dc.b	$33,$6c,$fb,$21,$72,$e8,$00,$5f,$1f,$16,$cf,$09,$9f,$3a,$f3,$99
	dc.b	$16,$1d,$81,$6a,$65,$ad,$be,$8a,$69,$d4,$e0,$b5,$61,$f1,$4c,$23
	dc.b	$ae,$bf,$3b,$c7,$ce,$19,$3f,$3e,$17,$d3,$6d,$b0,$56,$6a,$ac,$f0
	dc.b	$fd,$7e,$b5,$06,$d8,$04,$96,$c1,$24,$28,$f6,$f8,$5a,$00,$57,$d3
	dc.b	$14,$17,$72,$32,$e4,$a8,$ad,$a9,$09,$4d,$35,$f0,$23,$64,$35,$47
	dc.b	$f9,$ce,$f6,$10,$14,$77,$90,$ef,$e2,$21,$7f,$70,$dc,$a8,$90,$b0
	dc.b	$c9,$dc,$b2,$63,$36,$7d,$cb,$d3,$8a,$8f,$28,$e0,$a6,$78,$c0,$21
	dc.b	$9e,$2d,$3d,$ca,$56,$bc,$fd,$a3,$75,$b0,$ca,$64,$4a,$3e,$32,$56
	dc.b	$4b,$00,$24,$43,$97,$be,$8e,$b7,$84,$09,$4f,$46,$3b,$fd,$e6,$64
	dc.b	$b6,$d9,$db,$b9,$ae,$3a,$fa,$1f,$ad,$9e,$65,$a4,$fd,$2c,$a2,$77
	dc.b	$84,$60,$3e,$eb,$3f,$85,$89,$da,$d5,$e5,$6a,$25,$f4,$32,$6d,$12
	dc.b	$10,$9f,$e9,$c3,$ab,$cf,$a5,$f4,$da,$5f,$e8,$db,$9f,$74,$36,$94
	dc.b	$67,$35,$c4,$43,$dc,$25,$bb,$fa,$ba,$62,$88,$3f,$c3,$67,$cb,$76
	dc.b	$7e,$32,$9d,$a3,$d4,$80,$2b,$ad,$6c,$6d,$12,$38,$57,$01,$23,$a4
	dc.b	$0d,$63,$ac,$df,$f4,$3c,$40,$97,$93,$4f,$77,$f8,$ca,$1d,$d5,$59
	dc.b	$18,$cc,$12,$2a,$b5,$31,$b5,$d4,$99,$f7,$13,$42,$a9,$f2,$84,$3f
	dc.b	$48,$4e,$f8,$8d,$cb,$77,$dc,$b6,$9d,$93,$1d,$16,$38,$5b,$d0,$79
	dc.b	$01,$64,$3a,$92,$0f,$4c,$90,$0f,$74,$02,$3f,$8d,$e7,$f1,$0e,$8b
	dc.b	$69,$47,$c8,$bc,$e8,$35,$5b,$7a,$33,$20,$c2,$76,$39,$72,$d4,$05
	dc.b	$7d,$c3,$dd,$b1,$94,$4e,$f2,$10,$ad,$1d,$5f,$11,$5f,$c9,$4f,$aa
	dc.b	$8c,$9a,$60,$46,$b6,$c9,$8a,$f4,$2c,$a0,$c6,$46,$e1,$9c,$bc,$d8
	dc.b	$fe,$eb,$c9,$e5,$f5,$3e,$df,$ec,$b6,$3a,$5c,$4f,$27,$54,$44,$b6
	dc.b	$b9,$fe,$3b,$20,$fe,$a6,$99,$47,$ac,$50,$d1,$2f,$f3,$bc,$a7,$e4
	dc.b	$a6,$c7,$50,$35,$c7,$4a,$6a,$77,$81,$2a,$44,$74,$0f,$8e,$87,$f6
	dc.b	$58,$3d,$87,$cd,$76,$6d,$31,$19,$c3,$d5,$12,$20,$d4,$76,$c9,$28
	dc.b	$19,$c2,$ac,$60,$dc,$72,$41,$99,$7c,$9e,$68,$b1,$37,$96,$92,$0f
	dc.b	$2b,$fe,$2d,$83,$bc,$99,$40,$12,$aa,$07,$1f,$7b,$98,$18,$5d,$51
	dc.b	$61,$b4,$7e,$60,$5b,$1e,$59,$38,$9e,$cb,$aa,$3d,$78,$65,$88,$11
	dc.b	$df,$37,$55,$7b,$b2,$30,$cc,$86,$19,$45,$0f,$1a,$3c,$9e,$9f,$6b
	dc.b	$fa,$fa,$8c,$34,$f7,$fa,$9d,$7b,$6d,$40,$74,$e3,$1c,$bf,$2e,$b6
	dc.b	$46,$da,$ea,$f0,$40,$17,$17,$1e,$9b,$a0,$91,$61,$6a,$24,$35,$08
	dc.b	$0d,$4b,$68,$d5,$b0,$57,$ee,$0c,$ba,$07,$be,$b6,$8b,$ff,$5c,$85
	dc.b	$97,$65,$19,$56,$8a,$b6,$35,$6e,$ce,$cc,$03,$2c,$4b,$40,$d1,$7b
	dc.b	$9c,$e8,$5a,$3c,$d0,$d8,$e0,$ff,$bc,$42,$a2,$25,$48,$ba,$9e,$96
	dc.b	$d5,$ca,$cf,$bb,$2a,$40,$9b,$a4,$a1,$d4,$e4,$3c,$60,$fc,$9a,$9e
	dc.b	$90,$9f,$17,$9f,$8e,$3c,$a2,$8b,$df,$bb,$d4,$91,$59,$f0,$39,$20
	dc.b	$f1,$65,$1e,$a4,$1a,$64,$40,$fa,$d7,$55,$4e,$91,$cb,$83,$27,$6d
	dc.b	$8e,$89,$6f,$85,$ae,$cf,$fb,$b5,$12,$5f,$7a,$00,$3e,$65,$d2,$e1
	dc.b	$07,$d9,$62,$23,$53,$d4,$7d,$4d,$67,$dc,$6d,$68,$3d,$a9,$f6,$4b
	dc.b	$62,$16,$76,$74,$ea,$0a,$03,$d2,$9a,$94,$46,$83,$cb,$a9,$03,$f9
	dc.b	$eb,$23,$a3,$ce,$fd,$df,$3a,$97,$0b,$ba,$65,$6c,$57,$9c,$72,$f2
	dc.b	$b2,$aa,$66,$9e,$35,$1b,$73,$de,$d6,$6a,$7b,$53,$55,$31,$a1,$4c
	dc.b	$b2,$be,$32,$05,$1a,$24,$2c,$04,$0f,$5b,$f4,$dc,$f4,$d3,$2c,$66
	dc.b	$34,$e9,$93,$23,$a1,$29,$10,$d4,$b2,$9e,$33,$b2,$30,$13,$21,$4a
	dc.b	$18,$f1,$76,$f2,$12,$fe,$56,$59,$e3,$67,$78,$79,$8c,$2d,$47,$12
	dc.b	$19,$64,$3b,$d9,$2c,$dc,$01,$d7,$14,$d5,$a7,$e0,$b9,$a2,$d5,$4d
	dc.b	$d7,$c7,$66,$6b,$9d,$19,$34,$5c,$25,$30,$83,$92,$43,$cf,$e9,$78
	dc.b	$1b,$99,$47,$94,$a5,$c8,$d3,$2a,$22,$fe,$5b,$31,$84,$0d,$eb,$d0
	dc.b	$1b,$61,$30,$a3,$10,$84,$d9,$06,$97,$f9,$a9,$5f,$84,$d4,$86,$4b
	dc.b	$c7,$31,$f6,$a0,$2a,$fe,$bd,$1e,$8d,$94,$51,$81,$35,$3c,$86,$ea
	dc.b	$b9,$52,$76,$43,$b3,$82,$72,$05,$68,$85,$5c,$b8,$fd,$68,$c3,$0f
	dc.b	$ae,$10,$d1,$90,$8e,$64,$32,$be,$15,$03,$ee,$31,$d2,$be,$d2,$8b
	dc.b	$65,$18,$6a,$fe,$fb,$59,$cd,$e1,$34,$0b,$80,$44,$0d,$7a,$60,$e2
	dc.b	$32,$b2,$a0,$60,$cc,$a1,$a7,$33,$24,$90,$62,$30,$99,$df,$c4,$38
	dc.b	$e2,$a8,$cb,$01,$0d,$1d,$5a,$2a,$64,$a3,$35,$02,$dc,$83,$37,$49
	dc.b	$25,$e9,$4a,$d5,$48,$4b,$0b,$2e,$8d,$0e,$d0,$1d,$93,$08,$6a,$f2
	dc.b	$fe,$fa,$66,$25,$ec,$4e,$06,$33,$5b,$09,$d9,$1e,$07,$d8,$b8,$07
	dc.b	$19,$74,$38,$00,$5c,$8d,$d9,$f3,$62,$68,$a4,$9e,$cf,$c8,$ed,$01
	dc.b	$93,$2f,$7f,$f3,$47,$2b,$14,$61,$c2,$e7,$ef,$2c,$3b,$d6,$f6,$45
	dc.b	$33,$14,$44,$6c,$03,$b1,$0a,$29,$47,$dc,$a3,$11,$49,$5c,$c1,$6c
	dc.b	$fb,$d4,$a6,$cc,$98,$be,$0e,$42,$18,$4a,$ef,$01,$f1,$3b,$14,$58
	dc.b	$80,$45,$cc,$5e,$58,$b1,$9b,$24,$9c,$a7,$66,$52,$b4,$a1,$a6,$bd
	dc.b	$44,$90,$75,$c8,$8a,$4a,$f4,$60,$71,$30,$c3,$d4,$0c,$35,$8d,$7a
	dc.b	$62,$8e,$53,$b2,$64,$55,$25,$aa,$61,$a6,$af,$f2,$3b,$40,$8e,$50
	dc.b	$b8,$7a,$8f,$f6,$0e,$42,$3d,$45,$c3,$d1,$7a,$63,$0f,$f2,$c5,$9f
	dc.b	$3e,$c8,$c2,$b0,$f5,$c3,$04,$37,$9d,$cd,$f8,$a4,$69,$ea,$26,$a9
	dc.b	$26,$e9,$ec,$89,$59,$83,$12,$61,$9c,$20,$87,$f8,$c0,$4c,$de,$b2
	dc.b	$de,$4c,$7a,$38,$9a,$90,$81,$d1,$37,$57,$7c,$ea,$65,$01,$48,$0a
	dc.b	$72,$92,$00,$f3,$ac,$38,$38,$70,$f8,$ae,$1c,$12,$4e,$1c,$a0,$64
	dc.b	$8e,$c0,$6b,$e2,$1a,$b4,$bd,$d7,$df,$38,$e2,$0d,$2b,$c6,$d7,$5a
	dc.b	$12,$41,$a6,$20,$77,$69,$9d,$7c,$0f,$ef,$58,$1c,$72,$94,$05,$ca
	dc.b	$74,$6e,$0b,$0e,$69,$dd,$19,$72,$18,$3c,$32,$4b,$d1,$9e,$50,$c5
	dc.b	$51,$bc,$a9,$2b,$01,$92,$21,$d8,$1a,$f5,$70,$fd,$07,$8c,$04,$bc
	dc.b	$5a,$b3,$89,$3d,$18,$c0,$d5,$08,$eb,$f0,$f3,$b2,$56,$f8,$0d,$4a
	dc.b	$40,$1c,$eb,$08,$a7,$09,$a5,$56,$3f,$71,$44,$92,$46,$45,$20,$2a
	dc.b	$c6,$20,$44,$4c,$85,$cb,$3b,$08,$39,$62,$72,$02,$af,$44,$d1,$9b
	dc.b	$5b,$2e,$eb,$57,$ab,$6a,$b6,$3c,$e8,$02,$46,$11,$a9,$6c,$96,$cd
	dc.b	$11,$3d,$e5,$31,$58,$0a,$c6,$80,$aa,$c5,$a3,$91,$05,$2e,$94,$4c
	dc.b	$44,$64,$87,$49,$12,$db,$3e,$78,$12,$45,$2e,$5a,$c1,$22,$e0,$2f
	dc.b	$a5,$a6,$33,$22,$6b,$19,$ac,$d3,$2d,$a8,$89,$11,$eb,$1e,$b3,$90
	dc.b	$ec,$cd,$0a,$8b,$d2,$1c,$e2,$27,$23,$d7,$21,$ae,$fb,$8e,$88,$75
	dc.b	$9a,$0d,$c9,$d6,$ce,$b1,$fd,$42,$bd,$f3,$de,$50,$2d,$4d,$20,$12
	dc.b	$78,$a5,$55,$48,$1a,$ed,$45,$95,$15,$8d,$41,$10,$9b,$89,$3c,$e8
	dc.b	$12,$a3,$0e,$d0,$30,$b0,$dd,$97,$4b,$d9,$48,$73,$2c,$de,$c2,$29
	dc.b	$d2,$dd,$6c,$43,$8a,$fc,$c6,$8c,$e9,$19,$48,$4c,$07,$8e,$30,$4c
	dc.b	$6f,$a4,$36,$cb,$ae,$3d,$a7,$a5,$8c,$a8,$f1,$c3,$75,$24,$5a,$7b
	dc.b	$b1,$0b,$0d,$a9,$06,$e5,$cf,$2b,$94,$f1,$ef,$cc,$fd,$95,$37,$01
	dc.b	$51,$d0,$06,$70,$07,$de,$48,$59,$cd,$24,$a3,$e1,$84,$cf,$41,$e5
	dc.b	$c1,$f2,$b9,$b3,$2d,$ab,$66,$0b,$59,$c4,$0c,$d3,$9d,$51,$36,$e3
	dc.b	$f7,$64,$5b,$50,$53,$c6,$2d,$09,$19,$4c,$2c,$b1,$e9,$0e,$09,$a3
	dc.b	$90,$d6,$49,$26,$a4,$99,$25,$10,$d6,$50,$aa,$08,$0d,$ce,$3a,$c1
	dc.b	$bc,$af,$9b,$12,$31,$ab,$ca,$02,$f0,$80,$7b,$0d,$34,$c7,$42,$08
	dc.b	$8d,$98,$93,$8b,$93,$a3,$0d,$c4,$39,$01,$c3,$5e,$f0,$0e,$8f,$bf
	dc.b	$ab,$af,$29,$a8,$10,$13,$61,$e6,$9e,$43,$47,$2a,$43,$9c,$75,$d9
	dc.b	$c7,$63,$ac,$97,$85,$c4,$4a,$72,$44,$c0,$d2,$26,$0d,$f1,$95,$1a
	dc.b	$1b,$1a,$5f,$16,$36,$7f,$51,$83,$54,$68,$33,$58,$4e,$f3,$e2,$c8
	dc.b	$66,$22,$57,$d7,$be,$1f,$64,$55,$34,$05,$9f,$8d,$a8,$8e,$74,$f2
	dc.b	$dc,$1a,$35,$e2,$9b,$98,$30,$56,$98,$d5,$cb,$8e,$26,$35,$24,$03
	dc.b	$2c,$55,$e4,$44,$91,$7b,$b3,$6a,$39,$85,$39,$61,$a3,$92,$5d,$44
	dc.b	$a6,$50,$ea,$41,$ac,$aa,$0b,$7d,$91,$92,$5c,$7d,$91,$89,$88,$3e
	dc.b	$57,$10,$5c,$14,$c8,$81,$af,$a8,$f9,$41,$12,$0f,$61,$a2,$76,$80
	dc.b	$b7,$86,$b9,$ab,$80,$47,$22,$20,$88,$6a,$8f,$a1,$b2,$c2,$14,$44
	dc.b	$32,$da,$cb,$1b,$3d,$d9,$9b,$5a,$d9,$8c,$7c,$56,$12,$9b,$b6,$29
	dc.b	$ab,$6c,$5c,$7b,$4f,$07,$b0,$e5,$cc,$70,$35,$0c,$cf,$42,$47,$77
	dc.b	$97,$0c,$99,$3a,$15,$10,$e9,$91,$2b,$0d,$a8,$36,$b9,$df,$28,$54
	dc.b	$47,$54,$1e,$d5,$96,$3f,$d8,$05,$ed,$96,$b3,$a0,$cb,$1c,$b8,$0d
	dc.b	$5b,$46,$6d,$95,$a3,$3e,$e0,$15,$11,$19,$90,$e6,$5b,$51,$ad,$46
	dc.b	$bb,$0f,$51,$28,$31,$43,$5b,$38,$8f,$24,$81,$52,$b2,$2b,$2b,$2c
	dc.b	$5f,$60,$5b,$e3,$e5,$bb,$11,$5d,$76,$0c,$c7,$39,$9a,$01,$19,$88
	dc.b	$da,$30,$11,$d1,$c2,$95,$d7,$f5,$69,$b4,$03,$32,$b0,$e4,$c2,$d8
	dc.b	$7c,$f8,$7b,$5d,$fc,$56,$12,$31,$cf,$3b,$c4,$00,$29,$75,$24,$31
	dc.b	$ee,$f4,$b9,$46,$93,$fd,$aa,$3c,$70,$35,$63,$3d,$09,$10,$b4,$b2
	dc.b	$dd,$c0,$e3,$93,$a2,$31,$2e,$99,$12,$bb,$0b,$3c,$cd,$aa,$0f,$39
	dc.b	$89,$44,$42,$73,$b6,$dc,$89,$32,$40,$44,$cd,$68,$f7,$ca,$e4,$df
	dc.b	$2d,$28,$53,$0b,$2b,$80,$78,$f6,$92,$3a,$a5,$7b,$43,$6a,$0e,$a3
	dc.b	$c0,$46,$25,$33,$21,$cc,$b6,$a3,$5a,$88,$d6,$14,$78,$dc,$06,$11
	dc.b	$c4,$a0,$d2,$40,$ab,$11,$7b,$e5,$4c,$97,$42,$11,$d8,$e9,$96,$c3
	dc.b	$88,$ec,$f2,$20,$24,$bb,$f4,$41,$64,$64,$70,$21,$00,$88,$2a,$79
	dc.b	$70,$38,$28,$e9,$e1,$66,$80,$0d,$a1,$43,$0c,$72,$00,$5b,$ca,$9b
	dc.b	$77,$6d,$f1,$53,$e0,$f0,$e2,$7c,$a9,$0a,$39,$6c,$2f,$98,$3d,$c9
	dc.b	$dc,$1a,$06,$3d,$a7,$f8,$f4,$71,$cf,$ae,$f7,$8b,$7f,$3e,$d7,$0b
	dc.b	$99,$f4,$1e,$3b,$e1,$43,$fe,$7a,$c1,$7e,$0c,$ef,$b5,$c5,$64,$30
	dc.b	$00,$7c,$f7,$4e,$54,$c5,$bd,$cb,$b0,$99,$94,$7c,$0f,$6b,$34,$a9
	dc.b	$4d,$f2,$9a,$e0,$ae,$5a,$51,$5e,$c4,$f6,$64,$20,$3d,$e7,$a3,$91
	dc.b	$a0,$fd,$3a,$e1,$0e,$b4,$5a,$02,$7c,$10,$94,$d3,$7a,$e6,$16,$56
	dc.b	$95,$87,$32,$6d,$d8,$46,$f1,$2a,$f4,$47,$93,$44,$fe,$c4,$02,$cc
	dc.b	$82,$23,$1c,$51,$10,$fc,$c7,$4a,$e6,$1f,$43,$b5,$5a,$f7,$ba,$1e
	dc.b	$83,$2a,$38,$20,$5c,$64,$10,$fa,$9b,$a0,$f5,$1c,$85,$27,$e0,$cc
	dc.b	$fe,$ab,$bd,$95,$ca,$08,$dd,$7a,$d9,$9a,$b3,$e6,$f3,$a2,$75,$b8
	dc.b	$60,$b8,$1f,$49,$5d,$81,$dc,$dd,$7e,$77,$b6,$88,$97,$76,$48,$b1
	dc.b	$7a,$24,$40,$18,$4f,$96,$6d,$8f,$6e,$e7,$b7,$f9,$05,$d3,$59,$85
	dc.b	$9f,$e8,$a1,$bb,$4a,$51,$db,$eb,$3d,$01,$1a,$b3,$d1,$d4,$db,$44
	dc.b	$f5,$cd,$21,$36,$57,$02,$33,$49,$53,$e9,$a7,$2e,$c6,$a6,$a2,$47
	dc.b	$09,$88,$79,$1f,$f3,$9c,$30,$07,$56,$a4,$25,$0b,$ec,$41,$be,$41
	dc.b	$4b,$10,$2d,$3f,$47,$0f,$14,$85,$5f,$78,$45,$4d,$d6,$11,$59,$0b
	dc.b	$60,$c6,$81,$b4,$18,$ea,$de,$24,$b8,$1a,$a7,$20,$7d,$9b,$ca,$22
	dc.b	$1c,$2b,$33,$1c,$31,$ab,$10,$f0,$df,$6e,$95,$20,$40,$d4,$2b,$13
	dc.b	$85,$8d,$5c,$82,$e9,$9c,$84,$c7,$9c,$c3,$53,$6e,$3b,$0e,$97,$67
	dc.b	$9c,$01,$6c,$e0,$b2,$48,$31,$ec,$f2,$ff,$29,$32,$d9,$35,$b8,$40
	dc.b	$33,$fa,$87,$8a,$d4,$27,$96,$fc,$93,$60,$64,$c5,$6a,$93,$15,$87
	dc.b	$8c,$56,$b0,$16,$c2,$f3,$ad,$c3,$be,$85,$ad,$4e,$e3,$6c,$ca,$54
	dc.b	$d3,$5f,$47,$3a,$72,$72,$ae,$3a,$d9,$fb,$33,$ed,$81,$3c,$16,$be
	dc.b	$54,$59,$86,$5f,$f5,$03,$37,$ec,$31,$35,$b3,$f3,$62,$90,$d5,$10
	dc.b	$f8,$d4,$e3,$5a,$ab,$68,$46,$77,$d5,$29,$b1,$45,$f4,$0c,$44,$71
	dc.b	$b6,$6b,$e2,$74,$fb,$0a,$d9,$b0,$e6,$43,$02,$d5,$84,$70,$6d,$83
	dc.b	$18,$9b,$3e,$92,$65,$b2,$51,$08,$06,$af,$20,$95,$99,$11,$21,$1a
	dc.b	$ca,$6e,$cc,$6a,$14,$84,$6f,$42,$4a,$d4,$7a,$e3,$10,$d1,$49,$68
	dc.b	$5b,$6b,$09,$af,$a1,$69,$5c,$b9,$9b,$75,$48,$65,$d3,$ed,$f3,$01
	dc.b	$63,$99,$be,$a9,$00,$60,$f5,$90,$ce,$70,$5f,$bf,$d3,$69,$0d,$2c
	dc.b	$44,$ff,$79,$03,$23,$aa,$6f,$71,$2c,$b4,$74,$51,$25,$9c,$bc,$3f
	dc.b	$7f,$0e,$6c,$c9,$5b,$05,$d7,$74,$2c,$63,$1e,$b7,$f1,$1b,$d1,$5a
	dc.b	$47,$06,$30,$17,$b6,$c4,$b7,$8b,$b0,$08,$bc,$a0,$e7,$4d,$c2,$b0
	dc.b	$8b,$32,$1c,$83,$11,$de,$3c,$f5,$b0,$e6,$cd,$d1,$53,$8e,$6a,$d9
	dc.b	$80,$33,$78,$e6,$ab,$dd,$cd,$1c,$df,$da,$aa,$29,$77,$49,$a3,$84
	dc.b	$7c,$31,$1e,$22,$2c,$4e,$cc,$65,$35,$c4,$35,$29,$6c,$19,$38,$f2
	dc.b	$98,$c4,$d6,$43,$53,$8e,$fa,$b4,$10,$69,$08,$94,$cb,$a7,$91,$1d
	dc.b	$77,$16,$5a,$3a,$2a,$24,$82,$4b,$ca,$b8,$d7,$d7,$df,$c2,$a6,$64
	dc.b	$1b,$0a,$9f,$ca,$b6,$e9,$ae,$53,$34,$c3,$4a,$81,$cb,$9d,$d9,$38
	dc.b	$16,$c1,$a5,$28,$23,$63,$13,$0e,$39,$99,$6e,$db,$3a,$8c,$8e,$40
	dc.b	$0d,$4b,$f2,$81,$6a,$cf,$6b,$46,$77,$dc,$b2,$0d,$3f,$5e,$73,$c3
	dc.b	$f8,$bd,$9e,$2a,$66,$ff,$56,$69,$a7,$a9,$90,$a6,$de,$3b,$a1,$29
	dc.b	$d6,$62,$fc,$81,$9c,$a2,$8f,$a8,$68,$7d,$ca,$35,$60,$77,$22,$62
	dc.b	$3e,$1a,$b5,$67,$b0,$b8,$cf,$63,$d6,$7a,$c9,$c2,$7b,$53,$6c,$06
	dc.b	$bc,$49,$cf,$0f,$8b,$2d,$dc,$9a,$25,$0f,$ef,$cd,$3d,$7c,$c6,$4f
	dc.b	$0e,$c2,$44,$4d,$29,$d8,$34,$8b,$29,$a0,$47,$94,$83,$1b,$ff,$54
	dc.b	$a8,$13,$07,$91,$4d,$20,$e8,$d2,$c8,$64,$35,$0e,$a1,$24,$9f,$01
	dc.b	$ee,$d7,$b2,$3b,$3a,$4a,$1e,$97,$47,$29,$0d,$4e,$73,$f3,$8b,$95
	dc.b	$e2,$c0,$74,$24,$ee,$a6,$43,$d4,$d4,$7a,$1a,$df,$b1,$97,$79,$a7
	dc.b	$0b,$f3,$90,$46,$db,$8e,$31,$ab,$4b,$f7,$f9,$68,$cf,$dd,$b6,$34
	dc.b	$29,$9a,$df,$70,$29,$ef,$c4,$47,$b1,$fb,$ef,$75,$73,$d7,$cf,$2b
	dc.b	$84,$69,$2d,$27,$50,$72,$2e,$0f,$aa,$d3,$c8,$8e,$95,$1d,$08,$f3
	dc.b	$39,$75,$2a,$ca,$f8,$56,$e9,$25,$bd,$ae,$40,$3b,$38,$df,$00,$b5
	dc.b	$aa,$b3,$62,$b8,$25,$48,$c9,$da,$62,$60,$23,$fb,$be,$ea,$2c,$3c
	dc.b	$58,$1f,$89,$42,$33,$b9,$dd,$45,$1e,$05,$7d,$b4,$da,$a5,$89,$65
	dc.b	$d9,$8e,$9c,$e5,$0e,$c2,$83,$8b,$7a,$19,$88,$0c,$5f,$63,$88,$9e
	dc.b	$4a,$da,$41,$cd,$2a,$14,$4c,$32,$2d,$f7,$11,$12,$52,$44,$06,$70
	dc.b	$12,$8e,$5c,$89,$01,$b7,$e2,$eb,$d3,$e8,$c8,$5d,$00,$66,$3a,$f0
	dc.b	$0a,$8b,$10,$1f,$1b,$96,$10,$25,$6e,$b7,$cb,$c9,$a0,$34,$b9,$1c
	dc.b	$7f,$3f,$3a,$14,$99,$22,$d5,$ec,$e8,$8b,$8f,$09,$a9,$e6,$db,$bd
	dc.b	$1c,$fd,$96,$77,$1e,$d9,$45,$58,$bd,$9e,$27,$ce,$69,$ab,$2d,$66
	dc.b	$33,$78,$2f,$42,$1b,$8d,$5a,$3a,$3c,$d4,$af,$c9,$77,$86,$cb,$71
	dc.b	$52,$b9,$73,$0a,$63,$e7,$c3,$56,$37,$05,$11,$c1,$db,$ea,$f4,$4a
	dc.b	$e6,$f3,$b9,$ef,$2f,$8c,$69,$45,$e6,$d8,$b6,$88,$29,$f1,$7e,$fa
	dc.b	$d6,$69,$1d,$df,$b8,$91,$85,$2b,$a7,$c3,$19,$cc,$d6,$0e,$57,$f0
	dc.b	$eb,$de,$6b,$d0,$8b,$60,$07,$96,$a9,$ed,$b5,$88,$06,$4d,$7c,$b6
	dc.b	$14,$c9,$46,$90,$67,$75,$c7,$8f,$5e,$25,$d7,$ad,$07,$30,$79,$43
	dc.b	$bc,$b3,$91,$95,$10,$41,$0d,$21,$22,$43,$ab,$08,$c3,$dd,$0a,$e8
	dc.b	$35,$d1,$89,$37,$8b,$da,$01,$a7,$d5,$a6,$ec,$f2,$82,$34,$23,$36
	dc.b	$1b,$52,$ae,$ef,$93,$e0,$f9,$c0,$3c,$25,$aa,$86,$95,$80,$06,$41
	dc.b	$27,$fc,$fc,$77,$7f,$52,$41,$9f,$d5,$5e,$f0,$d4,$7c,$09,$c8,$75
	dc.b	$f7,$36,$14,$4d,$ce,$03,$50,$50,$17,$63,$d4,$11,$34,$91,$19,$38
	dc.b	$c7,$b9,$1e,$50,$2a,$62,$52,$04,$d6,$cc,$ac,$73,$67,$18,$cb,$cf
	dc.b	$07,$46,$ee,$11,$bf,$9d,$67,$1d,$7c,$27,$6a,$68,$41,$52,$5f,$e2
	dc.b	$0f,$0c,$75,$5e,$6c,$28,$68,$0f,$87,$f2,$8e,$75,$0a,$81,$44,$07
	dc.b	$58,$06,$76,$6c,$b4,$19,$22,$2f,$89,$69,$ac,$46,$b8,$63,$cb,$6b
	dc.b	$94,$f1,$36,$15,$aa,$e7,$65,$0e,$de,$19,$4b,$f5,$35,$d8,$21,$7b
	dc.b	$90,$c7,$40,$84,$5c,$7e,$ba,$8c,$b0,$53,$e5,$c1,$9e,$e5,$ff,$56
	dc.b	$a8,$01,$6d,$b9,$61,$fe,$a9,$92,$04,$76,$98,$bf,$3d,$7b,$3a,$bc
	dc.b	$da,$14,$2f,$97,$64,$62,$bf,$d9,$32,$6b,$b7,$7b,$29,$6e,$ab,$50
	dc.b	$70,$bb,$31,$ef,$b2,$60,$9e,$11,$82,$b9,$44,$5b,$aa,$fe,$5f,$ea
	dc.b	$53,$d8,$0f,$db,$a2,$b8,$cc,$58,$33,$7d,$09,$7d,$c3,$26,$1e,$b7
	dc.b	$bb,$be,$6a,$e1,$9c,$6e,$0a,$c2,$06,$45,$32,$85,$73,$6a,$e3,$f4
	dc.b	$0c,$dc,$01,$f9,$59,$b4,$f9,$71,$8b,$d4,$ea,$9c,$5e,$cb,$db,$07
	dc.b	$b8,$8b,$0a,$3d,$b3,$3e,$06,$b1,$4d,$fb,$95,$b6,$2f,$d0,$16,$7b
	dc.b	$29,$97,$76,$39,$11,$a2,$01,$4b,$70,$5b,$18,$e7,$ad,$bf,$ee,$eb
	dc.b	$97,$ac,$31,$c8,$4b,$10,$d0,$fd,$48,$e1,$7e,$58,$e3,$2e,$58,$42
	dc.b	$f7,$34,$43,$e2,$ca,$e4,$d6,$52,$dd,$5d,$30,$70,$c7,$cd,$ca,$64
	dc.b	$69,$00,$78,$e5,$9b,$8b,$62,$ca,$38,$40,$75,$bf,$17,$94,$a4,$60
	dc.b	$67,$60,$9b,$60,$27,$75,$85,$6c,$1f,$32,$da,$ae,$7d,$10,$79,$ee
	dc.b	$ec,$0b,$21,$46,$8e,$ef,$b4,$da,$c0,$6f,$f2,$5e,$8d,$da,$58,$1d
	dc.b	$ad,$1f,$28,$a6,$c8,$ab,$03,$33,$74,$18,$91,$ed,$92,$d4,$88,$78
	dc.b	$ac,$da,$79,$19,$0f,$b9,$39,$42,$32,$41,$dc,$bb,$3b,$18,$8a,$79
	dc.b	$61,$aa,$8b,$08,$5d,$08,$c0,$4d,$03,$3d,$4d,$fa,$72,$c1,$97,$07
	dc.b	$2b,$50,$75,$2c,$77,$10,$01,$66,$f7,$66,$37,$d2,$ad,$9d,$47,$fa
	dc.b	$01,$eb,$e1,$c4,$fe,$76,$2c,$bc,$58,$b5,$99,$b7,$62,$35,$64,$25
	dc.b	$72,$86,$8a,$f5,$35,$ba,$d7,$57,$55,$6d,$63,$8b,$8b,$24,$fb,$14
	dc.b	$76,$36,$33,$09,$b8,$38,$7b,$50,$14,$6b,$97,$70,$19,$6c,$1d,$58
	dc.b	$d5,$f0,$39,$d6,$58,$43,$58,$44,$af,$32,$f0,$38,$ca,$5a,$cf,$d2
	dc.b	$d6,$19,$a3,$6a,$b3,$aa,$91,$75,$17,$06,$7f,$0d,$9a,$3f,$2d,$b6
	dc.b	$c2,$ac,$26,$e8,$80,$a7,$16,$b3,$e9,$91,$1a,$9e,$54,$6c,$c8,$43
	dc.b	$ae,$12,$d4,$80,$e3,$dc,$24,$0f,$f3,$35,$95,$09,$b3,$22,$10,$6a
	dc.b	$0f,$2a,$38,$0d,$e1,$6c,$0c,$bd,$75,$ac,$ce,$31,$ef,$05,$cc,$d3
	dc.b	$52,$3a,$7a,$f1,$37,$05,$be,$68,$c8,$39,$f3,$2d,$8c,$bb,$b2,$18
	dc.b	$a6,$b0,$80,$23,$b6,$e1,$d4,$a7,$e2,$dc,$ef,$4b,$6a,$78,$75,$24
	dc.b	$34,$be,$9c,$08,$a7,$91,$60,$7f,$5a,$91,$c0,$20,$99,$7f,$17,$dd
	dc.b	$7b,$63,$c1,$9f,$af,$69,$ee,$d9,$14,$50,$d6,$78,$7b,$d2,$1e,$b8
	dc.b	$46,$cc,$1a,$88,$66,$b4,$3a,$e8,$bf,$2f,$82,$a2,$2c,$65,$92,$c4
	dc.b	$6a,$ea,$e0,$27,$78,$fb,$9f,$f6,$cf,$0f,$67,$c1,$bb,$73,$b8,$6d
	dc.b	$86,$35,$0d,$6c,$7d,$9e,$35,$9a,$90,$38,$4a,$00,$bb,$fb,$3a,$ef
	dc.b	$9c,$8a,$91,$74,$c1,$b2,$2c,$d5,$dc,$ae,$05,$c3,$b0,$f9,$ea,$f1
	dc.b	$59,$17,$ad,$76,$62,$4f,$3d,$d9,$af,$6f,$14,$3c,$bb,$48,$27,$a0
	dc.b	$7b,$b0,$6e,$3d,$90,$78,$2e,$5a,$9e,$bb,$96,$a5,$9f,$99,$bc,$37
	dc.b	$be,$80,$b8,$d0,$bb,$6c,$30,$5c,$ae,$5e,$5a,$9f,$ca,$66,$2f,$ea
	dc.b	$e2,$8b,$31,$9e,$ea,$32,$39,$5a,$b4,$fc,$f4,$3c,$b6,$41,$63,$2e
	dc.b	$03,$bb,$56,$13,$31,$38,$eb,$60,$be,$1d,$fd,$60,$a2,$1b,$50,$2f
	dc.b	$5c,$97,$e4,$2e,$98,$1c,$46,$11,$dd,$1f,$24,$5a,$bd,$c9,$d6,$c4
	dc.b	$27,$57,$e8,$4c,$a0,$7e,$49,$79,$41,$a1,$71,$49,$e5,$8a,$77,$21
	dc.b	$c3,$d7,$0f,$5e,$c3,$de,$59,$a5,$a1,$80,$2a,$c3,$e7,$32,$5d,$5b
	dc.b	$9c,$c7,$00,$e2,$9b,$fd,$df,$6e,$93,$1b,$2c,$db,$1a,$32,$ad,$db
	dc.b	$e5,$86,$89,$20,$80,$5a,$b4,$e3,$6f,$17,$00,$ae,$c5,$9e,$1e,$59
	dc.b	$ee,$a6,$e4,$52,$4c,$ee,$45,$e9,$c2,$0c,$ab,$2e,$e5,$65,$cf,$65
	dc.b	$39,$30,$6a,$e9,$45,$6c,$bd,$ee,$45,$6e,$b9,$01,$9e,$e5,$bb,$91
	dc.b	$43,$31,$bd,$cd,$dc,$99,$5b,$ba,$ee,$4c,$9d,$88,$75,$72,$9c,$00
	dc.b	$c1,$70,$b2,$f4,$2c,$f7,$0b,$83,$1e,$70,$2b,$74,$04,$a3,$80,$40
	dc.b	$c9,$64,$77,$02,$91,$76,$65,$16,$e0,$c5,$2e,$16,$5d,$f6,$c0,$d1
	dc.b	$24,$28,$d2,$03,$7c,$a9,$0f,$53,$93,$6c,$79,$b7,$8b,$21,$3b,$75
	dc.b	$b2,$81,$c7,$03,$dd,$d3,$b5,$33,$1e,$3b,$ba,$c9,$9d,$c9,$bd,$38
	dc.b	$64,$ca,$95,$f3,$98,$db,$b6,$66,$63,$8b,$7c,$f5,$28,$93,$ab,$8e
	dc.b	$07,$57,$58,$fa,$ec,$e4,$d4,$7b,$66,$a8,$a2,$d4,$9c,$93,$61,$3a
	dc.b	$ae,$6c,$6f,$77,$75,$dc,$3f,$5c,$ea,$fd,$58,$96,$31,$13,$0b,$28
	dc.b	$42,$3a,$b8,$88,$74,$b4,$13,$56,$c1,$53,$a1,$67,$b4,$b9,$d1,$64
	dc.b	$30,$90,$58,$8d,$8f,$45,$72,$63,$62,$92,$e0,$a0,$88,$14,$80,$ae
	dc.b	$1a,$ec,$cc,$2c,$97,$d4,$d9,$b8,$7e,$64,$75,$fd,$50,$5b,$2a,$e0
	dc.b	$0e,$43,$31,$47,$2e,$3d,$ab,$0a,$2a,$72,$c3,$00,$8b,$67,$e5,$e9
	dc.b	$28,$68,$57,$c7,$ff,$ea,$b3,$8f,$78,$ff,$12,$95,$6c,$44,$d3,$52
	dc.b	$e7,$dc,$ff,$89,$4d,$38,$4d,$b3,$82,$55,$52,$89,$23,$06,$82,$9d
	dc.b	$66,$50,$d6,$f2,$e5,$69,$04,$88,$8b,$08,$f0,$97,$55,$d1,$3a,$0e
	dc.b	$22,$c8,$aa,$b4,$22,$35,$91,$0a,$9a,$44,$d7,$01,$d5,$05,$bb,$3d
	dc.b	$6c,$01,$79,$2c,$34,$66,$4b,$96,$1e,$a8,$72,$38,$4d,$d2,$2e,$fd
	dc.b	$4a,$c1,$6f,$4e,$08,$c5,$2b,$b0,$4a,$2c,$33,$9c,$34,$ec,$05,$68
	dc.b	$ee,$54,$de,$13,$ca,$44,$44,$63,$c6,$42,$6c,$a8,$6b,$30,$1b,$63
	dc.b	$40,$a7,$4e,$45,$10,$47,$46,$ef,$3b,$60,$7e,$b0,$c3,$14,$01,$64
	dc.b	$4a,$5d,$45,$e5,$54,$20,$0c,$a3,$1b,$0a,$fe,$4f,$cf,$43,$e3,$5d
	dc.b	$93,$28,$d6,$04,$cc,$70,$59,$80,$f3,$a1,$30,$3b,$fc,$ac,$a1,$a0
	dc.b	$46,$4a,$f9,$54,$65,$8f,$b9,$db,$a8,$b1,$7b,$66,$33,$50,$af,$ea
	dc.b	$8b,$17,$b0,$df,$56,$e2,$22,$19,$29,$d4,$26,$ce,$34,$3a,$c6,$5a
	dc.b	$ed,$b2,$e5,$2c,$3d,$48,$83,$aa,$07,$67,$50,$ee,$93,$5c,$86,$82
	dc.b	$bf,$14,$08,$db,$be,$10,$23,$7e,$37,$51,$d5,$0c,$56,$11,$66,$73
	dc.b	$84,$85,$d9,$30,$06,$6d,$f1,$f7,$ec,$1a,$7a,$d3,$ae,$ce,$e9,$42
	dc.b	$a2,$03,$77,$8e,$17,$22,$8f,$c8,$43,$6e,$d3,$ce,$af,$81,$5d,$e3
	dc.b	$8b,$a7,$8d,$4f,$5e,$c6,$f1,$60,$ce,$e7,$14,$fd,$4c,$af,$8e,$f5
	dc.b	$b7,$78,$e9,$e6,$60,$6c,$94,$03,$90,$04,$61,$cf,$ae,$19,$9a,$72
	dc.b	$cd,$c6,$59,$cb,$93,$6c,$d7,$03,$a4,$46,$6a,$3d,$ef,$3d,$ce,$28
	dc.b	$fe,$35,$c5,$d6,$99,$19,$b2,$c5,$80,$39,$58,$76,$00,$c5,$5a,$29
	dc.b	$9d,$2c,$3d,$72,$fa,$54,$51,$e8,$d0,$4e,$06,$72,$1a,$39,$57,$6c
	dc.b	$d3,$92,$2e,$8f,$b7,$9a,$e1,$ca,$36,$cd,$73,$50,$a5,$61,$3b,$e3
	dc.b	$92,$d2,$0c,$a4,$71,$ca,$d1,$9f,$cf,$ce,$ed,$01,$82,$12,$0c,$12
	dc.b	$52,$1c,$65,$ec,$94,$51,$8a,$30,$d5,$93,$06,$87,$f2,$76,$af,$86
	dc.b	$14,$40,$a4,$f4,$4e,$de,$84,$cc,$f7,$30,$3f,$dd,$98,$1b,$c8,$ed
	dc.b	$aa,$7c,$b3,$60,$5c,$b6,$33,$30,$05,$6c,$8b,$ca,$0f,$bc,$cb,$f9
	dc.b	$b9,$5d,$81,$4d,$12,$b2,$d7,$a3,$ed,$e8,$8a,$19,$28,$1c,$6e,$cc
	dc.b	$2a,$e2,$63,$a1,$68,$67,$27,$f5,$d1,$60,$41,$10,$c5,$20,$f3,$ec
	dc.b	$c9,$ed,$d0,$d0,$f2,$d8,$94,$3a,$d1,$52,$2f,$73,$2c,$27,$e6,$69
	dc.b	$6d,$59,$5c,$1e,$2d,$b2,$1b,$aa,$e2,$bf,$5f,$00,$be,$3d,$bd,$2d
	dc.b	$32,$85,$76,$46,$bc,$84,$42,$d5,$63,$2c,$8c,$c9,$cb,$36,$c0,$24
	dc.b	$7c,$e5,$74,$b8,$49,$8a,$20,$05,$50,$91,$01,$c5,$e8,$29,$0b,$a5
	dc.b	$36,$d5,$cc,$05,$16,$aa,$43,$12,$29,$3d,$36,$85,$8a,$f7,$e4,$95
	dc.b	$b0,$63,$20,$7e,$91,$e4,$bf,$35,$0b,$f8,$f3,$11,$01,$f5,$e2,$4d
	dc.b	$e5,$1c,$5b,$0e,$cd,$26,$83,$1e,$50,$1c,$bb,$48,$6c,$40,$86,$76
	dc.b	$61,$01,$96,$f2,$69,$26,$9e,$f6,$bf,$5e,$16,$2c,$27,$2c,$79,$e6
	dc.b	$c0,$8d,$23,$c8,$dd,$d6,$57,$d3,$f8,$8e,$ac,$64,$3e,$02,$a9,$11
	dc.b	$26,$ec,$05,$70,$be,$f0,$41,$a6,$33,$95,$c7,$62,$43,$8c,$cc,$ac
	dc.b	$76,$74,$10,$e7,$39,$fd,$e4,$86,$d5,$e0,$a8,$98,$75,$63,$97,$60
	dc.b	$ef,$9e,$7d,$12,$e3,$dd,$ce,$d0,$b1,$02,$ed,$01,$04,$0f,$28,$3c
	dc.b	$37,$16,$66,$5a,$c8,$19,$5e,$28,$5a,$88,$30,$e8,$90,$f0,$19,$f1
	dc.b	$96,$26,$2a,$9e,$57,$e9,$ab,$84,$76,$32,$c8,$0a,$18,$bf,$9b,$aa
	dc.b	$ef,$83,$5a,$b1,$48,$64,$a7,$e2,$04,$ff,$7d,$43,$09,$a9,$88,$4d
	dc.b	$44,$48,$e4,$57,$db,$77,$54,$3f,$ce,$a2,$9e,$50,$95,$b8,$f9,$5d
	dc.b	$ca,$f3,$1d,$89,$01,$fb,$48,$51,$0a,$05,$ce,$4f,$4e,$57,$9d,$39
	dc.b	$0d,$51,$35,$03,$a5,$aa,$cb,$77,$dc,$6b,$dc,$98,$88,$e9,$02,$8a
	dc.b	$44,$40,$03,$c8,$b4,$97,$2e,$9f,$40,$b1,$a5,$f0,$25,$2b,$a4,$f7
	dc.b	$95,$cb,$07,$da,$ae,$c7,$cd,$0f,$12,$e1,$e2,$b7,$95,$37,$07,$6a
	dc.b	$75,$eb,$84,$78,$9f,$da,$59,$0c,$3a,$92,$03,$90,$ea,$ef,$05,$b0
	dc.b	$77,$c9,$34,$40,$5b,$ee,$89,$26,$2b,$53,$57,$64,$ec,$56,$0c,$f2
	dc.b	$b2,$0b,$e5,$43,$4d,$31,$5d,$42,$89,$09,$5b,$8e,$57,$55,$33,$9f
	dc.b	$5e,$b9,$12,$75,$98,$d3,$79,$c5,$0a,$e1,$ec,$1e,$b3,$a1,$68,$66
	dc.b	$bf,$7a,$98,$b0,$5e,$56,$c0,$8c,$53,$17,$55,$00,$b6,$9b,$d0,$04
	dc.b	$7a,$06,$2f,$43,$63,$c8,$e6,$a6,$52,$49,$22,$96,$79,$54,$57,$3e
	dc.b	$cf,$dc,$a9,$38,$28,$79,$52,$b9,$6e,$f2,$ad,$0d,$60,$c2,$da,$1c
	dc.b	$e7,$4b,$a5,$e2,$8d,$c2,$58,$b0,$91,$00,$56,$b0,$4e,$a3,$9f,$a9
	dc.b	$36,$bd,$5d,$6d,$6f,$e3,$32,$47,$c6,$e2,$83,$b2,$31,$aa,$79,$76
	dc.b	$51,$d5,$71,$0c,$f2,$4e,$36,$00,$67,$23,$5a,$bf,$46,$5e,$b1,$3b
	dc.b	$5d,$14,$61,$5d,$d7,$d3,$52,$c6,$ac,$2d,$bc,$d1,$12,$d9,$f4,$42
	dc.b	$58,$93,$62,$99,$71,$56,$c1,$3d,$4c,$6a,$a7,$4b,$46,$6d,$64,$fa
	dc.b	$40,$72,$2c,$70,$d6,$4b,$b1,$0c,$82,$38,$27,$a4,$ea,$75,$79,$4e
	dc.b	$c6,$5d,$20,$15,$8c,$05,$39,$7f,$ee,$d6,$c6,$a4,$51,$e8,$03,$23
	dc.b	$1b,$60,$b6,$2f,$cf,$fa,$75,$55,$fc,$7f,$a7,$54,$6c,$49,$05,$d0
	dc.b	$b6,$8c,$ec,$7f,$75,$cb,$79,$42,$cc,$e5,$02,$91,$2d,$8c,$7b,$6b
	dc.b	$0a,$e2,$a9,$cc,$79,$10,$70,$dc,$6a,$c1,$5e,$96,$19,$79,$5f,$5c
	dc.b	$79,$c4,$aa,$6b,$56,$1b,$29,$8e,$a8,$3c,$65,$eb,$9b,$6f,$eb,$d7
	dc.b	$cf,$3d,$f3,$a6,$a0,$75,$e6,$d6,$cc,$c2,$2a,$ba,$4e,$f0,$4a,$4c
	dc.b	$7d,$9e,$57,$08,$82,$63,$a9,$8c,$02,$32,$19,$eb,$3c,$33,$ce,$ba
	dc.b	$30,$02,$70,$99,$62,$db,$26,$74,$40,$d0,$d4,$47,$9c,$51,$fc,$40
	dc.b	$21,$a1,$cd,$42,$40,$36,$bd,$0f,$8c,$a2,$e2,$13,$35,$22,$2d,$5f
	dc.b	$b2,$bd,$58,$91,$92,$2a,$73,$65,$23,$a8,$b9,$5c,$e5,$d6,$48,$45
	dc.b	$f9,$86,$ba,$4f,$e4,$b4,$31,$48,$88,$1b,$06,$4e,$89,$6d,$82,$9a
	dc.b	$7e,$3d,$3a,$a0,$d6,$7e,$9d,$4f,$b1,$bb,$9b,$b9,$f5,$5e,$ec,$77
	dc.b	$fa,$88,$97,$4e,$a4,$5d,$89,$08,$e1,$6c,$09,$3b,$28,$86,$b0,$f5
	dc.b	$e3,$3a,$98,$a4,$56,$08,$8e,$51,$8e,$a9,$38,$54,$83,$9c,$03,$24
	dc.b	$54,$b4,$87,$3c,$a6,$cc,$75,$23,$f1,$35,$69,$d1,$55,$62,$76,$75
	dc.b	$bf,$ae,$3b,$97,$88,$ac,$5a,$16,$c3,$d6,$d4,$4c,$1a,$19,$e9,$75
	dc.b	$6d,$49,$0e,$61,$35,$29,$d5,$f3,$1e,$aa,$a8,$1b,$73,$d0,$bc,$d8
	dc.b	$5f,$d0,$1f,$36,$a1,$35,$ab,$91,$bf,$1d,$93,$24,$a4,$8b,$b6,$90
	dc.b	$e4,$cd,$23,$1a,$87,$45,$18,$d8,$87,$d6,$a8,$b8,$82,$59,$78,$d2
	dc.b	$8b,$b1,$55,$15,$44,$c9,$bf,$25,$b7,$ff,$ca,$74,$ec,$1a,$e7,$1c
	dc.b	$3a,$cc,$d3,$a2,$b7,$86,$15,$de,$ed,$33,$94,$d7,$1f,$0e,$b2,$b2
	dc.b	$51,$ba,$f7,$0a,$be,$ce,$a9,$3f,$f6,$cc,$a3,$59,$35,$de,$d3,$c3
	dc.b	$8c,$2b,$44,$10,$64,$1b,$28,$42,$39,$bb,$12,$c0,$1f,$85,$7a,$64
	dc.b	$69,$ac,$98,$a6,$c8,$a6,$ba,$01,$8f,$ae,$8d,$ee,$0e,$60,$34,$8a
	dc.b	$bb,$22,$bf,$4e,$6f,$46,$de,$d6,$d5,$75,$68,$7c,$89,$8d,$41,$77
	dc.b	$7b,$23,$1f,$44,$a2,$36,$8a,$d0,$d1,$0f,$a0,$70,$26,$9a,$94,$75
	dc.b	$2d,$1b,$4f,$44,$ac,$f0,$e0,$7b,$ac,$d6,$ae,$98,$8d,$58,$3b,$b2
	dc.b	$7a,$cd,$76,$18,$b3,$c0,$c9,$16,$48,$64,$fa,$0c,$de,$d2,$02,$a3
	dc.b	$56,$e2,$09,$79,$f1,$37,$4d,$94,$08,$3d,$9f,$a4,$91,$fc,$d0,$3e
	dc.b	$d0,$d5,$d8,$34,$d5,$1c,$5a,$cb,$59,$65,$f8,$d1,$6a,$ef,$6c,$5e
	dc.b	$25,$79,$4d,$be,$9b,$03,$cb,$25,$1e,$9d,$7f,$84,$da,$7f,$57,$2e
	dc.b	$65,$21,$44,$76,$3a,$f5,$3e,$dd,$e3,$24,$66,$49,$24,$fc,$ea,$b9
	dc.b	$fa,$a8,$67,$d5,$0c,$dd,$e3,$57,$79,$47,$bb,$11,$6a,$f0,$b9,$15
	dc.b	$a9,$6c,$31,$d5,$c1,$7c,$2b,$5a,$3b,$e0,$6c,$1a,$e0,$49,$48,$c9
	dc.b	$ad,$43,$b0,$73,$fd,$c4,$e2,$2f,$0b,$a9,$a7,$4d,$6a,$07,$a3,$1b
	dc.b	$35,$78,$b9,$05,$8e,$e9,$e8,$58,$89,$50,$1a,$e5,$2d,$51,$4c,$87
	dc.b	$a8,$d2,$4b,$b8,$ac,$c4,$dc,$ba,$90,$6a,$e5,$26,$05,$79,$19,$50
	dc.b	$8e,$e5,$d3,$f2,$01,$79,$e6,$5c,$90,$75,$7d,$16,$a4,$70,$2f,$70
	dc.b	$ea,$c0,$e2,$ba,$29,$92,$ea,$7a,$cb,$af,$2b,$a1,$7b,$e0,$bb,$e3
	dc.b	$a8,$12,$5e,$c2,$2b,$11,$ab,$31,$2d,$36,$61,$72,$bd,$04,$4d,$97
	dc.b	$2b,$d6,$65,$93,$29,$33,$dc,$56,$3b,$39,$df,$b6,$51,$bd,$1b,$bc
	dc.b	$ef,$be,$db,$8b,$eb,$57,$b2,$7c,$20,$54,$ad,$86,$b7,$d9,$e6,$6b
	dc.b	$91,$27,$54,$07,$f1,$84,$14,$cb,$76,$1d,$eb,$c0,$d4,$95,$3e,$bc
	dc.b	$96,$ff,$b0,$3e,$52,$13,$16,$5e,$8c,$34,$78,$a0,$a0,$f0,$88,$74
	dc.b	$e4,$6a,$f3,$87,$2b,$74,$14,$d9,$2c,$18,$af,$a5,$9c,$11,$00,$13
	dc.b	$b6,$01,$58,$81,$33,$2c,$f6,$6f,$15,$3e,$28,$27,$e2,$9b,$27,$7a
	dc.b	$cc,$8c,$a8,$5e,$9a,$4c,$34,$74,$04,$c8,$32,$41,$d6,$d4,$4c,$fa
	dc.b	$64,$7a,$d9,$ab,$9e,$60,$7b,$97,$39,$53,$9a,$79,$58,$47,$2c,$d6
	dc.b	$2e,$1c,$e6,$9f,$93,$98,$b8,$cc,$77,$e9,$b2,$8f,$3a,$75,$51,$95
	dc.b	$16,$be,$ae,$5f,$0f,$f3,$80,$74,$79,$c2,$af,$67,$39,$66,$bc,$ad
	dc.b	$ea,$fc,$e1,$4d,$10,$d9,$9c,$b3,$46,$71,$82,$2c,$e9,$0d,$9c,$58
	dc.b	$72,$eb,$9c,$e5,$e6,$f3,$ae,$c9,$a7,$ac,$d1,$d1,$25,$62,$ec,$f3
	dc.b	$1e,$58,$4c,$f7,$2c,$e9,$e2,$7e,$da,$3b,$50,$39,$30,$a4,$02,$ca
	dc.b	$84,$d9,$99,$ec,$5f,$8c,$f0,$1a,$5f,$77,$2e,$af,$76,$48,$70,$ae
	dc.b	$59,$98,$dd,$7f,$33,$22,$fb,$f3,$15,$52,$20,$11,$93,$2e,$54,$68
	dc.b	$9f,$59,$28,$9e,$e2,$be,$9b,$28,$8a,$89,$16,$a2,$22,$e7,$7d,$69
	dc.b	$cc,$fd,$75,$5a,$de,$c9,$c1,$25,$48,$4a,$c0,$f5,$90,$30,$4e,$44
	dc.b	$93,$2d,$59,$ff,$7e,$10,$dc,$8a,$3c,$79,$44,$b5,$7c,$c6,$71,$49
	dc.b	$8a,$33,$8f,$54,$25,$64,$5e,$fe,$4b,$67,$17,$c9,$9a,$ae,$eb,$07
	dc.b	$27,$84,$29,$f1,$b1,$18,$6e,$55,$1c,$b9,$c5,$28,$8e,$a3,$99,$92
	dc.b	$5a,$be,$57,$ee,$46,$96,$3c,$4a,$dc,$46,$e3,$a7,$ca,$16,$dd,$63
	dc.b	$54,$e9,$87,$46,$89,$f1,$be,$ee,$59,$9d,$1e,$72,$d0,$a4,$61,$39
	dc.b	$05,$2a,$c0,$87,$95,$03,$67,$0d,$78,$11,$b4,$12,$4f,$8c,$58,$02
	dc.b	$47,$eb,$a5,$f9,$2b,$31,$1f,$64,$0f,$d7,$36,$f7,$0f,$45,$d2,$e0
	dc.b	$fd,$1a,$39,$a3,$af,$85,$09,$fe,$ac,$93,$6d,$f2,$de,$67,$cb,$9b
	dc.b	$83,$3e,$6c,$2e,$9b,$45,$f4,$4b,$d9,$39,$e2,$c0,$d1,$ce,$26,$82
	dc.b	$c4,$9c,$dd,$d9,$5d,$6f,$8b,$be,$f8,$51,$1f,$d0,$d1,$6e,$b0,$f3
	dc.b	$f6,$1d,$61,$ab,$ee,$3a,$cb,$5c,$99,$57,$48,$8e,$fc,$21,$cc,$df
	dc.b	$9e,$b7,$ab,$21,$36,$11,$d5,$f5,$2f,$b7,$ad,$46,$8c,$e5,$e2,$87
	dc.b	$4a,$d4,$79,$f8,$a2,$57,$bc,$11,$7a,$28,$4f,$f6,$9f,$fa,$e9,$7c
	dc.b	$93,$2f,$f1,$0a,$a2,$b4,$7b,$c0,$b7,$a6,$72,$a9,$00,$f6,$06,$60
	dc.b	$09,$4e,$5c,$f5,$66,$69,$29,$7f,$ce,$29,$ba,$0a,$16,$f4,$17,$d9
	dc.b	$f5,$d9,$e1,$f1,$5d,$a3,$c3,$d1,$04,$58,$b9,$80,$63,$c1,$b5,$92
	dc.b	$6e,$3e,$4f,$33,$b2,$b0,$9b,$96,$b6,$b8,$dd,$0f,$7b,$0f,$6c,$9c
	dc.b	$ed,$60,$68,$e6,$5c,$a0,$b1,$24,$4f,$79,$23,$16,$1e,$01,$81,$58
	dc.b	$d1,$e2,$6a,$3d,$af,$14,$e8,$33,$57,$cc,$e5,$57,$23,$4a,$9c,$9d
	dc.b	$6b,$61,$bd,$f1,$aa,$44,$6d,$94,$b6,$aa,$23,$65,$13,$a6,$4b,$8e
	dc.b	$6b,$34,$bd,$4f,$aa,$3c,$a7,$e6,$7a,$d1,$16,$94,$69,$46,$0d,$1d
	dc.b	$60,$8b,$98,$eb,$02,$bc,$1b,$db,$b4,$53,$20,$95,$98,$1c,$7c,$a7
	dc.b	$2a,$ff,$95,$b3,$d7,$d0,$13,$b8,$32,$03,$c8,$5b,$42,$f8,$06,$d1
	dc.b	$93,$04,$6e,$eb,$ec,$b1,$94,$69,$eb,$4f,$59,$f7,$fe,$49,$fe,$6a
	dc.b	$e6,$c4,$05,$2f,$85,$09,$bd,$b2,$4c,$b4,$ae,$e7,$e4,$60,$73,$65
	dc.b	$d3,$3d,$d5,$85,$e7,$3d,$b7,$7e,$cf,$0b,$03,$47,$26,$b5,$f2,$8f
	dc.b	$94,$ff,$bf,$57,$e4,$9e,$09,$9b,$b0,$7b,$11,$bb,$4b,$dc,$fe,$2d
	dc.b	$d8,$02,$22,$a2,$b5,$69,$69,$d4,$ee,$3e,$82,$5b,$f6,$e3,$94,$a5
	dc.b	$15,$f6,$3c,$60,$27,$22,$ec,$b7,$0d,$dc,$5b,$8b,$e0,$1c,$85,$28
	dc.b	$dd,$e0,$c8,$9b,$64,$9a,$66,$43,$07,$f1,$b4,$5b,$12,$1b,$a2,$64
	dc.b	$7e,$4f,$44,$cb,$22,$98,$02,$69,$78,$dc,$8d,$dc,$ba,$62,$63,$c1
	dc.b	$70,$d4,$07,$92,$15,$c6,$7c,$03,$93,$ab,$55,$0d,$04,$d5,$dd,$d6
	dc.b	$2c,$d5,$c2,$d1,$9d,$66,$86,$98,$f4,$89,$d9,$99,$ca,$48,$71,$8c
	dc.b	$4e,$c8,$0e,$d2,$b2,$71,$c1,$f2,$f4,$76,$49,$e6,$f7,$3b,$2c,$e7
	dc.b	$c7,$92,$46,$b9,$4a,$0d,$12,$4e,$e5,$00,$e1,$5c,$3e,$bd,$e2,$7e
	dc.b	$d6,$06,$0d,$0d,$2a,$54,$1b,$fe,$69,$dd,$12,$83,$87,$2a,$d9,$46
	dc.b	$90,$dc,$4f,$df,$65,$9d,$d9,$89,$cf,$eb,$73,$e5,$fb,$7d,$bd,$b1
	dc.b	$47,$21,$1f,$4a,$66,$87,$57,$8b,$03,$35,$34,$46,$c9,$d4,$0d,$4b
	dc.b	$24,$8e,$33,$e5,$61,$b1,$7d,$75,$b1,$21,$a5,$8e,$37,$e2,$aa,$32
	dc.b	$db,$88,$5f,$1c,$e2,$b2,$51,$bb,$94,$98,$c2,$05,$c7,$8f,$41,$ca
	dc.b	$7f,$6c,$16,$93,$91,$59,$35,$4e,$65,$b1,$3f,$60,$61,$fe,$ae,$13
	dc.b	$79,$65,$82,$da,$43,$fd,$db,$cd,$4a,$36,$03,$0f,$64,$05,$76,$27
	dc.b	$4f,$e1,$a7,$da,$1d,$53,$1c,$47,$bd,$9a,$9a,$fe,$1c,$76,$4f,$ba
	dc.b	$4a,$0d,$1f,$31,$4d,$00,$37,$b8,$49,$e6,$1f,$69,$81,$da,$43,$86
	dc.b	$88,$d8,$0b,$c6,$c8,$fd,$2f,$3b,$6b,$8e,$c1,$a5,$db,$d1,$1a,$b4
	dc.b	$aa,$d7,$47,$74,$b9,$77,$6f,$76,$72,$df,$8d,$8a,$f4,$ff,$5e,$e5
	dc.b	$45,$99,$d6,$6f,$cb,$7a,$be,$84,$4d,$01,$3b,$d2,$50,$99,$45,$46
	dc.b	$d0,$d9,$92,$35,$ed,$a1,$59,$dd,$60,$49,$0d,$84,$5c,$34,$80,$92
	dc.b	$bb,$43,$c4,$34,$9d,$bc,$b5,$1c,$ab,$1d,$4d,$f3,$48,$6a,$51,$fd
	dc.b	$42,$bb,$5f,$bf,$72,$9e,$31,$74,$a0,$3c,$15,$c2,$bf,$e6,$77,$87
	dc.b	$89,$3f,$66,$a7,$82,$9c,$88,$16,$be,$87,$50,$2f,$69,$06,$54,$ed
	dc.b	$2f,$13,$ff,$93,$95,$3f,$68,$78,$b2,$d3,$c7,$2c,$26,$a5,$82,$58
	dc.b	$eb,$47,$61,$34,$a2,$bc,$13,$f9,$2f,$16,$41,$57,$63,$d3,$26,$48
	dc.b	$b4,$17,$33,$d4,$9e,$d3,$d6,$2f,$37,$93,$d7,$a6,$51,$02,$4d,$17
	dc.b	$a7,$ff,$b4,$ab,$03,$ae,$23,$90,$0a,$6e,$d5,$a7,$26,$3e,$0d,$8f
	dc.b	$f3,$b4,$c9,$15,$50,$87,$ba,$c6,$b7,$6a,$d9,$01,$e5,$44,$a2,$a2
	dc.b	$d7,$d0,$ea,$05,$e3,$22,$a4,$77,$60,$0a,$b1,$95,$2b,$19,$7c,$39
	dc.b	$8b,$b8,$49,$06,$66,$26,$87,$f2,$08,$a0,$da,$95,$5f,$6c,$55,$6d
	dc.b	$71,$e8,$90,$bd,$56,$0d,$63,$af,$10,$4e,$d1,$b2,$b5,$9f,$2e,$70
	dc.b	$ce,$03,$4a,$15,$a8,$e8,$3e,$da,$c7,$da,$b4,$70,$03,$93,$28,$8a
	dc.b	$15,$e5,$8b,$65,$67,$5d,$6a,$97,$d0,$cc,$e8,$1b,$b6,$6e,$c9,$fd
	dc.b	$e1,$b5,$b0,$75,$02,$d1,$04,$77,$95,$54,$a1,$8b,$cc,$40,$99,$8b
	dc.b	$4b,$f9,$6c,$e2,$1b,$93,$de,$9e,$6b,$87,$3e,$72,$dc,$1e,$bb,$88
	dc.b	$a8,$77,$08,$b0,$ff,$60,$df,$db,$4d,$62,$3c,$03,$84,$c1,$ec,$fe
	dc.b	$d5,$b2,$49,$ad,$83,$e6,$f8,$a6,$7e,$da,$0d,$58,$32,$8f,$7f,$d4
	dc.b	$b9,$9c,$c8,$2b,$27,$c0,$85,$06,$8f,$b3,$fc,$17,$1f,$0a,$e1,$24
	dc.b	$eb,$59,$6e,$ef,$2e,$d9,$5d,$95,$44,$8f,$a6,$cd,$37,$f3,$55,$49
	dc.b	$79,$5c,$78,$5e,$c3,$e6,$3a,$55,$ed,$2f,$2c,$b3,$2e,$f7,$63,$a0
	dc.b	$d6,$b1,$fb,$bf,$3b,$63,$a8,$96,$a9,$ae,$cb,$c9,$68,$9b,$0d,$0a
	dc.b	$3b,$bb,$86,$91,$2e,$53,$f6,$f2,$dd,$ba,$d6,$51,$d4,$bc,$4b,$b2
	dc.b	$4c,$d3,$44,$8f,$f1,$bb,$67,$54,$2d,$10,$4b,$be,$76,$11,$72,$07
	dc.b	$f5,$4a,$a9,$68,$47,$31,$04,$c5,$76,$72,$0f,$ae,$f5,$b2,$50,$af
	dc.b	$de,$84,$5f,$39,$3b,$fc,$30,$f2,$d7,$00,$5a,$69,$70,$d4,$c5,$3d
	dc.b	$c2,$96,$9e,$e5,$20,$e4,$9b,$df,$64,$e3,$f2,$07,$c9,$d4,$47,$e4
	dc.b	$f1,$76,$db,$2f,$a6,$5e,$57,$4d,$06,$ca,$d9,$d4,$ca,$14,$59,$e5
	dc.b	$0c,$83,$44,$97,$bd,$62,$76,$71,$4f,$69,$57,$2a,$4d,$ef,$da,$47
	dc.b	$73,$00,$e7,$47,$fb,$b8,$83,$67,$32,$1d,$3c,$db,$24,$ae,$60,$3a
	dc.b	$2f,$27,$c7,$7c,$d8,$cb,$e4,$c8,$6a,$29,$aa,$34,$6f,$0d,$a2,$49
	dc.b	$bb,$fb,$be,$18,$a1,$dc,$34,$a3,$cd,$3b,$44,$a1,$4d,$dc,$fb,$da
	dc.b	$dd,$15,$6f,$b4,$4c,$ca,$4d,$ee,$1b,$d2,$43,$8d,$b5,$10,$44,$ba
	dc.b	$ea,$8a,$5b,$02,$b4,$fa,$38,$24,$86,$88,$fd,$d5,$03,$1d,$69,$86
	dc.b	$81,$9b,$01,$53,$3e,$1a,$53,$2d,$02,$63,$e8,$c0,$4c,$58,$0a,$89
	dc.b	$e6,$fa,$d6,$b8,$a6,$5a,$95,$f2,$a8,$8a,$13,$d6,$40,$4b,$70,$6c
	dc.b	$b9,$e0,$ea,$8a,$14,$51,$d2,$b0,$b1,$39,$ea,$64,$bf,$27,$66,$ce
	dc.b	$a6,$51,$05,$4f,$28,$1c,$1a,$24,$b6,$c6,$f8,$b1,$8a,$66,$ab,$6c
	dc.b	$d2,$27,$a6,$14,$bc,$40,$51,$16,$e8,$b0,$dc,$f4,$87,$1f,$0c,$59
	dc.b	$a5,$e4,$91,$0f,$1c,$6f,$c2,$18,$9a,$ed,$46,$f5,$73,$1a,$b6,$02
	dc.b	$be,$58,$ff,$14,$45,$98,$68,$3e,$d4,$a4,$03,$5b,$0d,$dc,$90,$b5
	dc.b	$00,$ef,$5d,$e5,$1b,$42,$fe,$ce,$bd,$35,$45,$09,$e8,$f3,$d8,$49
	dc.b	$ad,$88,$e1,$26,$f2,$a4,$34,$e5,$46,$67,$ad,$c0,$51,$aa,$3e,$b9
	dc.b	$ee,$89,$23,$e5,$d8,$bb,$53,$b0,$30,$4f,$61,$b8,$13,$da,$28,$29
	dc.b	$0e,$45,$e9,$60,$14,$8c,$c2,$76,$5a,$97,$a5,$76,$9f,$19,$69,$f0
	dc.b	$33,$7a,$82,$a3,$76,$49,$b6,$15,$e1,$b3,$4f,$e1,$d5,$17,$87,$56
	dc.b	$91,$0e,$de,$f5,$68,$bf,$ca,$4d,$6b,$27,$c2,$85,$25,$1c,$6b,$94
	dc.b	$be,$b3,$ec,$cd,$90,$e3,$ef,$2e,$b1,$91,$54,$1d,$d9,$94,$6b,$19
	dc.b	$96,$3e,$ab,$53,$9f,$31,$a9,$08,$a4,$38,$c1,$8d,$ad,$a2,$20,$85
	dc.b	$a9,$ca,$2b,$65,$10,$a3,$85,$ad,$be,$ca,$5b,$57,$0e,$ac,$3d,$e6
	dc.b	$97,$a4,$80,$1d,$80,$7a,$6b,$61,$19,$80,$94,$4b,$e9,$db,$86,$37
	dc.b	$14,$0d,$f3,$b3,$5e,$0d,$31,$51,$a8,$b5,$bd,$20,$0f,$2b,$62,$61
	dc.b	$74,$c6,$f5,$a8,$18,$d4,$59,$c2,$95,$48,$35,$a7,$0f,$ad,$33,$1d
	dc.b	$65,$71,$6c,$a6,$60,$2a,$44,$30,$d3,$45,$70,$a6,$49,$f1,$39,$a2
	dc.b	$61,$dd,$bb,$ef,$db,$37,$cb,$91,$a2,$e7,$dc,$f8,$fb,$e8,$8a,$0d
	dc.b	$ec,$93,$26,$bd,$fd,$9f,$2c,$41,$83,$0a,$67,$c0,$3d,$e6,$9a,$27
	dc.b	$55,$93,$e1,$22,$92,$8e,$29,$a5,$b0,$1f,$3b,$80,$21,$59,$4d,$6e
	dc.b	$58,$f2,$e4,$69,$19,$90,$6d,$d4,$ef,$87,$fa,$a4,$c6,$98,$d4,$3b
	dc.b	$85,$21,$c6,$63,$55,$ac,$55,$a8,$2b,$49,$0a,$ee,$87,$c0,$38,$f4
	dc.b	$7e,$a6,$96,$d4,$93,$ab,$f7,$b7,$fc,$a2,$6d,$f4,$52,$1c,$a5,$89
	dc.b	$c8,$39,$ed,$54,$ec,$db,$b7,$88,$c8,$88,$44,$d1,$37,$99,$2a,$46
	dc.b	$06,$c6,$16,$6d,$59,$3c,$38,$2e,$3f,$49,$08,$b4,$44,$ee,$79,$45
	dc.b	$d0,$22,$28,$8c,$eb,$48,$c2,$de,$2a,$b6,$5b,$62,$42,$4a,$96,$26
	dc.b	$7d,$76,$2a,$3f,$66,$7f,$52,$51,$ba,$d3,$08,$9a,$5b,$05,$80,$d4
	dc.b	$2b,$8a,$91,$0a,$5d,$e5,$29,$83,$e5,$46,$ae,$c4,$3b,$f6,$75,$fc
	dc.b	$6a,$34,$3f,$f3,$da,$ce,$fd,$bd,$71,$ca,$65,$e3,$63,$90,$d6,$ef
	dc.b	$15,$83,$7e,$69,$f2,$81,$95,$19,$8a,$d2,$b1,$45,$ef,$f6,$51,$9f
	dc.b	$cd,$75,$5b,$f4,$23,$b0,$c5,$98,$73,$12,$83,$69,$6b,$39,$9d,$33
	dc.b	$83,$4e,$d4,$de,$36,$07,$16,$1c,$4b,$58,$6a,$cf,$dc,$2f,$c5,$10
	dc.b	$af,$d8,$0d,$5a,$c3,$2c,$21,$ee,$24,$9e,$bb,$21,$12,$32,$22,$59
	dc.b	$20,$af,$0a,$e2,$33,$11,$e6,$6a,$8e,$74,$da,$2e,$37,$f1,$ea,$da
	dc.b	$e7,$96,$8f,$ac,$84,$0c,$8a,$36,$d3,$8f,$94,$17,$fa,$18,$5b,$28
	dc.b	$13,$82,$a8,$9d,$bf,$d7,$b9,$ec,$38,$d9,$71,$c6,$01,$8d,$68,$7e
	dc.b	$09,$81,$cb,$4b,$42,$0d,$7a,$2e,$77,$a6,$56,$01,$a8,$79,$49,$23
	dc.b	$76,$ff,$5d,$ef,$80,$b3,$67,$01,$2a,$0d,$24,$5e,$64,$2a,$5e,$79
	dc.b	$7c,$f4,$22,$dc,$a6,$41,$ac,$72,$1a,$7b,$e4,$b5,$3d,$d9,$44,$71
	dc.b	$c8,$e0,$e5,$ac,$11,$52,$5a,$f3,$09,$2b,$39,$66,$2e,$d5,$af,$39
	dc.b	$e5,$c2,$e2,$88,$14,$ed,$e5,$bd,$8f,$d0,$7b,$bf,$94,$8f,$47,$0e
	dc.b	$6a,$bd,$e3,$74,$b3,$96,$3d,$ae,$c5,$98,$7f,$44,$48,$8f,$d8,$31
	dc.b	$fd,$e2,$64,$1c,$1a,$17,$4c,$b8,$96,$f1,$65,$19,$06,$49,$1a,$a3
	dc.b	$dd,$6a,$be,$21,$5e,$7a,$55,$48,$71,$b5,$2a,$00,$b8,$83,$90,$5f
	dc.b	$a8,$ca,$1b,$32,$b6,$76,$31,$11,$14,$80,$37,$a6,$53,$4f,$88,$0c
	dc.b	$42,$8c,$e2,$72,$e2,$fc,$4b,$2d,$29,$f6,$84,$ee,$ff,$3e,$54,$e2
	dc.b	$0f,$fe,$ef,$88,$53,$99,$dd,$75,$4c,$4b,$12,$dd,$d4,$38,$9a,$76
	dc.b	$38,$98,$fc,$29,$02,$7a,$7e,$54,$fc,$38,$8b,$ff,$17,$f1,$0a,$4a
	dc.b	$a5,$37,$10,$ad,$9e,$24,$9e,$c7,$10,$9f,$b5,$f8,$85,$49,$f2,$bb
	dc.b	$f1,$0a,$1b,$10,$9f,$a6,$e2,$62,$e9,$62,$14,$8a,$ac,$78,$85,$4a
	dc.b	$e2,$49,$ec,$71,$19,$25,$88,$b0,$e5,$f8,$62,$ac,$18,$d8,$f2,$5a
	dc.b	$93,$68,$49,$6a,$04,$4b,$1f,$cf,$92,$5a,$bf,$70,$aa,$82,$a7,$16
	dc.b	$48,$c9,$b8,$a2,$53,$fc,$31,$52,$92,$32,$36,$08,$e7,$72,$bc,$6f
	dc.b	$4a,$17,$76,$a6,$25,$d4,$b7,$75,$54,$45,$bc,$3d,$b0,$55,$8b,$0c
	dc.b	$8c,$ff,$9c,$46,$31,$62,$01,$39,$8c,$d7,$cb,$a3,$01,$33,$3f,$2a
	dc.b	$78,$65,$fa,$0d,$39,$a9,$14,$8d,$be,$72,$06,$47,$b3,$8d,$5a,$39
	dc.b	$5e,$37,$c2,$c2,$fe,$3c,$53,$ae,$7f,$17,$2a,$a3,$37,$d8,$f8,$07
	dc.b	$fc,$e8,$39,$62,$0d,$4f,$41,$9d,$f4,$4e,$5c,$1d,$b2,$df,$8d,$df
	dc.b	$3b,$bc,$ed,$97,$d3,$ed,$99,$21,$3a,$3c,$fa,$e3,$5a,$8e,$51,$77
	dc.b	$ae,$a5,$b0,$40,$d6,$68,$b0,$a4,$38,$d2,$0b,$38,$8d,$3e,$65,$61
	dc.b	$bb,$08,$e7,$23,$88,$f7,$80,$44,$0c,$90,$04,$15,$2a,$bf,$3f,$c3
	dc.b	$d5,$f6,$ec,$b1,$10,$18,$77,$f5,$fb,$b6,$0c,$71,$78,$32,$8f,$21
	dc.b	$de,$d0,$97,$93,$57,$d0,$e9,$37,$f5,$47,$02,$7d,$70,$e1,$b4,$ec
	dc.b	$3d,$43,$5e,$51,$06,$1d,$e2,$fc,$70,$ad,$dc,$09,$d6,$1d,$b6,$ec
	dc.b	$d7,$7c,$f5,$9f,$e8,$2d,$fc,$8e,$30,$59,$b9,$4c,$88,$98,$b0,$ca
	dc.b	$4c,$2d,$98,$05,$3c,$9a,$46,$7b,$da,$11,$e2,$16,$57,$f8,$99,$15
	dc.b	$1f,$01,$8d,$2e,$ea,$62,$fd,$8d,$4a,$23,$8b,$e3,$8e,$07,$70,$bc
	dc.b	$58,$93,$e9,$17,$75,$42,$d5,$51,$07,$02,$a2,$e6,$6b,$d3,$65,$cd
	dc.b	$6a,$3d,$a8,$cc,$1f,$9e,$8f,$b9,$af,$f6,$c2,$35,$af,$14,$51,$cf
	dc.b	$cc,$4e,$88,$73,$2c,$88,$1b,$85,$32,$40,$5a,$06,$e1,$61,$68,$a4
	dc.b	$32,$0d,$62,$c4,$b0,$12,$a9,$06,$29,$1c,$d4,$26,$83,$0e,$30,$74
	dc.b	$5d,$08,$71,$4e,$c4,$80,$22,$63,$1c,$bb,$26,$e7,$6c,$20,$60,$b9
	dc.b	$3a,$fb,$cc,$f7,$3d,$83,$18,$1e,$05,$75,$69,$b0,$d6,$2d,$3c,$2d
	dc.b	$52,$f3,$68,$f3,$8a,$97,$02,$bf,$40,$c6,$ec,$f3,$5e,$f1,$9c,$78
	dc.b	$68,$93,$af,$ba,$18,$05,$62,$91,$fb,$d5,$91,$f6,$be,$b9,$85,$4c
	dc.b	$6f,$e5,$fc,$bb,$cf,$d3,$ce,$72,$c9,$f2,$41,$ac,$b7,$dd,$98,$1a
	dc.b	$8e,$62,$37,$59,$fa,$2f,$4b,$1c,$af,$63,$0c,$ef,$4d,$bc,$26,$dc
	dc.b	$33,$8e,$e6,$0f,$76,$1a,$a6,$2c,$cd,$0a,$6b,$1d,$f5,$9b,$76,$85
	dc.b	$88,$0f,$bd,$d0,$57,$84,$b7,$d2,$26,$b9,$e1,$35,$b4,$5a,$c3,$5a
	dc.b	$8e,$41,$34,$87,$78,$be,$35,$a8,$28,$63,$a3,$ae,$d3,$44,$89,$79
	dc.b	$ab,$43,$68,$eb,$12,$59,$25,$c1,$bf,$28,$75,$b6,$19,$0e,$3c,$31
	dc.b	$2c,$3f,$65,$58,$ee,$61,$74,$0c,$34,$ba,$e3,$05,$52,$38,$9c,$40
	dc.b	$74,$a7,$68,$c4,$3d,$bf,$f2,$73,$3d,$75,$b9,$db,$01,$e0,$6b,$a4
	dc.b	$79,$e8,$fd,$83,$19,$ce,$20,$f9,$bf,$37,$6b,$43,$13,$b1,$c6,$47
	dc.b	$b4,$d8,$45,$e1,$77,$17,$08,$92,$e3,$3d,$83,$2c,$09,$f9,$44,$9d
	dc.b	$d1,$08,$09,$49,$be,$26,$f9,$5c,$87,$5b,$33,$c3,$bc,$e7,$62,$f6
	dc.b	$5e,$dc,$4e,$bb,$c9,$51,$a1,$1a,$ac,$9d,$7d,$9b,$4b,$22,$7a,$c6
	dc.b	$50,$d0,$f2,$c3,$81,$db,$4b,$34,$76,$da,$30,$4f,$17,$c5,$54,$83
	dc.b	$df,$12,$b1,$77,$c5,$34,$65,$73,$26,$b3,$6c,$6f,$16,$1a,$01,$c4
	dc.b	$bb,$32,$04,$d0,$e1,$0d,$e3,$ff,$a2,$1a,$90,$64,$72,$58,$7b,$25
	dc.b	$11,$ba,$47,$14,$79,$bc,$fc,$a7,$1d,$ac,$bc,$a4,$18,$3d,$f3,$21
	dc.b	$e9,$de,$70,$f8,$df,$13,$70,$c1,$3f,$2e,$47,$ec,$a8,$9d,$1f,$09
	dc.b	$70,$61,$c6,$d1,$00,$f3,$a3,$02,$74,$49,$6c,$01,$12,$4b,$9c,$88
	dc.b	$b1,$af,$6f,$76,$c2,$32,$67,$42,$bf,$2b,$c7,$04,$2f,$43,$ee,$e4
	dc.b	$c8,$de,$ca,$96,$9e,$02,$a5,$f4,$9d,$71,$70,$d5,$e1,$5b,$c5,$69
	dc.b	$be,$25,$80,$c7,$92,$43,$25,$ba,$08,$68,$af,$df,$99,$b1,$46,$48
	dc.b	$ef,$a5,$89,$e8,$d7,$96,$b7,$99,$82,$a4,$4a,$54,$68,$26,$ab,$dd
	dc.b	$81,$ec,$0e,$62,$2f,$74,$ed,$da,$17,$14,$9c,$35,$46,$94,$61,$f3
	dc.b	$dc,$30,$d5,$49,$ef,$85,$60,$cb,$59,$b7,$e8,$af,$e0,$6d,$1c,$ac
	dc.b	$b3,$46,$de,$9d,$78,$ec,$ca,$08,$95,$11,$a4,$47,$03,$70,$73,$50
	dc.b	$ec,$65,$06,$cb,$f9,$4b,$74,$cc,$ba,$17,$a3,$8a,$06,$b4,$d1,$1a
	dc.b	$fe,$aa,$5b,$35,$45,$c7,$27,$69,$6a,$25,$87,$d1,$29,$9d,$4f,$5e
	dc.b	$14,$11,$2f,$48,$7c,$1b,$85,$3b,$04,$dd,$3c,$39,$90,$37,$11,$03
	dc.b	$a1,$29,$be,$22,$1e,$b8,$c5,$f3,$b1,$f7,$aa,$32,$32,$96,$b9,$1e
	dc.b	$1a,$01,$f4,$79,$4a,$6f,$ad,$c3,$50,$36,$1d,$5e,$db,$97,$d4,$c8
	dc.b	$55,$88,$6e,$6e,$c5,$c4,$87,$00,$94,$92,$35,$a7,$79,$b6,$51,$d3
	dc.b	$67,$50,$1f,$35,$28,$62,$f4,$51,$b8,$5d,$67,$2b,$32,$33,$2a,$35
	dc.b	$da,$02,$ac,$06,$06,$3e,$ce,$ef,$94,$99,$a5,$f3,$34,$9b,$c3,$a9
	dc.b	$6b,$cc,$66,$18,$ca,$e0,$75,$5a,$a2,$cd,$f9,$1b,$ed,$b1,$37,$0c
	dc.b	$8c,$ef,$21,$29,$d3,$63,$e2,$74,$b8,$47,$38,$6a,$54,$bb,$18,$c8
	dc.b	$40,$99,$90,$3d,$a6,$31,$f3,$80,$a2,$b1,$36,$a9,$1f,$2d,$b5,$9c
	dc.b	$1a,$f2,$95,$41,$ce,$0b,$51,$b5,$20,$d0,$34,$3c,$da,$cb,$ca,$71
	dc.b	$93,$90,$f5,$e6,$87,$f6,$c3,$fa,$f1,$79,$40,$4a,$57,$8c,$e2,$18
	dc.b	$92,$38,$1b,$64,$d7,$53,$b5,$b1,$f4,$64,$0b,$d7,$37,$05,$b3,$82
	dc.b	$1c,$ed,$11,$51,$ca,$2d,$c9,$4b,$e3,$bf,$af,$95,$e0,$d7,$48,$35
	dc.b	$e0,$94,$bd,$8d,$33,$a3,$5f,$10,$fd,$b5,$67,$eb,$e0,$0c,$5a,$ac
	dc.b	$88,$0e,$49,$79,$24,$8d,$a3,$e0,$7c,$d3,$90,$de,$1d,$44,$5a,$0b
	dc.b	$f6,$68,$fd,$15,$5e,$eb,$37,$ce,$73,$5b,$ab,$2a,$35,$ca,$24,$ac
	dc.b	$33,$72,$d9,$7c,$50,$9d,$97,$6a,$44,$e9,$ca,$00,$f1,$5f,$9f,$95
	dc.b	$e0,$2c,$7d,$25,$d4,$77,$85,$d8,$ec,$35,$5a,$eb,$87,$b8,$5a,$83
	dc.b	$4b,$be,$6f,$24,$2c,$58,$69,$77,$2c,$57,$51,$87,$19,$ee,$a7,$ac
	dc.b	$f7,$a3,$8f,$12,$5d,$40,$5b,$d5,$bd,$b7,$d7,$7c,$52,$47,$b5,$22
	dc.b	$3c,$d2,$49,$da,$c3,$67,$2d,$4f,$5b,$18,$79,$10,$f6,$5c,$b6,$b7
	dc.b	$c7,$7e,$b9,$de,$54,$97,$86,$58,$3d,$f3,$57,$4c,$7b,$cb,$e4,$20
	dc.b	$17,$94,$09,$85,$9a,$c5,$e3,$5f,$d7,$5e,$80,$cd,$2d,$ce,$fe,$f4
	dc.b	$f9,$44,$95,$2c,$ec,$2d,$ce,$f2,$5f,$7d,$3f,$47,$c1,$1e,$6e,$0d
	dc.b	$79,$57,$a4,$84,$ef,$b6,$a7,$ac,$32,$cb,$63,$7d,$9e,$90,$28,$87
	dc.b	$02,$85,$7f,$b6,$79,$44,$48,$cd,$47,$5b,$03,$53,$b5,$f7,$92,$9f
	dc.b	$84,$c4,$fc,$ea,$df,$31,$07,$da,$f9,$1f,$58,$be,$65,$ae,$08,$f6
	dc.b	$cd,$cb,$28,$5c,$b5,$d3,$1c,$f4,$77,$e0,$fe,$42,$d8,$5b,$37,$d4
	dc.b	$85,$05,$a0,$b2,$cf,$63,$bd,$d8,$6a,$f3,$a1,$f3,$be,$f2,$61,$d5
	dc.b	$bb,$e2,$9c,$a0,$37,$5b,$93,$ed,$9d,$f0,$61,$15,$4e,$29,$9d,$86
	dc.b	$9f,$04,$68,$0c,$fb,$ef,$c3,$c7,$71,$80,$f8,$09,$41,$1a,$8f,$28
	dc.b	$1b,$33,$a2,$76,$8e,$22,$52,$d9,$9a,$87,$93,$95,$37,$95,$e6,$d2
	dc.b	$29,$15,$b0,$57,$cf,$43,$a4,$87,$cf,$ee,$21,$e7,$68,$ee,$42,$07
	dc.b	$21,$03,$48,$18,$0e,$99,$63,$78,$cc,$de,$54,$5b,$42,$d7,$04,$77
	dc.b	$8c,$78,$0f,$85,$f5,$80,$d9,$d2,$1a,$78,$89,$d2,$9c,$1a,$1e,$8b
	dc.b	$de,$da,$c7,$c6,$d5,$01,$8a,$96,$c2,$92,$06,$b2,$78,$d1,$16,$b5
	dc.b	$f9,$f8,$75,$22,$70,$ea,$1d,$34,$99,$73,$9d,$67,$52,$d3,$74,$d8
	dc.b	$c5,$a9,$e3,$2a,$35,$b0,$e3,$08,$0e,$c4,$19,$28,$dd,$e6,$18,$24
	dc.b	$41,$e2,$c5,$96,$c7,$d6,$3f,$d6,$a8,$2c,$0a,$e4,$f1,$ec,$c3,$fc
	dc.b	$40,$ce,$57,$65,$d0,$49,$8b,$4c,$3a,$95,$fa,$23,$6d,$2f,$55,$ea
	dc.b	$5b,$15,$3c,$e8,$07,$5d,$66,$02,$8d,$d1,$c6,$80,$cf,$89,$d7,$7f
	dc.b	$1e,$a3,$56,$c6,$5d,$83,$4f,$3c,$a5,$ce,$9d,$56,$c0,$88,$5a,$36
	dc.b	$ad,$e6,$ec,$3d,$da,$a7,$4d,$10,$80,$d4,$9e,$31,$92,$0c,$71,$a9
	dc.b	$76,$48,$42,$e9,$ae,$42,$1a,$a8,$40,$3a,$97,$d0,$81,$7c,$d5,$9f
	dc.b	$89,$09,$94,$da,$a2,$18,$bb,$0e,$39,$5d,$16,$0f,$b6,$5e,$26,$5b
	dc.b	$11,$77,$df,$af,$b9,$86,$a7,$13,$cf,$06,$8a,$40,$5f,$57,$81,$fe
	dc.b	$bb,$44,$9a,$2c,$46,$cf,$0b,$43,$cb,$f8,$c4,$05,$22,$2c,$d7,$8d
	dc.b	$8d,$af,$bd,$c2,$b9,$2a,$ec,$eb,$a9,$79,$c9,$5e,$fd,$39,$3b,$3e
	dc.b	$4d,$4d,$1c,$6d,$94,$2d,$76,$1c,$c9,$a6,$a6,$23,$bd,$e7,$56,$1d
	dc.b	$ce,$a4,$f7,$e2,$8a,$a3,$4e,$bf,$15,$8a,$e0,$58,$15,$8a,$a9,$f6
	dc.b	$e1,$7c,$2d,$bf,$14,$37,$3e,$08,$19,$15,$c9,$36,$42,$cb,$a2,$06
	dc.b	$e6,$d2,$c9,$79,$5c,$8f,$ce,$60,$38,$7b,$19,$89,$38,$b0,$a2,$d5
	dc.b	$26,$ad,$da,$df,$e6,$0f,$aa,$6e,$ce,$28,$37,$c3,$ca,$05,$ee,$51
	dc.b	$3a,$9d,$55,$f8,$8e,$f4,$b0,$44,$49,$d7,$e3,$9c,$ea,$49,$60,$aa
	dc.b	$98,$80,$69,$ba,$6d,$83,$04,$d0,$b8,$cc,$48,$08,$de,$99,$2c,$26
	dc.b	$8d,$f0,$3b,$00,$76,$74,$4b,$57,$a4,$2d,$71,$36,$55,$11,$ea,$b3
	dc.b	$42,$58,$83,$2e,$97,$cf,$47,$30,$f5,$63,$39,$ad,$ed,$47,$89,$57
	dc.b	$74,$57,$47,$9b,$02,$b7,$37,$d8,$85,$d2,$77,$a6,$84,$7c,$d8,$89
	dc.b	$b3,$4d,$3a,$7d,$ad,$7e,$c5,$c7,$f7,$c9,$67,$f9,$d7,$4b,$97,$62
	dc.b	$fd,$75,$a4,$fa,$5d,$19,$9a,$e4,$e0,$d5,$d8,$46,$b4,$02,$e8,$1c
	dc.b	$63,$88,$72,$0f,$f1,$12,$5f,$29,$51,$e2,$1f,$39,$b8,$84,$16,$10
	dc.b	$6a,$0d,$f0,$aa,$b4,$d1,$3b,$5a,$17,$c7,$7e,$ed,$79,$19,$c5,$47
	dc.b	$44,$e3,$f6,$7d,$29,$ae,$bc,$39,$a0,$e1,$31,$6f,$00,$fd,$30,$35
	dc.b	$41,$96,$1f,$f3,$87,$07,$db,$11,$92,$41,$6c,$72,$ba,$a7,$c5,$2b
	dc.b	$7d,$21,$48,$dd,$1f,$6f,$31,$18,$73,$a9,$cd,$c1,$a3,$59,$33,$08
	dc.b	$51,$78,$71,$ed,$68,$60,$f7,$ef,$90,$80,$ea,$98,$0f,$bd,$32,$5f
	dc.b	$88,$b9,$de,$8f,$db,$00,$61,$74,$65,$44,$1a,$bf,$b1,$d8,$3b,$e1
	dc.b	$ac,$6f,$33,$a0,$84,$cf,$f0,$e8,$e3,$cb,$35,$5e,$34,$74,$b5,$bc
	dc.b	$3d,$0a,$85,$e0,$dc,$ed,$d5,$6a,$b1,$3c,$37,$ab,$9f,$ee,$6b,$28
	dc.b	$e4,$92,$37,$8c,$de,$3a,$9b,$43,$d8,$bc,$b8,$ea,$65,$a8,$9b,$80
	dc.b	$bf,$d3,$85,$ea,$e4,$f0,$71,$33,$2a,$34,$97,$50,$fd,$61,$c6,$96
	dc.b	$d8,$31,$e5,$22,$38,$db,$12,$2e,$32,$69,$12,$c0,$c3,$fc,$14,$82
	dc.b	$c1,$a8,$3b,$0e,$1b,$df,$14,$45,$a8,$51,$6b,$71,$6d,$27,$bf,$f7
	dc.b	$fb,$bf,$29,$e7,$8f,$be,$fd,$72,$3e,$7c,$6f,$92,$13,$68,$ea,$fd
	dc.b	$f2,$a7,$3e,$8e,$74,$09,$e5,$a2,$5c,$0c,$d2,$13,$be,$3a,$c9,$d9
	dc.b	$e5,$2e,$af,$db,$e3,$b0,$2e,$a6,$b5,$27,$b2,$16,$58,$cc,$79,$39
	dc.b	$fd,$6d,$0c,$70,$8c,$1c,$2e,$3c,$ba,$4b,$43,$de,$0c,$0e,$c5,$e4
	dc.b	$21,$c4,$61,$cb,$bd,$78,$5e,$42,$60,$ee,$40,$2f,$23,$2d,$6d,$77
	dc.b	$a8,$7e,$3a,$1d,$86,$7d,$88,$b5,$2d,$12,$20,$3a,$fb,$5e,$0c,$84
	dc.b	$d6,$c6,$79,$4f,$1c,$d8,$9a,$73,$cd,$66,$0d,$53,$f3,$3e,$4f,$dc
	dc.b	$de,$e9,$d5,$29,$57,$7d,$b2,$4e,$89,$b0,$29,$49,$05,$9f,$6f,$39
	dc.b	$70,$3f,$fb,$33,$2d,$05,$a6,$f4,$eb,$76,$ff,$8e,$08,$f3,$2c,$92
	dc.b	$6e,$49,$aa,$f4,$2a,$c3,$84,$7a,$48,$31,$6d,$2b,$67,$3a,$fd,$e0
	dc.b	$e2,$d2,$3c,$18,$1b,$3a,$33,$72,$84,$1a,$a9,$66,$fe,$4f,$14,$3c
	dc.b	$55,$47,$53,$21,$f9,$c2,$3a,$f9,$76,$fc,$ad,$c7,$d7,$2f,$eb,$3d
	dc.b	$2c,$11,$f6,$13,$71,$54,$cd,$11,$27,$7b,$a5,$01,$1a,$ae,$47,$ee
	dc.b	$11,$c2,$00,$4a,$20,$b2,$f2,$ca,$87,$76,$a5,$8e,$bb,$88,$e6,$b0
	dc.b	$ec,$d3,$a5,$6c,$99,$2c,$31,$94,$e8,$fa,$1a,$69,$89,$38,$84,$6e
	dc.b	$32,$22,$a8,$42,$39,$db,$90,$98,$cc,$d6,$19,$2e,$fd,$3b,$9c,$1e
	dc.b	$33,$11,$d3,$2a,$d9,$76,$ce,$82,$6f,$42,$e5,$49,$ed,$39,$50,$7a
	dc.b	$e2,$af,$e4,$5c,$ca,$63,$4d,$bb,$5c,$a1,$ff,$e3,$e5,$15,$17,$cc
	dc.b	$e9,$65,$14,$b2,$9f,$ca,$27,$fc,$79,$4c,$58,$0a,$a1,$04,$0c,$2b
	dc.b	$be,$67,$2c,$ce,$66,$3f,$3a,$e3,$56,$91,$f5,$ef,$b5,$98,$c1,$f6
	dc.b	$1c,$c2,$7f,$c7,$99,$8f,$f4,$fc,$df,$6c,$c6,$1d,$73,$ee,$65,$ff
	dc.b	$85,$d2,$87,$99,$5f,$f8,$f3,$18,$d6,$4f,$31,$24,$08,$c8,$cc,$83
	dc.b	$d7,$3c,$a0,$87,$ef,$35,$8e,$03,$14,$d0,$0e,$ef,$6e,$47,$b9,$e1
	dc.b	$89,$d8,$92,$43,$54,$76,$d1,$03,$57,$44,$58,$cb,$e5,$5a,$b3,$5c
	dc.b	$b8,$1e,$67,$42,$fe,$87,$8e,$fa,$39,$94,$0e,$0c,$c6,$fd,$bf,$94
	dc.b	$92,$4b,$2f,$12,$a6,$2c,$06,$6f,$61,$17,$97,$02,$05,$2e,$b7,$10
	dc.b	$6b,$f3,$6b,$74,$86,$4c,$47,$d4,$65,$60,$56,$3b,$60,$7d,$55,$4e
	dc.b	$96,$7f,$45,$ab,$0c,$d7,$1a,$b4,$92,$1b,$df,$e2,$2e,$e5,$ee,$9a
	dc.b	$f5,$f8,$19,$07,$f6,$be,$11,$36,$69,$ac,$f6,$1a,$f9,$b1,$a0,$fa
	dc.b	$57,$c3,$eb,$82,$48,$32,$c4,$a2,$0d,$cf,$32,$ff,$37,$49,$16,$fd
	dc.b	$c3,$75,$0d,$c0,$19,$3d,$bf,$94,$b8,$96,$36,$ae,$02,$76,$1a,$8e
	dc.b	$df,$41,$4f,$06,$87,$f5,$fc,$3c,$cd,$01,$6c,$85,$c9,$9a,$24,$ef
	dc.b	$1d,$69,$35,$ac,$27,$76,$bb,$00,$4e,$65,$c2,$89,$7e,$6c,$78,$18
	dc.b	$bc,$52,$38,$0c,$e2,$05,$ab,$da,$fc,$78,$ac,$0b,$ff,$a6,$58,$0c
	dc.b	$b9,$16,$90,$7c,$05,$ff,$95,$8f,$d4,$38,$4c,$ab,$f0,$b9,$6a,$70
	dc.b	$a7,$fc,$ec,$26,$26,$f0,$4c,$bb,$d1,$4f,$ea,$5f,$c2,$3f,$f8,$5f
	dc.b	$19,$1c,$e1,$e8,$2d,$38,$70,$8f,$fc,$d7,$b7,$85,$8f,$f8,$7b,$79
	dc.b	$5b,$02,$31,$5c,$dc,$ee,$1f,$92,$b8,$9c,$65,$9a,$fc,$41,$7a,$18
	dc.b	$69,$23,$15,$15,$e4,$ff,$5e,$b8,$69,$6a,$b4,$83,$c3,$a4,$40,$1b
	dc.b	$29,$51,$dc,$93,$57,$bd,$a8,$b4,$e5,$7b,$a5,$2f,$42,$f0,$e3,$57
	dc.b	$6d,$e8,$6a,$59,$1a,$e5,$4a,$6b,$0d,$1f,$3e,$26,$f0,$03,$de,$18
	dc.b	$14,$5e,$74,$25,$e5,$0d,$26,$46,$1b,$90,$58,$cb,$c3,$07,$bb,$41
	dc.b	$60,$d3,$24,$d3,$49,$5e,$f0,$29,$d7,$7a,$29,$75,$7d,$d1,$1a,$b9
	dc.b	$9f,$05,$91,$e2,$0c,$6f,$3e,$ed,$78,$f4,$a6,$b4,$19,$26,$fc,$85
	dc.b	$3b,$06,$5b,$6a,$2f,$2a,$0c,$34,$64,$9b,$f0,$f4,$10,$5a,$d4,$20
	dc.b	$d5,$a1,$5f,$de,$29,$87,$8d,$07,$d6,$7d,$00,$2b,$1d,$0c,$20,$d6
	dc.b	$0d,$2a,$8b,$80,$1d,$c8,$5c,$45,$a3,$91,$01,$b5,$61,$77,$0d,$5e
	dc.b	$d4,$19,$76,$7a,$a5,$6a,$9f,$2a,$53,$5d,$f1,$5a,$40,$ea,$c0,$8f
	dc.b	$75,$56,$10,$f8,$cf,$ee,$70,$08,$f1,$73,$d0,$e7,$52,$bb,$b7,$51
	dc.b	$47,$a7,$f4,$38,$cc,$56,$a5,$1c,$29,$13,$e6,$57,$1c,$9c,$48,$24
	dc.b	$e6,$1f,$d1,$63,$1e,$dd,$fe,$df,$c9,$49,$d9,$21,$75,$12,$6c,$cd
	dc.b	$4b,$23,$40,$b5,$4a,$c4,$93,$de,$30,$8b,$58,$df,$48,$35,$eb,$a6
	dc.b	$03,$18,$9a,$9a,$c2,$ae,$03,$3a,$7b,$f3,$bb,$1c,$95,$2b,$15,$27
	dc.b	$4e,$69,$9a,$39,$86,$da,$b1,$13,$84,$ab,$a8,$2b,$e9,$7b,$e7,$f0
	dc.b	$08,$23,$f8,$e6,$af,$87,$36,$f5,$d6,$90,$6a,$39,$11,$2e,$09,$2d
	dc.b	$19,$48,$6e,$0d,$06,$ac,$ba,$22,$b0,$14,$53,$fa,$32,$a0,$de,$e5
	dc.b	$05,$95,$a0,$7e,$20,$a5,$52,$0c,$bb,$50,$1e,$a3,$55,$fd,$18,$f6
	dc.b	$da,$20,$31,$d9,$21,$d9,$d5,$7b,$bc,$2a,$81,$ea,$95,$ae,$6b,$7b
	dc.b	$79,$37,$c5,$6a,$b1,$42,$b0,$23,$6b,$2f,$53,$e4,$3e,$f8,$cc,$66
	dc.b	$a5,$dd,$07,$18,$85,$35,$67,$b5,$c5,$71,$3e,$57,$2f,$ec,$b0,$7e
	dc.b	$db,$1c,$29,$10,$04,$ae,$3b,$bf,$d1,$ed,$b6,$b4,$f7,$56,$35,$11
	dc.b	$34,$5b,$cd,$48,$0d,$58,$b1,$21,$00,$4f,$59,$1a,$09,$a8,$34,$69
	dc.b	$69,$b7,$d5,$02,$67,$e8,$4d,$5b,$83,$73,$db,$96,$c4,$26,$75,$7b
	dc.b	$5c,$57,$b8,$d6,$a5,$5a,$5e,$ac,$d6,$c8,$2f,$25,$00,$f5,$ab,$21
	dc.b	$53,$46,$f7,$8a,$11,$01,$7a,$b9,$8c,$27,$fb,$72,$3d,$af,$80,$7e
	dc.b	$3d,$7b,$73,$5a,$b2,$1c,$55,$f0,$ee,$43,$ac,$c8,$93,$30,$70,$91
	dc.b	$4c,$3b,$a2,$d5,$b1,$6c,$52,$9a,$90,$92,$27,$a7,$bf,$49,$5d,$ae
	dc.b	$cf,$b6,$66,$e9,$29,$dd,$c7,$9a,$99,$77,$bc,$0c,$ab,$7a,$45,$c6
	dc.b	$3b,$a0,$1e,$d3,$b3,$ae,$d5,$dd,$ae,$2b,$81,$ba,$8b,$b9,$bc,$35
	dc.b	$d6,$47,$f0,$36,$c6,$98,$ce,$8c,$e4,$0a,$c5,$53,$ec,$e3,$f7,$d2
	dc.b	$76,$ca,$78,$ac,$90,$15,$e6,$2f,$36,$3f,$8a,$8a,$ff,$59,$e2,$f2
	dc.b	$97,$62,$22,$90,$06,$c8,$9f,$76,$6f,$e8,$c5,$ff,$f7,$e0,$fe,$32
	dc.b	$f5,$ac,$06,$a0,$57,$60,$3b,$b3,$eb,$3f,$64,$69,$77,$46,$59,$58
	dc.b	$15,$98,$e1,$ba,$72,$d9,$ba,$f3,$45,$b6,$12,$50,$ff,$d3,$e5,$32
	dc.b	$a0,$d4,$d7,$f0,$9c,$85,$ac,$14,$b6,$23,$fc,$28,$95,$4e,$1f,$a7
	dc.b	$b3,$e2,$25,$dd,$24,$04,$ef,$b0,$a2,$c7,$7d,$ef,$09,$35,$b6,$7e
	dc.b	$4c,$a0,$82,$3e,$50,$80,$24,$84,$5e,$79,$4d,$85,$57,$85,$e7,$21
	dc.b	$6a,$70,$ea,$0b,$cc,$5e,$68,$80,$fa,$cf,$19,$12,$8e,$d1,$ed,$83
	dc.b	$95,$09,$68,$5a,$e9,$20,$ea,$27,$88,$70,$68,$5f,$98,$3d,$ba,$d6
	dc.b	$97,$ca,$e6,$df,$cd,$49,$28,$8c,$ea,$44,$a2,$57,$74,$65,$be,$db
	dc.b	$38,$a7,$d3,$90,$2b,$fb,$3a,$df,$fa,$78,$41,$42,$f7,$92,$cf,$a4
	dc.b	$05,$5a,$43,$88,$4d,$d8,$fb,$d4,$bc,$b6,$c2,$36,$10,$f8,$a0,$48
	dc.b	$18,$9e,$d6,$64,$32,$7e,$e7,$e5,$f9,$66,$4b,$3e,$13,$54,$92,$38
	dc.b	$e8,$0c,$9f,$7e,$13,$2b,$52,$37,$95,$81,$56,$2a,$69,$41,$c8,$5a
	dc.b	$13,$e8,$97,$24,$01,$e6,$2d,$96,$53,$9a,$9a,$fc,$38,$63,$49,$68
	dc.b	$e5,$8a,$78,$ac,$c5,$48,$6f,$73,$73,$ab,$50,$80,$9a,$77,$2d,$eb
	dc.b	$61,$ad,$9e,$f3,$f4,$03,$54,$58,$dc,$11,$2a,$25,$54,$04,$bc,$ec
	dc.b	$79,$10,$67,$89,$73,$b8,$97,$7a,$f2,$9a,$1b,$61,$47,$27,$de,$7b
	dc.b	$d0,$6c,$30,$d6,$12,$34,$cd,$e9,$a8,$b5,$67,$21,$13,$41,$0e,$41
	dc.b	$60,$d0,$a0,$70,$46,$24,$e9,$03,$c2,$01,$5a,$2d,$27,$57,$b4,$eb
	dc.b	$03,$2a,$36,$9c,$56,$e8,$13,$4d,$b5,$65,$76,$3b,$3e,$6f,$56,$9d
	dc.b	$56,$ad,$dd,$73,$7b,$6d,$ce,$ef,$b4,$0a,$07,$4a,$a5,$b3,$2a,$5d
	dc.b	$4a,$bb,$6d,$c9,$67,$74,$ba,$ed,$af,$53,$db,$66,$cb,$e8,$f6,$5b
	dc.b	$7e,$2f,$27,$d7,$25,$a5,$59,$2d,$78,$dc,$8e,$6b,$49,$a9,$de,$f4
	dc.b	$7b,$b2,$6a,$35,$66,$bd,$74,$bc,$e5,$b3,$3a,$ad,$6f,$1b,$97,$e5
	dc.b	$9b,$53,$29,$f5,$4a,$d5,$96,$d9,$8e,$c9,$e5,$34,$dd,$3e,$df,$70
	dc.b	$11,$2b,$9a,$5b,$b5,$1a,$cf,$4f,$aa,$53,$2e,$a2,$55,$6a,$f8,$9d
	dc.b	$16,$9f,$85,$d7,$9a,$ce,$ac,$f8,$5d,$0f,$32,$7b,$42,$b8,$e7,$b9
	dc.b	$54,$8b,$96,$fb,$b3,$53,$ae,$5d,$af,$5b,$c0,$3c,$ce,$73,$58,$b4
	dc.b	$62,$f9,$d2,$c9,$8d,$8a,$e7,$8c,$03,$4d,$e7,$76,$fb,$bd,$ee,$fb
	dc.b	$86,$dc,$79,$b8,$9e,$cf,$74,$8a,$87,$61,$ce,$7c,$a2,$52,$4b,$1f
	dc.b	$23,$9f,$23,$cc,$78,$a4,$3a,$fe,$c7,$7b,$c9,$19,$a3,$e1,$3e,$d2
	dc.b	$70,$2c,$76,$83,$8f,$d8,$78,$7c,$7f,$58,$a7,$9e,$a1,$82,$c8,$71
	dc.b	$fe,$78,$8f,$8c,$6f,$0f,$c3,$97,$c5,$62,$d8,$38,$d5,$7e,$f9,$9f
	dc.b	$02,$44,$e7,$92,$8e,$84,$36,$fd,$81,$9f,$7a,$3d,$fc,$1e,$fd,$c2
	dc.b	$f1,$17,$fb,$c2,$62,$33,$88,$e4,$7b,$41,$30,$85,$7d,$3f,$3f,$a8
	dc.b	$5c,$3b,$7f,$fb,$01,$c6,$21,$96,$08,$2c,$fe,$ff,$10,$84,$48,$28
	dc.b	$1f,$08,$34,$12,$3f,$f8,$87,$ff,$7f,$90,$7f,$07,$02,$04,$00,$01
	dc.b	$40,$ff,$d8,$08,$08,$07,$ff,$00,$02,$03,$88,$04,$41,$b1,$29,$13
	dc.b	$c6,$24,$6d,$76,$25,$61,$0e,$e6,$d3,$8c,$8e,$d3,$62,$3c,$5e,$0c
	dc.b	$4b,$69,$7e,$ef,$cd,$8e,$5d,$78,$14,$a9,$12,$76,$d9,$7b,$97,$9a
	dc.b	$bb,$96,$97,$c7,$ea,$1b,$a7,$94,$41,$d5,$c3,$cd,$7d,$01,$0c,$2e
	dc.b	$e1,$ea,$fb,$6b,$a0,$f0,$b4,$56,$ed,$6b,$b2,$4a,$5a,$f0,$0e,$ed
	dc.b	$d0,$66,$59,$bf,$b6,$ec,$69,$e0,$7f,$eb,$b9,$a2,$6a,$c4,$11,$c3
	dc.b	$45,$81,$da,$1f,$33,$02,$e1,$20,$cb,$79,$2b,$d8,$f0,$ea,$6b,$49
	dc.b	$b2,$f8,$2d,$63,$fd,$54,$fc,$8b,$b8,$73,$16,$a6,$55,$65,$c9,$53
	dc.b	$eb,$0c,$cb,$d7,$61,$06,$81,$d3,$f0,$dc,$c6,$a8,$59,$95,$5b,$22
	dc.b	$ef,$1c,$05,$31,$6b,$33,$2a,$30,$7c,$af,$32,$12,$bd,$d2,$7c,$fc
	dc.b	$52,$0a,$21,$c5,$26,$f6,$12,$02,$b3,$79,$87,$07,$e4,$29,$43,$41
	dc.b	$ab,$12,$a2,$e6,$00,$ee,$8b,$f4,$fb,$7b,$cb,$20,$c4,$d8,$0d,$3c
	dc.b	$9b,$dc,$ef,$7a,$b6,$21,$ab,$0e,$a8,$4d,$f9,$bc,$5f,$10,$36,$11
	dc.b	$95,$bc,$95,$ef,$3e,$b9,$79,$55,$a8,$75,$33,$fe,$1d,$b2,$56,$2f
	dc.b	$74,$a0,$e6,$aa,$6a,$cd,$a6,$a1,$df,$48,$4a,$d7,$dc,$f2,$b1,$d5
	dc.b	$60,$38,$81,$c2,$bb,$1f,$01,$7f,$bb,$7d,$7f,$c5,$a2,$69,$87,$70
	dc.b	$9f,$c3,$6a,$71,$e9,$70,$7b,$91,$84,$57,$f6,$c7,$87,$57,$3f,$31
	dc.b	$c9,$db,$6a,$20,$e8,$82,$23,$45,$01,$50,$fa,$a2,$7c,$9b,$55,$1b
	dc.b	$4b,$c2,$85,$30,$76,$ff,$36,$e0,$df,$a5,$ee,$33,$57,$62,$46,$de
	dc.b	$e9,$b5,$4c,$ab,$e9,$4d,$72,$99,$7d,$8f,$dc,$c2,$92,$bf,$bd,$82
	dc.b	$29,$b9,$21,$86,$6c,$f9,$83,$af,$ea,$56,$bd,$5a,$55,$c1,$ac,$3d
	dc.b	$cb,$13,$43,$7c,$85,$3e,$fe,$d7,$ec,$e8,$23,$55,$cc,$51,$fa,$78
	dc.b	$6c,$0c,$cb,$35,$7e,$f4,$10,$de,$ed,$ef,$44,$1b,$7f,$01,$0b,$e8
	dc.b	$98,$8d,$1b,$35,$80,$6b,$f6,$7c,$49,$65,$70,$0b,$72,$cb,$9a,$56
	dc.b	$a1,$f5,$9f,$12,$06,$e5,$8d,$54,$48,$06,$71,$a4,$ef,$db,$1f,$ca
	dc.b	$9c,$15,$61,$6f,$28,$a8,$16,$b1,$47,$41,$05,$0a,$ef,$48,$2e,$06
	dc.b	$95,$f6,$68,$2f,$7f,$0f,$79,$f1,$f7,$ec,$6f,$79,$4b,$c7,$a6,$46
	dc.b	$7d,$73,$1e,$3e,$6c,$bb,$a0,$6b,$b5,$96,$dd,$a6,$7b,$9b,$22,$2c
	dc.b	$ae,$44,$6a,$36,$5e,$44,$ac,$46,$c9,$13,$07,$3c,$df,$34,$eb,$82
	dc.b	$71,$fa,$a8,$eb,$36,$a2,$05,$c4,$6e,$5f,$c2,$5c,$56,$25,$51,$5f
	dc.b	$a9,$bd,$6f,$1d,$33,$e9,$de,$c1,$10,$bd,$01,$a0,$d7,$73,$03,$2c
	dc.b	$42,$54,$2b,$e2,$29,$38,$45,$2d,$c1,$5b,$e3,$e2,$5e,$a7,$d1,$e1
	dc.b	$00,$39,$58,$a3,$c8,$96,$1f,$5e,$48,$d6,$35,$fb,$cf,$42,$18,$ab
	dc.b	$da,$c8,$00,$30,$f4,$2c,$63,$fa,$32,$44,$2d,$46,$86,$20,$7b,$eb
	dc.b	$ae,$9c,$60,$da,$5a,$09,$a3,$4e,$16,$fa,$14,$73,$af,$61,$4e,$50
	dc.b	$f0,$73,$63,$f5,$d0,$fb,$ec,$d7,$08,$b0,$56,$fb,$62,$cd,$ac,$76
	dc.b	$e9,$2b,$f0,$85,$e6,$65,$78,$6a,$15,$a4,$c5,$46,$9f,$d9,$c8,$14
	dc.b	$88,$d5,$15,$ae,$57,$61,$84,$7e,$8a,$aa,$2b,$e8,$84,$83,$3e,$6f
	dc.b	$05,$70,$1c,$c7,$01,$c9,$dc,$99,$38,$cb,$93,$f3,$23,$aa,$4a,$39
	dc.b	$57,$b9,$36,$28,$ed,$4b,$68,$24,$d8,$87,$f4,$d9,$61,$e1,$ba,$bb
	dc.b	$7c,$3b,$4f,$1d,$15,$cb,$13,$f5,$42,$50,$b2,$03,$19,$ca,$49,$6f
	dc.b	$00,$52,$44,$1d,$5b,$51,$3a,$05,$bc,$c3,$0f,$65,$57,$9f,$15,$e8
	dc.b	$f3,$42,$64,$7c,$ac,$76,$f2,$95,$c1,$3f,$fe,$a0,$ee,$c8,$73,$9f
	dc.b	$15,$a2,$af,$c3,$e4,$06,$22,$77,$63,$92,$6f,$3b,$80,$55,$d8,$86
	dc.b	$21,$57,$ae,$4d,$e6,$0b,$7c,$f2,$13,$48,$8e,$64,$37,$69,$13,$d4
	dc.b	$90,$b2,$ed,$ce,$e3,$85,$3b,$3c,$29,$e1,$80,$f6,$89,$2f,$a2,$af
	dc.b	$a0,$17,$aa,$20,$35,$d6,$61,$dc,$76,$9e,$e1,$de,$38,$e8,$a2,$77
	dc.b	$d4,$1c,$a1,$20,$c4,$8b,$bc,$a2,$c1,$b6,$c5,$80,$ed,$93,$1e,$ff
	dc.b	$52,$78,$73,$84,$a6,$f1,$87,$b1,$8c,$97,$ea,$fa,$19,$f9,$3c,$60
	dc.b	$34,$0f,$05,$ae,$ab,$06,$ba,$fa,$fe,$7b,$02,$ad,$9a,$8d,$16,$c5
	dc.b	$fa,$e2,$5a,$8e,$e6,$1b,$7e,$cb,$f7,$92,$1f,$28,$1a,$df,$46,$90
	dc.b	$a0,$0d,$9a,$92,$53,$b1,$c0,$1e,$86,$02,$f5,$27,$aa,$b8,$52,$1d
	dc.b	$e7,$34,$14,$dc,$1b,$bb,$37,$69,$3c,$ef,$a2,$af,$b1,$f1,$84,$d7
	dc.b	$90,$e0,$51,$a7,$53,$b8,$e5,$61,$f5,$b1,$0c,$3a,$2f,$e8,$ea,$37
	dc.b	$c2,$c4,$11,$0b,$1b,$2d,$50,$53,$41,$38,$c1,$6e,$51,$98,$59,$78
	dc.b	$29,$58,$34,$29,$10,$a2,$c6,$cd,$37,$f7,$07,$34,$73,$e5,$e7,$c6
	dc.b	$27,$37,$c5,$c9,$4b,$6c,$6b,$30,$95,$38,$ad,$ac,$2c,$81,$4e,$4c
	dc.b	$d1,$58,$ae,$5c,$d8,$e9,$bd,$c9,$2f,$64,$1e,$84,$ec,$c3,$d5,$1c
	dc.b	$91,$0f,$dd,$21,$7e,$fd,$76,$72,$66,$c7,$01,$81,$56,$78,$2b,$e5
	dc.b	$d8,$17,$24,$a7,$4a,$99,$18,$11,$f2,$1f,$47,$51,$b2,$15,$7c,$ef
	dc.b	$03,$ae,$a9,$0b,$e5,$9d,$8e,$cf,$57,$21,$dd,$16,$e8,$9f,$fa,$49
	dc.b	$0d,$fc,$a6,$1b,$35,$a3,$43,$0a,$b1,$f3,$30,$c1,$ef,$e8,$10,$ae
	dc.b	$a0,$52,$03,$47,$c2,$10,$36,$68,$80,$e6,$88,$48,$ef,$17,$2f,$94
	dc.b	$bc,$5a,$55,$43,$84,$fa,$16,$e5,$c8,$09,$dd,$d0,$e8,$3a,$b4,$e5
	dc.b	$a6,$2b,$b0,$7e,$55,$a0,$ae,$9e,$e8,$13,$0b,$c5,$88,$23,$70,$44
	dc.b	$a4,$85,$e3,$93,$10,$e6,$ee,$8c,$ee,$c8,$fa,$01,$14,$58,$ab,$f3
	dc.b	$ac,$53,$ff,$d1,$39,$22,$d8,$db,$6d,$df,$67,$3a,$ce,$f2,$40,$c7
	dc.b	$a1,$6b,$0b,$5c,$25,$c1,$94,$ee,$b3,$a7,$15,$0a,$d1,$48,$b2,$83
	dc.b	$7a,$fc,$ec,$a2,$f1,$3e,$3a,$52,$67,$6f,$da,$e2,$e7,$3a,$96,$c6
	dc.b	$0b,$e4,$2a,$64,$30,$1a,$51,$08,$bb,$51,$e0,$60,$57,$60,$19,$34
	dc.b	$90,$d8,$48,$30,$a5,$0f,$91,$86,$23,$74,$f8,$d0,$4f,$c7,$42,$9f
	dc.b	$35,$16,$2b,$db,$6a,$1f,$39,$57,$36,$bf,$75,$96,$5f,$1d,$4e,$86
	dc.b	$98,$22,$c8,$7f,$c6,$15,$8c,$96,$3e,$78,$bc,$31,$27,$03,$81,$0a
	dc.b	$9a,$75,$08,$db,$ad,$86,$68,$00,$f9,$10,$fd,$53,$40,$8b,$68,$6c
	dc.b	$27,$bd,$f9,$24,$b6,$34,$0d,$e8,$6f,$a1,$64,$de,$34,$6e,$f4,$d3
	dc.b	$82,$c1,$0f,$62,$15,$a0,$7c,$e5,$7d,$1a,$0c,$84,$e0,$12,$5c,$ef
	dc.b	$11,$4d,$10,$92,$4b,$92,$75,$75,$d3,$9f,$92,$39,$74,$8f,$f0,$51
	dc.b	$2e,$9c,$fe,$ec,$f9,$74,$8f,$fd,$51,$db,$ee,$9c,$fc,$f7,$4b,$74
	dc.b	$e7,$ec,$86,$f2,$f7,$ba,$57,$fc,$14,$d3,$ba,$5f,$ff,$f7,$74,$72
	dc.b	$86,$5a,$66,$16,$b5,$68,$08,$8e,$c0,$8b,$e2,$1a,$fe,$77,$f3,$90
	dc.b	$2a,$2e,$94,$7c,$e5,$38,$61,$66,$56,$b7,$02,$d6,$c9,$ae,$0a,$e0
	dc.b	$d2,$eb,$0b,$5a,$a8,$26,$6e,$a3,$b1,$c3,$9d,$9e,$5f,$2b,$a1,$06
	dc.b	$66,$0f,$79,$ca,$7e,$69,$07,$96,$a1,$12,$46,$0d,$da,$40,$2e,$cd
	dc.b	$f6,$81,$9a,$3f,$1b,$fc,$c8,$02,$24,$60,$8c,$f2,$83,$9b,$02,$f9
	dc.b	$9e,$03,$1f,$8d,$1b,$4e,$6a,$25,$ae,$09,$9a,$69,$75,$46,$71,$4a
	dc.b	$fa,$8d,$3a,$68,$22,$c2,$bf,$a3,$fb,$d4,$2c,$ce,$82,$0a,$be,$f0
	dc.b	$12,$fe,$a1,$d0,$84,$ed,$78,$c1,$03,$31,$7c,$43,$4f,$35,$94,$6c
	dc.b	$67,$a6,$a0,$d4,$92,$67,$af,$ac,$98,$56,$02,$5e,$83,$ba,$d0,$45
	dc.b	$c2,$04,$cc,$e7,$e7,$fb,$64,$68,$a9,$59,$1d,$36,$84,$f7,$29,$ad
	dc.b	$7a,$91,$6d,$d1,$47,$79,$a6,$51,$67,$36,$66,$65,$24,$27,$73,$50
	dc.b	$c0,$19,$26,$2c,$9f,$56,$b8,$17,$2a,$f0,$36,$c1,$de,$c8,$1a,$f7
	dc.b	$8b,$a6,$d6,$cb,$90,$2b,$83,$0e,$ea,$92,$61,$98,$d0,$67,$63,$4e
	dc.b	$66,$c6,$f4,$78,$ac,$25,$59,$80,$0a,$cc,$2d,$b4,$82,$66,$a1,$1b
	dc.b	$23,$0b,$ba,$03,$4d,$a7,$bc,$85,$e6,$9b,$ac,$42,$7c,$41,$1b,$74
	dc.b	$e5,$cd,$bd,$96,$76,$e4,$94,$7b,$cd,$44,$e5,$99,$8d,$fa,$77,$4b
	dc.b	$32,$f6,$ca,$7a,$e6,$a4,$2a,$3d,$ce,$ef,$e3,$1d,$e5,$ec,$27,$a4
	dc.b	$7f,$41,$07,$6b,$02,$10,$a8,$3b,$08,$02,$73,$0d,$81,$91,$92,$62
	dc.b	$88,$2d,$2f,$28,$d9,$85,$b4,$b8,$ac,$41,$5e,$ed,$ba,$b2,$ea,$3b
	dc.b	$2c,$b9,$31,$7d,$b0,$44,$95,$4c,$c6,$9c,$e7,$7e,$63,$45,$a2,$8b
	dc.b	$b6,$61,$2f,$bf,$7c,$da,$34,$59,$60,$ad,$71,$fb,$c0,$05,$f9,$b9
	dc.b	$19,$9d,$1e,$72,$0c,$a4,$59,$57,$2e,$10,$ed,$d3,$54,$1f,$e0,$fb
	dc.b	$43,$ba,$97,$dd,$3e,$5a,$8b,$43,$ab,$a6,$0d,$93,$a9,$f2,$e4,$75
	dc.b	$d7,$a9,$83,$6e,$ab,$1f,$c7,$7d,$8e,$9c,$bf,$02,$ab,$2e,$88,$05
	dc.b	$34,$a7,$ef,$28,$d4,$22,$70,$c0,$61,$3c,$f9,$b2,$60,$c4,$6b,$7e
	dc.b	$b5,$49,$7e,$c5,$3f,$5c,$36,$4e,$f9,$c9,$19,$0f,$cd,$ec,$c7,$35
	dc.b	$a1,$64,$07,$d6,$3d,$27,$8e,$08,$db,$8a,$83,$f0,$e4,$b1,$f9,$67
	dc.b	$1f,$a0,$59,$9a,$c0,$93,$f5,$f4,$10,$94,$92,$60,$42,$36,$99,$c0
	dc.b	$7d,$31,$73,$0f,$f5,$d9,$4f,$c9,$8a,$24,$9a,$df,$ba,$b2,$75,$a9
	dc.b	$23,$22,$31,$d6,$82,$2d,$bd,$51,$7e,$c5,$b6,$9d,$f6,$29,$59,$fb
	dc.b	$00,$0c,$61,$c2,$b1,$10,$29,$10,$f1,$0c,$b4,$b3,$08,$3c,$3e,$34
	dc.b	$99,$eb,$0b,$35,$65,$d5,$6c,$d4,$f1,$0e,$d3,$d7,$58,$dc,$de,$ef
	dc.b	$ae,$8f,$df,$5f,$a6,$c1,$f1,$ed,$a7,$34,$4e,$d0,$3b,$d5,$14,$1e
	dc.b	$6d,$08,$fa,$aa,$ac,$dc,$21,$d5,$66,$c4,$0a,$84,$ea,$e7,$b9,$ea
	dc.b	$17,$9d,$33,$a8,$47,$20,$fe,$5d,$e1,$95,$4c,$3d,$fa,$64,$2b,$2a
	dc.b	$ae,$a6,$17,$31,$3b,$43,$d9,$f9,$ce,$df,$6c,$59,$d6,$75,$ad,$20
	dc.b	$55,$31,$6f,$8c,$7b,$f5,$8c,$6a,$93,$b4,$36,$fb,$a0,$c9,$29,$c3
	dc.b	$ae,$81,$67,$47,$00,$2f,$47,$c4,$14,$81,$95,$ba,$06,$0c,$d5,$94
	dc.b	$d4,$ba,$d0,$ae,$6a,$f2,$14,$bd,$94,$4e,$e5,$5d,$20,$f7,$51,$3b
	dc.b	$f3,$67,$e6,$89,$2c,$d8,$22,$47,$50,$35,$56,$49,$e2,$07,$6f,$85
	dc.b	$1a,$aa,$d0,$bd,$5b,$1c,$0c,$b6,$e4,$be,$3b,$a1,$d9,$7a,$66,$00
	dc.b	$9a,$ce,$22,$0a,$f8,$79,$01,$5b,$4a,$21,$db,$3b,$f4,$f0,$31,$ef
	dc.b	$fb,$f2,$5d,$2d,$0d,$d7,$73,$3e,$50,$ed,$2c,$62,$34,$06,$17,$e3
	dc.b	$e6,$3e,$58,$31,$0f,$d7,$e6,$9c,$27,$09,$72,$5d,$3b,$08,$e5,$92
	dc.b	$68,$14,$32,$55,$41,$fa,$a3,$6b,$5f,$55,$9b,$ba,$64,$18,$e5,$14
	dc.b	$b1,$bd,$68,$93,$7b,$f4,$f9,$59,$8a,$28,$8d,$20,$6f,$98,$5d,$c0
	dc.b	$61,$1f,$11,$62,$3d,$41,$05,$fc,$c9,$69,$53,$da,$e9,$60,$ab,$d0
	dc.b	$cc,$d9,$91,$0d,$b1,$00,$8e,$d0,$03,$6b,$00,$53,$c0,$4f,$90,$a5
	dc.b	$74,$e1,$5d,$ba,$ab,$b6,$f4,$b1,$88,$ef,$49,$6b,$c4,$9d,$56,$82
	dc.b	$b0,$f8,$03,$f3,$12,$ba,$c1,$81,$51,$c4,$39,$d2,$37,$95,$a0,$0d
	dc.b	$71,$9f,$08,$d6,$b9,$28,$ce,$60,$09,$ee,$24,$87,$3b,$39,$02,$3c
	dc.b	$e0,$18,$f2,$10,$ed,$93,$96,$81,$17,$3d,$fe,$55,$12,$c0,$d8,$e3
	dc.b	$a5,$99,$dd,$40,$e1,$7e,$50,$02,$7b,$41,$80,$b1,$e7,$14,$f7,$ce
	dc.b	$05,$e9,$1a,$7e,$5f,$05,$fb,$9e,$29,$23,$fd,$58,$a7,$ba,$64,$29
	dc.b	$d7,$08,$d2,$98,$7c,$cc,$d9,$e3,$bb,$3a,$7c,$37,$4c,$a8,$3a,$36
	dc.b	$42,$90,$08,$0c,$60,$31,$19,$90,$fc,$7f,$ab,$af,$96,$87,$46,$7d
	dc.b	$de,$77,$a5,$84,$3d,$2e,$06,$38,$4c,$57,$6e,$83,$06,$99,$02,$3d
	dc.b	$a0,$2f,$4a,$6a,$06,$7e,$42,$98,$59,$73,$c7,$7d,$af,$35,$e9,$66
	dc.b	$77,$52,$f6,$7f,$5a,$d3,$9d,$cd,$83,$2d,$50,$fa,$42,$ce,$d0,$62
	dc.b	$ec,$e1,$06,$13,$5c,$e6,$3f,$81,$a4,$f0,$6c,$36,$d7,$39,$09,$59
	dc.b	$81,$55,$6b,$8e,$54,$c6,$e4,$29,$75,$a1,$8d,$04,$2d,$40,$ea,$55
	dc.b	$1f,$38,$15,$d7,$ec,$8d,$c6,$98,$31,$91,$38,$5c,$93,$c3,$ce,$df
	dc.b	$80,$a7,$ed,$07,$19,$75,$a6,$e7,$f4,$e1,$b3,$49,$94,$30,$6e,$9a
	dc.b	$05,$45,$00,$ce,$b5,$b3,$d5,$1f,$cd,$f6,$84,$18,$d7,$7f,$67,$99
	dc.b	$ef,$7c,$d7,$0f,$e3,$be,$91,$24,$42,$2e,$cc,$0f,$bf,$90,$0d,$0d
	dc.b	$2a,$e1,$52,$1a,$8e,$ff,$b6,$ca,$d3,$9a,$9e,$8e,$0c,$0e,$f8,$7c
	dc.b	$76,$f4,$12,$e5,$4d,$b9,$b7,$9f,$21,$4b,$43,$05,$42,$e6,$02,$b7
	dc.b	$c8,$52,$8f,$e7,$62,$d3,$73,$aa,$e9,$b0,$63,$35,$5b,$33,$c2,$b5
	dc.b	$87,$ff,$5e,$b4,$1e,$84,$3b,$7f,$72,$04,$b4,$31,$f2,$00,$30,$ad
	dc.b	$b0,$73,$e1,$08,$c0,$fa,$ec,$1c,$18,$66,$d9,$98,$14,$56,$23,$47
	dc.b	$3f,$a0,$66,$f8,$8b,$55,$b4,$81,$68,$82,$3d,$76,$c4,$32,$93,$e8
	dc.b	$8d,$2b,$33,$28,$80,$4e,$60,$e0,$4e,$7e,$03,$48,$83,$d5,$f4,$eb
	dc.b	$35,$aa,$d5,$3c,$b0,$db,$76,$64,$6a,$04,$9a,$10,$d9,$90,$f9,$96
	dc.b	$b4,$0a,$84,$0b,$9a,$46,$48,$a6,$82,$cc,$ce,$5d,$66,$fb,$cb,$57
	dc.b	$7a,$56,$b0,$e8,$8c,$3d,$53,$d2,$0d,$bb,$2a,$84,$06,$4b,$66,$cf
	dc.b	$90,$a6,$e5,$b4,$92,$50,$bf,$c2,$e0,$c0,$1f,$eb,$c7,$cc,$67,$15
	dc.b	$5a,$0e,$df,$21,$24,$09,$5d,$03,$9b,$74,$d4,$19,$87,$74,$2b,$57
	dc.b	$bc,$35,$66,$67,$cd,$ad,$f7,$dc,$46,$b0,$b3,$60,$8e,$c9,$fb,$9f
	dc.b	$0f,$bc,$83,$1d,$0f,$55,$be,$14,$ba,$75,$9a,$27,$36,$91,$41,$e6
	dc.b	$87,$d4,$c6,$e7,$37,$c3,$7b,$c3,$86,$98,$43,$70,$09,$a9,$5a,$00
	dc.b	$8e,$d0,$75,$29,$4f,$4d,$03,$35,$1f,$ff,$41,$eb,$6e,$a4,$f9,$a3
	dc.b	$c1,$d3,$21,$0e,$3c,$01,$ae,$2e,$8b,$93,$dc,$e1,$13,$51,$59,$a2
	dc.b	$05,$55,$38,$34,$82,$5f,$20,$aa,$a2,$c1,$eb,$8b,$3a,$60,$db,$8a
	dc.b	$a7,$65,$2d,$8e,$af,$cc,$f1,$ff,$49,$97,$50,$de,$16,$4f,$48,$1e
	dc.b	$d6,$93,$39,$91,$35,$49,$ed,$f1,$0c,$1e,$8a,$38,$9d,$b6,$51,$5f
	dc.b	$14,$89,$78,$67,$b6,$1c,$30,$f9,$92,$36,$d5,$e3,$4d,$06,$5d,$58
	dc.b	$7c,$a5,$cb,$e1,$3a,$21,$cf,$5b,$60,$a6,$cf,$7c,$7d,$02,$ac,$c7
	dc.b	$c7,$67,$54,$49,$0a,$e4,$2c,$a1,$9c,$d4,$9a,$27,$d5,$90,$5b,$30
	dc.b	$d9,$80,$b2,$8e,$d9,$3a,$7a,$d0,$be,$15,$9b,$b4,$20,$c9,$18,$6d
	dc.b	$d0,$b8,$01,$30,$58,$37,$14,$e3,$73,$a9,$8e,$73,$7e,$cb,$0f,$98
	dc.b	$2b,$07,$e9,$a8,$2a,$09,$fd,$2c,$b4,$43,$9e,$02,$b7,$5d,$f1,$7a
	dc.b	$95,$7f,$ad,$bc,$b5,$51,$c2,$be,$68,$b0,$69,$3d,$70,$54,$81,$6e
	dc.b	$70,$81,$91,$87,$bf,$e4,$3e,$69,$06,$10,$26,$60,$db,$d8,$f6,$4b
	dc.b	$af,$9e,$af,$ad,$9b,$db,$33,$b0,$ef,$cc,$b5,$e9,$0c,$4b,$44,$06
	dc.b	$4d,$e6,$61,$5a,$85,$2c,$41,$b7,$46,$67,$5b,$61,$74,$2c,$8f,$72
	dc.b	$e0,$12,$30,$53,$0d,$f2,$24,$0f,$b2,$f2,$1a,$86,$fa,$9a,$1c,$43
	dc.b	$50,$c0,$2a,$cf,$65,$03,$6d,$ec,$97,$c0,$f1,$3c,$57,$2d,$9a,$b6
	dc.b	$db,$22,$1d,$3b,$c8,$69,$d4,$88,$15,$ab,$2d,$ca,$ce,$50,$a6,$10
	dc.b	$48,$2a,$b3,$d5,$4e,$04,$df,$90,$db,$18,$41,$85,$90,$ee,$19,$94
	dc.b	$18,$7e,$36,$fc,$55,$7d,$7f,$1b,$c4,$54,$f3,$9a,$18,$2d,$d8,$f4
	dc.b	$9e,$fd,$3e,$82,$15,$38,$ff,$cb,$2d,$13,$10,$30,$32,$3f,$77,$f0
	dc.b	$01,$83,$c8,$fb,$09,$2d,$d2,$21,$0e,$6a,$35,$07,$af,$04,$db,$b1
	dc.b	$0e,$cc,$32,$4f,$ac,$20,$64,$0f,$e3,$ab,$54,$f5,$ed,$b4,$34,$82
	dc.b	$47,$c9,$a5,$91,$f1,$ee,$19,$06,$34,$15,$53,$03,$4c,$0c,$c5,$44
	dc.b	$cf,$a1,$1d,$bc,$32,$bb,$f4,$09,$19,$90,$8d,$98,$59,$19,$80,$77
	dc.b	$c1,$fa,$9d,$19,$87,$cd,$78,$0a,$4e,$de,$9d,$65,$0a,$59,$db,$79
	dc.b	$02,$cc,$d6,$18,$29,$b8,$de,$3e,$d2,$62,$c3,$3d,$81,$ca,$17,$1b
	dc.b	$81,$41,$bb,$bf,$50,$27,$5e,$f0,$b7,$c8,$52,$30,$0c,$2b,$34,$cf
	dc.b	$32,$6a,$a1,$33,$00,$a1,$2a,$f9,$a4,$13,$67,$c1,$53,$7a,$c0,$cd
	dc.b	$2b,$e9,$7f,$4f,$a0,$94,$41,$14,$d0,$ba,$3e,$b3,$cb,$79,$de,$9f
	dc.b	$57,$51,$15,$ff,$a5,$96,$89,$89,$50,$0c,$1f,$9d,$c0,$f9,$37,$26
	dc.b	$74,$72,$22,$10,$b1,$c1,$de,$4c,$9b,$b1,$0c,$50,$28,$f1,$b8,$81
	dc.b	$91,$3f,$d7,$25,$d7,$1c,$86,$9a,$10,$74,$b4,$64,$27,$a1,$c6,$bd
	dc.b	$44,$4d,$5f,$22,$82,$1b,$aa,$aa,$e0,$be,$92,$8d,$09,$a8,$ae,$81
	dc.b	$23,$67,$0b,$2f,$6e,$24,$f6,$d8,$dc,$e2,$30,$29,$76,$86,$e2,$f1
	dc.b	$e4,$24,$e2,$7e,$34,$f2,$05,$4e,$3b,$ea,$ee,$26,$61,$fe,$d7,$cb
	dc.b	$08,$d2,$b6,$c4,$56,$89,$80,$71,$29,$29,$de,$01,$82,$4e,$a9,$af
	dc.b	$82,$69,$bb,$6c,$e7,$f7,$5c,$56,$6d,$8c,$b5,$98,$9f,$6c,$a7,$ff
	dc.b	$2a,$bb,$63,$2e,$cc,$ad,$8c,$b8,$6d,$8e,$45,$6e,$7c,$b8,$72,$1b
	dc.b	$80,$5e,$4b,$b8,$2f,$fe,$0e,$57,$02,$ff,$2a,$e1,$ea,$d3,$89,$f1
	dc.b	$00,$9b,$e5,$b1,$bf,$e7,$0a,$dd,$b0,$ff,$f7,$86,$e5,$18,$d9,$07
	dc.b	$d9,$5e,$61,$a7,$66,$2d,$3a,$41,$ae,$f4,$76,$07,$cc,$e6,$47,$a4
	dc.b	$96,$9b,$e2,$20,$b1,$f9,$3e,$73,$51,$df,$89,$f8,$df,$41,$44,$f3
	dc.b	$f1,$c7,$1e,$a9,$d7,$da,$e9,$07,$b9,$97,$bf,$90,$b5,$81,$df,$4f
	dc.b	$f4,$72,$ce,$61,$b3,$5f,$25,$8e,$df,$56,$89,$37,$90,$2c,$b4,$01
	dc.b	$cd,$e3,$cf,$00,$ef,$c6,$49,$2f,$81,$7c,$40,$55,$79,$41,$96,$84
	dc.b	$a8,$86,$1c,$5d,$82,$9e,$3b,$cd,$0f,$71,$6f,$50,$18,$6a,$0e,$df
	dc.b	$a9,$af,$4f,$3e,$9d,$59,$ca,$19,$b4,$a1,$a5,$e4,$25,$2c,$9d,$69
	dc.b	$f2,$11,$3b,$53,$a2,$f7,$33,$48,$7c,$8f,$20,$eb,$c8,$19,$8b,$5c
	dc.b	$24,$0d,$3e,$82,$b4,$6b,$9e,$d3,$d0,$78,$05,$66,$8e,$83,$98,$18
	dc.b	$98,$36,$c9,$03,$d1,$5a,$01,$c9,$56,$03,$3c,$93,$60,$39,$ff,$f7
	dc.b	$c0,$05,$f8,$78,$0a,$7f,$14,$b0,$02,$b8,$6f,$83,$c0,$6f,$fd,$97
	dc.b	$60,$05,$73,$9e,$02,$7f,$fa,$7c,$06,$7f,$8a,$ba,$77,$37,$c8,$ff
	dc.b	$3a,$f8,$3f,$fe,$a4,$36,$c3,$95,$54,$7b,$f2,$fe,$3f,$3c,$33,$f7
	dc.b	$94,$00,$db,$b7,$68,$4a,$6d,$34,$41,$1f,$9a,$6e,$e6,$35,$19,$91
	dc.b	$9e,$be,$fc,$89,$46,$fb,$79,$16,$3d,$c9,$82,$c0,$0c,$5b,$8a,$43
	dc.b	$8f,$87,$5a,$fa,$0e,$83,$ae,$a8,$4c,$7c,$db,$7d,$c8,$9e,$40,$ad
	dc.b	$98,$69,$19,$06,$90,$cc,$b8,$ec,$07,$d9,$9b,$66,$26,$c8,$3e,$50
	dc.b	$c9,$c8,$fe,$4f,$c8,$08,$34,$b5,$a1,$8f,$b7,$97,$65,$5c,$10,$8b
	dc.b	$a4,$0c,$87,$a1,$c8,$21,$e8,$0a,$02,$72,$83,$3f,$48,$45,$0c,$6a
	dc.b	$76,$d3,$43,$94,$e1,$19,$82,$25,$55,$bc,$f0,$c0,$3e,$80,$7e,$89
	dc.b	$05,$d7,$1e,$9c,$ea,$98,$75,$c9,$bb,$42,$5b,$ef,$c9,$d5,$ad,$0d
	dc.b	$eb,$dc,$06,$ab,$d8,$e8,$4a,$06,$0a,$c3,$89,$7f,$d5,$d0,$25,$36
	dc.b	$1a,$b0,$1b,$66,$88,$f3,$45,$23,$68,$d4,$2a,$b1,$98,$69,$23,$c5
	dc.b	$72,$70,$30,$c7,$df,$cc,$98,$27,$9a,$e6,$3c,$15,$32,$20,$89,$44
	dc.b	$ce,$98,$d5,$97,$e1,$15,$3d,$b4,$d5,$07,$39,$b9,$81,$f2,$84,$30
	dc.b	$2a,$f6,$bd,$77,$c8,$ae,$3a,$de,$27,$c7,$7d,$3e,$fb,$5a,$0a,$5e
	dc.b	$95,$92,$42,$d4,$9f,$ad,$1c,$ae,$6a,$2d,$9b,$f0,$08,$e2,$1b,$e9
	dc.b	$71,$67,$6f,$28,$67,$c9,$db,$7c,$d2,$1d,$53,$f5,$11,$f4,$d5,$84
	dc.b	$06,$0d,$09,$a2,$19,$b5,$7e,$6a,$18,$19,$e1,$05,$17,$4b,$b4,$7c
	dc.b	$83,$30,$80,$ca,$3f,$de,$66,$14,$43,$b4,$b3,$c8,$be,$54,$1c,$b2
	dc.b	$f5,$24,$c4,$9a,$ef,$20,$ec,$a0,$cf,$6f,$26,$14,$49,$a9,$7e,$a7
	dc.b	$b5,$23,$6c,$85,$fe,$ed,$88,$5c,$c0,$e7,$08,$a0,$62,$8e,$04,$8a
	dc.b	$38,$74,$57,$4b,$ba,$b4,$87,$32,$74,$8e,$46,$c9,$14,$68,$5e,$e4
	dc.b	$37,$e9,$6a,$e0,$60,$ac,$3d,$b4,$31,$e9,$92,$f8,$3c,$62,$51,$20
	dc.b	$43,$27,$dc,$e6,$a3,$3c,$25,$0d,$5d,$8a,$a8,$1b,$d4,$16,$84,$ea
	dc.b	$8d,$35,$41,$fe,$62,$76,$bd,$ae,$c0,$ff,$47,$1d,$59,$4c,$14,$82
	dc.b	$76,$6f,$cd,$ff,$52,$4d,$d6,$34,$95,$2c,$40,$63,$ee,$c6,$f5,$df
	dc.b	$38,$f5,$81,$c5,$2c,$83,$46,$8b,$22,$96,$20,$ba,$a7,$ec,$54,$3a
	dc.b	$ac,$d1,$70,$c3,$4c,$55,$d4,$e9,$4b,$6a,$d5,$b9,$7c,$63,$15,$d6
	dc.b	$05,$ed,$4b,$11,$31,$47,$ca,$de,$55,$aa,$70,$0c,$15,$ba,$4b,$93
	dc.b	$2e,$44,$7d,$ac,$0c,$fd,$d7,$d0,$fa,$26,$6d,$f5,$75,$09,$d2,$87
	dc.b	$b6,$23,$66,$f0,$08,$e8,$52,$07,$a4,$18,$47,$46,$43,$3a,$f8,$69
	dc.b	$05,$60,$32,$9f,$91,$e6,$83,$04,$bc,$9a,$8b,$99,$1c,$f4,$f4,$37
	dc.b	$49,$4d,$bd,$b7,$a1,$fb,$30,$68,$11,$a5,$22,$73,$51,$af,$f6,$67
	dc.b	$3f,$cf,$46,$cc,$50,$bc,$58,$1b,$d7,$ec,$a4,$b5,$21,$11,$99,$77
	dc.b	$e7,$02,$5a,$5a,$09,$2c,$dd,$d9,$c7,$30,$53,$b2,$4c,$e7,$a9,$a6
	dc.b	$eb,$ac,$69,$32,$0f,$40,$62,$9e,$0f,$e4,$3f,$55,$63,$a0,$74,$c5
	dc.b	$90,$61,$d1,$a4,$22,$21,$4b,$0e,$f5,$4d,$17,$55,$22,$33,$49,$71
	dc.b	$b9,$af,$35,$9d,$25,$8f,$bb,$d0,$31,$5a,$71,$65,$6d,$75,$57,$91
	dc.b	$73,$5d,$3e,$06,$e9,$29,$10,$98,$47,$3d,$e0,$8d,$1b,$28,$84,$68
	dc.b	$be,$d6,$ea,$18,$68,$29,$24,$7b,$78,$60,$b6,$20,$7d,$e8,$0c,$1a
	dc.b	$96,$a1,$c8,$a1,$92,$64,$b1,$66,$51,$cd,$40,$d0,$d5,$9f,$ae,$50
	dc.b	$df,$53,$05,$9b,$dd,$02,$3c,$3f,$4b,$a4,$6a,$a4,$e8,$75,$e7,$7f
	dc.b	$16,$04,$ad,$f7,$cb,$cc,$14,$86,$83,$de,$92,$70,$32,$a1,$bf,$4b
	dc.b	$54,$14,$cb,$6a,$e7,$7b,$0a,$a8,$67,$7f,$38,$14,$3d,$ae,$15,$57
	dc.b	$ac,$4f,$e2,$ca,$df,$04,$83,$7e,$d5,$3d,$48,$f4,$a1,$2b,$31,$8b
	dc.b	$d0,$55,$f7,$72,$80,$39,$8f,$35,$41,$8e,$00,$2c,$c4,$12,$89,$71
	dc.b	$62,$a0,$d5,$38,$1a,$30,$28,$76,$68,$5a,$3d,$e0,$54,$ed,$1f,$42
	dc.b	$55,$74,$c2,$b3,$51,$16,$98,$0d,$b7,$40,$49,$db,$a4,$32,$64,$10
	dc.b	$e6,$c2,$c8,$0c,$be,$95,$80,$c1,$5e,$10,$6f,$de,$43,$61,$f6,$64
	dc.b	$cc,$64,$c4,$1e,$81,$5a,$43,$4a,$8a,$0b,$6a,$84,$d0,$a0,$6c,$bd
	dc.b	$cd,$65,$83,$1e,$ae,$39,$55,$f7,$78,$cc,$3e,$78,$e0,$a7,$fb,$c7
	dc.b	$c8,$aa,$bd,$48,$d6,$34,$14,$c1,$4c,$7d,$29,$42,$fd,$ce,$fe,$2a
	dc.b	$43,$06,$53,$aa,$2e,$cf,$82,$0e,$f5,$05,$a2,$48,$c0,$99,$48,$bd
	dc.b	$31,$b5,$52,$fa,$2d,$b6,$19,$46,$0b,$cd,$16,$d5,$22,$f1,$04,$a6
	dc.b	$88,$eb,$17,$32,$9e,$4a,$16,$61,$b7,$da,$f2,$09,$b1,$a4,$14,$5a
	dc.b	$0a,$6a,$83,$62,$00,$b2,$20,$94,$4b,$8b,$b8,$6c,$50,$87,$0b,$de
	dc.b	$33,$13,$a8,$32,$91,$69,$a0,$11,$e3,$16,$f4,$02,$8a,$06,$37,$93
	dc.b	$01,$8f,$4e,$2b,$09,$c0,$d6,$09,$0b,$4c,$b4,$16,$f8,$2a,$48,$b5
	dc.b	$05,$32,$4d,$1a,$4d,$79,$57,$c5,$4a,$23,$1e,$d9,$73,$40,$9c,$0a
	dc.b	$02,$63,$29,$05,$a0,$85,$45,$fe,$c0,$d6,$51,$45,$8b,$65,$0c,$05
	dc.b	$1e,$68,$53,$3a,$f8,$5f,$1c,$c3,$37,$65,$98,$f5,$d6,$70,$db,$1a
	dc.b	$ce,$91,$a2,$1a,$78,$f5,$58,$c7,$d2,$8d,$f0,$33,$80,$7a,$a3,$3d
	dc.b	$fe,$7b,$b2,$65,$7f,$22,$36,$91,$39,$17,$dc,$fb,$08,$17,$5c,$7e
	dc.b	$f2,$b9,$71,$7d,$9c,$de,$81,$1f,$5b,$85,$f7,$82,$f6,$f9,$38,$c1
	dc.b	$c5,$e4,$4f,$99,$a8,$de,$e4,$b7,$28,$45,$97,$6a,$e0,$60,$5b,$92
	dc.b	$e4,$20,$eb,$5a,$a5,$84,$82,$be,$11,$bb,$a6,$41,$b2,$8d,$c1,$dc
	dc.b	$be,$8d,$55,$17,$dc,$ea,$42,$62,$3f,$78,$63,$69,$28,$92,$04,$eb
	dc.b	$66,$77,$71,$84,$e4,$d5,$e5,$e4,$08,$56,$67,$e4,$c0,$65,$29,$58
	dc.b	$24,$ed,$09,$a5,$22,$1c,$54,$87,$55,$4a,$92,$2b,$01,$b7,$53,$2d
	dc.b	$9f,$ba,$f3,$98,$18,$fb,$01,$44,$67,$41,$c9,$58,$c0,$82,$dc,$de
	dc.b	$87,$1e,$f4,$2a,$74,$76,$f9,$68,$dd,$6b,$41,$85,$0b,$49,$cd,$dc
	dc.b	$8f,$49,$81,$cb,$41,$75,$e2,$32,$ea,$8b,$79,$a3,$63,$c5,$e0,$98
	dc.b	$47,$58,$41,$16,$69,$95,$a0,$6f,$8b,$83,$9a,$e5,$2b,$ea,$ab,$e0
	dc.b	$44,$e4,$a4,$23,$e2,$c2,$df,$cd,$dd,$6d,$f6,$46,$0a,$4e,$35,$cd
	dc.b	$78,$39,$63,$8e,$ad,$f2,$e4,$83,$bc,$51,$5f,$0e,$6a,$36,$0b,$eb
	dc.b	$11,$45,$5b,$5f,$a6,$a2,$83,$71,$15,$29,$80,$cc,$5d,$2d,$cd,$a0
	dc.b	$72,$56,$60,$1a,$6d,$51,$9f,$47,$67,$57,$2c,$2b,$68,$81,$d0,$0c
	dc.b	$06,$b2,$5a,$da,$27,$c4,$da,$ac,$a0,$be,$36,$80,$95,$e1,$d5,$fe
	dc.b	$a2,$1b,$36,$21,$c6,$79,$10,$26,$95,$bb,$ce,$70,$cc,$9b,$6e,$c8
	dc.b	$a2,$94,$5f,$a8,$cc,$7d,$5c,$af,$6b,$7b,$77,$38,$48,$63,$d8,$3d
	dc.b	$e8,$56,$21,$80,$aa,$3a,$45,$91,$84,$35,$41,$af,$67,$a2,$57,$1f
	dc.b	$4e,$65,$d1,$de,$60,$c6,$49,$e8,$39,$47,$f4,$f6,$7a,$98,$26,$bd
	dc.b	$28,$64,$dc,$e2,$ab,$2f,$51,$06,$ac,$d1,$23,$6a,$2c,$00,$d8,$58
	dc.b	$82,$57,$9a,$b2,$74,$16,$00,$f2,$68,$27,$8b,$0e,$78,$f1,$58,$5c
	dc.b	$3f,$77,$e3,$cf,$d5,$c6,$f8,$be,$34,$0c,$38,$3f,$e0,$88,$87,$39
	dc.b	$c9,$6c,$93,$bb,$b9,$e6,$e7,$39,$ca,$a4,$7f,$58,$04,$56,$f3,$9c
	dc.b	$1b,$f7,$bb,$37,$f2,$f2,$18,$73,$0a,$24,$62,$2f,$83,$b9,$4e,$19
	dc.b	$73,$8f,$15,$c6,$bc,$b0,$2a,$67,$c5,$cd,$e4,$5b,$9c,$9a,$af,$6c
	dc.b	$38,$84,$2a,$a0,$db,$9c,$9e,$93,$e4,$bf,$7c,$68,$2e,$d6,$c8,$0d
	dc.b	$e0,$fb,$17,$9c,$72,$0c,$2c,$4d,$b0,$e7,$1c,$fe,$f3,$01,$80,$fe
	dc.b	$5b,$36,$4e,$8f,$c8,$74,$c7,$d8,$83,$4a,$30,$b8,$86,$cc,$ae,$af
	dc.b	$ad,$07,$12,$80,$1b,$8a,$21,$03,$85,$a6,$e9,$ce,$c4,$5e,$5d,$a0
	dc.b	$e0,$ea,$2d,$96,$66,$09,$a0,$9c,$cf,$dc,$37,$0e,$a9,$bf,$6f,$2c
	dc.b	$73,$4f,$ee,$fe,$96,$39,$b2,$c1,$56,$87,$78,$43,$bf,$57,$3b,$a4
	dc.b	$aa,$68,$d3,$dd,$0d,$7a,$b1,$fc,$f1,$b9,$16,$de,$f4,$47,$1a,$06
	dc.b	$2e,$bd,$c8,$55,$3d,$32,$19,$73,$b3,$4f,$57,$23,$ce,$70,$ae,$a6
	dc.b	$b5,$e5,$ad,$0e,$1d,$44,$6d,$35,$1a,$ac,$d1,$d6,$d1,$9a,$e7,$54
	dc.b	$74,$3f,$00,$53,$88,$55,$24,$fb,$95,$b0,$d9,$5f,$96,$91,$9f,$8f
	dc.b	$ec,$2c,$af,$9b,$25,$1f,$c2,$06,$45,$aa,$52,$6b,$f7,$97,$86,$72
	dc.b	$8e,$6c,$cc,$12,$d5,$2d,$d9,$10,$3d,$cb,$ca,$70,$22,$09,$b5,$06
	dc.b	$af,$91,$1a,$f9,$c4,$06,$8d,$fd,$94,$ce,$a6,$3b,$20,$70,$3d,$d6
	dc.b	$37,$c6,$38,$12,$ad,$93,$c0,$b2,$1e,$4b,$e0,$6c,$8e,$5e,$2c,$1a
	dc.b	$f9,$cf,$66,$03,$29,$c0,$7b,$aa,$27,$2d,$98,$02,$c5,$b4,$be,$c7
	dc.b	$7c,$91,$37,$fc,$50,$e0,$27,$72,$3e,$b7,$e4,$23,$5a,$c0,$b8,$c1
	dc.b	$5a,$f6,$f2,$b3,$a5,$77,$b9,$7a,$89,$2a,$71,$cf,$c6,$e6,$b5,$5c
	dc.b	$2f,$a9,$df,$b7,$03,$da,$fa,$78,$f8,$f6,$77,$c7,$a9,$2a,$39,$10
	dc.b	$8d,$51,$bb,$79,$53,$34,$b5,$c8,$ca,$72,$2c,$21,$16,$3c,$7e,$24
	dc.b	$02,$34,$bf,$67,$fe,$6a,$0c,$ec,$88,$d6,$20,$62,$d0,$0d,$3a,$a9
	dc.b	$cf,$c6,$ea,$72,$96,$25,$77,$83,$62,$0e,$c0,$6f,$c9,$c7,$ec,$75
	dc.b	$c5,$98,$02,$5d,$bd,$45,$5d,$f8,$23,$66,$1a,$58,$1b,$b9,$a2,$49
	dc.b	$e5,$5a,$21,$71,$20,$f9,$99,$30,$1b,$09,$0c,$9c,$93,$54,$9b,$52
	dc.b	$bb,$d3,$d8,$05,$a1,$f6,$02,$ae,$d1,$af,$a1,$d1,$6d,$1c,$0d,$3c
	dc.b	$7c,$3e,$e8,$e6,$05,$dd,$22,$ad,$8d,$4a,$d2,$e5,$e2,$67,$1b,$9d
	dc.b	$aa,$92,$d0,$03,$92,$d1,$aa,$db,$92,$5e,$dc,$56,$87,$02,$ab,$64
	dc.b	$97,$9a,$c0,$68,$a8,$39,$a5,$53,$1a,$cb,$48,$7c,$d8,$d8,$58,$e8
	dc.b	$82,$ad,$2e,$73,$6f,$ef,$70,$3e,$37,$d4,$c9,$74,$7f,$2d,$d1,$c8
	dc.b	$0d,$ef,$f2,$fe,$fc,$2b,$e7,$c0,$8b,$31,$d2,$74,$a1,$3f,$d9,$a7
	dc.b	$c6,$75,$94,$76,$c1,$c2,$20,$d9,$65,$36,$40,$ab,$5c,$19,$e4,$ad
	dc.b	$e6,$d0,$70,$c7,$45,$8e,$07,$3f,$52,$b3,$0c,$3c,$dd,$bf,$45,$b1
	dc.b	$62,$6f,$6a,$7c,$4f,$a0,$ec,$59,$44,$df,$77,$a6,$85,$22,$e5,$b9
	dc.b	$d2,$66,$0e,$20,$0a,$02,$3e,$0c,$93,$e2,$ef,$45,$e4,$95,$d9,$51
	dc.b	$27,$79,$7c,$97,$93,$46,$be,$0e,$f8,$9f,$ab,$77,$28,$9e,$17,$90
	dc.b	$b1,$c7,$4b,$0e,$53,$73,$52,$f7,$3d,$1d,$1c,$07,$21,$a7,$8b,$2c
	dc.b	$e5,$f5,$6b,$1b,$34,$06,$1a,$80,$46,$03,$c0,$44,$c9,$de,$30,$f6
	dc.b	$a5,$2c,$6b,$40,$0f,$f7,$43,$4f,$2b,$35,$b1,$74,$15,$f4,$0e,$51
	dc.b	$b8,$fc,$23,$6d,$bf,$46,$19,$7b,$34,$ac,$f0,$bb,$55,$d2,$d1,$23
	dc.b	$16,$4d,$95,$38,$bb,$e1,$aa,$73,$e5,$9c,$f5,$1e,$57,$c6,$e5,$be
	dc.b	$4e,$05,$66,$06,$2b,$35,$e7,$c8,$c4,$cb,$3a,$d5,$26,$ca,$70,$e6
	dc.b	$a2,$2e,$9c,$2e,$93,$17,$11,$52,$da,$10,$47,$81,$e5,$20,$af,$99
	dc.b	$be,$42,$f0,$6a,$fb,$7a,$b4,$cc,$29,$66,$57,$7c,$25,$66,$d3,$7d
	dc.b	$3d,$36,$24,$36,$4e,$6a,$2a,$c0,$60,$b4,$0d,$20,$db,$fa,$80,$fa
	dc.b	$bd,$4c,$11,$b1,$20,$25,$a1,$f3,$39,$f5,$da,$92,$bb,$14,$ba,$17
	dc.b	$d7,$d9,$4a,$10,$1f,$24,$c0,$a1,$24,$3d,$0d,$91,$a8,$50,$f6,$01
	dc.b	$59,$82,$69,$9b,$90,$fd,$a3,$96,$70,$9d,$ee,$23,$72,$d3,$86,$aa
	dc.b	$35,$91,$77,$1d,$92,$fb,$16,$49,$9f,$e1,$54,$97,$c4,$17,$f9,$eb
	dc.b	$6f,$10,$2f,$c3,$78,$7f,$10,$6f,$f6,$62,$05,$7e,$df,$a6,$b7,$88
	dc.b	$7f,$f9,$ee,$21,$9f,$c6,$c4,$7a,$b0,$2e,$22,$bf,$db,$7c,$43,$3f
	dc.b	$8c,$4e,$20,$df,$ec,$bb,$10,$cb,$8b,$88,$e7,$f6,$b1,$15,$fe,$c2
	dc.b	$71,$0c,$fe,$57,$cb,$10,$cb,$1d,$8d,$cd,$65,$b5,$d5,$6c,$70,$fd
	dc.b	$f2,$8d,$be,$f5,$7d,$3c,$e5,$61,$59,$77,$d6,$94,$59,$c1,$68,$90
	dc.b	$0c,$c7,$69,$f6,$35,$fe,$4d,$c3,$7a,$88,$d5,$4f,$68,$69,$12,$a8
	dc.b	$1f,$f2,$fd,$62,$7c,$9f,$0d,$38,$f4,$77,$e9,$b3,$f3,$7e,$ce,$c2
	dc.b	$47,$5b,$df,$28,$17,$ef,$69,$07,$43,$bb,$ed,$ce,$d8,$8e,$59,$1b
	dc.b	$3a,$d3,$31,$0e,$c6,$c3,$bb,$34,$d4,$29,$fd,$ac,$01,$be,$a8,$69
	dc.b	$10,$10,$98,$d4,$57,$fd,$0d,$de,$9b,$e9,$e1,$dd,$7b,$98,$f0,$f2
	dc.b	$7e,$36,$b5,$ac,$a9,$60,$18,$7f,$c9,$c3,$07,$6a,$80,$db,$5c,$14
	dc.b	$8c,$6a,$53,$64,$24,$ae,$55,$a2,$7e,$f8,$f6,$82,$fe,$68,$f5,$82
	dc.b	$44,$24,$7d,$44,$5f,$32,$1c,$bd,$1d,$2d,$0b,$34,$1a,$a2,$e7,$0e
	dc.b	$b9,$67,$1a,$d6,$11,$b9,$ec,$6e,$89,$58,$6c,$ed,$67,$02,$4f,$f2
	dc.b	$80,$69,$c0,$d3,$90,$7c,$64,$ef,$3a,$1f,$9c,$63,$53,$31,$06,$65
	dc.b	$57,$c9,$ca,$db,$3b,$23,$f7,$31,$df,$df,$1e,$ce,$cb,$6e,$c2,$f4
	dc.b	$9e,$b3,$cf,$fb,$f2,$c7,$1f,$97,$c7,$0d,$d5,$4e,$bc,$67,$07,$aa
	dc.b	$8d,$e7,$4e,$2d,$ee,$b4,$dc,$7f,$7b,$a9,$b3,$f7,$f0,$7b,$3f,$21
	dc.b	$c5,$66,$c5,$70,$6e,$6b,$a3,$50,$d5,$5e,$33,$80,$e2,$d4,$66,$99
	dc.b	$0b,$a4,$a3,$30,$d6,$7e,$78,$fd,$8c,$f3,$8d,$08,$29,$ab,$b0,$75
	dc.b	$4a,$b7,$b3,$f2,$ab,$43,$4d,$2e,$c8,$33,$d1,$e0,$dd,$f5,$24,$ba
	dc.b	$bf,$eb,$63,$97,$75,$ac,$e9,$10,$75,$c3,$c6,$fa,$db,$5a,$c1,$d6
	dc.b	$00,$c5,$11,$a2,$35,$f2,$34,$b0,$74,$7e,$b1,$a6,$28,$93,$ad,$3e
	dc.b	$8e,$bc,$d0,$04,$48,$eb,$88,$18,$32,$68,$80,$a4,$9a,$12,$30,$5e
	dc.b	$33,$d5,$77,$10,$4c,$ef,$54,$75,$87,$ae,$2e,$9d,$24,$c3,$67,$eb
	dc.b	$aa,$83,$62,$bb,$a2,$1d,$79,$86,$6e,$46,$d2,$75,$6e,$87,$f2,$03
	dc.b	$4a,$82,$86,$93,$d6,$7d,$a2,$2d,$28,$2b,$a6,$0b,$0b,$b6,$ba,$22
	dc.b	$cc,$19,$09,$f4,$1a,$00,$ff,$df,$db,$87,$75,$12,$b7,$c2,$70,$9a
	dc.b	$a4,$ba,$b5,$93,$7d,$9e,$e7,$d5,$2e,$97,$db,$d4,$e0,$e2,$e2,$3c
	dc.b	$05,$d0,$bb,$a2,$0a,$27,$4d,$5f,$37,$c2,$73,$ec,$5a,$8b,$99,$41
	dc.b	$74,$96,$dd,$ae,$64,$16,$c4,$db,$6a,$c0,$31,$82,$6d,$ee,$4c,$c9
	dc.b	$28,$bb,$8f,$c2,$7a,$d5,$68,$61,$e6,$ea,$e2,$29,$9f,$05,$4f,$da
	dc.b	$e8,$73,$bf,$5d,$76,$75,$e5,$81,$6d,$68,$08,$c6,$96,$f2,$b8,$e8
	dc.b	$d8,$81,$5b,$af,$23,$af,$28,$d2,$54,$2e,$e2,$d1,$64,$ba,$5e,$da
	dc.b	$07,$14,$c4,$7c,$da,$24,$47,$ee,$5d,$c8,$9a,$be,$2f,$ca,$43,$bb
	dc.b	$89,$c1,$34,$ca,$ac,$d6,$82,$cc,$8f,$d7,$6e,$21,$0e,$36,$9d,$9c
	dc.b	$80,$bb,$8c,$00,$42,$ee,$88,$08,$a0,$3c,$f3,$48,$61,$4a,$15,$72
	dc.b	$3e,$d4,$61,$95,$8b,$d3,$eb,$f6,$82,$0f,$36,$8e,$92,$b8,$0d,$26
	dc.b	$a8,$75,$8e,$77,$88,$3c,$a4,$5d,$5d,$83,$70,$c9,$a2,$2a,$e2,$68
	dc.b	$01,$c9,$aa,$33,$ab,$83,$85,$d0,$a9,$3f,$9b,$a7,$8f,$95,$c6,$16
	dc.b	$62,$0d,$b5,$69,$75,$df,$1d,$41,$6d,$78,$0b,$c6,$1b,$12,$07,$5d
	dc.b	$b3,$14,$5f,$78,$55,$84,$20,$a2,$62,$20,$66,$4e,$eb,$81,$8b,$c8
	dc.b	$45,$e3,$84,$5e,$a0,$cf,$fe,$a2,$db,$51,$2d,$f3,$6c,$d0,$f7,$62
	dc.b	$27,$48,$b9,$17,$6c,$3d,$e6,$83,$5d,$e1,$52,$6f,$20,$2d,$61,$db
	dc.b	$b6,$2c,$2a,$da,$7a,$6c,$20,$7c,$a0,$2c,$3d,$32,$23,$3a,$b2,$92
	dc.b	$34,$15,$cd,$aa,$43,$26,$b0,$10,$6d,$0b,$99,$95,$82,$9d,$5c,$a1
	dc.b	$73,$b3,$0e,$52,$55,$33,$e2,$48,$41,$1d,$58,$37,$1c,$10,$5f,$2b
	dc.b	$4f,$91,$74,$8d,$d8,$ad,$46,$1b,$31,$6a,$78,$be,$f5,$bc,$ab,$d0
	dc.b	$07,$72,$c1,$2e,$3a,$7c,$e9,$24,$bc,$1c,$fa,$a3,$f6,$04,$f7,$0b
	dc.b	$c8,$9b,$a2,$22,$72,$34,$ef,$1a,$1b,$6e,$88,$80,$d8,$de,$08,$29
	dc.b	$62,$de,$ea,$94,$55,$68,$46,$d4,$2e,$0a,$03,$60,$e3,$cb,$35,$17
	dc.b	$36,$05,$30,$54,$14,$83,$f6,$83,$a0,$1c,$14,$a0,$aa,$4d,$e5,$6a
	dc.b	$91,$08,$59,$20,$af,$3c,$80,$d7,$da,$90,$4b,$6d,$ef,$97,$b0,$16
	dc.b	$be,$9d,$43,$8a,$2d,$f9,$1a,$82,$ac,$fd,$fd,$77,$49,$60,$0a,$13
	dc.b	$79,$07,$56,$1d,$a5,$62,$ee,$c4,$56,$2d,$93,$b7,$5e,$06,$d2,$1a
	dc.b	$f8,$29,$7c,$88,$c5,$5a,$42,$f6,$20,$41,$f9,$00,$be,$d4,$95,$3a
	dc.b	$00,$c4,$50,$67,$c0,$25,$29,$69,$82,$35,$b9,$11,$b4,$0a,$58,$29
	dc.b	$bc,$d2,$18,$a8,$c3,$97,$e1,$d6,$07,$39,$d8,$5c,$16,$e2,$52,$13
	dc.b	$e7,$bc,$3a,$08,$c1,$9a,$b7,$7b,$a1,$5f,$18,$8d,$8b,$1b,$7a,$d5
	dc.b	$53,$1b,$77,$72,$87,$dd,$a8,$e7,$47,$50,$eb,$62,$d3,$47,$fe,$e6
	dc.b	$71,$a7,$e5,$59,$68,$05,$33,$7c,$44,$f6,$1d,$d2,$f6,$f6,$91,$cb
	dc.b	$81,$77,$a0,$29,$88,$2c,$f6,$98,$1c,$d2,$58,$c5,$f3,$17,$ba,$07
	dc.b	$a1,$1a,$88,$44,$4c,$02,$e8,$b7,$24,$3e,$6a,$e7,$57,$e1,$65,$c4
	dc.b	$e8,$72,$6a,$51,$23,$af,$59,$bc,$aa,$c3,$fb,$8a,$e8,$47,$1f,$87
	dc.b	$2c,$3b,$45,$73,$a9,$22,$dc,$41,$49,$d4,$4c,$59,$bb,$32,$23,$d5
	dc.b	$d8,$94,$15,$0e,$44,$85,$01,$60,$03,$94,$55,$da,$8e,$77,$26,$9f
	dc.b	$7f,$2a,$bf,$7e,$81,$5f,$81,$73,$04,$7e,$67,$26,$ed,$20,$eb,$1f
	dc.b	$3c,$d2,$10,$da,$dc,$d3,$5c,$1d,$43,$89,$bf,$df,$10,$59,$f9,$8b
	dc.b	$c0,$dc,$e2,$ba,$6d,$41,$15,$9d,$eb,$b9,$46,$5e,$36,$0b,$52,$7b
	dc.b	$12,$0c,$f6,$e8,$95,$49,$58,$74,$2d,$b7,$12,$a9,$d7,$99,$d7,$59
	dc.b	$e8,$d7,$b2,$f9,$50,$bc,$73,$de,$03,$ce,$aa,$d4,$8a,$ec,$dc,$da
	dc.b	$38,$67,$10,$b9,$82,$29,$30,$e9,$02,$6e,$89,$aa,$77,$80,$dc,$43
	dc.b	$e4,$56,$c7,$2c,$d8,$59,$c8,$33,$86,$8b,$54,$f2,$15,$af,$ff,$0b
	dc.b	$2b,$b3,$22,$3a,$7b,$22,$77,$66,$d6,$cb,$0a,$eb,$ea,$b1,$15,$5c
	dc.b	$b4,$10,$53,$f2,$1c,$47,$43,$be,$69,$11,$5b,$e4,$1b,$a8,$b6,$c8
	dc.b	$65,$2b,$6f,$9c,$f2,$2a,$b0,$e9,$de,$48,$bb,$32,$b2,$0a,$43,$8b
	dc.b	$2f,$0e,$cc,$11,$aa,$54,$a9,$d3,$81,$6c,$e8,$bb,$cd,$21,$4d,$8d
	dc.b	$4d,$dd,$f9,$ad,$40,$c7,$0f,$be,$20,$8d,$c8,$5a,$ce,$a5,$b5,$1e
	dc.b	$39,$5f,$12,$a2,$17,$3d,$86,$2d,$6f,$12,$74,$45,$22,$fd,$23,$2a
	dc.b	$f5,$7d,$66,$33,$bb,$a5,$55,$4a,$da,$4d,$89,$2f,$87,$b4,$e1,$28
	dc.b	$d8,$0f,$e9,$c5,$f8,$3c,$96,$02,$a5,$0e,$2b,$de,$81,$54,$a9,$c9
	dc.b	$2c,$26,$41,$37,$12,$3a,$ac,$94,$12,$ec,$b2,$e2,$40,$1d,$08,$43
	dc.b	$b1,$30,$ae,$28,$f5,$d2,$6a,$be,$49,$35,$1b,$16,$50,$f0,$9a,$ba
	dc.b	$fd,$38,$9b,$fa,$7a,$31,$f9,$f7,$eb,$1a,$b0,$1b,$16,$35,$84,$36
	dc.b	$b9,$31,$2b,$57,$2f,$ae,$99,$11,$5d,$ba,$a7,$6c,$0e,$82,$29,$11
	dc.b	$14,$68,$00,$79,$01,$08,$85,$56,$63,$3b,$8b,$90,$91,$23,$4a,$4e
	dc.b	$c9,$e2,$d9,$82,$2c,$c3,$80,$34,$31,$47,$5b,$f6,$c1,$9f,$ec,$6b
	dc.b	$f7,$6c,$19,$ff,$16,$0e,$ff,$96,$ec,$09,$fe,$17,$6d,$b0,$53,$f9
	dc.b	$42,$55,$f2,$c0,$5f,$f9,$58,$1c,$c3,$fb,$25,$4c,$f7,$66,$d4,$76
	dc.b	$d6,$89,$38,$1a,$15,$f6,$75,$12,$3a,$b4,$0b,$08,$f5,$bc,$69,$2d
	dc.b	$b3,$b6,$24,$8a,$f5,$e8,$c3,$ff,$e2,$10,$59,$fe,$b5,$27,$12,$a9
	dc.b	$e4,$39,$6d,$12,$42,$64,$7a,$bd,$c1,$7a,$95,$c3,$57,$c6,$26,$2c
	dc.b	$78,$75,$4a,$c7,$92,$34,$6a,$a1,$9a,$53,$56,$ac,$29,$c8,$2e,$dc
	dc.b	$1c,$d2,$fe,$8f,$83,$ce,$51,$ad,$a9,$09,$45,$c9,$d3,$19,$5c,$3d
	dc.b	$95,$dd,$18,$f8,$e7,$06,$42,$96,$fa,$10,$b3,$3f,$5e,$dc,$42,$d6
	dc.b	$cf,$50,$08,$f8,$2b,$49,$b3,$13,$28,$0a,$8c,$43,$9c,$d7,$33,$f0
	dc.b	$24,$57,$2a,$0a,$f2,$b6,$db,$84,$ac,$01,$16,$37,$b0,$ef,$34,$11
	dc.b	$61,$18,$28,$2c,$68,$2d,$42,$bc,$d0,$cf,$6c,$93,$61,$fd,$6e,$c9
	dc.b	$cc,$dc,$5b,$21,$2f,$8b,$c8,$1b,$b2,$04,$24,$dc,$e5,$83,$de,$a7
	dc.b	$c9,$33,$07,$38,$aa,$26,$c2,$b8,$4e,$34,$65,$e1,$b4,$55,$60,$2b
	dc.b	$c7,$f5,$a4,$34,$6d,$cb,$de,$bd,$ee,$44,$3b,$e5,$b7,$6a,$7e,$f7
	dc.b	$2b,$ea,$25,$a1,$b9,$59,$61,$b4,$50,$03,$43,$c9,$d6,$7c,$7d,$21
	dc.b	$aa,$8c,$02,$b7,$e0,$c8,$2e,$b8,$e7,$61,$67,$33,$08,$a5,$65,$71
	dc.b	$aa,$91,$3d,$7a,$6d,$b9,$79,$af,$66,$47,$16,$90,$63,$f9,$ff,$5c
	dc.b	$1e,$aa,$55,$f5,$8a,$d4,$5b,$37,$7a,$91,$16,$ad,$01,$4f,$94,$da
	dc.b	$57,$27,$4a,$73,$62,$f3,$ac,$d2,$02,$ac,$39,$7c,$53,$88,$45,$6b
	dc.b	$cf,$58,$25,$d5,$60,$45,$46,$dc,$bc,$4f,$c8,$d9,$6e,$84,$9e,$70
	dc.b	$13,$cf,$34,$32,$fa,$3b,$4f,$7a,$fc,$b2,$8e,$d1,$de,$28,$64,$5e
	dc.b	$d1,$15,$56,$bc,$42,$98,$d8,$f5,$58,$a5,$2d,$de,$ad,$32,$f7,$d2
	dc.b	$dd,$1f,$aa,$1e,$2c,$65,$e1,$88,$4e,$cb,$2b,$76,$be,$12,$9d,$c8
	dc.b	$9b,$1e,$fc,$88,$d3,$34,$d3,$7e,$6d,$2e,$d6,$9d,$6b,$90,$14,$32
	dc.b	$35,$27,$58,$86,$1b,$c3,$15,$c9,$1c,$03,$05,$0c,$ca,$2e,$cf,$85
	dc.b	$12,$2d,$eb,$da,$35,$9f,$16,$e2,$24,$2c,$15,$ab,$62,$9f,$5e,$a4
	dc.b	$3d,$8f,$a3,$21,$ba,$18,$2d,$bb,$3e,$2c,$18,$d4,$59,$a2,$aa,$32
	dc.b	$d5,$cd,$15,$53,$7c,$e2,$cf,$1f,$d4,$8b,$7c,$3c,$88,$19,$07,$a0
	dc.b	$3a,$59,$88,$45,$b3,$99,$ec,$b3,$6f,$b5,$21,$b0,$ad,$11,$4f,$91
	dc.b	$b3,$d1,$a3,$f6,$20,$97,$f5,$e6,$88,$be,$d9,$dd,$f5,$a0,$72,$22
	dc.b	$7a,$99,$d8,$0a,$73,$9a,$f7,$25,$bf,$9e,$b1,$62,$98,$f3,$22,$22
	dc.b	$4d,$75,$9d,$f8,$e3,$4e,$d0,$e1,$13,$66,$2b,$84,$e2,$c2,$b8,$b4
	dc.b	$8b,$72,$76,$22,$d8,$90,$66,$db,$f3,$73,$d1,$6c,$45,$7a,$20,$ed
	dc.b	$34,$0f,$7e,$6e,$5a,$58,$0e,$d9,$80,$df,$a9,$c7,$80,$65,$f1,$b0
	dc.b	$57,$d0,$43,$e8,$4c,$29,$60,$f3,$f3,$b6,$55,$c4,$44,$8a,$38,$d7
	dc.b	$7b,$01,$c8,$4d,$7c,$07,$31,$ad,$13,$1a,$bc,$30,$6b,$97,$bc,$c0
	dc.b	$7a,$f6,$ba,$fe,$06,$07,$2d,$5c,$9e,$4a,$c0,$73,$77,$4d,$04,$a5
	dc.b	$1a,$66,$1f,$9b,$20,$6c,$5a,$02,$d0,$60,$30,$37,$b9,$c8,$a7,$39
	dc.b	$ae,$48,$d9,$66,$23,$6e,$03,$80,$ac,$01,$10,$52,$07,$79,$a2,$23
	dc.b	$12,$9b,$cf,$49,$7d,$01,$9b,$98,$76,$99,$ca,$24,$a4,$59,$4a,$69
	dc.b	$bb,$9e,$8f,$88,$9c,$d9,$d8,$a6,$b6,$24,$f8,$57,$79,$b4,$cf,$62
	dc.b	$c6,$99,$75,$50,$6a,$a5,$3e,$53,$ae,$88,$7a,$6e,$a4,$eb,$ed,$f3
	dc.b	$8d,$5d,$52,$cf,$6f,$45,$5a,$9f,$6a,$01,$86,$41,$2c,$36,$28,$90
	dc.b	$a4,$3d,$8c,$0b,$c4,$1b,$53,$61,$34,$f4,$32,$77,$c2,$aa,$80,$ca
	dc.b	$b9,$d4,$5b,$25,$55,$7c,$90,$b9,$01,$3b,$c4,$39,$3d,$b9,$0e,$20
	dc.b	$60,$f1,$44,$88,$43,$f0,$13,$30,$19,$e2,$a8,$47,$e7,$c8,$d5,$c8
	dc.b	$92,$c6,$71,$d6,$27,$44,$62,$5e,$b1,$d4,$4c,$35,$6c,$6d,$52,$19
	dc.b	$91,$0e,$d8,$58,$2d,$2a,$f6,$55,$91,$b2,$c3,$e9,$d9,$49,$55,$b3
	dc.b	$40,$ca,$74,$ce,$dc,$40,$7f,$cb,$7e,$21,$3f,$ee,$c4,$27,$ff,$2f
	dc.b	$3a,$4b,$ad,$45,$a3,$e4,$c3,$b5,$83,$74,$66,$2b,$17,$53,$11,$bf
	dc.b	$db,$b3,$93,$1f,$ca,$29,$a3,$15,$e5,$f9,$3f,$be,$ce,$11,$0e,$62
	dc.b	$b9,$44,$7e,$39,$f2,$6e,$16,$e2,$a6,$cc,$c1,$b1,$d5,$22,$e9,$b7
	dc.b	$fe,$38,$f6,$e1,$22,$2d,$03,$37,$43,$23,$ac,$f4,$f7,$40,$33,$10
	dc.b	$43,$55,$25,$68,$6c,$37,$42,$10,$ba,$83,$b3,$00,$c7,$19,$aa,$f6
	dc.b	$52,$bc,$a0,$ce,$ac,$35,$98,$72,$db,$97,$70,$cf,$b7,$49,$91,$98
	dc.b	$0a,$11,$88,$32,$cc,$5c,$86,$a6,$a6,$bf,$d3,$05,$83,$f8,$cd,$fd
	dc.b	$ca,$f8,$c1,$01,$66,$60,$8b,$d9,$7a,$a2,$8f,$b2,$1c,$67,$52,$66
	dc.b	$ce,$0a,$d1,$09,$79,$18,$f0,$f0,$0f,$98,$8e,$3a,$c6,$90,$0f,$bc
	dc.b	$5d,$26,$6a,$b0,$0d,$b8,$f0,$56,$21,$cc,$c1,$97,$02,$d8,$7b,$bc
	dc.b	$d1,$18,$3e,$9a,$35,$e6,$d4,$6a,$b3,$e6,$d5,$3e,$83,$6e,$31,$25
	dc.b	$70,$b2,$fe,$ab,$e8,$db,$8b,$46,$b5,$f1,$61,$fb,$44,$c9,$44,$39
	dc.b	$b4,$26,$c6,$65,$57,$e9,$97,$25,$60,$cc,$6c,$96,$2a,$45,$e8,$f1
	dc.b	$95,$9c,$95,$2e,$7e,$51,$c9,$e5,$19,$b8,$58,$3a,$34,$03,$15,$80
	dc.b	$72,$b3,$98,$76,$a5,$18,$90,$94,$e2,$90,$75,$35,$8b,$05,$d6,$93
	dc.b	$61,$49,$82,$c3,$b3,$76,$01,$8d,$5a,$47,$aa,$23,$8f,$73,$2e,$c4
	dc.b	$d8,$52,$88,$28,$46,$57,$ab,$4e,$fa,$af,$db,$da,$36,$fe,$bf,$68
	dc.b	$14,$f2,$27,$47,$d6,$f2,$60,$8b,$ed,$5e,$a3,$9e,$20,$a2,$c3,$02
	dc.b	$f3,$2a,$29,$3a,$e4,$83,$81,$d2,$8f,$0e,$d8,$f8,$55,$d3,$8c,$24
	dc.b	$0a,$38,$2a,$3e,$59,$10,$0d,$ef,$a6,$1d,$2f,$21,$4d,$dd,$0a,$7e
	dc.b	$17,$02,$b7,$9a,$23,$16,$76,$b7,$d6,$ba,$e4,$03,$d3,$0e,$d2,$27
	dc.b	$2e,$6d,$15,$54,$5b,$b1,$0f,$38,$af,$95,$54,$66,$9a,$f5,$5e,$32
	dc.b	$df,$39,$11,$2e,$5b,$86,$1e,$a9,$9f,$90,$1c,$8c,$55,$9b,$a2,$19
	dc.b	$22,$fc,$7b,$41,$ad,$06,$da,$4d,$8e,$05,$a4,$dc,$3f,$e2,$9f,$74
	dc.b	$03,$19,$44,$10,$08,$b4,$18,$ce,$84,$36,$62,$0e,$99,$d9,$7b,$0b
	dc.b	$a2,$35,$71,$8d,$77,$6c,$51,$e5,$6c,$f5,$5d,$c8,$b8,$1a,$36,$96
	dc.b	$02,$c6,$29,$37,$43,$49,$cd,$c2,$47,$ba,$a9,$0f,$d1,$a0,$5f,$4a
	dc.b	$9a,$04,$86,$64,$24,$00,$1c,$c2,$29,$55,$7a,$97,$5a,$d9,$31,$40
	dc.b	$a8,$b6,$54,$52,$c7,$fc,$8e,$bd,$a6,$55,$fc,$da,$b0,$32,$ee,$e8
	dc.b	$f6,$07,$c3,$4b,$0e,$52,$2c,$0e,$50,$ec,$1c,$f9,$61,$b2,$68,$ad
	dc.b	$bc,$d2,$14,$bf,$e9,$77,$68,$6e,$62,$b9,$9b,$64,$59,$e3,$94,$83
	dc.b	$b1,$7a,$6e,$67,$a1,$93,$71,$63,$21,$44,$c6,$97,$f8,$a2,$25,$5d
	dc.b	$88,$1c,$34,$2b,$94,$55,$9d,$6d,$24,$6d,$2b,$f9,$3b,$3e,$26,$7b
	dc.b	$69,$36,$55,$ae,$91,$83,$a7,$23,$d6,$ff,$b4,$0a,$73,$51,$24,$00
	dc.b	$de,$6d,$1c,$95,$82,$ca,$4e,$97,$7f,$51,$49,$fd,$11,$a8,$74,$05
	dc.b	$14,$80,$fd,$34,$3e,$65,$a0,$3a,$e2,$c2,$bc,$9f,$4e,$2d,$08,$fe
	dc.b	$e9,$07,$76,$8e,$7a,$ec,$dd,$e4,$6f,$ca,$c5,$a1,$b9,$0d,$68,$45
	dc.b	$bb,$d4,$15,$0a,$45,$91,$e4,$6a,$eb,$87,$04,$e9,$33,$1b,$6f,$37
	dc.b	$cf,$2a,$99,$b9,$01,$e3,$9f,$60,$14,$36,$96,$2c,$c1,$dd,$b1,$c8
	dc.b	$9f,$5e,$42,$9d,$bd,$61,$9a,$be,$80,$ef,$34,$75,$83,$e7,$78,$79
	dc.b	$9b,$1e,$5d,$52,$9b,$25,$d5,$59,$0d,$a5,$46,$f4,$1d,$bd,$a6,$c0
	dc.b	$f4,$5b,$5e,$5d,$56,$ae,$8c,$8f,$94,$e7,$39,$ea,$21,$cd,$ad,$cc
	dc.b	$93,$81,$86,$45,$eb,$65,$8b,$45,$85,$a3,$6e,$97,$5c,$ab,$6f,$1d
	dc.b	$b3,$8e,$b6,$79,$85,$f9,$dd,$fa,$ef,$20,$db,$6b,$63,$91,$ba,$68
	dc.b	$66,$f4,$36,$28,$64,$eb,$4f,$1d,$32,$54,$c4,$6a,$75,$8f,$a6,$e9
	dc.b	$d4,$e6,$83,$aa,$50,$0e,$63,$b7,$bd,$66,$03,$04,$11,$6a,$d6,$84
	dc.b	$77,$75,$77,$57,$b4,$33,$e6,$1b,$c8,$0f,$fb,$75,$f7,$a8,$52,$98
	dc.b	$33,$6b,$2d,$05,$27,$31,$13,$96,$8b,$4c,$81,$e2,$aa,$bc,$d1,$a0
	dc.b	$86,$fd,$11,$8d,$12,$20,$a6,$57,$03,$ec,$6f,$7a,$ce,$60,$65,$92
	dc.b	$1a,$7d,$61,$c9,$98,$df,$21,$49,$5e,$40,$8d,$82,$c1,$79,$a4,$37
	dc.b	$bc,$63,$47,$95,$7f,$be,$56,$3d,$52,$f2,$6a,$87,$74,$db,$74,$dd
	dc.b	$e7,$73,$26,$a8,$f7,$59,$d7,$12,$1e,$cd,$0d,$10,$e7,$88,$99,$1b
	dc.b	$8d,$05,$e7,$14,$b4,$2e,$b7,$73,$6c,$6a,$6f,$1c,$ad,$6b,$a6,$4d
	dc.b	$85,$b2,$1a,$bf,$b4,$c7,$6a,$e4,$1b,$57,$1f,$08,$6a,$3b,$28,$75
	dc.b	$a5,$86,$92,$9d,$36,$d9,$c8,$f2,$b9,$42,$35,$65,$94,$ad,$3b,$65
	dc.b	$62,$d0,$f9,$e5,$c0,$84,$39,$96,$2e,$68,$27,$d0,$8e,$ef,$5d,$e3
	dc.b	$88,$d9,$9c,$85,$b5,$21,$7d,$48,$48,$d0,$05,$79,$2a,$a8,$ad,$d4
	dc.b	$a3,$45,$92,$64,$4f,$8a,$aa,$99,$6b,$92,$0f,$79,$05,$ef,$98,$69
	dc.b	$f5,$81,$b2,$c6,$4f,$60,$30,$0c,$05,$cd,$6e,$7e,$31,$98,$d6,$38
	dc.b	$d4,$87,$cb,$6c,$f3,$48,$5a,$2a,$b7,$f3,$b1,$e2,$0c,$66,$96,$86
	dc.b	$69,$c1,$0c,$9a,$a0,$3e,$17,$77,$7a,$1b,$f6,$93,$54,$d2,$1b,$ef
	dc.b	$4d,$dd,$8a,$7a,$21,$ce,$b7,$6a,$16,$fc,$6a,$a4,$a2,$c7,$38,$8c
	dc.b	$2b,$0d,$db,$fb,$82,$fd,$51,$e8,$b0,$d7,$b0,$71,$97,$16,$a0,$3f
	dc.b	$9b,$6a,$d3,$f5,$e8,$40,$ce,$be,$41,$b2,$f7,$4b,$5a,$4e,$85,$6a
	dc.b	$f7,$2b,$2a,$1c,$93,$ea,$71,$d9,$db,$68,$7c,$ea,$f9,$f1,$f8,$25
	dc.b	$55,$51,$a4,$6c,$d2,$0f,$50,$e0,$2d,$6c,$c0,$6a,$c5,$ae,$e9,$e4
	dc.b	$8c,$9a,$83,$e5,$41,$97,$a4,$1c,$52,$26,$35,$07,$3a,$79,$50,$ca
	dc.b	$1b,$c8,$eb,$c3,$40,$d4,$c2,$0c,$9f,$80,$54,$ae,$33,$ec,$26,$8e
	dc.b	$31,$01,$9d,$7f,$67,$e0,$0d,$f9,$01,$9f,$84,$82,$b2,$96,$f7,$9a
	dc.b	$3a,$88,$7a,$e2,$78,$6f,$84,$06,$2d,$45,$50,$c2,$c8,$d1,$b4,$0d
	dc.b	$dd,$e7,$c2,$a5,$ed,$1c,$85,$aa,$6a,$28,$a8,$21,$a4,$e8,$9b,$7a
	dc.b	$ee,$b0,$07,$0a,$f5,$aa,$f0,$c5,$4c,$54,$39,$3b,$68,$5e,$85,$67
	dc.b	$8e,$e6,$d3,$50,$e3,$cb,$5d,$47,$36,$6d,$19,$fa,$f5,$7a,$20,$d9
	dc.b	$bb,$49,$5d,$3a,$15,$24,$f9,$87,$94,$52,$2e,$8c,$a3,$43,$29,$ed
	dc.b	$08,$7f,$60,$0c,$d0,$87,$6b,$04,$aa,$f9,$0e,$4f,$5d,$c9,$a6,$2a
	dc.b	$d8,$0d,$52,$dd,$a1,$98,$fe,$b3,$34,$03,$26,$08,$89,$82,$d2,$91
	dc.b	$16,$4f,$33,$20,$d5,$e5,$43,$37,$02,$82,$05,$00,$a6,$10,$e9,$f0
	dc.b	$0a,$e3,$88,$22,$eb,$8e,$38,$40,$46,$40,$cc,$02,$d9,$41,$9b,$8e
	dc.b	$01,$17,$77,$9a,$19,$dd,$ca,$ad,$c4,$fb,$b8,$18,$8c,$7d,$56,$f8
	dc.b	$b2,$a6,$e4,$95,$c2,$ea,$e1,$50,$af,$10,$ad,$b4,$c6,$a1,$7d,$a7
	dc.b	$b9,$34,$a5,$44,$da,$b7,$58,$29,$02,$7a,$d5,$78,$56,$a9,$85,$a1
	dc.b	$de,$4e,$df,$ef,$62,$4d,$25,$08,$da,$45,$22,$eb,$38,$56,$9e,$03
	dc.b	$e8,$0a,$5d,$44,$6a,$f4,$66,$b3,$ca,$71,$85,$d5,$d1,$28,$d0,$36
	dc.b	$80,$d5,$d0,$b8,$43,$2e,$d0,$87,$0f,$c7,$8d,$0d,$8c,$c7,$c9,$eb
	dc.b	$b8,$e5,$a7,$12,$dd,$35,$51,$cf,$bd,$11,$4f,$34,$e0,$a6,$81,$7a
	dc.b	$d3,$46,$59,$90,$a2,$74,$4c,$ea,$b7,$79,$84,$22,$72,$00,$f6,$58
	dc.b	$e4,$ce,$10,$21,$94,$b3,$99,$bc,$a0,$cb,$dc,$70,$3e,$23,$79,$a1
	dc.b	$9b,$38,$dd,$e9,$9e,$f0,$ca,$7d,$6a,$ad,$f0,$06,$1a,$e6,$ae,$f2
	dc.b	$2e,$c4,$d7,$e2,$b1,$aa,$82,$b0,$2a,$1c,$b3,$44,$2b,$77,$88,$db
	dc.b	$fb,$d4,$17,$81,$5a,$a1,$2c,$fe,$9a,$e0,$a4,$85,$ef,$af,$69,$91
	dc.b	$4c,$be,$dd,$91,$c5,$ab,$55,$d0,$14,$0a,$20,$af,$42,$96,$22,$6a
	dc.b	$f7,$21,$f4,$0f,$92,$2b,$ef,$54,$ae,$02,$a5,$95,$3b,$40,$19,$d9
	dc.b	$e3,$41,$4e,$94,$7e,$4c,$5e,$2b,$9f,$9a,$7e,$f2,$86,$56,$1d,$f7
	dc.b	$27,$52,$03,$8a,$ef,$0b,$3b,$44,$19,$64,$79,$51,$84,$6c,$73,$20
	dc.b	$b3,$9d,$ea,$f8,$48,$35,$0a,$00,$17,$88,$07,$00,$f8,$07,$3d,$70
	dc.b	$01,$eb,$de,$68,$64,$f7,$2a,$2f,$93,$1d,$66,$50,$0e,$6e,$04,$50
	dc.b	$a3,$55,$41,$de,$44,$0a,$3b,$c9,$63,$5c,$6d,$e5,$bc,$98,$a2,$88
	dc.b	$54,$5e,$70,$7d,$ca,$30,$d8,$e0,$ac,$56,$24,$bf,$5f,$6d,$a5,$d5
	dc.b	$61,$f3,$a3,$68,$9e,$4a,$fc,$b6,$9a,$f7,$36,$dd,$7c,$71,$fa,$e5
	dc.b	$0e,$ad,$55,$14,$88,$0b,$bb,$0f,$0c,$e1,$29,$a0,$b4,$86,$4e,$0f
	dc.b	$20,$2d,$66,$d0,$03,$2c,$14,$d9,$1f,$22,$ee,$ef,$5c,$c8,$c9,$33
	dc.b	$ca,$19,$6a,$2d,$d0,$0f,$59,$13,$e3,$c3,$48,$30,$0e,$34,$82,$f7
	dc.b	$2a,$33,$ca,$ae,$64,$07,$bf,$bf,$56,$d9,$42,$36,$b0,$55,$10,$21
	dc.b	$26,$2e,$7e,$aa,$5e,$50,$67,$67,$c7,$24,$9c,$2d,$e5,$cf,$8c,$29
	dc.b	$a9,$d7,$e1,$a4,$0f,$22,$e4,$1f,$22,$ab,$b4,$56,$1b,$ad,$50,$94
	dc.b	$e2,$ff,$db,$38,$8a,$a5,$9c,$b1,$b2,$fe,$aa,$c3,$78,$25,$03,$d9
	dc.b	$a0,$ef,$ec,$9d,$b4,$aa,$a9,$33,$b4,$d1,$2f,$5c,$ee,$a3,$08,$f7
	dc.b	$10,$37,$b2,$c6,$cb,$92,$c1,$49,$41,$53,$d7,$71,$6f,$4f,$d4,$31
	dc.b	$68,$6f,$8d,$5b,$2a,$e1,$bd,$77,$00,$a2,$c8,$fa,$e1,$4a,$22,$e4
	dc.b	$59,$ec,$66,$46,$5a,$e5,$65,$48,$6a,$85,$4c,$66,$8d,$96,$8b,$c3
	dc.b	$4e,$75,$4d,$5d,$bb,$32,$05,$5c,$c8,$64,$46,$bb,$d5,$b1,$d9,$e1
	dc.b	$6f,$21,$06,$15,$2f,$20,$ab,$58,$4a,$56,$fe,$a4,$66,$00,$19,$82
	dc.b	$2a,$40,$ed,$c5,$21,$b4,$d3,$8a,$bc,$ef,$1f,$fc,$66,$2c,$f9,$0e
	dc.b	$ad,$b0,$19,$f9,$6d,$05,$70,$1f,$b8,$48,$c0,$db,$9c,$48,$8b,$59
	dc.b	$30,$de,$eb,$e2,$f2,$34,$1a,$89,$0c,$5e,$70,$2a,$b7,$c8,$c3,$8d
	dc.b	$84,$b9,$bf,$90,$ea,$ae,$ff,$79,$12,$af,$e4,$e6,$37,$ea,$f3,$b9
	dc.b	$e8,$a2,$c9,$72,$79,$19,$f0,$0f,$84,$82,$ea,$a4,$62,$81,$b1,$6d
	dc.b	$17,$77,$16,$ff,$bd,$40,$69,$93,$68,$bf,$7a,$77,$e4,$0a,$62,$3c
	dc.b	$80,$67,$d2,$e5,$11,$bd,$4b,$5c,$74,$c8,$c7,$3b,$32,$a4,$2a,$57
	dc.b	$74,$5a,$49,$cc,$b2,$47,$3a,$64,$82,$bb,$59,$90,$cb,$54,$43,$3a
	dc.b	$cf,$09,$18,$ab,$93,$30,$18,$8c,$d5,$64,$25,$26,$ba,$a8,$83,$90
	dc.b	$4e,$f2,$0c,$d9,$15,$68,$29,$1e,$68,$a5,$af,$96,$ef,$4c,$f6,$24
	dc.b	$aa,$47,$0c,$0a,$a5,$5c,$bb,$f3,$27,$6f,$1b,$ef,$7b,$44,$6a,$15
	dc.b	$34,$e9,$bc,$d4,$38,$0f,$44,$87,$77,$88,$12,$7f,$23,$0d,$f4,$06
	dc.b	$b4,$ba,$9e,$b1,$bf,$3b,$b3,$54,$d0,$7f,$a1,$57,$93,$17,$5f,$58
	dc.b	$78,$0e,$b4,$d6,$c7,$a0,$00,$89,$02,$de,$42,$30,$80,$30,$28,$b3
	dc.b	$d3,$7f,$77,$ab,$8c,$69,$dd,$ea,$24,$a4,$8d,$e8,$f9,$03,$4b,$50
	dc.b	$a5,$66,$c6,$88,$d5,$dd,$4c,$83,$56,$e2,$ef,$29,$0f,$2d,$8e,$8d
	dc.b	$04,$40,$d5,$e8,$db,$e0,$8d,$c8,$82,$b9,$a4,$18,$b5,$48,$44,$0a
	dc.b	$24,$cc,$6b,$e5,$30,$07,$ad,$43,$03,$7a,$10,$61,$29,$66,$0c,$66
	dc.b	$39,$44,$37,$1e,$82,$a6,$79,$a1,$58,$18,$09,$96,$6a,$4d,$45,$ab
	dc.b	$3a,$11,$12,$8e,$07,$04,$83,$c2,$01,$30,$a8,$5c,$30,$1a,$0e,$87
	dc.b	$c4,$02,$31,$40,$a5,$25,$4a,$a9,$ed,$41,$60,$c0,$a0,$78,$42,$22
	dc.b	$a4,$d7,$32,$59,$4d,$8e,$d3,$93,$d1,$ea,$82,$82,$41,$b9,$34,$da
	dc.b	$8b,$51,$a9,$5a,$6d,$79,$3c,$ae,$67,$35,$9b,$d0,$e8,$b4,$9a,$5d
	dc.b	$4e,$db,$b4,$08,$06,$d2,$e9,$b5,$ab,$2d,$aa,$ed,$8d,$d7,$6c,$b7
	dc.b	$7d,$df,$6c,$b6,$89,$4e,$aa,$d6,$6b,$79,$7d,$1e,$cf,$73,$cd,$e9
	dc.b	$f5,$a6,$54,$ca,$ee,$17,$15,$91,$cb,$69,$b5,$7a,$cd,$bf,$2b,$97
	dc.b	$db,$92,$ca,$65,$55,$7a,$f5,$9a,$d1,$72,$b9,$dd,$6f,$58,$bd,$56
	dc.b	$f7,$85,$ea,$f5,$ca,$e7,$59,$dc,$f6,$fb,$ca,$06,$96,$51,$a9,$15
	dc.b	$6b,$15,$d2,$ef,$89,$e7,$7d,$68,$56,$eb,$ce,$9f,$b9,$34,$b3,$dc
	dc.b	$71,$9c,$5e,$a5,$1e,$c7,$6c,$bd,$f7,$bd,$32,$e9,$ad,$06,$c9,$e2
	dc.b	$f9,$48,$f1,$d9,$ce,$67,$5f,$b0,$05,$92,$5f,$75,$fb,$ce,$37,$9b
	dc.b	$dd,$22,$c3,$4a,$2b,$1c,$7f,$64,$de,$77,$4f,$c4,$71,$39,$11,$d9
	dc.b	$ed,$53,$0f,$a8,$f9,$fd,$28,$78,$2d,$c4,$4a,$63,$6f,$bc,$6c,$26
	dc.b	$79,$8f,$27,$da,$43,$39,$e7,$fc,$64,$f6,$1e,$08,$12,$2d,$7e,$c1
	dc.b	$e1,$3c,$7e,$88,$af,$66,$23,$19,$89,$c5,$2a,$18,$f9,$7f,$7e,$7d
	dc.b	$90,$c0,$f8,$7c,$f1,$ab,$e4,$2a,$79,$5f,$8d,$fd,$e7,$1e,$f8,$bf
	dc.b	$0f,$a1,$0d,$cf,$dc,$2c,$10,$b8,$f6,$82,$38,$03,$84,$fe,$61,$d3
	dc.b	$0f,$d4,$62,$19,$bf,$fd,$80,$a4,$10,$58,$84,$1a,$81,$f0,$84,$41
	dc.b	$21,$f1,$f9,$fd,$ff,$c1,$07,$fc,$7f,$60,$5c,$0f,$e0,$02,$07,$80
	dc.b	$ff,$00,$60,$3f,$f8,$00,$50,$48,$39,$18,$0e,$87,$c6,$a2,$41,$23
	dc.b	$46,$a2,$00,$02
g2embed_title_end

	even
g2embed_title_pal
	dc.b	$00,$00,$00,$00,$0f,$0f,$00,$00,$0f,$0f,$00,$00,$0f,$0f,$00,$00
	dc.b	$0f,$d0,$00,$00,$0d,$a1,$00,$00,$0c,$80,$00,$00,$0a,$70,$00,$00
	dc.b	$07,$40,$00,$00,$04,$20,$00,$00,$05,$00,$00,$00,$00,$43,$00,$00
	dc.b	$04,$45,$00,$00,$07,$66,$00,$00,$08,$78,$00,$00,$07,$45,$00,$00
	dc.b	$07,$34,$00,$00,$05,$23,$00,$00,$07,$10,$00,$00,$08,$21,$00,$00
	dc.b	$0a,$41,$00,$00,$0a,$44,$00,$00,$02,$81,$00,$00,$0a,$66,$00,$00
	dc.b	$0c,$76,$00,$00,$0a,$88,$00,$00,$0c,$88,$00,$00,$0c,$99,$00,$00
	dc.b	$0c,$ba,$00,$00,$0e,$ba,$00,$00,$04,$e1,$00,$00,$0f,$ee,$00,$00
	dc.b	$00,$00,$00,$00,$07,$07,$08,$08,$07,$07,$08,$08,$07,$07,$08,$08
	dc.b	$07,$60,$08,$80,$06,$50,$08,$08,$06,$40,$00,$00,$05,$30,$00,$80
	dc.b	$03,$20,$08,$00,$02,$10,$00,$00,$02,$00,$08,$00,$00,$21,$00,$08
	dc.b	$02,$22,$00,$08,$03,$33,$08,$00,$04,$34,$00,$80,$03,$22,$08,$08
	dc.b	$03,$12,$08,$80,$02,$11,$08,$08,$03,$00,$08,$80,$04,$10,$00,$08
	dc.b	$05,$20,$00,$08,$05,$22,$00,$00,$01,$40,$00,$08,$05,$33,$00,$00
	dc.b	$06,$33,$00,$80,$05,$44,$00,$00,$06,$44,$00,$00,$06,$44,$00,$88
	dc.b	$06,$55,$00,$80,$07,$55,$00,$80,$02,$70,$00,$08,$07,$77,$08,$00
	dc.b	$00,$00,$00,$00,$0f,$0f,$00,$00,$0f,$0f,$00,$00,$0f,$0f,$00,$00
	dc.b	$0f,$d0,$00,$00,$0d,$a1,$00,$00,$0c,$80,$00,$00,$0a,$70,$00,$00
	dc.b	$07,$40,$00,$00,$04,$20,$00,$00,$05,$00,$00,$00,$00,$43,$00,$00
	dc.b	$04,$45,$00,$00,$07,$66,$00,$00,$08,$78,$00,$00,$07,$45,$00,$00
	dc.b	$07,$34,$00,$00,$05,$23,$00,$00,$07,$10,$00,$00,$08,$21,$00,$00
	dc.b	$0a,$41,$00,$00,$0a,$44,$00,$00,$02,$81,$00,$00,$0a,$66,$00,$00
	dc.b	$0c,$76,$00,$00,$0a,$88,$00,$00,$0c,$88,$00,$00,$0c,$99,$00,$00
	dc.b	$0c,$ba,$00,$00,$0e,$ba,$00,$00,$04,$e1,$00,$00,$0f,$ee,$00,$00
	dc.b	$00,$00,$00,$00,$07,$07,$08,$08,$07,$07,$08,$08,$07,$07,$08,$08
	dc.b	$07,$60,$08,$80,$06,$50,$08,$08,$06,$40,$00,$00,$05,$30,$00,$80
	dc.b	$03,$20,$08,$00,$02,$10,$00,$00,$02,$00,$08,$00,$00,$21,$00,$08
	dc.b	$02,$22,$00,$08,$03,$33,$08,$00,$04,$34,$00,$80,$03,$22,$08,$08
	dc.b	$03,$12,$08,$80,$02,$11,$08,$08,$03,$00,$08,$80,$04,$10,$00,$08
	dc.b	$05,$20,$00,$08,$05,$22,$00,$00,$01,$40,$00,$08,$05,$33,$00,$00
	dc.b	$06,$33,$00,$80,$05,$44,$00,$00,$06,$44,$00,$00,$06,$44,$00,$88
	dc.b	$06,$55,$00,$80,$07,$55,$00,$80,$02,$70,$00,$08,$07,$77,$08,$00
g2embed_title_pal_end

	even
g2embed_gloombrush
	dc.b	$43,$72,$4d,$32,$00,$00,$00,$00,$3e,$95,$00,$00,$30,$20,$0b,$88
	dc.b	$65,$c6,$cf,$fa,$21,$9f,$9e,$f7,$01,$1c,$35,$c3,$b6,$3b,$67,$08
	dc.b	$a5,$80,$cd,$63,$87,$8f,$69,$c2,$2f,$f6,$38,$5a,$7f,$7d,$33,$ac
	dc.b	$22,$a1,$23,$9f,$bc,$22,$ff,$9b,$1b,$49,$2c,$66,$fe,$d2,$d2,$34
	dc.b	$bd,$61,$74,$b4,$c3,$b1,$eb,$d3,$d0,$4a,$18,$ed,$82,$81,$62,$1b
	dc.b	$66,$f0,$2e,$6e,$1f,$ec,$7a,$c7,$af,$b1,$17,$f4,$33,$89,$01,$6e
	dc.b	$09,$39,$1a,$65,$09,$35,$8f,$8d,$2a,$ea,$f1,$a6,$bc,$76,$bd,$73
	dc.b	$57,$da,$2f,$f9,$83,$db,$a2,$11,$b4,$50,$88,$f6,$b4,$b1,$ae,$fb
	dc.b	$5e,$b1,$3b,$b5,$17,$dc,$2c,$9c,$33,$12,$43,$c2,$99,$75,$0e,$2a
	dc.b	$5b,$4f,$66,$92,$b1,$c3,$da,$f5,$a8,$60,$d7,$b7,$0b,$cf,$f8,$fe
	dc.b	$a9,$de,$34,$7d,$9e,$40,$d6,$2a,$91,$35,$34,$e3,$49,$ce,$19,$3d
	dc.b	$0b,$91,$c5,$85,$6c,$6a,$0a,$c4,$4d,$0e,$0a,$f8,$2f,$9a,$50,$99
	dc.b	$47,$85,$65,$bc,$b9,$83,$1e,$c6,$a5,$48,$44,$05,$2f,$1b,$84,$25
	dc.b	$63,$b3,$68,$0f,$f4,$5a,$ba,$8e,$20,$34,$50,$8f,$4a,$4f,$8a,$68
	dc.b	$7f,$cd,$3e,$eb,$c1,$69,$3c,$f4,$90,$f6,$6b,$17,$9b,$c0,$b7,$b7
	dc.b	$5a,$50,$57,$ef,$7b,$58,$3f,$6b,$66,$dd,$8b,$af,$35,$d7,$2d,$e5
	dc.b	$c1,$7b,$8c,$e2,$45,$6f,$06,$02,$96,$d2,$61,$26,$e4,$e1,$58,$4f
	dc.b	$d5,$e3,$5e,$b4,$7f,$06,$37,$a1,$79,$b5,$a1,$5f,$f8,$d8,$7c,$a7
	dc.b	$53,$16,$72,$aa,$18,$26,$c9,$07,$dd,$dd,$29,$0f,$a6,$98,$c9,$55
	dc.b	$a0,$33,$68,$9c,$20,$af,$e6,$cc,$a3,$b5,$1f,$94,$68,$b1,$59,$6f
	dc.b	$2f,$68,$a7,$5b,$50,$87,$d3,$79,$57,$c0,$ca,$83,$15,$7f,$d4,$2c
	dc.b	$d9,$5a,$ad,$50,$d2,$f5,$15,$d3,$e4,$84,$ae,$fe,$f5,$28,$a3,$2d
	dc.b	$da,$2a,$8e,$4b,$94,$f4,$5d,$1d,$bf,$66,$80,$9c,$ea,$78,$98,$47
	dc.b	$77,$d7,$ff,$a0,$b0,$4f,$eb,$db,$4b,$64,$a2,$e6,$e8,$f1,$4a,$33
	dc.b	$06,$30,$4d,$4a,$93,$0e,$20,$d7,$12,$ef,$a3,$3b,$c6,$b6,$68,$49
	dc.b	$63,$62,$88,$0c,$af,$b7,$0a,$a9,$af,$ae,$dd,$17,$c3,$ae,$23,$6a
	dc.b	$67,$38,$ba,$73,$ca,$df,$63,$58,$1c,$59,$ac,$c2,$14,$ad,$ec,$05
	dc.b	$43,$c5,$a7,$ff,$cf,$0e,$3b,$79,$50,$51,$3d,$81,$4f,$fd,$a6,$f3
	dc.b	$1e,$42,$3a,$fd,$92,$42,$24,$3c,$a5,$9d,$36,$55,$b1,$ce,$ab,$33
	dc.b	$6d,$27,$6e,$ff,$f6,$b6,$7e,$f5,$77,$0a,$a3,$2d,$8a,$4c,$c6,$cc
	dc.b	$6c,$26,$41,$89,$cf,$75,$6d,$88,$e2,$b4,$06,$82,$7f,$26,$f6,$75
	dc.b	$a0,$c0,$1a,$d9,$47,$56,$8e,$d7,$8d,$63,$8f,$a5,$b6,$4f,$d2,$40
	dc.b	$a4,$39,$7d,$62,$fa,$1a,$7d,$a0,$77,$ef,$6f,$27,$62,$34,$7c,$0b
	dc.b	$0a,$3a,$a3,$f8,$89,$27,$cf,$e7,$72,$16,$44,$27,$e4,$ad,$aa,$4c
	dc.b	$d4,$65,$4b,$c5,$a3,$bd,$5a,$43,$f3,$23,$ed,$b9,$e4,$aa,$03,$b5
	dc.b	$33,$51,$5a,$e8,$f1,$6a,$37,$04,$98,$a1,$a9,$52,$e6,$d0,$1c,$f5
	dc.b	$a2,$9f,$d4,$da,$a8,$b9,$08,$f9,$d5,$6e,$5d,$15,$91,$69,$e9,$dd
	dc.b	$a3,$fc,$f0,$f1,$9a,$b8,$79,$a6,$5e,$16,$e8,$dd,$74,$49,$78,$5d
	dc.b	$69,$0b,$cc,$8b,$d4,$1b,$18,$e6,$29,$3c,$6e,$e7,$e1,$62,$76,$d7
	dc.b	$41,$44,$f6,$04,$f3,$43,$8a,$a9,$21,$b6,$cf,$34,$c3,$07,$48,$a7
	dc.b	$97,$93,$14,$e5,$68,$0a,$0b,$3a,$7d,$47,$83,$74,$25,$91,$f9,$0f
	dc.b	$22,$13,$f2,$45,$d6,$8c,$0e,$06,$47,$ce,$3a,$a3,$aa,$a0,$0d,$40
	dc.b	$45,$9a,$55,$50,$ce,$0b,$0c,$7c,$fb,$20,$e2,$7a,$9e,$3a,$ff,$e7
	dc.b	$83,$e9,$92,$ba,$37,$19,$83,$af,$58,$b4,$d8,$23,$d7,$fa,$21,$56
	dc.b	$98,$01,$08,$0e,$1a,$d0,$eb,$28,$02,$4b,$75,$8a,$15,$c9,$87,$a2
	dc.b	$7b,$20,$dc,$d8,$ce,$7c,$63,$a6,$75,$62,$6b,$b9,$90,$41,$cd,$74
	dc.b	$74,$4a,$94,$7b,$b7,$95,$b7,$49,$d6,$ff,$4f,$2d,$ad,$a4,$c7,$0c
	dc.b	$31,$72,$5d,$db,$26,$63,$24,$3e,$00,$76,$ba,$3a,$47,$b1,$bf,$13
	dc.b	$b2,$7b,$48,$38,$eb,$f7,$83,$e1,$68,$55,$7f,$ba,$73,$df,$92,$1f
	dc.b	$dc,$c9,$87,$9c,$3a,$e5,$bb,$2b,$0f,$f7,$31,$1b,$47,$df,$fa,$ad
	dc.b	$f2,$2c,$89,$fb,$ad,$a4,$6b,$6f,$de,$e9,$73,$51,$b1,$8e,$8e,$64
	dc.b	$63,$24,$20,$38,$6a,$6c,$87,$2c,$2d,$38,$5a,$86,$29,$87,$90,$2b
	dc.b	$95,$3c,$36,$83,$30,$32,$b6,$68,$43,$09,$b4,$12,$75,$01,$33,$8d
	dc.b	$84,$bf,$e1,$b0,$80,$57,$5c,$51,$2d,$07,$b7,$95,$ba,$d6,$50,$91
	dc.b	$73,$ba,$a2,$17,$d0,$9b,$fd,$4c,$72,$fa,$2c,$62,$af,$21,$0b,$39
	dc.b	$d1,$7d,$62,$9e,$01,$8c,$d7,$03,$58,$83,$5a,$16,$f2,$4f,$65,$9b
	dc.b	$b7,$d8,$fe,$a7,$26,$da,$2a,$f3,$31,$4c,$bf,$87,$0e,$72,$74,$ca
	dc.b	$3d,$47,$36,$2c,$ad,$b6,$8f,$66,$45,$96,$83,$a6,$8d,$61,$e5,$d1
	dc.b	$11,$90,$e6,$55,$23,$93,$c9,$f4,$f5,$fe,$20,$63,$30,$5e,$af,$99
	dc.b	$b4,$f5,$ae,$ab,$ad,$34,$9b,$be,$a7,$30,$e4,$f8,$cf,$11,$6a,$2d
	dc.b	$e7,$17,$ba,$2d,$d7,$63,$d3,$d6,$d5,$d3,$40,$76,$e7,$a7,$05,$41
	dc.b	$dd,$97,$b5,$fe,$9d,$ad,$73,$48,$33,$1a,$9c,$ba,$52,$f7,$b3,$14
	dc.b	$78,$60,$c5,$17,$0f,$50,$79,$22,$e5,$0a,$d1,$51,$83,$59,$35,$f7
	dc.b	$20,$c6,$a3,$3b,$05,$7c,$5b,$89,$8e,$df,$e9,$03,$8e,$b0,$e6,$47
	dc.b	$c0,$12,$36,$ba,$06,$65,$a8,$e6,$b5,$e9,$13,$1d,$4e,$e0,$66,$ca
	dc.b	$9f,$46,$b7,$77,$55,$c2,$41,$f4,$87,$ae,$1e,$37,$81,$7d,$10,$a0
	dc.b	$6c,$37,$89,$ad,$62,$b6,$6b,$45,$a5,$ca,$72,$c6,$da,$d7,$2e,$38
	dc.b	$a6,$04,$19,$29,$3f,$71,$51,$e3,$c9,$74,$71,$74,$ca,$3d,$0d,$5e
	dc.b	$be,$e0,$18,$ca,$6d,$56,$d2,$1d,$dc,$1b,$4d,$1a,$fc,$b4,$89,$bb
	dc.b	$38,$4d,$95,$72,$7a,$87,$a7,$be,$3f,$3a,$3e,$30,$3a,$c8,$a9,$f9
	dc.b	$4f,$69,$31,$ee,$f3,$45,$6c,$82,$69,$b9,$2f,$9f,$67,$0b,$bb,$6e
	dc.b	$3f,$ff,$53,$7f,$c7,$c2,$22,$d4,$a2,$7f,$5f,$94,$3a,$83,$57,$2e
	dc.b	$51,$2d,$5b,$5a,$e1,$90,$6d,$81,$ba,$69,$e6,$9d,$e4,$b7,$f0,$b0
	dc.b	$c7,$77,$84,$56,$b7,$28,$ba,$3f,$15,$41,$47,$66,$b2,$cf,$33,$c8
	dc.b	$31,$0b,$b0,$39,$a1,$36,$cc,$0e,$80,$d8,$28,$1c,$7f,$ae,$91,$58
	dc.b	$6d,$75,$b4,$a3,$61,$ab,$d7,$b1,$87,$28,$7a,$cc,$0c,$e5,$06,$5b
	dc.b	$76,$37,$a5,$64,$1e,$5b,$3e,$ca,$12,$1a,$9e,$42,$75,$ac,$90,$13
	dc.b	$fa,$1f,$2b,$c7,$60,$f6,$62,$e9,$da,$d7,$5b,$df,$c4,$cf,$d6,$51
	dc.b	$f5,$69,$53,$bd,$44,$8e,$ff,$e1,$37,$8f,$cc,$2a,$b7,$47,$a4,$56
	dc.b	$e7,$70,$94,$32,$8b,$4a,$90,$a1,$f9,$51,$d3,$41,$7b,$28,$95,$e7
	dc.b	$6a,$13,$62,$9a,$dd,$cf,$5b,$cc,$4b,$6d,$37,$0b,$3e,$39,$5c,$f8
	dc.b	$ae,$27,$e4,$9f,$d7,$f8,$5d,$24,$5a,$dc,$31,$35,$82,$e2,$b7,$e3
	dc.b	$f0,$b9,$90,$be,$5b,$df,$ef,$60,$c9,$5b,$9e,$50,$96,$8f,$c7,$57
	dc.b	$29,$b0,$dd,$5a,$e1,$03,$81,$b3,$7e,$69,$a7,$fb,$b6,$4e,$3b,$18
	dc.b	$63,$c7,$fe,$15,$58,$9f,$df,$72,$10,$3c,$8d,$5d,$40,$95,$3a,$7c
	dc.b	$14,$cb,$46,$fa,$30,$7b,$31,$4c,$26,$83,$1a,$80,$95,$a1,$80,$38
	dc.b	$06,$ab,$5d,$27,$f7,$df,$cd,$32,$bb,$59,$f4,$be,$de,$dd,$46,$d2
	dc.b	$a9,$20,$35,$13,$1e,$32,$64,$1e,$e0,$d3,$24,$b5,$1a,$c8,$1d,$85
	dc.b	$c0,$12,$df,$d1,$50,$32,$8d,$5c,$93,$9f,$29,$cb,$fb,$ab,$5d,$50
	dc.b	$5a,$99,$a4,$e5,$d4,$13,$22,$7f,$9a,$8f,$de,$fd,$74,$1c,$fe,$ab
	dc.b	$e6,$a3,$74,$13,$15,$ae,$0f,$ab,$1a,$e9,$9f,$09,$6a,$8e,$35,$28
	dc.b	$51,$ca,$25,$19,$ab,$50,$34,$f4,$ed,$69,$63,$f1,$43,$63,$8a,$f0
	dc.b	$4f,$65,$89,$36,$9a,$87,$26,$7c,$ba,$82,$1c,$8f,$3e,$38,$62,$cb
	dc.b	$5d,$d2,$eb,$7b,$5f,$65,$bd,$37,$f1,$f6,$78,$a8,$4c,$59,$7b,$d8
	dc.b	$4a,$26,$a7,$3e,$10,$08,$dd,$5a,$fe,$14,$e2,$fb,$2e,$a5,$34,$e4
	dc.b	$6e,$64,$18,$a8,$cc,$73,$f8,$c2,$b9,$ce,$5f,$80,$c8,$6c,$fc,$8d
	dc.b	$5b,$4d,$30,$ac,$64,$25,$7a,$0c,$73,$44,$1b,$a9,$9e,$85,$40,$16
	dc.b	$81,$68,$ae,$7f,$91,$86,$88,$39,$b4,$50,$05,$8a,$d3,$d1,$f4,$bd
	dc.b	$24,$0e,$cf,$a4,$21,$69,$45,$cf,$55,$9c,$a0,$b0,$0c,$7b,$e4,$3d
	dc.b	$52,$f2,$d7,$46,$04,$7b,$5e,$4b,$0c,$a4,$da,$1c,$59,$35,$89,$5c
	dc.b	$13,$f6,$d5,$93,$ed,$ad,$7f,$72,$e1,$b2,$b7,$3b,$ae,$92,$e6,$3e
	dc.b	$0a,$30,$8e,$a2,$af,$33,$b5,$55,$cd,$5d,$6d,$3f,$03,$be,$ea,$7c
	dc.b	$23,$75,$31,$84,$52,$8d,$68,$f0,$d5,$12,$ab,$b2,$26,$cd,$35,$34
	dc.b	$ae,$fc,$48,$ed,$fe,$7b,$8b,$5f,$77,$28,$6d,$57,$cb,$ac,$07,$bd
	dc.b	$cc,$f0,$9a,$b4,$94,$fc,$d1,$b4,$ed,$0f,$19,$e3,$55,$70,$bd,$36
	dc.b	$e5,$fd,$de,$2a,$ea,$8d,$2f,$de,$c3,$a8,$96,$bb,$70,$e7,$ef,$dd
	dc.b	$5a,$fe,$02,$78,$a4,$eb,$6e,$94,$d3,$d1,$89,$a9,$6f,$90,$f0,$ac
	dc.b	$55,$76,$85,$57,$3d,$7c,$06,$64,$32,$df,$c8,$95,$b4,$27,$ab,$0f
	dc.b	$93,$15,$da,$ac,$d3,$be,$03,$4a,$a4,$ee,$68,$28,$c3,$15,$05,$75
	dc.b	$a3,$ae,$e5,$43,$9e,$bb,$6b,$a5,$d8,$54,$1d,$c4,$65,$40,$93,$92
	dc.b	$01,$96,$b9,$a9,$72,$87,$50,$73,$5c,$67,$72,$86,$33,$67,$15,$31
	dc.b	$96,$56,$30,$c0,$e6,$7f,$21,$94,$41,$56,$97,$88,$ec,$61,$f1,$96
	dc.b	$e4,$96,$74,$84,$76,$d6,$2b,$9d,$b8,$ef,$95,$c9,$47,$23,$76,$c8
	dc.b	$49,$99,$a7,$7d,$45,$22,$68,$f5,$b2,$e0,$fb,$32,$7f,$6d,$b5,$1f
	dc.b	$4b,$eb,$40,$fc,$25,$27,$7a,$80,$18,$50,$f5,$dd,$7b,$2b,$63,$4e
	dc.b	$9f,$e2,$cb,$ef,$f6,$ba,$e3,$d2,$a5,$a3,$cc,$e7,$60,$f6,$7f,$4f
	dc.b	$aa,$c3,$63,$62,$66,$ab,$f0,$7d,$ac,$d9,$af,$5a,$73,$c2,$c9,$7c
	dc.b	$41,$c5,$b5,$bb,$44,$7f,$a1,$bb,$bd,$89,$22,$43,$95,$33,$79,$fb
	dc.b	$6b,$58,$c0,$ea,$b5,$6a,$46,$f9,$4d,$39,$cc,$48,$22,$61,$2b,$e3
	dc.b	$31,$52,$d0,$93,$17,$5a,$d7,$9a,$49,$fe,$46,$1e,$ba,$cb,$6b,$97
	dc.b	$99,$a6,$ea,$75,$5b,$39,$d1,$8b,$61,$41,$33,$55,$91,$22,$fd,$09
	dc.b	$03,$b5,$79,$c4,$dd,$40,$c2,$5a,$e9,$a5,$87,$ce,$14,$ca,$13,$95
	dc.b	$d2,$50,$08,$f2,$47,$c6,$53,$18,$32,$02,$9c,$35,$eb,$5b,$a5,$15
	dc.b	$96,$82,$5e,$f7,$11,$d3,$40,$3d,$67,$29,$51,$8a,$d9,$10,$c5,$d1
	dc.b	$32,$76,$c2,$75,$ac,$4e,$8e,$ef,$96,$6a,$64,$18,$ef,$d5,$a3,$99
	dc.b	$88,$da,$15,$d1,$6a,$ab,$1a,$72,$9b,$62,$9b,$a6,$25,$44,$6b,$ca
	dc.b	$58,$60,$b4,$15,$ed,$20,$c6,$6e,$3e,$a2,$c1,$32,$9a,$c5,$55,$ba
	dc.b	$d6,$ee,$b7,$83,$38,$6d,$f6,$a8,$bf,$46,$37,$d8,$bb,$dc,$dd,$ba
	dc.b	$6c,$34,$7f,$6f,$f5,$9d,$84,$4f,$b4,$3b,$bb,$88,$6d,$c1,$e0,$c6
	dc.b	$4c,$31,$17,$91,$9a,$06,$21,$28,$71,$b4,$3d,$5a,$cb,$61,$88,$59
	dc.b	$a2,$fd,$2d,$26,$cd,$3c,$9b,$99,$8a,$fe,$b6,$9a,$b0,$e7,$3d,$60
	dc.b	$d2,$f2,$21,$a3,$5d,$15,$58,$8b,$ba,$9c,$d0,$34,$73,$e0,$ae,$bc
	dc.b	$ee,$34,$9e,$93,$7d,$86,$13,$b5,$13,$39,$ba,$8a,$a5,$aa,$e8,$e7
	dc.b	$32,$82,$34,$a5,$c9,$83,$af,$74,$11,$e3,$2a,$3c,$32,$83,$52,$45
	dc.b	$c4,$e2,$58,$79,$a9,$2f,$6c,$e2,$92,$14,$e3,$01,$71,$03,$ea,$81
	dc.b	$ac,$42,$b4,$3f,$13,$e7,$ef,$71,$70,$9d,$6b,$18,$a8,$99,$94,$ca
	dc.b	$9c,$b5,$f1,$8d,$f2,$85,$69,$19,$8d,$91,$67,$1a,$57,$2d,$b3,$ca
	dc.b	$4b,$d4,$92,$3a,$87,$a8,$33,$90,$d3,$ac,$30,$05,$48,$ac,$e9,$b6
	dc.b	$a9,$cc,$36,$90,$4e,$e1,$e8,$dd,$bb,$f7,$60,$f8,$df,$7b,$6b,$c9
	dc.b	$7d,$7b,$e2,$72,$a8,$79,$b3,$7c,$ff,$27,$e5,$e6,$79,$dc,$38,$cf
	dc.b	$9a,$a7,$25,$bc,$05,$6f,$11,$2d,$ff,$b8,$95,$d6,$98,$1d,$9c,$fc
	dc.b	$82,$3a,$4f,$a1,$25,$7e,$7c,$70,$f5,$6b,$ed,$ab,$60,$b3,$2d,$f4
	dc.b	$0d,$59,$7a,$cc,$53,$8b,$36,$ce,$0e,$8d,$09,$5c,$b8,$b4,$d7,$63
	dc.b	$ef,$07,$e4,$43,$47,$83,$fa,$cd,$e3,$1f,$75,$3a,$a5,$be,$13,$35
	dc.b	$48,$7a,$3f,$f9,$d4,$e9,$39,$94,$5c,$cc,$ce,$1c,$cb,$ae,$e6,$9e
	dc.b	$2d,$36,$a5,$4b,$52,$e4,$84,$ee,$51,$15,$17,$7e,$5c,$a1,$d4,$35
	dc.b	$95,$18,$5c,$05,$da,$4f,$25,$ee,$7f,$0b,$96,$c6,$ff,$4e,$3f,$1a
	dc.b	$43,$2e,$d6,$9b,$d8,$ae,$5b,$65,$a5,$bb,$9b,$98,$e5,$23,$3f,$53
	dc.b	$83,$71,$5f,$6c,$65,$07,$5b,$64,$1f,$5a,$5b,$47,$b4,$f9,$ca,$ba
	dc.b	$41,$b7,$aa,$ba,$65,$43,$b4,$5f,$e7,$4c,$f7,$ed,$b5,$eb,$58,$a1
	dc.b	$39,$42,$cb,$db,$7d,$b6,$ff,$5d,$dd,$39,$9e,$fa,$bf,$ee,$46,$f3
	dc.b	$83,$65,$bf,$7f,$62,$bb,$fc,$e7,$e9,$c8,$f8,$ad,$fc,$20,$4e,$da
	dc.b	$c0,$93,$45,$7b,$5a,$4a,$fd,$a2,$ba,$69,$fc,$06,$47,$0f,$4a,$76
	dc.b	$8a,$8b,$3b,$09,$b2,$4f,$eb,$74,$ed,$da,$f5,$ad,$36,$96,$f9,$9d
	dc.b	$a5,$22,$fe,$9e,$73,$4b,$48,$e0,$dd,$4f,$bb,$1f,$cc,$6a,$6e,$a7
	dc.b	$4e,$ef,$37,$83,$56,$a2,$a9,$b6,$ad,$b6,$b4,$dc,$f6,$8a,$ad,$b1
	dc.b	$f4,$6e,$f1,$94,$25,$0d,$02,$0e,$b1,$bb,$b7,$c2,$35,$97,$3b,$c4
	dc.b	$3a,$dd,$18,$fc,$60,$f0,$53,$95,$d5,$c0,$b2,$2b,$96,$33,$3b,$fe
	dc.b	$eb,$6e,$63,$a0,$cf,$d4,$e2,$fe,$e6,$4c,$64,$99,$27,$72,$ee,$0c
	dc.b	$10,$bd,$de,$72,$e3,$29,$ab,$05,$59,$06,$dd,$a6,$e2,$04,$6a,$8f
	dc.b	$6b,$54,$49,$ca,$1f,$a2,$18,$c2,$73,$f1,$c8,$1c,$a6,$49,$4d,$6d
	dc.b	$39,$7b,$6e,$04,$cc,$ee,$c2,$e1,$f5,$9d,$8d,$8d,$e7,$17,$f6,$bf
	dc.b	$cf,$b1,$f7,$e6,$bb,$57,$d8,$dc,$d7,$27,$58,$04,$a5,$a0,$5d,$3e
	dc.b	$d2,$d1,$b0,$b3,$c7,$e4,$15,$1f,$f3,$33,$42,$07,$93,$9b,$a8,$30
	dc.b	$68,$0e,$6f,$42,$6d,$5f,$92,$75,$b3,$0e,$40,$6d,$1a,$0a,$66,$45
	dc.b	$d1,$8e,$73,$7c,$8a,$ea,$5f,$2e,$d2,$81,$7e,$67,$f5,$6a,$e7,$91
	dc.b	$c5,$fd,$a2,$5b,$1c,$27,$4c,$ea,$93,$19,$a7,$d0,$6a,$d4,$54,$db
	dc.b	$51,$98,$d9,$0c,$51,$ab,$a5,$cb,$87,$4f,$71,$01,$b7,$00,$87,$21
	dc.b	$d3,$78,$49,$17,$1b,$39,$78,$8a,$c0,$e9,$c2,$0a,$e2,$e0,$59,$0f
	dc.b	$49,$da,$c9,$35,$89,$69,$7f,$f9,$2b,$e3,$b5,$a4,$51,$a2,$7d,$cd
	dc.b	$7f,$b1,$73,$21,$d5,$c7,$9c,$18,$ea,$a7,$39,$6f,$d8,$54,$dd,$e7
	dc.b	$d1,$ba,$41,$d7,$69,$9a,$02,$9b,$69,$16,$a0,$28,$d6,$b1,$4c,$61
	dc.b	$a3,$9c,$e8,$c9,$95,$ad,$eb,$5b,$8e,$eb,$23,$fa,$be,$29,$41,$69
	dc.b	$7a,$fd,$a3,$8d,$dd,$03,$6d,$de,$d2,$fb,$ee,$87,$63,$dd,$f9,$97
	dc.b	$ec,$e4,$51,$5d,$d4,$37,$72,$59,$ce,$d7,$8b,$8d,$43,$7e,$0b,$dc
	dc.b	$d6,$66,$ef,$d8,$9c,$9c,$db,$29,$19,$0c,$09,$ce,$ef,$ac,$6e,$ee
	dc.b	$2d,$b2,$d0,$58,$f0,$6b,$69,$53,$72,$ee,$97,$90,$90,$50,$fe,$44
	dc.b	$b1,$19,$a5,$32,$b5,$8f,$63,$44,$f8,$b8,$fb,$69,$1c,$e8,$4a,$b6
	dc.b	$c0,$44,$ea,$ea,$d4,$55,$b5,$46,$6c,$8a,$43,$78,$b9,$eb,$15,$1a
	dc.b	$ea,$99,$0c,$a9,$de,$41,$29,$ce,$43,$c2,$b7,$b3,$c9,$7a,$e0,$73
	dc.b	$c1,$97,$ea,$47,$1b,$35,$3e,$04,$4f,$c2,$ec,$f0,$7e,$b2,$4d,$62
	dc.b	$e3,$95,$fe,$ee,$da,$bf,$97,$31,$ca,$7f,$ec,$a7,$35,$ac,$65,$df
	dc.b	$6a,$d4,$dc,$f5,$73,$7f,$e9,$76,$5b,$8e,$e9,$75,$5d,$60,$de,$6d
	dc.b	$a0,$d6,$4d,$f4,$57,$75,$83,$77,$56,$33,$41,$35,$50,$8a,$8c,$9f
	dc.b	$47,$fd,$d6,$f5,$7c,$e9,$ee,$95,$97,$e3,$64,$75,$87,$a7,$f9,$22
	dc.b	$ba,$bf,$0e,$89,$dc,$f9,$fd,$ce,$66,$36,$69,$80,$0c,$81,$c0,$59
	dc.b	$cf,$f8,$2f,$7d,$db,$ed,$6e,$2f,$4f,$fe,$9b,$65,$31,$5c,$81,$39
	dc.b	$83,$ea,$60,$60,$ca,$15,$89,$d8,$94,$6c,$b5,$42,$5d,$3e,$91,$cd
	dc.b	$bf,$f2,$2e,$3a,$d3,$dd,$f6,$40,$ff,$4d,$da,$ed,$1e,$aa,$e9,$bb
	dc.b	$33,$be,$b3,$6b,$dc,$e8,$f1,$4c,$e4,$b5,$01,$7a,$68,$c8,$12,$0f
	dc.b	$68,$f6,$16,$eb,$26,$7e,$8c,$ef,$95,$77,$46,$2c,$87,$4d,$77,$f4
	dc.b	$7f,$a3,$c7,$28,$78,$02,$e7,$77,$46,$af,$d7,$02,$83,$db,$61,$6c
	dc.b	$bd,$a4,$d9,$0c,$bc,$b9,$c1,$d4,$66,$9d,$52,$5b,$18,$28,$ed,$14
	dc.b	$25,$70,$31,$90,$e0,$a3,$fb,$91,$4b,$77,$8a,$3b,$78,$a8,$7a,$83
	dc.b	$49,$de,$28,$a5,$39,$40,$fc,$6a,$8a,$1d,$8c,$d1,$e9,$46,$d5,$70
	dc.b	$45,$47,$f7,$73,$77,$fc,$72,$bc,$ed,$5f,$6a,$87,$d3,$79,$20,$4a
	dc.b	$fc,$0f,$25,$e7,$83,$e3,$1f,$e3,$f0,$da,$9a,$47,$09,$67,$11,$45
	dc.b	$d3,$e8,$b5,$0b,$8a,$dc,$17,$be,$ad,$f4,$b7,$67,$c7,$fe,$84,$4a
	dc.b	$44,$e2,$8e,$80,$fd,$1f,$f7,$e7,$33,$1a,$b1,$58,$14,$65,$8f,$59
	dc.b	$50,$a2,$c2,$d4,$35,$b9,$79,$33,$f9,$0c,$bd,$5c,$d6,$d9,$11,$fc
	dc.b	$de,$ad,$5c,$f0,$74,$27,$be,$e6,$6f,$99,$01,$6e,$63,$a6,$bb,$f4
	dc.b	$94,$a0,$28,$9a,$33,$1b,$c7,$69,$b2,$f7,$2f,$3d,$33,$24,$3c,$06
	dc.b	$ed,$ac,$81,$93,$83,$50,$d1,$2e,$4b,$c8,$31,$47,$29,$f6,$17,$bb
	dc.b	$e4,$8e,$9f,$9f,$00,$28,$cf,$f3,$f5,$fe,$af,$5d,$6f,$76,$c8,$ff
	dc.b	$57,$0e,$5a,$fb,$34,$ea,$91,$a4,$8d,$84,$fc,$c6,$2b,$cc,$4b,$37
	dc.b	$98,$49,$a9,$bd,$0d,$c1,$45,$6c,$14,$76,$8f,$61,$90,$cd,$fd,$b5
	dc.b	$a7,$a8,$38,$ed,$1e,$89,$a9,$57,$e7,$b2,$aa,$3c,$bc,$6b,$a5,$7b
	dc.b	$c4,$fe,$1c,$b6,$35,$ab,$56,$5f,$8c,$91,$94,$0f,$81,$fe,$74,$ff
	dc.b	$75,$c5,$8b,$33,$e1,$d5,$b7,$cd,$10,$b8,$a3,$09,$0e,$b5,$88,$9a
	dc.b	$93,$0b,$9a,$d3,$51,$53,$db,$2d,$05,$c6,$c3,$f0,$94,$8c,$70,$1d
	dc.b	$13,$c7,$17,$dc,$29,$56,$23,$54,$d5,$b9,$a6,$48,$69,$2d,$17,$97
	dc.b	$e3,$f9,$7b,$b5,$48,$6c,$17,$94,$cb,$e6,$f5,$68,$2b,$11,$eb,$1b
	dc.b	$7a,$27,$f3,$e6,$44,$14,$17,$03,$ba,$aa,$0a,$eb,$51,$1c,$ae,$83
	dc.b	$cb,$75,$f0,$d6,$8f,$4f,$41,$bb,$33,$a0,$5c,$f3,$6e,$b1,$ff,$4c
	dc.b	$90,$d1,$6e,$4b,$80,$d6,$d1,$4e,$a1,$64,$86,$2d,$b8,$02,$e2,$2c
	dc.b	$5c,$32,$dd,$71,$b1,$60,$2f,$55,$8e,$a7,$1b,$f0,$ec,$18,$c8,$d8
	dc.b	$48,$c8,$fe,$3c,$c4,$a6,$41,$f5,$48,$cf,$68,$a1,$2e,$67,$5b,$5a
	dc.b	$58,$ed,$69,$20,$c7,$fd,$27,$40,$87,$f6,$90,$4a,$87,$a4,$66,$b5
	dc.b	$58,$27,$9a,$b8,$79,$8d,$3d,$ce,$70,$5f,$ef,$63,$a9,$8b,$35,$f5
	dc.b	$ef,$e2,$64,$42,$f5,$fe,$ea,$ed,$9f,$9a,$21,$5f,$5f,$87,$d4,$3e
	dc.b	$87,$06,$4a,$76,$44,$47,$69,$cc,$2a,$75,$c6,$eb,$bf,$91,$db,$ae
	dc.b	$fb,$79,$31,$84,$d5,$74,$47,$d1,$1d,$31,$3c,$4b,$74,$5b,$cc,$2c
	dc.b	$f6,$0f,$7d,$76,$34,$89,$60,$70,$fd,$1f,$a7,$f9,$8d,$8a,$bb,$2b
	dc.b	$bb,$9a,$a6,$57,$c2,$73,$41,$76,$0d,$bb,$0c,$fb,$6b,$de,$15,$4d
	dc.b	$fc,$3e,$d4,$36,$c6,$91,$d3,$cd,$03,$8b,$84,$da,$5c,$9d,$19,$4a
	dc.b	$f4,$67,$29,$a9,$5e,$ae,$1c,$bc,$d1,$0f,$5c,$a6,$39,$e8,$80,$0b
	dc.b	$64,$75,$57,$81,$d4,$1e,$2a,$be,$24,$ba,$de,$90,$17,$aa,$3a,$88
	dc.b	$c3,$be,$67,$e9,$12,$35,$7f,$53,$26,$2a,$66,$07,$29,$a8,$37,$05
	dc.b	$10,$37,$33,$6d,$db,$0d,$f3,$65,$a7,$b3,$f4,$5d,$7b,$48,$07,$4c
	dc.b	$19,$6a,$b0,$11,$f3,$0f,$2f,$45,$f3,$de,$17,$47,$ee,$cb,$f9,$ce
	dc.b	$1a,$3a,$c7,$88,$1d,$b3,$7e,$37,$bf,$19,$c1,$6c,$6d,$bc,$6e,$0e
	dc.b	$f9,$ca,$88,$59,$cf,$74,$44,$70,$5d,$0e,$20,$de,$5c,$2e,$47,$e4
	dc.b	$1d,$ec,$7c,$17,$fa,$a1,$07,$52,$11,$eb,$cc,$7a,$fd,$39,$74,$a4
	dc.b	$66,$02,$9b,$dd,$d2,$84,$e6,$32,$f2,$a9,$a2,$fc,$bb,$6f,$97,$a6
	dc.b	$4d,$d9,$cd,$ad,$2f,$f0,$7f,$87,$5a,$0a,$02,$1e,$c3,$34,$fd,$77
	dc.b	$b7,$8a,$3a,$a0,$d0,$b9,$a0,$a8,$85,$d6,$57,$8e,$35,$f7,$8a,$e8
	dc.b	$0e,$d9,$e3,$20,$f7,$43,$6b,$87,$2c,$8e,$f0,$b5,$c6,$10,$85,$90
	dc.b	$94,$59,$0b,$66,$48,$79,$c0,$d9,$da,$93,$e9,$44,$9a,$dc,$6c,$8b
	dc.b	$35,$2d,$fe,$eb,$30,$ce,$76,$3e,$e7,$7c,$31,$13,$54,$95,$9c,$6d
	dc.b	$53,$36,$5e,$32,$83,$52,$73,$eb,$9c,$8a,$8b,$f3,$e8,$ef,$7a,$c7
	dc.b	$7b,$c7,$be,$66,$03,$bf,$9e,$53,$f4,$40,$95,$2d,$22,$dd,$01,$ce
	dc.b	$61,$e6,$34,$f6,$a7,$dd,$eb,$6d,$fe,$eb,$72,$59,$df,$58,$59,$df
	dc.b	$00,$ba,$9f,$56,$9e,$f6,$87,$b1,$95,$e6,$61,$4f,$1b,$b2,$23,$79
	dc.b	$77,$a2,$0d,$7d,$05,$c9,$e3,$d5,$df,$13,$f2,$36,$fa,$af,$8b,$15
	dc.b	$ae,$8c,$f0,$c6,$50,$8a,$f9,$e6,$63,$cf,$6c,$82,$9a,$84,$2f,$88
	dc.b	$a8,$bf,$0a,$45,$cb,$14,$4c,$df,$7b,$1f,$98,$da,$a6,$b0,$ae,$bf
	dc.b	$6c,$31,$56,$73,$5f,$79,$df,$0d,$3d,$aa,$c5,$ac,$fa,$63,$54,$c1
	dc.b	$b6,$a0,$a1,$4a,$e6,$c9,$eb,$a5,$d3,$98,$06,$60,$c7,$8a,$ca,$15
	dc.b	$5f,$c6,$42,$c8,$87,$4d,$a0,$ca,$0d,$78,$36,$e5,$6d,$e6,$50,$0b
	dc.b	$c5,$91,$66,$cf,$43,$b8,$9a,$68,$74,$6f,$81,$8c,$de,$2b,$29,$4a
	dc.b	$92,$d4,$46,$e0,$29,$a0,$44,$d5,$bb,$e9,$c1,$29,$92,$1d,$50,$60
	dc.b	$d4,$9c,$5f,$87,$44,$c3,$9f,$06,$90,$78,$0a,$2d,$ce,$57,$06,$97
	dc.b	$5e,$1b,$ca,$68,$35,$95,$31,$9f,$b2,$49,$63,$98,$d7,$0f,$2d,$61
	dc.b	$71,$2c,$eb,$73,$7e,$1b,$33,$fc,$63,$58,$f6,$c4,$b4,$9b,$87,$f5
	dc.b	$66,$e7,$fd,$9e,$26,$dd,$a6,$86,$d7,$ce,$c8,$51,$d8,$9f,$cf,$7d
	dc.b	$f9,$06,$33,$46,$ac,$a7,$e7,$a1,$5e,$4c,$7f,$ee,$da,$ac,$43,$3d
	dc.b	$3f,$7e,$22,$37,$33,$1b,$17,$07,$29,$a0,$d3,$95,$04,$9f,$ef,$dd
	dc.b	$3c,$d6,$0c,$4a,$73,$f7,$9b,$e4,$e0,$3a,$ac,$6d,$bc,$4c,$38,$b1
	dc.b	$b8,$0a,$68,$ef,$db,$8d,$95,$9f,$42,$a8,$96,$87,$27,$8c,$14,$29
	dc.b	$50,$fe,$ea,$f7,$54,$67,$31,$b6,$95,$03,$4b,$9d,$0e,$ad,$76,$ae
	dc.b	$0c,$5a,$e8,$74,$ea,$01,$af,$04,$3e,$22,$9e,$ff,$9d,$6e,$d0,$93
	dc.b	$66,$c8,$07,$ef,$34,$d0,$ec,$15,$9d,$89,$dd,$84,$c5,$99,$2c,$b5
	dc.b	$12,$3c,$6c,$a0,$ec,$60,$44,$d5,$ab,$f1,$59,$59,$30,$31,$de,$0d
	dc.b	$25,$27,$db,$f6,$6c,$4a,$96,$a6,$e3,$bd,$3f,$48,$36,$f8,$8e,$1b
	dc.b	$f5,$cd,$fe,$42,$a4,$f8,$3f,$ff,$20,$6e,$d7,$1b,$87,$9d,$95,$7c
	dc.b	$7a,$6d,$ff,$87,$c2,$3b,$8b,$c6,$85,$f2,$47,$61,$6d,$75,$3e,$af
	dc.b	$b3,$fc,$17,$13,$af,$b7,$86,$c0,$fa,$cf,$c4,$0e,$cd,$77,$bd,$29
	dc.b	$f7,$7d,$61,$b5,$51,$bc,$7e,$47,$4c,$4a,$9f,$8f,$60,$71,$7a,$45
	dc.b	$7d,$da,$8d,$cc,$c3,$18,$be,$24,$29,$1b,$fe,$72,$58,$60,$93,$29
	dc.b	$fd,$d4,$cd,$66,$04,$c2,$09,$6e,$cf,$ce,$ca,$7b,$af,$54,$7f,$ad
	dc.b	$08,$e8,$9f,$6a,$81,$83,$1d,$fb,$71,$c3,$f4,$fa,$13,$51,$6e,$73
	dc.b	$98,$c1,$41,$5a,$be,$eb,$c0,$57,$10,$56,$10,$78,$0a,$78,$0e,$c7
	dc.b	$ca,$cd,$b5,$d0,$ed,$89,$68,$2b,$c2,$2d,$e0,$2a,$9f,$fd,$87,$c4
	dc.b	$9f,$4a,$51,$dd,$e6,$84,$df,$5d,$92,$57,$d5,$3a,$70,$98,$d3,$25
	dc.b	$96,$a3,$26,$37,$80,$f4,$e7,$4f,$f1,$5c,$48,$94,$8a,$c1,$fb,$ca
	dc.b	$46,$93,$9a,$88,$ef,$01,$52,$82,$ed,$c2,$ff,$63,$30,$a4,$f8,$98
	dc.b	$98,$32,$99,$7e,$bb,$85,$14,$f7,$0a,$43,$cc,$3c,$9c,$0f,$f8,$bc
	dc.b	$d0,$74,$c6,$81,$b2,$c1,$53,$dc,$1e,$73,$88,$dc,$d1,$19,$f0,$ff
	dc.b	$d7,$ee,$ed,$f8,$8f,$bc,$0c,$de,$5d,$c5,$7f,$9e,$a1,$c5,$e1,$65
	dc.b	$19,$b1,$2d,$31,$ae,$0d,$af,$48,$b2,$a0,$36,$b3,$ca,$12,$14,$a6
	dc.b	$b9,$fb,$5a,$4a,$70,$f5,$06,$b3,$43,$83,$04,$dd,$37,$93,$80,$fb
	dc.b	$a3,$36,$f3,$e1,$32,$f6,$a8,$17,$13,$f4,$19,$93,$98,$cf,$b4,$55
	dc.b	$6f,$dd,$0c,$14,$59,$23,$d2,$99,$da,$8d,$a0,$22,$b7,$5d,$4b,$90
	dc.b	$72,$c3,$62,$4f,$46,$19,$f4,$c9,$1c,$4a,$bd,$d5,$cd,$67,$95,$bb
	dc.b	$a9,$f3,$7b,$41,$d6,$41,$2b,$ab,$cd,$06,$27,$bc,$df,$e3,$aa,$77
	dc.b	$a7,$24,$7f,$92,$c9,$74,$ca,$7a,$ff,$02,$f3,$38,$4f,$59,$89,$12
	dc.b	$9a,$9a,$0a,$46,$4b,$82,$52,$ca,$5a,$06,$e9,$20,$25,$8c,$51,$75
	dc.b	$50,$86,$51,$d3,$0d,$5a,$ef,$04,$0f,$f8,$3c,$1f,$01,$5c,$72,$4c
	dc.b	$b4,$ce,$61,$e7,$d7,$4a,$d6,$6e,$7a,$7a,$17,$c9,$02,$d7,$83,$ed
	dc.b	$4e,$cb,$f9,$a2,$53,$c6,$f2,$f9,$db,$81,$47,$e6,$c6,$71,$b8,$fc
	dc.b	$cf,$65,$ea,$1c,$46,$6f,$28,$94,$ad,$1f,$e3,$4c,$12,$7c,$87,$bd
	dc.b	$0a,$f0,$c4,$85,$2d,$78,$32,$e4,$28,$4f,$87,$68,$35,$9c,$cc,$18
	dc.b	$26,$16,$fc,$f4,$fe,$0d,$d4,$db,$b1,$84,$6e,$f2,$14,$1b,$b3,$32
	dc.b	$77,$dd,$31,$09,$ab,$dd,$9f,$43,$59,$92,$16,$3f,$b5,$cb,$c9,$a5
	dc.b	$0e,$45,$e4,$df,$f0,$bc,$85,$59,$e4,$28,$cf,$e4,$0d,$f8,$b5,$09
	dc.b	$72,$b5,$c7,$93,$49,$ec,$e9,$1a,$7c,$85,$05,$ea,$45,$ab,$93,$62
	dc.b	$f3,$1b,$f1,$b5,$bc,$5e,$4d,$2a,$46,$53,$ea,$e2,$cd,$b4,$52,$d4
	dc.b	$af,$f6,$52,$43,$ae,$62,$a4,$3b,$70,$6c,$bc,$da,$7a,$e6,$5b,$e9
	dc.b	$7f,$34,$ff,$bc,$f9,$8a,$0b,$d0,$1c,$90,$27,$5e,$0f,$83,$85,$da
	dc.b	$e1,$71,$19,$f8,$da,$5f,$2e,$dc,$0f,$bc,$c9,$6f,$6e,$dc,$dc,$a7
	dc.b	$cc,$57,$5c,$c5,$34,$c6,$98,$0a,$63,$2b,$ee,$a2,$84,$e2,$f5,$69
	dc.b	$59,$8c,$35,$6a,$bc,$db,$42,$b3,$43,$f5,$06,$e3,$36,$e9,$a8,$85
	dc.b	$ea,$29,$37,$b3,$32,$bb,$c5,$f6,$ec,$b2,$83,$7a,$1a,$cb,$a8,$52
	dc.b	$dd,$ab,$5e,$af,$5b,$83,$3d,$29,$77,$44,$96,$d8,$9c,$49,$10,$cd
	dc.b	$ca,$4c,$97,$b7,$6a,$74,$f0,$20,$9f,$cb,$7b,$9a,$0a,$71,$94,$08
	dc.b	$d6,$84,$af,$f5,$df,$94,$d9,$66,$71,$f4,$92,$c1,$99,$c7,$dd,$48
	dc.b	$b4,$fe,$b5,$8b,$cc,$af,$8d,$59,$c1,$29,$bd,$3b,$fc,$fb,$86,$53
	dc.b	$ca,$e2,$cd,$d4,$54,$af,$f6,$56,$f3,$28,$d6,$b0,$c2,$c8,$41,$44
	dc.b	$6a,$bc,$7c,$e6,$0e,$ff,$37,$04,$6b,$f2,$f9,$96,$19,$8f,$51,$50
	dc.b	$ad,$0e,$52,$b2,$15,$b6,$bb,$03,$3d,$b7,$06,$61,$27,$a0,$be,$48
	dc.b	$15,$af,$07,$e6,$85,$b1,$ed,$fc,$4a,$78,$da,$5f,$23,$7e,$04,$af
	dc.b	$28,$ee,$97,$f6,$17,$d1,$6d,$57,$03,$2b,$2f,$50,$c5,$98,$d2,$0d
	dc.b	$b1,$bb,$34,$9d,$33,$14,$ec,$29,$34,$18,$bb,$18,$4a,$c4,$e6,$f5
	dc.b	$ab,$2b,$85,$69,$41,$37,$93,$a1,$dd,$a8,$ef,$83,$33,$80,$3f,$55
	dc.b	$15,$1c,$bd,$99,$9b,$b1,$76,$27,$31,$35,$7a,$1b,$d7,$d6,$5d,$46
	dc.b	$2d,$cc,$a5,$3a,$aa,$a2,$91,$95,$73,$8d,$e5,$76,$1e,$84,$bd,$81
	dc.b	$b8,$af,$b3,$4d,$dd,$85,$42,$e2,$2f,$99,$5d,$8b,$7c,$56,$0e,$ce
	dc.b	$0c,$22,$8f,$b6,$bb,$1f,$ff,$e5,$46,$55,$ab,$b3,$d7,$d9,$65,$06
	dc.b	$a2,$94,$46,$b7,$66,$ff,$cc,$b0,$c7,$4d,$bf,$27,$cb,$55,$d4,$b7
	dc.b	$e3,$70,$45,$62,$3d,$c4,$07,$24,$0e,$9c,$1f,$d5,$a7,$5f,$81,$9d
	dc.b	$26,$3f,$c4,$19,$fc,$a5,$b0,$b8,$b2,$7c,$1e,$a9,$ff,$07,$ee,$af
	dc.b	$ff,$e7,$51,$42,$72,$f5,$fa,$57,$57,$52,$df,$8d,$c1,$93,$82,$eb
	dc.b	$d8,$79,$5d,$5b,$ff,$d7,$c1,$58,$c6,$2d,$de,$75,$3b,$b2,$ca,$ea
	dc.b	$d2,$c6,$36,$a8,$49,$d8,$97,$69,$5f,$47,$a6,$d7,$b2,$ec,$bc,$2b
	dc.b	$9c,$c0,$40,$0f,$0e,$4d,$06,$d6,$a4,$36,$4b,$1a,$8e,$de,$1b,$ed
	dc.b	$cd,$51,$8f,$a7,$e0,$76,$79,$05,$18,$f1,$09,$cf,$37,$a6,$fa,$98
	dc.b	$25,$24,$7c,$37,$b7,$06,$85,$ac,$fb,$64,$c6,$69,$58,$c3,$bd,$bf
	dc.b	$2a,$df,$f4,$ba,$ac,$30,$0d,$41,$28,$67,$81,$8c,$c2,$3d,$ad,$e2
	dc.b	$a8,$cd,$e9,$b7,$2c,$31,$d7,$4d,$b0,$d6,$19,$3f,$e4,$fb,$40,$79
	dc.b	$75,$0d,$19,$bd,$e8,$22,$b2,$9b,$42,$0b,$c3,$60,$0e,$e0,$fb,$dd
	dc.b	$ba,$ee,$66,$21,$58,$19,$d1,$8f,$b4,$14,$ed,$15,$f6,$33,$38,$eb
	dc.b	$16,$83,$50,$bb,$e7,$6a,$9b,$89,$e5,$25,$5b,$b3,$4c,$3f,$39,$98
	dc.b	$b6,$ff,$61,$4d,$7c,$92,$c3,$49,$59,$f1,$c9,$8e,$1c,$ac,$65,$a6
	dc.b	$1c,$69,$f9,$63,$2a,$aa,$f4,$19,$3d,$47,$76,$14,$eb,$b3,$33,$d1
	dc.b	$2e,$72,$e8,$9a,$bd,$a8,$5f,$59,$63,$a9,$17,$e9,$d5,$8f,$10,$a0
	dc.b	$66,$e4,$a5,$c6,$d8,$db,$74,$49,$6a,$d7,$fd,$21,$b6,$97,$23,$95
	dc.b	$78,$53,$bd,$6e,$72,$89,$fa,$d6,$b6,$84,$6c,$82,$5b,$2d,$5a,$16
	dc.b	$78,$eb,$f0,$97,$cb,$ef,$61,$4d,$b0,$d6,$c1,$47,$dc,$41,$9c,$86
	dc.b	$0b,$d1,$eb,$bc,$e9,$49,$1f,$4b,$e7,$3c,$35,$da,$a9,$29,$c4,$9c
	dc.b	$d5,$46,$b3,$c4,$4f,$5d,$94,$65,$cf,$4f,$61,$5f,$b9,$1b,$47,$4c
	dc.b	$20,$a1,$7c,$65,$11,$bc,$2f,$83,$58,$6d,$a3,$99,$14,$ca,$b2,$71
	dc.b	$12,$7c,$ce,$81,$9b,$de,$b6,$c3,$bb,$45,$c5,$e7,$de,$b6,$8d,$be
	dc.b	$f0,$5c,$74,$17,$33,$eb,$5f,$f9,$e2,$63,$1f,$d9,$d2,$9d,$f3,$5e
	dc.b	$ac,$44,$b8,$ef,$ee,$05,$12,$3b,$df,$ce,$5e,$bb,$28,$42,$b7,$a2
	dc.b	$2f,$12,$9c,$38,$14,$f5,$eb,$16,$ac,$30,$53,$c7,$12,$7f,$4a,$ea
	dc.b	$b9,$13,$26,$de,$3f,$cb,$ec,$dd,$aa,$f5,$8a,$1d,$ad,$ba,$0a,$6b
	dc.b	$b3,$f5,$d5,$81,$d5,$de,$9a,$bd,$ab,$af,$8f,$67,$55,$f3,$f4,$55
	dc.b	$8e,$ae,$8d,$2e,$01,$f4,$b1,$f8,$82,$a2,$a0,$af,$a2,$c5,$a4,$dc
	dc.b	$ab,$dd,$21,$fd,$1a,$5e,$73,$3b,$11,$32,$a0,$f1,$52,$50,$2a,$fb
	dc.b	$5d,$b7,$0e,$be,$7a,$7d,$05,$6c,$54,$8e,$0a,$16,$d0,$fd,$4e,$43
	dc.b	$f5,$6b,$f5,$66,$dd,$b1,$be,$cf,$cf,$58,$63,$a2,$c3,$f8,$08,$ae
	dc.b	$0d,$57,$da,$e0,$6d,$74,$ca,$49,$ad,$50,$ed,$e5,$08,$26,$d7,$c7
	dc.b	$4c,$29,$df,$a0,$ae,$bc,$0f,$85,$61,$ba,$80,$c8,$a6,$e8,$f6,$e8
	dc.b	$b2,$eb,$f5,$c0,$cd,$c0,$fb,$15,$a5,$e4,$f1,$05,$e1,$b5,$9e,$8d
	dc.b	$fb,$da,$f4,$cb,$66,$7b,$7e,$e7,$b8,$6c,$1f,$d3,$69,$aa,$9f,$aa
	dc.b	$66,$53,$9d,$fc,$f8,$dc,$02,$2f,$c8,$bc,$51,$a8,$54,$47,$3b,$0a
	dc.b	$98,$1d,$9f,$51,$67,$78,$3b,$53,$64,$ae,$b0,$c2,$8a,$28,$0f,$cb
	dc.b	$4a,$7e,$47,$e4,$05,$f9,$e9,$ce,$35,$7d,$b7,$cd,$74,$2a,$83,$41
	dc.b	$9d,$9f,$a9,$d9,$47,$57,$63,$57,$5e,$fd,$4d,$a1,$b6,$4e,$a3,$29
	dc.b	$ae,$fc,$c6,$30,$50,$0c,$b1,$ec,$28,$2e,$ec,$fa,$29,$a8,$89,$26
	dc.b	$18,$e6,$e6,$c9,$7b,$ad,$be,$df,$f5,$14,$c7,$cc,$9f,$4d,$4d,$09
	dc.b	$21,$8d,$c8,$7e,$cf,$a5,$b3,$e4,$ee,$a2,$bb,$63,$36,$3e,$42,$8f
	dc.b	$bb,$4c,$c9,$cf,$37,$84,$17,$e1,$dd,$b5,$1d,$c5,$63,$5f,$a8,$af
	dc.b	$3c,$9f,$09,$97,$21,$ff,$9c,$8b,$d7,$7e,$b5,$2e,$65,$7e,$e3,$34
	dc.b	$e9,$84,$3b,$f5,$d9,$49,$7e,$f7,$8a,$fd,$2d,$35,$a7,$68,$99,$47
	dc.b	$af,$44,$9f,$29,$7a,$0a,$ed,$8c,$d4,$fd,$1f,$10,$1c,$99,$56,$d5
	dc.b	$78,$1d,$b3,$e6,$63,$a6,$fd,$9f,$f1,$f1,$dd,$f6,$77,$be,$6b,$ae
	dc.b	$58,$e2,$f1,$b6,$80,$ea,$49,$cd,$c0,$f8,$bd,$8f,$90,$91,$64,$98
	dc.b	$cc,$dc,$0f,$2b,$2f,$6a,$6c,$d7,$37,$95,$14,$2d,$06,$04,$67,$95
	dc.b	$fc,$d1,$60,$fc,$9d,$1a,$ab,$ee,$d8,$cd,$a3,$85,$51,$50,$f7,$41
	dc.b	$eb,$ea,$eb,$df,$73,$c4,$34,$f7,$d2,$ef,$1d,$1f,$db,$31,$8a,$81
	dc.b	$97,$aa,$cf,$4b,$71,$71,$26,$e0,$db,$46,$0e,$8f,$f7,$59,$2f,$0b
	dc.b	$ee,$a2,$89,$f9,$cc,$71,$d8,$34,$54,$d7,$11,$c6,$4e,$ef,$08,$fb
	dc.b	$32,$bd,$76,$7b,$1a,$1b,$91,$37,$0b,$77,$b4,$59,$cf,$37,$9e,$0b
	dc.b	$f0,$e5,$20,$78,$21,$63,$5e,$2f,$c5,$a3,$ca,$a3,$35,$dc,$a3,$c0
	dc.b	$7d,$45,$24,$fa,$1d,$ff,$4c,$c2,$09,$96,$ee,$a7,$4c,$2f,$a7,$60
	dc.b	$9b,$3f,$5d,$5a,$60,$d6,$13,$16,$e8,$f4,$2e,$8b,$ad,$4f,$d8,$54
	dc.b	$68,$6d,$88,$54,$d8,$5f,$d8,$55,$5e,$f1,$c5,$b3,$31,$db,$5b,$5f
	dc.b	$04,$6e,$e7,$31,$ac,$f9,$cf,$a7,$b2,$f2,$47,$63,$22,$a3,$50,$bc
	dc.b	$8e,$f5,$1e,$c9,$57,$51,$4c,$66,$62,$bb,$27,$32,$a9,$a9,$b4,$01
	dc.b	$35,$f3,$71,$44,$b5,$7f,$8d,$73,$18,$01,$20,$c9,$d6,$c6,$ae,$2f
	dc.b	$57,$d1,$a1,$b6,$81,$c9,$f5,$14,$c7,$eb,$d3,$5e,$a2,$b8,$e2,$40
	dc.b	$69,$ef,$36,$bb,$47,$50,$d9,$bf,$15,$90,$10,$2d,$f9,$f4,$f2,$f8
	dc.b	$7d,$76,$53,$59,$46,$07,$01,$e6,$e1,$e0,$a7,$ab,$4f,$cc,$75,$15
	dc.b	$26,$b8,$c2,$e1,$40,$9e,$f9,$fa,$ed,$53,$d3,$d7,$65,$48,$93,$85
	dc.b	$be,$3d,$a7,$4b,$ad,$9d,$b7,$14,$e5,$3f,$bd,$38,$58,$8d,$57,$8a
	dc.b	$b2,$d0,$65,$dc,$fd,$1f,$9f,$54,$72,$ba,$8f,$61,$14,$13,$05,$d4
	dc.b	$e9,$86,$df,$d7,$7a,$64,$d4,$47,$d2,$d3,$58,$4f,$ef,$51,$5f,$00
	dc.b	$eb,$b3,$d4,$53,$ca,$bc,$3f,$ee,$c6,$07,$26,$0d,$1a,$fb,$bc,$22
	dc.b	$d0,$7e,$3a,$e7,$c8,$f6,$d1,$bb,$a2,$fe,$19,$b4,$86,$17,$95,$17
	dc.b	$fd,$56,$57,$5e,$7c,$4a,$48,$28,$b4,$8f,$a8,$f4,$52,$c9,$c5,$ca
	dc.b	$a5,$a1,$7e,$01,$18,$76,$28,$a0,$9a,$92,$7f,$01,$39,$93,$3a,$c1
	dc.b	$e5,$fe,$ab,$e7,$95,$75,$09,$ba,$a2,$a3,$a6,$be,$af,$19,$1d,$5d
	dc.b	$39,$77,$f7,$73,$01,$b6,$47,$57,$78,$c6,$18,$16,$1b,$9b,$20,$23
	dc.b	$a5,$2e,$65,$12,$ae,$26,$24,$c8,$31,$49,$c2,$0e,$59,$f6,$1e,$79
	dc.b	$f7,$d4,$57,$12,$df,$af,$13,$2e,$a1,$b5,$a1,$64,$2a,$52,$32,$bc
	dc.b	$77,$87,$c4,$d6,$c7,$a8,$a1,$4a,$eb,$55,$ed,$8f,$b3,$ab,$67,$4b
	dc.b	$aa,$35,$5e,$0e,$ca,$8b,$72,$ab,$bd,$5e,$2b,$94,$d5,$94,$c5,$b8
	dc.b	$f7,$44,$77,$25,$20,$db,$d3,$79,$51,$dc,$ca,$23,$59,$37,$3a,$61
	dc.b	$37,$d0,$fe,$a2,$83,$4c,$82,$36,$d1,$b5,$68,$e5,$cc,$a3,$c5,$a0
	dc.b	$3a,$dd,$40,$cd,$d9,$62,$95,$cc,$c4,$5c,$2f,$65,$cf,$a3,$5f,$70
	dc.b	$2b,$7f,$33,$9d,$03,$fc,$50,$ca,$d3,$fa,$9f,$de,$78,$55,$9f,$77
	dc.b	$b3,$7b,$f4,$de,$56,$56,$eb,$ca,$59,$8c,$28,$1c,$ae,$5c,$8a,$dd
	dc.b	$79,$5d,$4c,$9c,$7a,$35,$57,$ad,$cc,$63,$9c,$ae,$ac,$a6,$f5,$27
	dc.b	$f0,$11,$61,$6b,$ad,$8a,$ae,$35,$5f,$0a,$57,$e2,$27,$98,$f7,$d5
	dc.b	$e3,$87,$57,$47,$57,$6a,$03,$d0,$c3,$61,$73,$ba,$4d,$1b,$88,$6f
	dc.b	$36,$9e,$a5,$cc,$54,$6f,$da,$39,$8a,$e5,$cc,$36,$07,$b4,$3c,$26
	dc.b	$f9,$68,$10,$23,$e5,$38,$b1,$98,$4d,$34,$2c,$95,$38,$67,$39,$ce
	dc.b	$f7,$6d,$28,$b3,$29,$67,$f3,$ca,$b5,$8b,$75,$72,$46,$ce,$67,$48
	dc.b	$76,$2c,$ae,$2f,$52,$4f,$1b,$4f,$58,$66,$73,$95,$3e,$b4,$fd,$b9
	dc.b	$c2,$b4,$9d,$83,$24,$1b,$7a,$03,$71,$3d,$05,$7a,$a3,$f8,$23,$43
	dc.b	$3c,$ba,$3d,$7c,$bf,$47,$ac,$a8,$06,$7e,$4b,$ca,$bf,$3d,$bf,$82
	dc.b	$e0,$76,$56,$86,$34,$67,$4a,$93,$2d,$fb,$fa,$03,$ef,$7d,$90,$bb
	dc.b	$b8,$af,$6b,$a5,$b1,$fe,$7d,$e6,$ab,$b5,$ee,$dc,$07,$9e,$82,$94
	dc.b	$a4,$14,$46,$57,$f4,$1e,$e1,$e4,$e2,$89,$97,$dc,$a6,$82,$33,$1d
	dc.b	$e3,$85,$a5,$eb,$ef,$c0,$62,$ff,$44,$ee,$b0,$63,$71,$82,$86,$bc
	dc.b	$ab,$05,$d7,$fc,$a8,$a8,$13,$53,$29,$64,$8e,$f5,$d2,$ef,$ef,$d4
	dc.b	$41,$b9,$a7,$74,$5b,$18,$2c,$c3,$5d,$64,$04,$27,$3d,$16,$57,$1f
	dc.b	$c3,$f3,$1e,$a1,$8c,$ae,$51,$70,$f0,$94,$c2,$04,$34,$fc,$a7,$1c
	dc.b	$a0,$4c,$6d,$00,$54,$ea,$d1,$71,$8c,$c7,$97,$32,$40,$fc,$29,$5d
	dc.b	$62,$df,$d9,$18,$fc,$5f,$3a,$51,$b7,$9d,$57,$8a,$28,$47,$e6,$76
	dc.b	$d5,$d8,$cf,$ae,$38,$2b,$45,$98,$7f,$ed,$a7,$1c,$5e,$8b,$d3,$cc
	dc.b	$1b,$c6,$cd,$73,$a6,$09,$b6,$dc,$10,$e7,$b9,$be,$c1,$e6,$29,$69
	dc.b	$57,$31,$5f,$07,$5d,$e8,$09,$ff,$24,$52,$bf,$9e,$5a,$07,$fe,$ee
	dc.b	$83,$0c,$6c,$1f,$af,$9d,$0f,$de,$29,$9d,$1d,$cf,$c3,$7c,$f7,$16
	dc.b	$1f,$35,$89,$3b,$dd,$5c,$fd,$e9,$ea,$3b,$4e,$9c,$e0,$7c,$5e,$9b
	dc.b	$ba,$72,$ce,$9b,$a9,$87,$14,$4a,$98,$9c,$b9,$9a,$fd,$71,$db,$56
	dc.b	$8b,$db,$5f,$fe,$03,$66,$c6,$17,$5b,$9e,$3e,$d0,$50,$d1,$4a,$e0
	dc.b	$b2,$d9,$56,$cc,$06,$a6,$63,$75,$74,$15,$3b,$02,$0a,$77,$f5,$d5
	dc.b	$cf,$e1,$14,$37,$a0,$a5,$a9,$71,$d4,$5e,$ec,$fc,$7a,$0a,$75,$f5
	dc.b	$02,$ad,$c6,$70,$f5,$1d,$cf,$e8,$28,$9f,$c5,$03,$90,$1d,$11,$90
	dc.b	$27,$7b,$dd,$a4,$57,$d3,$71,$aa,$49,$fc,$e4,$c0,$fc,$15,$6b,$ba
	dc.b	$d6,$3c,$53,$27,$b1,$ea,$72,$59,$d4,$27,$05,$2a,$ad,$b4,$f8,$4a
	dc.b	$06,$50,$cd,$d2,$15,$4d,$37,$ed,$e8,$2b,$a4,$94,$65,$74,$69,$35
	dc.b	$fe,$ce,$98,$31,$fa,$0a,$5b,$ef,$5a,$f5,$86,$ea,$51,$b0,$ca,$3a
	dc.b	$e8,$28,$43,$ae,$17,$03,$77,$92,$15,$7d,$fe,$1f,$fc,$fd,$cd,$96
	dc.b	$30,$e5,$f8,$39,$9f,$14,$28,$78,$9e,$7f,$3c,$1a,$37,$88,$57,$e6
	dc.b	$b2,$9d,$6a,$1f,$b9,$c2,$82,$8c,$6f,$52,$df,$7d,$8a,$64,$3a,$6a
	dc.b	$3c,$c3,$90,$50,$e6,$52,$ef,$b5,$16,$d0,$62,$bf,$cb,$e1,$01,$8e
	dc.b	$c4,$b5,$d7,$f3,$bd,$68,$34,$34,$2a,$c1,$75,$a0,$d5,$8b,$02,$4e
	dc.b	$65,$67,$d4,$7a,$05,$d4,$50,$3f,$0a,$b6,$17,$5b,$80,$ec,$28,$2a
	dc.b	$fd,$45,$49,$95,$c6,$4b,$c0,$4a,$e5,$7c,$97,$79,$37,$f4,$22,$10
	dc.b	$cf,$e5,$ba,$6c,$59,$02,$12,$41,$1b,$2c,$c8,$9a,$d9,$5f,$91,$bc
	dc.b	$a9,$92,$13,$f0,$95,$d7,$7f,$72,$f2,$b7,$26,$27,$fb,$29,$5a,$4d
	dc.b	$6f,$8a,$28,$27,$65,$c0,$f5,$86,$e9,$e7,$53,$97,$22,$65,$36,$ee
	dc.b	$d5,$7e,$72,$06,$22,$ea,$0d,$da,$f5,$15,$f3,$6e,$42,$0a,$ea,$7f
	dc.b	$3f,$ea,$f5,$83,$a5,$1e,$9b,$e0,$eb,$f8,$08,$d8,$6c,$4a,$fd,$ff
	dc.b	$24,$ef,$c5,$5f,$50,$b3,$f2,$5c,$2c,$55,$be,$fc,$4f,$30,$38,$07
	dc.b	$9d,$64,$7d,$fa,$9c,$cc,$f5,$21,$d5,$77,$61,$5b,$76,$1e,$dc,$c6
	dc.b	$14,$c9,$c8,$8b,$9a,$77,$98,$6f,$b1,$2a,$73,$3d,$cb,$55,$d3,$cc
	dc.b	$1c,$e4,$10,$3d,$e5,$1d,$9c,$cd,$e5,$4a,$ac,$05,$0d,$12,$b8,$2c
	dc.b	$37,$97,$ab,$77,$50,$4d,$cc,$ea,$c0,$ef,$42,$6a,$f5,$8d,$18,$50
	dc.b	$af,$75,$50,$9c,$44,$70,$9d,$c4,$0d,$a5,$2e,$79,$15,$ee,$c1,$d4
	dc.b	$0e,$21,$e0,$97,$d7,$4e,$4b,$bd,$2b,$a5,$e6,$10,$80,$6d,$a1,$22
	dc.b	$ce,$51,$15,$01,$d6,$4b,$d6,$66,$fd,$8e,$ee,$f9,$c5,$9c,$c3,$2b
	dc.b	$d5,$39,$43,$b2,$67,$5d,$8f,$fb,$2b,$86,$fa,$cd,$ca,$ec,$97,$f4
	dc.b	$7e,$7d,$76,$36,$cf,$39,$bf,$5c,$82,$d0,$e7,$1f,$45,$36,$3d,$56
	dc.b	$52,$c8,$be,$bf,$a1,$79,$76,$98,$56,$73,$72,$11,$af,$0e,$b5,$aa
	dc.b	$ea,$40,$e9,$b7,$ec,$d8,$b9,$08,$c2,$b7,$a2,$8c,$6c,$8e,$03,$6f
	dc.b	$c4,$75,$34,$f6,$28,$59,$fc,$b2,$fa,$5f,$63,$d3,$f8,$90,$dc,$d1
	dc.b	$c0,$c5,$fd,$93,$20,$7f,$28,$9f,$c7,$85,$d3,$ea,$f3,$b3,$5d,$1e
	dc.b	$bc,$f5,$20,$91,$91,$0a,$14,$84,$18,$8b,$9a,$cf,$98,$7c,$76,$a4
	dc.b	$de,$d4,$cb,$ba,$ba,$79,$c2,$73,$96,$2f,$b2,$43,$ca,$93,$79,$c5
	dc.b	$de,$80,$a0,$b0,$03,$42,$8e,$b5,$b3,$cd,$09,$b9,$99,$9b,$4c,$7a
	dc.b	$13,$4f,$7e,$8e,$8c,$28,$53,$3b,$6c,$e7,$7d,$71,$cd,$f5,$75,$c0
	dc.b	$4a,$27,$a0,$a5,$59,$91,$ba,$8f,$19,$37,$0e,$de,$1c,$97,$01,$ab
	dc.b	$3c,$c2,$a3,$07,$ff,$78,$57,$6a,$c8,$11,$18,$16,$2f,$e0,$7b,$cc
	dc.b	$eb,$7a,$61,$65,$0f,$62,$61,$01,$6f,$b6,$82,$bf,$5e,$5f,$ec,$84
	dc.b	$bd,$e8,$be,$3d,$2f,$2a,$3b,$d7,$aa,$32,$c2,$67,$eb,$95,$9b,$61
	dc.b	$6f,$1d,$6c,$bb,$aa,$7f,$f0,$fb,$4b,$8a,$cf,$87,$1a,$86,$78,$2d
	dc.b	$fa,$a2,$ff,$d9,$87,$4b,$31,$95,$5b,$4d,$c0,$03,$4a,$03,$5f,$0d
	dc.b	$e5,$79,$9e,$fa,$05,$e9,$f1,$5d,$4c,$53,$13,$f3,$58,$33,$3b,$5a
	dc.b	$bc,$7e,$ca,$ee,$3f,$f7,$b8,$de,$ff,$13,$3f,$0b,$af,$20,$05,$e5
	dc.b	$8f,$20,$94,$68,$bd,$f6,$22,$e4,$1b,$17,$7e,$3d,$52,$4f,$f5,$34
	dc.b	$ae,$a6,$22,$6e,$3b,$8e,$08,$1f,$2a,$1b,$49,$bc,$c5,$58,$0d,$cd
	dc.b	$00,$34,$34,$cb,$4e,$bb,$e8,$03,$cc,$bc,$e4,$ed,$bb,$52,$ed,$4b
	dc.b	$ff,$5e,$86,$0a,$d3,$d8,$53,$be,$83,$5d,$5a,$e9,$f0,$24,$ae,$fa
	dc.b	$bd,$6d,$78,$51,$ea,$d2,$4b,$8b,$27,$87,$8c,$de,$4d,$87,$5d,$3a
	dc.b	$2e,$d0,$19,$8a,$60,$23,$86,$18,$bb,$1f,$d3,$d8,$81,$c2,$9e,$54
	dc.b	$66,$01,$6e,$a2,$85,$37,$fe,$c9,$d9,$3e,$c6,$67,$dd,$ca,$93,$64
	dc.b	$7d,$52,$9f,$2a,$3f,$ae,$67,$ec,$99,$bd,$5e,$b4,$58,$bc,$59,$da
	dc.b	$45,$43,$6a,$7a,$8a,$7a,$65,$aa,$da,$5d,$c7,$94,$0c,$c2,$13,$d5
	dc.b	$eb,$82,$b2,$b8,$91,$c2,$68,$51,$c7,$d3,$f6,$b2,$5e,$b7,$67,$a5
	dc.b	$e8,$fd,$a6,$cb,$35,$c2,$b7,$e1,$de,$ab,$e3,$8e,$96,$36,$6c,$66
	dc.b	$f7,$18,$90,$e5,$76,$ca,$56,$fe,$1e,$8e,$57,$6a,$22,$59,$17,$29
	dc.b	$de,$76,$e1,$ff,$a4,$ed,$8c,$a5,$74,$71,$68,$77,$1d,$8c,$59,$37
	dc.b	$54,$5e,$57,$66,$00,$68,$2d,$e6,$83,$45,$c4,$0f,$da,$b6,$16,$d3
	dc.b	$3b,$ba,$84,$e5,$4c,$d4,$53,$7d,$99,$07,$be,$6e,$3a,$b5,$eb,$da
	dc.b	$ea,$d2,$94,$57,$b5,$7c,$19,$ea,$2a,$e1,$db,$bd,$c0,$4d,$e1,$ff
	dc.b	$3c,$9b,$16,$7a,$7d,$a3,$88,$c2,$99,$2b,$c7,$42,$30,$fb,$69,$ec
	dc.b	$40,$fe,$54,$f2,$a3,$2e,$c8,$be,$6f,$45,$c9,$d9,$3e,$74,$cf,$77
	dc.b	$06,$e7,$e3,$7e,$a9,$4f,$95,$18,$bc,$79,$fb,$74,$9d,$c1,$f3,$e7
	dc.b	$28,$f6,$0a,$28,$6e,$6b,$45,$c2,$a1,$b6,$a0,$e5,$55,$b4,$d1,$ad
	dc.b	$a4,$36,$98,$79,$98,$1d,$27,$e8,$c9,$03,$ce,$6f,$e2,$89,$1c,$3c
	dc.b	$c2,$8f,$3d,$e2,$d4,$b5,$b1,$dd,$4f,$47,$ed,$3d,$d3,$5d,$58,$fe
	dc.b	$87,$e7,$47,$70,$c7,$cb,$f1,$a7,$60,$e6,$70,$ca,$ea,$d2,$e5,$23
	dc.b	$4f,$89,$52,$45,$c4,$dc,$8a,$07,$fe,$95,$31,$9a,$aa,$ea,$95,$a6
	dc.b	$d3,$3b,$15,$37,$4b,$ab,$4a,$9b,$d0,$b9,$ad,$bd,$45,$3c,$d0,$68
	dc.b	$a3,$c3,$f5,$bb,$85,$8f,$d7,$77,$50,$c5,$76,$a8,$a6,$5b,$32,$2c
	dc.b	$ff,$af,$1d,$4c,$e1,$c0,$93,$d3,$65,$08,$3f,$8c,$1b,$d8,$0b,$2e
	dc.b	$af,$48,$76,$cc,$91,$e1,$a2,$dd,$dd,$81,$f8,$17,$37,$d8,$29,$fd
	dc.b	$d0,$98,$78,$53,$be,$a8,$c1,$6e,$8d,$97,$c2,$53,$98,$3b,$ca,$87
	dc.b	$a3,$dd,$1c,$ff,$29,$c5,$bc,$96,$75,$d2,$78,$37,$bf,$a3,$ea,$5c
	dc.b	$c8,$3e,$96,$6e,$64,$9a,$56,$b1,$e4,$f9,$8a,$39,$04,$37,$8d,$39
	dc.b	$c0,$95,$c9,$6d,$98,$33,$1c,$9c,$07,$49,$b6,$98,$6d,$04,$ec,$f5
	dc.b	$0e,$e6,$53,$1c,$a6,$03,$ac,$8e,$f2,$68,$51,$5b,$23,$cb,$42,$f9
	dc.b	$99,$df,$b6,$a0,$3e,$3f,$39,$6e,$6f,$7b,$b1,$6e,$3e,$fa,$5f,$f6
	dc.b	$ad,$f6,$09,$60,$3d,$e7,$b6,$4f,$d8,$51,$0a,$6f,$b2,$80,$ce,$72
	dc.b	$4c,$8b,$5b,$34,$18,$1b,$94,$9d,$17,$70,$a7,$33,$9c,$53,$ba,$0e
	dc.b	$a5,$de,$7b,$46,$63,$66,$9c,$01,$5c,$de,$9a,$2a,$19,$79,$3f,$a0
	dc.b	$bf,$0e,$6f,$ab,$5a,$82,$f1,$d9,$75,$cc,$de,$a0,$cf,$e9,$c1,$39
	dc.b	$91,$25,$65,$45,$2b,$19,$52,$46,$19,$f4,$d7,$37,$ac,$8f,$07,$bc
	dc.b	$af,$57,$ab,$ab,$52,$6a,$6f,$b8,$15,$da,$ea,$65,$ca,$2c,$bc,$c6
	dc.b	$1d,$7b,$dd,$0e,$22,$dd,$1d,$6d,$74,$69,$9b,$a0,$ac,$bd,$f6,$c4
	dc.b	$17,$eb,$cc,$3f,$98,$9f,$13,$4b,$79,$87,$4e,$e8,$b2,$e2,$9c,$4d
	dc.b	$ed,$7e,$82,$b6,$41,$0d,$ce,$39,$c6,$b4,$f3,$26,$33,$58,$64,$db
	dc.b	$a0,$a9,$c4,$14,$41,$d2,$75,$0b,$01,$e0,$f6,$2a,$03,$bc,$6d,$74
	dc.b	$14,$f3,$3b,$c1,$9a,$ff,$30,$df,$1b,$e9,$7b,$9e,$0e,$9b,$9f,$c1
	dc.b	$96,$cd,$a1,$de,$5f,$81,$db,$1f,$e7,$d2,$fa,$91,$98,$f2,$1e,$62
	dc.b	$83,$14,$cc,$8c,$1b,$9c,$e1,$2e,$bb,$4d,$73,$e6,$58,$69,$93,$8c
	dc.b	$5a,$fe,$a2,$a8,$f7,$3d,$d1,$37,$39,$d5,$9e,$62,$fc,$33,$19,$cd
	dc.b	$75,$69,$83,$0d,$bf,$a2,$cb,$fe,$05,$b6,$bd,$53,$9e,$d6,$c2,$4d
	dc.b	$d3,$fd,$43,$af,$73,$8b,$09,$90,$d4,$00,$69,$72,$77,$2b,$a8,$fd
	dc.b	$8a,$a1,$65,$d4,$57,$0e,$5b,$c2,$cd,$cf,$8a,$9e,$16,$d4,$ec,$8d
	dc.b	$c4,$c6,$3a,$9f,$bc,$a1,$fc,$0b,$ad,$9f,$d7,$6c,$5f,$cb,$99,$3f
	dc.b	$65,$40,$16,$d3,$ca,$0c,$44,$f8,$34,$58,$96,$3a,$b4,$3d,$0a,$f1
	dc.b	$73,$7d,$60,$c5,$dd,$16,$95,$ec,$96,$dd,$85,$31,$d1,$67,$fd,$26
	dc.b	$27,$f7,$f9,$6c,$98,$9a,$b2,$ca,$ba,$8f,$1c,$33,$f4,$6b,$60,$e9
	dc.b	$0f,$22,$a1,$1b,$ab,$d4,$3c,$91,$c4,$9b,$c4,$35,$93,$eb,$bb,$29
	dc.b	$bc,$7c,$bd,$c2,$49,$75,$a6,$17,$f5,$b3,$9c,$67,$03,$bf,$dd,$16
	dc.b	$b3,$ad,$98,$43,$01,$e5,$c8,$31,$54,$f2,$98,$a4,$45,$f5,$5d,$e0
	dc.b	$89,$c9,$6c,$9c,$13,$7d,$b1,$95,$d0,$4e,$10,$59,$d2,$4a,$f7,$5b
	dc.b	$3c,$b9,$84,$31,$9d,$50,$2a,$0b,$13,$41,$a1,$8c,$4f,$10,$c8,$bf
	dc.b	$ca,$7e,$86,$cd,$07,$74,$09,$2f,$ea,$32,$be,$d4,$e0,$fa,$1b,$55
	dc.b	$d3,$65,$79,$6b,$27,$ff,$44,$61,$c6,$48,$82,$51,$65,$e0,$da,$c5
	dc.b	$ad,$94,$d5,$1b,$21,$79,$d7,$e3,$32,$79,$ae,$10,$d2,$8a,$a7,$bf
	dc.b	$63,$95,$65,$d7,$94,$27,$2b,$95,$d4,$51,$90,$68,$dc,$fa,$32,$2d
	dc.b	$85,$a6,$38,$e9,$66,$a9,$fb,$8c,$ed,$56,$45,$94,$cc,$e8,$77,$51
	dc.b	$5a,$b4,$57,$ff,$ad,$db,$01,$86,$72,$f3,$08,$5a,$67,$0e,$11,$b4
	dc.b	$68,$34,$cc,$87,$91,$54,$0c,$8a,$c6,$1f,$3c,$91,$3c,$fa,$f9,$9d
	dc.b	$59,$ce,$d3,$f3,$d8,$e1,$f8,$fc,$d1,$b3,$7f,$21,$b3,$ec,$f2,$ca
	dc.b	$75,$b1,$bc,$6b,$aa,$7f,$26,$b3,$50,$81,$e5,$0c,$19,$b7,$e0,$00
	dc.b	$8d,$c2,$88,$63,$47,$06,$0d,$3e,$d8,$26,$15,$bb,$66,$62,$c7,$d6
	dc.b	$cc,$38,$5a,$68,$b9,$48,$2c,$9c,$f2,$0f,$c3,$d7,$61,$80,$52,$a2
	dc.b	$6a,$0c,$c9,$5e,$30,$d3,$62,$35,$9f,$10,$d7,$36,$9b,$5e,$cd,$75
	dc.b	$f5,$0a,$71,$d6,$8b,$7d,$0e,$a1,$1f,$3a,$5c,$f2,$d5,$2e,$53,$3c
	dc.b	$7c,$1a,$92,$07,$a5,$32,$85,$51,$6b,$cc,$e2,$f0,$6f,$11,$e4,$75
	dc.b	$ab,$ec,$d2,$d2,$f8,$b8,$dd,$6b,$ba,$a5,$d6,$50,$75,$df,$cf,$85
	dc.b	$af,$4c,$db,$4a,$39,$41,$dd,$c5,$b7,$bc,$18,$d5,$4f,$0f,$e4,$d4
	dc.b	$fc,$c7,$76,$d5,$f8,$18,$77,$c5,$2a,$64,$81,$ee,$56,$72,$1b,$82
	dc.b	$72,$52,$c5,$3b,$81,$bb,$f6,$4d,$b3,$1b,$be,$ad,$fc,$71,$4e,$6e
	dc.b	$ab,$63,$2a,$e1,$5b,$87,$e0,$8b,$92,$00,$c7,$7d,$91,$62,$07,$f6
	dc.b	$b4,$ff,$fb,$79,$1c,$47,$d6,$fa,$37,$13,$dc,$ab,$c7,$2b,$7b,$49
	dc.b	$5f,$70,$3f,$ba,$60,$4a,$1e,$e2,$c0,$16,$18,$52,$10,$b5,$52,$34
	dc.b	$bb,$13,$e4,$b8,$0e,$76,$1f,$f9,$b1,$f2,$09,$fc,$b2,$98,$26,$0d
	dc.b	$27,$98,$33,$1e,$bd,$7c,$2a,$2a,$21,$07,$b0,$d4,$76,$97,$74,$61
	dc.b	$70,$14,$ef,$a6,$8d,$19,$a5,$f5,$0d,$5b,$63,$31,$f4,$d0,$25,$86
	dc.b	$34,$b8,$65,$8c,$34,$74,$a8,$cd,$14,$c1,$b6,$d2,$ed,$32,$9e,$1b
	dc.b	$41,$80,$0d,$cb,$c5,$a1,$4a,$cf,$a5,$e9,$c2,$37,$fe,$c7,$19,$99
	dc.b	$55,$a1,$f4,$77,$72,$11,$16,$fa,$57,$60,$d7,$47,$b6,$ff,$25,$e5
	dc.b	$0e,$81,$f8,$7e,$9b,$21,$8b,$80,$b1,$99,$33,$32,$87,$e0,$ca,$62
	dc.b	$82,$ff,$f2,$9c,$90,$4a,$87,$8a,$d2,$71,$fc,$3b,$66,$5a,$b2,$e6
	dc.b	$3d,$43,$f3,$44,$c7,$88,$90,$c3,$57,$7e,$66,$b0,$46,$67,$3c,$6c
	dc.b	$e9,$5b,$c3,$56,$de,$e7,$c5,$75,$29,$7c,$97,$ed,$99,$d9,$45,$f9
	dc.b	$b6,$84,$79,$06,$42,$9c,$a8,$4f,$85,$23,$2e,$89,$5d,$e5,$39,$89
	dc.b	$b2,$54,$d0,$eb,$4b,$a6,$1f,$cc,$54,$cb,$9e,$43,$b4,$f3,$03,$41
	dc.b	$c2,$84,$4d,$06,$88,$2c,$d7,$46,$a5,$da,$12,$a2,$38,$2a,$24,$d1
	dc.b	$b7,$b2,$4c,$85,$38,$25,$5a,$f4,$30,$b9,$c6,$59,$e9,$71,$2b,$6e
	dc.b	$eb,$6c,$7f,$0d,$af,$07,$59,$80,$92,$79,$94,$20,$39,$20,$77,$10
	dc.b	$f7,$f1,$12,$0f,$25,$2a,$ac,$65,$6b,$67,$8b,$8c,$65,$4a,$3f,$97
	dc.b	$15,$09,$ee,$88,$79,$e5,$3a,$ab,$db,$32,$6c,$a7,$ad,$5c,$3b,$6e
	dc.b	$43,$a5,$35,$35,$9e,$ac,$80,$95,$fb,$ca,$d8,$57,$20,$c5,$e2,$a9
	dc.b	$69,$4d,$93,$63,$14,$14,$61,$a3,$ca,$4e,$e4,$c6,$15,$bc,$5d,$5b
	dc.b	$88,$0d,$a7,$a6,$b7,$33,$6d,$78,$12,$38,$96,$e8,$4f,$33,$9a,$6c
	dc.b	$9b,$fb,$71,$67,$6d,$d2,$59,$f9,$1f,$6f,$86,$c7,$c9,$0a,$f8,$77
	dc.b	$58,$6e,$f8,$bb,$30,$9d,$06,$4e,$de,$0c,$28,$37,$57,$4e,$5d,$4b
	dc.b	$49,$55,$36,$14,$67,$28,$b5,$6d,$1b,$ca,$1a,$77,$b6,$af,$5f,$25
	dc.b	$d4,$f3,$2d,$d1,$b3,$4d,$3e,$80,$2f,$a1,$d4,$6b,$8e,$a0,$fa,$3e
	dc.b	$01,$a1,$8c,$23,$a3,$15,$d8,$7a,$e2,$c9,$76,$31,$4c,$35,$70,$81
	dc.b	$e9,$1e,$e6,$e9,$15,$30,$17,$1a,$a4,$1e,$13,$00,$f2,$1e,$a9,$72
	dc.b	$8a,$98,$d6,$20,$a2,$8f,$47,$c5,$ca,$3d,$0c,$b2,$a6,$29,$e4,$a3
	dc.b	$93,$59,$e4,$a3,$16,$60,$39,$4f,$55,$bf,$60,$71,$65,$d7,$df,$6b
	dc.b	$99,$06,$56,$91,$23,$1f,$58,$9a,$06,$51,$e6,$31,$67,$c0,$b2,$b3
	dc.b	$34,$d1,$80,$63,$57,$3e,$61,$ef,$9e,$03,$6f,$7f,$bc,$e2,$6a,$f1
	dc.b	$2c,$99,$4e,$06,$a9,$f4,$d8,$97,$cc,$9c,$3f,$c3,$fe,$75,$30,$79
	dc.b	$73,$ed,$17,$1f,$fb,$a0,$d3,$73,$16,$f9,$91,$ee,$2e,$48,$ab,$48
	dc.b	$ae,$a8,$8e,$ee,$a8,$ce,$d6,$d1,$89,$cc,$39,$cc,$cf,$5e,$d5,$03
	dc.b	$04,$1c,$9f,$70,$e5,$e4,$c6,$18,$76,$56,$68,$16,$eb,$10,$57,$a6
	dc.b	$a7,$6e,$7e,$dc,$d1,$46,$b3,$8f,$6e,$7c,$7e,$7b,$bb,$94,$fa,$30
	dc.b	$8e,$84,$c6,$2a,$e4,$3d,$6f,$73,$b5,$05,$a1,$17,$e2,$e2,$04,$9b
	dc.b	$9c,$48,$71,$fe,$8d,$cc,$49,$ae,$8c,$8a,$79,$a8,$fd,$f5,$32,$02
	dc.b	$e6,$6f,$3c,$25,$19,$fb,$5a,$09,$5d,$2d,$f6,$d8,$a3,$57,$9a,$d8
	dc.b	$e5,$0a,$53,$c0,$ca,$18,$c5,$1d,$9a,$44,$0f,$a6,$76,$f2,$82,$18
	dc.b	$76,$52,$76,$b7,$8c,$03,$2a,$e9,$8c,$c3,$29,$e5,$7c,$da,$6a,$0f
	dc.b	$37,$79,$d6,$85,$d1,$4d,$8a,$f2,$6a,$d6,$93,$b8,$fb,$7d,$d7,$ff
	dc.b	$3f,$ed,$6a,$d0,$64,$5d,$af,$c8,$4d,$cf,$50,$0b,$32,$87,$1d,$d0
	dc.b	$43,$3d,$b4,$51,$69,$67,$22,$18,$98,$4b,$92,$ed,$5c,$4c,$82,$6e
	dc.b	$fd,$10,$99,$50,$98,$29,$3b,$77,$11,$d0,$c1,$a1,$29,$3f,$50,$af
	dc.b	$bf,$f0,$1d,$6e,$8d,$9b,$47,$3d,$3c,$44,$d6,$d7,$3f,$68,$68,$9b
	dc.b	$a7,$56,$89,$a5,$ce,$9f,$5a,$6d,$1d,$d4,$8d,$9a,$c9,$01,$e9,$1a
	dc.b	$90,$f5,$b2,$db,$68,$03,$30,$87,$10,$23,$67,$63,$15,$e0,$b2,$a0
	dc.b	$dc,$f0,$15,$f3,$ba,$72,$c0,$ee,$5c,$c8,$e6,$60,$bc,$f5,$19,$27
	dc.b	$f5,$d1,$fd,$f0,$f8,$44,$c5,$25,$ad,$b9,$37,$ec,$ab,$81,$f7,$d1
	dc.b	$fb,$80,$a9,$39,$d2,$4c,$0c,$15,$e5,$05,$53,$6e,$52,$76,$e2,$bf
	dc.b	$78,$a8,$d1,$9e,$f6,$97,$ba,$94,$ad,$39,$d9,$06,$4a,$3e,$54,$4e
	dc.b	$e6,$0c,$e0,$c7,$9c,$b7,$46,$b7,$db,$0f,$8a,$d6,$9d,$b8,$6e,$fc
	dc.b	$dd,$d2,$f8,$39,$d5,$4a,$05,$db,$a0,$a6,$3a,$e8,$3b,$27,$39,$cc
	dc.b	$ba,$49,$49,$da,$27,$94,$85,$89,$ad,$f9,$da,$06,$0d,$f3,$bb,$e0
	dc.b	$67,$6e,$68,$0b,$ee,$6b,$2a,$cf,$c5,$a7,$28,$1f,$de,$86,$cb,$ca
	dc.b	$6d,$4d,$d1,$8f,$f1,$c4,$55,$d4,$af,$0f,$c1,$66,$30,$90,$3b,$c5
	dc.b	$07,$dc,$de,$32,$02,$b3,$26,$e0,$24,$f2,$1d,$0a,$49,$7f,$21,$ea
	dc.b	$d7,$d8,$e0,$31,$96,$57,$5e,$22,$4c,$6c,$1f,$75,$e2,$bd,$28,$77
	dc.b	$39,$ee,$8c,$56,$37,$ba,$28,$77,$3e,$8a,$2e,$64,$c7,$ab,$28,$fb
	dc.b	$9a,$b0,$94,$da,$dd,$be,$a6,$26,$5d,$36,$1c,$cf,$a2,$1e,$7a,$57
	dc.b	$56,$55,$e9,$8a,$3b,$03,$99,$21,$95,$28,$fd,$e1,$58,$bb,$a2,$50
	dc.b	$3c,$03,$06,$11,$68,$12,$07,$b1,$46,$c8,$33,$d6,$fd,$70,$3b,$bf
	dc.b	$4f,$f4,$f0,$7e,$ef,$03,$ba,$f4,$18,$26,$db,$93,$57,$ff,$9f,$1e
	dc.b	$ab,$5a,$5e,$7b,$7f,$d9,$97,$c6,$78,$30,$16,$50,$55,$74,$14,$cf
	dc.b	$ca,$8f,$2d,$a9,$ce,$64,$fd,$1e,$22,$a0,$fb,$98,$24,$4d,$6e,$1f
	dc.b	$08,$25,$99,$ca,$85,$88,$ab,$21,$1a,$24,$9c,$ab,$9b,$64,$12,$f4
	dc.b	$e0,$fb,$bc,$06,$dd,$42,$16,$9b,$a2,$4b,$15,$01,$ba,$05,$82,$30
	dc.b	$b9,$c8,$3a,$81,$d2,$e6,$56,$dd,$9f,$3c,$34,$f7,$20,$2a,$fd,$c1
	dc.b	$2b,$e8,$a4,$81,$a7,$5a,$32,$e4,$3d,$6b,$78,$b6,$80,$1c,$bd,$5b
	dc.b	$78,$86,$af,$32,$ff,$be,$7b,$3d,$06,$e8,$0e,$ba,$66,$e4,$ac,$ee
	dc.b	$62,$9e,$39,$29,$fd,$d4,$56,$cd,$5b,$75,$10,$3d,$ce,$26,$51,$e3
	dc.b	$9d,$b5,$26,$dd,$7e,$96,$5c,$94,$a3,$94,$52,$c1,$df,$4e,$90,$60
	dc.b	$38,$97,$e5,$3d,$7a,$0a,$4d,$95,$4d,$97,$d0,$54,$1d,$5d,$05,$49
	dc.b	$da,$72,$4e,$bb,$8a,$8f,$dd,$16,$5e,$00,$fc,$91,$7b,$06,$1a,$fa
	dc.b	$7e,$37,$f6,$35,$9d,$96,$15,$6b,$85,$7f,$8a,$fd,$dc,$55,$a0,$bc
	dc.b	$c6,$3f,$d1,$69,$cf,$f1,$47,$4f,$3b,$c5,$18,$3b,$13,$9c,$c4,$5c
	dc.b	$4c,$ad,$ab,$22,$ee,$e6,$41,$32,$59,$e2,$83,$24,$66,$4c,$2f,$35
	dc.b	$6c,$80,$d3,$00,$eb,$8e,$e3,$3c,$ab,$d8,$90,$0c,$fd,$43,$2f,$11
	dc.b	$d5,$ce,$d5,$42,$1b,$a4,$a7,$0c,$3e,$72,$06,$5a,$83,$94,$f7,$10
	dc.b	$3f,$9b,$7b,$03,$a2,$5c,$cc,$87,$6f,$0f,$ab,$3c,$0c,$bf,$39,$7a
	dc.b	$03,$dc,$71,$6d,$07,$33,$e6,$fb,$80,$4e,$52,$ce,$1e,$82,$ae,$05
	dc.b	$36,$50,$42,$76,$45,$d1,$93,$5a,$3d,$cc,$8b,$5b,$82,$7e,$ac,$96
	dc.b	$1b,$6e,$e7,$12,$26,$ef,$7f,$3a,$26,$09,$cc,$9f,$cd,$f6,$0d,$9e
	dc.b	$9b,$a0,$7c,$a3,$92,$87,$54,$79,$94,$55,$df,$ed,$d1,$18,$b5,$a3
	dc.b	$18,$74,$81,$83,$06,$dc,$de,$62,$99,$77,$3d,$a1,$38,$7e,$64,$6f
	dc.b	$b6,$8a,$ad,$7b,$60,$78,$7f,$8d,$8c,$13,$83,$c3,$cc,$75,$9d,$ab
	dc.b	$32,$4c,$6b,$59,$71,$b2,$bc,$8e,$9d,$b5,$94,$33,$56,$ce,$49,$98
	dc.b	$c5,$29,$db,$cb,$d1,$1b,$98,$5b,$63,$2e,$ab,$26,$a9,$cc,$51,$20
	dc.b	$cc,$b1,$2c,$19,$14,$51,$48,$bc,$cb,$f7,$44,$1c,$36,$a2,$bf,$da
	dc.b	$a6,$32,$09,$5f,$ec,$63,$ec,$8d,$86,$06,$52,$f6,$aa,$e8,$61,$02
	dc.b	$f6,$03,$89,$cf,$ca,$84,$fb,$4b,$9e,$79,$8a,$ab,$88,$5a,$48,$be
	dc.b	$b2,$1e,$7a,$4f,$14,$5d,$e9,$cb,$5f,$10,$1a,$c5,$b4,$27,$32,$73
	dc.b	$00,$b3,$7e,$63,$d7,$a4,$b3,$1b,$a0,$8e,$92,$01,$40,$74,$3e,$09
	dc.b	$9d,$8b,$3c,$ae,$5c,$36,$6c,$12,$26,$53,$1c,$26,$0c,$fd,$07,$b7
	dc.b	$b8,$a5,$47,$28,$80,$71,$52,$7d,$3c,$87,$a0,$c8,$46,$2d,$24,$a6
	dc.b	$2a,$58,$ca,$cf,$e4,$f5,$d9,$fa,$82,$dc,$6f,$bf,$6e,$8a,$a9,$bf
	dc.b	$d7,$14,$45,$9d,$08,$f4,$fd,$54,$38,$55,$9c,$a9,$ae,$40,$6b,$77
	dc.b	$67,$7a,$f1,$2b,$7f,$21,$ee,$6c,$18,$d6,$cd,$ef,$57,$32,$07,$a1
	dc.b	$81,$63,$35,$8c,$96,$ae,$5c,$d3,$98,$f3,$06,$49,$31,$95,$cf,$c5
	dc.b	$6e,$45,$be,$f6,$4c,$e8,$65,$39,$72,$7f,$5d,$9f,$c5,$3c,$0d,$90
	dc.b	$f9,$76,$eb,$51,$53,$46,$10,$c0,$4d,$5f,$bf,$c8,$7a,$93,$3d,$f1
	dc.b	$b4,$c3,$48,$d6,$95,$71,$79,$29,$1f,$66,$97,$7a,$a0,$0d,$7d,$39
	dc.b	$f6,$ca,$23,$17,$b5,$9c,$a1,$b3,$ca,$43,$fc,$6f,$77,$d8,$92,$f7
	dc.b	$92,$c2,$68,$03,$23,$a5,$25,$cd,$44,$89,$97,$4e,$cf,$3e,$70,$2a
	dc.b	$46,$cd,$13,$04,$ca,$0c,$e9,$1e,$78,$4b,$cd,$2b,$e0,$78,$50,$67
	dc.b	$98,$35,$d9,$a0,$f3,$d5,$02,$c0,$e9,$f0,$1e,$e2,$fe,$0a,$0c,$a2
	dc.b	$90,$d4,$17,$11,$bf,$a2,$e1,$5b,$63,$02,$c9,$96,$a9,$42,$86,$af
	dc.b	$ac,$4a,$87,$d3,$a2,$2f,$50,$3f,$0c,$b3,$b9,$4d,$13,$25,$68,$1e
	dc.b	$1d,$c2,$44,$ff,$88,$f9,$43,$db,$5d,$48,$e6,$1e,$89,$69,$b3,$0f
	dc.b	$a1,$a4,$f9,$8c,$84,$e1,$b0,$72,$54,$2a,$11,$5b,$ad,$58,$f1,$06
	dc.b	$2e,$e5,$e3,$b2,$ba,$94,$62,$f3,$8e,$cd,$30,$35,$5a,$b1,$93,$f7
	dc.b	$00,$cd,$1f,$04,$96,$15,$a5,$84,$8c,$2a,$12,$64,$d6,$19,$88,$af
	dc.b	$a5,$cf,$30,$ba,$a6,$dd,$82,$e4,$a9,$e0,$d5,$a1,$d0,$e2,$3b,$a5
	dc.b	$02,$82,$70,$32,$f1,$e9,$d4,$23,$54,$61,$0a,$6a,$8b,$ea,$1f,$19
	dc.b	$1e,$99,$0d,$ab,$a0,$b6,$53,$28,$fa,$0b,$fa,$99,$0b,$58,$b3,$a9
	dc.b	$90,$67,$50,$3b,$a6,$c4,$60,$ca,$ad,$71,$30,$b2,$38,$1e,$ea,$32
	dc.b	$a7,$2b,$a9,$04,$af,$71,$4a,$07,$52,$f4,$e9,$07,$de,$98,$d6,$56
	dc.b	$90,$df,$45,$0c,$97,$16,$18,$02,$d9,$ca,$7a,$40,$77,$ab,$da,$a7
	dc.b	$30,$33,$0b,$ef,$a9,$e5,$38,$4e,$9d,$a8,$b8,$13,$55,$30,$3f,$11
	dc.b	$33,$05,$35,$5b,$6f,$83,$e6,$19,$41,$5d,$d1,$14,$a0,$ef,$f6,$1c
	dc.b	$fe,$aa,$eb,$a1,$ba,$fe,$68,$3a,$42,$c6,$48,$2c,$fd,$12,$b5,$d2
	dc.b	$37,$0d,$36,$76,$93,$84,$69,$3d,$ab,$d3,$25,$5b,$65,$f5,$18,$49
	dc.b	$a1,$37,$06,$94,$25,$07,$03,$26,$0a,$d2,$de,$d7,$95,$26,$51,$ab
	dc.b	$fc,$cc,$52,$f4,$b9,$95,$af,$1d,$9e,$1a,$4b,$90,$53,$fc,$e0,$c9
	dc.b	$d6,$9b,$21,$aa,$0a,$3e,$ab,$af,$0c,$2b,$9d,$69,$b2,$16,$05,$de
	dc.b	$17,$e3,$48,$94,$b5,$6e,$86,$d2,$af,$1d,$5a,$94,$5e,$2b,$21,$f5
	dc.b	$7a,$2c,$e0,$7c,$93,$62,$e9,$b0,$19,$06,$06,$71,$d0,$f6,$3d,$4e
	dc.b	$f0,$08,$d9,$41,$0c,$96,$2c,$a0,$94,$55,$0d,$be,$14,$bd,$4d,$c8
	dc.b	$75,$d3,$18,$12,$e5,$34,$01,$43,$8d,$5b,$55,$47,$5b,$48,$1e,$39
	dc.b	$49,$33,$3d,$27,$97,$9d,$bd,$d4,$8a,$64,$17,$36,$58,$db,$98,$21
	dc.b	$65,$39,$c3,$13,$97,$ba,$b6,$fe,$a3,$cb,$68,$1e,$e8,$fe,$d1,$4f
	dc.b	$2b,$a1,$0d,$0b,$e2,$e6,$da,$7d,$5a,$8b,$ea,$18,$30,$49,$44,$66
	dc.b	$ab,$12,$f6,$bb,$27,$0b,$9b,$48,$a9,$08,$96,$e3,$73,$28,$70,$93
	dc.b	$14,$92,$c0,$d8,$15,$d7,$a0,$ea,$05,$89,$d5,$20,$64,$16,$c4,$6d
	dc.b	$9b,$42,$6e,$97,$32,$f1,$f5,$0a,$f2,$2c,$ae,$92,$75,$09,$a9,$07
	dc.b	$db,$20,$16,$fa,$97,$a5,$ba,$b9,$fc,$18,$1f,$6f,$5f,$35,$47,$8e
	dc.b	$04,$c9,$77,$8f,$fa,$47,$85,$72,$b1,$45,$89,$4a,$20,$75,$d1,$5d
	dc.b	$df,$db,$35,$13,$56,$7d,$9e,$43,$55,$b9,$8d,$ad,$26,$4f,$17,$2a
	dc.b	$78,$78,$de,$af,$73,$80,$c8,$ec,$8d,$00,$f5,$50,$fb,$50,$38,$67
	dc.b	$d4,$a8,$3f,$c3,$07,$e2,$07,$db,$67,$c9,$74,$44,$e0,$19,$34,$93
	dc.b	$aa,$61,$d3,$5a,$48,$4c,$b7,$d7,$bb,$0d,$92,$73,$9d,$ba,$71,$1c
	dc.b	$73,$a2,$e2,$6d,$d0,$c9,$1c,$5a,$a8,$5f,$e4,$4a,$5c,$04,$26,$39
	dc.b	$81,$c2,$18,$54,$e7,$52,$1b,$a5,$74,$cb,$43,$86,$b4,$a1,$99,$09
	dc.b	$72,$ef,$1e,$ec,$a5,$ab,$36,$54,$a2,$9c,$11,$93,$6d,$0e,$9e,$92
	dc.b	$3f,$f0,$88,$e7,$1b,$31,$94,$c8,$75,$66,$e1,$dc,$0c,$a1,$82,$d0
	dc.b	$bf,$6a,$49,$d2,$e4,$ec,$ce,$cb,$a1,$e1,$bb,$59,$8a,$26,$49,$0a
	dc.b	$b2,$13,$7a,$79,$e5,$ee,$5f,$73,$ee,$be,$cf,$47,$98,$a3,$fa,$47
	dc.b	$1b,$2d,$19,$17,$cd,$93,$b7,$5a,$b0,$88,$e0,$5c,$79,$29,$ed,$9b
	dc.b	$dc,$2d,$44,$e2,$6e,$9f,$c9,$54,$d6,$5a,$c2,$65,$36,$25,$8a,$09
	dc.b	$d5,$c3,$83,$83,$06,$db,$5e,$69,$7a,$a1,$54,$6a,$1b,$74,$f4,$aa
	dc.b	$6f,$fa,$a7,$c7,$e6,$2b,$a2,$4b,$0c,$6e,$aa,$74,$69,$80,$ed,$d4
	dc.b	$0a,$97,$7b,$47,$99,$f7,$05,$49,$b3,$31,$ae,$76,$d9,$ef,$3a,$d5
	dc.b	$22,$d1,$6c,$a6,$d0,$63,$5f,$da,$a0,$5d,$19,$35,$70,$16,$d6,$4c
	dc.b	$4a,$13,$99,$47,$21,$ba,$e9,$01,$31,$46,$a9,$1c,$90,$9f,$90,$53
	dc.b	$71,$90,$32,$27,$02,$63,$f5,$1e,$67,$dc,$1a,$de,$d9,$62,$ef,$1b
	dc.b	$46,$ec,$23,$77,$40,$5b,$81,$9e,$94,$80,$c7,$19,$9d,$4b,$99,$7e
	dc.b	$f1,$f1,$19,$6c,$80,$ba,$aa,$3d,$79,$92,$a3,$7b,$37,$f1,$f4,$7a
	dc.b	$5d,$ec,$95,$12,$be,$1a,$dc,$a0,$f3,$70,$72,$72,$fe,$90,$aa,$f8
	dc.b	$c8,$6e,$37,$50,$89,$a6,$d6,$4d,$dd,$ed,$b2,$fc,$c2,$b5,$d3,$69
	dc.b	$6d,$07,$47,$e6,$c5,$cc,$b4,$1b,$56,$d9,$44,$ba,$23,$16,$89,$df
	dc.b	$5d,$8f,$8c,$ab,$af,$7d,$e3,$62,$7e,$85,$74,$4b,$5a,$f3,$10,$fd
	dc.b	$7d,$30,$1d,$9e,$c0,$bf,$70,$ec,$13,$a4,$5e,$e2,$5f,$9d,$ab,$0a
	dc.b	$c1,$1b,$b5,$90,$ac,$a9,$b0,$4e,$a6,$a5,$26,$03,$a9,$5d,$11,$ba
	dc.b	$8b,$08,$e4,$37,$40,$c4,$a5,$1b,$a1,$5a,$4c,$e0,$c1,$f7,$dc,$07
	dc.b	$66,$b8,$16,$d0,$e5,$55,$80,$20,$f0,$17,$b1,$b6,$c6,$40,$be,$ac
	dc.b	$2a,$66,$83,$18,$76,$a5,$cc,$b3,$75,$ab,$c9,$f6,$b9,$01,$0a,$4c
	dc.b	$c0,$74,$61,$06,$4a,$8e,$df,$13,$86,$a4,$67,$7d,$25,$46,$68,$31
	dc.b	$ff,$91,$b8,$87,$79,$39,$7a,$bd,$68,$b7,$e3,$28,$ba,$8b,$69,$f9
	dc.b	$ea,$5d,$8c,$3f,$d6,$99,$d4,$f7,$a5,$16,$9f,$60,$50,$96,$0b,$26
	dc.b	$fb,$b6,$ad,$b3,$da,$a4,$00,$d5,$44,$2c,$52,$78,$6b,$9c,$62,$66
	dc.b	$52,$5a,$2a,$82,$9a,$6d,$c2,$d8,$90,$f3,$01,$d8,$2e,$04,$f3,$c2
	dc.b	$22,$8f,$a8,$92,$33,$72,$77,$50,$51,$d3,$66,$c1,$74,$4e,$7f,$3c
	dc.b	$ab,$db,$c6,$a2,$ca,$a8,$f5,$c9,$03,$75,$27,$d5,$1a,$6a,$65,$b2
	dc.b	$36,$0c,$18,$4b,$ed,$c1,$35,$c2,$17,$1f,$c0,$ba,$13,$f5,$2b,$86
	dc.b	$d0,$cb,$90,$7a,$74,$54,$15,$8b,$d5,$06,$45,$38,$8e,$8b,$56,$fa
	dc.b	$5c,$9d,$90,$83,$a3,$f7,$df,$28,$02,$86,$85,$17,$85,$97,$98,$f3
	dc.b	$17,$59,$2f,$13,$14,$91,$b4,$2a,$8d,$6c,$9a,$c9,$3c,$47,$93,$68
	dc.b	$39,$2c,$24,$c2,$4f,$7d,$41,$1f,$19,$6b,$06,$47,$4d,$13,$54,$8f
	dc.b	$73,$9e,$e9,$35,$05,$03,$0a,$c4,$77,$0e,$c1,$d1,$d2,$54,$a4,$42
	dc.b	$c5,$87,$1a,$5b,$8c,$4c,$59,$dc,$2a,$c3,$32,$aa,$36,$4c,$f0,$ef
	dc.b	$30,$cb,$73,$02,$79,$e6,$90,$7d,$10,$8a,$2c,$60,$d0,$d7,$5a,$54
	dc.b	$e4,$9b,$05,$d1,$6b,$0e,$4f,$a9,$8a,$ba,$60,$05,$70,$4a,$86,$02
	dc.b	$f5,$24,$32,$ad,$d0,$7e,$96,$c8,$d5,$8e,$92,$3a,$09,$5c,$32,$93
	dc.b	$f0,$26,$5c,$b7,$20,$96,$b6,$19,$79,$40,$4a,$d1,$d7,$01,$09,$68
	dc.b	$8d,$58,$60,$27,$cf,$4b,$91,$b1,$bf,$5a,$b9,$4e,$37,$d9,$c8,$d7
	dc.b	$3d,$17,$e2,$c9,$95,$a0,$9c,$4a,$6e,$26,$75,$f2,$a5,$d3,$4d,$74
	dc.b	$64,$c7,$0e,$b4,$92,$eb,$26,$da,$bc,$20,$c8,$11,$ef,$a8,$20,$34
	dc.b	$ce,$59,$8e,$f7,$26,$7a,$2e,$4d,$bc,$67,$6c,$d0,$c8,$59,$f6,$26
	dc.b	$60,$76,$fc,$1d,$74,$e4,$99,$48,$1d,$15,$58,$cb,$12,$9b,$c8,$47
	dc.b	$02,$68,$2e,$8d,$41,$69,$03,$dc,$c0,$ce,$6c,$0b,$34,$4d,$25,$6a
	dc.b	$2d,$9c,$8c,$80,$c8,$39,$06,$03,$41,$72,$6a,$56,$93,$53,$ad,$da
	dc.b	$02,$32,$40,$a9,$4d,$72,$cd,$bb,$04,$d9,$6d,$57,$6c,$ce,$9b,$75
	dc.b	$4d,$a8,$d4,$eb,$35,$ab,$45,$a7,$2b,$9a,$d2,$ed,$b7,$3d,$29,$6c
	dc.b	$ca,$93,$55,$ae,$da,$f1,$3a,$3d,$66,$c7,$a3,$d5,$eb,$76,$c0,$f2
	dc.b	$ea,$2d,$32,$a5,$64,$b9,$61,$72,$39,$3c,$de,$bb,$6b,$2c,$9b,$52
	dc.b	$ed,$b8,$ad,$0e,$af,$6f,$c9,$e5,$77,$68,$db,$2d,$ec,$aa,$85,$62
	dc.b	$b6,$5d,$71,$78,$dc,$76,$77,$3d,$aa,$e2,$f3,$7a,$60,$5a,$75,$7a
	dc.b	$e7,$7a,$ca,$67,$36,$7c,$6e,$5f,$6b,$db,$2b,$a2,$56,$ef,$3a,$2e
	dc.b	$77,$97,$d5,$25,$a4,$55,$ec,$77,$1b,$a6,$9e,$ad,$67,$b7,$65,$b9
	dc.b	$9d,$40,$34,$5a,$69,$35,$f2,$7a,$7d,$75,$4c,$bf,$5e,$87,$61,$c4
	dc.b	$66,$3c,$d2,$89,$d5,$1f,$85,$6f,$c1,$61,$35,$fd,$cf,$14,$4a,$29
	dc.b	$8c,$ec,$77,$a6,$74,$1a,$c6,$1b,$71,$f2,$d8,$71,$3d,$d1,$19,$24
	dc.b	$e6,$fb,$c8,$8a,$c6,$a3,$72,$3f,$64,$4e,$63,$4f,$a8,$01,$24,$5f
	dc.b	$59,$0c,$ef,$51,$7b,$fa,$46,$72,$1d,$9f,$b4,$df,$0f,$0a,$bc,$4b
	dc.b	$f7,$d3,$dc,$1c,$f2,$ef,$bc,$f4,$45,$ef,$d8,$fe,$3f,$c6,$3b,$e3
	dc.b	$e1,$c7,$38,$3e,$1f,$9c,$fa,$f9,$5f,$e7,$c3,$7a,$00,$3d,$06,$06
	dc.b	$13,$0b,$f3,$c7,$bf,$3f,$a9,$c6,$7e,$0b,$70,$87,$46,$21,$9f,$b9
	dc.b	$84,$12,$11,$ef,$b0,$49,$fb,$f2,$08,$30,$0b,$ef,$10,$df,$d0,$23
	dc.b	$e0,$0f,$c4,$ff,$e1,$02,$fe,$c3,$e0,$f7,$ff,$e7,$82,$07,$80,$e0
	dc.b	$00,$7f,$d0,$1f,$fc,$00,$04,$07,$06,$0e,$09,$03,$a1,$b2,$27,$88
	dc.b	$10,$ec,$57,$f9,$ff,$53,$21,$89,$d6,$c2,$e8,$53,$3f,$de,$1c,$e2
	dc.b	$ba,$de,$bb,$94,$26,$b3,$31,$93,$f3,$45,$87,$58,$b4,$d8,$a9,$e3
	dc.b	$d7,$b8,$0e,$a9,$12,$fe,$85,$74,$97,$c7,$81,$c4,$23,$e9,$f5,$43
	dc.b	$39,$a1,$63,$36,$09,$da,$ee,$00,$5c,$58,$80,$60,$30,$88,$64,$62
	dc.b	$35,$20,$90,$ca,$25,$33,$89,$f5,$e3,$7f,$c7,$ea,$75,$fb,$3e,$4f
	dc.b	$67,$df,$f1,$fb,$8f,$cf,$ea,$18,$0f,$07,$9f,$f5,$fc,$fe,$c1,$60
	dc.b	$ff,$e8,$25,$ff,$ff,$00,$28,$61,$40,$47,$28,$61,$00,$00
g2embed_gloombrush_end

	even
; -----------------------------------------------------------------------------
; v190hu embedded Zombie Massacre title overlay assets
; -----------------------------------------------------------------------------

	even
g2embed_zm_titlebrush
	dc.b	$01,$40,$00,$46,$00,$07,$00,$00,$00,$00,$00,$00,$f9,$00,$02,$09
	dc.b	$0c,$01,$fe,$00,$02,$3f,$81,$c0,$fb,$00,$06,$03,$e0,$40,$09,$f1
	dc.b	$83,$c0,$f7,$00,$f9,$00,$08,$09,$0c,$01,$00,$1f,$8c,$3f,$ff,$f0
	dc.b	$fb,$00,$07,$0f,$e0,$40,$08,$b1,$83,$c0,$64,$f8,$00,$f9,$00,$08
	dc.b	$09,$0c,$01,$00,$1f,$8c,$3e,$7e,$30,$fb,$00,$07,$0c,$20,$ff,$f7
	dc.b	$48,$00,$40,$60,$f8,$00,$f9,$00,$08,$09,$0c,$01,$00,$00,$02,$3f
	dc.b	$ff,$f0,$fb,$00,$07,$0f,$e8,$bf,$f6,$0e,$7c,$3f,$80,$f8,$00,$f9
	dc.b	$00,$08,$06,$f3,$fe,$ff,$e0,$71,$c1,$81,$c0,$fb,$00,$07,$03,$d7
	dc.b	$00,$09,$f1,$83,$80,$1f,$f8,$00,$d9,$00,$d9,$00,$f9,$00,$02,$06
	dc.b	$18,$02,$fe,$00,$02,$7f,$03,$80,$fb,$00,$06,$0f,$c0,$80,$00,$20
	dc.b	$23,$80,$f7,$00,$f9,$00,$08,$06,$18,$02,$00,$3f,$04,$7f,$ff,$e0
	dc.b	$fb,$00,$07,$0f,$c0,$c0,$00,$20,$23,$c0,$e0,$f8,$00,$f9,$00,$08
	dc.b	$06,$18,$02,$00,$33,$04,$7c,$fc,$60,$f9,$00,$05,$bf,$ff,$d8,$01
	dc.b	$80,$e0,$f8,$00,$f9,$00,$08,$06,$18,$02,$00,$00,$08,$7f,$ff,$e0
	dc.b	$fb,$00,$06,$0f,$d1,$3f,$ff,$df,$dc,$3f,$f7,$00,$f9,$00,$08,$01
	dc.b	$e7,$fd,$ff,$cc,$f3,$83,$03,$80,$fb,$00,$07,$0f,$ee,$40,$00,$20
	dc.b	$22,$40,$1e,$f8,$00,$d9,$00,$d9,$00,$f9,$00,$02,$03,$f4,$04,$fe
	dc.b	$00,$01,$7c,$07,$fa,$00,$08,$0f,$b0,$10,$00,$06,$23,$00,$00,$c0
	dc.b	$f9,$00,$f9,$00,$08,$03,$f4,$04,$00,$2e,$10,$7f,$ff,$e0,$fb,$00
	dc.b	$08,$0f,$b0,$90,$00,$06,$23,$01,$e0,$c0,$f9,$00,$f9,$00,$08,$03
	dc.b	$f4,$04,$00,$26,$10,$7b,$f8,$e0,$fa,$00,$07,$30,$1f,$ff,$f0,$0b
	dc.b	$01,$e0,$c0,$f9,$00,$f9,$00,$08,$03,$f4,$04,$00,$00,$0c,$7f,$ff
	dc.b	$e0,$fb,$00,$08,$0f,$b1,$6f,$ff,$f9,$dc,$fe,$00,$c0,$f9,$00,$f8
	dc.b	$00,$06,$0b,$fb,$ff,$d9,$e3,$84,$07,$fa,$00,$07,$0f,$ce,$80,$00
	dc.b	$06,$20,$00,$1e,$f8,$00,$d9,$00,$d9,$00,$f9,$00,$07,$01,$fc,$0f
	dc.b	$e0,$00,$00,$79,$1f,$fa,$00,$08,$0f,$f0,$20,$06,$89,$7c,$40,$01
	dc.b	$80,$f9,$00,$f9,$00,$08,$01,$fc,$0f,$e0,$3c,$20,$7f,$ff,$c0,$fb
	dc.b	$00,$08,$0f,$f3,$3c,$00,$89,$7c,$41,$e7,$e0,$f9,$00,$f9,$00,$08
	dc.b	$01,$fc,$0f,$e0,$2c,$20,$7e,$e0,$c0,$fa,$00,$07,$30,$3e,$7f,$71
	dc.b	$7c,$41,$e7,$e0,$f9,$00,$f9,$00,$08,$01,$fc,$0f,$e0,$00,$10,$7f
	dc.b	$ff,$c0,$fb,$00,$08,$0f,$f0,$c3,$f9,$76,$83,$be,$01,$e0,$f9,$00
	dc.b	$f8,$00,$06,$03,$f0,$1f,$d3,$cf,$81,$1f,$fa,$00,$07,$0f,$cf,$00
	dc.b	$06,$88,$00,$00,$18,$f8,$00,$d9,$00,$d9,$00,$f9,$00,$07,$01,$fc
	dc.b	$0f,$80,$00,$70,$76,$3c,$fa,$00,$06,$9f,$f8,$00,$04,$00,$fe,$c0
	dc.b	$f7,$00,$f9,$00,$08,$01,$fc,$0f,$80,$40,$70,$7f,$ff,$80,$fb,$00
	dc.b	$08,$9f,$fa,$38,$00,$00,$fe,$c3,$c2,$70,$f9,$00,$f9,$00,$08,$01
	dc.b	$fc,$0f,$80,$40,$70,$79,$c3,$80,$fb,$00,$08,$d0,$78,$3c,$f7,$f0
	dc.b	$7e,$c3,$c2,$70,$f9,$00,$f9,$00,$0b,$01,$fc,$0f,$80,$00,$70,$7f
	dc.b	$ff,$80,$00,$00,$02,$fe,$00,$08,$5f,$f9,$c7,$fb,$ff,$01,$3c,$00
	dc.b	$70,$f9,$00,$f8,$00,$06,$03,$f0,$7f,$bf,$8f,$86,$3c,$fa,$00,$07
	dc.b	$8f,$86,$00,$04,$00,$80,$00,$3c,$f8,$00,$d9,$00,$d9,$00,$f9,$00
	dc.b	$07,$01,$fe,$1f,$c0,$00,$40,$7e,$70,$fe,$00,$0c,$06,$00,$00,$01
	dc.b	$9f,$f8,$04,$78,$04,$bf,$80,$01,$80,$f9,$00,$f9,$00,$07,$01,$fe
	dc.b	$1f,$c0,$f0,$40,$ff,$ff,$fb,$00,$09,$01,$4f,$f8,$74,$78,$04,$bf
	dc.b	$87,$c5,$e0,$f9,$00,$f9,$00,$07,$01,$fe,$1f,$c0,$f0,$40,$f1,$8f
	dc.b	$fe,$00,$0c,$0f,$00,$00,$01,$d0,$f8,$74,$87,$f4,$be,$87,$c5,$60
	dc.b	$f9,$00,$f9,$00,$07,$01,$fe,$1f,$c0,$00,$40,$7f,$ff,$fe,$00,$0c
	dc.b	$02,$00,$00,$01,$af,$f9,$8b,$87,$fb,$40,$78,$01,$e0,$f9,$00,$f8
	dc.b	$00,$06,$01,$e0,$3f,$0f,$bf,$0e,$70,$fe,$00,$00,$09,$fe,$00,$08
	dc.b	$0f,$06,$00,$78,$00,$01,$00,$38,$80,$f9,$00,$ee,$00,$00,$0c,$fe
	dc.b	$00,$00,$50,$f1,$00,$d9,$00,$f9,$00,$07,$01,$fe,$7f,$e0,$00,$00
	dc.b	$7e,$f0,$fe,$00,$0c,$0e,$00,$00,$01,$ff,$fb,$00,$40,$31,$ff,$00
	dc.b	$03,$80,$f9,$00,$f9,$00,$07,$01,$fe,$7f,$e1,$30,$00,$7f,$ff,$fe
	dc.b	$00,$00,$09,$fe,$00,$08,$0f,$fb,$40,$40,$31,$ff,$07,$ff,$e0,$f9
	dc.b	$00,$f9,$00,$07,$01,$fe,$7f,$e1,$30,$00,$71,$0f,$fe,$00,$00,$0f
	dc.b	$fe,$00,$08,$f8,$fb,$41,$8f,$c1,$bf,$07,$ff,$e0,$f9,$00,$f9,$00
	dc.b	$07,$01,$fe,$7f,$e0,$00,$00,$7f,$ff,$fe,$00,$0c,$06,$00,$00,$01
	dc.b	$ff,$fb,$bf,$bf,$ce,$00,$f8,$03,$e0,$f9,$00,$f8,$00,$06,$01,$80
	dc.b	$1e,$cf,$ff,$8e,$f0,$fb,$00,$06,$01,$07,$04,$00,$40,$30,$40,$f6
	dc.b	$00,$ee,$00,$00,$09,$ed,$00,$d9,$00,$f9,$00,$16,$01,$ff,$e5,$c0
	dc.b	$01,$00,$7d,$f0,$00,$20,$00,$08,$80,$00,$02,$f6,$ff,$00,$28,$13
	dc.b	$fe,$00,$03,$f8,$00,$f9,$00,$17,$01,$ff,$e5,$c0,$41,$00,$7f,$fe
	dc.b	$00,$20,$00,$07,$80,$00,$03,$09,$ff,$00,$28,$13,$fe,$8f,$9b,$e0
	dc.b	$f9,$00,$f9,$00,$17,$01,$ff,$e5,$c0,$41,$00,$72,$0e,$00,$f0,$00
	dc.b	$0b,$b0,$00,$02,$ff,$ff,$01,$37,$f3,$7a,$0f,$9b,$e0,$f9,$00,$f9
	dc.b	$00,$17,$01,$ff,$e5,$c0,$01,$00,$7f,$fe,$00,$20,$00,$1c,$78,$00
	dc.b	$03,$f3,$ff,$3d,$d7,$ec,$01,$70,$03,$e0,$f9,$00,$f7,$00,$14,$1a
	dc.b	$3f,$be,$ff,$8d,$f0,$00,$d8,$00,$04,$84,$00,$01,$06,$00,$c2,$08
	dc.b	$00,$84,$80,$60,$f8,$00,$f0,$00,$02,$80,$00,$03,$fe,$00,$00,$08
	dc.b	$f1,$00,$d9,$00,$f8,$00,$15,$ff,$c9,$c0,$00,$00,$7f,$c8,$00,$f0
	dc.b	$00,$1b,$fa,$00,$01,$3d,$ff,$00,$00,$37,$d0,$00,$03,$f8,$00,$f8
	dc.b	$00,$16,$ff,$c9,$c0,$00,$00,$7f,$fe,$00,$a0,$00,$14,$06,$00,$01
	dc.b	$c2,$ff,$00,$00,$37,$d1,$9f,$1f,$c0,$f9,$00,$f8,$00,$16,$ff,$c9
	dc.b	$c0,$00,$00,$70,$36,$00,$f8,$00,$1b,$fa,$00,$01,$bd,$ff,$00,$3f
	dc.b	$c6,$d0,$1f,$1f,$c0,$f9,$00,$f8,$00,$16,$ff,$c9,$c0,$00,$00,$7f
	dc.b	$fe,$00,$d8,$00,$0f,$fd,$00,$00,$7f,$ff,$3b,$ff,$c8,$2e,$60,$03
	dc.b	$c0,$f9,$00,$f7,$00,$05,$36,$3f,$ff,$ff,$8f,$c8,$fe,$00,$0b,$04
	dc.b	$04,$00,$02,$43,$00,$c4,$00,$31,$01,$80,$60,$f8,$00,$f0,$00,$06
	dc.b	$20,$00,$10,$02,$00,$01,$80,$f1,$00,$d9,$00,$f8,$00,$15,$3f,$93
	dc.b	$c0,$00,$00,$ff,$e8,$00,$f0,$00,$1f,$df,$80,$03,$d2,$fe,$00,$0c
	dc.b	$2f,$10,$00,$02,$f8,$00,$f8,$00,$16,$3f,$93,$c0,$10,$00,$ff,$fe
	dc.b	$00,$80,$00,$00,$40,$00,$02,$af,$fe,$36,$0c,$2f,$12,$1e,$03,$c0
	dc.b	$f9,$00,$f8,$00,$16,$3f,$93,$c0,$10,$00,$f8,$16,$00,$e0,$00,$0f
	dc.b	$cf,$c0,$03,$ff,$de,$06,$1f,$cc,$00,$1e,$03,$c0,$f9,$00,$f8,$00
	dc.b	$16,$3f,$93,$c0,$00,$00,$ff,$fe,$00,$f0,$00,$1f,$9f,$00,$00,$01
	dc.b	$fe,$41,$f3,$d0,$ed,$e0,$03,$c0,$f9,$00,$f7,$00,$14,$6c,$3f,$ef
	dc.b	$ff,$07,$e8,$00,$18,$00,$10,$30,$40,$04,$00,$21,$b8,$00,$23,$12
	dc.b	$00,$e0,$f8,$00,$ed,$00,$03,$40,$c0,$03,$fe,$f1,$00,$d9,$00,$f8
	dc.b	$00,$14,$1f,$07,$f0,$00,$01,$ff,$f0,$80,$70,$00,$07,$cf,$80,$0f
	dc.b	$61,$5c,$00,$18,$7e,$00,$0c,$f7,$00,$f8,$00,$16,$1f,$07,$f0,$10
	dc.b	$01,$ff,$fe,$80,$00,$30,$08,$08,$40,$08,$9f,$3c,$6c,$18,$7e,$04
	dc.b	$33,$03,$c0,$f9,$00,$f8,$00,$16,$1f,$07,$f0,$10,$01,$f0,$0e,$80
	dc.b	$38,$30,$1f,$cb,$a0,$0f,$63,$dc,$0c,$1f,$8e,$00,$0f,$03,$c0,$f9
	dc.b	$00,$f8,$00,$16,$1f,$07,$f0,$00,$01,$ff,$ff,$00,$70,$00,$17,$8f
	dc.b	$c0,$08,$fc,$1c,$03,$e7,$81,$fb,$c0,$03,$c0,$f9,$00,$f7,$00,$14
	dc.b	$f8,$0f,$ef,$fe,$0f,$f0,$c0,$48,$00,$00,$04,$60,$00,$9d,$63,$f0
	dc.b	$00,$70,$04,$30,$c0,$f8,$00,$f0,$00,$07,$08,$00,$08,$40,$20,$07
	dc.b	$02,$80,$f2,$00,$d9,$00,$f8,$00,$15,$0f,$0f,$fc,$01,$61,$ff,$e0
	dc.b	$00,$18,$18,$13,$c3,$e0,$11,$ff,$f3,$00,$19,$dc,$00,$08,$04,$f8
	dc.b	$00,$f8,$00,$16,$0f,$0f,$fc,$01,$61,$ff,$ff,$e0,$40,$20,$0c,$00
	dc.b	$00,$36,$00,$07,$49,$19,$dc,$00,$77,$07,$80,$f9,$00,$f8,$00,$16
	dc.b	$0f,$0f,$fc,$01,$61,$e0,$1f,$60,$70,$10,$3b,$e1,$e1,$f5,$ff,$fb
	dc.b	$09,$1e,$1c,$00,$1f,$07,$80,$f9,$00,$f8,$00,$16,$0f,$0f,$fc,$01
	dc.b	$61,$ff,$fc,$80,$98,$38,$27,$c3,$c0,$9b,$ff,$f3,$06,$e6,$23,$ff
	dc.b	$80,$07,$80,$f9,$00,$f7,$00,$13,$f0,$03,$fe,$9e,$1f,$e0,$80,$28
	dc.b	$28,$04,$22,$01,$42,$00,$04,$f0,$01,$c0,$00,$60,$f7,$00,$f2,$00
	dc.b	$09,$01,$40,$40,$00,$18,$00,$21,$44,$00,$08,$f2,$00,$d9,$00,$f8
	dc.b	$00,$15,$0e,$8f,$fc,$02,$43,$ff,$e3,$a0,$88,$30,$3f,$e1,$e3,$5f
	dc.b	$93,$5c,$00,$39,$b8,$00,$30,$18,$f8,$00,$f8,$00,$08,$0e,$8f,$fc
	dc.b	$02,$43,$ff,$f8,$41,$10,$fe,$00,$0a,$02,$b8,$6b,$c3,$03,$b9,$b8
	dc.b	$01,$8e,$1f,$80,$f9,$00,$f8,$00,$16,$0e,$8f,$fc,$02,$43,$c0,$1b
	dc.b	$81,$d8,$70,$3f,$f1,$e2,$bf,$98,$1e,$03,$be,$38,$01,$3e,$1f,$80
	dc.b	$f9,$00,$f8,$00,$16,$0e,$8f,$fc,$02,$43,$ff,$f9,$f0,$8c,$78,$1f
	dc.b	$e1,$e3,$4f,$f4,$2c,$08,$46,$47,$fe,$40,$1f,$80,$f9,$00,$f8,$00
	dc.b	$14,$01,$70,$03,$fd,$bc,$3f,$e0,$60,$40,$00,$00,$12,$11,$50,$63
	dc.b	$e1,$f4,$01,$80,$00,$80,$f7,$00,$f2,$00,$00,$02,$fe,$00,$05,$20
	dc.b	$10,$00,$a0,$08,$32,$f2,$00,$d9,$00,$f8,$00,$15,$0c,$03,$f8,$04
	dc.b	$03,$ff,$eb,$a9,$8c,$74,$2f,$e1,$e1,$f2,$70,$73,$00,$31,$38,$c0
	dc.b	$60,$08,$f8,$00,$f8,$00,$0a,$0c,$03,$f8,$04,$03,$ff,$f8,$58,$00
	dc.b	$0c,$10,$fe,$00,$07,$89,$f0,$1f,$31,$38,$c7,$8e,$0f,$f8,$00,$f8
	dc.b	$00,$15,$0c,$03,$f8,$04,$03,$80,$1b,$b9,$84,$7c,$2f,$e3,$e1,$f9
	dc.b	$71,$93,$9f,$3e,$f8,$c4,$6e,$0f,$f8,$00,$f8,$00,$15,$0c,$03,$f8
	dc.b	$04,$03,$ff,$ff,$e9,$0c,$64,$1f,$f3,$f3,$f2,$f9,$f7,$80,$ce,$c7
	dc.b	$38,$00,$0f,$f8,$00,$f8,$00,$14,$03,$fc,$07,$fb,$fc,$7f,$e0,$40
	dc.b	$0a,$00,$10,$00,$00,$0f,$88,$6c,$60,$01,$00,$03,$80,$f7,$00,$f1
	dc.b	$00,$08,$10,$80,$10,$20,$00,$00,$08,$00,$04,$f2,$00,$d9,$00,$f8
	dc.b	$00,$15,$0f,$9f,$f0,$00,$03,$ff,$97,$f1,$04,$e0,$37,$f3,$e1,$f0
	dc.b	$f8,$f9,$c0,$20,$60,$00,$40,$18,$f8,$00,$f8,$00,$0b,$0f,$9f,$f0
	dc.b	$00,$03,$ff,$c4,$00,$02,$98,$08,$12,$fe,$00,$06,$f8,$7e,$20,$60
	dc.b	$0f,$bc,$1f,$f8,$00,$f8,$00,$15,$0f,$9f,$f0,$00,$03,$00,$37,$fb
	dc.b	$84,$f0,$37,$f3,$e1,$f8,$70,$39,$fe,$3f,$e0,$0e,$7c,$1f,$f8,$00
	dc.b	$f8,$00,$15,$0f,$9f,$f0,$00,$03,$ff,$8b,$f9,$06,$e8,$3f,$e1,$c1
	dc.b	$f8,$f8,$fa,$c1,$df,$9f,$f0,$00,$1f,$f8,$00,$f7,$00,$0e,$60,$0f
	dc.b	$ff,$fc,$ff,$c0,$02,$82,$0c,$48,$12,$02,$00,$88,$c4,$fe,$00,$01
	dc.b	$01,$80,$f7,$00,$f2,$00,$0a,$34,$00,$80,$10,$00,$00,$20,$00,$00
	dc.b	$01,$40,$f3,$00,$d9,$00,$f8,$00,$15,$0f,$ff,$f8,$00,$03,$fc,$7f
	dc.b	$f7,$02,$4c,$3f,$f3,$e1,$f8,$61,$38,$60,$08,$60,$01,$00,$10,$f8
	dc.b	$00,$f8,$00,$15,$0f,$ff,$f8,$00,$03,$fe,$98,$15,$01,$04,$40,$14
	dc.b	$21,$08,$91,$f8,$1c,$48,$60,$3e,$ba,$1e,$f8,$00,$f8,$00,$15,$0f
	dc.b	$ff,$f8,$00,$02,$e1,$ff,$f7,$07,$cc,$77,$f7,$e1,$f8,$e1,$b8,$4c
	dc.b	$47,$f0,$39,$ba,$1e,$f8,$00,$f8,$00,$15,$0f,$ff,$f8,$00,$03,$fc
	dc.b	$67,$e6,$06,$58,$2f,$f3,$e0,$f0,$79,$38,$e3,$b7,$9f,$c0,$00,$1e
	dc.b	$f8,$00,$f6,$00,$08,$07,$ff,$fd,$1e,$18,$01,$00,$a4,$08,$fe,$00
	dc.b	$05,$10,$c7,$b0,$08,$00,$06,$f6,$00,$f3,$00,$0b,$01,$80,$10,$00
	dc.b	$00,$50,$00,$01,$08,$00,$80,$80,$f3,$00,$d9,$00,$f8,$00,$15,$1f
	dc.b	$ff,$f8,$00,$06,$7f,$ce,$87,$0f,$4c,$c7,$e3,$81,$f8,$cb,$01,$30
	dc.b	$10,$f0,$00,$00,$20,$f8,$00,$f8,$00,$15,$1f,$ff,$f8,$00,$07,$50
	dc.b	$01,$21,$0c,$88,$88,$2c,$01,$08,$ba,$e0,$d0,$10,$f0,$77,$7e,$3c
	dc.b	$f8,$00,$f8,$00,$15,$1f,$ff,$f8,$00,$06,$47,$fe,$67,$03,$4e,$cf
	dc.b	$eb,$81,$f8,$ff,$a1,$e0,$1f,$f0,$70,$7e,$3c,$f8,$00,$f8,$00,$15
	dc.b	$1f,$ff,$f8,$00,$06,$4b,$ff,$c7,$0e,$84,$67,$a7,$c1,$f0,$80,$41
	dc.b	$0f,$ef,$0f,$88,$00,$3c,$f8,$00,$f6,$00,$11,$07,$ff,$f9,$b8,$01
	dc.b	$80,$0c,$8a,$00,$04,$00,$08,$0c,$5f,$30,$00,$00,$07,$f6,$00,$f3
	dc.b	$00,$0a,$0c,$00,$00,$01,$40,$80,$40,$00,$00,$73,$80,$f2,$00,$d9
	dc.b	$00,$f8,$00,$15,$2f,$fb,$7c,$00,$0a,$ef,$df,$0f,$7c,$f5,$ff,$d3
	dc.b	$81,$fb,$7e,$43,$00,$00,$f8,$08,$00,$40,$f8,$00,$f8,$00,$15,$3f
	dc.b	$fb,$7c,$00,$09,$90,$41,$09,$fb,$7a,$30,$1c,$71,$0a,$01,$e0,$61
	dc.b	$00,$f8,$76,$fc,$7c,$f8,$00,$f8,$00,$15,$3f,$fb,$7c,$00,$0a,$ef
	dc.b	$df,$0f,$80,$8d,$c7,$93,$f1,$fa,$ff,$43,$01,$1f,$d8,$78,$fc,$7c
	dc.b	$f8,$00,$f8,$00,$15,$3f,$fb,$7c,$00,$09,$1e,$5d,$07,$fb,$ba,$bf
	dc.b	$9f,$71,$f9,$80,$83,$9e,$ff,$07,$81,$00,$7c,$f8,$00,$f7,$00,$12
	dc.b	$04,$83,$ff,$f5,$50,$80,$00,$7f,$76,$78,$4c,$80,$01,$00,$bf,$60
	dc.b	$00,$20,$06,$f6,$00,$f4,$00,$0b,$02,$a1,$02,$08,$00,$01,$08,$00
	dc.b	$00,$02,$7f,$40,$f2,$00,$d9,$00,$f8,$00,$15,$0f,$e0,$f8,$02,$04
	dc.b	$76,$1c,$0f,$fb,$fd,$bb,$f7,$00,$73,$e3,$c6,$00,$20,$60,$c0,$00
	dc.b	$c0,$f8,$00,$f8,$00,$15,$7f,$e0,$f8,$02,$03,$89,$24,$01,$70,$3a
	dc.b	$34,$69,$f0,$82,$1c,$00,$40,$20,$60,$3c,$f8,$f8,$f8,$00,$f8,$00
	dc.b	$15,$7f,$e0,$f8,$02,$01,$75,$3c,$1f,$07,$c7,$8b,$97,$f0,$73,$f3
	dc.b	$c6,$00,$3f,$f0,$f0,$f8,$f8,$f8,$00,$f8,$00,$15,$7f,$e0,$f8,$02
	dc.b	$06,$f9,$18,$1e,$73,$bd,$f7,$ee,$f0,$f0,$0f,$87,$bf,$df,$9f,$03
	dc.b	$00,$f8,$f8,$00,$f7,$00,$12,$1f,$07,$fd,$fe,$8e,$00,$00,$f8,$3c
	dc.b	$7c,$68,$00,$82,$0c,$3e,$40,$00,$00,$0c,$f6,$00,$f4,$00,$0b,$01
	dc.b	$00,$24,$01,$04,$42,$40,$11,$00,$01,$f0,$40,$f2,$00,$d9,$00,$f8
	dc.b	$00,$15,$07,$81,$fc,$00,$27,$ee,$78,$1f,$0f,$fb,$bf,$cf,$cf,$71
	dc.b	$f0,$6c,$00,$51,$e0,$09,$00,$80,$f8,$00,$f8,$00,$12,$07,$81,$fc
	dc.b	$1c,$20,$0e,$00,$00,$80,$18,$78,$53,$ff,$81,$04,$80,$00,$51,$e0
	dc.b	$fe,$f0,$f8,$00,$f8,$00,$15,$07,$81,$fc,$1c,$27,$f0,$38,$1f,$7f
	dc.b	$e7,$87,$ae,$30,$f1,$f1,$6c,$00,$6f,$e0,$c9,$f0,$f0,$f8,$00,$f8
	dc.b	$00,$15,$07,$81,$fc,$00,$23,$ee,$78,$1f,$7f,$fb,$b3,$5d,$ff,$60
	dc.b	$f9,$cf,$ff,$ae,$1f,$06,$00,$f0,$f8,$00,$f7,$00,$12,$7e,$03,$e3
	dc.b	$dc,$0e,$40,$00,$f8,$38,$78,$71,$cf,$00,$0e,$bc,$00,$10,$00,$30
	dc.b	$f6,$00,$f3,$00,$00,$10,$fe,$00,$05,$04,$04,$82,$00,$91,$08,$f1
	dc.b	$00,$d9,$00,$f8,$00,$14,$03,$01,$fc,$00,$61,$dc,$78,$1e,$83,$ff
	dc.b	$7e,$bf,$9e,$60,$ef,$18,$00,$21,$c0,$38,$01,$f7,$00,$f8,$00,$14
	dc.b	$03,$01,$fc,$18,$62,$38,$08,$01,$00,$1d,$f9,$83,$fe,$80,$1c,$d0
	dc.b	$36,$21,$c1,$c7,$f1,$f7,$00,$f8,$00,$14,$03,$01,$fc,$18,$63,$e0
	dc.b	$78,$1e,$7f,$c1,$0e,$fc,$61,$71,$6f,$d8,$06,$0f,$c1,$ff,$f1,$f7
	dc.b	$00,$f8,$00,$14,$03,$01,$fc,$00,$61,$d8,$f8,$1f,$7b,$fc,$fb,$1b
	dc.b	$ff,$f0,$fc,$1f,$c9,$de,$3e,$00,$01,$f7,$00,$f7,$00,$10,$fe,$03
	dc.b	$e7,$9c,$3c,$00,$21,$f8,$3e,$f1,$c7,$9f,$81,$93,$f8,$30,$20,$f4
	dc.b	$00,$f4,$00,$0b,$02,$20,$00,$00,$04,$21,$04,$20,$00,$01,$00,$c0
	dc.b	$f2,$00,$d9,$00,$f8,$00,$14,$01,$03,$ff,$00,$4f,$dc,$e0,$1f,$07
	dc.b	$c1,$ff,$c7,$7c,$f0,$fb,$10,$00,$03,$82,$74,$02,$f7,$00,$f8,$00
	dc.b	$05,$01,$03,$ff,$00,$48,$10,$fd,$00,$0a,$70,$7f,$9c,$90,$8c,$f0
	dc.b	$ec,$03,$81,$8b,$f2,$f7,$00,$f8,$00,$14,$01,$03,$ff,$00,$4b,$c4
	dc.b	$e0,$1e,$ff,$fe,$0f,$e0,$82,$f0,$fc,$e0,$0c,$1f,$83,$ff,$f2,$f7
	dc.b	$00,$f8,$00,$14,$01,$03,$ff,$00,$4f,$94,$f0,$3f,$ff,$de,$7f,$17
	dc.b	$9e,$70,$fb,$0f,$13,$fc,$7c,$00,$02,$f7,$00,$f7,$00,$0f,$fc,$00
	dc.b	$ff,$b4,$7d,$00,$01,$fc,$1f,$f8,$1f,$7f,$00,$07,$f0,$e0,$f3,$00
	dc.b	$f1,$00,$08,$01,$00,$20,$00,$e0,$00,$80,$07,$e0,$f2,$00,$d9,$00
	dc.b	$f7,$00,$13,$02,$7e,$01,$ff,$b0,$c0,$1f,$03,$c0,$17,$29,$39,$60
	dc.b	$ff,$30,$00,$06,$04,$e8,$04,$f7,$00,$f7,$00,$04,$02,$7e,$01,$fc
	dc.b	$09,$fe,$00,$0b,$20,$08,$d9,$51,$00,$88,$e0,$50,$06,$03,$17,$e4
	dc.b	$f7,$00,$f7,$00,$13,$02,$7e,$01,$ff,$b0,$e0,$1f,$ff,$ff,$e7,$39
	dc.b	$e4,$e0,$f8,$d0,$1c,$1f,$07,$ef,$e4,$f7,$00,$f7,$00,$13,$02,$7e
	dc.b	$01,$fb,$37,$e0,$1f,$ff,$df,$ef,$e0,$35,$60,$ff,$1c,$af,$f9,$f8
	dc.b	$00,$04,$f7,$00,$f8,$00,$13,$01,$fd,$81,$fe,$00,$79,$00,$21,$fc
	dc.b	$3f,$f8,$c6,$7f,$00,$0f,$f3,$40,$00,$00,$10,$f6,$00,$f4,$00,$01
	dc.b	$04,$86,$fe,$00,$06,$20,$00,$1f,$c0,$80,$07,$c0,$f2,$00,$d9,$00
	dc.b	$f8,$00,$14,$01,$20,$7e,$00,$e8,$67,$c0,$1c,$0d,$c0,$1f,$bc,$03
	dc.b	$c0,$7e,$78,$1c,$03,$09,$c0,$0c,$f7,$00,$f8,$00,$07,$01,$20,$7e
	dc.b	$00,$eb,$46,$40,$02,$fe,$00,$09,$23,$f7,$20,$09,$e0,$14,$03,$06
	dc.b	$3f,$cc,$f7,$00,$f8,$00,$14,$01,$20,$7e,$00,$eb,$67,$c0,$1d,$f3
	dc.b	$ff,$ff,$fd,$d0,$e0,$f1,$98,$1c,$33,$0f,$ff,$cc,$f7,$00,$f8,$00
	dc.b	$14,$01,$20,$7e,$00,$ec,$e7,$80,$3f,$f1,$df,$ff,$9e,$2b,$40,$76
	dc.b	$19,$eb,$fc,$f0,$00,$0c,$f7,$00,$f7,$00,$0e,$df,$81,$ff,$10,$3c
	dc.b	$40,$03,$fc,$1f,$f0,$02,$2f,$80,$8f,$fe,$f2,$00,$f4,$00,$0c,$03
	dc.b	$02,$00,$00,$02,$20,$00,$61,$d8,$20,$87,$80,$14,$f3,$00,$d9,$00
	dc.b	$f7,$00,$12,$68,$fe,$01,$7b,$ff,$c1,$7f,$3d,$c0,$17,$f7,$cf,$40
	dc.b	$36,$f4,$7c,$02,$1b,$80,$f6,$00,$f7,$00,$05,$68,$fe,$01,$7b,$8c
	dc.b	$41,$fe,$00,$0a,$10,$10,$30,$80,$c9,$40,$40,$02,$04,$7f,$c0,$f7
	dc.b	$00,$f7,$00,$13,$68,$fe,$01,$7b,$cf,$c1,$7e,$c1,$ff,$e7,$c7,$cc
	dc.b	$40,$79,$34,$3e,$02,$1f,$ff,$c0,$f7,$00,$f7,$00,$11,$68,$fe,$01
	dc.b	$7b,$cb,$81,$bc,$c3,$df,$ff,$c7,$fe,$60,$36,$b7,$3d,$fd,$e0,$f5
	dc.b	$00,$f7,$00,$0f,$97,$01,$fe,$84,$7c,$40,$01,$fe,$1f,$f8,$78,$33
	dc.b	$a0,$8f,$fc,$c2,$f3,$00,$f3,$00,$0a,$04,$40,$42,$02,$20,$08,$08
	dc.b	$00,$20,$4f,$80,$f2,$00,$d9,$00,$f7,$00,$11,$59,$fe,$00,$3f,$fe
	dc.b	$ca,$7f,$7d,$f0,$77,$bd,$fe,$41,$ff,$f0,$7f,$44,$33,$f5,$00,$f7
	dc.b	$00,$13,$59,$fe,$00,$3f,$cd,$cb,$80,$02,$00,$34,$40,$01,$00,$00
	dc.b	$0e,$00,$04,$0c,$ff,$80,$f7,$00,$f7,$00,$13,$59,$fe,$00,$3f,$ce
	dc.b	$cf,$7e,$83,$ef,$8f,$85,$fe,$e1,$f0,$73,$ff,$c4,$3f,$ff,$80,$f7
	dc.b	$00,$f7,$00,$11,$59,$fe,$00,$3f,$cf,$08,$fe,$81,$ef,$bb,$c5,$ff
	dc.b	$40,$3f,$f1,$7e,$3b,$c0,$f5,$00,$f7,$00,$10,$26,$01,$ff,$c0,$39
	dc.b	$c4,$81,$fc,$3f,$f8,$7e,$01,$81,$8f,$fc,$00,$40,$f4,$00,$f3,$00
	dc.b	$0c,$04,$c3,$00,$02,$00,$04,$02,$00,$20,$4f,$80,$81,$80,$f4,$00
	dc.b	$d9,$00,$f7,$00,$11,$37,$f6,$00,$2f,$fd,$d1,$fe,$ff,$c0,$c7,$de
	dc.b	$ff,$01,$6b,$df,$ff,$c0,$26,$f5,$00,$f7,$00,$12,$37,$fe,$00,$2f
	dc.b	$d1,$8e,$01,$00,$3c,$00,$21,$00,$e7,$d4,$34,$00,$00,$19,$ff,$f6
	dc.b	$00,$f7,$00,$12,$37,$fe,$00,$2f,$d9,$e9,$fe,$0f,$ff,$3b,$e1,$ff
	dc.b	$e6,$f4,$df,$ff,$e0,$3f,$ff,$f6,$00,$f7,$00,$11,$37,$fe,$00,$2f
	dc.b	$de,$17,$fe,$0f,$ff,$3f,$c0,$ff,$01,$2f,$c3,$ff,$df,$c0,$f5,$00
	dc.b	$f7,$00,$10,$08,$01,$ff,$d0,$2f,$f6,$01,$fc,$3f,$fc,$3f,$00,$06
	dc.b	$8b,$f8,$00,$20,$f4,$00,$f3,$00,$01,$03,$88,$fe,$00,$05,$04,$21
	dc.b	$00,$e7,$df,$14,$f2,$00,$d9,$00,$f7,$00,$11,$1f,$ef,$00,$1f,$f2
	dc.b	$8f,$ff,$17,$ef,$83,$df,$ff,$a2,$57,$bf,$fb,$c0,$04,$f5,$00,$f7
	dc.b	$00,$12,$1f,$ff,$00,$1f,$f8,$70,$00,$ec,$30,$04,$20,$00,$4d,$e8
	dc.b	$80,$04,$20,$bb,$fe,$f6,$00,$f7,$00,$12,$1f,$ff,$00,$1f,$f7,$ef
	dc.b	$fe,$fb,$fc,$7b,$e2,$ff,$af,$e9,$bf,$fb,$e0,$bf,$fe,$f6,$00,$f7
	dc.b	$00,$11,$1f,$ff,$00,$1f,$f4,$1f,$ef,$fb,$fc,$7f,$c2,$7f,$e0,$16
	dc.b	$5f,$ff,$df,$40,$f5,$00,$f5,$00,$0d,$ff,$e0,$0a,$10,$01,$fc,$3f
	dc.b	$fc,$1f,$80,$5f,$9f,$c0,$04,$f3,$00,$f3,$00,$02,$01,$e0,$11,$fe
	dc.b	$00,$06,$20,$00,$0d,$ee,$e0,$00,$20,$f4,$00,$d9,$00,$f7,$00,$10
	dc.b	$01,$df,$00,$1f,$5c,$7f,$f6,$67,$db,$07,$fb,$7f,$e3,$ed,$e7,$fd
	dc.b	$e0,$f4,$00,$f7,$00,$08,$01,$ff,$00,$1f,$e3,$80,$38,$98,$24,$fe
	dc.b	$00,$06,$0f,$e3,$10,$02,$01,$ff,$fe,$f6,$00,$f7,$00,$12,$01,$ff
	dc.b	$00,$1f,$34,$7f,$fe,$bf,$dc,$f7,$f0,$7f,$ef,$e3,$ff,$fd,$e1,$ff
	dc.b	$fe,$f6,$00,$f7,$00,$10,$01,$ff,$00,$1f,$0b,$ff,$c7,$bb,$fc,$f7
	dc.b	$f4,$7f,$f0,$1e,$e7,$ff,$fe,$f4,$00,$f5,$00,$0d,$ff,$e0,$fb,$80
	dc.b	$01,$fc,$3f,$f8,$1b,$80,$1f,$ec,$00,$02,$f3,$00,$f3,$00,$0a,$24
	dc.b	$00,$39,$00,$00,$08,$04,$00,$1f,$8f,$18,$f2,$00,$d9,$00,$f6,$00
	dc.b	$0f,$7f,$00,$3f,$1c,$f7,$f2,$eb,$f2,$0f,$ef,$bf,$f7,$33,$23,$3f
	dc.b	$e0,$f4,$00,$f6,$00,$11,$7f,$00,$3e,$e3,$c8,$0d,$10,$1c,$00,$00
	dc.b	$40,$1b,$a4,$be,$40,$01,$ff,$dc,$f6,$00,$f6,$00,$11,$7b,$00,$3f
	dc.b	$1f,$df,$f3,$7f,$fd,$ff,$e4,$3f,$fb,$f7,$e3,$bf,$e1,$ff,$dc,$f6
	dc.b	$00,$f6,$00,$0f,$7f,$00,$3e,$fc,$27,$fe,$7b,$ed,$ef,$e4,$7f,$e4
	dc.b	$43,$24,$7f,$fe,$f4,$00,$f6,$00,$0e,$04,$ff,$c1,$e0,$20,$0c,$f8
	dc.b	$0f,$e0,$1f,$c0,$0f,$88,$3f,$40,$f3,$00,$f3,$00,$0b,$03,$d8,$01
	dc.b	$04,$10,$10,$00,$00,$1f,$bc,$c0,$80,$f3,$00,$d9,$00,$f6,$00,$0f
	dc.b	$20,$c0,$7f,$f7,$9f,$fe,$fb,$38,$1d,$ff,$bf,$6f,$3d,$13,$3f,$e0
	dc.b	$f4,$00,$f6,$00,$11,$3f,$c0,$7f,$0f,$e0,$01,$00,$08,$c2,$00,$40
	dc.b	$96,$c2,$fb,$a0,$07,$ff,$78,$f6,$00,$f6,$00,$11,$3f,$c0,$7f,$fc
	dc.b	$7f,$ff,$ff,$fb,$fd,$ef,$bf,$66,$ff,$0c,$3f,$e7,$ff,$78,$f6,$00
	dc.b	$f6,$00,$0f,$3f,$c0,$7e,$f3,$9f,$fe,$fb,$37,$df,$cf,$ff,$f9,$bc
	dc.b	$04,$5f,$f8,$f4,$00,$f5,$00,$0d,$3f,$81,$04,$60,$00,$f8,$03,$c2
	dc.b	$1f,$c0,$9f,$01,$fb,$80,$f3,$00,$f3,$00,$0b,$0f,$e0,$01,$04,$cc
	dc.b	$20,$20,$00,$0f,$c2,$08,$20,$f3,$00,$d9,$00,$f5,$00,$0e,$80,$1f
	dc.b	$3b,$1f,$ff,$bf,$f9,$fd,$df,$fe,$e2,$f7,$5c,$1f,$e8,$f4,$00,$f6
	dc.b	$00,$11,$1f,$80,$ff,$4f,$e0,$00,$40,$04,$40,$00,$81,$1f,$0b,$ff
	dc.b	$d0,$07,$fe,$f0,$f6,$00,$f6,$00,$03,$1f,$80,$fe,$38,$fe,$ff,$0a
	dc.b	$fc,$ff,$ff,$fe,$ef,$f7,$00,$df,$ef,$fe,$f0,$f6,$00,$f6,$00,$0f
	dc.b	$1f,$80,$1e,$f3,$1f,$ff,$ff,$f8,$b9,$df,$ff,$fc,$fb,$00,$0f,$f0
	dc.b	$f4,$00,$f5,$00,$0d,$3f,$01,$c4,$e0,$00,$f8,$c3,$84,$1f,$81,$10
	dc.b	$0f,$ff,$20,$f3,$00,$f3,$00,$0b,$8b,$e0,$00,$00,$04,$42,$20,$00
	dc.b	$0f,$00,$00,$10,$f3,$00,$d9,$00,$f5,$00,$0e,$31,$7f,$fe,$3f,$ff
	dc.b	$e6,$de,$ff,$fe,$7e,$ec,$f7,$f8,$17,$f0,$f4,$00,$f6,$00,$11,$0c
	dc.b	$31,$ff,$87,$c0,$00,$99,$21,$82,$00,$81,$13,$0f,$fe,$a8,$0f,$f9
	dc.b	$f0,$f6,$00,$f6,$00,$11,$0c,$31,$ff,$fd,$ff,$ff,$fe,$ff,$7f,$fe
	dc.b	$fe,$ec,$f7,$00,$b7,$ff,$f9,$f0,$f6,$00,$f6,$00,$0f,$0c,$31,$7f
	dc.b	$ba,$1f,$ff,$77,$df,$7d,$df,$7f,$f7,$ff,$01,$0f,$e0,$f4,$00,$f5
	dc.b	$00,$0d,$0e,$00,$05,$c0,$00,$79,$c3,$84,$3e,$01,$13,$0f,$fe,$48
	dc.b	$f3,$00,$f3,$00,$08,$47,$e0,$00,$88,$20,$02,$01,$80,$08,$f0,$00
	dc.b	$d9,$00,$f5,$00,$0e,$62,$3f,$fa,$3b,$df,$c6,$dd,$79,$f6,$ff,$fb
	dc.b	$ff,$d1,$07,$e0,$f4,$00,$f5,$00,$10,$63,$ff,$c3,$c4,$20,$79,$e7
	dc.b	$8c,$2a,$00,$04,$07,$dd,$40,$1f,$b3,$40,$f6,$00,$f5,$00,$10,$63
	dc.b	$ff,$fd,$fb,$df,$ff,$ff,$7d,$f7,$ff,$fb,$fe,$20,$47,$ff,$b3,$40
	dc.b	$f6,$00,$f5,$00,$0e,$62,$3f,$b6,$7f,$ff,$f7,$1a,$fd,$dc,$f9,$f7
	dc.b	$fe,$22,$3f,$e0,$f4,$00,$f5,$00,$0f,$1c,$00,$01,$84,$20,$70,$e3
	dc.b	$06,$36,$00,$04,$03,$dd,$80,$00,$40,$f5,$00,$f3,$00,$09,$4b,$c0
	dc.b	$00,$09,$e5,$8a,$2b,$06,$08,$04,$f1,$00,$d9,$00,$f5,$00,$0e,$0d
	dc.b	$ff,$76,$4e,$3d,$9d,$0a,$fd,$af,$f1,$33,$ff,$c0,$07,$c0,$f4,$00
	dc.b	$f5,$00,$0f,$4d,$ff,$8d,$90,$c2,$23,$f2,$8c,$7c,$0f,$cc,$03,$d8
	dc.b	$1c,$3f,$76,$f5,$00,$f5,$00,$0f,$4d,$ff,$77,$9d,$bf,$ff,$0a,$7f
	dc.b	$af,$ff,$fb,$fc,$20,$1f,$df,$76,$f5,$00,$f5,$00,$0e,$4d,$ff,$66
	dc.b	$72,$5d,$ac,$f9,$b1,$d1,$f6,$b7,$fc,$27,$e3,$e0,$f4,$00,$f5,$00
	dc.b	$0f,$12,$00,$9b,$ee,$40,$31,$16,$0c,$6e,$00,$04,$03,$d8,$00,$20
	dc.b	$80,$f5,$00,$f3,$00,$0b,$01,$f1,$a2,$43,$e7,$ce,$3c,$0f,$c8,$00
	dc.b	$00,$04,$f3,$00,$d9,$00,$f5,$00,$0e,$1f,$ff,$46,$e4,$7d,$fe,$7f
	dc.b	$ef,$ff,$eb,$f7,$ff,$d8,$03,$e0,$f4,$00,$f7,$00,$11,$20,$00,$9f
	dc.b	$ff,$bd,$3b,$a6,$33,$e7,$dc,$3c,$04,$08,$03,$d8,$38,$3f,$e0,$f5
	dc.b	$00,$f7,$00,$11,$20,$00,$9f,$ff,$5f,$1b,$7f,$fc,$7c,$7d,$ff,$f7
	dc.b	$ff,$fe,$00,$3f,$ff,$e0,$f5,$00,$f7,$00,$10,$20,$00,$9f,$ff,$e6
	dc.b	$e4,$9b,$cf,$8b,$b3,$83,$ef,$f7,$fc,$27,$c7,$c0,$f4,$00,$f3,$00
	dc.b	$0a,$a3,$df,$40,$20,$70,$0e,$7c,$08,$00,$03,$d8,$f2,$00,$f3,$00
	dc.b	$0c,$01,$ff,$e6,$33,$e7,$de,$3c,$1f,$c8,$02,$00,$00,$20,$f4,$00
	dc.b	$d9,$00,$f5,$00,$0e,$0f,$fe,$ff,$c0,$f4,$fe,$fb,$9e,$7f,$bd,$ff
	dc.b	$ff,$a0,$03,$c0,$f4,$00,$f5,$00,$0f,$3f,$ff,$0e,$ff,$0e,$27,$f6
	dc.b	$ff,$f8,$42,$24,$03,$a0,$78,$1f,$c0,$f5,$00,$f5,$00,$0f,$3f,$fe
	dc.b	$fe,$ff,$56,$fe,$c5,$3f,$ff,$af,$3f,$fe,$01,$7f,$ff,$c0,$f5,$00
	dc.b	$f5,$00,$0e,$3f,$fe,$ef,$c1,$aa,$dd,$3b,$c0,$07,$df,$d3,$fc,$5f
	dc.b	$87,$e0,$f4,$00,$f4,$00,$0b,$01,$11,$fe,$f9,$02,$c8,$5e,$78,$70
	dc.b	$c0,$01,$a0,$f2,$00,$f3,$00,$09,$01,$3f,$e7,$27,$f7,$bf,$f8,$1f
	dc.b	$ec,$02,$f1,$00,$d9,$00,$f5,$00,$0e,$0f,$be,$f7,$80,$e0,$74,$ff
	dc.b	$fe,$af,$de,$e3,$fd,$e0,$03,$c0,$f4,$00,$f5,$00,$0f,$1f,$be,$07
	dc.b	$ff,$3f,$8f,$fd,$1e,$20,$c1,$02,$03,$e0,$78,$1f,$80,$f5,$00,$f5
	dc.b	$00,$0f,$1f,$be,$f7,$bf,$ff,$ff,$8e,$fb,$7f,$ff,$0b,$fc,$00,$7f
	dc.b	$df,$80,$f5,$00,$f5,$00,$0e,$1f,$bf,$f7,$80,$8f,$73,$73,$c4,$af
	dc.b	$5f,$e5,$fe,$1f,$87,$e0,$f4,$00,$f4,$00,$0b,$41,$09,$ff,$70,$04
	dc.b	$88,$3a,$c0,$00,$f4,$03,$e0,$f2,$00,$f4,$00,$09,$01,$00,$3f,$ff
	dc.b	$8f,$ff,$9f,$30,$ff,$fe,$f0,$00,$d9,$00,$f5,$00,$0e,$0f,$fe,$f3
	dc.b	$83,$e3,$f0,$fb,$9a,$5c,$fb,$83,$fe,$40,$03,$80,$f4,$00,$f5,$00
	dc.b	$0e,$0f,$ff,$0f,$fd,$3c,$07,$74,$66,$62,$c0,$00,$00,$40,$e0,$3f
	dc.b	$f4,$00,$f5,$00,$0e,$0f,$ff,$f7,$bd,$7c,$7f,$0f,$fe,$dc,$f8,$03
	dc.b	$fc,$0c,$e7,$ff,$f4,$00,$f5,$00,$0e,$0f,$fe,$fb,$82,$1e,$37,$ff
	dc.b	$fd,$be,$ff,$fc,$7f,$bf,$1b,$c0,$f4,$00,$f3,$00,$0b,$0c,$7f,$e3
	dc.b	$80,$80,$03,$23,$07,$ff,$02,$40,$04,$f3,$00,$f4,$00,$0a,$01,$04
	dc.b	$3f,$ff,$cf,$ff,$ff,$41,$ff,$fc,$80,$f1,$00,$d9,$00,$f5,$00,$0f
	dc.b	$07,$fe,$ff,$c7,$df,$b1,$df,$bf,$fd,$3f,$06,$3c,$06,$07,$80,$70
	dc.b	$f5,$00,$f5,$00,$08,$07,$ff,$01,$f9,$f0,$c6,$c0,$40,$85,$fe,$00
	dc.b	$03,$06,$e0,$7c,$70,$f5,$00,$f5,$00,$0f,$07,$fe,$fe,$f9,$78,$fe
	dc.b	$df,$f0,$ff,$f8,$07,$bc,$1e,$e3,$fc,$70,$f5,$00,$f5,$00,$0f,$07
	dc.b	$ff,$fc,$c6,$94,$b7,$df,$ff,$79,$37,$f9,$ff,$f9,$1f,$80,$70,$f5
	dc.b	$00,$f4,$00,$0c,$01,$01,$3f,$7f,$01,$20,$0f,$80,$0f,$fe,$40,$00
	dc.b	$04,$f3,$00,$f3,$00,$09,$02,$3f,$e7,$cf,$ff,$ff,$07,$f7,$f8,$40
	dc.b	$f1,$00,$d9,$00,$f5,$00,$0f,$07,$fe,$ff,$cf,$7b,$db,$37,$fe,$76
	dc.b	$7e,$0c,$38,$0e,$23,$01,$e0,$f5,$00,$f6,$00,$10,$20,$07,$ff,$00
	dc.b	$f0,$b5,$85,$30,$00,$9e,$00,$00,$c0,$0f,$84,$79,$e0,$f5,$00,$f6
	dc.b	$00,$10,$20,$07,$fe,$ff,$f0,$b5,$dd,$ff,$ec,$7f,$f8,$0f,$3c,$1e
	dc.b	$a3,$f9,$e0,$f5,$00,$f6,$00,$10,$20,$07,$ff,$ff,$4f,$79,$5d,$37
	dc.b	$ff,$fe,$07,$f3,$1b,$f0,$5f,$01,$e0,$f5,$00,$f4,$00,$0d,$01,$00
	dc.b	$3f,$fe,$22,$00,$13,$80,$7f,$fc,$c4,$01,$04,$80,$f4,$00,$f2,$00
	dc.b	$08,$bf,$cf,$a7,$ff,$ff,$1f,$87,$f0,$20,$f1,$00,$d9,$00,$f5,$00
	dc.b	$0f,$03,$fe,$ff,$da,$73,$00,$c7,$dc,$fe,$fc,$38,$10,$18,$87,$03
	dc.b	$c0,$f5,$00,$f5,$00,$0f,$03,$ff,$00,$45,$8b,$9e,$40,$23,$2e,$00
	dc.b	$01,$d0,$1b,$81,$f3,$c0,$f5,$00,$f5,$00,$0f,$03,$fe,$ff,$c5,$8b
	dc.b	$9f,$7f,$fe,$ef,$f0,$3e,$58,$18,$cf,$f3,$c0,$f5,$00,$f5,$00,$0f
	dc.b	$03,$ff,$ff,$5a,$77,$32,$47,$ff,$de,$0f,$c6,$2d,$e4,$76,$03,$c0
	dc.b	$f5,$00,$f4,$00,$0c,$01,$00,$3f,$fa,$60,$80,$01,$10,$ff,$f9,$82
	dc.b	$03,$08,$f3,$00,$f2,$00,$0a,$9f,$fd,$ff,$ff,$fe,$3f,$0f,$c0,$10
	dc.b	$00,$01,$f3,$00,$d9,$00,$f5,$00,$0f,$01,$ff,$fe,$80,$00,$29,$8f
	dc.b	$bb,$c1,$f8,$70,$00,$7c,$16,$07,$80,$f5,$00,$f5,$00,$0f,$01,$fe
	dc.b	$01,$83,$fe,$80,$80,$44,$3f,$00,$03,$de,$7e,$09,$e7,$80,$f5,$00
	dc.b	$f5,$00,$05,$01,$ff,$fe,$83,$ff,$90,$fe,$ff,$06,$f0,$7e,$de,$7c
	dc.b	$1f,$e7,$80,$f5,$00,$f5,$00,$0f,$01,$ff,$ff,$80,$00,$68,$8f,$ff
	dc.b	$41,$0f,$8c,$21,$81,$e4,$07,$80,$f5,$00,$f3,$00,$0a,$01,$7f,$fe
	dc.b	$ef,$00,$00,$1f,$ff,$f1,$00,$02,$f2,$00,$f2,$00,$00,$03,$fe,$ff
	dc.b	$06,$fc,$be,$0f,$80,$00,$00,$0a,$f3,$00,$d9,$00,$f5,$00,$0e,$01
	dc.b	$ff,$fc,$40,$0f,$12,$8c,$79,$83,$fc,$47,$e0,$18,$2c,$0e,$f4,$00
	dc.b	$f5,$00,$0e,$01,$fe,$02,$c1,$ff,$0b,$90,$84,$7f,$00,$87,$fe,$1c
	dc.b	$01,$ae,$f4,$00,$f5,$00,$0e,$01,$ff,$fc,$81,$f7,$2f,$f0,$bd,$1f
	dc.b	$cc,$47,$fe,$18,$3d,$ae,$f4,$00,$f5,$00,$0e,$01,$fe,$fe,$c0,$07
	dc.b	$d0,$93,$fc,$e3,$33,$3f,$e1,$e3,$ce,$0e,$f4,$00,$f3,$00,$0b,$03
	dc.b	$7f,$ff,$9b,$0f,$43,$ff,$ff,$c0,$00,$04,$10,$f3,$00,$f4,$00,$08
	dc.b	$01,$00,$01,$f0,$ff,$ff,$fe,$9c,$33,$ef,$00,$d9,$00,$f4,$00,$0d
	dc.b	$fe,$ff,$80,$1e,$2e,$38,$81,$ae,$e0,$0e,$00,$12,$58,$24,$f4,$00
	dc.b	$f4,$00,$0d,$fe,$01,$90,$7e,$07,$e1,$7f,$1f,$07,$0e,$1c,$10,$03
	dc.b	$24,$f4,$00,$f4,$00,$0d,$fe,$ff,$10,$6e,$0f,$e1,$7f,$37,$e0,$0e
	dc.b	$1c,$12,$5f,$24,$f4,$00,$f4,$00,$0d,$ff,$ff,$90,$0f,$f8,$07,$80
	dc.b	$e6,$18,$2e,$03,$ed,$bc,$24,$f4,$00,$f4,$00,$09,$01,$00,$ef,$ff
	dc.b	$2f,$fe,$ff,$df,$e7,$d0,$f0,$00,$f4,$00,$07,$01,$00,$00,$61,$f7
	dc.b	$ff,$ff,$d1,$ee,$00,$d9,$00,$f4,$00,$0d,$fe,$ff,$98,$7e,$bc,$9b
	dc.b	$03,$dc,$40,$3c,$00,$b4,$30,$40,$f4,$00,$f4,$00,$0d,$ff,$00,$f8
	dc.b	$be,$f1,$e3,$ff,$ee,$08,$3c,$bd,$02,$46,$40,$f4,$00,$f4,$00,$0d
	dc.b	$fe,$ff,$60,$9e,$fd,$e3,$df,$df,$e0,$3c,$bc,$b6,$7e,$40,$f4,$00
	dc.b	$f4,$00,$0d,$fe,$ff,$f8,$1f,$be,$8f,$00,$ad,$b0,$7c,$82,$49,$98
	dc.b	$40,$f4,$00,$f4,$00,$0a,$01,$01,$9f,$fe,$fd,$ff,$ff,$fe,$49,$80
	dc.b	$01,$f1,$00,$f1,$00,$04,$81,$43,$7c,$df,$42,$fd,$00,$00,$20,$f3
	dc.b	$00,$d9,$00,$f4,$00,$0c,$7b,$7f,$10,$fc,$45,$8e,$67,$e9,$04,$60
	dc.b	$c0,$e0,$21,$f3,$00,$f4,$00,$0c,$7b,$81,$f4,$7f,$f1,$4f,$ff,$cd
	dc.b	$04,$ff,$fb,$0f,$89,$f3,$00,$f4,$00,$0c,$7b,$7e,$e4,$1c,$c5,$cf
	dc.b	$ff,$fe,$c4,$ff,$fb,$ef,$a9,$f3,$00,$f4,$00,$0c,$7b,$fd,$f4,$3c
	dc.b	$4f,$be,$63,$da,$e4,$ff,$c4,$10,$71,$f3,$00,$f3,$00,$07,$81,$1b
	dc.b	$ff,$f5,$cf,$ff,$cd,$03,$ef,$00,$f3,$00,$06,$02,$00,$00,$8a,$71
	dc.b	$9c,$24,$ee,$00,$d9,$00,$f4,$00,$0c,$2f,$7e,$20,$f8,$3f,$8e,$df
	dc.b	$72,$18,$00,$c1,$c0,$6c,$f3,$00,$f4,$00,$0c,$3f,$01,$e3,$fc,$02
	dc.b	$09,$e7,$52,$18,$0f,$e6,$1f,$0c,$f3,$00,$f4,$00,$0c,$3f,$7f,$c3
	dc.b	$18,$3e,$0f,$ff,$55,$80,$0f,$e7,$df,$4c,$f3,$00,$f4,$00,$0c,$2f
	dc.b	$fe,$e3,$f8,$3e,$4e,$db,$45,$d8,$0f,$c8,$20,$6c,$f3,$00,$f3,$00
	dc.b	$07,$80,$34,$ff,$ff,$bf,$ff,$fa,$18,$fe,$00,$00,$20,$f3,$00,$f3
	dc.b	$00,$00,$80,$fe,$00,$02,$41,$24,$20,$fd,$00,$00,$20,$f3,$00,$d9
	dc.b	$00,$f3,$00,$07,$7f,$00,$e3,$7f,$9e,$7e,$d7,$e0,$fe,$00,$00,$fc
	dc.b	$f3,$00,$f3,$00,$0b,$01,$03,$fb,$00,$12,$4e,$e7,$e0,$00,$00,$3c
	dc.b	$5c,$f3,$00,$f3,$00,$06,$ff,$03,$10,$70,$18,$6e,$d4,$fe,$00,$01
	dc.b	$3c,$dc,$f3,$00,$f3,$00,$07,$7f,$03,$f3,$70,$18,$6e,$e7,$e0,$fe
	dc.b	$00,$00,$1c,$f3,$00,$f3,$00,$07,$80,$00,$ef,$ff,$ff,$f7,$8b,$e0
	dc.b	$fe,$00,$00,$20,$f3,$00,$f3,$00,$00,$80,$fc,$00,$00,$30,$fd,$00
	dc.b	$00,$c0,$f3,$00,$d9,$00,$f3,$00,$06,$3c,$00,$80,$7f,$be,$fd,$3b
	dc.b	$fe,$00,$01,$c0,$40,$f3,$00,$f2,$00,$0a,$03,$80,$79,$a6,$fd,$e7
	dc.b	$80,$00,$00,$f8,$80,$f3,$00,$f3,$00,$0b,$3e,$03,$00,$79,$a6,$f9
	dc.b	$dc,$80,$00,$00,$f8,$42,$f3,$00,$f3,$00,$0b,$7c,$03,$80,$79,$a6
	dc.b	$fd,$ef,$80,$00,$00,$c0,$80,$f3,$00,$f3,$00,$06,$02,$00,$81,$86
	dc.b	$59,$07,$3b,$fd,$00,$00,$42,$f3,$00,$ed,$00,$00,$10,$fd,$00,$00
	dc.b	$c2,$f3,$00,$d9,$00,$f3,$00,$06,$3c,$00,$00,$df,$19,$a0,$18,$fd
	dc.b	$00,$00,$40,$f3,$00,$f3,$00,$06,$20,$02,$41,$d3,$ed,$a0,$0b,$ee
	dc.b	$00,$f3,$00,$06,$3c,$02,$41,$d3,$ed,$a0,$13,$fd,$00,$00,$c0,$f3
	dc.b	$00,$f3,$00,$06,$1e,$02,$41,$d3,$ed,$a0,$0b,$fd,$00,$00,$80,$f3
	dc.b	$00,$f3,$00,$06,$20,$00,$00,$0c,$12,$00,$18,$fd,$00,$00,$c0,$f3
	dc.b	$00,$ed,$00,$00,$10,$fd,$00,$00,$40,$f3,$00,$d9,$00,$f3,$00,$06
	dc.b	$0c,$00,$00,$1e,$22,$00,$10,$fd,$00,$00,$40,$f3,$00,$f0,$00,$03
	dc.b	$16,$02,$00,$10,$ee,$00,$f3,$00,$04,$1e,$00,$00,$16,$02,$fb,$00
	dc.b	$00,$c0,$f3,$00,$f3,$00,$06,$0c,$00,$00,$16,$02,$00,$10,$fd,$00
	dc.b	$00,$80,$f3,$00,$f3,$00,$06,$12,$00,$00,$08,$20,$00,$10,$fd,$00
	dc.b	$00,$c0,$f3,$00,$e8,$00,$00,$40,$f3,$00,$d9,$00,$f3,$00,$00,$0c
	dc.b	$fc,$00,$00,$10,$fd,$00,$00,$40,$f3,$00,$f3,$00,$00,$0a,$fc,$00
	dc.b	$00,$10,$fd,$00,$00,$a0,$f3,$00,$f3,$00,$00,$0c,$fc,$00,$00,$08
	dc.b	$fd,$00,$00,$60,$f3,$00,$f3,$00,$00,$06,$fc,$00,$00,$10,$fd,$00
	dc.b	$00,$a0,$f3,$00,$f3,$00,$00,$02,$fc,$00,$00,$18,$fd,$00,$00,$40
	dc.b	$f3,$00,$f3,$00,$00,$08,$fc,$00,$00,$08,$fd,$00,$00,$c0,$f3,$00
	dc.b	$d9,$00,$f3,$00,$00,$06,$fc,$00,$00,$30,$fd,$00,$00,$80,$f3,$00
	dc.b	$f3,$00,$00,$08,$f7,$00,$00,$40,$f3,$00,$f3,$00,$00,$0e,$fc,$00
	dc.b	$00,$10,$fd,$00,$00,$80,$f3,$00,$f3,$00,$00,$0b,$f7,$00,$00,$40
	dc.b	$f3,$00,$f3,$00,$00,$04,$fc,$00,$00,$30,$fd,$00,$00,$80,$f3,$00
	dc.b	$f3,$00,$00,$04,$fc,$00,$00,$10,$fd,$00,$00,$c0,$f3,$00,$d9,$00
	dc.b	$f3,$00,$00,$02,$fc,$00,$00,$10,$ee,$00,$f3,$00,$00,$04,$fc,$00
	dc.b	$00,$30,$fd,$00,$00,$80,$f3,$00,$f3,$00,$00,$07,$fc,$00,$00,$20
	dc.b	$fd,$00,$00,$80,$f3,$00,$f3,$00,$00,$04,$fc,$00,$00,$30,$fd,$00
	dc.b	$00,$80,$f3,$00,$f3,$00,$00,$07,$fc,$00,$00,$10,$ee,$00,$f3,$00
	dc.b	$00,$03,$e8,$00,$d9,$00,$f3,$00,$00,$02,$e8,$00,$f3,$00,$00,$04
	dc.b	$e8,$00,$f3,$00,$00,$06,$e8,$00,$f3,$00,$00,$04,$e8,$00,$f3,$00
	dc.b	$00,$02,$e8,$00,$f3,$00,$00,$02,$e8,$00,$d9,$00,$f3,$00,$09,$06
	dc.b	$00,$00,$14,$0a,$a0,$45,$02,$0a,$a0,$f1,$00,$f3,$00,$09,$05,$00
	dc.b	$00,$14,$0a,$a0,$45,$02,$0a,$a0,$f1,$00,$f3,$00,$09,$03,$00,$00
	dc.b	$14,$0a,$a0,$55,$12,$0a,$a0,$f1,$00,$f3,$00,$09,$05,$00,$00,$14
	dc.b	$0a,$a0,$45,$02,$0a,$a0,$f1,$00,$f3,$00,$09,$06,$00,$00,$6b,$34
	dc.b	$59,$b2,$dd,$34,$58,$f1,$00,$f3,$00,$00,$02,$fc,$00,$01,$10,$10
	dc.b	$ef,$00,$d9,$00,$f3,$00,$09,$06,$00,$00,$01,$40,$42,$48,$31,$01
	dc.b	$c0,$f1,$00,$f0,$00,$06,$01,$5a,$42,$58,$71,$13,$c0,$f1,$00,$f3
	dc.b	$00,$09,$06,$00,$00,$0b,$5a,$c2,$7c,$7b,$13,$e4,$f1,$00,$f3,$00
	dc.b	$09,$04,$00,$00,$25,$40,$62,$c9,$35,$01,$e0,$f1,$00,$f3,$00,$09
	dc.b	$06,$00,$00,$9a,$81,$8c,$26,$0a,$c8,$0c,$f1,$00,$f3,$00,$09,$02
	dc.b	$00,$00,$0a,$00,$80,$24,$0a,$00,$04,$f1,$00,$d9,$00,$f0,$00,$06
	dc.b	$20,$11,$40,$a2,$00,$11,$40,$f1,$00,$f3,$00,$09,$06,$00,$00,$20
	dc.b	$11,$4c,$a2,$00,$11,$40,$f1,$00,$f3,$00,$09,$04,$00,$00,$2c,$15
	dc.b	$6c,$aa,$0c,$11,$64,$f1,$00,$f3,$00,$09,$06,$00,$00,$20,$93,$40
	dc.b	$b2,$40,$93,$40,$f1,$00,$f3,$00,$09,$04,$00,$01,$0d,$04,$20,$08
	dc.b	$2d,$00,$2c,$f1,$00,$f3,$00,$09,$02,$00,$00,$0c,$04,$20,$08,$0c
	dc.b	$00,$24,$f1,$00,$d9,$00,$f0,$00,$06,$24,$11,$30,$42,$0a,$11,$60
	dc.b	$f1,$00,$f1,$00,$07,$01,$24,$11,$34,$42,$0b,$11,$68,$f1,$00,$f1
	dc.b	$00,$07,$01,$2c,$15,$34,$cb,$0b,$55,$6c,$f1,$00,$f0,$00,$06,$24
	dc.b	$93,$38,$52,$4a,$93,$60,$f1,$00,$f0,$00,$06,$09,$04,$00,$a9,$24
	dc.b	$44,$04,$f1,$00,$f0,$00,$06,$08,$04,$00,$89,$00,$44,$04,$f1,$00
	dc.b	$d9,$00,$f0,$00,$06,$08,$00,$20,$a1,$08,$14,$20,$f1,$00,$f0,$00
	dc.b	$06,$08,$01,$28,$a1,$09,$15,$20,$f1,$00,$f0,$00,$06,$48,$c5,$28
	dc.b	$b1,$09,$df,$24,$f1,$00,$f0,$00,$06,$08,$82,$24,$b1,$6c,$96,$20
	dc.b	$f1,$00,$f1,$00,$07,$01,$65,$54,$c3,$0a,$02,$48,$4c,$f1,$00,$f0
	dc.b	$00,$01,$40,$44,$fe,$00,$01,$48,$04,$f1,$00,$d9,$00,$f0,$00,$06
	dc.b	$08,$00,$a2,$29,$09,$10,$14,$f1,$00,$f0,$00,$06,$08,$00,$ee,$a9
	dc.b	$09,$10,$14,$f1,$00,$f0,$00,$06,$88,$c4,$ee,$b9,$09,$da,$54,$f1
	dc.b	$00,$f0,$00,$06,$08,$82,$a2,$39,$69,$92,$14,$f1,$00,$f1,$00,$07
	dc.b	$01,$a5,$55,$01,$02,$04,$4d,$68,$f1,$00,$f0,$00,$01,$80,$44,$fe
	dc.b	$00,$01,$48,$40,$f1,$00,$d9,$00,$f0,$00,$06,$08,$40,$00,$29,$08
	dc.b	$40,$04,$f1,$00,$f0,$00,$06,$08,$40,$08,$29,$08,$50,$2c,$f1,$00
	dc.b	$f0,$00,$06,$88,$c6,$09,$39,$08,$d2,$2c,$f1,$00,$f0,$00,$06,$08
	dc.b	$c2,$04,$39,$68,$c2,$04,$f1,$00,$f1,$00,$07,$01,$a5,$15,$61,$82
	dc.b	$05,$01,$50,$f1,$00,$f0,$00,$02,$80,$04,$01,$ed,$00,$d9,$00,$f0
	dc.b	$00,$06,$08,$10,$20,$2a,$09,$00,$20,$f1,$00,$f1,$00,$07,$01,$08
	dc.b	$10,$28,$2a,$29,$00,$20,$f1,$00,$f1,$00,$07,$01,$08,$d6,$29,$3a
	dc.b	$29,$c6,$24,$f1,$00,$f0,$00,$06,$08,$92,$24,$3a,$49,$82,$20,$f1
	dc.b	$00,$f0,$00,$06,$25,$45,$41,$80,$04,$55,$4c,$f1,$00,$ef,$00,$05
	dc.b	$44,$01,$00,$00,$44,$04,$f1,$00,$d9,$00,$f0,$00,$04,$0c,$10,$40
	dc.b	$aa,$04,$ef,$00,$f0,$00,$05,$0c,$10,$48,$aa,$04,$01,$f0,$00,$f0
	dc.b	$00,$06,$0c,$d6,$68,$bb,$0c,$c1,$60,$f1,$00,$f0,$00,$05,$0c,$92
	dc.b	$44,$ba,$64,$82,$f0,$00,$f1,$00,$07,$01,$21,$45,$20,$01,$09,$50
	dc.b	$68,$f1,$00,$ef,$00,$05,$44,$20,$01,$08,$40,$60,$f1,$00,$d9,$00
	dc.b	$ef,$00,$04,$03,$08,$00,$61,$80,$f0,$00,$f0,$00,$05,$7e,$2b,$9a
	dc.b	$45,$63,$b8,$f0,$00,$f1,$00,$06,$01,$7e,$ab,$9e,$55,$63,$b8,$f0
	dc.b	$00,$ef,$00,$04,$13,$08,$02,$61,$80,$f0,$00,$f1,$00,$07,$01,$81
	dc.b	$c4,$65,$b8,$9c,$47,$f0,$f1,$00,$f1,$00,$04,$01,$00,$80,$04,$10
	dc.b	$ee,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00
	dc.b	$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00
	dc.b	$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00
	dc.b	$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00,$d9,$00
g2embed_zm_titlebrush_end

	even
g2embed_zm_title_pal
	dc.b	$00,$00,$00,$00,$02,$10,$02,$10,$03,$20,$03,$20,$0f,$ff,$0e,$ee
	dc.b	$03,$30,$03,$30,$04,$40,$04,$40,$02,$00,$02,$00,$01,$00,$01,$00
	dc.b	$05,$50,$05,$50,$04,$50,$04,$50,$06,$40,$06,$40,$0f,$ff,$03,$33
	dc.b	$04,$30,$04,$30,$05,$40,$05,$40,$02,$22,$09,$99,$04,$20,$04,$20
	dc.b	$03,$00,$03,$00,$07,$50,$07,$50,$03,$10,$03,$10,$0e,$ee,$0b,$bb
	dc.b	$0d,$dd,$0b,$bb,$00,$00,$09,$99,$05,$30,$05,$30,$01,$11,$0b,$bb
	dc.b	$01,$11,$03,$33,$03,$40,$03,$40,$0e,$ee,$03,$22,$08,$50,$08,$50
	dc.b	$06,$30,$06,$30,$02,$22,$03,$33,$0c,$cc,$0c,$cb,$06,$50,$06,$50
	dc.b	$0d,$dd,$03,$32,$07,$60,$07,$60,$03,$33,$02,$22,$0b,$bb,$0b,$bb
	dc.b	$0c,$cc,$02,$21,$04,$44,$0b,$bb,$04,$10,$04,$10,$03,$33,$07,$88
	dc.b	$08,$60,$08,$60,$05,$55,$09,$99,$0b,$bb,$02,$22,$07,$40,$07,$40
	dc.b	$08,$70,$08,$70,$04,$44,$03,$33,$0e,$ee,$09,$87,$05,$55,$04,$44
	dc.b	$09,$70,$09,$81,$03,$33,$0d,$cc,$05,$20,$05,$20,$09,$99,$0c,$ba
	dc.b	$09,$99,$04,$33,$0a,$aa,$05,$44,$0e,$ed,$00,$0f,$09,$60,$09,$60
	dc.b	$0a,$aa,$0c,$cb,$07,$77,$0a,$aa,$06,$30,$02,$aa,$07,$77,$03,$33
	dc.b	$08,$88,$02,$22,$02,$21,$0f,$03,$06,$20,$06,$20,$06,$66,$0c,$cb
	dc.b	$02,$00,$0f,$aa,$08,$88,$0c,$cc,$04,$10,$06,$bf,$08,$76,$06,$3c
	dc.b	$04,$32,$07,$bb,$06,$66,$03,$33,$06,$54,$01,$1f,$0f,$00,$05,$ba
	dc.b	$0c,$00,$0d,$44,$0b,$bb,$0f,$a2,$03,$22,$0d,$22,$0b,$ba,$08,$49
	dc.b	$0a,$99,$06,$b9,$0b,$aa,$03,$d7,$0a,$a9,$0a,$89,$06,$64,$07,$b6
	dc.b	$0a,$a8,$0b,$1c,$02,$00,$05,$88,$02,$10,$07,$7a,$05,$33,$05,$dd
	dc.b	$06,$54,$07,$99,$03,$22,$0c,$e0,$08,$86,$08,$43,$08,$88,$0b,$97
	dc.b	$08,$77,$04,$a9,$0b,$bb,$0f,$30,$07,$55,$04,$aa,$06,$55,$0a,$88
	dc.b	$0d,$dd,$09,$62,$08,$61,$08,$99,$0e,$ed,$02,$04,$05,$52,$02,$2b
	dc.b	$03,$11,$06,$52,$0a,$aa,$08,$31,$0a,$aa,$0d,$a2,$0b,$a9,$05,$b7
	dc.b	$04,$22,$0c,$99,$04,$33,$08,$11,$08,$77,$0d,$fa,$07,$66,$0b,$b7
	dc.b	$08,$88,$09,$63,$0c,$cc,$07,$87,$06,$44,$02,$c2,$09,$88,$06,$74
	dc.b	$0a,$97,$05,$b8,$0a,$96,$03,$35,$09,$98,$0c,$da,$09,$98,$0a,$27
	dc.b	$08,$53,$02,$f2,$08,$74,$04,$4c,$09,$97,$0d,$24,$02,$00,$09,$11
	dc.b	$04,$30,$01,$cd,$09,$85,$09,$d0,$07,$66,$02,$70,$0c,$b9,$04,$69
	dc.b	$0c,$ba,$00,$82,$09,$86,$07,$5b,$07,$64,$07,$9b,$0c,$cc,$0c,$50
	dc.b	$06,$51,$0b,$6d,$0d,$dc,$04,$1a,$06,$40,$01,$78,$09,$76,$01,$d5
g2embed_zm_title_pal_end

