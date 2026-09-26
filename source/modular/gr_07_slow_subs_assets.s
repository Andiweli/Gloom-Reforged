;************** SLOW SUBS **********************

slowsubs

;MOVE d1,d4:LSL #8,d1:MOVE.b d4,d1:MOVE d1,d4:SWAP d1:MOVE d4,d1
;MOVE d2,d4:LSL #8,d2:MOVE.b d4,d2:MOVE d2,d4:SWAP d2:MOVE d4,d2
;MOVE d3,d4:LSL #8,d3:MOVE.b d4,d3:MOVE d3,d4:SWAP d3:MOVE d4,d3
;;EXT.l d0:MOVE.l (a0),a0:LEA 44(a0),a0:JMP -$354(a6)
;LEA table(pc),a1:MOVE.b d0,3(a1):MOVEM.l d1-d3,4(a1)
;MOVE.l (a0),a0:LEA 44(a0),a0:JMP -$372(a6)
;table:Dc.l $00010000,0,0,0,0

lastpal	dc.l	0
g2static_palette_count	dc	256	;c87b4: active picture palette entries (2^IFF depth)

; Restore the last picture/game palette with the same safe entry count that
; was used when it was installed.  initfontpal calls pokepal2 directly and
; therefore deliberately leaves lastpal/count untouched.
pokelastpal	move.l	lastpal(pc),a1
	move	g2static_palette_count(pc),d0
	bra	pokepal2
	;
pokepal	;a1=normal full game palette to poke
	;
	move.l	a1,lastpal
	move	colours(pc),d0
	move	d0,g2static_palette_count
pokepal2	;
	; c87b78h: register the palette transaction before the selected hardware/
	; source backend consumes it. The helper preserves every input register.
	jsr	g2p96_palette_note_update_c87b78h
	; c87b79p: DISPLAY=P96 owns palette publication unconditionally. Never trust
	; a legacy topokepal pointer to reach pokepal_os/aga/ecs behind P96.
	cmp	#2,g2display_mode
	bne.s	.g2c87b79p_native_dispatch
	jmp	pokepal_p96_source
.g2c87b79p_native_dispatch
	move.l	topokepal(pc),a0
	jmp	(a0)

; c87b4: trimmed-IFF palettes contain exactly 2^depth AGA colour pairs:
; 6-bit pictures use 64 entries/256 bytes, 7-bit 128/512, 8-bit 256/1024.
; Reading all 256 entries from every .pal walked beyond shorter files and
; caused the later Gloom3/ZM intermission false colours and possible crashes.
; in: a0=trimmed IFF (may be 0), a1=palette.  Same clobbers as pokepal.
g2pokepal_picture
	move.l	a1,lastpal
	move	colours(pc),d0	;safe fallback
	tst.l	a0
	beq.s	.store
	moveq	#0,d1
	move	4(a0),d1		;trimmed-IFF source depth
	cmp	#1,d1
	blo.s	.store
	cmp	#8,d1
	bhi.s	.store
	moveq	#1,d0
	lsl	d1,d0		;palette entries = 1 << depth
	cmp	colours(pc),d0
	bls.s	.store
	move	colours(pc),d0
.store	move	d0,g2static_palette_count
	bra	pokepal2

to32	macro
	move	\1,d5
	lsl	#8,\1
	move.b	d5,\1
	move	\1,d5
	swap	\1
	move	d5,\1
	endm

pokepal_os	;
	;OS version!
	;
	move.l	temppal(pc),a0
	move	d0,(a0)+	;how many
	clr	(a0)+	;first colour
	subq	#1,d0
	;
.loop	move	(a1)+,d1	;hi nyb
	move	d1,d2
	move	d1,d3
	move	d1,d4
	tst	aga
	beq.s	.skip
	move	(a1)+,d4
	;
.skip	move	d4,d5
	and	#$f00,d1
	lsr	#4,d1
	and	#$f00,d5
	lsr	#8,d5
	or	d5,d1
	to32	d1
	;
	move	d4,d5
	and	#$0f0,d2
	and	#$0f0,d5
	lsr	#4,d5
	or	d5,d2
	to32	d2
	;
	and	#$00f,d3
	lsl	#4,d3
	and	#$00f,d4
	or	d4,d3
	to32	d3
	;
	movem.l	d1-d3,(a0)
	lea	12(a0),a0
	dbf	d0,.loop
	clr.l	(a0)
	;
	move.l	viewport,a0
	move.l	temppal(pc),a1
	move.l	grbase(pc),a6
	jmp	-$372(a6)

pokepal_ecs	move.l	coplist,a2
	lea	palette_ecs-copinit_ecs(a2),a2
	subq	#1,d0
.loop0	move	(a1)+,2(a2)
	addq	#4,a2
	dbf	d0,.loop0
	rts

pokepal_aga	move.l	coplist,a2
	lea	palette_aga-copinit_aga(a2),a2
	subq	#1,d0
	move	d0,d2
	and	#31,d2
.loop	move	d2,d1
.loop2	move	(a1)+,6(a2)
	move	(a1)+,132+6(a2)
	addq	#4,a2
	dbf	d1,.loop2
	lea	264-128(a2),a2
	dbf	d0,.loop
	rts

decodeiff	;
	;a0=trimmed IFF file
	;a1=dest bitmap
	;
	move.l	bpmod(pc),d7
	;
	move	(a0)+,d0	;pixel width
	lsr	#3,d0	;to byte width
	move	(a0)+,d1	;pixel height
	cmp	#240,d1
	bls.s	.hok
	move	#240,d1
.hok	subq	#1,d1	;to dbf
	move	(a0)+,d2	;depth
	subq	#1,d2	;to dbf
	addq	#6,a0	;skip header
	;
.loop5	move	d2,d5	;depth
	move.l	a1,-(a7)	;start of newline
	;
.loop4	move.l	a1,a2
	; ECS1: source pictures may contain more planes than the active target.
	; Consume every ByteRun1 row, but discard planes >= bitplanes so a
	; 7/8-plane source can never write beyond a 6-plane ECS bitmap.
	move	d2,d6
	sub	d5,d6		;zero-based source plane index
	cmp	bitplanes(pc),d6
	bcs.s	.g2ecs1_decode_dest_ok
	lea	g2ecs1_decode_sink(pc),a2
.g2ecs1_decode_dest_ok
	move	d0,d4	;how many bytes in line
	;
.loop	moveq	#0,d3
	move.b	(a0)+,d3
	bmi.s	.repeat
	sub	d3,d4
.loop3	move.b	(a0)+,(a2)+
	dbf	d3,.loop3
	bra.s	.skip
	;
.repeat	cmp.b	#-128,d3
	beq.s	.loop
	neg.b	d3
	sub	d3,d4
.loop2	move.b	(a0),(a2)+
	dbf	d3,.loop2
	addq	#1,a0
.skip	subq	#1,d4
	bgt.s	.loop
	;
	; Advance the destination plane pointer only while this source plane
	; actually maps to an allocated destination plane.
	move	d2,d6
	sub	d5,d6
	cmp	bitplanes(pc),d6
	bcc.s	.g2ecs1_decode_no_advance
	add.l	d7,a1
.g2ecs1_decode_no_advance
	dbf	d5,.loop4
	;
	move	bitplanes(pc),d3
	subq	#1,d3
	sub	d2,d3
	ble.s	.noxs
	subq	#1,d3
	moveq	#0,d5
.c	move.l	a1,a2
	moveq	#9,d4	;clear a line
.cc	move.l	d5,(a2)+
	dbf	d4,.cc
	add.l	d7,a1
	dbf	d3,.c
.noxs	;
	move.l	(a7)+,a1
	add.l	linemod(pc),a1
	dbf	d1,.loop5
	;
	rts

; Scratch row for source planes which do not exist in the destination.
; 128 bytes safely covers the normal 320-pixel rows and wider test assets.
g2ecs1_decode_sink	ds.b	128
	even

copypic	cmp	#2,g2display_mode	;c87b79x: P96 has no planar pages
	beq.s	.g2c87b79x_done
	movem.l	showbitmap,a0-a1
	move.l	bmapmem(pc),d1
	lsr.l	#2,d1
	subq	#1,d1
.loop	move.l	(a0)+,(a1)+
	dbf	d1,.loop
.g2c87b79x_done
	rts

clspic	cmp	#2,g2display_mode	;c87b79x: P96 clear is direct-index owned
	beq.s	.g2c87b79x_done
	move.l	drawbitmap,a1
	move.l	bmapmem(pc),d1
	lsr.l	#2,d1
	subq	#1,d1
	moveq	#0,d0
.loop	move.l	d0,(a1)+
	dbf	d1,.loop
	jmp	db
.g2c87b79x_done
	rts

showpic	;a0=trimmed IFF file, a1=palette
	;
	jmp	g2p96_static_showpic_native_entry	;c86zjl: same-size trampoline (JMP+NOP replaces MOVEM+BSR.W)
	nop
	jsr	vwait
	movem.l	(a7),a0-a1
	tst.l	a0	;v190cj: absent picture -> blank safe frame
	beq.s	.nopic
	move.l	drawbitmap(pc),a1
	bsr	decodeiff
.nopic	movem.l	(a7)+,a0-a1
	tst.l	a1	;v190cj: absent palette -> keep current palette
	beq.s	.nopal
	bsr	g2pokepal_picture
.nopal	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active	;c86zgv: targeted staged P96 static present
	bra	vwait

showpic_noclear	;a0=trimmed IFF file, a1=palette
	; redraw without the intermediate blank/black clear to avoid
	; visible flicker on title/about transitions.
	jmp	g2p96_static_showpic_noclear_native_entry	;c86zjl: same-size trampoline
	beq.s	.nopic
	move.l	drawbitmap(pc),a1
	bsr	decodeiff
.nopic	movem.l	(a7)+,a0-a1
	tst.l	a1
	beq.s	.nopal
	bsr	g2pokepal_picture
.nopal	jsr	db
	jsr	g2p96_static_present_showbitmap_plain_if_active	;c86zgv: targeted staged P96 static present
	bra	vwait

	ifne	cd32

applname	dc.b	'Gloom',0
	even
itemname	dc.b	'Games',0
	even

gloomgame2	dc.b	'gamegamegamegamegame'

nvname	dc.b	'nonvolatile.library',0
	cnop	0,4
nv	dc.l	0

savegloomgame	;
	move.l	nv,d0
	beq.s	.done
	;
	move.l	d0,a6
	lea	applname(pc),a0
	lea	itemname(pc),a1
	lea	gloomgame2(pc),a2
	moveq	#2,d0	;20 bytes
	moveq	#-1,d1
	jsr	-42(a6)	;storenv
	tst.l	d0
	bne.s	.done	;error!
	;
	lea	applname(pc),a0
	lea	itemname(pc),a1
	moveq	#-1,d1
	moveq	#1,d2
	jsr	-66(a6)	;setnvprotection
	;
.done	rts

loadgloomgame	move.l	nv,d0
	beq.s	.done
	;
	move.l	d0,a6
	lea	applname(pc),a0
	lea	itemname(pc),a1
	moveq	#-1,d1
	jsr	-30(a6)	;getcopnv
	tst.l	d0
	beq.s	.done
	;
	move.l	d0,a0
	lea	gloomgame2(pc),a1
	moveq	#4,d1	;5 longs=20 bytes
.loop	move.l	(a0)+,(a1)+
	dbf	d1,.loop
	;
	move.l	d0,a0
	jsr	-36(a6)	;freenvdata
	;
.done	rts

	endc

flushc	;flush cache!
	;
	movem.l	a0-a1/d0-d1/a6,-(a7)
	move.l	4.w,a6
	cmp	#636,16(a6)
	bcs.s	.skip
	jsr	-636(a6)
.skip	movem.l	(a7)+,a0-a1/d0-d1/a6
	rts

findanglesign	;d1=angle I'm at ; d0=angle I wanna be at...return sign
	;(bmi, bpl) of add to get there
	;return cc (mi,pl) and d0.w (for tst) of sign to get there!
	;
	and	#255,d0
	and	#255,d1
	sub	d0,d1
	bpl.s	.plus
	;
	moveq	#1,d0
	cmp	#-128,d1
	bgt.s	.rts
	neg	d0
.rts	neg	d0
	rts
	;
.plus	moveq	#1,d0	;+
	cmp	#128,d1
	bge.s	.rts2
	neg	d0
.rts2	neg	d0
	rts

checklock	cmp	#2,d0
	bgt.s	.max
	cmp	#-2,d0
	bge.s	.rts
	moveq	#-2,d0
.rts	rts
.max	moveq	#2,d0
	rts

locklogic	;locking on to defender machine
	;
	bsr	playertimers	;do timer stuff...
	bsr	getcntrl	;player control
	;
	moveq	#0,d2	;how many locked
	move	ob_x(a5),d0
	sub	ob_telex(a5),d0
	bne.s	.lockx
	addq	#1,d2
	bra.s	.lockx2
.lockx	bsr	checklock
	sub	d0,ob_x(a5)
.lockx2	;
	move	ob_z(a5),d0
	sub	ob_telez(a5),d0
	bne.s	.lockz
	addq	#1,d2
	bra.s	.lockz2
.lockz	bsr	checklock
	sub	d0,ob_z(a5)
.lockz2	;
	move	ob_rot(a5),d1
	move	ob_telerot(a5),d0
	bsr	findanglesign
	;
	move	ob_rot(a5),d1
	sub	ob_telerot(a5),d1
	and	#255,d1
	bne.s	.lockrot
	addq	#1,d2
	bra.s	.lockrot2
.lockrot	cmp	#4,d1
	bls.s	.skip
	cmp	#256-4,d1
	bcs.s	.four
	or	#$ff00,d1
	neg	d1
	bra.s	.skip
.four	moveq	#4,d1
.skip	tst	d0
	bmi.s	.skip2
	neg	d1
.skip2	add	d1,ob_rot(a5)
	;
.lockrot2	bsr	unbounce
	tst	ob_bounce(a5)
	bne.s	.rts
	;
	subq	#3,d2
	bne.s	.rts
	;
	clr	ob_rotspeed(a5)
	move.l	#playdefender,ob_logic(a5)
	;
	move.b	floortag(pc),d0
	sub.b	#49,d0	;'1'->0
	ext	d0
	move	ltk(pc,d0*2),landerstokill
	move	lnd(pc,d0*2),landerdelay
	;
	move	#3,playerlives
	;
	bra	initnewdef
	;
.rts	rts

ltk	dc	20,35,50
lnd	dc	25,20,15

playdefender	bsr	atmachine
	bsr	defender
	move	landerstokill(pc),d0
	ble.s	.win
	move	playerlives(pc),d0
	ble.s	.lose
	rts
.win	addq	#1,ob_lives(a5)
	move	#-1,ob_update(a5)
	tst	gametype
	beq.s	.lose
	jsr	getother
	tst	ob_lives(a0)
	beq.s	.lose
	addq	#1,ob_lives(a0)
	move	#-1,ob_update(a0)
.lose	move	#96,ob_delay(a5)
	move.l	#waittolive,ob_logic(a5)
	rts

waittolive	bsr	atmachine
	bsr	defender
	subq	#1,ob_delay(a5)
	bgt.s	.rts
	move.l	#playerlogic,ob_logic(a5)
.rts	rts

atmachine	;standing at machine logic
	;
	bsr	playertimers	;do timer stuff...
	bsr	getcntrl	;player control
	;
	;OK, rotate slightly in front of machine!
	;
	move	joyx(pc),d0
	bne.s	.rot
	move	ob_rotspeed(a5),d0
	bpl.s	.rp
	addq	#2,ob_rotspeed(a5)
	ble.s	.rotdone
	clr	ob_rotspeed(a5)
	bra.s	.rotdone
.rp	subq	#2,ob_rotspeed(a5)
	bge.s	.rotdone
	clr	ob_rotspeed(a5)
	bra.s	.rotdone
.rot	bgt.s	.rplus
	subq	#1,ob_rotspeed(a5)
	cmp	#-8,ob_rotspeed(a5)
	bge.s	.rotdone
	move	#-8,ob_rotspeed(a5)
	bra.s	.rotdone
.rplus	addq	#1,ob_rotspeed(a5)
	cmp	#8,ob_rotspeed(a5)
	ble.s	.rotdone
	move	#8,ob_rotspeed(a5)
.rotdone	;
	move	ob_rotspeed(a5),d0
	move	d0,d4
	add	ob_telerot(a5),d0
	move	d0,ob_rot(a5)
	;
	move	d4,d5
	add	d4,d4
	add	d5,d4
	add	d4,d4
	;
	sub	#64,d0
	and	#255,d0
	move.l	camrots(pc),a0
	lea	0(a0,d0*8),a0
	move	d4,d5
	muls	2(a0),d4
	neg.l	d4
	swap	d4
	muls	6(a0),d5
	swap	d5
	add	ob_telex(a5),d4
	add	ob_telez(a5),d5
	move	d4,ob_x(a5)
	move	d5,ob_z(a5)
	rts

maxdefobjects	equ	128

	rsreset
	;
de_next	rs.l	1
de_prev	rs.l	1
de_xa	rs.l	1
de_ya	rs.l	1
de_x	rs.l	1
de_y	rs.l	1
de_shape	rs.w	1
de_delay	rs.w	1
de_colltype	rs.w	1
de_collwith	rs.w	1
de_logic	rs.l	1
	;
de_size	rs.b	0

defshapes	;
	dc	65,36,6,3	;0
	dc	65,40,6,3	;1
	dc	66,44,3,1	;2
	dc	66,46,3,1	;3
	dc	72,37,5,5	;4
	dc	84,37,1,1	;5
	dc	86,39,1,1	;6
	dc	81,39,1,1	;7
	dc	79,37,1,1	;8
	dc	71,44,2,1	;9
	dc	65,49,15,12	;10
	dc	86,49,11,10	;11
	dc	79,42,2,5	;12
	dc	85,42,2,5	;13

landerstoadd	dc	10	;how manylanders left!
landerstokill	dc	10
landerdelay	dc	25	;wait between landers
landercnt	dc	1
	;
defstack	dc.l	0
deflbut	dc.l	0	;last button status!
playerxa	dc.l	0	;x speed!
playerx	dc	0,0
playery	dc	14,0
playershape	dc	0
playerlives	dc	0

movedefplayer	move	joyx(pc),d0
	beq.s	.nox
	bpl.s	.xrite
	move	#1,playershape
	sub.l	#$8000,playerxa
	bpl.s	.xmore
	cmp.l	#-$30000,playerxa
	bge.s	.xdone
	move.l	#-$30000,playerxa
	bra.s	.xdone
.xmore	sub.l	#$4000,playerxa
	bra.s	.xdone
	;
.xrite	clr	playershape
	add.l	#$8000,playerxa
	ble.s	.xmore2
	cmp.l	#$30000,playerxa
	ble.s	.xdone
	move.l	#$30000,playerxa
	bra.s	.xdone
.xmore2	add.l	#$4000,playerxa
	bra.s	.xdone
	;
.nox	;to rest!
	move.l	playerxa(pc),d0
	beq.s	.xdone
	bpl.s	.xp
	add.l	#$1000,playerxa
	ble.s	.xdone
	clr.l	playerxa
.xp	sub.l	#$1000,playerxa
	bge.s	.xdone
	clr.l	playerxa
.xdone	;
	move.l	playerxa(pc),d0
	add.l	d0,playerx
	and	#255,playerx
	;
	move	joyy(pc),d0
	add	d0,playery
	cmp	#1,playery
	blt.s	.yf
	cmp	#34,playery
	blt.s	.ydone
	move	#34,playery
	bra.s	.ydone
.yf	move	#1,playery
.ydone	;
	move	joyb(pc),d0
	beq	.nofire
	move	deflbut(pc),d0
	bne	.rts
	st	deflbut
	;
	addfirst	defobjects
	beq.s	.rts
	move.l	#$20000,d0	;bullet speed!
	move	playershape(pc),d1
	beq.s	.rite
	neg.l	d0
.rite	add.l	playerxa(pc),d0
	move.l	d0,de_xa(a0)
	move	playerx(pc),de_x(a0)
	move	playery(pc),de_y(a0)
	addq	#1,de_y(a0)
	move	playershape(pc),d0
	addq	#2,d0
	move	d0,de_shape(a0)
	move	#2,de_colltype(a0)
	move.l	#defbull,de_logic(a0)
	move	#12,de_delay(a0)
	move.l	shootsfx3(pc),a0
	moveq	#32,d0
	moveq	#0,d1
	jmp	playsfx	; v190ex: GenAm range-safe tail jump
	;
.nofire	clr	deflbut
.rts	rts

deffrag	add.l	#$1000,de_ya(a5)
	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	cmp	#36,de_y(a5)
	bge	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	rts

impfrag	subq	#1,de_delay(a5)
	ble	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	rts

blowuplander	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	jsr	playsfx
	subq	#1,landerstokill
	moveq	#7,d7	;8 pixel exp
.loop2	addlast	defobjects
	beq	killdefobject
	move	de_x(a5),de_x(a0)
	move	de_y(a5),de_y(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_xa(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_ya(a0)
	move	d7,d0
	and	#1,d0
	addq	#5,d0
	move	d0,de_shape(a0)
	move.l	#deffrag,de_logic(a0)
	move	#15,de_delay(a0)
	clr	de_colltype(a0)
	dbf	d7,.loop2
	bra	killdefobject

blowupplayer	moveq	#3,d7
	;
.loop	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	jsr	playsfx
	dbf	d7,.loop
	;
	moveq	#31,d7
.loop2	addlast	defobjects
	beq	.rts
	move	playerx(pc),de_x(a0)
	move	playery(pc),de_y(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_xa(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,de_ya(a0)
	move	d7,d0
	and	#1,d0
	addq	#7,d0
	move	d0,de_shape(a0)
	move.l	#deffrag,de_logic(a0)
	move	#15,de_delay(a0)
	clr	de_colltype(a0)
	dbf	d7,.loop2
.rts	move	#-1,playershape
	subq	#1,playerlives
	rts

landerwait	subq	#1,de_delay(a5)
	ble.s	.skip
	rts
.skip	move.l	#landerlogic,de_logic(a5)
	move	#4,de_shape(a5)
landerlogic	;
	move	playershape(pc),d0
	bmi	.done
	;
	move	de_x(a5),d0
	move	d0,d2
	move	de_y(a5),d1
	move	d1,d3
	;
	sub	playerx(pc),d0
	bpl.s	.skipn1
	neg	d0
.skipn1	cmp	#6,d0
	bcc.s	.chk
	sub	playery(pc),d1
	bpl.s	.skipn2
	neg	d1
.skipn2	cmp	#4,d1
	bcs	blowupplayer
	;
	;check if shot!
.chk	lea	defobjects(pc),a0
.loop	move.l	(a0),a0
	tst.l	(a0)
	beq	.done
	move	de_colltype(a0),d0
	beq.s	.loop
	;
	move	d2,d0
	sub	de_x(a0),d0
	bpl.s	.skip
	neg	d0
.skip	cmp	#6,d0
	bcc.s	.loop
	;
	move	d3,d1
	sub	de_y(a0),d1
	bpl.s	.skip2
	neg	d1
.skip2	cmp	#4,d1
	bcc.s	.loop
	;
	;BOOM!
	;
	bra	blowuplander
.done	;
	move	de_x(a5),d0
	sub	playerx(pc),d0
	and	#255,d0
	cmp	#128,d0
	bcs.s	.left
	;
	;go right-ish!
	;
	add.l	#$4000,de_xa(a5)
	cmp.l	#$10000,de_xa(a5)
	ble.s	.xdone
	move.l	#$10000,de_xa(a5)
	bra.s	.xdone
	;
.left	sub.l	#$4000,de_xa(a5)
	cmp.l	#-$10000,de_xa(a5)
	bge.s	.xdone
	move.l	#-$10000,de_xa(a5)
	;
.xdone	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	;
	move	de_y(a5),d0
	sub	playery(pc),d0
	bpl.s	.up
	;
	;down
	;
	add.l	#$2000,de_ya(a5)
	cmp.l	#$8000,de_ya(a5)
	ble.s	.ydone
	move.l	#$8000,de_ya(a5)
	bra.s	.ydone
	;
.up	sub.l	#$2000,de_ya(a5)
	cmp.l	#-$8000,de_ya(a5)
	bge.s	.ydone
	move.l	#-$8000,de_ya(a5)
	;
.ydone	move.l	de_ya(a5),d0
	add.l	d0,de_y(a5)
	;
	rts

defbull	subq	#1,de_delay(a5)
	ble.s	killdefobject
	move.l	de_xa(a5),d0
	add.l	d0,de_x(a5)
	and	#255,de_x(a5)
	rts

killdefobject	move.l	a5,a0
	killitem	defobjects
	move.l	a0,a5
	move.l	defstack(pc),a7
	bra	def_loop

initnewdef	move	landerdelay(pc),landercnt
	move	landerstokill(pc),landerstoadd
	clearlist	defobjects
	clr.l	playerx
	clr.l	playerxa
	clr	playershape
	move	#18,playery
	rts

defender	;defender game!
	;
	move.l	a5,-(a7)
	;
	move	landerstoadd(pc),d0
	beq	.nolander
	subq	#1,landercnt
	bgt	.nolander
	;
	;add a lander!
	;
	addlast	defobjects
	beq	.nolander
	subq	#1,landerstoadd
	move	landerdelay(pc),landercnt
	;
	bsr	rndw
	and	#255,d0
	move	d0,d2
	move	d0,de_x(a0)
	moveq	#32,d0
	bsr	rndn
	move	d0,d3
	move	d0,de_y(a0)
	move	#5,de_shape(a0)
	clr.l	de_xa(a0)
	clr.l	de_ya(a0)
	move.l	#landerwait,de_logic(a0)
	move	#32,de_delay(a0)
	clr	de_colltype(a0)
	;
	;OK, now add lander fragments!
	;
	moveq	#7,d7
	;
.frloop	addlast	defobjects
	beq.s	.nolander
	;
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0	;xadd
	move.l	d0,d4
	move.l	d0,de_xa(a0)
	bsr	rndw
	ext.l	d0
	lsl.l	#1,d0
	move.l	d0,d5
	move.l	d0,de_ya(a0)
	;
	neg.l	d4
	lsl.l	#5,d4
	swap	d4
	add	d2,d4
	and	#255,d4
	move	d4,de_x(a0)
	neg.l	d5
	lsl.l	#5,d5
	swap	d5
	add	d3,d5
	move	d5,de_y(a0)
	;
	move	d7,d0
	and	#1,d0
	addq	#5,d0
	move	d0,de_shape(a0)
	move.l	#impfrag,de_logic(a0)
	move	#32,de_delay(a0)
	clr	de_colltype(a0)
	dbf	d7,.frloop
	;
.nolander	move	playershape(pc),d0
	bmi.s	.dead
	bsr	movedefplayer
.dead	;
	move	playerx(pc),d0
	sub	#22,d0
	bsr	drawmounts
	;
	;OK, scanner time!
	;
	moveq	#5,d0
	moveq	#3,d1
	moveq	#12,d2
	bsr	drawsprite
	moveq	#39,d0
	moveq	#3,d1
	moveq	#13,d2
	bsr	drawsprite
	move	playery(pc),d1
	lsr	#3,d1
	addq	#1,d1
	moveq	#22,d0
	moveq	#7,d2
	bsr	drawsprite
	;
	lea	defobjects(pc),a5
.scanloop	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.scandone
	cmp	#4,de_shape(a5)
	bne.s	.scanloop
	move	de_x(a5),d0
	sub	playerx(pc),d0
	lsr	#3,d0
	move	de_y(a5),d1
	lsr	#3,d1
	add	#16,d0
	and	#31,d0
	addq	#6,d0
	addq	#1,d1
	moveq	#5,d2
	bsr	drawsprite
	bra.s	.scanloop
.scandone	;	
	move.l	a7,defstack
	lea	defobjects(pc),a5
	;
def_loop	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.done
	;
	move.l	de_logic(a5),a0
	jsr	(a0)
	;
	move	de_x(a5),d0
	sub	playerx(pc),d0
	and	#255,d0
	cmp	#128,d0
	bcs.s	.nob
	or	#$ff00,d0
.nob	add	#22,d0
	move	de_y(a5),d1
	move	de_shape(a5),d2
	bsr	drawsprite
	;
	bra.s	def_loop
.done	;
	move	playershape(pc),d0
	bmi.s	.dead
	;
	move	landerstokill(pc),d0
	bgt.s	.bye2
	subq	#1,landerstokill
	subq	#1,d0
	and	#$10,d0
	beq.s	.bye2
	moveq	#22,d0
	moveq	#18,d1
	moveq	#11,d2
	bsr	drawsprite
.bye2	;
	moveq	#22,d0
	move	playery(pc),d1
	move	playershape(pc),d2
	bsr	drawsprite
	bra.s	.bye
	;
.dead	subq	#1,playershape
	cmp	#-96,playershape
	bcc.s	.no
	move	playerlives(pc),d3
	beq.s	.gameover
	;
	bsr	initnewdef
	bra.s	.bye
	;
.no	move	playerlives(pc),d3
	bne.s	.showlives
.gameover	and	#$10,d2
	beq.s	.exit
	moveq	#22,d0
	moveq	#18,d1
	moveq	#10,d2
	bsr	drawsprite
	bra.s	.exit
	;
.bye	move	playerlives(pc),d3
	beq.s	.exit
.showlives	subq	#1,d3
	moveq	#1,d1
	;
.lives	moveq	#2,d0
	moveq	#9,d2
	movem	d1/d3,-(a7)
	bsr	drawsprite
	movem	(a7)+,d1/d3
	addq	#2,d1
	dbf	d3,.lives
	;
.exit	move.l	(a7)+,a5
	rts

drawsprite	;d0=x, d1=y, d2=shape
	;
	exg	d0,d2
	move	d1,d3
	lea	defshapes(pc),a0
	movem	0(a0,d0*8),d0-d1/d4-d5
	;
	;d0=src x, d1=src y, d2=dest x,d3=dest y,d4=w, d5=h
	;
	sub	#64,d0
	movem.l	deftxt(pc),a0-a1
	add	d0,d1
	lsl	#6,d0
	add	d0,d1
	add	d1,a1
	;
	;handles...
	move	d4,d0
	lsr	#1,d0
	sub	d0,d2
	move	d5,d1
	lsr	#1,d1
	sub	d1,d3
	;
	tst	d2
	bmi.s	.xmi
	move	d2,d0
	add	d4,d0
	sub	#44,d0
	ble.s	.xok
	sub	d0,d4
	bgt.s	.xok
.xrts	rts
.xmi	add	d2,d4	;reduce width
	ble.s	.xrts
	move	d2,d0
	lsl	#6,d2
	add	d0,d2
	sub	d2,a1
	bra.s	.xdone
.xok	move	d2,d0
	lsl	#6,d2
	add	d0,d2
	add	d2,a0
.xdone	;
	tst	d3
	bmi.s	.ymi
	move	d3,d0
	add	d5,d0
	sub	#36,d0
	ble.s	.yok
	sub	d0,d5
	bgt.s	.yok
.yrts	rts
.ymi	add	d3,d5	;reduce width
	ble.s	.yrts
	sub	d3,a1
	bra.s	.ydone
.yok	add	d3,a0
.ydone	;
	moveq	#65,d7
	sub	d5,d7
	subq	#1,d4	;w
	subq	#1,d5	;h
.loop	move	d5,d6
.loop2	move.b	(a1)+,d0
	beq.s	.col0
	move.b	d0,(a0)
.col0	addq	#1,a0
	dbf	d6,.loop2
	add.l	d7,a0
	add.l	d7,a1
	dbf	d4,.loop
	;
	rts

drawmounts	;d0=offset
	;
	;parallax top 25, bottom 11
	;
	move	d0,d2
	lsr	#1,d0
	;
	and	#63,d0
	movem.l	deftxt(pc),a0-a1
	move	d0,d1
	lsl	#6,d1
	add	d0,d1	;* 65
	add	d1,a1
	;
	;OK, draw mountains at d0
	;
	moveq	#65-25,d7
	move.l	#64*65,d6
	moveq	#43,d1	;w
	;
.loop	move.b	(a1)+,(a0)+	;to even address - 1
	move	(a1)+,(a0)+	;to long address - 3
	move.l	(a1)+,(a0)+	;7
	move.l	(a1)+,(a0)+	;11
	move.l	(a1)+,(a0)+	;15
	move.l	(a1)+,(a0)+	;19
	move.l	(a1)+,(a0)+	;23
	move	(a1)+,(a0)+	;25!
	;
	add.l	d7,a0
	add.l	d7,a1
	addq	#1,d0
	and	#63,d0
	bne.s	.skip
	sub.l	d6,a1
.skip	dbf	d1,.loop
	;
	move	d2,d0
	and	#63,d0
	;
	movem.l	deftxt(pc),a0-a1
	move	d0,d1
	lsl	#6,d1
	add	d0,d1	;* 65
	add	d1,a1
	lea	25(a0),a0	;bottom 25!
	lea	25(a1),a1
	;
	;OK, draw mountains at d0
	;
	moveq	#65-11,d7
	moveq	#43,d1	;w
	;
.loop2	move	(a1)+,(a0)+	;2
	move.l	(a1)+,(a0)+	;6
	move.l	(a1)+,(a0)+	;10
	move.b	(a1)+,(a0)+	;11
	;
	add.l	d7,a0
	add.l	d7,a1
	addq	#1,d0
	and	#63,d0
	bne.s	.skip2
	sub.l	d6,a1
.skip2	dbf	d1,.loop2
	;
	rts

chatmap	dc.l	0
chatxout	dc	0
chatxin	dc	0

chatontxt	dc.b	'CHAT MODE ENABLED',0
	even

chatcls	move.l	chatmap,a0
	moveq	#0,d0
	move	#20*2*5-1,d1
.loop	move.l	d0,(a0)+
	dbf	d1,.loop
	clr.l	chatxout
	rts

chaton	;enable chat mode!
	;
	tst	linked
	beq	.rts
	tst	chatok
	bne	.rts
	;
	bsr	chatcls
	lea	chatontxt(pc),a2
.loop	move.b	(a2)+,d0
	beq.s	.done
	moveq	#3,d1
	bsr	chatprintout
	bra.s	.loop
.done	clr	chatoutput
	clr	chatoutget
	clr	chatinput
	clr	chatinget
	st	chatok
	;
.rts	rts

chatoff	;disable chat mode
	;
	tst	linked
	beq.s	chatoffrts
	tst	chatok
	beq.s	chatoffrts
	;
dochatoff	sf	chatok
	bsr	chatcls
	;
chatoffrts	rts

chatscrollin	;scroll chatin window across a byte.
	;
	move	d2,-(a7)
	move.l	chatmap,a0
	lea	40(a0),a0
	bra.s	chatsc
	
chatscrollout	;scroll chatout window across a byte.
	;
	move	d2,-(a7)
	move.l	chatmap,a0
chatsc	moveq	#4,d0	;5 lines to scroll
.loop3	moveq	#1,d1	;2 bitpanes
.loop2	moveq	#38,d2	;39 chars to move...
.loop	move.b	1(a0),(a0)+
	dbf	d2,.loop
	clr.b	(a0)+
	lea	40(a0),a0
	dbf	d1,.loop2
	dbf	d0,.loop3
	move	(a7)+,d2
	rts

chatspcout	cmp	#40,chatxout
	bcc.s	chatscrollout
	addq	#1,chatxout
	rts

calcchar	ext	d0
	cmp	#'A',d0
	bcs.s	.notal
	and	#31,d0
	add	#9,d0
	rts
.notal	cmp	#'.',d0
	bne.s	.not1
	moveq	#36,d0
	rts
.not1	cmp	#'!',d0
	bne.s	.not2
	moveq	#37,d0
	rts
.not2	cmp	#'?',d0
	bne.s	.not3
	moveq	#38,d0
	rts
.not3	cmp	#',',d0
	bne.s	.not4
	moveq	#39,d0
	rts
.not4	sub	#48,d0
	rts

chatprintout	;d0.b=chr$() to print, d1=colour (1,2,3)
	;
	cmp.b	#32,d0
	beq.s	chatspcout
	bsr	calcchar
	;
	movem.l	d2/a2,-(a7)
	;
	cmp	#40,chatxout
	bcs.s	.nosc
	;
	movem	d0-d1,-(a7)
	bsr	chatscrollout
	movem	(a7)+,d0-d1
	subq	#1,chatxout
.nosc	;
	lea	chatfont,a0
	ext	d0
	add	d0,a0
	move.l	chatmap,a1	;bp1
	add	chatxout(pc),a1
	addq	#1,chatxout
	cmp	#1,d1
	beq.s	.skip
	lea	80(a1),a2
	cmp	#2,d1
	beq.s	.skip2
	move.l	a2,a1
.skip	move.l	a1,a2
.skip2	moveq	#4,d0	;5 lines
.loop	move.b	(a0),(a1)
	move.b	(a0),(a2)
	lea	40(a0),a0
	lea	160(a1),a1
	lea	160(a2),a2
	dbf	d0,.loop
	;
	movem.l	(a7)+,d2/a2
	rts

chatspcin	cmp	#40,chatxin
	bcc	chatscrollin
	addq	#1,chatxin
	rts

chatprintinhex	move	d0,-(a7)
	lsr	#4,d0
	bsr	.skip
	move	(a7)+,d0
	;
.skip	and	#15,d0
	add	#48,d0
	cmp	#58,d0
	bcs.s	chatprintin
	addq	#7,d0
	;
chatprintin	;d0.b=chr$() to print, d1=colour (1,2,3)
	;
	cmp.b	#32,d0
	beq.s	chatspcin
	bsr	calcchar
	;
	movem.l	d2/a2,-(a7)
	;
	cmp	#40,chatxin
	bcs.s	.nosc
	;
	movem	d0-d1,-(a7)
	bsr	chatscrollin
	movem	(a7)+,d0-d1
	subq	#1,chatxin
.nosc	;
	lea	chatfont,a0
	ext	d0
	add	d0,a0
	move.l	chatmap,a1	;bp1
	add	chatxin(pc),a1
	lea	40(a1),a1
	addq	#1,chatxin
	cmp	#1,d1
	beq.s	.skip
	lea	80(a1),a2
	cmp	#2,d1
	beq.s	.skip2
	move.l	a2,a1
.skip	move.l	a1,a2
.skip2	moveq	#4,d0	;5 lines
.loop	move.b	(a0),(a1)
	move.b	(a0),(a2)
	lea	40(a0),a0
	lea	160(a1),a1
	lea	160(a2),a2
	dbf	d0,.loop
	;
	movem.l	(a7)+,d2/a2
	rts

