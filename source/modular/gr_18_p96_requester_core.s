; -----------------------------------------------------------------------------
; c87b70 - filtered P96 mode requester
;
; Stage 1 is a compact Intuition requester containing only supported resolutions
; that actually exist as exact 8-bit CLUT P96 modes on the current system.
; Stage 2 is the official p96RequestModeIDTagList requester, constrained to the
; selected exact width/height, 8-bit depth and RGBFB_CLUT. Gloom Reforged 2.0
; no longer exposes 16-bit modes in the native P96 mode contract.
;
; Supported output geometries:
;   320x240  standard
;   320x256  5:4
;   428x240  wide
;   640x480  standard high resolution
;   640x512  5:4 high resolution
;   854x480  wide high resolution
;
; 400x240/800x480 STRETCH and the WIDE/HIRES/5:4 tokens are intentionally gone.
; -----------------------------------------------------------------------------

G2P96_BID_FORMATS_ALLOWED	equ	P96BIDTAG_Dummy+$0001
G2P96_MA_DUMMY		equ	TAG_USER+$10000+96
G2P96_MA_MINWIDTH		equ	G2P96_MA_DUMMY+$0001
G2P96_MA_MINHEIGHT		equ	G2P96_MA_DUMMY+$0002
G2P96_MA_MINDEPTH		equ	G2P96_MA_DUMMY+$0003
G2P96_MA_MAXWIDTH		equ	G2P96_MA_DUMMY+$0004
G2P96_MA_MAXHEIGHT		equ	G2P96_MA_DUMMY+$0005
G2P96_MA_MAXDEPTH		equ	G2P96_MA_DUMMY+$0006
G2P96_MA_DISPLAYID		equ	G2P96_MA_DUMMY+$0007
G2P96_MA_FORMATSALLOWED	equ	G2P96_MA_DUMMY+$0008
G2P96_MA_WINDOWTITLE		equ	G2P96_MA_DUMMY+$000a
G2P96_MA_OKTEXT		equ	G2P96_MA_DUMMY+$000b
G2P96_MA_CANCELTEXT		equ	G2P96_MA_DUMMY+$000c
G2P96_RGBFF_SUPPORTED	equ	RGBFF_CLUT	;Gloom Reforged 2.0 exposes native 8-bit CLUT only
G2P96_IDA_DEPTH		equ	2
G2P96_IDA_BYTESPERPIXEL	equ	3
G2P96_IDA_BITSPERPIXEL	equ	4
G2P96_IDA_ISP96		equ	6

; Intuition V36+ Screen structure offsets used to calculate the final
; centered LeftEdge/TopEdge before the native chooser window is opened.
G2P96_S_WIDTH		equ	12
G2P96_S_HEIGHT		equ	14

; Main replacement for the old automatic P96 mode search.
; The first requester has distinct Use AGA and CANCEL actions.
g2p96_mode_requester_probe
	movem.l	d1-d7/a0-a6,-(a7)
	clr	g2p96_req_abort_startup
	clr.l	p96modeid
	clr	p96modeid_depth
	clr	p96modeid_state
	move.l	#RGBFB_CLUT,p96modeid_rgbformat
	cmp	#2,g2display_mode
	beq.s	.g2p96_req_is_p96
	move	#2,p96modeid_state
	bra.w	.g2p96_req_done
.g2p96_req_is_p96
	tst	p96present
	bne.s	.g2p96_req_have_library
	jsr	g2p96_req_show_nolib
	jsr	g2p96_req_fallback_aga
	bra.w	.g2p96_req_done
.g2p96_req_have_library
	clr	g2p96_modeid_override_used
	tst	g2p96_modeid_override_present
	beq	.g2p96_req_no_override
	jsr	g2p96_modeid_override_validate_host_c87b78s
	tst.l	d0
	bne	.g2p96_req_accept
	; A stale, malformed or unsupported ID must never bypass validation.
	; Explain the fallback, then show the two normal requesters.
	jsr	g2p96_req_show_bad_override
.g2p96_req_no_override
	jsr	g2p96_req_build_candidates_host_c87b78s
	tst	g2p96_req_available_count
	bne.s	.g2p96_req_choose_resolution
	jsr	g2p96_req_show_nomodes_host_c87b78s
	jsr	g2p96_req_fallback_aga
	bra.w	.g2p96_req_done
.g2p96_req_choose_resolution
	jsr	g2p96_req_show_resolution
	tst.l	d0
	bgt.s	.g2p96_req_resolution_selected
	bmi.s	.g2p96_req_resolution_use_aga
	; c87b70b: zero is the new final CANCEL gadget. Close the passive
	; P96 library and let entrypoint leave through its pre-init cleanup.
	move	#-1,g2p96_req_abort_startup
	jsr	g2p96_close
	bra.w	.g2p96_req_done
.g2p96_req_resolution_use_aga
	jsr	g2p96_req_fallback_aga
	bra.w	.g2p96_req_done
.g2p96_req_resolution_selected
	subq	#1,d0
	move	d0,g2p96_req_selected_index
	jsr	g2p96_req_apply_candidate
	jsr	g2p96_req_select_candidate_c87b80f
	cmp.l	#P96_INVALID_ID,d0
	beq.s	.g2p96_req_choose_resolution
	tst.l	d0
	beq.s	.g2p96_req_choose_resolution
	jsr	g2p96_req_validate_current
	tst.l	d0
	bne.s	.g2p96_req_accept
	jsr	g2p96_req_show_invalid
	bra.s	.g2p96_req_choose_resolution
.g2p96_req_accept
	move.l	d0,d7
	move.l	d7,p96modeid
	move.l	p96base,a6
	move.l	d7,d0
	moveq	#G2P96_IDA_DEPTH,d1
	jsr	-84(a6)
	move	d0,p96modeid_depth
	move.l	d7,d0
	moveq	#P96IDA_RGBFORMAT,d1
	jsr	-84(a6)
	move.l	d0,p96modeid_rgbformat
	move	#1,p96modeid_state
.g2p96_req_done
	movem.l	(a7)+,d1-d7/a0-a6
	moveq	#0,d0
	rts

; Probe the six supported geometries and remember one exact valid mode for each.
g2p96_req_build_candidates
	movem.l	d0-d7/a0-a2,-(a7)
	lea	g2p96_req_candidate_ids,a0
	moveq	#0,d0
	moveq	#5,d1
.g2p96_req_clear_ids
	move.l	d0,(a0)+
	dbf	d1,.g2p96_req_clear_ids
	clr	g2p96_req_available_count
	moveq	#0,d6
.g2p96_req_probe_loop
	move	d6,d0
	jsr	g2p96_req_apply_candidate
	jsr	g2p96_req_best_current
	tst.l	d0
	beq.s	.g2p96_req_probe_next
	lea	g2p96_req_candidate_ids,a0
	move	d6,d1
	lsl	#2,d1
	move.l	d0,0(a0,d1.w)
	addq	#1,g2p96_req_available_count
.g2p96_req_probe_next
	addq	#1,d6
	cmp	#6,d6
	bne.s	.g2p96_req_probe_loop
	movem.l	(a7)+,d0-d7/a0-a2
	rts

; Input d0.w = candidate index 0..5. Sets all old internal geometry flags and
; target tags so the existing proven presenters are reused unchanged.
g2p96_req_apply_candidate
	movem.l	d1-d3,-(a7)
	clr	g2p96_hires_mode
	clr	g2p96_stretch_mode
	clr	g2p96_wide_mode
	clr	g2p96_oneone_mode
	cmp	#1,d0
	beq.s	.g2p96_req_c_320x256
	cmp	#2,d0
	beq.s	.g2p96_req_c_428x240
	cmp	#3,d0
	beq.s	.g2p96_req_c_640x480
	cmp	#4,d0
	beq.s	.g2p96_req_c_640x512
	cmp	#5,d0
	beq.s	.g2p96_req_c_854x480
.g2p96_req_c_320x240
	move	#320,d0
	move	#240,d1
	moveq	#0,d2
	bra.s	.g2p96_req_c_set
.g2p96_req_c_320x256
	move	#-1,g2p96_oneone_mode
	move	#320,d0
	move	#256,d1
	moveq	#0,d2
	bra.s	.g2p96_req_c_set
.g2p96_req_c_428x240
	move	#-1,g2p96_wide_mode
	move	#428,d0
	move	#240,d1
	moveq	#3,d2
	bra.s	.g2p96_req_c_set
.g2p96_req_c_640x480
	move	#-1,g2p96_hires_mode
	move	#640,d0
	move	#480,d1
	moveq	#1,d2
	bra.s	.g2p96_req_c_set
.g2p96_req_c_640x512
	move	#-1,g2p96_hires_mode
	move	#-1,g2p96_oneone_mode
	move	#640,d0
	move	#512,d1
	moveq	#1,d2
	bra.s	.g2p96_req_c_set
.g2p96_req_c_854x480
	move	#-1,g2p96_hires_mode
	move	#-1,g2p96_wide_mode
	move	#854,d0
	move	#480,d1
	moveq	#2,d2
.g2p96_req_c_set
	jsr	g2p96_set_target_mode
	movem.l	(a7)+,d1-d3
	rts

; Find one exact mode for availability/preselection. The official requester is
; used after this and may offer multiple timings/cards for the chosen geometry.
g2p96_req_best_current
	jmp	g2p96_req_best_current_c87b80f
; Validate an exact mode against the released 8-bit CLUT presenter contract.
; Input/output d0.l = ModeID, zero on failure.
g2p96_req_validate_current
	jmp	g2p96_req_validate_current_c87b78j
; Build the numbered, availability-filtered resolution chooser text.
g2p96_req_build_text
	movem.l	d0-d7/a0-a4,-(a7)
	lea	g2p96_req_body_prefix,a0
	lea	g2p96_req_body_buffer,a1
	jsr	g2p96_req_copy_text
	lea	g2p96_req_gadget_buffer,a2
	lea	g2p96_req_candidate_ids,a3
	lea	g2p96_req_map,a4
	moveq	#0,d6	;candidate index
	moveq	#0,d7	;displayed number/count
.g2p96_req_text_loop
	tst.l	(a3)+
	beq.s	.g2p96_req_text_next
	addq	#1,d7
	move	d7,d0
	add	#'0',d0
	move.b	d0,(a1)+
	move.b	#'.',(a1)+
	move.b	#' ',(a1)+
	move.b	d0,(a2)+
	move.b	#'|',(a2)+
	move.b	d6,(a4)+
	lea	g2p96_req_line_ptrs,a0
	move	d6,d1
	lsl	#2,d1
	move.l	0(a0,d1.w),a0
	jsr	g2p96_req_copy_text
.g2p96_req_text_next
	addq	#1,d6
	cmp	#6,d6
	bne.s	.g2p96_req_text_loop
	move	d7,g2p96_req_display_count
	lea	g2p96_req_body_footer,a0
	jsr	g2p96_req_copy_text
	clr.b	(a1)
	move.l	a2,a1
	lea	g2p96_req_use_aga,a0
	jsr	g2p96_req_copy_text
	move.b	#'|',(a1)+
	lea	g2p96_req_cancel,a0
	jsr	g2p96_req_copy_text
	clr.b	(a1)
	movem.l	(a7)+,d0-d7/a0-a4
	rts

; Copy zero-terminated text without the terminator. a0=source, a1=destination.
g2p96_req_copy_text
	move.b	(a0)+,d0
	beq.s	.g2p96_req_copy_done
	move.b	d0,(a1)+
	bra.s	g2p96_req_copy_text
.g2p96_req_copy_done
	rts

; Return candidate index+1, -1 for Use AGA, or zero for CANCEL/failure.
; EasyRequestArgs returns zero for the final gadget, hence CANCEL is last.
g2p96_req_show_resolution
	jmp	g2p96_req_show_resolution_c87b70j	;c87b70j: styled native chooser lives at EOF

; Invoke the official P96 requester with exact, discontinuous filtering already
; resolved by stage 1. This shows matching 8-bit CLUT cards/timings for one geometry.
g2p96_req_show_exact_modes
	movem.l	d1-d7/a0-a2/a6,-(a7)
	moveq	#0,d0
	move	p96target_width,d0
	move.l	d0,g2p96_req_minwidth+4
	move.l	d0,g2p96_req_maxwidth+4
	moveq	#0,d0
	move	p96target_height,d0
	move.l	d0,g2p96_req_minheight+4
	move.l	d0,g2p96_req_maxheight+4
	move	g2p96_req_selected_index,d0
	lsl	#2,d0
	lea	g2p96_req_candidate_ids,a0
	move.l	0(a0,d0.w),d0
	move.l	d0,g2p96_req_displayid+4
	move.l	p96base,d0
	beq.s	.g2p96_req_exact_fail
	move.l	d0,a6
	lea	g2p96_req_mode_tags,a0
	jsr	-66(a6)	;p96RequestModeIDTagList
	bra.s	.g2p96_req_exact_done
.g2p96_req_exact_fail
	move.l	#P96_INVALID_ID,d0
.g2p96_req_exact_done
	movem.l	(a7)+,d1-d7/a0-a2/a6
	rts

; First-requester hard failures select the host's native chipset renderer.
; On AGA hosts this remains AGA; on OCS/ECS hosts it is the ECS/EHB path.
; Final CANCEL remains a separate clean startup abort.
g2p96_req_fallback_aga
	movem.l	d0-d2,-(a7)
	jsr	g2p96_req_select_chipset_fallback_c87b78s
	nop			;same 8-byte footprint as MOVE.W #1,abs.l
	clr	g2p96_hires_mode
	clr	g2p96_stretch_mode
	clr	g2p96_wide_mode
	clr	g2p96_oneone_mode
	move	#320,d0
	move	#240,d1
	moveq	#0,d2
	jsr	g2p96_set_target_mode
	clr.l	p96modeid
	clr	p96modeid_depth
	move	#2,p96modeid_state
	nop
	nop
	nop
	nop			;host helper already selected AGA or ECS core
	movem.l	(a7)+,d0-d2
	rts

; Small shared EasyRequest helper. a1 = EasyStruct, return value ignored.
g2p96_req_show_easy_a1
	movem.l	d0-d3/d5/a0-a3/a6,-(a7)
	move.l	a1,a2
	move.l	4.w,a6
	lea	g2p96_req_intuition_name,a1
	jsr	-408(a6)
	move.l	d0,d5
	beq.s	.g2p96_req_easy_done
	move.l	d0,a6
	suba.l	a0,a0
	move.l	a2,a1
	suba.l	a2,a2
	suba.l	a3,a3
	jsr	-588(a6)
	move.l	d5,a1
	move.l	4.w,a6
	jsr	-414(a6)
.g2p96_req_easy_done
	movem.l	(a7)+,d0-d3/d5/a0-a3/a6
	rts

g2p96_req_show_nomodes
	lea	g2p96_req_nomodes_easy,a1
	jmp	g2p96_req_show_easy_a1

g2p96_req_show_nolib
	lea	g2p96_req_nolib_easy,a1
	jmp	g2p96_req_show_easy_a1

g2p96_req_show_invalid
	lea	g2p96_req_invalid_easy,a1
	jmp	g2p96_req_show_easy_a1

g2p96_req_show_bad_override
	lea	g2p96_req_bad_override_easy,a1
	jmp	g2p96_req_show_easy_a1

	even
g2p96_req_candidate_ids	dcb.l	6,0
g2p96_req_map		dcb.b	6,0
	even
g2p96_req_available_count	dc.w	0
g2p96_req_display_count	dc.w	0
g2p96_req_selected_index	dc.w	0
g2p96_req_abort_startup	dc.w	0	;c87b70b: CANCEL exits before initmain
	even

; Exact-mode availability probe tags.
g2p96_req_best_tags
g2p96_req_best_formats	dc.l	G2P96_BID_FORMATS_ALLOWED,G2P96_RGBFF_SUPPORTED
g2p96_req_best_width	dc.l	P96BIDTAG_NominalWidth,320
g2p96_req_best_height	dc.l	P96BIDTAG_NominalHeight,240
g2p96_req_best_depth	dc.l	P96BIDTAG_Depth,8
	dc.l	TAG_DONE,0

; Official exact P96 requester tags.
g2p96_req_mode_tags
g2p96_req_minwidth	dc.l	G2P96_MA_MINWIDTH,320
g2p96_req_minheight	dc.l	G2P96_MA_MINHEIGHT,240
	dc.l	G2P96_MA_MINDEPTH,8
g2p96_req_maxwidth	dc.l	G2P96_MA_MAXWIDTH,320
g2p96_req_maxheight	dc.l	G2P96_MA_MAXHEIGHT,240
	dc.l	G2P96_MA_MAXDEPTH,8
g2p96_req_displayid	dc.l	G2P96_MA_DISPLAYID,0
	dc.l	G2P96_MA_FORMATSALLOWED,G2P96_RGBFF_SUPPORTED
	dc.l	G2P96_MA_WINDOWTITLE,g2p96_req_exact_title
	dc.l	G2P96_MA_OKTEXT,g2p96_req_exact_ok
	dc.l	G2P96_MA_CANCELTEXT,g2p96_req_exact_back
	dc.l	TAG_DONE,0

; Stage-1 filtered resolution requester.
g2p96_req_easystruct
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_body_buffer
	dc.l	g2p96_req_gadget_buffer

g2p96_req_nomodes_easy
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_nomodes_body
	dc.l	g2p96_req_ok

g2p96_req_nolib_easy
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_nolib_body
	dc.l	g2p96_req_ok

g2p96_req_invalid_easy
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_invalid_body
	dc.l	g2p96_req_ok

g2p96_req_bad_override_easy
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_req_bad_override_body
	dc.l	g2p96_req_ok

	even
g2p96_req_line_ptrs
	dc.l	g2p96_req_line_320240
	dc.l	g2p96_req_line_320256
	dc.l	g2p96_req_line_428240
	dc.l	g2p96_req_line_640480
	dc.l	g2p96_req_line_640512
	dc.l	g2p96_req_line_854480

; 512 bytes is deliberately generous for localized Workbench fonts/layouts.
g2p96_req_body_buffer	ds.b	512
g2p96_req_gadget_buffer	ds.b	64
	even

g2p96_req_intuition_name	dc.b	'intuition.library',0
g2p96_req_title	dc.b	'Gloom Reforged P96',0
g2p96_req_body_prefix
	dc.b	'Gloom Reforged 2.0 uses native direct-indexed',10
	dc.b	'8-bit Picasso96 output',10,10
	dc.b	'Select an available P96 output size',10,10,0
g2p96_req_body_footer
	dc.b	10,'The following requester shows the exact',10
	dc.b	'matching 8-bit CLUT P96 screen modes...',0
g2p96_req_use_aga	dc.b	'Use '
g2p96_req_use_aga_host	dc.b	'AGA',0
g2p96_req_aga
g2p96_req_aga_host	dc.b	'AGA',0
g2p96_req_cancel	dc.b	'CANCEL',0
g2p96_req_ok	dc.b	'OK',0

g2p96_req_line_320240	dc.b	'320x240, Standard',10,0
g2p96_req_line_320256	dc.b	'320x256, 5:4',10,0
g2p96_req_line_428240	dc.b	'428x240, Widescreen',10,0
g2p96_req_line_640480	dc.b	'640x480, Standard HiRes',10,0
g2p96_req_line_640512	dc.b	'640x512, 5:4 HiRes',10,0
g2p96_req_line_854480	dc.b	'854x480, Widescreen HiRes',10,0

g2p96_req_exact_title	dc.b	'Gloom Reforged - Select P96 Screen Mode',0
g2p96_req_exact_ok	dc.b	'Use Mode',0
g2p96_req_exact_back	dc.b	'Back',0

g2p96_req_nomodes_body
	dc.b	'No supported 8-bit CLUT P96 mode was found.',10
	dc.b	'Supported sizes are 320x240, 320x256, 428x240,',10
	dc.b	'640x480, 640x512 and 854x480.',10,10
	dc.b	'Gloom Reforged will start in '
g2p96_req_nomodes_host	dc.b	'AGA'
	dc.b	' mode.',0

g2p96_req_nolib_body
	dc.b	'Picasso96API.library was not found.',10,10
	dc.b	'Gloom Reforged will start in '
g2p96_req_nolib_host	dc.b	'AGA'
	dc.b	' mode.',0

g2p96_req_invalid_body
	dc.b	'The selected P96 mode is not an exact supported',10
	dc.b	'8-bit CLUT mode.',10
	dc.b	'Please select another mode.',0

g2p96_req_bad_override_body
	dc.b	'The P96MODEID ToolType is invalid, unsupported',10
	dc.b	'or no longer present in the current P96 setup.',10,10
	dc.b	'The normal P96 requesters will be shown.',0
	even



; -----------------------------------------------------------------------------
; Canonical build identifier kept at EOF to preserve the established placement.
; The former verbose P96 palette-map diagnostic block was removed in c87b79m; c87b79n makes DISPLAY=P96 the sole planar-source owner.
; -----------------------------------------------------------------------------
g2build_version_text	dc.b	'2.0 c87b80o'
g2build_version_text_end
g2build_version_text_len	equ	g2build_version_text_end-g2build_version_text

	; c87b79n: keep the canonical version string aligned after the source-backend cleanup.
	; The former 256-entry RGB565 palette-map dump remains removed.
	even

; -----------------------------------------------------------------------------
; c87b70g EOF implementation: Classic Gloom live palette/remap rebuild.
; Kept out of the historical main code layout to avoid new GenAm range errors.
; -----------------------------------------------------------------------------
g2v190cx_g1_count	dc.w	0
	even
g2v190cx_build_g1_tables_impl
	cmp	#1,g2_game_profile
	bne.w	.g2v190cx_done
	movem.l	d0-d7/a0-a4,-(a7)
	;
	; c87b70g: Classic Gloom has no physical palette_6/8 or remap_6/8.
	; The embedded Gloom-Deluxe tables are useful only as an early startup
	; fallback.  Once a map and its event objects are loaded, replace them with
	; the exact live Classic colour pool which addpal/remap already used to
	; rewrite every texture/object pixel.
	;
	lea	g2v190cx_g1_palette,a0
	moveq	#0,d0
	move	#511,d7		; clear the full 1024-byte AGA/P96 buffer
.g2v190cx_clear_palette
	move	d0,(a0)+
	dbf	d7,.g2v190cx_clear_palette
	lea	g2v190cx_g1_remap,a0
	move	#4095,d7
.g2v190cx_clear_remap
	move.b	d0,(a0)+
	dbf	d7,.g2v190cx_clear_remap
	;
	; Count the live global palette entries, including the reserved index 0.
	move.l	map_rgbs,a0
	move.l	map_rgbsat,d0
	sub.l	a0,d0
	lsr.l	#1,d0
	cmp.l	#256,d0
	bls.s	.g2v190cx_count_aga_ok
	move.l	#256,d0
.g2v190cx_count_aga_ok
	tst	aga
	bne.s	.g2v190cx_count_ready
	cmp.l	#32,d0
	bls.s	.g2v190cx_count_ready
	moveq	#32,d0		; ECS programs 32 base colours; EHB is hardware-derived
.g2v190cx_count_ready
	move	d0,g2v190cx_g1_count
	;
	; Build the display palette in the layout expected by the active chipset.
	; Index 0 is a transparent/reserved map entry and must display as black.
	move.l	map_rgbs,a0
	lea	g2v190cx_g1_palette,a2
	lea	g2v190cx_g1_remap,a3
	moveq	#0,d3
	move	g2v190cx_g1_count,d7
	beq.s	.g2v190cx_palette_done
	subq	#1,d7
.g2v190cx_palette_loop
	move	(a0)+,d0
	tst	d3
	bne.s	.g2v190cx_palette_real
	moveq	#0,d0
	bra.s	.g2v190cx_palette_store
.g2v190cx_palette_real
	and	#$0fff,d0
.g2v190cx_palette_store
	tst	aga
	beq.s	.g2v190cx_palette_ecs
	move	d0,(a2)+		; AGA/P96 high RGB12 word
	clr	(a2)+			; low-nibble word (Classic data is RGB12)
	bra.s	.g2v190cx_palette_exact
.g2v190cx_palette_ecs
	move	d0,(a2)+		; ECS packed RGB12 word
.g2v190cx_palette_exact
.g2v190cx_palette_next
	addq	#1,d3
	dbf	d7,.g2v190cx_palette_loop
.g2v190cx_palette_done
	;
	; ECS has only 32 programmable base registers.  When Classic's exact cyan
	; $0FF exists anywhere in the live colour pool, preserve it explicitly by
	; replacing the nearest selected base slot.  AGA/P96 already retain every
	; live colour directly and therefore need no anchor replacement.
	tst	aga
	bne.w	.g2v190cx_seed_exact
	move.l	map_rgbs,a0
	addq.l	#2,a0
	move.l	map_rgbsat,a1
.g2v190cx_find_cyan
	cmp.l	a1,a0
	bcc.w	.g2v190cx_seed_exact
	move	(a0)+,d0
	and	#$0fff,d0
	cmp	#$00ff,d0
	bne.s	.g2v190cx_find_cyan
	move	g2v190cx_g1_count,d7
	subq	#2,d7
	bmi.w	.g2v190cx_seed_exact
	lea	g2v190cx_g1_palette+2,a0
	move	#$7fff,d4
	moveq	#1,d5
	moveq	#1,d6
.g2v190cx_cyan_nearest
	move	(a0)+,d0
	and	#$0fff,d0
	moveq	#0,d3
	move	d0,d1
	lsr	#8,d1
	and	#$000f,d1
	add	d1,d3			; target red is zero
	move	d0,d1
	lsr	#4,d1
	and	#$000f,d1
	moveq	#15,d2
	sub	d1,d2
	add	d2,d3
	and	#$000f,d0
	moveq	#15,d2
	sub	d0,d2
	add	d2,d3
	cmp	d4,d3
	bcc.s	.g2v190cx_cyan_next
	move	d3,d4
	move	d6,d5
	tst	d3
	beq.s	.g2v190cx_cyan_install
.g2v190cx_cyan_next
	addq	#1,d6
	dbf	d7,.g2v190cx_cyan_nearest
.g2v190cx_cyan_install
	move	d5,d0
	add	d0,d0
	lea	g2v190cx_g1_palette,a0
	move	#$00ff,0(a0,d0.w)
	;
	; Pre-seed every exact display-palette colour after the optional ECS anchor
	; has been installed.  Reserved index 0 remains excluded.
.g2v190cx_seed_exact
	lea	g2v190cx_g1_palette,a0
	lea	g2v190cx_g1_remap,a3
	moveq	#1,d3
	move	g2v190cx_g1_count,d7
	subq	#2,d7
	bmi.s	.g2v190cx_exact_done
	tst	aga
	beq.s	.g2v190cx_exact_ecs_start
	addq.l	#4,a0
	bra.s	.g2v190cx_exact_loop_aga
.g2v190cx_exact_ecs_start
	addq.l	#2,a0
	bra.s	.g2v190cx_exact_loop_ecs
.g2v190cx_exact_loop_aga
	move	(a0),d0
	addq.l	#4,a0
	and	#$0fff,d0
	move.b	d3,0(a3,d0.w)
	addq	#1,d3
	dbf	d7,.g2v190cx_exact_loop_aga
	bra.s	.g2v190cx_exact_done
.g2v190cx_exact_loop_ecs
	move	(a0)+,d0
	and	#$0fff,d0
	move.b	d3,0(a3,d0.w)
	addq	#1,d3
	dbf	d7,.g2v190cx_exact_loop_ecs
.g2v190cx_exact_done
	;
	; Fill every still-unmapped RGB12 value with the nearest live Classic
	; colour.  This is required by calcpalettes: its 16 darkness tables create
	; RGB12 values which are not necessarily exact members of map_rgbs.
	lea	g2v190cx_g1_remap,a2
	moveq	#0,d7
.g2v190cx_target_loop
	tst.b	0(a2,d7.w)
	bne.w	.g2v190cx_target_next	; exact non-zero palette index already known
	tst	d7
	beq.w	.g2v190cx_target_next	; keep RGB $000 mapped to reserved/black 0
	move	g2v190cx_g1_count,d6
	subq	#2,d6			; real colours are indices 1..count-1
	bmi.w	.g2v190cx_target_next
	move	#$7fff,d4			; best Manhattan RGB distance
	moveq	#0,d5			; best palette index
	tst	aga
	beq.s	.g2v190cx_nearest_source_ecs
	move.l	map_rgbs,a0
	addq.l	#2,a0			; AGA/P96: live colours after reserved index 0
	bra.s	.g2v190cx_nearest_loop
.g2v190cx_nearest_source_ecs
	lea	g2v190cx_g1_palette+2,a0	; ECS: selected/anchored base colours
.g2v190cx_nearest_loop
	move	(a0)+,d0
	and	#$0fff,d0
	moveq	#0,d3
	; red distance
	move	d7,d1
	lsr	#8,d1
	and	#$000f,d1
	move	d0,d2
	lsr	#8,d2
	and	#$000f,d2
	sub	d1,d2
	bpl.s	.g2v190cx_red_pos
	neg	d2
.g2v190cx_red_pos
	add	d2,d3
	; green distance
	move	d7,d1
	lsr	#4,d1
	and	#$000f,d1
	move	d0,d2
	lsr	#4,d2
	and	#$000f,d2
	sub	d1,d2
	bpl.s	.g2v190cx_green_pos
	neg	d2
.g2v190cx_green_pos
	add	d2,d3
	; blue distance
	move	d7,d1
	and	#$000f,d1
	move	d0,d2
	and	#$000f,d2
	sub	d1,d2
	bpl.s	.g2v190cx_blue_pos
	neg	d2
.g2v190cx_blue_pos
	add	d2,d3
	cmp	d4,d3
	bcc.s	.g2v190cx_nearest_next
	move	d3,d4
	move	g2v190cx_g1_count,d5
	sub	d6,d5
	subq	#1,d5			; current index = count - dbfCounter - 1
	tst	d3
	beq.s	.g2v190cx_nearest_done
.g2v190cx_nearest_next
	dbf	d6,.g2v190cx_nearest_loop
.g2v190cx_nearest_done
	move.b	d5,0(a2,d7.w)
.g2v190cx_target_next
	addq	#1,d7
	cmp	#4096,d7
	bcs.w	.g2v190cx_target_loop
	;
	move.l	#g2v190cx_g1_palette,planar_palette
	move.l	#g2v190cx_g1_remap,planar_remap
	movem.l	(a7)+,d0-d7/a0-a4
.g2v190cx_done
	rts

	even

; -----------------------------------------------------------------------------
; c87b70s: polished classic-titlebar, fixed-font, single-column P96 chooser.
; The legacy entry label is retained so the established call site and earlier
; renderer/menu layout stay unchanged.
; -----------------------------------------------------------------------------
g2p96_req_show_resolution_c87b70j
	movem.l	d1-d7/a0-a6,-(a7)
	jsr	g2p96_req_build_text
	jsr	g2p96_req_custom_calc_layout
	clr	g2p96_req_custom_result
	clr.l	g2p96_req_custom_window
	clr.l	g2p96_req_custom_screen
	clr.l	g2p96_req_custom_grbase
	clr.l	g2p96_req_custom_intbase
	clr.l	g2p96_req_custom_font
	clr	g2p96_req_custom_origin_x
	clr	g2p96_req_custom_origin_y

	; Open Intuition and graphics only for this early, pre-initmain chooser.
	move.l	4.w,a6
	lea	g2p96_req_intuition_name,a1
	jsr	-408(a6)			; OldOpenLibrary intuition.library
	move.l	d0,g2p96_req_custom_intbase
	beq.w	.g2p96_req_custom_cancel
	move.l	4.w,a6
	lea	g2p96_req_graphics_name,a1
	jsr	-408(a6)			; OldOpenLibrary graphics.library
	move.l	d0,g2p96_req_custom_grbase
	beq.w	.g2p96_req_custom_fallback_easy

	; Lock the actual default public screen, calculate the final centered
	; coordinates first, then open the window once at that position. Unlike an
	; EasyRequester, no already-visible upper-left window has to be moved.
	move.l	g2p96_req_custom_intbase,a6
	suba.l	a0,a0
	jsr	-510(a6)			; LockPubScreen(NULL)
	move.l	d0,g2p96_req_custom_screen
	beq.w	.g2p96_req_custom_fallback_easy
	move.l	d0,a1
	moveq	#0,d0
	move	G2P96_S_WIDTH(a1),d0
	sub	#G2P96_REQ_WIN_W,d0
	asr	#1,d0
	bpl.s	.g2p96_req_custom_x_ok
	moveq	#0,d0
.g2p96_req_custom_x_ok
	move	d0,g2p96_req_custom_newwindow
	moveq	#0,d1
	move	G2P96_S_HEIGHT(a1),d1
	sub	#G2P96_REQ_WIN_H,d1
	asr	#1,d1
	bpl.s	.g2p96_req_custom_y_ok
	moveq	#0,d1
.g2p96_req_custom_y_ok
	move	d1,g2p96_req_custom_newwindow+2
	move.l	a1,g2p96_req_custom_newwindow+30	; NewWindow.Screen
	move.l	g2p96_req_custom_intbase,a6
	lea	g2p96_req_custom_newwindow,a0
	jsr	-204(a6)			; OpenWindow, already centered
	move.l	d0,g2p96_req_custom_window
	beq	.g2p96_req_custom_window_ready
	; Use the real Intuition border/title dimensions. All custom drawing and
	; hit testing below uses client coordinates and therefore remains correct
	; with different Workbench title fonts and border preferences.
	move.l	d0,a0
	moveq	#0,d1
	move.b	54(a0),d1			; Window.BorderLeft
	moveq	#0,d2
	move.b	56(a0),d2			; Window.BorderRight
	moveq	#0,d3
	move	8(a0),d3			; Window.Width
	sub	d1,d3
	sub	d2,d3
	sub	#G2P96_REQ_CONTENT_W,d3
	asr	#1,d3
	bpl.s	.g2p96_req_custom_content_x_ok
	moveq	#0,d3
.g2p96_req_custom_content_x_ok
	add	d3,d1
	move	d1,g2p96_req_custom_origin_x
	moveq	#0,d1
	move.b	55(a0),d1			; Window.BorderTop
	addq	#2,d1
	move	d1,g2p96_req_custom_origin_y

	; Force the requester body to the classic fixed-width Topaz 8 font.
	; The real Intuition title bar deliberately keeps the public-screen font.
	move.l	g2p96_req_custom_grbase,a6
	lea	g2p96_req_custom_textattr,a0
	jsr	-72(a6)			; OpenFont
	move.l	d0,g2p96_req_custom_font
	beq.s	.g2p96_req_custom_window_ready
	move.l	d0,a0
	move.l	g2p96_req_custom_window,a1
	move.l	50(a1),a1			; Window.RPort
	jsr	-66(a6)			; SetFont
.g2p96_req_custom_window_ready

	; The open visitor window now keeps the public screen alive.
	move.l	g2p96_req_custom_intbase,a6
	suba.l	a0,a0
	move.l	g2p96_req_custom_screen,a1
	jsr	-516(a6)			; UnlockPubScreen(NULL,screen)
	clr.l	g2p96_req_custom_screen
	tst.l	g2p96_req_custom_window
	beq.w	.g2p96_req_custom_fallback_easy

	jsr	g2rc4_p96_req_custom_draw_v21
	jsr	g2rc4_p96_req_custom_wait_v21
	move	d0,g2p96_req_custom_result
	jsr	g2p96_req_custom_drain	; reply anything already queued before CloseWindow
	bra.s	.g2p96_req_custom_cleanup

.g2p96_req_custom_fallback_easy
	; Extremely defensive fallback for missing V36 public-screen support or an
	; allocation failure. Normal supported systems never enter this path.
	move.l	g2p96_req_custom_screen,d0
	beq.s	.g2p96_req_custom_fallback_no_unlock
	move.l	g2p96_req_custom_intbase,a6
	suba.l	a0,a0
	move.l	d0,a1
	jsr	-516(a6)
	clr.l	g2p96_req_custom_screen
.g2p96_req_custom_fallback_no_unlock
	move.l	g2p96_req_custom_intbase,d0
	beq.s	.g2p96_req_custom_cancel
	move.l	d0,a6
	suba.l	a0,a0
	lea	g2p96_req_easystruct,a1
	suba.l	a2,a2
	suba.l	a3,a3
	jsr	-588(a6)			; EasyRequestArgs fallback only
	move	d0,g2p96_req_custom_result
	bra.s	.g2p96_req_custom_cleanup

.g2p96_req_custom_cancel
	clr	g2p96_req_custom_result

.g2p96_req_custom_cleanup
	move.l	g2p96_req_custom_window,d0
	beq.s	.g2p96_req_custom_no_window
	move.l	d0,a0
	move.l	g2p96_req_custom_intbase,a6
	jsr	-72(a6)			; CloseWindow
	clr.l	g2p96_req_custom_window
.g2p96_req_custom_no_window
	move.l	g2p96_req_custom_font,d0
	beq.s	.g2p96_req_custom_no_font
	move.l	d0,a1
	move.l	g2p96_req_custom_grbase,a6
	jsr	-78(a6)			; CloseFont
	clr.l	g2p96_req_custom_font
.g2p96_req_custom_no_font
	move.l	g2p96_req_custom_grbase,d0
	beq.s	.g2p96_req_custom_no_graphics
	move.l	d0,a1
	move.l	4.w,a6
	jsr	-414(a6)			; CloseLibrary graphics
	clr.l	g2p96_req_custom_grbase
.g2p96_req_custom_no_graphics
	move.l	g2p96_req_custom_intbase,d0
	beq.s	.g2p96_req_custom_no_intuition
	move.l	d0,a1
	move.l	4.w,a6
	jsr	-414(a6)			; CloseLibrary intuition
	clr.l	g2p96_req_custom_intbase
.g2p96_req_custom_no_intuition

	moveq	#0,d0
	move	g2p96_req_custom_result,d0
	tst.l	d0
	beq.s	.g2p96_req_resolution_cancel
	cmp	g2p96_req_display_count,d0
	bls.s	.g2p96_req_resolution_candidate
	move	g2p96_req_display_count,d1
	addq	#1,d1
	cmp	d1,d0
	bne.s	.g2p96_req_resolution_cancel
	moveq	#-1,d0		;c87b70b: Use AGA
	bra.s	.g2p96_req_resolution_done
.g2p96_req_resolution_candidate
	subq	#1,d0
	lea	g2p96_req_map,a0
	moveq	#0,d1
	move.b	0(a0,d0.w),d1
	move	d1,d0
	addq	#1,d0
	bra.s	.g2p96_req_resolution_done
.g2p96_req_resolution_cancel
	moveq	#0,d0
.g2p96_req_resolution_done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; Keep the window at its six-mode maximum height and anchor the footer/actions
; to the six-row position. If fewer modes are available, the unused space stays
; between the last visible mode button and the three-line explanatory footer,
; while the lower margin remains identical on every machine.
g2p96_req_custom_calc_layout
	movem.l	d0-d2,-(a7)
	move	#G2P96_REQ_FIXED_FOOTER1_BASE,g2p96_req_custom_footer1_base
	move	#G2P96_REQ_FIXED_FOOTER2_BASE,g2p96_req_custom_footer2_base
	move	#G2P96_REQ_FIXED_FOOTER3_BASE,g2p96_req_custom_footer3_base
	move	#G2P96_REQ_FIXED_ACTION_Y,g2p96_req_custom_action_y
	movem.l	(a7)+,d0-d2
	rts

; Reply every already queued IDCMP message before CloseWindow.
g2p96_req_custom_drain
	movem.l	d0-d2/a0-a2/a6,-(a7)
	move.l	g2p96_req_custom_window,d0
	beq.w	.done
	move.l	d0,a0
	move.l	86(a0),d0
	beq.w	.done
	move.l	d0,a2
.loop
	move.l	a2,a0
	move.l	4.w,a6
	jsr	-372(a6)			; GetMsg
	tst.l	d0
	beq.w	.done
	move.l	d0,a1
	move.l	4.w,a6
	jsr	-378(a6)			; ReplyMsg
	bra.s	.loop
.done
	movem.l	(a7)+,d0-d2/a0-a2/a6
	rts

; Draw the pre-centered native stage-1 chooser into its public-screen window.
g2p96_req_custom_draw
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	g2p96_req_custom_window,d0
	beq.w	.done
	move.l	d0,a0
	move.l	50(a0),a1			; Window.RPort
	move.l	g2p96_req_custom_grbase,a6
	moveq	#G2P96_REQ_PEN_BG,d0
	jsr	-348(a6)			; SetBPen
	moveq	#0,d0
	jsr	-354(a6)			; SetDrMd(JAM1)

	; Intuition draws the real border and title bar. Fill only the client body.
	moveq	#0,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W-1,d2
	move	#G2P96_REQ_CONTENT_H-1,d3
	moveq	#G2P96_REQ_PEN_BG,d4
	jsr	g2p96_req_custom_rect

	; Compact information panel with a complete one-pixel dark outline.
	; c87b70s retains the complete one-pixel information-panel border and white body.
	moveq	#5,d0
	moveq	#2,d1
	move	#G2P96_REQ_CONTENT_W-6,d2
	moveq	#25,d3
	moveq	#G2P96_REQ_PEN_SHADOW,d4
	jsr	g2p96_req_custom_rect
	moveq	#6,d0
	moveq	#3,d1
	move	#G2P96_REQ_CONTENT_W-7,d2
	moveq	#24,d3
	moveq	#G2P96_REQ_PEN_HILITE,d4	; c87b70s: white information-panel background
	jsr	g2p96_req_custom_rect
	lea	g2p96_req_custom_warning1,a0
	move	#g2p96_req_custom_warning1_len,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W,d2
	moveq	#11,d3
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center
	lea	g2p96_req_custom_warning2,a0
	move	#g2p96_req_custom_warning2_len,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W,d2
	moveq	#21,d3
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center
	lea	g2p96_req_custom_select,a0
	move	#g2p96_req_custom_select_len,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W,d2
	move	#G2P96_REQ_SELECT_BASE,d3
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center

	; One full-width mode button per row. Labels are deliberately left aligned.
	moveq	#0,d6
	move	g2p96_req_display_count,d7
	subq	#1,d7
	bmi.s	.buttons_done
.buttons_loop
	moveq	#G2P96_REQ_MODE_X,d0
	move	d6,d1
	mulu	#G2P96_REQ_MODE_STEP,d1
	add	#G2P96_REQ_MODE_Y,d1
	lea	g2p96_req_map,a0
	moveq	#0,d2
	move.b	0(a0,d6.w),d2		; candidate index
	lea	g2p96_req_custom_label_ptrs,a0
	move.l	0(a0,d2*4),a1
	lea	g2p96_req_custom_label_lens,a0
	move	0(a0,d2*2),d2
	move.l	a1,a0
	jsr	g2p96_req_custom_button
	addq	#1,d6
	dbf	d7,.buttons_loop
.buttons_done

	; Footer is fixed below the maximum six-row mode area. Fewer modes leave space above it.
	lea	g2p96_req_custom_footer1,a0
	move	#g2p96_req_custom_footer1_len,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W,d2
	move	g2p96_req_custom_footer1_base,d3
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center
	lea	g2p96_req_custom_footer2,a0
	move	#g2p96_req_custom_footer2_len,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W,d2
	move	g2p96_req_custom_footer2_base,d3
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center
	lea	g2p96_req_custom_footer3,a0
	move	#g2p96_req_custom_footer3_len,d0
	moveq	#0,d1
	move	#G2P96_REQ_CONTENT_W,d2
	move	g2p96_req_custom_footer3_base,d3
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center

	; Only AGA/CANCEL remain below the final three-line footer block.
	move	#44,d0
	move	g2p96_req_custom_action_y,d1
	lea	g2p96_req_aga,a0
	move	#G2P96_REQ_AGA_LEN,d2
	jsr	g2p96_req_custom_button_100
	move	#156,d0
	move	g2p96_req_custom_action_y,d1
	lea	g2p96_req_cancel,a0
	move	#G2P96_REQ_CANCEL_LEN,d2
	jsr	g2p96_req_custom_button_100
.done
	movem.l	(a7)+,d0-d7/a0-a6
	rts

; Wait for a mouse click or raw key. Return EasyRequester-compatible value:
; 1..N=displayed mode, N+1=Use AGA, 0=CANCEL.
g2p96_req_custom_wait
	movem.l	d1-d7/a0-a6,-(a7)
.wait
	move.l	g2p96_req_custom_window,a0
	move.l	86(a0),a0			; Window.UserPort
	move.l	4.w,a6
	jsr	-384(a6)			; WaitPort
.drain
	move.l	g2p96_req_custom_window,a0
	move.l	86(a0),a0
	move.l	4.w,a6
	jsr	-372(a6)			; GetMsg
	tst.l	d0
	beq.s	.wait
	move.l	d0,a2
	move.l	20(a2),d4			; IntuiMessage.Class
	moveq	#0,d5
	move	24(a2),d5			; Code
	moveq	#0,d6
	move	32(a2),d6			; MouseX
	moveq	#0,d7
	move	34(a2),d7			; MouseY
	move.l	a2,a1
	move.l	4.w,a6
	jsr	-378(a6)			; ReplyMsg
	cmp.l	#$00000008,d4		; IDCMP_MOUSEBUTTONS
	beq.s	.mouse
	cmp.l	#$00000400,d4		; IDCMP_RAWKEY
	beq.s	.key
	bra.s	.drain
.mouse
	cmp	#$0068,d5			; SELECTDOWN
	bne.s	.drain
	move	d6,d0
	move	d7,d1
	jsr	g2p96_req_custom_hit
	cmp	#-1,d0
	beq.s	.drain
	bra.s	.done
.key
	btst	#7,d5			; ignore key-up messages
	bne.s	.drain
	and	#$007f,d5
	cmp	#$45,d5			; ESC = CANCEL
	beq.s	.cancel
	cmp	#$33,d5			; C = CANCEL
	beq.s	.cancel
	cmp	#$20,d5			; A = Use AGA
	beq.s	.use_aga
	cmp	#1,d5
	bcs	.drain
	cmp	#6,d5
	bhi	.drain
	cmp	g2p96_req_display_count,d5
	bhi	.drain
	move	d5,d0
	bra.s	.done
.use_aga
	moveq	#0,d0
	move	g2p96_req_display_count,d0
	addq	#1,d0
	bra.s	.done
.cancel
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

; d0=x, d1=y. Return -1=no hit, 0=CANCEL, positive Easy-style value.
g2p96_req_custom_hit
	movem.l	d1-d5,-(a7)
	move	d0,d2
	move	d1,d3
	sub	g2p96_req_custom_origin_x,d2
	sub	g2p96_req_custom_origin_y,d3
	moveq	#-1,d0
	; Bottom AGA/CANCEL actions.
	move	g2p96_req_custom_action_y,d4
	cmp	d4,d3
	blt.s	.mode_list
	add	#22,d4
	cmp	d4,d3
	bge	.done
	cmp	#44,d2
	blt	.done
	cmp	#144,d2
	blt.s	.use_aga
	cmp	#156,d2
	blt	.done
	cmp	#256,d2
	bge	.done
	moveq	#0,d0			; CANCEL
	bra	.done
.use_aga
	moveq	#0,d0
	move	g2p96_req_display_count,d0
	addq	#1,d0
	bra	.done
.mode_list
	cmp	#G2P96_REQ_MODE_X,d2
	blt	.done
	cmp	#G2P96_REQ_MODE_X+G2P96_REQ_MODE_W,d2
	bge	.done
	cmp	#G2P96_REQ_MODE_Y,d3
	blt	.done
	move	d3,d4
	sub	#G2P96_REQ_MODE_Y,d4
	moveq	#0,d5			; visible row
.row_loop
	cmp	#G2P96_REQ_MODE_H,d4
	bcs.s	.row_hit
	sub	#G2P96_REQ_MODE_STEP,d4
	bmi	.done			; click in the vertical gap
	addq	#1,d5
	cmp	#6,d5
	bcs.s	.row_loop
	bra	.done
.row_hit
	cmp	g2p96_req_display_count,d5
	bcc	.done
	move	d5,d0
	addq	#1,d0
.done
	movem.l	(a7)+,d1-d5
	rts

; d0=x, d1=y, a0=label, d2=label length; full-width beveled button.
g2p96_req_custom_button
	movem.l	d0-d7/a0-a2,-(a7)
	move	d0,d5
	move	d1,d6
	move.l	a0,a2
	move	d2,d7
	move	d5,d0
	move	d6,d1
	move	d5,d2
	add	#G2P96_REQ_MODE_W-1,d2
	move	d6,d3
	add	#G2P96_REQ_MODE_H-1,d3
	moveq	#G2P96_REQ_PEN_SHADOW,d4
	jsr	g2p96_req_custom_rect
	move	d5,d0
	addq	#1,d0
	move	d6,d1
	addq	#1,d1
	move	d5,d2
	add	#G2P96_REQ_MODE_W-2,d2
	move	d6,d3
	add	#G2P96_REQ_MODE_H-2,d3
	moveq	#G2P96_REQ_PEN_BG,d4
	jsr	g2p96_req_custom_rect
	move	d5,d0
	move	d6,d1
	move	d5,d2
	add	#G2P96_REQ_MODE_W-2,d2
	move	d6,d3
	moveq	#G2P96_REQ_PEN_HILITE,d4
	jsr	g2p96_req_custom_rect
	move	d5,d0
	move	d6,d1
	move	d5,d2
	move	d6,d3
	add	#G2P96_REQ_MODE_H-2,d3
	moveq	#G2P96_REQ_PEN_HILITE,d4
	jsr	g2p96_req_custom_rect
	move.l	a2,a0
	move	d7,d0
	move	d5,d1
	add	#12,d1			; left-aligned label inset
	move	d6,d2
	add	#G2P96_REQ_MODE_TEXT_BASE,d2	; vertically centered Topaz 8 baseline
	moveq	#G2P96_REQ_PEN_TEXT,d3
	jsr	g2p96_req_custom_text
	movem.l	(a7)+,d0-d7/a0-a2
	rts

; d0=x, d1=y, a0=label, d2=label length; 100x22 beveled button.
g2p96_req_custom_button_100
	movem.l	d0-d7/a0-a2,-(a7)
	move	d0,d5
	move	d1,d6
	move.l	a0,a2
	move	d2,d7
	move	d5,d0
	move	d6,d1
	move	d5,d2
	add	#99,d2
	move	d6,d3
	add	#21,d3
	moveq	#G2P96_REQ_PEN_SHADOW,d4
	jsr	g2p96_req_custom_rect
	move	d5,d0
	addq	#1,d0
	move	d6,d1
	addq	#1,d1
	move	d5,d2
	add	#98,d2
	move	d6,d3
	add	#20,d3
	moveq	#G2P96_REQ_PEN_BG,d4
	jsr	g2p96_req_custom_rect
	move	d5,d0
	move	d6,d1
	move	d5,d2
	add	#98,d2
	move	d6,d3
	moveq	#G2P96_REQ_PEN_HILITE,d4
	jsr	g2p96_req_custom_rect
	move	d5,d0
	move	d6,d1
	move	d5,d2
	move	d6,d3
	add	#20,d3
	moveq	#G2P96_REQ_PEN_HILITE,d4
	jsr	g2p96_req_custom_rect
	move.l	a2,a0
	move	d7,d0
	move	d5,d1
	move	#100,d2
	move	d6,d3
	add	#G2P96_REQ_ACTION_TEXT_BASE,d3	; vertically centered Topaz 8 baseline
	moveq	#G2P96_REQ_PEN_TEXT,d4
	jsr	g2p96_req_custom_text_center
	movem.l	(a7)+,d0-d7/a0-a2
	rts

; Font-aware horizontal centering.
; a0=text,d0=len,d1=left,d2=available width,d3=baseline,d4=pen.
g2p96_req_custom_text_center
	movem.l	d0-d7/a0-a3/a6,-(a7)
	move.l	a0,a2
	move	d0,d5
	move	d1,d6
	move	d2,d7
	move.l	g2p96_req_custom_window,a0
	move.l	50(a0),a1			; RastPort
	move.l	a2,a0
	move	d5,d0
	move.l	g2p96_req_custom_grbase,a6
	jsr	-54(a6)			; TextLength
	move	d7,d1
	sub	d0,d1
	asr	#1,d1
	add	d6,d1
	move.l	a2,a0
	move	d5,d0
	move	d3,d2
	move	d4,d3
	jsr	g2p96_req_custom_text
	movem.l	(a7)+,d0-d7/a0-a3/a6
	rts

; d0=x1,d1=y1,d2=x2,d3=y2,d4=pen.
g2p96_req_custom_rect
	movem.l	d0-d7/a0-a2/a6,-(a7)
	add	g2p96_req_custom_origin_x,d0
	add	g2p96_req_custom_origin_y,d1
	add	g2p96_req_custom_origin_x,d2
	add	g2p96_req_custom_origin_y,d3
	move	d0,d5
	move	d1,d6
	move	d2,d7
	move.l	g2p96_req_custom_window,a0
	move.l	50(a0),a1
	move.l	g2p96_req_custom_grbase,a6
	move	d4,d0
	jsr	-342(a6)			; SetAPen (d2-d7 preserved)
	move	d5,d0
	move	d6,d1
	move	d7,d2
	jsr	-306(a6)			; RectFill, original d3 still holds y2
	movem.l	(a7)+,d0-d7/a0-a2/a6
	rts

; a0=text,d0=len,d1=x,d2=baseline y,d3=pen.
g2p96_req_custom_text
	movem.l	d0-d7/a0-a2/a6,-(a7)
	move.l	a0,a2
	move	d0,d4
	add	g2p96_req_custom_origin_x,d1
	add	g2p96_req_custom_origin_y,d2
	move	d1,d5
	move	d2,d6
	move	d3,d7
	move.l	g2p96_req_custom_window,a0
	move.l	50(a0),a1
	move.l	g2p96_req_custom_grbase,a6
	move	d7,d0
	jsr	-342(a6)			; SetAPen
	move	d5,d0
	move	d6,d1
	jsr	-240(a6)			; Move
	move.l	a2,a0
	move	d4,d0
	move.l	g2p96_req_custom_window,a1
	move.l	50(a1),a1
	move.l	g2p96_req_custom_grbase,a6
	jsr	-60(a6)			; Text
	movem.l	(a7)+,d0-d7/a0-a2/a6
	rts

; c87b70s: classic native pre-centered first P96 chooser state and layout.
G2P96_REQ_PEN_BG	equ	0
G2P96_REQ_PEN_TEXT	equ	1
G2P96_REQ_PEN_SHADOW	equ	1
G2P96_REQ_PEN_HILITE	equ	2
G2P96_REQ_PEN_ACCENT	equ	3
G2P96_REQ_AGA_LEN	equ	3
G2P96_REQ_CANCEL_LEN	equ	6
G2P96_REQ_OK_LEN	equ	2
G2P96_REQ_WIN_W	equ	320
G2P96_REQ_WIN_H	equ	256
G2P96_REQ_CONTENT_W	equ	300
G2P96_REQ_CONTENT_H	equ	224
G2P96_REQ_MODE_X	equ	12
G2P96_REQ_MODE_Y	equ	50
G2P96_REQ_MODE_W	equ	276
G2P96_REQ_MODE_H	equ	16
G2P96_REQ_MODE_STEP	equ	18
; Topaz 8 body metrics. The window stays at the maximum six-mode height.
; The explanatory footer and AGA/CANCEL are anchored after six rows, so any
; unused-mode space remains above the footer. The third line contains the
; requested ellipsis and the action buttons remain inside the fixed client.
G2P96_REQ_FONT_H	equ	8
G2P96_REQ_FONT_BASELINE	equ	6
G2P96_REQ_LINE_GAP	equ	8
G2P96_REQ_SELECT_BASE	equ	40
G2P96_REQ_FOOTER_LINE_STEP	equ	10
G2P96_REQ_MODE_TEXT_BASE	equ	10
G2P96_REQ_ACTION_TEXT_BASE	equ	13
G2P96_REQ_MAX_MODES	equ	6
; Fixed six-row geometry: three footer baselines 166/176/186, action top 196.
; This keeps the complete requested sentence inside the 300-pixel Topaz-8 client.
G2P96_REQ_FIXED_FOOTER1_BASE	equ	166
G2P96_REQ_FIXED_FOOTER2_BASE	equ	176
G2P96_REQ_FIXED_FOOTER3_BASE	equ	186
G2P96_REQ_FIXED_ACTION_Y	equ	196

g2p96_req_custom_result	dc.w	0
g2p96_req_custom_window	dc.l	0
g2p96_req_custom_screen	dc.l	0
g2p96_req_custom_intbase	dc.l	0
g2p96_req_custom_grbase	dc.l	0
g2p96_req_custom_font	dc.l	0
g2p96_req_custom_origin_x	dc.w	0
g2p96_req_custom_origin_y	dc.w	0
g2p96_req_custom_footer1_base	dc.w	0
g2p96_req_custom_footer2_base	dc.w	0
g2p96_req_custom_footer3_base	dc.w	0
g2p96_req_custom_action_y	dc.w	0

g2p96_req_custom_newwindow
	dc.w	0,0			; LeftEdge,TopEdge patched before OpenWindow
	dc.w	G2P96_REQ_WIN_W,G2P96_REQ_WIN_H
	dc.b	0,1			; DetailPen,BlockPen
	dc.l	$0000040c		; IDCMP_RAWKEY|IDCMP_MOUSEBUTTONS|IDCMP_REFRESHWINDOW
	dc.l	$00011046		; ACTIVATE|RMBTRAP|SIMPLE_REFRESH|WINDOWDRAG|WINDOWDEPTH
	dc.l	0			; FirstGadget
	dc.l	0			; CheckMark
	dc.l	g2rc4_req_title_v22	; real classic Intuition title bar
	dc.l	0			; Screen patched from LockPubScreen
	dc.l	0			; BitMap
	dc.w	-1,-1,-1,-1		; Min/Max
	dc.w	15			; CUSTOMSCREEN visitor window

	even
g2p96_req_graphics_name	dc.b	'graphics.library',0
g2p96_req_custom_topaz_name	dc.b	'topaz.font',0
	even
g2p96_req_custom_textattr
	dc.l	g2p96_req_custom_topaz_name
	dc.w	8
	dc.b	0,0			; normal style, fixed Topaz 8 body font
	even

g2p96_req_custom_title	dc.b	'Gloom Reforged P96'
g2p96_req_custom_title_end
g2p96_req_custom_title_len	equ	g2p96_req_custom_title_end-g2p96_req_custom_title

g2p96_req_custom_warning1	dc.b	'Gloom Reforged v2.0'
g2p96_req_custom_warning1_end
g2p96_req_custom_warning1_len	equ	g2p96_req_custom_warning1_end-g2p96_req_custom_warning1
	dcb.b	10,0			; preserve established binary spacing

g2p96_req_custom_warning2	dc.b	'Direct 8-Bit CLUT P96'
g2p96_req_custom_warning2_end
g2p96_req_custom_warning2_len	equ	g2p96_req_custom_warning2_end-g2p96_req_custom_warning2
	dcb.b	14,0			; preserve established binary spacing

g2p96_req_custom_select	dc.b	'Select a Screenmode and Options'
g2p96_req_custom_select_end
g2p96_req_custom_select_len	equ	g2p96_req_custom_select_end-g2p96_req_custom_select
	dcb.b	4,0			; preserve established binary spacing

g2p96_req_custom_footer1	dc.b	'The following requester shows'
g2p96_req_custom_footer1_end
g2p96_req_custom_footer1_len	equ	g2p96_req_custom_footer1_end-g2p96_req_custom_footer1

g2p96_req_custom_footer2	dc.b	'the exact matching 8-bit CLUT P96'
g2p96_req_custom_footer2_end
g2p96_req_custom_footer2_len	equ	g2p96_req_custom_footer2_end-g2p96_req_custom_footer2

g2p96_req_custom_footer3	dc.b	'screen modes...'
g2p96_req_custom_footer3_end
g2p96_req_custom_footer3_len	equ	g2p96_req_custom_footer3_end-g2p96_req_custom_footer3

	even
g2p96_req_custom_label_ptrs
	dc.l	g2p96_req_custom_l0,g2p96_req_custom_l1,g2p96_req_custom_l2
	dc.l	g2p96_req_custom_l3,g2p96_req_custom_l4,g2p96_req_custom_l5
g2p96_req_custom_label_lens
	dc.w	g2p96_req_custom_l0_len,g2p96_req_custom_l1_len
	dc.w	g2p96_req_custom_l2_len,g2p96_req_custom_l3_len
	dc.w	g2p96_req_custom_l4_len,g2p96_req_custom_l5_len

g2p96_req_custom_l0	dc.b	'320x240, Standard'
g2p96_req_custom_l0_end
g2p96_req_custom_l0_len	equ	g2p96_req_custom_l0_end-g2p96_req_custom_l0
g2p96_req_custom_l1	dc.b	'320x256, 5:4'
g2p96_req_custom_l1_end
g2p96_req_custom_l1_len	equ	g2p96_req_custom_l1_end-g2p96_req_custom_l1
g2p96_req_custom_l2	dc.b	'428x240, Widescreen'
g2p96_req_custom_l2_end
g2p96_req_custom_l2_len	equ	g2p96_req_custom_l2_end-g2p96_req_custom_l2
g2p96_req_custom_l3	dc.b	'640x480, Standard HiRes'
g2p96_req_custom_l3_end
g2p96_req_custom_l3_len	equ	g2p96_req_custom_l3_end-g2p96_req_custom_l3
g2p96_req_custom_l4	dc.b	'640x512, 5:4 HiRes'
g2p96_req_custom_l4_end
g2p96_req_custom_l4_len	equ	g2p96_req_custom_l4_end-g2p96_req_custom_l4
g2p96_req_custom_l5	dc.b	'854x480, Widescreen HiRes'
g2p96_req_custom_l5_end
g2p96_req_custom_l5_len	equ	g2p96_req_custom_l5_end-g2p96_req_custom_l5

	even

	even


; -----------------------------------------------------------------------------
; c87b79x: DISPLAY=P96 direct-index source backend and hard presenter gate.
;
; P96 no longer allocates or swaps the two compact planar bitmaps. Static pages,
; menus and intermission text are authoritative in direct index/CLUT caches.
; g2display_mode=2 is the single source of truth for this ownership.
; -----------------------------------------------------------------------------
	even

; Called after the native AGA/ECS/OS backend selection. DISPLAY=P96 routes the
; generic db endpoint here before any planar pointer is read. Palette transactions are noted
; before topokepal dispatch, so the P96 source endpoint also performs no hardware
; programming.
g2p96_select_source_backend_c87b79n
	cmp	#2,g2display_mode
	bne.w	.done
	tst	os
	beq.w	.done
	lea	db_p96_source,a0
	lea	pokepal_p96_source,a1
.done	rts

; The persistent title/game P96 screen is the only real display validation.
; c87b79o: a selected P96 mode is now an explicit P96-or-exit contract.  A
; failure never opens db_os, an AGA screen or an ECS screen behind the user.
g2p96_validate_persistent_screen_c87b79o
	moveq	#0,d0
	tst	p96gameplay_persist_active
	bne.w	.done
	jsr	g2p96_abort_open_failure_c87b79o
	moveq	#-1,d0
.done	rts

; One-shot fatal P96 open handler.  It may be called after a failed title,
; intermission or gameplay persistent open.  Partial P96 resources are closed,
; a public-screen requester explains the failure, and the normal top-level code
; exits through exittoos.  Native AGA/ECS dispatch pointers are never selected.
g2p96_abort_open_failure_c87b79o
	movem.l	d0-d3/a0-a3/a6,-(a7)
	cmp	#2,g2display_mode
	bne.w	.done
	move	#-1,g2p96_fatal_open_error_c87b79o
	jsr	g2p96_gameplay_persistent_close
	tst	g2p96_fatal_notice_shown_c87b79o
	bne.w	.done
	move	#-1,g2p96_fatal_notice_shown_c87b79o
	lea	g2p96_open_failed_easy_c87b79o,a1
	jsr	g2p96_req_show_easy_a1
.done
	movem.l	(a7)+,d0-d3/a0-a3/a6
	rts

	even
g2p96_fatal_open_error_c87b79o	dc.w	0
g2p96_fatal_notice_shown_c87b79o	dc.w	0
	even

g2p96_open_failed_easy_c87b79o
	dc.l	20,0
	dc.l	g2p96_req_title
	dc.l	g2p96_open_failed_body_c87b79o
	dc.l	g2p96_req_ok

g2p96_open_failed_body_c87b79o
	dc.b	'The selected 8-bit CLUT P96 screen could not be opened.',10,10
	dc.b	'Gloom Reforged will exit instead of switching',10
	dc.b	'to a native AGA or ECS display.',0
	even

; Generic db reaches this endpoint before any native bitmap swap. The P96
; presenters consume direct chunky/index sources themselves, so this endpoint
; intentionally performs no planar operation.
db_p96_source
	rts

; pokepal/pokepal2 already registered the palette transaction and stored lastpal.
; The active P96 CLUT owner installs it through its own LoadRGB32 path.
pokepal_p96_source
	rts


; -----------------------------------------------------------------------------
; c87b70l - optional exact P96 ModeID override
;
; Accepted case-insensitively from a Workbench ToolType or the CLI:
;   P96MODEID=$12345678
;   P96MODEID=12345678
;
; The value is only trusted after all six exact supported geometries and the
; complete direct 8-bit CLUT contract have been validated through P96 attributes.
; -----------------------------------------------------------------------------
g2p96_modeid_override_present	dc.w	0
g2p96_modeid_override_valid	dc.w	0
g2p96_modeid_override_used	dc.w	0
g2p96_modeid_override_source	dc.w	0
g2p96_modeid_override_value	dc.l	0
g2tok_p96modeid_prefix	dc.b	'P96MODEID='
	even

; a2=token start, d6=token length, d7=source. d0=-1 when the prefix was
; consumed (valid or malformed), zero when this is a different token.
g2tok_try_p96modeid
	movem.l	d1-d5/a0-a4,-(a7)
	moveq	#0,d0
	cmp	#10,d6
	bcs.w	.not_token
	move.l	a2,a3
	lea	g2tok_p96modeid_prefix,a4
	moveq	#9,d5
.prefix_loop
	move.b	(a3)+,d0
	jsr	g2display_upper_d0
	cmp.b	(a4)+,d0
	bne.w	.not_token
	dbf	d5,.prefix_loop
	move	#-1,g2p96_modeid_override_present
	clr	g2p96_modeid_override_valid
	clr	g2p96_modeid_override_used
	move	d7,g2p96_modeid_override_source
	clr.l	g2p96_modeid_override_value
	move	d6,d4
	sub	#10,d4
	cmp	#8,d4
	beq	.have_digits
	cmp	#9,d4
	bne	.consumed
	cmp.b	#'$',(a3)+
	bne	.consumed
.have_digits
	moveq	#0,d4
	moveq	#7,d5
.hex_loop
	moveq	#0,d0
	move.b	(a3)+,d0
	jsr	g2display_upper_d0
	cmp.b	#'0',d0
	bcs	.consumed
	cmp.b	#'9',d0
	bls	.hex_decimal
	cmp.b	#'A',d0
	bcs	.consumed
	cmp.b	#'F',d0
	bhi	.consumed
	sub.b	#55,d0
	bra	.hex_merge
.hex_decimal
	sub.b	#'0',d0
.hex_merge
	lsl.l	#4,d4
	or.b	d0,d4
	dbf	d5,.hex_loop
	move.l	d4,g2p96_modeid_override_value
	move	#-1,g2p96_modeid_override_valid
.consumed
	moveq	#-1,d0
	bra	.done
.not_token
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d5/a0-a4
	rts

; Return the validated ModeID in d0.l or zero. The geometry is derived only
; from P96 attributes; the user-configurable Base portion is never interpreted.
g2p96_modeid_override_validate
	movem.l	d1-d7/a0-a2/a6,-(a7)
	moveq	#0,d0
	tst	g2p96_modeid_override_valid
	beq.w	.fail
	move.l	g2p96_modeid_override_value,d7
	beq.w	.fail
	cmp.l	#P96_INVALID_ID,d7
	beq.w	.fail
	move.l	p96base,d0
	beq.w	.fail
	move.l	d0,a6
	move.l	d7,d0
	moveq	#P96IDA_WIDTH,d1
	jsr	-84(a6)
	and.l	#$0000ffff,d0
	move	d0,d4
	move.l	d7,d0
	moveq	#P96IDA_HEIGHT,d1
	jsr	-84(a6)
	and.l	#$0000ffff,d0
	move	d0,d5
	cmp	#320,d4
	bne	.not_320
	cmp	#240,d5
	beq	.c0
	cmp	#256,d5
	beq	.c1
	bra.w	.fail
.not_320
	cmp	#428,d4
	bne	.not_428
	cmp	#240,d5
	beq	.c2
	bra.w	.fail
.not_428
	cmp	#640,d4
	bne	.not_640
	cmp	#480,d5
	beq	.c3
	cmp	#512,d5
	beq	.c4
	bra.w	.fail
.not_640
	cmp	#854,d4
	bne.w	.fail
	cmp	#480,d5
	bne.w	.fail
	moveq	#5,d0
	bra	.apply
.c0	moveq	#0,d0
	bra	.apply
.c1	moveq	#1,d0
	bra	.apply
.c2	moveq	#2,d0
	bra	.apply
.c3	moveq	#3,d0
	bra	.apply
.c4	moveq	#4,d0
.apply
	jsr	g2p96_req_apply_candidate
	move.l	d7,d0
	jsr	g2p96_req_validate_current
	tst.l	d0
	beq	.fail
	move	#-1,g2p96_modeid_override_used
	move.l	d7,d0
	bra	.done
.fail
	clr	g2p96_modeid_override_used
	moveq	#0,d0
.done
	movem.l	(a7)+,d1-d7/a0-a2/a6
	rts

; Prominent duplicate at the beginning of RAM:gloom_basic.log.
g2basic_p96modeid_tooltype_block
	dc.b	'--- P96 MODE ID / COPY THIS TOOLTYPE ---',10
	dc.b	'P96MODEID=$'
g2basic_p96modeid_tooltype_hex	ds.b	8
	dc.b	10
	dc.b	'Use this exact line to skip both P96 requesters.',10,10
g2basic_p96modeid_tooltype_block_end
g2basic_p96modeid_tooltype_block_len	equ	g2basic_p96modeid_tooltype_block_end-g2basic_p96modeid_tooltype_block
	even

