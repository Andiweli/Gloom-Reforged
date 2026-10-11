; Cold structural bounds for the embedded MMD0/MMD1 player. Its relocation
; reads are reconstructed from source/medplay, file offsets from Kinnunen's
; MMD format revision 6. This does NOT certify synth command execution/DMA.
; a0=unrelocated registered module; d0=0/-1; all other registers preserved.
g2validate_med
	movem.l d1-d7/a0-a6,-(a7)
	move.l a7,g2med_check_sp
	move.l a0,a6
	jsr g2asset_bounds
	cmp.l #52,d0
	bcs.w g2med_check_bad
	move.l d0,d6
	move.l 4(a6),d0
	cmp.l #52,d0
	bcs.w g2med_check_bad
	cmp.l d6,d0
	bhi.w g2med_check_bad
	move.l d0,d6
	move.l d6,d7
	divu.l #52,d7	; at most this many disjoint module headers can exist
	clr.l g2med_chain_checkpoint
	move.l #1,g2med_chain_power
	clr.l g2med_chain_distance
	moveq #0,d0
.header
	moveq #52,d1
	bsr.w g2med_check_span
	move.l a0,a2
	move.l (a2),d0
	cmp.l #$4d4d4430,d0
	beq.s .song
	cmp.l #$4d4d4431,d0
	beq.s .song
	cmp.l #$4d434e30,d0	; subsequent multi-module headers
	beq.s .song
	cmp.l #$4d434e31,d0
	bne.w g2med_check_bad	; player only distinguishes MMD1 from MMD0
.song
	move.l 8(a2),d0
	move.l #788,d1
	bsr.w g2med_check_required
	move.l a0,a3
	moveq #0,d4
	move.w 504(a3),d4
	beq.w g2med_check_bad
	; Player's SUBQ.B before DBF fails for a zero low byte (e.g. 256).
	tst.b d4
	beq.w g2med_check_bad
	moveq #0,d5
	move.w 506(a3),d5
	beq.w g2med_check_bad
	cmp.w #256,d5
	bhi.w g2med_check_bad
	lea 508(a3),a0
.sequence
	moveq #0,d0
	move.b (a0)+,d0
	cmp.l d4,d0
	bcc.w g2med_check_bad
	subq.w #1,d5
	bne.s .sequence
	move.l 16(a2),d0
	move.l d4,d1
	lsl.l #2,d1
	bsr.w g2med_check_required
	move.l a0,a4
.block
	move.l (a4)+,d0
	moveq #2,d1
	cmp.b #'1',3(a2)
	bne.s .block_header
	moveq #8,d1
.block_header
	bsr.w g2med_check_required
	move.l a0,a5
	moveq #0,d0
	moveq #0,d1
	cmp.b #'1',3(a2)
	beq.s .block1
	move.b (a5),d0
	move.b 1(a5),d1
	addq.l #1,d1
	mulu.l d0,d1
	move.l d1,d0
	add.l d1,d1
	add.l d0,d1
	addq.l #2,d1
	bra.s .block_extent
.block1
	move.w (a5),d0
	move.w 2(a5),d1
	addq.l #1,d1
	mulu.l d0,d1
	lsl.l #2,d1
	addq.l #8,d1
.block_extent
	; 16 tracks match the player's fixed sixteen channel-state records.
	moveq #0,d0
	move.b (a5),d0
	cmp.b #'1',3(a2)
	bne.s .tracks
	move.w (a5),d0
.tracks
	tst.w d0
	beq.w g2med_check_bad
	cmp.w #16,d0
	bhi.w g2med_check_bad
	move.l a5,d0
	sub.l a6,d0
	bsr.w g2med_check_span
	cmp.b #'1',3(a2)
	bne.s .next_block
	move.l 4(a5),d0
	beq.s .next_block
	moveq #8,d1	; player's relocation reads the first two info pointers
	bsr.w g2med_check_span
	move.l (a0),d0
	moveq #4,d1
	bsr.w g2med_check_optional
	move.l 4(a5),d0
	moveq #8,d1
	bsr.w g2med_check_span
	move.l 4(a0),d0
	moveq #1,d1
	bsr.w g2med_check_optional
.next_block
	subq.w #1,d4
	bne.w .block
	moveq #0,d4
	move.b 787(a3),d4
	cmp.w #63,d4
	bhi.w g2med_check_bad
	move.l 24(a2),d0
	beq.w .expansion
	tst.w d4
	beq.w g2med_check_bad	; zero otherwise becomes DBF 255 in relocation
	move.l d4,d1
	lsl.l #2,d1
	bsr.w g2med_check_span
	move.l a0,a4
.sample
	move.l (a4)+,d0
	beq.w .next_sample
	moveq #6,d1
	bsr.w g2med_check_span
	move.l a0,a5
	move.w 4(a5),d0
	bmi.s .synth
	move.l (a5),d1
	tst.l d1
	bmi.w g2med_check_bad
	btst #5,d0
	beq.s .sample_bytes
	add.l d1,d1
	bcs.w g2med_check_bad
.sample_bytes
	addq.l #6,d1
	bcs.w g2med_check_bad
	move.l a5,d0
	sub.l a6,d0
	bsr.w g2med_check_span
	bra.w .next_sample
.synth
	cmp.w #-2,d0
	bcs.w g2med_check_bad
	move.l a5,d0
	sub.l a6,d0
	move.l #278,d1
	bsr.w g2med_check_span
	cmp.w #128,14(a5)
	bhi.w g2med_check_bad
	cmp.w #128,16(a5)
	bhi.w g2med_check_bad
	moveq #0,d5
	move.w 20(a5),d5
	beq.w g2med_check_bad
	cmp.w #64,d5
	bhi.w g2med_check_bad
	move.l d5,d1
	lsl.l #2,d1
	add.l #278,d1
	bsr.w g2med_check_span
	lea 278(a5),a1
.wave
	move.l (a1)+,d0
	add.l a5,d0
	bcs.w g2med_check_bad
	sub.l a6,d0
	moveq #2,d1
	bsr.w g2med_check_span
	moveq #0,d1
	move.w (a0),d1
	add.l d1,d1
	addq.l #2,d1
	; Hybrid wf[0] has an ordinary six-byte sample header.
	cmp.w #-2,4(a5)
	bne.s .wave_extent
	; The first entry is identified from the actual table cursor.
	move.l a1,d0
	sub.l a5,d0
	cmp.l #282,d0
	bne.s .wave_extent
	move.l a0,d0
	sub.l a6,d0
	moveq #6,d1
	bsr.w g2med_check_span
	move.l (a0),d1
	addq.l #6,d1
	bcs.w g2med_check_bad
.wave_extent
	move.l a0,d0
	sub.l a6,d0
	bsr.w g2med_check_span
	subq.w #1,d5
	bne.s .wave
.next_sample
	subq.w #1,d4
	bne.w .sample
.expansion
	move.l 32(a2),d0
	beq.w .valid
	moveq #56,d1	; last field read by this embedded player's relocator
	bsr.w g2med_check_span
	move.l a0,a5
	move.l 4(a5),d0
	beq.s .next_module
	moveq #0,d1
	move.w 8(a5),d1
	beq.s .next_module	; empty extension array is not read by the player
	cmp.w #63,d1
	bhi.w g2med_check_bad	; player stores hold/decay/finetune in 63-entry arrays
	moveq #0,d2
	move.w 10(a5),d2
	cmp.w #2,d2
	bcs.w g2med_check_bad
	cmp.w #32767,d2
	bhi.w g2med_check_bad	; ADDA.W signed entry stride
	mulu.l d2,d1
	bsr.w g2med_check_span
.next_module
	; All optional pointers touched by relocation must at least belong to input.
	lea g2med_exp_pointer_offsets,a4
	moveq #6,d4
.exp_pointer
	moveq #0,d0
	move.b (a4)+,d0
	move.l (a5,d0.w),d0
	moveq #1,d1
	bsr.w g2med_check_optional
	dbf d4,.exp_pointer
	tst.l 52(a5)
	bne.w g2med_check_bad	; player's MIDI-dump relocator loses nextmod context
	move.l (a5),d0
	beq.w .valid
	; Brent cycle detection: no scratch allocation or assumptions about file
	; ordering. Pointers are fully checked before the next header is read.
	cmp.l g2med_chain_checkpoint,d0
	beq.w g2med_check_bad
	addq.l #1,g2med_chain_distance
	move.l g2med_chain_distance,d1
	cmp.l g2med_chain_power,d1
	bne.s .chain_budget
	move.l d0,g2med_chain_checkpoint
	clr.l g2med_chain_distance
	add.l d1,d1
	move.l d1,g2med_chain_power
.chain_budget
	subq.l #1,d7
	beq.w g2med_check_bad	; cyclic/multiply referenced chains cannot hang load
	bra.w .header
.valid
	moveq #0,d0
	bra.s g2med_check_done
g2med_check_bad
	move.l g2med_check_sp,a7
	moveq #-1,d0
g2med_check_done
	movem.l (a7)+,d1-d7/a0-a6
	rts
g2med_check_optional
	tst.l d0
	beq.s g2med_check_return
	bra.s g2med_check_span
g2med_check_required
	tst.l d0
	beq.w g2med_check_bad
g2med_check_span	; d0=even relative offset, d1=bytes; a0=result
	btst #0,d0
	bne.w g2med_check_bad
	cmp.l d6,d0
	bcc.w g2med_check_bad
	move.l d6,d2
	sub.l d0,d2
	cmp.l d2,d1
	bhi.w g2med_check_bad
	move.l a6,a0
	add.l d0,a0
g2med_check_return
	rts
	even
g2med_check_sp dc.l 0
g2med_chain_checkpoint dc.l 0
g2med_chain_power dc.l 0
g2med_chain_distance dc.l 0
g2med_exp_pointer_offsets dc.b 0,12,20,32,40,44,52
	even
