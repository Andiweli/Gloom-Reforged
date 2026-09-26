entrypoint	;
	clr.l	map_test
	clr.l	g2display_cli_ptr	;c86zdv: optional DISPLAY= parser starts clean
	move.l	4.w,a6
	move.l	276(a6),a5	;task
	tst.l	$ac(a5)	;cli?
	bne.s	cli
	;
	lea	$5c(a5),a0
	jsr	-384(a6)	;waitport
	lea	$5c(a5),a0
	jsr	-372(a6)	;get message
	move.l	d0,wbmess
	bra	wb
g2ecs_profile_guard_enabled	equ	0	;c87b22: Gloom3/ZM Fast-EHB runtime paths are enabled

cli	;
	move.l	a0,g2display_cli_ptr	;c86zdv: scan full CLI line later for DISPLAY=AGA/P96/AUTO
	cmp.b	#'@',(a0)+
	bne.s	wb
	lea	tempfile,a1
	move.l	a1,map_test
.loop	move.b	(a0)+,(a1)
	beq.s	wb
	cmp.b	#10,(a1)+
	bne.s	.loop
	clr.b	-(a1)
wb	;
	lea	dosname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,dosbase
	;
	move.l	d0,a6
	jsr	-60(a6)
	move.l	d0,outhand
	;
	move.l	wbmess,d0
	beq.s	.nocd
	move.l	d0,a0
	move.l	$24(a0),a0
	move.l	(a0),d1
	move.l	dosbase,a6
	jsr	-126(a6)
.nocd	;
	jsr	g2chipset_detect	;c86zkm: cache ECS/AGA before display selection
	jsr	g2displaymode_probe	;c86zkm: parse bare AGA/ECS/P96 plus P96 options
	jsr	g2displaymode_apply_runtime	;ECS1: synchronize old 'aga' flag with selected display
	jsr	g2displaymode_validate	;c87b78s: only native AGA requires AGA hardware
	tst	d0
	bne	nomem
	ifne	g2ecs_profile_guard_enabled
	jsr	g2ecs_early_profile_preflight	;ECS9: DOS/Workbench notice before any game display
	tst	d0
	bne	nomem
	endc
	jsr	g2p96_probe	;c87b70d: passive Picasso96API.library probe only, no file output
	jsr	g2p96_modeid_probe	;c86zdx/c87b70b: filtered requester; CANCEL may abort startup
	jsr	g2p96_modeid_log_and_ecs_preflight_c87b78s	;c87b78s: log + ECS-host P96 open preflight
	tst	g2p96_req_abort_startup
	bne.w	nomem		;c87b70b: clean early exit before initmain/all display allocation
	; c87b70k: do not open throwaway P96 screens after mode selection.
	; The selected mode is validated by the one persistent title/game screen;
	; the old passive screen/window OpenScreen probes remain removed.
	move.l	4.w,a6
	moveq	#1,d1
	jsr	-216(a6)
	cmp.l	#$1a6548-$c000,d0 ;enough memory to run gloom?
	bcs	nomem
	;
	jsr	initmain
	tst	g2p96_fatal_open_error_c87b79o
	bne.w	exittoos		;c87b79o: selected P96 failed, never open a native display behind it
	jsr	g2cfg_load	;v141: normal Gloom Reforged config load
	jsr	g2stock_capture_cfg_options	;c87b67: preserve saved choices before STOCK overlay
	jsr	g2stock_enforce_effects_off	;c87b67: runtime only; gloom.cfg remains unchanged
	jsr	g2basic_log_reset	;c87b26: create RAM:gloom_basic.log + startup snapshot
	;
	bsr	g2v190ct_titlefont
	jsr	g2ecs2_asset_notice	;ECS2: visible warning when required ECS data was not loaded
	jsr	g2v190i_levelselect_loadscripts	; v190i: build START LEVEL list from script file before title menu
	;
	; Normal Gloom Reforged title/episode flow.
	; v41x diagnostic: bigfont returned, continue to title music start.
	;
.intro	jsr	g2p96_display_enter_title	;c86zfq: native P96 title/menu owns display
	tst	g2p96_fatal_open_error_c87b79o
	bne.w	exittoos		;c87b79o: P96-or-exit contract
	jsr	g2v190p_load_title_assets	; v190p: reload title art if gameplay freed it
	; v190go: Classic Gloom now uses embedded Gloom2 title/menu assets too,
	; so the old unsupported-profile title-music skip must not run anymore.
	move.l	medat,a1
	move.l	titlemed,d0	; v190cr: compatible installs may not have title MED
	beq.s	.g2v190cr_no_title_music
	move.l	d0,a0
	jsr	8(a1)	;start title music!
.g2v190cr_no_title_music
	;
.intro2	jsr	g2v36_clear_title_buffers	;v36: clear both OS bitmaps before returning to title menu
	jsr	dointro	;returns gametype
	; v08: previous diagnostic hold after dointro removed.
	; Continue into gametype handling after menu selection.
	;
	cmp	#3,gametype
	bcs.s	.play
	move.l	medat,a1
	jsr	12(a1)
	bra	exittoos	;c87b26a: GenAm range-safe buildfix
.play	;
	jsr	g2p96_transition_clear_all_p96_if_open_c87b79c	;c87b79c: clear both P96 pages before new game setup
	jsr	initnewgame
	tst	gametype
	bmi	.intro2
	; c86zhk: when starting a new game after returning to the title menu, the
	; P96 bridge may still be open and p96gameplay_delay_counter may still be
	; >= 12 from the previous level.  If we enter the gameplay presenter with
	; that old counter, it immediately copies the last old chunky/game frame
	; just before the next intermission picture.  Reset the startup delay and
	; blank once more so the handoff stays black until real new content appears.
	clr	p96gameplay_delay_counter
	clr	p96gameplay_latched
	move	#-1,p96newgame_hold_black_c87b79c
	jsr	g2p96_transition_clear_all_p96_if_open_c87b79c
	jsr	g2p96_gameplay_present_probe	;c87b79c: pre-open/keep black; never publish prior game's chunky page
	tst	g2p96_fatal_open_error_c87b79o
	bne.w	exittoos		;c87b79o: gameplay P96 open failure is fatal, not planar fallback
	jsr	g2basic_log_game_once	;c87b26: selected output/game geometry snapshot
	jsr	g2v190p_free_title_assets	; v190p: free title art during gameplay to keep memory contiguous
	;
	;bsr	smallfont
	tst	twowins
	beq.s	.n2
	bsr	swaphflags
.n2	jsr	execscript_med
.wmf	tst	fadevol
	bne.s	.wmf
	tst	twowins
	beq.s	.n22
	bsr	swaphflags
.n22	jsr	g2p96_transition_clear_all_p96_if_open_c87b79c	;c87b79c: blank both P96 pages on game->title handoff
	jsr	g2p96_display_enter_title	;c86zfq: native P96 title/menu owns display
	tst	g2p96_fatal_open_error_c87b79o
	bne.w	exittoos		;c87b79o: do not revive the native screen after a P96 reopen failure
	bsr	g2v190ct_titlefont
	bra	.intro
	;
exittoos	jsr	g2p96_display_shutdown	;c86zfq: central shutdown display-state close
	jsr	inputoff	; v34: restore ciaa/rawkey vectors before OS exit/closewindow
	jsr	g2cfg_save	;v141: persist menu/options on clean exit
	jsr	freeobjlist2
	jsr	permit
	jsr	finitdisplay
	jsr	finitvbint
	jsr	finitsfx
	jsr	finitser
	jsr	freememlist
	ifeq	cd32
	jsr	undir
	endc
	;
nomem	move.l	wbmess,d0
	beq.s	.bye
	;
	move.l	4.w,a6
	move.l	d0,a1
	jsr	-378(a6)
	clr.l	wbmess
	;
.bye	; v190hy cleanup: logger call removed
	rts

; ************* FAST SUBS ********************
	
fastsubs

swaphflags	movem.l	floorflag,d0-d1	;c86zdc: absolute access, avoids GenAm PC-range growth after startup guards
	move.l	d1,floorflag
	move.l	d0,floorflag2
	rts

smallfont	move	#6,fontw
	move	#8,fonth
	move.l	smallfont_,font
	rts

bigfont	move	#8,fontw
	move	#10,fonth
	move.l	bigfont_,font
	rts

; v190gl: all profiles, including Classic Gloom with embedded fallbacks,
; use the normal Gloom2 bigfont2 menu font path.
g2v190ct_titlefont
	bsr	bigfont
	rts

encodejoy	;a0=cntrl block to encode...
	;return d0 encoded
	;
	;bit:
	;0 = joyx -1
	;1 = joyx 1
	;2 = joyy -1
	;3 = joyy 1
	;4 = joyb true
	;5 = joys true
	;
	moveq	#0,d0
	;
	tst	(a0)
	beq.s	.skipx
	bpl.s	.x1
	bset	#0,d0
	bra.s	.skipx
.x1	bset	#1,d0
.skipx	tst	2(a0)
	beq.s	.skipy
	bpl.s	.y1
	bset	#2,d0
	bra.s	.skipy
.y1	bset	#3,d0
.skipy	tst	4(a0)
	beq.s	.skipb
	bset	#4,d0
.skipb	tst	6(a0)
	beq.s	.skipf
	bset	#5,d0
.skipf	;
	rts

decodejoy	;
	;d0.b = encoded byte...
	;a0 = block to fill
	;
	;0 = joyx -1
	;1 = joyx 1
	;2 = joyy -1
	;3 = joyy 1
	;4 = joyb true
	;5 = joys true
	;
	clr	(a0)
	move	d0,d1
	and	#3,d1
	beq.s	.skipx
	cmp	#1,d1
	bne.s	.x1
	move	#-1,(a0)
	bra.s	.skipx
.x1	move	#1,(a0)
.skipx	clr	2(a0)
	move	d0,d1
	and	#12,d1
	beq.s	.skipy
	cmp	#4,d1
	bne.s	.y1
	move	#-1,2(a0)
	bra.s	.skipy
.y1	move	#1,2(a0)
.skipy	btst	#4,d0
	sne	d1
	ext	d1
	move	d1,4(a0)
	btst	#5,d0
	sne	d1
	ext	d1
	move	d1,6(a0)
	rts

sfxs	;
sfx0	ds.b	fx_size
sfx1	ds.b	fx_size
sfx2	ds.b	fx_size
sfx3	ds.b	fx_size

sfxintserver0	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx0
	dc.l	sfxint

sfxintserver1	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx1
	dc.l	sfxint

sfxintserver2	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx2
	dc.l	sfxint

sfxintserver3	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	sfx3
	dc.l	sfxint

initsfx	push
	move.l	4.w,a6
	;
	moveq	#7,d0
	lea	sfxintserver0,a1
	jsr	-162(a6)	;setintvector
	;
	moveq	#8,d0
	lea	sfxintserver1,a1
	jsr	-162(a6)
	;
	moveq	#9,d0
	lea	sfxintserver2,a1
	jsr	-162(a6)
	;
	moveq	#10,d0
	lea	sfxintserver3,a1
	jsr	-162(a6)
	;
	lea	sfxs(pc),a1
	move	#$80,d0
	moveq	#1,d1
	moveq	#0,d2
	moveq	#3,d3
.loop	bsr	.init
	lea	fx_size(a1),a1
	dbf	d3,.loop
	;
	pull
	rts
	;
.init	clr	fx_status(a1)
	move	d0,fx_int(a1)
	move	d1,fx_dma(a1)
	move	d2,fx_offset(a1)
	add	d0,d0
	add	d1,d1
	add	#16,d2
	rts

finitsfx	push
	move.l	4.w,a6
	;
	moveq	#7,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	move.l	4.w,a6
	moveq	#8,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	move.l	4.w,a6
	moveq	#9,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	move.l	4.w,a6
	moveq	#10,d0
	sub.l	a1,a1
	jsr	-162(a6)
	;
	pull
	rts

; v190ep: exit safety for Paula SFX.  Some recent local-event sounds can still
; be active when the player leaves the game/menu.  Kill all four audio DMAs and
; their interrupt bits before config save/freeing, so Paula cannot keep reading
; sample memory during shutdown.
g2v190ep_stop_all_sfx
	movem.l	d0-d2/a1-a2,-(a7)
	lea	sfxs(pc),a1
	moveq	#3,d2
.g2v190ep_stop_loop
	clr	fx_status(a1)
	bsr	sfxoff
	lea	fx_size(a1),a1
	dbf	d2,.g2v190ep_stop_loop
	move	#$000f,$dff096	; clear AUD0..AUD3 DMA
	move	#$0780,$dff09a	; clear AUD0..AUD3 interrupt enable
	move	#$0780,$dff09c	; clear pending AUD0..AUD3 interrupt requests
	movem.l	(a7)+,d0-d2/a1-a2
	rts

waitquiet	jsr	vwait
	lea	sfxs(pc),a0
	moveq	#3,d0
.loop	tst	fx_status(a0)
	bne.s	waitquiet
	lea	fx_size(a0),a0
	dbf	d0,.loop
	rts

playsfx	;sfx file in a0, vol in d0, priority in d1
	;
	;move	#$4000,$dff09a	;snd/vb ints off
	;
	lea	sfxs(pc),a1
	moveq	#3,d2
.loop	tst	fx_status(a1)
	beq.s	makesfx
	lea	fx_size(a1),a1
	dbf	d2,.loop
	;
	;OK, none free...check priorities
	;
	lea	sfxs(pc),a1
	moveq	#3,d2
.loop2	cmp	fx_priority(a1),d1
	bgt.s	queuesfx
	lea	fx_size(a1),a1
	dbf	d2,.loop2
	;
	;no-can-do!
	;
	;move	#$c000,$dff09a
	rts
	;
queuesfx	;OK, turn off other and play US!
	;
	move	#1,fx_status(a1)
	move	d0,fx_vol(a1)
	move	d1,fx_priority(a1)
	move.l	a0,fx_sfx(a1)	;play me next!
	;
	bsr	sfxoff
	;
	;move	#$c000,$dff09a
	rts

sfxoff	lea	$dff0a0,a2
	add	fx_offset(a1),a2
	move.l	chipzero,(a2)
	move	#1,4(a2)	;len
	move	#0,8(a2)	;vol
	move	fx_int(a1),$dff09a
	move	fx_dma(a1),$dff096
	rts

makesfx	;OK, play this SFX NOW!
	;
	move	d1,fx_priority(a1)
	move	d0,fx_vol(a1)
	bsr	playsfxnow
	;move	#$c000,$dff09a
	rts

playsfxnow	move	#-2,fx_status(a1)
	;
	lea	$dff0a0,a2
	add	fx_offset(a1),a2
	move	(a0)+,6(a2)	;period
	move	(a0)+,4(a2)	;len
	move	fx_vol(a1),8(a2)	;vol
	move.l	a0,(a2)	;data
	;
	move	fx_dma(a1),d0	;dma bits
	or	#$8000,d0
	move	fx_int(a1),d1	;int bits
	move	d1,d2
	or	#$8000,d1
	;
	move	d0,$dff096	;dma on!
	move	d1,$dff09a	;int en
	move	d2,$dff09c	;intreq clr
	;
	rts

sfxint	;interupt for sfx!
	;
	tst	fx_status(a1)
	bge.s	.skip
	addq	#1,fx_status(a1)
	blt.s	.skip
	;
	move.l	a2,-(a7)
	bsr	sfxoff
	move.l	(a7)+,a2
	;
.skip	move	fx_int(a1),$dff09c
	moveq	#0,d0
	rts

