; -----------------------------------------------------------------------------
; ECS6: title brush source-palette remapping
;
; pics_ehb/gloom may be exported independently and therefore have different
; colour indices from pics_ehb/title.  Its own pics_ehb/gloom.pal is loaded into
; gloombrushpal.  After decodeiff, each brush pixel is translated to the nearest
; of the 32 programmable title colours.  Index 0 remains transparent/black.
; -----------------------------------------------------------------------------

	even
gloombrushpal	dc.l	0
g2ecs6_brush_index_map	ds.b	64
	even
g2c87b12_brush_map_valid	dc	0
g2c87b12_brush_map_brush	dc.l	0
g2c87b12_brush_map_srcpal	dc.l	0
g2c87b12_brush_map_dstpal	dc.l	0
	even

; out: d0=-1 if map available, d0=0 if remapping cannot be performed.
g2ecs6_build_brush_index_map
	movem.l	d1-d7/a0-a5,-(a7)
	moveq	#0,d0
	move.l	gloombrush,d1
	beq.w	.done
	move.l	gloombrushpal,d1
	beq.w	.done
	move.l	gloompal,d1
	beq.w	.done

	; c87b12: reuse the map while all three loaded source pointers match.
	tst	g2c87b12_brush_map_valid
	beq.s	.g2c87b12_rebuild_map
	move.l	gloombrush,d1
	cmp.l	g2c87b12_brush_map_brush,d1
	bne.s	.g2c87b12_rebuild_map
	move.l	gloombrushpal,d1
	cmp.l	g2c87b12_brush_map_srcpal,d1
	bne.s	.g2c87b12_rebuild_map
	move.l	gloompal,d1
	cmp.l	g2c87b12_brush_map_dstpal,d1
	bne.s	.g2c87b12_rebuild_map
	moveq	#-1,d0
	bra.w	.done

.g2c87b12_rebuild_map
	clr	g2c87b12_brush_map_valid

	; Clear all 64 entries first.
	lea	g2ecs6_brush_index_map,a3
	moveq	#0,d1
	moveq	#63,d2
.clear_map
	move.b	d1,(a3)+
	dbf	d2,.clear_map

	move.l	gloombrushpal,a4	;source brush palette
	move.l	gloompal,a5		;active title palette
	lea	g2ecs6_brush_index_map,a3

	; Source entry count = 2^depth, capped at 64.
	move.l	gloombrush,a0
	moveq	#0,d7
	move	4(a0),d7
	cmp	#1,d7
	blo.w	.done
	cmp	#6,d7
	bls.s	.depth_ok
	moveq	#6,d7
.depth_ok
	moveq	#1,d2
	lsl	d7,d2			;source colour count
	move	d2,d7			;ECS8: keep count away from distance result d2
	moveq	#0,d6			;source index
.map_source
	cmp	d7,d6
	bge.s	.map_ready
	tst	d6
	bne.s	.nonzero_source
	clr.b	(a3)			;index 0 always remains index 0
	addq	#1,d6
	bra.s	.map_source

.nonzero_source
	move	d6,d0
	add	d0,d0
	move	0(a4,d0.w),d0		;source RGB12
	move	#32767,d5		;best distance
	moveq	#1,d4			;best target index
	moveq	#1,d3			;target visible EHB index 1..63
.find_target
	cmp	#64,d3
	bge.s	.store_target
	move	d3,d1
	add	d1,d1
	move	0(a5,d1.w),d1		;target RGB12
	jsr	g2ecs6_rgb12_distance
	cmp	d5,d2
	bge.s	.next_target
	move	d2,d5
	move	d3,d4
.next_target
	addq	#1,d3
	bra.s	.find_target

.store_target
	move.b	d4,0(a3,d6.w)
	addq	#1,d6
	bra.s	.map_source

.map_ready
	move.l	gloombrush,d1
	move.l	d1,g2c87b12_brush_map_brush
	move.l	gloombrushpal,d1
	move.l	d1,g2c87b12_brush_map_srcpal
	move.l	gloompal,d1
	move.l	d1,g2c87b12_brush_map_dstpal
	move	#-1,g2c87b12_brush_map_valid
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a5
	rts

; in: d0.w=RGB12 A, d1.w=RGB12 B
; out: d2.w=Manhattan distance; d0/d1/d3/d4 preserved.
g2ecs6_rgb12_distance
	movem.l	d0-d1/d3-d4,-(a7)
	moveq	#0,d2

	move	d0,d3
	and	#$0f00,d3
	lsr	#8,d3
	move	d1,d4
	and	#$0f00,d4
	lsr	#8,d4
	sub	d4,d3
	bpl.s	.red_positive
	neg	d3
.red_positive
	add	d3,d2

	move	d0,d3
	and	#$00f0,d3
	lsr	#4,d3
	move	d1,d4
	and	#$00f0,d4
	lsr	#4,d4
	sub	d4,d3
	bpl.s	.green_positive
	neg	d3
.green_positive
	add	d3,d2

	move	d0,d3
	and	#$000f,d3
	move	d1,d4
	and	#$000f,d4
	sub	d4,d3
	bpl.s	.blue_positive
	neg	d3
.blue_positive
	add	d3,d2

	movem.l	(a7)+,d0-d1/d3-d4
	rts

; in: a1 = destination bitmap address at the first brush row
g2ecs6_remap_brush_bitmap
	movem.l	d0-d7/a0-a6,-(a7)
	jsr	g2ecs6_build_brush_index_map
	tst	d0
	beq.w	.done

	move.l	gloombrush,a4
	moveq	#0,d7
	move	(a4),d7		;width
	beq.w	.done
	cmp	#320,d7
	bls.s	.width_ok
	move	#320,d7
.width_ok
	moveq	#0,d6
	move	2(a4),d6		;height
	beq.w	.done
	cmp	#72,d6
	bls.s	.height_ok
	moveq	#72,d6
.height_ok
	lea	g2ecs6_brush_index_map,a5
	move.l	a1,a6		;first row, plane 0
	moveq	#0,d4		;row index

.row_loop
	cmp	d6,d4
	bge.w	.done
	moveq	#0,d5		;x

.pixel_loop
	cmp	d7,d5
	bge.w	.next_row

	; Locate byte and bit for this pixel in plane 0.
	move	d5,d0
	lsr	#3,d0
	move.l	a6,a0
	adda.w	d0,a0
	move	d5,d3
	and	#7,d3
	moveq	#7,d0
	sub	d3,d0
	move	d0,d3		;bit number 7..0

	; Read the source brush index now present in the destination.
	moveq	#0,d0
	moveq	#0,d2
	move.l	a0,a2
.read_plane
	cmp	bitplanes,d2
	bge.s	.have_source_index
	btst	d3,(a2)
	beq.s	.read_next
	bset	d2,d0
.read_next
	adda.l	bpmod,a2
	addq	#1,d2
	bra.s	.read_plane

.have_source_index
	tst	d0
	bne.s	.map_nonzero

	; Source index 0 is transparent for Gloom/Gloom Deluxe.  c87b27: the
	; Zombie Massacre g3-dc brush uses index 0 as real opaque black, so route
	; it through the normal map (map[0]=0) instead of restoring title pixels.
	cmp	#2,g2_game_profile
	beq.s	.map_nonzero
	move	d4,d1
	mulu	#40,d1
	move	d5,d2
	lsr	#3,d2
	add	d2,d1
	lea	g2ecs7_brush_background,a3
	adda.w	d1,a3
	moveq	#0,d1		;restored destination index
	moveq	#0,d2		;plane
.restore_read_plane
	cmp	bitplanes,d2
	bge.s	.have_dest_index
	btst	d3,(a3)
	beq.s	.restore_read_next
	bset	d2,d1
.restore_read_next
	adda.w	#2880,a3	;40 * 72 bytes per compact plane
	addq	#1,d2
	bra.s	.restore_read_plane

.map_nonzero
	moveq	#0,d1
	move.b	0(a5,d0.w),d1

.have_dest_index
	; Write restored or remapped index back to all active planes.
	moveq	#0,d2
	move.l	a0,a2
.write_plane
	cmp	bitplanes,d2
	bge.s	.pixel_done
	btst	d2,d1
	beq.s	.clear_bit
	bset	d3,(a2)
	bra.s	.write_next
.clear_bit
	bclr	d3,(a2)
.write_next
	adda.l	bpmod,a2
	addq	#1,d2
	bra.s	.write_plane

.pixel_done
	addq	#1,d5
	bra.w	.pixel_loop

.next_row
	adda.l	linemod,a6
	addq	#1,d4
	bra.w	.row_loop

.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts
	;ECS9_A600_PREFLIGHT_NOFLASH: retained rollback guard for unsupported profiles.
	;c87b22 compiles it out because Gloom3/Zombie Massacre use Fast-EHB data.
	;The old request text remains below as a range-stable rollback aid.
; -----------------------------------------------------------------------------
; ECS9: early ECS data-profile compatibility guard
;
; Runs after DOS/current-directory and DISPLAY parsing, but before P96 probes,
; memory allocation, initmain, screen creation, interrupts, sound or asset load.
;
; c87b22 keeps g2ecs_profile_guard_enabled at zero.  The routine remains in
; the source only as a range-stable rollback aid for incomplete data packages.
; -----------------------------------------------------------------------------

	even
g2ecs9_cli_zm
	dc.b	10,'Zombie Massacre does not have ECS support yet.',10
	dc.b	'Start this data set with DISPLAY=AGA or DISPLAY=P96.',10,10
g2ecs9_cli_zm_end
g2ecs9_cli_zm_len	equ	g2ecs9_cli_zm_end-g2ecs9_cli_zm

g2ecs9_cli_g3
	dc.b	10,'Gloom 3 does not have ECS support yet.',10
	dc.b	'Start this data set with DISPLAY=AGA or DISPLAY=P96.',10,10
g2ecs9_cli_g3_end
g2ecs9_cli_g3_len	equ	g2ecs9_cli_g3_end-g2ecs9_cli_g3

g2ecs9_req_title	dc.b	'Gloom Reforged ECS',0
g2ecs9_req_zm_body
	dc.b	'Zombie Massacre does not have ECS support yet.',10
	dc.b	'Use DISPLAY=AGA or DISPLAY=P96.',0
g2ecs9_req_g3_body
	dc.b	'Gloom 3 does not have ECS support yet.',10
	dc.b	'Use DISPLAY=AGA or DISPLAY=P96.',0
g2ecs9_req_ok	dc.b	'OK',0
	even

g2ecs9_req_zm
	dc.l	20
	dc.l	0
	dc.l	g2ecs9_req_title
	dc.l	g2ecs9_req_zm_body
	dc.l	g2ecs9_req_ok

g2ecs9_req_g3
	dc.l	20
	dc.l	0
	dc.l	g2ecs9_req_title
	dc.l	g2ecs9_req_g3_body
	dc.l	g2ecs9_req_ok

; out: d0=0 continue, d0=-1 abort
g2ecs_early_profile_preflight
	movem.l	d1-d7/a0-a6,-(a7)
	moveq	#0,d7

	; AGA and P96 retain all existing profile support.
	cmp	#3,g2display_mode
	bne.w	.done

	; DOS is already open and the Workbench current directory has been set.
	; Reuse the exact existing profile detector before any game subsystem starts.
	jsr	g2detectprofile
	cmp	#2,g2_game_profile
	beq.s	.zombie
	cmp	#3,g2_game_profile
	beq.s	.gloom3
	bra.w	.done			;profiles 0/1: Deluxe/Classic may start ECS

.zombie
	moveq	#2,d6
	bra.s	.unsupported
.gloom3
	moveq	#3,d6

.unsupported
	moveq	#-1,d7
	tst.l	wbmess
	bne.s	.workbench

	; CLI launch: write directly to the current AmigaDOS Output().
	move.l	dosbase,d0
	beq.w	.done
	move.l	outhand,d1
	beq.w	.done
	cmp	#2,d6
	bne.s	.cli_g3
	lea	g2ecs9_cli_zm,a0
	move.l	a0,d2
	move.l	#g2ecs9_cli_zm_len,d3
	bra.s	.cli_write
.cli_g3
	lea	g2ecs9_cli_g3,a0
	move.l	a0,d2
	move.l	#g2ecs9_cli_g3_len,d3
.cli_write
	move.l	dosbase,a6
	jsr	-48(a6)			;dos.library/Write
	bra.w	.done

.workbench
	; Workbench launch: show an ordinary EasyRequestArgs on the public screen.
	move.l	4.w,a6
	lea	g2early_intuition_name,a1
	jsr	-408(a6)		;OldOpenLibrary intuition.library
	move.l	d0,d5
	beq.w	.done
	move.l	d0,a6
	suba.l	a0,a0
	cmp	#2,d6
	bne.s	.req_g3
	lea	g2ecs9_req_zm,a1
	bra.s	.req_show
.req_g3
	lea	g2ecs9_req_g3,a1
.req_show
	suba.l	a2,a2
	suba.l	a3,a3
	jsr	-588(a6)		;EasyRequestArgs
	move.l	d5,a1
	move.l	4.w,a6
	jsr	-414(a6)		;CloseLibrary

.done
	move	d7,d0
	movem.l	(a7)+,d1-d7/a0-a6
	rts


; -----------------------------------------------------------------------------
; c87b25: shared fog colour for NASTY world decals.
; in: d0.w = camera-space depth.  out: g2bp_col = active chunky palette index.
; Uses the same DEFAULT/ADVANCED distance scaling, darktable and red shade ramp
; already used by the mobile blood renderer.  This changes colour only; decal
; world anchors, projection, depth tests and adaptive raster density are intact.
; -----------------------------------------------------------------------------
g2bp_set_fog_colour
	movem.l	d0-d4/a0,-(a7)
	move	d0,d3
	tst	g2_visibility
	bgt.s	.g2bpfog_adv
	cmp	#(4<<grdshft),d3
	blo.s	.g2bpfog_lookup
	sub	#(4<<grdshft),d3
	add	d3,d3
	add	#(4<<grdshft),d3
	cmp	#maxz-1,d3
	bls.s	.g2bpfog_lookup
	move	#maxz-1,d3
	bra.s	.g2bpfog_lookup
.g2bpfog_adv
	; Match the confirmed object/blood ADVANCED mapping:
	; distance/2 + distance/8 + distance/32 + distance/64.
	move	d3,d4
	lsr	#1,d3
	move	d4,d0
	lsr	#3,d0
	add	d0,d3
	lsr	#2,d0
	add	d0,d3
	lsr	#1,d0
	add	d0,d3
	cmp	#maxz-1,d3
	bls.s	.g2bpfog_lookup
	move	#maxz-1,d3
.g2bpfog_lookup
	move.l	darktable,a0
	tst.l	a0
	beq.s	.g2bpfog_fallback
	move	0(a0,d3*2),d3
	lea	blcols,a0
	move	0(a0,d3*2),d3
	and	#$0f00,d3		; red blood mask, smoothly $c00..$100
	move.l	planar_remap,a0
	tst.l	a0
	beq.s	.g2bpfog_fallback
	moveq	#0,d4
	move.b	0(a0,d3.w),d4	; index 0 is valid final fog/black
	bra.s	.g2bpfog_store
.g2bpfog_fallback
	moveq	#12,d4
.g2bpfog_store
	move	d4,g2bp_col
	movem.l	(a7)+,d0-d4/a0
	rts


; -----------------------------------------------------------------------------
; c87b26: compact always-on basic diagnostics.
;
; RAM:gloom_basic.log is recreated once per launch, then receives bounded
; one-shot snapshots for STARTUP, TITLE, GAME and (when applicable) P96_LINEAR.
; No per-frame writes occur.  Values are hexadecimal so pointers, ModeIDs and
; signed geometry can be compared byte-for-byte between systems.
; -----------------------------------------------------------------------------
g2basic_log_name	dc.b	'RAM:gloom_basic.log',0
	even
; c87b70e: g2build_version_text is stored once at the end of the source.
g2basic_log_header_prefix	dc.b	'Gloom Reforged '
g2basic_log_header_prefix_end
g2basic_log_header_prefix_len	equ	g2basic_log_header_prefix_end-g2basic_log_header_prefix
g2basic_log_header_suffix
	dc.b	' basic display log',10
	dc.b	'Values are hexadecimal; FFFFFFFF means -1/YES.',10
	dc.b	'Please send this complete file with the problem report.',10
	dc.b	10
g2basic_log_header_suffix_end
g2basic_log_header_suffix_len	equ	g2basic_log_header_suffix_end-g2basic_log_header_suffix

g2basic_stage_start	dc.b	'--- STARTUP ---',10
g2basic_stage_start_end
g2basic_stage_start_len	equ	g2basic_stage_start_end-g2basic_stage_start
g2basic_stage_title	dc.b	'--- TITLE ---',10
g2basic_stage_title_end
g2basic_stage_title_len	equ	g2basic_stage_title_end-g2basic_stage_title
g2basic_stage_game	dc.b	'--- GAME ---',10
g2basic_stage_game_end
g2basic_stage_game_len	equ	g2basic_stage_game_end-g2basic_stage_game
g2basic_stage_p96	dc.b	'--- P96_LINEAR ---',10
g2basic_stage_p96_end
g2basic_stage_p96_len	equ	g2basic_stage_p96_end-g2basic_stage_p96
	even

g2basic_log_block
	dc.b	'DISPLAY_MODE=$'
g2basic_display_hex	ds.b	8
	dc.b	' SOURCE=$'
g2basic_source_hex	ds.b	8
	dc.b	' PROFILE=$'
g2basic_profile_hex	ds.b	8
	dc.b	10,'CHIPSET_AGA=$'
g2basic_chipset_hex	ds.b	8
	dc.b	' RUNTIME_AGA=$'
g2basic_aga_hex	ds.b	8
	dc.b	' OS=$'
g2basic_os_hex	ds.b	8
	dc.b	10,'BITPLANES=$'
g2basic_bitplanes_hex	ds.b	8
	dc.b	' COLOURS=$'
g2basic_colours_hex	ds.b	8
	dc.b	' FAST_EHB=$'
g2basic_fastehb_hex	ds.b	8
	dc.b	10,'P96_HIRES=$'
g2basic_hires_hex	ds.b	8
	dc.b	' STRETCH=$'
g2basic_stretch_hex	ds.b	8
	dc.b	' WIDE=$'
g2basic_wide_hex	ds.b	8
	dc.b	' FIVE_TO_FOUR=$'
g2basic_5to4_hex	ds.b	8
	dc.b	10,'TARGET_W=$'
g2basic_targetw_hex	ds.b	8
	dc.b	' TARGET_H=$'
g2basic_targeth_hex	ds.b	8
	dc.b	' TARGET_MODE=$'
g2basic_targetmode_hex	ds.b	8
	dc.b	10,'MODEID=$'
g2basic_modeid_hex	ds.b	8
	dc.b	' RGBFORMAT=$'
g2basic_rgbformat_hex	ds.b	8
	dc.b	' P96_LINEAR=$'
g2basic_linear_hex	ds.b	8
	dc.b	10,'RENDER_W=$'
g2basic_renderw_hex	ds.b	8
	dc.b	' RENDER_STRIDE=$'
g2basic_stride_hex	ds.b	8
	dc.b	' VIEW_W=$'
g2basic_vieww_hex	ds.b	8
	dc.b	' VIEW_H=$'
g2basic_viewh_hex	ds.b	8
	dc.b	10,'MINX=$'
g2basic_minx_hex	ds.b	8
	dc.b	' MAXX=$'
g2basic_maxx_hex	ds.b	8
	dc.b	' MINY=$'
g2basic_miny_hex	ds.b	8
	dc.b	' MAXY=$'
g2basic_maxy_hex	ds.b	8
	dc.b	10,'LINEMOD=$'
g2basic_linemod_hex	ds.b	8
	dc.b	' BPMOD=$'
g2basic_bpmod_hex	ds.b	8
	dc.b	10,'TITLE_PTR=$'
g2basic_titleptr_hex	ds.b	8
	dc.b	' TITLE_W=$'
g2basic_titlew_hex	ds.b	8
	dc.b	' TITLE_H=$'
g2basic_titleh_hex	ds.b	8
	dc.b	' TITLE_DEPTH=$'
g2basic_titledepth_hex	ds.b	8
	dc.b	10,'STATIC_W=$'
g2basic_staticw_hex	ds.b	8
	dc.b	' STATIC_H=$'
g2basic_statich_hex	ds.b	8
	dc.b	' STATIC_VALID=$'
g2basic_staticvalid_hex	ds.b	8
	dc.b	10,10
g2basic_log_block_end
g2basic_log_block_len	equ	g2basic_log_block_end-g2basic_log_block
	even

g2basic_title_logged	dc	0
g2basic_game_logged	dc	0
g2basic_p96_logged	dc	0

; Recreate the file on each launch, write the header, then append STARTUP.
g2basic_log_reset
	movem.l	d0-d7/a0-a1/a6,-(a7)
	clr	g2basic_title_logged
	clr	g2basic_game_logged
	clr	g2basic_p96_logged
	move.l	dosbase,d0
	beq	.g2basic_reset_done
	move.l	d0,a6
	lea	g2basic_log_name,a0
	move.l	a0,d1
	move.l	#1006,d2		; MODE_NEWFILE
	jsr	-30(a6)		; Open
	move.l	d0,d7
	beq.s	.g2basic_reset_done
	move.l	d7,d1
	lea	g2basic_log_header_prefix,a0
	move.l	a0,d2
	move.l	#g2basic_log_header_prefix_len,d3
	jsr	-48(a6)		; Write prefix
	move.l	d7,d1
	lea	g2build_version_text,a0
	move.l	a0,d2
	move.l	#g2build_version_text_len,d3
	jsr	-48(a6)		; Write canonical build version
	move.l	d7,d1
	lea	g2basic_log_header_suffix,a0
	move.l	a0,d2
	move.l	#g2basic_log_header_suffix_len,d3
	jsr	-48(a6)		; Write suffix
	; c87b70l: duplicate the copy-ready ID as its own block near the top.
	cmp	#1,p96modeid_state
	bne	.g2basic_no_modeid_highlight
	move.l	p96modeid,d0
	lea	g2basic_p96modeid_tooltype_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	d7,d1
	lea	g2basic_p96modeid_tooltype_block,a0
	move.l	a0,d2
	move.l	#g2basic_p96modeid_tooltype_block_len,d3
	jsr	-48(a6)
.g2basic_no_modeid_highlight
	move.l	d7,d1
	jsr	-36(a6)		; Close
.g2basic_reset_done
	movem.l	(a7)+,d0-d7/a0-a1/a6
	moveq	#0,d0
	bra	g2basic_log_snapshot

g2basic_log_title_once
	tst	g2basic_title_logged
	bne.s	.g2basic_title_done
	move	#-1,g2basic_title_logged
	moveq	#1,d0
	bra	g2basic_log_snapshot
.g2basic_title_done
	rts

g2basic_log_game_once
	tst	g2basic_game_logged
	bne.s	.g2basic_game_done
	move	#-1,g2basic_game_logged
	moveq	#2,d0
	bra	g2basic_log_snapshot
.g2basic_game_done
	rts

g2basic_log_p96_once
	tst	g2basic_p96_logged
	bne.s	.g2basic_p96_done
	move	#-1,g2basic_p96_logged
	; Rebuild once from the currently installed palette so the compact P96
	; snapshot records the exact active conversion state.
	jsr	g2p96_gameplay_build_rgb565_source_lut
	moveq	#3,d0
	jsr	g2basic_log_snapshot
.g2basic_p96_done
	rts

; in d0.w: 0 STARTUP, 1 TITLE, 2 GAME, 3 P96_LINEAR.
g2basic_log_snapshot
	movem.l	d0-d7/a0-a3/a6,-(a7)
	move	d0,d6
	moveq	#0,d0
	move	g2display_mode,d0
	lea	g2basic_display_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2display_source,d0
	lea	g2basic_source_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2_game_profile,d0
	lea	g2basic_profile_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2chipset_aga,d0
	ext.l	d0
	lea	g2basic_chipset_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	aga,d0
	ext.l	d0
	lea	g2basic_aga_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	os,d0
	ext.l	d0
	lea	g2basic_os_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	bitplanes,d0
	lea	g2basic_bitplanes_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	colours,d0
	lea	g2basic_colours_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2ecs_fast_assets_enabled,d0
	ext.l	d0
	lea	g2basic_fastehb_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2p96_hires_mode,d0
	ext.l	d0
	lea	g2basic_hires_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2p96_stretch_mode,d0
	ext.l	d0
	lea	g2basic_stretch_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2p96_wide_mode,d0
	ext.l	d0
	lea	g2basic_wide_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2p96_oneone_mode,d0
	ext.l	d0
	lea	g2basic_5to4_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96target_width,d0
	lea	g2basic_targetw_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96target_height,d0
	lea	g2basic_targeth_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96target_mode,d0
	lea	g2basic_targetmode_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	p96modeid,d0
	lea	g2basic_modeid_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	p96modeid_rgbformat,d0
	lea	g2basic_rgbformat_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96gameplay_linear_active,d0
	ext.l	d0
	lea	g2basic_linear_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2render_width,d0
	lea	g2basic_renderw_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	g2render_stride,d0
	lea	g2basic_stride_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	width,d0
	lea	g2basic_vieww_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	hite,d0
	lea	g2basic_viewh_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	minx,d0
	ext.l	d0
	lea	g2basic_minx_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	maxx,d0
	ext.l	d0
	lea	g2basic_maxx_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	miny,d0
	ext.l	d0
	lea	g2basic_miny_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	maxy,d0
	ext.l	d0
	lea	g2basic_maxy_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	linemod,d0
	lea	g2basic_linemod_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	bpmod,d0
	lea	g2basic_bpmod_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	gloom,d0
	move.l	d0,d5
	lea	g2basic_titleptr_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	tst.l	d5
	beq.s	.g2basic_no_title
	move.l	d5,a3
	move	(a3),d0
	move	2(a3),d1
	move	4(a3),d2
.g2basic_no_title
	lea	g2basic_titlew_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	d1,d0
	lea	g2basic_titleh_hex,a0
	jsr	g2p96_long_to_hex8
	move.l	d2,d0
	lea	g2basic_titledepth_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96static_direct_width,d0
	lea	g2basic_staticw_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96static_direct_height,d0
	lea	g2basic_statich_hex,a0
	jsr	g2p96_long_to_hex8
	moveq	#0,d0
	move	p96static_direct_valid,d0
	ext.l	d0
	lea	g2basic_staticvalid_hex,a0
	jsr	g2p96_long_to_hex8

	move.l	dosbase,d0
	beq.w	.g2basic_snap_done
	move.l	d0,a6
	lea	g2basic_log_name,a0
	move.l	a0,d1
	move.l	#1004,d2		; MODE_READWRITE
	jsr	-30(a6)		; Open
	move.l	d0,d7
	bne.s	.g2basic_have_file
	lea	g2basic_log_name,a0
	move.l	a0,d1
	move.l	#1006,d2		; MODE_NEWFILE fallback
	jsr	-30(a6)
	move.l	d0,d7
	beq.w	.g2basic_snap_done
.g2basic_have_file
	move.l	d7,d1
	moveq	#0,d2
	moveq	#1,d3			; OFFSET_END
	jsr	-66(a6)		; Seek
	cmp	#1,d6
	beq.s	.g2basic_write_title
	cmp	#2,d6
	beq.s	.g2basic_write_game
	cmp	#3,d6
	beq.s	.g2basic_write_p96
	lea	g2basic_stage_start,a0
	move.l	#g2basic_stage_start_len,d3
	bra.s	.g2basic_write_stage
.g2basic_write_title
	lea	g2basic_stage_title,a0
	move.l	#g2basic_stage_title_len,d3
	bra.s	.g2basic_write_stage
.g2basic_write_game
	lea	g2basic_stage_game,a0
	move.l	#g2basic_stage_game_len,d3
	bra.s	.g2basic_write_stage
.g2basic_write_p96
	lea	g2basic_stage_p96,a0
	move.l	#g2basic_stage_p96_len,d3
.g2basic_write_stage
	move.l	d7,d1
	move.l	a0,d2
	jsr	-48(a6)		; Write stage
	move.l	d7,d1
	lea	g2basic_log_block,a0
	move.l	a0,d2
	move.l	#g2basic_log_block_len,d3
	jsr	-48(a6)		; Write values
	move.l	d7,d1
	jsr	-36(a6)		; Close
.g2basic_snap_done
	movem.l	(a7)+,d0-d7/a0-a3/a6
	rts

; -----------------------------------------------------------------------------
; c87b32: immutable generated ECS/EHB intermission palettes
;
; The editor-exported 128-byte .pal files are embedded byte-for-byte.  This
; removes DOS state, temporary allocation, START LEVEL skipping and stale
; lastpal/picpal pointers from palette selection.  The basename of the current
; pict_ command selects the exact profile-specific palette.
; -----------------------------------------------------------------------------

g2ecs_load_g3zm_intermission_palette_embedded
	movem.l	d0-d7/a0-a4,-(a7)
	clr	g2ecs_inter_palette_cache_valid
	jsr	g2ecs_inter_select_embedded_palette
	tst.l	d0
	beq.w	.done
	move.l	d0,a0
	lea	g2ecs_inter_palette_cache,a1
	moveq	#31,d7	; 32 longs = exact 128-byte generated palette
.copy
	move.l	(a0)+,(a1)+
	dbf	d7,.copy
	move	#-1,g2ecs_inter_palette_cache_valid
.done
	movem.l	(a7)+,d0-d7/a0-a4
	rts

g2ecs_inter_select_embedded_palette
	movem.l	d1-d3/a0-a4,-(a7)
	moveq	#0,d0
	tst	aga
	bne.w	.done
	cmp	#2,g2_game_profile
	beq.s	.zm
	cmp	#3,g2_game_profile
	bne.w	.done
	lea	g2ecs_emb_g3_palette_table,a3
	bra.s	.have_table
.zm
	lea	g2ecs_emb_zm_palette_table,a3
.have_table
	lea	g2v190t_lastpicname,a0
	tst.b	(a0)
	beq.w	.done
	move.l	a0,a2
.path_scan
	moveq	#0,d1
	move.b	(a0)+,d1
	beq.s	.have_base
	cmp.b	#'/',d1
	beq.s	.new_base
	cmp.b	#':',d1
	bne.s	.path_scan
.new_base
	move.l	a0,a2
	bra.s	.path_scan
.have_base
.next_record
	move.l	(a3),d0
	beq.s	.not_found
	move.l	a2,a0
	lea	4(a3),a4
.compare
	moveq	#0,d1
	moveq	#0,d2
	move.b	(a0)+,d1
	move.b	(a4)+,d2
	cmp.b	#'A',d1
	bcs.s	.fold2
	cmp.b	#'Z',d1
	bhi.s	.fold2
	or.b	#$20,d1
.fold2
	cmp.b	#'A',d2
	bcs.s	.compare_now
	cmp.b	#'Z',d2
	bhi.s	.compare_now
	or.b	#$20,d2
.compare_now
	cmp.b	d2,d1
	bne.s	.no_match
	tst.b	d1
	bne.s	.compare
	move.l	(a3),d0
	bra.s	.done
.no_match
	adda.w	#g2ecs_emb_palette_record_size,a3
	bra.s	.next_record
.not_found
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d3/a0-a4
	rts

g2ecs_emb_palette_record_size	equ	20
g2ecs_emb_g3_palette_table
	dc.l	g2ecs_emb_pal_00
	dc.b	'blackmagic',0
	ds.b	5
	dc.l	g2ecs_emb_pal_01
	dc.b	'carpark',0
	ds.b	8
	dc.l	g2ecs_emb_pal_02
	dc.b	'combat',0
	ds.b	9
	dc.l	g2ecs_emb_pal_03
	dc.b	'gloom',0
	ds.b	10
	dc.l	g2ecs_emb_pal_04
	dc.b	'gothic',0
	ds.b	9
	dc.l	g2ecs_emb_pal_05
	dc.b	'hell',0
	ds.b	11
	dc.l	g2ecs_emb_pal_04
	dc.b	'labs',0
	ds.b	11
	dc.l	g2ecs_emb_pal_06
	dc.b	'living',0
	ds.b	9
	dc.l	g2ecs_emb_pal_07
	dc.b	'Mall',0
	ds.b	11
	dc.l	g2ecs_emb_pal_08
	dc.b	'Military',0
	ds.b	7
	dc.l	g2ecs_emb_pal_05
	dc.b	'storage',0
	ds.b	8
	dc.l	g2ecs_emb_pal_09
	dc.b	'theend',0
	ds.b	9
	dc.l	g2ecs_emb_pal_10
	dc.b	'title',0
	ds.b	10
	dc.l	g2ecs_emb_pal_11
	dc.b	'tunnel',0
	ds.b	9
	dc.l	0
	ds.b	16

g2ecs_emb_zm_palette_table
	dc.l	g2ecs_emb_pal_12
	dc.b	'alphasoftw',0
	ds.b	5
	dc.l	g2ecs_emb_pal_01
	dc.b	'carpark',0
	ds.b	8
	dc.l	g2ecs_emb_pal_02
	dc.b	'combat',0
	ds.b	9
	dc.l	g2ecs_emb_pal_13
	dc.b	'g3-dc',0
	ds.b	10
	dc.l	g2ecs_emb_pal_04
	dc.b	'gothic',0
	ds.b	9
	dc.l	g2ecs_emb_pal_05
	dc.b	'hell',0
	ds.b	11
	dc.l	g2ecs_emb_pal_04
	dc.b	'labs',0
	ds.b	11
	dc.l	g2ecs_emb_pal_06
	dc.b	'living',0
	ds.b	9
	dc.l	g2ecs_emb_pal_07
	dc.b	'Mall',0
	ds.b	11
	dc.l	g2ecs_emb_pal_14
	dc.b	'mansion',0
	ds.b	8
	dc.l	g2ecs_emb_pal_08
	dc.b	'Military',0
	ds.b	7
	dc.l	g2ecs_emb_pal_05
	dc.b	'storage',0
	ds.b	8
	dc.l	g2ecs_emb_pal_15
	dc.b	'temple',0
	ds.b	9
	dc.l	g2ecs_emb_pal_09
	dc.b	'theend',0
	ds.b	9
	dc.l	g2ecs_emb_pal_16
	dc.b	'title',0
	ds.b	10
	dc.l	g2ecs_emb_pal_17
	dc.b	'train',0
	ds.b	10
	dc.l	g2ecs_emb_pal_11
	dc.b	'tunnel',0
	ds.b	9
	dc.l	g2ecs_emb_pal_18
	dc.b	'words1',0
	ds.b	9
	dc.l	g2ecs_emb_pal_18
	dc.b	'words2',0
	ds.b	9
	dc.l	g2ecs_emb_pal_18
	dc.b	'words3',0
	ds.b	9
	dc.l	g2ecs_emb_pal_18
	dc.b	'words4',0
	ds.b	9
	dc.l	g2ecs_emb_pal_19
	dc.b	'words5',0
	ds.b	9
	dc.l	0
	ds.b	16
	even

; g3:blackmagic
g2ecs_emb_pal_00
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0111,$0CAA,$0444
	dc.w	$0777,$0999,$0EDD,$0531,$0AAB,$0333,$0DCC,$0655
	dc.w	$0210,$0766,$0887,$0DBB,$0FDD,$0DDD,$0533,$0211
	dc.w	$0001,$0002,$0003,$0004,$0005,$0006,$0007,$0008
	dc.w	$0000,$0110,$0541,$0761,$0777,$0000,$0655,$0222
	dc.w	$0333,$0444,$0766,$0210,$0555,$0111,$0666,$0322
	dc.w	$0100,$0333,$0443,$0655,$0766,$0666,$0211,$0100
	dc.w	$0000,$0001,$0001,$0002,$0002,$0003,$0003,$0004

; g3:carpark, zm:carpark
g2ecs_emb_pal_01
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0743,$0333,$0111
	dc.w	$0FCB,$0A75,$0EA8,$0531,$0311,$0B98,$0C74,$0555
	dc.w	$0FEE,$0FFB,$0DA5,$0853,$0877,$0820,$0BCC,$0442
	dc.w	$0A42,$0FC8,$0222,$0210,$0C86,$0621,$0FFD,$0742
	dc.w	$0000,$0110,$0541,$0761,$0777,$0321,$0111,$0000
	dc.w	$0765,$0532,$0754,$0210,$0100,$0544,$0632,$0222
	dc.w	$0777,$0775,$0652,$0421,$0433,$0410,$0566,$0221
	dc.w	$0521,$0764,$0111,$0100,$0643,$0310,$0776,$0321

; g3:combat, zm:combat
g2ecs_emb_pal_02
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0AAA,$0DDD,$0EEE
	dc.w	$0888,$0FDA,$0554,$0A42,$0E93,$0FC7,$0FF5,$0CCC
	dc.w	$0BBB,$0999,$0974,$0751,$0B96,$0766,$0FED,$0843
	dc.w	$0C74,$0FFB,$0A76,$0FF7,$0D96,$0CA8,$0B62,$0731
	dc.w	$0000,$0110,$0541,$0761,$0777,$0555,$0666,$0777
	dc.w	$0444,$0765,$0222,$0521,$0741,$0763,$0772,$0666
	dc.w	$0555,$0444,$0432,$0320,$0543,$0333,$0776,$0421
	dc.w	$0632,$0775,$0533,$0773,$0643,$0654,$0531,$0310

; g3:gloom
g2ecs_emb_pal_03
	dc.w	$0000,$0220,$0B92,$0ED2,$04D1,$0FFF,$0281,$09F3
	dc.w	$0878,$0211,$05F3,$0DBB,$0655,$0140,$0043,$0EDD
	dc.w	$0BA9,$0333,$05F1,$0EC0,$0270,$0420,$0391,$0FF1
	dc.w	$0021,$0B88,$0200,$0766,$0777,$088A,$0444,$0640
	dc.w	$0000,$0110,$0541,$0761,$0260,$0777,$0140,$0471
	dc.w	$0434,$0100,$0271,$0655,$0322,$0020,$0021,$0766
	dc.w	$0554,$0111,$0270,$0760,$0130,$0210,$0140,$0770
	dc.w	$0010,$0544,$0100,$0333,$0333,$0445,$0222,$0320

; g3:gothic, g3:labs, zm:gothic, zm:labs
g2ecs_emb_pal_04
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFE,$0753,$0EA7,$0FEC
	dc.w	$0531,$0A98,$0FE6,$0111,$0B75,$0EBA,$0FFF,$0765
	dc.w	$0953,$0EC9,$0333,$0C97,$0331,$0CAA,$0ECC,$0455
	dc.w	$0A96,$0642,$0421,$0755,$0E62,$0C94,$0422,$0210
	dc.w	$0000,$0110,$0541,$0761,$0777,$0321,$0753,$0776
	dc.w	$0210,$0544,$0773,$0000,$0532,$0755,$0777,$0332
	dc.w	$0421,$0764,$0111,$0643,$0110,$0655,$0766,$0222
	dc.w	$0543,$0321,$0210,$0322,$0731,$0642,$0211,$0100

; g3:hell, g3:storage, zm:hell, zm:storage
g2ecs_emb_pal_05
	dc.w	$0000,$0220,$0B92,$0ED2,$0FEE,$0EB9,$0C33,$0811
	dc.w	$0E75,$0FEC,$0954,$0410,$0E97,$0111,$0321,$0FE6
	dc.w	$0FC2,$0C54,$0A32,$0FED,$0B87,$0100,$0022,$0F38
	dc.w	$0732,$0F44,$0FDA,$0C20,$0300,$0A11,$0E42,$0532
	dc.w	$0000,$0110,$0541,$0761,$0777,$0754,$0611,$0400
	dc.w	$0732,$0776,$0422,$0200,$0743,$0000,$0110,$0773
	dc.w	$0761,$0622,$0511,$0776,$0543,$0000,$0011,$0714
	dc.w	$0311,$0722,$0765,$0610,$0100,$0500,$0721,$0211

; g3:living, zm:living
g2ecs_emb_pal_06
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0FEA,$0EE4,$0511
	dc.w	$0FFD,$0A43,$0E98,$0662,$0200,$0FF8,$0E43,$0111
	dc.w	$0422,$0DC4,$0E73,$0FBC,$0922,$0546,$0541,$0A92
	dc.w	$0AA6,$0DDE,$0DC8,$0B9A,$0CB3,$0EB5,$0B66,$0FFB
	dc.w	$0000,$0110,$0541,$0761,$0777,$0775,$0772,$0200
	dc.w	$0776,$0521,$0744,$0331,$0100,$0774,$0721,$0000
	dc.w	$0211,$0662,$0731,$0756,$0411,$0223,$0220,$0541
	dc.w	$0553,$0667,$0664,$0545,$0651,$0752,$0533,$0775

; g3:Mall, zm:Mall
g2ecs_emb_pal_07
	dc.w	$0000,$0220,$0B92,$0ED2,$0FEC,$0111,$0633,$0C86
	dc.w	$0A64,$0FE8,$0422,$0E64,$0953,$0311,$0C42,$0332
	dc.w	$0D82,$0344,$0EA6,$0FA8,$0ECC,$0B75,$0721,$0632
	dc.w	$0DBA,$0986,$0A42,$0642,$0FCA,$0CA8,$0843,$0FC8
	dc.w	$0000,$0110,$0541,$0761,$0776,$0000,$0311,$0643
	dc.w	$0532,$0774,$0211,$0732,$0421,$0100,$0621,$0111
	dc.w	$0641,$0122,$0753,$0754,$0766,$0532,$0310,$0311
	dc.w	$0655,$0443,$0521,$0321,$0765,$0654,$0421,$0764

; g3:Military, zm:Military
g2ecs_emb_pal_08
	dc.w	$0000,$0220,$0B92,$0ED2,$0EEE,$0FED,$0A52,$0521
	dc.w	$0C96,$0FF7,$0775,$0ECC,$0F92,$0751,$0332,$0643
	dc.w	$0FDA,$0887,$0FC7,$0FFB,$0853,$0BA9,$0C83,$0974
	dc.w	$0FF9,$0B74,$0A41,$0FB4,$0E84,$0DCC,$0554,$0631
	dc.w	$0000,$0110,$0541,$0761,$0777,$0776,$0521,$0210
	dc.w	$0643,$0773,$0332,$0766,$0741,$0320,$0111,$0321
	dc.w	$0765,$0443,$0763,$0775,$0421,$0554,$0641,$0432
	dc.w	$0774,$0532,$0520,$0752,$0742,$0666,$0222,$0310

; g3:theend, zm:theend
g2ecs_emb_pal_09
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0DDC,$0111,$0887
	dc.w	$0555,$0BBA,$0333,$0A99,$0CCB,$0FFB,$0985,$0CA9
	dc.w	$0888,$0CBB,$0CCC,$0543,$0999,$0A87,$0AAA,$0A97
	dc.w	$0AA9,$0433,$0BBB,$0654,$0222,$0BA9,$0DCB,$0F8A
	dc.w	$0000,$0110,$0541,$0761,$0777,$0666,$0000,$0443
	dc.w	$0222,$0555,$0111,$0544,$0665,$0775,$0442,$0654
	dc.w	$0444,$0655,$0666,$0221,$0444,$0543,$0555,$0543
	dc.w	$0554,$0211,$0555,$0322,$0111,$0554,$0665,$0745

; g3:title
g2ecs_emb_pal_10
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$04D1,$0111,$0BA9
	dc.w	$0281,$09F3,$0EDD,$0777,$0434,$05F3,$0140,$0655
	dc.w	$0988,$0043,$0410,$0DBB,$0878,$0222,$05F1,$0EC0
	dc.w	$0270,$0333,$0391,$0FF1,$0766,$0021,$088A,$0422
	dc.w	$0000,$0110,$0541,$0761,$0777,$0260,$0000,$0554
	dc.w	$0140,$0471,$0766,$0333,$0212,$0271,$0020,$0322
	dc.w	$0444,$0021,$0200,$0655,$0434,$0111,$0270,$0760
	dc.w	$0130,$0111,$0140,$0770,$0333,$0010,$0445,$0211

; g3:tunnel, zm:tunnel
g2ecs_emb_pal_11
	dc.w	$0000,$0220,$0B92,$0ED2,$0234,$0111,$0AFE,$07A6
	dc.w	$0555,$0BF9,$0222,$0885,$0353,$0FE8,$0342,$0574
	dc.w	$0AB9,$0BCA,$0463,$0BFB,$0CC6,$0585,$0564,$09A8
	dc.w	$0683,$0DFB,$0675,$0785,$0797,$08CA,$08A7,$0CCB
	dc.w	$0000,$0110,$0541,$0761,$0112,$0000,$0577,$0353
	dc.w	$0222,$0574,$0111,$0442,$0121,$0774,$0121,$0232
	dc.w	$0554,$0565,$0231,$0575,$0663,$0242,$0232,$0454
	dc.w	$0341,$0675,$0332,$0342,$0343,$0465,$0453,$0665

; zm:alphasoftw
g2ecs_emb_pal_12
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0999,$000F,$0111
	dc.w	$0447,$0F00,$00F0,$099D,$0D55,$0777,$0BBB,$0D22
	dc.w	$0444,$0222,$0DDC,$0555,$00B0,$0B77,$0D99,$0666
	dc.w	$0B00,$0EE0,$0CB6,$0400,$0040,$0F11,$011F,$0995
	dc.w	$0000,$0110,$0541,$0761,$0777,$0444,$0007,$0000
	dc.w	$0223,$0700,$0070,$0446,$0622,$0333,$0555,$0611
	dc.w	$0222,$0111,$0666,$0222,$0050,$0533,$0644,$0333
	dc.w	$0500,$0770,$0653,$0200,$0020,$0700,$0007,$0442

; zm:g3-dc
g2ecs_emb_pal_13
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0111,$0752,$0BBA
	dc.w	$0440,$0555,$0DDD,$0333,$0400,$0860,$0530,$0991
	dc.w	$0330,$0998,$0210,$0320,$0875,$0EEE,$0222,$0D11
	dc.w	$0BB1,$0EA0,$0640,$0D91,$0550,$0CCC,$08A0,$0311
	dc.w	$0000,$0110,$0541,$0761,$0777,$0000,$0321,$0555
	dc.w	$0220,$0222,$0666,$0111,$0200,$0430,$0210,$0440
	dc.w	$0110,$0444,$0100,$0110,$0432,$0777,$0111,$0600
	dc.w	$0550,$0750,$0320,$0640,$0220,$0666,$0450,$0100

; zm:mansion
g2ecs_emb_pal_14
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0999,$0555,$0777
	dc.w	$0BBB,$0333,$0DDD,$0222,$0888,$0666,$0444,$0EEE
	dc.w	$0AAA,$0CCC,$0001,$0002,$0003,$0004,$0005,$0006
	dc.w	$0007,$0008,$0009,$000A,$000B,$000C,$000D,$000E
	dc.w	$0000,$0110,$0541,$0761,$0777,$0444,$0222,$0333
	dc.w	$0555,$0111,$0666,$0111,$0444,$0333,$0222,$0777
	dc.w	$0555,$0666,$0000,$0001,$0001,$0002,$0002,$0003
	dc.w	$0003,$0004,$0004,$0005,$0005,$0006,$0006,$0007

; zm:temple
g2ecs_emb_pal_15
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0999,$0555,$0DDD
	dc.w	$0777,$0333,$0BBB,$0EEE,$0444,$0222,$0AAA,$0666
	dc.w	$0CCC,$0888,$0001,$0002,$0003,$0004,$0005,$0006
	dc.w	$0007,$0008,$0009,$000A,$000B,$000C,$000D,$000E
	dc.w	$0000,$0110,$0541,$0761,$0777,$0444,$0222,$0666
	dc.w	$0333,$0111,$0555,$0777,$0222,$0111,$0555,$0333
	dc.w	$0666,$0444,$0000,$0001,$0001,$0002,$0002,$0003
	dc.w	$0003,$0004,$0004,$0005,$0005,$0006,$0006,$0007

; zm:title
g2ecs_emb_pal_16
	dc.w	$0000,$0220,$0B92,$0ED2,$0111,$0F20,$0751,$0FF0
	dc.w	$0440,$09A0,$0511,$0C40,$0870,$0770,$0530,$009C
	dc.w	$0200,$0CA0,$0330,$0320,$0BB1,$0210,$0550,$0980
	dc.w	$0660,$0840,$0311,$0EA0,$0430,$0100,$0540,$0880
	dc.w	$0000,$0110,$0541,$0761,$0000,$0710,$0320,$0770
	dc.w	$0220,$0450,$0200,$0620,$0430,$0330,$0210,$0046
	dc.w	$0100,$0650,$0110,$0110,$0550,$0100,$0220,$0440
	dc.w	$0330,$0420,$0100,$0750,$0210,$0000,$0220,$0440

; zm:train
g2ecs_emb_pal_17
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0777,$0BBB,$0444
	dc.w	$0DDD,$0999,$0333,$0EEE,$0555,$0CCC,$0222,$0AAA
	dc.w	$0888,$0666,$0111,$0001,$0002,$0003,$0004,$0005
	dc.w	$0006,$0007,$0008,$0009,$000A,$000B,$000C,$000D
	dc.w	$0000,$0110,$0541,$0761,$0777,$0333,$0555,$0222
	dc.w	$0666,$0444,$0111,$0777,$0222,$0666,$0111,$0555
	dc.w	$0444,$0333,$0000,$0000,$0001,$0001,$0002,$0002
	dc.w	$0003,$0003,$0004,$0004,$0005,$0005,$0006,$0006

; zm:words1, zm:words2, zm:words3, zm:words4
g2ecs_emb_pal_18
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0555,$0AAA,$0111
	dc.w	$0777,$0222,$0BBB,$0CCC,$0001,$0002,$0003,$0004
	dc.w	$0005,$0006,$0007,$0008,$0009,$000A,$000B,$000C
	dc.w	$000D,$000E,$000F,$0010,$0011,$0012,$0013,$0014
	dc.w	$0000,$0110,$0541,$0761,$0777,$0222,$0555,$0000
	dc.w	$0333,$0111,$0555,$0666,$0000,$0001,$0001,$0002
	dc.w	$0002,$0003,$0003,$0004,$0004,$0005,$0005,$0006
	dc.w	$0006,$0007,$0007,$0000,$0000,$0001,$0001,$0002

; zm:words5
g2ecs_emb_pal_19
	dc.w	$0000,$0220,$0B92,$0ED2,$0FFF,$0111,$0999,$0444
	dc.w	$0CCC,$0F00,$0777,$0EEE,$0DDD,$0333,$0BBB,$0AAA
	dc.w	$0555,$0666,$0888,$0F11,$0222,$0001,$0002,$0003
	dc.w	$0004,$0005,$0006,$0007,$0008,$0009,$000A,$000B
	dc.w	$0000,$0110,$0541,$0761,$0777,$0000,$0444,$0222
	dc.w	$0666,$0700,$0333,$0777,$0666,$0111,$0555,$0555
	dc.w	$0222,$0333,$0444,$0700,$0111,$0000,$0001,$0001
	dc.w	$0002,$0002,$0003,$0003,$0004,$0004,$0005,$0005

	even

