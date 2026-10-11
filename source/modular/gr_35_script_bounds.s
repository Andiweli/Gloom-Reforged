; Script commands are parsed on cold intermission/level transitions only.
; All cursors are bounded by the loader's logical length, never a guessed size.
; read_command: a0=cursor, a1=end; d0=command/-1, a0=parameter,
; a1=parameter end, a2=next line. Other registers preserved.
g2script_read_command
	movem.l d1-d7/a3-a6,-(a7)
	move.l a0,a3
	move.l a1,a4
.line
	cmp.l a4,a3
	bcc.w .bad
	moveq #0,d1
	move.b (a3),d1
	cmp.b #10,d1
	beq.w .blank
	cmp.b #13,d1
	beq.w .blank
	and.w #31,d1
	beq.s .skip
	cmp.w #27,d1
	bcc.s .skip
	move.l a4,d1
	sub.l a3,d1
	cmp.l #5,d1
	bcs.w .bad
	moveq #0,d0
	moveq #3,d2
.letters
	moveq #0,d1
	move.b (a3)+,d1
	and.w #31,d1
	beq.w .bad
	cmp.w #26,d1
	bhi.w .bad
	add.w #96,d1
	lsl.l #8,d0
	or.w d1,d0
	dbf d2,.letters
	cmp.b #'_',(a3)+
	bne.w .bad
	move.l a3,a0
.parameter
	cmp.l a4,a3
	bcc.s .end_parameter
	move.b (a3),d1
	beq.w .bad
	cmp.b #10,d1
	beq.s .end_parameter
	cmp.b #13,d1
	beq.s .end_parameter
	addq.l #1,a3
	bra.s .parameter
.end_parameter
	move.l a3,a1
	move.l a3,a2
	cmp.l a4,a2
	bcc.s .return
	move.b (a2)+,d1
	cmp.b #13,d1
	bne.s .return
	cmp.l a4,a2
	bcc.s .return
	cmp.b #10,(a2)
	bne.s .return
	addq.l #1,a2
	bra.s .return
.skip
	cmp.l a4,a3
	bcc.s .bad
	move.b (a3)+,d1
	cmp.b #10,d1
	beq.w .line
	cmp.b #13,d1
	beq.w .line
	bra.s .skip
.blank
	addq.l #1,a3
	bra.w .line
.bad
	moveq #-1,d0
.return
	movem.l (a7)+,d1-d7/a3-a6
	rts

g2validate_script
	movem.l d1-d7/a0-a6,-(a7)
	jsr g2asset_bounds
	tst.l d0
	beq.w .bad
	move.l a1,a6
	moveq #0,d7
.command
	move.l a6,a1
	jsr g2script_read_command
	cmp.l #-1,d0
	beq.w .bad
	move.l a1,d1
	sub.l a0,d1
	cmp.l #'done',d0
	beq.w .valid
	cmp.l #'loop',d0
	beq.w .loop
	cmp.l #'text',d0
	beq.s .text
	cmp.l #'play',d0
	beq.w .play
	cmp.l #'tile',d0
	beq.w .tile
	cmp.l #'pict',d0
	beq.w .pict
	cmp.l #'rest',d0
	beq.w .next
	cmp.l #'wait',d0
	beq.s .wait
	cmp.l #'draw',d0
	beq.s .empty
	cmp.l #'dark',d0
	beq.s .empty
	cmp.l #'show',d0
	beq.s .empty
	cmp.l #'hide',d0
	bne.s .bad
.empty
	tst.l d1
	bne.s .bad
	bra.s .next
.wait
	moveq #-1,d7
	bra.s .empty
.text
	cmp.l #pic_pal-text-1,d1	; actual shared text buffer, including NUL
	bhi.s .bad
	jsr g2validate_text_layout
	tst.l d0
	bne.w .bad
	move.l a0,a3
.text_glyph
	cmp.l a1,a3
	bcc.s .next
	moveq #0,d2
	move.b (a3)+,d2
	cmp.b #127,d2	; explicitly mapped cursor glyph 39
	beq.s .text_glyph
	and.w #31,d2
	cmp.w #31,d2	; printmess2 would index glyph 40 outside Bigfont2
	beq.s .bad
	bra.s .text_glyph
.play
	moveq #-1,d7
	tst.l d1
	beq.s .bad
	cmp.l #64-1,d1	; mapname DS.B 64
	bhi.s .bad
	bra.s .next
.tile
	cmp.l #g2floor_tag_end-floortag-1,d1
	bhi.s .bad
	bra.s .next
.pict
	cmp.l #pic_pal-picname-9-5,d1	; longest prefix pics_ehb/ plus .pal and NUL
	bhi.s .bad
.next
	move.l a2,a0
	bra.w .command
.loop
	tst.l d1
	bne.s .bad
	tst.l d7	; a loop with neither a level nor a wait can never yield
	beq.s .bad
.valid
	moveq #0,d0
	bra.s .return
.bad
	moveq #-1,d0
.return
	movem.l (a7)+,d1-d7/a0-a6
	rts

g2require_script
	movem.l d0-d7/a0-a6,-(a7)
	jsr g2validate_script
	tst.l d0
	bne.s .bad
	clr.w g2script_yielded
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2script_next_command
	movem.l d1-d7/a1-a6,-(a7)
	move.l script,a0
	jsr g2asset_bounds
	move.l scriptat,a0
	cmp.l script,a0
	bcs.s .bad
	jsr g2script_read_command
	cmp.l #-1,d0
	beq.s .bad
	move.l a1,g2script_parameter_end
	move.l a2,g2script_nextline
	move.l a0,scriptat
	movem.l (a7)+,d1-d7/a1-a6
	rts
.bad
	jmp g2fatal_abort

g2script_fetchrest
	movem.l d1/a2,-(a7)
	move.l scriptat,a0
	move.l g2script_parameter_end,d0
	sub.l a0,d0
	bmi.l g2fatal_abort
	move.l a1,d1
	lea pic_pal,a2
	cmp.l #text,d1
	beq.s .capacity
	lea g2map_name_end,a2
	cmp.l #mapname,d1
	beq.s .capacity
	lea g2floor_tag_end,a2
	cmp.l #floortag,d1
	beq.s .capacity
	cmp.l #picname,d1
	bcs.l g2fatal_abort
	lea pic_pal-4,a2	; leave room for .pal appended at the NUL
	cmp.l a2,a1
	bcc.l g2fatal_abort
.capacity
	move.l a2,d1
	sub.l a1,d1
	cmp.l d1,d0
	bcc.l g2fatal_abort
	move.l d0,d1
	beq.s .nul
.copy
	move.b (a0)+,(a1)+
	subq.l #1,d1
	bne.s .copy
.nul
	clr.b (a1)
	move.l g2script_nextline,scriptat
	movem.l (a7)+,d1/a2
	rts
	cnop 0,4
g2script_parameter_end dc.l 0
g2script_nextline dc.l 0
g2script_yielded dc.w 0

; Reconstruct g2v14_wrap_script_text before executing text_ or the blitter.
; The native bitmap is 320x240, Bigfont spacing is 8 pixels, baseline 240-18,
; and each explicit separator moves the baseline up 11 pixels.
g2validate_text_layout	; a0=parameter start, a1=end; d0=0/-1
	movem.l d1-d6/a0-a2,-(a7)
	move.l a0,a2
	move.l a1,d1
	sub.l a0,d1
	moveq #0,d2	; current explicit line length
	moveq #0,d3	; separator count
.scan
	cmp.l a1,a2
	bcc.s .scanned
	cmp.b #'\',(a2)+
	beq.s .separator
	addq.w #1,d2
	bra.s .scan
.separator
	cmp.w #320/8,d2
	bhi.w .bad
	moveq #0,d2
	addq.w #1,d3
	cmp.w #(240-18)/11,d3
	bhi.w .bad
	bra.s .scan
.scanned
	tst.w d3
	beq.s .automatic
	cmp.w #320/8,d2
	bhi.s .bad
	bra.s .valid
.automatic
	cmp.w #38,d1
	bls.s .valid
	move.l d1,d4
	lsr.w #1,d4	; same visual midpoint and closest blank as original wrapper
	moveq #-1,d2
	move.w #32767,d5
	moveq #8,d3
.blank
	cmp.w #38,d3
	bhi.s .split
	cmp.l d1,d3
	bcc.s .split
	cmp.b #' ',(a0,d3.w)
	bne.s .next
	move.w d3,d6
	sub.w d4,d6
	bpl.s .distance
	neg.w d6
.distance
	cmp.w d5,d6
	bge.s .next
	move.w d6,d5
	move.w d3,d2
.next
	addq.w #1,d3
	bra.s .blank
.split
	tst.w d2
	bpl.s .chosen
	moveq #38,d2
.chosen
	sub.w d2,d1
	subq.w #1,d1
	cmp.w #320/8,d1
	bhi.s .bad
.valid
	moveq #0,d0
	bra.s .done
.bad
	moveq #-1,d0
.done
	movem.l (a7)+,d1-d6/a0-a2
	rts
