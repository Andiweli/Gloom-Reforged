; =============================================================================
; GLOOMBENCH2 PATCH 8 - 040/060 FLAT BAYER LOOP SPLIT
; 020/030 retain the confirmed one-pixel V2 span loop. 040/060 use the
; four-pixel span loop for a focused fast-CPU A/B test. All geometry, Bayer
; decisions, fallback rows and benchmark automation remain unchanged.
;
; Base implementation: GLOOMBENCH2 PATCH 2 wall-derived spans.
;
; The wall renderer already provides one vertical interval per screen column in
; vertdraws.  This pass transforms changes between adjacent intervals into a
; compact per-scanline transition list.  The normal Bayer flat loop can then
; draw a proven single free span without reading/testing the destination byte
; for every pixel.  Complex rows and transparent wall strips use the unchanged
; reference loop.
;
; No sprite/Z-buffer format is changed.  drawshapes continues to clip against
; the existing vd_z values after walls and flats have been rendered.
; =============================================================================

g2p2_build_wall_spans
	movem.l	d0-d7/a0-a6,-(a7)
	clr	g2p2_span_ready

	; Only the row-major chunky owners can use direct horizontal spans.
	tst.w	g2kalms_linear_active
	bne.s	g2p2_bws_linear
	tst.w	p96gameplay_linear_active
	beq.w	g2p2_bws_done
g2p2_bws_linear
	move	hite,d7
	ble.w	g2p2_bws_done
	cmp	#256,d7
	bhi.w	g2p2_bws_done
	move	width,d6
	ble.w	g2p2_bws_done
	cmp	#512,d6
	bhi.w	g2p2_bws_done

	; Transparent wall strips intentionally contain holes that the old chunky
	; destination test fills with flats.  Keep those frames on the reference
	; loop rather than treating the full geometric wall interval as opaque.
	move.l	shapelist,a0
g2p2_bws_shape_scan
	tst.l	a0
	beq.s	g2p2_bws_shapes_safe
	tst.l	sh_shape(a0)
	beq.w	g2p2_bws_done
	move.l	sh_next(a0),a0
	bra.s	g2p2_bws_shape_scan
g2p2_bws_shapes_safe

	move	d7,g2p2_span_hite
	move	d6,g2p2_span_width

	; Clear only the active rows.  x1/x2 need no clear because count owns them.
	lea	g2p2_span_state,a0
	lea	g2p2_span_count,a1
	move	d7,d5
	subq	#1,d5
g2p2_bws_clear
	clr.b	(a0)+
	clr.b	(a1)+
	dbf	d5,g2p2_bws_clear

	move.l	vertdraws,a6
	tst.l	a6
	beq.w	g2p2_bws_done

	; Column zero defines each row's initial blocked/free state.
	jsr	g2p2_get_wall_interval
	move	d7,d3		; previous interval valid
	move	d0,d4		; previous top
	move	d1,d5		; previous bottom (exclusive)
	tst	d3
	beq.s	g2p2_bws_first_done
	jsr	g2p2_mark_state_range
g2p2_bws_first_done

	moveq	#1,d2		; x coordinate of current column boundary
	subq	#1,d6		; remaining columns after column zero
	beq.s	g2p2_bws_finish

g2p2_bws_column_loop
	lea	vd_size(a6),a6
	jsr	g2p2_get_wall_interval	; d0=top d1=bottom d7=valid

	tst	d3
	bne.s	g2p2_bws_prev_valid
	; Previous column free: entering a wall toggles the current interval.
	tst	d7
	beq.s	g2p2_bws_update_prev
	jsr	g2p2_add_transition_range
	bra.s	g2p2_bws_update_prev

g2p2_bws_prev_valid
	tst	d7
	bne.s	g2p2_bws_both_valid
	; Leaving a wall toggles the previous interval.
	move	d0,-(a7)
	move	d1,-(a7)
	move	d4,d0
	move	d5,d1
	jsr	g2p2_add_transition_range
	move	(a7)+,d1
	move	(a7)+,d0
	bra.s	g2p2_bws_update_prev

g2p2_bws_both_valid
	; Two solid intervals differ only in their symmetric difference.  The
	; helper emits at most two vertical transition ranges for this X boundary.
	jsr	g2p2_add_interval_difference

g2p2_bws_update_prev
	move	d7,d3
	tst	d7
	beq.s	g2p2_bws_next_column
	move	d0,d4
	move	d1,d5
g2p2_bws_next_column
	addq	#1,d2
	subq	#1,d6
	bne.w	g2p2_bws_column_loop

g2p2_bws_finish
	move	#-1,g2p2_span_ready
g2p2_bws_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Read and clip one vertdraws wall interval.
; In: a6=vd. Out: d0=top, d1=bottom exclusive, d7=-1 valid / 0 empty.
; d2 is preserved because the caller uses it as the current X boundary.
g2p2_get_wall_interval
	move.l	d2,-(a7)
	moveq	#0,d7
	moveq	#0,d0
	moveq	#0,d1
	tst.l	vd_data(a6)
	beq.s	g2p2_gwi_done
	move	vd_y(a6),d0
	add	midy,d0
	move	vd_h(a6),d1
	ble.s	g2p2_gwi_empty
	add	d0,d1
	ble.s	g2p2_gwi_empty
	tst	d0
	bpl.s	g2p2_gwi_top_ok
	moveq	#0,d0
g2p2_gwi_top_ok
	move	hite,d2
	cmp	d2,d1
	ble.s	g2p2_gwi_bottom_ok
	move	d2,d1
g2p2_gwi_bottom_ok
	cmp	d0,d1
	ble.s	g2p2_gwi_empty
	moveq	#-1,d7
	bra.s	g2p2_gwi_done
g2p2_gwi_empty
	moveq	#0,d0
	moveq	#0,d1
g2p2_gwi_done
	move.l	(a7)+,d2
	rts

; Mark rows blocked at X=0. In: d0=start, d1=end exclusive.
g2p2_mark_state_range
	movem.l	d0-d2/a0,-(a7)
	cmp	d0,d1
	ble.s	g2p2_msr_done
	lea	g2p2_span_state,a0
	adda.w	d0,a0
	sub	d0,d1
	subq	#1,d1
g2p2_msr_loop
	move.b	#1,(a0)+
	dbf	d1,g2p2_msr_loop
g2p2_msr_done
	movem.l	(a7)+,d0-d2/a0
	rts

; Add transition X=d2 to every row [d0,d1). Counts are capped at three:
; 0/1/2 are usable classifications, 3 means complex/reference fallback.
g2p2_add_transition_range
	movem.l	d0-d3/a0-a2,-(a7)
	cmp	d0,d1
	ble.w	g2p2_atr_done
	move	d0,d3
	lea	g2p2_span_count,a0
	adda.w	d3,a0
	add	d3,d3
	lea	g2p2_span_x1,a1
	adda.w	d3,a1
	lea	g2p2_span_x2,a2
	adda.w	d3,a2
	sub	d0,d1
	subq	#1,d1
g2p2_atr_loop
	moveq	#0,d0
	move.b	(a0),d0
	beq.s	g2p2_atr_first
	cmp	#1,d0
	beq.s	g2p2_atr_second
	move.b	#3,(a0)
	bra.s	g2p2_atr_next
g2p2_atr_first
	move	d2,(a1)
	move.b	#1,(a0)
	bra.s	g2p2_atr_next
g2p2_atr_second
	move	d2,(a2)
	move.b	#2,(a0)
g2p2_atr_next
	addq.l	#1,a0
	addq.l	#2,a1
	addq.l	#2,a2
	dbf	d1,g2p2_atr_loop
g2p2_atr_done
	movem.l	(a7)+,d0-d3/a0-a2
	rts

; Emit the symmetric difference of two valid vertical intervals.
; Current=[d0,d1), previous=[d4,d5), transition X=d2.
g2p2_add_interval_difference
	movem.l	d0-d7/a0-a2,-(a7)
	move	d0,d6		; current top
	move	d1,d7		; current bottom
	cmp	d6,d5		; previous bottom <= current top
	ble.s	g2p2_aid_disjoint
	cmp	d4,d7		; current bottom <= previous top
	ble.s	g2p2_aid_disjoint

	; Overlap: top edges and bottom edges each form one difference range.
	cmp	d6,d4
	beq.s	g2p2_aid_top_done
	blt.s	g2p2_aid_prev_top_first
	move	d6,d0
	move	d4,d1
	bra.s	g2p2_aid_add_top
g2p2_aid_prev_top_first
	move	d4,d0
	move	d6,d1
g2p2_aid_add_top
	jsr	g2p2_add_transition_range
g2p2_aid_top_done
	cmp	d7,d5
	beq.s	g2p2_aid_done
	blt.s	g2p2_aid_prev_bottom_first
	move	d7,d0
	move	d5,d1
	bra.s	g2p2_aid_add_bottom
g2p2_aid_prev_bottom_first
	move	d5,d0
	move	d7,d1
g2p2_aid_add_bottom
	jsr	g2p2_add_transition_range
	bra.s	g2p2_aid_done

g2p2_aid_disjoint
	move	d4,d0
	move	d5,d1
	jsr	g2p2_add_transition_range
	move	d6,d0
	move	d7,d1
	jsr	g2p2_add_transition_range
g2p2_aid_done
	movem.l	(a7)+,d0-d7/a0-a2
	rts

; Try the single-span Bayer path for the current scanline.
; Entry is the exact state at .g2c87b69_flat4_bayer_setup after a3=a2:
; a0 texture, a1 next palette, a3 destination, a5 base palette, a6 Bayer row;
; d0/d1 coordinates, d4/d6 steps, d7=127.
; Return d5=-1 if handled, d5=0 for the untouched reference fallback.
g2p2_try_span_bayer
	moveq	#0,d5
	tst	g2p2_span_ready
	beq.w	g2p2_tsb_fallback

	move	g2_bayer_ybase,d5
	add	midy,d5
	bmi.w	g2p2_tsb_fallback
	cmp	g2p2_span_hite,d5
	bge.w	g2p2_tsb_fallback

	lea	g2p2_span_state,a4
	moveq	#0,d2
	move.b	0(a4,d5),d2
	lea	g2p2_span_count,a4
	moveq	#0,d3
	move.b	0(a4,d5),d3

	tst	d3
	bne.s	g2p2_tsb_has_transition
	; No transition: complete free row or complete blocked row.
	tst	d2
	bne.w	g2p2_tsb_handled_empty
	clr	g2p2_work_start
	move	g2p2_span_width,g2p2_work_end
	bra.w	g2p2_tsb_have_span

g2p2_tsb_has_transition
	cmp	#1,d3
	bne.s	g2p2_tsb_two_or_complex
	lea	g2p2_span_x1,a4
	move	0(a4,d5*2),d3
	tst	d2
	bne.s	g2p2_tsb_one_blocked_start
	clr	g2p2_work_start
	move	d3,g2p2_work_end
	bra.s	g2p2_tsb_have_span
g2p2_tsb_one_blocked_start
	move	d3,g2p2_work_start
	move	g2p2_span_width,g2p2_work_end
	bra.s	g2p2_tsb_have_span

g2p2_tsb_two_or_complex
	cmp	#2,d3
	bne.w	g2p2_tsb_fallback
	; Starting free with two transitions means two distinct free spans.
	tst	d2
	beq.w	g2p2_tsb_fallback
	lea	g2p2_span_x1,a4
	move	0(a4,d5*2),g2p2_work_start
	lea	g2p2_span_x2,a4
	move	0(a4,d5*2),g2p2_work_end

g2p2_tsb_have_span
	move	g2p2_work_end,d5
	sub	g2p2_work_start,d5
	ble.s	g2p2_tsb_handled_empty

	; Advance across the blocked left prefix without touching destination RAM.
	move	g2p2_work_start,d5
	beq.s	g2p2_tsb_draw_setup
	subq	#1,d5
	moveq	#0,d2
g2p2_tsb_skip_prefix
	add.l	d4,d0
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	addq.l	#1,a3
	lea	1(a6),a6
	dbf	d5,g2p2_tsb_skip_prefix

g2p2_tsb_draw_setup
	; Patch 8: only 040/060 enter the split four-pixel span loops.
	; 020/030 continue directly through the exact confirmed V2 loop below.
	cmp.w	#g2kalms_cpu_040,g2kalms_cpu_mode
	beq.w	g2p6_tsb_draw_setup_040
	move	g2p2_work_end,d5
	sub	g2p2_work_start,d5
	subq	#1,d5

g2p2_tsb_draw_loop
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	tst	g2_bayer_thresh
	beq.s	g2p2_tsb_base
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	g2p2_tsb_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	g2p2_tsb_advance
g2p2_tsb_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
g2p2_tsb_advance
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,g2p2_tsb_draw_loop

g2p2_tsb_handled_empty
	moveq	#-1,d5
	rts

g2p2_tsb_fallback
	; Restore the scratch-register contract expected by the original setup.
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d5
	rts

; 68040/68060-only four-pixel fast span.
g2p6_tsb_draw_setup_040
	; Patch 8 040/060: select once per span between an undithered
	; base-palette FLAT4 loop and the ordered-Bayer FLAT4 loop. This removes
	; the threshold test from every pixel while preserving exact coordinates,
	; palette selection and the 0..3-pixel remainder.
	move	g2p2_work_end,d5
	sub	g2p2_work_start,d5
	move	d5,d3
	and	#3,d3
	move	d3,g2p6_span_tail_count
	; One threshold decision per visible span, never once per pixel.
	tst	g2_bayer_thresh
	beq.w	g2p8_tsb_nobayer_setup
	lsr	#2,d5
	beq.w	g2p6_tsb_tail
	subq	#1,d5

g2p6_tsb_draw4_loop
	; Pixel A
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	g2p6_tsb_base_a
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	g2p6_tsb_advance_a
g2p6_tsb_base_a
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
g2p6_tsb_advance_a
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6

	; Pixel B
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	g2p6_tsb_base_b
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	g2p6_tsb_advance_b
g2p6_tsb_base_b
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
g2p6_tsb_advance_b
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6

	; Pixel C
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	g2p6_tsb_base_c
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	g2p6_tsb_advance_c
g2p6_tsb_base_c
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
g2p6_tsb_advance_c
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6

	; Pixel D
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	g2p6_tsb_base_d
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	g2p6_tsb_advance_d
g2p6_tsb_base_d
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
g2p6_tsb_advance_d
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,g2p6_tsb_draw4_loop

g2p6_tsb_tail
	move	g2p6_span_tail_count,d5
	beq.w	g2p2_tsb_handled_empty
	subq	#1,d5
g2p6_tsb_tail_loop
	and	d7,d0
	and	d7,d1
	move	d0,d2
	lsl	#7,d2
	add	d2,d1
	add.l	d4,d0
	moveq	#0,d3
	move.b	(a6),d3
	cmp	g2_bayer_thresh,d3
	bcc.s	g2p6_tsb_tail_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a1,d3),(a3)+
	bra.s	g2p6_tsb_tail_advance
g2p6_tsb_tail_base
	moveq	#0,d3
	move.b	0(a0,d1),d3
	move.b	0(a5,d3),(a3)+
g2p6_tsb_tail_advance
	addx	d2,d0
	add.l	d6,d1
	addx	d2,d1
	lea	1(a6),a6
	dbf	d5,g2p6_tsb_tail_loop
	bra.w	g2p2_tsb_handled_empty

; Patch 8 040/060 no-Bayer fast path. The threshold is known to be zero,
; so no Bayer-row reads, threshold compares or Bayer pointer increments remain.
g2p8_tsb_nobayer_setup
	lsr	#2,d5
	beq.w	g2p8_tsb_nobayer_tail
	subq	#1,d5

g2p8_tsb_nobayer_draw4_loop
	; Pixel A
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

	; Pixel B
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

	; Pixel C
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

	; Pixel D
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
	dbf	d5,g2p8_tsb_nobayer_draw4_loop

g2p8_tsb_nobayer_tail
	move	g2p6_span_tail_count,d5
	beq.w	g2p2_tsb_handled_empty
	subq	#1,d5
g2p8_tsb_nobayer_tail_loop
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
	dbf	d5,g2p8_tsb_nobayer_tail_loop
	bra.w	g2p2_tsb_handled_empty

	even
g2p2_span_ready	dc	0
g2p2_span_hite	dc	0
g2p2_span_width	dc	0
g2p2_work_start	dc	0
g2p2_work_end	dc	0
g2p6_span_tail_count	dc	0
	even
g2p2_span_state	ds.b	256
g2p2_span_count	ds.b	256
	even
g2p2_span_x1	ds.w	256
g2p2_span_x2	ds.w	256
	even



; c87b80e: Dormant benchmark loading/audio gates removed.

; =============================================================================
; PATCH 10: 68040/68060 four-row ordered-Bayer wall loop
;
; Inputs are the exact drawsolidstrip dither state:
;   d0.l = chunky row stride
;   d2.l = wall texture Y accumulator
;   d3.l = wall texture Y step
;   d4.w = visible wall height (1..screen height)
;   d7.w = Bayer threshold
;   a1   = destination at first visible wall pixel
;   a2   = Bayer matrix pointer at current X/Y phase
;   a3   = source texture column
;   a4   = base palette LUT
;   a5   = next-darker palette LUT
;
; Output:
;   a1/d2 advanced exactly like the original one-pixel loop.
;
; The Bayer sequence is unchanged. Four vertical pixels use offsets
; 0,4,8,12 from the current column phase; the matrix pointer advances by
; 16 bytes once per group. A 0..3 row tail uses the original single-pixel
; order. d1/d7/a2 are restored by the caller.
; =============================================================================
g2p10_wall_dither4_040060
	; Carry fix: prepare both DBF counters before establishing X.
	move	d4,d1
	and	#3,d1			; tail pixel count 0..3
	lsr	#2,d4			; complete groups of four
	subq	#1,d4			; group DBF count, -1 means none
	subq	#1,d1			; tail DBF count, -1 means none

	; Final X-changing sequence before the first texture ADDX.
	sub	d3,d2
	add.l	d3,d2

	; TST/BMI and DBF preserve X.
	tst	d4
	bmi.w	.g2p10_wall_tail

.g2p10_wall_group
	; Row A, Bayer offset +0
	moveq	#0,d6
	move.b	0(a2),d6
	cmp	d7,d6
	bcc.s	.g2p10_wall_base_a
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2p10_wall_advance_a
.g2p10_wall_base_a
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2p10_wall_advance_a
	addx.l	d3,d2
	add.l	d0,a1

	; Row B, Bayer offset +4
	moveq	#0,d6
	move.b	4(a2),d6
	cmp	d7,d6
	bcc.s	.g2p10_wall_base_b
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2p10_wall_advance_b
.g2p10_wall_base_b
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2p10_wall_advance_b
	addx.l	d3,d2
	add.l	d0,a1

	; Row C, Bayer offset +8
	moveq	#0,d6
	move.b	8(a2),d6
	cmp	d7,d6
	bcc.s	.g2p10_wall_base_c
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2p10_wall_advance_c
.g2p10_wall_base_c
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2p10_wall_advance_c
	addx.l	d3,d2
	add.l	d0,a1

	; Row D, Bayer offset +12
	moveq	#0,d6
	move.b	12(a2),d6
	cmp	d7,d6
	bcc.s	.g2p10_wall_base_d
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2p10_wall_advance_d
.g2p10_wall_base_d
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2p10_wall_advance_d
	addx.l	d3,d2
	add.l	d0,a1

	lea	16(a2),a2
	dbf	d4,.g2p10_wall_group

.g2p10_wall_tail
	tst	d1
	bmi.s	.g2p10_wall_done
.g2p10_wall_tail_loop
	moveq	#0,d6
	move.b	(a2),d6
	cmp	d7,d6
	bcc.s	.g2p10_wall_tail_base
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2p10_wall_tail_advance
.g2p10_wall_tail_base
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2p10_wall_tail_advance
	addx.l	d3,d2
	add.l	d0,a1
	lea	4(a2),a2
	dbf	d1,.g2p10_wall_tail_loop
.g2p10_wall_done
	rts

; =============================================================================
; v2.0 Fix 1: missing EHB assets - blinking message and immediate ESC abort
;
; In:
;   a0 = g2ecs2_assetfailmenu
;
; Controls:
;   ESC         = close warning and immediately run the normal exit cleanup
;   Fire/Return = close warning and continue with the existing fallback
;
; The early asset notice occurs before normal title input is guaranteed active.
; Explicitly enable input here. The selected one-row menu then uses the same
; 13-VBlank optoff/opton blinking cadence as the original selmenu path.
; =============================================================================
g2ecs2_asset_notice_wait_esc
	jsr	qmenu
	jsr	inputon

.g2ecs2_ehb_blink_restart
	jsr	optoff

.g2ecs2_ehb_off_wait
	jsr	vwait
	qkey	$45
	bne.w	.g2ecs2_ehb_abort
	jsr	readmenujoy
	btst	#4,d0
	bne.w	.g2ecs2_ehb_continue
	subq	#1,flashdelay
	bgt.s	.g2ecs2_ehb_off_wait

	jsr	opton

.g2ecs2_ehb_on_wait
	jsr	vwait
	qkey	$45
	bne.w	.g2ecs2_ehb_abort
	jsr	readmenujoy
	btst	#4,d0
	bne.s	.g2ecs2_ehb_continue
	subq	#1,flashdelay
	bgt.s	.g2ecs2_ehb_on_wait
	bra.w	.g2ecs2_ehb_blink_restart

.g2ecs2_ehb_continue
	; Ensure the row is visible while the activation key is released.
	jsr	opton
.g2ecs2_ehb_continue_release
	jsr	vwait
	jsr	readmenujoy
	btst	#4,d0
	bne.s	.g2ecs2_ehb_continue_release
	jsr	finitqmenu
	rts

.g2ecs2_ehb_abort
	; No key-release delay: ESC aborts on the first sampled VBlank.
	jsr	finitqmenu

	; Drop:
	;   1) helper -> g2ecs2_asset_notice return
	;   2) g2ecs2_asset_notice -> startup return
	; Then enter the existing full game cleanup.
	addq.l	#8,a7
	jmp	exittoos

; =============================================================================
; c87b71a - top HUD life heart
;
; The original Gloom source draws lives with shape #43 from misc/smallfont.bin.
; That file uses the older Black Magic planar/blitter shape layout, while this
; Reforged HUD is a chunky renderer using Gloom Deluxe smallfont2.bin. Feeding
; the old shape table to g2hud_draw_shape_top would therefore be unsafe.
;
; This routine reproduces the original compact 7x7 heart silhouette directly
; in chunky space. Its three reds are resolved through planar_remap, keeping
; ECS/EHB, AGA and P96 palette-correct. In: d0=x, d1=y.
; =============================================================================
g2c87b71a_draw_heart_top
	movem.l	d0-d7/a0-a3,-(a7)
	move	d0,d6
	move	d1,d7
	tst	d6
	bmi.w	.g2c87b71a_heart_done
	tst	d7
	bmi.w	.g2c87b71a_heart_done
	move	d6,d0
	addq	#7,d0
	cmp	g2render_width,d0
	bgt.w	.g2c87b71a_heart_done
	move	d7,d0
	addq	#7,d0
	cmp	hite,d0
	bgt.w	.g2c87b71a_heart_done
	move.l	chunky,a1
	tst.l	a1
	beq.w	.g2c87b71a_heart_done

	; Palette-correct dark, middle and bright red.
	moveq	#12,d2
	moveq	#12,d3
	moveq	#12,d4
	move.l	planar_remap,a0
	tst.l	a0
	beq.s	.g2c87b71a_heart_colours_ready
	moveq	#0,d2
	move.b	$600(a0),d2
	bne.s	.g2c87b71a_heart_dark_ok
	moveq	#12,d2
.g2c87b71a_heart_dark_ok
	moveq	#0,d3
	move.b	$a00(a0),d3
	bne.s	.g2c87b71a_heart_mid_ok
	move	d2,d3
.g2c87b71a_heart_mid_ok
	moveq	#0,d4
	move.b	$f00(a0),d4
	bne.s	.g2c87b71a_heart_colours_ready
	move	d3,d4
.g2c87b71a_heart_colours_ready

	move	d7,d0
	mulu	g2render_stride,d0
	add.l	d0,a1
	lea	coloffs,a2
	lea	g2c87b71a_heart_pixels(pc),a0
	moveq	#6,d7
.g2c87b71a_heart_row
	move	d6,d0
	moveq	#6,d5
.g2c87b71a_heart_col
	moveq	#0,d1
	move.b	(a0)+,d1
	beq.s	.g2c87b71a_heart_next
	cmp.b	#1,d1
	beq.s	.g2c87b71a_heart_dark
	cmp.b	#2,d1
	beq.s	.g2c87b71a_heart_mid
	move	d4,d1
	bra.s	.g2c87b71a_heart_plot
.g2c87b71a_heart_dark
	move	d2,d1
	bra.s	.g2c87b71a_heart_plot
.g2c87b71a_heart_mid
	move	d3,d1
.g2c87b71a_heart_plot
	move.l	a1,a3
	add.l	0(a2,d0*4),a3
	move.b	d1,(a3)
.g2c87b71a_heart_next
	addq	#1,d0
	dbf	d5,.g2c87b71a_heart_col
	adda.w	g2render_stride,a1
	dbf	d7,.g2c87b71a_heart_row
.g2c87b71a_heart_done
	movem.l	(a7)+,d0-d7/a0-a3
	rts

; 0=transparent, 1=dark red, 2=middle red, 3=bright red.
; Geometry follows the old smallfont.bin shape #43: twin lobes, narrow point.
g2c87b71a_heart_pixels
	dc.b	1,3,3,1,3,3,1
	dc.b	1,3,3,3,3,3,1
	dc.b	1,2,3,3,3,2,1
	dc.b	1,2,2,2,2,2,1
	dc.b	0,1,2,2,2,1,0
	dc.b	0,0,1,2,1,0,0
	dc.b	0,0,0,1,0,0,0
	even


; =============================================================================
; c87b72a - visible wall stain owner capture
;
; In: a0 = gore item, a4 = nearest candidate from checknewslow.
; Keep fixed-world rendering unless current vertdraw depth and texture prove
; that this candidate is the actually visible front wall at the stain X.
; =============================================================================
g2c87b72a_store_wall_stain_owner
	movem.l	d0-d7/a1-a3,-(a7)

	; Always retain the legacy fixed-world wall definition. Moving ownership is
	; optional and is enabled only after the candidate is proven frontmost.
	clr.l	go_pool_wallpoly(a0)
	clr	go_pool_wallrelx(a0)
	clr	go_pool_wallrelz(a0)
	move	zo_na(a4),go_pool_walltx(a0)
	move	zo_nb(a4),go_pool_walltz(a0)
	move	#1,go_pool_wall(a0)

	; Project the stored wall anchor. X and depth are independent of the chosen
	; Y here; zero is sufficient for selecting the rendered wall column.
	move	go_pool_wallx(a0),d0
	moveq	#0,d1
	move	go_pool_wallz(a0),d2
	jsr	g2bp_project_xyz
	tst	d0
	beq.w	.g2c87b72a_owner_done

	move	g2bp_px,d0
	bmi.w	.g2c87b72a_owner_done
	cmp	g2render_width,d0
	bge.w	.g2c87b72a_owner_done

	; The candidate must coincide with the currently rendered front wall.
	move.l	vertdraws,a1
	move	d0,d3
	mulu	#vd_size,d3
	lea	0(a1,d3.l),a1
	move.l	vd_data(a1),d4
	beq.w	.g2c87b72a_owner_done

	move	g2bp_pz,d3
	sub	vd_z(a1),d3
	bpl.s	.g2c87b72a_depth_abs
	neg	d3
.g2c87b72a_depth_abs
	cmp	#8,d3			; stricter than the 16-unit draw tolerance
	bhi.w	.g2c87b72a_owner_done

	; Depth alone is insufficient for a closed door hidden almost coplanar
	; behind another wall. Verify that vd_data belongs to one of this polygon's
	; eight texture slots. vd_data points one byte past the 65-byte column header.
	subq.l	#1,d4
	lea	zo_t(a4),a3
	lea	textures,a2
	moveq	#7,d7
.g2c87b72a_texture_loop
	moveq	#0,d0
	move.b	(a3)+,d0
	move.l	0(a2,d0*4),d1
	beq.s	.g2c87b72a_texture_next
	cmp.l	d1,d4
	bcs.s	.g2c87b72a_texture_next
	move.l	d1,d2
	add.l	#4160,d2		; 64 columns * 65 bytes
	cmp.l	d2,d4
	bcs.s	.g2c87b72a_owner_visible
.g2c87b72a_texture_next
	dbf	d7,.g2c87b72a_texture_loop
	bra.w	.g2c87b72a_owner_done

.g2c87b72a_owner_visible
	move.l	a4,go_pool_wallpoly(a0)
	move	go_pool_wallx(a0),d0
	sub	zo_lx(a4),d0
	move	d0,go_pool_wallrelx(a0)
	move	go_pool_wallz(a0),d0
	sub	zo_lz(a4),d0
	move	d0,go_pool_wallrelz(a0)

.g2c87b72a_owner_done
	movem.l	(a7)+,d0-d7/a1-a3
	rts

; =============================================================================
; c87b71a - draw a wall stain from its live polygon-relative anchor
;
; In: a5 = gore item. Static walls reconstruct the same coordinates as before.
; A door updates zo_lx/lz and zo_rx/rz in dodoors; adding the stored relative
; offset makes the stain translate by exactly the same amount as the door.
; A zero owner pointer retains compatibility with already-created/legacy data.
; =============================================================================
g2c87b71a_draw_attached_wall_stain
	movem.l	d0/a0,-(a7)
	tst	go_pool_wall(a5)
	beq.s	.g2c87b71a_stain_done
	move.l	go_pool_wallpoly(a5),a0
	beq.s	.g2c87b71a_stain_legacy

	move	zo_lx(a0),d0
	add	go_pool_wallrelx(a5),d0
	move	d0,go_pool_wallx(a5)
	move	d0,g2bp_wallx
	move	zo_lz(a0),d0
	add	go_pool_wallrelz(a5),d0
	move	d0,go_pool_wallz(a5)
	move	d0,g2bp_wallz
	move	zo_na(a0),d0
	move	d0,go_pool_walltx(a5)
	move	d0,g2bp_walltx
	move	zo_nb(a0),d0
	move	d0,go_pool_walltz(a5)
	move	d0,g2bp_walltz
	bra.s	.g2c87b71a_stain_draw

.g2c87b71a_stain_legacy
	move	go_pool_wallx(a5),g2bp_wallx
	move	go_pool_wallz(a5),g2bp_wallz
	move	go_pool_walltx(a5),g2bp_walltx
	move	go_pool_walltz(a5),g2bp_walltz

.g2c87b71a_stain_draw
	jsr	g2bp_draw_wall_stain
.g2c87b71a_stain_done
	movem.l	(a7)+,d0/a0
	rts

; =============================================================================
; c87b76a - prepare first-person weapon dither/opaque warning state
;
; In:
;   a5 = current player object, or zero
;   d0 = gunpic pointer and must remain unchanged
;
; Behaviour:
;   ob_invisible > 120: 50-percent dithered weapon
;    91..120:          normal fully opaque weapon
;    61..90:           50-percent dithered weapon
;    31..60:           normal fully opaque weapon
;     1..30:           50-percent dithered weapon
;     0:               normal fully opaque weapon remains visible
;
; The final warning alternates dithered and opaque rendering. An alive
; player's weapon is never completely removed by the warning.
;
; Out:
;   Z=1: alive/no player; draw according to g2gun_dither50.
;   Z=0: dead player only; skip the complete overlay.
; =============================================================================
g2c87b76a_prepare_weapon_visibility
	clr.b	g2gun_dither50
	tst.l	a5
	beq.s	.g2c87b76a_weapon_draw
	tst	ob_hitpoints(a5)
	ble.s	.g2c87b76a_weapon_hidden
	move	ob_invisible(a5),d1
	beq.s	.g2c87b76a_weapon_draw

	; More than three seconds remain: accepted continuous 50-percent dither.
	cmp	#120,d1
	bhi.s	.g2c87b76a_weapon_dither

	; Final 150 ticks:
	; 120..91 = normal opaque
	;  90..61 = 50-percent dither
	;  60..31 = normal opaque
	;  30..1  = 50-percent dither
	cmp	#90,d1
	bhi.s	.g2c87b76a_weapon_draw
	cmp	#60,d1
	bhi.s	.g2c87b76a_weapon_dither
	cmp	#30,d1
	bhi.s	.g2c87b76a_weapon_draw

.g2c87b76a_weapon_dither
	st	g2gun_dither50

.g2c87b76a_weapon_draw
	moveq	#0,d1
	tst.b	d1			; Z=1: always draw alive player's weapon
	rts

.g2c87b76a_weapon_hidden
	moveq	#1,d1
	tst.b	d1			; Z=0: dead player only
	rts

; =============================================================================
; c87b75a - finish showstats and draw the current message at upper centre
;
; showstats saved d0-d7/a0-a4 before entering and reaches this routine through
; a six-byte absolute JMP. This helper must restore that exact frame and return
; directly to the original showstats caller.
;
; Existing source strings are reused unchanged. Lower-case letters map through
; g2hud_draw_text_top to the same uppercase smallfont2 glyphs, so examples appear
; visually as HEALTH BONUS, INVISIBILITY, NEW WEAPON, WEAPON BOOST, etc.
; =============================================================================
g2c87b75a_finish_hud_and_message
	tst.l	a5
	beq.w	.g2c87b75a_hud_restore
	tst.l	panel
	beq.w	.g2c87b75a_hud_restore

	; A small-view HUD is first deferred. Draw the message only during the later
	; forced top-strip pass, not into the unconverted compact game window.
	tst	g2hud_pending
	beq.s	.g2c87b75a_message_timer
	tst	g2hud_force_draw
	beq.w	.g2c87b75a_hud_restore

.g2c87b75a_message_timer
	move	ob_messtimer(a5),d0
	ble.w	.g2c87b75a_hud_restore
	move.l	ob_mess(a5),a4
	tst.l	a4
	beq.w	.g2c87b75a_hud_restore
	move	ob_messlen(a5),d0
	ble.w	.g2c87b75a_hud_restore

	; Six pixels per smallfont2 character, centred in the active physical width.
	mulu	#6,d0
	move	g2render_width,d7
	sub	d0,d7
	asr	#1,d7
	bpl.s	.g2c87b75a_message_x_ok
	moveq	#0,d7
.g2c87b75a_message_x_ok
	moveq	#24,d6			; directly below HEALTH/WEAPON/LIVES rows
	jsr	g2hud_draw_text_top

.g2c87b75a_hud_restore
	movem.l	(a7)+,d0-d7/a0-a4
	rts


g2gun_dither50
	dc.b	0
	even


