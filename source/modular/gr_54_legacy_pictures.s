; =============================================================================
; 2.5.0: Gloom 3 / Zombie Massacre intermission pictures (from v3.0 c87b87).
; Included by GloomReforged_Modular.s and by GloomBench.s (shared hooks in
; gr_31 and gr_36).
;
; Original Gloom3/ZM artwork can end a ByteRun1 row one byte late. The 2.4.0
; audit stabilization repaired that only for pictures loaded through a fixed
; slot (title, combat, magic: g2validate_loaded_slot). Pictures loaded by the
; level script (pict_, the intermission between the levels) went straight to
; the strict check and ONE PLAYER / TWO PLAYER stopped at the first pict_
; (AGA/P96 in g2require_picture_palette, ECS in g2require_iff via decodeiff).
;
; g2legacy_validate_picture replaces JSR g2validate_iff in both checks (same
; size). Strict check first; only for profiles 2/3 a rejected picture is
; canonicalised in place by g2normalize_legacy_iff (owned loader memory, no
; allocation) and then checked strictly again. Gloom and Gloom Deluxe keep
; the unchanged strict check. Every existing label keeps its address.
; =============================================================================

; a0 = picture; d0 = 0 valid / -1 invalid, flags from d0 (as g2validate_iff);
; all other registers preserved.
g2legacy_validate_picture
	jsr	g2validate_iff
	tst.l	d0
	beq.s	.done
	cmp.w	#2,g2_game_profile
	beq.s	.legacy
	cmp.w	#3,g2_game_profile
	bne.s	.done
.legacy
	jsr	g2normalize_legacy_iff
	tst.l	d0
	bne.s	.done
	jsr	g2validate_iff
.done
	tst.l	d0
	rts
