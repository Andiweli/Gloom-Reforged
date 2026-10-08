; v2.3.3 c87b83-map3: P96 TAB cycle: full map -> live local map -> off.
; Native ECS/AGA retain their paused map toggle. Local drawing is main-task only.
; Main-task only. Classifications are cached; local geometry follows live walls.
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
	tst g2map_overlay_active
	beq .open_full_map
	jsr g2automap_reset
	bra .done
.open_full_map
	bsr g2map_allocate
	tst.l d0
	beq .done
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
	cmp #2,g2display_mode
	bne .restore
	move #-1,g2map_overlay_active
	clr g2map_overlay_pens_ready
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
	tst g2map_overlay_active
	bne .retain_cache
	jsr g2automap_reset
.retain_cache
	move.l 4.w,a6
	jsr -120(a6)
	move g2map_saved_frame,framecnt
	move g2map_saved_pause,paused
	jsr -126(a6)
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts

; Allocate only at a main-task map/level boundary; caller preserves registers.
g2map_allocate
	; Check the zone span before allocating or changing display/pause state.
	move.l map_poly,d0
	beq .fail
	move.l map_ppnt,d1
	sub.l d0,d1
	ble .fail
	move.l d1,d0
	and.l #zo_size-1,d0
	bne .fail
	lsr.l #5,d1
	move.l d1,g2map_zonecount
	move.l d1,d0
	add.l #G2MAP_BYTES,d0
	move.l d0,g2map_allocbytes
	move.l #$10004,d1	; MEMF_FAST | MEMF_CLEAR
	move.l 4.w,a6
	jsr -198(a6)		; AllocMem
	tst.l d0
	bne .allocated
	move.l g2map_allocbytes,d0
	move.l #$10001,d1	; existing PUBLIC fallback
	jsr -198(a6)
.allocated
	move.l d0,g2map_buffer
	beq .fail
	add.l #G2MAP_BYTES,d0
	move.l d0,g2map_flags
	rts
.fail
	clr.l g2map_buffer
	clr.l g2map_flags
	clr.l g2map_allocbytes
	clr.l g2map_zonecount
	moveq #0,d0
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

; c87b83-map3: transparent rotating local map in the completed CLUT stage.
; 64x64 logical pixels, 32 world units/pixel = +/-4 grid/wall units.
; No background, rectangle fill, VRAM access, extra upload or palette writes.
G2MAP_LOCAL_W equ 64
G2MAP_LOCAL_H equ 64
G2MAP_LOCAL_C equ G2MAP_LOCAL_W/2

; Session reset: TAB off, title/new game and central exit.
g2automap_reset
	clr g2map_overlay_active
	; Fall through: release level resources separately from the session choice.
g2automap_release_level
	movem.l d0-d1/a0-a1/a6,-(a7)
	clr g2map_overlay_pens_ready
	move.l g2map_buffer,d0
	beq.w .done
	move.l d0,a1
	move.l g2map_allocbytes,d0
	move.l 4.w,a6
	jsr -210(a6)
.done
	clr.l g2map_buffer
	clr.l g2map_flags
	clr.l g2map_allocbytes
	clr.l g2map_zonecount
	clr.l g2map_mapend
	movem.l (a7)+,d0-d1/a0-a1/a6
	rts


; Rebuild classifications while the newly loaded level is still paused.
; No full-map screen or key wait. Failed allocation/classification skips this
; level's overlay safely; the session choice remains enabled for later levels.
g2automap_begin_level
	movem.l d0-d7/a0-a6,-(a7)
	jsr g2automap_release_level
	tst g2map_overlay_active
	beq .done
	cmp #2,g2display_mode
	bne .done
	tst linked
	bne .done
	bsr g2map_allocate
	tst.l d0
	beq .done
	bsr g2map_classify
	tst.l d0
	bne .done
	jsr g2automap_release_level
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts

g2map_overlay_draw
	movem.l d0-d7/a0-a6,-(a7)
	tst g2map_overlay_active
	beq.w .done
	cmp #2,g2display_mode
	bne.w .done
	cmp #P96DSP_GAMEPLAY,p96display_state
	bne.w .done
	tst paused
	bne.w .done
	tst game_menu_active
	bne.w .done
	tst g2teleport_blackout
	bne.w .done
	tst finished
	bne.w .done
	tst linked
	bne.w .done
	tst.l g2map_flags
	beq.w .done
	tst.l g2map_buffer
	beq.w .done
	tst.l p96clut_stage_ptr
	beq.w .done
	cmp #1,p96clut_active_role
	bne.w .done
	tst p96clut_palette_dirty
	bne.w .done
	; Recheck the live zone span before indexing the retained classifications.
	move.l map_poly,d0
	beq.w .done
	move.l map_ppnt,d1
	sub.l d0,d1
	ble.w .done
	move.l d1,d0
	and.l #31,d0
	bne.w .done
	lsr.l #5,d1
	cmp.l g2map_zonecount,d1
	bne.w .done
	moveq #0,d0
	move p96target_width,d0
	cmp #320,d0
	blo.w .done
	moveq #0,d1
	move p96target_height,d1
	cmp #240,d1
	blo.w .done
	mulu d0,d1
	cmp.l p96clut_stage_size,d1
	bhi.w .done
	move #1,g2map_overlay_scale
	cmp #640,p96target_width
	blo.w .scale_ready
	cmp #480,p96target_height
	blo.w .scale_ready
	move #2,g2map_overlay_scale
.scale_ready
	jsr g2map_overlay_find_pens
	move p96target_height,g2map_overlay_view_bottom
	tst twowins
	beq.w .one_player
	lsr g2map_overlay_view_bottom
.one_player
	move.l player1,a5
	jsr g2map_overlay_player
	tst twowins
	beq.w .done
	move p96target_height,g2map_overlay_view_bottom
	move.l player2,a5
	jsr g2map_overlay_player
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts

; Snapshot a player's integer position/rotation together (brief IRQ transaction).
; The camera vector uses the same Q15 table words as the existing full map.
g2map_overlay_player
	move.l a5,d0
	beq.w .done
	move.l 4.w,a6
	jsr -120(a6)
	move ob_x(a5),d0
	move ob_z(a5),d1
	move ob_rot(a5),d2
	ext.l d0
	ext.l d1
	move.l d0,g2map_overlay_px
	move.l d1,g2map_overlay_pz
	and #255,d2
	move.l camrots,a0
	lea 0(a0,d2.w*8),a0
	move 2(a0),g2map_overlay_sin
	move 6(a0),g2map_overlay_cos
	jsr -126(a6)
	; Lower-left of the physical viewport, with an 8-logical-pixel margin.
	moveq #0,d0
	move g2map_overlay_scale,d0
	mulu #G2MAP_LOCAL_H+8,d0
	move g2map_overlay_view_bottom,d1
	sub d0,d1
	bmi.w .done
	move d1,g2map_overlay_y
	move g2map_overlay_scale,d0
	lsl #3,d0
	move d0,g2map_overlay_x
	move.l map_poly,a4
.zone
	jsr g2map_zone_pen
	beq.w .next
	moveq #0,d6
	move.b g2map_overlay_red,d6
	cmp #3,d7
	bne.w .pen_ready
	move.b g2map_overlay_yellow,d6
.pen_ready
	move d6,d7
	move zo_lx(a4),d0
	move zo_lz(a4),d1
	move zo_rx(a4),d2
	move zo_rz(a4),d3
	ext.l d0
	ext.l d1
	ext.l d2
	ext.l d3
	sub.l g2map_overlay_px,d0
	sub.l g2map_overlay_pz,d1
	sub.l g2map_overlay_px,d2
	sub.l g2map_overlay_pz,d3
	; Cheap conservative world AABB reject, before four multiplies per line.
	; A rotated +/-1024 square fits inside +/-1449, rounded outward to 1536.
	cmp.l #-1536,d0
	bge.w .left_ok
	cmp.l #-1536,d2
	blt.w .next
.left_ok
	cmp.l #1536,d0
	ble.w .right_ok
	cmp.l #1536,d2
	bgt.w .next
.right_ok
	cmp.l #-1536,d1
	bge.w .bottom_ok
	cmp.l #-1536,d3
	blt.w .next
.bottom_ok
	cmp.l #1536,d1
	ble.w .near
	cmp.l #1536,d3
	bgt.w .next
.near
	jsr g2map_overlay_project
	exg d0,d2
	exg d1,d3
	jsr g2map_overlay_project
	jsr g2map_overlay_line
.next
	lea zo_size(a4),a4
	cmpa.l map_ppnt,a4
	blo.w .zone
	; Small fixed upward-pointing filled arrow, drawn last over the walls.
	moveq #0,d7
	move.b g2map_overlay_white,d7
	moveq #G2MAP_LOCAL_C-2,d6
.ray
	move d6,d0
	moveq #G2MAP_LOCAL_C+2,d1
	moveq #G2MAP_LOCAL_C,d2
	moveq #G2MAP_LOCAL_C-4,d3
	jsr g2map_overlay_line
	addq #1,d6
	cmp #G2MAP_LOCAL_C+2,d6
	ble.w .ray
.done
	rts

; Signed LONG player-relative coordinates -> logical screen WORDS.
; Halving before MULS avoids extreme-coordinate overflow. Combined >>19
; gives 1px/32 world units; precision loss is under one pixel.
; right=dx*cos+dz*sin; screen-down=dx*sin-dz*cos, matching game heading.
g2map_overlay_project
	movem.l d2-d6,-(a7)
	asr.l #1,d0
	asr.l #1,d1
	move d0,d2
	move d1,d3
	muls g2map_overlay_cos,d0
	muls g2map_overlay_sin,d1
	add.l d1,d0
	muls g2map_overlay_sin,d2
	muls g2map_overlay_cos,d3
	sub.l d3,d2
	asr.l #8,d0
	asr.l #8,d0
	asr.l #3,d0
	move.l d2,d1
	asr.l #8,d1
	asr.l #8,d1
	asr.l #3,d1
	add #G2MAP_LOCAL_C,d0
	add #G2MAP_LOCAL_C,d1
	movem.l (a7)+,d2-d6
	rts

; Cohen-Sutherland clip, then bounded Bresenham. Every accepted line is
; inside 0..63, so no far-wall iteration and no writes outside the rectangle.
g2map_overlay_line
	movem.l d0-d7/a0,-(a7)
	move.b d7,g2map_overlay_pen
.clip
	jsr g2map_overlay_outcode
	move d4,d5
	exg d0,d2
	exg d1,d3
	jsr g2map_overlay_outcode
	exg d0,d2
	exg d1,d3
	move d4,d6
	and d5,d4
	bne.w .done
	move d5,d4
	or d6,d4
	beq.w .raster
	; Always intersect the first endpoint; swap if only the second is outside.
	tst d5
	bne.w .outside
	exg d0,d2
	exg d1,d3
	move d6,d5
.outside
	move d2,d4
	sub d0,d4
	move d3,d6
	sub d1,d6
	btst #2,d5
	bne.w .top
	btst #3,d5
	bne.w .bottom
	moveq #0,d5
	cmp #0,d0
	blt.w .vertical
	moveq #G2MAP_LOCAL_W-1,d5
.vertical
	sub d0,d5
	muls d6,d5
	tst d4
	beq.w .done
	divs d4,d5
	add d5,d1
	cmp #0,d0
	blt.w .left
	moveq #G2MAP_LOCAL_W-1,d0
	bra.w .clip
.left
	moveq #0,d0
	bra.w .clip
.top
	moveq #0,d5
	bra.w .horizontal
.bottom
	moveq #G2MAP_LOCAL_W-1,d5
.horizontal
	sub d1,d5
	muls d4,d5
	tst d6
	beq.w .done
	divs d6,d5
	add d5,d0
	cmp #0,d1
	blt.w .up
	moveq #G2MAP_LOCAL_H-1,d1
	bra.w .clip
.up
	moveq #0,d1
	bra.w .clip
.raster
	moveq #1,d4
	moveq #1,d5
	sub d0,d2
	bge.w .dx
	neg d2
	neg d4
.dx
	sub d1,d3
	bge.w .dy
	neg d3
	neg d5
.dy
	move d2,d6
	sub d3,d6
	move d2,-(a7)
	cmp d3,d2
	bge.w .loop
	move d3,(a7)
.loop
	jsr g2map_overlay_pixel
	move d6,-(a7)
	add d6,d6
	neg d3
	cmp d3,d6
	ble.w .nox
	add d4,d0
.nox
	neg d3
	cmp d2,d6
	bge.w .noy
	add d5,d1
	add d2,(a7)
.noy
	neg d3
	cmp d3,d6
	ble.w .noerr
	add d3,(a7)
.noerr
	neg d3
	move (a7)+,d6
	subq #1,(a7)
	bpl.w .loop
	addq.l #2,a7
.done
	movem.l (a7)+,d0-d7/a0
	rts

; outcode bits: left, right, top, bottom. Leaves all but d4 unchanged.
g2map_overlay_outcode
	moveq #0,d4
	tst d0
	bpl.w .right
	or #1,d4
.right
	cmp #G2MAP_LOCAL_W,d0
	blt.w .top
	or #2,d4
.top
	tst d1
	bpl.w .bottom
	or #4,d4
.bottom
	cmp #G2MAP_LOCAL_H,d1
	blt.w .done
	or #8,d4
.done
	rts

; Transparent pixel writer: only the selected wall/arrow pixels are touched.
; Scaled 2x2 at HiRes, same logical geometry in every supported P96 mode.
g2map_overlay_pixel
	cmp #G2MAP_LOCAL_W,d0
	bhs.w .done
	cmp #G2MAP_LOCAL_H,d1
	bhs.w .done
	movem.l d0-d3/a0,-(a7)
	move g2map_overlay_scale,d2
	mulu d2,d0
	mulu d2,d1
	add g2map_overlay_x,d0
	add g2map_overlay_y,d1
	mulu p96target_width,d1
	and.l #$ffff,d0
	add.l d0,d1
	move.l p96clut_stage_ptr,a0
	adda.l d1,a0
	move.b g2map_overlay_pen,d3
	move.b d3,(a0)
	cmp #2,d2
	bne.w .restore
	move.b d3,1(a0)
	moveq #0,d1
	move p96target_width,d1
	move.b d3,0(a0,d1.l)
	move.b d3,1(a0,d1.l)
.restore
	movem.l (a7)+,d0-d3/a0
.done
	rts

; Palette-aware nearest red/yellow/white, cached by the live LUT inputs.
; Uses existing gameplay pens; it never steals colours from the 256-colour scene.
; Exact RGB colours are used when present; otherwise nearest available shades.
g2map_overlay_find_pens
	tst g2map_overlay_pens_ready
	beq.w .rebuild
	move.l p96palette_generation,d0
	cmp.l g2map_overlay_pal_generation,d0
	bne.w .rebuild
	move.l p96palette_remap_generation,d0
	cmp.l g2map_overlay_remap_generation,d0
	bne.w .rebuild
	move.l p96gameplay_palette_ptr,d0
	cmp.l g2map_overlay_palette_ptr,d0
	bne.w .rebuild
	move p96gameplay_palette_source,d0
	cmp g2map_overlay_palette_source,d0
	bne.w .rebuild
	move p96gameplay_lut_aga,d0
	cmp g2map_overlay_palette_aga,d0
	beq.w .done
.rebuild
	lea g2map_overlay_red,a2
	moveq #31,d4
	moveq #0,d5
	moveq #0,d6
	jsr g2map_overlay_nearest
	lea g2map_overlay_yellow,a2
	moveq #31,d4
	moveq #63,d5
	moveq #0,d6
	jsr g2map_overlay_nearest
	lea g2map_overlay_white,a2
	moveq #31,d4
	moveq #63,d5
	moveq #31,d6
	jsr g2map_overlay_nearest
	move.l p96palette_generation,g2map_overlay_pal_generation
	move.l p96palette_remap_generation,g2map_overlay_remap_generation
	move.l p96gameplay_palette_ptr,g2map_overlay_palette_ptr
	move p96gameplay_palette_source,g2map_overlay_palette_source
	move p96gameplay_lut_aga,g2map_overlay_palette_aga
	move #-1,g2map_overlay_pens_ready
.done
	rts

; d4/d5/d6 = R5/G6/B5 target, a2=output byte. Prefer first exact match.
g2map_overlay_nearest
	lea p96gameplay_rgb565_source_lut,a0
	move #$7fff,d3
	moveq #0,d7
	clr.b (a2)
.pen
	move (a0)+,d0
	ror #8,d0 ; RGBFB_R5G6B5PC storage -> RGB565 components
	move d0,d1
	lsr #8,d1
	lsr #3,d1
	and #31,d1
	sub d4,d1
	bpl.w .red
	neg d1
.red
	move d1,d2
	move d0,d1
	lsr #5,d1
	and #63,d1
	sub d5,d1
	bpl.w .green
	neg d1
.green
	add d1,d2
	and #31,d0
	sub d6,d0
	bpl.w .blue
	neg d0
.blue
	add d0,d2
	cmp d3,d2
	bhs.w .next
	move d2,d3
	move.b d7,(a2)
	tst d3
	beq.w .done
.next
	addq #1,d7
	cmp #256,d7
	blo.w .pen
.done
	rts

	even
g2map_overlay_active dc.w 0
g2map_overlay_pens_ready dc.w 0
g2map_overlay_scale dc.w 1
g2map_overlay_view_bottom dc.w 0
g2map_overlay_x dc.w 0
g2map_overlay_y dc.w 0
g2map_overlay_px dc.l 0
g2map_overlay_pz dc.l 0
g2map_overlay_sin dc.w 0
g2map_overlay_cos dc.w 0
g2map_overlay_pal_generation dc.l 0
g2map_overlay_remap_generation dc.l 0
g2map_overlay_palette_ptr dc.l 0
g2map_overlay_palette_source dc.w 0
g2map_overlay_palette_aga dc.w 0
g2map_overlay_red dc.b 0
g2map_overlay_yellow dc.b 0
g2map_overlay_white dc.b 0
g2map_overlay_pen dc.b 0
