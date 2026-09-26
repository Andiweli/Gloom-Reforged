; Step 1: Bayer gates use the live switch (also forced OFF by STOCK).
makewalls	;
	;New approach!
	;
	;use poly's line eq to test perpendicular distance to wall
	;produce nearest -> furthest wall list.
	;
	;optimizations...
	;check if both z's are negative after rotation
	;check if projected left/rite ends are on screen
	;
	bsr	incframe
	;
	clr.l	inlist
	move.l	#inlist,inlistf
	;
	move.l	map_poly(pc),a4
	move.l	map_ppnt(pc),a3
	move.l	map_grid(pc),a2
	movem	camx(pc),d6-d7	;x,z
	lsr	#grdshft,d6
	lsr	#grdshft,d7
	lea	gridoffs(pc),a6
	moveq	#(gridoffsf-gridoffs)>>2-1,d5
	;
.loop	movem	(a6)+,d0-d1
	add	d6,d0
	cmp	#32,d0
	bcc	.skip
	add	d7,d1
	cmp	#32,d1
	bcc	.skip
	;
	;d0,d1=x/z of map to check!
	;
	lsl	#5,d1	;Y*32...
	add	d1,d0	;+X
	lea	0(a2,d0*8),a0	;mapgrid
	move	(a0)+,d4	;how many polys here
	bmi	.skip
	move	(a0),d0	;poly data offset
	lea	0(a3,d0*2),a0
	;
.loop2	move	(a0)+,d0	;poly#
	lsl	#5,d0
	lea	0(a4,d0),a1	;actual poly
	;
	bsr	dothezone
	;
	dbf	d4,.loop2	;finish sq
	;
.skip	dbf	d5,.loop	;gridoffs
	;
	;now do rots/morphs...
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
.loop4	move.l	a4,a1
	bsr	dothezone2
	;
	lea	32(a4),a4
	dbf	d4,.loop4
	;
	bra.s	.loop3
.rpdone	;
makeoutlist	;create outlist from inlist
	;
	clr.l	outlist
	move.l	#outlist,outlistf
	;
.loop	lea	inlist(pc),a0
	move.l	(a0),d0
	beq	.done
	move.l	a0,a2	;save previous!
	move.l	d0,a0
	;
	;OK, see if any are in front of a0...
	;
	lea	inlist(pc),a1
	;
.loop2	move.l	(a1),d0
	beq	.none
	move.l	a1,a3
	move.l	d0,a1
	cmp.l	a0,a1
	beq.s	.loop2	;don't compare with self!
	;
	;check screen pos overlap...
	;
	move	wl_rsx(a0),d0
	cmp	wl_lsx(a1),d0
	blt	.loop2
	;
	move	wl_lsx(a0),d1
	cmp	wl_rsx(a1),d1
	bgt	.loop2
	;
	;check near/far Z overlap
	;
	move	wl_nz(a1),d2
	cmp	wl_fz(a0),d2
	bge	.loop2	;behind!
	;
	move	wl_fz(a1),d2
	cmp	wl_nz(a0),d2
	ble	.swap
	;
	tst	wl_open(a1)
	bne	.swap	
	;
	;look at a0 points against a1 line...
	;
	movem	wl_a(a1),d5-d6
	move.l	wl_c(a1),d7
	;
	move	wl_lx(a1),d0
	sub	wl_lx(a0),d0
	muls	d5,d0
	move	wl_lz(a1),d1
	sub	wl_lz(a0),d1
	muls	d6,d1
	add.l	d1,d0
	eor.l	d7,d0
	;
	move	wl_lx(a1),d1
	sub	wl_rx(a0),d1
	muls	d5,d1
	move	wl_lz(a1),d2
	sub	wl_rz(a0),d2
	muls	d6,d2
	add.l	d2,d1
	eor.l	d7,d1
	;
	;if both a0 in front, no swap
	;
	move.l	d0,d4
	or.l	d1,d4
	bpl	.loop2	;both a0's in front of a1!
	;
	;if both a0 behind, swap
	;
	and.l	d1,d0
	bmi	.swap	;both a0's behind a1!
	;
	;look at a1 points against a0 line!
	;
	movem	wl_a(a0),d5-d6
	move.l	wl_c(a0),d7
	;
	move	wl_lx(a0),d2
	sub	wl_lx(a1),d2
	muls	d5,d2
	move	wl_lz(a0),d3
	sub	wl_lz(a1),d3
	muls	d6,d3
	add.l	d3,d2
	eor.l	d7,d2
	;
	move	wl_lx(a0),d3
	sub	wl_rx(a1),d3
	muls	d5,d3
	move	wl_lz(a0),d4
	sub	wl_rz(a1),d4
	muls	d6,d4
	add.l	d4,d3
	eor.l	d7,d3
	;
	move.l	d2,d4
	and.l	d3,d4
	bmi	.loop2	;both a1's behind a0!
	;
	or.l	d3,d2
	bmi	.loop2
	;
.swap	move.l	a1,a0
	move.l	a3,a2
	bra	.loop2
	;
.none	;OK, none in front of this (a0)
	;
	move.l	(a0),(a2)	;unlink from inlist
	clr.l	(a0)
	;
	move.l	outlistf(pc),a2
	move.l	a0,(a2)
	move.l	a0,outlistf
	bra	.loop
	;
.done	rts

dothezone2	;
	move	frame,d0
	cmp	zo_done(a1),d0
	beq.s	.rts
	move	d0,zo_done(a1)
	tst	zo_open(a1)
	bmi.s	.rts
	;
	movem	d4-d7,-(a7)
	;
	movem	zo_lx(a1),d0-d3	;x1,z1,x2,z2
	movem	camx(pc),d6-d7
	;
	move	#maxz,d4
	tst	g2_visibility
	ble.s	.g2v190dw_zone2_view_ok
	move	#g2advviewfar,d4	; v190fc: ADVANCED zone cull = 16 texture widths
.g2v190dw_zone2_view_ok
	move	d4,d5
	neg	d5
	;
	sub	d6,d0
	cmp	d4,d0
	bge.s	.rts2
	cmp	d5,d0
	ble.s	.rts2
	;
	sub	d7,d1
	cmp	d4,d1
	bge.s	.rts2
	cmp	d5,d1
	ble.s	.rts2
	;
	sub	d6,d2
	cmp	d4,d2
	bge.s	.rts2
	cmp	d5,d2
	ble.s	.rts2
	;
	sub	d7,d3
	cmp	d4,d3
	bge.s	.rts2
	cmp	d5,d3
	bgt	dothezone3 ;.rts2
	;
.rts2	movem	(a7)+,d4-d7
	;
.rts	rts

dothezone	;
	move	frame,d0
	cmp	zo_done(a1),d0
	beq	rts ;.skip3
	move	d0,zo_done(a1)
	tst	zo_open(a1)
	bmi	rts ;.skip3
	;
	;OK, setup:
	;
	;d0=lx,d1=lz,d2=rx,d3=rz
	;d4=t,d5=sc,d6=dist
	;
	;back face/dist check...
	;
	movem	d4-d7,-(a7)
	;
	movem	zo_lx(a1),d0-d3	;x1,z1,x2,z2
	movem	camx(pc),d6-d7
	;
	sub	d6,d0
	sub	d7,d1
	sub	d6,d2
	sub	d7,d3
	;
dothezone3	move	d0,d4
	move	d1,d5
	muls	cm1(pc),d0
	muls	cm2(pc),d5
	add.l	d5,d0
	add.l	d0,d0
	swap	d0
	;
	muls	cm3(pc),d4
	muls	cm4(pc),d1
	add.l	d4,d1
	add.l	d1,d1
	swap	d1	;LZ
	;
	move	d2,d4
	move	d3,d5
	muls	cm1(pc),d2
	muls	cm2(pc),d5
	add.l	d5,d2
	add.l	d2,d2
	swap	d2	;RX
	;
	muls	cm3(pc),d4
	muls	cm4(pc),d3
	add.l	d4,d3
	add.l	d3,d3
	swap	d3	;RZ
	;
	;check Z's...
	tst	d1
	bgt.s	.zok
	tst	d3
	ble	.skip2
.zok	;
	move	#maxz,d4
	tst	g2_visibility
	ble.s	.g2v190dw_wall_view_ok
	move	#g2advviewfar,d4	; v190fc: ADVANCED wall/zone cull = 16 texture widths
.g2v190dw_wall_view_ok
	cmp	d4,d1
	blt.s	.zok2
	cmp	d4,d3
	bge	.skip2
.zok2	;
	;do backface check...generate a,b,c...
	;
	rol.l	#exshft,d0
	rol.l	#exshft,d1
	rol.l	#exshft,d2
	rol.l	#exshft,d3
	;
	move	d1,d4
	sub	d3,d4	;a
	move	d2,d5
	sub	d0,d5	;b
	;
	move	d0,d6
	muls	d4,d6
	move	d1,d7
	muls	d5,d7
	add.l	d7,d6
	bpl.s	.front
	;
	;backface showing!...
	bra	.skip2
.front	;
	move.l	memat(pc),a5
	;
	movem	d0-d5,wl_lx(a5)
	move.l	d6,wl_c(a5)
	;
	;work out some screen positions!
	tst	d1
	bgt.s	.z1ok
	;
	;lz bad, rz must be OK...
	;
.ov1	move	minx(pc),wl_lsx(a5)
	bra.s	.z1sk
	;
.z1ok	ext.l	d0
	lsl.l	#focshft,d0
	divs	d1,d0
	bvs.s	.ov1		; RC4: preserve original Gloom2 DIVS overflow handling
	jsr	g2view_scale_x_d0	; v190hx7: full-FOV wall endpoint X
	subq	#1,d0
	cmp	maxx(pc),d0
	bge	.skip2
	move	d0,wl_lsx(a5)
.z1sk	;
	tst	d3
	bgt.s	.z2ok
	;
	;rz bad, lz must be OK...
	;
.ov2	move	maxx(pc),wl_rsx(a5)
	bra.s	.z2sk
	;
.z2ok	ext.l	d2
	lsl.l	#focshft,d2
	divs	d3,d2
	bvs.s	.ov2		; RC4: preserve original Gloom2 DIVS overflow handling
	jsr	g2view_scale_x_d2	; v190hx7: full-FOV wall endpoint X
	addq	#1,d2
	cmp	minx(pc),d2
	blt	.skip2
	move	d2,wl_rsx(a5)
.z2sk	;
	cmp	d1,d3
	bge.s	.zskp
	exg	d1,d3
.zskp	movem	d1/d3,wl_nz(a5)	;near/far Z
	;
	move.l	zo_t(a1),wl_t(a5)
	move.l	zo_t+4(a1),wl_t+4(a5)
	move	zo_sc(a1),wl_sc(a5)
	move	zo_open(a1),wl_open(a5)
	;
	;add to end of inlist...
	;
	clr.l	(a5)
	move.l	inlistf(pc),a1
	move.l	a5,(a1)
	move.l	a5,inlistf
	add.l	#wl_size,memat
	;
.skip2	movem	(a7)+,d4-d7
	;
.skip3	rts

	;elseif

makeoutlist2	;create outlist from inlist
	;
.loop0	lea	inlist(pc),a0
	;
.loop	move.l	(a0),d0
	beq	.done
	move.l	a0,a2	;save previous!
	move.l	d0,a0
	;
	;OK, see if any are in front of a0...
	;
	lea	inlist(pc),a1
	;
.loop2	move.l	(a1),d0
	beq	.none
	move.l	a1,a3
	move.l	d0,a1
	;
	cmp.l	a0,a1
	beq.s	.loop2	;don't compare with self!
	;
	;see if a1 is in front of a0
	;
	move	wl_nz(a1),d0
	cmp	wl_fz(a0),d0
	bge	.loop2	;behind!
	;
	move	wl_fz(a1),d0
	cmp	wl_nz(a0),d0
	ble	.swap
	;
	;now, compare screen x coords.....
	;
	move	wl_rsx(a0),d0
	cmp	wl_lsx(a1),d0
	blt	.loop2
	;
	move	wl_lsx(a0),d0
	cmp	wl_rsx(a1),d0
	bgt	.loop2
	;
	;look at a0 points against a1 line
	;
	;If Sgn((x3-x1)*a2+(y3-y1)*b2)<>Sgn(c2)
	;  If Sgn((x3-x2)*a2+(y3-y2)*b2)<>Sgn(c2)
	;    tr=-1:Return
	;  EndIf
	;EndIf
	;
	movem	wl_a(a1),d5-d6
	move.l	wl_c(a1),d7
	;
	move	wl_lx(a1),d0
	sub	wl_lx(a0),d0
	muls	d5,d0
	move	wl_lz(a1),d1
	sub	wl_lz(a0),d1
	muls	d6,d1
	add.l	d1,d0
	eor.l	d7,d0
	;
	move	wl_lx(a1),d1
	sub	wl_rx(a0),d1
	muls	d5,d1
	move	wl_lz(a1),d2
	sub	wl_rz(a0),d2
	muls	d6,d2
	add.l	d2,d1
	eor.l	d7,d1
	;
	;OK, screen X's overlap...
	;if both a0 in front, no swap
	;
	move.l	d0,d4
	or.l	d1,d4
	bpl	.loop2
	;
	;if both a0 behind, swap
	;
	move.l	d0,d4
	and.l	d1,d4
	bmi	.swap
	;
	;bra	.loop2
	;
	;elseif
	;look at a1 points against a0 line
	;
	;If Sgn((x1-x3)*a1+(y1-y3)*b1)=Sgn(c1)
	;  If Sgn((x1-x4)*a1+(y1-y4)*b1)=Sgn(c1)
	;    tr=-1:Return
	;  EndIf
	;EndIf
	;
	movem	wl_a(a0),d5-d6
	move.l	wl_c(a0),d7
	;
	move	wl_lx(a0),d2
	sub	wl_lx(a1),d2
	muls	d5,d2
	move	wl_lz(a0),d3
	sub	wl_lz(a1),d3
	muls	d6,d3
	add.l	d3,d2
	eor.l	d7,d2
	;
	move	wl_lx(a0),d3
	sub	wl_rx(a1),d3
	muls	d5,d3
	move	wl_lz(a0),d4
	sub	wl_rz(a1),d4
	muls	d6,d4
	add.l	d4,d3
	eor.l	d7,d3
	;
	;if both a1's behind, no swap
	;
	move.l	d2,d4
	and.l	d3,d4
	bmi	.loop2	;both a1's behind...
	;
	;if both a1's in front, swap
	move.l	d2,d4
	or.l	d3,d4
	bpl	.swap
	;
	bra	.loop2
	;
	;elseif
	;
.swap	;a1 is infront of a0! make a1 new frontmost
	bra	.loop
	move.l	a1,a0
	move.l	a3,a2
	bra	.loop2
	;
.none	;OK, none in front of this (a0)
	;
	move.l	(a0),(a2)	;unlink from inlist
	clr.l	(a0)
	move.l	outlistf(pc),a2
	move.l	a0,(a2)
	move.l	a0,outlistf
	bra	.loop0
	;
.done	;move.l	inlist(pc),d0
	;bne	.loop0
	rts

	;elseif

castwalls	;process 'walls' list
	;
	tst	g2twop_crop_mode
	bne.w	.g2twop_crop_cast
	; c87w1: once native WIDE is live, minx/maxx are the real expanded ray
	; domain. Standard VIEW SIZE modes retain the proven full-FOV resampler.
	tst	g2p96_wide_mode
	beq.s	.g2c87w1_standard_cast
	tst	p96gameplay_linear_active
	beq.s	.g2c87w1_standard_cast
	move	minx(pc),d7		; compact destination X domain
	move	d7,d0
	move.l	#256,d1
	; c87b69e: for 2x1/2x2, cast all native WIDE rays into half as many
	; columns.  Destination comparisons stay compact; ray coordinates start at
	; the saved native left edge and advance two native columns per sample.
	tst.w	g2resolution_active
	beq.s	.g2c87b69e_wide_cast_ready
	move	g2resolution_saved_minx,d0
	move.w	g2resolution_active,d2
	btst	#0,d2
	beq.s	.g2c87b69e_wide_cast_ready
	move.l	#512,d1
.g2c87b69e_wide_cast_ready
	ext.l	d0
	lsl.l	#8,d0
	move.l	d0,g2view_cast_xfp
	move.l	d1,g2view_cast_step
	move.l	vertdraws(pc),a4
	bra.w	.loop
.g2c87w1_standard_cast
	move	minx(pc),d7
	move.l	#-40960,g2view_cast_xfp
	move.l	#81920,d0
	divu	width,d0
	and.l	#$0000ffff,d0
	move.l	d0,g2view_cast_step
	move.l	vertdraws(pc),a4
	bra.w	.loop
.g2twop_crop_cast
	; c86l: gloom.s-style crop/window casting.  Use minx/maxx directly
	; against the existing castrots table; no full-FOV resampling step.
	move.l	castrots(pc),a6
	move	minx(pc),d7
	lea	0(a6,d7*8),a6
	move.l	vertdraws(pc),a4
	;
.loop	;do this vert line!
	;
	tst	g2twop_crop_mode
	bne.s	.g2twop_have_castrot
	move.l	g2view_cast_xfp(pc),d6
	asr.l	#8,d6
	move.l	castrots(pc),a6
	tst	g2p96_wide_mode
	beq.s	.g2c87w1_castptr_ready
	tst	p96gameplay_linear_active
	beq.s	.g2c87w1_castptr_ready
	move.l	g2wide_castrots(pc),a6
.g2c87w1_castptr_ready
	lea	0(a6,d6*8),a6
.g2twop_have_castrot
	lea	outlist(pc),a5
	;
.loop2	move.l	(a5),d0
	beq	.empty
	move.l	a5,a3	;previous
	move.l	d0,a5
	;
	cmp	wl_lsx(a5),d7
	blt.s	.loop2	;not up to left yet!
	;
	cmp	wl_rsx(a5),d7
	ble.s	.try
	;
	;past right! unlink!
	move.l	(a5),(a3)
	bra.s	.loop2	
.try	;
	movem	wl_lx(a5),d0-d1
	muls	(a6),d0
	muls	2(a6),d1
	add.l	d1,d0	;LX!
	bgt.s	.loop2
	;
	movem	wl_rx(a5),d1-d2
	muls	(a6),d1
	muls	2(a6),d2
	add.l	d2,d1	;RX!
	blt.s	.loop2
	;
	sub.l	d0,d1
	;
	swap	d1
	tst	d1
	ble.s	.dfix
	neg.l	d0
	divu	d1,d0
	bvc.s	.noov
.dfix	moveq	#-1,d0
.noov	lsr	#1,d0	;fraction -> unsigned
	;
	cmp	wl_open(a5),d0
	bcs.s	.loop2
	;
	movem	wl_lx(a5),d1-d2
	muls	4(a6),d1
	muls	6(a6),d2
	add.l	d2,d1
	add.l	d1,d1	;lz
	;
	movem	wl_rx(a5),d2-d3
	muls	4(a6),d2
	muls	6(a6),d3
	add.l	d3,d2
	add.l	d2,d2	;rz
	;
	sub.l	d1,d2
	swap	d2
	muls	d0,d2
	add.l	d2,d2
	add.l	d1,d2
	;
	swap	d2
	;
	cmp	#exone,d2
	blt	.loop2
	move	#maxz<<exshft,d6
	tst	g2_visibility
	ble.s	.g2v190dw_cast_view_ok
	move	#(g2advviewfar<<exshft)-8,d6	; v190fc: ADVANCED wall cast just below signed 16-bit edge, approx 16 widths
.g2v190dw_cast_view_ok
	cmp	d6,d2
	bcs.s	.zisok
	;
.empty	move	#32767,vd_z(a4)
	clr.l	vd_data(a4)
	bra	.next
.zisok	;
	;d0=frac, d2=z, a5=item
	;
	;calc column#
	;
	move.l	a4,a0	;do vd...
	;
	move	wl_sc(a5),d1
	bgt.s	.mul
	neg	d1
	ext.l	d0
	add.l	d0,d0
	lsr.l	d1,d0
	bra.s	.scdone
.mul	mulu	d1,d0
.scdone	move.l	d0,d1
	swap	d1	;0...sc-1
	and	#7,d1
	move.b	wl_t(a5,d1),d1
	;
	lea	textures(pc),a3
	move.l	0(a3,d1*4),a3	;texture!
	lsl.l	#6,d0	;*64
	swap	d0
	and	#63,d0	;0...w-1
	move	d0,d1
	lsl	#6,d0
	add	d1,d0
	add	d0,a3
	;
	lsr	#exshft,d2
	;
	; v190dz: ADVANCED must not hard-pop walls/doors at the
	; extended clip.  DEFAULT already fades into its fog before the
	; normal clip; for ADVANCED dissolve whole far columns with a
	; stable 4x4 Bayer mask from 8..16 texture widths, so geometry
	; approaches the final clip already mostly hidden.
	;
	tst	g2_visibility
	; v190ey: ADVANCED 12 now uses the same smooth scaled fog as v190ew DEFAULT-12.
	; Do not dissolve whole columns at the far end.
	bra	.g2v190dz_wallclip_done
	ble.s	.g2v190dz_wallclip_done
	cmp	#(8<<grdshft),d2
	blo.s	.g2v190dz_wallclip_done
	move	d2,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 0..15 over the 8..16 advanced far band
	cmp	#15,d6
	bls.s	.g2v190dz_wallclip_lvl_ok
	moveq	#15,d6
.g2v190dz_wallclip_lvl_ok
	move	d2,d5
	lsr	#8,d5
	and	#3,d5
	lsl	#2,d5
	move	d7,d4
	and	#3,d4
	add	d4,d5
	lea	g2v190dz_bayer4(pc),a2
	moveq	#0,d4
	move.b	0(a2,d5),d4
	cmp	d6,d4
	; v190ed: zero-distance branch removed; keep far wall alive for fog/shade fade
.g2v190dz_wallclip_done
	;
	;a3=texture column!
	;
	tst.b	(a3)+
	beq.s	.solid
	;
	bsr	makestrip	;do strip!
	;
.solid	move.l	a3,vd_data(a0)	;start column
	;
	;fill in vd struct...
	;
	move	d2,d6
	tst	g2_visibility
	bgt.s	.g2v190ey_wall_shade_adv
	cmp	#(4<<grdshft),d6
	blo.s	.g2v190dw_wall_shade_ok
	sub	#(4<<grdshft),d6
	add	d6,d6
	add	#(4<<grdshft),d6
	cmp	#maxz-1,d6
	bls.s	.g2v190dw_wall_shade_ok
	move	#maxz-1,d6
	bra.s	.g2v190dw_wall_shade_ok
.g2v190ey_wall_shade_adv
	move	d6,d0
	lsr	#1,d6
	move	d0,d5
	lsr	#3,d5
	add	d5,d6
	move	d0,d5
	lsr	#5,d5
	add	d5,d6
	move	d0,d5
	lsr	#6,d5
	add	d5,d6
	cmp	#maxz-1,d6
	bls.s	.g2v190dw_wall_shade_ok
	move	#maxz-1,d6
.g2v190dw_wall_shade_ok
	move.l	darktable(pc),a2
	move	0(a2,d6*2),d3
	; v190ec: ADVANCED keeps 12-width visibility but never lets far
	; walls/doors pop as bright solid columns at the advanced clip.
	; Keep the wall column alive and fade its palette through the same
	; fog logic as DEFAULT; only the last far band is Bayer-mixed to
	; the darkest fog palette instead of being removed from vertdraws.
	tst	g2_visibility
	; v190ey: no separate ADVANCED 8..12 far-dark/clip fade.
	; The scaled darktable path above is the confirmed smooth v190ew behavior.
	bra	.g2v190dy_wallfade_done
	ble.s	.g2v190dy_wallfade_done
	cmp	#(8<<grdshft),d2
	blo.s	.g2v190dy_wallfade_done
	move	d2,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 0..15 over the 8..12 texture-width advanced band
	cmp	#15,d6
	bls.s	.g2v190ec_wallfade_lvl_ok
	moveq	#15,d6
.g2v190ec_wallfade_lvl_ok
	move	d6,d0
	lsr	#2,d0	; gentle extra darkness before the final dither fog
	add	d0,d3
	cmp	#14,d3
	bls.s	.g2v190ec_wallfade_cap_ok
	moveq	#14,d3
.g2v190ec_wallfade_cap_ok
	move	d2,d5
	lsr	#8,d5
	and	#3,d5
	lsl	#2,d5
	move	d7,d0
	and	#3,d0
	add	d0,d5
	lea	g2v190dz_bayer4(pc),a2
	moveq	#0,d0
	move.b	0(a2,d5),d0
	cmp	d6,d0
	bcc.s	.g2v190dy_wallfade_done
	moveq	#15,d3	; darkest fog palette, not empty/no-wall
.g2v190dy_wallfade_done
	movem	d2-d3,vd_z(a0)
	;
	move	#-256,d3
	sub	camy(pc),d3
	move	d3,d5
	ext.l	d3
	lsl.l	#focshft,d3
	divs	d2,d3	;sc Y1
	jsr	g2view_scale_y_d3	; v190hx7: full-FOV wall Y scale
	;
	move	camy(pc),d4
	neg	d4
	ext.l	d4
	lsl.l	#focshft,d4
	divs	d2,d4	;sc y2
	jsr	g2view_scale_y_d4	; v190hx7: full-FOV wall Y scale
	;
	sub	d3,d4	;y1,hite
	movem	d3-d4,vd_y(a0)
	;
	;elseif
	;
	moveq	#64,d5
	swap	d5
	clr	d5
	ext.l	d4
	;
	add.l	d5,d5
	add.l	d4,d4
	addq	#1,d4
	;
	divu.l	d4,d5
	;
	;elseif
	;v14: disabled old alternate quarter wall texture step.
	;This is the same class of wall-texture fix as the stable gloom.s path.
;	neg	d3
;	neg	d5
;	cmp	#-128,camy
;	sle	d4
;	ext	d4
;	add	d4,d5
;	;
;	swap	d5
;	clr	d5
;	ext.l	d3
;	divu.l	d3,d5	;sc step
;	asr.l	#2,d5
	;
	;elseif
	;
	move.l	d5,vd_ystep(a0)
	;
	cmp.l	a0,a4
	bne	.loop2
	;
.next	;onto next display column
	;
	lea	vd_size(a4),a4
	tst	g2twop_crop_mode
	bne.s	.g2twop_crop_step
	move.l	g2view_cast_step(pc),d0
	add.l	d0,g2view_cast_xfp
	bra.s	.g2twop_step_done
.g2twop_crop_step
	addq.l	#8,a6
.g2twop_step_done
	addq	#1,d7
	cmp	maxx(pc),d7
	blt	.loop
	;
	check	.loop
	;
	rts

makestrip	;this wall strip has see through bits!
	;insert it into shape list instead of vd list!
	;
	move.l	memat(pc),a0
	add.l	#vd_size,memat
	;
	move.l	memat(pc),a1
	add.l	#sh_size,memat
	;
	clr.l	(a1)
	move	d7,sh_x(a1)
	move	d2,sh_z(a1)
	clr.l	sh_shape(a1)
	move.l	a0,sh_strip(a1)
	;
	;insert into drawlist!
	;
	movem.l	a2-a3,-(a7)
	lea	shapelist(pc),a2
.loop	move.l	(a2),d0
	beq.s	.end
	move.l	a2,a3
	move.l	d0,a2
	cmp	sh_z(a2),d2	;nearer...further in list
	blt.s	.loop
	move.l	a2,(a1)
	move.l	a1,(a3)
	bra.s	.ins
.end	move.l	d0,(a1)
	move.l	a1,(a2)
.ins	movem.l	(a7)+,a2-a3
	;
	rts

drawsolidstrip	macro
	;
	;a0=stripdata, a1=dest, a2=palettes
	;d0=chunkymod
	;
	move	hite(pc),d1	;remainder to CLS
	move.l	vd_data(a0),d2
	bne.s	.g2c87b69_wall_hasdata
	tst	g2walls_precleared
	bne.w	.rts
	bra.w	.vertskip	;legacy path must still clear an empty column
.g2c87b69_wall_hasdata
	move.l	d2,a3	;source texture column.
	move	vd_y(a0),d2
	move.l	vd_ystep(a0),d3
	move	vd_h(a0),d4
	;
	add	midy(pc),d2
	move	d2,g2_bayer_ybase	; v190ej: wall start row for Bayer shade blend
	bpl.s	.notopclip
	clr	g2_bayer_ybase	; top-clipped columns start at row 0
	;
	;clip top Y
	;
	add	d2,d4	;reduce hite of texture
	ble	.vertskip
	neg	d2
	ext.l	d2
	mulu.l	d3,d2	;y step* y
	bra.w	.clipdone
.notopclip	;
	beq.w	.notopcls
	;
	sub	d2,d1	;reduce botcls
	; CLEAR16 has already zeroed the compact linear world surface. In that
	; path only advance to the first wall pixel; legacy layouts retain WALL2.
	tst	g2walls_precleared
	beq.s	.g2c87b69_top_clear
	move	d2,d6
	mulu	d0,d6
	add.l	d6,a1
	bra.s	.notopcls
.g2c87b69_top_clear
	move	d2,d6
	lsr	#1,d6
	beq.s	.g2c87b69_top_tail
	subq	#1,d6
	moveq	#0,d5
.g2c87b69_top_pair
	move.b	d5,(a1)
	add.l	d0,a1
	move.b	d5,(a1)
	add.l	d0,a1
	dbf	d6,.g2c87b69_top_pair
.g2c87b69_top_tail
	btst	#0,d2
	beq.w	.notopcls
	moveq	#0,d5
	move.b	d5,(a1)
	add.l	d0,a1
.notopcls	;
	moveq	#0,d2	;start position in texture
	;
.clipdone	;a1=correct start!
	;
	sub	d4,d1	;reduce bot cls
	bge.s	.hiteok
	add	d1,d4
	ble	.rts
	moveq	#0,d1
.hiteok	;
	;d2=starting texture Y,d3=step,d4=height,a1=dest
	;
	swap	d2
	swap	d3
	move	vd_pal(a0),d5	;0...15
	move.l	0(a2,d5*4),a4
	; v190em: true bright-side lead-in for each real shade-table
	; transition.  The current wall shade is kept as base; only in the
	; last quarter before the next darker darktable step are Bayer pixels
	; drawn with the next darker palette.  No darker-side tail, no clip
	; or column dithering.
	clr	g2_bayer_thresh
	; c87b63 STOCK: select the existing undithered fast wall loop and skip
	; all Bayer transition probing for this column.
	tst	g2_bayer_disabled
	bne.w	.g2v190ej_wallblend_setup_done
	move	vd_z(a0),d6
	tst	g2_visibility
	bgt.s	.g2v190ey_wallblend_adv
	cmp	#(4<<grdshft),d6
	blo.s	.g2v190ej_wallblend_dist_ok
	sub	#(4<<grdshft),d6
	add	d6,d6
	add	#(4<<grdshft),d6
	cmp	#maxz-1,d6
	bls.s	.g2v190ej_wallblend_dist_ok
	move	#maxz-1,d6
	bra.s	.g2v190ej_wallblend_dist_ok
.g2v190ey_wallblend_adv
	move	d7,-(a7)
	move	d6,d7
	lsr	#1,d6
	lsr	#3,d7
	add	d7,d6
	lsr	#2,d7
	add	d7,d6
	lsr	#1,d7
	add	d7,d6
	cmp	#maxz-1,d6
	bls.s	.g2v190ey_wallblend_scale_ok
	move	#maxz-1,d6
.g2v190ey_wallblend_scale_ok
	move	(a7)+,d7
.g2v190ej_wallblend_dist_ok
	; v190eo: no near-distance skip here either.  Every bright
	; shade band may now get its last-quarter darker Bayer lead-in.
	cmp	#14,d5
	bcc	.g2v190ej_wallblend_setup_done
	movem.l	d1/d6/d7/a2,-(a7)
	move.l	darktable(pc),a5
	moveq	#15,d7
	move	d6,d1
	add	#24,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_24ok
	move	#maxz-1,d1
.g2v190em_wallblend_24ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#11,d7
	move	d6,d1
	add	#48,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_48ok
	move	#maxz-1,d1
.g2v190em_wallblend_48ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#7,d7
	move	d6,d1
	add	#72,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_72ok
	move	#maxz-1,d1
.g2v190em_wallblend_72ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	; v190ep: softer sparse start before the normal wall shade lead-in.
	moveq	#4,d7
	move	d6,d1
	add	#96,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190em_wallblend_96ok
	move	#maxz-1,d1
.g2v190em_wallblend_96ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#2,d7
	move	d6,d1
	add	#112,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190ep_wallblend_112ok
	move	#maxz-1,d1
.g2v190ep_wallblend_112ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bhi	.g2v190em_wallblend_set
	moveq	#1,d7
	move	d6,d1
	add	#128,d1
	cmp	#maxz-1,d1
	bls.s	.g2v190ep_wallblend_128ok
	move	#maxz-1,d1
.g2v190ep_wallblend_128ok
	move	0(a5,d1*2),d1
	cmp	d5,d1
	bls.s	.g2v190em_wallblend_restore
.g2v190em_wallblend_set
	move	d7,g2_bayer_thresh
	addq	#1,d5
	cmp	#14,d5
	bls.s	.g2v190em_wallblend_palok
	moveq	#14,d5
.g2v190em_wallblend_palok
	move.l	0(a2,d5*4),a5
.g2v190em_wallblend_restore
	movem.l	(a7)+,d1/d6/d7/a2
.g2v190ej_wallblend_setup_done
	tst	g2_bayer_thresh
	bne.w	.g2v190ej_wall_dither_setup
	; Gloombench WALL2: two exact textured pixels per DBF on the undithered
	; path. Keep the original ADD/ADDX carry chain and odd-height tail.
	move	d4,d6
	lsr	#1,d6
	subq	#1,d6
	sub	d3,d2
	add.l	d3,d2
	tst	d6
	bmi.s	.g2c87b69_wall_single
.g2c87b69_wall_pair
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
	addx.l	d3,d2
	add.l	d0,a1
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
	addx.l	d3,d2
	add.l	d0,a1
	dbf	d6,.g2c87b69_wall_pair
	btst	#0,d4
	beq.w	.vertskip
.g2c87b69_wall_single
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
	addx.l	d3,d2
	add.l	d0,a1
	bra.w	.vertskip
	;
.g2v190ej_wall_dither_setup
	movem.l	d1/d7/a2,-(a7)
	lea	g2v190ej_bayer_column_long,a2
	move	g2_bayer_x,d6
	and	#3,d6
	adda.w	d6,a2
	move	g2_bayer_ybase,d6
	and	#3,d6
	lsl	#2,d6
	adda.w	d6,a2
	move	g2_bayer_thresh,d7
	; Patch 10: 040/060 use a four-row unrolled Bayer wall loop.
	; 020/030 retain the exact original one-pixel loop below.
	cmp.w	#g2kalms_cpu_040,g2kalms_cpu_mode
	beq.w	.g2p10_wall_dither4
	subq	#1,d4	; original DBF count for 020/030
	sub	d3,d2
	add.l	d3,d2	; set X flag immediately before the legacy loop
.g2v190ej_wall_dither_loop
	moveq	#0,d1
	move.b	(a2),d1
	cmp	d7,d1
	bcc.s	.g2v190ej_wall_base
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a5,d5),(a1)
	bra.s	.g2v190ej_wall_advance
.g2v190ej_wall_base
	moveq	#0,d5
	move.b	0(a3,d2),d5
	move.b	0(a4,d5),(a1)
.g2v190ej_wall_advance
	addx.l	d3,d2
	add.l	d0,a1
	lea	4(a2),a2	; next Bayer row, does not disturb X flag
	dbf	d4,.g2v190ej_wall_dither_loop
	bra.s	.g2p10_wall_dither_done
.g2p10_wall_dither4
	jsr	g2p10_wall_dither4_040060
.g2p10_wall_dither_done
	movem.l	(a7)+,d1/d7/a2
.vertskip	;
	tst	g2walls_precleared
	bne.w	.rts
	; Legacy/non-linear path: WALL2 bottom clear with odd-pixel tail.
	tst	d1
	ble.s	.rts
	move	d1,d6
	lsr	#1,d6
	beq.s	.g2c87b69_bot_tail
	subq	#1,d6
	moveq	#0,d5
.g2c87b69_bot_pair
	move.b	d5,(a1)
	add.l	d0,a1
	move.b	d5,(a1)
	add.l	d0,a1
	dbf	d6,.g2c87b69_bot_pair
.g2c87b69_bot_tail
	btst	#0,d1
	beq.s	.rts
	moveq	#0,d5
	move.b	d5,(a1)
	add.l	d0,a1
.rts	;
	endm

; c86zb1: build a simple per-column nearest transparent-strip cover table
; before drawing shapes.  Enemy floor reflections can then be suppressed while
; the enemy is still behind a nearer door/window/transparent strip.
g2_build_reflect_coverz
	movem.l	d0-d3/a0-a2,-(a7)
	lea	g2_reflect_coverz(pc),a0
	move	g2render_last_x(pc),d0
	move	#32767,d1
.g2c86zb1_clr
	move	d1,(a0)+
	dbf	d0,.g2c86zb1_clr
	lea	shapelist(pc),a2
.g2c86zb1_scan
	move.l	(a2),d0
	beq.s	.g2c86zb1_done
	move.l	d0,a2
	tst.l	sh_shape(a2)
	bne.s	.g2c86zb1_scan	; only transparent wall strips have sh_shape=0
	move	sh_x(a2),d1
	add	midx(pc),d1
	bmi.s	.g2c86zb1_scan
	cmp	width(pc),d1
	bge.s	.g2c86zb1_scan
	add	d1,d1
	lea	g2_reflect_coverz(pc),a0
	move	0(a0,d1.w),d2
	move	sh_z(a2),d3
	cmp	d2,d3
	bge.s	.g2c86zb1_scan	; keep nearest/smallest Z only
	move	d3,0(a0,d1.w)
	bra.s	.g2c86zb1_scan
.g2c86zb1_done
	movem.l	(a7)+,d0-d3/a0-a2
	rts

; return d0=1 if the current enemy centre column is still behind a nearer
; transparent strip/door/window, so its floor reflection should stay hidden.
g2_enemy_reflection_blocked_by_cover
	moveq	#0,d0
	move	g2_enemy_ref_cx(pc),d1
	bmi.s	.rts
	cmp	width(pc),d1
	bge.s	.rts
	add	d1,d1
	lea	g2_reflect_coverz(pc),a0
	move	0(a0,d1.w),d1
	cmp	#32767,d1
	beq.s	.rts
	cmp	d2,d1
	bge.s	.rts		; strip is not nearer than the enemy
	moveq	#1,d0
.rts	rts

; c86zb3: stricter runtime cover test for the actual reflection column.
; The c86zb1 centre-column test can miss partially covered enemies behind
; windows or half-transparent doors.  This one runs inside the reflection
; draw path and suppresses each covered column independently.
g2_enemy_reflection_current_column_blocked
	movem.l	d1/a0,-(a7)
	moveq	#0,d0
	move	g2_enemy_ref_curx(pc),d1
	bmi.s	.rts
	cmp	width(pc),d1
	bge.s	.rts
	add	d1,d1
	lea	g2_reflect_coverz(pc),a0
	move	0(a0,d1.w),d1
	cmp	#32767,d1
	beq.s	.rts
	cmp	g2_enemy_ref_z(pc),d1
	bge.s	.rts		; cover is not nearer than the enemy
	moveq	#1,d0
.rts	movem.l	(a7)+,d1/a0
	rts

drawshapes
	; c87b68 STOCK locks reflections off, so the per-column transparent-cover
	; table is never consumed and can be skipped completely.
	tst	g2stock_enabled
	bne.s	.g2stock_no_reflect_cover
	bsr	g2_build_reflect_coverz
.g2stock_no_reflect_cover
	lea	shapelist(pc),a6
	;
.drawloop	move.l	(a6),d0
	beq	.rts
	move.l	d0,a6
	; v190ay: beyond the hard far-fog distance, do not draw later
	; shape/wallstrip overlays at all.  They were rendered after the far
	; corridor fog and could appear as horizontal wrong-texture lines inside
	; the dark zone.  Real far walls/floors are already handled by the wall
	; renderer/fog; sprites and transparent strips should only fade in before
	; they reach this fully dark distance.
	move	#(6<<grdshft),d0
	tst	g2_visibility
	ble.s	.g2v190dw_shapelist_view_ok
	move	#g2advshapez,d0	; v190fc: ADVANCED strips/objects = 16 texture widths
.g2v190dw_shapelist_view_ok
	move	sh_z(a6),d1
	cmp	d0,d1
	bcc	.drawloop
	; v190dz: dissolve far transparent strips/objects in ADVANCED
	; with the same 8..12 texture-width Bayer band as solid walls,
	; otherwise switches/doors/strip overlays pop at their hard clip.
	tst	g2_visibility
	; v190ey: keep transparent strips/objects alive; no old far-end dissolve.
	bra	.g2v190dz_shapeclip_done
	ble.s	.g2v190dz_shapeclip_done
	cmp	#(8<<grdshft),d1
	blo.s	.g2v190dz_shapeclip_done
	move	d1,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 8..16 texture-width far band
	cmp	#15,d6
	bls.s	.g2v190dz_shapeclip_lvl_ok
	moveq	#15,d6
.g2v190dz_shapeclip_lvl_ok
	move	d1,d5
	lsr	#8,d5
	and	#3,d5
	lsl	#2,d5
	move	sh_x(a6),d4
	and	#3,d4
	add	d4,d5
	lea	g2v190dz_bayer4(pc),a2
	moveq	#0,d4
	move.b	0(a2,d5),d4
	cmp	d6,d4
	; v190ed: zero-distance branch removed; keep far strips/objects alive for fog fade
.g2v190dz_shapeclip_done
	move.l	sh_shape(a6),d0
	bne.s	.shape
	;
	;wall strip!
	;
	move	sh_x(a6),d0
	add	midx(pc),d0
	move.l	chunky(pc),a1
	lea	coloffs(pc),a5
	add.l	0(a5,d0*4),a1
	;
	move.l	palette(pc),a2
	move.l	sh_strip(a6),a4
	bsr	drawstrip2
	bra	.drawloop
	;
.shape	move.l	d0,a0
	movem	sh_x(a6),d0-d2
	move	sh_scale(a6),d7
	movem	(a0)+,d3-d4	;x,y handles
	;
	muls	d7,d3	;* scale
	asr.l	#8,d3
	sub.l	d3,d0
	;
	muls	d7,d4
	asr.l	#8,d4
	sub.l	d4,d1
	;
	;d0=rotated X, d1=Y, d2=Z
	;
	lsl.l	#focshft,d0
	divs	d2,d0	;Screen X
	jsr	g2view_scale_x_d0	; v190hx7: full-FOV object X scale
	cmp	maxx(pc),d0
	bge	.drawloop	;X too big!
	;
	lsl.l	#focshft,d1
	divs	d2,d1	;Screen Y
	jsr	g2view_scale_y_d1	; v190hx7: full-FOV object Y scale
	cmp	maxy(pc),d1
	bge	.drawloop
	;
	movem	(a0),d3-d4	;width/hite
	;
	move.l	d3,d5
	muls	d7,d3
	;
	ifne	8-focshft
	asr.l	#8-focshft,d3
	endc
	;
	divs	d2,d3	;screen width
	jsr	g2view_scale_x_d3	; v190hx7: scale object width to render window
	ext.l	d3
	ble	.drawloop
	;
	move.l	d4,d6
	muls	d7,d4
	;
	ifne	8-focshft
	asr.l	#8-focshft,d4
	endc
	;
	divs	d2,d4	;hite
	jsr	g2view_scale_y_d4	; v190hx7: scale object height to render window
	ext.l	d4
	ble	.drawloop
	;
	swap	d5
	divu.l	d3,d5
	;
	add	midx(pc),d0
	bpl.s	.xcskip
	add	d0,d3	;reduce width
	ble	.drawloop
	neg	d0
	;
	ext.l	d0
	mulu.l	d5,d0	;start column in shape
	;
	moveq	#0,d7
	cmp	width(pc),d3
	ble.s	.xcdone
	move	width(pc),d3
	bra.s	.xcdone
	;
.xcskip	move	d0,d7	;sc X
	add	d3,d0
	sub	width(pc),d0
	ble.s	.xcdone2
	sub	d0,d3
	ble	.drawloop
.xcdone2	move.l	d5,d0
	lsr.l	#1,d0
.xcdone	;
	swap	d6
	divu.l	d4,d6	;y step
	;
	move.l	chunky(pc),a1
	;
	add	midy(pc),d1
	bpl.s	.ycskip
	add	d1,d4	;hite
	ble	.drawloop
	neg	d1
	ext.l	d1
	mulu.l	d6,d1
	;
	cmp	hite(pc),d4
	ble.s	.ycdone
	move	hite(pc),d4
	bra.s	.ycdone
	;
.ycskip	move	d1,-(a7)
	mulu	chunkymodw(pc),d1
	add.l	d1,a1
	move	(a7)+,d1
	add	d4,d1
	sub	hite(pc),d1
	ble.s	.ycdone2
	sub	d1,d4
	ble	.drawloop
.ycdone2	move.l	d6,d1
	lsr.l	#1,d1
.ycdone	;
	;draw bit...
	;
	;a0=src, a1=dest, a2=palette
	;
	;d0.q=src x
	;d1.q=src y
	;d2.w = Z!
	;d3.w=width
	;d4.w=height
	;d5.q=x step
	;d6.q=y step
	;d7.w=start screen column
	;a0.l=src
	;a1.l=dest
	;a2.l=palette
	;
	bsr	g2_setup_enemy_blob_column	;v126 hard-edged per-column shadow under enemies
	lea	coloffs,a5
	lea	0(a5,d7*4),a5
	;
	move.l	sh_render(a6),a3
	move.l	a6,-(a7)
	move.l	vertdraws(pc),a6
	mulu	#vd_size,d7
	lea	0(a6,d7),a6	;column for Z compare!
	;
	move	d2,d7
	tst	g2_visibility
	bgt.s	.g2v190ey_obj_shade_adv
	cmp	#(4<<grdshft),d7
	blo.s	.g2v190dw_obj_shade_ok
	move	d6,-(a7)
	sub	#(4<<grdshft),d7
	add	d7,d7
	add	#(4<<grdshft),d7
	cmp	#maxz-1,d7
	bls.s	.g2v190ey_obj_shade_restore_default
	move	#maxz-1,d7
.g2v190ey_obj_shade_restore_default
	move	(a7)+,d6
	bra.s	.g2v190dw_obj_shade_ok
.g2v190ey_obj_shade_adv
	move	d6,-(a7)
	move	d7,d6
	lsr	#1,d7
	lsr	#3,d6
	add	d6,d7
	lsr	#2,d6
	add	d6,d7
	lsr	#1,d6
	add	d6,d7
	cmp	#maxz-1,d7
	bls.s	.g2v190ey_obj_shade_restore_adv
	move	#maxz-1,d7
.g2v190ey_obj_shade_restore_adv
	move	(a7)+,d6
.g2v190dw_obj_shade_ok
	move.l	darktable(pc),a2
	move	0(a2,d7*2),d7
	; v190ec: keep ADVANCED far sprites/switch-like objects fogged
	; at the advanced clip instead of letting them appear fully at once.
	tst	g2_visibility
	; v190ey: no additional ADVANCED object fog clamp; scaled darktable handles it.
	bra	.g2v190ec_objfog_done
	ble.s	.g2v190ec_objfog_done
	cmp	#(8<<grdshft),d2
	blo.s	.g2v190ec_objfog_done
	movem.l	d0-d6,-(a7)
	move	d2,d6
	sub	#(8<<grdshft),d6
	lsr	#6,d6	; v190ex: 8..16 texture-width far band
	cmp	#15,d6
	bls.s	.g2v190ec_objfog_lvl_ok
	moveq	#15,d6
.g2v190ec_objfog_lvl_ok
	move	d6,d0
	lsr	#2,d0
	add	d0,d7
	cmp	#15,d7
	bls.s	.g2v190ec_objfog_cap_ok
	moveq	#15,d7
.g2v190ec_objfog_cap_ok
	movem.l	(a7)+,d0-d6
.g2v190ec_objfog_done
	move.l	palette(pc),a2
	move.l	0(a2,d7*4),a2
	;
	subq	#1,d3
	subq	#1,d4
	swap	d0
	swap	d1
	swap	d5
	swap	d6
	addq	#2,a0
	;
	jsr	(a3)	;drawobjnorm/invs
	clr	g2_shadow_active	;v126 shadow state belongs to this one sprite
	clr	g2_enemy_ref_active	;c86r separate enemy reflection state
	;
	move.l	(a7)+,a6
	bra	.drawloop
	;
.rts	rts

drawobjinvs	;draw invisible object (half brite background!)
	;
	rts
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcc.s	.zbad
	;
	movem.l	d0-d2/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	chunkymodw(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$eee,d2	;RGB and
	;
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	;
	move	(a4),d5
	and	d2,d5
	lsr	#1,d5
	move	d5,(a4)
	;
.skip	add.l	d6,d1	;next src Y
	addx	d0,d1
	add.l	d7,a4
	dbf	d4,.vloop
	;
	movem.l	(a7)+,d0-d2/d4-d5
	;
.zbad	add.l	d5,d0
	moveq	#0,d7
	addx.l	d7,d0	;next src X
	lea	vd_size(a6),a6
	;
	dbf	d3,.hloop
	;
	rts

drawobjtrans	;draw transparent object (merge both colours!)
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcc.s	.zbad
	;
	movem.l	d0-d5/a5-a6,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move.l	chunkymod(pc),d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$eee,d2	;RGB and
	;
	move.l	planar_remap(pc),a5	;remap RGB->LUT
	move.l	planar_palette,a6
	;
	; v190hy4: blob shadows must be behind the sprite column.
	; Reflections stay after the sprite via g2_draw_reflection_column_after_sprite.
	bsr	g2_draw_blob_column_before_sprite
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	;
	move.b	0(a2,d5),d5	;ghost colour!
	move	0(a6,d5*4),d5	;to RGB
	and	d2,d5
	;
	moveq	#0,d3
	move.b	(a4),d3
	move	0(a6,d3*4),d3	;to RGB
	and	d2,d3
	;
	add	d3,d5
	lsr	#1,d5
	move.b	0(a5,d5),(a4)
	moveq	#0,d5
	;
.skip	add.l	d6,d1	;next src Y
	addx	d0,d1	;xtend
	add.l	d7,a4
	dbf	d4,.vloop
	bsr	g2_draw_reflection_column_after_sprite	;v190hy4: reflections only after sprite
	;
	movem.l	(a7)+,d0-d5/a5-a6
	;
.zbad	tst	g2_shadow_active
	ble.s	.noshinc
	addq	#1,g2_shadow_curx
.noshinc	tst	g2_enemy_ref_active
	ble.s	.noerinc
	addq	#1,g2_enemy_ref_curx
.noerinc	add.l	d5,d0
	moveq	#0,d7
	addx.l	d7,d0	;next src X
	lea	vd_size(a6),a6
	;
	dbf	d3,.hloop
	;
	rts

drawobjnorm	;normal draw object...
	;
.hloop	move.l	a1,a4
	add.l	(a5)+,a4
	;
	cmp	vd_z(a6),d2
	bcs.s	.zok
	;
	tst	thermo
	beq.s	.zbad
	;
	bsr	thermostrip
	bra.s	.zbad
	;
.zok	movem.l	d0-d1/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move.l	chunkymod(pc),d7
	moveq	#0,d5
	moveq	#0,d0
	;
	sub	d6,d1
	add.l	d6,d1
	;
	; v190hy4: draw enemy blob shadow before sprite pixels so feet/gore stay on top.
	bsr	g2_draw_blob_column_before_sprite
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	move.b	0(a2,d5),(a4)
.skip	addx.l	d6,d1	;next src Y
	add.l	d7,a4
	dbf	d4,.vloop
	bsr	g2_draw_reflection_column_after_sprite	;v190hy4: reflections only after sprite
	;
	movem.l	(a7)+,d0-d1/d4-d5
	;
.zbad	tst	g2_shadow_active
	ble	.noshinc
	addq	#1,g2_shadow_curx
.noshinc	tst	g2_enemy_ref_active
	ble.s	.noerinc
	addq	#1,g2_enemy_ref_curx
.noerinc	add.l	d5,d0
	moveq	#0,d7
	addx.l	d7,d0	;next src X
	lea	vd_size(a6),a6
	;
	dbf	d3,.hloop
	;
	rts

thermostrip	movem.l	d0-d2/d4-d5,-(a7)
	;
	mulu	(a0),d0
	lea	2(a0,d0),a3	;src
	;
	move	chunkymodw(pc),d7
	ext.l	d7
	moveq	#0,d5
	moveq	#0,d0
	move	#$00f,d2
	;
	sub	d6,d1
	add.l	d6,d1
	;
.vloop	move.b	0(a3,d1),d5
	beq.s	.skip
	;
	move	0(a2,d5*2),d5
	and	d2,d5
	move	d5,(a4)
	;
.skip	addx.l	d6,d1	;next src Y
	add.l	d7,a4
	dbf	d4,.vloop
	;
	movem.l	(a7)+,d0-d2/d4-d5
	;
	rts


; -----------------------------------------------------------------------------
; v137/v176/v190dq/v190ds enemy blob shadows + floor-anchored reflections.
; Blob shadows keep the confirmed hard-edged foot shadow path.  Reflections use
; one remapped colour only. v190ds keeps the clean one-colour look but widens
; the dithered edge bands for a softer test falloff without bright rims.
; -----------------------------------------------------------------------------
g2_setup_enemy_blob_column
	movem.l	d0-d7/a0-a2,-(a7)
	clr	g2_shadow_active
	clr	g2_enemy_ref_active	;c86r reflection state is separate from blob shadows
	move.l	sh_prev(a6),a2	;object owner copied when shape was queued
	tst.l	a2
	beq	.done
	move.l	player1(pc),d0
	cmp.l	d0,a2
	beq	.g2c57_player_shadow_owner
	move.l	player2(pc),d0
	cmp.l	d0,a2
	beq	.g2c57_player_shadow_owner
	bra.s	.g2c57_not_player_owner
.g2c57_player_shadow_owner
	; c57: in TWO PLAYER the other player is a real visible actor and should
	; get the same floor blob as monsters.  The current camera player is not
	; queued by calcscene anyway, but keep the guard for safety.
	tst	twowins
	beq	.done
	cmp.l	player_(pc),a2
	beq	.done
	bra	.g2c57_player_try_blob
.g2c57_not_player_owner
	;
	; v132: reflections first.  The accidental projectile shadows in v126 showed
	; that bullets also pass this same draw path, so use it deliberately now.
	tst	g2_reflections
	ble	.try_blob
	move.l	ob_logic(a2),d0
	cmp.l	#firelogic,d0
	beq	.setup_reflection
	cmp.l	#homeinlogic,d0
	beq	.setup_reflection
	cmp.l	#weaponlogic,d0
	beq	.setup_reflection
	; c86zcv: keep only the working projectile/weapon-upgrade/bouncy
	; reflection owners.  Removed old non-working token-powerup
	; attempts for thermo/invisi/invinc here.
	cmp.l	#bouncylogic,d0
	beq	.setup_reflection
	move.l	ob_hit(a2),d0
	cmp.l	#bouncygot,d0
	beq	.setup_reflection
	cmp.l	#weapongot,d0
	beq	.setup_reflection
	; c87b38: WEAPON stops here. Enemy mirrors are enabled by ALL only.
	cmp	#1,g2_reflections
	bne	.try_blob
	; c86r: living enemies may get a weak mirrored floor reflection.
	; This state is separate from blob shadows so BLOB SHADOW colour/path stays unchanged.
	tst	ob_colltype(a2)
	bne	.try_blob
	tst	ob_hitpoints(a2)
	ble	.try_blob
	cmp	#3<<grdshft,d2
	bgt	.try_blob
	bsr	g2_prepare_enemy_reflection_safe
	bra	.try_blob
	;
.setup_reflection
	bsr	g2_prepare_reflection_column
	bra	.done
	;
.g2c57_player_try_blob
	; c86zcn: in TWO PLAYER modes the visible other player gets the same
	; safe mirrored floor reflection as grounded enemies.  Enemy/near-distance
	; reflection sizing and dither remain exactly the stable c86zc7 version.
	; c87b38: visible player reflections belong to ALL only.
	cmp	#1,g2_reflections
	bne	.g2c57_player_blob_only
	tst	ob_hitpoints(a2)
	ble	.g2c57_player_blob_only
	cmp	#3<<grdshft,d2
	bgt	.g2c57_player_blob_only
	bsr	g2_prepare_enemy_reflection_safe
.g2c57_player_blob_only
	tst	g2_blobshadow
	ble	.done
	bra	.g2c57_blob_after_colltype
	;
.try_blob
	tst	g2_blobshadow
	ble	.done
	; v127: bullets use colltype 1/2/4 and were visible in v126.
	; Real monsters use colltype 0 here, so keep shadows enemy-only.
	tst	ob_colltype(a2)
	bne	.done
.g2c57_blob_after_colltype
	tst	ob_hitpoints(a2)
	ble	.done
	; v128: keep blob shadows only in the near range.
	; Far floors are already heavily darkened by distance shading, and a fixed
	; palette blob can look brighter there.  About three map/texture widths
	; (=3*gs) is the visible cutoff.
	cmp	#3<<grdshft,d2
	bgt	.done
	; d7=start screen column, d3=visible clipped sprite width
	move	d7,g2_shadow_curx
	move	d7,d0
	move	d3,d1
	lsr	#1,d1
	add	d1,d0
	move	d0,g2_shadow_cx
	; v130: foot-width blob, not full body width.  Use about half the
	; visible sprite width as the total shadow width (radius = width/4).
	move	d3,d0
	lsr	#2,d0
	cmp	#3,d0
	bge	.rx_min_ok
	moveq	#3,d0
.rx_min_ok
	cmp	#16,d0
	ble	.rx_max_ok
	moveq	#16,d0
.rx_max_ok
	move	d0,g2_shadow_rx
	; v190hy3: anchor enemy blob shadows to the projected floor plane,
	; not to the lower edge of the visible sprite bitmap.  Flying monsters
	; can bob above the floor, but their shadow must stay on the ground.
	move	camy(pc),d0
	neg	d0
	ext.l	d0
	asl.l	#focshft,d0
	divs	d2,d0
	jsr	g2view_scale_y_d0	; keep VIEW SIZE scaling consistent with sprites
	add	midy(pc),d0
	cmp	#2,d0
	blt	.done
	move	hite(pc),d1
	sub	#6,d1
	cmp	d1,d0
	bgt	.done
	move	d0,g2_reflect_floorrow	; reused as absolute floor row for blob shadows
	moveq	#1,d0	;v129 fallback: darker blob shadow
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq	.col_ok
	move	#$111,d1	;v129: darker shadow tone
	move.b	0(a0,d1.w),d0
	bne	.col_ok
	move	#$222,d1
	move.b	0(a0,d1.w),d0
	bne	.col_ok
	moveq	#1,d0
.col_ok	move	d0,g2_shadow_col
	move	#1,g2_shadow_active
.done	movem.l	(a7)+,d0-d7/a0-a2
	rts

; c86y: safe mirrored enemy floor reflection; keep proven air-gap floor start.
; This intentionally does not reuse g2_shadow_active, g2_shadow_col or the blob
; draw routine.  The previous c86q attempt mixed these paths and could recolour
; blob shadows or read past sprite data.
g2_prepare_enemy_reflection_safe
	; d7=start screen column, d3=visible clipped sprite width, d4=visible height, d2=depth
	move	d2,g2_enemy_ref_z	;c86zb3 keep enemy depth for per-column cover blocking
	move	d7,g2_enemy_ref_curx
	move	d7,d0
	move	d3,d1
	lsr	#1,d1
	add	d1,d0
	move	d0,g2_enemy_ref_cx
	move	d3,d0
	lsr	#1,d0
	cmp	#4,d0
	bge.s	.rx_min_ok
	moveq	#4,d0
.rx_min_ok
	cmp	#28,d0
	ble.s	.rx_max_ok
	moveq	#28,d0
.rx_max_ok
	move	d0,g2_enemy_ref_rx
	; c86zc2: full-but-weak enemy reflection now builds with distance.
	; Keep the fuller silhouette when close, but avoid showing a tall reflection
	; immediately at range.  Visible sprite height is still the base, then a
	; distance cap controls how much of it can appear.
	move	d4,d0
	cmp	#2,d0
	bge.s	.rh_min_ok
	moveq	#2,d0
.rh_min_ok
	move	d2,d1
	cmp	#(1<<grdshft),d1
	blo.s	.rh_near
	cmp	#(2<<grdshft),d1
	blo.s	.rh_mid
	moveq	#5,d1		; far: max 5 rows
	bra.s	.rh_cap_apply
.rh_mid
	moveq	#12,d1		; medium: max 12 rows
	bra.s	.rh_cap_apply
.rh_near
	moveq	#24,d1		; close: max 24 rows
.rh_cap_apply
	cmp	d1,d0
	ble.s	.rh_max_ok
	move	d1,d0
.rh_max_ok
	move	d0,g2_enemy_ref_h
	; projected floor row, same anchor idea as confirmed blob shadows
	move	camy(pc),d0
	neg	d0
	ext.l	d0
	asl.l	#focshft,d0
	divs	d2,d0
	jsr	g2view_scale_y_d0
	add	midy(pc),d0
	cmp	#2,d0
	blt.s	.no_ref
	; c87b69e: full-screen RESOLUTION modes no longer need the old VIEW SIZE
	; edge rejection.  Keep the projected floor anchor inside the frame; the
	; draw path below shifts the complete prepared tail upward if required.
	move	hite(pc),d1
	subq	#2,d1
	cmp	d1,d0
	ble.s	.g2c87b69e_enemy_floor_ok
	move	d1,d0
.g2c87b69e_enemy_floor_ok
	; c86za: keep the grounded enemy reflection from c86y, but suppress
	; reflections for airborne/floating enemies entirely for now.  Their
	; pointed/uneven lower silhouettes still looked wrong mirrored.
	move	ob_y(a2),d1
	bpl.s	.airgap_done
	bra.s	.no_ref
.airgap_done
	move	d0,g2_enemy_ref_floorrow
	bsr	g2_enemy_reflection_blocked_by_cover
	tst	d0
	bne.s	.no_ref
	move	#1,g2_enemy_ref_active
	rts
.no_ref
	clr	g2_enemy_ref_active
	rts

; Draw a weak mirrored column by sampling the already-rendered sprite column
; above a4 and writing sparse/darkened pixels below the projected floor.
; This is a conservative visual probe: no source-shape pointer, no palette pointer,
; no blob-shadow colour reuse.
g2_draw_enemy_mirror_reflection_safe
	movem.l	d0-d7/a0-a3,-(a7)
	tst	g2_enemy_ref_active
	ble	.rts
	move	g2_enemy_ref_curx(pc),d0
	move	d0,d1
	sub	g2_enemy_ref_cx(pc),d1
	bpl.s	.abs_ok
	neg	d1
.abs_ok
	move	g2_enemy_ref_rx(pc),d2
	cmp	d2,d1
	bgt	.rts
	bsr	g2_enemy_reflection_current_column_blocked
	tst	d0
	bne	.rts
	move.l	chunkymod(pc),d7
	move.l	a4,a3
	sub.l	d7,a3	; first source sample: bottom visible sprite pixel
	move.l	chunky(pc),d0
	move	g2_enemy_ref_curx(pc),d3
	lsl	#2,d3
	lea	coloffs(pc),a0
	add.l	0(a0,d3.w),d0
	move.l	d0,a0
	move	g2_enemy_ref_floorrow(pc),d3
	addq	#1,d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a0
	; status/gun safety limit
	move.l	chunky(pc),d0
	move	g2_enemy_ref_curx(pc),d3
	lsl	#2,d3
	lea	coloffs(pc),a1
	add.l	0(a1,d3.w),d0
	move.l	d0,a1
	move	hite(pc),d3
	sub	#10,d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a1
	move	g2_enemy_ref_h(pc),d6
	subq	#1,d6
	blt	.rts
	; c87b69e: if the projected floor point is very low, move the complete
	; prepared reflection upward just enough to keep its height.  Previously the
	; per-row safety test shortened it again while approaching the object.
	move.l	a0,d0
	move	d6,d1
	ext.l	d1
	mulu.l	d7,d1
	add.l	d1,d0
	cmp.l	a1,d0
	bls.s	.g2c87b69e_enemy_tail_fits
	sub.l	a1,d0
	sub.l	d0,a0
.g2c87b69e_enemy_tail_fits
	moveq	#0,d5
.yloop
	cmp.l	a1,a0
	bhi	.rts
	; c86zc1: full but very weak enemy mirror.  The reflected silhouette is
	; taller/more complete, but only about 20 percent of the pixels survive
	; near the feet and less toward the tail.
	moveq	#8,d4		; top: less dither / more stable near the feet
	cmp	#3,d5
	blt.s	.dither_pick
	moveq	#5,d4		; early mid: still fuller than c86zc4
	cmp	#8,d5
	blt.s	.dither_pick
	moveq	#3,d4		; lower: coarse fade
	cmp	#14,d5
	blt.s	.dither_pick
	moveq	#1,d4		; tail: sparse end
.dither_pick
	; c87b63 STOCK: retain the mirror geometry but skip the ordered mask.
	tst	g2_bayer_disabled
	bne.s	.g2stock_enemy_ref_draw
	move	g2_enemy_ref_curx(pc),d0
	and	#3,d0
	move	d5,d1
	and	#3,d1
	lsl	#2,d1
	add	d0,d1
	lea	g2_enemy_ref_bayer4(pc),a2
	moveq	#0,d0
	move.b	0(a2,d1.w),d0
	cmp	d4,d0
	bge	.next
.g2stock_enemy_ref_draw
	moveq	#0,d0
	move.b	(a3),d0
	beq.s	.next
	; sampled pixel is already in the final chunky palette.  Do not map it again,
	; otherwise transparent/normal enemy columns can turn into wrong colours.
	move.b	d0,(a0)
.next
	add.l	d7,a0
	sub.l	d7,a3
	addq	#1,d5
	dbf	d6,.yloop
.rts	movem.l	(a7)+,d0-d7/a0-a3
	rts

; c86w/c86y 4x4 ordered threshold table for enemy-reflection transparency.
g2_enemy_ref_bayer4
	dc.b	0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5

; c86zb1: nearest transparent strip z per screen column.  Used to suppress
; enemy floor reflections while the enemy is still behind a door/window/strip.
g2_reflect_coverz	ds.w	g2render_max_width

; prepare coloured reflection under bullets or weapon upgrades.
; active=2 means reflection, active=1 means enemy blob shadow.
g2_prepare_reflection_column
	; d7=start screen column, d3=visible clipped sprite width, a2=object
	; v170: projectiles now cast a reflection about as wide as the visible
	; projectile itself.  Stationary weapon-upgrade reflections stay anchored
	; on the floor and only pulse lightly at the low/bottom part of their
	; bobbing/animation phase.
	cmp	#5<<grdshft,d2	;c86zdm: keep projectile/upgrade reflections visible farther
	bgt	.no_reflect
	move	d7,g2_shadow_curx
	move	d7,d0
	move	d3,d1
	lsr	#1,d1
	add	d1,d0
	move	d0,g2_shadow_cx
	clr	g2_reflect_pickup
	clr	g2_reflect_pulse	;c86zdi brief weapon-upgrade floor-touch pulse
	clr	g2_reflect_nearthick	;c86zdh distance class for vertical-only oval thickening
	bsr	g2_reflect_owner_is_pickup
	tst	d0
	beq	.bullet_size
	move	#1,g2_reflect_pickup
	; v182: weapon upgrades should read more like projectile reflections:
	; still clearly visible, but smaller in the distance and less oversized.
	move.l	ob_hit(a2),d1
	cmp.l	#weapongot,d1
	bne	.pick_token_size
	move	d3,d0
	lsr	#1,d0
	cmp	#3,d0
	bge	.wp_min_ok
	moveq	#3,d0
.wp_min_ok
	cmp	#16,d0
	ble	.wp_pulse
	moveq	#16,d0
.wp_pulse
	move	d0,d6		;c86zdm: remember unpulsed base radius for distance caps
	; c86zdq: weapon-upgrade pulse grows/shrinks with a longer envelope and
	; tops out at about 1.8x.  Width is handled by re-evaluated scaled
	; columns, not by stamping edge pixels outside the oval.
	move	ob_y(a2),d1
	cmp	#-36,d1
	blt	.pick_pulse_done
	cmp	#-16,d1
	bgt	.pick_pulse_done
	move	ob_movspeed(a2),d1
	and	#31,d1
	; c86zdq: longer true pulse envelope:
	; 1.0 -> 1.125 -> 1.25 -> 1.5 -> 1.8 -> 1.5 -> 1.25 -> 1.125 -> 1.0.
	cmp	#31,d1
	bgt	.pick_pulse_done
	cmp	#4,d1
	ble	.wp_pulse_l1
	cmp	#8,d1
	ble	.wp_pulse_l2
	cmp	#13,d1
	ble	.wp_pulse_l3
	cmp	#21,d1
	ble	.wp_pulse_l4
	cmp	#25,d1
	ble	.wp_pulse_l3
	cmp	#29,d1
	ble	.wp_pulse_l2
	bra	.wp_pulse_l1
.wp_pulse_l1
	move	#1,g2_reflect_pulse
	move	d6,d0
	move	d6,d1
	lsr	#3,d1
	add	d1,d0		;level 1: about 1.125x
	bra	.wp_pulse_distcap
.wp_pulse_l2
	move	#2,g2_reflect_pulse
	move	d6,d0
	move	d6,d1
	lsr	#2,d1
	add	d1,d0		;level 2: about 1.25x
	bra	.wp_pulse_distcap
.wp_pulse_l3
	move	#3,g2_reflect_pulse
	move	d6,d0
	move	d6,d1
	lsr	#1,d1
	add	d1,d0		;level 3: about 1.5x radius
	bra	.wp_pulse_distcap
.wp_pulse_l4
	move	#4,g2_reflect_pulse
	move	d6,d0
	move	d6,d1
	mulu	#13,d1
	lsr.l	#4,d1
	add	d1,d0		;level 4: about 1.8x radius at pulse peak
.wp_pulse_distcap
	cmp	#(3<<grdshft),d2
	blt	.wp_dist_mid_or_near
	clr	g2_reflect_pulse	;far: keep only the long, dark fade
	move	d6,d0
	bra	.wp_pulse_cap
.wp_dist_mid_or_near
	cmp	#(2<<grdshft),d2
	blt	.wp_dist_close_or_near
	cmp	#1,g2_reflect_pulse
	ble	.wp_mid_keep
	move	#1,g2_reflect_pulse
	move	d6,d0
	move	d6,d1
	lsr	#3,d1
	add	d1,d0
.wp_mid_keep
	bra	.wp_pulse_cap
.wp_dist_close_or_near
	cmp	#(1<<grdshft),d2
	blt	.wp_pulse_cap
	cmp	#3,g2_reflect_pulse
	ble	.wp_pulse_cap
	move	#3,g2_reflect_pulse
	move	d6,d0
	move	d6,d1
	lsr	#1,d1
	add	d1,d0
.wp_pulse_cap
	cmp	#32,d0
	ble	.pick_pulse_done
	moveq	#32,d0
	bra	.pick_pulse_done
.pick_token_size
	move	d3,d0
	; c86zcv: non-weapon token powerups were removed again; this remaining
	; path is for weapon/bouncy-style upgrades only.
	lsr	#1,d0
	cmp	#2,d0
	bge	.up_min_ok
	moveq	#2,d0
.up_min_ok
	cmp	#14,d0
	ble	.pick_pulse
	moveq	#14,d0
.pick_pulse
	; v185/c86zcv: stationary weapon-upgrade reflections stay visible at their base size.
	; Only the brief floor-touch moment should increase the oval.
	move	ob_y(a2),d1
	bpl.s	.pick_y_abs
	neg	d1
.pick_y_abs	cmp	#4,d1
	bgt	.pick_pulse_done
	move	d0,d1
	lsr	#1,d1
	add	d1,d0
	cmp	#21,d0
	ble	.pick_pulse_done
	moveq	#21,d0
.pick_pulse_done
	bra	.rx_ok
.bullet_size
	move	d3,d0
	; v170: projectile reflection diameter ~= projectile width, so radius
	; ~= visible width / 2 instead of the older smaller width / 3 shadow.
	lsr	#1,d0
	cmp	#2,d0
	bge	.bul_min_ok
	moveq	#2,d0
.bul_min_ok
	cmp	#16,d0
	ble	.rx_ok
	moveq	#16,d0
.rx_ok
	; c86zdh: keep projectile/upgrade reflection width exactly as before.
	; Only store a near-distance class so the draw path can make the
	; middle vertically thicker/rounder when the object is close.
	; c86zdm distance classes: -1 = far dark fade, 0 = normal,
	; 1 = close, 2 = very close.  Reflections now survive farther
	; than before, but the extra range is sparse/darkened.
	clr	g2_reflect_nearthick
	cmp	#(3<<grdshft),d2
	blt	.rx_not_far_fade
	move	#-1,g2_reflect_nearthick
	bra	.rx_store
.rx_not_far_fade
	cmp	#(2<<grdshft),d2
	bge	.rx_store
	move	#1,g2_reflect_nearthick
	cmp	#(1<<grdshft),d2
	bge	.rx_store
	move	#2,g2_reflect_nearthick
.rx_store
	move	d0,g2_shadow_rx
	; v181/c86zcv: stationary weapon upgrades get an absolute projected floor row, so their reflection
	; can be anchored to the same floor plane as projectile reflections
	; without following the bobbing sprite bitmap.  Projectiles keep the old
	; relative y-offset path.
	clr	g2_shadow_yoff
	clr	g2_reflect_floorrow
	tst	g2_reflect_pickup
	beq.s	.projectile_floor_yoff
	move	camy(pc),d0
	neg	d0
	ext.l	d0
	asl.l	#focshft,d0
	divs	d2,d0
	jsr	g2view_scale_y_d0	; v190hx7: reflection floor row scales with view height
	add	midy(pc),d0
	addq	#2,d0		; v189: back to the v186 pickup reflection baseline, but about 2px higher
	; v190hx12: safe anchor-only clipping for floor reflections.
	; Do not clamp an off-screen pickup reflection back into the 3D window
	; because that makes it slide along the VIEW SIZE edge.  Unlike hx11,
	; this does not touch the low-level reflection draw pointer path.
	cmp	#2,d0
	blt	.no_reflect
	; c87b69e: keep a near pickup/projectile reflection active at the lower
	; edge.  The column draw path fits its full prepared height safely.
	move	hite(pc),d1
	subq	#2,d1
	cmp	d1,d0
	ble.s	.g2c87b69e_pick_floor_ok
	move	d1,d0
.g2c87b69e_pick_floor_ok
	move	d0,g2_reflect_floorrow
	bra.s	.y_done
.projectile_floor_yoff
	move	ob_y(a2),d0
	neg	d0
.scale_yoff	ext.l	d0
	asl.l	#focshft,d0
	divs	d2,d0
	jsr	g2view_scale_y_d0	; v190hx7: reflection y offset scales with view height
	cmp	#30,d0
	ble	.ymax_ok
	moveq	#30,d0
.ymax_ok	cmp	#-16,d0
	bge	.ymin_ok
	move	#-16,d0
.ymin_ok	move	d0,g2_shadow_yoff
.y_done	bsr	g2_reflection_colour
	move	d0,g2_shadow_col
	move	#2,g2_shadow_active
	rts
.no_reflect	clr	g2_shadow_active
	rts

; c86zcv: narrow stationary weapon-upgrade/bouncy classifier used only by the reflection path.
g2_reflect_owner_is_pickup
	move.l	ob_logic(a2),d0
	cmp.l	#weaponlogic,d0
	beq.s	.yes
	cmp.l	#bouncylogic,d0
	beq.s	.yes
	move.l	ob_hit(a2),d0
	cmp.l	#bouncygot,d0
	beq.s	.yes
	cmp.l	#weapongot,d0
	beq.s	.yes
	moveq	#0,d0
	rts
.yes	moveq	#1,d0
	rts

g2_reflection_colour
	; v190dq: use one darker projectile/upgrade colour for the complete
	; reflection.  Edge dithering happens in the draw path, without the old
	; brighter rim colour that caused dirty/light borders.
	movem.l	d1-d3/a0,-(a7)
	moveq	#0,d2
	move.l	ob_shape(a2),d1
	cmp.l	#bullet1,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet2,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet3,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet4,d1
	beq	.got_weapon
	addq	#1,d2
	cmp.l	#bullet5,d1
	beq	.got_weapon
	; c86zcv: colour stationary weapon/bouncy upgrade reflections only.
	move.l	ob_logic(a2),d1
	cmp.l	#bouncylogic,d1
	beq	.got_bouncy
	move.l	ob_hit(a2),d1
	move	ob_weapon(a2),d2
	bra	.got_weapon
.got_bouncy	moveq	#1,d2	; green-ish
	bra	.got_weapon
.got_weapon
	and	#7,d2
	moveq	#2,d0	; dark centre/body fallback
	moveq	#15,d3	; bright sparse edge fallback
	move.l	planar_remap(pc),a0
	tst.l	a0
	beq	.store_edge
	lea	g2_reflect_dark_rgb(pc),a0
	move	0(a0,d2*2),d1
	move.l	planar_remap(pc),a0
	move.b	0(a0,d1.w),d0
	bne	.edge_colour
	moveq	#2,d0
.edge_colour	lea	g2_reflect_rgb(pc),a0
	move	0(a0,d2*2),d1
	move.l	planar_remap(pc),a0
	move.b	0(a0,d1.w),d3
	bne	.store_edge
	moveq	#15,d3
.store_edge	move	d0,g2_reflect_edge_col	; v190dq: edge uses same colour as body
	movem.l	(a7)+,d1-d3/a0
	rts

; RGB12 colours, remapped to the active Gloom palette at runtime.
; v174 weapon/projectile colours: 1 yellow, 2 green, 3 green/white,
; 4 blue/white, 5 magenta.  Dark table is the visible reflection body.
; The bright table is retained for compatibility but v190dq no longer uses
; it as a separate visible rim colour.
g2_reflect_dark_rgb
	dc	$520,$040,$030,$404,$404,$520,$040,$030	; v190du: weapon 4 colour only matches weapon 5
g2_reflect_rgb
	dc	$960,$0a0,$6f6,$66f,$a0a,$960,$0a0,$6f6

g2_draw_blob_column_before_sprite
	cmp	#1,g2_shadow_active
	beq.s	.draw_blob
	cmp	#2,g2_shadow_active
	bne.s	.rts
	bsr	g2_draw_projectile_reflection_column_before_sprite
	rts
.draw_blob
	bsr	g2_draw_enemy_blob_column
.rts	rts

; c86zcu: projectile / weapon-upgrade glow reflections are drawn before the
; owning bitmap column, so the actual shot/upgrade animation stays visibly
; in front of its reflection.  This deliberately does not re-enable any
; non-working healthkit/thermo/invisi/invinc token-reflection branches are absent.
; The old reflection routine expects a4 one row below the clipped sprite
; column, so synthesize that pointer from the current top pointer and d4.
g2_draw_projectile_reflection_column_before_sprite
	movem.l	d0-d3/d7/a4,-(a7)
	move.l	chunkymod(pc),d7
	move	d4,d0
.adj_loop
	adda.l	d7,a4
	dbf	d0,.adj_loop
	; c86zdp: draw the normal column first, then optionally draw one
	; real re-evaluated scaled column for the weapon-upgrade pulse.
	; Do not stamp edge pixels inside the y-loop.
	bsr	g2_draw_enemy_blob_column
	tst	g2_reflect_pickup
	beq	.done
	move	g2_reflect_pulse,d0
	beq	.done
	move	g2_shadow_curx(pc),d1
	move	d1,d2
	sub	g2_shadow_cx(pc),d2
	beq	.done
	bpl	.right_half
	neg	d2
	move	d2,d3
	cmp	#4,d0
	beq	.left_l4
	cmp	#3,d0
	beq	.left_l3
	cmp	#2,d0
	beq	.left_l2
	lsr	#3,d3
	bra	.left_have_extra
.left_l2
	lsr	#2,d3
	bra	.left_have_extra
.left_l3
	lsr	#1,d3
	bra	.left_have_extra
.left_l4
	mulu	#13,d3
	lsr.l	#4,d3
.left_have_extra
	tst	d3
	beq	.done
	sub	d3,d1
	blt	.done
	move	g2_shadow_curx(pc),d0
	move	d1,g2_shadow_curx
	bsr	g2_draw_enemy_blob_column
	move	d0,g2_shadow_curx
	bra	.done
.right_half
	move	d2,d3
	cmp	#4,d0
	beq	.right_l4
	cmp	#3,d0
	beq	.right_l3
	cmp	#2,d0
	beq	.right_l2
	lsr	#3,d3
	bra	.right_have_extra
.right_l2
	lsr	#2,d3
	bra	.right_have_extra
.right_l3
	lsr	#1,d3
	bra	.right_have_extra
.right_l4
	mulu	#13,d3
	lsr.l	#4,d3
.right_have_extra
	tst	d3
	beq	.done
	add	d3,d1
	cmp	g2render_last_x(pc),d1
	bgt	.done
	move	g2_shadow_curx(pc),d0
	move	d1,g2_shadow_curx
	bsr	g2_draw_enemy_blob_column
	move	d0,g2_shadow_curx
.done	movem.l	(a7)+,d0-d3/d7/a4
	rts

; c86zcu: coloured projectile/weapon-upgrade reflections now happen before
; their sprites.  The after-sprite pass remains only for mirrored enemy/player
; silhouettes because those sample the already-rendered sprite column.
g2_draw_reflection_column_after_sprite
	tst	g2_enemy_ref_active
	ble.s	.rts
	bsr	g2_draw_enemy_mirror_reflection_safe
.rts	rts

g2_draw_enemy_blob_column
	; called from drawobjnorm/drawobjtrans after the current sprite column was drawn.
	; a4 points one row below the drawn/clipped sprite column.
	movem.l	d0-d7/a0-a1,-(a7)
	tst	g2_shadow_active
	ble	.rts
	cmp	#2,g2_shadow_active
	beq	.reflection
	move	g2_shadow_curx(pc),d0
	move	d0,d1
	sub	g2_shadow_cx(pc),d1
	bpl	.abs_ok
	neg	d1
.abs_ok	move	g2_shadow_rx(pc),d2
	cmp	d2,d1
	bgt	.rts
	; v130: narrower, more oval hard-edged foot shadow.  The centre is
	; a little thicker, but the outer columns stay 1 pixel high so the shape
	; reads as an ellipse instead of a wide flat diamond/karo.
	moveq	#2,d5	;outer edge vertical offset
	moveq	#0,d6	;dbf count: 1 row
	move	d2,d3
	mulu	#7,d3
	lsr	#3,d3	;7/8 radius: thin outer edge
	cmp	d3,d1
	bgt	.have_band
	moveq	#1,d5
	moveq	#1,d6	;2 rows in broad mid band
	move	d2,d3
	lsr	#1,d3	;1/2 radius
	cmp	d3,d1
	bgt	.have_band
	moveq	#0,d5
	moveq	#2,d6	;3 rows in centre
	move	d2,d3
	lsr	#2,d3	;1/4 radius
	cmp	d3,d1
	bgt	.have_band
	moveq	#0,d5
	moveq	#2,d6	;keep hard oval centre, no tall diamond peak
.have_band
	move.l	chunkymod(pc),d7
	; v190hy3: draw the blob at the projected floor row.  The old path
	; started from a4 (sprite column bottom), so flying sprites dragged the
	; shadow upward with their animation/bob height.
	move.l	chunky(pc),d0
	move	g2_shadow_curx(pc),d3
	lsl	#2,d3
	lea	coloffs(pc),a0
	add.l	0(a0,d3.w),d0
	move.l	d0,a0
	move	g2_reflect_floorrow(pc),d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a0
	sub.l	d7,a0	; keep the confirmed v132/v130 blob vertical bias
	sub.l	d7,a0
	sub.l	d7,a0
	; skip down by start offset
	tst	d5
	beq	.draw
.offloop	adda.l	d7,a0
	subq	#1,d5
	bne	.offloop
.draw	move	g2_shadow_col(pc),d4
.yloop	move.b	d4,(a0)
	adda.l	d7,a0
	dbf	d6,.yloop
	bra	.rts
	;
.reflection
	move	g2_shadow_curx(pc),d0
	move	d0,d1
	sub	g2_shadow_cx(pc),d1
	bpl	.rabs_ok
	neg	d1
.rabs_ok	move	g2_shadow_rx(pc),d2
	cmp	d2,d1
	bgt	.rts
	; v172/c86zdj: projectile and weapon-upgrade reflections use a
	; rounder multi-band oval.  The old c86zdi centre became too tall while
	; the sides stayed immediately flat, which read as a T-shape when close.
	; Use four gradual horizontal bands instead: sparse outer rim, light mid,
	; dense inner body and rounded core.
	clr	g2_reflect_softedge
	tst	g2_reflect_pickup
	bne.s	.pickup_band
	moveq	#2,d5	;outer edge: low, sparse rim
	moveq	#0,d6	;1 row
	move	d2,d3
	mulu	#7,d3
	lsr	#3,d3	;7/8 radius: only far outer columns
	cmp	d3,d1
	bgt	.rsoft_outer
	moveq	#1,d5
	moveq	#1,d6	;2-row mid band
	move	d2,d3
	mulu	#5,d3
	lsr	#3,d3	;5/8 radius: broader rounded side band
	cmp	d3,d1
	bgt	.rsoft_mid
	moveq	#0,d5
	moveq	#2,d6	;3-row inner body
	move	d2,d3
	mulu	#3,d3
	lsr	#3,d3	;3/8 radius: inner body before core
	cmp	d3,d1
	bgt	.rbody_inner
	moveq	#0,d5
	moveq	#3,d6	;4-row rounded core at distance
	bra	.rband_ok
.pickup_band
	; Weapon-upgrade reflections share the same rounded oval family; pulse
	; scaling is applied later only for weapon upgrades near the low bob point.
	; c86zdr: at roughly 2+ texture widths the weapon-upgrade reflection was
	; still too tall.  Keep close/very-close height unchanged, but use a
	; lower vertical profile while g2_reflect_nearthick is still 0.
	tst	g2_reflect_nearthick
	bne.s	.pickup_near_band
	moveq	#2,d5	;distant outer edge: 1 sparse row
	moveq	#0,d6
	move	d2,d3
	mulu	#7,d3
	lsr	#3,d3	;7/8 radius
	cmp	d3,d1
	bgt	.rsoft_outer
	moveq	#1,d5
	moveq	#0,d6	;distant mid: 1 row, not 2
	move	d2,d3
	mulu	#5,d3
	lsr	#3,d3	;5/8 radius
	cmp	d3,d1
	bgt	.rsoft_mid
	moveq	#0,d5
	moveq	#1,d6	;distant inner: 2 rows
	move	d2,d3
	mulu	#3,d3
	lsr	#3,d3	;3/8 radius
	cmp	d3,d1
	bgt	.rbody_inner
	moveq	#0,d5
	moveq	#2,d6	;distant core: 3 rows max
	bra	.rband_ok
.pickup_near_band
	moveq	#2,d5	;outer edge: low, sparse rim
	moveq	#0,d6	;1 row
	move	d2,d3
	mulu	#7,d3
	lsr	#3,d3	;7/8 radius
	cmp	d3,d1
	bgt	.rsoft_outer
	moveq	#1,d5
	moveq	#1,d6	;2-row mid band
	move	d2,d3
	mulu	#5,d3
	lsr	#3,d3	;5/8 radius
	cmp	d3,d1
	bgt	.rsoft_mid
	moveq	#0,d5
	moveq	#2,d6	;3-row inner body
	move	d2,d3
	mulu	#3,d3
	lsr	#3,d3	;3/8 radius
	cmp	d3,d1
	bgt	.rbody_inner
	moveq	#0,d5
	moveq	#3,d6	;4-row rounded core at distance
	bra	.rband_ok
.rsoft_outer
	move	#2,g2_reflect_softedge	;outer edge: sparse dither
	bra	.rband_ok
.rsoft_mid
	move	#1,g2_reflect_softedge	;mid edge: light dither
	bra	.rband_ok
.rbody_inner
	move	#3,g2_reflect_softedge	;inner body: dense dither, not hard core
.rband_ok
	; c86zdm: in the extended far range keep the reflection alive,
	; but dark/sparse and low until it finally disappears farther away.
	move	g2_reflect_nearthick,d0
	bpl	.oval_not_far_fade
	moveq	#2,d5
	moveq	#0,d6		;far fade: one low row only
	move	#2,g2_reflect_softedge
	bra	.oval_v_done
.oval_not_far_fade
	; c86zdj: close projectiles/upgrades become vertically thicker through
	; gradual side/body/core steps instead of a single tall centre spike.
	beq	.oval_v_done
	move	g2_reflect_softedge(pc),d3
	cmp	#2,d3
	beq.s	.oval_v_done	;outer dither rim remains thin
	cmp	#1,d3
	bne.s	.oval_v_inner_or_core
	moveq	#1,d5
	moveq	#2,d6		;near mid: 3 rows
	cmp	#2,d0
	bne.s	.oval_v_done
	moveq	#1,d5
	moveq	#3,d6		;very near mid: 4 rows
	bra.s	.oval_v_done
.oval_v_inner_or_core
	cmp	#3,d3
	bne.s	.oval_v_core
	moveq	#0,d5
	moveq	#4,d6		;near inner body: 5 rows
	cmp	#2,d0
	bne.s	.oval_v_done
	moveq	#5,d6		;very near inner body: 6 rows
	bra.s	.oval_v_done
.oval_v_core
	moveq	#0,d5
	moveq	#5,d6		;near core: 6 rows
	cmp	#2,d0
	bne.s	.oval_v_done
	moveq	#6,d6		;very near core: 7 rows
.oval_v_done
	; c86zdq: weapon-upgrade floor-touch pulse swells smoothly up to about 1.8x.
	; g2_reflect_pulse is 0..4 from prepare: 1 ~= 1.125x, 2 ~= 1.25x,
	; 3 ~= 1.5x, 4 ~= 1.8x.  Height is shaped here; width is handled
	; by drawing one real scaled oval column in the before-sprite wrapper.
	move	g2_reflect_pulse,d0
	beq	.oval_pulse_done
	tst	g2_reflect_pickup
	beq	.oval_pulse_done
	; c86zdm: prevent distant weapon upgrades from pulsing taller than
	; near ones.  prepare already caps pulse by distance, but keep this
	; defensive clamp here too.
	tst	g2_reflect_nearthick
	bmi	.oval_pulse_done
	; c86zdr: at about 2 texture widths and farther, allow the width/envelope
	; pulse from prepare, but do not add extra vertical height.
	beq	.oval_pulse_done
	move	g2_reflect_softedge(pc),d3
	cmp	#2,d3
	beq.s	.oval_pulse_outer
	cmp	#1,d3
	beq.s	.oval_pulse_mid
	cmp	#3,d3
	beq.s	.oval_pulse_inner
	moveq	#0,d5
	moveq	#5,d6		;pulse core level 1: 6 rows
	cmp	#2,d0
	blt	.oval_pulse_done
	moveq	#6,d6		;pulse core level 2: 7 rows
	cmp	#3,d0
	blt	.oval_pulse_done
	moveq	#7,d6		;pulse core level 3: 8 rows
	cmp	#4,d0
	blt	.oval_pulse_done
	moveq	#8,d6		;pulse core level 4: 9 rows
	bra	.oval_pulse_done
.oval_pulse_inner
	moveq	#0,d5
	moveq	#4,d6		;pulse inner level 1: 5 rows
	cmp	#2,d0
	blt	.oval_pulse_done
	moveq	#5,d6		;pulse inner level 2: 6 rows
	cmp	#3,d0
	blt	.oval_pulse_done
	moveq	#6,d6		;pulse inner level 3: 7 rows
	cmp	#4,d0
	blt	.oval_pulse_done
	moveq	#7,d6		;pulse inner level 4: 8 rows
	bra	.oval_pulse_done
.oval_pulse_mid
	moveq	#1,d5
	moveq	#2,d6		;pulse mid level 1: 3 rows
	cmp	#2,d0
	blt	.oval_pulse_done
	moveq	#3,d6		;pulse mid level 2: 4 rows
	cmp	#3,d0
	blt	.oval_pulse_done
	moveq	#4,d6		;pulse mid level 3: 5 rows
	cmp	#4,d0
	blt	.oval_pulse_done
	moveq	#5,d6		;pulse mid level 4: 6 rows
	bra	.oval_pulse_done
.oval_pulse_outer
	moveq	#1,d5
	moveq	#1,d6		;pulse outer level 1/2: 2 sparse rows
	cmp	#3,d0
	blt	.oval_pulse_done
	moveq	#2,d6		;pulse outer level 3: 3 sparse rows
	cmp	#4,d0
	blt	.oval_pulse_done
	moveq	#3,d6		;pulse outer level 4: 4 sparse rows
.oval_pulse_done
	move.l	chunkymod(pc),d7
	tst	g2_reflect_pickup
	bne.s	.pick_anchor_a
	move.l	a4,a0
	sub.l	d7,a0
	sub.l	d7,a0
	; projectile path: relative floor-anchor from sprite underside.
	move	g2_shadow_yoff(pc),d3
	beq	.yoff_done
	bmi	.yoff_up
.yoff_down	adda.l	d7,a0
	subq	#1,d3
	bne	.yoff_down
	bra	.yoff_done
.yoff_up	neg	d3
.yoff_up_loop	suba.l	d7,a0
	subq	#1,d3
	bne	.yoff_up_loop
	bra.s	.yoff_done
.pick_anchor_a
	move.l	chunky(pc),d0
	move	g2_shadow_curx(pc),d4
	lsl	#2,d4
	lea	coloffs(pc),a0
	add.l	0(a0,d4.w),d0
	move.l	d0,a0
	move	g2_reflect_floorrow(pc),d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a0
	sub.l	d7,a0
	sub.l	d7,a0
.yoff_done
	; safety: never let reflections write into the status/gun area.
	move.l	chunky(pc),a1
	move	g2_shadow_curx(pc),d4
	lsl	#2,d4
	lea	coloffs(pc),a0
	add.l	0(a0,d4.w),a1
	move	hite(pc),d4
	sub	#10,d4
	mulu	chunkymodw(pc),d4
	add.l	d4,a1
	tst	g2_reflect_pickup
	bne.s	.pick_anchor_b
	move.l	a4,a0
	sub.l	d7,a0
	sub.l	d7,a0
	move	g2_shadow_yoff(pc),d3
	beq	.clamp_yoff_done
	bmi	.clamp_yoff_up
.clamp_yoff_down	adda.l	d7,a0
	subq	#1,d3
	bne	.clamp_yoff_down
	bra	.clamp_yoff_done
.clamp_yoff_up	neg	d3
.clamp_yoff_up_loop	suba.l	d7,a0
	subq	#1,d3
	bne	.clamp_yoff_up_loop
	bra.s	.clamp_yoff_done
.pick_anchor_b
	move.l	chunky(pc),d0
	move	g2_shadow_curx(pc),d3
	lsl	#2,d3
	lea	coloffs(pc),a0
	add.l	0(a0,d3.w),d0
	move.l	d0,a0
	move	g2_reflect_floorrow(pc),d3
	mulu	chunkymodw(pc),d3
	add.l	d3,a0
	sub.l	d7,a0
	sub.l	d7,a0
.clamp_yoff_done
	; c87b69e: preserve the chosen oval height near the lower edge.  Fit the
	; final DBF tail as one block instead of letting it disappear/shrink.
	move.l	a0,d0
	move	d6,d1
	add	d5,d1		; include the per-band start offset applied below
	ext.l	d1
	mulu.l	d7,d1
	add.l	d1,d0
	cmp.l	a1,d0
	bls.s	.g2c87b69e_reflect_tail_fits
	sub.l	a1,d0
	sub.l	d0,a0
.g2c87b69e_reflect_tail_fits
	cmp.l	a1,a0
	bhi	.rts
	tst	d5
	beq	.rdraw
.roffloop	adda.l	d7,a0
	subq	#1,d5
	bne	.roffloop
.rdraw	move	g2_shadow_col(pc),d4
		; c87b63 STOCK keeps the reflection geometry but bypasses the ordered
		; transparency mask and its per-row table/branch work.
		tst	g2_bayer_disabled
		bne.w	.g2stock_reflection_solid
		; c86zdm: complete reflection remains Bayer-dithered.  The
		; extended far range is deliberately much sparser/darker before
		; disappearing, instead of cutting off abruptly at the old range.
		tst	g2_reflect_nearthick
	bmi	.far_dither_setup
		moveq	#10,d3		; core threshold: dense but still dithered
		move	g2_reflect_softedge(pc),d0
		beq	.dither_setup
		move	g2_reflect_edge_col(pc),d4
		cmp	#2,d0
		beq	.outer_dither_setup
		cmp	#3,d0
		beq	.inner_dither_setup
		moveq	#7,d3		; mid edge: medium Bayer density
		bra	.dither_setup
.inner_dither_setup
		moveq	#9,d3		; inner body: dense, but less hard than core
		bra	.dither_setup
.outer_dither_setup
		moveq	#4,d3		; outer edge: sparse Bayer density
		bra	.dither_setup
.far_dither_setup
		moveq	#3,d3		;c86zdm far fade: very sparse/dark
.dither_setup
		moveq	#0,d5		; per-column reflection row for Bayer y
.ryloop
		move	g2_shadow_curx(pc),d0
		and	#3,d0
		move	d5,d1
		and	#3,d1
		lsl	#2,d1
		add	d0,d1
		lea	g2_enemy_ref_bayer4(pc),a1
		moveq	#0,d0
		move.b	0(a1,d1.w),d0
		cmp	d3,d0
		bge	.ryskip
		move.b	d4,(a0)
.ryskip
		adda.l	d7,a0
		addq	#1,d5
		dbf	d6,.ryloop
		bra.s	.rts
.g2stock_reflection_solid
		move.b	d4,(a0)
		adda.l	d7,a0
		dbf	d6,.g2stock_reflection_solid
.rts	movem.l	(a7)+,d0-d7/a0-a1
	rts

g2walls_precleared	dc.w	0
	even

; c87b69 / Gloombench 3O CLEAR16 dispatcher. Every active row-major owner
; (ECS, AGA and P96, ONE/TWO PLAYER, all four RESOLUTION modes) clears the
; compact world surface once, then drawsolidstrip writes wall texels only.
g2renderwalls_dispatch
	clr.w	g2walls_precleared
	tst.w	g2kalms_linear_active
	bne.s	.linear
	tst.w	p96gameplay_linear_active
	beq.w	renderwalls
.linear
	movem.l	d0-d3/a0,-(a7)
	move.l	chunky(pc),a0
	moveq	#0,d0
	move.w	width(pc),d0
	mulu	hite(pc),d0
	jsr	g2clear_bytes16
	movem.l	(a7)+,d0-d3/a0
	move.w	#-1,g2walls_precleared
	bsr	renderwalls
	clr.w	g2walls_precleared
	rts

renderwalls	;
	move.l	chunkymod(pc),d0
	move.l	vertdraws(pc),a0
	move.l	palette(pc),a2
	lea	palettes,a2
	lea	coloffs(pc),a6
	;
	move	width(pc),d7
	subq	#1,d7
	;
.loop	move.l	(a6)+,a1
	add.l	chunky(pc),a1
	;
	; v190ej: screen-X phase for wall shade-step Bayer blend.
	move	width(pc),d6
	subq	#1,d6
	sub	d7,d6
	move	d6,g2_bayer_x
	;
	drawsolidstrip
	;
	lea	vd_size(a0),a0
	dbf	d7,.loop
	;
	rts

solidstrip	set	0
drawstrip2	; v190bz chunky-safe transparent wall strip overlay with green glass
	; a1=top of destination column, a2=palettes base, a4=strip/vd data
	; Non-zero texels are drawn through the current wall palette.  Zero texels
	; are normally transparent, except for the original Gloom strip flag -6
	; where zero texels apply a green transparent filter to the already-rendered
	; chunky pixel behind the strip.
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	vd_data(a4),d0
	beq	.rts
	move.l	d0,a0		; source texture column, byte -1 is the strip flag
	moveq	#0,d6		; 0 = plain transparency on texel 0
	move.b	-1(a0),d6
	; v190cb: handle all original coloured transparent strip flags, not only
	; -6.  The classic renderer uses -7..-2 as coloured glass/mask selectors
	; and -1 as neutral transparency.  Some Deluxe green windows do not arrive
	; as exactly -6 after texture remapping, so treat every coloured flag as
	; green-tinted for this focused green-glass restoration pass.
	cmp.b	#$f9,d6		; -7..-2 are coloured flags
	bcs.s	.g2st_plain
	cmp.b	#$ff,d6		; -1 = neutral transparent/white, keep plain
	beq.s	.g2st_plain
	lea	g2_strip_green_lut,a6
	moveq	#1,d6
	bra.s	.g2st_mode_done
.g2st_plain
	moveq	#0,d6
.g2st_mode_done
	move.l	chunkymod(pc),d7
	move	vd_y(a4),d2
	add	midy(pc),d2	; screen Y start
	move.l	vd_ystep(a4),d3
	move	vd_h(a4),d4
	moveq	#0,d0		; texture Y start, 16.16 style after swap below
	tst	d2
	bpl.s	.notopclip
	add	d2,d4
	ble	.rts
	neg	d2
	ext.l	d2
	mulu.l	d3,d2
	move.l	d2,d0
	moveq	#0,d2
	bra.s	.clipdone
.notopclip
	beq.s	.clipdone
	move	d2,d5
	ext.l	d5
	mulu.l	d7,d5
	add.l	d5,a1
.clipdone
	move	hite(pc),d5
	sub	d2,d5
	ble	.rts
	cmp	d5,d4
	ble.s	.hiteok
	move	d5,d4
.hiteok
	subq	#1,d4
	blt	.rts
	swap	d0
	swap	d3
	sub	d3,d0
	add.l	d3,d0
	move	vd_pal(a4),d5
	move.l	0(a2,d5*4),a5
.loop
	move.b	0(a0,d0),d5
	beq.s	.zero
	move.b	0(a5,d5),(a1)
	bra.s	.advance
.zero
	tst	d6
	beq.s	.advance
	moveq	#0,d5
	move.b	(a1),d5
	move.b	0(a6,d5.w),(a1)
.advance
	addx.l	d3,d0
	add.l	d7,a1
	dbf	d4,.loop
.rts	movem.l	(a7)+,d0-d7/a0-a6
	rts

	dc	$f0ff,$ff0f,$fff0
	dc	$f00f,$f0f0,$ff00
	dc	$ffff
	;
stripands	;red,green,blue,yel,pur,cyn,wht

vwait	tst	os
	bne.s	.osvwait
	move	#1,vbcounter
.loop	tst	vbcounter
	bgt.s	.loop
	rts
.osvwait	movem.l	d0-d1/a0-a1/a6,-(a7)
	move.l	grbase(pc),a6
	jsr	-270(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a6
	rts

