	.FILE	"ATTRDRNE.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	C30.EQU
	.include	MACS.EQU
	.include	MPROC.EQU
	.include	VUNIT.EQU
	.include	CMOS.EQU
	.include	SYSID.EQU
	.include	SYS.EQU
	.include	OBJ.EQU
	.include	GLOBALS.EQU
	.include	SNDTAB.EQU
	.include	PALL.EQU
	.include	OBJECTS.EQU
	.include	TEXT.EQU
	.include	DIRQ.EQU
	.include	DELTA.EQU


		.data

_CAMERAPOSI		.word	_CAMERAPOS
VIEWLISTI		.word	VIEWLIST
ATTR_WAVETABI		.word	ATTR_WAVETAB

		pbss	ATTRWAVE,1
		.global	CAMVIEW


*----------------------------------------------------------------------------
* CAMERA variable space
*

CUT_PAN			.set	PDATA+1
ZOOMVEL			.set	PDATA+2
CAMERA_XYZR		.set	PDATA+3		;4 long
NEWCAMERA_XYZR		.set	PDATA+7		;4 long
NEW_POSX		.set	PDATA+11
NEW_POSY		.set	PDATA+12
NEW_POSZ		.set	PDATA+13
NEW_RADX		.set	PDATA+14
NEW_RADY		.set	PDATA+15
NEW_RADZ		.set	PDATA+16
NEW_MATRIX		.set	PDATA+17	;9 long
CAMERA_VIEW		.set	PDATA+26
CAMERA_VEL		.set	PDATA+27
CAROBJ			.set	PDATA+28
CARDIS			.set	PDATA+29
CAMERA_ACCEL		.set	PDATA+30
CAMERA_INFIN		.set	PDATA+31
TEMP_DATA		.set	PDATA+32	;10 long
LIST_NUM		.set	PDATA+42
CAMERA_LANE		.set	PDATA+43
OBJINS			.set	PDATA+44
CAMYOFF			.set	PDATA+45



*----------------------------------------------------------------------------
*
;	.data
;STARTXPOS	.float	-1754318
;STARTYPOS	.float	2345
;STARTZPOS	.float	1314000
	.text

ATTRACT_DELTA:
	LDI	0,R0
	STI	R0,*+AR7(OBJINS)
	LDI	@ATTRWAVE,R4
	LSH	-1,R4
	STI	R4,*+AR7(LIST_NUM)
	CALL	INIT_ATTR_LEG


	LDI	4,R0
	STI	R0,@NOSWAP

	CREATE	LOGO_PROC,UTIL_C

	LDI	@_MODE,R0
	OR	MGO,R0
	STI	R0,@_MODE

	LDI	-1,R0
	STI	R0,*+AR7(CUT_PAN)

	LDI	1,R0	    		;SET GAME FRAME RATE
	STI	R0,@FRAMRATE
	STI	R0,@TIMECLR
	STI	R0,@DRONE_DISPATCH_P

	SLEEP	1
	LDI	@PLYCAR,AR4
	LDI	*+AR4(PAR5),AR5
	LDI	*+AR4(PAR4),AR4
	LDI	*+AR5(PAR5),AR0
	STI	AR4,@PLYCAR
	STI	AR0,@PLYCBLK

	LDI	90,R0
	STI	R0,@_countdown

	LDI	1,R0
	STI	R0,*+AR7(CUT_PAN)

	CALL	GET_LIST_ADDR
	BR	DELTA_LOOP_ENTRY

aDELTA_LOOP
	LDI	*AR6,AR0
	CALLU	AR0

ADELTA2
	CALL	UPDATE_CAMERA
	SLEEP	1

	LDI	@NOSWAP,R0
	BEQ	ADELTA2A
	SUBI	1,R0		;OK Now we have a valid frame
	STI	R0,@NOSWAP
ADELTA2A	

	CMPI	0,AR5
	BGT	aDELTA_LOOP

	ADDI	1,AR6		;Advance to next mode
DELTA_LOOP_ENTRY
	LDI	*AR6,AR0
	CMPI	0,AR0
	BNE	sDELTA_LOOP
;	CALL	GET_LIST_ADDR
;	BU	$
	SUBI	3,AR6		;Loop on last entry

sDELTA_LOOP
	LDI	*+AR7(OBJINS),R0
	BEQ	NO_OBJINS
	LDI	R0,AR2
	CALL	OBJ_INSERT			;INSERT PLAYER OBJECT
	LDI	0,R0
	STI	R0,*+AR7(OBJINS)
NO_OBJINS
	LDI	*AR6++,AR0
	CALLU	AR0

	LDI	*AR6++,AR5
	B	ADELTA2
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*CREATE THE OBJECT 'CRUISIN USA' FOR OVERLAY DURING ATTRACT MODE
*
LOGO_STARTZ		.set	10000
LOGO_ENDX		.set	-120
LOGO_ENDY		.set	-85
LOGO_ENDZ		.set	368
LOGO_FLYIN_FRAMES	.set	125
LOGO_WHOOSH_FRAMES	.set	462
LOGO_SPINZ		.set	18.85	;3 revolutions

LOGO_PROC:
	CALL	OBJ_GET
	BC	LOGOX
	LDI	AR0,AR4
	LDIL	logo,R0
	STI	R0,*+AR0(OROMDATA)
	LDI	O_IROT|O_NOROT|O_NOUROT|O_NOUNIV,R0
	OR	*+AR0(OFLAGS),R0
	STI	R0,*+AR0(OFLAGS)


	LDI	UTIL_C|LOGO_T,R0
	STI	R0,*+AR0(OID)


	FLOAT	LOGO_STARTZ,R0
	STF	R0,*+AR0(OPOSZ)
	LDI	AR0,AR2
	CALL	OBJ_INSERTP

	LDF	LOGO_SPINZ,R0
	STF	R0,*+AR4(ORADX)

	LDF	0,R7		;SPEED FACTOR
	LDI	LOGO_FLYIN_FRAMES,AR5
LOGO_LOOP1
	SLEEP	1
	FLOAT	@NFRAMES,R6

	FLOAT	LOGO_ENDY,R0
	CMPF	*+AR4(OPOSY),R0
	BEQ	LOGO2

	FLOAT	LOGO_ENDX,R0
	SUBF	*+AR4(OPOSX),R0
	MPYF	R7,R0
	MPYF	R6,R0
	ADDF	*+AR4(OPOSX),R0
	FLOAT	LOGO_ENDX,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR4(OPOSX)

	FLOAT	LOGO_ENDY,R0
	SUBF	*+AR4(OPOSY),R0
	MPYF	R7,R0
	MPYF	R6,R0
	ADDF	*+AR4(OPOSY),R0
	FLOAT	LOGO_ENDY,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR4(OPOSY)

	ADDF	0.03,R7

LOGO2
	FLOAT	LOGO_ENDZ-LOGO_STARTZ,R0
	FLOAT	LOGO_FLYIN_FRAMES,R1
	CALL	DIV_F
	MPYF	R6,R0
	LDF	*+AR4(OPOSZ),R1
	ADDF	R1,R0
	FLOAT	LOGO_ENDZ,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR4(OPOSZ)

	LDF	LOGO_SPINZ,R0
	FLOAT	LOGO_FLYIN_FRAMES,R1
	CALL	DIV_F
	MPYF	R6,R0
	LDF	*+AR4(ORADX),R2
	SUBF	R0,R2
	LDFN	0,R2
	STF	R2,*+AR4(ORADX)
	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_ZMATRIX

	SUBI	@NFRAMES,AR5
	CMPI	0,AR5
	BP	LOGO_LOOP1

LOGOX
	DIE

*----------------------------------------------------------------------------
GET_LIST_ADDR:
	LDI	*+AR7(LIST_NUM),AR6
	ADDI	@VIEWLISTI,AR6
	LDI	*AR6,AR6
	RETS

*----------------------------------------------------------------------------

	.SECT	"THEDATA"
VIEWLIST
	.word	GGPARK_LIST
	.word	BEVHILL_LIST
	.word	GCANYON_LIST
	.word	CHICAGO_LIST
	.word	GGPARK_LIST
	.word	BEVHILL_LIST
	.word	GCANYON_LIST
	.word	CHICAGO_LIST

GGPARK_LIST
*THE first call is to intialize
	.word	INIT_STARTING,70,ROAD_VIEW
	.word	INIT_LEAD,80,LEAD_VIEW
	.word	INIT_WATCH,1214h,240,WATCH_VIEW
	.word	CUT_TO_VIEW2,1404h,SMOOTH_VIEW
	.word	INITVIEW1_VIEW,17FBh,SMOOTH_VIEW
	.word	INIT_LEAD,80,LEAD_VIEW
	.word	0,0

BEVHILL_LIST
*THE first call is to intialize
	.word	INIT_STARTING,80,ROAD_VIEW
	.word	CUT_TO_VIEW2,14AFBh,SMOOTH_VIEW
	.word	INITVIEW1_VIEW,14DF3h,SMOOTH_VIEW
	.word	INIT_STARTING,100,ROAD_VIEW
	.word	0,0


GCANYON_LIST
*THE first call is to intialize
	.word	INIT_STARTING,70,ROAD_VIEW
	.word	INIT_WATCH,2E20Ah,220,WATCH_VIEW
	.word	CUT_TO_VIEW2,2E800h,SMOOTH_VIEW
	.word	INITVIEW1_VIEW,2EC00h,SMOOTH_VIEW
	.word	INIT_WATCH,2EF00h,240,WATCH_VIEW
	.word	CUT_TO_VIEW2,30000h,SMOOTH_VIEW
	.word	0,0

CHICAGO_LIST
*THE first call is to intialize
	.word	INIT_STARTING,80,ROAD_VIEW
	.word	INIT_REVERS_CUP,60,REV_ROAD_VIEW
	.word	CUT_TO_VIEW2,3AA0Eh,SMOOTH_VIEW
	.word	INITVIEW1_VIEW,3C00Ah,SMOOTH_VIEW
	.word	INIT_WATCH,3C5F5h,240,WATCH_VIEW
	.word	INIT_LEAD,80,LEAD_VIEW
	.word	0,0

	.text
*----------------------------------------------------------------------------
INIT_STARTING:
	LDI	-350,R0
	FLOAT	R0,R1
	STF	R1,*+AR7(CAMYOFF)
	LDI	4,R0		;direction to search in
	LDI	1,R1		;distance to start with
	LDI	8,R2		;Position to follow
	LDF	0,R3		;RADY OFFSET

	CALL	INITROAD_VIEW
	LDF	1,R2
	CALL	SET_LANE
	CALL	INIT_LANE
	CALL	ROAD_VIEW

	CALL	UPDATE_CAMERA
	CALL	RESCAN
	RETS

*----------------------------------------------------------------------------
INIT_WATCH:
	LDI	1,R0
	STI	R0,*+AR7(CUT_PAN)

	LDF	0,R0
	STF	R0,*+AR7(CAMERA_XYZR+3)		;Reset the offset
	LDI	*AR6++,R2				;READ the track ID from the VIEWLIST
	CALL	FIND_MAP
INIW1
	LDI	*+AR4(3),R2		;Get ID
	CALL	FIND_TRACK		;MAKE DAMN SURE WE ARE ON A LOADED TRACK SECTION!!!
	CMPI	0,AR2
	BNE	INIW2
	SUBI	4,AR4
	BR	INIW1
INIW2
	PUSH	AR4
	LDI	4,R2
	CALL	FIND_RACER
	STI	AR4,*+AR7(CAROBJ)
	STI	AR4,@PLYCAR
	LDI	*+AR4(OCARBLK),AR0
	STI	AR0,@PLYCBLK
	POP	AR4

	LDI	-300,R0
	FLOAT	R0,R1
	STF	R1,*+AR7(CAMYOFF)
	ADDI	*+AR4(Y),R0
	FLOAT	R0
	STF	R0,*+AR7(NEW_POSY)

	FLOAT	*+AR4(X),R0
	STF	R0,*+AR7(NEW_POSX)

	FLOAT	*+AR4(Z),R0
	STF	R0,*+AR7(NEW_POSZ)

	LDI	AR4,AR2
	ADDI	-4,AR2

	LDI	*+AR2(X),R0
	SUBI	*+AR4(X),R0
	FLOAT	R0
	MPYF	R0,R0
	LDI	*+AR2(Z),R1
	SUBI	*+AR4(Z),R1
	FLOAT	R1
	MPYF	R1,R1
	ADDF	R0,R1,R2
	CALL	SQRT
	LDF	R0,R2

	LDI	*+AR2(Y),R3
	SUBI	*+AR4(Y),R3
	FLOAT	R3
	MPYF	1.8,R3
	CALL	ARCTANF
	CALL	NORM_VECTOR
	NEGF	R0
	ADDF	0.09,R0		;Offset for VIEWX
	STF	R0,*+AR7(NEW_RADX)

	FLOAT	-2500,R3
	CALL	DO_LANE_POS

	LDF	-100,R6			;SMALL number for a rad
	CALL	WATCH_VIEW
	LDF	*+AR7(NEW_RADY),R6	;Save initial value

	CALL	UPDATE_CAMERA
	PUSHF	R6
	CALL	RESCAN			;This hoses all RX registers
	POPF	R6
	RETS

*----------------------------------------------------------------------------
INIT_REVERS_CUP:
	LDI	-350,R0
	FLOAT	R0,R1
	STF	R1,*+AR7(CAMYOFF)
	LDI	4,R0		;direction to search in
	LDI	1,R1		;distance to start with
	LDI	5,R2		;Position to follow
	LDF	PI,R3
	CALL	INITROAD_VIEW
	LDF	1,R2
	CALL	SET_LANE
	CALL	INIT_LANE
	CALL	REV_ROAD_VIEW

	CALL	UPDATE_CAMERA
	CALL	RESCAN
	RETS

*----------------------------------------------------------------------------
INIT_CATCHUP:
	LDI	-350,R0
	FLOAT	R0,R1
	STF	R1,*+AR7(CAMYOFF)
	LDI	4,R0		;direction to search in
	LDI	1,R1		;distance to start with
	LDI	5,R2		;Position to follow
	LDF	0,R3
	CALL	INITROAD_VIEW
	LDF	1,R2
	CALL	SET_LANE
	CALL	INIT_LANE
	CALL	ROAD_VIEW
	CALL	UPDATE_CAMERA
	CALL	RESCAN
	RETS

*----------------------------------------------------------------------------
INIT_LEAD:
	LDI	-300,R0
	FLOAT	R0,R1
	STF	R1,*+AR7(CAMYOFF)
	LDI	-4,R0
	LDI	1,R1
	LDI	0,R2
	LDF	PI,R3
	CALL	INITROAD_VIEW
	LDF	1,R2
	CALL	SET_LANE
	CALL	INIT_LANE
	CALL	LEAD_VIEW
	CALL	UPDATE_CAMERA
	CALL	RESCAN
	RETS

*----------------------------------------------------------------------------
INITROAD_VIEW:
	STI	R0,*+AR7(CAMERA_XYZR)
	STI	R1,*+AR7(CAMERA_XYZR+1)
	STI	R2,*+AR7(CAMERA_XYZR+2)
	STF	R3,*+AR7(CAMERA_XYZR+3)

	LDF	0,R0
	STF	R0,*+AR7(CAMERA_ACCEL)

	LDI	1,R0
	STI	R0,*+AR7(CUT_PAN)

	LDI	*+AR7(CAMERA_XYZR+2),R2		;Position to find
	CALL	FIND_RACER

	LDI	AR4,AR0
	STI	AR4,*+AR7(CAROBJ)
	STI	AR4,@PLYCAR
	LDI	*+AR4(OCARBLK),AR1
	STI	AR1,@PLYCBLK

	CALL	GET_MAP_CARBLK

	LDI	*+AR7(CAMERA_XYZR+1),R0
	MPYI	*+AR7(CAMERA_XYZR),R0
	SUBI	R0,AR4		;Start this many track sections behind first place
	LDI	@NOSWAP,R0
	CMPI	0,R0			;Don't check during init
	BNE	OK_FOUNDIT
TRY_AGAIN
	LDI	*+AR4(3),R2		;Get ID
	CALL	FIND_TRACK
	CMPI	0,AR2
	BNE	OK_FOUNDIT
	ADDI	*+AR7(CAMERA_XYZR),AR4
	BR	TRY_AGAIN
OK_FOUNDIT
	CALL	GET_ROAD_RADY
	STF	R0,*+AR7(NEW_RADY)

	FLOAT	*+AR4(X),R0
	STF	R0,*+AR7(NEW_POSX)

	FIX	*+AR7(CAMYOFF),R0
	ADDI	*+AR4(Y),R0
	FLOAT	R0
	STF	R0,*+AR7(NEW_POSY)

	FLOAT	*+AR4(Z),R0
	STF	R0,*+AR7(NEW_POSZ)

	RETS


*----------------------------------------------------------------------------
WATCH_VIEW:

	LDI	*+AR7(CAROBJ),AR0
	LDF	*+AR0(OPOSX),R2		;Get the direction of the car relative to 
	SUBF	*+AR7(NEW_POSX),R2	;the direction the camera is moving in.
	LDF	*+AR0(OPOSZ),R3
	SUBF	*+AR7(NEW_POSZ),R3
	CALL	ARCTANF
	CALL	NORM_VECTOR
	SUBF	HALFPI,R0
	CALL	NORM_VECTOR
	NEGF	R0
	STF	R0,*+AR7(NEW_RADY)
WV1
	LDI	AR7,R2
	ADDI	NEW_RADX,R2
	LDI	AR7,AR2
	ADDI	NEW_MATRIX,AR2
	CALL	FIND_MATRIX

	LDI	@NFRAMES,R0
	SUBI	R0,AR5		;Will count frames in this case

	LDI	@ATTRWAVE,R0
	CMPI	2,R0		;preincremented will actually be GGPARK
	BNE	NO_WHOOSH
	READADJ	ADJ_ATTRACT_MODE_SOUND
	CMPI	0,R0
	BEQ	NO_WHOOSH
	LDF	R6,R0
	SUBF	*+AR7(NEW_RADY),R0
	CMPF	0.18,R0			;9deg	diff
	BLT	NO_WHOOSH
	LDF	-100,R6				;do only once
	SOND1	WHOOSH
NO_WHOOSH

	RETS



*----------------------------------------------------------------------------
REV_ROAD_VIEW:
	LDI	*+AR7(CAROBJ),AR0
	LDI	*+AR0(OCARBLK),AR1
	LDF	*+AR1(CARSPEED),R0
	MPYF	1.8,R0
	STF	R0,*+AR7(CAMERA_VEL)	;Set initial camera velocity
	LDF	0.6,R2
	CALL	SET_LANE
	CALL	MOVE_ROAD_CAMERA
	RETS
	
*----------------------------------------------------------------------------
	.data
ACCEL_RATE	.float	0.000002
	.text
ROAD_VIEW:
	CALL	FIND_CLOSEST_RACER
	CMPI	0,AR1
	LDIZ	0,AR5		;PASSED FIRST PLACE CHANGE MODES (AR5 = frame to switch)
	BEQ	RV1

	CMPI	*+AR7(CAROBJ),AR1
	BEQ	RV1A
	LDF	0,R2
	STF	R2,*+AR7(CAMERA_ACCEL)


	STI	AR1,*+AR7(CAROBJ)	;FOUND a NEW CAR
	STI	AR1,@PLYCAR
	LDI	*+AR1(OCARBLK),AR0
	STI	AR0,@PLYCBLK
	STF	R0,*+AR7(CARDIS)
RV1A

	LDF	@ACCEL_RATE,R3
	LDF	*+AR7(CAMERA_ACCEL),R2
	LDF	*+AR7(CARDIS),R1
	MPYF	0.6,R1
	CMPF	R0,R1			;Are we half way there yet?
	BLT	RV1B
	NEGF	R3
RV1B
	ADDF	R3,R2
	LDFLT	0,R2
	STF	R2,*+AR7(CAMERA_ACCEL)
	MPYF	R0,R2			;Factor in overall distance
	ADDF	1.6,R2
	
	LDI	*+AR1(OCARBLK),AR0
	LDF	*+AR0(CARSPEED),R0
	MPYF	R2,R0
	STF	R0,*+AR7(CAMERA_VEL)	;Set initial camera velocity
RV1
	LDF	0.6,R2
	CALL	SET_LANE
	CALL	MOVE_ROAD_CAMERA
	RETS

*----------------------------------------------------------------------------
LEAD_VIEW:
	LDI	*+AR7(CAROBJ),AR0
	LDI	*+AR0(OCARBLK),AR1
	LDF	*+AR1(CARSPEED),R0
	MPYF	1.51,R0
	STF	R0,*+AR7(CAMERA_VEL)	;Set initial camera velocity

	LDF	0.6,R2
	CALL	SET_LANE
	CALL	MOVE_ROAD_CAMERA
	RETS


*----------------------------------------------------------------------------
MOVE_ROAD_CAMERA:
	LDI	@NOSWAP,R0	;If noswap is on definatly do it
	BNE	MRC1
	LDI	@SUSPEND_MODE,R0	;This stops the shimmer at the start of bevhills
	CMPI	SM_HALT,R0
	BEQ	MRCX
MRC1
	CALL	GETCAMDIR

	LDI	@VECTORBI,AR2
	LDF	*+AR7(NEW_RADX),R0
	STF	R0,*+AR2(X)
	LDF	*+AR7(NEW_RADZ),R0
	STF	R0,*+AR2(Z)

	LDF	*+AR7(NEW_RADY),R0
	SUBF	*+AR7(CAMERA_XYZR+3),R0	;LOOSE the Offset rad for viewing
	CALL	NORM_VECTOR
	NEGF	R0			;Move in oposite direction looking?
	STF	R0,*+AR2(Y)

	LDI	@VECTORBI,R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_MATRIX

	LDI	@VECTORAI,AR2
	LDF	0,R0
	STF	R0,*+AR2(X)
	STF	R0,*+AR2(Y)
	LDF	*+AR7(CAMERA_VEL),R0
	FLOAT	@NFRAMES,R1
	MPYF	R1,R0
	STF	R0,*+AR2(Z)
	LDI	@VECTORBI,R3
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

	LDI	@VECTORBI,AR2
	LDF	*+AR2(X),R0
	ADDF	*+AR7(NEW_POSX),R0
	STF	R0,*+AR7(NEW_POSX)

	LDF	*+AR2(Z),R0
	ADDF	*+AR7(NEW_POSZ),R0
	STF	R0,*+AR7(NEW_POSZ)

	PUSH	AR4
	LDI	AR7,AR4
	ADDI	NEW_POSX,AR4
	CALL	CAMSCAN
	POP	AR4
	BNC	USE_SLOPE
	LDF	*+AR7(CAMYOFF),R1
	ADDF	R1,R0
	ADDF	*+AR7(NEW_POSY),R0
	STF	R0,*+AR7(NEW_POSY)
	BR	NO_SLOPE
USE_SLOPE
;This code should really never get used
	LDI	AR4,AR2
	ADDI	4,AR2
	LDI	*+AR2(Z),R0
	SUBI	*+AR4(Z),R0
	FLOAT	R0
	MPYF	R0,R0
	LDI	*+AR2(X),R1
	SUBI	*+AR4(X),R1
	FLOAT	R1
	MPYF	R1,R1
	ADDF3	R0,R1,R2	;R= SQRT (X^2 + Z^2)
	CALL	SQRT
	LDF	R0,R1

	LDI	*+AR2(Y),R0
	SUBI	*+AR4(Y),R0
	FLOAT	R0
	MPYF	1.05,R0		;FUDGE FACTOR
	CALL	DIV_F
	LDI	@VECTORAI,AR0
	LDF	*+AR0(Z),R1
	MPYF	R1,R0
	ADDF	*+AR7(NEW_POSY),R0
	STF	R0,*+AR7(NEW_POSY)

	LDI	-400,R1		;at 1000 above the road
	ADDI	*+AR4(Y),R1
	FLOAT	R1
	SUBF	*+AR7(NEW_POSY),R1
	MPYF	0.04,R1
	ADDF	*+AR7(NEW_POSY),R1
	STF	R1,*+AR7(NEW_POSY)
NO_SLOPE

	LDI	AR7,R2
	ADDI	NEW_RADX,R2
	LDI	AR7,AR2
	ADDI	NEW_MATRIX,AR2
	CALL	FIND_MATRIX

	CALL	NEXT_ROAD
MRCX
	RETS
*---------------------------------------------------------------------------
* Updates AR4 to point to the road segment that the camera is on
* NOTE: uses Stealth mode
* INPUT	AR4 = segment on
* OUTPUT AR4 = segment on (updated)
*

NEXT_ROAD:
	FLOAT	*+AR4(X),R0
	SUBF	*+AR7(NEW_POSX),R0
	MPYF	R0,R0
	FLOAT	*+AR4(Z),R1
	SUBF	*+AR7(NEW_POSZ),R1
	MPYF	R1,R1
	ADDF	R1,R0

	LDI	AR4,AR2
	ADDI	4,AR2
	FLOAT	*+AR2(X),R1
	SUBF	*+AR7(NEW_POSX),R1
	MPYF	R1,R1
	FLOAT	*+AR2(Z),R2
	SUBF	*+AR7(NEW_POSZ),R2
	MPYF	R2,R2
	ADDF	R2,R1

	CMPF	R1,R0
	BLE	fcrx			;didn't move
	ADDI	4,AR4
;	.if	DEBUG
;	LDI	*+AR4(3),R2
;	CALL	FIND_TRACK
;	CMPI	0,AR2
;	BNE	fcr1
;	LOCKUP				;TRACK not loaded yet
;fcr1
;	.endif
	DEC	AR5			;AR5 is the number of road segments before swithching
	BR	NEXT_ROAD		;See if the road segment beyond is even closer
fcrx
	RETS

*---------------------------------------------------------------------------
* Sets the cameras RADY based on the next track segments reletive position
* NOTE: uses stealth mode
* No I/O
*	Sets CAMERA_RADY = (CAMERA_XYZR+3)+ RAD to next track section

GETCAMDIR:
	LDF	*+AR7(CAMERA_VEL),R0	;Adjust the smothing factor to speed
	FLOAT	@NFRAMES,R1
	MPYF	R1,R0
	FLOAT	5000,R1
	CALL	DIV_F
	LDF	R0,R4

	CALL	GET_ROAD_RADY		;Calculate the offset for lane position
	NEGF	R0			;based on the roads direction
	LDF	R0,R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX

	LDI	@VECTORAI,AR2
	LDF	0,R0
	STF	R0,*+AR2(Y)
	STF	R0,*+AR2(Z)
	LDF	*+AR7(CAMERA_LANE),R0
	STF	R0,*+AR2(X)
	LDI	@VECTORBI,R3
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

	LDI	AR4,AR1
	ADDI	4*2,AR1

	LDI	@VECTORBI,AR2			;Factor in the desired location to be at
	FLOAT	*+AR1(Z),R2			;reletive to where we are
	ADDF	*+AR2(Z),R2
	SUBF	*+AR7(NEW_POSZ),R2
	FLOAT	*+AR1(X),R3
	ADDF	*+AR2(X),R3
	SUBF	*+AR7(NEW_POSX),R3
	CALL	ARCTANF
	CALL	NORM_VECTOR
	ADDF	*+AR7(CAMERA_XYZR+3),R0		;Offset for VIEW
	CALL	NORM_VECTOR
	SUBF	*+AR7(NEW_RADY),R0
	LDF	R4,R2
	CALL	SMOOTH_VECTOR
	ADDF	*+AR7(NEW_RADY),R0
	STF	R0,*+AR7(NEW_RADY)

	LDF	0,R0
	STF	R0,*+AR7(NEW_RADX)
	STF	R0,*+AR7(NEW_RADZ)

	RETS

*----------------------------------------------------------------------------
*INPUT R2 = FL smoothing
SET_LANE:
	LDI	*+AR7(CAROBJ),AR0
	LDI	*+AR0(OPLINK),AR0
	FLOAT	1000,R1			;Offset to center of right lanes
	LDF	*+AR0(ROADOFFSET),R0
	BP	SL1
	NEGF	R1
SL1
	SUBF	R1,R0
;	MPYF	0.40,R0			;Move to just inside where the car is.
	MPYF	0.30,R0			;Move to just inside where the car is.
	ADDF	R1,R0
	CMPF	1.0,R2
	BEQ	SL2
	SUBF	*+AR7(CAMERA_LANE),R0
	MPYF	R2,R0
	ADDF	*+AR7(CAMERA_LANE),R0
	STF	R0,*+AR7(CAMERA_LANE)
SL2
	STF	R0,*+AR7(CAMERA_LANE)
	RETS
*----------------------------------------------------------------------------
INIT_LANE:
	LDF	*+AR7(CAMERA_LANE),R3
	CALL	DO_LANE_POS
	RETS

*---------------------------------------------------------------------------
*INPUT	R2 = RADIANS to offset for doing the lanes
*	R3 = Distance from center +/-

DO_LANE_POS:
	PUSHF	R3
	LDI	AR4,AR1
	ADDI	4*2,AR1

	CALL	GET_ROAD_RADY
	NEGF	R0
	LDF	R0,R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX

	LDI	@VECTORAI,AR2
	LDF	0,R0
	STF	R0,*+AR2(Y)
	STF	R0,*+AR2(Z)
	POPF	R0
	STF	R0,*+AR2(X)

	LDI	@VECTORBI,R3
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

	LDI	@VECTORBI,AR2
	LDF	*+AR2(X),R0
	ADDF	*+AR7(NEW_POSX),R0
	STF	R0,*+AR7(NEW_POSX)

	LDF	*+AR2(Z),R0
	ADDF	*+AR7(NEW_POSZ),R0
	STF	R0,*+AR7(NEW_POSZ)
	RETS

*---------------------------------------------------------------------------
*INPUT	AR4 = POINTER to LEG_MAP where road is
*OUTPUT	R0 = DIRECTION of road 
GET_ROAD_RADY:
	PUSH	AR1
	PUSH	R2
	PUSHF	R2
	PUSH	R3
	PUSHF	R3

	LDI	AR4,AR1
	ADDI	4*2,AR1

	LDI	*+AR1(Z),R2
	SUBI	*+AR4(Z),R2
	FLOAT	R2
	LDI	*+AR1(X),R3	;Get the direction of the road
	SUBI	*+AR4(X),R3
	FLOAT	R3
	CALL	ARCTANF
	CALL	NORM_VECTOR

	POPF	R3
	POP	R3
	POPF	R2
	POP	R2
	POP	AR1
	RETS

*---------------------------------------------------------------------------
*This algorithm is based on a bubble sort
*Find the RACER DRONE IN FIRST PLACE based on position in LEG_MAP
*INPUT R2 = Position to find
*OUTPUT AR4 = OBJ of the racer
*
*
FIND_RACER:
	LDI	AR7,AR3			;clear the list
	ADDI	TEMP_DATA,AR3
	LDI	0,R0
	RPTS	9
	STI	R0,*AR3++
	LDI	AR7,AR3
	ADDI	TEMP_DATA,AR3

	LDI	0,IR0
	LDI	0,AR1
	LDI	7FFFh,R3
	MPYI	R3,R3			;BIG number
FR0
	LDI	0,R4
	LDI	@CAR_LISTI,AR0		;Scan the list of car objects
	SUBI	OLINK3,AR0

FR1
	LDI	*+AR0(OLINK3),AR0	;They are linked by OLINK3
	CMPI	0,AR0
	BEQ	FRX

	LDI	*+AR0(OID),R0			;Is this a racer?
	CMPI	DRONE_C|VEHICLE_T|DRNE_RACER,R0
	BNE	FR1

	CALL	GET_MAP_CARBLK

	CMPI	AR4,R3			;Best position looking for
	BLT	FR1
	CMPI	AR4,R4			;Greatest entry in the LEG_MAP wins
	BGT	FR1

	LDI	IR0,IR1			;WHILE ((IR0>0) && (*+AR3(IR1++) != AR0))
FR2A
	SUBI	1,IR1
	CMPI	0,IR1
	BN	FR2B
FR2
	CMPI	*+AR3(IR1),AR0		;IF THIS CAR IS ALLREADY ON LIST, Then Get NEXT
	BEQ	FR1
	BR	FR2A
FR2B
	LDI	AR4,R4
	LDI	AR0,AR1			;Set the pointer to the cars obj
	BU	FR1
FRX
	STI	AR1,*+AR3(IR0)
	ADDI	1,IR0
	LDI	R4,R3
	SUBI	1,R2
	BP	FR0			;Find the next best
	CMPI	0,AR1
	BNE	FRXX
	LOCKUP				;No RACERS?
FRXX
	LDI	AR1,AR4
	RETS	

*----------------------------------------------------------------------------
*This algorithm is based on a single pass bubble sort
*OUTPUT
*	R0	=	Distance to the closest Racer Drone
*	AR1	=	Pointer to the Closest Racer Drone in front of the camera
*	AR1	=	0, If no Racer Drones in front of the camera
*


FIND_CLOSEST_RACER:
	FLOAT	30000,R5
	MPYF	R5,R5
	MPYF	R5,R5
	MPYF	R5,R5
	MPYF	R5,R5		;BIG F'N NUMBER

	LDI	@CAR_LISTI,AR0		;Scane the linked list of cars
	SUBI	OLINK3,AR0
	LDI	0,AR1
FCR1
	LDI	*+AR0(OLINK3),AR0
	CMPI	0,AR0
	BEQ	FCRX

	LDI	*+AR0(OID),R0
	CMPI	DRONE_C|VEHICLE_T|DRNE_RACER,R0	;Racer drones only
	BNE	FCR1

	LDF	*+AR0(OPOSZ),R2
	SUBF	*+AR7(NEW_POSZ),R2
	LDF	*+AR0(OPOSX),R3		;Get the direction of the car relative to 
	SUBF	*+AR7(NEW_POSX),R3	;the direction the camera is moving in.
	CALL	ARCTANF
	CALL	NORM_VECTOR
	SUBF	*+AR7(NEW_RADY),R0	;DEG from camera
	CALL	NORM_VECTOR
	SUBF	*+AR7(CAMERA_XYZR+3),R0	;LOOSE the Offset rad for viewing
	CALL	NORM_VECTOR
	ABSF	R0
	CMPF	0.78,R0			;Within +/- 45deg?
	BGT	FCR1			;Nop this car is beside us or behind us

	LDF	*+AR0(OPOSX),R0		;Now compute the distance to the car
	SUBF	*+AR7(NEW_POSX),R0	;D = SQRT((X2-X1)^2+(Y2-Y1)^2)
	MPYF	R0,R0
	LDF	*+AR0(OPOSZ),R1
	SUBF	*+AR7(NEW_POSZ),R1
	MPYF	R1,R1
	ADDF	R0,R1,R2
	CALL	SQRT
	CMPF	R0,R5
	LDFGT	R0,R5
	LDIGT	AR0,AR1
	BU	FCR1
FCRX
	LDF	R5,R0
	RETS

*---------------------------------------------------------------------------
*
*GET OBJECT POINTER TO ROAD SEG ID IN R2
*INPUTS  R2=OUSR1
*OUPTUTS AR2=POINTER TO OBJECT
*	  AR2=0 not found
FIND_TRACK:
	LDI	@DYNALIST_TRUEBEGIN,AR2
FDL
	LDI	*+AR2(OUSR1),R0
	CMPI	R0,R2
	BZ	FDLX
	LDI	*+AR2(OLINK4),AR2
	CMPI	0,AR2			;CHECK END OF THE LINE
	BNZ	FDL
FDLX
	RETS

*---------------------------------------------------------------------------
*
*GET POINTER TO MAP_LEG, FOR THE CAR IN AR4
*INPUTS  AR0=POINTER TO CARBLK
*OUPTUTS AR4=POINTER TO place in LEG_MAP
*SETS CAROBJ IF GET_MAP_SEGMENT is called

GET_MAP_CARBLK:				;INPUT is AR0=POINTER TO THE CARBLK
	PUSH	R2
	LDI	*+AR0(OPLINK),AR2
	LDI	*+AR2(DELTA_SPTR),AR4
	LDI	*+AR2(STEALTHMODE),R0	;ARE YOU A STEALTHY BITCH?
	BNZ	GMSX
	LDI	*+AR0(OCARBLK),AR4
	LDI	*+AR4(CARTRAK),AR4	;Get the track piece the car is on
	LDI	*+AR4(OUSR1),R2

	CALL	FIND_MAP

GMSX
	POP	R2
	RETS

*---------------------------------------------------------------------------
*
*GET POINTER TO MAP_LEG, ID IN R2
*INPUTS  R2=OUSR1
*OUPTUTS AR4=POINTER TO place in LEG_MAP

FIND_MAP:
	LDI	@LEG_MAPI,AR4		;FIND THE POSITION IN THE MAP
	ADDI	3,AR4				;OFFSET TO ID
FIND_LP
	LDI	*AR4++(4),R0
	CMPI	R2,R0
	BLT	FIND_LP
FINDX
	SUBI	7,AR4
	RETS

INITVIEW1_VIEW:
	LDI	0,R1
	STI	R0,*+AR7(CAMERA_VIEW)
	LDI	@PLYCAR,AR4
	LDF	0,R0
	FLOAT	-150,R1
	FLOAT	0,R2
	LDF	0,R3
	BR	SET_SMOOTH_VIEW

CUT_TO_VIEW2:
	LDI	1,R0			;Don't smooth while spinning
	STI	R0,*+AR7(CUT_PAN)

	LDI	4,R2		;FOLOW 3rd place
	CALL	FIND_RACER
	STI	AR4,@PLYCAR
	LDI	*+AR4(OCARBLK),AR0
	STI	AR0,@PLYCBLK
	CALL	INITVIEW2_VIEW
	CALL	UPDATE_CAMERA
	CALL	RESCAN
	RETS

INITVIEW2_VIEW:
	LDI	@PLYCAR,AR4

	LDI	1,R0
	STI	R0,*+AR7(CAMERA_VIEW)
	LDF	0,R0
	FLOAT	-400,R1
	FLOAT	-2200,R2
	LDF	0,R3
	BR	SET_SMOOTH_VIEW

INITVIEW3_VIEW:
	LDI	BUT_VIEW3,R1
	STI	R0,*+AR7(CAMERA_VIEW)
	LDF	0,R0
	FLOAT	-900,R1
	FLOAT	-3840,R2
	LDF	0,R3
	BR	SET_SMOOTH_VIEW

*----------------------------------------------------------------------------
	.ref	CAMYADJ

FACE_FRONT:
	PUSH	AR5

	LDI	*+AR4(OCARBLK),AR5
	LDI	*+AR4(OFLAGS),R0	;CHECK IF CAR IS DISPLAYED
	TSTB	O_LIST_M,R0
	BNZ	SECOND_PERSON			
FIRST_PERSON				;NO, Then in first person
	LDI	0,R0
	STI	R0,@CAMVIEW

	LDI	AR7,AR2
	ADDI	NEW_MATRIX,AR2
	LDI	AR4,R2
	ADDI	OMATRIX,R2
	CALL	CPYIMAT			;Copy the cars matrix into NEW_MATRIX

	LDF	0,R0
	STF	R0,*+AR5(CARROT)	;NO OVERROTATION IN CORNER

	LDF	0,R0
	STF	R0,*+AR7(NEW_RADY)		;NOTE this is not used for first person

	LDF	*+AR5(CARXLEAN),R0
	MPYF	-0.7,R0			;NEGATE AND SCALE
	SUBF	*+AR7(NEW_RADX),R0
	LDF	0.20,R2
	CALL	SMOOTH_VECTOR	
	ADDF	*+AR7(NEW_RADX),R0
	STF	R0,*+AR7(NEW_RADX)		;NOTE this is not used for first person

	LDF	*+AR5(CARZLEAN),R0  	;GET Z LEAN FACTOR
	MPYF	-0.5,R0			;NEGATE AND SCALE
	STF	R0,*+AR7(NEW_RADZ)

	LDI	@MATRIXCI,AR2
	LDI	AR7,R2
	ADDI	NEW_RADX,R2
	CALL	FIND_MATRIX

	LDI	AR7,AR2
	ADDI	NEW_MATRIX,AR2
	LDI	AR2,R3
	LDI	@MATRIXCI,R2
	CALL	CONCATMAT

	NEGF	*+AR5(CARYROT),R0	;SAVE this for switching out of first person
	STF	R0,*+AR7(NEW_RADY)		;NOTE this is not used for first person

	LDI	*+AR5(CAR_SPIN),R0	;SPINNING?
	BZ	FFX
	LDI	1,R0			;Don't smooth while spinning
	STI	R0,*+AR7(CUT_PAN)
	BR	FFX

SECOND_PERSON
	LDI	1,R0
	STI	R0,@CAMVIEW
	LDI	*+AR5(CAR_SPIN),R0	;SPINNING?
	BNZ	FFX			;YES, DONT mess WITH CAMERA ANGLE

	LDF	*+AR4(OVELX),R3		
	LDF	*+AR4(OVELZ),R2
	ADDF3	R3,R2,R1
	CMPF	0,R1
	BNE	FFX1
	NEGF	*+AR5(CARYROT),R0	;If stopped don't use the velocity
	BR	FFX2
FFX1
	CALL	ARCTANF
FFX2
	CALL	NORM_VECTOR
	ADDF	*+AR7(CAMERA_XYZR+3),R0

	LDI	*+AR7(CUT_PAN),R2
	CMPI	0,R2
	BNE	FFX3				;NO smoothing in a cut
	SUBF	*+AR7(NEW_RADY),R0
	LDF	0.10,R2	
;	LDF	0.20,R2	
	CALL	SMOOTH_VECTOR

	ADDF	*+AR7(NEW_RADY),R0
FFX3
	STF	R0,*+AR7(NEW_RADY)

	LDF	0,R0
	STF	R0,*+AR7(NEW_RADX)
	STF	R0,*+AR7(NEW_RADZ)
FFX4
	LDI	AR7,R2
	ADDI	NEW_RADX,R2
	LDI	AR7,AR2
	ADDI	NEW_MATRIX,AR2
	CALL	FIND_MATRIX

	LDI	AR7,AR0
	ADDI	NEW_POSX,AR0
	CALL	CAMYADJ			;MAKE sure the camera doesn't go below the road

FFX
	POP	AR5
	RETS


*----------------------------------------------------------------------------
*Does averaging
*INPUT
*		R2 = average	0.20
*		R0 = difference between the two angles
*OUTPUT
*		R0 = SMOOTHED difference
SMOOTH_VECTOR:
	CALL	NORM_VECTOR

	LDI	*+AR5(CAR_SPIN),R3	;SPINNING?
	CMPI	1,R3
	BEQ	SV1			;Yes then don't smooth
	LDF	R0,R3		;Save of the non smoothed value

	MPYF	R2,R0	    		;ANGLE SMOOTHING

	ABSF	R3,R2
	CMPF	0.78,R2 	;Is this within 45 degrees?
	BLT	SVX
	LDF	R3,R0		;NO, Then don't smooth the pig (PROBABLY JUST CHANGED CAMERA ANGLE)
SV1
	LDI	1,R3
	STI	R3,*+AR7(CUT_PAN)	;This is a cut, Don't smooth the matrix
SVX
	RETS

SERIOUSLY_NORMALIZE:  		;For those crazy wacked out vectors that are more than 360deg
	ABSF	R0,R1
	CMPF	@TWOPII,R1
	BLT	NORM_VECTOR
	LDF	@TWOPII,R1
	PUSHF	R0
	CALL	DIV_F
	FIX	R0,R1
	FLOAT	R1
	MPYF	@TWOPII,R1		;MOD 6.28
	POPF	R0
	SUBF	R1,R0
NORM_VECTOR:
	LDF	0,R1 			;NORMALIZE DIFFERENCE
	CMPF	3.14,R0
	LDFGT	-6.28,R1

	CMPF	-3.14,R0
	LDFLT	6.28,R1
	ADDF	R1,R0
	RETS

*----------------------------------------------------------------------------

SET_SMOOTH_VIEW:
	LDI	0,AR5			;Set AR5 for init

	STF	R0,*+AR7(NEWCAMERA_XYZR)
	STF	R1,*+AR7(NEWCAMERA_XYZR+1)
	STF	R2,*+AR7(NEWCAMERA_XYZR+2)
	STF	R3,*+AR7(NEWCAMERA_XYZR+3)

	LDF	0,R4
	STF	R4,*+AR7(ZOOMVEL)

	LDI	*+AR7(CUT_PAN),R4
	BEQ	SMOOTH_VIEW
;DO A CUT
	STF	R0,*+AR7(CAMERA_XYZR)
	STF	R1,*+AR7(CAMERA_XYZR+1)
	STF	R2,*+AR7(CAMERA_XYZR+2)
	STF	R3,*+AR7(CAMERA_XYZR+3)
	
SMOOTH_VIEW:
	CALL	ZOOM_CAMERA
	CALL	FACE_FRONT

	LDI	AR7,AR2
	ADDI	CAMERA_XYZR,AR2
	LDI	AR7,R2
	ADDI	NEW_MATRIX,R2
	LDI	AR7,R3
	ADDI	NEW_POSX,R3
	CALL	MATRIX_MUL

	LDF	*+AR4(OPOSX),R0
	SUBF	*+AR7(NEW_POSX),R0
	STF	R0,*+AR7(NEW_POSX)

	LDF	*+AR4(OPOSY),R0
	ADDF	*+AR7(NEW_POSY),R0
	STF	R0,*+AR7(NEW_POSY)

	LDF	*+AR4(OPOSZ),R0
	ADDF	*+AR7(NEW_POSZ),R0
	STF	R0,*+AR7(NEW_POSZ)

	LDI	*+AR4(OCARBLK),AR0
	LDI	*+AR0(CARTRAK),AR0
	LDI	*+AR0(OUSR1),R1
	CMPI	AR5,R1
	RETSLT
	LDI	0,AR5

;Put car back if it was removed
	LDI	*+AR4(OFLAGS),R0	;CHECK IF ALREADY ON LIST
	TSTB	O_LIST_M,R0
	BNZ	SMOOTH_VIEWX			;YES, DONT INSERT

	STI	AR4,*+AR7(OBJINS)
;	LDI	AR4,AR2
;	CALL	OBJ_INSERT			;INSERT PLAYER OBJECT

SMOOTH_VIEWX
	RETS

ZOOMACCEL	.float	0.006

ZOOM_CAMERA:
	LDI	*+AR7(CUT_PAN),R0
	BNE	ZOOMX
	LDF	*+AR7(ZOOMVEL),R0
	ADDF	@ZOOMACCEL,R0
	CMPF	0.2,R0
	LDFGT	0.2,R0
	STF	R0,*+AR7(ZOOMVEL)
	LDI	AR7,AR0
	ADDI	CAMERA_XYZR,AR0
	LDI	AR7,AR1
	ADDI	NEWCAMERA_XYZR,AR1
	LDI	3,RC

	RPTB	ZOOMLP
	LDF	*AR1++,R2
	SUBF	*AR0,R2
	MPYF	R0,R2
	ADDF	*AR0,R2
ZOOMLP	STF	R2,*AR0++

	LDI	*+AR7(CAMERA_VIEW),R0
	CMPI	0,R0
	BNE	ZOOM1
	ABSF	*+AR7(CAMERA_XYZR+2),R0
	CMPF	100,R0
	BGT	ZOOMX
	LDI	*+AR4(OFLAGS),R0	;CHECK IF ALREADY OFF LIST
	TSTB	O_LIST_M,R0
	BZ	ZOOMX			;YES, DONT DELETE
	LDI	AR4,AR2		;IN first person
	CALL	OBJ_PULL
	BR	ZOOMX
ZOOM1
	ABSF	*+AR7(CAMERA_XYZR+2),R0
	CMPF	100,R0
	BLT	ZOOMX
	LDI	*+AR4(OFLAGS),R0	;CHECK IF ALREADY ON LIST
	TSTB	O_LIST_M,R0
	BNZ	ZOOMX			;YES, DONT INSERT
	LDI	AR4,AR2
	CALL	OBJ_INSERT			;INSERT PLAYER OBJECT
	LDI	1,R0
	STI	R0,*+AR7(CUT_PAN)
ZOOMX
	RETS

*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
* UPDATE_CAMERA
*	INPUT	NEW_POSx/y/z,NEW_RADx/y/z,NEW_MATRIX
*	OUTPUT	_CAMERAPOS,_CAMERAMATRIX,_CAMERARAD
*
UPDATE_CAMERA:
	LDI	@_CAMERAPOSI,AR0
	LDF	*+AR7(NEW_POSX),R0
	STF	R0,*AR0
	LDF	*+AR7(NEW_POSY),R0
	STF	R0,*+AR0(Y)
	LDF	*+AR7(NEW_POSZ),R0
	STF	R0,*+AR0(Z)

	LDP	@_CAMERARAD
	LDF	*+AR7(NEW_RADX),R0
	STF	R0,@_CAMERARAD
	LDF	*+AR7(NEW_RADY),R0
	STF	R0,@_CAMERARAD+Y
	LDF	*+AR7(NEW_RADZ),R0
	STF	R0,@_CAMERARAD+Z
	SETDP

	LDI	@CAMERAMATRIXI,AR0
	LDI	AR7,AR1
	ADDI	NEW_MATRIX,AR1

	LDI	*+AR7(CUT_PAN),R0
	BEQ	SMOOTH_MATRIX

	LDI	8,RC
	RPTB	loopA
	LDF	*AR1++,R1
loopA	STF	R1,*AR0++
	BR	UPCAMX

SMOOTH_MATRIX
	LDI	8,RC
	RPTB	loop
	LDF	*AR0,R0
	MPYF	0.20,R0
	LDF	*AR1++,R1
	MPYF	0.80,R1
	ADDF	R0,R1
loop	STF	R1,*AR0++

UPCAMX
	CALL	CAMERA_HORIZON_PROJECTION
	LDI	0,R0
	STI	R0,*+AR7(CUT_PAN)		;Ok to smooth after this
	RETS


;*----------------------------------------------------------------------------
;* MOVE_CAMERA
;*
;*	INPUT CAMERA_SPEED,CAMERA_VEC
;*
;
;MOVE_CAMERA
;	LDF	@NEW_CAMERA+CAMERA_SPEED,R0
;	BEQ	no_movment
;	LDI	@NEW_CAMERAI,R2
;	ADDI	CAMERA_VECX,R2
;	LDI	@MATRIXAI,AR2
;	CALL	FIND_MATRIX
;
;	LDF	0,R0
;	STF	R0,@VECTORA
;	STF	R0,@VECTORA+1
;	LDF	@NEW_CAMERA+CAMERA_SPEED,R0
;	STF	R0,@VECTORA+2
;
;	LDI	@MATRIXAI,R2
;	LDI	@VECTORAI,AR2
;	LDI	AR2,R3
;	CALL	MATRIX_MUL
;
;	LDF	@VECTORA,R0
;	ADDF	@NEW_CAMERA+CAMERAX,R0
;	STF	R0,@NEW_CAMERA+CAMERAX
;
;	LDF	@VECTORA+1,R0
;	ADDF	@NEW_CAMERA+CAMERAY,R0
;	STF	R0,@NEW_CAMERA+CAMERAY
;
;	LDF	@VECTORA+2,R0
;	ADDF	@NEW_CAMERA+CAMERAZ,R0
;	STF	R0,@NEW_CAMERA+CAMERAZ
;no_movment
;	RETS
;
*----------------------------------------------------------------------------
CAMERA_HORIZON_PROJECTION:
	LDF	*+AR7(NEW_RADX),R2
	CALL	_SINE

	FLOAT	512,R1
	MPYF	R1,R0
	ADDF	*+AR7(CAMERA_INFIN),R0
	STF	R0,@INFIN_CORRECT

	RETS

	.SECT "THEDATA"
ATTR_WAVETAB	
 	.word	0,0
 	.word	L_LEG5_BEGIN+1,4
 	.word	L_LEG9_BEGIN+1,8
 	.word	L_LEG11_BEGIN+1,10
 	.word	0,0
 	.word	L_LEG5_BEGIN+1,4
 	.word	L_LEG9_BEGIN+1,8
 	.word	L_LEG11_BEGIN+1,10

ATTR_WAVETAB_LEN	.set $-ATTR_WAVETAB-1
	.text

INIT_ATTR_LEG:
	LDI	@ATTRWAVE,R0
	BNE	NO_MUSIC

	;Wed Mar 8 11:02:10 1995
	;
	;
	;if COMMP ON  && SLAVE then no music
	;if COMMP ON && MASTER then send_attrsnd
	;if COMMP OFF do regular
	;
	;
	LDI	@DIPRAM,R0
	TSTB	DIP_COMMP,R0
	BNZ	DOTEST
	TSTB	CMDP_MASTER,R0
	BNZ	NO_MUSIC

	CALL	SEND_ATTRSND

DOTEST
	;
	;
	;

	READADJ	ADJ_ATTRACT_MODE_SOUND
	CMPI	0,R0
	BEQ	NO_MUSIC
	SOND1	ATTR_THEME
NO_MUSIC

	LDI	MATTR|MINFIN,R0
	STI	R0,@_MODE

	LDL	press_PALETTES,AR2	;make sure these are gone
	CALL	dealloc_section

	LDI	0,R0			;NO CHALLENGE RACES IN ATTRACT MODE
	STI	R0,@CHALLENGE_RACE

	LDI	@ATTR_WAVETABI,AR1
	ADDI	@ATTRWAVE,AR1


	LDI	*AR1++,R0
	STI	R0,@NEXT_STARTUP
	LDI	*AR1,R1
	STI	R1,@BONUS_WAVE

	LDI	@BONUS_WAVE,AR0
	ADDI	@FULLSETUP_TABLEI,AR0
	LDI	*AR0,R0
	CALLU	R0

	LDF	@INFIN_CORRECT,R0
	STF	R0,*+AR7(CAMERA_INFIN)

	CALL	OBJ_INIT
	CALL	INIT_DRONES	;init DRONE tracker system
	CALL	DYNAOBJ_INIT	;init DYNAMIC OBJECTS
	CALL	CARB_INIT	;init CAR BLOCKS
	CALL	INIT_RDDEBRIS	;initialize ROAD DEBRIS list(s)

	;
	;RE INITIALIZE TRACK...
	;
	LDI	@BONUS_WAVE,AR0
	ADDI	@BONUS_POSTLAUNCHI,AR0
	LDI	*AR0,R0
	CALLU	R0

	LDI	@NEXT_STARTUP,R0
	STI	R0,@STARTSECTION
	CALL	BGD_INIT

	PUSH	AR7
	LDI	UTIL_C|BACKGRND_T,R0
	LDI	-1,R1
	CALL	PRC_FIND
	LDI	AR0,AR7
	LDI	3,R0
	STI	R0,*+AR7(PTIME)
	POP	AR7

	LDI	*+AR7(PDATA),R0
	STI	R0,@BGNDCOLA

	LDI	1,R0
	STI	R0,@NOAERASE
	CLRI	R0
	STI	R0,@OHIGH_PRIORITY

	CREATE	WAVEFLAG,UTIL_C|MONKEY_T

	CALL	ATTR_INIT_GAMELEG

	LDI	MAX_DRONES,R0
	STI	R0,@DD_MAX_DRONES

	LDI	@ATTRWAVE,R0
	ADDI	2,R0
	CMPI	ATTR_WAVETAB_LEN-1,R0
	LDIGT	0,R0
	STI	R0,@ATTRWAVE

	RETS

*----------------------------------------------------------------------------
ATTR_INIT_GAMELEG:
	CREATE	RHO_DISPATCHER,SPAWNER_C|TRAFFIC_T
	CREATE	SIGMA_DISPATCHER,SPAWNER_C|TRAFFIC_T
	CREATE	CPOINT_LIGHT,SPAWNER_C|COLORCYC_T
	CREATE	POSITION_FINDER,SPAWNER_C|TRAFFIC_T

	LDI	SM_HALT,R0
	STI	R0,@SUSPEND_MODE

	LDI	0,R4
	CREATE	RACER_DRONE,DRONE_C
	LDI	1,R4
	CREATE	RACER_DRONE,DRONE_C

	LDI	2,R4
	CREATE	RACER_DRONE,DRONE_C

	LDI	3,R4
	CREATE	RACER_DRONE,DRONE_C

	LDI	4,R4
	CREATE	RACER_DRONE,DRONE_C
	STI	AR0,@PLYCAR

	LDI	5,R4
	CREATE	RACER_DRONE,DRONE_C

	LDI	6,R4
	CREATE	RACER_DRONE,DRONE_C
	LDI	7,R4
	CREATE	RACER_DRONE,DRONE_C

	LDI	9,R4
	CREATE	RACER_DRONE,DRONE_C

	RETS
;*----------------------------------------------------------------------------
;
LOAD_ATTR_LEG:
	LDI	@ATTRWAVE,AR0
	ADDI	@ATTR_WAVETABI,AR0
	LDI	*+AR0(1),AR0

	.if DEBUG
	CMPI	0,AR0
	LDILT	0,AR0
	CMPI	13,AR0
	LDIGT	13,AR0
	.endif

	ADDI	@LOADSECTION_TABLEI,AR0
	LDI	*AR0,R0
	CALLU	R0
	RETS

*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*OLD CODE THAT I DEARLY LIKE TO REFFERENCE

;*----------------------------------------------------------------------------
;*TURN CAMERA TO FOLLOW OBJECT IN AR4
;*
;*PARAMETERS
;*	AR4	OBJECT TO 'WATCH'
;*
;WATCH_OBJ:
;	LDF	*+AR4(OPOSX),R2
;	SUBF	@NEW_CAMERA+CAMERAX,R2
;	LDF	*+AR4(OPOSZ),R3
;	SUBF	@NEW_CAMERA+CAMERAZ,R3
;	CALL	ARCTANF
;	SUBF	HALFPI,R0
;
;	NEGF	R0,R2
;	STF	R2,@NEW_CAMERA+CAMERARADY
;
;	LDF	*+AR4(OPOSZ),R0
;	SUBF	@NEW_CAMERA+CAMERAZ,R0
;	MPYF	R0,R0
;	LDF	*+AR4(OPOSX),R1
;	SUBF	@NEW_CAMERA+CAMERAX,R1
;	MPYF	R1,R1
;	ADDF3	R0,R1,R2	;R= SQRT (X^2 + Z^2)
;	CALL	SQRT
;	LDF	R0,R3
;
;	LDF	*+AR4(OPOSY),R2
;	SUBF	@NEW_CAMERA+CAMERAY,R2
;
;	CALL	ARCTANF
;
;	SUBF	HALFPI,R0
;
;	STF	R0,@NEW_CAMERA+CAMERARADX
;
;	LDI	@NEW_CAMERAI,R2
;	ADDI	CAMERARADX,R2
;	LDI	@NEW_CAMERAI,AR2
;	ADDI	CAMERA_MATRIX,AR2
;	CALL	FIND_MATRIX
;
;	CAll	CAMERA_HORIZON_PROJECTION
;
;	RETS
;*----------------------------------------------------------------------------
;INITFLYBY_VIEW:
;	LDI	-1,R0
;	STI	R0,*+AR7(CUT_PAN)
;
;	FLOAT	-4300,R0
;	STF	R0,@NEW_CAMERA+CAMERA_SPEED
;
;FLYBY_VIEW:
;	LDF	@NEW_CAMERA+CAMERA_SPEED,R0
;	FLOAT	150,R1
;	ADDF	R1,R0
;	STF	R0,@NEW_CAMERA+CAMERA_SPEED
;
;	LDF	*+AR4(OPOSY),R0
;	STF	R0,@NEW_CAMERA+CAMERAY
;
;	LDF	*+AR4(ORADY),R2
;	ADDF	-1.54,R2
;	CALL	_SINE
;	FLOAT	500,R2
;	MPYF	R0,R2
;	LDF	*+AR4(OPOSX),R0
;	ADDF	R2,R0
;	STF	R0,@NEW_CAMERA+CAMERAX
;
;	LDF	*+AR4(ORADY),R2
;	ADDF	-1.54,R2
;	CALL	_COSI
;	FLOAT	500,R2
;	MPYF	R0,R2
;	LDF	*+AR4(OPOSZ),R0
;	ADDF	R2,R0
;	STF	R0,@NEW_CAMERA+CAMERAZ
;
;	LDF	*+AR4(ORADY),R0
;	SUBF	0.10,R0
;	STF	R0,@NEW_CAMERA+CAMERA_VECY
;
;	LDF	0.3,R0
;	STF	R0,@NEW_CAMERA+CAMERA_VECX
;
;	LDF	*+AR4(ORADZ),R0
;	STF	R0,@NEW_CAMERA+CAMERA_VECZ
;
;	CALL	MOVE_CAMERA
;
;	LDF	*+AR4(OPOSY),R0
;	FLOAT	-1500,R1			;FIX ELEVATION
;	ADDF	R1,R0
;	STF	R0,@NEW_CAMERA+CAMERAY
;passed
;	CALL	WATCH_OBJ
;
;	RETS

 	.END
