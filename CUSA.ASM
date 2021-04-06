 	.FILE	"CUSA.ASM"
*----------------------------------------------------------------------------
*			CRUIS'N USA
*
*
*	EUGENE JARVIS			DIRECTOR
*
*	ERIC PRIBYL			SOFTWARE
*
*	MARK LOFFREDO			HARDWARE
*	GLENN SHIPP			HARDWARE
*
*	TED BARBER			GRAPHICS
*	SHAWN COOPER			GRAPHICS
*
*	MATT BOOTY			SOUND FX
*	VINCE PONTARELLI		MUSIC
*
*
*	COPYRIGHT (C) 1994 NINTENDO, DEVELOPED BY TV GAMES, INC.
*	MANUFACTURED AND SOLD BY MIDWAY MANUFACTURING COMPANY UNDER LICENSE
*
*

MEMTESTS	.set	1

	.include	MPROC.EQU
	.include	MACS.EQU
	.include	OBJ.EQU
	.include	OBJECTS.EQU
	.include	GLOBALS.EQU
	.include	SYS.EQU
	.include	C30.EQU
	.include	TEXT.EQU
	.include	VUNIT.EQU
	.include	CMOS.EQU
	.include	SNDTAB.EQU
	.include	PALL.EQU
	.include	SYSID.EQU
	.include	DIRQ.EQU
	.include	ERROR.EQU
	.include	COMM.EQU
	.include	CHECKSUM.EQU


TIKS_PER_SECOND	.set	57

	.include	DATE.ASM



	.text

	fbss	COMMINTM,1	;0       if NON-linked
				;INT2_M  if linked

	.globl	VERSION_STAMP
	romdata


	.if	0
startup0	.string	"DO NOT EVEN CONSIDER RELEASING THESE ROMS",0
startup2	.string	"   THIS VERSION HAS A FATAL BUG",0
startup1
startup3
dlts		.string	"TEST VERSION",0
VERSION_STAMP	.string	"VERSION NOT FOR RELEASE",0
	.else
startup0 	.string	"          CRUISN USA (TM)     HEAD 2 HEAD",0
startup1	.string	"  (C) 1994 NINTENDO, DEVELOPED BY TV GAMES, INC.",0
startup2	.string	"MANUFACTURED AND SOLD BY MIDWAY MANUFACTURING COMPANY",0
startup3	.string	"                  UNDER LICENSE.",0
dlts		.string	"DOWNLOADING TEXTURES",0



;Release of linked version will be 4.0
;	I = I4000
;	VID = 40
;
VERSION_STAMP	.string	"VERSION  4.4",0
	.endif

INTERNAL_VERS	.string	"I440",0
VERSION_ID	.set	40

	;Because of managements inability to deal with software projects,
	;or being able to keep the version control straight
	;we have now moved into Internal and External versions of the program
	;VERSION_STAMP contains whatever the management wants to call it.
	;If management asks call it 'version' or 'release'.
	;'actual version' or 'internal version' or 'internal' is what 
	;to use for us.
	;INTERNAL_VERS is the actual version of the software.
	;Keep in mind that multiple releases exist under the external
	;version name, and the true software version can be gotten from
	;the title page.



M1		.string	"LOADING OS-WMS...",0
M2		.string	"I-NODES ALLOCATED,  DCS DECODED (14-1715)",0
M3		.string	"WMS SATELLITE COMM, CHANNEL 3 ACTIVE LYBIRP",0
M4		.string	"USR/ELP/CUSA>NETLINK WMS 14.32.86.1 -K CIRE",0
M5		.string	"CONNECTING TO HOST...",0

M6		.string	"CONNECTION ESTABLISHED, PUBLIC-KEY: CIRE",0
M7		.string	"USR/ELP/CUSA>FTP GET CUSA",0

M8		.string	"37940813 BYTES RECEIVED OK",0
M9		.string	"USR/ELP/CUSA>TV30 CUSA /L",0

	.text


	;*** RAM DEFINITIONS
	pbss	_MODE,1		;machine mode
	pbss	STATE,1		;comm machine state


	.bss	NFRAMES,1	;number of frames passed since last update
	.bss	INFRAMES,1

	.bss	FRAMRATE,1	;MIN frames allowed-1
	.bss	IFRAMES,1	
	.bss	OFRAMES,1
	.bss	ERRORN,1
	.bss	ERRORO,1
	.bss	FRAMETIME,1	;TMR_FRAME

	.bss	SWITCHBUTS,1
	.bss	BGNDCOLA,1	;color 0 in COLORRAM
	.bss	DIAG_ACTIVE,1
	.bss	GAME_TIMER,1	;FL	minutes since last buyin

	pbss	SYSCNTL,1	;shadow location
	pbss	_pot0,1		;steering wheel
	.bss	_pot1,1		;accel pedal
	.bss	_pot2,1		;brake pedal

	.bss	RDPOT,1
	.bss	_sectime,1	;one second timer
	.bss	CLEARRDY,1	;clear screen is ready (1 = swap pages and clear screen)
	.bss	NOAERASE,1	;NO AUTOERASE FLAG
	.bss	NOSWAP,1	;NO PAGE SWAPPING
	.bss	DISPLAY_PAGE,1

	fbss	MPROC_TIK,1



*----------------------------------------------------------------------------
_c_int00:
	LDI	02h,IOF			;TV30 KLUDGE

	CLRI	R0			;must fix COMM setup asap
	LDP	@COMMINTM
	STI	R0,@COMMINTM

	LDP	@CPU_WS
	LDI	1068h,R0
	STI	R0,@CPU_WS

	LDP	@FIFO_CONTROL
	LDI	FIFO_CONTROL_INIT,R0
	STI	R0,@FIFO_CONTROL

	LDI	800h,ST			;ENABLE THE CACHE, DISABLE INTERRUPTS
        LDP	@FASTSTKI
        LDI	@FASTSTKI,SP		;LOAD THE ADDRESS INTO SP
	DINT				;DISABLE INTERUPTS

	CLRI	R0
	LDP	@CMOS_WP_WORD
	STI	R0,@CMOS_WP_WORD	;DISABLE CMOS WRITES
	LDIL	RAM0,AR0		;CLEARS CMOS_WP_WORD_SHADOW
	RPTS	2047
	STI	R0,*AR0++

	;
	;CHECK TO SEE IF THIS IS A WATCHDOG
	;
	fbss	WDHIT,1

	;POWERUP IGNORE GLITCH FIX
	LDP	@991050h 		;DOG TEST
	LDI	@991050h,R0
	LDP	@WDHIT
	STI	R0,@WDHIT		;SAVE YOUR DOGGIE

	LDP	@SYSCNTLR
	LDI	SYSCNTL_INIT,R0		;INIT SYSCNTL
	STI	R0,@SYSCNTLR

	LDP	@DMA_SETUP
	LDI	DMA_SETUP_INIT,R0	;INIT DMA
	STI	R0,@DMA_SETUP

	LDP	@FIFO_SIZE
	LDI	270,R0			;INIT FIFO SIZE
	STI	R0,@FIFO_SIZE

	CALL	CRT_REG_SETUP		;INIT CRT

	SETDP

	.if	MEMTESTS
	CALL	TEST_STATIC_CHIPS	;TEST THE INSTALLABLE CHIPS
	.endif

	.if	DEBUG
	;
	;COPY THE 'ROM' into the 'ROM'
	;
	;*this only works in RAM
	;and, if used in ROM will cause a lockup
	;

	LDI	40h,AR1			;SOURCE ADDRESS
	LDI	0C000h,AR2		;DESINATION ADDRESS
	LS	8,AR2
	ADDI	40h,AR2
	LDI	1000h,RC		;COPY THE PROGRAM INTO
	LS	4,RC			;FAST RAM
	SUBI	41h,RC
	RPTB	LD_DBG1
	LDI	*AR1++,R0
LD_DBG1	STI	R0,*AR2++
		
	.endif



	LDI	0,AR1			;SOURCE ADDRESS
	LDI	4000h,AR2		;DESINATION ADDRESS
	LS	8,AR2
	LDI	1000h,RC		;COPY THE PROGRAM INTO
	LS	4,RC			;FAST RAM
	RPTB	LD_RAM
	LDI	*AR1++,R0
LD_RAM	STI	R0,*AR2++
	NOP
	NOP				;DELAY FOR PIPELINE
	NOP
	LDI	22h,IOF
	NOP
	NOP				;DELAY FOR PIPELINE
	NOP


	SOFTWTM	R0		    	;SET WAIT STATES

	CLRI	R0
	LDP	@COMMINTM
	STI	R0,@COMMINTM
	SETDP

	.if	MEMTESTS
	CALL	TEST_CHIPS		;TEST THE INSTALLABLE CHIPS
	.endif


	SOFTWTM	R0		    	;SET WAIT STATES
	DINT
        LDP	@FASTSTKI
        LDI	@FASTSTKI,SP		;LOAD THE ADDRESS INTO SP

	.if	MEMTESTS = 0
	;For RAM (development) version, we must copy the
	;program into what would be the ROM
	;
	LDI	@SYSCNTL,R0
	ANDN	10h,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR
	SETDP

	LDI	040h,AR1		;SOURCE ADDRESS
	LDI	0C000h,AR2		;DESINATION ADDRESS
	LS	8,AR2
	ADDI	040h,AR2

	LDI	1000h,RC		;COPY THE PROGRAM INTO
	LS	4,RC			;FAST RAM
	SUBI	41h,RC
	RPTB	LD_RAM3
	LDI	*AR1++,R0
LD_RAM3	STI	R0,*AR2++

	LDI	@SYSCNTL,R0
	OR	10h,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR
	SETDP
	.endif


	CLRI	R2
	SETAUD	ADJ_OUTOFDIAG
      	BU	DR1 			;SKIP DOGGIE

DIAG_RETURN:
	LDI	8,R0	      		;PREVENT FALSE DOGGIE
	LDP	@WDHIT
	STI	R0,@WDHIT		;SAVE YOUR DOGGIE
DR1
	SOFTWTM	R0		    	;SET WAIT STATES
	DINT
        LDP	@FASTSTKI
        LDI	@FASTSTKI,SP		;LOAD THE ADDRESS INTO SP

	.if	DEBUG
	CALL	VERIFY_CODE_INTEGRITY
	.endif

	;LOAD CODE BACK INTO RAM
	;
	;
	LDI	040h,AR1		;SOURCE ADDRESS
	LDI	0C000h,AR2		;DESINATION ADDRESS
	LS	8,AR2
	ADDI	040h,AR2

	LDI	1000h,RC		;COPY THE PROGRAM INTO
	LS	4,RC			;FAST RAM
	RPTB	LD_RAM2
	LDI	*AR2++,R0
LD_RAM2	STI	R0,*AR1++


	CLRI	R0
	LDP	@COLORAM
	STI	R0,@COLORAM
	SETDP
	STI	R0,@DIAG_ACTIVE

	CALL	CLR_PBSS

	CALL	CLR_RAM			;INIT .BSS TO 0
	LDI	MDIAG,R0		;MELLOW THE WHEEL
	STI	R0,@_MODE

	LDI	SYSCNTL_INIT,R0		;INIT SYSCNTL RAM SHADOW
	STI	R0,@SYSCNTL
	CALL	FEED_WATCHDOG


	CALL	MESSAGE1		;DISPLAY STARTUP MESSAGE TO SCREEN
	CALL	MSG1

	LDI	240,R0			;X MIN
	STI	R0,@PREVX
	LDI	1,R0
	STI	R0,@DELTA


	LDP	@TIMER_CNTL1
	LDI	200h|1,R0		;INIT TIMER MUMBO-JUMBO
	STI	R0,@TIMER_CNTL1		;
	LDI	-1,R0			;
	STI	R0,@TIMER_PERIOD1	;
	SETDP

	LDF	0,R0
	LDI	@TIMERAMI,AR0
	RPTS	47	 		;CLEAR OUT COUNT AREA
	STF	R0,*AR0++


	LDL	5A5A5A5Ah,R0	 	;INIT RANDOM NUMBER SEED
	STI	R0,@RAND

	CALL	LOAD_FIXED_PALETTES	;LOAD BASE PALETTES
	CALL	INIT_SYSTEM		;INIT REST OF SYSTEM

	CALL	READIO			;GET I/O STATUS (W/INTs OFF)
	CALL	CHECKDIAG		;GOTO DIAGNOSTICS PREDICATE

	CALL	FIFO_RESET		;CLEAR THE FIFO

	CALL	COMM_INIT

	CALL	TIMER_RESET
	DINT
	CALL	RESET_SNDBRD		;RESET SOUND BOARD (and DB)
	EINT

	CALL	FIFO_RESET
	LDI	INT0_M|INT3_M,IE	;ENABLE INTERRUPTS
	AND     0,IF
	CALL	ENABLEGIE

	CALL	COMM_ENABLE_INT2



	.globl	INITIALIZATION_MOTION_CHECK
	CALL	INITIALIZATION_MOTION_CHECK
	CLRI	R2
	SETAUD	ADJ_OUTOFDIAG


	LDI	1,R0			;INIT BASE OF WAVERAM
	STI	R0,@HARD_SECTION_LOAD
	LDL	_SECshared,AR2
	CALL	LOAD_SECTION_REQ
	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD
	LDL	_SECskys,AR2
	CALL	LOAD_SECTION_REQ

	CALL	MSG2

	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD
	STI	R0,@BOOT_PACIFY_SCREEN_P
	LDL	_SECgeneral,AR2
	CALL	LOAD_SECTION_REQ

	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD
	STI	R0,@BOOT_PACIFY_SCREEN_P
	.globl	_SEChead2head
	LDL	_SEChead2head,AR2
	CALL	LOAD_SECTION_REQ


	CALL	MSG3

	LDI	1,R0			;LOAD 1ST WAVE
	STI	R0,@HARD_SECTION_LOAD
	STI	R0,@BOOT_PACIFY_SCREEN_P

	LDL	_SECpress,AR2
	CALL	LOAD_SECTION_REQ
	LDI	0,R2
	LDI	AUD_BCREDITS,AR2
	CALL	AUDIT_WRITE


	READADJ	ADJ_VOLUME
	LDI	R0,R1
	CALL	SET_MASTER_VOL


	LDP	@WDHIT			;LOG WATCHDOG HIT
	LDI	@WDHIT,R0
	SETDP
	AND	8,R0 			;CHECK B3
	BNZ	NOPEIT
	INCAUD	AUD_NUM_WATCHDOGS
NOPEIT
	CLRI	R0
	STI	R0,@_newbut
	LDI	-1,AR2
	STI	AR2,@_ATTR_MODE
	CALL	WAVE			;setup 1st wave

	CALL	FIFO_RESET
	LDI	INT0_M|INT3_M,IE	;ENABLE INTERRUPTS
	LDP	@COMMINTM
	OR	@COMMINTM,IE
	SETDP
	AND     0,IF
	CALL	ENABLEGIE

	READAUD	AUD_VERSION		;version update???
	CMPI	VERSION_ID,R0
	BNE	VERSION_UPDATE

	CALL	VALIDATE_CMOS		;DIAGNOSTIC CHECK ON CMOS
	BC	CMOS_ERROR		;wait till its better

	

	READAUD	ADJ_ACTUALHSTDRESET	;CHECK FOR HI SCORE RESET
	CMPI	0,R0
	BGT	NODO1
	CALL	INIT_HSTD_TABLES

	READAUD	ADJ_HIGHSCORE_RESET
	LDI	R0,R2
	SETADJ	ADJ_ACTUALHSTDRESET

NODO1	LDI	1,R0
	STI	R0,@NFRAMES
	LDI	0,R0
	STI	R0,@ERRORO
	STI	R0,@ERRORN

	CALL	TIMERESET

	CALL	COMMQ_PACKET_INIT

*----------------------------------------------------------------------------
MAINLOOP:
	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	CALL	FIFO_RESET

	CALL	TIMEREC
	CALL	DECOMPRESS_PROC
	CALL	TIMEREC

MWAIT0	LDI	@INFRAMES,R0
	CMPI	@FRAMRATE,R0		;1 FRAME MINIMUM
	BLT	MWAIT0

	CALL	TIMEREC
	CALL	ZSORTWT			;WAIT FOR PAGE WHILE SORTING
	CALL	TIMEREC

MWAIT	LDI	@CLEARRDY,R0		;DONE WHEN INT SIGNALS PAGE SWAPPED
	BNZ	MWAIT

ENTER2
	;COMMUNICATION XFER
	;
	CALL	COMM_ROUTINE
	CALL	COMMQ_PACKET_INIT
	CALL	DECODE_BUFFER
	
	LDI	@INFRAMES,R0
	CLRI	R1
	STI	R1,@INFRAMES		;CLEAR INTERRUPT COUNTER
	STI	R0,@NFRAMES		;SAVE FOR ALL CURRENT PROCESSES

	CALL	TIMEREC
	STF	R0,@FRAMETIME		;SAVE THE FRAMETIME

	CALL	TIMERESET

	LDI	@_MODE,R4		;FILL FIFO STUFF
	TSTB	MINFIN,R4		;
	CALLNZ	INFINITY

	CALL	TIMEREC

	LDI	@COMM_DRONE_PTR,R0
	CALLNZ	COMM_DRONE_PTR_SORT
	CALL	DIRQ			;DISPLAY THE POLYGONS

	CALL	TIMEREC

	LDI	@_MODE,R4		;FILL FIFO STUFF
	TSTB	MHUD,R4
	BZ	NHUD
	AND	MMODE,R4
	CMPI	MGAME,R4
	BEQ	DOIT8
	CMPI	MBONUS,R4
	BNE	NHUD
DOIT8	CALL	HUD			;HEADS UP DISPLAY (GAME MODE ONLY)
NHUD
	CALL	TIMEREC

	LDI	@_MODE,R4
	AND	MMODE,R4		;THIS MASK IS IMPORTANT!!!!
	CMPI	MATTR,R4
	CALLEQ	INSERT_COINS		
	CALL	VOLUME_DISPLAY

	CALL	TIMEREC

	LDI	@_MODE,R0		;MOTION CABINET LEVELING
	AND	MMODE,R4		;IF NOT IN GAME
	CMPI	MGAME,R4
	BEQ	NODO555
	CALL	LEVEL_THE_MOTION
NODO555

	CALL	CHECKDIAG		;JUMP TO DIAGNOSTICS?
	CALL	SWDISP			;DISPATCH ANY SWITCH PROCESSES

	CALL	COLSCC


	CLRI	R0
	LDP	@MPROC_TIK
	STI	R0,@MPROC_TIK
	SETDP
	CALL	PRC_DISPATCH		;EXECUTE PROCESSES
	CALL	COMMQ_READY_TO_SEND

	CALL	TEXT_OUTPUT		;END FILL FIFO STUFF
	CALL	TIMEREC






	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BNE	MAINLOOP

	;we are in attract mode, set appropriately
	LDI	@DIPRAM,R0
	TSTB	CMDP_MASTER,R0
	BZ	MAINLOOP

	LDI	@OM_ATTR_MODE,AR2
	CMPI	@OLD_OM_ATTR_MODE,AR2
	BEQ	MAINLOOP

	CMPI	-2,AR2		;WE MAY ONLY SYNC ON THE MIDWAY SPIN
	BNE	MAINLOOP

	STI	AR2,@OM_ATTR_MODE
	STI	AR2,@_ATTR_MODE
	CALL	SILENT
        LDI	@FASTSTKI,SP		;GET PAGE OF STORED ADDRESS
	LDI	@_ATTR_MODE,AR2		;AND INTO FP TOO
	CALL	WAVE
	BU	COLD_ENTER
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*WE HAVE A RADICAL SYSTEM CHANGE
*WE WANT TO
*1.	LET EXECUTE ANY PROCESSES THAT WE HAVE BEGUN
*2.	CLEAR THE SCREEN (WHILE STILL VIEWING OLD SCREEN)
*3.	PLOT THE NEW SCREEN
*4.	CONTINUE WITH THE SYSTEM
*
COLD_ENTER:
	FIFO_CLRP	R0		;is the fifo clear
	DMA_WT		R0
	CALL	FIFO_RESET

	LDI	1,R0
	STI	R0,@CLEARRDY		;set clear ready to happen...
	CLRI	R0
	STI	R0,@NOAERASE		;turn auto-erase ON

C_WAIT	LDI	@CLEARRDY,R0		;wait for it to clear
	BNZ	C_WAIT

	CALL	COMMQ_READY_TO_SEND
	CALL	COMM_ROUTINE
	CALL	COMMQ_PACKET_INIT
	CALL	DECODE_BUFFER

	CALL	PRC_DISPATCH
	CALL	COMMQ_READY_TO_SEND

	BR	ENTER2
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*INTERRUPT ROUTINE
*
*1.	initially mask out all interupts we dont want to occur
*2.	enable GIE of ST by calling a routine that RETI's
*	(allows debugger to function)
*3.	increment number of frames passed since last screen update
*
*
ENABLEGIE:
	RETI

INT0:
	PUSH	ST
	LDI	INT1_M,IE	;disable everything except TV30 interrupt & comm int

	ANDN	INT0_M,IF	;we wont irq ourself

	PUSH	DP
	PUSH	R0

	LDP	@COMMINTM
	OR	@COMMINTM,IE

	LDP	@CPU_WS
	LDI	@CPU_WS,R0
	PUSH	R0
	LDI	SOFT_WS,R0
	STI	R0,@CPU_WS

	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	PUSHF	R0
	PUSHF	R1
	PUSHF	R2
	PUSHF	R3
	PUSHF	R4
	PUSHF	R5
	PUSHF	R6
	PUSHF	R7
	PUSH	RC
	PUSH	RS
	PUSH	RE
	PUSH	BK
	PUSH	IR0
	PUSH	IR1
	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR3
	PUSH	AR4
	PUSH	AR5
	PUSH	AR6
	PUSH	AR7

	SETDP


	CALL	PAL_XFER		;TRANSFER QUEUED PALETTES
	LDI	@BGNDCOLA,R0		;SET BACKGROUND COLOR
	LDP	@COLORAM
	STI	R0,@COLORAM
	SETDP				;RESET DP

	CALL	COMM_MASTER_SEND_SYNC
	CALL	ENABLEGIE



	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MDIAG,R0
	BEQ	NTEST
	LDP	@MPROC_TIK
	LDI	@MPROC_TIK,R0
	SETDP
	INC	R0
	CMPI	300,R0
	BLE	REGIT
	ERRON	U,EC_WATCHDOG2
	BU	_c_int00

REGIT	LDP	@MPROC_TIK
	STI	R0,@MPROC_TIK
	SETDP
NTEST



	CALL	FEED_WATCHDOG

	LDI	@CLEARRDY,R0
	BZ	NCLRSCR


	LDI	0,R0
	STI	R0,@CLEARRDY		;RESET SCREEN CLEAR FLAG
	STI	R0,@IFRAMES	 	;RESET INTERRUPT FRAME COUNTER

	.globl	MOTION_RCV_TIKS
	LDI	@MOTION_RCV_TIKS,R0	;MOTION RECEIVE ERROR
	DEC	R0
	STI	R0,@MOTION_RCV_TIKS

	LDI	@NOSWAP,R0		;PAGE SWAP?
	BNZ	NCLRSCR

	LDI	@DISPLAY_PAGE,R0	;PAGE SWAP FLAG
	XOR	1,R0
	STI	R0,@DISPLAY_PAGE
	BNZ	PAGE1

	CALL	SETPAGE1
	CALL	FASTCLR0
	B	DN_PAGE

PAGE1	CALL	SETPAGE0
	CALL	FASTCLR1
DN_PAGE
NCLRSCR

	LDI	@STOPWATCH_CNTL,R0	;STOPWATCH TIMER
	BZ	NOSTOPWUPDT
	INCM	@STOPWATCH
NOSTOPWUPDT

	INCM	@_sectime		;ONE SECOND TIMER
	CMPI	TIKS_PER_SECOND,R0
	BLT	NOTASEC
	CLRI	R0
	STI	R0,@_sectime

	LDI	@_MODE,R5
	AND	MMODE,R5
	CMPI	MDIAG,R5
	BEQ	JJ88
	INCAUD	AUD_POWERON_TIME
	CMPI	MATTR,R5
	BEQ	JJ88
	INCAUD	AUD_GAMEON_TIME

	CMPI	MGAME,R5
	BNE	JJ88

	LDI	@CAMVIEW,AR2
	ADDI	AUD_VIEW1_TIME,AR2
	CALL	AUDIT_INC
JJ88

	


	LDI	@OFFROAD_TMR,R0	 	;OFFROAD TIMER
	SUBI	1,R0
	LDILT	0,R0
	STI	R0,@OFFROAD_TMR


	LDI	@_countdown,R0		;LO DP TIME REMAINING FOR PLAYER
	BLE	NOTASEC

	LDI	@_MODE,R1		;RACE MUST BE HAPPENING TO DECREMENT COUNT
	TSTB	MGO,R1
	BZ	NOTASEC

	SUBI	1,R0
	STI	R0,@_countdown
NOTASEC

	.data
FLOAT_TIK	.float	0.000292397	;(1/60)/57 of a minute
	.text
	LDF	@FLOAT_TIK,R0
	ADDF	@GAME_TIMER,R0
	STF	R0,@GAME_TIMER
NOTINGAME


	INCM	@INFRAMES		;increment number of frames passed since last screen switch
	INCMF	@IFRAMES


	CALL	NUWHEEL			;motorized wheel
	CALL	SNDPROC			;sound processor
	CALL	READIO			;read the switches
	CALL	RANDOM			;randomize further...
	CALL	BUTTONS			;lighted buttons routine
	CALL	COIN_COUNTER		;coin counter routine
	CALL	CHECK_STATE
	CALL	LATCH_ERROR		;motion error



	ANDN	INT0_M,IF		;set 60Hz IRQ no longer pending
	POP	AR7
	POP	AR6
	POP	AR5
	POP	AR4
	POP	AR3
	POP	AR2
	POP	AR1
	POP	AR0
	POP	IR1
	POP	IR0
	POP	BK
	POP	RE
	POP	RS
	POP	RC
	POPF	R7
	POPF	R6
	POPF	R5
	POPF	R4
	POPF	R3
	POPF	R2
	POPF	R1
	POPF	R0
	POP	R7
	POP	R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	POP	R1

	POP	R0
	LDP	@CPU_WS
	STI	R0,@CPU_WS

	POP	R0
	LDI	INT1_M|INT3_M|INT0_M,IE
	LDP	@COMMINTM
	OR	@COMMINTM,IE
	POP	DP
	POP	ST
	RETI
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*READ IO  SWITCHES AND POTS
*
*
	pbss	_newbut,0
	pbss	SWRAM,3       		;SWITCH STATE STORE N,N-1,N-2
SWRAMI	.word	SWRAM

	pbss	DIPRAM,1		;DIP SWITCH RAM COPY

READIO:
	CLRI	AR0			;for Loff production board timing problem
	LDP	@DIPSW
	LDI	@DIPSW,R0
	LDI	*AR0,R2
	LDP	@DIPRAM
	RS	16,R0
	STI	R0,@DIPRAM



	LDP	@SWITCH3
	LDI	@SWITCH3,R0   		;READ HARDWARE 0=CLOSED, 1=OPEN
	LDI	*AR0,R2			;Loff
	LS	16,R0
	LDI	@SWITCH1,R1
	LDI	*AR0,R2			;Loff
	LS	16,R1
	LDP	@FASTSTKI
	RS	16,R1
	OR	R1,R0

	NOT	R0,R1
	LDI	@SWRAMI,AR0
	STI	R1,@SWITCHBUTS


	;
	;SCAN SWITCHES, TRIGGER ON LEADING EDGE
	;
	AND	*AR0,*+AR0(1),R2	;PREVIOUS TWO OPEN
	AND	R1,R2			;CURRENT ONE CLOSED
	OR	*+AR0(2),R2		;OR INTO EDGE LIST
	STI	R2,*+AR0(2)		;STORE EDGE WORD 1=EDGE TRIGGERED

	LDI	*AR0,R1			;GET N-1
	STI	R1,*+AR0(1)		;N-1 --> N-2
	STI	R0,*AR0			;N --> N-1

	PUSH	DP
	LDI	@SYSCNTL,R0	      	;actually we signal a read of the
	LDP	@SYSCNTLR		;have a value
	ANDN	ATOD_WR,R0	      	;pot(s), they interrupt us when they
	STI	R0,@SYSCNTLR		;have a value
	POP	DP

	CLRI	AR0
	LDP	@ATOD_R
	LDI	04h,R0
	LS	24,R0
	STI	R0,@ATOD_R
	LDI	*AR0,R2
	SETDP

	CLRI	R0
	STI	R0,@RDPOT


	;THESE ARE SPECIAL ROUTINES WHICH ARE CALLED, *NOT* CREATED
	;FOR PROCESSES.
	;	THIS INCLUDES:
	;		VOL+
	;		VOL-
	;		DIAG BUTTON
	;NO OTHER ROUTINES SHOULD BE HERE
	LDI	@SWRAM+2,R0
	TSTB	SW_DIAG,R0
	CALLNZ	DIAG_TOGGLE

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BEQ	NIGY
	CMPI	MDIAG,R0
	BEQ	NIGY

	LDI	@SWITCHBUTS,R0
	TSTB	SW_VOLPLUS,R0
	CALLNZ	VOL_PLUS
	TSTB	SW_VOLMINUS,R0
	CALLNZ	VOL_MINUS
NIGY

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
VOL_MINUS:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	AR2

	LDP	@SWRAM+2
	LDI	@SWRAM+2,R0
	ANDN	SW_VOLMINUS,R0
	STI	R0,@SWRAM+2
	SETDP

	.globl	VOLUME_ACTIVE
	LDI	60,R0
	STI	R0,@VOLUME_ACTIVE

	READADJ	ADJ_MIN_VOL_LEVEL
	LDI	R0,R3

	READADJ	ADJ_VOLUME
	DEC	R0
	CMPI	R3,R0
	LDILT	R3,R0

	BU	VOLJN
VOL_PLUS:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	AR2
	LDP	@SWRAM+2
	LDI	@SWRAM+2,R0
	ANDN	SW_VOLPLUS,R0
	STI	R0,@SWRAM+2
	SETDP

	LDI	60,R0
	STI	R0,@VOLUME_ACTIVE

	READADJ	ADJ_MIN_VOL_LEVEL
	LDI	R0,R3

	READADJ	ADJ_VOLUME
	INC	R0
	CMPI	R3,R0
	LDILT	R3,R0
VOLJN
	CMPI	0,R0
	LDILE	0,R0
	CMPI	255,R0		;??? strange - but 249-255 cut off
	LDIGT	255,R0

	LDI	R0,R2
	PUSH	R0
	SETADJ	ADJ_VOLUME
	POP	R1
	CALL	SET_MASTER_VOL

	POP	AR2
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS

DIAG_TOGGLE:
	PUSH	R0
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MDIAG,R0
	BEQ	DTXX

	LDI	@SWRAM+2,R0
	ANDN	010h,R0
	STI	R0,@SWRAM+2
	LDI	@DIAG_ACTIVE,R0
	LDIZ	1,R0
	LDINZ	0,R0
	STI	R0,@DIAG_ACTIVE
DTXX	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*OPTIMIZED 9/14/93-ELP
ATODINT:
	PUSH	ST

	PUSH	IE
	PUSH	DP
	LDP	@COMMINTM
	LDI	@COMMINTM,IE
	SETDP
	CALL	ENABLEGIE

	PUSH	R0
	PUSHF	R0
	PUSH	R6

	LDP	@CPU_WS
	PUSH	R1
	PUSHF	R1
	PUSH	AR0
	LDI	@CPU_WS,R6		;SET WAIT STATES
	LDI	1090h,R0
	STI	R0,@CPU_WS


	LDP	@RDPOT			;WHICH POT TO READ?
	LDI	@RDPOT,R0
	BNZD	RDFOOT
	LDP	@SYSCNTL
	LDI	@SYSCNTL,R1
	ANDN	ATOD_RD,R1
	;---->BNZD	RDFOOT


					;RDSTEER
	LDP	@SYSCNTLR
	STI	R1,@SYSCNTLR
	CLRI	AR0
	LDP	@ATOD_R
	LDI	@ATOD_R,R1
	LDI	*AR0,R0

	LDP	@_pot0
	RS	24,R1
	FLOAT	R1
	FLOAT	@_pot0,R0

	;MAXIMUM SLEW RATE
	;
	SUBF	R0,R1
	CMPF	65,R1
	LDFGT	65,R1
	CMPF	-65,R1
	LDFLT	-65,R1
	ADDF	R0,R1


	MPYF	0.33,R1	  		;SMOOTH WHEEL A TAD
	MPYF	0.67,R0
	ADDF	R1,R0
	FIX	R0
	STI	R0,@_pot0
NOSMOOTH1


	LDP	@SYSCNTL
	LDI	@SYSCNTL,R0		;ACTUALLY WE SIGNAL A READ OF THE
	LDP	@SYSCNTLR		;HAVE A VALUE
	ANDN	ATOD_WR,R0		;POT(S), THEY INTERRUPT US WHEN THEY
	STI	R0,@SYSCNTLR		;HAVE A VALUE

	LDP	@ATOD_R
	CLRI	AR0
	LDI	05h,R0			;SETUP TO READ GAS PEDAL
	LS	24,R0
	STI	R0,@ATOD_R
	LDI	*AR0,R0

	BUD	EXITR
	LDP	@RDPOT
	LDI	1,R0
	STI	R0,@RDPOT
	;---->	BUD	EXITR

RDFOOT
	CMPI	1,R0
	BNED	RDBRAKE

	LDP	@SYSCNTLR
	STI	R1,@SYSCNTLR
	LDP	@ATOD_R			;READ GAS PEDAL
	;---->	BNED	RDBRAKE

	CLRI	AR0
	LDI	@ATOD_R,R1
	LDI	*AR0,R0
	LDP	@_pot1
	RS	24,R1
	FLOAT	R1
	FLOAT	@_pot1,R0
	MPYF	0.33,R1	  		;SMOOTH A TAD
	MPYF	0.67,R0
	ADDF	R1,R0
	FIX	R0
	STI	R0,@_pot1


	LDP	@SYSCNTL
	LDI	@SYSCNTL,R0		;ACTUALLY WE SIGNAL A READ OF THE
	LDP	SYSCNTLR
	ANDN	ATOD_WR,R0		;POT(S), THEY INTERRUPT US WHEN THEY
	STI	R0,@SYSCNTLR

	LDP	@ATOD_R
	LDI	06h,R0			;SETUP TO READ BRAKE PEDAL
	LS	24,R0
	CLRI	AR0
	STI	R0,@ATOD_R
	LDI	*AR0,R0

	BUD	EXITR
	LDP	@RDPOT
	LDI	2,R0
	STI	R0,@RDPOT
	;---->	BUD	EXITR


RDBRAKE

	CLRI	AR0
	LDI	@ATOD_R,R1		;READ BRAKE PEDAL
	LDI	*AR0,R0
	LDP	@_pot2
	RS	24,R1
	FLOAT	R1

	FLOAT	@_pot2,R0
	MPYF	0.25,R1	  		;SMOOTH A TAD
	MPYF	0.75,R0

	ADDF	R1,R0

	FIX	R0
	STI	R0,@_pot2

	LDP	@RDPOT
	LDI	3,R0
	STI	R0,@RDPOT

EXITR
	LDP	@CPU_WS
	POP	AR0
	POPF	R1
	POP	R1
	STI	R6,@CPU_WS
	POP	R6
	POPF	R0
	POP	R0
	POP	DP
	ANDN	INT3_M,IF		;masking a2d int. (no longer pending)
	POP	IE
	POP	ST
	RETI
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*SWITCH DISPATCH	 START PROCESSES FOR SWITCHES
*
SWDISP:
;	LDP	@SWRAM
	LDI	@SWRAM+2,R3
	LS	4,R3 		;MASK GARBAGE
	RS	4,R3
	BZ	SWSTX	 	;NO EDGES ACTIVATED

	LDI	0,R1
	STI	R1,@SWRAM+2	;CLEAR OUT EDGES

	LDI	-1,R1
SWTLP
	ADDI	1,R1
	LSH	-1,R3
	BNC	SWTLP	

;	LDP	@SWTABI
	LDI	@SWTABI,AR0
     	ADDI	R1,AR0
	LDI	*AR0,AR2	;GET WAKEUP
	CMPI	0,AR2
	BEQ	NOGPROC
	LDI	SPAWNER_C|SPWN_SWITCH_T,R2
	CALL	PRC_CREATE	;R2=PID, AR2=WAKEUP ADDR
NOGPROC	LDI	R3,R3
	BNZ	SWTLP
SWSTX

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SWITCH ROUTINE TABLE
*0 = NO PROCESS TO CREATE
SWTABI	.word	SWTAB
SWTAB
	.word	COIN1  		;00000001 SW_COIN1	(COIN.ASM)
	.word	COIN2		;00000002 SW_COIN2 	(COIN.ASM)
	.word	_start		;00000004 START		(INTRO.ASM)
	.word	0		;00000008
	.word	0		;00000010 SW_DIAG	(DIAG.ASM)
	.word	0		;00000020 
	.word	SERV_COIN	;00000040 SW_COINSRV	(COIN.ASM)
	.word	COIN3		;00000080 
	.word	0		;00000100 
	.word	0		;00000200 
	.word	0		;00000400 
	.word	0		;00000800 
	.word	0		;00001000 
	.word	0		;00002000 
	.word	COIN4		;00004000 
	.word	0		;00008000
	.word	0		;00010000 BRAKE
	.word	RADIO_BUT	;00020000 RADIO (OLD ABORT)
	.word	0		;00040000 LOW
	.word	_debug		;00080000 DEBUG
	.word	_VIEW0		;00100000 VIEW0
	.word	_VIEW1		;00200000 VIEW1
	.word	_VIEW2		;00400000 VIEW2
	.word	0		;00800000 VIEW4
	.word	0		;01000000
	.word	0		;02000000
	.word	0		;04000000
	.word	0		;08000000
	.word	0		;10000000
	.word	0		;20000000
	.word	0		;40000000
	.word	0		;80000000
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CHECKDIAG:
	LDI	@DIAG_ACTIVE,R0
	RETSZ
	BR	ENTER_DIAG
;	RETS
*----------------------------------------------------------------------------


PB1	.usect	pbsss,1
PB2	.usect	pbsse,1

PBSS_PTR	.word	PB1
PBSS_BSSEND	.word	PB2

CLR_PBSS:
	PUSH	R0
	PUSH	AR0
	PUSH	RC
	PUSH	RS
	PUSH	RE
	LDI	@PBSS_PTR,AR0

	LDI	@PBSS_BSSEND,RC
	SUBI	AR0,RC
	SUBI	1,RC

	CLRI	R0
	RPTB	PRAMCLP
PRAMCLP	STI	R0,*AR0++

	CALL	CLEAR_LINK

	POP	RE
	POP	RS
	POP	RC
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CLR RAM  (SLOW RAM)
*make sure this is *NOT* done after C initializations
*make sure nothing exists on the stack yet
*
*
RAM_PTR		.word	BSSSTART

;RAM_BSSEND	.word	01F7FFh
RAM_BSSEND	.word	01EFFFh		;save protected hi bss ram

CLR_RAM:
	PUSH	R0
	PUSH	AR0
	PUSH	RC
	PUSH	RS
	PUSH	RE
	LDI	@RAM_PTR,AR0

	LDI	@RAM_BSSEND,RC
	SUBI	AR0,RC
	SUBI	1,RC

	CLRI	R0
	RPTB	RAMCLP
RAMCLP	STI	R0,*AR0++

	POP	RE
	POP	RS
	POP	RC
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*THESE MUST BE CALLED *BEFORE* PROGRAM IS COPIED INTO FAST RAM
*
CLEAR_ONCHIPRAM:
	LDIL	809800h,AR0
	CLRI	R0
	LDI	2047h,RC
	RPTS	RC
	STI	R0,*AR0++
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
SPACER	.set	20
	fbss	BUTTON_TIKS,1
	pbss	BUTTON_STATUS,1
	.bss	OLD_BUTTON_STATUS,1
*
BUTTONS:
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MDIAG,R0
	BEQ	DIAG_BUTTONS
	CMPI	MATTR,R0
	BNE	BUT3

	READAUD	ADJ_FREE_PLAY
	CMPI	1,R0
	BNE	JUSTGOON

	LDI	@BUTTON_STATUS,R0
	OR	BUT_START,R0
	STI	R0,@BUTTON_STATUS
	BU	BUT3
JUSTGOON


	READAUD	AUD_CREDITS
	CMPI	0,R0
	BLE	DASHLIGHT

	.globl	OLD_BUTTON_STATUS
BUT3
	LDI	@BUTTON_STATUS,R0

	TSTB	BUT_START,R0
	BZ	NOSTART

	LDP	@BUTTON_TIKS
	LDI	@BUTTON_TIKS,R1
	INC	R1
	STI	R1,@BUTTON_TIKS
	SETDP
	CMPI	30,R1
	BLT	NOSTART

	ANDN	BUT_START,R0		;TURN IT OFF
	CMPI	60,R1
	BLT	NOSTART

 	CLRI	R1
	LDP	@BUTTON_TIKS
	STI	R1,@BUTTON_TIKS
	SETDP

NOSTART
	LDI	@HEAD2HEAD_ON,R2
	BNZ	PAPAFFD
	CMPI	@OLD_BUTTON_STATUS,R0
	RETSEQ
PAPAFFD	STI	R0,@OLD_BUTTON_STATUS

BUTLITE
	LDIL	SOUND,AR0
	LDI	0FF05h,R1
	LDI	0F705h,R2
	STI	R1,*AR0
	RPTS	SPACER
	NOP
	STI	R2,*AR0
	RPTS	SPACER
	NOP
	STI	R1,*AR0
	RPTS	SPACER
	NOP

	LDI	@HEAD2HEAD_ON,R2
	BZ	KKDAK
	LDI	@THIS_MACHINE_AHEAD,R2
	BNZ	KKDAK
	AND	0FFh,R0
	ANDN	BUT_FRONT,R0
	BU	FDDDA

KKDAK	AND	0FFh,R0
	OR	BUT_FRONT,R0
FDDDA	LDI	R0,R1
	OR	0FF00h,R0
	OR	0FB00h,R1

	STI	R0,*AR0
	RPTS	SPACER
	NOP
	STI	R1,*AR0
	RPTS	SPACER
	NOP
	STI	R0,*AR0
	RPTS	SPACER
	NOP
	RETS


DIAG_BUTTONS:
	LDP	@BUTTON_STATUS
	LDI	@BUTTON_STATUS,R0
	SETDP

	LDP	@BUTTON_TIKS
	LDI	@BUTTON_TIKS,R1
	INC	R1
	STI	R1,@BUTTON_TIKS
	SETDP
	CMPI	30,R1
	BLT	DGBT

	CLRI	R0
	CMPI	50,R1
	BLT	DGBT
	
	CLRI	R1
	LDP	@BUTTON_TIKS
	STI	R1,@BUTTON_TIKS
	SETDP
DGBT

	LDIL	SOUND,AR0
	LDI	0FF05h,R1
	LDI	0F705h,R2
	STI	R1,*AR0
	RPTS	SPACER
	NOP
	STI	R2,*AR0
	RPTS	SPACER
	NOP
	STI	R1,*AR0
	RPTS	SPACER
	NOP

	LDI	R0,R1
	OR	0FF00h,R0
	OR	0FB00h,R1

	STI	R0,*AR0
	RPTS	SPACER
	NOP
	STI	R1,*AR0
	RPTS	SPACER
	NOP
	STI	R0,*AR0
	RPTS	SPACER
	NOP

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*WAIT FOR INTERRUPT AT VBLANK
*
WAIT_FOR_VBLANK:
	LDI	@INFRAMES,R0
WAIT1	CMPI	@INFRAMES,R0		;wait for a hot one
	BZ	WAIT1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CRT_REG_SETUP_STRI
	.word	CRT_REG_SETUP_STR
	romdata
CRT_REG_SETUP_STR
	.word	399|CRT_SETUP_ICSYNC	;CRT_SETUP	
	.word	01ffh		;CRT_HADDRINC
	.word	01feh		;CRT_HBLKSTART
	.word	020eh		;CRT_HSYNCSTART
	.word	0227h		;CRT_HSYNCEND
	.word	0299h		;CRT_HBLKEND
	.word	029ah		;CRT_HTTL

	.word	018eh		;CRT_VBLKSTART
	.word	0191h		;CRT_SYNCSTART
	.word	0194h		;CRT_SYNCEND
	.word	01afh		;CRT_VBLK
	.word	01b0h		;CRT_VTTL
					

;before syncing
;	.word	400|CRT_SETUP_ICSYNC	;CRT_SETUP	
;	.word	01ffh		;CRT_HADDRINC	
;	.word	01feh		;CRT_HBLKSTART	
;	.word	020eh		;CRT_HSYNCSTART
;	.word	0227h		;CRT_HSYNCEND	
;	.word	0299h		;CRT_HBLKEND	
;	.word	029ah		;CRT_HTTL	
;	.word	018fh		;CRT_VBLKSTART	
;	.word	0192h		;CRT_SYNCSTART	
;	.word	0195h		;CRT_SYNCEND	
;	.word	01b0h		;CRT_VBLK	
;	.word	01b0h		;CRT_VTTL	
	.text


CRT_REG_SETUP:
	PUSHM	AR0,AR1,R0,DP
	LDIL	CRT_SETUP,AR0
	LDP	@CRT_REG_SETUP_STRI
	LDI	@CRT_REG_SETUP_STRI,AR1
	LDI	11,RC
	RPTB	CRTRGLP
	LDI	*AR1++,R0
CRTRGLP	STI	R0,*AR0++

	POPM	DP,R0,AR1,AR0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*IF THIS IS EVER HIT STOP AND FIND OUT WHERE IT IS
*COMING FROM
*
ERROR_TRAP:
	CALL	ENABLEGIE
	NOP
	NOP
	NOP
	SLOCKON	U,"ERROR_TRAP INT"
	.if	DEBUG
	BU	$
	.endif
	RETI
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FIFO_RESET:
	DINT
	LDP	@SYSCNTL
	LDI	@SYSCNTL,R0		;READ SHADOW LOCATION
	LDI	R0,R1
	ANDN	1,R1			;MASK OUT FIFORS
	LDP	@SYSCNTLR
	STI	R1,@SYSCNTLR		;STROBE SYSTEM
	STI	R0,@SYSCNTLR		;THEN BACK TO NORMAL
	EINT

	LDP	@FIFO_CONTROL		;RESET COUNTER ON FIFO  (SAFETY FEATURE)
	LDI	FIFO_CONTROL_DMA_RUNSEL|FIFO_CONTROL_FIFO_RST,R0
	STI	R0,@FIFO_CONTROL
	NOP
	LDI	FIFO_CONTROL_DMA_RUNSEL,R0
	STI	R0,@FIFO_CONTROL
	SETDP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*INTERRUPT VECTORS
*
	.sect	"vector"
	.word	_c_int00	;RESET startup			(000h)
	.word	INT0		;INT 0	(display int [60Hz])	(001h)
	.word	ERROR_TRAP	;INT 1	(TV30 interrupt)	(002h)
	.word	COMM_IRQ	;INT 2  (COMM IRQ)		(003h)
	.word	ATODINT		;INT 3	(ATOD CONVERTER DONE)	(004h)
	.word	ERROR_TRAP	;XINT0				(005h)
	.word	ERROR_TRAP	;RINT0				(006h)
	.word	ERROR_TRAP	;XINT1				(007h)
	.word	ERROR_TRAP	;RINT1				(008h)
	.word	ERROR_TRAP	;TINT0				(009h)
	.word	ERROR_TRAP	;TINT1				(00Ah)
	.word	ERROR_TRAP	;DINT				(00Bh)
	.word	ERROR_TRAP	;RESERVED			(00Ch)
	.word	ERROR_TRAP	;RESERVED			(00Dh)
	.word	ERROR_TRAP	;RESERVED			(00Eh)
	.word	ERROR_TRAP	;RESERVED			(00Fh)
	.word	ERROR_TRAP	;RESERVED			(010h)
	.word	ERROR_TRAP	;RESERVED			(011h)
	.word	ERROR_TRAP	;RESERVED			(012h)
	.word	ERROR_TRAP	;RESERVED			(013h)
	.word	ERROR_TRAP	;RESERVED			(014h)
	.word	ERROR_TRAP	;RESERVED			(015h)
	.word	ERROR_TRAP	;RESERVED			(016h)
	.word	ERROR_TRAP	;RESERVED			(017h)
	.word	ERROR_TRAP	;RESERVED			(018h)
	.word	ERROR_TRAP	;RESERVED			(019h)
	.word	ERROR_TRAP	;RESERVED			(01Ah)
	.word	ERROR_TRAP	;RESERVED			(01Bh)
	.word	ERROR_TRAP	;RESERVED			(01Ch)
	.word	ERROR_TRAP	;RESERVED			(01Dh)
	.word	ERROR_TRAP	;RESERVED			(01Eh)
	.word	ERROR_TRAP	;RESERVED			(01Fh)
	.word	ERROR_TRAP	;TRAP 0				(020h)
	.word	ERROR_TRAP	;TRAP 1				(021h)
	.word	ERROR_TRAP	;TRAP 2				(022h)
	.word	ERROR_TRAP	;TRAP 3				(023h)
	.word	ERROR_TRAP	;TRAP 4				(024h)
	.word	ERROR_TRAP	;TRAP 5				(025h)
	.word	ERROR_TRAP	;TRAP 6				(026h)
	.word	ERROR_TRAP	;TRAP 7				(027h)
	.word	ERROR_TRAP	;TRAP 8				(028h)
	.word	ERROR_TRAP	;TRAP 9				(029h)
	.word	ERROR_TRAP	;TRAP 10			(02Ah)
	.word	ERROR_TRAP	;TRAP 11			(02Bh)
	.word	ERROR_TRAP	;TRAP 12			(02Ch)
	.word	ERROR_TRAP	;TRAP 13			(02Dh)
	.word	ERROR_TRAP	;TRAP 14			(02Eh)
	.word	ERROR_TRAP	;TRAP 15			(02Fh)
	.word	ERROR_TRAP	;TRAP 16			(030h)
	.word	ERROR_TRAP	;TRAP 17			(031h)
	.word	ERROR_TRAP	;TRAP 18			(032h)
	.word	ERROR_TRAP	;TRAP 19			(033h)
	.word	ERROR_TRAP	;TRAP 20			(034h)
	.word	ERROR_TRAP	;TRAP 21			(035h)
	.word	ERROR_TRAP	;TRAP 22			(036h)
	.word	ERROR_TRAP	;TRAP 23				(037h)
	.word	ERROR_TRAP	;TRAP 24				(038h)
	.word	ERROR_TRAP	;TRAP 25  (TV30  BREAK POINT)		(039h)
	.word	ERROR_TRAP	;TRAP 26  (TV30  TVBP, TVBPX)		(03Ah)
	.word	ERROR_TRAP	;TRAP 27  (TV30  RPTS/RPTB STATEMENTS)	(03Bh)
	.word	ERROR_TRAP	;TRAP 28  (RESERVED)			(03Ch)
	.word	ERROR_TRAP	;TRAP 29  (RESERVED)			(03Dh)
	.word	ERROR_TRAP	;TRAP 30  (RESERVED)			(03Eh)
	.word	ERROR_TRAP	;TRAP 31  (RESERVED)			(03Fh)
	.text
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
	.if	STATISTICS
	.bss	ST_POLYGONS,1		;number of polygons (total)
	.bss	ST_VERTICES,1		;number of vertices (total)
	.bss	ST_OBJECTS,1		;number of objects (total)
	.endif
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*1ms   = 10 counts
*1mils = 10000
*1frame should = 165000 (roughly)
*
TIMER_RESET:
	PUSH	DP
	PUSH	R0
	LDP	@TIMER_CNTL1
	LDI	@TIMER_CNTL1,R0
	OR	TMR_RESET_GO,R0
	STI	R0,@TIMER_CNTL1
	POP	R0
	POP	DP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TIMER_READ:
	PUSH	DP
	LDP	@TIMER_CNTR1
	LDI	@TIMER_CNTR1,R0
	POP	DP
	RETS
*----------------------------------------------------------------------------


	.bss	TIMEFRAME,1
	.bss	TIMEX,1
	.bss	TIMECLR,1
	.bss	TIMERAM,50

TIMERAMI	.word	TIMERAM

*----------------------------------------------------------------------------
TIMERESET:
	PUSH	DP
	CALL	TIMER_RESET
	SETDP


	LDI	@TIMERAMI,AR0
	STI	AR0,@TIMEX

	LDI	@TIMECLR,R0
	BNZ	TIMEL1

	LDF	@TIMEFRAME,R0
	ADDF	1,R0
	STF	R0,@TIMEFRAME

	CALL	INV_F30

	LDI	@TIMERAMI,AR0
	STI	AR0,@TIMEX

	LDI	15,RC
	RPTB	TIMELP

	LDF	*AR0++,R1
	ADDF	*+AR0(15),R1
	STF	R1,*+AR0(15)

 	MPYF	R0,R1
TIMELP	STF	R1,*+AR0(31)

	POP	DP
	RETS

TIMEL1
	LDI	0,R0
	STI	R0,@TIMECLR
	LDF	0,R0
	STF	R0,@TIMEFRAME
	LDI	@TIMERAMI,AR0

	RPTS	47	 		;CLEAR OUT COUNT AREA
	STF	R0,*AR0++
	POP	DP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TIMEREC:
	PUSH	DP
	PUSH	AR0
	LDP	@TIMER_CNTR1
	FLOAT	@TIMER_CNTR1,R0
	LDP	@TIMEX
	LDI	@TIMEX,AR0
	STF	R0,*AR0++ 	;SAVE THE INDEX
	STI	AR0,@TIMEX
	POP	AR0
	POP	DP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
MESSAGE1:
	CLRI	R0
	LDP	@9E0000h
	STI	R0,@9E0000h
	LDI	-1,R0
	STI	R0,@9E0001h		;white
	LDI	06000h,R0
	STI	R0,@9E0003h		;red
	LDI	0294Ah,R0
	STI	R0,@9E000Bh		;grey
	SETDP

	CALL	CLRSCRN
	CALL	SETPAGE0

	LDIL	SCREEN0,R0		;set active screen to 1 (writeable)
	STI	R0,@ACTIVE_SCREEN


	LDI	1,RC
	TEXTIT	startup0,1,40
	TEXTIT	startup1,1,70
	TEXTIT	startup2,1,80
	TEXTIT	startup3,1,90
	LDI	11,RC
	TEXTIT	dlts,40,110

	LDI	1,RC
	TEXTIT	VERSION_STAMP,40,130
	TEXTIT	INTERNAL_VERS,260,150
	TEXTIT	DATE_STAMP,40,150


	CLRI	AR0
	LDP	@DIPSW
	LDI	@DIPSW,R0
	LDI	*AR0,AR0
	RS	16,R0
	SETDP

	TSTB	DIP_COMMP,R0
	BZ	DODOIBO
	LDI	@LINKDISABLED,AR2
	BU	HJSADF

DODOIBO	TSTB	CMDP_MASTER,R0
	LDIZ	@IAMMASTER,AR2
	LDINZ	@IAMSLAVE,AR2
HJSADF	LDI	40,R2
	LDI	160,R3
	CALL	_outtextxyc



	;test if link pal is installed
	;
	;
COMMPAL		.set	0990000h	;COMMUNICATIONS PAL
	CLRI	AR0
	LDP	@COMMPAL
	LDI	@COMMPAL,R0
	LDI	*AR0,R1
	SETDP

	AND	0FH,R0
	CMPI	4,R0			;BAD PAL ?
	LDIZ	@TPALI,AR2
	LDINZ	@TPALNI,AR2
	LDI	40,R2
	LDI	170,R3
	LDI	1,RC
	CALL	_outtextxyc
	;
	;





	LDI	239,AR2
	LDI	110,R2
	LDI	301,R3
	LDI	117,RC
	LDI	11,RS
	CALL	_rectangle

	LDI	11,RC
	TEXTIT	M1,1,190
	RETS

	.bss	MSG_CNT,1
MSG1:	LDI	11,RC
	TEXTIT	M2,1,200
	TEXTIT	M3,1,220
	TEXTIT	M4,1,230
	TEXTIT	M5,1,240
	RETS

MSG2:	LDI	11,RC
	TEXTIT	M6,1,260
	TEXTIT	M7,1,270
	RETS

LINKDISABLED	SPTR	"LINK DISABLED BY U97  DIP6 OFF"
IAMMASTER	SPTR	"LINK MASTER MACHINE"
IAMSLAVE	SPTR	"LINK SLAVE MACHINE"
TPALI		SPTR	"U38 LINK PAL INSTALLED"
TPALNI		SPTR	"U38 LINK PAL NOT INSTALLED"
	
MSG3:	LDI	11,RC
	TEXTIT	M8,1,280
	TEXTIT	M9,1,290
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*SECRET OCTOPUS
*
*
NUM_STATES	.set	7
STATE_TABLE	.word	SW_VIEW0|SW_VIEW2
		.word	SW_VIEW2
		.word	SW_VIEW1|SW_VIEW2
		.word	SW_VIEW1
		.word	SW_VIEW0|SW_VIEW1
		.word	SW_VIEW0
		.word	SW_VIEW0|SW_RADIO
STATE_TABLEI	.word	STATE_TABLE
*
STATE_MASK	.word	SW_VIEW0|SW_VIEW1|SW_VIEW2|SW_RADIO
*
		.bss	STATE_NUM,1
		.bss	STATE_TIK,1

*
*
*
CHECK_STATE:
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MATTR,R0
	BNE	ABORT_STATE
	
	LDI	@SWITCHBUTS,R2

	LDI	@STATE_NUM,AR0
	LDI	AR0,R0

	ADDI	@STATE_TABLEI,AR0
	LDI	*AR0,R1

	AND	@STATE_MASK,R2
	CMPI	R1,R2		;ADVANCE TO NEXT STATE?
	BEQ	NEXTSTATE

	LDI	@STATE_NUM,R1
	BZ	ABORT_STATE
	DEC	R1
	LDI	R1,AR0
	ADDI	@STATE_TABLEI,AR0
	LDI	*AR0,R1
	CMPI	R1,R2		;IS IT THE PREVIOUS STATE??
	BNE	ABORT_STATE

	LDI	@STATE_TIK,R0
	DEC	R0		;ABORT STATE
	BLT	ABORT_STATE
	STI	R0,@STATE_TIK
	RETS


NEXTSTATE
	LDI	@STATE_NUM,R0
	INC	R0
	CMPI	NUM_STATES,R0
	BEQ	DODIAG
	STI	R0,@STATE_NUM

	LDI	120,R0
	STI	R0,@STATE_TIK
	RETS
DODIAG
	CLRI	R0
	STI	R0,@STATE_NUM
	STI	R0,@STATE_TIK
	.globl	HIDDEN_DIAG
	BR	HIDDEN_DIAG
	
*
*
*
ABORT_STATE:	
	CLRI	R0
	STI	R0,@STATE_NUM
	STI	R0,@STATE_TIK
	RETS
*----------------------------------------------------------------------------


	.bss	BUTTON_IBO,1
	.bss	BUTTON_TIK,1
*----------------------------------------------------------------------------
BUTTONI	.word	BUTTII
BUTTII	.word	BUT_VIEW1,BUT_VIEW2,BUT_VIEW3,BUT_VIEW2
*
DASHLIGHT:
	LDI	@BUTTON_TIK,R0
	INC	R0
	LDILT	0,R0
	STI	R0,@BUTTON_TIK
	CMPI	60,R0
	RETSLT	

	LDI	0,R0
	STI	R0,@BUTTON_TIK

	LDI	@BUTTON_IBO,R0
	INC	R0
	CMPI	3,R0
	LDIGE	0,R0
	CMPI	0,R0
	LDILT	0,R0
	STI	R0,@BUTTON_IBO
	LDI	R0,AR0
	ADDI	@BUTTONI,AR0
	LDI	*AR0,R0
	B	BUTLITE
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CMOS_ERROR:
	LDI	8,AR6
FLASH_LP
	CALL	CLRSCRN			;CMOS WAS RESET
	CALL	SETPAGE0

	LDIL	SCREEN0,R0		;set active screen to 1 (writeable)
	STI	R0,@ACTIVE_SCREEN

	LDI	100,AR5
FLASH_LP1
	LDI	1,RC
	TEXTITT	"CMOS ERROR",216,190
	TEXTITT	"FACTORY ADJUSTMENTS RESTORED",144,200
	DBU	AR5,FLASH_LP1

	CALL	FEED_WATCHDOG
	DBU	AR6,FLASH_LP
	CALL	FAKEDIAG

	CALL	SET_CONTROLS
	BR	DIAG_RETURN	
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
VERSION_UPDATE:
	LDI	8,AR6
VFLASH_LP
	CALL	CLRSCRN			;CMOS WAS RESET
	CALL	SETPAGE0

	LDIL	SCREEN0,R0		;set active screen to 1 (writeable)
	STI	R0,@ACTIVE_SCREEN

	LDI	100,AR5
VFLASH_LP1
	LDI	1,RC
	TEXTITT	"VERSION UPDATED",196,190
	TEXTITT	"FACTORY SETTINGS RESTORED",156,200
	DBU	AR5,VFLASH_LP1

	CALL	FEED_WATCHDOG
	DBU	AR6,VFLASH_LP

;RESET YOUR SHIT
	CALL	FAKEDIAG

	CALL	FFRSUB
	LDI	VERSION_ID,R2
	SETAUD	AUD_VERSION
	BR	DIAG_RETURN	
*----------------------------------------------------------------------------


	.globl	FFRSUB,SET_CONTROLS,DIAGPAL
*----------------------------------------------------------------------------
	.globl	FAKEDIAG
FAKEDIAG:
	CALL	INIT_SYSTEM
	CALL	PAL_INIT
	LDL	DIAGPAL,AR2
	CALL	PAL_ALLOC_RAW
	LDI	4210H,R0
	STI	R0,@BGNDCOLA
	LDI	MDIAG,R0		;set mode appropriate
	STI	R0,@_MODE
 	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FEED_WATCHDOG:
	PUSH	DP
	PUSH	R0
	LDP	@CPU_WS
	LDI	@CPU_WS,R0
	PUSH	R0

	LDI	SOFT_WS,R0
	STI	R0,@CPU_WS

	LDP	@SYSCNTL
	LDI	@SYSCNTL,R0
	XOR	WDOG,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR

	POP	R0
	LDP	@CPU_WS
	STI	R0,@CPU_WS
	POP	R0
	POP	DP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
	fbss	SYSCNTL_OC,1
	.globl	FEED_WATCHDOG_HARD
FEED_WATCHDOG_HARD:
	PUSH	DP
	PUSH	R0
	LDP	@CPU_WS
	LDI	@CPU_WS,R0
	PUSH	R0

	LDI	1068h,R0
	STI	R0,@CPU_WS

	LDP	@SYSCNTL
	LDI	@SYSCNTL,R0
	XOR	WDOG,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR

	POP	R0
	LDP	@CPU_WS
	STI	R0,@CPU_WS
	POP	R0
	POP	DP
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
	.globl	BSSSTART
BSSSTARTI	.word	BSSSTART
VERIFY_CODE_INTEGRITY:
	.if	DEBUG
	;
	;verify that the code has not been corrupted
	;
	;*this only works in RAM
	;and, if used in ROM will cause a lockup
	;

	LDI	40h,AR1			;SOURCE ADDRESS
	LDI	0C00h,AR2		;DESINATION ADDRESS
	LS	12,AR2
	ADDI	40h,AR2

	LDI	@BSSSTARTI,RC
	SUBI	041h,RC

	RPTB	LD_CHK1
	LDI	*AR1++,R0

	CMPI	*AR2++,R0
	.if	CODE_CHECK
	BNE	$
	.endif
LD_CHK1	NOP
	.endif
	RETS
*----------------------------------------------------------------------------
	.END
