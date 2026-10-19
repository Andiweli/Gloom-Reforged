; =============================================================================
; 2.5.0: menu fixes (appended module, game build only).
; P96 optoff null-page guard and the v3.0 menu flicker fixes (c87b86,
; stages 6 and 1), ported to Gloom Reforged 2.4.0 / 2.5.0. Native AGA/ECS: the ESC menu, option refreshes and CONTINUE are
; composed in the hidden page and shown together with their palette. P96:
; option refreshes publish the finished frame once, row updates no longer
; blank the row first, and unchanged menu pens are reused.
;
; Every hook into gr_02..gr_21 is a same-size instruction exchange, so all
; existing labels and the audited modulo-16 phases stay unchanged. This
; module references older code only through absolute operands.
; =============================================================================

; -----------------------------------------------------------------------------
; Legacy optoff guard (called from gr_09 optoff, replaces BSR ownblitter and
; MOVE curropt(pc),d6).
;
; DISPLAY=P96 owns no planar pages: initmenu2 stores a null strip pointer and
; showbitmap/menubmap stay zero. If the glyph cache or the staged target is
; unavailable, optoff used to fall through to the planar blit and copied from
; Chip address 0 into low Chip RAM. The guard performs the original two
; instructions when a strip and a planar page exist. Otherwise it drops the
; return address and completes optoff without touching the blitter, exactly
; like the original tail after its blit.
; -----------------------------------------------------------------------------
g2menu_optoff_legacy_guard
	cmp	#2,g2display_mode
	beq.s	.skip
	tst.l	menubmap
	beq.s	.skip
	move	curropt,d6
	lea	menustrips,a0
	tst.l	4(a0,d6.w*8)
	beq.s	.skip
	jsr	ownblitter
	move	curropt,d6
	rts
.skip
	addq.l	#4,a7		; return directly to optoff's caller
	move	#13,flashdelay
	clr	p96menu_native_selected
	jsr	g2p96_menu_current_row_present
	rts
	even

; =============================================================================
; Stage 1: menu flicker fixes.
; =============================================================================

; -----------------------------------------------------------------------------
; Native AGA/ECS page-flip control.
;
; db swaps showbitmap/drawbitmap and asks the display backend (todb) to show
; the new page. While the hold is armed the backend is replaced by a stub that
; swaps the two pointers back: renderers keep drawing into the hidden page and
; the visible page with its palette stays on screen.
; -----------------------------------------------------------------------------
g2menu_db_hold_on
	move.l	todb,g2menu_saved_todb
	move.l	#g2menu_db_hold_stub,todb
	rts

g2menu_db_hold_off
	move.l	g2menu_saved_todb,todb
	rts

g2menu_db_hold_stub
	movem.l	showbitmap,d0-d1
	exg	d0,d1
	movem.l	d0-d1,showbitmap
	rts

; Show drawbitmap and install the palette in a1 (0 = keep) in the same frame.
; Both requests are made while the beam is inside the visible area, so the
; bitmap switch and the new colours take effect at the same vertical blank.
g2menu_flip_with_palette
	move.l	a1,-(a7)
	jsr	vwait
	move.l	#300000,d2	; bounded: never hang on an unexpected beam counter
.beam
	move.l	$dff004,d0
	lsr.l	#8,d0
	and.w	#$01ff,d0
	cmp.w	#80,d0
	blo.s	.next
	cmp.w	#200,d0
	blo.s	.ready
.next
	subq.l	#1,d2
	bne.s	.beam
.ready
	jsr	db
	move.l	(a7)+,a1
	move.l	a1,d0
	beq.s	.done
	jsr	pokepal
.done
	rts

; Release the planar menu strips exactly like finitmenu, without its clspic
; black frame and without changing the palette.
g2menu_free_strips
	movem.l	d0-d2/a0-a1/a5,-(a7)
	lea	menustrips,a5
	move	numopts,d2
	subq	#1,d2
	bmi.s	.done
.loop
	addq.l	#4,a5
	move.l	(a5)+,d0
	beq.s	.next
	move.l	d0,a1
	clr.l	-4(a5)
	freemem	menustrip
.next
	dbf	d2,.loop
.done
	movem.l	(a7)+,d0-d2/a0-a1/a5
	rts

; -----------------------------------------------------------------------------
; ESC menu grey backdrop (entry jump from g2v190aj_grey_menu_backdrop, gr_11).
; Same result as the original, but the grey page is converted off screen and
; then shown together with the grey palette. The original installed the grey
; palette first, so the coloured game frame was visible in grey colours while
; the C2P ran.
; -----------------------------------------------------------------------------
g2menu_grey_backdrop
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#2,g2display_mode
	beq.w	.done
	move.l	lastpal,g2v190aj_saved_lastpal
	jsr	g2v190aj_build_grey_palette
	jsr	g2v190aj_build_grey_lut
	jsr	g2v190aj_apply_grey_lut
	jsr	g2menu_db_hold_on
	tst	twowins
	beq.s	.one
	jsr	g2twop_restore_coloffs
	jsr	g2twop_menu_full_c2p
	bra.s	.c2p_done
.one
	jsr	doc2p
.c2p_done
	jsr	g2menu_db_hold_off
	lea	g2v190aj_grey_pal,a1
	jsr	g2menu_flip_with_palette
	jsr	vwait
	jsr	vwait		; ChangeVPBitMap has completed, the old page is hidden
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; -----------------------------------------------------------------------------
; In-game option refresh, native AGA/ECS (called from the .aga_refresh_full
; branch of g2p96_ingame_menu_floorceil_live_refresh, gr_12).
;
; The new gameplay frame, its grey conversion and the complete menu are built
; in the hidden page while the old grey menu stays visible. initmenu2's own db
; then shows the finished page. The grey menu palette is never touched, so
; neither a black frame nor a recoloured frame becomes visible.
; -----------------------------------------------------------------------------
g2menu_native_live_refresh
	move	curropt,-(a7)
	jsr	g2menu_refresh_wait_blit
	cmp	#2,g2display_mode
	beq.w	.legacy
	jsr	g2menu_db_hold_on
	jsr	predrawall
	jsr	g2menu_refresh_wait_blit
	jsr	g2v190aj_build_grey_lut
	jsr	g2v190aj_apply_grey_lut
	tst	twowins
	beq.s	.one
	jsr	g2twop_restore_coloffs
	jsr	g2twop_menu_full_c2p
	bra.s	.grey_done
.one
	jsr	doc2p
.grey_done
	jsr	g2menu_db_hold_off
	jsr	g2menu_refresh_wait_blit
	jsr	g2menu_free_strips
	; initmenu2 first copies showbitmap to drawbitmap. With both pointing at
	; the new page that copy changes nothing and the whole menu is composed
	; off screen; initmenu2's db then shows it and hands back the old page.
	move.l	drawbitmap,showbitmap
	move	(a7),curropt
	lea	gamemenu,a4
	jsr	initmenu2
	jsr	g2menu_refresh_wait_blit
	move	(a7),curropt
	jsr	opton
	jsr	g2menu_refresh_wait_blit
	addq.l	#2,a7
	rts
.legacy
	; DISPLAY=P96 without a live P96 owner: unchanged original sequence.
	jsr	g2v190aj_restore_game_palette
	jsr	finitmenu
	jsr	predrawall
	jsr	g2menu_refresh_wait_blit
	jsr	g2v190aj_grey_menu_backdrop
	jsr	g2menu_refresh_wait_blit
	move	(a7),curropt
	lea	gamemenu,a4
	jsr	initmenu2
	jsr	g2menu_refresh_wait_blit
	move	(a7),curropt
	jsr	opton
	jsr	g2menu_refresh_wait_blit
	addq.l	#2,a7
	rts

; -----------------------------------------------------------------------------
; Leaving the in-game menu with CONTINUE (called from dogamemenu, gr_02).
;
; Native AGA/ECS: render the restored game frame off screen and show it
; together with the game palette. The original cleared the visible page first
; (finitmenu -> clspic, predrawall -> 2x clspic), so the screen went black
; for the duration of two renders. Both pages finally hold the game frame,
; exactly as after predrawall. DISPLAY=P96 keeps the original sequence.
; -----------------------------------------------------------------------------
g2menu_exit_to_game
	cmp	#2,g2display_mode
	bne.s	.native
	jsr	dispoff
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette
	jsr	g2resolution_apply_after_menu
	jsr	predrawall
	jmp	dispon
.native
	; No dispoff/dispon: the display stays on and shows the menu until the
	; flip (dispoff would switch DMA off on a non-OS copper display).
	jsr	g2menu_refresh_wait_blit
	jsr	g2menu_free_strips
	; finitfontpal state, its palette poke is replaced by the game palette
	clr	g2inter_yellow_text_active
	clr	g2ecs7_direct_font_active
	clr	g2ecs8_defer_font_palette
	clr	g2ecs8_font_palette_pending
	jsr	g2resolution_apply_after_menu
	jsr	g2menu_db_hold_on
	jsr	predrawall
	jsr	g2menu_db_hold_off
	jsr	g2menu_refresh_wait_blit
	move.l	g2v190aj_saved_lastpal,d0
	beq.s	.no_saved
	clr.l	g2v190aj_saved_lastpal
	move.l	d0,a1
	jsr	g2menu_flip_with_palette
	bra.s	.shown
.no_saved
	sub.l	a1,a1
	jsr	g2menu_flip_with_palette
	jsr	pokelastpal
.shown
	jsr	vwait
	jsr	vwait		; the old menu page is hidden now
	jmp	copypic		; second page = same game frame

; -----------------------------------------------------------------------------
; P96 in-game option refresh without visible intermediate states.
;
; While g2menu_p96_defer is set, the gameplay redraw neither loads the
; gameplay palette (the visible menu keeps its font pens) nor copies the
; text-free frame to the screen. The new frame only updates the RAM stages.
; g2p96_menu_all_rows_present then installs the menu palette once and
; publishes the menu band; g2menu_p96_refresh_finish publishes the rows above
; and below that band from the same new stage.
; -----------------------------------------------------------------------------
g2menu_p96_redraw_deferred
	move	#-1,g2menu_p96_defer
	jsr	g2p96_menu_redraw_gameplay_source_once
	clr	g2menu_p96_defer
	rts

; Entry of g2p96_clut_apply_table_c87b78j (replaces its MOVEM + MOVEQ).
g2menu_clut_apply_entry
	tst	g2menu_p96_defer
	bne.s	.defer
	movem.l	d1-d2/a0-a2/a6,-(a7)
	moveq	#0,d0
	jmp	g2p96_clut_apply_table_c87b78j+6
.defer
	moveq	#0,d0		; not applied: the table stays pending (dirty)
	rts

; Replaces the visible copy at the end of the RGB565 menu presenter (gr_13).
g2menu_stage_publish_gate
	tst	g2menu_p96_defer
	bne.s	.defer
	jmp	g2p96_gameplay_copy_stage_to_draw_target
.defer
	movem.l	d1-d7/a0-a6,-(a7)
	jsr	g2p96_clut_convert_full_stage_c87b78j	; keep the indexed stage current
	movem.l	(a7)+,d1-d7/a0-a6
	moveq	#-1,d0		; frame completed, publication deferred
	rts

; Replaces the JSR opton after g2p96_menu_all_rows_present in the refresh.
g2menu_p96_refresh_finish
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96target_height
	beq.s	.done
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq.s	.whole
	moveq	#0,d1
	moveq	#0,d2
	move	p96menu_batch_dst_y0,d2
	bsr.s	.publish		; rows above the published menu band
	moveq	#0,d1
	move	p96menu_batch_dst_y0,d1
	add	p96menu_batch_height,d1
	moveq	#0,d2
	move	p96target_height,d2
	sub	d1,d2
	bsr.s	.publish		; rows below the menu band
	bra.s	.done
.whole
	; no glyph menu: show the new frame as the original refresh did
	moveq	#0,d1
	moveq	#0,d2
	move	p96target_height,d2
	bsr.s	.publish
.done
	movem.l	(a7)+,d0-d7/a0-a6
	jmp	opton

; d1.w = first physical row, d2.w = number of rows
.publish
	tst.w	d2
	ble.w	.pub_done
	movem.l	d1-d2,-(a7)
	jsr	g2p96_menu_direct_clut_320_active_c87b78p
	movem.l	(a7)+,d1-d2
	moveq	#0,d3
	move	p96target_width,d3
	beq.w	.pub_done
	tst.l	d0
	beq.w	.pub_rgb565
	move.l	p96clut_stage_ptr,d4
	beq.w	.pub_done
	move.l	d4,p96safe_rect_src_ptr
	move.l	d3,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d3,p96safe_rect_rowbytes
	move	d1,p96safe_rect_src_y
	move	d1,p96safe_rect_dst_y
	move	d2,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
	bra.w	.pub_done
.pub_rgb565
	move.l	p96static_rgbbufptr,d4
	beq.w	.pub_done
	add.l	d3,d3
	move.l	d4,p96safe_rect_src_ptr
	move.l	d3,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d3,p96safe_rect_rowbytes
	move	d1,p96safe_rect_src_y
	move	d1,p96safe_rect_dst_y
	move	d2,p96safe_rect_height
	jsr	g2p96_copy_ram_rect_to_visible_c87b78d
.pub_done
	rts

; -----------------------------------------------------------------------------
; P96 row updates.
;
; Every row draw builds its row cache from the clean stage, plots the glyphs
; and publishes the complete band once. The restore that used to precede a
; draw only made the row visibly disappear first, so it is skipped there.
; Pure restores (blink off, optoff) compute their row from curropt: the
; previous code used p96menu_y_start/y_end of the last drawn row, which after
; a full menu redraw is the bottom row (QUIT GAME vanished).
; -----------------------------------------------------------------------------
g2menu_restore_skip
	rts

g2menu_restore_curropt
	movem.l	d0-d1,-(a7)
	move	curropt,d0
	move	fonth,d1
	mulu	d1,d0
	add	menuy,d0
	move	d0,p96menu_y_start
	add	d1,d0
	move	d0,p96menu_y_end
	movem.l	(a7)+,d0-d1
	jmp	g2p96_menu_restore_current_row_dispatch_c87b78p

; -----------------------------------------------------------------------------
; P96 menu pen selection cache.
;
; The collision-free font pens depend only on the clean stage and the base
; palette. Within one composed menu (initmenu2 .. next initmenu2) the stage
; changes only through a live refresh, which reinstalls the base palette and
; therefore invalidates the cache. Repeating the full-stage pen scan and the
; 256-colour LoadRGB32 for every row draw is skipped while nothing changed.
; -----------------------------------------------------------------------------
g2menu_session_begin	; replaces CLR p96menu_native_init_active (initmenu2)
	clr	p96menu_native_init_active
	clr	g2menu_overlay_valid
	rts

g2menu_overlay_cached	; replaces JSR g2p96_clut_overlay_menu_lut_c87b78y
	tst	g2menu_overlay_valid
	beq.s	.full
	move.l	d0,-(a7)
	cmp	#3,p96clut_active_role
	bne.s	.miss
	tst	p96clut_palette_dirty
	bne.s	.miss
	move	p96display_state,d0
	cmp	g2menu_overlay_state,d0
	bne.s	.miss
	move.l	p96clut_stage_ptr,d0
	cmp.l	g2menu_overlay_stage,d0
	bne.s	.miss
	move.l	p96clut_active_lut_ptr,d0
	cmp.l	g2menu_overlay_lut,d0
	bne.s	.miss
	move.l	p96clut_active_lut_sum,d0
	cmp.l	g2menu_overlay_sum,d0
	bne.s	.miss
	move.l	(a7)+,d0
	rts
.miss
	move.l	(a7)+,d0
.full
	clr	g2menu_overlay_valid
	jsr	g2p96_clut_overlay_menu_lut_c87b78y
	move.l	d0,-(a7)
	cmp	#3,p96clut_active_role
	bne.s	.done
	tst	p96clut_palette_dirty
	bne.s	.done
	move	p96display_state,d0
	cmp	#P96DSP_MENU,d0
	beq.s	.record
	cmp	#P96DSP_TITLE,d0
	bne.s	.done
.record
	move	d0,g2menu_overlay_state
	move.l	p96clut_stage_ptr,g2menu_overlay_stage
	move.l	p96clut_active_lut_ptr,g2menu_overlay_lut
	move.l	p96clut_active_lut_sum,g2menu_overlay_sum
	move	#-1,g2menu_overlay_valid
.done
	move.l	(a7)+,d0
	rts

	even
g2menu_saved_todb	dc.l	0
g2menu_overlay_stage	dc.l	0
g2menu_overlay_lut	dc.l	0
g2menu_overlay_sum	dc.l	0
g2menu_overlay_state	dc.w	0
g2menu_overlay_valid	dc.w	0
g2menu_p96_defer	dc.w	0
	even
