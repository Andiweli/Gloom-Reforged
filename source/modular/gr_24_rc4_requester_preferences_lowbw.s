; =============================================================================
; c87b80m / Gloom Reforged v2.0 RC4 shared P96 requester
; Ported directly from the hardware-confirmed GloomBench TEST5 source.
; Saved P96 ModeID + left-Shift override + low-bandwidth P96 publishing.
;
; Config compatibility:
;   The original 34-byte gloom.cfg v4 payload remains byte-for-byte at the
;   beginning of the file.  This test appends a 12-byte "P961" extension:
;       +0  long  signature 'P961'
;       +4  long  saved P96 ModeID (zero when Save Screenmode is unchecked)
;       +8  word  save flag (0/-1)
;       +10 word  low-bandwidth flag (0/-1)
;   The original 34-byte v4 prefix remains compatible. RC4 writes and
;   preserves the 12-byte extension on every normal configuration save.
; =============================================================================

G2RC4_CFG_BASE_LEN_V21      equ g2cfg_len
G2RC4_CFG_EXT_LEN_V21       equ 12
G2RC4_CFG_TOTAL_LEN_V21     equ G2RC4_CFG_BASE_LEN_V21+G2RC4_CFG_EXT_LEN_V21
G2RC4_CFG_EXT_SIG_V21       equ 'P961'
G2RC4_INPUT_IOREQ_LEN_V21   equ 48
G2RC4_IEQUALIFIER_LSHIFT    equ $0001
G2RC4_INPUT_LVO_PEEKQUALIFIER equ -42
G2RC4_REQ_SAVE_HIT_V21      equ -2
G2RC4_REQ_LOWBW_HIT_V21     equ -3
G2RC4_REQ_OK_HIT_V21        equ -4
G2RC4_REQ_SAVE_BASE_Y_V21   equ 170
G2RC4_REQ_SHIFT_BASE_Y_V21  equ 180
G2RC4_REQ_LOWBW_BASE_Y_V21  equ 192
G2RC4_REQ_ACTION_Y_V21      equ 200
G2RC4_REQ_SAVE_HIT_TOP_V21  equ 161
G2RC4_REQ_SAVE_HIT_END_V21  equ 183
G2RC4_REQ_LOWBW_HIT_TOP_V21 equ 184
G2RC4_REQ_LOWBW_HIT_END_V21 equ 200
G2RC4_REQ_ACTION_W_V21      equ 80
G2RC4_REQ_OK_X_V21          equ 16
G2RC4_REQ_AGA_X_V21         equ 110
G2RC4_REQ_CANCEL_X_V21      equ 204

        even
g2rc4_save_screenmode_v21       dc.w 0
g2rc4_low_bandwidth_v21         dc.w 0
g2rc4_lshift_override_v21       dc.w 0
g2rc4_saved_mode_used_v21       dc.w 0
g2rc4_requester_selected_v21    dc.w 0
g2rc4_req_selected_row_v21      dc.w -1
g2rc4_lowbw_phase_v21           dc.w 0
g2rc4_saved_modeid_v21          dc.l 0
        even

g2rc4_cfg_buffer_v21            ds.b 52 ; v4 + P961 + BAY1
        even
g2rc4_input_port_v21            dc.l 0
g2rc4_input_ioreq_ptr_v21       dc.l 0
        even
g2rc4_input_name_v21            dc.b 'input.device',0
        even

; Load only the appended P96 preferences before display selection.
; The normal gameplay configuration is loaded later through g2cfg_load.
g2rc4_p96prefs_load_v21
        movem.l d0-d7/a0-a6,-(a7)
        clr     g2rc4_save_screenmode_v21
        clr     g2rc4_low_bandwidth_v21
        clr     g2rc4_saved_mode_used_v21
        clr.l   g2rc4_saved_modeid_v21
        move.l  dosbase,d0
        beq.w   .done
        move.l  d0,a6
        lea     g2cfg_name,a0
        move.l  a0,d1
        move.l  #1005,d2
        jsr     -30(a6)                 ; Open MODE_OLDFILE
        move.l  d0,d7
        beq.w   .done
        move.l  d7,d1
        lea     g2rc4_cfg_buffer_v21(pc),a0
        move.l  a0,d2
        move.l  #G2RC4_CFG_TOTAL_LEN_V21,d3
        jsr     -42(a6)                 ; Read
        move.l  d0,d6
        move.l  d7,d1
        jsr     -36(a6)                 ; Close
        cmp.l   #G2RC4_CFG_TOTAL_LEN_V21,d6
        bcs.w   .done
        lea     g2rc4_cfg_buffer_v21(pc),a0
        cmp.l   #'GLMC',(a0)+
        bne.w   .done
        cmp.b   #'F',(a0)+
        bne.w   .done
        cmp.b   #'G',(a0)+
        bne.w   .done
        move    (a0),d0
        cmp     #1,d0
        blt.w   .done
        cmp     #4,d0
        bgt.w   .done
        lea     g2rc4_cfg_buffer_v21+G2RC4_CFG_BASE_LEN_V21(pc),a0
        cmp.l   #G2RC4_CFG_EXT_SIG_V21,(a0)+
        bne.w   .done
        move.l  (a0)+,g2rc4_saved_modeid_v21
        move    (a0)+,d0
        beq.w   .save_off
        move    #-1,g2rc4_save_screenmode_v21
        bra.w   .save_done
.save_off
        clr     g2rc4_save_screenmode_v21
.save_done
        move    (a0)+,d0
        beq.w   .low_off
        move    #-1,g2rc4_low_bandwidth_v21
        bra.w   .done
.low_off
        clr     g2rc4_low_bandwidth_v21
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Snapshot only the left Shift qualifier through input.device V36+.
; Failure to open the device simply leaves the override disabled.
g2rc4_lshift_probe_v21
        movem.l d0-d7/a0-a6,-(a7)
        clr     g2rc4_lshift_override_v21
        clr.l   g2rc4_input_port_v21
        clr.l   g2rc4_input_ioreq_ptr_v21
        moveq   #0,d7                   ; device-open flag
        move.l  4.w,a6
        cmp.w   #36,20(a6)              ; V36 supplies CreateIORequest/PeekQualifier
        bcs.w   .done
        jsr     -666(a6)                ; CreateMsgPort
        move.l  d0,g2rc4_input_port_v21
        beq.w   .done
        move.l  d0,a0
        moveq   #G2RC4_INPUT_IOREQ_LEN_V21,d0
        jsr     -654(a6)                ; CreateIORequest
        move.l  d0,g2rc4_input_ioreq_ptr_v21
        beq.w   .delete_port
        move.l  d0,a1
        lea     g2rc4_input_name_v21(pc),a0
        moveq   #0,d0                   ; unit 0
        moveq   #0,d1                   ; flags
        jsr     -444(a6)                ; OpenDevice
        tst.l   d0
        bne.w   .delete_ioreq
        moveq   #-1,d7
        move.l  g2rc4_input_ioreq_ptr_v21,a1
        move.l  20(a1),d0               ; io_Device / InputBase
        beq.w   .close
        move.l  d0,a6
        cmp.w   #36,20(a6)              ; Library.lib_Version
        bcs.w   .close
        jsr     G2RC4_INPUT_LVO_PEEKQUALIFIER(a6)
        and.w   #G2RC4_IEQUALIFIER_LSHIFT,d0
        beq.w   .close
        move    #-1,g2rc4_lshift_override_v21
.close
        tst     d7
        beq.w   .delete_ioreq
        move.l  4.w,a6
        move.l  g2rc4_input_ioreq_ptr_v21,a1
        jsr     -450(a6)                ; CloseDevice
.delete_ioreq
        move.l  g2rc4_input_ioreq_ptr_v21,d0
        beq.w   .delete_port
        move.l  d0,a0
        move.l  4.w,a6
        jsr     -660(a6)                ; DeleteIORequest
        clr.l   g2rc4_input_ioreq_ptr_v21
.delete_port
        move.l  g2rc4_input_port_v21,d0
        beq.w   .done
        move.l  d0,a0
        move.l  4.w,a6
        jsr     -672(a6)                ; DeleteMsgPort
        clr.l   g2rc4_input_port_v21
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Validate the saved ID through the exact same host-aware P96MODEID contract,
; while preserving the visible ToolType source/override state.
g2rc4_validate_saved_mode_v21
        movem.l d1-d7/a0-a6,-(a7)
        move    g2p96_modeid_override_valid,d4
        move    g2p96_modeid_override_used,d5
        move.l  g2p96_modeid_override_value,d6
        move    #-1,g2p96_modeid_override_valid
        clr     g2p96_modeid_override_used
        move.l  g2rc4_saved_modeid_v21,g2p96_modeid_override_value
        jsr     g2p96_modeid_override_validate_host_c87b78s
        move.l  d0,d7
        move    d4,g2p96_modeid_override_valid
        move    d5,g2p96_modeid_override_used
        move.l  d6,g2p96_modeid_override_value
        move.l  d7,d0
        movem.l (a7)+,d1-d7/a0-a6
        rts

; Full RC4 requester flow plus the optional saved-ModeID fast path.
g2rc4_p96_mode_requester_probe_v21
        movem.l d1-d7/a0-a6,-(a7)
        jsr     g2rc4_p96prefs_load_v21
        jsr     g2rc4_lshift_probe_v21
        clr     g2rc4_saved_mode_used_v21
        clr     g2rc4_requester_selected_v21
        clr     g2rc4_lowbw_phase_v21
        clr     g2p96_req_abort_startup
        clr.l   p96modeid
        clr     p96modeid_depth
        clr     p96modeid_state
        move.l  #RGBFB_CLUT,p96modeid_rgbformat
        cmp     #2,g2display_mode
        beq.w   .is_p96
        move    #2,p96modeid_state
        bra.w   .done
.is_p96
        tst     p96present
        bne.w   .have_library
        jsr     g2p96_req_show_nolib
        jsr     g2p96_req_fallback_aga
        bra.w   .done
.have_library
        clr     g2p96_modeid_override_used
        tst     g2p96_modeid_override_present
        beq.w   .try_saved
        jsr     g2p96_modeid_override_validate_host_c87b78s
        tst.l   d0
        bne.w   .accept
        jsr     g2p96_req_show_bad_override
        bra.w   .normal_requester
.try_saved
        tst     g2rc4_lshift_override_v21
        bne.w   .normal_requester
        tst     g2rc4_save_screenmode_v21
        beq.w   .normal_requester
        move.l  g2rc4_saved_modeid_v21,d0
        beq.w   .normal_requester
        jsr     g2rc4_validate_saved_mode_v21
        tst.l   d0
        beq.w   .normal_requester
        move    #-1,g2rc4_saved_mode_used_v21
        bra.w   .accept
.normal_requester
        jsr     g2p96_req_build_candidates_host_c87b78s
        tst     g2p96_req_available_count
        bne.w   .choose
        jsr     g2p96_req_show_nomodes_host_c87b78s
        jsr     g2p96_req_fallback_aga
        bra.w   .done
.choose
        move    #-1,g2rc4_req_selected_row_v21
        jsr     g2p96_req_show_resolution
        tst.l   d0
        bgt.w   .selected
        bmi.w   .use_chipset
        move    #-1,g2p96_req_abort_startup
        jsr     g2p96_close
        bra.w   .done
.use_chipset
        jsr     g2p96_req_fallback_aga
        bra.w   .done
.selected
        subq    #1,d0
        move    d0,g2p96_req_selected_index
        jsr     g2p96_req_apply_candidate
        jsr     g2p96_req_select_candidate_c87b80f
        cmp.l   #P96_INVALID_ID,d0
        beq.w   .choose
        tst.l   d0
        beq.w   .choose
        jsr     g2p96_req_validate_current
        tst.l   d0
        bne.w   .selected_valid
        jsr     g2p96_req_show_invalid
        bra.w   .choose
.selected_valid
        move    #-1,g2rc4_requester_selected_v21
.accept
        move.l  d0,d7
        move.l  d7,p96modeid
        move.l  p96base,a6
        move.l  d7,d0
        moveq   #G2P96_IDA_DEPTH,d1
        jsr     -84(a6)
        move    d0,p96modeid_depth
        move.l  d7,d0
        moveq   #P96IDA_RGBFORMAT,d1
        jsr     -84(a6)
        move.l  d0,p96modeid_rgbformat
        move    #1,p96modeid_state
        tst     g2rc4_requester_selected_v21
        beq.w   .done
        jsr     g2rc4_p96prefs_save_v21
.done
        movem.l (a7)+,d1-d7/a0-a6
        moveq   #0,d0
        rts

; Preserve the user's existing binary config prefix, append/update only P961.
g2rc4_p96prefs_save_v21
        movem.l d0-d7/a0-a6,-(a7)
        move.l  dosbase,d0
        beq.w   .done
        lea     g2rc4_cfg_buffer_v21(pc),a0
        moveq   #0,d0
        moveq   #12,d1
.clear
        move.l  d0,(a0)+
        dbf     d1,.clear

        move.l  dosbase,a6
        lea     g2cfg_name,a0
        move.l  a0,d1
        move.l  #1005,d2
        jsr     -30(a6)
        move.l  d0,d7
        beq.w   .build_default
        move.l  d7,d1
        lea     g2rc4_cfg_buffer_v21(pc),a0
        move.l  a0,d2
        move.l  #G2RC4_CFG_TOTAL_LEN_V21+6,d3
        jsr     -42(a6)
        move.l  d0,d6
        move.l  d7,d1
        jsr     -36(a6)
        cmp.l   #g2cfg_len_old,d6
        bcs.w   .build_default
        lea     g2rc4_cfg_buffer_v21(pc),a0
        cmp.l   #'GLMC',(a0)+
        bne.w   .build_default
        cmp.b   #'F',(a0)+
        bne.w   .build_default
        cmp.b   #'G',(a0)+
        bne.w   .build_default
        move    (a0),d0
        cmp     #1,d0
        blt.w   .build_default
        cmp     #4,d0
        ble.w   .have_prefix
.build_default
        lea     g2rc4_cfg_buffer_v21(pc),a0
        move.l  #'GLMC',(a0)+
        move.b  #'F',(a0)+
        move.b  #'G',(a0)+
        move    #4,(a0)+
        move    #320,(a0)+
        move    #240,(a0)+
        move    #1,(a0)+               ; floor
        move    #1,(a0)+               ; ceiling
        move    #-1,(a0)+              ; blob shadows
        move    #-1,(a0)+              ; reflections
        clr     (a0)+                  ; invincible
        clr     (a0)+                  ; bouncy
        clr     (a0)+                  ; weapon
        clr     (a0)+                  ; boost
        clr     (a0)+                  ; one hit
        move    #-1,(a0)+              ; visibility
        clr     (a0)+                  ; resolution 1x1
.have_prefix
        ; The requester saves BEFORE gameplay cfg load. Preserve BAY1 here,
        ; otherwise selecting a screenmode would erase saved Bayer NO.
        lea     g2rc4_cfg_buffer_v21+G2RC4_CFG_TOTAL_LEN_V21(pc),a0
        cmp.l   #'BAY1',(a0)
        beq.w   .bayer_preserved
        move.l  #'BAY1',(a0)+
        clr.w   (a0)
.bayer_preserved
        lea     g2rc4_cfg_buffer_v21+G2RC4_CFG_BASE_LEN_V21(pc),a0
        move.l  #G2RC4_CFG_EXT_SIG_V21,(a0)+
        tst     g2rc4_save_screenmode_v21
        beq.w   .no_saved_id
        move.l  p96modeid,d0
        bra.w   .store_id
.no_saved_id
        moveq   #0,d0
.store_id
        move.l  d0,(a0)+
        move    g2rc4_save_screenmode_v21,d0
        beq.w   .store_save
        moveq   #-1,d0
.store_save
        move    d0,(a0)+
        move    g2rc4_low_bandwidth_v21,d0
        beq.w   .store_low
        moveq   #-1,d0
.store_low
        move    d0,(a0)+

        lea     g2cfg_name,a0
        move.l  a0,d1
        move.l  #1006,d2
        move.l  dosbase,a6
        jsr     -30(a6)
        move.l  d0,d7
        beq.w   .done
        move.l  d7,d1
        lea     g2rc4_cfg_buffer_v21(pc),a0
        move.l  a0,d2
        move.l  #G2RC4_CFG_TOTAL_LEN_V21+6,d3
        jsr     -48(a6)
        move.l  d7,d1
        jsr     -36(a6)

        tst     g2rc4_save_screenmode_v21
        beq.w   .clear_runtime_saved
        move.l  p96modeid,g2rc4_saved_modeid_v21
        bra.w   .done
.clear_runtime_saved
        clr.l   g2rc4_saved_modeid_v21
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Checkbox-aware replacement drawing for the established custom requester.
g2rc4_p96_req_custom_draw_v21
        movem.l d0-d7/a0-a6,-(a7)
        move.l  g2p96_req_custom_window,d0
        beq.w   .done
        move.l  d0,a0
        move.l  50(a0),a1
        move.l  g2p96_req_custom_grbase,a6
        moveq   #G2P96_REQ_PEN_BG,d0
        jsr     -348(a6)
        moveq   #0,d0
        jsr     -354(a6)

        moveq   #0,d0
        moveq   #0,d1
        move    #G2P96_REQ_CONTENT_W-1,d2
        move    #G2P96_REQ_CONTENT_H-1,d3
        moveq   #G2P96_REQ_PEN_BG,d4
        jsr     g2p96_req_custom_rect

        moveq   #5,d0
        moveq   #2,d1
        move    #G2P96_REQ_CONTENT_W-6,d2
        moveq   #25,d3
        moveq   #G2P96_REQ_PEN_SHADOW,d4
        jsr     g2p96_req_custom_rect
        moveq   #6,d0
        moveq   #3,d1
        move    #G2P96_REQ_CONTENT_W-7,d2
        moveq   #24,d3
        moveq   #G2P96_REQ_PEN_HILITE,d4
        jsr     g2p96_req_custom_rect
        lea     g2p96_req_custom_warning1,a0
        move    #g2p96_req_custom_warning1_len,d0
        moveq   #0,d1
        move    #G2P96_REQ_CONTENT_W,d2
        moveq   #11,d3
        moveq   #G2P96_REQ_PEN_TEXT,d4
        jsr     g2p96_req_custom_text_center
        lea     g2p96_req_custom_warning2,a0
        move    #g2p96_req_custom_warning2_len,d0
        moveq   #0,d1
        move    #G2P96_REQ_CONTENT_W,d2
        moveq   #21,d3
        moveq   #G2P96_REQ_PEN_TEXT,d4
        jsr     g2p96_req_custom_text_center
        lea     g2p96_req_custom_select,a0
        move    #g2p96_req_custom_select_len,d0
        moveq   #0,d1
        move    #G2P96_REQ_CONTENT_W,d2
        move    #G2P96_REQ_SELECT_BASE,d3
        moveq   #G2P96_REQ_PEN_TEXT,d4
        jsr     g2p96_req_custom_text_center

        ; Screenmode rows are selection buttons. The chosen row remains latched
        ; in the title-bar accent colour until OK is pressed.
        moveq   #0,d6
        move    g2p96_req_display_count,d7
        subq    #1,d7
        bmi.w   .buttons_done
.buttons_loop
        moveq   #G2P96_REQ_MODE_X,d0
        move    d6,d1
        mulu    #G2P96_REQ_MODE_STEP,d1
        add     #G2P96_REQ_MODE_Y,d1
        lea     g2p96_req_map,a0
        moveq   #0,d2
        move.b  0(a0,d6.w),d2
        lea     g2p96_req_custom_label_ptrs,a0
        move.l  0(a0,d2*4),a1
        lea     g2p96_req_custom_label_lens,a0
        move    0(a0,d2*2),d2
        move.l  a1,a0
        cmp     g2rc4_req_selected_row_v21,d6
        bne.w   .normal_button
        jsr     g2rc4_p96_req_custom_button_selected_v21
        bra.w   .button_done
.normal_button
        jsr     g2p96_req_custom_button
.button_done
        addq    #1,d6
        dbf     d7,.buttons_loop
.buttons_done

        ; Save-screenmode checkbox.
        lea     g2rc4_checkbox_off_v21(pc),a0
        tst     g2rc4_save_screenmode_v21
        beq.w   .save_box_ready
        lea     g2rc4_checkbox_on_v21(pc),a0
.save_box_ready
        moveq   #3,d0
        move    #12,d1
        move    #G2RC4_REQ_SAVE_BASE_Y_V21,d2
        moveq   #G2P96_REQ_PEN_TEXT,d3
        jsr     g2p96_req_custom_text
        lea     g2rc4_save_label_v21(pc),a0
        move    #g2rc4_save_label_len_v21,d0
        move    #44,d1
        move    #G2RC4_REQ_SAVE_BASE_Y_V21,d2
        moveq   #G2P96_REQ_PEN_TEXT,d3
        jsr     g2p96_req_custom_text
        lea     g2rc4_shift_note_v21(pc),a0
        move    #g2rc4_shift_note_len_v21,d0
        move    #44,d1
        move    #G2RC4_REQ_SHIFT_BASE_Y_V21,d2
        moveq   #G2P96_REQ_PEN_TEXT,d3
        jsr     g2p96_req_custom_text

        ; Low-bandwidth checkbox.
        lea     g2rc4_checkbox_off_v21(pc),a0
        tst     g2rc4_low_bandwidth_v21
        beq.w   .low_box_ready
        lea     g2rc4_checkbox_on_v21(pc),a0
.low_box_ready
        moveq   #3,d0
        move    #12,d1
        move    #G2RC4_REQ_LOWBW_BASE_Y_V21,d2
        moveq   #G2P96_REQ_PEN_TEXT,d3
        jsr     g2p96_req_custom_text
        lea     g2rc4_lowbw_label_v21(pc),a0
        move    #g2rc4_lowbw_label_len_v21,d0
        move    #44,d1
        move    #G2RC4_REQ_LOWBW_BASE_Y_V21,d2
        moveq   #G2P96_REQ_PEN_TEXT,d3
        jsr     g2p96_req_custom_text

        ; Final actions: OK confirms the latched row; AGA/ECS and CANCEL keep
        ; their established immediate actions.
        move    #G2RC4_REQ_OK_X_V21,d0
        move    #G2RC4_REQ_ACTION_Y_V21,d1
        lea     g2p96_req_ok,a0
        move    #G2P96_REQ_OK_LEN,d2
        jsr     g2rc4_p96_req_custom_button_80_v21
        move    #G2RC4_REQ_AGA_X_V21,d0
        move    #G2RC4_REQ_ACTION_Y_V21,d1
        lea     g2p96_req_aga,a0
        move    #G2P96_REQ_AGA_LEN,d2
        jsr     g2rc4_p96_req_custom_button_80_v21
        move    #G2RC4_REQ_CANCEL_X_V21,d0
        move    #G2RC4_REQ_ACTION_Y_V21,d1
        lea     g2p96_req_cancel,a0
        move    #G2P96_REQ_CANCEL_LEN,d2
        jsr     g2rc4_p96_req_custom_button_80_v21
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Repair exposed SIMPLE_REFRESH damage without disturbing the current state.
; BeginRefresh restricts the full redraw to Intuition's damaged region;
; EndRefresh(TRUE) then completes and clears the refresh state.
g2rc4_p96_req_custom_refresh_v21
        movem.l d0-d7/a0-a6,-(a7)
        move.l  g2p96_req_custom_window,d0
        beq.w   .done
        move.l  d0,a0
        move.l  g2p96_req_custom_intbase,a6
        jsr     -354(a6)                ; BeginRefresh(window)
        jsr     g2rc4_p96_req_custom_draw_v21
        move.l  g2p96_req_custom_window,a0
        moveq   #-1,d0                  ; Complete=TRUE
        move.l  g2p96_req_custom_intbase,a6
        jsr     -366(a6)                ; EndRefresh(window,TRUE)
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Mouse/keyboard/refresh wait loop. UI changes redraw the same window.
g2rc4_p96_req_custom_wait_v21
        movem.l d1-d7/a0-a6,-(a7)
.wait
        move.l  g2p96_req_custom_window,a0
        move.l  86(a0),a0
        move.l  4.w,a6
        jsr     -384(a6)
.drain
        move.l  g2p96_req_custom_window,a0
        move.l  86(a0),a0
        move.l  4.w,a6
        jsr     -372(a6)
        tst.l   d0
        beq.w   .wait
        move.l  d0,a2
        move.l  20(a2),d4
        moveq   #0,d5
        move    24(a2),d5
        moveq   #0,d6
        move    32(a2),d6
        moveq   #0,d7
        move    34(a2),d7
        move.l  a2,a1
        move.l  4.w,a6
        jsr     -378(a6)
        cmp.l   #$00000004,d4           ; IDCMP_REFRESHWINDOW
        beq.w   .refresh
        cmp.l   #$00000008,d4
        beq.w   .mouse
        cmp.l   #$00000400,d4
        beq.w   .key
        bra.w   .drain
.refresh
        jsr     g2rc4_p96_req_custom_refresh_v21
        bra.w   .drain
.mouse
        cmp     #$0068,d5
        bne.w   .drain
        move    d6,d0
        move    d7,d1
        jsr     g2rc4_p96_req_custom_hit_v21
        cmp     #G2RC4_REQ_SAVE_HIT_V21,d0
        beq.w   .toggle_save
        cmp     #G2RC4_REQ_LOWBW_HIT_V21,d0
        beq.w   .toggle_low
        cmp     #G2RC4_REQ_OK_HIT_V21,d0
        beq.w   .confirm
        cmp     #-1,d0
        beq.w   .drain
        tst     d0
        beq.w   .done                  ; CANCEL
        move    g2p96_req_display_count,d1
        addq    #1,d1
        cmp     d1,d0
        beq.w   .done                  ; AGA/ECS
        cmp     g2p96_req_display_count,d0
        bhi.w   .drain
        subq    #1,d0
        move    d0,g2rc4_req_selected_row_v21
        bra.w   .redraw
.toggle_save
        tst     g2rc4_save_screenmode_v21
        beq.w   .save_on
        clr     g2rc4_save_screenmode_v21
        bra.w   .redraw
.save_on
        move    #-1,g2rc4_save_screenmode_v21
        bra.w   .redraw
.toggle_low
        tst     g2rc4_low_bandwidth_v21
        beq.w   .low_on
        clr     g2rc4_low_bandwidth_v21
        bra.w   .redraw
.low_on
        move    #-1,g2rc4_low_bandwidth_v21
.redraw
        jsr     g2rc4_p96_req_custom_draw_v21
        bra.w   .drain
.confirm
        move    g2rc4_req_selected_row_v21,d0
        bmi.w   .drain
        addq    #1,d0
        bra.w   .done
.key
        btst    #7,d5
        bne.w   .drain
        and     #$007f,d5
        cmp     #$45,d5
        beq.w   .cancel
        cmp     #$33,d5
        beq.w   .cancel
        cmp     #$20,d5
        beq.w   .use_chipset
        cmp     #$44,d5               ; RETURN = OK
        beq.w   .confirm
        cmp     #$43,d5               ; numeric ENTER = OK
        beq.w   .confirm
        cmp     #1,d5
        bcs.w   .drain
        cmp     #6,d5
        bhi.w   .drain
        cmp     g2p96_req_display_count,d5
        bhi.w   .drain
        subq    #1,d5
        move    d5,g2rc4_req_selected_row_v21
        bra.w   .redraw
.use_chipset
        moveq   #0,d0
        move    g2p96_req_display_count,d0
        addq    #1,d0
        bra.w   .done
.cancel
        moveq   #0,d0
.done
        movem.l (a7)+,d1-d7/a0-a6
        rts

; Return mode/action values compatible with the original hit tester, plus
; -2/-3 for the two checkbox rows.
g2rc4_p96_req_custom_hit_v21
        movem.l d1-d5,-(a7)
        move    d0,d2
        move    d1,d3
        sub     g2p96_req_custom_origin_x,d2
        sub     g2p96_req_custom_origin_y,d3
        moveq   #-1,d0

        cmp     #G2RC4_REQ_ACTION_Y_V21,d3
        blt.w   .checkboxes
        cmp     #G2RC4_REQ_ACTION_Y_V21+22,d3
        bge.w   .done
        cmp     #G2RC4_REQ_OK_X_V21,d2
        blt.w   .done
        cmp     #G2RC4_REQ_OK_X_V21+G2RC4_REQ_ACTION_W_V21,d2
        blt.w   .ok
        cmp     #G2RC4_REQ_AGA_X_V21,d2
        blt.w   .done
        cmp     #G2RC4_REQ_AGA_X_V21+G2RC4_REQ_ACTION_W_V21,d2
        blt.w   .use_chipset
        cmp     #G2RC4_REQ_CANCEL_X_V21,d2
        blt.w   .done
        cmp     #G2RC4_REQ_CANCEL_X_V21+G2RC4_REQ_ACTION_W_V21,d2
        bge.w   .done
        moveq   #0,d0
        bra.w   .done
.ok
        moveq   #G2RC4_REQ_OK_HIT_V21,d0
        bra.w   .done
.use_chipset
        moveq   #0,d0
        move    g2p96_req_display_count,d0
        addq    #1,d0
        bra.w   .done

.checkboxes
        cmp     #8,d2
        blt.w   .mode_list
        cmp     #292,d2
        bge.w   .mode_list
        cmp     #G2RC4_REQ_SAVE_HIT_TOP_V21,d3
        blt.w   .mode_list
        cmp     #G2RC4_REQ_SAVE_HIT_END_V21,d3
        blt.w   .save_hit
        cmp     #G2RC4_REQ_LOWBW_HIT_TOP_V21,d3
        blt.w   .mode_list
        cmp     #G2RC4_REQ_LOWBW_HIT_END_V21,d3
        blt.w   .low_hit
        bra.w   .mode_list
.save_hit
        moveq   #G2RC4_REQ_SAVE_HIT_V21,d0
        bra.w   .done
.low_hit
        moveq   #G2RC4_REQ_LOWBW_HIT_V21,d0
        bra.w   .done

.mode_list
        cmp     #G2P96_REQ_MODE_X,d2
        blt.w   .done
        cmp     #G2P96_REQ_MODE_X+G2P96_REQ_MODE_W,d2
        bge.w   .done
        cmp     #G2P96_REQ_MODE_Y,d3
        blt.w   .done
        move    d3,d4
        sub     #G2P96_REQ_MODE_Y,d4
        moveq   #0,d5
.row_loop
        cmp     #G2P96_REQ_MODE_H,d4
        bcs.w   .row_hit
        sub     #G2P96_REQ_MODE_STEP,d4
        bmi.w   .done
        addq    #1,d5
        cmp     #6,d5
        bcs.w   .row_loop
        bra.w   .done
.row_hit
        cmp     g2p96_req_display_count,d5
        bcc.w   .done
        move    d5,d0
        addq    #1,d0
.done
        movem.l (a7)+,d1-d5
        rts

; Selected full-width screenmode button. The accent fill uses the same
; classic pen reserved for the requester/title-bar colour and the inverted
; edge treatment makes the row look latched rather than momentarily clicked.
g2rc4_p96_req_custom_button_selected_v21
        movem.l d0-d7/a0-a2,-(a7)
        move    d0,d5
        move    d1,d6
        move.l  a0,a2
        move    d2,d7
        move    d5,d0
        move    d6,d1
        move    d5,d2
        add     #G2P96_REQ_MODE_W-1,d2
        move    d6,d3
        add     #G2P96_REQ_MODE_H-1,d3
        moveq   #G2P96_REQ_PEN_SHADOW,d4
        jsr     g2p96_req_custom_rect
        move    d5,d0
        addq    #1,d0
        move    d6,d1
        addq    #1,d1
        move    d5,d2
        add     #G2P96_REQ_MODE_W-2,d2
        move    d6,d3
        add     #G2P96_REQ_MODE_H-2,d3
        moveq   #G2P96_REQ_PEN_ACCENT,d4
        jsr     g2p96_req_custom_rect
        ; Bottom and right highlight complete the pressed/latched bevel.
        move    d5,d0
        addq    #1,d0
        move    d6,d1
        add     #G2P96_REQ_MODE_H-1,d1
        move    d5,d2
        add     #G2P96_REQ_MODE_W-1,d2
        move    d6,d3
        add     #G2P96_REQ_MODE_H-1,d3
        moveq   #G2P96_REQ_PEN_HILITE,d4
        jsr     g2p96_req_custom_rect
        move    d5,d0
        add     #G2P96_REQ_MODE_W-1,d0
        move    d6,d1
        addq    #1,d1
        move    d5,d2
        add     #G2P96_REQ_MODE_W-1,d2
        move    d6,d3
        add     #G2P96_REQ_MODE_H-1,d3
        moveq   #G2P96_REQ_PEN_HILITE,d4
        jsr     g2p96_req_custom_rect
        move.l  a2,a0
        move    d7,d0
        move    d5,d1
        add     #12,d1
        move    d6,d2
        add     #G2P96_REQ_MODE_TEXT_BASE,d2
        moveq   #G2P96_REQ_PEN_HILITE,d3
        jsr     g2p96_req_custom_text
        movem.l (a7)+,d0-d7/a0-a2
        rts

; d0=x, d1=y, a0=label, d2=label length; 80x22 action button.
g2rc4_p96_req_custom_button_80_v21
        movem.l d0-d7/a0-a2,-(a7)
        move    d0,d5
        move    d1,d6
        move.l  a0,a2
        move    d2,d7
        move    d5,d0
        move    d6,d1
        move    d5,d2
        add     #G2RC4_REQ_ACTION_W_V21-1,d2
        move    d6,d3
        add     #21,d3
        moveq   #G2P96_REQ_PEN_SHADOW,d4
        jsr     g2p96_req_custom_rect
        move    d5,d0
        addq    #1,d0
        move    d6,d1
        addq    #1,d1
        move    d5,d2
        add     #G2RC4_REQ_ACTION_W_V21-2,d2
        move    d6,d3
        add     #20,d3
        moveq   #G2P96_REQ_PEN_BG,d4
        jsr     g2p96_req_custom_rect
        move    d5,d0
        move    d6,d1
        move    d5,d2
        add     #G2RC4_REQ_ACTION_W_V21-2,d2
        move    d6,d3
        moveq   #G2P96_REQ_PEN_HILITE,d4
        jsr     g2p96_req_custom_rect
        move    d5,d0
        move    d6,d1
        move    d5,d2
        move    d6,d3
        add     #20,d3
        moveq   #G2P96_REQ_PEN_HILITE,d4
        jsr     g2p96_req_custom_rect
        move.l  a2,a0
        move    d7,d0
        move    d5,d1
        move    #G2RC4_REQ_ACTION_W_V21,d2
        move    d6,d3
        add     #G2P96_REQ_ACTION_TEXT_BASE,d3
        moveq   #G2P96_REQ_PEN_TEXT,d4
        jsr     g2p96_req_custom_text_center
        movem.l (a7)+,d0-d7/a0-a2
        rts

; Render every frame into Fast RAM as before, but publish only alternating
; completed frames to an already active P96 gameplay screen when enabled.
g2rc4_p96_present_dispatch_v21
        cmp     #2,g2display_mode
        bne.w   .normal_reset
        tst     g2rc4_low_bandwidth_v21
        beq.w   .normal_reset
        tst     p96gameplay_persist_active
        beq.w   .normal_reset
        tst     p96newgame_hold_black_c87b79c
        bne.w   .normal_reset
        cmp     #P96DSP_GAMEPLAY,p96display_state
        bne.w   .normal_reset
        tst     p96gameplay_linear_ready
        beq.w   .normal_reset
        tst     g2rc4_lowbw_phase_v21
        beq.w   .publish
        clr     g2rc4_lowbw_phase_v21
        move    #-1,p96gameplay_skip_aga_present
        rts
.publish
        move    #-1,g2rc4_lowbw_phase_v21
        jmp     g2p96_gameplay_present_probe
.normal_reset
        clr     g2rc4_lowbw_phase_v21
        jmp     g2p96_gameplay_present_probe

        even
g2rc4_checkbox_off_v21     dc.b '[ ] '
g2rc4_checkbox_on_v21      dc.b '[X] '
g2rc4_save_label_v21       dc.b 'Save Screenmode'
g2rc4_save_label_end_v21
g2rc4_save_label_len_v21   equ g2rc4_save_label_end_v21-g2rc4_save_label_v21
g2rc4_shift_note_v21       dc.b '(L-Shift at startup overrides)'
g2rc4_shift_note_end_v21
g2rc4_shift_note_len_v21   equ g2rc4_shift_note_end_v21-g2rc4_shift_note_v21
g2rc4_lowbw_label_v21      dc.b 'Low Bandwidth (eg. pVision)'
g2rc4_lowbw_label_end_v21
g2rc4_lowbw_label_len_v21  equ g2rc4_lowbw_label_end_v21-g2rc4_lowbw_label_v21
g2rc4_req_title_v22        dc.b 'Gloom Reforged (Picasso96 Mode)',0
        even

; End of Gloom Reforged v2.0 RC4 requester/preferences additions.
