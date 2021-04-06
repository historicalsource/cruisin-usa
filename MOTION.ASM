	.FILE	"MOTION.ASM"
*----------------------------------------------------------------------------
*     
* 
*COPYRIGHT (C) 1994 BY	TV GAMES, INC.
*ALL RIGHTS RESERVED
*   
*
*
*Misc Notes:
*
*	The Galil board is unreliable under conditions of abort, and can
*	become confused.  To illustrate this point D/L a program, send a
*	HW Abort, then send an XQ command, and send a HW Abort.  We have been
*	able to repeatedly shut the Galil board down, so that it will not
*	respond (under normal AB circumstances even under abort, Galil will
*	still return a prompt).
*
*	We have to place the following redundancies into our code to assure
*	safe handling of the motion control:
*
*	1)	within the program the TL (torque limit) must be tested to
*		insure no runaway motors (test incombination of movement)
*	2)	check HW value for safety controls
*	3)	every thirty frames the Galil board is polled for abort status
*	4)	every sixty frames (when motion is OK) we must make sure
*		that we are receiving characters
*
*
*

	.include	MACS.EQU
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
	.include	DIAG.EQU



	.globl	CHECK_MOTION_DIP
	.globl	CHECK_MOTION_PRESENT

	.globl	CHECK_MOTION_DIP,CHECK_MOTION_PRESENT
MIN_MOVE_DIST	.set	200

	.bss	MOTION_NOT_ON,1
	.bss	MOTION_STOP_HIT,1
	.bss	MOTION_RCV_TIKS,1




	.text
*----------------------------------------------------------------------------
*This is the initial check of the galil board.
*The CMOS value will be set to ON if cool else OFF
*No other routine may turn it ON.
*No other routine will ever download or initialize galil
*This routine may only be called at powerup
*
*
*
*
INITIALIZATION_MOTION_CHECK:
	CALL	CLEAR_LATCH_ERROR

	LDI	1,R2
	SETAUD	ADJ_MOTION_PRESENT
	LDI	0,R2
	SETAUD	AUD_RESET_TOTALLY

	CALL	CHECK_MOTION_DIP
	RETSNZ

	LDI	1,RC
	TEXTITT	"MOTION SETUP TESTING...",1,250

        CALL    RESET_GALIL
        CALL    WAIT_ACK_REAL

	CALL	CHECK_MOTION_PRESENT
	BNE	INIT_MOTION_ERROROUT

;send it UP, for .5 inch  (1000)
;
	romdata

MINIT10	.string	"SP  15000, 15000, 15000",13,0
MINIT11	.string	"AC 105000,105000,105000",13,0
MINIT12	.string	"DC 435000,435000,435000",13,"TL 7,7,7",13,0
MINIT13	.string	"IT 0.1,0.1,0.1",13,0

MINIT9	.string	"SH;TL 7,7,7;ER 1000,1000,1000;OE 1,1,1;PR 4000,4000,4000;BG",13,0
MINIT9DIAG	.string	"SH;PR 4000,4000,4000;BG",13,0

MINIT1	.string	"OE 0,0,0;TL 5,5,5;JG 13000,13000,13000;BG;",13,0
MINITQX	.string	"MG ",34,"X",34,", _TSX {$2.0}",13,0
MINITQY	.string	"MG ",34,"Y",34,", _TSY {$2.0}",13,0
MINITQZ	.string	"MG ",34,"Z",34,", _TSZ {$2.0}",13,0

	.text

	;test limit switches if not found in 3 seconds shutdown
	;motion
	;
	;

	LDI	1,RC
	TEXTITT	"TESTING UPPER LIMITS",50,260

        LDL     MINIT10,AR2		;send init strings first
        CALL    SEND_CMD
        CALL    WAIT_ACK
        LDL     MINIT11,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK
        LDL     MINIT12,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK
        LDL     MINIT13,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK

	READAUD	ADJ_OUTOFDIAG
	CMPI	1,R0
	BNE	JAJA66
	LDL	MINIT9DIAG,AR2
	BU	JAJA887
JAJA66	LDL	MINIT9,AR2	;lift off the failsafes (PR 4000,4000,4000)
JAJA887	CALL    SEND_CMD
        CALL    WAIT_ACK


	
	LDI	100,AR3
GLLLT	CALL	WAIT_FOR_VBLANK
	DBU	AR3,GLLLT

	CALL	ABORT_RESET_GALIL


	;
	;check for safety errors
	;hold for 10 seconds until all errors
	;are cleared.
	;
SAFETY_ERROR_CHK

	LDI	57*10,AR3
MILOOP2
	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	AND	@CME_MASK,R0
	BZ	NO_ERRORMIL

	LDI	1,RC
	TEXTITT	"MOTION ERROR",50,270
	TEXTITT	"CLEAR MATS AND BEAM TO CONTINUE",50,280

	CALL	WAIT_FOR_VBLANK

	DBU	AR3,MILOOP2
	BU	INIT_MOTION_ERROROUT

	;
	;no safety errors, continue on
	;
NO_ERRORMIL

	LDI	2000,R0
	CALL	WAITMSEC

	CALL	ABORT_RESET_GALIL

	FILL	50,270,500,289,0

	LDL	MINIT1,AR2	;send it up
        CALL    SEND_CMD
        CALL    WAIT_ACK

	LDI	10,AR3
LLLT	CALL	WAIT_FOR_VBLANK
	DBU	AR3,LLLT

	LDI	-1,R0
	STI	R0,@GALIL_STATUS_X
	STI	R0,@GALIL_STATUS_Y
	STI	R0,@GALIL_STATUS_Z

	LDI	57*9,AR3
MILOOP1
	PUSH	AR3

	LDL	MINITQX,AR2	;query X
        CALL    SEND_CMD
        CALL    WAIT_ACK

	LDL	MINITQY,AR2	;query Y
        CALL    SEND_CMD
        CALL    WAIT_ACK

	LDL	MINITQZ,AR2	;query Z
        CALL    SEND_CMD
        CALL    WAIT_ACK
	POP	AR3

	CALL	WAIT_FOR_VBLANK

	;insert checking for limit switches
	;
	;

	LDI	@GALIL_STATUS_X,R0
	TSTB	08h,R0
	BNZ	NO_UP_LIM_YET
	LDI	@GALIL_STATUS_Y,R0
	TSTB	08h,R0
	BNZ	NO_UP_LIM_YET
	LDI	@GALIL_STATUS_Z,R0
	TSTB	08h,R0

	BZ	GOT_ALL_UPPERS
	;if all limit switches are activated, then exit

NO_UP_LIM_YET
	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	AND	@CME_MASK,R0
	BZ	NO_UP_SAFETY_ERROR
	BU	SAFETY_ERROR_CHK
	;check for mats or optos
	;start over if error

NO_UP_SAFETY_ERROR

	DBU	AR3,MILOOP1

	BU	UPPER_LIMIT_ERROR
	;here we would error out

GOT_ALL_UPPERS

	;check failsafes
	;
	;
	CALL	CHECK_MOTION_ERROR
	BC	INIT_MOTION_ERROROUT

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	AND	@CME_MASK,R0
	RS	8,R0
	AND	0F0h,R0
	CMPI	060h,R0
	BGE	INIT_MOTION_ERROROUT
	;
	;---> BR if FAILSAFES STILL ON
	;


	romdata
MINIT1L	.string	"SH;JG -13000,-13000,-13000;BG",13,0
	.text


	LDI	1,RC
	TEXTITT	"LOWER LIMIT TEST",250,260

	LDL	MINIT1L,AR2	;send it up
        CALL    SEND_CMD
        CALL    WAIT_ACK

	LDI	10,AR3
LLLLT	CALL	WAIT_FOR_VBLANK
	DBU	AR3,LLLLT

	;
	;check lower limits
	;
	LDI	57*9,AR3
MILOOP1LOW
	PUSH	AR3

	LDL	MINITQX,AR2	;query X
        CALL    SEND_CMD
        CALL    WAIT_ACK

	LDL	MINITQY,AR2	;query Y
        CALL    SEND_CMD
        CALL    WAIT_ACK

	LDL	MINITQZ,AR2	;query Z
        CALL    SEND_CMD
        CALL    WAIT_ACK
	POP	AR3

	CALL	WAIT_FOR_VBLANK

	;insert checking for limit switches
	;
	;

	LDI	@GALIL_STATUS_X,R0
	TSTB	04h,R0
	BNZ	NO_LO_LIM_YET
	LDI	@GALIL_STATUS_Y,R0
	TSTB	04h,R0
	BNZ	NO_LO_LIM_YET
	LDI	@GALIL_STATUS_Z,R0
	TSTB	04h,R0
	BZ	GOT_ALL_LOWERS
	;if all limit switches are activated, then exit

NO_LO_LIM_YET

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	AND	@CME_MASK,R0
	BZ	NO_LO_SAFETY_ERROR
	BU	SAFETY_ERROR_CHK
	;check for mats or optos
	;start over if error

NO_LO_SAFETY_ERROR

	DBU	AR3,MILOOP1LOW

	BU	LOWER_LIMIT_ERROR
	;here we would error out

GOT_ALL_LOWERS

	;
	;initialize the stuff
	;

        LDL     PP,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK

	CALL	CHECK_MOTION_PRESENT
	BNE	INIT_MOTION_ERROROUT


	LDI	57*3,AR3
LLLTA	CALL	WAIT_FOR_VBLANK
	DBU	AR3,LLLTA


        LDL     PP1,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK
        LDL     PP2,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK
        LDL     PP3,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK
        LDL     PP4,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK


	;hang out for a moment
	CALL	WAIT_FOR_VBLANK



	;
	;now dl the program.
	;
	CALL	CLEAR_LATCH_ERROR
	CALL	ABORT_RESET_GALIL
	CALL	MOTION_DLPROG

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	AND	@CME_MASK,R0
	BNZ	INIT_MOTION_ERROROUT

	LDI	@LATCHED_ERROR,R0
	BNZ	INIT_MOTION_ERROROUT

	;
	;execute the program
	;we are now guarenteed to be cool
	;

	FILL	1,250,500,350,0
	LDI	1,RC
	TEXTITT	"MOTION SYSTEM OK",300,240

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*an intialization error has occurred:
*	shutdown and dont use the galil
*
*

	romdata

;MOTOROFF	.string	"ST;MO",13,0
;MOTOROFF	.string	"ST",13,0
;MOTOROFF	.string	"TL 0.6,0.6,1.8;JG 90000,90000,90000;BG;WT 4000;TL 0.5,0.5,1.6;WT 4000;TL 0.3,0.3,1.4;WT 4000;ST XYZ;MO",13,0
;
;MOTOROFF1	.string	"TL 0.6,0.6,1.8;JG 90000,90000,90000;BG",13,0
;MOTOROFF2	.string	"TL 0.5,0.5,1.6;WT 3000;TL 0.4,0.4,1.4;WT 3000;TL 0.3,0.3,1.2",13,0
;MOTOROFF3	.string	"TL 0.2,0.2,1.0;WT 3000;TL 0.1,0.1,0.8;WT 3000;TL 0.0,0.0,0.6",13,0
;MOTOROFF4	.string	"ST XYZ;MO",13,0
;MOTOROFF4	.string	0
;
MOTOROFF0	.string	"JG 90000,90000,90000;BG;TL 0.6,0.6,1.8",13,0
MOTOROFF1	.string	"TL 0.55,0.55,1.7;WT 1000",13,0
MOTOROFF2	.string	"TL 0.50,0.50,1.6;WT 1000",13,0
MOTOROFF3	.string	"TL 0.45,0.45,1.5;WT 1000",13,0
MOTOROFF4	.string	"TL 0.40,0.40,1.4;WT 1000",13,0
MOTOROFF5	.string	"TL 0.35,0.35,1.3;WT 1000",13,0
MOTOROFF6	.string	"TL 0.30,0.30,1.2;WT 1000",13,0
MOTOROFF7	.string	"TL 0.25,0.25,1.1;WT 1000",13,0
MOTOROFF8	.string	"TL 0.20,0.20,1.0;WT 1000",13,0
MOTOROFF9	.string	"TL 0.15,0.15,0.9;WT 1000",13,0
MOTOROFF10	.string	"TL 0.10,0.10,0.8;WT 1000",13,0
MOTOROFF11	.string	"TL 0.05,0.05,0.7;WT 1000",13,0
MOTOROFF12	.string	"ST XYZ;MO",13,0

MOTOFF_PROG
	.word	MOTOROFF1
	.word	MOTOROFF2
	.word	MOTOROFF3
	.word	MOTOROFF4
	.word	MOTOROFF5
	.word	MOTOROFF6
	.word	MOTOROFF7
	.word	MOTOROFF8
	.word	MOTOROFF9
	.word	MOTOROFF10
	.word	MOTOROFF11
	.word	MOTOROFF12
	.word	0

	.text

	.globl	SEND_MOTOR_OFF
SEND_MOTOR_OFF:
        CALL    RESET_GALIL
        CALL    WAIT_ACK_REAL

	;bong sound
	LDI	984,AR2
	CALL	SENDSND
 
	;2.5 sec delay
	LDI	2500,R0
	CALL	WAITMSEC

	LDL	MOTOROFF12,AR2
	CALL	SEND_CMD
        CALL    WAIT_ACK
	RETS


SEND_MOTOR_OFF_NO_RESET:

	LDL	MOTOROFF0,AR2
	CALL	SEND_CMD
	CALL    WAIT_ACK

	FILL	1,200,500,390,0

	LDI	500,R0			;WAIT
	CALL	WAITMSEC

	LDL	MOTOFF_PROG,AR4
MOTOFF_LOOP

	LDI	1,RC
	TEXTITT	"SLOWLY TURNING OFF MOTORS",1,200

	LDI	984,AR2			;BONG
	CALL	SENDSND
					
	LDI	2000,R0			;WAIT
	CALL	WAITMSEC
					
	LDI	*AR4++,AR2		;SEND NEXT TORQUE LEVEL
	CMPI	0,AR2
	BEQ	MOTOFF_DONE		
	CALL	SEND_CMD		
	CALL	WAIT_ACK		
					
	FILL	1,200,500,390,0		;CLEAR MESSAGE

	LDI	500,R0			;WAIT
	CALL	WAITMSEC
					
	LDI	*AR4++,AR2		;SEND NEXT TORQUE LEVEL
	CMPI	0,AR2
	BEQ	MOTOFF_DONE		
	CALL	SEND_CMD		
	CALL	WAIT_ACK		
	BU	MOTOFF_LOOP		

MOTOFF_DONE				
	FILL	1,200,500,390,0
	RETS



INIT_MOTION_ERROROUT:

	CALL    SEND_MOTOR_OFF_NO_RESET

	CLRI	R2
	SETAUD	ADJ_MOTION_PRESENT

	;show message on screen
	;

	FILL	1,250,500,350,0
	LDI	4,AR5
GDLPAA	LDI	1,RC
	TEXTITT	"MOTION SYSTEM HAS ERRORS",100,250
	TEXTITT	"MOTION SYSTEM DEACTIVATED",100,260
	LDI	984,AR2
	CALL	SENDSND

	LDI	450,R0
	CALL	WAITMSEC

	FILL	1,250,500,350,0

	LDI	150,R0
	CALL	WAITMSEC
	DBU	AR5,GDLPAA

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	RS	12,R0		;right justify
	AND	0Fh,R0


	CMPI	8,R0
	BLT	NNE1
	LDI	1,RC
	TEXTITT	"BOARD NOT PLUGGED IN",100,250
	BU	FFFD
NNE1

	LDI	R0,AR2
	ADDI	@BABAID,AR2
	LDI	*AR2,AR2
	LDI	1,RC
	LDI	100,R2
	LDI	250,R3
	CALL	_outtextxyc
FFFD

	LDI	3000,R0
	CALL	WAITMSEC
	FILL	1,250,500,350,0
	RETS
BABAID	.word	JJG
	romdata
JJG	.word	MM0,MM1,MM2,MM3,MM4,MM5,MM6,MM7
MM0	.string	"UNKNOWN ERROR",0
MM1	.string	"MAT NOT PLUGGED IN",0
MM2	.string	"MAT STEPPED ON",0
MM3	.string	"SAFETY BEAM PATH BROKEN",0
MM4	.string	"SAFETY BEAM DETECTOR NOT RECEIVING",0
MM5	.string	"SAFETY BEAM LIGHT NOT EMITTING",0
MM6	.string	"FAIL SAFE SWITCH ENGAGED",0
MM7	.string	"FAIL SAFE SWITCH NOT CONNECT PROPERLY",0
	;maybe reported as 'error 48'
	.text
*----------------------------------------------------------------------------



;if EVER failsafe problem MOTOR OFF
	;now message on screen
	;countdown 10 seconds
	;if in 10 seconds error not cleared
	;no motion for game
;move it up
;read status
;check for upper limit switches
;if not found in 3 seconds shut down NO MOTION
;check failsafes and all errors
;if failsafes still engaged msg "NO MOTION FOR THIS GAME"
;other safety error  10 seconds to clear if not clear NO MOTION FOR GAME
;dl the program
;has error been latched?
;F->continue
;T->dl program again if > 2x than NO MOTION
;xq the program

;if ST from galil (during gameplay) MOTION OFF until reset
;	hit the ABORT LINE ???
;	stop sending commands
;TS
*----------------------------------------------------------------------------




bbd	.string	"MOTION BURNIN",0
*----------------------------------------------------------------------------
*
*WAIT 500
*
WAIT500:
;	RPTS	490
	RPTS	100
	NOP
	PUSH	R0
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MDIAG,R0
	BNE	WT500X
	CALL	FEED_WATCHDOG 	;FEED THE DOG WHEN IN DIAGNOSTICS
WT500X
	POP	R0
	RETS
*----------------------------------------------------------------------------
*
*CHECK FOR MOTION DIPSWITCH
*RET NE IF MOTION DIPSWITCH OFF
*
CHECK_MOTION_DIP:
	PUSH	AR2
	CLRI	AR2
	LDP	@DIPSW
	LDI	@DIPSW,R0	;READ DIPSWITCH
	LDI	*AR2,AR2
	POP	AR2
	RS	16,R0
	SETDP
	TSTB	DIP_MOTION,R0	;MOTION CABINET?
	RETS
*
*CHECK IF MOTION PRESENT
*RET NE IF MOTION NOT PRESENT
*
CHECK_MOTION_PRESENT:
	READAUD	ADJ_MOTION_PRESENT
	CMPI	1,R0
 	RETS

DIAG_MOTION_TESTZ:
	LDI	1,IR1
	BU	MOTION_BURNIN_J
DIAG_MOTION_TESTX:
	LDI	2,IR1
	BU	MOTION_BURNIN_J
DIAG_MOTION_TESTY:
	LDI	4,IR1
	BU	MOTION_BURNIN_J

DIAG_MOTION_BURNIN:
	LDI	7,IR1

MOTION_BURNIN_J
	CALL	CHECK_MOTION_DIP
	BNZ	GALIL_ERR1		;RETURN IF NON MOVING


	CALL	CHECK_MOTION_PRESENT
	BNE	GALIL_ERROR

;	CALL	INITIALIZE_GALIL
	CALL	INITIALIZATION_MOTION_CHECK

	CALL	CHECK_MOTION_PRESENT
	BNE	GALIL_ERROR
	
	CALL	CLRSCRN
	CALL	SETPAGE0

	LDIL	SCREEN0,R0		;set active screen to 1 (writeable)
	STPI	R0,@ACTIVE_SCREEN

	CLRI	AR4			;page index

	LDI	DEFAULT_COLOR,RC
	TEXTIT	bbd,50,330

	CLRF	R5
	CLRF	R6
	CLRF	R7
MBI_LP

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP
	RS	8,R0
	LS	24,R0
	CMPI	0,R0
	BEQ	JAJA
	.globl	MOTION_SAFETY_SWITCHES_DIAG
	CALL	MOTION_SAFETY_SWITCHES_DIAG
	BU	ENTER_DIAG
JAJA


	TSTB	1,IR1
	BZ	JJ5

	ADDFL	0.03,R5
	CMPF	TWOPI,R5
	BLT	JJ5
	SUBF	TWOPI,R5
JJ5
	TSTB	2,IR1
	BZ	JJ6

	ADDFL	0.05,R6
	CMPF	TWOPI,R6
	BLT	JJ6
	SUBF	TWOPI,R6
JJ6
	TSTB	4,IR1
	BZ	JJ7

	ADDFL	0.04,R7
	CMPF	TWOPI,R7
	BLT	JJ7
	SUBF	TWOPI,R7
JJ7
	LDF	R7,R2
	PUSHFL	R5
	PUSHFL	R6
	PUSHFL	R7
	CALL	_HPsin
	LDF	R0,R4
	POPFL	R7
	POPFL	R6
	POPFL	R5

	LDF	R6,R2
	PUSHFL	R4
	PUSHFL	R5
	PUSHFL	R6
	PUSHFL	R7
	CALL	_HPsin
	LDF	R0,R3
	POPFL	R7
	POPFL	R6
	POPFL	R5
	POPFL	R4

	LDF	R5,R2
	PUSHFL	R3
	PUSHFL	R4
	PUSHFL	R5
	PUSHFL	R6
	PUSHFL	R7
	CALL	_HPsin
	LDF	R0,R2
	POPFL	R7
	POPFL	R6
	POPFL	R5
	POPFL	R4
	POPFL	R3


	PUSHFL	R5
	PUSHFL	R6
	PUSHFL	R7
	;R2	front
	;R3	left
	;R4	right
	;

	;-1>=x>=1
	MPYF	0.8,R2
	MPYF	0.8,R3
	MPYF	0.8,R4

	;-.8>=x>=.8

	CALL	MOTION_SCALE_ENTER
	CALL	WAIT_FOR_VBLANK
	POPFL	R7
	POPFL	R6
	POPFL	R5

	LDI	@_newbut,R0
	LDI	R0,R1
	TSTB	SW_DIAG,R1		;move up
	BNZ	MBI_LP

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PLAYER CABINET MOTION
*
*PARAMETERS
*	AR4	PLAYER CAR OBJECT
*	AR5	PLAYER CAR STRUCTURE
*
*CONTROL AXES:
*		X=LFT REAR 0=GROUND, 50000=FULL HEIGHT
*		Y=RT REAR  0=GROUND, 50000=FULL HEIGHT
*		Z=FRONT	   0=GROUND, 50000=FULL HEIGHT
*
PLMOTION:
	CALL	CHECK_MOTION_DIP
	RETSNZ			;RETURN IF NON MOVING


	LDI	@MOTION_STOP_HIT,R0
	RETSNZ


	;
	;check for an abort
	;

	LDI	@ABORT_QUERY,R0
	DEC	R0
	STI	R0,@ABORT_QUERY
	BGT	NOCHECK

	LDI	30,R0
	STI	R0,@ABORT_QUERY
	LDL	ABORTQ,AR2
	CALL	SEND_CMD
	CALL	WAIT_ACK
NOCHECK

	.bss	ABORT_QUERY,1
	romdata
ABORTQ	.string	"#IBO;IBO=_SCX|_SCY|_SCZ;MG ",34,"V",34," IBO {$2.0}",13,0
	.text




	;
	;MOTION SAFETY CODE
	;

MOTION_ERROR_TIKS	.set	(57*5)
	.globl	WAITTIK
	.bss	WAITTIK,1

	LDI	@WAITTIK,R0			;is counter in a previous 5 second wait?
	BZ	NO_PREVMOTION_ERRORS		;br -> NO, continue error checking

	LDI	1,R1
	STI	R1,@MOTION_SAFETY_ON

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R2
	LDI	*AR2,AR2
	SETDP
	LDL	0FF80h,R1
	AND	R1,R2
	BZ	NO_NEW_MOTION_ERRORS

	LDI	MOTION_ERROR_TIKS,R1
	STI	R1,@WAITTIK
	RETS


NO_NEW_MOTION_ERRORS
	SUBI	@NFRAMES,R0
	LDILT	0,R0
	STI	R0,@WAITTIK

	CMPI	0,R0
	RETSGT

	;here is where we want to test to see if we are done with the error
	;and how we are to recover

	CALL	ABORT_RESET_GALIL		;recover latch from mark

	CLRI	AR2
	LDP	@991030h	;IF we have a motion error after
	LDI	@991030h,R0	;we attempted to reset, THEN
	LDI	*AR2,AR2
	SETDP			;try again next frame
	LDL	0FF80h,R1	;
	AND	R1,R0		;
	RETSNZ			;

;	CALL	MOTION_DLPROG

RESETMOTIONANYWAY
	.globl	XQ,SEND_CMD,WAIT_ACK
	LDL	XQ,AR2				;tell galil to continue executing program
	CALL	SEND_CMD
	CALL	WAIT_ACK

	CLRI	R0
	STI	R0,@MOTION_SAFETY_ON

;	LDI	300,R0
;	STI	R0,@MOTION_RCV_TIKS

	RETS


NO_PREVMOTION_ERRORS


;	LDI	@LATCHED_ERROR,R0
;	BZ	NONELAT
;
;	CALL	CLEAR_LATCH_ERROR
;	CALL	ABORT_RESET_GALIL		;recover latch from mark
;	CALL	MOTION_DLPROG
;	
;	BU	RESETMOTIONANYWAY
;NONELAT


	;IF galil is NOT responding
	;attempt to reset serious
	;
	LDI	@MOTION_RCV_TIKS,R0
	BGT	NOTTLRST


	LDI	1,R2
	SETAUD	AUD_RESET_TOTALLY

	LDI	0,R2
	SETAUD	ADJ_MOTION_PRESENT
	RETS

;
;	CALL    RESET_GALIL
;	CALL    WAIT_ACK_REAL
;
;
;	LDS	"JG -26000,-2,AR2
;	CALL    SEND_CMD
;	CALL    WAIT_ACK
;
;	CALL	CHECK_MOTION_PRESENT
;	BEQ	KKGK
;
;	LDI	1,R2
;	SETAUD	ADJ_MOTION_PRESENT
	RETS
KKGK
	LDL     PP1,AR2
	CALL    SEND_CMD
	CALL    WAIT_ACK
	LDL     PP2,AR2
	CALL    SEND_CMD
	CALL    WAIT_ACK
	LDL     PP3,AR2
	CALL    SEND_CMD
	CALL    WAIT_ACK
	LDL     PP4,AR2
	CALL    SEND_CMD
	CALL    WAIT_ACK

	;
	;dl the program.
	;
	CALL	CLEAR_LATCH_ERROR
	CALL	MOTION_DLPROG

	LDI	300,R0
	STI	R0,@MOTION_RCV_TIKS
NOTTLRST


	.globl	MOTION_SAFETY_ON
	.bss	MOTION_SAFETY_ON,1
	.globl	MOTION_SAFETY_TYPE
	.bss	MOTION_SAFETY_TYPE,1

	CLRI	AR2
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR2,AR2
	SETDP

	LDL	0FF80h,R1
	AND	R1,R0
	BZ	NO_MOTION_ERRORS


	;we do have an error
	;
	LDI	MOTION_ERROR_TIKS,R1
	STI	R1,@WAITTIK
	LDI	1,R1
	STI	R1,@MOTION_SAFETY_ON

	LDI	R0,R2
	RS	12,R2
	AND	0Fh,R2
	LDI	0,R3	;assume its a mat

	CMPI	3,R2
	LDIEQ	1,R3
	CMPI	4,R2
	LDIEQ	1,R3
	CMPI	5,R2
	LDIEQ	1,R3

	CMPI	6,R2
	LDIEQ	2,R3
	CMPI	7,R2
	LDIEQ	2,R3
	STI	R3,@MOTION_SAFETY_TYPE


	LDI	R0,R1
	RS	16,R1
	RETSC					;BOARD NOT PLUGGED IN OR PAL NOT INSTALLED -> DONT DO ANYTHING

	TSTB	080h,R0				;MOTION STOP IF HELD DOWN -> DONT DO ANYTHING
	BZ	NOTTHIS

	LDI	3,R0
	STI	R0,@MOTION_SAFETY_TYPE

	LDI	1,R0
	STI	R0,@MOTION_STOP_HIT

	romdata
MSSM	.string	"MOTION STOP BUTTON HIT",0
	.text
	LDL	MSSM,AR2
	FLOAT	256,R2
	FLOAT	310,R3
	LDI	57*3,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)

	RETS

NOTTHIS
KDS

NO_MOTION_ERRORS




	LDI	@MOTION_NOT_ON,R0
	RETSNZ

	CALL	CHECK_MOTION_PRESENT
	RETSNE
	
	LDF	*+AR5(RF_PY),R5
	ADDF	*+AR5(LF_PY),R5

	ADDF	*+AR5(LR_PY),R5
	ADDF	*+AR5(RR_PY),R5
	MPYF	0.25,R5


*FIND AVERAGE Y POSITION = R5

	LDF	*+AR5(RF_PY),R2
	ADDF	*+AR5(LF_PY),R2
	MPYF	0.5,R2

	LDF	*+AR5(LR_PY),R3
	LDF	*+AR5(RR_PY),R4


*GET Y HEIGHT DELTA TO CENTER


	SUBRF	R5,R2		;Z (FRONT) AXIS DELTA
	SUBRF	R5,R3		;X (LREAR) AXIS DELTA
	SUBRF	R5,R4		;Y (RREAR) AXIS DELTA

	FLOAT	150,R0		;DIVIDE BY RADIUS FOR PROPORTIONALITY
	CALL	INV_F30


*COMPUTE EQUATION M=2X-X*X/150
	LDF	2,R1
	MPYF	R1,R2,R5   	;2*Z
	MPYF	R2,R2
	MPYF	R0,R2
	SUBF	R2,R5,R2
	MPYF	R0,R2

	MPYF	R1,R3,R5   	;2*X
	MPYF	R3,R3
	MPYF	R0,R3
	SUBF	R3,R5,R3
	MPYF	R0,R3

	MPYF	R1,R4,R5   	;2*Y
	MPYF	R4,R4
	MPYF	R0,R4
	SUBF	R4,R5,R4
	MPYF	R0,R4




;	MPYF	R0,R2
;	MPYF	R0,R3
;	MPYF	R0,R4
;
	CMPF	0.9,R2		;RESTRICT RANGE TO -0.9->0.9
	LDFGT	0.9,R2
	CMPF	-0.9,R2
	LDFLT	-0.9,R2

	CMPF	0.9,R3		;RESTRICT RANGE TO -0.9->0.9
	LDFGT	0.9,R3
	CMPF	-0.9,R3
	LDFLT	-0.9,R3

	CMPF	0.9,R4		;RESTRICT RANGE TO -0.9->0.9
	LDFGT	0.9,R4
	CMPF	-0.9,R4
	LDFLT	-0.9,R4

*GET LEAN ANGLES 20% OF MOTION (10% OF MOTION RESERVED)

*FRONT-BACK (XLEAN)

	LDF	*+AR5(CARXLEAN),R1		;RADIAN LEAN -0.1->0.1

	MPYF	6,R1

	ADDF	R1,R3
	ADDF	R1,R4
	SUBF	R1,R2

*LEFT-RIGHT (ZLEAN)
	
	LDF	*+AR5(CARZLEAN),R1    	;RADIAN LEAN -0.1->0.1

	MPYF	6,R1

	ADDF	R1,R4
	SUBF	R1,R3

*LIMIT MOTION +-1.0

	CMPF	1.0,R2
	LDFGT	1.0,R2
	CMPF	1.0,R3
	LDFGT	1.0,R3
	CMPF	1.0,R4
	LDFGT	1.0,R4

	CMPF	-1.0,R2
	LDFLT	-1.0,R2
	CMPF	-1.0,R3
	LDFLT	-1.0,R3
	CMPF	-1.0,R4
	LDFLT	-1.0,R4

*SEND STUFF TO MOTION PLATFORM

*R2=Z FRONT		-1.0->1.0
*R3=X LFT REAR		-1.0->1.0
*R4=Y RT REAR		-1.0->1.0







MOTION_SCALE_ENTER:



	;NOW SCALE INTO THE RANGE USEABLE
	;BY OR MOTION SYSTEM
	;
	FLOAT	17000,R1
	MPYF	R1,R2
	MPYF	R1,R3
	MPYF	R1,R4
	FLOAT	26000,R1
	ADDF	R1,R2
	ADDF	R1,R3
	ADDF	R1,R4

	FIX	R2
	FIX	R3
	FIX	R4
JAJA555


	.bss	sPOTVALUE,15
	.bss	MOTION_CMDSTR,80

	.bss	LAST_ZF,1
	.bss	LAST_XL,1
	.bss	LAST_YR,1


	PUSH	R3
	PUSH	R4

;	PUSHFL	R3
;	PUSHFL	R4

	LDI	@LAST_ZF,R1
	SUBI	R2,R1
	ABSI	R1
	CMPI	MIN_MOVE_DIST,R1
	BLT	N76

	STI	R2,@LAST_ZF
	LDL	sPOTVALUE,AR2
	CALL	_itoa

	LDL	PZC1,AR0
	LDL	MOTION_CMDSTR,AR1
	CALL	STRCPY

	LDL	MOTION_CMDSTR,AR0
	LDL	sPOTVALUE,AR1
	CALL	STRCAT

	LDL	MOTION_CMDSTR,AR0
	LDL	PZC2,AR1
	CALL	STRCAT

	LDI	AR0,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK

N76
	POP	R2		;RT REAR (Y)
	LDI	@LAST_YR,R1
	SUBI	R2,R1
	ABSI	R1
	CMPI	MIN_MOVE_DIST,R1
	BLT	N77

	STI	R0,@LAST_YR

	LDL	sPOTVALUE,AR2
	CALL	_itoa

	LDL	PYC1,AR0
	LDL	MOTION_CMDSTR,AR1
	CALL	STRCPY

	LDL	MOTION_CMDSTR,AR0
	LDL	sPOTVALUE,AR1
	CALL	STRCAT

	LDL	MOTION_CMDSTR,AR0
	LDL	PYC2,AR1
	CALL	STRCAT
	LDI	AR0,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK

N77
	POP	R2		;LT REAR (X)

	LDI	@LAST_XL,R1
	SUBI	R2,R1
	ABSI	R1
	CMPI	MIN_MOVE_DIST,R1
	BLT	N78

	STI	R0,@LAST_XL

	LDL	sPOTVALUE,AR2
	CALL	_itoa

	LDL	PXC1,AR0
	LDL	MOTION_CMDSTR,AR1
	CALL	STRCPY

	LDL	MOTION_CMDSTR,AR0
	LDL	sPOTVALUE,AR1
	CALL	STRCAT

	LDL	MOTION_CMDSTR,AR0
	LDL	PXC2,AR1
	CALL	STRCAT
	LDI	AR0,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK
N78
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
LEVEL_THE_MOTION:
	CALL	CHECK_MOTION_DIP
	RETSNZ			;RETURN IF NON MOVING

	CALL	CHECK_MOTION_PRESENT
	RETSNE

;	LDF	-1.26,R2
;	LDF	-1.26,R3
;	LDF	-1.26,R4
;	BU	MOTION_SCALE_ENTER

	LDI	0,R2
	STI	R2,@LAST_ZF
	LDL	sPOTVALUE,AR2
	CALL	_itoa

	LDL	PZC1,AR0
	LDL	MOTION_CMDSTR,AR1
	CALL	STRCPY

	LDL	MOTION_CMDSTR,AR0
	LDL	sPOTVALUE,AR1
	CALL	STRCAT

	LDL	MOTION_CMDSTR,AR0
	LDL	PZC2,AR1
	CALL	STRCAT

	LDI	AR0,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK


	LDI	0,R2		;RT REAR (Y)
	LDL	sPOTVALUE,AR2
	CALL	_itoa

	LDL	PYC1,AR0
	LDL	MOTION_CMDSTR,AR1
	CALL	STRCPY

	LDL	MOTION_CMDSTR,AR0
	LDL	sPOTVALUE,AR1
	CALL	STRCAT

	LDL	MOTION_CMDSTR,AR0
	LDL	PYC2,AR1
	CALL	STRCAT
	LDI	AR0,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK

	CLRI	R2		;LT REAR (X)
	LDL	sPOTVALUE,AR2
	CALL	_itoa

	LDL	PXC1,AR0
	LDL	MOTION_CMDSTR,AR1
	CALL	STRCPY

	LDL	MOTION_CMDSTR,AR0
	LDL	sPOTVALUE,AR1
	CALL	STRCAT

	LDL	MOTION_CMDSTR,AR0
	LDL	PXC2,AR1
	CALL	STRCAT
	LDI	AR0,AR2
        CALL    SEND_CMD
        CALL    WAIT_ACK

	RETS
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------

SH	.string	"SH;JG 10000,10000,10000;BG",13,0


THEPROGL
	.word	EDIT,T5,T6,T7,T8,T9
	.word	T10,T11,T12,T13,T14,T15,T16,T17,T18,T19
	.word	T20,T21,T22,T23,T24,T25,T26,T27,T28,T29
	.word	T30,T31,T32,T33,T34,T35,T36,T37,T38,T39
	.word	T40,T41,T42,T43,T44,T45,T46,T47,T48,T49
	.word	T50,T51,T52,T53,T54,T55,T56,T57,T58,T59
	.word	T60

;	.word	T60,T1,T2,T3,T4,T61,T63,T64,T65,0
;	.word	T60,T1,T2,T3,T4,T61,T62,T63,T64,T65,0

	.word	T1,T2,T3
	.word	T66X,T67X,T68X
	.word	T66Y,T67Y,T68Y
	.word	T66Z,T67Z,T68Z
	.word	T69
	.word	T70,T71,T72,T73,T74,T75,T76,T77,T78,T79
	.word	T80,T81,T82,T83,T84
	.word	0

;INITPROGL
;	.word	EDIT,T5,T6,T7,T8,T9
;	.word	T10,T11,T13,T14,T15,T16,T17,T18,T19
;	.word	T20,T21,T22,T23,T25,T26,T27,T28,T29
;	.word	T30,T31,T32,T33,T34,T35,T36,T37,T38,T39
;	.word	T40,T41,T42,T43,T44,T45,T46,T47,T48,T49
;	.word	T50,T51,T52,T53,T54,T55,T56,T57,T58,T59
;	.word	T60
;
;	.word	T1,T2,T3
;	.word	T66,T67,T68,T69
;	.word	T70,T71,T72,T73,T74,T75,T76,T77,T78,T79
;	.word	T80,T81,T82,T83,T84
;	.word	0
;

*----------------------------------------------------------------------------
DOWNLOAD_PROGRAM:

IBO654
	LDI	*AR4++,AR2
	CMPI	0,AR2
	BEQ	DNF
	CALL	SEND_CMD
	CALL	WAIT_ACK	;#

	CALL	WAIT_FOR_VBLANK

	BU	IBO654
DNF
	LDL	ENDED,AR2
	CALL	SEND_CMD
	CALL	WAIT_ACK	;:

	LDL	XQ,AR2
	CALL	SEND_CMD
	CALL	WAIT_ACK
;
;eric, is this correct? - ml
;
;	LDL	T10,AR2		;;set actuators
;	CALL	SEND_CMD
;	CALL	WAIT_ACK
;
;	LDL	T11,AR2
;	CALL	SEND_CMD
;	CALL	WAIT_ACK
;
;	LDL	T12,AR2
;	CALL	SEND_CMD
;	CALL	WAIT_ACK

	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*SEND COMMAND TO GALIL MOTION CONTROL BOARD
*
*
*FF09
*F709
*FF09
*
*FF00
*FB00
*FF00
*
*
*PARAMETERS
*	AR2	PTR TO STR
*
*
SEND_CMD:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	DINT

	LDIL	SOUND,AR3
	LDI	0FF09h,R0
	LDI	0F709h,R1
	STI	R0,*AR3
	CALL	WAIT500
	STI	R1,*AR3
	CALL	WAIT500
	STI	R0,*AR3
	CALL	WAIT500


	LDI	0FF00h,R2
	LDI	0FB00h,R3



	CLRI	R5		;SHIFT COUNT
LLKK	CMPI	-32,R5
	BNE	REGLP
	CLRI	R5
	NOP	*AR2++
REGLP
	LDI	*AR2,R4
	LSH	R5,R4
	SUBI	8,R5
	AND	0FFh,R4
	CMPI	0,R4
	BZ	KKKII


	OR	R4,R2,R6
	OR	R4,R3,R7
	STI	R6,*AR3
	CALL	WAIT500
	STI	R7,*AR3
	CALL	WAIT500
	STI	R6,*AR3
	CALL	WAIT500
	BU	LLKK
KKKII

	EINT
	POP	R7
	POP	R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
RESET_GALIL:
	DINT
        LDIL    SOUND,AR3
        LDI     0FF0Ch,R0
        LDI     0F70Ch,R1

        STI     R0,*AR3
        CALL	WAIT500
        STI     R1,*AR3
        CALL	WAIT500
        STI     R0,*AR3
        CALL	WAIT500


        LDI     0FF00h,R0
        LDI     0FB00h,R1
        STI     R0,*AR3
        CALL	WAIT500
        STI     R1,*AR3
        CALL	WAIT500
        STI     R0,*AR3
        CALL	WAIT500


        LDI     0FF0bh,R0
        LDI     0F70bh,R1
        STI     R0,*AR3
        CALL	WAIT500
        STI     R1,*AR3
        CALL	WAIT500
        STI     R0,*AR3
        CALL	WAIT500


        LDI     0FF00h,R0
        LDI     0FB00h,R1
        STI     R0,*AR3
        CALL	WAIT500
        STI     R1,*AR3
        CALL	WAIT500
        STI     R0,*AR3
        CALL	WAIT500
	EINT

        RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*
*clear the abort (restore communication to galil)
*
*
	.globl	ABORT_RESET_GALIL
ABORT_RESET_GALIL:
	DINT
        LDIL    SOUND,AR3

	;
	;in essence we are clearing the abort, but NOT reseting galil
	;

        LDI     0FF0eh,R0	;  0Ch = reset bit addr
        LDI     0F70eh,R1	;  0Eh = abort/reset bit addr
        STI     R0,*AR3
        CALL	WAIT500
        STI     R1,*AR3
        CALL	WAIT500
        STI     R0,*AR3
        CALL	WAIT500


        LDI     0FF00h,R0
        LDI     0FB00h,R1
        STI     R0,*AR3
        CALL	WAIT500
        STI     R1,*AR3
        CALL	WAIT500
        STI     R0,*AR3
        CALL	WAIT500
	EINT


	LDL	XQ,AR2				;tell galil to continue executing program
	CALL	SEND_CMD
	CALL	WAIT_ACK


        RETS
*----------------------------------------------------------------------------



	.globl	DIAG_MOTION_TESTX,DIAG_MOTION_TESTY,DIAG_MOTION_TESTZ
	.globl	DIAG_MOTION_BURNIN


*----------------------------------------------------------------------------
MOTION_DLPROG:
	CALL	CHECK_MOTION_DIP
	RETSNZ			;RETURN IF NON MOVING

	CALL	CHECK_MOTION_PRESENT
	RETSNE

	LDL	THEPROGL,AR4
	CALL	DOWNLOAD_PROGRAM

	CLRI	R0
	STI	R0,@LAST_ZF
	STI	R0,@LAST_XL
	STI	R0,@LAST_YR

	CLRI	R0
	STI	R0,@MOTION_NOT_ON
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*MOTION DIPSWITCH OFF
GALIL_ERR1
	CALL	SETPAGE0
	LDIL	SCREEN0,R0
	STI	R0,@ACTIVE_SCREEN

	LDI	2,AR5
GDLP
	LDI	0,RC
	TEXTITT	"WARNING MOTION DIP SWITCH OFF",150,130

	LDI	250,R0
	CALL	WAITMSEC

	LDI	COL_WHITE,RC
	TEXTITT	"WARNING MOTION DIP SWITCH OFF",150,130

	LDI	984,AR2
	CALL	SENDSND

	LDI	250,R0
	CALL	WAITMSEC
	DBU	AR5,GDLP

	RETS

*MOTION NO DETECTED
GALIL_ERROR:

;	.globl	MOTION_SAFETY_SWITCHES_DIAG
;	CALL	MOTION_SAFETY_SWITCHES_DIAG
;	BU	ENTER_DIAG


;	CALL	CLRSCRN
	CALL	SETPAGE0
	LDIL	SCREEN0,R0
	STI	R0,@ACTIVE_SCREEN

	LDI	2,AR5
GLP
	LDI	0,RC
	TEXTITT	"WARNING MOTION NOT DETECTED",150,130

	LDI	250,R0
	CALL	WAITMSEC

	LDI	COL_WHITE,RC
	TEXTITT	"WARNING MOTION NOT DETECTED",150,130

	LDI	984,AR2
	CALL	SENDSND

	LDI	250,R0
	CALL	WAITMSEC
	DBU	AR5,GLP

	RETS
*
*WAIT R0 X MSEC
*
WAITMSEC
	MPYI	5000,R0
WTMLP
	SUBI	1,R0
	BGE	WTMLP
	RETS

*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
*RETURNS
*	C	IF ERROR
*	NC	IF NOT ERROR
*
*
CME_MASK	.word	0FF80h
CHECK_MOTION_ERROR:
	PUSH	R0
	PUSH	AR0
	CLRI	AR0
	LDP	@991030h
	LDI	@991030h,R0
	LDI	*AR0,AR0
	SETDP

	AND	@CME_MASK,R0
	BZ	CME_NO_MOTION_ERRORS

	SETC
	POP	AR0
	POP	R0
	RETS

CME_NO_MOTION_ERRORS
	CLRC
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
	.globl	CLEAR_LATCH_ERROR
CLEAR_LATCH_ERROR:
	DINT
	CLRI	R0
	STI	R0,@LATCHED_ERROR
	EINT
	RETS
	.bss	LATCHED_ERROR,1
LATCH_ERROR:
	CALL	CHECK_MOTION_DIP
	RETSNZ			;RETURN IF NON MOVING
	CALL	CHECK_MOTION_ERROR
	RETSNC
	LDI	1,R0
	STI	R0,@LATCHED_ERROR
	RETS
*----------------------------------------------------------------------------


*
*CHECK GALIL READY
*RET CS IF GALIL READY W/ CHAR
*
G_READY:
        LDIL    SOUND,AR3
        LDI     0FF0Ah,R0
        LDI     0F70ah,R1
        STI     R0,*AR3
        CALL 	WAIT500
        STI     R1,*AR3
        CALL 	WAIT500
        STI     R0,*AR3
        CALL	WAIT500

        LDI     0FF00h,R0
        LDI     0Fb00h,R1
        STI     R0,*AR3
        CALL 	WAIT500
        STI     R1,*AR3
        CALL 	WAIT500

        LDI     *AR3,R1		;read status
        STI     R0,*AR3
        CALL 	WAIT500
	LSH	17,R1		;PUT INTO CARRY
	RETS

*
*GET GALIL CHARACTER
*RET R1= 8 BIT ASCII CODE B0-B7
*RET CS IF CHAR PRESENT
*RET CC IF NO CHAR PRESENT
*
G_CHAR:
	CALL	G_READY
	RETSNC			;RETURN IF NOTHING 

	CALL	G_READY
	RETSNC			;RETURN IF NOTHING 

        LDIL    SOUND,AR3
        LDI     0FF08h,R0
        LDI     0F708h,R1
        STI     R0,*AR3
        CALL 	WAIT500
        STI     R1,*AR3
        CALL 	WAIT500
        STI     R0,*AR3
        CALL 	WAIT500

        LDI     0FF00h,R0
        LDI     0Fb00h,R1
        STI     R0,*AR3
        CALL 	WAIT500
        STI     R1,*AR3
        CALL 	WAIT500

        LDI     *AR3,R1
        RS      8,R1
        AND     0FFh,R1

        STI     R0,*AR3
        CALL 	WAIT500
	SETC
	RETS

*
*GET GALIL STRING
*
G_STRING:

GS0
	CALL	G_CHAR	   		;CHARACTER READY?
	BNC	GSX			;NO...


	CMPI	'G',R1	;position error
	BNE	NOTPERR	;attempt motion recalibration

	LDI	1,R2
	SETAUD	AUD_RESET_TOTALLY

	LDI	0,R2
	SETAUD	ADJ_MOTION_PRESENT
	BU	GS0

NOTPERR
	CMPI	'V',R1			;STATUS ANYONE?
	BNE	NOTQSTATUS
	CALL	G_HEX
	AND	6h,R1
	CMPI	6h,R1
	BZ	GS0

	LDI	@WAITTIK,R1
	CMPI	2,R1
	LDILT	2,R1
	STI	R1,@WAITTIK
	BU	GS0

NOTQSTATUS


	CMPI	'W',R1			;IS IT AN ERROR??
	BNE	NOTQQERRORX		;
	LDI	@LLG6X,AR2
	BU	SHOWENCODER

NOTQQERRORX
	CMPI	'S',R1			;IS IT AN ERROR??
	BNE	NOTQQERRORY		;

	LDI	@LLG6Y,AR2
	BU	SHOWENCODER
NOTQQERRORY

	CMPI	'Q',R1			;IS IT AN ERROR??
	BNE	NOTQQERRORZ		;

	LDI	@LLG6Z,AR2
	BU	SHOWENCODER
	.data
LLG6X	.word	L4ABX
LLG6Y	.word	L4ABY
LLG6Z	.word	L4ABZ
	romdata
L4ABX	.string	"X ENCODER FAILURE",0
L4ABY	.string	"Y ENCODER FAILURE",0
L4ABZ	.string	"Z ENCODER FAILURE",0
	.text

SHOWENCODER
	FLOAT	256,R2
	FLOAT	110,R3
	LDI	60,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET40FONTDS

	CLRI	R2
	SETAUD	ADJ_MOTION_PRESENT

;
; galil program will take care of this - ml
;
;	;send shutdown commands
;	LDL	MOTOROFF,AR2
;	CALL	SEND_CMD
;	RETS

	RETS

NOTQQERRORZ
NOTQQERROR
	CMPI	'X',R1
	BNE	GS1
	CALL	G_HEX
	BNC	GSX
	STI	R1,@GALIL_STATUS_X
	B	GS0
GS1
	CMPI	'Y',R1
	BNE	GS2
	CALL	G_HEX
	BNC	GSX
	STI	R1,@GALIL_STATUS_Y
	B	GS0
GS2
	CMPI	'Z',R1
	BNE	GS0
	CALL	G_HEX
	BNC	GSX
	STI	R1,@GALIL_STATUS_Z
	B	GS0
GSX
	RETS
*----------------------------------------------------------------------------


	.bss	GALIL_STATUS_X,1
	.bss	GALIL_STATUS_Y,1
	.bss	GALIL_STATUS_Z,1
*----------------------------------------------------------------------------
*
*GET HEX STRING
*
G_HEX
	CALL	G_CHAR
	BNC	GHX			;NO...

	CMPI	'$',R1
	BNZ	GHX

	CALL	G_CHAR
	BNC	GHX			;NO...
	CALL	ASCIIHEX
	BNC	GHX
	LDI	R1,R2
	LSH	4,R2

	CALL	G_CHAR
	BNC	GHX			;NO...

	CALL	ASCIIHEX
	BNC	GHX
	ADDI	R2,R1
	SETC
	RETS
GHX
	CLRC
	RETS

*
*CHANGE ASCIIHEX TO HEX 4 BITS
*R1=ASCII
*RET R1 =HEX
*CC IF INVALID
*CS IF VALID
*
ASCIIHEX:
	CMPI	47H,R1
	BGE	ASCERR

	SUBI	30H,R1
	BN	ASCERR
	
	CMPI	9,R1
	BLE	AH1
	CMPI	11H,R1
	BLT	ASCERR

	SUBI	7,R1
AH1
	SETC
	RETS
ASCERR
	CLRC	
	RETS
*----------------------------------------------------------------------------


	
*----------------------------------------------------------------------------
WAIT_ACK:

	DINT
	LDI	1000,R6		;EXCESS CHARACTER TIMEOUT

WAIT_ACK_LOOP
	CALL	G_READY
	BNC	EXITL2 		;NOTHING THERE DUDES...

	LDI	300,R0
	STI	R0,@MOTION_RCV_TIKS

	CALL	G_STRING
	BNC	EXITL2 		;NOTHING THERE DUDES...
	DEC	R6
	BZ	NO_RESPONSE	;TOO MANY CHARACTERS

        BU      WAIT_ACK_LOOP
EXITL2
	EINT
        RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
NO_RESPONSE:
	EINT
	LDI	0,R2
	SETAUD	ADJ_MOTION_PRESENT
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
WAIT_ACK_REAL:

	LDI	10000,R6	;NO RESPONSE TIMEOUT
WAR0
	CALL	G_READY
	BC	WAR1
	DEC	R6
	BZ	NO_RESPONSE
	B	WAR0
WAR1
	LDI	1000,R6		;EXCESS CHARACTER TIMEOUT
WAR1L
	CALL	G_CHAR
	BNC	EXITL2A		;NO MORE CHARACTERS

	DEC	R6
	BZ	NO_RESPONSE	;TOO MANY CHARACTERS
        BU      WAR1L

EXITL2A
        RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*
*
UPPER_LIMIT_ERROR:
;
;	CALL	RESET_GALIL
;       CALL    WAIT_ACK_REAL
;
;	;send shutdown commands
;	LDL	MOTOROFF,AR2
;	CALL	SEND_CMD
;
	CALL    SEND_MOTOR_OFF_NO_RESET

	CLRI	R2
	SETAUD	ADJ_MOTION_PRESENT

	LDI	5,AR5

ULLERR
	FILL	1,200,500,390,0

	LDI	50,R0
	CALL	WAITMSEC

	LDI	1,RC
	TEXTITT	"UPPER LIMIT SWITCH ERROR",1,200

	LDI	@GALIL_STATUS_X,R0
	TSTB	08h,R0
	BZ	ULL1

	TEXTITT	"X AXIS LIMIT SWITCH NOT FOUND",1,210
ULL1	LDI	@GALIL_STATUS_Y,R0
	TSTB	08h,R0
	BZ	ULL2

	TEXTITT	"Y AXIS LIMIT SWITCH NOT FOUND",1,220
ULL2	LDI	@GALIL_STATUS_Z,R0
	TSTB	08h,R0
	BZ	ULL3

	TEXTITT	"Z AXIS LIMIT SWITCH NOT FOUND",1,230
ULL3

	LDI	450,R0
	CALL	WAITMSEC
	DBU	AR5,ULLERR
	RETS
*----------------------------------------------------------------------------

	

*----------------------------------------------------------------------------
LOWER_LIMIT_ERROR:
;
;	CALL	RESET_GALIL
;        CALL    WAIT_ACK_REAL
;
;	;send shutdown commands
;	LDL	MOTOROFF,AR2
;	CALL	SEND_CMD
;

	CALL    SEND_MOTOR_OFF_NO_RESET

	CLRI	R2
	SETAUD	ADJ_MOTION_PRESENT

	FILL	1,200,500,390,0

	LDI	5,AR5
LLLERR


	FILL	1,200,500,390,0

	LDI	50,R0
	CALL	WAITMSEC

	LDI	1,RC
	TEXTITT	"LOWER LIMIT SWITCH ERROR",1,200

	LDI	@GALIL_STATUS_X,R0
	TSTB	04h,R0
	BZ	LLL1

	TEXTITT	"X AXIS LIMIT SWITCH NOT FOUND",1,210
LLL1	LDI	@GALIL_STATUS_Y,R0
	TSTB	04h,R0
	BZ	LLL2

	TEXTITT	"Y AXIS LIMIT SWITCH NOT FOUND",1,220
LLL2	LDI	@GALIL_STATUS_Z,R0
	TSTB	04h,R0
	BZ	LLL3

	TEXTITT	"Z AXIS LIMIT SWITCH NOT FOUND",1,230
LLL3

	LDI	450,R0
	CALL	WAITMSEC
	DBU	AR5,LLLERR



	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------


*We must take into consideration:
*	IF a limit switch is bogus, we can compensate by
*	doing:
*
*	"JG -26000,-26000,-26000;BG",13,"WT 3100",13,
*	"SH",13
*	"PR 500,500,500"		;just to relieve the pressure a bit...
*	"DP 0,0,0",13
*	"SP 15000,15000,15000",13,0
*	etc... etc...
*
*	NO NOT TRUE
*
*AC	ACCERATION
*BG	BEGIN MOTION
*DC	DECELERATION
*DP	DEFINE POSITION AS
*IT	INDEPENDANT TIME CONSTANT (SMOOTHING FUNCTION)
*JG	JOG (MOVE AT SPEED)
*JP	JUMP
*MO	MOTOR OFF
*PA	POSITION ABSOLUTE
*PR	POSITION RELATIVE
*SP	SPEED
*WT	WAIT
*XQ	EXECUTE (LABEL)
*#<>	LABEL
*EN	END OF PROGRAM
*ED	EDIT (OPEN BUFFER)
*^Q	(17/CTRL-Q) (END OF BUFFER)
*

	romdata

PPSAF	.string	"PR 4000,4000,4000;BG",13,"WT 500",13,"PR -12000,-12000,-12000",13,0

PP	.string	"JG -26000,-26000,-26000;BG",13,"WT 3100",13,"DP 0,0,0",13,"SP 15000,15000,15000",13,0
PP1	.string	"AC 105000,105000,105000",13,"ER 8000,8000,8000",13,0
PP2	.string	"DC 435000,435000,435000",13,"TL 7,7,7",13,0
PP3	.string	"IT 0.1,0.1,0.1",13,"PA 0,0,0;BG",13,0
PP4	.string	"JG 0,0,0;BG",13,0


EDIT	.string	"ED",13,0
T5	.string	"#PROG",13,0
T6	.string	"#XE",13,0
T7	.string	"#XA",13,0
T8	.string	"#YE",13,0
T9	.string	"#YA",13,0
T10	.string	"#ZE",13,0
T11	.string	"#ZA",13,0
T12	.string	"JG 0,0,0",13,0
T13	.string	"BG XYZ",13,0
T14	.string	"XA=0",13,0
T15	.string	"YA=0",13,0
T16	.string	"ZA=0",13,0
T17	.string	"#LOOP",13,0
T18	.string	"XE=XA-_RPX",13,0
T19	.string	"XE=XE*5",13,0
T20	.string	"YE=YA-_RPY",13,0
T21	.string	"YE=YE*5",13,0
T22	.string	"ZE=ZA-_RPZ",13,0
T23	.string	"ZE=ZE*5",13,0
T24	.string	"JG XE,YE,ZE",13,0
;T25	.string	"JP #CHKX,(_TTX*_TTX)>21",13,0
T25	.string	"JP #CHKX,(_TTX*_TTX)>23",13,0
;T26	.string	"JP #CHKY,(_TTY*_TTY)>21",13,0
T26	.string	"JP #CHKY,(_TTY*_TTY)>23",13,0
;T27	.string	"JP #CHKZ,(_TTZ*_TTZ)>21",13,0
T27	.string	"JP #CHKZ,(_TTZ*_TTZ)>26",13,0		;LOFF DLTA November 9,1994
T28	.string	"JP #LOOP",13,0
T29	.string	"#INITP",13,0
T30	.string	"#COUNT",13,0

T31	.string	"#CHKX",13,0
T32	.string	"ACC=0",13,0
T33	.string	"INITP=_TPX",13,0
T34	.string	"#MLPX",13,0
;T35	.string	"JP #LOOP,(_TTX*_TTX)<7",13,0
T35	.string	"JP #LOOP,(_TTX*_TTX)<10",13,0
T36	.string	"JP #LOOP,(_TPX-INITP)>5",13,0
T37	.string	"JP #LOOP,(_TPX-INITP)<-8",13,0
T38	.string	"COUNT=COUNT+1",13,0
T39	.string	"JP #ERROUTX,COUNT>5",13,0
T40	.string	"JP #MLPX",13,0

T41	.string	"#CHKY",13,0
T42	.string	"COUNT=0",13,0
T43	.string	"INITP=_TPY",13,0
T44	.string	"#MLPY",13,0
;T45	.string	"JP #LOOP,(_TTY*_TTY)<7",13,0
T45	.string	"JP #LOOP,(_TTY*_TTY)<10",13,0
T46	.string	"JP #LOOP,(_TPY-INITP)>5",13,0
T47	.string	"JP #LOOP,(_TPY-INITP)<-8",13,0
T48	.string	"COUNT=COUNT+1",13,0
T49	.string	"JP #ERROUTY,COUNT>5",13,0
T50	.string	"JP #MLPY",13,0

T51	.string	"#CHKZ",13,0
T52	.string	"COUNT=0",13,0
T53	.string	"INITP=_TPZ",13,0
T54	.string	"#MLPZ",13,0
;T55	.string	"JP #LOOP,(_TTZ*_TTZ)<7",13,0		;LOFF DLTA November 9,1994
T55	.string	"JP #LOOP,(_TTZ*_TTZ)<17",13,0
T56	.string	"JP #LOOP,(_TPZ-INITP)>5",13,0
T57	.string	"JP #LOOP,(_TPZ-INITP)<-8",13,0
T58	.string	"COUNT=COUNT+1",13,0
T59	.string	"JP #ERROUTZ,COUNT>5",13,0
T60	.string	"JP #MLPZ",13,0

T1	.string	"#POSERR",13,0
T2	.string	"MG ",34,"G",34,13,0
T3	.string "JP #MOTOFF",13,0

T66X	.string	"#ERROUTX",13,0
T67X	.string	"MG ",13,0
T68X	.string	"MG ",34,"W",34,13,0

T66Y	.string	"#ERROUTY",13,0
T67Y	.string	"MG ",13,0
T68Y	.string	"MG ",34,"S",34,13,0

T66Z	.string	"#ERROUTZ",13,0
T67Z	.string	"MG ",13,0
T68Z	.string	"MG ",34,"Q",34,13,0


T69	.string	"#MOTOFF",13,0
T70	.string	"JG 90000,90000,90000;BG;TL 0.6,0.6,1.8",13,0
T71	.string	"WT 2000;TL 0.55,0.55,1.6",13,0
T72	.string	"WT 2000;TL 0.50,0.50,1.5",13,0
T73	.string	"WT 2000;TL 0.45,0.45,1.4",13,0
T74	.string	"WT 2000;TL 0.40,0.40,1.3",13,0
T75	.string	"WT 2000;TL 0.35,0.35,1.2",13,0
T76	.string	"WT 2000;TL 0.30,0.30,1.1",13,0
T77	.string	"WT 2000;TL 0.25,0.25,1.0",13,0
T78	.string	"WT 2000;TL 0.20,0.20,0.9",13,0
T79	.string	"WT 2000;TL 0.15,0.15,0.8",13,0
T80	.string	"WT 2000;TL 0.10,0.10,0.7",13,0
T81	.string	"WT 2000;TL 0.05,0.05,0.6",13,0
T82	.string	"WT 2000",13,0
T83	.string	"OE 1,1,1;AB",13,0
T84	.string	"TL 7,7,7;EN",13,0


ENDED	.string	17,0
XQ	.string	"XQ",13,0		;"XQ #PROG",13,0

PXC1	.string	"XA=",0
PXC2	.string	13,"BG XYZ",13,0

PYC1	.string	"YA=",0
PYC2	.string	13,0

PZC1	.string	"ZA=",0
PZC2	.string	13,0

	.text
*----------------------------------------------------------------------------
	.END

