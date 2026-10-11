; Fixed tables are validated when acquired, not in colour conversion loops.
g2require_asset_bytes	; a0=resource, d1=minimum logical bytes; preserves inputs
	movem.l d0-d7/a0-a6,-(a7)
	move.l d1,d7
	jsr g2asset_bounds
	cmp.l d7,d0
	bcs.s .bad
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2require_picture_palette	; a0=picture, a1=palette; preserves inputs
	movem.l d0-d7/a0-a6,-(a7)
	move.l a0,d0
	beq.w .done	; no picture means no palette consumer at this call site
	move.l a1,d0
	beq.s .bad
	move.l a1,a2
	jsr g2validate_iff
	tst.l d0
	bne.s .bad
	moveq #0,d0
	move.w 4(a0),d0
	moveq #1,d1
	lsl.l d0,d1
	move.l #256,d2
	tst.w aga
	bne.s .count
	moveq #32,d2
.count
	cmp.l d2,d1
	bls.s .bytes
	move.l d2,d1
.bytes
	add.l d1,d1	; ECS consumes one word per base colour
	tst.w aga
	beq.s .check
	add.l d1,d1	; AGA/P96 consumes high/low RGB12 word pairs
.check
	move.l a2,a0
	jsr g2require_asset_bytes
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2require_picpal
	movem.l a0-a1,-(a7)
	move.l pic,a0
	move.l picpal,a1
	jsr g2require_picture_palette
	movem.l (a7)+,a0-a1
	rts

g2validate_loaded_slot	; d0=loaded pointer, a3=compile-time destination slot
	movem.l d0-d7/a0-a6,-(a7)
	tst.l d0
	beq.w .done
	move.l d0,a1
	cmp.l #panel,a3
	beq.w .panel
	cmp.l #gunpic,a3
	beq.w .gun
	cmp.l #titlemed,a3
	beq.w .med
	cmp.l #loadingmed,a3
	beq.w .med
	cmp.l #bigfont_,a3
	beq.w .font
	cmp.l #gloombrush,a3
	beq.w .iff
	cmp.l #g2zm_g3dcbrush,a3
	beq.w .iff
	cmp.l #gloom,a3
	beq.w .iff
	cmp.l #magic,a3
	beq.w .iff
	cmp.l #combat,a3
	beq.w .iff
	cmp.l #g2ecs_fast_title_base,a3
	beq.w .iff
	lea g2sfx_resource_slots,a0
.sfx_slot
	move.l (a0)+,d1
	beq.s .other_slot
	cmp.l a3,d1
	bne.s .sfx_slot
	move.l a1,a0
	jsr g2validate_sfx
	tst.l d0
	bne.w .bad
	bra.w .done
.other_slot
	cmp.l #planar_remap,a3
	beq.w .remap
	cmp.l #planar_palette,a3
	beq.w .game_palette
	cmp.l #gloompal,a3
	beq.w .title
	cmp.l #magicpal,a3
	beq.w .magic
	cmp.l #combatpal,a3
	beq.w .combat
	cmp.l #g2ecs_fast_title_base_pal,a3
	beq.w .base_title
	bra.w .done
.remap
	move.l a1,a0
	move.l #4096,d1	; all RGB12 indices are read by calcpalettes/effects
	jsr g2require_asset_bytes
	bra.w .done
.game_palette
	move.l a1,a0
	move.l #256*4,d1
	tst.w aga
	bne.s .fixed
	moveq #32*2,d1
.fixed
	jsr g2require_asset_bytes
	bra.w .done
.title
	move.l gloom,a0
	bra.s .picture
.magic
	move.l magic,a0
	bra.s .picture
.combat
	move.l combat,a0
	bra.s .picture
.base_title
	move.l g2ecs_fast_title_base,a0
.picture
	jsr g2require_picture_palette
	bra.w .done
.panel
	moveq #48,d7	; showstats selects health cells 45..47 and weapon cells 39..43
	bra.s .animation
.gun
	cmp.w #3,g2_game_profile
	bne.s .full_gun
	move.l a1,a0
	jsr g2require_anim
	tst.w an_rotshft(a0)
	bne.s .full_gun
	cmp.w #2,an_frames(a0)
	bne.s .full_gun
	jsr g2prepare_legacy_gun
	move.l d0,(a7)	; return replacement to the loader; slot is updated by helper
	bra.w .done
.full_gun
	moveq #5,d7	; g2drawgun_muzzle selects entries 0..4
.animation
	move.l a1,a0
	jsr g2require_anim
	moveq #0,d0
	move.w an_frames(a0),d0
	move.w an_rotshft(a0),d1
	lsl.l d1,d0
	cmp.l d7,d0
	bcs.w .bad
	bra.w .done
.font
	moveq #40,d7	; printmess2 has glyphs 0..39 in Bigfont2
.shapes
	move.l a1,a0
	jsr g2validate_blit_shapes
	tst.l d0
	bne.s .bad
	bra.w .done
.med
	move.l a1,a0
	jsr g2validate_med
	tst.l d0
	bne.s .bad
	bra.w .done
.iff
	move.l a1,a0
	jsr g2validate_iff
	tst.l d0
	beq.s .done
	; Original Gloom3/ZM artwork can end a ByteRun1 row one byte late.
	; Canonicalise that legacy stream in owned loader memory before use.
	cmp.w #2,g2_game_profile
	beq.s .legacy_iff
	cmp.w #3,g2_game_profile
	bne.s .bad
.legacy_iff
	jsr g2normalize_legacy_iff
	tst.l d0
	bne.s .bad
	jsr g2validate_iff
	tst.l d0
	bne.s .bad
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2require_core_tables	; alternate profile loaders and embedded replacements
	movem.l d0/a3,-(a7)
	lea planar_palette,a3
	move.l (a3),d0
	jsr g2validate_loaded_slot
	lea planar_remap,a3
	move.l (a3),d0
	jsr g2validate_loaded_slot
	lea gloompal,a3
	move.l (a3),d0
	jsr g2validate_loaded_slot
	lea panel,a3
	move.l (a3),d0
	jsr g2validate_loaded_slot
	lea gunpic,a3
	move.l (a3),d0
	jsr g2validate_loaded_slot
	movem.l (a7)+,d0/a3
	rts

; Paula's zero length means 65536 words, not an empty sample.
g2validate_sfx
	movem.l d1-d2/a0-a1,-(a7)
	jsr g2asset_bounds
	cmp.l #4,d0
	bcs.s .bad
	moveq #0,d1
	move.w 2(a0),d1
	bne.s .length
	move.l #65536,d1
.length
	add.l d1,d1
	addq.l #4,d1
	cmp.l d1,d0
	bcs.s .bad
	moveq #0,d0
	bra.w .done
.bad
	moveq #-1,d0
.done
	movem.l (a7)+,d1-d2/a0-a1
	rts

; Blit atlas: palette offset, offset table, per-shape cookie offset,
; source row bytes, BLTSIZE, plane count, image bytes and cookie mask.
; d7=minimum entries required by the actual consumer, not a guessed file size.
g2validate_blit_shapes
	movem.l d1-d7/a0-a6,-(a7)
	move.l a0,a2
	jsr g2asset_bounds
	move.l d0,d6
	move.l a1,a6
	cmp.l #18,d6
	bcs.w .bad
	move.l 4(a2),d5
	cmp.l #8,d5
	bcs.w .bad
	cmp.l d6,d5
	bcc.w .bad
	move.l d5,d0
	subq.l #4,d0
	move.l d0,d1
	and.l #3,d1
	bne.w .bad
	lsr.l #2,d0
	cmp.l d7,d0
	bcs.w .bad
	move.l d0,d7
	move.l (a2),d1
	cmp.l d5,d1
	bcs.w .bad
	cmp.l d6,d1
	bcc.w .bad
	lea 0(a2,d1.l),a0
	jsr g2validate_palette
	tst.l d0
	bne.w .bad
	cmp.w #3,(a0)	; initfontpal reads black plus three font colours
	bcs.w .bad
	lea 4(a2),a3
.shape
	move.l (a3)+,d1
	cmp.l d5,d1
	bcs.w .bad
	move.l d6,d0
	sub.l d1,d0
	bcs.w .bad
	cmp.l #10,d0
	bcs.w .bad
	btst #0,d1
	bne.w .bad
	lea 0(a2,d1.l),a4
	moveq #0,d2
	move.w 4(a4),d2	; source row bytes
	beq.w .bad
	btst #0,d2
	bne.w .bad
	moveq #0,d3
	move.w 6(a4),d3
	move.l d3,d4
	and.w #63,d4
	beq.w .bad
	add.w d4,d4
	subq.w #2,d4
	cmp.w d2,d4
	bne.w .bad
	lsr.w #6,d3
	bne.s .height
	move.w #1024,d3
.height
	cmp.w #10,d3	; Bigfont uses the compiled 8x10 menu/text cell
	bhi.w .bad
	mulu d2,d3	; one complete plane, plus the blitter's extra word
	move.l d3,d4
	addq.l #2,d4
	move.l (a4),d1
	btst #0,d1
	bne.w .bad
	cmp.l #10,d1
	bcs.w .bad
	add.l d4,d1
	bcs.w .bad
	cmp.l d0,d1
	bhi.w .bad
	moveq #0,d2
	move.w 8(a4),d2
	beq.w .bad
	cmp.w #8,d2
	bhi.w .bad
	tst.w aga
	bne.s .planes
	cmp.w #6,d2	; native ECS only owns six destination planes
	bhi.w .bad
.planes
	mulu.l d2,d3
	add.l #12,d3	; header plus extra word fetched after the last image row
	cmp.l d0,d3
	bhi.w .bad
	subq.l #1,d7
	bne.w .shape
	moveq #0,d0
	bra.w .done
.bad
	moveq #-1,d0
.done
	movem.l (a7)+,d1-d7/a0-a6
	rts
g2sfx_resource_slots
	dc.l shootsfx,shootsfx2,shootsfx3,shootsfx4,shootsfx5
	dc.l gruntsfx,gruntsfx2,gruntsfx3,gruntsfx4,tokensfx,doorsfx
	dc.l footstepsfx,diesfx,splatsfx,telesfx,ghoulsfx,lizsfx,lizhitsfx
	dc.l trollsfx,trollhitsfx,robotsfx,robodiesfx,dragonsfx,0

; Minimum flat entries referenced by the actual actor logic/renderers.
; Eight-facing drawshape_8 indexes (frame*8 + facing), independent of the
; file's rotation header. Scalar token types select fixed entries 0..5.
g2require_actor_shape	; a0=main shape, a2=compiled resource holder
	movem.l d0-d7/a0-a6,-(a7)
	jsr g2require_anim
	lea g2actor_shape_entries,a1
.holder
	move.l (a1)+,d0
	beq.w .done
	move.l (a1)+,d1
	cmp.l a2,d0
	bne.s .holder
	moveq #0,d0
	move.w an_frames(a0),d0
	move.w an_rotshft(a0),d2
	lsl.l d2,d0
	cmp.l d1,d0
	bcs.s .bad
.done
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort
g2actor_shape_entries
	dc.l player,5*8,tokens,6,marine,5*8,baldy,6*8,terra,5*8
	dc.l ghoul,3*8,demon,6*8,phantom,6*8,lizard,6*8
	dc.l deathhead,3*8,dragon,4*8,troll,6*8,0

g2require_defender_texture	; a1=selected texture column, all registers preserved
	movem.l d0-d7/a0-a6,-(a7)
	move.l a1,a0
	jsr g2asset_span
	cmp.l #2*64*65,d0	; display column plus full wrapping background column
	bcs.s .bad
	movem.l (a7)+,d0-d7/a0-a6
	rts
.bad
	jmp g2fatal_abort

g2require_external_c2p
	movem.l a0/d1,-(a7)
	move.l planar_c2p,a0
	move.l a0,d1
	beq.w .done
	moveq #42,d1	; last published entry is a word instruction at offset 40
	jsr g2require_asset_bytes
.done
	movem.l (a7)+,a0/d1
	rts

; Original Gloom3/ZM trimmed pictures use rows of width/8 or width/8+1.
; The legacy native decoder wrote the extra byte over the following row/plane.
; Two cold passes: prove complete source/run bounds first, then remove only
; that last extra byte. Literal payload is fully consumed; no new allocation.
; Output never overtakes input, header/visible row bytes stay unchanged, and
; normal strict validation remains the contract of every display decoder.
; a0=registered owned picture; d0=0/-1; other registers preserved.
g2normalize_legacy_iff
 movem.l d1-d7/a0-a6,-(a7)
 move.l a0,a2
 jsr g2asset_bounds
 cmp.l #12,d0
 bcs.w .bad
 move.l a1,a3
 moveq #0,d6
 move.w (a2),d6
 beq.w .bad
 cmp.w #320,d6
 bhi.w .bad
 move.l d6,d0
 and.w #7,d0
 bne.w .bad
 lsr.w #3,d6
 moveq #0,d7
.pass
 lea 12(a2),a4
 move.l a4,a5
 moveq #0,d5
 move.w 2(a2),d5
 beq.w .bad
 moveq #0,d0
 move.w 4(a2),d0
 beq.w .bad
 cmp.w #8,d0
 bhi.w .bad
 mulu.w d0,d5
.row
 move.l d6,d4
.run
 cmp.l a3,a4
 bcc.w .bad
 moveq #0,d2
 move.b (a4)+,d2
 ext.w d2
 cmp.w #-128,d2
 beq.s .run
 moveq #0,d3
 move.w d2,d3
 bpl.s .literal_count
 neg.w d3
.literal_count
 addq.w #1,d3
 move.l d4,d0
 addq.w #1,d0
 cmp.w d0,d3
 bhi.w .bad
 move.l d3,d1
 tst.w d2
 bpl.s .payload
 moveq #1,d1
.payload
 move.l a3,d0
 sub.l a4,d0
 cmp.l d0,d1
 bhi.w .bad
 move.l d3,d0
 cmp.w d4,d0
 bls.s .count_ok
 move.l d4,d0
.count_ok
 tst.w d7
 beq.s .skip_payload
 move.l d0,d1
 subq.w #1,d1
 tst.w d2
 bpl.s .copy_literal
 neg.b d1
 move.b d1,(a5)+
 move.b (a4)+,(a5)+
 bra.s .advance
.copy_literal
 move.b d1,(a5)+
 move.l d0,d1
.copy
 move.b (a4)+,(a5)+
 subq.w #1,d1
 bne.s .copy
 cmp.w d0,d3
 beq.s .advance
 addq.l #1,a4
 bra.s .advance
.skip_payload
 adda.l d1,a4
.advance
 sub.w d0,d4
 bne.w .run
 subq.l #1,d5
 bne.w .row
 tst.w d7
 bne.s .good
 moveq #1,d7
 bra.w .pass
.good
 moveq #0,d0
 bra.s .done
.bad
 moveq #-1,d0
.done
 movem.l (a7)+,d1-d7/a0-a6
 rts

; Gloom3's original gun has exactly normal/recoil frames and no muzzle art.
; Add three NULL consumer slots in a private copy, retaining an_frames=2 so
; remapanim processes only the two original shapes. The unchanged muzzle
; renderer already skips NULL slots. All original pixels/palette are copied.
; Called only after full animation validation, before any gun consumer.
; a0=owned animation; d0=replacement; all other registers preserved.
g2prepare_legacy_gun
 movem.l d1-d7/a0-a6,-(a7)
 move.l a0,a2
 jsr g2asset_bounds
 move.l d0,d6
 cmp.l #32,d6
 bcs.s .copy_needed
 cmp.l #32,12(a2)
 bcs.s .copy_needed
 cmp.l #32,16(a2)
 bcs.s .copy_needed
 tst.l 20(a2)
 bne.s .copy_needed
 tst.l 24(a2)
 bne.s .copy_needed
 tst.l 28(a2)
 bne.s .copy_needed
 move.l a2,d0
 bra.w .done
.copy_needed
 move.l d6,d0
 add.l #12,d0
 bcs.w .bad
 moveq #4,d1
 lea g2legacy_gun_label(pc),a0
 jsr allocmem_
 tst.l d0
 beq.w .bad
 move.l d0,a3
 move.l a2,a0
 move.l a3,a1
 moveq #19,d1
.header
 move.b (a0)+,(a1)+
 dbf d1,.header
 clr.l (a1)+
 clr.l (a1)+
 clr.l (a1)+
 move.l d6,d1
 sub.l #20,d1
.body
 move.b (a0)+,(a1)+
 subq.l #1,d1
 bne.s .body
 add.l #12,an_pal(a3)
 add.l #12,12(a3)
 add.l #12,16(a3)
 move.l a3,gunpic
 move.l a2,a1
 jsr freemem_
 move.l a3,d0
.done
 movem.l (a7)+,d1-d7/a0-a6
 rts
.bad
 jmp g2fatal_abort
g2legacy_gun_label dc.b 'Gloom3 gun',0
	even
