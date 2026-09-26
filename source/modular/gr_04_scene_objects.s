calcscene	;a5=player object
	;
	move	#$20,$dff09a
	;
	move.l	player_(pc),a0
	;
	move.l	ob_palette(a0),palette
	move	ob_thermo(a0),thermo
	move	ob_infra(a0),infra
	move	ob_pixsize(a0),pixsize
	;
	clr.l	shapelist
	bsr	calccamera
	bsr	makewalls
	;
	lea	objects,a5	;c87b68a: GenAm PC-range buildfix
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.done
	cmp.l	player_(pc),a5
	beq.s	.loop
	move.l	ob_render(a5),a0
	tst	ob_invisible(a5)
	beq.s	.notinvs
	bpl.s	.hb
	move.l	#drawobjtrans,shaperender
	bra.s	.rit
.hb	move.l	#drawobjinvs,shaperender
.rit	move.l	a5,g2_shape_owner	;v126 owner for enemy blob shadow
	jsr	(a0)
	clr.l	g2_shape_owner
	move.l	#drawobjnorm,shaperender
	bra.s	.loop
.notinvs	move.l	a5,g2_shape_owner	;v126 owner for enemy blob shadow
	jsr	(a0)
	clr.l	g2_shape_owner
	bra.s	.loop
.done	;
	; c87b69 STOCK keeps the original Gloom gore-list traversal unchanged.
	lea	gore,a5
	;
.loop2	move.l	(a5),a5
	tst.l	(a5)
	beq.s	.done2
	;
	movem	go_x(a5),d0/d2
	moveq	#0,d1
	move.l	go_shape(a5),a0
	move	#$200,d7
	clr.l	g2_shape_owner	;v126 gore/body chunks never get enemy shadows
	bsr	drawshape_q
	;
	bra.s	.loop2
	;
.done2	move	#$8020,$dff09a
	;
	rts

blitscene	;
	move.l	player_(pc),a5
	;
	; v103: teleport handoff blackout.  Once the last visible teleport pixel
	; frame has been reached, suppress gun/HUD/statusbar and C2P a clean black
	; frame.  The intermission is only shown after it has loaded.
	tst	g2teleport_blackout
	beq.s	.g2bs_not_blackout
	jsr	g2clearfullchunky
	clr	panelcnt
	rts
.g2bs_not_blackout
	;
	; v190gi: no lower statusbar/panel. Draw gun at the new bottom and
	; draw top HUD through the normal chunky/C2P path.
	bclr	#7,ob_update(a5)
	bsr	g2drawgun
	bsr	showstats
	clr	panelcnt
	rts

.noupdate	move	ob_messtimer(a5),d0
	bpl.s	.mskip
	addq	#1,d0
	beq.s	.mdone
	neg	ob_messtimer(a5)
	move.l	ob_window(a5),a0
	;bsr	putstrip
	bsr	printmess
	bra.s	.mskip
	;
.mdone	clr	ob_messtimer(a5)
	move.l	ob_window(a5),a0
	;bsr	putstrip
.mskip	;
	rts

drawscene	;a5=player
	; v28: pinpoint first-level crash inside drawscene.
	bsr	castwalls
	bsr	g2renderwalls_dispatch
	; Gloombench2 Patch 2: derive per-row wall transitions from vertdraws.
	; This is read-only renderer metadata; walls and sprite Z clipping stay unchanged.
	jsr	g2p2_build_wall_spans
	; v190fx: real-Amiga safe order. Do not run the v190bb wallspan
	; void-fog pass before roof/floor; late neutral void-fog remains after flats.
	;
	move	roofflag(pc),d0
	ble.s	.g2v190dm_roof_fog
	move	#-255,d0
	sub	camy(pc),d0
	moveq	#1,d1
	move	miny(pc),d7
	move.l	roof(pc),a0
	bsr	flat
	bra.s	.noroof
.g2v190dm_roof_fog
	; c87b69 STOCK: disabled-flat neutral fog is Reforged-only. Preserve the
	; already-cleared classic background instead of calculating/filling it.
	tst	g2stock_enabled
	bne.s	.noroof
	moveq	#1,d1		; CEILING NO: Reforged neutral fog
	move	miny(pc),d7
	jsr	g2fill_disabled_flat_fog
.noroof	;
	move	floorflag(pc),d0
	ble.s	.g2v190dm_floor_fog
	move	camy(pc),d0
	neg	d0
	moveq	#-1,d1
	move	maxy(pc),d7
	subq	#1,d7
	move.l	floor(pc),a0
	bsr	flat
	bra.s	.nofloor
.g2v190dm_floor_fog
	; c87b69 STOCK: as above, leave the original cleared background untouched.
	tst	g2stock_enabled
	bne.s	.nofloor
	moveq	#-1,d1		; FLOOR NO: Reforged neutral fog
	move	maxy(pc),d7
	subq	#1,d7
	jsr	g2fill_disabled_flat_fog
.nofloor	;
	; c86zc1: full weak wall-reflection test.  Run after floor/ceiling so the
	; sparse reflected pixels sit on top of the floor, but before sprites/blood.
	; c86zc4: wall reflections removed again.  Keep the wall-reflection routine
	; in the source for possible later experiments, but do not call it now.
	; c86zco: conservative re-enable.  The routine is guarded by g2_reflections
	; and mirrors already-rendered wall columns with the same Bayer logic family
	; used by enemy/player floor reflections.  Use jsr to avoid GenAm range pain.
	; c87b68 STOCK: do not enter the wall-reflection routine at all.
	tst	g2stock_enabled
	bne.s	.g2stock_no_wall_reflection
	jsr	g2_draw_wall_reflection_lite
.g2stock_no_wall_reflection
	; v190bd: after floor/ceiling, fill any still-empty no-wall columns with
	; a global dark wall fog colour sampled earlier from a far wall.  This
	; keeps very long corridor openings dark instead of black, without
	; interfering with wall/floor rendering or copying texture rows.
	; c87b69 STOCK: the late neutral void-fog fill is Reforged-only.
	tst	g2stock_enabled
	bne.s	.g2stock_no_void_fog
	jsr	g2fill_void_fog_remaining
.g2stock_no_void_fog
	; c87b19: world-fixed floor pools and stored wall stains after flats/walls,
	; but still below shapes, gore chunks and enemies.
	jsr	g2draw_bloodpools
	bsr	drawshapes
	; v17: original gloom2 had an early RTS here, making blood/pixelate reachable.
	; v31: safe chunky blood renderer re-enabled, legacy screen-splat disabled.
	bsr	drawblood
	;
	; v99: ZGloom-style screen colour effects.  Teleport/exit uses pixsize
	; as a blue-white fade timer, then the existing pixelate pass runs.
	; Death/hit uses a transparent red screen tint while the eye-height death
	; animation already moves the view down.
	; c87b69 STOCK: Reforged blue/white framebuffer tint is disabled. The
	; original pixelate transition below remains active.
	tst	g2stock_enabled
	bne.s	.g2ds_no_blue_tint
	move.l	player_(pc),a0
	move	ob_pixsize(a0),d0
	beq.s	.g2ds_no_blue_tint
	jsr	g2apply_blue_tint
.g2ds_no_blue_tint
	; c87b69 STOCK: Reforged red framebuffer tint is disabled as well.
	tst	g2stock_enabled
	bne.s	.g2ds_no_red_tint
	move.l	player_(pc),a0
	tst	ob_paltimer(a0)
	bne.s	.g2ds_red_tint
	tst	ob_hitpoints(a0)
	bgt.s	.g2ds_no_red_tint
.g2ds_red_tint
	jsr	g2apply_red_tint
.g2ds_no_red_tint
	;
	move.l	player_(pc),a0
	move	ob_pixsize(a0),d0
	beq.s	.g2ds_no_pixel
	jsr	pixelate
.g2ds_no_pixel
	rts


; ---------------------------------------------------------------------------
; c87b21: NASTY-only, world-fixed adaptively rasterised floor/wall decals
;
; The shape is defined once in world space. Its seed selects a permanent world
; orientation; camera motion only changes the projection. Every pool row is a
; line between two fixed world endpoints. X, Y and depth are interpolated per
; pixel, so apparent size follows 1/Z when approaching or moving away.
;
; Wall stains are no longer synthesized from current screen overlap. If a wall
; was close enough when the gore settled, its fixed wall point and tangent were
; stored in the gore record. Deterministic world-space droplets are projected
; from those values every frame and therefore remain attached to the same wall.
; ---------------------------------------------------------------------------

g2draw_bloodpools
	; c87b68 STOCK: no persistent NASTY floor pools or wall stains.
	tst	g2stock_enabled
	bne.s	.g2bp_stock_rts
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#2,mode
	bne.w	.g2bp_done
	move.l	chunky(pc),d0
	beq.w	.g2bp_done
	lea	gore,a5	;c87b78l: GenAm-safe absolute relocatable address
.g2bp_loop
	move.l	(a5),a5
	tst.l	(a5)
	beq.w	.g2bp_done
	tst	go_pool_seed(a5)
	beq.s	.g2bp_loop
	bsr	g2draw_bloodpool_one
	bra.s	.g2bp_loop
.g2bp_done
	movem.l	(a7)+,d0-d7/a0-a6
.g2bp_stock_rts
	rts

g2draw_bloodpool_one
	move	go_x(a5),g2bp_centerx
	move	go_z(a5),g2bp_centerz
	move	go_pool_seed(a5),g2bp_seed
	move	go_pool_size(a5),g2bp_size

	; Permanent random world orientation, derived only from the stored seed.
	move	g2bp_seed(pc),d0
	and	#15,d0
	lsl	#2,d0
	lea	g2bp_rot16(pc),a0
	move	0(a0,d0.w),g2bp_cos
	move	2(a0,d0.w),g2bp_sin

	; Palette-correct dark red shared by ECS/EHB, AGA and P96.
	moveq	#12,d5
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq.s	.g2bp_col_ok
	moveq	#0,d5
	move.b	$800(a0),d5
	bne.s	.g2bp_col_ok
	moveq	#12,d5
.g2bp_col_ok
	move	d5,g2bp_col

	; c87b21: choose raster density from the projected physical radius.
	; The decal keeps the same world size. Only the number of samples changes:
	; far away it collapses to one compact row; nearby it gains enough rows to
	; fill the larger retinal/screen image without becoming sparse or pixelly.
	move	g2bp_centerx(pc),d0
	moveq	#0,d1
	move	g2bp_centerz(pc),d2
	bsr	g2bp_project_xyz
	tst	d0
	beq.w	.g2bp_one_done
	; c87b25: use the same shared fog-distance mapping as sprites and flying
	; blood.  Physical decal size/shape remains unchanged; only its palette
	; colour darkens with distance before the rows and droplets are rasterised.
	move	g2bp_pz(pc),d0
	jsr	g2bp_set_fog_colour
	move	g2bp_size(pc),d0
	ext.l	d0
	lsl.l	#focshft,d0
	divs	g2bp_pz(pc),d0
	jsr	g2view_scale_x_d0
	tst	d0
	bpl.s	.g2bp_rows_abs_ok
	neg	d0
.g2bp_rows_abs_ok
	cmp	#1,d0
	bge.s	.g2bp_rows_min_ok
	moveq	#1,d0
.g2bp_rows_min_ok
	cmp	#32,d0		; c87b78a: cap near floor-pool raster cost
	ble.s	.g2bp_rows_max_ok
	moveq	#32,d0
.g2bp_rows_max_ok
	move	d0,g2bp_rows
	move	d0,g2bp_denom
	subq	#1,g2bp_denom

	moveq	#0,d7
.g2bp_row_loop
	cmp	#1,g2bp_rows
	bne.s	.g2bp_row_multi
	clr	g2bp_rowv
	move	#8,g2bp_idx
	bra.s	.g2bp_row_shape

.g2bp_row_multi
	; Local V remains exactly inside the original fixed world interval
	; -size/2 .. +size/2, independent of the current camera distance.
	move	d7,d0
	mulu	g2bp_size(pc),d0
	divu	g2bp_denom(pc),d0
	move	g2bp_size(pc),d1
	lsr	#1,d1
	sub	d1,d0
	move	d0,g2bp_rowv

	; Normalised 0..16 profile index. Edge wobble therefore belongs to the
	; world shape and does not change when the adaptive row count changes.
	move	d7,d0
	mulu	#16,d0
	divu	g2bp_denom(pc),d0
	move	d0,g2bp_idx

.g2bp_row_shape
	lea	g2bp_profile(pc),a0
	moveq	#0,d4
	move	g2bp_idx(pc),d0
	move.b	0(a0,d0.w),d4
	mulu	g2bp_size(pc),d4
	lsr	#4,d4

	move	g2bp_seed(pc),d0
	move	g2bp_idx(pc),d1
	eor	d1,d0
	rol	#3,d0
	and	#3,d0
	subq	#1,d0
	add	d0,d4
	cmp	#1,d4
	bge.s	.g2bp_half_ok
	moveq	#1,d4
.g2bp_half_ok
	move	d4,g2bp_half

	; Left fixed world endpoint.
	move	g2bp_half(pc),d0
	neg	d0
	move	g2bp_rowv(pc),d1
	moveq	#0,d2
	bsr	g2bp_project_local
	tst	d0
	beq.s	.g2bp_next_row
	movem	g2bp_px(pc),d0-d2
	movem	d0-d2,g2bp_x0

	; Right fixed world endpoint.
	move	g2bp_half(pc),d0
	move	g2bp_rowv(pc),d1
	moveq	#0,d2
	bsr	g2bp_project_local
	tst	d0
	beq.s	.g2bp_next_row
	movem	g2bp_px(pc),d0-d2
	movem	d0-d2,g2bp_x1
	bsr	g2bp_draw_projected_line

.g2bp_next_row
	addq	#1,d7
	cmp	g2bp_rows(pc),d7
	blt.w	.g2bp_row_loop

	; Three fixed local droplets. They use the same permanent orientation and
	; therefore never orbit around the pool when the player turns.
	move	g2bp_size(pc),d5
	move	g2bp_seed(pc),d6

	move	d5,d0
	move	d5,d1
	asr	#1,d1
	add	d1,d0
	btst	#0,d6
	beq.s	.g2bp_d1_sign
	neg	d0
.g2bp_d1_sign
	move	d6,d1
	asr	#3,d1
	and	#7,d1
	subq	#3,d1
	moveq	#3,d2
	bsr	g2bp_draw_local_dot

	move	d5,d0
	addq	#5,d0
	btst	#1,d6
	beq.s	.g2bp_d2_sign
	neg	d0
.g2bp_d2_sign
	move	d5,d1
	asr	#1,d1
	btst	#4,d6
	beq.s	.g2bp_d2_depth
	neg	d1
.g2bp_d2_depth
	moveq	#2,d2
	bsr	g2bp_draw_local_dot

	move	d5,d0
	add	d5,d0
	addq	#3,d0
	btst	#2,d6
	beq.s	.g2bp_d3_sign
	neg	d0
.g2bp_d3_sign
	move	d6,d1
	and	#15,d1
	subq	#7,d1
	moveq	#1,d2
	bsr	g2bp_draw_local_dot

	jsr	g2c87b71a_draw_attached_wall_stain
.g2bp_one_done
	rts

; ---------------------------------------------------------------------------
; Project local pool U/V at world Y.
; in: d0=local U, d1=local V, d2=world Y
; out: d0=-1 success / 0 reject; g2bp_px/py/pz filled on success.
; ---------------------------------------------------------------------------
g2bp_project_local
	move	d0,d4
	move	d1,d5
	move	d2,d6

	; world X = centreX + (U*cos - V*sin)/256
	muls	g2bp_cos(pc),d0
	move	d5,d1
	muls	g2bp_sin(pc),d1
	sub.l	d1,d0
	asr.l	#8,d0
	add	g2bp_centerx(pc),d0
	move	d0,g2bp_wx

	; world Z = centreZ + (U*sin + V*cos)/256
	move	d4,d0
	muls	g2bp_sin(pc),d0
	move	d5,d1
	muls	g2bp_cos(pc),d1
	add.l	d1,d0
	asr.l	#8,d0
	add	g2bp_centerz(pc),d0
	move	d0,d2
	move	d6,d1
	move	g2bp_wx(pc),d0
	bra	g2bp_project_xyz

; ---------------------------------------------------------------------------
; Project a fixed world point.
; in: d0=world X, d1=world Y, d2=world Z
; out: d0=-1 success / 0 reject; g2bp_px/py/pz filled.
; ---------------------------------------------------------------------------
g2bp_project_xyz
	move	d0,d3
	sub	camx(pc),d0
	move	d2,d4
	sub	camz(pc),d4
	move	d0,d5
	move	d4,d6

	muls	cm1(pc),d0
	muls	cm2(pc),d4
	add.l	d4,d0
	add.l	d0,d0
	swap	d0			; camera X

	muls	cm3(pc),d5
	muls	cm4(pc),d6
	add.l	d5,d6
	add.l	d6,d6
	swap	d6			; camera Z / depth

	; c87b20a: allow the fixed world decal to grow much closer to the player.
	; c87b19a discarded complete rows below depth 20, which flattened the
	; apparent size change. Depth 8 keeps the final under-player region safe.
	cmp	#8,d6
	blt.s	.g2bpp_fail
	tst	g2_visibility
	bgt.s	.g2bpp_adv
	cmp	#maxz+64,d6
	bcc.s	.g2bpp_fail
	bra.s	.g2bpp_range_ok
.g2bpp_adv
	cmp	#g2advviewfar+64,d6
	bcc.s	.g2bpp_fail
.g2bpp_range_ok

	; Do not clamp invalid/off-screen endpoints and connect them across the
	; framebuffer. Reject points farther than eight depth-units sideways.
	; This still gives a very generous field outside the visible viewport,
	; while guaranteeing a safe signed DIVS quotient.
	move	d0,d3
	bpl.s	.g2bpp_absx_ok
	neg	d3
.g2bpp_absx_ok
	ext.l	d3
	move	d6,d4
	mulu	#8,d4
	cmp.l	d4,d3
	bhi.s	.g2bpp_fail

	ext.l	d0
	lsl.l	#focshft,d0
	divs	d6,d0
	jsr	g2view_scale_x_d0
	add	midx(pc),d0
	move	d0,g2bp_px

	sub	camy(pc),d1
	ext.l	d1
	lsl.l	#focshft,d1
	divs	d6,d1
	jsr	g2view_scale_y_d1
	add	midy(pc),d1
	move	d1,g2bp_py
	move	d6,g2bp_pz
	moveq	#-1,d0
	rts
.g2bpp_fail
	moveq	#0,d0
	rts

; ---------------------------------------------------------------------------
; Draw a small world-fixed side droplet with adaptive local rows.
; in: d0=local centre U, d1=local centre V, d2=world radius.
; ---------------------------------------------------------------------------
g2bp_draw_local_dot
	movem.l	d0-d7/a0,-(a7)
	move	d0,g2bp_dotu
	move	d1,g2bp_dotv
	move	d2,g2bp_dotr

	; Project the fixed droplet centre only to obtain its current depth.
	move	g2bp_dotu(pc),d0
	move	g2bp_dotv(pc),d1
	moveq	#0,d2
	bsr	g2bp_project_local
	tst	d0
	beq.w	.g2bpdot_done

	; Screen-space diameter determines sampling density, not physical size.
	move	g2bp_dotr(pc),d0
	ext.l	d0
	lsl.l	#focshft,d0
	divs	g2bp_pz(pc),d0
	jsr	g2view_scale_x_d0
	tst	d0
	bpl.s	.g2bpdot_abs_ok
	neg	d0
.g2bpdot_abs_ok
	add	d0,d0
	addq	#1,d0
	cmp	#1,d0
	bge.s	.g2bpdot_min_ok
	moveq	#1,d0
.g2bpdot_min_ok
	cmp	#8,d0		; c87b78a: cap satellite-droplet raster cost
	ble.s	.g2bpdot_max_ok
	moveq	#8,d0
.g2bpdot_max_ok
	move	d0,g2bp_rows
	move	d0,g2bp_denom
	subq	#1,g2bp_denom

	moveq	#0,d7
.g2bpdot_loop
	cmp	#1,g2bp_rows
	bne.s	.g2bpdot_multi
	move	g2bp_dotv(pc),g2bp_rowv
	move	#2,g2bp_idx
	bra.s	.g2bpdot_shape

.g2bpdot_multi
	; World V = centreV - radius + (2*radius*i)/(rows-1).
	move	g2bp_dotr(pc),d0
	add	d0,d0
	mulu	d7,d0
	divu	g2bp_denom(pc),d0
	sub	g2bp_dotr(pc),d0
	add	g2bp_dotv(pc),d0
	move	d0,g2bp_rowv

	move	d7,d0
	mulu	#4,d0
	divu	g2bp_denom(pc),d0
	move	d0,g2bp_idx

.g2bpdot_shape
	lea	g2bp_dotprofile(pc),a0
	moveq	#0,d4
	move	g2bp_idx(pc),d0
	move.b	0(a0,d0.w),d4
	mulu	g2bp_dotr(pc),d4
	lsr	#2,d4
	cmp	#1,d4
	bge.s	.g2bpdot_half_ok
	moveq	#1,d4
.g2bpdot_half_ok
	move	d4,g2bp_half

	move	g2bp_dotu(pc),d0
	sub	g2bp_half(pc),d0
	move	g2bp_rowv(pc),d1
	moveq	#0,d2
	bsr	g2bp_project_local
	tst	d0
	beq.s	.g2bpdot_next
	movem	g2bp_px(pc),d0-d2
	movem	d0-d2,g2bp_x0

	move	g2bp_dotu(pc),d0
	add	g2bp_half(pc),d0
	move	g2bp_rowv(pc),d1
	moveq	#0,d2
	bsr	g2bp_project_local
	tst	d0
	beq.s	.g2bpdot_next
	movem	g2bp_px(pc),d0-d2
	movem	d0-d2,g2bp_x1
	bsr	g2bp_draw_projected_line

.g2bpdot_next
	addq	#1,d7
	cmp	g2bp_rows(pc),d7
	blt.w	.g2bpdot_loop
.g2bpdot_done
	movem.l	(a7)+,d0-d7/a0
	rts

; ---------------------------------------------------------------------------
; Perspective-correct DDA between two projected world endpoints.
; Endpoint layout is X,Y,Z words. Depth is interpolated per pixel.
; ---------------------------------------------------------------------------
g2bp_draw_projected_line
	move.l	#g2bp_plot_floor_pixel,g2bp_plotfn
	bra.s	g2bp_draw_projected_line_core

g2bp_draw_projected_wall_line
	move.l	#g2bp_plot_wall_pixel,g2bp_plotfn

g2bp_draw_projected_line_core
	movem.l	d0-d7/a0-a3,-(a7)
	move	g2bp_x1(pc),d3
	sub	g2bp_x0(pc),d3		; dx
	move	g2bp_y1(pc),d4
	sub	g2bp_y0(pc),d4		; dy
	move	g2bp_z1(pc),d5
	sub	g2bp_z0(pc),d5		; dz

	move	d3,d6
	bpl.s	.g2bpl_absx
	neg	d6
.g2bpl_absx
	move	d4,d7
	bpl.s	.g2bpl_absy
	neg	d7
.g2bpl_absy
	cmp	d7,d6
	bge.s	.g2bpl_steps_ok
	move	d7,d6
.g2bpl_steps_ok
	tst	d6
	bne.s	.g2bpl_have_steps
	move	g2bp_x0(pc),d0
	move	g2bp_y0(pc),d1
	move	g2bp_z0(pc),d2
	move.l	g2bp_plotfn(pc),a3
	jsr	(a3)
	bra.w	.g2bpl_done
.g2bpl_have_steps
	move	d6,g2bp_steps

	; 8.8 fixed point is sufficient for a one-pixel DDA and keeps every
	; DIVS quotient inside the signed 16-bit range on a plain 68000.
	move	g2bp_x0(pc),d0
	ext.l	d0
	lsl.l	#8,d0
	move.l	d0,g2bp_lx
	move	g2bp_y0(pc),d0
	ext.l	d0
	lsl.l	#8,d0
	move.l	d0,g2bp_ly
	move	g2bp_z0(pc),d0
	ext.l	d0
	lsl.l	#8,d0
	move.l	d0,g2bp_lz

	ext.l	d3
	lsl.l	#8,d3
	divs	d6,d3
	ext.l	d3
	move.l	d3,g2bp_ix
	ext.l	d4
	lsl.l	#8,d4
	divs	d6,d4
	ext.l	d4
	move.l	d4,g2bp_iy
	ext.l	d5
	lsl.l	#8,d5
	divs	d6,d5
	ext.l	d5
	move.l	d5,g2bp_iz

	move	g2bp_steps(pc),d7
.g2bpl_loop
	move.l	g2bp_lx(pc),d0
	asr.l	#8,d0
	move.l	g2bp_ly(pc),d1
	asr.l	#8,d1
	move.l	g2bp_lz(pc),d2
	asr.l	#8,d2
	move.l	g2bp_plotfn(pc),a3
	jsr	(a3)
	move.l	g2bp_ix(pc),d0
	add.l	d0,g2bp_lx
	move.l	g2bp_iy(pc),d0
	add.l	d0,g2bp_ly
	move.l	g2bp_iz(pc),d0
	add.l	d0,g2bp_lz
	dbf	d7,.g2bpl_loop
.g2bpl_done
	movem.l	(a7)+,d0-d7/a0-a3
	rts

; d0=screen X, d1=screen Y, d2=depth.
g2bp_plot_floor_pixel
	tst	d0
	bmi.s	.g2bppx_done
	cmp	g2render_width(pc),d0
	bge.s	.g2bppx_done
	tst	d1
	bmi.s	.g2bppx_done
	cmp	hite(pc),d1
	bge.s	.g2bppx_done

	move.l	vertdraws(pc),a0
	move	d0,d3
	mulu	#vd_size,d3
	lea	0(a0,d3.l),a0
	tst.l	vd_data(a0)
	beq.s	.g2bppx_visible
	cmp	vd_z(a0),d2
	bge.s	.g2bppx_done
.g2bppx_visible
	move.l	chunky(pc),a1
	move	d1,d3
	mulu	g2render_stride(pc),d3
	add.l	d3,a1
	lea	coloffs(pc),a2
	move.l	0(a2,d0*4),d3
	move	g2bp_col(pc),d4
	move.b	d4,0(a1,d3.l)
.g2bppx_done
	rts

; ---------------------------------------------------------------------------
; Fixed wall stain. All generated positions are deterministic world points on
; the wall plane. Visibility accepts only the frontmost wall at that column.
; ---------------------------------------------------------------------------
g2bp_draw_wall_stain
	movem.l	d0-d7/a0-a3,-(a7)

	; Main fixed stain.
	moveq	#0,d0
	move	g2bp_size(pc),d3
	lsr	#1,d3
	move	d3,d1
	addq	#2,d1
	neg	d1
	move	d3,d2			; original wall spread: radius = size/2
	bsr	g2bp_draw_wall_oval

	; Satellite 1.
	move	g2bp_size(pc),d0
	move	d0,d4
	lsr	#1,d4
	add	d4,d0
	btst	#0,g2bp_seed+1
	beq.s	.g2bpws_sat1_sign
	neg	d0
.g2bpws_sat1_sign
	move	g2bp_size(pc),d1
	lsr	#2,d1
	addq	#3,d1
	neg	d1
	moveq	#3,d2
	moveq	#2,d3
	bsr	g2bp_draw_wall_oval

	; Satellite 2.
	move	g2bp_size(pc),d0
	addq	#6,d0
	btst	#1,g2bp_seed+1
	beq.s	.g2bpws_sat2_sign
	neg	d0
.g2bpws_sat2_sign
	move	g2bp_size(pc),d1
	addq	#5,d1
	neg	d1
	moveq	#2,d2
	moveq	#3,d3
	bsr	g2bp_draw_wall_oval

	; Satellite 3: narrow vertical run.
	move	g2bp_seed(pc),d0
	and	#15,d0
	subq	#7,d0
	move	g2bp_size(pc),d1
	move	d1,d4
	lsr	#1,d4
	add	d4,d1
	neg	d1
	moveq	#1,d2
	moveq	#4,d3
	bsr	g2bp_draw_wall_oval

	movem.l	(a7)+,d0-d7/a0-a3
	rts

; Draw one physically fixed filled oval on the stored wall.
; in: d0=along-wall centre offset, d1=world Y centre,
;     d2=horizontal radius, d3=vertical radius.
g2bp_draw_wall_oval
	movem.l	d0-d7/a0-a2,-(a7)
	move	d0,g2bp_walloff
	move	d1,g2bp_wallcy
	move	d2,g2bp_wallrx
	move	d3,g2bp_wallry

	; Convert along-wall offset through the stored 1.15 tangent.
	move	g2bp_walloff(pc),d0
	muls	g2bp_walltx(pc),d0
	add.l	d0,d0
	swap	d0
	add	g2bp_wallx(pc),d0
	move	d0,g2bp_wallcx

	move	g2bp_walloff(pc),d0
	muls	g2bp_walltz(pc),d0
	add.l	d0,d0
	swap	d0
	add	g2bp_wallz(pc),d0
	move	d0,g2bp_wallcz

	; Screen-space height determines raster density only.
	move	g2bp_wallcx(pc),d0
	move	g2bp_wallcy(pc),d1
	move	g2bp_wallcz(pc),d2
	bsr	g2bp_project_xyz
	tst	d0
	beq.w	.g2bpwo_done
	; c87b25: wall splashes follow their own fixed wall depth, so each oval
	; receives the correct fog shade even when it is offset from the floor pool.
	move	g2bp_pz(pc),d0
	jsr	g2bp_set_fog_colour

	move	g2bp_wallry(pc),d0
	ext.l	d0
	lsl.l	#focshft,d0
	divs	g2bp_pz(pc),d0
	jsr	g2view_scale_y_d0
	tst	d0
	bpl.s	.g2bpwo_abs_ok
	neg	d0
.g2bpwo_abs_ok
	add	d0,d0
	addq	#1,d0
	cmp	#1,d0
	bge.s	.g2bpwo_min_ok
	moveq	#1,d0
.g2bpwo_min_ok
	cmp	#32,d0		; c87b78a: cap near wall-stain raster cost
	ble.s	.g2bpwo_max_ok
	moveq	#32,d0
.g2bpwo_max_ok
	move	d0,g2bp_rows
	move	d0,g2bp_denom
	subq	#1,g2bp_denom

	moveq	#0,d7
.g2bpwo_loop
	cmp	#1,g2bp_rows
	bne.s	.g2bpwo_multi
	move	g2bp_wallcy(pc),g2bp_wally
	move	#8,g2bp_idx
	bra.s	.g2bpwo_shape

.g2bpwo_multi
	move	g2bp_wallry(pc),d0
	add	d0,d0
	mulu	d7,d0
	divu	g2bp_denom(pc),d0
	sub	g2bp_wallry(pc),d0
	add	g2bp_wallcy(pc),d0
	move	d0,g2bp_wally

	move	d7,d0
	mulu	#16,d0
	divu	g2bp_denom(pc),d0
	move	d0,g2bp_idx

.g2bpwo_shape
	lea	g2bp_profile(pc),a0
	moveq	#0,d4
	move	g2bp_idx(pc),d0
	move.b	0(a0,d0.w),d4
	mulu	g2bp_wallrx(pc),d4
	lsr	#4,d4

	move	g2bp_seed(pc),d0
	move	g2bp_idx(pc),d1
	eor	d1,d0
	ror	#3,d0
	and	#3,d0
	subq	#1,d0
	add	d0,d4
	cmp	#1,d4
	bge.s	.g2bpwo_half_ok
	moveq	#1,d4
.g2bpwo_half_ok
	move	d4,g2bp_half

	; Left wall endpoint.
	move	g2bp_half(pc),d5
	neg	d5
	move	d5,d0
	muls	g2bp_walltx(pc),d0
	add.l	d0,d0
	swap	d0
	add	g2bp_wallcx(pc),d0
	move	d0,d4

	move	d5,d0
	muls	g2bp_walltz(pc),d0
	add.l	d0,d0
	swap	d0
	add	g2bp_wallcz(pc),d0
	move	d0,d2

	move	d4,d0
	move	g2bp_wally(pc),d1
	bsr	g2bp_project_xyz
	tst	d0
	beq.s	.g2bpwo_next
	movem	g2bp_px(pc),d0-d2
	movem	d0-d2,g2bp_x0

	; Right wall endpoint.
	move	g2bp_half(pc),d5
	move	d5,d0
	muls	g2bp_walltx(pc),d0
	add.l	d0,d0
	swap	d0
	add	g2bp_wallcx(pc),d0
	move	d0,d4

	move	d5,d0
	muls	g2bp_walltz(pc),d0
	add.l	d0,d0
	swap	d0
	add	g2bp_wallcz(pc),d0
	move	d0,d2

	move	d4,d0
	move	g2bp_wally(pc),d1
	bsr	g2bp_project_xyz
	tst	d0
	beq.s	.g2bpwo_next
	movem	g2bp_px(pc),d0-d2
	movem	d0-d2,g2bp_x1
	bsr	g2bp_draw_projected_wall_line

.g2bpwo_next
	addq	#1,d7
	cmp	g2bp_rows(pc),d7
	blt.w	.g2bpwo_loop

.g2bpwo_done
	movem.l	(a7)+,d0-d7/a0-a2
	rts

; d0=screen X, d1=screen Y, d2=projected wall depth.
g2bp_plot_wall_pixel
	tst	d0
	bmi.s	.g2bpwp_done
	cmp	g2render_width(pc),d0
	bge.s	.g2bpwp_done
	tst	d1
	bmi.s	.g2bpwp_done
	cmp	hite(pc),d1
	bge.s	.g2bpwp_done

	move.l	vertdraws(pc),a0
	move	d0,d3
	mulu	#vd_size,d3
	lea	0(a0,d3.l),a0
	tst.l	vd_data(a0)
	beq.s	.g2bpwp_done

	move	d2,d3
	sub	vd_z(a0),d3
	bpl.s	.g2bpwp_abs_ok
	neg	d3
.g2bpwp_abs_ok
	cmp	#16,d3
	bhi.s	.g2bpwp_done

	; Keep the stain inside the visible wall column.
	move	vd_y(a0),d3
	add	midy(pc),d3
	cmp	d3,d1
	blt.s	.g2bpwp_done
	add	vd_h(a0),d3
	cmp	d3,d1
	bge.s	.g2bpwp_done

	move.l	chunky(pc),a1
	move	d1,d3
	mulu	g2render_stride(pc),d3
	add.l	d3,a1
	lea	coloffs(pc),a2
	move.l	0(a2,d0*4),d3
	move	g2bp_col(pc),d4
	move.b	d4,0(a1,d3.l)
.g2bpwp_done
	rts

; 16 world orientations, signed 8.8 unit vectors (cos,sin).
g2bp_rot16
	dc.w	256,0,237,98,181,181,98,237
	dc.w	0,256,-98,237,-181,181,-237,98
	dc.w	-256,0,-237,-98,-181,-181,-98,-237
	dc.w	0,-256,98,-237,181,-181,237,-98

; Compact irregular oval profile, local far edge -> centre -> near edge.
g2bp_profile
	dc.b	2,6,9,11,13,14,15,16,16,16,15,14,13,11,9,6,2
g2bp_dotprofile
	dc.b	1,3,4,3,1
	even

; Persistent-per-draw scratch.
g2bp_centerx	dc	0
g2bp_centerz	dc	0
g2bp_seed	dc	0
g2bp_size	dc	0
g2bp_cos	dc	0
g2bp_sin	dc	0
g2bp_col	dc	0
g2bp_rowv	dc	0
g2bp_half	dc	0
g2bp_idx	dc	0
g2bp_rows	dc	0
g2bp_denom	dc	0
g2bp_wx	dc	0
g2bp_wallx	dc	0
g2bp_wallz	dc	0
g2bp_walltx	dc	0
g2bp_walltz	dc	0
g2bp_walloff	dc	0
g2bp_wallcx	dc	0
g2bp_wallcz	dc	0
g2bp_wallcy	dc	0
g2bp_wallrx	dc	0
g2bp_wallry	dc	0
g2bp_wally	dc	0
g2bp_dotu	dc	0
g2bp_dotv	dc	0
g2bp_dotr	dc	0

; Projected point and endpoint triples: X,Y,Z.
g2bp_px	dc	0
g2bp_py	dc	0
g2bp_pz	dc	0
g2bp_x0	dc	0
g2bp_y0	dc	0
g2bp_z0	dc	0
g2bp_x1	dc	0
g2bp_y1	dc	0
g2bp_z1	dc	0

; DDA 8.8 state.
g2bp_lx	dc.l	0
g2bp_ly	dc.l	0
g2bp_lz	dc.l	0
g2bp_ix	dc.l	0
g2bp_iy	dc.l	0
g2bp_iz	dc.l	0
g2bp_plotfn	dc.l	0
g2bp_steps	dc	0
	even

chatstuff	move	chatok(pc),d0
	beq.s	.rts
	;
	move	chatoutget,d0
	cmp	chatoutput,d0
	beq.s	.noout
	and	#31,d0
	lea	chatout,a0
	move.b	0(a0,d0),d0	;chat out character!
	addq	#1,chatoutget
	moveq	#1,d1
	move	d0,-(a7)
	bsr	chatprintout
	move	(a7)+,d0
	sub.b	#32,d0	;encode for chat
	bset	#6,d0
	bsr	serput
	;
.noout	move	chatcnt(pc),d0
	beq.s	.rts
	;
	move	chatinget,d0
	and	#31,d0
	lea	chatin,a0
	move.b	0(a0,d0),d0
	addq	#1,chatinget
	subq	#1,chatcnt
	moveq	#2,d1
	bsr	chatprintin
	;
.rts	rts

sfxvbint	lea	sfxs(pc),a1
	moveq	#3,d3
	;
.loop	tst	fx_status(a1)
	ble.s	.skip
	;
	;this one queued! gotta play it...
	;
	subq	#1,fx_status(a1)
	bgt.s	.skip
	move.l	fx_sfx(a1),a0
	bsr	playsfxnow
	;
.skip	lea	fx_size(a1),a1
	dbf	d3,.loop
	;
	;fade out song if nec.
	;
	move	fadevol(pc),d0
	beq.s	.nofade
	move.l	medat,a1
	sub	#$80,fadevol
	bgt.s	.setvol
	clr	fadevol
	jmp	12(a1)	;stop song
	bra.s	.nofade
	;
.setvol	move	fadevol(pc),d0
	lsr	#8,d0
	jmp	16(a1)	;set volume
	;
.nofade	rts

	dc.l	readmodem
; v34: KEYBMOUSE becomes control 0, matching stable gloom.s v29a/WAXD.
; joytable_end is used by inputon/inputoff so OS deactivation/EXIT cannot
; overwrite code while clearing the table.
joytable	dc.l	readnull,readnull,readnull,readnull,readnull,readnull
joytable_end
joytable2	dc.l	readkeymouse,readkeys,readjoy1,readjoy0,readcd321,readcd320

readjoy	;a0=player
	move	ob_cntrl(a0),d0
	bmi.s	readmodem
	;
	lea	joyx0,a0
	lea	0(a0,d0*8),a0
	move.l	joytable(pc,d0*4),a1
	jsr	(a1)
	move	linked(pc),d0
	bne.s	.send
	rts
.send	;
	;a0=cntrl block
	;
	bsr	encodejoy
	movem.l	d0/a0,-(a7)
	bsr	serput
	;movem.l	(a7),d0/a0
	;bsr	serput
	movem.l	(a7)+,d0/a0
	;
.noput	lea	pbuff(pc),a1
	;
	move	pput(pc),d1
	and	#127,d1
	move.b	d0,0(a1,d1)
	addq	#1,pput
	;
	move	pget(pc),d1
	and	#127,d1
	move.b	0(a1,d1),d0
	addq	#1,pget
	;
	bra	decodejoy
readmodem	;
	bsr	rbfchk
	bne.s	.serhere
	;
	;OK, do a vwait to allow other machine to catch up!
	;
	move	#$20,$dff09c
.vw	;
	ifne	debugser
	col	#$f0f
	endc
	;
	btst	#5,$dff01f
	beq.s	.vw
	;
	move	#$20,$dff09c
	bsr	chatstuff
	bra.s	readmodem
	;
.serhere	bsr	serget
	lea	joyxs,a0
	bclr	#7,d0
	beq.s	.djoy
	and	#$ff,d0
	move	d0,finished
	moveq	#0,d0
	;bra.s	.sgot
	;
.djoy	;movem.l	d0/a0,-(a7)
	;bsr	serwait
	;move	d0,d1
	;movem.l	(a7)+,d0/a0
	;cmp.b	d0,d1
	;beq.s	.sgot
	;
	;warn	#$fff
	;warn	#$00f
	;
.sgot	bsr	decodejoy
	move.l	(a0)+,joyx
	move.l	(a0),joyb
	rts

escape	dc	0

readjoys	;fill in appropriate 'joyxn' block...check escape
	;
	move	finished(pc),d0
	or	finished2(pc),d0
	bne.s	.rts
	;
	jsr	g2hotkeys_menu_key	; ESC or F10
	sne	escape
	;
	move.l	player1(pc),a0
	bsr	readjoy
	move	gametype(pc),d0
	beq.s	.rts
	move.l	player2(pc),a0
	bra	readjoy
	;
.rts	rts

lrnd	dc	0

vbhandler	movem.l	d2-d7/a2-a6,-(a7)
	;
	subq	#1,(a1)+	;inc/dec frame counters
	addq	#1,(a1)
	;
	; v34: sample/apply KEYBMOUSE mouse before drawing, as in stable v29a.
	jsr	sample_keymouse_vb
	;this done every frame!
	bsr	chatstuff
	bsr	sfxvbint
	;
	btst	#0,framecnt+1
	beq	exit_vb2
	tst	paused
	bne	exit_vb2
	;
	;OK, movement/animation stuff!
	;
	bsr	readjoys
	bsr	doanims
	bsr	dorots
	bsr	dodoors
	; v31: update blood particles again; draw path is guarded/chunky-safe.
	bsr	moveblood
	;
	ifne	debugser
	;
	;OK, kludge in a random number!
	move	framecnt(pc),d0
	and	#126,d0
	bne.s	.nornd
	;
	bsr	rndw
	move	lrnd(pc),d1
	move	d0,lrnd
	cmp	d0,d1
	bne.s	.hi
	warn	#$fff
	warn	#$00f
.hi	lea	.rndasc(pc),a0
	moveq	#3,d1
.loop	rol	#4,d0
	move	d0,d2
	and	#15,d2
	add	#48,d2
	cmp	#58,d2
	bcs.s	.rok
	addq	#7,d2
.rok	move.b	d2,(a0)+
	dbf	d1,.loop
	;
	move.l	player1(pc),a5
	bsr	message
.rndasc	dc.b	'aaaa',0
	even
	;
	endc
.nornd	;
	move.l	a7,obj_stack
	lea	objects(pc),a5
	;
obj_loop	move.l	(a5),a5
	tst.l	(a5)
	beq	exit_vb
	;
	move.l	ob_logic(a5),a0
	jsr	(a0)
	;
	;check collision!
	;
	move	ob_collwith(a5),d0
	beq.s	obj_loop
	;
	move	ob_rad(a5),d1
	move	ob_x(a5),d6
	move	ob_z(a5),d7
	;
	lea	objects(pc),a0
	;
.loop2	move.l	(a0),a0
	cmp.l	a5,a0
	bne.s	.this
	;
	clr.l	ob_washit(a5)	;not hit! can get hit next time...
	bra	obj_loop
.this	;
	move	ob_colltype(a0),d2
	and	d0,d2
	beq.s	.loop2
	;
	move	ob_rad(a0),d2
	add	d1,d2	;r sum
	;
	move	ob_x(a0),d3
	sub	d6,d3
	bpl.s	.xpl
	neg	d3
.xpl	cmp	d2,d3
	bcc.s	.loop2
	;
	move	ob_z(a0),d4
	sub	d7,d4
	bpl.s	.ypl
	neg	d4
.ypl	cmp	d2,d4
	bcc.s	.loop2
	;
	mulu	d2,d2
	mulu	d3,d3
	mulu	d4,d4
	add.l	d4,d3
	cmp.l	d2,d3
	bcc.s	.loop2
	;
	cmp.l	ob_washit(a5),a0
	beq	obj_loop
	move.l	a0,ob_washit(a5)
	;
	move	finished2(pc),d0
	bne	obj_loop
	;
	move.l	#killobject3,killjsr
	movem.l	a0/a5,obj_a0
	exg.l	a0,a5
	;
	move	ob_damage(a0),d0
	bsr	g2_onehit_damage
	move.l	ob_hit(a5),a1
	sub	d0,ob_hitpoints(a5)
	bgt.s	hit_skip
	move.l	ob_die(a5),a1
	;
hit_skip	jsr	(a1)
	;
hit_ret	move.l	#killobject2,killjsr
	movem.l	obj_a0(pc),a0/a5
	;
	move	ob_damage(a0),d0
	bsr	g2_onehit_damage
	move.l	ob_hit(a5),a1
	sub	d0,ob_hitpoints(a5)
	bgt.s	hit_skip2
	move.l	ob_die(a5),a1
	;
hit_skip2	jsr	(a1)
	bra	obj_loop

; v183: ONE-HIT-KILL cheat.  Only projectile objects get their damage
; raised to the target's remaining hitpoints, and players themselves are
; explicitly excluded so player/friendly damage is untouched.
g2_onehit_damage	; in/out d0=damage, a0=attacker, a5=victim
	tst	trainer_onehit
	beq.s	.rts
	tst	d0
	ble.s	.rts
	move.l	ob_logic(a0),d1
	cmp.l	#firelogic,d1
	beq.s	.projectile
	cmp.l	#homeinlogic,d1
	bne.s	.rts
.projectile
	move.l	player1(pc),d1
	cmp.l	d1,a5
	beq.s	.rts
	move.l	player2(pc),d1
	cmp.l	d1,a5
	beq.s	.rts
	move	ob_hitpoints(a5),d1
	ble.s	.rts
	move	d1,d0
.rts	rts
	;
exit_vb	st	doneflag
	;
exit_vb2	st	showflag
	;
	movem.l	(a7)+,d2-d7/a2-a6
	moveq	#0,d0
	;
rts	rts

obj_a0	dc.l	0
obj_a5	dc.l	0
obj_stack	dc.l	0
killjsr	dc.l	killobject2

killobject	;
	move.l	killjsr(pc),a0
	jmp	(a0)

killobject2	move.l	a5,a0
	killitem	objects
	move.l	a0,a5
	move.l	obj_stack(pc),a7
	bra	obj_loop

killobject3	move.l	a5,a0
	killitem	objects
	move.l	obj_stack(pc),a7
	bra	hit_ret

bloodspeed	bsr	rndw
	ext.l	d0
	lsl.l	#2,d0
	rts

bloodspeed2	bsr	rndw
	ext.l	d0
	lsl.l	#5,d0
	rts

bloodspeed3	bsr	rndw
	ext.l	d0
	lsl.l	#4,d0
	rts

makesparksq	move.l	ob_chunks(a5),a2
	;
makesparks	;a2=sparks
	;
	movem.l	ob_x(a5),d2-d4
	move	2(a2),d5
	subq	#1,d5
	;
.loop	addlast	objects
	beq	.rts
	movem.l	d2-d4,ob_x(a0)
	bsr	bloodspeed2
	move.l	d0,ob_xvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_yvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_zvec(a0)
	move.l	a2,ob_shape(a0)
	move	d5,ob_frame(a0)
	move.l	#sparkslogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	bsr	rndw
	and	#15,d0
	add	#15,d0
	move	d0,ob_delay(a0)
	dbf	d5,.loop
.rts	rts

sparkslogic	subq	#1,ob_delay(a5)
	ble	killobject
	movem.l	ob_x(a5),d0-d2
	add.l	ob_xvec(a5),d0
	add.l	ob_yvec(a5),d1
	add.l	ob_zvec(a5),d2
	movem.l	d0-d2,ob_x(a5)
	rts

bloodymess	;throw random blood splots everywhere!
	; v31: blood particles restored; drawblood uses safe chunky byte writes.
	bsr	bloodspeed2
	add.l	ob_x(a5),d0
	move.l	d0,d2
	bsr	bloodspeed2
	add.l	ob_gutsy(a5),d0
	move.l	d0,d3
	bsr	bloodspeed2
	add.l	ob_z(a5),d0
	move.l	d0,d4
	;
.loop	addlast	blood
	beq.s	.done
	;
	movem.l	d2-d4,bl_x(a0)
	bsr	bloodspeed
	move.l	d0,bl_xvec(a0)
	bsr	bloodspeed
	move.l	d0,bl_yvec(a0)
	bsr	bloodspeed
	move.l	d0,bl_zvec(a0)
	move	ob_blood(a5),bl_color(a0)
	;
	dbf	d7,.loop
	;
.done	rts

bloodymess2	;throw random blood splots everywhere!
	; v31: blood particles restored; drawblood uses safe chunky byte writes.
	bsr	bloodspeed2
	add.l	ob_x(a5),d0
	move.l	d0,d2
	bsr	bloodspeed2
	add.l	ob_gutsy(a5),d0
	move.l	d0,d3
	bsr	bloodspeed2
	add.l	ob_z(a5),d0
	move.l	d0,d4
	;
.loop	addlast	blood
	beq.s	.done
	;
	movem.l	d2-d4,bl_x(a0)
	bsr	bloodspeed3
	move.l	d0,bl_xvec(a0)
	bsr	bloodspeed3
	move.l	d0,bl_yvec(a0)
	bsr	bloodspeed3
	move.l	d0,bl_zvec(a0)
	move	ob_blood(a5),bl_color(a0)
	;
	dbf	d7,.loop
	;
.done	rts

chunklogic	move	mode(pc),d0
	beq	chunklogic2
	;
	add.l	#$8000,ob_yvec(a5)
	move.l	ob_yvec(a5),d0
	add.l	ob_y(a5),d0
	blt	.skip
	;
	;OK...hit ground!
	;
	bsr	splat
	addlast	gore
	bne.s	.gok
	;
	move.l	gore(pc),a0
	killitem	gore
	addlast	gore
	beq	killobject
	;
.gok	move	ob_x(a5),go_x(a0)
	move	ob_z(a5),go_z(a0)
	move.l	ob_shape(a5),a1
	move	ob_frame(a5),d0
	add.l	12(a1,d0*4),a1
	move.l	a1,go_shape(a0)
	; c87b19: NASTY stores one fixed world-space pool definition.
	clr	go_pool_seed(a0)
	clr	go_pool_size(a0)
	clr	go_pool_wall(a0)
	clr	go_pool_wallx(a0)
	clr	go_pool_wallz(a0)
	clr	go_pool_walltx(a0)
	clr	go_pool_walltz(a0)
	cmp	#2,mode
	bne.w	.g2c87b19_no_pool
	bsr	rndw
	or	#1,d0
	move	d0,go_pool_seed(a0)
	and	#7,d0
	add	#18,d0		; fixed physical radius basis 18..25 world units
	move	d0,go_pool_size(a0)

	; Find a genuinely adjacent wall once, while the chunk becomes permanent
	; gore. checknewslow returns the closest wall segment inside ob_rad.
	move	ob_rad(a5),d3
	move	go_pool_size(a0),d0
	add	#10,d0
	move	d0,ob_rad(a5)
	move.l	a0,-(a7)
	move.l	a5,-(a7)
	move	ob_x(a5),d6
	move	ob_z(a5),d7
	bsr	checknewslow
	move.l	closewall(pc),a4
	move.l	(a7)+,a5
	move.l	(a7)+,a0
	move	d3,ob_rad(a5)
	tst	d1
	beq.w	.g2c87b19_no_pool

	; Project the fixed pool centre perpendicularly onto that wall plane.
	; zo_a/zo_b are the 1.15 wall normal; zo_na/zo_nb its tangent.
	move	zo_rx(a4),d0
	sub	go_x(a0),d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	go_z(a0),d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0			; signed perpendicular distance in world units
	move	d0,d2

	move	d2,d0
	muls	zo_a(a4),d0
	add.l	d0,d0
	swap	d0
	add	go_x(a0),d0
	move	d0,go_pool_wallx(a0)

	move	d2,d0
	muls	zo_b(a4),d0
	add.l	d0,d0
	swap	d0
	add	go_z(a0),d0
	move	d0,go_pool_wallz(a0)

	jsr	g2c87b72a_store_wall_stain_owner
.g2c87b19_no_pool
	;
	bra	killobject
	;
.skip	move.l	d0,ob_y(a5)
	bsr	checkvecs
	beq.s	.rts
	clr.l	ob_xvec(a5)
	clr.l	ob_zvec(a5)
.rts	rts

chunklogic2	add.l	#$8000,ob_yvec(a5)
	move.l	ob_yvec(a5),d0
	add.l	d0,ob_y(a5)
	blt.s	.ok
	;bsr	splat
	bra	killobject
.ok	movem.l	ob_xvec(a5),d0-d1
	add.l	d0,ob_x(a5)
	add.l	d1,ob_z(a5)
	rts

splat	move.l	splatsfx(pc),a0
	moveq	#32,d0
	moveq	#-1,d1
	bra	playsfx

blowterra	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#20,d1
	bsr	playsfx
	bra	blowquick

blowdragon	;same, but messier...
	;
	;loud!
	;
	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	move.l	robodiesfx(pc),a0
	moveq	#64,d0
	moveq	#50,d1
	bsr	playsfx
	;
	moveq	#63,d7
	bsr	bloodymess2
	;
	move.l	ob_chunks(a5),a4
	bsr	blowchunx
	bsr	blowchunx
	bsr	blowchunx
	bsr	blowchunx
	;
	move.l	#dragondead,ob_logic(a5)
	move.l	#rts,ob_render(a5)
	clr	ob_colltype(a5)
	clr	ob_collwith(a5)
	move	#127,ob_delay(a5)
	rts

dragondead	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	move	#3,finished
	;
.rts	rts

blowdeath	cmp.l	sucker(pc),a5
	bne.s	blowobject
	clr.l	sucker
	clr.l	sucking
	;
blowobject	move.l	diesfx(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr	playsfx
blowquick	;
	moveq	#31,d7
	bsr	bloodymess2
	;
	move.l	ob_chunks(a5),d0
	bne.s	.chok
	;
	moveq	#15,d7
	bsr	bloodymess2
	bra	killobject
	;
.chok	move.l	d0,a4
	bsr	blowchunx
	bra	killobject

blowchunx	; v30: body chunks enabled again; blood particle creation remains disabled.
	move	2(a4),d7
	subq	#1,d7
	;
.loop	addlast	objects
	beq	killobject
	movem.l	ob_x(a5),d0-d2
	move.l	#-64<<16,d1
	movem.l	d0-d2,ob_x(a0)
	;
	bsr	bloodspeed3
	move.l	d0,ob_xvec(a0)
	bsr	bloodspeed3
	sub.l	#$40000,d0
	move.l	d0,ob_yvec(a0)
	bsr	bloodspeed3
	move.l	d0,ob_zvec(a0)
	;
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	move.l	#chunklogic,ob_logic(a0)
	move.l	a4,ob_shape(a0)
	move.l	#drawshape_1sc,ob_render(a0)
	move	d7,ob_frame(a0)
	move	ob_scale(a5),ob_scale(a0)
	;
	move	an_maxw(a4),d0
	move	d0,ob_rad(a0)
	mulu	d0,d0
	move.l	d0,ob_radsq(a0)
	;
	dbf	d7,.loop
	rts

hurtdeath	;OK! death head hit!
	;
	;point at player, and start to suck his soul!
	;
	move.l	sucking(pc),d0
	bne.s	.rts
	;
	bsr	pickplayer
	cmp.l	#playerlogic,ob_logic(a0)
	bne.s	.rts
	;
	move.l	a0,sucking
	move.l	a5,sucker
	;
	move	ob_rot(a5),ob_oldrot(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#deathsuck,ob_logic(a5)
	move.l	#rts,ob_hit(a5)
	move	#64,ob_delay(a5)
	bra.s	deathsuck
	;
.rts	rts

deathsuck	;death head sucking out a players soul!
	;
	bsr	deathbounce
	bsr	deathanim
	subq	#1,ob_delay(a5)
	bgt.s	.more
	move	ob_oldrot(a5),ob_rot(a5)
	move.l	ob_oldlogic(a5),ob_logic(a5)
	move.l	#hurtdeath,ob_hit(a5)
	clr.l	sucker
	clr.l	sucking
	bra	rnddelay
	;
.more	move.l	sucking(pc),a0
	move.l	a0,a2
	bsr	calcangle	;point at player!
	move	d0,ob_rot(a5)
	;
	add	#128,d0
	and	#255,d0
	move.l	camrots(pc),a3
	lea	0(a3,d0*8),a3
	;
	move.l	a3,suckangle
	;
	;calc x/z vecs
	;
	moveq	#3,d7
	bsr	addsoul
	;
.rts	rts

sucker	dc.l	0
sucking	dc.l	0
suckangle	dc.l	0

addsoul	;d7 times!
	;
	addlast	blood
	beq	.rts
	;
	move	2(a3),d2
	ext.l	d2
	lsl.l	#5,d2
	neg.l	d2
	move	6(a3),d3
	ext.l	d3
	lsl.l	#5,d3
	;
	move.l	d2,bl_xvec(a0)
	move.l	a5,bl_yvec(a0)
	move.l	d3,bl_zvec(a0)
	;
	swap	d2
	swap	d3
	add	d2,d2
	add	d3,d3
	add	ob_x(a2),d2
	add	ob_z(a2),d3
	;
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	d2,d0
	move	d0,bl_x(a0)
	;
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	#110,d0
	move	d0,bl_y(a0)	;>0= funny blood!
	;
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	d3,d0
	move	d0,bl_z(a0)
	;
	bsr	rndw
	and	#1,d0
	move	soulcols(pc,d0*2),bl_color(a0)
	;
	dbf	d7,addsoul
	;
.rts	rts

soulcols	dc	$0ff,$0f0

hurtghoul	moveq	#31,d7
	bsr	bloodymess
	rts

hurtterra	move.l	a0,-(a7)
	move.l	shootsfx2(pc),a0
	moveq	#64,d0
	moveq	#2,d1
	bsr	playsfx
	move.l	(a7)+,a0
	bra.s	hurtobject

hurtngrunt	move.l	a0,-(a7)
	bsr	rndw
	and	#3,d0
	cmp	lastgrunt(pc),d0
	bne.s	.new
	addq	#1,d0
	and	#3,d0
.new	move	d0,lastgrunt
	lea	grunttable(pc),a0
	move.l	0(a0,d0*4),a0
	move.l	(a0),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr	playsfx
	move.l	(a7)+,a0
	;
hurtobject	move	ob_colltype(a0),d0
	and	#24,d0
	bne.s	.rts
	;
	moveq	#23,d7
	bsr	bloodymess
	move	ob_hurtpause(a5),ob_hurtwait(a5)
	beq	.rts
	;
	move	#4,ob_frame(a5)
	move.l	ob_logic(a5),ob_oldlogic2(a5)
	move.l	ob_hit(a5),ob_oldhit(a5)
	move.l	#pauselogic2,ob_logic(a5)
	move.l	#rts,ob_hit(a5)
	;
.rts	rts

lizhurt	move.l	a0,-(a7)
	move.l	lizhitsfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr	playsfx
	move.l	(a7)+,a0
	bra	hurtobject

trollhurt	move.l	a0,-(a7)
	move.l	trollhitsfx(pc),a0
	moveq	#64,d0
	moveq	#1,d1
	bsr	playsfx
	move.l	(a7)+,a0
	bra	hurtobject

pauselogic2	subq	#1,ob_hurtwait(a5)
	bgt.s	.rts
	clr	ob_frame(a5)
	move.l	ob_oldlogic2(a5),ob_logic(a5)
	move.l	ob_oldhit(a5),ob_hit(a5)
.rts	rts

pauselogic	subq	#1,ob_delay(a5)
	bgt.s	.skip
	;
	bsr	rnddelay
	move.l	ob_oldlogic(a5),ob_logic(a5)
	;
	;if in front of player, continue on old course...
	;
	bsr	pickcalc
	;
	move	ob_rot(a0),d1
	and	#255,d1
	sub	d0,d1
	bpl.s	.pl
	neg	d1
.pl	cmp	#64,d1
	bcs.s	.skip
	cmp	#192,d1
	bcc.s	.skip
	;
.useold	move	ob_oldrot(a5),ob_rot(a5)
	bsr	calcvecs
	;
.skip	rts

g2apply_player_muzzle_origin
	movem.l	d0-d2/a1,-(a7)
	move.l	a5,d1
	move.l	player1(pc),d0
	cmp.l	d1,d0
	beq.s	.g2amo_do
	move.l	player2(pc),d0
	cmp.l	d1,d0
	bne.s	.g2amo_done
.g2amo_do
	; v68: ZGloom muzzle-origin approximation.  Spawn player bullets
	; slightly in front of the player so the projectile appears to leave
	; the weapon instead of emerging from behind the statusbar.
	move	ob_rot(a5),d0
	and	#255,d0
	move.l	camrots(pc),a1
	lea	0(a1,d0*8),a1
	move	#28,d0		;v120: restore original muzzle-origin base offset
	move	d0,d2
	muls	2(a1),d0
	add.l	d0,d0
	neg.l	d0
	add.l	d0,ob_x(a0)
	muls	6(a1),d2
	add.l	d2,d2
	add.l	d2,ob_z(a0)
	; v80: ZGloom keeps the shot y unchanged here.  The projectile height
	; already comes from ob_firey(a5) in shoot above; adding another negative
	; offset made the first projectile appear too high and huge on screen.
.g2amo_done
	movem.l	(a7)+,d0-d2/a1
	rts

g2player_bullet_visual_prestep
	movem.l	d0-d1,-(a7)
	move.l	a5,d0
	cmp.l	player1,d0
	beq.s	.do
	cmp.l	player2,d0
	bne.s	.done
.do	movem.l	ob_xvec(a0),d0-d1
	add.l	d0,ob_x(a0)
	add.l	d1,ob_z(a0)
	add.l	d0,ob_x(a0)
	add.l	d1,ob_z(a0)
	add.l	d0,ob_x(a0)
	add.l	d1,ob_z(a0)
.done	movem.l	(a7)+,d0-d1
	rts

shoot	;
	;fire off a bullet...
	;
	;d2 : colltype
	;d3 : collwith
	;d4 : hitpoints
	;d5 : damage
	;d6 : speed
	;a2=bullet shape
	;a3=sparks shape
	;
	addfirst	objects
	beq	.rts
	;
	move	ob_bouncecnt(a5),ob_bouncecnt(a0)
	move	ob_x(a5),ob_x(a0)
	move	ob_y(a5),d0
	add	ob_firey(a5),d0
	move	d0,ob_y(a0)
	move	ob_z(a5),ob_z(a0)
	bsr	g2apply_player_muzzle_origin
	move.l	#firelogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	move.l	#rts,ob_hit(a0)
	move.l	#killobject,ob_die(a0)
	move	d2,ob_colltype(a0)
	move	d3,ob_collwith(a0)
	move	d4,ob_hitpoints(a0)
	move	d5,ob_damage(a0)
	move	d6,ob_movspeed(a0)
	move.l	a2,ob_shape(a0)
	clr	ob_invisible(a0)
	clr	ob_frame(a0)
	move.l	a3,ob_chunks(a0)
	;
	move	ob_rot(a5),d0
	and	#255,d0
	move.l	camrots(pc),a1
	lea	0(a1,d0*8),a1
	;
	move	2(a1),d0
	move	d0,ob_nxvec(a0)
	neg	d0
	muls	d6,d0
	add.l	d0,d0
	move	6(a1),d1
	move	d1,ob_nzvec(a0)
	muls	d6,d1
	add.l	d1,d1
	;
	movem.l	d0-d1,ob_xvec(a0)
	; v120: player bullets need a visual pre-step after the real flight
	; vector is known.  The old #28/#34/#50 base offset alone was too
	; small visually for the big weapon-4/5 projectile sprites.
	bsr	g2player_bullet_visual_prestep
	;
	move	#32,ob_rad(a0)
	move.l	#32*32,ob_radsq(a0)
	;
.rts	rts

pickcalc	;pick a player and calculate angle to player!
	;
	bsr	pickplayer
	bsr	calcangle
	tst	ob_invisible(a0)
	beq.s	.rts
	move	d0,-(a7)
	bsr	rndw
	and	#63,d0
	sub	#32,d0
	add	(a7)+,d0
	and	#255,d0
.rts	rts

fire1	bsr	pickcalc
	;
	;random noise for inaccuracy!
	;
	move	d0,-(a7)
	bsr	rndw
	and	#31,d0
	sub	#16,d0
	add	(a7)+,d0
	and	#255,d0
	;
	move	d0,ob_rot(a5)
	bsr	calcvecs
	move	#7,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#pauselogic,ob_logic(a5)
	clr.l	ob_frame(a5)
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#1,d5	;damage
	moveq	#20,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet1,a2
	lea	sparks1,a3
	;
	bsr	shoot
	;
	rts

pickplayer	;pick nearest player
	;
	move.l	player1(pc),a0
	move	gametype(pc),d0
	beq.s	.rts
	move.l	player2(pc),a1
	move	linked(pc),d0
	bpl.s	.nosw
	exg	a0,a1
.nosw	;
	tst	ob_hitpoints(a0)
	beq	.sw
	tst	ob_hitpoints(a1)
	beq.s	.rts
	;
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0	;dist to player a0
	;
	move	ob_x(a5),d1
	sub	ob_x(a1),d1
	muls	d1,d1
	move	ob_z(a5),d2
	sub	ob_z(a1),d2
	muls	d2,d2
	add.l	d2,d1	;dist to player a1
	;
	cmp.l	d1,d0
	bcs.s	.rts
	;
.sw	move.l	a1,a0
	;
.rts	rts

checkcoll	;check for collision between a5, and a0
	;
	move	ob_rad(a5),d1
	move	ob_rad(a0),d2
	add	d1,d2	;r sum
	;
	move	ob_x(a0),d3
	sub	ob_x(a5),d3
	bpl.s	.xpl
	neg	d3
.xpl	cmp	d2,d3
	bcc.s	.no
	;
	move	ob_z(a0),d4
	sub	ob_z(a5),d4
	bpl.s	.ypl
	neg	d4
.ypl	cmp	d2,d4
	bcc.s	.no
	;
	mulu	d2,d2
	mulu	d3,d3
	mulu	d4,d4
	add.l	d4,d3
	cmp.l	d2,d3
	bcc.s	.no
	;
	moveq	#-1,d0
	rts
	;
.no	moveq	#0,d0
	rts

baldycharge	;
	;baldy charging at player!
	;
	bsr	checkvecs
	beq	baldy_skip
	;
baldy_tonorm	move.l	ob_movspeed(a5),d0
	lsr.l	#2,d0
	move.l	d0,ob_movspeed(a5)
	;
	move.l	ob_framespeed(a5),d0
	lsr.l	#2,d0
	move.l	d0,ob_framespeed(a5)
	;
	move.l	ob_oldlogic(a5),ob_logic(a5)
	bsr	rnddelay
	;
	bra	monsterfix
	;
baldy_skip	;close to player? start throwing punches around!
	;
	bsr	pickcalc
	;
	sub	ob_rot(a5),d0
	cmp	#32,d0
	bgt	baldy_tonorm
	cmp	#-32,d0
	blt	baldy_tonorm
	;
	move.l	a0,ob_washit(a5)
	bsr	checkcoll
	beq	monsternew	;no collisions!
	;
	;go into punch mode!
	;
	move.l	#baldypunch,ob_logic(a5)
	move	ob_punchrate(a5),ob_delay(a5)
	clr.l	ob_frame(a5)
	rts

baldypunch	;
	bsr	pickplayer
	bsr	checkcoll
	bne.s	.doit
	;
	clr.l	ob_frame(a5)
	bra	baldy_tonorm
	;
.doit	subq	#1,ob_delay(a5)
	ble.s	.punch
	rts
.punch	move	ob_punchrate(a5),ob_delay(a5)
	moveq	#0,d0	;stand frame
	cmp	ob_frame(a5),d0
	bne	.skip
	;
	clr.l	ob_washit(a5)	;punch!
	bsr	calcangle
	move	d0,ob_rot(a5)
	moveq	#5,d0
.skip	move	d0,ob_frame(a5)
	rts

calcbangle	bsr	calcangle
	tst	ob_invisible(a0)
	beq.s	.notinv
	;
	;invisible, add some randomeness!
	;
	move	d0,-(a7)
	bsr	rndw
	and	#127,d0
	sub	#64,d0
	add	(a7)+,d0
	and	#255,d0
	;
.notinv	move	d0,ob_rot(a5)
	rts

trolllogic	move	ob_rad(a5),d0
	mulu	#$a000,d0
	swap	d0
	move	d0,ob_rad(a5)
	mulu	d0,d0
	move.l	d0,ob_radsq(a5)
	move.l	#trolllogic2,ob_logic(a5)
	;
trolllogic2	subq	#1,ob_delay(a5)
	bgt	monstermove	;charge?
	;
	bsr	pickcalc	;pic player in a0!
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#320*320,d0
	bcc	bl2
	;
	move.l	trollsfx(pc),a0
	moveq	#64,d0
	moveq	#5,d1
	bsr	playsfx
	;
	bra	bl2

lizardlogic	;
	subq	#1,ob_delay(a5)
	bgt	monstermove	;charge?
	;
	bsr	pickcalc	;pic player in a0!
	move	ob_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	ob_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#256*256,d0
	bcc.s	bl2
	;
	move.l	lizsfx(pc),a0
	moveq	#32,d0
	moveq	#5,d1
	bsr	playsfx
	;
	bra	bl2

baldylogic	;
	;OK, what can baldy do...
	;
	;how about, walk around similar to the marine, but randomly 
	;charge at you?
	;
	;then, if he's close enough, he throws a punch!
	;
	subq	#1,ob_delay(a5)
	bgt	monstermove	;charge?
	;
bl2	bsr	pickcalc
	move	d0,ob_rot(a5)
	;
	move.l	ob_movspeed(a5),d0
	lsl.l	#2,d0
	move.l	d0,ob_movspeed(a5)
	move.l	ob_framespeed(a5),d0
	lsl.l	#2,d0
	move.l	d0,ob_framespeed(a5)
	;
	bsr	calcvecs
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#baldycharge,ob_logic(a5)
	;
	rts

terralogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	ble	.fire
	;
	move	ob_delay(a5),d0
	and	#31,d0
	bne	monstermove
	;
	move.l	robotsfx(pc),a0
	moveq	#64,d0
	moveq	#10,d1
	bsr	playsfx
	bra	monstermove
	;
.fire	;OK, terra goes apeshit! stand there firing off at player!
	;use punchrate as firedelay!
	;
	clr	ob_frame(a5)
	move	#1,ob_delay(a5)
	move	ob_firecnt(a5),ob_delay2(a5)
	move.l	#terralogic2,ob_logic(a5)
	rts

terralogic2	;
	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	move	ob_firerate(a5),ob_delay(a5)
	;
	;OK, to to face player and fire away!
	;
	bsr	pickcalc
	move	d0,ob_rot(a5)
	bsr	calcvecs
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#15,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet4,a2
	lea	sparks4,a3
	;
	bsr	shoot
	;
	move.l	shootsfx3(pc),a0
	moveq	#32,d0
	moveq	#5,d1
	bsr	playsfx
	;
	subq	#1,ob_delay2(a5)
	bgt.s	.rts
	;
	bsr	rnddelay
	move.l	#terralogic,ob_logic(a5)
	;
.rts	rts

ghoullogic	;
	addq	#8,ob_bounce(a5)
	move	ob_bounce(a5),d0
	move.l	camrots(pc),a0
	and	#255,d0
	move	0(a0,d0*8),d0
	ext.l	d0
	lsl.l	#5,d0	;+/- 32
	swap	d0
	add	#-32,d0
	move	d0,ob_y(a5)
	;
	bsr	pickcalc
	move	d0,ob_rot(a5)
	;
	subq	#1,ob_delay(a5)
	bgt.s	.skip
	;
	move	#1,ob_frame(a5)
	move.l	#$2000,ob_framespeed(a5)
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#20,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet2,a2
	lea	sparks2,a3
	;
	bsr	shoot
	bsr	rnddelay
	;
.skip	;OK, ghoul moves around ignoring walls!
	;
	;he's pointed at player...how about randomly selected to make 
	;this his new movement vector?
	;
	bsr	rndw
	move	ob_movspeed(a5),d1
	lsl	#8,d1
	cmp	d1,d0
	bcc.s	.no
	;
	bsr	calcvecs
	;
	move.l	ghoulsfx(pc),a0
	moveq	#32,d0
	moveq	#-5,d1
	bsr	playsfx
	;
.no	movem.l	ob_xvec(a5),d0-d1
	add.l	d0,ob_x(a5)
	add.l	d1,ob_z(a5)
	;
	move.l	ob_framespeed(a5),d0
	beq.s	.rts
	add.l	d0,ob_frame(a5)
	cmp	#3,ob_frame(a5)
	bcs.s	.rts
	;
	clr	ob_frame(a5)
	clr.l	ob_framespeed(a5)
	;
.rts	rts

demonpause	move	ob_delay(a5),d0
	move	d0,d1
	and	#4,d0
	sne	d0
	ext	d0
	and	#5,d0	;0 or 5
	move	d0,ob_frame(a5)
	;
	and	#7,d1	;do a fire?
	cmp	#7,d1
	bne.s	.nofire
	;
	move	ob_delay(a5),d0
	lsr	#3,d0
	mulu	#18,d0
	lea	wtable(pc),a0
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	movem	0(a0,d0),d4-d6	;hits,dam,speed
	mulu	#$c000,d5
	swap	d5	;3/4 damage!
	moveq	#0,d7	;acc
	movem.l	6(a0,d0),a2-a3	;bullets/sparks
	move.l	14(a0,d0),-(a7)	;sfx!
	;
	bsr	shoot
	;
	move.l	(a7)+,a0
	move.l	(a0),a0
	moveq	#32,d0
	moveq	#0,d1
	bsr	playsfx
	;
.nofire	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	bsr	rnddelay
	move.l	ob_oldlogic(a5),ob_logic(a5)
	;
.rts	rts

demonlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	bgt	monstermove
	;
	bsr	pickcalc
	;
	move	d0,ob_rot(a5)
	bsr	calcvecs
	move	#5<<3-1,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#demonpause,ob_logic(a5)
	;
	rts

phantomlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	subq	#1,ob_delay(a5)
	bgt	monstermove
	;
	bsr	pickcalc
	;
	move	d0,ob_rot(a5)
	bsr	calcvecs
	move	#7,ob_delay(a5)
	move.l	ob_logic(a5),ob_oldlogic(a5)
	move.l	#pauselogic,ob_logic(a5)
	move	#5,ob_frame(a5)
	;
	moveq	#4,d2	;colltype
	moveq	#0,d3	;collwith
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#20,d6	;speed
	moveq	#0,d7	;acceleration!
	lea	bullet3,a2
	lea	sparks3,a3
	;
	bra	shoot

deathbounce	addq	#4,ob_bounce(a5)
	move	ob_bounce(a5),d0
	move.l	camrots(pc),a0
	and	#255,d0
	move	0(a0,d0*8),d0
	ext.l	d0
	lsl.l	#5,d0	;+/- 64
	swap	d0
	add	#-48,d0
	move	d0,ob_y(a5)
	rts

deathheadlogic	;
	;cruises around rotating at speed ob_delay
	;
	bsr	deathbounce
	;
	bsr	checkvecs
	bne.s	.hit
	;
	;charge player?
	;
	bsr	pickcalc	;find angle to player
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d0,d1	;am I near?
	bpl.s	.ansk
	neg	d1
.ansk	cmp	#16,d1
	bcc.s	.notnear
	;
	;OK! chargaroony!
	;
	move	d0,ob_rot(a5)
	move.l	#deathcharge,ob_logic(a5)
	bra	calcvecs
.hit	add	#128,ob_rot(a5)
	bsr	rnddelay
.notnear	move	ob_delay(a5),d0
	add	d0,ob_rot(a5)
	bsr	calcvecs
	rts

deathanim	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	cmp.l	#$8000,ob_frame(a5)
	blt.s	.fix
	cmp.l	#$28000,ob_frame(a5)
	blt.s	.fok
.fix	neg.l	d0
	add.l	d0,ob_frame(a5)
	move.l	d0,ob_framespeed(a5)
	;
.fok	rts

deathcharge	bsr	deathbounce
	bsr	deathanim
	;
	bsr	pickcalc
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d1,d0	;am I near?
	bpl.s	.ansk
	neg	d0
.ansk	cmp	#128,d0
	bcc.s	.hit
	bsr	checkvecs
	bne.s	.hit2
	rts
.hit2	add	#128,ob_rot(a5)
.hit	move.l	#deathheadlogic,ob_logic(a5)
	move.l	#$8000,ob_frame(a5)
	bra	rnddelay

monsterlogic	;
	move	ob_rot(a5),ob_oldrot(a5)
	;monster cruising around minding his own business...
	;
	subq	#1,ob_delay(a5)
	ble	fire1
	;
monstermove	bsr	checkvecs
	beq.s	monsternew
	;
	;OK, try 90/-90 degrees...
	;
monsterfix	bsr	rndw
	moveq	#64,d1
	tst	d0
	bpl.s	.umk
	moveq	#-64,d1
.umk	add	d1,ob_rot(a5)
	bsr	calcvecs
	bsr	checkvecs
	beq.s	monsternew
	;
	add	#128,ob_rot(a5)
	bsr	calcvecs
	bsr	checkvecs
	beq.s	monsternew
	;
	move	ob_oldrot(a5),d0
	add	#128,d0
	move	d0,ob_rot(a5)
	;
	bsr	calcvecs
	bsr	checkvecs
monsternew	;
	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

dragonfire	;dragon fires at you!
	;
	;d2 : colltype
	;d3 : collwith
	;d4 : hitpoints
	;d5 : damage
	;d6 : speed
	;a2=bullet shape
	;a3=sparks shape
	;
	subq	#1,ob_delay(a5)
	bpl	.rts
	move	ob_delay(a5),d0
	cmp	#-16*8,d0
	bgt.s	.try
	move	#47,ob_delay(a5)
	rts
.try	and	#7,d0
	bne	.rts
	;
.fire	moveq	#0,d2	;colltype
	moveq	#24+3,d3	;collwith - p1/p2/bullets
	moveq	#1,d4	;hitpoints
	moveq	#3,d5	;damage
	moveq	#15,d6	;speed
	lea	bullet5,a2
	lea	sparks5,a3
	;
	addlast	objects
	beq	.rts
	;
	move	ob_bouncecnt(a5),ob_bouncecnt(a0)
	move	ob_x(a5),ob_x(a0)
	move	ob_y(a5),d0
	add	ob_firey(a5),d0
	move	d0,ob_y(a0)
	move	ob_z(a5),ob_z(a0)
	move.l	#homeinlogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	move.l	#makesparksq,ob_hit(a0)
	move.l	#blowdb,ob_die(a0)
	move	d2,ob_colltype(a0)
	move	d3,ob_collwith(a0)
	move	d4,ob_hitpoints(a0)
	move	d5,ob_damage(a0)
	move	d6,ob_movspeed(a0)
	move.l	a2,ob_shape(a0)
	clr	ob_invisible(a0)
	clr	ob_frame(a0)
	move.l	a3,ob_chunks(a0)
	;
	move	ob_rot(a5),d0
	and	#255,d0
	move.l	camrots(pc),a1
	lea	0(a1,d0*8),a1
	;
	move	2(a1),d0
	move	d0,ob_nxvec(a0)
	neg	d0
	muls	d6,d0
	add.l	d0,d0
	move	6(a1),d1
	move	d1,ob_nzvec(a0)
	muls	d6,d1
	add.l	d1,d1
	;
	movem.l	d0-d1,ob_xvec(a0)
	;
	move	#32,ob_rad(a0)
	move.l	#32*32,ob_radsq(a0)
	;
.rts	rts

blowdb	bsr	makesparksq
	bra	killobject

homeinlogic	bsr	checkvecs
	bne.s	blowdb
	bsr	pickcalc	;find angle to player!
	move.l	camrots(pc),a0
	lea	0(a0,d0*8),a0
	move	2(a0),d4	;x acc.
	neg	d4
	ext.l	d4
	lsl.l	#2,d4
	move	6(a0),d5	;z acc.
	ext.l	d5
	lsl.l	#2,d5
	;
	add.l	ob_xvec(a5),d4
	move.l	d4,d0
	bpl.s	.pl1
	neg.l	d0
.pl1	cmp.l	#$200000,d0	;max speed
	bcc.s	.sk1
	move.l	d4,ob_xvec(a5)
	;
.sk1	add.l	ob_zvec(a5),d5
	move.l	d5,d0
	bpl.s	.pl2
	neg.l	d0
.pl2	cmp.l	#$200000,d0
	bcc.s	.sk2
	move.l	d5,ob_zvec(a5)
.sk2	;
	bra	putfire

dragonanim	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

getobrot	move	ob_rotspeed(a5),d0
	bne.s	.addr
	;
	;OK, randomly left/rite!
	;
	bsr	rndw
	and	#1,d0
	bne.s	.addr2
	moveq	#-1,d0
	;
.addr2	lsl	#2,d0
	move	d0,ob_rotspeed(a5)
	;
.addr	rts

dragonlogic	;OK! end of game baddy!
	;
	;how about cruising around in a circle a-la
	;deathhead!
	;
	bsr	dragonanim
	bsr	dragonfire
	bsr	checkvecs
	beq.s	.nohit
	;
	;OK, dragon has hit a wall...rot him around till he's clear!
	;
	bsr	getobrot
	lsl	#2,d0
	add	d0,ob_rot(a5)
	bra	calcvecs
.nohit	;
	bsr	pickcalc
	move	ob_rot(a5),d1
	and	#255,d1
	sub	d0,d1	;am I near?
	bpl.s	.ansk
	neg	d1
.ansk	moveq	#6,d0
	tst	ob_rotspeed(a5)
	bne.s	.sh
	moveq	#24,d0
.sh	cmp	d0,d1
	bcs.s	.near
	;
	;not pointed at player!
	bsr	getobrot
	add	d0,ob_rot(a5)
	bra	calcvecs
	;
.near	tst	ob_rotspeed(a5)
	beq.s	.near2
	clr	ob_rotspeed(a5)	;towards player!
	;
	move.l	dragonsfx(pc),a0
	moveq	#64,d0
	moveq	#20,d1
	bsr	playsfx
	;
.near2	rts

weaponlogic	;
	move.l	camrots(pc),a0
	;
	addq	#8,ob_movspeed(a5)
	move	ob_movspeed(a5),d0
	and	#127,d0
	move	2(a0,d0*8),d0
	asr	#8,d0
	; c86zdf: keep jumping weapon upgrades about 20px above the floor.
	; Positive/near-zero Y lets the pickup dip too low; cap the lowest point.
	cmp	#-20,d0
	ble.s	.g2c86zdf_weapon_y_ok
	move	#-20,d0
.g2c86zdf_weapon_y_ok
	move	d0,ob_y(a5)
	;
	move.l	ob_framespeed(a5),d0
	add.l	d0,ob_frame(a5)
	move	ob_frame(a5),d0
	move.l	ob_shape(a5),a0
	cmp	2(a0),d0
	bcs.s	.skip
	clr	ob_frame(a5)
.skip	;
	subq	#1,ob_delay(a5)
	bgt	.rts
	bsr	rnddelay
	;
	addlast	objects
	beq.s	.rts
	;
	movem.l	ob_x(a5),d2-d4
	movem.l	d2-d4,ob_x(a0)
	bsr	bloodspeed2
	move.l	d0,ob_xvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_yvec(a0)
	bsr	bloodspeed2
	move.l	d0,ob_zvec(a0)
	move.l	ob_chunks(a5),a2
	move.l	a2,ob_shape(a0)
	move	2(a2),d0
	bsr	rndn
	move	d0,ob_frame(a0)
	move.l	#sparkslogic,ob_logic(a0)
	move.l	#drawshape_1,ob_render(a0)
	clr	ob_invisible(a0)
	clr	ob_colltype(a0)
	clr	ob_collwith(a0)
	bsr	rndw
	and	#15,d0
	add	#15,d0
	move	d0,ob_delay(a0)
.rts	rts

calcvecs	move	ob_rot(a5),d0
	;
	and	#255,d0
	move.l	camrots(pc),a0
	lea	0(a0,d0*8),a0
	;
	move	ob_movspeed(a5),d4
	move	d4,d5
	muls	2(a0),d4
	add.l	d4,d4
	neg.l	d4
	move.l	d4,ob_xvec(a5)
	muls	6(a0),d5
	add.l	d5,d5
	move.l	d5,ob_zvec(a5)
	rts

checkvecs	movem.l	ob_xvec(a5),d6-d7
	add.l	ob_x(a5),d6
	add.l	ob_z(a5),d7
	bsr	checknewslow	;ok to stand here?
	beq.s	.ok
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bsr	checknewslow
	bne.s	.fix
	moveq	#-1,d1	;use old pos, and report hit!
	rts
	;
.fix	bsr	adjustposq	;fixup!
	moveq	#-1,d1
	;
.ok	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	tst	d1
	rts

playerdead	; v102: dead-on-ground state is inert: no rotation/mouse drift.
	clr.l	ob_rotspeed(a5)
	;
	subq	#1,ob_delay(a5)
	bgt.s	.rts
	;
	cmp	#2,gametype
	bne.s	.notcom
	;
	;combat game!
	;
	move	#4,finished2
	move	#1,ob_pixsizeadd(a5)
	move.l	#rts,ob_logic(a5)
	bsr	getother
	move	#1,ob_pixsizeadd(a0)
.rts	rts
	;
.notcom	;
	tst	ob_lives(a5)
	beq.s	.dead
	move.l	#waitrestart,ob_logic(a5)
	rts
	;
.dead	move.l	#rts,ob_logic(a5)
	tst	gametype
	bne.s	.not1p
.allover	move	#2,finished
	rts
	;
.not1p	;OK, I'm all out of lives...what about other guy...
	bsr	getother
	tst	ob_lives(a0)
	beq.s	.allover
	rts

waitrestart	bsr	getcntrl
	;
	bsr	checkfireb
	beq.s	.rts
	;
	move	ob_weapon(a5),-(a7)
	;
	lea	p1x(pc),a0
	lea	player1_+4,a1
	cmp.l	player1,a5
	beq.s	.got
	lea	p2x(pc),a0
	lea	player2_+4,a1
.got	lea	ob_info(a5),a2
	move	#(objinfof-objinfo-4)>>1-1,d0
.loop	move	(a1)+,(a2)+
	dbf	d0,.loop
	;
	clr.l	ob_colltype(a5)
	move	#75,ob_delay(a5)
	move.l	#playerlogic0,ob_logic(a5)
	;
	move	(a0)+,ob_x(a5)
	move	(a0)+,ob_z(a5)
	move	(a0)+,ob_rot(a5)
	;
	move	(a7)+,ob_weapon(a5)
	clr	ob_bounce(a5)
	;
	move.l	ob_shape(a5),a0
	move.l	4(a0),ob_chunks(a5)
	move.l	(a0),a0
	move.l	a0,ob_shape(a5)
	;
	bsr	resetplayer
	move	#-1,ob_update(a5)
	st	ob_lastbut(a5)
	;
.rts	rts

playerdeath	bsr	getcntrl
	;
	addq	#4,ob_rot(a5)
	addq	#4,ob_eyey(a5)
	cmp	#-32,ob_eyey(a5)
	blt	.rts
	;
	move	#-32,ob_eyey(a5)
	move.l	#playerdead,ob_logic(a5)
	move	#63,ob_delay(a5)
	;
	cmp	#2,gametype
	bne.s	.notcom
	;
	;death in combat game!
	;
	bsr	getother
	;
.win	move.l	a5,-(a7)
	;
	move.l	a0,a5
	clr	ob_collwith(a5)
	clr	ob_colltype(a5)
	bsr	message
	dc.b	'winner!',0
	even
	;
	move.l	(a7)+,a5
	subq	#1,ob_lives(a5)
	move	#-1,ob_update(a5) ;refresh 'lives'
	bsr	message
	dc.b	'loser!',0
	even
	;
	rts
.notcom	;
	subq	#1,ob_lives(a5)
	move	#-1,ob_update(a5)
	move	gametype(pc),d0
	beq.s	.one
	;
	;2 player game!
	;
	bsr	getother
	tst	ob_lives(a5)
	beq.s	.hmm
	move	ob_lives(a5),ob_lives(a0)
	move	#-1,ob_update(a0)
	rts
.hmm	tst	ob_lives(a0)
	beq.s	.go2
	rts
.one	tst	ob_lives(a5)
	beq.s	.go
	rts
.go2	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	message
	dc.b	'game over',0
	even
	move.l	(a7)+,a5
.go	bsr	message
	dc.b	'game over',0
	even
.rts	rts

getother	;get other player from a5!
	;
	move.l	player1(pc),a0
	cmp.l	a0,a5
	bne.s	.rts
	move.l	player2(pc),a0
.rts	rts

redpal	;move.l	#palettesr,ob_palette(a5)
	move	#2,ob_paltimer(a5)
	rts

playerhit	tst	ob_damage(a0)
	beq.s	.rts
	tst	trainer_invincible	;v115: unlimited health cancels visual hit/HUD flicker
	beq.s	.normal
	move	#25,ob_hitpoints(a5)
	rts
.normal	st	ob_update(a5)
	bsr	redpal
.rts	rts

playerdie	;v115: unlimited health also blocks lethal damage without HUD flash
	tst	trainer_invincible
	beq.s	.die
	move	#25,ob_hitpoints(a5)
	rts
.die	bsr	redpal
	clr	ob_hitpoints(a5)
	st	ob_update(a5)
	move.l	#playerdeath,ob_logic(a5)
	clr	ob_colltype(a5)
	clr	ob_collwith(a5)
	rts

inchealth	;inc health of a5
	;
	addq	#5,ob_hitpoints(a5)
	cmp	#25,ob_hitpoints(a5)
	ble.s	.skip
	move	#25,ob_hitpoints(a5)
.skip	st	ob_update(a5)
	bsr	message
	dc.b	'health bonus!',0
	even
	rts

healthgot	bsr	playtsfx
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	inchealth
	move.l	(a7)+,a5
	bra	killobject

playtsfx	move.l	a0,-(a7)
	move.l	tokensfx(pc),a0
	moveq	#64,d0
	moveq	#0,d1
	bsr	playsfx
	move.l	(a7)+,a0
	rts

weapongot	bsr	playtsfx
	move.l	a5,-(a7)
	move	ob_weapon(a5),d0	;weapon #!
	move.l	a0,a5
	bsr	weapond0
	move.l	(a7)+,a5
	bra	killobject

weapond0	tst	trainer_weapon	;v115: forced trainer weapon/upgrade must not flicker on pickups
	bne	.trainer_skip
	tst	trainer_boost
	bne	.trainer_skip
	st	ob_update(a5)
	cmp	ob_weapon(a5),d0
	bne	.new
	;
	subq.b	#1,ob_reload(a5)
	beq.s	.skip
	cmp.b	#1,ob_reload(a5)
	bne.s	.notfull
	bsr	message
	dc.b	'weapon boosted to full!',0
	even
	rts
	;
.notfull	bsr	message
	dc.b	'weapon boost!',0
	even
	rts
	;
.skip	addq.b	#1,ob_reload(a5)
	add	#250,ob_mega(a5)
	cmp	#ok,ob_mega(a5)
	bcs.s	.mwb
	;
	bsr	message
	dc.b	'ultra mega overkill!!!',0
	even
	rts
	;
.mwb	bsr	message
	dc.b	'mega weapon boost!',0
	even
	rts
	;
.new	move	d0,ob_weapon(a5)
	move.b	#ireload,ob_reload(a5)
	st	ob_update(a5)
	bsr	message
	dc.b	'new weapon!',0
	even
	rts
.trainer_skip	rts

invisigot	bsr	playtsfx
	move.l	a5,-(a7)
	move.l	a0,a5
	add	#1500,ob_invisible(a5)
	bsr	message
	dc.b	'invisibility!',0
	even
	move.l	(a7)+,a5
	bra	killobject

invincgot	bsr	playtsfx
	tst	ob_hyper(a0)
	bne.s	.rts
	move.l	a5,-(a7)
	move.l	a0,a5
	;
	move	#-$200,ob_hyper(a5)
	bsr	message
	dc.b	'hyper!',0
	even
	;
	move.l	(a7)+,a5
	bra	killobject
	;
.rts	rts

bouncylogic	addq	#1,ob_delay(a5)
	move	ob_delay(a5),d0
	lsr	#1,d0
	and	#3,d0
	move	.bnc(pc,d0*2),ob_frame(a5)
	rts
.bnc	dc	3,4,3,5

bouncygot	bsr	playtsfx
	cmp	#3,ob_bouncecnt(a0)
	bcc.s	.rts
	addq	#1,ob_bouncecnt(a0)
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	message
	dc.b	'bouncy bullets!',0
	even
	move.l	(a7)+,a5
	bra	killobject
.rts	rts

thermogot	bsr	playtsfx
	add	#1500,ob_thermo(a0)
	move.l	a5,-(a7)
	move.l	a0,a5
	bsr	message
	dc.b	'got the thermo glasses!',0
	even
	move.l	(a7)+,a5
	bra	killobject

maxsize	equ	$280

playertimers	tst	ob_mega(a5)
	beq.s	.nomega
	subq	#1,ob_mega(a5)
	bne.s	.nomout
	bsr	message
	dc.b	'mega weapon out...',0
	even
.nomout	move	ob_mega(a5),d0
	and	#31,d0
	bne.s	.nomega
	st	ob_update(a5)
	;
.nomega	tst	ob_thermo(a5)
	beq.s	.noth
	subq	#1,ob_thermo(a5)
	bne.s	.noth
	bsr	message
	dc.b	'thermo glasses out...',0
	even
	;
.noth	tst	ob_messtimer(a5)
	ble.s	.notm
	subq	#2,ob_messtimer(a5)
.notm	;
	tst	ob_invisible(a5)
	beq.s	.noti
	subq	#1,ob_invisible(a5)
	bne.s	.noti
	bsr	message
	dc.b	'invisibility out...',0
	even
.noti	;
	tst	ob_paltimer(a5)
	beq.s	.notp
	subq	#1,ob_paltimer(a5)
	bne.s	.notp
	move.l	#palettes,ob_palette(a5)
.notp	;
	move	ob_pixsizeadd(a5),d0
	beq.s	.notpix
	add	d0,ob_pixsize(a5)
	bne.s	.pixnz
	;
	clr	ob_pixsizeadd(a5)
	bra.s	.notpix
	;
.pixnz	cmp	#22,ob_pixsize(a5)	;v105c: keep teleport animation visible 10 frames longer before black hold
	blt.s	.notpix
	;
	; v104: level-exit teleport was still holding the final blue frame because
	; finished2 was copied to finished before the v103 blackout flag was set.
	; For exits/intermissions, first request a black C2P frame, clear pix/HUD
	; state, then let mainloop leave the level.  The loading/intermission wait
	; now sits on black instead of the last blue teleport chamber frame.
	move	finished2(pc),d0
	beq.s	.g2normal_teleport
	move	#1,g2teleport_blackout
	move	#17,g2teleport_black_hold	;v105b: shorter black hold, about one third of v105
	move	d0,g2teleport_black_finish
	clr	finished			;do not leave the level until the black hold elapsed
	clr	ob_pixsize(a5)
	clr	ob_pixsizeadd(a5)
	bra.s	.notpix
	;
.g2normal_teleport
	move	ob_telex(a5),ob_x(a5)
	move	ob_telez(a5),ob_z(a5)
	move	ob_telerot(a5),ob_rot(a5)
	clr	ob_pixsize(a5)
	clr	ob_pixsizeadd(a5)
.notpix	;
	move	ob_hyper(a5),d0
	beq.s	.nothyper
	bpl.s	.hplus
	;
	;hyper is minus! growing...
	;
	subq	#4,d0
	move	d0,d1
	neg	d1
	cmp	#maxsize,d1
	bne.s	.hdone
	move	#750<<2+maxsize,d0
	bra.s	.hdone
	;
.hplus	subq	#4,d0
	cmp	#maxsize,d0
	bhi.s	.hdone2
	bne.s	.noteq
	bsr	message
	dc.b	'hyper out...',0
	even
	move	#maxsize,d0
.noteq	move	d0,d1
	cmp	#$200,d0
	bne.s	.hdone
	moveq	#0,d0
	;
.hdone	move	d1,ob_scale(a5)
	;
	move	d1,d2
	mulu	#((pl_eyey<<16)/$200),d2
	swap	d2
	neg	d2
	move	d2,ob_eyey(a5)
	;
	move	d1,d2
	mulu	#((pl_firey<<16)/$200),d2
	swap	d2
	neg	d2
	move	d2,ob_firey(a5)
	;
	move	d1,d2
	mulu	#((pl_gutsy<<16)/$200),d2
	swap	d2
	neg	d2
	move	d2,ob_gutsy(a5)
	;
.hdone2	move	d0,ob_hyper(a5)
.nothyper	;
	rts

footstep	move.l	d0,-(a7)
	move.l	footstepsfx(pc),a0
	moveq	#16,d0
	moveq	#0,d1
	bsr	playsfx
	move.l	(a7)+,d0
	rts

pbuff	ds.b	128	;player controls to use!
pput	dc	0	;put new cntrl here
pget	dc	0	;read this for actual

getcntrl	move	ob_cntrl(a5),d0
	lea	joyx0,a0
	move.l	0(a0,d0*8),joyx
	move.l	4(a0,d0*8),joyb
	rts

maxrotsp	equ	$40000
rotacc	equ	$20000
rotrevacc	equ	$40000
rotsetacc	equ	$20000

rotplayer	;return rot in d0, leave a0
	;
	cmp	#0,ob_cntrl(a5)	; v34 KEYBMOUSE mouse rotation is applied in VBlank sampler
	bne.w	.notkmouse
	clr.l	ob_rotspeed(a5)
	rts
.notkmouse	move	joys(pc),d0	;strafing?
	bne.s	.norot
	move	joyx(pc),d0
	beq.s	.norot
	;
	move.l	#rotacc,d1	;rotacc
	move	ob_rotspeed(a5),d2
	beq.s	.useacc
	eor	d2,d0
	bpl.s	.useacc
	move.l	#rotrevacc,d1	;fast rev!
.useacc	move	joyx(pc),d0
	bpl.s	.plus
	neg.l	d1
.plus	add.l	d1,ob_rotspeed(a5)
	cmp.l	#maxrotsp,ob_rotspeed(a5)
	bgt.s	.fixaccpl
	cmp.l	#-maxrotsp,ob_rotspeed(a5)
	bge.s	.addrot
	move.l	#-maxrotsp,ob_rotspeed(a5)
	bra.s	.addrot
.fixaccpl	move.l	#maxrotsp,ob_rotspeed(a5)
	bra.s	.addrot
	;
.norot	tst.l	ob_rotspeed(a5)
	beq.s	.skip
	bpl.s	.orpl
	add.l	#rotsetacc,ob_rotspeed(a5)
	ble.s	.addrot
.clrrot	clr.l	ob_rotspeed(a5)
	bra.s	.skip
.orpl	sub.l	#rotsetacc,ob_rotspeed(a5)
	bmi.s	.clrrot
	;
.addrot	move.l	ob_rotspeed(a5),d0
	add.l	d0,ob_rot(a5)
	;
.skip	rts

unbounce	move	ob_bounce(a5),d1
	beq.s	.rts
	add	#30,ob_bounce(a5)
	move	ob_bounce(a5),d1
	and	#127,d1
	cmp	#30,d1
	bcc.s	.rts
	clr	ob_bounce(a5)
	clr	ob_frame(a5)
	bra	footstep
.rts	rts

moveplayer	;work out movement vector into d0/d1...check still/moving!
	;
	cmp	#0,ob_cntrl(a5)	; v34 KEYBMOUSE: W/X forward-back and A/D strafe, mouse turns
	bne	.normmove
	move	joyy(pc),d4	;forward/backward
	move	joyx(pc),d5	;strafe direction
	move	joys(pc),d0
	bne.s	.kmstrflag
	clr	d5
.kmstrflag	tst	d4
	bne.s	.kmmove
	tst	d5
	beq.w	.still
.kmmove	movem.l	d4-d5/a1,-(a7)
	move.l	camrots(pc),a1
	move	ob_rot(a5),d1
	and	#255,d1
	lea	0(a1,d1*8),a1
	move	d4,d0
	beq.s	.kmnostep
	neg	d0
	move	d0,d2
	bsr	g2_get_shift_movspeed	; v59: SHIFT run = 150% speed for KEYBMOUSE
	muls	d0,d2
	move	d2,d0
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
.kmnostep	move	d5,d0
	beq.s	.kmdonevec
	move.l	camrots(pc),a1	; v35: strafe uses camrot table base, not forward-rotated entry
	lsl	#6,d0
	add	ob_rot(a5),d0
	and	#255,d0
	lea	0(a1,d0*8),a1
	bsr	g2_get_shift_movspeed	; v59: SHIFT run = 150% speed for KEYBMOUSE strafe
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
.kmdonevec	movem.l	(a7)+,d4-d5/a1
	bra	.check
.normmove	move	joyy(pc),d0
	bne	.move
	move	joys(pc),d0
	beq.w	.still
	move	joyx(pc),d0
	bne.s	.strafe
	;
.still	bsr	unbounce
	move	ob_bounce(a5),d0
	bne	.fskip
	rts
	;
.strafe	;do strafe! X rot in d0
	;
	move.l	camrots(pc),a1
	lsl	#6,d0	;* ninety degrees
	add	ob_rot(a5),d0
	and	#255,d0
	lea	0(a1,d0*8),a1
	;
	move	ob_movspeed(a5),d0
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
	bra	.check
	;
.move	;and possibly strafe!
	;
	;work out move vec into d0/d1
	;
	neg	d0
	muls	ob_movspeed(a5),d0	;speed
	move.l	camrots(pc),a1
	move	ob_rot(a5),d1
	and	#255,d1
	lea	0(a1,d1*8),a1
	move	d0,d1
	muls	2(a1),d0
	add.l	d0,d0
	muls	6(a1),d1
	add.l	d1,d1
	neg.l	d0
	add.l	d0,d6
	add.l	d1,d7
	move	joys(pc),d0
	beq.s	.check
	move	joyx(pc),d0
	bne.s	.strafe
.check	;
	bsr	checknewslow
	beq.s	.newpos
	bsr	adjustpos
	beq.s	.newpos
	bsr	adjustpos
	beq.s	.newpos
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bra.s	.bounce
	;
.newpos	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	;
.bounce	move	ob_bounce(a5),d2
	; v190fy: SHIFT run is 150%, so advance the footstep/bob timer
	; by 30 instead of 20 while KEYBMOUSE SHIFT-run is active.
	moveq	#20,d0
	cmp	#0,ob_cntrl(a5)
	bne.s	.g2v190fy_stepadd
	move.l	rawtable,a0
	move.b	12(a0),d1	; raw $60/$61 = left/right SHIFT bits
	and.b	#3,d1
	beq.s	.g2v190fy_stepadd
	moveq	#30,d0
.g2v190fy_stepadd
	add	d0,ob_bounce(a5)
	move	ob_bounce(a5),d1
	and	#255,d2
	cmp	#64,d2
	bcc.s	.fskip
	and	#255,d1
	cmp	#64,d1
	bcs.s	.fskip
	;
	bsr	footstep
.fskip	;
	move.l	ob_framespeed(a5),d1
	add.l	d1,ob_frame(a5)
	and	#3,ob_frame(a5)
	rts

; v59: KEYBMOUSE run modifier.  Left or right SHIFT keeps the existing
; W/X/A/D and cursor movement logic, but raises the effective move speed
; to approximately 150%.  It reads the existing rawmatrix bits, so no new
; keyboard poller is introduced.
g2_get_shift_movspeed
	move	ob_movspeed(a5),d0
	movem.l	d1/a0,-(a7)
	move.l	rawtable,a0
	move.b	12(a0),d1	; raw $60/$61 = left/right SHIFT bits
	and.b	#3,d1
	beq.s	.g2gsm_done
	move	d0,d1
	asr	#1,d1
	add	d1,d0
.g2gsm_done
	movem.l	(a7)+,d1/a0
	rts

checkevent	bsr	checknew2
	beq.s	.rts
	;
	move	ob_pixsizeadd(a5),d0
	or	finished2(pc),d0
	bne	.rts
	;
	move	zo_ev(a4),d0	;poly->event
	bmi.s	.rts
	;
	cmp	#24,d0
	bne.s	.notexit
	;
	move	#3,finished2		;pattern done!
	move	#1,ob_pixsizeadd(a5)	;pixel out
	tst	gametype
	beq.s	.onewin
	bsr	getother
	move	#1,ob_pixsizeadd(a0)	;c86p: match ONE PLAYER teleport frame pacing for other player too
.onewin	;
	bsr	dotelesfx
	moveq	#24,d0
	;
.notexit	cmp	#19,d0
	bcc.s	.noclr
	;
	;OK, gotta clear all 'event' zones with same type!
	;
	move.l	map_poly(pc),a0
	move.l	map_ppnt(pc),a1
	moveq	#32,d1
.loop2	cmp	zo_ev(a0),d0
	bne.s	.skip2
	neg	zo_ev(a0)
.skip2	add.l	d1,a0
	cmp.l	a1,a0
	bcs.s	.loop2
	;
.noclr	move.l	a5,eventobj
	movem.l	d6-d7,-(a7)
	jsr	execevent
	movem.l	(a7)+,d6-d7
	move.l	eventobj(pc),a5
	;
.rts	rts

	;these updated after a call to 'getcntrl'
	;
joyx	dc	0	;left/rite
joyy	dc	0	;for/back
joyb	dc	0	;fire
joys	dc	0	;strafe

checksuck	cmp.l	sucking(pc),a5
	bne.s	.nosuck
	;
	move.l	suckangle(pc),a0
	moveq	#25,d0
	move	d0,d1
	muls	2(a0),d0
	neg.l	d0
	add.l	d0,d6
	;
	muls	6(a0),d1
	add.l	d1,d7
	bsr	checknewslow
	beq.s	.newok
	bsr	adjustpos
	beq.s	.newok
	bsr	adjustpos
	beq.s	.newok
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	bra.s	.nosuck
	;
.newok	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
	;
.nosuck	rts

playerlogic0	;restart after death...2 seconds invincibility.
	;
	subq	#1,ob_delay(a5)
	bgt.s	playerlogic
	;
	;OK, fix colltype/collwith
	;
	lea	player1_,a1
	cmp.l	player1,a5
	beq.s	.got
	lea	player2_,a1
.got	lea	p1_ob_colltype-player1_(a1),a1
	move.l	(a1),ob_colltype(a5)
	move.l	#playerlogic,ob_logic(a5)
playerlogic	;
	bsr	playertimers	;do timer stuff...
	jsr	trainer_maintain_one	;v115: permanent trainer options, including level/pickup override
	; v100: once teleport/exit pixel-fade begins, freeze player control so
	; the player cannot keep walking while the blue teleport effect runs.
	move	ob_pixsize(a5),d0
	or	ob_pixsizeadd(a5),d0
	bne	rts		;v100a: generic return label, not checkfire's local .rts
	bsr	getcntrl	;player control
	;
	move.l	ob_x(a5),d6
	move.l	ob_z(a5),d7
	;
	;getting sucked?
	;
	;OK, are we getting pushed/squashed?
	;
	bsr	checknewslow
	beq.s	.newok
	bsr	adjustpos
	beq.s	.newok2
	bsr	adjustpos
	beq.s	.newok2
	;
	subq	#1,ob_hitpoints(a5)
	ble	playerdie
	st	ob_update(a5)
	bra	redpal
	;
.newok2	move.l	d6,ob_x(a5)
	move.l	d7,ob_z(a5)
.newok	;
	bsr	checksuck
	bsr	checkevent	;in an event zone?
	; v100: checkevent can start teleport this same frame; do not still rotate,
	; move or fire after the transition has already started.
	move	ob_pixsize(a5),d0
	or	ob_pixsizeadd(a5),d0
	bne	rts		;v100a: generic return label, not checkfire's local .rts
	bsr	rotplayer	;rotate
	bsr	moveplayer	;forward/back/strafe
checkfire	;
	move	cheat(pc),d0
	beq.s	.nocheat
	;
	; HELP is handled once per press by g2hotkeys_poll (Unlimited Health).
	move.l	rawtable,a0	; remaining legacy cheat keys still need the matrix
.noend	key	10
	beq.s	.nohealth
	bsr	inchealth
	bra.s	.nocheat
.nohealth	move.b	(a0),d1
	moveq	#5,d0
.loop	btst	d0,d1
	bne.s	.gotch
	subq	#1,d0
	bne.s	.loop
	bra.s	.nocheat
.gotch	;
	subq	#1,d0
	bsr	weapond0
	;
.nocheat	bsr	checkfireb
	beq	.nofire
	tst.b	ob_reloadcnt(a5)
	bne	.nofire2
	;
	move	ob_collwith(a5),d2
	and	#3,d2
	eor	#3,d2	;colltype
	moveq	#0,d3	;collwith!
	;
	move	ob_weapon(a5),d0
	mulu	#18,d0
	lea	wtable(pc),a0
	movem	0(a0,d0),d4-d6
	movem.l	6(a0,d0),a2-a3
	move.l	14(a0,d0),-(a7)
	;
	tst	ob_mega(a5)
	beq.s	.nomega
	;
	cmp	#ok,ob_mega(a5)
	bcc.s	.threeway
	;
	movem.l	d2-d6/a2-a3,-(a7)
	addq	#4,ob_rot(a5)
	bsr	shoot
	movem.l	(a7)+,d2-d6/a2-a3
	subq	#8,ob_rot(a5)
	bsr	shoot
	addq	#4,ob_rot(a5)
	bra.s	.shdone
.threeway	;
	movem.l	d2-d6/a2-a3,-(a7)
	addq	#8,ob_rot(a5)
	bsr	shoot
	movem.l	(a7),d2-d6/a2-a3
	sub	#16,ob_rot(a5)
	bsr	shoot
	movem.l	(a7)+,d2-d6/a2-a3
	addq	#8,ob_rot(a5)
	;
.nomega	bsr	shoot
	;
.shdone	move.l	(a7)+,a0
	move	#3,g2gun_firetimer	;v79: 3-frame single-shape flash 1x->1.6x->2.4x
	move.l	(a0),a0
	moveq	#32,d0
	moveq	#0,d1
	bsr	playsfx
	;
	; c87b70f: run at exactly 80% of the original long-term fire rate.
	; Original shot interval is ob_reload+1 logic steps.  80% frequency means
	; a 5/4 interval.  Keep the quarter-step remainder in unused ob_something
	; per player, distributing it across shots instead of rounding every shot.
	; ob_reload itself stays unchanged, so all weapon-upgrade display/steps stay
	; original.  KEYBMOUSE held-button autofire in checkfireb is untouched.
	moveq	#0,d0
	move.b	ob_reload(a5),d0
	addq	#1,d0		; original interval
	mulu	#5,d0		; desired interval numerator /4
	move.l	d0,d1
	and	#3,d1		; fractional quarter remainder
	lsr.l	#2,d0		; whole desired interval
	subq	#1,d0		; store counter, interval is counter+1
	move	ob_something(a5),d2
	and	#3,d2		; per-player fire fraction 0..3
	add	d1,d2
	cmp	#4,d2
	bcs.s	.g2fire80_no_carry
	subq	#4,d2
	addq	#1,d0
.g2fire80_no_carry
	move	d2,ob_something(a5)
	move.b	d0,ob_reloadcnt(a5)
	rts
	;
.nofire	tst.b	ob_reloadcnt(a5)
	beq.s	.rts
.nofire2	subq.b	#1,ob_reloadcnt(a5)
.rts	rts

	;
	;hitpoints
	;damage
	;speed
	;
wtable	dc	1,1,32
	dc.l	bullet1,sparks1,shootsfx3
	dc	5,2,36
	dc.l	bullet2,sparks2,shootsfx5
	dc	10,2,40
	dc.l	bullet3,sparks3,shootsfx
	dc	15,3,40
	dc.l	bullet4,sparks4,shootsfx4
	dc	20,5,24
	dc.l	bullet5,sparks5,shootsfx5

adjustposq	;
	neg	d0
	move	d0,d1
	;
	muls	zo_a(a4),d0
	add.l	d0,d0
	;
	muls	zo_b(a4),d1
	add.l	d1,d1
	;
	sub.l	d0,d6
	sub.l	d1,d7
	;
	rts

adjustpos	bsr	adjustposq
	;
	;addq	#1,(a4)
	;move.l	a4,-(a7)
	bsr	checknewslow
	;move.l	(a7)+,a3
	;addq	#1,(a3)
	tst	d1
	rts

checkfireb	move	joyb(pc),d0
	beq.s	.nofire
	cmp	#0,ob_cntrl(a5)	; v34 KEYBMOUSE keeps firing while held
	beq.s	.kmfire
	tst	ob_lastbut(a5)
	bne.s	.skip
	move	d0,ob_lastbut(a5)
	rts
.kmfire	move	d0,ob_lastbut(a5)
	rts
.skip	moveq	#0,d0
	rts
.nofire	clr	ob_lastbut(a5)
	rts

eventobj	dc.l	0

calcbounce	;calculate bounce vector...poly in a4, obj in a5
	;
	;R=2 N (N dot V) - V
	;
	;where R=reflect vector, N=normal to poly, V=original vector
	;
	subq	#1,ob_bouncecnt(a5)
	bge.s	.nok
	bsr	makesparksq
	bra	killobject
.nok	;
	move.l	closewall(pc),a4
	movem	ob_nxvec(a5),d0-d1	;normalized dir
	movem	zo_na(a4),d2-d3		;normal to poly
	neg	d2
	;
	;calc dot product:
	;
	move	d0,d4
	muls	d2,d4
	move	d1,d5
	muls	d3,d5
	add.l	d5,d4
	add.l	d4,d4
	swap	d4	;dot product?
	;
	muls	d4,d2
	lsl.l	#2,d2
	swap	d0
	clr	d0
	sub.l	d0,d2
	swap	d2
	;
	muls	d4,d3
	lsl.l	#2,d3
	swap	d1
	clr	d1
	sub.l	d1,d3
	swap	d3
	;
	movem	d2-d3,ob_nxvec(a5)
	;
	neg	d2
	muls	ob_movspeed(a5),d2
	add.l	d2,d2
	muls	ob_movspeed(a5),d3
	add.l	d3,d3
	;
	movem.l	d2-d3,ob_xvec(a5)
	;
	bsr	checkvecs
	beq.s	putfire
	bra	calcbounce

firelogic	;
	bsr	checkvecs
	bne	calcbounce
putfire	;
	addq	#1,ob_frame(a5)
	move	ob_frame(a5),d0
	move.l	ob_shape(a5),a0
	cmp	2(a0),d0
	bcs.s	.skip
	clr	ob_frame(a5)
.skip	;
	rts

moveblood	lea	blood(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq	.done
	;
	tst	bl_y(a5)
	ble.s	.do
	;
	move.l	sucking(pc),d0
	beq.s	.kill
	;
	move.l	bl_xvec(a5),d0
	add.l	d0,bl_x(a5)
	move.l	bl_zvec(a5),d1
	add.l	d1,bl_z(a5)
	;
	move.l	bl_dest(a5),a0
	move	bl_x(a5),d0
	sub	ob_x(a0),d0
	muls	d0,d0
	move	bl_z(a5),d1
	sub	ob_z(a0),d1
	muls	d1,d1
	add.l	d1,d0
	cmp.l	#64*64,d0
	bcc.s	.loop
	bra.s	.kill
	;
.do	add.l	#$8000,bl_yvec(a5)
	;
	movem.l	bl_xvec(a5),d0-d2
	add.l	d1,bl_y(a5)
	blt.s	.ok
	;
.kill	move.l	a5,a0
	killitem	blood
	move.l	a0,a5
	bra	.loop
	;
.ok	add.l	d0,bl_x(a5)
	add.l	d2,bl_z(a5)
	bra	.loop
	;
.done	rts

scrnblood	dc	0

drawblood	clr	scrnblood
	move	#$20,$dff09a
	; c87b69 STOCK keeps the original Gloom blood-list traversal unchanged.
	lea	blood(pc),a5
	;
.loop	move.l	(a5),a5
	tst.l	(a5)
	beq	.done
	;
	move	bl_color(a5),d6
	beq.s	.loop	;already splatted on screen if 0!
	;
	move	bl_x(a5),d0
	sub	camx(pc),d0
	move	bl_y(a5),d1
	ble.s	.blok
	neg	d1
.blok	sub	camy(pc),d1
	move	bl_z(a5),d2
	sub	camz(pc),d2
	;
	;rotate x/z around cam...
	;
	move	d0,d3
	move	d2,d5
	muls	cm1(pc),d0
	muls	cm2(pc),d5
	add.l	d5,d0
	add.l	d0,d0
	swap	d0	;X
	;
	muls	cm3(pc),d3
	muls	cm4(pc),d2
	add.l	d3,d2
	add.l	d2,d2
	swap	d2	;Z
	;
	tst	d2
	beq	.loop
	tst	g2_visibility
	bgt.s	.g2v190dw_blood_far
	cmp	#maxz,d2	; v190ey: DEFAULT original cull
	bcc	.loop
	bra.s	.g2v190dw_blood_zok
.g2v190dw_blood_far
	cmp	#g2advviewfar,d2	; v190fc: ADVANCED uses smooth 16 texture widths
	bcc	.loop
.g2v190dw_blood_zok
	;
	ext.l	d0
	lsl.l	#focshft,d0
	divs	d2,d0
	jsr	g2view_scale_x_d0	; v190hx7: full-FOV VIEW SIZE X scale
	cmp	minx(pc),d0
	blt	.loop
	cmp	maxx(pc),d0
	bge	.loop
	;
	ext.l	d1
	lsl.l	#focshft,d1
	divs	d2,d1
	jsr	g2view_scale_y_d1	; v190hx7: full-FOV VIEW SIZE Y scale
	cmp	miny(pc),d1
	blt	.loop
	cmp	maxy(pc),d1
	bge	.loop
	;
	; v34: same wall-occlusion test as stable gloom.s v45a.
	; Blood is drawn after walls, so reject droplets behind the nearest wall
	; in the projected screen column.
	move	d0,d4
	add	midx(pc),d4
	move.l	vertdraws(pc),a0
	mulu	#vd_size,d4
	lea	0(a0,d4),a0
	cmp	vd_z(a0),d2
	bcc	.loop
	;
	cmp	#40,d2
	bcc.s	.pix
	tst	bl_y(a5)
	bgt.s	.pix
	;
	;blood on screen!
	;
	st	scrnblood
	clr	bl_color(a5)
	bra	.loop
.pix	;
	move	d0,d4	;projected relative X for bounds of 2x2 splat
	move	d1,d5	;projected relative Y for bounds of 2x2 splat
	add	midx(pc),d0
	add	midy(pc),d1
	;
	move	d2,d3
	move	d6,-(a7)	; preserve blood colour mask during fog-distance scaling
	tst	g2_visibility
	bgt.s	.g2v190ey_blood_shade_adv
	cmp	#(4<<grdshft),d3
	blo.s	.g2v190ey_blood_shade_restore
	sub	#(4<<grdshft),d3
	add	d3,d3
	add	#(4<<grdshft),d3
	cmp	#maxz-1,d3
	bls.s	.g2v190ey_blood_shade_restore
	move	#maxz-1,d3
	bra.s	.g2v190ey_blood_shade_restore
.g2v190ey_blood_shade_adv
	move	d3,d6
	lsr	#1,d3
	lsr	#3,d6
	add	d6,d3
	lsr	#2,d6
	add	d6,d3
	lsr	#1,d6
	add	d6,d3
	cmp	#maxz-1,d3
	bls.s	.g2v190ey_blood_shade_restore
	move	#maxz-1,d3
.g2v190ey_blood_shade_restore
	move	(a7)+,d6
.g2v190dw_blood_shade_ok
	move.l	darktable(pc),a0
	move	0(a0,d3*2),d3
	;
	; v31: chunky blood must use byte writes.  The old planar/cop path
	; wrote a word through COP/wi_bmap and could corrupt the chunky/C2P
	; frame or hit the legacy screen-splat blit path.  Keep the original
	; particle projection, but draw a small guarded 2x2 block into chunky.
	;
	move.l	d1,d7
	mulu	chunkymodw(pc),d7	;row offset
	;
	lea	blcols,a0
	move	0(a0,d3*2),d3
	and	d6,d3
	;
	; v32: convert 12-bit RGB blood colour to the active 8-bit chunky
	; palette index.  v31 wrote the low byte of $f00/$c00/etc. directly,
	; which becomes 0 for red blood and therefore drew black splats.
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq.s	.v32_blood_fallback_red
	move.b	0(a0,d3.w),d3
	bra.s	.v32_blood_color_ok
.v32_blood_fallback_red
	moveq	#12,d3
.v32_blood_color_ok
	;
	move.l	chunky(pc),a1
	lea	coloffs,a2
	add.l	0(a2,d0*4),a1
	move.b	d3,0(a1,d7.l)
	;
	move	d4,d6	;relative X from before midx add
	addq	#1,d6
	cmp	maxx(pc),d6
	bge.s	.no_x2
	move	d0,d6
	addq	#1,d6
	move.l	chunky(pc),a3
	add.l	0(a2,d6*4),a3
	move.b	d3,0(a3,d7.l)
.no_x2	;
	move	d5,d6	;relative Y from before midy add
	addq	#1,d6
	cmp	maxy(pc),d6
	bge.s	.no_y2
	move.l	d7,d6
	move	chunkymodw(pc),d5
	ext.l	d5
	add.l	d5,d6
	move.b	d3,0(a1,d6.l)
	;
	move	d4,d5
	addq	#1,d5
	cmp	maxx(pc),d5
	bge.s	.no_y2
	move	d0,d5
	addq	#1,d5
	move.l	chunky(pc),a3
	add.l	0(a2,d5*4),a3
	move.b	d3,0(a3,d6.l)
.no_y2	bra	.loop
	;
.done	move	#$8020,$dff09a
	;
	; v31: disable legacy close-up screen splat blit for now.  It uses
	; font/wi_bmap planar drawing and was the likely crash path in the
	; new chunky/C2P renderer.  World blood and gore remain active.
	clr	scrnblood
	rts

blcols	dc	$ccc,$bbb,$aaa,$999,$888,$777,$666,$555
	dc	$444,$333,$222,$111,$111,$111,$111,$111

shaperender	dc.l	drawobjnorm	;default!

drawshape_1sc	;draw shape with one frame, scaled!
	;
	move.l	ob_shape(a5),a0
	move	ob_frame(a5),d0
	add.l	12(a0,d0*4),a0
	move	ob_scale(a5),d7
	bra	drawshape

drawshape_1	;
	move.l	ob_shape(a5),a0
	move	ob_frame(a5),d0
	add.l	12(a0,d0*4),a0
	move	#$200,d7	;scale
	bra	drawshape

drawshape_8	;
	;shape has 8 rotations, and a scale!
	;
	bsr	calcangle2
	add	#16,d0
	sub	ob_rot(a5),d0
	lsr	#5,d0	;c56: match working gloom.s 8-way actor facing (256/8), avoid spinny 2P player sprite
	and	#7,d0
	move	ob_frame(a5),d1
	lsl	#3,d1
	or	d1,d0
	move.l	ob_shape(a5),a0
	move	ob_scale(a5),d7
	add.l	12(a0,d0*4),a0
	;
drawshape	move	ob_x(a5),d0
	move	ob_y(a5),d1
	move	ob_z(a5),d2
drawshape_q	;
	;A0=shape
	;D0=X
	;D1=Y
	;D2=Z
	;D7=sclae factor
	;
	;rotate Z around camera!
	;
	sub	camx(pc),d0
	sub	camy(pc),d1
	sub	camz(pc),d2
	;
	move	d0,d3
	move	d2,d5
	muls	cm3(pc),d3
	muls	cm4(pc),d2
	add.l	d3,d2
	add.l	d2,d2
	swap	d2
	;
	tst	d2
	ble	.rts
	tst	g2_visibility
	bgt.s	.g2v190dw_shape_far
	cmp	#maxz,d2	; v190ey: DEFAULT original object/sprite distance
	bcc	.rts
	bra.s	.g2v190dw_shape_zok
.g2v190dw_shape_far
	cmp	#g2advshapez,d2	; v190fc: ADVANCED objects/sprites = 16 texture widths
	bcc	.rts
.g2v190dw_shape_zok
	;
	muls	cm1(pc),d0
	muls	cm2(pc),d5
	add.l	d5,d0
	add.l	d0,d0
	swap	d0
	;
	move.l	memat(pc),a1
	add.l	#sh_size,memat
	movem	d0-d2,sh_x(a1)
	move.l	g2_shape_owner,sh_prev(a1)	;v126 object owner copied into draw item
	move.l	a0,sh_shape(a1)
	move	d7,sh_scale(a1)
	move.l	shaperender(pc),sh_render(a1)
	;
	lea	shapelist(pc),a2
.loop	move.l	(a2),d0
	beq.s	.end
	move.l	a2,a3
	move.l	d0,a2
	cmp	sh_z(a2),d2	;nearer...further in list
	ble.s	.loop
	move.l	a2,(a1)
	move.l	a1,(a3)
	rts
.end	move.l	d0,(a1)
	move.l	a1,(a2)
.rts	rts

checknew2	;check trigger zone
	move.l	map_grid(pc),a0
	addq	#4,a0
	bra.s	checknew_

gs	equ	1<<grdshft

incframe	addq	#1,frame
	bne.s	.skip
	;
	movem.l	d0-d1/a0-a1,-(a7)
	moveq	#0,d0
	moveq	#32,d1
	move.l	map_poly(pc),a0
	move.l	map_ppnt(pc),a1
.loop	move	d0,(a0)
	add.l	d1,a0
	cmp.l	a1,a0
	bcs.s	.loop
	;
	addq	#1,frame
	movem.l	(a7)+,d0-d1/a0-a1
	;
.skip	rts

checkoffs	dc	0,0,-gs,0,gs,0,0,-gs,0,gs
	dc	-gs,-gs,gs,-gs,-gs,gs,gs,gs

checknew	;check wall zone
	;
	;d6.q=x, d7.q=z
	;
	;check for ob_radsq(a5)
	;
	move.l	map_grid(pc),a0
	;
checknew_	movem.l	d3-d7,-(a7)
	swap	d6
	swap	d7
	;
	lea	checkoffs(pc),a1	;where to check from
	move.l	map_poly(pc),a2
	bsr	incframe
	move	frame,d3
	moveq	#8,d5		;nine squares
	;
.loop	movem	(a1)+,d0-d1
	add	d6,d0
	cmp	#32<<grdshft,d0
	bcc	.next
	add	d7,d1
	cmp	#32<<grdshft,d1
	bcc	.next
	;
	;d0,d1=sq to check!
	;
	lsr	#grdshft,d0
	lsr	#grdshft,d1
	;
	lsl	#5,d1
	add	d1,d0
	lea	0(a0,d0*8),a3	;square to check!
	;
	move	(a3)+,d4	;how many in square
	bmi	.next
	move	(a3),d1
	;
	move.l	map_ppnt(pc),a3
	lea	0(a3,d1*2),a3
	;
.loop2	move	(a3)+,d0
	lsl	#5,d0
	lea	0(a2,d0),a4	;poly to check
	;
	cmp	(a4),d3
	beq.s	.next2
	move	d3,(a4)
	;
	bsr	findsegdist
	;
	sub	ob_rad(a5),d0
	bpl.s	.next2
	;
	movem.l	(a7)+,d3-d7
	moveq	#-1,d1	;coll!
	rts
	;
.next2	dbf	d4,.loop2
	;
.next	dbf	d5,.loop
	;
	movem.l	(a7)+,d3-d7
	moveq	#0,d1	;no coll!
	rts

closest	dc	0	;nearest so far!
closewall	dc.l	0

checknewslow	;check wall zone
	;
	;d6.q=x, d7.q=z
	;
	;check for ob_radsq(a5)
	;
	move.l	map_grid(pc),a0
	;
	movem.l	d3-d7,-(a7)
	swap	d6
	swap	d7
	;
	lea	checkoffs(pc),a1	;where to check from
	move.l	map_poly(pc),a2
	bsr	incframe
	move	frame,d3
	moveq	#8,d5		;nine squares
	move	#$3fff,closest
	;
.loop	movem	(a1)+,d0-d1
	add	d6,d0
	cmp	#32<<grdshft,d0
	bcc.s	.next
	add	d7,d1
	cmp	#32<<grdshft,d1
	bcc.s	.next
	;
	;d0,d1=sq to check!
	;
	lsr	#grdshft,d0
	lsr	#grdshft,d1
	;
	lsl	#5,d1
	add	d1,d0
	lea	0(a0,d0*8),a3	;square to check!
	;
	move	(a3)+,d4	;how many in square
	bmi.s	.next
	move	(a3),d1
	;
	move.l	map_ppnt(pc),a3
	lea	0(a3,d1*2),a3
	;
.loop2	move	(a3)+,d0	;grab poly#
	lsl	#5,d0
	lea	0(a2,d0),a4	;poly to check
	bsr	checkpolydist
	dbf	d4,.loop2
.next	dbf	d5,.loop
	;
	lea	rotpolys(pc),a3
	;
.loop3	move.l	(a3),a3
	tst.l	(a3)
	beq.s	.rpdone
	;
	move.l	rp_first(a3),a4
	move	rp_num(a3),d4
	subq	#1,d4
	;
.loop4	bsr	checkpolydist
	lea	32(a4),a4
	dbf	d4,.loop4
	;
	bra.s	.loop3
.rpdone	;
	movem.l	(a7)+,d3-d7
	move	closest(pc),d0
	sub	ob_rad(a5),d0
	bpl.s	.wallok
	move.l	closewall(pc),a4
	moveq	#-1,d1
	rts
.wallok	moveq	#0,d1
	rts

checkpolydist	;	
	cmp	(a4),d3
	beq	.rts
	move	d3,(a4)
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_na(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_nb(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0	;distance from end
	;
	cmp	zo_ln(a4),d0
	bcc.s	.rts
	;
	;find perpendicular dist.
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	bpl.s	.pl
	neg.l	d0
.pl	swap	d0	;perpendicular dist.w
	;
	cmp	closest(pc),d0
	bcc.s	.rts
	move	d0,closest
	move.l	a4,closewall
	;
.rts	rts

findsegdist	;find distance from d6,d7 to zone in a4...
	;
	;find end dist
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_na(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_nb(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0	;distance from end
	;
	cmp	zo_ln(a4),d0
	bcs.s	.perp	;use perpendicular distance!
	;
	move	#$3fff,d0
	rts
	;
.perp	;find perpendicular dist.
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	bpl.s	.pl
	neg.l	d0
.pl	swap	d0	;perpendicular dist.w
	rts

findsegdist2	;find distance from d6,d7 to zone in a4...
	;
	;find perpendicular dist.
	;
	move	zo_rx(a4),d0
	sub	d6,d0
	muls	zo_a(a4),d0
	move	zo_rz(a4),d1
	sub	d7,d1
	muls	zo_b(a4),d1
	add.l	d1,d0
	add.l	d0,d0
	swap	d0	;perpendicular dist.w
	muls	d0,d0
	;
	;find distance from end
	;
	move	zo_rx(a4),d1
	sub	d6,d1
	muls	zo_na(a4),d1
	move	zo_rz(a4),d2
	sub	d7,d2
	muls	zo_nb(a4),d2
	add.l	d2,d1
	add.l	d1,d1
	swap	d1	;distance from end
	;
	cmp	zo_ln(a4),d1
	bcs.s	.perp	;use perpendicular distance!
	;
	;gotta find radial distance
	;
	blt.s	.min	;minus?
	sub	zo_ln(a4),d1
.min	muls	d1,d1
	add.l	d1,d0
	;
.perp	rts

calccamera	;a0=player object
	;	
	move.l	camrots(pc),a2
	;
	move	ob_x(a0),camx
	move	ob_y(a0),d0
	add	ob_eyey(a0),d0
	;
	;add bounce!
	;
	move	ob_bounce(a0),d1
	and	#255,d1
	move	2(a2,d1*8),d1
	muls	#20,d1
	swap	d1
	;
	add	d1,d0
	;
	move	d0,camy
	move	ob_z(a0),camz
	move	ob_rot(a0),d0
	and	#255,d0
	move	d0,camr
	move.l	camrots(pc),a1
	;
	lea	0(a1,d0*8),a1
	;
	move.l	(a1)+,cm1
	move.l	(a1),cm3
	;
	;calc inverse camera matrix!
	;
	move.l	camrots(pc),a1
	neg	d0
	and	#255,d0
	lea	0(a1,d0*8),a1
	;
	move.l	(a1)+,icm1
	move.l	(a1),icm3
	;
	rts

readnull	clr.l	(a0)
	clr.l	4(a0)
	rts

readjoydir	bsr	joydir
	move	d1,d0
	move	d2,d1
	add	d1,d1
	eor	d1,d2
	;
joydir	btst	#9,d2
	bne.s	.neg
	btst	#1,d2
	bne.s	.pos
	moveq	#0,d1
	rts
.neg	moveq	#-1,d1
	rts
.pos	moveq	#1,d1
	rts

readjoy0	;into a0 block
	;
	move	$dff00a,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	btst	#6,$bfe001
	seq	d0
	ext	d0
	move	d0,4(a0)
	btst	#2,$dff016
	seq	d0
	ext	d0
	move	d0,6(a0)
	rts

readjoy1	;into a0 block
	;
	move	$dff00c,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	btst	#7,$bfe001
	seq	d0
	ext	d0
	move	d0,4(a0)
	btst	#6,$dff016
	seq	d0
	ext	d0
	move	d0,6(a0)
	rts

readcd320	;into a0 block
	;
	move	$dff00a,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	;
	lea	$bfe001,a2
	lea	$dff016,a1
	;
	moveq	#6,d3
	move	#$400,d4
	bset	d3,$200(a2)
	bclr	d3,(a2)
	move	#$f200,$dff034
	moveq	#0,d0
	moveq	#6,d1
.loop	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	move	(a1),d2
	bset	d3,(a2)
	bclr	d3,(a2)
	and	d4,d2
	bne.s	.skip
	bset	d1,d0
.skip	dbf	d1,.loop
	move	#$f300,$dff034	;#0
	bclr	d3,$200(a2)
	;
handlecd32	btst	#5,d0
	sne	d1
	ext	d1
	move	d1,4(a0)	;fire button!
	clr	6(a0)
	;
	lsr	#1,d0	;btst	#0,d0
	bcc.s	.noesc
	st	escape
.noesc	;
	lsr	#1,d0	;btst	#1,d0
	bcc.s	.nolsh
	;
	;left should button!
	move	#-1,(a0)	;left/
	move	#-1,6(a0)	;strafe!
	rts
	;
.nolsh	lsr	#1,d0	;btst	#2,d0
	bcc.s	.norsh
	;
	;rite shoulder button
	move	#1,(a0)
	move	#-1,6(a0)
	;
.norsh	rts

readcd321	;into a0 block
	;
	move	$dff00c,d2	;joy0
	bsr	readjoydir
	movem	d0-d1,(a0)
	;
	lea	$bfe001,a2
	lea	$dff016,a1
	;
	moveq	#7,d3
	move	#$4000,d4
	bset	d3,$200(a2)
	bclr	d3,(a2)
	move	#$2000,$dff034
	moveq	#0,d0
	moveq	#6,d1
.loop	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	tst.b	(a2)
	move	(a1),d2
	bset	d3,(a2)
	bclr	d3,(a2)
	and	d4,d2
	bne.s	.skip
	bset	d1,d0
.skip	dbf	d1,.loop
	move	#$3000,$dff034
	bclr	d3,$200(a2)
	;
	bra	handlecd32

	;    00 : play/pause
	;    01 : reverse
	;    02 : forward
	;    03 : green
	;    04 : yellow
	;    05 : red
	;    06 : blue

readkeys	;into a0 block
	;
	move.l	rawtable,a1
	moveq	#0,d0
	keya1	$4f
	beq.s	.nleft
	moveq	#-1,d0
.nleft	keya1	$4e
	beq.s	.nrite
	moveq	#1,d0
.nrite	move	d0,(a0)
	moveq	#0,d0
	keya1	$63
	bne.s	.up
	keya1	$4c
	beq.s	.nup
.up	moveq	#-1,d0
.nup	keya1	$60
	bne.s	.down
	keya1	$4d
	beq.s	.ndown
.down	moveq	#1,d0
.ndown	move	d0,2(a0)
	moveq	#0,d0
	keya1	$66
	beq.s	.nbut
	moveq	#-1,d0
.nbut	move	d0,4(a0)
	moveq	#0,d0
	keya1	$64
	beq.s	.nstr
	moveq	#-1,d0
.nstr	move	d0,6(a0)
	rts

readkeymouse	;keyboard plus mouse into a0 block
	; v34: imported from stable gloom.s v29a/WAXD.
	; W/A/S/X/D are tracked in rawkeyread; S and X are backward.
	movem.l	d1-d3/a1,-(a7)
	move.l	rawtable,a1
	clr	(a0)
	clr	2(a0)
	clr	4(a0)
	clr	6(a0)
	moveq	#0,d0
	keya1	$63	; cursor up
	bne.s	.km_up
	keya1	$4c	; numpad up
	bne.s	.km_up
	btst	#1,wasd_state	; W held
	beq.s	.km_nup
.km_up	moveq	#-1,d0
.km_nup	; v118: do not treat raw $60 as KEYBMOUSE down here.
	; $60 is left SHIFT in the raw matrix and is used as run modifier;
	; keeping it as down made SHIFT+W / SHIFT+cursor-up walk backward.
	keya1	$4d	; cursor/numpad down
	bne.s	.km_down
	btst	#3,wasd_state	; X held = backward
	beq.s	.km_ndown
.km_down	moveq	#1,d0
.km_ndown	move	d0,2(a0)
	moveq	#0,d0
	keya1	$4f	; cursor left
	bne.s	.km_left
	btst	#2,wasd_state	; A held
	beq.s	.km_nleft
.km_left	moveq	#-1,d0
.km_nleft	keya1	$4e	; cursor right
	bne.s	.km_rite
	btst	#4,wasd_state	; D held
	beq.s	.km_nrite
.km_rite	moveq	#1,d0
.km_nrite	tst	d0
	beq.s	.km_nostrafe
	move	d0,(a0)
	move	#-1,6(a0)
.km_nostrafe	moveq	#0,d0
	keya1	$66
	beq.s	.km_nkeyfire
	moveq	#-1,d0
.km_nkeyfire	move	d0,4(a0)
	btst	#6,$bfe001	; left mouse button = fire
	bne.s	.km_nolmfire
	move	#-1,4(a0)
.km_nolmfire	movem.l	(a7)+,d1-d3/a1
	rts

sample_keymouse_vb	;v34/v29a: VBlank direct mouse yaw for KEYBMOUSE, mid speed
	movem.l	d0-d2/a5,-(a7)
	move	$dff00a,d1
	move.b	d1,d0
	tst	mousexinit
	bne.s	.kmvb_have_last
	move.b	d0,mousexlast
	move	#-1,mousexinit
	bra.s	.kmvb_done
.kmvb_have_last	move.b	mousexlast,d2
	move.b	d0,mousexlast
	sub.b	d2,d0
	ext.w	d0
	beq.s	.kmvb_done
	cmp	#24,d0
	ble.s	.kmvb_pos_ok
	moveq	#24,d0
	bra.s	.kmvb_apply
.kmvb_pos_ok	cmp	#-24,d0
	bge.s	.kmvb_apply
	moveq	#-24,d0
.kmvb_apply	tst	paused
	bne.s	.kmvb_done
	move.l	player1,a5
	tst.l	a5
	beq.s	.kmvb_done
	; v102: while teleporting or dead, never apply live mouse yaw.  The death
	; animation may still spin/fall by script, but once the body is down the
	; player can no longer turn the camera.
	move	ob_pixsize(a5),d1
	or	ob_pixsizeadd(a5),d1
	bne.s	.kmvb_done
	tst	ob_hitpoints(a5)
	ble.s	.kmvb_done
	cmp	#0,ob_cntrl(a5)
	bne.s	.kmvb_done
	ext.l	d0
	swap	d0
	clr.w	d0
	move.l	d0,d1
	asr.l	#3,d0
	asr.l	#4,d1
	add.l	d1,d0
	add.l	d0,ob_rot(a5)
	clr.l	ob_rotspeed(a5)
.kmvb_done	movem.l	(a7)+,d0-d2/a5
	rts

gridoffs	incbin	gridoffs4.bin
gridoffsf

