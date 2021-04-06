	.FILE	"COMMQ.ASM"
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
	.include	COMM.EQU
	.include	DELTA.EQU


	.bss	IGNORE_UPDATES,1

	fbss	COMMQ_TMP_BUFF,80

SEND_BUFFER_AI	.word	SEND_BUFFER_A

	phibss	SEND_BUFFER_A,COMM_BUFFER_SIZE
	pbss	SEND_BUFFER_A_LEN,1

	;RECEIVE BUFFER
	;
	pbss	RBUFF_LEN,1
	phibss	RECEIVE_BUFFER,COMM_BUFFER_SIZE


	;OTHER MACHINE
	;(OM_*)
	;
	pbss	OM_DIFF,1
	pbss	OM_MODE,1
	pbss	OM_CHOSEN_RACE,1
	pbss	OM_VEHICLE,1
	pbss	OM_STATE,1
	pbss	MY_STATE,1
	pbss	OM_ATTR_MODE,1
	pbss	OLD_OM_ATTR_MODE,1
	pbss	OM_LINKWAIT,1
	.bss	MY_LINKWAIT,1
	pbss	LINKEDP,1
	pbss	OM_HIDDEN_ON,1
	pbss	OM_RACE_MODE,1
	.bss	BSYNC,1
	pbss	OM_BSYNC,1
	pbss	OM_POSITION,1


	pbss	HEAD2HEAD_ON,1

COMMQ_TMP_BUFFI	.word	COMMQ_TMP_BUFF




*----------------------------------------------------------------------------
*Clear all of the linking elements
*
*
	.bss	SAVED_PLY2CAR,1
CLEAR_LINK:
	LDI	@PLY2CAR,R0
	STI	R0,@SAVED_PLY2CAR

	CLRI	R0
	STI	R0,@MY_STATE
	STI	R0,@OM_STATE
	STI	R0,@OM_MODE
	STI	R0,@HEAD2HEAD_ON
	STI	R0,@MY_LINKWAIT
	STI	R0,@OM_LINKWAIT
	STI	R0,@PLY2CAR
	STI	R0,@CAR_LIST

	LDI	@RACER_PTRI,AR0
	RPTS	10-1
	STI	R0,*AR0++


	LDI	-1,R0
	STI	R0,@OM_CHOSEN_RACE
	STI	R0,@OM_VEHICLE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
DECODE_BUFFER:

	LDI	@DIPRAM,R0
	TSTB	DIP_COMMP,R0 	       ;LINKED ?
	RETSNZ			       ;NOPE...

	LDI	@TRANSMISSION_ACTIVE,R0
	RETSZ

	LDI	@RBUFF_LEN,R0	       ;ANYTHING THERE ?
	RETSZ			       ;NOPE

	LDI	@RECEIVE_BUFFERI,AR2
	LDI	@RBUFF_LEN,AR6
	INC	AR6
	LS	1,AR6
	ADDI	AR2,AR6
	B	DECLPX

DECODE_LP
	LDI	*AR2++,AR0		;GET THE BLOCK ID
	LS	8,AR0
	RS	24,AR0			;SHIFT OFF THE CRAP

	CMPI	CB_LASTMSG,AR0		;CHECK BOGUS MESSAGE

	.if	CDEBUG
	BGE	$			;TRAP ON BUGUS FOR DEBUG
	.endif

	BGE	ISDONE			;EXIT ON BOGUS

	ADDI	@DECODE_BLOCKI,AR0
	LDI	*AR0,R0
	CALLU	R0

DECLPX
	CMPI	AR6,AR2
	BLT	DECODE_LP
	
ISDONE:
	CLRI	R0
	STI	R0,@RBUFF_LEN
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*
*	.word	ID,ROUTINE TO DECODE
*
*
*Each decode routine can assume:
*	  AR2 is the pointer to the data block
*	  AR6,DP registers must be saved/restored
*	  AR2 should be incremented to the next block
*
*
DECODE_BLOCKI	.word	DECODE_BLOCK
DECODE_BLOCK
	.word	DECODE_NULL
	.word	DECODE_MODE		;CB_MODE
	.word	DECODE_TIMECODE		;CB_TIMECODE
	.word	DECODE_RACENUM		;CB_RACENUM
	.word	DECODE_VEHICLE		;CHOSEN CAR IDENTITY CODE
	.word	DECODE_START_GAME
	.word	DECODE_END_GAME
	.word	DECODE_CAR_UPDATE	;UPDATE DATA BLOCK FOR CAR
	.word	DECODE_END_GAME
	.word	DECODE_LINKEDT
	.word	DECODE_LINKEDF
	.word	DECODE_LINKCANCELLED

	.word	DECODE_RACER_UPDATE
	.word	DECODE_RACER_XSFER
	.word	DECODE_RACER_KILL

	.word	DECODE_RHO_CREATE	
	.word	DECODE_RHO_KILL		
	.word	DECODE_RHO_XSFER	
	.word	DECODE_RHO_UPDATE	

	.word	DECODE_FLY_KILL		
	.word	DECODE_FLY_XSFER	
	.word	DECODE_FLY_UPDATE

	.word	DECODE_WAVEFL_READY
	.word	DECODE_WAVEFL_SET
	.word	DECODE_WAVEFL_GO

	.word	DECODE_OM_TRACK

	.word	DECODE_BSYNC0
	.word	DECODE_BSYNC1
	.word	DECODE_BSYNC2
	.word	DECODE_BSYNC3

	.word	DECODE_CHANGE_MUSIC
	.word	DECODE_COINDROP
	.word	DECODE_DIAGNOSTIC

	.word	DECODE_ATTRSND

	.word	-1

	.globl	SEND_FLY_KILL,DECODE_FLY_KILL,SEND_FLY_POS,DECODE_FLY_XSFER
	.globl	DECODE_RACER_XSFER
	.globl	DECODE_RHO_KILL,DECODE_RHO_XSFER

*----------------------------------------------------------------------------
*
*SETUP SEND BUFFER POINTERS
*
COMMQ_PACKET_INIT:
	PUSH	R0

;	LDI	@SEND_BUFFER_AI,R0
;	STI	R0,@FILLBUFF_PTR
;	LDL	SEND_BUFFER_A_LEN,R0
;	STI	R0,@FILLBUFF_LEN_PTR

	CLRI	R0
	STI	R0,@SEND_BUFFER_A_LEN
CMQIX
	CALL	SEND_MODE

	POP	R0
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
*
*
*FOR MASTER, HE WILL SEND IMMEDIATELY FOLLOWING,
*FOR SLAVE, HE WILL SWITCH BUFFERS, AND WHEN REQUESTED SEND THIS BUFFER
*IF THE NEXT BUFFER IF FULL, SLAVE WILL OVERWRITE THIS BUFFER, AND SO ON
*
*
COMMQ_READY_TO_SEND:
	PUSH	R0
	PUSH	AR0
	PUSH	AR2


	;PAD THE END OF THE MESSAGES
	LDI	CB_NULL,AR2
	CALL	MESSAGE_ADD_SB

	POP	AR2
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
*
*REMEMBER ALSO THAT THESE ARE BYTE STRINGS (LOWER 8 BITS ONLY)
*
*
*
*PARAMETERS
*	RC	(LENGTH OF BUFFER)-1
*	AR2	PTR TO MESSAGE STRING (BUFFER)
*
*	(REMEMBER THAT THE FIRST WORD OF THE MESSAGE SHOULD BE THE
*	BLOCK HEADER)
*
MESSAGE_ADD:
	PUSH	AR0
	PUSH	AR2
	PUSH	AR3
	PUSH	R0

	LDI	@DIPRAM,R0
	TSTB	DIP_COMMP,R0
	BNZ	MESSADDX

	LDI	RC,R0
	
	LDI	@SEND_BUFFER_AI,AR3
	ADDI	@SEND_BUFFER_A_LEN,AR3
	ADDI	@SEND_BUFFER_A_LEN,R0

;	LDI	@FILLBUFF_LEN_PTR,AR0
;	LDI	@FILLBUFF_PTR,AR3
;	ADDI	*AR0,AR3		;start of new message
;	ADDI	*AR0,R0

	INC	R0			;->(Length - 1)

	CMPI	COMM_BUFFER_SIZE,R0
	.if	CDEBUG
	BGT	$
	.endif
	BGT	MESSADDX

;	STI	R0,*AR0			;length 
	STI	R0,@SEND_BUFFER_A_LEN

	RPTB	JJAG
	LDI	*AR2++,R0
JJAG	STI	R0,*AR3++


MESSADDX
	POP	R0
	POP	AR3
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*MESSAGE ADD, SINGLE BYTE
*
*PARAMETERS
*	AR2	MESSAGE
*
MESSAGE_ADD_SB:
	PUSH	R0
	PUSH	AR0

	LDI	@DIPRAM,R0
	TSTB	DIP_COMMP,R0
	BNZ	MASBX

	LDI	@SEND_BUFFER_A_LEN,R0

;	LDI	@FILLBUFF_LEN_PTR,AR0
;	LDI	*AR0,R0

	INC	R0
	CMPI	COMM_BUFFER_SIZE,R0
	.if	CDEBUG
	BGT	$
	.endif
	BGT	MASBX

;	STI	R0,*AR0
	STI	R0,@SEND_BUFFER_A_LEN

;	LDI	*AR0,AR0
;	ADDI	@FILLBUFF_PTR,AR0

	LDI	@SEND_BUFFER_AI,AR0
	ADDI	R0,AR0
	STI	AR2,*-AR0(1)
MASBX
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------

DECODE_NULL		;DO NOTHING
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SEND_WAVEFL_READY:
	LDI	CB_WAVEFL_READY,AR2
	BR	MESSAGE_ADD_SB
SEND_WAVEFL_SET:
	LDI	CB_WAVEFL_SET,AR2
	BR	MESSAGE_ADD_SB
SEND_WAVEFL_GO:
	CLRI	R0
	STI	R0,@_sectime
	LDI	CB_WAVEFL_GO,AR2
	BR	MESSAGE_ADD_SB
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
DECODE_WAVEFL_READY:
	LDI	1,R0
	STI	R0,@H2H_FLAGSTATE
	RETS
DECODE_WAVEFL_SET:
	LDI	2,R0
	STI	R0,@H2H_FLAGSTATE
	RETS
DECODE_WAVEFL_GO:
	LDI	3,R0
	STI	R0,@H2H_FLAGSTATE

	CLRI	R0
	STI	R0,@_sectime
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SEND_LINKEDT:
	PUSH	AR2
	LDI	CB_HEAD2HEADT,AR2
	CALL	MESSAGE_ADD_SB
	POP	AR2
	RETS
SEND_LINKEDF:
	PUSH	AR2
	LDI	CB_HEAD2HEADF,AR2
	CALL	MESSAGE_ADD_SB
	POP	AR2
	RETS

DECODE_LINKEDT:
	PUSH	R0
	LDI	1,R0
	STI	R0,@LINKEDP
	POP	R0
	RETS
DECODE_LINKEDF:
	PUSH	R0
	LDI	2,R0
	STI	R0,@LINKEDP
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
DECODE_MODE:
	PUSH	R0
	PUSH	R1
	PUSH	R2

	LDI	0FFh,R2
	LS	16,R2
	AND	*AR2++,R2,R0
	RS	16,R0

	AND	*AR2++,R2,R1
	RS	8,R1
	OR	R1,R0

	AND	*AR2++,R2,R1
	OR	R1,R0

	AND	*AR2++,R2,R1
	LS	8,R1
	OR	R1,R0
	STI	R0,@OM_MODE

	;the state
	AND	*AR2++,R2,R0
	RS	16,R0
	AND	*AR2++,R2,R1
	LS	8,R1
	RS	16,R1
	OR	R1,R0
	STI	R0,@OM_STATE

	AND	*AR2++,R2,R0
	RS	16,R0
	STI	R0,@OM_BONUS_WAITFLAG

	;POSITION
	AND	*AR2++,R2,R0
	RS	16,R0
	STI	R0,@OM_POSITION
	
	;the attract mode index
	AND	*AR2++,R2,R0
	LS	8,R0
	ASH	-24,R0
	LDI	@OM_ATTR_MODE,R1
	STI	R1,@OLD_OM_ATTR_MODE
	STI	R0,@OM_ATTR_MODE

	;DECODE  OM_DIFF
	AND	*AR2++,R2,R0
	LSH	-16,R0
	FLOAT	R0
	MPYF	0.01,R0
	STF	R0,@OM_DIFF


	LDI	@OM_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BNE	DC_M_NOP

	LDI	0,R0
	STI	R0,@HEAD2HEAD_ON

	LDI	-1,R0
	STI	R0,@OM_CHOSEN_RACE
	STI	R0,@OM_VEHICLE
	BU	DCMX

DC_M_NOP


	LDI	@OM_STATE,R0
	TSTB	OMS_FINISHLINE,R0
	BZ	DWAI

	LDI	@MY_STATE,R1
	TSTB	OMS_FINISHLINE,R1
	BNZ	DWAI

	;else: Hes finished, Im not
	;therefore:  0 -> countdown

;	LDI	1,R1
;	STI	R1,@I_TIMED_OUT

	CLRI	R1
	STI	R1,@_countdown

	BU	DCMX
DWAI


	LDI	@OM_MODE,R0
	AND	MMODE,R0
	CMPI	MGAME,R0	;OM in game?
	BNE	DCMX

	LDI	@_MODE,R0	;ME in game?
	AND	MMODE,R0
	CMPI	MGAME,R0
	BNE	NONEWCP


	LDI	@OM_STATE,R0
	AND	OMS_CPOINT_M,R0
	LDI	@MY_STATE,R1
	AND	OMS_CPOINT_M,R1
	CMPI	R1,R0
	BEQ	NONEWCP

	CMPI	R0,R1		;is my CP cnt > his CP cnt?
	CALLLT	CHECKPOINT_HIT_R
NONEWCP

DCMX
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
*turn on the checkpoint bit within the MY_STATE
*does not actually send data over the comm lines.
*
*
SEND_CHECKPOINT:
	LDI	@CHECKPOINT_NUM,R0
	LDI	1,R1
	LS	R0,R1
	LS	8,R1
	OR	@MY_STATE,R1
	STI	R1,@MY_STATE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_FINISH:
	LDI	OMS_FINISHLINE,R0
	OR	@MY_STATE,R0
	STI	R0,@MY_STATE
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SEND_MODE:
	LDI	@COMMQ_TMP_BUFFI,AR2

	LDI	CB_MODE,R0
	STI	R0,*AR2++

	LDI	@_MODE,R0
	STI	R0,*AR2++
	RS	8,R0
	STI	R0,*AR2++
	RS	8,R0
	STI	R0,*AR2++
	RS	8,R0
	STI	R0,*AR2++


	LDI	@MY_STATE,R0
	STI	R0,*AR2++
	RS	8,R0
	STI	R0,*AR2++

	LDI	@BONUS_WAITFLAG,R0
	STI	R0,*AR2++

	LDI	@POSITION,R0
	STI	R0,*AR2++

	LDI	@_ATTR_MODE,R0
	STI	R0,*AR2++


	LDF	@GAMEDIFF,R0 		;SEND DIFFICULTY
	MPYF	100,R0
	FIX	R0
	STI	R0,*AR2--(10)


	LDI	11-1,RC
	BR	MESSAGE_ADD
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
DECODE_LINKCANCELLED:
	CLRI	R0
	STI	R0,@OM_LINKWAIT
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
SEND_LINKCANCELLED:
	LDI	CB_LINKCANCELLED,AR2
	BR	MESSAGE_ADD_SB
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
* T 	I BOUGHT IN
*
*
*
SEND_START_GAME:
	CLRI	R0
	STI	R0,@IGNORE_UPDATES
	LDI	CB_START_GAME,AR2
	CALL	MESSAGE_ADD_SB

	LDI	0,R0
	STI	R0,@MY_STATE
	STI	R0,@HEAD2HEAD_ON

	LDI	1,R0
	STI	R0,@MY_LINKWAIT
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
DECODE_START_GAME:
	LDI	1,R0
	STI	R0,@OM_LINKWAIT

	LDI	@MY_LINKWAIT,R0
	BZ	NOPE
	LDI	1,R0
	STI	R0,@HEAD2HEAD_ON

	INCAUD	AUD_H2HGAMES

	CLRI	R0
	STI	R0,@OM_LINKWAIT
	STI	R0,@MY_LINKWAIT
	CALL	SEND_LINKEDT

	LDI	-1,R0
	STI	R0,@OM_CHOSEN_RACE
	STI	R0,@OM_VEHICLE

	PUSH	AR2
	SOND1	START_THEME
	POP	AR2

	LDI	@RACE_MODE,R0
	CMPI	RM_USA,R0
	RETSNE
	CALL	SEND_RACENUM
	RETS

NOPE
	CALL	SEND_LINKEDF

	LDI	-1,R0
	STI	R0,@OM_CHOSEN_RACE
	STI	R0,@OM_VEHICLE
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SEND_END_GAME:
	LDI	CB_END_GAME,AR2
	BR	MESSAGE_ADD_SB
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
*clear the variables associated with the game...
DECODE_END_GAME:
	LDI	0,R0
	STI	R0,@HEAD2HEAD_ON
	RETS
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
SEND_TIMECODE:
	LDI	@COMMQ_TMP_BUFFI,AR2

	LDI	CB_TIMECODE,R0
	STI	R0,*AR2++

	LDI	@_countdown,R0
	STI	R0,*AR2++
	RS	8,R0
	STI	R0,*AR2++
	LDI	@_sectime,R0
	STI	R0,*AR2--(3)
	LDI	4-1,RC
	BR	MESSAGE_ADD
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SEND_RACENUM:
	LDL	COMMQ_TMP_BUFF,AR2
	LDI	CB_RACENUM,R0
	STI	R0,*AR2++

	LDI	@HIDDEN_ON,R0
	STI	R0,*AR2++

	LDI	@RACE_MODE,R0
	STI	R0,*AR2++

	LDI	@CHOSEN_RACE,R0
	STI	R0,*AR2--(3)

	LDI	4-1,RC
	BR	MESSAGE_ADD
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
DECODE_RACENUM:
	PUSH	R1
	LDI	*AR2++,R1
	LS	8,R1
	ASH	-24,R1
	STI	R1,@OM_HIDDEN_ON
	
	LDI	*AR2++,R0
	LS	8,R0
	RS	24,R0
	STI	R0,@OM_RACE_MODE

	LDI	*AR2++,R0
	LS	8,R0
	RS	24,R0
	STI	R0,@OM_CHOSEN_RACE
NOTHIDDEN
	POP	R1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
DECODE_VEHICLE:
	LDI	*AR2++,R0
	LS	8,R0
	RS	24,R0
	STI	R0,@OM_VEHICLE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_VEHICLE:
	LDI	@COMMQ_TMP_BUFFI,AR2
	LDI	CB_VEHICLE,R0
	STI	R0,*AR2++
	LDI	@CHOOSENCAR,R0	;contains extended vehicles
	STI	R0,*AR2--

	LDI	2-1,RC
	BR	MESSAGE_ADD
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
DECODE_TIMECODE:
	PUSH	R0
	PUSH	R1
	PUSH	R2

	LDI	0FFh,R2
	LS	16,R2
	AND	*AR2++,R2,R0
	RS	16,R0

	AND	*AR2++,R2,R1
	RS	8,R1
	OR	R1,R0
	STI	R0,@_countdown

	AND	*AR2++,R2,R0
	STI	R0,@_sectime

	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------




	.GLOBL	SEND_RACER_POS,SEND_RHO_POS
*----------------------------------------------------------------------------
*
*AR4=CAR OBJECT
*AR5=CAR BLOCK
*AR7=RHO PROCESS
*
SEND_FLY_POS
SEND_RHO_POS:
	LDI	*+AR7(DELTA_LAST_OID),R0
	STI	R0,*+AR5(CARTRACK_ID)  	;SAVE TRACK ID

	LDI	CB_RHO_UPDATE,R0	;GET MESSAGE HEADER

	LDI	AR4,AR0	    		;GET OBJECT IN AR0
	LDI	@COMMQ_TMP_BUFFI,AR2
	STI	R0,*AR2++

*SEND CAR ID #

	LDI	*+AR5(CARNUM),R0
	B	SEND_CP0
*
*AR4=CAR OBJECT
*AR5=CAR BLOCK
*AR7=RACER PROCESS
*
SEND_RACER_POS:
	LDI	*+AR7(DELTA_LAST_OID),R0
	STI	R0,*+AR5(CARTRACK_ID)  	;SAVE TRACK ID

	LDI	CB_RACER_UPDATE,R0	;GET MESSAGE HEADER
	B	SEND_CAR_POS

SEND_PLAYERS_POS:
*
*AR4=PLAYER CAR OBJECT
*AR7=PLAYER PROCESS
*
	LDI	CB_CAR_UPDATE,R0	;GET MESSAGE HEADER

SEND_CAR_POS:

*SEND MESSAGE HEADER

	LDI	AR4,AR0	    		;GET OBJECT IN AR0
	LDI	@COMMQ_TMP_BUFFI,AR2
	STI	R0,*AR2++

*SEND CAR ID #

	LDI	*+AR7(DELTA_INIT),R0
SEND_CP0
	STI	R0,*AR2++

*SEND XYZ

	ADDI	OPOSX,AR0

	LDI	2,RC
	RPTB	SENDXYZ			;GET XYZ COORD

	FIX	*AR0++,R0		;CONVERT TO 32 BIT FIXED
	STI	R0,*AR2++
	LSH	-8,R0
	STI	R0,*AR2++
	LSH	-8,R0
	STI	R0,*AR2++
	LSH	-8,R0
SENDXYZ	STI	R0,*AR2++

*SEND MATRIX

	LDI	AR4,AR0	    		;GET OBJECT IN AR0
	ADDI	OMATRIX,AR0

	FLOAT	32000,R1

	LDI	8,RC			;DO 9 MATRIX ENTRIES
	RPTB	MATLP
	MPYF	*AR0++,R1,R0
	FIX	R0
	STI	R0,*AR2++
	LSH	-8,R0
MATLP	STI	R0,*AR2++

*SEND CARYROT

	LDI	AR4,AR0	    		;GET OBJECT IN AR0
	LDI	*+AR0(OCARBLK),AR1
	LDF	*+AR1(CARYROT),R2
	CALL	NORMITS
	
	FLOAT	1000,R1
	MPYF	R1,R2
	FIX	R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++

*SEND CAR STRUCTURE STUFF
*SEND CARTURN

	LDF	*+AR1(CARTURN),R2
	CALL	NORMITS

	FLOAT	1000,R1
	MPYF	R1,R2
	FIX	R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++

*SEND CARVROT

	LDF	*+AR1(CARVROT),R2
	CALL	NORMITS

	FLOAT	1000,R1
	MPYF	R1,R2
	FIX	R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++


*SEND CARSPEED

	FIX	*+AR1(CARSPEED),R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++

*SEND AIRF, AIRB

	LDI	*+AR1(CAR_AIRF),R2
	STI	R2,*AR2++

	LDI	*+AR1(CAR_AIRB),R2
	STI	R2,*AR2++

*SEND BRAKE

	LDF	*+AR1(CARBRAKE),R2
	MPYF	100,R2
	FIX	R2
	STI	R2,*AR2++

*SEND TRACK ID

	LDI	*+AR1(CARTRACK_ID),R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++ 		;24 BITS ID

;	CLRI	R0			;padding
;	STI	R0,*AR2++

	LDI	@COMMQ_TMP_BUFFI,AR2	;GET START OF MESSAGE

	LDI	45,RC
;	LDI	46,RC
	BR	MESSAGE_ADD
*
*SEND RHO CREATION
*AR4=OBJECT
*R5=VEHICLE DESCRIPTOR INDEX
*R0=VEHICLE ID #
*
	.globl	SEND_RHO_CREATE

SEND_RHO_CREATE:
	LDI	@HEAD2HEAD_ON,R1
	RETSZ
	
	LDI	CB_RHO_CREATE,R1	;GET MESSAGE HEADER
	LDI	@COMMQ_TMP_BUFFI,AR2
	STI	R1,*AR2++		;MESSAGE HEADER CODE
	STI	R0,*AR2++		;save car id #
	STI	R5,*AR2++	    	;SAVE CAR INDEX
	LDI	*+AR4(OPAL),R0
	LSH	-8,R0
	STI	R0,*AR2++

	LDI	4-1,RC
	LDI	@COMMQ_TMP_BUFFI,AR2
	BR	MESSAGE_ADD

*----------------------------------------------------------------------------

*MATRIX DECODE CONSTANT
MATCON	.FLOAT	0.00003125		;1/32000	
RADCON	.FLOAT	0.001			;1/1000

*----------------------------------------------------------------------------
	.GLOBL	PLY2CAR,FIND_DRONE

*
*FIND DRONE CAR
*RET Z=FOUND, AR0=CAR OBJECT
*R2=-16, R3=-8

FIND_DRONE:

	LDI	-16,R2
	LDI	-8,R3

*GET CAR ID #

	LSH	R2,*AR2++,R1   		;GET CAR #

	LDI	@CAR_LIST,R0	 	;GET LIST
	B	FD1
FDL
	LDI	*+AR0(OCARBLK),AR1	;GET CAR BLOCK
	CMPI	*+AR1(CARNUM),R1   	;IS THIS THE CAR
	RETSZ				;WE FOUND IT

	LDI	*+AR0(OLINK3),R0
FD1
	BNZD	FDL
	LDI	R0,AR0
	NOP
	NOP
	;---->BNZD	FDL

	LDI	1,R0			;INDICATE DRONE NOT FOUND
	RETS

*
*DECODE RHO CAR UPDATE
*
DECODE_FLY_UPDATE:
DECODE_RHO_UPDATE:
	LDI	@IGNORE_UPDATES,R0
	BNZ	DECCARX


	CALL	FIND_DRONE
	BZ	DECODE_CAR_UP0

	SUBI	1,AR2
	B	DECCARX			;CAR NOT FOUND
*
*DECODE DRONE CAR UPDATE
*
DECODE_RACER_UPDATE:
	LDI	@IGNORE_UPDATES,R0
	BNZ	DECCARX
	

	LDI	-16,R2
	LDI	-8,R3

*GET CAR ID #

	LSH	R2,*AR2,R0   		;GET CAR #
	BLT	DECCARX
	CMPI	9,R0
	BGT	DECCARX			;RANGE CHECK

	ADDI	@RACER_PTRI,R0
	LDI	R0,AR0
	LDI	*AR0,R0		 	;GET POINTER
	BZ	DECCARX
	ADDI	1,AR2
	LDI	R0,AR0
	B	DECODE_CAR_UP0
*
*DECODE THE LINKED PLAYERS POSITION
*
DECODE_CAR_UPDATE:
	LDI	@IGNORE_UPDATES,R0
	BNZ	DECCARX

	LDI	@PLY2CAR,R0
	BZ	DECCARX			;NO CAR EXISTS
	LDI	R0,AR0

	LDI	-16,R2
	LDI	-8,R3

*GET CAR ID #

	LSH	R2,*AR2++,R1   		;GET CAR #
*
*AR0=POINTER TO CAR
*
DECODE_CAR_UP0:

	LDI	AR0,AR4			;SAVE CAR INDEX

*GET CAR XYZ

	ADDI	OPOSX,AR0

	LDI	2,RC
	RPTB	GETXYZ

	LSH	R2,*AR2++,R0		;GET X, Y, Z
	LSH	R2,*AR2++,R1
	LS	8,R1
	OR	R1,R0
	LSH	R2,*AR2++,R1
	LS	16,R1
	OR	R1,R0
	LSH	R2,*AR2++,R1
	LS	24,R1
	OR	R1,R0
	FLOAT	R0
GETXYZ	STF	R0,*AR0++

;	ADDI	27,AR2	 		;BLOW IT OFF
;	RETS

*GET MATRIX

	LDI	AR4,AR0
	ADDI	OMATRIX,AR0
	LDF	@MATCON,R1

	LDI	8,RC			;DO 9 MATRIX ENTRIES
	RPTB	GETMAT
	LSH	R2,*AR2++,R0
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	LSH	16,R0
	ASH	-16,R0			;DO SIGN EXTEND
	FLOAT	R0
	MPYF	@MATCON,R0
GETMAT	STF	R0,*AR0++

*GET CARYROT

	LDI	AR4,AR0
	LDI	*+AR0(OCARBLK),AR1

	LDI	1,R0	 		;SET UPDATE FLAG
	STI	R0,*+AR1(CARUPD)


	LSH	R2,*AR2++,R0
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	LSH	16,R0
	ASH	-16,R0			;DO SIGN EXTEND
	FLOAT	R0
	MPYF	@RADCON,R0
	STF	R0,*+AR1(CARYROT)

*GET CARTURN

	LSH	R2,*AR2++,R0
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	LSH	16,R0
	ASH	-16,R0			;DO SIGN EXTEND
	FLOAT	R0
	MPYF	@RADCON,R0
	STF	R0,*+AR1(CARTURN)

*GET CARVROT

	LSH	R2,*AR2++,R0
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	LSH	16,R0
	ASH	-16,R0			;DO SIGN EXTEND
	FLOAT	R0
	MPYF	@RADCON,R0
	STF	R0,*+AR1(CARVROT)


*GET CARSPEED

	LSH	R2,*AR2++,R0
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	LSH	16,R0
	ASH	-16,R0			;DO SIGN EXTEND
	FLOAT	R0
	STF	R0,*+AR1(CARSPEED)

*GET AIRF, AIRB

	LSH	R2,*AR2++,R1
	STI	R1,*+AR1(CAR_AIRF)

	LSH	R2,*AR2++,R1
	STI	R1,*+AR1(CAR_AIRB)

*GET BRAKE

	LSH	R2,*AR2++,R1
	FLOAT	R1
	MPYF	0.01,R1
	STF	R1,*+AR1(CARBRAKE)	;BRAKE = FLOAT 0-1

*GET TRACK ID

	LSH	R2,*AR2++,R0		;GET ROAD SECTION ID
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	ADDI	*AR2++,R0
;	LDI	*+AR0(OPLINK),AR3
;	STI	R0,*+AR3(DELTA_LAST_OID)
	STI	R0,*+AR1(CARTRACK_ID)
;	ADDI	1,AR2	 		;PADDING
	RETS

DECCARX
;	ADDI	46,AR2	 		;BLOW IT OFF
	ADDI	45,AR2	 		;BLOW IT OFF
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*DECODE RHO CREATION
*
	.GLOBL	RHO_START
DECODE_RHO_CREATE:
	LDI	@HEAD2HEAD_ON,R0
	BZ	DCRHOX

	LDI	@IGNORE_UPDATES,R0
	BNZ	DCRHOX

	PUSH	AR6
	LDI	-16,R2
	LDI	-8,R3
	LSH	R2,*AR2++,R4   		;GET CAR ID #
	LSH	R2,*AR2++,R5   		;GET INDEX  #
	
	LSH	R3,*AR2++,AR6  		;GET OPAL IN AR6

	PUSH	AR2
	CREATE	RHO_START,DRONE_C|VEHICLE_T|DRNE_RHO
	POP	AR2
	POP	AR6
	RETS
DCRHOX
	ADDI	3,AR2
	RETS
*
*KILL OFF RACER
*
DECODE_RACER_KILL:
	LDI	-16,R2
	LSH	R2,*AR2++,R0   		;GET CAR ID #

	LDI	@IGNORE_UPDATES,R1
	BNZ	DCRKX

	BLT	DECRKX
	CMPI	9,R0
	BGT	DECRKX			;RANGE CHECK

	ADDI	@RACER_PTRI,R0
	LDI	R0,AR0
	LDI	*AR0,R0		 	;GET POINTER
	BZ	DECRKX
*KILL OFF OBJECT, PROCESS, ANIMATION PROCESS

DECRKX
	RETS
DCRKX
	INC	AR2
	RETS


*DECODE TRACK RANGE OTHER MACHINE
DECODE_OM_TRACK

	LDI	-16,R2
	LDI	-8,R3
	LSH	R2,*AR2++,R0		;GET ROAD SECTION ID
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	ADDI	*AR2++,R0
	STI	R0,@OM_TRACK_LO

	LDI	-16,R2
	LDI	-8,R3
	LSH	R2,*AR2++,R0		;GET ROAD SECTION ID
	LSH	R3,*AR2++,R1
	ADDI	R1,R0
	ADDI	*AR2++,R0
	STI	R0,@OM_TRACK_HI
	RETS

*SEND YOUR TRACK RANGE
	.GLOBL	OM_TRACK_LO,OM_TRACK_HI
	.GLOBL 	SEND_OM_TRACK
SEND_OM_TRACK
	LDI	@COMMQ_TMP_BUFFI,AR2
	LDI	CB_OM_TRACK,R2			;GET MESSAGE HEADER
	STI	R2,*AR2++

	LDI	@DYNALIST_TRUEBEGIN,AR0		;GET CLOSEST ROAD ID
	LDI	*+AR0(OLINK4),AR0		;LINK A COUPLE AHEAD
	LDI	*+AR0(OLINK4),AR0
	LDI	*+AR0(OUSR1),R2			

	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++ 			;24 BITS ID

	LDI	@DYNALIST_END,AR0		;GET FURTHEST ROAD ID
	LDI	*+AR0(OUSR1),R2			

	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++
	LSH	-8,R2
	STI	R2,*AR2++ 			;24 BITS ID
	LDI	7-1,RC
	LDI	@COMMQ_TMP_BUFFI,AR2
	BR	MESSAGE_ADD
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_BSYNC0:
;	LDI	0,R0
;	STI	R0,@BSYNC
;	LDI	CB_BONUS_SYNC0,AR2
;	BU	SBLS
SEND_BSYNC1:
;	LDI	1,R0
;	STI	R0,@BSYNC
;	LDI	CB_BONUS_SYNC1,AR2
;	BU	SBLS
SEND_BSYNC2:
;	LDI	2,R0
;	STI	R0,@BSYNC
;	LDI	CB_BONUS_SYNC2,AR2
;	BU	SBLS
SEND_BSYNC3:
	LDI	3,R0
	STI	R0,@BSYNC
	LDI	CB_BONUS_SYNC3,AR2
SBLS	BR	MESSAGE_ADD_SB

DECODE_BSYNC0:
;	LDI	0,R0
;	STI	R0,@OM_BSYNC
;	RETS
DECODE_BSYNC1:
;	LDI	1,R0
;	STI	R0,@OM_BSYNC
;	RETS
DECODE_BSYNC2:
;	LDI	2,R0
;	STI	R0,@OM_BSYNC
;	RETS
DECODE_BSYNC3:
	LDI	3,R0
	STI	R0,@OM_BSYNC
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
DECODE_CHANGE_MUSIC:
	LDI	*AR2++,R0

	LDI	@HEAD2HEAD_ON,R1
	RETSZ

	PUSH	AR2
	LS	8,R0
	RS	24,R0
	LDI	R0,AR2
	CALL	SET_TUNE_LINKED
	POP	AR2

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_CHANGE_MUSIC:
	LDI	@COMMQ_TMP_BUFFI,AR2
	LDI	CB_CHANGE_MUSIC,R0
	STI	R0,*AR2++

	LDI	@TUNE_IDX,R0
	STI	R0,*AR2--

	LDI	2-1,RC
	CALL	MESSAGE_ADD
	RETS
*----------------------------------------------------------------------------


	.bss	COINDROP,1
*----------------------------------------------------------------------------
DECODE_COINDROP:
	LDI	1,R0
	STI	R0,@COINDROP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_COINDROP:
	LDI	CB_COINDROP,AR2
	BR	MESSAGE_ADD_SB
*----------------------------------------------------------------------------


	fbss	OM_DIAGVALUE,1
	fbss	DIAGVALUE,1
*----------------------------------------------------------------------------
*For diagnostics on the Link we send a 'ping'
*the ping is echoed back with the upper nybble
*changed to reflect the machine type (MASTER
*or SLAVE... 'A0' or 'B0' respectively.
*
*
DECODE_DIAGNOSTIC:
	LDI	*AR2++,R0
	LS	8,R0
	ASH	-24,R0
	STI	R0,@OM_DIAGVALUE

	AND	0Fh,R0
	STI	R0,@DIAGVALUE
	CALL	SEND_DIAGNOSTIC
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_DIAGNOSTIC:
	LDI	@COMMQ_TMP_BUFFI,AR2
	LDI	CB_DIAGNOSTIC,R0
	STI	R0,*AR2++

	LDI	@DIAGVALUE,R0
	INC	R0
	STI	R0,@DIAGVALUE

	LDI	@DIPRAM,R0
	TSTB	CMDP_MASTER,R0
	LDINZ	0A0h,R1		;MASTER
	LDIZ	0B0h,R1		;SLAVE

	OR	R1,R0
	STI	R0,*AR2--

	LDI	2-1,RC
	BR	MESSAGE_ADD
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
DECODE_ATTRSND:
	PUSH	R0
	PUSH	AR2
	READADJ	ADJ_ATTRACT_MODE_SOUND
	CMPI	0,R0
	BEQ	NO_MUSIC
	SOND1	ATTR_THEME
NO_MUSIC
	POP	AR2
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SEND_ATTRSND:
	LDI	CB_ATTRSND,AR2
	BU	MESSAGE_ADD_SB
*----------------------------------------------------------------------------

	.END

