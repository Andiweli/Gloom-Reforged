
 	;*********
	;* GLOOM *
	;*********
	;
	;error codes
	;
	;red - allocmem failed
	;yel - freemem failed
	;orange - unknown script command
	;purp - unknown event command
	;cyn - can't open file in loadfile
	;blu - ran out of remap colours!

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
focshft	equ	6
grdshft	equ	8
darkshft	equ	7	;smaller=smaller range=faster!
maxz	equ	16<<darkshft	;16*128=2048*8=16384
	;
exshft	equ	3
exone	equ	1<<exshft
exhalf	equ	exone>>1
	;
linemod	equ	40*7

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
wi_copmod	rs.w	1
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
	move.l	rawtable(pc),a0
	key	\1
	endm

freemem	macro
	;
	ifne	debugmem
	lea	.fmem\@,a0
	jsr	freemem_
	bra.l	.fmemskip\@
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
	bra.l	.amemskip\@
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
	bra.l	.amemskip\@
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
	bra.l	alskip\@
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
	beq.l	.anskip\@
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
	beq.l	.afskip\@
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
	beq.l	.alskip\@
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
	beq.l	.cldone\@
	killitem	\1
	bra.l	.clloop\@
.cldone\@	;
	endm

zerolist	macro	listname,size of item
	;
	;fill all list items with 0!
	;
	clearlist	\1
.zlloop\@	addlast	\1
	beq.l	.zlskip\@
	lea	8(a0),a1
	moveq	#0,d0
	move	#(\2-8)/2-1,d1
.zlloop2\@	move	d0,(a1)+
	dbf	d1,.zlloop2\@
	bra.l	.zlloop\@
.zlskip\@	clearlist	\1
	;
	endm

bwait	macro
	;
.bwait\@	btst	#6,$dff002
	beq.l	.bwait2\@
	bra.l	.bwait\@
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
	bne.l	cli
	;
	lea	$5c(a5),a0
	jsr	-384(a6)	;waitport
	lea	$5c(a5),a0
	jsr	-372(a6)	;get message
	move.l	d0,wbmess
	bra.l	wb
cli	;
	cmp.b	#'@',(a0)+
	bne.l	wb
	lea	tempfile,a1
	move.l	a1,map_test
.loop	move.b	(a0)+,(a1)
	beq.l	wb
	cmp.b	#10,(a1)+
	bne.l	.loop
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
	;
	move.l	wbmess(pc),d0
	beq.l	.nocd
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
	bcs.l	nomem
	;
	jsr	initmain
	bsr.l	bigfont
	;
.intro	move.l	medat(pc),a1
	move.l	titlemed(pc),a0
	jsr	8(a1)	;start title music!
	;
.intro2	jsr	dointro	;returns gametype
	;
	cmp	#3,gametype
	bcs.l	.play
	move.l	medat(pc),a1
	jsr	12(a1)
	bra.l	exittoos
.play	;
	bsr.l	initnewgame
	tst	gametype
	bmi.l	.intro2
	;
	bsr.l	smallfont
	tst	twowins
	beq.l	.n2
	bsr.l	swaphflags
.n2	bsr.l	execscript_med
.wmf	tst	fadevol
	bne.l	.wmf
	tst	twowins
	beq.l	.n22
	bsr.l	swaphflags
.n22	bsr.l	bigfont
	bra.l	.intro
	;
exittoos	bsr.l	freeobjlist2
	move	#$4000,$dff09a
	move.l	ciaa,a0
	movem.l	rawstuff,d0-d1
	movem.l	d0-d1,$64(a0)
	move	#$c000,$dff09a
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
	beq.l	.bye
	;
	move.l	4.w,a6
	move.l	d0,a1
	jsr	-378(a6)
	clr.l	wbmess
	;
.bye	rts

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
	beq.l	.skipx
	bpl.l	.x1
	bset	#0,d0
	bra.l	.skipx
.x1	bset	#1,d0
.skipx	tst	2(a0)
	beq.l	.skipy
	bpl.l	.y1
	bset	#2,d0
	bra.l	.skipy
.y1	bset	#3,d0
.skipy	tst	4(a0)
	beq.l	.skipb
	bset	#4,d0
.skipb	tst	6(a0)
	beq.l	.skipf
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
	beq.l	.skipx
	cmp	#1,d1
	bne.l	.x1
	move	#-1,(a0)
	bra.l	.skipx
.x1	move	#1,(a0)
.skipx	clr	2(a0)
	move	d0,d1
	and	#12,d1
	beq.l	.skipy
	cmp	#4,d1
	bne.l	.y1
	move	#-1,2(a0)
	bra.l	.skipy
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
.loop	bsr.l	.init
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

waitquiet	bsr.l	vwait
	lea	sfxs(pc),a0
	moveq	#3,d0
.loop	tst	fx_status(a0)
	bne.l	waitquiet
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
	beq.l	makesfx
	lea	fx_size(a1),a1
	dbf	d2,.loop
	;
	;OK, none free...check priorities
	;
	lea	sfxs(pc),a1
	moveq	#3,d2
.loop2	cmp	fx_priority(a1),d1
	bgt.l	queuesfx
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
	bsr.l	sfxoff
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
	bsr.l	playsfxnow
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
	bge.l	.skip
	addq	#1,fx_status(a1)
	blt.l	.skip
	;
	move.l	a2,-(a7)
	bsr.l	sfxoff
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
	move.l	player1,a5
	move.l	ob_palette(a5),-(a7)
	move.l	#palettesw,ob_palette(a5)
	move.l	ob_window(a5),a2
	jsr	plotwbmap
	;
	tst	twowins
	beq.l	.p1
	;
	move.l	player2,a5
	move.l	ob_palette(a5),-(a7)
	move.l	#palettesw,ob_palette(a5)
	move.l	ob_window(a5),a2
	jsr	plotwbmap
.p1	;
	bsr.l	drawall2
	;
	move.l	player1,a5
	lea	gamemenu,a4
	move.l	ob_window(a5),a6
	jsr	initmenu
	;
.loop	jsr	selmenu
	beq.l	.done
	;
	subq	#1,d0
	bne.l	.notpsize
	bsr.l	newpsize
	bra.l	.loop
	;
.notpsize	subq	#1,d0
	bne.l	.notwsize
	bsr.l	newwsize
	bra.l	.loop
	;
.notwsize	subq	#1,d0
	bne.l	.notlwin
	bsr.l	largewin
	bra.l	.loop
	;
.notlwin	subq	#1,d0
	bne.l	.notfloor
	;
	addq	#1,floorflag
	cmp	#2,floorflag
	bne.l	.fskip
	move	#-1,floorflag
.fskip	bsr.l	refresh
	bra.l	.loop
	;
.notfloor	subq	#1,d0
	bne.l	.notroof
	;
	addq	#1,roofflag
	cmp	#2,roofflag
	bne.l	.rskip
	move	#-1,roofflag
.rskip	bsr.l	refresh
	bra.l	.loop
.notroof	;
	move	#1,finished
	;
.done	jsr	finitmenu
	;
	tst	twowins
	beq.l	.p12
	;
	move.l	player2,a5
	move.l	(a7)+,ob_palette(a5)
	move.l	ob_window(a5),a2
	jsr	plotwbmap
	bsr.l	initstats
	bsr.l	showstats
.p12	;
	move.l	player1,a5
	move.l	(a7)+,ob_palette(a5)
	move.l	ob_window(a5),a2
	jsr	plotwbmap
	bsr.l	initstats
	bsr.l	showstats
	;
	move	#$20,$dff09a
	;
	move	(a7)+,linked
	beq.l	.nolink
	move	finished(pc),d0
	beq.l	.nolink
	bset	#7,d0
	bsr.l	serput
.nolink	move	(a7)+,framecnt
	clr	paused
	;
	move	#$8020,$dff09a
	;
	rts

freewindows	lea	window1,a0
	jsr	freewindow
	tst	twowins
	beq.l	.p1
	lea	window2,a0
	jsr	freewindow
.p1	rts

largewin	move.l	player1,a5
	bsr.l	large
	tst	twowins
	beq.l	refresh
	move.l	player2,a5
	bsr.l	large
	bra.l	refresh

large	move.l	ob_window(a5),a6
	move	wi_pw(a6),d2
	;
	cmp	#2,d2
	beq.l	.lhr
	;
	;large lo-res window!
	;
.lores	move	#324,d0
	move	#240,d1
	bra.l	thinkwin
	;
.lhr	bsr.l	swappsize
	bra.l	.lores
	;
	move	#180,d0
	move	#240,d1
	bra.l	thinkwin

newwsize	;window size stuff!
	;
	move.l	player1,a5
	bsr.l	swapwsize
	tst	twowins
	beq.l	refresh
	move.l	player2,a5
	bsr.l	swapwsize
	bra.l	refresh

swapwsize	;increment window size!
	;
	move.l	ob_window(a5),a6
	movem	wi_w(a6),d0-d1	;w,h
	move	wi_pw(a6),d2
	mulu	d2,d0
	mulu	d2,d1
	cmp	#2,d2
	beq.l	.hr
	;
	;lo-res!
	;
	cmp	#318,d0
	bcs.l	.inc
	move	#132,d0
	move	d0,d1
	bra.l	thinkwin
.inc	add	#24,d0
	move	d0,d1
	cmp	#240,d1
	bls.l	thinkwin
	move	#240,d1
	bra.l	thinkwin
	;
.hr	cmp	#180,d0
	bcs.l	.inc2
	tst	twowins
	bne.l	.min
	add	#18,d1
	cmp	#240,d1
	bls.l	thinkwin
.min	move	#132,d0
	move	d0,d1
	bra.l	thinkwin
.inc2	add	#24,d0
	move	d0,d1
	;
thinkwin	move	#180,d3	;max width!
	cmp	#2,d2
	beq.l	.gmax
	move	#318,d3
.gmax	cmp	d3,d0
	bls.l	.nm
	move	d3,d0
.nm	;
	cmp	#240,d1
	bls.l	.n240
	move	#240,d1
.n240	tst	twowins
	beq.l	.ggt
	move	#120,d1
.ggt	;
	move	#160,d3
	move	d0,d4
	lsr	#1,d4
	sub	d4,d3	;wi_x
	move	d3,wi_x(a6)
	;
	ext.l	d0
	divu	d2,d0
	move	d0,wi_w(a6)
	;
	tst	twowins
	bne.l	.skip3
	;
	move	#cy,d3
	move	d1,d4
	lsr	#1,d4
	sub	d4,d3
	move	d3,wi_y(a6)
	;		
.skip3	ext.l	d1
	divu	d2,d1
	move	d1,wi_h(a6)
	;
	rts

newpsize	;toggle pixel size between 2 and 3
	;
	;copy windows to temp so we can free 'em up later
	;
	move.l	player1,a5
	bsr.l	swappsize
	tst	twowins
	beq.l	refresh
	move.l	player2,a5
	bsr.l	swappsize
	;
refresh	jsr	dispoff
	jsr	finitmenu
	;
	bsr.l	freewindows
	bsr.l	putwindow
	;
	lea	window1,a0
	jsr	makewindow
	lea	window1,a0
	jsr	showwindow
	;
	tst	twowins
	beq.l	.p1
	;
	lea	window2,a0
	jsr	makewindow
	lea	window2,a0
	jsr	showwindow
	;
.p1	jsr	calcbpos
	;
	lea	gamemenu,a4
	lea	window1,a6
	jsr	initmenu2
	;
	bsr.l	drawall2
	jsr	dispon
	rts

swappsize	move.l	ob_window(a5),a6
	movem	wi_w(a6),d0-d1	;w,h
	move	wi_pw(a6),d2
	mulu	d2,d0
	mulu	d2,d1
	eor	#1,d2	;2,3...
	move	d2,wi_pw(a6)
	move	d2,wi_ph(a6)
	;
	bra.l	thinkwin

showflag	dc	0

showit	;don't show if beam in the way!
	;
	move	showflag(pc),d0
	beq.l	.rts
	;
	move.l	$dff004,d0
	lsr.l	#8,d0	;beampos
	and	#$1ff,d0
	;
	cmp	minbpos(pc),d0
	bcs.l	.show
	cmp	maxbpos(pc),d0
	bcs.l	.rts
	;
	;cmp	minbpos(pc),d0
	;bcc.s	.rts
	;
.show	clr	showflag
	lea	window1,a0
	jsr	showwindowq
	lea	window2,a0
	jmp	showwindowq
	;
.rts	rts

drawall2	bsr.l	drawall
	bsr.l	drawall
	bra.l	vwait

drawall	;
.wait	move	doneflag(pc),d0
	beq.l	.wait	;wait for update
	clr	doneflag
.wait2	move	showflag(pc),d0
	bne.l	.wait2
	;
	move.l	memory(pc),memat
	move.l	player1(pc),a5
	bsr.l	calcscene
	move.l	player1(pc),a5
	bsr.l	blitscene
	move.l	player1(pc),a5
	bsr.l	drawscene
	;
	move	twowins(pc),d0
	beq.l	.show
	;
	move.l	memory(pc),memat
	move.l	player2(pc),a5
	bsr.l	calcscene
	move.l	player2(pc),a5
	bsr.l	blitscene
	move.l	player2(pc),a5
	bsr.l	drawscene
	;
.show	st	showflag
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
	bne.l	.loop
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
printmess2	;a6=window, a4=message, d0=length of message, d6=Y
	;
	move	fontw(pc),d2
	lsr	#1,d2
	mulu	d2,d0
	move	#160,d7
	sub	d0,d7	;X
	;
.loop2	move.b	(a4)+,d2
	beq.l	.done
	cmp.b	#' ',d2
	beq.l	.spc
	cmp.b	#'\',d2
	beq.l	.spc
	cmp.b	#'0',d2
	bcs.l	.nnum
	cmp.b	#'9',d2
	bhi.l	.nnum
	sub.b	#'0',d2
	ext	d2
	bra.l	.here
.nnum	cmp.b	#"'",d2
	bne.l	.notap
	moveq	#57,d2
	bra.l	.here
.notap	cmp.b	#'!',d2
	bne.l	.notex
	moveq	#36,d2
	bra.l	.here
.notex	cmp.b	#'.',d2
	bne.l	.notfs
	moveq	#37,d2
	bra.l	.here
.notfs	cmp.b	#':',d2
	bne.l	.notcol
	moveq	#38,d2
	bra.l	.here
.notcol	cmp.b	#127,d2
	bne.l	.notcurs
	moveq	#39,d2
	bra.l	.here
.notcurs	and	#31,d2
	add	#9,d2
.here	move.l	font(pc),a0
	move.l	wi_bmap(a6),a1
	move	d7,d0
	move	d6,d1
	bsr.l	blit
	;
	move	pdelay(pc),d2
	subq	#1,d2
	bmi.l	.spc
	;
.pdloop	bsr.l	vwait
	bsr.l	checkany
	beq.l	.none
	move	#-1,pdelay
	moveq	#0,d2
.none	dbf	d2,.pdloop
	;
.spc	add	fontw(pc),d7
	bra.l	.loop2
.done	;
	rts

initstats	;
	;health...
	move.l	ob_window(a5),a0
	moveq	#2,d0
	add	wi_x(a0),d0
	move.l	wi_bmap(a0),a1
	move.l	font(pc),a0
	moveq	#2,d1
	moveq	#39,d2
	bsr.l	blit
	;
	;weapon...
	move.l	ob_window(a5),a0
	moveq	#2,d0
	add	wi_x(a0),d0
	move.l	wi_bmap(a0),a1
	move.l	font(pc),a0
	moveq	#12,d1
	moveq	#44,d2
	bra.l	blit

putstrip	;a0=window
	;
	move.l	wi_bmap(a0),a1
	move	wi_bh(a0),d0
	lsr	#2,d0
	mulu	#7*40,d0
	add.l	d0,a1		;dest
	move.l	wi_strip(a0),a0	;src
	;
	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.l	.bwait
	;
	move.l	#$9f00000,$dff040
	move.l	#-1,$dff044
	move	#0,$dff064
	move	#0,$dff066
	move.l	a0,$dff050
	move.l	a1,$dff054
	move	#(7*7)<<6+20,$dff058
	rts

loff	dc	0

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
	bsr.l	blit
	movem.l	(a7)+,d0-d2/a0-a1
	;
	move	#8,-(a7)
.loop	rol.l	#4,d2
	movem.l	d0-d2/a0-a1,-(a7)
	and	#15,d2
	move.l	font(pc),a0
	bsr.l	blit
	movem.l	(a7)+,d0-d2/a0-a1
	addq	#6,d0
	subq	#1,(a7)
	bne.l	.loop
	addq	#2,a7
	addq	#8,d1
	rts

showstats	;a5=player
	;
	;ok, hitpoints...
	;
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	;
	;lagtime...
	move.l	ob_window(a5),a0
	moveq	#2,d0
	add	wi_x(a0),d0
	move.l	wi_bmap(a0),a1
	move.l	font(pc),a0
	moveq	#22,d1
	move	lagtime(pc),d2
	bsr.l	blit
	;
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	;
	move.l	ob_window(a5),a0
	moveq	#44,d5
	add	wi_x(a0),d5
	moveq	#40,d4
	moveq	#0,d6
	move	ob_hitpoints(a5),d7
	;
.hploop	cmp	d7,d6
	bcs.l	.hpskip
	cmp	#25,d7
	bcc.l	.hpdone
	moveq	#41,d4
	moveq	#25,d7
	bra.l	.hploop
	;
.hpskip	move.l	font(pc),a0
	move.l	ob_window(a5),a1
	move.l	wi_bmap(a1),a1
	move	d5,d0
	moveq	#2,d1
	move	d4,d2
	bsr.l	blit
	addq	#2,d5
	addq	#1,d6
	bra.l	.hploop
.hpdone	;
	;show lives remaining...
	;
	move.l	ob_window(a5),a0
	move	wi_bw(a0),d5
	add	wi_x(a0),d5
	move	ob_lives(a5),d7
	beq.l	.lvdone
	subq	#1,d7
.lvloop	;
	move.l	font(pc),a0
	move.l	ob_window(a5),a1
	move.l	wi_bmap(a1),a1
	subq	#8,d5
	move	d5,d0
	moveq	#2,d1
	moveq	#43,d2
	bsr.l	blit
	dbf	d7,.lvloop
.lvdone	;
	;show weapons!
	;
	move.l	ob_window(a5),a0
	moveq	#44,d5
	add	wi_x(a0),d5
	moveq	#49,d4
	sub	ob_weapon(a5),d4	;0...4
	moveq	#1,d7
.wploop	;
	move.l	font(pc),a0
	move.l	ob_window(a5),a1
	move.l	wi_bmap(a1),a1
	move	d5,d0
	moveq	#12,d1
	moveq	#50,d2
	cmp.b	ob_reload(a5),d7
	blt.l	.nowp
	move	d4,d2
.nowp	bsr.l	blit
	;
	add	#10,d5
	addq	#1,d7
	cmp	#6,d7
	bcs.l	.wploop
	;
	rts

blit	;a0=shapetable to blit, a1=bitmap, d0=X, d1=Y, d2=char
	;
	add.l	4(a0,d2*4),a0
	;
	mulu	#280,d1
	add.l	d1,a1
	move	d0,d2
	asr	#3,d2
	add	d2,a1	;dest!
	move.l	a0,a2
	add.l	(a0),a2
	lea	8(a0),a3
	addq	#4,a0
	and	#15,d0
	ror	#4,d0
	;
	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.l	.bwait
	;
	move.l	a2,$dff050
	move.l	a3,$dff04c
	move.l	a1,$dff048
	move.l	a1,$dff054
	;
	move	d0,$dff042
	or	blitmode(pc),d0
	move	d0,$dff040
	move.l	#$ffff0000,$dff044
	moveq	#-2,d0
	move	d0,$dff064
	move	d0,$dff062
	moveq	#38,d0
	sub	(a0)+,d0
	move	d0,$dff060
	move	d0,$dff066
	move	(a0)+,$dff058
	;
	rts

blitmode	dc	$fca

pixsize	dc	0	;pixel size...at least 2!

pixelate	;pixel out the coplist...d0=pixelsize
	;
	move	d0,pixsize
	move	d0,d1
	;
	;pixel out vertically, then horizontally
	;
	move.l	cop(pc),a0
	lea	coloffs(pc),a1
	moveq	#0,d2	;x
	move	d1,d6
	lsr	#1,d6
.forx	;
	move.l	a0,a3
	lea	0(a1,d2*4),a2
	add.l	(a2),a3
	;
	move	d2,d5
	add	d6,d5
	cmp	width(pc),d5
	ble.l	.xok
	move	width(pc),d5
.xok	sub	d2,d5
	ble.l	.done
	subq	#1,d5
	;	
.loop2	moveq	#0,d3
	move.l	a3,a4
	move.l	a0,a5
	add.l	(a2)+,a5
	move	d1,d7
	lsr	#1,d7	;first Y add
.fory	;
	move	(a4),d0	;start column!
	move	d3,d4
	add	d7,d4
	cmp	hite(pc),d4
	ble.l	.yok
	move	hite(pc),d4
.yok	sub	d3,d4
	ble.l	.nextx
	subq	#1,d4
	;
.loop	move	d0,(a5)
	add	copmod(pc),a4
	add	copmod(pc),a5
	;
	dbf	d4,.loop
	;
.nexty	add	d7,d3
	move	d1,d7
	bra.l	.fory
	;
.nextx	dbf	d5,.loop2
	;
	add	d6,d2
	move	d1,d6
	bra.l	.forx
	;
.done	rts

makeqstrip	;
	;do a simple roof/floor strip for blitter to wack in...
	;
	cmp	#$100,con0poke
	bne.l	.doit
	rts
	;
.doit	move.l	qstrip(pc),a0
	move.l	darktable(pc),a1
	move.l	palette(pc),a2
	move.l	qstripbot(pc),a4
	moveq	#0,d2
	;
	move	floorflag(pc),d0
	bne.l	.fdone
	;
	move	camy(pc),d0
	neg	d0
	ext.l	d0
	lsl.l	#focshft,d0
	;
	move.b	qcols+1(pc),d2
	move.l	qstripbot(pc),a4
	move	maxy(pc),d1
	;
.floop	subq	#1,d1
	beq.l	.fdone
	;
	move.l	d0,d3
	divs	d1,d3
	cmp	#maxz,d3
	bcc.l	.fdone
	;
	move	0(a1,d3*2),d3	 ;darkness (0...15)
	move.l	0(a2,d3*4),a3	 ;pal to use
	move	0(a3,d2*2),-(a4) ;colour!
	;
	bra.l	.floop
	;
.fdone	move	roofflag(pc),d0
	bne.l	.rdone
	;
	move	#-256,d0
	sub	camy(pc),d0
	ext.l	d0
	lsl.l	#focshft,d0	;cam Y
	;
	move.b	qcols(pc),d2
	;
	move	miny(pc),d1	;SY
	;
.rloop	beq.l	.rdone
	;
	move.l	d0,d3
	divs	d1,d3
	cmp	#maxz,d3
	bcc.l	.rdone
	;
	move	0(a1,d3*2),d3	 ;darkness (0...15)
	move.l	0(a2,d3*4),a3	 ;pal to use
	move	0(a3,d2*2),(a0)+ ;colour!
	;
	addq	#1,d1
	bra.l	.rloop
.rdone	;
	moveq	#0,d0
.loop	cmp.l	a4,a0
	bcc.l	.done
	move.l	d0,(a0)+
	bra.l	.loop
	;
.done	rts

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
	muls	copmod(pc),d1
	move	d1,flatyadd2
	;
	move	d7,d0
	add	midy(pc),d0
	mulu	copmod(pc),d0
	add.l	cop(pc),d0
	add.l	coloffs(pc),d0
	move.l	d0,a2
.vloop	;
	;find Z on this scanline...
	;
	tst	d7
	beq.l	.rts
	move.l	flatcam(pc),d6
	divs	d7,d6	;d6.w = Z
	cmp	#maxz,d6
	bcc.l	.rts
	;
	move.l	darktable(pc),a5
	move	0(a5,d6*2),d5
	move.l	palette(pc),a5
	move.l	0(a5,d5*4),a5
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
	;move.l	d4,d2
	;asr.l	#1,d2
	;add.l	d2,d0
	;
	;move.l	d6,d2
	;asr.l	#1,d2
	;add.l	d2,d1
	;
	swap	d0
	add	camx(pc),d0
	swap	d1
	add	camz(pc),d1
	swap	d4
	swap	d6
	;
	move	d7,-(a7)
	moveq	#127,d7
	moveq	#0,d2
	moveq	#0,d3
	;
	move.l	a2,a3
	;
	move	wdiv32(pc),-(a7)
	;
.hloop2	moveq	#31,d5
	;
.hloop	tst	(a3)	;check destination!
	bne.l	.skip
	;
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	move.b	0(a0,d1),d3
	addx	d2,d0
	add.l	d6,d1
	move	0(a5,d3*2),(a3)
	addx	d2,d1
	addq	#4,a3
	dbf	d5,.hloop
	bra.l	.hhh
	;
.skip	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq	#4,a3
	dbf	d5,.hloop
	;
.hhh	addq	#4,a3
	subq	#1,(a7)
	bgt.l	.hloop2
	bne.l	.kl
	;
	move	wrem32(pc),d5
	bpl.l	.hloop
	;
.kl	move.l	(a7)+,d7
	add	flatyadd(pc),d7
	add	flatyadd2(pc),a2
	bra.l	.vloop
	;
.rts	rts

doanims	move.l	map_anim(pc),a0
	lea	textures,a1
	;
.loop	move	(a0)+,d0	;how many frames
	beq.l	.done
	movem	(a0)+,d1-d2	;first, delay
	subq	#1,(a0)+
	bgt.l	.loop
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
	bra.l	.loop
	;
.done	rts

dorots	;
	move.l	camrots2(pc),a6
	lea	rotpolys(pc),a5	;header!
	;
rotloop	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.done
	move	rp_speed(a5),d0
	beq.l	rotloop
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
	bne.l	morph
	;
.rot	movem	rp_cx(a5),d6-d7	;centre x,z
	and	#1023,d0
	lea	0(a6,d0*8),a4	;rotation matrix.
	;
.loop	bsr.l	rotter
	add	d6,d0
	add	d7,d1
	movem	d0-d1,zo_lx(a2)
	movem	d0-d1,zo_rx(a1)
	bsr.l	rotter
	movem	d0-d1,zo_na(a2)
	exg	d0,d1
	neg	d0
	movem	d0-d1,zo_a(a2)
	move.l	a2,a1
	lea	32(a2),a2
	dbf	d5,.loop
	;
	bra.l	rotloop
	;
.done	rts
	;
morph	tst	d0
	bgt.l	.dp
	moveq	#0,d0
.neg	neg	rp_speed(a5)
	bra.l	.skip2
.dp	cmp	#$4000,d0
	blt.l	.skip
	move	#$4000,d0
	btst	#1,rp_flags+1(a5)
	bne.l	.neg
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
	bsr.l	calcnormvec
	movem	d0-d1,zo_na(a2)
	exg	d0,d1
	neg	d0
	movem	d0-d1,zo_a(a2)
	lea	32(a2),a2
	dbf	d5,.loop2
	;
	bra.l	rotloop

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
	bcs.l	.ok
	asr.l	#1,d2
	mulu.l	#92681,d4:d3	;mult by sqr(2)
	move	d4,d3
	swap	d3
	bra.l	.fitit
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
	bpl.l	.xp
	neg	d3
.xp	move	d1,d4
	bpl.l	.zp
	neg	d4
.zp	;
	cmp	d4,d3
	bcc.l	.bg
	exg	d3,d4
.bg	;
	cmp	d3,d2
	bcc.l	.lo
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
	beq.l	.done
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
	beq.l	.kill
	cmp	#$4000,d0
	bne.l	.loop
	;
.kill	move.l	a5,a0
	killitem	doors
	move.l	a0,a5
	bra.l	.loop
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
	beq.l	.rts
	subq	#1,d0
	beq.l	exec_addobj	;1 - add an object (alien etc)
	subq	#1,d0
	beq.l	exec_opendoor	;2 - open a door
	subq	#1,d0
	beq.l	exec_teleport	;3 - teleport
	subq	#1,d0
	beq.l	exec_loadobjs	;4 - load objects
	subq	#1,d0
	beq.l	exec_changetxt	;5 - change texture
	subq	#1,d0
	beq.l	exec_rotpolys	;6 - start polygons rotating!
	;
	warn	#$f0f
	;
.rts	tst	doorsfxflag
	beq.l	.nodoor
	clr	doorsfxflag
	move.l	doorsfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr.l	playsfx
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
	bra.l	exec_loop

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
	bra.l	exec_loop

exec_teleport	move.l	eventobj(pc),a0
	;
	move	(a6)+,ob_telex(a0)
	addq	#2,a6
	move	(a6)+,ob_telez(a0)
	move	(a6)+,ob_telerot(a0)
	;
	move	finished(pc),d0
	or	finished2(pc),d0
	bne.l	exec_loop
	;
	tst	-6(a6)	;teleport? or lock!
	beq.l	.tele
	;
	;LOCK!
	cmp.l	#playerlogic,ob_logic(a0)
	bne.l	exec_loop
	;
	move	changedtxt(pc),d0
	lea	textures(pc),a1
	move.l	0(a1,d0*4),a1
	lea	65<<6+1(a1),a2
	lea	10*65+19(a1),a1
	movem.l	a1-a2,deftxt
	;
	move.l	#locklogic,ob_logic(a0)
	bra.l	exec_loop
.tele	;
	move	#2,ob_pixsizeadd(a0)
	bsr.l	dotelesfx
	bra.l	exec_loop

dotelesfx	move.l	telesfx(pc),a0
	moveq	#64,d0
	moveq	#10,d1
	bra.l	playsfx

exec_loadobjs	;
.loop	move	(a6)+,d0
	bmi.l	.done
	bsr.l	loadanobj
	bra.l	.loop
.done	;
	bra.l	exec_loop
	
loadanobj	;d0=object#...sys must be permitted
	;
	lea	objinfo,a2
	mulu	#objinfof-objinfo,d0
	move.l	_ob_shape-objinfo(a2,d0),a2
	lea	8(a2),a3	;filename
	;
	tst.l	(a2)
	bne.l	.skip
	move.l	a3,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,(a2)
	beq.l	.skip
	move.l	d0,a0
	jsr	remapanim
.skip	;
	tst.l	4(a2)
	bne.l	.rts
	move.l	a3,a0
.loop	tst.b	(a3)+
	bne.l	.loop
	move.b	#'2',-(a3)
	moveq	#1,d1
	jsr	loadfile
	clr.b	(a3)
	move.l	d0,4(a2)
	beq.l	.rts
	move.l	d0,a0
	jsr	remapanim
	;
.rts	rts

exec_rotpolys	;
	;could also be morphpolys depending on bit 0 of flags!
	;
	addlast	rotpolys
	bne.l	.ok
	addq	#8,a6
	bra.l	exec_loop
	;
.ok	st	doorsfxflag
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
	beq.l	.rot
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
	bra.l	exec_loop
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
	bra.l	exec_loop

exec_addobj	clr.l	dummy
	move	(a6)+,d0	;monster type
	lea	objinfo,a2
	mulu	#objinfof-objinfo,d0
	add.l	d0,a2
	move.l	(a2)+,a3
	tst.l	(a3)
	beq.l	.ok
.no	addq	#8,a6
	bra.l	exec_loop
.ok	cmp	#2,-2(a6)	;player?
	bcc.l	.notp
	addfirst	objects
	bra.l	.bum
.notp	addlast	objects
.bum	beq.l	.no
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
	bsr.l	calcvecs
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
	bsr.l	rnddelay
	;
	bra.l	exec_loop

rnddelay	move	ob_range(a5),d0
	bsr.l	rndn
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
	bne.l	.skip
	lea	rndtable+110(pc),a0
.skip	move.l	a0,j_index
	move.l	k_index(pc),a0
	add	-(a0),d0
	move	d0,(a0)
	cmp.l	a0,a1
	bne.l	.skip2
	lea	rndtable+110(pc),a0
.skip2	move.l	a0,k_index
	movem.l	(a7)+,a0/a1
	rts

rndtable	ds.w	55
k_index	dc.l	0
j_index	dc.l	0

rndl	bsr.l	rndw
	move	d0,d1
	bsr.l	rndw
	swap	d0
	move	d1,d0
	rts

rndn	move	d0,d1
	bsr.l	rndw
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
	bne.l	.skip
	lea	rndtable2+110(pc),a0
.skip	move.l	a0,j_index2
	move.l	k_index2(pc),a0
	add	-(a0),d0
	move	d0,(a0)
	cmp.l	a0,a1
	bne.l	.skip2
	lea	rndtable2+110(pc),a0
.skip2	move.l	a0,k_index2
	movem.l	(a7)+,a0/a1
	rts

rndtable2	ds.w	55
k_index2	dc.l	0
j_index2	dc.l	0

rndl2	bsr.l	rndw2
	move	d0,d1
	bsr.l	rndw2
	swap	d0
	move	d1,d0
	rts

rndn2	move	d0,d1
	bsr.l	rndw2
	mulu	d1,d0
	swap	d0
	rts

calcangle2	;angle of camera to object in a5
	;
	move	camx(pc),d0
	sub	ob_x(a5),d0
	move	camz(pc),d1
	sub	ob_z(a5),d1
	bra.l	calcangle_

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
	bpl.l	.hpos
	moveq	#16,d2
	neg	d1
.hpos	tst	d0
	bpl.l	.wpos
	eor	#8,d2
	neg	d0
.wpos	cmp	d1,d0
	bmi.l	.notsteep
	bne.l	.neq
	move	#$2000,d1
	bra.l	.flow
.neq	eor	#4,d2
	exg	d1,d0
.notsteep	tst	d1
	bne.l	.noflow
	moveq	#0,d1
	bra.l	.flow
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

currplayer	dc.l	0

calcscene	;a5=player object
	;
	move	#$20,$dff09a
	;
	move.l	a5,currplayer
	move.l	ob_palette(a5),palette
	move	ob_thermo(a5),thermo
	move	ob_infra(a5),infra
	move	ob_pixsize(a5),pixsize
	;
	clr.l	shapelist
	move.l	a5,a0
	bsr.l	calccamera
	bsr.l	makewalls
	;
	lea	objects(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.done
	cmp.l	currplayer(pc),a5
	beq.l	.loop
	move.l	ob_render(a5),a0
	tst	ob_invisible(a5)
	beq.l	.notinvs
	bpl.l	.hb
	move.l	#drawobjtrans,shaperender
	bra.l	.rit
.hb	move.l	#drawobjinvs,shaperender
.rit	jsr	(a0)
	move.l	#drawobjnorm,shaperender
	bra.l	.loop
.notinvs	jsr	(a0)
	bra.l	.loop
.done	;
	lea	gore(pc),a5
	;
.loop2	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.done2
	;
	movem	go_x(a5),d0/d2
	moveq	#0,d1
	move.l	go_shape(a5),a0
	move	#$200,d7
	bsr.l	drawshape_q
	;
	bra.l	.loop2
	;
.done2	move	#$8020,$dff09a
	;
	rts

blitscene	;
	bclr	#7,ob_update(a5)
	beq.l	.noupdate
	;
	bclr	#7,ob_update+1(a5)
	beq.l	.stats
	;
	move.l	ob_window(a5),a2
	moveq	#9,d0
	jsr	wcopy
	bsr.l	initstats
	;
.stats	bsr.l	showstats
	;
.noupdate	move	ob_messtimer(a5),d0
	bpl.l	.mskip
	addq	#1,d0
	beq.l	.mdone
	neg	ob_messtimer(a5)
	move.l	ob_window(a5),a0
	bsr.l	putstrip
	bsr.l	printmess
	bra.l	.mskip
	;
.mdone	clr	ob_messtimer(a5)
	move.l	ob_window(a5),a0
	bsr.l	putstrip
.mskip	;
	rts

drawscene	;a5=player
	;
	move.l	ob_window(a5),a0
	bsr.l	dbwindow
	;
	bsr.l	castwalls
	bsr.l	makeqstrip
	bsr.l	renderwalls
	;
	move	floorflag(pc),d0
	ble.l	.nofloor
	;
	move	camy(pc),d0
	neg	d0
	moveq	#-1,d1
	move	maxy(pc),d7
	subq	#1,d7
	move.l	floor(pc),a0
	bsr.l	flat
	;
.nofloor	move	roofflag(pc),d0
	ble.l	.noflat
	;
	move	#-255,d0
	sub	camy(pc),d0
	moveq	#1,d1
	move	miny(pc),d7
	move.l	roof(pc),a0
	bsr.l	flat
	;
.noflat	bsr.l	drawshapes
	bsr.l	drawblood
	;
	move.l	currplayer(pc),a0
	move	ob_pixsize(a0),d0
	bne.l	pixelate
	rts

chatstuff	move	chatok(pc),d0
	beq.l	.rts
	;
	move	chatoutget(pc),d0
	cmp	chatoutput(pc),d0
	beq.l	.noout
	and	#31,d0
	lea	chatout(pc),a0
	move.b	0(a0,d0),d0	;chat out character!
	addq	#1,chatoutget
	moveq	#1,d1
	move	d0,-(a7)
	bsr.l	chatprintout
	move	(a7)+,d0
	sub.b	#32,d0	;encode for chat
	bset	#6,d0
	bsr.l	serput
	;
.noout	move	chatcnt(pc),d0
	beq.l	.rts
	;
	move	chatinget(pc),d0
	and	#31,d0
	lea	chatin(pc),a0
	move.b	0(a0,d0),d0
	addq	#1,chatinget
	subq	#1,chatcnt
	moveq	#2,d1
	bsr.l	chatprintin
	;
.rts	rts

sfxvbint	lea	sfxs(pc),a1
	moveq	#3,d3
	;
.loop	tst	fx_status(a1)
	ble.l	.skip
	;
	;this one queued! gotta play it...
	;
	subq	#1,fx_status(a1)
	bgt.l	.skip
	move.l	fx_sfx(a1),a0
	bsr.l	playsfxnow
	;
.skip	lea	fx_size(a1),a1
	dbf	d3,.loop
	;
	;fade out song if nec.
	;
	move	fadevol(pc),d0
	beq.l	.nofade
	move.l	medat(pc),a1
	sub	#$80,fadevol
	bgt.l	.setvol
	clr	fadevol
	jmp	12(a1)	;stop song
	bra.l	.nofade
	;
.setvol	move	fadevol(pc),d0
	lsr	#8,d0
	jmp	16(a1)	;set volume
	;
.nofade	rts

	dc.l	readmodem
joytable	dc.l	readjoy1,readjoy0,readkeys,readcd321,readcd320

readjoy	;a0=player
	move	ob_cntrl(a0),d0
	bmi.l	readmodem
	;
	lea	joyx0(pc),a0
	lea	0(a0,d0*8),a0
	move.l	joytable(pc,d0*4),a1
	jsr	(a1)
	move	linked(pc),d0
	bne.l	.send
	rts
.send	;
	;a0=cntrl block
	;
	bsr.l	encodejoy
	movem.l	d0/a0,-(a7)
	bsr.l	serput
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
	bra.l	decodejoy
readmodem	;
	bsr.l	rbfchk
	bne.l	.serhere
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
	beq.l	.vw
	;
	move	#$20,$dff09c
	bsr.l	chatstuff
	bra.l	readmodem
	;
.serhere	bsr.l	serget
	lea	joyxs(pc),a0
	bclr	#7,d0
	beq.l	.djoy
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
.sgot	bsr.l	decodejoy
	move.l	(a0)+,joyx
	move.l	(a0),joyb
	rts

escape	dc	0

readjoys	;fill in appropriate 'joyxn' block...check escape
	;
	move	finished(pc),d0
	or	finished2(pc),d0
	bne.l	.rts
	;
	qkey	$45
	sne	escape
	;
	move.l	player1(pc),a0
	bsr.l	readjoy
	move	gametype(pc),d0
	beq.l	.rts
	move.l	player2(pc),a0
	bra.l	readjoy
	;
.rts	rts

lrnd	dc	0

vbhandler	movem.l	d2-d7/a2-a6,-(a7)
	;
	subq	#1,(a1)+	;inc/dec frame counters
	addq	#1,(a1)
	;
	;this done every frame!
	bsr.l	showit
	bsr.l	chatstuff
	bsr.l	sfxvbint
	;
	btst	#0,framecnt+1
	beq.l	exit_vb
	tst	paused
	bne.l	exit_vb
	;
	;OK, movement/animation stuff!
	;
	bsr.l	readjoys
	bsr.l	doanims
	bsr.l	dorots
	bsr.l	dodoors
	bsr.l	moveblood
	;
	ifne	debugser
	;
	;OK, kludge in a random number!
	move	framecnt(pc),d0
	and	#126,d0
	bne.l	.nornd
	;
	bsr.l	rndw
	move	lrnd(pc),d1
	move	d0,lrnd
	cmp	d0,d1
	bne.l	.hi
	warn	#$fff
	warn	#$00f
.hi	lea	.rndasc(pc),a0
	moveq	#3,d1
.loop	rol	#4,d0
	move	d0,d2
	and	#15,d2
	add	#48,d2
	cmp	#58,d2
	bcs.l	.rok
	addq	#7,d2
.rok	move.b	d2,(a0)+
	dbf	d1,.loop
	;
	move.l	player1(pc),a5
	bsr.l	message
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
	beq.l	exit_vb
	;
	move.l	ob_logic(a5),a0
	jsr	(a0)
	;
	;check collision!
	;
	move	ob_collwith(a5),d0
	beq.l	obj_loop
	;
	move	ob_rad(a5),d1
	move	ob_x(a5),d6
	move	ob_z(a5),d7
	;
	lea	objects(pc),a0
	;
.loop2	move.l	(a0),a0
	cmp.l	a5,a0
	bne.l	.this
	;
	clr.l	ob_washit(a5)	;not hit! can get hit next time...
	bra.l	obj_loop
.this	;
	move	ob_colltype(a0),d2
	and	d0,d2
	beq.l	.loop2
	;
	move	ob_rad(a0),d2
	add	d1,d2	;r sum
	;
	move	ob_x(a0),d3
	sub	d6,d3
	bpl.l	.xpl
	neg	d3
.xpl	cmp	d2,d3
	bcc.l	.loop2
	;
	move	ob_z(a0),d4
	sub	d7,d4
	bpl.l	.ypl
	neg	d4
.ypl	cmp	d2,d4
	bcc.l	.loop2
	;
	mulu	d2,d2
	mulu	d3,d3
	mulu	d4,d4
	add.l	d4,d3
	cmp.l	d2,d3
	bcc.l	.loop2
	;
	cmp.l	ob_washit(a5),a0
	beq.l	obj_loop
	move.l	a0,ob_washit(a5)
	;
	move	finished2(pc),d0
	bne.l	obj_loop
	;
	move.l	#killobject3,killjsr
	movem.l	a0/a5,obj_a0
	exg.l	a0,a5
	;
	move	ob_damage(a0),d0
	move.l	ob_hit(a5),a1
	sub	d0,ob_hitpoints(a5)
	bgt.l	hit_skip
	move.l	ob_die(a5),a1
	;
hit_skip	jsr	(a1)
	;
hit_ret	move.l	#killobject2,killjsr
	movem.l	obj_a0(pc),a0/a5
	;
	move	ob_damage(a0),d0
	move.l	ob_hit(a5),a1
	sub	d0,ob_hitpoints(a5)
	bgt.l	hit_skip2
	move.l	ob_die(a5),a1
	;
hit_skip2	jsr	(a1)
	bra.l	obj_loop
	;
exit_vb	st	doneflag
	bsr.l	showit
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
	bra.l	obj_loop

killobject3	move.l	a5,a0
	killitem	objects
	move.l	obj_stack(pc),a7
	bra.l	hit_ret

bloodspeed	bsr.l	rndw
	ext.l	d0
	lsl.l	#2,d0
	rts

bloodspeed2	bsr.l	rndw
	ext.l	d0
	lsl.l	#5,d0
	rts

bloodspeed3	bsr.l	rndw
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
	beq.l	.rts
	movem.l	d2-d4,ob_x(a0)
	bsr.l	bloodspeed2
	move.l	d0,ob_xvec(a0)
	bsr.l	bloodspeed2
	move.l	d0,ob_yvec(a0)
	bsr.l	bloodspeed2
	move.l	d0,ob_zvec(a0)
	move.l	a2,ob_shape(a0)
	move	d5,ob_frame(a0)
	move.l	#sparkslogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	bsr.l	rndw
	and	#15,d0
	add	#15,d0
	move	d0,ob_delay(a0)
	dbf	d5,.loop
.rts	rts

sparkslogic	subq	#1,ob_delay(a5)
	ble.l	killobject
	movem.l	ob_x(a5),d0-d2
	add.l	ob_xvec(a5),d0
	add.l	ob_yvec(a5),d1
	add.l	ob_zvec(a5),d2
	movem.l	d0-d2,ob_x(a5)
	rts

bloodymess	;throw random blood splots everywhere!
	;
	bsr.l	bloodspeed2
	add.l	ob_x(a5),d0
	move.l	d0,d2
	bsr.l	bloodspeed2
	add.l	ob_gutsy(a5),d0
	move.l	d0,d3
	bsr.l	bloodspeed2
	add.l	ob_z(a5),d0
	move.l	d0,d4
	;
.loop	addlast	blood
	beq.l	.done
	;
	movem.l	d2-d4,bl_x(a0)
	bsr.l	bloodspeed
	move.l	d0,bl_xvec(a0)
	bsr.l	bloodspeed
	move.l	d0,bl_yvec(a0)
	bsr.l	bloodspeed
	move.l	d0,bl_zvec(a0)
	move	ob_blood(a5),bl_color(a0)
	;
	dbf	d7,.loop
	;
.done	rts

bloodymess2	;throw random blood splots everywhere!
	;
	bsr.l	bloodspeed2
	add.l	ob_x(a5),d0
	move.l	d0,d2
	bsr.l	bloodspeed2
	add.l	ob_gutsy(a5),d0
	move.l	d0,d3
	bsr.l	bloodspeed2
	add.l	ob_z(a5),d0
	move.l	d0,d4
	;
.loop	addlast	blood
	beq.l	.done
	;
	movem.l	d2-d4,bl_x(a0)
	bsr.l	bloodspeed3
	move.l	d0,bl_xvec(a0)
	bsr.l	bloodspeed3
	move.l	d0,bl_yvec(a0)
	bsr.l	bloodspeed3
	move.l	d0,bl_zvec(a0)
	move	ob_blood(a5),bl_color(a0)
	;
	dbf	d7,.loop
	;
.done	rts

chunklogic	move	mode(pc),d0
	beq.l	chunklogic2
	;
	add.l	#$8000,ob_yvec(a5)
	move.l	ob_yvec(a5),d0
	add.l	ob_y(a5),d0
	blt.l	.skip
	;
	;OK...hit ground!
	;
	bsr.l	splat
	addlast	gore
	bne.l	.gok
	;
	move.l	gore(pc),a0
	killitem	gore
	addlast	gore
	beq.l	killobject
	;
.gok	move	ob_x(a5),go_x(a0)
	move	ob_z(a5),go_z(a0)
	move.l	ob_shape(a5),a1
	move	ob_frame(a5),d0
	add.l	12(a1,d0*4),a1
	move.l	a1,go_shape(a0)
	;
	bra.l	killobject
	;
.skip	move.l	d0,ob_y(a5)
	bsr.l	checkvecs
	beq.l	.rts
	clr.l	ob_xvec(a5)
	clr.l	ob_zvec(a5)
.rts	rts

chunklogic2	add.l	#$8000,ob_yvec(a5)
	move.l	ob_yvec(a5),d0
	add.l	d0,ob_y(a5)
	blt.l	.ok
	;bsr	splat
	bra.l	killobject
.ok	movem.l	ob_xvec(a5),d0-d1
	add.l	d0,ob_x(a5)
	add.l	d1,ob_z(a5)
	rts

splat	move.l	splatsfx(pc),a0
	moveq	#32,d0
	moveq	#-1,d1
	bra.l	playsfx

blowterra	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#20,d1
	bsr.l	playsfx
	bra.l	blowquick

blowdragon	;same, but messier...
	;
	;loud!
	;
	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr.l	playsfx
	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr.l	playsfx
	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr.l	playsfx
	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr.l	playsfx
	;
	moveq	#63,d7
	bsr.l	bloodymess2
	;
	move.l	ob_chunks(a5),a4
	bsr.l	blowchunx
	bsr.l	blowchunx
	bsr.l	blowchunx
	bsr.l	blowchunx
	;
	move.l	#dragondead,ob_logic(a5)
	move.l	#rts,ob_render(a5)
	clr	ob_colltype(a5)
	clr	ob_collwith(a5)
	move	#127,ob_delay(a5)
	rts

dragondead	subq	#1,ob_delay(a5)
	bgt.l	.rts
	;
	move	#3,finished
	;
.rts	rts

blowdeath	cmp.l	sucker(pc),a5
	bne.l	blowobject
	clr.l	sucker
	clr.l	sucking
	;
blowobject	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr.l	playsfx
blowquick	;
	moveq	#31,d7
	bsr.l	bloodymess2
	;
	move.l	ob_chunks(a5),d0
	bne.l	.chok
	;
	moveq	#15,d7
	bsr.l	bloodymess2
	bra.l	killobject
	;
.chok	move.l	d0,a4
	bsr.l	blowchunx
	bra.l	killobject

blowchunx	move	2(a4),d7
	subq	#1,d7
	;
.loop	addlast	objects
	beq.l	killobject
	movem.l	ob_x(a5),d0-d2
	move.l	#-64<<16,d1
	movem.l	d0-d2,ob_x(a0)
	;
	bsr.l	bloodspeed3
	move.l	d0,ob_xvec(a0)
	bsr.l	bloodspeed3
	sub.l	#$40000,d0
	move.l	d0,ob_yvec(a0)
	bsr.l	bloodspeed3
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
	bne.l	.rts
	;
	bsr.l	pickplayer
	cmp.l	#playerlogic,ob_logic(a0)
	bne.l	.rts
	;
	move.l	a0,sucking
	move.l	a5,sucker
	;
	move	ob_rot(a5),ob_oldrot(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#deathsuck,ob_logic(a5)
	move.l	#rts,ob_hit(a5)
	move	#64,ob_delay(a5)
	bra.l	deathsuck
	;
.rts	rts

deathsuck	;death head sucking out a players soul!
	;
	bsr.l	deathbounce
	bsr.l	deathanim
	subq	#1,ob_delay(a5)
	bgt.l	.more
	move	ob_oldrot(a5),ob_rot(a5)
	move.l	ob_oldlogic(a5),ob_logic(a5)
	move.l	#hurtdeath,ob_hit(a5)
	clr.l	sucker
	clr.l	sucking
	bra.l	rnddelay
	;
.more	move.l	sucking(pc),a0
	move.l	a0,a2
	bsr.l	calcangle	;point at player!
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
	bsr.l	addsoul
	;
.rts	rts

sucker	dc.l	0
sucking	dc.l	0
suckangle	dc.l	0

addsoul	;d7 times!
	;
	addlast	blood
	beq.l	.rts
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
	bsr.l	rndw
	and	#63,d0
	sub	#32,d0
	add	d2,d0
	move	d0,bl_x(a0)
	;
	bsr.l	rndw
	and	#63,d0
	sub	#32,d0
	add	#110,d0
	move	d0,bl_y(a0)	;>0= funny blood!
	;
	bsr.l	rndw
	and	#63,d0
	sub	#32,d0
	add	d3,d0
	move	d0,bl_z(a0)
	;
	bsr.l	rndw
	and	#1,d0
	move	soulcols(pc,d0*2),bl_color(a0)
	;
	dbf	d7,addsoul
	;
.rts	rts

soulcols	dc	$0ff,$0f0

hurtghoul	moveq	#31,d7
	bsr.l	bloodymess
	rts

hurtterra	move.l	a0,-(a7)
	move.l	shootsfx2(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr.l	playsfx
	move.l	(a7)+,a0
	bra.l	hurtobject

hurtngrunt	move.l	a0,-(a7)
	bsr.l	rndw
	and	#3,d0
	cmp	lastgrunt(pc),d0
	bne.l	.new
	addq	#1,d0
	and	#3,d0
.new	move	d0,lastgrunt
	lea	grunttable(pc),a0
	move.l	0(a0,d0*4),a0
	move.l	(a0),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr.l	playsfx
	move.l	(a7)+,a0
	;
hurtobject	move	ob_colltype(a0),d0
	and	#24,d0
	bne.l	.rts
	;
	moveq	#23,d7
	bsr.l	bloodymess
	move	ob_hurtpause(a5),ob_hurtwait(a5)
	beq.l	.rts
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
	bsr.l	playsfx
	move.l	(a7)+,a0
	bra.l	hurtobject

trollhurt	move.l	a0,-(a7)
	move.l	trollhitsfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr.l	playsfx
	move.l	(a7)+,a0
	bra.l	hurtobject

pauselogic2	subq	#1,ob_hurtwait(a5)
	bgt.l	.rts
	clr	ob_frame(a5)
	move.l	ob_oldlogic2(a5),ob_logic(a5)
	move.l	ob_oldhit(a5),ob_hit(a5)
.rts	rts

pauselogic	subq	#1,ob_delay(a5)
	bgt.l	.skip
	;
	bsr.l	rnddelay
	move.l	ob_oldlogic(a5),ob_logic(a5)
	;
	;if in front of player, continue on old course...
	;
	bsr.l	pickcalc
	;
	move	ob_rot(a0),d1
	and	#255,d1
	sub	d0,d1
	bpl.l	.pl
	neg	d1
.pl	cmp	#64,d1
	bcs.l	.skip
	cmp	#192,d1
	bcc.l	.skip
	;
.useold	move	ob_oldrot(a5),ob_rot(a5)
	bsr.l	calcvecs
	;
.skip	rts

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
	beq.l	.rts
	;
	move	ob_bouncecnt(a5),ob_bouncecnt(a0)
	move	ob_x(a5),ob_x(a0)
	move	ob_y(a5),d0
	add	ob_firey(a5),d0
	move	d0,ob_y(a0)
	move	ob_z(a5),ob_z(a0)
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
	;add.l	d0,ob_x(a0)
	;add.l	d1,ob_z(a0)
	;
	move	#32,ob_rad(a0)
	move.l	#32*32,ob_radsq(a0)
	;
.rts	rts

pickcalc	;pick a player and calculate angle to player!
	;
	bsr.l	pickplayer
	bsr.l	calcangle
	tst	ob_invisible(a0)
	beq.l	.rts
	move	d0,-(a7)
	bsr.l	rndw
	and	#63,d0
	sub	#32,d0
	add	(a7)+,d0
	and	#255,d0
.rts	rts

fire1	bsr.l	pickcalc
	;
	;random noise for inaccuracy!
	;
	move	d0,-(a7)
	bsr.l	rndw
	and	#31,d0
	sub	#16,d0
	add	(a7)+,d0
	and	#255,d0
	;
	move	d0,ob_rot(a5)
	bsr.l	calcvecs
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
	bsr.l	shoot
	;
	rts

pickplayer	;pick nearest player
	;
	move.l	player1(pc),a0
	move	gametype(pc),d0
	beq.l	.rts
	move.l	player2(pc),a1
	move	linked(pc),d0
	bpl.l	.nosw
	exg	a0,a1
.nosw	;
	tst	ob_hitpoints(a0)
	beq.l	.sw
	tst	ob_hitpoints(a1)
	beq.l	.rts
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
	bcs.l	.rts
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
	bpl.l	.xpl
	neg	d3
.xpl	cmp	d2,d3
	bcc.l	.no
	;
	move	ob_z(a0),d4
	sub	ob_z(a5),d4
	bpl.l	.ypl
	neg	d4
.ypl	cmp	d2,d4
	bcc.l	.no
	;
	mulu	d2,d2
	mulu	d3,d3
	mulu	d4,d4
	add.l	d4,d3
	cmp.l	d2,d3
	bcc.l	.no
	;
	moveq	#-1,d0
	rts
	;
.no	moveq	#0,d0
	rts

baldycharge	;
	;baldy charging at player!
	;
	bsr.l	checkvecs
	beq.l	baldy_skip
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
	bsr.l	rnddelay
	;
	bra.l	monsterfix
	;
baldy_skip	;close to player? start throwing punches around!
	;
	bsr.l	pickcalc
	;
	sub	ob_rot(a5),d0
	cmp	#32,d0
	bgt.l	baldy_tonorm
	cmp	#-32,d0
	blt.l	baldy_tonorm
	;
	move.l	a0,ob_washit(a5)
	bsr.l	checkcoll
	beq.l	monsternew	;no collisions!
	;
	;go into punch mode!
	;
	move.l	#baldypunch,ob_logic(a5)
	move	ob_punchrate(a5),ob_delay(a5)
	clr.l	ob_frame(a5)
	rts

baldypunch	;
	bsr.l	pickplayer
	bsr.l	checkcoll
	bne.l	.doit
	;
	clr.l	ob_frame(a5)
	bra.l	baldy_tonorm
	;
.doit	subq	#1,ob_delay(a5)
	ble.l	.punch
	rts
.punch	move	ob_punchrate(a5),ob_delay(a5)
	moveq	#0,d0	;stand frame
	cmp	ob_frame(a5),d0
	bne.l	.skip
	;
	clr.l	ob_washit(a5)	;punch!
	bsr.l	calcangle
	move	d0,ob_rot(a5)
	moveq	#5,d0
.skip	move	d0,ob_frame(a5)
	rts

calcbangle	bsr.l	calcangle
	tst	ob_invisible(a0)
	beq.l	.notinv
	;
	;invisible, add some randomeness!
	;
	move	d0,-(a7)
	bsr.l	rndw
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
	bgt.l	monstermove	;charge?
	;
	bsr.l	pickcalc	;pic player in a0!
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#320*320,d0
	bcc.l	bl2
	;
	move.l	trollsfx(pc),a0
	moveq	#64,d0
	moveq	#5,d1
	bsr.l	playsfx
	;
	bra.l	bl2

lizardlogic	;
	subq	#1,ob_delay(a5)
	bgt.l	monstermove	;charge?
	;
	bsr.l	pickcalc	;pic player in a0!
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#256*256,d0
	bcc.l	bl2
	;
	move.l	lizsfx(pc),a0
	moveq	#32,d0
	moveq	#5,d1
	bsr.l	playsfx
	;
	bra.l	bl2

baldylogic	;
	;OK, what can baldy do...
	;
	;how about, walk around similar to the marine, but randomly 
	;charge at you?
	;
	;then, if he's close enough, he throws a punch!
	;
	subq	#1,ob_delay(a5)
	bgt.l	monstermove	;charge?
	;
bl2	bsr.l	pickcalc
	move	d0,ob_rot(a5)
	;
	move.l	ob_movspeed(a5),d0
	lsl.l	#2,d0
	move.l	d0,ob_movspeed(a5)
	move.l	ob_framespeed(a5),d0
	lsl.l	#2,d0
	move.l	d0,ob_framespeed(a5)
	;
	bsr.l	calcvecs
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#baldycharge,ob_logic(a5)
	;
	rts

terralogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	ble.l	.fire
	;
	move	ob_delay(a5),d0
	and	#31,d0
	bne.l	monstermove
	;
	move.l	robotsfx(pc),a0
	moveq	#64,d0
	moveq	#10,d1
	bsr.l	playsfx
	bra.l	monstermove
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
	bgt.l	.rts
	;
	move	ob_firerate(a5),ob_delay(a5)
	;
	;OK, to to face player and fire away!
	;
	bsr.l	pickcalc
	move	d0,ob_rot(a5)
	bsr.l	calcvecs
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#16,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet4,a2
	lea	sparks4,a3
	;
	bsr.l	shoot
	;
	move.l	shootsfx3(pc),a0
	moveq	#32,d0
	moveq	#5,d1
	bsr.l	playsfx
	;
	subq	#1,ob_delay2(a5)
	bgt.l	.rts
	;
	bsr.l	rnddelay
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
	bsr.l	pickcalc
	move	d0,ob_rot(a5)
	;
	subq	#1,ob_delay(a5)
	bgt.l	.skip
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
	bsr.l	shoot
	bsr.l	rnddelay
	;
.skip	;OK, ghoul moves around ignoring walls!
	;
	;he's pointed at player...how about randomly selected to make 
	;this his new movement vector?
	;
	bsr.l	rndw
	move	ob_movspeed(a5),d1
	lsl	#8,d1
	cmp	d1,d0
	bcc.l	.no
	;
	bsr.l	calcvecs
	;
	move.l	ghoulsfx(pc),a0
	moveq	#32,d0
	moveq	#-5,d1
	bsr.l	playsfx
	;
.no	movem.l	ob_xvec(a5),d0-d1
	add.l	d0,ob_x(a5)
	add.l	d1,ob_z(a5)
	;
	move.l	ob_framespeed(a5),d0
	beq.l	.rts
	add.l	d0,ob_frame(a5)
	cmp	#3,ob_frame(a5)
	bcs.l	.rts
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
	bne.l	.nofire
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
	bsr.l	shoot
	;
	move.l	(a7)+,a0
	move.l	(a0),a0
	moveq	#32,d0
	moveq	#0,d1
	bsr.l	playsfx
	;
.nofire	subq	#1,ob_delay(a5)
	bgt.l	.rts
	;
	bsr.l	rnddelay
	move.l	ob_oldlogic(a5),ob_logic(a5)
	;
.rts	rts

demonlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	bgt.l	monstermove
	;
	bsr.l	pickcalc
	;
	move	d0,ob_rot(a5)
	bsr.l	calcvecs
	move	#5<<3-1,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#demonpause,ob_logic(a5)
	;
	rts

phantomlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	bgt.l	monstermove
	;
	bsr.l	pickcalc
	;
	move	d0,ob_rot(a5)
	bsr.l	calcvecs
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
	bra.l	shoot

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
	bsr.l	deathbounce
	;
	bsr.l	checkvecs
	bne.l	.hit
	;
	;charge player?
	;
	bsr.l	pickcalc	;find angle to player
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d0,d1	;am I near?
	bpl.l	.ansk
	neg	d1
.ansk	cmp	#16,d1
	bcc.l	.notnear
	;
	;OK! chargaroony!
	;
	move	d0,ob_rot(a5)
	move.l	#deathcharge,ob_logic(a5)
	bra.l	calcvecs
.hit	add	#128,ob_rot(a5)
	bsr.l	rnddelay
.notnear	move	ob_delay(a5),d0
	add	d0,ob_rot(a5)
	bsr.l	calcvecs
	rts

deathanim	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	cmp.l	#$8000,ob_frame(a5)
	blt.l	.fix
	cmp.l	#$28000,ob_frame(a5)
	blt.l	.fok
.fix	neg.l	d0
	add.l	d0,ob_frame(a5)
	move.l	d0,ob_framespeed(a5)
	;
.fok	rts

deathcharge	bsr.l	deathbounce
	bsr.l	deathanim
	;
	bsr.l	pickcalc
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d1,d0	;am I near?
	bpl.l	.ansk
	neg	d0
.ansk	cmp	#128,d0
	bcc.l	.hit
	bsr.l	checkvecs
	bne.l	.hit2
	rts
.hit2	add	#128,ob_rot(a5)
.hit	move.l	#deathheadlogic,ob_logic(a5)
	move.l	#$8000,ob_frame(a5)
	bra.l	rnddelay

monsterlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	;monster cruising around minding his own business...
	;
	subq	#1,ob_delay(a5)
	ble.l	fire1
	;
monstermove	bsr.l	checkvecs
	beq.l	monsternew
	;
	;OK, try 90/-90 degrees...
	;
monsterfix	bsr.l	rndw
	moveq	#64,d1
	tst	d0
	bpl.l	.umk
	moveq	#-64,d1
.umk	add	d1,ob_rot(a5)
	bsr.l	calcvecs
	bsr.l	checkvecs
	beq.l	monsternew
	;
	add	#128,ob_rot(a5)
	bsr.l	calcvecs
	bsr.l	checkvecs
	beq.l	monsternew
	;
	move	ob_oldrot(a5),d0
	add	#128,d0
	move	d0,ob_rot(a5)
	;
	bsr.l	calcvecs
	bsr.l	checkvecs
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
	bpl.l	.rts
	move	ob_delay(a5),d0
	cmp	#-16*8,d0
	bgt.l	.try
	move	#47,ob_delay(a5)
	rts
.try	and	#7,d0
	bne.l	.rts
	;
.fire	moveq	#0,d2	;colltype
	moveq	#24+3,d3	;collwith - p1/p2/bullets
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#16,d6	;speed
	lea	bullet5,a2
	lea	sparks5,a3
	;
	addlast	objects
	beq.l	.rts
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

blowdb	bsr.l	makesparksq
	bra.l	killobject

homeinlogic	bsr.l	checkvecs
	bne.l	blowdb
	bsr.l	pickcalc	;find angle to player!
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
	bpl.l	.pl1
	neg.l	d0
.pl1	cmp.l	#$200000,d0	;max speed
	bcc.l	.sk1
	move.l	d4,ob_xvec(a5)
	;
.sk1	add.l	ob_zvec(a5),d5
	move.l	d5,d0
	bpl.l	.pl2
	neg.l	d0
.pl2	cmp.l	#$200000,d0
	bcc.l	.sk2
	move.l	d5,ob_zvec(a5)
.sk2	;
	bra.l	putfire

dragonanim	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

getobrot	move	ob_rotspeed(a5),d0
	bne.l	.addr
	;
	;OK, randomly left/rite!
	;
	bsr.l	rndw
	and	#1,d0
	bne.l	.addr2
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
	bsr.l	dragonanim
	bsr.l	dragonfire
	bsr.l	checkvecs
	beq.l	.nohit
	;
	;OK, dragon has hit a wall...rot him around till he's clear!
	;
	bsr.l	getobrot
	lsl	#2,d0
	add	d0,ob_rot(a5)
	bra.l	calcvecs
.nohit	;
	bsr.l	pickcalc
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d0,d1	;am I near?
	bpl.l	.ansk
	neg	d1
.ansk	moveq	#6,d0
	tst	ob_rotspeed(a5)
	bne.l	.sh
	moveq	#24,d0
.sh	cmp	d0,d1
	bcs.l	.near
	;
	;not pointed at player!
	bsr.l	getobrot
	add	d0,ob_rot(a5)
	bra.l	calcvecs
	;
.near	tst	ob_rotspeed(a5)
	beq.l	.near2
	clr	ob_rotspeed(a5)	;towards player!
	;
	move.l	dragonsfx(pc),a0
	moveq	#64,d0
	moveq	#20,d1
	bsr.l	playsfx
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
	bcs.l	.skip
	clr	ob_frame(a5)
.skip	;
	subq	#1,ob_delay(a5)
	bgt.l	.rts
	bsr.l	rnddelay
	;
	addlast	objects
	beq.l	.rts
	;
	movem.l	ob_x(a5),d2-d4
	movem.l	d2-d4,ob_x(a0)
	bsr.l	bloodspeed2
	move.l	d0,ob_xvec(a0)
	bsr.l	bloodspeed2
	move.l	d0,ob_yvec(a0)
	bsr.l	bloodspeed2
	move.l	d0,ob_zvec(a0)
	move.l	ob_chunks(a5),a2
	move.l	a2,ob_shape(a0)
	move	2(a2),d0
	bsr.l	rndn
	move	d0,ob_frame(a0)
	move.l	#sparkslogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	bsr.l	rndw
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
	bsr.l	checknewslow	;ok to stand here?
	beq.l	.ok
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bsr.l	checknewslow
	bne.l	.fix
	moveq	#-1,d1	;use old pos, and report hit!
	rts
	;
.fix	bsr.l	adjustposq	;fixup!
	moveq	#-1,d1
	;
.ok	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	tst	d1
	rts

playerdead	bsr.l	getcntrl
	;
	subq	#1,ob_delay(a5)
	bgt.l	.rts
	;
	cmp	#2,gametype
	bne.l	.notcom
	;
	;combat game!
	;
	move	#4,finished2
	move	#1,ob_pixsizeadd(a5)
	move.l	#rts,ob_logic(a5)
	bsr.l	getother
	move	#1,ob_pixsizeadd(a0)
.rts	rts
	;
.notcom	;
	tst	ob_lives(a5)
	beq.l	.dead
	move.l	#waitrestart,ob_logic(a5)
	rts
	;
.dead	move.l	#rts,ob_logic(a5)
	tst	gametype
	bne.l	.not1p
.allover	move	#2,finished
	rts
	;
.not1p	;OK, I'm all out of lives...what about other guy...
	bsr.l	getother
	tst	ob_lives(a0)
	beq.l	.allover
	rts

waitrestart	bsr.l	getcntrl
	;
	bsr.l	checkfireb
	beq.l	.rts
	;
	move	ob_weapon(a5),-(a7)
	;
	lea	p1x(pc),a0
	lea	player1_+4,a1
	cmp.l	player1,a5
	beq.l	.got
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
	bsr.l	resetplayer
	move	#-1,ob_update(a5)
	st	ob_lastbut(a5)
	;
.rts	rts

playerdeath	bsr.l	getcntrl
	;
	addq	#4,ob_rot(a5)
	addq	#4,ob_eyey(a5)
	cmp	#-32,ob_eyey(a5)
	blt.l	.rts
	;
	move	#-32,ob_eyey(a5)
	move.l	#playerdead,ob_logic(a5)
	move	#63,ob_delay(a5)
	;
	cmp	#2,gametype
	bne.l	.notcom
	;
	;death in combat game!
	;
	bsr.l	getother
	;
.win	move.l	a5,-(a7)
	;
	move.l	a0,a5
	clr	ob_collwith(a5)
	clr	ob_colltype(a5)
	bsr.l	message
	dc.b	'winner!',0
	even
	;
	move.l	(a7)+,a5
	subq	#1,ob_lives(a5)
	move	#-1,ob_update(a5) ;refresh 'lives'
	bsr.l	message
	dc.b	'loser!',0
	even
	;
	rts
.notcom	;
	subq	#1,ob_lives(a5)
	move	#-1,ob_update(a5)
	move	gametype(pc),d0
	beq.l	.one
	;
	;2 player game!
	;
	bsr.l	getother
	tst	ob_lives(a5)
	beq.l	.hmm
	move	ob_lives(a5),ob_lives(a0)
	move	#-1,ob_update(a0)
	rts
.hmm	tst	ob_lives(a0)
	beq.l	.go2
	rts
.one	tst	ob_lives(a5)
	beq.l	.go
	rts
.go2	move.l	a5,-(a7)
	move.l	a0,a5
	bsr.l	message
	dc.b	'game over',0
	even
	move.l	(a7)+,a5
.go	bsr.l	message
	dc.b	'game over',0
	even
.rts	rts

getother	;get other player from a5!
	;
	move.l	player1(pc),a0
	cmp.l	a0,a5
	bne.l	.rts
	move.l	player2(pc),a0
.rts	rts

redpal	move.l	#palettesr,ob_palette(a5)
	move	#2,ob_paltimer(a5)
	rts

playerhit	tst	ob_damage(a0)
	beq.l	.rts
	st	ob_update(a5)
	bsr.l	redpal
.rts	rts

playerdie	bsr.l	redpal
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
	ble.l	.skip
	move	#25,ob_hitpoints(a5)
.skip	st	ob_update(a5)
	bsr.l	message
	dc.b	'health bonus!',0
	even
	rts

healthgot	bsr.l	playtsfx
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr.l	inchealth
	move.l	(a7)+,a5
	bra.l	killobject

playtsfx	move.l	a0,-(a7)
	move.l	tokensfx(pc),a0
	moveq	#64,d0
	moveq	#0,d1
	bsr.l	playsfx
	move.l	(a7)+,a0
	rts

weapongot	bsr.l	playtsfx
	move.l	a5,-(a7)
	move	ob_weapon(a5),d0	;weapon #!
	move.l	a0,a5
	bsr.l	weapond0
	move.l	(a7)+,a5
	bra.l	killobject

weapond0	cmp	ob_weapon(a5),d0
	bne.l	.new
	;
	subq.b	#1,ob_reload(a5)
	beq.l	.skip
	cmp.b	#1,ob_reload(a5)
	bne.l	.notfull
	bsr.l	message
	dc.b	'weapon boosted to full!',0
	even
	bra.l	.kill
	;
.notfull	bsr.l	message
	dc.b	'weapon boost!',0
	even
	;
.kill	st	ob_update(a5)
	rts
	;
.skip	addq.b	#1,ob_reload(a5)
	add	#250,ob_mega(a5)
	cmp	#ok,ob_mega(a5)
	bcs.l	.mwb
	;
	bsr.l	message
	dc.b	'ultra mega overkill!!!',0
	even
	rts
	;
.mwb	bsr.l	message
	dc.b	'mega weapon boost!',0
	even
	rts
	;
.new	move	d0,ob_weapon(a5)
	move.b	#ireload,ob_reload(a5)
	st	ob_update(a5)
	bsr.l	message
	dc.b	'new weapon!',0
	even
	bra.l	.kill

invisigot	bsr.l	playtsfx
	move.l	a5,-(a7)
	move.l	a0,a5
	add	#1500,ob_invisible(a5)
	bsr.l	message
	dc.b	'invisibility!',0
	even
	move.l	(a7)+,a5
	bra.l	killobject

invincgot	bsr.l	playtsfx
	tst	ob_hyper(a0)
	bne.l	.rts
	move.l	a5,-(a7)
	move.l	a0,a5
	;
	move	#-$200,ob_hyper(a5)
	bsr.l	message
	dc.b	'hyper!',0
	even
	;
	move.l	(a7)+,a5
	bra.l	killobject
	;
.rts	rts

bouncylogic	addq	#1,ob_delay(a5)
	move	ob_delay(a5),d0
	lsr	#1,d0
	and	#3,d0
	move	.bnc(pc,d0*2),ob_frame(a5)
	rts
.bnc	dc	3,4,3,5

bouncygot	bsr.l	playtsfx
	cmp	#3,ob_bouncecnt(a0)
	bcc.l	.rts
	addq	#1,ob_bouncecnt(a0)
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr.l	message
	dc.b	'bouncy bullets!',0
	even
	move.l	(a7)+,a5
	bra.l	killobject
.rts	rts

thermogot	bsr.l	playtsfx
	add	#1500,ob_thermo(a0)
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr.l	message
	dc.b	'got the thermo glasses!',0
	even
	move.l	(a7)+,a5
	bra.l	killobject

maxsize	equ	$280

playertimers	tst	ob_mega(a5)
	beq.l	.nomega
	subq	#1,ob_mega(a5)
	bne.l	.nomega
	bsr.l	message
	dc.b	'mega weapon out...',0
	even
	;
.nomega	tst	ob_thermo(a5)
	beq.l	.noth
	subq	#1,ob_thermo(a5)
	bne.l	.noth
	bsr.l	message
	dc.b	'thermo glasses out...',0
	even
	;
.noth	tst	ob_messtimer(a5)
	ble.l	.notm
	subq	#2,ob_messtimer(a5)
.notm	;
	tst	ob_invisible(a5)
	beq.l	.noti
	subq	#1,ob_invisible(a5)
	bne.l	.noti
	bsr.l	message
	dc.b	'invisibility out...',0
	even
.noti	;
	tst	ob_paltimer(a5)
	beq.l	.notp
	subq	#1,ob_paltimer(a5)
	bne.l	.notp
	move.l	#palettes,ob_palette(a5)
.notp	;
	move	ob_pixsizeadd(a5),d0
	beq.l	.notpix
	add	d0,ob_pixsize(a5)
	bne.l	.pixnz
	;
	clr	ob_pixsizeadd(a5)
	bra.l	.notpix
	;
.pixnz	cmp	#24,ob_pixsize(a5)
	bne.l	.notpix
	;
	move	finished2(pc),finished
	bne.l	.notpix
	;
	move	ob_telex(a5),ob_x(a5)
	move	ob_telez(a5),ob_z(a5)
	move	ob_telerot(a5),ob_rot(a5)
	neg	ob_pixsizeadd(a5)
.notpix	;
	move	ob_hyper(a5),d0
	beq.l	.nothyper
	bpl.l	.hplus
	;
	;hyper is minus! growing...
	;
	subq	#4,d0
	move	d0,d1
	neg	d1
	cmp	#maxsize,d1
	bne.l	.hdone
	move	#750<<2+maxsize,d0
	bra.l	.hdone
	;
.hplus	subq	#4,d0
	cmp	#maxsize,d0
	bhi.l	.hdone2
	bne.l	.noteq
	bsr.l	message
	dc.b	'hyper out...',0
	even
	move	#maxsize,d0
.noteq	move	d0,d1
	cmp	#$200,d0
	bne.l	.hdone
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
	bsr.l	playsfx
	move.l	(a7)+,d0
	rts

pbuff	ds.b	128	;player controls to use!
pput	dc	0	;put new cntrl here
pget	dc	0	;read this for actual

getcntrl	move	ob_cntrl(a5),d0
	lea	joyx0(pc),a0
	move.l	0(a0,d0*8),joyx
	move.l	4(a0,d0*8),joyb
	rts

maxrotsp	equ	$40000
rotacc	equ	$20000
rotrevacc	equ	$40000
rotsetacc	equ	$20000

rotplayer	;return rot in d0, leave a0
	;
	move	joys(pc),d0	;strafing?
	bne.l	.norot
	move	joyx(pc),d0
	beq.l	.norot
	;
	move.l	#rotacc,d1	;rotacc
	move	ob_rotspeed(a5),d2
	beq.l	.useacc
	eor	d2,d0
	bpl.l	.useacc
	move.l	#rotrevacc,d1	;fast rev!
.useacc	move	joyx(pc),d0
	bpl.l	.plus
	neg.l	d1
.plus	add.l	d1,ob_rotspeed(a5)
	cmp.l	#maxrotsp,ob_rotspeed(a5)
	bgt.l	.fixaccpl
	cmp.l	#-maxrotsp,ob_rotspeed(a5)
	bge.l	.addrot
	move.l	#-maxrotsp,ob_rotspeed(a5)
	bra.l	.addrot
.fixaccpl	move.l	#maxrotsp,ob_rotspeed(a5)
	bra.l	.addrot
	;
.norot	tst.l	ob_rotspeed(a5)
	beq.l	.skip
	bpl.l	.orpl
	add.l	#rotsetacc,ob_rotspeed(a5)
	ble.l	.addrot
.clrrot	clr.l	ob_rotspeed(a5)
	bra.l	.skip
.orpl	sub.l	#rotsetacc,ob_rotspeed(a5)
	bmi.l	.clrrot
	;
.addrot	move.l	ob_rotspeed(a5),d0
	add.l	d0,ob_rot(a5)
	;
.skip	rts

unbounce	move	ob_bounce(a5),d1
	beq.l	.rts
	add	#30,ob_bounce(a5)
	move	ob_bounce(a5),d1
	and	#127,d1
	cmp	#30,d1
	bcc.l	.rts
	clr	ob_bounce(a5)
	clr	ob_frame(a5)
	bra.l	footstep
.rts	rts

moveplayer	;work out movement vector into d0/d1...check still/moving!
	;
	move	joyy(pc),d0
	bne.l	.move
	move	joys(pc),d0
	beq.l	.still
	move	joyx(pc),d0
	bne.l	.strafe
	;
.still	bsr.l	unbounce
	move	ob_bounce(a5),d0
	bne.l	.fskip
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
	bra.l	.check
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
	beq.l	.check
	move	joyx(pc),d0
	bne.l	.strafe
.check	;
	bsr.l	checknewslow
	beq.l	.newpos
	bsr.l	adjustpos
	beq.l	.newpos
	bsr.l	adjustpos
	beq.l	.newpos
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bra.l	.bounce
	;
.newpos	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	;
.bounce	move	ob_bounce(a5),d2
	add	#20,ob_bounce(a5)
	move	ob_bounce(a5),d1
	and	#255,d2
	cmp	#64,d2
	bcc.l	.fskip
	and	#255,d1
	cmp	#64,d1
	bcs.l	.fskip
	;
	bsr.l	footstep
.fskip	;
	move.l	ob_framespeed(a5),d1
	add.l	d1,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

checkevent	bsr.l	checknew2
	beq.l	.rts
	;
	move	ob_pixsizeadd(a5),d0
	or	finished2(pc),d0
	bne.l	.rts
	;
	move	zo_ev(a4),d0	;poly->event
	bmi.l	.rts
	;
	cmp	#24,d0
	bne.l	.notexit
	;
	move	#3,finished2		;pattern done!
	move	#1,ob_pixsizeadd(a5)	;pixel out
	tst	gametype
	beq.l	.onewin
	bsr.l	getother
	move	#2,ob_pixsizeadd(a0)	;pixel out other player
.onewin	;
	bsr.l	dotelesfx
	moveq	#24,d0
	;
.notexit	cmp	#19,d0
	bcc.l	.noclr
	;
	;OK, gotta clear all 'event' zones with same type!
	;
	move.l	map_poly(pc),a0
	move.l	map_ppnt(pc),a1
	moveq	#32,d1
.loop2	cmp	zo_ev(a0),d0
	bne.l	.skip2
	neg	zo_ev(a0)
.skip2	add.l	d1,a0
	cmp.l	a1,a0
	bcs.l	.loop2
	;
.noclr	move.l	a5,eventobj
	movem.l	d6-d7,-(a7)
	bsr.l	execevent
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
	bne.l	.nosuck
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
	bsr.l	checknewslow
	beq.l	.newok
	bsr.l	adjustpos
	beq.l	.newok
	bsr.l	adjustpos
	beq.l	.newok
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bra.l	.nosuck
	;
.newok	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	;
.nosuck	rts

playerlogic0	;restart after death...2 seconds invincibility.
	;
	subq	#1,ob_delay(a5)
	bgt.l	playerlogic
	;
	;OK, fix colltype/collwith
	;
	lea	player1_,a1
	cmp.l	player1,a5
	beq.l	.got
	lea	player2_,a1
.got	lea	p1_ob_colltype-player1_(a1),a1
	move.l	(a1),ob_colltype(a5)
	move.l	#playerlogic,ob_logic(a5)
playerlogic	;
	bsr.l	playertimers	;do timer stuff...
	bsr.l	getcntrl	;player control
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	;
	;getting sucked?
	;
	;OK, are we getting pushed/squashed?
	;
	bsr.l	checknewslow
	beq.l	.newok
	bsr.l	adjustpos
	beq.l	.newok2
	bsr.l	adjustpos
	beq.l	.newok2
	;
	subq	#1,ob_hitpoints(a5)
	ble.l	playerdie
	st	ob_update(a5)
	bra.l	redpal
	;
.newok2	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
.newok	;
	bsr.l	checksuck
	bsr.l	checkevent	;in an event zone?
	bsr.l	rotplayer	;rotate
	bsr.l	moveplayer	;forward/back/strafe
checkfire	;
	move	cheat(pc),d0
	beq.l	.nocheat
	;
	qkey	$5f	;help?????
	beq.l	.noend
	move	#3,finished
	rts
.noend	key	10
	beq.l	.nohealth
	bsr.l	inchealth
	bra.l	.nocheat
.nohealth	move.b	(a0),d1
	moveq	#5,d0
.loop	btst	d0,d1
	bne.l	.gotch
	subq	#1,d0
	bne.l	.loop
	bra.l	.nocheat
.gotch	;
	subq	#1,d0
	bsr.l	weapond0
	;
.nocheat	bsr.l	checkfireb
	beq.l	.nofire
	tst.b	ob_reloadcnt(a5)
	bne.l	.nofire2
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
	beq.l	.nomega
	;
	cmp	#ok,ob_mega(a5)
	bcc.l	.threeway
	;
	movem.l	d2-d6/a2-a3,-(a7)
	addq	#4,ob_rot(a5)
	bsr.l	shoot
	movem.l	(a7)+,d2-d6/a2-a3
	subq	#8,ob_rot(a5)
	bsr.l	shoot
	addq	#4,ob_rot(a5)
	bra.l	.shdone
.threeway	;
	movem.l	d2-d6/a2-a3,-(a7)
	addq	#8,ob_rot(a5)
	bsr.l	shoot
	movem.l	(a7),d2-d6/a2-a3
	sub	#16,ob_rot(a5)
	bsr.l	shoot
	movem.l	(a7)+,d2-d6/a2-a3
	addq	#8,ob_rot(a5)
	;
.nomega	bsr.l	shoot
	;
.shdone	move.l	(a7)+,a0
	move.l	(a0),a0
	moveq	#32,d0
	moveq	#0,d1
	bsr.l	playsfx
	;
	move.b	ob_reload(a5),ob_reloadcnt(a5)
	rts
	;
.nofire	tst.b	ob_reloadcnt(a5)
	beq.l	.rts
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

adjustpos	bsr.l	adjustposq
	;
	;addq	#1,(a4)
	;move.l	a4,-(a7)
	bsr.l	checknewslow
	;move.l	(a7)+,a3
	;addq	#1,(a3)
	tst	d1
	rts

checkfireb	move	joyb(pc),d0
	beq.l	.nofire
	tst	ob_lastbut(a5)
	bne.l	.skip
	move	d0,ob_lastbut(a5)
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
	bge.l	.nok
	bsr.l	makesparksq
	bra.l	killobject
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
	bsr.l	checkvecs
	beq.l	putfire
	bra.l	calcbounce

firelogic	;
	bsr.l	checkvecs
	bne.l	calcbounce
putfire	;
	addq	#1,ob_frame(a5)
	move	ob_frame(a5),d0
	move.l	ob_shape(a5),a0
	cmp	2(a0),d0
	bcs.l	.skip
	clr	ob_frame(a5)
.skip	;
	rts

moveblood	lea	blood(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.done
	;
	tst	bl_y(a5)
	ble.l	.do
	;
	move.l	sucking(pc),d0
	beq.l	.kill
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
	bcc.l	.loop
	bra.l	.kill
	;
.do	add.l	#$8000,bl_yvec(a5)
	;
	movem.l	bl_xvec(a5),d0-d2
	add.l	d1,bl_y(a5)
	blt.l	.ok
	;
.kill	move.l	a5,a0
	killitem	blood
	move.l	a0,a5
	bra.l	.loop
	;
.ok	add.l	d0,bl_x(a5)
	add.l	d2,bl_z(a5)
	bra.l	.loop
	;
.done	rts

scrnblood	dc	0

drawblood	clr	scrnblood
	move	#$20,$dff09a
	lea	blood(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.done
	;
	move	bl_color(a5),d6
	beq.l	.loop	;already splatted on screen if 0!
	;
	move	bl_x(a5),d0
	sub	camx(pc),d0
	move	bl_y(a5),d1
	ble.l	.blok
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
	beq.l	.loop
	cmp	#maxz,d2
	bcc.l	.loop
	;
	ext.l	d0
	lsl.l	#focshft,d0
	divs	d2,d0
	cmp	minx(pc),d0
	blt.l	.loop
	cmp	maxx(pc),d0
	bge.l	.loop
	;
	ext.l	d1
	lsl.l	#focshft,d1
	divs	d2,d1
	cmp	miny(pc),d1
	blt.l	.loop
	cmp	maxy(pc),d1
	bge.l	.loop
	;
	cmp	#40,d2
	bcc.l	.pix
	tst	bl_y(a5)
	bgt.l	.pix
	;
	;blood on screen!
	;
	st	scrnblood
	clr	bl_color(a5)
	bra.l	.loop
.pix	;
	add	midx(pc),d0
	add	midy(pc),d1
	;
	move.l	darktable(pc),a0
	move	0(a0,d2*2),d3
	;
	move.l	cop(pc),a1
	;
	lea	coloffs,a2
	add.l	0(a2,d0*4),a1
	mulu	copmod(pc),d1
	;
	move	blcols(pc,d3*2),d3
	and	d6,d3
	move	d3,0(a1,d1.l)
	bra.l	.loop
	;
.done	move	#$8020,$dff09a
	;
	move	scrnblood(pc),d0
	beq.l	.rts
	clr	scrnblood
	;
	bsr.l	rndw2
	and	#3,d0
	add	#51,d0
	move	d0,d2	;splat#
	;
	move.l	window(pc),a0
	move	wi_bh(a0),d0
	subq	#8,d0
	bsr.l	rndn2
	move	d0,d3	;Y
	;
	move	wi_bw(a0),d0
	subq	#8,d0
	bsr.l	rndn2
	add	wi_x(a0),d0	;X
	;
	move	d3,d1
	move.l	wi_bmap(a0),a1
	move.l	font(pc),a0
	bra.l	blit
	;
.rts	rts

blcols	dc	$ccc,$bbb,$aaa,$999,$888,$777,$666,$555
	dc	$444,$333,$222,$111,$111,$111,$111,$111

shaperender	dc.l	drawobjnorm	;default!

drawshape_1sc	;draw shape with one frame, scaled!
	;
	move.l	ob_shape(a5),a0
	move	ob_frame(a5),d0
	add.l	12(a0,d0*4),a0
	move	ob_scale(a5),d7
	bra.l	drawshape

drawshape_1	;
	move.l	ob_shape(a5),a0
	move	ob_frame(a5),d0
	add.l	12(a0,d0*4),a0
	move	#$200,d7	;scale
	bra.l	drawshape

drawshape_8	;
	;shape has 8 rotations, and a scale!
	;
	bsr.l	calcangle2
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
	ble.l	.rts
	cmp	#maxz,d2
	bcc.l	.rts
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
	move.l	a0,sh_shape(a1)
	move	d7,sh_scale(a1)
	move.l	shaperender(pc),sh_render(a1)
	;
	lea	shapelist(pc),a2
.loop	move.l	(a2),d0
	beq.l	.end
	move.l	a2,a3
	move.l	d0,a2
	cmp	sh_z(a2),d2	;nearer...further in list
	ble.l	.loop
	move.l	a2,(a1)
	move.l	a1,(a3)
	rts
.end	move.l	d0,(a1)
	move.l	a1,(a2)
.rts	rts

checknew2	;check trigger zone
	move.l	map_grid(pc),a0
	addq	#4,a0
	bra.l	checknew_

gs	equ	1<<grdshft

incframe	addq	#1,frame
	bne.l	.skip
	;
	movem.l	d0-d1/a0-a1,-(a7)
	moveq	#0,d0
	moveq	#32,d1
	move.l	map_poly(pc),a0
	move.l	map_ppnt(pc),a1
.loop	move	d0,(a0)
	add.l	d1,a0
	cmp.l	a1,a0
	bcs.l	.loop
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
	bsr.l	incframe
	move	frame(pc),d3
	moveq	#8,d5		;nine squares
	;
.loop	movem	(a1)+,d0-d1
	add	d6,d0
	cmp	#32<<grdshft,d0
	bcc.l	.next
	add	d7,d1
	cmp	#32<<grdshft,d1
	bcc.l	.next
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
	bmi.l	.next
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
	beq.l	.next2
	move	d3,(a4)
	;
	bsr.l	findsegdist
	;
	sub	ob_rad(a5),d0
	bpl.l	.next2
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
	bsr.l	incframe
	move	frame(pc),d3
	moveq	#8,d5		;nine squares
	move	#$3fff,closest
	;
.loop	movem	(a1)+,d0-d1
	add	d6,d0
	cmp	#32<<grdshft,d0
	bcc.l	.next
	add	d7,d1
	cmp	#32<<grdshft,d1
	bcc.l	.next
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
	bmi.l	.next
	move	(a3),d1
	;
	move.l	map_ppnt(pc),a3
	lea	0(a3,d1*2),a3
	;
.loop2	move	(a3)+,d0	;grab poly#
	lsl	#5,d0
	lea	0(a2,d0),a4	;poly to check
	bsr.l	checkpolydist
	dbf	d4,.loop2
.next	dbf	d5,.loop
	;
	lea	rotpolys(pc),a3
	;
.loop3	move.l	(a3),a3
	tst.l	(a3)
	beq.l	.rpdone
	;
	move.l	rp_first(a3),a4
	move	rp_num(a3),d4
	subq	#1,d4
	;
.loop4	bsr.l	checkpolydist
	lea	32(a4),a4
	dbf	d4,.loop4
	;
	bra.l	.loop3
.rpdone	;
	movem.l	(a7)+,d3-d7
	move	closest(pc),d0
	sub	ob_rad(a5),d0
	bpl.l	.wallok
	move.l	closewall(pc),a4
	moveq	#-1,d1
	rts
.wallok	moveq	#0,d1
	rts

checkpolydist	;	
	cmp	(a4),d3
	beq.l	.rts
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
	bcc.l	.rts
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
	bpl.l	.pl
	neg.l	d0
.pl	swap	d0	;perpendicular dist.w
	;
	cmp	closest(pc),d0
	bcc.l	.rts
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
	bcs.l	.perp	;use perpendicular distance!
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
	bpl.l	.pl
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
	bcs.l	.perp	;use perpendicular distance!
	;
	;gotta find radial distance
	;
	blt.l	.min	;minus?
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

readjoydir	bsr.l	joydir
	move	d1,d0
	move	d2,d1
	add	d1,d1
	eor	d1,d2
	;
joydir	btst	#9,d2
	bne.l	.neg
	btst	#1,d2
	bne.l	.pos
	moveq	#0,d1
	rts
.neg	moveq	#-1,d1
	rts
.pos	moveq	#1,d1
	rts

readjoy0	;into a0 block
	;
	move	$dff00a,d2	;joy0
	bsr.l	readjoydir
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
	bsr.l	readjoydir
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
	bsr.l	readjoydir
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
	bne.l	.skip
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
	bcc.l	.noesc
	st	escape
.noesc	;
	lsr	#1,d0	;btst	#1,d0
	bcc.l	.nolsh
	;
	;left should button!
	move	#-1,(a0)	;left/
	move	#-1,6(a0)	;strafe!
	rts
	;
.nolsh	lsr	#1,d0	;btst	#2,d0
	bcc.l	.norsh
	;
	;rite shoulder button
	move	#1,(a0)
	move	#-1,6(a0)
	;
.norsh	rts

readcd321	;into a0 block
	;
	move	$dff00c,d2	;joy0
	bsr.l	readjoydir
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
	bne.l	.skip
	bset	d1,d0
.skip	dbf	d1,.loop
	move	#$3000,$dff034
	bclr	d3,$200(a2)
	;
	bra.l	handlecd32

	;    00 : play/pause
	;    01 : reverse
	;    02 : forward
	;    03 : green
	;    04 : yellow
	;    05 : red
	;    06 : blue

readkeys	;into a0 block
	;
	move.l	rawtable(pc),a1
	moveq	#0,d0
	keya1	$4f
	beq.l	.nleft
	moveq	#-1,d0
.nleft	keya1	$4e
	beq.l	.nrite
	moveq	#1,d0
.nrite	move	d0,(a0)
	moveq	#0,d0
	keya1	$63
	bne.l	.up
	keya1	$4c
	beq.l	.nup
.up	moveq	#-1,d0
.nup	keya1	$60
	bne.l	.down
	keya1	$4d
	beq.l	.ndown
.down	moveq	#1,d0
.ndown	move	d0,2(a0)
	moveq	#0,d0
	keya1	$66
	beq.l	.nbut
	moveq	#-1,d0
.nbut	move	d0,4(a0)
	moveq	#0,d0
	keya1	$64
	beq.l	.nstr
	moveq	#-1,d0
.nstr	move	d0,6(a0)
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
	bsr.l	incframe
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
	bcc.l	.skip
	add	d7,d1
	cmp	#32,d1
	bcc.l	.skip
	;
	;d0,d1=x/z of map to check!
	;
	lsl	#5,d1	;Y*32...
	add	d1,d0	;+X
	lea	0(a2,d0*8),a0	;mapgrid
	move	(a0)+,d4	;how many polys here
	bmi.l	.skip
	move	(a0),d0	;poly data offset
	lea	0(a3,d0*2),a0
	;
.loop2	move	(a0)+,d0	;poly#
	lsl	#5,d0
	lea	0(a4,d0),a1	;actual poly
	;
	bsr.l	dothezone
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
	beq.l	.rpdone
	;
	move.l	rp_first(a3),a4
	move	rp_num(a3),d4
	subq	#1,d4
	;
.loop4	move.l	a4,a1
	bsr.l	dothezone2
	;
	lea	32(a4),a4
	dbf	d4,.loop4
	;
	bra.l	.loop3
.rpdone	;
makeoutlist	;create outlist from inlist
	;
	clr.l	outlist
	move.l	#outlist,outlistf
	;
.loop	lea	inlist(pc),a0
	move.l	(a0),d0
	beq.l	.done
	move.l	a0,a2	;save previous!
	move.l	d0,a0
	;
	;OK, see if any are in front of a0...
	;
	lea	inlist(pc),a1
	;
.loop2	move.l	(a1),d0
	beq.l	.none
	move.l	a1,a3
	move.l	d0,a1
	cmp.l	a0,a1
	beq.l	.loop2	;don't compare with self!
	;
	;check screen pos overlap...
	;
	move	wl_rsx(a0),d0
	cmp	wl_lsx(a1),d0
	blt.l	.loop2
	;
	move	wl_lsx(a0),d1
	cmp	wl_rsx(a1),d1
	bgt.l	.loop2
	;
	;check near/far Z overlap
	;
	move	wl_nz(a1),d2
	cmp	wl_fz(a0),d2
	bge.l	.loop2	;behind!
	;
	move	wl_fz(a1),d2
	cmp	wl_nz(a0),d2
	ble.l	.swap
	;
	tst	wl_open(a1)
	bne.l	.swap	
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
	bpl.l	.loop2	;both a0's in front of a1!
	;
	;if both a0 behind, swap
	;
	and.l	d1,d0
	bmi.l	.swap	;both a0's behind a1!
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
	bmi.l	.loop2	;both a1's behind a0!
	;
	or.l	d3,d2
	bmi.l	.loop2
	;
.swap	move.l	a1,a0
	move.l	a3,a2
	bra.l	.loop2
	;
.none	;OK, none in front of this (a0)
	;
	move.l	(a0),(a2)	;unlink from inlist
	clr.l	(a0)
	;
	move.l	outlistf(pc),a2
	move.l	a0,(a2)
	move.l	a0,outlistf
	bra.l	.loop
	;
.done	rts

dothezone2	;
	move	frame(pc),d0
	cmp	zo_done(a1),d0
	beq.l	.rts
	move	d0,zo_done(a1)
	tst	zo_open(a1)
	bmi.l	.rts
	;
	movem	d4-d7,-(a7)
	;
	movem	zo_lx(a1),d0-d3	;x1,z1,x2,z2
	movem	camx(pc),d6-d7
	;
	move	#maxz,d4
	move	d4,d5
	neg	d5
	;
	sub	d6,d0
	cmp	d4,d0
	bge.l	.rts2
	cmp	d5,d0
	ble.l	.rts2
	;
	sub	d7,d1
	cmp	d4,d1
	bge.l	.rts2
	cmp	d5,d1
	ble.l	.rts2
	;
	sub	d6,d2
	cmp	d4,d2
	bge.l	.rts2
	cmp	d5,d2
	ble.l	.rts2
	;
	sub	d7,d3
	cmp	d4,d3
	bge.l	.rts2
	cmp	d5,d3
	bgt.l	dothezone3 ;.rts2
	;
.rts2	movem	(a7)+,d4-d7
	;
.rts	rts

dothezone	;
	move	frame(pc),d0
	cmp	zo_done(a1),d0
	beq.l	rts ;.skip3
	move	d0,zo_done(a1)
	tst	zo_open(a1)
	bmi.l	rts ;.skip3
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
	bgt.l	.zok
	tst	d3
	ble.l	.skip2
.zok	;
	cmp	#maxz,d1
	blt.l	.zok2
	cmp	#maxz,d3
	bge.l	.skip2
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
	bpl.l	.front
	;
	;backface showing!...
	bra.l	.skip2
.front	;
	move.l	memat(pc),a5
	;
	movem	d0-d5,wl_lx(a5)
	move.l	d6,wl_c(a5)
	;
	;work out some screen positions!
	tst	d1
	bgt.l	.z1ok
	;
	;lz bad, rz must be OK...
	;
.ov1	move	minx(pc),wl_lsx(a5)
	bra.l	.z1sk
	;
.z1ok	ext.l	d0
	lsl.l	#focshft,d0
	divs	d1,d0
	bvs.l	.ov1
	subq	#1,d0
	cmp	maxx(pc),d0
	bge.l	.skip2
	move	d0,wl_lsx(a5)
.z1sk	;
	tst	d3
	bgt.l	.z2ok
	;
	;rz bad, lz must be OK...
	;
.ov2	move	maxx(pc),wl_rsx(a5)
	bra.l	.z2sk
	;
.z2ok	ext.l	d2
	lsl.l	#focshft,d2
	divs	d3,d2
	bvs.l	.ov2
	addq	#1,d2
	cmp	minx(pc),d2
	blt.l	.skip2
	move	d2,wl_rsx(a5)
.z2sk	;
	cmp	d1,d3
	bge.l	.zskp
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

; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif

makeoutlist2	;create outlist from inlist
	;
.loop0	lea	inlist(pc),a0
	;
.loop	move.l	(a0),d0
	beq.l	.done
	move.l	a0,a2	;save previous!
	move.l	d0,a0
	;
	;OK, see if any are in front of a0...
	;
	lea	inlist(pc),a1
	;
.loop2	move.l	(a1),d0
	beq.l	.none
	move.l	a1,a3
	move.l	d0,a1
	;
	cmp.l	a0,a1
	beq.l	.loop2	;don't compare with self!
	;
	;see if a1 is in front of a0
	;
	move	wl_nz(a1),d0
	cmp	wl_fz(a0),d0
	bge.l	.loop2	;behind!
	;
	move	wl_fz(a1),d0
	cmp	wl_nz(a0),d0
	ble.l	.swap
	;
	;now, compare screen x coords.....
	;
	move	wl_rsx(a0),d0
	cmp	wl_lsx(a1),d0
	blt.l	.loop2
	;
	move	wl_lsx(a0),d0
	cmp	wl_rsx(a1),d0
	bgt.l	.loop2
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
	bpl.l	.loop2
	;
	;if both a0 behind, swap
	;
	move.l	d0,d4
	and.l	d1,d4
	bmi.l	.swap
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
	bmi.l	.loop2	;both a1's behind...
	;
	;if both a1's in front, swap
	move.l	d2,d4
	or.l	d3,d4
	bpl.l	.swap
	;
	bra.l	.loop2
	;
	;elseif
	;
.swap	;a1 is infront of a0! make a1 new frontmost
	bra.l	.loop
	move.l	a1,a0
	move.l	a3,a2
	bra.l	.loop2
	;
.none	;OK, none in front of this (a0)
	;
	move.l	(a0),(a2)	;unlink from inlist
	clr.l	(a0)
	move.l	outlistf(pc),a2
	move.l	a0,(a2)
	move.l	a0,outlistf
	bra.l	.loop0
	;
.done	;move.l	inlist(pc),d0
	;bne	.loop0
	rts

; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif

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
	beq.l	.empty
	move.l	d0,a5
	;
	cmp	wl_lsx(a5),d7
	blt.l	.loop2
	cmp	wl_rsx(a5),d7
	bgt.l	.loop2
	;
	movem	wl_lx(a5),d0-d1
	muls	(a6),d0
	muls	2(a6),d1
	add.l	d1,d0	;LX!
	bgt.l	.loop2
	;
	movem	wl_rx(a5),d1-d2
	muls	(a6),d1
	muls	2(a6),d2
	add.l	d2,d1	;RX!
	blt.l	.loop2
	;
	sub.l	d0,d1
	;
	swap	d1
	tst	d1
	ble.l	.dfix
	neg.l	d0
	divu	d1,d0
	bvc.l	.noov
.dfix	moveq	#-1,d0
.noov	lsr	#1,d0	;fraction -> unsigned
	;
	cmp	wl_open(a5),d0
	bcs.l	.loop2
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
	blt.l	.loop2
	cmp	#maxz<<exshft,d2
	bcs.l	.zisok
	;
.empty	move	#32767,vd_z(a4)
	clr.l	vd_data(a4)
	bra.l	.next
.zisok	;
	;d0=frac, d2=z, a5=item
	;
	;calc column#
	;
	move.l	a4,a0	;do vd...
	;
	move	wl_sc(a5),d1
	bgt.l	.mul
	neg	d1
	ext.l	d0
	add.l	d0,d0
	lsr.l	d1,d0
	bra.l	.scdone
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
	;a3=texture column!
	;
	tst.b	(a3)+
	beq.l	.solid
	;
	bsr.l	makestrip	;do strip!
	;
.solid	move.l	a3,vd_data(a0)	;start column
	;
	;fill in vd struct...
	;
	move.l	darktable(pc),a2
	move	0(a2,d2*2),d3
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
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
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
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	;
	neg	d3
	neg	d5
	cmp	#-128,camy
	sle	d4
	ext	d4
	add	d4,d5
	;
	swap	d5
	clr	d5
	ext.l	d3
	divu.l	d3,d5	;sc step
	asr.l	#2,d5
	;
	;elseif
	;
	move.l	d5,vd_ystep(a0)
	;
	cmp.l	a0,a4
	bne.l	.loop2
	;
.next	;onto next display column
	;
	lea	vd_size(a4),a4
	addq	#8,a6
	addq	#1,d7
	cmp	maxx(pc),d7
	blt.l	.loop
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
	beq.l	.end
	move.l	a2,a3
	move.l	d0,a2
	cmp	sh_z(a2),d2	;nearer...further in list
	blt.l	.loop
	move.l	a2,(a1)
	move.l	a1,(a3)
	bra.l	.ins
.end	move.l	d0,(a1)
	move.l	a1,(a2)
.ins	movem.l	(a7)+,a2-a3
	;
	rts

dbwindow	;a0=window to double buffer....
	;
	movem.l	wi_cop(a0),d0-d1
	cmp.l	d0,d1
	bne.l	.skip
	move.l	wi_cop2(a0),d1
.skip	move.l	d1,wi_cop(a0)
	;
usewindow	;a0=window to use...
	;
	move.l	a0,window
	move.l	wi_cop(a0),cop
	move.l	wi_bmap(a0),bitmap
	;
	move	wi_copmod(a0),copmod
	move	wi_w(a0),d0
	move	d0,width
	move	d0,d1
	lsr	#5,d1
	move	d1,wdiv32
	move	d0,d1
	and	#31,d1
	subq	#1,d1
	move	d1,wrem32
	;
	lsr	#1,d0
	move	d0,maxx
	neg	d0
	move	d0,minx
	;
	move	wi_h(a0),d1
	move	d1,hite
	lsr	#1,d1
	move	d1,maxy
	neg	d1
	move	d1,miny
	;
	rts

drawstrip_	macro
	;
	;a1=top of dest column
	;a2=palettes base
	;a4=strip data
	;
	move	hite(pc),d6
	;
	move.l	vd_data(a4),d0
	beq.l	.vertskip
	;
	move.l	d0,a0
	;
	move	vd_h(a4),d5
	move.l	vd_ystep(a4),d1
	;
	;setup d6, how much more to cls!
	;
	move	vd_y(a4),d0
	add	midy(pc),d0
	bpl.l	.noclip
	;
	;gotta clip Y
	add	d0,d5	;reduce hite
	ble.l	.vertskip
	neg	d0
	;
	;d1=ystep.q, d0=y.w...
	;
	ext.l	d0
	mulu.l	d1,d0	;y step* y
	;
	cmp	d6,d5
	ble.l	.skipclip
	move	d6,d5
	bra.l	.skipclip
	;
.noclip	;OK, cls down to Y in d0!
	;
	ifne	solidstrip
	;
	beq.l	.skcl
	move	d0,d2
	lsl	#6,d2
	or	#1,d2
	bwait
	move.l	qstrip(pc),$dff050	;APth
	move.l	a1,$dff054		;Dpth
	move	d2,$dff058		;size...
	;
	endc
	;
	;start draw from here...
.skcl	move	d0,d2
	mulu	copmod(pc),d2
	add.l	d2,a1
	;
	move	d0,d2
	add	d5,d2
	sub	d6,d2
	ble.l	.skipclip2
	sub	d2,d5
	ble.l	.vertskip
	;
.skipclip2	sub	d0,d6
	moveq	#0,d0
.skipclip	;
	sub	d5,d6
	;
	subq	#1,d5
	swap	d0
	swap	d1
	move	vd_pal(a4),d2
	move.l	0(a2,d2*4),a3
	;
	ifeq	solidstrip
	move.b	-1(a0),d6
	ext	d6
	move	stripands(pc,d6*2),d6
	endc
	;
	move	copmod(pc),d4
	ext.l	d4
	moveq	#0,d3
	;
	sub	d1,d0	;Thanx Hendrix!
	add.l	d1,d0
	;
.vertloop	;a0=src texture column
	;a1=dest coppoke
	;a3=palette
	;d0=current Y
	;d1=Y step
	;d2=0
	;d3=$00xx
	;d4=copmod
	;d5=count
	;
	ifne	solidstrip
	;
	move.b	0(a0,d0),d3
	move	0(a3,d3*2),(a1)
	addx.l	d1,d0
	add.l	d4,a1
	;
	dbf	d5,.vertloop
	;
	elseif
	;
	move.b	0(a0,d0),d3	;lut entry
	bne.l	.coln
	and	d6,(a1)
	addx.l	d1,d0
	add.l	d4,a1
	dbf	d5,.vertloop
	bra.l	.vertskip
	;
.coln	move	0(a3,d3*2),(a1)
	addx.l	d1,d0
	add.l	d4,a1
	dbf	d5,.vertloop
	;
	endc
.vertskip	;
	ifne	solidstrip
	;
	add	d6,d6
	ble.l	.rts
	move.l	qstripbot(pc),a0
	sub	d6,a0
	lsl	#5,d6
	or	#1,d6
	bwait
	movem.l	a0-a1,$dff050
	move	d6,$dff058
.rts	;
	endc
	;
	endm

drawshapes	lea	shapelist(pc),a6
	;
.drawloop	move.l	(a6),d0
	beq.l	.rts
	move.l	d0,a6
	move.l	sh_shape(a6),d0
	bne.l	.shape
	;
	;wall strip!
	;
	move	sh_x(a6),d0
	add	midx(pc),d0
	move.l	cop(pc),a1
	lea	coloffs(pc),a5
	add.l	0(a5,d0*4),a1
	;
	move.l	palette(pc),a2
	move.l	sh_strip(a6),a4
	bsr.l	drawstrip2
	bra.l	.drawloop
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
	bge.l	.drawloop	;X too big!
	;
	lsl.l	#focshft,d1
	divs	d2,d1	;Screen Y
	cmp	maxy(pc),d1
	bge.l	.drawloop
	;
	movem	(a0),d3-d4	;width/hite
	;
	move.l	d3,d5
	muls	d7,d3
	asr.l	#8-focshft,d3
	divs	d2,d3	;screen width
	ext.l	d3
	ble.l	.drawloop
	;
	move.l	d4,d6
	muls	d7,d4
	asr.l	#8-focshft,d4
	divs	d2,d4	;hite
	ext.l	d4
	ble.l	.drawloop
	;
	swap	d5
	divu.l	d3,d5
	;
	add	midx(pc),d0
	bpl.l	.xcskip
	add	d0,d3	;reduce width
	ble.l	.drawloop
	neg	d0
	;
	ext.l	d0
	mulu.l	d5,d0	;start column in shape
	;
	moveq	#0,d7
	cmp	width(pc),d3
	ble.l	.xcdone
	move	width(pc),d3
	bra.l	.xcdone
	;
.xcskip	move	d0,d7	;sc X
	add	d3,d0
	sub	width(pc),d0
	ble.l	.xcdone2
	sub	d0,d3
	ble.l	.drawloop
.xcdone2	move.l	d5,d0
	lsr.l	#1,d0
.xcdone	;
	swap	d6
	divu.l	d4,d6	;y step
	;
	move.l	cop(pc),a1
	;
	add	midy(pc),d1
	bpl.l	.ycskip
	add	d1,d4	;hite
	ble.l	.drawloop
	neg	d1
	ext.l	d1
	mulu.l	d6,d1
	;
	cmp	hite(pc),d4
	ble.l	.ycdone
	move	hite(pc),d4
	bra.l	.ycdone
	;
.ycskip	move	d1,-(a7)
	mulu	copmod(pc),d1
	add.l	d1,a1
	move	(a7)+,d1
	add	d4,d1
	sub	hite(pc),d1
	ble.l	.ycdone2
	sub	d1,d4
	ble.l	.drawloop
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
	move.l	darktable(pc),a2
	move	0(a2,d7*2),d7
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
	;
	move.l	(a7)+,a6
	bra.l	.drawloop
	;
.rts	rts

drawobjinvs	;draw invisible object (half brite background!)
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcc.l	.zbad
	;
	movem.l	d0-d2/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	copmod(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$eee,d2	;RGB and
	;
.vloop	move.b	0(a3,d1),d5
	beq.l	.skip
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
	bcc.l	.zbad
	;
	movem.l	d0-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	copmod(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$eee,d2	;RGB and
	;
.vloop	move.b	0(a3,d1),d5
	beq.l	.skip
	;
	move	0(a2,d5*2),d3
	and	d2,d3
	move	(a4),d5
	and	d2,d5
	add	d3,d5
	lsr	#1,d5
	move	d5,(a4)
	moveq	#0,d5
	;
.skip	add.l	d6,d1	;next src Y
	addx	d0,d1	;xtend
	add.l	d7,a4
	dbf	d4,.vloop
	;
	movem.l	(a7)+,d0-d5
	;
.zbad	add.l	d5,d0
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
	bcs.l	.zok
	;
	tst	thermo
	beq.l	.zbad
	;
	bsr.l	thermostrip
	bra.l	.zbad
	;
.zok	movem.l	d0-d1/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	copmod(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	;
	sub	d6,d1
	add.l	d6,d1
	;
.vloop	move.b	0(a3,d1),d5
	beq.l	.skip
	move	0(a2,d5*2),(a4)
.skip	addx.l	d6,d1	;next src Y
	add.l	d7,a4
	dbf	d4,.vloop
	;
	movem.l	(a7)+,d0-d1/d4-d5
	;
.zbad	add.l	d5,d0
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
	move	copmod(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$00f,d2
	;
	sub	d6,d1
	add.l	d6,d1
	;
.vloop	move.b	0(a3,d1),d5
	beq.l	.skip
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

renderwalls	;
	move.l	palette(pc),a2
	;
	move.l	vertdraws(pc),a4
	lea	coloffs(pc),a5
	move	width(pc),d7
	subq	#1,d7
	;
	move	copmod(pc),d0
	subq	#2,d0
	;
	bwait
	move.l	con0poke(pc),$dff040
	move	#0,$dff064
	move	d0,$dff066
	move.l	#-1,$dff044
	move	#0,$dff074
	;
.loop	move.l	cop(pc),a1
	add.l	(a5)+,a1
	;
solidstrip	set	-1
	drawstrip_
	;
	lea	vd_size(a4),a4
	dbf	d7,.loop
	;
	rts

solidstrip	set	0
drawstrip2	;
	drawstrip_
	;
	rts

	dc	$f0ff,$ff0f,$fff0
	dc	$f00f,$f0f0,$ff00
	dc	$ffff
	;
stripands	;red,green,blue,yel,pur,cyn,wht

vwait	move	#1,vbcounter
.loop	tst	vbcounter
	bgt.l	.loop
	rts

;************** DATA ***************************

data

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

qcols	dc.b	1,2
qpal	dc	2
	dc	$544	;roof colour
	dc	$544	;floor colour
	cnop	0,4

qstrip	dc.l	0
qstripbot	dc.l	0
con0poke	dc	$100,0	;100=no qfloor!

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
player1	dc.l	0
player2	dc.l	0
doneflag	dc.l	0
memory	dc.l	0
memat	dc.l	0
shapelist	dc.l	0
bitmap	dc.l	0
	;
palette	dc.l	0	;the one we're using...
	;
palettes	ds.l	16	;16 palettes for 16 brightnesses
palettesw	ds.l	16
palettesr	ds.l	16

map_map	dc.l	0
map_grid	dc.l	0
map_poly	dc.l	0
map_ppnt	dc.l	0
map_rgbs	dc.l	0
map_rgbsw	dc.l	0
map_rgbsr	dc.l	0
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

cop	dc.l	0
copmod	dc	0
width	dc	0
hite	dc	0
minx	dc	0
midx	;
maxx	dc	0
miny	dc	0
midy	;
maxy	dc	0
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
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	dc	160-126 ;45*2
	dc	cy-120 ;45*2
	dc	126	;max width for 2 high = 90!
	dc	80
	dc	2
	dc	3
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	;
	dc	160-90
	dc	cy-90
	dc	90
	dc	90
	dc	2
	dc	2
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

cols24	macro
	dc	$180,0,$182,0,$184,0,$186,0
	dc	$188,0,$18a,0,$18c,0,$18e,0
	dc	$190,0,$192,0,$194,0,$196,0
	dc	$198,0,$19a,0,$19c,0,$19e,0
	dc	$1a0,0,$1a2,0,$1a4,0,$1a6,0
	dc	$1a8,0,$1aa,0,$1ac,0,$1ae,0
	endm

copinit	;initialization for display
	;
	dc	$1fc,15,$096,$120
	;
	dc	$08e,$1e81,$090,$23c1,$1e4,$2000
	dc	$092,$38,$094,$c0,$102,0
	;
	dc	$100,$a200,$108,80,$10a,80
	dc	$106,0,$10c,0	;bank, eor
	dc	$182,$fff,$184,$f0f,$186,$ff0
	;
chatplanes	dc	$e0,0,$e2,0,$e4,0,$e6,0
	;
	dc	26<<8+1,$fffe
	;
	dc	$140,0,$142,0,$144,0,$146,0
	dc	$148,0,$14a,0,$14c,0,$14e,0
	dc	$150,0,$152,0,$154,0,$156,0
	dc	$158,0,$15a,0,$15c,0,$15e,0
	dc	$160,0,$162,0,$164,0,$166,0
	dc	$168,0,$16a,0,$16c,0,$16e,0
	dc	$170,0,$172,0,$174,0,$176,0
	dc	$178,0,$17a,0,$17c,0,$17e,0
	;
chatdispon	dc	$1fe,0 ;096,$8100
	dc	$2401,$fffe,$096,$100
	dc	$094,$a0,$100,$7200,$108,6*40,$10a,6*40
	;
	;lo colour nybs - lo bank
	dc	$106,$0200
cols1	cols24
	;
	;lo nybs - hi bank
	dc	$106,$8200
cols2	cols24
	;
	;hi colour nybs - lo bank
	dc	$106,0
cols3	cols24
	;
	;hi colour nybs - hi bank
	dc	$106,$8000
cols4	cols24
	;
	;slice...
sl1	;
	dc	$e0,0,$e2,0
	dc	$e4,0,$e6,0
	dc	$e8,0,$ea,0
	dc	$ec,0,$ee,0
	dc	$f0,0,$f2,0
	dc	$f4,0,$f6,0
	dc	$f8,0,$fa,0
	dc	$08e,$2c81,$090,$f4c1	;diw
	dc	$0001,$fffe	;wait for slice!
	dc	$096,$8100
	;
	dc	$084,0,$086,0,$08a,0
sl2	;
	dc	$e0,0,$e2,0
	dc	$e4,0,$e6,0
	dc	$e8,0,$ea,0
	dc	$ec,0,$ee,0
	dc	$f0,0,$f2,0
	dc	$f4,0,$f6,0
	dc	$f8,0,$fa,0
	;56
	dc	$08e,$2c81,$090,$f4c1	;diw
	;64
	dc	$0001,$fffe	;wait for slice!
	;68
	dc	$096,$8100
	;72
	;
	dc	$084,0,$086,0,$08a,0
	;
cstop	dc	$096,$0100	;display DMA off...
	dc	$ffff,$fffe
copinitf	;

bigdata

textscrns	ds.l	8	;8*20=160
textures	ds.l	160

;************** SLOW SUBS **********************

slowsubs

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
	beq.l	.done
	;
	move.l	d0,a6
	lea	applname(pc),a0
	lea	itemname(pc),a1
	lea	gloomgame2(pc),a2
	moveq	#2,d0	;20 bytes
	moveq	#-1,d1
	jsr	-42(a6)	;storenv
	tst.l	d0
	bne.l	.done	;error!
	;
	lea	applname(pc),a0
	lea	itemname(pc),a1
	moveq	#-1,d1
	moveq	#1,d2
	jsr	-66(a6)	;setnvprotection
	;
.done	rts

loadgloomgame	move.l	nv,d0
	beq.l	.done
	;
	move.l	d0,a6
	lea	applname(pc),a0
	lea	itemname(pc),a1
	moveq	#-1,d1
	jsr	-30(a6)	;getcopnv
	tst.l	d0
	beq.l	.done
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
	bcs.l	.skip
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
	bpl.l	.plus
	;
	moveq	#1,d0
	cmp	#-128,d1
	bgt.l	.rts
	neg	d0
.rts	neg	d0
	rts
	;
.plus	moveq	#1,d0	;+
	cmp	#128,d1
	bge.l	.rts2
	neg	d0
.rts2	neg	d0
	rts

checklock	cmp	#2,d0
	bgt.l	.max
	cmp	#-2,d0
	bge.l	.rts
	moveq	#-2,d0
.rts	rts
.max	moveq	#2,d0
	rts

locklogic	;locking on to defender machine
	;
	bsr.l	playertimers	;do timer stuff...
	bsr.l	getcntrl	;player control
	;
	moveq	#0,d2	;how many locked
	move	ob_x(a5),d0
	sub	ob_telex(a5),d0
	bne.l	.lockx
	addq	#1,d2
	bra.l	.lockx2
.lockx	bsr.l	checklock
	sub	d0,ob_x(a5)
.lockx2	;
	move	ob_z(a5),d0
	sub	ob_telez(a5),d0
	bne.l	.lockz
	addq	#1,d2
	bra.l	.lockz2
.lockz	bsr.l	checklock
	sub	d0,ob_z(a5)
.lockz2	;
	move	ob_rot(a5),d1
	move	ob_telerot(a5),d0
	bsr.l	findanglesign
	;
	move	ob_rot(a5),d1
	sub	ob_telerot(a5),d1
	and	#255,d1
	bne.l	.lockrot
	addq	#1,d2
	bra.l	.lockrot2
.lockrot	cmp	#4,d1
	bls.l	.skip
	cmp	#256-4,d1
	bcs.l	.four
	or	#$ff00,d1
	neg	d1
	bra.l	.skip
.four	moveq	#4,d1
.skip	tst	d0
	bmi.l	.skip2
	neg	d1
.skip2	add	d1,ob_rot(a5)
	;
.lockrot2	bsr.l	unbounce
	tst	ob_bounce(a5)
	bne.l	.rts
	;
	subq	#3,d2
	bne.l	.rts
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
	bra.l	initnewdef
	;
.rts	rts

ltk	dc	20,35,50
lnd	dc	25,20,15

playdefender	bsr.l	atmachine
	bsr.l	defender
	move	landerstokill(pc),d0
	ble.l	.win
	move	playerlives(pc),d0
	ble.l	.lose
	rts
.win	addq	#1,ob_lives(a5)
	move	#-1,ob_update(a5)
	tst	gametype
	beq.l	.lose
	jsr	getother
	tst	ob_lives(a0)
	beq.l	.lose
	addq	#1,ob_lives(a0)
	move	#-1,ob_update(a0)
.lose	move	#96,ob_delay(a5)
	move.l	#waittolive,ob_logic(a5)
	rts

waittolive	bsr.l	atmachine
	bsr.l	defender
	subq	#1,ob_delay(a5)
	bgt.l	.rts
	move.l	#playerlogic,ob_logic(a5)
.rts	rts

atmachine	;standing at machine logic
	;
	bsr.l	playertimers	;do timer stuff...
	bsr.l	getcntrl	;player control
	;
	;OK, rotate slightly in front of machine!
	;
	move	joyx(pc),d0
	bne.l	.rot
	move	ob_rotspeed(a5),d0
	bpl.l	.rp
	addq	#2,ob_rotspeed(a5)
	ble.l	.rotdone
	clr	ob_rotspeed(a5)
	bra.l	.rotdone
.rp	subq	#2,ob_rotspeed(a5)
	bge.l	.rotdone
	clr	ob_rotspeed(a5)
	bra.l	.rotdone
.rot	bgt.l	.rplus
	subq	#1,ob_rotspeed(a5)
	cmp	#-8,ob_rotspeed(a5)
	bge.l	.rotdone
	move	#-8,ob_rotspeed(a5)
	bra.l	.rotdone
.rplus	addq	#1,ob_rotspeed(a5)
	cmp	#8,ob_rotspeed(a5)
	ble.l	.rotdone
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
	beq.l	.nox
	bpl.l	.xrite
	move	#1,playershape
	sub.l	#$8000,playerxa
	bpl.l	.xmore
	cmp.l	#-$30000,playerxa
	bge.l	.xdone
	move.l	#-$30000,playerxa
	bra.l	.xdone
.xmore	sub.l	#$4000,playerxa
	bra.l	.xdone
	;
.xrite	clr	playershape
	add.l	#$8000,playerxa
	ble.l	.xmore2
	cmp.l	#$30000,playerxa
	ble.l	.xdone
	move.l	#$30000,playerxa
	bra.l	.xdone
.xmore2	add.l	#$4000,playerxa
	bra.l	.xdone
	;
.nox	;to rest!
	move.l	playerxa(pc),d0
	beq.l	.xdone
	bpl.l	.xp
	add.l	#$1000,playerxa
	ble.l	.xdone
	clr.l	playerxa
.xp	sub.l	#$1000,playerxa
	bge.l	.xdone
	clr.l	playerxa
.xdone	;
	move.l	playerxa(pc),d0
	add.l	d0,playerx
	and	#255,playerx
	;
	move	joyy(pc),d0
	add	d0,playery
	cmp	#1,playery
	blt.l	.yf
	cmp	#34,playery
	blt.l	.ydone
	move	#34,playery
	bra.l	.ydone
.yf	move	#1,playery
.ydone	;
	move	joyb(pc),d0
	beq.l	.nofire
	move	deflbut(pc),d0
	bne.l	.rts
	st	deflbut
	;
	addfirst	defobjects
	beq.l	.rts
	move.l	#$20000,d0	;bullet speed!
	move	playershape(pc),d1
	beq.l	.rite
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
	bra.l	playsfx
	;
.nofire	clr	deflbut
.rts	rts

deffrag	add.l	#$1000,de_ya(a5)
	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	cmp	#36,de_y(a5)
	bge.l	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	rts

impfrag	subq	#1,de_delay(a5)
	ble.l	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	rts

blowuplander	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr.l	playsfx
	subq	#1,landerstokill
	moveq	#7,d7	;8 pixel exp
.loop2	addlast	defobjects
	beq.l	killdefobject
	move	de_x(a5),de_x(a0)
	move	de_y(a5),de_y(a0)
	bsr.l	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_xa(a0)
	bsr.l	rndw
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
	bra.l	killdefobject

blowupplayer	moveq	#3,d7
	;
.loop	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr.l	playsfx
	dbf	d7,.loop
	;
	moveq	#31,d7
.loop2	addlast	defobjects
	beq.l	.rts
	move	playerx(pc),de_x(a0)
	move	playery(pc),de_y(a0)
	bsr.l	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_xa(a0)
	bsr.l	rndw
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
	ble.l	.skip
	rts
.skip	move.l	#landerlogic,de_logic(a5)
	move	#4,de_shape(a5)
landerlogic	;
	move	playershape(pc),d0
	bmi.l	.done
	;
	move	de_x(a5),d0
	move	d0,d2
	move	de_y(a5),d1
	move	d1,d3
	;
	sub	playerx(pc),d0
	bpl.l	.skipn1
	neg	d0
.skipn1	cmp	#6,d0
	bcc.l	.chk
	sub	playery(pc),d1
	bpl.l	.skipn2
	neg	d1
.skipn2	cmp	#4,d1
	bcs.l	blowupplayer
	;
	;check if shot!
.chk	lea	defobjects(pc),a0
.loop	move.l	(a0),a0
	tst.l	(a0)
	beq.l	.done
	move	de_colltype(a0),d0
	beq.l	.loop
	;
	move	d2,d0
	sub	de_x(a0),d0
	bpl.l	.skip
	neg	d0
.skip	cmp	#6,d0
	bcc.l	.loop
	;
	move	d3,d1
	sub	de_y(a0),d1
	bpl.l	.skip2
	neg	d1
.skip2	cmp	#4,d1
	bcc.l	.loop
	;
	;BOOM!
	;
	bra.l	blowuplander
.done	;
	move	de_x(a5),d0
	sub	playerx(pc),d0
	and	#255,d0
	cmp	#128,d0
	bcs.l	.left
	;
	;go right-ish!
	;
	add.l	#$4000,de_xa(a5)
	cmp.l	#$10000,de_xa(a5)
	ble.l	.xdone
	move.l	#$10000,de_xa(a5)
	bra.l	.xdone
	;
.left	sub.l	#$4000,de_xa(a5)
	cmp.l	#-$10000,de_xa(a5)
	bge.l	.xdone
	move.l	#-$10000,de_xa(a5)
	;
.xdone	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	;
	move	de_y(a5),d0
	sub	playery(pc),d0
	bpl.l	.up
	;
	;down
	;
	add.l	#$2000,de_ya(a5)
	cmp.l	#$8000,de_ya(a5)
	ble.l	.ydone
	move.l	#$8000,de_ya(a5)
	bra.l	.ydone
	;
.up	sub.l	#$2000,de_ya(a5)
	cmp.l	#-$8000,de_ya(a5)
	bge.l	.ydone
	move.l	#-$8000,de_ya(a5)
	;
.ydone	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	;
	rts

defbull	subq	#1,de_delay(a5)
	ble.l	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	rts

killdefobject	move.l	a5,a0
	killitem	defobjects
	move.l	a0,a5
	move.l	defstack(pc),a7
	bra.l	def_loop

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
	beq.l	.nolander
	subq	#1,landercnt
	bgt.l	.nolander
	;
	;add a lander!
	;
	addlast	defobjects
	beq.l	.nolander
	subq	#1,landerstoadd
	move	landerdelay(pc),landercnt
	;
	bsr.l	rndw
	and	#255,d0
	move	d0,d2
	move	d0,de_x(a0)
	moveq	#32,d0
	bsr.l	rndn
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
	beq.l	.nolander
	;
	bsr.l	rndw
	ext.l	d0
	lsl.l	#1,d0	;xadd
	move.l	d0,d4
	move.l	d0,de_xa(a0)
	bsr.l	rndw
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
	bmi.l	.dead
	bsr.l	movedefplayer
.dead	;
	move	playerx(pc),d0
	sub	#22,d0
	bsr.l	drawmounts
	;
	;OK, scanner time!
	;
	moveq	#5,d0
	moveq	#3,d1
	moveq	#12,d2
	bsr.l	drawsprite
	moveq	#39,d0
	moveq	#3,d1
	moveq	#13,d2
	bsr.l	drawsprite
	move	playery(pc),d1
	lsr	#3,d1
	addq	#1,d1
	moveq	#22,d0
	moveq	#7,d2
	bsr.l	drawsprite
	;
	lea	defobjects(pc),a5
.scanloop	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.scandone
	cmp	#4,de_shape(a5)
	bne.l	.scanloop
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
	bsr.l	drawsprite
	bra.l	.scanloop
.scandone	;	
	move.l	a7,defstack
	lea	defobjects(pc),a5
	;
def_loop	move.l	(a5),a5
	tst.l	(a5)
	beq.l	.done
	;
	move.l	de_logic(a5),a0
	jsr	(a0)
	;
	move	de_x(a5),d0
	sub	playerx(pc),d0
	and	#255,d0
	cmp	#128,d0
	bcs.l	.nob
	or	#$ff00,d0
.nob	add	#22,d0
	move	de_y(a5),d1
	move	de_shape(a5),d2
	bsr.l	drawsprite
	;
	bra.l	def_loop
.done	;
	move	playershape(pc),d0
	bmi.l	.dead
	;
	move	landerstokill(pc),d0
	bgt.l	.bye2
	subq	#1,landerstokill
	subq	#1,d0
	and	#$10,d0
	beq.l	.bye2
	moveq	#22,d0
	moveq	#18,d1
	moveq	#11,d2
	bsr.l	drawsprite
.bye2	;
	moveq	#22,d0
	move	playery(pc),d1
	move	playershape(pc),d2
	bsr.l	drawsprite
	bra.l	.bye
	;
.dead	subq	#1,playershape
	cmp	#-96,playershape
	bcc.l	.no
	move	playerlives(pc),d3
	beq.l	.gameover
	;
	bsr.l	initnewdef
	bra.l	.bye
	;
.no	move	playerlives(pc),d3
	bne.l	.showlives
.gameover	and	#$10,d2
	beq.l	.exit
	moveq	#22,d0
	moveq	#18,d1
	moveq	#10,d2
	bsr.l	drawsprite
	bra.l	.exit
	;
.bye	move	playerlives(pc),d3
	beq.l	.exit
.showlives	subq	#1,d3
	moveq	#1,d1
	;
.lives	moveq	#2,d0
	moveq	#9,d2
	movem	d1/d3,-(a7)
	bsr.l	drawsprite
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
	bmi.l	.xmi
	move	d2,d0
	add	d4,d0
	sub	#44,d0
	ble.l	.xok
	sub	d0,d4
	bgt.l	.xok
.xrts	rts
.xmi	add	d2,d4	;reduce width
	ble.l	.xrts
	move	d2,d0
	lsl	#6,d2
	add	d0,d2
	sub	d2,a1
	bra.l	.xdone
.xok	move	d2,d0
	lsl	#6,d2
	add	d0,d2
	add	d2,a0
.xdone	;
	tst	d3
	bmi.l	.ymi
	move	d3,d0
	add	d5,d0
	sub	#36,d0
	ble.l	.yok
	sub	d0,d5
	bgt.l	.yok
.yrts	rts
.ymi	add	d3,d5	;reduce width
	ble.l	.yrts
	sub	d3,a1
	bra.l	.ydone
.yok	add	d3,a0
.ydone	;
	moveq	#65,d7
	sub	d5,d7
	subq	#1,d4	;w
	subq	#1,d5	;h
.loop	move	d5,d6
.loop2	move.b	(a1)+,d0
	beq.l	.col0
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
	bne.l	.skip
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
	bne.l	.skip2
	sub.l	d6,a1
.skip2	dbf	d1,.loop2
	;
	rts

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
	beq.l	.rts
	tst	chatok
	bne.l	.rts
	;
	bsr.l	chatcls
	lea	chatontxt(pc),a2
.loop	move.b	(a2)+,d0
	beq.l	.done
	moveq	#3,d1
	bsr.l	chatprintout
	bra.l	.loop
.done	clr	chatoutput
	clr	chatoutget
	clr	chatinput
	clr	chatinget
	st	chatok
	move.l	coplist(pc),a0
	move.l	#$0968100,chatdispon-copinit(a0)
	;
.rts	rts

chatoff	;disable chat mode
	;
	tst	linked
	beq.l	chatoffrts
	tst	chatok
	beq.l	chatoffrts
	;
dochatoff	sf	chatok
	bsr.l	chatcls
	move.l	coplist(pc),a0
	move.l	#$1fe0000,chatdispon-copinit(a0)
	;
chatoffrts	rts

chatscrollin	;scroll chatin window across a byte.
	;
	move	d2,-(a7)
	move.l	chatmap,a0
	lea	40(a0),a0
	bra.l	chatsc
	
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
	bcc.l	chatscrollout
	addq	#1,chatxout
	rts

calcchar	ext	d0
	cmp	#'A',d0
	bcs.l	.notal
	and	#31,d0
	add	#9,d0
	rts
.notal	cmp	#'.',d0
	bne.l	.not1
	moveq	#36,d0
	rts
.not1	cmp	#'!',d0
	bne.l	.not2
	moveq	#37,d0
	rts
.not2	cmp	#'?',d0
	bne.l	.not3
	moveq	#38,d0
	rts
.not3	cmp	#',',d0
	bne.l	.not4
	moveq	#39,d0
	rts
.not4	sub	#48,d0
	rts

chatprintout	;d0.b=chr$() to print, d1=colour (1,2,3)
	;
	cmp.b	#32,d0
	beq.l	chatspcout
	bsr.l	calcchar
	;
	movem.l	d2/a2,-(a7)
	;
	cmp	#40,chatxout
	bcs.l	.nosc
	;
	movem	d0-d1,-(a7)
	bsr.l	chatscrollout
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
	beq.l	.skip
	lea	80(a1),a2
	cmp	#2,d1
	beq.l	.skip2
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
	bcc.l	chatscrollin
	addq	#1,chatxin
	rts

chatprintinhex	move	d0,-(a7)
	lsr	#4,d0
	bsr.l	.skip
	move	(a7)+,d0
	;
.skip	and	#15,d0
	add	#48,d0
	cmp	#58,d0
	bcs.l	chatprintin
	addq	#7,d0
	;
chatprintin	;d0.b=chr$() to print, d1=colour (1,2,3)
	;
	cmp.b	#32,d0
	beq.l	chatspcin
	bsr.l	calcchar
	;
	movem.l	d2/a2,-(a7)
	;
	cmp	#40,chatxin
	bcs.l	.nosc
	;
	movem	d0-d1,-(a7)
	bsr.l	chatscrollin
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
	beq.l	.skip
	lea	80(a1),a2
	cmp	#2,d1
	beq.l	.skip2
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
	beq.l	.wait
	move	#1,$dff09c
	;
	rts

rbfchk	;return ne if something there!
	;
	move	rbfcnt(pc),d0
	rts

serwait	bsr.l	rbfchk
	beq.l	serwait
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
	bmi.l	.fuck
	move	#$800,$dff09c
	;
	move	chatok(pc),d1
	beq.l	.chskip
	bclr	#6,d0
	beq.l	.chskip
	add.b	#32,d0
	;
	lea	chatin(pc),a1
	move	chatinput(pc),d1
	and	#31,d1
	move.b	d0,0(a1,d1)
	addq	#1,chatinput
	addq	#1,chatcnt
	bra.l	.bye
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
	bra.l	.fuck

rbuff	ds.b	sblen
rput	dc	0
rget	dc	0

medat	dc.l	0
titlemed	dc.l	0
loadingmed	dc.l	0
fadevol	dc	0	;non-zero=fade to 0!

relocate	;a0=pointer to what to relocate
	;
	bsr.l	flushc
	;
	move.l	(a0),d0
	beq.l	.rts
	move.l	d0,a1
	add.l	#32,(a0)
	lea	28(a1),a0
	move.l	(a0)+,d0
	lea	0(a0,d0.l*4),a1
	cmp.l	#$3ec,(a1)+
	bne.l	.rts
	move.l	(a1)+,d0
	addq	#4,a1
	move.l	a0,d2
	;
.loop	move.l	(a1)+,d1	;offset
	add.l	d2,0(a0,d1)
	subq.l	#1,d0
	bne.l	.loop
	;
.rts	bsr.l	flushc
	;
	rts

initmed	lea	medat,a0
	tst.l	(a0)
	bne.l	.noreloc
	;
	move.l	#medplayer,(a0)
	bsr.l	relocate
	;
.noreloc	move.l	medat(pc),a1
	move.l	chipzero(pc),a0
	jsr	(a1)
	;
	move.l	medat(pc),a1
	move.l	titlemed(pc),a0
	jsr	4(a1)
	;
	move.l	loadingmed(pc),d0
	beq.l	.no
	move.l	d0,a0
	move.l	medat(pc),a1
	jsr	4(a1)
.no	;
	rts

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

progfiles	dc.l	bigfont_+1	;odd=chipmem!
	dc.b	'misc/bigfont.bin',0
	even
	dc.l	smallfont_+1	;odd=chipmem!
	dc.b	'misc/smallfont.bin',0
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
	;
	dc.l	0

loadfiles	;
	push
	move.l	a0,a2
	;
.loop	move.l	(a2)+,d0
	beq.l	.done
	moveq	#1,d1
	bclr	#0,d0
	beq.l	.nochip
	moveq	#2,d1
.nochip	move.l	d0,a3
	move.l	a2,a0
	bsr.l	loadfile
	move.l	d0,(a3)
.z	tst.b	(a2)+
	bne.l	.z
	exg	a2,d0
	addq.l	#1,d0
	bclr	#0,d0
	exg	a2,d0
	bra.l	.loop
	;
.done	pull
	rts

diskmenu	dc.b	1
	dc.b	'please insert gloom data disk',0
	even

magicfiles	dc.l	magic
	dc.b	'pics/blackmagic',0
	even
	dc.l	magicpal
	dc.b	'pics/blackmagic.pal',0
	even
	dc.l	0

magic	dc.l	0
magicpal	dc.l	0
vbr	dc.l	0

initmain	;
	move.l	4.w,a6
	move.l	276(a6),a0
	move.l	#-1,184(a0)
	;
	bsr.l	initrawmap
	;
	jsr	-150(a6)	;supervisor
	dc	$4e7a,$2801	;get vbr->d2
	jsr	-156(a6)
	move.l	d2,vbr
	;
	lea	ciaaname,a1
	jsr	-498(a6)
	move.l	d0,ciaa
	move.l	d0,a0
	movem.l	$64(a0),d0-d1
	movem.l	d0-d1,rawstuff
	move	#$4000,$dff09a
	move.l	rawtable(pc),$64(a0)
	move.l	#rawkeyread,$68(a0)
	move	#$c000,$dff09a
	;
	move.l	#8,d0
	move.l	#$10002,d1
	allocmem	chipzero
	move.l	d0,chipzero
	;
	move.l	#256,d0	;128 words high max!
	moveq	#2,d1
	allocmem	qstrip
	move.l	d0,qstrip
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
	move.l	#16*512*2,d0	;16 shades, 256 words
	moveq	#1,d1
	allocmem	map_rgbs
	;
	move.l	#map_rgbs_,map_rgbs
	;move.l	d0,map_rgbs
	;add.l	#16*512,d0
	move.l	d0,map_rgbsw
	add.l	#16*512,d0
	move.l	d0,map_rgbsr
	;
	st	paused
	clr	dispnest
	clr.l	font
	bsr.l	initsfx
	bsr.l	initvbint
	bsr.l	initdisplay
	bsr.l	dispoff
	;
	lea	magicfiles,a0
	bsr.l	loadfiles
	;
	move.l	magic,a0
	move.l	magicpal,a1
	bsr.l	makeiff
	bsr.l	showiff
	bsr.l	dispon
	move	#50,vbcounter
	;
	lea	progfiles,a0
	bsr.l	loadfiles
	;
	bsr.l	initbmappal
	bsr.l	initmed
	bsr.l	initser
	bsr.l	calcbaud
	bsr.l	makecoloffs
	bsr.l	initdarktable
	;
	bset	#15,remapped
	bne.l	.noremap
	;
	move.l	map_rgbs(pc),a0
	move	#-1,(a0)+
	move.l	a0,map_rgbsat
	;
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
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	lea	128*128+groundtile,a2
	move.l	a2,a0
	bsr.l	addpal
	lea	groundtile,a0
	move.l	a2,a1
	bsr.l	remap
	;
	lea	128*128+ceilingtile,a2
	move.l	a2,a0
	bsr.l	addpal
	lea	ceilingtile,a0
	move.l	a2,a1
	bsr.l	remap
; vasm-wrapper: orphan Devpac elseif marker disabled: 	elseif
	;
	lea	qpal,a0
	bsr.l	addpal
	lea	qcols,a0
	lea	qpal,a1
	bsr.l	remap
	;
	move.l	map_rgbsat(pc),map_rgbsat2
.noremap	;
	move.l	map_rgbsat2(pc),map_rgbsat
	;
	moveq	#0,d0
	bsr.l	loadanobj	;load player1
	moveq	#1,d0
	bsr.l	loadanobj	;load player2
	moveq	#2,d0
	bsr.l	loadanobj	;load tokens (health)
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
	bgt.l	.w5sex
	;
	bsr.l	dispoff
	lea	iffwindow,a0
	bsr.l	freewindow
	;
	move.l	magic,a1
	freemem	magic
	move.l	magicpal,a1
	freemem	magicpal
	;
	move	#$1234,d0
	bsr.l	seedrnd2
	;
	ifne	cd32
	lea	nvname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,nv
	bsr.l	loadgloomgame
	endc
	;
	bra.l	forbid

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
	beq.l	.done
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	40(a0),a1
	add.l	a1,a1
	add.l	a1,a1
	cmp.b	#9,(a1)+	;9 chars
	bne.l	.loop
	lea	lockname(pc),a2
	moveq	#8,d0	;check 9 chars!
.loop2	cmp.b	(a1)+,(a2)+
	bne.l	.loop
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
	bsr.l	permit
	move.l	#gamename,d1
	move.l	#1005,d2
	move.l	dosbase(pc),a6
	jsr	-30(a6)
	move.l	d0,d1
	beq.l	.nolock
	jsr	-36(a6)	;close it!
	bra.l	.load
	;
.nolock	bsr.l	forbid
	bsr.l	checkdatadisk
	beq.l	.dataok	;already there?
	;
	lea	diskmenu,a0
	bsr.l	qmenu
	;
	;OK, gotta swap disks and pick up data files!
	;
.wfd	bsr.l	permit
	move.l	grbase(pc),a6
	jsr	-270(a6)
	bsr.l	forbid
	bsr.l	checkdatadisk
	bne.l	.wfd
	;
	bsr.l	finitqmenu
	;
.dataok	bsr.l	permit
	bsr.l	undir	;release old lock!
	move.l	#lockname,d1
	moveq	#-2,d2
	move.l	dosbase(pc),a6
	jsr	-84(a6)	;lock?
	move.l	d0,d1
	beq.l	.wfd
	jsr	-126(a6)	;make current dir!
	move.l	d0,oldlock
	;
.load	lea	datafiles,a0
	bsr.l	loadfiles
	bra.l	forbid

undir	move.l	oldlock(pc),d1
	beq.l	.rts
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
	bne.l	.li
.rts	rts
.li	;
	;bsr	qsync
	bsr.l	qsync2
	;
	moveq	#31,d5
	;
	tst	linked
	bmi.l	.slave
	;
	;MASTER - average out 32 sends of random data!
	;
	moveq	#0,d6	;sum
	;
.mloop	moveq	#0,d7
	bsr.l	vwait
	bsr.l	serput
	;
.mwait	addq	#1,d7
	bsr.l	vwait
	bsr.l	rbfchk
	beq.l	.mwait
	;
	bsr.l	serget
	add	d7,d6
	dbf	d5,.mloop
	;
	add	#64,d6
	lsr	#7,d6	;/32 = avg. /2=half, /2=25 FPS
	addq	#1,d6	;safety...
	;
	move	d6,d0
	move	d0,lagtime
	bsr.l	serput
	bra.l	initlag
	;
.slave	;OK, bounce back 32 items...
	;
	moveq	#31,d5
.sloop	bsr.l	serwait
	bsr.l	serput
	dbf	d5,.sloop
	;
	;now, wait to get told lagtime!
	;
	bsr.l	serwait
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
	beq.l	.rts
	;
.more	bsr.l	rbfchk	;anything there?
	beq.l	.no
	bsr.l	serget
	cmp.b	#$8f,d0
	bne.l	.more
	move.b	#$8f,d0
	bra.l	serput
	;
.no	lea	syncmenu,a0
	bsr.l	qmenu
	move.b	#$8f,d0
	bsr.l	serput
	;
.loop	bsr.l	serwait
	cmp.b	#$8f,d0
	bne.l	.loop
	;
	bra.l	finitqmenu
	;
.rts	rts

qsync2	;OK, quick sync up, but now 'waiting' menu
	;
	move	linked(pc),d0
	beq.l	.rts
	;
	move.b	#$8f,d0
	bsr.l	serput
	;
.loop	bsr.l	serwait
	cmp.b	#$8f,d0
	bne.l	.loop
	;
.rts	rts

combatnokmenu	dc.b	1
	dc.b	'sorry...not available in demo',0
	even

initnewgame	;
	ifeq	combatok
	;
	cmp	#2,gametype
	bne.l	.skipnok
	lea	combatnokmenu(pc),a0
	bsr.l	qmenu
	;
	bsr.l	selmenu
	;
	bsr.l	finitqmenu
	move	#-1,gametype
	rts
.skipnok	;
	endc
	;
	move	gametype(pc),twowins
	beq.l	.skip
	tst	linked
	beq.l	.skip
	clr	cheat
	;
	nop
	;
	ifeq	debugser
	clr	twowins
	endc
.skip	;
	tst.l	map_test
	bne.l	.skhit
	;
	bset	#15,gloomdata
	bne.l	.gotdata
.skhit	;
	ifne	cd32
	bsr.l	permit
	lea	datafiles,a0
	bsr.l	loadfiles
	bsr.l	forbid
	elseif
	bsr.l	askdatadisk
	endc
.gotdata	;
	bsr.l	qsync
	;
	move.l	medat(pc),a1
	jsr	12(a1)
	cmp	#2,gametype
	bne.l	normalgame
	;
	;combat type game!
	;
	move	#6,p1_ob_collwith
	move	#5,p2_ob_collwith
	;
	lea	combatmenu,a0
	bsr.l	qmenu
	;
.loop	bsr.l	selmenu
	cmp	#3,d0
	bcs.l	.play
	bne.l	.loop
	;
	;change number of wins...
	;
	addq.b	#1,comnum
	cmp.b	#'9',comnum
	bls.l	.loop
	move.b	#'2',comnum
	bra.l	.loop
	;
.play	add	#49,d0
	move.b	d0,comseriesnum
	;
	bsr.l	finitqmenu
	move.b	comnum(pc),d0
	sub.b	#'0',d0
	ext	d0
	move	d0,p1lives
	move	d0,p2lives
	;
	lea	combatfiles(pc),a0
	bsr.l	permit
	bsr.l	loadfiles
	bra.l	forbid
normalgame	;
	;check for continue offsets in 'gloomgame' file!
	;
	tst	linked
	bge.l	.master
	;
	bsr.l	qsync
	bsr.l	longget
	add.l	script(pc),d0
	move.l	d0,scriptat
	bra.l	initpstuff
.master	;
	move.l	script(pc),scriptat	;default
	move.l	gloomgame(pc),a0
	lea	conttxts(pc),a1
	lea	conts(pc),a2
	moveq	#0,d7
	;
.loop	move.l	(a0)+,d0
	cmp.l	#'game',d0
	beq.l	.done
	;
	;another!
	;
	addq	#1,d7
	add.l	script(pc),d0
	move.l	d0,(a2)+
	lea	context(pc),a3
.loop2	move.b	(a3)+,(a1)+
	bne.l	.loop2
	subq	#1,a1
	move.l	d0,a3
.loop3	move.b	(a3)+,(a1)
	cmp.b	#10,(a1)+
	bne.l	.loop3
	clr.b	-1(a1)
	bra.l	.loop
	;
.done	move	linked(pc),-(a7)
	tst	d7
	beq.l	.more
	addq	#1,d7
	move.b	d7,contmenu
	;
	;OK, need a continue game menu...
	;
	clr	linked
	lea	gloom,a0
	lea	gloompal,a1
	lea	contmenu,a2
	bsr.l	pmenu
	bsr.l	selmenu
	bsr.l	finitpmenu
	;
	move	curropt(pc),d0
	beq.l	.more
	lea	conts(pc),a0
	move.l	-4(a0,d0*4),a0
.leol	cmp.b	#10,(a0)+
	bne.l	.leol
	move.l	a0,scriptat
	;
.more	move	(a7)+,linked
	beq.l	initpstuff
	bsr.l	qsync
	move.l	scriptat(pc),d0
	sub.l	script(pc),d0
	bsr.l	longput
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
	bsr.l	waitquiet
	;
	move.l	loadingmed(pc),d0
	beq.l	execscript
	move.l	d0,a0
	move.l	medat(pc),a1
	jsr	8(a1)	;start loading music!
	;
execscript	cmp	#2,gametype
	beq.l	scriptplay	;no script for combat game!
	;
	move.l	scriptat(pc),a0
	;
.loop	move.b	(a0)+,d0
	cmp.b	#10,d0
	beq.l	.loop
	and	#31,d0
	bne.l	.more
.loop2	cmp.b	#10,(a0)+
	bne.l	.loop2
	bra.l	.loop
.more	cmp	#27,d0
	bcc.l	.loop2
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
	beq.l	scriptpict
	cmp.l	#'draw',d0
	beq.l	scriptdraw
	cmp.l	#'text',d0
	beq.l	scripttext
	cmp.l	#'wait',d0
	beq.l	scriptwait
	cmp.l	#'play',d0
	beq.l	scriptplay
	cmp.l	#'done',d0
	beq.l	scriptdone
	cmp.l	#'dark',d0
	beq.l	scriptdark
	cmp.l	#'show',d0
	beq.l	scriptshow
	cmp.l	#'hide',d0
	beq.l	scripthide
	cmp.l	#'loop',d0
	beq.l	scriptloop
	cmp.l	#'rest',d0
	beq.l	scriptrest
	cmp.l	#'tile',d0
	beq.l	scripttile
	;
	warn	#$f80
	;
	;Hmmm....bad command
.fucked	;
	rts
	;
scriptdone	bsr.l	dispoff
	move.l	loadingmed(pc),d0
	beq.l	gameover
	;
	move.l	medat(pc),a1
	clr	fadevol
	jsr	12(a1)	;stop song
	bra.l	gameover

sccont	dc.b	'cont_'
	even

scriptrest	;restart point!
	;this changes...we add this to 'gloomgame' file now.
	;
	move.l	a0,d1
	sub.l	script(pc),d1	;offset from start of script!
.leol	cmp.b	#10,(a0)+
	bne.l	.leol
	move.l	a0,scriptat
	;
	move.l	gloomgame(pc),a1
.loop	move.l	(a1)+,d0
	cmp.l	#'game',d0
	beq.l	.add
	cmp.l	d0,d1
	bne.l	.loop
	;
	;already here!
	;
	bra.l	execscript
	;
.add	;OK, gotta add new scriptat position!
	;
	move.l	d1,-(a1)
	;
	;save it out!
	;
	bsr.l	permit
	ifne	cd32
	bsr.l	savegloomgame
	elseif
	lea	gamename,a0
	move.l	gloomgame,a1
	moveq	#32,d0
	bsr.l	savefile
	endc
	bsr.l	forbid
	;
	bra.l	execscript

scriptloop	move.l	script,scriptat
	bra.l	execscript

scripthide	bsr.l	dispoff
	bra.l	execscript

scriptshow	clr	pdelay
	bsr.l	dispon
	bra.l	execscript

scriptdraw	move.l	pic,a0
	move.l	picpal,a1
	bsr.l	makeiff
	bsr.l	showiff
	bra.l	execscript

fetchrest	move.l	scriptat,a0
	moveq	#-1,d0
.loop	addq	#1,d0
	move.b	(a0)+,(a1)
	cmp.b	#10,(a1)+
	bne.l	.loop
	clr.b	-(a1)
	move.l	a0,scriptat
	rts

picpath	dc.b	'pics/'
picname	ds.b	64
pic_pal	dc.b	'.pal',0
	even

pic	dc.l	0
picpal	dc.l	0

freeiff	push
	move.l	pic(pc),d0
	beq.l	.skip1
	clr.l	pic
	move.l	d0,a1
	freemem	pic
.skip1	move.l	picpal(pc),d0
	beq.l	.skip2
	clr.l	picpal
	move.l	d0,a1
	freemem	picpal
.skip2	pull
	rts

freetiles	push
	move.l	floor(pc),d0
	beq.l	.skip1
	clr.l	floor
	move.l	d0,a1
	freemem	floor
.skip1	move.l	roof(pc),d0
	beq.l	.skip2
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
	;
	lea	floortag(pc),a1
	bsr.l	fetchrest
	bsr.l	loadtile
	bra.l	execscript

loadtile	;
	;floor tag=tile extension...
	;
	bsr.l	freetiles
	lea	floortag(pc),a0
	lea	rooftag(pc),a1
.loop	move.b	(a0)+,(a1)+
	bne.l	.loop
	;
	bsr.l	permit
	lea	floorname(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,floor
	lea	roofname(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,roof
	bsr.l	forbid
	;
	move.l	map_rgbsfrom,map_rgbsat
	;
	move.l	floor(pc),a2
	lea	128*128(a2),a2
	move.l	a2,a0
	bsr.l	addpal
	move.l	floor(pc),a0
	move.l	a2,a1
	bsr.l	remap
	;
	move.l	roof(pc),a2
	lea	128*128(a2),a2
	move.l	a2,a0
	bsr.l	addpal
	move.l	roof(pc),a0
	move.l	a2,a1
	bsr.l	remap
	;
	move.l	map_rgbsat,map_rgbsfrom2
	rts

scriptpict	;load an iff
	bsr.l	freeiff
	lea	picname,a1
	bsr.l	fetchrest
	move.l	a1,-(a7)
	bsr.l	permit
	lea	picpath,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,pic
	lea	pic_pal,a0
	move.l	(a7)+,a1
.loop	move.b	(a0)+,(a1)+
	bne.l	.loop
	lea	picpath,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,picpal
	bsr.l	forbid
	bra.l	execscript

scriptdark	move.l	iffwindow+wi_cop,a0	;copperlist to darken!
	;
	;bank,32,bank,32...
	;
	addq	#6,a0
	moveq	#3,d0	;4 lots of 32 colours
	moveq	#31,d1
	;
	;skip first 8
	;
	;subq	#8,d1
	;lea	32(a0),a0
.loop	;
	move	(a0),d2	;hi nyb
	move	132(a0),d3	;lo nyb!
	and	#$eee,d3
	lsr	#1,d3
	move	d2,d4
	and	#$111,d4
	lsl	#3,d4
	or	d4,d3
	and	#$eee,d2
	lsr	#1,d2
	move	d2,(a0)
	move	d3,132(a0)
	;
	addq	#4,a0
	dbf	d1,.loop
	moveq	#31,d1
	lea	136(a0),a0
	dbf	d0,.loop
	bra.l	execscript

text	ds.b	64

scripttext	;print text on iff
	;a6=window, a4=message, d0=length of message, d6=Y
	;
	move	#2,pdelay
	;
	lea	text,a1
	bsr.l	fetchrest
	;
	lea	iffwindow,a6
	lea	text,a4
	move	wi_bh(a6),d6
	sub	#7,d6
	bsr.l	printmess2
	;
	tst	pdelay
	bmi.l	execscript
	clr	pdelay
	bra.l	execscript

scriptwait	;
	tst	pdelay
	bmi.l	execscript
	bsr.l	waitany
	bra.l	execscript

checkany	movem.l	d0-d7/a0-a6,-(a7)
	bsr.l	vwait
	bsr.l	readmenusel
	and	#$10,d0	;set ne if fire!
	movem.l	(a7)+,d0-d7/a0-a6
	rts

waitany	movem.l	d0-d7/a0-a6,-(a7)
.wait	bsr.l	checkany
	beq.l	.wait
.wait2	bsr.l	checkany
	bne.l	.wait2
	movem.l	(a7)+,d0-d7/a0-a6
	rts

copywin	moveq	#wi_size/2-1,d0
.loop	move	(a0)+,(a1)+
	dbf	d0,.loop
	rts

freeobjlist	lea	objlist,a2
	;
.loop	move.l	(a2)+,d0
	beq.l	.done
	move.l	d0,a3
	;
	move.l	(a3),d0
	beq.l	.skip
	move.l	d0,a1
	freemem	obj
	clr.l	(a3)
.skip	;
	move.l	4(a3),d0
	beq.l	.loop
	move.l	d0,a1
	freemem	objchunks
	clr.l	4(a3)
	bra.l	.loop
	;
.done	rts

freeobjlist2	lea	objlist,a2
	;
.loop	move.l	-(a2),d0
	beq.l	.done
	move.l	d0,a3
	;
	move.l	(a3),d0
	beq.l	.skip
	move.l	d0,a1
	freemem	obj2
	clr.l	(a3)
.skip	;
	move.l	4(a3),d0
	beq.l	.loop
	move.l	d0,a1
	freemem	objchunks2
	clr.l	4(a3)
	bra.l	.loop
	;
.done	rts

mappath	dc.b	'maps/'
mapname	ds.b	64
	even

getwindow	tst	twowins
	bne.l	.p2
	;
	lea	defwindow1_1p,a0
	lea	window1,a1
	bsr.l	copywin
	rts
	;
.p2	lea	defwindow1_2p,a0
	lea	window1,a1
	bsr.l	copywin
	;
	lea	defwindow2_2p,a0
	lea	window2,a1
	bsr.l	copywin
	rts

putwindow	tst	twowins
	bne.l	.p2
	;
	lea	window1,a0
	lea	defwindow1_1p,a1
	bsr.l	copywin
	rts
	;
.p2	lea	window1,a0
	lea	defwindow1_2p,a1
	bsr.l	copywin
	;
	lea	window2,a0
	lea	defwindow2_2p,a1
	bsr.l	copywin
	rts

linkswap	tst	linked
	bpl.l	.rts
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
	bge.l	.doit
	;
	;OK, slave...get map# from other player!
	;
	bsr.l	serwait
	move.b	d0,d2
	bra.l	.gotmap
	;
.doit	move	$dff006,d0
	bsr.l	seedrnd
	;
	move	comsleft(pc),d0
	bne.l	.pick
	moveq	#7,d0
	move	d0,comsleft
.pick	bsr.l	rndn
	lea	commaps(pc),a0
	subq	#1,comsleft
	move	comsleft(pc),d1
	move.b	0(a0,d0),d2		;map to play!
	move.b	0(a0,d1),0(a0,d0)
	move.b	d2,0(a0,d1)
	;
	tst	linked
	beq.l	.gotmap
	;
	move.b	d2,d0
	bsr.l	serput
	;
.gotmap	move.l	(a7)+,a1
	add.b	#48,d2
	move.b	d2,comseriesmap
	;
	lea	comname(pc),a0
.loop	move.b	(a0)+,(a1)+
	bne.l	.loop
	;
	move.l	combat,a0
	move.l	combatpal,a1
	bsr.l	makeiff
	bsr.l	showiff
	bsr.l	dispon
	move.b	comseriesnum(pc),floortag
	clr.b	floortag+1
	bra.l	loadtile

commaps	dc.b	1,2,3,4,5,6,7,8
comsleft	dc	7	;7 maps left!
comname	dc.b	'com'
comseriesnum	dc.b	'1_'
comseriesmap	dc.b	'1',0
	even

scriptplay	;
	lea	mapname,a1
	;
	cmp	#2,gametype
	bne.l	.notcombat
	;
	;OK, combat game is a happening...
	;
	;select from on-screen maps.
	;
	bsr.l	pickcombat
	bra.l	.gotname
	;
.notcombat	bsr.l	fetchrest
.gotname	;
	zerolist	objects,ob_size
	zerolist	doors,do_size
	zerolist	blood,bl_size
	zerolist	gore,go_size
	zerolist	rotpolys,rp_size
	;
	clr.l	player1
	clr.l	player2
	tst	gametype
	bne.l	.p2
	not.l	player2	;no player 2!
.p2	;
	bsr.l	permit
	;
	move.l	map_test(pc),d0
	bne.l	.use
	move.l	#mappath,d0
.use	move.l	d0,a0
	moveq	#1,d1
	bsr.l	loadfile
	move.l	d0,map_map
	;
	bsr.l	initmap
	bsr.l	loadtxts
	move	#$a3f7,d0
	bsr.l	seedrnd
	moveq	#1,d0
	bsr.l	execevent
	bsr.l	calcpalettes
	bsr.l	forbid
	bsr.l	makepalettes
	bsr.l	dispoff
	bsr.l	freewindows
	bsr.l	getwindow
	;
	;init player vars...
	;
	move.l	player1,a5
	;
	move	p1lives(pc),ob_lives(a5)
	;
	cmp	#2,gametype
	beq.l	.psk
	;
	move	p1health(pc),d0
	bne.l	.p1hok
	move	#25,p1health
	move.b	#ireload,p1reload
.p1hok	move	p1health(pc),ob_hitpoints(a5)
	move	p1weapon(pc),ob_weapon(a5)
	move.b	p1reload(pc),ob_reload(a5)
	;
.psk	bsr.l	resetplayer
	;
	tst	gametype
	beq.l	.p1
	;
	move.l	player2,a5
	move	p2lives(pc),ob_lives(a5)
	;
	cmp	#2,gametype
	beq.l	.psk2
	;
	move	p2health(pc),d0
	bne.l	.p2hok
	move	#25,p2health
	move.b	#ireload,p2reload
.p2hok	move	p2health(pc),ob_hitpoints(a5)
	move	p2weapon(pc),ob_weapon(a5)
	move.b	p2reload(pc),ob_reload(a5)
	;
.psk2	bsr.l	resetplayer
.p1	;
	bsr.l	linkswap
	;
	;save player positions at start of level!
	;
	move.l	player1(pc),a5
	move	ob_x(a5),p1x
	move	ob_z(a5),p1z
	move	ob_rot(a5),p1r
	tst	gametype
	beq.l	.shit
	move.l	player2(pc),a5
	move	ob_x(a5),p2x
	move	ob_z(a5),p2z
	move	ob_rot(a5),p2r
.shit	;
	;init windows...
	;
	move.l	player1(pc),a5
	move.l	#window1,ob_window(a5)
	move.l	ob_window(a5),a0
	bsr.l	makewindow
	move.l	ob_window(a5),a0
	bsr.l	showwindow
	bsr.l	initstats
	;
	tst	twowins
	beq.l	.onew
	;
	move.l	player2(pc),a5
	move.l	#window2,ob_window(a5)
	move.l	ob_window(a5),a0
	bsr.l	makewindow
	move.l	ob_window(a5),a0
	bsr.l	showwindow
	bsr.l	initstats
.onew	;
	bsr.l	calcbpos
	;
	;move	#$4000,fadevol	;fadeout med!
	;
	move.l	loadingmed(pc),d0
	beq.l	.nolmed
	move.l	medat(pc),a1
	clr	fadevol
	jsr	12(a1)	;stop song
.nolmed	;
	move	#$1f3a,d0
	bsr.l	seedrnd
	clr.l	sucker
	clr.l	sucking
	clr	finished
	clr	finished2
	clr	doneflag
	clr	showflag
	clr	escape
	clr	frame
	;
	bsr.l	syncup
	;
	clr	framecnt
	clr	paused
	bsr.l	drawall2
	bsr.l	dispon
	bsr.l	chaton
	;
mainloop	bsr.l	drawall
	move	escape(pc),d0
	beq.l	.noesc
	bsr.l	dogamemenu
	clr	escape
.noesc	move	finished(pc),d0
	beq.l	mainloop
	;
	st	paused
	bsr.l	chatoff
	bsr.l	dispoff
	bsr.l	qsync2
	bsr.l	freewindows
	bsr.l	linkswap
	bsr.l	freeobjlist
	bsr.l	freetxts
	bsr.l	freemap
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
	beq.l	exitgame
	subq	#1,d0
	beq.l	gameover
	subq	#1,d0
	beq.l	levelover
	subq	#1,d0
	beq.l	combatwon
	;
.fuck	warn	#$f08
	warn	#$80f
	bra.l	.fuck
	;
exitgame	cmp	#2,gametype
	bne.l	gameover
combatover	move.l	combat,a1
	freemem	combat
	move.l	combatpal,a1
	freemem	combatpal
gameover	bsr.l	freeiff
	bra.l	freetiles
levelover	;
	move.l	player1,a5
	move	ob_hitpoints(a5),p1health
	move	ob_lives(a5),p1lives
	move	ob_weapon(a5),p1weapon
	move.b	ob_reload(a5),p1reload
	;
	tst	gametype
	beq.l	.p1p1
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
	bcc.l	.used0
	move	d1,d0
.used0	move	d0,p1lives
	move	d0,p2lives
	;
.p1p1	tst.l	map_test
	bne.l	gameover
	bra.l	execscript_med
	;
combatwon	move.l	player1(pc),a5
	move	ob_lives(a5),p1lives
	beq.l	.p1lost
	move.l	player2(pc),a5
	move	ob_lives(a5),p2lives
	beq.l	.p2lost
	;
	;combat game continues!
	;
	bra.l	execscript_med
	;
.p1lost	;player 1 lost the game
	;
	lea	p2wins(pc),a2
	tst	linked
	beq.l	.combatmess
	lea	ploses_(pc),a2
	bgt.l	.combatmess
	lea	pwins_(pc),a2
	bra.l	.combatmess
	;
.p2lost	;player 2 lost combat game
	;
	lea	p1wins(pc),a2
	tst	linked
	beq.l	.combatmess
	lea	ploses_(pc),a2
	blt.l	.combatmess
	lea	pwins_(pc),a2
	;
.combatmess	move.l	combat,a0
	move.l	combatpal,a1
	bsr.l	pmenu
	bsr.l	selmenu
	bsr.l	finitpmenu
	bra.l	combatover

p1wins	dc.b	1,'player one wins combat game!',0
	even
p2wins	dc.b	1,'player two wins combat game!',0
	even
pwins_	dc.b	1,'player wins combat game!',0
	even
ploses_	dc.b	1,'player loses combat game!',0
	even

freemap	move.l	map_map,d0
	beq.l	.done
	move.l	d0,a1
	freemem	map
	clr.l	map_map
.done	rts

inccntrl	addq	#1,(a2)
	cmp	#5,(a2)
	bcs.l	.pok
	clr	(a2)
.pok	move	(a2),d0
	cmp	(a3),d0
	beq.l	inccntrl
	;
.there	lea	popts(pc),a0
	move.l	0(a0,d0*4),a0
.sk	move.b	(a0)+,(a1)+
	bne.l	.sk
	rts

dointro	;
	lea	gloom,a0
	lea	gloompal,a1
	jsr	makeiff
	jsr	showiff
	;
	lea	gloombrush,a0
	lea	iffwindow,a1
	move.l	wi_bmap(a1),a1
	add.l	#168*7*40,a1
	bsr.l	decodeiff
	;
	bsr.l	dispon
	;
	bsr.l	chaton
	;
	bsr.l	waitany
	;
	lea	startmenu,a4
	tst	linked
	beq.l	.use
	lea	startmenu2,a4
.use	lea	iffwindow,a6
	jsr	initmenu
	;
.sel	jsr	selmenu
	;
	tst	linked
	beq.l	.notlinked
	;
	cmp	#2,d0
	bcs.l	.newgame2
	subq	#2,d0
	beq.l	.unlink
	subq	#1,d0
	beq.l	.about
	subq	#1,d0
	beq.l	.exitgloom
	bra.l	.sel
.unlink	;
	bsr.l	qsync2
	bsr.l	chatoff
	clr	linked
	lea	p2ctype(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr.l	inccntrl
	;
	bsr.l	finitpmenu
	bra.l	dointro
	;
.newgame2	addq	#1,d0
	move	d0,gametype
	bsr.l	qsync2
	bsr.l	chatoff
	bra.l	finitpmenu
	;
.notlinked	cmp	#3,d0
	bcs.l	.newgame
	;
	subq	#3,d0
	bne.l	.notp1
	;
	lea	p1ctype(pc),a1
	lea	p1_ob_cntrl,a2
	lea	p2_ob_cntrl,a3
	bsr.l	inccntrl
	bra.l	.sel
	;
.notp1	subq	#1,d0
	bne.l	.notp2
	;
	lea	p2ctype(pc),a1
	lea	p2_ob_cntrl,a2
	lea	p1_ob_cntrl,a3
	bsr.l	inccntrl
	bra.l	.sel
	;
.notp2	subq	#1,d0
	bne.l	.notlink
	;
	bsr.l	finitpmenu
	bsr.l	linkup
	bra.l	dointro
	;
.notlink	subq	#1,d0
	bne.l	.notvile
	;
	addq	#1,mode
	and	#1,mode
	move	mode(pc),d0
	lea	modes,a0
	move.l	0(a0,d0*4),a0
	lea	modetxt,a1
.moloop	move.b	(a0)+,(a1)+
	bne.l	.moloop
	;
	bra.l	.sel
	;
.notvile	subq	#1,d0
	bne.l	.notabout
	;
.about	;about text...
	;
	bsr.l	finitpmenu
	lea	gloom,a0
	lea	gloompal,a1
	lea	abouttext,a2
	bsr.l	pmenu
	move	numopts(pc),-(a7)
	move	#1,numopts
	;
	bsr.l	selmenu
	;
	;cheat mode too?
	;
	qkey	$5f
	beq.l	.noch
	;
	warn	#$f0f
	move	#-1,cheat
	;
.noch	move	(a7)+,numopts
	bsr.l	finitpmenu
	bra.l	dointro
	;
.notabout	subq	#1,d0
	bne.l	.sel
	;
.exitgloom	moveq	#4,d0
	;
.newgame	move	d0,gametype
	bsr.l	qsync2
	bsr.l	chatoff
	bra.l	finitpmenu

linkup	;link up...
	;
	lea	linkupmenu,a0
	bsr.l	qmenu
	;
.loop	bsr.l	selmenu
	cmp	#3,d0
	bne.l	.notb
	bsr.l	optbaud
	bra.l	.loop
	;
.notb	bsr.l	finitqmenu
	move	curropt(pc),d0
	beq.l	nulllink
	cmp	#4,d0
	beq.l	.rts
	subq	#1,d0
	beq.l	dialup
	subq	#1,d0
	beq.l	answer
.rts	rts
	;
answer	lea	ata(pc),a0
	move	#-1,linked
	bra.l	doconnect

dialup	;
	lea	phonenum(pc),a0
	move.l	a0,a1
	move.l	a0,phoneat
.clr	tst.b	(a0)
	beq.l	.clrd
	move.b	#32,(a0)+
	bra.l	.clr
.clrd	move.b	#127,(a1)
	;
	lea	linkmenu0,a0
	bsr.l	qmenu
	;
	st	chatok
	;
.loop	qkey	$41,d0	;undel!
	bne.l	.loop
	;
.wkey	bsr.l	checkesc
	bne.l	.escout
	qkey	$44	;return?
	bne.l	.done
	key	$41,d0
	bne.l	.del	;del
	;
	move	chatoutget(pc),d0
	cmp	chatoutput(pc),d0
	beq.l	.wkey
	;
	and	#31,d0
	lea	chatout(pc),a0
	move.b	0(a0,d0),d0	;chat out character!
	addq	#1,chatoutget
	;
	cmp	#48,d0
	bcs.l	.loop
	cmp	#58,d0
	bcc.l	.loop
	;
	move.l	phoneat(pc),a0
	move.b	d0,(a0)+
	tst.b	(a0)
	beq.l	.skinc
	move.b	#127,(a0)
	move.l	a0,phoneat
	;
.skinc	bsr.l	vwait
	bsr.l	optoff
	bsr.l	opton
	bra.l	.loop
	;
.del	move.l	phoneat(pc),a0
	cmp.l	#phonenum,a0
	beq.l	.loop
	cmp.b	#127,(a0)
	bne.l	.noc
	move.b	#32,(a0)
	subq	#1,a0
.noc	move.b	#127,(a0)
	move.l	a0,phoneat
	bra.l	.skinc
	;
.done	qkey	$44
	bne.l	.done
	;
	bsr.l	.escout
	;
	lea	pbuff(pc),a0	;use this for connect string!
	move.l	a0,a2
	;
	move.l	#'ATDT',(a2)+
	lea	phonenum(pc),a1
.cpn	move.b	(a1)+,(a2)
	beq.l	.null
	cmp.b	#32,(a2)+
	bne.l	.cpn
	subq	#1,a2
.null	move.b	#13,(a2)+
	move.b	#10,(a2)+
	clr.b	(a2)
	;
	move	#1,linked
	bra.l	doconnect
	;
.escout	bsr.l	finitqmenu
	clr	chatok
	clr	chatoutget
	clr	chatoutput
	rts

checkesc	qkey	$45
	ifne	cd32
	movem.l	d0-d7/a0-a6,-(a7)
	lea	cd32buff(pc),a0
	clr	escape
	bsr.l	readcd321
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
	bsr.l	sendstring
	bsr.l	waitconnect
	beq.l	.calcmaster
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
	bne.l	.linked
	;
	move	linkdelay(pc),d0
	ext.l	d0
	move.l	d0,d2
	bsr.l	longput
	bsr.l	longget
	cmp.l	d0,d2
	beq.l	.itsatie
	bhi.l	.master
	bra.l	.slave
	;
.itsatie	;OK, both connected at same time! use faster machine...
	;
	moveq	#0,d7
	;
	move	#$20,$dff09a
	;
.vwloop	btst	#5,$dff01f
	beq.l	.vwloop
	move	#$20,$dff09c
.cmloop	;
	btst	#5,$dff01f
	bne.l	.cmdone
	bsr.l	rndw
	ext.l	d0
	divs	#$a5a5,d0
	addq.l	#1,d7
	bra.l	.cmloop
.cmdone	;
	move	#$20,$dff09c
	move	#$8020,$dff09a
	;
	move.l	d7,d0
	bsr.l	longput
	bsr.l	longget
	cmp.l	d0,d7
	beq.l	.calcmaster
	blt.l	.slave
	;
	;I'm player 1
.master	move	#1,linked
	bra.l	.linked
	;
.slave	;I'm actually player 2!
	move	#-1,linked
	;
.linked	move	#-1,p2_ob_cntrl
	;
	lea	incharge(pc),a0
	tst	linked
	bgt.l	.goz
	lea	notincharge(pc),a0
.goz	bsr.l	qmenu
	bsr.l	chaton
	bsr.l	selmenu
	bra.l	finitqmenu

longput	;send ser long in d0
	;
	moveq	#3,d1
.loop	rol.l	#8,d0
	movem.l	d0-d1,-(a7)
	bsr.l	vwait
	bsr.l	serput
	movem.l	(a7)+,d0-d1
	dbf	d1,.loop
	rts

longget	;get ser long in d0
	;
	move.l	d2,-(a7)
	moveq	#3,d1
.loop	movem.l	d1-d2,-(a7)
	bsr.l	serwait
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
.loop	bsr.l	vwait
	move.b	(a2)+,d0
	beq.l	.done
	bsr.l	serput
	bra.l	.loop
.done	rts

linkdelay	dc	0

waitconnect	;wait for 'CONNECT' to arrive...
	;return eq if OK, else ne if 'esc'ed or not received.
	;
	lea	linkmess,a0
	bsr.l	qmenu
	clr	linkdelay
	;
.retry	lea	wconnect(pc),a2
	;
.loop	bsr.l	vwait
	addq	#1,linkdelay
	bsr.l	checkesc
	bne.l	.notok
	bsr.l	rbfchk
	beq.l	.loop
	bsr.l	serget
	cmp.b	(a2)+,d0
	bne.l	.retry
	tst.b	(a2)
	bne.l	.loop
	;
.ok	;OK, connect xxxx ends with 13,10...
	;
.w10	bsr.l	vwait
	addq	#1,linkdelay
	bsr.l	checkesc
	bne.l	.notok
	bsr.l	rbfchk
	beq.l	.w10
	bsr.l	serget
	cmp.b	#10,d0
	bne.l	.w10
	;
	bsr.l	finitqmenu
	moveq	#0,d0
	rts
	;
.notok	bsr.l	finitqmenu
	moveq	#-1,d0
	rts

optbaud	addq	#1,baud
	cmp	#6,baud
	bcs.l	.ok
	clr	baud
.ok	;
calcbaud	move	baud(pc),d0
	lea	bauds(pc),a0
	move.l	4(a0,d0*8),a0	;baud text!
	lea	baudtext(pc),a1
.loop	move.b	(a0)+,(a1)+
	bne.l	.loop
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
popts	dc.l	popt1,popt2,popt3,popt4,popt5
	;
popt0	dc.b	'NULL MODEM',0	;-1
popt1	dc.b	'JOYSTICK 1',0	;0
popt2	dc.b	'JOYSTICK 2',0	;1
popt3	dc.b	' KEYBOARD ',0	;2
popt4	dc.b	'CD32 PAD 1',0	;3
popt5	dc.b	'CD32 PAD 2',0	;4

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

	even

makeiff	;show an IFF picture...128 colours...320 X 240
	;
	;a0=trimmed iff, a1=iff's palette
	;
	push
	movem.l	a0-a1,-(a7)
	lea	iffwindow,a0
	bsr.l	freewindow
	movem.l	(a7)+,a0-a1
	;
	lea	iffwindow,a2
	cmp.l	#0,a0
	bne.l	.notblank
	addq	#1,a0
	move.l	a0,wi_iff(a2)
	move.l	#rgbs16,a1
	bra.l	.blank
	;
.notblank	move.l	a0,wi_iff(a2)
.blank	move.l	a1,wi_pal(a2)
	;
	;copy font palette to IFF palette!
	;
	move.l	font(pc),d0
	beq.l	.nofont
	;
	move.l	d0,a0
	add.l	(a0),a0
	addq	#2,a0
	clr.l	(a1)+
	moveq	#14,d0
.loop	move	(a0),(a1)+
	move	(a0)+,(a1)+
	dbf	d0,.loop
.nofont	;
	move.l	a2,a0
	bsr.l	makewindow
	;
	pull
	rts

showiff	push
	lea	iffwindow,a0
	bsr.l	showwindow
	pull
	rts

gamemenu	dc.b	7
	dc.b	'CONTINUE',0
	dc.b	'RESOLUTION',0
	dc.b	'WINDOW SIZE',0
	dc.b	'FULL SCREEN WINDOW',0
	dc.b	'FLOOR',0
	dc.b	'CEILING',0
	dc.b	'QUIT GAME',0
	even

modes	dc.l	mode1,mode2

mode1	dc.b	'MEATY',0

mode2	dc.b	'MESSY',0

startmenu	dc.b	9
	dc.b	'ONE PLAYER GAME',0	;0
	dc.b	'TWO PLAYER GAME',0	;1
	dc.b	'TWO PLAYER COMBAT',0	;2
	dc.b	'PLAYER 1 '
p1ctype
	ifne	cd32
	dc.b	'CD32 PAD 1',0	;3
	elseif
	dc.b	'JOYSTICK 1',0		;3
	endc
	;
	dc.b	'PLAYER 2 '
p2ctype
	ifne	cd32
	dc.b	'CD32 PAD 2',0	;4
	elseif
	dc.b	'JOYSTICK 2',0		;4
	endc
	;
	dc.b	'REMOTE LINK OPTIONS',0	;5
	;
	dc.b	'VIOLENCE MODEL: '
modetxt	dc.b	'MEATY',0		;6
	dc.b	'ABOUT GLOOM',0		;7
	dc.b	'EXIT GLOOM',0		;8
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

qmenu	move.l	a0,-(a7)
	sub.l	a0,a0
	bsr.l	makeiff
	bsr.l	showiff
	move.l	(a7)+,a4
	lea	iffwindow,a6
	bsr.l	initmenu
	bra.l	dispon

pmenu	move.l	a2,-(a7)
	bsr.l	makeiff
	bsr.l	showiff
	move.l	(a7)+,a4
	lea	iffwindow,a6
	bsr.l	initmenu
	bra.l	dispon

finitpmenu	;
finitqmenu	bsr.l	dispoff
	bsr.l	finitmenu
	lea	iffwindow,a0
	bra.l	freewindow

initmenu	clr	curropt
initmenu2	;
	;do a menu...menu in a4, window in a6
	;
	move.l	a6,menuwindow
	move.b	(a4)+,d0	;how many
	ext	d0
	move	d0,numopts
	move	d0,-(a7)	;counter
	move	wi_bh(a6),d6
	move.l	wi_bmap(a6),menubmap
	lsr	#1,d6
	move	fonth(pc),d2
	lsr	#1,d2
	mulu	d2,d0
	sub	d0,d6	;Y
	move	d6,menuy
	lea	menustrips(pc),a5
	;
.loop	;save strip!
	;
	move.l	a4,(a5)+
	;
	move	#40*7,d0
	mulu	fonth(pc),d0
	moveq	#2,d1
	allocmem	menustrip
	move.l	d0,(a5)+
	move.l	d0,a1
	move.l	wi_bmap(a6),a0
	move	d6,d0
	mulu	#7*40,d0
	add.l	d0,a0
	;
	move	#40*7,d0
	mulu	fonth(pc),d0
	lsr.l	#2,d0
	subq	#1,d0
	;
.sloop	move.l	(a0)+,(a1)+
	dbf	d0,.sloop
	;
	move.l	a4,a0
	moveq	#-1,d0
.cnt	addq	#1,d0
	tst.b	(a0)+
	bne.l	.cnt
	;
	jsr	printmess2
	;
	add	fonth(pc),d6
	subq	#1,(a7)
	bgt.l	.loop
	addq	#2,a7
	;
	ifne	debugmem
	bsr.l	showmem
	lea	memasc,a4
	moveq	#8,d0
	jsr	printmess2
	;
	move.l	freememerr,d0
	beq.l	.nomemerr
	clr.l	freememerr
	move.l	d0,a4
	move.l	d0,a0
	moveq	#-1,d0
.ccloop	addq	#1,d0
	tst.b	(a0)+
	bne.l	.ccloop
	add	fonth(pc),d6
	jsr	printmess2
.nomemerr	;
	endc
	;
	rts

minmem	dc.l	$7fffffff

	ifne	debugmem
	;
showmem	push
	move.l	4.w,a6
	move.l	#$20001,d1
	jsr	-216(a6)
	cmp.l	minmem(pc),d0
	bge.l	.notmin
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
	bcs.l	.skip
	addq	#7,d2
.skip	move.b	d2,(a0)+
	dbf	d1,.loop
	pull
	rts
	;
memasc	dc.b	'12345678',0
	even
	endc

optoff	move	curropt(pc),d6
	lea	menustrips(pc),a0
	move.l	4(a0,d6*8),a0	;address of strip
	mulu	fonth(pc),d6
	add	menuy(pc),d6
	mulu	#7*40,d6
	move.l	menubmap(pc),a1
	add.l	d6,a1
	;
	move	fonth(pc),d0
	mulu	#7,d0
	lsl	#6,d0
	or	#20,d0
	;
	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.l	.bwait
	;
	move.l	#$9f00000,$dff040
	move.l	#-1,$dff044
	move	#0,$dff064
	move	#0,$dff066
	move.l	a0,$dff050
	move.l	a1,$dff054
	move	d0,$dff058
	;
	move	#13,flashdelay
	;
	rts

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
	bne.l	.loop
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
	lea	joyx(pc),a0
	bsr.l	readjoy1
	lea	joyx0(pc),a0
	bsr.l	readkeys
	move.l	joyx0(pc),d0
	or.l	d0,joyx
	move.l	joyb0(pc),d0
	or.l	d0,joyb
	;
	qkey	$44
	bne.l	.fire
	qkey	$45
	beq.l	.encode
.fire	move	#-1,joyb
.encode	lea	joyx(pc),a0
	jsr	encodejoy
	and	#$1c,d0	;fire/up/down only!
	rts

	;bit:
	;0 = joyx -1
	;1 = joyx 1
	;2 = joyy -1
	;3 = joyy 1
	;4 = joyb true
	;5 = joys true

unselmenu	move	d0,-(a7)
.loop	bsr.l	readmenujoy
	cmp	(a7),d0
	beq.l	.loop
	move	(a7)+,d0
	rts

readmenusel	;read menu selection!
	tst	linked
	bne.l	.link
	;
	;not linked...
	;
	bsr.l	readmenujoy
	bne.l	unselmenu
	rts
	;
.link	bmi.l	.slave
	;
	;master...
	;
	bsr.l	readmenujoy
	beq.l	.rts
	bsr.l	unselmenu
	bsr.l	serput
	bsr.l	serwait
	and	#255,d0
.rts	rts
	;
.slave	bsr.l	rbfchk
	beq.l	.rts
	bsr.l	serget
	bsr.l	serput
	and	#255,d0
	rts

selmenu	;select a menu item...return item in d0
	;
	;flash selected option on/off
	;
	bsr.l	optoff
.loop1	bsr.l	vwait
	bsr.l	readmenusel
	bne.l	.joygot
	subq	#1,flashdelay
	bgt.l	.loop1
	;
	bsr.l	opton
.loop2	bsr.l	vwait
	bsr.l	readmenusel
	bne.l	.joygot2
	subq	#1,flashdelay
	bgt.l	.loop2
	bra.l	selmenu
	;
.joygot	move	d0,-(a7)
	bsr.l	opton
	move	(a7)+,d0
.joygot2	;
	btst	#2,d0
	bne.l	.up
	btst	#3,d0
	bne.l	.down
	;
	;selected!
	;
	move	curropt(pc),d0
	rts
	;
.up	subq	#1,curropt
	bpl.l	selmenu
	move	numopts(pc),d0
	subq	#1,d0
	move	d0,curropt
	bra.l	selmenu
	;
.down	addq	#1,curropt
	move	curropt(pc),d0
	cmp	numopts(pc),d0
	bcs.l	selmenu
	clr	curropt
	bra.l	selmenu

finitmenu	;clean up menu operation
	;
	lea	menustrips(pc),a5
	move	numopts(pc),d2
	subq	#1,d2
.loop	addq	#4,a5
	move.l	(a5)+,a1
	freemem	menustrip
	dbf	d2,.loop
	rts

initbmappal	move.l	smallfont_,a0
	add.l	(a0),a0
	addq	#2,a0
	moveq	#22,d0	;23 colours to poke!
	move.l	coplist(pc),a1
	move.l	a1,a2
	move.l	a1,a3
	move.l	a1,a4
	;
	lea	cols1+6-copinit(a1),a1
	lea	cols2+6-copinit(a2),a2
	lea	cols3+6-copinit(a3),a3
	lea	cols4+6-copinit(a4),a4
	;
.loop	move	(a0),(a1)
	move	(a0),(a2)
	move	(a0),(a3)
	move	(a0)+,(a4)
	addq	#4,a1
	addq	#4,a2
	addq	#4,a3
	addq	#4,a4
	dbf	d0,.loop
	rts

initdarktable	;
	move	#maxz-1,d2
	move.l	sqr(pc),a0
	move.l	darktable(pc),a1
	;
.loop	move	d2,d3
	lsl	#3,d3
	move	0(a0,d3),d3
	lsr	#3,d3
	eor	#15,d3
	move	d3,(a1)+
	;
	dbf	d2,.loop
	;
	rts

initrawmap	lea	ascmap(pc),a0
	lea	rawmap(pc),a1
	bsr.l	.loop
	lea	ascmap2(pc),a0
	lea	shiftmap(pc),a1
	;
.loop	moveq	#0,d0
	move.b	(a0)+,d0
	cmp	#$ff,d0
	beq.l	.rts
.loop2	move.b	(a0)+,d1
	beq.l	.loop
	move.b	d1,0(a1,d0)
	addq	#1,d0
	bra.l	.loop2
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
	bne.l	.clrkey
	;
.setkey	bset	d1,0(a1,d0)	;key on!
	;
	move	chatok(pc),d0
	beq.l	.skip
	;
	lea	rawmap(pc),a0
	move.b	$60>>3(a1),d0
	and	#7,d0
	beq.l	.unshft
	lea	shiftmap(pc),a0
.unshft	move.b	0(a0,d2),d0	;asc!
	beq.l	.skip
	;
	;ok, add to chat out buffer!
	;
	lea	chatout(pc),a0
	move	chatoutput(pc),d1
	and	#31,d1
	move.b	d0,0(a0,d1)
	addq	#1,chatoutput
	;
	bra.l	.skip
	;
.clrkey	bclr	d1,0(a1,d0)
	;
.skip	moveq	#6,d0	;wait 6 scanlines?
	moveq	#-1,d1
.loop	move	d1,d2
.loop2	move.l	$dff004,d1
	lsr.l	#8,d1
	and	#$1ff,d1
	cmp	d2,d1
	beq.l	.loop2
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
	bne.l	.ok
	;
	lea	wpmess(pc),a0
	bsr.l	qmenu
	;
.help	bsr.l	vwait
	;
	movem.l	(a7),d0/a0-a1
	move.l	dosbase,a6
	move.l	a0,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq.l	.help
	;
	move.l	d7,-(a7)
	bsr.l	finitqmenu
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
	bra.l	loadfile_

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
	beq.l	.err
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
	bcs.l	.nocrunch
	;
	moveq	#0,d6
	move.l	fileheader(pc),d0
	cmp.l	#'CrM2',d0
	beq.l	.crunch
	cmp.l	#'CrM!',d0
	bne.l	.nocrunch
	;
.crunch	cmp.l	fileheader+6(pc),d4 ;loadlen>destlen?
	bcc.l	.skip
	move.l	fileheader+6(pc),d4 ;length to allocate
.skip	;
	moveq	#14,d6
	add	fileheader+4(pc),d6
	bsr.l	loadit
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
	bsr.l	loadit
	;
.err	pull
	rts

loadit	;d4=length to alloc/read, d5=memtype
	;seek to start, load, close and return base in d0.
	;
	move.l	loadmem(pc),d0
	bne.l	.noalloc
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

andtable	dc	$ffff,0	;rgb and, brightness add...wht
	dc	$ff00,8	;red

makepalettes	;
	;make wht and red pals
	;
	;create pointers...
	;
	lea	palettes(pc),a0
	move.l	map_rgbs(pc),d0
	lea	palettesw(pc),a1
	move.l	map_rgbsw(pc),d1
	lea	palettesr(pc),a2
	move.l	map_rgbsr(pc),d2
	;
	moveq	#15,d7
	;
.loop	move.l	(a0)+,d3
	sub.l	d0,d3	;offset!
	move.l	d3,d4
	add.l	d1,d3
	move.l	d3,(a1)+
	add.l	d2,d4
	move.l	d4,(a2)+
	;
	dbf	d7,.loop
	;
	move.l	map_rgbsend(pc),d7
	sub.l	map_rgbs(pc),d7		;how many bytes!
	lsr	#1,d7
	subq	#1,d7		;words!
	;
	move.l	map_rgbsw(pc),a1
	move	#$ffff,d1		;col and
	move	#0,d2		;gamma
	bsr.l	makeapal
	;
	move.l	map_rgbsr(pc),a1
	move	#$ff00,d1
	moveq	#16,d2
	bsr.l	makeapal
	;
	rts

makeapal	move.l	map_rgbs(pc),a0
	;
.loop	move	(a0)+,d4	;src colour...find briteness
	;
	move	d4,d5
	move	d4,d6
	and	#$f00,d4
	lsr	#8,d4
	and	#$0f0,d5
	lsr	#4,d5
	and	#$00f,d6
	add	d6,d5
	add	d5,d4
	add	d2,d4
	cmp	#16*3,d4
	bcs.l	.bok
	moveq	#16*3-1,d4
.bok	ext.l	d4
	divu	#3,d4	;(r+g+b)/3=briteness!
	;
	move	d4,d5
	move	d4,d6
	lsl	#8,d4
	lsl	#4,d5
	or	d6,d5
	or	d5,d4	;RGB
	and	d1,d4
	;
	move	d4,(a1)+
	;
	cmp.l	map_rgbsend(pc),a0
	bcs.l	.loop
	;
	rts

calcpalettes	;OK, our palette currently runs from:
	;
	;map_rgbs
	;   to
	;map_rgbsat
	;
	;append brightness versions...
	;
	lea	palettes(pc),a2
	move.l	map_rgbs(pc),(a2)+	;first brightness!
	move.l	map_rgbsat(pc),a1	;first brightness!
	move.l	a1,a3
	moveq	#1,d0	;rgb subtract
	;
.loop	move.l	map_rgbs(pc),a0
	move.l	a1,(a2)+
	;
.loop2	move	(a0)+,d1
	move	d1,d2
	move	d1,d3
	;
	and	#$f00,d1
	lsr	#8,d1
	sub	d0,d1
	bpl.l	.rok
	moveq	#0,d1
.rok	;
	and	#$f0,d2
	lsr	#4,d2
	sub	d0,d2
	bpl.l	.gok
	moveq	#0,d2
.gok	;
	and	#$0f,d3
	sub	d0,d3
	bpl.l	.bok
	moveq	#0,d3
.bok	;
	lsl	#8,d1
	lsl	#4,d2
	or	d3,d2
	or	d2,d1
	or	#$8000,d1
	;
	move	d1,(a1)+
	cmp.l	a3,a0
	bcs.l	.loop2
	;
	addq	#1,d0
	cmp	#16,d0
	bcs.l	.loop
	;
	move.l	a1,map_rgbsend
	;
	rts

map_rgbsend	dc.l	0

dispoff	tst	dispnest
	bne.l	.skip
	bsr.l	vwait
	move	#$01a0,$dff096	;bp/cop/spr off!
.skip	addq	#1,dispnest
	rts

dispon	subq	#1,dispnest
	bgt.l	.skip
	bsr.l	vwait
	move.l	coplist(pc),$dff080
	move	#0,$dff088
	move	#$8080,$dff096	;cop on!
	move	#0,$dff088
.skip	rts

forbid	push
	moveq	#49,d0
.fl	bsr.l	vwait
	dbf	d0,.fl
	bsr.l	ownblitter
	move.l	4.w,a6
	jsr	-132(a6)
	move	#$8400,$dff096	;bltnasty!
	pull
	rts

permit	push
	move.l	4.w,a6
	jsr	-138(a6)
	bsr.l	disownblitter
	pull
	rts

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

ownblitter	push
	move.l	grbase,a6
	jsr	-456(a6)
	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.l	.bwait
	pull
	rts

disownblitter	push
	btst	#6,$dff002
.bwait	btst	#6,$dff002
	bne.l	.bwait
	move.l	grbase,a6
	jsr	-462(a6)
	pull
	rts

makecoloffs	push
	;
	lea	coloffs,a0
	moveq	#2,d0
	moveq	#3,d2
.loop	addq.l	#4,d0
	moveq	#31,d1
.loop2	move.l	d0,(a0)+
	addq.l	#4,d0
	dbf	d1,.loop2
	dbf	d2,.loop
	;
	pull
	rts

grname	dc.b	'graphics.library',0
	even
grbase	dc.l	0
oldview	dc.l	0
dosname	dc.b	'dos.library',0
	even
dosbase	dc.l	0

calcbpos	;also: calc qstripbot, con0poke...
	;
	move	window1+wi_h,d0
	add	d0,d0
	ext.l	d0
	add.l	qstrip(pc),d0
	move.l	d0,qstripbot
	;
	move	#$100,con0poke
	move	floorflag(pc),d0
	and	roofflag(pc),d0
	bne.l	.cp
	move	#$9f0,con0poke	;one of them is cop strip!
.cp	;
	move	window1+wi_y,d0
	subq	#4,d0
	move	d0,minbpos
	tst	twowins
	beq.l	.p1
	;
	move	window2+wi_y,d0
	add	window2+wi_bh,d0
	addq	#4,d0
	move	d0,maxbpos
	rts
	;
.p1	move	window1+wi_y,d0
	add	window1+wi_bh,d0
	addq	#4,d0
	move	d0,maxbpos
	;
	rts

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
	move.l	grbase,a6
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

chatmap	dc.l	0

initdisplay	push
	;
	lea	grname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,grbase
	;
	move.l	d0,a6
	move.l	34(a6),oldview
	sub.l	a1,a1
	jsr	-222(a6)	;loadview
	;
	move.l	#80*2*5,d0
	moveq	#2,d1
	allocmem	chatplanes
	move.l	d0,chatmap
	;
	move	d0,chatplanes+6
	swap	d0
	move	d0,chatplanes+2
	swap	d0
	add.l	#80,d0
	move	d0,chatplanes+14
	swap	d0
	move	d0,chatplanes+10
	;
	move.l	#copinitf-copinit,d0
	moveq	#2,d1
	allocmem	copinit
	move.l	d0,coplist
	;
	move.l	d0,a1
	lea	copinit,a0
	lea	copinitf,a2
	;
.loop	cmp.l	a2,a0
	bcc.l	.done
	move.l	(a0)+,(a1)+
	bra.l	.loop
.done	;
	add.l	#sl1-copinit,d0
	move.l	d0,slice1
	add.l	#sl2-sl1,d0
	move.l	d0,slice2
	add.l	#cstop-sl2,d0
	move.l	d0,copstop
	;
	move.l	copstop,d0
	move.l	slice1,a0
	move.l	slice2,a1
	;
	move	d0,72+6(a0)
	move	d0,72+6(a1)
	swap	d0
	move	d0,72+2(a0)
	move	d0,72+2(a1)
	;
	bsr.l	dochatoff
	;
	jsr	-270(a6)
	move	#$81a0,$dff096
	;
	;jsr	-270(a6)
	;move.l	coplist,$dff080
	;move	#0,$dff088
	;
	pull
	rts

allocwbmap	move	wi_w(a2),d0
	mulu	wi_pw(a2),d0
	move	d0,wi_bw(a2)
	;
	move	wi_h(a2),d0
	mulu	wi_ph(a2),d0
	move	d0,wi_bh(a2)
	;
	mulu	#40*7,d0
	;
	move.l	#$10002,d1
	move.l	d0,wi_bmapmem(a2)
	allocmem	wi_bmap
	move.l	d0,wi_bmap(a2)
	;
	move.l	#40*7*7,d0
	moveq	#2,d1
	allocmem	wi_strip
	move.l	d0,wi_strip(a2)
	;
	rts

windowiff	;draw iff into window!
	;
	move.l	wi_iff(a2),a0
	cmp.l	#1,a0
	bne.l	.do
	rts
	;
.do	move.l	wi_bmap(a2),a1
	;
	move	2(a0),d1
	cmp	#240,d1
	bcs.l	.skip
	move	#240,d1
.skip	move	#120,d2
	lsr	#1,d1
	sub	d1,d2
	mulu	#7*40,d2
	add.l	d2,a1
	;
decodeiff	;for 40 columns...
	;
	;a0=trimmed IFF file,
	;a1=destination bitmap...
	;
	move.l	a2,-(a7)
	moveq	#40,d7
	;
	move	(a0)+,d0	;pixel width
	lsr	#3,d0	;to byte width
	move	(a0)+,d1	;pixel height
	cmp	#240,d1
	bls.l	.hok
	move	#240,d1
.hok	subq	#1,d1	;to dbf
	move	(a0)+,d2	;depth
	subq	#1,d2	;to dbf
	addq	#6,a0	;skip header
	;
.loop5	move	d2,d5	;depth
	;
.loop4	move.l	a1,a2
	move	d0,d4	;how many bytes in line
	;
.loop	moveq	#0,d3
	move.b	(a0)+,d3
	bmi.l	.repeat
	sub	d3,d4
.loop3	move.b	(a0)+,(a2)+
	dbf	d3,.loop3
	bra.l	.skip
	;
.repeat	cmp.b	#-128,d3
	beq.l	.loop
	neg.b	d3
	sub	d3,d4
.loop2	move.b	(a0),(a2)+
	dbf	d3,.loop2
	addq	#1,a0
.skip	subq	#1,d4
	bgt.l	.loop
	;
	add	d7,a1
	dbf	d5,.loop4
	dbf	d1,.loop5
	;
	move.l	(a7)+,a2
	rts

plotwbmap	;OK, plot colours on bitmap!
	;
	move.l	wi_iff(a2),d0
	bne.l	windowiff
	;
	move.l	wi_bmap(a2),a0
	move	wi_x(a2),d0
	move	d0,d1
	lsr	#3,d0
	not	d1
	and	#7,d1
	moveq	#127,d7	;colour
	move	wi_w(a2),d6	;width
	subq	#1,d6
	;
.wloop	move	wi_pw(a2),d5
	subq	#1,d5
	;
.wloop2	move	d7,d4
	moveq	#6,d3
	;
.dloop	bclr	d1,0(a0,d0)
	lsr	#1,d4
	bcc.l	.dskip
	bset	d1,0(a0,d0)
.dskip	lea	40(a0),a0
	dbf	d3,.dloop
	;
	lea	-40*7(a0),a0
	subq	#1,d1
	bpl.l	.dskip2
	moveq	#7,d1
	addq	#1,d0
.dskip2	dbf	d5,.wloop2
	;
	subq	#1,d7
	dbf	d6,.wloop
	;
	move	wi_bh(a2),d0	;how many to copy
	subq	#1,d0
	bsr.l	wcopy
	;
	move.l	wi_bmap(a2),a0
	move.l	wi_strip(a2),a1
	move	wi_bh(a2),d0
	lsr	#2,d0
	mulu	#7*40,d0
	add.l	d0,a0
	move	#7*7*10-1,d2
	;
.loop	move.l	(a0)+,(a1)+
	dbf	d2,.loop
	;
	rts

wcopy	;copy top scanline to next d0 scanlines
	;
	move.l	wi_bmap(a2),a0
	mulu	#10*7,d0
	subq	#1,d0
	lea	40*7(a0),a1
.cbloop	move.l	(a0)+,(a1)+
	dbf	d0,.cbloop
	;
	rts

freewindow	;window in a0
	;
	push
	move.l	a0,a2
	move.l	wi_bmap(a2),d0
	beq.l	.no1
	clr.l	wi_bmap(a2)
	move.l	d0,a1
	freemem	wi_bmap
.no1	move.l	wi_strip(a2),d0
	beq.l	.no2
	clr.l	wi_strip(a2)
	move.l	d0,a1
	freemem	wi_strip
.no2	move.l	wi_cop1(a2),d0
	beq.l	.no3
	clr.l	wi_cop1(a2)
	move.l	d0,a1
	freemem	wi_cop
.no3	pull
	rts

makewindow	;make window
	;
	;a0=window struct!
	;
	push
	;
	move.l	a0,a2
	;
	bsr.l	allocwbmap
	bsr.l	plotwbmap
	;
	tst.l	wi_iff(a2)
	beq.l	wchunky
	;
	;make a palette coplist for the window
	;
	;to write 32 colours...
	;set bank, write hi nybs, set bank, write lo nybs...
	;=66 copins.
	;*4=264 total
	;+1 for final wait +3 for final copjump=268
	;
	move.l	#268<<2,d0
	move.l	d0,wi_copmem(a2)
	moveq	#2,d1
	allocmem	wi_iffcop
	move.l	d0,wi_cop(a2)
	move.l	d0,wi_cop1(a2)
	move.l	d0,wi_cop2(a2)
	move.l	d0,a0	;dest
	move.l	wi_pal(a2),a1	;palette!
	;
	moveq	#0,d0	;bank
	moveq	#3,d3	;something.
	;
.loop	move	#$106,(a0)+
	move	d0,(a0)+
	move	#$180,d1
	moveq	#31,d2
.hiloop	move	d1,(a0)+
	move	(a1),(a0)+
	addq	#4,a1
	addq	#2,d1
	dbf	d2,.hiloop
	;
	lea	-128+2(a1),a1
	move	#$106,(a0)+
	bset	#9,d0
	move	d0,(a0)+
	bclr	#9,d0
	move	#$180,d1
	moveq	#31,d2
.loloop	move	d1,(a0)+
	move	(a1),(a0)+
	addq	#4,a1
	addq	#2,d1
	dbf	d2,.loloop
	subq	#2,a1
	;
	add	#$2000,d0	;next bank!
	dbf	d3,.loop
	;
	move.l	#$fffffffe,(a0)+
	move.l	#$00840000,(a0)+
	move.l	#$00860000,(a0)+
	move.l	#$008a0000,(a0)+
	pull
	rts
	;
wchunky	;how many copins on one line?
	;
	move	wi_w(a2),d0
	move	d0,d1
	subq	#1,d0
	lsr	#5,d0	;how many bank changes per line!
	addq	#3,d0	;1 waits - 1 eor, 1 init bank select
	add	d1,d0	;+colpokes
	;
	move	d0,d1
	lsl	#2,d1
	move	d1,wi_copmod(a2)
	;
	mulu	wi_h(a2),d0
	addq	#4,d0	;1 wait and cop jump at end
	;
	lsl.l	#2,d0	;4 bytes/copins
	moveq	#2,d1	;cop in chip
	move.l	d0,wi_copmem(a2)
	lsl.l	#1,d0	;2 coplists!
	allocmem	wi_chunkycop
	move.l	d0,wi_cop(a2)
	move.l	d0,wi_cop1(a2)
	;
	move.l	d0,a0
	move	wi_y(a2),d6
	move	wi_h(a2),d7
	subq	#1,d7
	move	#$111,d3	;test colour
	move	#$8000,d4	;Colour Eor
	;
.hloop	;make one copline...
	;
	moveq	#127,d0	;colour reg to poke
	move	wi_w(a2),d1
	subq	#1,d1
	;
.lloop	move	d0,d2
	addq	#1,d2
	and	#31,d2
	bne.l	.notnbank
	;
	;new bank....
	move	d0,d2
	sub	#31,d2
	and	#$ffe0,d2
	lsl	#8,d2
	or	d4,d2	;eor bank
	move	#$106,(a0)+	;bank select
	move	d2,(a0)+
	;
.notnbank	move	d0,d2
	and	#31,d2
	add	d2,d2
	add	#$180,d2
	move	d2,(a0)+	;colour poke
	move	d3,(a0)+
	add	#$111,d3
	subq	#1,d0
	dbf	d1,.lloop
	;
	bsr.l	.makewait
	;
	;ok, now do EOR!
	move	#$10c,(a0)+
	move	d4,(a0)+
	bchg	#15,d4
	;
	dbf	d7,.hloop
	;
	bsr.l	.makewait
	;
	move.l	#$00840000,(a0)+
	move.l	#$00860000,(a0)+
	move.l	#$008a0000,(a0)+
	;
	;OK, 1 list created...copy to other!
	;
	move.l	wi_cop1(a2),a0
	move.l	a0,a1
	add.l	wi_copmem(a2),a1
	move.l	a1,wi_cop2(a2)
	move.l	a1,a3
	;
.copycop	move.l	(a0)+,(a3)+
	cmp.l	a1,a0
	bcs.l	.copycop
	;
	pull
	rts

.makewait	;
	;make wait ins. at pos d6
	;
	subq	#1,d6
	move.b	d6,(a0)+
	move.b	#$e1,(a0)+
	move	#$fffe,(a0)+
	addq	#1,d6
	add	wi_ph(a2),d6
	rts

allocmem2_	;
	;as below, but d2.l = extra mem at start to set aside
	;
	push
	moveq	#16,d3
	add.l	d2,d3
	bra.l	amem_

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
	bne.l	.skip
	;
	warn	#$f00
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
	beq.l	.done
	move.l	d0,a2
	;
	ifne	debugmem
	move.l	12(a2),a0	;text field
	move.l	a0,d2
	moveq	#-1,d3
.loop	addq.l	#1,d3
	tst.b	(a0)+
	bne.l	.loop
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
	bra.l	.more
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
	beq.l	.err
	move.l	d0,a1
	;
	move.l	a1,a3
	add.l	8(a3),a3
	cmp.l	a3,a2
	bne.l	.more
	;
	move.l	(a1),(a0)
	move.l	4(a1),d0
	move.l	4.w,a6
	jsr	-210(a6)
	bra.l	.done
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
	beq.l	.skip
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
	bne.l	.ltl2
	moveq	#0,d0
	cmp.l	#.temp+1,a0
	beq.l	.notext
	lea	.temp2(pc),a0
	moveq	#1,d1
	jsr	loadfile
	;
.notext	move.l	d0,(a6)+	;texture!
	beq.l	.skip
	;
	;do colour mapping stuff!
	;
	move.l	d0,-(a7)
	;
	move.l	d0,a0
	add.l	(a0),a0
	move.l	a0,a2
	bsr.l	addpal
	;
	move.l	(a7),a0
	addq	#4,a0
	move.l	a2,a1
	bsr.l	remap
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
	bsr.l	addpal
	;
	lea	an_size(a6),a5
	;
.loop	move.l	a6,a0
	add.l	(a5)+,a0	;start of shape
	addq	#4,a0	;skip handles
	movem	(a0)+,d0-d1	;w/h
	mulu	d1,d0
	lea	0(a0,d0.l),a1	;end
	bsr.l	remap
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
	bcc.l	.done
	move.b	(a0),d0
	move.b	0(a2,d0),(a0)+
	bra.l	.loop
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
	bmi.l	.next	;not used!
	move.l	map_rgbs,a1
	;
.loop2	cmp.l	a2,a1
	bcc.l	.no
	cmp	(a1)+,d1
	beq.l	.yes
	bra.l	.loop2
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
	bcs.l	.ok
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
	dc	3	;for player 0,1=joyport, 2=keys
	elseif
	dc	0
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
	dc	4	;for player 0,1=joyport, 2=keys, 3=serial
	elseif
	dc	1
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

abouttext	dc.b	14
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

gloombrush	incbin	gloombrush

gloom	incbin	title
gloompal	incbin	title.pal

medplayer	incbin	medplay
decrm	incbin	decrm

castrotsinc	incbin	castrots64.bin
camrotsinc	incbin	camrots.bin	;256
camrots2inc	incbin	camrots2.bin	;1024
chatfont	incbin	chatfont.bin

rgbs16	ds.l	16
map_rgbs_	ds.w	256*16


; vasm-wrapper: compatibility stubs for missing floor/ceiling mapper labels
; The public source references these labels but does not provide their implementation.
; Keep them as safe no-op routines for a first linkable build.
	cnop	0,2
groundtile	rts
ceilingtile	rts
