;-------------- serial stuff -------------------;

sblen	equ	128	;serial buffer length

g2exit_serial_vector	dc.l	0
g2exit_serial_intena	dc.w	0
g2exit_serial_owned	dc.w	0

initser	push
	tst	g2exit_serial_owned
	bne.w	.done
	move.l	4.w,a6
	jsr	-120(a6)
	move	$dff01c,d0
	and	#$0801,d0
	move	d0,g2exit_serial_intena
	move	#$0801,$dff09a
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
	move.l	d0,g2exit_serial_vector
	move	#-1,g2exit_serial_owned
	;
	move	#$0801,$dff09c
	move	#$0001,$dff09a	;no tbe int.
	move	#$8800,$dff09a	;rbf int only
	jsr	-126(a6)
.done	pull
	rts

finitser	push
	tst	g2exit_serial_owned
	beq.s	.done
	move.l	4.w,a6
	jsr	-120(a6)
	move	#$0801,$dff09a
	move	#$0801,$dff09c
	moveq	#11,d0
	move.l	g2exit_serial_vector,a1
	jsr	-162(a6)
	clr	g2exit_serial_owned
	move	g2exit_serial_intena,d0
	or	#$8000,d0
	move	d0,$dff09a
	jsr	-126(a6)
.done	pull
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
	move	#-1,g2exit_med_initialized
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
	dc.l	g2ecs_fast_title_base
	dc.b	'pics_ehb/title_base',0
	even
	dc.l	g2ecs_fast_title_base_pal
	dc.b	'pics_ehb/title_base.pal',0
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
	; c87b5: gloomgame is deliberately not part of the load list.
	dc.l	0
	; Keep the old filename label as inert data only; no code opens it.
gamename	dc.b	'gloomgame',0
	even

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

; ECS4: the retail/AGA BlackMagic image is not guaranteed to use the same
; indices as the EHB palette.  ECS therefore loads a matching six-plane image.
ecsmagicimagefiles	dc.l	magic
	dc.b	'pics_ehb/blackmagic',0
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

g2ecs4_black_palette	ds.w	32
	even

initmain	;
	; c87b80d: former ECS DH3 stage checkpoints were permanent no-ops and
	; are no longer called or assembled in the release-candidate source.
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
.os1	jsr	g2p96_select_source_backend_c87b79n
	;
	move	d0,bitplanes
	move	d1,colours
	move.l	d2,linemod
	move.l	d3,bpmod
	move.l	a0,todb
	move.l	a1,topokepal
	;
	move.l	4.w,a6
	move.l	276(a6),a0
	move.l	184(a0),g2exit_old_windowptr
	st	g2exit_windowptr_set
	move.l	#-1,184(a0)	;requesters OFF for our task.
	;
	; c87w1: always start in the confirmed 320-column geometry. WIDE is armed
	; only after the guarded linear P96 owner is live.
	move	#320,g2render_width
	move	#160,g2render_center_x
	move	#319,g2render_last_x
	move	#320,g2render_stride
	bsr	initrawmap	;init keyboard reader
	lea	ciaaname,a1
	jsr	-498(a6)
	move.l	d0,ciaa
	;
	tst	os
	beq.s	.osskipz
	move.l	#12*257,d0
	moveq	#4,d1
	allocmem	temppal
	move.l	d0,temppal
.osskipz	;
	; Fix3b: keep audio silence at +0 separate from writable sprite data.
	; Bytes 0..127: audio zero buffer; bytes 128..255: blank pointer.
	move.l	#256,d0	;MEMF_CLEAR below initializes both chip RAM regions
	move.l	#$10002,d1
	allocmem	chipzero
	move.l	d0,chipzero
	;
	move.l	#256,d0
	moveq	#4,d1
	allocmem	maptable
	move.l	d0,maptable
	;
	move.l	#32768,d0
	moveq	#4,d1
	allocmem	memory
	move.l	d0,memory
	;
	move.l	#g2render_max_width*vd_size,d0
	moveq	#4,d1
	allocmem	vertdraws
	move.l	d0,vertdraws
	;
	move.l	#maxz*2,d0
	moveq	#4,d1
	allocmem	darktable
	move.l	d0,darktable
	;
	move.l	#g2render_max_width*g2render_height_const+15,d0
	moveq	#4,d1
	allocmem	chunky
	tst.l	d0
	beq.s	.g2p11_chunky_alloc_done
	add.l	#15,d0
	and.l	#$fffffff0,d0	; Patch 11: 16-byte aligned chunky base
.g2p11_chunky_alloc_done
	move.l	d0,chunky	;chunky buffer
	;
	; c86zgv: staged P96 static-screen RGB565 buffer.  Static pictures/menus
	; are converted completely in FastRAM first and only then copied to RTG, so
	; the user does not watch slow planar->RGB conversion line-by-line.
	clr.l	p96static_rgbbufptr
	clr.l	p96static_rgbbufsize
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq	.g2c86zgv_no_staticbuf
	moveq	#0,d0
	move	p96target_width,d0
	moveq	#0,d1
	move	p96target_height,d1
	mulu	d1,d0
	add.l	d0,d0
	move.l	d0,p96static_rgbbufsize
	moveq	#4,d1
	allocmem	p96staticrgb
	move.l	d0,p96static_rgbbufptr
.g2c86zgv_no_staticbuf
	;
	; c87b78j: a CLUT target keeps all conversion in Fast RAM. The packed
	; 8-bit page is target-sized; the 65536-byte reverse table maps every
	; compositor RGB565 word to the exact pen installed by LoadRGB32.
	clr.l	p96clut_stage_ptr
	clr.l	p96clut_stage_size
	clr.l	p96clut_reverse_ptr
	clr	p96clut_runtime_ready
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne	.g2c87b78j_no_clut_buffers
	moveq	#0,d0
	move	p96target_width,d0
	moveq	#0,d1
	move	p96target_height,d1
	mulu	d1,d0
	move.l	d0,p96clut_stage_size
	moveq	#4,d1
	allocmem	p96clutstage
	move.l	d0,p96clut_stage_ptr
	beq	.g2c87b78j_no_clut_buffers
	move.l	#65536,d0
	moveq	#4,d1
	allocmem	p96clutreverse
	move.l	d0,p96clut_reverse_ptr
	beq	.g2c87b78j_no_clut_buffers
	jsr	g2p96_clut_clear_runtime_c87b78j
	move	#-1,p96clut_runtime_ready
.g2c87b78j_no_clut_buffers
	;
	;
	move.l	#256*16,d0
	moveq	#4,d1
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
	moveq	#2,d0
	;
	jsr	g2detectprofile	;v190cj: select Gloom/Gloom3/ZM data layout
	moveq	#3,d0
	move.l	g2magicfiles_ptr,a0
	tst	aga
	bne.s	.g2ecs4_magic_image_list_ready
	move.l	g2ecsmagicimagefiles_ptr,a0
.g2ecs4_magic_image_list_ready
	bsr	loadfiles

	; ECS5b fallback: if pics_ehb/blackmagic was absent, try pics/blackmagic.
	; Accept it only when the trimmed-IFF header proves 320x240x6.
	tst	aga
	bne.s	.g2ecs5b_magic_image_done
	tst.l	magic
	bne.s	.g2ecs5b_magic_validate
	move.l	g2magicfiles_ptr,a0
	bsr	loadfiles
.g2ecs5b_magic_validate
	move.l	magic,d0
	beq.s	.g2ecs5b_magic_image_done
	move.l	d0,a0
	cmp	#320,(a0)
	bne.s	.g2ecs5b_magic_reject
	cmp	#240,2(a0)
	blo.s	.g2ecs5b_magic_reject
	cmp	#6,4(a0)
	beq.s	.g2ecs5b_magic_image_done
.g2ecs5b_magic_reject
	clr.l	magic
.g2ecs5b_magic_image_done
	move.l	g2agamagicfiles_ptr,a0
	tst	aga
	bne.s	.agaa
	move.l	g2ecsmagicfiles_ptr,a0
.agaa	bsr	loadfiles
	moveq	#4,d0
	;
	; c86zhg: show BlackMagic through the targeted P96 static bridge for
	; Gloom Deluxe/Gloom3/Zombie Massacre, but do not enable this early P96
	; bridge for Classic Gloom yet.  On real hardware Classic could hang after
	; the BlackMagic picture when the intermission bridge was entered here.
	; c86zjr: Classic Gloom now uses the same confirmed P96 title bridge for
	; the BlackMagic startup picture as all other profiles.  Keep this block
	; unconditional so no AGA-visible startup picture remains for profile 1.
	jsr	g2p96_display_enter_title
.g2c86zhg_blackmagic_oldpath
	move.l	magic,a0
	move.l	magicpal,a1
	; ECS2: never display the shared BlackMagic bitmap with an absent ECS
	; palette.  The old loader deliberately returns zero for missing optional
	; files; showing the image anyway produced the observed white background
	; and false colours.  AGA/P96 keep their proven behaviour unchanged.
	tst	aga
	bne.s	.g2ecs2_magic_ready
	tst.l	a0
	beq.s	.g2ecs4_magic_black
	tst.l	a1
	bne.s	.g2ecs2_magic_ready
.g2ecs4_magic_black
	sub.l	a0,a0		;blank image
	lea	g2ecs4_black_palette(pc),a1	;and explicitly program 32 black colours
.g2ecs2_magic_ready
	jsr	showpic
	moveq	#5,d0
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
	jsr	g2zm_ecs_load_core_fallbacks	;c87b23: accept alternate ZM ECS core-data locations
	jsr	g2ecs_fast_detect_assets	;c87b14: validate precomposed title/title_base contract
	jsr	g2ecs2_asset_check	;ECS2: validate required ECS resources
	jsr	g2embed_apply_g1_fallbacks	;v190gl: missing Classic-Gloom modern assets
	jsr	g2loadgunfallback	;v61: optional misc/stuf gun.bin fallback
	jsr	g2embed_apply_g1_fallbacks	;v190gl: gun fallback if no file exists
	jsr	g2embed_apply_zm_title_overlay	;v190hu: embedded Zombie Massacre title overlay
	moveq	#6,d0
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
		; c87b37: keep the proven BlackMagic-compatible converter as fallback,
		; but route compatible linear 320-pixel passes through Kalm.  The renderer
		; itself is switched to a 0..319 coloffs table before those frames, so Kalm
		; receives true row-major chunky pixels rather than BlackMagic's historical
		; 0,2,4...14,1,3...15 permutation.
		move.l	a0,g2kalms_legacy_c2p
		move.l	#g2kalms_c2p_dispatch,c2p
		jsr	g2kalms_startup_init
		moveq	#7,d0
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
	moveq	#8,d0
	bsr	initmed
	bsr	initser
	bsr	calcbaud
	bsr	initdarktable
	moveq	#9,d0
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
	moveq	#10,d0
	;
	; v41q diagnostic: remapanim/remap block returned.
	; Continue into initial object/anim loads, then hold after them.
	;
	moveq	#0,d0
	jsr	loadanobj	;load player1 - c87b16a long-call
	moveq	#1,d0
	jsr	loadanobj	;load player2 - c87b16a long-call
	moveq	#2,d0
	jsr	loadanobj	;load tokens (health) - c87b16a long-call
	moveq	#11,d0
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
	moveq	#12,d0
	;
.w5sex	tst	vbcounter
	bgt	.w5sex
	moveq	#13,d0
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
	jsr	seedrnd2		;c87b18b: long-call buildfix
	moveq	#14,d0
	;
	ifne	cd32
	lea	nvname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,nv
	; c87b5: saved continuation data is intentionally ignored.
	endc
	;
	; c87b80d: preserve the confirmed return register state formerly left by
	; the disabled stage-15 marker after forbid returned.
	jsr	forbid
	moveq	#15,d0
	rts

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
	; c87b5: probe the real script data only; gloomgame is ignored.
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
	jsr	vwait
	bsr	serput
	;
.mwait	addq	#1,d7
	jsr	vwait
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
	jsr	g2automap_reset	; new game starts with local map off
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
	bsr	forbid
	elseif
	bsr	askdatadisk
	endc
.gotdata	;
	; c87b5: only the script is required; gloomgame is never consumed.
	tst.l	script
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
	; c87b5: gloomgame/CONTINUE FROM is intentionally disabled.
	; Linked slaves may still receive the master's script offset, but the local
	; master always starts through the normal script/START LEVEL machinery.
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
	move.l	script(pc),scriptat
	; fall through into the normal game initialisation

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
scriptdone	; v190hy cleanup: log marker removed
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

scriptrest	;restart point marker
	; c87b5: consume the rest_ line and continue, but never add an offset,
	; allocate a continuation entry or write a gloomgame file.
.leol	cmp.b	#10,(a0)+
	bne.s	.leol
	move.l	a0,scriptat
	bra	execscript

scriptloop	; v190hy cleanup: log marker removed
	move.l	script,scriptat
	bra	execscript

scripthide	; v190hy cleanup: log marker removed
	jsr	g2p96_display_enter_intermission	;c86zfq: native P96 script/intermission owns display
	bsr	dispoff
	bra	execscript

scriptshow	; v190hy cleanup: log marker removed
	jsr	g2p96_display_enter_intermission	;c86zfq: reveal AGA/intermission before dispon
	tst.l	g2v190i_start_offset	; v190t: while skipping earlier levels, suppress old intermission screens
	bgt	execscript
	clr	pdelay
	bsr	dispon
	bra	execscript

scriptdraw	; v190hy cleanup: log marker removed
	jsr	g2p96_display_enter_intermission	;c86zfq: native P96 intermission before drawing
	tst.l	g2v190i_start_offset	; v190t: skip draw_ before earlier play_ entries
	bgt	execscript
	tst	g2v190t_reload_pic_after_level	; v190t: reload intermission IFF after gameplay, if needed
	beq.s	.g2v190t_no_reload_pic
	clr	g2v190t_reload_pic_after_level
	bsr	g2v190t_reload_current_pic
.g2v190t_no_reload_pic
	; c87b31: pict_ owns the palette lifetime.  ECS Gloom3/ZM load the exact
	; 128-byte .pal directly into fixed storage even while START LEVEL skips
	; earlier episodes.  A visible draw_ must therefore use that matching cache
	; and never a NULL/stale picpal allocation.  Retry once only if a prior load
	; failed; the retry also writes directly to fixed storage without AllocMem.
	move.l	picpal,a1
	tst	aga
	bne.s	.g2c87b31_palette_selected
	cmp	#2,g2_game_profile
	beq.s	.g2c87b31_try_cache
	cmp	#3,g2_game_profile
	bne.s	.g2c87b31_palette_selected
.g2c87b31_try_cache
	tst	g2ecs_inter_palette_cache_valid
	bne.s	.g2c87b31_use_cache
	jsr	permit
	jsr	g2ecs_load_g3zm_intermission_palette_abs
	jsr	forbid
	tst	g2ecs_inter_palette_cache_valid
	bne.s	.g2c87b31_use_cache
	; Safe visible fallback only.  This avoids dereferencing a NULL picpal if
	; the generated .pal is genuinely missing; the normal asset notice remains.
	move.l	gloompal,a1
	bra.s	.g2c87b31_palette_selected
.g2c87b31_use_cache
	lea	g2ecs_inter_palette_cache,a1
.g2c87b31_palette_selected
	; c87b23: generated ECS/EHB pictures must keep their own matching 128-byte
	; palette.  The immutable embedded G3/ZM palettes are 256-colour AGA data
	; and caused false colours when their first entries were applied to EHB.
	; AGA/P96 retain the established exact-palette selection unchanged.
	tst	aga
	beq.s	.g2c87b23_loaded_ehb_palette
	jsr	g2inter_select_exact_palette
.g2c87b23_loaded_ehb_palette
	move.l	pic,d0
	bne.s	.use
	move.l	gloompal,a1
	move.l	gloom,d0
.use	move.l	d0,a0
	; Keep the established AGA/P96 exact-palette preparation.
	jsr	g2ecs4_prepare_loaded_ehb_text_palette
	jsr	showpic
	; ECS7: the bitmap now exists. Evacuate indices 1..3/33..35 from the
	; picture and install the exact original Bigfont palette.
	tst	aga
	bne.s	.g2ecs7_intermission_non_ecs
	move.l	lastpal(pc),a1
	jsr	g2ecs7_prepare_exact_font_overlay
	bra.s	.g2ecs7_intermission_palette_ready
.g2ecs7_intermission_non_ecs
	; c87b9: AGA/P96 private palette handling remains unchanged.
	jsr	g2inter_install_work_palette
.g2ecs7_intermission_palette_ready
	; c86zhg: force the intermission picture visible before scripttext starts,
	; so the user sees the picture immediately and then the text types on top.
	clr	p96static_palette_mode
	jsr	g2p96_static_present_showbitmap_if_intermission
	; Never overwrite ECS picture entries 0..3 with the font palette.  Text
	; pixels are recoloured in isolation after each glyph blit.
	tst	aga
	beq.s	.g2v190hy2_draw_no_fontpal
	cmp	#2,g2_game_profile	;c87b4: Zombie Massacre keeps the original picture palette
	beq.s	.g2v190hy2_draw_no_fontpal
	cmp	#3,g2_game_profile	;v190hy2: Gloom3 keeps the original picture palette
	beq.s	.g2v190hy2_draw_no_fontpal
	bsr	initfontpal
.g2v190hy2_draw_no_fontpal
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

; c87b31: exact ECS Gloom3/Zombie Massacre intermission palette storage.
; The generated .pal files are exactly 128 bytes (32 ECS base colours).
; loadfileabs reads them directly into this fixed buffer and therefore cannot
; fail merely because a second small AllocMem block is unavailable after the
; large picture allocation or after several episode/START LEVEL transitions.
g2ecs_inter_palette_cache_valid	dc	0
g2ecs_inter_palette_cache	ds.b	128
g2ecs_inter_palette_name	ds.b	72
	even

; Load <g2v190t_lastpicname>.pal directly into the fixed cache.
; Call only while DOS access is permitted.  Other profiles/modes are untouched.
g2ecs_load_g3zm_intermission_palette_abs
	; c87b32: keep this mature call site and its exact assembled footprint, but
	; redirect palette acquisition to immutable embedded data. JMP+2*NOP = 10
	; bytes, matching the replaced MOVEM.L (4) + absolute CLR.W (6).
	jmp	g2ecs_load_g3zm_intermission_palette_embedded
	nop
	nop
	tst	aga
	bne.s	.done
	cmp	#2,g2_game_profile
	beq.s	.profile_ok
	cmp	#3,g2_game_profile
	bne.s	.done
.profile_ok
	tst.b	g2v190t_lastpicname
	beq.s	.done
	lea	g2v190t_lastpicname,a0
	lea	g2ecs_inter_palette_name,a1
.copy_name
	move.b	(a0)+,(a1)+
	bne.s	.copy_name
	subq.l	#1,a1
	lea	pic_pal,a0
.add_suffix
	move.b	(a0)+,(a1)+
	bne.s	.add_suffix
	lea	g2ecs_inter_palette_name,a0
	lea	g2ecs_inter_palette_cache,a1
	moveq	#1,d1
	jsr	loadfileabs
	tst.l	d0
	beq.s	.done
	move	#-1,g2ecs_inter_palette_cache_valid
.done
	movem.l	(a7)+,d0-d2/a0-a2
	rts

freeiff	push
	; c87b7: never carry an embedded intermission palette into a later title,
	; menu or unrelated picture path.  scriptdraw selects it again by name.
	clr.l	g2inter_exact_palette_ptr
	clr	g2ecs_inter_palette_cache_valid
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
	;
	lea	floortag(pc),a1
	bsr	fetchrest
	lea	floortag,a0
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
	jsr	g2p96_display_enter_intermission	;c86zfq: picture scripts use the native P96 intermission owner
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

	; c87b31: remember every pict_ basename before any picture allocation,
	; including pict_ commands consumed while START LEVEL skips episodes.
	movem.l	a0-a2,-(a7)
	lea	picname,a0
	lea	g2v190t_lastpicname,a2
.g2c87b31_piccopy
	move.b	(a0)+,(a2)+
	bne.s	.g2c87b31_piccopy
	movem.l	(a7)+,a0-a2

	; Keep the end of the base filename for the established AGA/P96 .pal load.
	move.l	a1,-(a7)
	bsr	permit

	; ECS Gloom3/ZM: load the exact palette first and directly into fixed
	; storage.  This is independent of START_OFFSET and needs no AllocMem.
	jsr	g2ecs_load_g3zm_intermission_palette_abs

	lea	picname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,pic
	beq.s	.nopic

	; AGA/P96 and the other ECS profiles retain the original allocated palette
	; path.  ECS Gloom3/ZM already own the fixed 128-byte cache above.
	tst	aga
	bne.s	.load_allocated_pal
	cmp	#2,g2_game_profile
	beq.s	.nopic
	cmp	#3,g2_game_profile
	beq.s	.nopic
.load_allocated_pal
	lea	pic_pal,a0
	move.l	(a7),a1
.g2c87b31_addpal
	move.b	(a0)+,(a1)+
	bne.s	.g2c87b31_addpal
	lea	picname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,picpal
.nopic
	addq	#4,a7
	bsr	forbid
	bra	execscript


g2v190t_reload_current_pic
	; Reload the last intermission picture after returning from gameplay.
	; c87b31 refreshes the fixed ECS palette before the large picture load,
	; avoiding a second allocation and preserving exact episode/image pairing.
	tst.b	g2v190t_lastpicname
	beq.s	.rts
	bsr	freeiff
	bsr	permit
	jsr	g2ecs_load_g3zm_intermission_palette_abs
	lea	g2v190t_lastpicname,a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,pic
	beq.s	.close
	tst	aga
	bne.s	.load_allocated_pal
	cmp	#2,g2_game_profile
	beq.s	.close
	cmp	#3,g2_game_profile
	beq.s	.close
.load_allocated_pal
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
	jsr	g2p96_display_enter_intermission	;c86zfq: palette darken in the native P96 intermission owner
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
	;a6=window, a4=message, d0=length of message, d6=Y
	;
	jsr	g2p96_display_enter_intermission	;c86zfq: text overlays in the native P96 intermission owner
	tst.l	g2v190i_start_offset	; v190t: consume but do not show text_ for skipped earlier levels
	ble.s	.g2v190t_show_text
	lea	text,a1
	bsr	fetchrest
	bra	execscript
.g2v190t_show_text
	; c87b9: build/cache the exact glyph mask and enable isolated yellow glyph
	; rendering only for Gloom3/ZM intermission text.
	jsr	g2inter_prepare_yellow_text
	move	#2,pdelay
	; c86zhi: P96 intermission should not type glyph-by-glyph because
	; repeated RTG conversion is far too slow.  Use pdelay=0 so
	; printmess2 draws the complete text immediately, but keep pdelay
	; non-negative so scriptwait still waits for ENTER/fire.
	; DISPLAY=AGA keeps the original typewriter timing and menu blink.
	cmp	#2,g2display_mode	; ECS1: native typewriter shortcut is P96-only
	bne	.g2c86zhi_keep_typewriter
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne	.g2c86zhi_keep_typewriter
	tst	p96gameplay_persist_active
	beq	.g2c86zhi_keep_typewriter
	jsr	g2p96_intermission_native_typewriter_prepare_standard_c87b78r
.g2c86zhi_keep_typewriter
	; ECS4: every ECS intermission keeps its picture palette.  The isolated
	; glyph recolour path supplies the yellow text without changing image pixels.
	tst	aga
	beq.s	.g2v190cx_text_no_fontpal
	cmp	#1,g2_game_profile	;v190cx: old Gloom intermission keeps picture palette
	beq.s	.g2v190cx_text_no_fontpal
	cmp	#2,g2_game_profile	;c87b4: Zombie Massacre keeps picture palette too
	beq.s	.g2v190cx_text_no_fontpal
	cmp	#3,g2_game_profile	;v190hy2: Gloom3 intermission keeps picture palette too
	beq.s	.g2v190cx_text_no_fontpal
	bsr	initfontpal
.g2v190cx_text_no_fontpal
	;
	lea	text,a1
	bsr	fetchrest
	lea	text,a0
	bsr	g2v14_wrap_script_text
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
	jsr	printmess2
	movem.l	(a7)+,d0/d6/a4
	;
.done	; v190hy cleanup: log marker removed
	jsr	printmess2
	jsr	g2p96_intermission_native_typewriter_finish_standard_c87b78r	;c87b78r: clear scale latch, then confirmed finish
	clr	g2inter_yellow_text_active	;c87b9: never leak intermission glyph mode
	clr	g2ecs7_direct_font_active	;ECS7: never leak direct exact-font mode
	;
	tst	pdelay
	bmi	execscript
	clr	pdelay
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
	tst.l	g2v190i_start_offset	; v190t: skip wait_ before skipped earlier levels
	bgt	execscript
	tst	pdelay
	bmi	execscript
	bsr	waitany
	bra	execscript

checkany	movem.l	d0-d7/a0-a6,-(a7)
	jsr	vwait
	jsr	readmenusel	; joystick/fire and existing RETURN path
	and	#$10,d0
	bne.s	.g2c87b15_any_pressed
	; c87b15: all skippable script/static screens accept the same keys.
	; Rawkey codes: $44 RETURN, $43 keypad ENTER, $40 SPACE, $45 ESC.
	qkey	$44
	bne.s	.g2c87b15_any_set
	qkey	$43
	bne.s	.g2c87b15_any_set
	qkey	$40
	bne.s	.g2c87b15_any_set
	qkey	$45
	bne.s	.g2c87b15_any_set
	btst	#6,$bfe001	; left mouse button, active low
	beq.s	.g2c87b15_any_set
	moveq	#0,d0
	bra.s	.g2c87b15_any_pressed
.g2c87b15_any_set
	moveq	#$10,d0
.g2c87b15_any_pressed
	tst	d0		; preserve EQ/NE across MOVEM restore for waitany/pdelay
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
.pick	jsr	rndn
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
	lea	mapname,a0
	; v11 native safety check. c87b79p: P96 never executes doc2p and must
	; not depend on an external/native C2P routine being present.
	cmp	#2,g2display_mode
	beq.s	.g2c87b79p_c2p_ready
	move.l	c2p(pc),d0
	lea	g2v08_dummy_c2p(pc),a0
	move.l	a0,d1
	cmp.l	d1,d0
	beq	g2v11_c2pfail_scriptplay
.g2c87b79p_c2p_ready
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
	bsr	initmap
	bsr	loadtxts
	move	#$a3f7,d0
	jsr	seedrnd
	moveq	#1,d0
	jsr	execevent
	jsr	g2v190cx_build_g1_tables	; c87b70g: live Classic palette/remap after map assets
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
	jsr	g2hotkeys_seed	; do not inherit a held key from title/intermission
	jsr	g2automap_seed
	jsr	g2automap_begin_level	; rebuild cache, retain session overlay choice
	clr	paused
	jsr	predrawall
	jsr	g2fps_reset	;c87a6: reset actual presented-FPS interval after buffer-prime frames
	bsr	dispon
	bsr	chaton
	;
mainloop	; Step 2: handle option keys at a main-task frame boundary
	jsr	g2automap_poll	; c87b80u: paused TAB map, never from VBlank
	jsr	g2hotkeys_poll
	jsr	drawall
	move	escape,d0
	beq.s	.noesc
	jsr	dogamemenu
	jsr	g2automap_seed	; held menu TAB must not open the map on return
	jsr	g2fps_restart_window	;c87a6: discard menu dwell before next FPS sample
	clr	escape
.noesc	; v190hy cleanup: log marker removed
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
	jsr	g2automap_release_level	; drop old map data, retain overlay choice
	jsr	g2p96_display_enter_intermission	;c86zfq: central gameplay->intermission handoff
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
gameover	jsr	g2automap_reset	; return to title ends the map session
	bsr	freeiff
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
	; c87b79x: P96 has no show/draw planar anchors. Decode the validated brush
	; directly at its explicit logical title Y and preserve the index base.
	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_brush_native
	move	#168,d6
	cmp	#2,g2_game_profile
	bne.s	.g2c87b79x_brush_y_ok
	subq	#1,d6
.g2c87b79x_brush_y_ok
	move.l	gloombrush,a0
	suba.l	a1,a1
	jsr	g2p96_static_decode_gloombrush_direct_y_c87b79x
	bra.w	.restore
.g2c87b79x_brush_native
	; c87b12: the ECS remapper is CPU-heavy.  Never run it directly against
	; the visible bitmap and never run it twice.  Copy the clean visible title
	; to the hidden bitmap, compose/remap there once, swap it atomically into
	; view, then duplicate the completed result with a fast longword copy.
	tst	aga
	bne.s	.g2c87b12_brush_legacy_two_buffers
	jsr	copypic
	move.l	drawbitmap,d0
	beq.s	.restore
	move.l	d0,a1
	jsr	.g2v142_drawone
	jsr	db
	jsr	copypic
	bra.s	.restore

.g2c87b12_brush_legacy_two_buffers
	move.l	showbitmap,d0
	beq.s	.skipshow
	move.l	d0,a1
	jsr	.g2v142_drawone
.skipshow
	move.l	drawbitmap,d0
	beq.s	.restore
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
	cmp	#2,g2display_mode
	beq.s	.g2ecs5_brush_p96
	; ECS/AGA are already planar.  Preserve the destination origin because
	; decodeiff advances a1 while expanding the image.
	move.l	a1,-(a7)
	; ECS7: keep the existing title pixels so source index 0 can behave as
	; transparent rather than becoming a black rectangle.  c87b27: Zombie
	; Massacre intentionally keeps index 0 opaque black, matching the AGA brush.
	tst	aga
	bne.s	.g2ecs7_brush_decode
	cmp	#2,g2_game_profile
	beq.s	.g2ecs7_brush_decode
	jsr	g2ecs7_save_brush_background
.g2ecs7_brush_decode
	jsr	decodeiff
	move.l	(a7)+,a1
	; Only ECS needs transparent source-palette -> title-palette remapping.
	tst	aga
	bne.s	.g2ecs5_brush_done
	jsr	g2ecs6_remap_brush_bitmap
	bra.s	.g2ecs5_brush_done
.g2ecs5_brush_p96
	jsr	g2p96_static_decode_gloombrush_direct_dispatch_c87b79u
.g2ecs5_brush_done
	movem.l	(a7)+,d0/a0-a1
	rts

; ECS4: draw the optional title overlay for Gloom Deluxe, Classic and
; Zombie Massacre.  g2v142 validates dimensions/depth before decoding, so a
; six-plane pics_ehb/gloom is safe.  Gloom3 intentionally remains overlay-free.
g2v145_draw_menu_gloombrush
	tst	aga
	bne.s	.g2c87b14_legacy_brush
	tst	g2ecs_fast_assets_enabled
	beq.s	.g2c87b14_legacy_brush
	; c87b33: every Fast-EHB main title is already fully composed offline.
	; Gloom3 has no overlay; Zombie Massacre uses title_base only for ABOUT.
	bra.s	.rts
	nop			;keep c87b32 code footprint/ranges stable
	nop
.g2c87b14_legacy_brush
	cmp	#3,g2_game_profile
	beq.s	.rts
.draw	jsr	g2v142_draw_gloombrush_safe	;legacy AGA/P96 or ZM Fast-EHB brush
	jsr	g2p96_static_present_showbitmap_plain_if_active	;c86zgv: refresh P96 title brush after full offscreen draw
.rts	rts

; v145: rebuild the clean title background.  The menu overlay is added
; separately, so ABOUT can stay free of the pics/gloom logo.
g2v145_show_clean_title
	; c87b14: ABOUT under Fast-EHB uses the separately exported uncomposited
	; title_base.  AGA/P96 and old non-Fast data retain the original title.
	tst	aga
	bne.s	.g2c87b14_clean_legacy
	tst	g2ecs_fast_assets_enabled
	beq.s	.g2c87b14_clean_legacy
	cmp	#3,g2_game_profile
	beq.s	.g2c87b14_clean_legacy	;c87b33: only Gloom3 has no separate title_base
	move.l	g2ecs_fast_title_base(pc),a0
	move.l	g2ecs_fast_title_base_pal(pc),a1
	bra.s	.g2c87b14_clean_show
.g2c87b14_clean_legacy
	move.l	gloom(pc),a0
	move.l	gloompal(pc),a1
.g2c87b14_clean_show
	jsr	showpic_noclear
	jsr	g2v36_hide_pointer
	rts

; Main title.  Under Fast-EHB, pics_ehb/title already includes the retail
; Gloom strip.  Legacy AGA/P96 still add their separate overlay afterwards.
g2v145_show_main_title
	move.l	gloom(pc),a0
	move.l	gloompal(pc),a1
	jsr	showpic_noclear
	jsr	g2v36_hide_pointer
	jmp	g2basic_log_title_once	;c87b26: log composed static/title geometry once

; v146: show the optional pics/gloom overlay immediately when the title
; screen loads.  ABOUT still uses g2v145_show_clean_title, so the overlay
; stays hidden there.  The overlay itself is still drawn at Y=168.
g2v146_show_title_with_gloom
	jsr	g2v145_show_main_title
	jsr	g2v145_draw_menu_gloombrush
	rts


dointro	;
	jsr	g2p96_display_enter_title	;c86zfq: native P96 title menu owns display
	clr	g2v190hx_level_select_active	; v190hx2: returning to title shows plain ONE PLAYER GAME again
	clr	g2v190f_level_index
	; v190gl: Classic Gloom now uses embedded Gloom2 title/menu assets,
	; so do not show the old unsupported notice.
	move	#-1,p96static_defer_present	;c86zgz: legacy P96 defers until overlay is composed
	jsr	g2v145_show_main_title	;c87b14: ECS title already includes the Gloom strip
	; c86zdu: only Zombie Massacre may pre-compose g3-dc/g3-zm before
	; dispon.  Classic Gloom was stable in c86zc7 with the brush drawn
	; after dispon; pre-drawing it can expose palette/bitmap timing issues
	; on real Amiga hardware while the emulator still looks OK.
	cmp	#2,g2_game_profile
	bne	.g2c86zdu_no_prefade_brush
	jsr	g2v145_draw_menu_gloombrush
	clr	p96static_defer_present	;c86zgz: allow composed title+brush P96 present
	jsr	g2p96_static_present_showbitmap_plain_if_active
	bsr	dispon
	bra	.g2v190ct_no_prebrush
.g2c86zdu_no_prefade_brush
	bsr	dispon
	jsr	g2v145_draw_menu_gloombrush	; c86zc7 timing for Classic/Gloom Deluxe/Gloom3-safe no-op
	clr	p96static_defer_present	;c86zgz: allow composed title+brush P96 present
	jsr	g2p96_static_present_showbitmap_plain_if_active
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
	jsr	g2p96_title_skip_redundant_brush_if_active	;c86zhd: P96 cache already has title+brush, avoid 1s redecode/present
	tst	d0
	bne.s	.g2c86zhd_skip_redraw_brush
	jsr	g2v145_draw_menu_gloombrush
.g2c86zhd_skip_redraw_brush
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
	cmp	#1,d0		;c87b4: linked title keeps only TWO PLAYER GAME
	bcs	.newgame2
	subq	#1,d0
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
	tst	d7		; v190hx: LEFT/RIGHT on ONE PLAYER controls optional level select
	beq.s	.g2v190hx_no_level_lr
	tst	d0
	beq	.g2v190f_level_lrsel
.g2v190hx_no_level_lr
	tst	g2_game_profile	; compatibility profiles use the same compact row mapping
	bne	.g2compat_notlinked
	tst	d7
	beq.s	.g2v166_notlinked_fire
	cmp	#3,d0		;c87b4: compact PLAYER 1 row
	beq	.g2v166_p1lrsel
	cmp	#4,d0		;c87b4: compact PLAYER 2 row
	beq	.g2v166_p2lrsel
	bra	.sel
.g2v166_notlinked_fire
	cmp	#2,d0		;c87b4: rows 0/1 -> one/two-player game
	bcs	.newgame
	cmp	#3,d0
	beq	.g2v166_p1sel
	cmp	#4,d0
	beq	.g2v166_p2sel
	cmp	#6,d0
	beq	.vilesel
	cmp	#7,d0
	beq	.about
	cmp	#8,d0
	beq	.exitgloom
	bra	.sel
.g2compat_notlinked
	tst	d7
	beq.s	.g2compat_fire
	cmp	#3,d0		;c87b4: compact compatibility PLAYER 1 row
	beq	.g2compat_p1lrsel
	cmp	#4,d0		;c87b4: compact compatibility PLAYER 2 row
	beq	.g2compat_p2lrsel
	bra	.sel
.g2compat_fire
	cmp	#2,d0		;c87b4: rows 0/1 -> one/two-player game
	bcs	.newgame
	cmp	#3,d0
	beq	.g2compat_p1sel
	cmp	#4,d0
	beq	.g2compat_p2sel
	cmp	#6,d0
	beq	.vilesel
	cmp	#7,d0
	beq	.about
	cmp	#8,d0
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
	cmp	#4,curropt	;c86zhd: link submenu EXIT returns to cached title menu, no full title reload
	bne.s	.g2c86zhd_link_full_return
	jsr	g2p96_title_restore_staged_background_standard_c87b78r
	bra	.redrawmenu
.g2c86zhd_link_full_return
	bra	dointro
	;
.vilesel
	addq	#1,mode
	tst	g2stock_enabled
	beq.s	.g2c87b69_mode_normal
	cmp	#2,mode		; STOCK: cycle MEATY <-> MESSY, never NASTY
	blt.s	.g2c87b17_mode_ok
	clr	mode
	bra.s	.g2c87b17_mode_ok
.g2c87b69_mode_normal
	cmp	#3,mode
	blt.s	.g2c87b17_mode_ok
	clr	mode
.g2c87b17_mode_ok
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
	; c87b14: Fast-EHB ABOUT starts from the clean title_base image.
	tst	aga
	bne.s	.g2c87b14_about_picture_ready
	tst	g2ecs_fast_assets_enabled
	beq.s	.g2c87b14_about_picture_ready
	cmp	#2,g2_game_profile
	bcc.s	.g2c87b14_about_picture_ready	;c87b22: direct G3/ZM title, no title_base
	move.l	g2ecs_fast_title_base(pc),a0
	move.l	g2ecs_fast_title_base_pal(pc),a1
.g2c87b14_about_picture_ready
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
	; c86zhe: rollback unsafe c86zhd ABOUT fast-cache return.
	; Reusing the title cache here left ABOUT/title glyph state corrupted on real hardware.
	jsr	g2v145_show_main_title	;c87b14: restore final title including offline-composited brush
	; Legacy AGA/P96 still require the separate overlay; Fast-EHB returns here.
	jsr	g2v145_draw_menu_gloombrush
	bsr	dispon
	bra	.redrawmenu
.g2v190dp_zm_about_return
	bsr	dispoff
	jsr	g2embed_apply_zm_title_overlay	; AGA keeps embedded ZM overlay; ECS is a no-op
	jsr	g2v145_show_main_title	;c87b33: ECS main title already contains the brush
	jsr	g2v145_draw_menu_gloombrush	;AGA draws separate brush; ECS Fast returns immediately
	bsr	dispon
	bra	.redrawmenu
	;
.notabout	subq	#1,d0
	bne	.sel
	;
.exitgloom	moveq	#4,d0
	;
.newgame	clr.l	map_test	; v190f: normal title starts are not forced-map tests
	tst	g2v190hx_level_select_active	; v190hx: optional ONE PLAYER: MAPx.y selection active?
	beq.s	.g2v190hx_normal_start
	bsr	g2v190f_level_start	; selected index becomes script play_ skip counter
	bra.s	.newgame_maptest
.g2v190hx_normal_start
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
.skinc	jsr	vwait
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
	jsr	vwait
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
.loop	jsr	vwait
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
.loop	jsr	vwait
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
.w10	jsr	vwait
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
	; c87b69: world-render resolution; all overlays and output remain native.
game_resolution	dc.b	'         RESOLUTION: 1x1 PIXELS                  ',0
game_bayer	dc.b	'    BAYER DITHERING: YES                        ',0
	; CEILING precedes FLOOR consistently in every game profile.
game_ceil	dc.b	'            CEILING: YES                        ',0
game_floor	dc.b	'              FLOOR: YES                        ',0
	dc.b	92,0
game_blob	dc.b	'       BLOB SHADOWS: NO                         ',0
game_reflections	dc.b	'        REFLECTIONS: NO                         ',0
game_visibility	dc.b	'      VIEW DISTANCE:  DEFAULT                    ',0
	dc.b	92,0
game_inv	dc.b	'   UNLIMITED HEALTH: NO                         ',0
game_bouncy	dc.b	'     BOUNCY BULLETS: NO                         ',0
game_onehit	dc.b	'       ONE HIT KILL: NO                         ',0
game_weapon	dc.b	'             WEAPON: DEFAULT                    ',0
game_boost	dc.b	'            UPGRADE: DEFAULT                    ',0
	dc.b	92,0
	dc.b	'QUIT GAME',0

	even

trainer_resolution_values
	dc.l	trainer_resolution_1x1
	dc.l	trainer_resolution_2x1
	dc.l	trainer_resolution_1x2
	dc.l	trainer_resolution_2x2
trainer_resolution_1x1	dc.b	'1x1 PIXELS',0
trainer_resolution_2x1	dc.b	'2x1 PIXELS',0
trainer_resolution_1x2	dc.b	'1x2 PIXELS',0
trainer_resolution_2x2	dc.b	'2x2 PIXELS',0
	even

g2_resolution	dc	0	;c87b69 0=1x1, 1=2x1, 2=1x2, 3=2x2
g2_bayer_disabled	dc	0	; Step 1: session switch, 0=YES (default), -1=NO


g2_blobshadow	dc	-1	;v116c menu flag, v126 enables enemy blob shadow
g2_reflections	dc	-1	;c87b38 -1=NO, 2=WEAPON(projectiles/upgrades), 1=ALL(+walls/enemies/players)
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
g2_reflect_pickup	dc	0	;v169/c86zcv current reflection owner is stationary weapon upgrade
g2_reflect_nearthick	dc	0	;c86zdh 0=far, 1=near, 2=very near vertical oval thickening
g2_reflect_pulse	dc	0	;c86zdq smooth 0..4 weapon-upgrade floor-touch pulse up to about 1.8x
g2_reflect_softedge	dc	0	;v135 reflection-only edge feather/dither flag
g2_reflect_edge_col	dc	0	;v137 lighter outer reflection colour
g2_enemy_ref_active	dc	0	;c86r independent enemy mirror-reflection state
g2_enemy_ref_curx	dc	0
g2_enemy_ref_cx	dc	0
g2_enemy_ref_rx	dc	0
g2_enemy_ref_floorrow	dc	0
g2_enemy_ref_h	dc	0
g2_enemy_ref_z	dc	0	;c86zb3 enemy depth for per-column cover blocking
g2_enemy_ref_srcidx	dc.l	0	;c86x source-mask index for uneven transparent sprite bottoms
g2_enemy_ref_srcstep	dc.l	0	;c86x source-mask y step
trainer_invincible	dc	0
trainer_bouncy	dc	0
trainer_onehit	dc	0	;0=NO, -1=YES one-shot enemy kills
trainer_weapon	dc	0	;0=DEFAULT, 1..5 forced weapon
trainer_boost	dc	0	;0=DEFAULT, 1..5 forced upgrade
game_menu_active	dc	0	;-1 while in in-game menu

modes	dc.l	mode1,mode2,mode3

; c87b69d: all labels are exactly 20 characters plus terminator so the live menu
; buffer can safely receive NASTY without overwriting ABOUT.
mode1	dc.b	'MEATY VIOLENCE MODE ',0
mode2	dc.b	'MESSY VIOLENCE MODE ',0
mode3	dc.b	'NASTY VIOLENCE MODE ',0

startmenu	dc.b	9		;c87b4: combat/link rows removed; level select remains on row 0 LEFT/RIGHT
	dc.b	'ONE PLAYER GAME',0	;0
	dc.b	'TWO PLAYER GAME',0	;1
	dc.b	0			;2 spacer/separator above PLAYER 1
	dc.b	'PLAYER 1 '
p1ctype
	ifne	cd32
	dc.b	'CD32 PAD 1',0	;3, fixed 10-char field
	elseif
	dc.b	'KEYBMOUSE  ',0		;3, fixed 10-char field
	endc
	;
	dc.b	'PLAYER 2 '
p2ctype
	ifne	cd32
	dc.b	'CD32 PAD 2',0	;4, fixed 10-char field
	elseif
	dc.b	'JOYSTICK 1 ',0		;4, fixed 10-char field
	endc
	;
	dc.b	0			;5 spacer/separator above VIOLENCE MODE
modetxt	dc.b	'MEATY VIOLENCE MODE ',0	;6, c87b17 fixed 21-char field
	dc.b	'ABOUT',0		;7
	dc.b	'EXIT',0		;8
	even

g2v190f_level_text	dc.b	'MAP1.1',0	; hidden level selector text buffer; script/stages scan kept
	even

compat_startmenu	dc.b	9		;c87b4: compact Gloom/Gloom3/ZM menu; level select remains on row 0
	dc.b	'ONE PLAYER GAME',0	;0
	dc.b	'TWO PLAYER GAME',0	;1
	dc.b	0			;2 spacer/dotted line above PLAYER rows
	dc.b	'PLAYER 1 '
p1ctypec
	ifne	cd32
	dc.b	'CD32 PAD 1',0	;3, fixed 10-char field
	elseif
	dc.b	'KEYBMOUSE  ',0		;3, fixed 10-char field
	endc
	;
	dc.b	'PLAYER 2 '
p2ctypec
	ifne	cd32
	dc.b	'CD32 PAD 2',0	;4, fixed 10-char field
	elseif
	dc.b	'JOYSTICK 1 ',0		;4, fixed 10-char field
	endc
	;
	dc.b	0			;5 spacer/dotted line above VIOLENCE MODE
modetxtc	dc.b	'MEATY VIOLENCE MODE ',0	;6, c87b17 fixed 21-char field
	dc.b	'ABOUT',0		;7
	dc.b	'EXIT',0		;8
	even

g2v190f_level_index dc 0
g2v190hx_level_select_active dc 0	; 0=plain ONE PLAYER GAME, -1=show/use selected level

g2v190f_level_next
	tst	g2v190hx_level_select_active
	bne.s	.g2v190hx_next_already
	move	#-1,g2v190hx_level_select_active	; first RIGHT enables optional level text
	clr	g2v190f_level_index	; first shown level is the first script entry
	bra	g2v190f_level_update
.g2v190hx_next_already
	move	g2v190i_level_count(pc),d1
	beq	g2v190f_level_update
	move	g2v190f_level_index(pc),d0
	addq	#1,d0
	cmp	d1,d0
	bcs.s	.g2v190hx_next_store
	subq	#1,d1		; stop at last level, do not wrap
	move	d1,d0
.g2v190hx_next_store
	move	d0,g2v190f_level_index
	bra	g2v190f_level_update

g2v190f_level_prev
	tst	g2v190hx_level_select_active
	beq	g2v190f_level_update	; LEFT before first RIGHT keeps plain ONE PLAYER GAME
	move	g2v190i_level_count(pc),d1
	beq	g2v190f_level_update
	tst	g2v190f_level_index
	beq	g2v190f_level_update	; stop at first level, do not wrap/remove selector
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

; v190hx: optional ONE PLAYER level suffix.  The menu table itself stays
; unchanged, so RETURN starts normally until LEFT/RIGHT activates this text.
g2v190hx_level_menu_a4
	tst	g2v190hx_level_select_active
	beq.s	.rts
	cmp.l	#startmenu+1,a4
	beq.s	.use
	cmp.l	#compat_startmenu+1,a4
	bne.s	.rts
.use	bsr.s	g2v190hx_level_build_row
	lea	g2v190hx_level_row_text(pc),a4
.rts	rts

g2v190hx_level_build_row
	movem.l	d0-d2/a0-a1,-(a7)
	tst	g2v190i_level_count
	bne.s	.have
	jsr	g2v190i_level_default
.have	lea	g2v190hx_level_prefix(pc),a0
	lea	g2v190hx_level_row_text(pc),a1
.pfx	move.b	(a0)+,d1
	beq.s	.level
	move.b	d1,(a1)+
	bra.s	.pfx
.level	move	g2v190f_level_index(pc),d0
	cmp	g2v190i_level_count(pc),d0
	bcs.s	.idxok
	clr	g2v190f_level_index
	moveq	#0,d0
.idxok	jsr	g2v190i_get_name_ptr
	moveq	#15,d2
.copy	move.b	(a0)+,d1
	beq.s	.done
	move.b	d1,(a1)+
	dbf	d2,.copy
.done	clr.b	(a1)
	movem.l	(a7)+,d0-d2/a0-a1
	rts

g2v190hx_level_prefix dc.b 'ONE PLAYER GAME: ',0
g2v190hx_level_row_text ds.b 40
	even

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
	clr	g2v190hx_level_select_active	; v190hx: title starts as plain ONE PLAYER GAME
	bsr	permit
	; v190hx3: Classic Gloom may have misc/script stored compressed on disk.
	; The normal loader has already decrunched it into the script pointer, so
	; parse that in-memory script first.  If it yields no play_ entries, fall
	; back to the simple program-folder file scanner used by v190hx.
	move.l	script(pc),d0
	beq.s	.g2v190hx3_try_files
	move.l	d0,a0
	jsr	g2v190i_parse_script
	tst	g2v190i_level_count
	bne	.doneio
.g2v190hx3_try_files
	lea	g2v190i_script_misc(pc),a0	; v190hx: program-folder misc/script
	bsr	g2v190i_try_script
	tst	g2v190i_level_count
	bne	.doneio
	lea	g2v190i_script_stages(pc),a0	; v190hx: program-folder stuf/stages
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
	; v190hx4: load the script through the normal loadfile path instead of
	; DOS Read().  Classic Gloom's misc/script can be CrM2-packed; raw scanning
	; sees only compressed bytes and falls back to MAP1.1.  loadfile gives this
	; scanner the same decrunched script data the game later executes.
	movem.l	d0-d7/a0-a6,-(a7)
	moveq	#1,d1		; public/fast memory is enough for temporary script scan
	jsr	loadfile		; a0 = filename, returns decrunched pointer in d0 or 0
	move.l	d0,d7
	beq.w	.done
	move.l	d7,a0
	jsr	g2v190i_parse_script
	move.l	d7,a1
	jsr	freemem_		; release temporary scan copy
.done
	movem.l	(a7)+,d0-d7/a0-a6
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
	; v190hx4: command match is case-insensitive, like execscript itself.
	; This keeps Classic scripts safe even if commands are PLAY_/DONE_.
	moveq	#0,d1
	move.b	(a6),d1
	and	#31,d1
	add	#96,d1
	lsl.l	#8,d1
	moveq	#0,d2
	move.b	1(a6),d2
	and	#31,d2
	add	#96,d2
	or	d2,d1
	lsl.l	#8,d1
	moveq	#0,d2
	move.b	2(a6),d2
	and	#31,d2
	add	#96,d2
	or	d2,d1
	lsl.l	#8,d1
	moveq	#0,d2
	move.b	3(a6),d2
	and	#31,d2
	add	#96,d2
	or	d2,d1
	cmp.b	#'_',4(a6)
	bne	.skipline
	cmp.l	#'done',d1
	beq	.done
	cmp.l	#'play',d1
	bne	.skipline
	move.l	a6,a5		; v190r: remember script command start for chain entry
	lea	5(a6),a0
	jsr	g2v190i_add_level
.skipline
	move.b	(a6)+,d0
	beq	.done
	cmp.b	#13,d0		; v190hx3: Amiga/Classic scripts can be CR-only
	beq	.loop
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

