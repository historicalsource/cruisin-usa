	.FILE	"ROADKILL.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*
	.include	MACS.EQU
	.include	OBJ.EQU
	.include	MPROC.EQU
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
ROADKILL_TABI	.word	ROADKILL_TAB

	.SECT	"THEDATA"
ROADKILL_TYPES	.set	2-1

RKT_DEATH	.set	0		;UH
RKT_SND		.set	1		;UH
RKT_PARTS	.set	2		;UH
RKT_WIDTHL	.set	3		;FL LEFT half the width
RKT_WIDTHR	.set	4		;FL RIGHT half the width
RKT_SIZE	.set	5

ROADKILL_TAB
		.word	deerc1,EXP3,COW_PARTS
		.float	-200,200			;SOON TO BE A COW
		.word	deerc1,EXP3,DEER_PARTS
		.float	-400,400			;DEER

	.text
	.bss	ROADKILLXZ,2

*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*This checks collisions between the Player and the roadkill. This is needed
*because the roadkill are to wide to be covered completely by the POINT
*collision routine.
*No special list is needed. This routine simply searches for the ID's. Seeing
*it is only checking agianst the player the overhead is nominal.

PLYRROADKILL:
	LDI	@PLYCAR,AR0
	CMPI	0,AR0
	BEQ	PLYRKX			;NO player at the moment

	LDI	@OACTIVEI,AR1
	LDI	*AR1,R0
	BEQ	PLYRKX
FINDLP
	LDI	R0,AR1
	LDI	*+AR1(OID),R0
	AND	CLASS_M|TYPE_M,R0
	CMPI	RDDEBRIS_C|TSC_ROADKILL,R0
	CALLEQ	CHECK_COLLISION
	LDI	*AR1,R0
	BNZ	FINDLP
PLYRKX
	LDF	0,R0
	STF	R0,@ROADKILLXZ
	STF	R0,@ROADKILLXZ+1
	RETS

*----------------------------------------------------------------------------
*AR0	= CAR OBJECT TO CHECK
*AR1	= ROADKILL OBJECT
CHECK_COLLISION:
	LDI	*+AR1(OID),R0
	AND	SUBTYPE_M,R0
	BZ	CCOLLX			;PARTS ARE NOT COLLIDEABLE
	CMPI	TSC_PARTS_S,R0
	BEQ	CCOLLX			;NORMALL COLLISION WILL DO IT FOR PARTS

	SUBI	1,R0
	MPYI	RKT_SIZE,R0
	LDI	R0,AR3			;AR3 = index into roadkill table
	ADDI	@ROADKILL_TABI,AR3
	LDF	*+AR3(RKT_WIDTHL),R4
	CALL	CHECK_OFFSET
	LDI	*+AR1(OID),R0
	AND	SUBTYPE_M,R0
	BZ	COFFX			;OBJECT_COLLIDED
	LDF	*+AR3(RKT_WIDTHR),R4
	CALL	CHECK_OFFSET
CCOLLX
	RETS
*----------------------------------------------------------------------------
*AR0	= CAR OBJECT TO CHECK
*AR1	= ROADKILL OBJECT
*R4	= OFFSET
CHECK_OFFSET:
	PUSH	AR3
	LDF	*+AR1(OPOSX),R0		;Set the roadkills real XZ coords
	STF	R0,@ROADKILLXZ		;A nonzero XZ will let the roadkill
	LDF	*+AR1(OPOSZ),R0		;know that it must use ROADKILLXZ as its
	STF	R0,@ROADKILLXZ+1	;real coords. The road kill will copy them back

	;Set the roadkills offset XZ coords
	LDP	@_CAMERARAD+X
	LDF	@_CAMERARAD+Y,R2
	SETDP
	CALL	NORMITS
	NEGF	R2
	CALL	_COSI
	MPYF	R4,R0
	ADDF	*+AR1(OPOSX),R0
	STF	R0,*+AR1(OPOSX)

	CALL	_SINE
	MPYF	R4,R0
	ADDF	*+AR1(OPOSZ),R0
	STF	R0,*+AR1(OPOSZ)

	CALL	COLSGCK			;This does the actual collision check
					;and also calls explode deer if collision exists
	LDI	*+AR1(OID),R0
	AND	SUBTYPE_M,R0
	BZ	COFFX			;OBJECT_COLLIDED

	LDF	@ROADKILLXZ,R0
	STF	R0,*+AR1(OPOSX)
	LDF	@ROADKILLXZ+1,R0
	STF	R0,*+AR1(OPOSZ)

COFFX
	POP	AR3
	RETS
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR1	OBJECT
*
*RETURNS
*	C	IS A FLYER
*	NC	NOT A FLYER
*
*
ROADKILL_FLYERP:
	PUSH	R0
	PUSH	AR2

	LDI	*+AR1(ODIST),R0
	CMPI	30000,R0
	BGT	RKFPX
	LDI	*+AR1(OID),R0
	AND	SUBTYPE_M,R0
	CMPI	TSC_PARTS_S,R0
	BNE	NORMAL_ROADKILL
	CALL	FLYING_PARTS		;HANDLE COLLISION
	BR	RKFPX
NORMAL_ROADKILL
	CALL	ROADKILL_SETKILL


	LDF	@ROADKILLXZ,R0
	ADDF	@ROADKILLXZ+1,R0
	BZ	RKFP

	LDF	@ROADKILLXZ,R0
	STF	R0,*+AR1(OPOSX)
	LDF	@ROADKILLXZ+1,R0
	STF	R0,*+AR1(OPOSZ)
RKFP
	CALL	DEER_EXPLODE
RKFPX
	CLRC			;flying taken car of
	POP	AR2
	POP	R0
	RETS
*----------------------------------------------------------------------------
*
*
*
*
	.data
SOUNDTIME	.float	0.00204678	;7(1/60)/57 of a minute
	.text
	.bss	ROADKILL_SOUND_TIMER,1

ROADKILL_HIT:
	PUSH	R0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR4

	LDF	@GAME_TIMER,R0
	SUBF	@ROADKILL_SOUND_TIMER,R0
	CMPF	@SOUNDTIME,R0
	BLT	PKQ			;not enough time has lappsed since the last sound
	LDF	@GAME_TIMER,R0
	STF	R0,@ROADKILL_SOUND_TIMER

	LDI	*+AR1(OID),AR2
	AND	SUBTYPE_M,AR2
	CMPI	0,AR2
	BZ	PKQ
	CMPI	TSC_PARTS_S,AR2
	BZ	PKQ
	SUBI	1,AR2
	MPYI	RKT_SIZE,AR2
	ADDI	@ROADKILL_TABI,AR2
	LDI	*+AR2(RKT_SND),AR2

	LDI	*+AR0(OID),R0		;CAR that hit the animal
	AND	CLASS_M,R0
	CMPI	PLYR_C,R0
	BEQ	DO_PLYR

	LDI	AR0,AR4			;A drone hit the animal
	CALL	DRONESND1
	BR	PKQ
DO_PLYR
	CALL	ONESNDFX

;	LDI	*+AR1(OID),AR2
;	AND	SUBTYPE_M,AR2
;	CMPI	TSC_DEER_S,AR2
;	BNE	PKQ

	LDI	MOO,AR2
	CALL	KILLSNDFX

	LDI	EXP1,AR2
	CALL	ONESNDFX

;	LDI	0,R0
;	LDI	0,R1
;	CALL	SET_TRACK_VOL
	BU	PKQ

PKQ	POP	AR4
	POP	AR2
	POP	AR1
	POP	R0
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*INPUT	AR1 = OBJECT
*
*PARAMTERS
*
ROADKILL_SETKILL:
	PUSH	AR0
	PUSH	AR3
	LDI	*+AR1(OLINK4),AR0
	CMPI	-1,AR0
	BEQ	NNWAY

	LDI	*+AR1(OID),AR3
	AND	SUBTYPE_M,AR3
	SUBI	1,AR3
	MPYI	RKT_SIZE,AR3
	ADDI	@ROADKILL_TABI,AR3

	LDI	*+AR3(RKT_DEATH),AR0
	STI	AR0,*+AR1(OROMDATA)

RS1
	LDI	-1,AR0
	STI	AR0,*+AR4(OLINK4)
NNWAY
	POP	AR3
	POP	AR0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*INPUT
*	R1 = hight off ground
*
*OUTPUT
*	C = 0,no ground under object
*	C = 1,Ground under object

OBJ_MOVE_GROUND:
	LDI	AR4,AR2
	ADDI	OVELX,AR2
	LDI	AR4,R2
	ADDI	OMATRIX,R2
	LDI	@VECTORAI,R3
	CALL	MATRIX_MUL

	LDI	@VECTORAI,AR0
	LDF	*+AR0(X),R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR0(Z),R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	PUSH	AR4
	PUSHF	R1
	ADDI	OPOSX,AR4
	CALL	CAMSCAN
	POPF	R1
	POP	AR4
	BNC	OMGX
	SUBF	R1,R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
	SETC
OMGX
	RETS

*----------------------------------------------------------------------------
*Sets ORADY, OMATRIX, and AR0 to 10 tracks down the road
*
*
GET_ROADKILL_TRACK:
	LDI	@PLYCBLK,AR2
	LDI	*+AR2(CARTRAK),R0
	LDI	R0,AR0
	LDI	20,AR1
GRT_FF
	LDI	AR0,AR2
	LDI	R0,AR0
	LDI	*+AR0(OLINK4),R0
	BEQ	OUT_OF_TRACK
	DBU	AR1,GRT_FF
OUT_OF_TRACK
	LDF	*+AR0(OPOSX),R2
	SUBF	*+AR2(OPOSX),R2
	LDF	*+AR0(OPOSZ),R3
	SUBF	*+AR2(OPOSZ),R3
	CALL	ARCTANF
	SUBF	HALFPI,R0
	LDF	R0,R2				;FIND THETA

	STF	R2,*+AR4(ORADY)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX			;FIND Y MATRIX (FOR LANE OFFSETTING)

	RETS

*----------------------------------------------------------------------------
*INPUT		R2= PID to count
*RETURNS	R0= number of active procs
*Trashes AR0,R1

PROC_COUNT:
	LDI	0,R0
	LDI	@PACTIVEI,R1
	RETSZ				;NULL LIST?
PCLP
	LDI	R1,AR0
	LDI	*+AR0(PID),R1
	CMPI	R2,R1
	BNE	PC1
	ADDI	1,R0
PC1
	LDI	*AR0,R1
	BNZ	PCLP
	RETS

*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*	.FILE	"COW.ASM"
*----------------------------------------------------------------------------
	.SECT "THEDATA"
	.include	cow.pal
	.text

*----------------------------------------------------------------------------
* COW_SPAWNER_PROC	PROC
*This PROC has a COW
*	CREATE	COW_SPAWNER_PROC,SPAWNER_C
*
COW_SPAWNER_PROC:
	READADJ	ADJ_ROADKILL
	CMPI	0,R0
	BEQ	CSPX

	LDI	adblud1_p,AR2		;overwrite the deer parts with the cow palette
	CALL	PAL_FIND
	BC	CSPSLEEP
	LDI	R0,R2
	LDL	cow_pal,AR2
	LDI	*AR2++,R3
	CALL	PAL_SET

CSPSLEEP
	SLEEP	1			;wait for game to start
	LDI	@_MODE,R0
	AND	MGO,R0
	BZ	CSPSLEEP

CSPLP
	SLEEP	30*20
;	SLEEP	30*5
	LDI	500,AR2
	CALL	RANDPER
	BNC	CSPLP

	LDI	RDDEBRIS_C|TSC_ROADKILL|TSC_COW_S,R2
	CALL	PROC_COUNT
	CMPI	1,R0
	BGE	CSPLP
	CREATE	COW_PROC,RDDEBRIS_C|TSC_ROADKILL|TSC_COW_S
	BR	CSPLP
CSPX
	DIE
*----------------------------------------------------------------------------
* COW_PROC	PROC
*Maintains a COW
*	CREATE	COW_PROC,RDDEBRIS_C|TSC_ROADKILL|TSC_COW_S
LOOP_COUNT	.set	PDATA
TOTAL_FRAMES	.set	PDATA+1
COW_PROC:
	LDL	kow3,AR2
	FLOAT	10,R4			;Hight of a cow
	CALL	INIT_COW
	BC	COW_DIE
	LDF	0,R0
	STF	R0,*+AR7(LOOP_COUNT)
	STF	R0,*+AR7(TOTAL_FRAMES)
COW_WAIT
	SLEEP	1
	LDF	1,R1
	ADDF	*+AR7(LOOP_COUNT),R1
	STF	R1,*+AR7(LOOP_COUNT)

	FLOAT	@NFRAMES,R0
	ADDF	*+AR7(TOTAL_FRAMES),R0
	STF	R0,*+AR7(TOTAL_FRAMES)
	CALL	DIV_F
	LDF	R0,R1

	LDI	@PLYCBLK,AR5
	MPYF	*+AR5(CARSPEED),R1
	MPYF	1.5,R1			;CARSPEED FUDGE 'O RAMA
	FLOAT	*+AR4(ODIST),R0
	CALL	DIV_F
	CMPF	20,R0			;APPROX NUMBER OF FRAMES TO COW
	BGT	COW_WAIT
	SONDFX	MOO
COW_SLEEP
	SLEEP	100			;THIS IS NEEDED FOR COW COUNTING
	BR	COW_SLEEP

COW_DIE
	DIE

*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*	.FILE	"DEER.ASM"
*----------------------------------------------------------------------------
	.data
DEERANII	.word	DEERANI

	.SECT	"THEDATA"
DEERANI
	.word	edeer,edeer1,edeer2,edeer3,edeer4,edeer5,-1

	.text
*----------------------------------------------------------------------------
* DEER_SPAWNER_PROC	PROC
*Maintains several DEER animations
*	CREATE	DEER_SPAWNER_PROC,SPAWNER_C
*
DEER_SPAWNER_PROC:
	READADJ	ADJ_ROADKILL
	CMPI	0,R0
	BEQ	DSPX
	SLEEP	1			;wait for game to start
	LDI	@_MODE,R0
	AND	MGO,R0
	BZ	DEER_SPAWNER_PROC

DSPLP
	SLEEP	30*20
;	SLEEP	30*2
	LDI	500,AR2
	CALL	RANDPER
	BNC	DSPLP

	LDI	RDDEBRIS_C|TSC_ROADKILL|TSC_DEER_S,R2
	CALL	PROC_COUNT
	CMPI	1,R0
	BGE	DSPLP
	CREATE	DEER_PROC,RDDEBRIS_C|TSC_ROADKILL|TSC_DEER_S
	BR	DSPLP
DSPX
	DIE
*----------------------------------------------------------------------------
* DEER_PROC	PROC
*Maintains several DEER animations
*	CREATE	DEER_PROC,RDDEBRIS_C|TSC_ROADKILL|TSC_DEER_S

DEER_PROC:
	FLOAT	219,R4			;Hight of a deer
	CALL	INIT_DEER
	BC	DEER_DIE
	LDI	@DEERANII,AR6
DEERANI_LOOP

	LDI	*++AR6,R0
	LDIN	@DEERANII,AR6

	LDI	*AR6,R0
	STI	R0,*+AR4(OROMDATA)

DEER_SLEEP
	SLEEP	3			;frame rate of 3
	BR	DEERANI_LOOP		;Ultimatly backgrnd or colla will kill this proc
DEER_DIE
	DIE

*----------------------------------------------------------------------------
* INIT_DEER
*INPUT R4 = hight to place off ground
*Creates and maintains a DEER animation

INIT_DEER:
	LDI	@DEERANII,AR6

	LDI	*AR6,AR2
INIT_COW:
	LDF	1,R6
	CALL	OBJ_GETE
	BC	INIT_DEERX
	LDI	AR0,AR4

	CALL	ADD_RDDEBRIS

	LDI	1,R0			;PROC ME BABY
	LS	O_PROC_B,R0
	OR	*+AR4(OFLAGS),R0
	STI	R0,*+AR4(OFLAGS)
	STI	AR7,*+AR4(OPLINK)

;	LDI	RDDEBRIS_C|TSC_ROADKILL|TSC_DEER_S,R0
	LDI	*+AR7(PID),R0		;MAKE SAME AS PROC
	STI	R0,*+AR4(OID)

	CALL	GET_ROADKILL_TRACK

	FLOAT	500,R0			;calculate the random offset that this obj will have
	CALL	SFRAND
	LDF	R0,R1
	FLOAT	500,R0
	CALL	SFRAND
	LDF	R0,R2

	LDF	*+AR0(OPOSX),R0			;set to road position
	ADDF	R1,R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR0(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR0(OPOSZ),R0
	ADDF	R2,R0
	STF	R0,*+AR4(OPOSZ)

	FLOAT	750,R0			;Side of road
	MPYF	R6,R0
	STF	R0,*+AR4(OVELX)
	
	LDF	R4,R1			;Hight above ground
	CALL	OBJ_MOVE_GROUND		;Offset the starting point

	LDI	AR4,AR2
	CALL	OBJ_INSERT

	CLRC
INIT_DEERX
	RETS


*----------------------------------------------------------------------------
	.data
SPINSPEEDF	.float	0.0002

	.SECT	"THEDATA"

COW_PARTS
	.word	deerc1,1,deerc1,1,deerc2,0,deerc2,0,deerc3,0,deerc4,0
	.word	deerc1,1,deerc1,1,deerc2,0,deerc2,0,deerc3,0,deerc4,0
	.word	deerc1,1,deerc1,1,deerc2,0,deerc2,0,deerc3,0,deerc4,0,-1

DEER_PARTS
	.word	deerc1,1,deerc1,1,deerc2,0,deerc2,0,deerc3,0
	.word	deerc4,0,antler,0,antler,0,dheada,0
	.word	dheada,1,dheada,1,deerc1,1,deerc1,1,deerc2,0
	.word	deerc2,0,deerc3,0,deerc4,0,-1

	.text

DEER_EXPLODE:				;called from within colla
	CALL	PUSHALL

	LDI	AR1,AR6		;save off pointer to deer's object
	LDI	*+AR6(OID),R0
	AND	SUBTYPE_M,R0
	SUBI	1,R0
	MPYI	RKT_SIZE,R0
	LDI	R0,AR1
	ADDI	@ROADKILL_TABI,AR1
	LDI	*+AR1(RKT_PARTS),AR1

;	LDI	@DEER_PARTSI,AR1
	LDI	RDDEBRIS_C|TSC_ROADKILL,R0
	STI	R0,*+AR6(OID)
MAKE_PARTSLP
	LDI	*AR1++,R0
	BN	DEER_EXPX
	LDI	R0,AR2
	CALL	OBJ_GETE
	BC	DEER_EXPX
	PUSH	AR1

	LDI	AR0,AR4
	CALL	ADD_RDDEBRIS

	LDI	RDDEBRIS_C|TSC_ROADKILL,R0
	STI	R0,*+AR4(OID)

	LDF	*+AR6(OPOSX),R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR6(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR6(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	CALL	FLY_PARTS

	LDI	AR4,AR2
	CALL	OBJ_INSERT
	POP	AR1

	LDI	*AR1++,R0
	CALLNE	MAKE_NOCOLL
	BR	MAKE_PARTSLP
DEER_EXPX
	LDI	AR6,AR4
	NEGF	*+AR4(OVELX),R7		;Deer distance from center
	CALL	FLY_PARTS
	CREATEC	DEER_BLOOD_PROC,UTIL_C

	LDI	@CAMVIEW,R0
	BZ	NO_SPINOUT		;First person

	LDF	*+AR5(CARDIST2CNTR),R0
	SUBF	R0,R7			;Deer distance from center
	LDF	*+AR5(CARSPEED),R0	;SPINSPEED = SPEED+distance to center of deer
	CMPF	0,R7
	BGE	NO_NEG
	NEGF	R0
NO_NEG
	ADDF	R7,R0


	LDF	@SPINSPEEDF,R1
	MPYF	R1,R0			;SPIN SPEED factor adjustment	
	ABSF	R0,R1
	CMPF	0.06,R1
	BLT	NO_SPINOUT		;To slow to spin
	STF	R0,*+AR5(CARDROT)
	LDF	3.14,R0
	STF	R0,*+AR5(CARSPRAD)
	LDI	1,R0
	STI	R0,*+AR5(CAR_SPIN)
NO_SPINOUT

	LDF	*+AR5(CARSPEED),R0		;Nuke the car that hit it
	MPYF	0.5,R0
	STF	R0,*+AR5(CARSPEED)
	CALL	POPALL
	RETS


MAKE_NOCOLL:
	LDI	RDDEBRIS_C|TSC_ROADKILL|TSC_PARTS_S,R0
	STI	R0,*+AR4(OID)
	LDI	*+AR4(OFLAGS),R0
	ANDN	O_NOCOLL,R0
	STI	R0,*+AR4(OFLAGS)
	RETS
*----------------------------------------------------------------------------
*DEER_BLOOD_PROC	PROC
*
*INPUT
*	AR4	= THE DEER
*	AR5	= CARBLK THAT HIT THE DEER
*Creates and maintains a single blood animation
*	CREATEC	DEER_BLOOD_PROC,UTIL_C

	.SECT	"THEDATA"
DEERBLOOD_ANI	.word	adblud1,adblud2,adblud3,adblud4,adblud5,adblud6,-1
	.text

DEER_BLOOD_PROC:
	LDL	DEERBLOOD_ANI,AR6
	LDI	*AR6++,AR2
	CALL	OBJ_GETE
	BC	DBP_DIE

	ORM	O_POSTER|O_NOCOLL,*+AR0(OFLAGS)

	LDF	*+AR4(OPOSX),R0
	STF	R0,*+AR0(OPOSX)
	LDF	*+AR4(OPOSY),R0
	ADDF	-150,R0
	STF	R0,*+AR0(OPOSY)
	LDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)
	LDI	AR0,AR4

	LDF	*+AR5(CARVROT),R2
	CALL	_SINE
	NEGF	R0,R3
	CALL	_COSI

	LDF	*+AR5(CARSPEED),R1	;GET CURRENT SPEED
	MPYF	1.5,R1
	MPYF	1.5,R1			;150% the speed of the car
	MPYF	R1,R3	
	MPYF	R1,R0
	STF	R3,*+AR4(OVELX)	       	;SETUP VELOCITIES
	STF	R0,*+AR4(OVELZ)

	CALL	OVELNADD		;Update position based on velocity

	LDI	AR4,AR2
	CALL	OBJ_INSERT
DBP_LP
	SLEEP	1
	LDI	*AR6++,R0
	BN	DBP_DONE
	STI	R0,*+AR4(OROMDATA)	
	CALL	OVELNADD		;Update position based on velocity
	BR	DBP_LP
DBP_DONE
	LDI	AR4,AR2
	CALL	OBJ_DELETE
DBP_DIE
	DIE


*----------------------------------------------------------------------------
*CALLABLE FROM COLLA
FLYING_PARTS:
	CALL	PUSHALL
	LDI	AR1,AR4
	CALL	FLY_PARTS
	CALL	MAKE_NOCOLL
	CALL	POPALL
	RETS

*----------------------------------------------------------------------------
*
*FLY PARTS			;YES THIS WAS RIPPED OF FROM COLLA
*	AR5	POINTS TO CAR OBJECT
*	AR4	POINTS TO OBJECT HIT
*This routine is needed to insure that the parts do fly
*When I just simply added them the would not collide with the cars if they were going fast

FLY_PARTS:
	LDI	@CAMVIEW,R0
	LDFZ	1.5,R6			;First person
	LDFNZ	2.4,R6			;Not first person
	LDF	1.0,R1

	LDF	0.12,R0 		;ADD RANDOM ROTATION
	MPYF	R6,R0
	CALL	SFRAND
	LDF	R0,R2

	ADDF	*+AR5(CARVROT),R2

	LDF	0.50,R0			;RANDOM SPEED MULTIPLIER
	MPYF	R6,R0
	CALL	FRAND
	LDF	R0,R1
	ADDF	0.7,R1
;	MPYF	1.3,R1			;SPEEDFUDGE FACTOR

	CALL	_SINE
	NEGF	R0,R3
	CALL	_COSI

	LDF	*+AR5(CARSPEED),R2	;GET CURRENT SPEED
	CMPF	100,R2
	LDFLT	100,R2
	MPYF	R2,R1

	MPYF	R1,R3	
	MPYF	R1,R0
	STF	R3,*+AR4(OVELX)	       	;SETUP VELOCITIES
	STF	R0,*+AR4(OVELZ)

	LDF	-0.05,R0
	MPYF	R6,R0
	CALL	FRAND	
	LDF	-0.10,R1
	MPYF	R6,R1
	ADDF	R1,R0
	MPYF	1.5,R0			;SPEEDFUDGE FACTOR

;	MPYF	*+AR5(CARSPEED),R0	;GET CURRENT SPEED
	MPYF	R2,R0
	LDF	-27,R1
	MPYF	R6,R1
	CMPF	R1,R0
	LDFLT	R1,R0		  	;MAX VERTICAL VELOCITY

	STF	R0,*+AR4(OVELY)		;STUFF VERTICAL VELOCITY

	LDI	1,R0
	LSH	O_PROC_B,R0		;PROCESS BIT MASK IN OBJECT STRUCT
	TSTB	*+AR4(OFLAGS),R0	;PROCESS ALREADY ACTIVE	?

	LDINZ	*+AR4(OPLINK),AR2	;YES, KILL HIM OFF...
	CALLNZ	PRC_KILL

	LDI	@FLYCOLLPI,AR2		;GET SIGN FLY PROCESS
	LDI	DRONE_C|FLYER_T,R2
	CALL	PRC_CREATE_CHILD	;CREATE A PROCESS
	BC	FLY_PARTSX		;NOTHING AVAILABLE, QUIT

	STI	AR0,*+AR4(OPLINK)	;SAVE PROCESS LINK

	LDI	1,R0
	LSH	O_3DROT_B,R0		;FLAG CAN AS NON-2D OPTIMIZABLE

	LDI	1,R1
	LSH	O_PROC_B,R1		;PROCESS BIT MASK IN OBJECT STRUCT
	ADDI	R1,R0

	OR	*+AR4(OFLAGS),R0	;SET YOUR FLAGS...	
	OR	O_NOCOLL,R0		;Parts can only be hit once
	STI	R0,*+AR4(OFLAGS)

	LDI	0,R0			;KILL OFF GROUP REFERENCE
	STI	R0,*+AR4(OLINK2)
FLY_PARTSX
	RETS


*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*	.FILE	"GEESE.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*
	.data
GEESEANII	.word	GEESEANI
GEESE_DIRI	.word	GEESE_DIR
	.SECT "THEDATA"
GEESEANI:
	.word	geese1,geeseb,geesec,geesed
	.word	geesee,geesef,geeseg,geeseh,-1

GEESE_DIR:
	.word	250,1
	.float	0
	.word	150,-1
	.float	0
	.word	150,-1
	.float	-0.13
	.word	250,1
	.float	-0.13

	.text

*----------------------------------------------------------------------------
SPEED		.set	PDATA
DIRECTION	.set	PDATA+1
DIR_RAD		.set	PDATA+2
NUM_SPLATS	.set	PDATA+3
*----------------------------------------------------------------------------
GEESE_SPAWNER:
	SLEEP	1
	LDI	@PLYCAR,R0
	BZ	GEESE_SPAWNER
	LDI	@_MODE,R0
	AND	MGO,R0
	BZ	GEESE_SPAWNER
GOOSE_ME
	SLEEP	30*20		;sleep approx. 20 seconds
;	SLEEP	30*5

	LDI	500,AR2
	CALL	RANDPER
	BNC	GOOSE_ME

	LDI	4,AR2
	CALL	RANDU0
	MPYI	3,R0
	LDI	@GEESE_DIRI,AR0
	ADDI	R0,AR0

	LDI	*AR0++,R4
	LDI	*AR0++,R5
		;register is pushed as INT
	LDF	*AR0++,R6
	CREATE	GEESE_PROC,UTIL_C
	BR	GOOSE_ME

*----------------------------------------------------------------------------
* Set by Spawner:
*	R4	=	SPEED
*	R5	=	DIRECTION INT (+/-1, Direction to travers road)
*	R6	=	RADS direction FL 
SHIT_ANII	.word	SHIT_ANI
	.SECT	"THEDATA"
SHIT_ANI	.word	bdst,bdst2,bdst3,bdst4,bdst5,bdst6,-1
	.text

GEESE_PROC:
	FLOAT	R4
	STF	R4,*+AR7(SPEED)
	STI	R5,*+AR7(DIRECTION)
	STF	R6,*+AR7(DIR_RAD)

	LDI	0,R0
	STI	R0,*+AR7(NUM_SPLATS)

	CALL	OBJ_GET
	BC	GEESE_DIE

	LDI	AR0,AR4

	SONDFX	GEESES


	LDI	@PLYCBLK,AR2
	LDI	*+AR2(CARTRAK),AR2	;Get the track piece the car is on
	LDI	*+AR2(OUSR1),R2

	CALL	FIND_MAP
	ADDI	20*4,AR2		;bump it up 40 road segments
	LDI	AR2,AR6			;save pointer to ROAD LEG

	FLOAT	*+AR6(X),R0
	STF	R0,*+AR4(OPOSX)
	
	LDF	*+AR7(DIR_RAD),R2	;flying with the road?
	CMPF	0,R2
	BEQ	NO_XOFFSET

	LDI	*+AR7(DIRECTION),R2
	LDI	AR6,AR2
	CALL	GET_ROAD_RADY
	ADDF	HALFPI,R2	
	
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX

	CALL	CLR_VECTORA		;Move the flock ('o geese off the side of the road)
	FLOAT	2500,R0
	STF	R0,*+AR2(Z)
	LDI	@MATRIXAI,R2
	LDI	AR2,R3
	CALL	MATRIX_MUL

	LDF	*+AR4(OPOSX),R0
	ADDF	*+AR2(X),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OPOSZ),R0
	ADDF	*+AR2(Z),R0
	STF	R0,*+AR4(OPOSZ)

NO_XOFFSET
	FLOAT	-3000,R1
	FLOAT	*+AR6(Y),R0
	ADDF	R1,R0
	STF	R0,*+AR4(OPOSY)
	FLOAT	*+AR6(Z),R0
	STF	R0,*+AR4(OPOSZ)

	LDI	AR4,AR2
	CALL	OBJ_INSERT

GEESERST
	LDI	@GEESEANII,AR5

GEESELP
	LDI	*AR5++,R0
	BN	GEESERST

	STI	R0,*+AR4(OROMDATA)

	LDI	*+AR7(DIRECTION),R2
	LDI	AR6,AR2
	CALL	GET_ROAD_RADY
	ADDF	*+AR7(DIR_RAD),R2
	PUSHF	R2
	ADDF	PI,R2			;Geese point in wrong direction
	STF	R2,*+AR4(ORADY)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX

	POPF	R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX

	CALL	CLR_VECTORA		;Move the flock ('o geese)
	LDI	@PLYCBLK,AR0
	LDF	*+AR0(CARSPEED),R0
	MPYF	0.4,R0
	LDI	*+AR7(DIRECTION),R1
	MPYI	@NFRAMES,R1
	FLOAT	R1
	MPYF	R1,R0
	ADDF	*+AR7(SPEED),R0

	STF	R0,*+AR2(Z)
	LDI	@MATRIXAI,R2
	LDI	AR2,R3
	CALL	MATRIX_MUL

	LDF	*+AR4(OPOSX),R0
	ADDF	*+AR2(X),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OPOSZ),R0
	ADDF	*+AR2(Z),R0
	STF	R0,*+AR4(OPOSZ)

	PUSH	AR4
	ADDI	OPOSX,AR4
	CALL	CAMSCAN
	POP	AR4
	BNC	GEESE_DONE		;FLU off the edge of the earth
	FLOAT	3000,R1
	SUBF	R1,R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
OFF_MAP
	LDI	AR6,AR2
	LDI	*+AR7(DIRECTION),R2
	CALL	NEXT_ROAD
	LDI	AR2,AR6
	CMPI	@LEG_MAPI,AR6
	BLE	GEESE_DONE

	LDI	@PLYCBLK,AR2
	LDI	*+AR2(CARTRAK),AR2	;Get the track piece the car is on
	LDI	*+AR2(OUSR1),R2

	CALL	FIND_MAP
	LDI	AR2,AR0
	ADDI	-10*4,AR2		;track sections behind the player
	CMPI	AR2,AR6
	BLE	GEESE_DONE

	ADDI	30*4,AR0		;track sections beyond the player
	CMPI	AR0,AR6
	BGE	GEESE_DONE

GEESE_SLEEP
	SLEEP	1

	READADJ	ADJ_ROADKILL
	CMPI	0,R0
	BEQ	NO_SPLAT

	LDI	@CAMVIEW,R0
	BNZ	NO_SPLAT		;NOT in First person
	
	LDI	*+AR4(ODIST),R0
	BN	NO_SPLAT

	CALL	DIST_TO_PLYR
	FLOAT	5000,R1
	CMPF	R1,R0
	BGT	NO_SPLAT

	LDI	AR6,AR2
	LDI	1,R2
	CALL	GET_ROAD_RADY
	NEGF	R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX
	CALL	CLR_VECTORA
	FLOAT	*+AR6(X),R1
	LDF	*+AR4(OPOSX),R0
	SUBF	R1,R0
	STF	R0,*+AR2(X)

	FLOAT	*+AR6(Z),R1
	LDF	*+AR4(OPOSZ),R0
	SUBF	R1,R0
	STF	R0,*+AR2(Z)

	LDI	@MATRIXAI,R2
	LDI	@VECTORAI,R3
	LDI	R3,AR3
	CALL	MATRIX_MUL

	LDI	@VECTORAI,AR0
	LDF	*+AR0(X),R0
	LDI	@PLYCBLK,AR0
	SUBF	*+AR0(CARDIST2CNTR),R0
	ABSF	R0
	FLOAT	2000,R1
	CMPF	R1,R0
	BGT	NO_SPLAT


	LDI	800,AR2
	CALL	RANDPER
	BNC	NO_SPLAT
	LDI	*+AR7(NUM_SPLATS),R0
	CMPI	6,R0
	BGT	NO_SPLAT
	ADDI	1,R0
	STI	R0,*+AR7(NUM_SPLATS)
	LDI	@SHIT_ANII,R5
	CREATE	SPLAT_PROC,UTIL_C	;The SPLAT will hit the windshield

NO_SPLAT
	BU	GEESELP

GEESE_DONE
	LDI	AR4,AR2
	CALL	OBJ_DELETE
	LDI	GEESES,AR2
	CALL	KILLSNDFX
GEESE_DIE
	DIE

*---------------------------------------------------------------------------
*---------------------------------------------------------------------------
*---------------------------------------------------------------------------
*----------------------------------------------------------------------------
* BUG_SPAWNER_PROC	PROC
*Creates several BUG SPLAT PROCS
*	CREATE	BUG_SPAWNER_PROC,SPAWNER_C
*
BUG_ANII	.word	BUG_ANI
	.SECT	"THEDATA"
BUG_ANI	.word	bug1,bug2,bug3,bug4,bug5,-1
	.text

BUG_SPAWNER_PROC:
	READADJ	ADJ_ROADKILL
	CMPI	0,R0
	BEQ	BSPX

	SLEEP	1			;wait for game to start
	LDI	@_MODE,R0
	AND	MGO,R0
	BZ	BUG_SPAWNER_PROC

BSPLP
	SLEEP	30*5
	LDI	@CAMVIEW,R0
	BNZ	BSPLP			;NOT in First person

	LDI	300,AR2
	CALL	RANDPER
	BNC	BSPLP

	SONDFX	BUGBUZZ
	SONDFX	BUGBUZZ
	SLEEP	10

	LDI	@BUG_ANII,R5
	CREATE	SPLAT_PROC,UTIL_C	;The SPLAT will hit the windshield
	SLEEP	30*20			;20 seconds before another bug can apear
	BR	BSPLP
BSPX
	DIE

*---------------------------------------------------------------------------
*SPLAT PROC
*R5 points to start of animation

SPLAT_PROC:
	LDI	@PLYCBLK,AR5
	LDI	R5,AR6
	LDI	*AR6++,AR2
	CALL	OBJ_GETE
	LDI	AR0,AR4

	LDI	PLYR_C|PLYR_SPLAT_S,R0
	STI	R0,*+AR4(OID)

	LDF	100,R0
	CALL	SFRAND
	STF	R0,*+AR4(OPOSX)

	FLOAT	-300,R0
	STF	R0,*+AR4(OPOSY)

	FLOAT	2000,R0
	STF	R0,*+AR4(OPOSZ)

	LDI	O_POSTER|O_NOCOLL|O_NOROTS|O_NOUNIV,R0
	OR	*+AR4(OFLAGS),R0
	STI	R0,*+AR4(OFLAGS)
	LDI	AR4,AR2
	CALL	OBJ_INSERTP

	LDF	1,R0
	CALL	FRAND
	ADDF	1.2,R0
	LDF	R0,R6
	MPYF	0.1,R6
SPLAT_LP
	SLEEP	1
	LDI	@CAMVIEW,R0
	BNZ	SPLAT_DONE		;NOT in First person

	FLOAT	@NFRAMES,R0		;Calculate the rate that the camera is moving
	MPYF	*+AR5(CARSPEED),R0
	MPYF	-0.8,R0			;NORMAL SPEED WOULD BE -1.5
	CMPF	-120,R0			;Minimum velocity
	LDFGT	-120,R0
	NEGF	R0,R1
	MPYF	R6,R1			;Move down 1/10th the rate as coming at you
	ADDF	*+AR4(OPOSY),R1
	STF	R1,*+AR4(OPOSY)

	ADDF	*+AR4(OPOSZ),R0
	FLOAT	368,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR4(OPOSZ)
	BGT	SPLAT_LP

	LDI	BUGBUZZ,AR2
	CALL	KILLSNDFX
	SONDFX	RK_SPLAT1
	LDI	*AR6++,R4
SPLAT_LP1
	STI	R4,*+AR4(OROMDATA)
	SLEEP	2
	LDI	@CAMVIEW,R0
	BNZ	SPLAT_DONE		;NOT in First person

	LDI	*AR6++,R4
	BP	SPLAT_LP1

	LDF	*+AR4(OPOSX),R2
	LDF	*+AR4(OPOSY),R3
	CALL	ARCTANF
	LDF	R0,R2
	CALL	_COSI
	STF	R0,*+AR4(OVELX)
	CALL	_SINE
	STF	R0,*+AR4(OVELY)
SPLAT_LP2
	SLEEP	1
	LDI	@CAMVIEW,R0
	BNZ	SPLAT_DONE		;NOT in First person

	FLOAT	@NFRAMES,R2

	LDF	*+AR4(OVELX),R0
	MPYF	0.2,R0
	ADDF	*+AR4(OVELX),R0
	STF	R0,*+AR4(OVELX)
	MPYF	R2,R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OVELY),R1
	MPYF	0.1,R1
	ADDF	*+AR4(OVELY),R1
	STF	R1,*+AR4(OVELY)
	MPYF	R2,R1
	ADDF	*+AR4(OPOSY),R1
	STF	R1,*+AR4(OPOSY)

	FLOAT	300,R2
	ABSF	R0
	CMPF	R2,R0
	BGT	SPLAT_DONE

	CMPF	R2,R1
	BLE	SPLAT_LP2

SPLAT_DONE
	LDI	AR4,AR2
	CALL	OBJ_DELETE
SPLAT_DIE
	LDI	BUGBUZZ,AR2		;Make sure that it dies (it loops)
	CALL	KILLSNDFX
	DIE
	
DELETE_SPLAT:
DBSLP
	LDI	PLYR_C|PLYR_SPLAT_S,AR2
	CALL	OBJ_FIND_FIRST_PRIORITY
	BNC	DBSX
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	BR	DBSLP
DBSX
	RETS


*---------------------------------------------------------------------------
* Updates AR2 to point to the road segment that the camera is on
* NOTE: uses Stealth mode
* INPUT	AR2 = segment on
*	AR4 = object moving
*	R2  = Direction moving	INT (+/-1)
* OUTPUT AR2 = segment on (updated)
*	R2 = # of segments moved
NEXT_ROAD:
	LDI	R2,R4
	MPYI	4,R4
	LDI	0,R3
NEXT_ROADLP
	FLOAT	*+AR2(X),R0
	SUBF	*+AR4(OPOSX),R0
	MPYF	R0,R0
	FLOAT	*+AR2(Z),R1
	SUBF	*+AR4(OPOSZ),R1
	MPYF	R1,R1
	ADDF	R1,R0

	LDI	AR2,AR0
	ADDI	R4,AR0
	FLOAT	*+AR0(X),R1
	SUBF	*+AR4(OPOSX),R1
	MPYF	R1,R1
	FLOAT	*+AR0(Z),R2
	SUBF	*+AR4(OPOSZ),R2
	MPYF	R2,R2
	ADDF	R2,R1

	CMPF	R1,R0
	BLE	NEXTRX			;didn't move
	ADDI	R4,AR2
	CMPI	@LEG_MAPI,AR2
	LDILT	@LEG_MAPI,AR2
	BLT	NEXTRX			;don't fly off the back of the map
	ADDI	1,R3			;R3 is the number of road segments moved
	BR	NEXT_ROADLP		;See if the road segment beyond is even closer
NEXTRX
	LDI	R3,R2
	RETS

*---------------------------------------------------------------------------
*INPUT	AR2 = POINTER to LEG_MAP where road is
*	R2  = Direction moving	INT (+/-1)
*
*OUTPUT	R2 = DIRECTION of road 
GET_ROAD_RADY:
	MPYI	4*2,R2
	LDI	AR2,AR1
	ADDI	R2,AR1

	LDI	*+AR1(Z),R3
	SUBI	*+AR2(Z),R3
	FLOAT	R3
	LDI	*+AR1(X),R2
	SUBI	*+AR2(X),R2
	FLOAT	R2
	CALL	ARCTANF
	LDF	R0,R2
	CALL	NORMITS
	SUBF	HALFPI,R2
	CALL	NORMITS
	RETS

*---------------------------------------------------------------------------
*
*GET POINTER TO MAP_LEG, ID IN R2
*INPUTS  R2=OUSR1
*OUPTUTS AR2=POINTER TO place in LEG_MAP
FIND_MAP:
	LDI	@LEG_MAPI,AR2		;FIND THE POSITION IN THE MAP
	ADDI	3,AR2				;OFFSET TO ID
FIND_LP
	LDI	*AR2++(4),R0
	CMPI	R2,R0
	BLT	FIND_LP
FINDX
	SUBI	7,AR2
	RETS
*---------------------------------------------------------------------------

	.END
