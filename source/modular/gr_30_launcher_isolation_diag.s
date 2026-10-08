; detail2: controlled test branches, entirely absent from normal builds.
; No graphics/Exec/DOS ABI changes and no replacement mode-discovery algorithm.
        ifne G2DIAG_STAGE
        ifeq G2LAUNCHER_DIAG
        fail "G2DIAG_STAGE requires G2LAUNCHER_DIAG=1"
        endc
        even

; Validate only the caller-supplied ID through the established exact contract.
; Derive the visible candidate slot from returned target geometry; never assume
; an ID base or a default ID, never allocate a P96 mode list in this test.
g2iso_seed_candidate
        movem.l d1-d7/a0-a6,-(a7)
        lea     g2p96_req_candidate_ids,a0
        moveq   #5,d1
.clear
        clr.l   (a0)+
        dbf     d1,.clear
        clr.w   g2p96_req_available_count
        tst.w   g2p96_modeid_override_present
        beq.w   .fail
        g2ld_mark 59
        jsr     g2p96_modeid_override_validate_host_c87b78s
        move.l  d0,d7
        beq.w   .fail
        lea     g2iso_geometries,a0
        moveq   #0,d6
.find
        move.w  (a0)+,d1
        move.w  (a0)+,d2
        cmp.w   p96target_width,d1
        bne.w   .next
        cmp.w   p96target_height,d2
        beq.w   .found
.next
        addq.w  #1,d6
        cmp.w   #6,d6
        bcs.w   .find
        bra.w   .fail
.found
        move.w  d6,g2p96_req_selected_index
        lsl.w   #2,d6
        lea     g2p96_req_candidate_ids,a0
        move.l  d7,0(a0,d6.w)
        move.w  #1,g2p96_req_available_count
        g2ld_mark 61
        move.l  d7,d0
        bra.w   .done
.fail
        moveq   #0,d0
.done
        movem.l (a7)+,d1-d7/a0-a6
        rts

; Central normal pre-init exit: no graphics/input/audio takeover ever starts.
g2iso_finish
        movem.l d0-d7/a0-a6,-(a7)
        move.w  #-1,g2p96_req_abort_startup
        g2ld_mark 62
        jsr     g2p96_close
        g2ld_mark 63
        movem.l (a7)+,d0-d7/a0-a6
        rts
g2iso_geometries
        dc.w 320,240,320,256,428,240,640,480,640,512,854,480
        endc
