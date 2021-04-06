	.FILE	"HOTTUB.ASM"
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



	.globl	HT_HOTTUB,HT_RADAR,HT_STAGENT



BABA1	SPTR	"THE PRESIDENT OF"
BABA2	SPTR	"THE UNITED STATES"





*----------------------------------------------------------------------------
*
*
*JSRPed from BONUS SCREEN
*
HOTTUB_SCENE:
	LDI	1,R0
	.globl	DO_FOLDFLAG
	STI	R0,@DO_FOLDFLAG		;whoosh the text away

	CLRI	R0
	STI	R0,@NOAERASE

	LDI	@_MODE,R0
	OR	MINFIN|MWATER,R0
	STI	R0,@_MODE

	FLOAT	0,R0
	STF	R0,@INFIN_CORRECT
	


	CALL	OBJ_INIT


	LDI	@CAMERAPOSI,AR6
	FLOAT	-600,R0		;-100
	STF	R0,*+AR6(Y)
	CLRF	R0
	STF	R0,*+AR6(X)
	FLOAT	-12000,R0
	STF	R0,*+AR6(Z)


	LDF	0,R2
	LDP	@_CAMERARAD
	STF	R2,@_CAMERARAD+Y
	SETDP
	LDI	@CAMERAMATRIXI,AR2
	CALL	FIND_YMATRIX



	LDL	dc_PALETTES,AR2
	CALL	dealloc_section

	LDL	dc_shared_PALETTES,AR2
	CALL	alloc_section
	LDL	finale_PALETTES,AR2
	CALL	alloc_section



	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	CALL	FIFO_RESET

	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD
	LDL	_SECdc_shared,AR2
	CALL	LOAD_SECTION_REQ

	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD
	LDL	_SECfinale,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECdc_shared,AR2
	CALL	LOAD_SECTION_REQ




	LDI	@_MODE,R0
	ANDN	MINFIN|MWATER,R0
	STI	R0,@_MODE


	SOND1	LOWCOUNTRY
	SOND1	THEPRES		;"Ladies and gentlemen...


	LDL	preseal2,AR2
	CLRI	R2
	LDI	-30,R3
	LDI	368,RC
	CALL	OBJ_QMAKE
	.bss	PRES,1
	ORM	O_NOUNIV|O_POSTER|O_NOUROT,*+AR0(OFLAGS)
	LDI	AR0,AR2
	STI	AR2,@PRES
	CALL	OBJ_INSERTP


	LDI	@BABA1,AR2
	FLOAT	256,R2
	FLOAT	270,R3
	LDI	46,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)

	LDI	@BABA2,AR2
	FLOAT	256,R2
	FLOAT	300,R3
	LDI	46,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)

	CREATE	POLITICAL_CARTOON_NOTICE,1234h

	SLEEP	15


	CALL	SCREENWIPE_OPEN
	LDL	whitehse_grp,AR2
	CALL	LOAD_SINGLE_SECTION
	CALL	START_ANIMATIONS
	CREATE	HOTTUB_WATERVOL,1235h


	LDI	@_MODE,R0
	OR	MINFIN|MWATER,R0
	STI	R0,@_MODE

	SLEEP	5

	CREATE	PREZSPEAK,1234h

	SLEEP	25
	LDI	@PRES,AR2
	CALL	OBJ_DELETE
 
	SLEEP	30
	LDI	1,R0
	STI	R0,@NOAERASE

	LDI	180,AR5
;	LDI	210,AR5
HOTTUB_LPB
	LDI	@CAMERAPOSI,AR6

	LDF	*+AR6(Z),R0
	FLOAT	-1500,R1
	SUBF	R0,R1,R2
;	MPYF	0.02,R2
	MPYF	0.017,R2
	ADDF	R2,R0
	STF	R0,*+AR6(Z)

	LDF	*+AR6(Y),R0
	FLOAT	-4300,R1
	SUBF	R0,R1,R2
	MPYF	0.04,R2
	ADDF	R2,R0
	STF	R0,*+AR6(Y)

	SLEEP	1
	DBU	AR5,HOTTUB_LPB
	SLEEP	300

	CALL	SCREENWIPE_CLOSE

	LDI	1235h,R0
	LDI	-1,R1
	CALL	PRC_KILLALL
	LDI	FIREHYDRSND,AR2
	CALL	KILLSNDFX

	SOND1	CLIN8

	SLEEP	15


	SONDFX	CROWD1
	SONDFX	CROWDROAR

	LDI	100,AR5
HOTTUB_LPB2
	LDI	@CAMERAPOSI,AR6

	LDF	*+AR6(Z),R0
	FLOAT	-12000,R1
	SUBF	R0,R1,R2
	MPYF	0.01,R2
	ADDF	R2,R0
	STF	R0,*+AR6(Z)

	CMPI	60,AR5
	BNE	HOTTT
	SOND1	CLIN5
	LDI	3,R0 		;COOL LAST YEEHAH
	LDI	130,R1
	CALL	SET_TRACK_VOL

HOTTT
	SLEEP	1
	DBU	AR5,HOTTUB_LPB2


;moved to bonus.asm
;Wed Mar 8 09:52:21 1995
;
;	SLEEP	1
;
;	CALL	OBJ_INIT
;	CALL	INIT_DRONES	;initialize DRONE tracker system
;	CALL	DYNAOBJ_INIT	;initialize DYNAMIC OBJECTS
;	CALL	CARB_INIT	;initialize CAR BLOCKS
;	CALL	INIT_RDDEBRIS	;initialize ROAD DEBRIS list(s)
;
;
;	LDI	1234h,R0
;	LDI	-1,R1
;	CALL	PRC_KILLALL
;
;
;	LDI	SPAWNER_C|ANIMATION_T,R0
;	LDI	-1,R1
;	CALL	PRC_KILLALL
;
;
;	LDL	dc_shared_PALETTES,AR2
;	CALL	dealloc_section
;	LDL	finale_PALETTES,AR2
;	CALL	dealloc_section

	RETP
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
HOTTUB_WATERVOL:

	LDI	@WATCHOBJ,AR4
	LDF	*+AR4(OPOSX),R0
	LDI	@CAMERAPOSI,AR0
	SUBF	*+AR0(X),R0
	MPYF	R0,R0

	LDF	*+AR4(OPOSZ),R2
	SUBF	*+AR0(Z),R2
	MPYF	R2,R2

	ADDF	R0,R2
	CALL	SQRT


	;from  0-12,000  255
	;12,001-64,000  255-110
	;
	FLOAT	2000,R1
	CMPF	R1,R0
	BGT	NDOO

	LDI	205,R2
	BU	BIBO

NBIBO	LDI	10,R2
	BU	BIBO
NDOO

	FLOAT	12000,R2
	CMPF	R2,R0
	BGT	NBIBO

	SUBF	R1,R0
	MPYFL	0.0001,R0		;1/50,000
	SUBRF	1.0,R0
	MPYF	205,R0
	FIX	R0,R2

	CMPI	180,R2
	LDIGT	180,R2

BIBO	LDI	FIREHYDRSND,AR2
	CALL	AMBIENCE_SOUND
	SLEEP	1
	BU	HOTTUB_WATERVOL
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
PREZSPEAK:
	SLEEP	25
	SONDFX	CROWDROAR
	SLEEP	25
	SOND1	CLIN1	;Croozin USA
	SLEEP	44
	SOND1	CLIN2	;Come on Down
	SONDFX	CROWD1
	SLEEP	75
	SOND1	CLIN3	;I luv this job
	SONDFX	CROWDROAR
	SLEEP	50
	SOND1	CLIN5	;Yee HAW
	SLEEP	40
	SOND1	CLIN4	;Come in the hot tub
	SLEEP	60
	SOND1	CHICKCHEER
	SLEEP	70
	SOND1	CLIN6	;Well Hoo Eee
	SLEEP	30
	SONDFX	MOO
	SLEEP	40
	SOND1	CLIN7	;Hey Doggie
	DIE
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
START_ANIMATIONS:

	LDI	@OACTIVEI,AR4

ODC	LDI	*AR4,R3
	BZ	ODCX

	LDI	R3,AR4
ODCL2	LDI	*+AR4(OID),R2

	CMPI	6D0h,R2
	BNE	HHTT
	CALL	HT_HUNGH
	BU	ODC


HHTT
	CMPI	621h,R2
	BNE	NTT1

	CALL	HT_HOTTUB
	BU	ODC
NTT1	
	CMPI	622h,R2
	BNE	NTT1A

	CALL	HT_HILLY
	BU	ODC
NTT1A
	CMPI	623h,R2
	BNE	NTT1B

	CALL	HT_GIRL
	BU	ODC
NTT1B


	CMPI	615h,R2
	BNE	NTT2

	CALL	HT_RADAR
	BU	ODC
NTT2	CMPI	616h,R2
	BNE	ODC

	CALL	HT_STAGENT
	BU	ODC
ODCX	
	

	RETS
*----------------------------------------------------------------------------


ANI_HOTTUBI	.word	ANI_HOTTUB
ANI_HOTTUB	.word	htub,htub1,htub2,htub3,htub4,htub5,-1

HILLANII	.word	HILLANI
HILLANI		.word	hilly1,hilly2,hilly3,hilly4,hilly5,hilly6,-1

GIRLANII	.word	GIRLANI
GIRLANI		.word	girl1,girl2,girl3,girl4,girl5,girl6,-1

;hott1,hott2,hott3,hott4,hott5,hott6,-1

ANI_RADARI	.word	ANI_RADAR
ANI_RADAR	.word	rad1,rad2,rad3,rad4,rad5,rad6,rad7,rad8,rad9,-1

ANI_STAGI	.word	ANI_STAG
ANI_STAG	.word	stagent1,stagent2,stagent3,5,stagent2,-1


HT_HUNGH:
	PUSH	AR6

;	LDI	*+AR4(OPLINK),AR2
;	CALL	PRC_KILL

;	LDI	*+AR4(OFLAGS),R0
;	ANDN	O_POSTER,R0
;	STI	R0,*+AR4(OFLAGS)

	LDF	1.2,R0
	STF	R0,*+AR4(OMAT00)
	STF	R0,*+AR4(OMAT11)
	STF	R0,*+AR4(OMAT22)


	.globl	HUNGH_ANISI
	LDI	@HUNGH_ANISI,AR6
	CREATE	PLAINANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS
HT_RUT:
	PUSH	AR6

	LDI	*+AR4(OPLINK),AR2
	CALL	PRC_KILL

	LDI	*+AR4(OFLAGS),R0
	ANDN	O_POSTER,R0
	STI	R0,*+AR4(OFLAGS)

	.globl	RUT_ANISI
	LDI	@RUT_ANISI,AR6
	CREATE	PLAINANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS
	

	.bss	WATCHOBJ,1
HT_HILLY:
	PUSH	AR6
	LDI	@HILLANII,AR6
	CREATE	PLAINANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS

HT_GIRL:
	PUSH	AR6
	LDI	@GIRLANII,AR6
	CREATE	PLAINANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS

HT_HOTTUB:
	PUSH	AR6
	STI	AR4,@WATCHOBJ
	LDI	@ANI_HOTTUBI,AR6
	CREATE	PLAINANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS

HT_RADAR:
	PUSH	AR6
	LDI	@ANI_RADARI,AR6
	CREATE	PLAINANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS
HT_STAGENT:
	PUSH	AR6
	LDI	@ANI_STAGI,AR6
	CREATE	AGENTANI_PROC,SPAWNER_C|ANIMATION_T
	POP	AR6
	RETS


PLAINANI_PROC:
	LDI	AR6,AR5
PLAINANI_LP
	LDI	*AR5++,R0
	BLT	PLAINANI_PROC
	STI	R0,*+AR4(OROMDATA)

	LDI	9,R4
	RANDN	3
	ADDI	R0,R4

PPDD	SLEEP	1
	SUBI	@NFRAMES,R4
	BLE	PLAINANI_LP
	BU	PPDD
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
AGENTANI_PROC:

	RANDN	50
	LDI	R0,AR2
	ADDI	20,AR2
	CALL	SLEEP


	LDI	AR6,AR5
AGENTANI_LP

	LDI	*AR5++,R0
	BLT	AGENTANI_PROC

	CMPI	5,R0
	BNE	JKG
	SLEEP	12
	BU	AGENTANI_LP

JKG	STI	R0,*+AR4(OROMDATA)

	LDI	15,R4
PPDDA	SLEEP	1
	SUBI	@NFRAMES,R4
	BLE	AGENTANI_LP
	BU	PPDDA
*----------------------------------------------------------------------------

PC1	SPTR	"CELEBRITY IMPERSONATION"
PC2	SPTR	"POLITICAL CARTOON"


*----------------------------------------------------------------------------
POLITICAL_CARTOON_NOTICE:

	LDI	@PC1,AR2
	LDI	15,RC
	CALL	POLTXT

	SLEEP	26

	LDI	@PC2,AR2
	LDI	20,RC
	CALL	POLTXT
	DIE

POLTXT:
	FLOAT	256,R2
	FLOAT	20,R3
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)

	.globl	font18_white
	LDL	font18_white,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)
	STI	R0,*+AR1(TEXT_PAL)
	RETS

*----------------------------------------------------------------------------






BABE_ASTRT	.set	PDATA



*----------------------------------------------------------------------------
CROWD_IT:
	LDI	255,R2
	LDI	CROWD1,AR2
	CALL	AMBIENCE_SOUND
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
BABE_TROPHY:

;	SLEEP	6
	LDI	12,AR5
DABLP3	SLEEP	1
	SUBI	@NFRAMES,AR5
	CMPI	0,AR5
	LDILT	0,AR5
	DBU	AR5,DABLP3

	SOND1	GETREADYTUNE

	CALL	OBJ_GET
	LDI	AR0,AR4

	FLOAT	-50,R0
	STF	R0,*+AR4(OPOSX)
	FLOAT	310,R0
	STF	R0,*+AR4(OPOSY)
	FLOAT	368,R0
	STF	R0,*+AR4(OPOSZ)

	LDI	*+AR4(OFLAGS),R0
	OR	O_POSTER|O_NOUROT|O_NOUNIV,R0
	STI	R0,*+AR4(OFLAGS)

	LDL	here1,R0
	STI	R0,*+AR4(OROMDATA)


	READAUD	ADJ_GIRLS
	CMPI	0,R0
	BEQ	NODA

	LDI	AR4,AR2
	CALL	OBJ_INSERTP
NODA

	LDL	BABE_TROPHY_SCRIPT,AR6
	STI	AR6,*+AR7(BABE_ASTRT)

	LDI	11,AR5
BABE_LP
	LDF	*+AR4(OPOSY),R0
	SUBF	3,R0
	STF	R0,*+AR4(OPOSY)

	CALL	BABE_ANI
	CALL	CROWD_IT

	SLEEP	1

	LDF	*+AR4(OPOSY),R0
	SUBF	3,R0
	STF	R0,*+AR4(OPOSY)
	CALL	CROWD_IT
	SLEEP	1

	LDF	*+AR4(OPOSY),R0
	SUBF	3,R0
	STF	R0,*+AR4(OPOSY)
	CALL	CROWD_IT
	SLEEP	1
	DBU	AR5,BABE_LP


	LDI	13,AR5
BBD	CALL	BABE_ANI
	CALL	CROWD_IT
	SLEEP	3
	DBU	AR5,BBD

	SONDFX	CHICK_LAUGH


	LDI	27,AR5
BABE_LP2
	CALL	BABE_ANI
	CALL	CROWD_IT

	SLEEP	3
	DBU	AR5,BABE_LP2


;	LDI	25-1,AR5
	LDI	50-1,AR5
BABLP3	SLEEP	1
	SUBI	@NFRAMES,AR5
	CMPI	0,AR5
	LDILT	0,AR5
	DBU	AR5,BABLP3

BABE_TROPHYX

	CREATEC	BABE_IBO,UTIL_C
	LDI	*+AR7(BABE_ASTRT),R0
	STI	R0,*+AR0(BABE_ASTRT)
	RETP

*
*
BABE_IBO:
	LDI	6,AR5
BABE_LP3
	LDF	*+AR4(OPOSY),R0
	ADDF	15,R0
	STF	R0,*+AR4(OPOSY)
	SLEEP	1

	LDF	*+AR4(OPOSY),R0
	ADDF	15,R0
	STF	R0,*+AR4(OPOSY)
	SLEEP	1

	LDF	*+AR4(OPOSY),R0
	ADDF	15,R0
	STF	R0,*+AR4(OPOSY)
	SLEEP	1

	DBU	AR5,BABE_LP3

	LDI	0,R0
	LDI	100,R1
	CALL	SET_TRACK_VOL
	SOND1	MAPTUNE
	DIE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
BABE_ANI:
	LONGROUT
BABE_ANIKK
	LDI	*AR6++,R0
	BN	BX
	STI	R0,*+AR4(OROMDATA)
	RETS
BX	LDI	*+AR7(BABE_ASTRT),AR6
	BU	BABE_ANIKK
	END_LONGROUT
*----------------------------------------------------------------------------



BABE_TROPHY_SCRIPT
	.word	here1
	.word	here2
	.word	here3
	.word	here4
	.word	here5
	.word	here6
	.word	-1


BABE_FLAG_SCRIPT
	.word	flag1
	.word	flag2
	.word	flag3
	.word	flag4
	.word	flag5
	.word	flag6
	.word	flag7
	.word	-1





*----------------------------------------------------------------------------
*
*
*
*
*
BABE_WAVEFLAG:
	READAUD	ADJ_GIRLS
	CMPI	0,R0
	BEQ	SUICIDE

	CALL	OBJ_GET
	LDI	AR0,AR4

	FLOAT	-350,R0
	STF	R0,*+AR4(OPOSX)
	FLOAT	40,R0
	STF	R0,*+AR4(OPOSY)
	FLOAT	368,R0
	STF	R0,*+AR4(OPOSZ)

	LDI	*+AR4(OFLAGS),R0
	OR	O_POSTER|O_NOUROT|O_NOUNIV,R0
	STI	R0,*+AR4(OFLAGS)

	LDL	flag1,R0
	STI	R0,*+AR4(OROMDATA)
	LDI	AR4,AR2
	CALL	OBJ_INSERTP


BABEWTLP
	LDI	@BABE_CONTROL,R0
	BNZ	BABEGO

	LDF	*+AR4(OPOSX),R0
	FLOAT	-200,R1
	CMPF	R1,R0
	BGE	IBO2
	ADDF	5,R0
	STF	R0,*+AR4(OPOSX)
IBO2

	SLEEP	1
	BU	BABEWTLP

BABEGO

	LDI	17,AR5
BABERST
	LDL	BABE_FLAG_SCRIPT,AR6
BABE_LPWF
	LDI	*AR6++,R0
	BN	BABERST
	STI	R0,*+AR4(OROMDATA)

	SLEEP	2
	DBU	AR5,BABE_LPWF

	SLEEP	5



	LDI	16,AR5
BABEOFF
	LDF	*+AR4(OPOSX),R0
	SUBF	6,R0
	STF	R0,*+AR4(OPOSX)

	SLEEP	1

	LDF	*+AR4(OPOSX),R0
	SUBF	6,R0
	STF	R0,*+AR4(OPOSX)
	SLEEP	1
	DBU	AR5,BABEOFF


	LDI	AR4,AR2
	CALL	OBJ_DELETE
	DIE
*----------------------------------------------------------------------------
	.END
