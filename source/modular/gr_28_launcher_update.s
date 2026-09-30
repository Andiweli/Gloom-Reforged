; LauncherUpdate1: optional independent AmiSSL worker, before game init only.
; The worker owns its code/libraries/files and may finish after this window closes.
; No networking, DOS polling, or update code is called from a game frame/interrupt.
; gr_24/gr_18 retain the established P96 mode selection and public-screen UI.

; Native modes keep their explicit AGA/ECS selection. Never probe P96 here.
g2update_native_launcher
        tst     g2rc4_lshift_override_v21
        beq.w   .done
        movem.l d0-d7/a0-a6,-(a7)
        move    #-1,g2update_native
        lea     g2p96_req_candidate_ids,a0
        moveq   #5,d0
.clear
        clr.l   (a0)+
        dbf     d0,.clear
        clr     g2p96_req_available_count
        move    #-1,g2rc4_req_selected_row_v21
        jsr     g2p96_req_show_resolution
        tst.l   d0
        beq.w   .cancel
        jsr     g2launcher_pref_save
        bra.w   .continue
.cancel
        move    #-1,g2p96_req_abort_startup
.continue
        clr     g2update_native
        movem.l (a7)+,d0-d7/a0-a6
.done   rts

; Return a0/d0 = second white-panel line and its length.
g2update_subtitle
        lea     g2p96_req_custom_warning2,a0
        move    #g2p96_req_custom_warning2_len,d0
        tst     g2update_native
        beq.w   .done
        lea     g2update_native_aga,a0
        cmp     #3,g2display_mode
        bne.w   .length
        lea     g2update_native_ecs,a0
.length moveq   #17,d0
.done   rts

g2update_draw_native
        movem.l d0-d7/a0-a6,-(a7)
        lea     g2update_native_note,a0
        move    #g2update_native_note_end-g2update_native_note,d0
        moveq   #0,d1
        move    #G2P96_REQ_CONTENT_W,d2
        moveq   #80,d3
        moveq   #G2P96_REQ_PEN_TEXT,d4
        jsr     g2p96_req_custom_text_center
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Called only after the visitor window has opened successfully.
g2update_init
        movem.l d0-d7/a0-a6,-(a7)
        jsr     g2update_get_pens
        tst     g2update_state
        bne.w   .done
        ; Derive installed public version from the common build marker.
        lea     g2build_version_text,a0
        lea     g2update_version,a1
        moveq   #14,d1
.version
        move.b  (a0)+,d0
        cmp.b   #' ',d0
        beq.w   .version_end
        move.b  d0,(a1)+
        dbf     d1,.version
.version_end
        clr.b   (a1)
        ; Task address plus DateStamp ticks makes concurrent launcher jobs distinct.
        move.l  4.w,a6
        suba.l  a1,a1
        jsr     -294(a6)              ; FindTask(NULL)
        lea     g2update_job_task,a0
        jsr     g2p96_long_to_hex8
        lea     g2update_stamp,a0
        move.l  a0,d1
        move.l  dosbase,a6
        jsr     -192(a6)              ; DateStamp
        move.l  g2update_stamp+8,d0
        lea     g2update_job_time,a0
        jsr     g2p96_long_to_hex8
        lea     g2update_job,a0
        lea     g2update_status_path,a1
        jsr     g2p96_req_copy_text
        lea     g2update_suffix,a0
        jsr     g2p96_req_copy_text
        clr.b   (a1)
        move    #1,g2update_state
        lea     g2update_check_arg,a0
        jsr     g2update_spawn
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

; DOS CreateNewProc copies NP_Arguments and owns/frees the separately loaded seglist.
; Default NIL: input/output handles are private to the worker, not parent handles.
; No shell and no remote text in the command line.
g2update_spawn
        movem.l d0-d7/a0-a6,-(a7)
        lea     g2update_args,a1
        jsr     g2p96_req_copy_text
        lea     g2update_version,a0
        jsr     g2p96_req_copy_text
        move.b  #' ',(a1)+
        lea     g2update_job,a0
        jsr     g2p96_req_copy_text
        move.b  #10,(a1)+
        clr.b   (a1)
        move.l  dosbase,a6
        cmp     #37,20(a6)            ; NP_Arguments operational since V37
        bcs.w   .failed
        lea     g2update_status_path,a0
        move.l  a0,d1
        jsr     -72(a6)              ; DeleteFile (stale completed result)
        lea     g2update_helper,a0
        move.l  a0,d1
        jsr     -150(a6)             ; LoadSeg(PROGDIR:GloomUpdate)
        move.l  d0,g2update_proc_seg+4
        beq.w   .failed
        lea     g2update_proc_tags,a0
        move.l  a0,d1
        jsr     -498(a6)             ; CreateNewProc
        tst.l   d0
        bne.w   .started
        move.l  g2update_proc_seg+4,d1
        jsr     -156(a6)             ; UnLoadSeg: ownership not transferred
.failed
        move    #6,g2update_state
.started
        move    #1,g2update_ticks
        move    #240,g2update_polls_left
        cmp     #4,g2update_state
        bne.w   .timeout_ready
        move    #1800,g2update_polls_left
.timeout_ready
        clr.l   g2update_proc_seg+4
        movem.l (a7)+,d0-d7/a0-a6
        rts

g2update_download
        cmp     #2,g2update_state
        bne.w   .done
        move    #4,g2update_state     ; disable immediately, before process launch
        lea     g2update_get_arg,a0
        jsr     g2update_spawn
.done   rts

; Called by replied INTUITICKS messages, at most every fifth tick (~0.5 seconds).
; d0=1 means redraw; only closed, atomically renamed 256-byte results are consumed.
g2update_poll
        movem.l d1-d7/a0-a6,-(a7)
        moveq   #0,d7
        cmp     #1,g2update_state
        beq.w   .pending
        cmp     #4,g2update_state
        bne.w   .done
.pending
        subq    #1,g2update_ticks
        bgt.w   .done
        move    #5,g2update_ticks
        lea     g2update_status_path,a0
        move.l  a0,d1
        move.l  #1005,d2
        move.l  dosbase,a6
        jsr     -30(a6)              ; Open MODE_OLDFILE
        move.l  d0,d6
        bne.w   .have_result
        subq    #1,g2update_polls_left
        bgt.w   .done
        moveq   #1,d7
        bra.w   .error
.have_result
        move.l  d6,d1
        lea     g2update_response,a0
        move.l  a0,d2
        move.l  #256,d3
        jsr     -42(a6)              ; Read
        move.l  d0,d5
        move.l  d6,d1
        jsr     -36(a6)              ; Close
        lea     g2update_status_path,a0
        move.l  a0,d1
        jsr     -72(a6)              ; DeleteFile, never an open worker output
        moveq   #1,d7
        cmp.l   #256,d5
        bne.w   .error
        cmp.l   #'GRU1',g2update_response
        bne.w   .error
        clr.b   g2update_response+39 ; cap worker tag and diagnostic strings
        clr.b   g2update_response+255
        move.b  g2update_response+4,d0
        cmp.b   #'E',d0
        beq.w   .error
        cmp     #4,g2update_state
        beq.w   .download_result
        cmp.b   #'U',d0
        beq.w   .current
        cmp.b   #'N',d0
        bne.w   .error
        lea     g2update_new_label,a1
        lea     g2update_new_prefix,a0
        jsr     g2p96_req_copy_text
        lea     g2update_response+8,a0
        ; Protocol limits version display to 15 chars; cap again at this boundary.
        cmp.b   #'v',(a0)
        beq.w   .skip_v
        cmp.b   #'V',(a0)
        bne.w   .version_tag
.skip_v
        addq.l  #1,a0
.version_tag
        moveq   #11,d1
.tag
        move.b  (a0)+,d0
        beq.w   .tag_end
        move.b  d0,(a1)+
        dbf     d1,.tag
.tag_end
        clr.b   (a1)
        move    #2,g2update_state
        bra.w   .done
.current
        move    #3,g2update_state
        bra.w   .done
.download_result
        cmp.b   #'D',d0
        bne.w   .error
        move    #5,g2update_state
        bra.w   .done
.error
        move    #6,g2update_state
.done
        move.l  d7,d0
        movem.l (a7)+,d1-d7/a0-a6
        rts

; Same bevel and dimensions as a resolution button. Disabled states use a grey
; text pen and are excluded by hit testing; only NEW is red and clickable.
g2update_draw
        movem.l d0-d7/a0-a6,-(a7)
        lea     g2update_checking,a2
        cmp     #2,g2update_state
        bne.w   .not_new
        lea     g2update_new_label,a2
.not_new
        cmp     #3,g2update_state
        bne.w   .not_current
        lea     g2update_current,a2
.not_current
        cmp     #4,g2update_state
        bne.w   .not_downloading
        lea     g2update_downloading,a2
.not_downloading
        cmp     #5,g2update_state
        bne.w   .not_downloaded
        lea     g2update_downloaded,a2
.not_downloaded
        cmp     #6,g2update_state
        bne.w   .label
        lea     g2update_unavailable,a2
.label
        move.l  a2,a0
        moveq   #0,d7
.length
        tst.b   (a0)+
        beq.w   .draw
        addq    #1,d7
        bra.w   .length
.draw
        move.l  a2,a0
        moveq   #G2P96_REQ_MODE_X,d0
        moveq   #29,d1
        move    d7,d2
        jsr     g2p96_req_custom_button
        ; Erase the original black label before drawing grey/red text.
        move    #G2P96_REQ_MODE_X+2,d0
        moveq   #31,d1
        move    #G2P96_REQ_MODE_X+G2P96_REQ_MODE_W-3,d2
        move    #29+G2P96_REQ_MODE_H-3,d3
        moveq   #G2P96_REQ_PEN_BG,d4
        jsr     g2p96_req_custom_rect
        move.l  a2,a0
        move    d7,d0
        moveq   #G2P96_REQ_MODE_X,d1
        move    #G2P96_REQ_MODE_W,d2
        moveq   #29+G2P96_REQ_MODE_TEXT_BASE,d3
        move.l  g2update_grey_pen,d4
        cmp     #2,g2update_state
        bne.w   .pen
        move.l  g2update_red_pen,d4
.pen
        tst.l   d4
        bpl.w   .text
        moveq   #G2P96_REQ_PEN_TEXT,d4
.text
        jsr     g2p96_req_custom_text_center
        movem.l (a7)+,d0-d7/a0-a6
        rts

; Obtain/release pens on the public screen without altering Workbench colours.
g2update_get_pens
        move.l  #-1,g2update_red_pen
        move.l  #-1,g2update_grey_pen
        clr.l   g2update_colormap
        move.l  g2p96_req_custom_grbase,a6
        cmp     #39,20(a6)
        bcs.w   .done
        move.l  g2p96_req_custom_window,a0
        move.l  46(a0),a0           ; Window.WScreen
        move.l  48(a0),a0           ; Screen.ViewPort.ColorMap
        move.l  a0,g2update_colormap
        suba.l  a1,a1
        move.l  #$ffffffff,d1
        moveq   #0,d2
        moveq   #0,d3
        jsr     -840(a6)            ; ObtainBestPenA(map,red,green,blue,NULL)
        move.l  d0,g2update_red_pen
        move.l  g2update_colormap,a0
        suba.l  a1,a1
        move.l  #$77777777,d1
        move.l  d1,d2
        move.l  d1,d3
        jsr     -840(a6)
        move.l  d0,g2update_grey_pen
.done   rts

g2update_release_pens
        movem.l d0-d1/a0-a1/a6,-(a7)
        tst.l   g2update_colormap
        beq.w   .done
        move.l  g2p96_req_custom_grbase,a6
        move.l  g2update_red_pen,d0
        bmi.w   .grey
        move.l  g2update_colormap,a0
        jsr     -948(a6)            ; ReleasePen
.grey
        move.l  g2update_grey_pen,d0
        bmi.w   .clear
        move.l  g2update_colormap,a0
        jsr     -948(a6)
.clear
        clr.l   g2update_colormap
        move.l  #-1,g2update_red_pen
        move.l  #-1,g2update_grey_pen
.done
        movem.l (a7)+,d0-d1/a0-a1/a6
        rts

        even
g2update_native       dc.w 0
g2update_state        dc.w 0 ; 0 unstarted,1 checking,2 new,3 current,4 get,5 done,6 error
g2update_polls_left   dc.w 240
g2update_ticks        dc.w 1
g2update_red_pen      dc.l -1
g2update_grey_pen     dc.l -1
g2update_colormap     dc.l 0
g2update_stamp        ds.l 3
g2update_proc_tags
g2update_proc_seg     dc.l $800003e9,0       ; NP_Seglist
                      dc.l $800003ea,1       ; NP_FreeSeglist
                      dc.l $800003f3,65536   ; NP_StackSize
                      dc.l $800003f4,g2update_process_name
                      dc.l $800003f5,-1      ; NP_Priority (below the launcher)
                      dc.l $800003f7,-1      ; NP_WindowPtr: no DOS error requesters
                      dc.l $800003fa,1       ; NP_Cli
                      dc.l $800003fd,g2update_args ; NP_Arguments, copied by DOS
                      dc.l 0,0
g2update_helper       dc.b 'PROGDIR:GloomUpdate',0
g2update_process_name dc.b 'Gloom Reforged update',0
g2update_check_arg    dc.b 'CHECK ',0
g2update_get_arg      dc.b 'GET ',0
g2update_suffix       dc.b '.status',0
g2update_job          dc.b 'RAM:GRUpdate-'
g2update_job_task     ds.b 8
                      dc.b '-'
g2update_job_time     ds.b 8
                      dc.b 0
g2update_checking     dc.b 'Checking for updates...',0
g2update_current      dc.b 'Gloom Reforged is up to date!',0
g2update_downloading  dc.b 'Downloading update to RAM:...',0
g2update_downloaded   dc.b 'Update downloaded to RAM:',0
g2update_unavailable  dc.b 'Update check/download unavailable',0
g2update_new_prefix   dc.b 'Download new Update v',0
g2update_native_aga   dc.b 'Native AGA output',0
g2update_native_ecs   dc.b 'Native ECS output',0
g2update_native_note  dc.b 'Press OK to start the game.'
g2update_native_note_end
                      even
g2update_version      ds.b 16
g2update_status_path  ds.b 96
g2update_new_label    ds.b 64
g2update_args         ds.b 128
g2update_response     ds.b 256
                      even

; v2.3: independent preference, unaffected by gameplay gloom.cfg writers.
; Only accepted launcher choices are saved. Missing/invalid data defaults OFF.
g2launcher_pref_load
        movem.l d0-d7/a0-a6,-(a7)
        clr.w   g2launcher_always
        clr.w   g2launcher_saved
        lea     g2launcher_pref_name,a0
        move.l  a0,d1
        move.l  #1005,d2
        move.l  dosbase,a6
        jsr     -30(a6)
        move.l  d0,d7
        beq.w   .done
        move.l  d7,d1
        lea     g2launcher_pref_data,a0
        move.l  a0,d2
        moveq   #6,d3
        jsr     -42(a6)
        move.l  d0,d6
        move.l  d7,d1
        jsr     -36(a6)
        cmp.l   #6,d6
        bne.w   .done
        cmp.l   #'GLA1',g2launcher_pref_data
        bne.w   .done
        cmp.w   #-1,g2launcher_pref_data+4
        bne.w   .done
        move.w  #-1,g2launcher_always
        move.w  #-1,g2launcher_saved
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

g2launcher_pref_save
        movem.l d0-d7/a0-a6,-(a7)
        move.w  g2launcher_always,d0
        cmp.w   g2launcher_saved,d0
        beq.w   .done
        move.l  #'GLA1',g2launcher_pref_data
        move.w  d0,g2launcher_pref_data+4
        lea     g2launcher_pref_name,a0
        move.l  a0,d1
        move.l  #1006,d2
        move.l  dosbase,a6
        jsr     -30(a6)
        move.l  d0,d7
        beq.w   .done
        move.l  d7,d1
        lea     g2launcher_pref_data,a0
        move.l  a0,d2
        moveq   #6,d3
        jsr     -48(a6)
        move.l  d0,d6
        move.l  d7,d1
        jsr     -36(a6)
        tst.l   d0
        beq.w   .done
        cmp.l   #6,d6
        bne.w   .done
        move.w  g2launcher_always,g2launcher_saved
.done
        movem.l (a7)+,d0-d7/a0-a6
        rts

        even
g2launcher_always    dc.w 0
g2launcher_saved     dc.w 0
g2launcher_pref_data dc.l 'GLA1'
                     dc.w 0
g2launcher_pref_name dc.b 'PROGDIR:gloom.launcher',0
g2launcher_always_label dc.b 'Always show Launcher'
        even
