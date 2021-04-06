	.FILE	"HEADS.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	MACS.EQU
	.include	MPROC.EQU
	.include	OBJ.EQU
	.include	VUNIT.EQU
	.include	CMOS.EQU
	.include	SYSID.EQU
	.include	SYS.EQU
	.include	GLOBALS.EQU
	.include	SNDTAB.EQU
	.include	PALL.EQU
	.include	OBJECTS.EQU
	.include	TEXT.EQU


HEADTYPE	.set	88D0h


*----------------------------------------------------------------------------
TEXTDELER:


	LDI	@TEXT_ACTIVEI,AR4
TEXTDELERLP
	LDI	*AR4,R0
	BZ	TXTXX
TTEST	LDI	R0,AR4

	LDF	*+AR4(TEXT_POSY),R0
	CMPF	-25,R0
	BGT	TEXTDELERLP


	LDI	*AR4,R7

	LDI	@TEXT_ACTIVEI,R1	;get free list pointer
DELLP	LDI	R1,AR1
	LDI	*AR1,R1
	.if	DEBUG
	BZ	$			;lockup on end of list found
	.endif

	CMPI	R1,AR4
	BNE	DELLP

	LDI	*AR4,R1		
	STI	R1,*AR1			;LINK AROUND

	LDI	@TEXT_FREE_COUNT,R1
	INC	R1
	STI	R1,@TEXT_FREE_COUNT

	LDI	@TEXT_FREEI,AR1		;get free list pointer
	LDI	*AR1,R1
	STI	R1,*AR4
	STI	AR4,*AR1
	LDI	R7,R0
	BZ	TXTXX
	BU	TTEST

TXTXX
	SLEEP	1
	BU	TEXTDELER
*----------------------------------------------------------------------------


HEADS	.word	jeno
	.word	marc
	.word	pet
	.word	xion
	.word	ted
	.word	matt
	.word	vince
	.word	carl
	.word	glen
	.word	ken
	.word	eric
	.word	-1

*----------------------------------------------------------------------------
*
*
*
VANITY_HEADS:
	SETDP

	LDI	@CAMERAPOSI,AR6
	CLRF	R0
	STF	R0,*+AR6(X)
	STF	R0,*+AR6(Y)
	STF	R0,*+AR6(Z)


	LDL	theheads_PALETTES,AR2
	CALL	alloc_section


	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	CALL	FIFO_RESET

	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD
	LDL	_SECtheheads,AR2
	CALL	LOAD_SECTION_REQ


	LDL	HEADS,AR5
;	CLRF	R6
	LDF	PI,R6


VANHDLP
	LDI	*AR5++,R0
	BN	VHIX
	LDI	R0,AR2
	CALL	OBJ_GETE


	LDF	R6,R2
;	CALL	_SINE
	PUSH	AR0
	CALL	_HPsin
	POP	AR0
	MPYF	130,R0
	STF	R0,*+AR0(OPOSX)

	LDF	R6,R2
;	CALL	_COSI
	PUSH	AR0
	CALL	_HPcos
	POP	AR0
	MPYF	130,R0
	STF	R0,*+AR0(OPOSY)

	FLOAT	368,R0
	STF	R0,*+AR0(OPOSZ)
	STF	R6,*+AR0(ORADY)


	LDI	AR0,AR2
	CALL	OBJ_INSERT

	SUBF	0.571,R6
	B	VANHDLP


VHIX
	
;	DIE
	
VANITY_HEADS_LP
	LDI	@OACTIVEI,AR0

VOLP
	LDI	*AR0,R0
	BZ	VOSLP
	LDI	R0,AR0
	LDF	*+AR0(ORADY),R2
	ADDF	0.01,R2
	STF	R2,*+AR0(ORADY)

	LDF	R2,R6

	CALL	_SINE
	MPYF	130,R0
	STF	R0,*+AR0(OPOSX)

	LDF	R6,R2
	CALL	_COSI
	MPYF	130,R0
	STF	R0,*+AR0(OPOSY)


	BU	VOLP

VOSLP	SLEEP	1
	BU	VANITY_HEADS_LP
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SET18FONTDS_WHITE:
	CALL	SET18FONTDS
	.globl	font18_white
	LDL	font18_white,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)
	STI	R0,*+AR1(TEXT_PAL)
	RETS
*----------------------------------------------------------------------------

	


	.bss	YINCREMENT,1
*----------------------------------------------------------------------------
	.globl	VANITY,VANITY_SUB
VANITY:
	JSRP	VANITY_SUB
	BR	CYCLE_ATTR


VANITY_SUB:
	LDI	MATTR,R0
	STI	R0,@_MODE

	LDI	1,R0
	STI	R0,@COINOFF
	CLRI	R0
	STI	R0,@BGNDCOLA
	STI	R0,@NOAERASE


	LDI	@CAMERAPOSI,AR6
	CLRF	R2
	STF	R2,*+AR6(X)
	STF	R2,*+AR6(Y)
	STF	R2,*+AR6(Z)
	LDI	@CAMERARADI,AR6
	STF	R2,*+AR6(X)
	STF	R2,*+AR6(Y)
	STF	R2,*+AR6(Z)
	LDI	@CAMERAMATRIXI,AR2
	CALL	FIND_YMATRIX

	SLEEP	1

	CREATE	VANITY_HEADS,HEADTYPE
	

	CREATE	TEXTDELER,HEADTYPE
;	CREATE	LOGO_WATCH,UTIL_C

	LDL	SET18FONTDS_WHITE,R0
	STI	R0,@FONTUSED

	LDF	24,R0
	STF	R0,@YINCREMENT

	FLOAT	420,R6
	LDI	2,AR5
	LDI	@THANKS_TABLEI,AR4
DTLP2
	ADDF	@YINCREMENT,R6		;ADDF	24,R6

KKPD	FLOAT	402,R0
	CMPF	R0,R6
	BLT	JJDDA
	SLEEP	1
	SUBF	1,R6
	BU	KKPD
JJDDA

	LDI	*AR4++,R7	;number of entries

	CMPI	10,R7
	BNE	NOT10
	LDI	*AR4++,R0
	STI	R0,@FONTUSED

	LDF	10,R0
	STF	R0,@YINCREMENT

	BU	KKPD
NOT10

	CMPI	8,R7
	BNE	NOTSPEC8
	FLOAT	*AR4++,R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT
	BU	DTLP2
NOTSPEC8


	CMPI	7,R7
	BNE	NOTSPEC7
	FLOAT	*AR4++,R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT
	CALL	RIGHTEM
	BU	DTLP2
NOTSPEC7



	CMPI	4,R7
	BNE	NOTSPEC4

	LDI	1,R0
	STI	R0,@TEXT_FREEZE
	SLEEP	60
	CLRI	R0
	STI	R0,@TEXT_FREEZE
	BU	KKPD

NOTSPEC4

	CMPI	99,R7
	BNE	NOTSPEC99

	FLOAT	*AR4++,R2

	FLOAT	(256-600),R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT
	CALL	CENTEREM

	PUSH	AR4
	PUSH	AR5
	LDI	AR0,AR4
	LDI	AR1,AR5
	CREATE	KRIS,HEADTYPE
	POP	AR5
	POP	AR4
	BU	DTLP2

KRIS:	SLEEP	1

	LDF	*+AR4(TEXT_POSX),R0
	FLOAT	259,R1
	SUBF	R0,R1
	MPYF	0.05,R1
	ADDF	R1,R0
	STF	R0,*+AR4(TEXT_POSX)

	LDF	*+AR5(TEXT_POSX),R0
	FLOAT	256,R1
	SUBF	R0,R1
	MPYF	0.05,R1
	ADDF	R1,R0
	STF	R0,*+AR5(TEXT_POSX)
	BU	KRIS



NOTSPEC99

	CMPI	3,R7
	BNE	NOTSPEC3

	FLOAT	*AR4++,R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT
	CALL	CENTEREM



	PUSH	AR4
	PUSH	AR5
	LDI	AR0,AR4
	LDI	AR1,AR5
	CREATE	ADAMSTOPRIBYL,HEADTYPE
	POP	AR5
	POP	AR4
	BU	DTLP2

CHISPRIB	SPTR	"CHRISTINE PRIBYL"
ADAMSTOPRIBYL:

	SLEEP	1
	LDF	*+AR4(TEXT_POSY),R0
	FLOAT	250,R1
	CMPF	R1,R0
	BGT	ADAMSTOPRIBYL

	LDI	@CHISPRIB,R0
	STI	R0,*+AR4(TEXT_PTR)
	STI	R0,*+AR5(TEXT_PTR)
	DIE


NOTSPEC3
	CMPI	-1,R7
	BEQ	WTD55
	CMPI	0,R7
	BNE	NOT0

	BU	DTLP2

NOT0
	CMPI	2,R7
	BEQ	TWO

	;ONE
	
	FLOAT	*AR4++,R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT
	CALL	CENTEREM

	BU	DTLP2

TWO
	FLOAT	*AR4++,R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT


	FLOAT	*AR4++,R2
	LDF	R6,R3
	LDI	*AR4++,AR2
	CALL	GETT
	CALL	RIGHTEM
	BU	DTLP2

WTD55

	LDI	HEADTYPE,R0
	LDI	-1,R1
	CALL	PRC_KILLALL
	RETP
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SUBROUTINE FOR THE ABOVE
*
*
*PARAMETERS
*	AR2	STRING
*	R2	X
*	R3	Y
*	R4	FONT
*RETURNS
*	AR0	S1
*	AR1	S2
*

	.bss	FONTUSED,1
;	LDL	SET18FONTDS
;	LDL	SETFIXEDFONTDS
GETT:
	LDI	9999,RC
	CALL	TEXT_ADDDS

	LDF	-1,R0
	STF	R0,*+AR0(TEXT_VELY)
	STF	R0,*+AR1(TEXT_VELY)

	LDI	@FONTUSED,R0
	CALLU	R0
	RETS

CENTEREM:
	LDI	*+AR0(TEXT_COLOR),R0
	OR	TXT_CENTER,R0
	STI	R0,*+AR0(TEXT_COLOR)
	LDI	*+AR1(TEXT_COLOR),R0
	OR	TXT_CENTER,R0
	STI	R0,*+AR1(TEXT_COLOR)
	RETS

RIGHTEM:
	LDI	*+AR0(TEXT_COLOR),R0
	OR	TXT_RIGHT,R0
	STI	R0,*+AR0(TEXT_COLOR)
	LDI	*+AR1(TEXT_COLOR),R0
	OR	TXT_RIGHT,R0
	STI	R0,*+AR1(TEXT_COLOR)
	RETS
*----------------------------------------------------------------------------

	romdata
	.string	"DONT DISASSEMBLE MY CODE!!!  YOU WONT"
	.string	"FIND ANYTHING BUT BUGS AND PULLED OUT HAIR"
	.string	"AND MAYBE SOME FERRET TURDS"
	.string	"LIVE LONG AND ENJOY LIFE.  WE ONLY LIVE ONCE,"
	.string	"AND THERES FAR TOO MUCH CODE LEFT TO BE WRITTEN"
	.string	"ERIC L PRIBYL   AUG 15,1994"
	.text


	.include	VANTAB.INC

