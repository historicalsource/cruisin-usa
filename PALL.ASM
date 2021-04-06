	.FILE	"PALL.ASM"
*----------------------------------------------------------------------------
*PALETTE ALLOCATION SYSTEM
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
*
*PALETTE MANAGEMENT ROUTINES
*PALETTES ARE ALLOCATED IN 128 BLOCKS OF 256 COLORS
*

	.include	VUNIT.EQU
	.include	MPROC.EQU
	.include	PALL.EQU
	.include	OBJECTS.EQU
	.include	SYS.EQU
	.include	MACS.EQU
	.include	ERROR.EQU
	.include	GLOBALS.EQU


	.bss  	PALRAM,PALNUM		;ACTIVE PALETTES
	.bss	RAWLOCS,PALNUM
	.bss	PTTRAM,PALNUM*3		;PALLETTE TRANSFER RAM
	.bss	NUM_FIXED,1		;THE NUMBER OF FIXED PALETTES


*----------------------------------------------------------------------------
*INDEX STORAGE
PALROMI		.word	_PALROM		;INDEXED PALETTES SOURCE ADDR LIST
PTTRAMI		.word	PTTRAM		;PALETTE TRANSFER RAM
PALRAMI		.word	PALRAM		;INDEXED PALETTE ACTIVE LOCATION LIST
PALLISTI	.word	_PALLIST	;CROSS-REFERENCE LIST
RAWLOCSI	.word	RAWLOCS		;RAW LOCATION REFERENCE SPACE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CLEAR OUT PALETTE RAM
*
*
PAL_INIT:
	PUSH	R0
	PUSH	AR0

	;CLEAR OUT PALETTE TRANSFER RAM
	LDP	@PTTRAMI
	LDI	@PTTRAMI,AR0
	LDI	0,R0
	RPTS	(PALNUM*3)-1
	STI	R0,*AR0++

	;CLEAR OUT PALETTE ALLOCATION RAM
	LDP	@PALRAMI
	LDI	@PALRAMI,AR0
	RPTS	PALNUM-1
	STI	R0,*AR0++

	;CLEAR OUT RAW PALETTE LOOKUP LIST
	LDP	@RAWLOCSI
	LDI	@RAWLOCSI,AR0
	RPTS	PALNUM-1
	STI	R0,*AR0++

	;CLEAR OUT PALETTE CROSS-REF LIST
	LDP	@PALLISTI
	LDI	@PALLISTI,AR0
	RPTS	num_palettes-1
	STI	R0,*AR0++

	CALL	PALXFER_INIT

	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PALTRANS- TRANSFER PALETTE DATA TO COLORRAM
*	CALL FROM DISPLAY IRQ AT BEGIN OF VBLNK
*
*CLOBBERS
*	R0,R1,R7,AR0,AR1,AR2
*
	.bss	PALSXFER,1
PAL_XFER:
	CLRI	R7
	LDP	@PALXFER_ACTIVE
	LDI	@PALXFER_ACTIVE,R0
	BNE	NOTCLR

	;NONE LEFT TO TRANSFER
	STI	R0,@PALXFER_AVAILABLE_P
	RETS

NOTCLR
	LDI	@PALXFER_ACTIVE,R0
	B	I889
PALTR0
	INC	R7
	CMPI	12,R7
	BGT	PALTRX

	LDI	*AR0,R0		;NEXT XFER BLOCK
	CALL	PALXFER_DEL

I889	LDI	R0,AR0
	CMPI	0,AR0
	BZ	PALTRX

	LDI	*+AR0(PALX_COUNT),R0
;	BZ	PALTRX		;COUNT=0,GAME OVER DONE
	BNN	NOT_PACKED_PAL

	;THIS IS A PACKED PALETTE STORED AS:  16BITS|(16BITS<<16)
	;UNPACK ON THE FLY
	LS	1,R0		;remove high bit
	RS	2,R0		;divide by 2

	.if	DEBUG
	CMPI	256,R0
	SLOCKON	GT,"PALL\PALTRANS  more than 256 entries?"
	.endif

;	STI	R1,*AR0++		;CLEAR OUT COUNT
	LDI	*+AR0(PALX_SADDR),AR1	;GET SOURCE
	LDI	*+AR0(PALX_DADDR),AR2	;GET DESTINATION
;	LDI	*AR0++,AR1		;GET SOURCE
;	LDI	*AR0++,AR2		;GET DESTINATION
	.if	DEBUG
	.data
COLRAML	.word	COLORAM
COLRAMH	.word	COLORAM+7FFFh
	.text
	
	CMPI	@COLRAML,AR2
	SLOCKON	LT,"PALL\PALTRANS SETUP XFER OUT OF CRAM LT"
	CMPI	@COLRAMH,AR2
	SLOCKON	GT,"PALL\PALTRANS SETUP XFER OUT OF CRAM GT"
	.endif


	SUBI	1,R0		;DEC COUNT BY 1

	LDI	R0,RC
	RPTB	PACBLK
	LDI	*AR1++,R2
	STI	R2,*AR2++	;FIRST COLOR
	RS	16,R2
PACBLK	STI	R2,*AR2++	;SECOND COLOR
	B     	PALTR0		;LOOK FOR NEXT TRANSFER

NOT_PACKED_PAL
;	STI	R1,*AR0++	;CLEAR OUT COUNT
	LDI	*+AR0(PALX_SADDR),AR1	;GET SOURCE
	LDI	*+AR0(PALX_DADDR),AR2	;GET DESTINATION
;	LDI	*AR0++,AR1	;GET SOURCE
;	LDI	*AR0++,AR2	;GET DESTINATION
	.if	DEBUG
	CMPI	@COLRAML,AR2
	SLOCKON	LT,"PALL\PALTRANS SETUP XFER OUT OF CRAM LT 2"
	CMPI	@COLRAMH,AR2
	SLOCKON	GT,"PALL\PALTRANS SETUP XFER OUT OF CRAM GT 2"
	.endif


	SUBI	2,R0		;DEC COUNT BY 1
	BNN	REGDOIT
	LDI	*AR1++,R2	;single case
	STI	R2,*AR2++
	B	PALTR0
REGDOIT

	LDI	*AR1++,R2
	RPTS	R0
	LDI	*AR1++,R2
 ||	STI	R2,*AR2++
	STI	R2,*AR2++

	B     	PALTR0		;LOOK FOR NEXT TRANSFER
PALTRX
	RETS
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
*
*
*PARAMETERS
*	R0	PAL TO OVERWRITE
*	R1	SOURCE PAL
*
*
PAL_OVERWRITE:
	LDI	R0,AR2
	CALL	PAL_FIND
	SLOCKON	C,"PALL\PAL_OVERWRITE  FINDPAL FAILURE"
	RETSC

	LDP	@PALROMI
	LDI	R1,AR2
	ADDI	@PALROMI,AR2
	LDI	*AR2,AR2

	;SETUP TRANSFER
	LDI	*AR2++,R3	;GET COUNT
	LDI	R0,R2		;GET DESTINATION
	CALL	PAL_SET
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*FIND A PALETTE
*
*PARAMETERS
*	AR2	PALETTE INDEX
*RETURNS
*	R0	COLORAM CODE
*	CARRY SET IF PALETTE NOT FOUND
*
PAL_FIND:
	PUSH	AR2
	SETC		 	;ASSUME PALETTE NOT FOUND
	LDP	@PALLISTI	 	   
	ADDI	@PALLISTI,AR2
	LDI	*AR2,R0
	BZ	FPLXEX
	LSH	-16,R0
	LSH	8,R0
	CLRC	    		;WE FOUND IT DUDES...
FPLX
	POP	AR2
	RETS
FPLXEX
;edbg
;	BU	$
	SETC
	POP	AR2
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*FIND RAW PALETTE
*
*Raw palettes are not allocated the same as regular polygon palettes
*(they are not part of the indexing system)  Therefore a different
*method has been used for their allocation.  This simply reverses the
*process and finds out where we put the dadeo.
*PARAMETERS
*	AR2	RAW PALETTE ADDRESS
*RETURNS
*	NOT FOUND
*		CARRY CLEAR
*	FOUND
*		CARRY SET
*		R0	PALLETTE CODE
*
PAL_FIND_RAW:
	PUSH	AR0
	LDI	-1,R0
	LDP	@RAWLOCSI
	LDI	@RAWLOCSI,AR0

FINDRLP	ADDI	1,R0
	CMPI	AR2,*AR0++
	BEQ	FOUNDRAW
	CMPI	PALNUM,R0
	BLE	FINDRLP
	LDI	-1,R0

;	.if	DEBUG
;edbg	;DBG DBG
;	BU	$
;	;DBG
;	.endif
	CLRC
	POP	AR0
	RETS
FOUNDRAW
	LSH	8,R0
	SETC
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*
*
*PARAMETERS
*	AR2	ACTUAL PALETTE INDEX
*		(16 BIT)
*
PAL_DELETE_RAW:
	PUSH	AR0

	RS	8,AR2

	LDP	@RAWLOCSI
	LDI	@RAWLOCSI,AR0
	ADDI	AR2,AR0
	CLRI	R0
	STI	R0,*AR0

;edbg
;	CMPI	0,AR2
;	BEQ	$
;edbg

	LDP	@PALRAMI
	LDI	@PALRAMI,AR0
	ADDI	AR2,AR0
	CLRI	R0
	STI	R0,*AR0

	POP	AR0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*GET A PALETTE
*
*PARAMETERS
*	AR2	PALETTE SOURCE INDEX
*RETURNS
*	R0	PALETTE CODE
*	LOCKUP ON ERROR
*
PAL_ALLOC:
	PUSHM	R2,R3,AR1,AR0,AR2

;	.if	DEBUG
;	CMPI	256,AR2
;	SLOCKON	GT,"PALL\GETPAL	next RAM loc??? find out"
;	.endif

	;LOOK IF ALREADY ALLOCATED
	LDI	@PALLISTI,AR1
	ADDI	AR2,AR1
	LDI	*AR1,R0	     	;ALREADY ALLOCATED?
	BZ	GPL0		;NO...
	ADDI	1,R0		;YES, INCREMENT AND RETURN
	STI	R0,*AR1
	B	GPLX		;RETURN...
GPL0
	;FIND A FREE ONE
	LDP	@PALRAMI	 	;LOOK FOR FREE CELL	
	LDI	@PALRAMI,AR0
	LDI	PALNUM-1,RC

	LDI	*AR0++,R0 	;GET FIRST ONE
	RPTB	GPLP
	BZ	GETPL		;GOT A EMPTY
GPLP	LDI	*AR0++,R0	;GET NEXT ONE
GPERR
;	SLOCKON	U,"PALL\GETPAL   ERROR NONE LEFT"
	ERRON	U,77h
;edbg	.if	DEBUG
;	BU	$
;	.endif
	B	GPLX

GETPL
	LDI	AR2,R2
	LDP	PALROMI
	ADDI	@PALROMI,AR2
	LDI	*AR2,AR2	;NOW HOLDS RAM LOCATION

	OR	8000H,R2	;MAKE SURE A BIT IS SET
	STI	R2,*-AR0(1)	;MARK PALETTE AS TAKEN
	SUBI	PALNUM-1,RC	;GET PALETTE CODE
	NEGI	RC,R0
	LSH	16,R0
	ADDI	1,R0		;INC COUNT
	STI	R0,*AR1		

	;SETUP TRANSFER
	LDI	*AR2++,R3	;GET COUNT
	LDI	R0,R2		;GET DESTINATION
	LSH	-16,R2
	LSH	8,R2  		
	CALL	PAL_SET
	SUBI	1,AR2		;RESTORE AR2
GPLX
	LSH	-16,R0		;SHIFT DOWN CODE
	LSH	8,R0
	POPM	AR2,AR0,AR1,R3,R2
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PAL_ALLOC_RAW
*THIS ROUTINE IS FOR USE WHEN YOU HAVE A SELF-CREATED PALETTE THAT
*YOU NEED TO ALLOCATE INTO MEMORY, BUT NOT USE THE PCOMP INDEXING SYSTEM
*
*PARAMETERS
*	AR2	PALETTE SOURCE ADDRESS
*RETURNS
*	R0	PALETTE CODE
*	LOCKUP ON ERROR
*
PAL_ALLOC_RAW:
	PUSHM	R2,R3,AR1,AR0,AR2

	;FIND A FREE ONE
	LDP	@PALRAMI	 	;LOOK FOR FREE CELL
	LDI	@PALRAMI,AR0
	LDI	PALNUM-1,RC

	LDI	*AR0++,R0 	;GET FIRST ONE
	RPTB	RPLP
	BZ	RAWPL		;GOT A EMPTY
RPLP	LDI	*AR0++,R0	;GET NEXT ONE

	ERRON	U,78h
;	SLOCKON	U,"PALL\RAWPAL  ERROR... NONE LEFT"
;edbg	.if	DEBUG
;	BU	$
;	.endif
	B	RAWPEX		;UNTIL WE COME UP WITH A BETTER IDEA

RAWPL
	LDI	-1,R2
	STI	R2,*-AR0(1)	;MARK PALETTE AS TAKEN
	SUBI	PALNUM-1,RC	;GET PALETTE CODE
	NEGI	RC,R0
	LSH	16,R0
	ADDI	1,R0		;INC COUNT

	;SETUP TRANSFER
	LDI	*AR2++,R3	;GET COUNT
	LDI	R0,R2		;GET DESTINATION
	LSH	-16,R2
	LSH	8,R2  		
	CALL	PAL_SET
	SUBI	1,AR2		;RESTORE AR2
RPLX	LSH	-16,R0		;SHIFT DOWN CODE

	LDI	R0,AR0
	LDP	@RAWLOCSI
	ADDI	@RAWLOCSI,AR0
	STI	AR2,*AR0

RAWPEX
	LSH	8,R0
	POPM	AR2,AR0,AR1,R3,R2
	RETS
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
*SETUP PALETTE TRANSFER
*
*PARAMETERS
*	AR2	SOURCE DATA ADDRESSS
*	R2	DEST PALETTE(B8-15), DEST COLOR(B0-7)
*	R3	COUNT
*
PAL_SET:
	PUSH	R0
	PUSH	AR0

;	LDI	2000h,R0
;	CMPI	R2,R0
;	BEQ	$	;... found it

;edbg
;	LDI	R2,R0
;	RS	8,R0
;	CMPI	0,R0
;	BEQ	$
;edbg


	DINT
	CALL	PALXFER_GET

	STI	AR2,*+AR0(PALX_SADDR)	;SAVE SOURCE ADDR
	LDI	COLORAM>>16,RC		;ADD IN COLORAM ADDRESS
	LSH	16,RC			;SHIFT IT IN PLACE
	ADDI	R2,RC			;CONVERTED TO ADDRESS
	STI	RC,*+AR0(PALX_DADDR)	;SAVE DEST ADDR
	STI	R3,*+AR0(PALX_COUNT)	;SAVE WORD COUNT

	CALL	ENABLEGIE


	.if	DEBUG
	NOP
	NOP
	NOP
	CMPI	@COLRAML,RC
	ERRON	LT,88
;	SLOCKON	LT,"PALL\PALTRANS SETUP XFER OUT OF CRAM LT"
	CMPI	@COLRAMH,RC
	ERRON	GT,88
;	SLOCKON	GT,"PALL\PALTRANS SETUP XFER OUT OF CRAM GT"
	.endif



	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*STRUCT PALXFER
PALX_LINK	.set	0	;UH	
PALX_SADDR	.set	1	;UH
PALX_DADDR	.set	2	;UH
PALX_COUNT	.set	3	;UH
PALX_SIZE	.set	4	;SIZ
*ENDSTRUCT

PALXFER_ACTIVEI	.word	PALXFER_ACTIVE
PALXFER_FREEI	.word	PALXFER_FREE
PALXFER_STRI	.word	PALXFER_STR
NXFER_PALS	.set	128

	.bss	PALXFER_ACTIVE,1
	.bss	PALXFER_FREE,1
	.bss	PALXFER_AVAILABLE_P,1
	.bss	PALXFER_STR,PALX_SIZE*NXFER_PALS

*----------------------------------------------------------------------------
PALXFER_INIT:
	PUSH	R0
	PUSH	AR0
	PUSH	AR1

	CLRI	R0
	STI	R0,@PALXFER_ACTIVE

	LDI	@PALXFER_FREEI,AR0	 	;GET FREE POINTER
	LDI	@PALXFER_STRI,AR1
	LDI	NXFER_PALS-1,RC

	RPTB	PXIL
	STI	AR1,*AR0
	LDI	AR1,AR0
PXIL	ADDI	PALX_SIZE,AR1

	LDI	0,R0
	STI	R0,*AR0

	POP	AR1
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*ALLOCATE A PALETTE XFER BLOCK
*
*RETURNS
*	AR0	PTR TO AVAILABLE XFER BLOCK
*
PALXFER_GET:
	PUSH	R0
	LDI	1,R0
	STI	R0,@PALXFER_AVAILABLE_P

	LDI	@PALXFER_FREE,AR0
	.if	DEBUG
	CMPI	0,AR0
	BNE	CNT
	EINT
	BU	$
CNT
	.endif
	LDI	*+AR0(PALX_LINK),R0
	STI	R0,@PALXFER_FREE

	LDI	@PALXFER_ACTIVE,R0
	STI	R0,*+AR0(PALX_LINK)
	STI	AR0,@PALXFER_ACTIVE
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*FREE A PALETTE XFER BLOCK
*
*PARAMETERS
*	AR0	PTR TO XFER BLOCK TO FREE
*
PALXFER_DEL:
	PUSH	R0
	PUSH	AR1

	LDI	@PALXFER_ACTIVEI,R1
PXFLP	LDI	R1,AR1
	LDI	*AR1,R1
	.if	DEBUG
	BZ	$
	.endif
	BZ	PXXX

	CMPI	R1,AR0
	BNE	PXFLP

	LDI	*AR0,R1
	STI	R1,*AR1			;LINK AROUND

	LDI	@PALXFER_FREE,R1
	STI	R1,*AR0
	STI	AR0,@PALXFER_FREE
PXXX
	POP	AR1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*DELETE A PALETTE
*
*PARAMETERS
*	AR2	PALETTE INDEX
*	LOCKUP ON ERROR
*
PAL_DELETE:
	PUSH	R0
	PUSH	AR0

;edbg
;	CMPI	0,AR2
;	BEQ	$
;edbg

	;DELETE FROM PALETTE LIST AREA
	LDP	@PALLISTI
	LDI	@PALLISTI,AR0
	ADDI	AR2,AR0

	LDI	*AR0,R0
	BZ	DELP2
	RS	16,R0
	LS	16,R0

     	STI	R0,*AR0
	LDI	R0,RC
	LSH	16,R0
	BNZ	DELP2	;palette not found ignore...

	;CLEAR OUT PALRAM, LIST ENTRY IF COUNT IS ZERO
DELP1	LDI	0,R0
	STI	R0,*AR0		;CLEAR OUT LIST ENTRY
	LDP	@PALRAMI
	LDI	@PALRAMI,AR0
	LSH	-16,RC
	ADDI	RC,AR0
	STI	R0,*AR0		;ZERO OUT PALRAM AREA
DELP2
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PALETTE DIMMER
*
*PARAMETERS
*	AR0	SOURCE PALETTE
*	AR1	RAM BUFFER
*	R0	(FL) UNIT NUMBER
*OPERATION
*	READS DATA IN FROM SOURCE PALETTE
*	MULTIPLIES BY UNIT NUMBER
*	STORES DATA IN RAM BUFFER
*	CALLS PAL_SET APPROPRIATELY
*	(ASSUMES RAM BUFFER IS ALREADY ALLOCATED
*	 AS A PALETTE)
*
*
PAL_DIMMER:
	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	R0
	PUSH	R1
	PUSHFL	R6
	PUSHFL	R7

	PUSH	AR1
	LDF	R0,R7

	LDI	*AR0++,R0
	STI	R0,*AR1++
	LDI	127,AR5
PDMLP
	LDI	*AR0++,R4	;get src2
	LDI	R4,R1
	AND	01Fh,R1
	FLOAT	R1
	MPYF	R7,R1
	FIX	R1

	LDI	R4,R2		;--
	RS	5,R2
	AND	01Fh,R2
	FLOAT	R2
	MPYF	R7,R2
	FIX	R2
	LS	5,R2
	OR	R2,R1

	LDI	R4,R2		;--
	RS	10,R2
	AND	01Fh,R2
	FLOAT	R2
	MPYF	R7,R2
	FIX	R2
	LS	10,R2
	OR	R2,R1
	PUSH	R1

	;----second word----------
	RS	16,R4		;get src1(B)
	LDI	R4,R1
	AND	01Fh,R1
	FLOAT	R1
	MPYF	R7,R1
	FIX	R1

	LDI	R4,R2
	RS	5,R2
	AND	01Fh,R2
	FLOAT	R2
	MPYF	R7,R2
	FIX	R2
	LS	5,R2
	OR	R2,R1

	LDI	R4,R2
	RS	10,R2
	AND	01Fh,R2
	FLOAT	R2
	MPYF	R7,R2
	FIX	R2
	LS	10,R2
	OR	R2,R1

	POP	R2
	LS	16,R1
	OR	R2,R1
	STI	R1,*AR1++
	DBU	AR5,PDMLP

	POP	AR2			;RECOVER RAM BUFFER ADDR
	CALL	PAL_FIND_RAW
	LDI	*AR2++,R3
	LDI	R0,R2
	CALL	PAL_SET

	POPFL	R7
	POPFL	R6
	POP	R1
	POP	R0
	POP	AR2
	POP	AR1
	POP	AR0
	RETS
*----------------------------------------------------------------------------
	.END
