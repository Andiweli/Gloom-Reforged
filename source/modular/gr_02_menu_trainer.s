dogamemenu	;
	jsr	g2p96_display_enter_ingame_menu	;c86zfq: native P96 ESC menu owns display
	move	#$20,$dff09a
	;
	st	paused
	clr	g2resolution_menu_changed	;c87b69f: track only changes made in this menu session
	move	framecnt,-(a7)
	move	linked,-(a7)
	clr	linked
	;
	move	#$8020,$dff09a
	;
	jsr	g2p96_display_should_lock_fullwin	;c86zga: P96 menu uses live gameplay, AGA keeps original grey backdrop
	tst	d0
	bne.s	.p96_menu_no_grey
	jsr	g2v190aj_grey_menu_backdrop	; v190aj: grey current chunky frame for ESC menu, no full drawall call
	; c86zgb buildfix: branch target was the next instruction; GenAm cannot encode 0-byte bra.s
	nop
.p96_menu_no_grey
	; No grey/dim backdrop under P96.  Keep the last gameplay frame visible.
.menu_backdrop_done
	bsr	trainer_update_display_texts
	lea	gamemenu,a4
	; c87b12: this flag must be active before initmenu.  Otherwise ECS treats
	; the in-game menu like TITLE/ABOUT and performs the complete 320x240
	; six-plane static-picture remap before drawing any menu row.
	move	#-1,game_menu_active
	jsr	initmenu
	; c86zgc: keep the already-present P96 gameplay frame, including HUD.
	; Do not redraw/clear the HUD or copy a full backdrop here; only overlay glyphs.
	jsr	g2p96_menu_all_rows_present	;c86zgc: fast glyph-only menu overlay
	; v17: entering the in-game menu via ESC leaves ESC/fire still held.
	; Wait until the trigger is released so CONTINUE is not auto-selected.
	jsr	g2v17_wait_menu_release
	;
.loop	jsr	selmenu
	move	d0,d7
	and	#$0300,d7	;v109: $0100=left, $0200=right in game menu
	and	#$00ff,d0
	tst	d7
	beq.s	.game_menu_fire
	cmp	#0,d0
	beq	.loop
	bra.s	.game_menu_adjust
.game_menu_fire
	cmp	#0,d0
	beq	.done
.game_menu_adjust
	cmp	#2,d0
	bne.s	.notresolution
	cmp	#$0100,d7
	beq.s	.resolution_left
	bsr	trainer_next_resolution
	bra.s	.resolution_done
.resolution_left
	bsr	trainer_prev_resolution
.resolution_done
	jsr	g2resolution_live_menu
	bra	.loop
.notresolution
	cmp	#3,d0
	bne.s	.notbayer
	bsr	trainer_toggle_bayer
	jsr	g2p96_ingame_menu_floorceil_live_refresh
	bra	.loop
.notbayer
	cmp	#4,d0
	bne.s	.notroof
	tst	roofflag
	bgt.s	.roof_off
	move	#1,roofflag
	bra.s	.rskip
.roof_off	move	#-1,roofflag
.rskip	move	roofflag,roofflag2	;c87b69: CEILING row 4
	bsr	trainer_update_ceiling_text
	jsr	g2cfg_save
	jsr	g2p96_ingame_menu_floorceil_live_refresh
	bra	.loop
.notroof
	cmp	#5,d0
	bne.s	.notfloor
	tst	floorflag
	bgt.s	.floor_off
	move	#1,floorflag
	bra.s	.fskip
.floor_off	move	#-1,floorflag
.fskip	move	floorflag,floorflag2	;c87b69: FLOOR row 5
	bsr	trainer_update_floor_text
	jsr	g2cfg_save
	jsr	g2p96_ingame_menu_floorceil_live_refresh
	bra	.loop
.notfloor
	cmp	#7,d0
	bne.s	.notblob
	bsr	trainer_toggle_blobshadow
	jsr	g2p96_ingame_menu_floorceil_live_refresh
	bra	.loop
.notblob
	cmp	#8,d0
	bne.s	.notrefl
	bsr	trainer_toggle_reflections
	jsr	g2p96_ingame_menu_floorceil_live_refresh
	bra	.loop
.notrefl
	cmp	#9,d0
	bne.s	.notvis
	bsr	trainer_toggle_visibility
	jsr	g2p96_ingame_menu_floorceil_live_refresh
	bra	.loop
.notvis
	cmp	#11,d0
	bne.s	.notinv
	bsr	trainer_toggle_inv
	jsr	opton
	bra	.loop
.notinv
	cmp	#12,d0
	bne.s	.notbouncy
	bsr	trainer_toggle_bouncy
	jsr	opton
	bra	.loop
.notbouncy
	cmp	#13,d0
	bne.s	.notonehit
	bsr	trainer_toggle_onehit
	jsr	opton
	bra	.loop
.notonehit
	cmp	#14,d0
	bne.s	.notweapon
	cmp	#$0100,d7
	beq.s	.weapon_left
	bsr	trainer_next_weapon
	bra.s	.weapon_done
.weapon_left	bsr	trainer_prev_weapon
.weapon_done	jsr	opton
	bra	.loop
.notweapon
	cmp	#15,d0
	bne.s	.notboost
	cmp	#$0100,d7
	beq.s	.boost_left
	bsr	trainer_next_boost
	bra.s	.boost_done
.boost_left	bsr	trainer_prev_boost
.boost_done	jsr	opton
	bra	.loop
.notboost
	cmp	#17,d0
	bne	.loop
	tst	d7
	bne	.loop
	move	#1,finished
	;
.done	jsr	g2cfg_save	;v141: save ingame menu settings when leaving menu
	clr	game_menu_active
	cmp	#1,finished
	beq.s	.finish_exit
	; v190am: normal CONTINUE path stays display-on.  The visible
	; menu frame remains until predrawall has rendered and db-swapped
	; the restored game frame, avoiding the old black redraw flash.
	jsr	dispoff	; v190do: full cleanup after VIEW SIZE changes, no stale menu text
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette
	jsr	g2resolution_apply_after_menu	;c87b69f: live P96 WIDE geometry re-arm
	jsr	predrawall
	jsr	dispon
	bra.s	.findone
.finish_exit
	clr	g2resolution_menu_changed	;c87b69f: no pending live apply when quitting
	jsr	g2p96_transition_clear_p96_if_open	;c86zhj: black P96 immediately when leaving game from ESC menu
	jsr	dispoff
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette	; restore gameplay palette after grey/font menu palette
	jsr	clspic
	jsr	clspic
	jsr	dispon
.findone
	;
	move	#$20,$dff09a
	;
	move	(a7)+,linked
	beq.s	.nolink
	move	finished,d0
	beq.s	.nolink
	bset	#7,d0
	jsr	serput
.nolink	move	(a7)+,framecnt
	clr	paused
	;
	move	#$8020,$dff09a
	;
	rts

g2stock_capture_cfg_options
	; c87b67: remember the sanitized persisted choices before STOCK applies its
	; runtime-only NO / NO / DEFAULT overlay. These shadow words are written
	; back by g2cfg_save while STOCK is active, so the file is never changed.
	move	g2_blobshadow,g2stock_cfg_blobshadow
	move	g2_reflections,g2stock_cfg_reflections
	move	g2_visibility,g2stock_cfg_visibility
	move	g2_bayer_disabled,g2stock_cfg_bayer
	rts

g2stock_enforce_effects_off
	; c87b69: pure runtime STOCK lock. Persisted choices remain untouched.
	tst	g2stock_enabled
	beq.s	.rts
	move	#-1,g2_bayer_disabled	; Step 1: STOCK also locks the live Bayer switch to NO
	move	#-1,g2_blobshadow
	move	#-1,g2_reflections
	move	#-1,g2_visibility
	cmp	#2,mode		; NASTY is a Reforged extension
	bne.s	.rts
	move	#1,mode		; STOCK exposes classic MESSY at most
	bsr	g2stock_refresh_violence_text
.rts	rts

g2stock_refresh_violence_text
	movem.l	d0/a0-a1,-(a7)
	lea	mode2,a0
	lea	modetxt,a1
.copy_main
	move.b	(a0)+,(a1)+
	bne.s	.copy_main
	lea	mode2,a0
	lea	modetxtc,a1
.copy_classic
	move.b	(a0)+,(a1)+
	bne.s	.copy_classic
	movem.l	(a7)+,d0/a0-a1
	rts

trainer_toggle_blobshadow
	tst	g2stock_enabled
	beq.s	.normal
	move	#-1,g2_blobshadow
	bsr	trainer_update_blob_text
	rts
.normal	tst	g2_blobshadow
	ble.s	.on
	move	#-1,g2_blobshadow
	bra.s	.done
.on	move	#1,g2_blobshadow
.done	bsr	trainer_update_blob_text
	rts

trainer_toggle_reflections
	tst	g2stock_enabled
	bne.s	.locked
	tst	g2_bayer_disabled
	beq.s	.normal
.locked
	move	#-1,g2_reflections
	bsr	trainer_update_reflection_text
	rts
.normal
	; c87b38: three-state cycle, while preserving the historic +1 value as ALL
	; so existing gloom.cfg files keep all reflections enabled after updating.
	; LEFT cycles backwards; RIGHT/ENTER/FIRE cycles forwards.
	cmp	#$0100,d7
	beq.s	.prev
.next	move	g2_reflections,d0
	cmp	#2,d0		; WEAPON -> ALL
	beq.s	.all
	cmp	#1,d0		; ALL -> NO
	beq.s	.no
	move	#2,g2_reflections	; NO/invalid -> WEAPON
	bra.s	.done
.prev	move	g2_reflections,d0
	cmp	#2,d0		; WEAPON -> NO
	beq.s	.no
	cmp	#1,d0		; ALL -> WEAPON
	beq.s	.weapon
	move	#1,g2_reflections	; NO/invalid -> ALL
	bra.s	.done
.weapon	move	#2,g2_reflections
	bra.s	.done
.all	move	#1,g2_reflections
	bra.s	.done
.no	move	#-1,g2_reflections
.done	bsr	trainer_update_reflection_text
	rts

trainer_toggle_visibility
	; c87b66: STOCK permanently exposes DEFAULT visibility only.
	tst	g2stock_enabled
	beq.s	.normal
	move	#-1,g2_visibility
	bsr	trainer_update_visibility_text
	rts
.normal	tst	g2_visibility
	bgt.s	.default
	move	#1,g2_visibility
	bra.s	.done
.default	move	#-1,g2_visibility
.done	bsr	trainer_update_visibility_text
	rts

trainer_toggle_inv
	tst	trainer_invincible
	beq.s	.on
	clr	trainer_invincible
	bra.s	.done
.on	move	#-1,trainer_invincible
.done	bsr	trainer_update_inv_text
	bra	trainer_apply

trainer_toggle_bouncy
	tst	trainer_bouncy
	beq.s	.on
	clr	trainer_bouncy
	bra.s	.done
.on	move	#-1,trainer_bouncy
.done	bsr	trainer_update_bouncy_text
	bra	trainer_apply

trainer_toggle_onehit
	tst	trainer_onehit
	beq.s	.on
	clr	trainer_onehit
	bra.s	.done
.on	move	#-1,trainer_onehit
.done	bsr	trainer_update_onehit_text
	rts

trainer_next_weapon
	; v117: WEAPON loops DEFAULT->1..5->DEFAULT for right/RETURN
	cmp	#5,trainer_weapon
	bcs.s	.inc
	clr	trainer_weapon
	bra.s	.ok
.inc	addq	#1,trainer_weapon
.ok	bsr	trainer_update_weapon_text
	bra	trainer_apply

trainer_prev_weapon
	; v117: WEAPON loops DEFAULT<-5<-... for left
	tst	trainer_weapon
	bne.s	.dec
	move	#5,trainer_weapon
	bra.s	.ok
.dec	subq	#1,trainer_weapon
.ok	bsr	trainer_update_weapon_text
	bra	trainer_apply

trainer_next_boost
	; v117: UPGRADE loops DEFAULT->1..5->DEFAULT for right/RETURN
	cmp	#5,trainer_boost
	bcs.s	.inc
	clr	trainer_boost
	bra.s	.ok
.inc	addq	#1,trainer_boost
.ok	bsr	trainer_update_boost_text
	bra	trainer_apply

trainer_prev_boost
	; v117: UPGRADE loops DEFAULT<-5<-... for left
	tst	trainer_boost
	bne.s	.dec
	move	#5,trainer_boost
	bra.s	.ok
.dec	subq	#1,trainer_boost
.ok	bsr	trainer_update_boost_text
	bra	trainer_apply

trainer_apply
	move.l	player1,d0	;c87b16a: absolute, GenAm PC range
	beq.s	.p2
	move.l	d0,a5
	bsr	trainer_apply_one
.p2	tst	twowins
	beq.s	.rts
	move.l	player2,d0	;c87b16a: absolute, GenAm PC range
	beq.s	.rts
	move.l	d0,a5
	bsr	trainer_apply_one
.rts	rts

trainer_apply_one
	move	trainer_weapon,d0
	beq.s	.weapon_default
	subq	#1,d0
	move	d0,ob_weapon(a5)
.weapon_default
	move	trainer_boost,d0
	beq.s	.boost_default
	moveq	#6,d0
	sub	trainer_boost,d0
	move.b	d0,ob_reload(a5)
.boost_default
	tst	trainer_bouncy
	beq.s	.no_bouncy
	move	#3,ob_bouncecnt(a5)
	bra.s	.bouncy_done
.no_bouncy	clr	ob_bouncecnt(a5)
.bouncy_done	tst	trainer_invincible
	beq.s	.no_inv
	move	#25,ob_hitpoints(a5)
.no_inv	st	ob_update(a5)
	rts

trainer_maintain_one	;v112: keep enabled trainer options permanent without forcing
			;status redraws every frame.  Only mark ob_update when a
			;visible value actually changed.
	moveq	#0,d7
	move	trainer_weapon,d0
	beq.s	.weapon_done
	subq	#1,d0
	cmp	ob_weapon(a5),d0
	beq.s	.weapon_done
	move	d0,ob_weapon(a5)
	moveq	#-1,d7
.weapon_done
	move	trainer_boost,d0
	beq.s	.boost_done
	moveq	#6,d0
	sub	trainer_boost,d0
	cmp.b	ob_reload(a5),d0
	beq.s	.boost_done
	move.b	d0,ob_reload(a5)
	moveq	#-1,d7
.boost_done
	tst	trainer_bouncy
	beq.s	.bouncy_done
	cmp	#3,ob_bouncecnt(a5)
	beq.s	.bouncy_done
	move	#3,ob_bouncecnt(a5)
	moveq	#-1,d7
.bouncy_done
	tst	trainer_invincible
	beq.s	.inv_done
	cmp	#25,ob_hitpoints(a5)
	beq.s	.inv_done
	move	#25,ob_hitpoints(a5)
	; do not set ob_update here: damage is cancelled visually, so the HUD
	; should not flash/flicker on every invincible hit.
.inv_done
	tst	d7
	beq.s	.rts
	st	ob_update(a5)
.rts	rts

trainer_update_yesno3
	; a0 points to YES/NO field, d0 flag (>0 = YES)
	tst	d0
	ble.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_blob_text
	lea	game_blob,a0
	lea	21(a0),a0
	move	g2_blobshadow,d0
	bra	trainer_update_yesno3

trainer_update_reflection_text
	; c87b38: render NO / WEAPON / ALL in the six-character value field.
	lea	game_reflections,a0
	lea	21(a0),a0
	moveq	#5,d1
.clear	move.b	#' ',(a0)+
	dbf	d1,.clear
	lea	game_reflections,a0
	lea	21(a0),a0
	move	g2_reflections,d0
	cmp	#2,d0
	beq.s	.weapon
	tst	d0
	ble.s	.no
	move.b	#'A',(a0)+
	move.b	#'L',(a0)+
	move.b	#'L',(a0)+
	rts
.weapon
	move.b	#'W',(a0)+
	move.b	#'E',(a0)+
	move.b	#'A',(a0)+
	move.b	#'P',(a0)+
	move.b	#'O',(a0)+
	move.b	#'N',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	rts

trainer_update_visibility_text
	lea	game_visibility,a0
	lea	21(a0),a0
	moveq	#7,d1
.clear	move.b	#' ',(a0)+
	dbf	d1,.clear
	lea	game_visibility,a0
	lea	21(a0),a0
	tst	g2_visibility
	bgt.s	.advanced
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'F',(a0)+
	move.b	#'A',(a0)+
	move.b	#'U',(a0)+
	move.b	#'L',(a0)+
	move.b	#'T',(a0)+
	rts
.advanced
	move.b	#'A',(a0)+
	move.b	#'D',(a0)+
	move.b	#'V',(a0)+
	move.b	#'A',(a0)+
	move.b	#'N',(a0)+
	move.b	#'C',(a0)+
	move.b	#'E',(a0)+
	move.b	#'D',(a0)+
	rts

trainer_update_inv_text
	lea	game_inv,a0
	lea	21(a0),a0
	tst	trainer_invincible
	beq.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_bouncy_text
	lea	game_bouncy,a0
	lea	21(a0),a0
	tst	trainer_bouncy
	beq.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_onehit_text
	lea	game_onehit,a0
	lea	21(a0),a0
	tst	trainer_onehit
	beq.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	rts

trainer_update_weapon_text
	lea	game_weapon,a0
	lea	21(a0),a0
	move	trainer_weapon,d0
	bra	trainer_write_default_or_digit

trainer_update_boost_text
	lea	game_boost,a0
	lea	21(a0),a0
	move	trainer_boost,d0
	bra	trainer_write_default_or_digit

trainer_write_default_or_digit
	move.l	a0,-(a7)
	moveq	#7,d1
.clear	move.b	#' ',(a0)+
	dbf	d1,.clear
	move.l	(a7)+,a0
	tst	d0
	bne.s	.digit
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'F',(a0)+
	move.b	#'A',(a0)+
	move.b	#'U',(a0)+
	move.b	#'L',(a0)+
	move.b	#'T',(a0)+
	rts
.digit	add	#'0',d0
	move.b	d0,(a0)
	rts

trainer_update_display_texts
	movem.l	d0-d7/a0-a6,-(a7)
	bsr	g2stock_enforce_effects_off
	bsr	trainer_update_resolution_text
	bsr	trainer_update_bayer_text
	bsr	trainer_update_floor_text
	bsr	trainer_update_ceiling_text
	bsr	trainer_update_blob_text
	bsr	trainer_update_reflection_text
	bsr	trainer_update_visibility_text
	bsr	trainer_update_inv_text
	bsr	trainer_update_bouncy_text
	bsr	trainer_update_onehit_text
	bsr	trainer_update_weapon_text
	bsr	trainer_update_boost_text
	movem.l	(a7)+,d0-d7/a0-a6
	rts

trainer_prev_resolution
	move	g2_resolution,d0
	subq	#1,d0
	bpl.s	.store
	moveq	#3,d0
.store	move	d0,g2_resolution
	move	#-1,g2resolution_menu_changed	;c87b69f: apply native WIDE raster on CONTINUE
	bra.s	trainer_update_resolution_text

trainer_next_resolution
	move	g2_resolution,d0
	addq	#1,d0
	cmp	#4,d0
	blo.s	.store
	moveq	#0,d0
.store	move	d0,g2_resolution
	move	#-1,g2resolution_menu_changed	;c87b69f: apply native WIDE raster on CONTINUE

trainer_update_resolution_text
	move	g2_resolution,d0
	cmp	#3,d0
	bls.s	.valid
	moveq	#0,d0
	move	d0,g2_resolution
.valid
	lea	trainer_resolution_values,a1
	lsl	#2,d0
	move.l	0(a1,d0.w),a1
	lea	game_resolution,a0
	lea	21(a0),a0
	moveq	#15,d1
.blank	move.b	#' ',(a0)+
	dbf	d1,.blank
	lea	game_resolution,a0
	lea	21(a0),a0
.copy	move.b	(a1)+,d0
	beq.s	.done
	move.b	d0,(a0)+
	bra.s	.copy
.done	rts

 ; Step 1: runtime choice; 0=YES, -1=NO. STOCK keeps its original lock.
trainer_toggle_bayer
	tst	g2stock_enabled
	bne.s	.locked
	not.w	g2_bayer_disabled
	bra.s	trainer_update_bayer_text
.locked
	move	#-1,g2_bayer_disabled
trainer_update_bayer_text
	; Step 1b: disabling Bayer also disables reflections immediately.
	; Re-enabling Bayer leaves reflections OFF until selected explicitly.
	tst	g2_bayer_disabled
	beq.s	.text
	move	#-1,g2_reflections
	bsr	trainer_update_reflection_text
.text
	lea	game_bayer+21,a0
	tst	g2_bayer_disabled
	bne.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)
	rts
.no
	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)
	rts

trainer_update_floor_text
	lea	game_floor,a0
	lea	21(a0),a0
	move	floorflag,d0		;c87b19a: absolute range-safe
	bmi.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.shaded	move.b	#'S',(a0)+
	move.b	#'H',(a0)+
	move.b	#'A',(a0)+
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'D',(a0)+
	rts

trainer_update_ceiling_text
	lea	game_ceil,a0
	lea	21(a0),a0
	move	roofflag,d0		;c87b19a: absolute range-safe
	bmi.s	.no
	move.b	#'Y',(a0)+
	move.b	#'E',(a0)+
	move.b	#'S',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.no	move.b	#'N',(a0)+
	move.b	#'O',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	rts
.shaded	move.b	#'S',(a0)+
	move.b	#'H',(a0)+
	move.b	#'A',(a0)+
	move.b	#'D',(a0)+
	move.b	#'E',(a0)+
	move.b	#'D',(a0)+
	rts


g2v17_wait_menu_release
	movem.l	d0,-(a7)
.g2v17_wmr_loop
	jsr	vwait
	jsr	readmenujoy
	bne.s	.g2v17_wmr_loop
	movem.l	(a7)+,d0
	rts

calcoffset	move	#320,d0
	sub	width,d0		;c87b19a: absolute range-safe
	lsr	#4,d0
	ext.l	d0
	;
	move	#240,d1
	sub	hite,d1		;c87b19a: absolute range-safe
	lsr	#1,d1
	mulu	linemodw,d1		;c87b21a: absolute range-safe
	add.l	d1,d0
	move.l	d0,offset
	;
	rts

; v190hx7: VIEW SIZE full-FOV scaling helpers.
; Projection still computes the original 320x240 full-screen coordinates, then
; these helpers scale the result down to the selected render window.  That makes
; small VIEW SIZE modes render the whole scene at lower resolution instead of
; showing only a cropped centre slice.
g2view_scale_x_d0
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_wide_mode
	beq.s	.g2c87w1_scale_standard
	tst	p96gameplay_linear_active
	beq.s	.g2c87w1_scale_standard
	; c87b69e: native WIDE normally needs no 320-based rescale.  During
	; RESOLUTION, however, project native 428-wide coordinates into the compact
	; 200/214 raster using the saved native width as denominator.
	tst.w	g2resolution_active
	beq.s	.rts
	move.l	d1,-(a7)
	ext.l	d0
	move	width,d1
	muls	d1,d0
	move	g2resolution_saved_width,d1
	divs	d1,d0
	move.l	(a7)+,d1
	rts
.g2c87w1_scale_standard
	cmp	#320,width
	beq.s	.rts
	move.l	d1,-(a7)
	ext.l	d0
	move	width,d1
	muls	d1,d0
	move	#320,d1
	divs	d1,d0
	move.l	(a7)+,d1
.rts	rts

g2view_scale_x_d2
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_wide_mode
	beq.s	.g2c87w1_scale_standard
	tst	p96gameplay_linear_active
	beq.s	.g2c87w1_scale_standard
	tst.w	g2resolution_active
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d2,d0
	ext.l	d0
	move	width,d1
	muls	d1,d0
	move	g2resolution_saved_width,d1
	divs	d1,d0
	move	d0,d2
	movem.l	(a7)+,d0-d1
	rts
.g2c87w1_scale_standard
	cmp	#320,width
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d2,d0
	ext.l	d0
	move	width,d1
	muls	d1,d0
	move	#320,d1
	divs	d1,d0
	move	d0,d2
	movem.l	(a7)+,d0-d1
.rts	rts

g2view_scale_x_d3
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_wide_mode
	beq.s	.g2c87w1_scale_standard
	tst	p96gameplay_linear_active
	beq.s	.g2c87w1_scale_standard
	tst.w	g2resolution_active
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d3,d0
	ext.l	d0
	move	width,d1
	muls	d1,d0
	move	g2resolution_saved_width,d1
	divs	d1,d0
	move	d0,d3
	movem.l	(a7)+,d0-d1
	rts
.g2c87w1_scale_standard
	cmp	#320,width
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d3,d0
	ext.l	d0
	move	width,d1
	muls	d1,d0
	move	#320,d1
	divs	d1,d0
	move	d0,d3
	movem.l	(a7)+,d0-d1
.rts	rts

g2view_scale_y_d0
	; c87b69c: TWO PLAYER 1x2 and 2x2 both render half as many rows.
	; 1x1 and 2x1 retain the established split-local Y projection.
	tst.w	g2twop_quality_mode
	beq.s	.g2c87b62_normal
	cmp.w	#2,g2twop_quality_mode
	bcs.s	.rts
	asr.w	#1,d0
	rts
.g2c87b62_normal
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_normal
	tst	p96gameplay_linear_active
	beq.s	.g2c87p1_normal
	; c87b69e: 5:4 owns a native 256-row projection.  When RESOLUTION halves
	; Y, scale against that saved native height instead of returning unscaled.
	tst.w	g2resolution_active
	beq.s	.rts
	move.l	d1,-(a7)
	ext.l	d0
	move	hite,d1
	muls	d1,d0
	move	g2resolution_saved_hite,d1
	divs	d1,d0
	move.l	(a7)+,d1
	rts
.g2c87p1_normal
	cmp	#240,hite
	beq.s	.rts
	move.l	d1,-(a7)
	ext.l	d0
	move	hite,d1
	muls	d1,d0
	move	#240,d1
	divs	d1,d0
	move.l	(a7)+,d1
.rts	rts

g2view_scale_y_d1
	; c87b69c: TWO PLAYER 1x2 and 2x2 both render half as many rows.
	; 1x1 and 2x1 retain the established split-local Y projection.
	tst.w	g2twop_quality_mode
	beq.s	.g2c87b62_normal
	cmp.w	#2,g2twop_quality_mode
	bcs.s	.rts
	asr.w	#1,d1
	rts
.g2c87b62_normal
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_normal
	tst	p96gameplay_linear_active
	beq.s	.g2c87p1_normal
	tst.w	g2resolution_active
	beq.s	.rts
	movem.l	d0/d2,-(a7)
	move	d1,d0
	ext.l	d0
	move	hite,d2
	muls	d2,d0
	move	g2resolution_saved_hite,d2
	divs	d2,d0
	move	d0,d1
	movem.l	(a7)+,d0/d2
	rts
.g2c87p1_normal
	cmp	#240,hite
	beq.s	.rts
	; v190hx10: keep d1 scaled. hx7 restored d1 here, so sprite/blood
	; Y positions stayed full-size while their heights were already scaled.
	movem.l	d0/d2,-(a7)
	move	d1,d0
	ext.l	d0
	move	hite,d2
	muls	d2,d0
	move	#240,d2
	divs	d2,d0
	move	d0,d1
	movem.l	(a7)+,d0/d2
.rts	rts

g2view_scale_y_d3
	; c87b69c: TWO PLAYER 1x2 and 2x2 both render half as many rows.
	; 1x1 and 2x1 retain the established split-local Y projection.
	tst.w	g2twop_quality_mode
	beq.s	.g2c87b62_normal
	cmp.w	#2,g2twop_quality_mode
	bcs.s	.rts
	asr.w	#1,d3
	rts
.g2c87b62_normal
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_normal
	tst	p96gameplay_linear_active
	beq.s	.g2c87p1_normal
	tst.w	g2resolution_active
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d3,d0
	ext.l	d0
	move	hite,d1
	muls	d1,d0
	move	g2resolution_saved_hite,d1
	divs	d1,d0
	move	d0,d3
	movem.l	(a7)+,d0-d1
	rts
.g2c87p1_normal
	cmp	#240,hite
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d3,d0
	ext.l	d0
	move	hite,d1
	muls	d1,d0
	move	#240,d1
	divs	d1,d0
	move	d0,d3
	movem.l	(a7)+,d0-d1
.rts	rts

g2view_scale_y_d4
	; c87b69c: TWO PLAYER 1x2 and 2x2 both render half as many rows.
	; 1x1 and 2x1 retain the established split-local Y projection.
	tst.w	g2twop_quality_mode
	beq.s	.g2c87b62_normal
	cmp.w	#2,g2twop_quality_mode
	bcs.s	.rts
	asr.w	#1,d4
	rts
.g2c87b62_normal
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_normal
	tst	p96gameplay_linear_active
	beq.s	.g2c87p1_normal
	tst.w	g2resolution_active
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d4,d0
	ext.l	d0
	move	hite,d1
	muls	d1,d0
	move	g2resolution_saved_hite,d1
	divs	d1,d0
	move	d0,d4
	movem.l	(a7)+,d0-d1
	rts
.g2c87p1_normal
	cmp	#240,hite
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d4,d0
	ext.l	d0
	move	hite,d1
	muls	d1,d0
	move	#240,d1
	divs	d1,d0
	move	d0,d4
	movem.l	(a7)+,d0-d1
.rts	rts

g2view_unscale_y_d6
	; c87b69c: inverse of the split half-height projection above.
	; 1x2 and 2x2 map compact rows back to the native split height.
	tst.w	g2twop_quality_mode
	beq.s	.g2c87b62_normal
	cmp.w	#2,g2twop_quality_mode
	bcs.s	.rts
	add.w	d6,d6
	rts
.g2c87b62_normal
	; c86n: in TWO PLAYER crop/window mode the renderer already uses
	; the split-local logical Y range.  Do not unscale back to 240 here,
	; otherwise floor/ceiling projection swims independently from walls.
	tst	g2twop_crop_mode
	bne.s	.rts
	tst	g2p96_oneone_mode
	beq.s	.g2c87p1_normal
	tst	p96gameplay_linear_active
	beq.s	.g2c87p1_normal
	tst.w	g2resolution_active
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d6,d0
	ext.l	d0
	move	g2resolution_saved_hite,d1
	muls	d1,d0
	move	hite,d1
	divs	d1,d0
	move	d0,d6
	movem.l	(a7)+,d0-d1
	rts
.g2c87p1_normal
	cmp	#240,hite
	beq.s	.rts
	movem.l	d0-d1,-(a7)
	move	d6,d0
	ext.l	d0
	move	#240,d1
	muls	d1,d0
	move	hite,d1
	divs	d1,d0
	move	d0,d6
	movem.l	(a7)+,d0-d1
.rts	rts

refresh	jsr	dispoff
	jsr	finitmenu
	jsr	g2v190aj_restore_game_palette	; v190aj: leave font palette before drawing refreshed backdrop
	jsr	predrawall
	tst	game_menu_active
	beq.s	.g2v190aj_refresh_nogrey
	jsr	g2v190aj_grey_menu_backdrop
.g2v190aj_refresh_nogrey
	lea	gamemenu,a4
	jsr	initmenu2
	jsr	dispon
	; c87b79y: initmenu2 already publishes the direct indexed P96 menu.
	; Native AGA/ECS use their normal planar display and need no P96 bridge.
	rts

drawchunky	;draw a chunky shape on a 320 wide chunkymap
	;
	;d0=x,d1=y,d2=shape#,a0=shapetable
	;
	move.l	panel,a0	;c87b68a: GenAm PC-range buildfix
	; fall through with panel as source table
g2drawchunky_a0	;a0=shapetable, d0=x,d1=y,d2=shape#
	add	#224,d1
	;
	movem.l	d2-d5/a2-a4,-(a7)
	;
	move.l	chunky,a1	;c87b68a: GenAm PC-range buildfix
	mulu	g2render_stride,d1	;c87b21a: absolute range-safe
	add.l	d1,a1	;left
	lea	coloffs,a2
	lea	0(a2,d0*4),a2	;coloff
	;
	add.l	12(a0,d2*4),a0	;start of shape!
	addq	#4,a0	;skip handles
	movem	(a0)+,d2-d3	;width, height
	subq	#1,d2
	subq	#1,d3
	moveq	#0,d5
	move	g2render_stride,d5	;c87b21a: absolute range-safe; active chunky row stride
	moveq	#0,d0
	move.l	palettes,a4		;c87b21b: absolute range-safe
.hloop	move	d3,d4	;start of column
	move.l	a1,a3
	add.l	(a2)+,a3
.vloop	move.b	(a0)+,d0
	beq.s	.skip
	move.b	0(a4,d0),(a3)	;v64: normal shapes still need active palette remap
.skip	add.l	d5,a3
	dbf	d4,.vloop
	dbf	d2,.hloop
	;
	movem.l	(a7)+,d2-d5/a2-a4
	rts


; v47: final retail CrM2 smallfont2.bin has the full green statusbar
; background one entry later than the public source smallfont2.bin.  Public
; data:  #47 = 320px bar, #46 = middle clear.
; Retail: #48 = 320px bar, #49 = middle clear, #47/#46 are tiny pieces.
; Detect the shape width at runtime so both data sets work.
g2draw_statusbar_base
	; v190gi: lower smallfont2 statusbar background disabled.
	rts

g2draw_statusbar_clear
	; v190gi: lower smallfont2 statusbar clear strip disabled.
	rts

; v20: keep the original 224..239 chunky panel source deterministic.
; The real status strip is the 13-line shape #47; the remaining three
; visible lines are explicitly black so C2P never converts stale RAM.
g2clearpanelchunky
	movem.l	d0-d2/a0,-(a7)
	move.l	chunky,a0	;c87b68a: GenAm PC-range buildfix
	moveq	#0,d1
	move	g2render_stride,d1	;c87b21a: absolute range-safe
	move.l	d1,d2
	mulu	#224,d2
	adda.l	d2,a0
	mulu	#16,d1
	lsr.l	#2,d1
	subq.l	#1,d1
	moveq	#0,d0
.g2cpc_loop
	move.l	d0,(a0)+
	dbf	d1,.g2cpc_loop
	movem.l	(a7)+,d0-d2/a0
	rts

; v103: clear the whole chunky frame before C2P.  Used for teleport handoff:
; after the last visible blue/pixel frame we display black while the next
; intermission screen is loaded, instead of holding the final blue chamber view.
g2clearfullchunky
	movem.l	d0-d3/a0,-(a7)
	move.l	chunky,a0
	moveq	#0,d0
	move	g2render_stride,d0	;c87b69 native output stride
	mulu	#g2render_height_const,d0
	bsr	g2clear_bytes16
	movem.l	(a7)+,d0-d3/a0
	rts

; c87b69 / Gloombench 3O CLEAR16. Input: a0=start, d0.l=byte count.
; Handles full 64-byte groups plus longword/byte tails, so 428-wide P96
; and every 1x1/2x1/1x2/2x2 compact world raster are covered exactly.
g2clear_bytes16
	; Patch 11: use MOVE16 only on 040/060, aligned buffers and 16-byte sizes.
	cmp.w	#g2kalms_cpu_040,g2kalms_cpu_mode
	bne.w	.g2p11_clear_legacy
	move.l	a0,d1
	and.l	#15,d1
	bne.w	.g2p11_clear_legacy
	move.l	d0,d1
	and.l	#15,d1
	bne.w	.g2p11_clear_legacy
	cmp.l	#32,d0
	blo.w	.g2p11_clear_legacy
	move.l	a1,-(a7)
	move.l	a0,a1		; source trails destination by one cache line
	moveq	#0,d2
	move.l	d2,(a0)+	; seed first aligned 16-byte zero block
	move.l	d2,(a0)+
	move.l	d2,(a0)+
	move.l	d2,(a0)+
	sub.l	#16,d0
	lsr.l	#4,d0		; remaining 16-byte blocks
	subq.l	#1,d0
.g2p11_move16_loop
	; GenAm 3.18 buildfix: MOVE16 (a1)+,(a0)+ encoded directly.
	; 68040/68060 opcode words: source A1, destination A0.
	dc.w	$f621,$8000
	dbf	d0,.g2p11_move16_loop
	move.l	(a7)+,a1
	rts
.g2p11_clear_legacy
	moveq	#0,d2
	move.l	d0,d3
	move.l	d0,d1
	lsr.l	#6,d1
	beq.s	.long_tail
	subq.w	#1,d1
.block_loop
	rept	16
	move.l	d2,(a0)+
	endr
	dbf	d1,.block_loop
.long_tail
	move.l	d3,d1
	and.l	#63,d1
	move.l	d1,d0
	lsr.l	#2,d0
	beq.s	.byte_tail
	subq.w	#1,d0
.long_loop
	move.l	d2,(a0)+
	dbf	d0,.long_loop
.byte_tail
	and.w	#3,d1
	beq.s	.done
	subq.w	#1,d1
.byte_loop
	move.b	d2,(a0)+
	dbf	d1,.byte_loop
.done
	rts

; v61/v63: optional first-person gun overlay; v61/v63: optional first-person gun overlay from CrM2 gun.bin.
; gun.bin is a normal anim/shape file with its own palette.  The loader
; remaps it once at startup.  Index 0 stays transparent; index 1 is
; kept as opaque black so the weapon body has no see-through holes.
; v67 draws the already-remapped gun indices through the active palettes table,
; just like drawchunky, while still using coloffs layout.  This keeps the gun
; in one piece and maps its colours into the current display palette.
g2drawgun
	movem.l	d0-d7/a0-a5,-(a7)
	; v190gl: Classic Gloom can use the embedded/physical Gloom2 gun.bin fallback.
	move.l	gunpic,d0
	beq.w	.g2dg_done
	; v100: during the death fall, hide the first-person weapon completely.
	; ZGloom only leaves the red translucent screen / camera drop visible.
	move.l	player_,a5	;c87b43: range-safe absolute relocatable access
	jsr	g2c87b76a_prepare_weapon_visibility
	bne.w	.g2dg_done	; dead player only: warning phases always draw
	nop			; preserve the original 18-byte gate layout
.g2dg_player_ok
	move.l	d0,a0
	;
	; v68: ZGloom-style fire handling.  gun.bin shape #1 is the
	; recoil/firing weapon frame; shapes #2..#4 are muzzle flashes
	; selected by weapon group.  Draw the muzzle first, then the gun.
	clr.b	g2gun_recoilflag
	move	g2gun_firetimer,d7
	beq.s	.g2dg_normal_shape
	st	g2gun_recoilflag
	subq	#1,g2gun_firetimer
	moveq	#1,d6		;shape #1 = firing/recoil gun frame
	bra.s	.g2dg_have_shape_index
.g2dg_normal_shape
	moveq	#0,d6		;shape #0 = normal gun frame
.g2dg_have_shape_index
	lsl	#2,d6
	add	#12,d6		;anim offset table entry
	move.l	0(a0,d6.w),d0
	beq.w	.g2dg_done
	cmp.l	#$20000,d0
	bcc.w	.g2dg_done
	add.l	d0,a0		;a0 = shape
	;
	; shape header: xhandle,yhandle,width,height then column-major pixels.
	; ZGloom placement: x = centre - xhandle.  We keep the higher
	; Gloom2Reforged baseline from v65, and add recoil downward when fired.
	move	(a0),d0		;x handle
	move	g2render_center_x,d1	;c87b39: absolute relocatable access; PC-relative distance exceeds 16-bit range
	sub	d0,d1		;x
	move	6(a0),d3		;height
	move	hite,d4
	add	#26,d4		;c87p1: preserve the same 26px lower crop at 240 or 256 rows
	sub	d3,d4		;cropped naturally at lower screen edge
	tst.b	g2gun_recoilflag
	beq.s	.g2dg_no_recoil_y
	add	#2,d4		;v71: shorter, lighter firing recoil
.g2dg_no_recoil_y
	;
	; ZGloom bob is only used when not firing.
	tst.b	g2gun_recoilflag
	bne.s	.g2dg_bob_done
	move.l	player_,a5	;c87b68a: GenAm PC-range buildfix
	move	ob_bounce(a5),d0
	beq.s	.g2dg_bob_done
	lsr	#1,d0
	and	#255,d0
	move.l	camrots,a2	;c87b43: range-safe absolute relocatable access
	lea	0(a2,d0*8),a2
	move	2(a2),d0
	asr	#8,d0
	asr	#3,d0		;approx /2048 => about +/-16px
	add	d0,d1
	move	d0,d7
	bpl.s	.g2dg_bobpos
	neg	d7
.g2dg_bobpos
	lsr	#1,d7
	sub	d7,d4
.g2dg_bob_done
	; v71: draw animated muzzle flash first so the weapon sprite sits in front.
	tst.b	g2gun_recoilflag
	beq.s	.g2dg_no_muzzle
	bsr	g2drawgun_muzzle
.g2dg_no_muzzle
	bsr	g2drawgun_coloffs_shape_crop_left	;v99: hide stray left-edge non-transparent gun pixels
.g2dg_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Draw one gun.bin shape into the Gloom2 chunky/C2P column layout.
; In: a0 = shape, d1 = x, d4 = y.  Shape pixels are already remapped by
; remapanim, but still go through the active palettes table like drawchunky.
g2drawgun_coloffs_shape
	movem.l	d0-d7/a0-a5,-(a7)
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	tst	d2
	ble.w	.g2dgs_done
	cmp	#160,d2
	bhi.w	.g2dgs_done
	tst	d3
	ble.w	.g2dgs_done
	cmp	#128,d3
	bhi.w	.g2dgs_done
	cmp	hite,d4
	bge.w	.g2dgs_done
	move	hite,d5
	sub	d4,d5		;visible rows from y to bottom
	ble.w	.g2dgs_done
	cmp	d3,d5
	bls.s	.g2dgs_vhok
	move	d3,d5
.g2dgs_vhok
	move	d3,d6
	sub	d5,d6		;bytes to skip at bottom of every source column
	subq	#1,d5		;dbf visible height
	subq	#1,d2		;dbf width
	move.l	chunky,a1
	mulu	g2render_stride,d4	;c87b43: range-safe absolute relocatable access
	add.l	d4,a1		;destination row base
	ext.l	d1
	lea	coloffs,a2
	lea	0(a2,d1*4),a2	;C2P column layout, not linear x
	lea	8(a0),a0		;source pixels
	move.l	palettes,a4	;c87b68a: GenAm PC-range buildfix
	moveq	#0,d0
	tst.b	g2gun_dither50
	bne.w	.g2dgs_dither_begin
.g2dgs_xloop
	move.l	a1,a3
	add.l	(a2)+,a3
	move	d5,d7
.g2dgs_yloop
	move.b	(a0)+,d0
	beq.s	.g2dgs_skip
	move.b	0(a4,d0),(a3)
.g2dgs_skip
	adda.w	g2render_stride,a3	;c87b43: range-safe absolute relocatable access
	dbf	d7,.g2dgs_yloop
	adda.w	d6,a0
	dbf	d2,.g2dgs_xloop
	bra.w	.g2dgs_done

.g2dgs_dither_begin
	moveq	#0,d3		; local destination column for stable checkerboard
.g2dgs_dither_xloop
	move.l	a1,a3
	add.l	(a2)+,a3
	move	d5,d7
.g2dgs_dither_yloop
	move	d3,d0
	eor	d5,d0
	eor	d7,d0		; parity = local x + local y
	btst	#0,d0
	bne.s	.g2dgs_dither_skip_source
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.s	.g2dgs_dither_next
	move.b	0(a4,d0),(a3)
	bra.s	.g2dgs_dither_next
.g2dgs_dither_skip_source
	addq.l	#1,a0
.g2dgs_dither_next
	adda.w	g2render_stride,a3
	dbf	d7,.g2dgs_dither_yloop
	adda.w	d6,a0
	addq	#1,d3
	dbf	d2,.g2dgs_dither_xloop
.g2dgs_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; v99: draw the main first-person gun with a tiny left crop.  Some gun.bin
; variants contain a few non-zero pixels in the transparent left padding.  Do
; not restore the old index-1 transparency globally because that punched holes
; into the weapon body; crop the first four source columns for the gun.
g2drawgun_coloffs_shape_crop_left
	movem.l	d0-d7/a0-a5,-(a7)
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	cmp	#8,d2
	bls.w	.g2dgcl_done
	tst	d3
	ble.w	.g2dgcl_done
	cmp	#128,d3
	bhi.w	.g2dgcl_done
	cmp	hite,d4
	bge.w	.g2dgcl_done
	addq	#4,d1		;v105b: skip four transparent-padding columns on screen
	subq	#4,d2		;and in source width
	move	hite,d5
	sub	d4,d5
	ble.w	.g2dgcl_done
	cmp	d3,d5
	bls.s	.g2dgcl_vhok
	move	d3,d5
.g2dgcl_vhok
	move	d3,d6
	sub	d5,d6
	subq	#1,d5
	subq	#1,d2
	move.l	chunky,a1
	mulu	g2render_stride,d4	;c87b68a: GenAm PC-range buildfix
	add.l	d4,a1
	ext.l	d1
	lea	coloffs,a2
	lea	0(a2,d1*4),a2
	lea	8(a0),a0
	move	d3,d0
	lsl	#2,d0
	adda.w	d0,a0		;v105b: skip four column-major source columns
	move.l	palettes,a4
	moveq	#0,d0
	tst.b	g2gun_dither50
	bne.w	.g2dgcl_dither_begin
.g2dgcl_xloop
	move.l	a1,a3
	add.l	(a2)+,a3
	move	d5,d7
.g2dgcl_yloop
	move.b	(a0)+,d0
	beq.s	.g2dgcl_skip
	move.b	0(a4,d0),(a3)
.g2dgcl_skip
	adda.w	g2render_stride,a3	;c87b68a: GenAm PC-range buildfix
	dbf	d7,.g2dgcl_yloop
	adda.w	d6,a0
	dbf	d2,.g2dgcl_xloop
	bra.w	.g2dgcl_done

.g2dgcl_dither_begin
	moveq	#0,d3		; local cropped-gun column
.g2dgcl_dither_xloop
	move.l	a1,a3
	add.l	(a2)+,a3
	move	d5,d7
.g2dgcl_dither_yloop
	move	d3,d0
	eor	d5,d0
	eor	d7,d0		; parity = local x + local y
	btst	#0,d0
	bne.s	.g2dgcl_dither_skip_source
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.s	.g2dgcl_dither_next
	move.b	0(a4,d0),(a3)
	bra.s	.g2dgcl_dither_next
.g2dgcl_dither_skip_source
	addq.l	#1,a0
.g2dgcl_dither_next
	adda.w	g2render_stride,a3
	dbf	d7,.g2dgcl_dither_yloop
	adda.w	d6,a0
	addq	#1,d3
	dbf	d2,.g2dgcl_dither_xloop
.g2dgcl_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Draw one gun.bin shape scaled as solid pixel blocks in the same coloffs/C2P
; layout.  In: a0 = shape, d1 = x, d4 = y, d7 = integer scale factor 1..3.
g2drawgun_coloffs_shape_scaled
	cmp	#1,d7
	bhi.s	.g2dgss_go
	bra	g2drawgun_coloffs_shape
.g2dgss_go
	movem.l	d0-d7/a0-a6,-(a7)
	move	d7,d5		;scale
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	tst	d2
	ble.w	.g2dgss_done
	cmp	#160,d2
	bhi.w	.g2dgss_done
	tst	d3
	ble.w	.g2dgss_done
	cmp	#128,d3
	bhi.w	.g2dgss_done
	cmp	hite,d4
	bge.w	.g2dgss_done
	move	d2,d0
	mulu	d5,d0
	add	d1,d0
	cmp	g2render_width,d0
	bgt.w	.g2dgss_done
	move	d3,d0
	mulu	d5,d0
	add	d4,d0
	cmp	hite,d0
	bgt.w	.g2dgss_done
	move.l	chunky,a1
	mulu	g2render_stride,d4
	add.l	d4,a1		;base destination row
	ext.l	d1
	lea	coloffs,a6
	lea	8(a0),a5		;current source column
	move.l	palettes,a4
	subq	#1,d2		;dbf width
.g2dgss_xsrc
	move	d5,d6		;repeat this source column scale times
.g2dgss_xrep
	move.l	a1,a3
	lea	0(a6,d1*4),a2
	add.l	(a2),a3
	move.l	a5,a2		;source pixel ptr for this column
	move	d3,d4
	subq	#1,d4		;dbf source height
.g2dgss_ysrc
	moveq	#0,d0
	move.b	(a2)+,d0
	beq.s	.g2dgss_zero
	move.b	0(a4,d0.w),d0
	move	d5,d7
	subq	#1,d7
.g2dgss_yrep_nz
	move.b	d0,(a3)
	adda.w	g2render_stride,a3
	dbf	d7,.g2dgss_yrep_nz
	bra.s	.g2dgss_ynext
.g2dgss_zero
	move	d5,d7
	subq	#1,d7
.g2dgss_yrep_z
	adda.w	g2render_stride,a3
	dbf	d7,.g2dgss_yrep_z
.g2dgss_ynext
	dbf	d4,.g2dgss_ysrc
	addq	#1,d1
	subq	#1,d6
	bne.s	.g2dgss_xrep
	adda.w	d3,a5		;next source column (column-major layout)
	dbf	d2,.g2dgss_xsrc
.g2dgss_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Draw one gun.bin shape with a fractional nearest-neighbour scale.
; In: a0 = shape, d1 = x, d4 = y, d6 = numerator, d7 = denominator.
; Used for smaller follow-up muzzle flashes than the old 2x/3x steps.
g2drawgun_coloffs_shape_scalefrac
	movem.l	d0-d7/a0-a6,-(a7)
	move	4(a0),d2		;width
	move	6(a0),d3		;height
	tst	d2
	ble.w	.g2dgsf_done
	cmp	#160,d2
	bhi.w	.g2dgsf_done
	tst	d3
	ble.w	.g2dgsf_done
	cmp	#128,d3
	bhi.w	.g2dgsf_done
	cmp	hite,d4
	bge.w	.g2dgsf_done
	move	d2,d5
	mulu	d6,d5
	divu	d7,d5		;scaled width
	beq.w	.g2dgsf_done
	move	d3,d0
	mulu	d6,d0
	divu	d7,d0		;scaled height
	beq.w	.g2dgsf_done
	move	d5,d6
	add	d1,d6
	cmp	g2render_width,d6
	bgt.w	.g2dgsf_done
	move	d0,d6
	add	d4,d6
	cmp	hite,d6
	bgt.w	.g2dgsf_done
	move.l	chunky,a1
	mulu	g2render_stride,d4
	add.l	d4,a1		;base destination row
	move	d0,d4		;scaled height
	move	d1,d7		;base x
	ext.l	d7
	lea	coloffs,a6
	lea	8(a0),a5		;source base
	move.l	palettes,a4
	moveq	#0,d6		;dest x index
	tst.b	g2gun_dither50
	bne.w	.g2dgsf_dither_xloop
.g2dgsf_xloop
	cmp	d5,d6
	bge.w	.g2dgsf_done	; GenAmFix1: target beyond short range
	move	d6,d0
	mulu	d2,d0
	divu	d5,d0		;source x = dx * srcw / dstw
	mulu	d3,d0
	lea	0(a5,d0.w),a0	;source column base
	move	d7,d0
	add	d6,d0
	move.l	a1,a3
	lea	0(a6,d0*4),a2
	add.l	(a2),a3
	moveq	#0,d1		;dest y index
.g2dgsf_yloop
	cmp	d4,d1
	bge.s	.g2dgsf_xnext
	move	d1,d0
	mulu	d3,d0
	divu	d4,d0		;source y = dy * srch / dsth
	move.b	0(a0,d0.w),d0
	andi.l	#$ff,d0
	beq.s	.g2dgsf_skip
	move.b	0(a4,d0),(a3)
.g2dgsf_skip
	adda.w	g2render_stride,a3
	addq	#1,d1
	bra.s	.g2dgsf_yloop
.g2dgsf_xnext
	addq	#1,d6
	bra.s	.g2dgsf_xloop

; c87b74a: 50 percent checkerboard for the scaled muzzle flash.
.g2dgsf_dither_xloop
	cmp	d5,d6
	bge.w	.g2dgsf_done
	move	d6,d0
	mulu	d2,d0
	divu	d5,d0		;source x = dx * srcw / dstw
	mulu	d3,d0
	lea	0(a5,d0.w),a0
	move	d7,d0
	add	d6,d0
	move.l	a1,a3
	lea	0(a6,d0*4),a2
	add.l	(a2),a3
	moveq	#0,d1
.g2dgsf_dither_yloop
	cmp	d4,d1
	bge.s	.g2dgsf_dither_xnext
	move	d1,d0
	mulu	d3,d0
	divu	d4,d0
	move.b	0(a0,d0.w),d0
	andi.l	#$ff,d0
	beq.s	.g2dgsf_dither_skip
	move.l	d0,a2		; preserve palette index while checking parity
	move	d6,d0
	add	d1,d0		; local destination x+y checkerboard
	btst	#0,d0
	bne.s	.g2dgsf_dither_skip
	move.l	a2,d0
	move.b	0(a4,d0),(a3)
.g2dgsf_dither_skip
	adda.w	g2render_stride,a3
	addq	#1,d1
	bra.s	.g2dgsf_dither_yloop
.g2dgsf_dither_xnext
	addq	#1,d6
	bra.w	.g2dgsf_dither_xloop
.g2dgsf_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Draw the muzzle-flash shape from gun.bin.  ZGloom uses shapes #2..#4,
; selected as 2 + ((weapon + 1) / 2), so weapon 0/1 share the first flash,
; 2/3 share the second, and 4 uses the largest flash.
g2drawgun_muzzle
	movem.l	d0-d7/a0-a5,-(a7)
	move.l	gunpic,d0
	beq.w	.g2dm_done
	move.l	d0,a0
	; v73: match the muzzle flash to the current weapon upgrade like ZGloom:
	; shape = 2 + ((weapon + 1) / 2).  This gives matching flash art for
	; upgrades 0/1, 2/3 and 4, instead of cycling unrelated flash frames.
	move.l	player_,a5
	moveq	#0,d7
	tst.l	a5
	beq.s	.g2dm_have_weapon
	move	ob_weapon(a5),d7
	cmp	#4,d7
	bls.s	.g2dm_weapon_ok
	moveq	#4,d7
.g2dm_weapon_ok
	addq	#1,d7
	asr	#1,d7
	addq	#2,d7
.g2dm_have_weapon
	move	d7,d6
	lsl	#2,d6
	add	#12,d6
	move.l	0(a0,d6.w),d0
	beq.w	.g2dm_done
	cmp.l	#$20000,d0
	bcc.w	.g2dm_done
	add.l	d0,a0
	; v72: keep the flash behind the gun, but raise it far enough so the
	; upper/sides remain visible.  Bottom-aligning at 240 hid it entirely
	; behind the gun/statusbar in the Gloom2 C2P layout.
	move	4(a0),d0		;width
	move	g2render_width,d1
	sub	d0,d1
	asr	#1,d1		;centre by width, not xhandle
	move	6(a0),d3		;height
	move	#237,d4		;v190gi: muzzleflash follows gun moved down by 26px
	sub	d3,d4		;v76 base plus removed statusbar height
				;right at/just above the gun muzzle instead of being hidden too low
	; v79: keep the single-shape approach from v78, but reduce the follow-up
	; sizes by about 20%.  The 3-frame sequence is now 1x -> 1.6x -> 2.4x
	; instead of 1x -> 2x -> 3x.
	move	g2gun_firetimer,d5
	cmp	#2,d5
	beq.s	.g2dm_scale1
	cmp	#1,d5
	beq.s	.g2dm_scale16
	; firetimer == 0 on the last visible flash frame after g2drawgun already
	; decremented it.  Draw the same flash shape one more step larger.
.g2dm_scale24
	move	d0,d6
	moveq	#12,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d0,d6
	lsr	#1,d6
	sub	d6,d1		;centre 2.4x flash around the same muzzle point
	move	d3,d6
	moveq	#12,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d3,d6
	lsr	#1,d6
	sub	d6,d4
	moveq	#12,d6
	moveq	#5,d7
	bsr	g2drawgun_coloffs_shape_scalefrac
	bra.s	.g2dm_done
.g2dm_scale16
	move	d0,d6
	moveq	#8,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d0,d6
	lsr	#1,d6
	sub	d6,d1		;centre 1.6x flash
	move	d3,d6
	moveq	#8,d7
	mulu	d7,d6
	moveq	#5,d7
	divu	d7,d6
	sub	d3,d6
	lsr	#1,d6
	sub	d6,d4
	moveq	#8,d6
	moveq	#5,d7
	bsr	g2drawgun_coloffs_shape_scalefrac
	bra.s	.g2dm_done
.g2dm_scale1
	bsr	g2drawgun_coloffs_shape
.g2dm_done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Try all known Gloom/Gloom Deluxe/Zombie Massacre gun locations.
g2loadgunfallback
	movem.l	d0-d1/a0,-(a7)
	tst.l	gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_miscbin(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_stufbin(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_miscraw(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
	bne.s	.g2lg_done
	lea	g2gun_name_stufraw(pc),a0
	moveq	#1,d1
	jsr	loadfile
	move.l	d0,gunpic
.g2lg_done
	movem.l	(a7)+,d0-d1/a0
	rts

; gun.bin uses raw palette index 1 as transparent.  drawchunky skips 0,
; therefore convert index 1 to 0 before remapanim destroys the raw indices.
g2gun_prepare
	; v73: keep gun palette index 1 as a real black gun colour.
	; Earlier builds converted raw index 1 to 0 before remapanim, which
	; created transparent holes inside the weapon graphic.  gun.bin already
	; uses index 0 as transparency; index 1 must remain opaque black.
	rts

g2gun_name_miscbin	dc.b	'misc/gun.bin',0
	even
g2gun_name_stufbin	dc.b	'stuf/gun.bin',0
	even
g2gun_name_miscraw	dc.b	'misc/gun',0
	even
g2gun_name_stufraw	dc.b	'stuf/gun',0
	even

