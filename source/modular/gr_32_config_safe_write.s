; Staged config replacement for AmigaDOS V36+. This is main-task-only.
; Input a0=name, a1=bytes, d0=length. Output d0=0 success, -1 failure.
; Keep the old file until Write and Close succeed. Rename cannot overwrite an
; existing AmigaDOS file, so retain a recoverable backup during installation.
; Task-specific temporary names avoid collisions between game/bench processes.
; The fixed .g2bak name can be discovered after a task is interrupted/restarted.
; A pre-existing temporary/backup file is never truncated or deleted.

g2save_config_checked
	movem.l	d1-d7/a0-a6,-(a7)
	move.l	a0,a2
	move.l	a1,a3
	move.l	d0,d4
	ble.w	.failed
	move.l	dosbase,d0
	beq.w	.failed
	move.l	d0,a6
	lea	g2save_temp_name,a0
	lea	g2save_backup_name,a1
	move.l	a2,a4
	moveq	#95,d1
	moveq	#0,d5		; last path component length
.copy_name
	move.b	(a4)+,d0
	beq.s	.suffix
	tst.w	d1
	beq.w	.failed
	cmp.b	#':',d0
	beq.s	.separator
	cmp.b	#'/',d0
	beq.s	.separator
	addq.w	#1,d5
	bra.s	.copy_char
.separator
	moveq	#0,d5
.copy_char
	move.b	d0,(a0)+
	move.b	d0,(a1)+
	subq.w	#1,d1
	bra.s	.copy_name
.suffix
	cmp.w	#15,d5	; fifteen-byte suffix must fit classic 30-character FFS names
	bhi.w	.failed
	move.b	#'.',(a0)+
	move.b	#'g',(a0)+
	move.b	#'2',(a0)+
	move.b #'.',(a1)+
	move.b #'g',(a1)+
	move.b #'2',(a1)+
	move.b #'b',(a1)+
	move.b #'a',(a1)+
	move.b #'k',(a1)+
	clr.b (a1)
	move.l	4.w,a4
	move.l	276(a4),d2
	moveq	#7,d3
.hex
	rol.l	#4,d2
	move.l	d2,d0
	and.w	#15,d0
	add.w	#'0',d0
	cmp.w	#'9',d0
	bls.s	.digit
	addq.w	#7,d0
.digit
	move.b	d0,(a0)+
	dbf	d3,.hex
	move.b	#'.',(a0)+
	move.b	#'t',(a0)+
	move.b	#'m',(a0)+
	move.b	#'p',(a0)+
	clr.b	(a0)
	lea	g2save_temp_name,a0
	bsr.w	g2save_path_absent
	tst.l	d0
	bne.w	.failed
	lea	g2save_backup_name,a0
	bsr.w	g2save_path_absent
	tst.l	d0
	bne.w	.failed
	lea	g2save_temp_name,a0
	move.l	a0,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq.w	.failed
	move.l	d7,d1
	move.l	a3,d2
	move.l	d4,d3
	jsr	-48(a6)
	move.l	d0,d5
	move.l	d7,d1
	jsr	-36(a6)	; file handle is consumed even when Close reports failure
	tst.l	d0
	beq.w	.delete_temp
	cmp.l	d4,d5
	bne.w	.delete_temp
	moveq	#0,d6
	move.l	a2,d1
	lea	g2save_backup_name,a0
	move.l	a0,d2
	jsr	-78(a6)	; Rename(old,backup)
	tst.l	d0
	bne.s	.old_saved
	jsr	-132(a6)	; IoErr, only a genuinely absent old file may be installed
	cmp.l	#205,d0
	bne.w	.delete_temp
	bra.s	.install
.old_saved
	moveq	#-1,d6
.install
	lea	g2save_temp_name,a0
	move.l	a0,d1
	move.l	a2,d2
	jsr	-78(a6)
	tst.l	d0
	beq.s	.rollback
	tst.l	d6
	beq.s	.success
	lea	g2save_backup_name,a0
	move.l	a0,d1
	jsr	-72(a6)	; failure leaves the old backup intact, new config is valid
.success
	moveq	#0,d0
	bra.s	.done
.rollback
	tst.l	d6
	beq.s	.delete_temp
	lea	g2save_backup_name,a0
	move.l	a0,d1
	move.l	a2,d2
	jsr	-78(a6)
	tst.l	d0
	beq.s	.failed	; preserve BOTH complete files for manual recovery
.delete_temp
	lea	g2save_temp_name,a0
	move.l	a0,d1
	jsr	-72(a6)
.failed
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d7/a0-a6
	rts

g2save_path_absent	; a0=name; d0=0 absent, -1 existing or any other error
	movem.l	d1-d2/a0-a1,-(a7)
	move.l	a0,d1
	moveq	#-2,d2	; ACCESS_READ
	jsr	-84(a6)
	tst.l	d0
	beq.s	.no_lock
	move.l	d0,d1
	jsr	-90(a6)
	moveq	#-1,d0
	bra.s	.done
.no_lock
	jsr	-132(a6)
	cmp.l	#205,d0
	bne.s	.error
	moveq	#0,d0
	bra.s	.done
.error
	moveq	#-1,d0
.done
	movem.l	(a7)+,d1-d2/a0-a1
	rts

; Restore only an absent target. Never overwrite an existing file, never use an
; unchecked temporary file, and never delete a backup left by another process.
; Returns 0 if restored, -1 otherwise. Normal readers validate restored bytes.
g2config_recover
	movem.l d1-d7/a0-a6,-(a7)
	move.l a0,a2
	move.l dosbase,d0
	beq.s .failed
	move.l d0,a6
	bsr.w g2save_path_absent
	tst.l d0
	bne.s .failed
	lea g2save_backup_name,a1
	move.l a2,a0
	moveq #95,d1
.name
	move.b (a0)+,d0
	beq.s .suffix
	tst.w d1
	beq.s .failed
	move.b d0,(a1)+
	subq.w #1,d1
	bra.s .name
.suffix
	move.b #'.',(a1)+
	move.b #'g',(a1)+
	move.b #'2',(a1)+
	move.b #'b',(a1)+
	move.b #'a',(a1)+
	move.b #'k',(a1)+
	clr.b (a1)
	lea g2save_backup_name,a0
	move.l a0,d1
	move.l a2,d2
	jsr -78(a6)
	tst.l d0
	beq.s .failed
	moveq #0,d0
	bra.s .done
.failed
	moveq #-1,d0
.done
	movem.l (a7)+,d1-d7/a0-a6
	rts

	cnop	0,4
g2save_temp_name		ds.b	128
g2save_backup_name	ds.b	128
