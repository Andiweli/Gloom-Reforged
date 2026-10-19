; =============================================================================
; 2.5.0: Gloom 3 / Zombie Massacre monsters with fewer frames (from v3.0 c87b87d).
; Included by GloomReforged_Modular.s and by GloomBench.s (shared hook in
; gr_36).
;
; The actor logic indexes drawshape_8 entries frame*8+facing. Attacks use
; frame 5 (entries 40..47, baldypunch and the monsters that share it). The
; original Gloom 3 files objs/baldy, objs/lizard and objs/troll have only 40
; entries and objs/demon has 47; the 2.4.0 audit stabilization rejected them
; (fatal #31) when the first such monster was loaded.
;
; g2legacy_actor_extend replaces the JMP g2fatal_abort of
; g2require_actor_shape (same size). For profiles 2/3 it builds a private
; copy of the loaded shape with the missing entries appended: each missing
; entry shows the last existing frame of the same facing (entry - 8, - 16 ...;
; the last entry if no frame has that facing). All pixels, shapes and the
; palette are copied unchanged. The copy is made right after the load and the
; palette remap of the file and before any object of that type exists; the
; holder is updated and the original allocation is freed, so freeobjlist
; frees the copy as before. remapanim is never called again for level
; objects, so the aliased entries are not remapped twice. Gloom and Gloom
; Deluxe keep the fatal check. Every existing label keeps its address.
; =============================================================================

; From g2require_actor_shape .bad (JMP, its MOVEM frame is on the stack):
; a0 = loaded shape, a2 = resource holder, d0 = entries present, d1 = entries
; the actor logic uses.
g2legacy_actor_extend
	cmp.w	#2,g2_game_profile
	beq.s	.legacy
	cmp.w	#3,g2_game_profile
	bne.s	.fatal
.legacy
	movem.l	d0-d1,-(a7)
	bsr.w	g2legacy_actor_copy
	tst.l	d0
	beq.s	.fatal_pop
	move.l	d0,(a2)			; the holder owns the extended copy
	addq.l	#8,a7
	movem.l	(a7)+,d0-d7/a0-a6	; return from g2require_actor_shape
	rts
.fatal_pop
	movem.l	(a7)+,d0-d1
.fatal
	jmp	g2fatal_abort

; a0 = validated shape (owned), d0 = entries present, d1 = entries needed.
; d0 = extended copy (original freed) or 0 (nothing changed). Other registers
; preserved.
g2legacy_actor_copy
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a2			; original
	move.l	d0,d4			; present
	move.l	d1,d5			; needed
	beq.w	.bad
	cmp.l	d4,d5
	bls.w	.bad
	cmp.l	#256,d5
	bhi.w	.bad
	jsr	g2asset_bounds
	move.l	d0,d6			; original length
	move.l	d4,d0
	lsl.l	#2,d0
	add.l	#an_size,d0		; first byte after the original table
	cmp.l	d0,d6
	bls.w	.bad
	move.l	d5,d3
	sub.l	d4,d3
	lsl.l	#2,d3			; bytes added to the table
	move.l	d6,d0
	add.l	d3,d0
	moveq	#1,d1			; any memory, like loadfile
	lea	g2legacy_actor_label,a0
	jsr	allocmem_
	tst.l	d0
	beq.w	.bad
	move.l	d0,a3			; copy
	; header: frames/rotations describe the extended table
	move.l	4(a2),4(a3)		; an_maxw, an_maxh
	move.l	an_pal(a2),d0
	add.l	d3,d0
	move.l	d0,an_pal(a3)
	moveq	#0,d2
	move.w	an_rotshft(a2),d2
	moveq	#1,d0
	lsl.l	d2,d0
	subq.l	#1,d0
	and.l	d5,d0
	beq.s	.rot_ok
	moveq	#0,d2			; needed count is not whole frames
.rot_ok
	move.w	d2,an_rotshft(a3)
	move.l	d5,d0
	lsr.l	d2,d0
	move.w	d0,an_frames(a3)
	; existing entries, moved behind the longer table
	lea	an_size(a2),a0
	lea	an_size(a3),a1
	move.l	d4,d7
.table
	move.l	(a0)+,d0
	add.l	d3,d0
	move.l	d0,(a1)+
	subq.l	#1,d7
	bne.s	.table
	; missing entries: same facing of the last frame that has it
	lea	an_size(a3),a4
	move.l	d4,d7
.alias
	move.l	d7,d0
.down
	subq.l	#8,d0
	bmi.s	.last
	cmp.l	d4,d0
	bhs.s	.down
	bra.s	.found
.last
	move.l	d4,d0
	subq.l	#1,d0
.found
	move.l	0(a4,d0.l*4),(a1)+
	addq.l	#1,d7
	cmp.l	d5,d7
	blo.s	.alias
	; shapes and palette, byte for byte
	move.l	d4,d0
	lsl.l	#2,d0
	add.l	#an_size,d0
	lea	0(a2,d0.l),a0
	move.l	d6,d1
	sub.l	d0,d1
.body
	move.b	(a0)+,(a1)+
	subq.l	#1,d1
	bne.s	.body
	move.l	a3,a0
	jsr	g2validate_anim
	tst.l	d0
	bne.s	.undo
	move.l	a2,a1
	jsr	freemem_
	move.l	a3,d0
	bra.s	.done
.undo
	move.l	a3,a1
	jsr	freemem_
.bad
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

g2legacy_actor_label	dc.b	'Gloom3/ZM monster',0
	even
