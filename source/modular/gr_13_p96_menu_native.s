; -----------------------------------------------------------------------------
; c86zji: P96-native menu selection/navigation row updates.
;
; The complete original Bigfont menu is already present in menubmap after the
; one-time initmenu build, and c86zjh has already transferred all rows to P96.
; During the live selection loop there is therefore no reason to restore a row
; with the Amiga blitter or call printmess2 again.  These helpers restore only
; the visible P96 background row and redraw the cached real-Bigfont delta with
; either normal or selected colours.  DISPLAY=AGA never reaches these helpers.
; Dynamic content changes (FLOOR/CEILING, level text, etc.) retain their proven
; recompose fallback for now and can be ported separately after this step.
; -----------------------------------------------------------------------------
g2p96_menu_native_nav_select
	movem.l	d0,-(a7)
	move	#13,flashdelay
	move	#-1,p96menu_native_selected
	jsr	g2p96_menu_native_nav_present
	movem.l	(a7)+,d0
	rts

g2p96_menu_native_nav_normal
	movem.l	d0,-(a7)
	move	#13,flashdelay
	clr	p96menu_native_selected
	jsr	g2p96_menu_native_nav_present
	movem.l	(a7)+,d0
	rts

g2p96_menu_native_nav_present
	movem.l	d0-d1,-(a7)
	cmp	#P96DSP_TITLE,p96display_state
	bne.s	.not_title
	move	curropt,d0
	move	fonth,d1
	mulu	d1,d0
	add	menuy,d0
	move	d0,p96menu_y_start
	add	d1,d0
	move	d0,p96menu_y_end
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
	bra.s	.done
.not_title
	cmp	#P96DSP_MENU,p96display_state
	bne.s	.done
	move	curropt,d0
	move	fonth,d1
	mulu	d1,d0
	add	menuy,d0
	move	d0,p96menu_y_start
	add	d1,d0
	move	d0,p96menu_y_end
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
.done
	movem.l	(a7)+,d0-d1
	rts

g2p96_menu_blink_current_row_on
	movem.l	d0,-(a7)
	cmp	#P96DSP_TITLE,p96display_state	;c86zgy: title menu blinks against staged title background
	bne	.not_title_on
	jsr	g2p96_title_menu_blink_current_row_on
	bra	.done_on
.not_title_on
	move	#-1,p96menu_native_selected
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
.done_on
	movem.l	(a7)+,d0
	rts

g2p96_menu_blink_current_row_off
	movem.l	d0,-(a7)
	cmp	#P96DSP_TITLE,p96display_state	;c86zgy: title menu OFF restores clean staged title row
	bne	.not_title_off
	jsr	g2p96_title_menu_blink_current_row_off
	bra	.done_off
.not_title_off
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
.done_off
	movem.l	(a7)+,d0
	rts

; c86zgs: when navigation happens during blink-OFF, first redraw the old
; selected row ON so optoff can restore it to a normal, non-selected menu row.
; This avoids the c86zgr fast-navigation bug where previous items vanished.
g2p96_menu_blink_ensure_visible
	tst	p96menu_blink_visible
	bne	.done
	move	#-1,p96menu_blink_visible
	jsr	g2p96_menu_blink_current_row_on
.done
	rts

; c86zgs: after curropt moved and opton built the new selected row, reapply
; the old blink phase without restarting the timer.  OFF phase becomes OFF again
; immediately, ON phase stays visible.  p96menu_blink_count is untouched.
g2p96_menu_apply_saved_blink_phase
	tst	p96menu_nav_old_visible
	beq	.off_phase
	move	#-1,p96menu_blink_visible
	rts
.off_phase
	clr	p96menu_blink_visible
	jsr	g2p96_menu_blink_current_row_off
	rts

; c86zgo: redraw only the live gameplay chunky/P96 source after FLOOR/CEILING
; changes.  This is deliberately not predrawall/initmenu2: those rebuild the
; whole menu and caused the visible multi-second P96 blackout.
g2p96_menu_redraw_gameplay_source_once
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#P96DSP_MENU,p96display_state
	bne.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done
	jsr	g2p96_menu_redraw_twoplayer_source_once_c87b79l
	bmi.s	.done
	move.l	player1,player_
	move.l	memory,memat
	; Step 2: match the normal one-player world-resolution pipeline.
	jsr	g2kalms_prepare_frame_layout
	jsr	g2p96_gameplay_prepare_linear_frame
	jsr	g2quality_prepare_frame
	jsr	calcscene
	jsr	drawscene
	jsr	g2quality_expand_restore
	jsr	blitscene
	jsr	g2p96_gameplay_persistent_update
	jsr	g2p96_menu_refresh_index_backdrop_c87b78p
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; c86zhj: lightweight transition blank.  Unlike black_close_if_open it does
; not close/reopen P96; it just clears the currently visible RTG bitmap so
; stale gameplay is not visible while title/intermission assets are loading.
g2p96_transition_clear_p96_if_open
	movem.l	d0-d1,-(a7)
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq	.done
	tst	p96gameplay_persist_active
	beq	.done
	move.l	p96winprobe_window_ptr,d0
	beq	.done
	jsr	g2p96_gameplay_clear_p96_screen
.done
	movem.l	(a7)+,d0-d1
	rts

; c87b79c: transition blanking for a persistent double-buffered P96 owner.
; The old helper cleared only the currently visible ScreenBuffer. The opposite
; draw page could still contain the last frame of the previous game and become
; visible during the next ownership change. Clear both pages without flipping.
g2p96_transition_clear_all_p96_if_open_c87b79c
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96winprobe_window_ptr,d0
	beq.w	.done
	tst	p96gameplay_dbuf_active
	beq.s	.single_buffer
	; Bridge/title ownership may leave double buffering suspended.  The generic
	; draw-bitmap selector deliberately maps a suspended owner back to Window.RPort
	; and could therefore clear the front page twice.  Synchronise once, then name
	; SB0 and SB1 explicitly so both physical pages are guaranteed black.
	jsr	g2p96_gameplay_dbuf_wait_safe
	tst	d0
	beq.s	.single_buffer
	jsr	g2p96_gameplay_dbuf_wait_disp
	tst	d0
	beq.s	.single_buffer
	jsr	g2p96_gameplay_clear_stage_black
	tst.l	d0
	beq.w	.done
	move.l	p96gameplay_dbuf_sb0,a0
	tst.l	a0
	beq.s	.clear_sb1
	move.l	SB_BitMap(a0),a2
	tst.l	a2
	beq.s	.clear_sb1
	jsr	g2p96_gameplay_copy_stage_to_bitmap_a2
.clear_sb1
	move.l	p96gameplay_dbuf_sb1,a0
	tst.l	a0
	beq.w	.done
	move.l	SB_BitMap(a0),a2
	tst.l	a2
	beq.w	.done
	jsr	g2p96_gameplay_copy_stage_to_bitmap_a2
	bra.w	.done
.single_buffer
	jsr	g2p96_gameplay_clear_p96_screen
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2p96_display_state_set
	move	p96display_state,p96display_prev_state
	move	d0,p96display_state
	rts

g2p96_display_is_p96_capable
	moveq	#0,d0
	move	g2display_mode,d1
	cmp	#2,d1		;capability exists only for DISPLAY=P96
	bne.s	.done
	tst	p96present
	beq.s	.done
	cmp	#1,p96modeid_state
	bne.s	.done
	; c87b79q: a P96 owner is valid only under the released 8-bit CLUT contract.
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.s	.done
	cmp	#8,p96modeid_depth
	bne.s	.done
	moveq	#-1,d0
.done
	rts

g2p96_display_enter_gameplay
	cmp	#2,g2display_mode	;ECS1: planar AGA/ECS never enter P96 ownership
	bne.s	.done
	jsr	g2p96_gameplay_dbuf_resume	;c86zje
	moveq	#P96DSP_GAMEPLAY,d0
	jsr	g2p96_display_state_set
.done	rts

g2p96_display_enter_title
	; c87b37: also a planar AGA/ECS lifecycle boundary.
	jsr	g2kalms_restore_legacy_layout
	cmp	#2,g2display_mode	;ECS1: planar AGA/ECS keep the normal display path
	bne.s	.done
	push
	jsr	g2p96_gameplay_dbuf_suspend_visible	;c86zjf: bridge writes to the buffer that is really on screen
	jsr	g2p96_gameplay_restore_c2p_layout	;c86zjd title/static compatibility decode uses the proven planar source layout
	moveq	#1,d0
	move	d0,p96display_event
	cmp	#P96DSP_GAMEPLAY,p96display_state	;c86zhe: title entered from gameplay/menu needs one safe qmenu rebuild
	beq.s	.g2c86zhe_mark_qmenu_rebuild
	cmp	#P96DSP_MENU,p96display_state
	bne.s	.g2c86zhe_no_qmenu_mark
.g2c86zhe_mark_qmenu_rebuild
	move	#-1,p96title_qmenu_rebuild_needed
.g2c86zhe_no_qmenu_mark
	jsr	g2p96_static_open_screen	;c86zgv: keep/open P96 while title is built offscreen
	moveq	#P96DSP_TITLE,d0
	jsr	g2p96_display_state_set
	pull
.done	rts

g2p96_display_enter_ingame_menu
	cmp	#2,g2display_mode	;ECS1: no P96 menu owner in planar modes
	bne.s	.done
	push
	jsr	g2p96_gameplay_dbuf_suspend_visible	;c86zjf: keep paused gameplay visible and retarget RPort
	moveq	#2,d0
	move	d0,p96display_event
	; c87b79y: keep the live P96 screen open for the direct indexed ESC menu.
	; The prepared index backdrop plus Bigfont glyph/page/row caches are the
	; only P96 menu sources; no planar menu bitmap is published or sampled.
	jsr	g2p96_menu_prepare_index_backdrop_c87b78p
	moveq	#P96DSP_MENU,d0
	jsr	g2p96_display_state_set
	pull
.done	rts

g2p96_display_enter_intermission
	; c87b37: also a planar AGA/ECS lifecycle boundary.
	jsr	g2kalms_restore_legacy_layout
	cmp	#2,g2display_mode	;ECS1: no P96 static owner in planar modes
	bne.w	.done
	push
	jsr	g2p96_gameplay_dbuf_suspend_visible	;c86zjf: static owner writes to the visible buffer
	jsr	g2p96_gameplay_restore_c2p_layout	;c86zjd intermission/static compatibility decode uses the proven planar source layout
	moveq	#3,d0
	move	d0,p96display_event
	jsr	g2p96_static_open_screen	;c86zgv: keep/open P96 while intermission is built offscreen
	moveq	#P96DSP_INTERMISSION,d0
	jsr	g2p96_display_state_set
	pull
.done	rts

g2p96_display_inputoff
	; c87b37: also a planar AGA/ECS lifecycle boundary.
	jsr	g2kalms_restore_legacy_layout
	cmp	#2,g2display_mode	;ECS1: no P96 ownership to close in planar modes
	bne.w	.done
	push
	moveq	#4,d0
	move	d0,p96display_event
	jsr	g2p96_display_black_close_if_open
	moveq	#P96DSP_AGA,d0
	jsr	g2p96_display_state_set
	pull
.done	rts

g2p96_display_shutdown
	; c87b37: also a planar AGA/ECS lifecycle boundary.
	jsr	g2kalms_restore_legacy_layout
	cmp	#2,g2display_mode	;ECS1: no P96 ownership to close in planar modes
	bne.w	.done
	push
	moveq	#5,d0
	move	d0,p96display_event
	jsr	g2p96_display_black_close_if_open
	moveq	#P96DSP_SHUTDOWN,d0
	jsr	g2p96_display_state_set
	pull
.done	rts

; c87b79h: P96 owns gameplay, title, menus and intermissions. The legacy
; WINDOW SIZE source shape remains locked while P96 owns output geometry;
; native planar AGA/ECS keeps the original behaviour.
g2p96_display_should_lock_fullwin
	jsr	g2p96_display_is_p96_capable
	rts

; One controlled exit from P96 ownership. It blanks the P96 bitmap, waits one
; refresh when graphics.library is open, then closes the P96 screen/window.
; Input-off, shutdown and validated fallback paths share this handoff.
g2p96_display_black_close_if_open
	push
	clr	p96gameplay_skip_aga_present
	clr	p96gameplay_latched
	clr	p96gameplay_delay_counter
	move.l	p96gameplay_intbase,d0
	bne	.have_open
	move.l	p96gameplay_grbase,d0
	bne	.have_open
	tst	p96gameplay_persist_active
	bne	.have_open
	bra	.done
.have_open
	cmp	#P96DSP_GAMEPLAY,p96display_state	;c86zhe: remember that next title qmenu must not trust stale cache
	beq.s	.g2c86zhe_mark_close_qmenu
	cmp	#P96DSP_MENU,p96display_state
	bne.s	.g2c86zhe_no_close_qmenu
.g2c86zhe_mark_close_qmenu
	move	#-1,p96title_qmenu_rebuild_needed
.g2c86zhe_no_close_qmenu
	moveq	#P96DSP_TRANSITION_BLACK,d0
	jsr	g2p96_display_state_set
	jsr	g2p96_gameplay_clear_p96_screen
	jsr	g2p96_display_wait_tof_once
	jsr	g2p96_gameplay_persistent_close
.done
	pull
	rts

g2p96_display_wait_tof_once
	move.l	p96gameplay_grbase,d0
	beq.w	.done
	move.l	d0,a6
	jsr	-270(a6)	;graphics.library WaitTOF
.done
	rts

; c86zfb: hide the mouse pointer on the P96 gameplay window as well as on AGA.
g2p96_gameplay_hide_pointer
	movem.l	d0-d3/a0-a1/a6,-(a7)
	move	#$0020,$dff096	;disable hardware sprite DMA while game owns the display
	move.l	p96winprobe_window_ptr,d0
	beq	.done
	move.l	p96gameplay_intbase,d1
	beq	.done
	move.l	chipzero,a1
	move.l	a1,d1
	beq	.done
	move.l	d0,a0
	moveq	#16,d0	;RC5: complete 16-row invisible Intuition pointer
	moveq	#16,d1	;full 16-pixel sprite width
	moveq	#0,d2
	moveq	#0,d3
	move.l	p96gameplay_intbase,a6
	jsr	-270(a6)	;Intuition SetPointer, full 16x16 blank chip pointer
.done
	movem.l	(a7)+,d0-d3/a0-a1/a6
	rts

; c87b78c: build a black frame in Fast RAM, then use the same short
; p96LockBitMap/copy/unlock path as normal gameplay.  No bitmap internals are
; inspected here and the lock is never held while clearing/converting pixels.
g2p96_gameplay_clear_p96_screen
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2p96_gameplay_clear_stage_black
	tst.l	d0
	beq.w	.done
	jsr	g2p96_gameplay_copy_stage_to_visible_target
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Clear the complete packed RGB565 staging page in Fast RAM.
; Returns d0=-1 on success, zero when the staging allocation is unavailable.
g2p96_gameplay_clear_stage_black
	movem.l	d1/a0,-(a7)
	move.l	p96static_rgbbufptr,d0
	beq.s	.fail
	move.l	d0,a0
	move.l	p96static_rgbbufsize,d1
	beq.s	.fail
	lsr.l	#2,d1		;supported RGB565 page sizes are all longword multiples
	beq.s	.fail
	subq.l	#1,d1
.clear
	clr.l	(a0)+
	subq.l	#1,d1
	bpl.s	.clear
	moveq	#-1,d0
	bra.s	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1/a0
	rts

; Select exactly the bitmap that is safe to draw next.  During active double
; buffering this is the current offscreen ScreenBuffer selected only after the
; SafeMessage was received.  Bridge/single-buffer ownership uses Window.RPort.
; Returns a2=BitMap and d0=-1, or d0=0 on failure.
g2p96_gameplay_select_draw_bitmap
	moveq	#0,d0
	tst	p96gameplay_dbuf_active
	beq.s	.window_bitmap
	tst	p96gameplay_dbuf_suspended
	bne.s	.window_bitmap
	tst	p96gameplay_dbuf_draw
	beq.s	.draw_sb0
	move.l	p96gameplay_dbuf_sb1,d0
	bra.s	.have_sb
.draw_sb0
	move.l	p96gameplay_dbuf_sb0,d0
.have_sb
	beq.s	.fail
	move.l	d0,a1
	move.l	SB_BitMap(a1),d0
	beq.s	.fail
	move.l	d0,a2
	moveq	#-1,d0
	rts
.window_bitmap
	move.l	p96winprobe_window_ptr,d0
	beq.s	.fail
	move.l	d0,a0
	move.l	50(a0),d0	;Window.RPort
	beq.s	.fail
	move.l	d0,a1
	move.l	4(a1),d0	;RastPort.BitMap (selection only, no bitmap internals)
	beq.s	.fail
	move.l	d0,a2
	moveq	#-1,d0
	rts
.fail
	moveq	#0,d0
	rts

; Select the bitmap currently visible on screen.  Transition blanking must not
; accidentally clear only the next offscreen draw page.
g2p96_gameplay_select_visible_bitmap
	moveq	#0,d0
	tst	p96gameplay_dbuf_active
	beq.s	.window_bitmap
	tst	p96gameplay_dbuf_current
	beq.s	.visible_sb0
	move.l	p96gameplay_dbuf_sb1,d0
	bra.s	.have_sb
.visible_sb0
	move.l	p96gameplay_dbuf_sb0,d0
.have_sb
	beq.s	.fail
	move.l	d0,a1
	move.l	SB_BitMap(a1),d0
	beq.s	.fail
	move.l	d0,a2
	moveq	#-1,d0
	rts
.window_bitmap
	move.l	p96winprobe_window_ptr,d0
	beq.s	.fail
	move.l	d0,a0
	move.l	50(a0),d0
	beq.s	.fail
	move.l	d0,a1
	move.l	4(a1),d0
	beq.s	.fail
	move.l	d0,a2
	moveq	#-1,d0
	rts
.fail
	moveq	#0,d0
	rts

; Copy the completed Fast-RAM page into the currently visible bitmap.
g2p96_gameplay_copy_stage_to_visible_target
	movem.l	d1-d7/a0-a6,-(a7)
	jsr	g2p96_gameplay_select_visible_bitmap
	tst.l	d0
	beq.s	.fail
	jsr	g2p96_gameplay_copy_stage_to_bitmap_a2
	bra.s	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Copy the completed Fast-RAM RGB565 stage into the currently safe draw bitmap.
g2p96_gameplay_copy_stage_to_draw_target
	movem.l	d1-d7/a0-a6,-(a7)
	jsr	g2p96_gameplay_select_draw_bitmap
	tst.l	d0
	beq.s	.fail
	jsr	g2p96_gameplay_copy_stage_to_bitmap_a2
	bra.s	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; a2 = destination BitMap.
; The target is locked only for the memory copy.  RenderInfo supplies the real
; VRAM address, stride and RGB format; BitMap.Planes[] and BitMap.BytesPerRow are
; deliberately not touched.  Returns d0=-1 only after a successful unlock.
g2p96_gameplay_copy_stage_to_bitmap_a2
	jmp	g2p96_gameplay_copy_stage_to_bitmap_a2_c87b78j
; c87b78c full-source P96-primary stage builder and short locked presenter.
; The source is normally 320x240, native ONE PLAYER 5:4 is 320x256, and c87p3
; also supplies a true 320x256 TWO PLAYER source made from two 320x128 halves.
; Target geometry comes from the current P96 mode and RESOLUTION remains the
; established 1x1/1x2/2x1/2x2 world-render setting.  Output conversion happens
; fully in Fast RAM before the short VRAM lock/copy/unlock window.
g2p96_gameplay_draw_mini_frame_160x96
	; c87b78m: fixed-size trampoline. JMP (6) + four NOPs (8) exactly
	; replace the former 14-byte MOVEM/MOVE/BEQ prologue, so established
	; GenAm PC-relative ranges after this point do not move.
	jmp	g2p96_gameplay_draw_dispatch_c87b78m
	nop
	nop
	nop
	nop
g2p96_gameplay_draw_rgb565_continue_c87b78m
	move.l	d0,a4		;source chunky base in Fast RAM
	move	chunkymodw,d5
	beq.w	.done
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	move.l	d0,a3		;c87b78c packed RGB565 staging origin in Fast RAM
	moveq	#0,d4
	move	p96target_width,d4
	add.l	d4,d4		;packed staging BytesPerRow = target width * 2
	move	d4,p96gameplay_stage_bpr
	jsr	g2p96_gameplay_build_rgb565_source_lut
	; c86zfn: do not black-fill the full 480p widescreen bitmap every frame.
	; The screen is cleared once when opened, then only the gameplay image is
	; updated.  This avoids visible dark scan/clear bands on real A1200 RTG.

	; c87b78c: target offsets belong to the final locked copy, not conversion.

	lea	coloffs,a6
	lea	p96gameplay_rgb565_source_lut,a5
	; c87p3: hite is deliberately restored to the AGA-safe full value of 240
	; after split rendering.  The P96 presenter instead follows the real split
	; source height: 120+120 normally, 128+128 in active P96 5:4.
	move	hite,d0
	tst	twowins
	beq.s	.g2c87p3_present_rows_ready
	move	g2twop_half_height,d0
	add	d0,d0
.g2c87p3_present_rows_ready
	move	d0,g2p96_present_rows
	moveq	#0,d6	; source y 0..239, or 0..255 in native P96 5:4
.rowloop
	cmp	g2p96_present_rows,d6
	bge.w	.fps_overlay
	move	d6,d0
	mulu	d5,d0
	move.l	a4,a2
	adda.l	d0,a2	; chunky source row
	move	d6,d0
	move	p96target_mode,d1
	cmp	#1,d1
	beq.s	.double_y
	cmp	#2,d1
	beq.s	.double_y
	bra.s	.low_y
.double_y
	add	d0,d0		; 480-line modes duplicate each source row
.low_y
	; c87p1: before the native 256-row linear source is armed, centre the
	; legacy 240-row frame in the 256/512 target. Native 1:1 frames start at Y=0.
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_y_ready
	cmp	#256,g2p96_present_rows	;c87p3: true 128+128 TWO PLAYER already fills target
	beq.s	.g2c87p1_y_ready
	tst	p96gameplay_linear_active
	bne.s	.g2c87p1_y_ready
	tst	g2p96_hires_mode
	beq.s	.g2c87p1_y_low
	add	#16,d0
	bra.s	.g2c87p1_y_ready
.g2c87p1_y_low
	addq	#8,d0
.g2c87p1_y_ready
	mulu	d4,d0
	move.l	a3,a1
	adda.l	d0,a1	; destination row 1
	move.l	a1,a0
	cmp	#1,d1
	beq.s	.add_row2
	cmp	#2,d1
	beq.s	.add_row2
	bra.s	.dispatch
.add_row2
	adda.l	d4,a0	; destination row 2 for 480-line output
.dispatch
	; c87w1: native WIDE already rendered every logical source column. Never
	; rescale the old 320 image in this branch.
	tst	g2p96_wide_mode
	beq.s	.standard_dispatch
	tst	p96gameplay_linear_active
	beq.s	.standard_dispatch
	cmp	#2,p96target_mode
	beq	.copy_wide_2x
	bra	.copy_wide_1x
.standard_dispatch
	move	p96target_mode,d0
	beq	.copy_1x
	cmp	#1,d0
	beq	.copy_2x
	cmp	#3,d0
	beq	.copy_stretch_240
	bra	.copy_stretch_480
.copy_wide_1x
	moveq	#0,d7
.g2c87w1_w1_loop
	cmp	g2render_width,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),(a1)+
	addq	#1,d7
	bra.s	.g2c87w1_w1_loop

.copy_wide_2x
	; 854 = 428x2 with one duplicate omitted at each extreme edge,
	; keeping the centre and every interior column exact 2x.
	moveq	#0,d7
	move	g2render_last_x,d3
.g2c87w1_w2_loop
	cmp	g2render_width,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	move	d2,(a0)+
	cmp	#428,g2render_width
	bne.s	.g2c87w1_w2_dup
	tst	d7
	beq.s	.g2c87w1_w2_next
	cmp	d3,d7
	beq.s	.g2c87w1_w2_next
.g2c87w1_w2_dup
	move	d2,(a1)+
	move	d2,(a0)+
.g2c87w1_w2_next
	addq	#1,d7
	bra.s	.g2c87w1_w2_loop


.copy_1x
	moveq	#0,d7	; source x 0..319
.loop1
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0	; old c86zds column offset
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	addq	#1,d7
	bra.s	.loop1

.copy_2x
	moveq	#0,d7	; source x 0..319, doubled to 640
.loop2
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	move	d2,(a1)+
	move	d2,(a0)+
	move	d2,(a0)+
	addq	#1,d7
	bra.s	.loop2

.copy_stretch_480
	; c86zfj: source-driven scaler.  The c86zfi destination-driven
	; accumulator could produce repeated/striped output on some wide RTG modes.
	; This version walks the real 320 source columns once and emits as many
	; destination pixels as the selected width requires.
	moveq	#0,d7	; source x 0..319
	moveq	#0,d3	; fractional/error accumulator
	moveq	#0,d2	; destination x count
.stretch480_src_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d1
	add	p96target_width,d3
.stretch480_emit
	cmp	p96target_width,d2
	bge.w	.nextrow
	move	d1,(a1)+
	move	d1,(a0)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.stretch480_emit
	addq	#1,d7
	bra.s	.stretch480_src_loop

.copy_stretch_240
	; c86zfj: same source-driven scaler for 240-line wide modes.
	moveq	#0,d7	; source x 0..319
	moveq	#0,d3	; fractional/error accumulator
	moveq	#0,d2	; destination x count
.stretch240_src_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d1
	add	p96target_width,d3
.stretch240_emit
	cmp	p96target_width,d2
	bge.w	.stretch240_hud_overlay
	move	d1,(a1)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.stretch240_emit
	addq	#1,d7
	bra.s	.stretch240_src_loop

.stretch240_hud_overlay
	; c86zfo: 240p widescreen can put the right HUD very close to the
	; physical/screenmode edge on real RTG setups.  Keep the main image stretched,
	; but redraw the rightmost 80 source columns 1:1 over the stretched result so
	; the lives/head strip keeps the same usable width as the normal 320x240 path.
	lea	-160(a1),a1	; destination: rightmost 80 16-bit pixels
	move	#240,d7		; source: right HUD/lives area, x=240..319
.hud240_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d1
	move	d1,(a1)+
	addq	#1,d7
	bra.s	.hud240_loop
.nextrow
	addq	#1,d6
	bra.w	.rowloop
.fps_overlay
	move.l	a3,a0		;c87b78c completed Fast-RAM RGB565 page
	move.l	d4,d0		;packed staging BytesPerRow
	jsr	g2fps_draw_p96_target
	jsr	g2p96_gameplay_copy_stage_to_draw_target
	tst.l	d0
	beq.w	.done
	move	#-1,p96gameplay_direct_state	;only a completed lock/copy/unlock counts
.done
g2p96_gameplay_draw_common_done_c87b78m
	movem.l	(a7)+,d0-d7/a0-a6
	rts



g2p96_menu_all_rows_present
	jsr	g2p96_menu_glyph_mode_active
	tst	d0
	beq.w	.g2c87b79x_direct_unavailable
	movem.l	d0-d7,-(a7)
	move	curropt,-(a7)
	jsr	g2p96_menu_build_rgb565_lut
	jsr	g2p96_menu_batch_begin_dispatch_c87b78p
	clr	p96menu_native_selected
	moveq	#0,d7
.g2c86zjj_native_loop
	move	numopts,d0
	cmp	d0,d7
	bge	.g2c86zjj_native_flush
	move	d7,curropt
	jsr	g2p96_menu_glyph_draw_current_row_no_restore
	addq	#1,d7
	bra	.g2c86zjj_native_loop
.g2c86zjj_native_flush
	jsr	g2p96_menu_batch_flush_dispatch_c87b78p
	jsr	g2p96_menu_batch_end
	move	(a7)+,curropt
	movem.l	(a7)+,d0-d7
	rts
.g2c87b79x_direct_unavailable
	; c87b79y: direct dependencies unavailable; return without a legacy path.
	rts
; c86zgd: opton/optoff row update.  Restore only this source row from the
; paused gameplay frame, then draw native text over it.  This gives clean blink
; and navigation without copying or decoding the whole menu bitmap.
g2p96_menu_current_row_present
	movem.l	d0-d1,-(a7)
	; opton/optoff is also used by DISPLAY=AGA. Enter this direct row-cache
	; updater only while a real P96 owner/window is active.
	jsr	g2p96_display_is_p96_capable
	tst	d0
	beq	.done
	tst	p96gameplay_persist_active
	beq	.done
	move.l	p96winprobe_window_ptr,d0
	beq	.done
	cmp	#P96DSP_TITLE,p96display_state	;c86zgy: title menu row refresh uses staged title background
	bne	.not_title
	jsr	g2p96_title_menu_current_row_present
	bra	.done
.not_title
	move	curropt,d0
	move	fonth,d1
	mulu	d1,d0
	add	menuy,d0
	move	d0,p96menu_y_start
	add	d1,d0
	move	d0,p96menu_y_end
	jsr	g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_draw_current_row_best_no_restore
.done
	movem.l	(a7)+,d0-d1
	rts

; c86zgd: restore one menu row from the current gameplay chunky source into the
; visible P96 bitmap.  This is similar to the confirmed gameplay present path,
; but limited to p96menu_y_start..end so menu blink stays cheap.
g2p96_menu_native_restore_current_row
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#P96DSP_MENU,p96display_state
	bne.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96winprobe_window_ptr,d0
	beq.w	.done
	move.l	chunky,d0
	beq.w	.done
	move.l	d0,a4
	move	chunkymodw,d5
	beq.w	.done
	move.l	p96winprobe_window_ptr,a5
	move.l	50(a5),d0
	beq.w	.done
	move.l	d0,a1
	move.l	4(a1),d0
	beq.w	.done
	move.l	d0,a2
	move.l	8(a2),d0
	beq.w	.done
	move.l	d0,a3
	moveq	#0,d4
	move	0(a2),d4
	and.l	#$0000ffff,d4
	jsr	g2p96_gameplay_build_rgb565_source_lut
	moveq	#0,d0
	move	6(a5),d0
	mulu	d4,d0
	adda.l	d0,a3
	moveq	#0,d0
	move	4(a5),d0
	add.l	d0,d0
	adda.l	d0,a3
	lea	coloffs,a6
	lea	p96gameplay_rgb565_source_lut,a5
	move	p96menu_y_start,d6
	bpl.s	.rowloop
	moveq	#0,d6
.rowloop
	cmp	p96menu_y_end,d6
	bge.w	.done
	cmp	#240,d6
	bge.w	.done
	move	d6,d0
	; c87p1: the native gameplay source itself is 256 rows high. The old
	; 240-row menu layout is centred at Y=8, so restore the matching gameplay
	; source row as well as writing it to physical Y+8. Otherwise navigation
	; would copy row Y over row Y+8 and create horizontal background bands.
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_bridge_source_y_ready
	addq	#8,d0
.g2c87p1_bridge_source_y_ready
	mulu	d5,d0
	move.l	a4,a2
	adda.l	d0,a2
	move	d6,d0
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_bridge_y_ready
	addq	#8,d0
.g2c87p1_bridge_y_ready
	move	p96target_mode,d1
	cmp	#1,d1
	beq.s	.double_y
	cmp	#2,d1
	beq.s	.double_y
	bra.s	.low_y
.double_y
	add	d0,d0
.low_y
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
	; c87w3/c87b78z: ONE PLAYER native WIDE owns a real 428-byte chunky row.
	; The old menu refresh restored only 320 pixels at physical X=0, shifting
	; the paused background whenever the selected row changed.  Restore the
	; complete native row exactly like the confirmed gameplay presenter, then
	; let the existing centred glyph renderer redraw the menu text.
	tst	g2p96_wide_mode
	beq.s	.standard_dispatch
	tst	p96gameplay_linear_active
	beq.s	.standard_dispatch
	cmp	#2,p96target_mode
	beq.w	.copy_wide_2x
	bra.w	.copy_wide_1x
.standard_dispatch
	move	p96target_mode,d0
	beq.w	.copy_1x
	cmp	#1,d0
	beq.w	.copy_2x
	cmp	#3,d0
	beq.w	.copy_stretch_240
	bra.w	.copy_stretch_480

.copy_wide_1x
	moveq	#0,d7
.g2c87w3_row_w1_loop
	cmp	g2render_width,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),(a1)+
	addq	#1,d7
	bra.s	.g2c87w3_row_w1_loop

.copy_wide_2x
	; 854 = 428x2 with one duplicate omitted at each extreme edge,
	; matching the already confirmed WIDE gameplay output.
	moveq	#0,d7
	move	g2render_last_x,d3
.g2c87w3_row_w2_loop
	cmp	g2render_width,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	move	d2,(a0)+
	cmp	#428,g2render_width
	bne.s	.g2c87w3_row_w2_dup
	tst	d7
	beq.s	.g2c87w3_row_w2_next
	cmp	d3,d7
	beq.s	.g2c87w3_row_w2_next
.g2c87w3_row_w2_dup
	move	d2,(a1)+
	move	d2,(a0)+
.g2c87w3_row_w2_next
	addq	#1,d7
	bra.s	.g2c87w3_row_w2_loop

.copy_1x
	moveq	#0,d7
.loop1
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	addq	#1,d7
	bra.s	.loop1
.copy_2x
	moveq	#0,d7
.loop2
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	move	d2,(a1)+
	move	d2,(a1)+
	move	d2,(a0)+
	move	d2,(a0)+
	addq	#1,d7
	bra.s	.loop2
.copy_stretch_480
	moveq	#0,d7
	moveq	#0,d3
	moveq	#0,d2
.stretch480_src_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d1
	add	p96target_width,d3
.stretch480_emit
	cmp	p96target_width,d2
	bge.w	.nextrow
	move	d1,(a1)+
	move	d1,(a0)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.stretch480_emit
	addq	#1,d7
	bra.s	.stretch480_src_loop
.copy_stretch_240
	moveq	#0,d7
	moveq	#0,d3
	moveq	#0,d2
.stretch240_src_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	d1,d1
	move	0(a5,d1.w),d1
	add	p96target_width,d3
.stretch240_emit
	cmp	p96target_width,d2
	bge.w	.nextrow
	move	d1,(a1)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.stretch240_emit
	addq	#1,d7
	bra.s	.stretch240_src_loop
.nextrow
	addq	#1,d6
	bra.w	.rowloop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; c86zgd: plot one source-coordinate menu pixel in the selected P96 output mode.
; Uses p96menu_native_px/py/colour and the current p96target_mode/width.
; c87w1: source menu coordinate -> centred physical target coordinate.
; d0=x, d1=y. Returns d3=0 low/1 high.
g2wide_menu_map_xy
	moveq	#0,d3
	cmp	#2,p96target_mode
	beq.s	.high
	move	p96target_width,d6
	sub	#320,d6
	lsr	#1,d6
	add	d6,d0
	rts
.high
	moveq	#1,d3
	add	d0,d0
	move	p96target_width,d6
	sub	#640,d6
	lsr	#1,d6
	add	d6,d0
	add	d1,d1
	rts

g2p96_menu_native_put_pixel
	movem.l	d0-d7/a0-a2,-(a7)
	move	p96menu_native_px,d0
	move	p96menu_native_py,d1
	move	p96menu_native_colour,d2
	; c87p2: caches already begin at physical Y+8/Y+16, so their pixels
	; must remain in logical menu coordinates. Only direct bitmap writes need
	; the physical 1:1 border offset here.
	; c86zgh: when a full-menu batch is active, never touch visible RTG memory
	; during glyph sampling.  Write into the menu-page cache and let the caller
	; perform one final linear flush after all rows are complete.
	tst	p96menu_batch_active
	beq.s	.check_row_cache
	jsr	g2p96_menu_native_put_pixel_batch_dispatch_c87b78p
	bra.w	.done
.check_row_cache
	tst	p96menu_cache_active
	beq.s	.visible
	jsr	g2p96_menu_native_put_pixel_cache_dispatch_c87b78p
	bra.w	.done
.visible
	tst	g2p96_oneone_mode
	beq.s	.g2c87p2_menu_y_ready
	addq	#8,d1		;HIRES doubles this later to a 16-line top border
.g2c87p2_menu_y_ready
	move.l	p96menu_native_dstbase,a1
	move.l	p96menu_native_bpr,d4
	tst	g2p96_wide_mode
	beq.s	.normal_modes
	jsr	g2wide_menu_map_xy
	move	d1,d5
	mulu	d4,d5
	adda.l	d5,a1
	add	d0,d0
	adda.w	d0,a1
	move	d2,(a1)
	tst	d3
	beq.w	.done
	move	d2,2(a1)
	move.l	a1,a2
	adda.l	d4,a2
	move	d2,(a2)
	move	d2,2(a2)
	bra.w	.done
.normal_modes
	move	p96target_mode,d3
	cmp	#1,d3
	beq.w	.mode_2x
	cmp	#2,d3
	beq.w	.mode_stretch480
	cmp	#3,d3
	beq.w	.mode_stretch240
.mode_1x
	move	d1,d5
	mulu	d4,d5
	adda.l	d5,a1
	add	d0,d0
	adda.w	d0,a1
	move	d2,(a1)
	bra.w	.done
.mode_2x
	add	d1,d1
	move	d1,d5
	mulu	d4,d5
	adda.l	d5,a1
	add	d0,d0
	add	d0,d0
	adda.w	d0,a1
	move.l	a1,a2
	adda.l	d4,a2
	move	d2,(a1)+
	move	d2,(a1)
	move	d2,(a2)+
	move	d2,(a2)
	bra.w	.done
.mode_stretch480
	add	d1,d1
	move	d1,d5
	mulu	d4,d5
	adda.l	d5,a1
	move.l	a1,a2
	adda.l	d4,a2
	bra.s	.stretch_common
.mode_stretch240
	move	d1,d5
	mulu	d4,d5
	adda.l	d5,a1
	move.l	a1,a2
.stretch_common
	moveq	#0,d5
	move	d0,d5
	mulu	p96target_width,d5
	move.l	d5,d6
	move	#320,d7
	divu	d7,d6	; start x
	addq	#1,d0
	moveq	#0,d5
	move	d0,d5
	mulu	p96target_width,d5
	move.l	d5,d7
	move	#320,d0
	divu	d0,d7	; end x
	cmp	d6,d7
	bhi.s	.have_width
	addq	#1,d7
.have_width
	move	d6,d0
	add	d0,d0
	adda.w	d0,a1
	cmp	#2,d3
	bne.s	.stretch240_loop
	move.l	a1,a2
	adda.l	d4,a2
.stretch480_loop
	cmp	d6,d7
	bls.w	.done
	move	d2,(a1)+
	move	d2,(a2)+
	addq	#1,d6
	bra.s	.stretch480_loop
.stretch240_loop
	cmp	d6,d7
	bls.w	.done
	move	d2,(a1)+
	addq	#1,d6
	bra.s	.stretch240_loop
.done
	movem.l	(a7)+,d0-d7/a0-a2
	rts


g2p96_menu_batch_end
	clr	p96menu_batch_active
	rts

; input from g2p96_menu_native_put_pixel after loading:
;   d0 = source x, d1 = source y, d2 = RGB565 colour
g2p96_menu_native_put_pixel_batch
	movem.l	d0-d7/a0-a2,-(a7)
	move.l	p96menu_page_cache_ptr,d7
	beq.w	.done
	move.l	d7,a1
	tst	g2p96_wide_mode
	beq.s	.normal_modes
	sub	p96menu_batch_src_y0,d1
	bmi.w	.done
	jsr	g2wide_menu_map_xy
	cmp	p96menu_batch_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_batch_rowbytes,d5
	adda.l	d5,a1
	add	d0,d0
	adda.w	d0,a1
	move	d2,(a1)
	tst	d3
	beq.w	.done
	move	d2,2(a1)
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_batch_rowbytes,d4
	adda.l	d4,a2
	move	d2,(a2)
	move	d2,2(a2)
	bra.w	.done
.normal_modes
	move	p96target_mode,d3
	cmp	#1,d3
	beq.w	.mode_2x
	cmp	#2,d3
	beq.w	.mode_stretch480
	cmp	#3,d3
	beq.w	.mode_stretch240

.mode_1x
	sub	p96menu_batch_src_y0,d1
	bmi.w	.done
	cmp	p96menu_batch_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_batch_rowbytes,d5
	adda.l	d5,a1
	add	d0,d0
	adda.w	d0,a1
	move	d2,(a1)
	bra.w	.done

.mode_2x
	sub	p96menu_batch_src_y0,d1
	bmi.w	.done
	add	d1,d1
	cmp	p96menu_batch_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_batch_rowbytes,d5
	adda.l	d5,a1
	add	d0,d0
	add	d0,d0
	adda.w	d0,a1
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_batch_rowbytes,d4
	adda.l	d4,a2
	move	d2,(a1)+
	move	d2,(a1)
	move	d2,(a2)+
	move	d2,(a2)
	bra.w	.done

.mode_stretch480
	sub	p96menu_batch_src_y0,d1
	bmi.w	.done
	add	d1,d1
	cmp	p96menu_batch_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_batch_rowbytes,d5
	adda.l	d5,a1
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_batch_rowbytes,d4
	adda.l	d4,a2
	bra.s	.stretch_common

.mode_stretch240
	sub	p96menu_batch_src_y0,d1
	bmi.w	.done
	cmp	p96menu_batch_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_batch_rowbytes,d5
	adda.l	d5,a1
	move.l	a1,a2

.stretch_common
	moveq	#0,d5
	move	d0,d5
	mulu	p96target_width,d5
	move.l	d5,d6
	move	#320,d7
	divu	d7,d6
	addq	#1,d0
	moveq	#0,d5
	move	d0,d5
	mulu	p96target_width,d5
	move.l	d5,d7
	move	#320,d0
	divu	d0,d7
	cmp	d6,d7
	bhi.s	.have_width
	addq	#1,d7
.have_width
	move	d6,d0
	add	d0,d0
	adda.w	d0,a1
	cmp	#2,d3
	bne.s	.stretch240_loop
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_batch_rowbytes,d4
	adda.l	d4,a2
.stretch480_loop
	cmp	d6,d7
	bls.w	.done
	move	d2,(a1)+
	move	d2,(a2)+
	addq	#1,d6
	bra.s	.stretch480_loop
.stretch240_loop
	cmp	d6,d7
	bls.w	.done
	move	d2,(a1)+
	addq	#1,d6
	bra.s	.stretch240_loop
.done
	movem.l	(a7)+,d0-d7/a0-a2
	rts

p96menu_page_cache_ptr	dc.l	0
p96menu_batch_dstbase	dc.l	0
p96menu_batch_bpr	dc.l	0
p96menu_batch_active	dc	0
p96menu_batch_rowbytes	dc	0
p96menu_batch_src_y0	dc	0
p96menu_batch_src_y1	dc	0
p96menu_batch_src_height	dc	0
p96menu_batch_dst_y0	dc	0
p96menu_batch_height	dc	0
p96menu_page_cache_name	dc.b	'p96menupagecache',0
	even

; input from g2p96_menu_native_put_pixel after loading:
;   d0 = source x, d1 = source y, d2 = RGB565 colour
g2p96_menu_native_put_pixel_cache
	movem.l	d0-d7/a0-a2,-(a7)
	lea	p96menu_row_cache,a1
	tst	g2p96_wide_mode
	beq.s	.normal_modes
	sub	p96menu_y_start,d1
	bmi.w	.done
	jsr	g2wide_menu_map_xy
	cmp	p96menu_cache_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_cache_rowbytes,d5
	adda.l	d5,a1
	add	d0,d0
	adda.w	d0,a1
	move	d2,(a1)
	tst	d3
	beq.w	.done
	move	d2,2(a1)
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_cache_rowbytes,d4
	adda.l	d4,a2
	move	d2,(a2)
	move	d2,2(a2)
	bra.w	.done
.normal_modes
	move	p96target_mode,d3
	cmp	#1,d3
	beq.w	.mode_2x
	cmp	#2,d3
	beq.w	.mode_stretch480
	cmp	#3,d3
	beq.w	.mode_stretch240

.mode_1x
	sub	p96menu_y_start,d1
	bmi.w	.done
	cmp	p96menu_cache_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_cache_rowbytes,d5
	adda.l	d5,a1
	add	d0,d0
	adda.w	d0,a1
	move	d2,(a1)
	bra.w	.done

.mode_2x
	sub	p96menu_y_start,d1
	bmi.w	.done
	add	d1,d1
	cmp	p96menu_cache_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_cache_rowbytes,d5
	adda.l	d5,a1
	add	d0,d0
	add	d0,d0
	adda.w	d0,a1
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_cache_rowbytes,d4
	adda.l	d4,a2
	move	d2,(a1)+
	move	d2,(a1)
	move	d2,(a2)+
	move	d2,(a2)
	bra.w	.done

.mode_stretch480
	sub	p96menu_y_start,d1
	bmi.w	.done
	add	d1,d1
	cmp	p96menu_cache_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_cache_rowbytes,d5
	adda.l	d5,a1
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_cache_rowbytes,d4
	adda.l	d4,a2
	bra.s	.stretch_common

.mode_stretch240
	sub	p96menu_y_start,d1
	bmi.w	.done
	cmp	p96menu_cache_height,d1
	bge.w	.done
	move	d1,d5
	mulu	p96menu_cache_rowbytes,d5
	adda.l	d5,a1
	move.l	a1,a2

.stretch_common
	moveq	#0,d5
	move	d0,d5
	mulu	p96target_width,d5
	move.l	d5,d6
	move	#320,d7
	divu	d7,d6
	addq	#1,d0
	moveq	#0,d5
	move	d0,d5
	mulu	p96target_width,d5
	move.l	d5,d7
	move	#320,d0
	divu	d0,d7
	cmp	d6,d7
	bhi.s	.have_width
	addq	#1,d7
.have_width
	move	d6,d0
	add	d0,d0
	adda.w	d0,a1
	cmp	#2,d3
	bne.s	.stretch240_loop
	move.l	a1,a2
	moveq	#0,d4
	move	p96menu_cache_rowbytes,d4
	adda.l	d4,a2
.stretch480_loop
	cmp	d6,d7
	bls.w	.done
	move	d2,(a1)+
	move	d2,(a2)+
	addq	#1,d6
	bra.s	.stretch480_loop
.stretch240_loop
	cmp	d6,d7
	bls.w	.done
	move	d2,(a1)+
	addq	#1,d6
	bra.s	.stretch240_loop
.done
	movem.l	(a7)+,d0-d7/a0-a2
	rts

p96menu_cache_active	dc	0
p96menu_cache_rowbytes	dc	0
p96menu_cache_dsty	dc	0
p96menu_cache_height	dc	0
	even
p96menu_row_cache
	ds.b	36000
	even

p96menu_native_selected	dc	0	;c86zgd -1=selected row, 0=normal row
p96menu_blink_visible	dc	0	;c86zgq -1=selected row currently visible in P96 blink
p96menu_blink_count	dc	0	;c86zgq P96-only selected-row blink counter
p96menu_nav_old_visible	dc	0	;c86zgs saved blink phase during up/down navigation
p96menu_native_colour	dc	0
p96menu_native_px	dc	0
p96menu_native_py	dc	0
p96menu_native_dstbase	dc.l	0
p96menu_native_bpr	dc.l	0
	even

; c87b69: direct menu palette lookup; there are no disabled P96 rows.
g2p96_menu_pixel_rgb565
	add	d1,d1
	move	0(a5,d1.w),d2
	rts

; c87b79y: direct menu palette-index -> RGB565 LUT for cached glyph pixels.
; Unlike gameplay Chunky bytes, menu indices are not passed through g2_strip_invpal.
; Use lastpal first because the ESC menu has already set the menu/font palette;
; planar_palette is only a fallback.
g2p96_menu_build_rgb565_lut
	jsr	g2p96_menu_build_rgb565_lut_legacy
	jmp	g2p96_clut_menu_lut_ready_c87b78j
g2p96_menu_build_rgb565_lut_legacy
	movem.l	d0-d7/a0-a3,-(a7)
	lea	p96menu_rgb565_lut,a1
	move.l	lastpal,d0
	bne.s	.havepal
	move.l	planar_palette,d0
	beq.w	.black_all
.havepal
	move.l	d0,a3
	moveq	#0,d7
.lut_loop
	cmp	#256,d7
	bge.w	.done
	; The original menu font temporarily pokes only the first four colours.
	; lastpal remains the grey/backdrop palette, so copy the AGA font entries
	; for indices 0..3 when available.
	tst	aga
	beq.s	.no_font_override
	cmp	#4,d7
	bcc.s	.no_font_override
	lea	fontpal_aga12,a0
	move	d7,d6
	lsl	#2,d6
	move	0(a0,d6.w),d0
	move	2(a0,d6.w),d2
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra.s	.store
.no_font_override
	move	d7,d6
	tst	aga
	beq.s	.ecs
	lsl	#2,d6		; AGA high/low RGB12 pair
	bra.s	.paladdr
.ecs
	add	d6,d6
.paladdr
	move	0(a3,d6.w),d0
	tst	aga
	beq.s	.ecs_convert
	move	2(a3,d6.w),d2
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra.s	.store
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

p96menu_rgb565_lut
	dcb.w	256,0
p96menu_y_start
	dc	0
p96menu_y_end
	dc	0
	even


