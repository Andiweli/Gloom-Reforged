; Cold-path resource bounds. Private memlist headers keep allocation ownership
; and logical payload length separate. No checks are added to render loops.

g2asset_bounds	; a0=user start; d0=logical length (0 if unknown), a1=end
	movem.l	d1/a2,-(a7)
	move.l	memlist,a2
.heap
	move.l	a2,d0
	beq.s	.static
	move.l	a2,d1
	add.l	8(a2),d1
	cmp.l	a0,d1
	beq.s	.found
	move.l	(a2),a2
	bra.s	.heap
.found
	move.l	16(a2),d0
	move.l	a0,a1
	add.l	d0,a1
	bra.s	.done
.static
	lea	g2asset_static_ranges,a2
.next
	move.l	(a2)+,d0
	beq.s	.unknown
	cmp.l	a0,d0
	beq.s	.static_found
	addq.l	#4,a2
	bra.s	.next
.static_found
	move.l	(a2),a1
	move.l	a1,d0
	sub.l	a0,d0
	bra.s	.done
.unknown
	move.l	a0,a1
.done
	movem.l	(a7)+,d1/a2
	rts

g2asset_set_length	; a0=registered user pointer, d0=actual payload bytes
	movem.l	d1/a1,-(a7)
	move.l	memlist,a1
.loop
	move.l	a1,d1
	beq.s	.bad
	add.l	8(a1),d1
	cmp.l	a0,d1
	beq.s	.found
	move.l	(a1),a1
	bra.s	.loop
.found
	move.l	4(a1),d1
	sub.l	8(a1),d1
	cmp.l	d1,d0
	bhi.s	.bad
	move.l	d0,16(a1)
	clr.l	20(a1)
	movem.l	(a7)+,d1/a1
	rts
.bad
	jmp	g2fatal_abort

g2validate_palette	; a0=palette start, a1=end; 0=valid, -1=invalid
	movem.l	d1-d2,-(a7)
	move.l	a1,d1
	sub.l	a0,d1
	cmp.l	#2,d1
	bcs.s	.bad
	moveq	#0,d2
	move.w	(a0),d2
	beq.s	.bad	; addpal's DBF must never receive an empty palette
	cmp.l	#255,d2
	bhi.s	.bad
	add.l	d2,d2
	addq.l	#2,d2
	cmp.l	d1,d2
	bhi.s	.bad
	moveq	#0,d0
	bra.s	.done
.bad
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d2
	rts

g2validate_anim	; a0=start; 0=valid, -1=invalid; all other registers preserved
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a2
	jsr	g2asset_bounds
	cmp.l	#an_size,d0
	bcs.w	.bad
	move.l	d0,d6
	move.l	a1,a3
	moveq	#0,d1
	move.w	an_rotshft(a2),d1
	cmp.l	#15,d1
	bhi.w	.bad
	moveq	#0,d7
	move.w	an_frames(a2),d7
	beq.w	.bad
	lsl.l	d1,d7
	cmp.l	#65536,d7
	bhi.w	.bad
	move.l	d7,d5
	lsl.l	#2,d5
	add.l	#an_size,d5
	cmp.l	d6,d5
	bhi.w	.bad
	move.l	an_pal(a2),d1
	cmp.l	d5,d1
	bcs.w	.bad
	cmp.l	d6,d1
	bcc.w	.bad
	lea	0(a2,d1.l),a0
	move.l	a3,a1
	jsr	g2validate_palette
	tst.l	d0
	bne.w	.bad
	lea	an_size(a2),a4
.frame
	move.l	(a4)+,d1
	cmp.l	d5,d1
	bcs.w	.bad
	move.l	d6,d2
	sub.l	#8,d2
	cmp.l	d2,d1
	bhi.w	.bad
	lea	0(a2,d1.l),a0
	moveq	#0,d2
	moveq	#0,d3
	move.w	4(a0),d2
	move.w	6(a0),d3
	beq.w	.bad
	tst.w	d2
	beq.w	.bad
	mulu	d3,d2
	move.l	d6,d3
	sub.l	d1,d3
	subq.l	#8,d3
	cmp.l	d3,d2
	bhi.w	.bad
	subq.l	#1,d7
	bne.w	.frame
	moveq	#0,d0
	bra.s	.done
.bad
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

g2require_anim
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2validate_anim
	tst.l	d0
	bne.s	.bad
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.bad
	jmp	g2fatal_abort

g2validate_texture	; one to twenty 64x65 columns plus a bounded palette
	movem.l	d1-d2/a0-a1,-(a7)
	jsr	g2asset_bounds
	cmp.l	#4+64*65+2,d0
	bcs.s	.bad
	move.l	(a0),d1
	cmp.l	#4+64*65,d1
	bcs.s	.bad
	cmp.l	#4+20*64*65,d1
	bhi.s	.bad
	subq.l	#2,d0
	cmp.l	d0,d1
	bhi.s	.bad
	move.l	d1,d2
	subq.l	#4,d2
	divu	#64*65,d2
	swap	d2
	tst.w	d2
	bne.s	.bad	; compact screens must still contain whole columns
	add.l	d1,a0
	jsr	g2validate_palette
	bra.s	.done
.bad
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d2/a0-a1
	rts

g2require_texture
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2validate_texture
	tst.l	d0
	bne.s	.bad
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.bad
	jmp	g2fatal_abort

g2clear_texture_slots
	movem.l	d0-d1/a0,-(a7)
	lea	textures,a0
	moveq	#0,d0
	move.w	#159,d1
.loop
	move.l	d0,(a0)+
	dbf	d1,.loop
	movem.l	(a7)+,d0-d1/a0
	rts

; Map framing, grid/point indices and the eight texture names are checked here.
; Full event-bytecode operands and polygon semantics remain F004 open work.
g2validate_map
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a2
	jsr	g2asset_bounds
	cmp.l	#116+8192,d0
	bcs.w	.bad
	move.l	d0,d7
	move.l	a1,a6
	move.l	(a2),d1
	cmp.l	#116,d1
	bcs.w	.bad
	moveq	#4,d6
	move.l	a2,a3
.offsets
	move.l	(a3)+,d2
	cmp.l	d1,d2
	bcs.w	.bad
	cmp.l	d7,d2
	bcc.w	.bad
	btst	#0,d2
	bne.w	.bad
	move.l	d2,d1
	dbf	d6,.offsets
	move.l	4(a2),d1
	sub.l	(a2),d1
	cmp.l	#8192,d1
	bcs.w	.bad
	move.l	8(a2),d5
	sub.l	4(a2),d5
	move.l	d5,d1
	and.l	#31,d1
	bne.w	.bad
	lsr.l	#5,d5		; polygon count, indexed by signed word*32
	cmp.l	#1024,d5
	bhi.w	.bad
	move.l	12(a2),d4
	sub.l	8(a2),d4
	lsr.l	#1,d4		; point index count
	cmp.l	#32768,d4
	bhi.w	.bad
	move.l	a2,a3
	add.l	8(a2),a3
	move.l	d4,d6
	beq.s	.grid_start
.points
	moveq	#0,d1
	move.w	(a3)+,d1
	cmp.l	d5,d1
	bcc.w	.bad
	subq.l	#1,d6
	bne.s	.points
.grid_start
	move.l	a2,a3
	add.l	(a2),a3
	move.w	#2047,d6	; wall and trigger group per 32x32 square
.grid
	moveq	#0,d1
	move.w	(a3)+,d1
	moveq	#0,d2
	move.w	(a3)+,d2
	tst.w	d1
	bmi.s	.grid_next
	cmp.l	#32767,d2
	bhi.w	.bad
	addq.l	#1,d1
	add.l	d2,d1
	cmp.l	d4,d1
	bhi.w	.bad
.grid_next
	dbf	d6,.grid
	move.l	a2,a3
	add.l	16(a2),a3
	moveq	#7,d6
.name
	moveq	#63,d5
.char
	cmp.l	a6,a3
	bcc.w	.bad
	tst.b	(a3)+
	beq.s	.next_name
	subq.w	#1,d5
	bpl.s	.char
	bra.w	.bad
.next_name
	dbf	d6,.name
	lea	20(a2),a3
	moveq	#23,d6
.event
	move.l	(a3)+,d1
	cmp.l	#116,d1
	bcs.w	.bad
	move.l	d7,d2
	subq.l	#2,d2
	cmp.l	d2,d1
	bhi.w	.bad
	btst	#0,d1
	bne.w	.bad
	dbf	d6,.event
	moveq	#0,d0
	bra.s	.done
.bad
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

g2require_map
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	map_map,a0
	jsr	g2validate_map
	tst.l	d0
	bne.s	.bad
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.bad
	jmp	g2fatal_abort

; Validate all ByteRun1 rows before either existing decoder sees the picture.
g2validate_iff
	movem.l	d1-d7/a0-a3,-(a7)
	move.l	a0,a2
	jsr	g2asset_bounds
	cmp.l	#12,d0
	bcs.w	.bad
	move.l	a1,a3
	moveq	#0,d4
	move.w	(a2)+,d4
	beq.w	.bad
	cmp.l	#320,d4
	bhi.w	.bad
	move.l	d4,d1
	and.l	#7,d1
	bne.w	.bad
	lsr.l	#3,d4
	moveq	#0,d5
	move.w	(a2)+,d5
	beq.w	.bad
	moveq	#0,d1
	move.w	(a2)+,d1
	beq.w	.bad
	cmp.l	#8,d1
	bhi.w	.bad
	mulu	d1,d5
	addq.l	#6,a2
.row
	move.l	d4,d3
.run
	cmp.l	a3,a2
	bcc.w	.bad
	moveq	#0,d2
	move.b	(a2)+,d2
	ext.w	d2
	bmi.s	.repeat
	addq.w	#1,d2
	cmp.w	d3,d2
	bhi.w	.bad
	move.l	a3,d1
	sub.l	a2,d1
	cmp.l	d1,d2
	bhi.w	.bad
	add.l	d2,a2
	bra.s	.advance
.repeat
	cmp.w	#-128,d2
	beq.s	.run
	neg.w	d2
	addq.w	#1,d2
	cmp.w	d3,d2
	bhi.w	.bad
	cmp.l	a3,a2
	bcc.w	.bad
	addq.l	#1,a2
.advance
	sub.w	d2,d3
	bne.s	.run
	subq.l	#1,d5
	bne.s	.row
	moveq	#0,d0
	bra.s	.done
.bad
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a3
	rts

g2require_iff
	movem.l	d0-d7/a0-a6,-(a7)
	; Dynamic pictures cache successful validation in their private header.
	move.l	memlist,a4
.find
	move.l	a4,d0
	beq.s	.validate
	add.l	8(a4),d0
	cmp.l	a0,d0
	beq.s	.cache
	move.l	(a4),a4
	bra.s	.find
.cache
	btst	#0,23(a4)
	bne.s	.done
.validate
	jsr	g2validate_iff
	tst.l	d0
	bne.s	.bad
	move.l	a4,d0
	beq.s	.done
	bset	#0,23(a4)
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts
.bad
	jmp	g2fatal_abort

g2asset_static_ranges
	dc.l	g2embed_bigfont2_crm,g2embed_bigfont2_crm_end
	dc.l	g2embed_smallfont2_crm,g2embed_smallfont2_crm_end
	dc.l	g2embed_gun,g2embed_gun_end
	dc.l	g2embed_palette8_crm,g2embed_palette8_crm_end
	dc.l	g2embed_remap8_crm,g2embed_remap8_crm_end
	dc.l	g2embed_title,g2embed_title_end
	dc.l	g2embed_title_pal,g2embed_title_pal_end
	dc.l	g2embed_gloombrush,g2embed_gloombrush_end
	dc.l	g2embed_zm_titlebrush,g2embed_zm_titlebrush_end
	dc.l	g2embed_zm_title_pal,g2embed_zm_title_pal_end
	dc.l	bullet1,bullet1_end
	dc.l	bullet2,bullet2_end
	dc.l	bullet3,bullet3_end
	dc.l	bullet4,bullet4_end
	dc.l	bullet5,bullet5_end
	dc.l	sparks1,sparks1_end
	dc.l	sparks2,sparks2_end
	dc.l	sparks3,sparks3_end
	dc.l	sparks4,sparks4_end
	dc.l	sparks5,sparks5_end
	dc.l	0
