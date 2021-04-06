	.FILE	"WAVE.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	C30.EQU
	.include	OBJ.EQU
	.include	MACS.EQU
	.include	MPROC.EQU
	.include	VUNIT.EQU
	.include	CMOS.EQU
	.include	SYSID.EQU
	.include	SYS.EQU
	.include	GLOBALS.EQU
	.include	PALL.EQU
	.include	SNDTAB.EQU
	.include	OBJECTS.EQU
	.include	TEXT.EQU
	.include	DIRQ.EQU
	.include	COMM.EQU
	.include	H2HOBJ.EQU



	pbss	TEASE_COUNT,1	;WHEN SPUTTER SOUND CAN BE CALLED IN ATTR
	pbss	ATTR_MODEL,1	;DISPLAYED MODEL IN DRIVING
	pbss	_ATTR_MODE,1	;CURRENT ATTRACT MODE
	pbss	LOADED,1	;IS THE SYSTEM READY TO SLAVE OVER TO A NEW SCREENP

*----------------------------------------------------------------------------
*PARAMETERS
*	AR2	WAVE INDEX
*		<  0 -> ATTRACT MODE N
*		>= 0 -> REGULAR GAME
*
WAVE:
	POP	AR7	;return addr
	CALL	SILENT

	;CLEAR ALL RAM AND RELOAD CODE
	;
	CLRI	R0			;CLEAR INTERNAL RAM
	LDIL	RAM0,AR0
	RPTS	2047
	STI	R0,*AR0++

	CALL	COMM_ENABLE_INT2





	LDI	@COUNTER_IDX,R0
	PUSH	R0
	LDI	@COUNTER_MODE,R0
	PUSH	R0
	LDI	@COIN_COUNTER1,R0
	PUSH	R0
	LDI	@COIN_COUNTER2,R0
	PUSH	R0


	CALL	CLR_RAM			;CLEAR BSS SPACE


	POP	R0
	STI	R0,@COIN_COUNTER2
	POP	R0
	STI	R0,@COIN_COUNTER1
	POP	R0
	STI	R0,@COUNTER_MODE
	POP	R0
	STI	R0,@COUNTER_IDX




	;RELOAD GAME CODE
	LDI	0,AR1			;SOURCE ADDRESS
	LDI	4000h,AR3		;DESINATION ADDRESS
	LS	8,AR3
	LDI	1000h,RC		;COPY THE PROGRAM INTO
	LS	4,RC			;FAST RAM
	RPTB	LD_RAM
	LDI	*AR1++,R0
LD_RAM	STI	R0,*AR3++


	PUSH	AR7
	PUSH	AR2


	.if	DEBUG
	CALL	VERIFY_CODE_INTEGRITY
	.endif


	CALL	CLRONE	;CAN NOW BE DUAL PLAYER


	CALL	INIT_SYSTEM
	LDP	@_CAMERARAD
	CLRF	R0
	STF	R0,@_CAMERARAD+X
	STF	R0,@_CAMERARAD+Y
	STF	R0,@_CAMERARAD+Z
	STF	R0,@_CAMERAPOS+X
	STF	R0,@_CAMERAPOS+Y
	STF	R0,@_CAMERAPOS+Z
	STF	R0,@_LIGHT+Z
	LDF	0.707,R0
	STF	R0,@_LIGHT+X
	STF	R0,@_LIGHT+Y
	SETDP

	CALL	INIT_CUSTOM_COIN	;Set the CUSTOM SETUP in RAM

	LDI	@CAMERAMATRIXI,AR0
	CALL	INITMAT

	FLOAT	35,R0
	STF	R0,@INFIN_CORRECT
	LDI	1,R0
	STI	R0,@CLEARRDY

	READADJ	ADJ_STEERCENTER
	FLOAT	R0
	STF	R0,@WHEELPOS
	CLRF	R0
	STF	R0,@WHEELPWR
	STF	R0,@WHEELVEL
	CLRI	R0
	STI	R0,@COINOFF
	STI	R0,@NOLONG_VEHICLES

	CALL	LOAD_FIXED_PALETTES


	CREATE	SCAN_OBJECTS,UTIL_C
	POP	AR2



	CMPI	1,AR2
	BEQ	BEGIN_GAME



	CLRI	AR0
	LDP	@SWITCH3
	NOT	@SWITCH3,R0   		;READ HARDWARE 0=CLOSED, 1=OPEN
	LDI	*AR0,R2			;Loff
	SETDP
	AND	SW_VIEW0_H|SW_VIEW1_H|SW_VIEW2_H,R0
	CMPI	SW_VIEW1_H|SW_VIEW2_H,R0
	BEQ	CREDITS


	LDI	AR2,AR0
	ADDI	@_ATTR_WAVETABI,AR0
	LDI	*AR0,R0
	CALLU	R0
	RETS


_ATTR_WAVETABI	.word	_ATTR_WAVETAB	;NOTE THE VALUES ARE NEGATVIE
	.word	HEAD2HEAD_WAIT	
	.word	CREDITS		;MUST BE -6
	.word	THANKS		;MUST BE -5
	.word	MIDSPINHS ;-4
	.word	RACELEG	;-3
	.word	MIDSPIN	;-2
	.word	HIGH_SCORE	;-1
_ATTR_WAVETAB

HEAD2HEADWATCH:
	SLEEP	1
	LDI	@OM_MODE,R0
	AND	MMODE,R0
	CMPI	MBONUS,R0
	BEQ	ISTRUE
	CMPI	MINIT,R0
	BEQ	ISTRUE
	CMPI	MINSERT_COINS,R0
	BEQ	ISTRUE

	LDI	@OM_LINKWAIT,R0
	BZ	HEAD2HEADWATCH
ISTRUE	LDI	-7,R0
	STI	R0,@_ATTR_MODE
	BR	SET_ATTR

HEAD2HEAD_WAIT:
	LDI	@BUTTON_STATUS,R0
	ANDN	BUT_VIEWS,R0
	STI	R0,@BUTTON_STATUS
	CREATE	HEAD2HEAD_LOGO_WAIT,UTIL_C
	RETS
	

HIGH_SCORE:
	LDI	@BUTTON_STATUS,R0
	ANDN	BUT_VIEWS,R0
	STI	R0,@BUTTON_STATUS

	.globl	OLD_BUTTON_STATUS
	LDI	-1,R0	;Kick start the light routine
	STI	R0,@OLD_BUTTON_STATUS

	LDI	MATTR|MHS,R0
	STI	R0,@_MODE
	CREATE	DISPLAY_HIGH_SCORES,UTIL_C
	CREATE	HEAD2HEADWATCH,UTIL_C
	RETS

MIDSPIN:
	LDI	@BUTTON_STATUS,R0
	ANDN	BUT_VIEWS,R0
	STI	R0,@BUTTON_STATUS

	CLRI	R0

	LDI	MATTR,R0
	STI	R0,@_MODE
	CALL	LOAD_ATTR_LEG

	CREATE	HEAD2HEADWATCH,UTIL_C

	LDI	@ATTRWAVE,AR6		;DCS LOGOSOUND will play only if 0

;	LDI	3,AR2
;	CALL	RANDU0
;	CMPI	0,R0
;	BEQ	BBDD
;
;	CREATE	HEAD2HEAD_LOGO,UTIL_C
;	RETS
;BBDD
	CREATE	_MIDWAYSPIN,UTIL_C
	RETS

MIDSPINHS:
	LDI	@BUTTON_STATUS,R0
	ANDN	BUT_VIEWS,R0
	STI	R0,@BUTTON_STATUS

	LDL	_SECpress,AR2
	CALL	LOAD_SECTION_REQ

	LDI	MATTR,R0
	STI	R0,@_MODE

	.globl	SPIN_CAR
	CREATE	SPIN_CAR,UTIL_C
	CREATE	HEAD2HEADWATCH,UTIL_C
	RETS

RACELEG:
	CLRI	R0
	STI	R0,@TEASE_COUNT
	LDI	MATTR,R0
	STI	R0,@_MODE

	CREATE	ATTRACT_DELTA,DRONE_C|DELTA_ATTR_S

	LDI	@ATTRWAVE,R0
	CMPI	4,R0
	LDIEQ	25*30,R0
	LDINE	30*30,R0
	STI	R0,@_timer
	CREATE	_timeout,UTIL_C
	CREATE	HEAD2HEADWATCH,UTIL_C
	RETS

HIGH_SCORE_INI:
THANKS:
	CALL	LOAD_HIGH_SCORE
	BU	HIGH_SCORE

	;these are not cycled, they are special routines

CREDITS:
	CREATE	VANITY,UTIL_C
	LDI	-1,R0
	STI	R0,@_ATTR_MODE
	RETS

LOAD_HIGH_SCORE:
	CALL	FIFO_RESET
	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD

	LDL	_SECpress,AR2
	CALL	LOAD_SECTION_REQ
	LDI	-1,R0
	STI	R0,@_ATTR_MODE
	RETS
*
*NOTE	ANY GAME STARTUP CODE & PROC INITS ARE CALLED/CREATED IN INTRO.ASM
*
BEGIN_GAME:
	CALL	SND_RESET_QUIET
	LDI	1,R0
	STI	R0,@LOADED

	CREATE	PLYR_INTRO,PLYR_C|PLYR1_T	;PLAYERS PROCESS
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
INIT_SYSTEM:
	CALL	PRC_INIT	;initialize process system
	CALL	OBJ_INIT	;initialize object system
	CALL	TEXT_INIT	;initialize text system

	CALL	INIT_DRONES	;initialize DRONE tracker system
	CALL	DYNAOBJ_INIT	;initialize DYNAMIC OBJECTS
	CALL	CARB_INIT	;initialize CAR BLOCKS
	CALL	INIT_RDDEBRIS	;initialize ROAD DEBRIS list(s)
	CLRI	R0
	STI	R0,@_sectime
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FIXEDPAL:
	.word	14
	RGB	0,0,0
	RGB	255,255,255		;1  WHITE
	RGB	070h,070h,070h		;2  GREY
	RGB	255,0,0			;3  RED
	RGB	0,255,0			;4  GREEN
	RGB	055h,055h,99h		;5  BLUE  (for the sky paled out)
	RGB	255,255,0		;6  YELLOW
	RGB	0,255,255		;7  CYAN
	RGB	0,0,0			;8  BLACK
	RGB	0,0,255			;9  TRUE BLUE
	RGB	0C0h,0A0h,0		;A  Amber color
	RGB	050h,050h,050h		;B	DARK GREY
	RGB	0A0h,0A0h,0A0h		;C	LIGHT GREY
	RGB	030h,030h,030h		;D	VERY DARK GREY
					;F  -cycling color


ILLUM_PAL:
	.word	16
	RGB	06Ah,000h,000h
	RGB	06Fh,000h,000h
	RGB	074h,000h,000h
	RGB	079h,000h,000h
	RGB	07Eh,000h,000h
	RGB	083h,000h,000h
	RGB	088h,000h,000h
	RGB	08Dh,000h,000h
	RGB	092h,000h,000h
	RGB	097h,000h,000h
	RGB	09Ch,000h,000h
	RGB	0A1h,002h,005h
	RGB	0A6h,007h,00Ah
	RGB	0ABh,00Ch,00Fh
	RGB	0B0h,011h,014h
	RGB	0B5h,016h,019h
*----------------------------------------------------------------------------


	romdata
	.include	font43.pal
	.include	font18.pal
	.globl	font18_white

	.globl	dnums_amber
	.include	dnums2.pal

	.globl	bnout1_smoke
	.include	smoke.pal


	.globl	osg10fnt_white
	.include	osg10fnt.pal


	.text
*----------------------------------------------------------------------------
*THESE PALETTES ONLY HAVE TO BE LOADED UPON STARTUP
*
LOAD_FIXED_PALETTES:
	CALL	PAL_INIT
	LDL	FIXEDPAL,AR2
	CALL	PAL_ALLOC_RAW

	CLRI	R0
	LDP	@COLORAM
	STI	R0,@COLORAM+0FFh
	SETDP

	LDL	fixedfnt_tPAL,AR2
	CALL	PAL_ALLOC_RAW
	
	LDL	ILLUM_PAL,AR2		;only 1 palette
	CALL	PAL_ALLOC_RAW

	LDL	lgnum43_coolyelo,AR2
	CALL	PAL_ALLOC_RAW

	LDL	font18_white,AR2
	CALL	PAL_ALLOC_RAW

	LDL	dnums_amber,AR2
	CALL	PAL_ALLOC_RAW

	CALL	LOAD_VARIOUS_PALETTES	;mixed palettes
	LDL	shared_PALETTES,AR2
	CALL	HARDalloc_section

	LDI	sky1_p,AR2
	CALL	PAL_ALLOC

	LDL	osg10fnt_white,AR2
	CALL	PAL_ALLOC_RAW

	LDL	bnout1_smoke,AR2
	CALL	PAL_ALLOC_RAW

	LDL	H2HPAL1,AR2
	CALL	PAL_ALLOC_RAW
	LDL	H2HPAL2,AR2
	CALL	PAL_ALLOC_RAW
	LDL	H2HPAL3,AR2
	CALL	PAL_ALLOC_RAW

	LDL	general_PALETTES,AR2
	CALL	HARDalloc_section
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
LOAD_STARTUP_PALS:
	LDL	ggate_PALETTES,AR2
	CALL	HARDalloc_section
	RETS
*----------------------------------------------------------------------------


	romdata
*----------------------------------------------------------------------------
COPCARTAB	;PLAYERS VERSION!!!
	.word	5		;#OF DYNAS-1

	.float	0,101,0		;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	192,101,-301	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	208,101,371	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-192,101,-301	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	-208,101,371	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	0,0,0	 	;BODY XYZ CENTER OFFSET
	.word	72-1		;VERTS-1
	.word	0		;DYNAFLAG
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
HOTRODTAB
	.word	5		;#OF DYNAS-1

	.float	0,117,0		;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	211,100,-329	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	221,100,414	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-211,100,-329	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	-221,100,414	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	0,0,0	 	;BODY XYZ CENTER OFFSET
	.word	131		;VERTS-1
	.word	0		;DYNAFLAG


TESTORTAB
	.word	5		;#OF DYNAS-1

	.float	0,62,0		;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	251,62,-333	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	251,62,285	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-251,62,285	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-251,62,-333	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	0,0,0	 	;BODY XYZ CENTER OFFSET
	.word	59		;VERTS-1
	.word	0		;DYNAFLAG

*
*JEEP DYNAMIC OBJECT SETUP
*
JEEPTAB
	.word	5		;#OF DYNAS-1

	.float	0,119,0		;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	250,131,-285	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	250,131,355	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-250,131,-285	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	-250,131,357	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	0,0,0		;BODY XYZ CENTER OFFSET
	.word	62		;VERTS-1
	.word	0		;DYNAFLAG

*
*CVETT DYNAMIC OBJECT SETUP
*
VETTTAB
	.word	5		;#OF DYNAS-1

	.float	0,-164,0	;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	254,67,-296	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	228,81,376	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-254,67,-296	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	-228,81,376	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	0,0,0		;BODY XYZ CENTER OFFSET
	.word	114		;VERTS-1
	.word	0		;DYNAFLAG


*
*GTRUCKP DYNAMIC OBJECT SETUP
*
GTRUCKTABP
	.word	5		;#OF DYNAS-1

	.float	0,-117,0		;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	259,86,-358	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	248,90,388	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-259,86,-358	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	-248,90,388	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	0,0,0		;BODY XYZ CENTER OFFSET
	.word	131		;VERTS-1
	.word	0		;DYNAFLAG


*
*MISSILE DYNAMIC OBJECT SETUP
*
MISSILE_TAB
	.word	5		;#OF DYNAS-1

	.float	0,-117,0		;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	259,86,-358	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	248,90,388	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-259,86,-358	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG


	.float	-248,90,388	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG


	.float	0,0,0		;BODY XYZ CENTER OFFSET
	.word	131		;VERTS-1
	.word	0		;DYNAFLAG


*
*PLAYERS SCHOOL BUS
*
PSBUSTAB
	.word	5		;#OF DYNAS-1

	.float	0,-127,0	;SHADOW
	.word	3		;VERTS-1
	.word	-1		;DYNAFLAG

	.float	246,127,-380	;RT REAR WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	247,127,573	;RT FRONT WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG

	.float	-247,127,-380	;LFT REAR WHEEL	XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	1		;DYNAFLAG

	.float	-247,127,573	;LFT FRONT WHEEL XYZ CENTER OFFSET
	.word	23		;VERTS-1
	.word	2		;DYNAFLAG


	.float	0,0,0		;BODY XYZ CENTER OFFSET
	.word	91		;VERTS-1
	.word	0		;DYNAFLAG

*----------------------------------------------------------------------------
	.text


*----------------------------------------------------------------------------
*
*STRUCT VEHTAB
*	.word	model,model_palette,animation,degraded_model,degraded_model_level2
*	.word	taillight_color_count
*	.float	mass
*	.word	passby,backnoise
*	.word	pallete_table
*	.word	drone_dyna_table
*
*
VEHICLE_TABLEI	.word	VEHICLE_TABLE
VEHICLE_TABLE:

	;#0
	.word	cvette,cvette_p,VETTTAB,0,0
	.word	1
	.float	1.0
	.word	SPCARPASS,0
	.word	CVETTEPAL
	.word	0

	;#1
	.word	hotrod,hotrod_p,HOTRODTAB,dhotrod,d2hotrod
	.word	0
	.float	1.0
	.word	SPCARPASS,0
	.word	HOTRODPAL
	.word	0

	;#2
	.word	missle,missle_p,MISSILE_TAB,0,0
	.word	1
	.float	1.0
	.word	FCARPASS,0
	.word	BULLETPAL
	.word	0

	;#3
	.word	testor,testor_p,TESTORTAB,dtestor,d2testor
	.word	3
	.float	1.0
	.word	SPCARPASS,0
	.word	TESTORPAL
	.word	0

	;#4
	.word	gtruck,gtruck_p,0,dgtruck,d2gtruck
	.word	0
	.float	1.5
	.word	TRUCKPASS,0
	.word	GTRUCKPAL
	.word	DDYNA_GTRUCK

	;#5
	.word	ftruck,ftruck_p,0,0,0
	.word	0
	.float	2
	.word	TRUCKPASS,0
	.word	NOPAL
	.word	DDYNA_FTRUCK

	;#6	//locked
	.word	cbus,cbus_p,0,dcbus,d2cbus
	.word	0
	.float	2.0
	.word	TRUCKPASS,0
	.word	NOPAL
	.word	DDYNA_CBUS

	;#7
	.word	copcar,copcar_p,0,dcopcar,d2copcar
	.word	2
	.float	1.0
	.word	SPCARPASS,0
	.word	NOPAL
	.word	DDYNA_COPCAR

	;#8
	.word	muscle,muscle_p,0,dmuscle,d2muscle
	.word	0
	.float	1.0
	.word	SPCARPASS,0
	.word	MUSCLEPAL
	.word	DDYNA_MUSCLE

	;#9
	.word	caravan,caravan_p,0,dcaravan,d2carava
	.word	0
	.float	1.2
	.word	TRUCKPASS,0
	.word	CARAVANPAL
	.word	DDYNA_CARAVAN

	;#10	//locked
	.word	sbus,sbus_p,0,dsbus,d2sbus
	.word	0
	.float	2.0
	.word	TRUCKPASS,0
	.word	NOPAL
	.word	DDYNA_SBUS

	;#11	//locked
	.word	ptruckg,ptruckg_p,0,dptruckg,d2ptruck
	.word	0
	.float	1.0
	.word	TRUCKPASS,0
	.word	PTRUCKGPAL
	.word	DDYNA_PTRUCKG

	;#12
	.word	mustang,mustang,0,dmustang,d2mustang
	.word	0
	.float	1.0
	.word	SPCARPASS,0
	.word	NOPAL
	.word	DDYNA_MUSTANG

	;#13
	.word	toxic,0,0,0,0		;toxic in DV
	.word	0
	.float	2.0
	.word	0,0
	.word	NOPAL
	.word	0

	;#14
	.word	jeep,jeep_p,JEEPTAB,djeep,0
	.word	0
	.float	1.0
	.word	SMCARPASS,0
	.word	JEEPPAL
	.word	0


	;#15 copcar for the player
	.word	copcarp,copcar_p,COPCARTAB,dcopcar,d2copcar
	.word	2
	.float	1.0
	.word	SPCARPASS,0
	.word	NOPAL
	.word	0

	;#16 gtruckp for the player
	.word	gtruckp,gtruck_p,GTRUCKTABP,dgtruck,d2gtruck
	.word	0
	.float	1.5
	.word	TRUCKPASS,0
	.word	GTRUCKPAL
	.word	0

	;#17 sbusp for the player
	.word	sbusp,sbus_p,PSBUSTAB,0,0
	.word	0
	.float	5.5
	.word	TRUCKPASS,0
	.word	NOPAL
	.word	0


	romdata


*	number of axels,number of vertices
*	{
*	vertices, xcenter,ycenter,zcenter
*	} * number of axels
*
DDYNA_GTRUCK
	.word	3,154
	.word	8,-252,211,671
	.word	8,-254,211,-422
	.word	8,-254,211,-704
DDYNA_FTRUCK
	.word	2,92
	.word	8,-291,210,624
	.word	8,-293,210,-605
DDYNA_CBUS
;	.word	3,120
	.word	3,144
	.word	8,-291,261,-843
	.word	8,-294,261,-582
	.word	8,-294,261,914
DDYNA_COPCAR
	.word	2,135
	.word	8,0,97,369
	.word	8,0,97,-296
DDYNA_MUSCLE
	.word	2,148
	.word	8,244,108,441
	.word	8,237,108,-277
DDYNA_CARAVAN
	.word	2,105
	.word	8,-263,156,466
	.word	8,263,156,-435
DDYNA_SBUS
	.word	2,152
	.word	8,316,242,830
	.word	8,315,242,-378
DDYNA_PTRUCKG
	.word	2,169
	.word	8,197,107,323
	.word	8,196,107,-270
DDYNA_MUSTANG
	.word	2,173
	.word	8,234,93,407
	.word	8,233,93,-348

	.text


*----------------------------------------------------------------------------
*PALETTE_TABLES :
*
*TABLE_NAME
*	.word	length
*	{
*	.word	pal_ptr
*	} * length
*
	romdata
	.include	jeep.pal
	.include	testor.pal
	.include	gtruck.pal
	.include	hotrod.pal
	.include	missle.pal
	.include	caravan.pal
	.include	cvette.pal
	.include	muscle.pal
	.include	ptruckg.pal
	.text

NOPAL
	.word	0

;TESTORPAL	.word	3,testor_blue,testor_grape,testor_gold
TESTORPAL	.word	2,testor_blue,testor_grape
BULLETPAL	.word	3,missle_yellow,missle_red,missle_blue
;HOTRODPAL	.word	3,hotrod_yellow,hotrod_brtblue,hotrod_maroon
HOTRODPAL	.word	2,hotrod_yellow,hotrod_brtblue
		.globl	cvette_blue,cvette_red,cvette_purple
CVETTEPAL	.word	3,cvette_blue,cvette_red,cvette_purple

JEEPPAL		.word	2,jeep_red,jeep_yellow
;GTRUCKPAL	.word	2,gtruck_yellow,gtruck_bluep
GTRUCKPAL	.word	1,gtruck_bluep
CARAVANPAL	.word	2,caravan_redyelo,caravan_yelogrey
		.globl	muscle_yellow,muscle_green
MUSCLEPAL	.word	2,muscle_yellow,muscle_green
		.globl	ptruckg_purple,ptruckg_yellr
PTRUCKGPAL	.word	2,ptruckg_purple,ptruckg_yellr


	.globl	testor_grape,hotrod_yellow,bullet_plat
	.globl	testor_blue,hotrod_brtblue,bullet_grape
LOAD_VARIOUS_PALETTES:
	LDL	caravan_redyelo,AR2
	CALL	PAL_ALLOC_RAW
	LDL	caravan_yelogrey,AR2
	CALL	PAL_ALLOC_RAW

	LDL	hotrod_yellow,AR2
	CALL	PAL_ALLOC_RAW
	LDL	hotrod_brtblue,AR2
	CALL	PAL_ALLOC_RAW
;	.globl	hotrod_maroon
;	LDL	hotrod_maroon,AR2
;	CALL	PAL_ALLOC_RAW

	LDL	missle_yellow,AR2
	CALL	PAL_ALLOC_RAW
	LDL	missle_red,AR2
	CALL	PAL_ALLOC_RAW
	LDL	missle_blue,AR2
	CALL	PAL_ALLOC_RAW

	LDL	jeep_red,AR2
	CALL	PAL_ALLOC_RAW
	LDL	jeep_yellow,AR2
	CALL	PAL_ALLOC_RAW

	LDL	cvette_blue,AR2
	CALL	PAL_ALLOC_RAW
	LDL	cvette_red,AR2
	CALL	PAL_ALLOC_RAW
	LDL	cvette_purple,AR2
	CALL	PAL_ALLOC_RAW

	LDL	testor_blue,AR2
	CALL	PAL_ALLOC_RAW
	LDL	testor_grape,AR2
	CALL	PAL_ALLOC_RAW
;	LDL	testor_gold,AR2
;	CALL	PAL_ALLOC_RAW

;	LDL	gtruck_yellow,AR2
;	CALL	PAL_ALLOC_RAW
	LDL	gtruck_bluep,AR2
	CALL	PAL_ALLOC_RAW

	LDL	muscle_yellow,AR2
	CALL	PAL_ALLOC_RAW
	LDL	muscle_green,AR2
	CALL	PAL_ALLOC_RAW

	LDL	ptruckg_purple,AR2
	CALL	PAL_ALLOC_RAW
	LDL	ptruckg_yellr,AR2
	CALL	PAL_ALLOC_RAW

	RETS
*----------------------------------------------------------------------------
	



	romdata
*----------------------------------------------------------------------------
*OVERWRITTEN ON TOWER PALETTE, AND RESTORED IN GGATE PARK
*
tower_bgrey:
	.word	080000000h|256
	.word	(00h<<16)|021h,(042h<<16)|0463h,(0463h<<16)|0884h,(0884h<<16)|0884h,(0884h<<16)|0CA5h,(0CA5h<<16)|0CA5h,(0CA5h<<16)|0CA5h,(0CA5h<<16)|0CA5h,(0CA5h<<16)|0CA5h
	.word	(0CA5h<<16)|0CA5h,(0CA5h<<16)|010C6h,(010C6h<<16)|0CA5h,(0CA5h<<16)|010C6h,(0CA5h<<16)|010C6h,(010C6h<<16)|010C6h,(010C6h<<16)|010C6h,(010C6h<<16)|010C6h,(010C6h<<16)|010C6h
	.word	(014E7h<<16)|010C6h,(010C6h<<16)|010C6h,(010C6h<<16)|014E7h,(010C6h<<16)|010C6h,(014E7h<<16)|010C6h,(014E7h<<16)|014E7h,(014E7h<<16)|014E7h,(014E7h<<16)|014E7h,(014E7h<<16)|014E7h
	.word	(014E7h<<16)|014E7h,(014E7h<<16)|014E7h,(014E7h<<16)|01908h,(01908h<<16)|01D29h,(014E7h<<16)|01908h,(014E7h<<16)|01908h,(01908h<<16)|01908h,(01908h<<16)|01908h,(01908h<<16)|01908h
	.word	(01908h<<16)|014E7h,(01908h<<16)|01908h,(01908h<<16)|01D29h,(01908h<<16)|01908h,(01908h<<16)|010C6h,(01D29h<<16)|01908h,(01908h<<16)|01D29h,(01908h<<16)|01D29h,(01D29h<<16)|01908h
	.word	(01908h<<16)|01D29h,(01908h<<16)|01D29h,(01908h<<16)|01D29h,(01D29h<<16)|01D29h,(01D29h<<16)|01D29h,(01D29h<<16)|01D29h,(01D29h<<16)|01908h,(01D29h<<16)|01908h,(01D29h<<16)|01D29h
	.word	(01D29h<<16)|0214Ah,(01D29h<<16)|01D29h,(01D29h<<16)|01D29h,(01D29h<<16)|01D29h,(01D29h<<16)|0214Ah,(01D29h<<16)|0214Ah,(014E7h<<16)|01D29h,(01D29h<<16)|01D29h,(0214Ah<<16)|0214Ah
	.word	(0214Ah<<16)|01D29h,(0214Ah<<16)|01D29h,(0214Ah<<16)|0214Ah,(0214Ah<<16)|01D29h,(0214Ah<<16)|0214Ah,(0256Bh<<16)|01D29h,(0214Ah<<16)|0214Ah,(0214Ah<<16)|0214Ah,(01D29h<<16)|0214Ah
	.word	(0256Bh<<16)|014E7h,(01D29h<<16)|0214Ah,(0256Bh<<16)|0214Ah,(0214Ah<<16)|0214Ah,(0256Bh<<16)|0214Ah,(0214Ah<<16)|0256Bh,(0256Bh<<16)|0214Ah,(0214Ah<<16)|0214Ah,(0256Bh<<16)|0214Ah
	.word	(0256Bh<<16)|0256Bh,(0214Ah<<16)|0256Bh,(0256Bh<<16)|0214Ah,(0256Bh<<16)|0256Bh,(0214Ah<<16)|0256Bh,(0298Ch<<16)|0256Bh,(0256Bh<<16)|0214Ah,(0256Bh<<16)|0256Bh,(0256Bh<<16)|0256Bh
	.word	(0256Bh<<16)|01D29h,(0298Ch<<16)|0256Bh,(0298Ch<<16)|0256Bh,(0256Bh<<16)|0256Bh,(0298Ch<<16)|0298Ch,(0298Ch<<16)|0256Bh,(0298Ch<<16)|0298Ch,(0298Ch<<16)|01D29h,(0298Ch<<16)|0298Ch
	.word	(0298Ch<<16)|0298Ch,(0298Ch<<16)|0256Bh,(0298Ch<<16)|0298Ch,(0256Bh<<16)|0298Ch,(0298Ch<<16)|0298Ch,(0298Ch<<16)|0298Ch,(02DADh<<16)|02DADh,(0298Ch<<16)|02DADh,(02DADh<<16)|0298Ch
	.word	(0298Ch<<16)|02DADh,(02DADh<<16)|02DADh,(02DADh<<16)|02DADh,(0298Ch<<16)|02DADh,(02DADh<<16)|02DADh,(031CEh<<16)|02DADh,(02DADh<<16)|031CEh,(031CEh<<16)|031CEh,(031CEh<<16)|02DADh
	.word	(031CEh<<16)|031CEh,(02DADh<<16)|031CEh,(031CEh<<16)|031CEh,(031CEh<<16)|035EFh,(035EFh<<16)|031CEh,(031CEh<<16)|035EFh,(03A10h<<16)|035EFh,(02DADh<<16)|03E31h,(035EFh<<16)|03E31h
	.word	(03E31h<<16)|04252h,(04673h<<16)|04A94h
*----------------------------------------------------------------------------
	.text
	.END
