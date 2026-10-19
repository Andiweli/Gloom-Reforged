; Bounded CrM!/CrM2 decoder, derived from tools/asm_helpers/decrm.s.
; Main-task-only (like the original shared Huffman workspace).
; a0=source/header, a1=destination, d0=actual source bytes, d1=dest capacity.
; d0=0 success / -1 malformed; every other register is preserved.
; No render loop calls this routine. Both disk and embedded loaders use it.
g2crm_decode_checked
 movem.l d1-d7/a0-a6,-(a7)
 move.l a7,g2crm_saved_sp
 move.l d1,d5
 tst.l a0
 beq.w g2crm_bad
 tst.l a1
 beq.w g2crm_bad
 cmp.l #14,d0
 bcs.w g2crm_bad
 tst.l d0
 bmi.w g2crm_bad
 tst.l d5
 ble.w g2crm_bad
 move.l a0,d6
 add.l d0,d6
 bcs.w g2crm_bad
 move.l (a0),d4
 cmp.l #'CrM!',d4
 beq.s .header
 cmp.l #'CrM2',d4
 bne.w g2crm_bad
.header
 move.l 6(a0),d1
 ble.w g2crm_bad
 cmp.l d5,d1
 bhi.w g2crm_bad
 move.l 10(a0),d2
 cmp.l #6,d2
 bcs.w g2crm_bad
 sub.l #14,d0
 cmp.l d0,d2
 bhi.w g2crm_bad
 lea 14(a0),a2
 move.l a0,g2crm_src_start
 lea 2(a0),a3	; physical reads stay within the file, including header lookahead
 move.l a3,g2crm_src_floor
 move.l a2,a3
 add.l d2,a3
 moveq #0,d6
 move.w -2(a3),d6
 ; Zero is valid too: demonstrated by palette_8 and a CrM! literal fixture.
 cmp.w #16,d6
 bhi.w g2crm_bad
 ; 64-bit semantic bit budget: payload*8 - 32 + final-word bit count.
 ; The old reader speculatively fetches the final header word. It can read
 ; inside the actual file, but those header bits may never be consumed.
 move.l d2,d0
 lsr.l #8,d0
 lsr.l #8,d0
 lsr.l #8,d0
 lsr.l #5,d0
 move.l d0,g2crm_bits_hi
 move.l d2,d0
 lsl.l #3,d0
 sub.l #32,d0
 bcc.s .budget_tail
 subq.l #1,g2crm_bits_hi
.budget_tail
 add.l d6,d0
 bcc.s .budget_ready
 addq.l #1,g2crm_bits_hi
.budget_ready
 move.l d0,g2crm_bits_lo
 move.l a1,g2crm_dst_start
 move.l a1,d6
 add.l d1,d6
 bcs.w g2crm_bad
 move.l d6,g2crm_dst_end
 cmp.l #'CrM!',d4
 bne.s .lzh
 bsr.w g2crm_FastDecruncher
 bra.s .finished
.lzh
 bsr.w g2crm_LZHDecruncher
.finished
 cmp.l g2crm_dst_start,a1
 bne.w g2crm_bad
 moveq #0,d0
 bra.s g2crm_return
g2crm_bad
 move.l g2crm_saved_sp,a7
 moveq #-1,d0
g2crm_return
 movem.l (a7)+,d1-d7/a0-a6
 rts

g2crm_check_copy
 cmp.l g2crm_dst_end,a3
 bhi.w g2crm_bad
 cmp.l a1,a3
 bls.w g2crm_bad
g2crm_check_write
 cmp.l g2crm_dst_start,a1
 bls.w g2crm_bad
 movem.l d1,-(a7)
 move.l a1,d1
 subq.l #1,d1
 cmp.l g2crm_src_start,d1
 bcs.s .safe
 cmp.l a2,d1
 bcs.w g2crm_bad
.safe
 movem.l (a7)+,d1
 rts

g2crm_take_one
 move.l d1,-(a7)
 moveq #1,d1
 bsr.s g2crm_take_bits
 move.l (a7)+,d1
 rts
g2crm_take_bits
 movem.l d0-d2,-(a7)
 cmp.l #1,d1
 bcs.w g2crm_bad
 cmp.l #16,d1
 bhi.w g2crm_bad
 move.l g2crm_bits_lo,d0
 sub.l d1,d0
 bcc.s .remaining
 tst.l g2crm_bits_hi
 beq.w g2crm_bad
 subq.l #1,g2crm_bits_hi
.remaining
 move.l d0,g2crm_bits_lo
 movem.l (a7)+,d0-d2
 rts

 cnop 0,4
g2crm_saved_sp dc.l 0
g2crm_src_start dc.l 0
g2crm_src_floor dc.l 0
g2crm_dst_start dc.l 0
g2crm_dst_end dc.l 0
g2crm_bits_lo dc.l 0
g2crm_bits_hi dc.l 0
g2crm_code_space dc.l 0
g2crm_code_bits dc.w 0
g2crm_len_symbols dc.w 0
g2crm_dist_symbols dc.w 0
 even

g2crm_FastDecruncher:
  MOVE.l  a1,a5     ;Decrunched Anfang (hier Ende des Decrunchens)
  ADD.l d1,a1
  ADD.l d2,a2
  MOVE.w  -(a2),d0    ;Anz Bits in letztem Wort
  MOVE.l  -(a2),d6    ;1.LW
  MOVEQ #16,d7      ;Anz Bits
  SUB.w d0,d7     ;Anz Bits, die rotiert werden m|ssen
  LSR.l d7,d6     ;1.Bits an Anfang bringen
  MOVE.w  d0,d7     ;Anz Bits, die noch im Wort sind
  MOVEQ #16,d3
  MOVEQ #0,d4
g2crm_DecrLoop:
  CMP.l a5,a1
  BLE.l g2crm_DecrEnd    ;a1=a5: fertig (a1<a5: eigentlich Fehler)

  BSR g2crm_BitTest
  BCC.w g2crm_InsertSeq    ;1.Bit 0: Sequenz
  MOVEQ #0,d4
;** einzelne Bytes einf|gen **
g2crm_InsertBytes:
  MOVEQ #8,d1
  BSR g2crm_GetBits
  BSR.w g2crm_check_write
  MOVE.b  d0,-(a1)
  DBF d4,g2crm_InsertBytes
  BRA g2crm_DecrLoop
;*------------
g2crm_SpecialInsert:
  MOVEQ #14,d4
  MOVEQ #5,d1
  BSR g2crm_BitTest
  BCS.w g2crm_IB1
  MOVEQ #14,d1
g2crm_IB1: BSR g2crm_GetBits
  ADD.w d0,d4
  BRA g2crm_InsertBytes
;*------------
g2crm_InsertSeq:
;** Anzahl der gleichen Bits holen **
  BSR g2crm_BitTest
  BCS.w g2crm_AB1
  MOVEQ #1,d1     ;Maske: 0 (1 AB)
  MOVEQ #1,d4     ;normal: Summe 1
  BRA g2crm_ABGet
g2crm_AB1:
  BSR g2crm_BitTest
  BCS.w g2crm_AB2
  MOVEQ #2,d1     ;Maske: 01 (2 ABs)
  MOVEQ #3,d4     ;ab hier: Summe mindestens 3
  BRA g2crm_ABGet
g2crm_AB2:
  BSR g2crm_BitTest
  BCS.w g2crm_AB3
  MOVEQ #4,d1     ;Maske: 011 (4 ABs)
  MOVEQ #7,d4     ;hier: Summe 11
  BRA g2crm_ABGet
g2crm_AB3:
  MOVEQ #8,d1     ;Maske: 111 (8 ABs)
  MOVEQ #$17,d4     ;hier: Summe 11
g2crm_ABGet:
  BSR g2crm_GetBits
  ADD.w d0,d4     ;d0: Ldnge der Sequenz - 1
  CMP.w #22,d4
  BEQ.w g2crm_SpecialInsert
  BLT.w g2crm__Cont
  SUBQ.w  #1,d4
g2crm__Cont:
;** SequenzAnbstand holen **
  BSR g2crm_BitTest
  BCS.w g2crm_DB1
  MOVEQ #9,d1     ;Maske: 0 (9 DBs)
  MOVEQ #$20,d2
  BRA g2crm_DBGet
g2crm_DB1:
  BSR g2crm_BitTest
  BCS.w g2crm_DB2
  MOVEQ #5,d1     ;Maske: 01 (5 DBs)
  MOVEQ #0,d2
  BRA g2crm_DBGet
g2crm_DB2:
  MOVEQ #14,d1      ;Maske: 11 (12 DBs)
  MOVE.w  #$220,d2
g2crm_DBGet:
  BSR g2crm_GetBits
  ADD.w d2,d0
  LEA 0(a1,d0.w),a3   ;a3 auf Anf zu kopierender Seq setzten
g2crm_InsSeqLoop:
  BSR.w g2crm_check_copy
  MOVE.b  -(a3),-(a1)   ;Byte kopieren
  DBF d4,g2crm_InsSeqLoop

  BRA g2crm_DecrLoop
;*------------
g2crm_BitTest:
  BSR.w g2crm_take_one
  SUBQ.w  #1,d7
  BNE.w g2crm_BTNoLoop
  MOVEQ #16,d7      ;hier kein add notwendig: d7 vorher 0
  MOVE.w  d6,d0
  LSR.l #1,d6     ;Bit rausschieben und Flags setzen
  SWAP  d6      ;ror.l  #16,d6
  CMP.l g2crm_src_floor,a2
  BCS.w g2crm_bad
  MOVE.w  -(a2),d6    ;ndchstes Wort holen
  SWAP  d6      ;rol.l  #16,d6
  LSR.w #1,d0     ;Bit rausschieben und Flags setzen
  RTS
g2crm_BTNoLoop:
  LSR.l #1,d6     ;Bit rausschieben und Flags setzen
  RTS
;*----------
g2crm_GetBits:       ;d1:AnzBits->d0:Bits
  BSR.w g2crm_take_bits
  MOVE.w  d6,d0     ;d6:Akt Wort
  LSR.l d1,d6     ;ndchste Bits nach vorne bringen
  SUB.w d1,d7     ;d7:Anz Bits, die noch im Wort sind
  BGT.w g2crm_GBNoLoop
; add.w #16,d7      ;BitCounter korrigieren
  ADD.w d3,d7     ;BitCounter korrigieren
  ROR.l d7,d6     ;restliche Bits re rausschieben
  CMP.l g2crm_src_floor,a2
  BCS.w g2crm_bad
  MOVE.w  -(a2),d6    ;ndchstes Wort holen
  ROL.l d7,d6     ;und zur|ckrotieren
g2crm_GBNoLoop:
  ADD.w d1,d1     ;*2 (in Tab sind Ws)
  AND.w g2crm_AndData-2(pc,d1.w),d0  ;unerw|nschte Bits rausschmei_en
  RTS
;*----------
g2crm_AndData:
  Dc.w  %1,%11,%111,%1111,%11111,%111111,%1111111
  Dc.w  %11111111,%111111111,%1111111111
  Dc.w  %11111111111,%111111111111
  Dc.w  %1111111111111,%11111111111111
;*-----------
g2crm_DecrEnd:
  RTS   ;a5: Start of decrunched Data

;***************************************************************************
g2crm_OCmpTab   = 0
g2crm_OAddTab   = 64
g2crm_ORealTab  = 128
g2crm_OAnzPerBits = 1182
g2crm_OBufLen   = 1246+2
;******************************

g2crm_LZHDecruncher:
  LEA g2crm_Tabbs+2(pc),a6
; addq.l  #2,a6
  ADD.l d1,a1
  ADD.l d2,a2

  MOVE.w  -(a2),d0    ;Anz Bits in letztem Wort
  MOVE.l  -(a2),d6    ;1.LW
  MOVEQ #16,d7      ;Anz Bits
  SUB.w d0,d7     ;Anz Bits, die rotiert werden m|ssen
  LSR.l d7,d6     ;1.Bits an Anfang bringen
  MOVE.w  d0,d7     ;Anz Bits, die noch im Wort sind
  MOVEQ #16,d3

g2crm_BufLoop:
  LEA g2crm_OAnzPerBits(a6),a0
  MOVEQ #16-1,d2
g2crm_clear: CLR.l (a0)+
  DBF d2,g2crm_clear

  LEA g2crm_OAnzPerBits+32(a6),a0
  LEA g2crm_ORealTab+30(a6),a4
  MOVEQ #9,d2
  BSR g2crm_ReadTab
  LEA g2crm_OAnzPerBits(a6),a0
  LEA g2crm_ORealTab(a6),a4
  MOVEQ #4,d2
  BSR g2crm_ReadTab

  LEA g2crm_OAnzPerBits+32(a6),a3
  LEA g2crm_OCmpTab-2(a6),a4
  BSR g2crm_CalcCmpTab
  LEA g2crm_OAnzPerBits(a6),a3
  LEA g2crm_OCmpTab+30(a6),a4
  BSR g2crm_CalcCmpTab

  MOVEQ #16,d1
  BSR g2crm_GetBits2
  MOVE.w  d0,d5
  LEA g2crm_ORealTab+30(a6),a0
  LEA -30(a0),a5
g2crm_decrloop2:  ;** tabu: d3/d6/d7/a0-a2/a4
  MOVE.l  a6,a4
  BSR g2crm_ReadIt
  BTST  #8,d0
  BNE.w g2crm_skip
  MOVE.w  d0,d4

  LEA g2crm_OCmpTab+32(a6),a4
  EXG a0,a5
  BSR g2crm_ReadIt
  EXG a0,a5
  MOVE.w  d0,d1
  MOVE.w  d0,d2
  BNE.w g2crm_sc1
  MOVEQ #1,d1
  MOVEQ #16,d2
g2crm_sc1: BSR g2crm_GetBits2
  BSET  d2,d0
g2crm_sc2: LEA 1(a1,d0.w),a3
g2crm_sloop: BSR.w g2crm_check_copy
  MOVE.b  -(a3),-(a1)
  DBF d4,g2crm_sloop

  BSR.w g2crm_check_copy
  MOVE.b  -(a3),-(a1)
  BSR.w g2crm_check_copy
  MOVE.b  -(a3),d0
g2crm_skip:  BSR.w g2crm_check_write
  MOVE.b  d0,-(a1)
  DBF d5,g2crm_decrloop2
  MOVEQ #1,d1
  BSR g2crm_GetBits2
  BNE.w g2crm_BufLoop
  BRA g2crm_LZHDecrEnd
;*-----------*******************
g2crm_ReadIt:
  MOVEQ #0,d1     ;Nr Byte
  MOVE.w #15,g2crm_code_bits
g2crm_RIloop:
  SUBQ.w #1,g2crm_code_bits
  BMI.w g2crm_bad
  BSR.w g2crm_take_one
  SUBQ.w  #1,d7
  BEQ.w g2crm_BTLoop
  LSR.l #1,d6     ;Bit rausschieben und Flags setzen
  BRA g2crm_BTEnd
g2crm_BTLoop:
  MOVEQ #16,d7      ;hier kein add notwendig: d7 vorher 0
  MOVE.w  d6,d0
  LSR.l #1,d6     ;Bit rausschieben und Flags setzen
  SWAP  d6      ;ror.l  #16,d6
  CMP.l g2crm_src_floor,a2
  BCS.w g2crm_bad
  MOVE.w  -(a2),d6    ;ndchstes Wort holen
  SWAP  d6      ;rol.l  #16,d6
  LSR.w #1,d0     ;Bit rausschieben und Flags setzen
g2crm_BTEnd:
  ROXL.w  #1,d1
  MOVE.w  (a4)+,d0
  CMP.w d1,d0
  BLS.w g2crm_RIloop

  ADD.w 62(a4),d1
  CMP.l #g2crm_Tabbs+2+g2crm_ORealTab+30,a0
  BNE.s .dist_index
  CMP.w g2crm_len_symbols,d1
  BCC.w g2crm_bad
  BRA.s .index_ok
.dist_index
  CMP.w g2crm_dist_symbols,d1
  BCC.w g2crm_bad
.index_ok
  ADD.w d1,d1
  MOVE.w  0(a0,d1.w),d0
  RTS
;*-------------------------------------
g2crm_GetBits2:       ;d1:AnzBits->d0:Bits
  BSR.w g2crm_take_bits
  MOVE.w  d6,d0     ;d6:Akt Wort
  LSR.l d1,d6     ;ndchste Bits nach vorne bringen
  SUB.w d1,d7     ;d7:Anz Bits, die noch im Wort sind
  BGT.w g2crm_GBNoLoop2
  ADD.w d3,d7     ;BitCounter korrigieren
  ROR.l d7,d6     ;restliche Bits re rausschieben
  CMP.l g2crm_src_floor,a2
  BCS.w g2crm_bad
  MOVE.w  -(a2),d6    ;ndchstes Wort holen
  ROL.l d7,d6     ;und zur|ckrotieren
g2crm_GBNoLoop2:
  ADD.w d1,d1     ;*2 (in Tab sind Ws)
  AND.w g2crm_AndData2-2(pc,d1.w),d0  ;unerw|nschte Bits rausschmei_en
  RTS
;*----------
g2crm_AndData2:
  Dc.w  %1,%11,%111,%1111,%11111,%111111,%1111111
  Dc.w  %11111111,%111111111,%1111111111
  Dc.w  %11111111111,%111111111111
  Dc.w  %1111111111111,%11111111111111
  Dc.w  %111111111111111,%1111111111111111
;*---------------------------------------
g2crm_ReadTab:
  MOVEM.l d1-d5/a3,-(a7)
  MOVEQ #4,d1
  BSR g2crm_GetBits2    ;Anz g2crm_AnzPerBits
  TST.w d0
  BEQ.w g2crm_bad
  MOVE.w  d0,d5
  SUBQ.w  #1,d5
  MOVEQ #0,d4
  SUB.l a3,a3
  MOVE.l #1,g2crm_code_space
g2crm_RTlop: ADDQ.w  #1,d4
  MOVE.w  d4,d1
  CMP.w d2,d1
  BLE.w g2crm_c1
  MOVE.w  d2,d1
g2crm_c1:  BSR g2crm_GetBits2
  MOVEM.l d1,-(a7)
  MOVE.l g2crm_code_space,d1
  ADD.l d1,d1
  MOVE.l d1,g2crm_code_space
  MOVEQ #0,d1
  MOVE.w d0,d1
  SUB.l d1,g2crm_code_space
  BCS.w g2crm_bad
  MOVEM.l (a7)+,d1
  MOVE.w d0,(a0)+
  ADD.w d0,a3
  CMP.l #15,a3
  BLS.s .count_ok
  CMP.w #9,d2
  BNE.w g2crm_bad
  CMP.l #512,a3
  BHI.w g2crm_bad
.count_ok
  DBF d5,g2crm_RTlop

  MOVE.w a3,d5
  BEQ.w g2crm_bad
  CMP.w #9,d2
  BNE.s .distance_count
  MOVE.w d5,g2crm_len_symbols
  BRA.s .symbols_ready
.distance_count
  MOVE.w d5,g2crm_dist_symbols
.symbols_ready
  SUBQ.w #1,d5
g2crm_RTlp2: MOVE.w  d2,d1
  BSR g2crm_GetBits2
  MOVE.w  d0,(a4)+
  DBF d5,g2crm_RTlp2
  MOVEM.l (a7)+,d1-d5/a3
  RTS
;**************************************************************
g2crm_CalcCmpTab:
  MOVEM.l d0-d7,-(a7)
  CLR.w (a4)+
  MOVEQ #15-1,d7
  MOVEQ #-1,d4
  MOVEQ #0,d2
  MOVEQ #0,d3
  MOVEQ #1,d1
g2crm_CClop: MOVE.w  (a3)+,d6
  MOVE.w  d3,64(a4)
  MOVE.w  -2(a4),d0
  ADD.w d0,d0
  SUB.w d0,64(a4)
  ADD.w d6,d3
  MULU  d1,d6
  ADD.w d6,d2
  MOVE.w  d2,(a4)+
g2crm_cont2:
  LSL.w #1,d2
  DBF d7,g2crm_CClop
  MOVEM.l (a7)+,d0-d7
  RTS
;*********************************************
g2crm_LZHDecrEnd:
;LZHDecrLen  equ *-g2crm_LZHDecruncher

  RTS
;***********************************
g2crm_Tabbs:  Dc.w  0   ;unbedingt!!!!!!!
g2crm_CmpTab: Ds.w 16    ;Len
  Ds.w 16    ;Dist
g2crm_AddTab: Ds.w 16    ;Len
  Ds.w 16    ;Dist
g2crm_RealTab:
  Ds.w 527   ;Dist+Len
g2crm_AnzPerBits:
  Ds.w 32    ;Dist+Len
