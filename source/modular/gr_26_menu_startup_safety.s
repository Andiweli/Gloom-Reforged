; =============================================================================
; Step 3: bounded CLI map argument and controlled menu-allocation failure.
; =============================================================================

; Input: a0 = text after '@', a1 = tempfile (64 bytes).
; Output: d0 = 0 on success, -1 on overflow; changes d1/a0/a1.
; Accept at most 63 data bytes followed by NUL or LF. Always terminate within
; the buffer. On overflow the caller exits, never opens a truncated map name.
g2safe_copy_map_parameter
	moveq	#63,d1
.loop
	move.b	(a0)+,d0
	beq.w	.terminated
	cmp.b	#10,d0
	beq.w	.terminated
	tst.w	d1
	beq.w	.overflow
	move.b	d0,(a1)+
	subq.w	#1,d1
	bra.w	.loop
.terminated
	clr.b	(a1)
	moveq	#0,d0
	rts
.overflow
	clr.b	(a1)
	moveq	#-1,d0
	rts

; All initmenu/initmenu2 callers run in the main task after initmain.
; A failed strip allocation cannot continue: selected-row restoration assumes
; valid strip storage. Abandon nested menu frames using the stack captured at
; entrypoint, then use the same complete cleanup as an ordinary game exit.
; Do not free strips separately: every successful allocmem menustrip belongs
; to memlist, and exittoos/freememlist frees the partial set exactly once.
; No finitmenu walk over an incomplete/stale menustrips array is performed.
g2menu_allocation_failed
	st	paused			; stop gameplay logic before tearing down its memory
	move.l	g2menu_entry_sp,a7
	jsr	exittoos		; display/input/audio/interrupts/objects/memlist/dir
	moveq	#20,d0			; AmigaDOS failure return code
	rts

	even
g2menu_entry_sp	dc.l	0
