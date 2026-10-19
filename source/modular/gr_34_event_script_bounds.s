; Map programs: framing before initmap exposes pointers to runtime code.
; Tables are derived from the actual 24-entry dispatcher and objinfo layout.
; No checks in doanims, wall rasterization or object render loops.
g2validate_map_programs
	movem.l d1-d7/a0-a6,-(a7)
	moveq #0,d3
	bra.s g2validate_map_programs_body
g2require_map_textures
	movem.l d1-d7/a0-a6,-(a7)
	move.l map_map,a0
	moveq #1,d3
g2validate_map_programs_body
	move.l a7,g2map_program_sp
	move.l a0,a2
	jsr g2asset_bounds
	move.l a1,a6
	move.l 8(a2),d7
	sub.l 4(a2),d7
	lsr.l #5,d7
	move.l a2,a4
	add.l 4(a2),a4
	move.l d7,d5
	beq.s .events
.polygon_event
	move.w zo_ev(a4),d0
	bmi.s .disabled
	cmp.w #24,d0
	bhi.w g2map_program_bad
.disabled
	lea 32(a4),a4
	subq.l #1,d5
	bne.s .polygon_event
.events
	move.l a2,a3
	add.l (a2),a3
	sub.l #96,a3	; same table as map_events + indices 1..24
	moveq #23,d6
.event
	move.l a2,a4
	add.l (a3)+,a4
.opcode
	bsr.w g2map_program_word
	tst.w d0
	beq.w .next_event
	cmp.w #6,d0
	bhi.w g2map_program_bad
	cmp.w #1,d0
	beq.w .object
	cmp.w #2,d0
	beq.w .door
	cmp.w #3,d0
	beq.w .teleport
	cmp.w #4,d0
	beq.w .objects
	cmp.w #5,d0
	beq.w .texture
	; opcode 6: first polygon, count, speed, flags
	bsr.w g2map_program_word
	cmp.l d7,d0
	bcc.w g2map_program_bad
	move.l d0,d4
	bsr.w g2map_program_word
	tst.w d0
	beq.w g2map_program_bad
	cmp.w #(rp_size-rp_lx)/8,d0	; capacity of the actual rotating record
	bhi.w g2map_program_bad
	move.l d0,d5
	add.l d0,d4
	cmp.l d7,d4
	bhi.w g2map_program_bad
	bsr.w g2map_program_word	; signed speed, no arbitrary limit
	bsr.w g2map_program_word
	btst #0,d0
	beq.w .opcode
	add.l d5,d4	; morph reads a second equal-size polygon block
	cmp.l d7,d4
	bhi.w g2map_program_bad
	bra.w .opcode
.object
	bsr.w g2map_program_word
	cmp.w #(g2objinfo_end-objinfo)/oilen,d0
	bcc.w g2map_program_bad
	moveq #3,d5	; x,y,z,rotation; fixed complete operand record
.object_fields
	bsr.w g2map_program_word
	dbf d5,.object_fields
	bra.w .opcode
.door
	bsr.w g2map_program_word
	cmp.l d7,d0
	bcc.w g2map_program_bad
	bra.w .opcode
.teleport
	cmp.w #23,d6	; event 1 runs before an event object exists
	beq.w g2map_program_bad
	moveq #3,d5
.teleport_fields
	bsr.w g2map_program_word
	dbf d5,.teleport_fields
	bra.w .opcode
.objects
	bsr.w g2map_program_word
	tst.w d0
	bmi.w .opcode	; signed negative terminator is part of the format
	cmp.w #(g2objinfo_end-objinfo)/oilen,d0
	bcc.w g2map_program_bad
	bra.s .objects
.texture
	bsr.w g2map_program_word
	cmp.l d7,d0
	bcc.w g2map_program_bad
	bsr.w g2map_program_word
	bsr.w g2map_texture_index
	bra.w .opcode
.next_event
	dbf d6,.event
	; Animated texture records end at map_txts, with a zero word sentinel.
	move.l a2,a4
	add.l 12(a2),a4
	move.l a2,a6
	add.l 16(a2),a6
.animation
	bsr.w g2map_program_word
	tst.w d0
	beq.s .valid
	cmp.w #2,d0	; doanims uses DBF(count-2), so one would iterate 65536 times
	bcs.w g2map_program_bad
	cmp.w #160,d0
	bhi.w g2map_program_bad
	move.l d0,d5
	bsr.w g2map_program_word
	move.l d0,d4
	add.l d5,d0
	cmp.l #160,d0
	bhi.w g2map_program_bad
.animation_slots
	move.l d4,d0
	bsr.w g2map_texture_index
	addq.l #1,d4
	subq.l #1,d5
	bne.s .animation_slots
	bsr.w g2map_program_word
	bsr.w g2map_program_word
	bra.s .animation
.valid
	; Only wall groups render zo_t; trigger polygons may use other semantics.
	move.l a2,a5
	add.l (a2),a5
	move.w #1023,d6
.wall_square
	moveq #0,d5
	move.w (a5)+,d5
	moveq #0,d4
	move.w (a5)+,d4
	addq.l #4,a5	; skip the separately validated trigger group
	tst.w d5
	bmi.s .wall_next
	move.l a2,a3
	add.l 8(a2),a3
	add.l d4,d4
	add.l d4,a3
.wall_polygon
	moveq #0,d4
	move.w (a3)+,d4
	lsl.l #5,d4
	move.l a2,a4
	add.l 4(a2),a4
	add.l d4,a4
	lea zo_t(a4),a4
	moveq #7,d7
.wall_texture
	moveq #0,d0
	move.b (a4)+,d0
	bsr.w g2map_texture_index
	dbf d7,.wall_texture
	dbf d5,.wall_polygon
.wall_next
	dbf d6,.wall_square
	moveq #0,d0
	bra.s g2map_program_return
g2map_program_bad
	move.l g2map_program_sp,a7
	moveq #-1,d0
g2map_program_return
	tst.l d3
	beq.s .return
	tst.l d0
	bne.l g2fatal_abort
.return
	movem.l (a7)+,d1-d7/a0-a6
	rts

g2map_texture_index
	cmp.l #160,d0
	bcc.w g2map_program_bad
	tst.l d3
	beq.s .done
	lea textures,a1
	tst.l 0(a1,d0.l*4)
	beq.w g2map_program_bad
.done
	rts

g2map_program_word
	move.l a6,d1
	sub.l a4,d1
	cmp.l #2,d1
	bcs.w g2map_program_bad
	cmp.l a6,a4
	bcc.w g2map_program_bad
	moveq #0,d0
	move.w (a4)+,d0
	rts
	cnop 0,4
g2map_program_sp dc.l 0

; Interior palette pointers have the same owning logical extent as the asset.
g2asset_span
	movem.l d1-d2/a2,-(a7)
	move.l memlist,a2
.heap
	move.l a2,d0
	beq.s .static
	move.l a2,d1
	add.l 8(a2),d1
	cmp.l d1,a0
	bcs.s .next_heap
	move.l d1,d2
	add.l 16(a2),d2
	cmp.l d2,a0
	bcs.s .found
.next_heap
	move.l (a2),a2
	bra.s .heap
.static
	lea g2asset_static_ranges,a2
.range
	move.l (a2)+,d1
	beq.s .unknown
	move.l (a2)+,d2
	cmp.l d1,a0
	bcs.s .range
	cmp.l d2,a0
	bcc.s .range
.found
	move.l d2,a1
	move.l d2,d0
	sub.l a0,d0
	bra.s .done
.unknown
	move.l a0,a1
.done
	movem.l (a7)+,d1-d2/a2
	rts

g2require_palette
	movem.l d0-d7/a0-a6,-(a7)
	jsr g2asset_span
	jsr g2validate_palette
	tst.l d0
	bne.s .bad
	move.l map_rgbsat,d0
	sub.l map_rgbs,d0
	cmp.l #512,d0
	bhi.s .bad
	btst #0,d0
	bne.s .bad
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2require_tile
	movem.l d0-d7/a0-a6,-(a7)
	jsr g2asset_bounds
	cmp.l #128*128+2,d0
	bcs.s .bad
	lea 128*128(a0),a0
	jsr g2validate_palette
	tst.l d0
	bne.s .bad
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

; Cold event/morph bodies live after the original hot code and data.
; Entry JMPs/NOP padding preserve historical PC-relative instruction widths.
g2cold_calcnormvec	;d0,d1 = vector...normalize!
	;
	;OK, find vector length!
	;
	move	d0,d2
	muls	d2,d2
	move	d1,d3
	muls	d3,d3
	add.l	d3,d2
	bvs.l g2fatal_abort	; the extreme signed vectors must not loop in .fitit
	beq.l g2fatal_abort	; a collapsed morph edge cannot be normalized/divided
	;
	;OK, sqr of d2.l!
	;
	move.l	#$10000,d3
	;
.fitit	cmp.l	#16384,d2	;fits?
	bcs.s	.ok
	asr.l	#1,d2
	mulu.l	#92681,d4:d3	;mult by sqr(2)
	move	d4,d3
	swap	d3
	bra.s	.fitit
	;
.ok	;OK to look up, but multiply the result.w by d3.q
	;
	move.l	sqr,a0
	and	#$fffe,d2
	movem	0(a0,d2),d2	;sqr.l!
	mulu.l	d3,d2
	swap	d2	;length.w
	;
	;length should be >= both abs(xvec) AND abs(zvec)
	;
	move	d0,d3
	bpl.s	.xp
	neg	d3
.xp	move	d1,d4
	bpl.s	.zp
	neg	d4
.zp	;
	cmp	d4,d3
	bcc.s	.bg
	exg	d3,d4
.bg	;
	cmp	d3,d2
	bcc.s	.lo
	move	d3,d2
.lo	;
	ext.l	d2
	;
	swap	d0
	clr	d0
	divs.l	d2,d0
	muls.l	#32766,d0
	swap	d0
	;
	swap	d1
	clr	d1
	divs.l	d2,d1
	muls.l	#32766,d1
	swap	d1
	rts

g2cold_execevent	;d0=event number to execute...1,2...
	;
	tst.w d0
	beq.s .none
	cmp.w #24,d0
	bhi.l g2fatal_abort
	sf	doorsfxflag
	move.l	map_map,a6
	move.l	map_events,a0
	add.l	0(a0,d0*4),a6
	bra.l exec_loop
.none	rts
	;
g2cold_exec_opendoor
	addlast	doors	;a0=new door
	bne.s .allocated
	addq.l #2,a6	; exhausted pool: consume the validated operand and skip
	bra.l exec_loop
.allocated
	st doorsfxflag
	;
	move	(a6)+,d0	;door #
	move.l	map_poly,a1
	lsl	#5,d0
	lea	0(a1,d0),a1	;polygon to open!
	;
	;calc lx add, lz add, rx add, rz add
	;
	move.l	a1,do_poly(a0)
	move.l	zo_lx(a1),do_lx(a0)
	move.l	zo_rx(a1),do_rx(a0)
	clr	do_frac(a0)
	move	#$100,do_fracadd(a0)
	bra.l exec_loop

g2cold_exec_teleport	move.l	eventobj,a0
	move.l a0,d0
	beq.l g2fatal_abort
	;
	move	(a6)+,ob_telex(a0)
	addq	#2,a6
	move	(a6)+,ob_telez(a0)
	move	(a6)+,ob_telerot(a0)
	;
	move	finished,d0
	or	finished2,d0
	bne.l exec_loop
	;
	tst	-6(a6)	;teleport? or lock!
	beq.s	.tele
	;
	;LOCK!
	cmp.l	#playerlogic,ob_logic(a0)
	bne.l exec_loop
	moveq #0,d1
	move.b floortag,d1
	sub.w #'1',d1
	cmp.w #2,d1	; ltk/lnd each contain the three tile variants 1..3
	bhi.l g2fatal_abort
	;
	move	changedtxt,d0
	lea	textures,a1
	move.l	0(a1,d0*4),a1
	move.l a1,d0
	beq.l g2fatal_abort
	jsr g2require_defender_texture
	lea	65<<6+1(a1),a2
	lea	10*65+19(a1),a1
	movem.l	a1-a2,deftxt
	;
	move.l	#locklogic,ob_logic(a0)
	bra.l exec_loop
.tele	;
	move	#2,ob_pixsizeadd(a0)
	jsr	dotelesfx
	bra.l exec_loop

g2cold_loadanobj	;d0=object#...sys must be permitted
	;
	lea	objinfo,a2
	mulu	#objinfof-objinfo,d0
	move.l	_ob_shape-objinfo(a2,d0),a2
	lea	8(a2),a3	;filename
	;
	tst.l	(a2)
	bne.s	.skip
	move.l	a3,a0
	moveq	#1,d1
	jsr	loadfile
	requiremem		; main object shape cannot be rendered from NULL
	move.l	d0,(a2)
	move.l	d0,a0
	jsr	remapanim
.skip	;
	move.l (a2),a0
	jsr g2require_actor_shape
	tst.l	4(a2)
	bne.s	.rts
	move.l	a3,a0
.loop	tst.b	(a3)+
	bne.s	.loop
	move.b	#'2',-(a3)
	moveq	#1,d1
	jsr	loadfile
	clr.b	(a3)
	move.l	d0,4(a2)
	beq.s	.rts
	move.l	d0,a0
	jsr	remapanim
	;
.rts	rts

g2cold_exec_addobj	clr.l	dummy
	move	(a6)+,d0	;monster type
	lea	objinfo,a2
	mulu	#objinfof-objinfo,d0
	add.l	d0,a2
	move.l	(a2)+,a3
	tst.l	(a3)
	beq.s	.ok
.no	addq	#8,a6
	bra.l exec_loop
.ok	cmp	#2,-2(a6)	;player?
	bcc.s	.notp
	addfirst	objects
	bra.s	.bum
.notp	addlast	objects
.bum	beq.s	.no
	move.l	a0,a5
	;
	move.l	a5,(a3)
	;
	move	(a6)+,ob_x(a5)
	move	(a6)+,ob_y(a5)
	move	(a6)+,ob_z(a5)
	move	(a6)+,ob_rot(a5)
	;
	lea	ob_info(a5),a3
	move	#(objinfof-objinfo-4)>>1-1,d0
.loop	move	(a2)+,(a3)+
	dbf	d0,.loop
	;
	tst	ob_blood(a5)	;hi bit of blood=1=invisible!
	smi	d0
	ext	d0
	move	d0,ob_invisible(a5)
	;
	jsr calcvecs
	movem.l	d4-d5,ob_xvec(a5)
	;
	move.l	ob_shape(a5),a0
	move.l	4(a0),ob_chunks(a5)
	move.l	(a0),a0
	move.l a0,d0
	beq.l g2fatal_abort
	move.l	a0,ob_shape(a5)
	;
	move	an_maxw(a0),d0
	move	d0,ob_rad(a5)
	mulu	d0,d0
	move.l	d0,ob_radsq(a5)
	;
	clr.l	ob_washit(a5)
	;
	jsr rnddelay
	;
	bra.l exec_loop
