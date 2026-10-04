; v2.3 c87b80x-diag2: opt-in P96 measurement, no scheduler changes.
; ReadEClock is interrupt-safe (V36). Each metric has its own scratch clock.
; No DOS/device I/O in hooks. All hooks preserve registers and CCR.
; Finish runs after finitvbint on normal exit; early exits precede initvbint.
g2diag_token
 movem.l d1-d7/a0-a6,-(a7)
 moveq #0,d0
 cmp #7,d6
 bne .single
 move.l a2,a3
 lea g2diag_token_diag,a4
 jsr g2tok_equal
 tst d0
 beq .done
 move.w #-1,g2diag_requested
 bra .done
.single
 cmp #9,d6
 bne .no
 move.l a2,a3
 lea g2diag_token_single,a4
 jsr g2tok_equal
 tst d0
 beq .done
 move.w #-1,g2diag_requested
 move.w #-1,g2diag_single
 bra .done
.no
 moveq #0,d0
.done
 movem.l (a7)+,d1-d7/a0-a6
 rts
g2diag_token_diag dc.b 'P96DIAG'
g2diag_token_single dc.b 'P96SINGLE'
 even
g2diag_init
 movem.l d0-d7/a0-a6,-(a7)
 cmp #2,g2display_mode
 beq .p96
 clr g2diag_single
 bra .done
.p96
 tst g2diag_requested
 beq .done
 move.w #-1,g2diag_started
 move.l 4.w,a6
 move.l 276(a6),a0
 moveq #0,d0
 move.b 9(a0),d0
 ext.w d0
 ext.l d0
 move.l d0,g2diag_priority
 jsr -666(a6)
 move.l d0,g2diag_port
 beq .done
 move.l d0,a0
 moveq #40,d0
 jsr -654(a6)
 move.l d0,g2diag_io
 beq .done
 move.l d0,a1
 lea g2diag_timername,a0
 moveq #1,d0
 moveq #0,d1
 jsr -444(a6)
 tst.l d0
 bne .done
 move.w #-1,g2diag_timeropen
 move.l g2diag_io,a0
 move.l 20(a0),a6
 cmp.w #36,20(a6)
 blo .done
 move.l a6,g2diag_timerbase
 lea g2diag_epoch,a0
 jsr -60(a6)
 move.l d0,g2diag_frequency
 move.w #-1,g2diag_active
.done
 movem.l (a7)+,d0-d7/a0-a6
 rts
g2diag_render_begin
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l 4.w,a6
 moveq #0,d0
 move.b 294(a6),d0
 ext.w d0
 ext.l d0
 move.l d0,g2diag_idnest
 moveq #0,d0
 move.b 295(a6),d0
 ext.w d0
 ext.l d0
 move.l d0,g2diag_tdnest
 tst.b 295(a6)
 bmi .notforbid
 addq.l #1,g2diag_forbidden_frames
.notforbid
 moveq #0,d0
 move.w os,d0
 move.l d0,g2diag_os
 moveq #0,d0
 move.w p96gameplay_dbuf_active,d0
 move.l d0,g2diag_dbactive
 moveq #0,d0
 move.w g2rc4_low_bandwidth_v21,d0
 move.l d0,g2diag_lowbw
 move.l g2diag_timerbase,a6
 lea g2diag_render_clock,a0
 jsr -60(a6)
 move.l g2diag_render_clock+4,d0
 move.l d0,g2diag_render_start
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_render_end
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_render_clock,a0
 jsr -60(a6)
 move.l g2diag_render_clock+4,d0
 sub.l g2diag_render_start,d0
 addq.l #1,g2diag_render_count
 add.l d0,g2diag_render_sumlo
 bcc .nocarry
 addq.l #1,g2diag_render_sumhi
.nocarry
 cmp.l g2diag_render_max,d0
 bls .done
 move.l d0,g2diag_render_max
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_copy_begin
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_copy_clock,a0
 jsr -60(a6)
 move.l g2diag_copy_clock+4,d0
 move.l d0,g2diag_copy_start
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_copy_end
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_copy_clock,a0
 jsr -60(a6)
 move.l g2diag_copy_clock+4,d0
 sub.l g2diag_copy_start,d0
 addq.l #1,g2diag_copy_count
 add.l d0,g2diag_copy_sumlo
 bcc .nocarry
 addq.l #1,g2diag_copy_sumhi
.nocarry
 cmp.l g2diag_copy_max,d0
 bls .done
 move.l d0,g2diag_copy_max
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_flip_begin
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_flip_clock,a0
 jsr -60(a6)
 move.l g2diag_flip_clock+4,d0
 move.l d0,g2diag_flip_start
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_flip_end
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_flip_clock,a0
 jsr -60(a6)
 move.l g2diag_flip_clock+4,d0
 sub.l g2diag_flip_start,d0
 addq.l #1,g2diag_flip_count
 add.l d0,g2diag_flip_sumlo
 bcc .nocarry
 addq.l #1,g2diag_flip_sumhi
.nocarry
 cmp.l g2diag_flip_max,d0
 bls .done
 move.l d0,g2diag_flip_max
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_wait_begin
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_wait_clock,a0
 jsr -60(a6)
 move.l g2diag_wait_clock+4,d0
 move.l d0,g2diag_wait_start
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_wait_end
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_wait_clock,a0
 jsr -60(a6)
 move.l g2diag_wait_clock+4,d0
 sub.l g2diag_wait_start,d0
 addq.l #1,g2diag_wait_count
 add.l d0,g2diag_wait_sumlo
 bcc .nocarry
 addq.l #1,g2diag_wait_sumhi
.nocarry
 cmp.l g2diag_wait_max,d0
 bls .done
 move.l d0,g2diag_wait_max
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_vblank_begin
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_vblank_clock,a0
 jsr -60(a6)
 move.l g2diag_vblank_clock+4,d0
 move.l d0,g2diag_vblank_start
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_vblank_end
 move.w ccr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_active
 beq .done
 move.l g2diag_timerbase,a6
 lea g2diag_vblank_clock,a0
 jsr -60(a6)
 move.l g2diag_vblank_clock+4,d0
 sub.l g2diag_vblank_start,d0
 addq.l #1,g2diag_vblank_count
 add.l d0,g2diag_vblank_sumlo
 bcc .nocarry
 addq.l #1,g2diag_vblank_sumhi
.nocarry
 cmp.l g2diag_vblank_max,d0
 bls .done
 move.l d0,g2diag_vblank_max
.done
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 rts
g2diag_open_count
 move.w ccr,-(a7)
 tst g2diag_started
 beq .done
 addq.l #1,g2diag_open_value
.done
 move.w (a7)+,ccr
 rts
g2diag_dbuf_fail_count
 move.w ccr,-(a7)
 tst g2diag_started
 beq .done
 addq.l #1,g2diag_dbuf_fail_value
.done
 move.w (a7)+,ccr
 rts
g2diag_bitmap_fail_count
 move.w ccr,-(a7)
 tst g2diag_started
 beq .done
 addq.l #1,g2diag_bitmap_fail_value
.done
 move.w (a7)+,ccr
 rts
g2diag_timeout_count
 move.w ccr,-(a7)
 tst g2diag_started
 beq .done
 addq.l #1,g2diag_timeout_value
.done
 move.w (a7)+,ccr
 rts
g2diag_finish
 movem.l d0-d7/a0-a6,-(a7)
 tst g2diag_started
 beq .done
 clr g2diag_active
 clr g2diag_started
 move.l g2diag_timerbase,d0
 beq .noelapsed
 move.l d0,a6
 lea g2diag_endclock,a0
 jsr -60(a6)
 move.l g2diag_endclock+4,d0
 sub.l g2diag_epoch+4,d0
 move.l d0,g2diag_elapsed
.noelapsed
 move.l 4.w,a6
 tst g2diag_timeropen
 beq .noopen
 clr g2diag_timeropen
 move.l g2diag_io,a1
 jsr -450(a6)
.noopen
 clr.l g2diag_timerbase
 move.l g2diag_io,d0
 beq .noio
 move.l d0,a0
 jsr -660(a6)
 clr.l g2diag_io
.noio
 move.l g2diag_port,d0
 beq .noport
 move.l d0,a0
 jsr -672(a6)
 clr.l g2diag_port
.noport
 moveq #0,d0
 move.w g2diag_single,d0
 move.l d0,g2diag_single_value
 moveq #0,d0
 move.w p96target_width,d0
 move.l d0,g2diag_width
 move.w p96target_height,d0
 move.l d0,g2diag_height
 lea g2diag_fields,a2
 lea g2diag_report,a3
.field
 move.l (a2)+,d0
 beq .write
 move.l d0,a0
 move.l (a0),d2
.seek
 cmp.b #'$',(a3)+
 bne .seek
 moveq #7,d3
.hex
 rol.l #4,d2
 move.l d2,d0
 and.w #15,d0
 add.b #'0',d0
 cmp.b #'9',d0
 bls .digit
 addq.b #7,d0
.digit
 move.b d0,(a3)+
 dbf d3,.hex
 bra .field
.write
 move.l dosbase,d0
 beq .done
 move.l d0,a6
 lea g2diag_path_db,a0
 tst g2diag_single
 beq .path
 lea g2diag_path_single,a0
.path
 move.l a0,d1
 move.l #1006,d2
 jsr -30(a6)
 move.l d0,d4
 beq .done
 move.l d4,d1
 move.l #g2diag_report,d2
 move.l #g2diag_report_end-g2diag_report,d3
 jsr -48(a6)
 move.l d4,d1
 jsr -36(a6)
.done
 movem.l (a7)+,d0-d7/a0-a6
 rts
g2diag_timername dc.b 'timer.device',0
g2diag_path_db dc.b 'RAM:Gloom-P96-Diag-DB.log',0
g2diag_path_single dc.b 'RAM:Gloom-P96-Diag-Single.log',0
 even
g2diag_requested dc.w 0
g2diag_single dc.w 0
g2diag_started dc.w 0
g2diag_active dc.w 0
g2diag_timeropen dc.w 0
 even
g2diag_port dc.l 0
g2diag_io dc.l 0
g2diag_timerbase dc.l 0
g2diag_epoch dc.l 0,0
g2diag_endclock dc.l 0,0
g2diag_render_clock dc.l 0,0
g2diag_render_start dc.l 0
g2diag_copy_clock dc.l 0,0
g2diag_copy_start dc.l 0
g2diag_flip_clock dc.l 0,0
g2diag_flip_start dc.l 0
g2diag_wait_clock dc.l 0,0
g2diag_wait_start dc.l 0
g2diag_vblank_clock dc.l 0,0
g2diag_vblank_start dc.l 0
g2diag_frequency dc.l 0
g2diag_elapsed dc.l 0
g2diag_priority dc.l 0
g2diag_single_value dc.l 0
g2diag_width dc.l 0
g2diag_height dc.l 0
g2diag_os dc.l 0
g2diag_dbactive dc.l 0
g2diag_lowbw dc.l 0
g2diag_idnest dc.l 0
g2diag_tdnest dc.l 0
g2diag_forbidden_frames dc.l 0
g2diag_open_value dc.l 0
g2diag_dbuf_fail_value dc.l 0
g2diag_bitmap_fail_value dc.l 0
g2diag_timeout_value dc.l 0
g2diag_render_count dc.l 0
g2diag_render_sumhi dc.l 0
g2diag_render_sumlo dc.l 0
g2diag_render_max dc.l 0
g2diag_copy_count dc.l 0
g2diag_copy_sumhi dc.l 0
g2diag_copy_sumlo dc.l 0
g2diag_copy_max dc.l 0
g2diag_flip_count dc.l 0
g2diag_flip_sumhi dc.l 0
g2diag_flip_sumlo dc.l 0
g2diag_flip_max dc.l 0
g2diag_wait_count dc.l 0
g2diag_wait_sumhi dc.l 0
g2diag_wait_sumlo dc.l 0
g2diag_wait_max dc.l 0
g2diag_vblank_count dc.l 0
g2diag_vblank_sumhi dc.l 0
g2diag_vblank_sumlo dc.l 0
g2diag_vblank_max dc.l 0
g2diag_fields
 dc.l g2diag_frequency
 dc.l g2diag_elapsed
 dc.l g2diag_priority
 dc.l g2diag_single_value
 dc.l g2diag_width
 dc.l g2diag_height
 dc.l g2diag_os
 dc.l g2diag_dbactive
 dc.l g2diag_lowbw
 dc.l g2diag_idnest
 dc.l g2diag_tdnest
 dc.l g2diag_forbidden_frames
 dc.l g2diag_open_value
 dc.l g2diag_dbuf_fail_value
 dc.l g2diag_bitmap_fail_value
 dc.l g2diag_timeout_value
 dc.l g2diag_render_count
 dc.l g2diag_render_sumhi
 dc.l g2diag_render_sumlo
 dc.l g2diag_render_max
 dc.l g2diag_copy_count
 dc.l g2diag_copy_sumhi
 dc.l g2diag_copy_sumlo
 dc.l g2diag_copy_max
 dc.l g2diag_flip_count
 dc.l g2diag_flip_sumhi
 dc.l g2diag_flip_sumlo
 dc.l g2diag_flip_max
 dc.l g2diag_wait_count
 dc.l g2diag_wait_sumhi
 dc.l g2diag_wait_sumlo
 dc.l g2diag_wait_max
 dc.l g2diag_vblank_count
 dc.l g2diag_vblank_sumhi
 dc.l g2diag_vblank_sumlo
 dc.l g2diag_vblank_max
 dc.l 0
g2diag_report
 dc.b 'Gloom Reforged v2.3 c87b80x-diag2',10
 dc.b 'Hex values; EClock ticks. Timings inclusive, do not add categories.',10
 dc.b 'frequency=$00000000',10
 dc.b 'elapsed=$00000000',10
 dc.b 'priority=$00000000',10
 dc.b 'single_value=$00000000',10
 dc.b 'width=$00000000',10
 dc.b 'height=$00000000',10
 dc.b 'os=$00000000',10
 dc.b 'dbactive=$00000000',10
 dc.b 'lowbw=$00000000',10
 dc.b 'idnest=$00000000',10
 dc.b 'tdnest=$00000000',10
 dc.b 'forbidden_frames=$00000000',10
 dc.b 'open_value=$00000000',10
 dc.b 'dbuf_fail_value=$00000000',10
 dc.b 'bitmap_fail_value=$00000000',10
 dc.b 'timeout_value=$00000000',10
 dc.b 'render_count=$00000000',10
 dc.b 'render_sumhi=$00000000',10
 dc.b 'render_sumlo=$00000000',10
 dc.b 'render_max=$00000000',10
 dc.b 'copy_count=$00000000',10
 dc.b 'copy_sumhi=$00000000',10
 dc.b 'copy_sumlo=$00000000',10
 dc.b 'copy_max=$00000000',10
 dc.b 'flip_count=$00000000',10
 dc.b 'flip_sumhi=$00000000',10
 dc.b 'flip_sumlo=$00000000',10
 dc.b 'flip_max=$00000000',10
 dc.b 'wait_count=$00000000',10
 dc.b 'wait_sumhi=$00000000',10
 dc.b 'wait_sumlo=$00000000',10
 dc.b 'wait_max=$00000000',10
 dc.b 'vblank_count=$00000000',10
 dc.b 'vblank_sumhi=$00000000',10
 dc.b 'vblank_sumlo=$00000000',10
 dc.b 'vblank_max=$00000000',10
g2diag_report_end
 even
