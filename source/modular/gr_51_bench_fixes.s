; =============================================================================
; 2.5.0: GloomBench-only fix. Included by GloomBench.s only.
;
; optoff with DISPLAY=P96 and no glyph cache: the legacy blitter path read a
; null strip and wrote into a null menubmap (same latent fault as the game,
; fixed there in gr_46). g2bench_optoff_guard skips that path. The hook in
; GloomBench.s is a same-size exchange; every existing label keeps its
; address in the FAST and BASE builds.
; =============================================================================

; Replaces BSR ownblitter + MOVE curropt(pc),d6 on the legacy optoff path.
; Owns the blitter and loads d6 = curropt when a strip and a planar page
; exist; otherwise finishes optoff like its end and returns to its caller.
g2bench_optoff_guard
	cmp	#2,g2display_mode
	beq.s	.skip
	tst.l	menubmap
	beq.s	.skip
	move	curropt,d6
	lea	menustrips,a0
	tst.l	4(a0,d6.w*8)
	beq.s	.skip
	jsr	ownblitter
	move	curropt,d6
	rts
.skip
	addq.l	#4,a7			; return directly to optoff's caller
	move	#13,flashdelay
	clr	p96menu_native_selected
	jsr	g2p96_menu_current_row_present
	rts
