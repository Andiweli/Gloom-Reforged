; Step 1: Bayer gates use the live switch (also forced OFF by STOCK).
predrawall	;draw up everything....
	;
	;status bar too...
	;
	jsr	clspic		;c87b16a: long-call buildfix
	jsr	clspic		;c87b16a: long-call buildfix
	bsr	calcoffset
	; v190gi: no lower statusbar background.
	; c87b70g: these late data labels exceed GenAm's signed 16-bit PC range.
	move.l	player1,a0
	st	ob_update(a0)
	tst	gametype
	beq.s	.skip
	move.l	player2,a0
	st	ob_update(a0)
.skip	bsr	drawall_
	bra	drawall_

drawall	;
	jsr	g2v36_hide_pointer	;v36: keep Intuition pointer hidden during gameplay
.wait	tst	doneflag
	bne.s	.waitskip
	jsr	vwait
	bra	.wait
.waitskip	clr	doneflag
	;
drawall_	; c87a6: FPS is measured only at the actual AGA/P96 present point
	tst	twowins		; c54/c86m: route 2P into split path, keep normal 1P untouched
	bne	g2twop_drawall_split
	move.l	player1,player_	; Patch10 GenAm fix: absolute source
	move.l	memory,memat	; Patch10 GenAm fix: absolute source
	; c87b37: select the correct chunky layout before rendering.  Planar AGA/ECS
	; full-width one-player frames use a linear 0..319 coloffs table for Kalm c5.
	; Smaller views and TWO PLAYER keep the proven BlackMagic layout.  P96 then
	; applies its own established linear-layout manager below.
	jsr	g2kalms_prepare_frame_layout
	; c86zjd: once the direct P96 bitmap has accepted one legacy-layout frame,
	; render subsequent one-player gameplay frames in true linear x order.
	jsr	g2p96_gameplay_prepare_linear_frame
	; c87b69: RESOLUTION affects only the 3D world. Geometry is restored before
	; blitscene so weapon, HUD, menus and the final C2P remain native 320px.
	jsr	g2quality_prepare_frame	;c87b69: saved 1x1/2x1/1x2/2x2 world raster
	jsr	calcscene
	jsr	drawscene
	jsr	g2quality_expand_restore	;c87b61: restore native 320x240 before overlays
	jsr	blitscene
	;
g2drawall_show
.wait2	tst	showflag
	bne.s	.waitskip2
	jsr	vwait
	bra	.wait2
.waitskip2	; c87a6: measure only the real presented-frame interval below
	; c87b78b: native P96 gameplay owner/presenter. A successful P96 copy skips
	; the planar doc2p/db present. The non-P96 and explicit failure rollback paths
	; remain unchanged; no removed legacy ToolType is consulted here.
	jsr	g2rc4_p96_present_dispatch_v21	;RC4: optional every-second-frame P96 publish
	tst	p96gameplay_skip_aga_present
	beq	.g2c86zfa_do_aga_present
	jsr	g2twop_restore_after_c2p
	clr	showflag
	rts
.g2c86zfa_do_aga_present
	jsr	g2fps_update_present	;c87a7: count actual AGA presents in one-second window
	jsr	g2fps_draw_chunky	;c87a6: current two-digit white 5x7 FPS before AGA C2P
	jsr	doc2p
	jsr	db
	jsr	g2twop_restore_after_c2p	;c54/c86m: restore user view globals after split C2P
	clr	showflag
	rts

; c86m: restored real TWO PLAYER entry label.  c86l accidentally inlined this
; block into the one-player path and left the branch targets undefined.
g2twop_drawall_split
	; c87b79c: resolve the real split source width before choosing linear
	; ownership. P96 WIDE uses a native 428-byte source row; every other owner
	; retains the confirmed 320-byte split frame.
	jsr	g2twop_prepare_view_width
	jsr	g2kalms_prepare_twoplayer_frame_layout
	move.l	chunky(pc),d0
	beq	g2drawall_show
	move.l	d0,g2twop_saved_chunky
	move	width,g2twop_saved_width	;c87b70-bench2-fix3: absolute source, GenAm PC range >32 KiB
	move	hite,g2twop_saved_hite	;c87b70-bench2-fix3: absolute source, GenAm PC range >32 KiB
	move	chunkymodw(pc),g2twop_saved_chunkymodw
	move	minx,g2twop_saved_minx	;c87b70-bench2-wallspans-fix1: GenAm PC range
	move	maxx,g2twop_saved_maxx	;c87b70-bench2-wallspans-fix1: GenAm PC range
	move	miny,g2twop_saved_miny	;c87b70-bench2-wallspans-fix1: GenAm PC range
	move	maxy,g2twop_saved_maxy	; Patch10 GenAm fix: absolute source
	move.l	offset(pc),g2twop_saved_offset
	;
	; c87b79c: RESOLUTION temporarily reduces only the internal 3D raster
	; per half; expansion finishes before each native-width split HUD pass.
	jsr	g2clearfullchunky	;clear both split halves from the real full-frame base
	jsr	g2twop_center_coloffs	;centre selected 2P view inside each native split half
	jsr	g2twop_set_half_view
	;
	; c86o: TWO PLAYER does not call blitscene, so the old v103 teleport
	; blackout hook there never ran for split-screen.  If a level-exit
	; teleport starts the black hold, flush the complete native split frame to
	; black before C2P and skip drawing HUD/second player.  This prevents the
	; short stale gameplay-frame flash before the intermission picture.
	tst	g2teleport_blackout
	bne	.g2twop_blackout_full
	move.l	g2twop_saved_chunky(pc),chunky	;player 1 top half
	move.l	player1(pc),d0
	beq.w	.g2twop_restore_full
	move.l	d0,player_
	move.l	memory(pc),memat
	jsr	g2twop_quality_prepare_half	;c87b69: saved RESOLUTION for split half
	jsr	calcscene
	jsr	drawscene
	tst	g2teleport_blackout
	beq.s	.g2c87b62_p1_expand
	jsr	g2twop_quality_abort_half
	bra.w	.g2twop_blackout_full
.g2c87b62_p1_expand
	jsr	g2twop_quality_expand_half
	jsr	g2twop_draw_half_hud	;c86m: HUD anchored to split edges, not render crop
	;
	move.l	player2(pc),d0	;player 2 bottom half
	beq.s	.g2twop_restore_full
	move.l	d0,player_
	move.l	g2twop_saved_chunky(pc),d0
	moveq	#0,d1
	move	g2twop_half_height,d1	;c87p3: 120 normal, true 128 in active P96 5:4
	mulu	g2twop_view_width,d1	;c87b79c: 320 standard/5:4, native 428 WIDE
	add.l	d1,d0
	move.l	d0,chunky
	move.l	memory(pc),memat
	jsr	g2twop_quality_prepare_half	;c87b69: same saved RESOLUTION for player 2
	jsr	calcscene
	jsr	drawscene
	tst	g2teleport_blackout
	beq.s	.g2c87b62_p2_expand
	jsr	g2twop_quality_abort_half
	bra.w	.g2twop_blackout_full
.g2c87b62_p2_expand
	jsr	g2twop_quality_expand_half
	jsr	g2twop_draw_half_hud	;c86m: HUD anchored to split edges, not render crop
.g2twop_restore_full
	clr.w	g2twop_quality_mode	;c87b62: no compact half state may reach C2P
	clr	g2twop_crop_mode
	jsr	g2twop_restore_coloffs	;restore full-width linear table before final presentation
	jsr	g2twop_set_full_c2p_view
	bra	g2drawall_show
.g2twop_blackout_full
	move.l	g2twop_saved_chunky(pc),chunky
	clr.w	g2twop_quality_mode	;c87b62: abort compact state on teleport blackout
	clr	g2twop_crop_mode
	jsr	g2twop_restore_coloffs
	jsr	g2twop_set_full_c2p_view
	jsr	g2clearfullchunky
	bra	g2drawall_show

; c86l: draw the existing top HUD directly into the currently selected split
; half, but with full-width coloffs so HEALTH/WEAPON and LIVES sit at the
; physical split-screen edges like ONE PLAYER, independent of the 3D crop.
g2twop_draw_half_hud
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	player_(pc),a5
	tst.l	a5
	beq.s	.done
	jsr	g2twop_restore_coloffs
	move	#-1,g2hud_force_draw
	jsr	showstats
	clr	g2hud_force_draw
	clr	g2hud_pending	;c55: no late full-screen HUD pass after split C2P
	jsr	g2twop_center_coloffs
.done	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2twop_prepare_view_width
	; c87b79c: WIDE TWO PLAYER renders a genuine 428-column source page.
	; The 854-pixel output is derived from that source only at presentation.
	move	#320,d0
	cmp	#2,g2display_mode
	bne.s	.geometry
	tst	p96gameplay_persist_active
	beq.s	.geometry
	tst	g2p96_wide_mode
	beq.s	.geometry
	move	p96target_width,d1
	cmp	#428,d1
	beq.s	.wide
	cmp	#854,d1
	bne.s	.geometry
.wide	move	#428,d0
.geometry
	move	d0,g2twop_view_width
	move	d0,g2render_width
	move	d0,g2render_stride
	move	d0,width
	move	d0,chunkymodw
	move	d0,d1
	lsr	#1,d1
	move	d1,g2render_center_x
	move	d1,maxx
	neg	d1
	move	d1,minx
	move	d0,d1
	subq	#1,d1
	move	d1,g2render_last_x
	rts

g2twop_set_half_view
	move	g2twop_view_width(pc),d0
	move	d0,width
	move	#120,d1
	; c87p3: once the P96 5:4 screen owns gameplay, each split half is a
	; genuine 320x128 view. WIDE remains 428x120 per half.
	tst	g2p96_oneone_mode
	beq.s	.g2c87p3_half_height_ready
	tst	p96gameplay_persist_active
	beq.s	.g2c87p3_half_height_ready
	move	#128,d1
.g2c87p3_half_height_ready
	move	d1,hite
	move	d1,g2twop_half_height
	move	g2twop_view_width(pc),chunkymodw
	move	g2twop_view_width(pc),g2render_width
	move	g2twop_view_width(pc),g2render_stride
	move	g2twop_view_width(pc),d0
	lsr	#1,d0
	move	d0,g2render_center_x
	move	d0,maxx
	neg	d0
	move	d0,minx
	move	g2twop_view_width(pc),d0
	subq	#1,d0
	move	d0,g2render_last_x
	move	d1,d2
	lsr	#1,d2
	neg	d2
	move	d2,miny
	neg	d2
	move	d2,maxy
	clr.l	offset
	move	#-1,g2twop_crop_mode
	rts

; Map the full split view to its physical half-frame. The helper
; remains shared with HUD/menu restoration, while RESOLUTION owns scaling.
g2twop_center_coloffs
	movem.l	d0-d2/a0-a1,-(a7)
	lea	coloffs,a0
	lea	coloffs,a1
	move	g2twop_view_width(pc),d0
	move	g2render_width(pc),d1
	sub	d0,d1
	lsr	#1,d1
	lsl	#2,d1
	ext.l	d1
	add.l	d1,a1
	subq	#1,d0
	bmi.s	.done
.loop	move.l	(a1)+,(a0)+
	dbf	d0,.loop
.done	movem.l	(a7)+,d0-d2/a0-a1
	rts

; c87b40/c87b79c: rebuild the full-width x table before final presentation, each
; full-width split HUD draw and the in-game menu frame. Under linear ownership
; it is 0..319 or 0..427; under legacy planar ownership it retains the
; original BlackMagic permutation.  paladjust remains the established identity
; table in the linear path and is rebuilt by g2_inline_c2p_init in legacy mode.
g2twop_restore_coloffs
	movem.l	d0-d2/a0-a1,-(a7)
	tst.w	g2kalms_linear_active
	beq.s	.legacy
	lea	coloffs,a0
	moveq	#0,d0
	move	g2twop_view_width(pc),d1
	subq	#1,d1
.linear_loop
	move.l	d0,(a0)+
	addq.l	#1,d0
	dbf	d1,.linear_loop
	bra.s	.done
.legacy
	lea	coloffs,a0
	move	#320,d0
	lea	paladjust,a1
	jsr	g2_inline_c2p_init
.done
	movem.l	(a7)+,d0-d2/a0-a1
	rts

g2twop_set_full_c2p_view
	move.l	g2twop_saved_chunky(pc),chunky
	clr	g2twop_crop_mode
	move	g2twop_view_width(pc),d0
	move	d0,width
	move	d0,chunkymodw
	move	d0,g2render_width
	move	d0,g2render_stride
	move	d0,d1
	lsr	#1,d1
	move	d1,g2render_center_x
	move	d1,maxx
	neg	d1
	move	d1,minx
	move	d0,d1
	subq	#1,d1
	move	d1,g2render_last_x
	move	g2twop_half_height,d0	;c87b79d: absolute reference, GenAm PC range fix
	add	d0,d0
	move	d0,hite
	lsr	#1,d0
	move	d0,maxy
	neg	d0
	move	d0,miny
	clr.l	offset
	move	#-1,g2twop_restore_pending
	rts

g2twop_restore_after_c2p
	tst	g2twop_restore_pending
	beq.s	.done
	clr	g2twop_restore_pending
	clr	g2twop_crop_mode
	move.l	g2twop_saved_chunky(pc),chunky
	move	g2twop_saved_width(pc),width
	move	g2twop_saved_hite(pc),hite
	move	g2twop_saved_chunkymodw(pc),chunkymodw
	move	g2twop_saved_minx(pc),minx
	move	g2twop_saved_maxx(pc),maxx
	move	g2twop_saved_miny(pc),miny
	move	g2twop_saved_maxy(pc),maxy
	move.l	g2twop_saved_offset(pc),offset
.done	rts

; c86n: C2P helper for the native TWO PLAYER in-game menu fallback.
; The chunky frame already contains both split halves. Convert it as one
; full native frame, then restore the saved gameplay geometry.
g2twop_menu_full_c2p
	movem.l	d0-d7/a0-a6,-(a7)
	; c87b79p: this helper is a native AGA/ECS fallback only. P96 menus use
	; their direct indexed split-frame presenter and must never enter C2P.
	cmp	#2,g2display_mode
	beq.w	.g2c87b79p_done
	move.l	chunky,g2menu_saved_chunky
	move	width,g2menu_saved_width
	move	hite,g2menu_saved_hite
	move	chunkymodw,g2menu_saved_chunkymodw
	move	minx,g2menu_saved_minx
	move	maxx,g2menu_saved_maxx
	move	miny,g2menu_saved_miny
	move	maxy,g2menu_saved_maxy
	move.l	offset,g2menu_saved_offset
	move.l	g2twop_saved_chunky,d0
	beq.s	.have_chunky
	move.l	d0,chunky
.have_chunky
	clr	g2twop_crop_mode
	move	#320,width
	move	#240,hite
	move	#320,chunkymodw
	move	#-160,minx
	move	#160,maxx
	move	#-120,miny
	move	#120,maxy
	clr.l	offset
	jsr	doc2p
	jsr	db
	move.l	g2menu_saved_chunky,chunky
	move	g2menu_saved_width,width
	move	g2menu_saved_hite,hite
	move	g2menu_saved_chunkymodw,chunkymodw
	move	g2menu_saved_minx,minx
	move	g2menu_saved_maxx,maxx
	move	g2menu_saved_miny,miny
	move	g2menu_saved_maxy,maxy
	move.l	g2menu_saved_offset,offset
.g2c87b79p_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

doc2p	;
	; c87b79p: hard central P96 gate. Even an obsolete caller cannot invoke the
	; external/built-in planar converter after DISPLAY=P96 was selected.
	cmp	#2,g2display_mode
	beq.w	.rts
	move.l	chunky(pc),a0		;src
	move.l	drawbitmap(pc),a1	;dest
	add.l	offset(pc),a1
	move	width(pc),d0
	move	hite(pc),d1
	move.l	bpmod(pc),d2		;bpmod
	move.l	linemod(pc),d3		;linemod
	move.l	c2p(pc),a2
	jsr	(a2)
	jsr	g2hud_post_c2p	;v190hx6: fixed top HUD pass for non-fullscreen views
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

; v190hx6: for smaller VIEW SIZE modes the main C2P pass only converts the
; centred game window.  Keep the HUD at its fixed 320x240 screen position by
; drawing it after the main C2P and converting only the top strip full-width.
g2hud_post_c2p
	tst	g2hud_pending
	beq.s	.done
	clr	g2hud_pending
	movem.l	d0-d7/a0-a6,-(a7)
	; v190hx9: the fixed HUD pass for smaller VIEW SIZE modes must not
	; permanently overwrite the chunky source buffer.  The grey ESC-menu
	; preview later uses chunky as the 3D-source image; if the HUD remains
	; there, it appears again inside the small render window, distorted.
	jsr	g2hud_save_top_chunky
	jsr	g2hud_clear_top_chunky
	move.l	g2hud_pending_player(pc),a5
	tst.l	a5
	beq.s	.skipdraw
	move	#-1,g2hud_force_draw
	jsr	showstats
	clr	g2hud_force_draw
.skipdraw
	move.l	chunky(pc),a0
	move.l	drawbitmap(pc),a1
	move	#320,d0
	move	#32,d1
	move.l	bpmod(pc),d2
	move.l	linemod(pc),d3
	move.l	c2p(pc),a2
	jsr	(a2)
	jsr	g2hud_restore_top_chunky
	movem.l	(a7)+,d0-d7/a0-a6
.done	rts

; Save/restore only the fixed top HUD strip in the chunky source buffer.
g2hud_save_top_chunky
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	chunky(pc),a0
	lea	g2hud_saved_top_chunky,a1
	moveq	#0,d0
	move	g2render_stride(pc),d0
	mulu	#32,d0
	lsr.l	#2,d0
	subq.l	#1,d0
.loop	move.l	(a0)+,(a1)+
	dbf	d0,.loop
	movem.l	(a7)+,d0-d1/a0-a1
	rts

g2hud_restore_top_chunky
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	chunky(pc),a0
	lea	g2hud_saved_top_chunky,a1
	moveq	#0,d0
	move	g2render_stride(pc),d0
	mulu	#32,d0
	lsr.l	#2,d0
	subq.l	#1,d0
.loop	move.l	(a1)+,(a0)+
	dbf	d0,.loop
	movem.l	(a7)+,d0-d1/a0-a1
	rts

; Clear only the fixed top HUD strip; Clear only the fixed top HUD strip in the chunky source buffer.
g2hud_clear_top_chunky
	movem.l	d0-d1/a0,-(a7)
	move.l	chunky(pc),a0
	moveq	#0,d0
	move	g2render_stride(pc),d0
	mulu	#32,d0
	lsr.l	#2,d0
	subq.l	#1,d0
.loop	clr.l	(a0)+
	dbf	d0,.loop
	movem.l	(a7)+,d0-d1/a0
	rts


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
	move	#127,ob_messtimer(a5)	;c87b75a: brief top-centre message lifetime
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
.here
	; c87b79x: DISPLAY=P96 owns no planar showbitmap. Intermission glyphs are
	; composed directly into the authoritative index page/stage by the proven
	; typewriter hook. Menus normally use their direct Bigfont caches; if a
	; catastrophic cache probe ever reaches printmess2, skipping the glyph is
	; safer than dereferencing a null planar page.
	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_print_planar
	jsr	g2p96_intermission_typewriter_char_if_active
	bra.s	.g2c87b79x_print_done
.g2c87b79x_print_planar
	; c87b12: g2ecs7_prepare_exact_font_overlay has already reserved palette
	; indices 1..3 and installed the original Bigfont yellow shades.  Draw the
	; real planar glyph with the hardware blitter instead of writing every glyph
	; pixel through six CPU bitplanes.  No recolour pass is needed, so the former
	; white corner pixels cannot occur.
	tst	aga
	bne.s	.g2c87b12_print_normal
	tst	g2ecs7_direct_font_active
	beq.s	.g2c87b12_print_normal
	move.l	font(pc),a0
	move.l	showbitmap(pc),a1
	move	d7,d0
	move	d6,d1
	bsr	blit
	bra.s	.g2c87b12_print_done
.g2c87b12_print_normal
	move.l	font(pc),a0
	move.l	showbitmap(pc),a1
	move	d7,d0
	move	d6,d1
	bsr	blit
	; Retain the established native isolated recolour path.
	jsr	g2inter_recolour_last_glyph_yellow
.g2c87b12_print_done
	; c86zhg: publish each freshly blitted intermission character during the
	; normal typewriter cadence. Native AGA/ECS calls return immediately.
	jsr	g2p96_intermission_typewriter_char_if_active
.g2c87b79x_print_done
	;
	move	pdelay(pc),d2
	subq	#1,d2
	bmi.s	.spc
	;
.pdloop	jsr	vwait
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
	; v190hx6: in FULLSCREEN draw directly into the main chunky/C2P frame.
	; For smaller VIEW SIZE modes defer the HUD until after the main C2P pass,
	; then convert a fixed full-width top strip so the HUD stays in place.
	movem.l	d0-d7/a0-a4,-(a7)
	move.l	panel(pc),d0
	beq.w	.g2hud_done
	tst	g2hud_force_draw
	bne.s	.g2hud_draw_now
	move	width(pc),d0
	cmp	g2render_width(pc),d0
	bne.s	.g2hud_defer
	cmp	#240,hite
	beq.s	.g2hud_draw_now
	tst	g2p96_oneone_mode
	beq.s	.g2hud_defer
	cmp	#256,hite
	bne.s	.g2hud_defer
	bra.s	.g2hud_draw_now
.g2hud_defer
	move.l	a5,g2hud_pending_player
	move	#-1,g2hud_pending
	bra.w	.g2hud_done
.g2hud_draw_now
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
	move	g2render_width(pc),d7
	sub	#84,d7
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
	move	g2render_width(pc),d6
	sub	#48,d6		; c87b72a: 4px nearer to LIVES
.g2hud_lives_loop
	move	d6,d0
	moveq	#4,d1		;v190hm: HUD 2px lower
	jsr	g2c87b71a_draw_heart_top	; original-Gloom-style 7x7 life heart
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
	jmp	g2c87b75a_finish_hud_and_message	; six-byte tail hook

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
	cmp	g2render_last_x(pc),d0
	bgt.w	.g2hds_done
	cmp	#0,d1
	blt.w	.g2hds_done
	cmp	hite,d1
	bge.w	.g2hds_done
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
	cmp	g2render_width(pc),d6
	bgt.w	.g2hds_done
	move	d1,d6
	add	d3,d6
	cmp	hite,d6
	bgt.w	.g2hds_done
	subq	#1,d2
	subq	#1,d3
	move.l	chunky(pc),a1
	mulu	g2render_stride(pc),d1
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
	adda.w	g2render_stride(pc),a3
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

; c86zc1: experimental full weak wall reflection.
; This starts over from the good c86zb3 enemy-reflection anchor instead of
; reusing the problematic wall-depth test branch.  Each solid rendered wall
; column is mirrored below its own visible foot.  The reflection is deliberately
; very weak: roughly 20 percent of the source pixels survive through ordered
; dither, fading further with depth and down the mirrored tail.  Source pixels
; stay palette-correct because they are sampled from the already rendered
; chunky wall column; no new colour mapping is attempted here.
g2_draw_wall_reflection_lite
	movem.l	d0-d7/a0-a6,-(a7)
	; c87b38: wall reflections are part of REFLECTIONS ALL only.
	; Internal values: -1=NO, 2=WEAPON, 1=ALL (historic YES compatibility).
	cmp	#1,g2_reflections
	bne.w	.done
	move.l	chunky(pc),a2
	tst.l	a2
	beq.w	.done
	; c86zcw: do not require FLOOR YES here. When FLOOR is hidden,
	; drawscene has already filled the lower half with neutral disabled-floor
	; fog, so wall reflections can safely sit on that surface.
	move.l	vertdraws(pc),a0
	lea	coloffs(pc),a1
	move	width(pc),d7
	beq.w	.done
	subq	#1,d7
	clr	d4		; screen-X Bayer phase, kept modulo four
.col_loop
	tst.l	vd_data(a0)
	beq	.col_next
	move	vd_y(a0),d0
	add	midy(pc),d0		; visible wall top on screen
	move	vd_h(a0),d1
	ble	.col_next
	add	d0,d1
	subq	#1,d1		; visible wall foot / last source row
	cmp	midy(pc),d1
	blt	.col_next		; only walls reaching the floor half

	; c87b69i: strict ZGloom mirror anchors. The destination always starts
	; immediately below the real wall foot. No upward relocation is allowed.
	move	hite(pc),d2
	subq	#1,d2		; last valid chunky row
	cmp	d2,d1
	bge	.col_next		; no destination row below the wall foot

	; Reflections exist only inside the established four-texture-width near field.
	move	vd_z(a0),d5
	bpl.s	.g2c87b69i_z_ok
	moveq	#0,d5
.g2c87b69i_z_ok
	cmp	#(4<<grdshft),d5
	bcc	.col_next

	; Visible source segment after top clipping.
	move	d0,d5
	bpl.s	.g2c87b69i_top_ok
	moveq	#0,d5
.g2c87b69i_top_ok
	move	d1,d2
	sub	d5,d2
	addq	#1,d2		; visible source rows, including wall foot
	tst	d2
	ble	.col_next

	; ZGloom uses about 45 percent of the visible wall height. Keep the Amiga
	; pass conservative but clearly longer than c87b69h: 4..48 desired rows.
	moveq	#0,d6
	move	d2,d6
	mulu	#45,d6
	divu	#100,d6
	and.l	#$0000ffff,d6
	cmp	#4,d6
	bcc.s	.g2c87b69i_min_ok
	moveq	#4,d6
.g2c87b69i_min_ok
	cmp	#48,d6
	bls.s	.g2c87b69i_max_ok
	moveq	#48,d6
.g2c87b69i_max_ok
	cmp	d2,d6
	ble.s	.g2c87b69i_source_ok
	move	d2,d6		; never sample above the visible wall top
.g2c87b69i_source_ok

	; Available destination rows below the real wall foot.
	move	hite(pc),d5
	subq	#1,d5
	sub	d1,d5
	tst	d5
	ble	.col_next

	; c87b71a: output is clipped only by the physical rows below the wall foot.
	; Never compress a longer source tail into fewer bottom rows: neighbouring
	; near columns otherwise use different vertical scales and visibly bow up.
	move	d6,d3
	cmp	d5,d3
	ble.s	.g2c87b69i_out_ok
	move	d5,d3
.g2c87b69i_out_ok
	tst	d3
	ble	.col_next

	; Build source-foot and destination-start pointers before d1 is reused.
	move.l	(a1),d5		; chunky X offset for this screen column
	move	d1,d2
	mulu	chunkymodw(pc),d2
	move.l	a2,a6
	add.l	d5,a6
	add.l	d2,a6		; a6 = source at real wall foot
	move	d1,d2
	addq	#1,d2
	mulu	chunkymodw(pc),d2
	move.l	a2,a4
	add.l	d5,a4
	add.l	d2,a4		; a4 = first destination row below wall foot

	; c87b71a: fixed 8.8 step of exactly 1.0 source row per destination row.
	; The former proportional step block remains unreachable below solely to
	; preserve the mature assembled layout around this renderer.
	move.l	#$00000100,a5	; exact 1.0 source row in 8.8 fixed point
	bra.s	.g2c87b69i_step_ready
	move.l	d0,a5
	bra.s	.g2c87b69i_step_ready
.g2c87b69i_step_calc
	moveq	#0,d0
	move	d6,d0
	subq	#1,d0
	lsl.l	#8,d0
	move	d3,d1
	subq	#1,d1
	divu	d1,d0
	and.l	#$0000ffff,d0
	move.l	d0,a5		; source step in 8.8 fixed point
.g2c87b69i_step_ready
	move	d6,d2		; c87b72a: uncut desired tail for stable fade
	move	d3,d6
	subq	#1,d6		; DBF destination-row count
	moveq	#0,d5		; destination/reflection/source row index

.row_loop
	; c87b72a: normalize against the full desired reflection tail, never the
	; bottom-clipped output count. Off-screen continuation therefore keeps the
	; same fade slope in every neighbouring column while the player turns.
	move	d5,d0
	mulu	#7,d0
	divu	d2,d0		; c87b72a: full desired length, not clipped rows
	and.l	#$0000ffff,d0
	moveq	#8,d1
	sub	d0,d1
	move	vd_z(a0),d0
	bpl.s	.g2c87b69i_fade_z_ok
	moveq	#0,d0
.g2c87b69i_fade_z_ok
	lsr	#7,d0		; 0..7 over the 0..4-width reflection range
	cmp	#7,d0
	bls.s	.g2c87b69i_fade_cap_ok
	moveq	#7,d0
.g2c87b69i_fade_cap_ok
	sub	d0,d1
	tst	d1
	ble.s	.skip_px

	; STOCK normally locks reflections off. Retain the historic safety bypass
	; so a forced internal STOCK/reflection combination still avoids Bayer work.
	tst	g2_bayer_disabled
	bne.s	.g2stock_wall_reflect_draw
	; Compare the threshold directly with the 4x4 Bayer sample.
	move	d5,d0
	and	#3,d0
	lsl	#2,d0
	add	d4,d0
	lea	g2_enemy_ref_bayer4(pc),a3
	cmp.b	0(a3,d0.w),d1
	bls.s	.skip_px
.g2stock_wall_reflect_draw
	; Sample the matching mirrored source row. c87b71a always advances exactly
	; one source row, so vertical wall detail stays straight down to the clip.
	move	d5,d0		; c87b72a: fixed one-to-one mirrored source row
	mulu	chunkymodw(pc),d0
	move.l	a6,a3
	sub.l	d0,a3
	moveq	#0,d0
	move.b	(a3),d0
	beq.s	.skip_px
	move.b	d0,(a4)
.skip_px
	add.l	chunkymod(pc),a4
	nop			; c87b72a: old 8.8 accumulator no longer required
	nop			; retain the mature renderer layout
	addq	#1,d5
	dbf	d6,.row_loop
.col_next
	addq	#1,d4
	and	#3,d4
	lea	vd_size(a0),a0
	addq.l	#4,a1
	dbf	d7,.col_loop
.done
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
	mulu	chunkymodw,d0
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
g2flat_tail_count	dc	0	;c87b69 P96 WIDE FLAT4 remainder 0..3

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
	mulu	chunkymodw,d0
	add.l	chunky(pc),d0
	move.l	d0,a2
	lea	coloffs,a1
.vloop	;
	;find Z on this scanline...
	;
	tst	d7
	beq	.rts
	move	d7,d6		; v190hx7: display Y -> full-screen projection Y
	jsr	g2view_unscale_y_d6
	tst	d6
	beq	.rts
	move.l	flatcam(pc),d0
	divs	d6,d0	;d0.w = Z
	move	d0,d6
	tst	g2_visibility
	bgt.s	.g2v190ey_flat_adv
	cmp	#maxz,d6
	bcc	.rts
	move	d6,d5
	; c87b69 STOCK: use the exact original Gloom distance index. The Reforged
	; DEFAULT 4..6 -> 4..8 shade remap below is not part of STOCK.
	tst	g2stock_enabled
	bne.w	.g2v190dw_flat_shade
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
	; c87b63 STOCK: keep the current discrete shade and skip all Bayer
	; look-ahead/table setup for this scanline.
	tst	g2_bayer_disabled
	bne.w	.g2v190ej_flatblend_done
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
	; c86n: match floor/ceiling projection to the wall crop window in
	; TWO PLAYER.  c86m cast walls through minx/maxx but flats still
	; used -160..160 full-FOV, so the flats slid/swum against the walls.
	tst	g2twop_crop_mode
	bne.s	.g2c87w1_flat_active_edges
	tst	g2p96_wide_mode
	beq.s	.g2twop_flat_full_edges
	tst	p96gameplay_linear_active
	beq.s	.g2twop_flat_full_edges
	; c87b69e: compact WIDE rows still cover the complete native field of view.
	; Use the saved 428-wide edges, while width remains the compact sample count.
	tst.w	g2resolution_active
	beq.s	.g2c87w1_flat_active_edges
	move	g2resolution_saved_minx,d5
	move	g2resolution_saved_maxx,d4
	bra.s	.g2twop_flat_have_edges
.g2c87w1_flat_active_edges
	move	minx(pc),d5
	move	maxx(pc),d4
	bra.s	.g2twop_flat_have_edges
.g2twop_flat_full_edges
	move	#-160,d5	; standard full-FOV flat left edge
	move	#160,d4	; standard full-FOV flat right edge
.g2twop_flat_have_edges
	muls	d6,d5
	asr.l	#focshft,d5
	;
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
	; Step 2a: only the actual STOCK profile selects the legacy flat loop.
	; The live Bayer switch controls g2_bayer_thresh above (zero when OFF).
	; Keep the normal resolution/span path for both Bayer YES and NO.
	tst	g2stock_enabled
	bne.w	.g2stock_flat_draw_setup
	move	d7,g2_bayer_ybase
	lea	g2v190ej_bayer_xrows,a6
	move	d7,d2
	and	#3,d2
	lsl	#8,d2
	add	d2,d2
	adda.w	d2,a6
	move.l	g2_bayer_nextpal,a1
	move.l	d7,-(a7)
	moveq	#127,d7
	moveq	#0,d2
	moveq	#0,d3
	;
	tst.w	g2kalms_linear_active
	bne.s	.g2c87b69_flat4_bayer_setup
	tst.w	p96gameplay_linear_active
	beq.w	.g2c87b69_flat_bayer_indexed
.g2c87b69_flat4_bayer_setup
	move.l	a2,a3
	; Patch 2 fast path. d5=-1 means the complete row was handled.
	; d5=0 restores the exact reference FLAT4 setup below.
	jsr	g2p2_try_span_bayer
	tst	d5
	bne.w	.hhh
	move	width(pc),d5
	move	d5,d3
	and	#3,d3
	move	d3,g2flat_tail_count
	moveq	#0,d3
	lsr	#2,d5
	beq.w	.g2c87b69_flat4_bayer_tail
	subq	#1,d5
.g2c87b69_flat4_bayer_loop
	; Pixel A
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_bayer_skip_a
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2c87b69_flat4_bayer_base_a
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2c87b69_flat4_bayer_base_a
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	.g2c87b69_flat4_bayer_advance_a
.g2c87b69_flat4_bayer_base_a
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
.g2c87b69_flat4_bayer_advance_a
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	bra.s	.g2c87b69_flat4_bayer_pixel_b
.g2c87b69_flat4_bayer_skip_a
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	lea	1(a6),a6
.g2c87b69_flat4_bayer_pixel_b
	; Pixel B
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_bayer_skip_b
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2c87b69_flat4_bayer_base_b
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2c87b69_flat4_bayer_base_b
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	.g2c87b69_flat4_bayer_advance_b
.g2c87b69_flat4_bayer_base_b
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
.g2c87b69_flat4_bayer_advance_b
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	bra.s	.g2c87b69_flat4_bayer_pixel_c
.g2c87b69_flat4_bayer_skip_b
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	lea	1(a6),a6
.g2c87b69_flat4_bayer_pixel_c
	; Pixel C
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_bayer_skip_c
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2c87b69_flat4_bayer_base_c
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2c87b69_flat4_bayer_base_c
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	.g2c87b69_flat4_bayer_advance_c
.g2c87b69_flat4_bayer_base_c
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
.g2c87b69_flat4_bayer_advance_c
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	bra.s	.g2c87b69_flat4_bayer_pixel_d
.g2c87b69_flat4_bayer_skip_c
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	lea	1(a6),a6
.g2c87b69_flat4_bayer_pixel_d
	; Pixel D
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_bayer_skip_d
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2c87b69_flat4_bayer_base_d
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2c87b69_flat4_bayer_base_d
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	.g2c87b69_flat4_bayer_advance_d
.g2c87b69_flat4_bayer_base_d
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
.g2c87b69_flat4_bayer_advance_d
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,.g2c87b69_flat4_bayer_loop
	bra.s	.g2c87b69_flat4_bayer_tail
.g2c87b69_flat4_bayer_skip_d
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	lea	1(a6),a6
	dbf	d5,.g2c87b69_flat4_bayer_loop
.g2c87b69_flat4_bayer_tail
	move	g2flat_tail_count,d5
	beq.w	.hhh
	subq	#1,d5
.g2c87b69_flat4_bayer_tail_loop
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_bayer_tail_skip
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2c87b69_flat4_bayer_tail_base
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2c87b69_flat4_bayer_tail_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	.g2c87b69_flat4_bayer_tail_advance
.g2c87b69_flat4_bayer_tail_base
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
.g2c87b69_flat4_bayer_tail_advance
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	bra.s	.g2c87b69_flat4_bayer_tail_next
.g2c87b69_flat4_bayer_tail_skip
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	lea	1(a6),a6
.g2c87b69_flat4_bayer_tail_next
	dbf	d5,.g2c87b69_flat4_bayer_tail_loop
	bra.w	.hhh

.g2c87b69_flat_bayer_indexed
	lea	coloffs(pc),a3
	move	width(pc),d5
	subq	#1,d5
.g2c87b69_flat_bayer_idx_loop
	move.l	(a3)+,a4
	tst.b	0(a2,a4.l)
	bne.w	.g2c87b69_flat_bayer_idx_skip
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	.g2c87b69_flat_bayer_idx_base
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	.g2c87b69_flat_bayer_idx_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),0(a2,a4.l)
	bra.s	.g2c87b69_flat_bayer_idx_advance
.g2c87b69_flat_bayer_idx_base
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),0(a2,a4.l)
.g2c87b69_flat_bayer_idx_advance
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,.g2c87b69_flat_bayer_idx_loop
	bra.w	.hhh
.g2c87b69_flat_bayer_idx_skip
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,.g2c87b69_flat_bayer_idx_loop
	bra.w	.hhh

.g2stock_flat_draw_setup
	move.l	d7,-(a7)
	moveq	#127,d7
	moveq	#0,d2
	moveq	#0,d3
	tst.w	g2kalms_linear_active
	bne.s	.g2c87b69_flat4_stock_setup
	tst.w	p96gameplay_linear_active
	beq.w	.g2c87b69_flat_stock_indexed
.g2c87b69_flat4_stock_setup
	move.l	a2,a3
	move	width(pc),d5
	move	d5,d3
	and	#3,d3
	move	d3,g2flat_tail_count
	moveq	#0,d3
	lsr	#2,d5
	beq.w	.g2c87b69_flat4_stock_tail
	subq	#1,d5
.g2c87b69_flat4_stock_loop
	; Pixel A
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_stock_skip_a
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	bra.s	.g2c87b69_flat4_stock_pixel_b
.g2c87b69_flat4_stock_skip_a
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
.g2c87b69_flat4_stock_pixel_b
	; Pixel B
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_stock_skip_b
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	bra.s	.g2c87b69_flat4_stock_pixel_c
.g2c87b69_flat4_stock_skip_b
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
.g2c87b69_flat4_stock_pixel_c
	; Pixel C
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_stock_skip_c
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	bra.s	.g2c87b69_flat4_stock_pixel_d
.g2c87b69_flat4_stock_skip_c
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
.g2c87b69_flat4_stock_pixel_d
	; Pixel D
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_stock_skip_d
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	dbf	d5,.g2c87b69_flat4_stock_loop
	bra.s	.g2c87b69_flat4_stock_tail
.g2c87b69_flat4_stock_skip_d
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	dbf	d5,.g2c87b69_flat4_stock_loop
.g2c87b69_flat4_stock_tail
	move	g2flat_tail_count,d5
	beq.w	.hhh
	subq	#1,d5
.g2c87b69_flat4_stock_tail_loop
	tst.b	(a3)
	bne.w	.g2c87b69_flat4_stock_tail_skip
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	bra.s	.g2c87b69_flat4_stock_tail_next
.g2c87b69_flat4_stock_tail_skip
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
.g2c87b69_flat4_stock_tail_next
	dbf	d5,.g2c87b69_flat4_stock_tail_loop
	bra.w	.hhh

.g2c87b69_flat_stock_indexed
	lea	coloffs(pc),a3
	move	width(pc),d5
	subq	#1,d5
.g2c87b69_flat_stock_idx_loop
	move.l	(a3)+,a4
	tst.b	0(a2,a4.l)
	bne.w	.g2c87b69_flat_stock_idx_skip
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),0(a2,a4.l)
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	dbf	d5,.g2c87b69_flat_stock_idx_loop
	bra.w	.hhh
.g2c87b69_flat_stock_idx_skip
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	dbf	d5,.g2c87b69_flat_stock_idx_loop
	bra.w	.hhh
	;
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
	lea	rotpolys,a5	;header! ; c87w2 absolute address after WIDE code growth
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

dodoors	lea	doors,a5
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

