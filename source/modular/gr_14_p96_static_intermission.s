; -----------------------------------------------------------------------------
; c86zgv: targeted staged P96 static-screen presenter.
; This does NOT hook db globally.  Only explicit showpic/initmenu/scripttext
; callers use it while the display state is TITLE_BRIDGE or INTERMISSION_BRIDGE.
; Complete planar frames are converted to a RAM RGB565 buffer first; only the
; finished buffer is copied to the visible RTG bitmap.
; -----------------------------------------------------------------------------
p96static_rgbbufptr		dc.l	0
p96static_rgbbufsize		dc.l	0
p96static_rgbbpr		dc.l	0
p96static_palette_mode	dc	0	;0=picture palette, -1=font/menu-aware LUT
p96static_defer_present	dc	0	;c86zgz: nonzero suppresses intermediate title P96 present
	cnop	0,4
p96static_rgb565_lut
	dcb.w	256,0
	even

; -----------------------------------------------------------------------------
; c86zgx: title-menu text bridge without the rejected fullscreen static-font
; converter.  c86zgw proved that staged static pictures are safe and gameplay
; stays fast, but menu/script text was still pushed through the slow whole-screen
; planar converter and came out pink.  For title menus, initmenu has already
; rendered the real bigfont.bin/bigfont2.bin rows into menubmap and saved the
; pre-text background strips.  Reuse the proven c86zgs delta idea: compare each
; row against its saved strip and emit only the changed glyph pixels into a RAM
; batch cache, then flush once.  No chatfont, no guessed shape parser, no full
; visible screen rebuild.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; c86zgy: title-menu P96 row restore/blink helpers.
; The staged static RGB565 buffer remains the clean title/menu background.  When
; a title-menu row blinks OFF, copy only that row range back from the staged
; buffer.  When it blinks ON, draw the already-composed real bigfont row using
; the bounded glyph scan.  No full-screen text converter, no chatfont fallback.
; -----------------------------------------------------------------------------
g2p96_title_menu_current_row_present
	movem.l	d0-d1,-(a7)
	move	curropt,d0
	move	fonth,d1
	mulu	d1,d0
	add	menuy,d0
	move	d0,p96menu_y_start
	add	d1,d0
	move	d0,p96menu_y_end
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
	movem.l	(a7)+,d0-d1
	rts

g2p96_title_menu_blink_current_row_on
	movem.l	d0,-(a7)
	move	#-1,p96menu_native_selected
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
	movem.l	(a7)+,d0
	rts

g2p96_title_menu_blink_current_row_off
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	rts

g2p96_title_menu_native_restore_current_row
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	move.l	d0,a3		; staged clean RGB565 title buffer
	move.l	p96winprobe_window_ptr,d0
	beq.w	.done
	move.l	d0,a5
	move.l	50(a5),d0
	beq.w	.done
	move.l	d0,a1
	move.l	4(a1),d0
	beq.w	.done
	move.l	d0,a2
	move.l	8(a2),d0
	beq.w	.done
	move.l	d0,a4		; visible P96 base
	moveq	#0,d4
	move	0(a2),d4
	and.l	#$0000ffff,d4	; destination bytes per row
	moveq	#0,d5
	move	p96target_width,d5
	beq.w	.done
	add.l	d5,d5		; staged bytes per row = width * 2
	move.l	d5,p96static_rgbbpr
	cmp.l	d5,d4
	blo.w	.done
	moveq	#0,d0
	move	6(a5),d0	; Window.TopEdge
	mulu	d4,d0
	adda.l	d0,a4
	moveq	#0,d0
	move	4(a5),d0	; Window.LeftEdge
	add.l	d0,d0
	adda.l	d0,a4
	move	p96menu_y_start,d6
	bpl	.y_start_ok
	moveq	#0,d6
.y_start_ok
	move	p96menu_y_end,d3
	cmp	#240,d3
	ble	.y_end_ok
	move	#240,d3
.y_end_ok
	cmp	d3,d6
	bge.w	.done
.rowloop
	move	p96target_mode,d0
	cmp	#1,d0
	beq	.double_row
	cmp	#2,d0
	beq	.double_row
	move	d6,d0
	jsr	g2p96_title_menu_copy_one_scaled_row_1to1
	bra	.nextrow
.double_row
	move	d6,d0
	add	d0,d0
	jsr	g2p96_title_menu_copy_one_scaled_row_1to1
	addq	#1,d0
	jsr	g2p96_title_menu_copy_one_scaled_row_1to1
.nextrow
	addq	#1,d6
	cmp	d3,d6
	blt	.rowloop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; input: d0=already-scaled destination/staged row, a3=staged buffer,
; a4=visible P96 base, d4=dest bpr, d5=staged bpr.
g2p96_title_menu_copy_one_scaled_row
	movem.l	d0-d2/d7/a0-a1,-(a7)
	move.l	a3,a0
	move	d0,d1
	mulu	d5,d1
	adda.l	d1,a0
	move.l	a4,a1
	move	d0,d1
	mulu	d4,d1
	adda.l	d1,a1
	move	p96target_width,d7
	beq	.done
	subq	#1,d7
.copy
	move	(a0)+,(a1)+
	dbf	d7,.copy
.done
	movem.l	(a7)+,d0-d2/d7/a0-a1
	rts


; c86zhd: P96 title/about cache helpers.  They are deliberately conservative:
; they only claim success while the P96 title owner is active and a staged RGB565
; title buffer exists.  AGA keeps the original slow but safe showpic path.
g2p96_title_cache_ready_if_active
	move.l	d1,-(a7)
	moveq	#0,d0
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96winprobe_window_ptr,d1
	beq.w	.done
	move.l	p96static_rgbbufptr,d1
	beq.w	.done
	move.l	p96static_rgbbufsize,d1
	beq.w	.done
	moveq	#-1,d0
.done
	move.l	(a7)+,d1
	rts

g2p96_title_skip_redundant_brush_if_active
	; Called before the normal title-menu redraw draws pics/gloom again.  If the
	; P96 staged title buffer is already valid, avoid the expensive brush decode
	; and the extra staged present.  The following initmenu still draws the menu.
	bra	g2p96_title_cache_ready_if_active

; c86zhe: qmenu background helper.  c86zhb restored the staged title buffer
; directly, which is fine on first title entry but can dereference stale title
; bridge/window state after returning from gameplay and then opening REMOTE LINK
; OPTIONS.  If the previous P96 owner was gameplay, rebuild the clean title+brush
; once through the proven title path, then mark the cache as title-owned again.
g2p96_title_qmenu_background_if_active
	movem.l	d0-d1/a0-a1,-(a7)
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.done
	tst	p96title_qmenu_rebuild_needed
	bne.s	.rebuild
	cmp	#P96DSP_GAMEPLAY,p96display_prev_state
	bne.s	.restore
.rebuild
	; Rebuild through the safe title path after gameplay->title lifecycle changes.
	; This is slower only for the first REMOTE menu after returning from a game,
	; but avoids the stale-cache crash seen on real Amiga.
	jsr	g2v146_show_title_with_gloom
	clr	p96title_qmenu_rebuild_needed
	move	#P96DSP_TITLE,p96display_prev_state
	bra.s	.done
.restore
	jsr	g2p96_title_restore_staged_background_standard_c87b78r
.done
	movem.l	(a7)+,d0-d1/a0-a1
	rts

; c86zhb: Safe P96 quick-menu background restore.
; c86zha tried to clear quick menus by blacking the staged buffer, but that
; destroyed the title backdrop and corrupted the title-menu lifecycle.  Keep
; the confirmed c86zgz title/menu path and only remove stale menu text by
; copying the already staged title+brush RGB565 buffer back to the visible P96
; bitmap before qmenu/initmenu draws the new remote/link menu text.
g2p96_title_restore_staged_background_if_active
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#P96DSP_TITLE,p96display_state
	bne	.done
	tst	p96gameplay_persist_active
	beq	.done
	move.l	p96static_rgbbufptr,d0
	beq	.done
	move.l	d0,a3
	move.l	p96winprobe_window_ptr,d0
	beq	.done
	move.l	d0,a5
	move.l	50(a5),d0
	beq	.done
	move.l	d0,a1
	move.l	4(a1),d0
	beq	.done
	move.l	d0,a2
	move.l	8(a2),d0
	beq	.done
	move.l	d0,a4
	moveq	#0,d4
	move	0(a2),d4
	and.l	#$0000ffff,d4
	moveq	#0,d5
	move	p96target_width,d5
	beq	.done
	add.l	d5,d5
	moveq	#0,d0
	move	p96target_height,d0
	mulu	d5,d0
	move.l	p96static_rgbbufsize,d1
	cmp.l	d0,d1
	blo	.done
	moveq	#0,d0
	move	6(a5),d0
	mulu	d4,d0
	adda.l	d0,a4
	moveq	#0,d0
	move	4(a5),d0
	add.l	d0,d0
	adda.l	d0,a4
	moveq	#0,d6
.row_loop
	cmp	p96target_height,d6
	bge	.done
	move.l	a3,a0
	move	d6,d0
	mulu	d5,d0
	adda.l	d0,a0
	move.l	a4,a1
	move	d6,d0
	mulu	d4,d0
	adda.l	d0,a1
	move	p96target_width,d7
	beq	.next_row
	subq	#1,d7
.copy_loop
	move	(a0)+,(a1)+
	dbf	d7,.copy_loop
.next_row
	addq	#1,d6
	bra	.row_loop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2p96_static_present_showbitmap_if_intermission
	movem.l	d0-d1,-(a7)
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne	.done
	tst	p96gameplay_persist_active
	beq	.done
	jsr	g2p96_static_present_showbitmap
.done	movem.l	(a7)+,d0-d1
	rts

; c86zhg: small hook used by printmess2.  It is intentionally gated by
; pdelay so normal title/in-game menu text rendering is not converted after
; every glyph.  Intermission text uses pdelay>=0 and therefore appears with
; the original typewriter timing on P96 too.
g2p96_intermission_typewriter_char_if_active
	movem.l	d0-d2,-(a7)
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne	.done
	tst	p96gameplay_persist_active
	beq	.done
	move	pdelay,d0
	cmp	#1,d0	;c86zjn: only the real typewriter cadence updates per glyph
	blt	.done
	tst	p96inter_typewriter_active
	beq	.legacy
	jsr	g2p96_intermission_native_typewriter_char_standard_c87b78r
	bra	.done
.legacy
	; Safe fallback retained for any path which did not arm the native compositor.
	btst	#6,$dff002
.wait	btst	#6,$dff002
	bne.s	.wait
	move	#-1,p96static_palette_mode
	jsr	g2p96_static_present_showbitmap
.done	movem.l	(a7)+,d0-d2
	rts

g2p96_static_present_intermission_text_skip_if_active
	; c86zhf: targeted intermission text P96 present.  This is deliberately
	; NOT the rejected global db bridge: only scripttext calls it after the
	; original printmess2 has finished drawing into showbitmap.  Convert the
	; already complete planar intermission+text frame into the staged RGB565
	; buffer, then copy the finished buffer once to P96.
	movem.l	d0-d1,-(a7)
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne	.done
	tst	p96gameplay_persist_active
	beq	.done
	move	#-1,p96static_palette_mode	;c86zhg: font/text palette, not picture palette (fix pink text)
	jsr	g2p96_static_present_showbitmap
.done	movem.l	(a7)+,d0-d1
	rts

g2p96_static_present_title_menu_bigfont_if_active
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq.w	.g2c87b79x_title_direct_unavailable
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.g2c86zjj_title_native_done
	tst	p96gameplay_persist_active
	beq.w	.g2c86zjj_title_native_done
	jsr	g2p96_menu_build_rgb565_lut
	jsr	g2p96_menu_batch_begin_dispatch_c87b78p
	; If the large page batch is unavailable, each row still uses the proven
	; offscreen row cache and is flushed complete; never leave a blank title menu.
	move	curropt,-(a7)
	clr	p96menu_native_selected
	moveq	#0,d7
.g2c86zjj_title_native_loop
	move	numopts,d0
	cmp	d0,d7
	bge	.g2c86zjj_title_native_flush
	move	d7,curropt
	jsr	g2p96_menu_glyph_draw_current_row_no_restore
	addq	#1,d7
	bra	.g2c86zjj_title_native_loop
.g2c86zjj_title_native_flush
	jsr	g2p96_title_menu_draw_separator_lines_if_needed
	move	(a7)+,curropt
	tst	p96menu_batch_active
	beq	.g2c86zjj_title_native_done
	jsr	g2p96_menu_batch_flush_dispatch_c87b78p
	jsr	g2p96_menu_batch_end
.g2c86zjj_title_native_done
	clr	p96menu_batch_active
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.g2c87b79x_title_direct_unavailable
	rts
; c87b4: P96 title menu dotted separator lines.  The AGA path draws two
; 80px dotted lines in the compact spacer rows (between TWO PLAYER GAME and
; PLAYER 1, and between PLAYER 2 and VIOLENCE MODE).  The title P96 bridge draws
; only glyph deltas, so add the separators explicitly into the active batch.
g2p96_title_menu_draw_separator_lines_if_needed
	movem.l	d0-d7,-(a7)
	tst	g2v154_titlemenu_lines
	beq	.done
	move	menuy,d0
	move	fonth,d1
	move	d1,d2
	lsr	#1,d2
	moveq	#2,d3
	mulu	d1,d3
	add	d3,d0
	add	d2,d0
	subq	#1,d0
	jsr	g2p96_title_menu_draw_one_separator_line
	move	menuy,d0
	move	fonth,d1
	move	d1,d2
	lsr	#1,d2
	moveq	#5,d3
	mulu	d1,d3
	add	d3,d0
	add	d2,d0
	subq	#1,d0
	jsr	g2p96_title_menu_draw_one_separator_line
.done
	movem.l	(a7)+,d0-d7
	rts

g2p96_title_menu_draw_one_separator_line	; d0 = source Y
	movem.l	d0-d7,-(a7)
	move	d0,d6
	cmp	#0,d6
	blt	.done
	cmp	#240,d6
	bge	.done
	jsr	g2p96_menu_normal_colour_c87b78j
	move	d2,p96menu_native_colour	; exact normal menu pen for active P96 format
	move	#120,d7
.loop
	cmp	#200,d7
	bge	.done
	btst	#0,d7
	beq	.skip
	move	d7,p96menu_native_px
	move	d6,p96menu_native_py
	jsr	g2p96_menu_native_put_pixel
.skip
	addq	#1,d7
	bra	.loop
.done
	movem.l	(a7)+,d0-d7
	rts

g2p96_static_open_screen
	movem.l	d0-d1/a0-a1/a6,-(a7)
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq	.done
	tst	p96gameplay_persist_active
	bne	.done	;c86zhi: do not black screen between intermission picture/text
	clr	p96gameplay_latched
	clr	p96gameplay_delay_counter
	jsr	g2p96_gameplay_persistent_open
	jsr	g2p96_validate_persistent_screen_c87b79o
	tst	p96gameplay_persist_active
	beq	.done
	jsr	g2p96_gameplay_clear_p96_screen
.done
	movem.l	(a7)+,d0-d1/a0-a1/a6
	rts

g2p96_static_present_showbitmap_plain_if_active
	clr	p96static_palette_mode
	bra	g2p96_static_present_showbitmap_if_active

g2p96_static_present_showbitmap_if_active
	movem.l	d0-d1,-(a7)
	cmp	#P96DSP_TITLE,p96display_state
	beq	.present
	cmp	#P96DSP_INTERMISSION,p96display_state
	beq	.present
	bra	.done
.present
	tst	p96static_defer_present	;c86zgz: avoid showing half-built title before brush/menu stage
	bne	.done
	tst	p96gameplay_persist_active
	beq	.done
	jsr	g2p96_static_present_showbitmap
.done
	movem.l	(a7)+,d0-d1
	rts

g2p96_static_present_showbitmap
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96static_direct_valid	;c87b79x: authoritative index page only
	beq	.done
	move.l	p96static_direct_index_ptr,d0
	beq	.done
	suba.l	a4,a4		; no compact planar source exists under P96
	move.l	p96static_rgbbufptr,d0
	beq	.done
	move.l	d0,a3		; completed RGB565 staging page in Fast RAM

	; c87b78f: derive only the packed RAM geometry here. Destination address,
	; stride and RGB format are obtained later from p96LockBitMap RenderInfo.
	moveq	#0,d0
	move	p96target_width,d0
	beq	.done
	add.l	d0,d0
	move.l	d0,p96static_rgbbpr
	moveq	#0,d1
	move	p96target_height,d1
	beq	.done
	mulu	d1,d0
	move.l	p96static_rgbbufsize,d1
	cmp.l	d0,d1
	blo	.done
	tst	p96static_palette_mode
	beq	.plain_lut
	; c86zhi: font/text mode keeps the picture palette for the backdrop
	; and overrides only font entries.  The menu LUT caused pink/brown text.
	jsr	g2p96_static_build_font_rgb565_lut
	bra	.have_lut
.plain_lut
	jsr	g2p96_static_build_rgb565_lut
.have_lut
	jsr	g2p96_static_build_rgb_buffer
	jsr	g2p96_static_copy_rgb_buffer_to_p96_c87b78n
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2p96_static_build_rgb_buffer
	movem.l	d0-d7/a0-a6,-(a7)
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_standard
	jsr	g2oneone_static_build_rgb_buffer
	bra.w	.done
.g2c87p1_standard
	suba.l	a4,a4		;c87b79x: row selector consumes direct index page
	move.l	p96static_rgbbufptr,a3
	lea	p96static_rgb565_lut,a5
	moveq	#0,d6
.rowloop
	cmp	#240,d6
	bge.w	.done
	move	d6,d0
	move	p96target_mode,d1
	cmp	#1,d1
	beq.s	.double_y
	cmp	#2,d1
	beq.s	.double_y
	bra.s	.low_y
.double_y
	add	d0,d0
.low_y
	move.l	p96static_rgbbpr,d4
	mulu	d4,d0
	move.l	a3,a1
	adda.l	d0,a1
	move.l	a1,a0
	cmp	#1,d1
	beq.s	.add_row2
	cmp	#2,d1
	beq.s	.add_row2
	bra.s	.dispatch
.add_row2
	adda.l	d4,a0
.dispatch
	jsr	g2p96_static_decode_index_row_best
	tst	g2p96_wide_mode
	beq.s	.standard
	jsr	g2wide_static_emit_row
	bra.w	.nextrow
.standard
	move	p96target_mode,d0
	beq	.copy_1x
	cmp	#1,d0
	beq	.copy_2x
	cmp	#3,d0
	beq	.copy_stretch_240
	bra	.copy_stretch_480
.copy_1x
	moveq	#0,d7
.loop1
	cmp	#320,d7
	bge	.nextrow
	moveq	#0,d1
	move.b	(a6)+,d1
	add	d1,d1
	move	0(a5,d1.w),(a1)+
	addq	#1,d7
	bra	.loop1
.copy_2x
	moveq	#0,d7
.loop2
	cmp	#320,d7
	bge	.nextrow
	moveq	#0,d1
	move.b	(a6)+,d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	move	d2,(a1)+
	move	d2,(a0)+
	move	d2,(a0)+
	addq	#1,d7
	bra	.loop2
.copy_stretch_480
	moveq	#0,d7
	moveq	#0,d3
	moveq	#0,d2
.stretch480_src_loop
	cmp	#320,d7
	bge	.nextrow
	move	d2,-(a7)
	moveq	#0,d1
	move.b	(a6)+,d1
	add	d1,d1
	move	0(a5,d1.w),d1
	move	(a7)+,d2
	add	p96target_width,d3
.stretch480_emit
	cmp	p96target_width,d2
	bge	.nextrow
	move	d1,(a1)+
	move	d1,(a0)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs	.stretch480_emit
	addq	#1,d7
	bra	.stretch480_src_loop
.copy_stretch_240
	moveq	#0,d7
	moveq	#0,d3
	moveq	#0,d2
.stretch240_src_loop
	cmp	#320,d7
	bge	.nextrow
	move	d2,-(a7)
	moveq	#0,d1
	move.b	(a6)+,d1
	add	d1,d1
	move	0(a5,d1.w),d1
	move	(a7)+,d2
	add	p96target_width,d3
.stretch240_emit
	cmp	p96target_width,d2
	bge	.nextrow
	move	d1,(a1)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs	.stretch240_emit
	addq	#1,d7
	bra	.stretch240_src_loop
.nextrow
	addq	#1,d6
	bra.w	.rowloop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; c87w1: centre the untouched 320x240 artwork and extend its first/last
; scanline colours into a four-step dark edge wash. Input a6=index row,
; a1=first destination row, a0=second row for 480p, a5=RGB565 LUT.
g2wide_static_emit_row
	movem.l	d0-d7/a2-a4,-(a7)
	moveq	#0,d7
	cmp	#2,p96target_mode
	bne.s	.low
	moveq	#1,d7
.low
	move	p96target_width,d6
	move	#320,d5
	tst	d7
	beq.s	.content_ready
	move	#640,d5
.content_ready
	sub	d5,d6
	lsr	#1,d6		;border width
	moveq	#0,d1
	move.b	(a6),d1
	add	d1,d1
	move	0(a5,d1.w),d2	;left edge colour
	move	d2,d5		;preserve unshaded edge colour
	moveq	#0,d4
.left_loop
	cmp	d6,d4
	bge.s	.center
	moveq	#0,d3
	move	d4,d3
	lsl	#2,d3
	divu	d6,d3
	move	d5,d2
	jsr	g2wide_rgb565_shade
	move	d2,(a1)+
	tst	d7
	beq.s	.left_next
	move	d2,(a0)+
.left_next
	addq	#1,d4
	bra.s	.left_loop
.center
	moveq	#0,d4
.center_loop
	cmp	#320,d4
	bge.s	.right_setup
	moveq	#0,d1
	move.b	0(a6,d4.w),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	tst	d7
	beq.s	.center_next
	move	d2,(a1)+
	move	d2,(a0)+
	move	d2,(a0)+
.center_next
	addq	#1,d4
	bra.s	.center_loop
.right_setup
	moveq	#0,d1
	move.b	319(a6),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,d5		;preserve unshaded edge colour
	moveq	#0,d4
.right_loop
	cmp	d6,d4
	bge.s	.done
	moveq	#0,d3
	move	d6,d3
	subq	#1,d3
	sub	d4,d3
	lsl	#2,d3
	divu	d6,d3
	move	d5,d2
	jsr	g2wide_rgb565_shade
	move	d2,(a1)+
	tst	d7
	beq.s	.right_next
	move	d2,(a0)+
.right_next
	addq	#1,d4
	bra.s	.right_loop
.done
	movem.l	(a7)+,d0-d7/a2-a4
	rts

; d2=RGB565, d3=0..3 (quarter, half, three-quarter, full).
g2wide_rgb565_shade
	movem.l	d0-d1/d4,-(a7)
	move	d2,d0
	cmp.l	#RGBFB_R5G6B5,p96modeid_rgbformat
	beq.s	.native
	ror	#8,d0
.native
	cmp	#3,d3
	bge.s	.pack
	move	d0,d1
	and	#$f7de,d1
	lsr	#1,d1		;half
	tst	d3
	beq.s	.quarter
	cmp	#1,d3
	beq.s	.use_half
	move	d0,d4
	and	#$e79c,d4
	lsr	#2,d4
	add	d4,d1		;three-quarter
.use_half
	move	d1,d0
	bra.s	.pack
.quarter
	move	d0,d1
	and	#$e79c,d1
	lsr	#2,d1
	move	d1,d0
.pack
	cmp.l	#RGBFB_R5G6B5,p96modeid_rgbformat
	beq.s	.store
	ror	#8,d0
.store
	move	d0,d2
	movem.l	(a7)+,d0-d1/d4
	rts

g2p96_static_copy_rgb_buffer_to_p96
	; c87b78f: publish the completed full-screen Fast-RAM page through the
	; common visible-bitmap rectangle helper. The helper selects the currently
	; visible ScreenBuffer, obtains real VRAM address/stride/format from
	; RenderInfo, copies only while locked and always unlocks before return.
	movem.l	d0-d3,-(a7)
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	move.l	d0,p96safe_rect_src_ptr
	move.l	p96static_rgbbpr,d0
	beq.w	.done
	move.l	d0,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d0,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	clr	p96safe_rect_dst_y
	move	p96target_height,d0
	beq.w	.done
	move	d0,p96safe_rect_height
	jsr	g2p96_copy_ram_rect_to_visible_c87b78d
.done
	movem.l	(a7)+,d0-d3
	rts


g2p96_static_build_rgb565_lut
	jsr	g2p96_static_build_rgb565_lut_legacy
	jmp	g2p96_clut_static_lut_ready_c87b78j
g2p96_static_build_rgb565_lut_legacy
	movem.l	d0-d7/a0-a3,-(a7)
	lea	p96static_rgb565_lut,a1
	move.l	a1,a0
	moveq	#0,d0
	move	#255,d7
.clear_lut
	move	d0,(a0)+
	dbf	d7,.clear_lut
	move.l	lastpal,d0
	; c87b7: during Gloom3/ZM intermissions the LUT reads the immutable
	; embedded original palette directly, never a mutable global palette.
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.s	.g2c87b7_plain_legacy
	cmp	#2,g2_game_profile
	beq.s	.g2c87b7_plain_exact
	cmp	#3,g2_game_profile
	bne.s	.g2c87b7_plain_legacy
.g2c87b7_plain_exact
	move.l	g2inter_exact_palette_ptr,d1
	beq.s	.g2c87b7_plain_legacy
	move.l	d1,d0
.g2c87b7_plain_legacy
	bne	.havepal
	move.l	planar_palette,d0
	beq	.black_all
.havepal
	move.l	d0,a3
	moveq	#0,d7
.lut_loop
	cmp	g2static_palette_count,d7	;c87b4: never read beyond the loaded .pal
	bge	.done
	move	d7,d6
	tst	aga
	beq	.ecs
	lsl	#2,d6
	bra	.paladdr
.ecs
	add	d6,d6
.paladdr
	move	0(a3,d6.w),d0
	tst	aga
	beq	.ecs_convert
	move	2(a3,d6.w),d2
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra	.store
.ecs_convert
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.store
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
	addq	#1,d7
	bra	.lut_loop
.black_all
	moveq	#0,d0
	move	#255,d7
.black_loop
	move	d0,(a1)+
	dbf	d7,.black_loop
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts


; c86zhi: Build a P96 static-screen LUT for intermission/title text.
; Base colours come from the current picture palette (picpal/gloompal), then
; entries 0..3 are overridden from bigfont.bin/bigfont2.bin.  That keeps the
; background faithful while making the font yellow like the AGA renderer.
g2p96_static_build_font_rgb565_lut
	jsr	g2p96_static_build_font_rgb565_lut_c87b78y
	jmp	g2p96_clut_static_lut_ready_c87b78j
g2p96_static_build_font_rgb565_lut_legacy
	movem.l	d0-d7/a0-a3,-(a7)
	lea	p96static_rgb565_lut,a1
	move.l	a1,a0
	moveq	#0,d0
	move	#255,d7
.clear_lut
	move	d0,(a0)+
	dbf	d7,.clear_lut
	move.l	picpal,d0
	; c87b7: the native P96 text pass must use the same exact palette as
	; scriptdraw.  Do not fall back to stale picpal/lastpal after a level.
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.s	.g2c87b7_font_legacy
	cmp	#2,g2_game_profile
	beq.s	.g2c87b7_font_exact
	cmp	#3,g2_game_profile
	bne.s	.g2c87b7_font_legacy
.g2c87b7_font_exact
	move.l	g2inter_exact_palette_ptr,d1
	beq.s	.g2c87b7_font_legacy
	move.l	d1,d0
.g2c87b7_font_legacy
	bne	.havepal
	move.l	gloompal,d0
	bne	.havepal
	move.l	planar_palette,d0
	beq	.black_all
.havepal
	move.l	d0,a3
	moveq	#0,d7
.lut_loop
	cmp	g2static_palette_count,d7	;c87b4: source depth bounds .pal reads
	bge	.font_override
	move	d7,d6
	tst	aga
	beq	.ecs
	lsl	#2,d6
	bra	.paladdr
.ecs
	add	d6,d6
.paladdr
	move	0(a3,d6.w),d0
	tst	aga
	beq	.ecs_convert
	move	2(a3,d6.w),d2
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra	.store
.ecs_convert
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.store
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
	addq	#1,d7
	bra	.lut_loop
.black_all
	moveq	#0,d0
	move	#255,d7
.black_loop
	move	d0,(a1)+
	dbf	d7,.black_loop
.font_override
	; c87b10: keep the picture LUT exact and publish the three isolated
	; Bigfont yellow shades at their selected palette indices.
	tst	g2inter_yellow_text_active
	beq	.g2c87b10_no_isolated_yellow_lut
	move.l	g2inter_exact_palette_ptr,d0
	beq	.g2c87b10_no_isolated_yellow_lut
	move.l	d0,a3
	lea	g2inter_yellow_text_indices,a0
	moveq	#2,d5
.g2c87b10_yellow_lut_loop
	move	(a0)+,d7
	tst	d7
	bmi	.g2c87b10_yellow_lut_next
	move	d7,d6
	tst	aga
	beq	.g2c87b10_yellow_ecs_addr
	lsl	#2,d6
	move	0(a3,d6.w),d0
	move	2(a3,d6.w),d2
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra	.g2c87b10_yellow_store
.g2c87b10_yellow_ecs_addr
	add	d6,d6
	move	0(a3,d6.w),d0
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.g2c87b10_yellow_store
	lea	p96static_rgb565_lut,a1
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
.g2c87b10_yellow_lut_next
	dbf	d5,.g2c87b10_yellow_lut_loop
.g2c87b10_no_isolated_yellow_lut
	cmp	#2,g2_game_profile	;c87b4: ZM picture palette remains exact
	beq	.done
	cmp	#3,g2_game_profile	;c87b4: Gloom3 picture palette remains exact
	beq	.done
	move.l	font,d0
	beq	.done
	move.l	d0,a0
	add.l	(a0),a0
	lea	p96static_rgb565_lut,a1
	moveq	#0,d7
.font_loop
	cmp	#4,d7
	bge	.done
	move	(a0)+,d0
	tst	d7
	bne	.font_colour
	moveq	#0,d0
.font_colour
	moveq	#0,d2
	tst	aga
	beq	.font_ecs
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra	.font_store
.font_ecs
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.font_store
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
	addq	#1,d7
	bra	.font_loop
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts

; c87b70e: build source-byte -> RGB565 LUT from the palette that is really
; installed on the Amiga display. Chunky gameplay bytes are paladjust/C2P-
; scrambled, therefore each source byte is first mapped through g2_strip_invpal.
; lastpal is updated by pokepal whenever the game/menu palette changes; use it
; first, then fall back to planar_palette only before any palette was installed.
; On AGA, read both high and low RGB12 words before reducing to RGB565.
g2p96_gameplay_build_rgb565_source_lut
	jsr	g2p96_gameplay_build_rgb565_source_lut_c87b78h
	jmp	g2p96_clut_gameplay_lut_ready_c87b78j
; d0 = RGB12 word $0RGB, return d1 = c86zds-confirmed RGB565 word.
g2p96_gameplay_rgb12_to_rgb565_c86zds
	movem.l	d2-d4,-(a7)
	move	d0,d1
	and	#$0f00,d1
	lsr	#8,d1		;R 0..15
	move	d1,d2
	lsl	#1,d1
	lsr	#3,d2
	or	d2,d1		;R 0..31
	lsl	#8,d1
	lsl	#3,d1
	move	d0,d2
	and	#$00f0,d2
	lsr	#4,d2		;G 0..15
	move	d2,d3
	lsl	#2,d2
	lsr	#2,d3
	or	d3,d2		;G 0..63
	lsl	#5,d2
	or	d2,d1
	move	d0,d2
	and	#$000f,d2	;B 0..15
	move	d2,d3
	lsl	#1,d2
	lsr	#3,d3
	or	d3,d2		;B 0..31
	or	d2,d1		;RGB565
	cmp.l	#RGBFB_R5G6B5,p96modeid_rgbformat	;c86zjc native 68k word order
	beq.s	.noswap
	ror	#8,d1		;RGBFB_R5G6B5PC and safe fallback
.noswap
	movem.l	(a7)+,d2-d4
	rts

; c86zey: d0 = AGA high RGB12 word, d2 = AGA low RGB12 word.
; Return d1 = byteswapped RGB565.  This preserves the confirmed c86zds byte
; order, but uses AGA's extra low nibbles before reducing to 5/6/5 bits.
g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	movem.l	d2-d5,-(a7)
	; R5 = (Rhigh << 1) | (Rlow >> 3)
	move	d0,d1
	and	#$0f00,d1
	lsr	#8,d1
	lsl	#1,d1
	move	d2,d3
	and	#$0f00,d3
	lsr	#8,d3
	lsr	#3,d3
	or	d3,d1
	lsl	#8,d1
	lsl	#3,d1
	; G6 = (Ghigh << 2) | (Glow >> 2)
	move	d0,d3
	and	#$00f0,d3
	lsr	#4,d3
	lsl	#2,d3
	move	d2,d4
	and	#$00f0,d4
	lsr	#4,d4
	lsr	#2,d4
	or	d4,d3
	lsl	#5,d3
	or	d3,d1
	; B5 = (Bhigh << 1) | (Blow >> 3)
	move	d0,d3
	and	#$000f,d3
	lsl	#1,d3
	move	d2,d4
	and	#$000f,d4
	lsr	#3,d4
	or	d4,d3
	or	d3,d1
	cmp.l	#RGBFB_R5G6B5,p96modeid_rgbformat	;c86zjc native 68k word order
	beq.s	.noswap
	ror	#8,d1		;RGBFB_R5G6B5PC and safe fallback
.noswap
	movem.l	(a7)+,d2-d5
	rts

p96gameplay_rgb565_source_lut
	dcb.w	256,0
	even

SB_SCREEN_BITMAP	equ	1
SB_COPY_BITMAP	equ	2
SB_BitMap	equ	0
SB_DBufInfo	equ	4
DBI_SafeReplyPort	equ	22
DBI_DispReplyPort	equ	54
p96gameplay_dbuf_active	dc	0
p96gameplay_dbuf_suspended	dc	0
p96gameplay_dbuf_current	dc	0
p96gameplay_dbuf_draw	dc	1
p96gameplay_dbuf_safe_pending	dc	0
p96gameplay_dbuf_disp_pending	dc	0
p96gameplay_dbuf_sb0	dc.l	0
p96gameplay_dbuf_sb1	dc.l	0
p96gameplay_dbuf_safeport	dc.l	0
p96gameplay_dbuf_dispport	dc.l	0
p96gameplay_dbuf_rport_orig	dc.l	0
g2p96_force_hide_screen_title
	movem.l	d0/a0/a6,-(a7)
	move.l	p96winprobe_screen_ptr,a0
	tst.l	a0
	beq.w	.done
	move.l	p96gameplay_intbase,a6
	tst.l	a6
	beq.w	.done
	moveq	#0,d0		;FALSE = hide screen title bar
	jsr	-282(a6)	;ShowTitle
.done
	movem.l	(a7)+,d0/a0/a6
	rts

g2p96_gameplay_dbuf_init
	movem.l	d0-d3/a0-a2/a6,-(a7)
	clr	p96gameplay_dbuf_active
	clr	p96gameplay_dbuf_suspended
	clr	p96gameplay_dbuf_safe_pending
	clr	p96gameplay_dbuf_disp_pending
	clr.l	p96gameplay_dbuf_sb0
	clr.l	p96gameplay_dbuf_sb1
	clr.l	p96gameplay_dbuf_safeport
	clr.l	p96gameplay_dbuf_dispport
	clr.l	p96gameplay_dbuf_rport_orig
	; P96SINGLE, IndiECS or Warp/csgfx: no second bitmap/reply ports.
	cmp	#2,g2display_mode
	bne.s	.single_checked
	tst	g2p96_single_buffer
	bne.w	.done
	jsr	g2p96_auto_single_board
	tst.l	d0
	bne.w	.done
.single_checked
	move.l	p96winprobe_screen_ptr,d0
	beq.w	.fail
	move.l	p96gameplay_intbase,d0
	beq.w	.fail
	move.l	4.w,a6
	jsr	-666(a6)	;CreateMsgPort
	move.l	d0,p96gameplay_dbuf_safeport
	beq.w	.fail
	move.l	4.w,a6
	jsr	-666(a6)	;CreateMsgPort
	move.l	d0,p96gameplay_dbuf_dispport
	beq.w	.fail
	move.l	p96winprobe_screen_ptr,a0
	sub.l	a1,a1
	moveq	#SB_SCREEN_BITMAP,d0
	move.l	p96gameplay_intbase,a6
	jsr	-768(a6)	;AllocScreenBuffer
	move.l	d0,p96gameplay_dbuf_sb0
	beq.w	.fail
	move.l	p96winprobe_screen_ptr,a0
	sub.l	a1,a1
	moveq	#SB_COPY_BITMAP,d0
	move.l	p96gameplay_intbase,a6
	jsr	-768(a6)	;AllocScreenBuffer
	move.l	d0,p96gameplay_dbuf_sb1
	beq.w	.fail
	; c86zjf: remember the original single-buffer bitmap used by the window.
	move.l	p96winprobe_window_ptr,d0
	beq.w	.fail
	move.l	d0,a0
	move.l	50(a0),d0
	beq.w	.fail
	move.l	d0,a1
	move.l	4(a1),d0
	beq.w	.fail
	move.l	d0,p96gameplay_dbuf_rport_orig
	move.l	p96gameplay_dbuf_sb0,a0
	move.l	SB_DBufInfo(a0),d0
	beq.w	.fail
	move.l	d0,a1
	move.l	p96gameplay_dbuf_safeport,DBI_SafeReplyPort(a1)
	move.l	p96gameplay_dbuf_dispport,DBI_DispReplyPort(a1)
	move.l	p96gameplay_dbuf_sb1,a0
	move.l	SB_DBufInfo(a0),d0
	beq.w	.fail
	move.l	d0,a1
	move.l	p96gameplay_dbuf_safeport,DBI_SafeReplyPort(a1)
	move.l	p96gameplay_dbuf_dispport,DBI_DispReplyPort(a1)
	clr	p96gameplay_dbuf_current
	move	#1,p96gameplay_dbuf_draw
	move	#-1,p96gameplay_dbuf_active
	move.l	p96gameplay_dbuf_sb1,a0
	move.l	SB_BitMap(a0),a2
	jsr	g2p96_gameplay_clear_bitmap_a2
	moveq	#-1,d0
	bra	.done
.fail
	jsr	g2p96_gameplay_dbuf_free_partial
	moveq	#0,d0
.done
	movem.l	(a7)+,d0-d3/a0-a2/a6
	rts

g2p96_gameplay_dbuf_poll_port
	movem.l	d1-d2/a0-a2/a6,-(a7)
	move.l	a0,a2
	moveq	#7,d2
.poll
	move.l	a2,a0
	move.l	4.w,a6
	jsr	-372(a6)	;GetMsg
	tst.l	d0
	bne	.got
	move.l	p96gameplay_grbase,d0
	beq	.fail
	move.l	d0,a6
	jsr	-270(a6)	;WaitTOF
	dbf	d2,.poll
	; Check the reply delivered during the final WaitTOF as well.
	move.l	a2,a0
	move.l	4.w,a6
	jsr	-372(a6)
	tst.l	d0
	bne	.got
.fail
	moveq	#0,d0
	bra	.done
.got
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d2/a0-a2/a6
	rts

g2p96_gameplay_dbuf_wait_safe
	movem.l	a0,-(a7)
	moveq	#-1,d0
	tst	p96gameplay_dbuf_active
	beq	.done
	tst	p96gameplay_dbuf_safe_pending
	beq	.done
	move.l	p96gameplay_dbuf_safeport,a0
	beq	.fail
	jsr	g2p96_gameplay_dbuf_poll_port
	tst	d0
	beq	.fail
	clr	p96gameplay_dbuf_safe_pending
	moveq	#-1,d0
	bra	.done
.fail
	moveq	#0,d0
.done
	move.l	(a7)+,a0
	rts

g2p96_gameplay_dbuf_wait_disp
	movem.l	a0,-(a7)
	moveq	#-1,d0
	tst	p96gameplay_dbuf_active
	beq	.done
	tst	p96gameplay_dbuf_disp_pending
	beq	.done
	move.l	p96gameplay_dbuf_dispport,a0
	beq	.fail
	jsr	g2p96_gameplay_dbuf_poll_port
	tst	d0
	beq	.fail
	clr	p96gameplay_dbuf_disp_pending
	moveq	#-1,d0
	bra	.done
.fail
	moveq	#0,d0
.done
	move.l	(a7)+,a0
	rts

g2p96_gameplay_dbuf_flip
	movem.l	d1-d3/a0-a1/a6,-(a7)
	moveq	#-1,d0
	tst	p96gameplay_dbuf_active
	beq.w	.done
	tst	p96gameplay_dbuf_suspended
	bne.w	.done
	jsr	g2p96_gameplay_dbuf_wait_disp
	tst	d0
	beq.w	.fail
	move.l	p96gameplay_grbase,d0
	beq.w	.fail
	move.l	d0,a6
	jsr	-228(a6)	;WaitBlit
	tst	p96gameplay_dbuf_draw
	beq	.use0
	move.l	p96gameplay_dbuf_sb1,a1
	bra	.have_sb
.use0
	move.l	p96gameplay_dbuf_sb0,a1
.have_sb
	moveq	#3,d3
.retry
	move.l	p96winprobe_screen_ptr,a0
	move.l	p96gameplay_intbase,a6
	jsr	-780(a6)	;ChangeScreenBuffer
	tst	d0
	bne	.swapped
	move.l	p96gameplay_grbase,a6
	jsr	-270(a6)	;WaitTOF
	dbf	d3,.retry
	bra	.fail
.swapped
	jsr	g2p96_force_hide_screen_title	;c86zjp: suppress title bar after every front-buffer change
	move	p96gameplay_dbuf_draw,d1
	move	d1,p96gameplay_dbuf_current
	eor	#1,d1
	move	d1,p96gameplay_dbuf_draw
	move	#-1,p96gameplay_dbuf_safe_pending
	move	#-1,p96gameplay_dbuf_disp_pending
	moveq	#-1,d0
	bra	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d3/a0-a1/a6
	rts

g2p96_gameplay_dbuf_restore_rport_original
	movem.l	d0/a0-a1,-(a7)
	move.l	p96gameplay_dbuf_rport_orig,d0
	beq.w	.done
	move.l	p96winprobe_window_ptr,a0
	tst.l	a0
	beq.w	.done
	move.l	50(a0),a1
	tst.l	a1
	beq.w	.done
	move.l	d0,4(a1)
.done
	movem.l	(a7)+,d0/a0-a1
	rts

; c86zjf: menu and static owners must not assume the original screen bitmap
; is visible after ChangeScreenBuffer().  Finish the pending swap, freeze the
; current front buffer, then point Window.RPort.BitMap at exactly that bitmap.
g2p96_gameplay_dbuf_suspend_visible
	movem.l	d0-d1/a0-a2,-(a7)
	tst	p96gameplay_dbuf_active
	beq.w	.done
	tst	p96gameplay_dbuf_suspended
	bne.w	.done
	jsr	g2p96_gameplay_dbuf_wait_safe
	tst	d0
	beq.w	.fail
	jsr	g2p96_gameplay_dbuf_wait_disp
	tst	d0
	beq.w	.fail
	tst	p96gameplay_dbuf_current
	beq.s	.use0
	move.l	p96gameplay_dbuf_sb1,a0
	bra.s	.have_sb
.use0
	move.l	p96gameplay_dbuf_sb0,a0
.have_sb
	tst.l	a0
	beq.w	.fail
	move.l	SB_BitMap(a0),d1
	beq.w	.fail
	move.l	p96winprobe_window_ptr,a1
	tst.l	a1
	beq.w	.fail
	move.l	50(a1),a2
	tst.l	a2
	beq.w	.fail
	move.l	d1,4(a2)
	move	#-1,p96gameplay_dbuf_suspended
	jsr	g2p96_force_hide_screen_title	;c86zjp: menu/static owners must not expose Intuition screen title
	bra.s	.done
.fail
	; Stop further flips even on failure; the bridge must never race gameplay.
	move	#-1,p96gameplay_dbuf_suspended
.done
	movem.l	(a7)+,d0-d1/a0-a2
	rts

g2p96_gameplay_dbuf_suspend_primary
	movem.l	d0-d3/a0-a1/a6,-(a7)
	jsr	g2p96_gameplay_dbuf_restore_rport_original	;c86zjf: FreeScreenBuffer/close uses original bitmap
	tst	p96gameplay_dbuf_active
	beq.w	.done
	; Even a bridge-suspended screen may still be displaying SB1.  Continue
	; through the primary-buffer handoff before FreeScreenBuffer/CloseScreen.
	jsr	g2p96_gameplay_dbuf_wait_safe
	tst	d0
	beq.w	.syncfail
	jsr	g2p96_gameplay_dbuf_wait_disp
	tst	d0
	beq.w	.syncfail
	tst	p96gameplay_dbuf_current
	beq	.primary
	move.l	p96gameplay_grbase,d0
	beq.w	.syncfail
	move.l	d0,a6
	jsr	-228(a6)
	; c86zjf: SB0 may still contain an older gameplay frame.  Clear it before
	; the close-only handoff so title/exit can never flash that stale frame.
	move.l	p96gameplay_dbuf_sb0,a0
	tst.l	a0
	beq.w	.syncfail
	move.l	SB_BitMap(a0),a2
	tst.l	a2
	beq.w	.syncfail
	jsr	g2p96_gameplay_clear_bitmap_a2
	move.l	p96gameplay_dbuf_sb0,a1
	moveq	#3,d3
.retry
	move.l	p96winprobe_screen_ptr,a0
	move.l	p96gameplay_intbase,a6
	jsr	-780(a6)
	tst	d0
	bne	.changed
	move.l	p96gameplay_grbase,a6
	jsr	-270(a6)
	dbf	d3,.retry
	bra.w	.syncfail
.changed
	clr	p96gameplay_dbuf_current
	move	#1,p96gameplay_dbuf_draw
	move	#-1,p96gameplay_dbuf_safe_pending
	move	#-1,p96gameplay_dbuf_disp_pending
	jsr	g2p96_gameplay_dbuf_wait_safe
	tst	d0
	beq	.syncfail
	jsr	g2p96_gameplay_dbuf_wait_disp
	tst	d0
	beq	.syncfail
.primary
	move	#-1,p96gameplay_dbuf_suspended
	bra	.done
.syncfail
	move	#-1,p96gameplay_dbuf_suspended
.done
	movem.l	(a7)+,d0-d3/a0-a1/a6
	rts

g2p96_gameplay_dbuf_resume
	movem.l	d0/a0-a1,-(a7)
	tst	p96gameplay_dbuf_active
	beq.w	.done
	; v2.3.1: enter_gameplay is also called after every present.
	; Only a real suspended->running transition may change draw ownership.
	tst	p96gameplay_dbuf_suspended
	beq.w	.done
	jsr	g2p96_gameplay_dbuf_restore_rport_original
	clr	p96gameplay_dbuf_suspended
	; The frozen front buffer remains current.  Render the first resumed frame
	; into the opposite buffer instead of falsely resetting ownership to SB0.
	move	p96gameplay_dbuf_current,d0
	eor	#1,d0
	move	d0,p96gameplay_dbuf_draw
	; Never manufacture acknowledgement: pending replies belong to the
	; next wait_safe/wait_disp, including a previously failed suspend.
.done
	movem.l	(a7)+,d0/a0-a1
	rts

g2p96_gameplay_dbuf_free
	movem.l	d0/a0-a1/a6,-(a7)
	jsr	g2p96_gameplay_dbuf_wait_safe
	jsr	g2p96_gameplay_dbuf_wait_disp
	jsr	g2p96_gameplay_dbuf_free_partial
	movem.l	(a7)+,d0/a0-a1/a6
	rts

g2p96_gameplay_dbuf_free_partial
	movem.l	d0/a0-a1/a6,-(a7)
	move.l	p96gameplay_intbase,d0
	beq	.no_buffers
	move.l	p96gameplay_dbuf_sb1,d0
	beq	.no_sb1
	move.l	p96winprobe_screen_ptr,a0
	move.l	d0,a1
	move.l	p96gameplay_intbase,a6
	jsr	-774(a6)	;FreeScreenBuffer
	clr.l	p96gameplay_dbuf_sb1
.no_sb1
	move.l	p96gameplay_dbuf_sb0,d0
	beq	.no_buffers
	move.l	p96winprobe_screen_ptr,a0
	move.l	d0,a1
	move.l	p96gameplay_intbase,a6
	jsr	-774(a6)
	clr.l	p96gameplay_dbuf_sb0
.no_buffers
	move.l	p96gameplay_dbuf_dispport,d0
	beq	.no_disp
	move.l	d0,a0
	move.l	4.w,a6
	jsr	-672(a6)	;DeleteMsgPort
	clr.l	p96gameplay_dbuf_dispport
.no_disp
	move.l	p96gameplay_dbuf_safeport,d0
	beq	.no_safe
	move.l	d0,a0
	move.l	4.w,a6
	jsr	-672(a6)
	clr.l	p96gameplay_dbuf_safeport
.no_safe
	clr.l	p96gameplay_dbuf_rport_orig
	clr	p96gameplay_dbuf_active
	clr	p96gameplay_dbuf_suspended
	clr	p96gameplay_dbuf_safe_pending
	clr	p96gameplay_dbuf_disp_pending
	clr	p96gameplay_dbuf_current
	move	#1,p96gameplay_dbuf_draw
	movem.l	(a7)+,d0/a0-a1/a6
	rts

g2p96_gameplay_clear_bitmap_a2
	movem.l	d0-d7/a0-a6,-(a7)
	tst.l	a2
	beq.w	.done
	jsr	g2p96_gameplay_clear_stage_black
	tst.l	d0
	beq.w	.done
	jsr	g2p96_gameplay_copy_stage_to_bitmap_a2
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

p96static_plane_bytes	ds.b	8
p96static_indexrow	ds.b	320
	even

g2p96_static_decode_index_row_fast
	; input: a4 = planar bitmap base, d6 = source y
	; output: a6 = p96static_indexrow (320 palette indices)
	movem.l	d0-d7/a0-a3/a5,-(a7)
	lea	p96static_indexrow,a6
	tst	bitplanes
	beq.w	.black_row
	move	d6,d0
	mulu	linemodw,d0
	move.l	a4,a0
	adda.l	d0,a0		; plane 0, byte x=0 for this source row
	moveq	#39,d7		; 40 planar bytes = 320 pixels
.byte_loop
	move.l	a0,a1
	lea	p96static_plane_bytes,a2
	move	bitplanes,d4
	subq	#1,d4
.load_planes
	move.b	(a1),(a2)+
	adda.l	bpmod,a1
	dbf	d4,.load_planes
	moveq	#7,d3		; pixels inside planar byte, bit 7..0
.bit_loop
	moveq	#0,d1		; resulting palette index
	moveq	#0,d5		; plane number
	lea	p96static_plane_bytes,a2
	move	bitplanes,d4
	subq	#1,d4
.plane_loop
	moveq	#0,d0
	move.b	0(a2,d5.w),d0
	btst	d3,d0
	beq.s	.no_plane_bit
	bset	d5,d1
.no_plane_bit
	addq	#1,d5
	dbf	d4,.plane_loop
	move.b	d1,(a6)+
	dbf	d3,.bit_loop
	addq.l	#1,a0
	dbf	d7,.byte_loop
	bra.s	.done
.black_row
	moveq	#0,d0
	moveq	#79,d7		; 80 longwords = 320 zero indices
.black_loop
	move.l	d0,(a6)+
	dbf	d7,.black_loop
.done
	lea	p96static_indexrow,a6
	movem.l	(a7)+,d0-d7/a0-a3/a5
	rts

p96menu_native_init_active	dc	0
p96menu_glyph_cache_state	dc	0	; -1=valid, 0=not built, 1=failed for current font
p96menu_glyph_cache_ptr	dc.l	0
p96menu_glyph_cache_font	dc.l	0
p96menu_glyph_scratch_ptr	dc.l	0
p96menu_glyph_scratch_size	dc.l	0
p96menu_glyph_decode_xbase	dc	0
p96menu_glyph_decode_ybase	dc	0
p96menu_glyph_draw_ybase	dc	0
; c87b27: obsolete standalone glyph-cache file logging permanently disabled.
; Keep the variable/routine for range-stable compatibility with mature P96 code.
p96menu_glyph_cache_name	dc.b	'P96 Bigfont glyph cache',0
p96menu_glyph_scratch_name	dc.b	'P96 Bigfont CHIP scratch',0	; 25 bytes including NUL
	even			; c87b79j: keep following 680x0 code word-aligned
p96menu_glyph_count	equ	40
p96menu_glyph_width	equ	8
p96menu_glyph_height	equ	10
p96menu_glyph_bytes	equ	80
p96menu_glyph_cache_bytes	equ	3200

; Return d0=-1 only while a real P96 title/in-game menu can use the cache.
g2p96_menu_glyph_mode_active
	movem.l	d1-d2,-(a7)
	moveq	#0,d0
	cmp	#P96DSP_MENU,p96display_state
	beq	.state_ok
	cmp	#P96DSP_TITLE,p96display_state
	bne	.done
.state_ok
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq	.done_zero
	tst	p96gameplay_persist_active
	beq	.done_zero
	cmp	#8,fontw
	bne	.done_zero
	cmp	#10,fonth
	bne	.done_zero
	jsr	g2p96_menu_glyph_cache_ensure
	tst	d0
	beq	.done_zero
	; Cache validity alone is not enough: activate the direct menu only while
	; the staged target and currently visible P96 bitmap resolve safely.
	jsr	g2p96_menu_glyph_prepare_target_c87b78d
	bra	.done
.done_zero
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d2
	rts

; Build/rebuild the cache when the loaded Bigfont pointer changes.
g2p96_menu_glyph_cache_ensure
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	font,d6
	beq.w	.fail
	cmp.l	p96menu_glyph_cache_font,d6
	bne	.rebuild
	tst	p96menu_glyph_cache_state
	bmi.w	.success
	bgt.w	.fail
.rebuild
	clr	p96menu_glyph_cache_state
	move.l	d6,p96menu_glyph_cache_font
	move.l	p96menu_glyph_cache_ptr,d0
	bne	.have_cache
	move.l	#p96menu_glyph_cache_bytes,d0
	moveq	#1,d1		; public/any RAM; final cache is CPU-only
	lea	p96menu_glyph_cache_name,a0
	jsr	allocmem_
	move.l	d0,p96menu_glyph_cache_ptr
	beq.w	.fail_mark
.have_cache
	; blit() uses global bpmod between planes, so the temporary bitmap mirrors
	; the complete current planar allocation.  It is freed immediately.
	move.l	bpmod,d0
	moveq	#0,d1
	move	bitplanes,d1
	beq.w	.fail_mark
	mulu	d1,d0
	move.l	d0,p96menu_glyph_scratch_size
	moveq	#2,d1		; MEMF_CHIP for the hardware blitter
	lea	p96menu_glyph_scratch_name,a0
	jsr	allocmem_
	move.l	d0,p96menu_glyph_scratch_ptr
	beq.w	.fail_mark
	; clear all planes before cookie-cut glyph blits
	move.l	d0,a0
	move.l	p96menu_glyph_scratch_size,d7
	lsr.l	#2,d7
	beq	.cleared
	subq.l	#1,d7
.clear_loop
	clr.l	(a0)+
	dbf	d7,.clear_loop
.cleared
	jsr	ownblitter
	moveq	#0,d7		; glyph slot 0..39
.render_loop
	cmp	#p96menu_glyph_count,d7
	bge	.render_done
	move	d7,d0
	move	d0,d1
	and	#15,d0
	lsr	#4,d1
	lsl	#4,d1		; 16px rows
	lsl	#4,d0		; 16px cells avoid shifted blit overlap/right edge
	move.l	font,a0
	move.l	p96menu_glyph_scratch_ptr,a1
	move	d7,d2
	jsr	blit
	addq	#1,d7
	bra	.render_loop
.render_done
	btst	#6,$dff002
.wait_last_blit
	btst	#6,$dff002
	bne	.wait_last_blit
	jsr	disownblitter
	; expand each 8x10 cell into one byte per palette index
	moveq	#0,d7
.decode_glyph
	cmp	#p96menu_glyph_count,d7
	bge.w	.decode_done
	move	d7,d0
	move	d0,d1
	and	#15,d0
	lsr	#4,d1
	lsl	#4,d1
	move	d1,p96menu_glyph_decode_ybase
	lsl	#4,d0		; source cell x
	move	d0,p96menu_glyph_decode_xbase
	move.l	p96menu_glyph_cache_ptr,a6
	move	d7,d0
	mulu	#p96menu_glyph_bytes,d0
	adda.l	d0,a6
	moveq	#0,d5		; glyph y
.decode_y
	cmp	#p96menu_glyph_height,d5
	bge.w	.next_glyph
	moveq	#0,d6		; glyph x
.decode_x
	cmp	#p96menu_glyph_width,d6
	bge	.next_y
	moveq	#0,d3		; palette index
	moveq	#0,d4		; plane number
.plane_loop
	cmp	bitplanes,d4
	bge	.store_index
	move.l	p96menu_glyph_scratch_ptr,a0
	move.l	bpmod,d0
	mulu	d4,d0
	adda.l	d0,a0
	move	p96menu_glyph_decode_ybase,d0
	add	d5,d0
	mulu	linemodw,d0
	adda.l	d0,a0
	move	p96menu_glyph_decode_xbase,d0
	add	d6,d0
	move	d0,d1
	lsr	#3,d0
	adda.w	d0,a0
	and	#7,d1
	moveq	#7,d0
	sub	d1,d0
	btst	d0,(a0)
	beq	.no_plane_bit
	bset	d4,d3
.no_plane_bit
	addq	#1,d4
	bra	.plane_loop
.store_index
	move.b	d3,(a6)+
	addq	#1,d6
	bra	.decode_x
.next_y
	addq	#1,d5
	bra.w	.decode_y
.next_glyph
	addq	#1,d7
	bra.w	.decode_glyph
.decode_done
	move.l	p96menu_glyph_scratch_ptr,a1
	clr.l	p96menu_glyph_scratch_ptr
	jsr	freemem_
	move	#-1,p96menu_glyph_cache_state
.success
	moveq	#-1,d0
	bra	.done
.fail_mark
	move	#1,p96menu_glyph_cache_state
.fail
	move.l	p96menu_glyph_scratch_ptr,d0
	beq	.fail_no_scratch
	move.l	d0,a1
	clr.l	p96menu_glyph_scratch_ptr
	jsr	freemem_
.fail_no_scratch
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; printmess2-compatible character -> 0..39 Bigfont slot.
; Space, backslash and apostrophe are filtered by the caller exactly like the
; original renderer.  All remaining non-special characters intentionally use
; printmess2's historic (ASCII & 31)+9 mapping, so lowercase and punctuation
; cannot silently disappear from dynamic menu strings.
g2p96_menu_glyph_calcchar
	ext	d0
	cmp	#'0',d0
	bcs	.notnum
	cmp	#'9',d0
	bhi	.notnum
	sub	#'0',d0
	rts
.notnum
	cmp	#'!',d0
	bne	.notex
	moveq	#36,d0
	rts
.notex
	cmp	#'.',d0
	bne	.notdot
	moveq	#37,d0
	rts
.notdot
	cmp	#':',d0
	bne	.notcolon
	moveq	#38,d0
	rts
.notcolon
	cmp	#127,d0
	bne	.default_map
	moveq	#39,d0
	rts
.default_map
	and	#31,d0
	add	#9,d0
	cmp	#39,d0
	bls	.mapped
	moveq	#-1,d0
.mapped
	rts

; Compatibility entry for callers of the former direct visible target setup.
; c87b78g redirects it to the staged Fast-RAM target selector below.

g2p96_menu_glyph_prepare_target
	; c87b78g compatibility entry: the former routine derived a live VRAM base
	; from BitMap.Planes[0] and BytesPerRow. All callers now receive only the
	; final-size Fast-RAM staging page and validate the visible ScreenBuffer via
	; the common selector. No bitmap internals are exposed.
	jmp	g2p96_menu_glyph_prepare_target_c87b78d

; Draw curropt directly from linear glyph indices into the active full-menu
; batch or one completed offscreen row cache.  Background restoration is owned
; by the caller so blink OFF remains a pure restore.
g2p96_menu_glyph_draw_current_row_no_restore
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq.w	.done
	tst	p96menu_batch_active
	bne	.g2c86zjj_target_ready
	jsr	g2p96_menu_glyph_prepare_target_c87b78d
	tst	d0
	beq.w	.done
	jsr	g2p96_menu_build_rgb565_lut
.g2c86zjj_target_ready
	move	curropt,d6
	move	fonth,d0
	mulu	d0,d6
	add	menuy,d6
	move	d6,p96menu_y_start
	move	d6,p96menu_glyph_draw_ybase
	move	d6,d0
	add	fonth,d0
	move	d0,p96menu_y_end
	move	curropt,d0
	lea	menustrips,a0
	move.l	0(a0,d0*8),a4
	move.l	a4,d0
	beq.w	.done
	jsr	g2v190hx_level_menu_a4
	move.l	a4,a0
	moveq	#-1,d3
.len_loop
	addq	#1,d3
	tst.b	(a0)+
	bne	.len_loop
	tst	d3
	beq.w	.done
	move	fontw,d2
	lsr	#1,d2
	move	d3,d0
	mulu	d2,d0
	move	#160,d7
	sub	d0,d7
	bpl	.x_ok
	moveq	#0,d7
.x_ok
	; Batch callers already own a complete page cache.  Row updates copy the
	; visible row first and flush it only after every glyph pixel is complete.
	clr	p96menu_cache_active
	tst	p96menu_batch_active
	bne	.cache_ready
	jsr	g2p96_menu_cache_begin_dispatch_c87b78p
	move	#-1,p96menu_cache_active
.cache_ready
	lea	p96menu_rgb565_lut,a5
	move.l	a4,a0
.char_loop
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.w	.draw_done
	cmp.b	#' ',d0
	beq.w	.advance
	cmp.b	#'\',d0
	beq.w	.advance
	cmp.b	#"'",d0
	beq.w	.advance
	jsr	g2p96_menu_glyph_calcchar
	cmp	#-1,d0
	beq.w	.advance
	move.l	p96menu_glyph_cache_ptr,a2
	mulu	#p96menu_glyph_bytes,d0
	adda.l	d0,a2
	moveq	#0,d5
.glyph_y
	cmp	#p96menu_glyph_height,d5
	bge	.advance
	move.l	a2,a3		; one complete 8-byte cached glyph row
	adda.w	#p96menu_glyph_width,a2
	move	p96menu_glyph_draw_ybase,d4
	add	d5,d4
	cmp	#0,d4
	blt	.next_glyph_y
	cmp	#240,d4
	bge	.next_glyph_y
	moveq	#0,d3
.glyph_x
	cmp	#p96menu_glyph_width,d3
	bge	.next_glyph_y
	moveq	#0,d1
	move.b	(a3)+,d1
	beq	.next_glyph_x
	move	d4,p96menu_native_py
	move	d7,d0
	add	d3,d0
	cmp	#320,d0
	bge	.next_glyph_x
	move	d0,p96menu_native_px
	move	d4,d6
	jsr	g2p96_menu_pixel_rgb565
	move	d2,p96menu_native_colour
	jsr	g2p96_menu_native_put_pixel
.next_glyph_x
	addq	#1,d3
	bra	.glyph_x
.next_glyph_y
	addq	#1,d5
	bra	.glyph_y
.advance
	add	fontw,d7
	bra.w	.char_loop
.draw_done
	tst	p96menu_batch_active
	bne	.no_flush
	clr	p96menu_cache_active
	jsr	g2p96_menu_cache_flush_dispatch_c87b78p
.no_flush
.done
	clr	p96menu_cache_active
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; c87b79y: direct-only P96 row dispatcher. The glyph routine validates the
; cache and staged target itself; failure returns safely without a planar path.
g2p96_menu_draw_current_row_best_no_restore
	jmp	g2p96_menu_glyph_draw_current_row_no_restore

g2p96_menu_restore_current_row_best
	cmp	#P96DSP_TITLE,p96display_state
	beq	.title
	jmp	g2p96_menu_native_restore_current_row
.title
	jmp	g2p96_title_menu_native_restore_current_row

p96static_direct_index_ptr	dc.l	0
p96static_direct_valid	dc	0
p96static_direct_dest_y	dc	0
p96static_direct_width	dc	0
p96static_direct_height	dc	0
p96static_direct_depth	dc	0
p96static_direct_rowbytes	dc	0
; c87b79x: native AGA/ECS may write planar pages (-1). Every P96 static
; owner uses only the direct Fast-RAM index page (zero).
p96static_direct_planar_write	dc	-1
p96static_direct_name	dc.b	'P96 direct IFF index composition',0
p96static_direct_planerows	ds.b	8*40
p96static_direct_packbytes	ds.b	8
	even

; Replacement body for showpic.  The small trampoline at the original label
; keeps every following mature GenAm/PC-relative address unchanged.
g2p96_static_showpic_native_entry
	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_native
	jmp	g2p96_static_showpic_direct_only_c87b79x
.g2c87b79x_native
	movem.l	a0-a1,-(a7)
	move.l	drawbitmap,d0
	beq.w	.legacy_clear
	move.l	d0,a1
	move.l	(a7),a0
	jsr	g2p96_static_decode_iff_dual_clear_if_active
	tst	d0
	beq.w	.legacy_clear
	; Direct decoder already cleared and filled the authoritative index page
	; without an AGA-visible blank swap. Keep the palette/db/vwait tail exact.
	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq	.direct_nopal
	jsr	g2pokepal_picture
.direct_nopal
	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active
	jmp	vwait

.legacy_clear
	clr	p96static_direct_valid
	jsr	clspic
	jsr	vwait
	movem.l	(a7),a0-a1
	tst.l	a0
	beq	.legacy_nopic
	move.l	drawbitmap,a1
	jsr	decodeiff
.legacy_nopic
	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq	.legacy_nopal
	jsr	g2pokepal_picture
.legacy_nopal
	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active
	jmp	vwait

; Replacement body for showpic_noclear.  Full 320x240 images can establish a
; fresh direct composition; smaller overlays require an already valid base.
g2p96_static_showpic_noclear_native_entry
	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_native
	jmp	g2p96_static_showpic_noclear_direct_only_c87b79x
.g2c87b79x_native
	movem.l	a0-a1,-(a7)
	tst.l	a0
	beq	.no_picture
	move.l	drawbitmap,d0
	beq	.planar_only
	move.l	d0,a1
	move.l	(a7),a0
	jsr	g2p96_static_decode_iff_dual_noclear_if_active
	tst	d0
	bne	.decoded
.planar_only
	clr	p96static_direct_valid
	move.l	(a7),a0
	move.l	drawbitmap,a1
	jsr	decodeiff
.decoded
.no_picture
	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq	.nopal
	jsr	g2pokepal_picture
.nopal
	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active
	jmp	vwait

; Return d0=-1 only while a direct composition buffer is available for the
; current P96 title/intermission owner.
g2p96_static_direct_ensure_buffer
	movem.l	d1-d3/a0/a6,-(a7)
	moveq	#0,d0
	cmp	#P96DSP_TITLE,p96display_state
	beq	.state_ok
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne	.done
.state_ok
	tst	p96gameplay_persist_active
	beq	.done
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq	.done
	move.l	p96static_direct_index_ptr,d0
	bne	.success
	move.l	#320*240,d0
	moveq	#1,d1
	lea	p96static_direct_name,a0
	jsr	allocmem_
	move.l	d0,p96static_direct_index_ptr
	beq	.fail
.success
	moveq	#-1,d0
	bra	.done
.fail
	clr	p96static_direct_valid
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d3/a0/a6
	rts

; Clear the authoritative direct index page and, only for native/fallback
; states, the compatibility draw bitmap. c87b79u skips planar clear/write for
; normal P96 TITLE, ABOUT and INTERMISSION ownership.
g2p96_static_decode_iff_dual_clear_if_active
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a5
	move.l	a1,a4
	jsr	g2p96_static_direct_ensure_buffer
	tst	d0
	beq.w	.fail
	jsr	g2p96_static_select_planar_write_c87b79u
	; Clear planar compatibility memory only for native/non-CLUT fallback.
	; Normal P96 TITLE/ABOUT/INTERMISSION owns the index page directly.
	tst	p96static_direct_planar_write
	beq.s	.planar_cleared
	move.l	a4,a0
	move.l	bmapmem,d7
	lsr.l	#2,d7
	beq	.planar_cleared
	subq.l	#1,d7
.clear_planar
	clr.l	(a0)+
	dbf	d7,.clear_planar
.planar_cleared
	move.l	p96static_direct_index_ptr,a0
	moveq	#0,d0
	moveq	#79,d7		; 80 longwords per row
	move.w	#239,d6
.clear_index_row
	moveq	#79,d7
.clear_index_long
	move.l	d0,(a0)+
	dbf	d7,.clear_index_long
	dbf	d6,.clear_index_row
	move	#-1,p96static_direct_valid
	tst.l	a5
	beq	.blank_success
	move.l	a5,a0
	move.l	a4,a1
	moveq	#0,d6
	jsr	g2p96_static_decode_iff_dual_common
	tst	d0
	beq	.fail
.blank_success
	; c87b79x: no P96 planar mirror exists and native dual writes are already
	; complete when this point is reached. No deferred sync state remains.
	moveq	#-1,d0
	bra	.done
.fail
	clr	p96static_direct_valid
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Noclear decode.  A complete 320x240 source may establish a fresh direct base;
; a smaller source is accepted only when it can overlay an existing valid base.
g2p96_static_decode_iff_dual_noclear_if_active
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a5
	move.l	a1,a4
	jsr	g2p96_static_direct_ensure_buffer
	tst	d0
	beq	.fail
	jsr	g2p96_static_select_planar_write_c87b79u
	tst.l	a5
	beq	.fail
	tst	p96static_direct_valid
	bne	.have_base
	cmp	#320,(a5)
	bne	.fail
	cmp	#240,2(a5)
	blo	.fail
	; Full replacement: initialise untouched/clipped areas to black.
	move.l	p96static_direct_index_ptr,a0
	moveq	#0,d0
	move.w	#239,d6
.clear_row
	moveq	#79,d7
.clear_long
	move.l	d0,(a0)+
	dbf	d7,.clear_long
	dbf	d6,.clear_row
.have_base
	move.l	a5,a0
	move.l	a4,a1
	moveq	#0,d6
	jsr	g2p96_static_decode_iff_dual_common
	tst	d0
	beq	.fail
	move	#-1,p96static_direct_valid
	; c87b79x: no P96 planar mirror exists and native dual writes are already
	; complete when this point is reached. No deferred sync state remains.
	moveq	#-1,d0
	bra	.done
.fail
	; c87b79x: no planar fallback exists. Caller chooses a direct black/safe tail.
	clr	p96static_direct_valid
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; The title brush is decoded twice by legacy code (showbitmap and drawbitmap).
; Update the direct composition during the showbitmap decode only; the second
; call remains the original planar compatibility update.
g2p96_static_decode_gloombrush_best
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	showbitmap,d0
	beq	.check_drawbitmap
	move.l	a1,d1
	sub.l	d0,d1
	bmi	.check_drawbitmap
	move.l	bpmod,d2
	cmp.l	d2,d1
	bhs	.check_drawbitmap
	tst	p96static_direct_valid
	beq	.fallback_saved
	moveq	#0,d2
	move	linemodw,d2
	beq	.fallback_saved
	divu	d2,d1
	and.l	#$0000ffff,d1
	move	d1,p96static_direct_dest_y
	; Restore original source/destination registers, then re-apply the derived Y.
	movem.l	(a7),d0-d7/a0-a6
	move	p96static_direct_dest_y,d6
	jsr	g2p96_static_decode_iff_dual_common
	tst	d0
	beq	.fallback_live
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.check_drawbitmap
	; The legacy routine immediately decodes the same brush into drawbitmap.
	; Preserve the direct composition created by the preceding showbitmap pass.
	move.l	drawbitmap,d0
	beq	.fallback_saved
	move.l	a1,d1
	sub.l	d0,d1
	bmi	.fallback_saved
	move.l	bpmod,d2
	cmp.l	d2,d1
	bhs	.fallback_saved
	movem.l	(a7),d0-d7/a0-a6
	jsr	decodeiff
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.fallback_saved
	movem.l	(a7),d0-d7/a0-a6
.fallback_live
	clr	p96static_direct_valid
	jsr	decodeiff
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Common ByteRun1 decoder.
; in: a0=trimmed IFF, a1=planar destination at target Y, d6=direct target Y.
; out: d0=-1 success.  Source width is the same 8-pixel multiple expected by
; the original decodeiff routine; height is clipped to the remaining 240 rows.
g2p96_static_decode_iff_dual_common
	movem.l	d1-d7/a0-a6,-(a7)
	move	d6,p96static_direct_dest_y
	move.l	a0,a5		; source header/data
	move.l	a1,a4		; planar target base at destination Y
	moveq	#0,d0
	move	(a5)+,d0
	beq.w	.fail
	cmp	#320,d0
	bhi.w	.fail
	move	d0,p96static_direct_width
	lsr	#3,d0
	beq.w	.fail
	cmp	#40,d0
	bhi.w	.fail
	move	d0,p96static_direct_rowbytes
	moveq	#0,d1
	move	(a5)+,d1
	beq.w	.fail
	moveq	#0,d2
	move	p96static_direct_dest_y,d2
	cmp	#240,d2
	bhs.w	.fail
	move	#240,d3
	sub	d2,d3
	cmp	d3,d1
	bls	.height_ok
	move	d3,d1
.height_ok
	move	d1,p96static_direct_height
	moveq	#0,d2
	move	(a5)+,d2
	beq.w	.fail
	cmp	#8,d2
	bhi.w	.fail
	cmp	bitplanes,d2
	bhi.w	.fail
	move	d2,p96static_direct_depth
	addq.l	#6,a5		; skip remaining trimmed-IFF header
	moveq	#0,d7		; row number
.row_loop
	cmp	p96static_direct_height,d7
	bge.w	.success
	; Clear eight 40-byte scratch plane rows.
	lea	p96static_direct_planerows,a2
	moveq	#0,d0
	moveq	#79,d6
.clear_scratch
	move.l	d0,(a2)+
	dbf	d6,.clear_scratch
	moveq	#0,d6		; source plane number
.plane_decode_loop
	cmp	p96static_direct_depth,d6
	bge	.copy_planar_rows
	lea	p96static_direct_planerows,a2
	move	d6,d0
	mulu	#40,d0
	adda.l	d0,a2
	move	p96static_direct_rowbytes,d4	; remaining output bytes
.run_loop
	tst	d4
	ble	.next_plane
	moveq	#0,d3
	move.b	(a5)+,d3
	ext.w	d3
	bmi	.repeat_run
	addq	#1,d3		; literal count
	cmp	d4,d3
	bls	.literal_count_ok
	move	d4,d3
.literal_count_ok
	sub	d3,d4
.literal_copy
	move.b	(a5)+,(a2)+
	subq	#1,d3
	bne	.literal_copy
	bra	.run_loop
.repeat_run
	cmp	#-128,d3
	beq	.run_loop
	neg	d3
	addq	#1,d3		; repeat count
	moveq	#0,d2
	move.b	(a5)+,d2
	cmp	d4,d3
	bls	.repeat_count_ok
	move	d4,d3
.repeat_count_ok
	sub	d3,d4
.repeat_copy
	move.b	d2,(a2)+
	subq	#1,d3
	bne	.repeat_copy
	bra	.run_loop
.next_plane
	addq	#1,d6
	bra	.plane_decode_loop

.copy_planar_rows
	; c87b79u: normal P96 static paths consume scratch planes only to build
	; final index bytes. Do not mirror them into planar pages.
	tst	p96static_direct_planar_write
	beq.w	.build_index_row
	moveq	#0,d6
.copy_plane_loop
	cmp	p96static_direct_depth,d6
	bge	.build_index_row
	lea	p96static_direct_planerows,a2
	move	d6,d0
	mulu	#40,d0
	adda.l	d0,a2
	move.l	a4,a3
	move	d7,d0
	mulu	linemodw,d0
	adda.l	d0,a3
	move	d6,d0
	mulu	bpmodw,d0
	adda.l	d0,a3
	move	p96static_direct_rowbytes,d4
	subq	#1,d4
.copy_plane_bytes
	move.b	(a2)+,(a3)+
	dbf	d4,.copy_plane_bytes
	addq	#1,d6
	bra	.copy_plane_loop

.build_index_row
	move.l	p96static_direct_index_ptr,a3
	moveq	#0,d0
	move	p96static_direct_dest_y,d0
	add	d7,d0
	mulu	#320,d0
	adda.l	d0,a3
	moveq	#0,d6		; planar byte X
.byte_x_loop
	cmp	p96static_direct_rowbytes,d6
	bge	.next_row
	moveq	#7,d5		; bit 7..0
.bit_x_loop
	moveq	#0,d1		; palette index
	moveq	#0,d4		; plane
.plane_bit_loop
	cmp	p96static_direct_depth,d4
	bge	.store_index
	lea	p96static_direct_planerows,a2
	move	d4,d0
	mulu	#40,d0
	adda.l	d0,a2
	moveq	#0,d2
	move.b	0(a2,d6.w),d2
	btst	d5,d2
	beq	.no_bit
	bset	d4,d1
.no_bit
	addq	#1,d4
	bra	.plane_bit_loop
.store_index
	move.b	d1,(a3)+
	dbf	d5,.bit_x_loop
	addq	#1,d6
	bra	.byte_x_loop
.next_row
	addq	#1,d7
	bra.w	.row_loop
.success
	move	#-1,p96static_direct_valid
	moveq	#-1,d0
	bra	.done
.fail
	clr	p96static_direct_valid
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Row selector used by the existing RGB565/scaling loops.

; Keep c86zjg's fallback log truthful: direct rows have their own c86zjl marker.
g2p96_static_decode_index_row_best
	tst	p96static_direct_valid
	beq	.planar
	move.l	p96static_direct_index_ptr,d0
	beq	.planar
	move.l	d0,a6
	move	d6,d0
	mulu	#320,d0
	adda.l	d0,a6
	rts
.planar
	cmp	#2,g2display_mode
	bne.s	.native_planar
	; c87b79x: catastrophic missing direct source. Return a black logical row,
	; never dereference the removed showbitmap.
	lea	p96static_indexrow,a6
	moveq	#0,d0
	moveq	#79,d1
.g2c87b79x_black_row
	move.l	d0,(a6)+
	dbf	d1,.g2c87b79x_black_row
	lea	p96static_indexrow,a6
	rts
.native_planar
	jmp	g2p96_static_decode_index_row_fast

; c87b79x: direct typewriter keeps the authoritative index page current.
; The old final planar reconstruction/present guard is now a direct no-op tail.
g2p96_static_present_intermission_text_native_guard
	tst	p96static_direct_valid
	beq.s	.done
	jmp	g2p96_static_present_intermission_text_skip_if_active
.done	rts

p96inter_typewriter_active	dc	0
p96inter_visible_base	dc.l	0	;c87b78g legacy-reserved, never a live VRAM pointer
p96inter_visible_bpr	dc.l	0	;c87b78g legacy-reserved, never a live bitmap stride
p96inter_glyph_y	dc	0	;c87b78g logical 320x240 Y of the completed glyph
g2p96_intermission_native_typewriter_prepare
	movem.l	d1-d7/a0-a6,-(a7)
	clr	p96inter_typewriter_active
	clr.l	p96inter_visible_base	;c87b78g never cache a visible VRAM address
	clr.l	p96inter_visible_bpr
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.w	.fail
	tst	p96gameplay_persist_active
	beq.w	.fail
	tst	p96static_direct_valid
	beq.w	.fail
	move.l	p96static_direct_index_ptr,d0
	beq.w	.fail
	move.l	p96static_rgbbufptr,d0
	beq.w	.fail
	cmp	#8,fontw
	bne.w	.fail
	cmp	#10,fonth
	bne.w	.fail
	jsr	g2p96_menu_glyph_cache_ensure
	tst	d0
	beq.w	.fail
	; c87b78g: prepare only the final-size Fast-RAM page and prove that a
	; visible ScreenBuffer can be selected. No bitmap structure is inspected.
	jsr	g2p96_menu_glyph_prepare_target_c87b78d
	tst	d0
	beq.w	.fail
	moveq	#0,d0
	move	p96target_width,d0
	add.l	d0,d0
	move.l	d0,p96static_rgbbpr
	jsr	g2p96_static_build_font_rgb565_lut
	clr	p96menu_batch_active
	clr	p96menu_cache_active
	move	#-1,p96inter_typewriter_active
	moveq	#-1,d0
	bra.s	.done
.fail
	; c87b79x: direct dependencies failed. Complete timing safely without
	; attempting a removed planar text fallback.
	clr	pdelay
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Called immediately after printmess2 blits one real Bigfont character.
; a4 points one byte past that character, d7=X and d6=Y remain intact.

g2p96_intermission_native_typewriter_char
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96inter_typewriter_active
	beq.w	.done
	moveq	#0,d0
	move.b	-1(a4),d0
	cmp.b	#' ',d0
	beq.w	.done
	cmp.b	#'\',d0
	beq.w	.done
	cmp.b	#"'",d0
	beq.w	.done
	jsr	g2p96_menu_glyph_calcchar
	cmp	#-1,d0
	beq.w	.done
	move.l	p96menu_glyph_cache_ptr,a2
	mulu	#p96menu_glyph_bytes,d0
	adda.l	d0,a2
	move	d7,d4		; logical glyph X
	move	d6,d5		; logical glyph Y
	move	d5,p96inter_glyph_y
	moveq	#0,d3		; glyph row
.row
	cmp	#p96menu_glyph_height,d3
	bge.w	.publish
	moveq	#0,d2		; glyph column
.col
	cmp	#p96menu_glyph_width,d2
	bge	.next_row
	moveq	#0,d1
	move.b	(a2)+,d1
	beq	.next_col
	; c87b10: map Bigfont source colours 1..3 to three separate isolated
	; yellow shades instead of flattening every non-zero pixel to one colour.
	tst	g2inter_yellow_text_active
	beq	.g2c87b10_keep_glyph_index
	cmp	#3,d1
	bls	.g2c87b10_glyph_level_ok
	moveq	#3,d1
.g2c87b10_glyph_level_ok
	subq	#1,d1
	add	d1,d1
	lea	g2inter_yellow_text_indices,a0
	move	0(a0,d1.w),d1
	tst	d1
	bmi	.next_col
.g2c87b10_keep_glyph_index
	move	d4,d0
	add	d2,d0
	cmp	#320,d0
	bge	.next_col
	tst	d0
	blt.s	.next_col
	move	d5,d7
	add	d3,d7
	cmp	#240,d7
	bge.s	.next_col
	tst	d7
	blt.s	.next_col
	; Keep the linear source-of-truth composition current.
	move.l	p96static_direct_index_ptr,a0
	move	d7,d6
	mulu	#320,d6
	adda.l	d6,a0
	move.b	d1,0(a0,d0.w)
	; Convert this exact font palette index once.
	lea	p96static_rgb565_lut,a5
	move	d1,d6
	add	d6,d6
	move	0(a5,d6.w),d6
	move	d6,p96menu_native_colour
	move	d0,p96menu_native_px
	move	d7,p96menu_native_py
	; c87b78g: update only the final-size Fast-RAM RGB565 composition.
	; Visible publication happens once after all pixels of this glyph are ready.
	move.l	p96static_rgbbufptr,d6
	move.l	d6,p96menu_native_dstbase
	move.l	p96static_rgbbpr,d6
	move.l	d6,p96menu_native_bpr
	jsr	g2p96_menu_native_put_pixel
.next_col
	addq	#1,d2
	bra	.col
.next_row
	addq	#1,d3
	bra.w	.row
.publish
	jsr	g2p96_intermission_publish_glyph_band_c87b78g
.done
	; Keep later staged renderers pointed at Fast RAM even after a failed copy.
	move.l	p96static_rgbbufptr,d0
	move.l	d0,p96menu_native_dstbase
	move.l	p96static_rgbbpr,d0
	move.l	d0,p96menu_native_bpr
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Publish the completed glyph atomically as a full-width physical row band.
; Copying the band instead of individual pixels keeps geometry simple and exact
; for 320/428/640/854-wide, 240/256/480/512-high and 5:4-centred targets. The
; transfer remains small (10 or 20 rows) and uses the common official lock path.
g2p96_intermission_publish_glyph_band_c87b78g
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96inter_typewriter_active
	beq.w	.done
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	move.l	p96static_rgbbpr,d4
	beq.w	.done

	; Clip the logical 320x240 glyph band before converting it to target Y.
	move	p96inter_glyph_y,d0	; logical start
	move	d0,d1
	add	#p96menu_glyph_height,d1	; logical end (exclusive)
	tst	d0
	bpl.s	.start_ok
	moveq	#0,d0
.start_ok
	cmp	#240,d1
	ble.s	.end_ok
	move	#240,d1
.end_ok
	cmp	d0,d1
	ble.w	.done
	sub	d0,d1		; logical height

	; Native 5:4 pages centre the 240-line composition at Y=8 (Y=16 HIRES).
	tst	g2p96_oneone_mode
	beq.s	.no_5x4
	addq	#8,d0
.no_5x4
	; Every current HIRES P96 target doubles logical rows.
	tst	g2p96_hires_mode
	beq.s	.physical_ready
	add	d0,d0
	add	d1,d1
.physical_ready
	tst	d1
	beq.w	.done
	moveq	#0,d2
	move	d0,d2
	moveq	#0,d3
	move	d1,d3
	add.l	d3,d2
	moveq	#0,d5
	move	p96target_height,d5
	cmp.l	d5,d2
	bhi.w	.done

	; The staging page already contains final horizontal scaling/centering.
	; Publishing the complete row band therefore needs no mode-specific X math.
	move.l	p96static_rgbbufptr,p96safe_rect_src_ptr
	move.l	d4,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d4,p96safe_rect_rowbytes
	move	d0,p96safe_rect_src_y
	move	d0,p96safe_rect_dst_y
	move	d1,p96safe_rect_height
	jsr	g2p96_copy_ram_rect_to_visible_c87b78d
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Native characters already updated the index page, Fast-RAM RGB565 page and
; visible P96 row bands. The old full planar present remains only as fallback.
g2p96_intermission_native_typewriter_finish
	movem.l	d0-d1,-(a7)
	tst	p96inter_typewriter_active
	beq.s	.fallback
	clr	p96inter_typewriter_active
	move	#-1,p96static_direct_valid
	bra.s	.done
.fallback
	jsr	g2p96_static_present_intermission_text_native_guard
.done
	movem.l	(a7)+,d0-d1
	rts

g2display_tokens_scan
	movem.l	d0-d7/a0-a4,-(a7)
	move.w	d1,d7

g2tok_skip_sep
	move.b	(a0),d0
	beq	g2tok_done
	cmp.b	#10,d0
	beq	g2tok_done
	cmp.b	#13,d0
	beq.s	g2tok_advance_sep
	cmp.b	#' ',d0
	beq.s	g2tok_advance_sep
	cmp.b	#9,d0
	beq.s	g2tok_advance_sep
	cmp.b	#',',d0
	bne.s	g2tok_start
g2tok_advance_sep
	addq.l	#1,a0
	bra.s	g2tok_skip_sep

g2tok_start
	move.l	a0,a2
	moveq	#0,d6
g2tok_measure
	move.b	(a0),d0
	beq.s	g2tok_compare
	cmp.b	#10,d0
	beq.s	g2tok_compare
	cmp.b	#13,d0
	beq.s	g2tok_compare
	cmp.b	#' ',d0
	beq.s	g2tok_compare
	cmp.b	#9,d0
	beq.s	g2tok_compare
	cmp.b	#',',d0
	beq.s	g2tok_compare
	addq.l	#1,a0
	addq	#1,d6
	bra.s	g2tok_measure

g2tok_compare
	cmp #9,d6
	bne.s .not_single
	move.l a2,a3
	lea g2tok_p96single,a4
	jsr g2tok_equal
	tst d0
	beq.s .not_single
	move.w #-1,g2p96_single_buffer
	bra g2tok_next
.not_single
	; c87b70l: variable-length assignment token. The helper returns nonzero
	; whenever the P96MODEID= prefix was consumed, valid or malformed.
	jsr	g2tok_try_p96modeid
	tst	d0
	bne	g2tok_next
	cmp	#3,d6
	bne.s	g2tok_len4
	move.l	a2,a3
	lea	g2tok_aga(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_aga
	move.l	a2,a3
	lea	g2tok_ecs(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_ecs
	move.l	a2,a3
	lea	g2tok_p96(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_p96
	move.l	a2,a3
	lea	g2tok_fps(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_fps
	move.l	a2,a3
	lea	g2tok_oneone(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_oneone
	bra	g2tok_next

g2tok_len4
	cmp	#4,d6
	bne.s	g2tok_len5
	move.l	a2,a3
	lea	g2tok_wide(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_wide
	bra	g2tok_next

g2tok_len5
	cmp	#5,d6
	bne.s	g2tok_len7
	move.l	a2,a3
	lea	g2tok_hires(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_hires
	move.l	a2,a3
	lea	g2tok_stock(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_stock
	bra	g2tok_next

g2tok_len7
	cmp	#7,d6
	bne	g2tok_next
	move.l	a2,a3
	lea	g2tok_stretch(pc),a4
	jsr	g2tok_equal
	tst	d0
	bne	g2tok_set_stretch
	bra	g2tok_next

g2tok_set_aga
	move	#1,g2display_mode
	move	d7,g2display_source
	bra	g2tok_next

g2tok_set_ecs
	move	#3,g2display_mode
	move	d7,g2display_source
	bra	g2tok_next

g2tok_set_p96
	move	#2,g2display_mode
	move	d7,g2display_source
	bra	g2tok_next

g2tok_set_fps
	clr	g2fps_enabled	; Step 3b: always start OFF, even with legacy FPS token
	bra	g2tok_next

g2tok_set_stock
	move	#-1,g2stock_enabled	;c87b67: runtime overlay; saved cfg values stay untouched
	bra	g2tok_next

g2tok_set_hires
	move	#-1,g2p96_hires_mode
	bra	g2tok_next

g2tok_set_stretch
	move	#-1,g2p96_stretch_mode
	clr	g2p96_wide_mode
	clr	g2p96_oneone_mode
	bra	g2tok_next

g2tok_set_wide
	move	#-1,g2p96_wide_mode
	clr	g2p96_stretch_mode
	clr	g2p96_oneone_mode
	bra	g2tok_next

g2tok_set_oneone
	move	#-1,g2p96_oneone_mode
	clr	g2p96_wide_mode
	clr	g2p96_stretch_mode

g2tok_next
	bra	g2tok_skip_sep

g2tok_done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

; a3 = token, a4 = uppercase reference, d6 = length
; d0 = -1 equal, 0 different
g2tok_equal
	movem.l	d1-d3/a3-a4,-(a7)
	move.w	d6,d3
	subq	#1,d3
g2tok_equal_loop
	move.b	(a3)+,d0
	jsr	g2display_upper_d0
	move.b	(a4)+,d1
	cmp.b	d1,d0
	bne.s	g2tok_not_equal
	dbf	d3,g2tok_equal_loop
	moveq	#-1,d0
	bra.s	g2tok_equal_done
g2tok_not_equal
	moveq	#0,d0
g2tok_equal_done
	movem.l	(a7)+,d1-d3/a3-a4
	rts

g2tok_aga	dc.b	'AGA'
g2tok_ecs	dc.b	'ECS'
g2tok_p96	dc.b	'P96'
g2tok_fps	dc.b	'FPS'
g2tok_oneone	dc.b	'---'
g2tok_wide	dc.b	'----'
g2tok_hires	dc.b	'-----'
g2tok_stock	dc.b	'STOCK'
g2tok_stretch	dc.b	'-------'
	even

; Cache chipset without showing any requester.
g2chipset_detect
	movem.l	d0-d2/a1/a6,-(a7)
	clr	g2chipset_aga
	move.l	4.w,a6
	lea	grname,a1
	jsr	-408(a6)
	move.l	d0,d2
	beq.s	g2chipset_detect_done
	move.l	d0,a6
	btst	#2,$ec(a6)
	bne.s	g2chipset_is_aga
	move.w	$dff07c,d0
	and.w	#$00ff,d0
	cmp.w	#$00f8,d0
	bne.s	g2chipset_close
g2chipset_is_aga
	move	#-1,g2chipset_aga
g2chipset_close
	move.l	d2,a1
	move.l	4.w,a6
	jsr	-414(a6)
g2chipset_detect_done
	movem.l	(a7)+,d0-d2/a1/a6
	rts

; ECS1 runtime display synchronization.
; g2display_mode: 1=AGA, 2=P96, 3=ECS.
; The old renderer still selects its 8-plane or 6-plane setup through the
; runtime word 'aga', so update that word after ToolType/CLI parsing and before
; initmain.  P96 options are ignored in ECS mode and the fixed target remains
; the original 320x240 EHB screen.
g2displaymode_apply_runtime
	movem.l	d0,-(a7)
	jsr	g2p96_patch_host_labels_c87b78s	;c87b78s: 256-colour core + host-aware fallback labels
	nop			;keep the former MOVE.W #imm,abs.l footprint
	move	g2display_mode,d0
	cmp	#3,d0
	bne.w	.done
	clr	aga			;ECS selects 6 planes + EHB + ECS palettes/C2P
	clr	g2p96_hires_mode
	clr	g2p96_stretch_mode
	clr	g2p96_wide_mode
	clr	g2p96_oneone_mode
	move	#320,p96target_width
	move	#240,p96target_height
	clr	p96target_mode
	clr	p96display_state
	clr	p96display_prev_state
	clr	p96display_event
.done
	movem.l	(a7)+,d0
	rts

; c87b78s validation:
; - ECS is valid on OCS/ECS and AGA hardware.
; - P96 is valid on either chipset family because its selected RTG screen is
;   preflighted before initmain and the legacy 8-plane buffers stay offscreen.
; - Only the native DISPLAY=AGA path requires physical AGA hardware.
g2displaymode_validate
	movem.l	d1-d7/a0-a6,-(a7)
	clr	d7			;0 = continue, -1 = abort
	move	g2display_mode,d0
	cmp	#1,d0
	bne.w	.done			;ECS and P96 are valid on non-AGA hosts
	tst	g2chipset_aga
	bne.w	.done
	moveq	#-1,d7
	jsr	g2early_show_noaga_notice
.done
	move	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts


; Optional P96 override; other boards remain double buffered by default.
g2p96_single_buffer dc.w 0
g2tok_p96single dc.b 'P96SINGLE'
 even

; c87b82: identify the board of the actual opened P96 screen.
; Return d0=-1 for exact IndiECS or csgfx names (case-insensitive).
; csgfx is the shared CS-Lab Warp RTG driver, not a ModeID or filename test.
; Keep the explicit P96SINGLE preference separate: reevaluate on every open.
; Unknown boards or missing attributes retain the normal double-buffer path.
g2p96_auto_single_board
 movem.l d1-d2/a0-a2/a6,-(a7)
 cmp #2,g2display_mode
 bne .no
 tst.l p96base
 beq .no
 move.l p96gameplay_grbase,d0
 beq .no
 move.l d0,a6
 move.l p96winprobe_screen_ptr,d0
 beq .no
 move.l d0,a0
 lea 44(a0),a0
 jsr -792(a6) ; GetVPModeID(Screen.ViewPort)
 cmp.l #-1,d0
 beq .no
 move.l d0,d2
 move.l p96base,a6
 moveq #6,d1 ; P96IDA_ISP96
 jsr -84(a6)
 tst.l d0
 beq .no
 move.l d2,d0
 moveq #9,d1 ; P96IDA_BOARDNAME
 jsr -84(a6)
 tst.l d0
 beq .no
 cmp.l #-1,d0
 beq .no
 move.l d0,a2 ; retain the board-name pointer for the second exact match
 move.l a2,a0
 lea g2p96_indiecs_name,a1
 bsr.s .match_name
 tst.l d0
 bne.s .done
 move.l a2,a0
 lea g2p96_csgfx_name,a1
 bsr.s .match_name
 bra.s .done
.no
 moveq #0,d0
.done
 movem.l (a7)+,d1-d2/a0-a2/a6
 rts

; a0=driver name, a1=lowercase expected name. Never accept a partial name.
.match_name
 move.b (a1)+,d1
 beq.s .name_end
 move.b (a0)+,d0
 or.b #$20,d0
 cmp.b d1,d0
 bne.s .name_no
 bra.s .match_name
.name_end
 tst.b (a0) ; exact name, do not accept prefixes or suffixes
 bne.s .name_no
 moveq #-1,d0
 rts
.name_no
 moveq #0,d0
 rts
g2p96_indiecs_name dc.b 'indiecs',0
g2p96_csgfx_name dc.b 'csgfx',0
 even
