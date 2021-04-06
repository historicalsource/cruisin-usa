	.FILE	"UTIL.ASM"
*----------------------------------------------------------------------------
*UTILITY ROUTINES
*
*COPYRIGHT (C) 1994 BY TV GAMES,INC.
*ALL RIGHTS RESERVED
*
*
	.include	MPROC.EQU
	.include	C30.EQU
	.include	MACS.EQU
	.include	OBJ.EQU
	.include	OBJECTS.EQU
	.include	GLOBALS.EQU
	.include	SYS.EQU
	.include	TEXT.EQU
	.include	VUNIT.EQU
	.include	CMOS.EQU
	.include	SNDTAB.EQU
	.include	PALL.EQU
	.include	SYSID.EQU
	.include	DIRQ.EQU
	.include	DELTA.EQU


	.text

	pbss	RAND,1		;RANDOM SEED
	.bss	CRTCTLRAM,1	;SHADOW RAM FOR CRT CONTROLLER
	.bss	ACTIVE_SCREEN,1	;start of active screen (not visual screen)


*----------------------------------------------------------------------------
*ROM DEFINITIONS
*
LINE255I	.word	SCREEN0+3F000H 	;LAST LINE PAGE 0
LINE511I	.word	SCREEN0+7FC00H	;LAST LINE PAGE 1

SCREEN0I	.word	SCREEN0		;PAGE ZERO OF SCREEN
SCREEN1I	.word	SCREEN1		;PAGE ZERO OF SCREEN
SCRSIZI		.word	3FFFFH


	.if	DEBUG
*----------------------------------------------------------------------------
*TV30 DEBUGGING ROUTINES
*
*The two rountines TVBP, and TVBPX, if present, are called upon entering and
*exiting a breakpoint (respectively).
*
	.def	TVBP,TVBPX,TVPATCH,TVPATCHX
TVBP:	RETS
TVBPX:	RETS
TVPATCH:
	.space	25
TVPATCHX
*----------------------------------------------------------------------------
	.endif


*----------------------------------------------------------------------------
*SET SCREEN DISPLAY TO PAGE 0  (AND WRITE PAGE TO 1)
*
SETPAGE0:
;	.if	DEBUG
	LDI	@PAGEWORD,R0
	BNE	P1
;	.endif

	LDI	@SCREEN1I,R0		;set active screen to 1 (writeable)
	STI	R0,@ACTIVE_SCREEN

	LDP	@DMA_SETUP
	LDI	@DMA_SETUP,R0
	ANDN	DMA_VIDEO_PAG_DISPLAYED,R0
	OR	DMA_DMA_WRITE_PAGE,R0
	STI	R0,@DMA_SETUP
	SETDP

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*SET SCREEN DISPLAY TO PAGE 1	(AND WRITE PAGE TO 0)
*
SETPAGE1:
;	.if	DEBUG
	LDI	@PAGEWORD,R0
	BNE	P1
;	.endif

	LDI	@SCREEN0I,R0		;set active screen to 1 (writeable)
	STI	R0,@ACTIVE_SCREEN

	LDP	@DMA_SETUP
	LDI	@DMA_SETUP,R0
	OR	DMA_VIDEO_PAG_DISPLAYED,R0
	ANDN	DMA_DMA_WRITE_PAGE,R0
	STI	R0,@DMA_SETUP
	SETDP
	RETS

;	.if	DEBUG
PAGEWORD	.WORD	0
P1
	LDI	@SCREEN1I,R0		;set active screen to 1 (writeable)
	STI	R0,@ACTIVE_SCREEN

	LDP	@DMA_SETUP
	LDI	@DMA_SETUP,R0
	OR	DMA_VIDEO_PAG_DISPLAYED+DMA_DMA_WRITE_PAGE,R0
	STI	R0,@DMA_SETUP
	SETDP
	RETS
;	.endif
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SRT PAGE ONE
*
*CLEAR SCREEN FAST SHIFT REGISTER TRANSFER
*CALL ONLY DURING VBLANK
*
FASTCLR0:
FASTCLR1:
	LDI	@NOAERASE,R0
	RETSNZ

	LDI	0,AR2		;X
	STI	AR2,@_ACNTL
	LDI	0,R2		;Y
	LDI	511,R3		;X2
	LDI	399,RC		;Y2
	LDI	0,RS		;PAL
	LDI	0A0h,RE		;ADDR
	RS	16,RE
	CALL	_rdma
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CLEAR SCREEN BITMAP
*
CLRSCRN:
	CALL	CLRSCRN0
CLRSCRN1:			;CLEAR BITMAP 1
	PUSH	AR2
	LDI	@SCREEN1I,AR2
	B	CLRSC00

CLRSCRN0:
	PUSH	AR2
	LDI	@SCREEN0I,AR2

CLRSC00	PUSH	R3
	LDI	@SCRSIZI,R3

CLRSC01:
	PUSH	R2
	LDI	0,R2
	CALL	SCREEN_FILL
	POP	R2
	POP	R3
	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CLEAR LINE 255,255 OF BITMAP
*
CLR255:
	PUSH	AR2
	PUSH	R3
	LDI	@LINE255I,AR2
	LDI	1023,R3		;ONE ROW ONLY
	B	CLRSC01
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CLEAR LINE 511,511 OF BITMAP
*
CLR511:
	PUSH	AR2
	PUSH	R3
	LDI	@LINE511I,AR2
	LDI	1023,R3		;ONE ROW ONLY
	B	CLRSC01
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*FILL SCREEN
SCRNFIL:
	LDI	@SCREEN0I,AR2
	LDI	@FILSIZI,R3
	LDI	@FILWORD,R2	;fill it with some crud
	B	SCREEN_FILL

FILSIZI	.word	3FFFFH
FILWORD	.word	93093H
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SCREEN WRITER
*
*PARAMETERS
*	AR2	START ADDRESS
*	R2	COLOR
*	R3	COUNT-1
*
SCREEN_FILL:
	PUSH	R0
	PUSH	AR1
	PUSH	AR2
	PUSH	IE

	LDP	@COMMINTM
	LDI	@COMMINTM,IE
	SETDP

	PUSH	DP
	LDP	@CPU_WS
	LDI	0,AR1
	LDI	R3,RC

	LDI	HARD_WS,R0
	STI	R0,@CPU_WS

	RPTB	CLRSCL
	STI	R2,*AR2++
CLRSCL	LDI	*AR1,R0		;DUMMY READ FOR WAIT STATE SHIT

	LDP	@CPU_WS
	LDI	SOFT_WS,R0
	STI	R0,@CPU_WS
	POP	DP

	POP	IE
	POP	AR2
	POP	AR1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CLEAR COLOR RAM
*
CLRCRAM:
	LDI	COLORAM>>16,AR0
	LSH	16,AR0
	LDI	0,R1
	RPTS	07FFFH
	STI	R1,*AR0++
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*RANDOM NUMBER UTILITIES
*----------------------------------------------------------------------------
*RANDOM - GENERATE A RANDOM NUMBER
*RETURNS
*	R0	32 BIT RANDOM #		  
*   
RANDOM:
	PUSH	R1
	LDI	@RAND,R0
	LDI	R0,R1
	LSH	1,R0
	XOR	R0,R1
	BNN	RND2
	OR	1,R0
RND2	POP	R1
	MPYI	794Fh,R0
	STI	R0,@RAND
	RETS	
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*FLOATING POINT RANDOM
*
*PARAMETERS
*	R0	NUMBER
*RETURNS
*	R0	RANDOM NUMBER 0->N FLOATING POINT
*
FRAND:
	PUSH	AR2
	PUSHFL	R1

	PUSHF	R0
	LDI	10000,AR2
	CALL	RANDU0
	FLOAT	R0

	MPYF	0.01,R0
	MPYF	0.01,R0
	POPF	R1
	MPYF	R1,R0

	POPFL	R1
	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SIGNED FLOATING POINT RANDOM
*
*PARAMETERS
*	R0	FL NUMBER
*RETURNS
*	R0	FL RANDOM NUMBER -N->+N FLOATING POINT
*
SFRAND:
	PUSH	R1
	PUSHF	R1
	PUSHF	R0
	MPYF	2,R0
	CALL	FRAND
	POPF	R1
	SUBF	R1,R0
	POPF	R1
	POP	R1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*RANDOM UNSIGNED 0 TO N-1
*
*PARAMETERS
*	AR2	N  RANGE INPUT (0-FFFF)
*RETURNS
*	R0	RANDOM # BETWEEN 0 AND [AR2]
*             
RANDU0:
	CALL	RANDOM
	LSH	-16,R0
	MPYI	AR2,R0
	LSH	-16,R0
	RETS		
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*RANDOM UNSIGNED
*
*PARAMETERS
*	AR2	N
*RETURNS
*	R0	RANDOM # BETWEEN 1 AND N
RANDU:
	CALL	RANDU0
	ADDI	1,R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SIGNED RANDOM
*
*PARAMETERS
*	AR2	N
*RETURNS
*	R0	RANDOM # IN RANDGE +/- N
*
SRAND:
	LSH	1,AR2
	ADDI	1,AR2
	CALL	RANDU0
	LSH	-1,AR2
	SUBI	AR2,R0
	RETS
*----------------------------------------------------------------------------


;*----------------------------------------------------------------------------
;*RANGE RANDOM
;*PARAMETERS
;*	AR2	LOWER BOUND
;*	R2	UPPER BOUND
;*RETURNS
;*	R0	RANDOM # FROM AR2 TO R2
;*                 
;RANGRAND:
;	SUBI	AR2,R2,R0
;	ADDI	1,R0
;	CALL	RANDU0
;	ADDI	AR2,R0
;	RETS
;*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*RANDOM % ROUTINE
*
*PARAMETERS
*	AR2	PROBABILITY OF EVENT (0-1000) P(A0=1000) = 1; P(A0=1) = 1/1000.
*RETURNS
*	C=1	IF PROBABILITY IS TRUE, 
*		R0	ACTUAL RANDOM # 0-999 
*	C=0	FOR FALSE
*		R0	ZERO 
RANDPER:
	CALL	RANDOM
	LSH	-16,R0
	MPYI	1000,R0
	LSH	-16,R0
	CMPI	AR2,R0
	BC	RANDPX
	LDI	0,R0
RANDPX
	RETS		
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
*GENERIC LINKED LIST ROUTINES
*These routines are for use with any linked list situation that do not
*require special attention (such as the object list).
*
*----------------------------------------------------------------------------
*void	INIT_LINKED_LIST(start_addr, free_list, active_list, length-1, size)
*
*PARAMETERS
*	AR2	START ADDRESS
*	R2	FREE LIST
*	R3	ACTIVE LIST
*	RC	LENGTH-1
*	RS	ENTRY SIZE
*
*
INIT_LINKED_LIST:
	PUSH	R0
	PUSH	AR0
	LDI	R3,AR0		;ZERO ACTIVE POINTER
	LDI	0,R0
	STI	R0,*AR0

	LDI	R2,AR0	 	;GET FREE POINTER
	LDI	RS,R0		;SAVE THE SIZE

	RPTB	INIT_LL
	STI	AR2,*AR0
	LDI	AR2,AR0
INIT_LL	ADDI	R0,AR2

	LDI	0,R0
	STI	R0,*AR0
	POP	AR0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GET_LLIST(free_list,active_list)
*GET A LINKED LIST ELEMENT AND INSERT ON LIST
*
*
*PARAMETERS
*	AR2	FREELIST PTR
*	R2	ACTIVE LIST PTR
*
*RETURNS
*	(SUCCESSFUL)
*		AR0	LIST ELEMENT (INSERTED INTO ACTIVE LIST)
*		R0	LIST ELEMENT (INSERTED INTO ACTIVE LIST)
*		CARRY SET
*	(UNSUCCESSFUL)
*		CARRY CLEAR
*
GET_LLIST:
	PUSH	R1
	PUSH	AR1
	LDI	*AR2,R0
	SLOCKON	Z,"GET_LLIST  out of elements"
	BZ	GETLL_ERR

	LDI	R0,AR0

	LDI	*AR0,AR0
	STI	AR0,*AR2		;and update free list

	;insert into the active list
	LDI	R2,AR1			;get ptr to active
	LDI	R0,AR0			;get ptr to element
	LDI	*AR1,R1			;get 1st element in active
	STI	R1,*AR0			;link element into element
	STI	AR0,*AR1		;store element into active

	SETC
GETLL_X
	POP	AR1
	POP	R1
	RETS
GETLL_ERR
	CLRC
	BU	GETLL_X
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*ALLOC_LLIST(free_list)
*GET A LINKED LIST ELEMENT (DO NOT INSERT TO ACTIVE)
*
*PARAMETERS
*	AR2	FREE LIST
*RETURNS
*	AR0	LIST ELEMENT (NOT INSERTED INTO ACTIVE LIST)
*
ALLOC_LLIST:
	PUSH	R0
	LDI	*AR2,R0
	SLOCKON	Z,"_allocllist  out of elements"
	BZ	ALLOCLIST_ISERROR


	LDI	R0,AR0

	LDI	*AR0,AR0
	STI	AR0,*AR2		;and update free list
	LDI	R0,AR0
	SETC
ALLOCLIST_X
	POP	R0
	RETS

ALLOCLIST_ISERROR
	CLRC
	BU	ALLOCLIST_X
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*FREE_LLIST(element, active, free)
*FREE AN ELEMENT OF A LINKED LIST
*
*PARAMETERS
*	AR2	OBJECT
*	R2	free list
*
*
FREE_LLIST:
	PUSH	R2
	PUSH	AR0
	LDI	R2,AR0		;free
	LDI	*AR0,R2
	STI	R2,*AR2
	STI	AR2,*AR0
	LDI	AR0,R2
	POP	AR0
	POP	R2
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*DEL_LLIST(element, active, free)
*DELETE AN ELEMENT OF A LINKED LIST
*
*PARAMETERS
*	AR2	OBJECT
*	R2	ACTIVE LIST
*	R3	FREE LIST
*
DEL_LLIST:
	PUSH	R0
	PUSH	R1
	PUSH	AR0
	PUSH	AR1

	LDI	R2,R1


DELLP	LDI	R1,AR1
	LDI	*AR1,R1
	SLOCKON	Z,"DEL_LLIST  end of list found"
	BZ	DEL_LLX

	CMPI	R1,AR2
	BNE	DELLP

	LDI	*AR2,R1		
	STI	R1,*AR1			;LINK AROUND

	LDI	R3,AR1			;get free list pointer
	LDI	*AR1,R1
	STI	R1,*AR2
	STI	AR2,*AR1

DEL_LLX
	POP	AR1
	POP	AR0
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*VEHICLE ANIMATION UTILITIES
*
*----------------------------------------------------------------------------
*
*GET DYNAMIC OBJECTS FOR A CAR
*
*PARAMETERS
*	AR2	INDEX OF VEHICLE
*	AR4	CAR OBJECT
*
VEHICLE_ANI_INIT:
	PUSH	AR0
	PUSH	AR3


	MPYI	VEHTAB_SIZE,AR2
	ADDI	@VEHICLE_TABLEI,AR2
	LDI	*+AR2(VEHTAB_ANI),AR2
	CMPI	0,AR2			;COULD BE A NULL ENTRY (NO ANIMATION)
	BEQ	VANIX

	LDI	O_DYNAMIC,R0	 	;MAKE PARENT OBJECT DYNAMIC
	OR	*+AR4(OFLAGS),R0
	STI	R0,*+AR4(OFLAGS)


*INITIALIZE CENTERXYZ,TRANSXYZ,VERTS

	LDI	AR4,AR3
	ADDI	ODYNALIST,AR3

	LDI	*AR2++,RC		;GET DYNAMIC OBJECT COUNT
	RPTB	WHEELLP

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
WHEELLP	LDI	AR0,AR3

	LDI	0,R0
	STI	R0,*AR3			;LAST LINK IS ZERO, DUDES

*GET A CAR PROCESS

	LDI	*AR2++,R0		;GET PROCESS POINTER

	LDI	@CARPROCI,AR2
	LDI	DRONE_C|ANI_T,R2	;PID
	CALL	PRC_CREATE_CHILD
	STI	AR0,*+AR4(ORADZ)	;DOUBLING AS A PROC PTR
VANIX
	POP	AR3
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CAR PROCESS
*
*	SPINS WHEELS
*	TURNS FRONT WHEELS
*	LEANS BODY
*
*PARAMETERS
*	AR4	CAR OBJECT
*	AR5	CAR BLOCK
*	R6	X RADIANS	;FOR WHEEL SPIN
*USES
*	AR3	DYNA OBJECT
*	AR4	MASTER OBJECT 
*	AR5	CAR BLOCK
*	AR6	DYNAMATRIX
*	R4	OLD ORADY
*	R5	Z RADIANS FOR BODY LEAN
*	R6	X RADIANS FOR BODY LEAN
*	R7	OLD CAR SPEED
*	PDATA	OLD CAR ORADY
*	PDATA+1 BODY LEAN Z RADIANS
*	PDATA+2 X RADIANS FOR WHEEL SPIN
CARPROCI	.WORD	CARPROC
CARPROC:
	LDI	*+AR4(OCARBLK),AR5

	LDF	0,R6	 		;INIT SPIN RADIANS

	LDF	*+AR5(CARSPEED),R0	;INIT SPEED
	LDF	R0,R7

	LDF	*+AR4(ORADY),R0
	STF	R0,*+AR7(PDATA)		;INIT OLD ORADY

	CLRF	R5			;INITIALIZE BODY Z RADIANS
	STF	R5,*+AR7(PDATA+1)	;SAVE Z RADIANS

	LDF	0,R0			;INITIALIZE WHEEL X RADIANS
	STF	R0,*+AR7(PDATA+2)	;SAVE WHEEL X RADIANS
CARPROCL
	LDI	3,AR2	  		;SLEEP TIME
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MINTRO,R0
	BEQ	NCS

	LDI	@_MODE,R2		;ARE WE AT STARTING LINE?
	TSTB	MSLINE,R2
	BNZ	NCS


	LDI	@SUSPEND_MODE,R0
	CMPI	SM_HALT,R0
	BNE	NCS

	LDF	*+AR5(CARSPEED),R7	;UPDATE OLD SPEED TO AVOID JERK
	B	CARSLP
NCS

	LDI	*+AR4(ODIST),R0
	CMPI	20000,R0		;FAR OFF JUST SLEEP
	BGT	CARSLP
*GET FRONT WHEEL STEER MATRIX

	LDF	*+AR5(CARTURN),R2
	MPYF	1.5,R2			;BOOST TURN A LITTLE
	
	LDI	@MATRIXAI,AR2
	CALL	FIND_YMATRIX
	LDI	AR2,AR0

*GET WHEEL SPIN MATRIX

	LDF	*+AR5(CARSPEED),R2
	MPYF	0.02,R2   		;FUDGE FACTOR

	ADDF	*+AR7(PDATA+2),R2
	STF	R2,*+AR7(PDATA+2)	;SAVE WHEEL X RADIANS

	LDI	@MATRIXBI,AR2		;GET X SPIN IN MATRIXB
	CALL	FIND_XMATRIX

*CONCAT FOR FRONT WHEELS

	LDI	@MATRIXCI,AR1		;A X B = C
	
	LDI	AR1,AR6			;SAVE FRONT WHEEL MATRIX PTR
	LDI	AR2,AR3			;SAVE REAR WHEEL MATRIX PTR
	CALL	CONCAT201    		;CONCAT YOUR MATRICES INTO DYNOBJ

*STUFF YOUR DYNAMIC MATRICES

	LDI	*+AR4(ODYNALIST),R0
	SLOCKON	Z,"UTIL\CARPROC   dynamic objects not found"

CDTOP
	LDI	R0,AR0
	LDI	*+AR0(DYNAFLAG),R0
	BN	CDLP			;SHADOW...CONTINUE
	BZ	CARBODY			;HANDLE BODY

	LDI	AR0,AR2
	ADDI	DYNAMATRIX,AR2

	CMPI	1,R0
	BZ	CARRWHL			;REAR WHEEL

*STUFF FRONT WHEEL

	LDF	*AR6++,R0
	
	RPTS	7
	LDF	*AR6++,R0
 ||	STF	R0,*AR2++	

 	STF	R0,*AR2++	
	NOP	*AR6--(9)
	B	CDLP

*STUFF REAR WHEEL

CARRWHL
	LDF	*AR3++,R0
	
	RPTS	7
	LDF	*AR3++,R0
 ||	STF	R0,*AR2++	

 	STF	R0,*AR2++	
	NOP	*AR3--(9)

CDLP
	LDI	*AR0,R0
	BNZ	CDTOP
	LDI	3,AR2	  		;SLEEP TIME
	B	CARSLP

*HANDLE BODY
*BODY MUST BE LAST
CARBODY
	CALL	LEAN
	LDI	1,AR2
CARSLP
	CALL	SLEEP	
	B 	CARPROCL
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
NTWOPII	.float	-TWOPI
*
*LEAN BODY IN Z
*
*PARAMETERS
*	AR0	DYNA OBJECT
*	AR4	MASTER OBJECT 
*	AR5	CAR BLOCK
*	AR6	DYNAMATRIX
*	R4	OLD ORADY
*	R5	Z RADIANS
*	R6	X RADIANS
*	R7	OLD SPEED
*	PDATA	OLD CAR ORADY
*	PDATA+1 BODY LEAN Z RADIANS
*
LEAN:
	LDI	AR0,AR1
	ADDI	DYNAMATRIX,AR1	

	;GET X LEAN (BRAKE/ACCEL)
	;

	LDF	R7,R0
	LDF	*+AR5(CARSPEED),R7	;GET NEW SPEED
	SUBF	R0,R7,R0

	MPYF	0.06,R0			;CONVERT TO RADIANS
	ADDF	R0,R6
	MPYF	0.25,R6
	NEGF	R6,R2
	LDI	*+AR5(CAR_AIRF),R0
	OR	*+AR5(CAR_AIRB),R0
	LDFNZ	0,R2 			;ZERO OUT WHEN IN AIR FOLKS

	LDF	R2,R2			;AMPLIFY ACCELERATION ONLY
	LDFGT	1,R1
	LDFLT	2,R1
	MPYF	R1,R2

	LDF	*+AR5(CARRPM),R0      	;REV FACTOR
	MPYF	0.01,R0
	MPYF	-0.05,R0
	ADDF	R0,R2


	CMPF	0.1,R2			;LIMIT CHECK
	LDFGT	0.1,R2
	CMPF	-0.1,R2
	LDFLT	-0.1,R2
	STF	R2,*+AR5(CARXLEAN)

	LDI	@MATRIXBI,AR2
	CALL	FIND_XMATRIX
	LDI	AR2,AR0			;SAVE MATRIX PTR


	;GET YOUR Z LEAN (CORNERING)
	;
	LDF	*+AR7(PDATA),R4		;OLD ORADY
	LDF	*+AR7(PDATA+1),R5	;Z RADIANS
	
	LDF	*+AR4(ORADY),R0
	STF	R0,*+AR7(PDATA)		;SAVE NEW OLD ORADY
	SUBF	R4,R0			;DELTA ORADY
	LDF	0,R1
	CMPF	3.14,R0


	LDFGT	@NTWOPII,R1
	CMPF	-3.14,R0


	LDFLT	@TWOPII,R1
	ADDI	R1,R0			;HANDLE RADIAN WRAPAROUND
	MPYF	R7,R0			;MULTIPLY BY SPEED FACTOR
	MPYF	0.06,R0			;CONVERT TO RADIANS
	MPYF	0.1,R0			;CONVERT TO RADIANS
	ADDF	R0,R5
	MPYF	0.5,R5
	STF	R5,*+AR7(PDATA+1)	;SAVE NEW Z RADIANS
	NEGF	R5,R2

	LDI	*+AR5(CAR_AIRF),R0
	OR	*+AR5(CAR_AIRB),R0
	LDFNZ	0,R2 			;ZERO OUT WHEN IN AIR FOLKS

	CMPF	0.1,R2			;LIMIT CHECK
	LDFGT	0.1,R2
	CMPF	-0.1,R2
	LDFLT	-0.1,R2
	STF	R2,*+AR5(CARZLEAN)    	;SAVE IT

;	MPYF	3,R2			;PUMP IT UP
	MPYF	2.2,R2			;PUMP IT UP
	CMPF	0.1,R2			;LIMIT CHECK
	LDFGT	0.1,R2
	CMPF	-0.1,R2
	LDFLT	-0.1,R2

	LDI	@MATRIXAI,AR2		;GET Z IN TEMP THING
	CALL	FIND_ZMATRIX
	CALL	CONCAT201    		;CONCAT YOUR MATRICES INTO DYNOBJ
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*DYNAOBJECT DYNAMIC ALLOCATION SUBSYSTEM
*----------------------------------------------------------------------------
*
	.bss	DYNALIST,NUM_DYNAS*DYNASIZE	;(~3420 WORDS)
	.bss	DYNAFREE,1
	.bss	NULL,1
DYNALISTI	.word	DYNALIST
DYNAFREEI	.word	DYNAFREE
NULLI		.word	NULL

*----------------------------------------------------------------------------
DYNAOBJ_INIT:
	PUSH	AR2
	PUSH	R2
	PUSH	R3
	PUSH	RC
	PUSH	RS

	LDI	@DYNALISTI,AR2

	LDI	@DYNAFREEI,R2

	LDI	@NULLI,R3
	LDI	NUM_DYNAS-1,RC
	LDI	DYNASIZE,RS
	CALL	INIT_LINKED_LIST

	POP	RS
	POP	RC
	POP	R3
	POP	R2
	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*GET A DYNAMIC OBJECT
*
*RETURNS
*	(SUCCESSFUL)
*		CARRY SET
*		AR0	POINTER TO DYNA OBJ
*	(UNSUCCESSFUL)
*		CARRY CLEAR
*
*
GETDYNA:
	PUSH	R0
;	LDP	@DYNAFREE
	LDI	@DYNAFREE,R0
	LDI	R0,AR0
	SLOCKON	Z,"UTIL\GETDYNA   out of dynamic objects"
	BZ	GETDYNA_ERR

	LDI	*AR0,R0
	STI	R0,@DYNAFREE

	ADDI	DYNAMATRIX,AR0		;INIT YOUR MATRIX FOLKS
	CALL	INITMAT
	SUBI	DYNAMATRIX,AR0
	CLRI	R0
	STI	R0,*+AR0(DYNAFLAG)

	SETC
GETDYNA_X
	POP	R0
	RETS

GETDYNA_ERR
	CLRC
	B	GETDYNA_X
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*DELETE A DYNA OBJECT
*
*PARAMETERS
*	AR2	POINTER TO DYNA OBJ
*
*
DELDYNA:
	PUSH	R0
;	LDP	@DYNAFREE
	LDI	@DYNAFREE,R0
	STI	R0,*AR2
	STI	AR2,@DYNAFREE
	POP	R0
	RETS
*----------------------------------------------------------------------------



	.bss	CARLIST,NUM_CARS*CARSIZ 	;(~1050 WORDS)
	.bss	CARFREE,1
	.bss	CAR_COUNT,1
CARLISTI	.word	CARLIST
CARFREEI	.word	CARFREE

*----------------------------------------------------------------------------
CARB_INIT:
	LDI	@CARFREEI,AR0
	LDI	@CARLISTI,AR1

	LDI	NUM_CARS-1,RC
	RPTB	CARINTL

	STI	AR1,*AR0
	LDI	AR1,AR0
CARINTL ADDI	CARSIZ,AR1

	LDI	0,R0
	STI	R0,*AR0
	STPI	R0,@CAR_COUNT

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*GET A CAR OBJECT
*
*RETURNS
*	(SUCCESSFUL)
*		AR0	POINTER TO CAR OBJ
*		CARRY SET
*	(UNSUCCESSFUL)
*		CARRY CLEAR
*
*
GETCAR:
	PUSH	R0
;	LDP	@CARFREE
	LDI	@CARFREE,AR0
	CMPI	0,AR0
	SLOCKON	Z,"UTIL\GETCAR   out of cars"
	BZ	GETCAR_ERR
	LDI	*AR0,R0
	STI	R0,@CARFREE

	INCM	@CAR_COUNT
	SETC
GETCAR_X
	POP	R0
	RETS

GETCAR_ERR
	CLRC
	B	GETCAR_X
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*DELETE A CAR OBJECT
*
*PARAMETERS
*	AR2	POINTER TO CAR OBJ
*
DELCAR:
	PUSH	R0
;	LDP	@CARFREE
	LDI	@CARFREE,R0
	STI	R0,*AR2
	STI	AR2,@CARFREE

;	LDP	@CAR_COUNT
	LDI	@CAR_COUNT,R0
	DEC	R0
	SLOCKON	LT,"UTIL\DELCAR   erroneous CAR_COUNT"

	STI	R0,@CAR_COUNT
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
SCAN_OBJECTS:
	CALL	ISCAN
	SLEEP	1

	CALL	OSCAN
	SLEEP	1
	B	SCAN_OBJECTS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
PUSHALL:
	POP	BK

	PUSH	AR0
	PUSH	AR1
	PUSH	AR2
	PUSH	AR3
	PUSH	AR4
	PUSH	AR5
	PUSH	AR6
	PUSH	AR7

	PUSH	R0
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

	BU	BK
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
POPALL:
	POP	BK

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

	POP	AR7
	POP	AR6
	POP	AR5
	POP	AR4
	POP	AR3
	POP	AR2
	POP	AR1
	POP	AR0

	BU	BK
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*PARAMETERS
*	X = sin(T)
*	Y = cos(T)
*	R2	(FL) THETA
*	R0	(FL) DISTANCE
*RETURNS
*	R0	(FL) X DISTANCE
*	R1	(FL) Z DISTANCE
*
*
DISTANCE_2D:
	PUSHFL	R3

	LDF	R0,R1
	NEGF	R0,R3
	CALL	_COSI
	MPYF	R0,R1

	CALL	_SINE
	MPYF	R3,R0
	POPFL	R3
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*ADD OBJECT VELOCITIES
*
*PARAMETERS
*	AR4	OBJECT
*
OVELADD:
	LDF	*+AR4(OVELX),R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OVELY),R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)

	LDF	*+AR4(OVELZ),R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*ADD N FRAMES X VELOCITY
OVELNADD:
	FLOATP	@NFRAMES,R1
	LDF	*+AR4(OVELX),R0
	MPYF	R1,R0
	ADDF	*+AR4(OPOSX),R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OVELY),R0
	MPYF	R1,R0
	ADDF	*+AR4(OPOSY),R0
	STF	R0,*+AR4(OPOSY)

	LDF	*+AR4(OVELZ),R0
	MPYF	R1,R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*MOVE FORWARD
*PARAMETERS
*	AR2	MATRIX
*	R2	DIST
*	R3	DESTINATION VECTOR
FORWARD:
	PUSH	AR2
	LDF	0,R0

	PUSHF	R0
	PUSHF	R0
	PUSHF	R2

	LDI	AR2,R2
	LDI	SP,AR2
	SUBI	2,AR2

	CALL	MATRIX_MUL
	POPF	R2
	SUBI	2,SP
	POP	AR2
	RETS
*----------------------------------------------------------------------------
	.END
