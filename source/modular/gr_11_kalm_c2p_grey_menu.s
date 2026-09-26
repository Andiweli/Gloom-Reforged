; ===========================================================================
; c87b37 embedded Kalm C2P implementations (Public Domain)
; Source: https://github.com/Kalmalyzer/kalms-c2p
; Local symbols are prefixed g2k_; fixed GEN plane span is 9600 bytes.
; ===========================================================================

; ---- Embedded Public Domain Kalm routine: c2p1x1_8_c5_gen.s ----
;
; 1999-01-08
;
; g2k_c2p1x1_8_c5_gen
;
; 1.38vbl [all dma off] on Blizzard 1230-IV@50MHz
;



; d0.w	chunkyx [chunky-pixels]
; d1.w	chunkyy [chunky-pixels]
; d2.w	(scroffsx) [screen-pixels]
; d3.w	scroffsy [screen-pixels]
; d4.w	(rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l	(bplsize) [bytes] -- offset between one row in one bpl and the next bpl

g2k_c2p1x1_8_c5_gen_init
	movem.l	d2-d3,-(sp)
	andi.l	#$ffff,d0
	mulu.w	d0,d3
	lsr.l	#3,d3
	move.l	d3,g2k_c2p1x1_8_c5_gen_scroffs
	mulu.w	d0,d1
	move.l	d1,g2k_c2p1x1_8_c5_gen_pixels
	movem.l	(sp)+,d2-d3
	rts

; a0	c2pscreen
; a1	bitplanes

g2k_c2p1x1_8_c5_gen
	movem.l	d2-d7/a2-a6,-(sp)

	move.l	#$33333333,d5
	move.l	#$55555555,a6

	add.w	#9600,a1
	add.l	g2k_c2p1x1_8_c5_gen_scroffs,a1

	move.l	g2k_c2p1x1_8_c5_gen_pixels,a2
	add.l	a0,a2
	cmp.l	a0,a2
	beq	.none

	movem.l	a0-a1,-(sp)

	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3

	move.l	#$0f0f0f0f,d4		; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsl.l	#4,d0
	lsl.l	#4,d1
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7

	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsl.l	#4,d2
	lsl.l	#4,d3
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3

	move.l	d2,d6			; Swap 2x2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	#$00ff00ff,d4
	move.l	d1,d6			; Swap 8x1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	bra	.start1
.x1
	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3
	move.l	d7,-9600(a1)

	move.l	#$0f0f0f0f,d4		; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsl.l	#4,d0
	lsl.l	#4,d1
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7
	move.l	a3,9600(a1)

	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsl.l	#4,d2
	lsl.l	#4,d3
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3
	move.l	a4,9600*2(a1)

	move.l	d2,d6			; Swap 2x2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	#$00ff00ff,d4
	move.l	d1,d6			; Swap 8x1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	move.l	a5,(a1)+
.start1
	and.l	d4,d6
	and.l	d4,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d1
	eor.l	d7,d3

	move.l	a6,d4
	move.l	d1,d6			; Swap 1x1
	move.l	d3,d7
	lsr.l	#1,d6
	lsr.l	#1,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d4,d6
	and.l	d4,d7
	eor.l	d6,d0
	eor.l	d7,d2
	add.l	d6,d6
	add.l	d7,d7
	eor.l	d1,d6
	eor.l	d3,d7

	move.l	d0,a4
	move.l	d2,a5
	move.l	d6,a3

	cmpa.l	a0,a2
	bne	.x1
	move.l	d7,-9600(a1)
	move.l	a3,9600(a1)
	move.l	a4,9600*2(a1)
	move.l	a5,(a1)+

	movem.l	(sp)+,a0-a1
	add.l	#9600*4,a1

	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3

	move.l	#$f0f0f0f0,d4		; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsr.l	#4,d2
	lsr.l	#4,d3
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7

	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3

	move.l	d2,d6			; Swap 2x2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	#$00ff00ff,d4
	move.l	d1,d6			; Swap 8x1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	bra	.start2
.x2
	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3
	move.l	d7,-9600(a1)

	move.l	#$f0f0f0f0,d4		; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsr.l	#4,d2
	lsr.l	#4,d3
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7
	move.l	a3,9600(a1)

	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3
	move.l	a4,9600*2(a1)

	move.l	d2,d6			; Swap 2x2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	#$00ff00ff,d4
	move.l	d1,d6			; Swap 8x1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	move.l	a5,(a1)+
.start2
	and.l	d4,d6
	and.l	d4,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d1
	eor.l	d7,d3

	move.l	a6,d4
	move.l	d1,d6			; Swap 1x1
	move.l	d3,d7
	lsr.l	#1,d6
	lsr.l	#1,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d4,d6
	and.l	d4,d7
	eor.l	d6,d0
	eor.l	d7,d2
	add.l	d6,d6
	add.l	d7,d7
	eor.l	d1,d6
	eor.l	d3,d7

	move.l	d0,a4
	move.l	d2,a5
	move.l	d6,a3

	cmpa.l	a0,a2
	bne	.x2
	move.l	d7,-9600(a1)
	move.l	a3,9600(a1)
	move.l	a4,9600*2(a1)
	move.l	a5,(a1)+

.none
	movem.l	(sp)+,d2-d7/a2-a6
	rts


g2k_c2p1x1_8_c5_gen_scroffs	ds.l	1
g2k_c2p1x1_8_c5_gen_pixels	ds.l	1

; ---- Embedded Public Domain Kalm routine: c2p1x1_6_c5_gen.s ----

; 060 friendly version
;				modulo	max res	fscreen	compu
; g2k_c2p1x1_6_c5_gen		no	320x256?  no	030



; d0.w	chunkyx [chunky-pixels]
; d1.w	chunkyy [chunky-pixels]
; d2.w	(scroffsx) [screen-pixels]
; d3.w	scroffsy [screen-pixels]
; d4.w	(rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l	(bplsize) [bytes] -- offset between one row in one bpl and the next bpl

g2k_c2p1x1_6_c5_gen_init
	movem.l	d2-d3,-(sp)
	andi.l	#$ffff,d0
	mulu.w	d0,d3
	lsr.l	#3,d3
	move.l	d3,g2k_c2p1x1_6_c5_gen_scroffs
	mulu.w	d0,d1
	move.l	d1,g2k_c2p1x1_6_c5_gen_pixels
	movem.l	(sp)+,d2-d3
	rts

; a0	c2pscreen
; a1	bitplanes

g2k_c2p1x1_6_c5_gen
	movem.l	d2-d7/a2-a6,-(sp)

	move.l	#$33333333,d5
	move.l	#$55555555,a6

	add.w	#9600,a1
	add.l	g2k_c2p1x1_6_c5_gen_scroffs,a1

	move.l	g2k_c2p1x1_6_c5_gen_pixels,a2
	add.l	a0,a2
	cmp.l	a0,a2
	beq	.none

	movem.l	a0-a1,-(sp)

	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3

	move.l	#$0f0f0f0f,d4		; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsl.l	#4,d0
	lsl.l	#4,d1
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7

	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsl.l	#4,d2
	lsl.l	#4,d3
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3

	move.l	d2,d6			; Swap 2x2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	#$00ff00ff,d4
	move.l	d1,d6			; Swap 8x1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	bra	.start1
.x1
	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3
	move.l	d7,-9600(a1)

	move.l	#$0f0f0f0f,d4		; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsl.l	#4,d0
	lsl.l	#4,d1
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7
	move.l	a3,9600(a1)

	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsl.l	#4,d2
	lsl.l	#4,d3
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3
	move.l	a4,9600*2(a1)

	move.l	d2,d6			; Swap 2x2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	#$00ff00ff,d4
	move.l	d1,d6			; Swap 8x1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	move.l	a5,(a1)+
.start1
	and.l	d4,d6
	and.l	d4,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d1
	eor.l	d7,d3

	move.l	a6,d4
	move.l	d1,d6			; Swap 1x1
	move.l	d3,d7
	lsr.l	#1,d6
	lsr.l	#1,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d4,d6
	and.l	d4,d7
	eor.l	d6,d0
	eor.l	d7,d2
	add.l	d6,d6
	add.l	d7,d7
	eor.l	d1,d6
	eor.l	d3,d7

	move.l	d0,a4
	move.l	d2,a5
	move.l	d6,a3

	cmpa.l	a0,a2
	bne	.x1
	move.l	d7,-9600(a1)
	move.l	a3,9600(a1)
	move.l	a4,9600*2(a1)
	move.l	a5,(a1)+

	movem.l	(sp)+,a0-a1
	add.l	#9600*4,a1

	move.l	#$55555555,d5
	move.l	#$30303030,a6

	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3

	move.l	a6,d4			; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsr.l	#4,d2
	lsr.l	#4,d3
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7

	bra.s	.start2
.x2
	move.l	(a0)+,d0
	move.l	(a0)+,d2
	move.l	(a0)+,d1
	move.l	(a0)+,d3
	move.l	d7,-9600(a1)

	move.l	a6,d4			; Merge 4x1, part 1
	and.l	d4,d0
	and.l	d4,d1
	and.l	d4,d2
	and.l	d4,d3
	lsr.l	#4,d2
	lsr.l	#4,d3
	or.l	d2,d0
	or.l	d3,d1

	move.l	(a0)+,d2
	move.l	(a0)+,d6
	move.l	(a0)+,d3
	move.l	(a0)+,d7
	move.l	a3,(a1)+
.start2
	and.l	d4,d2			; Merge 4x1, part 2
	and.l	d4,d6
	and.l	d4,d3
	and.l	d4,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	or.l	d6,d2
	or.l	d7,d3

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3

	lsl.l	#2,d0			; Merge 2x2
	lsl.l	#2,d1
	or.l	d2,d0
	or.l	d3,d1

	move.l	d1,d7			; Swap 8x1
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d1

	move.l	d1,d7			; Swap 1x1
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	d5,d7
	eor.l	d7,d0
	add.l	d7,d7
	eor.l	d1,d7

	move.l	d0,a3

	cmp.l	a0,a2
	bne.s	.x2
	move.l	d7,-9600(a1)
	move.l	a3,(a1)

.none
	movem.l	(sp)+,d2-d7/a2-a6
	rts


g2k_c2p1x1_6_c5_gen_scroffs	ds.l	1
g2k_c2p1x1_6_c5_gen_pixels	ds.l	1

; ---- Embedded Public Domain Kalm routine: c2p1x1_8_c5_040.s ----

g2k_c2p1x1_8_c5_040_init
	move.l	d3,-(sp)
	mulu.w	d0,d3
	lsr.l	#3,d3
	move.l	d3,g2k_c2p1x1_8_c5_040_scroffs
	mulu.w	d0,d1
	move.l	d1,g2k_c2p1x1_8_c5_040_pixels
	move.l	d5,d0
	lsl.l	#3,d0
	sub.l	d5,d0
	move.l	d0,g2k_c2p1x1_8_c5_040_delta0
	addq.l	#4,d0
	move.l	d0,g2k_c2p1x1_8_c5_040_delta4
	move.l	d5,d0
	lsl.l	#2,d0
	move.l	d0,g2k_c2p1x1_8_c5_040_delta1
	move.l	d0,g2k_c2p1x1_8_c5_040_delta3
	move.l	d0,g2k_c2p1x1_8_c5_040_delta5
	move.l	d0,g2k_c2p1x1_8_c5_040_delta7
	sub.l	d5,d0
	move.l	d0,g2k_c2p1x1_8_c5_040_delta2
	move.l	d0,g2k_c2p1x1_8_c5_040_delta6
	move.l	d0,g2k_c2p1x1_8_c5_040_delta8
	move.l	(sp)+,d3
	rts



; a0	c2pscreen
; a1	bitplanes

g2k_c2p1x1_8_c5_040
	movem.l	d2-d7/a2-a6,-(sp)

	add.l	g2k_c2p1x1_8_c5_040_delta0(pc),a1
	add.l	g2k_c2p1x1_8_c5_040_scroffs(pc),a1

	move.l	g2k_c2p1x1_8_c5_040_pixels(pc),d0
	beq	.none
	add.l	a0,d0
	move.l	d0,-(sp)

	tst.b	16(a0)
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	tst.b	16(a0)
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,a5
	move.l	(a0)+,a6

	swap	d4			; Swap 16x4, part 1
	swap	d5
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d6			; Swap 2x4, part 1
	move.l	d5,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	#$33333333,d6
	and.l	#$33333333,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d4
	eor.l	d7,d5

	exg	d4,a5
	exg	d5,a6

	swap	d4			; Swap 16x4, part 2
	swap	d5
	eor.w	d2,d4
	eor.w	d3,d5
	eor.w	d4,d2
	eor.w	d5,d3
	eor.w	d2,d4
	eor.w	d3,d5
	swap	d4
	swap	d5

	move.l	d4,d6			; Swap 2x4, part 1
	move.l	d5,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d2,d6
	eor.l	d3,d7
	and.l	#$33333333,d6
	and.l	#$33333333,d7
	eor.l	d6,d2
	eor.l	d7,d3
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d4
	eor.l	d7,d5

	move.l	d1,d6			; Swap 4x1, part 1
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d6
	and.l	#$0f0f0f0f,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d1
	eor.l	d7,d3

	move.l	d2,d6			; Swap 8x2, part 1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	#$00ff00ff,d6
	and.l	#$00ff00ff,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d2
	eor.l	d7,d3

	bra	.start

	cnop	0,4
.x
	tst.b	32(a0)
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	tst.b	32(a0)
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,a5
	move.l	(a0)+,a6

	move.l	d6,(a1)

	swap	d4			; Swap 16x4, part 1
	swap	d5
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	sub.l	g2k_c2p1x1_8_c5_040_delta1(pc),a1
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d6			; Swap 2x4, part 1
	move.l	d7,(a1)
	move.l	d5,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	#$33333333,d6
	and.l	#$33333333,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d4
	eor.l	d7,d5

	exg	d4,a5
	add.l	g2k_c2p1x1_8_c5_040_delta2(pc),a1
	exg	d5,a6

	swap	d4			; Swap 16x4, part 2
	swap	d5
	eor.w	d2,d4
	eor.w	d3,d5
	eor.w	d4,d2
	eor.w	d5,d3
	eor.w	d2,d4
	eor.w	d3,d5
	swap	d4
	swap	d5

	move.l	a3,(a1)
	move.l	d4,d6			; Swap 2x4, part 2
	move.l	d5,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d2,d6
	eor.l	d3,d7
	and.l	#$33333333,d6
	and.l	#$33333333,d7
	eor.l	d6,d2
	eor.l	d7,d3
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d4
	eor.l	d7,d5

	move.l	d1,d6			; Swap 4x1, part 1
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d6
	and.l	#$0f0f0f0f,d7
	sub.l	g2k_c2p1x1_8_c5_040_delta3(pc),a1
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d1
	move.l	a4,(a1)
	eor.l	d7,d3

	move.l	d2,d6			; Swap 8x2, part 1
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	#$00ff00ff,d6
	and.l	#$00ff00ff,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d2
	add.l	g2k_c2p1x1_8_c5_040_delta4(pc),a1
	eor.l	d7,d3
.start

	move.l	d2,d6			; Swap 1x2, part 1
	move.l	d3,d7
	lsr.l	#1,d6
	lsr.l	#1,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	#$55555555,d6
	and.l	#$55555555,d7
	eor.l	d6,d0
	eor.l	d7,d1
	move.l	d0,(a1)
	add.l	d6,d6
	add.l	d7,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	a5,d6
	move.l	a6,d7
	move.l	d2,a3
	move.l	d3,a4

	move.l	d5,d2			; Swap 4x1, part 2
	move.l	d7,d3
	lsr.l	#4,d2
	lsr.l	#4,d3
	sub.l	g2k_c2p1x1_8_c5_040_delta5(pc),a1
	eor.l	d4,d2
	eor.l	d6,d3
	and.l	#$0f0f0f0f,d2
	and.l	#$0f0f0f0f,d3
	eor.l	d2,d4
	move.l	d1,(a1)
	eor.l	d3,d6

	lsl.l	#4,d2
	lsl.l	#4,d3
	eor.l	d2,d5
	eor.l	d3,d7

	move.l	d4,d2			; Swap 8x2, part 2
	move.l	d5,d3
	lsr.l	#8,d2
	lsr.l	#8,d3
	add.l	g2k_c2p1x1_8_c5_040_delta6(pc),a1
	eor.l	d6,d2
	eor.l	d7,d3
	and.l	#$00ff00ff,d2
	and.l	#$00ff00ff,d3
	eor.l	d2,d6
	move.l	a3,(a1)
	eor.l	d3,d7

	lsl.l	#8,d2
	lsl.l	#8,d3
	eor.l	d2,d4
	eor.l	d3,d5

	move.l	d4,d2			; Swap 1x2, part 2
	move.l	d5,d3
	sub.l	g2k_c2p1x1_8_c5_040_delta7(pc),a1
	lsr.l	#1,d2
	lsr.l	#1,d3
	eor.l	d6,d2
	eor.l	d7,d3
	and.l	#$55555555,d2
	move.l	a4,(a1)
	and.l	#$55555555,d3

	eor.l	d2,d6
	eor.l	d3,d7
	add.l	d2,d2
	add.l	d3,d3
	eor.l	d2,d4
	eor.l	d3,d5

	add.l	g2k_c2p1x1_8_c5_040_delta8(pc),a1
	move.l	d4,a3
	move.l	d5,a4

	cmp.l	(sp),a0
	bne	.x

	move.l	d6,(a1)
	sub.l	g2k_c2p1x1_8_c5_040_delta1(pc),a1
	move.l	d7,(a1)
	add.l	g2k_c2p1x1_8_c5_040_delta2(pc),a1
	move.l	a3,(a1)
	sub.l	g2k_c2p1x1_8_c5_040_delta3(pc),a1
	move.l	a4,(a1)

	addq.l	#4,sp

.none	movem.l	(sp)+,d2-d7/a2-a6
	rts

			cnop	0,4

g2k_c2p1x1_8_c5_040_data
g2k_c2p1x1_8_c5_040_scroffs	ds.l	1
g2k_c2p1x1_8_c5_040_pixels	ds.l	1
g2k_c2p1x1_8_c5_040_delta0	ds.l	1
g2k_c2p1x1_8_c5_040_delta1	ds.l	1
g2k_c2p1x1_8_c5_040_delta2	ds.l	1
g2k_c2p1x1_8_c5_040_delta3	ds.l	1
g2k_c2p1x1_8_c5_040_delta4	ds.l	1
g2k_c2p1x1_8_c5_040_delta5	ds.l	1
g2k_c2p1x1_8_c5_040_delta6	ds.l	1
g2k_c2p1x1_8_c5_040_delta7	ds.l	1
g2k_c2p1x1_8_c5_040_delta8	ds.l	1

; ---- Embedded Public Domain Kalm routine: c2p1x1_6_c5_040.s ----
;
; Date: 2000-04-17			Mikael Kalms (Scout/C-Lous & more)
;					Email: mikael@kalms.org
;
; About:
;   1x1 6bpl cpu5 C2P for contigous bitplanes and no horizontal modulo
;
;   This routine is intended for use on all 68040 and 68060 based systems.
;   It is not designed to perform well on 68020-030.
;
;   This routine is released into the public domain. It may be freely used
;   for non-commercial as well as commercial purposes. A short notice via
;   email is always appreciated, though.
;
; Timings:
;   Estimated to run at copyspeed on 040-40 and 060
;
; Features:
;   Handles bitplanes of virtually any size (4GB)
;
; Restrictions:
;   Chunky-buffer must be an even multiple of 32 pixels wide
;   If incorrect/invalid parameters are specified, the routine will
;   most probably crash.
;
; g2k_c2p1x1_6_c5_040_init			sets chunkybuffer size/pos & bplsize
; g2k_c2p1x1_6_c5_040			performs the actual c2p conversion
;


; d0.w	chunkyx [chunky-pixels]
; d1.w	chunkyy [chunky-pixels]
; d2.w	(scroffsx) [screen-pixels]
; d3.w	scroffsy [screen-pixels]
; d4.l	(rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l	bplsize [bytes] -- offset between one row in one bpl and the next bpl
; d6.l	(chunkylen) [bytes] -- offset between one row and the next in chunkybuf

g2k_c2p1x1_6_c5_040_init
	move.l	d3,-(sp)
	mulu.w	d0,d3
	lsr.l	#3,d3
	move.l	d3,g2k_c2p1x1_6_c5_040_scroffs
	mulu.w	d0,d1
	move.l	d1,g2k_c2p1x1_6_c5_040_pixels
	move.l	d5,d0
	lsl.l	#2,d0
	add.l	d5,d0
	move.l	d0,g2k_c2p1x1_6_c5_040_delta0
	addq.l	#4,d0
	move.l	d0,g2k_c2p1x1_6_c5_040_delta3
	neg.l	d5
	move.l	d5,g2k_c2p1x1_6_c5_040_delta1
	move.l	d5,g2k_c2p1x1_6_c5_040_delta2
	move.l	d5,g2k_c2p1x1_6_c5_040_delta4
	move.l	d5,g2k_c2p1x1_6_c5_040_delta5
	move.l	d5,g2k_c2p1x1_6_c5_040_delta6
	move.l	(sp)+,d3
	rts


; a0	chunkybuffer
; a1	bitplanes

g2k_c2p1x1_6_c5_040

	movem.l	d2-d7/a2-a6,-(sp)

	add.l	g2k_c2p1x1_6_c5_040_delta0(pc),a1
	add.l	g2k_c2p1x1_6_c5_040_scroffs(pc),a1

	move.l	g2k_c2p1x1_6_c5_040_pixels(pc),a2
	tst.l	a2
	beq	.none
	add.l	a0,a2

	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,a5
	move.l	(a0)+,a6

	move.l	d1,d6			; Swap 4x1, part 1
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d6
	and.l	#$0f0f0f0f,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d1
	eor.l	d7,d3

	exg	d2,a5
	exg	d3,a6

	move.l	d5,d6			; Swap 4x1, part 2
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d4,d6
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d6
	and.l	#$0f0f0f0f,d7
	eor.l	d6,d4
	eor.l	d7,d2
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d5
	eor.l	d7,d3

	exg	a5,d1

	move.w	d4,d6			; Swap 16x4, part 1
	move.w	d2,d7
	move.w	d0,d4
	move.w	d1,d2
	swap	d4
	swap	d2
	move.w	d4,d0
	move.w	d2,d1
	move.w	d6,d4
	move.w	d7,d2

	lsl.l	#2,d0			; Swap/Merge 2x4, part 1
	lsl.l	#2,d1
	or.l	d4,d0
	or.l	d2,d1

	move.l	d1,d6			; Swap 8x2, part 1
	move.l	a5,d4			; Swap 16x4, part 2, interleaved
	lsr.l	#8,d6
	move.l	a6,d2

	swap	d5
	swap	d3
	eor.l	d0,d6
	eor.w	d4,d5
	and.l	#$00ff00ff,d6
	eor.w	d2,d3
	eor.l	d6,d0
	eor.w	d5,d4
	lsl.l	#8,d6
	eor.w	d3,d2
	eor.l	d6,d1
	eor.w	d4,d5

	move.l	d1,d6			; Swap 1x2, part 1
	eor.w	d2,d3			; Swap 16x4, part 2, interleaved
	swap	d5
	swap	d3
	lsr.l	#1,d6

	bra	.start
	cnop	0,16
.x
	tst.b	32(a0)
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	tst.b	32(a0)
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,a5
	move.l	(a0)+,a6

	move.l	d6,(a1)

	move.l	d1,d6			; Swap 4x1, part 1
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d6
	and.l	#$0f0f0f0f,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d1
	eor.l	d7,d3

	exg	d2,a5
	exg	d3,a6

	move.l	d5,d6			; Swap 4x1, part 2
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d4,d6
	add.l	g2k_c2p1x1_6_c5_040_delta1(pc),a1
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d6
	and.l	#$0f0f0f0f,d7
	eor.l	d6,d4
	eor.l	d7,d2
	move.l	a3,(a1)
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d5
	eor.l	d7,d3

	exg	a5,d1

	move.w	d4,d6			; Swap 16x4, part 1
	move.w	d2,d7
	move.w	d0,d4
	move.w	d1,d2
	swap	d4
	swap	d2
	move.w	d4,d0
	move.w	d2,d1
	move.w	d6,d4
	move.w	d7,d2

	lsl.l	#2,d0			; Swap/Merge 2x4, part 1
	lsl.l	#2,d1
	add.l	g2k_c2p1x1_6_c5_040_delta2(pc),a1
	or.l	d4,d0
	or.l	d2,d1

	move.l	d1,d6			; Swap 8x2, part 1
	move.l	a5,d4			; Swap 16x4, part 2, interleaved
	lsr.l	#8,d6
	move.l	a6,d2
	move.l	a4,(a1)

	swap	d5
	swap	d3
	eor.l	d0,d6
	eor.w	d4,d5
	and.l	#$00ff00ff,d6
	eor.w	d2,d3
	eor.l	d6,d0
	eor.w	d5,d4
	lsl.l	#8,d6
	eor.w	d3,d2
	eor.l	d6,d1
	eor.w	d4,d5

	move.l	d1,d6			; Swap 1x2, part 1
	eor.w	d2,d3			; Swap 16x4, part 2, interleaved
	swap	d5
	swap	d3
	add.l	g2k_c2p1x1_6_c5_040_delta3(pc),a1
	lsr.l	#1,d6
.start
	eor.l	d0,d6
	and.l	#$55555555,d6
	eor.l	d6,d0
	add.l	d6,d6
	eor.l	d6,d1

	move.l	d0,(a1)

	move.l	d5,d6			; Swap/Merge 2x4, part 2
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d4,d6
	eor.l	d2,d7
	and.l	#$33333333,d6
	and.l	#$33333333,d7
	eor.l	d6,d4
	eor.l	d7,d2
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d5
	eor.l	d7,d3

	add.l	g2k_c2p1x1_6_c5_040_delta4(pc),a1
	move.l	d2,d6			; Swap 8x2, part 2
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d4,d6
	eor.l	d5,d7
	move.l	d1,(a1)
	and.l	#$00ff00ff,d6
	and.l	#$00ff00ff,d7
	eor.l	d6,d4
	eor.l	d7,d5
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	d2,d6			; Swap 1x2, part 2
	move.l	d3,d7
	lsr.l	#1,d6
	lsr.l	#1,d7
	add.l	g2k_c2p1x1_6_c5_040_delta5(pc),a1
	eor.l	d4,d6
	eor.l	d5,d7
	and.l	#$55555555,d6
	and.l	#$55555555,d7
	eor.l	d6,d4
	eor.l	d7,d5
	move.l	d4,(a1)
	add.l	d6,d6
	add.l	d7,d7
	eor.l	d2,d6
	eor.l	d7,d3

	move.l	d5,a3
	move.l	d3,a4
	add.l	g2k_c2p1x1_6_c5_040_delta6(pc),a1

	cmp.l	a0,a2
	bne	.x

	move.l	d6,(a1)
	add.l	g2k_c2p1x1_6_c5_040_delta1(pc),a1
	move.l	a3,(a1)
	add.l	g2k_c2p1x1_6_c5_040_delta2(pc),a1
	move.l	a4,(a1)


.none	movem.l	(sp)+,d2-d7/a2-a6
	rts

			cnop	0,4
g2k_c2p1x1_6_c5_040_data
g2k_c2p1x1_6_c5_040_scroffs	ds.l	1
g2k_c2p1x1_6_c5_040_pixels	ds.l	1
g2k_c2p1x1_6_c5_040_delta0	ds.l	1
g2k_c2p1x1_6_c5_040_delta1	ds.l	1
g2k_c2p1x1_6_c5_040_delta2	ds.l	1
g2k_c2p1x1_6_c5_040_delta3	ds.l	1
g2k_c2p1x1_6_c5_040_delta4	ds.l	1
g2k_c2p1x1_6_c5_040_delta5	ds.l	1
g2k_c2p1x1_6_c5_040_delta6	ds.l	1

; v190p: title art memory pressure relief.  Direct START LEVEL tests show that
; later maps load when the title/intermission path has not accumulated extra
; large allocations.  Keep the title picture out of memory while playing, then
; reload it before returning to the title menu.  Palette/remap tables stay loaded.
g2v190p_load_title_assets
	movem.l	d0/a0,-(a7)
	tst.l	gloom
	bne.s	.done
	jsr	permit
	move.l	g2title_aga_ptr,a0
	tst	aga
	bne.s	.load
	; c87b14: ECS title is already precomposed.  Clear all legacy brush state
	; and the clean ABOUT title before reloading the two Fast-EHB title files.
	clr.l	gloombrush
	clr.l	gloombrushpal
	clr.l	g2ecs_fast_title_base
	clr.l	g2ecs_fast_title_base_pal
	move.l	g2title_ecs_ptr,a0
.load	jsr	loadfiles
	jsr	g2ecs_fast_detect_assets
	jsr	g2embed_apply_g1_fallbacks	;v190gl: title/brush/palette fallback after reload
	jsr	g2embed_apply_zm_title_overlay	;v190hu: embedded Zombie Massacre title overlay after reload
	jsr	forbid
.done	movem.l	(a7)+,d0/a0
	rts

g2v190p_free_title_assets
	movem.l	d0/a1,-(a7)
	move.l	gloom,d0
	beq.s	.skip_gloom
	cmp.l	#g2embed_title,d0
	beq.s	.skip_gloom
	clr.l	gloom
	move.l	d0,a1
	freemem	title
.skip_gloom
	move.l	gloompal,d0
	beq.s	.skip_pal
	cmp.l	#g2embed_title_pal,d0
	beq.s	.skip_pal
	cmp.l	#g2embed_zm_title_pal,d0	; v190hu: embedded ZM title palette is static
	beq.s	.skip_pal
	clr.l	gloompal
	move.l	d0,a1
	freemem	titlepal
.skip_pal
	move.l	gloombrush,d0
	beq.s	.skip_brush
	cmp.l	#g2embed_gloombrush,d0
	beq.s	.skip_brush
	cmp.l	#g2embed_zm_titlebrush,d0	; v190hu: embedded ZM title image is static
	beq.s	.skip_brush
	clr.l	gloombrush
	move.l	d0,a1
	freemem	titlebrush
.skip_brush
	move.l	gloombrushpal,d0
	beq.s	.skip_brushpal
	clr.l	gloombrushpal
	move.l	d0,a1
	freemem	titlebrushpal
.skip_brushpal
	move.l	g2ecs_fast_title_base,d0
	beq.s	.skip_fast_base
	clr.l	g2ecs_fast_title_base
	move.l	d0,a1
	freemem	fasttitlebase
.skip_fast_base
	move.l	g2ecs_fast_title_base_pal,d0
	beq.s	.skip_fast_base_pal
	clr.l	g2ecs_fast_title_base_pal
	move.l	d0,a1
	freemem	fasttitlebasepal
.skip_fast_base_pal
	movem.l	(a7)+,d0/a1
	rts

; c87b22: detect the editor Fast-EHB contract.
; All profiles require a 320-wide, at least 240-line, six-plane title and its
; 128-byte EHB palette.  Gloom/Gloom Deluxe additionally require title_base for
; their clean ABOUT screen.  Gloom3 uses the converted retail title directly.  Zombie Massacre follows
; the Fast-EHB precomposed-title contract and therefore also requires title_base.
g2ecs_fast_detect_assets
	movem.l	d0/a0,-(a7)
	clr	g2ecs_fast_assets_enabled
	tst	aga
	bne.s	.done
	move.l	gloom,d0
	beq.s	.done
	move.l	d0,a0
	cmp	#320,(a0)
	bne.s	.done
	cmp	#240,2(a0)
	blo.s	.done
	cmp	#6,4(a0)
	bne.s	.done
	tst.l	gloompal
	beq.s	.done
	cmp	#3,g2_game_profile
	beq.s	.direct_title_ready	;c87b33: only Gloom3 uses its direct title for ABOUT
	move.l	g2ecs_fast_title_base,d0
	beq.s	.done
	move.l	d0,a0
	cmp	#320,(a0)
	bne.s	.done
	cmp	#240,2(a0)
	bne.s	.done
	cmp	#6,4(a0)
	bne.s	.done
	tst.l	g2ecs_fast_title_base_pal
	beq.s	.done
.direct_title_ready
	move	#-1,g2ecs_fast_assets_enabled
.done
	movem.l	(a7)+,d0/a0
	rts

g2v190p_title_aga
	dc.l	gloom
	dc.b	'pics/title',0
	even
	dc.l	gloompal
	dc.b	'pics/title.pal',0
	even
	dc.l	gloombrush
	dc.b	'pics/gloom',0
	even
	dc.l	0

g2v190p_title_ecs
	dc.l	gloom
	dc.b	'pics_ehb/title',0
	even
	dc.l	gloompal
	dc.b	'pics_ehb/title.pal',0
	even
	dc.l	g2ecs_fast_title_base
	dc.b	'pics_ehb/title_base',0
	even
	dc.l	g2ecs_fast_title_base_pal
	dc.b	'pics_ehb/title_base.pal',0
	even
	dc.l	0

paladjust	ds.b	256	;remaping for scrambled bitplanes
map_rgbs_	ds.w	256*16	;v190p original-sized 4bit RGB palette pool

	even
; v190o: large levelselect/script buffers moved out of the middle of code/data so
; they do not push existing PC-relative references beyond GenAm's 32KB range.
g2v190i_script_static ds.b g2v190i_script_static_size
	even
g2v190i_level_names ds.b g2v190i_max_levels*16
g2v190i_level_paths ds.b g2v190i_max_levels*64
g2v190i_level_offsets ds.l g2v190i_max_levels	; v190r: script command offsets for START LEVEL chain mode
	even


	even

		even

	even
; v190an: resume from ESC in-game menu without the old predrawall blank
; frames.  predrawall clears and db-swaps both bitmaps via clspic, which is the
; visible black flash on real Amiga.  Here the grey/menu frame stays visible
; while a real gameplay frame is rendered into the hidden bitmap.  After the
; first db the screen is already back in-game; a second render fills the other
; buffer as well so the following frame cannot bounce back to the menu image.
g2v190an_resume_menu_noblank
	movem.l	d0/a0,-(a7)
	move.l	player1,a0
	st	ob_update(a0)
	tst	gametype
	beq.s	.g2v190an_one_player
	move.l	player2,a0
	st	ob_update(a0)
.g2v190an_one_player
	movem.l	(a7)+,d0/a0
	jsr	g2v190aj_restore_game_palette
	jsr	drawall_
	jsr	drawall_
	rts

; v190bz: transparent wall strip colour filter LUTs for chunky renderer.
; The original planar renderer used the byte before each transparent texture
; column as a colour-mask selector.  Flag -6 is the green glass/screen tint.
; In chunky mode we emulate that by remapping the already-rendered destination
; pixel through this palette-aware LUT when the transparent texel is zero.
g2build_strip_luts
	movem.l	d0-d7/a0-a6,-(a7)
	lea	g2_strip_green_lut,a0
	moveq	#0,d0
	move	#255,d7
.g2st_identity
	move.b	d0,(a0)+
	addq	#1,d0
	dbf	d7,.g2st_identity
	move.l	planar_palette,d0
	beq.w	.g2st_done
	move.l	d0,a2
	move.l	planar_remap,a3
	tst.l	a3
	beq.w	.g2st_done
	; build inverse paladjust: adjusted chunky index -> original palette index
	lea	g2_strip_invpal,a0
	moveq	#0,d0
	move	#255,d7
.g2st_clear_inv
	move.b	d0,(a0)+
	addq	#1,d0
	dbf	d7,.g2st_clear_inv
	lea	g2_strip_invpal,a0
	lea	paladjust,a1
	moveq	#0,d0
	move	#255,d7
.g2st_inv_loop
	moveq	#0,d1
	move.b	0(a1,d0.w),d1
	move.b	d0,0(a0,d1.w)
	addq	#1,d0
	dbf	d7,.g2st_inv_loop
	lea	g2_strip_green_lut,a4
	lea	g2_strip_invpal,a0
	lea	paladjust,a5
	moveq	#0,d3
	move	#255,d7
.g2st_lut_loop
	moveq	#0,d4
	move.b	0(a0,d3.w),d4	; real palette index before paladjust
	moveq	#0,d0
	cmp	colours,d4
	bcc.s	.g2st_make_green
	move	d4,d5
	tst	aga
	beq.s	.g2st_ecs_col
	lsl	#2,d5
	bra.s	.g2st_get_col
.g2st_ecs_col
	add	d5,d5
.g2st_get_col
	move	0(a2,d5.w),d0	; 12-bit RGB
.g2st_make_green
	; v190cf: realistic green glass.  Preserve the brightness of what is
	; already behind the pane instead of adding a fixed green boost.  Dark
	; walls therefore remain dark, while bright lamps/textures stay bright but
	; become green-tinted.
	move	d0,d1	; red
	lsr	#8,d1
	and	#$000f,d1
	move	d0,d2	; green
	lsr	#4,d2
	and	#$000f,d2
	move	d0,d6	; blue
	and	#$000f,d6
	move	d1,d5	; brightness = max(r,g,b)
	cmp	d2,d5
	bhs.s	.g2st_max_g_ok
	move	d2,d5
.g2st_max_g_ok
	cmp	d6,d5
	bhs.s	.g2st_max_b_ok
	move	d6,d5
.g2st_max_b_ok
	move	d5,d2	; green channel keeps background brightness
	move	d5,d1	; red/blue only a weak bleed-through
	lsr	#2,d1
	move	d1,d6
	lsl	#8,d1
	lsl	#4,d2
	or	d2,d1
	or	d6,d1
	moveq	#0,d0
	move.b	0(a3,d1.w),d0	; RGB -> nearest game palette entry
	move.b	0(a5,d0.w),d0	; paladjust -> active chunky index
	move.b	d0,0(a4,d3.w)
	addq	#1,d3
	dbf	d7,.g2st_lut_loop
.g2st_done
	; c87b78h: inverse paladjust is the second half of the P96 source-colour
	; contract. Bump its generation even when the rebuilt table is identical;
	; this guarantees correctness after level/profile/remap changes.
	cmp	#2,g2display_mode
	bne.s	.g2c87b78h_no_remap_generation
	addq.l	#1,p96palette_remap_generation
	bne.s	.g2c87b78h_no_remap_generation
	addq.l	#1,p96palette_remap_generation
.g2c87b78h_no_remap_generation
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2_strip_invpal	ds.b	256
g2_strip_green_lut	ds.b	256
	even

; v190aj: true grey in-game menu backdrop for the Gloom2 chunky/C2P path.
; Based on the original gloom.s idea of drawing the game through a temporary
; grey palette, but without calling the full drawall wait path from ESC.
; We remap the already-rendered chunky frame to safe grey indices 4..15,
; poke a matching temporary grey palette, C2P it once, then initmenu draws the
; yellow bigfont2 over this grey frame.  On leaving/refreshing the menu, the
; original gameplay palette is restored before normal rendering continues.
g2v190aj_grey_menu_backdrop
	movem.l	d0-d7/a0-a6,-(a7)
	; c87b79p: the grey chunky/C2P backdrop belongs only to native AGA/ECS.
	; P96 keeps the live indexed gameplay frame and overlays glyphs directly.
	cmp	#2,g2display_mode
	beq.w	.g2c87b79p_done
	move.l	lastpal,d0
	move.l	d0,g2v190aj_saved_lastpal
	jsr	g2v190aj_build_grey_palette
	jsr	g2v190aj_build_grey_lut
	jsr	g2v190aj_apply_grey_lut
	lea	g2v190aj_grey_pal,a1
	jsr	pokepal
	; c86n: in TWO PLAYER the grey ESC-menu backdrop must C2P the
	; complete 320x240 split frame.  The active WINDOW SIZE globals may
	; describe only the game crop, which made the menu preview distorted
	; while changing WINDOW SIZE.
	tst	twowins
	beq.s	.g2v190aj_normal_c2p
	jsr	g2twop_restore_coloffs
	jsr	g2twop_menu_full_c2p
	bra.s	.g2v190aj_c2p_done
.g2v190aj_normal_c2p
	jsr	doc2p
	jsr	db
.g2v190aj_c2p_done
.g2c87b79p_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

g2v190aj_restore_game_palette
	movem.l	d0/a1,-(a7)
	move.l	g2v190aj_saved_lastpal,d0
	beq.s	.g2v190aj_rg_done
	move.l	d0,a1
	jsr	pokepal
	clr.l	g2v190aj_saved_lastpal
.g2v190aj_rg_done
	movem.l	(a7)+,d0/a1
	rts

g2v190aj_build_grey_palette
	movem.l	d0-d7/a0,-(a7)
	lea	g2v190aj_grey_pal,a0
	move	colours,d7
	beq.s	.g2v190aj_bgp_done
	subq	#1,d7
	moveq	#0,d0
	tst	aga
	beq.s	.g2v190aj_bgp_ecs
.g2v190aj_bgp_aga_loop
	bsr.s	g2v190aj_make_grey_rgb
	move	d1,(a0)+
	clr	(a0)+
	addq	#1,d0
	dbf	d7,.g2v190aj_bgp_aga_loop
	bra.s	.g2v190aj_bgp_done
.g2v190aj_bgp_ecs
	bsr.s	g2v190aj_make_grey_rgb
	move	d1,(a0)+
	addq	#1,d0
	dbf	d7,.g2v190aj_bgp_ecs
.g2v190aj_bgp_done
	movem.l	(a7)+,d0-d7/a0
	rts

; d0 = palette index, returns d1 = 12-bit RGB grey.  4..15 are the grey ramp;
; 1..3 are left for initfontpal/bigfont2 and are not used by the backdrop.
g2v190aj_make_grey_rgb
	moveq	#0,d1
	cmp	#4,d0
	bcs.s	.g2v190aj_mgr_done
	cmp	#15,d0
	bhi.s	.g2v190aj_mgr_done
	move	d0,d1
	subq	#4,d1
	mulu	#9,d1
	divu	#11,d1
	addq	#1,d1		; darker dim ramp 1..10, not full white
	move	d1,d2
	lsl	#8,d1
	move	d2,d3
	lsl	#4,d3
	or	d3,d1
	or	d2,d1
.g2v190aj_mgr_done
	rts

g2v190aj_build_grey_lut
	movem.l	d0-d7/a0-a5,-(a7)
	lea	g2v190aj_invpal,a0
	moveq	#0,d0
	move	#255,d7
.g2v190aj_clear_inv
	move.b	d0,(a0)+
	dbf	d7,.g2v190aj_clear_inv
	lea	g2v190aj_invpal,a0
	lea	paladjust,a1
	moveq	#0,d0
	move	#255,d7
.g2v190aj_inv_loop
	moveq	#0,d1
	move.b	0(a1,d0.w),d1
	move.b	d0,0(a0,d1.w)
	addq	#1,d0
	dbf	d7,.g2v190aj_inv_loop
	move.l	planar_palette,d0
	bne.s	.g2v190fy_havepal
	; v190fy: no source palette available, still build a deterministic
	; grey backdrop LUT instead of leaving stale LUT entries behind.
	lea	g2v190aj_lut,a3
	moveq	#0,d3
	move	#255,d7
.g2v190fy_fallback_lut
	move	d3,d0
	and	#15,d0
	mulu	#11,d0
	divu	#15,d0
	addq	#4,d0
	move.b	d0,0(a3,d3.w)
	addq	#1,d3
	dbf	d7,.g2v190fy_fallback_lut
	bra.w	.g2v190aj_lut_done
.g2v190fy_havepal
	move.l	d0,a2
	lea	g2v190aj_lut,a3
	lea	g2v190aj_invpal,a0
	lea	paladjust,a5
	moveq	#0,d3
	move	#255,d7
.g2v190aj_lut_loop
	moveq	#0,d4
	move.b	0(a0,d3.w),d4	; real display palette index before paladjust
	cmp	colours,d4
	bcc.s	.g2v190aj_lut_black
	move	d4,d5
	tst	aga
	beq.s	.g2v190aj_lut_ecscol
	lsl	#2,d5
	bra.s	.g2v190aj_lut_getcol
.g2v190aj_lut_ecscol
	add	d5,d5
.g2v190aj_lut_getcol
	move	0(a2,d5.w),d0	; 12-bit RGB
	move	d0,d1
	move	d0,d2
	and	#$0f00,d0
	lsr	#8,d0
	and	#$00f0,d1
	lsr	#4,d1
	and	#$000f,d2
	add	d1,d0
	add	d2,d0
	divu	#3,d0		; grey brightness 0..15
	mulu	#11,d0
	divu	#15,d0		; 0..11
	addq	#4,d0		; safe grey palette indices 4..15
	bra.s	.g2v190aj_lut_store
.g2v190aj_lut_black
	moveq	#4,d0
.g2v190aj_lut_store
	; v190fy: write direct safe grey palette indices 4..15 into the
	; static menu backdrop.  Do not pass these through paladjust here:
	; on some C2P/palette layouts that can land in font colour slots 1..3,
	; which initmenu later turns yellow for the menu text.
	move.b	d0,0(a3,d3.w)
	addq	#1,d3
	dbf	d7,.g2v190aj_lut_loop
.g2v190aj_lut_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

g2v190aj_apply_grey_lut
	movem.l	d0-d7/a0-a1,-(a7)
	move.l	chunky,d0
	beq.s	.g2v190aj_ag_done
	move.l	d0,a0
	lea	g2v190aj_lut,a1
	move	hite,d6
	subq	#1,d6
.g2v190aj_ag_y
	move	g2render_last_x,d7
.g2v190aj_ag_x
	moveq	#0,d0
	move.b	(a0),d0
	move.b	0(a1,d0.w),(a0)+
	dbf	d7,.g2v190aj_ag_x
	dbf	d6,.g2v190aj_ag_y
.g2v190aj_ag_done
	movem.l	(a7)+,d0-d7/a0-a1
	rts

; v190aj grey menu temporary palette/LUT storage.  Kept at the file end so it
; does not disturb nearby PC-relative code/data ranges.
g2v190aj_saved_lastpal	dc.l	0
g2v190aj_grey_pal	ds.w	512
g2v190aj_invpal	ds.b	256
g2v190aj_lut	ds.b	256
	even


