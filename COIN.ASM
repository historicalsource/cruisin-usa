	.FILE	"COIN.ASM"
*----------------------------------------------------------------------------
*COIN ROUTINES
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
	.include	PALL.EQU
	.include	OBJECTS.EQU
	.include	TEXT.EQU


	.bss	COINOFF,1		;T -> DONT SHOW "INSERT COINS" MESSAGE

*----------------------------------------------------------------------------
*THESE ROUTINES MUST PRESERVE R3
COIN1:
	SOND1	COININ
	INCAUD	AUD_COIN1
	CALL	SEND_COINDROP

	CALL	GET_COIN1_COUNTER

	LDP	@COIN_COUNTER1
	LDI	@COIN_COUNTER1,R1
	ADDI	R0,R1
;	INC	R1
	STI	R1,@COIN_COUNTER1
	SETDP


	CALL	GET_COIN1

	BU	CHECK_CREDITS
COIN2:
	SOND1	COININ
	INCAUD	AUD_COIN2

	CALL	SEND_COINDROP


;this is a possibly permenant kludge of only having
;1 coin counter
;


	LDI	@DIPRAM,R0
	TSTB	DIP_COINCNTR,R0
	BZ	JAJA3
	CALL	GET_COIN2_COUNTER
	
	LDP	@COIN_COUNTER1
	LDI	@COIN_COUNTER1,R1
	ADDI	R0,R1
;	INC	R1
	STI	R1,@COIN_COUNTER1
	SETDP
	BU	JAJA5

JAJA3
	CALL	GET_COIN2_COUNTER

	LDP	@COIN_COUNTER2
	LDI	@COIN_COUNTER2,R1
	ADDI	R0,R1
	STI	R1,@COIN_COUNTER2
	SETDP
JAJA5



	CALL	GET_COIN2
	BU	CHECK_CREDITS


COIN3:
	SOND1	COININ
	INCAUD	AUD_COIN2
	CALL	GET_COIN3_COUNTER

	LDP	@COIN_COUNTER1
	LDI	@COIN_COUNTER1,R1
	ADDI	R0,R1
	STI	R1,@COIN_COUNTER1
	SETDP

	CALL	GET_COIN3
	BU	CHECK_CREDITS


COIN4:
	SOND1	COININ
	INCAUD	AUD_COIN4
	CALL	GET_COIN4_COUNTER

	LDP	@COIN_COUNTER1
	LDI	@COIN_COUNTER1,R1
	ADDI	R0,R1
	STI	R1,@COIN_COUNTER1
	SETDP

	CALL	GET_COIN4
	BU	CHECK_CREDITS

SERV_COIN:
	SOND1	COININ
	INCAUD	AUD_SERVICE_CREDITS
	READAUD	AUD_CREDITS
	LDI	R0,R1
	INC	R1


	READAUD	ADJ_MAX_CREDITS
	CMPI	R0,R1
	LDIGE	R0,R1

	LDI	R1,R2
	SETAUD	AUD_CREDITS
	DIE

CHECK_CREDITS:
	;R2 HAS PCREDITS TO INCREMENT
	;
	CMPI	0,R2			;ZERO COIN SLOT? THIS will mees up the bonus system
	BEQ	CHECK_CREDITSX

	LDI	R2,R1			;ADD TO PCREDITS
	ADDAUD	AUD_PCREDITS		;R2 HAS NEW VALUE

	LDI	R1,R2			;ADD TO BCREDITS
	ADDAUD	AUD_BCREDITS		;BONUS COUNTER

	READAUD	AUD_PCREDITS		;READ BACK THE PCREDITS
	LDI	R0,R2


CHECK_CREDITSLP

;FIRST CHECK TO SEE IF MORE THAN MIN PCREDITS FOR A CREDIT
	CALL	GET_MIN_UNITS
	CMPI	R1,R2
	BLT	NOINC
SKIP_MIN
	CALL	GET_UNITS_PER_CREDIT
	CMPI	R1,R2
	BLT	NOINC

	SUBI	R1,R2
	SETAUD	AUD_PCREDITS
	PUSH	R2

	READAUD	AUD_CREDITS

	PUSH	R2
	LDI	R0,R1
	INC	R1
	
	READAUD	ADJ_MAX_CREDITS
	CMPI	R0,R1
	LDIGE	R0,R1

	LDI	R1,R2
	SETAUD	AUD_CREDITS
	POP	R2

	INCAUD	AUD_PAID_CREDITS

NOINCCRD
	POP	R2
	BU	CHECK_CREDITSLP
NOINC
	READAUD	AUD_BCREDITS
	LDI	R0,R2
	CALL	GET_UNITS_FOR_BONUS
	CMPI	0,R1
	BEQ	NOBONUS
	CMPI	R1,R2
	BLT	NOBONUS
	LDI	0,R2
	LDI	AUD_BCREDITS,AR2
	CALL	AUDIT_WRITE
	READAUD	AUD_CREDITS		;BONUS CREDIT


	LDI	R0,R1
	ADDI	1,R1			;Actually give the bonus
	
	READAUD	ADJ_MAX_CREDITS
	CMPI	R0,R1
	LDIGE	R0,R1

	LDI	R1,R2
	SETAUD	AUD_CREDITS

	LDI	0,R2
	SETAUD	AUD_PCREDITS
NOBONUS
CHECK_CREDITSX
	DIE
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GETCOIN
*
*RETURNS
*	AR0	PTR TO COIN TABLE ENTRY
*
	.global	COIN_ENTRY_SIZE
	.ref	COIN_TABLEI,COIN_TABLEENDI
	.def	GETCOIN
	.def	GETCOINTXT
GETCOIN:
	LDI	ADJ_STANDARD_PRICING,AR2
	CALL	ADJUSTMENT_READ
	CMPI	1,R0
	BEQ	USE_STANDARD
	LDI	@CUSTOM_COINTABI,AR0
	RETS
USE_STANDARD
	LDI	ADJ_COINMODE,AR2
	CALL	ADJUSTMENT_READ
	LDI	R0,AR0

GET_THIS_COIN:
	AND	07Fh,AR0
	MPYI	COIN_ENTRY_SIZE,AR0
	ADDI	@COIN_TABLEI,AR0

	CMPI	@COIN_TABLEENDI,AR0
	BLT	GETCOINX

	LDI	@COIN_TABLEI,AR0
GETCOINX
	RETS

	.def	GET_THIS_COINTXT
GET_THIS_COINTXT:
	CALL	GET_THIS_COIN
	ADDI	3,AR0		;NOTE AR0 now points to the COIN TABLE ENTRY WHERE THE MESSAGE RESIDES
	RETS

GETCOINTXT:
	CALL	GETCOIN
	ADDI	3,AR0		;NOTE AR0 now points to the COIN TABLE ENTRY WHERE THE MESSAGE RESIDES
	RETS
*----------------------------------------------------------------------------

*COIN TABLE ENTRY 11 words total
*0	byte	coin1,coin2,coin3,coin4
*1	byte	units per credit,units for bonus,min units,credits to start
*2	byte	credits to continue,show partial credits,NOT USED,NOT USED
*3	word	message_string line 1;Must have at lease one message
*4	word	message_string line 2;	0 = no message on line 2 or 3
*5	word	message_string line 3;	0 = no message on line 3
*6	word	message_string coin 1 denaomination	NOTE: NULL$ = NOT USED
*7	word	message_string coin 2 denaomination	NOTE: NULL$ = NOT USED
*8	word	message_string coin 3 denaomination	NOTE: NULL$ = NOT USED
*9	word	message_string coin 4 denaomination	NOTE: NULL$ = NOT USED
*10	byte	coin1_denom,coin2_denom,coin3_denom,coin4_denom
*NOTE ALL UNUSED BYTES MUST BE SET TO 0

	LONGROUT
*----------------------------------------------------------------------------
GET_COIN1:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*AR0,R2			;GET UNITS FOR COIN 1
	AND	0FFh,R2			; byte	coin1,coin2,coin3,coin4

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
GET_COIN2:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*AR0,R2			;GET UNITS FOR COIN 2
	LSH	-8,R2
	AND	0FFh,R2			; byte	coin1,coin2,coin3,coin4

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
GET_COIN3:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*AR0,R2			;GET UNITS FOR COIN 3
	LSH	-16,R2
	AND	0FFh,R2			; byte	coin1,coin2,coin3,coin4

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
GET_COIN4:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*AR0,R2			;GET UNITS FOR COIN 4
	LSH	-24,R2
	AND	0FFh,R2			; byte	coin1,coin2,coin3,coin4

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
GET_UNITS_PER_CREDIT:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*+AR0(1),R1		;GET #MIN UNITS FOR 1 CREDIT
	AND	0FFh,R1			; byte	units per credit,units for bonus,min units,credits to start

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS

*----------------------------------------------------------------------------
GET_UNITS_FOR_BONUS:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*+AR0(1),R1		;GET #UNITS FOR 1 CREDIT
	LSH	-8,R1
	AND	0FFh,R1			; byte	units per credit,units for bonus,min units,credits to start

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
GET_MIN_UNITS:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*+AR0(1),R1		;GET #MIN UNITS FOR 1 CREDIT
	LSH	-16,R1
	AND	0FFh,R1			; byte	units per credit,units for bonus,min units,credits to start

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS

*----------------------------------------------------------------------------
	.def	GET_CREDITS_TO_START
GET_CREDITS_TO_START:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*+AR0(1),R1		;GET #UNITS FOR 1 CREDIT
	LSH	-24,R1
	AND	0FFh,R1			; byte	units per credit,units for bonus,min units,credits to start

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
	.def	GET_CREDITS_TO_CONTINUE
GET_CREDITS_TO_CONTINUE:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*+AR0(2),R1		;GET #UNITS FOR 1 CREDIT
	AND	0FFh,R1			; byte	credits to continue,show partial credits,NOT USED,NOT USED

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------
GET_SHOW_PARTIAL:
	PUSH	AR0
	PUSH	AR2
	PUSH	R0
	PUSHF	R0

	CALL	GETCOIN
	LDI	*+AR0(2),R1		;GET #UNITS FOR 1 CREDIT
	LSH	-8,R1
	AND	0FFh,R1			; byte	credits to continue,show partial credits,NOT USED,NOT USED

	POPF	R0
	POP	R0
	POP	AR2
	POP	AR0
	RETS

*----------------------------------------------------------------------------
GET_COIN1_COUNTER:
	PUSH	AR0
	PUSH	AR2

	CALL	GETCOIN
	LDI	*+AR0(10),R0		;GET UNITS FOR COIN 1 DENOMINATION
	AND	0FFh,R0			; byte	coin1,coin2,coin3,coin4

	POP	AR2
	POP	AR0
	RETS

*----------------------------------------------------------------------------
GET_COIN2_COUNTER:
	PUSH	AR0
	PUSH	AR2

	CALL	GETCOIN
	LDI	*+AR0(10),R0		;GET UNITS FOR COIN 2 DENOMINATION
	LSH	-8,R0
	AND	0FFh,R0			; byte	coin1,coin2,coin3,coin4

	POP	AR2
	POP	AR0
	RETS

*----------------------------------------------------------------------------
GET_COIN3_COUNTER:
	PUSH	AR0
	PUSH	AR2

	CALL	GETCOIN
	LDI	*+AR0(10),R0		;GET UNITS FOR COIN 3 DENOMINATION
	LSH	-16,R0
	AND	0FFh,R0			; byte	coin1,coin2,coin3,coin4

	POP	AR2
	POP	AR0
	RETS

*----------------------------------------------------------------------------
GET_COIN4_COUNTER:
	PUSH	AR0
	PUSH	AR2

	CALL	GETCOIN
	LDI	*+AR0(10),R0		;GET UNITS FOR COIN 4 DENOMINATION
	LSH	-24,R0
	AND	0FFh,R0			; byte	coin1,coin2,coin3,coin4

	POP	AR2
	POP	AR0
	RETS

	END_LONGROUT

*----------------------------------------------------------------------------
*Reads DIPSW3 to determine the default value of the coin mode
*RETURNS
*	AR2= POINTER TO COIN MODE DATA
*	R2= COINMODE NUMBER

	.def	GETCOIN_DEFAULT
	.ref	COUNTRY_DEFAULTS_ENDI
GETCOIN_DEFAULT:
	PUSH	AR2
	CLRI	AR2
	LDP	@DIPSW
	LDI	@DIPSW,R2
	LDI	*AR2,AR2
	POP	AR2
	SETDP
	RS	24,R2
	NOT	R2
	LDI	0,R0
	LDI	7,RC
	RPTB	INVBLP
	LSH	-1,R2
INVBLP	ROLC	R0
	LDI	R0,R2
	AND	060h,R2
	LSH	-5,R2
	.ref	COUNTRY_DEFAULTSI
	LDI	@COUNTRY_DEFAULTSI,AR2
	AND	01Fh,R0
	MPYI	4,R0
	ADDI	R0,AR2
	ADDI	R2,AR2

	CMPI	@COUNTRY_DEFAULTS_ENDI,AR2
	LDIGT	@COUNTRY_DEFAULTSI,AR2
	LDI	*AR2,R0
	SUBI	@COIN_TABLEI,R0
	LDI	COIN_ENTRY_SIZE,R1
	CALL	DIV_I
	LDI	R0,R2
	LDI	*AR2,AR2
	RETS
*----------------------------------------------------------------------------
*Set the custom coinage to the standard coin mode selected
	.def	SET_COINAGE_ADJ

SET_COINAGE_ADJ:
	CALL	PUSHALL		;Take no chances
	CALL	GET_COIN1
	SETADJ	ADJ_COIN1_UNITS

	CALL	GET_COIN2
	SETADJ	ADJ_COIN2_UNITS

	CALL	GET_COIN3
	SETADJ	ADJ_COIN3_UNITS

	CALL	GET_COIN4
	SETADJ	ADJ_COIN4_UNITS

	CALL	GET_UNITS_PER_CREDIT
	LDI	R1,R2
	SETADJ	ADJ_UNITS_PER_CREDIT

	CALL	GET_UNITS_FOR_BONUS
	LDI	R1,R2
	SETADJ	ADJ_BONUS_UNITS

	CALL	GET_MIN_UNITS
	LDI	R1,R2
	SETADJ	ADJ_UNITS_MIN

	CALL	GET_CREDITS_TO_START
	LDI	R1,R2
	SETADJ	ADJ_CREDITS_TO_START

	CALL	GET_CREDITS_TO_CONTINUE
	LDI	R1,R2
	SETADJ	ADJ_CREDITS_TO_CONTINUE

	CALL	GET_SHOW_PARTIAL
	LDI	R1,R2
	SETADJ	ADJ_SHOW_FRAC

	CALL	GET_COIN1_COUNTER
	SETADJ	ADJ_COIN1_COUNTER

	CALL	GET_COIN2_COUNTER
	SETADJ	ADJ_COIN2_COUNTER

	CALL	GET_COIN3_COUNTER
	SETADJ	ADJ_COIN3_COUNTER

	CALL	GET_COIN4_COUNTER
	SETADJ	ADJ_COIN4_COUNTER

	CALL	POPALL
	RETS

*----------------------------------------------------------------------------
INIT_CUSTOM_COIN:
	LDI	3*8,R5
	LDI	@CUSTOM_COINTABI,AR3
	LDI	ADJ_COIN4_UNITS,AR2
	CALL	INICC		;Set SLOT SETTINGS coin1,coin2,coin3,coin4

	LDI	ADJ_CREDITS_TO_START,AR2
	LDI	3*8,R5			;Set units per credit,units for bonus,min units,credits to start
	CALL	INICC

	LDI	ADJ_SHOW_FRAC,AR2
	LDI	1*8,R5			;Set credits to continue,show partial credits,NOT USED,NOT USED
	CALL	INICC

	LDI	@MSG_NULLI,R0		;Set pointer to the string
	STI	R0,*AR3++
	LDI	0,R0
	STI	R0,*AR3++
	STI	R0,*AR3++

	LDI	@MSG_NULLI,R0		;Point denomination messages to NULL string
	STI	R0,*AR3++
	STI	R0,*AR3++
	STI	R0,*AR3++
	STI	R0,*AR3++

	LDI	3*8,R5
	LDI	ADJ_COIN4_COUNTER,AR2
	CALL	INICC		;Set SLOT SETTINGS coin1,coin2,coin3,coin4

ICCX
	RETS
INICC:
	LDI	0,R6
INICC_LP
	PUSH	AR2
	CALL	ADJUSTMENT_READ
	POP	AR2
	NOP	*AR2--
	AND	0FFh,R0
	LSH	R5,R0
	OR	R0,R6
	SUBI	8,R5
	BGE	INICC_LP	
	STI	R6,*AR3++

	RETS


CUSTOM_COINTABI	.word	CUSTOM_COINTAB
	.bss	CUSTOM_COINTAB,COIN_ENTRY_SIZE
CUSTOM_COINSTRI	.word	CUSTOM_COINSTR
	.bss	CUSTOM_COINSTR,10
bufferi	.word	buffer
	.bss	buffer,2


CTS_STRI	.word	CTS_STR
CTS_STR		.string	" TO START",0

CTC_STRI	.word	CTC_STR
CTC_STR		.string	" TO CONTINUE",0

FCBI	.word	FCB	;FULL CREDIT BUFFER
	.bss	FCB,1

PCBI	.word	PCB	;PARTIAL CREDIT BUFFER
	.bss	PCB,1

CREDITBUFFI	.word	CREDITBUFFER
	.bss	CREDITBUFFER,8

TOSTARTBUFFI	.word	TOSTARTBUFFER
	.bss	TOSTARTBUFFER,8

NCBI	.word	NCB	; '/'
NCB	.string	"@",0

SPCI	.word	SPC
SPC	.string	" ",0

DBLSPCI	.word	DBLSPC
DBLSPC	.string	"  ",0

CWI	.word	CW
CW	.string	"CREDITS",0

CWSI	.word	CWS
CWS	.string	"CREDIT",0

SCI	.word	SCS	;CREDITS TO START (START CREDIT)
	.bss	SCS,1

MSG_NULLI	.word	MSG_NULL
MSG_NULL	.string "",0

*----------------------------------------------------------------------------

FONT18RED:
	.globl	font18_white
	LDL	font18_white,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)
	RETS

FONT18REDDS:
	LDL	font18_white,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)
	STI	R0,*+AR1(TEXT_PAL)
	RETS


*----------------------------------------------------------------------------
*
*	F  P/N  CREDITS
*
INSERTCOINSI	.word	INSERTCOINS
INSERTCOINS	.string	"INSERT COINS",0
HITSTARTI	.word	HITSTART
HITSTART	.string	"PRESS START",0

	.bss	ICF,1	;INSERT COIN FLASH

INSERT_COINS:
	CALL	VOLUME_DISPLAY

	CALL	MOTION_VALID


	LDI	@COINOFF,R0
	RETSNZ

	READADJ	ADJ_FREE_PLAY
	FLOAT	360,R3
	CMPI	1,R0
	BEQ	FLASH_START

	LDI	@_ATTR_MODE,R0
	AND	1,R0
	BZ	SHOW_COINAGE


	READAUD	AUD_PCREDITS
	PUSH	R0
	READAUD	AUD_CREDITS
	POP	R2
	ADDI	R0,R2
	BZ	FLASH_INSERTCOINS

	;
	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MINSERT_COINS,R0
	BEQ	FLASH_INSERTCOINS
SHOW_COINAGE
	CALL	GET_COINAGE_HIGHT	;Sets R3
	ADDF	44,R3
	MPYF	-0.5,R3
	FLOAT	345,R0			;Center of text hight
	ADDF	R0,R3

	READAUD	AUD_CREDITS

	CALL	GET_CREDITS_TO_START
	CMPI	R1,R0
	BLT	NO_START
	CALLGE	FLASH_START
	ADDF	22,R3
	BU	SHOW_CREDITS
NO_START
	CALL	FLASH_TO_START		;FLASH THE TO START AND TO CONTINUE MESSAGES
	ADDF	22,R3
SHOW_CREDITS
	READAUD	AUD_PCREDITS
	PUSH	R0
	READAUD	AUD_CREDITS
	POP	R2
	ADDI	R0,R2
	BNZ	GODO_CREDITS
	CALL	SHOW_INSERTCOINS
	BU	DO_COINAGE
GODO_CREDITS
	CALL	PRINT_CREDITS		;Print the credits message

	LDI	@CREDITBUFFI,AR2
	FLOAT	256,R2
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	FONT18REDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
DO_COINAGE
	ADDF	22,R3
	FLOAT	256,R2
;	FLOAT	345,R3
	CALL	PRINT_COINAGE

INSERT_COINSX
	RETS

*----------------------------------------------------------------------------
* This routine FLASHES THE INSERT COINS MESSAGE
*

FLASH_INSERTCOINS:
	LDI	@ICF,R0
	BGT	NO_INSERTCOINS

	SUBI	@NFRAMES,R0
	CMPI	-30,R0
	LDILT	1,R0
	STI	R0,@ICF

SHOW_INSERTCOINS:
	LDI	@INSERTCOINSI,AR2
	FLOAT	256,R2
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	FONT18REDDS
	BU	FLASH_INSERTCOINSX

NO_INSERTCOINS
	LDI	@ICF,R0
	ADDI	@NFRAMES,R0
	CMPI	30,R0
	LDIGT	-1,R0
	STI	R0,@ICF

FLASH_INSERTCOINSX
	RETS

*----------------------------------------------------------------------------
* This routine FLASHES THE PRESS START MESSAGE
*
FLASH_START:
	LDI	BUT_START,R0
	STI	R0,@BUTTON_STATUS

	LDI	@ICF,R0
	BGT	START_SKIP

	SUBI	@NFRAMES,R0
	CMPI	-20,R0
	LDILT	1,R0
	STI	R0,@ICF


	LDI	@HITSTARTI,AR2
	FLOAT	256,R2
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	FONT18REDDS


	BU	FLASH_STARTX

START_SKIP
	ADDI	@NFRAMES,R0
	CMPI	20,R0
	LDIGT	-1,R0
	STI	R0,@ICF
	BU	FLASH_STARTX

FLASH_STARTX
	RETS




*----------------------------------------------------------------------------
*PRINT_COINAGE
*
*Prints up to 3 lines of text that describes credits per coin
*
*INPUT
*	R2 (FLOAT)	= X screen position in pixels
*	R3 (FLOAT)	= Y screen position in pixels
FONT10_HIGHT	.set	17.0

PRINT_COINAGE:
	CALL	GETCOINTXT
	LDI	*AR0,AR2
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET12FONTDS

	CALL	WHITE10FNT

	CALL	GETCOINTXT
	LDI	*+AR0(1),AR2
	CMPI	0,AR2
	BEQ	PRINT_COINAGEX
	ADDF	FONT10_HIGHT,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET12FONTDS

	CALL	WHITE10FNT

	CALL	GETCOINTXT
	LDI	*+AR0(2),AR2
	CMPI	0,AR2
	BEQ	PRINT_COINAGEX
	ADDF	FONT10_HIGHT,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET12FONTDS
	CALL	WHITE10FNT

PRINT_COINAGEX
	RETS

*----------------------------------------------------------------------------
*GET_COINAGE_HIGHT
*
*Calculates the hight in pixels of the coinage text for centering
*
*RETURNS
*	R3 (FLOAT)	= Y screen hight in pixels

GET_COINAGE_HIGHT:
	PUSHF	R0
	PUSH	R0
	PUSH	AR0
	CALL	GETCOINTXT
	LDF	FONT10_HIGHT,R3
	LDI	*+AR0(1),R0
	BEQ	GCHX
	ADDF	FONT10_HIGHT,R3
	LDI	*+AR0(2),R0
	BEQ	GCHX
	ADDF	FONT10_HIGHT,R3
GCHX
	POP	AR0
	POP	R0
	POPF	R0
	RETS

*----------------------------------------------------------------------------
	.globl	osg10fnt_white
WHITE10FNT:
	LDL	osg10fnt_white,AR2
	CALL	PAL_FIND_RAW
	STI	R0,*+AR0(TEXT_PAL)
	STI	R0,*+AR1(TEXT_PAL)
	RETS

*----------------------------------------------------------------------------
*PRINT_CREDITS
*
*Prints the CREDITS message including partial credits if the mode is on.
*

PRINT_CREDITS:
	CLRI	R7
	STI	R7,@CREDITBUFFER	;STRING BUFFER

	CALL	GET_SHOW_PARTIAL
	LDI	R1,R4

	READAUD	AUD_CREDITS		;DO WE HAVE ANY CREDITS?
	LDI	R0,R2
	BNZ	DO_CREDITS		;Yes, then go print them

	CMPI	1,R4			;No, then check partial credits on?
	BEQ	CHKPCREDITS		;Yes, then go print the partial credits
DO_CREDITS
	LDI	1,R7
	LDI	@FCBI,AR2
	CALL	_itoa

	LDI	@CREDITBUFFI,AR0
	LDI	@FCBI,AR1
	CALL	STRCAT

	LDI	@CREDITBUFFI,AR0
	LDI	@DBLSPCI,AR1
	CALL	STRCAT

CHKPCREDITS
	READAUD	AUD_PCREDITS		;Are there any patial credits?
	LDI	R0,R2
	BZ	NO_PCREDITS		;No, then skip this

	CMPI	0,R4			;Is partial credits on?
	BEQ	NO_PCREDITS		;No, then skip this


	LDI	1,R7
	LDI	@PCBI,AR2
	CALL	_itoa

	LDI	@CREDITBUFFI,AR0
	LDI	@PCBI,AR1
	CALL	STRCAT


 	LDI	@CREDITBUFFI,AR0
	LDI	@NCBI,AR1
	CALL	STRCAT

	CALL	GET_UNITS_PER_CREDIT
	LDI	R1,R2
	LDI	@SCI,AR2
	CALL	_itoa

	LDI	@CREDITBUFFI,AR0
	LDI	@SCI,AR1
	CALL	STRCAT

	LDI	@CREDITBUFFI,AR0
	LDI	@SPCI,AR1
	CALL	STRCAT


NO_PCREDITS
	LDI	@CREDITBUFFI,AR0
	LDI	@CWI,AR1
	READAUD	AUD_CREDITS		;DO WE HAVE ONLY 1 CREDIT?
	CMPI	1,R0
	LDILE	@CWSI,AR1		;ONLY HAVE ON CREDIT USE SINGULAR "CREDIT"

	CALL	STRCAT
	;
	RETS

*----------------------------------------------------------------------------
*FLASH_TO_START
*
*Flash the messages N CREDTIS TO START/N CREDITS TO CONTINUE MESSAGE

FLASH_TO_START:
	LDI	@ICF,R0
	BGT	NO_TOSTART

	SUBI	@NFRAMES,R0
	CMPI	-45,R0
	LDILT	1,R0
	STI	R0,@ICF
	CALL	TOSTART_STRING
	BU	PRINT_TOSTART
NO_TOSTART
	LDI	@ICF,R0
	ADDI	@NFRAMES,R0
	CMPI	45,R0
	LDIGT	-1,R0
	STI	R0,@ICF

	CALL	GET_CREDITS_TO_START
	LDI	R1,R0

	CALL	GET_CREDITS_TO_CONTINUE
	LDI	R1,R2
	CMPI	R0,R2
	BEQ	FLASH_TOSTARTX

	CALL	TOCONT_STRING
PRINT_TOSTART
	LDI	@TOSTARTBUFFI,AR2
	FLOAT	256,R2
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	FONT18REDDS
FLASH_TOSTARTX
	RETS

*----------------------------------------------------------------------------
TOSTART_STRING:
	CLRI	R7
	STI	R7,@TOSTARTBUFFER	;STRING BUFFER

	CALL	GET_CREDITS_TO_START
	LDI	R1,R2

	LDI	1,R7
	LDI	@FCBI,AR2
	CALL	_itoa

	LDI	@TOSTARTBUFFI,AR0
	LDI	@FCBI,AR1
	CALL	STRCAT

	LDI	@TOSTARTBUFFI,AR0
	LDI	@SPCI,AR1
	CALL	STRCAT

	LDI	@TOSTARTBUFFI,AR0
	LDI	@CWI,AR1
	CALL	GET_CREDITS_TO_START
	CMPI	1,R1
	LDIEQ	@CWSI,AR1		;ONLY HAVE ON CREDIT USE SINGULAR "CREDIT"

	CALL	STRCAT

	LDI	@TOSTARTBUFFI,AR0
	LDI	@CTS_STRI,AR1
	CALL	STRCAT
	RETS
*----------------------------------------------------------------------------
TOCONT_STRING:
	CLRI	R7
	STI	R7,@TOSTARTBUFFER	;STRING BUFFER

	CALL	GET_CREDITS_TO_CONTINUE
	LDI	R1,R2

	LDI	1,R7
	LDI	@FCBI,AR2
	CALL	_itoa

	LDI	@TOSTARTBUFFI,AR0
	LDI	@FCBI,AR1
	CALL	STRCAT

	LDI	@TOSTARTBUFFI,AR0
	LDI	@SPCI,AR1
	CALL	STRCAT

	LDI	@TOSTARTBUFFI,AR0
	LDI	@CWI,AR1
	CALL	GET_CREDITS_TO_CONTINUE
	CMPI	1,R1
	LDIEQ	@CWSI,AR1		;ONLY HAVE ON CREDIT USE SINGULAR "CREDIT"
	CALL	STRCAT

	LDI	@TOSTARTBUFFI,AR0
	LDI	@CTC_STRI,AR1
	CALL	STRCAT
	RETS

*----------------------------------------------------------------------------
*VOLUME DISPLAY
*
*
	.bss	VOLUME_ACTIVE,1
	.bss	VOLUME_COUNT,4
VOLUME_TXT	.string	"VOLUME",0
VOLUME_DISPLAY:
	LDI	@VOLUME_ACTIVE,R0
	RETSZ

	DEC	R0
	STI	R0,@VOLUME_ACTIVE

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MDIAG,R0
	RETSEQ


	READADJ	ADJ_VOLUME
	FLOAT	R0,R2
	MPYF	0.11764,R2		;30/255
	FIX	R2
	LDL	VOLUME_COUNT,AR2
	CALL	_itoa
	FLOAT	180,R2
	FLOAT	310,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	FONT18REDDS

	LDL	VOLUME_TXT,AR2
	FLOAT	60,R2
	FLOAT	310,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	CALL	FONT18REDDS

	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*
*
*
*
*
INSERT_MORE_COINS:
	PUSH	R4

	READADJ	ADJ_FREE_PLAY
	CMPI	1,R0
	BEQ	INSERT_COINSXM

	CALL	PRINT_TOCONT

	READAUD	AUD_CREDITS
	LDI	R0,R1
	READAUD	AUD_PCREDITS
	ADDI	R0,R1
	BNZ	ISMCC
	CALL	FLASH_INSERTCOINSM
	BU	INSERT_COINSXM
ISMCC
	CALL	PRINT_CREDITS

	LDI	@CREDITBUFFI,AR2
	FLOAT	256,R2
	FLOAT	237,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)

INSERT_COINSXM
	POP	R4
	RETS
*----------------------------------------------------------------------------
FLASH_INSERTCOINSM:
	LDI	@ICF,R0
	BGT	NO_INSERTCOINSM

	SUBI	@NFRAMES,R0
	CMPI	-30,R0
	LDILT	1,R0
	STI	R0,@ICF

	LDI	@INSERTCOINSI,AR2
	FLOAT	256,R2
	FLOAT	237,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	BU	FLASH_INSERTCOINSXM

NO_INSERTCOINSM
	LDI	@ICF,R0
	ADDI	@NFRAMES,R0
	CMPI	30,R0
	LDIGT	-1,R0
	STI	R0,@ICF

FLASH_INSERTCOINSXM
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
PRINT_TOCONT:
	CALL	TOCONT_STRING

	LDI	@TOSTARTBUFFI,AR2
	FLOAT	256,R2
	FLOAT	200,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
TOCONTX
	RETS
*----------------------------------------------------------------------------



	.bss	CMOS_WP_WORD_SHADOW,1
	.bss	COIN_COUNTER1,1
	.bss	COIN_COUNTER2,1
	.bss	COUNTER_IDX,1
	.bss	COUNTER_MODE,1
*----------------------------------------------------------------------------
*
*IT TAKES 75ms - 100ms FOR STOBING THE COIN COUNTERS
*
*IF (COUNTER_IDX >= 6)  {
*	IF (COUNTER_MODE)
*		
*
*
*}
*ELSE
*	COUNTER_IDX++
*
*
*
*
COIN_COUNTER:
	LDP	@COUNTER_IDX
	LDI	@COUNTER_IDX,R0
	INC	R0
	STI	R0,@COUNTER_IDX
	SETDP
	CMPI	8,R0
	RETSLT

	LDP	@COUNTER_IDX
	CLRI	R0
	STI	R0,@COUNTER_IDX

	LDP	@COUNTER_MODE
	LDI	@COUNTER_MODE,R0
	BZ	CLEARIT

	CLRI	R0
	STI	R0,@COUNTER_MODE

	LDP	@CMOS_WP_WORD_SHADOW
	LDI	@CMOS_WP_WORD_SHADOW,R0
	ANDN	0F00h,R0

	LDP	@COIN_COUNTER1
	LDI	@COIN_COUNTER1,R1
	DEC	R1
	BLT	NOINC1
	STI	R1,@COIN_COUNTER1
	OR	100h,R0
NOINC1
	LDP	@COIN_COUNTER2
	LDI	@COIN_COUNTER2,R1
	DEC	R1
	BLT	NOINC2
	STI	R1,@COIN_COUNTER2
	OR	200h,R0
NOINC2
	DINT
	LDP	@CMOS_WP_WORD
	STI	R0,@CMOS_WP_WORD
	LDP	@CMOS_WP_WORD_SHADOW
	STI	R0,@CMOS_WP_WORD_SHADOW
	EINT
	SETDP
	RETS

CLEARIT
	LDI	1,R0
	STI	R0,@COUNTER_MODE

	DINT
	LDP	@CMOS_WP_WORD_SHADOW
	LDI	@CMOS_WP_WORD_SHADOW,R0
	ANDN	0F00h,R0
	STI	R0,@CMOS_WP_WORD_SHADOW

	LDP	@CMOS_WP_WORD
	STI	R0,@CMOS_WP_WORD
	EINT

	SETDP
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
MOTIONDIS	SPTR	"MOTION OFF"
MOTION_VALID:
	.globl	CHECK_MOTION_DIP
	.globl	CHECK_MOTION_PRESENT

	CALL	CHECK_MOTION_DIP
	RETSNZ			;RETURN IF NON MOVING

	CALL	CHECK_MOTION_PRESENT
	RETSEQ			;RETURN IF ALL OK

	LDI	@MOTIONDIS,AR2
	FLOAT	256,R2
	FLOAT	305,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	RETS
*----------------------------------------------------------------------------
	.END
