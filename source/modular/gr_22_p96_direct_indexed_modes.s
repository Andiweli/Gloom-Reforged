; =============================================================================
; c87b78q - direct indexed title/About menus and intermission typewriter
;
; Guarded scope remains deliberately exact:
;   - P96 RGBFB_CLUT
;   - 320x240, target mode 0
;   - standard aspect (no WIDE, no 5:4)
;
; TITLE_BRIDGE menus use the clean packed CLUT stage produced by the confirmed
; c87b78n static publisher. INTERMISSION_BRIDGE glyphs update both the logical
; 320x240 index source and that same packed stage, then publish a complete
; 10-row byte band. Any missing prerequisite tail-calls the mature RGB565 path.
; =============================================================================

p96inter_direct_index_active_c87b78q	dc.w	0
p96title_direct_index_active_c87b78q	dc.w	0
	even

; Generalised direct-menu predicate. The original c87b78p entry JMPs here with
; no code-size change. In-game menus still require the explicit paused-frame
; ready flag; title/About menus require a successfully published direct static
; page, which proves that p96clut_stage_ptr is the current clean background.
g2p96_menu_direct_clut_320_active_c87b78q
	bra.w	g2p96_menu_direct_clut_standard_active_c87b78r
	moveq	#0,d0
	jsr	g2p96_menu_direct_clut_320_geometry_c87b78p
	tst.l	d0
	beq.w	.done
	cmp	#P96DSP_MENU,p96display_state
	beq.w	.ingame
	cmp	#P96DSP_TITLE,p96display_state
	beq.w	.title
	moveq	#0,d0
	bra.w	.done
.ingame
	tst	p96menu_direct_index_ready
	beq.w	.fail
	moveq	#-1,d0
	bra.w	.done
.title
	clr	p96title_direct_index_active_c87b78q
	tst	p96static_direct_valid
	beq.w	.fail
	tst	p96static_direct_clut_state
	beq.w	.fail
	move.l	p96static_direct_index_ptr,d1
	beq.w	.fail
	move.l	p96clut_stage_ptr,d1
	beq.w	.fail
	move.l	p96clut_stage_size,d2
	cmp.l	#76800,d2
	bcs.w	.fail
	move	#-1,p96title_direct_index_active_c87b78q
	moveq	#-1,d0
	bra.w	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d2
	rts

; Quick-menu/title return background restore. The indexed path republishes the
; untouched packed CLUT page through the common official lock/copy/unlock helper.
; Every other target keeps the mature RGB565 restore unchanged.
g2p96_title_restore_staged_background_c87b78q
	movem.l	d0-d3/a0,-(a7)
	jsr	g2p96_menu_direct_clut_320_active_c87b78q
	tst.l	d0
	beq.w	.fallback
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.fallback
	move.l	p96clut_stage_ptr,d0
	beq.w	.fallback
	move.l	d0,p96safe_rect_src_ptr
	move.l	#320,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	#320,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	clr	p96safe_rect_dst_y
	move	#240,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
	tst.l	d0
	beq.w	.fallback
	movem.l	(a7)+,d0-d3/a0
	rts
.fallback
	movem.l	(a7)+,d0-d3/a0
	; Never fall back to the historical direct BitMap-field writer on a CLUT
	; screen. The mature static publisher has the official lock/copy path and
	; can rebuild from either the direct index page or RGB565 RAM cache.
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.legacy
	jsr	g2p96_static_copy_rgb_buffer_to_p96_c87b78n
	rts
.legacy
	jmp	g2p96_title_restore_staged_background_if_active

; Try the exact direct indexed typewriter first. Failure restores all registers
; and enters the confirmed RGB565 staged compositor, which also owns pdelay=0
; fallback behaviour when any dependency is unavailable.
g2p96_intermission_native_typewriter_prepare_c87b78q
	movem.l	d1-d7/a0-a6,-(a7)
	clr	p96inter_direct_index_active_c87b78q
	jsr	g2p96_menu_direct_clut_320_geometry_c87b78p
	tst.l	d0
	beq.w	.fallback
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.w	.fallback
	tst	p96gameplay_persist_active
	beq.w	.fallback
	tst	p96static_direct_valid
	beq.w	.fallback
	tst	p96static_direct_clut_state
	beq.w	.fallback
	move.l	p96static_direct_index_ptr,d1
	beq.w	.fallback
	move.l	p96clut_stage_ptr,d1
	beq.w	.fallback
	cmp	#8,fontw
	bne.w	.fallback
	cmp	#10,fonth
	bne.w	.fallback
	jsr	g2p96_menu_glyph_cache_ensure
	tst.l	d0
	beq.w	.fallback
	jsr	g2p96_menu_glyph_prepare_target_c87b78d
	tst.l	d0
	beq.w	.fallback
	; Rebuild/apply the exact intermission font palette contract. This updates
	; LoadRGB32/reverse keys only; no RGB565 image page is composed here.
	jsr	g2p96_static_build_font_rgb565_lut
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.fallback
	tst	p96clut_palette_dirty
	bne.w	.fallback
	clr	p96menu_batch_active
	clr	p96menu_cache_active
	move	#-1,p96inter_typewriter_active
	move	#-1,p96inter_direct_index_active_c87b78q
	moveq	#-1,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts
.fallback
	movem.l	(a7)+,d1-d7/a0-a6
	jmp	g2p96_intermission_native_typewriter_prepare

; Direct one-byte glyph compositor. Source font indices are already final CLUT
; pens: ordinary intermissions use indices 1..3 after initfontpal; Gloom3/ZM use
; the isolated yellow indices selected by g2inter_prepare_yellow_text.
g2p96_intermission_native_typewriter_char_c87b78q
	tst	p96inter_direct_index_active_c87b78q
	bne.w	.direct
	jmp	g2p96_intermission_native_typewriter_char
.direct
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
	move	d7,d4
	move	d6,d5
	move	d5,p96inter_glyph_y
	moveq	#0,d3
.row
	cmp	#p96menu_glyph_height,d3
	bge.w	.publish
	moveq	#0,d2
.col
	cmp	#p96menu_glyph_width,d2
	bge.w	.next_row
	moveq	#0,d1
	move.b	(a2)+,d1
	beq.w	.next_col
	tst	g2inter_yellow_text_active
	beq.w	.pen_ready
	cmp	#3,d1
	bls.w	.level_ok
	moveq	#3,d1
.level_ok
	subq	#1,d1
	add	d1,d1
	lea	g2inter_yellow_text_indices,a0
	move	0(a0,d1.w),d1
	tst	d1
	bmi.w	.next_col
.pen_ready
	move	d4,d0
	add	d2,d0
	tst	d0
	blt.w	.next_col
	cmp	#320,d0
	bge.w	.next_col
	move	d5,d7
	add	d3,d7
	tst	d7
	blt.w	.next_col
	cmp	#240,d7
	bge.w	.next_col
	move	d7,d6
	mulu	#320,d6
	move.l	p96static_direct_index_ptr,a0
	adda.l	d6,a0
	move.b	d1,0(a0,d0.w)
	move.l	p96clut_stage_ptr,a1
	adda.l	d6,a1
	move.b	d1,0(a1,d0.w)
.next_col
	addq	#1,d2
	bra.w	.col
.next_row
	addq	#1,d3
	bra.w	.row
.publish
	jsr	g2p96_intermission_publish_index_band_c87b78q
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Publish the completed logical glyph band from the packed CLUT stage. At the
; guarded 320x240 geometry source Y equals destination Y and each row is 320 B.
g2p96_intermission_publish_index_band_c87b78q
	movem.l	d0-d4/a0,-(a7)
	move	p96inter_glyph_y,d0
	move	d0,d1
	add	#p96menu_glyph_height,d1
	tst	d0
	bpl.w	.start_ok
	moveq	#0,d0
.start_ok
	cmp	#240,d1
	ble.w	.end_ok
	move	#240,d1
.end_ok
	cmp	d0,d1
	ble.w	.done
	sub	d0,d1
	move.l	p96clut_stage_ptr,p96safe_rect_src_ptr
	move.l	#320,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	#320,p96safe_rect_rowbytes
	move	d0,p96safe_rect_src_y
	move	d0,p96safe_rect_dst_y
	move	d1,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
.done
	movem.l	(a7)+,d0-d4/a0
	rts

; Direct glyphs already updated the logical index page, packed CLUT stage and
; visible row bands. The existing finish routine remains the fallback owner.
g2p96_intermission_native_typewriter_finish_c87b78q
	tst	p96inter_direct_index_active_c87b78q
	bne.w	.direct
	jmp	g2p96_intermission_native_typewriter_finish
.direct
	clr	p96inter_direct_index_active_c87b78q
	clr	p96inter_typewriter_active
	move	#-1,p96static_direct_valid
	move	#-1,p96static_direct_clut_state
	rts
; =============================================================================
; c87b78r - direct indexed standard 1x1/2x2 menu and typewriter geometry
;
; Extends the confirmed direct CLUT composition from 320x240 mode 0 to the
; exact standard 640x480 P96 target mode 1. Logical menu/font coordinates remain 320x240;
; mode 1 writes each logical pixel as a 2x2 block into the packed CLUT stage.
; WIDE, 5:4 and every other geometry retain the confirmed fallback.
; =============================================================================

p96direct_std_scale_c87b78r	dc.w	0	;1=320x240, 2=640x480
p96direct_cache_src_y0_c87b78r	dc.w	0	;logical 320x240 menu Y
p96direct_cache_src_height_c87b78r	dc.w	0	;logical unclipped row height
p96inter_direct_scale_c87b78r	dc.w	0	;latched while typewriter owns display
	even

; d0=-1 for the two exact standard direct-index geometries, otherwise zero.
g2p96_menu_direct_clut_standard_geometry_c87b78r
	jmp	g2p96_menu_direct_clut_standard_geometry_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; General active predicate for in-game and title/About menu owners.
g2p96_menu_direct_clut_standard_active_c87b78r
	movem.l	d1-d2,-(a7)
	moveq	#0,d0
	jsr	g2p96_menu_direct_clut_standard_geometry_c87b78r
	tst.l	d0
	beq.w	.done
	cmp	#P96DSP_MENU,p96display_state
	beq.s	.ingame
	cmp	#P96DSP_TITLE,p96display_state
	beq.s	.title
	moveq	#0,d0
	bra.s	.done
.ingame
	tst	p96menu_direct_index_ready
	beq.s	.fail
	moveq	#-1,d0
	bra.s	.done
.title
	clr	p96title_direct_index_active_c87b78q
	tst	p96static_direct_valid
	beq.s	.fail
	tst	p96static_direct_clut_state
	beq.s	.fail
	move.l	p96static_direct_index_ptr,d1
	beq.s	.fail
	move.l	p96clut_stage_ptr,d1
	beq.s	.fail
	move	#-1,p96title_direct_index_active_c87b78q
	moveq	#-1,d0
	bra.s	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d2
	rts

; Build the full active menu text region from the clean packed index stage.
g2p96_menu_batch_begin_index_standard_c87b78r
	jmp	g2p96_menu_batch_begin_index_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


g2p96_menu_batch_flush_index_standard_c87b78r
	movem.l	d0-d3/a0,-(a7)
	clr	p96menu_direct_index_last_publish
	tst	p96menu_batch_active
	beq.w	.done
	move.l	p96menu_page_cache_ptr,d0
	beq.w	.done
	move.l	d0,p96safe_rect_src_ptr
	moveq	#0,d1
	move	p96menu_batch_rowbytes,d1
	beq.w	.done
	move.l	d1,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d1,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	move	p96menu_batch_dst_y0,p96safe_rect_dst_y
	move	p96menu_batch_height,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
	tst.l	d0
	beq.s	.done
	move	#-1,p96menu_direct_index_last_publish
.done
	movem.l	(a7)+,d0-d3/a0
	rts

; Build one selected/blinking menu-row cache from the clean packed index stage.
g2p96_menu_cache_begin_index_standard_c87b78r
	jmp	g2p96_menu_cache_begin_index_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


g2p96_menu_cache_flush_index_standard_c87b78r
	movem.l	d0-d3/a0,-(a7)
	tst	p96menu_batch_active
	bne.w	.done
	moveq	#0,d0
	move	p96menu_cache_height,d0
	beq.w	.done
	moveq	#0,d1
	move	p96menu_cache_rowbytes,d1
	beq.w	.done
	lea	p96menu_row_cache,a0
	move.l	a0,p96safe_rect_src_ptr
	move.l	d1,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d1,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	move	p96menu_cache_dsty,p96safe_rect_dst_y
	move	d0,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
.done
	movem.l	(a7)+,d0-d3/a0
	rts

; Restore one logical menu row from the untouched packed index stage.
g2p96_menu_restore_current_row_index_standard_c87b78r
	jmp	g2p96_menu_restore_current_row_index_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Plot one logical glyph pixel into the full-menu indexed cache.
g2p96_menu_native_put_pixel_batch_index_standard_c87b78r
	jmp	g2p96_menu_native_put_pixel_batch_index_standard_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Plot one logical glyph pixel into the selected-row indexed cache.
g2p96_menu_native_put_pixel_cache_index_standard_c87b78r
	jmp	g2p96_menu_native_put_pixel_cache_index_standard_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Full title/About background restore for 320x240 or 640x480 standard CLUT.
g2p96_title_restore_staged_background_standard_c87b78r
	movem.l	d0-d4/a0,-(a7)
	jsr	g2p96_menu_direct_clut_standard_active_c87b78r
	tst.l	d0
	beq.w	.fallback
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.fallback
	move.l	p96clut_stage_ptr,d0
	beq.w	.fallback
	moveq	#0,d1
	move	p96target_width,d1
	moveq	#0,d2
	move	p96target_height,d2
	move.l	d0,p96safe_rect_src_ptr
	move.l	d1,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d1,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	clr	p96safe_rect_dst_y
	move	d2,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
	tst.l	d0
	beq.w	.fallback
	movem.l	(a7)+,d0-d4/a0
	rts
.fallback
	movem.l	(a7)+,d0-d4/a0
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.s	.legacy
	jsr	g2p96_static_copy_rgb_buffer_to_p96_c87b78n
	rts
.legacy
	jmp	g2p96_title_restore_staged_background_if_active

; Prepare direct indexed intermission text for the two standard geometries.
g2p96_intermission_native_typewriter_prepare_standard_c87b78r
	jmp	g2p96_intermission_native_typewriter_prepare_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Direct logical glyph compositor with exact 1x1 or 2x2 stage writes.
g2p96_intermission_native_typewriter_char_standard_c87b78r
	jmp	g2p96_intermission_native_typewriter_char_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Publish the completed logical glyph band at the active standard scale.
g2p96_intermission_publish_index_band_standard_c87b78r
	jmp	g2p96_intermission_publish_index_band_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Clear the latched physical scale on every typewriter exit, then retain the
; confirmed q finish/fallback ownership unchanged.
g2p96_intermission_native_typewriter_finish_standard_c87b78r
	jmp	g2p96_intermission_native_typewriter_finish_standard_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.




; -----------------------------------------------------------------------------
; c87b78s: OCS/ECS-host enablement for the already validated standard P96 path.
; Kept at EOF so historical GenAm PC-relative layout is not disturbed.
; -----------------------------------------------------------------------------
	even

; Replaces the former MOVE.W #-1,aga in g2displaymode_apply_runtime with an
; equal-size JSR+NOP. P96 deliberately keeps the 256-colour software core even
; on ECS hardware; only DISPLAY=ECS clears 'aga' in the unchanged code below.
; The chooser/fallback text is patched in writable data with equal-length AGA/
; ECS tokens, so no requester layout or existing pointer changes.
g2p96_patch_host_labels_c87b78s
	move	#-1,aga
	move.b	#'A',g2p96_req_use_aga_host
	move.b	#'G',g2p96_req_use_aga_host+1
	move.b	#'A',g2p96_req_use_aga_host+2
	move.b	#'A',g2p96_req_aga_host
	move.b	#'G',g2p96_req_aga_host+1
	move.b	#'A',g2p96_req_aga_host+2
	move.b	#'A',g2p96_req_nomodes_host
	move.b	#'G',g2p96_req_nomodes_host+1
	move.b	#'A',g2p96_req_nomodes_host+2
	move.b	#'A',g2p96_req_nolib_host
	move.b	#'G',g2p96_req_nolib_host+1
	move.b	#'A',g2p96_req_nolib_host+2
	tst	g2chipset_aga
	bne.s	.done
	move.b	#'E',g2p96_req_use_aga_host
	move.b	#'C',g2p96_req_use_aga_host+1
	move.b	#'S',g2p96_req_use_aga_host+2
	move.b	#'E',g2p96_req_aga_host
	move.b	#'C',g2p96_req_aga_host+1
	move.b	#'S',g2p96_req_aga_host+2
	move.b	#'E',g2p96_req_nomodes_host
	move.b	#'C',g2p96_req_nomodes_host+1
	move.b	#'S',g2p96_req_nomodes_host+2
	move.b	#'E',g2p96_req_nolib_host
	move.b	#'C',g2p96_req_nolib_host+1
	move.b	#'S',g2p96_req_nolib_host+2
.done	rts

; The historical label remains for all existing callers. On an AGA machine it
; still selects AGA. On an OCS/ECS host it selects the native ECS/EHB renderer,
; preventing a missing/invalid/cancelled P96 selection from ever opening AGA.
g2p96_req_select_chipset_fallback_c87b78s
	tst	g2chipset_aga
	beq.s	.ecs
	move	#1,g2display_mode
	move	#-1,aga
	rts
.ecs
	move	#3,g2display_mode
	clr	aga
	rts

; Verify the selected P96 custom screen/window on an ECS host before initmain
; allocates renderer data or chooses 256-colour assets, then write the prominent
; ModeID log for the final P96 or chipset-fallback state.
g2p96_modeid_log_and_ecs_preflight_c87b78s
	jsr	g2p96_ecs_host_preflight_c87b78s
	jsr	g2p96_modeid_log	;log the final P96 state or an explicit user-selected native mode
	rts

; Open and close the exact selected P96 screen/window once on OCS/ECS hardware.
; No bitmap is locked, no palette/frame is rendered and no game allocation has
; happened yet. This makes the later offscreen 256-colour compatibility core a
; safe choice: the only real display has already proved it can open.
g2p96_ecs_host_preflight_c87b78s
	movem.l	d0-d7/a0-a6,-(a7)
	tst	g2p96_req_abort_startup
	bne.w	.done			;CANCEL remains a clean exit, never a fallback
	cmp	#2,g2display_mode
	bne.w	.done
	tst	g2chipset_aga
	bne.w	.done
	cmp	#1,p96modeid_state
	bne.w	.fallback
	move.l	p96modeid,d0
	beq.w	.fallback
	move.l	d0,p96winprobe_displayid_tag+4
	moveq	#0,d0
	move	p96modeid_depth,d0
	move.l	d0,p96winprobe_depth_tag+4
	clr.l	p96winprobe_window_screenptr
	move.l	4.w,a6
	lea	intname,a1
	jsr	-408(a6)		;OldOpenLibrary intuition.library
	move.l	d0,d6
	beq.w	.fallback
	move.l	d6,a6
	sub.l	a0,a0
	lea	p96winprobe_tags,a1
	jsr	-612(a6)		;OpenScreenTagList
	move.l	d0,d5
	beq.s	.close_int_fallback
	move.l	d5,p96winprobe_window_screenptr
	move.l	d6,a6
	lea	p96winprobe_newwindow,a0
	jsr	-204(a6)		;OpenWindow on selected P96 screen
	move.l	d0,d4
	beq.s	.close_screen_fallback
	move.l	d4,a0
	move.l	d6,a6
	jsr	-72(a6)		;CloseWindow
	clr.l	p96winprobe_window_screenptr
	move.l	d5,a0
	move.l	d6,a6
	jsr	-66(a6)		;CloseScreen
	move.l	d6,a1
	move.l	4.w,a6
	jsr	-414(a6)		;CloseLibrary intuition.library
	bra.s	.done
.close_screen_fallback
	clr.l	p96winprobe_window_screenptr
	move.l	d5,a0
	move.l	d6,a6
	jsr	-66(a6)
.close_int_fallback
	move.l	d6,a1
	move.l	4.w,a6
	jsr	-414(a6)
.fallback
	clr.l	p96winprobe_window_screenptr
	lea	g2p96_ecs_preflight_easy_c87b78s,a1
	jsr	g2p96_req_show_easy_a1
	move	#-1,g2p96_req_abort_startup	;c87b79o: selected P96 preflight failure is fatal
	jsr	g2p96_close
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

	even
g2p96_ecs_preflight_easy_c87b78s
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_ecs_preflight_body_c87b78s
	dc.l	g2p96_req_ok

g2p96_ecs_preflight_body_c87b78s
	dc.b	'The selected P96 screen could not be opened',10
	dc.b	'on this OCS/ECS computer.',10,10
	dc.b	'Gloom Reforged will exit instead of switching',10
	dc.b	'to the native ECS/EHB renderer.',0
	even


; On non-AGA hosts expose only the two standard geometries whose complete
; direct-indexed path has been validated: 320x240 and 640x480. AGA hosts retain
; the unchanged six-mode chooser while the remaining geometries are developed.
g2p96_req_build_candidates_host_c87b78s
	jmp	g2p96_req_build_candidates_host_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; P96MODEID overrides on OCS/ECS hosts obey the same release boundary. A valid
; but not-yet-released 5:4/WIDE ID is rejected and falls through to the normal
; filtered chooser instead of bypassing the standard-mode restriction.
g2p96_modeid_override_validate_host_c87b78s
	jmp	g2p96_modeid_override_validate_host_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



; Host-specific no-mode explanation: ECS machines intentionally expose only the
; two completely validated standard CLUT geometries in this release.
g2p96_req_show_nomodes_host_c87b78s
	jmp	g2p96_req_show_nomodes_host_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


	even
g2p96_req_nomodes_ecs_easy_c87b78s
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_nomodes_ecs_body_c87b78s
	dc.l	g2p96_req_ok

g2p96_req_nomodes_ecs_body_c87b78s
	dc.b	'No validated standard P96 mode was found.',10,10
	dc.b	'On OCS/ECS hosts this build enables only',10
	dc.b	'320x240 and 640x480.',10,10
	dc.b	'Gloom Reforged will start in ECS mode.',0
	even



; =============================================================================
; c87b78t - direct indexed P96 5:4 (320x256 / 640x512)
;
; The historical entry labels above retain their byte footprints and trampoline
; here. All new code is appended after c87b78s so no earlier assembled address or
; GenAm PC-relative relationship is displaced.
; =============================================================================
	even

p96direct_yoff_c87b78t		dc.w	0	;physical top offset: 0, 8 or 16
p96inter_direct_yoff_c87b78t	dc.w	0	;latched for intermission glyph output
p96static_fivefour_state_c87b78t	dc.w	0	;-1 when indexed 5:4 page was built
	even


; -----------------------------------------------------------------------------
; Direct static publication: standard modes reuse c87b78n's established stage
; builder. Exact 5:4 modes build the centred indexed page below, including the
; same four-level edge wash formerly produced in RGB565 and reverse-mapped.
; -----------------------------------------------------------------------------
g2p96_static_copy_rgb_buffer_to_p96_c87b78t
	jmp	g2p96_static_copy_rgb_buffer_to_p96_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



; Build a complete 320x256 or 640x512 indexed page in Fast RAM.
; Centre rows are copied directly from the authoritative 320x240 index image.
; Only the decorative 8/16-row edge wash performs RGB565 colour arithmetic in
; Fast RAM to select the nearest already-installed CLUT pen. The visible target
; remains one byte per pixel and is never touched while this routine runs.
g2p96_static_build_direct_clut_fivefour_c87b78t
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7
	clr	p96static_fivefour_state_c87b78t
	tst	g2p96_oneone_mode
	beq.w	.done
	tst	g2p96_wide_mode
	bne.w	.done
	move.l	p96static_direct_index_ptr,a4
	move.l	a4,d0
	beq.w	.done
	move.l	p96clut_stage_ptr,a3
	move.l	a3,d0
	beq.w	.done
	move.l	p96clut_reverse_ptr,a6
	move.l	a6,d0
	beq.w	.done
	moveq	#0,d4
	move	p96target_width,d4
	moveq	#0,d0
	move	p96target_height,d0
	mulu	d4,d0
	cmp.l	p96clut_stage_size,d0
	bhi.w	.done

	move	p96target_mode,d0
	cmp	#0,d0
	bne.s	.check_high
	cmp	#320,d4
	bne.w	.done
	cmp	#256,p96target_height
	bne.w	.done
	moveq	#1,d5		;physical scale
	moveq	#8,d6		;top/bottom border height
	bra.s	.geometry_ok
.check_high
	cmp	#1,d0
	bne.w	.done
	cmp	#640,d4
	bne.w	.done
	cmp	#512,p96target_height
	bne.w	.done
	moveq	#2,d5
	moveq	#16,d6
.geometry_ok
	move	d4,p96gameplay_stage_bpr

	; Top border: source row 0, shade 0..3 from darkest to full.
	moveq	#0,d2		;physical destination row
.top_loop
	cmp	d6,d2
	bge.s	.center_setup
	moveq	#0,d3
	move	d2,d3
	lsl	#2,d3
	divu	d6,d3
	move.l	a4,a2
	move	d2,d0
	mulu	d4,d0
	move.l	a3,a1
	adda.l	d0,a1
	jsr	g2p96_static_emit_index_shaded_row_c87b78t
	addq	#1,d2
	bra.s	.top_loop

.center_setup
	moveq	#0,d2		;logical source y 0..239
.center_loop
	cmp	#240,d2
	bge.s	.bottom_setup
	move.l	a4,a2
	move	d2,d0
	mulu	#320,d0
	adda.l	d0,a2
	move	d2,d0
	mulu	d5,d0
	add	d6,d0
	mulu	d4,d0
	move.l	a3,a1
	adda.l	d0,a1
	cmp	#2,d5
	beq.s	.center_2x
	move.l	a2,a0
	move.l	#320,d0
	move.l	4.w,a6
	jsr	-624(a6)
	bra.s	.center_next
.center_2x
	move.l	a1,a0
	adda.l	d4,a0
	moveq	#0,d1
.center_2x_loop
	cmp	#320,d1
	bge.s	.center_next
	moveq	#0,d0
	move.b	(a2)+,d0
	move.b	d0,(a1)+
	move.b	d0,(a1)+
	move.b	d0,(a0)+
	move.b	d0,(a0)+
	addq	#1,d1
	bra.s	.center_2x_loop
.center_next
	addq	#1,d2
	bra.s	.center_loop

.bottom_setup
	moveq	#0,d2		;border row index 0..d6-1
	move.l	a4,a2
	adda.l	#76480,a2	;source row 239 (239*320)
.bottom_loop
	cmp	d6,d2
	bge.s	.success
	moveq	#0,d3
	move	d6,d3
	subq	#1,d3
	sub	d2,d3
	lsl	#2,d3
	divu	d6,d3
	move	d6,d0
	move	#240,d1
	mulu	d5,d1
	add	d1,d0		;physical y = border + centre + border index
	add	d2,d0
	mulu	d4,d0
	move.l	a3,a1
	adda.l	d0,a1
	jsr	g2p96_static_emit_index_shaded_row_c87b78t
	addq	#1,d2
	bra.s	.bottom_loop
.success
	move	#-1,p96static_fivefour_state_c87b78t
	moveq	#-1,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; a2=320 source indices, a1=physical destination row, d3=shade 0..3,
; d5=horizontal scale 1/2. Produces final CLUT pens through the exact installed
; RGB565 reverse map, matching the mature 5:4 edge-wash appearance.
g2p96_static_emit_index_shaded_row_c87b78t
	movem.l	d0-d7/a0-a5,-(a7)
	lea	p96static_rgb565_lut,a5
	move.l	p96clut_reverse_ptr,a4
	moveq	#0,d7
.pixel
	cmp	#320,d7
	bge.s	.done
	moveq	#0,d0
	move.b	0(a2,d7.w),d0
	add	d0,d0
	move	0(a5,d0.w),d2
	jsr	g2wide_rgb565_shade
	moveq	#0,d0
	move	d2,d0
	moveq	#0,d1
	move.b	0(a4,d0.l),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.next
	move.b	d1,(a1)+
.next
	addq	#1,d7
	bra.s	.pixel
.done
	movem.l	(a7)+,d0-d7/a0-a5
	rts


; -----------------------------------------------------------------------------
; Unified direct indexed geometry predicate for standard and exact 5:4 modes.
; d0=-1 on success, p96direct_std_scale=1/2, p96direct_yoff=0/8/16.
; -----------------------------------------------------------------------------
g2p96_menu_direct_clut_standard_geometry_c87b78t
	jmp	g2p96_menu_direct_clut_standard_geometry_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



; Build the full active menu text region from the centred packed index stage.
g2p96_menu_batch_begin_index_standard_c87b78t
	movem.l	d0-d7/a0-a6,-(a7)
	clr	p96menu_batch_active
	clr	p96menu_direct_index_batch
	jsr	g2p96_menu_direct_clut_standard_active_c87b78r
	tst.l	d0
	beq.w	.done
	move.l	p96menu_page_cache_ptr,d0
	bne.s	.have_cache
	move.l	#900000,d0
	moveq	#1,d1
	lea	p96menu_page_cache_name,a0
	jsr	allocmem_
	move.l	d0,p96menu_page_cache_ptr
	beq.w	.done
.have_cache
	moveq	#0,d4
	move	p96target_width,d4
	beq.w	.done
	move	d4,p96menu_batch_rowbytes
	move.l	d4,p96menu_batch_bpr
	clr.l	p96menu_batch_dstbase

	move	menuy,d0
	bpl.s	.y0_ok
	moveq	#0,d0
.y0_ok
	move	d0,p96menu_batch_src_y0
	move	numopts,d1
	move	fonth,d2
	mulu	d2,d1
	add	menuy,d1
	cmp	#240,d1
	ble.s	.y1_ok
	move	#240,d1
.y1_ok
	cmp	d0,d1
	ble.w	.done
	move	d1,p96menu_batch_src_y1
	sub	d0,d1
	move	d1,p96menu_batch_src_height
	move	p96direct_std_scale_c87b78r,d3
	cmp	#2,d3
	bne.s	.scaled
	add	d0,d0
	add	d1,d1
.scaled
	add	p96direct_yoff_c87b78t,d0
	move	d0,p96menu_batch_dst_y0
	move	d1,p96menu_batch_height
	beq.w	.done
	move.l	p96clut_stage_ptr,a0
	moveq	#0,d2
	move	d0,d2
	mulu	d4,d2
	adda.l	d2,a0
	move.l	p96menu_page_cache_ptr,a1
	moveq	#0,d2
	move	d1,d2
	mulu	d4,d2
	move.l	d2,d0
	move.l	4.w,a6
	jsr	-624(a6)
	move	#-1,p96menu_direct_index_batch
	move	#-1,p96menu_batch_active
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts


; Build one selected/blinking row cache from the centred packed index stage.
g2p96_menu_cache_begin_index_standard_c87b78t
	movem.l	d0-d7/a0-a2/a6,-(a7)
	clr	p96menu_cache_active
	clr	p96menu_direct_index_cache
	tst	p96menu_batch_active
	bne.w	.done
	jsr	g2p96_menu_direct_clut_standard_active_c87b78r
	tst.l	d0
	beq.w	.done
	move	p96menu_y_start,d2
	bpl.s	.start_ok
	moveq	#0,d2
.start_ok
	move	p96menu_y_end,d3
	cmp	#240,d3
	ble.s	.end_ok
	move	#240,d3
.end_ok
	cmp	d3,d2
	bge.w	.done
	move	d2,p96direct_cache_src_y0_c87b78r
	move	d3,d0
	sub	d2,d0
	move	d0,p96direct_cache_src_height_c87b78r
	moveq	#0,d4
	move	p96target_width,d4
	move	d4,p96menu_cache_rowbytes
	move	d2,d0
	sub	d2,d3
	move	p96direct_std_scale_c87b78r,d1
	cmp	#2,d1
	bne.s	.scaled
	add	d0,d0
	add	d3,d3
.scaled
	add	p96direct_yoff_c87b78t,d0
	move	d0,p96menu_cache_dsty
	move	d3,p96menu_cache_height
	moveq	#0,d5
	move	d3,d5
	mulu	d4,d5
	cmp.l	#36000,d5
	bhi.w	.done
	move.l	p96clut_stage_ptr,a0
	moveq	#0,d6
	move	d0,d6
	mulu	d4,d6
	adda.l	d6,a0
	lea	p96menu_row_cache,a1
	move.l	d5,d0
	move.l	4.w,a6
	jsr	-624(a6)
	move	#-1,p96menu_direct_index_cache
	move	#-1,p96menu_cache_active
.done
	movem.l	(a7)+,d0-d7/a0-a2/a6
	rts


; Restore one logical menu row from the centred authoritative index stage.
g2p96_menu_restore_current_row_index_standard_c87b78t
	movem.l	d1-d7/a0-a2,-(a7)
	moveq	#0,d7
	jsr	g2p96_menu_direct_clut_standard_active_c87b78r
	tst.l	d0
	beq.w	.done
	move	p96menu_y_start,d2
	bpl.s	.start_ok
	moveq	#0,d2
.start_ok
	move	p96menu_y_end,d3
	cmp	#240,d3
	ble.s	.end_ok
	move	#240,d3
.end_ok
	cmp	d3,d2
	bge.w	.done
	move	p96direct_std_scale_c87b78r,d1
	cmp	#2,d1
	bne.s	.scaled
	add	d2,d2
	add	d3,d3
.scaled
	add	p96direct_yoff_c87b78t,d2
	add	p96direct_yoff_c87b78t,d3
	move	d3,d4
	sub	d2,d4
	moveq	#0,d5
	move	p96target_width,d5
	move.l	p96clut_stage_ptr,p96safe_rect_src_ptr
	move.l	d5,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d5,p96safe_rect_rowbytes
	move	d2,p96safe_rect_src_y
	move	d2,p96safe_rect_dst_y
	move	d4,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
	move.l	d0,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a2
	rts


; Prepare the direct indexed typewriter and latch both scale and centre offset.
g2p96_intermission_native_typewriter_prepare_standard_c87b78t
	jmp	g2p96_intermission_native_typewriter_prepare_standard_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



; Direct glyph compositor for standard and centred 5:4 pages.
g2p96_intermission_native_typewriter_char_standard_c87b78t
	jmp	g2p96_intermission_native_typewriter_char_standard_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



; Publish the completed glyph band at its centred physical Y position.
g2p96_intermission_publish_index_band_standard_c87b78t
	movem.l	d0-d5/a0,-(a7)
	move	p96inter_glyph_y,d0
	move	d0,d1
	add	#p96menu_glyph_height,d1
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
	move	p96inter_direct_scale_c87b78r,d2
	cmp	#2,d2
	bne.s	.scaled
	add	d0,d0
	add	d1,d1
.scaled
	add	p96inter_direct_yoff_c87b78t,d0
	add	p96inter_direct_yoff_c87b78t,d1
	sub	d0,d1
	moveq	#0,d3
	move	p96target_width,d3
	move.l	p96clut_stage_ptr,p96safe_rect_src_ptr
	move.l	d3,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d3,p96safe_rect_rowbytes
	move	d0,p96safe_rect_src_y
	move	d0,p96safe_rect_dst_y
	move	d1,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
.done
	movem.l	(a7)+,d0-d5/a0
	rts


g2p96_intermission_native_typewriter_finish_standard_c87b78t
	jmp	g2p96_intermission_native_typewriter_finish_standard_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



; -----------------------------------------------------------------------------
; OCS/ECS chooser release boundary: standard + 5:4 are now validated code paths.
; WIDE 428x240/854x480 remains filtered until its dedicated indexed edge-shade
; and menu geometry pass is completed.
; -----------------------------------------------------------------------------
g2p96_req_build_candidates_host_c87b78t
	jmp	g2p96_req_build_candidates_host_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



g2p96_modeid_override_validate_host_c87b78t
	jmp	g2p96_modeid_override_validate_host_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.



g2p96_req_show_nomodes_host_c87b78t
	jmp	g2p96_req_show_nomodes_host_c87b78u
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


	even
g2p96_req_nomodes_ecs_easy_c87b78t
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_nomodes_ecs_body_c87b78t
	dc.l	g2p96_req_ok

g2p96_req_nomodes_ecs_body_c87b78t
	dc.b	'No validated standard or 5:4 P96 mode was found.',10,10
	dc.b	'On OCS/ECS hosts this build enables 320x240,',10
	dc.b	'320x256, 640x480 and 640x512.',10,10
	dc.b	'Gloom Reforged will start in ECS mode.',0
	even



; =============================================================================
; c87b78u - direct indexed P96 WIDE (428x240 / 854x480)
;
; Exact native WIDE gameplay was already emitted directly by c87b78m from the
; 428-column chunky renderer. This block completes the remaining visible owners:
; static artwork, title/About, in-game menus and intermission text. Logical
; artwork/font coordinates remain 320x240 and are centred at physical X=54 in
; 428x240 or X=107 in 854x480. All composition remains in Fast RAM; the P96
; bitmap is locked only for the completed linear copy.
; =============================================================================
	even

p96direct_xoff_c87b78u		dc.w	0	;0 standard/5:4, 54 WIDE, 107 WIDE HIRES
p96inter_direct_xoff_c87b78u	dc.w	0	;latched while intermission owns output
p96static_wide_state_c87b78u	dc.w	0	;-1 after indexed WIDE page completion
	even


; -----------------------------------------------------------------------------
; Direct static publication for all six released exact geometries.
; -----------------------------------------------------------------------------
g2p96_static_copy_rgb_buffer_to_p96_c87b78u
	movem.l	d0-d3/a0-a2,-(a7)
	clr	p96static_direct_clut_state
	clr	p96static_fivefour_state_c87b78t
	clr	p96static_wide_state_c87b78u
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.fallback
	tst	p96clut_runtime_ready
	beq.w	.fallback
	tst	p96static_direct_valid
	beq.w	.fallback
	move.l	p96static_direct_index_ptr,d0
	beq.w	.fallback
	tst	g2p96_wide_mode
	beq.s	.not_wide
	jsr	g2p96_static_build_direct_clut_wide_c87b78u
	bra.s	.built
.not_wide
	tst	g2p96_oneone_mode
	beq.s	.standard
	jsr	g2p96_static_build_direct_clut_fivefour_c87b78t
	bra.s	.built
.standard
	jsr	g2p96_static_build_direct_clut_stage_c87b78n
.built
	tst.l	d0
	beq.w	.fallback
	jsr	g2p96_gameplay_select_visible_bitmap
	tst.l	d0
	beq.w	.fallback
	jsr	g2p96_gameplay_copy_clut_stage_to_bitmap_a2_c87b78m
	tst.l	d0
	beq.w	.fallback
	move	#-1,p96static_direct_clut_state
	movem.l	(a7)+,d0-d3/a0-a2
	rts
.fallback
	movem.l	(a7)+,d0-d3/a0-a2
	jmp	g2p96_static_copy_rgb_buffer_to_p96


; Build 428x240 or 854x480 directly from the authoritative 320x240 index page.
; Centre artwork stays pixel exact (or exact 2x2); only the physical side wash
; uses the mature RGB565 shade arithmetic as a temporary key to select an
; already installed CLUT pen. No RGB565 screen/frame is produced.
g2p96_static_build_direct_clut_wide_c87b78u
	jmp	g2p96_static_build_direct_clut_wide_c87b78v
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; a2=320 source indices, a1=first destination row, a0=second row when d5=2,
; d5=centre scale 1/2, d6=physical border 54/107.
g2p96_static_emit_index_wide_row_c87b78u
	movem.l	d0-d7/a0-a6,-(a7)
	lea	p96static_rgb565_lut,a5
	move.l	p96clut_reverse_ptr,a4

	; Left edge colour, darkest at physical outer edge.
	moveq	#0,d0
	move.b	(a2),d0
	add	d0,d0
	move	0(a5,d0.w),d7
	moveq	#0,d4
.left
	cmp	d6,d4
	bge.s	.center
	moveq	#0,d3
	move	d4,d3
	lsl	#2,d3
	divu	d6,d3
	move	d7,d2
	jsr	g2wide_rgb565_shade
	moveq	#0,d0
	move	d2,d0
	moveq	#0,d1
	move.b	0(a4,d0.l),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.left_next
	move.b	d1,(a0)+
.left_next
	addq	#1,d4
	bra.s	.left

.center
	moveq	#0,d4
.center_loop
	cmp	#320,d4
	bge.s	.right_setup
	moveq	#0,d1
	move.b	0(a2,d4.w),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.center_next
	move.b	d1,(a1)+
	move.b	d1,(a0)+
	move.b	d1,(a0)+
.center_next
	addq	#1,d4
	bra.s	.center_loop

.right_setup
	moveq	#0,d0
	move.b	319(a2),d0
	add	d0,d0
	move	0(a5,d0.w),d7
	moveq	#0,d4
.right
	cmp	d6,d4
	bge.s	.done
	moveq	#0,d3
	move	d6,d3
	subq	#1,d3
	sub	d4,d3
	lsl	#2,d3
	divu	d6,d3
	move	d7,d2
	jsr	g2wide_rgb565_shade
	moveq	#0,d0
	move	d2,d0
	moveq	#0,d1
	move.b	0(a4,d0.l),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.right_next
	move.b	d1,(a0)+
.right_next
	addq	#1,d4
	bra.s	.right
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts


; -----------------------------------------------------------------------------
; Unified geometry: standard, 5:4 and exact WIDE.
; d0=-1, scale=1/2, xoff=0/54/107 and yoff=0/8/16 on success.
; -----------------------------------------------------------------------------
g2p96_menu_direct_clut_standard_geometry_c87b78u
	movem.l	d1-d4,-(a7)
	moveq	#0,d0
	clr	p96direct_std_scale_c87b78r
	clr	p96direct_yoff_c87b78t
	clr	p96direct_xoff_c87b78u
	cmp	#2,g2display_mode
	bne.w	.done
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done

	tst	g2p96_wide_mode
	beq.s	.not_wide
	tst	g2p96_oneone_mode
	bne.w	.done
	move	p96target_mode,d1
	cmp	#3,d1
	bne.s	.wide_high
	cmp	#428,p96target_width
	bne.w	.done
	cmp	#240,p96target_height
	bne.w	.done
	move	#1,p96direct_std_scale_c87b78r
	move	#54,p96direct_xoff_c87b78u
	bra.w	.size
.wide_high
	cmp	#2,d1
	bne.w	.done
	cmp	#854,p96target_width
	bne.w	.done
	cmp	#480,p96target_height
	bne.w	.done
	move	#2,p96direct_std_scale_c87b78r
	move	#107,p96direct_xoff_c87b78u
	bra.w	.size

.not_wide
	move	p96target_mode,d1
	cmp	#0,d1
	beq.s	.low
	cmp	#1,d1
	bne.w	.done
	cmp	#640,p96target_width
	bne.w	.done
	tst	g2p96_oneone_mode
	beq.s	.high_standard
	cmp	#512,p96target_height
	bne.w	.done
	move	#16,p96direct_yoff_c87b78t
	bra.s	.high_ok
.high_standard
	cmp	#480,p96target_height
	bne.w	.done
.high_ok
	move	#2,p96direct_std_scale_c87b78r
	bra.s	.size
.low
	cmp	#320,p96target_width
	bne.w	.done
	tst	g2p96_oneone_mode
	beq.s	.low_standard
	cmp	#256,p96target_height
	bne.w	.done
	move	#8,p96direct_yoff_c87b78t
	bra.s	.low_ok
.low_standard
	cmp	#240,p96target_height
	bne.w	.done
.low_ok
	move	#1,p96direct_std_scale_c87b78r
.size
	move.l	p96clut_stage_ptr,d1
	beq.s	.fail
	moveq	#0,d2
	move	p96target_width,d2
	moveq	#0,d3
	move	p96target_height,d3
	mulu	d2,d3
	move.l	p96clut_stage_size,d4
	cmp.l	d3,d4
	bcs.s	.fail
	moveq	#-1,d0
	bra.s	.done
.fail
	clr	p96direct_std_scale_c87b78r
	clr	p96direct_yoff_c87b78t
	clr	p96direct_xoff_c87b78u
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d4
	rts


; Plot one logical glyph pixel into a full-width indexed batch cache.
g2p96_menu_native_put_pixel_batch_index_standard_c87b78u
	movem.l	d0-d7/a0-a3,-(a7)
	tst	d0
	blt.w	.done
	cmp	#320,d0
	bge.w	.done
	sub	p96menu_batch_src_y0,d1
	blt.w	.done
	cmp	p96menu_batch_src_height,d1
	bge.w	.done
	move.l	p96menu_page_cache_ptr,a1
	move.l	a1,d3
	beq.w	.done
	move.l	p96clut_reverse_ptr,a0
	move.l	a0,d3
	beq.w	.done
	moveq	#0,d3
	move	d2,d3
	moveq	#0,d7
	move.b	0(a0,d3.l),d7
	moveq	#0,d4
	move	p96target_width,d4
	move	p96direct_std_scale_c87b78r,d5
	cmp	#2,d5
	beq.s	.scale2
	move	d1,d6
	mulu	d4,d6
	adda.l	d6,a1
	add	p96direct_xoff_c87b78u,d0
	adda.w	d0,a1
	move.b	d7,(a1)
	bra.w	.done
.scale2
	add	d1,d1
	move	d1,d6
	mulu	d4,d6
	adda.l	d6,a1
	add	d0,d0
	add	p96direct_xoff_c87b78u,d0
	adda.w	d0,a1
	move.l	a1,a2
	adda.l	d4,a2
	move.b	d7,(a1)
	move.b	d7,1(a1)
	move.b	d7,(a2)
	move.b	d7,1(a2)
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts


; Plot one logical glyph pixel into a full-width selected-row cache.
g2p96_menu_native_put_pixel_cache_index_standard_c87b78u
	movem.l	d0-d7/a0-a3,-(a7)
	tst	d0
	blt.w	.done
	cmp	#320,d0
	bge.w	.done
	sub	p96direct_cache_src_y0_c87b78r,d1
	blt.w	.done
	move	p96direct_cache_src_height_c87b78r,d3
	cmp	d3,d1
	bge.w	.done
	lea	p96menu_row_cache,a1
	move.l	p96clut_reverse_ptr,a0
	move.l	a0,d3
	beq.w	.done
	moveq	#0,d3
	move	d2,d3
	moveq	#0,d7
	move.b	0(a0,d3.l),d7
	moveq	#0,d4
	move	p96target_width,d4
	move	p96direct_std_scale_c87b78r,d5
	cmp	#2,d5
	beq.s	.scale2
	move	d1,d6
	mulu	d4,d6
	adda.l	d6,a1
	add	p96direct_xoff_c87b78u,d0
	adda.w	d0,a1
	move.b	d7,(a1)
	bra.w	.done
.scale2
	add	d1,d1
	move	d1,d6
	mulu	d4,d6
	adda.l	d6,a1
	add	d0,d0
	add	p96direct_xoff_c87b78u,d0
	adda.w	d0,a1
	move.l	a1,a2
	adda.l	d4,a2
	move.b	d7,(a1)
	move.b	d7,1(a1)
	move.b	d7,(a2)
	move.b	d7,1(a2)
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts


; -----------------------------------------------------------------------------
; Direct indexed intermission text with centred WIDE X origin.
; -----------------------------------------------------------------------------
g2p96_intermission_native_typewriter_prepare_standard_c87b78u
	movem.l	d1-d7/a0-a6,-(a7)
	clr	p96inter_direct_index_active_c87b78q
	clr	p96inter_direct_scale_c87b78r
	clr	p96inter_direct_yoff_c87b78t
	clr	p96inter_direct_xoff_c87b78u
	jsr	g2p96_menu_direct_clut_standard_geometry_c87b78r
	tst.l	d0
	beq.w	.fallback
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.w	.fallback
	tst	p96gameplay_persist_active
	beq.w	.fallback
	tst	p96static_direct_valid
	beq.w	.fallback
	tst	p96static_direct_clut_state
	beq.w	.fallback
	move.l	p96static_direct_index_ptr,d1
	beq.w	.fallback
	move.l	p96clut_stage_ptr,d1
	beq.w	.fallback
	cmp	#8,fontw
	bne.w	.fallback
	cmp	#10,fonth
	bne.w	.fallback
	jsr	g2p96_menu_glyph_cache_ensure
	tst.l	d0
	beq.w	.fallback
	jsr	g2p96_menu_glyph_prepare_target_c87b78d
	tst.l	d0
	beq.w	.fallback
	jsr	g2p96_static_build_font_rgb565_lut
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.fallback
	tst	p96clut_palette_dirty
	bne.w	.fallback
	clr	p96menu_batch_active
	clr	p96menu_cache_active
	move	p96direct_std_scale_c87b78r,p96inter_direct_scale_c87b78r
	move	p96direct_yoff_c87b78t,p96inter_direct_yoff_c87b78t
	move	p96direct_xoff_c87b78u,p96inter_direct_xoff_c87b78u
	move	#-1,p96inter_typewriter_active
	move	#-1,p96inter_direct_index_active_c87b78q
	moveq	#-1,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts
.fallback
	movem.l	(a7)+,d1-d7/a0-a6
	jmp	g2p96_intermission_native_typewriter_prepare


g2p96_intermission_native_typewriter_char_standard_c87b78u
	tst	p96inter_direct_index_active_c87b78q
	bne.w	.direct
	jmp	g2p96_intermission_native_typewriter_char
.direct
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
	move	d7,d4		;logical x
	move	d6,d5		;logical y
	move	d5,p96inter_glyph_y
	moveq	#0,d3
.row
	cmp	#p96menu_glyph_height,d3
	bge.w	.publish
	moveq	#0,d2
.col
	cmp	#p96menu_glyph_width,d2
	bge.w	.next_row
	moveq	#0,d1
	move.b	(a2)+,d1
	beq.w	.next_col
	tst	g2inter_yellow_text_active
	beq.s	.pen_ready
	cmp	#3,d1
	bls.s	.level_ok
	moveq	#3,d1
.level_ok
	subq	#1,d1
	add	d1,d1
	lea	g2inter_yellow_text_indices,a0
	move	0(a0,d1.w),d1
	tst	d1
	bmi.w	.next_col
.pen_ready
	move	d4,d0
	add	d2,d0
	tst	d0
	blt.w	.next_col
	cmp	#320,d0
	bge.w	.next_col
	move	d5,d7
	add	d3,d7
	tst	d7
	blt.w	.next_col
	cmp	#240,d7
	bge.w	.next_col

	; Keep the logical source page authoritative.
	move	d7,d6
	mulu	#320,d6
	move.l	p96static_direct_index_ptr,a0
	adda.l	d6,a0
	move.b	d1,0(a0,d0.w)

	; Final packed stage: logical scale plus exact centre offsets.
	move	p96inter_direct_scale_c87b78r,d6
	cmp	#2,d6
	beq.s	.stage2
	move.l	p96clut_stage_ptr,a1
	move	d7,d6
	add	p96inter_direct_yoff_c87b78t,d6
	mulu	p96target_width,d6
	adda.l	d6,a1
	add	p96inter_direct_xoff_c87b78u,d0
	move.b	d1,0(a1,d0.w)
	bra.s	.next_col
.stage2
	move	d7,d6
	add	d6,d6
	add	p96inter_direct_yoff_c87b78t,d6
	mulu	p96target_width,d6
	move.l	p96clut_stage_ptr,a1
	adda.l	d6,a1
	add	d0,d0
	add	p96inter_direct_xoff_c87b78u,d0
	move.l	a1,a3
	moveq	#0,d6
	move	p96target_width,d6
	adda.l	d6,a3
	move.b	d1,0(a1,d0.w)
	move.b	d1,1(a1,d0.w)
	move.b	d1,0(a3,d0.w)
	move.b	d1,1(a3,d0.w)
.next_col
	addq	#1,d2
	bra.w	.col
.next_row
	addq	#1,d3
	bra.w	.row
.publish
	jsr	g2p96_intermission_publish_index_band_standard_c87b78t
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts


g2p96_intermission_native_typewriter_finish_standard_c87b78u
	clr	p96inter_direct_scale_c87b78r
	clr	p96inter_direct_yoff_c87b78t
	clr	p96inter_direct_xoff_c87b78u
	jmp	g2p96_intermission_native_typewriter_finish_c87b78q


; -----------------------------------------------------------------------------
; OCS/ECS release boundary: all six exact P96 geometries are now enabled.
; -----------------------------------------------------------------------------
g2p96_req_build_candidates_host_c87b78u
	jmp	g2p96_req_build_candidates


g2p96_modeid_override_validate_host_c87b78u
	movem.l	d1-d2,-(a7)
	jsr	g2p96_modeid_override_validate
	tst.l	d0
	beq.w	.done
	tst	g2chipset_aga
	bne.w	.done
	move	p96target_width,d1
	move	p96target_height,d2
	cmp	#320,d1
	bne.s	.check_428
	cmp	#240,d2
	beq.w	.done
	cmp	#256,d2
	beq.w	.done
	bra.s	.reject
.check_428
	cmp	#428,d1
	bne.s	.check_640
	cmp	#240,d2
	beq.w	.done
	bra.s	.reject
.check_640
	cmp	#640,d1
	bne.s	.check_854
	cmp	#480,d2
	beq.w	.done
	cmp	#512,d2
	beq.w	.done
	bra.s	.reject
.check_854
	cmp	#854,d1
	bne.s	.reject
	cmp	#480,d2
	beq.w	.done
.reject
	clr	g2p96_modeid_override_used
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d2
	rts


g2p96_req_show_nomodes_host_c87b78u
	tst	g2chipset_aga
	bne.s	.aga
	lea	g2p96_req_nomodes_ecs_easy_c87b78u,a1
	jmp	g2p96_req_show_easy_a1
.aga
	jmp	g2p96_req_show_nomodes

	even
g2p96_req_nomodes_ecs_easy_c87b78u
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_nomodes_ecs_body_c87b78u
	dc.l	g2p96_req_ok

g2p96_req_nomodes_ecs_body_c87b78u
	dc.b	'No validated P96 mode was found.',10,10
	dc.b	'This build enables 320x240, 320x256, 428x240,',10
	dc.b	'640x480, 640x512 and 854x480 on OCS/ECS hosts.',10,10
	dc.b	'Gloom Reforged will start in ECS mode.',0
	even


; =============================================================================
; c87b78v - WIDE edge continuity and collision-free CLUT menu pens
;
; 1. WIDE static pages no longer require an exact reverse-map hit for each
;    quarter/half/three-quarter edge shade.  A 256x4 lookup table is built once
;    from the active static palette and selects the nearest installed CLUT pen.
;    The original first/last image columns are therefore pulled continuously
;    into the side areas without unmapped (pen 0) gaps.
;
; 2. Menu/font colours no longer overwrite fixed palette indices 0..3.  The
;    current packed background is counted before menu entry. Exact existing
;    colours are reused; otherwise genuinely unused pens are borrowed. Their
;    former source colours are redirected to the nearest unchanged base pen so
;    later FLOOR/CEILING refreshes cannot reintroduce a collision. If no unused
;    pen exists, the closest existing palette colour is used without changing
;    any background pen.
;
; TWO PLAYER remains deliberately unchanged in this regression-fix patch.
; =============================================================================
	even

p96wide_shade_pen_table_c87b78v	dcb.b	1024,0	;256 source pens * 4 shade levels
	even

p96menu_pen_frequency_c87b78v	dcb.l	256,0
p96menu_pen_selected_c87b78v	dcb.b	256,0
p96menu_pen_reserved_c87b78v	dcb.b	256,0
p96menu_clut_pens_c87b78v	dcb.b	4,0
p96menu_clut_dynamic_count_c87b78v	dc.w	0
p96nearest_target_r_c87b78v	dc.w	0
p96nearest_target_g_c87b78v	dc.w	0
p96nearest_target_b_c87b78v	dc.w	0
p96nearest_best_distance_c87b78v	dc.w	0
p96nearest_best_pen_c87b78v	dc.w	0
	even


; -----------------------------------------------------------------------------
; Generic nearest installed CLUT pen search in RGB565 component space.
; in: d2.w = stored R5G6B5PC key, a3 = 256-word base LUT,
;     a4 = optional 256-byte exclusion mask (zero means no exclusions)
; out: d1.w = selected pen 0..255
; -----------------------------------------------------------------------------
g2p96_find_nearest_pen_c87b78v
	movem.l	d0/d2-d7/a0-a4,-(a7)
	move	d2,d6
	ror	#8,d6
	move	d6,d0
	lsr	#8,d0
	lsr	#3,d0
	and	#$001f,d0
	move	d0,p96nearest_target_r_c87b78v
	move	d6,d0
	lsr	#5,d0
	and	#$003f,d0
	move	d0,p96nearest_target_g_c87b78v
	move	d6,d0
	and	#$001f,d0
	move	d0,p96nearest_target_b_c87b78v
	move	#$7fff,p96nearest_best_distance_c87b78v
	clr	p96nearest_best_pen_c87b78v
	move.l	a3,a0
	moveq	#0,d7
.loop
	move.l	a4,d0
	beq.s	.not_excluded
	tst.b	0(a4,d7.w)
	bne.w	.next
.not_excluded
	moveq	#0,d6
	move	(a0),d6
	ror	#8,d6
	moveq	#0,d0

	move	d6,d2
	lsr	#8,d2
	lsr	#3,d2
	and	#$001f,d2
	sub	p96nearest_target_r_c87b78v,d2
	bpl.s	.r_positive
	neg	d2
.r_positive
	add	d2,d0

	move	d6,d2
	lsr	#5,d2
	and	#$003f,d2
	sub	p96nearest_target_g_c87b78v,d2
	bpl.s	.g_positive
	neg	d2
.g_positive
	add	d2,d0

	move	d6,d2
	and	#$001f,d2
	sub	p96nearest_target_b_c87b78v,d2
	bpl.s	.b_positive
	neg	d2
.b_positive
	add	d2,d0

	cmp	p96nearest_best_distance_c87b78v,d0
	bge.s	.next
	move	d0,p96nearest_best_distance_c87b78v
	move	d7,p96nearest_best_pen_c87b78v
	tst	d0
	beq.s	.exact
.next
	addq.l	#2,a0
	addq	#1,d7
	cmp	#256,d7
	blo.w	.loop
	bra.s	.result
.exact
	move	d7,p96nearest_best_pen_c87b78v
.result
	moveq	#0,d1
	move	p96nearest_best_pen_c87b78v,d1
	movem.l	(a7)+,d0/d2-d7/a0-a4
	rts


; -----------------------------------------------------------------------------
; Build source-index/shade-level -> nearest installed static CLUT pen.
; out d0=-1 on success.
; -----------------------------------------------------------------------------
g2p96_wide_build_shade_pen_table_c87b78v
	movem.l	d1-d7/a0-a5,-(a7)
	moveq	#0,d0
	lea	p96static_rgb565_lut,a3
	move.l	a3,d1
	beq.w	.done
	lea	p96wide_shade_pen_table_c87b78v,a5
	suba.l	a4,a4		;no exclusions
	moveq	#0,d7		;source pen
.pen_loop
	move	d7,d1
	add	d1,d1
	move	0(a3,d1.w),d6	;base RGB565 key
	moveq	#0,d3		;shade 0..3
.shade_loop
	move	d6,d2
	jsr	g2wide_rgb565_shade
	jsr	g2p96_find_nearest_pen_c87b78v
	move.b	d1,(a5)+
	addq	#1,d3
	cmp	#4,d3
	blo.s	.shade_loop
	addq	#1,d7
	cmp	#256,d7
	blo.s	.pen_loop
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a5
	rts


; -----------------------------------------------------------------------------
; Correct direct-index WIDE static builder. Centre pixels remain exact; side
; extensions use the nearest installed palette pen for the established four
; shade levels, so no unmapped reverse key can create a black/missing segment.
; -----------------------------------------------------------------------------
g2p96_static_build_direct_clut_wide_c87b78v
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d0
	clr	p96static_wide_state_c87b78u
	tst	g2p96_wide_mode
	beq.w	.done
	tst	g2p96_oneone_mode
	bne.w	.done
	move.l	p96static_direct_index_ptr,a4
	move.l	a4,d1
	beq.w	.done
	move.l	p96clut_stage_ptr,a3
	move.l	a3,d1
	beq.w	.done
	moveq	#0,d4
	move	p96target_width,d4
	moveq	#0,d1
	move	p96target_height,d1
	mulu	d4,d1
	cmp.l	p96clut_stage_size,d1
	bhi.w	.done

	move	p96target_mode,d1
	cmp	#3,d1
	bne.s	.check_high
	cmp	#428,d4
	bne.w	.done
	cmp	#240,p96target_height
	bne.w	.done
	moveq	#1,d5
	moveq	#54,d6
	bra.s	.geometry_ok
.check_high
	cmp	#2,d1
	bne.w	.done
	cmp	#854,d4
	bne.w	.done
	cmp	#480,p96target_height
	bne.w	.done
	moveq	#2,d5
	move	#107,d6
.geometry_ok
	jsr	g2p96_wide_build_shade_pen_table_c87b78v
	tst.l	d0
	beq.w	.done
	move	d4,p96gameplay_stage_bpr
	moveq	#0,d7
.row
	cmp	#240,d7
	bge.s	.success
	move.l	a4,a2
	move	d7,d1
	mulu	#320,d1
	adda.l	d1,a2
	move	d7,d1
	mulu	d5,d1
	mulu	d4,d1
	move.l	a3,a1
	adda.l	d1,a1
	move.l	a1,a0
	cmp	#2,d5
	bne.s	.emit
	adda.l	d4,a0
.emit
	jsr	g2p96_static_emit_index_wide_row_c87b78v
	addq	#1,d7
	bra.s	.row
.success
	move	#-1,p96static_wide_state_c87b78u
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts


; a2=320 source indices, a1=first destination row, a0=second row for 2x,
; d5=scale 1/2, d6=physical side extension 54/107.
g2p96_static_emit_index_wide_row_c87b78v
	movem.l	d0-d7/a0-a5,-(a7)
	lea	p96wide_shade_pen_table_c87b78v,a4

	moveq	#0,d7
	move.b	(a2),d7
	lsl	#2,d7
	moveq	#0,d4
.left
	cmp	d6,d4
	bge.s	.center
	moveq	#0,d3
	move	d4,d3
	lsl	#2,d3
	divu	d6,d3
	move	d7,d0
	add	d3,d0
	moveq	#0,d1
	move.b	0(a4,d0.w),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.left_next
	move.b	d1,(a0)+
.left_next
	addq	#1,d4
	bra.s	.left

.center
	moveq	#0,d4
.center_loop
	cmp	#320,d4
	bge.s	.right_setup
	moveq	#0,d1
	move.b	0(a2,d4.w),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.center_next
	move.b	d1,(a1)+
	move.b	d1,(a0)+
	move.b	d1,(a0)+
.center_next
	addq	#1,d4
	bra.s	.center_loop

.right_setup
	moveq	#0,d7
	move.b	319(a2),d7
	lsl	#2,d7
	moveq	#0,d4
.right
	cmp	d6,d4
	bge.s	.done
	moveq	#0,d3
	move	d6,d3
	subq	#1,d3
	sub	d4,d3
	lsl	#2,d3
	divu	d6,d3
	move	d7,d0
	add	d3,d0
	moveq	#0,d1
	move.b	0(a4,d0.w),d1
	move.b	d1,(a1)+
	cmp	#2,d5
	bne.s	.right_next
	move.b	d1,(a0)+
.right_next
	addq	#1,d4
	bra.s	.right
.done
	movem.l	(a7)+,d0-d7/a0-a5
	rts


; -----------------------------------------------------------------------------
; Count the currently composed packed background and choose collision-free
; menu pens. Exact existing colours are reused. Missing colours borrow only
; pens whose current frequency is zero; if no such pen exists, the closest
; unchanged base colour is used instead.
; out d0=-1 on success.
; -----------------------------------------------------------------------------
g2p96_menu_prepare_isolated_pens_c87b78v
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d0
	move.l	p96clut_stage_ptr,a0
	move.l	a0,d1
	beq.w	.done
	move.l	p96clut_active_lut_ptr,a3
	move.l	a3,d1
	beq.w	.done
	move.l	p96clut_reverse_ptr,d1
	beq.w	.done
	moveq	#0,d6
	move	p96target_width,d6
	moveq	#0,d7
	move	p96target_height,d7
	mulu	d6,d7
	tst.l	d7
	beq.w	.done
	cmp.l	p96clut_stage_size,d7
	bhi.w	.done

	lea	p96menu_pen_frequency_c87b78v,a1
	move	#255,d1
.clear_freq
	clr.l	(a1)+
	dbf	d1,.clear_freq
	lea	p96menu_pen_selected_c87b78v,a1
	lea	p96menu_pen_reserved_c87b78v,a2
	move	#255,d1
.clear_masks
	clr.b	(a1)+
	clr.b	(a2)+
	dbf	d1,.clear_masks
	clr	p96menu_clut_dynamic_count_c87b78v

	lea	p96menu_pen_frequency_c87b78v,a1
	subq.l	#1,d7
.count_loop
	moveq	#0,d1
	move.b	(a0)+,d1
	lsl	#2,d1
	addq.l	#1,0(a1,d1.w)
	subq.l	#1,d7
	bpl.s	.count_loop

	lea	p96menu_rgb565_lut,a5
	lea	p96menu_clut_pens_c87b78v,a6
	moveq	#0,d7		;font level 0..3
.select_loop
	move	d7,d0
	add	d0,d0
	move	0(a5,d0.w),d6	;desired key

	; Prefer an exact base-palette colour.
	move.l	a3,a0
	moveq	#0,d5
.exact_search
	cmp	(a0)+,d6
	beq.s	.exact_found
	addq	#1,d5
	cmp	#256,d5
	blo.s	.exact_search

	; Otherwise borrow an actually unused pen, highest indices first.
	move	#255,d5
.find_unused
	lea	p96menu_pen_selected_c87b78v,a1
	tst.b	0(a1,d5.w)
	bne.s	.unused_next
	move	d5,d0
	lsl	#2,d0
	lea	p96menu_pen_frequency_c87b78v,a1
	tst.l	0(a1,d0.w)
	bne.s	.unused_next
	; Do not borrow a currently unused base pen whose exact colour is needed
	; by another font level later in this same four-colour contract.
	move	d5,d0
	add	d0,d0
	move	0(a3,d0.w),d2
	lea	p96menu_rgb565_lut,a0
	moveq	#3,d1
.protect_exact
	cmp	(a0)+,d2
	beq.s	.unused_next
	dbf	d1,.protect_exact
	bra.s	.unused_found
.unused_next
	subq	#1,d5
	bpl.s	.find_unused

	; Fully occupied palette: use the closest unchanged base colour.
	move	d6,d2
	lea	p96menu_pen_reserved_c87b78v,a4
	jsr	g2p96_find_nearest_pen_c87b78v
	move	d1,d5
	bra.s	.store_selected

.exact_found
	bra.s	.store_selected

.unused_found
	lea	p96menu_pen_reserved_c87b78v,a1
	move.b	#-1,0(a1,d5.w)
	addq	#1,p96menu_clut_dynamic_count_c87b78v

.store_selected
	move.b	d5,(a6)+
	lea	p96menu_pen_selected_c87b78v,a1
	move.b	#-1,0(a1,d5.w)
	addq	#1,d7
	cmp	#4,d7
	blo.w	.select_loop

	; Install mappings. Borrowed pens first redirect their original source key
	; to the nearest non-borrowed base colour, protecting later menu refreshes.
	moveq	#0,d7
.install_loop
	moveq	#0,d5
	lea	p96menu_clut_pens_c87b78v,a0
	move.b	0(a0,d7.w),d5
	lea	p96menu_pen_reserved_c87b78v,a1
	tst.b	0(a1,d5.w)
	beq.s	.map_font_key

	move	d5,d0
	add	d0,d0
	move	0(a3,d0.w),d2	;borrowed pen's original colour
	lea	p96menu_pen_reserved_c87b78v,a4
	jsr	g2p96_find_nearest_pen_c87b78v
	moveq	#0,d0
	move	d2,d0
	move.l	p96clut_reverse_ptr,a0
	move.b	d1,0(a0,d0.l)

	; Replace only this unused palette entry with the requested font colour.
	move	d7,d0
	add	d0,d0
	move	0(a5,d0.w),d2
	lea	p96palette_loadrgb32_table+4,a1
	moveq	#0,d0
	move	d5,d0
	mulu	#12,d0
	adda.l	d0,a1
	move	d2,d0
	jsr	g2p96_clut_store_rgb32_from_word_c87b78j
	bra.s	.map_font_key_ready

.map_font_key
	move	d7,d0
	add	d0,d0
	move	0(a5,d0.w),d2
.map_font_key_ready
	moveq	#0,d0
	move	d2,d0
	move.l	p96clut_reverse_ptr,a0
	move.b	d5,0(a0,d0.l)
	addq	#1,d7
	cmp	#4,d7
	blo.w	.install_loop
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts


; -----------------------------------------------------------------------------
; Collision-free replacement for the historical fixed-pen 0..3 overlay.
; -----------------------------------------------------------------------------
g2p96_clut_overlay_menu_lut_c87b78v
	movem.l	d0-d7/a0-a6,-(a7)
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done

	tst	p96clut_active_role
	bne.s	.base_ready
	cmp	#P96DSP_MENU,p96display_state
	beq.s	.restore_gameplay_base
	cmp	#P96DSP_TITLE,p96display_state
	beq.s	.restore_static_base
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.w	.done
.restore_static_base
	lea	p96static_rgb565_lut,a0
	moveq	#2,d0
	jsr	g2p96_clut_install_full_lut_c87b78j
	bra.s	.base_ready_check
.restore_gameplay_base
	lea	p96gameplay_rgb565_source_lut,a0
	moveq	#1,d0
	jsr	g2p96_clut_install_full_lut_c87b78j
.base_ready_check
	tst	p96clut_active_role
	beq.w	.done
.base_ready
	jsr	g2p96_menu_prepare_isolated_pens_c87b78v
	tst.l	d0
	beq.w	.done
	jsr	g2p96_clut_apply_table_c87b78j
	move.l	d0,d6
	move	#3,p96clut_active_role
	tst.l	d6
	beq.s	.pending
	clr	p96clut_palette_dirty
	bra.s	.done
.pending
	move	#-1,p96clut_palette_dirty
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts


; -----------------------------------------------------------------------------
; Direct indexed intermission glyph compositor using the dynamically selected
; ordinary font pens. Special Gloom3/ZM yellow indices remain unchanged.
; -----------------------------------------------------------------------------
g2p96_intermission_native_typewriter_char_standard_c87b78v
	tst	p96inter_direct_index_active_c87b78q
	bne.w	.direct
	jmp	g2p96_intermission_native_typewriter_char
.direct
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96inter_typewriter_active
	beq.w	.done
	moveq	#0,d0
	move.b	-1(a4),d0
	cmp.b	#' ',d0
	beq.w	.done
	cmp.b	#$5c,d0	; c87b78w: GenAm-safe backslash byte literal
	beq.w	.done
	cmp.b	#"'",d0
	beq.w	.done
	jsr	g2p96_menu_glyph_calcchar
	cmp	#-1,d0
	beq.w	.done
	move.l	p96menu_glyph_cache_ptr,a2
	mulu	#p96menu_glyph_bytes,d0
	adda.l	d0,a2
	move	d7,d4
	move	d6,d5
	move	d5,p96inter_glyph_y
	moveq	#0,d3
.row
	cmp	#p96menu_glyph_height,d3
	bge.w	.publish
	moveq	#0,d2
.col
	cmp	#p96menu_glyph_width,d2
	bge.w	.next_row
	moveq	#0,d1
	move.b	(a2)+,d1
	beq.w	.next_col
	tst	g2inter_yellow_text_active
	bne.s	.yellow_pen
	cmp	#3,d1
	bhi.w	.next_col
	lea	p96menu_clut_pens_c87b78v,a0
	moveq	#0,d6
	move.b	0(a0,d1.w),d6
	move	d6,d1
	bra.s	.pen_ready
.yellow_pen
	cmp	#3,d1
	bls.s	.level_ok
	moveq	#3,d1
.level_ok
	subq	#1,d1
	add	d1,d1
	lea	g2inter_yellow_text_indices,a0
	move	0(a0,d1.w),d1
	tst	d1
	bmi.w	.next_col
.pen_ready
	move	d4,d0
	add	d2,d0
	tst	d0
	blt.w	.next_col
	cmp	#320,d0
	bge.w	.next_col
	move	d5,d7
	add	d3,d7
	tst	d7
	blt.w	.next_col
	cmp	#240,d7
	bge.w	.next_col

	move	d7,d6
	mulu	#320,d6
	move.l	p96static_direct_index_ptr,a0
	adda.l	d6,a0
	move.b	d1,0(a0,d0.w)

	move	p96inter_direct_scale_c87b78r,d6
	cmp	#2,d6
	beq.s	.stage2
	move.l	p96clut_stage_ptr,a1
	move	d7,d6
	add	p96inter_direct_yoff_c87b78t,d6
	mulu	p96target_width,d6
	adda.l	d6,a1
	add	p96inter_direct_xoff_c87b78u,d0
	move.b	d1,0(a1,d0.w)
	bra.s	.next_col
.stage2
	move	d7,d6
	add	d6,d6
	add	p96inter_direct_yoff_c87b78t,d6
	mulu	p96target_width,d6
	move.l	p96clut_stage_ptr,a1
	adda.l	d6,a1
	add	d0,d0
	add	p96inter_direct_xoff_c87b78u,d0
	move.l	a1,a3
	moveq	#0,d6
	move	p96target_width,d6
	adda.l	d6,a3
	move.b	d1,0(a1,d0.w)
	move.b	d1,1(a1,d0.w)
	move.b	d1,0(a3,d0.w)
	move.b	d1,1(a3,d0.w)
.next_col
	addq	#1,d2
	bra.w	.col
.next_row
	addq	#1,d3
	bra.w	.row
.publish
	jsr	g2p96_intermission_publish_index_band_standard_c87b78t
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts


; -----------------------------------------------------------------------------
; Preserve the static/title picture palette as the CLUT base. The historical
; font builder writes Bigfont colours into p96static_rgb565_lut[0..3]; keep
; those desired colours in p96menu_rgb565_lut instead, then restore the true
; picture colours before the full static CLUT contract is installed.
; -----------------------------------------------------------------------------
g2p96_static_build_font_rgb565_lut_c87b78v
	movem.l	d0-d7/a0-a3,-(a7)
	jsr	g2p96_static_build_font_rgb565_lut_legacy

	; Always derive the four desired font keys explicitly for the dynamic menu
	; pen allocator. Pen 0 remains transparent/black as in the original path.
	move.l	font,d0
	beq.s	.maybe_restore_base
	move.l	d0,a0
	add.l	(a0),a0
	lea	p96menu_rgb565_lut,a1
	moveq	#0,d7
.font_loop
	cmp	#4,d7
	bge.s	.maybe_restore_base
	move	(a0)+,d0
	tst	d7
	bne.s	.font_colour
	moveq	#0,d0
.font_colour
	moveq	#0,d2
	tst	aga
	beq.s	.font_ecs
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra.s	.font_store
.font_ecs
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.font_store
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
	addq	#1,d7
	bra.s	.font_loop

.maybe_restore_base
	; Gloom3/Zombie Massacre already keep their exact picture LUT untouched and
	; use separately selected intermission yellow indices.
	cmp	#2,g2_game_profile
	beq.w	.done
	cmp	#3,g2_game_profile
	beq.w	.done

	move.l	picpal,d0
	bne.s	.have_palette
	move.l	gloompal,d0
	bne.s	.have_palette
	move.l	planar_palette,d0
	beq.s	.black_base
.have_palette
	move.l	d0,a3
	lea	p96static_rgb565_lut,a1
	moveq	#0,d7
.base_loop
	cmp	#4,d7
	bge.s	.done
	move	d7,d6
	tst	aga
	beq.s	.base_ecs_addr
	lsl	#2,d6
	bra.s	.base_addr_ready
.base_ecs_addr
	add	d6,d6
.base_addr_ready
	move	0(a3,d6.w),d0
	tst	aga
	beq.s	.base_ecs_convert
	move	2(a3,d6.w),d2
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra.s	.base_store
.base_ecs_convert
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.base_store
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
	addq	#1,d7
	bra.s	.base_loop
.black_base
	lea	p96static_rgb565_lut,a1
	clr	(a1)
	clr	2(a1)
	clr	4(a1)
	clr	6(a1)
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts


