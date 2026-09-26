startmenu2	dc.b	4		;c87b4: combat row removed from linked title menu
	dc.b	'TWO PLAYER GAME',0	;0
	dc.b	'UNLINK FROM REMOTE PLAYER',0	;1
	dc.b	'ABOUT',0		;2
	dc.b	'EXIT',0		;3
	even

menuwindow	dc.l	0
menubmap	dc.l	0

menuy	dc	0
numopts	dc	0	;how many menu options
curropt	dc	0	;current option
flashdelay	dc	0

menustrips	ds.l	36	;18 max: one text/strip pointer pair for every gamemenu row

qmenu	;quick menu in a0
	; c87w5: the old body occupied 22 bytes.  menustrips now needs four
	; additional longs for the 17th/18th menu rows, so keep all following
	; labels at their proven addresses by replacing this body with a 6-byte
	; absolute jump and moving the implementation to the file end.
	jmp	g2wide_qmenu_relocated

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
	beq.s	.g2c87b79w_soft_no_strip
	freemem	menustrip
.g2c87b79w_soft_no_strip
	dbf	d2,.loop
.nostrips	clr	numopts
	bra	finitfontpal

; v147: redraw a picture/menu pair without the showpic clear/dispoff path.
g2v147_pmenu_soft	;a0=iff, a1=palette, a2=menu
	move.l	a2,-(a7)
	; c86zhe: rollback unsafe c86zhd ABOUT fast-background shortcut.
	; The ABOUT screen must build its own picture/menu pair or the font deltas corrupt.
	bsr	showpic_noclear
	move.l	(a7)+,a4
	bsr	initmenu
	bra	dispon

g2v190cs_pmenu_precomposed	;a2=menu, title/overlay already present in show/draw bitmaps
	move.l	a2,a4
	bsr	initmenu
	bra	dispon

swapshow	cmp	#2,g2display_mode	;c87b79x: no P96 planar ownership
	beq.s	.g2c87b79x_done
	movem.l	showbitmap(pc),d0-d1
	exg	d0,d1
	movem.l	d0-d1,showbitmap
.g2c87b79x_done
	rts

finitfontpal
	clr	g2inter_yellow_text_active
	clr	g2ecs7_direct_font_active
	clr	g2ecs8_defer_font_palette
	clr	g2ecs8_font_palette_pending
	bra	pokelastpal

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
	; c87b79x: DISPLAY=P96 has no planar compatibility pages. Arm the direct
	; menu contract unconditionally, then warm the glyph target when available.
	; A failed cache/target probe degrades to missing text, never to a null
	; planar fallback. Native AGA/ECS retain the complete old sequence.
	clr	p96menu_native_init_active
	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_planar_seed
	move	#-1,p96menu_native_init_active
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq.s	.g2c87b79x_seed_ready
	jsr	g2p96_menu_glyph_prepare_target_c87b78d
	bra.s	.g2c87b79x_seed_ready
.g2c87b79x_planar_seed
	bsr	copypic
	bsr	swapshow
.g2c87b79x_seed_ready
	; ECS7: every non-game ECS menu shown over title/about artwork uses the
	; exact original Bigfont colours.  First evacuate picture pixels from
	; indices 1..3 and their EHB partners 33..35, then install initfontpal.
	tst	aga
	bne.s	.g2ecs7_normal_menu_fontpal
	tst	game_menu_active
	bne.s	.g2ecs7_normal_menu_fontpal
	move.l	lastpal(pc),a1
	move	#-1,g2ecs8_defer_font_palette
	jsr	g2ecs7_prepare_exact_font_overlay
	clr	g2ecs8_defer_font_palette
	tst	g2ecs7_direct_font_active
	bne.s	.g2ecs7_menu_font_ready
.g2ecs7_normal_menu_fontpal
	bsr	initfontpal
.g2ecs7_menu_font_ready
	; c87b79x: p96menu_native_init_active was resolved before the planar
	; seed. Do not probe again here: the same decision owns this whole init.
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
	sub	fonth(pc),d6	;c87b4: cancel 11->9 auto-recentring, keep first row fixed
	bra.s	.titlemenu_y_done
.titlemenu_compat	move	#2,g2v154_titlemenu_lines	; compatibility menus keep dotted lines
	sub	fonth(pc),d6	; original compatibility offset row 1
	sub	fonth(pc),d6	; original compatibility offset row 2
	sub	fonth(pc),d6	;c87b4: cancel 11->9 auto-recentring, keep first row fixed
.titlemenu_y_done
	move	d6,menuy
	lea	menustrips(pc),a5
	;
.loop	;save strip!
	;
	move.l	a4,(a5)+
	; c87b79x: direct P96 rows use only the string pointer plus staged page/
	; row caches. Keep a null strip slot so teardown and audits can distinguish
	; this path without allocating or reading planar menu background memory.
	tst	p96menu_native_init_active
	beq.s	.g2c87b79x_make_strip
	clr.l	(a5)+
	bra.w	.g2c87b79x_strip_ready
.g2c87b79x_make_strip
	;
	move	fonth(pc),d0
	mulu	#40,d0
	mulu	bitplanes(pc),d0
	moveq	#2,d1
	allocmem	menustrip
	tst.l	d0
	bne.s	.strip_alloc_ok
	jmp	g2menu_allocation_failed	; no null strip copy, no partial-menu continuation
.strip_alloc_ok
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
.g2c87b79x_strip_ready
	;
	move.l	a4,-(a7)		; v190hx: keep original menu stream pointer
	bsr	g2v190hx_level_menu_a4	; draw optional ONE PLAYER: MAPx.y row
	move.l	a4,a0
	moveq	#-1,d0
.cnt	addq	#1,d0
	tst.b	(a0)+
	bne.s	.cnt
	;
	tst	p96menu_native_init_active
	bne	.g2c86zjj_skip_planar_text
	jsr	printmess2
.g2c86zjj_skip_planar_text
	move.l	(a7)+,a4		; restore and advance original sequential menu string
.g2v190hx_adv_orig
	tst.b	(a4)+
	bne.s	.g2v190hx_adv_orig
	;
	add	fonth(pc),d6
	subq	#1,(a7)
	bgt.w	.loop	;c87b79w1: GenAm short branch exceeded 8-bit displacement
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
	; c87b12: ECS7 already evacuates picture indices 1..3/33..35 before
	; menu composition.  Separator index 2 is therefore safe on ECS again.
	tst	p96menu_native_init_active
	bne.s	.g2v154_no_title_lines
	bsr	g2v154_draw_titlemenu_lines
.g2v154_no_title_lines
	tst	g2v158_titlemenu_credit
	beq.s	.g2v158_no_title_credit
	bsr	g2v158_draw_title_credit
.g2v158_no_title_credit
	; c87b79x: a direct P96 init never owns a planar draw page, so do
	; not swap or publish one. The native full-menu batch below publishes the
	; completed staged CLUT rectangle. Native/fallback paths stay unchanged.
	tst	p96menu_native_init_active
	bne.s	.g2c87b79x_planar_publish_done
	bsr	swapshow
	bsr	db
.g2c87b79x_planar_publish_done
	; ECS8: db now points the next frame at the fully remapped/menu-composed
	; bitmap. Wait for that VBlank before changing colours 1..3, eliminating
	; the one-frame flash of the old, unremapped title bitmap.
	tst	g2ecs8_font_palette_pending
	beq.s	.g2ecs8_menu_palette_ready
	jsr	vwait
	; ECS9: ChangeVPBitMap is asynchronous. If called during an already active
	; blank, the first vwait can return before the new bitmap is actually shown.
	; A second full VBlank is required only for the OS-managed ECS screen.
	tst	os
	beq.s	.g2ecs9_bitmap_switch_settled
	jsr	vwait
.g2ecs9_bitmap_switch_settled
	jsr	initfontpal
	clr	g2ecs8_font_palette_pending
.g2ecs8_menu_palette_ready
	jsr	g2p96_static_present_title_menu_bigfont_if_active	;c86zgx: title menu text via real bigfont delta only
	bra	vwait

; c87b4: draw two thin 80px dotted separators in the compact title menu:
; one between TWO PLAYER GAME and PLAYER 1, one between PLAYER 2 and
; VIOLENCE MODE. Each dot uses a slightly
; brighter yellow from the existing palette, while every second pixel stays
; transparent so the title image remains visible in between.
g2v154_draw_titlemenu_lines
	movem.l	d0-d7/a0-a2,-(a7)
	move.l	showbitmap(pc),a0
	move	menuy(pc),d0
	move	fonth(pc),d1
	move	d1,d2
	lsr	#1,d2
	moveq	#2,d3	;c87b4: compact first spacer row
	cmp	#2,g2v154_titlemenu_lines
	bne.s	.g2v190cp_line1row_ok
	moveq	#2,d3
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
	moveq	#5,d3	;c87b4: compact second spacer row
	cmp	#2,g2v154_titlemenu_lines
	bne.s	.g2v190cp_line2row_ok
	moveq	#5,d3
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
	; c86zjj: P96 glyph-cache menus erase the row from the native backdrop;
	; do not touch the Amiga blitter or the planar menubmap.
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq	.g2c86zjj_legacy_optoff
	clr	p96menu_native_selected
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	move	#13,flashdelay
	rts
.g2c86zjj_legacy_optoff
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
	bsr	disownblitter
	clr	p96menu_native_selected	;c86zgd: native P96 row = normal/off
	jsr	g2p96_menu_current_row_present	;c86zgd: native row restore + redraw
	rts

opton	; c86zjj: direct cached Bigfont row for P96, original printmess2 for AGA/fallback.
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq	.g2c86zjj_legacy_opton
	move	#-1,p96menu_native_selected
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
	move	#13,flashdelay
	rts
.g2c86zjj_legacy_opton
	move	curropt(pc),d6
	lea	menustrips(pc),a0
	move.l	0(a0,d6*8),a4	;text!
	bsr	g2v190hx_level_menu_a4	; v190hx: selected first row uses dynamic level text
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
	move	#-1,p96menu_native_selected	;c86zgd: native P96 row = selected/on
	jsr	g2p96_menu_current_row_present	;c86zgd: native row restore + redraw
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
	jsr	readjoy1	;c86zcn build-safe absolute call after added player-reflection code
	lea	joyx0,a0
	jsr	readkeys	;c86zdk build-safe absolute call after pulse code growth
	move.l	joyx0(pc),d0
	or.l	d0,joyx
	move.l	joyb0(pc),d0
	or.l	d0,joyb
	;
	jsr	g2hotkeys_menu_key	; ESC or F10, same release handling
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
	jsr	g2hotkeys_poll_menu	; both native and P96 selection loops
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
	jsr	g2p96_menu_should_use_stable_select	;c86zgo: P96 keeps selected row stable, no flicker-blink
	tst	d0
	beq.s	.g2c86zgo_old_blink
	jmp	g2p96_menu_selmenu_stable
.g2c86zgo_old_blink
	bsr	optoff
.loop1	jsr	vwait
	jsr	readmenusel
	bne.s	.joygot
	subq	#1,flashdelay
	bgt.s	.loop1
	;
	bsr	opton
.loop2	jsr	vwait
	jsr	readmenusel
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
	jsr	menuskip	;v115 visual spacer rows are never selectable
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
	cmp	#9,d1		;c87b4: compact title menu still supports level/player LEFT/RIGHT
	beq.s	g2v166_tplr_compact
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
	tst	d1		; ONE PLAYER GAME accepts LEFT/RIGHT for optional level select
	beq.s	g2v166_tplr_yes
	cmp	#4,d1
	beq.s	g2v166_tplr_yes
	cmp	#5,d1
	beq.s	g2v166_tplr_yes
	bra.s	g2v166_tplr_no
g2v166_tplr_compact
	move	curropt(pc),d1
	tst	d1		;c87b4: ONE PLAYER level select
	beq.s	g2v166_tplr_yes
	cmp	#3,d1		;c87b4: PLAYER 1 control
	beq.s	g2v166_tplr_yes
	cmp	#4,d1		;c87b4: PLAYER 2 control
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
g2v166_upchk	jsr	menuskip
	beq.s	g2v166_sel_up
	bra	selmenu
	;
g2v166_sel_down	addq	#1,curropt
	move	curropt(pc),d0
	cmp	numopts(pc),d0
	bcs.s	g2v166_downchk
	clr	curropt
g2v166_downchk	jsr	menuskip
	beq.s	g2v166_sel_down
	bra	selmenu

finitmenu	;clean up menu operation
	;
	bsr	clspic
	jsr	vwait
	lea	menustrips(pc),a5
	move	numopts(pc),d2
	subq	#1,d2
.loop	addq	#4,a5
	move.l	(a5)+,a1
	beq.s	.g2c87b79w_no_strip
	freemem	menustrip
.g2c87b79w_no_strip
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
	; c87b64 STOCK: retain the original Gloom distance-shade result and skip
	; the Reforged one-step darkness boost plus the stronger 4..8-width fog
	; ramp below. This is evaluated only while the startup table is built.
	tst	g2stock_enabled
	bne.w	.g2stock_dark_store
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
.g2stock_dark_store
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
wasd_state	dc.b	0	;bit1 W, bit2 A, bit3 S/X(back), bit4 D
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
	cmp.b	#'S',d0	; c86zdt: S also maps to backward; X still handled by rawcode $32
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

; v190hy: diagnostic RAM:gloom.log logger removed for cleanup/speed.
; v190hy: all g2log/g2log_drawstep call sites were removed.

; c87b69: binary PROGDIR:gloom.cfg persistence, version 4.
; v4 appends the RESOLUTION word. v1-v3 migrate safely to 1x1 PIXELS.
g2cfg_load
	movem.l	d0-d7/a0-a6,-(a7)
	clr	g2_bayer_disabled	; old configs default to Bayer YES
	move.l	dosbase,a6
	lea	g2cfg_name(pc),a0
	move.l	a0,d1
	move.l	#1005,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq	.load_done
	move.l	d7,d1
	lea	g2cfg_buf(pc),a0
	move.l	a0,d2
	move.l	#g2cfg_len+18,d3
	jsr	-42(a6)
	move.l	d0,d6
	move.l	d7,d1
	jsr	-36(a6)
	cmp.l	#g2cfg_len,d6
	bge.s	.len_ok
	cmp.l	#g2cfg_len_v3,d6
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
	blt	.load_done
	cmp	#4,d7
	bgt	.load_done
	addq.l	#4,a0		; discard historic width/hite fields
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
	blt.s	.no_onehit
	move	(a0)+,trainer_onehit
.no_onehit
	move	#-1,g2_visibility
	cmp	#3,d7
	blt.s	.no_visibility
	move	(a0)+,g2_visibility
.no_visibility
	clr	g2_resolution
	cmp	#4,d7
	bne.s	.no_resolution
	move	(a0)+,g2_resolution
.no_resolution
	cmp.l	#g2cfg_len+18,d6
	blt.s	.no_bayer
	lea	g2cfg_buf+g2cfg_len+12,a0
	cmp.l	#'BAY1',(a0)+
	bne.s	.no_bayer
	tst.w	(a0)
	beq.s	.no_bayer
	move	#-1,g2_bayer_disabled
	move	#-1,g2_reflections	; saved Bayer NO keeps reflections locked OFF
.no_bayer
	bsr	g2cfg_sanitize
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
	move	#4,(a0)+
	move	#320,(a0)+		; obsolete slots retained for compatible layout
	move	#240,(a0)+
	move	floorflag,(a0)+
	move	roofflag,(a0)+
	tst	g2stock_enabled
	beq.s	.live_effects
	move	g2stock_cfg_blobshadow,(a0)+
	move	g2stock_cfg_reflections,(a0)+
	bra.s	.effects_done
.live_effects
	move	g2_blobshadow,(a0)+
	move	g2_reflections,(a0)+
.effects_done
	move	trainer_invincible,(a0)+
	move	trainer_bouncy,(a0)+
	move	trainer_weapon,(a0)+
	move	trainer_boost,(a0)+
	move	trainer_onehit,(a0)+
	tst	g2stock_enabled
	beq.s	.live_visibility
	move	g2stock_cfg_visibility,(a0)+
	bra.s	.visibility_done
.live_visibility
	move	g2_visibility,(a0)+
.visibility_done
	move	g2_resolution,(a0)+
	; RC4: append the same backward-compatible P96 preferences used by GloomBench.
	move.l	#'P961',(a0)+
	tst	g2rc4_save_screenmode_v21
	beq.s	.rc4_cfg_no_modeid
	move.l	g2rc4_saved_modeid_v21,d0
	bra.s	.rc4_cfg_store_modeid
.rc4_cfg_no_modeid
	moveq	#0,d0
.rc4_cfg_store_modeid
	move.l	d0,(a0)+
	move	g2rc4_save_screenmode_v21,d0
	beq.s	.rc4_cfg_store_save
	moveq	#-1,d0
.rc4_cfg_store_save
	move	d0,(a0)+
	move	g2rc4_low_bandwidth_v21,d0
	beq.s	.rc4_cfg_store_low
	moveq	#-1,d0
.rc4_cfg_store_low
	move	d0,(a0)+
	; Keep the v4/P961 prefix intact; append the independent Bayer setting.
	move.l	#'BAY1',(a0)+
	move	g2_bayer_disabled,d0
	tst	g2stock_enabled
	beq.s	.store_bayer
	move	g2stock_cfg_bayer,d0	; STOCK must not overwrite the saved normal choice
.store_bayer
	move	d0,(a0)+
	move.l	dosbase,a6
	lea	g2cfg_name(pc),a0
	move.l	a0,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq	.save_done
	move.l	d7,d1
	lea	g2cfg_buf(pc),a0
	move.l	a0,d2
	move.l	#g2cfg_len+18,d3
	jsr	-48(a6)
	move.l	d7,d1
	jsr	-36(a6)
.save_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2cfg_sanitize
	move	floorflag,d0
	bgt.s	.floor_yes
	move	#-1,floorflag
	bra.s	.floor_ok
.floor_yes	move	#1,floorflag
.floor_ok
	move	roofflag,d0
	bgt.s	.roof_yes
	move	#-1,roofflag
	bra.s	.roof_ok
.roof_yes	move	#1,roofflag
.roof_ok
	move	floorflag,floorflag2
	move	roofflag,roofflag2
	move	g2_blobshadow,d0
	bgt.s	.blob_yes
	move	#-1,g2_blobshadow
	bra.s	.blob_ok
.blob_yes	move	#1,g2_blobshadow
.blob_ok
	move	g2_reflections,d0
	cmp	#2,d0
	beq.s	.refl_ok
	tst	d0
	bgt.s	.refl_all
	move	#-1,g2_reflections
	bra.s	.refl_ok
.refl_all	move	#1,g2_reflections
.refl_ok
	move	g2_visibility,d0
	bgt.s	.visibility_yes
	move	#-1,g2_visibility
	bra.s	.visibility_ok
.visibility_yes	move	#1,g2_visibility
.visibility_ok
	tst	trainer_invincible
	beq.s	.inv_ok
	move	#-1,trainer_invincible
.inv_ok
	tst	trainer_bouncy
	beq.s	.bouncy_ok
	move	#-1,trainer_bouncy
.bouncy_ok
	tst	trainer_onehit
	beq.s	.onehit_ok
	move	#-1,trainer_onehit
.onehit_ok
	move	trainer_weapon,d0
	bpl.s	.weapon_pos
	clr	trainer_weapon
	bra.s	.weapon_ok
.weapon_pos	cmp	#5,d0
	ble.s	.weapon_ok
	move	#5,trainer_weapon
.weapon_ok
	move	trainer_boost,d0
	bpl.s	.boost_pos
	clr	trainer_boost
	bra.s	.boost_ok
.boost_pos	cmp	#5,d0
	ble.s	.boost_ok
	move	#5,trainer_boost
.boost_ok
	move	g2_resolution,d0
	cmp	#3,d0
	bls.s	.resolution_ok
	clr	g2_resolution
.resolution_ok
	move	#320,width
	move	#240,hite
	rts

g2cfg_apply_view
	move	#320,width
	move	#240,hite
	move	#320,chunkymodw
	move	#-160,minx
	move	#160,maxx
	move	#-120,miny
	move	#120,maxy
	clr.l	offset
	rts

g2cfg_name	dc.b	'PROGDIR:gloom.cfg',0
	even
g2cfg_len_old	equ	6+2+(10*2)
g2cfg_len_v2	equ	6+2+(11*2)
g2cfg_len_v3	equ	6+2+(12*2)
g2cfg_len	equ	6+2+(13*2)
g2cfg_buf	ds.b	g2cfg_len+18
g2stock_cfg_bayer	dc.w	0
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
.help	jsr	vwait
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
	; Gloombench2 Patch 1: ordinary CPU-side file loads use FastRAM first.
	; Explicit CHIP requests (d1=2) remain untouched. allocmem2_ falls back
	; from MEMF_FAST to MEMF_PUBLIC if FastRAM is unavailable.
	cmp.l	#1,d5
	bne.s	.g2bench_p1_memtype_ready
	moveq	#4,d5		; MEMF_FAST
.g2bench_p1_memtype_ready
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
	; c87b70g: Classic Gloom replaces the early embedded fallback with its
	; live map-derived palette/remap before this routine is called. Other
	; profiles continue to use their physical/embedded remap tables.
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
	; v190bz: rebuild chunky transparent-strip colour filter LUTs whenever
	; the level palette/shade palettes are regenerated.
	jsr	g2build_strip_luts
	rts

dispoff	tst	dispnest
	bne.s	.skip
	jsr	vwait
	tst	os
	bne.s	.skip
	move	#$01a0,$dff096	;bp/cop/spr off!
.skip	addq	#1,dispnest
	rts

dispon	subq	#1,dispnest
	bgt.s	.skip
	jsr	vwait
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
.fl	jsr	vwait
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


; c86zhz: very early AGA requirement guard.
; Runs after CLI/Workbench launch handling and DOS output setup, but before
; DISPLAY parsing, P96 probing, screen opening, memory checks, or initmain.
; First use the OS-supported GfxBase chipset flag.  If SetPatch has not yet
; populated that flag on an AGA machine, accept the AGA Denise/Lisa ID $f8 as
; a secondary check.  OCS/ECS systems are rejected before any game display.
g2early_aga_guard
	movem.l	d1-d7/a0-a6,-(a7)
	clr	d7			;0 = continue, -1 = abort
	move.l	4.w,a6
	lea	grname(pc),a1
	jsr	-408(a6)		;OldOpenLibrary graphics.library
	move.l	d0,d6
	beq.s	.noaga
	move.l	d0,a6
	btst	#2,$ec(a6)		;GFXB_AA_ALICE / gb_ChipRevBits0
	bne.s	.aga_close
	; Secondary hardware check for AGA machines booted without SetPatch.
	move.w	$dff07c,d0		;DENISEID
	and.w	#$00ff,d0
	cmp.w	#$00f8,d0		;Lisa/AGA identification value
	beq.s	.aga_close
	bra.s	.noaga_close
.aga_close
	move.l	d6,a1
	move.l	4.w,a6
	jsr	-414(a6)		;CloseLibrary
	bra.s	.done
.noaga_close
	move.l	d6,a1
	move.l	4.w,a6
	jsr	-414(a6)		;CloseLibrary
.noaga
	moveq	#-1,d7
	bsr	g2early_show_noaga_notice
.done
	move	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; CLI launches write to the current shell.  Workbench launches use an
; ordinary EasyRequestArgs requester on the default public/Workbench screen.
g2early_noaga_cli_text
	dc.b	10,'The selected AGA mode requires an AGA Amiga.    ',10
	dc.b	'Use the bare ECS token to start the ECS EHB renderer.',10,10
g2early_noaga_cli_text_end
g2early_noaga_cli_text_len	equ	g2early_noaga_cli_text_end-g2early_noaga_cli_text

g2early_intuition_name	dc.b	'intuition.library',0
g2early_req_title	dc.b	'Gloom Reforged',0
g2early_req_body	dc.b	'The selected AGA mode requires an AGA Amiga.    ',10,'Use the bare ECS token for the ECS EHB renderer.',0
g2early_req_gadget	dc.b	'OK',0
	even
g2early_easystruct
	dc.l	20			;sizeof(struct EasyStruct)
	dc.l	0			;flags
	dc.l	g2early_req_title
	dc.l	g2early_req_body
	dc.l	g2early_req_gadget

	even
g2early_show_noaga_notice
	movem.l	d0-d4/a0-a3/a6,-(a7)
	tst.l	wbmess
	bne.s	.workbench
	; CLI: Write(Output(), message, length)
	move.l	dosbase,d0
	beq.s	.done
	move.l	outhand,d1
	beq.s	.done
	lea	g2early_noaga_cli_text(pc),a0
	move.l	a0,d2
	move.l	#g2early_noaga_cli_text_len,d3
	move.l	dosbase,a6
	jsr	-48(a6)		;dos.library/Write
	bra.s	.done
.workbench
	move.l	4.w,a6
	lea	g2early_intuition_name(pc),a1
	jsr	-408(a6)		;OldOpenLibrary intuition.library
	move.l	d0,d4
	beq.s	.done
	move.l	d0,a6
	suba.l	a0,a0			;no reference window: Workbench/public screen
	lea	g2early_easystruct(pc),a1
	suba.l	a2,a2			;no IDCMP result pointer
	suba.l	a3,a3			;no formatting arguments
	jsr	-588(a6)		;EasyRequestArgs
	move.l	d4,a1
	move.l	4.w,a6
	jsr	-414(a6)		;CloseLibrary
.done
	movem.l	(a7)+,d0-d4/a0-a3/a6
	rts

; Display-mode selector.  It reads bare AGA/ECS/P96 tokens from ToolTypes
; or CLI.  ECS1 applies the selected value to the old runtime 'aga' flag
; immediately after this parser returns.  Later P96 stages resolve
; the actual ModeID live on each start because P96 mode numbers are setup-
; dependent between emulators, monitor drivers and real RTG hardware.
g2display_cli_ptr	dc.l	0
g2display_mode	dc	1	;1=AGA, 2=P96, 3=ECS
g2display_source	dc	0	;0=hardware default, 1=ToolType, 2=CLI
g2p96_hires_mode	dc	0	;0/NO=320x240, -1/YES=640x480
g2p96_stretch_mode	dc	0	;0=normal, -1=widescreen stretch
g2p96_wide_mode	dc	0	;native horizontal WIDE rendering, P96 only
g2p96_oneone_mode	dc	0	;P96-only true vertical 320x256 / 640x512 mode
p96target_width	dc	320
p96target_height	dc	240
p96target_mode	dc	0	;0=320x240, 1=640x480, 2=480-line stretch, 3=240-line stretch
g2chipset_aga	dc	0	;0=OCS/ECS, -1=AGA
g2iconbase	dc.l	0
iconname	dc.b	'icon.library',0
	even
g2display_log_name	dc.b	'RAM:gloom_displaymode.txt',0
	even
g2display_msg_auto_default	dc.b	'DISPLAY probe: AGA (default)',10
g2display_msg_auto_default_len	equ	*-g2display_msg_auto_default
g2display_msg_auto_tool	dc.b	'DISPLAY probe: AUTO (ToolType)',10
g2display_msg_auto_tool_len	equ	*-g2display_msg_auto_tool
g2display_msg_auto_cli	dc.b	'DISPLAY probe: AUTO (CLI)',10
g2display_msg_auto_cli_len	equ	*-g2display_msg_auto_cli
g2display_msg_aga_tool	dc.b	'DISPLAY probe: AGA (ToolType)',10
g2display_msg_aga_tool_len	equ	*-g2display_msg_aga_tool
g2display_msg_aga_cli	dc.b	'DISPLAY probe: AGA (CLI)',10
g2display_msg_aga_cli_len	equ	*-g2display_msg_aga_cli
g2display_msg_p96_tool	dc.b	'DISPLAY probe: P96 (ToolType)',10
g2display_msg_p96_tool_len	equ	*-g2display_msg_p96_tool
g2display_msg_p96_cli	dc.b	'DISPLAY probe: P96 (CLI)',10
g2display_msg_p96_cli_len	equ	*-g2display_msg_p96_cli
	even

; v190p96a: passive P96 probe state.  This first step only opens the
; Picasso96 API library if present.  No P96 screen/window/output path is
; enabled here; the AGA/OS render path below stays untouched.
p96name	dc.b	'Picasso96API.library',0
	even
p96name2	dc.b	'p96api.library',0
	even
p96base	dc.l	0
p96present	dc	0
p96found	dc	0	;v190p96a2: 0=none, 1=Picasso96API.library, 2=p96api.library

; Active Picasso96 ModeID/tag constants used by mode discovery and validation.
TAG_DONE	equ	0
TAG_USER	equ	$80000000
P96BIDTAG_Dummy	equ	TAG_USER+96
P96BIDTAG_NominalWidth	equ	P96BIDTAG_Dummy+$0003
P96BIDTAG_NominalHeight	equ	P96BIDTAG_Dummy+$0004
P96BIDTAG_Depth	equ	P96BIDTAG_Dummy+$0005
P96_INVALID_ID	equ	$FFFFFFFF
P96IDA_WIDTH	equ	0
P96IDA_HEIGHT	equ	1
P96IDA_RGBFORMAT	equ	5
RGBFB_CLUT	equ	1	;c87b78h official Picasso96 indexed 8-bit format
RGBFF_CLUT	equ	2	;c87b78j 1<<RGBFB_CLUT, native indexed P96 mode flag
RGBFB_R5G6B5PC	equ	4
RGBFB_R5G6B5	equ	10

p96modeid	dc.l	0
p96modeid_depth	dc	0
p96modeid_state	dc	0	;0=not found, 1=found, 2=skip non-P96, 3=no P96 lib
p96modeid_rgbformat	dc.l	RGBFB_CLUT	;c87b79k native P96 mode contract default
p96modeid_log_name	dc.b	'RAM:gloom_p96_modeid.txt',0
	even
p96modeid_msg_found
	dc.b	'*** GLOOM REFORGED P96 MODE ID ***',10,10
	dc.b	'P96MODEID=$'
p96modeid_hex	ds.b	8
	dc.b	10,10
	dc.b	'Copy the complete P96MODEID line above into the',10
	dc.b	'program icon ToolTypes to skip both P96 requesters.',10,10
	dc.b	'SIZE=$'
p96modeid_width_hex	ds.b	4
	dc.b	'x$'
p96modeid_height_hex	ds.b	4
	dc.b	' DEPTH=$'
p96modeid_depth_hex	ds.b	4
	dc.b	10
p96modeid_msg_found_len	equ	*-p96modeid_msg_found
p96modeid_msg_notfound	dc.b	'P96 modeid: not found requested output',10
p96modeid_msg_notfound_len	equ	*-p96modeid_msg_notfound
p96modeid_msg_skip_aga	dc.b	'P96 modeid: skipped (DISPLAY is not P96)',10
p96modeid_msg_skip_aga_len	equ	*-p96modeid_msg_skip_aga
p96modeid_msg_skip_nolib	dc.b	'P96 modeid: skipped, no P96 library',10
p96modeid_msg_skip_nolib_len	equ	*-p96modeid_msg_skip_nolib
p96modeid_hexchars	dc.b	'0123456789ABCDEF'

; c86zdy: Intuition OpenScreenTagList probe for the live-found P96 ModeID.
; The screen is opened only as a diagnostic and immediately closed again.
; No window, no drawing and no renderer switch happen in this patch.
SA_Dummy	equ	TAG_USER+32
SA_Left	equ	SA_Dummy+1
SA_Top	equ	SA_Dummy+2
SA_Width	equ	SA_Dummy+3
SA_Height	equ	SA_Dummy+4
SA_Depth	equ	SA_Dummy+5
SA_Type	equ	SA_Dummy+13
SA_DisplayID	equ	SA_Dummy+18
SA_Title	equ	SA_Dummy+20
SA_ShowTitle	equ	SA_Dummy+22
SA_Quiet	equ	SA_Dummy+24
SA_AutoScroll	equ	SA_Dummy+25
SA_Draggable	equ	SA_Dummy+30

; c87b79g: Historical Workbench preview-window/log/state data removed.

; c86zdv: read DISPLAY= from Workbench ToolTypes first, then allow CLI to
; override it.  The selected value is stored for later P96 stages, but this
; probe only logs the decision and leaves the renderer on the existing AGA path.
	even			;c87b79y1: byte tables above may end odd after legacy cleanup
g2displaymode_probe
	push
	clr	g2display_source
	clr	g2p96_hires_mode
	clr	g2p96_stretch_mode
	clr	g2p96_wide_mode
	clr	g2p96_oneone_mode
	clr	g2p96_modeid_override_present
	clr	g2p96_modeid_override_valid
	clr	g2p96_modeid_override_used
	clr	g2p96_modeid_override_source
	clr.l	g2p96_modeid_override_value
	clr	g2fps_enabled	;c87a6: FPS is opt-in on every program start, never loaded from gloom.cfg
	clr	g2stock_enabled	;c87b64: STOCK disables Bayer + Reforged fog ramp
	move	#320,p96target_width
	move	#240,p96target_height
	clr	p96target_mode
	move	#3,g2display_mode	;hardware default: ECS
	tst	g2chipset_aga
	beq.s	g2display_probe_default_ready
	move	#1,g2display_mode	;hardware default: AGA
g2display_probe_default_ready
	jsr	g2displaymode_tooltype_probe
	move.l	g2display_cli_ptr,d0
	beq.s	g2display_probe_done
	move.l	d0,a0
	moveq	#2,d1	;CLI overrides ToolTypes
	jsr	g2display_tokens_scan
g2display_probe_done
	pull
	rts

; Workbench ToolType probe.  Uses icon.library only long enough to read the
; program icon's do_ToolTypes list, then closes it again.  If anything fails,
; the default AGA mode remains active unless DISPLAY=AUTO/P96/AGA is provided.
g2displaymode_tooltype_probe
	push
	move.l	wbmess,d0
	beq	.done
	move.l	4.w,a6
	lea	iconname(pc),a1
	jsr	-408(a6)	;OldOpenLibrary icon.library
	move.l	d0,g2iconbase
	beq	.done
	move.l	wbmess,a0
	move.l	$24(a0),d0	;WBStartup.sm_ArgList
	beq	.close
	move.l	d0,a0
	move.l	4(a0),d0	;first WBArg.wa_Name
	beq	.close
	move.l	d0,a0
	move.l	g2iconbase(pc),a6
	jsr	-78(a6)	;GetDiskObject(name)
	move.l	d0,d6
	beq	.close
	move.l	d6,a0
	move.l	54(a0),d0	;DiskObject.do_ToolTypes
	beq	.free
	move.l	d0,a2
.loop	move.l	(a2)+,d0
	beq	.free
	move.l	d0,a0
	bsr	g2tooltype_disabled	;c86zhz: ignore icon ToolTypes disabled as (DISPLAY=...)
	tst	d0
	bne	.loop
	move.l	-4(a2),a0
	moveq	#1,d1	;ToolType source
	jsr	g2display_tokens_scan
	bra	.loop
.free	move.l	d6,a0
	move.l	g2iconbase(pc),a6
	jsr	-90(a6)	;FreeDiskObject
.close	move.l	g2iconbase(pc),d0
	beq	.done
	move.l	d0,a1
	move.l	4.w,a6
	jsr	-414(a6)	;CloseLibrary
	clr.l	g2iconbase
.done	pull
	rts

; c86zhz: Workbench icon ToolTypes wrapped in parentheses are disabled by
; IconEdit/Workbench convention and must not affect DISPLAY/HIRES/STRETCH.
; Input: a0 points to a single ToolType string.  Output: d0=-1 disabled, 0 active.
; a0 is preserved so the normal scanners can still consume active ToolTypes.
g2tooltype_disabled
	move.l	a0,a1
.skip	move.b	(a1)+,d0
	beq.s	.active
	cmp.b	#' ',d0
	beq.s	.skip
	cmp.b	#9,d0
	beq.s	.skip
	cmp.b	#'(',d0
	beq.s	.disabled
.active	moveq	#0,d0
	rts
.disabled	moveq	#-1,d0
	rts

; in: a0 = zero/LF terminated text line, d1 = source id (1 ToolType, 2 CLI)
; out: d0 = 1 if DISPLAY= was found and accepted, 0 otherwise
g2displaymode_scan_line
	jmp	g2display_tokens_scan

g2display_upper_d0
	cmp.b	#'a',d0
	bcs	.rts
	cmp.b	#'z',d0
	bhi	.rts
	sub.b	#32,d0
.rts	rts

; Write one compact status line to RAM:gloom_displaymode.txt.  This is the
; only observable effect of c86zdv on systems where visible P96 output cannot
; be inspected because the display hardware switches back to AGA.
g2displaymode_log
	push
	move.l	dosbase(pc),d0
	beq	.done
	move.l	d0,a6
	lea	g2display_log_name(pc),a0
	move.l	a0,d1
	move.l	#1006,d2	;MODE_NEWFILE
	jsr	-30(a6)	;Open
	move.l	d0,d7
	beq	.done
	move	g2display_mode(pc),d0
	move	g2display_source(pc),d1
	cmp	#1,d0
	beq	.aga
	cmp	#2,d0
	beq	.p96
.auto	tst	d1
	beq	.auto_default
	cmp	#2,d1
	beq	.auto_cli
	lea	g2display_msg_auto_tool(pc),a0
	move.l	#g2display_msg_auto_tool_len,d3
	bra	.write
.auto_cli
	lea	g2display_msg_auto_cli(pc),a0
	move.l	#g2display_msg_auto_cli_len,d3
	bra	.write
.auto_default
	lea	g2display_msg_auto_default(pc),a0
	move.l	#g2display_msg_auto_default_len,d3
	bra	.write
.aga	tst	d1
	beq	.aga_default
	cmp	#2,d1
	beq	.aga_cli
	lea	g2display_msg_aga_tool(pc),a0
	move.l	#g2display_msg_aga_tool_len,d3
	bra	.write
.aga_default	lea	g2display_msg_auto_default(pc),a0	;c86zhl: label now contains AGA default text
	move.l	#g2display_msg_auto_default_len,d3
	bra	.write
.aga_cli
	lea	g2display_msg_aga_cli(pc),a0
	move.l	#g2display_msg_aga_cli_len,d3
	bra	.write
.p96	cmp	#2,d1
	beq	.p96_cli
	lea	g2display_msg_p96_tool(pc),a0
	move.l	#g2display_msg_p96_tool_len,d3
	bra	.write
.p96_cli
	lea	g2display_msg_p96_cli(pc),a0
	move.l	#g2display_msg_p96_cli_len,d3
.write	move.l	d7,d1
	move.l	a0,d2
	jsr	-48(a6)	;Write
	move.l	d7,d1
	jsr	-36(a6)	;Close
.done	pull
	rts

; ECS1: safe second-stage probe.  Only DISPLAY=P96 may open the P96 API.
; DISPLAY=AGA and DISPLAY=ECS leave the planar renderer completely untouched.
