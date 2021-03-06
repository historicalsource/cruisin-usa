	.FILE	"ATTRACTA.ASM"
*----------------------------------------------------------------------------
*ATTRACT MODE
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
*

	.include	MPROC.EQU
	.include	MACS.EQU
	.include	OBJ.EQU
	.include	OBJECTS.EQU
	.include	GLOBALS.EQU
	.include	SYS.EQU
	.include	TEXT.EQU
	.include	VUNIT.EQU
	.include	CMOS.EQU
	.include	SNDTAB.EQU



	.text
NOVANITY	.set	1

*----------------------------------------------------------------------------
startthey	.set	4.18894205	;-deg(10)
startthez	.set	0.087266462	; deg(5)
CREATED_DCS	.set	PDATA+1
DECOMP_COUNT	.set	PDATA+1

*----------------------------------------------------------------------------
*AR6 is set by the creator of this routine. 0= play dcs logo sound 1=don't play
*
_MIDWAYSPIN:
	LDI	0,AR6
	LDI	@_ATTR_MODE,R0
	CMPI	-2,R0
	BNE	NO_NINTENDO
	LDI	@ATTRWAVE,R0
	BNE	NO_NINTENDO
	READADJ	ADJ_ATTRACT_MODE_SOUND
	CMPI	0,R0
	BEQ	NO_NINTENDO

	READADJ	ADJ_VOLUME		;make sure volume correct
	LDI	R0,R1
	CALL	SET_MASTER_VOL


	;if COMM on and SLAVE then NO NINTENDO
	;
	LDI	@DIPRAM,R0
	TSTB	DIP_COMMP,R0
	BNZ	DOMUS
	TSTB	CMDP_MASTER,R0
	BNZ	NO_NINTENDO
DOMUS

	LDI	890,AR6			;Length of sound
	SOND1	NINTENDO_SND

NO_NINTENDO
	CALL	ULTRA_LOGO

	LDI	0,R0
	STI	R0,*+AR7(DECOMP_COUNT)
;	STI	R0,*+AR7(CREATED_DCS)
	LDI	0,R0
	STI	R0,@BGNDCOLA

	LDP	@_CAMERAPOS+Y
	FLOAT	-2780,R0
	STF	R0,@_CAMERAPOS+Y
	SETDP

	LDL	midway,AR2
	CALL	OBJ_GETE
	.if	DEBUG
	BC	$
	.endif
	LDI	AR0,AR4

	CLRF	R0
	STF	R0,*+AR4(OPOSX)
;	FLOAT	-480,R0
	FLOAT	-910,R0
	STF	R0,*+AR4(OPOSY)
	FLOAT	5500,R0
	STF	R0,*+AR4(OPOSZ)


	LDI	*+AR4(OFLAGS),R0
	OR	O_ILLUM|O_NOUNIV|O_NOUROT,R0
	LDI	1,R1
	LS	16,R1
	OR	R1,R0
	STI	R0,*+AR4(OFLAGS)


	CLRF	R0
	STF	R0,*+AR4(ORADX)
	LDF	startthey,R2
	ADDF	HALFPI,R2
	STF	R2,*+AR4(ORADY)
	LDF	startthez,R2
	STF	R2,*+AR4(ORADZ)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	LDI	AR4,R2
	ADDI	ORADX,R2
	CALL	FIND_MATRIX
	LDI	AR4,AR2
	CALL	OBJ_INSERTP


	LDF	*+AR4(ORADY),R0
	STF	R0,*+AR4(OUSR1)


;	LDI	470,AR5
MSLP1
	LDF	0.0174539,R0
	FLOAT	@NFRAMES,R1
	MPYF	R1,R0
	ADDF	*+AR4(OUSR1),R0		;ORADY
	STF	R0,*+AR4(OUSR1)
	LDP	@_CAMERARAD+Y
	SUBF	@_CAMERARAD+Y,R0
	SETDP
	STF	R0,*+AR4(ORADY)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	LDI	AR4,R2
	ADDI	ORADX,R2
	CALL	FIND_MATRIX

MSLP2
	SLEEP	1
	CALL	MSLP_CHECK
	BR	MSLP1

MSLP_CHECK
	SUBI	@NFRAMES,AR6

	LDI	@DECOMP_ACTIVE,R0
	CMPI	0,R0
	BNE	MSLP3
	LDI	*+AR7(DECOMP_COUNT),R0
	ADDI	1,R0
	STI	R0,*+AR7(DECOMP_COUNT)
	CMPI	3,R0
	BGT	MSLP4				;Done Loading
MSLP3
	RETS
;	BR	MSLP1
MSLP4
	CMPI	0,AR6
	RETSGT
;	BGT	MSLP1	
MSLPX

	LDI	0,R0
	STI	R0,@LOADED

	POP	BK		;POP return address
	BR	CYCLE_ATTR


*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
MIDWAYSPINENTER:

	LDL	midway,AR2
	CALL	OBJ_GETE
	.if	DEBUG
	BC	$
	.endif
	LDI	AR0,AR4

	CLRF	R0
	STF	R0,*+AR4(OPOSX)
	FLOAT	-480,R0
	STF	R0,*+AR4(OPOSY)
	FLOAT	5500,R0
	STF	R0,*+AR4(OPOSZ)


	LDI	*+AR4(OFLAGS),R0
	OR	O_ILLUM|O_NOUNIV|O_NOUROT,R0
	LDI	1,R1
	LS	16,R1
	OR	R1,R0
	STI	R0,*+AR4(OFLAGS)


	CLRF	R0
	STF	R0,*+AR4(ORADX)
	LDF	startthey,R2
	ADDF	PI,R2
	STF	R2,*+AR4(ORADY)
	LDF	startthez,R2
	STF	R2,*+AR4(ORADZ)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	LDI	AR4,R2
	ADDI	ORADX,R2
	CALL	FIND_MATRIX
	LDI	AR4,AR2
	CALL	OBJ_INSERTP


	LDF	*+AR4(ORADY),R0
	STF	R0,*+AR4(OUSR1)


	LDI	690,AR5
MSLP1a
	LDF	*+AR4(OUSR1),R0		;ORADY
	ADDF	0.0174539,R0
	STF	R0,*+AR4(OUSR1)
	LDP	@_CAMERARAD+Y
	SUBF	@_CAMERARAD+Y,R0
	SETDP
	STF	R0,*+AR4(ORADY)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	LDI	AR4,R2
	ADDI	ORADX,R2
	CALL	FIND_MATRIX

	SLEEP	1
	DBU	AR5,MSLP1a

	CALL	TEXT_INIT
	BR	CYCLE_ATTR
*----------------------------------------------------------------------------
	.globl	SPIN_CAR
SPIN_CARTABI	.word	SPIN_CARTAB
	romdata
SPIN_CARTAB	.word	missle,hotrod,testor,cvette
	.text

SPIN_CAR:
	LDI	0,R0
	STI	R0,*+AR7(DECOMP_COUNT)

	LDIL	logo,AR2
	CALL	OBJ_GETE
	LDI	O_IROT|O_NOROT|O_NOUROT|O_NOUNIV,R0
	OR	*+AR0(OFLAGS),R0
	STI	R0,*+AR0(OFLAGS)
	FLOAT	-150,R0
	STF	R0,*+AR0(OPOSX)
	FLOAT	-110,R0
	STF	R0,*+AR0(OPOSY)
	FLOAT	436,R0
	STF	R0,*+AR0(OPOSZ)
	LDI	AR0,AR2
	CALL	OBJ_INSERT

	CALL	LOGO_SMALL

	LDI	@ATTRWAVE,AR2
	LSH	-1,AR2
	SUBI	1,AR2
	AND	3,AR2
	ADDI	@SPIN_CARTABI,AR2
	LDI	*AR2,AR2
	CALL	OBJ_GETE
	LDI	O_IROT|O_NOROT|O_NOUROT|O_NOUNIV,R0
	OR	*+AR0(OFLAGS),R0
	STI	R0,*+AR0(OFLAGS)

	FLOAT	1368,R0
	STF	R0,*+AR0(OPOSZ)
	LDI	AR0,AR4

	LDF	-0.196,R2
	STF	R2,*+AR4(ORADX)

	LDF	3.534,R2
	STF	R2,*+AR4(ORADY)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	LDI	AR4,R2
	ADDI	ORADX,R2
	CALL	FIND_MATRIX

	LDI	AR4,AR2
	CALL	OBJ_INSERTP

	LDI	16,AR6
SPIN_CAR_WAIT
	SLEEP	1
	SUBI	1,AR6
	CMPI	0,AR6
	BGT	SPIN_CAR_WAIT

	LDI	550,AR6
SPIN_CARLP
	LDF	*+AR4(ORADY),R2
	FLOAT	@NFRAMES,R0
	MPYF	0.018,R0
	ADDF	R0,R2
	STF	R2,*+AR4(ORADY)

	LDI	AR4,R2
	ADDI	ORADX,R2
	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_MATRIX

	SLEEP	1
	CALL	MSLP_CHECK
	BU	SPIN_CARLP


*----------------------------------------------------------------------------
*
TEXTTOGET:
	SLEEP	75

	LDI	@TEXT_ACTIVEI,AR0
	CLRF	R1
TXTLP	LDI	*AR0,R0
	BZ	NXTWT
	LDI	R0,AR0

	STF	R1,*+AR0(TEXT_VELX)
	BR	TXTLP
NXTWT
	SLEEP	460

	LDI	@TEXT_ACTIVEI,AR0
	LDF	-6,R1
TXTLPA	LDI	*AR0,R0
	BNZ	TXTLPB
	BR	SUICIDE
TXTLPB
	LDI	R0,AR0

	STF	R1,*+AR0(TEXT_VELY)
	BR	TXTLPA
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
	.data
DEMOTHANKS_LISTI	.word	DEMOTHANKS_LIST
	.SECT "THEDATA"

DT1	.string	"THANK YOU FOR PLAYING",0
DT2	.string	"CRUISIN USA",0
DT3	.string	"SNEAK PREVIEW",0

DEMOTHANKS_LIST
	.word	140,DT1
	.word	180,DT2
	.word	220,DT3

	.text

DEMOTHANKS:
	LDI	1,R0
	STI	R0,@COINOFF

	CLRI	R0
	STI	R0,@BGNDCOLA	;COLORAM

	LDI	2,AR5
	LDI	@DEMOTHANKS_LISTI,AR4
DTLP
	FLOAT	256,R2
	FLOAT	*AR4++,R3
	LDI	*AR4++,AR2
	LDI	9999,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)

	DBU	AR5,DTLP

	LDI	-6,R0
	STI	R0,@_ATTR_MODE

	BR	MIDWAYSPINENTER
*----------------------------------------------------------------------------
	.END
