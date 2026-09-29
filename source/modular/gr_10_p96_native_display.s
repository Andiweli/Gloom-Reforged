g2p96_probe	push
	clr.l	p96base
	clr	p96present
	clr	p96found
	move	g2display_mode(pc),d0
	cmp	#2,d0		;ECS1: only explicit P96 may touch the P96 library
	beq.s	.open
	move	#3,p96found	;log explicit non-P96 skip
	bra.s	.done
.open	move.l	4.w,a6
	lea	p96name(pc),a1
	jsr	-408(a6)	;OldOpenLibrary
	tst.l	d0
	bne.s	.got1
	move.l	4.w,a6
	lea	p96name2(pc),a1
	jsr	-408(a6)	;fallback name used by some installs/tools
	tst.l	d0
	beq.s	.done
	move	#2,p96found
	bra.s	.got
.got1	move	#1,p96found
.got	move.l	d0,p96base
	move	#-1,p96present
.done
	pull
	rts

; Legacy passive ModeID probe entry retained for compatibility.
g2p96_modeid_probe
	jmp	g2rc4_p96_mode_requester_probe_v21

; d0.w width, d1.w height, d2.w mode. Patch only the live persistent
; P96 window/bitmap target fields that must agree with the ModeID resolution.
g2p96_set_target_mode
	push
	move	d0,p96target_width
	move	d1,p96target_height
	move	d2,p96target_mode
	and.l	#$0000ffff,d0
	and.l	#$0000ffff,d1
	move.l	d0,p96winprobe_width_tag+4
	move.l	d1,p96winprobe_height_tag+4
	move	p96target_width,p96winprobe_window_size
	move	p96target_height,p96winprobe_window_size+2
	pull
	rts

g2p96_modeid_log
	; c87b70l: deliberately not behind the legacy diagnostic switch. This is
	; the one-purpose user file from which the exact ToolType can be copied.
	movem.l	d0-d3/d7/a0-a1/a6,-(a7)
	move.l	dosbase,d0
	beq.w	.done
	move.l	d0,a6
	cmp	#1,p96modeid_state
	bne	.have_text
	move.l	p96modeid,d0
	lea	p96modeid_hex,a0
	jsr	g2p96_long_to_hex8
	move	p96target_width,d0
	lea	p96modeid_width_hex,a0
	jsr	g2p96_word_to_hex4
	move	p96target_height,d0
	lea	p96modeid_height_hex,a0
	jsr	g2p96_word_to_hex4
	move	p96modeid_depth,d0
	lea	p96modeid_depth_hex,a0
	jsr	g2p96_word_to_hex4
.have_text
	lea	p96modeid_log_name,a0
	move.l	a0,d1
	move.l	#1006,d2	; MODE_NEWFILE: also removes stale prior-run content
	jsr	-30(a6)	; Open
	move.l	d0,d7
	beq.w	.done
	move	p96modeid_state,d0
	cmp	#1,d0
	beq	.found
	cmp	#2,d0
	beq	.skipaga
	cmp	#3,d0
	beq	.skipnolib
	lea	p96modeid_msg_notfound,a0
	move.l	#p96modeid_msg_notfound_len,d3
	bra	.write
.skipaga
	lea	p96modeid_msg_skip_aga,a0
	move.l	#p96modeid_msg_skip_aga_len,d3
	bra	.write
.skipnolib
	lea	p96modeid_msg_skip_nolib,a0
	move.l	#p96modeid_msg_skip_nolib_len,d3
	bra	.write
.found
	lea	p96modeid_msg_found,a0
	move.l	#p96modeid_msg_found_len,d3
.write
	move.l	d7,d1
	move.l	a0,d2
	jsr	-48(a6)	; Write
	move.l	d7,d1
	jsr	-36(a6)	; Close
.done
	movem.l	(a7)+,d0-d3/d7/a0-a1/a6
	rts

; d0.l -> 8 ASCII hex digits at a0
g2p96_long_to_hex8	movem.l	d0-d3/a1,-(a7)
	move.l	d0,d3
	moveq	#7,d2
.lhex	move.l	d3,d1
	rol.l	#4,d1
	and	#$000f,d1
	lea	p96modeid_hexchars(pc),a1
	move.b	0(a1,d1.w),(a0)+
	rol.l	#4,d3
	dbf	d2,.lhex
	movem.l	(a7)+,d0-d3/a1
	rts

; d0.w -> 4 ASCII hex digits at a0
g2p96_word_to_hex4	movem.l	d0-d2/a1,-(a7)
	moveq	#3,d2
.whex	move	d0,d1
	lsr	#8,d1
	lsr	#4,d1
	and	#$000f,d1
	lea	p96modeid_hexchars(pc),a1
	move.b	0(a1,d1.w),(a0)+
	lsl	#4,d0
	dbf	d2,.whex
	movem.l	(a7)+,d0-d2/a1
	rts

g2p96_close	push
	move.l	p96base,d0
	beq.s	.done
	move.l	d0,a1
	move.l	4.w,a6
	jsr	-414(a6)	;CloseLibrary
	clr.l	p96base
	clr	p96present
	clr	p96found
.done	pull
	rts

showwindow	;a0=window
	;
	push
	;
	;poke bitmaps...
	move.l	wi_slice(a0),a1
	move.l	(a1),a1
	move.l	wi_bmap(a0),d0
	moveq	#6,d1	;7 bitplanes
.loop	move	d0,6(a1)
	swap	d0
	move	d0,2(a1)
	swap	d0
	add.l	#40,d0
	addq	#8,a1
	dbf	d1,.loop
	;
	;create DIW
	;
	move.l	wi_slice(a0),a1
	move.l	(a1),a1
	;
	move	wi_y(a0),d0
	move	d0,d1
	add	wi_bh(a0),d1
	lsl	#8,d0
	or	#$81,d0
	move	d0,56+2(a1)
	lsl	#8,d1
	or	#$c1,d1
	move	d1,56+6(a1)
	;
	;create wait!
	;
	move	wi_y(a0),d0
	subq	#3,d0
	move.b	d0,64(a1)
	;
	;create link to next!
	move.l	wi_nslice(a0),a1
	move.l	(a1),d0
	move.l	wi_cop1(a0),a1
	add.l	wi_copmem(a0),a1
	move.l	wi_cop2(a0),a2
	add.l	wi_copmem(a0),a2
	move	d0,-6(a1)
	move	d0,-6(a2)
	swap	d0
	move	d0,-10(a1)
	move	d0,-10(a2)
	;
	pull
	;
showwindowq	;display coplist
	;
	move.l	wi_cop(a0),d0
	move.l	wi_slice(a0),a0
	move.l	(a0),a0
	;
	move	d0,72+6(a0)
	swap	d0
	move	d0,72+2(a0)
	;
	rts

finitdisplay	push
	;
	jsr	g2p96_display_shutdown	;c86zfq: display-state shutdown close
	jsr	g2p96_close	;c86zdw: close passive library probe if it was opened
	;
	; c87b79n: DISPLAY=P96 owns only the RAM-side planar source pages here.
	; The actual P96 Screen/Window was already closed by g2p96_display_shutdown,
	; so there is no legacy Intuition Screen or DBufInfo to release.
	cmp	#2,g2display_mode
	bne.s	.g2c87b79n_finit_normal
	clr.l	screen
	clr.l	viewport
	clr.l	dbufinfo
	clr.l	oswindow
	pull
	rts
.g2c87b79n_finit_normal
	tst	os
	beq.w	.noos
	;
	move.l	dbufinfo(pc),a1
	move.l	grbase(pc),a6
	jsr	-$3cc(a6)	;free dbufinfo
	;
	; Close our synchronous covering window before its owning screen.
	move.l	oswindow,d0
	beq.s	.native_window_closed
	move.l	d0,a0
	move.l	int(pc),a6
	jsr	-72(a6)	; CloseWindow; IDCMPFlags=0, no messages to drain
	clr.l	oswindow
	clr.l	newwindow_s
.native_window_closed
	move.l	screen(pc),a0
	move.l	int(pc),a6
	jsr	-66(a6)
	;
	pull
	rts
	;
.noos	move.l	grbase,a6
	move.l	oldview,a1
	jsr	-222(a6)	;load view
	jsr	-270(a6)
	jsr	-270(a6)
	move.l	38(a6),$dff080
	move	#$81a0,$dff096
	move	#0,$dff088
	;
	pull
	rts

initbitmap	;a0=bitmap struct, d0=bitplane 0
	;
	move	bitplanes,d1
	move	#40,(a0)	;linemod
	move	#240,2(a0)	;v16: restore original compact bitmap rows
	move	d1,4(a0)
	clr	6(a0)
	lea	8(a0),a1
	subq	#1,d1
	move.l	#40*240,d2
.loop	move.l	d0,(a1)+
	add.l	d2,d0
	dbf	d1,.loop
	rts

intname	dc.b	'intuition.library',0
	even
int	dc.l	0

osbitmap1	ds.b	40
osbitmap2	ds.b	40

screen	dc.l	0
viewport	dc.l	0
dbufinfo	dc.l	0

newscreen	dc	0,0	;x,y ;v106: native PAL/WinUAE centering; no 40px right-shift
	dc	320,240	;w,h ;v17: keep compact 240-line bitmap, avoid bottom overread
newscreen_d	dc	8	;depth
	dc.b	0,0	;pens
newscreen_v	dc	0	;viewmode
	dc	$4f	;type
	dc.l	0	;font
	dc.l	0	;title
	dc.l	0	;gadgets
	dc.l	osbitmap1	;custombitmap

	;make a new task for this window...
	;simply wait for activate/deactive and 
	;modify input readers 
	;
newwindow	dc	0,0	;x,y
	dc	320,240	;w,h ;v17: keep compact 240-line window
	dc.b	0,0	;pens
	dc.l	0	; synchronous covering window: no undrained IDCMP messages
	dc.l	$11840	;ACTIVATE|BORDERLESS|SIMPLE_REFRESH|RMBTRAP; no BACKDROP
	dc.l	0	;gadgets
	dc.l	0	;checkmark
	dc.l	0	;title
newwindow_s	dc.l	0	;screen
	dc.l	0	;bitmap
	dc	-1,-1,-1,-1	;mins/maxs
	dc	15	;type

oswindow	dc.l	0
msgport	dc.l	0
g2v36_defer_pointer_show_rc5	dc	0	;native focus debounce suppresses transient ClearPointer

newtask	dcb.b	92,0

inputon	bsr	g2v36_hide_pointer	;v36: hide pointer even if input was already active
	tst	active
	bne.s	.rts
	;
	move	#$4000,$dff09a
	;
	lea	joytable,a2
	lea     joytable2,a3
	lea	joytable_end,a4
.loop	move.l	(a3)+,(a2)+
	cmp.l	a4,a2
	bcs.s	.loop
	;
	move.l	ciaa,a0
	movem.l	$64(a0),d0-d1
	movem.l	d0-d1,rawstuff
	move.l	rawtable,$64(a0)
	move.l	#rawkeyread,$68(a0)
	move	#$c000,$dff09a
	st	active
	;
	; v36: pointer hide is handled by g2v36_hide_pointer above.
.rts	rts

inputoff	jsr	g2p96_display_inputoff	;c86zfq: input loss exits P96 display ownership
	tst	active
	beq.s	.rts
	;
	move	#$4000,$dff09a
	;
	lea	joytable,a2
	lea	readnull,a3
	lea	joytable_end,a4
.loop	move.l	a3,(a2)+
	cmp.l	a4,a2
	bcs.s	.loop
	;
	move.l	ciaa,a0
	movem.l	rawstuff,d0-d1
	movem.l	d0-d1,$64(a0)
	move	#$c000,$dff09a
	;
	; RC5: a native INACTIVEWINDOW pulse may defer the visible pointer restore.
	; Normal shutdown/P96 paths leave this flag clear and retain immediate restore.
	tst	g2v36_defer_pointer_show_rc5
	bne.s	.g2rc5_skip_pointer_show
	bsr	g2v36_show_pointer
.g2rc5_skip_pointer_show
	clr	active
	;
.rts	rts

g2v35_blank_pointer	dc.w	0,0,0,0

g2v36_hide_pointer	;force invisible pointer for the game screen/window
	movem.l	d0-d3/a0-a1/a6,-(a7)
	move	#$0020,$dff096	;v39: disable hardware sprite DMA so OS mouse sprite vanishes even without an Intuition window
	move.l	oswindow,d0
	beq.s	.rts
	move.l	int,d1
	beq.s	.rts
	move.l	chipzero,a1	;v37: pointer image must live in chip RAM
	move.l	a1,d1
	beq.s	.rts
	lea	128(a1),a1	;Fix3b: private sprite area; never overwrite audio silence
	move.l	d0,a0
	moveq	#16,d0	;RC5: complete 16-row invisible Intuition pointer
	moveq	#16,d1	;RC5: full 16-pixel sprite width
	moveq	#0,d2	;x offset
	moveq	#0,d3	;y offset
	move.l	int,a6
	jsr	-270(a6)	; Intuition SetPointer
.rts	movem.l	(a7)+,d0-d3/a0-a1/a6
	rts

g2v36_show_pointer	;restore normal pointer when inactive/exit
	movem.l	d0/a0/a6,-(a7)
	move	#$8020,$dff096	;v39: re-enable hardware sprite DMA for Workbench/OS pointer
	move.l	oswindow,d0
	beq.s	.rts
	move.l	int,d0
	beq.s	.rts
	move.l	oswindow,a0
	move.l	int,a6
	jsr	-60(a6)	; Intuition ClearPointer
.rts	movem.l	(a7)+,d0/a0/a6
	rts

windowtask	move.l	int(pc),a6	;intuition base
	lea	newwindow(pc),a0
	jsr	-204(a6)	;openwindow
	move.l	d0,oswindow
	bne.s	.g2rc5_open_ok	;RC5 GenAmFix1: nearby success path
	rts			;failed OpenWindow: return without dereferencing d0
.g2rc5_open_ok
	bsr	g2v36_hide_pointer	;RC5: install full blank pointer immediately
	move.l	d0,a0
	move.l	86(a0),msgport
	;
	; RC5: WaitPort signals availability; GetMsg owns/removes each message
	; before it is replied. Drain every queued focus event in order.
	;
	move.l	4.w,a6
.g2rc5_wait
	move.l	msgport(pc),a0
	jsr	-384(a6)	;Exec WaitPort
.g2rc5_drain
	move.l	msgport(pc),a0
	jsr	-372(a6)	;Exec GetMsg
	tst.l	d0
	beq.s	.g2rc5_wait
	move.l	d0,a1
	move.l	20(a1),d4
	jsr	-378(a6)	;Exec ReplyMsg
	cmp.l	#$40000,d4	;IDCMP_ACTIVEWINDOW
	beq.s	.g2rc5_activate
	cmp.l	#$80000,d4	;IDCMP_INACTIVEWINDOW
	bne.s	.g2rc5_drain
	;
	; Native AGA/ECS can receive very short INACTIVE/ACTIVE pulses from
	; commodities or screen managers. Detach input now, but keep the blank
	; pointer until four VBlanks have collapsed all queued focus messages.
	cmp	#2,g2display_mode
	beq.s	.g2rc5_inactive_immediate
	move	#-1,g2v36_defer_pointer_show_rc5
	bsr	inputoff
	clr	g2v36_defer_pointer_show_rc5
	bsr	g2v36_window_inactive_settle_rc5
	tst	d0
	bne.s	.g2rc5_reactivate_after_settle
	bsr	g2v36_show_pointer
	move.l	4.w,a6
	bra.s	.g2rc5_wait
.g2rc5_reactivate_after_settle
	bsr	inputon
	move.l	4.w,a6
	bra.s	.g2rc5_wait
.g2rc5_inactive_immediate
	bsr	inputoff
	move.l	4.w,a6
	bra.s	.g2rc5_drain
.g2rc5_activate
	bsr	inputon
	move.l	4.w,a6
	bra.s	.g2rc5_drain

; RC5 native focus debounce.
; The triggering INACTIVEWINDOW message has already been removed and replied.
; Wait four refreshes, drain every focus message now queued on the native game
; window, and return d0=-1 when the latest state is active, otherwise d0=0.
g2v36_window_inactive_settle_rc5
	movem.l	d1-d3/a0-a1/a6,-(a7)
	moveq	#0,d3		;latest known state: inactive
	moveq	#3,d2		;four VBlanks
.g2rc5_frame
	move.l	grbase,d0
	beq.s	.g2rc5_drain
	move.l	d0,a6
	jsr	-270(a6)	;graphics.library WaitTOF
.g2rc5_drain
	move.l	msgport,a0
	move.l	4.w,a6
	jsr	-372(a6)	;Exec GetMsg
	tst.l	d0
	beq.s	.g2rc5_next_frame
	move.l	d0,a1
	move.l	20(a1),d1
	cmp.l	#$40000,d1	;IDCMP_ACTIVEWINDOW
	bne.s	.g2rc5_not_active
	moveq	#-1,d3
	bra.s	.g2rc5_reply
.g2rc5_not_active
	cmp.l	#$80000,d1	;IDCMP_INACTIVEWINDOW
	bne.s	.g2rc5_reply
	moveq	#0,d3
.g2rc5_reply
	move.l	4.w,a6
	jsr	-378(a6)	;Exec ReplyMsg
	bra.s	.g2rc5_drain
.g2rc5_next_frame
	dbf	d2,.g2rc5_frame
	move.l	d3,d0
	movem.l	(a7)+,d1-d3/a0-a1/a6
	rts

initdisplay	;
	lea	grname,a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,grbase
	;
	; c87b79x: native AGA/ECS keep the two compact planar pages. DISPLAY=P96
	; owns only chunky/direct index and CLUT staging pages, so leave every
	; legacy bitmap pointer and size at zero.
	clr.l	bmapmem
	clr.l	bitmaps
	clr.l	bitmaps2
	clr.l	showbitmap
	clr.l	drawbitmap
	cmp	#2,g2display_mode
	beq.s	.g2c87b79x_bitmaps_ready
	move	#40*240,d2	;1 bitplane (DB), v16 compact plane span
	mulu	bitplanes,d2
	move.l	d2,bmapmem
	move.l	d2,d0
	add.l	d0,d0	;2 for DB
	moveq	#2,d1
	allocmem	bitmaps
	move.l	d0,bitmaps
	add.l	d2,d0
	move.l	d0,bitmaps2
.g2c87b79x_bitmaps_ready
	;
	; ECS3: AllocMem does not guarantee cleared Chip RAM.  Clear both complete
	; ECS buffers before OpenScreen/LoadView can expose them, eliminating the
	; random striped frame seen before BlackMagic.  AGA/P96 remain untouched.
	tst	aga
	bne.s	g2ecs3_bitmaps_ready
	jsr	g2v36_clear_title_buffers
g2ecs3_bitmaps_ready
	;
	tst	os
	beq.w	.noos
	;
	;OK, OS version...
	;init bitmaps and open a screen!
	;
	move.l	4.w,a6
	lea	intname(pc),a1
	jsr	-408(a6)
	move.l	d0,int
	;
	cmp	#2,g2display_mode
	beq	db		;c87b79x: no OS-format planar bitmap structures
	move.l	bitmaps,d0
	lea	osbitmap1(pc),a0
	bsr	initbitmap
	move.l	bitmaps2,d0
	lea	osbitmap2(pc),a0
	bsr	initbitmap
	;
	; Native OS-managed AGA/ECS screen follows. P96 branched to db above.
	move	bitplanes,newscreen_d
	tst	aga
	bne.s	.agasc
	move	#$80,newscreen_v
	;
.agasc	move.l	int(pc),a6
	lea	newscreen(pc),a0
	jsr	-198(a6)
	move.l	d0,a0
	move.l	a0,screen
	bne.s	.g2c86zdc_screen_ok
	clr.w	os	; OpenScreen failed: use existing direct-display fallback
	bra.w	.noos
.g2c86zdc_screen_ok
	; Open the covering window synchronously. The legacy windowtask is
	; not started anywhere in this source. Its flags alone had no effect.
	; No IDCMP port: input remains owned by the existing hardware readers.
	move.l	screen(pc),newwindow_s
	move.l	int(pc),a6
	lea	newwindow(pc),a0
	jsr	-204(a6)	; OpenWindow
	move.l	d0,oswindow
	bne.s	.native_window_ok
	; Do not continue with an uncovered screen after OpenWindow failure.
	; Match the existing OpenScreen-failure custom-display fallback.
	move.l	screen(pc),a0
	move.l	int(pc),a6
	jsr	-66(a6)	; CloseScreen (no window exists)
	clr.l	screen
	clr.l	newwindow_s
	clr.w	os
	bra.w	.noos
.native_window_ok
	jsr	g2v36_hide_pointer
	move.l	screen(pc),a0
	move.l	int(pc),a6
	moveq	#0,d0
	jsr	-282(a6)	; ShowTitle(FALSE), explicit screen-bar suppression
	move.l	screen(pc),a0
	lea	44(a0),a0
	;
	move.l	a0,viewport
	move.l	grbase(pc),a6
	jsr	-$3c6(a6)	;alocdbufinfo
	move.l	d0,dbufinfo
	bra	db
	;
.noos	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_noos_native
	jmp	db_p96_source	;c87b79x: never program native copper with null bitmaps
.g2c87b79x_noos_native
	move.l	grbase(pc),a6
	move.l	34(a6),oldview
	sub.l	a1,a1
	jsr	-222(a6)	;loadview 0.
	;
	bsr	dispoff
	lea	copinit_aga,a0
	lea	copfinit_aga,a1
	tst	aga
	bne	.aga	
	lea	copinit_ecs,a0
	lea	copfinit_ecs,a1
.aga	movem.l	a0-a1,-(a7)
	move.l	a1,d0
	sub.l	a0,d0
	move.l	d0,d2
	moveq	#2,d1
	allocmem	coplist
	move.l	d0,coplist
	move.l	d0,a2	;dest
	movem.l	(a7)+,a0-a1
	lsr.l	#2,d2
	subq	#1,d2
.loop	move.l	(a0)+,(a2)+
	cmp.l	a1,a0
	bcs.s	.loop
	;
db	;double buffering / RAM source-page swap
	;
	; c87b79x: hard P96 gate before reading the removed bitmap pair.
	cmp	#2,g2display_mode
	bne.s	.g2c87b79x_native_swap
	jmp	db_p96_source
.g2c87b79x_native_swap
	movem.l	bitmaps,d0-d1
	cmp.l	drawbitmap,d0
	beq.s	.show
	exg	d0,d1
.show	movem.l	d0-d1,showbitmap
.g2c87b79p_native_dispatch
	move.l	todb,a0
	jmp	(a0)

db_ecs	move.l	coplist,a0
	moveq	#40,d2
	lea	bitplanes_ecs-copinit_ecs(a0),a0
	moveq	#5,d1	;6 bitplanes
.loop0	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	d2,d0
	addq	#8,a0
	dbf	d1,.loop0
	rts

db_aga	move.l	coplist,a0
	moveq	#40,d2
	lea	bitplanes_aga-copinit_aga(a0),a0
	moveq	#7,d1	;8 bitplanes
.loop	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	d2,d0
	addq	#8,a0
	dbf	d1,.loop
	rts

db_os	move.l	viewport(pc),a0
	lea	osbitmap1(pc),a1
	cmp.l	8(a1),d0
	beq.s	.got
	lea	osbitmap2(pc),a1
.got	move.l	dbufinfo(pc),a2
	move.l	grbase(pc),a6
	jmp	-$3ae(a6)	;changevpbitmap
	
;a0=bitmap, a1=screen, a3=intution, a6=graphics
;
;.agashowbitmap
;  MOVE.l a0,d4:MOVE.l (a1),a2:MOVE.l 4(a1),d0:BNE gotdbuff
;  MOVEM.l a1-a2,-(a7):LEA 44(a2),a0:JSR -$3c6(a6):MOVEM.l (a7)+,a1-a2
;  ;_AllocDBufInfo(a6):
;  MOVE.l d0,4(a1)
;gotdbuff:
;  LEA 44(a2),a0:MOVE.l d4,a1:MOVE.l d0,a2:JSR -$3ae(a6) ;ChangeVPBitMap_
;  RTS

allocmem2_	;
	;as below, but d2.l = extra mem at start to set aside
	;
	push
	moveq	#16,d3
	add.l	d2,d3
	bra.s	amem_

allocmem_	;
	;d0=size, d1=requirements, a0=text field
	;
	;set up node before allocmem for quick freemem:
	;
	;00.l : next
	;04.l : real size
	;08.l : offset to user mem (normally 16, but CM fucks things up)
	;12.l : pointer to text field for debugging
	;
	push
	moveq	#16,d3	;offset
	;
amem_	move.l	a0,d4
	add.l	d3,d0
	;
	move.l	d0,d2	;len
	move.l	a0,d4	;text
	move.l	4.w,a6
	jsr	-198(a6)
	tst.l	d0
	bne.s	.skip
	;
	; Gloombench2 Patch 1: MEMF_FAST is preferred for CPU-side data,
	; but preserve compatibility by retrying the identical allocation as
	; MEMF_PUBLIC before reporting failure. CHIP allocations never enter here.
	cmp.l	#4,d1
	bne.s	.g2bench_p1_alloc_failed
	move.l	d2,d0		; restore total size including memlist header
	moveq	#1,d1		; MEMF_PUBLIC fallback
	jsr	-198(a6)
	tst.l	d0
	bne.s	.skip
.g2bench_p1_alloc_failed
	;
	warn	#$f00
	clr.l	d0		; v190p: allocation failed, return 0 instead of writing through address 0
	pull
	rts
	;
.skip	move.l	d0,a0
	move.l	memlist,(a0)	;next
	move.l	a0,memlist
	movem.l	d2-d4,4(a0)
	add.l	d3,a0
	move.l	a0,d0
	;
	pull
	rts

freememlist	push
	;
.more	move.l	memlist,d0
	beq.s	.done
	move.l	d0,a2
	;
	ifne	debugmem
	move.l	12(a2),a0	;text field
	move.l	a0,d2
	moveq	#-1,d3
.loop	addq.l	#1,d3
	tst.b	(a0)+
	bne.s	.loop
	;
	move.l	outhand,d1
	move.l	dosbase,a6
	jsr	-48(a6)
	endc
	;
	move.l	a2,a1
	;
	move.l	(a1),memlist
	move.l	4(a1),d0
	move.l	4.w,a6
	jsr	-210(a6)
	bra.s	.more
	;
.done	pull
	rts

freemem_	;
	;a1=address to free!
	;
	push
	;
	ifne	debugmem
	move.l	a0,-(a7)	;error mess
	elseif
	endc
	;
	move.l	a1,a2	;mem to find!
	lea	memlist,a1
	;
.more	move.l	a1,a0	;prev
	move.l	(a1),d0
	beq.s	.err
	move.l	d0,a1
	;
	move.l	a1,a3
	add.l	8(a3),a3
	cmp.l	a3,a2
	bne.s	.more
	;
	move.l	(a1),(a0)
	move.l	4(a1),d0
	move.l	4.w,a6
	jsr	-210(a6)
	bra.s	.done
	;
.err	warn	#$ff0
	ifne	debugmem
	move.l	(a7),freememerr
	endc
.done	;
	ifne	debugmem
	addq	#4,a7
	endc
	;
	pull
	rts

freememerr	dc.l	0

initmap	;map address in map_map...
	;load in textures, do colour mapping etc.
	;
	push
	;
	move.l	map_map,a0
	;
	move.l	a0,a1
	add.l	(a0),a1
	move.l	a1,map_grid
	;
	move.l	a0,a1
	add.l	4(a0),a1
	move.l	a1,map_poly
	;
	move.l	a0,a1
	add.l	8(a0),a1
	move.l	a1,map_ppnt
	;
	move.l	a0,a1
	add.l	12(a0),a1
	move.l	a1,map_anim
	;
	move.l	a0,a1
	add.l	16(a0),a1
	move.l	a1,map_txts
	;
	move.l	(a0),d0
	sub.l	#25*4,d0
	add.l	a0,d0
	move.l	d0,map_events
	;
	move.l	map_rgbsfrom2,map_rgbsat
	;
	pull
	rts

freetxts	lea	textscrns,a6
	moveq	#7,d7
.loop	move.l	(a6)+,d0
	beq.s	.skip
	move.l	d0,a1
	freemem	freetxts
	clr.l	-4(a6)
.skip	dbf	d7,.loop
	rts

loadtxts	push
	;
	lea	textures,a4
	move.l	map_txts,a5	;texture names
	lea	textscrns,a6
	moveq	#7,d7
	;
.ltl	lea	.temp(pc),a0
	;
.ltl2	move.b	(a5)+,(a0)+
	bne.s	.ltl2
	moveq	#0,d0
	cmp.l	#.temp+1,a0
	beq.s	.notext
	lea	.temp2(pc),a0
	moveq	#1,d1
	jsr	loadfile
	;
.notext	move.l	d0,(a6)+	;texture!
	beq.s	.skip
	;
	;do colour mapping stuff!
	;
	move.l	d0,-(a7)
	;
	move.l	d0,a0
	add.l	(a0),a0
	move.l	a0,a2
	bsr	addpal
	;
	move.l	(a7),a0
	addq	#4,a0
	move.l	a2,a1
	bsr	remap
	;
	move.l	(a7)+,a0
	addq	#4,a0
	moveq	#19,d0
	move.l	#64*65,d1
	;
.mtxt	move.l	a0,(a4)+
	add.l	d1,a0
	dbf	d0,.mtxt
.skip	;
	dbf	d7,.ltl
	;
	pull
	rts

.temp2	dc.b	'txts/'
.temp	ds.b	64 
	even

remapanim	;a0=anim to remap...
	;
	push
	;
	move.l	a0,a6
	movem	(a6),d6-d7
	lsl	d6,d7	;how many frames!
	subq	#1,d7
	;
	move.l	a6,a0
	add.l	an_pal(a0),a0
	bsr	addpal
	;
	lea	an_size(a6),a5
	;
.loop	move.l	a6,a0
	add.l	(a5)+,a0	;start of shape
	addq	#4,a0	;skip handles
	movem	(a0)+,d0-d1	;w/h
	mulu	d1,d0
	lea	0(a0,d0.l),a1	;end
	bsr	remap
	;
	dbf	d7,.loop
	;
	pull
	rts
	
remap	;a0=start of byte data, a1=end of byte data
	;
	push
	;
	moveq	#0,d0
	move.l	maptable,a2
	;
.loop	cmp.l	a1,a0
	bcc.s	.done
	move.b	(a0),d0
	move.b	0(a2,d0),(a0)+
	bra.s	.loop
.done	;
	pull
	rts

addpal	;add palette in a0 to end of map_rgb
	;
	push
	;
	move	(a0)+,d0
	subq	#1,d0
	move.l	map_rgbsat,a2	;end of rgbs
	move.l	maptable,a3
	;
	clr.b	(a3)	;0=0
	move.b	#255,255(a3)	;-1=-1
	move.b	#254,254(a3)	;-1=-1
	move.b	#253,253(a3)	;-1=-1
	move.b	#252,252(a3)	;-1=-1
	move.b	#251,251(a3)	;-1=-1
	move.b	#250,250(a3)	;-1=-1
	move.b	#249,249(a3)	;-1=-1
	;
	moveq	#1,d2	;colour 1!
	;
.loop	move	(a0)+,d1	;colour...does it exist?
	bmi.s	.next	;not used!
	move.l	map_rgbs,a1
	;
.loop2	cmp.l	a2,a1
	bcc.s	.no
	cmp	(a1)+,d1
	beq.s	.yes
	bra.s	.loop2
	;
.no	;colour doesn't exist!
	;may have to do a 'near match' routine if we run out of colours
	;
	move	d1,(a2)+
	move.l	a2,a1
	;
.yes	subq	#2,a1
	sub.l	map_rgbs,a1
	move.l	a1,d1
	lsr	#1,d1	;real colour
	;
	cmp	#256,d1
	bcs.s	.ok
	;
	warn	#$00f
	;
.ok	move.b	d1,0(a3,d2)
	;
.next	addq	#1,d2
	dbf	d0,.loop
	;
	move.l	a2,map_rgbsat
	;
	pull
	rts

	;coll types...
	;
	;1...bullet from player 1
	;2...bullet from player 2
	;4...bullet from monster
	;8...player 1
	;16..player 2
	;

	dc.l	0,player,tokens
	;
objlist	;list of objects to be freed...
	;
	dc.l	marine,baldy,terra,ghoul,demon,phantom
	dc.l	lizard,deathhead,dragon,troll,0

player	dc.l	0,0	;main, chunks
	dc.b	'objs/player',0,0
	even
tokens	dc.l	0,0
	dc.b	'objs/tokens',0,0
	even
marine	dc.l	0,0
	dc.b	'objs/marine',0,0
	even
baldy	dc.l	0,0
	dc.b	'objs/baldy',0,0
	even
terra	dc.l	0,0
	dc.b	'objs/terra',0,0
	even
ghoul	dc.l	0,0
	dc.b	'objs/ghoul',0,0
	even
demon	dc.l	0,0
	dc.b	'objs/demon',0,0
	even
phantom	dc.l	0,0
	dc.b	'objs/phantom',0,0
	even
lizard	dc.l	0,0
	dc.b	'objs/lizard',0,0
	even
deathhead	dc.l	0,0
	dc.b	'objs/deathhead',0,0
	even
dragon	dc.l	0,0
	dc.b	'objs/dragon',0,0
	even
troll	dc.l	0,0
	dc.b	'objs/troll',0,0
	even

objinfo
player1_	dc.l	player1
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	$d0000
_ob_shape	dc.l	player
.ob_logic	dc.l	playerlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	playerhit
.ob_die	dc.l	playerdie
	;
.ob_eyey	dc	-pl_eyey	;eye height
.ob_firey	dc	-pl_firey	;where bullets come from
.ob_gutsy	dc	-pl_gutsy
.ob_othery	dc	0
p1_ob_colltype	dc	8
p1_ob_collwith	dc	6	;6=combat, 4=game
p1_ob_cntrl
	ifne	cd32
	dc	4	;CD32 PAD 1 in v34 control table
	elseif
	dc	0	;KEYBMOUSE default
	endc
.ob_damage	dc	1
.ob_hitpoints	dc	25
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	1
.ob_range	dc	1
.ob_weapon	dc	0	;weapon type...0...25
.ob_reload	dc.b	ireload,0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0	;4!
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

objinfof

oilen	equ	objinfof-objinfo

player2_	dc.l	player2
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	$d0000
.ob_shape	dc.l	player
.ob_logic	dc.l	playerlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	playerhit
.ob_die	dc.l	playerdie
.ob_eyey	dc	-pl_eyey	;eye height
.ob_firey	dc	-pl_firey	;where bullets come from
.ob_gutsy	dc	-pl_gutsy
.ob_othery	dc	0
p2_ob_colltype	dc	16
p2_ob_collwith	dc	5	;5=combat, 4=game
p2_ob_cntrl
	ifne	cd32
	dc	5	;CD32 PAD 2 in v34 control table
	elseif
	dc	2	;v168 JOYSTICK 1 default is valid while P1 uses KEYBMOUSE
	endc

.ob_damage	dc	1
.ob_hitpoints	dc	25
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	1
.ob_range	dc	1
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc.b	ireload,0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0	;4!
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

health_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	healthgot
.ob_die	dc.l	healthgot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$20000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

weapon_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon2
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	1
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

thermo_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	thermogot
.ob_die	dc.l	thermogot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$00000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

infra_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	thermogot
.ob_die	dc.l	thermogot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$00000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

invisi_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	invisigot
.ob_die	dc.l	invisigot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$10000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

invinc_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	rts
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	invincgot
.ob_die	dc.l	invincgot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$20000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

dragon_	dc.l	dummy
.ob_rotspeed	dc.l	$ffff0000
.ob_movspeed	dc.l	$c0000
.ob_shape	dc.l	dragon
.ob_logic	dc.l	dragonlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	rts	;hurtngrunt
.ob_die	dc.l	blowdragon	;object
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-144	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	10
.ob_hitpoints	dc	250
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	16
.ob_range	dc	32
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$300
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

bouncy_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	tokens
.ob_logic	dc.l	bouncylogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	bouncygot
.ob_die	dc.l	bouncygot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	$30000
.ob_framespeed	dc.l	0
.ob_base	dc	0
.ob_range	dc	0
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

marine_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$60000
.ob_shape	dc.l	marine
.ob_logic	dc.l	monsterlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	1
.ob_hitpoints	dc	5
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	16
.ob_range	dc	32
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

baldy_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$40000
.ob_shape	dc.l	baldy
.ob_logic	dc.l	baldylogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	2
.ob_hitpoints	dc	10
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	8
.ob_range	dc	16
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	3
.ob_punchrate	dc	4
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$220
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

terra_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$20000
.ob_shape	dc.l	terra
.ob_logic	dc.l	terralogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtterra ;ngrunt
.ob_die	dc.l	blowterra
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	1
.ob_hitpoints	dc	35
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$6000
.ob_base	dc	32
.ob_range	dc	48
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_firerate	dc	12	;how often terra fires
.ob_bouncecnt	dc	0	;how many times
.ob_firecnt	dc	5
.ob_scale	dc	$280
.ob_apad	dc	0
.ob_blood	dc	$fff	;color AND for blood
.ob_ypad	dc	1

ghoul_	dc.l	dummy
.ob_rotspeed	dc.l	$0
.ob_movspeed	dc.l	$80000
.ob_shape	dc.l	ghoul
.ob_logic	dc.l	ghoullogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtghoul
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-64	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	5
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	0
.ob_base	dc	32
.ob_range	dc	48
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_firerate	dc	12	;how often terra fires
.ob_bouncecnt	dc	0	;how many times
.ob_firecnt	dc	5
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$80f0	;color AND for blood
.ob_ypad	dc	1

phantom_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$a0000
.ob_shape	dc.l	phantom
.ob_logic	dc.l	phantomlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	3
.ob_hitpoints	dc	10
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$a000
.ob_base	dc	8
.ob_range	dc	16
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	7
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$280
.ob_apad	dc	0
.ob_blood	dc	$ff0	;color AND for blood
.ob_ypad	dc	1

demon_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$70000
.ob_shape	dc.l	demon
.ob_logic	dc.l	demonlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtngrunt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-90	;where bullets come from
.ob_gutsy	dc	-72
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	5
.ob_hitpoints	dc	25
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$7000
.ob_base	dc	32
.ob_range	dc	4
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	5
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$380
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

weapon1_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon1
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	0
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon2_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon2
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	1
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon3_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon3
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	2
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon4_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon4
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	3
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

weapon5_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	0
.ob_shape	dc.l	weapon5
.ob_logic	dc.l	weaponlogic
.ob_render	dc.l	drawshape_1
.ob_hit	dc.l	weapongot
.ob_die	dc.l	weapongot
.ob_eyey	dc	0	;eye height
.ob_firey	dc	0	;where bullets come from
.ob_gutsy	dc	0
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	0
.ob_hitpoints	dc	0
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$08000
.ob_base	dc	4
.ob_range	dc	4
.ob_weapon	dc	4
.ob_reload	dc	0
.ob_hurtpause	dc	0
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	0	;color AND for blood
.ob_ypad	dc	0

lizard_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$60000
.ob_shape	dc.l	lizard
.ob_logic	dc.l	lizardlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	lizhurt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	2
.ob_hitpoints	dc	10
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	8
.ob_range	dc	8
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	2
.ob_punchrate	dc	3
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$240
.ob_apad	dc	0
.ob_blood	dc	$f0f	;color AND for blood
.ob_ypad	dc	1

deathhead_	dc.l	dummy
.ob_rotspeed	dc.l	0
.ob_movspeed	dc.l	$c0000
.ob_shape	dc.l	deathhead
.ob_logic	dc.l	deathheadlogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	hurtdeath
.ob_die	dc.l	blowdeath
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-96
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	3
.ob_hitpoints	dc	35
.ob_think	dc	0
.ob_frame	dc.l	$8000
.ob_framespeed	dc.l	$6000
.ob_base	dc	-8
.ob_range	dc	16
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	10
.ob_punchrate	dc	0
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$200
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

troll_	dc.l	dummy
.ob_rotspeed	dc.l	$30000
.ob_movspeed	dc.l	$60000
.ob_shape	dc.l	troll
.ob_logic	dc.l	trolllogic
.ob_render	dc.l	drawshape_8
.ob_hit	dc.l	trollhurt
.ob_die	dc.l	blowobject
.ob_eyey	dc	-64	;eye height
.ob_firey	dc	-60	;where bullets come from
.ob_gutsy	dc	-64
.ob_othery	dc	0
.ob_colltype	dc	0
.ob_collwith	dc	24+3
.ob_cntrl	dc	0	;for player 0,1=joyport
.ob_damage	dc	3
.ob_hitpoints	dc	18
.ob_think	dc	0
.ob_frame	dc.l	0
.ob_framespeed	dc.l	$4000
.ob_base	dc	8
.ob_range	dc	8
.ob_weapon	dc	0	;weapon type...
.ob_reload	dc	0
.ob_hurtpause	dc	2
.ob_punchrate	dc	3
.ob_bouncecnt	dc	0
.ob_something	dc	0
.ob_scale	dc	$240
.ob_apad	dc	0
.ob_blood	dc	$f00	;color AND for blood
.ob_ypad	dc	1

abouttext	dc.b	16
	dc.b	'GLOOM',0
	dc.b	0
	dc.b	'A BLACK MAGIC GAME',0
	dc.b	0
	dc.b	'PROGRAMMED BY MARK SIBLY',0
	dc.b	'GRAPHICS BY THE BUTLER BROTHERS',0
	dc.b	'MUSIC BY KEV STANNARD',0
	dc.b	'AUDIO BY US',0
	dc.b	'PRODUCED BY US',0
	dc.b	'DESIGNED BY US',0
	dc.b	'GAME CODED IN DEVPAC2',0
	dc.b	'UTILITIES CODED IN BLITZ BASIC 2',0
	dc.b	'RENDERED IN DPAINT3 AND DPAINT4',0
	dc.b	'DECRUNCHING CODE BY THOMAS SCHWARZ',0
	dc.b	0
	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

abouttext_g3	dc.b	14
	dc.b	'GLOOM3 ZOMBIE EDITION',0
	dc.b	'A GAME BY GARETH MURFIN',0
	dc.b	0
	dc.b	'ADDITIONAL GFX AND SFX BY',0
	dc.b	'JAMES CAYGILL',0
	dc.b	'CHRIS BURNS',0
	dc.b	'RICHARD MURFIN',0
	dc.b	0
	dc.b	'STORY BY',0
	dc.b	'CHRIS MURFIN',0
	dc.b	0
	dc.b	'BASED ON GLOOM BY MARK SIBLY',0
	dc.b	0
	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

abouttext_zm	dc.b	8
	dc.b	'ALPHA SOFTWARE',0
	dc.b	'QUALITY AMIGA SOFTWARE',0
	dc.b	0
	dc.b	'FOUNDED BY GARETH MURFIN',0
	dc.b	0
	dc.b	'CHECK OUT THE BOOKLET NOW!',0
	dc.b	0
	dc.b	'GLOOM REFORGED IDEA BY ANDIWELI',0
	even

sqrinc	incbin	sqr.bin

weapon1	dc.l	bullet1,sparks1
weapon2	dc.l	bullet2,sparks2
weapon3	dc.l	bullet3,sparks3
weapon4	dc.l	bullet4,sparks4
weapon5	dc.l	bullet5,sparks5

bullet1	incbin	bullet1.bin
bullet2	incbin	bullet2.bin
bullet3	incbin	bullet3.bin
bullet4	incbin	bullet4.bin
bullet5	incbin	bullet5.bin

sparks1	incbin	sparks1.bin
sparks2	incbin	sparks2.bin
sparks3	incbin	sparks3.bin
sparks4	incbin	sparks4.bin
sparks5	incbin	sparks5.bin

medplayer	incbin	medplay
decrm	incbin	decrm

g2wide_castrots_table
	; c87w1: 54 additional rays left of the exact original 320-entry table.
	dc.w	$21d7,$3872,$c78e,$21d7
	dc.w	$2213,$3892,$c76e,$2213
	dc.w	$2250,$38b2,$c74e,$2250
	dc.w	$228d,$38d2,$c72e,$228d
	dc.w	$22ca,$38f2,$c70e,$22ca
	dc.w	$2309,$3911,$c6ef,$2309
	dc.w	$2347,$3931,$c6cf,$2347
	dc.w	$2387,$3951,$c6af,$2387
	dc.w	$23c7,$3970,$c690,$23c7
	dc.w	$2407,$3990,$c670,$2407
	dc.w	$2448,$39af,$c651,$2448
	dc.w	$248a,$39cf,$c631,$248a
	dc.w	$24cc,$39ee,$c612,$24cc
	dc.w	$250f,$3a0d,$c5f3,$250f
	dc.w	$2553,$3a2c,$c5d4,$2553
	dc.w	$2597,$3a4b,$c5b5,$2597
	dc.w	$25dc,$3a6a,$c596,$25dc
	dc.w	$2621,$3a89,$c577,$2621
	dc.w	$2667,$3aa8,$c558,$2667
	dc.w	$26ae,$3ac7,$c539,$26ae
	dc.w	$26f5,$3ae5,$c51b,$26f5
	dc.w	$273d,$3b04,$c4fc,$273d
	dc.w	$2786,$3b22,$c4de,$2786
	dc.w	$27cf,$3b40,$c4c0,$27cf
	dc.w	$281a,$3b5e,$c4a2,$281a
	dc.w	$2864,$3b7c,$c484,$2864
	dc.w	$28b0,$3b9a,$c466,$28b0
	dc.w	$28fc,$3bb7,$c449,$28fc
	dc.w	$2949,$3bd5,$c42b,$2949
	dc.w	$2996,$3bf2,$c40e,$2996
	dc.w	$29e5,$3c0f,$c3f1,$29e5
	dc.w	$2a34,$3c2c,$c3d4,$2a34
	dc.w	$2a83,$3c48,$c3b8,$2a83
	dc.w	$2ad4,$3c65,$c39b,$2ad4
	dc.w	$2b25,$3c81,$c37f,$2b25
	dc.w	$2b77,$3c9d,$c363,$2b77
	dc.w	$2bca,$3cb9,$c347,$2bca
	dc.w	$2c1d,$3cd4,$c32c,$2c1d
	dc.w	$2c71,$3cf0,$c310,$2c71
	dc.w	$2cc6,$3d0b,$c2f5,$2cc6
	dc.w	$2d1c,$3d25,$c2db,$2d1c
	dc.w	$2d73,$3d40,$c2c0,$2d73
	dc.w	$2dca,$3d5a,$c2a6,$2dca
	dc.w	$2e22,$3d74,$c28c,$2e22
	dc.w	$2e7b,$3d8e,$c272,$2e7b
	dc.w	$2ed5,$3da7,$c259,$2ed5
	dc.w	$2f30,$3dc0,$c240,$2f30
	dc.w	$2f8b,$3dd8,$c228,$2f8b
	dc.w	$2fe8,$3df1,$c20f,$2fe8
	dc.w	$3045,$3e09,$c1f7,$3045
	dc.w	$30a3,$3e20,$c1e0,$30a3
	dc.w	$3102,$3e37,$c1c9,$3102
	dc.w	$3161,$3e4e,$c1b2,$3161
	dc.w	$31c2,$3e64,$c19c,$31c2
castrotsinc	incbin	castrots128.bin
	; c87w1: 54 additional rays right of the exact original table.
	dc.w	$31c2,$c19c,$3e64,$31c2
	dc.w	$3161,$c1b2,$3e4e,$3161
	dc.w	$3102,$c1c9,$3e37,$3102
	dc.w	$30a3,$c1e0,$3e20,$30a3
	dc.w	$3045,$c1f7,$3e09,$3045
	dc.w	$2fe8,$c20f,$3df1,$2fe8
	dc.w	$2f8b,$c228,$3dd8,$2f8b
	dc.w	$2f30,$c240,$3dc0,$2f30
	dc.w	$2ed5,$c259,$3da7,$2ed5
	dc.w	$2e7b,$c272,$3d8e,$2e7b
	dc.w	$2e22,$c28c,$3d74,$2e22
	dc.w	$2dca,$c2a6,$3d5a,$2dca
	dc.w	$2d73,$c2c0,$3d40,$2d73
	dc.w	$2d1c,$c2db,$3d25,$2d1c
	dc.w	$2cc6,$c2f5,$3d0b,$2cc6
	dc.w	$2c71,$c310,$3cf0,$2c71
	dc.w	$2c1d,$c32c,$3cd4,$2c1d
	dc.w	$2bca,$c347,$3cb9,$2bca
	dc.w	$2b77,$c363,$3c9d,$2b77
	dc.w	$2b25,$c37f,$3c81,$2b25
	dc.w	$2ad4,$c39b,$3c65,$2ad4
	dc.w	$2a83,$c3b8,$3c48,$2a83
	dc.w	$2a34,$c3d4,$3c2c,$2a34
	dc.w	$29e5,$c3f1,$3c0f,$29e5
	dc.w	$2996,$c40e,$3bf2,$2996
	dc.w	$2949,$c42b,$3bd5,$2949
	dc.w	$28fc,$c449,$3bb7,$28fc
	dc.w	$28b0,$c466,$3b9a,$28b0
	dc.w	$2864,$c484,$3b7c,$2864
	dc.w	$281a,$c4a2,$3b5e,$281a
	dc.w	$27cf,$c4c0,$3b40,$27cf
	dc.w	$2786,$c4de,$3b22,$2786
	dc.w	$273d,$c4fc,$3b04,$273d
	dc.w	$26f5,$c51b,$3ae5,$26f5
	dc.w	$26ae,$c539,$3ac7,$26ae
	dc.w	$2667,$c558,$3aa8,$2667
	dc.w	$2621,$c577,$3a89,$2621
	dc.w	$25dc,$c596,$3a6a,$25dc
	dc.w	$2597,$c5b5,$3a4b,$2597
	dc.w	$2553,$c5d4,$3a2c,$2553
	dc.w	$250f,$c5f3,$3a0d,$250f
	dc.w	$24cc,$c612,$39ee,$24cc
	dc.w	$248a,$c631,$39cf,$248a
	dc.w	$2448,$c651,$39af,$2448
	dc.w	$2407,$c670,$3990,$2407
	dc.w	$23c7,$c690,$3970,$23c7
	dc.w	$2387,$c6af,$3951,$2387
	dc.w	$2347,$c6cf,$3931,$2347
	dc.w	$2309,$c6ef,$3911,$2309
	dc.w	$22ca,$c70e,$38f2,$22ca
	dc.w	$228d,$c72e,$38d2,$228d
	dc.w	$2250,$c74e,$38b2,$2250
	dc.w	$2213,$c76e,$3892,$2213
	dc.w	$21d7,$c78e,$3872,$21d7
g2wide_castrots_end


; c87b80e: The permanently disabled GLOOMBENCH2 automation harness,
; result writer and private state were removed from the release build.

camrotsinc	incbin	camrots.bin	;256
camrots2inc	incbin	camrots2.bin	;1024
chatfont	incbin	chatfont.bin

copinit_ecs	dc	$096,$120
	;
	dc	$08e,$2ca1,$090,$1ce1	;v17: stronger 320x240 right-centering test
	dc	$092,$38,$094,$d0,$102,0,$104,0,$106,0
	dc	$100,$6200,$108,5*40,$10a,5*40,$10c,0
	;
	;palette layout:
	;
	;hinybs of first 32,lonybs,hinybs of second 32,lonybs
	;
palette_ecs	dc	$180,0,$182,0,$184,0,$186,0
	dc	$188,0,$18a,0,$18c,0,$18e,0
	dc	$190,0,$192,0,$194,0,$196,0
	dc	$198,0,$19a,0,$19c,0,$19e,0
	dc	$1a0,0,$1a2,0,$1a4,0,$1a6,0
	dc	$1a8,0,$1aa,0,$1ac,0,$1ae,0
	dc	$1b0,0,$1b2,0,$1b4,0,$1b6,0
	dc	$1b8,0,$1ba,0,$1bc,0,$1be,0
	;
bitplanes_ecs	dc	$e0,0,$e2,0
	dc	$e4,0,$e6,0
	dc	$e8,0,$ea,0
	dc	$ec,0,$ee,0
	dc	$f0,0,$f2,0
	dc	$f4,0,$f6,0
	;
	dc	26<<8+1,$fffe
	;
sprites_ecs	dc	$140,0,$142,0,$144,0,$146,0
	dc	$148,0,$14a,0,$14c,0,$14e,0
	dc	$150,0,$152,0,$154,0,$156,0
	dc	$158,0,$15a,0,$15c,0,$15e,0
	dc	$160,0,$162,0,$164,0,$166,0
	dc	$168,0,$16a,0,$16c,0,$16e,0
	dc	$170,0,$172,0,$174,0,$176,0
	dc	$178,0,$17a,0,$17c,0,$17e,0
	;
	dc	32<<8+1,$fffe,$096,$8100
	;
	dc.l	$fffffffe
copfinit_ecs	;

cols32	macro	;bank,losel
	dc	$106,(\1<<13)|(\2<<9)
	dc	$180,0,$182,0,$184,0,$186,0
	dc	$188,0,$18a,0,$18c,0,$18e,0
	dc	$190,0,$192,0,$194,0,$196,0
	dc	$198,0,$19a,0,$19c,0,$19e,0
	dc	$1a0,0,$1a2,0,$1a4,0,$1a6,0
	dc	$1a8,0,$1aa,0,$1ac,0,$1ae,0
	dc	$1b0,0,$1b2,0,$1b4,0,$1b6,0
	dc	$1b8,0,$1ba,0,$1bc,0,$1be,0
	endm

copinit_aga	;copperlist for AGA amigas
	;
	dc	$1fc,15,$096,$120
	;
	dc	$08e,$2ca1,$090,$1ce1	;v17: stronger right-centering test
	dc	$092,$38,$094,$a0,$102,0,$104,0,$106,0
	dc	$100,$7200,$108,7*40,$10a,7*40,$10c,0
	;
	;palette layout:
	;
	;hinybs of first 32,lonybs,hinybs of second 32,lonybs
	;
palette_aga	cols32	0,0
	cols32	0,1
	cols32	1,0
	cols32	1,1
	cols32	2,0
	cols32	2,1
	cols32	3,0
	cols32	3,1
	cols32	4,0
	cols32	4,1
	cols32	5,0
	cols32	5,1
	cols32	6,0
	cols32	6,1
	cols32	7,0
	cols32	7,1
	;
bitplanes_aga	dc	$e0,0,$e2,0
	dc	$e4,0,$e6,0
	dc	$e8,0,$ea,0
	dc	$ec,0,$ee,0
	dc	$f0,0,$f2,0
	dc	$f4,0,$f6,0
	dc	$f8,0,$fa,0
	dc	$fc,0,$fe,0
	;
	dc	26<<8+1,$fffe
	;
sprites_aga	dc	$140,0,$142,0,$144,0,$146,0
	dc	$148,0,$14a,0,$14c,0,$14e,0
	dc	$150,0,$152,0,$154,0,$156,0
	dc	$158,0,$15a,0,$15c,0,$15e,0
	dc	$160,0,$162,0,$164,0,$166,0
	dc	$168,0,$16a,0,$16c,0,$16e,0
	dc	$170,0,$172,0,$174,0,$176,0
	dc	$178,0,$17a,0,$17c,0,$17e,0
	;
	dc	32<<8+1,$fffe,$096,$8100
	;
	dc.l	$fffffffe
copfinit_aga	;



		even
		;
		; v13 built-in fallback C2P.  This is the original c2p/blackmagic_1
		; algorithm embedded as a safety net, so gameplay is not dependent on
		; the helper file being found through the current directory.
		;
g2v13_c2pname	dc.b	'c2p/blackmagic_1',0
		even


; ---------------------------------------------------------------------------
; c87b37: Kalm's C2P dispatcher
;
; Existing BlackMagic-compatible call ABI:
;   a0 = contiguous chunky source
;   a1 = destination plane 0, already including byte offset
;   d0.w = width, d1.w = height
;   d2.l = plane size, d3.l = destination row length
;
; Kalm's c5 routines process a compact chunky rectangle and contiguous planes.
; Gloom's fixed full-width passes (320x240 gameplay, 320x32 HUD, 320x16 panel,
; and the complete 320x240 two-player composition) meet that contract whenever
; the renderer owns a true linear coloffs table.  Resolution expansion restores the native output before C2P; incompatible/static
; layouts retain the proven legacy converter.
;
g2kalms_cpu_020	equ	0	; GEN, used by 68020 and 68030
g2kalms_cpu_040	equ	2	; K040, used by 68040 and 68060
g2kalms_attnflags	equ	296
g2kalms_afb_68040	equ	3

g2kalms_cpu_mode	dc.w	g2kalms_cpu_020
g2kalms_active_planes	dc.w	0
g2kalms_linear_active	dc.w	0	;c87b37: -1 only while planar renderer writes row-major chunky
g2kalms_legacy_c2p	dc.l	g2v13_doc2p_1X1X8
g2kalms_last_width	dc.w	-1
g2kalms_last_height	dc.w	-1
g2kalms_last_planes	dc.w	-1
	even

; c87b37: switch the planar one-player renderer to ordinary row-major chunky
; only where Kalm c5 is actually compatible.  The already proven P96 linear
; renderer demonstrated that walls, flats, sprites, gun, HUD and effects all
; honour coloffs, so changing this table is sufficient and costs no copy pass.
g2kalms_prepare_frame_layout
	movem.l	d0-d3/a0-a1,-(a7)
	; P96 owns its own linear table and must never share this state.
	cmp.w	#2,g2display_mode
	beq.w	.legacy
	; TWO PLAYER rewrites/centres the legacy table for each split half.
	tst.w	twowins
	bne.w	.legacy
	; c5 has no horizontal destination modulo.  It is therefore safe only
	; when one complete chunky row maps to the complete 40-byte planar row.
	cmp.w	#320,width
	bne.w	.legacy
	cmp.w	#320,chunkymodw
	bne.w	.legacy
	cmp.w	#240,hite
	bne.w	.legacy
	cmp.l	#40,linemod
	bne.w	.legacy
	cmp.l	#40*240,bpmod
	bne.w	.legacy
	move.w	bitplanes,d0
	cmp.w	#6,d0
	beq.s	.enable
	cmp.w	#8,d0
	bne.w	.legacy
.enable
	tst.w	g2kalms_linear_active
	bne.s	.done
	; Build the normal x->byte table: 0,1,2,...319.
	jsr	g2kalms_build_linear_coloffs
	move.w	#-1,g2kalms_linear_active
	; Old bytes belong to the permuted layout.  Clear once at ownership change
	; so any intentionally untouched background pixels cannot leak through.
	jsr	g2clearfullchunky
	bra.s	.done
.legacy
	; This call occurs at the start of a real render frame, so the chunky
	; buffer is valid and can be cleared if ownership changes.
	jsr	g2kalms_prepare_legacy_render_layout
.done
	movem.l	(a7)+,d0-d3/a0-a1
	rts

; c87b40: select linear ownership for the complete planar TWO PLAYER frame.
; Each half still renders with its own centred crop table, but both halves share
; a normal 320-byte row stride and together form one compact 320x240 Kalm input.
; RESOLUTION is applied later per split half; this stage owns the native frame.
g2kalms_prepare_twoplayer_frame_layout
	movem.l	d0-d3/a0-a1,-(a7)
	tst.w	twowins
	beq.s	.legacy
	move.w	g2twop_view_width,d0
	cmp.w	g2render_stride,d0
	bne.s	.legacy
	; c87b79c: P96 plain/5:4 uses 320-byte rows; true WIDE uses 428.
	; P96 does not require planar stride/plane checks.
	cmp.w	#2,g2display_mode
	beq.s	.enable
	cmp.w	#320,d0		; planar owners remain the proven 320-wide layout
	bne.s	.legacy
	cmp.l	#40,linemod
	bne.s	.legacy
	cmp.l	#40*240,bpmod
	bne.s	.legacy
	move.w	bitplanes,d0
	cmp.w	#6,d0
	beq.s	.enable
	cmp.w	#8,d0
	bne.s	.legacy
.enable
	move.w	#-1,g2kalms_linear_active
	jsr	g2twop_restore_coloffs	;c87b79c: build 320 or 428 linear table
	bra.s	.done
.legacy
	jsr	g2kalms_prepare_legacy_render_layout
.done
	movem.l	(a7)+,d0-d3/a0-a1
	rts

; Shared full-width linear table builder.  It deliberately does not alter the
; ownership flag and does not clear chunky, so callers can use it both for an
; ownership transition and for repeated TWO PLAYER HUD/crop table restoration.
g2kalms_build_linear_coloffs
	movem.l	d0-d1/a0,-(a7)
	lea	coloffs,a0
	moveq	#0,d0
	move.w	#319,d1
.loop
	move.l	d0,(a0)+
	addq.l	#1,d0
	dbf	d1,.loop
	movem.l	(a7)+,d0-d1/a0
	rts

; Rendering-safe legacy switch.  Unlike the lifecycle-only restore below, this
; may clear chunky because drawall has already established a valid frame buffer.
g2kalms_prepare_legacy_render_layout
	tst.w	g2kalms_linear_active
	beq.s	.done
	jsr	g2kalms_restore_legacy_layout
	jsr	g2clearfullchunky
.done
	rts

; Restore BlackMagic's exact 16-pixel permutation.  This lifecycle-safe helper
; never touches chunky: title/shutdown paths may call it after that buffer has
; already been released.
g2kalms_restore_legacy_layout
	movem.l	d0-d2/a0-a1,-(a7)
	tst.w	g2kalms_linear_active
	beq.s	.done
	lea	coloffs,a0
	move.w	#320,d0
	lea	paladjust,a1
	jsr	g2_inline_c2p_init
	clr.w	g2kalms_linear_active
.done
	movem.l	(a7)+,d0-d2/a0-a1
	rts

g2kalms_startup_init
	movem.l	d0-d2/a6,-(a7)
	move.l	4.w,a6
	move.w	g2kalms_attnflags(a6),d0
	moveq	#g2kalms_cpu_020,d1	; 020/030 = confirmed GEN winner
	btst	#g2kalms_afb_68040,d0
	beq.s	.mode_ready
	moveq	#g2kalms_cpu_040,d1	; 040/060 = confirmed K040 winner
.mode_ready
	move.w	d1,g2kalms_cpu_mode
	move.w	bitplanes,g2kalms_active_planes
	clr.w	g2kalms_linear_active
	move.w	#-1,g2kalms_last_width
	move.w	#-1,g2kalms_last_height
	move.w	#-1,g2kalms_last_planes
	movem.l	(a7)+,d0-d2/a6
	rts

g2kalms_c2p_dispatch
	; Kalm is valid only while the renderer explicitly owns the linear table.
	; This prevents 320-wide title/static legacy buffers from being misidentified
	; solely by dimensions, while c87b40 deliberately admits linear TWO PLAYER.
	tst.w	g2kalms_linear_active
	beq.w	.legacy
	; Reject every layout not proven compatible with the compact c5 contract.
	cmp.w	#320,d0
	bne.w	.legacy
	cmp.l	#40*240,d2
	bne.w	.legacy
	cmp.l	#40,d3
	bne.w	.legacy
	tst.w	d1
	ble.w	.legacy
	cmp.w	#256,d1
	bhi.w	.legacy
	move.w	bitplanes,d4
	cmp.w	#6,d4
	beq.s	.compatible
	cmp.w	#8,d4
	bne.w	.legacy
.compatible
	; Select the active six- or eight-plane implementation and initialise only
	; the frame dimensions. No K030 SMC path remains in the final build.
	move.w	g2kalms_cpu_mode(pc),d5
	cmp.w	#g2kalms_cpu_040,d5
	beq.w	.cpu040

.cpu020
	moveq	#0,d2
	moveq	#0,d3
	cmp.w	#6,d4
	beq.s	.cpu020_6
	jsr	g2k_c2p1x1_8_c5_gen_init
	jsr	g2k_c2p1x1_8_c5_gen
	rts
.cpu020_6
	jsr	g2k_c2p1x1_6_c5_gen_init
	jsr	g2k_c2p1x1_6_c5_gen
	rts

.cpu040
	moveq	#0,d2
	moveq	#0,d3
	move.l	#40,d4
	move.l	#40*240,d5
	move.l	#320,d6
	cmp.w	#6,bitplanes
	beq.s	.cpu040_6
	jsr	g2k_c2p1x1_8_c5_040_init
	jsr	g2k_c2p1x1_8_c5_040
	rts
.cpu040_6
	jsr	g2k_c2p1x1_6_c5_040_init
	jsr	g2k_c2p1x1_6_c5_040
	rts

.legacy
	move.l	g2kalms_legacy_c2p(pc),a2
	jmp	(a2)

g2v13_rotbits	macro	;reg1,reg2,shift
		move.l	\1,d4
		and.l	d6,\1
		eor.l	\1,d4
		lsl.l	#\3,\1
		;
		move.l	\2,d5
		and.l	d6,d5
		eor.l	d5,\2
		lsr.l	#\3,\2
		or.l	d4,\2
		or.l	d5,\1
		endm

g2v13_doc2p_1X1X8
		move.l	#$0f0f0f0f,a2
		move.l	#$33333333,a3
		move.l	#$5555aaaa,a4
		move.l	d2,a5
		lsl.l	#3,d2
		move.l	d2,a6
		sub.l	a5,a6
		subq.l	#2,a6
		lsr	#4,d0
		move	d0,d2
		ext.l	d2
		add.l	d2,d2
		add.l	a6,d2
		sub.l	d2,d3
		move.l	d3,-(a7)
		subq	#1,d1
		move	d1,d7
		swap	d7
		subq	#1,d0
		move	d0,d7
		subq	#2,a7
		move	d7,-(a7)
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		bra.s	.g2v13_8_here
.g2v13_8_loop2
		swap	d7
		bra.s	.g2v13_8_here
.g2v13_8_loop
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		sub.l	a6,a1
.g2v13_8_here
	g2v13_rotbits	d0,d2,4
	g2v13_rotbits	d1,d3,4
		move.l	a3,d6
	g2v13_rotbits	d0,d1,2
		move.l	a4,d6
		move.l	d0,d4
		and.l	d6,d4
		eor.l	d4,d0
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d0
		move	d0,(a1)
		add.l	a5,a1
		move.l	d1,d4
		and.l	d6,d4
		eor.l	d4,d1
		swap	d0
		move	d0,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d1
		move	d1,(a1)
		add.l	a5,a1
		move.l	a3,d6
	g2v13_rotbits	d2,d3,2
		move.l	a4,d6
		move.l	d2,d4
		and.l	d6,d4
		eor.l	d4,d2
		swap	d1
		move	d1,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d2
		move	d2,(a1)
		add.l	a5,a1
		move.l	d3,d4
		and.l	d6,d4
		eor.l	d4,d3
		swap	d2
		move	d2,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d3,d4
		move	d4,(a1)
		add.l	a5,a1
		dbf	d7,.g2v13_8_loop
		move	(a7),d7
		swap	d7
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		add.l	4(a7),a1
		dbf	d7,.g2v13_8_loop2
		addq	#8,a7
		rts

g2v13_doc2p_1X1X6
		move.l	#$0f0f0f0f,a2
		move.l	#$33333333,a3
		move.l	#$5555aaaa,a4
		move.l	d2,a5
		lsl.l	#2,d2
		add.l	a5,d2
		move.l	d2,a6
		subq.l	#2,a6
		lsr	#4,d0
		move	d0,d2
		ext.l	d2
		add.l	d2,d2
		add.l	a6,d2
		sub.l	d2,d3
		move.l	d3,-(a7)
		subq	#1,d1
		move	d1,d7
		swap	d7
		subq	#1,d0
		move	d0,d7
		subq	#2,a7
		move	d7,-(a7)
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		bra.s	.g2v13_6_here
.g2v13_6_loop2
		swap	d7
		bra.s	.g2v13_6_here
.g2v13_6_loop
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		sub.l	a6,a1
.g2v13_6_here
	g2v13_rotbits	d0,d2,4
	g2v13_rotbits	d1,d3,4
		move.l	a3,d6
	g2v13_rotbits	d0,d1,2
		move.l	a4,d6
		move.l	d0,d4
		and.l	d6,d4
		eor.l	d4,d0
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d0
		move	d0,(a1)
		add.l	a5,a1
		move.l	d1,d4
		and.l	d6,d4
		eor.l	d4,d1
		swap	d0
		move	d0,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d4,d1
		move	d1,(a1)
		add.l	a5,a1
		move.l	a3,d6
	g2v13_rotbits	d2,d3,2
		move.l	a4,d6
		move.l	d2,d4
		and.l	d6,d4
		eor.l	d4,d2
		swap	d1
		move	d1,(a1)
		add.l	a5,a1
		lsr	#1,d4
		swap	d4
		add	d4,d4
		or.l	d2,d4
		move	d4,(a1)
		add.l	a5,a1
		dbf	d7,.g2v13_6_loop
		move	(a7),d7
		swap	d7
		movem.l	(a0)+,d0-d3
		move.l	a2,d6
		swap	d4
		move	d4,(a1)
		add.l	4(a7),a1
		dbf	d7,.g2v13_6_loop2
		addq	#8,a7
		rts


