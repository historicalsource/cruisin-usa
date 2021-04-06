	.FILE	"TOTALA.ASM"
*----------------------------------------------------------------------------
*TOTALA.ASM
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
	.include	MACS.EQU
	.include	VUNIT.EQU
	.include	GLOBALS.EQU
	.include	PALL.EQU


NOFIFO	.set	0

AIVI	.word	_AIVI

	.bss	_ACNTL,1
	.bss	_ACMAP,1
	.bss	_ARPS,12
	.bss	_AIVI,4
	.bss	_ADDRL,1



*----------------------------------------------------------------------------
*	rdma(x1,y1,x2,y2,palette,addr)
*
*PARAMETERS
*	AR2	x1
*	R2	y1
*	R3	x2
*	RC	y2
*	RS	palette
*	RE	addr
*
*
_rdma:
	STI	RS,@_ACMAP
	STI	RE,@_ADDRL


	STI	AR2,@_ARPS+0		;AX
	STI	AR2,@_ARPS+9		;DX
	STI	R2,@_ARPS+1		;AY
	STI	R2,@_ARPS+4		;BY
	STI	R3,@_ARPS+3		;BX
	STI	R3,@_ARPS+6		;CX
	STI	RC,@_ARPS+7		;CY
	STI	RC,@_ARPS+10		;DY

	;BU	_stuff_fpga
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*COPY THE CONTENTS OF _ACNTL TO _ADDRL INTO THE FIFO
*
_stuff_fpga:
	PUSH	AR0
	PUSH	AR1
	PUSH	R0
	PUSH	R1
	PUSH	RC
	PUSH	RS
	PUSH	RE

	.if	STATISTICS
	LDI	@ST_POLYGONS,R0
	INC	R0
	STI	R0,@ST_POLYGONS
	.endif


	LDP	@FIFO_STATUS
STUFFWT	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZ	STUFFWT
	SETDP

	FIFO_WT	R0
	LDP	@FIFO_ADDR,AR0
	LS	16,AR0

	LDI	@ASHADOW,AR1
	LDI	*AR1++,R0

	STI	R0,*AR0
 ||	LDI	*AR1++,R0

	STI	R0,*AR0

	LDI	3,RC
	RPTB	LP1
	LDI	*AR1++,R0			;x
	STI	R0,*AR0
	LDI	*AR1++(2),R0			;y
LP1	STI	R0,*AR0

 	LDI	*AR1++,R0			;IVs
 	STI	R0,*AR0
 ||	LDI	*AR1++,R0
 	STI	R0,*AR0
 ||	LDI	*AR1++,R0
 	STI	R0,*AR0
 ||	LDI	*AR1++,R0
 	STI	R0,*AR0
 ||	LDI	*AR1++,R0			;addr
	STI	R0,*AR0

	LDP	@FIFO_INC
	LDI	@FIFO_INC,R0
	SETDP

	CLRI	AR3
	LDI	*AR3,R0

 	POP	RE
	POP	RS
	POP	RC
	POP	R1
	POP	R0
	POP	AR1
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*BITBLIT MODEL AS 2D IMAGE
*
*LOCKUP ON 
*
*
*
*Internal vertices are used to get the image parameters
*
*PARAMETERS
*	AR2	MODEL POINTER
*	R2	POS X
*	R3	POS Y
*	R4	CNTL
*
*	BLTMOD2D_NOPAL
*		RS	PAL
*
*	.word	nV-1|(nP-1)<<16
*	{
*	.word	x,-y,z
*	} * nV
*	{
*	.word	control|pal<<16
*	.word	v1|v2<<8|v3<<16|v4<<24
*	.word	iv01,iv23
*	.word	addr
*	} * NUM_POLYGONS
*
*	This is expected:
*
*	Offset	Contents
*	0	radius
*	1	nV|nP	== 3
*	2	[x y z]
*	4	[x y z]
*	6	[x y z]
*	8	[x y z]
*	10	cntl|pal
*	11	verts
*	12	iv01
*	13	iv23
*	14	addr
*
*
BLTMOD2D_NOPAL:
	PUSHM	R0,R1,R2,R3,R4,R5,R6,R7
	PUSHM	AR0,AR1,AR2,AR3

	BU	SKIPPALENTRY

BLTMOD2D:
	PUSHM	R0,R1,R2,R3,R4,R5,R6,R7
	PUSHM	AR0,AR1,AR2,AR3

	LDI	*+AR2(10),AR0		;IMAGE PAL
	RS	16,AR0
	ADDI	@_PALLISTI,AR0
	LDI	*AR0,RS
	RS	8,RS

SKIPPALENTRY
	STI	R4,@_ACNTL

	.if	DEBUG
	LDI	*+AR2(1),R0
	CMPI	3,R0
	BNE	$		;it should have 4 vertices and 1 polygon
	.endif


	LDI	-16,R0
	LDI	*+AR2(12),R4
	STI	R4,@_AIVI
	LSH	R0,R4,R5
	STI	R5,@_AIVI+1

	LDI	*+AR2(13),R6
	STI	R6,@_AIVI+2
	LSH	R0,R6,R7
	STI	R7,@_AIVI+3

	LDI	*+AR2(14),RE		;IMAGE ADDR


	PUSH	R3
	AND	0FFh,R4
	AND	0FFh,R6
	LDI	R2,AR2
	SUBI	R4,R6		;find xsize
	ADDI	R6,R2,R3	;add xsize to dest

	POP	R2
	RS	8,R7
	AND	0FFh,R7		;find y size
	ADDI	R7,R2,R0
	LDI	R0,RC


	CALL	_rdma

	POPM	AR3,AR2,AR1,AR0
	POPM	R7,R6,R5,R4,R3,R2,R1,R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
BLTMOD2D_DS:
	PUSHM	R2,R3,R4
	ADDI	2,R2
	ADDI	2,R3
	LDI	TM|ZS|NZR,R4
	CALL	BLTMOD2D
	POPM	R4,R3,R2
	CALL	BLTMOD2D
	RETS
*----------------------------------------------------------------------------
	.END
