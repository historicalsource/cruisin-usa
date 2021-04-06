	.FILE	"HUD.ASM"
*----------------------------------------------------------------------------
*HEADS UP DISPLAY ROUTINES
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	C30.EQU
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
	.include	DIRQ.EQU

SECTION_COUNTER	.set	0	;1 = TURN ON UL CRNR 



COUNTDOWN_BUFI	.word	COUNTDOWN_BUF
		.bss	COUNTDOWN_BUF,2

MPH_BUFFERI	.word	MPH_BUFFER
		.bss	MPH_BUFFER,2

		.bss	_countdown,1	;SD
		.bss	_MPH,1		;UD
		.bss	SCORE,1		;UD
		.bss	POSITION,1	;UD
		.bss	MAXMPH_COUNT,1	;FL

STOPBUFFI	.word	STOPBUFFER
		.bss	STOPBUFFER,4

	romdata
YOURLOSTTXT	.string	"YOU ARE LOST",0
OFFROADTXT	.string	"OFFROAD",0
	.text
		.bss	OFFROADBUFF,2




	.globl	MOTION_STOP_HIT,MOTION_SAFETY_ON



*----------------------------------------------------------------------------
	.bss	MOVEIN_OFFSET,1
MOVEIN_HUD_EQUIP:
	LDI	150,R0
	STI	R0,@MOVEIN_OFFSET

LIU8	LDI	@_MODE,R0
	TSTB	MHUD,R0
	BNZ	M2L
	SLEEP	1
	BU	LIU8


M2L	LDI	25-1,AR5
MIHEL
	LDI	@MOVEIN_OFFSET,R0
	SUBI	6,R0
	STI	R0,@MOVEIN_OFFSET

	SLEEP	1
	DBU	AR5,MIHEL

	CLRI	R0
	STI	R0,@MOVEIN_OFFSET
	DIE
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
MOVEOUT_HUD_EQUIP:

	LDI	25-1,AR5
MIHEL2
	LDI	@MOVEIN_OFFSET,R0
	ADDI	6,R0
	STI	R0,@MOVEIN_OFFSET

	SLEEP	1
	DBU	AR5,MIHEL2

	LDI	150,R0
	STI	R0,@MOVEIN_OFFSET
	DIE
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*HEADS UP DISPLAY ROUTINE
*CALL FROM MAIN LOOP
*
*SHOULD ONLY BE CALLED DURING GAME PLAY
*
HUD:
	CALL	TACHOMETER_ANIMATE
	CALL	RADAR_PLOT

	;
	;MOTION SAFETY ON
	;
	READAUD	ADJ_MOTION_PRESENT
	CMPI	0,R0
	BEQ	NOMOTIONMSGS

	LDI	@MOTION_STOP_HIT,R0
	BNZ	NOMOTIONMSGS


	.globl	MOTION_SAFETY_ON
	LDI	@MOTION_SAFETY_ON,R0
	BZ	BLAHBLAH

	.data

SAFETSI	.word	SAFETS
	romdata
SAFETS	.word	MSAF,BSAF,OSAF,MSSM
MSAF	.string	"SAFETY MAT ACTIVATED",0
BSAF	.string	"SAFETY BEAM ACTIVATED",0
OSAF	.string	"FAIL SAFE SWITCH ACTIVATED",0
MSSM	.string	"MOTION STOP BUTTON HIT",0

	.text


	LDI	@SAFETSI,AR2
	.globl	MOTION_SAFETY_TYPE
	ADDI	@MOTION_SAFETY_TYPE,AR2
	LDI	*AR2,AR2

	FLOAT	256,R2
	FLOAT	310,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
BLAHBLAH
	;
	;
NOMOTIONMSGS



	;-------OFF ROAD TIMER
	;
	;
	LDI	@_MODE,R0
	ANDN	MMODE,R0
	CMPI	MGAME,R0
	BNE	NOT_OFFROAD

	LDI	@OFFROAD_TMR,R2
	CMPI	10,R2
	BGE	NOT_OFFROAD

	CMPI	3,R2
	BGT	NOTLOST


	LDL	YOURLOSTTXT,AR2
	FLOAT	256,R2
	FLOAT	5,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	SET18FONTDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	BU	OFJN
NOTLOST
	LDL	OFFROADTXT,AR2
	FLOAT	256,R2
	FLOAT	5,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	SET18FONTDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
OFJN

	LDI	@OFFROAD_TMR,R2
	LDL	OFFROADBUFF,AR2
	CALL	_itoa
	FLOAT	256,R2
	FLOAT	30,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
NOT_OFFROAD




	;-------ELAPSED TIME,SPEED TEXT
	;
	;
	LDL	rpm,AR2
	LDI	420,R2			;R2	POS X
	ADDI	@MOVEIN_OFFSET,R2
	LDI	290,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D


	LDI	@CHOSEN_TRANSMISSION,R0
	CMPI	AUTO_TRANSMISSION,R0
	BEQ	ISAUTOTRNS

	LDL	rpmman,AR2
	LDI	463,R2			;R2	POS X
	ADDI	@MOVEIN_OFFSET,R2
	LDI	380,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D
	BU	DNDNL
ISAUTOTRNS
	LDL	rpmauto,AR2
	LDI	470,R2			;R2	POS X
	ADDI	@MOVEIN_OFFSET,R2
	LDI	380,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D
DNDNL




	;show gear digit
	;
	;
	LDI	@PLYCBLK,AR0
	LDI	*+AR0(CARGEAR),AR2
	ADDI	@GEARI,AR2
	LDI	*AR2,AR2
	FLOAT	458,R2			;R2	POS X
	FLOAT	@MOVEIN_OFFSET,R0
	ADDF	R0,R2
	FLOAT	360,R3			;R3	POS Y
	LDI	1,RC
	CALL	TEXT_ADD
	CALL	SETSMDIGITFONT
	
	.data
GEARI	.word	GEARS
GEARS	.word	GEARN,GEAR1,GEAR2,GEAR3,GEAR4
GEAR1	.string	"1",0
GEAR2	.string	"2",0
GEAR3	.string	"3",0
GEAR4	.string	"4",0
GEARN	.string	";",0
	.text





	;show MPH or KPH
	;
	LDL	mph,AR2
	LDI	0,R2			;R2	POS X
	SUBI	@MOVEIN_OFFSET,R2
	LDI	335,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D

	READAUD	ADJ_MPHORKPM
	CMPI	0,R0
	BEQ	ISMPHT

	LDL	kph,AR2
	LDI	50,R2			;R2	POS X
	SUBI	@MOVEIN_OFFSET,R2
	LDI	385,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D
	BU	ISDNN
ISMPHT

	LDL	mphmph,AR2
	LDI	50,R2			;R2	POS X
	SUBI	@MOVEIN_OFFSET,R2
	LDI	385,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D
ISDNN


	;-------time remaining
	;
	LDL	time,AR2
	LDI	242,R2			;R2	POS X
	LDI	9,R3			;R3	POS Y
	SUBI	@MOVEIN_OFFSET,R3
	LDI	TM|ZS,R4
	CALL	BLTMOD2D_DS


	;-------TIME (_countdown)
	;
	;
	LDI	@_countdown,R2
	LDI	@COUNTDOWN_BUFI,AR2
	CALL	_itoa
	FLOAT	256,R2
	FLOAT	24,R3
	FLOAT	@MOVEIN_OFFSET,R0
	SUBF	R0,R3
	LDI	1,RC
	CALL	TEXT_ADD
	CALL	SETN43FONT
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	.globl	lgnum43_coolyelo
	LDL	lgnum43_coolyelo,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)



	;-------LAST 3/10 SECONDS OF TIME (_countdown)
	;
	;
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MGAME,R0
	BNE	NBEEP
	.bss	LASTSEC,1
	LDI	@_countdown,R0
	CMPI	10,R0
	BGT	NBEEP
	BLT	NOINITBP
	LDI	@LASTSEC,R1
	CMPI	R1,R0
	BEQ	NBEEP
	STI	R0,@LASTSEC
	SOND1	GV_TENSECONDS
	BU	NBEEP
NOINITBP
	LDI	@LASTSEC,R1
	CMPI	R1,R0
	BEQ	NBEEP
	STI	R0,@LASTSEC

	CMPI	3,R0
	BGT	NBEEP
	SOND1	BASICBEEPH
NBEEP



	;-------SPEED
	;
	;
	;PLOT SPEED

	READAUD	ADJ_MPHORKPM
	CMPI	0,R0
	BEQ	ISMPH

	FLOAT	@_MPH,R2
	MPYF	1.6666,R2
	FIX	R2
	BU	ISKPH

ISMPH	LDI	@_MPH,R2
ISKPH	LDI	@MPH_BUFFERI,AR2
	CALL	_itoa
	FLOAT	66,R2
	FLOAT	@MOVEIN_OFFSET,R0
	SUBF	R0,R2
	FLOAT	346,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	SETLGDIGITFONTDS
	ORM	TXT_RIGHT,*+AR0(TEXT_COLOR)
	ORM	TXT_RIGHT,*+AR1(TEXT_COLOR)
	.globl	dnums_amber
	LDL	dnums_amber,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)
	STI	R0,*+AR1(TEXT_PAL)


	;-------STOPWATCH (actual elapsed time)
	;
	;
	LDI	8,R0
	LDI	19,R1
	SUBI	@MOVEIN_OFFSET,R1
	LDI	106,R2
	LDI	30,R3
	CALL	FILL_DITHER

	LDL	elap,AR2
	LDI	10,R2			;R2	POS X
	LDI	20,R3			;R3	POS Y
	SUBI	@MOVEIN_OFFSET,R3
	LDI	TM|ZS,R4
	CALL	BLTMOD2D_DS


	LDI	@STOPWATCH,R0
	LDI	@STOPBUFFI,AR2
	CALL	TIME2STR
	FLOAT	20,R2
	FLOAT	33,R3
	FLOAT	@MOVEIN_OFFSET,R0
	SUBF	R0,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	SETSMDIGITFONTDS


	;-------POSITION
	;(PLAYERS RANK)
	;
	LDI	@POSITION,AR4
	SUBI	1,AR4
	MPYI	3,AR4
	ADDI	@POS_TABLEI,AR4
	LDI	*AR4++,AR2
	LDI	415,R2
	ADDI	*+AR4,R2
	LDI	20,R3
	SUBI	@MOVEIN_OFFSET,R3
	LDI	TM|ZS,R4
	CALL	BLTMOD2D_DS

	LDI	*AR4++,AR2
	LDI	450,R2
	LDI	20,R3
	SUBI	@MOVEIN_OFFSET,R3
	LDI	TM|ZS,R4
	CALL	BLTMOD2D_DS


	.data
POS_TABLEI	.word	POS_TABLE
POS_TABLE
	.word	scred1,dst,7
	.word	scred2,dnd,0
	.word	scred3,drd,0
	.word	scred4,dth,0
	.word	scred5,dth,0
	.word	scred6,dth,0
	.word	scred7,dth,0
	.word	scred8,dth,0
	.word	scred9,dth,0
	.word	scred10,dth,-20
	.text




	.if	SECTION_COUNTER
	;-------DEBUGGING SECTION_COUNTER
	;
	;
	.bss	SECIDX,2
	LDI	@PLYCBLK,AR0
	LDI	*+AR0(CARTRAK),AR0
	LDI	*+AR0(OUSR1),R2
	RS	8,R2
	LDL	SECIDX,AR2
	CALL	_itoa
	FLOAT	10,R2
	FLOAT	50,R3
	LDI	1,RC
	CALL	TEXT_ADD
	.endif


	;-------LOGIC: MAXMPH COMPUTATION
	;(COMPUTE FOR BONUS SCREEN...)
	;
	;
	FLOAT	@_MPH,R2
	.globl	CHEAT
	MPYF	@CHEAT,R2		;DO THE CHEAT THING !!!
	FLOAT	@NFRAMES,R0
	MPYF	R0,R2
	ADDF	@MAXMPH,R2
	STF	R2,@MAXMPH

	ADDF	@MAXMPH_COUNT,R0
;	LDF	@MAXMPH_COUNT,R0
;	INCF	R0

	STF	R0,@MAXMPH_COUNT
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*ALLOCATE PALETTES FOR A SECTION
*
*PARAMETERS
*	AR2	PTR TO SECTION HEADER
*
SECTION_PALETTE_ALLOC:
alloc_section:
HARDalloc_section:
	LDI	*AR2++,AR6
	LDI	*AR2,AR5

	DEC	AR5
alloc_LPA
	LDI	AR6,AR2
	CALL	PAL_ALLOC
	INC	AR6
	DBU	AR5,alloc_LPA
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*DEALLOCATE PALETTES USED FOR A SECTION
*
*
*PARAMETERS
*	AR2	SECTION POINTER
*
dealloc_section:
	PUSH	AR4
	PUSH	AR5
	PUSH	AR6
	LDI	*AR2++,AR6
	LDI	*AR2,AR5
	DEC	AR5
deal_LP	
	LDI	AR6,AR2
	CALL	PAL_DELETE
	INC	AR6
	DBU	AR5,deal_LP
	POP	AR6
	POP	AR5
	POP	AR4
	RETS
*----------------------------------------------------------------------------




	.include	RPM.PAL

	.bss	TACHOMETER_PAL,32

*----------------------------------------------------------------------------
TACHOMETER_ANIMATE:

	LDL	TACH_GRADIENT,AR0
	LDL	TACHOMETER_PAL,AR1

	LDI	22-1,RC
	RPTB	LP89
	LDI	*AR0++,R0
LP89	STI	R0,*AR1++

	LDI	@PLYCBLK,AR0
	LDF	*+AR0(CARRPM),R0
	MPYF	0.4583,R0		;22/48
;	MPYF	0.729,R0		;35/48
;	MPYF	0.6041,R0		;29/48
	FIX	R0
	CMPI	22,R0
	LDIGT	22,R0

	CMPI	0,R0
	LDILT	0,R0
	LDI	R0,RC
	SUBRI	22,RC

	LDL	TACHOMETER_PAL,AR1
	ADDI	R0,AR1
	CLRI	R1
	RPTS	RC
	STI	R1,*AR1++


	LDI	rpm_p,AR2
	CALL	PAL_FIND
	PUSH	R0
	LDI	R0,R2
	ADDI	256-22,R2

	LDL	TACHOMETER_PAL,AR2
	LDI	22,R3
	CALL	PAL_SET



	LDI	@PLYCBLK,AR0
	LDI	*+AR0(CARGEAR),R0

	CLRI	R1		;ASSUME NEUTRAL
	LDL	GEARPAL,AR2
	CMPI	1,R0
	LDIEQ	4,R1

	CMPI	2,R0
	LDIEQ	3,R1

	CMPI	3,R0
	LDIEQ	2,R1

	CMPI	4,R0
	LDIEQ	1,R1

	POP	R2
	ADDI	1,R2
	ADDI	R1,AR2
	LDI	4,R3
	CALL	PAL_SET
	RETS

GEARPAL
	.word	0
	.word	0
	.word	0
	.word	0
	RGB	0,255,255
	.word	0
	.word	0
	.word	0


*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*PARAMETERS
*	R0	X POS
*	R1	Y POS
*	R2	X WIDTH
*	R3	Y WIDTH
*
*
FILL_DITHER:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4

	;background
	LDI	CC|DITHER|8,R4
	BD	ENTER2
	STI	R4,@_ACNTL

	CLRI	R4
	STI	R4,@_ACMAP
	;---->	BD	ENTER2

FILL_PLOT:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4


;	;background
;	LDI	CC|DITHER|8,R4
;	STI	R4,@_ACNTL
ENTER2

	STI	R0,@(_ARPS+(0*3))
	STI	R0,@(_ARPS+(3*3))

	ADDI	R2,R0
	STI	R0,@(_ARPS+(1*3))
	STI	R0,@(_ARPS+(2*3))

	STI	R1,@(_ARPS+(0*3)+1)
	STI	R1,@(_ARPS+(1*3)+1)

	ADDI	R3,R1,R0
	STI	R0,@(_ARPS+(3*3)+1)
	STI	R0,@(_ARPS+(2*3)+1)
	CLRI	R0
	STI	R0,@_ADDRL

	CALL	_stuff_fpga

	POP	R4
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------
	.END
