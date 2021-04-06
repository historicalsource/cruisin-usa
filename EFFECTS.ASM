	.FILE	"EFFECTS.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	MACS.EQU
	.include	MPROC.EQU
	.include	OBJ.EQU
	.include	SYSID.EQU
	.include	GLOBALS.EQU
	.include	OBJECTS.EQU


*----------------------------------------------------------------------------
*ADVANCED FEATURES
*
*it would be best to do open and close via the same process
*also, sideways wipes  //  or \\  up, down, left or right can be specified
*via on word ala:
*
*	SCW_OPEN	.set	0
*	SCW_CLOSE	.set	1
*	SCW_L		.set	10h	;these specifiy the 
*	SCW_R		.set	20h	;single panels
*	SCW_T		.set	40h	;
*	SCW_B		.set	80h	;
*
*for convience:
*	SCW_OPEN_H	.set	030h
*	SCW_CLOSE_H	.set	031h
*	SCW_OPEN_V	.set	0C0h
*	SCW_CLOSE_V	.set	0C1h
*
*also can be added:	(S = straight instead of diagonal)
*
*	SCW_LS		.set	12h	;these specifiy the 
*	SCW_RS		.set	22h	;single panels
*	SCW_TS		.set	42h	;
*	SCW_BS		.set	82h	;
*
*
*these parameters would be encoded into AR2 when calling SCREEN_WIPE
*and from there it would be moved to AR6, and checked each tik.
*


MONKEYOBJRVI	.word	mnkrv
MONKEYOBJLVI	.word	mnklv
MONKEYOBJUHI	.word	mnkuh
MONKEYOBJLHI	.word	mnklh



	.bss	SCREENWIPE_DONE,1

*----------------------------------------------------------------------------
SCREENWIPE_OPEN:
	CLRI	R0
	STPI	R0,@SCREENWIPE_DONE
	CREATEC	SCREENWIPE_OPEN_PRC,UTIL_C|MONKEY_T
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SCREENWIPE_CLOSE:
	CLRI	R0
	STPI	R0,@SCREENWIPE_DONE
	CREATE	SCREENWIPE_CLOSE_PRC,UTIL_C|MONKEY_T
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SCREENWIPE_OPEN_PRC_FAST:

	LONGROUT
	LDF	1.9,R0
	BR	L55

	.text

SCREENWIPE_OPEN_PRC:

	LONGROUT

	LDF	1.1,R0
L55	STF	R0,*+AR7(PDATA+7)

	CALL	GET_EFFECTS_OBJS


	SLEEP	19

	LDI	64,AR5
	CLRF	R6
	LDF	2,R7
SWCL1

	MPYF	*+AR7(PDATA+7),R7
;	MPYF	1.1,R7

	ADDF	0.2,R6
	LDF	R6,R2
	LDPI	@MATRIXAI,AR2
	CALL	FIND_ZMATRIX


	LDI	*+AR7(PDATA),AR0
	LDF	*+AR0(OUSR1),R0
	ADDF	R7,R0
	STF	R0,*+AR0(OUSR1)

	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL

	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	




	LDI	*+AR7(PDATA+1),AR0
	LDF	*+AR0(OUSR1),R0
	SUBF	R7,R0
	STF	R0,*+AR0(OUSR1)

	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDPI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL

	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	



	LDI	*+AR7(PDATA+2),AR0
	LDF	*+AR0(OUSR2),R0
	SUBF	R7,R0
	STF	R0,*+AR0(OUSR2)


	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL
	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	




	LDI	*+AR7(PDATA+3),AR0
	LDF	*+AR0(OUSR2),R0
	ADDF	R7,R0
	STF	R0,*+AR0(OUSR2)

	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL
	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	


	SLEEP	1
	DBU	AR5,SWCL1


	LDI	*+AR7(PDATA),AR2
	CALL	OBJ_DELETE
	LDI	*+AR7(PDATA+1),AR2
	CALL	OBJ_DELETE
	LDI	*+AR7(PDATA+2),AR2
	CALL	OBJ_DELETE
	LDI	*+AR7(PDATA+3),AR2
	CALL	OBJ_DELETE


	LDI	1,R0
	STI	R0,@SCREENWIPE_DONE
	DIE

	END_LONGROUT
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
SCREENWIPE_CLOSE_PRC:

	LONGROUT

	CALL	GET_EFFECTS_OBJS

	LDI	100,AR5

	LDF	12.8,R6
	LDLFH	28530.66038,R7


SWCL1C

	MPYF	0.91,R7

	SUBF	0.2,R6
	LDF	R6,R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_ZMATRIX


	LDI	*+AR7(PDATA),AR0
	STF	R7,*+AR0(OUSR1)

	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL

	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	




	LDI	*+AR7(PDATA+1),AR0
	NEGF	R7,R0
	STF	R0,*+AR0(OUSR1)

	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL

	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	



	LDI	*+AR7(PDATA+2),AR0
	NEGF	R7,R0
	STF	R0,*+AR0(OUSR2)


	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL
	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	




	LDI	*+AR7(PDATA+3),AR0
	STF	R7,*+AR0(OUSR2)


	LDI	AR0,AR2
	ADDI	OUSR1,AR2
	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	CALL	MATRIX_MUL
	LDI	AR0,AR1
	ADDI	OMATRIX,AR1
	LDI	R2,AR0
	LDI	8,RC
	CALL	MEMCPY	


	SLEEP	1
	DBU	AR5,SWCL1C

	LDI	1,R0
	STI	R0,@SCREENWIPE_DONE
	DIE

	END_LONGROUT
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
GET_EFFECTS_OBJS:

	LONGROUT


	LDI	@MONKEYOBJRVI,AR1
	CALL	OBJ_GET
	LDI	AR0,AR4
	LDLH	O_3DROT|O_NOUROT|O_NOUNIV,R0
	STI	R0,*+AR4(OFLAGS)
	STI	AR0,*+AR7(PDATA)
	STI	AR1,*+AR4(OROMDATA)
	FLOAT	368,R0
	STF	R0,*+AR4(OPOSZ)
	LDI	AR4,AR2
	CALL	OBJ_INSERTP

	LDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OUSR1)
	LDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OUSR2)
	LDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OUSR3)


	LDI	@MONKEYOBJLVI,AR1
	CALL	OBJ_GET
	LDI	AR0,AR4
	LDLH	O_3DROT|O_NOUROT|O_NOUNIV,R0
	STI	R0,*+AR4(OFLAGS)
	STI	AR0,*+AR7(PDATA+1)
	STI	AR1,*+AR4(OROMDATA)
	FLOAT	368,R0
	STF	R0,*+AR4(OPOSZ)
	LDI	AR0,AR2
	CALL	OBJ_INSERTP

	LDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OUSR1)
	LDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OUSR2)
	LDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OUSR3)



	LDI	@MONKEYOBJUHI,AR1
	CALL	OBJ_GET
	LDI	AR0,AR4
	LDLH	O_3DROT|O_NOUROT|O_NOUNIV,R0
	STI	R0,*+AR4(OFLAGS)
	STI	AR0,*+AR7(PDATA+2)
	STI	AR1,*+AR4(OROMDATA)
	FLOAT	368,R0
	STF	R0,*+AR4(OPOSZ)
	LDI	AR4,AR2
	CALL	OBJ_INSERTP

	LDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OUSR1)
	LDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OUSR2)
	LDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OUSR3)




	LDI	@MONKEYOBJLHI,AR1
	CALL	OBJ_GET
	LDI	AR0,AR4
	LDLH	O_3DROT|O_NOUROT|O_NOUNIV,R0
	STI	R0,*+AR4(OFLAGS)
	STI	AR0,*+AR7(PDATA+3)
	STI	AR1,*+AR4(OROMDATA)
	FLOAT	368,R0
	STF	R0,*+AR4(OPOSZ)
	LDI	AR4,AR2
	CALL	OBJ_INSERTP


	LDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OUSR1)
	LDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OUSR2)
	LDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OUSR3)
	RETS

	END_LONGROUT
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*MEMCPY
*
*PARAMETERS
*	AR0	SOURCE POINTER
*	AR1	DEST POINTER
*	RC	LENGTH -1
*
MEMCPY:
	LONGROUT
	PUSH	AR0
	PUSH	AR1
	PUSH	R0

	RPTB	MEMCPYL
	LDI	*AR0++,R0
MEMCPYL	STI	R0,*AR1++

	POP	R0
	POP	AR1
	POP	AR0
	RETS
	END_LONGROUT
*----------------------------------------------------------------------------
	.END
