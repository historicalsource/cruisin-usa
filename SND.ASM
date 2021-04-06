	.FILE	"SND.ASM"
*----------------------------------------------------------------------------
*SOUND SYSTEM
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
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
	.include	TEXT.EQU
	.include	OBJECTS.EQU
	.include	COMM.EQU


	fbss	IN_RESET_MODE,1
	fbss	RESET_TIMER,R0


	
	.bss	SNDSTR,NCHAN*SND_SIZ
	.bss	SNDEND,0

SNDTABI	.word	SNDTAB

*----------------------------------------------------------------------------
*STATION TABLE
*
STATION_LISTI	.word	STATION_LIST
STATION_LIST	.word	MUNSTER_SURF	;0
		.word	SHUFFLE_DRIV	;1
		.word	DISCODUCK	;2
		.word	SPAGETTI	;3
		.word	VENTURE		;4
		.word	STRAIGHT_2_4	;5
		.word	DISCODUCK	;6
		.word	BOOGIE		;7

STATION_TEXTI	.word	STATION_TEXT
STATION_TEXT
	SPTR	"SURFARI MONSTER"	;MONSTER_SURF	;0	[2
	SPTR	"REDLINE SHUFFLE"	;SHUFFLE_DRIV	;1	[4
	SPTR	"HOUSE SPECIAL"		;DISCODUCK	;2	[24
	SPTR	"DEADWOOD RIDE"		;SPAGETTI	;3	[16
	SPTR	"TUBULAR SURF"		;VENTURE	;4	[10
	SPTR	"ROADKILL JAM"		;STRAIGHT_2_4	;5	[6
	SPTR	"HOUSE SPECIAL"		;DISCODUCK	;6	[24
	SPTR	"BLUEGRASS BOOGIE"	;BOOGIE		;7	[13
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
	.bss	STATION_TIMEOUT,1
	.bss	RS_X,1
RADIO_SHOW:
	LDI	@TUNE_IDX,AR2
	ADDI	@STATION_TEXTI,AR2
	LDI	*AR2,AR2
	FLOAT	210,R2
	FLOAT	370,R3
	LDI	1,RC
	CALL	TEXT_ADDDS

	LDL	cdd,AR2
	LDI	160,R2
	LDI	360,R3
	LDI	TM|ZS,R4
	CALL	BLTMOD2D_DS
	
	SLEEP	1
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MGAME,R0
	BNE	KILLME

	LDI	@STATION_TIMEOUT,R0
	DEC	R0
	STI	R0,@STATION_TIMEOUT
	BLE	SUICIDE
	BU	RADIO_SHOW

KILLME
	CLRI	R0
	STI	R0,@STATION_TIMEOUT
	DIE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
RADIO_BUT:
	LDPI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MGAME,R0
;	BNE	SUICIDE

	BEQ	RBMGAME
	BR	RBMATTR_CHECK	;This code is in hstdp.asm
RBMGAME

	CALL	CHANGE_STATION
	DIE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PARAMETERS
*	AR2	STATION #
*
SET_STATION:
	.if	DEBUG
	CMPI	0,AR2
	BLT	$
	CMPI	NUM_STATIONS,AR2
	BGE	$
	.endif
	STI	AR2,@TUNE_IDX
	CALL	RESUME_TUNE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PARAMETERS
*	NONE
*
CHANGE_STATION:
	PUSH	R0
	LDI	@TUNE_IDX,R0
	INC	R0
	CMPI	8,R0
	LDIGE	0,R0
	STI	R0,@TUNE_IDX

	CALL	RESUME_TUNE
	POP	R0
	RETS
*----------------------------------------------------------------------------


	.bss	TUNE_IDX,1	;ACTUALLY A STATION #
*----------------------------------------------------------------------------
*PARAMETERS (SET_TUNE)
*	AR2	CHANNEL
*
SET_TUNE_LINKED:
	PUSH	AR2
	PUSH	AR6
	LDI	1,AR6
	STI	AR2,@TUNE_IDX
	BU	L987

SET_TUNE:
	PUSH	AR2
	PUSH	AR6
	CLRI	AR6
	STI	AR2,@TUNE_IDX
	BU	L987

RESUME_TUNE:
	PUSH	AR2
	PUSH	AR6
	CLRI	AR6

L987
	CALL	RESUME_TUNE_NT

	LDI	UTIL_C|RADIOPROC_T,R0
	LDI	-1,R1
	CALL	PRC_FIND
	CMPI	0,AR0
	BNE	ISTHERE

	CREATE	RADIO_SHOW,UTIL_C|RADIOPROC_T
ISTHERE
	LDI	40,R0
	STI	R0,@STATION_TIMEOUT
	LDI	0,R0
	STI	R0,@RS_X

;	LDI	0,R0
;	LDI	150,R1
;	CALL	SET_TRACK_VOL

	CMPI	1,AR6
	BEQ	NOOMUS

	LDI	@HEAD2HEAD_ON,R0
	BZ	NOOMUS
	CALL	SEND_CHANGE_MUSIC
NOOMUS


	POP	AR6
	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
RESUME_TUNE_NT:
	LDI	@TUNE_IDX,AR2
	CMPI	8,AR2
	LDIGT	0,AR2
	ADDI	@STATION_LISTI,AR2
	LDI	*AR2,AR2
	CALL	ONESND
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PARAMETERS
*	R0	TRACK #(0-3)	(EXCEPT IN MASTER VOL)
*	R1	VOL (0-255)
*
SET_MASTER_VOL:
	PUSH	AR2
	BUD	JI1
	PUSH	R0
	PUSH	R1
	LDI	055AAh,R0
	;---->	BUD	JI1
SET_TRACK_VOL:
	PUSH	AR2
	PUSH	R0
	PUSH	R1

	LDI	1,AR2
	STI	AR2,@DO_NOT_REENABLE_INT

	PUSH	AR0
	LDI	R0,AR0
	MPYI	SND_SIZ,AR0
	ADDI	@SNDSTRI,AR0		;WE HAVE POINTER TO CHANNEL IN AR0
	STI	R1,*+AR0(SND_VOL)
	POP	AR0

	ADDI	055ABh,R0
JI1	

	LDI	1,AR2
	STI	AR2,@DO_NOT_REENABLE_INT

	LDI	R0,AR2
	CALL	SENDSND
	AND	0FFh,R1

	CLRI	AR2
	STI	AR2,@DO_NOT_REENABLE_INT

	NOT	R1,R0
	AND	0FFh,R0
	LS	8,R1
	OR	R0,R1
	LDI	R1,AR2
	CALL	SENDSND

	POP	R1
	POP	R0
	POP	AR2
	RETS
	.bss	DO_NOT_REENABLE_INT,1
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
RESET_SNDBRD:

	;new sound system reset
	;
	;
	;
	LDI	@SYSCNTL,R0
	LDI	R0,R1
	ANDN	SND2_RESET,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR
	NOP
	NOP
	NOP
	STI	R1,@SYSCNTLR
	SETDP
	STI	R1,@SYSCNTL
	;


	PUSH	DP
	LDP	@SOUND
	LDI	0FF00h,R0
	LDI	0F700h,R1
	STPI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP


	LDI	0FF3Ch,R0
	LDI	0FB3Ch,R1
	STI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP


	LDI	500,RC
	MPYI	1000,RC
	RPTB	WAITIT
WAITIT	NOP


	LDI	0FF1Ch,R0
	LDI	0FB1Ch,R1
	STI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP
	POP	DP

	BU	CLRSNDDB
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SILENT:
	PUSH	AR2
	CALL	CLRSNDDB
	CLRI	AR2
	CALL	SENDSND
	LDI	1256,AR2
	CALL	SENDSND

	LDI	1,AR2
	STI	AR2,@DO_NOT_REENABLE_INT
	LDI	055CCh,AR2
	CALL	SENDSND
	LDI	0,AR2
	STI	AR2,@DO_NOT_REENABLE_INT
	CALL	SENDSND

	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CLEAR THE SOUND DATA BASE
*
SNDSTRI	.word	SNDSTR
CLRSNDDB:
	PUSH	AR0
	PUSH	R0
	LDI	@SNDSTRI,AR0
	CLRI	R0
	RPTS	(SND_SIZ*NCHAN)-1
	STI	R0,*AR0++
	POP	R0
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GET SOUND PRIORITY
*
*PARAMETERS
*	AR0	CHANNEL #0-3
*
GETPRI:
	RS	8,AR0
	AND	0Fh,AR0			;isolate channel
	MPYI	SND_SIZ,AR0
	ADDI	@SNDSTRI,AR0		;we have pointer to channel in AR0
	LDI	*+AR0(SND_PRI),R0
	AND	0FFh,R0			;extract priority of current sound
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*ACTIVATE SOUND WITH VARIABLE VOLUME
*
*PARAMETERS
*	AR2	SOUND INDEX
*	R0	VOLUME 0-255
*
VOLSNDFX:
 	AND	0FFH,R0		;KEEP IN RANGE
	B	SNDFX
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*ACTIVATE ONE SOUND ON ONE OF THE FX TRACKS (CHAN1 or CHAN2)
*
*1.  IF EITHER TRACK IS OPEN THEN SEND TO THAT TRACK
*2.  ELSE SEE IF IT HAS A HIGHER PRIORITY THAN EITHER TRACK
*3.  ELSE RETURN NOT AVAILABLE
*
*PARAMETERS
*	AR2	SOUND ENTRY INDEX
*RETURNS
*	C	SOUND SUCCESSFUL
*	NC	SONUD UNSUCCESSFUL
*
*
ONESNDFX:
	LDI	255,R0
*
*PARAMETERS
*	R0	SOUND VOLUME
*
SNDFX:
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	AR0
	PUSH 	R0			;SAVE VOLUME

	LDI	@_MODE,R1
	AND	MMODE,R1
	CMPI	MATTR,R1
	BEQ	SNDLDXFX		;IF attr DONT CALL SOUND FX


	LDI	1,AR0
	LDI	@SNDSTR+SND_SIZ+SND_PRI,R2
	LDI	R2,R0
	AND	0FFh,R2
	LDI	@SNDSTR+SND_SIZ+SND_SIZ+SND_PRI,R3
	LDI	R3,R1
	AND	0FFh,R3
	CMPI	R3,R2
	LDIGT	R3,R2
	LDIGT	R1,R0
	LDIGT	2,AR0	  		;CHANNEL #, LOWEST PRIORITY

	LDI	AR2,R3			;SAVE THE INDEX (IDENTITY)
	ADDI	@SNDTABI,AR2		;INDEX OUT TO GET ACTUAL SCRIPT
	LDI	*AR2,R1			;GET PRIORITY WORD
	AND	0FFh,R1

	CMPI	R2,R1
	BLT	NOSOUND_FX
	BGT	ONESNDFX2

	TSTB	ENINT,R0
	BNZ	NOSOUND_FX
ONESNDFX2
	TSTB	NINT,R0
	BNZ	NOSOUND_FX

	LDI	AR0,R0

	MPYI	SND_SIZ,AR0
	ADDI	@SNDSTRI,AR0		;WE HAVE POINTER TO CHANNEL IN AR0

	POP	R1			;GET VOLUME VALUE
	CMPI	*+AR0(SND_VOL),R1
	BEQ	NOVOL

	CALL	SET_TRACK_VOL
NOVOL
	LDI	1,R2			;R2  - # OF REPEATS
	STI	R2,*+AR0(SND_REP)
	STI	AR2,*+AR0(SND_ST)
	STI	AR2,*+AR0(SND_ADDR)
	STI	R3,*+AR0(SND_IDX)
	SUBI	1,R0
	STI	R0,*+AR0(SND_STATUS)	;INCREMENT SOUND BIT

	CALL	SNDUPD			;GET THE SOUND GOING
	PUSH	R0			;DUMMY PUSH
SNDLDXFX
	SETC
L88	POP	R0
	POP	AR0
	POP	R3
	POP	R2
	POP	R1
	RETS

NOSOUND_FX
	CLRC
	BU	L88
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*KILL A SOUND ON ONE OF THE FX TRACKS (CHAN1 or CHAN2)
*
*1.  IF TRACK HAS SOUND, KILL THAT TRACK
*2.  IF SOUND NOT ACTIVE DO NOTHING
*
*PARAMETERS
*
*	AR2	SOUND ENTRY INDEX
*
*RETURNS CS IF SOUND ACTUALLY KILLED, OTHERWISE CC
*
KILLSNDFX:
	PUSH	AR2
	CMPI	@SNDSTR+SND_SIZ+SND_IDX,AR2
	BNE	KILSFX1
	SOND1	KILLCHAN1
	B	KILSFX3
KILSFX1
	CMPI	@SNDSTR+2*(SND_SIZ)+SND_IDX,AR2
	BNE	KILSFX2
	SOND1	KILLCHAN2
	SETC
	B	KILSFX3
KILSFX2
	CLRC
KILSFX3
	POP	AR2
	RETS

*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*
*PARAMETERS
*	R0	SPEED  (0-255)
*	R1	VOLUME (0-255)
*
*
PLYR_ENGINE:
	LS	8,R0
	OR	R0,R1

	LDI	1,R0
	STI	R0,@DO_NOT_REENABLE_INT

	LDI	055CCh,AR2
	CALL	SENDSND

	CLRI	R0
	STI	R0,@DO_NOT_REENABLE_INT

	LDI	R1,AR2
	B	SENDSND
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*MAINLY FOR DIAGNOSTICS
*	EXECUTE THE SOUND!
*
	.globl	HARDSND
HARDSND:
	ADDI	@SNDTABI,AR2		;INDEX OUT TO GET ACTUAL SCRIPT
	LDI	*+AR2(1),AR2
	LS	16,AR2
	RS	16,AR2
	CALL	SENDSND
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*ACTIVATE ONE SOUND
*
*
*PARAMETERS
*	AR2	SOUND ENTRY INDEX
*
*
ONESND:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	AR0

	.if	DEBUG
	CMPI	0,AR2
	BLT	$
	CMPI	KILLALLS,AR2
	BGT	$
	.endif

	LDI	AR2,R4			;SAVE THE INDEX (IDENTITY)

	ADDI	@SNDTABI,AR2		;INDEX OUT TO GET ACTUAL SCRIPT

	LDI	*AR2,R0			;GET PRIORITY WORD
	LDI	R0,AR0
	RS	8,AR0
	AND	0FH,AR0			;ISOLATE CHANNEL

	.if	DEBUG
	CMPI	3,AR0
	BGT	$
	.endif

	MPYI	SND_SIZ,AR0
	ADDI	@SNDSTRI,AR0		;WE HAVE POINTER TO CHANNEL IN AR0
	LDI	*+AR0(SND_PRI),R1
	TSTB	NINT,R1			;IS IT NON-INTERRUPTABLE?
	BNZ	SNDLDX
	LDI	R1,R2
	AND	0FFH,R1			;EXTRACT PRIORITY OF CURRENT SOUND
	LDI	R0,R3
	AND	0FFH,R3			;EXTRACT PRIORITY OF OUR TEST
	CMPI	R3,R1
	BLT	SNDLD1			;BR->CURRENT SOUND IS MORE IMPORTANT

	BNE	SNDLDX		  	
	TSTB	ENINT,R2		;CHECK INTERRUPTABLE BY EQUAL
	BNE	SNDLDX			;NOPE
SNDLD1

	LDI	*+AR0(SND_VOL),R0
	CMPI	255,R0
	BEQ	NOTRESETVOL

	LDI	*AR2,R0			;GET PRIORITY WORD
	RS	8,R0
	AND	0FH,R0			;ISOLATE CHANNEL
	LDI	255,R1
	CALL	SET_TRACK_VOL

NOTRESETVOL
	LDI	1,R2			;R2  - # OF REPEATS
	STI	R2,*+AR0(SND_REP)
	STI	AR2,*+AR0(SND_ST)
	STI	AR2,*+AR0(SND_ADDR)
	CLRI	R0
	STI	R0,*+AR0(SND_STATUS)
	STI	R4,*+AR0(SND_IDX)
	CALL	SNDUPD			;GET THE SOUND GOING

SNDLDX
	POP	AR0
	POP	R4
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*SEND SOUND TO SOUND BOARD
*
*PARAMETER
*	AR2	SOUND CODE (16 BITS)
*
*RETURNS
*	NOTHING
*
*NOTE	On the actual writes to the sound board we are blowing the
*	specified timings as per Loffs suggestion to save time. He
*	says that they are over speced and that it shouldn't be a
*	problem. Initial tests indicate no change in operation.
*	Alter .set SPACER to a larger number if there is a problem.
*
*
SPACER	.set	30		;# OF NOPs BETWEEN WRITES

SENDSND:
	LDP	@IN_RESET_MODE
	LDI	@IN_RESET_MODE,R0
	SETDP
	CMPI	0,R0
	BEQ	NIRM
	RETS
NIRM
	PUSH	AR3
	LDL	9A0000h,AR3	;SND2

	PUSHM	R0,R1
	DINT
	LDP	@SOUND		;byte 1
	LDI	AR2,R0

	RS	8,R0
	LDI	R0,R1
	OR	0FD00h,R1
	OR	0FF00h,R0
	STI	R0,@SOUND
	STI	R0,*AR3		;<-NEW SND2


	RPTS	SPACER
	NOP
	STI	R1,@SOUND
	RPTS	SPACER
	NOP
	STI	R0,@SOUND

	RPTS	SPACER
	NOP

	AND	0FFh,AR2
	LDI	AR2,R0
	LDI	AR2,R1
	OR	0FF00h,R0	;byte 0
	OR	0FD00h,R1

	STI	R0,@SOUND
	STI	R0,*AR3		;<-NEW SND2
	RPTS	SPACER
	NOP
	STI	R1,@SOUND
	RPTS	SPACER
	NOP
	STI	R0,@SOUND

	RPTS	SPACER
	NOP

	SETDP
	LDI	@DO_NOT_REENABLE_INT,R0
	CALLZ	ENABLEGIE
	POPM	R1,R0
	POP	AR3
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*Frame Number	Action
*  1		Initialize Reset
*  2		Lift Reset
*  4		Send Single Byte
*  6		Turn off Reset
*
*
RESETMUNGE:
	DINT
	LDP	@RESET_TIMER
	LDI	@RESET_TIMER,R0
	INC	R0
	STI	R0,@RESET_TIMER
	SETDP
	CMPI	2,R0
	BNE	NOT_F1


	;first pass through

	;new reset mumbo jumbo
	;
	;
	LDI	@SYSCNTL,R0		;reset LOW for new board
	LDI	R0,R1
	ANDN	SND2_RESET,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR
	PUSH	R1
	;continued below


	LDP	@SOUND
	LDI	0FF00h,R0		;set wheel board addr
	LDI	0F700h,R1
	STPI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP


	LDI	0FF3Ch,R0		;set reset HI (old board)
	LDI	0FB3Ch,R1
	STI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP

	RPTS	2500			;wait for 100 milliseconds
	NOP

	;new board from above
	;
	POP	R1			;set reset HIGH (new board)
	LDP	@SYSCNTLR
	STI	R1,@SYSCNTLR
	SETDP
	STI	R1,@SYSCNTL
	;


	LDP	@SOUND	 
	LDI	0FF00h,R0		;set addr
	LDI	0F700h,R1
	STPI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP

	LDI	0FF1Ch,R0		;set reset LOW (old board)
	LDI	0FB1Ch,R1
	STI	R0,@SOUND
	RPTS	50
	NOP
	STI	R1,@SOUND
	RPTS	50
	NOP
	STI	R0,@SOUND
	RPTS	50
	NOP
	BU	RESETMUNGE_X
NOT_F1


NOT_F2
	CMPI	4,R0
	BNE	NOT_F4

	LDL	9A0000h,AR2	;SND2

	LDP	@SOUND		;byte 1
	LDI	0FD00h,R1	;send dummy byte to abort BONGs
	LDI	0FF00h,R0
	STI	R0,@SOUND
	STI	R0,*AR2		;<-NEW SND2

	RPTS	SPACER
	NOP
	STI	R1,@SOUND
	RPTS	SPACER
	NOP
	STI	R0,@SOUND

	BU	RESETMUNGE_X
NOT_F4
	CMPI	6,R0
	BNE	NOT_F6

	CLRI	R0
	LDP	@IN_RESET_MODE
	STI	R0,@IN_RESET_MODE
	SETDP

	READADJ	ADJ_VOLUME
	LDI	R0,R1
	CALL	SET_MASTER_VOL

	;BU	RESETMUNGE_X
NOT_F6

RESETMUNGE_X
	SETDP
	CALL	ENABLEGIE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SND_RESET_QUIET:
	LDP	@RESET_TIMER
	LDI	1,R0
	STI	R0,@RESET_TIMER
	STI	R0,@IN_RESET_MODE
	SETDP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CALLED IN DISPLAY INTERRUPT (16ms)
*
SNDPROC:
	LDP	@IN_RESET_MODE
	LDI	@IN_RESET_MODE,R0
	SETDP
	CMPI	1,R0
	BEQ	RESETMUNGE

	PUSH	R0
	PUSH	R4
	LDI	@SNDSTRI,AR0
	LDI	NCHAN-1,R4
SNDLP
	LDI	*+AR0(SND_TMR),R0
	BEQ	SNDPLP
	DEC	R0
	STI	R0,*+AR0(SND_TMR)
	CALLZ	SNDUPD			;on ZERO CALL UPDATE

SNDPLP
	ADDI	SND_SIZ,AR0
	DEC	R4
	BGE	SNDLP

	POP	R4
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PARAMETERS
*	AR0	PTR TO SOUND CHANNEL RAM
*
SNDUPD:
;this code allows for scripted sound calls.
;as of now they are not used, and I don't
;believe they will be before CUSA is finished.
;therefore this operation is removed.
;
;on next implimentation, set a BIT in the
;control flag signifying a scripted sound
;call - a WORD is a terrible thing to waste.
;	ELP July 1,1994
;
	PUSH	AR1

	LDI	*+AR0(SND_ADDR),AR1
	LDI	*AR1++,R0
	BZ	SNDCLRE			;NULL entry let us quit


	STI	R0,*+AR0(SND_PRI)
	LDI	*AR1,R0
	LDI	R0,AR2
	AND	07FFFh,AR2

	LDI	*+AR0(SND_STATUS),R0
	BZ	JUSTGO
	INC	AR2
JUSTGO
	CALL	SENDSND			;do the actually sending

	LDI	*AR1++,R0		;EXTRACT TIMING DATA
	RS	16,R0
	STI	R0,*+AR0(SND_TMR)	;start countdown
	STI	AR1,*+AR0(SND_ADDR)

	CMPI	0,R0
	BGT	SNDUPX
SNDCLRE
	CLRI	R0
	STI	R0,*+AR0(SND_PRI)
	STI	R0,*+AR0(SND_ST)
	STI	R0,*+AR0(SND_STATUS)
SNDUPX
	POP	AR1
	RETS
*----------------------------------------------------------------------------
	.END
