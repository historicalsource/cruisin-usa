	.FILE	"DRONES.ASM"
*----------------------------------------------------------------------------
*COMMON DRONE ROUTINES
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
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
	.include	DELTA.EQU

	.globl	bnout1_smoke

*----------------------------------------------------------------------------
*DRONE TYPES
*	DELTA	intelligent, race vs plyr
*	RHO	oncoming traffic + RHO WEAVER
*	SIGMA	slow moving same direction as plyr (obstacles)
*		+ WEAVER SIGMA
*	COPCAR
*	CHOPPER	the helicopter
*



	.bss	DRONE_DISPATCH_P,1	;FLAG dispatching active???
	.bss	SUSPEND_MODE,1		;ALL DRONES *MUST* CHECK EVERY FRAME

	.bss	RACER_GRID_START,1	;Starting Index

*----------------------------------------------------------------------------
	.bss	DRONE_COUNT,1		;UD	NUMBER OF ACTIVE DRONES
	.bss	MIN_TRACK_TIME,1	;FL	MINIMUM TIME TO COMPLETE A SINGLE TRACK LEG
	.bss	PSYCHO_RHO,1		;UD	FLAG may they appear?

LANEPI	.word	LANEP
LANEP	.word	LANES,LANES4
LANES	.float	-576.0,-576.0,576.0,576.0	;TWO & 2/2 LANE
LANES4	.float	-1728.0,-576.0,576.0,1728.0	;TWO & 2/2 LANE



*----------------------------------------------------------------------------
	.bss	ONCSCREEN_CARS,1
POSITION_FINDER:
	LDI	@PLYCAR,AR4
	LDI	@PLYCBLK,AR5

	CALL	FIND_PLAYERS_POSITION
	SLEEP	14
	BU	POSITION_FINDER
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*FIND PLAYERS POSITION, AND # OF CARS CLOSE ONSCREEN
*
*PARAMETERS
*	AR4	PLAYERS OBJECT
*	AR5	PLAYERS CARBLOCK
*
* OUTPUT:SETS @POSITION, @ONCSCREEN_CARS
*
FIND_PLAYERS_POSITION:

;	CLRI	IR0	;TEMP FLAG FOR OTHER MACHINE

	LDI	1,R7		;POSITION #
	CLRI	R6		;CARS CLOSE TO SCREEN

	LDI	*+AR5(CARTRAK),AR6
	LDI	*+AR6(OUSR1),R1

	LDI	@CAR_LIST,AR0
	CMPI	0,AR0
	BZ	FPPX

FPPLP
	LDI	0,R5
	LDI	*+AR0(ODIST),R0
	CMPI	30000,R0
	BGT	NNEG
	CMPI	-5000,R0
	BLT	NNEG
	INC	R6
NNEG
	LDI	*+AR0(OID),R0
	CMPI	DRONE_C|VEHICLE_T|DRNE_RACER,R0
	BNE	NXTLP

	LDI	*+AR0(OCARBLK),AR3
	LDI	*+AR3(CAR_OM),R0  	;OTHER MACHINES CAR?
	BZ	FPP1			;NO...


	LDI	*+AR3(CARTRACK_ID),R0	;CHECK IF AHEAD OR BEHIND
	CMPI	R1,R0
	BNE	NXTLP1
;	BEQ	FURTHER
;	BLT	ISBLAMP
;
;	CMPI	@PLY2CAR,AR0
;	BNE	NXTLP1
;
;	LDI	0,R0
;	STI	R0,@THIS_MACHINE_AHEAD
;	BU	NXTLP1
;
;ISBLAMP	LDI	1,R0
;	STI	R0,@THIS_MACHINE_AHEAD
;	BU	NXTLP1
;
;FURTHER
	CMPI	@PLY2CAR,AR0
	LDIEQ	1,IR0

;	LDI	1,IR0
	STI	AR6,*+AR3(CARTRAK)  	;CALC CARDIST2CNTR DUDE
	LDI	AR6,AR2
	PUSH	AR4
	PUSH	AR5
	LDI	AR0,AR4
	LDI	AR3,AR5
	CALL	DRONE_RIDE_RIGHT
	STF	R0,*+AR5(CARDIST2CNTR)	;STORE DIST TO CENTER
	POP	AR5
	POP	AR4
	B	FPP2
FPP1


	LDI	*+AR0(OPLINK),AR2
	LDI	*+AR2(STEALTHMODE),R0  	;0=ONSCRN,-1=BEHIND ST, 1=AHEAD STEALTH
	BNE	NXTLP1

	LDI	*+AR0(OCARBLK),AR3
	LDI	*+AR3(CARTRAK),AR2
	LDI	*+AR2(OUSR1),R0

	CMPI	R1,R0
	BNE	NXTLP1
*
*ON SAME TRACK SEGMENT
*
FPP2

	LDI	*+AR2(OLINK4),AR2		;get the next road piece
	SUBF	*+AR0(OPOSX),*+AR2(OPOSX),R0
	MPYF	R0,R0
	LDF	*+AR0(OPOSZ),R3
	SUBF	*+AR2(OPOSZ),R3
	MPYF	R3,R3
	ADDF	R0,R3,R4
	LDF	*+AR3(CARDIST2CNTR),R0		;CORRECT FOR NOT CENTERED
	MPYF	R0,R0
	SUBF	R0,R4
	
	SUBF	*+AR4(OPOSX),*+AR2(OPOSX),R0
	MPYF	R0,R0
	LDF	*+AR4(OPOSZ),R3
	SUBF	*+AR2(OPOSZ),R3
	MPYF	R3,R3
	ADDF	R0,R3

	LDF	*+AR5(CARDIST2CNTR),R0		;CORRECT FOR NOT CENTERED
	MPYF	R0,R0
	SUBF	R0,R3

	;CHECK FOR LAMP
;	CMPI	0,IR0
;	BEQ	KKDKA
;	CLRI	IR0	;clear the flag
;	CMPF	R4,R3
;	LDIGT	0,R0
;	LDILE	1,R0
;	STI	R0,@THIS_MACHINE_AHEAD
KKDKA
	;END CHECK LAMP

	CMPF	R4,R3
NXTLP1	
	LDIGT	1,R5
	ADDI	R5,R7
NXTLP
	LDI	*+AR0(OLINK3),AR0
	CMPI	0,AR0
	BNE	FPPLP
FPPX
	STI	R7,@POSITION
	STI	R6,@ONCSCREEN_CARS
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*DRONE DISPATCHER
*
*
	.bss	DD_SLP,1	;MINIMUM SLEEP VALUE (def=40)
	.bss	DD_VAR,1	;SLEEP TIME VARIENCE (def=100)
	.bss	DD_MAX_DRONES,1	;MAX DRONES (def=MAX_DRONES)


*----------------------------------------------------------------------------
SIGMA_DISPATCHER:
	LDI	@HEAD2HEAD_ON,R0
	BZ	CONTIN
	DIE
CONTIN
	SLEEP	30*20

SIGDSP_LP
	LDI	@DD_VAR,AR2
	CALL	RANDU0
	ADDI	@DD_SLP,R0
	MPYI	2,R0
	LDI	R0,AR2
SG_DISP_S
	CALL	SLEEP

	LDI	1,AR2
	LDI	@DRONE_DISPATCH_P,R0
	BZ	SG_DISP_S


	LDI	@SUSPEND_MODE,R0
	CMPI	SM_HALT,R0
	BEQ	SIGDSP_LP	;->STRAIGHT TO SLEEP

	LDI	@DRONE_COUNT,R0
	SUBI	1,R0
	CMPI	@DD_MAX_DRONES,R0
	BGT	SIGDSP_LP

	LDI	@POSITION,R1
	CMPI	1,R1
	BLE	DOIT

	RANDN	100		;R0 <- rand %%
	CMPI	4,R1
	BGT	OV1

	CMPI	70,R0
	BLT	DOIT
	BGT	SIGDSP_LP
OV1	CMPI	7,R1
	BGT	OV2

	CMPI	60,R0
	BLT	DOIT
	BGT	SIGDSP_LP

OV2	CMPI	35,R0
	BGT	SIGDSP_LP

DOIT
;	CALL	COP_ACTIVE	;NO SIGMAS MIXED WITH COPS
;	BC	SIGDSP_LP

	CREATE	SIGMA_DRONE,DRONE_C|VEHICLE_T|DRNE_SIGMA
	BC	SIGDSP_LP
	LDI	AR0,AR5
NOTYET	SLEEP	1

	LDI	*+AR5(PAR4),AR4
	LDI	*+AR4(OID),R0
	CMPI	DRONE_C|VEHICLE_T|DRNE_SIGMA,R0
	BNE	SIGDSP_LP

	LDI	@DGROUP_AW,AR0
	LDI	AR0,AR2
	ADDI	1,AR2
	LDI	AR4,R2
	ADDI	OPOSX,R2
	CALL	GET_XZ_DISTANCE

;	FLOAT	15000,R1
	FLOAT	25000,R1
	CMPF	R1,R0
	BLT	NOTYET

	BU	SIGDSP_LP
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*ADD ID TO DRONE POINTER TABLE
*
*PARAMETERS
*	AR4	OBJECT
*	AR5	CAR BLOCK
*RETURNS
*	R0	ID
*

	.bss	DRONENUM,1

DRONE_PTR_ADD:

	LDI	0,R0
	STI	R0,*+AR5(CAR_OM)

	LDI	@DRONENUM,R0		;INCREMENT ID #
	ADDI	1,R0
	CMPI	127,R0
	LDIGT	10,R0			;RESET TO 10
	STI	R0,@DRONENUM


	LDI	@DIPRAM,R1
	TSTB	CMDP_MASTER,R1		;CHECK MASTER
	LDIZ	80H,R1			;YES, SET BIT 7
	LDINZ	0,R1
	OR	R1,R0

	
	STI	R0,*+AR5(CARNUM)
	RETS

DRONE_CLR:
	LDI	10,R0
	STI	R0,@DRONENUM
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
*
*MODIFICATION, THE PLYR MUST MOVE AT LEAST 9000 Voxels FROM THE
*INITIAL STARTING POSITION FOR US TO RELEASE ANY RHO DRONES, BECAUSE
*THEY DISAPPEAR WHEN THEY BEGIN TRACKING NO WORLD, WHICH AT THE STARTUP
*OF EACH LEG IS REALLY CUTTING IT
*
*
RHO_DISPATCHER:

	CALL	DRONE_CLR 	;CLEAR OUT DRONE POINTER TABLE

	SLEEP	30		;WAIT A SECOND
	LDI	@PLYCAR,AR4
	LDF	*+AR4(OPOSX),R6
	LDF	*+AR4(OPOSZ),R7	;GRAB THE 'INITIAL' LOCATION

	SLEEP	30*20		;WAIT LIKE 20 SECONDS ANYWAY...

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	BEGIN_RELEASING
	.if	DEBUG
	CMPI	@PLYCAR,AR4
	BNE	$
	.endif

RHOPSL
	LDF	R6,R0
	LDF	R7,R2
	SUBF	*+AR4(OPOSX),R0
	SUBF	*+AR4(OPOSZ),R2
	MPYF	R0,R0
	MPYF	R2,R2
	ADDF	R0,R2
	CALL	SQRT
	FLOAT	11000,R1
	CMPF	R1,R0
	BGT	BEGIN_RELEASING
	SLEEP	1
	BU	RHOPSL
BEGIN_RELEASING





RHO_DLP
	LDI	@POSITION,R0
	CMPI	2,R0
	BGT	NKLD
	LDI	50,AR2
	BU	TF_DISP_S
NKLD
	LDI	@DD_VAR,AR2
	CALL	RANDU0
	ADDI	@DD_SLP,R0
	LDI	R0,AR2
TF_DISP_S
	CALL	SLEEP

	LDI	1,AR2
	LDI	@DRONE_DISPATCH_P,R0
	BZ	TF_DISP_S

	LDI	@SUSPEND_MODE,R0
	CMPI	SM_HALT,R0
	BEQ	RHO_DLP

	LDI	@DRONE_COUNT,R0
	CMPI	@DD_MAX_DRONES,R0
	BGT	RHO_DLP

	LDI	@POSITION,R1
	CMPI	2,R1
	BLE	DOITR

	RANDN	100		;R0 <- rand %%
	CMPI	4,R1
	BGT	OV1R

	CMPI	75,R0
	BLT	DOITR
	BGT	RHO_DLP
OV1R	CMPI	7,R1
	BGT	OV2R

	CMPI	60,R0
	BLT	DOITR
	BGT	RHO_DLP

OV2R	CMPI	35,R0
	BGT	RHO_DLP

DOITR

	LDI	@ONCSCREEN_CARS,R0
	CMPI	8,R0
	BGT	RHO_DLP


	CALL	CK_LINK_DISP
	BZ	RHO_DLP			;NOT DISPATCHING, BEHIND IN LINK

	CREATE	RHO_DRONE,DRONE_C|VEHICLE_T|DRNE_RHO
	BU	RHO_DLP
*----------------------------------------------------------------------------
*
*CHECK IF AHEAD IN LINK FOR DISPATCH
*
	.GLOBL	COMPTRAK

CK_LINK_DISP

	LDI	@HEAD2HEAD_ON,R0
	BZ	GODISP
	
	CALL	COMPTRAK	;COMPARE TRACK RANKS OF PLAYERS	
	BLT	NOGO		;WERE BEHIND, NO DISPATCH
	BGT	GODISP

	NOT	@DIPRAM,R0	;CHECK MASTER
	TSTB	CMDP_MASTER,R0
	BNZ	GODISP		;ITS A MASTER...
NOGO
	LDI	0,R0
	RETS
GODISP
	LDI	1,R0
	RETS


*----------------------------------------------------------------------------
SET_DRONE_PAL:
	PUSH	R0
	PUSH	AR2
	LDI	*+AR7(DELTA_MODEL),AR2
	MPYI	VEHTAB_SIZE,AR2
	ADDI	@VEHICLE_TABLEI,AR2
	LDI	*+AR2(VEHTAB_PALTAB),AR2
	LDI	*AR2++,R0
	BZ	NO_EPALS

	PUSH	AR2
	INC	R0
	LDI	R0,AR2
	CALL	RANDU0
	POP	AR2
	CMPI	0,R0
	BEQ	NO_EPALS
	DEC	R0
	ADDI	R0,AR2
	LDI	*AR2,AR2
	CALL	PAL_FIND_RAW
	BNC	NO_EPALS
	STI	R0,*+AR4(OPAL)
	LDI	*+AR4(OFLAGS),R0
	OR	O_1PAL,R0
	STI	R0,*+AR4(OFLAGS)
NO_EPALS
	POP	AR2
	POP	R0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*PARAMETERS
*	AR2	OBJECT TO CHECK VALID LANES FOR...
*RETURNS
*	R0	0 - 2 lanes
*		1 - 4 lanes
*
GET_LANES:
	PUSH	AR0
	PUSH	AR1
	LDI	*+AR2(OUSR1),R0
	RS	8,R0

	LDI	@DGROUP_COUNT,AR0
	INC	AR0
	LDI	@DGROUPSI,AR1
GL_LP	CMPI	*+AR1(DGRP_IDX),R0
	BEQ	GL_FND
	ADDI	DGRP_SIZE,AR1
	DBU	AR0,GL_LP

	CLRI	R0
	POP	AR1
	POP	AR0
	RETS
GL_FND
	LDI	*+AR1(DGRP_FLAG),R0
	RS	7,R0
	AND	1,R0

	POP	AR1
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GET X/Z DISTANCE TO PLAYER
*
*PARAMETERS
*	AR4	OBJECT TO CHECK
*RETURNS
*	R0	FL DISTANCE TO PLAYER (IN VOXELS)
*
DIST_TO_PLYR:
	PUSH	AR3
	PUSHFL	R1
	PUSHFL	R2
	LDPI	@PLYCAR,AR3
	LDF	*+AR4(OPOSX),R2
	SUBF	*+AR3(OPOSX),R2
	LDF	*+AR4(OPOSZ),R1
	SUBF	*+AR3(OPOSZ),R1
	MPYF	R1,R1
	MPYF	R2,R2
	ADDF	R1,R2
	CALL	SQRT

	.if	DEBUG
	CMPI	0,DP
	BNE	$
	.endif
	POPFL	R2
	POPFL	R1
	POP	AR3
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GRAB THE AR2th PIECE ON THE CURRENT TRACK
*
*PARAMETERS
*	AR2	NUMBER OF PIECES IN TO START
*RETURNS
*	AR2	OBJECT POINTER TO STARTING ROAD PIECE
*
INIT_TRACKING_PIECE:
	PUSH	AR0
	PUSH	AR1

	LDI	@DYNALIST_BEGIN,AR0
LPP	LDI	*+AR0(OLINK4),AR1
	LDI	AR1,AR0
	DBU	AR2,LPP

	LDI	AR0,AR2
	.if	DEBUG
	CMPI	0,AR2
	SLOCKON	EQ,"DRONES\INIT_TRACKING_PIECE .."
	.endif
	STI	AR2,*+AR7(DELTA_TPIECE)
	POP	AR1
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*TRACK APPROPRIATE PIECE
*
*GETS THE POSITION THAT WE ARE CURRENTLY TRACKING ON,
*IF THE POSITION IS TOO CLOSE THEN WE ADVANCE TO THE NEXT POSITION (W/WRAP 
*AROUND)
*
*PARAMETERS
*	AR4			DRONE OBJECT
*	AR7			DRONE PROCESS
*	*+AR7(DELTA_TPIECE)	VALID ROAD OBJECT CURRENTLY TRACKING
*
*RETURNS
*	VECTORA		[X Y Z] POSITION
*	AR5		PTR TO TRACK ENTRY
*	R0		(FL) DISTANCE TO NEXT PIECE
*	MATRIXA		find Y Matrix (of Tracking Piece)
*
GET_TRACK_POS_RVS_XLANE:
	PUSHFL	R1
	PUSHFL	R2
	PUSH	AR2
	LDI	*+AR7(DELTA_TPIECE),AR2
	CALL	SUB_FUNCTION_RVS_XLANE		;GET LANE OFFSET (VECTOR A)
	BU	TRKP2


GET_TRACK_POS_RVS:
	PUSHFL	R1
	PUSHFL	R2
	PUSH	AR2
	LDI	*+AR7(DELTA_TPIECE),AR2
	CALL	SUB_FUNCTION_RVS
	BU	TRKP2


DELTA_GET_TRACK_POS:
	PUSHFL	R1
	PUSHFL	R2
	PUSH	AR2
	LDI	*+AR7(DELTA_TPIECE),AR2
	CALL	DELTA_SUB_FUNCTION		;GET LANE OFFSET (VECTOR A)
	BU	TRKP2

GET_TRACK_POS:
	PUSHFL	R1
	PUSHFL	R2
	PUSH	AR2
	LDI	*+AR7(DELTA_TPIECE),AR2

TRACK_PIECE
	CALL	SUB_FUNCTION		;GET LANE OFFSET (VECTOR A)

TRKP2
	.if	DEBUG
	LDI	*+AR2(OUSR1),R1
	SLOCKON	LT,"DRONES\GET_TRACK_POS  probably tracking a deleted object"
	.endif

	LDF	*+AR2(OPOSX),R2		;X
	SUBF	*+AR4(OPOSX),R2
	LDF	*+AR2(OPOSZ),R1		;Z
	SUBF	*+AR4(OPOSZ),R1

	MPYF	R2,R2
	MPYF	R1,R1
	ADDF	R1,R2
	CALL	SQRT
	;R0 now has distance to next check

DISTANCE_OK
	POP	AR2
	POPFL	R2
	POPFL	R1
	RETS
*----------------------------------------------------------------------------




;*----------------------------------------------------------------------------
;*
;*PARAMETERS
;*	AR7			DRONE PROCESS
;*	AR4			DRONE OBJECT
;*	*+AR7(DELTA_SPTR)	VALID STEALTH POINTER
;*
;*
;*
;*RETURNS
;*	VECTORA		[X Y Z] POSITION
;*	R0		(FL) DISTANCE TO NEXT PIECE
;*	MATRIXA		find Y Matrix (of Tracking Piece)
;*
;GET_STEALTH_POS:
;	PUSHFL	R1
;	PUSHFL	R2
;	PUSHFL	R3
;	PUSH	AR2
;	LDI	*+AR7(DELTA_SPTR),AR2
;
;	FLOAT	*+AR2(Y),R0
;	FLOAT	52,R1
;	SUBF	R1,R0
;	STF	R0,*+AR4(OPOSY)
;
;;	yrot  = cr + ROAD_ITEMS[i].rads.y;
;;	yrot *= 128;
;;	yroti = (int) yrot;
;;
;;	ROAD_MAP[MAP_LENGTH].id = (ROAD_MAP[MAP_LENGTH].id & 0x0fffff) |
;;				((yroti & 0x0fff) << 20);
;
;
;	;to get the proper theta we must compute the direction to the next 
;	;piece via arctan2
;	;
;	LDI	*+AR2(4+X),R2
;	LDI	*+AR2(4+Z),R3
;	SUBI	*+AR2(X),R2
;	SUBI	*+AR2(Z),R3
;	FLOAT	R2
;	FLOAT	R3
;	CALL	ARCTANF
;	SUBF	HALFPI,R0
;	LDF	R0,R2
;
;
;	LDI	@MATRIXAI,AR2
;	CALL	FIND_YMATRIX
;
;	LDI	*+AR7(DELTA_SPTR),AR2
;	FLOAT	*+AR2(X),R2
;	SUBF	*+AR4(OPOSX),R2
;	FLOAT	*+AR2(Z),R1
;	SUBF	*+AR4(OPOSZ),R1
;
;	MPYF	R2,R2
;	MPYF	R1,R1
;	ADDF	R1,R2
;	CALL	SQRT
;
;	POP	AR2
;	POPFL	R3
;	POPFL	R2
;	POPFL	R1
;	RETS
;*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GETS OFFSET OF LANE
*
*
*PARAMETERS
*	AR2	PIECE TO TRACK (ALLOCATED OBJECT)
*	AR4	DRONE OBJECT
*	AR7	DRONE PROCESS
*
*
*RETURNS
*	MATRIXA	ROTATED FOR THE LANE
*	VECTORA	LANE OFFSET
*	R2	RADIAN Y
*
*
*	if (obj -> OLINK4 == NULL)  {
*		dont know???
*	}
*	else  {
*		
*
*	}
*
SUB_FUNCTION_RVS:
	PUSH	AR0
	PUSHFL	R0
	PUSHFL	R3

	LDI	*+AR2(OBLINK4),R0
	SLOCKON	Z,"DRONES\SUB_FUNCTION_RVS  OBLINK4 to NULL"
	BU	SF_ENTER2


SUB_FUNCTION:
	PUSH	AR0
	PUSHFL	R0
	PUSHFL	R3

	LDI	*+AR2(OLINK4),R0
	SLOCKON	Z,"DRONES\SUB_FUNCTION  OLINK4 to NULL"
SF_ENTER2
	LDI	R0,AR0
	LDF	*+AR0(OPOSX),R2
	SUBF	*+AR2(OPOSX),R2
	LDF	*+AR0(OPOSZ),R3
	SUBF	*+AR2(OPOSZ),R3
	CALL	ARCTANF
	SUBF	HALFPI,R0
	LDF	R0,R2				;FIND THETA

	PUSHF	R2

	CALL	GET_LANES

	PUSH	AR2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX			;FIND Y MATRIX (FOR LANE OFFSETTING)

	LDI	*+AR7(DELTA_STATUS),AR0
	AND	DELTA_STATUS_LANE,AR0

;	LDPI	@LANEPI,AR1
	LDI	@LANEPI,AR1
	ADDI	R0,AR1		;4 or 2 lane map?
	LDI	*AR1,R0
	ADDI	R0,AR0		;which lane?
	LDF	*AR0,R0


DELTA_JOININ


	LDI	@VECTORAI,AR2
	STF	R0,*+AR2(X)
	CLRF	R0
	STF	R0,*+AR2(Y)
	STF	R0,*+AR2(Z)
	LDI	AR2,R3

	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL			;COMPUTE THE LANE OFFSET IN VECTORA

	POP	AR2
	POPF	R2

	POPFL	R3
	POPFL	R0
	POP	AR0
	RETS

SUB_FUNCTION_RVS_XLANE:
	PUSH	AR0
	PUSHFL	R0
	PUSHFL	R3

	LDI	*+AR2(OBLINK4),R0
	BU	SFENTER66


SUB_FUNCTION_XLANE:
DELTA_SUB_FUNCTION:
	PUSH	AR0
	PUSHFL	R0
	PUSHFL	R3

	LDI	*+AR2(OLINK4),R0
	SLOCKON	Z,"DRONES\DELTA_SUB_FUNCTION  OLINK4 to NULL"
SFENTER66
	LDI	R0,AR0
	LDF	*+AR0(OPOSX),R2
	SUBF	*+AR2(OPOSX),R2
	LDF	*+AR0(OPOSZ),R3
	SUBF	*+AR2(OPOSZ),R3
	CALL	ARCTANF
	SUBF	HALFPI,R0
	LDF	R0,R2				;FIND THETA

	PUSHF	R2
	PUSH	AR2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX			;FIND Y MATRIX (FOR LANE OFFSETTING)

	LDF	*+AR7(DELTA_XLANE),R0
	BU	DELTA_JOININ
*----------------------------------------------------------------------------



;*----------------------------------------------------------------------------
;*GIVEN A SECTION/ROAD ID FIND THE MAP ENTRY IN THE
;*ROAD MAP WHICH CONTAINS THE ID EQUAL TO, OR GREATER
;*THAN THE GIVEN ID.
;*[finds GE road ID ptr]
;*
;*PARAMETERS
;*	R2	CODED ID (from OUSR1)
;*	AR7	DRONE PROCESS
;*
;*RETURNS
;*	*+AR7(STEALTH_PTR)
;*
;FIND_MAPENTRY:
;	PUSH	AR0
;	PUSH	R0
;	LDI	@ROAD_MAPI,AR0
;FIND_LP
;	LDI	*+AR0(3),R0
;	LS	12,R0
;	RS	12,R0
;	CMPI	R2,R0
;	BGE	FINDX
;	ADDI	4,AR0
;	BU	FIND_LP
;FINDX
;	STI	AR0,*+AR7(DELTA_SPTR)
;	STI	R0,*+AR7(DELTA_LAST_OID)	;save road id
;
;	POP	R0
;	POP	AR0
;	RETS
;*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*DRONE UTILITY FUNCTIONS
*
INIT_DRONES:
	PUSH	R0
	CLRI	R0
	STI	R0,@CAR_LIST
	STI	R0,@DRONE_COUNT

	LDI	SM_GO,R0
	STI	R0,@SUSPEND_MODE

	LDI	40,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR
	LDI	MAX_DRONES,R0
	STI	R0,@DD_MAX_DRONES

	POP	R0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*ADD TO DRONE SUPP LIST
*
*PARAMETERS
*	AR4	OBJECT DRONE POINTER
*
ADD_DRONE:
	PUSH	R0
	LDI	@CAR_LIST,R0
	STI	R0,*+AR4(OLINK3)
	STI	AR4,@CAR_LIST
	INCM	@DRONE_COUNT
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*FREE_DRONE
*unlink DRONE from DRONE supplimentary list
*
*PARAMETERS
*	AR4	OBJECT DRONE POINTER
*
FREE_DRONE:
	PUSH	R0
	PUSH	AR1
	PUSH	AR3

	LDI	@CAR_LISTI,R0
	SUBI	OLINK3,R0		;(we are offset pointing)

FREELP	LDI	R0,AR1
	LDI	*+AR1(OLINK3),R0
	SLOCKON	Z,"DRONES\FREE_DRONE  end of list found"
	BZ	FREEDR_X

	CMPI	R0,AR4
	BNE	FREELP


	LDI	*+AR4(OLINK3),R0
	STI	R0,*+AR1(OLINK3)	;LINK AROUND
	DECM	@DRONE_COUNT
	.if	DEBUG
	CMPI	0,R0
	SLOCKON	LT,"DRONES\FREE_DRONE  DRONE_COUNT INVALID"
	.endif

FREEDR_X
	POP	AR3
	POP	AR1
	POP	R0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*
*
EXP_PUFF:
	LDL	40000,R0
	CMPI	*+AR4(ODIST),R0
	BLT	SUICIDE

	LDI	AR4,AR6
	CALL	OBJ_GET
	BC	SUICIDE
	LDI	AR0,AR4
	LDI	@EXP_ANII,AR5

	LDI	*AR5,AR0
	STI	AR0,*+AR4(OROMDATA)

	LDF	*+AR6(OPOSX),R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR6(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR6(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	ORM	O_POSTER,*+AR4(OFLAGS)
	LDI	AR4,AR2
	CALL	OBJ_INSERT

	LDF	6,R0
	CALL	SFRAND
	LDF	R0,R6

	LDF	6,R0
	CALL	SFRAND
	LDF	R0,R7


EXP_PUFFLP

	LDL	40000,R0
	CMPI	*+AR4(ODIST),R0
	BLT	EXP_DIE


	LDF	*+AR4(OPOSX),R0
	ADDF	R6,R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR4(OPOSZ),R0
	ADDF	R7,R0
	STF	R0,*+AR4(OPOSZ)

	LDI	*AR5++,AR0
	CMPI	-1,AR0
	BEQ	EXP_DIE
	STI	AR0,*+AR4(OROMDATA)

	LDF	*+AR4(OPOSY),R0
	SUBF	10,R0
	STF	R0,*+AR4(OPOSY)

	SLEEP	1
	BU	EXP_PUFFLP
EXP_DIE
	LDI	AR4,AR2
	CALL	OBJ_DELETE
	DIE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
EXP_ANII	.word	EXP_ANI
	romdata
EXP_ANI
;	.word	blast1,blast2,blast3,blast4,blast5
;	.word	blast6,blast7,blast8,blast9,blast10,-1

	.word	dexplo1,dexplo2,dexplo3,dexplo4,dexplo5
	.word	dexplo6,dexplo7,dexplo8,dexplo9,dexplo10,dexplo11,-1
	.text
*----------------------------------------------------------------------------



;*----------------------------------------------------------------------------
;*MK_CHUNK
;*
;*PARAMETERS
;*	AR4	HEAD OBJECT
;*	AR2	ROM DATA PTR
;*
;*RETURNS
;*	C	CANNOT GET OBJECT
;*	AR0	CHUNK
;*
;*
;	.bss	XZSPC,1
;	.bss	XZMIN,1
;	.bss	YSPC,1
;	.bss	YMIN,1
;MK_CHUNK:
;	PUSH	AR2
;	PUSH	R0
;	PUSH	R1
;	PUSH	R2
;	PUSHF	R0
;	PUSHF	R1
;	PUSHF	R2
;
;
;	CALL	OBJ_GET
;	BC	MK_CHUNKX
;
;	MOVMF	*+AR4(OPOSX),*+AR0(OPOSX)
;	MOVMF	*+AR4(OPOSY),*+AR0(OPOSY)
;	MOVMF	*+AR4(OPOSZ),*+AR0(OPOSZ)
;	STI	AR2,*+AR0(OROMDATA)
;
;	LDI	@XZSPC,AR2
;	CALL	SRAND
;	FLOAT	R0
;	FLOATP	@XZMIN,R1
;	SADDFR	R1,R0
;	STF	R0,*+AR0(OVELX)
;
;	LDI	@XZSPC,AR2
;	CALL	SRAND
;	FLOAT	R0
;	FLOAT	@XZMIN,R1
;	SADDFR	R1,R0
;	STF	R0,*+AR0(OVELZ)
;
;
;	LDI	@YSPC,AR2
;	CALL	RANDU0
;	ADDI	@YMIN,R0
;	FLOAT	R0
;	NEGF	R0
;	STF	R0,*+AR0(OVELY)
;	LDI	AR0,AR2
;	CALL	OBJ_INSERT
;
;
;	LDI	10,AR2
;	CALL	SRAND
;	FLOAT	R0
;	MPYF	0.01,R0
;	STF	R0,*+AR0(OUSR2)
;
;	LDI	10,AR2
;	CALL	SRAND
;	FLOAT	R0
;	MPYF	0.03,R0
;	STF	R0,*+AR0(OUSR3)
;
;	CLRC
;MK_CHUNKX
;	POPF	R2
;	POPF	R1
;	POPF	R0
;	POP	R2
;	POP	R1
;	POP	R0
;	POP	AR2
;	RETS
;*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*PRECOLLIDE_PLYR	CHECK TO SEE IF CAR WILL COLLIDE WITH PLAYER
*
*
*check distance to player
*if within that distance
*
*examine path, is player in immediate player
*
*
*PARAMETERS
*	AR4	OBJECT
*	AR5	CARBLOCK
*	AR7	DRONE PROCESS 
*
*RETURNS
*	CARRY SET ON COLLISION IMMINENT
*	CARRY CLR PATH MAINLY CLEAR
*
PRECOLLIDE_PLYR:

	CALL	DIST_TO_PLYR
	FLOAT	15000,R1
	CMPF	R1,R0
	BGT	NOT_IMMINENT


	;
	;project ahead 5 frames
	;
	LDI	@VECTORAI,AR3
	LDF	*+AR5(CARSPEED),R0
	MPYF	@NFRAMES,R0
	MPYF	5,R0
	STF	R0,*+AR3(Z)
	CLRF	R0
	STF	R0,*+AR3(X)
	STF	R0,*+AR3(Y)

	LDI	@MATRIXAI,AR2
	LDF	*+AR5(CARVROT),R2
	CALL	FIND_YMATRIX

	LDI	AR2,R2
	LDI	AR3,AR2
	LDI	AR3,R3
	CALL	MATRIX_MUL


	;generate the line equation
	;
	LDP	@_VECTORA
	NEGF	@_VECTORA+Z,R6		;A = Uy - Vy
	LDF	@_VECTORA+X,R7		;B = Vx - Ux
	SETDP

	LDF	*+AR4(OPOSX),R5
	MPYF	R6,R5
	LDF	*+AR4(OPOSZ),R3
	MPYF	R7,R3
	ADDF	R3,R5
	NEGF	R5			;C = -(A Ux + B Uy)




;	LDPI	@CAR_LISTI,AR1


	;now find the distance of a point to a line
	;

	MPYF	R6,R6,R2
	MPYF	R7,R7,R3
	ADDF	R3,R2
	CALL	SQRT
	LDF	R0,R1

	LDPI	@PLYCAR,AR2
	LDF	*+AR2(OPOSX),R2
	MPYF	R6,R2
	LDF	*+AR2(OPOSZ),R3
	MPYF	R7,R3
	ADDF	R3,R2

	ADDF	R5,R2
	LDF	R2,R0
	CALL	DIV_F
	ABSF	R0

	FLOAT	400,R1
	CMPF	R1,R0
	BGT	NOT_IMMINENT

IS_IMMINENT
	SETC
	RETS

NOT_IMMINENT
	CLRC
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PLYR_RIDE_RIGHT	is the player riding on the right side of the road?
*
*RETURNS
*	CARRY CLR	ON RIGHT SIDE OF ROAD
*	CARRY SET	NOT ON RIGHT SIDE OF ROAD
*	R0		DISTANCE TO ROAD CENTER
*
*Algorythm
*
*	generate line equation by the closest track piece and the next piece
*	check the sign of the distance to this line (plyrs position)
*	and return which side of the road
*
*ANY ERRORS WILL ASSUME PLYR IS ON RITE SIDE
*
*DRONE_RIDE_RIGHT
*
*
*PARAMETERS
*	AR4	DRONE OBJ
*	AR5	DRONE CAR BLOCK
*RETURNS
*	R0	(FL) DISTANCE TO CENTERLINE OF ROAD
*
DRONE_RIDE_RIGHT:
	PUSH	R1
	PUSHFL	R2
	PUSH	R3
	PUSH	AR0
	PUSH	AR2
	PUSH	AR4
	PUSH	AR5

	BU	RIDE_RIGHT_JOININ

PLYR_RIDE_RIGHT:
	PUSH	R1
	PUSHFL	R2
	PUSH	R3
	PUSH	AR0
	PUSH	AR2
	PUSH	AR4
	PUSH	AR5

	LDPI	@PLYCAR,AR4
	CMPI	0,AR4
	BEQ	PRR_ONRITE
	LDI	*+AR4(OCARBLK),AR5

RIDE_RIGHT_JOININ

	LDI	*+AR5(CARTRAK),AR2
	LDI	*+AR2(OLINK4),R0
	BZ	PRR_ONRITE

	LDI	R0,AR0
	LDF	*+AR2(OPOSZ),R0
	SUBF	*+AR0(OPOSZ),R0		;A = Uy - Vy
	LDF	*+AR0(OPOSX),R1
	SUBF	*+AR2(OPOSX),R1		;B = Vx - Ux

	NEGF	R0,R2
	NEGF	R1,R3
	MPYF	*+AR2(OPOSX),R2
	MPYF	*+AR2(OPOSZ),R3
	ADDF	R3,R2			;C = -(A Ux + B Uy)
;	NEGF	R2

	PUSHF	R0
	PUSHF	R2
	MPYF	R0,R0,R0
	MPYF	R1,R1,R2
	ADDF	R0,R2
	CALL	SQRT
	LDF	R0,R3
	POPF	R2
	POPF	R0

	MPYF	*+AR4(OPOSX),R0
	MPYF	*+AR4(OPOSZ),R1
	ADDF	R1,R0
	ADDF	R2,R0

	LDF	R3,R1
	CALL	DIV_F
	LDF	R0,R0			;dist = (A Ux + B Uy + C)/sqrt(A^2 + B^2)
	BLT	PRR_ONRITE


PRR_NONRITE
	CLRC
	BU	PRR_X
PRR_ONRITE
	SETC
PRR_X
	POP	AR5
	POP	AR4
	POP	AR2
	POP	AR0
	POP	R3
	POPFL	R2
	POP	R1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*SMOKE_PUFF
*
*PARAMETERS
*	AR4	OBJECT THAT IS SMOKING
*
	.bss	SMOKE_COUNT,1
SMOKE_PUFF:
	LDI	@SMOKE_COUNT,R0
	CMPI	5,R0
	BGE	SUICIDE
	INC	R0
	STI	R0,@SMOKE_COUNT


	LDL	40000,R0
	CMPI	*+AR4(ODIST),R0
	BLT	SUICIDE

	LDI	AR4,AR6
	CALL	OBJ_GET
	BC	SUICIDE

	LDI	AR0,AR4
	LDI	@SMOKE_ANII,AR5

	LDI	*AR5,AR0
	STI	AR0,*+AR4(OROMDATA)

	LDI	UTIL_C|SMOKE_T,R0
	STI	R0,*+AR4(OID)


	LDL	bnout1_smoke,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR4(OPAL)


	LDF	*+AR6(OPOSX),R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR6(OPOSY),R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR6(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	ORM	O_POSTER|O_1PAL,*+AR4(OFLAGS)
	LDI	AR4,AR2
	CALL	OBJ_INSERT

SMOKE_PUFFLP
	LDL	40000,R0
	CMPI	*+AR4(ODIST),R0
	BLT	SMOKE_DIE

	LDF	6,R0
	CALL	SFRAND
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)
	LDF	6,R0
	CALL	SFRAND
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	LDI	*AR5++,AR0
	CMPI	-1,AR0
	BEQ	SMOKE_DIE
	STI	AR0,*+AR4(OROMDATA)

	LDI	*AR5++,AR2
	LDF	*+AR4(OPOSY),R0
	SUBF	*AR5++,R0

	STF	R0,*+AR4(OPOSY)

	CALL	SLEEP
	BU	SMOKE_PUFFLP
SMOKE_DIE

	LDI	@SMOKE_COUNT,R0
	DEC	R0
	.if	DEBUG
	BLT	$
	.endif
	STI	R0,@SMOKE_COUNT

	LDI	AR4,AR2
	CALL	OBJ_DELETE
	DIE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SMOKE_ANII	.word	SMOKE_ANI
	romdata
SMOKE_ANI
	.word	bnout1,1
	.float	10
	.word	bnout2,2
	.float	12
	.word	bnout3,1
	.float	16
	.word	bnout4,1
	.float	20
	.word	bnout5,1
	.float	24
	.word	bnout6,1
	.float	30
	.word	bnout7,1
	.float	35
	.word	bnout8,1
	.float	40
	.word	bnout9,1
	.float	45
	.word	-1

	.text
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR5	PALM TREE OBJECT
*
	.bss	COCONUT_COUNT,1
DROP_COCONUTS:
	LDI	@COCONUT_COUNT,R0
	CMPI	5,R0
	BGE	SUICIDE
	INC	R0
	STI	R0,@COCONUT_COUNT

	CALL	OBJ_GET
	BC	SUICIDE

	LDI	AR0,AR4
	LDF	*+AR5(OPOSX),R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR5(OPOSY),R0
	FLOAT	1500,R1
	SUBF	R1,R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR5(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	LDL	coco1,R0
	STI	R0,*+AR4(OROMDATA)

	LDI	*+AR4(OFLAGS),R0
	OR	O_POSTER,R0
	STI	R0,*+AR4(OFLAGS)
	LDI	AR4,AR2
	CALL	OBJ_INSERT

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	NSND1
	SONDFX	COCONUTLOW
NSND1
	LDF	*+AR4(OPOSY),R0
	STF	R0,*+AR7(PDATA+1)	;save initial base Y
	CALL	OBJSCAN
	STF	R0,*+AR7(PDATA)

	RANDN	20
	MPYI	3,R0
	FLOAT	R0
	ADDF	20,R0
	STF	R0,*+AR4(OVELY)

	RANDN	20
	MPYI	3,R0
	FLOAT	R0
	SUBF	30,R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)

	RANDN	20
	MPYI	3,R0
	FLOAT	R0
	SUBF	30,R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)


	CLRI	R0
	STI	R0,*+AR7(PDATA+2)
	CLRF	R0
	STF	R0,*+AR4(OVELX)
	STF	R0,*+AR4(OVELZ)


DROPLP
	LDI	*+AR4(ODIST),R0
	BN	DROPCOCOKILL

	CMPI	20000,R0
	BGT	DROPCOCOKILL


	LDF	*+AR4(OVELY),R0
	ADDF	25,R0
	FLOAT	450,R1
	CMPF	R1,R0
	LDFGT	R1,R0
	STF	R0,*+AR4(OVELY)


	LDF	*+AR4(OPOSX),R0
	ADDF	*+AR4(OVELX),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OPOSZ),R0
	ADDF	*+AR4(OVELZ),R0
	STF	R0,*+AR4(OPOSZ)

	LDF	*+AR4(OPOSY),R0
	ADDF	*+AR4(OVELY),R0
	STF	R0,*+AR4(OPOSY)


	CMPF	*+AR5(OPOSY),R0
	BLT	FRSL

	LDI	*+AR7(PDATA+2),R0
	BNZ	NOTINITIAL

	RANDN	30
	MPYI	3,R0
	FLOAT	R0
	SUBF	45,R0
	STF	R0,*+AR4(OVELX)

	RANDN	30
	MPYI	3,R0
	FLOAT	R0
	SUBF	45,R0
	STF	R0,*+AR4(OVELZ)
	BU	LLKK

NOTINITIAL
	CMPI	3,R0
	BEQ	HOLDTOSLEEP

	LDF	*+AR4(OVELX),R0
	MPYF	0.5,R0
	STF	R0,*+AR4(OVELX)

	LDF	*+AR4(OVELZ),R0
	MPYF	0.5,R0
	STF	R0,*+AR4(OVELZ)
LLKK
	LDI	*+AR7(PDATA+2),R0
	INC	R0
	STI	R0,*+AR7(PDATA+2)


	LDF	*+AR4(OVELY),R0
	CMPF	3,R0
	BLE	HOLDTOSLEEP
	MPYF	-0.5,R0
	STF	R0,*+AR4(OVELY)

	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)



	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	NSND2

	RANDN	1
	LDI	R0,R0
	LDIZ	COCONUTHI,AR2
	LDINZ	COCONUTLOW,AR2
	CALL	ONESNDFX
NSND2

FRSL
	SLEEP	1
	BU	DROPLP
HOLDTOSLEEP
	LDI	*+AR4(ODIST),R0
	BN	DROPCOCOKILL
	SLEEP	1
	B	HOLDTOSLEEP

DROPCOCOKILL

	LDI	@COCONUT_COUNT,R0
	DEC	R0
	.if	DEBUG
	BLT	$
	.endif
	STI	R0,@COCONUT_COUNT

	LDI	AR4,AR2
	CALL	OBJ_DELETE
	DIE
*----------------------------------------------------------------------------



MODELTABI	.word	MODELTAB
MODELTAB	.word	cvettem,hotrodm,missle,testorm

TEXTTABSI	.word	TEXTTABS
TEXTTABS	.word	VETETXT,RODRTXT,BULLTXT,FERRTXT

TITLES	.word	HRT12,HRT13,HRT14,HRT15,HRT16

	romdata
VETETXT	.word	HRS11,HRS12,HRS13,HRS14,HRS15,HRS16
RODRTXT	.word	HRS21,HRS22,HRS23,HRS24,HRS25,HRS26
BULLTXT	.word	HRS31,HRS32,HRS33,HRS34,HRS35,HRS36
FERRTXT	.word	HRS41,HRS42,HRS43,HRS44,HRS45,HRS46

HRT12	.string	"TOP SPEED:",0
HRT13	.string	"SKIDPAD:",0
HRT14	.string	"AERO COEFF:",0
HRT15	.string	"0?60 MPH:",0
HRT16	.string	"POWER:",0

TABING	.float	60,220,220,220,220,220


HRS11	.string	"63 MUSCLE CAR",0
HRS12	.string	"145 MPH@233 KPH",0
HRS13	.string	"0=89 G",0
HRS14	.string	"0=39",0
HRS15	.string	"2=98 SEC=",0
HRS16	.string	"462HP  454 CID V8",0

HRS21	.string	"LA BOMBA",0
HRS22	.string	"142 MPH@228 KPH",0
HRS23	.string	"0=98 G",0
HRS24	.string	"0=45",0
HRS25	.string	"2=51 SEC=",0
HRS26	.string	"580HP  SUPERCHARGED V12",0

HRS31	.string	"DEVASTATOR VI",0
HRS32	.string	"147 MPH@236 KPH",0
HRS33	.string	"0=85 G",0
HRS34	.string	"0=25",0
HRS35	.string	"3=15 SEC=",0
HRS36	.string	"395HP  TWIN TURBO V6",0

HRS41	.string	"ITALIA P69",0
HRS42	.string	"144 MPH@231 KPH",0
HRS43	.string	"1=01 G",0
HRS44	.string	"0=28",0
HRS45	.string	"2=88 SEC=",0
HRS46	.string	"472HP  V12 DOHC 48V",0

	.text
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
*AM I AHEAD OF THE PLAYER?
*
*PARAMETERS
*	AR4	OBJECT
*	AR5	CAR BLOCK
*
*RETURNS
*	CARRY SET ON AHEAD OF PLAYER
*	CARRY CLR ON BEHIND PLAYER
*
AHEAD_OF_PLAYER_P:
	PUSH	AR0
	PUSH	AR1
	PUSH	R0

	LDI	@PLYCBLK,AR0
	LDI	*+AR0(CARTRAK),AR0
	LDI	*+AR0(OUSR1),R0

	LDI	*+AR5(CARTRAK),AR1
	CMPI	*+AR1(OUSR1),R0
	BLT	AHEADOF
	BGT	ISBEHIND


	LDI	*+AR0(OLINK4),AR0	;GET NEXT OBJECT
	LDI	*+AR0(OLINK4),AR0	;GET NEXT OBJECT

	LDF	*+AR0(OPOSX),R0
	SUBF	*+AR4(OPOSX),R0
	MPYF	R0,R0
	LDF	*+AR0(OPOSZ),R1
	SUBF	*+AR4(OPOSZ),R1
	MPYF	R1,R1
	ADDF	R1,R0

	LDI	@(_plyr1+PLY_CAR),AR1
	LDF	*+AR0(OPOSX),R2
	SUBF	*+AR1(OPOSX),R2
	MPYF	R2,R2
	LDF	*+AR0(OPOSZ),R1
	SUBF	*+AR1(OPOSZ),R1
	MPYF	R1,R1
	ADDF	R2,R1

	CMPF	R1,R0	;WHO IS CLOSER?
	BLT	AHEADOF

ISBEHIND
	CLRC
	POP	R0
	POP	AR1
	POP	AR0
	RETS
AHEADOF
	SETC
	POP	R0
	POP	AR1
	POP	AR0
	RETS
*----------------------------------------------------------------------------
	.END
