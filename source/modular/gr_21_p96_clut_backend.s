; =============================================================================
; c87b78h/c87b79q - P96 palette ownership and CLUT runtime foundation
;
; Kept at EOF so the large 256-colour shadow table cannot push established
; GenAm PC-relative references in the original code/data body out of range.
; =============================================================================

; One explicit palette-ownership contract for the native P96 backend.
; p96palette_generation changes for every valid pokepal2 transaction, even when
; the source pointer is reused and only its contents changed (fades/effects).
p96palette_active_ptr	dc.l	0
p96palette_active_count	dc	0
p96palette_active_aga	dc	0
p96palette_generation	dc.l	0
p96palette_remap_generation	dc.l	0
p96palette_table_generation	dc.l	0
p96palette_applied_generation	dc.l	0
p96palette_table_ready	dc	0
p96palette_reserved	dc	0
p96gameplay_lut_palette_generation	dc.l	0
p96gameplay_lut_remap_generation	dc.l	0
p96gameplay_lut_rgbformat	dc.l	0
p96gameplay_lut_aga	dc	0
p96gameplay_lut_reserved	dc	0
	even

g2p96_gameplay_build_rgb565_source_lut_c87b78h
	movem.l	d0-d7/a0-a6,-(a7)
	lea	p96gameplay_rgb565_source_lut,a1
	lea	g2_strip_invpal,a2

	; Select the real currently installed palette exactly as before.
	moveq	#0,d4		;source kind: 1=planar fallback, 2=lastpal
	move.l	lastpal,d3
	beq.s	.try_planar_palette
	moveq	#2,d4
	bra.s	.have_active_palette
.try_planar_palette
	move.l	planar_palette,d3
	beq.w	.black_all
	moveq	#1,d4
.have_active_palette

	; c87b78h: the LUT is immutable until one of its complete inputs changes.
	; This removes the former 256-colour RGB conversion from every gameplay frame
	; while still rebuilding for same-pointer palette edits, fades and remaps.
	tst	p96gameplay_rgb565_source_state
	beq.s	.rebuild
	cmp.l	p96gameplay_palette_ptr,d3
	bne.s	.rebuild
	cmp	p96gameplay_palette_source,d4
	bne.s	.rebuild
	move.l	p96palette_generation,d0
	cmp.l	p96gameplay_lut_palette_generation,d0
	bne.s	.rebuild
	move.l	p96palette_remap_generation,d0
	cmp.l	p96gameplay_lut_remap_generation,d0
	bne.s	.rebuild
	move.l	p96modeid_rgbformat,d0
	cmp.l	p96gameplay_lut_rgbformat,d0
	bne.s	.rebuild
	move	aga,d0
	cmp	p96gameplay_lut_aga,d0
	bne.s	.rebuild
	bra.w	.done

.rebuild
	clr	p96gameplay_rgb565_source_state
	move	d4,p96gameplay_palette_source
	move.l	d3,p96gameplay_palette_ptr
	move.l	d3,a3
	moveq	#0,d7
.lut_loop
	cmp	#256,d7
	bge.s	.valid
	moveq	#0,d0
	move.b	0(a2,d7.w),d0	;undo paladjust/C2P scrambling
	move	d0,d6
	tst	aga
	beq.s	.ecs
	lsl	#2,d6		;AGA palette entry = high/low word pair
	bra.s	.paladdr
.ecs
	add	d6,d6
.paladdr
	move	0(a3,d6.w),d0	;RGB12 high word
	tst	aga
	beq.s	.ecs_convert_high_only
	move	2(a3,d6.w),d2	;AGA RGB12 low word: extra colour precision
	jsr	g2p96_gameplay_rgb12_pair_to_rgb565_aga8
	bra.s	.store_lut_word
.ecs_convert_high_only
	jsr	g2p96_gameplay_rgb12_to_rgb565_c86zds
.store_lut_word
	move	d7,d6
	add	d6,d6
	move	d1,0(a1,d6.w)
	addq	#1,d7
	bra	.lut_loop
.valid
	move.l	p96palette_generation,p96gameplay_lut_palette_generation
	move.l	p96palette_remap_generation,p96gameplay_lut_remap_generation
	move.l	p96modeid_rgbformat,p96gameplay_lut_rgbformat
	move	aga,p96gameplay_lut_aga
	move	#-1,p96gameplay_rgb565_source_state
	bra.s	.done
.black_all
	clr	p96gameplay_rgb565_source_state
	clr	p96gameplay_palette_source
	clr.l	p96gameplay_palette_ptr
	moveq	#0,d0
	move	#255,d7
.black_loop
	move	d0,(a1)+
	dbf	d7,.black_loop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; c87b78h: a1=palette source, d0.w=entry count. Preserve the original pokepal2
; ABI completely. Tracking is P96-only; AGA/ECS pay no extra work and the
; current RGB565 path updates only the compact 1 KB raw palette shadow.
g2p96_palette_note_update_c87b78h
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#2,g2display_mode
	bne.w	.done
	move.l	a1,d1
	beq.s	.invalidate
	moveq	#0,d1
	move	d0,d1
	beq.s	.invalidate
	cmp.l	#256,d1
	bls.s	.count_ok
	move.l	#256,d1
.count_ok
	move.l	a1,p96palette_active_ptr
	move	d1,p96palette_active_count
	move	aga,p96palette_active_aga
	jsr	g2p96_palette_update_raw_shadow_c87b78h
	addq.l	#1,p96palette_generation
	bne.s	.have_generation
	addq.l	#1,p96palette_generation	;generation zero is reserved for "never set"
.have_generation
	jsr	g2p96_palette_apply_clut_if_needed_c87b78h
	bra.s	.done
.invalidate
	clr.l	p96palette_active_ptr
	clr	p96palette_active_count
	clr	p96palette_table_ready
	clr.l	p96palette_table_generation
	clr.l	p96palette_applied_generation
	lea	p96palette_raw_shadow,a0
	move	#255,d7
.clear_raw
	clr.l	(a0)+
	dbf	d7,.clear_raw
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Update colours 0..count-1 in the normalized raw shadow. Each entry is stored
; as an AGA-style high/low RGB12 pair; ECS repeats its high word as the low word.
g2p96_palette_update_raw_shadow_c87b78h
	movem.l	d0-d4/d7/a0-a2,-(a7)
	move.l	p96palette_active_ptr,d0
	beq.w	.done
	move.l	d0,a1
	moveq	#0,d7
	move	p96palette_active_count,d7
	beq.w	.done
	cmp	#256,d7
	bls.s	.count_ok
	move	#256,d7
.count_ok
	lea	p96palette_raw_shadow,a0
	subq	#1,d7
.copy_loop
	move	(a1)+,d1
	move	d1,(a0)+
	tst	p96palette_active_aga
	beq.s	.ecs_low
	move	(a1)+,(a0)+
	bra.s	.next
.ecs_low
	move	d1,(a0)+
.next
	dbf	d7,.copy_loop
.done
	movem.l	(a7)+,d0-d4/d7/a0-a2
	rts

; Build one complete 256-colour graphics.library LoadRGB32 table lazily.
; AGA palettes use the high/low RGB12 pair; ECS repeats the high nibble.
g2p96_palette_build_loadrgb32_c87b78h
	movem.l	d0-d7/a0-a3,-(a7)
	move.l	p96palette_generation,d0
	beq.w	.fail
	lea	p96palette_raw_shadow,a1
	lea	p96palette_loadrgb32_table,a0
	move.l	#$01000000,(a0)+	;256 colours from register zero
	move	#255,d7
.colour_loop
	move	(a1)+,d1	;normalized high RGB12
	move	d1,d2
	move	d1,d3
	move	(a1)+,d4	;normalized low RGB12
	move	d4,d5
	and	#$0f00,d1
	lsr	#4,d1
	and	#$0f00,d5
	lsr	#8,d5
	or	d5,d1
	to32	d1
	move.l	d1,(a0)+

	move	d4,d5
	and	#$00f0,d2
	and	#$00f0,d5
	lsr	#4,d5
	or	d5,d2
	to32	d2
	move.l	d2,(a0)+

	and	#$000f,d3
	lsl	#4,d3
	and	#$000f,d4
	or	d4,d3
	to32	d3
	move.l	d3,(a0)+
	dbf	d7,.colour_loop
	clr.l	p96palette_loadrgb32_terminator
	move.l	p96palette_generation,p96palette_table_generation
	move	#-1,p96palette_table_ready
	moveq	#-1,d0
	bra.s	.done
.fail
	clr	p96palette_table_ready
	clr.l	p96palette_table_generation
	moveq	#0,d0
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts

; c87b78j compatibility entry: palette events invalidate the compositor-exact
; CLUT contract. The next gameplay/static/menu builder owns the LoadRGB32 table.
g2p96_palette_apply_clut_if_needed_c87b78h
	jmp	g2p96_palette_mark_clut_dirty_c87b78j

	even
p96palette_raw_shadow
	dcb.l	256,0	;normalized high/low RGB12 pair per colour
p96palette_loadrgb32_table
	dcb.l	770,0	;LoadRGB32 header + 256*(R,G,B) + terminating zero
p96palette_loadrgb32_terminator	equ	p96palette_loadrgb32_table+4+256*12
	even

; =============================================================================
; c87b78j - guarded native P96 CLUT backend
; =============================================================================

p96clut_stage_ptr	dc.l	0
p96clut_stage_size	dc.l	0
p96clut_reverse_ptr	dc.l	0
p96clut_runtime_ready	dc	0
p96clut_active_role	dc	0	;0=none, 1=gameplay, 2=static/title, 3=menu overlay
p96clut_palette_dirty	dc	0
p96clut_active_lut_ptr	dc.l	0
p96clut_active_lut_sum	dc.l	0
p96clut_game_pal_gen	dc.l	0
p96clut_game_remap_gen	dc.l	0
p96clut_game_rgbformat	dc.l	0
p96clut_game_aga	dc	0
p96clut_pad	dc	0
p96clut_name_stage	dc.b	'p96clutstage',0
p96clut_name_reverse	dc.b	'p96clutreverse',0
	even

; Clear newly allocated CLUT RAM without touching any bitmap.
g2p96_clut_clear_runtime_c87b78j
	movem.l	d0-d2/a0,-(a7)
	move.l	p96clut_stage_ptr,a0
	move.l	p96clut_stage_size,d0
	beq	.clear_reverse
	lsr.l	#2,d0
	beq	.clear_reverse
	subq.l	#1,d0
.clear_stage_loop
	clr.l	(a0)+
	subq.l	#1,d0
	bpl	.clear_stage_loop
.clear_reverse
	move.l	p96clut_reverse_ptr,a0
	move.l	a0,d0
	beq	.done
	move	#16383,d0
.clear_reverse_loop
	clr.l	(a0)+
	dbf	d0,.clear_reverse_loop
.done
	clr	p96clut_active_role
	clr	p96clut_palette_dirty
	clr.l	p96clut_active_lut_ptr
	clr.l	p96clut_active_lut_sum
	movem.l	(a7)+,d0-d2/a0
	rts

; Find one exact native 8-bit CLUT mode for the selected geometry.
; The former RGB565 availability fallback is intentionally gone from the
; Gloom Reforged 2.0 P96 mode contract.
g2p96_req_best_current_c87b78j
	movem.l	d1-d4/a0/a6,-(a7)
	moveq	#0,d0
	move	p96target_width,d0
	move.l	d0,g2p96_req_best_width+4
	moveq	#0,d0
	move	p96target_height,d0
	move.l	d0,g2p96_req_best_height+4
	move.l	p96base,d0
	beq	.fail
	move.l	d0,a6
	move.l	#RGBFF_CLUT,g2p96_req_best_formats+4
	move.l	#8,g2p96_req_best_depth+4
	lea	g2p96_req_best_tags,a0
	jsr	-60(a6)
	cmp.l	#P96_INVALID_ID,d0
	beq	.fail
	tst.l	d0
	beq	.fail
	jsr	g2p96_req_validate_current_c87b78j
	bra	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d4/a0/a6
	rts

; Exact Gloom Reforged 2.0 contract: 8-bit, one byte per pixel,
; RGBFB_CLUT, exact geometry and genuine P96 ownership. This validation is
; shared by the requesters and P96MODEID, so old 16-bit overrides are rejected.
g2p96_req_validate_current_c87b78j
	movem.l	d1-d7/a0-a1/a6,-(a7)
	move.l	d0,d7
	move.l	p96base,d0
	beq.w	.fail
	move.l	d0,a6
	move.l	d7,d0
	moveq	#P96IDA_WIDTH,d1
	jsr	-84(a6)
	and.l	#$0000ffff,d0
	cmp	p96target_width,d0
	bne.w	.fail
	move.l	d7,d0
	moveq	#P96IDA_HEIGHT,d1
	jsr	-84(a6)
	and.l	#$0000ffff,d0
	cmp	p96target_height,d0
	bne.w	.fail
	move.l	d7,d0
	moveq	#G2P96_IDA_ISP96,d1
	jsr	-84(a6)
	tst.l	d0
	beq.w	.fail
	move.l	d7,d0
	moveq	#P96IDA_RGBFORMAT,d1
	jsr	-84(a6)
	cmp.l	#RGBFB_CLUT,d0
	bne.w	.fail
	move.l	d7,d0
	moveq	#G2P96_IDA_DEPTH,d1
	jsr	-84(a6)
	cmp.l	#8,d0
	bne	.fail
	move.l	d7,d0
	moveq	#G2P96_IDA_BYTESPERPIXEL,d1
	jsr	-84(a6)
	cmp.l	#1,d0
	bne	.fail
	move.l	d7,d0
	moveq	#G2P96_IDA_BITSPERPIXEL,d1
	jsr	-84(a6)
	cmp.l	#8,d0
	bne	.fail
	move.l	d7,d0
	bra	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a1/a6
	rts

; pokepal2 only invalidates the presenter-exact CLUT contract. The next
; gameplay/static/menu LUT builder installs the exact matching table.
g2p96_palette_mark_clut_dirty_c87b78j
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne	.done
	move	#-1,p96clut_palette_dirty
	clr	p96clut_active_role
	clr.l	p96clut_active_lut_ptr
.done
	rts

; Compute a cheap order-sensitive checksum over 256 RGB565 words.
; in a0=lut, out d0.l=sum.
g2p96_clut_lut_checksum_c87b78j
	movem.l	d1-d3/a0,-(a7)
	moveq	#0,d0
	move	#255,d3
.loop
	moveq	#0,d1
	move	(a0)+,d1
	rol.l	#3,d0
	eor.l	d1,d0
	add.l	d1,d0
	dbf	d3,.loop
	movem.l	(a7)+,d1-d3/a0
	rts

; Convert one stored RGB565 word to three LoadRGB32 component longs.
; in d0.w=stored word, a1=destination R/G/B longs; advances a1 by 12.
g2p96_clut_store_rgb32_from_word_c87b78j
	movem.l	d0-d6,-(a7)
	; CLUT-era compositor words use the proven R5G6B5PC byte order.
	ror	#8,d0
	move	d0,d1
	lsr	#8,d1
	lsr	#3,d1
	and	#$001f,d1	;R5
	move	d1,d2
	lsl	#3,d1
	lsr	#2,d2
	or	d2,d1		;R8
	to32	d1
	move.l	d1,(a1)+
	move	d0,d1
	lsr	#5,d1
	and	#$003f,d1	;G6
	move	d1,d2
	lsl	#2,d1
	lsr	#4,d2
	or	d2,d1		;G8
	to32	d1
	move.l	d1,(a1)+
	and	#$001f,d0	;B5
	move	d0,d2
	lsl	#3,d0
	lsr	#2,d2
	or	d2,d0		;B8
	to32	d0
	move.l	d0,(a1)+
	movem.l	(a7)+,d0-d6
	rts

; Apply the complete table currently stored in p96palette_loadrgb32_table.
g2p96_clut_apply_table_c87b78j
	movem.l	d1-d2/a0-a2/a6,-(a7)
	moveq	#0,d0
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne	.done
	tst	p96gameplay_persist_active
	beq	.done
	move.l	p96winprobe_window_ptr,d1
	beq	.done
	move.l	d1,a0
	move.l	p96gameplay_intbase,d1
	beq	.done
	move.l	d1,a6
	jsr	-300(a6)	;ViewPortAddress
	move.l	d0,a0
	beq	.fail
	move.l	p96gameplay_grbase,d1
	beq	.fail
	move.l	d1,a6
	lea	p96palette_loadrgb32_table,a1
	jsr	-$372(a6)	;LoadRGB32
	moveq	#-1,d0
	bra	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d2/a0-a2/a6
	rts

; Reapply a previously prepared exact table after a new CLUT screen opens.
; No raw palette is substituted: only the active compositor-exact table is used.
g2p96_clut_apply_pending_c87b78j
	movem.l	d1,-(a7)
	moveq	#0,d0
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne	.done
	tst	p96clut_runtime_ready
	beq	.done
	tst	p96clut_active_role
	beq	.done
	tst	p96clut_palette_dirty
	beq	.done
	jsr	g2p96_clut_apply_table_c87b78j
	tst.l	d0
	beq	.done
	clr	p96clut_palette_dirty
.done
	movem.l	(a7)+,d1
	rts

; Full exact palette/reverse-map install from one compositor LUT.
; in a0=256-word RGB565 LUT, d0.w=role (1 gameplay, 2 static).
g2p96_clut_install_full_lut_c87b78j
	movem.l	d0-d7/a0-a6,-(a7)
	move	d0,d7
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	move.l	a0,a5
	jsr	g2p96_clut_lut_checksum_c87b78j
	move.l	d0,d6
	tst	p96clut_palette_dirty
	bne	.rebuild
	cmp	p96clut_active_role,d7
	bne	.rebuild
	cmp.l	p96clut_active_lut_sum,d6
	bne	.rebuild
	move.l	a5,d0
	cmp.l	p96clut_active_lut_ptr,d0
	beq.w	.done
.rebuild
	move.l	p96clut_reverse_ptr,a2
	move.l	a2,d0
	beq.w	.done
	move	#16383,d0
.clear_reverse
	clr.l	(a2)+
	dbf	d0,.clear_reverse
	move.l	p96clut_reverse_ptr,a2
	lea	p96palette_loadrgb32_table,a1
	move.l	#$01000000,(a1)+
	move.l	a5,a0
	moveq	#0,d5
.loop
	move	(a0)+,d0
	moveq	#0,d1
	move	d0,d1
	move.b	d5,0(a2,d1.l)
	jsr	g2p96_clut_store_rgb32_from_word_c87b78j
	addq	#1,d5
	cmp	#256,d5
	bne	.loop
	clr.l	p96palette_loadrgb32_terminator
	jsr	g2p96_clut_apply_table_c87b78j
	move.l	d0,d4		;remember whether the live ColorMap accepted the table
	move	d7,p96clut_active_role
	move.l	a5,p96clut_active_lut_ptr
	move.l	d6,p96clut_active_lut_sum
	tst.l	d4
	beq	.pending
	clr	p96clut_palette_dirty
	bra	.done
.pending
	move	#-1,p96clut_palette_dirty
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Menu/font LUTs change only the four font pens. Keep the current full gameplay
; or static mapping intact and patch indices 0..3 plus their exact reverse keys.
g2p96_clut_overlay_menu_lut_c87b78j
	movem.l	d0-d7/a0-a4,-(a7)
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done

	; c87b78l: initfontpal/pokepal2 marks the CLUT contract dirty and clears
	; p96clut_active_role before every title/about/in-game menu.  The former
	; overlay therefore returned here and the exact font RGB565 keys were never
	; entered into the reverse map; unmapped glyphs became CLUT index 0 (black).
	; Recover the already composed base page first, then overlay pens 0..3.
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
	move.l	p96clut_reverse_ptr,a2
	move.l	a2,d0
	beq.w	.done
	lea	p96menu_rgb565_lut,a0
	lea	p96palette_loadrgb32_table+4,a1
	moveq	#0,d7
.loop
	move	(a0)+,d0
	moveq	#0,d1
	move	d0,d1
	move.b	d7,0(a2,d1.l)
	jsr	g2p96_clut_store_rgb32_from_word_c87b78j
	addq	#1,d7
	cmp	#4,d7
	bne	.loop
	jsr	g2p96_clut_apply_table_c87b78j
	move.l	d0,d6
	move	#3,p96clut_active_role
	tst.l	d6
	beq	.pending
	clr	p96clut_palette_dirty
	bra	.done
.pending
	move	#-1,p96clut_palette_dirty
.done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

; Hooks called by the existing exact RGB565 LUT builders.
g2p96_clut_gameplay_lut_ready_c87b78j
	movem.l	d0/a0,-(a7)
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne	.done
	; Avoid the 256-word checksum on unchanged gameplay frames.
	tst	p96clut_palette_dirty
	bne	.install
	cmp	#1,p96clut_active_role
	bne	.install
	move.l	p96gameplay_lut_palette_generation,d0
	cmp.l	p96clut_game_pal_gen,d0
	bne	.install
	move.l	p96gameplay_lut_remap_generation,d0
	cmp.l	p96clut_game_remap_gen,d0
	bne	.install
	move.l	p96gameplay_lut_rgbformat,d0
	cmp.l	p96clut_game_rgbformat,d0
	bne	.install
	move	p96gameplay_lut_aga,d0
	cmp	p96clut_game_aga,d0
	beq	.done
.install
	lea	p96gameplay_rgb565_source_lut,a0
	moveq	#1,d0
	jsr	g2p96_clut_install_full_lut_c87b78j
	move.l	p96gameplay_lut_palette_generation,p96clut_game_pal_gen
	move.l	p96gameplay_lut_remap_generation,p96clut_game_remap_gen
	move.l	p96gameplay_lut_rgbformat,p96clut_game_rgbformat
	move	p96gameplay_lut_aga,p96clut_game_aga
.done
	movem.l	(a7)+,d0/a0
	rts

g2p96_clut_static_lut_ready_c87b78j
	movem.l	d0/a0,-(a7)
	lea	p96static_rgb565_lut,a0
	moveq	#2,d0
	jsr	g2p96_clut_install_full_lut_c87b78j
	movem.l	(a7)+,d0/a0
	rts

g2p96_clut_menu_lut_ready_c87b78j
	jsr	g2p96_clut_overlay_menu_lut_c87b78y
	rts

; Return the normal menu/font colour in d2 for callers that draw separators
; without going through the selected/unselected pixel picker.
g2p96_menu_normal_colour_c87b78j
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.s	.invalid
	move	p96menu_rgb565_lut+4,d2	;pen 2, exact key in CLUT reverse map
	rts
.invalid
	moveq	#0,d2
	rts

; Convert the complete RGB565 stage to packed indices before any bitmap lock.
g2p96_clut_convert_full_stage_c87b78j
	movem.l	d1-d7/a0-a3,-(a7)
	moveq	#0,d7
	move.l	p96static_rgbbufptr,a0
	move.l	a0,d0
	beq	.done
	move.l	p96clut_stage_ptr,a1
	move.l	a1,d0
	beq	.done
	move.l	p96clut_reverse_ptr,a2
	move.l	a2,d0
	beq	.done
	moveq	#0,d6
	move	p96target_width,d6
	moveq	#0,d5
	move	p96target_height,d5
	mulu	d6,d5
	move.l	p96clut_stage_size,d0
	cmp.l	d5,d0
	blo	.done
	tst.l	d5
	beq	.done
	subq.l	#1,d5
.loop
	moveq	#0,d0
	move	(a0)+,d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	move.b	d1,(a1)+
	subq.l	#1,d5
	bpl	.loop
	moveq	#-1,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a3
	rts

; CLUT-only full-frame destination publisher.
g2p96_gameplay_copy_stage_to_bitmap_a2_c87b78j
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7
	; c87b79q: visible P96 publication is CLUT-only.  RGB565 is retained
	; only as an internal compositor/key representation and can never be
	; copied to a screen bitmap.
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	jsr	g2p96_clut_convert_full_stage_c87b78j
	tst.l	d0
	beq.w	.done
	move.l	a2,p96gameplay_target_bitmap
	clr.l	p96gameplay_target_lock
	clr.l	p96gameplay_ri_memory
	clr.l	p96gameplay_ri_bpr
	clr.l	p96gameplay_ri_format
	move.l	p96base,d0
	beq.w	.done
	move.l	d0,a6
	move.l	a2,a0
	lea	p96gameplay_renderinfo,a1
	moveq	#12,d0
	jsr	-48(a6)
	move.l	d0,p96gameplay_target_lock
	beq.w	.done
	move.l	p96gameplay_ri_memory,a5
	move.l	a5,d0
	beq	.unlock
	moveq	#0,d3
	move	p96gameplay_ri_bpr,d3
	and.l	#$0000ffff,d3
	moveq	#0,d4
	move	p96target_width,d4
	cmp.l	d4,d3
	blo	.unlock
	cmp.l	#RGBFB_CLUT,p96gameplay_ri_format
	bne	.unlock
	move.l	p96clut_stage_ptr,a4
	cmp.l	d4,d3
	bne	.row_copy
	moveq	#0,d0
	move	p96target_height,d0
	mulu	d4,d0
	move.l	a4,d1
	move.l	a5,d2
	or.l	d2,d1
	or.l	d0,d1
	and.l	#3,d1
	bne	.flat_copy
	move.l	a4,a0
	move.l	a5,a1
	move.l	4.w,a6
	jsr	-630(a6)
	bra	.copy_ok
.flat_copy
	move.l	a4,a0
	move.l	a5,a1
	move.l	4.w,a6
	jsr	-624(a6)
	bra	.copy_ok
.row_copy
	moveq	#0,d6
	move	p96target_height,d6
	beq	.unlock
	subq	#1,d6
.row_loop
	move.l	a4,a0
	move.l	a5,a1
	move.l	d4,d0
	move.l	4.w,a6
	jsr	-624(a6)
	adda.l	d4,a4
	adda.l	d3,a5
	dbf	d6,.row_loop
.copy_ok
	moveq	#-1,d7
.unlock
	move.l	p96gameplay_target_lock,d0
	beq	.done
	move.l	p96gameplay_target_bitmap,a0
	move.l	p96base,a6
	jsr	-54(a6)
	clr.l	p96gameplay_target_lock
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Convert the configured RGB565 rectangle into a packed CLUT rectangle.
; Output is always at p96clut_stage_ptr with src x/y zero and packed BPR.
g2p96_clut_convert_safe_rect_c87b78j
	movem.l	d1-d7/a0-a4,-(a7)
	moveq	#0,d7
	move.l	p96safe_rect_src_ptr,a0
	move.l	a0,d0
	beq.w	.done
	move.l	p96clut_stage_ptr,a1
	move.l	a1,d0
	beq.w	.done
	move.l	p96clut_reverse_ptr,a2
	move.l	a2,d0
	beq.w	.done
	move.l	p96safe_rect_src_bpr,d4
	move.l	p96safe_rect_rowbytes,d5
	move.l	p96safe_rect_src_xbytes,d6
	move.l	p96safe_rect_dst_xbytes,d3
	move.l	d4,d0
	or.l	d5,d0
	or.l	d6,d0
	or.l	d3,d0
	and.l	#1,d0
	bne.w	.done
	lsr.l	#1,d5		;visible pixels / packed CLUT rowbytes
	beq.w	.done
	moveq	#0,d0
	move	p96safe_rect_height,d0
	beq.w	.done
	move.l	d5,d1
	mulu	d0,d1
	cmp.l	p96clut_stage_size,d1
	bhi.w	.done
	moveq	#0,d1
	move	p96safe_rect_src_y,d1
	mulu	d4,d1
	adda.l	d1,a0
	adda.l	d6,a0
	move	d0,d2
	subq	#1,d2
.row
	move.l	a0,a3
	move.l	a1,a4
	move.l	d5,d1
	subq.l	#1,d1
.pixel
	moveq	#0,d0
	move	(a3)+,d0
	moveq	#0,d3
	move.b	0(a2,d0.l),d3
	move.b	d3,(a4)+
	subq.l	#1,d1
	bpl	.pixel
	adda.l	d4,a0
	adda.l	d5,a1
	dbf	d2,.row
	move.l	p96clut_stage_ptr,p96safe_rect_src_ptr
	move.l	d5,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	move.l	d5,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	move.l	p96safe_rect_dst_xbytes,d0
	lsr.l	#1,d0
	move.l	d0,p96safe_rect_dst_xbytes
	moveq	#-1,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a4
	rts

; CLUT-only rectangle publication. RGB565 remains an internal source/key format.
g2p96_copy_ram_rect_to_visible_c87b78j
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7
	; c87b79q: every visible rectangle must target the validated one-byte
	; RGBFB_CLUT bitmap.  There is no 16-bit screen publication fallback.
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	jsr	g2p96_clut_convert_safe_rect_c87b78j
	tst.l	d0
	beq.w	.done
	move.l	p96safe_rect_src_ptr,d0
	beq.w	.done
	move.l	p96safe_rect_src_bpr,d4
	move.l	p96safe_rect_rowbytes,d5
	moveq	#0,d6
	move	p96safe_rect_height,d6
	beq.w	.done
	jsr	g2p96_gameplay_select_visible_bitmap
	tst.l	d0
	beq.w	.done
	move.l	a2,p96gameplay_target_bitmap
	clr.l	p96gameplay_target_lock
	clr.l	p96gameplay_ri_memory
	clr.l	p96gameplay_ri_bpr
	clr.l	p96gameplay_ri_format
	move.l	p96base,d0
	beq.w	.done
	move.l	d0,a6
	move.l	a2,a0
	lea	p96gameplay_renderinfo,a1
	moveq	#12,d0
	jsr	-48(a6)
	move.l	d0,p96gameplay_target_lock
	beq.w	.done
	move.l	p96gameplay_ri_memory,a5
	move.l	a5,d0
	beq.w	.unlock
	moveq	#0,d3
	move	p96gameplay_ri_bpr,d3
	and.l	#$0000ffff,d3
	beq.w	.unlock
	cmp.l	#RGBFB_CLUT,p96gameplay_ri_format
	bne.w	.unlock
	move.l	p96safe_rect_src_ptr,a4
	move.l	p96safe_rect_dst_xbytes,d2
	moveq	#0,d0
	move	p96safe_rect_dst_y,d0
	move.l	p96winprobe_window_ptr,a0
	move.l	a0,d1
	beq	.window_ready
	moveq	#0,d1
	move	4(a0),d1
	ext.l	d1
	tst.l	d1
	bmi.w	.unlock
	add.l	d1,d2		;one byte per CLUT pixel
	moveq	#0,d1
	move	6(a0),d1
	ext.l	d1
	tst.l	d1
	bmi.w	.unlock
	add.l	d1,d0
.window_ready
	move.l	d5,d1
	add.l	d2,d1
	cmp.l	d3,d1
	bhi.w	.unlock
	move.l	d0,d1
	add.l	d6,d1
	moveq	#0,d0
	move	p96target_height,d0
	cmp.l	d0,d1
	bhi.w	.unlock
	moveq	#0,d0
	move	p96safe_rect_dst_y,d0
	move.l	p96winprobe_window_ptr,a0
	move.l	a0,d1
	beq	.address_y
	moveq	#0,d1
	move	6(a0),d1
	add.l	d1,d0
.address_y
	mulu	d3,d0
	adda.l	d0,a5
	adda.l	d2,a5
	subq	#1,d6
.copy_row
	move.l	a4,a0
	move.l	a5,a1
	move.l	d5,d0
	move.l	4.w,a6
	jsr	-624(a6)
	adda.l	d4,a4
	adda.l	d3,a5
	dbf	d6,.copy_row
	moveq	#-1,d7
.unlock
	move.l	p96gameplay_target_lock,d0
	beq	.done
	move.l	p96gameplay_target_bitmap,a0
	move.l	p96base,a6
	jsr	-54(a6)
	clr.l	p96gameplay_target_lock
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; =============================================================================
; c87b78m - direct indexed gameplay path for native RGBFB_CLUT
;
; The installed gameplay CLUT is indexed by the renderer's source byte:
; p96gameplay_rgb565_source_lut[i] becomes LoadRGB32 pen i. The source byte is
; therefore already the final destination pen. Scaling it directly avoids the
; old byte -> RGB565 -> reverse map -> byte round trip on every gameplay pixel.
; =============================================================================

; Fixed-size entry trampoline target. It owns the original outer MOVEM frame.
; Only the normal gameplay owner uses the direct path. Menu/transition owners keep
; the proven RGB565 staged page because their caches source p96static_rgbbufptr.
g2p96_gameplay_draw_dispatch_c87b78m
	movem.l	d0-d7/a0-a6,-(a7)
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.s	.rgb565
	cmp	#P96DSP_GAMEPLAY,p96display_state
	bne.s	.rgb565
	jsr	g2p96_gameplay_draw_direct_clut_c87b78m
	jmp	g2p96_gameplay_draw_common_done_c87b78m
.rgb565
	move.l	chunky,d0
	bne.s	.have_chunky
	jmp	g2p96_gameplay_draw_common_done_c87b78m
.have_chunky
	jmp	g2p96_gameplay_draw_rgb565_continue_c87b78m

; Build a complete packed 8-bit gameplay page in Fast RAM, then copy it to the
; safe draw ScreenBuffer with the normal short bitmap lock. No VRAM is touched
; while rendering/scaling and no RGB565 intermediate page is written.
g2p96_gameplay_draw_direct_clut_c87b78m
	movem.l	d0-d7/a0-a6,-(a7)
	clr	p96gameplay_direct_state
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	move.l	chunky,d0
	beq.w	.done
	move.l	d0,a4
	move	chunkymodw,d5
	beq.w	.done
	move.l	p96clut_stage_ptr,d0
	beq.w	.done
	move.l	d0,a3
	moveq	#0,d4
	move	p96target_width,d4
	beq.w	.done
	moveq	#0,d0
	move	p96target_height,d0
	beq.w	.done
	mulu	d4,d0
	cmp.l	p96clut_stage_size,d0
	bhi.w	.done
	move	d4,p96gameplay_stage_bpr

	; Generation-cached: installs exact pen i for renderer byte i when needed.
	jsr	g2p96_gameplay_build_rgb565_source_lut
	cmp	#1,p96clut_active_role
	bne.w	.done
	tst	p96clut_palette_dirty
	bne.w	.done

	; c87b79c: exact-size entry trampoline. On ordinary frames the helper
	; restores a6=coloffs and d0=hite exactly like the replaced instructions.
	; On validated TWO PLAYER it publishes the complete packed split page directly
	; for all six exact P96 geometries, including true 428/854 WIDE.
	jsr	g2p96_twop_direct_all_try_c87b79c
	bmi.w	.fps_overlay
	nop
	tst	twowins
	beq.s	.present_rows_ready
	move	g2twop_half_height,d0
	add	d0,d0
.present_rows_ready
	move	d0,g2p96_present_rows
	; Exact packed single-player pages can bypass the per-pixel rebuild.
	; The helper preserves the fallback registers and validates live coloffs.
	jsr	g2p96_try_fast_clut_stage_c87b83b
	tst.l	d0
	bne.w	.fps_overlay
	; c87b84b: exact 2x expansion of validated linear source pages.
	jsr	g2p96_try_fast_scaled_clut_stage_c87b84b
	tst.l	d0
	bne.w	.fps_overlay
	moveq	#0,d6
.rowloop
	cmp	g2p96_present_rows,d6
	bge.w	.fps_overlay
	move	d6,d0
	mulu	d5,d0
	move.l	a4,a2
	adda.l	d0,a2
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
	tst	g2p96_oneone_mode
	beq.s	.y_ready
	cmp	#256,g2p96_present_rows
	beq.s	.y_ready
	tst	p96gameplay_linear_active
	bne.s	.y_ready
	tst	g2p96_hires_mode
	beq.s	.y_low
	add	#16,d0
	bra.s	.y_ready
.y_low
	addq	#8,d0
.y_ready
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
	beq	.copy_scaled_240
	bra	.copy_scaled_480

.copy_wide_1x
	moveq	#0,d7
.wide1_loop
	cmp	g2render_width,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	move.b	d1,(a1)+
	addq	#1,d7
	bra.s	.wide1_loop

.copy_wide_2x
	moveq	#0,d7
	move	g2render_last_x,d3
.wide2_loop
	cmp	g2render_width,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d2
	move.b	0(a2,d0.l),d2
	move.b	d2,(a1)+
	move.b	d2,(a0)+
	cmp	#428,g2render_width
	bne.s	.wide2_dup
	tst	d7
	beq.s	.wide2_next
	cmp	d3,d7
	beq.s	.wide2_next
.wide2_dup
	move.b	d2,(a1)+
	move.b	d2,(a0)+
.wide2_next
	addq	#1,d7
	bra.s	.wide2_loop

.copy_1x
	moveq	#0,d7
.copy1_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	move.b	d1,(a1)+
	addq	#1,d7
	bra.s	.copy1_loop

.copy_2x
	moveq	#0,d7
.copy2_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d2
	move.b	0(a2,d0.l),d2
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	addq	#1,d7
	bra.s	.copy2_loop

.copy_scaled_480
	moveq	#0,d7
	moveq	#0,d3
	moveq	#0,d2
.scaled480_src_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	p96target_width,d3
.scaled480_emit
	cmp	p96target_width,d2
	bge.w	.nextrow
	move.b	d1,(a1)+
	move.b	d1,(a0)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.scaled480_emit
	addq	#1,d7
	bra.s	.scaled480_src_loop

.copy_scaled_240
	moveq	#0,d7
	moveq	#0,d3
	moveq	#0,d2
.scaled240_src_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	add	p96target_width,d3
.scaled240_emit
	cmp	p96target_width,d2
	bge.w	.scaled240_hud_overlay
	move.b	d1,(a1)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.scaled240_emit
	addq	#1,d7
	bra.s	.scaled240_src_loop

.scaled240_hud_overlay
	lea	-80(a1),a1
	move	#240,d7
.hud240_loop
	cmp	#320,d7
	bge.w	.nextrow
	move.l	0(a6,d7*4),d0
	moveq	#0,d1
	move.b	0(a2,d0.l),d1
	move.b	d1,(a1)+
	addq	#1,d7
	bra.s	.hud240_loop

.nextrow
	addq	#1,d6
	bra.w	.rowloop

.fps_overlay
	jsr	g2map_overlay_draw
	move.l	a3,a0
	move.l	d4,d0
	jsr	g2fps_draw_p96_clut_target_c87b78m
	jsr	g2p96_gameplay_copy_clut_stage_to_draw_target_c87b78m
	tst.l	d0
	beq.w	.done
	move	#-1,p96gameplay_direct_state
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Select the safe draw bitmap and publish the already packed CLUT page.
g2p96_gameplay_copy_clut_stage_to_draw_target_c87b78m
	movem.l	d1-d7/a0-a6,-(a7)
	jsr	g2p96_gameplay_select_draw_bitmap
	tst.l	d0
	beq.s	.fail
	jsr	g2p96_gameplay_copy_clut_stage_to_bitmap_a2_c87b78m
	bra.s	.done
.fail
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; a2=destination BitMap. The indexed stage is complete before locking.
g2p96_gameplay_copy_clut_stage_to_bitmap_a2_c87b78m
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7
	move.l	a2,p96gameplay_target_bitmap
	clr.l	p96gameplay_target_lock
	clr.l	p96gameplay_ri_memory
	clr.l	p96gameplay_ri_bpr
	clr.l	p96gameplay_ri_format
	move.l	p96clut_stage_ptr,d0
	beq.w	.done
	move.l	p96base,d0
	beq.w	.done
	move.l	d0,a6
	move.l	a2,a0
	lea	p96gameplay_renderinfo,a1
	moveq	#12,d0
	jsr	-48(a6)
	move.l	d0,p96gameplay_target_lock
	beq.w	.done
	move.l	p96gameplay_ri_memory,a5
	move.l	a5,d0
	beq.w	.unlock
	moveq	#0,d3
	move	p96gameplay_ri_bpr,d3
	and.l	#$0000ffff,d3
	moveq	#0,d4
	move	p96target_width,d4
	cmp.l	d4,d3
	blo.w	.unlock
	cmp.l	#RGBFB_CLUT,p96gameplay_ri_format
	bne.w	.unlock
	move.l	p96clut_stage_ptr,a4

	cmp.l	d4,d3
	bne.s	.row_copy
	moveq	#0,d0
	move	p96target_height,d0
	mulu	d4,d0
	cmp.l	p96clut_stage_size,d0
	bhi.w	.unlock
	move.l	a4,d1
	move.l	a5,d2
	or.l	d2,d1
	or.l	d0,d1
	and.l	#3,d1
	bne.s	.flat_copy
	move.l	a4,a0
	move.l	a5,a1
	move.l	4.w,a6
	jsr	-630(a6)
	bra.s	.copy_ok
.flat_copy
	move.l	a4,a0
	move.l	a5,a1
	move.l	4.w,a6
	jsr	-624(a6)
	bra.s	.copy_ok

.row_copy
	moveq	#0,d6
	move	p96target_height,d6
	beq.s	.unlock
	subq	#1,d6
.row_loop
	move.l	a4,a0
	move.l	a5,a1
	move.l	d4,d0
	move.l	4.w,a6
	jsr	-624(a6)
	adda.l	d4,a4
	adda.l	d3,a5
	dbf	d6,.row_loop
.copy_ok
	moveq	#-1,d7
.unlock
	move.l	p96gameplay_target_lock,d0
	beq.w	.done
	move.l	p96gameplay_target_bitmap,a0
	move.l	p96base,a6
	jsr	-54(a6)
	clr.l	p96gameplay_target_lock
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Indexed equivalent of g2fps_draw_p96_target. Black still uses the exact
; RGB565 $0000 reverse key. RC5 obtains the digit pen from the palette-aware
; whitest-neutral chunky selector because many valid gameplay LUTs contain no
; exact RGB565 $FFFF key.
g2fps_draw_p96_clut_target_c87b78m
	tst	g2fps_enabled
	beq.w	.done
	cmp	#P96DSP_GAMEPLAY,p96display_state
	bne.w	.done
	tst	g2teleport_blackout
	bne.w	.done
	movem.l	d0-d7/a0-a4,-(a7)
	jsr	g2fps_update_present
	move.l	a0,a4
	move.l	d0,d5
	move.l	p96clut_reverse_ptr,a3
	move.l	a3,d0
	beq.w	.exit
	moveq	#0,d2
	move.b	(a3),d2		;installed pen for exact RGB565 black
	jsr	g2fps_find_white_chunky	;RC5: adjusted source pen for whitest neutral colour
	cmp.b	d2,d4
	bne.s	.g2rc5_white_ready
	moveq	#1,d4		;defensive visible-pen fallback for degenerate palettes
	cmp.b	d2,d4
	bne.s	.g2rc5_white_ready
	moveq	#-1,d4
.g2rc5_white_ready
	moveq	#0,d0
	move	p96target_width,d0
	cmp	#14,d0
	bcs.w	.exit
	sub	#14,d0
	adda.l	d0,a4
	moveq	#0,d0
	move	p96target_height,d0
	cmp	#10,d0
	bcs.w	.exit
	sub	#10,d0
	mulu	d5,d0
	adda.l	d0,a4
	move.l	a4,a1
	moveq	#8,d6
.clear_row
	move.l	a1,a2
	moveq	#12,d7
.clear_pixel
	move.b	d2,(a2)+
	dbf	d7,.clear_pixel
	adda.l	d5,a1
	dbf	d6,.clear_row
	adda.l	d5,a4
	addq.l	#1,a4
	jsr	g2fps_draw_digits_clut_c87b78m
.exit
	movem.l	(a7)+,d0-d7/a0-a4
.done
	rts

g2fps_draw_digits_clut_c87b78m
	jsr	g2fps_split_digits
	move	d6,d0
	lsl	#3,d0
	sub	d6,d0
	ext.l	d0
	lea	g2fps_digits,a0
	adda.l	d0,a0
	move.l	a4,a1
	jsr	g2fps_draw_glyph_clut_c87b78m
	move	d7,d0
	lsl	#3,d0
	sub	d7,d0
	ext.l	d0
	lea	g2fps_digits,a0
	adda.l	d0,a0
	move.l	a4,a1
	adda.w	#6,a1
	jsr	g2fps_draw_glyph_clut_c87b78m
	rts

g2fps_draw_glyph_clut_c87b78m
	movem.l	d0/d6/a1,-(a7)
	moveq	#6,d6
.row
	moveq	#0,d0
	move.b	(a0)+,d0
	btst	#4,d0
	beq.s	.x1
	move.b	d4,(a1)
.x1
	btst	#3,d0
	beq.s	.x2
	move.b	d4,1(a1)
.x2
	btst	#2,d0
	beq.s	.x3
	move.b	d4,2(a1)
.x3
	btst	#1,d0
	beq.s	.x4
	move.b	d4,3(a1)
.x4
	btst	#0,d0
	beq.s	.next
	move.b	d4,4(a1)
.next
	adda.l	d5,a1
	dbf	d6,.row
	movem.l	(a7)+,d0/d6/a1
	rts



; =============================================================================
; c87b78n - direct indexed static-screen publication for native RGBFB_CLUT
;
; The mature static compositor still builds p96static_rgbbufptr because the
; title/About/in-game menu caches and the staged intermission typewriter use it
; as their clean final-size RGB565 background.  The visible CLUT publication no
; longer needs to convert that complete RGB565 page back through the 65536-byte
; reverse map when an authoritative p96static_direct_index_ptr is available.
;
; Guarded scope:
;   - exact RGBFB_CLUT target
;   - valid 320x240 direct static composition
;   - standard aspect output (not WIDE)
;   - normal 240/480-line output (not 5:4 border wash)
;
; WIDE and 5:4 deliberately retain the RGB565/reverse-map path because their
; decorative shaded borders create colours which are not original source pens.
; Any failure immediately falls through to the proven c87b78j RGB565 converter.
; =============================================================================

p96static_direct_clut_state	dc.w	0
	even

; Drop-in replacement for the one final call made after the RGB565 page has
; been completed.  Success returns without touching the fallback publisher;
; failure tail-jumps to the mature RGB565 -> CLUT/RGB565 path.
g2p96_static_copy_rgb_buffer_to_p96_c87b78n
	jmp	g2p96_static_copy_rgb_buffer_to_p96_c87b78t
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; Scale the authoritative 320x240 palette-index page directly into the packed
; final-size CLUT stage. Every destination byte is written before any bitmap is
; locked. Modes match the established static RGB565 scaler:
;   0 = 320x240 1x1
;   1 = 640x480 2x2
;   3 = horizontally scaled 240-line output
;   2 = horizontally scaled and vertically doubled 480-line output
; WIDE and 5:4 never enter this routine.
g2p96_static_build_direct_clut_stage_c87b78n
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7
	move.l	p96static_direct_index_ptr,a4
	move.l	a4,d0
	beq.w	.done
	tst	p96static_direct_valid
	beq.w	.done
	move.l	p96clut_stage_ptr,a3
	move.l	a3,d0
	beq.w	.done
	moveq	#0,d4
	move	p96target_width,d4
	beq.w	.done
	moveq	#0,d0
	move	p96target_height,d0
	beq.w	.done
	mulu	d4,d0
	cmp.l	p96clut_stage_size,d0
	bhi.w	.done

	; Reject unexpected geometry instead of leaving partly written rows.
	move	p96target_mode,d1
	cmp	#0,d1
	bne.s	.check_2x
	cmp	#320,d4
	bne.w	.done
	cmp	#240,p96target_height
	bne.w	.done
	bra.s	.geometry_ok
.check_2x
	cmp	#1,d1
	bne.s	.check_scaled_low
	cmp	#640,d4
	bne.w	.done
	cmp	#480,p96target_height
	bne.w	.done
	bra.s	.geometry_ok
.check_scaled_low
	cmp	#3,d1
	bne.s	.check_scaled_high
	cmp	#240,p96target_height
	bne.w	.done
	cmp	#320,d4
	blo.w	.done
	bra.s	.geometry_ok
.check_scaled_high
	cmp	#2,d1
	bne.w	.done
	cmp	#480,p96target_height
	bne.w	.done
	cmp	#320,d4
	blo.w	.done
.geometry_ok
	move	d4,p96gameplay_stage_bpr
	moveq	#0,d6
.row_loop
	cmp	#240,d6
	bge.w	.success
	move.l	a4,a2
	move	d6,d0
	mulu	#320,d0
	adda.l	d0,a2

	move	d6,d0
	move	p96target_mode,d1
	cmp	#1,d1
	beq.s	.double_y
	cmp	#2,d1
	bne.s	.y_ready
.double_y
	add	d0,d0
.y_ready
	mulu	d4,d0
	move.l	a3,a1
	adda.l	d0,a1
	move.l	a1,a0
	cmp	#1,d1
	beq.s	.second_row
	cmp	#2,d1
	bne.s	.dispatch
.second_row
	adda.l	d4,a0
.dispatch
	cmp	#0,d1
	beq.w	.copy_1x
	cmp	#1,d1
	beq.w	.copy_2x
	cmp	#3,d1
	beq.w	.copy_scaled_240
	bra.w	.copy_scaled_480

.copy_1x
	; Geometry was validated as exactly 320 bytes. CopyMem is safe for any
	; alignment and avoids 320 per-pixel loop iterations.
	move.l	a2,a0
	; Preserve destination row while CopyMem requires a1.
	move.l	a1,a5
	move.l	a5,a1
	move.l	#320,d0
	move.l	4.w,a6
	jsr	-624(a6)
	bra.w	.next_row

.copy_2x
	moveq	#0,d5
.copy2_loop
	cmp	#320,d5
	bge.w	.next_row
	moveq	#0,d2
	move.b	(a2)+,d2
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	addq	#1,d5
	bra.s	.copy2_loop

.copy_scaled_240
	moveq	#0,d5		;source x
	moveq	#0,d3		;Bresenham accumulator
	moveq	#0,d2		;destination x
.scaled240_source
	cmp	#320,d5
	bge.w	.next_row
	moveq	#0,d0
	move.b	(a2)+,d0
	add	d4,d3
.scaled240_emit
	cmp	d4,d2
	bge.w	.next_row
	move.b	d0,(a1)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.scaled240_emit
	addq	#1,d5
	bra.s	.scaled240_source

.copy_scaled_480
	moveq	#0,d5		;source x
	moveq	#0,d3		;Bresenham accumulator
	moveq	#0,d2		;destination x
.scaled480_source
	cmp	#320,d5
	bge.w	.next_row
	moveq	#0,d0
	move.b	(a2)+,d0
	add	d4,d3
.scaled480_emit
	cmp	d4,d2
	bge.w	.next_row
	move.b	d0,(a1)+
	move.b	d0,(a0)+
	addq	#1,d2
	sub	#320,d3
	cmp	#320,d3
	bhs.s	.scaled480_emit
	addq	#1,d5
	bra.s	.scaled480_source

.next_row
	addq	#1,d6
	bra.w	.row_loop
.success
	moveq	#-1,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; =============================================================================
; c87b78o - first-open in-game-menu RGB565 backdrop synchronisation
;
; Native CLUT gameplay keeps the authoritative visible frame in the packed
; one-byte p96clut_stage_ptr and deliberately skips the old per-frame RGB565
; page. The menu compositor still takes its clean background from the packed
; two-byte p96static_rgbbufptr. For the confirmed 320x240 standard path, rebuild
; that cache once from the exact current CLUT frame before changing display
; ownership to MENU_BRIDGE. No P96 bitmap is locked or touched here.
;
; This routine replaces the old six-byte CLR at the call site and therefore also
; performs that original clear on every path. It is intentionally conservative:
; all other geometries/formats simply keep the previous behaviour.
; =============================================================================

p96menu_first_backdrop_sync_state
	dc.w	0	; -1=current 320x240 CLUT frame mirrored to RGB565, 0=fallback
	even

g2p96_menu_sync_rgb565_backdrop_c87b78o
	movem.l	d0-d7/a0-a3,-(a7)
	clr	p96gameplay_skip_aga_present	; preserve the replaced original operation
	clr	p96menu_first_backdrop_sync_state

	cmp	#2,g2display_mode
	bne.w	.done
	cmp	#P96DSP_GAMEPLAY,p96display_state
	bne.w	.done
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	cmp	#320,p96target_width
	bne.w	.done
	cmp	#240,p96target_height
	bne.w	.done
	tst	g2p96_wide_mode
	bne.w	.done
	tst	g2p96_oneone_mode
	bne.w	.done
	move.l	p96clut_stage_ptr,d0
	beq.w	.done
	move.l	d0,a0
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	move.l	d0,a1
	move.l	p96static_rgbbufsize,d0
	cmp.l	#153600,d0		; 320*240*2 bytes required
	bcs.w	.done

	; Revalidate the exact source-byte -> RGB565 table for the paused frame.
	jsr	g2p96_gameplay_build_rgb565_source_lut
	cmp	#1,p96clut_active_role
	bne.w	.done
	tst	p96clut_palette_dirty
	bne.w	.done
	lea	p96gameplay_rgb565_source_lut,a2
	move.l	#76800,d7		; one complete 320x240 indexed frame
.copy_pixel
	moveq	#0,d0
	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	0(a2,d0.w),(a1)+
	subq.l	#1,d7
	bne.s	.copy_pixel
	move	#-1,p96menu_first_backdrop_sync_state
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts



; =============================================================================
; c87b78p - direct indexed 320x240 P96/CLUT in-game-menu composition
;
; Scope is intentionally exact and conservative:
;   - P96 display owner
;   - RGBFB_CLUT target
;   - 320x240, target mode 0
;   - standard aspect (no WIDE, no 5:4)
;   - a successfully published direct indexed gameplay frame
;
; The clean paused background remains in p96clut_stage_ptr. Full-menu and
; current-row caches are one byte per pixel. Existing menu code may continue to
; describe glyph colours as exact RGB565 keys; only the short cache plotter maps
; those keys through p96clut_reverse_ptr to the installed destination pen.
; No bitmap is read, no RGB565 backdrop is built on first entry and the bitmap
; lock covers only the completed one-byte rectangle copy.
; =============================================================================

p96menu_direct_index_ready	dc.w	0
p96menu_direct_index_batch	dc.w	0
p96menu_direct_index_cache	dc.w	0
p96menu_direct_index_last_publish	dc.w	0
	even

; Geometry/capability predicate independent of display_state. d0=-1 on success.
g2p96_menu_direct_clut_320_geometry_c87b78p
	bra.w	g2p96_menu_direct_clut_standard_geometry_c87b78r
	moveq	#0,d0
	cmp	#2,g2display_mode
	bne.w	.done
	cmp.l	#RGBFB_CLUT,p96modeid_rgbformat
	bne.w	.done
	tst	p96clut_runtime_ready
	beq.w	.done
	cmp	#0,p96target_mode
	bne.w	.done
	cmp	#320,p96target_width
	bne.w	.done
	cmp	#240,p96target_height
	bne.w	.done
	tst	g2p96_wide_mode
	bne.w	.done
	tst	g2p96_oneone_mode
	bne.w	.done
	move.l	p96clut_stage_ptr,d1
	beq.w	.done
	move.l	p96clut_stage_size,d2
	cmp.l	#76800,d2
	bcs.w	.done
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d2
	rts

; Active in-game-menu predicate. d0=-1 only for the new indexed path.
g2p96_menu_direct_clut_320_active_c87b78p
	jmp	g2p96_menu_direct_clut_320_active_c87b78q
	; c87b80c: unreachable superseded body removed; entry remains a direct JMP.


; First ESC-menu entry. For the direct path, retain the exact indexed gameplay
; stage and skip the c87b78o 8-bit -> RGB565 mirror. All fallback modes still
; call the confirmed synchroniser unchanged.
g2p96_menu_prepare_index_backdrop_c87b78p
	clr	p96menu_direct_index_ready
	clr	p96menu_direct_index_batch
	clr	p96menu_direct_index_cache
	clr	p96menu_direct_index_last_publish
	jsr	g2p96_menu_direct_clut_320_geometry_c87b78p
	tst.l	d0
	beq.s	.fallback
	cmp	#P96DSP_GAMEPLAY,p96display_state
	bne.s	.fallback
	tst	p96gameplay_direct_state
	beq.s	.fallback
	clr	p96gameplay_skip_aga_present	; operation replaced at the original call site
	move	#-1,p96menu_direct_index_ready
	rts
.fallback
	jmp	g2p96_menu_sync_rgb565_backdrop_c87b78o

; FLOOR/CEILING redraw still uses the mature RGB565 compositor while menu owns
; the screen. Convert that completed RAM page back to the indexed clean stage
; once, outside any bitmap lock, so subsequent row restores see the new view.
g2p96_menu_refresh_index_backdrop_c87b78p
	movem.l	d0-d2/a0-a2,-(a7)
	clr	p96gameplay_skip_aga_present	; preserve replaced instruction
	tst	p96menu_direct_index_ready
	beq.s	.done
	jsr	g2p96_menu_direct_clut_320_active_c87b78p
	tst.l	d0
	beq.s	.done
	jsr	g2p96_clut_convert_full_stage_c87b78j
.done
	movem.l	(a7)+,d0-d2/a0-a2
	rts

; -----------------------------------------------------------------------------
; Full-menu batch cache dispatch and one-byte implementation.
; -----------------------------------------------------------------------------
g2p96_menu_batch_begin_dispatch_c87b78p
	clr	p96menu_direct_index_batch
	jsr	g2p96_menu_direct_clut_320_active_c87b78p
	tst.l	d0
	bne.s	.direct
	jmp	g2p96_menu_batch_begin_c87b78d
.direct
	jmp	g2p96_menu_batch_begin_index_standard_c87b78r

g2p96_menu_batch_begin_index_c87b78p
	movem.l	d0-d7/a0-a6,-(a7)
	clr	p96menu_batch_active
	clr	p96menu_direct_index_batch
	move.l	p96menu_page_cache_ptr,d0
	bne.s	.have_cache
	move.l	#900000,d0
	moveq	#1,d1
	lea	p96menu_page_cache_name,a0
	jsr	allocmem_
	move.l	d0,p96menu_page_cache_ptr
	beq.w	.done
.have_cache
	move	#320,p96menu_batch_rowbytes
	move.l	#320,p96menu_batch_bpr
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
	move	d0,p96menu_batch_dst_y0
	move	d1,p96menu_batch_height
	move.l	p96clut_stage_ptr,a0
	moveq	#0,d2
	move	d0,d2
	mulu	#320,d2
	adda.l	d2,a0
	move.l	p96menu_page_cache_ptr,a1
	moveq	#0,d0
	move	d1,d0
	mulu	#320,d0
	move.l	4.w,a6
	jsr	-624(a6)	; CopyMem: clean indexed stage -> indexed batch
	move	#-1,p96menu_direct_index_batch
	move	#-1,p96menu_batch_active
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2p96_menu_batch_flush_dispatch_c87b78p
	tst	p96menu_direct_index_batch
	bne.s	.direct
	jmp	g2p96_menu_batch_flush_c87b78d
.direct
	jmp	g2p96_menu_batch_flush_index_standard_c87b78r

g2p96_menu_batch_flush_index_c87b78p
	movem.l	d0-d3/a0,-(a7)
	clr	p96menu_direct_index_last_publish
	tst	p96menu_batch_active
	beq.w	.done
	move.l	p96menu_page_cache_ptr,d0
	beq.w	.done
	move.l	d0,p96safe_rect_src_ptr
	move.l	#320,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	#320,p96safe_rect_rowbytes
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

; -----------------------------------------------------------------------------
; One-row cache dispatch and one-byte implementation.
; -----------------------------------------------------------------------------
g2p96_menu_cache_begin_dispatch_c87b78p
	clr	p96menu_direct_index_cache
	jsr	g2p96_menu_direct_clut_320_active_c87b78p
	tst.l	d0
	bne.s	.direct
	jmp	g2p96_menu_cache_begin_c87b78d
.direct
	jmp	g2p96_menu_cache_begin_index_standard_c87b78r

g2p96_menu_cache_begin_index_c87b78p
	movem.l	d0-d7/a0-a2/a6,-(a7)
	clr	p96menu_cache_active
	clr	p96menu_direct_index_cache
	tst	p96menu_batch_active
	bne.w	.done
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
	move	#320,p96menu_cache_rowbytes
	move	d2,p96menu_cache_dsty
	sub	d2,d3
	move	d3,p96menu_cache_height
	move.l	p96clut_stage_ptr,a0
	moveq	#0,d0
	move	d2,d0
	mulu	#320,d0
	adda.l	d0,a0
	lea	p96menu_row_cache,a1
	moveq	#0,d0
	move	d3,d0
	mulu	#320,d0
	move.l	4.w,a6
	jsr	-624(a6)
	move	#-1,p96menu_direct_index_cache
	move	#-1,p96menu_cache_active
.done
	movem.l	(a7)+,d0-d7/a0-a2/a6
	rts

g2p96_menu_cache_flush_dispatch_c87b78p
	tst	p96menu_direct_index_cache
	bne.s	.direct
	jmp	g2p96_menu_cache_flush_c87b78d
.direct
	jmp	g2p96_menu_cache_flush_index_standard_c87b78r

g2p96_menu_cache_flush_index_c87b78p
	movem.l	d0-d3/a0,-(a7)
	tst	p96menu_batch_active
	bne.w	.done
	moveq	#0,d0
	move	p96menu_cache_height,d0
	beq.w	.done
	lea	p96menu_row_cache,a0
	move.l	a0,p96safe_rect_src_ptr
	move.l	#320,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	#320,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	move	p96menu_cache_dsty,p96safe_rect_dst_y
	move	d0,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
.done
	movem.l	(a7)+,d0-d3/a0
	rts

; Restore a selected/blinking row from the untouched indexed gameplay stage.
g2p96_menu_restore_current_row_dispatch_c87b78p
	jsr	g2p96_menu_direct_clut_320_active_c87b78p
	tst.l	d0
	bne.s	.direct
	jmp	g2p96_menu_restore_current_row_best_c87b78d
.direct
	jmp	g2p96_menu_restore_current_row_index_standard_c87b78r

g2p96_menu_restore_current_row_index_c87b78p
	movem.l	d1-d7/a0-a2,-(a7)
	moveq	#0,d7
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
	bge.s	.done
	move	d3,d4
	sub	d2,d4
	move.l	p96clut_stage_ptr,p96safe_rect_src_ptr
	move.l	#320,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	#320,p96safe_rect_rowbytes
	move	d2,p96safe_rect_src_y
	move	d2,p96safe_rect_dst_y
	move	d4,p96safe_rect_height
	jsr	g2p96_publish_direct_clut_rect_c87b78p
	move.l	d0,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a2
	rts

; -----------------------------------------------------------------------------
; RGB565-key -> destination-pen cache plotters. Existing glyph scanners and
; exact font colour selection remain unchanged; only cache storage is indexed.
; -----------------------------------------------------------------------------
g2p96_menu_native_put_pixel_batch_dispatch_c87b78p
	tst	p96menu_direct_index_batch
	bne.s	.direct
	jmp	g2p96_menu_native_put_pixel_batch
.direct
	jmp	g2p96_menu_native_put_pixel_batch_index_standard_c87b78r

g2p96_menu_native_put_pixel_batch_index_c87b78p
	movem.l	d0-d7/a0-a2,-(a7)
	cmp	#0,d0
	blt.s	.done
	cmp	#320,d0
	bge.s	.done
	sub	p96menu_batch_src_y0,d1
	blt.s	.done
	cmp	p96menu_batch_height,d1
	bge.s	.done
	move.l	p96menu_page_cache_ptr,a1
	move.l	a1,d3
	beq.s	.done
	move	d1,d3
	mulu	#320,d3
	adda.l	d3,a1
	adda.w	d0,a1
	move.l	p96clut_reverse_ptr,a0
	move.l	a0,d3
	beq.s	.done
	moveq	#0,d3
	move	d2,d3
	move.b	0(a0,d3.l),(a1)
.done
	movem.l	(a7)+,d0-d7/a0-a2
	rts

g2p96_menu_native_put_pixel_cache_dispatch_c87b78p
	tst	p96menu_direct_index_cache
	bne.s	.direct
	jmp	g2p96_menu_native_put_pixel_cache
.direct
	jmp	g2p96_menu_native_put_pixel_cache_index_standard_c87b78r

g2p96_menu_native_put_pixel_cache_index_c87b78p
	movem.l	d0-d7/a0-a2,-(a7)
	cmp	#0,d0
	blt.s	.done
	cmp	#320,d0
	bge.s	.done
	sub	p96menu_cache_dsty,d1
	blt.s	.done
	cmp	p96menu_cache_height,d1
	bge.s	.done
	lea	p96menu_row_cache,a1
	move	d1,d3
	mulu	#320,d3
	adda.l	d3,a1
	adda.w	d0,a1
	move.l	p96clut_reverse_ptr,a0
	move.l	a0,d3
	beq.s	.done
	moveq	#0,d3
	move	d2,d3
	move.b	0(a0,d3.l),(a1)
.done
	movem.l	(a7)+,d0-d7/a0-a2
	rts

; -----------------------------------------------------------------------------
; Publish an already indexed RAM rectangle. RenderInfo supplies actual VRAM
; memory, stride and format. The lock is held only during row CopyMem calls.
; -----------------------------------------------------------------------------
g2p96_publish_direct_clut_rect_c87b78p
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7
	move.l	p96safe_rect_src_ptr,d0
	beq.w	.done
	move.l	p96safe_rect_src_bpr,d4
	beq.w	.done
	move.l	p96safe_rect_rowbytes,d5
	beq.w	.done
	moveq	#0,d6
	move	p96safe_rect_height,d6
	beq.w	.done
	move.l	p96safe_rect_src_xbytes,d0
	add.l	d5,d0
	cmp.l	d4,d0
	bhi.w	.done
	jsr	g2p96_gameplay_select_visible_bitmap
	tst.l	d0
	beq.w	.done
	move.l	a2,p96gameplay_target_bitmap
	clr.l	p96gameplay_target_lock
	clr.l	p96gameplay_ri_memory
	clr.l	p96gameplay_ri_bpr
	clr.l	p96gameplay_ri_format
	move.l	p96base,d0
	beq.w	.done
	move.l	d0,a6
	move.l	a2,a0
	lea	p96gameplay_renderinfo,a1
	moveq	#12,d0
	jsr	-48(a6)
	move.l	d0,p96gameplay_target_lock
	beq.w	.done
	move.l	p96gameplay_ri_memory,a5
	move.l	a5,d0
	beq.w	.unlock
	moveq	#0,d3
	move	p96gameplay_ri_bpr,d3
	and.l	#$0000ffff,d3
	beq.w	.unlock
	cmp.l	#RGBFB_CLUT,p96gameplay_ri_format
	bne.w	.unlock

	move.l	p96safe_rect_src_ptr,a4
	moveq	#0,d0
	move	p96safe_rect_src_y,d0
	mulu	d4,d0
	adda.l	d0,a4
	adda.l	p96safe_rect_src_xbytes,a4

	move.l	p96safe_rect_dst_xbytes,d2
	moveq	#0,d0
	move	p96safe_rect_dst_y,d0
	move.l	p96winprobe_window_ptr,a0
	move.l	a0,d1
	beq.s	.window_ready
	moveq	#0,d1
	move	4(a0),d1
	ext.l	d1
	tst.l	d1
	bmi.w	.unlock
	add.l	d1,d2	; one byte per indexed pixel
	moveq	#0,d1
	move	6(a0),d1
	ext.l	d1
	tst.l	d1
	bmi.w	.unlock
	add.l	d1,d0
.window_ready
	move.l	d5,d1
	add.l	d2,d1
	cmp.l	d3,d1
	bhi.w	.unlock
	move.l	d0,d1
	add.l	d6,d1
	moveq	#0,d0
	move	p96target_height,d0
	cmp.l	d0,d1
	bhi.w	.unlock
	moveq	#0,d0
	move	p96safe_rect_dst_y,d0
	move.l	p96winprobe_window_ptr,a0
	move.l	a0,d1
	beq.s	.address_y
	moveq	#0,d1
	move	6(a0),d1
	add.l	d1,d0
.address_y
	mulu	d3,d0
	adda.l	d0,a5
	adda.l	d2,a5
	subq	#1,d6
.copy_row
	move.l	a4,a0
	move.l	a5,a1
	move.l	d5,d0
	move.l	4.w,a6
	jsr	-624(a6)
	adda.l	d4,a4
	adda.l	d3,a5
	dbf	d6,.copy_row
	moveq	#-1,d7
.unlock
	move.l	p96gameplay_target_lock,d0
	beq.s	.done
	move.l	p96gameplay_target_bitmap,a0
	move.l	p96base,a6
	jsr	-54(a6)
	clr.l	p96gameplay_target_lock
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts


; =============================================================================
; v2.3.3 / c87b83b: card-independent exact-size RAM staging.
; CopyMemQuick is used only with aligned addresses/size; otherwise CopyMem.
; Scaled, non-linear and split layouts retain the original pixel builder.
; No VRAM lock, cache policy, buffer policy or diagnostic logging is added.
; =============================================================================
	even
g2p96_try_fast_clut_stage_c87b83b
	movem.l d1-d7/a0-a6,-(a7)
	moveq #0,d0
	tst twowins
	bne.w .done
	tst p96gameplay_linear_active
	beq.w .done
	tst p96target_mode
	bne.w .done
	moveq #0,d2
	move p96target_width,d2
	cmp #320,d2
	beq.w .width_ok
	cmp #428,d2
	bne.w .done
.width_ok
	cmp g2render_width,d2
	bne.w .done
	cmp chunkymodw,d2
	bne.w .done
	moveq #0,d3
	move p96target_height,d3
	cmp hite,d3
	bne.w .done
	cmp g2p96_present_rows,d3
	bne.w .done
	tst d3
	beq.w .done
	move.l chunky,a0
	move.l a0,d1
	beq.w .done
	move.l p96clut_stage_ptr,a1
	move.l a1,d1
	beq.w .done
	; Validate the live table, including fallback after menu/layout changes.
	lea coloffs,a2
	moveq #0,d4
.offsets
	cmp.l (a2)+,d4
	bne.w .done
	addq #1,d4
	cmp d2,d4
	blo.w .offsets
	mulu d2,d3
	cmp.l p96clut_stage_size,d3
	bhi.w .done
	move.l a0,d1
	move.l a1,d2
	or.l d2,d1
	or.l d3,d1
	and.l #3,d1
	move.l d3,d0
	move.l 4.w,a6
	tst.l d1
	bne.w .unaligned
	jsr -630(a6) ; CopyMemQuick, CPU/OS selects implementation
	bra.w .copied
.unaligned
	jsr -624(a6) ; CopyMem supports unaligned allocations
.copied
	moveq #-1,d0
.done
	movem.l (a7)+,d1-d7/a0-a6
	rts


; =============================================================================
; v2.4.0 / c87b84b: fast 640x480, 640x512 and 854x480 RAM staging.
; No source-table indirection or per-pixel geometry branches in the hot loops.
; Both destination rows receive the same aligned word; no per-row library call.
; Standard: 320 source bytes -> 640 pens. WIDE: adjacent source pairs yield
; [s0,s1], [s1,s2], ... [s426,s427], exactly 1 + 426*2 + 1 = 854 pens.
; Complete guard validation precedes the first write. All other layouts fall
; back to the original builder. No allocation, cache change, VRAM or logging.
; =============================================================================
	even
g2p96_try_fast_scaled_clut_stage_c87b84b
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d0
	tst	twowins
	bne.w	.done
	tst	p96gameplay_linear_active
	beq.w	.done
	moveq	#0,d2
	move	p96target_width,d2
	moveq	#0,d7
	cmp	#1,p96target_mode
	beq.w	.standard_geometry
	cmp	#2,p96target_mode
	bne.w	.done
	cmp	#854,d2
	bne.w	.done
	tst	g2p96_wide_mode
	beq.w	.done
	cmp	#428,g2render_width
	bne.w	.done
	cmp	#428,chunkymodw
	bne.w	.done
	cmp	#427,g2render_last_x
	bne.w	.done
	cmp	#240,hite
	bne.w	.done
	move	#428,d7
	bra.w	.common_geometry
.standard_geometry
	cmp	#640,d2
	bne.w	.done
	tst	g2p96_wide_mode
	bne.w	.done
	cmp	#320,g2render_width
	bne.w	.done
	cmp	#320,chunkymodw
	bne.w	.done
	cmp	#319,g2render_last_x
	bne.w	.done
	cmp	#240,hite
	beq.s	.standard_rows_ok
	cmp	#256,hite
	bne.w	.done
.standard_rows_ok
	move	#320,d7
.common_geometry
	moveq	#0,d3
	move	hite,d3
	cmp	g2p96_present_rows,d3
	bne.w	.done
	move.l	d3,d1
	add	d1,d1
	cmp	p96target_height,d1
	bne.w	.done
	mulu	d2,d1
	cmp.l	p96clut_stage_size,d1
	bhi.w	.done
	move.l	chunky,a0
	move.l	a0,d1
	beq.w	.done
	move.l	p96clut_stage_ptr,a1
	move.l	a1,d1
	beq.w	.done
	btst	#0,d1	; every destination row and word must be even-aligned
	bne.w	.done
	lea	coloffs,a2
	moveq	#0,d4
.check_columns
	cmp.l	(a2)+,d4
	bne.w	.done
	addq	#1,d4
	cmp	d7,d4
	blo.s	.check_columns
	move.l	a1,a2
	adda.w	d2,a2
	subq	#1,d3	; source rows minus one for DBF
	moveq	#0,d0
	cmp	#428,d7
	beq.w	.wide_row
	lea	g2resolution_dupbyte_table,a4
.standard_row
	moveq	#79,d5	; 80 groups of four source pixels
.standard_pixels
	move.b	(a0)+,d0
	move.w	0(a4,d0.w*2),d1
	move.w	d1,(a1)+
	move.w	d1,(a2)+
	move.b	(a0)+,d0
	move.w	0(a4,d0.w*2),d1
	move.w	d1,(a1)+
	move.w	d1,(a2)+
	move.b	(a0)+,d0
	move.w	0(a4,d0.w*2),d1
	move.w	d1,(a1)+
	move.w	d1,(a2)+
	move.b	(a0)+,d0
	move.w	0(a4,d0.w*2),d1
	move.w	d1,(a1)+
	move.w	d1,(a2)+
	dbf	d5,.standard_pixels
	adda.w	d2,a1
	adda.w	d2,a2
	dbf	d3,.standard_row
	bra.w	.success
.wide_row
	move.b	(a0)+,d0	; preload first edge pixel, consume remaining 427 below
	moveq	#60,d5	; 61 groups of seven adjacent source pairs
.wide_pixels
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	lsl.w	#8,d0
	move.b	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,(a2)+
	dbf	d5,.wide_pixels
	adda.w	d2,a1
	adda.w	d2,a2
	dbf	d3,.wide_row
.success
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

