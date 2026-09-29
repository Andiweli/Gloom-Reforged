; Gloom Reforged 2.1 - wall Bayer precomputation, performance trial 1.
; Appended at EOF: large storage must not extend existing PC-relative spans.
;
; Exact table: byte threshold[shade 0..13][scaled distance 0..maxz-1].
; First matching probe wins, with the original unsigned comparison and clamp.
; No monotonicity assumption. No palette pointers/colours are cached.
; initdarktable is the sole darktable writer in this source and calls this
; builder after its final store. DEFAULT/ADVANCED scale distance at runtime;
; Bayer OFF and shade >=14 bypass the lookup exactly as before.
; Static storage follows the existing program data convention. No new heap
; allocation or cleanup path. 14*2048 + 14*4 = 28728 bytes of table storage.
;
; Preserves every used register. Invoked during initialization, not rendering.
g2wall_bayer_build
	movem.l	d0-d7/a0-a2,-(a7)
	move.l	darktable,a0
	lea	g2wall_bayer_table,a1
	moveq	#0,d5
.shade
	moveq	#0,d6
.distance
	moveq	#15,d7
	move	d6,d4
	add	#24,d4
	cmp	#maxz-1,d4
	bls.s	.probe0
	move	#maxz-1,d4
.probe0
	move	0(a0,d4.w*2),d0
	cmp	d5,d0
	bhi.w	.store
	moveq	#11,d7
	move	d6,d4
	add	#48,d4
	cmp	#maxz-1,d4
	bls.s	.probe1
	move	#maxz-1,d4
.probe1
	move	0(a0,d4.w*2),d0
	cmp	d5,d0
	bhi.w	.store
	moveq	#7,d7
	move	d6,d4
	add	#72,d4
	cmp	#maxz-1,d4
	bls.s	.probe2
	move	#maxz-1,d4
.probe2
	move	0(a0,d4.w*2),d0
	cmp	d5,d0
	bhi.w	.store
	moveq	#4,d7
	move	d6,d4
	add	#96,d4
	cmp	#maxz-1,d4
	bls.s	.probe3
	move	#maxz-1,d4
.probe3
	move	0(a0,d4.w*2),d0
	cmp	d5,d0
	bhi.w	.store
	moveq	#2,d7
	move	d6,d4
	add	#112,d4
	cmp	#maxz-1,d4
	bls.s	.probe4
	move	#maxz-1,d4
.probe4
	move	0(a0,d4.w*2),d0
	cmp	d5,d0
	bhi.w	.store
	moveq	#1,d7
	move	d6,d4
	add	#128,d4
	cmp	#maxz-1,d4
	bls.s	.probe5
	move	#maxz-1,d4
.probe5
	move	0(a0,d4.w*2),d0
	cmp	d5,d0
	bhi.w	.store
	moveq	#0,d7
.store
	move.b	d7,(a1)+
	addq	#1,d6
	cmp	#maxz,d6
	blo.w	.distance
	addq	#1,d5
	cmp	#14,d5
	blo.w	.shade
	movem.l	(a7)+,d0-d7/a0-a2
	rts

	even
g2wall_bayer_rows
	dc.l	g2wall_bayer_table+0*maxz
	dc.l	g2wall_bayer_table+1*maxz
	dc.l	g2wall_bayer_table+2*maxz
	dc.l	g2wall_bayer_table+3*maxz
	dc.l	g2wall_bayer_table+4*maxz
	dc.l	g2wall_bayer_table+5*maxz
	dc.l	g2wall_bayer_table+6*maxz
	dc.l	g2wall_bayer_table+7*maxz
	dc.l	g2wall_bayer_table+8*maxz
	dc.l	g2wall_bayer_table+9*maxz
	dc.l	g2wall_bayer_table+10*maxz
	dc.l	g2wall_bayer_table+11*maxz
	dc.l	g2wall_bayer_table+12*maxz
	dc.l	g2wall_bayer_table+13*maxz
g2wall_bayer_table
	ds.b	14*maxz
	even
