	.FILE	"FONT1A.ASM"
*----------------------------------------------------------------------------
*FONT1A.ASM
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
*PACKED FONT STYLE CPU PLOTTING
*(DIAGNOSTICS ONLY!  NOT DURING ASIC OPERATION)
*
*
	.include	C30.EQU
	.include	VUNIT.EQU
	.include	MACS.EQU
	.include	TEXT.EQU


	;ref
	.globl	DIV_I30,MOD_I30		;ROUTS.ASM
	.globl	ACTIVE_SCREEN		;start of active screen (not visual screen)
	.globl	_font1
	.globl	PRINTER_LOG_SYMBOLIC
	.globl	COMMINTM

	;def
	.globl	_ftoa,_itoa,_pixel,_outtextxyc,_fill,_itoaLZ
	.globl	HEX2ASC


_font1I		.word	_font1


*----------------------------------------------------------------------------
ENABLEGIE	RETI
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
POINT	.string	".",0
	.bss	ftoa_tmp,2
_ftoa:
	PUSH	R0
	PUSH	R2
	PUSH	AR2

	PUSH	AR2
	PUSHFL	R2
	FIX	R2
	CALL	_itoa
	LDL	POINT,AR1
	LDI	AR2,AR0
	CALL	STRCAT

	POPFL	R2
	LDL	ftoa_tmp,AR2
	FIX	R2,R0
	FLOAT	R0
	SUBF	R0,R2
	FIX	R2
	MPYI	100,R2
	CALL	_itoa
	LDI	AR2,AR1
	POP	AR0
	CALL	STRCAT
	POP	AR2
	POP	R2
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*INTEGER TO ASCIZ (PACKED)
*
*PARAMETERS
*	AR2	STRING SPACE
*	R2	NUMBER
*RETS
*	AR2	POINTING TO SPACE
*	R0	HAVING THE SHIFT COUNT
*
*
*INTEGER TO ASCIZ WITH LEADING ZERO
_itoaLZ:
	PUSH	R0			;this entry includes a leading zero
	PUSH	R1			;if the value is 9 or less
	PUSH	R2			;
	PUSH	R3			;
	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR7

	PUSH	R6
	PUSH	R7
	CLRI	R7			;flag if negative
	CMPI	0,R2
	BZD	ISZERO2
	LDILT	1,R7
	ABSI	R2
	CLRI	R3

	CMPI	9,R2
	BGT	itoa1
	LDI	1,AR7

	BU	itoa1

_itoa:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR7
	PUSH	R6
	PUSH	R7


	CLRI	R7			;flag if negative
	CMPI	0,R2
	BZD	ISZERO
	LDILT	1,R7

	CLRI	AR7

	ABSI	R2
	CLRI	R3
itoa1	LDI	10,R1			;this loop generates the ASCII
	LDI	R2,R0			;pieces and pushes them on the stack
	CALL	MOD_I30

	OR	30h,R0
	PUSH	R0
	INC	R3

	LDI	10,R1
	LDI	R2,R0
	CALL	DIV_I30
	LDI	R0,R2
	BGT	itoa1


	CMPI	1,AR7
	BNE	NOLEADINGZERO
	LDI	30h,R0
	PUSH	R0
	INC	R3
NOLEADINGZERO


	CLRI	R6			;this loop pops the ASCII pieces off
	CLRI	R1			;the stack and packs them into the
	CMPI	0,R7			;destination space
	BEQ	NOTNEG			;check sign flag
	LDI	MINUS_CHAR,R1
	ADDI	8,R6
NOTNEG

LOOP2	POP	R0   
	LSH	R6,R0
	OR	R0,R1
	ADDI	8,R6
	CMPI	32,R6
	BLT	DALOP
	STI	R1,*AR2++
	CLRI	R1
	CLRI	R6

DALOP	DEC	R3
	BGT	LOOP2

	LDI	0,R0			;NULL terminator
	LSH	R6,R0
	OR	R0,R1
	STI	R1,*AR2

	LDI	R6,R0

itoaX
	POP	R7
	POP	R6
	POP	AR7
	POP	AR2
	POP	AR1
	POP	AR0
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS

ISZERO2
	BUD	itoaX
	LDI	03030h,R0			;case when number is zero
	STI	R0,*AR2
	LDI	16,R0
	;---->	BUD	itoaX

ISZERO
	BUD	itoaX
	LDI	030h,R0			;case when number is zero
	STI	R0,*AR2
	LDI	8,R0
	;---->	BUD	itoaX
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*HEX2ASC	CONVERT HEX TO ASCII
*
*PARAMETERS
*	R2	NUMBER
*	AR2	BUFFER
*
*
HEX2ASC:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR7
	PUSH	R6
	PUSH	R7


	CMPI	0,R2
	BZD	ISZEROH

;	LS	16,R2
;	RS	16,R2
	CLRI	R3
htoa1	
	LDI	R2,R0
	AND	0Fh,R0
	CMPI	10,R0
	BLT	DDJ
	ADDI	'A'-10,R0
	BU	JJK
DDJ	ADDI	30h,R0

JJK	PUSH	R0
	INC	R3
	RS	4,R2
	BGT	htoa1

	CLRI	R6			;this loop pops the ASCII pieces off
	CLRI	R1			;the stack and packs them into the

LOOP2H	POP	R0   
	LSH	R6,R0
	OR	R0,R1
	ADDI	8,R6
	CMPI	32,R6
	BLT	HDALOP
	STI	R1,*AR2++
	CLRI	R1
	CLRI	R6

HDALOP	DEC	R3
	BGT	LOOP2H

	LDI	0,R0			;NULL terminator
	LSH	R6,R0
	OR	R0,R1
	STI	R1,*AR2

	LDI	R6,R0

htoaX
	POP	R7
	POP	R6
	POP	AR7
	POP	AR2
	POP	AR1
	POP	AR0
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
ISZEROH
	BUD	htoaX
	LDI	030h,R0			;case when number is zero
	STI	R0,*AR2
	LDI	8,R0

*----------------------------------------------------------------------------






*----------------------------------------------------------------------------
*fill(int x1,int y1,int x2,int y2,int color)
*
*PARAMETERS
*	AR2	X1
*	R2	Y1
*	R3	X2
*	RC	Y2
*	RS	COLOR
*
*
_fill:
	PUSH	AR2
FILLLP1
	PUSH	R3
	LDI	RS,R3

	CALL	_pixel

	POP	R3
	INC	AR2
	CMPI	AR2,R3
	BGE	FILLLP1
	POP	AR2
	PUSH	AR2

	INC	R2
	CMPI	R2,RC
	BGE	FILLLP1
	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*OUTPUT TEXT STRING AT X,Y PACKED CHARACTERS
*void	outtextxyc(Pchar *,int x,int y,int color_pal);
*
*PARAMETERS
*	AR2	STRING
*	R2	X LOC
*	R3	Y LOC
*	RC	COLOR
*
*	print a text string with the .string (packed)
*
*CLOBBERS	RS,RE,RC
*
_outtextxyc:
	PUSH	R4
	PUSH	R5

	LDI	3,RS
	CLRI	RS
OLP	CMPI	-32,RS
	BNE	REGLP
	CLRI	RS
	NOP	*AR2++
REGLP
	LDI	*AR2,AR0
	LSH	RS,AR0
	SUBI	8,RS
	AND	0FFh,AR0
	CMPI	0,AR0
	BZ	oucX
	CMPI	' ',AR0
	BEQ	NXTCHAR
	SUBI	'(',AR0			;the start of the font

	;NOW PLOT OT THE CHARACTER
	MPYI	7,AR0			;index to character
	ADDI	@_font1I,AR0		;pointing to font data


	LDI	7,R5			;Y count
OUTRLP
	LDI	*AR0++,R1
	LS	24,R1
	LDI	8,R4
LOOP1	ASH	1,R1
	BNC	NPLOT

	PUSH	AR2
	PUSH	R2
	PUSH	R3

	LDI	R2,AR2
	LDI	R3,R2
	LDI	RC,R3
	CALL	_pixel

	POP	R3
	POP	R2
	POP	AR2


NPLOT	INC	R2			;advance to next pixel
	DEC	R4
	BGT	LOOP1

	SUBI	8,R2			;reset X position
	INC	R3			;increment Y position

	DEC	R5
	BGT	OUTRLP

	SUBI	7,R3			;reset Y position
NXTCHAR	ADDI	8,R2			;to next X position
	BU	OLP
	
oucX
	POP	R5
	POP	R4
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PIXEL ROUTINE
*
*NOTE :	other routines rely on the spec being exactly as they are specified 
*here. DO NOT TRASH OTHER REGISTERS!!!
*
*PARAMETERS
*	AR2	X COORD
*	R2	Y COORD
*	R3	COLOR
*
*R3	: [ xxxxPPCC ]
*	PP   PALETTE CODE
*	CC   COLOR CODE
*
*CLOBBERS	R0,AR1
*
_pixel:
	PUSH	AR1
	PUSH	AR2
	PUSH	R2

	PUSH	IE

	LDP	@COMMINTM
	LDI	@COMMINTM,IE
	SETDP

	LDP	@CPU_WS
	LDI	HARD_WS,AR1
	AND	0DFFFh,ST		;turn off GIE.
	POP	IE

	STI	AR1,@CPU_WS		;SET WAITSTATE MODE
	SETDP

	LDI	0,AR1			;DUMMY READ ADDR
	LSH	9,R2
	ADDI	@ACTIVE_SCREEN,AR2	;GET CURRENT SCREEN PAGE
	ADDI	R2,AR2

	LDP	@CPU_WS
	STI	R3,*AR2			;store to screen
	LDI	*AR1,R2			;DUMMY READ
	LDI	SOFT_WS,R2
	STI	R2,@CPU_WS
	SETDP

	CALL	ENABLEGIE

	POP	R2
	POP	AR2
	POP	AR1
	RETS
*----------------------------------------------------------------------------
	.END
