	.FILE	"LEG.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*


USEFIXED	.set	1
USEEXTENDED	.set	0

	.include	MACS.EQU
	.include	VUNIT.EQU
	.include	SYS.EQU
	.include	GLOBALS.EQU
	.include	OBJECTS.EQU

	.bss	FINISH_ID,1


*----------------------------------------------------------------------------
* USEAGE:
*
*
*FOR EACH LEG IN THE SYSTEM THE LEG_GENERATE_MAP ROUTINE IS
*CALLED TO GENERATE THE LEG MAP.
*THIS MAP IS IDENTICAL TO HOW THE OBJECTS WILL BE ALLOCATED ON
*THE DYNAMIC LIST.
*
*THE LIST STARTS AT LEGMAP (located in hibss space)
*AND HAS THE FOLLOWING STRUCTURE:
*
*
**STRUCT LEG
*LEG_POSX	.set	0	;FL
*LEG_POSY	.set	1	;FL
*LEG_POSZ	.set	2	;FL
*LEG_ID		.set	3	;UH
**ENDSTRUCT
*LEG_SIZE	.set	4	;SI
*	.globl	LEG_MAP	;RAM SPACE
*MAX_LEG_ELEMENTS	.set	1200
*
*THE LAST ENTRY IN THE MAP HAS ALL FIELDS AS
*0FFFF FFFFh
*
*DRONES ON STARTING GRID MUST USE:
*	.bss	RACER_GRID_START
*AS THE STARTING INDEX TO ASSUME THE PLAYER
*WILL BE LOCATED AT.
*
*
*


LEG_MAPI	.word	LEG_MAP


	.globl	LEG_MAP
	.bss	LEG_ELEMENTS,1
	hibss	LEG_MAP,MAX_LEG_ELEMENTS*LEG_SIZE

	.bss	LAST_END_CACHE,1
	.bss	LAST_END_INDEX,1
	.bss	LAST_ORIENTATION,1




*----------------------------------------------------------------------------
*
*
*THIS INITIALIZATION IS FOR EACH GAME, NOT
*EACH LEG
*
*
LEG_INIT:
	PUSH	R0
	CLRI	R0
	STI	R0,@LEG_ELEMENTS
	LDI	1,R0
	STI	R0,@LAST_END_INDEX
	LDI	@TYCO_TRKI,R0
	STI	R0,@LAST_END_CACHE
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
MINILL_SIZE	.set	60
	hibss	LEG_SSLL,MINILL_SIZE*(LEG_SIZE+1)
	.bss	LEGFREE,1
	.bss	LEGLL,1
*
*NOT A TRUE LINKED LIST, BECAUSE THERE IS NO DYNAMIC
*DEALLOCATION (TO ALLOW REALLOCATION)  THE SYSTEM IS
*RESET WHEN PIECES ARE REALLOCATED.
*
*THIS IS FOR THE SAKE OF SPEED
*
ELEMENT_INIT:
	PUSH	R0

	LDL	LEG_SSLL,R0
	STI	R0,@LEGFREE

	CLRI	R0
	STI	R0,@LEGLL

	.if	DEBUG
	.bss	DBG_LEGCNT,1
	STI	R0,@DBG_LEGCNT
	.endif
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*RETURNS
*	AR3	PTR TO ELEMENT
*
ELEMENT_GET:
	PUSH	AR0

	.if	DEBUG
	LDI	@DBG_LEGCNT,AR0		;CHECK TO SEE IF WE ARE ALLOCATING TO MANY
	INC	AR0			;PIECES
	CMPI	MINILL_SIZE,AR0
	BGE	$
	STI	AR0,@DBG_LEGCNT
	.endif

	LDI	@LEGFREE,AR3
	LDI	AR3,AR0
	ADDI	LEG_SIZE+1,AR0
	STI	AR0,@LEGFREE
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR3	LIST ELEMENT
*
*INSERT LOWEST TO HIGHEST ONTO LEGLL
*

LEGLLI	.word	LEGLL
ELEMENT_ADD:
	LDI	*+AR3(1+LEG_ID),R0


	LDI	@LEGLLI,AR0
R65	LDI	*AR0,AR1
	CMPI	0,AR1
	BEQ	QT

	CMPI	*+AR1(1+LEG_ID),R0
	BLT	QT
	LDI	AR1,AR0
	BU	R65

QT
	STI	AR1,*AR3
	STI	AR3,*AR0

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR3	PTR TO LEG MAP ENTRY
*
ELEMENT_DUMP_INTO_LEGMAP:
	PUSH	R0
	PUSH	AR0
	PUSH	AR1

	LDI	@LEGLL,AR0
EDILL	CMPI	0,AR0
	BEQ	ENDIT

	LDI	AR0,AR1
	LDI	*AR0,AR0
	INC	AR1

	LDI	LEG_SIZE-1,RC
	RPTB	K99
	LDI	*AR1++,R0
K99	STI	R0,*AR3++
	BU	EDILL
ENDIT

	POP	AR1
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR0	START INDEX
*	AR1	END INDEX
*
*
LEG_GENERATE_MAP:
	LDI	AR1,R1
	ADDI	2,R1
	STI	R1,@FINISH_ID

	LDI	@LAST_END_CACHE,AR2
	LDI	@LAST_END_INDEX,AR4


	;GROUP LOOP
GENMAPLP

*
*FIND THE TYCOMAP ENTRY APPROPRIATE TO THIS LEG
*
*
*

LPP	CMPI	AR0,AR4
	BEQ	DNFND

	LDI	*AR2++(6),R1
	TSTB	1,R1
	BZ	NOOVERA
	ADDI	1,AR2
NOOVERA	TSTB	SC_REVERSE,R1
	BZ	CNTA
	NOP	*AR2++(4)
CNTA	TSTB	SC_OVER2,R1
	BZ	CNTNA
	NOP	*AR2++			;OVERLAY 2
CNTNA
	INC	AR4			;INCREMENT INDEX
	BU	LPP


DNFND
	LDI	@LEG_MAPI,AR3

*
*LOAD TYCO ENTRIES UNTIL LAST LEG IS FOUND
*
*
LOAD_LP

	;AR2	TYCO ENTRY
	;AR3	MAP ENTRY
	CALL	LEG_ADD_GROUP

	LDI	*AR2++(6),R1
	TSTB	1,R1
	BZ	NOOVERB
	ADDI	1,AR2
NOOVERB	TSTB	SC_REVERSE,R1
	BZ	CNTB
	NOP	*AR2++(4)
CNTB	TSTB	SC_OVER2,R1
	BZ	CNTNB
	NOP	*AR2++			;OVERLAY 2
CNTNB
	INC	AR4			;INCREMENT INDEX
	CMPI	AR1,AR4
	BLE	LOAD_LP


	STI	AR2,@LAST_END_CACHE
	STI	AR4,@LAST_END_INDEX

*
*LOAD THREE EXTRA LEGS ONTO THE END
*
	ADDI	3,AR1

LOAD_LP2
	;AR2	TYCO ENTRY
	;AR3	MAP ENTRY
	CALL	LEG_ADD_GROUP

	LDI	*AR2++(6),R1
	TSTB	1,R1
	BZ	NOOVERB2
	ADDI	1,AR2
NOOVERB2
	TSTB	SC_REVERSE,R1
	BZ	CNTB2
	NOP	*AR2++(4)
CNTB2	TSTB	SC_OVER2,R1
	BZ	CNTNB2
	NOP	*AR2++			;OVERLAY 2
CNTNB2
	INC	AR4			;INCREMENT INDEX
	CMPI	AR1,AR4
	BLE	LOAD_LP2



*
*FLAG THE END OF THE LIST
*

	LDI	-1,R0
	RPTS	LEG_SIZE-1
	STI	R0,*AR3++

*
*AND RETURN TO GAME...
*

	RETS
*----------------------------------------------------------------------------

	


	.bss	LEG_FLAG,1	;UH
	.bss	LEG_RADY,1	;FL
	.bss	LEG_SECTIONIDX,1	;UH


*----------------------------------------------------------------------------
*
*
*
*PARAMETERS
*	AR2	PTR TO TYCO ROM ENTRY
*	AR3	PTR TO LEG MAP ENTRY
*	AR4	INDEX
*
*
LEG_ADD_GROUP:
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR3
	PUSH	AR4
	PUSH	AR5
	PUSH	AR7

	STI	AR4,@LEG_SECTIONIDX

	CALL	ELEMENT_INIT
	CALL	ELEMENT_GET
	INC	AR3


	LDI	AR2,AR7			;DEDICATED POINTER
	LDI	*AR7,R5			;LOAD FLAG

	LDI	R5,R6			;LANE COUNT
	RS	7,R6
	AND	1,R6			;THIS IS THE LANES
	



	LDF	*+AR7(TB_RADY),R2
	STF	R2,@LEG_RADY

	LDI	@MATRIXAI,AR2		;Group rotation matrix
	CALL	HPFIND_YMATRIX		;require High Precision

	LDI	*+AR7(TB_GROUP),AR5	;Group pointer
	ADDI	1,AR5			;skip radius


	LDI	*AR5++,R4		;get number of objects to load
	SUBI	1,R4

L12	LDI	*AR5++,AR2		;GET MODEL PTR
	FLOAT	*AR5++,R1		;GET X POSITION
	STF	R1,*+AR3(LEG_POSX)
	FLOAT	*AR5++,R1		;GET Y POSITION

	TSTB	SC_REVERSE,R5
	BZD	NOTREVERSED
	STF	R1,*+AR3(LEG_POSY)
	FLOAT	*AR5++,R1		;GET Z POSITION
	STF	R1,*+AR3(LEG_POSZ)
	;---->BZD	NOTREVERSED


	;SPECIAL REVERSED CASE
	;
	PUSH	AR7
	TSTB	SC_OVERLAY,R5
	BNZ	ISOVER
	DEC	AR7
ISOVER

	LDF	*+AR7(TB_RVS_POSX),R0	;TRANSLATE BY THE NEGATIVE OFFSET
	ADDF	*+AR3(LEG_POSX),R0	;POSITION (THIS BLOCKS ENDING POSITION)
	STF	R0,*+AR3(LEG_POSX)

	LDF	*+AR7(TB_RVS_POSY),R0
	ADDF	*+AR3(LEG_POSY),R0
	STF	R0,*+AR3(LEG_POSY)

	LDF	*+AR7(TB_RVS_POSZ),R0
	ADDF	*+AR3(LEG_POSZ),R0
	STF	R0,*+AR3(LEG_POSZ)
	POP	AR7
ISOVERA

	LDI	@MATRIXAI,R2
	LDI	AR3,AR2
	ADDI	LEG_POSX,AR2
	LDI	@VECTORAI,R3
	CALL	MATRIX_MUL		;rotation by occurance matrix


	LDI	@VECTORAI,AR0
	LDF	*AR0++,R1
	ADDF	*+AR7(TB_POSX),R1
	STF	R1,*+AR3(LEG_POSX)

	LDF	*AR0++,R1
	ADDF	*+AR7(TB_POSY),R1
	STF	R1,*+AR3(LEG_POSY)

	LDF	*AR0++,R1
	ADDF	*+AR7(TB_POSZ),R1
	STF	R1,*+AR3(LEG_POSZ)

	BU	JOIN_UP

NOTREVERSED
	LDI	@MATRIXAI,R2
	LDI	AR3,AR2
	ADDI	LEG_POSX,AR2
	LDI	R2,R3
	LDI	@VECTORAI,R3
	CALL	MATRIX_MUL		;ROTATION BY OCCURANCE MATRIX


	LDI	@VECTORAI,AR0
	LDF	*AR0++,R1
	ADDF	*+AR7(TB_POSX),R1
	STF	R1,*+AR3(LEG_POSX)

	LDF	*AR0++,R1
	ADDF	*+AR7(TB_POSY),R1
	STF	R1,*+AR3(LEG_POSY)

	LDF	*AR0++,R1
	ADDF	*+AR7(TB_POSZ),R1
	STF	R1,*+AR3(LEG_POSZ)


JOIN_UP	LDF	*AR5++,R2		;LOAD OBJECTS RADIANS
	LDI	*AR5++,R1		;LOAD OBJECT ID (GENV STYLE)


	LDI	R1,R0
	AND	00F00h,R0
	CMPI	0B00h,R0
	BNE	NOTDYNAROAD


	;*******************
	;*******************
	;
	;THIS IS THE CASE WE ARE LOOKING FOR
	;
	;*******************
	;*******************

	;
	;add this element to dynamic fLEX list
	;

	LDI	R1,R3
	LDI	@LEG_SECTIONIDX,R1
	LS	8,R1

	LDI	R3,R0
	AND	0FFh,R0

	TSTB	SC_REVERSE,R5			;in the case of reversed track
	BZ	NOTRVSTRK			;we say the index value is
	SUBRI	255,R0				;255 - index
NOTRVSTRK
	OR	R1,R0
	STI	R0,*+AR3(LEG_ID)

	.if	USEFIXED
	FIX	*+AR3(LEG_POSX),R0
	STI	R0,*+AR3(LEG_POSX)

	FIX	*+AR3(LEG_POSY),R0
	ANDN	1,R0
	OR	R6,R0				;# of LANES
	STI	R0,*+AR3(LEG_POSY)

	FIX	*+AR3(LEG_POSZ),R0
	STI	R0,*+AR3(LEG_POSZ)
	.endif


	DEC	AR3
	CALL	ELEMENT_ADD
	CALL	ELEMENT_GET
	INC	AR3

;	NOP	*AR3++(LEG_SIZE)

NOTDYNAROAD

	SUBI	1,R4
	BGE	L12

ACTIVATE_X


	POP	AR7
	POP	AR5
	POP	AR4
	POP	AR3
	POP	AR2
	POP	AR1
	POP	AR0
	POP	R6
	POP	R5
	POP	R4

	CALL	ELEMENT_DUMP_INTO_LEGMAP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*POST PROCESS LEG MAP
*
*
*
*
GENERATE_LINEAR_DISTANCE:

	.if	USEEXTENDED

	LDL	LEG_MAP,AR2
	FLOAT	*+AR2(LEG_POSX),R6	;STARTING POSITION
	FLOAT	*+AR2(LEG_POSZ),R7

	CLRF	R4			;ACCUMULATED DISTANCE

GLDLP	LDI	*AR2,R0
	CMPI	-1,R0
	BEQ	GLDX

	FLOAT	*+AR2(LEG_POSX),R2	;STARTING POSITION
	FLOAT	*+AR2(LEG_POSZ),R1
	SUBF	R5,R2
	SUBF	R6,R1
	MPYF	R2,R2
	MPYF	R1,R1
	ADDF	R1,R2
	CALL	SQRT

	ADDF	R0,R4
	FIX	R4,R0
	LS	16,R0

	LDI	*+AR2(LEG_POSY),R6
	LS	16,R6
	RS	16,R6

	OR	R0,R6
	STI	R6,*+AR2(LEG_POSY)

	FLOAT	*+AR2(LEG_POSX),R6	;STARTING POSITION
	FLOAT	*+AR2(LEG_POSZ),R7

	NOP	*AR3++(LEG_SIZE)
	BU	GLDLP
GLDX
	.endif

	RETS
*----------------------------------------------------------------------------

