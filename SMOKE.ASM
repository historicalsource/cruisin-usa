	.FILE	"SMOKE.ASM"
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
	.include	SYSID.EQU
	.include	SYS.EQU
	.include	GLOBALS.EQU
	.include	PALL.EQU
	.include	OBJECTS.EQU


	.bss	TIRE_SMOKE_COUNT,1
	.data
SMOKEANII	.word	SMOKEANI
SMOKE2ANII	.word	SMOKE2ANI

	.SECT	"THEDATA"
SMOKEANI
	.word	bnout2,bnout4,bnout6,bnout8,bnout10,bnout12,bnout14,bnout16,-1
SMOKE2ANI
	.word	bnout1,bnout2,bnout3,bnout4,bnout5,bnout6,bnout7,bnout8,bnout9,bnout10
	.word	bnout11,bnout12,bnout14,bnout15,bnout16,-1

	.text
*----------------------------------------------------------------------------
* SMOKE	PROC
*INPUT	AR4 = CAROBJ
*	AR5 = CARBLK
*Creates and maintains several puffs of smoke
NUM_SMOKES	.set	PDATA
SMOKE_PAL	.set	PDATA+1
SMOKE_OBJS	.set	PDATA+2

SMOKE_PROC:
	LDI	@TIRE_SMOKE_COUNT,R0
	CMPI	1,R0
	BGE	SMOKE_DIE
	LDF	0,R7

	LDL	bnout1_smoke,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR7(SMOKE_PAL)

	LDI	0,R0
	STI	R0,*+AR7(NUM_SMOKES)

	LDI	1,R0
	STI	R0,@TIRE_SMOKE_COUNT
	BR	SMOKELP_ENTRY
SMOKE_PUFFLP
	LDI	0,R6
	LDI	0,R5
	LDI	SMOKE_OBJS,IR0
SMPUFFLP1
	LDI	*+AR7(IR0),AR0
	CMPI	0,AR0
	BEQ	SMPUFF1
	LDI	*+AR0(OUSR1),AR1
	LDI	*AR1++,R0
	BN	SMOKE_DONE
	STI	R0,*+AR0(OROMDATA)
	STI	AR1,*+AR0(OUSR1)


	LDI	@MATRIXAI,AR2
	LDF	*+AR5(CARVROT),R2
	CALL	FIND_YMATRIX

	CALL	CLR_VECTORA
	FLOAT	@NFRAMES,R0
	MPYF	*+AR5(CARSPEED),R0
	MPYF	1.51,R0
	SUBF	50,R0		;Constant speed less than the player is moving
	STF	R0,*+AR2(Z)

	LDI	@MATRIXAI,R2
	LDI	AR2,R3
	CALL	MATRIX_MUL

	LDI	@VECTORAI,AR1
	LDF	*+AR1(X),R0
	ADDF	*+AR0(OPOSX),R0
	STF	R0,*+AR0(OPOSX)
	LDF	*+AR1(Z),R0
	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	PUSH	AR4
	PUSH	IR0
	PUSH	R5
	LDI	AR0,AR4
	ADDI	OPOSX,AR4
	CALL	CAMSCAN
	POP	R5
	POP	IR0
	POP	AR4
	LDI	*+AR7(IR0),AR0
	ADDF	*+AR0(OPOSY),R0
	STF	R0,*+AR0(OPOSY)

	ADDI	1,R6
SMPUFF1
	ADDI	1,IR0
	ADDI	1,R5
	CMPI	*+AR7(NUM_SMOKES),R5
	BNE	SMPUFFLP1
SMOKE_CONT
	CMPI	0,R6
	BEQ	SMOKEX
SMOKELP_ENTRY
	LDF	0,R5

	LDI	*+AR5(CAR_SPIN),R0	;SPINNING?
	BNE	SMOKEN

	CMPF	0,R7
	BNE	KLUDGE_MO
	LDF	2,R7			;wait N more frames
SMOKEN
	CALL	CREATE_SMOKE_OBJ
KLUDGE_MO
	SUBF	1.0,R7
	SLEEP	1
	BR	SMOKE_PUFFLP
SMOKE_DONE
	LDI	AR0,AR2
	PUSH	IR0
	CALL	OBJ_DELETE
	POP	IR0
	LDI	0,R0
	STI	R0,*+AR7(IR0)		;make null on list
	BR	SMPUFFLP1
SMOKEX
	LDI	0,R0
	STI	R0,@TIRE_SMOKE_COUNT
SMOKE_DIE
	DIE


*----------------------------------------------------------------------------
* CREATE_SMOKE_OBJ
*INPUT	AR4 = CAROBJ
*	AR5 = CARBLK
*	R5 = ZOFFSET
*OUTPUT	SETC if no obj made; CLRC if obj made
*Creates a puff of smoke

CREATE_SMOKE_OBJ:
	LDI	*+AR7(NUM_SMOKES),R0
	CMPI	1,R0
	BLT	DO_SMOKE

	LDF	*+AR5(CARBRAKE),R0 
	CMPF	0.4,R0
	BLT	CHECK_SKID

	LDF	*+AR5(CARSPEED),R0 
	CMPF	20,R0
	BGT	OK_SMOKE
CHECK_SKID
	LDF	*+AR5(CARSKID),R0
	CMPF	0.25,R0
	BLT	NO_SMOKE			;NO SKID ACTIVE
OK_SMOKE
	LDI	*+AR7(NUM_SMOKES),R0
	CMPI	20,R0
	BGE	NO_SMOKE
DO_SMOKE

	LDI	AR4,AR2
	CALL	GETCARBODY
	LDI	AR0,AR2
	LDI	AR4,R2
	ADDI	OMATRIX,R2
	LDI	@MATRIXAI,R3
	CALL	CONCATMATV

	LDI	@SMOKEANII,AR1
	LDF	*+AR5(CARSKID),R0
	CMPF	0.5,R0
	LDIGT	@SMOKE2ANII,AR1
	LDI	*+AR5(CAR_SPIN),R0	;SPINNING?
	LDINE	@SMOKE2ANII,AR1

	LDI	*AR1,AR2
	CALL	OBJ_GETE
	BC	CSOX

	LDI	AR4,AR2
	CALL	GET_REAR
	PUSH	AR2
	LDI	*+AR5(RR_PCOL),AR3
	LDI	*+AR3(OID),R4
	CALL	INIT_SMOKE

	LDI	*AR1,AR2
	CALL	OBJ_GETE
	POP	AR2
	BC	CSOX
	CALL	GET_OTHER_REAR
	LDI	*+AR5(LR_PCOL),AR3
	LDI	*+AR3(OID),R4
	CALL	INIT_SMOKE
CSOX
	RETS
NO_SMOKE
	SETC
	RETS

*----------------------------------------------------------------------------
*FIND THE WHEEL IN THE DYNALIST OF THE CAR POINTED TO BY AR2
*INPUT	AR2 = CARS OBJECT
*OUTPUT AR0 = MATRIX OF THE BODY
* SCRAMBLES R0,R1

GET_OTHER_REAR:
	LDI	*AR2,R0
	BR	FBLOOP
GET_REAR:
	LDI	*+AR2(ODYNALIST),R0
	SLOCKON	Z,"UTIL\CARPROC   dynamic objects not found"
FBLOOP
	LDI	R0,AR2
	LDI	*+AR2(DYNAFLAG),R1
	CMPI	1,R1
	BZ	FOUND_REAR		;1 = rear tire
	LDI	*AR2,R0
	BR	FBLOOP
FOUND_REAR
	RETS

*----------------------------------------------------------------------------
*INPUT	AR0 = obj to init
*	AR1 = ANI to init with
*	AR2 = wheel obj
*	MATRIXAI - MATRIX of car
*	R4 = OID of object over
*	R5 = ZOFFSET

INIT_SMOKE:
	PUSH	AR1
	LDI	*+AR7(NUM_SMOKES),R0
	ADDI	SMOKE_OBJS,R0
	LDI	R0,IR0
	STI	AR0,*+AR7(IR0)
;	LDI	@SMOKEANII,AR1
	STI	AR1,*+AR0(OUSR1)	;pointer to animation table

	CMPI	300h,R4
	BNE	INSM1
	LDI	*+AR7(SMOKE_PAL),R0
	STI	R0,*+AR0(OPAL)
INSM1
	LDI	*AR1,R0
	STI	R0,*+AR0(OROMDATA)


	LDI	PLYR_C|PLYR_SMOKE_S,R0
	STI	R0,*+AR0(OID)

	LDF	40,R0
	CALL	SFRAND
	ADDF	*+AR2(DYNACENTERX),R0
	STF	R0,*+AR0(OPOSX)

	FLOAT	130,R0
	ADDF	*+AR2(DYNACENTERY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	*+AR2(DYNACENTERZ),R0
	ADDF	R5,R0
	STF	R0,*+AR0(OPOSZ)

	LDI	@MATRIXAI,R2
	LDI	AR0,R3
	ADDI	OPOSX,R3
	LDI	R3,AR2
	CALL	MATRIX_MUL

	LDF	*+AR0(OPOSX),R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR0(OPOSX)

	LDF	*+AR0(OPOSY),R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	*+AR0(OPOSZ),R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	ORM	O_POSTER|O_NOCOLL,*+AR0(OFLAGS)
	LDI	AR0,AR2
	CALL	OBJ_INSERT

	LDI	*+AR7(NUM_SMOKES),R0
	ADDI	1,R0			;NOTE this instruction clears the CARRY
	STI	R0,*+AR7(NUM_SMOKES)

	POP	AR1
	RETS

*----------------------------------------------------------------------------
*
*
*
SORT_SMOKE:
	LDI	PLYR_C,AR2
	CALL	OBJ_FIND_FIRST
	BNC	SORT_SMOKEX
	LDI	AR0,AR5
	LDI	AR5,AR6			;Stop when AR6 is reached
	LDI	@OACTIVE,AR4
	LDI	AR4,AR2
SSLOOP
	CMPI	AR4,AR6
	BEQ	SORT_SMOKEX		;Reached the object we linked behind
	CMPI	0,AR4
	BEQ	SORT_SMOKEX
	LDI	*+AR4(OID),R0
	CMPI	PLYR_C|PLYR_SMOKE_S,R0
	BNE	SSLOOPEND
	CMPI	@OACTIVE,AR4		;First item in list?
	BNE	UNLINK
	LDI	*AR4,R0
	.if	DEBUG
	BEQ	$		;The smoke should never be the only item displayed
	.endif
	STI	R0,@OACTIVE
	BR	LINK
UNLINK
	LDI	*AR4,R0
	STI	R0,*AR2
LINK
	LDI	*AR5,R1		;get object after AR5
	STI	AR4,*AR5	;Link this object to AR5
	STI	R1,*AR4		;Link the next object to AR4
	LDI	AR4,AR5
	LDI	R0,AR4
	BR	SSLOOP
SSLOOPEND
	LDI	AR4,AR2		;AR2 = last object for unlinking
	LDI	*AR4,AR4
	BR	SSLOOP
SORT_SMOKEX
	RETS
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
	.data
SPARKANII	.word	SPARKANI

	.SECT	"THEDATA"
SPARKANI
;	.word	sparc10,sparc10,sparc11,sparc11,sparc12,sparc12,-1
	.word	x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,-1
;	.word	x2,x4,x6,x8,x10,-1

	.text

*----------------------------------------------------------------------------
* INIT_SPARK
*INPUT	AR4 = object of parent
*Creates and maintains several spark animations
COLL_X		.set	PDATA
COLL_Y		.set	PDATA+1
COLL_Z		.set	PDATA+2
FRAME_ON	.set	PDATA+3
CAR_OBJ		.set	PDATA+4
CAR_BLOCK	.set	PDATA+5
NUM_SPARKS	.set	PDATA+6
SPARK_OBJS	.set	PDATA+7

INIT_SPARK:
	CALL	PUSHALL
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	INIT_SPARKX

	CALL	TOO_MANY_SPARKS
	BC	INIT_SPARKX

	LDI	@PLYPROC,AR7
	CREATEC	SPARK_PROC,UTIL_C|SPARK_T
	BC	INIT_SPARKX
	LDI	AR0,AR7
	STI	AR4,*+AR7(CAR_OBJ)
	LDI	*+AR4(OCARBLK),AR5
	STI	AR5,*+AR7(CAR_BLOCK)

	LDI	0,R5
IS_LOOP
	LDI	@SPARKANII,AR0
	LDI	*AR0,AR2
	CALL	OBJ_GETE
	BC	IS_LOOPX

	LDI	*+AR0(OFLAGS),R0
	OR	O_NOCOLL|O_POSTER,R0
	STI	R0,*+AR0(OFLAGS)

	LDI	AR0,AR4
	CALL	ADD_RDDEBRIS

	LDI	RDDEBRIS_C|TSC_IGNORE|TSC_SPARK_S,R0
	STI	R0,*+AR4(OID)

	LDI	R5,IR0
	ADDI	SPARK_OBJS,IR0
	STI	AR4,*+AR7(IR0)

	LDI	*+AR7(CAR_OBJ),AR2	;Use the body of the cars matrix
	CALL	GETCARBODY		;get the over rotation of the car body
	LDI	AR0,AR2
	LDI	*+AR7(CAR_OBJ),R2	;MATRIX = OVERROT+ROT of cars body
	ADDI	OMATRIX,R2
	LDI	AR4,R3
	ADDI	OMATRIX,R3
	CALL	CONCATMATV

	LDF	*+AR5(CARXPLUS),R0
	SUBF	*+AR5(CARXMINUS),R0
	CALL	FRAND
	ADDF	*+AR5(CARXMINUS),R0
	LDF	R0,R1

	LDI	*+AR7(CAR_OBJ),AR0
	LDF	*+AR0(OPOSX),R0		;Set the start point of the spark
	ADDF	R1,R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR0(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	FLOAT	180,R0
	STF	R0,*+AR4(OVELY)		;bottom of car
	LDF	*+AR5(CARZMINUS),R0	;BACK
	STF	R0,*+AR4(OVELZ)
	
	LDI	AR4,AR2
	LDF	1,R1			;absolute move(note frame rate dependant)
	CALL	OBJ_MOVE		;Offset the starting point

	LDI	@SPARKANII,R0
	STI	R0,*+AR4(OVELZ)
	LDF	0,R0
	STF	R0,*+AR4(OVELY)

	LDI	AR4,AR2
	CALL	OBJ_INSERT

	ADDI	1,R5
	CMPI	6,R5
	BLT	IS_LOOP
IS_LOOPX
	CMPI	0,R5
	BEQ	INIT_SPARK_KILL

	STI	R5,*+AR7(NUM_SPARKS)

INIT_SPARKX
	CALL	POPALL
	RETS

*----------------------------------------------------------------------------
*Called from within SPARK_PROC. Will make a new spark based on...
*INPUT	AR7 = PROCESS BLOCK OF SPARK_PROC
*	R7  = FL, NUMBER OF FRAMES SINCE LAST SPARK

REPLICATE_SPARK:
	LDI	*+AR7(NUM_SPARKS),R0
	CMPI	4,R0
	BGE	REPSPARKX
	LDI	AR7,AR0
	ADDI	SPARK_OBJS,AR0
	LDI	0,R0
FIND_LAST_SPARKLP
	LDI	*AR0++,R1		;This loop will leave AR4 = to last NONZERO SPARK
	LDINE	R1,AR4
	ADDI	1,R0
	CMPI	*+AR7(NUM_SPARKS),R0
	BLT	FIND_LAST_SPARKLP

	LDI	@SPARKANII,AR2
	LDI	*AR2,AR2
	CALL	OBJ_GETE
	BC	REPSPARKX

	LDI	*+AR0(OFLAGS),R0
	OR	O_NOCOLL|O_POSTER,R0
	STI	R0,*+AR0(OFLAGS)

	LDI	@MATRIXAI,AR2
	LDF	*+AR5(CARVROT),R2
	CALL	FIND_YMATRIX

	LDF	40,R0
	CALL	SFRAND
	STF	R0,*+AR0(OPOSX)
	LDF	90,R0
	CALL	SFRAND
	STF	R0,*+AR0(OPOSY)

	FLOAT	@NFRAMES,R0
	MPYF	50,R0			;Constant speed less than the player is moving
	MPYF	R7,R0			;NUMBER OF FRAMES SINCE LAST SPARK CREATED
	NEGF	R0			;OFFSET FROM LAST SPARK
	STF	R0,*+AR0(OPOSZ)

	LDI	AR0,AR2
	ADDI	OPOSX,AR2
	LDI	AR2,R3
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

	LDF	*+AR4(OPOSX),R0
	ADDF	*+AR0(OPOSX),R0
	STF	R0,*+AR0(OPOSX)

	LDF	*+AR4(OPOSY),R0
	ADDF	*+AR0(OPOSY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	*+AR4(OPOSZ),R0
	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	LDI	*+AR7(NUM_SPARKS),AR2
	ADDI	SPARK_OBJS,AR2
	ADDI	AR7,AR2
	STI	AR0,*AR2

	LDF	*+AR4(OVELY),R0
	STF	R0,*+AR0(OVELY)

	LDI	*+AR7(NUM_SPARKS),R0
	ADDI	1,R0
	STI	R0,*+AR7(NUM_SPARKS)

	LDI	AR0,AR4
	CALL	ADD_RDDEBRIS

	LDI	RDDEBRIS_C|TSC_IGNORE|TSC_SPARK_S,R0
	STI	R0,*+AR4(OID)

	LDI	@SPARKANII,R0
	STI	R0,*+AR4(OVELZ)

	LDI	AR4,AR2
	CALL	OBJ_INSERT

REPSPARKX
	RETS

*----------------------------------------------------------------------------
* SPARK_PROC	PROC

*INPUT	PDATA = SETUP see equates at begining of file
*Maintains several spark animations
SPARK_PROC:
	LDF	0,R7
	LDI	*+AR7(CAR_BLOCK),AR5
SSANI_LOOP

	LDI	0,R5		;SPARK ON
	LDI	0,R6		;NUMBER OF SPARKS STILL ACTIVE
SS1
	LDI	R5,IR0
	ADDI	SPARK_OBJS,IR0
	LDI	*+AR7(IR0),AR4
	CMPI	0,AR4
	BEQ	NEXT_SPARK		;SPARK is no longer with us

	LDI	*+AR4(OFLAGS),R0	;CHECK IF ALREADY OFF LIST
	TSTB	O_LIST_M,R0
	BZ	SPARK_ANIX			;YES, DELETE FROM LIST

	LDI	*+AR4(OID),R0
	CMPI	RDDEBRIS_C|TSC_IGNORE|TSC_SPARK_S,R0
	BNE	SPARK_ANIX		;not a spark???!!!

	LDI	*+AR4(OVELZ),AR6		;ANIMATION POINTER
	LDI	*++AR6,R0
	BN	SPARK_ANIX

	STI	R0,*+AR4(OROMDATA)
	STI	AR6,*+AR4(OVELZ)

	LDI	*+AR4(ODIST),R0
	CMPI	1000,R0
	BLE	SPARK_ANIX

	LDI	@MATRIXAI,AR2
	LDF	*+AR5(CARVROT),R2
	CALL	FIND_YMATRIX

	CALL	CLR_VECTORA
	FLOAT	@NFRAMES,R0
	MPYF	*+AR5(CARSPEED),R0
	MPYF	1.5,R0
	SUBF	100,R0		;Constant speed less than the player is moving
	STF	R0,*+AR2(Z)

	LDI	@MATRIXAI,R2
	LDI	AR2,R3
	CALL	MATRIX_MUL

	LDI	@VECTORAI,AR1
	LDF	*+AR1(X),R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR1(Z),R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	PUSH	AR4
	PUSH	IR0
	PUSH	R5
	ADDI	OPOSX,AR4
	CALL	CAMSCAN
	POP	R5
	POP	IR0
	POP	AR4
	BNC	SPARK_ANIX	;This spark is out of this world
	
	SUBF	*+AR4(OVELY),R0		;SPARKS OFFSET FROM THE GROUND
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)

	ADDI	1,R6
NEXT_SPARK
	ADDI	1,R5
	CMPI	*+AR7(NUM_SPARKS),R5
	BLT	SS1
	CMPI	0,R6
	BEQ	SPARK_DIE
	SLEEP	1

	ADDF	1,R7
	CMPF	2,R7			;WAIT NFRAMES
	BNE	KLUDGE_MOFO
	CALL	REPLICATE_SPARK		;Will replicate the latest spark still active
	LDF	0,R7
KLUDGE_MOFO
	BR	SSANI_LOOP

SPARK_DIE
	DIE

SPARK_ANIX
	LDI	R5,IR0
	ADDI	SPARK_OBJS,IR0
	LDI	*+AR7(IR0),AR2
	LDI	0,R0
	STI	R0,*+AR7(IR0)		;COLOR THIS SPARK GONE

	LDI	*+AR2(OFLAGS),R0	;CHECK IF ALREADY OFF LIST
	TSTB	O_LIST_M,R0
	BZ	NO_OBJ

	LDI	*+AR2(OID),R0
	CMPI	RDDEBRIS_C|TSC_IGNORE|TSC_SPARK_S,R0
	BNE	NO_OBJ			;not a spark???!!!

	CALL	OBJ_DELETE
NO_OBJ
	BR	NEXT_SPARK

*----------------------------------------------------------------------------
* INIT_COLLA_OBJS
*INPUT	AR0 points to proc memory
*Creates several spark animations
INIT_COLLA_OBJS:
	LDI	0,R5
ICO_LOOP
	LDI	@SPARKANII,AR0
	LDI	*AR0,AR2
	CALL	OBJ_GETE
	BC	ICO_LOOPX		;out of objects
	LDI	AR0,AR4

	LDI	*+AR4(OFLAGS),R0
	OR	O_NOCOLL|O_POSTER,R0
	STI	R0,*+AR4(OFLAGS)

	CALL	ADD_RDDEBRIS

	LDI	RDDEBRIS_C|TSC_IGNORE|TSC_SPARK_S,R0
	STI	R0,*+AR4(OID)

	LDI	R5,IR0
	ADDI	SPARK_OBJS,IR0
	STI	AR4,*+AR7(IR0)

	FLOAT	60,R0			;calculate the random offset that this obj will have
	CALL	SFRAND
	LDF	R0,R1

	FLOAT	-60,R0
	CALL	FRAND
	ADDF	20,R0
	LDF	R0,R2

	FLOAT	60,R0
	CALL	SFRAND
	LDF	R0,R3

	LDI	*+AR7(CAR_OBJ),AR0
	LDF	*+AR7(COLL_X),R0		;Set the start point of the spark
	ADDF	R1,R0
	ADDF	*+AR0(OPOSX),R0
	STF	R0,*+AR4(OPOSX)


	LDF	*+AR7(COLL_Y),R0
	ADDF	R2,R0
	ADDF	-30,R0
	NEGF	R0,R1
	ADDF	180,R1				;AVERAGE car hight from road
	STF	R1,*+AR4(OVELY)			;This will be used as the y offset
	ADDF	*+AR0(OPOSY),R0
	STF	R0,*+AR4(OPOSY)

	LDF	*+AR7(COLL_Z),R0
	ADDF	R3,R0
	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	LDI	@SPARKANII,R0
	STI	R0,*+AR4(OVELZ)


	LDI	AR4,AR2
	CALL	OBJ_INSERT

	ADDI	1,R5
	CMPI	2,R5
	BLT	ICO_LOOP
ICO_LOOPX
	CMPI	0,R5
	BEQ	INIT_SPARK_KILL
	STI	R5,*+AR7(NUM_SPARKS)
	RETS

INIT_SPARK_KILL
	LDI	AR7,AR2
	LDI	0,AR7		;Stupid thing thinks I'm commiting suicide!
	CALL	PRC_KILL
	RETS

*----------------------------------------------------------------------------
*INPUT	AR4	Car object
*	AR5	Car block
*OUTPUT	NONE
*
* Creates sparks at position where the wall was hit

WALL_SPARK:
	CALL	PUSHALL
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	WALL_SPARKX

	CMPI	@PLYCAR,AR4
	BNE	WALL_SPARKX		;Only work for the players car

	LDI	*+AR5(CARTRAK),R0
	BZ	WALL_SPARKX		;DUDE IS NOT ON THE ROAD

	CALL	TOO_MANY_SPARKS
	BC	WALL_SPARKX

	LDI	@PLYPROC,AR7
	CREATEC	SPARK_PROC,UTIL_C|SPARK_T
	BC	WALL_SPARKX

	LDI	AR0,AR7
	STI	AR4,*+AR7(CAR_OBJ)
	STI	AR5,*+AR7(CAR_BLOCK)

	LDF	*+AR5(CARYROT),R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX

;find the angle of the car reletive to the track it is on
	LDI	*+AR5(CARTRAK),R0
	LDI	R0,AR2
	CALL	GETRDIR
	LDF	R0,R2
;	LDF	*+AR5(CARVROT),R2
	CALL	NORMITS
	LDF	R2,R0
	LDF	*+AR5(CARYROT),R2
	CALL	NORMITS
	SUBF	R0,R2
	CALL	NORMITS
;find the side of the road the car is on
	LDF	*+AR5(CARDIST2CNTR),R0		;- = right side ;+ = left side
;determine which corner of the car hit the wall
	ABSF	R2,R1
	CMPF	HALFPI,R1
	BLT	FACINGFRONT
	NEGF	R0
	NEGF	R2
FACINGFRONT
	CMPF	0,R0			;which side is the wall?
	BGT	LEFT_SIDE
RIGHT_SIDE
	LDF	*+AR5(CARXPLUS),R1
	CMPF	0,R2
	LDFGT	*+AR5(CARZMINUS),R0	;BACK
	LDFLE	*+AR5(CARZPLUS),R0	;FRONT
	BR	WALLS1
LEFT_SIDE
	LDF	*+AR5(CARXMINUS),R1
	CMPF	0,R2
	LDFGT	*+AR5(CARZPLUS),R0	;FRONT
	LDFLE	*+AR5(CARZMINUS),R0	;BACK
WALLS1
;get the coords of that corner
;transform them based on the body of the car
	STF	R1,*+AR7(COLL_X)
	STF	R0,*+AR7(COLL_Z)
	LDF	-90,R0
	STF	R0,*+AR7(COLL_Y)
	LDI	AR7,AR2
	ADDI	COLL_X,AR2
	LDI	AR2,R3
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

;no go and make the spark objects
	CALL	INIT_COLLA_OBJS

WALL_SPARKX
	CALL	POPALL
	RETS

*----------------------------------------------------------------------------
*IMPACT_SPARK
*	INPUT *-AR3(1) = XYZ
*	INPUT	AR0,AR1 = two objects
*

IMPACT_SPARK:
	CALL	PUSHALL
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	IMPACT_SPARKX


	CMPI	@PLYCAR,AR0
	LDIEQ	AR0,AR4
	BEQ	IMPACTED_PLAYER
	CMPI	@PLYCAR,AR1
	LDIEQ	AR1,AR4
	BNE	IMPACT_SPARKX		;Only work for the players car

IMPACTED_PLAYER
	LDI	*+AR4(OCARBLK),AR5
	LDI	*+AR5(CARTRAK),R0
	BZ	IMPACT_SPARKX		;DUDE IS NOT ON THE ROAD

	CALL	TOO_MANY_SPARKS
	BC	IMPACT_SPARKX

	LDI	@PLYPROC,AR7
	CREATEC	SPARK_PROC,UTIL_C|SPARK_T
	BC	IMPACT_SPARKX

	LDI	AR0,AR7
	STI	AR4,*+AR7(CAR_OBJ)
	STI	AR5,*+AR7(CAR_BLOCK)

	LDF	*-AR3(1),R0
	SUBF	*+AR4(OPOSX),R0		;Make offset from the car
	STF	R0,*+AR7(COLL_X)
;	LDF	*AR3,R0
;	SUBF	60,R0
;	SUBF	*+AR4(OPOSY),R0		;Make offset from the car
	LDF	-80,R0
	STF	R0,*+AR7(COLL_Y)
	LDF	*+AR3(1),R0
	SUBF	*+AR4(OPOSZ),R0		;Make offset from the car
	STF	R0,*+AR0(COLL_Z)

	CALL	INIT_COLLA_OBJS

IMPACT_SPARKX
	CALL	POPALL
	RETS

*----------------------------------------------------------------------------
*ROAD_IMPACT_SPARK ASSUMSE IT IS CALLED FROM A ROUTINE THAT USED BOXSCAN IN COLLA
*INPUT	R2 = distance to road bottom from the point the is bellow it
*
*

ROAD_IMPACT_SPARK:
	RETS

;	CALL	PUSHALL
;
;	CREATE	SPARK_COLLA_PROC,UTIL_C|SPARK_T
;;find the lowest coordinate in the box
;	LDI	@BOXSCRAMI,AR1		;Box endpoint coords, set above by BOXSCAN
;	ADDI	24,AR1			;offset to world based
;	LDF	*+AR1(Y),R0
;	LDI	7,RC
;	RPTB	SCANYS
;	CMPF	*+AR1(Y),R0
;	LDILT	AR1,AR2
;	LDFLT	*+AR1(Y),R0
;SCANYS	NOP	*++AR1(3)
;
;;Now set the point of impact t0 this
;	SUBF	60,R2
;	LDF	*+AR2(X),R0
;	STF	R0,*+AR0(PDATA)
;	LDF	*+AR2(Y),R0
;	SUBF	R2,R0
;	STF	R0,*+AR0(PDATA+1)
;	LDF	*+AR2(Z),R0
;	STF	R0,*+AR0(PDATA+2)
;
;;now go make the objects
;	CALL	INIT_COLLA_OBJS
;ROAD_IMPACT_SPARKX
;	CALL	POPALL
;	RETS

*----------------------------------------------------------------------------
*INPUT	AR4 = CARS OBJECT
*	AR5 = CARBLK
SKID_SPARK:
	RETS

;	CALL	PUSHALL
;
;	LDI	*+AR4(ODIST),R0
;	CMPI	30000,R0
;	BGT	SKID_SPARKX
;
;	CREATE	SPARK_COLLA_PROC,UTIL_C|SPARK_T
;;Get the grounds elevation
;	LDI	*+AR5(CARTRAK),AR1	;OK if on enbankment, grass dosn't make sparks
;	LDF	*+AR1(OPOSY),R0
;	SUBF	30,R0
;	STF	R0,*+AR0(PDATA+1)
;;Now use the velocity of the car to offset the spark behind it
;	LDF	*+AR4(OVELX),R0
;	MPYF	-0.5,R0
;	ADDF	*+AR4(OPOSX),R0
;	STF	R0,*+AR0(PDATA)
;	LDF	*+AR4(OVELZ),R0
;	MPYF	-0.5,R0
;	ADDF	*+AR4(OPOSZ),R0
;	STF	R0,*+AR0(PDATA+2)
;;Go make the spark objects
;	CALL	INIT_COLLA_OBJS
;;done
;SKID_SPARKX
;	CALL	POPALL
;	RETS
*----------------------------------------------------------------------------
*RETURNS	R2= number of spark procs
*		C=1 if too many
*		C=0 if ok
TOO_MANY_SPARKS:
	LDI	0,R2
	LDI	@PACTIVEI,R0
	BZ	TMSXCC			;NULL LIST?
TMS_LP
	LDI	R0,AR0
	LDI	*+AR0(PID),R0
	TSTB	UTIL_C,R0
	BZ	TMSLPE
	AND	TYPE_M,R0
	CMPI	SPARK_T,R0
	BNE	TMSLPE
	ADDI	1,R2
TMSLPE
	LDI	*AR0,R0
	BNZ	TMS_LP
;	CMPI	5,R2
	CMPI	2,R2
	BLT	TMSXCC
	SETC
	RETS
TMSXCC
	CLRC
	RETS


OBJ_MOVE:
	LDI	AR2,AR1
	ADDI	OVELX,AR2
	LDI	AR1,R2
	ADDI	OMATRIX,R2
	LDI	@VECTORAI,R3
	CALL	MATRIX_MUL

	LDI	@VECTORAI,AR0
	LDF	*+AR0(X),R0
	MPYF	R1,R0
	ADDF	*+AR1(OPOSX),R0
	STF	R0,*+AR1(OPOSX)

	LDF	*+AR0(Y),R0
	MPYF	R1,R0
	ADDF	*+AR1(OPOSY),R0
	STF	R0,*+AR1(OPOSY)

	LDF	*+AR0(Z),R0
	MPYF	R1,R0
	ADDF	*+AR1(OPOSZ),R0
	STF	R0,*+AR1(OPOSZ)

	RETS



	.END
