; 2.1 performance trial 2: compact two-pixel expansion and paired row copy.
; =============================================================================
; c87b69 - saved world RESOLUTION selector
;
; 0 = 1x1 PIXELS, 1 = 2x1 PIXELS, 2 = 1x2 PIXELS, 3 = 2x2 PIXELS.
; Only the 3D world uses the compact raster.  Expansion is completed before
; gun, muzzle flash, HUD, FPS, menus and the final AGA/ECS/P96 presentation.
; The same code accepts planar linear ownership and P96 linear ownership.
; =============================================================================

g2resolution_active              dc.w    0
g2resolution_saved_width         dc.w    320
g2resolution_saved_hite          dc.w    240
g2resolution_saved_chunkymodw    dc.w    320
g2resolution_saved_minx          dc.w    -160
g2resolution_saved_maxx          dc.w    160
g2resolution_saved_miny          dc.w    -120
g2resolution_saved_maxy          dc.w    120
g2resolution_saved_render_width  dc.w    320
g2resolution_saved_render_center dc.w    160
g2resolution_saved_render_last   dc.w    319
g2resolution_saved_render_stride dc.w    320
g2resolution_compact_width       dc.w    320
g2resolution_compact_hite        dc.w    240
g2resolution_saved_offset        dc.l    0
        even

g2quality_prepare_frame
        movem.l d0-d3,-(a7)
        clr.w   g2resolution_active
        move.w  g2_resolution,d0
        beq.w   .done
        cmp.w   #3,d0
        bhi.w   .done
        tst.w   twowins
        bne.w   .done
        tst.w   g2kalms_linear_active
        bne.s   .linear
        tst.w   p96gameplay_linear_active
        beq.w   .done
.linear
        move.w  width,d1
        ble.w   .done
        cmp.w   chunkymodw,d1
        bne.w   .done
        cmp.w   g2render_stride,d1
        bne.w   .done
        move.w  hite,d2
        ble.w   .done
        tst.l   offset
        bne.w   .done

        move.w  width,g2resolution_saved_width
        move.w  hite,g2resolution_saved_hite
        move.w  chunkymodw,g2resolution_saved_chunkymodw
        move.w  minx,g2resolution_saved_minx
        move.w  maxx,g2resolution_saved_maxx
        move.w  miny,g2resolution_saved_miny
        move.w  maxy,g2resolution_saved_maxy
        move.l  offset,g2resolution_saved_offset
        move.w  g2render_width,g2resolution_saved_render_width
        move.w  g2render_center_x,g2resolution_saved_render_center
        move.w  g2render_last_x,g2resolution_saved_render_last
        move.w  g2render_stride,g2resolution_saved_render_stride
        move.w  d0,g2resolution_active

        btst    #0,d0
        beq.s   .x_ready
        lsr.w   #1,d1
.x_ready
        btst    #1,d0
        beq.s   .y_ready
        lsr.w   #1,d2
.y_ready
        move.w  d1,g2resolution_compact_width
        move.w  d2,g2resolution_compact_hite
        move.w  d1,width
        move.w  d2,hite
        move.w  d1,chunkymodw
        move.w  d1,g2render_width
        move.w  d1,g2render_stride
        move.w  d1,d3
        lsr.w   #1,d3
        move.w  d3,g2render_center_x
        move.w  d1,d3
        subq.w  #1,d3
        move.w  d3,g2render_last_x
        move.w  d1,d3
        lsr.w   #1,d3
        move.w  d3,maxx
        neg.w   d3
        move.w  d3,minx
        move.w  d2,d3
        lsr.w   #1,d3
        move.w  d3,maxy
        neg.w   d3
        move.w  d3,miny
        clr.l   offset
.done
        movem.l (a7)+,d0-d3
        rts

g2quality_expand_restore
        move.w  g2resolution_active,d0
        beq.w   .done
        cmp.w   #1,d0
        beq.w   .expand_x
        cmp.w   #2,d0
        beq.w   .expand_y
        bra.w   .expand_xy

.expand_x
        movem.l d0-d2/d7/a0-a2,-(a7)
        move.l  chunky,a0
        moveq   #0,d0
        move.w  g2resolution_compact_width,d0
        mulu    g2resolution_compact_hite,d0
        move.l  a0,a1
        adda.l  d0,a0
        moveq   #0,d1
        move.w  g2resolution_saved_width,d1
        mulu    g2resolution_saved_hite,d1
        adda.l  d1,a1
        lea     g2resolution_dupbyte_table,a2
        move.w  d0,d7
        ; Two source pixels per loop; backwards preserves in-place overlap.
        ; Clear index once: MOVE.B below cannot change its upper bits.
        moveq   #0,d0
        lsr.w   #1,d7
        bcc.s   .x_pairs
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a1)
.x_pairs
        subq.w  #1,d7
        bmi.s   .x_finished
.x_loop
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a1)
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a1)
        dbf     d7,.x_loop
.x_finished
        movem.l (a7)+,d0-d2/d7/a0-a2
        bra.w   .restore

.expand_y
        movem.l d0-d2/d6-d7/a0-a4,-(a7)
        move.l  chunky,a0
        moveq   #0,d0
        move.w  g2resolution_compact_width,d0
        mulu    g2resolution_compact_hite,d0
        move.l  chunky,a1
        adda.l  d0,a0
        moveq   #0,d1
        move.w  g2resolution_saved_width,d1
        mulu    g2resolution_saved_hite,d1
        adda.l  d1,a1
        move.w  g2resolution_compact_hite,d7
        subq.w  #1,d7
.y_row
        move.w  g2resolution_saved_width,d6
        lsr.w   #2,d6
        subq.w  #1,d6
.y_copy_lower
        move.l  -(a0),-(a1)
        dbf     d6,.y_copy_lower
        move.l  a1,a3
        move.l  a1,a4
        suba.w  g2resolution_saved_width,a4
        move.w  g2resolution_saved_width,d6
        lsr.w   #2,d6
        subq.w  #1,d6
.y_copy_upper
        move.l  (a3)+,(a4)+
        dbf     d6,.y_copy_upper
        suba.w  g2resolution_saved_width,a1
        dbf     d7,.y_row
        movem.l (a7)+,d0-d2/d6-d7/a0-a4
        bra.w   .restore

.expand_xy
        movem.l d0-d3/d6-d7/a0-a5,-(a7)
        move.l  chunky,a0
        moveq   #0,d0
        move.w  g2resolution_compact_width,d0
        mulu    g2resolution_compact_hite,d0
        move.l  chunky,a1
        adda.l  d0,a0
        moveq   #0,d1
        move.w  g2resolution_saved_width,d1
        mulu    g2resolution_saved_hite,d1
        adda.l  d1,a1
        lea     g2resolution_dupbyte_table,a2
        move.w  g2resolution_compact_hite,d7
        subq.w  #1,d7
.xy_row
        move.l  a1,a4
        move.w  g2resolution_compact_width,d6
        ; Two source pixels per loop; backwards preserves in-place overlap.
        ; Clear index once: MOVE.B below cannot change its upper bits.
        moveq   #0,d0
        lsr.w   #1,d6
        bcc.s   .xy_pairs
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a4)
.xy_pairs
        subq.w  #1,d6
        bmi.s   .xy_finished
.xy_loop
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a4)
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a4)
        dbf     d6,.xy_loop
.xy_finished
        move.l  a4,a1
        move.l  a4,a3
        move.l  a4,a5
        suba.w  g2resolution_saved_width,a5
        move.w  g2resolution_saved_width,d6
        lsr.w   #2,d6
        ; Two longwords per loop, with one-longword tail for e.g. 428px.
        lsr.w   #1,d6
        bcc.s   .xy_copy_pairs
        move.l  (a3)+,(a5)+
.xy_copy_pairs
        subq.w  #1,d6
        bmi.s   .xy_copy_finished
.xy_copy_upper
        move.l  (a3)+,(a5)+
        move.l  (a3)+,(a5)+
        dbf     d6,.xy_copy_upper
.xy_copy_finished
        suba.w  g2resolution_saved_width,a1
        dbf     d7,.xy_row
        movem.l (a7)+,d0-d3/d6-d7/a0-a5

.restore
        move.w  g2resolution_saved_width,width
        move.w  g2resolution_saved_hite,hite
        move.w  g2resolution_saved_chunkymodw,chunkymodw
        move.w  g2resolution_saved_minx,minx
        move.w  g2resolution_saved_maxx,maxx
        move.w  g2resolution_saved_miny,miny
        move.w  g2resolution_saved_maxy,maxy
        move.l  g2resolution_saved_offset,offset
        move.w  g2resolution_saved_render_width,g2render_width
        move.w  g2resolution_saved_render_center,g2render_center_x
        move.w  g2resolution_saved_render_last,g2render_last_x
        move.w  g2resolution_saved_render_stride,g2render_stride
        clr.w   g2resolution_active
.done
        rts

; =============================================================================
; TWO PLAYER: the same four resolution modes are applied independently to each
; 320x120, 320x128 or native 428x120 half before its HUD is drawn.
; =============================================================================

g2twop_quality_mode dc.w 0
        even

g2twop_quality_prepare_half
        movem.l d0-d3,-(a7)
        clr.w   g2twop_quality_mode
        move.w  g2_resolution,d0
        beq.w   .done
        cmp.w   #3,d0
        bhi.w   .done
        tst.w   twowins
        beq.w   .done
        move.w  g2twop_view_width,d2
        cmp.w   g2twop_saved_width,d2
        bne.w   .done
        cmp.w   width,d2
        bne.w   .done
        move.w  g2twop_half_height,d1
        cmp.w   hite,d1
        bne.w   .done
        cmp.w   chunkymodw,d2
        bne.w   .done
        cmp.w   g2render_stride,d2
        bne.w   .done
        tst.w   g2kalms_linear_active
        beq.w   .done
        jsr     g2twop_quality_begin_wide_linear_c87b79t
        move.w  g2twop_view_width,d2
        move.w  d1,d3
        btst    #0,d0
        beq.s   .x_ready
        lsr.w   #1,d2
.x_ready
        btst    #1,d0
        beq.s   .y_ready
        lsr.w   #1,d3
.y_ready
        move.w  d2,width
        move.w  d3,hite
        move.w  d2,chunkymodw
        move.w  d2,g2render_width
        move.w  d2,g2render_stride
        move.w  d2,d1
        lsr.w   #1,d1
        move.w  d1,g2render_center_x
        move.w  d2,d1
        subq.w  #1,d1
        move.w  d1,g2render_last_x
        move.w  d2,d1
        lsr.w   #1,d1
        move.w  d1,maxx
        neg.w   d1
        move.w  d1,minx
        move.w  d3,d1
        lsr.w   #1,d1
        move.w  d1,maxy
        neg.w   d1
        move.w  d1,miny
        clr.l   offset
        clr.w   g2twop_crop_mode
.done
        movem.l (a7)+,d0-d3
        rts

g2twop_quality_expand_half
        move.w  g2twop_quality_mode,d0
        beq.w   .done
        cmp.w   #1,d0
        beq.w   .expand_x
        cmp.w   #2,d0
        beq.w   .expand_y
        bra.w   .expand_xy

.expand_x
        movem.l d0-d3/d7/a0-a2,-(a7)
        move.l  chunky,a0
        move.l  a0,a1
        moveq   #0,d0
        move.w  g2twop_view_width,d3
        move.w  d3,d0
        lsr.w   #1,d0
        mulu    g2twop_half_height,d0
        adda.l  d0,a0
        moveq   #0,d1
        move.w  d3,d1
        mulu    g2twop_half_height,d1
        adda.l  d1,a1
        lea     g2resolution_dupbyte_table,a2
        move.w  d0,d7
        ; Two source pixels per loop; backwards preserves in-place overlap.
        ; Clear index once: MOVE.B below cannot change its upper bits.
        moveq   #0,d0
        lsr.w   #1,d7
        bcc.s   .tx_pairs
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a1)
.tx_pairs
        subq.w  #1,d7
        bmi.s   .tx_finished
.tx_loop
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a1)
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a1)
        dbf     d7,.tx_loop
.tx_finished
        movem.l (a7)+,d0-d3/d7/a0-a2
        bra.w   .restore

.expand_y
        movem.l d0-d3/d6-d7/a0-a4,-(a7)
        move.w  g2twop_half_height,d2
        lsr.w   #1,d2
        move.w  g2twop_view_width,d3
        move.l  chunky,a0
        move.l  a0,a1
        moveq   #0,d0
        move.w  d3,d0
        mulu    d2,d0
        adda.l  d0,a0
        moveq   #0,d1
        move.w  d3,d1
        mulu    g2twop_half_height,d1
        adda.l  d1,a1
        move.w  d2,d7
        subq.w  #1,d7
.ty_row
        move.w  d3,d6
        lsr.w   #2,d6
        subq.w  #1,d6
.ty_copy_lower
        move.l  -(a0),-(a1)
        dbf     d6,.ty_copy_lower
        move.l  a1,a3
        move.l  a1,a4
        suba.w  d3,a4
        move.w  d3,d6
        lsr.w   #2,d6
        subq.w  #1,d6
.ty_copy_upper
        move.l  (a3)+,(a4)+
        dbf     d6,.ty_copy_upper
        suba.w  d3,a1
        dbf     d7,.ty_row
        movem.l (a7)+,d0-d3/d6-d7/a0-a4
        bra.w   .restore

.expand_xy
        movem.l d0-d3/d6-d7/a0-a5,-(a7)
        move.w  g2twop_half_height,d2
        lsr.w   #1,d2
        move.w  g2twop_view_width,d3
        move.l  chunky,a0
        move.l  a0,a1
        moveq   #0,d0
        move.w  d3,d0
        lsr.w   #1,d0
        mulu    d2,d0
        adda.l  d0,a0
        moveq   #0,d1
        move.w  d3,d1
        mulu    g2twop_half_height,d1
        adda.l  d1,a1
        lea     g2resolution_dupbyte_table,a2
        move.w  d2,d7
        subq.w  #1,d7
.txy_row
        move.l  a1,a4
        move.w  d3,d6
        lsr.w   #1,d6
        ; Two source pixels per loop; backwards preserves in-place overlap.
        ; Clear index once: MOVE.B below cannot change its upper bits.
        moveq   #0,d0
        lsr.w   #1,d6
        bcc.s   .txy_pairs
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a4)
.txy_pairs
        subq.w  #1,d6
        bmi.s   .txy_finished
.txy_loop
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a4)
        move.b  -(a0),d0
        move.w  0(a2,d0.w*2),-(a4)
        dbf     d6,.txy_loop
.txy_finished
        move.l  a4,a1
        move.l  a4,a3
        move.l  a4,a5
        suba.w  d3,a5
        move.w  d3,d6
        lsr.w   #2,d6
        ; Two longwords per loop, with one-longword tail for e.g. 428px.
        lsr.w   #1,d6
        bcc.s   .txy_copy_pairs
        move.l  (a3)+,(a5)+
.txy_copy_pairs
        subq.w  #1,d6
        bmi.s   .txy_copy_finished
.txy_copy_upper
        move.l  (a3)+,(a5)+
        move.l  (a3)+,(a5)+
        dbf     d6,.txy_copy_upper
.txy_copy_finished
        suba.w  d3,a1
        dbf     d7,.txy_row
        movem.l (a7)+,d0-d3/d6-d7/a0-a5

.restore
        jsr     g2twop_quality_restore_half
.done
        rts

g2twop_quality_abort_half
        tst.w   g2twop_quality_mode
        beq.s   .done
        jsr     g2twop_quality_restore_half
.done
        rts

g2twop_quality_restore_half
        move.w  g2twop_view_width,d1
        move.w  d1,width
        move.w  g2twop_half_height,d0
        move.w  d0,hite
        move.w  d1,chunkymodw
        move.w  d1,g2render_width
        move.w  d1,g2render_stride
        move.w  d1,d2
        lsr.w   #1,d2
        move.w  d2,g2render_center_x
        move.w  d2,maxx
        neg.w   d2
        move.w  d2,minx
        move.w  d1,d2
        subq.w  #1,d2
        move.w  d2,g2render_last_x
        lsr.w   #1,d0
        move.w  d0,maxy
        neg.w   d0
        move.w  d0,miny
        clr.l   offset
        move.w  #-1,g2twop_crop_mode
        jsr     g2twop_quality_end_wide_linear_c87b79t
        rts

        even
g2resolution_dupbyte_table
        dc.w $0000,$0101,$0202,$0303,$0404,$0505,$0606,$0707
        dc.w $0808,$0909,$0A0A,$0B0B,$0C0C,$0D0D,$0E0E,$0F0F
        dc.w $1010,$1111,$1212,$1313,$1414,$1515,$1616,$1717
        dc.w $1818,$1919,$1A1A,$1B1B,$1C1C,$1D1D,$1E1E,$1F1F
        dc.w $2020,$2121,$2222,$2323,$2424,$2525,$2626,$2727
        dc.w $2828,$2929,$2A2A,$2B2B,$2C2C,$2D2D,$2E2E,$2F2F
        dc.w $3030,$3131,$3232,$3333,$3434,$3535,$3636,$3737
        dc.w $3838,$3939,$3A3A,$3B3B,$3C3C,$3D3D,$3E3E,$3F3F
        dc.w $4040,$4141,$4242,$4343,$4444,$4545,$4646,$4747
        dc.w $4848,$4949,$4A4A,$4B4B,$4C4C,$4D4D,$4E4E,$4F4F
        dc.w $5050,$5151,$5252,$5353,$5454,$5555,$5656,$5757
        dc.w $5858,$5959,$5A5A,$5B5B,$5C5C,$5D5D,$5E5E,$5F5F
        dc.w $6060,$6161,$6262,$6363,$6464,$6565,$6666,$6767
        dc.w $6868,$6969,$6A6A,$6B6B,$6C6C,$6D6D,$6E6E,$6F6F
        dc.w $7070,$7171,$7272,$7373,$7474,$7575,$7676,$7777
        dc.w $7878,$7979,$7A7A,$7B7B,$7C7C,$7D7D,$7E7E,$7F7F
        dc.w $8080,$8181,$8282,$8383,$8484,$8585,$8686,$8787
        dc.w $8888,$8989,$8A8A,$8B8B,$8C8C,$8D8D,$8E8E,$8F8F
        dc.w $9090,$9191,$9292,$9393,$9494,$9595,$9696,$9797
        dc.w $9898,$9999,$9A9A,$9B9B,$9C9C,$9D9D,$9E9E,$9F9F
        dc.w $A0A0,$A1A1,$A2A2,$A3A3,$A4A4,$A5A5,$A6A6,$A7A7
        dc.w $A8A8,$A9A9,$AAAA,$ABAB,$ACAC,$ADAD,$AEAE,$AFAF
        dc.w $B0B0,$B1B1,$B2B2,$B3B3,$B4B4,$B5B5,$B6B6,$B7B7
        dc.w $B8B8,$B9B9,$BABA,$BBBB,$BCBC,$BDBD,$BEBE,$BFBF
        dc.w $C0C0,$C1C1,$C2C2,$C3C3,$C4C4,$C5C5,$C6C6,$C7C7
        dc.w $C8C8,$C9C9,$CACA,$CBCB,$CCCC,$CDCD,$CECE,$CFCF
        dc.w $D0D0,$D1D1,$D2D2,$D3D3,$D4D4,$D5D5,$D6D6,$D7D7
        dc.w $D8D8,$D9D9,$DADA,$DBDB,$DCDC,$DDDD,$DEDE,$DFDF
        dc.w $E0E0,$E1E1,$E2E2,$E3E3,$E4E4,$E5E5,$E6E6,$E7E7
        dc.w $E8E8,$E9E9,$EAEA,$EBEB,$ECEC,$EDED,$EEEE,$EFEF
        dc.w $F0F0,$F1F1,$F2F2,$F3F3,$F4F4,$F5F5,$F6F6,$F7F7
        dc.w $F8F8,$F9F9,$FAFA,$FBFB,$FCFC,$FDFD,$FEFE,$FFFF
        even

; c87b69f: late placement keeps the established GenAm PC-relative layout stable.
	even
g2resolution_menu_changed	dc.w	0	;pending live P96 WIDE re-arm
	even
g2resolution_apply_after_menu
	; c87b70c: P96 WIDE and native 5:4 keep the persistent direct-linear
	; gameplay owner open under the ESC menu. Re-arm it when RESOLUTION changed,
	; so predrawall immediately rebuilds the active 428x240/854x480 WIDE or
	; 320x256/640x512 5:4 geometry instead of retaining the old compact raster
	; until the next title-screen/gameplay lifecycle.
	tst	g2resolution_menu_changed
	beq.w	.done
	clr	g2resolution_menu_changed
	cmp	#2,g2display_mode
	bne.w	.done
	tst	g2p96_wide_mode
	bne.s	.geometry_needs_rearm
	tst	g2p96_oneone_mode
	beq.w	.done
.geometry_needs_rearm
	tst	p96gameplay_persist_active
	beq.w	.done
	jsr	g2p96_gameplay_restore_c2p_layout
	move	#-1,p96gameplay_linear_ready
.done	rts

