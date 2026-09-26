; =============================================================================
; c87b78y - exact c87b78u intermission yellow, c87b78w WIDE/menu fixes retained
;
; The collision-free dynamic pen allocator is correct for title/about/in-game
; menus, because those overlays sit on a live game/static background whose used
; indices must never be repaletted.  The intermission path is different: the
; confirmed c87b78u contract deliberately builds the complete static palette
; with the original Bigfont colours in entries 0..3 and emits glyph levels as
; indices 1..3.  c87b78v/w routed ordinary intermissions through the dynamic
; menu allocator and therefore changed the visible yellow shades.
;
; These two dispatchers restore c87b78u only while INTERMISSION owns the P96
; display.  Every other menu keeps c87b78w's isolated dynamic pens.
; =============================================================================
	even

; Build the original complete intermission LUT, including fixed Bigfont pens.
; Title/About/Ingame continue through the collision-free c87b78v builder.
g2p96_static_build_font_rgb565_lut_c87b78y
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.s	.isolated_menu
	jsr	g2p96_static_build_font_rgb565_lut_legacy
	rts
.isolated_menu
	jmp	g2p96_static_build_font_rgb565_lut_c87b78v


; Use the original fixed-pen overlay contract for intermission only.  This also
; clears any palette-dirty state in the same manner as the confirmed c87b78u
; build.  All normal menus retain collision-free dynamic allocation.
g2p96_clut_overlay_menu_lut_c87b78y
	cmp	#P96DSP_INTERMISSION,p96display_state
	bne.s	.isolated_menu
	jmp	g2p96_clut_overlay_menu_lut_c87b78j
.isolated_menu
	jmp	g2p96_clut_overlay_menu_lut_c87b78v

; =============================================================================
; c87b79c - P96 TWO PLAYER packed direct-index path for all six exact modes
;
; Source pages:
;   320x240 / 320x256 for standard and 5:4
;   428x240 for both WIDE targets
;
; Outputs:
;   320x240, 320x256, 428x240: packed 1:1 copy
;   640x480, 640x512: exact 2x2 expansion
;   854x480: exact WIDE expansion, 1 + 426*2 + 1 pixels, 2x vertically
;
; Return contract remains identical to the generic ONE PLAYER presenter:
;   d0 >= 0 : not handled; a6=coloffs and d0=hite
;   d0 < 0  : complete TWO PLAYER page built in the CLUT stage
; =============================================================================
	even
g2p96_twop_direct_all_try_c87b79c
	movem.l	d1-d3/d6-d7/a0-a2/a5-a6,-(a7)
	tst	twowins
	beq.w	.fallback
	tst.w	g2kalms_linear_active
	beq.w	.fallback
	moveq	#0,d1
	move	g2twop_half_height,d1
	add	d1,d1		; packed source rows: 240 or 256
	cmp	#240,d1
	beq.s	.rows_valid
	cmp	#256,d1
	bne.w	.fallback
.rows_valid
	cmp	#320,d5
	beq.w	.standard_source
	cmp	#428,d5
	beq.w	.wide_source
	bra.w	.fallback

.standard_source
	tst	g2p96_wide_mode
	bne.w	.fallback
	cmp	#320,d4
	beq.w	.copy_1x
	cmp	#640,d4
	beq.w	.copy_2x_standard
	bra.w	.fallback

.wide_source
	tst	g2p96_wide_mode
	beq.w	.fallback
	cmp	#240,d1		; WIDE is 120+120, never the 5:4 128+128 layout
	bne.w	.fallback
	cmp	#428,d4
	beq.w	.copy_1x
	cmp	#854,d4
	beq.w	.copy_2x_wide
	bra.w	.fallback

.copy_1x
	cmp	p96target_height,d1
	bne.w	.fallback
	move	d1,g2p96_present_rows
	moveq	#0,d2
	move	d5,d2
	mulu	d1,d2
	move.l	a4,a0
	move.l	a3,a1
	move.l	4.w,a6
	move.l	d2,d0
	jsr	-624(a6)	; CopyMem - complete packed split page
	moveq	#-1,d0
	bra.w	.done

.copy_2x_standard
	move	d1,d2
	add	d2,d2
	cmp	p96target_height,d2
	bne.w	.fallback
	move	d2,g2p96_present_rows
	move.l	a4,a0
	move.l	a3,a1
	lea	g2resolution_dupbyte_table,a5
	move	d1,d6
	subq	#1,d6
.row_2x_std
	move.l	a1,a2
	adda.w	#640,a2
	move	#319,d7
.pixel_2x_std
	moveq	#0,d0
	move.b	(a0)+,d0
	move.w	0(a5,d0.w*2),d2
	move.w	d2,(a1)+
	move.w	d2,(a2)+
	dbf	d7,.pixel_2x_std
	move.l	a2,a1
	dbf	d6,.row_2x_std
	moveq	#-1,d0
	bra.s	.done

.copy_2x_wide
	cmp	#480,p96target_height
	bne.w	.fallback
	move	#480,g2p96_present_rows
	move.l	a4,a0
	move.l	a3,a1
	lea	g2resolution_dupbyte_table,a5
	move	#239,d6
.row_2x_wide
	move.l	a1,a2
	adda.w	#854,a2
	; Preserve the two outermost source pixels once. Duplicate only columns
	; 1..426, matching the established ONE PLAYER 854-wide mapping exactly.
	move.b	(a0)+,(a1)+
	move.b	-1(a0),(a2)+
	move	#425,d7
.pixel_2x_wide
	moveq	#0,d0
	move.b	(a0)+,d0
	move.w	0(a5,d0.w*2),d2
	move.w	d2,(a1)+
	move.w	d2,(a2)+
	dbf	d7,.pixel_2x_wide
	move.b	(a0)+,(a1)+
	move.b	-1(a0),(a2)+
	move.l	a2,a1
	dbf	d6,.row_2x_wide
	moveq	#-1,d0
	bra.s	.done

.fallback
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d3/d6-d7/a0-a2/a5-a6
	tst.l	d0
	bmi.s	.return
	lea	coloffs,a6
	move	hite,d0
.return
	rts

; =============================================================================
; c87b79l - native P96 TWO PLAYER FLOOR/CEILING live menu refresh
;
; The former menu refresh intentionally returned immediately when twowins was
; active.  Consequently changed roof/floor flags were not rendered until the
; menu closed.  Build one complete split page here with the proven gameplay
; helpers, publish it through the mature MENU-owned RGB565 staging path, refresh
; the indexed clean backdrop, then let the caller redraw every menu row.
; =============================================================================
	even
g2p96_menu_twop_saved_player	dc.l	0
g2p96_menu_twop_saved_memat	dc.l	0
g2p96_menu_twop_saved_linear	dc.w	0
	even

g2p96_menu_redraw_twoplayer_source_once_c87b79l
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7			; zero = ONE PLAYER/not handled
	tst	twowins
	beq.w	.done
	cmp	#P96DSP_MENU,p96display_state
	bne.w	.handled
	tst	p96gameplay_persist_active
	beq.w	.handled
	move.l	chunky,d0
	beq.w	.handled

	move.l	player_,g2p96_menu_twop_saved_player
	move.l	memat,g2p96_menu_twop_saved_memat
	move	p96gameplay_linear_active,g2p96_menu_twop_saved_linear

	; Mirror g2twop_drawall_split up to, but not including, its normal present.
	jsr	g2twop_prepare_view_width
	jsr	g2kalms_prepare_twoplayer_frame_layout
	move.l	chunky,d0
	move.l	d0,g2twop_saved_chunky
	move	width,g2twop_saved_width
	move	hite,g2twop_saved_hite
	move	chunkymodw,g2twop_saved_chunkymodw
	move	minx,g2twop_saved_minx
	move	maxx,g2twop_saved_maxx
	move	miny,g2twop_saved_miny
	move	maxy,g2twop_saved_maxy
	move.l	offset,g2twop_saved_offset

	jsr	g2clearfullchunky
	jsr	g2twop_center_coloffs
	jsr	g2twop_set_half_view
	tst	g2teleport_blackout
	bne.w	.blackout_full

	; Player 1, top half.
	move.l	g2twop_saved_chunky,chunky
	move.l	player1,d0
	beq.w	.compose_done
	move.l	d0,player_
	move.l	memory,memat
	jsr	g2twop_quality_prepare_half
	jsr	calcscene
	jsr	drawscene
	tst	g2teleport_blackout
	beq.s	.p1_expand
	jsr	g2twop_quality_abort_half
	bra.w	.blackout_full
.p1_expand
	jsr	g2twop_quality_expand_half
	jsr	g2twop_draw_half_hud

	; Player 2, bottom half.
	move.l	player2,d0
	beq.s	.compose_done
	move.l	d0,player_
	move.l	g2twop_saved_chunky,d0
	moveq	#0,d1
	move	g2twop_half_height,d1
	mulu	g2twop_view_width,d1
	add.l	d1,d0
	move.l	d0,chunky
	move.l	memory,memat
	jsr	g2twop_quality_prepare_half
	jsr	calcscene
	jsr	drawscene
	tst	g2teleport_blackout
	beq.s	.p2_expand
	jsr	g2twop_quality_abort_half
	bra.s	.blackout_full
.p2_expand
	jsr	g2twop_quality_expand_half
	jsr	g2twop_draw_half_hud

.compose_done
	clr.w	g2twop_quality_mode
	clr	g2twop_crop_mode
	jsr	g2twop_restore_coloffs
	jsr	g2twop_set_full_c2p_view
	bra.s	.publish

.blackout_full
	move.l	g2twop_saved_chunky,chunky
	clr.w	g2twop_quality_mode
	clr	g2twop_crop_mode
	jsr	g2twop_restore_coloffs
	jsr	g2twop_set_full_c2p_view
	jsr	g2clearfullchunky

.publish
	; MENU ownership intentionally uses the established RGB565 compositor so its
	; temporary font pens remain active.  Mark the packed split source linear only
	; for this conversion; this also selects true 428/854 WIDE instead of scaling
	; a 320-column subset.  The CLUT clean stage is rebuilt immediately afterwards.
	move	#-1,p96gameplay_linear_active
	jsr	g2p96_gameplay_persistent_update
	jsr	g2p96_menu_refresh_index_backdrop_c87b78p
	jsr	g2twop_restore_after_c2p
	move	g2p96_menu_twop_saved_linear,p96gameplay_linear_active
	move.l	g2p96_menu_twop_saved_player,player_
	move.l	g2p96_menu_twop_saved_memat,memat
.handled
	moveq	#-1,d7			; TWO PLAYER was consumed by this helper
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; =============================================================================
; c87b79r P96 static direct-source helpers (appended to protect mature ranges)
; =============================================================================

; =============================================================================
; c87b79t - compact TWO PLAYER WIDE linear/projection ownership
;
; Why c87b79s did not alter the visible result:
;   The shared WIDE helpers first test g2p96_wide_mode and then
;   p96gameplay_linear_active. TWO PLAYER uses the equally row-major
;   g2kalms_linear_active owner instead, so compact halves still entered the
;   legacy 320-based scaler before g2resolution_active could have any effect.
;
; Contract for one compact half:
;   - keep g2kalms_linear_active as the actual coloffs/source owner
;   - publish p96gameplay_linear_active only as the common WIDE geometry gate
;   - publish the native 428x120 saved geometry through g2resolution_saved_*
;   - restore the exact previous P96-linear flag before HUD/presenter code
;
; The extra owner contract is deliberately limited to active P96 WIDE +
; persistent gameplay. Standard, 5:4 and native AGA/ECS keep the c87b79r
; behaviour; TWO PLAYER 1x1 returns before this helper is called.
; =============================================================================
	even
g2twop_quality_saved_p96_linear_c87b79t	dc.w	0
g2twop_quality_forced_p96_linear_c87b79t	dc.w	0
	even

g2twop_quality_begin_wide_linear_c87b79t
	; in: d0 = RESOLUTION selector, d1 = native split height
	; d0 and d1 must survive because the caller immediately uses both.
	move.l	d1,-(a7)
	move.w	d0,g2twop_quality_mode
	clr.w	g2resolution_active
	clr.w	g2twop_quality_forced_p96_linear_c87b79t
	move.w	p96gameplay_linear_active,d1
	move.w	d1,g2twop_quality_saved_p96_linear_c87b79t

	; Publish the extra owner contract only for the affected P96 WIDE halves.
	; All standard/5:4/native compact paths remain byte-for-byte equivalent to r.
	cmp.w	#2,g2display_mode
	bne.w	.no_force
	tst.w	p96gameplay_persist_active
	beq.w	.no_force
	tst.w	g2p96_wide_mode
	beq.w	.no_force
	tst.w	g2kalms_linear_active
	beq.w	.no_force
	move.w	d0,g2resolution_active
	move.w	width,g2resolution_saved_width
	move.w	hite,g2resolution_saved_hite
	move.w	chunkymodw,g2resolution_saved_chunkymodw
	move.w	minx,g2resolution_saved_minx
	move.w	maxx,g2resolution_saved_maxx
	move.w	miny,g2resolution_saved_miny
	move.w	maxy,g2resolution_saved_maxy
	move.l	offset,g2resolution_saved_offset
	move.w	g2render_width,g2resolution_saved_render_width
	move.w	g2render_center_x,g2resolution_saved_render_center
	move.w	g2render_last_x,g2resolution_saved_render_last
	move.w	g2render_stride,g2resolution_saved_render_stride
	move.w	#-1,p96gameplay_linear_active
	move.w	#-1,g2twop_quality_forced_p96_linear_c87b79t
.no_force
	move.l	(a7)+,d1
	rts

	even
g2twop_quality_end_wide_linear_c87b79t
	; Every expand and abort path converges here before HUD/presentation.
	move.l	d0,-(a7)
	tst.w	g2twop_quality_forced_p96_linear_c87b79t
	beq.s	.no_restore
	move.w	g2twop_quality_saved_p96_linear_c87b79t,d0
	move.w	d0,p96gameplay_linear_active
.no_restore
	clr.w	g2twop_quality_forced_p96_linear_c87b79t
	clr.w	g2twop_quality_mode
	clr.w	g2resolution_active
	move.l	(a7)+,d0
	rts

; =============================================================================
; c87b79u - P96 TITLE/ABOUT direct-source phase 2
;
; All new assembled code is appended. Established code changes only absolute
; JSR targets of identical size, protecting the mature GenAm branch layout.
; =============================================================================
	even

; Expanded static-source owner selector. The c87b79r selector remains in place
; as historical code; active direct decoders call this phase-2 contract.
g2p96_static_select_planar_write_c87b79u
	move	#-1,p96static_direct_planar_write
	cmp	#2,g2display_mode
	bne.s	.done
	clr	p96static_direct_planar_write	;c87b79x: every P96 static owner is direct-only
.done
	rts

; Direct-only title-brush dispatcher. Legacy AGA/ECS/non-CLUT states jump to
; the untouched c87b79r dual builder. P96 TITLE derives the overlay Y from the
; caller's compatibility pointer but writes only the authoritative index page.
g2p96_static_decode_gloombrush_direct_dispatch_c87b79u
	jsr	g2p96_static_select_planar_write_c87b79u
	tst	p96static_direct_planar_write
	bne.w	.legacy
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96static_direct_valid
	beq.w	.direct_fallback_saved
	move.l	a1,d1
	move.l	showbitmap,d0
	beq.s	.check_draw
	sub.l	d0,d1
	bmi.s	.check_draw
	move.l	bpmod,d2
	cmp.l	d2,d1
	blo.s	.have_offset
.check_draw
	move.l	a1,d1
	move.l	drawbitmap,d0
	beq.w	.direct_fallback_saved
	sub.l	d0,d1
	bmi.w	.direct_fallback_saved
	move.l	bpmod,d2
	cmp.l	d2,d1
	bhs.w	.direct_fallback_saved
.have_offset
	moveq	#0,d2
	move	linemodw,d2
	beq.w	.direct_fallback_saved
	divu	d2,d1
	and.l	#$0000ffff,d1
	move	d1,p96static_direct_dest_y
	movem.l	(a7),d0-d7/a0-a6
	move	p96static_direct_dest_y,d6
	jsr	g2p96_static_decode_iff_dual_common
	tst	d0
	beq.w	.direct_fallback_live
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.direct_fallback_saved
	movem.l	(a7),d0-d7/a0-a6
.direct_fallback_live
	; c87b79x: P96 has no planar rollback target. Preserve the direct base and
	; return without touching a null destination.
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.legacy
	jmp	g2p96_static_decode_gloombrush_best

; =============================================================================
; c87b79x - final P96 planar-page/materializer removal helpers
; =============================================================================
	even

; P96 showpic clear path: decode exclusively into the direct index page.
g2p96_static_showpic_direct_only_c87b79x
	movem.l	a0-a1,-(a7)
	suba.l	a1,a1
	move.l	(a7),a0
	jsr	g2p96_static_decode_iff_dual_clear_if_active
	tst	d0
	bne.s	.decoded
	jsr	g2p96_static_force_black_direct_c87b79x
.decoded
	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq.s	.nopal
	jsr	g2pokepal_picture
.nopal
	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active
	jmp	vwait

; P96 showpic_noclear path: overlay/replace only the direct index page.
g2p96_static_showpic_noclear_direct_only_c87b79x
	movem.l	a0-a1,-(a7)
	tst.l	a0
	beq.s	.no_picture
	suba.l	a1,a1
	move.l	(a7),a0
	jsr	g2p96_static_decode_iff_dual_noclear_if_active
	tst	d0
	bne.s	.no_picture
	jsr	g2p96_static_force_black_direct_c87b79x
.no_picture
	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq.s	.nopal
	jsr	g2pokepal_picture
.nopal
	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active
	jmp	vwait

; Establish a valid all-black logical source without any planar allocation.
g2p96_static_force_black_direct_c87b79x
	movem.l	d0-d2/a0,-(a7)
	jsr	g2p96_static_direct_ensure_buffer
	tst	d0
	beq.s	.done
	move.l	p96static_direct_index_ptr,a0
	moveq	#0,d0
	move.w	#239,d1
.clear_row
	moveq	#79,d2
.clear_long
	move.l	d0,(a0)+
	dbf	d2,.clear_long
	dbf	d1,.clear_row
	move	#-1,p96static_direct_valid
	clr	p96static_direct_clut_state
.done
	movem.l	(a7)+,d0-d2/a0
	rts

; Decode a validated title brush at explicit logical Y. Preserve the current
; base-valid flag on an unexpected decode failure; no planar rollback exists.
g2p96_static_decode_gloombrush_direct_y_c87b79x
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96static_direct_valid
	beq.s	.done
	move	#-1,d7		; remember valid base
	jsr	g2p96_static_select_planar_write_c87b79u
	suba.l	a1,a1
	jsr	g2p96_static_decode_iff_dual_common
	tst	d0
	bne.s	.success
	move	d7,p96static_direct_valid
	bra.s	.done
.success
	move	#-1,p96static_direct_valid
	clr	p96static_direct_clut_state
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts


; =============================================================================
; c87b80f / RC3 - robust P96 mode-list selection
;
; pVision with Picasso96API.library 2.455 exposes all valid modes through
; p96AllocModeListTagList(), while p96BestModeIDTagList() returns INVALID_ID
; even for exact geometries.  The released chooser therefore obtains each
; candidate directly from the authoritative P96 mode list, then validates the
; DisplayID against the unchanged direct CLUT8 renderer contract.
;
; The compact geometry chooser remains unchanged.  Selecting a geometry now
; uses its already validated first ModeID directly.  P96MODEID remains available
; when a particular card/timing must be forced on a multi-board setup.
; =============================================================================

G2P96_RC3_MODE_WIDTH       equ 62
G2P96_RC3_MODE_HEIGHT      equ 64
G2P96_RC3_MODE_DEPTH       equ 66
G2P96_RC3_MODE_DISPLAYID   equ 68

        even
g2p96_req_modelist_tags_c87b80f
        dc.l    TAG_DONE,0

; Return the first exact, genuine 8-bit CLUT ModeID for p96target_width/height.
; Output d0.l = validated ModeID, or zero.  The allocated P96 list is always
; released before returning.
g2p96_req_best_current_c87b80f
        movem.l d1-d7/a0-a6,-(a7)
        moveq   #0,d7
        move.l  p96base,d0
        beq.w   .done
        move.l  d0,a6
        lea     g2p96_req_modelist_tags_c87b80f,a0
        jsr     -72(a6)                 ; p96AllocModeListTagList
        move.l  d0,a4
        beq.w   .done

        move.l  (a4),a3                 ; List.lh_Head
.loop
        move.l  a3,d0
        beq.s   .free
        move.l  (a3),d0                 ; tail sentinel: ln_Succ == 0
        beq.s   .free

        moveq   #0,d0
        move    G2P96_RC3_MODE_WIDTH(a3),d0
        cmp     p96target_width,d0
        bne.s   .next
        moveq   #0,d0
        move    G2P96_RC3_MODE_HEIGHT(a3),d0
        cmp     p96target_height,d0
        bne.s   .next
        moveq   #0,d0
        move    G2P96_RC3_MODE_DEPTH(a3),d0
        cmp     #8,d0
        bne.s   .next

        move.l  G2P96_RC3_MODE_DISPLAYID(a3),d0
        jsr     g2p96_req_validate_current_c87b78j
        tst.l   d0
        beq.s   .next
        move.l  d0,d7
        bra.s   .free

.next
        move.l  (a3),a3
        bra.s   .loop

.free
        move.l  a4,a0
        move.l  p96base,a6
        jsr     -78(a6)                 ; p96FreeModeList
.done
        move.l  d7,d0
        movem.l (a7)+,d1-d7/a0-a6
        rts

; Stage 1 already stored one exact validated ModeID per displayed geometry.
; Return that ID directly instead of invoking p96RequestModeIDTagList(), whose
; empty result on pVision was the reason no usable resolution could be started.
g2p96_req_select_candidate_c87b80f
        movem.l d1/a0,-(a7)
        moveq   #0,d0
        move    g2p96_req_selected_index,d0
        bmi.s   .invalid
        cmp     #5,d0
        bhi.s   .invalid
        lsl     #2,d0
        lea     g2p96_req_candidate_ids,a0
        move.l  0(a0,d0.w),d0
        bra.s   .done
.invalid
        moveq   #0,d0
.done
        movem.l (a7)+,d1/a0
        rts

