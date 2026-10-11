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
	bne.w .next_sample
	bsr.w g2med_check_raw_dma
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
	bra.s .bad
.original
	cmp.l #$48e73f3e,$50(a0)
	bne.s .bad
	cmp.w #$4279,$54(a0)
	bne.s .bad
	move.w #$4ef9,$50(a0)
	move.l #g2med_stop_checked,$52(a0)
.timer_open
	; AllocTimer retries ciab after setting A6 to ciaa.resource. Its second
	; OpenResource must use Exec, never the CIA base left by AddICRVector.
	cmp.w #$4ef9,$e98(a0)
	bne.s .original_open
	cmp.l #g2med_open_cia_checked,$e9a(a0)
	bne.s .bad
	bra.s .done
.original_open
	cmp.l #$4eaefe0e,$e98(a0)
	bne.s .bad
	cmp.w #$23c0,$e9c(a0)
	bne.s .bad
	move.l a0,d0
	add.l #$f5e,d0
	cmp.l $e9e(a0),d0
	bne.s .bad
	move.w #$4ef9,$e98(a0)
	move.l #g2med_open_cia_checked,$e9a(a0)
	move.l #$4e714e71,$e9e(a0)
.done
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
