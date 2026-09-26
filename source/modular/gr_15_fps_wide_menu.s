; -----------------------------------------------------------------------------
; c87a7 - optional true presented-FPS ToolType counter
;
; Bare ToolType FPS enables the counter.  It is never written to gloom.cfg.
;
; Gloom deliberately presents normal gameplay at most once every two VBlanks.
; On PAL this means a correct counter normally reads 25 FPS; on NTSC it reads
; 30 FPS.  Scene complexity changes the value only when rendering misses one or
; more display slots.  This is real output FPS, not a synthetic workload value.
;
; Every actual AGA or P96 gameplay present is counted.  The visible two-digit
; value is updated only after at least one complete second has elapsed.  It is
; calculated from all presents in that interval and then remains unchanged for
; the next full interval.  This prevents single-frame flashing while retaining
; a real average presented-FPS reading.  Menu dwell and level starts reset the
; sample window so they cannot create a false low reading.
;
; The display always contains exactly two digits (00..99).  Every digit uses a
; fixed 5x7 bitmap.  A one-pixel black frame surrounds the 11x7 digit field.
; P96 writes into the final RGB565 draw buffer before the ScreenBuffer flip.
; AGA/fallback writes through coloffs, matching the real chunky/C2P layout.
; -----------------------------------------------------------------------------
EB_VBLANKFREQUENCY	equ	530

g2fps_enabled		dc	0	;0=off, -1=FPS ToolType present
g2stock_enabled	dc	0	;c87b67 0=normal, -1=runtime STOCK overlay
g2stock_cfg_blobshadow	dc	-1	;c87b67 preserved gloom.cfg/default choice
g2stock_cfg_reflections	dc	-1	;c87b67 preserved gloom.cfg/default choice
g2stock_cfg_visibility	dc	-1	;c87b67 preserved gloom.cfg/default choice
g2fps_value		dc	0	;latched displayed FPS, 00..99
g2fps_window_start	dc	0	;framecnt at start of current >=1 second window
g2fps_window_count	dc	0	;real gameplay presents after window start
g2fps_window_valid	dc	0	;0 until first present establishes the window
g2fps_refresh_hz	dc	50	;PAL default; read from ExecBase when sane

; New gameplay session/level: configure refresh rate and show the engine's
; normal capped value until the first complete one-second sample is available.
g2fps_reset
	movem.l	d0-d2/a0,-(a7)
	moveq	#50,d1
	move.l	4.w,a0
	moveq	#0,d0
	move.b	EB_VBLANKFREQUENCY(a0),d0
	cmp	#40,d0
	bcs.s	.fallback
	cmp	#100,d0
	bhi.s	.fallback
	move	d0,d1
.fallback
	move	d1,g2fps_refresh_hz
	lsr	#1,d1		;Gloom's normal one-present-per-two-VBlanks cap
	move	d1,g2fps_value
	clr	g2fps_window_start
	clr	g2fps_window_count
	clr	g2fps_window_valid
	movem.l	(a7)+,d0-d2/a0
	rts

; Returning from the in-game menu must not include menu dwell time in the next
; sample.  Keep the current displayed value and restart the one-second window.
g2fps_restart_window
	clr	g2fps_window_count
	clr	g2fps_window_valid
	rts

; Count a real AGA C2P present or P96 gameplay-buffer present.  framecnt is
; incremented by the VBlank interrupt.  Reading it twice avoids a torn sample.
; The first present only opens the measurement window.  Subsequent presents are
; counted until at least refresh_hz VBlanks have elapsed.  The displayed FPS is
; then count*refresh_hz/elapsed, rounded to the nearest integer, and remains
; latched for the complete following window.
g2fps_update_present
	tst	g2fps_enabled
	beq.w	.done
	movem.l	d0-d5,-(a7)
.retry
	moveq	#0,d0
	move	framecnt,d0
	moveq	#0,d1
	move	framecnt,d1
	cmp	d0,d1
	bne.s	.retry
	tst	g2fps_window_valid
	bne.s	.have_window
	move	#-1,g2fps_window_valid
	move	d0,g2fps_window_start
	clr	g2fps_window_count
	bra.s	.exit
.have_window
	addq	#1,g2fps_window_count
	move	d0,d1
	sub	g2fps_window_start,d1
	and.l	#$0000ffff,d1
	moveq	#0,d2
	move	g2fps_refresh_hz,d2
	cmp.l	d2,d1
	bcs.s	.exit		;visible value must remain for at least one second

	; Rounded average: presents * refresh_hz / elapsed_vblanks.
	moveq	#0,d3
	move	g2fps_window_count,d3
	mulu	d2,d3
	move.l	d1,d4
	lsr.l	#1,d4
	add.l	d4,d3
	divu	d1,d3
	moveq	#0,d5
	move	d3,d5
	cmp	#99,d5
	bls.s	.store
	moveq	#99,d5
.store
	move	d5,g2fps_value

	; The present ending this interval becomes the zero point of the next one.
	move	d0,g2fps_window_start
	clr	g2fps_window_count
.exit
	movem.l	(a7)+,d0-d5
.done
	rts

; Return d4.b = adjusted chunky colour index for the whitest neutral colour
; currently installed.  Exact RGB12 white wins immediately.  Otherwise the
; score favours a high minimum R/G/B channel, avoiding bright coloured pens.
g2fps_find_white_chunky
	movem.l	d0-d3/d5-d7/a0-a1,-(a7)
	moveq	#-1,d4		;safe fallback: highest palette index
	move.l	lastpal,d0
	bne.s	.have_palette
	move.l	planar_palette,d0
	beq.w	.done
.have_palette
	move.l	d0,a0
	move	colours,d0
	beq.w	.done
	subq	#1,d0
	move	d0,d7		;DBF colour count
	moveq	#0,d6		;logical palette index
	moveq	#0,d4		;best logical palette index
	moveq	#-1,d5		;best score
.scan
	moveq	#0,d0
	move	(a0),d0		;RGB12 high-nibble word
	cmp	#$0fff,d0
	beq.s	.exact_white
	move	d0,d1
	lsr	#8,d1
	and	#$000f,d1	;R
	move	d0,d2
	lsr	#4,d2
	and	#$000f,d2	;G
	move	d0,d3
	and	#$000f,d3	;B
	move	d1,d0		;minimum channel
	cmp	d2,d0
	bls.s	.min_g_ok
	move	d2,d0
.min_g_ok
	cmp	d3,d0
	bls.s	.min_b_ok
	move	d3,d0
.min_b_ok
	lsl	#6,d0		;neutral brightness dominates score
	add	d1,d0
	add	d2,d0
	add	d3,d0
	cmp	d5,d0
	ble.s	.next
	move	d0,d5
	move	d6,d4
.next
	tst	aga
	beq.s	.next_ecs
	addq.l	#4,a0		;AGA palette entry = two RGB12 words
	bra.s	.next_index
.next_ecs
	addq.l	#2,a0
.next_index
	addq	#1,d6
	dbf	d7,.scan
	bra.s	.map_adjusted
.exact_white
	move	d6,d4
.map_adjusted
	lea	paladjust,a1
	moveq	#0,d0
	move.b	0(a1,d4.w),d0
	move	d0,d4
.done
	movem.l	(a7)+,d0-d3/d5-d7/a0-a1
	rts

; AGA and emergency P96 fallback.
; Visible X coordinates must go through coloffs while rows are separated by
; chunkymodw.  This matches Gloom's actual C2P source layout.
g2fps_draw_chunky
	tst	g2fps_enabled
	beq.w	.done
	tst	g2teleport_blackout
	bne.w	.done
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	chunky,d0
	beq.w	.exit
	move.l	d0,a4		;chunky base
	moveq	#0,d5
	move	chunkymodw,d5	;real row stride
	beq.w	.exit
	lea	coloffs,a6	;visible x -> C2P source offset
	bsr	g2fps_find_white_chunky

	; Clear 13x9 readability box at screen x=306..318, y=230..238.
	move	#230,d0
	mulu	d5,d0
	move.l	a4,a1
	adda.l	d0,a1
	moveq	#8,d7		;nine rows
.clear_row
	move	g2render_width,d6
	sub	#14,d6
.clear_pixel
	move	d6,d0
	move.l	0(a6,d0*4),d0
	clr.b	0(a1,d0.l)
	addq	#1,d6
	cmp	g2render_last_x,d6
	blt.s	.clear_pixel
	adda.l	d5,a1
	dbf	d7,.clear_row

	; Draw two complete 5x7 digits at screen x=307 and x=313, y=231.
	move	g2render_width,d2
	sub	#13,d2
	move	#231,d3
	bsr	g2fps_draw_digits_chunky
.exit
	movem.l	(a7)+,d0-d7/a0-a6
.done
	rts

; P96: a0=completed draw bitmap origin, d0=BytesPerRow.
g2fps_draw_p96_target
	tst	g2fps_enabled
	beq.w	.done
	cmp	#P96DSP_GAMEPLAY,p96display_state
	bne.w	.done
	tst	g2teleport_blackout
	bne.w	.done
	movem.l	d0-d7/a0-a4,-(a7)
	jsr	g2fps_update_present	;c87a7: count P96 gameplay presents, never menu refresh copies
	move.l	a0,a4
	move.l	d0,d5
	moveq	#0,d0
	move	p96target_width,d0
	cmp	#14,d0
	bcs.w	.exit
	sub	#14,d0		;13-pixel box plus one-pixel right margin
	add	d0,d0		;RGB565 byte offset
	adda.l	d0,a4
	moveq	#0,d0
	move	p96target_height,d0
	cmp	#10,d0
	bcs.w	.exit
	sub	#10,d0		;nine-pixel box plus one-pixel bottom margin
	mulu	d5,d0
	adda.l	d0,a4
	move.l	a4,a1
	moveq	#8,d6
.clear_row
	move.l	a1,a2
	moveq	#12,d7
.clear_pixel
	clr.w	(a2)+
	dbf	d7,.clear_pixel
	adda.l	d5,a1
	dbf	d6,.clear_row
	adda.l	d5,a4		;one-pixel top border
	addq.l	#2,a4		;one-pixel left border
	bsr	g2fps_draw_digits_rgb565
.exit
	movem.l	(a7)+,d0-d7/a0-a4
.done
	rts

; Draw exactly two digits into the C2P-layout chunky buffer.
; a4=chunky base, a6=coloffs, d2=x, d3=y, d4.b=white, d5=row stride.
g2fps_draw_digits_chunky
	bsr	g2fps_split_digits
	move	d6,d0
	lsl	#3,d0
	sub	d6,d0		;digit * 7 bytes
	ext.l	d0
	lea	g2fps_digits(pc),a0
	adda.l	d0,a0
	bsr	g2fps_draw_glyph_chunky
	move	d7,d0
	lsl	#3,d0
	sub	d7,d0
	ext.l	d0
	lea	g2fps_digits(pc),a0
	adda.l	d0,a0
	addq	#6,d2		;five pixels plus one-pixel gap
	bsr	g2fps_draw_glyph_chunky
	rts

; Draw exactly two digits into the final P96 RGB565 bitmap.
g2fps_draw_digits_rgb565
	bsr	g2fps_split_digits
	move	d6,d0
	lsl	#3,d0
	sub	d6,d0
	ext.l	d0
	lea	g2fps_digits(pc),a0
	adda.l	d0,a0
	move.l	a4,a1
	bsr	g2fps_draw_glyph_rgb565
	move	d7,d0
	lsl	#3,d0
	sub	d7,d0
	ext.l	d0
	lea	g2fps_digits(pc),a0
	adda.l	d0,a0
	move.l	a4,a1
	adda.w	#12,a1		;six pixels * two bytes
	bsr	g2fps_draw_glyph_rgb565
	rts

; Return d6=tens and d7=ones, clamped to 00..99.
g2fps_split_digits
	moveq	#0,d0
	move	g2fps_value,d0
	cmp	#99,d0
	bls.s	.range_ok
	moveq	#99,d0
.range_ok
	moveq	#10,d1
	divu	d1,d0
	moveq	#0,d6
	move	d0,d6		;quotient
	swap	d0
	moveq	#0,d7
	move	d0,d7		;remainder
	rts

; Seven rows, five columns, bit 4=left pixel ... bit 0=right pixel.
g2fps_draw_glyph_chunky
	movem.l	d0-d1/d6/a1,-(a7)
	move	d3,d0
	mulu	d5,d0
	move.l	a4,a1
	adda.l	d0,a1
	moveq	#6,d6
.row
	moveq	#0,d0
	move.b	(a0)+,d0
	btst	#4,d0
	beq.s	.x1
	move	d2,d1
	move.l	0(a6,d1*4),d1
	move.b	d4,0(a1,d1.l)
.x1
	btst	#3,d0
	beq.s	.x2
	move	d2,d1
	addq	#1,d1
	move.l	0(a6,d1*4),d1
	move.b	d4,0(a1,d1.l)
.x2
	btst	#2,d0
	beq.s	.x3
	move	d2,d1
	addq	#2,d1
	move.l	0(a6,d1*4),d1
	move.b	d4,0(a1,d1.l)
.x3
	btst	#1,d0
	beq.s	.x4
	move	d2,d1
	addq	#3,d1
	move.l	0(a6,d1*4),d1
	move.b	d4,0(a1,d1.l)
.x4
	btst	#0,d0
	beq.s	.next
	move	d2,d1
	addq	#4,d1
	move.l	0(a6,d1*4),d1
	move.b	d4,0(a1,d1.l)
.next
	adda.l	d5,a1
	dbf	d6,.row
	movem.l	(a7)+,d0-d1/d6/a1
	rts

g2fps_draw_glyph_rgb565
	movem.l	d0/d6/a1,-(a7)
	moveq	#6,d6
.row
	moveq	#0,d0
	move.b	(a0)+,d0
	btst	#4,d0
	beq.s	.x1
	move	#$ffff,(a1)
.x1
	btst	#3,d0
	beq.s	.x2
	move	#$ffff,2(a1)
.x2
	btst	#2,d0
	beq.s	.x3
	move	#$ffff,4(a1)
.x3
	btst	#1,d0
	beq.s	.x4
	move	#$ffff,6(a1)
.x4
	btst	#0,d0
	beq.s	.next
	move	#$ffff,8(a1)
.next
	adda.l	d5,a1
	dbf	d6,.row
	movem.l	(a7)+,d0/d6/a1
	rts

; Canonical, high-contrast 5x7 digits.  Each byte is one complete five-pixel row.
g2fps_digits
	dc.b	$0e,$11,$13,$15,$19,$11,$0e	;0
	dc.b	$04,$0c,$04,$04,$04,$04,$0e	;1
	dc.b	$0e,$11,$01,$02,$04,$08,$1f	;2
	dc.b	$1e,$01,$01,$0e,$01,$01,$1e	;3
	dc.b	$02,$06,$0a,$12,$1f,$02,$02	;4
	dc.b	$1f,$10,$10,$1e,$01,$01,$1e	;5
	dc.b	$0e,$10,$10,$1e,$11,$11,$0e	;6
	dc.b	$1f,$01,$02,$04,$08,$08,$08	;7
	dc.b	$0e,$11,$11,$0e,$11,$11,$0e	;8
	dc.b	$0e,$11,$11,$0f,$01,$01,$0e	;9
	even

; -----------------------------------------------------------------------------
; c87b7/c87b23: immutable original Gloom3 / Zombie Massacre AGA palettes
;
; The external .pal files remain loaded.  AGA/P96 scriptdraw selects these exact
; original bytes by the current pict_ basename; ECS keeps each generated EHB .pal.
; This makes the visible palette independent of load order, freed/reused file
; buffers, lastpal, gameplay palette changes and START LEVEL/script restarts.
; -----------------------------------------------------------------------------
g2inter_select_exact_palette
	movem.l	d0-d4/a0/a2-a4,-(a7)
	clr.l	g2inter_exact_palette_ptr
	cmp	#2,g2_game_profile	; Zombie Massacre
	beq.s	.g2c87b7_profile_ok
	cmp	#3,g2_game_profile	; Gloom3
	bne.w	.g2c87b7_done
.g2c87b7_profile_ok
	tst.l	pic
	beq.w	.g2c87b7_fallback
	lea	g2v190t_lastpicname,a0
	tst.b	(a0)
	beq.w	.g2c87b7_fallback
	move.l	a0,a2		; basename candidate
.g2c87b7_pathscan
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.s	.g2c87b7_have_base
	cmp.b	#'/',d0
	beq.s	.g2c87b7_new_base
	cmp.b	#':',d0
	bne.s	.g2c87b7_pathscan
.g2c87b7_new_base
	move.l	a0,a2
	bra.s	.g2c87b7_pathscan
.g2c87b7_have_base
	lea	g2inter_exact_palette_table,a3
.g2c87b7_next_record
	move.l	(a3),d0
	beq.s	.g2c87b7_fallback
	move.l	a2,a0
	lea	4(a3),a4
.g2c87b7_compare
	moveq	#0,d1
	moveq	#0,d2
	move.b	(a0)+,d1
	move.b	(a4)+,d2
	cmp.b	#'A',d1
	bcs.s	.g2c87b7_fold2
	cmp.b	#'Z',d1
	bhi.s	.g2c87b7_fold2
	or.b	#$20,d1
.g2c87b7_fold2
	cmp.b	#'A',d2
	bcs.s	.g2c87b7_cmp
	cmp.b	#'Z',d2
	bhi.s	.g2c87b7_cmp
	or.b	#$20,d2
.g2c87b7_cmp
	cmp.b	d2,d1
	bne.s	.g2c87b7_nomatch
	tst.b	d1
	bne.s	.g2c87b7_compare
	move.l	(a3),a1
	; c87b10: copy the immutable exact palette to private writable storage.
	; Used entries remain byte-identical; three out-of-depth spare entries are
	; used for the original graded Bigfont yellows whenever available.
	jsr	g2inter_build_work_palette
	move.l	a1,g2inter_exact_palette_ptr
	bra.s	.g2c87b7_done
.g2c87b7_nomatch
	adda.w	#g2inter_exact_palette_record_size,a3
	bra.s	.g2c87b7_next_record
.g2c87b7_fallback
	lea	g2inter_yellow_text_indices,a0
	move	#-1,(a0)
	move	#-1,2(a0)
	move	#-1,4(a0)
	clr	g2inter_yellow_text_active
	move.l	picpal,a1
	move.l	a1,g2inter_exact_palette_ptr
.g2c87b7_done
	movem.l	(a7)+,d0-d4/a0/a2-a4
	rts

	even
g2inter_exact_palette_ptr	dc.l	0
g2inter_exact_palette_record_size	equ	20
g2inter_exact_palette_table

	dc.l	g2inter_pal_storage
	dc.b	'storage',0
	ds.b	8
	dc.l	g2inter_pal_storage
	dc.b	'hell',0
	ds.b	11
	dc.l	g2inter_pal_labs
	dc.b	'labs',0
	ds.b	11
	dc.l	g2inter_pal_labs
	dc.b	'gothic',0
	ds.b	9
	dc.l	g2inter_pal_tunnel
	dc.b	'tunnel',0
	ds.b	9
	dc.l	g2inter_pal_living
	dc.b	'living',0
	ds.b	9
	dc.l	g2inter_pal_carpark
	dc.b	'carpark',0
	ds.b	8
	dc.l	g2inter_pal_mall
	dc.b	'mall',0
	ds.b	11
	dc.l	g2inter_pal_military
	dc.b	'military',0
	ds.b	7
	dc.l	g2inter_pal_theend
	dc.b	'theend',0
	ds.b	9
	dc.l	g2inter_pal_mansion
	dc.b	'mansion',0
	ds.b	8
	dc.l	g2inter_pal_mansion
	dc.b	'temple',0
	ds.b	9
	dc.l	g2inter_pal_mansion
	dc.b	'train',0
	ds.b	10
	dc.l	g2inter_pal_words
	dc.b	'words1',0
	ds.b	9
	dc.l	g2inter_pal_words
	dc.b	'words2',0
	ds.b	9
	dc.l	g2inter_pal_words
	dc.b	'words3',0
	ds.b	9
	dc.l	g2inter_pal_words
	dc.b	'words4',0
	ds.b	9
	dc.l	g2inter_pal_words
	dc.b	'words5',0
	ds.b	9
	dc.l	g2inter_pal_alphasoftw
	dc.b	'alphasoftw',0
	ds.b	5
	dc.l	g2inter_pal_g3dc
	dc.b	'g3-dc',0
	ds.b	10
	dc.l	g2inter_pal_combat
	dc.b	'combat',0
	ds.b	9
	dc.l	0
	ds.b	16
	even

g2inter_pal_storage
	dc.l	$00000000,$08110E50,$098003DF,$0998033B
	dc.l	$0D98013A,$0DC905A1,$0DDC0328,$0146073E
	dc.l	$02510799,$0400069A,$0DED0A75,$0FEC088D
	dc.l	$0EFE0B3D,$0FEE0BA8,$0FFE0A47,$0FFF0745
	dc.l	$0123010E,$0FFF04C9,$012006BC,$0FFF0897
	dc.l	$0FFF0AC9,$02000221,$0FFF0CEB,$09250426
	dc.l	$00120F71,$0110059B,$01000200,$0C110B88
	dc.l	$000107A2,$0C900C6B,$000005C5,$00000A00
	dc.l	$0DC10743,$05130587,$08410ECA,$00000241
	dc.l	$04300F5C,$0D850094,$00000020,$0813096E
	dc.l	$031201D1,$06000DA8,$021007CA,$0E850E87
	dc.l	$0D9B04EA,$0C4109EF,$0D4500D9,$0F980877
	dc.l	$0FC907B5,$0FE80AEF,$08200EA9,$0EA809EE
	dc.l	$0FB50011,$010104D2,$010006D4,$0EFD0B73
	dc.l	$03000663,$0D650039,$0C680C16,$051201A2
	dc.l	$0F650129,$0FBA0874,$094300DC,$0E86087E
	dc.l	$00000874,$0FCA088D,$0C430DA8,$0DC4057E
	dc.l	$0E540D03,$0E970964,$01000921,$0B4300B5
	dc.l	$04110EB0,$0FA80B7A,$0A200CCA,$0FFC0C78
	dc.l	$06300E7E,$0E75073D,$0EDB0871,$0FB90B63
	dc.l	$0FFD0B37,$00000B41,$0DC2065D,$0E900D5B
	dc.l	$098503C0,$0FFE04C4,$020108C3,$00000A20
	dc.l	$06120CB2,$0D6400A5,$020007E4,$0F7606AB
	dc.l	$0A110D74,$0FFE0B99,$00000463,$0D230124
	dc.l	$01000373,$031007BB,$05500C89,$05000699
	dc.l	$0FFE0DCA,$0B6400A2,$0F870A80,$071100C1
	dc.l	$05540A72,$0D540027,$0FFD0CC8,$030108C2
	dc.l	$0F970A67,$0FC007EF,$02000C22,$01000341
	dc.l	$09550179,$0FDB0B72,$08210F7E,$0BA108E2
	dc.l	$05320055,$0FE10C34,$0FEB0AC4,$0A230D60
	dc.l	$0B540017,$0A210E7F,$0FFE0EEB,$09580791
	dc.l	$0CA00FFF,$0FA90B96,$0A320B44,$09320042
	dc.l	$0F75081D,$057701FF,$09BC01A5,$0546069C
	dc.l	$048A0718,$0ADC001E,$09B40B2E,$09BA063C
	dc.l	$066901E6,$0FE4099E,$0543000A,$079A0408
	dc.l	$0133057B,$03570881,$04540143,$077305DF
	dc.l	$077004AA,$0FBB043D,$0B94004F,$0A410BEB
	dc.l	$0A980FBD,$0E1107AB,$0A25074C,$0A900F8C
	dc.l	$077705E3,$0BB90442,$0E450DF7,$0A550F9B
	dc.l	$0C610CF9,$0BBC02D6,$0A580D75,$09A70DC4
	dc.l	$05670261,$0CB40E3D,$0DC605AD,$0E930E00
	dc.l	$032003FC,$0FC203ED,$0BDE06D5,$073300FA
	dc.l	$0E230D43,$0AA202FE,$0FDC0868,$0DCB02A0
	dc.l	$033302BA,$0E780E44,$0DA800EE,$03690684
	dc.l	$075403C2,$06130F59,$075102D7,$07AB0460
	dc.l	$077505DE,$03550FAB,$0B970100,$08710D14
	dc.l	$0E640BB8,$0A710D02,$0BAA0026,$0FBD02A6
	dc.l	$02230E2B,$098701A1,$04510249,$098204DE
	dc.l	$093501BD,$0788049C,$0A920F8E,$08330F54
	dc.l	$08640FC0,$0BBA049C,$0CBB0E6C,$0C220CB3
	dc.l	$0E6108D7,$0B760101,$07720594,$08760F20
	dc.l	$089A0FD3,$0C580F01,$0FE708B1,$0B78035A
	dc.l	$0A360CC1,$0BB4084E,$0C920D3E,$0DA700E1
	dc.l	$0DFE070E,$0FA70686,$0CB20F2C,$0EB20F5B
	dc.l	$0FC401EE,$0FB0023E,$06670EB1,$0BCD050D
	dc.l	$0FD6040F,$073502E7,$06320F55,$03320215
	dc.l	$0D8701D0,$0D520D33,$0E2209B4,$0FE20B8D
	dc.l	$09CE067F,$0DEB0933,$0FDE0B67,$03450438
	dc.l	$0C330E84,$0B330271,$012205C6,$0765035C
	dc.l	$0D760151,$0C780D78,$04450F52,$0D9A0365
	dc.l	$013504BB,$05550CF9,$0BA207FE,$0DBA0045
	dc.l	$071407DD,$0DE30B53,$0E330B85,$0E9A0E36
	dc.l	$01580956,$0BC10911,$0E790D89,$0BDC054E
	dc.l	$0BB6063E,$09780275,$0DDD047C,$05520D76
	even

g2inter_pal_labs
	dc.l	$00000100,$08210704,$08880CB6,$023609F9
	dc.l	$03420879,$041007C9,$09810AD8,$0BB90BA6
	dc.l	$01230546,$01210972,$020008C2,$0ACC050A
	dc.l	$0D8101F5,$011106DE,$00100B4D,$0C2106CA
	dc.l	$093401E5,$01000540,$0DC90C42,$05510B22
	dc.l	$04230788,$000107A2,$00000AC4,$0C780CE5
	dc.l	$0EE8091F,$04210EE0,$0DDC0818,$0C950853
	dc.l	$00000A10,$0DED0F05,$05530C2B,$0864074D
	dc.l	$0A640C7C,$06310931,$0DC50663,$00000371
	dc.l	$098501C2,$0DEE0C46,$00000441,$0DCA0A2B
	dc.l	$089B0F55,$0773011A,$099806AE,$098700D2
	dc.l	$02110ED9,$00000320,$08500F87,$0E950650
	dc.l	$042108CE,$0A980CDB,$05540AAF,$0A5107B5
	dc.l	$0C96076E,$08660E96,$0EEC0C3E,$0FCB02F0
	dc.l	$02100774,$0FFD0C72,$032005DC,$022206B2
	dc.l	$0AA90C1C,$0C9A06D6,$08530773,$0A970720
	dc.l	$08730F63,$053200C3,$0EDB07FA,$03100685
	dc.l	$0A660BC6,$0C980CFD,$09750091,$0CA708E1
	dc.l	$0E980DFC,$010104E3,$0A8408FE,$0DDB0E03
	dc.l	$062109DF,$0343096C,$033205A5,$075403BD
	dc.l	$010005D1,$0FEC096C,$06610EE8,$01100854
	dc.l	$0FEE0394,$0A7507B0,$0CA80EE7,$063206C3
	dc.l	$066601C7,$0BA405BE,$0FFE0A77,$095305A5
	dc.l	$0FEB0732,$0BA703B2,$0753043A,$0FC804BE
	dc.l	$044305BD,$01110684,$0FDC0056,$032205D1
	dc.l	$0FFF0CC4,$052106DD,$0BBB04A1,$0454091B
	dc.l	$0FFB0C90,$0750033D,$0DC70590,$06100BAC
	dc.l	$0B94074F,$03230265,$0B96074E,$073206E5
	dc.l	$02330A54,$0BAA01E0,$04110BF9,$00000C70
	dc.l	$0EC10215,$0BA800BE,$033407F7,$02110790
	dc.l	$0964067C,$0CA90DFA,$0CCA060E,$058A0210
	dc.l	$0B7506B2,$0D96068F,$01000AD3,$07760358
	dc.l	$033307D6,$0C540939,$0D610001,$0C650990
	dc.l	$05660D33,$0A210B65,$0E910F62,$0E610418
	dc.l	$098301C4,$0DB306F5,$0E650CB2,$0C32091D
	dc.l	$045609C5,$0A440EF7,$07890573,$06330CE7
	dc.l	$0CCC0144,$0E970F41,$0A530AB4,$08220B67
	dc.l	$0FD70012,$0E920E4E,$0C530DE2,$0C930D23
	dc.l	$0BBB0012,$0A220BC8,$04620BB0,$0FC404EE
	dc.l	$0E62095F,$0A880EC6,$0EBA0617,$0A830FF8
	dc.l	$0FC2089D,$0B8104F4,$0E540468,$0C660CD6
	dc.l	$0E760D15,$01330905,$07660053,$0C430743
	dc.l	$0855086C,$079A003A,$0F8800E6,$0EB50630
	dc.l	$04330CD9,$0CDC042E,$08710727,$0B700347
	dc.l	$0EB70532,$03680E00,$0A720B78,$08310BC4
	dc.l	$0FD10A5D,$0CA50BF4,$08420B0E,$0B560154
	dc.l	$07750210,$0C730D90,$0FA205FE,$0CA30ED2
	dc.l	$0C710E94,$0A310EE4,$0FE70972,$0E710BC7
	dc.l	$0644070D,$0FA105F6,$0CA10FA7,$07720657
	dc.l	$0DDE0963,$0C400B5F,$044108EC,$0CBA0D19
	dc.l	$0A330DF1,$0FD20CCD,$0BA30055,$0FE40A2F
	dc.l	$098902C6,$044601B0,$09AB07C7,$0E730CB0
	dc.l	$0FE90AA1,$09AA0813,$077706D8,$0C560C80
	dc.l	$0BA10728,$08760DCC,$0A890FDB,$0E750EC4
	dc.l	$09940BDF,$07520316,$0EB90B00,$09970AC3
	dc.l	$0C760CEC,$0A760DDB,$06110EEB,$0C7509C4
	dc.l	$07670173,$05520C44,$0FDD0369,$0ACD0EDE
	dc.l	$09930BB8,$05770F3A,$07990C20,$0E760DEB
	dc.l	$0D430E46,$0CDB0C07,$0134086C,$0BBC0229
	dc.l	$0F94095D,$0B5106C3,$0FB4095F,$0DFF0F77
	dc.l	$08540C27,$053403CD,$09710705,$0EBB0627
	dc.l	$0C980A08,$09210506,$01220A71,$0B710068
	dc.l	$0CCD0369,$0FC10958,$08510F58,$0DB70701
	dc.l	$0FB70732,$0A730A78,$0CB909E3,$0CDE0194
	even

g2inter_pal_tunnel
	dc.l	$0110007E,$086402F0,$05670153,$0F620F08
	dc.l	$03310B35,$012302CA,$0030081B,$01210F8D
	dc.l	$02320BD7,$03410EAA,$05620D21,$0234059B
	dc.l	$0352031E,$045301FA,$03430E3A,$02450EA8
	dc.l	$054207EB,$0563069E,$04550F63,$046509C4
	dc.l	$04740D56,$066309A7,$05830F0A,$06750DA5
	dc.l	$05850C7A,$08840855,$05870556,$07950208
	dc.l	$0885051C,$089A05C0,$05960EC5,$067807ED
	dc.l	$07970313,$07A6015B,$06980095,$089508BD
	dc.l	$08870B70,$079805F9,$0A9400E7,$08880DC7
	dc.l	$08A70D32,$09A50F4F,$09B80212,$07B8093D
	dc.l	$099A09F4,$0CBA06B7,$08BA0553,$0AB70E9C
	dc.l	$0AA80DBC,$0CC70317,$09C904E3,$0AB908DB
	dc.l	$0DDB014E,$09AB06CB,$0BD90512,$0ABC02B2
	dc.l	$0CC8054E,$0DC70AED,$0DD90322,$09CB0DE8
	dc.l	$0BDA044F,$0CDA0D46,$0CEB041E,$0EDA0107
	even

g2inter_pal_living
	dc.l	$00000532,$08110E58,$0981015F,$09990120
	dc.l	$0D8801FD,$0DC804DD,$0DDD04B2,$0FDC072E
	dc.l	$0FFD0B97,$0FDE06BC,$02570344,$0FFF0CDA
	dc.l	$04400E6E,$0DDE01ED,$0FBD083A,$0510010C
	dc.l	$0FFB0A10,$0BCE01EE,$0DCA04CF,$02340528
	dc.l	$01100B8A,$02000675,$0122054F,$032003BC
	dc.l	$032200AB,$04110CC9,$04320F9C,$0A470413
	dc.l	$05240047,$0C320C4E,$0C820DFC,$01350DFF
	dc.l	$04440F5E,$06310F61,$0CB30C41,$094100DD
	dc.l	$0FE90371,$06220F61,$04520E7D,$03540D7C
	dc.l	$0FD8050F,$08220EF9,$0724027A,$0D8400EF
	dc.l	$0C520E48,$06440E37,$098404FC,$06610A2B
	dc.l	$094401F6,$09350F49,$0DBC030C,$055409DD
	dc.l	$0C540D0E,$0F8402D7,$03570B83,$0FBA041D
	dc.l	$0DC40B48,$07460113,$07720C60,$0FF80C9A
	dc.l	$0A110B7B,$0DBA011E,$0FB90501,$0BA209B9
	dc.l	$0FC603F9,$0A220FED,$0764040D,$0E430BBF
	dc.l	$0BBC00BD,$05660909,$0A420CE2,$0A920A54
	dc.l	$0D9C0517,$0DB8001F,$0F9D0551,$0FA605FF
	dc.l	$0FE50AA1,$0CB70FF2,$0F98012D,$0BBA022F
	dc.l	$04680975,$0757032C,$0A440FF5,$0FA503D2
	dc.l	$0EA30ED6,$08640FFA,$0784080A,$0A620DD1
	dc.l	$0776054A,$0E9A0F5A,$0BB904A1,$05760ABE
	dc.l	$0B6401ED,$037A0A40,$0C720D07,$096700B5
	dc.l	$0BA4015D,$0F970200,$09BD03C7,$06780FC6
	dc.l	$0B9C081C,$098703D0,$0E310C82,$0D9A0129
	dc.l	$0C640FFF,$068A0754,$0A960F3F,$0B6700EA
	dc.l	$0B48069C,$09AB0392,$0C570C3F,$0F62057C
	dc.l	$0E7B0233,$0BB6054D,$08790F7F,$0F74021B
	dc.l	$059C0410,$0C770F08,$0D8701C0,$08AC0D3D
	dc.l	$0B98008D,$0FA1021A,$0E770F59,$0E580791
	dc.l	$0B7B0428,$07BD062C,$0C5A0FB5,$079C0092
	even

g2inter_pal_carpark
	dc.l	$00000463,$08210473,$08770FF8,$0BA90385
	dc.l	$0DB9031A,$0DDD0310,$0157083F,$034308E7
	dc.l	$04100868,$0DDE05CB,$0FEC093E,$0FFE075E
	dc.l	$0DFF0968,$0FFF0DEC,$0FFD0D37,$0EDE0C54
	dc.l	$01240397,$01110AFA,$0BEF0546,$020001A5
	dc.l	$0FDB0737,$0BED070C,$00020AC5,$00000FDB
	dc.l	$021105C8,$01220619,$0310036D,$04210727
	dc.l	$09740974,$0332031F,$043309EF,$05210721
	dc.l	$08430FE4,$0D6306C3,$02240AA5,$05320056
	dc.l	$06210DA9,$03440828,$02260D82,$073200E9
	dc.l	$013605B5,$02460C05,$054309EB,$0FC90ADB
	dc.l	$0B750F21,$0DA5005B,$03450AEC,$074301B9
	dc.l	$01560E12,$0B530AA4,$0FB906C0,$0D850E6E
	dc.l	$08320A90,$0EBA0BCC,$09320DD8,$0DA80202
	dc.l	$054500D1,$035707A3,$06540D4D,$0A4102A8
	dc.l	$0BCF03F0,$0C440364,$05650907,$0D8600DE
	dc.l	$0A4303D5,$075307FE,$0A640A11,$07650165
	dc.l	$08640F2B,$055605DB,$0A4508C7,$03580498
	dc.l	$0DCB07E9,$076600CD,$0577062F,$0BCC051C
	dc.l	$015A0B82,$0EA908FA,$09760040,$0DBB0081
	dc.l	$0E980867,$0A6606C7,$03790A04,$035A04E6
	dc.l	$0BBE00D8,$077804B8,$0B860213,$0D740327
	dc.l	$09DF08C2,$0A870F7A,$0BBB0795,$0279025E
	dc.l	$0FA702AF,$0579037E,$037A085D,$0DC70708
	dc.l	$0789043D,$09970888,$0E970C80,$0E7406E3
	dc.l	$07990452,$037C08D1,$09AC00E9,$08880FCD
	dc.l	$0B970594,$048B0C3F,$09A90B37,$068B0A55
	dc.l	$0F8202A0,$0AAC0AD2,$0F940382,$0A980E7D
	dc.l	$079A067D,$0FA50299,$059B0924,$0AAA0C6A
	dc.l	$09CE084E,$09CD08A7,$099A04C9,$049C0C8E
	dc.l	$09BB0593,$038D033A,$06AC0E0C,$07BC087D
	dc.l	$08AE06A0,$049E036E,$05AE0BFC,$06CF0E37
	even

g2inter_pal_mall
	dc.l	$00000664,$0F100F0A,$0F000F76,$0F100F0B
	dc.l	$0F110F09,$0F000F75,$01110345,$0F110F80
	dc.l	$020002FA,$02100729,$02110172,$021007A6
	dc.l	$011204C3,$02210606,$0310034A,$021201F1
	dc.l	$03110778,$02220871,$03100B9C,$03210557
	dc.l	$040004F5,$03220501,$03200D1C,$02310E16
	dc.l	$03220381,$03320016,$03310B16,$04100C7A
	dc.l	$03320924,$04200F25,$04210D24,$03330241
	dc.l	$0510077C,$04300D2D,$04210F8E,$033309A2
	dc.l	$04320754,$053100A1,$05200F27,$05210E12
	dc.l	$05210A8B,$043209D7,$043307E1,$05320A21
	dc.l	$062004B6,$062104A3,$04430519,$05310FC5
	dc.l	$044303A8,$062108ED,$063203B5,$054300A6
	dc.l	$0720036E,$05330FB1,$063109C4,$072103EA
	dc.l	$04440BC5,$05430F70,$06420735,$07200CAC
	dc.l	$05430CBA,$07210CA7,$07310A35,$07410534
	dc.l	$05540039,$07320961,$06430F10,$07420634
	dc.l	$05540D14,$06430EC2,$08310523,$05530FAD
	dc.l	$0750075C,$0751064E,$05540CAC,$08320780
	dc.l	$08410624,$06540D24,$08430201,$07530634
	dc.l	$08420833,$084202AF,$055509F9,$0850071D
	dc.l	$09310475,$075308C5,$0851075D,$075401E7
	dc.l	$093204F5,$093108E4,$08540202,$08530733
	dc.l	$075500D3,$0665007E,$09410996,$08630611
	dc.l	$085400E5,$094207B9,$09420E14,$09530169
	dc.l	$095107BA,$06650F8F,$07650C60,$0A410644
	dc.l	$09630316,$09520D97,$0A4204B9,$08540FD8
	dc.l	$06760936,$09530F24,$0A51058A,$07650E9E
	dc.l	$08740837,$09620D77,$07760841,$08650D64
	dc.l	$09640766,$0A5302E8,$0A530E32,$0973083C
	dc.l	$0B5101B2,$0A520F98,$0875075D,$09650984
	dc.l	$0B5102DF,$077704B5,$0974074E,$0A530FF7
	dc.l	$0A640864,$0A72085B,$0975033F,$0A7307A6
	dc.l	$0B630637,$0A650991,$0A740756,$097602D3
	dc.l	$0B620E18,$0887010C,$0B640578,$0A750665
	dc.l	$0A840713,$0B710A7E,$08770ED6,$0C630046
	dc.l	$0C640043,$0B720D5D,$0B740908,$0B730D47
	dc.l	$0A7606A3,$0A850744,$0A860176,$09870C17
	dc.l	$08880CA1,$0B740E96,$0C830007,$0B840695
	dc.l	$0B750D73,$0B75089F,$09870D88,$0B85034E
	dc.l	$0D730034,$0D6400F5,$0C840267,$0A8702E9
	dc.l	$0B8602D4,$0B870164,$0C85032E,$0C820DE8
	dc.l	$0C750E77,$0B95095C,$0998095C,$0C8600C1
	dc.l	$0D840406,$0B970406,$0B960788,$0D93000D
	dc.l	$0D830982,$0D85003A,$0B97042E,$0D8504A0
	dc.l	$0B9703C7,$0C950E46,$0B980338,$0D8603B1
	dc.l	$0B9801C8,$0E910709,$0C960D57,$0C870BF3
	dc.l	$0DA4000E,$0E8302EF,$0C97082E,$0A990DF5
	dc.l	$0D9601D6,$0E9205E6,$0E94052D,$0C970EA6
	dc.l	$0C9806B7,$0E960034,$0CA80351,$0E930BD8
	dc.l	$0DA60386,$0EA4005F,$0E9600D5,$0BA903CD
	dc.l	$0D970F85,$0DA80240,$0BA90F88,$0CA80AD3
	dc.l	$0EA601B4,$0FA4011D,$0CA90A69,$0EA60D41
	dc.l	$0EA70615,$0FA306A9,$0DA805E3,$0DA80F15
	dc.l	$0FA10CDE,$0CA909FE,$0EB70307,$0EB60C31
	dc.l	$0FA60494,$0DB90419,$0EA802CA,$0FB408A6
	dc.l	$0CBA054D,$0EB80826,$0FB70304,$0EB709CB
	dc.l	$0DBA016C,$0FB508EE,$0EB90642,$0EB907D1
	dc.l	$0DCA040C,$0FB70B89,$0EBA02C4,$0FC70666
	dc.l	$0FB808AD,$0EBB00D0,$0FC8055E,$0FBA01D0
	dc.l	$0DCB026F,$0FD70C06,$0FCA004C,$0ECC0215
	dc.l	$0ECA0FE7,$0FD90C00,$0EDC0006,$0FCA0DB8
	dc.l	$0FDA0A67,$0FCC01E0,$0ECD0FE2,$0FDB0EF1
	dc.l	$0FDC0886,$0FEC0D12,$0FDD07DC,$0FED0DDE
	even

g2inter_pal_military
	dc.l	$00000664,$0F120FA1,$0F100F3B,$0F210F0A
	dc.l	$03320B5A,$0F100F9A,$04300E5F,$05210434
	dc.l	$06310748,$04430614,$07210BC4,$06430231
	dc.l	$05540745,$073105FB,$08410A36,$07510B57
	dc.l	$08430230,$06540E67,$09420946,$0853006B
	dc.l	$0A410644,$05650C2B,$095401F1,$076604B0
	dc.l	$09510DBD,$09750411,$0A530753,$0B5208E1
	dc.l	$0A730189,$0B710A7E,$0B63045F,$07770BE9
	dc.l	$0B730EDD,$0A7604F4,$0B750ADC,$0D740023
	dc.l	$098805C2,$0C820DE8,$0D8304BB,$0B960912
	dc.l	$0B97037C,$0D95066D,$0DA60246,$0E910709
	dc.l	$0E940419,$0EA4044F,$0AA90F48,$0EA30C12
	dc.l	$0C980BF2,$0FA10CDE,$0E9701FD,$0EA60AB3
	dc.l	$0FB408A6,$0CA90CBA,$0FB508EE,$0EB70C4C
	dc.l	$0CBA0F9C,$0FC709A6,$0FC80A9F,$0FCA0177
	dc.l	$0DCC0E94,$0FDB0EF1,$0FDC032C,$0FED0DCE
	even

g2inter_pal_theend
	dc.l	$00000000,$08440213,$0F440F90,$04100259
	dc.l	$01200F5F,$020005EB,$0F010FF2,$00000D86
	dc.l	$00000AAA,$0110011D,$00110F67,$0F110F76
	dc.l	$021105C9,$09990286,$0CA90AA9,$0985030B
	dc.l	$0CCC0EFF,$0B760370,$0CCB0E24,$08870856
	dc.l	$030004AA,$02220131,$0A870238,$055509C7
	dc.l	$0BBA0B32,$0310089D,$0DCA0D6A,$064307A9
	dc.l	$031104E8,$03220551,$0CCC0EB0,$0EED0233
	dc.l	$02320C0C,$0DCB0C98,$04110678,$0F320F2A
	dc.l	$0421053C,$0432050B,$0AA90B02,$04310A8F
	dc.l	$0DB9062A,$0A870FB6,$0A970BAA,$043308B2
	dc.l	$0B970E9E,$0CBC0CF2,$09450083,$088809E4
	dc.l	$0521052C,$0F330FE9,$0AAA0CF8,$0532032C
	dc.l	$05320702,$061100EB,$06540626,$0BA901BD
	dc.l	$053307D0,$06320581,$054207BD,$0BA90CBA
	dc.l	$0CBA0975,$06330720,$0BBA0FCF,$06430500
	even

g2inter_pal_mansion
	dc.l	$00000000,$00000111,$0F000F00,$0F000F00
	dc.l	$00000555,$00000777,$00000AAA,$00000CCC
	dc.l	$00000EEE,$01110000,$01110111,$01110333
	dc.l	$01110666,$01110777,$01110999,$01110BBB
	dc.l	$01110DDD,$02220000,$02220111,$02220444
	dc.l	$02220555,$02220888,$02220999,$02220BBB
	dc.l	$02220DDD,$02220FFF,$03330222,$03330444
	dc.l	$03330555,$03330888,$03330999,$03330BBB
	dc.l	$03330DDD,$03330FFF,$04440111,$04440333
	dc.l	$04440666,$04440888,$04440AAA,$04440CCC
	dc.l	$04440EEE,$05550000,$05550222,$05550444
	dc.l	$05550AAA,$05550BBB,$05550DDD,$05550FFF
	dc.l	$06660111,$06660444,$06660666,$06660777
	dc.l	$06660999,$06660CCC,$06660EEE,$06660FFF
	dc.l	$07770111,$07770444,$07770555,$07770888
	dc.l	$07770AAA,$07770BBB,$07770EEE,$07770FFF
	dc.l	$08880111,$08880444,$08880555,$08880888
	dc.l	$08880AAA,$08880BBB,$08880EEE,$08880FFF
	dc.l	$09990111,$09990444,$09990555,$09990888
	dc.l	$09990999,$09990BBB,$09990DDD,$0AAA0000
	dc.l	$0AAA0111,$0AAA0333,$0AAA0555,$0AAA0777
	dc.l	$0AAA0AAA,$0AAA0CCC,$0AAA0DDD,$0BBB0000
	dc.l	$0BBB0222,$0BBB0444,$0BBB0555,$0BBB0777
	dc.l	$0BBB0AAA,$0BBB0BBB,$0BBB0EEE,$0CCC0000
	dc.l	$0CCC0111,$0CCC0444,$0CCC0666,$0CCC0888
	dc.l	$0CCC0AAA,$0CCC0BBB,$0CCC0DDD,$0DDD0000
	dc.l	$0DDD0222,$0DDD0444,$0DDD0555,$0DDD0777
	dc.l	$0DDD0AAA,$0DDD0BBB,$0DDD0DDD,$0EEE0000
	dc.l	$0EEE0222,$0EEE0444,$0EEE0555,$0EEE0888
	dc.l	$0EEE0AAA,$0EEE0CCC,$0EEE0EEE,$0FFF0000
	dc.l	$0FFF0222,$0FFF0444,$0FFF0666,$0FFF0777
	dc.l	$0FFF0AAA,$0FFF0CCC,$0FFF0EEE,$0FFF0FFF
	even

g2inter_pal_words
	dc.l	$00000000,$00000111,$0F000F00,$0F000F00
	dc.l	$00000555,$00000777,$00000AAA,$00000CCC
	dc.l	$00000EEE,$01110000,$01110111,$01110333
	dc.l	$01110666,$01110777,$01110999,$01110BBB
	dc.l	$01110DDD,$02220000,$02220111,$02220444
	dc.l	$02220555,$02220888,$02220999,$02220BBB
	dc.l	$02220DDD,$02220FFF,$03330222,$03330444
	dc.l	$03330555,$03330888,$03330999,$03330BBB
	dc.l	$03330DDD,$03330FFF,$04440111,$04440333
	dc.l	$04440666,$04440888,$04440AAA,$04440CCC
	dc.l	$04440EEE,$05550000,$05550222,$05550444
	dc.l	$05550AAA,$05550BBB,$05550DDD,$05550FFF
	dc.l	$06660111,$06660444,$06660666,$06660777
	dc.l	$06660999,$06660CCC,$06660EEE,$06660FFF
	dc.l	$07770111,$07770444,$07770555,$07770888
	dc.l	$07770AAA,$07770BBB,$07770EEE,$07770FFF
	dc.l	$08880111,$08880444,$08880555,$08880888
	dc.l	$08880AAA,$08880BBB,$08880EEE,$08880FFF
	dc.l	$09990111,$09990444,$09990555,$09990888
	dc.l	$09990999,$09990BBB,$09990DDD,$0AAA0000
	dc.l	$0AAA0111,$0AAA0333,$0AAA0555,$0AAA0777
	dc.l	$0AAA0AAA,$0AAA0CCC,$0AAA0DDD,$0BBB0000
	dc.l	$0BBB0222,$0BBB0444,$0BBB0555,$0BBB0777
	dc.l	$0BBB0AAA,$0BBB0BBB,$0BBB0EEE,$0CCC0000
	dc.l	$0CCC0111,$0CCC0444,$0CCC0666,$0CCC0888
	dc.l	$0CCC0AAA,$0CCC0BBB,$0CCC0DDD,$0DDD0000
	dc.l	$0DDD0222,$0DDD0444,$0DDD0555,$0DDD0777
	dc.l	$0DDD0AAA,$0DDD0BBB,$0DDD0DDD,$0EEE0000
	dc.l	$0FF00FF0,$0EEE0444,$0EEE0555,$0EEE0888
	dc.l	$0EEE0AAA,$0EEE0CCC,$0EEE0EEE,$0FFF0000
	dc.l	$0FFF0222,$0FFF0444,$0FFF0666,$0FFF0777
	dc.l	$0FFF0AAA,$0FFF0CCC,$0FFF0EEE,$0FFF0FFF
	even

g2inter_pal_alphasoftw
	dc.l	$00000000,$00000000,$046F04DF,$068B068B
	dc.l	$07000F00,$03330FFF,$05110FFF,$05510FFF
	dc.l	$07330FFF,$03300FF0,$05150FFF,$03000F00
	dc.l	$01150FFF,$01110FFF,$07300FF0,$05550FFF
	dc.l	$03700FF0,$0F330FFF,$00000000,$0DDD0FFF
	dc.l	$09110FFF,$0003000F,$003000F0,$03730FFF
	dc.l	$09510FFF,$03370FFF,$03070F0F,$0B000F00
	dc.l	$0007000F,$07700FF0,$07730FFF,$07070F0F
	dc.l	$007000F0,$0B300FF0,$07370FFF,$0B330FFF
	dc.l	$01190FFF,$01910FFF,$05190FFF,$007700FF
	dc.l	$09550FFF,$0D110FFF,$05590FFF,$00B000F0
	dc.l	$07770FFF,$000B000F,$0B700FF0,$033B0FFF
	dc.l	$03B30FFF,$08880000,$004D004D,$09910FFF
	dc.l	$07B00FF0,$0B730FFF,$037B0FFF,$07B30FFF
	dc.l	$03F30FFF,$00BF00FF,$073B0FFF,$0F000F00
	dc.l	$0D510FFF,$0B370FFF,$00F000F0,$05D505D5
	dc.l	$03B70FFF,$000F000F,$033F0FFF,$09590FFF
	dc.l	$0DD10FFF,$0E900E90,$0E440E44,$0B0F0F0F
	dc.l	$0F070F0F,$0D550FFF,$0BB00FF0,$09950FFF
	dc.l	$0A970000,$0B0B0F0F,$070F0F0F,$0B770FFF
	dc.l	$07F00FF0,$07B70FFF,$09990000,$077B0FFF
	dc.l	$05990FFF,$09990FFF,$00FB00FF,$00BB00FF
	dc.l	$00F700FF,$007F00FF,$07BB0FFF,$07F70FFF
	dc.l	$077F0FFF,$09BD0463,$0B7B0FFF,$0FBF0FFF
	dc.l	$0DD90FFF,$0FB70FFF,$0D9D0FFF,$0D990FFF
	dc.l	$0D950FFF,$0F3F0FFF,$0F770FFF,$0F730FFF
	dc.l	$09CF081F,$09D90FFF,$0BB70FFF,$099D0FFF
	dc.l	$0BBB0FFF,$0BF70FFF,$0B7F0FFF,$0F7B0FFF
	dc.l	$0FA90F97,$07BF0FFF,$07FB0FFF,$0BF00FF0
	dc.l	$0BBF0FFF,$03FF0FFF,$0BFB0FFF,$07FF0FFF
	dc.l	$0FBB0FFF,$0F300FF0,$0FF00FF0,$0FB00FF0
	dc.l	$0F700FF0,$0FFB0FFF,$0FF30FFF,$0FFF0FFF
	even

g2inter_pal_g3dc
	dc.l	$00000000,$02100210,$03200320,$0FFF0EEE
	dc.l	$03300330,$04400440,$02000200,$01000100
	dc.l	$05500550,$04500450,$06400640,$0FFF0333
	dc.l	$04300430,$05400540,$02220999,$04200420
	dc.l	$03000300,$07500750,$03100310,$0EEE0BBB
	dc.l	$0DDD0BBB,$00000999,$05300530,$01110BBB
	dc.l	$01110333,$03400340,$0EEE0322,$08500850
	dc.l	$06300630,$02220333,$0CCC0CCB,$06500650
	dc.l	$0DDD0332,$07600760,$03330222,$0BBB0BBB
	dc.l	$0CCC0221,$04440BBB,$04100410,$03330788
	dc.l	$08600860,$05550999,$0BBB0222,$07400740
	dc.l	$08700870,$04440333,$0EEE0987,$05550444
	dc.l	$09700981,$03330DCC,$05200520,$09990CBA
	dc.l	$09990433,$0AAA0544,$0EED000F,$09600960
	dc.l	$0AAA0CCB,$07770AAA,$063002AA,$07770333
	dc.l	$08880222,$02210F03,$06200620,$06660CCB
	dc.l	$02000FAA,$08880CCC,$041006BF,$0876063C
	dc.l	$043207BB,$06660333,$0654011F,$0F0005BA
	dc.l	$0C000D44,$0BBB0FA2,$03220D22,$0BBA0849
	dc.l	$0A9906B9,$0BAA03D7,$0AA90A89,$066407B6
	dc.l	$0AA80B1C,$02000588,$0210077A,$053305DD
	dc.l	$06540799,$03220CE0,$08860843,$08880B97
	dc.l	$087704A9,$0BBB0F30,$075504AA,$06550A88
	dc.l	$0DDD0962,$08610899,$0EED0204,$0552022B
	dc.l	$03110652,$0AAA0831,$0AAA0DA2,$0BA905B7
	dc.l	$04220C99,$04330811,$08770DFA,$07660BB7
	dc.l	$08880963,$0CCC0787,$064402C2,$09880674
	dc.l	$0A9705B8,$0A960335,$09980CDA,$09980A27
	dc.l	$085302F2,$0874044C,$09970D24,$02000911
	dc.l	$043001CD,$098509D0,$07660270,$0CB90469
	dc.l	$0CBA0082,$0986075B,$0764079B,$0CCC0C50
	dc.l	$06510B6D,$0DDC041A,$06400178,$097601D5
	even

g2inter_pal_combat
	dc.l	$00000664,$0F120FA1,$0F100F3B,$0F210F0A
	dc.l	$03320B5A,$0F100F9A,$04300E5F,$05210434
	dc.l	$06310748,$04430614,$07210BC4,$06430231
	dc.l	$05540745,$073105FB,$08410A36,$07510B57
	dc.l	$08430230,$06540E67,$09420946,$0853006B
	dc.l	$0A410644,$05650C2B,$095401F1,$076604B0
	dc.l	$09510DBD,$09750411,$0A530753,$0B5208E1
	dc.l	$0A730189,$0B710A7E,$0B63045F,$07770BE9
	dc.l	$0B730EDD,$0A7604F4,$0B750ADC,$0D740023
	dc.l	$098805C2,$0C820DE8,$0D8304BB,$0B960912
	dc.l	$0B97037C,$0D95066D,$0DA60246,$0E910709
	dc.l	$0E940419,$0EA4044F,$0AA90F48,$0EA30C12
	dc.l	$0C980BF2,$0FA10CDE,$0E9701FD,$0EA60AB3
	dc.l	$0FB408A6,$0CA90CBA,$0FB508EE,$0EB70C4C
	dc.l	$0CBA0F9C,$0FC709A6,$0FC80A9F,$0FCA0177
	dc.l	$0DCC0E94,$0FDB0EF1,$0FDC032C,$0FED0DCE
	dc.l	$08880111,$08880444,$08880666,$08880777
	dc.l	$08880AAA,$08880CCC,$08880DDD,$09990000
	dc.l	$09990111,$09990444,$09990666,$09990777
	dc.l	$09990999,$09990BBB,$09990EEE,$09990FFF
	dc.l	$0AAA0111,$0AAA0333,$0AAA0555,$0AAA0777
	dc.l	$0AAA0AAA,$0AAA0BBB,$0AAA0EEE,$0BBB0000
	dc.l	$0BBB0222,$0BBB0333,$0BBB0666,$0BBB0888
	dc.l	$0BBB0AAA,$0BBB0BBB,$0BBB0DDD,$0BBB0FFF
	dc.l	$0CCC0111,$0CCC0333,$0CCC0666,$0CCC0888
	dc.l	$0CCC0999,$0CCC0CCC,$0CCC0EEE,$0CCC0FFF
	dc.l	$0DDD0222,$0DDD0444,$0DDD0555,$0DDD0888
	dc.l	$0DDD0999,$0DDD0CCC,$0DDD0EEE,$0EEE0000
	dc.l	$0EEE0111,$0EEE0444,$0EEE0666,$0EEE0777
	dc.l	$0EEE0AAA,$0EEE0CCC,$0EEE0EEE,$0FFF0000
	dc.l	$0FFF0222,$0FFF0444,$0FFF0666,$0FFF0888
	dc.l	$0FFF0AAA,$0FFF0CCC,$0FFF0EEE,$0FFF0FFF
	even



; -----------------------------------------------------------------------------
; c87b10: graded yellow intermission text over exact embedded palettes
;
; c87b7 remains the confirmed source of truth for Gloom3/ZM picture colours.
; The original Bigfont has three non-transparent palette levels (1..3).  This
; path preserves all three levels instead of flattening them to one solid
; yellow.  If the picture depth leaves at least three free screen entries, the
; exact Bigfont palette colours are copied there.  With a full-depth picture,
; three distinct existing colours nearest to the Bigfont shades are selected,
; so no picture palette entry is modified.
; -----------------------------------------------------------------------------

g2ecs4_prepare_loaded_ehb_text_palette
	; in: a0 = selected trimmed-IFF picture, a1 = selected ECS .pal
	; c87b23: all ECS profiles now use their generated per-picture EHB palette.
	; The editor reserves the verified Bigfont shades, so the same isolated
	; glyph-colour preparation is valid for Gloom3 and Zombie Massacre too.
	movem.l	d0-d7/a0-a5,-(a7)
	tst	aga
	bne.w	.done
	lea	g2inter_yellow_text_indices,a5
	move	#-1,(a5)
	move	#-1,2(a5)
	move	#-1,4(a5)
	clr	g2inter_yellow_text_active
	clr.l	g2inter_exact_palette_ptr
	tst.l	a0
	beq.w	.done
	tst.l	a1
	beq.w	.done
	move.l	a1,a4
	move.l	a1,g2inter_exact_palette_ptr

	; Visible ECS/EHB palette size comes from source depth, capped at 64.
	moveq	#0,d1
	move	4(a0),d1
	cmp	#2,d1
	blo.w	.done
	cmp	#6,d1
	bls.s	.depth_ok
	moveq	#6,d1
.depth_ok
	moveq	#1,d7
	lsl	d1,d7
	cmp	#4,d7
	blo.w	.done
	cmp	#64,d7
	bls.s	.count_ok
	moveq	#64,d7
.count_ok
	move	d7,g2inter_work_palette_count

	; Copy all visible palette words.  A correct EHB .pal stores 32 base words
	; followed by their 32 half-bright words, so indices 0..63 can be compared
	; directly and selected without touching the hardware palette.
	lea	g2inter_work_palette,a2
	move	d7,d5
	subq	#1,d5
.copy_palette
	move	(a4)+,(a2)+
	dbf	d5,.copy_palette

	; Read the three real Bigfont shades, with safe yellow fallbacks.
	lea	g2inter_font_yellow_rgb12,a3
	move	#$0880,(a3)
	move	#$0cc0,2(a3)
	move	#$0ff0,4(a3)
	move.l	font,d0
	beq.s	.have_font_colours
	move.l	d0,a2
	add.l	(a2),a2
	move	2(a2),(a3)
	move	4(a2),2(a3)
	move	6(a2),4(a3)
.have_font_colours

	; Choose three distinct existing EHB indices nearest to the font shades.
	moveq	#0,d6
.find_loop
	cmp	#3,d6
	bge.s	.done
	move	d6,d1
	add	d1,d1
	move	0(a3,d1.w),d0
	move	d0,g2inter_nearest_target
	jsr	g2inter_find_nearest_distinct_colour
	move	d6,d1
	add	d1,d1
	move	d4,0(a5,d1.w)
	addq	#1,d6
	bra.s	.find_loop
.done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

g2inter_build_work_palette
	; in: a1 = immutable embedded exact palette
	; out: a1 = private writable exact palette
	movem.l	d0-d7/a0/a2-a5,-(a7)
	lea	g2inter_yellow_text_indices,a5
	move	#-1,(a5)
	move	#-1,2(a5)
	move	#-1,4(a5)
	clr	g2inter_yellow_text_active
	move.l	a1,a4
	lea	g2inter_work_palette,a2
	; Clear the complete 1024-byte AGA-sized buffer.
	moveq	#0,d0
	move	#255,d7
.g2c87b10_clear_work
	move.l	d0,(a2)+
	dbf	d7,.g2c87b10_clear_work
	; Determine actual picture palette entries from trimmed-IFF depth.
	move	colours,d7
	move.l	pic,d0
	beq	.g2c87b10_have_count
	move.l	d0,a0
	moveq	#0,d1
	move	4(a0),d1
	cmp	#1,d1
	blo	.g2c87b10_have_count
	cmp	#8,d1
	bhi	.g2c87b10_have_count
	moveq	#1,d7
	lsl	d1,d7
	cmp	colours,d7
	bls	.g2c87b10_have_count
	move	colours,d7
.g2c87b10_have_count
	move	d7,g2inter_work_palette_count
	lea	g2inter_work_palette,a2
	tst	aga
	beq	.g2c87b10_copy_ecs
	move	d7,d6
	subq	#1,d6
.g2c87b10_copy_aga
	move.l	(a4)+,(a2)+
	dbf	d6,.g2c87b10_copy_aga
	bra	.g2c87b10_choose_indices
.g2c87b10_copy_ecs
	move	d7,d6
	subq	#1,d6
.g2c87b10_copy_ecs_loop
	move	(a4)+,(a2)+
	dbf	d6,.g2c87b10_copy_ecs_loop

.g2c87b10_choose_indices
	; Read the real Bigfont palette entries 1..3.  These are the exact shades
	; used by Gloom/Gloom Deluxe.  Safe fallback values are used only if the
	; font asset is unexpectedly unavailable.
	lea	g2inter_font_yellow_rgb12,a3
	move	#$0880,(a3)
	move	#$0cc0,2(a3)
	move	#$0ff0,4(a3)
	move.l	font,d0
	beq	.g2c87b10_have_font_colours
	move.l	d0,a0
	add.l	(a0),a0
	move	2(a0),(a3)
	move	4(a0),2(a3)
	move	6(a0),4(a3)
.g2c87b10_have_font_colours
	; Prefer three entries outside the picture depth.
	move	colours,d0
	sub	d7,d0
	cmp	#3,d0
	bcs	.g2c87b10_find_existing_shades
	move	colours,d0
	subq	#3,d0
	lea	g2inter_yellow_text_indices,a5
	move	d0,(a5)
	addq	#1,d0
	move	d0,2(a5)
	addq	#1,d0
	move	d0,4(a5)
	; Install the exact three Bigfont RGB12 shades in the free slots.
	lea	g2inter_font_yellow_rgb12,a3
	lea	g2inter_yellow_text_indices,a5
	moveq	#2,d5
.g2c87b10_install_spare_loop
	move	(a5)+,d0
	move	(a3)+,d1
	move	d0,d2
	tst	aga
	beq	.g2c87b10_install_spare_ecs
	lsl	#2,d2
	lea	g2inter_work_palette,a2
	move	d1,0(a2,d2.w)
	clr	2(a2,d2.w)
	bra	.g2c87b10_install_spare_next
.g2c87b10_install_spare_ecs
	add	d2,d2
	lea	g2inter_work_palette,a2
	move	d1,0(a2,d2.w)
.g2c87b10_install_spare_next
	dbf	d5,.g2c87b10_install_spare_loop
	bra	.g2c87b10_work_done

.g2c87b10_find_existing_shades
	; Full-depth image: map each Bigfont shade to a distinct existing palette
	; entry nearest in RGB12 space.  The picture palette itself is untouched.
	lea	g2inter_font_yellow_rgb12,a3
	lea	g2inter_yellow_text_indices,a5
	moveq	#0,d6		; number of already chosen entries
.g2c87b10_find_shade_loop
	cmp	#3,d6
	bge	.g2c87b10_work_done
	move	d6,d1
	add	d1,d1
	move	0(a3,d1.w),d0
	move	d0,g2inter_nearest_target
	jsr	g2inter_find_nearest_distinct_colour
	move	d6,d1
	add	d1,d1
	move	d4,0(a5,d1.w)
	addq	#1,d6
	bra	.g2c87b10_find_shade_loop

.g2c87b10_work_done
	lea	g2inter_work_palette,a1
	movem.l	(a7)+,d0-d7/a0/a2-a5
	rts

; Input: g2inter_nearest_target=target RGB12,
;        d6=number of previously selected indices (0..2),
;        d7=palette entry count.  Output: d4=nearest unused palette index.
g2inter_find_nearest_distinct_colour
	movem.l	d0-d3/d5/a0-a2,-(a7)
	move	#32767,d5	; best score
	moveq	#1,d4		; best index (never transparent index 0)
	moveq	#1,d3		; candidate index
	lea	g2inter_work_palette,a2
.g2c87b10_nearest_loop
	cmp	d7,d3
	bge	.g2c87b10_nearest_done
	; Skip indices already selected for darker shades.
	moveq	#0,d1
	lea	g2inter_yellow_text_indices,a0
.g2c87b10_used_loop
	cmp	d6,d1
	bge	.g2c87b10_not_used
	move	d1,d2
	add	d2,d2
	cmp	0(a0,d2.w),d3
	beq	.g2c87b10_nearest_next
	addq	#1,d1
	bra	.g2c87b10_used_loop
.g2c87b10_not_used
	; Load candidate RGB12 high word.
	move	d3,d1
	tst	aga
	beq	.g2c87b10_nearest_ecs_addr
	lsl	#2,d1
	bra	.g2c87b10_nearest_addr_ready
.g2c87b10_nearest_ecs_addr
	add	d1,d1
.g2c87b10_nearest_addr_ready
	moveq	#0,d0
	move	0(a2,d1.w),d0
	move.l	d0,a1		; preserve candidate RGB12
	moveq	#0,d2		; accumulated Manhattan distance
	; Red distance.
	and	#$0f00,d0
	move	g2inter_nearest_target,d1
	and	#$0f00,d1
	sub	d1,d0
	bpl	.g2c87b10_r_abs
	neg	d0
.g2c87b10_r_abs
	lsr	#8,d0
	add	d0,d2
	; Green distance.
	move.l	a1,d0
	and	#$00f0,d0
	move	g2inter_nearest_target,d1
	and	#$00f0,d1
	sub	d1,d0
	bpl	.g2c87b10_g_abs
	neg	d0
.g2c87b10_g_abs
	lsr	#4,d0
	add	d0,d2
	; Blue distance.
	move.l	a1,d0
	and	#$000f,d0
	move	g2inter_nearest_target,d1
	and	#$000f,d1
	sub	d1,d0
	bpl	.g2c87b10_b_abs
	neg	d0
.g2c87b10_b_abs
	add	d0,d2
	cmp	d5,d2
	bge	.g2c87b10_nearest_next
	move	d2,d5
	move	d3,d4
.g2c87b10_nearest_next
	addq	#1,d3
	bra	.g2c87b10_nearest_loop
.g2c87b10_nearest_done
	movem.l	(a7)+,d0-d3/d5/a0-a2
	rts

; After showpic installed only the source-depth entries, install the complete
; private palette so the three out-of-depth font shades are also present.
g2inter_install_work_palette
	movem.l	d0-d1/a0-a1,-(a7)
	move	g2inter_yellow_text_indices,d0
	bmi	.g2c87b10_install_done
	move.l	g2inter_exact_palette_ptr,d1
	beq	.g2c87b10_install_done
	lea	g2inter_work_palette,a0
	move.l	a0,d0
	cmp.l	d0,d1
	bne	.g2c87b10_install_done
	move.l	a0,a1
	move	colours,d0
	jsr	pokepal2
.g2c87b10_install_done
	movem.l	(a7)+,d0-d1/a0-a1
	rts

; Called before printmess2, while no blitter ownership is held.
g2inter_prepare_yellow_text
	movem.l	d0-d2,-(a7)
	clr	g2inter_yellow_text_active
	; All ECS profiles use isolated glyph recolouring.  On AGA retain the
	; existing exact-palette path only for Zombie Massacre and Gloom3.
	tst	aga
	beq	.g2c87b10_prepare_profile_ok
	cmp	#2,g2_game_profile
	beq	.g2c87b10_prepare_profile_ok
	cmp	#3,g2_game_profile
	bne	.g2c87b10_prepare_done
.g2c87b10_prepare_profile_ok
	tst.l	g2inter_exact_palette_ptr
	beq	.g2c87b10_prepare_done
	tst	g2inter_yellow_text_indices
	bmi	.g2c87b10_prepare_done
	jsr	g2p96_menu_glyph_cache_ensure
	tst	d0
	beq	.g2c87b10_prepare_done
	move	#-1,g2inter_yellow_text_active
.g2c87b10_prepare_done
	movem.l	(a7)+,d0-d2
	rts

; Called immediately after blit() for one printmess2 character.
; a4 points one byte past the character; d7=X and d6=Y.
g2inter_recolour_last_glyph_yellow
	movem.l	d0-d7/a0-a6,-(a7)
	tst	g2inter_yellow_text_active
	beq.w	.g2c87b10_recolour_done
	moveq	#0,d0
	move.b	-1(a4),d0
	cmp.b	#' ',d0
	beq.w	.g2c87b10_recolour_done
	cmp.b	#'\',d0
	beq.w	.g2c87b10_recolour_done
	cmp.b	#"'",d0
	beq.w	.g2c87b10_recolour_done
	jsr	g2p96_menu_glyph_calcchar
	cmp	#-1,d0
	beq.w	.g2c87b10_recolour_done
.g2c87b10_wait_blit
	btst	#6,$dff002
	bne	.g2c87b10_wait_blit
	move.l	p96menu_glyph_cache_ptr,a2
	mulu	#p96menu_glyph_bytes,d0
	adda.l	d0,a2
	lea	g2inter_yellow_text_indices,a6
	moveq	#0,d3		; glyph row
.g2c87b10_recolour_row
	cmp	#p96menu_glyph_height,d3
	bge.w	.g2c87b10_recolour_done
	moveq	#0,d2		; glyph column
.g2c87b10_recolour_col
	cmp	#p96menu_glyph_width,d2
	bge	.g2c87b10_recolour_next_row
	moveq	#0,d5
	move.b	(a2)+,d5
	beq	.g2c87b10_recolour_next_col
	cmp	#3,d5
	bls	.g2c87b10_recolour_level_ok
	moveq	#3,d5
.g2c87b10_recolour_level_ok
	subq	#1,d5
	add	d5,d5
	move	0(a6,d5.w),d5
	tst	d5
	bmi	.g2c87b10_recolour_next_col
	move	d7,d0
	add	d2,d0
	cmp	#320,d0
	bge	.g2c87b10_recolour_next_col
	tst	d0
	blt	.g2c87b10_recolour_next_col
	move	d6,d1
	add	d3,d1
	cmp	#240,d1
	bge	.g2c87b10_recolour_next_col
	tst	d1
	blt	.g2c87b10_recolour_next_col
	move.l	showbitmap,a0
	move	d1,d4
	mulu	linemodw,d4
	adda.l	d4,a0
	move	d0,d4
	lsr	#3,d4
	adda.w	d4,a0
	and	#7,d0
	moveq	#7,d4
	sub	d0,d4
	moveq	#0,d1
.g2c87b10_recolour_plane
	cmp	bitplanes,d1
	bge	.g2c87b10_recolour_next_col
	btst	d1,d5
	beq	.g2c87b10_recolour_clear
	bset	d4,(a0)
	bra	.g2c87b10_recolour_plane_next
.g2c87b10_recolour_clear
	bclr	d4,(a0)
.g2c87b10_recolour_plane_next
	adda.l	bpmod,a0
	addq	#1,d1
	bra	.g2c87b10_recolour_plane
.g2c87b10_recolour_next_col
	addq	#1,d2
	bra	.g2c87b10_recolour_col
.g2c87b10_recolour_next_row
	addq	#1,d3
	bra.w	.g2c87b10_recolour_row
.g2c87b10_recolour_done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

	even
g2inter_yellow_text_active	dc	0
g2inter_yellow_text_indices	dc	-1,-1,-1
g2inter_font_yellow_rgb12	dc	$0880,$0cc0,$0ff0
g2inter_nearest_target	dc	0
g2inter_work_palette_count	dc	0
g2inter_work_palette	ds.b	1024
	even

	even
; c87w5: relocated original qmenu implementation.  The public qmenu entry is
; a fixed 6-byte JMP so the four extra menustrips longs consume exactly the
; 16 bytes saved from the former 22-byte inline body.  pmenu and every later
; proven code/data label therefore retain their WIDE4 addresses.
g2wide_qmenu_relocated
	move.l	a0,-(a7)
	jsr	clspic
	jsr	g2p96_title_qmenu_background_if_active
	move.l	(a7)+,a4
	jsr	initmenu
	jmp	dispon

; -----------------------------------------------------------------------------
; c87w6: final FLOOR/CEILING QUIT-row repair.
;
; The live refresh itself and the earlier c87w4 redraw both happened before the
; release wait had fully completed.  Real hardware shows that the final menu
; state reached after that wait can still lack the last row, while moving the
; cursor to QUIT immediately restores it.  Therefore use the exact proven P96
; navigation row path only after g2v17_wait_menu_release has returned.
;
; This helper is called only from the FLOOR/CEILING refresh tail and leaves AGA/
; ECS untouched. c87b79l applies the proven post-release redraw to every native
; P96 geometry in ONE PLAYER and TWO PLAYER. The active row remains selected.
; -----------------------------------------------------------------------------
g2wide_floorceil_wait_release_quit_fix
	jsr	g2v17_wait_menu_release
	movem.l	d0-d2/d6-d7,-(a7)
	; c87b79l: the post-release final-row loss is not geometry-specific.  Apply
	; the exact proven navigation redraw to every active native P96 in-game menu,
	; including standard, 5:4 and WIDE in ONE PLAYER and TWO PLAYER.
	cmp	#2,g2display_mode
	bne.w	.done
	cmp	#P96DSP_MENU,p96display_state
	bne.w	.done
	tst	p96gameplay_persist_active
	beq.w	.done
	move	curropt,d6
	move	p96menu_blink_visible,d7
	move	numopts,d0
	beq.s	.restore
	subq	#1,d0
	move	d0,curropt
	; Draw the final QUIT row through the same normal-row path used by navigation.
	jsr	g2p96_menu_native_nav_normal
.restore
	move	d6,curropt
	; Restore the active FLOOR/CEILING row and its saved blink phase.
	jsr	g2p96_menu_native_nav_select
	move	d7,p96menu_blink_visible
.done
	movem.l	(a7)+,d0-d2/d6-d7
	rts


; -----------------------------------------------------------------------------
; c87p1: P96 5:4 static-picture presenter.
; The original 320x240 artwork is kept pixel exact and centred in 320x256.
; HIRES doubles it to 640x480 inside 640x512. The first and last source rows
; are extended vertically through the same 1/4, 1/2, 3/4, full RGB565 shading
; used by WIDE's horizontal edge wash.
; -----------------------------------------------------------------------------
g2oneone_static_build_rgb_buffer
	movem.l	d0-d7/a0-a6,-(a7)
	tst	p96static_direct_valid	;c87b79x: direct index source required
	beq.w	.done
	move.l	p96static_direct_index_ptr,d0
	beq.w	.done
	suba.l	a4,a4
	move.l	p96static_rgbbufptr,d0
	beq.w	.done
	lea	p96static_rgb565_lut,a5

	; top physical border: 8 rows lowres, 16 rows HIRES
	moveq	#8,d5
	tst	g2p96_hires_mode
	beq.s	.top_count_ready
	move	#16,d5
.top_count_ready
	moveq	#0,d4		; physical destination y
.top_loop
	cmp	d5,d4
	bge.s	.center_setup
	moveq	#0,d6		; source row 0
	jsr	g2p96_static_decode_index_row_best
	moveq	#0,d3
	move	d4,d3
	lsl	#2,d3
	divu	d5,d3		; 0..3, darker toward physical top
	jsr	g2oneone_static_emit_physical_row
	addq	#1,d4
	bra.s	.top_loop

.center_setup
	moveq	#0,d6		; source y 0..239
.center_loop
	cmp	#240,d6
	bge.s	.bottom_setup
	jsr	g2p96_static_decode_index_row_best
	move	d6,d4
	tst	g2p96_hires_mode
	beq.s	.center_low
	add	d4,d4
	add	#16,d4
	moveq	#3,d3
	jsr	g2oneone_static_emit_physical_row
	addq	#1,d4
	moveq	#3,d3
	jsr	g2oneone_static_emit_physical_row
	bra.s	.center_next
.center_low
	addq	#8,d4
	moveq	#3,d3
	jsr	g2oneone_static_emit_physical_row
.center_next
	addq	#1,d6
	bra.s	.center_loop

.bottom_setup
	moveq	#8,d5
	move	#248,d4
	tst	g2p96_hires_mode
	beq.s	.bottom_ready
	move	#16,d5
	move	#496,d4
.bottom_ready
	moveq	#0,d7		; border row index 0..d5-1
.bottom_loop
	cmp	d5,d7
	bge.s	.done
	move	#239,d6
	jsr	g2p96_static_decode_index_row_best
	move	d5,d3
	subq	#1,d3
	sub	d7,d3
	lsl	#2,d3
	divu	d5,d3		; 3..0, darker toward physical bottom
	jsr	g2oneone_static_emit_physical_row
	addq	#1,d4
	addq	#1,d7
	bra.s	.bottom_loop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; a6 = decoded 320-byte palette-index row, d4 = physical target y,
; d3 = shade 0..3. Horizontal output is 320 pixels or exact 2x 640 pixels.
g2oneone_static_emit_physical_row
	movem.l	d0-d7/a0-a3,-(a7)
	move.l	p96static_rgbbufptr,a1
	move.l	p96static_rgbbpr,d0
	mulu	d4,d0
	adda.l	d0,a1
	moveq	#0,d7
.pixel_loop
	cmp	#320,d7
	bge.s	.done
	moveq	#0,d1
	move.b	0(a6,d7.w),d1
	add	d1,d1
	move	0(a5,d1.w),d2
	jsr	g2wide_rgb565_shade
	move	d2,(a1)+
	tst	g2p96_hires_mode
	beq.s	.next
	move	d2,(a1)+
.next
	addq	#1,d7
	bra.s	.pixel_loop
.done
	movem.l	(a7)+,d0-d7/a0-a3
	rts


; -----------------------------------------------------------------------------
; c87p2: P96 5:4 menu Y-origin helpers.
; Appended deliberately: all existing code/data labels keep their p1 addresses.
; -----------------------------------------------------------------------------
g2p96_title_batch_get_src_y0_physical
	move	p96menu_batch_src_y0,d0
	tst	g2p96_oneone_mode
	beq.w	.done
	addq	#8,d0		;HIRES doubles d0 immediately afterwards -> +16
.done
	rts

; d0 is an already scaled title-menu row in the legacy 240/480 coordinate
; system. Preserve caller d0 because the HIRES caller invokes this twice for
; d0 and d0+1. The staged 5:4 title buffer and visible bitmap both begin the
; original picture at physical Y=8 or Y=16.
g2p96_title_menu_copy_one_scaled_row_1to1
	movem.l	d0-d1,-(a7)
	tst	g2p96_oneone_mode
	beq.s	.copy
	tst	g2p96_hires_mode
	beq.s	.low
	add	#16,d0
	bra.s	.copy
.low
	addq	#8,d0
.copy
	jsr	g2p96_title_menu_copy_one_scaled_row
	movem.l	(a7)+,d0-d1
	rts

; -----------------------------------------------------------------------------
; c87p3: runtime dimensions for the native P96 5:4 split presenter.
; Appended so all prior proven code/data labels retain their p2 addresses.
; -----------------------------------------------------------------------------
g2twop_half_height	dc	120	;120 legacy/AGA, 128 while P96 5:4 owns gameplay
g2p96_present_rows	dc	240	;actual chunky rows consumed by the direct P96 presenter
	even




; -----------------------------------------------------------------------------
; c87b80d: ECS core asset validation (release-candidate path).
; The former DH3 stage logger was permanently disabled and has been removed.
; -----------------------------------------------------------------------------
; ECS2: core ECS data validation and visible missing-file warning.
;
; The original loadfiles/loadfile contract treats a missing file as a zero
; pointer and continues.  That is useful for genuinely optional resources, but
; it made an incomplete ECS data installation look like a renderer failure:
;   - missing EHB BlackMagic image or pics_ehb/blackmagic.pal -> clean black fallback and asset warning
;   - missing pics_ehb/title          -> black title picture
;   - missing pics_ehb intermissions  -> black picture, correctly drawn text
;   - missing palette_6/remap_6       -> psychedelic gameplay colours
;
; This checker changes no AGA/P96 path and does not substitute 8-bit AGA data.
; It still validates every required core pointer and raises
; a one-item menu warning after the normal menu font has been selected.
; -----------------------------------------------------------------------------
g2ecs2_asset_missing_mask	dc	0
	even
g2ecs2_assetfailmenu	dc.b	1
	dc.b	'EHB FILES MISSING - ESC TO WB ',0
	even

; Validate the core ECS resources after the profile file list has loaded.
; The mask directly feeds the visible missing-EHB warning; no file is written.
g2ecs2_asset_check
	movem.l	d0-d7/a0-a6,-(a7)
	clr	g2ecs2_asset_missing_mask
	tst	aga
	bne	.done		;AGA and P96 remain byte-for-byte behavioural peers

	move.l	magic,d0
	beq.s	.magic_missing
	move.l	d0,a0
	cmp	#320,(a0)
	bne.s	.magic_missing
	cmp	#240,2(a0)
	blo.s	.magic_missing
	cmp	#6,4(a0)
	beq.s	.magic_ok
.magic_missing
	moveq	#1,d0
	or	d0,g2ecs2_asset_missing_mask
.magic_ok
	tst.l	magicpal
	bne.s	.magicpal_ok
	moveq	#2,d0
	or	d0,g2ecs2_asset_missing_mask
.magicpal_ok
	move.l	gloom,d0
	beq.s	.title_missing
	move.l	d0,a0
	cmp	#320,(a0)
	bne.s	.title_missing
	cmp	#240,2(a0)
	blo.s	.title_missing
	cmp	#6,4(a0)
	beq.s	.title_ok
.title_missing
	moveq	#4,d0
	or	d0,g2ecs2_asset_missing_mask
.title_ok
	tst.l	gloompal
	bne.s	.titlepal_ok
	moveq	#8,d0
	or	d0,g2ecs2_asset_missing_mask
.titlepal_ok
	cmp	#3,g2_game_profile
	beq.s	.fastbase_ok	;c87b33: only Gloom3 needs no title_base
	move.l	g2ecs_fast_title_base,d0
	beq.s	.fastbase_missing
	move.l	d0,a0
	cmp	#320,(a0)
	bne.s	.fastbase_missing
	cmp	#240,2(a0)
	bne.s	.fastbase_missing
	cmp	#6,4(a0)
	beq.s	.fastbase_ok
.fastbase_missing
	moveq	#64,d0
	or	d0,g2ecs2_asset_missing_mask
.fastbase_ok
	cmp	#3,g2_game_profile
	beq.s	.fastbasepal_ok	;c87b33: only Gloom3 has no separate base palette
	tst.l	g2ecs_fast_title_base_pal
	bne.s	.fastbasepal_ok
	move	#128,d0
	or	d0,g2ecs2_asset_missing_mask
.fastbasepal_ok
	tst.l	planar_palette
	bne.s	.palette_ok
	moveq	#16,d0
	or	d0,g2ecs2_asset_missing_mask
.palette_ok
	tst.l	planar_remap
	bne.s	.remap_ok
	moveq	#32,d0
	or	d0,g2ecs2_asset_missing_mask
.remap_ok

	; c87b80d: validation result is consumed by g2ecs2_asset_notice.
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Called only after g2v190ct_titlefont, so the normal one-item menu renderer is
; ready even when the title picture itself was missing and the screen is black.
g2ecs2_asset_notice
	tst	aga
	bne.w	.done
	tst	g2ecs2_asset_missing_mask
	beq.w	.done
	lea	g2ecs2_assetfailmenu,a0
	jsr	g2ecs2_asset_notice_wait_esc
.done
	rts
	;ECS5b_BLACKMAGIC_FALLBACK: ECS first loads pics_ehb/blackmagic; if absent,
	;it accepts pics/blackmagic only when its trimmed-IFF header is 320x240x6.

; -----------------------------------------------------------------------------
; ECS7: exact ECS static-font rendering and transparent brush support
; -----------------------------------------------------------------------------

	even
g2ecs7_direct_font_active	dc	0
g2ecs8_defer_font_palette	dc	0
g2ecs8_font_palette_pending	dc	0
g2ecs7_font_index_map		ds.b	64
	even
; Compact saved title background for the maximum 320x72 six-plane brush.
; Plane stride = 40*72 = 2880 bytes.
g2ecs7_brush_background		ds.b	17280
	even

; Save the current title pixels under the brush rectangle.
; in: a1 = destination origin in plane 0.
g2ecs7_save_brush_background
	movem.l	d0-d7/a0-a5,-(a7)
	move.l	gloombrush,d0
	beq.w	.done
	move.l	d0,a4
	moveq	#0,d6
	move	2(a4),d6
	beq.w	.done
	cmp	#72,d6
	bls.s	.height_ok
	moveq	#72,d6
.height_ok
	lea	g2ecs7_brush_background,a5
	move.l	a1,a3
	moveq	#0,d7
.plane_loop
	cmp	bitplanes,d7
	bge.s	.done
	move.l	a3,a0
	move	d6,d5
	subq	#1,d5
.row_loop
	move.l	a0,a2
	moveq	#9,d4		;40 bytes = ten longs
.copy_40
	move.l	(a2)+,(a5)+
	dbf	d4,.copy_40
	adda.l	linemod,a0
	dbf	d5,.row_loop
	; Keep fixed 2880-byte plane spacing even for shorter brushes.
	moveq	#72,d0
	sub	d6,d0
	beq.s	.next_plane
	mulu	#40,d0
	adda.l	d0,a5
.next_plane
	adda.l	bpmod,a3
	addq	#1,d7
	bra.s	.plane_loop
.done
	movem.l	(a7)+,d0-d7/a0-a5
	rts

; Prepare exact font colours 1..3 without changing visible picture pixels.
; in: a1 = current 64-word ECS/EHB picture palette.
g2ecs7_prepare_exact_font_overlay
	movem.l	d0-d7/a0-a6,-(a7)
	clr	g2ecs7_direct_font_active
	clr	g2ecs8_font_palette_pending
	clr	g2inter_yellow_text_active
	tst	aga
	bne.w	.done
	tst.l	a1
	beq.w	.done
	move.l	a1,a6

	; c87b14: editor Fast-EHB pictures never use indices 1..3/33..35 for
	; image pixels.  No full-screen pixel scan or remap is required.
	tst	g2ecs_fast_assets_enabled
	beq.s	.g2c87b14_legacy_font_prepare
	tst	g2ecs8_defer_font_palette
	beq.s	.g2c87b14_fast_font_now
	move	#-1,g2ecs8_font_palette_pending
	move	#-1,g2ecs7_direct_font_active
	bra.w	.done
.g2c87b14_fast_font_now
	jsr	initfontpal
	move	#-1,g2ecs7_direct_font_active
	bra.w	.done

.g2c87b14_legacy_font_prepare
	; The legacy direct renderer depends on the decoded 8x10 glyph cache.
	jsr	g2p96_menu_glyph_cache_ensure
	tst	d0
	beq.w	.done

	; Identity-map all visible indices first.
	lea	g2ecs7_font_index_map,a5
	moveq	#0,d0
	moveq	#63,d7
.map_identity
	move.b	d0,(a5)+
	addq	#1,d0
	dbf	d7,.map_identity

	; Find replacements for base indices 1..3 and their EHB partners 33..35.
	lea	g2ecs7_font_index_map,a5
	moveq	#1,d6
.base_loop
	cmp	#4,d6
	bge.s	.map_ready

	; Base colour replacement.
	move	d6,d0
	jsr	g2ecs7_find_font_safe_replacement
	move.b	d4,0(a5,d6.w)

	; Half-bright partner replacement.
	move	d6,d0
	add	#32,d0
	jsr	g2ecs7_find_font_safe_replacement
	move	d6,d1
	add	#32,d1
	move.b	d4,0(a5,d1.w)

	addq	#1,d6
	bra.s	.base_loop

.map_ready
	; Remap the complete visible bitmap before initfontpal changes registers 1..3.
	move.l	showbitmap,a6
	moveq	#0,d6		;y
.row_loop
	cmp	#240,d6
	bge.w	.install_font_palette
	moveq	#0,d7		;x
.pixel_loop
	cmp	#320,d7
	bge.s	.next_row

	move	d7,d0
	lsr	#3,d0
	move.l	a6,a0
	adda.w	d0,a0
	move	d7,d3
	and	#7,d3
	moveq	#7,d0
	sub	d3,d0
	move	d0,d3

	; Read current six-plane index.
	moveq	#0,d0
	moveq	#0,d2
	move.l	a0,a2
.read_plane
	cmp	bitplanes,d2
	bge.s	.have_index
	btst	d3,(a2)
	beq.s	.read_next
	bset	d2,d0
.read_next
	adda.l	bpmod,a2
	addq	#1,d2
	bra.s	.read_plane

.have_index
	moveq	#0,d1
	move.b	0(a5,d0.w),d1
	cmp	d0,d1
	beq.s	.pixel_done

	; Write replacement index.
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
	addq	#1,d7
	bra.w	.pixel_loop

.next_row
	adda.l	linemod,a6
	addq	#1,d6
	bra.w	.row_loop

.install_font_palette
	; Now no picture pixel depends on base colours 1..3 or EHB 33..35.
	; Intermissions may install the palette immediately.  Title/ABOUT menu
	; construction defers it until db has selected the fully prepared bitmap.
	tst	g2ecs8_defer_font_palette
	beq.s	.g2ecs8_install_font_now
	move	#-1,g2ecs8_font_palette_pending
	move	#-1,g2ecs7_direct_font_active
	bra.s	.done
.g2ecs8_install_font_now
	jsr	initfontpal
	move	#-1,g2ecs7_direct_font_active
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; in: d0.w = source visible index 1..63
;     a6 = 64-word source palette
; out: d4.w = nearest safe index whose base pair is not 1,2,3
g2ecs7_find_font_safe_replacement
	movem.l	d0-d3/d5-d7/a0-a2,-(a7)
	move	d0,d7
	add	d7,d7
	move	0(a6,d7.w),d7	;source RGB12
	move	#32767,d5
	moveq	#4,d4		;safe default
	moveq	#1,d3
.candidate_loop
	cmp	#64,d3
	bge.s	.done
	move	d3,d2
	and	#31,d2
	cmp	#1,d2
	beq.s	.next
	cmp	#2,d2
	beq.s	.next
	cmp	#3,d2
	beq.s	.next

	move	d3,d1
	add	d1,d1
	move	0(a6,d1.w),d1
	move	d7,d0
	jsr	g2ecs6_rgb12_distance
	cmp	d5,d2
	bge.s	.next
	move	d2,d5
	move	d3,d4
.next
	addq	#1,d3
	bra.s	.candidate_loop
.done
	movem.l	(a7)+,d0-d3/d5-d7/a0-a2
	rts

; Direct 8x10 glyph draw for ECS static screens.
; in: d2 = already resolved Bigfont glyph slot, d7 = X, d6 = Y
g2ecs7_draw_cached_glyph_exact
	movem.l	d0-d7/a0-a6,-(a7)
	cmp	#0,d2
	blt.w	.done
	cmp	#p96menu_glyph_count,d2
	bge.w	.done
	move.l	p96menu_glyph_cache_ptr,a2
	tst.l	a2
	beq.w	.done
	move	d2,d0
	mulu	#p96menu_glyph_bytes,d0
	adda.l	d0,a2
	moveq	#0,d3		;glyph y
.row_loop
	cmp	#p96menu_glyph_height,d3
	bge.w	.done
	moveq	#0,d2		;glyph x
.col_loop
	cmp	#p96menu_glyph_width,d2
	bge.s	.next_row
	moveq	#0,d5
	move.b	(a2)+,d5
	beq.s	.next_col
	cmp	#3,d5
	bls.s	.level_ok
	moveq	#3,d5
.level_ok
	move	d7,d0
	add	d2,d0
	cmp	#320,d0
	bge.s	.next_col
	tst	d0
	blt.s	.next_col
	move	d6,d1
	add	d3,d1
	cmp	#240,d1
	bge.s	.next_col
	tst	d1
	blt.s	.next_col

	move.l	showbitmap,a0
	move	d1,d4
	mulu	linemodw,d4
	adda.l	d4,a0
	move	d0,d4
	lsr	#3,d4
	adda.w	d4,a0
	and	#7,d0
	moveq	#7,d4
	sub	d0,d4

	moveq	#0,d1
.write_plane
	cmp	bitplanes,d1
	bge.s	.next_col
	btst	d1,d5
	beq.s	.clear_bit
	bset	d4,(a0)
	bra.s	.write_next
.clear_bit
	bclr	d4,(a0)
.write_next
	adda.l	bpmod,a0
	addq	#1,d1
	bra.s	.write_plane

.next_col
	addq	#1,d2
	bra.s	.col_loop
.next_row
	addq	#1,d3
	bra.w	.row_loop
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

