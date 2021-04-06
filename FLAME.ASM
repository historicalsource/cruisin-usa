	.FILE	"FLAME.ASM"
*----------------------------------------------------------------------------
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED

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

	.data
FLAMEANII	.word	FLAMEANI
FLAME_POSI	.word	FLAME_POS

	.SECT	"THEDATA"
FLAME_POS
	.word	180,87,-450		;Vette
	.word	130,105,-586		;Coope
	.word	140,107,-460		;Missle
	.word	160,70,-460		;Ferrari
	.word	180,87,-450		;JEEP
	.word	190,87,-650		;SBUSP
	.word	160,155,-500		;COPCAR
	
FLAMEANI
	.word	sparc1,sparc3,sparc5,sparc7,sparc9,sparc7
	.word	sparc5,sparc3,sparc1,-1

	.text
*----------------------------------------------------------------------------
* FLAME	PROC
*
FRAME_ON	.set	PDATA+1
CARBODY_MATRIX	.set	PDATA+2

FLAME_PRC:
	LDI	PLYR_C|PLYR_FLAMES_S,AR2
	CALL	OBJ_FIND_FIRST
	BC	FLAME_DIE		;Only one set of flames at a time

	LDI	PLYR_C,AR2
	CALL	OBJ_FIND_FIRST
	BNC	FLAME_DIE		;IF there is no player object then bail.
	LDI	AR0,AR6
	LDI	*+AR0(OCARBLK),AR1
	LDI	*+AR1(CAR_SPIN),R0
	BNZ	FLAME_DIE			;YES, the no flames

	LDI	AR0,AR2
	CALL	GETCARBODY

	STI	AR0,*+AR7(CARBODY_MATRIX)

	LDI	0,R0
	STI	R0,*+AR7(FRAME_ON)	;Reset animation counter
	CALL	OBJ_GET
	BC	FLAME_DIE
	LDI	AR0,AR4			;Left flame

;	LDI	@CHOSEN_VEHICLE,R0
	LDI	@CHOOSENCAR,R0
	MPYI	3,R0
	ADDI	@FLAME_POSI,R0
	LDI	R0,AR0
	FLOAT	*+AR0(X),R1
	FLOAT	*+AR0(Y),R2
	FLOAT	*+AR0(Z),R3
	STF	R1,*+AR4(OVELX)
	STF	R2,*+AR4(OVELY)
	STF	R3,*+AR4(OVELZ)

	LDI	PLYR_C|PLYR_FLAMES_S,R0
	STI	R0,*+AR4(OID)
	

	CALL	OBJ_GET
	BC	FLAME_DIE
	LDI	AR0,AR5			;Right frame
	LDF	PI,R0
	STF	R0,*+AR5(ORADY)
	FLOAT	180,R0
	NEGF	R1			;opposite side
	STF	R1,*+AR5(OVELX)
	STF	R2,*+AR5(OVELY)
	STF	R3,*+AR5(OVELZ)
	LDI	PLYR_C|PLYR_FLAMES_S,R0
	STI	R0,*+AR5(OID)

	LDI	AR4,AR2
	CALL	OBJ_INSERT
	LDI	AR5,AR2
	CALL	OBJ_INSERT

	LDI	9-1,R5
FLAME_ANI_LOOP
	LDI	*+AR6(OCARBLK),AR1
	LDI	*+AR1(CAR_SPIN),R0
	BNZ	FLAME_ANIX			;YES, the kill the flames

	LDI	*+AR7(CARBODY_MATRIX),AR2
	LDI	AR6,R2
	ADDI	OMATRIX,R2
	LDI	@MATRIXAI,R3
	CALL	CONCATMATV

	LDI	@MATRIXAI,AR3
	LDI	AR4,AR0
	LDI	*+AR7(FRAME_ON),IR0
	LDI	@FLAMEANII,AR1
	CALL	animate_child

	LDI	@MATRIXAI,AR3
	LDI	*+AR7(FRAME_ON),IR0
	LDI	@FLAMEANII,AR1
	LDI	AR5,AR0
	CALL	animate_child
	STI	R0,*+AR7(FRAME_ON)

	SLEEP	1
	SUBI	1,R5
	BP	FLAME_ANI_LOOP
FLAME_ANIX
	LDI	PLYR_C|PLYR_FLAMES_S,AR2
	CALL	OBJ_FIND_FIRST
	BNC	FLANX1
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	BR	FLAME_ANIX
FLANX1

FLAME_DIE
	DIE
*----------------------------------------------------------------------------
*Input
*	AR0 = object to position and ani
*	    OVELX/Y/Z = offset from parent
*	AR6 = object to position reletive to
*	AR1 = Animation list
*	IR0  = Frame on
*OUTPUT
*	IR0  = Next frame
*TRASHES	AR2,R1,R2,R3

animate_child:
;Set the Frame
set_frame
	LDI	*+AR1(IR0),R1
	LDIN	0,IR0
	BN	set_frame
	ADDI	1,IR0
	STI	R1,*+AR0(OROMDATA)
	PUSH	IR0
;Set the position reletive to the parent object.
	LDI	AR3,R2
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	CPYMAT

	LDI	AR0,AR2		;rotate the position reletive to parent
	ADDI	OVELX,AR2
	LDI	AR0,R2			;Source 3X3
	ADDI	OMATRIX,R2
	LDI	AR0,R3			;Dest 1X3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL

	LDF	*+AR6(OPOSX),R2		;Set the position
	ADDF	*+AR0(OPOSX),R2
	STF	R2,*+AR0(OPOSX)

	LDF	*+AR6(OPOSY),R2
	ADDF	*+AR0(OPOSY),R2
	STF	R2,*+AR0(OPOSY)

	LDF	*+AR6(OPOSZ),R2
	ADDF	*+AR0(OPOSZ),R2
	STF	R2,*+AR0(OPOSZ)

	LDI	@MATRIXBI,AR2
	LDI	AR0,R2
	ADDI	ORADX,R2
	CALL	FIND_MATRIX

	LDI	AR3,AR2
	LDI	@MATRIXBI,R2
	LDI	AR0,R3
	ADDI	OMATRIX,R3
	CALL	CONCATMATV

	POP	R0
	RETS

*----------------------------------------------------------------------------
*CALLED BY ZSORTWT in obj.asm just after the players car is linked in.
*PUTS THE FLAMES JUST BEHIND THE PLAYERS CAR

FLAMESORT:
	LDI	@OACTIVE,AR0
	CMPI	0,AR0
	BEQ	FLMSORTX		;NO LIST... NO GO
FLMSORT_LOOP
	LDI	PLYR_C|PLYR_FLAMES_S,R1
	CALL	FIND_NEXT_OBJ
	BC	FLMSORTX
	LDI	AR0,AR4
	CALL	FIND_NEXT_OBJ
	BC	FLMSORTX
	LDI	AR0,AR5

	LDI	*+AR4(OFLAGS),R0	;SAVE the flages
	LDI	*+AR5(OFLAGS),R1	;SAVE the flages
	LDI	AR4,AR2
	CALL	OBJ_PULL
	LDI	AR5,AR2
	CALL	OBJ_PULL
	STI	R0,*+AR4(OFLAGS)	;RESTORE the flags
	STI	R1,*+AR5(OFLAGS)	;RESTORE the flags

	LDI	PLYR_C,AR2
	CALL	OBJ_FIND_FIRST
	BNC	FLMSORTX		;NO PLAYER?

	STI	AR5,*AR4		;Link flame2 to flame1

	LDI	*AR0,R0			;Get link to next object
	STI	AR4,*AR0		;link the flames to the players object
	STI	R0,*AR5			;link back in the object behind the player

FLMSORTX
	RETS



*----------------------------------------------------------------------------
*FIND THE MATRIX IN THE DYNALIST OF THE CAR POINTED TO BY AR2
*INPUT	AR2 = CARS OBJECT
*OUTPUT AR0 = MATRIX OF THE BODY
* SCRAMBLES R0,R1

GETCARBODY:
	LDI	*+AR2(ODYNALIST),R0
	SLOCKON	Z,"UTIL\CARPROC   dynamic objects not found"
FBLOOP
	LDI	R0,AR0
	LDI	*+AR0(DYNAFLAG),R1
	BZ	FOUND_BODY		;0 = car body
	LDI	*AR0,R0
	BR	FBLOOP
FOUND_BODY
	ADDI	DYNAMATRIX,AR0
	RETS

FIND_NEXT_OBJ:
	PUSH	R0
	PUSHF	R0
	PUSH	AR5

	LDI	*AR0,AR5

OFN	LDI	AR5,R0
	LDI	R0,AR0
	BZ	OFNX		;NONE FOUND. This routine is passive
	LDI	*AR0,AR5
	LDI	*+AR0(OID),R0
	CMPI	R1,R0
	BNE	OFN
OFNX
	CLRC
	CMPI	0,AR0
	BNE	OFNX1
	SETC
OFNX1
	POP	AR5
	POPF	R0
	POP	R0
	RETS

	
*----------------------------------------------------------------------------
	.END
