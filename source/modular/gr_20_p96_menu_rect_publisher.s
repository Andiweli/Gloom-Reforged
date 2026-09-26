; =============================================================================
; c87b78d - native P96 menu/title staged rectangle publication
;
; The clean final-size RGB565 page in p96static_rgbbufptr is the source of
; truth for title and in-game-menu backgrounds. Glyphs are rendered into a
; Fast-RAM row/full-menu cache. Only the completed rectangle is copied while
; the visible P96 bitmap is locked. No menu/title routine below renders into,
; reads from or derives addresses from BitMap.Planes[]/BytesPerRow.
; =============================================================================

p96safe_rect_src_ptr
	dc.l	0
p96safe_rect_src_bpr
	dc.l	0
p96safe_rect_src_xbytes
	dc.l	0
p96safe_rect_dst_xbytes
	dc.l	0
p96safe_rect_rowbytes
	dc.l	0
p96safe_rect_src_y
	dc.w	0
p96safe_rect_dst_y
	dc.w	0
p96safe_rect_height
	dc.w	0
	even

; Return d0=-1 when the native menu renderer has both a Fast-RAM staged page
; and a selectable visible P96 bitmap. The "target" fields point to the staged
; page, never VRAM; row/full-menu cache flushes publish through the lock helper.
g2p96_menu_glyph_prepare_target_c87b78d
	movem.l	d1-d4/a0-a2,-(a7)
	moveq	#0,d0
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96static_rgbbufptr,d1
	beq.w	.done
	moveq	#0,d2
	move	p96target_width,d2
	beq.w	.done
	add.l	d2,d2
	move.l	d1,p96menu_native_dstbase
	move.l	d2,p96menu_native_bpr
	jsr	g2p96_gameplay_select_visible_bitmap
	tst.l	d0
	beq.w	.done_zero
	moveq	#-1,d0
	bra.s	.done
.done_zero
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d4/a0-a2
	rts

; Restore the current logical menu row from the clean staged target page.
; The staged page already contains final P96 geometry, so only Y mapping from
; the 320x240 menu coordinate system is required.
g2p96_menu_restore_current_row_best_c87b78d
	movem.l	d1-d7/a0-a2,-(a7)
	moveq	#0,d7
	cmp	#P96DSP_MENU,p96display_state
	beq.s	.state_ok
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.done
.state_ok
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96static_rgbbufptr,d0
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
	; Native 5:4 keeps the 240-line menu centred inside the 256-line page.
	tst	g2p96_oneone_mode
	beq.s	.no_5x4_offset
	addq	#8,d2
	addq	#8,d3
.no_5x4_offset
	move	p96target_mode,d4
	cmp	#1,d4
	beq.s	.double_y
	cmp	#2,d4
	bne.s	.have_y
.double_y
	add	d2,d2
	add	d3,d3
.have_y
	move	d3,d5
	sub	d2,d5
	ble.w	.done
	moveq	#0,d6
	move	p96target_width,d6
	beq.w	.done
	add.l	d6,d6
	move.l	p96static_rgbbufptr,p96safe_rect_src_ptr
	move.l	d6,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d6,p96safe_rect_rowbytes
	move	d2,p96safe_rect_src_y
	move	d2,p96safe_rect_dst_y
	move	d5,p96safe_rect_height
	jsr	g2p96_copy_ram_rect_to_visible_c87b78d
	move.l	d0,d7
.done
	move.l	d7,d0
	movem.l	(a7)+,d1-d7/a0-a2
	rts

; Build one menu row cache from the clean staged page, never from visible VRAM.
g2p96_menu_cache_begin_c87b78d
	movem.l	d0-d7/a0-a2/a6,-(a7)
	clr	p96menu_cache_active
	tst	p96menu_batch_active
	bne.w	.done
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	moveq	#0,d4
	move	p96target_width,d4
	beq.w	.done
	add.l	d4,d4
	move	d4,p96menu_cache_rowbytes
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
	tst	g2p96_oneone_mode
	beq.s	.no_5x4_offset
	addq	#8,d2
	addq	#8,d3
.no_5x4_offset
	move	p96target_mode,d1
	cmp	#1,d1
	beq.s	.double_y
	cmp	#2,d1
	bne.s	.have_y
.double_y
	add	d2,d2
	add	d3,d3
.have_y
	move	d2,p96menu_cache_dsty
	sub	d2,d3
	move	d3,p96menu_cache_height
	ble.w	.done
	; Full-width staged rows are packed, therefore the requested slice is flat.
	move.l	p96static_rgbbufptr,a0
	moveq	#0,d0
	move	d2,d0
	mulu	d4,d0
	adda.l	d0,a0
	lea	p96menu_row_cache,a1
	moveq	#0,d0
	move	d3,d0
	mulu	d4,d0
	move.l	4.w,a6
	jsr	-624(a6)	;CopyMem: staged page -> completed Fast-RAM row cache
	move	#-1,p96menu_cache_active
.done
	movem.l	(a7)+,d0-d7/a0-a2/a6
	rts

; Publish one completed row cache through a short P96 bitmap lock.
g2p96_menu_cache_flush_c87b78d
	movem.l	d0-d3,-(a7)
	tst	p96menu_batch_active
	bne.w	.done
	moveq	#0,d0
	move	p96menu_cache_rowbytes,d0
	beq.w	.done
	moveq	#0,d1
	move	p96menu_cache_height,d1
	beq.w	.done
	lea	p96menu_row_cache,a0
	move.l	a0,p96safe_rect_src_ptr
	move.l	d0,p96safe_rect_src_bpr
	clr.l	p96safe_rect_src_xbytes
	clr.l	p96safe_rect_dst_xbytes
	move.l	d0,p96safe_rect_rowbytes
	clr	p96safe_rect_src_y
	move	p96menu_cache_dsty,p96safe_rect_dst_y
	move	d1,p96safe_rect_height
	jsr	g2p96_copy_ram_rect_to_visible_c87b78d
.done
	movem.l	(a7)+,d0-d3
	rts

; Build the full active menu text region from the clean staged page.
g2p96_menu_batch_begin_c87b78d
	movem.l	d0-d7/a0-a6,-(a7)
	clr	p96menu_batch_active
	cmp	#P96DSP_MENU,p96display_state
	beq.s	.state_ok
	cmp	#P96DSP_TITLE,p96display_state
	bne.w	.done
.state_ok
	tst	p96gameplay_persist_active
	beq.w	.done
	move.l	p96static_rgbbufptr,d0
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
	add.l	d4,d4
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

	; Convert logical menu Y bounds to final staged-page coordinates.
	tst	g2p96_oneone_mode
	beq.s	.no_5x4_offset
	addq	#8,d0
.no_5x4_offset
	move	p96target_mode,d2
	cmp	#1,d2
	beq.s	.double_y
	cmp	#2,d2
	bne.s	.have_dest_y
.double_y
	add	d0,d0
	add	d1,d1
.have_dest_y
	move	d0,p96menu_batch_dst_y0
	move	d1,p96menu_batch_height
	beq.w	.done

	move.l	p96static_rgbbufptr,a0
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
	jsr	-624(a6)	;CopyMem: clean staged region -> menu batch RAM
	move	#-1,p96menu_batch_active
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Publish the completed full-menu RAM batch through one short bitmap lock.
g2p96_menu_batch_flush_c87b78d
	movem.l	d0-d3/a0,-(a7)
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
	jsr	g2p96_copy_ram_rect_to_visible_c87b78d
.done
	movem.l	(a7)+,d0-d3/a0
	rts

; Copy one completed Fast-RAM rectangle to the visible P96 bitmap.
; The bitmap is locked only for the linear CopyMem rows and is always unlocked
; before return. RenderInfo provides the real VRAM pointer, stride and format.
g2p96_copy_ram_rect_to_visible_c87b78d
	jmp	g2p96_copy_ram_rect_to_visible_c87b78j
