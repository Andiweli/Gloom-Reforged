; Cold bounds for the embedded player. Its relocation
; reads are reconstructed from source/medplay, file offsets from Kinnunen's
; MMD format revision 6. Consumer checks below cover concrete playback hazards;
; this is not a proof of every reachable effect/alias state (see audit report).
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
	cmp.l #$4d4d4431,d0
	beq.s .song
	cmp.l #$4d434e31,d0
	bne.w g2med_check_bad	; this binary's tick only consumes four-byte MMD1 cells
.song
	tst.b 42(a2)	; Start writes only pblock's low byte; high byte is read later
	bne.w g2med_check_bad
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
	bmi.w g2med_check_bad	; no synth/hybrid branch in this binary's PlayNote
	cmp.w #6,d0
	bhi.w g2med_check_bad	; no 16-bit/stereo decoder; only raw/multi-octave types
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
	tst.w 4(a5)
	bne.s .octave_dma
	bsr.w g2med_check_raw_dma
	bra.w .next_sample
.octave_dma
	bsr.w g2med_check_octave_dma
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
	bsr.w g2med_check_consumers
	move.l 32(a2),d0
	beq.w .header_ready
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
	moveq #0,d2
	move.w 10(a5),d2
	cmp.w #3,d2
	bls.s .next_module
	moveq #0,d1
	move.w 8(a5),d1
.finetune
	move.b 3(a0),d0
	addq.b #8,d0
	cmp.b #15,d0
	bhi.w g2med_check_bad	; signed -8..7 indexes sixteen period-table pointers
	adda.w d2,a0
	subq.w #1,d1
	bne.s .finetune
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
.header_ready
	bsr.w g2med_check_aliases
	bsr.w g2med_check_breaks
	move.l 32(a2),d0
	beq.w .valid
	move.l a6,a5
	adda.l d0,a5
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

; Bound pointer relocation writes against their actual consumers. Metadata
; regions must not overlap; read-only sample sharing remains legal. Shared
; blocks with NULL info remain legal, while repeated relocation of non-NULL
; info pointers is unsafe. Checks are local to each validated header; cross-
; header ownership/aliasing is explicitly not certified by this routine.
g2med_check_aliases
	movem.l d0-d7/a0-a5,-(a7)
	lea g2med_alias_regions,a4
	move.l a2,(a4)+
	move.l #52,(a4)+
	move.l a3,(a4)+
	move.l #788,(a4)+
	move.l 16(a2),d0
	add.l a6,d0
	move.l d0,(a4)+
	moveq #0,d0
	move.w 504(a3),d0
	lsl.l #2,d0
	move.l d0,(a4)+
	move.l 24(a2),d0
	moveq #0,d1
	tst.l d0
	beq.s .sample_region
	add.l a6,d0
	move.b 787(a3),d1
	lsl.l #2,d1
.sample_region
	move.l d0,(a4)+
	move.l d1,(a4)+
	move.l 32(a2),d0
	moveq #0,d1
	tst.l d0
	beq.s .exp_region
	add.l a6,d0
	moveq #56,d1
.exp_region
	move.l d0,(a4)+
	move.l d1,(a4)+
	lea g2med_alias_regions,a5
	moveq #4,d5
.major
	move.l (a5),d0
	move.l 4(a5),d1
	bsr.w g2med_alias_no_major
	addq.l #8,a5
	dbf d5,.major
	move.l 16(a2),a4
	adda.l a6,a4
	moveq #0,d5
	move.w 504(a3),d5
	suba.l a5,a5
.block
	move.l (a4)+,d4
	add.l a6,d4
	move.l d4,a0
	moveq #0,d1
	move.w 2(a0),d1
	addq.l #1,d1
	mulu.w (a0),d1
	lsl.l #2,d1
	addq.l #8,d1
	move.l d4,d0
	bsr.w g2med_alias_no_major
	bsr.w g2med_alias_no_writes
	move.l 4(a0),d0
	beq.w .next_block
	add.l a6,d0
	moveq #8,d1
	bsr.w g2med_alias_no_major
	bsr.w g2med_alias_no_blocks
	; The same block header/nonnull info cannot be relocated twice. Likewise
	; overlapping info records with any nonzero pointer would be mutated twice.
	move.l d0,a0
	move.l 16(a2),a1
	adda.l a6,a1
.previous
	lea -4(a4),a5
	cmp.l a5,a1
	beq.s .info_done
	move.l (a1)+,d2
	add.l a6,d2
	cmp.l d4,d2
	beq.w g2med_check_bad
	move.l d2,a5
	move.l 4(a5),d2
	beq.s .previous
	add.l a6,d2
	move.l d2,a5
	move.l d2,d3
	addq.l #8,d3
	cmp.l d3,d0
	bcc.s .previous
	move.l d0,d3
	addq.l #8,d3
	cmp.l d3,d2
	bcc.s .previous
	tst.l (a0)
	bne.w g2med_check_bad
	tst.l 4(a0)
	bne.w g2med_check_bad
	tst.l (a5)
	bne.w g2med_check_bad
	tst.l 4(a5)
	bne.w g2med_check_bad
	bra.s .previous
.info_done
	suba.l a5,a5
.next_block
	subq.w #1,d5
	bne.w .block
	move.l 24(a2),d0
	beq.s .extension
	move.l a6,a4
	adda.l d0,a4
	moveq #0,d5
	move.b 787(a3),d5
.sample
	move.l (a4)+,d0
	beq.s .next_sample
	add.l a6,d0
	move.l d0,a0
	move.l (a0),d1
	addq.l #6,d1
	moveq #-1,d4
	bsr.w g2med_alias_no_major
	bsr.w g2med_alias_no_writes
.next_sample
	subq.w #1,d5
	bne.s .sample
.extension
	move.l 32(a2),d0
	beq.s .done
	move.l a6,a0
	adda.l d0,a0
	move.l 4(a0),d0
	beq.s .done
	moveq #0,d1
	move.w 8(a0),d1
	beq.s .done
	mulu.w 10(a0),d1
	add.l a6,d0
	moveq #-1,d4
	bsr.w g2med_alias_no_major
	bsr.w g2med_alias_no_writes
.done
	movem.l (a7)+,d0-d7/a0-a5
	rts

g2med_alias_no_major ; d0=start,d1=size,a5=own descriptor or NULL
	movem.l d1-d3/a0,-(a7)
	tst.l d1
	beq.s .done
	move.l d0,d3
	add.l d1,d3
	lea g2med_alias_regions,a0
	moveq #4,d2
.region
	cmp.l a5,a0
	beq.s .next
	tst.l 4(a0)
	beq.s .next
	cmp.l (a0),d3
	bls.s .next
	move.l (a0),d1
	add.l 4(a0),d1
	cmp.l d1,d0
	bcs.w g2med_check_bad
.next
	addq.l #8,a0
	dbf d2,.region
.done
	movem.l (a7)+,d1-d3/a0
	rts

g2med_alias_no_blocks ; d0=start,d1=size; info may not overlay block data
	movem.l d1-d3/a0-a1,-(a7)
	move.l d0,d3
	add.l d1,d3
	move.l 16(a2),a0
	adda.l a6,a0
	move.w 504(a3),d2
.block
	move.l (a0)+,d1
	add.l a6,d1
	cmp.l d3,d1
	bcc.s .next
	move.l d1,a1
	moveq #0,d1
	move.w 2(a1),d1
	addq.l #1,d1
	mulu.w (a1),d1
	lsl.l #2,d1
	addq.l #8,d1
	add.l a1,d1
	cmp.l d1,d0
	bcs.w g2med_check_bad
.next
	subq.w #1,d2
	bne.s .block
	movem.l (a7)+,d1-d3/a0-a1
	rts

g2med_alias_no_writes ; d0=start,d1=size,d4=own block header or -1
	movem.l d1-d3/d5/a0-a1,-(a7)
	move.l d0,d3
	add.l d1,d3
	move.l 16(a2),a0
	adda.l a6,a0
	move.w 504(a3),d2
.block
	move.l (a0)+,d1
	add.l a6,d1
	move.l d1,a1
	tst.l 4(a1)
	beq.s .next
	cmp.l d4,d1
	beq.s .info
	addq.l #4,d1
	bsr.s .slot
.info
	move.l 4(a1),d1
	add.l a6,d1
	move.l d1,a1
	tst.l (a1)
	beq.s .second
	bsr.s .slot
.second
	tst.l 4(a1)
	beq.s .next
	move.l a1,d1
	addq.l #4,d1
	bsr.s .slot
.next
	subq.w #1,d2
	bne.s .block
	movem.l (a7)+,d1-d3/d5/a0-a1
	rts
.slot
	cmp.l d3,d1
	bcc.s .return
	move.l d1,d5
	addq.l #4,d5
	cmp.l d5,d0
	bcs.w g2med_check_bad
.return
	rts
g2med_alias_regions ds.l 10

; The row handler's $1d stores parameter+1 as the pending row. Its final
; lookahead reads that row in the selected successor block before another
; header/row bound is consulted. Check the last effective $1d, preserving
; Bxx ordering, sequence wrapping, repeated blocks and overwritten commands.
; A later nonzero $16 loop can replace the pending row dynamically; those
; states remain explicitly outside this cold proof, rather than guessing.
g2med_check_breaks
	movem.l d0-d7/a0-a5,-(a7)
	lea 508(a3),a4
	moveq #0,d7
.block
	move.l 16(a2),a0
	adda.l a6,a0
	move.l (a0,d7.l*4),a5
	adda.l a6,a5
	moveq #0,d6
.row
	move.l d6,d0
	mulu.w (a5),d0
	lsl.l #2,d0
	lea 8(a5,d0.l),a1
	moveq #-1,d2	; last effective break, or -1
	moveq #-1,d3	; last Bxx sequence, or -1
	moveq #0,d4	; final flag writer: 1=$1d/F00, 2=Bxx
	moveq #0,d5	; immediate previous nonzero $19 (WORD D4 contamination)
	moveq #0,d1
	move.w (a5),d1
	cmp.w #4,d1
	bls.s .channels
	moveq #4,d1	; Start's fixed Paula mask is $000f
.channels
	moveq #0,d0
	move.b 2(a1),d0
	and.w #31,d0
	cmp.w #11,d0
	beq.s .jump
	cmp.w #29,d0
	beq.s .jump
	cmp.w #22,d0
	bne.s .tempo
	tst.b 3(a1)
	beq.s .offset
	moveq #-1,d2	; later loop state not proved by this local check
	bra.s .offset
.tempo
	cmp.w #15,d0
	bne.s .offset
	tst.b 3(a1)
	bne.s .offset
	moveq #1,d4
	bra.s .offset
.jump
	tst.w d5
	bne.w g2med_check_bad	; $19 leaves a nonzero high BYTE in D4
	cmp.w #11,d0
	bne.s .break
	moveq #0,d3
	move.b 3(a1),d3
	moveq #2,d4
	bra.s .offset
.break
	moveq #0,d2
	move.b 3(a1),d2
	moveq #1,d4
.offset
	moveq #0,d5
	cmp.w #25,d0
	bne.s .next_channel
	move.b 3(a1),d5
.next_channel
	addq.l #4,a1
	subq.w #1,d1
	bne.s .channels
	tst.w d2
	bmi.s .next_row
	moveq #0,d5
.sequence
	moveq #0,d0
	move.b (a4,d5.w),d0
	cmp.w d7,d0
	bne.s .next_sequence	; do not constrain unplayed blocks
	move.w d3,d0
	bpl.s .have_sequence
	move.w d5,d0
.have_sequence
	cmp.w #2,d4
	beq.s .target
	addq.w #1,d0
	cmp.w 506(a3),d0
	bcs.s .target
	moveq #0,d0
.target
	move.b (a4,d0.w),d0
	and.w #255,d0
	move.l 16(a2),a0
	adda.l a6,a0
	move.l (a0,d0.w*4),a0
	adda.l a6,a0
	cmp.w 2(a0),d2
	bhi.w g2med_check_bad
.next_sequence
	addq.w #1,d5
	cmp.w 506(a3),d5
	bcs.s .sequence
.next_row
	addq.w #1,d6
	cmp.w 2(a5),d6
	bls.w .row
	addq.l #1,d7
	moveq #0,d0
	move.w 504(a3),d0
	cmp.l d0,d7
	bcs.w .block
	movem.l (a7)+,d0-d7/a0-a5
	rts

; The handler at medplay file $40e reads MMD1 rows with WORD row*4,
; masks instruments to six bits and effects to five bits. Check the actual
; consumer indices before relocation, without work in the audio interrupt.
g2med_check_consumers
	movem.l d0-d5/a0-a5,-(a7)
	moveq #0,d0
	move.w 764(a3),d0
	beq.w g2med_check_bad	; tempo zero indexes before the timer table/divides by zero
	btst #5,768(a3)
	beq.s .tempo_ok
	moveq #0,d1
	move.b 768(a3),d1
	and.w #31,d1
	addq.w #1,d1
	mulu.w d1,d0
	tst.w d0	; the player's BPM DIVU divisor is the low WORD of this product
	beq.w g2med_check_bad
.tempo_ok
	moveq #0,d3
	move.b 787(a3),d3
	moveq #0,d4
	move.w 504(a3),d4
	move.l 16(a2),a4
	adda.l a6,a4
.block
	move.l (a4)+,a5
	adda.l a6,a5
	moveq #0,d5
	move.w 2(a5),d5
	cmp.w #16383,d5
	bhi.w g2med_check_bad
	addq.l #1,d5
	moveq #0,d0
	move.w (a5),d0
	mulu.l d0,d5
	lea 8(a5),a1
.cell
	moveq #0,d0
	move.b 1(a1),d0
	and.w #63,d0
	beq.s .effect
	cmp.w d3,d0
	bhi.w g2med_check_bad
	subq.w #1,d0
	lsl.l #2,d0
	move.l 24(a2),d1
	beq.w g2med_check_bad
	move.l a6,a0
	adda.l d1,a0
	tst.l (a0,d0.l)
	beq.w g2med_check_bad
.effect
	move.b 2(a1),d0
	and.b #31,d0
	cmp.b #11,d0
	bne.s .finetune_effect
	moveq #0,d1
	move.b 3(a1),d1
	cmp.w 506(a3),d1
	bcc.w g2med_check_bad	; Bxx may only enter the validated play-sequence prefix
.finetune_effect
	cmp.b #21,d0
	bne.s .next
	move.b 3(a1),d0
	addq.b #8,d0
	cmp.b #15,d0
	bhi.w g2med_check_bad
.next
	addq.l #4,a1
	subq.l #1,d5
	bne.s .cell
	subq.w #1,d4
	bne.w .block
	movem.l (a7)+,d0-d5/a0-a5
	rts

; Raw-sample initial/loop DMA spans, as published at medplay file $3b6..$3e2.
; Paula ignores the address low bit and AUDLEN=0 means 65536 WORDS. Validate
; against the complete owned module, not an invented per-sample fence: the
; original Zombie Massacre medA has an odd-length sample with a loop ending
; one byte beyond that sample, still within the module. Effect-driven offsets
; and multi-octave state need separate analysis (see remaining F004 limits).
g2med_check_raw_dma
	movem.l d0-d5/a0-a1,-(a7)
	move.l a4,d0
	sub.l a6,d0
	sub.l 24(a2),d0
	subq.l #4,d0
	add.l d0,d0	; sample array index *8 = song's instrument record offset
	move.l a3,a1
	adda.l d0,a1
	move.l a5,d4
	sub.l a6,d4
	addq.l #6,d4	; even sample start relative to module
	moveq #0,d5
	move.w 2(a1),d5
	cmp.w #1,d5
	bls.s .no_loop
	add.l d5,d5
	moveq #0,d0
	move.w (a1),d0
	add.l d0,d0
	add.l d4,d0	; loop start
	add.l d0,d5	; loop end
	cmp.l d6,d5
	bhi.w g2med_check_bad
	move.l d5,d1
	sub.l d4,d1
	bra.s .length
.no_loop
	move.l (a5),d1
.length
	lsr.l #1,d1
	and.l #$ffff,d1
	beq.w g2med_check_bad
	add.l d1,d1
	add.l d4,d1
	cmp.l d6,d1
	bhi.w g2med_check_bad
	movem.l (a7)+,d0-d5/a0-a1
	rts

; Multi-octave PlayNote uses a WORD DIVU quotient and WORD shifts, then the
; same DMA publisher as raw samples. Use the unchanged player's actual lookup
; bytes ($2a3/$2a9/$326/$34a), not a guessed format limit. Certify initial and
; loop spans for all six clamped octave choices. Dynamic offsets/retained
; instrument state are separate remaining limits, not claimed by this check.
g2med_check_octave_dma
	movem.l d0-d5/d7/a0-a2,-(a7)
	move.l a4,d0
	sub.l a6,d0
	sub.l 24(a2),d0
	subq.l #4,d0
	add.l d0,d0
	move.l a3,a2
	adda.l d0,a2
	moveq #0,d0
	move.w 4(a5),d0
	lea medplayer+$2a9,a0
	moveq #0,d1
	move.b (a0,d0.w),d1
	move.l (a5),d4
	divu.l d1,d4	; mathematical quotient: prove the player's DIVU.W cannot overflow
	cmp.l #65535,d4
	bhi.w g2med_check_bad
	lea medplayer+$2a3,a0
	moveq #0,d5
	move.b (a0,d0.w),d5
	moveq #5,d7
.octave
	lea medplayer+$326,a0
	moveq #0,d0
	move.b (a0,d5.w),d0
	move.w d4,d1
	lsl.w d0,d1
	and.l #65535,d1
	moveq #0,d2
	move.w (a2),d2
	lsl.w d0,d2
	moveq #0,d3
	move.w 2(a2),d3
	lsl.w d0,d3
	lea medplayer+$34a,a0
	moveq #0,d0
	move.b (a0,d5.w),d0
	mulu.w d4,d0
	add.l a5,d0
	sub.l a6,d0
	addq.l #6,d0	; actual sample start, relative to owned module
	cmp.w #1,d3
	bls.s .initial_end
	add.l d2,d2
	add.l d0,d2	; loop start
	add.l d3,d3
	move.l d2,d1
	and.l #$fffffffe,d1
	add.l d3,d1	; published loop's aligned DMA end
	cmp.l d6,d1
	bhi.w g2med_check_bad
	add.l d2,d3
	move.l d3,d1
	sub.l d0,d1	; initial publication runs to the loop end
.initial_end
	lsr.l #1,d1
	and.l #65535,d1
	beq.w g2med_check_bad	; Paula would interpret zero as 65536 WORDS
	add.l d1,d1
	and.l #$fffffffe,d0
	add.l d0,d1
	cmp.l d6,d1
	bhi.w g2med_check_bad
	addq.w #1,d5
	dbf d7,.octave
	movem.l (a7)+,d0-d5/d7/a0-a2
	rts

; Public Stop($0c) enters code+$50. The embedded FreeTimer leaves its
; ownership byte set after RemICRVector. Redirect Stop and the cold CIA open;
; keep
; all tick/DMA/effect instructions and every benchmark measurement unchanged.
; Fixed offsets/signatures are tied to the unchanged source/medplay INCBIN.
g2med_install_stop
	movem.l d0-d7/a0-a6,-(a7)
	move.l medat,a0
	cmp.w #$4ef9,$50(a0)
	bne.s .original
	cmp.l #g2med_stop_checked,$52(a0)
	beq.s .timer_open
	bra.w .bad
.original
	cmp.l #$48e73f3e,$50(a0)
	bne.w .bad
	cmp.w #$4279,$54(a0)
	bne.w .bad
	move.w #$4ef9,$50(a0)
	move.l #g2med_stop_checked,$52(a0)
.timer_open
	; AllocTimer retries ciab after setting A6 to ciaa.resource. Its second
	; OpenResource must use Exec, never the CIA base left by AddICRVector.
	cmp.w #$4ef9,$e98(a0)
	bne.s .original_open
	cmp.l #g2med_open_cia_checked,$e9a(a0)
	bne.w .bad
	bra.s .done
.original_open
	cmp.l #$4eaefe0e,$e98(a0)
	bne.w .bad
	cmp.w #$23c0,$e9c(a0)
	bne.w .bad
	move.l a0,d0
	add.l #$f5e,d0
	cmp.l $e9e(a0),d0
	bne.w .bad
	move.w #$4ef9,$e98(a0)
	move.l #g2med_open_cia_checked,$e9a(a0)
	move.l #$4e714e71,$e9e(a0)
.done
	; First-note portamento/Ffd can consult the tuning pointer before PlayNote
	; initializes it. Supply the existing finetune-zero table only for NULL
	; Paula pointers, once before Init/Start and any interrupt. Retained nonzero
	; tuning state and the twelve short MIDI records must remain untouched.
	move.l a0,d0
	add.l #$132a,d0
	cmp.l $1c4a(a0),d0
	bne.w .bad
	lea $1218(a0),a1
	moveq #3,d1
.period_pointer
	move.l (a1)+,a2
	tst.l $4e(a2)
	bne.s .period_next
	move.l d0,$4e(a2)
.period_next
	dbf d1,.period_pointer
	jsr flushc	; publish instruction writes on 020/030/040/060, including re-entry
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2med_open_cia_checked
	move.l 4.w,a6
	jsr -498(a6)
	move.l medat,a0
	move.l d0,$f5e(a0)	; original result store and its condition codes
	jmp $ea2(a0)

; Cold Start preflight for the production title/loading entries. A first-row
; note without a new instrument reuses old channel metadata but indexes the
; new sample array. Reject an out-of-range/NULL new sample before the player
; dereferences it. Portamento, hold, Ffd and Ffe do not call PlayNote here.
; This local check does not certify later effect/chain transitions.
; Disable spans preflight AND original Start: otherwise an old IRQ can change
; the instrument after checking, or AddICRVector can dispatch before Start has
; published its state. Balance exactly this call's Disable, including failure.
g2med_start_checked	; a0=module; medat=player; original Start result ABI
	movem.l d0-d7/a0-a6,-(a7)
	move.l 4.w,a6
	jsr -120(a6)
	move.l 32(a7),a2
	move.l medat,a5
	; AllocTimer does not distinguish its own occupied timer on a second Start.
	; An already active restart must release that proven ownership first; the
	; normal stopped-song path makes no additional Stop/RemICRVector call.
	tst.b $f92(a5)
	beq.s .stopped
	move.l a5,a1
	jsr 12(a1)
.stopped
	tst.w $1c6e(a5)
	bne.w .start	; alternate chain selection is outside this local proof
	moveq #0,d6
	cmp.b #'M',(a2)
	bne.s .relocated
	move.l a2,d6
.relocated
	move.l 8(a2),a3
	adda.l d6,a3
	moveq #0,d0
	move.b 508(a3),d0
	move.l 16(a2),a4
	adda.l d6,a4
	move.l (a4,d0.l*4),a4
	adda.l d6,a4
	moveq #0,d0
	move.w (a4),d0
	cmp.w #4,d0
	bls.s .tracks
	moveq #4,d0
.tracks
	addq.l #8,a4
	moveq #0,d1
	move.b 787(a3),d1
	move.l 24(a2),d5
	move.l d5,a2
	adda.l d6,a2
	lea $1218(a5),a5
.channel
	move.l (a5)+,a0
	moveq #0,d2
	move.b 2(a4),d2
	and.w #31,d2
	cmp.w #15,d2
	bne.s .not_special
	cmp.b #$fe,3(a4)
	beq.s .start	; Ffe terminates this row before any later channel
	cmp.b #$fd,3(a4)
	beq.s .next
	cmp.b #$f2,3(a4)
	beq.s .next
.not_special
	cmp.w #3,d2
	beq.s .next
	cmp.w #31,d2
	bne.s .note
	move.b 3(a4),d2
	beq.s .next
	and.w #$f0,d2
	bne.s .next	; delayed retriggers need a separate full tick-state proof
	; Undelayed $1f0x retriggers immediately via $c0c -> PlayNote at tick 0.
.note
	tst.b (a4)
	ble.s .next
	move.b 1(a4),d2
	and.w #63,d2
	bne.s .next
	tst.l $e(a0)
	beq.s .next
	moveq #0,d2
	move.b 1(a0),d2
	cmp.w d1,d2
	bcc.s .bad
	tst.l d5
	beq.s .bad
	tst.l (a2,d2.l*4)
	beq.s .bad
.next
	addq.l #4,a4
	subq.w #1,d0
	bne.s .channel
.start
	movem.l (a7)+,d0-d7/a0-a6
	move.l medat,a1
	jsr 8(a1)
	movem.l d0-d1/a0-a1/a6,-(a7)
	move.l 4.w,a6
	jsr -126(a6)
	movem.l (a7)+,d0-d1/a0-a1/a6
	rts
.bad
	move.l 4.w,a6
	jsr -126(a6)
	jmp g2fatal_abort

g2med_stop_checked
	movem.l d2-d7/a2-a6,-(a7)
	move.l medat,a2
	clr.w $1c72(a2)	; original public Stop's state change
	move.l a2,-(a7)
	jsr $90(a2)	; original internal stop: disable owned timer, stop DMA, remove IRQ
	move.l (a7)+,a2
	clr.b $f92(a2)	; ownership ends only after RemICRVector has returned
	movem.l (a7)+,d2-d7/a2-a6
	rts
g2med_check_sp dc.l 0
g2med_chain_checkpoint dc.l 0
g2med_chain_power dc.l 0
g2med_chain_distance dc.l 0
g2med_exp_pointer_offsets dc.b 0,12,20,32,40,44,52
	even
