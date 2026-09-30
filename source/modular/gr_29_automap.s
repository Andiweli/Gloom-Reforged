; v2.3 c87b80w: TAB automap, paused first stage on every display backend.
; Main-task only. No per-frame geometry work, configuration or interrupt drawing.
; The raw matrix uses Amiga key $42 (TAB). Serial games cannot pause locally.
G2MAP_W equ 320
G2MAP_H equ 240
G2MAP_BYTES equ G2MAP_W*G2MAP_H

g2automap_seed
	movem.l d0/a0,-(a7)
	move.l rawtable,a0
	btst #2,8(a0)
	sne g2map_key
	movem.l (a7)+,d0/a0
	rts

g2automap_poll
	movem.l d0-d7/a0-a6,-(a7)
	move.l rawtable,a0
	btst #2,8(a0)
	sne d0
	move.b g2map_key,d1
	move.b d0,g2map_key
	tst.b d0
	beq .done
	tst.b d1
	bne .done
	tst linked
	bne .done
	tst paused
	bne .done
	tst game_menu_active
	bne .done
	tst finished
	bne .done
	tst finished2
	bne .done
	tst g2teleport_blackout
	bne .done
	tst.l player1
	beq .done
	; Check the zone span before allocating or changing display/pause state.
	move.l map_poly,d0
	beq .done
	move.l map_ppnt,d1
	sub.l d0,d1
	ble .done
	move.l d1,d0
	and.l #zo_size-1,d0
	bne .done
	lsr.l #5,d1
	move.l d1,g2map_zonecount
	move.l d1,d0
	add.l #G2MAP_BYTES,d0
	move.l d0,g2map_allocbytes
	move.l #$10001,d1	; MEMF_PUBLIC | MEMF_CLEAR; prefer FastRAM
	move.l 4.w,a6
	jsr -198(a6)		; AllocMem
	move.l d0,g2map_buffer
	beq .done
	add.l #G2MAP_BYTES,d0
	move.l d0,g2map_flags
	; Match the existing menu's pause semantics, with an atomic time snapshot.
	jsr -120(a6)		; Disable (only this short state transaction)
	move paused,g2map_saved_pause
	st paused
	move framecnt,g2map_saved_frame
	jsr -126(a6)		; Enable
	bsr g2map_classify
	tst.l d0
	beq .restore
	bsr g2map_draw
	bsr g2map_present
	tst.l d0
	beq .restore
.release
	jsr vwait
	move.l rawtable,a0
	btst #2,8(a0)
	bne .release
.wait
	jsr vwait
	move.l rawtable,a0
	btst #2,8(a0)
	beq .wait
.restore
	cmp #2,g2display_mode
	beq .p96restore
	jsr pokelastpal
	bra .redraw
.p96restore
	move #-1,p96clut_palette_dirty
	clr p96clut_active_role
.redraw
	; drawall waits for simulation; predrawall deliberately bypasses that wait.
	; Both buffers are rebuilt while paused, as on return from the game menu.
	jsr predrawall
	jsr g2hotkeys_seed
	jsr g2automap_seed
	jsr g2fps_restart_window
	move.l g2map_buffer,a1
	move.l g2map_allocbytes,d0
	move.l 4.w,a6
	jsr -210(a6)		; FreeMem
	clr.l g2map_buffer
	clr.l g2map_flags
	jsr -120(a6)
	move g2map_saved_frame,framecnt
	move g2map_saved_pause,paused
	jsr -126(a6)
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts

; Classify once per opening, from the same grid and bytecode as the engine.
; Flags per zone: bit 0 wall-grid member; bit 1 trigger-grid member;
; bit 2 referenced by OPEN DOOR or ROTATE/MORPH (including future events).
; Never execute events or change zone data. Trigger membership always wins.
g2map_classify
	move.l map_map,a3
	move.l memlist,a0
.findmem
	move.l a0,d0
	beq .fail
	move.l a0,d0
	add.l 8(a0),d0
	cmp.l a3,d0
	beq .found
	move.l (a0),a0
	bra .findmem
.found
	move.l a0,d0
	add.l 4(a0),d0
	move.l d0,g2map_mapend
	; Validate grid, zone span, pointer list and the 25-entry event table.
	move.l map_grid,a0
	cmpa.l a3,a0
	blo .fail
	lea 32*32*8(a0),a1
	cmpa.l map_poly,a1
	bhi .fail
	move.l map_poly,a1
	cmpa.l a3,a1
	blo .fail
	move.l map_ppnt,a1
	cmpa.l map_anim,a1
	bhi .fail
	move.l map_anim,a1
	cmpa.l d0,a1
	bhi .fail
	move.l map_events,a1
	cmpa.l a3,a1
	blo .fail
	lea 25*4(a1),a1
	cmpa.l map_grid,a1
	bhi .fail
	move.l g2map_flags,a5
	move #32*32-1,d7
.cell
	moveq #1,d6
	bsr g2map_grid_flags
	moveq #2,d6
	bsr g2map_grid_flags
	dbf d7,.cell
	; Event zero is not a script (header slot 16 is texture-name offset).
	move.l map_events,a4
	addq.l #4,a4
	moveq #23,d7
.event
	move.l (a4)+,d0
	btst #0,d0
	bne .nextevent
	move.l map_map,a0
	adda.l d0,a0
	cmpa.l map_txts,a0
	blo .nextevent
.op
	moveq #2,d0
	bsr g2map_need
	bhi .nextevent
	move (a0)+,d2
	beq .nextevent
	cmp #1,d2
	beq .object
	cmp #2,d2
	beq .door
	cmp #3,d2
	beq .teleport
	cmp #4,d2
	beq .loadobjects
	cmp #5,d2
	beq .texture
	cmp #6,d2
	beq .rotate
	bra .nextevent	; unknown opcode: do not guess its length
.object
	moveq #10,d0	; type,x,y,z,rotation
	bra .skip
.teleport
	moveq #8,d0	; x,y,z,rotation
	bra .skip
.texture
	moveq #4,d0	; zone,new texture
.skip
	bsr g2map_need
	bhi .nextevent
	adda.l d0,a0
	bra .op
.loadobjects
	moveq #2,d0
	bsr g2map_need
	bhi .nextevent
	tst (a0)+
	bpl .loadobjects
	bra .op
.door
	moveq #2,d0
	bsr g2map_need
	bhi .nextevent
	moveq #0,d2
	move (a0)+,d2
	cmp.l g2map_zonecount,d2
	bhs .op
	or.b #4,0(a5,d2.l)
	bra .op
.rotate
	moveq #8,d0	; first zone,count,speed,flags
	bsr g2map_need
	bhi .nextevent
	moveq #0,d2
	move (a0)+,d2
	moveq #0,d3
	move (a0)+,d3
	addq.l #4,a0
	tst.l d3
	beq .op
	move.l d2,d4
	add.l d3,d4
	cmp.l g2map_zonecount,d4
	bhi .op
.rotzone
	or.b #4,0(a5,d2.l)
	addq.l #1,d2
	subq.l #1,d3
	bne .rotzone
	bra .op
.nextevent
	dbf d7,.event
	moveq #-1,d0
	rts
.fail
	moveq #0,d0
	rts

; a0 advances over one grid pair (count-minus-one, index into map_ppnt).
; A malformed pair is ignored without leaving the pointer-list allocation.
g2map_grid_flags
	move (a0)+,d0
	moveq #0,d1
	move (a0)+,d1
	tst d0
	bmi .done
	moveq #0,d2
	move d0,d2
	addq.l #1,d2
	add.l d1,d1
	move.l map_ppnt,a1
	adda.l d1,a1
	move.l d2,d3
	add.l d3,d3
	add.l a1,d3
	cmp.l map_anim,d3
	bhi .done
.loop
	moveq #0,d1
	move (a1)+,d1
	cmp.l g2map_zonecount,d1
	bhs .next
	or.b d6,0(a5,d1.l)
.next
	dbf d0,.loop
.done
	rts

; Upper bound for bytecode reads. Carry/HI follows end > allocation end.
g2map_need
	move.l a0,d1
	add.l d0,d1
	cmp.l g2map_mapend,d1
	rts

; a4 = zone; pen 0 means omit (including from bounds), 1 red, 3 yellow.
g2map_zone_pen
	moveq #0,d7
	tst zo_open(a4)
	bmi .done
	move.l a4,d0
	sub.l map_poly,d0
	lsr.l #5,d0
	move.l g2map_flags,a0
	move.b 0(a0,d0.l),d0
	move.b d0,d1
	and.b #3,d1
	cmp.b #1,d1
	bne .done
	moveq #1,d7
	btst #2,d0
	beq .done
	moveq #3,d7
.done
	tst d7
	rts

; Bounds include players and drawable walls, never trigger geometry.
g2map_draw
	move.l player1,a5
	move ob_x(a5),d0
	ext.l d0
	move.l d0,g2map_minx
	move.l d0,g2map_maxx
	move ob_z(a5),d1
	ext.l d1
	move.l d1,g2map_minz
	move.l d1,g2map_maxz
	tst gametype
	beq .walls
	move.l player2,a5
	move.l a5,d0
	beq .walls
	move ob_x(a5),d0
	move ob_z(a5),d1
	bsr g2map_bound
.walls
	move.l map_poly,a4
.bounds
	bsr g2map_zone_pen
	bne .wallbound
	bsr g2map_is_exit
	beq .nextbound
	bsr g2map_exit_midpoint
	bsr g2map_bound
	bra .nextbound
.wallbound
	move zo_lx(a4),d0
	move zo_lz(a4),d1
	bsr g2map_bound
	move zo_rx(a4),d0
	move zo_rz(a4),d1
	bsr g2map_bound
.nextbound
	lea zo_size(a4),a4
	cmpa.l map_ppnt,a4
	blo .bounds
	move.l g2map_maxx,d4
	sub.l g2map_minx,d4
	move.l g2map_maxz,d5
	sub.l g2map_minz,d5
	move.l d4,d0
	mulu #208,d0
	move.l d5,d1
	mulu #296,d1
	cmp.l d1,d0
	blo .zlimits
	move #296,g2map_num
	move d4,g2map_den
	bra .scale
.zlimits
	move #208,g2map_num
	move d5,g2map_den
.scale
	tst g2map_den
	bne .nonzero
	move #1,g2map_den
.nonzero
	mulu g2map_num,d4
	divu g2map_den,d4
	move #320,d0
	sub d4,d0
	lsr #1,d0
	move d0,g2map_ox
	mulu g2map_num,d5
	divu g2map_den,d5
	move #240,d0
	sub d5,d0
	lsr #1,d0
	move d0,g2map_oy
	move.l map_poly,a4
.lines
	bsr g2map_zone_pen
	beq .nextline
	move zo_lx(a4),d0
	move zo_lz(a4),d1
	bsr g2map_project
	move d0,d2
	move d1,d3
	move zo_rx(a4),d0
	move zo_rz(a4),d1
	bsr g2map_project
	bsr g2map_line
.nextline
	lea zo_size(a4),a4
	cmpa.l map_ppnt,a4
	blo .lines
	move.l map_poly,a4
.exits
	bsr g2map_is_exit
	beq .nextexit
	bsr g2map_exit_midpoint
	bsr g2map_project
	bsr g2map_exit_icon
.nextexit
	lea zo_size(a4),a4
	cmpa.l map_ppnt,a4
	blo .exits
	move.l player1,a5
	moveq #2,d7
	bsr g2map_arrow
	tst gametype
	beq .done
	move.l player2,a5
	move.l a5,d0
	beq .done
	moveq #3,d7
	bsr g2map_arrow
.done
	rts

; Only the trigger grid plus event 24 identifies a real level exit.
; A normal wall's opening fraction can also equal 24: never treat it as exit.
g2map_is_exit
	moveq #0,d0
	move zo_ev(a4),d0
	bpl .positive
	neg d0
.positive
	cmp #24,d0
	bne .no
	move.l a4,d0
	sub.l map_poly,d0
	lsr.l #5,d0
	move.l g2map_flags,a0
	btst #1,0(a0,d0.l)
	beq .no
	moveq #-1,d0
	rts
.no
	moveq #0,d0
	rts

; Average in longs so extreme signed world coordinates cannot overflow.
g2map_exit_midpoint
	move zo_lx(a4),d0
	ext.l d0
	move zo_rx(a4),d2
	ext.l d2
	add.l d2,d0
	asr.l #1,d0
	move zo_lz(a4),d1
	ext.l d1
	move zo_rz(a4),d2
	ext.l d2
	add.l d2,d1
	asr.l #1,d1
	rts

; Screen anchor d0/d1: 8x6 checkerboard and a white 10-pixel pole.
; Draw after walls but before players. Black squares are opaque; the arrow
; remains on top when the player is standing at the exit. Uses existing pens.
g2map_exit_icon
	movem.l d0-d7,-(a7)
	subq #4,d0
	sub #9,d1
	move d0,d2
	move d1,d3
	moveq #0,d5
.row
	move d2,d0
	move d3,d1
	add d5,d1
	moveq #2,d7
	bsr g2map_pixel
	cmp #6,d5
	bge .nextrow
	moveq #0,d4
.checker
	move d2,d0
	addq #1,d0
	add d4,d0
	move d4,d6
	lsr #1,d6
	move d5,d7
	lsr #1,d7
	eor d6,d7
	and #1,d7
	eor #1,d7
	add d7,d7
	bsr g2map_pixel
	addq #1,d4
	cmp #8,d4
	blo .checker
.nextrow
	addq #1,d5
	cmp #10,d5
	blo .row
	movem.l (a7)+,d0-d7
	rts

g2map_bound
	ext.l d0
	ext.l d1
	cmp.l g2map_minx,d0
	bge .xmax
	move.l d0,g2map_minx
.xmax
	cmp.l g2map_maxx,d0
	ble .zmin
	move.l d0,g2map_maxx
.zmin
	cmp.l g2map_minz,d1
	bge .zmax
	move.l d1,g2map_minz
.zmax
	cmp.l g2map_maxz,d1
	ble .done
	move.l d1,g2map_maxz
.done
	rts

; Signed world words -> screen words. Preserve d2/d3 (other line endpoint).
; Products <= 65535*296; DIVU quotient <=296, also for extreme word bounds.
g2map_project
	ext.l d0
	ext.l d1
	sub.l g2map_minx,d0
	neg.l d1
	add.l g2map_maxz,d1
	mulu g2map_num,d0
	divu g2map_den,d0
	add g2map_ox,d0
	mulu g2map_num,d1
	divu g2map_den,d1
	add g2map_oy,d1
	rts

; Bresenham d0/d1 -> d2/d3, pen d7.b. Clipped pixel stores, all regs saved.
g2map_line
	movem.l d0-d7/a0,-(a7)
	moveq #1,d4
	moveq #1,d5
	sub d0,d2
	bge .dx
	neg d2
	neg d4
.dx
	sub d1,d3
	bge .dy
	neg d3
	neg d5
.dy
	move d2,d6
	sub d3,d6		; error=dx-dy
	move d2,-(a7)
	cmp d3,d2
	bge .count
	move d3,(a7)
.count	; max(dx,dy)+1 pixels, including both endpoints
.loop
	bsr g2map_pixel
	move d6,-(a7)
	add d6,d6		; temporary 2*error
	neg d3
	cmp d3,d6
	ble .nox
	add d4,d0
.nox
	; Use a scratch word for e2 while updating the saved error.
	neg d3
	cmp d2,d6
	bge .noy
	add d5,d1
	add d2,(a7)
.noy
	; X decision again (e2 unchanged), subtract dy from saved error.
	neg d3
	cmp d3,d6
	ble .noerrx
	add d3,(a7)
.noerrx
	neg d3
	move (a7)+,d6
	subq #1,(a7)
	bpl .loop
	addq.l #2,a7
	movem.l (a7)+,d0-d7/a0
	rts

g2map_pixel
	cmp #320,d0
	bhs .done
	cmp #240,d1
	bhs .done
	movem.l d0-d1/a0,-(a7)
	mulu #320,d1
	and.l #$ffff,d0
	add.l d0,d1
	move.l g2map_buffer,a0
	move.b d7,0(a0,d1.l)
	movem.l (a7)+,d0-d1/a0
.done
	rts

; Filled pointed triangle. Rotation is the same -sin/+cos forward vector
; used by moveplayer, with north at the top of the screen.
g2map_arrow
	movem.l d0-d7/a0-a3,-(a7)
	move ob_x(a5),d0
	move ob_z(a5),d1
	bsr g2map_project
	move d0,g2map_cx
	move d1,g2map_cy
	move ob_rot(a5),d0
	and #255,d0
	move.l camrots,a0
	lea 0(a0,d0.w*8),a0
	move 2(a0),d4
	move 6(a0),d5
	ext.l d4
	ext.l d5
	neg.l d4
	neg.l d5
	; Q15 -> approx +/-4 (half the original arrow dimensions), with full long negation for -32768.
	asr.l #8,d4
	asr.l #5,d4
	asr.l #8,d5
	asr.l #5,d5
	move g2map_cx,d2
	move g2map_cy,d3
	add d4,d2
	add d5,d3		; tip
	asr #1,d4
	asr #1,d5
	move g2map_cx,d0
	move g2map_cy,d1
	sub d4,d0
	sub d5,d1		; rear centre
	; Fill as five rays across the half-size perpendicular base (-2..+2).
	moveq #-2,d6
.ray
	movem.l d0-d1/d4-d6,-(a7)
	muls d6,d4
	muls d6,d5
	asr.l #1,d4
	asr.l #1,d5
	sub d5,d0
	add d4,d1
	bsr g2map_line
	movem.l (a7)+,d0-d1/d4-d6
	addq #1,d6
	cmp #2,d6
	ble .ray
	movem.l (a7)+,d0-d7/a0-a3
	rts

; Native layout uses its actual row and plane strides (OS and copper paths).
g2map_present
	cmp #2,g2display_mode
	beq g2map_present_p96
	move.l drawbitmap,a0
	move.l bmapmem,d0
	lsr.l #2,d0
	subq.l #1,d0
.clear
	clr.l (a0)+
	dbf d0,.clear
	move.l drawbitmap,a2
	move.l g2map_buffer,a0
	move #239,d5
.row
	move.l a2,a1
	moveq #39,d4
.byte
	moveq #0,d0
	moveq #0,d1
	moveq #7,d3
.bits
	add.b d0,d0
	add.b d1,d1
	move.b (a0)+,d2
	lsr.b #1,d2
	bcc .no0
	addq.b #1,d0
.no0
	lsr.b #1,d2
	bcc .no1
	addq.b #1,d1
.no1
	dbf d3,.bits
	move.b d0,(a1)
	move.l bpmod,d2
	move.b d1,0(a1,d2.l)
	addq.l #1,a1
	dbf d4,.byte
	adda.l linemod,a2
	dbf d5,.row
	jsr vwait
	lea g2map_pal_ecs,a1
	tst aga
	beq .pal
	lea g2map_pal_aga,a1
.pal
	tst os
	bne .ospal
	tst aga
	beq .ospal
	; The legacy AGA copper publisher assumes complete 32-colour banks.
	; Patch only our four entries, preserving all other copper instructions.
	move.l coplist,a2
	lea palette_aga-copinit_aga(a2),a2
	moveq #3,d0
.copperpal
	move (a1)+,6(a2)
	move (a1)+,138(a2)
	addq.l #4,a2
	dbf d0,.copperpal
	bra .swap
.ospal
	moveq #4,d0
	jsr pokepal2
.swap
	jsr db
	moveq #-1,d0
	rts

; Fullscreen indexed stage; integer scaling preserves square map geometry.
; No planar buffers, compositor palette shadow or ownership state is changed.
g2map_present_p96
	cmp #320,p96target_width
	blo .fail
	cmp #240,p96target_height
	blo .fail
	move.l p96clut_stage_ptr,a0
	move.l a0,d0
	beq .fail
	moveq #0,d0
	move p96target_width,d0
	mulu p96target_height,d0
	cmp.l p96clut_stage_size,d0
	bhi .fail
	move.l d0,d1
.clear
	clr.b (a0)+
	subq.l #1,d1
	bne .clear
	moveq #1,d6
	cmp #640,p96target_width
	blo .scale
	cmp #480,p96target_height
	blo .scale
	moveq #2,d6
.scale
	move #320,d0
	mulu d6,d0
	move p96target_width,d4
	sub d0,d4
	bmi .fail
	lsr #1,d4
	move #240,d0
	mulu d6,d0
	move p96target_height,d1
	sub d0,d1
	bmi .fail
	lsr #1,d1
	mulu p96target_width,d1
	and.l #$ffff,d4
	add.l d4,d1
	move.l p96clut_stage_ptr,a2
	adda.l d1,a2
	move.l g2map_buffer,a0
	move #239,d5
.row
	move.l a2,a1
	move #319,d3
.pixel
	move.b (a0)+,d0
	move.b d0,(a1)+
	cmp #2,d6
	bne .next
	move.b d0,(a1)+
	moveq #0,d1
	move p96target_width,d1
	move.b d0,-2(a1,d1.l)
	move.b d0,-1(a1,d1.l)
.next
	dbf d3,.pixel
	moveq #0,d0
	move p96target_width,d0
	mulu d6,d0
	adda.l d0,a2
	dbf d5,.row
	jsr g2p96_gameplay_copy_clut_stage_to_draw_target_c87b78m
	tst.l d0
	beq .fail
	jsr g2p96_gameplay_dbuf_flip
	tst d0
	beq .fail
	jsr g2p96_gameplay_dbuf_wait_disp
	tst d0
	beq .fail
	move.l p96winprobe_window_ptr,a0
	move.l p96gameplay_intbase,a6
	jsr -300(a6)
	move.l d0,a0
	beq .fail
	lea g2map_pal32,a1
	move.l p96gameplay_grbase,a6
	jsr -$372(a6)
	moveq #-1,d0
	rts
.fail
	moveq #0,d0
	rts

	even
g2map_key dc.b 0,0
g2map_saved_pause dc.w 0
g2map_saved_frame dc.w 0
g2map_buffer dc.l 0
g2map_flags dc.l 0
g2map_zonecount dc.l 0
g2map_allocbytes dc.l 0
g2map_mapend dc.l 0
g2map_minx dc.l 0
g2map_maxx dc.l 0
g2map_minz dc.l 0
g2map_maxz dc.l 0
g2map_num dc.w 0
g2map_den dc.w 0
g2map_ox dc.w 0
g2map_oy dc.w 0
g2map_cx dc.w 0
g2map_cy dc.w 0
g2map_pal_ecs dc.w $000,$f00,$fff,$ff0
g2map_pal_aga dc.w $000,$000,$f00,$f00,$fff,$fff,$ff0,$ff0
g2map_pal32 dc.l $00040000,0,0,0,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,$ffffffff,$ffffffff,$ffffffff,0,0
