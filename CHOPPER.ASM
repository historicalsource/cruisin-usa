	.FILE	"CHOPPER.ASM"
*----------------------------------------------------------------------------
*CHOPPER IN THE SKY
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
	.include	DELTA.EQU

	.bss	HELI_ABORT,1	;P	abort chopper routine?

*
*	!!!!NO JSRPing!!!!
*

*LOCALS  (AFTER DELTA EQUATES)
CD_ANIPROC	.set	PDATA+18
CD_MODE		.set	PDATA+19
CD_ACC		.set	PDATA+20	;acceleration
CD_SPEED	.set	PDATA+21	;current speed
CD_BOMBTIK	.set	PDATA+22	;bomb pause
CD_TSPEED	.set	PDATA+23	;true speed (x/y/z)
CD_TSPEED_OLD	.set	PDATA+24	;old true speed (x/y/z)
CD_FLYTDIR	.set	PDATA+25	;breakaway theta
CD_DHEIGHT	.set	PDATA+26	;FL desired height value
CD_ODHEIGHT	.set	PDATA+27	;FL old desired height value
CD_CLOSEROAD	.set	PDATA+28	;UD closest road object
CD_AHEADP	.set	PDATA+29	;UD	flag ahead of player?
CD_PASS_COUNT	.set	PDATA+30
CD_BOMB_COUNT	.set	PDATA+31
CD_MAX_PASSES	.set	PDATA+32
CD_MAX_BOMBS	.set	PDATA+33
CD_LASTPASS	.set	PDATA+34	;P
CD_DOATTACK	.set	PDATA+35	;P
*NO MORE UNLESS NOT JSRPing

*CHOPPER MODE
CM_CU		.set	1		;CATCH UP
CM_DB		.set	2		;DROP BOMBS
CM_FA		.set	3		;FLY AWAY

CRADZ	.set	OUSR1

MAX_SPEED	.set	667		;about 180 mph

*----------------------------------------------------------------------------
CHOPPERDYNA
	.word	1		;#OF DYNAS-1

	.float	0,-206,14	;blades
	.word	3		;VERTS-1
	.word	1		;DYNAFLAG

	.float	0,0,0		;main body
	.word	94		;VERTS-1
	.word	1		;DYNAFLAG
*----------------------------------------------------------------------------



*---------------------------------------------------------------------------
*
*go straight for the plyrs car
*
*(already close by)
*branched to from oncoming buzz
*
*
DIRECT_ATTACK:

	;
	;DEBUG	only attack player when he is in the first position
	;
	LDI	@POSITION,R0
	CMPI	1,R0
	BNE	FLYAWAY
	;
	;


	CALL	DIST_TO_PLYR
	LDF	*+AR7(DELTA_PLYRDIST),R1
	STF	R0,*+AR7(DELTA_PLYRDIST)
	STF	R1,*+AR7(DELTA_OPLYRDIST)


	CALL	HELI_SND

	;see if we should track the next piece
CHECK_DIST28:
	LDI	*+AR7(DELTA_LAST_OID),R0	;CHECK TO SEE IF IT IS IN THE RANGE
	RS	8,R0
	LDI	@SECTIONIDX,R1
	SUBPI	@DGROUP_COUNT,R1
	CMPI	R1,R0
	BLE	FLYAWAY		;CHOPPER_DIE


	LDI	*+AR7(DELTA_TPIECE),AR2
	LDI	*+AR2(OBLINK4),R0
	BZ	FLYAWAY	;CHOPPER_DIE

	LDI	@PLYCBLK,AR2
	LDF	*+AR2(CARDIST2CNTR),R0
	STF	R0,*+AR7(DELTA_XLANE)

	CALL	GET_TRACK_POS_RVS_XLANE		;CHECK IF WE SHOULD ADVANCE 
	FLOAT	5000,R1				;TO THE NEXT ROADPIECE
	CMPF	R1,R0
	BGT	THIS_PIECE28

	LDI	*+AR7(DELTA_TPIECE),AR2
	LDI	*+AR2(OBLINK4),R0
	STI	R0,*+AR7(DELTA_TPIECE)
	LDI	R0,AR0
	LDI	*+AR0(OUSR1),R0
	STI	R0,*+AR7(DELTA_LAST_OID)	;SAVE THE LAST KNOWN VALID OID
	BU	CHECK_DIST28
THIS_PIECE28


	FLOATP	@NFRAMES,R1
	MPYF	*+AR7(CD_TSPEED),R1
	LDFLE	30,R1			;if 0 or less assume 30 voxel per frame
	CALL	DIV_F			;R0/R1 (distance to piece/speed) -> # frames to achieve
	FIX	R0,R7

	LDI	*+AR7(DELTA_TPIECE),AR2
	LDP	@_VECTORA		;lane position
	LDF	*+AR2(OPOSX),R2		;X
	SUBF	*+AR4(OPOSX),R2
	ADDF	@_VECTORA+X,R2
	LDF	*+AR2(OPOSZ),R3		;Z
	SUBF	*+AR4(OPOSZ),R3
	ADDF	@_VECTORA+Z,R3
	SETDP



	;find the theta delta to this position
	;
	CALL	ARCTANF			;-> R0
	SUBF	HALFPI,R0		;R0	DESIRED THETA (float)

 	LDF	*+AR4(ORADY),R2		;R2	CURRENT THETA
	CALL	GETTHETADIFF		;->R0	THETA DELTA (float)
	FLOAT	R7,R1			;theta / number of turns to achieve
	SUBF	1,R1
	BLE	NODIV8
	CALL	DIV_F			;-> R0
NODIV8
	CMPF	0.3926,R0		;PI/8 (maximum turning radius)
	LDFGT	0.3926,R0
	CMPF	-0.3926,R0
	LDFLT	-0.3926,R0
	STF	R0,*+AR7(DELTA_RADYDELTA)


	PUSH	AR4
	ADDI	OPOSX,AR4
	CALL	CAMSCAN
	POP	AR4
	BNC	LLK28

	NEGF	R0
	FLOAT	-300,R1
	SUBF	R1,R0
	NEGF	R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR7(CD_DHEIGHT)
LLK28

	LDF	*+AR7(CD_SPEED),R0
	ADDF	*+AR7(CD_ACC),R0
	FLOAT	MAX_SPEED,R1
	CMPF	R1,R0
	LDFGT	R1,R0
	STF	R0,*+AR7(CD_SPEED)

	LDF	*+AR7(DELTA_RADYDELTA),R2
	LDF	*+AR7(CD_SPEED),R3
	CALL	FSL_MOVE

	SLEEP	1
	BU	DIRECT_ATTACK
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*Take the helicopter, and buzz (@ 200 MPH) right over the players car
*exit when start of the world is hit
*
*
*
ONCOMMING_BUZZ:
	LDF	0,R0
	STF	R0,*+AR4(ORADX)
	STF	R0,*+AR4(ORADY)
	STF	R0,*+AR4(CRADZ)

	STF	R0,*+AR4(OVELX)
	STF	R0,*+AR4(OVELY)
	STF	R0,*+AR4(OVELZ)


	;
	;find where player is

	LDI	@PLYCBLK,AR2
	LDF	*+AR2(CARDIST2CNTR),R0
	STF	R0,*+AR7(DELTA_XLANE)

	LDI	@DYNALIST_END,AR2
	LDI	*+AR2(OBLINK4),AR2
	LDI	*+AR2(OBLINK4),AR2
	STI	AR2,*+AR7(DELTA_TPIECE)
	LDI	*+AR2(OUSR1),R0
	STI	R0,*+AR7(DELTA_LAST_OID)
	CALL	SUB_FUNCTION_RVS_XLANE		;MATRIXA,VECTORA,R2

	LDP	@_VECTORA
	LDF	*+AR2(OPOSX),R0
	ADDF	@_VECTORA+X,R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR2(OPOSY),R0
	FLOAT	1000,R1
	SUBF	R1,R0
	ADDF	@_VECTORA+Y,R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR2(OPOSZ),R0
	ADDF	@_VECTORA+Z,R0
	STF	R0,*+AR4(OPOSZ)
	SETDP


	;initialize Ytheta to the intentional direction
	STF	R2,*+AR4(ORADY)
	STF	R2,*+AR7(DELTA_RADYDELTA)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX


ONBUZZ_L

	CALL	DIST_TO_PLYR
	LDF	*+AR7(DELTA_PLYRDIST),R1
	STF	R0,*+AR7(DELTA_PLYRDIST)
	STF	R1,*+AR7(DELTA_OPLYRDIST)


	FLOAT	22000,R2
	CMPF	R2,R0
	BLE	FLYAWAY

	CALL	HELI_SND


	;see if we should track the next piece
CHECK_DIST2:
	LDI	*+AR7(DELTA_LAST_OID),R0	;CHECK TO SEE IF IT IS IN THE RANGE
	RS	8,R0
	LDI	@SECTIONIDX,R1
	SUBPI	@DGROUP_COUNT,R1
	CMPI	R1,R0
	BLE	CHOPPER_DIE


	LDI	*+AR7(DELTA_TPIECE),AR2
	LDI	*+AR2(OBLINK4),R0
	BZ	CHOPPER_DIE

	LDI	@PLYCBLK,AR2
	LDF	*+AR2(CARDIST2CNTR),R0
	STF	R0,*+AR7(DELTA_XLANE)

	CALL	GET_TRACK_POS_RVS_XLANE		;CHECK IF WE SHOULD ADVANCE 
	FLOAT	5000,R1				;TO THE NEXT ROADPIECE
	CMPF	R1,R0
	BGT	THIS_PIECE2

	LDI	*+AR7(DELTA_TPIECE),AR2
	LDI	*+AR2(OBLINK4),R0
	STI	R0,*+AR7(DELTA_TPIECE)
	LDI	R0,AR0
	LDI	*+AR0(OUSR1),R0
	STI	R0,*+AR7(DELTA_LAST_OID)	;SAVE THE LAST KNOWN VALID OID
	BU	CHECK_DIST2
THIS_PIECE2


	FLOATP	@NFRAMES,R1
	MPYF	*+AR7(CD_TSPEED),R1
	LDFLE	30,R1			;if 0 or less assume 30 voxel per frame
	CALL	DIV_F			;R0/R1 (distance to piece/speed) -> # frames to achieve
	FIX	R0,R7

	LDI	*+AR7(DELTA_TPIECE),AR2
	LDP	@_VECTORA		;lane position
	LDF	*+AR2(OPOSX),R2		;X
	SUBF	*+AR4(OPOSX),R2
	ADDF	@_VECTORA+X,R2
	LDF	*+AR2(OPOSZ),R3		;Z
	SUBF	*+AR4(OPOSZ),R3
	ADDF	@_VECTORA+Z,R3
	SETDP



	;find the theta delta to this position
	;
	CALL	ARCTANF			;-> R0
	SUBF	HALFPI,R0		;R0	DESIRED THETA (float)

 	LDF	*+AR4(ORADY),R2		;R2	CURRENT THETA
	CALL	GETTHETADIFF		;->R0	THETA DELTA (float)
	FLOAT	R7,R1			;theta / number of turns to achieve
	SUBF	1,R1
	BLE	NODIV
	CALL	DIV_F			;-> R0
NODIV
	CMPF	0.3926,R0		;PI/8 (maximum turning radius)
	LDFGT	0.3926,R0
	CMPF	-0.3926,R0
	LDFLT	-0.3926,R0
	STF	R0,*+AR7(DELTA_RADYDELTA)



	PUSH	AR4
	ADDI	OPOSX,AR4
	CALL	CAMSCAN
	POP	AR4
	BNC	LLK2

	NEGF	R0
	FLOAT	-1300,R1
	SUBF	R1,R0
	NEGF	R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR7(CD_DHEIGHT)
LLK2

	LDF	*+AR7(CD_SPEED),R0
	ADDF	*+AR7(CD_ACC),R0
	FLOAT	MAX_SPEED,R1
	CMPF	R1,R0
	LDFGT	R1,R0
	STF	R0,*+AR7(CD_SPEED)

	LDF	*+AR7(DELTA_RADYDELTA),R2
	LDF	*+AR7(CD_SPEED),R3
	CALL	FSL_MOVE

	SLEEP	1
	BU	ONBUZZ_L
*----------------------------------------------------------------------------


;
;*----------------------------------------------------------------------------
;*
;*
;*
;*
;CIRCLE_BUZZ:
;	LDF	0,R0
;	STF	R0,*+AR4(ORADX)
;	STF	R0,*+AR4(ORADY)
;	STF	R0,*+AR4(CRADZ)
;
;	STF	R0,*+AR4(OVELX)
;	STF	R0,*+AR4(OVELY)
;	STF	R0,*+AR4(OVELZ)
;
;
;	;
;	;find where player is
;
;	LDI	@PLYCBLK,AR2
;	NEGF	*+AR2(CARDIST2CNTR),R0
;	STF	R0,*+AR7(DELTA_XLANE)
;	LDI	*+AR2(CARTRAK),AR2
;	LDI	*+AR2(OBLINK4),AR2
;
;	STI	AR2,*+AR7(DELTA_TPIECE)
;	LDI	*+AR2(OUSR1),R0
;	STI	R0,*+AR7(DELTA_LAST_OID)
;	CALL	DELTA_SUB_FUNCTION			;MATRIXA,VECTORA,R2
;
;	LDP	@_VECTORA
;	LDF	*+AR2(OPOSX),R0
;	ADDF	@_VECTORA+X,R0
;	STF	R0,*+AR4(OPOSX)
;	LDF	*+AR2(OPOSY),R0
;	FLOAT	1000,R1
;	SUBF	R1,R0
;	ADDF	@_VECTORA+Y,R0
;	STF	R0,*+AR4(OPOSY)
;	LDF	*+AR2(OPOSZ),R0
;	ADDF	@_VECTORA+Z,R0
;	STF	R0,*+AR4(OPOSZ)
;	SETDP
;
;
;	;initialize Ytheta to the intentional direction
;	STF	R2,*+AR4(ORADY)
;	STF	R2,*+AR7(DELTA_RADYDELTA)
;
;	LDI	AR4,AR2
;	ADDI	OMATRIX,AR2
;	CALL	FIND_YMATRIX
;
;
;CIRCLE_JOIN
;	CLRF	R6
;	LDI	@CIRCLE_SI,AR5
;
;CIRCL_L
;	LDI	@PLYCBLK,AR0
;	LDF	*+AR0(CARSPEED),R0
;	CMPF	40,R0
;	BLT	ISOK55
;	RETP
;ISOK55
;
;	
;	CALL	DIST_TO_PLYR
;	LDF	*+AR7(DELTA_PLYRDIST),R1
;	STF	R0,*+AR7(DELTA_PLYRDIST)
;	STF	R1,*+AR7(DELTA_OPLYRDIST)
;
;	CALL	HELI_SND
;
;	.data
;CIRCLE_SI	.word	CIRCLE_S
;CIRCLE_S ;	X,Z
;	.float	4000,2200
;	.float	2500,5000
;	.float	0,9000
;	.float	-2500,5000
;	.float	-4000,2200
;	.float	-1
;	.text
;
;
;JKKU
;	LDI	@PLYCBLK,AR2
;	LDI	*+AR2(CARTRAK),AR2
;	LDI	*+AR2(OLINK4),AR0
;	LDF	*+AR0(OPOSX),R2
;	SUBF	*+AR2(OPOSX),R2
;	LDF	*+AR0(OPOSZ),R3
;	SUBF	*+AR2(OPOSZ),R3
;	CALL	ARCTANF
;	SUBF	HALFPI,R0
;	LDF	R0,R2				;FIND THETA
;	LDI	@MATRIXAI,AR2
;	CALL	FIND_YMATRIX
;
;
;	CALL	CLR_VECTORA
;	LDF	*AR5,R4
;	LDF	*+AR5(1),R5
;	STF	R4,*+AR2(X)
;	STF	R5,*+AR2(Z)
;
;
;	LDI	@MATRIXAI,R2
;	LDI	AR2,R3
;	CALL	MATRIX_MUL
;
;
;	LDI	@PLYCAR,AR3
;	LDF	*+AR3(OPOSX),R4
;	ADDF	*+AR2(X),R4
;	LDF	*+AR3(OPOSZ),R5
;	ADDF	*+AR2(Z),R5		;R4,R5 contains X/Z position
;
;
;	LDF	*+AR4(OPOSX),R2
;	SUBF	R4,R2
;	MPYF	R2,R2
;	LDF	*+AR4(OPOSZ),R1
;	SUBF	R5,R1
;	ADDF	R1,R2
;	CALL	SQRT			;R0 <- distance to new position
;
;
;	FLOAT	2000,R1
;	CMPF	R1,R0
;	BGT	KKK
;	LDF	*++AR5(2),R0
;	CMPF	-1,R0
;	BNE	JKKU
;	LDI	@CIRCLE_SI,AR5
;	BU	JKKU
;KKK
;
;
;
;	PUSHF	R4
;	PUSHF	R5
;
;	FLOAT	@NFRAMES,R1
;	MPYF	*+AR7(CD_TSPEED),R1
;	LDFLE	30,R1			;if 0 or less assume 30 voxel per frame
;	CALL	DIV_F			;R0/R1 (distance to piece/speed) -> # frames to achieve
;	FIX	R0,R7
;
;	POPF	R5
;	POPF	R4
;
;	LDF	R4,R2			;X
;	SUBF	*+AR4(OPOSX),R2
;	LDF	R5,R3			;Z
;	SUBF	*+AR4(OPOSZ),R3
;
;
;
;	;find the theta delta to this position
;	;
;	CALL	ARCTANF			;-> R0
;	SUBF	HALFPI,R0		;R0	DESIRED THETA (float)
;
; 	LDF	*+AR4(ORADY),R2		;R2	CURRENT THETA
;	CALL	GETTHETADIFF		;->R0	THETA DELTA (float)
;	FLOAT	R7,R1			;theta / number of turns to achieve
;	SUBF	1,R1
;	BLE	NODIV3
;	CALL	DIV_F			;-> R0
;NODIV3
;	CMPF	0.06926,R0		;PI/8 (maximum turning radius)
;	LDFGT	0.06926,R0
;	CMPF	-0.06926,R0
;	LDFLT	-0.06926,R0
;	STF	R0,*+AR7(DELTA_RADYDELTA)
;
;
;	PUSH	AR4
;	ADDI	OPOSX,AR4
;	CALL	CAMSCAN
;	POP	AR4
;	BNC	LLK23
;
;	NEGF	R0
;	FLOAT	-1300,R1
;	SUBF	R1,R0
;	NEGF	R0
;	ADDF	*+AR4(OPOSY),R0
;	STF	R0,*+AR7(CD_DHEIGHT)
;LLK23
;
;
;	LDF	*+AR7(CD_SPEED),R3
;	ADDF	*+AR7(CD_ACC),R3
;
;	FLOAT	300,R1			;MAX speed
;
;	CMPF	R1,R3
;	LDFGT	R1,R3
;	STF	R3,*+AR7(CD_SPEED)
;
;
;
;	LDF	*+AR7(DELTA_RADYDELTA),R2
;	CALL	FSL_MOVE
;
;
;	SLEEP	1
;	BU	CIRCL_L
;*----------------------------------------------------------------------------
;


*----------------------------------------------------------------------------
*CHOPPER SEQUENCE:
*
*
*	come from behind and overhead and zoom ahead of player
*	rotate tilted forward (moving with player)
*	radio noise and such 
*	zoom off to left or right
*	pull obj and sleep for awhile
*	reinsert objects and redo sequence
*
*
*
*
CHOPPER:
	;BEGIN INITIALIZATION CODE
	;
	LDI	@(_plyr1+PLY_PROC),AR2	;FIRST SETUP THAT WE FOLLOW THE PLAYERS PROC
	CALL	PRC_FOLLOW

	CALL	OBJ_GET
	BC	SUICIDE

	LDI	AR0,AR4
	LDIL	helli,R0
	STI	R0,*+AR4(OROMDATA)
	CLRF	R0
	STF	R0,*+AR4(OPOSX)
	FLOAT	-20,R0
	STF	R0,*+AR4(OPOSY)
	FLOAT	3500,R0
	STF	R0,*+AR4(OPOSZ)

	LDI	AR4,AR2
	CALL	OBJ_INSERT

	CALL	_CARV0
	LDI	*+AR4(OCARBLK),AR5


	CALL	SETDYNAOBJ

	LDF	0,R2
	STF	R2,*+AR4(ORADX)
	STF	R2,*+AR4(ORADY)
	STF	R2,*+AR4(CRADZ)
	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX

	CLRI	R0
	STI	R0,*+AR7(CD_PASS_COUNT)
	STI	R0,*+AR7(CD_BOMB_COUNT)

	LDI	DRONE_C|HELICOPTER,R0
	STI	R0,*+AR4(OID)
	STI	R0,*+AR7(PID)
	STI	AR7,*+AR4(OPLINK)


	RANDN	2
	ADDI	1,R0
	STI	R0,*+AR7(CD_MAX_PASSES)

	CLRI	R0
	STI	R0,*+AR7(CD_DOATTACK)
	;
	;END OF INITIALIZATION CODE

	CLRI	R0
	STI	R0,*+AR7(CD_LASTPASS)


	;what type of pass to make?
CHOPPER_PASS:
	LDI	@HELI_ABORT,R0
	BNZ	CHOPPER_DIE

	LDI	*+AR7(CD_LASTPASS),R0
	BNZ	CHOPPER_DIE

	LDI	*+AR7(CD_PASS_COUNT),R0
	INC	R0
	CMPI	*+AR7(CD_MAX_PASSES),R0
	BGT	DOTHEMOVE
	STI	R0,*+AR7(CD_PASS_COUNT)

	BU	ONCOMMING_BUZZ
DOTHEMOVE

	LDI	1,R0
	STI	R0,*+AR7(CD_LASTPASS)

	RANDN	2
	STI	R0,*+AR7(CD_DOATTACK)
	LDI	R0,R0
	BNZ	ONCOMMING_BUZZ



FORWARD_BUZZ:
	;FORWARD BUZZ INIT. CODE
	;
	RANDN	20
	ADDI	20,R0
	STI	R0,*+AR7(CD_MAX_BOMBS)




	LDF	0,R0
	STF	R0,*+AR4(ORADX)
	STF	R0,*+AR4(ORADY)
	STF	R0,*+AR4(CRADZ)

	STF	R0,*+AR4(OVELX)
	STF	R0,*+AR4(OVELY)
	STF	R0,*+AR4(OVELZ)


	;
	;find where player is

	LDI	@PLYCBLK,AR2
	NEGF	*+AR2(CARDIST2CNTR),R0
	STF	R0,*+AR7(DELTA_XLANE)
	LDI	*+AR2(CARTRAK),AR2
	LDI	*+AR2(OBLINK4),AR2

	STI	AR2,*+AR7(DELTA_TPIECE)
	LDI	*+AR2(OUSR1),R0
	STI	R0,*+AR7(DELTA_LAST_OID)
	CALL	DELTA_SUB_FUNCTION			;MATRIXA,VECTORA,R2

	LDP	@_VECTORA
	LDF	*+AR2(OPOSX),R0
	ADDF	@_VECTORA+X,R0
	STF	R0,*+AR4(OPOSX)
	LDF	*+AR2(OPOSY),R0
	FLOAT	1000,R1
	SUBF	R1,R0
	ADDF	@_VECTORA+Y,R0
	STF	R0,*+AR4(OPOSY)
	LDF	*+AR2(OPOSZ),R0
	ADDF	@_VECTORA+Z,R0
	STF	R0,*+AR4(OPOSZ)
	SETDP


	;initialize Ytheta to the intentional direction
	STF	R2,*+AR4(ORADY)
	STF	R2,*+AR7(DELTA_RADYDELTA)

	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX


	FLOAT	60,R0
	STF	R0,*+AR7(CD_ACC)
	LDI	0,R0
	STI	R0,*+AR7(CD_BOMBTIK)

	LDI	CM_DB,R0
	STI	R0,*+AR7(CD_MODE)
	;
	;END FORWARD BUZZ INIT. CODE


CHOPPER_L:	;FORWARD BUZZ LOOP
	LDI	@HELI_ABORT,R0
	BNZ	FLYAWAY

	LDI	@PLYCBLK,AR2
	NEGF	*+AR2(CARDIST2CNTR),R0
	STF	R0,*+AR7(DELTA_XLANE)

;	LDF	*+AR2(CARSPEED),R1
;	CMPF	60,R1
;	BGT	NOCIRC
;	JSRP	CIRCLE_JOIN
;NOCIRC


	CALL	DIST_TO_PLYR
	LDF	*+AR7(DELTA_PLYRDIST),R1
	STF	R0,*+AR7(DELTA_PLYRDIST)
	STF	R1,*+AR7(DELTA_OPLYRDIST)

	FLOAT	10000,R2
	CMPF	R2,R0
	BGT	FLYAWAY

	CALL	HELI_SND


	;see if we should track the next piece
CHECK_DIST:
	LDI	*+AR7(DELTA_LAST_OID),R0	;CHECK TO SEE IF IT IS IN THE RANGE
	RS	8,R0
	LDI	@SECTIONIDX,R1
	SUBI	@DGROUP_COUNT,R1
	CMPI	R1,R0
	BLE	CHOPPER_DIE


	LDI	*+AR7(DELTA_TPIECE),AR2
	LDI	*+AR2(OLINK4),R0
	BZ	CHOPPER_SLP


	;old xlane determination code position

	CALL	DELTA_GET_TRACK_POS		;CHECK IF WE SHOULD ADVANCE 
	FLOAT	5000,R1				;TO THE NEXT ROADPIECE
	CMPF	R1,R0
	BGT	THIS_PIECE

	LDI	*+AR7(DELTA_TPIECE),AR2
	LDI	*+AR2(OLINK4),R0
	STI	R0,*+AR7(DELTA_TPIECE)
	LDI	R0,AR0
	LDI	*+AR0(OUSR1),R0
	STI	R0,*+AR7(DELTA_LAST_OID)	;SAVE THE LAST KNOWN VALID OID
	BU	CHECK_DIST
THIS_PIECE




	FLOAT	@NFRAMES,R1
	MPYF	*+AR7(CD_TSPEED),R1
	LDFLE	30,R1			;if 0 or less assume 30 voxel per frame
	CALL	DIV_F			;R0/R1 (distance to piece/speed) -> # frames to achieve
	FIX	R0,R7

	LDI	*+AR7(DELTA_TPIECE),AR2
	LDP	@_VECTORA		;lane position
	LDF	*+AR2(OPOSX),R2		;X
	SUBF	*+AR4(OPOSX),R2
	ADDF	@_VECTORA+X,R2
	LDF	*+AR2(OPOSZ),R3		;Z
	SUBF	*+AR4(OPOSZ),R3
	ADDF	@_VECTORA+Z,R3
	SETDP



	;find the theta delta to this position
	;
	CALL	ARCTANF			;-> R0
	SUBF	HALFPI,R0		;R0	DESIRED THETA (float)

 	LDF	*+AR4(ORADY),R2		;R2	CURRENT THETA
	CALL	GETTHETADIFF		;->R0	THETA DELTA (float)
	FLOAT	R7,R1			;theta / number of turns to achieve
	SUBF	1,R1
	BLE	NODIV2
	CALL	DIV_F			;-> R0
NODIV2
	CMPF	0.3926,R0		;PI/8 (maximum turning radius)
	LDFGT	0.3926,R0
	CMPF	-0.3926,R0
	LDFLT	-0.3926,R0
	STF	R0,*+AR7(DELTA_RADYDELTA)



	CALL	GET_CLOSEST_TRAK
	STI	AR0,*+AR7(CD_CLOSEROAD)


	LDF	*+AR7(CD_ODHEIGHT),R0
	STF	R0,*+AR7(CD_DHEIGHT)

	LDI	*+AR7(CD_CLOSEROAD),AR0
	FIX	*+AR0(OPOSY),R0
	SUBI	1300,R0
	FLOAT	R0
	STF	R0,*+AR7(CD_DHEIGHT)

	

	LDI	*+AR7(CD_CLOSEROAD),AR0
	LDI	*+AR0(OUSR1),R0
	LDI	@PLYCBLK,AR1
	LDI	*+AR1(CARTRAK),AR2
	LDI	*+AR2(OUSR1),R1
	CMPI	R1,R0
	BLT	ISBEND
	BGT	ISAHED

	;tied case, must be exact
	;
	LDI	*+AR2(OLINK4),AR2
	LDI	@PLYCAR,AR0
	LDF	*+AR0(OPOSX),R0
	SUBF	*+AR2(OPOSX),R0
	MPYF	R0,R0
	LDF	*+AR0(OPOSZ),R1
	SUBF	*+AR2(OPOSZ),R1
	MPYF	R1,R1
	ADDF	R1,R0

	LDF	*+AR4(OPOSX),R2
	SUBF	*+AR2(OPOSX),R2
	MPYF	R2,R2
	LDF	*+AR4(OPOSZ),R1
	SUBF	*+AR2(OPOSZ),R1
	MPYF	R1,R1
	ADDF	R2,R1

	CMPF	R0,R1
	BGT	ISBEND



ISAHED	;is ahead of
	LDI	1,R0
	STI	R0,*+AR7(CD_AHEADP)

	LDF	*+AR7(DELTA_PLYRDIST),R1
	FLOAT	1750,R2
	CMPF	R2,R1
	BLT	LITTLE

	LDF	*+AR7(CD_SPEED),R0

	LDF	R0,R2
	MPYF	1.1,R2
	LDF	*+AR1(CARSPEED),R1
	ADDF	*+AR7(CD_ACC),R0
	MPYF	1.5,R1
	CMPF	R1,R0
	LDFGT	R1,R0

	CMPF	R2,R0				;never rad change on our vel.
	LDFGT	R2,R0

	STF	R0,*+AR7(CD_SPEED)
	BU	L88

ISBEND
	CLRI	R0
	STI	R0,*+AR7(CD_AHEADP)

	LDF	*+AR7(DELTA_PLYRDIST),R1
	FLOAT	3500,R2
	CMPF	R2,R1
	BLT	LITTLE

	LDF	*+AR1(CARSPEED),R0
	MPYF	3,R0
	FLOAT	600,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR7(CD_SPEED)
	BU	L88

LITTLE
	LDF	*+AR7(CD_SPEED),R2
	MPYF	1.1,R2

	LDF	*+AR1(CARSPEED),R0
	MPYF	2.0,R0
	FLOAT	500,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	CMPF	R2,R0
	LDFGT	R2,R0
	STF	R0,*+AR7(CD_SPEED)

L88	LDF	*+AR7(DELTA_RADYDELTA),R2
	LDF	*+AR7(CD_SPEED),R3
	CALL	FSL_MOVE





	LDI	*+AR7(CD_MODE),R4
	CMPI	CM_DB,R4
	BNE	NO_BOMBS


	LDI	*+AR7(CD_BOMBTIK),R0
	DEC	R0
	STI	R0,*+AR7(CD_BOMBTIK)
	BGT	NO_BOMBS

	LDI	*+AR7(CD_AHEADP),R0
	BZ	NO_BOMBS



	LDI	@POSITION,R0
	CMPI	1,R0
	BNE	FLYAWAY



	FLOAT	2300,R0
	CMPF	*+AR7(DELTA_PLYRDIST),R0
	BGT	NO_BOMBS


	RANDN	10
	ADDI	10,R0
	STI	R0,*+AR7(CD_BOMBTIK)
	LDI	R0,R4


	LDI	*+AR7(CD_BOMB_COUNT),R0
	INC	R0
	CMPI	*+AR7(CD_MAX_BOMBS),R0
	BGT	FLYAWAY		;NO_BOMBS
	STI	R0,*+AR7(CD_BOMB_COUNT)

;	CREATE	BOMB_PROC,3434
NO_BOMBS


CHOPPER_SLP
	SLEEP	1
	B	CHOPPER_L
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FLYAWAY:
	CLRI	AR6			;flag
	LDI	100,AR5
	LDF	-10,R7


	LDF	0.015,R0
	CALL	SFRAND
	LDF	R0,R0
	BLT	KKII
	ADDF	0.01,R0
	BU	KKUU
KKII	SUBF	0.01,R0
KKUU	STF	R0,*+AR7(CD_FLYTDIR)



FLYAWAY_LP
	CALL	DIST_TO_PLYR
	STF	R0,*+AR7(DELTA_PLYRDIST)

	CALL	HELI_SND


	SUBF	3,R7
	CMPF	-95,R7
	LDFLT	-95,R7

	LDF	*+AR7(CD_DHEIGHT),R1
	ADDF	R7,R1
	STF	R1,*+AR7(CD_DHEIGHT)


	LDF	*+AR7(CD_SPEED),R0
	ADDF	*+AR7(CD_ACC),R0
	FLOAT	MAX_SPEED,R1
	CMPF	R1,R0
	LDFGT	R1,R0
	STF	R0,*+AR7(CD_SPEED)
	LDF	*+AR7(CD_SPEED),R3

	LDF	*+AR7(CD_FLYTDIR),R2
	CALL	FSL_MOVE

	SLEEP	1
	DBU	AR5,FLYAWAY_LP
	BU	CHOPPER_PASS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CHOPPER_DIE:
	LDI	*+AR4(OCARBLK),AR2
	CALL	DELCAR

	LDI	AR4,AR2
	CALL	OBJ_DELETE

	LDI	HELI_SNDLP,AR2		;may want to add in volume effects
	CALL	KILLSNDFX

	LDI	*+AR7(CD_ANIPROC),AR2
	CALL	PRC_KILL
	DIE
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR4	OBJECT
*
FIND_YX_MATRIX:
	LDF	*+AR4(ORADY),R2
	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX

	LDI	@MATRIXAI,AR2
	LDF	*+AR4(ORADX),R2
	CALL	FIND_XMATRIX

	LDI	@MATRIXAI,R2
	LDI	AR4,R3
	ADDI	OMATRIX,R3
	LDI	R3,AR2
	CALL	CONCATMAT
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SETDYNAOBJ:
	LDI	O_DYNAMIC,R0	 	;MAKE PARENT OBJECT DYNAMIC
	OR	*+AR4(OFLAGS),R0
	STI	R0,*+AR4(OFLAGS)

	LDL	CHOPPERDYNA,AR2

	LDI	AR4,AR3
	ADDI	ODYNALIST,AR3

*INIT DYNA OBJECTS
	LDI	*AR2++,RC		;GET DYNAMIC OBJECT COUNT
	RPTB	CHOPLP

 	CALL	GETDYNA	     		;LINK HIM INTO LIST
	STI	AR0,*AR3

	LDF	*AR2++,R0
	STF	R0,*+AR0(DYNACENTERX)
	STF	R0,*+AR0(DYNATRANSX)
	LDF	*AR2++,R0
	STF	R0,*+AR0(DYNACENTERY)
	STF	R0,*+AR0(DYNATRANSY)
	LDF	*AR2++,R0
	STF	R0,*+AR0(DYNACENTERZ)
	STF	R0,*+AR0(DYNATRANSZ)
	LDI	*AR2++,R0
	STI	R0,*+AR0(DYNANVERTS)
	LDI	*AR2++,R0
	STI	R0,*+AR0(DYNAFLAG)
	STI	AR4,*+AR0(DYNAPARENT)
CHOPLP	LDI	AR0,AR3

	LDI	0,R0
	STI	R0,*AR3			;LAST LINK IS ZERO, DUDES

	LDI	AR3,AR0
	ADDI	DYNAMATRIX,AR0
	CALL	INITMAT


	LDL	CHOPPERANI,AR2
	LDI	DRONE_C|ANI_T,R2
	CALL	PRC_CREATE_CHILD
	STI	AR0,*+AR7(CD_ANIPROC)
	STI	AR0,*+AR4(ORADZ)

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CHOPPERANI:
	LONGROUT
	CLRF	R6
CANILP
	LDI	*+AR4(ODYNALIST),R0
	LDI	R0,AR0
	LDF	R6,R2

	FLOAT	@NFRAMES,R0
	MPYF	0.6,R0
	ADDF	R0,R2
	CALL	NORMITS
	LDF	R2,R6
	LDI	AR0,AR2
	ADDI	DYNAMATRIX,AR2
	CALL	FIND_YMATRIX

	SLEEP	1
	BU	CANILP

	END_LONGROUT
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*FSL_MOVE	Frictionless Movement
*
*PARAMETERS
*	R2	THETA DELTA (CHANGE IN THETA)
*	R3	SPEED
*
FSL_MOVE:

;	LDP	@NFRAMES
;	FLOAT	@NFRAMES,R0
;	MPYF	R0,R3

	;
	;move to better y height
	;
	LDF	*+AR7(CD_DHEIGHT),R0
	SUBF	*+AR4(OPOSY),R0
	LDF	*+AR4(OVELY),R1
	MPYF	0.85,R1
	MPYF	0.15,R0
	ADDF	R0,R1

	CMPF	60,R1
	LDFGT	60,R1
	CMPF	-60,R1
	LDFLT	-60,R1

	STF	R1,*+AR4(OVELY)


	PUSHF	R2
	ADDF	*+AR4(ORADY),R2
 	STF	R2,*+AR4(ORADY)
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX


	LDI	AR2,R2
	CALL	CLR_VECTORA
	STF	R3,*+AR2(Z)
	LDF	*+AR4(OVELY),R0
	STF	R0,*+AR2(Y)


	LDI	AR2,R3
	CALL	MATRIX_MUL

	LDF	*+AR2(X),R0
	LDF	*+AR4(OVELX),R1
	MPYF	0.1,R0
	MPYF	0.9,R1
	ADDF	R1,R0
	STF	R0,*+AR4(OVELX)
	FLOAT	@NFRAMES,R1
	MPYF	R1,R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR2(Y),R0
	LDF	*+AR4(OVELY),R1
	MPYF	0.9,R0
	MPYF	0.1,R1
	ADDF	R1,R0
	STF	R0,*+AR4(OVELY)
;	FLOAT	@NFRAMES,R1
;	MPYF	R1,R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)

	LDF	*+AR2(Z),R0
	LDF	*+AR4(OVELZ),R1
	MPYF	0.1,R0
	MPYF	0.9,R1
	ADDF	R1,R0
	STF	R0,*+AR4(OVELZ)
	FLOAT	@NFRAMES,R1
	MPYF	R1,R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

 	LDF	*+AR4(ORADY),R2		;R2	CURRENT THETA
	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX


	LDF	*+AR7(CD_TSPEED),R0


	LDF	*+AR4(ORADX),R2
	LDI	@MATRIXBI,AR2
	CALL	FIND_XMATRIX

	POPF	R2


	MPYF	25,R2
	LDF	*+AR4(CRADZ),R0
	MPYF	0.1,R2
	MPYF	0.9,R0
	ADDF	R0,R2

	CMPF	0.4,R2
	LDFGT	0.4,R2
	CMPF	-0.4,R2
	LDFLT	-0.4,R2
	STF	R2,*+AR4(CRADZ)
	LDI	@MATRIXAI,AR2
	CALL	FIND_ZMATRIX

	LDI	@MATRIXBI,AR2
	LDI	@MATRIXAI,R2
	LDI	AR2,R3
	CALL	CONCATMATV		;X * Z -> matA


	LDI	AR4,R2
	ADDI	OMATRIX,R2
	LDI	R2,R3
	CALL	CONCATMATV




	;FIND WHAT OUR SPEED ACTUAL IS
	LDF	*+AR4(OVELX),R2
	MPYF	R2,R2
	LDF	*+AR4(OVELY),R1
	MPYF	R1,R1
	ADDF	R1,R2
	LDF	*+AR4(OVELZ),R1
	MPYF	R1,R1
	ADDF	R1,R2
	CALL	SQRT
	LDF	*+AR7(CD_TSPEED),R1
	STF	R0,*+AR7(CD_TSPEED)
	STF	R1,*+AR7(CD_TSPEED_OLD)

	CALL	DIV_F30
	CMPF	1.0,R0
	LDFGT	1.0,R0
	MPYF	0.2,R0
	STF	R0,*+AR4(ORADX)

	RETS
*----------------------------------------------------------------------------



;
;*----------------------------------------------------------------------------
;*
;*PARAMETERS
;*	AR4	CHOPPER OBJECT
;*
;BOMB_PROC:
;	LDI	AR4,AR5
;	CALL	OBJ_GET
;	BC	SUICIDE
;
;	LDI	AR0,AR4
;	LDF	*+AR5(OPOSX),R0
;	STF	R0,*+AR4(OPOSX)
;	LDF	*+AR5(OPOSY),R0
;	STF	R0,*+AR4(OPOSY)
;	LDF	*+AR5(OPOSZ),R0
;	STF	R0,*+AR4(OPOSZ)
;
;	STI	AR7,*+AR4(OPLINK)
;
;	LDF	*+AR2(ORADY),R2
;	LDI	AR4,AR2
;	ADDI	OMATRIX,AR2
;	CALL	FIND_YMATRIX
;
;	LDIL	bomb,AR0
;	STI	AR0,*+AR4(OROMDATA)
;
;	LDI	1,R1
;	LS	O_PROC_B,R1
;	LDI	1,R0
;	LS	O_3DROT_B,R0
;	OR	R1,R0
;	OR	*+AR4(OFLAGS),R0
;	STI	R0,*+AR4(OFLAGS)
;
;	LDF	HALFPI,R2
;	LDI	AR4,AR2
;	ADDI	OMATRIX,AR2
;	CALL	FIND_XMATRIX
;
;	LDI	AR4,AR2
;	CALL	OBJ_INSERT
;
;
;	LDF	HALFPI,R0
;	STF	R0,*+AR4(ORADX)
;
;
;	LDF	*+AR5(OVELX),R0
;	STF	R0,*+AR4(OVELX)
;	LDF	*+AR5(OVELY),R0
;	STF	R0,*+AR4(OVELY)
;	LDF	*+AR5(OVELZ),R0
;	STF	R0,*+AR4(OVELZ)
;
;	CALL	ADD_RDDEBRIS
;	LDI	TSIGN_C|TSC_HARD,R0
;	STI	R0,*+AR4(OID)
;
;
;
;	LDI	120,AR6
;BOMB_L
;	DEC	AR6
;	CMPI	0,AR6
;	BLE	BOMBDIE
;
;	PUSH	AR4
;	ADDI	OPOSX,AR4
;	CALL	CAMSCAN
;	POP	AR4
;	BNC	BOMBDIE
;
;	FLOAT	100,R1
;	CMPF	R1,R0
;	BLE	BOMBDIE
;
;
;	LDF	*+AR4(OVELX),R0
;	MPYF	0.99,R0
;	STF	R0,*+AR4(OVELX)
;	LDF	*+AR4(OVELY),R0
;	ADDF	5,R0
;	FLOAT	50,R1
;	CMPF	R1,R0
;	LDFGT	R1,R0
;	STF	R0,*+AR4(OVELY)
;	LDF	*+AR4(OVELZ),R0
;	MPYF	0.99,R0
;	STF	R0,*+AR4(OVELZ)
;
;	FLOAT	@NFRAMES,R2
;
;	LDF	*+AR4(OVELX),R0
;	MPYF	R2,R0
;	ADDF	*+AR4(OPOSX),R0
;	STF	R0,*+AR4(OPOSX)
;
;	LDF	*+AR4(OVELY),R0
;	MPYF	R2,R0
;	ADDF	*+AR4(OPOSY),R0
;	STF	R0,*+AR4(OPOSY)
;
;	LDF	*+AR4(OVELZ),R0
;	MPYF	R2,R0
;	ADDF	*+AR4(OPOSZ),R0
;	STF	R0,*+AR4(OPOSZ)
;
;
;	LDF	*+AR4(ORADX),R2
;	MPYF	0.80,R2
;	STF	R2,*+AR4(ORADX)
;	LDI	@MATRIXAI,AR2
;	CALL	FIND_XMATRIX
;
;
;	LDF	*+AR4(ORADY),R2
;	ADDF	0.3,R2
;	CALL	NORMITS
;	STF	R2,*+AR4(ORADY)
;
;	LDI	AR4,AR2
;	ADDI	OMATRIX,AR2
;	CALL	FIND_YMATRIX
;
;	LDI	@MATRIXAI,AR2
;	LDI	AR4,R2
;	ADDI	OMATRIX,R2
;	LDI	R2,R3
;	CALL	CONCATMATV
;	
;	SLEEP	1
;	BU	BOMB_L
;
;BOMBDIE
;	LDI	@EXP_ANII,AR5
;
;	LDI	*AR5,AR0
;	STI	AR0,*+AR4(OROMDATA)
;
;	ORM	O_POSTER,*+AR4(OFLAGS)
;
;	LDI	*+AR4(OFLAGS),R0
;	ANDN	O_1PAL,R0
;	OR	O_POSTER,R0
;	STI	R0,*+AR4(OFLAGS)
;
;	BU	EXLJ
;*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
;EXP_ANII	.word	EXP_ANI
;EXP_ANI
;	;.word	exp1,exp2,exp3,exp4,exp5,exp6,exp7,-1
;	;.word	dexplo1,dexplo2,dexplo3,dexplo4,dexplo5
;	;.word	dexplo6,dexplo7,dexplo8,dexplo9,dexplo10,dexplo11,-1
;
;	.word	blast1,blast2,blast3,blast4,blast5
;	.word	blast6,blast7,blast8,blast9,blast10,-1
;	
;
;
;EXPLO_SOUNDSI	.word	EXPLO_SOUNDS
;EXPLO_SOUNDS	.word	EXP1,EXP2,EXP3
;
;EXP_NMPUFF:
;	LDI	AR4,AR6
;	CALL	OBJ_GET
;	BC	SUICIDE
;	LDI	AR0,AR4
;	LDI	@EXP_ANII,AR5
;
;	LDI	*AR5,AR0
;	STI	AR0,*+AR4(OROMDATA)
;
;	LDF	*+AR6(OPOSX),R0
;	STF	R0,*+AR4(OPOSX)
;	LDF	*+AR6(OPOSY),R0
;	STF	R0,*+AR4(OPOSY)
;	LDF	*+AR6(OPOSZ),R0
;	STF	R0,*+AR4(OPOSZ)
;	ORM	O_POSTER,*+AR4(OFLAGS)
;	LDI	AR4,AR2
;	CALL	OBJ_INSERT
;EXLJ
;
;;explosions must get louder
;;
;;	RANDN	3
;	LDI	@EXPLO_SOUNDSI,AR2
;;	ADDI	R0,AR2
;	LDI	*AR2,AR2
;	CALL	ONESNDFX
;
;	;collidable explosion
;
;EXP_NMPUFFLP
;	LDI	*AR5++,AR0
;	CMPI	-1,AR0
;	BEQ	EXP_DIE
;	STI	AR0,*+AR4(OROMDATA)
;
;	SLEEP	1
;	BU	EXP_NMPUFFLP
;
;EXP_DIE
;	LDI	1,R1
;	LS	O_PROC_B,R1
;	NOT	R1
;	LDI	*+AR4(OFLAGS),R0
;	AND	R1,R0
;	STI	R0,*+AR4(OFLAGS)
;
;
;	LDI	AR4,AR2
;	CALL	OBJ_DELETE
;	DIE
;*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
HELI_SND:
	LDI	HELI_SNDLP,AR2		;may want to add in volume effects

	CMPI	@SNDSTR+SND_SIZ+SND_IDX,AR2	;CHECK TRACK1
	BEQ	IS_T1
	CMPI	@SNDSTR+(2*SND_SIZ)+SND_IDX,AR2	;CHECK TRACK2
	BEQ	IS_T2
	CALL	ONESNDFX

	CMPI	@SNDSTR+SND_SIZ+SND_IDX,AR2	;CHECK TRACK1
	BNE	NOT_T1
IS_T1
	LDF	*+AR7(DELTA_PLYRDIST),R0
	FLOAT	20000,R1
	CMPF	R1,R0
	LDFGT	R1,R0

	SUBRF	R1,R0
	MPYFL	0.00005,R0
;	MPYF	64,R0
;	ADDF	191,R0

	MPYF	127,R0
	ADDF	128,R0

	FIX	R0,R1
	LDI	1,R0
	CALL	SET_TRACK_VOL
	BU	HEND

NOT_T1	CMPI	@SNDSTR+(2*SND_SIZ)+SND_IDX,AR2	;CHECK TRACK2
	BNE	NOT_T2
IS_T2
	LDF	*+AR7(DELTA_PLYRDIST),R0
	FLOAT	20000,R1
	CMPF	R1,R0
	LDFGT	R1,R0

	SUBRF	R1,R0
	MPYFL	0.00005,R0
;	MPYF	64,R0
;	ADDF	191,R0

	MPYF	127,R0
	ADDF	128,R0

	FIX	R0,R1
	LDI	2,R0
	CALL	SET_TRACK_VOL
	BU	HEND
NOT_T2
HEND
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*RETURNS
*	AR0	ROAD OBJECT
*
GET_CLOSEST_TRAK:
	LDI	@DRIVE_LIST,R0
	BZ	GETRKX  		;NULL LIST DUDES

	LDI	0,AR0			;CLOSEST ROAD SEGMENT INDEX
	FLOAT	7FFFH,R2		;INITIAL CLOSEST DISTANCE
	MPYF	R2,R2

	LDF	*+AR4(OPOSX),R3		
	LDF	*+AR4(OPOSZ),R4		
	LDI	R0,AR2
GETRK
	LDI	*+AR2(OID),R0	    	;IS THIS REAL ROAD?
	AND	0FF0H,R0
	CMPI	300H,R0
	BNE	GETRKL			;NOPE...

	LDF	R3,R0
	SUBF	*+AR2(OPOSX),R0
	MPYF	R0,R0

	LDF	R4,R1
	SUBF	*+AR2(OPOSZ),R1
	MPYF	R1,R1
	ADDF	R0,R1

	CMPF	R1,R2
	BLE	GETRKL
	LDI	AR2,AR0
	LDF	R1,R2
GETRKL
	LDI	*+AR2(OLINK3),R0
	BNZD	GETRK

	LDI	R0,AR2
	NOP		     
	NOP
	;---->	BNZ	GETRK
;	STI	AR0,*+AR5(CARTRAK)	;SAVE TRACK SECTION
GETRKX
	RETS
*----------------------------------------------------------------------------
	.END
