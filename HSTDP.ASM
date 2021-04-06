	.FILE	"HSTDP.ASM"
*----------------------------------------------------------------------------
*HSTD PROCESSES
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	MPROC.EQU
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


FLASH_ON	.set	1	;TURN THIS OFF TO LOOSE FLASHING 
		.global	DISPLAY_HIGH_SCORES

		.data

PLATE_LETTERSI	.word	PLATE_LETTERS
THREED_LETTERSI	.word	THREED_LETTERS
EIPI		.word	EIP
SCROLLBTABI	.word	SCROLLBTAB
DELISTI 	.word	DELIST
NUMTABI		.word	NUMTAB

		.SECT "THEDATA"

		.include	scroll.pal
		.include	plate.pal

;These are for the license plate and pressing of the plate

PRESS_DIAM	.set	271		;NOTE: The plate is on the bottom surface
PRESS_RADX	.set	1.5708
ROLLER_ZOFF	.set	620
PRESS_STARTZ	.set	-1300
PRESS_LASTZ	.set	-2100		;-1900
PRESS_TRAVELZ	.set	PRESS_LASTZ-PRESS_STARTZ
;PRESS_STARTY	.set	-30
PRESS_STARTY	.set	-45
PRESS_LASTY	.set	-100
PRESS_TRAVELY	.set	PRESS_LASTY-PRESS_STARTY
HIGH_SCORE_GROUP .set	200h


NUMTAB		.word	dzero,done,dtwo,dthree,dfour,dfive,dsix,dseven,deight,dnine

THREED_LETTERS	.word	ma,mb,mc,md,me,mf,mg,mh,mi,mj,mk,ml,mm,mn,mo,mp,mq,mr
		.word	ms,mt,mu,mv,mw,mx,my,mz
THREED_END	.set	$-THREED_LETTERS

RUB		.set	'Z'-'A'+1
PLATE_LETTERS	.word	pa,pb,pc,pd,pe,pf,pg,ph,pi,pj,pk,pl,pm,pn,po,pp,pq,pr
		.word	ps,pt,pu,pv,pw,px,py,pz,arrow,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,pend
LAST_LETTER
LASTCHAR	.set	LAST_LETTER-PLATE_LETTERS-1
EIP	.string	"ENTER INITIALS",0
		.text
*----------------------------------------------------------------------------
LETTER0	.set	PDATA+3
LETTER1	.set	PDATA+4
LETTER2	.set	PDATA+5
darkp_pal	.set	PDATA+6
medp_pal	.set	PDATA+7
lightp_pal	.set	PDATA+8
lightp1_pal	.set	PDATA+9

INIT0	.set	PDATA		;ptr to obj 0 (1st char)
INIT1	.set	PDATA+1		;	    1
INIT2	.set	PDATA+2		;	    2
STRFREE	.set	PDATA+3		;steering wheel amount of free spin
STRSTRT	.set	PDATA+4		;steering wheel minimum
PEDTRIG	.set	PDATA+5		;middle of pedal (pedal trigger)
OLDPOT0	.set	PDATA+6
FLASH_PROC .set PDATA+6		;Not used at the same time as OLDPOT0
INITI0	.set	PDATA+7		;initial index
INITI1	.set	PDATA+8		;initial index
INITI2	.set	PDATA+9		;initial index

PLATEOBJ	.set	PDATA+10
PRESSOBJ	.set	PDATA+11
BPRESSOBJ	.set	PDATA+12
SCROLLBOBJ	.set	PDATA+13
FRAMEOBJ	.set	PDATA+14	;No longer used
MISPLATEOBJ	.set	PDATA+15
HSPOINTER	.set	PDATA+16
PLACE		.set	PDATA+17
WHITE_PAL	.set	PDATA+18
ARMSOBJ		.set	PDATA+19
TEMP_STR	.set	PDATA+20	;10 long
CAMX		.set	PDATA+30
CAMY		.set	PDATA+31
CAMZ		.set	PDATA+32
RACE_NUMBER	.set	PDATA+33
GREY_PAL	.set	PDATA+34


*----------------------------------------------------------------------------
ENTER_INITIALS:
	CALL	INTO_TABLE_P
	BC	GOODENOUGH
	RETP		;NOPE, didn't make it
GOODENOUGH
	STI	R0,*+AR7(PLACE)
;Wait for LOADING TO END
	LDI	1,R0
	STI	R0,@NOSWAP

	LDI	0,R4
MSLP2
	LDI	@DECOMP_ACTIVE,R0
	BNZ	MSLP3
	ADDI	1,R4
	CMPI	3,R4
	BGT	MSLPX				;Done Loading
MSLP3
	SLEEP	1
	BU	MSLP2
MSLPX


	LDI	0,R0
	STI	R0,@NOAERASE

	CALL	SILENT
	SOND1	ENTER_INITS_THEME	;Play the Initials entry theme

	CALL	OBJ_INIT		;Zero out object data list pointers
	CALL	TEXT_INIT

	FLOAT	-512,R0
	STF	R0,@INFIN_CORRECT

	LDI	@_MODE,R0
	ANDN	MMODE|MWATER|MBRIDGE|MINTUNNEL,R0
	OR	MINIT|MINFIN|MHS,R0
	STI	R0,@_MODE

	LDI	UTIL_C|TEXTP_T,R0
	LDI	-1,R1
	CALL	PRC_KILLALL

	CLRI	R0			;Black background
	STI	R0,@BGNDCOLA

	LDP	@_CAMERAPOS+X		;Initialize the camera
	LDF	-24,R0
	STF	R0,@_CAMERAPOS+X
	FLOAT	PRESS_STARTY,R0
	STF	R0,@_CAMERAPOS+Y
	FLOAT	PRESS_STARTZ,R0
	STF	R0,@_CAMERAPOS+Z

	CLRF	R2
	STF	R2,@_CAMERARAD+Y
	SETDP
	LDI	@CAMERAMATRIXI,AR2
	CALL	FIND_YMATRIX

;	CALL	CLEANUP_PALS
	CALL	LOAD_FIXED_PALETTES

	LDL	press_PALETTES,AR2
	CALL	HARDalloc_section



	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0


	CALL	FIFO_RESET		;This will load the wave ram before continuing on
	LDI	1,R0
	STI	R0,@HARD_SECTION_LOAD

	LDL	_SECpress,AR2
	CALL	LOAD_SECTION_REQ

	LDL	scroll_white,AR2	;This is the palette for the letters
	CALL	PAL_ALLOC_RAW
	STI	R0,*+AR7(WHITE_PAL)

	LDL	press_grp,AR2
	CALL	LOAD_SINGLE_SECTION

	CALL	INIT_PRESS_OBJECTS	;Go and set up pointers to special Objects

	CALL	RESCAN

	LDI	0,R0
	STI	R0,@NOSWAP

	LDI	LASTCHAR+1,R0			;Set the steering wheel selection
	STI	R0,@POSES
	LDI	LASTCHAR/2,R0
	STI	R0,@POSE

	LDI	20,R0			;Set the number of seconds to enter your initials
	STI	R0,@_countdown


	;GET THE OBJECTS
	;
	LDL	scroll_gr2,AR2	;Palette used for the Letters on the bottom of the press
	CALL	PAL_ALLOC_RAW
	STI	R0,*+AR7(GREY_PAL)

	CALL	CHECK_FIRST_TIME
	BC	PRESS_CODE_ENTRY
	LDI	*+AR7(WHITE_PAL),R4
	FLOAT	-LETTER_SIZEX-LETTER_SIZEX/4,R5	;Position of the first letter
	FLOAT	-103+LETTER_YOFF,R6
	FLOAT	-PRESS_DIAM-73,R7

	LDI	' ',R0
	STI	R0,*+AR7(INITI0)
	STI	R0,*+AR7(INITI1)
	STI	R0,*+AR7(INITI2)
	LDL	pa,AR2			;Create the first Letter
	CALL	OBJ_GETE
	STI	AR0,*+AR7(INIT0)
	STI	R4,*+AR0(OPAL)
	STF	R5,*+AR0(OPOSX)
	STF	R6,*+AR0(OPOSY)
	STF	R7,*+AR0(OPOSZ)
	FLOAT	LETTER_SIZEX,R0
	ADDF	R0,R5

	LDI	AR0,AR2
	CALL	OBJ_INSERT


	LDL	po,AR2			;Create the second letter
	CALL	OBJ_GETE
	STI	AR0,*+AR7(INIT1)
	STI	R4,*+AR0(OPAL)
	STF	R5,*+AR0(OPOSX)
	STF	R6,*+AR0(OPOSY)
	STF	R7,*+AR0(OPOSZ)
	FLOAT	LETTER_SIZEX,R0
	ADDF	R0,R5

	LDL	po,AR2			;Create the third letter
	CALL	OBJ_GETE
	STI	AR0,*+AR7(INIT2)
	STI	R4,*+AR0(OPAL)
	STF	R5,*+AR0(OPOSX)
	STF	R6,*+AR0(OPOSY)
	STF	R7,*+AR0(OPOSZ)

	CREATE	ENTERTEXT,SPAWNER_C	;This will slide in the text "ENTER INITIALS"


	CLRI	AR5			;character index
	LDF	@STEERCT,R0
	STF	R0,@WHEELPOS

	CALL	GETCHOICE	;READS the steering wheel, uses POSES = number of choices
	LDI	@POSE,R4	;On return POSE = Choice wheel is pointing at.
	STI	R4,*+AR7(OLDPOT0)

	LDI	0,R0		;CLEAR OUT LEFT OVER START HIT
	STI	R0,@START_HIT

	LDF	@PEDALMN,R0
	LDF	@PEDALMX,R1
	SUBF	R0,R1
	FIX	R1
	RS	1,R1
	FIX	@PEDALMN,R0
	ADDI	R0,R1	
	STI	R1,*+AR7(PEDTRIG)
	LDI	0,AR6			;Set debounce counter to 0
;	BR	PEDALWT

	.bss	PEDHIT,1
	LDI	1,R0
	STI	R0,@PEDHIT		;not touched



*----------------------------------------------------------------------------
*
EIML


	CMPI	0,AR6
	BNE	TOSLP2
	LDI	@SWITCHBUTS,R0
	LDL	SW_RADIO|SW_VIEW0|SW_VIEW1|SW_VIEW2,R1
	AND	R1,R0
	BZ	TOSLP2
	LDI	@_countdown,R0
	DEC	R0
	STI	R0,@_countdown
	LDI	2,AR6
TOSLP2
	CMPI	0,AR6
	BEQ	TOSLP3
	SUBI	1,AR6
TOSLP3

	CALL	GETCHOICE	;READS the steering wheel, uses POSES = number of choices
	LDI	@POSE,R4	;On return POSE = Choice wheel is pointing at.
	CMPI	LASTCHAR,R4
	LDIGT	LASTCHAR,R4
	CMPI	0,R4
	LDILT	0,R4

	LDI	*+AR7(OLDPOT0),R1
	STI	R4,*+AR7(OLDPOT0)
	ADDI	R1,R4
	RS	1,R4

	LDI	R4,R0

	CMPI	LASTCHAR,R0
	LDIGT	LASTCHAR,R0

	ADDI	@PLATE_LETTERSI,R0	;Add in the start of the Letter table
	LDI	R0,AR0
	LDI	*AR0,AR1		;Get the ROM pointer to the image the letter will use

	LDI	AR7,AR0
	ADDI	INIT0,AR0		;GET index to which letter we are on
	ADDI	AR5,AR0
	LDI	*AR0,AR0
	LDI	*+AR7(WHITE_PAL),R0
	STI	R0,*+AR0(OPAL)
	STI	AR1,*+AR0(OROMDATA)	;Set the ROM point of the object for this leter

	LDI	AR7,AR0
	ADDI	INITI0,AR0
	ADDI	AR5,AR0			;AR5 = which letter 0-2

	LDI	R4,R0
	CMPI	LASTCHAR,R0
	LDIGE	' ',R0
	BGE	EMIL1A
	CMPI	RUB+1,R0
	BLT	EMIL1
	ADDI	'0'-RUB-1,R0
	BR	EMIL1A
EMIL1
	ADDI	'A',R0			;TRANSLATE BACK TO ASCII
EMIL1A
	STI	R0,*AR0			;initial index SET THE LETTER


	LDI	@_countdown,R0
	BLE	DOTRIG			;Out of time, then auto trigger the next letter


	LDI	@START_HIT,R0
	BNZ	DOTRIG


*ELP CHANGE
	LDI	@_pot1,R0
	CMPI	*+AR7(PEDTRIG),R0
	BGE	TRIGPOTCHK

	CLRI	R0
	STI	R0,@PEDHIT
	BU	NOTRIG
TRIGPOTCHK

	LDI	@PEDHIT,R1
	CMPI	1,R1
	BEQ	NOTRIG

	LDI	1,R0
	STI	R0,@PEDHIT
*ELP END CHANGE


DOTRIG
	LDI	@_countdown,R0
	BZ	DT1			;If out of time don't decrement
	LDI	20,R0			;Set the number of seconds to enter your initials
	STI	R0,@_countdown
DT1
	CLRI	R0
	STI	R0,@START_HIT

	LDI	AR7,AR0
	ADDI	INIT0,AR0
	ADDI	AR5,AR0

	CMPI	RUB,R4
	BNE	NOTBCKSPC

	LDI	@_countdown,R0
	BGT	DORUB			;Out of time?
	LDI	LASTCHAR,R4		;FORCE END

	LDI	AR7,AR0			;Put a space in the position the RUB was in
	ADDI	INITI0,AR0
	ADDI	AR5,AR0			;AR5 = which letter 0-2
	LDI	' ',R0
	STI	R0,*AR0
	BR	NOTBCKSPC		;THIS WILL BAIL CORRECTLY
DORUB
	CMPI	0,AR5			;if char[0] then dont backspace
	BEQ	PEDALWT
;This does a back space

	LDI	*AR0,AR2
	CALL	OBJ_PULL			;Get rid of the letter on

	DEC	AR5			;AR5 = LETTER on

	BR	PEDALWT


NOTBCKSPC
	LDI	AR7,AR1
	ADDI	INIT0,AR1		;GET index to the last letter we are on
	ADDI	AR5,AR1
	LDI	*AR1,AR1
	LDI	*+AR7(GREY_PAL),R0
	STI	R0,*+AR1(OPAL)
	LDI	*+AR1(OROMDATA),R1	;Set the ROM point of the object for this leter
	CMPI	LASTCHAR,R4
	BEQ	DONE_ENTRY

	INC	AR5
	CMPI	3,AR5
	BGE	DONE_ENTRY

	INC	AR0
	LDI	*AR0,AR2
	STI	R1,*+AR2(OROMDATA)	;Set the ROM point of the object for this leter
	CALL	OBJ_INSERT		;Add the next letters object

	SONDFX	CHOOSE_LETTER

PEDALWT:			;Loop waiting for the pedal to be released
;	LDI	@_countdown,R0
;	BLE	EIML
;
;	SLEEP	1
;
;	;wait for release of pedal
;	LDI	@_pot1,R0
;	LDI	*+AR7(PEDTRIG),R1
;	CMPI	R1,R0
;	BGE	PEDALWT

NOTRIG
	CALL	HSTD_TIMER
	CALL	POS_SCROLLB
	SLEEP	1
	BR	EIML

DONE_ENTRY
	CMPI	LASTCHAR,R4
	BNE	DE1
	LDI	AR1,AR2
	CALL	OBJ_PULL
DE1
	LDI	*+AR7(INITI2),R2	;Create string for initial entry
	LSH	8,R2
	OR	*+AR7(INITI1),R2
	LSH	8,R2
	OR	*+AR7(INITI0),R2
	SETADJ	ADJ_INITIALS

	BR	PRESS_CODE
*----------------------------------------------------------------------------
*This proc slides in the WORDS "ENTER INITIALS"
ENTERTEXT:
	FLOAT	616,R2			;XPOS
	CALL	CREATE_ENTERTEXT
	LDF	-6,R0
	STF	R0,*+AR4(TEXT_VELX)
	STF	R0,*+AR5(TEXT_VELX)

	SLEEP	60

	SONDFX	WELCOME

	CLRF	R0
	STF	R0,*+AR4(TEXT_VELX)
	STF	R0,*+AR5(TEXT_VELX)

ET0
	SLEEP	1
	BR	ET0			;THIS PROC GETS KILLED BY PRESS_CODE
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PARAMETERS	R2 = XPOS
CREATE_ENTERTEXT:
	LDI	@EIPI,AR2		;enter initials	string
	FLOAT	254,R3			;YPOS
	LDI	9999,RC			;JIFFYS TO DISPLAY (INDEFINATLY)
	CALL	TEXT_ADDDS
	CALL	MAKE_CENTER
	RETS

*----------------------------------------------------------------------------
MAKE_CENTER:
	LDI	AR0,AR4
	LDI	AR1,AR5
	ORM	TXT_CENTER,*+AR4(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR5(TEXT_COLOR)
	RETS

*----------------------------------------------------------------------------
HSTD_TIMER:
	LDI	@_countdown,R2
	LDI	@COUNTDOWN_BUFI,AR2
	CALL	_itoa
	FLOAT	256,R2
	FLOAT	343,R3			;YPOS
	LDI	1,RC
	CALL	TEXT_ADDDS
	PUSH	AR4
	PUSH	AR5
	CALL	MAKE_CENTER
	POP	AR5
	POP	AR4
	RETS
*----------------------------------------------------------------------------
INSERT_INITS
	LDI	@SCORE,R0
	LDI	*+AR7(INITI0),R1
	LDI	*+AR7(INITI1),R2
	LDI	*+AR7(INITI2),R3
	LDI	0,R4			;POSITION FINISHED IN
	LDI	*+AR7(PLACE),R5
	LDI	*+AR7(RACE_NUMBER),R6
	CALL	INSERT_TABLE_ENTRY

	LDI	*+AR7(RACE_NUMBER),R1
	RETS

*----------------------------------------------------------------------------
* USES BONUS_WAVE and GAMETRAKI to determine...
*
*RETURNS C = 1 PLAYER WILL MAKE IT INTO THE HS TABLE
*	 C = 0 PLAYER WILL NOT MAKE IT
INTO_TABLE_P:
	CALL	VALIDATE_HSTD_TABLES

	;check check score if good enough to enter
	;the hstd table
	LDI	@BONUS_WAVE,R1
	SUBI	1,R1
	STI	R1,*+AR7(RACE_NUMBER)
	LDI	R1,R0
	MPYI	GT_SIZE,R0
	ADDI	@GAMETRAKI,R0
	LDI	R0,AR0
;	LDI	*+AR0(GT_ETIME),R0
	.globl	ETIME
	LDI	@ETIME,R0
	CMPI	14,R1
	CALLEQ	CALC_TOTAL_ELAPSED	;A call to ENTER_INITIALS WITH BONUS_WAVE =15 WILL
	CMPI	0,R0			;CHECK SF TO DC
	BEQ	ITP1			;Did Not Finish this Race (DNF)
	CALL	CHECK_RACE_TABLE
	CMPI	-1,R0
	BNE	ITP2
ITP1
	CLRC
	RETS
ITP2
	SETC
	RETS
*----------------------------------------------------------------------------
*RETURNS C = 1 PLAYER HAS ALLREADY ENTERED INITS
*	 C = 0 PLAYER HAS NOT ENTERED INITS
*SETS PLAYER LETTERS IF FOUND
* INITI0-INITI2
CHECK_FIRST_TIME:
	READADJ	ADJ_INITIALS
	CMPI	-1,R0
	BNE	NOT_FIRST_TIME
	CLRC
	RETS

NOT_FIRST_TIME
	LDI	' ',R1			;Just incase the initials have been corrupted
	STI	R1,*+AR7(INITI1)
	STI	R1,*+AR7(INITI2)

	LDI	AR7,AR0
	ADDI	INITI0,AR0
NFTLP
	LDI	R0,R1
	AND	0FFh,R1
	BEQ	NFTX
	STI	R1,*AR0++
	LSH	-8,R0
	BNE	NFTLP
NFTX
	SETC
	RETS
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*Below Is code only used for the plate stamping sequence
*
*
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*R0 = total elapsed time
*R0 = 0, did not finish
CALC_TOTAL_ELAPSED:
	PUSH	R1
	PUSH	R2
	PUSH	AR0
	LDI	@GAMETRAKI,AR0
	LDI	13,R1
	LDI	0,R2
CTELP
	LDI	*+AR0(GT_ETIME),R0
	BEQ	CTEX			;Did Not Finish this Race (DNF)
	ADDI	R0,R2
	ADDI	GT_SIZE,AR0
	SUBI	1,R1
	BP	CTELP
	LDI	R2,R0
CTEX
	POP	AR0
	POP	R2
	POP	R1
	RETS
*----------------------------------------------------------------------------
*	This routine is branched to from within a proccess
*	It will stamp the letters on the plate then put the plate onto the wall
*
PRESS_FRAMES	.set	60		;120
PLACE_FRAMES	.set	40
ROLLER_TRAVEL	.set	12.7117	;2*PI = 1 revolution PI = 3.14

ARM_FRAMES	.set	10		;20
ARM_START	.set	0
ARM_BOTTOM	.set	ARM_START+240
ARM_TRAVEL	.set	ARM_BOTTOM-ARM_START

STAMP_FRAMES	.set	4
STAMP_SHAKE	.set	7


ARMS2		.set	8Ah

PRESS_CODE_ENTRY:
;Put the letters on the bottom of the press
	LDI	*+AR7(WHITE_PAL),R4
	FLOAT	-LETTER_SIZEX-LETTER_SIZEX/4,R5	;Position of the first letter
	FLOAT	-103+LETTER_YOFF,R6
	FLOAT	-PRESS_DIAM-73,R7

	LDI	*+AR7(INITI0),AR2			;Create the first Letter
	CALL	ASCII_TO_OBJ
	STI	AR0,*+AR7(INIT0)
	STI	R4,*+AR0(OPAL)
	STF	R5,*+AR0(OPOSX)
	STF	R6,*+AR0(OPOSY)
	STF	R7,*+AR0(OPOSZ)
	FLOAT	LETTER_SIZEX,R0
	ADDF	R0,R5
	LDI	*+AR7(INITI0),AR2
	CMPI	' ',AR2
	BEQ	NOINS0
	LDI	AR0,AR2
	CALL	OBJ_INSERT
NOINS0

	LDI	*+AR7(INITI1),AR2			;Create the first Letter
	CALL	ASCII_TO_OBJ
	STI	AR0,*+AR7(INIT1)
	STI	R4,*+AR0(OPAL)
	STF	R5,*+AR0(OPOSX)
	STF	R6,*+AR0(OPOSY)
	STF	R7,*+AR0(OPOSZ)
	FLOAT	LETTER_SIZEX,R0
	ADDF	R0,R5
	LDI	*+AR7(INITI1),AR2
	CMPI	' ',AR2
	BEQ	NOINS1
	LDI	AR0,AR2
	CALL	OBJ_INSERT
NOINS1
	LDI	*+AR7(INITI2),AR2			;Create the first Letter
	CALL	ASCII_TO_OBJ
	STI	AR0,*+AR7(INIT2)
	STI	R4,*+AR0(OPAL)
	STF	R5,*+AR0(OPOSX)
	STF	R6,*+AR0(OPOSY)
	STF	R7,*+AR0(OPOSZ)
	LDI	*+AR7(INITI2),AR2
	CMPI	' ',AR2
	BEQ	NOINS2
	LDI	AR0,AR2
	CALL	OBJ_INSERT
NOINS2
	SONDFX	WELCOME

*ELP CHANGE
	PUSHP	AR5
	;SLEEP	60
	LDI	30-1,AR5
PAPA35	LDI	@START_HIT,R0
	BNZ	PAPA35X
	SUBI	@NFRAMES,AR5
	CMPI	0,AR5
	LDILT	0,AR5
	SLEEP	1
	DBU	AR5,PAPA35
PAPA35X
	POPP	AR5
*ELP END CHANGE


;FALL INTO PRESS CODE
PRESS_CODE:
	LDI	SPAWNER_C,R0		;KILL ENTERTEXT
	LDI	CLASS_M,R1
	CALL	PRC_KILLALL
	CALL	TEXT_INIT

	CLRI	R0
	STI	R0,@START_HIT

	
	LDI	0,R0
	STI	R0,@FRAMRATE   		;RESET FRAME RATE TO ATTRACT MODE
	SONDFX	DOPEN

	LDI	*+AR7(RACE_NUMBER),R1
	LDI	R1,R0
	MPYI	GT_SIZE,R0
	ADDI	@GAMETRAKI,R0
	LDI	R0,AR0
	LDI	*+AR0(GT_ETIME),R0
	CMPI	14,R1
	CALLZ	CALC_TOTAL_ELAPSED
	STI	R0,@SCORE
	CALL	INSERT_INITS
	STI	R0,@SCORE

	CALL	FIND_PLATES		;Set up the High score display board

	LDI	0,R0
	STI	R0,@_countdown

	CALL	ADJUST_ROLLERS
	CALL	ENTER_HSTEXT

	FLOAT	-1950,R2
	LDI	HIGH_SCORE_GROUP,R1		;High score group
	CALL	OBJ_MOVY_GROUP

	LDI	*+AR7(MISPLATEOBJ),AR2
	CALL	OBJ_PULL			;Loose the plate in the players place

	CALL	INI_PLAYERS_BOLTS		;Move them into position to fly

	LDI	5,R1
	CALL	OBJ_FIND
	FLOAT	-2000,R0
	LDF	*+AR0(OPOSY),R1
	ADDF	R0,R1
	STF	R1,*+AR0(OPOSY)

	LDI	8,R1
	CALL	OBJ_FIND
	FLOAT	-2000,R0
	LDF	*+AR0(OPOSY),R1
	ADDF	R0,R1
	STF	R1,*+AR0(OPOSY)


	LDI	*+AR7(SCROLLBOBJ),AR2	;LOOSE THE WHEEL AND IT's LETTERS
	CALL	OBJ_PULL

PRA0					;LOOSE THE LETTERS ON THE FRAME
	LDI	MARQLET,R1
	CALL	OBJ_FIND
	BC	PRA
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	BR	PRA0
PRA
;Pan the camera back,pull back the frame,rotate the press down,
;and scroll the plate in on the rollers

	FLOAT	PRESS_FRAMES,R1		;Pan camera to correct y
	FLOAT	PRESS_TRAVELY,R0
	CALL	DIV_F			;PRESS_TRAVELZ/PRESS_FRAMES
	LDP	@_CAMERAPOS+Y
	ADDF	@_CAMERAPOS+Y,R0
	STF	R0,@_CAMERAPOS+Y
	SETDP

	FLOAT	PRESS_FRAMES,R1		;Pan camera back
	FLOAT	PRESS_TRAVELZ,R0
	CALL	DIV_F			;PRESS_TRAVELZ/PRESS_FRAMES
	LDP	@_CAMERAPOS+Z
	ADDF	@_CAMERAPOS+Z,R0
	STF	R0,@_CAMERAPOS+Z
	SETDP

	FLOAT	PRESS_FRAMES-1,R1	;Rotate press down
	LDF	PRESS_RADX,R0
	CALL	DIV_F			;PRESS_RADX/PRESS_FRAMES

	LDI	*+AR7(PRESSOBJ),AR0
	LDF	*+AR0(ORADX),R2
	SUBF	R0,R2
	STF	R2,*+AR0(ORADX)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	FLOAT	PRESS_FRAMES,R1		;Pull the frame back
	FLOAT	-2000,R0
	CALL	DIV_F			;-2000/PRESS_FRAMES
;	LDI	*+AR7(FRAMEOBJ),AR0
	LDI	FRAME,R1
	CALL	OBJ_FIND
	BC	PRA2
PRA1
	LDF	*+AR0(OPOSZ),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSZ)
	CALL	OBJ_FIND_NEXT
	BNC	PRA1
PRA2
	CALL	MOVE_PRESSB		;Move the bottom of the press reletive to the press
	CALL	MOVE_BIGLET_PRESS	;Move the letters reletive to the bottom of the press

	LDI	*+AR7(PRESSOBJ),AR0		;Spin the rollers until press is rotated all the way down
	LDF	*+AR0(ORADX),R2
	CMPF	-0.01309,R2
	BLE	PR0A

	FLOAT	PRESS_FRAMES,R1
	LDF	ROLLER_TRAVEL,R0
	CALL	DIV_F			;PRESS_TRAVELZ/PRESS_FRAMES
	CALL	SPIN_ROLLERS		;Spin rollers also moves the plate

	SLEEP	1

*ELP CHANGE
	LDI	@START_HIT,R0
	BZ	PRA
;	BR	PRA
*ELP END CHANGE



PR0A
	LDI	FRAME,R1
	CALL	OBJ_FIND
	BC	PR0A2
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	BR	PR0A
PR0A2

	SONDFX	HYDRO
*ELP CHANGE
	;SLEEP	10
	SLEEP	5
*ELP END CHANGE
PR0

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR1
*ELP END CHANGE


;Move the Press and Arms down to stamp
	FLOAT	ARM_FRAMES,R1
	FLOAT	ARM_TRAVEL,R0
	CALL	DIV_F			;ARM_TRAVEL/ARM_FRAMES

	LDI	*+AR7(PRESSOBJ),AR0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	PUSHF	R0
	CALL	MOVE_PRESSB
	CALL	MOVE_BIGLET_PRESS
	POPF	R0

	LDI	*+AR7(ARMSOBJ),AR0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	FLOAT	ARM_BOTTOM,R0
	CMPF	R0,R2
	BGE	PR1

	SLEEP	1

	BR	PR0

PR1
	SONDFX	STAMP
	SONDFX	STAMP1
;STAMP
	LDI	*+AR7(INITI0),R0
	LDI	*+AR7(INIT0),AR2
	CMPI	' ',R0
	BEQ	PR1A1
	CALL	OBJ_PULL
PR1A1
	LDI	*+AR7(INITI1),R0
	LDI	*+AR7(INIT1),AR2
	CMPI	' ',R0
	BEQ	PR1A2
	CALL	OBJ_PULL
PR1A2
	LDI	*+AR7(INITI2),R0
	LDI	*+AR7(INIT2),AR2
	CMPI	' ',R0
	BEQ	PR1A3
	CALL	OBJ_PULL
PR1A3

	LDI	STAMP_FRAMES,AR5
PR1A

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR1ZZZ
*ELP END CHANGE


	FLOAT	STAMP_SHAKE,R0
	LDP	@_CAMERAPOS+Y
	ADDF	@_CAMERAPOS+Y,R0
	STF	R0,@_CAMERAPOS+Y
	SETDP

	SLEEP	1

	FLOAT	STAMP_SHAKE,R0
	NEGF	R0
	LDP	@_CAMERAPOS+Y
	ADDF	@_CAMERAPOS+Y,R0
	STF	R0,@_CAMERAPOS+Y
	SETDP

	SLEEP	1

	DBU	AR5,PR1A

	FLOAT	PRESS_LASTY,R0
	LDP	@_CAMERAPOS+Y
	STF	R0,@_CAMERAPOS+Y
	SETDP

*ELP CHANGE
	;SLEEP	6
	SLEEP	3
*ELP END CHANGE
PR1ZZZ
	CALL	MAKE_PLAYERS_PLATE
PR2

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR2A
*ELP END CHANGE

;PULL press up
	CALL	MOVE_PRESSB

	FLOAT	ARM_FRAMES,R1
	FLOAT	ARM_TRAVEL,R0
	NEGF	R0
	CALL	DIV_F			;ARM_TRAVEL/ARM_FRAMES

	LDI	*+AR7(PRESSOBJ),AR0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	LDI	*+AR7(ARMSOBJ),AR0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	FLOAT	ARM_START,R0
	CMPF	R0,R2
	BLE	PR2A

	SLEEP	1
	BR	PR2

PR2A
;Rotate the camera up
	SONDFX	DOPEN

CAM_RADX	.set	-0.393
ROT_FRAMES	.set	40

	LDP	@_CAMERAPOS
	LDF	@_CAMERAPOS,R0
	LDF	@_CAMERAPOS+Y,R1
	LDF	@_CAMERAPOS+Z,R2
	SETDP
	STF	R0,*+AR7(CAMX)
	STF	R1,*+AR7(CAMY)
	STF	R2,*+AR7(CAMZ)

	LDI	ROT_FRAMES-1,AR6
PR2AA
*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR2A1
*ELP END CHANGE


	LDI	*+AR7(PRESSOBJ),AR0
	FLOAT	-50,R0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)


	LDI	*+AR7(ARMSOBJ),AR0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	LDI	*+AR7(BPRESSOBJ),AR0
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	LDI	ARMS2,R1
	CALL	OBJ_FIND
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)
	CALL	OBJ_FIND_NEXT
	LDF	*+AR0(OPOSY),R2
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSY)

	FLOAT	ROT_FRAMES,R1		;Pan camera to correct y
	LDF	CAM_RADX,R0
	CALL	DIV_F
	LDP	@_CAMERARAD
	LDF	@_CAMERARAD,R2
	ADDF	R0,R2
	STF	R2,@_CAMERARAD
	SETDP
	LDI	@CAMERAMATRIXI,AR2
	CALL	FIND_XMATRIX

	NEGF	R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_XMATRIX

	LDI	@MATRIXAI,R2
	LDI	AR7,AR2
	ADDI	CAMX,AR2
	LDI	@CAMERAPOSI,R3
	CALL	MATRIX_MUL
	SLEEP	1
	
	DBU	AR6,PR2AA

;Scroll plate left,pan camera left with th plate;ZOOM IN;ZOOM OUT

left_stop	.set	-5000
cam_left_stop	.set	-4700
zoomin_stop	.set	-1300
zoomout_stop	.set	-2100

	SONDFX	GOPEN

	LDF	0.00,R6			;AR5 is speed of rotation
PR2A1

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR2A3
*ELP END CHANGE

	LDF	R6,R0
*ELP CHANGE
	;ADDF	0.02,R6	 		;ACCELERATE
	ADDF	0.04,R6	 		;ACCELERATE
*ELP END CHANGE
;	ADDF	0.01,R6	 		;ACCELERATE
	CALL	SPIN_ROLLERS
	LDI	*+AR7(PLATEOBJ),AR0
	LDF	*+AR0(OPOSX),R0

	SUBF	*+AR7(CAMX),R0
*ELP CHANGE
	;MPYF	0.20,R0
	MPYF	0.40,R0
*ELP END CHANGE
	ADDF	*+AR7(CAMX),R0
	FLOAT	cam_left_stop,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR7(CAMX)

	LDF	R0,R3
	FLOAT	zoomin_stop,R4
	FLOAT	zoomout_stop,R5
	FLOAT	-2500,R2		;Accelerating or decelerating?
	CMPF	R2,R3			;R3 set above to = PLATE OPOSX
	LDFGE	R4,R0			;Accelerating
	LDFLT	R5,R0			;Deccelerating
	SUBF	*+AR7(CAMZ),R0
*ELP CHANGE
	;MPYF	0.1,R0
	MPYF	0.2,R0
*ELP END CHANGE
;	MPYF	0.05,R0
	ADDF	*+AR7(CAMZ),R0
	CMPF	R4,R0			;Range check the zpos
	LDFGT	R4,R0			;to large
	CMPF	R5,R0
	LDFLT	R5,R0			;to small
	STF	R0,*+AR7(CAMZ)

	LDP	@_CAMERARAD
	LDF	@_CAMERARAD,R2
	SETDP
	NEGF	R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_XMATRIX

	LDI	@MATRIXAI,R2
	LDI	AR7,AR2
	ADDI	CAMX,AR2
	LDI	@CAMERAPOSI,R3
	CALL	MATRIX_MUL	

	CALL	ADJUST_ROLLERS


	SLEEP	1

	LDI	*+AR7(PLATEOBJ),AR0
	LDF	*+AR0(OPOSX),R0
	FLOAT	-2500,R1
	CMPF	R1,R0
	BGE	PR2A2
*ELP CHANGE
	ADDF	-0.08,R6	 		;DEACCELERATE (MUST BE TWICE ACCELERATE)
*ELP END CHANGE
	CMPF	0.02,R6
	LDFN	0.02,R6

;	ADDF	-0.02,R6	 		;DEACCELERATE (MUST BE TWICE ACCELERATE)
;	CMPF	0.01,R6
;	LDFN	0.01,R6

PR2A2
	LDI	*+AR7(PLATEOBJ),AR0
	LDF	*+AR0(OPOSX),R0
	FLOAT	left_stop,R1
	CMPF	R1,R0
	BGE	PR2A1

;Flip the plate up on end 90deg

PR2A3

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR3B
*ELP END CHANGE

	LDI	*+AR7(PLATEOBJ),AR2
	LDF	0.15708,R2
	ADDF	*+AR2(ORADX),R2
	CMPF	HALFPI,R2
	LDFGT	HALFPI,R2
	STF	R2,*+AR2(ORADX)
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	LDI	*+AR7(PLATEOBJ),AR2	;Setup the offset for the bottom of the plate
	LDF	0,R0
	STF	R0,*+AR2(OVELX)
	STF	R0,*+AR2(OVELY)
	FLOAT	-156,R0
	STF	R0,*+AR2(OVELZ)

	LDI	*+AR7(PLATEOBJ),R2
	ADDI	OMATRIX,R2
	ADDI	OVELX,AR2
	LDI	AR2,R3
	CALL	MATRIX_MUL

	LDI	*+AR7(PLATEOBJ),AR0
	FLOAT	PLATE_ZOFF,R0
	ADDF	*+AR0(OVELZ),R0
	STF	R0,*+AR0(OPOSZ)

	FLOAT	610,R0
	ADDF	*+AR0(OVELY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	0,R0			;No x movement
	CALL	MOVE_PLAYERS_LETTERS

	SLEEP	1
	LDI	*+AR7(PLATEOBJ),AR0
	LDF	*+AR0(ORADX),R2
	CMPF	HALFPI,R2
	BNE	PR2A3


PLACE_ENDRADX	.set	4.71239

;Put the plate onto the wall
	SONDFX	WIPE4

;	FLOAT	PRESS_LASTY,R0
;	STF	R0,*+AR7(CAMY)
;	FLOAT	PRESS_LASTZ,R0
;	STF	R0,*+AR7(CAMZ)

	LDI	PLACE_FRAMES-1,AR5
PR3
	FLOAT	PLACE_FRAMES,R1
	LDF	PLACE_ENDRADX,R0
	SUBF	HALFPI,R0		;Allready rotated 90deg
	CALL	DIV_F
	LDI	*+AR7(PLATEOBJ),AR2
	ADDF	*+AR2(ORADX),R0
	CMPF	PLACE_ENDRADX,R0
	LDFGT	PLACE_ENDRADX,R0
	STF	R0,*+AR2(ORADX)
	LDF	R0,R2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	LDI	*+AR7(MISPLATEOBJ),AR2
	LDI	*+AR7(PLATEOBJ),AR0

	LDF	*+AR2(OPOSY),R0
	SUBF	*+AR0(OPOSY),R0
	FLOAT	AR5,R1
	CALL	DIV_F	
	LDF	R0,R2
	ADDF	*+AR0(OPOSY),R0
	STF	R0,*+AR0(OPOSY)
	CMPF	*+AR7(CAMY),R0
	BGT	PR3A			;Don't move the camera until the plate is above center
	SUBF	*+AR7(CAMY),R0
	MPYF	0.20,R0
	ADDF	*+AR7(CAMY),R0
	FLOAT	-2150,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,*+AR7(CAMY)
PR3A
	LDF	*+AR2(OPOSZ),R0
	SUBF	*+AR0(OPOSZ),R0
	FLOAT	AR5,R1
	CALL	DIV_F	
	LDF	R0,R2
	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	LDF	*+AR2(OPOSX),R0
	SUBF	*+AR0(OPOSX),R0
	FLOAT	AR5,R1
	CALL	DIV_F	
	LDF	R0,R2
	ADDF	*+AR0(OPOSX),R0
	STF	R0,*+AR0(OPOSX)

	LDI	*+AR7(PLATEOBJ),AR0
	LDF	R2,R0
	NEGF	R0
	CALL	MOVE_PLAYERS_LETTERS

	FLOAT	ROT_FRAMES,R1		;Pan camera to correct y
	LDF	-CAM_RADX,R0
	CALL	DIV_F
	LDP	@_CAMERARAD
	LDF	@_CAMERARAD,R2
	ADDF	R0,R2
	CMPF	-0.01,R2
	LDFGT	0,R2
	STF	R2,@_CAMERARAD
	SETDP
	LDI	@CAMERAMATRIXI,AR2
	CALL	FIND_XMATRIX

	NEGF	R2
	LDI	@MATRIXAI,AR2
	CALL	FIND_XMATRIX

	LDI	@MATRIXAI,R2
	LDI	AR7,AR2
	ADDI	CAMX,AR2
	LDI	@CAMERAPOSI,R3
	CALL	MATRIX_MUL	

	SLEEP	1
	DBU	AR5,PR3

;Now fly the bolts in
	LDI	*+AR7(PLACE),R4	;Calculate the first bolts object number
	MPYI	4,R4
	ADDI	FIRST_BOLT,R4
	LDI	3,AR5
PR3B

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR3BA
*ELP END CHANGE

	LDI	R4,R1
	CALL	OBJ_FIND
	BC	PR3BA
	LDI	AR0,AR4
	CREATE	FLY_BOLT,UTIL_C

*ELP CHANGE
	;SLEEP	15
	SLEEP	6
*ELP END CHANGE

	ADDI	1,R4
	DBU	AR5,PR3B
PR3BA

*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR5A
*ELP END CHANGE

;If not in top 5 skip the pan up
	LDI	*+AR7(PLACE),R0
	CMPI	4,R0
	BGT	PR5A

;Continue to pan the camera to the top of the highscore table
PR4A
*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PR5A
*ELP END CHANGE
	SLEEP	1

	LDP	@_CAMERAPOS+Y
	LDF	@_CAMERAPOS+Y,R0
	ADDF	-20,R0
	FLOAT	-2150,R1
	CMPF	R1,R0
	LDFLT	R1,R0
	STF	R0,@_CAMERAPOS+Y
	SETDP
	CMPF	R1,R0
	BNE	PR4A
PR5A


	LDL	plate_darkp,AR2
	CALL	PAL_ALLOC_RAW
	STI	R0,*+AR7(darkp_pal)

	LDL	plate_medp,AR2
	CALL	PAL_ALLOC_RAW
	STI	R0,*+AR7(medp_pal)

	LDL	plate_lightp,AR2
	CALL	PAL_ALLOC_RAW
	STI	R0,*+AR7(lightp_pal)

	LDL	plate_lightp1,AR2
	CALL	PAL_ALLOC_RAW
	STI	R0,*+AR7(lightp1_pal)


*ELP CHANGE
	LDI	@START_HIT,R0
	BNZ	PRESSCODEX2
*ELP END CHANGE


	LDI	*+AR7(RACE_NUMBER),R4
	CREATEC	FLASH_LETTERS_PROC,UTIL_C
	STI	AR0,*+AR7(FLASH_PROC)

PRESS_CODEX
;	SLEEP	60
*ELP CHANGE
	;SLEEP	90
	SLEEP	30
*ELP END CHANGE
	SOND1	CLOSING
PRESSCODEX2
*ELP CHANGE
	;CREATE	UNFOLDMAP_NOPAL,UTIL_C
	CREATE	UNFOLDMAP,UTIL_C
	;SLEEP	40
	SLEEP	20
*ELP END CHANGE


	LDI	*+AR7(FLASH_PROC),AR2
	CALL	PRC_KILL

	LDL	press_PALETTES,AR2
	CALL	dealloc_section

	LDI	*+AR7(GREY_PAL),AR2
	CALL	PAL_DELETE_RAW
	LDI	*+AR7(WHITE_PAL),AR2
	CALL	PAL_DELETE_RAW
	LDI	*+AR7(darkp_pal),AR2
	CALL	PAL_DELETE_RAW
	LDI	*+AR7(medp_pal),AR2
	CALL	PAL_DELETE_RAW
	LDI	*+AR7(lightp_pal),AR2
	CALL	PAL_DELETE_RAW
	LDI	*+AR7(lightp1_pal),AR2
	CALL	PAL_DELETE_RAW


	LDI	@_MODE,R0
	ANDN	MMODE|MINFIN|MHS,R0
	OR	MBONUS,R0
	STI	R0,@_MODE

	RETP
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FRAME		.set	85h
SCROLLB		.set	86h
PRESS		.set	87h
PRESSB		.set	88h
ARMS		.set	89h
PLATE		.set	8Bh
MARQLET		.set	8Ch

PLATE_ZOFF	.set	ROLLER_ZOFF-140


INIT_PRESS_OBJECTS:
	LDI	9h,R1
	CALL	OBJ_FIND
	LDI	AR0,AR2
	CALL	OBJ_PULL
	LDI	81h,R1
	CALL	OBJ_FIND
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	LDI	82h,R1
	CALL	OBJ_FIND
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	LDI	83h,R1
	CALL	OBJ_FIND
	LDI	AR0,AR2
	CALL	OBJ_DELETE

	LDI	@OACTIVEI,AR0
	LDI	*AR0,AR5

FPO	LDI	AR5,R0
	BZ	FPOX
	LDI	R0,AR0
	LDI	*AR0,AR5

	LDI	*+AR0(OID),R0
	AND	0FFh,R0
	CMPI	PRESS,R0
	BNE	FPO1
	STI	AR0,*+AR7(PRESSOBJ)
	LDF	PRESS_RADX,R2
	STF	R2,*+AR0(ORADX)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	BR	FPLE
FPO1
	LDI	*+AR0(OID),R0
	AND	0FFh,R0
	CMPI	PRESSB,R0
	BNE	FPO1A
	STI	AR0,*+AR7(BPRESSOBJ)

	BR	FPLE
FPO1A

	CMPI	PLATE,R0
	BNE	FPO3
	STI	AR0,*+AR7(PLATEOBJ)
	LDF	*+AR0(OPOSZ),R2
	FLOAT	PLATE_ZOFF,R0
	ADDF	R0,R2
	STF	R2,*+AR0(OPOSZ)
	BR	FPLE
FPO3
	CMPI	ARMS,R0
	BNE	FPO4
	STI	AR0,*+AR7(ARMSOBJ)
	BR	FPLE
FPO4
	CMPI	SCROLLB,R0
	BNE	FPO6
	LDI	*+AR7(WHITE_PAL),R2	;This is the palette for the letters
	STI	R2,*+AR0(OPAL)
	STI	AR0,*+AR7(SCROLLBOBJ)
	BR	FPLE
FPO6
;	CMPI	FRAME,R0
;	BNE	FPO7
;	STI	AR0,*+AR7(FRAMEOBJ)
	BR	FPLE
FPO7
FPLE
	BR	FPO
FPOX
	CALL	MOVE_PRESSB
	CALL	MAKE_NEW_MARQ
	RETS

*----------------------------------------------------------------------------
*This proc prints the name of the location on the marque

MAKE_NEW_MARQ:
;	LDI	5,R1
;	CALL	OBJ_FIND
;	RETSC
;	LDI	AR0,AR4
;	LDI	*+AR4(OROMDATA),AR2
;	CALL	OBJ_GETE
;	RETSC
;	FLOAT	-24,R0
;	STF	R0,*+AR0(OPOSX)
;	FLOAT	-800+83,R0
;	STF	R0,*+AR0(OPOSY)
;	FLOAT	-341,R0
;	STF	R0,*+AR0(OPOSZ)
;	LDI	FRAME,R0	;ID
;	STI	R0,*+AR0(OID)
;	LDI	AR0,AR2
;	CALL	OBJ_INSERT
;
;	LDI	8,R1
;	CALL	OBJ_FIND
;	RETSC
;	LDI	AR0,AR4
;	LDI	*+AR4(OROMDATA),AR2
;	CALL	OBJ_GETE
;	RETSC
;	FLOAT	-24,R0
;	STF	R0,*+AR0(OPOSX)
;	FLOAT	-865+83,R0
;	STF	R0,*+AR0(OPOSY)
;	FLOAT	-341,R0
;	STF	R0,*+AR0(OPOSZ)
;	LDI	FRAME,R0	;ID
;	STI	R0,*+AR0(OID)
;	LDI	AR0,AR2
;	CALL	OBJ_INSERT

	FLOAT	-710+83,R3
	LDI	*+AR7(RACE_NUMBER),AR2
	ADDI	@LEG_NAMESI,AR2
	LDI	*AR2,AR2
	FLOAT	-24,R2
	FLOAT	-341,R4
	LDI	MARQLET,R6	;ID
	CALL	PRINT3D
	RETS

MOVE_PRESSB:
	LDI	*+AR7(PRESSOBJ),AR0
	LDI	*+AR7(BPRESSOBJ),AR2		;The PRESS OWNS the plate
	LDF	*+AR0(ORADX),R2		;Get rotation of the PRESS
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	LDF	*+AR0(ORADX),R2		;Get rotation of the PRESS
	LDI	*+AR7(SCROLLBOBJ),AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	LDI	*+AR7(BPRESSOBJ),AR2		;The PRESS OWNS the plate
	LDI	*+AR7(SCROLLBOBJ),AR3
	FLOAT	PRESS_DIAM,R1
	ADDF	60,R1
	LDF	*+AR0(ORADX),R2		;Get rotation of the PRESS
	STF	R2,*+AR2(ORADX)
	STF	R2,*+AR3(ORADX)
	CALL	_SINE
	NEGF	R0
	MPYF3	R0,R1,R3
	ADDF	*+AR0(OPOSZ),R3		;Translated and offset Z
	STF	R3,*+AR2(OPOSZ)	
	ADDF	1,R3			;Ensure that the letters are behind pressb
	STF	R3,*+AR3(OPOSZ)	

	CALL	_COSI
	MPYF3	R0,R1,R3
	FLOAT	ARM_BOTTOM+PRESS_DIAM,R2
	ADDF	*+AR0(OPOSY),R3
	CMPF	R2,R3
	LDFGT	R2,R3
	STF	R3,*+AR2(OPOSY)		;Translated And OFFSET Y
	STF	R3,*+AR3(OPOSY)		;Translated And OFFSET Y
	RETS

MOVE_BIGLET_PRESS:
	LDI	*+AR7(PRESSOBJ),AR0
	LDI	*+AR7(INIT0),AR2
	LDF	*+AR0(ORADX),R2		;Get rotation of the PRESS
	ABSF	R2
	ADDF	-HALFPI,R2
	STF	R2,*+AR2(ORADX)

	PUSH	AR2
	LDF	*+AR0(ORADX),R2		;Get rotation of the PRESS
	LDI	@MATRIXAI,AR2
	CALL	FIND_XMATRIX

	LDI	@VECTORAI,AR1
	LDF	0,R2
	STF	R2,*AR1
	FLOAT	PRESS_DIAM+60+13,R2
	STF	R2,*+AR1(1)
	FLOAT	-98,R2
	STF	R2,*+AR1(2)

	LDI	@VECTORAI,AR2
	LDI	@MATRIXAI,R2
	LDI	AR2,R3
	CALL	MATRIX_MUL
	POP	AR2

	
	LDI	@VECTORAI,AR1
	FLOAT	ARM_BOTTOM+PRESS_DIAM+13,R2
	LDF	*+AR0(OPOSY),R3
	ADDF	*+AR1(1),R3
	CMPF	R2,R3
	LDFGT	R2,R3
	STF	R3,*+AR2(OPOSY)		;Translated And OFFSET Y

	LDF	*+AR0(OPOSZ),R3
	ADDF	*+AR1(2),R3
	STF	R3,*+AR2(OPOSZ)		;Translated And OFFSET Z

	LDI	*+AR7(INIT0),AR0	;Now use the first letter to set the rest

	LDI	0,R4
MPB
	LDI	INIT0,IR0
	ADDI	R4,IR0
	LDI	*+AR7(IR0),AR2
	LDF	*+AR0(OPOSY),R3		;Translated and offset Y
	STF	R3,*+AR2(OPOSY)
	LDF	*+AR0(OPOSZ),R3		;Translated and offset Z
	STF	R3,*+AR2(OPOSZ)	

	LDF	*+AR0(ORADX),R2		;Get rotation of the PRESS
	STF	R2,*+AR2(ORADX)
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	ADDI	1,R4
	CMPI	3,R4
	BNE	MPB

	RETS

*----------------------------------------------------------------------------
* This positions the bar of letters during the Name Entry
*
*

SCROLLBTAB	;	A    B	  C   D	  E   F	  G   H	  I   J	  K   L	  M   N	  O
		.word	1057,1010,960,911,855,803,753,696,648,598,546,494,426,367,307
		;       P   Q   R   S  T  U   V    W    X    Y    Z	RUB 0    1    2
		.word	252,193,138,82,24,-35,-97,-161,-230,-292,-347,-401,-465,-517,-573
		;	3	4   5   6   7     8    9     END
		.word	-633,-697,-757,-820,-880,-945,-1007,-1063

POS_SCROLLB:
	LDI	*+AR7(SCROLLBOBJ),AR2
	LDI	@POSE,R2		;POSITION of the STEERING WHEEL
	CMPI	LASTCHAR,R2
	LDIGT	LASTCHAR,R2

	LDI	@SCROLLBTABI,AR1
	ADDI	R2,AR1
	FLOAT	*AR1,R2
	ADDF	-24,R2
	SUBF	*+AR2(OPOSX),R2
	MPYF	0.50,R2
	ADDF	*+AR2(OPOSX),R2
	STF	R2,*+AR2(OPOSX)
	LDI	@POSE,R2		;POSITION of the STEERING WHEEL
	CMPI	*+AR2(OVELX),R2
	BEQ	POSBX
	STI	R2,*+AR2(OVELX)
	SONDFX	LETTER_RIGHT
POSBX
	RETS

*----------------------------------------------------------------------------
*ADJUST_ROLLERS	This routine places the rollers in a arc so that there
*		priorities are correct.
*IO = NONE
*
ROLLER_GROUP	.set	400h

ADJUST_ROLLERS:
	LDP	@_CAMERAPOS
	LDF	@_CAMERAPOS,R4
	SETDP
	LDF	0,R3
ADJRL
	FLOAT	246,R2
	MPYF	R3,R2
	ADDF	R4,R2
	CALL	FIND_ROLLER
	FLOAT	ROLLER_ZOFF,R2
	ADDF	R3,R2
	ADDF	-11,R2
	STF	R2,*+AR2(OPOSZ)

	FLOAT	-246,R2
	MPYF	R3,R2
	ADDF	R4,R2
	CALL	FIND_ROLLER
	FLOAT	ROLLER_ZOFF,R2
	ADDF	R3,R2
	ADDF	-11,R2
	STF	R2,*+AR2(OPOSZ)
	ADDF	1,R3
	CMPF	7,R3
	BNE	ADJRL
	RETS

*----------------------------------------------------------------------------
*FIND_ROLLER Finds the roller with XPOS closest to R2
*	PARAMETERS	R2 = XPOS to look for
*	 RETURNS	AR2 points to closest roller

FIND_ROLLER:
	PUSH	R3			;R3 is used by the routine that calls this
	PUSHF	R3
	LDI	ROLLER_GROUP,R1			;Roller Group
	CALL	OBJ_GFIND
	FLOAT	32000,R3		;ANY large number will do
	LDI	AR0,AR2			;Make sure AR2 points to something
FRL
	LDF	*+AR0(OPOSX),R0
	SUBF	R2,R0
	ABSF	R0
	CMPF	R3,R0
	LDFLT	R0,R3
	LDILT	AR0,AR2
	CALL	OBJ_GFIND_NEXT
	BNC	FRL

	POPF	R3
	POP	R3
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
ROLLER_DIAM	.set	111

SPIN_ROLLERS:
	LDI	ROLLER_GROUP,R1		;Roller group
	CALL	OBJ_GFIND
SR0
	LDF	*+AR0(ORADZ),R2
	ADDF	R0,R2
	STF	R2,*+AR0(ORADZ)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_ZMATRIX

	CALL	OBJ_GFIND_NEXT
	BNC	SR0

;NOW move the plate
	LDI	*+AR7(PLATEOBJ),AR0
	FLOAT	ROLLER_DIAM,R1

	MPYF	R1,R0		;R = 111, R0 = RADS rotated
				;Circumfrence = 2*PI*R NOTE R0=2PI/THETA
	LDF	*+AR0(OPOSX),R2
	SUBF	R0,R2
	STF	R2,*+AR0(OPOSX)

	CALL	MOVE_PLAYERS_LETTERS
	RETS

*----------------------------------------------------------------------------
*Moves the LEtters on the plate being stamped
*PARAMETERS	R0 = X distance to move the letters
*

MOVE_PLAYERS_LETTERS:
	PUSH	R6
	PUSHF	R6
	LDI	*+AR7(PLACE),R2
	ADDI	16,R2
	LDI	1,R1
	LSH	R2,R1
	CALL	OBJ_GFIND
	BC	MPLX			;They haven't been made yet

	LDI	*+AR7(PLATEOBJ),AR1
	LDF	*+AR1(ORADX),R2
	ADDF	HALFPI,R2
	FLOAT	LETTER_YOFF,R3
	ADDF	*+AR1(OPOSY),R3
	LDF	*+AR1(OPOSZ),R4
	SUBF	1,R4			;Make sure the letters are in front

MPL1
	LDF	*+AR0(OPOSX),R5
	SUBF	R0,R5
	STF	R5,*+AR0(OPOSX)

	STF	R3,*+AR0(OPOSY)
	STF	R4,*+AR0(OPOSZ)

	LDF	*+AR0(ORADX),R6
	CMPF	-PI,R6
	BEQ	MPL2
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX
MPL2
	CALL	OBJ_GFIND_NEXT
	BNC	MPL1
MPLX
	POPF	R6
	POP	R6
	RETS

*----------------------------------------------------------------------------
MAKE_PLAYERS_PLATE:
	LDI	*+AR7(RACE_NUMBER),R6			;Race number
	LDI	*+AR7(PLACE),R7				;Entry number
	CALL	GET_TABLE_ADDR
	CALL	TABLE_ENTRY_READ
	STI	R1,*+AR7(LETTER0)
	STI	R2,*+AR7(LETTER1)
	STI	R3,*+AR7(LETTER2)

	LDI	*+AR7(PLATEOBJ),AR0

	LDI	*+AR7(PLACE),R1
	CALL	CREATE_LETTERS

	LDF	0,R0
	CALL	MOVE_PLAYERS_LETTERS
	RETS

*----------------------------------------------------------------------------
FIRST_BOLT	.set	30h
INI_PLAYERS_BOLTS:
	LDI	*+AR7(PLACE),R1	;Calculate the first bolts object number
	MPYI	4,R1
	ADDI	FIRST_BOLT,R1
	LDI	3,AR5
IPB1
	CALL	OBJ_FIND
	BC	IPBX
	FLOAT	-2500,R0
	STF	R0,*+AR0(OPOSZ)
	ADDI	1,R1
	DBU	AR5,IPB1
IPBX
	RETS


*----------------------------------------------------------------------------
*PROC 	FLY BOLT
*
FLY_BOLT:
	SONDFX	DD2

	LDI	15,AR5
FBL

	FLOAT	1000,R1
	LDF	*+AR4(OPOSZ),R3
	SUBF	R3,R1
	MPYF	0.24,R1
	ADDF	*+AR4(OPOSZ),R1
	STF	R1,*+AR4(OPOSZ)

	LDF	*+AR4(ORADZ),R2		;Now spin the little fckers
	ADDF	0.0873,R2
	STF	R2,*+AR4(ORADZ)
	LDI	AR4,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_ZMATRIX

	SLEEP	1
	DBU	AR5,FBL

	DIE

*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*Below Is code That is shared by both the High score entry and display
*
*
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
*	OBJ_FIND	Finds the object in the Active list
*	PARAMETERS
*	R1 =	ID of the object
*	RETURNS
*	AR0		Points to the first object in the list with that ID
*	CARRY = SET if not found

OBJ_FIND:
	PUSH	R0
	PUSHF	R0
	PUSH	AR5

	LDI	@OACTIVEI,AR0
	LDI	*AR0,AR5

OFIND	LDI	AR5,R0		;Search for the plate
	BZ	OH_NO
	LDI	R0,AR0
	LDI	*AR0,AR5
	LDI	*+AR0(OID),R0
	AND	0FFh,R0
	CMPI	R1,R0
	BNE	OFIND
	CLRC			;GOT IT
O_FOUND
	POP	AR5
	POPF	R0
	POP	R0
	RETS
OH_NO
	SETC
	BR	O_FOUND		;OBJECT NOT found



*----------------------------------------------------------------------------
*	OBJ_FIND_NEXT	Find the next instance of the object
*	PARAMETERS
*	AR0		The First instance of the object.
*	RETURNS
*	AR0		Points to the next object in the list with that ID
*	CARRY = SET if not found

OBJ_FIND_NEXT:
	PUSH	R0
	PUSHF	R0
	PUSH	AR5

	LDI	*AR0,AR5

OFN	LDI	AR5,R0
	LDI	R0,AR0
	BZ	OFNX		;NONE FOUND. This routine is passive
	LDI	*AR0,AR5
	LDI	*+AR0(OID),R0
	AND	0FFh,R0
	CMPI	R1,R0
	BNE	OFN
OFNX
	CLRC
	CMPI	0,AR0
	BNE	OFNX1
	SETC
OFNX1
	POP	AR5
	POPF	R0
	POP	R0
	RETS

*----------------------------------------------------------------------------
*	OBJ_GFIND	Finds the FIRST object in the GROUP on the Active list
*	PARAMETERS
*	R1 =	BIT in the ID that determines the group
*	RETURNS
*	AR0		Points to the first object in the list with that ID
*	CARRY = SET if not found

OBJ_GFIND:
	PUSH	R0
	PUSHF	R0
	PUSH	AR5

	LDI	@OACTIVEI,AR0
	LDI	*AR0,AR5

OGFIND	LDI	AR5,R0		;Search for the plate
	BZ	OH_GNO
	LDI	R0,AR0
	LDI	*AR0,AR5
	LDI	*+AR0(OID),R0
	TSTB	R1,R0
	BZ	OGFIND
	CLRC
O_GFOUND			;GOT IT
	POP	AR5
	POPF	R0
	POP	R0
	RETS
OH_GNO
	SETC
	LDI	0,AR0
	BR	O_GFOUND		;OBJECT NOT found


*----------------------------------------------------------------------------
*	OBJ_GFIND_NEXT	Find the next instance of the GROUP
*	PARAMETERS
*	AR0		The First instance of the object.
*	R1 =	BIT in the ID that determines the group
*
*	RETURNS
*	AR0		Points to the next object in the list with that ID
*	CARRY = SET if not found

OBJ_GFIND_NEXT:
	PUSH	R0
	PUSHF	R0
	PUSH	AR5

	LDI	*AR0,AR5

OGFN	LDI	AR5,R0
	LDI	R0,AR0
	BZ	OGFNX		;NONE FOUND. This routine is passive
	LDI	*AR0,AR5
	LDI	*+AR0(OID),R0
	TSTB	R1,R0
	BZ	OGFN
OGFNX
	CLRC
	CMPI	0,AR0
	BNE	OGFNX1
	SETC
OGFNX1
	POP	AR5
	POPF	R0
	POP	R0
	RETS

*----------------------------------------------------------------------------
*This code can be deleted after I can change the ID numbers for the PRESS Group
* PARAMETERS AR3 = packed list of object ID's to tag
*	R2  = What to tage them with. NOTE R2 will be orred with the ID
OBJ_TAG:
	
OTAG0
	LDI	*AR3++,R1	;Get ID looking for
	CMPI	0FFh,R1		;Is it a range of ID's?
	BLE	OTAG
	LDI	R1,R0		;YES, Decode the end
	AND	0FFh,R0
	LSH	-8,R1		;Decode the start
OTAG1
	CALL	OBJ_TAGALL	;Remove the range of objects
	ADDI	1,R1
	CMPI	R1,R0
	BGE	OTAG1
	BR	OTAG0
OTAG
	CMPI	0,R1
	BEQ	OTAGX
	CALL	OBJ_TAGALL
	BR	OTAG0
OTAGX
	RETS

*----------------------------------------------------------------------------
*This code can be deleted after I can change the ID numbers for the PRESS Group
*	R1 = Object looking for
*	R2  = What to tage them with. NOTE R2 will be orred with the ID
OBJ_TAGALL:
	CALL	OBJ_FIND
	BC	OTAX
	LDI	*+AR0(OID),R3
	OR	R2,R3
	STI	R3,*+AR0(OID)
OTA1
	CALL	OBJ_FIND_NEXT
	BC	OTAX
	LDI	*+AR0(OID),R3
	OR	R2,R3
	STI	R3,*+AR0(OID)
	BR	OTA1
OTAX
	RETS


*----------------------------------------------------------------------------
*OBJ_MOVY_GROUP
*	PARAMETERS	R1 = Bit of OID to search for
*	PARAMETERS	R2 = FLOAT amount to move YPOS
*
OBJ_MOVY_GROUP:
	PUSH	R3
	PUSHF	R3

	CALL	OBJ_GFIND
	BC	OMYG
	LDF	*+AR0(OPOSY),R3
	ADDF	R2,R3
	STF	R3,*+AR0(OPOSY)
OMYG1
	CALL	OBJ_GFIND_NEXT
	BC	OMYG
	LDF	*+AR0(OPOSY),R3
	ADDF	R2,R3
	STF	R3,*+AR0(OPOSY)
	BR	OMYG1
OMYG
	POPF	R3
	POP	R3
	RETS

*----------------------------------------------------------------------------
*OBJ_DEL_GROUP
*	PARAMETERS	R1 = Bit of OID to search for
*
*
OBJ_DEL_GROUP:
	CALL	OBJ_GFIND
	BC	ODG
	LDI	AR0,AR2
	CALL	OBJ_PULL
ODG1
	CALL	OBJ_GFIND_NEXT
	BC	ODG
	LDI	AR0,AR2
	CALL	OBJ_PULL
	BR	ODG1
ODG
	RETS

*----------------------------------------------------------------------------
FIND_ALL_PLATES:
	LDI	15,R0			;HE WILL NEVER GET TO THIS PLACE
	STI	R0,*+AR7(PLACE)
	CALL	FIND_PLATES
	RETS
*----------------------------------------------------------------------------
*FIND_PLATES Creates the objects for the name and the score
*
*
*


NUM_PLATES	.set	9
FIRST_PLATE	.set	20h

FIND_PLATES:
	PUSH	AR5
	LDI	*+AR7(RACE_NUMBER),R6		;Race number
	LDI	0,R7				;Entry number
	CALL	GET_TABLE_ADDR
	STI	AR2,*+AR7(HSPOINTER)

	LDI	0,AR5
MP0

	CMPI	*+AR7(PLACE),AR5
	BEQ	MP1		;Skip creating the letters and score for the player


	LDI	*+AR7(HSPOINTER),AR2
	CALL	TABLE_ENTRY_READ
	STI	AR2,*+AR7(HSPOINTER)
	STI	R1,*+AR7(LETTER0)
	STI	R2,*+AR7(LETTER1)
	STI	R3,*+AR7(LETTER2)

	CALL	MAKE_TIME

	LDI	AR5,R1
	ADDI	FIRST_PLATE,R1
	CALL	OBJ_FIND	;Get the pointer to the plate

	LDI	AR5,R1
	CALL	CREATE_LETTERS

MP2
	ADDI	1,AR5
	CMPI	NUM_PLATES,AR5
	BLE	MP0

	POP	AR5
	RETS

MP1				;Skip this plate
	LDI	*+AR7(HSPOINTER),AR2
	CALL	TABLE_ENTRY_READ
	STI	AR2,*+AR7(HSPOINTER)

	LDI	AR5,R1
	ADDI	FIRST_PLATE,R1
	CALL	OBJ_FIND	;Get the pointer to the plate
	STI	AR0,*+AR7(MISPLATEOBJ)	;Save its pointer for latter use

	LDI	@SCORE,R0
	CALL	MAKE_TIME

	BR	MP2


*----------------------------------------------------------------------------
*MAKE_NUMBERS
*	R0	= INTEGER SCORE
*	AR5	= PLACE
*
*
FIRST_NUMBER	.set	10h

MAKE_NUMBERS:
	LDI	R0,R2
	LDI	AR7,AR2
	ADDI	TEMP_STR,AR2
	CALL	_itoa
	CALL	FORMAT_NUM
	LDI	AR7,AR4
	ADDI	TEMP_STR,AR4


	LDI	FIRST_NUMBER,R1
	ADDI	AR5,R1			;AR5 = the place
	CALL	OBJ_FIND

	LDI	*AR4++,IR0
	LDI	@NUMTABI,AR1
	LDI	*+AR1(IR0),R0
	STI	R0,*+AR0(OROMDATA)	;Replace it with the proper number
	LDI	HIGH_SCORE_GROUP,R0		;Make this part of the High Score group
	STI	R0,*+AR0(OID)

	LDI	5,AR6		;Now make 6 more
MNLOOP
	LDI	AR0,AR1
	LDI	*AR4++,IR0
	LDI	@NUMTABI,AR0
	LDI	*+AR0(IR0),AR2
	CALL	OBJ_GETE

	LDI	HIGH_SCORE_GROUP,R0		;Make this part of the High Score group
	STI	R0,*+AR0(OID)

	LDF	*+AR1(OPOSX),R0
	FLOAT	-145,R1			;WIDTH OF ONE NUMBER
	ADDF	R1,R0
	STF	R0,*+AR0(OPOSX)

	LDF	*+AR1(OPOSY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	*+AR1(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	LDF	0,R2
	STF	R2,*+AR0(ORADX)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	LDI	AR0,AR2
	CALL	OBJ_INSERT

	DBU	AR6,MNLOOP
	RETS


*----------------------------------------------------------------------------
*MAKE_TIME
*	R0	= INTEGER TIME
*	AR5	= PLACE
*
*
	.data
LONGEST_TIME	.word	198000
	.text
MAKE_TIME:
	CMPI	0,R0			;Range check time for bogus values
	LDILT	0,R0
	LDI	@LONGEST_TIME,R1
	CMPI	R1,R0
	LDIGT	R1,R0

	CALL	CVTTIME
	MPYI	100,R1
	ADDI	R1,R0
	MPYI	10000,R2
	ADDI	R0,R2
;	CALL	CONVERT_TIME
	LDI	AR7,AR2
	ADDI	TEMP_STR,AR2
	CALL	_itoa
	CALL	FORMAT_NUM
	LDI	AR7,AR4
	ADDI	TEMP_STR,AR4

	LDI	FIRST_NUMBER,R1
	ADDI	AR5,R1			;AR5 = the place
	CALL	OBJ_FIND

	LDI	*AR4++,IR0
	LDI	@NUMTABI,AR1
	LDI	*+AR1(IR0),R0
	STI	R0,*+AR0(OROMDATA)	;Replace it with the proper number
	LDI	HIGH_SCORE_GROUP,R0		;Make this part of the High Score group
	STI	R0,*+AR0(OID)

	LDI	6,AR6		;Now make 6 more
MTLOOP
	LDI	AR0,AR1
	FLOAT	-145,R1			;WIDTH OF ONE NUMBER

	CMPI	5,AR6
	BEQ	MT1
	CMPI	2,AR6
	BNE	MT2
MT1
	LDL	dcol,AR2
	CALL	OBJ_GETE
	FLOAT	-82,R1			;WIDTH OF ONE COLON
	BR	MT3
MT2
	LDI	*AR4++,IR0
	LDI	@NUMTABI,AR0
	LDI	*+AR0(IR0),AR2
	CALL	OBJ_GETE
MT3
	LDI	HIGH_SCORE_GROUP,R0		;Make this part of the High Score group
	STI	R0,*+AR0(OID)

	LDF	*+AR1(OPOSX),R0
	ADDF	R1,R0
	STF	R0,*+AR0(OPOSX)

	LDF	*+AR1(OPOSY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	*+AR1(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	LDF	0,R2
	STF	R2,*+AR0(ORADX)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX

	LDI	AR0,AR2
	CALL	OBJ_INSERT

	DBU	AR6,MTLOOP
	RETS

*----------------------------------------------------------------------------
*READS ASCI NUMBER and reformats it to 7 digit display
*	AR2 = string
FORMAT_NUM:
	LDI	0,R1
	LDI	0,R2
	LDI	AR2,AR1
FORMN_LOOP
	CMPI	0,R2
	BNE	FORMNA
	LDI	*AR2++,R0
FORMNA	LDI	R0,R3
	LSH	R2,R3
	SUBI	8,R2
	CMPI	-24,R2
	LDILT	0,R2

	AND	0FFh,R3
	CMPI	MINUS_CHAR,R3
	BEQ	FORMN			;Disregard minus sign
	CMPI	0,R3
	BEQ	FN_PAD			;Reached end
	SUBI	'0',R3
	PUSH	R3
	ADDI	1,R1
FORMN
	CMPI	6,R1
	BLE	FORMN_LOOP
FN_PAD
	SUBI	1,R1
	LDI	R1,RC

	RPTB	FORMN1
	POP	R0
FORMN1	STI	R0,*AR1++

	CMPI	6,R1
	BEQ	FORMNX
	LDI	0,R0
	NEGI	R1
	ADDI	6,R1
	BN	FORMNX
	LDI	R1,RC
	RPTB	FORMN2
FORMN2	STI	R0,*AR1++
FORMNX
	RETS

*----------------------------------------------------------------------------
*	PARAMETERS	AR0 = POINTER TO PLATE that owns this
*		LETTER0-LETTER2 = THE three letters
*		R1  = Place the player is in
LETTER_SIZEX	.set	120
LETTER_XOFF	.set	-120
LETTER_YOFF	.set	-12

CREATE_LETTERS:
	LDI	AR7,AR3
	ADDI	LETTER0,AR3

	ADDI	16,R1
	LDI	1,R2
	LSH	R1,R2
	OR	HIGH_SCORE_GROUP,R2		;Make this part of the High Score group

	LDI	AR0,AR1
	LDF	0,R4
CRLLOOP
	LDI	*AR3++,AR2
	AND	07Fh,AR2		;EXTRACT the CHAR
	CMPI	0,AR2
	BEQ	CRLX			;String Zero terminated

	CALL	ASCII_TO_OBJ
	BC	CRLX				;OUT OF OBJECTS... BAIL

	FLOAT	LETTER_SIZEX,R0
	MPYF	R4,R0
	FLOAT	LETTER_XOFF,R1
	ADDF	R1,R0
	ADDF	*+AR1(OPOSX),R0
	STF	R0,*+AR0(OPOSX)	
	FLOAT	LETTER_YOFF,R0
	ADDF	*+AR1(OPOSY),R0
	STF	R0,*+AR0(OPOSY)
	LDF	*+AR1(OPOSZ),R0
	SUBF	1,R0			;Make sure that it is on top of the plate
	STF	R0,*+AR0(OPOSZ)
	LDI	*+AR7(WHITE_PAL),R0
	STI	R0,*+AR0(OPAL)
	STI	R2,*+AR0(OID)

	PUSH	R2
	LDF	0,R2
	LDI	*-AR3(1),AR2
	CMPI	20h,AR2		;is it a space?
	LDFEQ	-PI,R2
	STF	R2,*+AR0(ORADX)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_XMATRIX
	POP	R2

	LDI	AR0,AR2
	CALL	OBJ_INSERT

	ADDF	1,R4
	CMPF	2,R4
	BLE	CRLLOOP
CRLX
	RETS

ASCII_TO_OBJ:
	CMPI	'0',AR2
	LDILT	'0',AR2
	CMPI	'9',AR2
	BGT	CRLL
	ADDI	'Z'+2-'0',AR2
	BR	CRL1
CRLL
	CMPI	'Z',AR2
	LDIGT	'Z',AR2
CRL1
	SUBI	'A',AR2
	CMPI	0,AR2
	LDILT	0,AR2
	CMPI	LASTCHAR,AR2
	LDIGT	LASTCHAR,AR2
	ADDI	@PLATE_LETTERSI,AR2
	LDI	*AR2,AR2

	CALL	OBJ_GETE
	RETS

*----------------------------------------------------------------------------
*	PARAMETERS	AR2 = POINTER TO STRING
*		R2  = Xpos FL
*		R3  = Ypos FL
*		R4  = Zpos FL
*		R6  = ID
LETTER3D_SIZEX	.set	80

PRINT3D:
	LDI	AR2,AR1			;I use AR2 as input for continuity with the 2d print
	LDI	0,R1
	PUSH	R1			;This will terminate the string being pulled off the stack
	FLOAT	LETTER3D_SIZEX/2,R5
PR3DFS
	LDI	*AR1,R0			;Count the number of letters in this group
	LSH	R1,R0
	ADDI	-8,R1
	CMPI	-24,R1
	BGE	PR3DA
	LDI	0,R1
	NOP	*AR1++
PR3DA
	AND	7Fh,R0
	PUSH	R0
	ADDI	1,IR0
	ADDF	R5,R2			;Center the text's Xpos	
	CMPI	0,R0
	BNE	PR3DFS
	SUBF	R5,R2			;Correction for zero terminator
	SUBF	R5,R2			;Correction for first letter


	POP	AR0			;POP the zero terminator
PR3DLOOP
	POP	AR0
	CMPI	0,AR0			;Not stripped by loop above
	BEQ	PR3DX			;String Zero terminated

	CMPI	20h,AR0			;if its a space, skip it
	BEQ	PR3DNEXT
	CMPI	'0',AR0
	LDIZ	'O',AR0

	CMPI	'1',AR0
	LDIZ	'I',AR0

	SUBI	'A',AR0
	CMPI	0,AR0
	LDILT	0,AR0
	CMPI	THREED_END,AR0
	LDIGT	THREED_END,AR0
	ADDI	@THREED_LETTERSI,AR0
	LDI	*AR0,AR2

	CALL	OBJ_GETE
	.if DEBUG
	BC	$
	.endif

	STF	R2,*+AR0(OPOSX)	
	STF	R3,*+AR0(OPOSY)
	STF	R4,*+AR0(OPOSZ)
	STI	R6,*+AR0(OID)
	PUSHF	R2
	LDF	0,R2
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_YMATRIX
	POPF	R2

	LDI	AR0,AR2
	CALL	OBJ_INSERT
PR3DNEXT
	FLOAT	LETTER3D_SIZEX,R0
	SUBF	R0,R2
	BR	PR3DLOOP
PR3DX
	RETS

*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*Below Is code only used to display the high score and is not used during high
*score entry
*
*
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------
*----------------------------------------------------------------------------

HS_ZOOM		.set	40
HS_STARTY	.set	650
;HS_ENDY 	.set	-280
HS_ENDY 	.set	-210
HS_YDIFF	.set	(HS_ENDY-HS_STARTY)/HS_ZOOM

HS_STARTZ	.set	-4200
HS_ENDZ 	.set	-1960	;-800
HS_ZDIFF	.set	(HS_ENDZ-HS_STARTZ)/HS_ZOOM

DISPLAY_HIGH_SCORES:
	LDL	scroll_white,AR2
	CALL	PAL_ALLOC_RAW

	LDL	plate_darkp,AR2
	CALL	PAL_ALLOC_RAW

	LDL	plate_medp,AR2
	CALL	PAL_ALLOC_RAW

	LDL	plate_lightp,AR2
	CALL	PAL_ALLOC_RAW

	LDL	plate_lightp1,AR2
	CALL	PAL_ALLOC_RAW

	LDL	press_PALETTES,AR2	;Load in the palettes
	CALL	alloc_section

	LDI	0,R0			;IGNORE PRVIOUS BUTTON PRESSES
	STI	R0,@RADIO_HS_SWITCH
	STI	R0,@RADIO_HS_SHADOW

	LDI	@ATTRWAVE,AR5
DHSLOOP
	CLRI	AR0
;	LDP	@SWITCH3
;	NOT	@SWITCH3,R0   		;READ HARDWARE 0=CLOSED, 1=OPEN
;	LDI	*AR0,R2			;Loff
;	SETDP
;	AND	SW_RADIO_H,R0
;	BNZ	DHSLOOP		;Wait for radio button to come up

	LDI	AR5,AR6
	CREATE	DISPLAY_HS,UTIL_C|DISPLAYHS_T
	LDI	AR0,AR4			;Save PROC incase we need to kill it latter	
	LDI	30*7,AR6		;Sleep 7 seconds
DHSWAIT
	SLEEP	1
;	CLRI	AR0
;	LDP	@SWITCH3
;	NOT	@SWITCH3,R0   		;READ HARDWARE 0=CLOSED, 1=OPEN
;	LDI	*AR0,R2			;Loff
;	SETDP
;	AND	SW_RADIO_H,R0
;	BNZ	DHSNEXT	;if radio button pressed skip to next HS
	LDI	@RADIO_HS_SWITCH,R0
	CMPI	@RADIO_HS_SHADOW,R0	;Edge trigger
	BZ	DHSNOBUT
	STI	R0,@RADIO_HS_SHADOW
	CMPI	-1,R0			;First trigger
	LDIEQ	-1,AR5			;First trigger set level = -1 (DHSNEXT WILL INC)

	BR	DHSNEXT
DHSNOBUT
	DBU	AR6,DHSWAIT

	CALL	OBJ_INIT	;initialize object system (ERASE OLD OBJECTS)

	ADDI	1,AR5
	CMPI	15,AR5
	BGE	DHSLOOPX
	TSTB	1,AR5
	BNE	DHSLOOP
DHSLOOPX
	BR	CYCLE_ATTR
DHSNEXT
	ADDI	1,AR5
	CMPI	15,AR5
	BGE	DHSLOOPX

	LDI	UTIL_C|DISPLAYHS_T,R0	;KILL THE OLD PROCS OFF
	LDI	CLASS_M|TYPE_M,R1
	CALL	PRC_KILLALL
	CALL	OBJ_INIT	;initialize object system (ERASE OLD OBJECTS)
	BR	DHSLOOP

DISPLAY_HS:
	STI	AR6,*+AR7(RACE_NUMBER)		;Passed by parent proc


	LDL	scroll_white,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR7(WHITE_PAL)

	LDI	0,R0
	STI	R0,@NOAERASE

	LDP	@_CAMERAPOS+X		;Set the initial camera position
	FLOAT	-4700,R0
	STF	R0,@_CAMERAPOS+X
	FLOAT	HS_STARTY,R0
	STF	R0,@_CAMERAPOS+Y
	FLOAT	HS_STARTZ,R0
	STF	R0,@_CAMERAPOS+Z

	CLRF	R2
	STF	R2,@_CAMERARAD+Y
	SETDP

	LDI	@CAMERAMATRIXI,AR2
	CALL	FIND_YMATRIX

	LDL	press_grp,AR2		;Load the objects
	CALL	LOAD_SINGLE_SECTION

	CALL	DELETE_PRESS_OBJECTS	;Loose the extra stuff used for the name entry
	CALL	FIND_ALL_PLATES

	CALL	FIX_PLATES		;Init the plates zpos for the fly in

	FLOAT	120,R2			;Adjust the plates y position for the new Marqee
	LDI	HIGH_SCORE_GROUP,R1		;High score group
	CALL	OBJ_MOVY_GROUP

	LDI	9h,R1
	CALL	OBJ_FIND
	LDI	AR0,AR2
	CALL	OBJ_PULL

	CALL	DISPLAY_HSTEXT

	CALL	RESCAN			;Make sure all these changes are shown the next display

	LDI	*+AR7(RACE_NUMBER),R4
	CREATEC	FLASH_LETTERS_PROC,UTIL_C|DISPLAYHS_T|FLASH_ST
	STI	AR0,*+AR7(FLASH_PROC)
DHS0
	SLEEP	1
	FLOAT	250,R0
	CALL	FLY_PLATES		;Fly the plates onto the back wall
	FLOAT	998,R1
	CMPF	R1,R3
	BLT	DHS0

	SLEEP	30*2

	LDI	HS_ZOOM-1,AR6
DHS1
	SLEEP	1
	FLOAT	HS_ZDIFF,R1		;Zoom the camera up close
	LDP	@_CAMERAPOS

	FLOAT	HS_YDIFF,R1		;Pan the y so that the marqee is at the top
	LDF	@_CAMERAPOS+Y,R0
	ADDF	R1,R0
	STF	R0,@_CAMERAPOS+Y

	FLOAT	HS_ZDIFF,R1
	LDF	@_CAMERAPOS+Z,R0
	ADDF	R1,R0
	STF	R0,@_CAMERAPOS+Z

	SETDP
	DBU	AR6,DHS1

	SLEEP	30*2			;Pause to see last few names
	LDI	*+AR7(FLASH_PROC),AR2
	CALL	PRC_KILL
	DIE

*----------------------------------------------------------------------------
*PROC
*R4 = race number
FLASH_PALSI	.word	FLASH_PALS
scroll_whiteI	.word	scroll_white
	.SECT	"THEDATA"
FLASH_PALS
	.word	plate_medp,plate_lightp,plate_lightp1,plate_lightp,-1
	.text


FLASH_LETTERS_PROC:
	.if	FLASH_ON = 1
	LDI	R4,R1
	CALL	CHECK_LASTHS
	CMPI	-1,R0
	BEQ	FLASH_LOCK
	ADDI	16,R0
	LDI	1,R4
	LSH	R0,R4
	OR	HIGH_SCORE_GROUP,R4		;Make this part of the High Score group
	LDI	@FLASH_PALSI,AR6
FLASH_LOOP
	LDI	*AR6,R0
	LDIN	@FLASH_PALSI,AR6
	LDIN	*AR6++,R0			;THIS will increment allways
	PUSH	R0
	LDI	200,AR2
	CALL	RANDPER
	POP	R0
	LDIC	@scroll_whiteI,R0
	CALL	FLASH_LETTERS
	SLEEP	6
	BR	FLASH_LOOP
	.endif
FLASH_LOCK
	SLEEP	1
	BR	FLASH_LOCK

*----------------------------------------------------------------------------
*R0 OPAL
*R4 OID
FLASH_LETTERS:
	LDI	R0,AR2
	CALL	PAL_FIND_RAW
	LDI	R4,AR2
	CALL	OBJ_FIND_FIRST
	BNC	FLASHX
FLASH_LP
	STI	R0,*+AR0(OPAL)
	LDI	AR2,R1
	CALL	FIND_NEXT_OBJ
	BNC	FLASH_LP
FLASHX
	RETS
*----------------------------------------------------------------------------
*REMOVES the objects in the list of ID's
*NOTE if the value of the ID is > FF it will eliminate the range (inclusive)
*

DELIST		.word	808Bh,0104h,3057h,0


DELETE_PRESS_OBJECTS:
	LDI	@DELISTI,AR3	;TAG them with 100h
	LDI	100h,R2
	CALL	OBJ_TAG

	LDI	100h,R1		;Now Bag them
	CALL	OBJ_DEL_GROUP
	RETS

*----------------------------------------------------------------------------
*	FIX_PLATES
*
FIX_PLATES:
	PUSH	AR5
	FLOAT	-5000,R0		;Initial Z offset
	LDI	0,AR5
	LDI	1h,R2
	LSH	16,R2
FIXPL
	LDI	AR5,R1
	ADDI	FIRST_PLATE,R1
	CALL	OBJ_FIND

	LDF	*+AR0(OPOSZ),R3		;Offset the plates Z
	ADDF	R0,R3
	STF	R3,*+AR0(OPOSZ)
	SUBF	1,R3
FIXPL1
	LDI	R2,R1
	LSH	1,R2
	CALL	OBJ_GFIND
	BC	FIXPL3			;No letters on this plate, move on. (useually hosed CMOS)
FIXPL2
	STF	R3,*+AR0(OPOSZ)		;Now do the letters on it
	CALL	OBJ_GFIND_NEXT
	BNC	FIXPL2			;do as many as there are
FIXPL3
	FLOAT	-500,R1			;PLate to plate offset
	ADDF	R1,R0

	ADDI	1,AR5
	CMPI	9,AR5
	BLE	FIXPL
	POP	AR5
	RETS

*----------------------------------------------------------------------------
*	FLY PLATES
*	R0 = how far to move
*	R3 = position of the last plate
FLY_PLATES:
	PUSH	AR5
	LDI	0,AR5
	LDI	1h,R2
	LSH	16,R2
FLPL
	LDI	AR5,R1
	ADDI	FIRST_PLATE,R1
	CALL	OBJ_FIND

	LDF	*+AR0(OPOSZ),R1
	ADDF	R0,R1
	FLOAT	1000,R3
	CMPF	R3,R1		;BLEW by destination?
	LDFGT	R3,R1
	STF	R1,*+AR0(OPOSZ)
	LDF	R1,R3
	SUBF	1,R3
FLPL1
	LDI	R2,R1
	LSH	1,R2
	CALL	OBJ_GFIND
	BC	FLPL3			;No letters ,hosed CMOS?
FLPL2
	STF	R3,*+AR0(OPOSZ)		;Now do the letters on it
	CALL	OBJ_GFIND_NEXT
	BNC	FLPL2			;do as many as there are
FLPL3
	ADDI	1,AR5
	CMPI	9,AR5
	BLE	FLPL

	POP	AR5
	RETS

*----------------------------------------------------------------------------
*This proc prints the name of the location on the marque

DISPLAY_HSTEXT:
	FLOAT	-910,R3
	BR	RACE_TEXT
ENTER_HSTEXT:
	FLOAT	-910-2000,R3			;The marquee is moved up 2000
RACE_TEXT:
	LDI	*+AR7(RACE_NUMBER),AR2
	ADDI	@LEG_NAMESI,AR2
	LDI	*AR2,AR2
	FLOAT	-4700,R2
	FLOAT	-301,R4
	LDI	0,R6	;ID
	CALL	PRINT3D
	RETS

LOGO_X		.set	-250
LOGO_Y		.set	-170
LOGO_Z		.set	368*2

INIT_LOGO:
	CALL	OBJ_GET
	BC	LOGOX
	LDI	AR0,AR4
	LDIL	logo,R0
	STI	R0,*+AR0(OROMDATA)
	LDI	O_IROT|O_NOROT|O_NOUROT|O_NOUNIV,R0
	OR	*+AR0(OFLAGS),R0
	STI	R0,*+AR0(OFLAGS)


	FLOAT	LOGO_X,R0
	STF	R0,*+AR0(OPOSX)
	FLOAT	LOGO_Y,R0
	STF	R0,*+AR0(OPOSY)
	FLOAT	LOGO_Z,R0
	STF	R0,*+AR0(OPOSZ)
	LDI	AR0,AR2
	CALL	OBJ_INSERTP
LOGOX
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*BRANCHED TO FROM RADIO_BUT IN SND.asm
*IS A PROC

	.bss	RADIO_HS_SHADOW,1
	.bss	RADIO_HS_SWITCH,1

RBMATTR_CHECK:
	LDI	@_MODE,R0
	TSTB	MHS,R0		;IN HS DISPLAY?
	BEQ	RBMCX
	LDI	@RADIO_HS_SWITCH,R0
	SUBI	1,R0
	STI	R0,@RADIO_HS_SWITCH

RBMCX
	DIE
*----------------------------------------------------------------------------
	.END
