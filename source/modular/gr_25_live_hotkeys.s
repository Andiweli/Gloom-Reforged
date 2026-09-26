; =============================================================================
; Step 2: live menu resolution and frame-boundary option hotkeys.
; All external calls/references are absolute; the new code is appended so the
; existing renderer is not expanded by an entire input dispatcher.
; Keyboard interrupts only maintain the existing raw matrix. No DOS/rendering
; work is added to an interrupt. F8 is deliberately not sampled; F9 toggles the FPS overlay.
; =============================================================================

; Same condition flags as qkey $45: Z clear while ESC or F10 is held.
; The existing menu trigger/release path owns F10 exactly like ESC.
g2hotkeys_menu_key
	move.l	rawtable,a0
	btst	#5,8(a0)		; raw $45 = ESC
	bne.w	.done
	btst	#1,11(a0)		; raw $59 = F10
.done	rts

; d0.w: bits 0..6 = F1..F7; bit 8 = HELP; bit 9 = F9. Changes only d0/a0 and CCR.
g2hotkeys_sample
	move.l	rawtable,a0
	moveq	#0,d0
	move.b	10(a0),d0		; raw $50..$57
	and.w	#$007f,d0		; exclude F8
	btst	#7,11(a0)		; raw $5f = HELP
	beq.w	.f9
	bset	#8,d0
.f9
	btst	#0,11(a0)		; raw $58 = F9; F10 stays on the ESC path
	beq.w	.done
	bset	#9,d0
.done	rts

; Called at each new level; held title/intermission keys are not new presses.
g2hotkeys_seed
	movem.l	d0/a0,-(a7)
	jsr	g2hotkeys_sample
	move.w	d0,g2hotkeys_previous
	clr.w	g2hotkeys_edges
	movem.l	(a7)+,d0/a0
	rts

g2hotkeys_poll_menu
	tst	game_menu_active
	beq.w	.done
	jsr	g2hotkeys_poll
.done	rts

; Called only by the gameplay main loop or the in-game menu selection loop.
; Keep the caller's registers and pause state, including across trainer_apply.
; The saved edge mask lives in memory because existing option routines may
; freely use any data register. Record all held keys BEFORE a live refresh.
g2hotkeys_poll
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2hotkeys_sample
	move.w	g2hotkeys_previous,d1
	not.w	d1
	and.w	d0,d1
	move.w	d0,g2hotkeys_previous
	move.w	d1,g2hotkeys_edges
	beq.w	.done
	; Do not alter an outgoing level or its teleport presentation.
	tst	finished
	bne.w	.done
	tst	finished2
	bne.w	.done
	tst	g2teleport_blackout
	bne.w	.done
	move	paused,-(a7)
	st	paused

	btst	#0,g2hotkeys_edges+1
	beq.w	.f2
	jsr	trainer_next_resolution
.f2
	btst	#1,g2hotkeys_edges+1
	beq.w	.f3
	jsr	trainer_toggle_bayer
.f3
	btst	#2,g2hotkeys_edges+1
	beq.w	.f4
	jsr	g2hotkeys_toggle_ceiling
.f4
	btst	#3,g2hotkeys_edges+1
	beq.w	.f5
	jsr	g2hotkeys_toggle_floor
.f5
	btst	#4,g2hotkeys_edges+1
	beq.w	.f6
	jsr	trainer_toggle_blobshadow
.f6
	btst	#5,g2hotkeys_edges+1
	beq.w	.f7
	moveq	#0,d7		; forward NO -> WEAPON -> ALL -> NO
	jsr	trainer_toggle_reflections
.f7
	btst	#6,g2hotkeys_edges+1
	beq.w	.help
	jsr	trainer_toggle_visibility
.help
	btst	#0,g2hotkeys_edges	; bit 8 in the big-endian word
	beq.w	.fps
	jsr	trainer_toggle_inv
.fps
	btst	#1,g2hotkeys_edges	; bit 9 = F9
	beq.w	.apply
	jsr	g2hotkeys_toggle_fps
.apply
	jsr	g2hotkeys_notice_for_edges	; final effective values, same HUD slot as pickups
	; Re-arm persistent P96 WIDE/5:4 geometry before drawing a changed raster.
	jsr	g2resolution_apply_after_menu
	tst	game_menu_active
	beq.w	.resume
	; One redraw for all simultaneous option presses, with selected row intact.
	jsr	g2p96_ingame_menu_floorceil_live_refresh
.resume
	move	(a7)+,paused
	; Persist F1..F7 immediately, independently of opening/leaving the menu.
	; F8 has no action. F9/FPS alone never writes configuration.
	move.w	g2hotkeys_edges,d0
	and.w	#$007f,d0
	beq.w	.done
	jsr	g2cfg_save
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Existing binary ceiling/floor semantics, shared by the hotkey dispatcher.
g2hotkeys_toggle_ceiling
	tst	roofflag
	bgt.w	.off
	move	#1,roofflag
	bra.w	.text
.off	move	#-1,roofflag
.text	move	roofflag,roofflag2
	jmp	trainer_update_ceiling_text

g2hotkeys_toggle_floor
	tst	floorflag
	bgt.w	.off
	move	#1,floorflag
	bra.w	.text
.off	move	#-1,floorflag
.text	move	floorflag,floorflag2
	jmp	trainer_update_floor_text

; Use the existing FPS flag, including the initial FPS ToolType selection.
; Start a fresh interval so disabled/menu time never dilutes the next reading.
g2hotkeys_toggle_fps
	not.w	g2fps_enabled
	jmp	g2fps_restart_window

; Menu arrows/activation use this after trainer_next/prev_resolution.
; The existing refresh redraws both halves for TWO PLAYER, or prepares and
; expands the single-player world before HUD/menu composition.
g2resolution_live_menu
	jsr	g2resolution_apply_after_menu
	jmp	g2p96_ingame_menu_floorceil_live_refresh

	even
g2hotkeys_previous	dc.w	0
g2hotkeys_edges		dc.w	0

; -----------------------------------------------------------------------------
; Step 4: option feedback through the existing timed pickup-message HUD slot.
; The old message routine consumes an INLINE string at its return address,
; so a dynamic string must set ob_mess/ob_messlen/ob_messtimer directly.
; All option changes have completed; display the actual post-lock value.
; One HUD slot: simultaneous keys use F9, then the highest F1..F7 as priority.
; F8 is unused; HELP and F10 do not emit a new option notice here.
; -----------------------------------------------------------------------------
g2hotkeys_notice_for_edges
	movem.l	d0-d2/a0-a5,-(a7)
	btst	#1,g2hotkeys_edges	; bit 9 = F9
	beq.w	.options
	lea	g2hotkeys_fps_no,a0
	tst	g2fps_enabled
	beq.w	.emit
	lea	g2hotkeys_fps_yes,a0
	bra.w	.emit
.options
	move.w	g2hotkeys_edges,d0
	and.w	#$007f,d0
	beq.w	.done
	moveq	#6,d1
.find
	btst	d1,d0
	bne.w	.found
	subq.w	#1,d1
	bra.w	.find
.found
	lea	g2hotkeys_notice_rows,a0
	lsl.w	#2,d1
	move.l	0(a0,d1.w),a0
.emit
	bsr.w	g2hotkeys_notice_from_row
.done
	movem.l	(a7)+,d0-d2/a0-a5
	rts

; a0 = menu row. Labels end at ':', all value fields begin at byte 21.
; Copy at most 63 bytes, discard padding and colon, insert one separator.
; a3 tracks the last non-space endpoint so trailing padding never reaches HUD.
g2hotkeys_notice_from_row
	lea	21(a0),a1
	lea	g2hotkeys_notice_buffer,a2
	move.l	a2,a3
	moveq	#63,d2
.leading
	cmp.b	#' ',(a0)
	bne.w	.label
	addq.l	#1,a0
	bra.w	.leading
.label
	move.b	(a0)+,d0
	beq.w	.publish
	cmp.b	#':',d0
	beq.w	.separator
	move.b	d0,(a2)+
	move.l	a2,a3
	subq.w	#1,d2
	beq.w	.publish
	bra.w	.label
.separator
	move.b	#' ',(a2)+
	subq.w	#1,d2
	beq.w	.publish
.value_leading
	cmp.b	#' ',(a1)
	bne.w	.value
	addq.l	#1,a1
	bra.w	.value_leading
.value
	move.b	(a1)+,d0
	beq.w	.publish
	move.b	d0,(a2)+
	cmp.b	#' ',d0
	beq.w	.value_space
	move.l	a2,a3
.value_space
	subq.w	#1,d2
	beq.w	.publish
	bra.w	.value
.publish
	clr.b	(a3)
	move.l	a3,d0
	sub.l	#g2hotkeys_notice_buffer,d0
	beq.w	.done
	move.l	player1,d1
	beq.w	.player2
	move.l	d1,a5
	bsr.w	.set_player
.player2
	tst	twowins
	beq.w	.done
	move.l	player2,d1
	beq.w	.done
	move.l	d1,a5
	bsr.w	.set_player
.done
	rts
.set_player
	move.l	#g2hotkeys_notice_buffer,ob_mess(a5)
	move.w	d0,ob_messlen(a5)
	move.w	#127,ob_messtimer(a5)	; same lifetime and renderer as pickup notices
	rts

	even
g2hotkeys_notice_rows
	dc.l	game_resolution,game_bayer,game_ceil,game_floor
	dc.l	game_blob,game_reflections,game_visibility
; FPS has no menu row. Use the identical value-field layout and YES/NO style.
g2hotkeys_fps_yes	dc.b	'FPS:                 YES',0
g2hotkeys_fps_no	dc.b	'FPS:                 NO',0
	even
g2hotkeys_notice_buffer	ds.b	64
