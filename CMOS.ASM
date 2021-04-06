	.FILE	"CMOS.ASM"
*----------------------------------------------------------------------------
*CMOS ROUTINES
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	SYS.EQU
	.include	VUNIT.EQU
	.include	C30.EQU
	.include	CMOS.EQU
	.include	MACS.EQU
	.include	GLOBALS.EQU

	.text
*----------------------------------------------------------------------------
CMOSI	.word	CMOS		;start of CMOS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*DECREMENT HIGH SCORE RESET COUNTER
*
HSTDEC
	READAUD	ADJ_ACTUALHSTDRESET
	SUBI	1,R0
	LDILT	0,R0
	LDI	R0,R2
	SETADJ	ADJ_ACTUALHSTDRESET
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CMOS_ON_C:
	PUSH	DP
	LDP	@CPU_WS
	LDI	CMOS_WS,R1
	STI	R1,@CPU_WS
	POP	DP
	RETS
CMOS_OFF_C:
	PUSH	DP
	LDP	@CPU_WS
	LDI	SOFT_WS,R1
	STI	R1,@CPU_WS
	POP	DP
	RETS
CMOS_WPON_C:
	PUSH	DP
	.globl	CMOS_WP_WORD_SHADOW
	LDP	@CMOS_WP_WORD_SHADOW
	LDI	@CMOS_WP_WORD_SHADOW,R1
	AND	0F00h,R1

	LDP	@CMOS_WP_WORD
	STI	R1,@CMOS_WP_WORD
	POP	DP
	RETS
CMOS_WPOFF_C:
	PUSH	DP
	.globl	CMOS_WP_WORD_SHADOW
	LDP	@CMOS_WP_WORD_SHADOW
	LDI	@CMOS_WP_WORD_SHADOW,R1
	AND	0F00h,R1

	LDP	@CMOS_WP_WORD
	OR	CMOS_WP,R1
	STI	R1,@CMOS_WP_WORD
	POP	DP
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*VALIDATE_CMOS
*
*THIS ROUTINE VERIFIES THAT THE CMOS WE ARE USING
*IS CORRECT.  IF NOT, THE VALUES ARE RESET TO THE DEFAULTS.
*CALL ON STARTUP
*
*
VALIDATE_CMOS:

	READAUD	AUD_PCREDITS
	LDI	R0,R2
	CMPI	10,R0
	LDIGT	10,R2
	CMPI	0,R0
	LDILT	0,R2
	SETAUD	AUD_PCREDITS


	READAUD	AUD_CREDITS
	LDI	R0,R2
	CMPI	30,R0
	LDIGT	30,R2
	CMPI	0,R0
	LDILT	0,R2
	SETAUD	AUD_CREDITS

	CALL	VALIDATE_HSTD_TABLES
	CALL	VERIFY_ADJUSTMENTS_ACCURACY
	CLRC
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*RESET_BOOKKEEPING
*
*	RESET THE BOOKKEEPING CMOS PAGE (GENERATE THE NEW CHECKSUM)
*
RESET_BOOKKEEPING:
	PUSH	R0
	PUSH	R2
	PUSH	AR2
	PUSH	AR4

	;erase AUDITS
	LDI	(NUM_AUDITS-MAX_ADJUSTMENTS)-1,AR4
	LDI	@CMOSI,AR2
	ADDI	(MAX_ADJUSTMENTS+1)<<2,AR2
	CLRI	R2
RBLP	CALL	_wr_cw
	DBU	AR4,RBLP

	POP	AR4
	POP	AR2
	POP	R2
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
*
*
VADJTAB	.MACRO	LOW,HIGH,DEFAULT
	.word	:LOW:
	.word	:HIGH:
	.word	:DEFAULT:
;	.word	:HIGH:<<8|:LOW:|(:DEFAULT:<<16)
	.ENDM
	romdata
VERIFY_ADJUSTMENTS_ACCURACYTAB
	VADJTAB	0,81,0		;ADJ_COINMODE
	VADJTAB	0,255,0		;ADJ_GASMIN
	VADJTAB	0,255,255	;ADJ_GASMAX
	VADJTAB	0,255,0		;ADJ_STEERMIN
	VADJTAB	0,255,255	;ADJ_STEERMAX
	VADJTAB	0,255,128	;ADJ_STEERCENTER
	VADJTAB	0,255,0		;ADJ_BRAKEMIN
	VADJTAB	0,255,255	;ADJ_BRAKEMAX
	VADJTAB	0,255,200	;ADJ_VOLUME

	VADJTAB	0,100,1		;ADJ_COIN1_UNITS
	VADJTAB	0,100,1		;ADJ_COIN2_UNITS
	VADJTAB	0,100,1		;ADJ_COIN3_UNITS
	VADJTAB	0,100,1		;ADJ_COIN4_UNITS


	VADJTAB 0,100,1		;ADJ_UNITS_PER_CREDIT
	VADJTAB 0,100,0		;ADJ_BONUS_UNITS
	VADJTAB 0,100,0		;ADJ_UNITS_MIN
	VADJTAB 0,100,3		;ADJ_CREDITS_TO_START
	VADJTAB 0,100,3		;ADJ_CREDITS_TO_CONTINUE

	VADJTAB 0,1,1		;ADJ_SHOW_FRAC
	VADJTAB 0,127,1		;ADJ_COIN1_COUNTER
	VADJTAB 0,127,1		;ADJ_COIN2_COUNTER
	VADJTAB 0,127,1		;ADJ_COIN3_COUNTER
	VADJTAB 0,127,4		;ADJ_COIN4_COUNTER


	VADJTAB	0,1,1		;ADJ_STANDARD_PRICING
	VADJTAB	0,1,0		;ADJ_CUSTOM_PRICING
	VADJTAB	0,1,0		;ADJ_FREE_PLAY
	VADJTAB	0,1,1		;ADJ_FREEGAME
	VADJTAB	0,9,5		;ADJ_DIFFICULTY
	VADJTAB	0,6,3		;ADJ_TIME_TO_START
	VADJTAB	10,25,20	;ADJ_CHECKPOINT_BONUS
	VADJTAB	0,1,0		;ADJ_ATTRACT_MODE_SOUND
	VADJTAB	0,1,1		;ADJ_HIGH_SCORE_ENTRY
	VADJTAB	0,255,100	;ADJ_MIN_VOL_LEVEL
	VADJTAB	0,25000,4000	;ADJ_ACTUALHSTDRESET
	VADJTAB	0,1,0		;ADJ_MPHORKPM
	VADJTAB	0,1,1		;ADJ_ROADKILL
	VADJTAB	0,1,1		;ADJ_CLINTON
	VADJTAB	0,1,1		;ADJ_GIRLS
	VADJTAB	0,5,5		;ADJ_STEERING_SENSE
	VADJTAB	1000,25000,5000	;ADJ_HIGHSCORE_RESET (step 1000)
	VADJTAB	0,100,50	;ADJ_DIFF_LOCAL
	VADJTAB	0,1,0		;UNKNOWN
	VADJTAB	0,30,20		;ADJ_RAMP_PERCENTAGE
	VADJTAB	0,5000,0	;ADJ_RAMP_COUNT
	VADJTAB	0,1,1		;ADJ_ENTER_INITS
	VADJTAB	10,50,30	;ADJ_MAX_CREDITS

	.text
*
VERIFY_ADJUSTMENTS_ACCURACY:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	AR2
	PUSH	AR5
	PUSH	AR6
	CLRI	AR5
	LDL	VERIFY_ADJUSTMENTS_ACCURACYTAB,AR6
VAALP
	LDI	AR5,AR2
	CALL	AUDIT_READ	;R0 = ADJUSTMENT VALUE

	LDI	*AR6++,R1
	LDI	*AR6++,R2
	LDI	*AR6++,R3

	CMPI	R1,R0
	BLT	DORST
	CMPI	R2,R0
	BLE	NORST

DORST	LDI	R3,R2
	LDI	AR5,AR2
	CALL	ADJUSTMENT_WRITE

NORST	INC	AR5
	CMPI	NUM_ADJUSTMENTS,AR5
	BLT	VAALP

	POP	AR6
	POP	AR5
	POP	AR2
	POP	R4
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
RESET_ADJUSTMENTS:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	AR2
	PUSH	AR5
	PUSH	AR6

	CLRI	AR5
	LDL	VERIFY_ADJUSTMENTS_ACCURACYTAB,AR6
VAALP2
	LDI	*AR6++,R2
	LDI	*AR6++,R2
	LDI	*AR6++,R2		;RESET VALUE
	LDI	AR5,AR2
	CALL	AUDIT_WRITE

	INC	AR5
	CMPI	NUM_ADJUSTMENTS,AR5
	BLT	VAALP2

	.ref	GETCOIN_DEFAULT
	CALL	GETCOIN_DEFAULT


;	LDP	@DIPSW
;	LDI	@DIPSW,R2
;	SETDP
;	RS	24,R2
;	NOT	R2
;	LDI	0,R0
;	LDI	7,RC
;	RPTB	INVBLP
;	LSH	-1,R2
;INVBLP	ROLC	R0
;	AND	07Fh,R0
;	LDI	R0,R2

;Now check to see if the dipswitch setting is a valid coinmode
	LDL	VERIFY_ADJUSTMENTS_ACCURACYTAB,AR2
	LDI	ADJ_COINMODE,R0
	MPYI	3,R0
	ADDI	R0,AR2
	LDI	*+AR2,R0
	CMPI	R0,R2
	LDIGT	*+AR2(2),R2
	
	LDI	ADJ_COINMODE,AR2
	CALL	ADJUSTMENT_WRITE


	CALL	CHECKSUMGEN_ADJ
	LDI	R0,R2
	SETAUD	ADJ_CHECKSUM
	POP	AR6
	POP	AR5
	POP	AR2
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*GENERATE CHECKSUM FOR THE ADJUSTMENTS
*
*RETURNS
*	R0	ADJUSTMENT CHECKSUM
*
CHECKSUMGEN_ADJ:
	PUSH	R1
	PUSH	AR2
	PUSH	AR5

	CLRI	AR5
	CLRI	R1
VAALP3
	LDI	AR5,AR2
	CALL	AUDIT_READ	;R0 = ADJUSTMENT VALUE
	ADDI	R0,R1

	INC	AR5
	CMPI	NUM_ADJUSTMENTS,AR5
	BLT	VAALP3

	LDI	R1,R0
	POP	AR5
	POP	AR2
	POP	R1
	RETS
*----------------------------------------------------------------------------



;*----------------------------------------------------------------------------
;*GENERATE CHECKSUM FOR THE AUDITS
;*
;*RETURNS
;*	R0	ADJUSTMENT CHECKSUM
;*
;CHECKSUMGEN_AUD:
;	PUSH	R0
;	PUSH	R1
;	PUSH	AR2
;	PUSH	AR5
;
;	LDI	AUD_COIN1,AR5
;	CLRI	R1
;VAALP4	LDI	AR5,AR2
;	CALL	AUDIT_READ	;R0 = ADJUSTMENT VALUE
;	ADDI	R0,R1
;
;	INC	AR5
;	CMPI	NUM_AUDITS-MAX_ADJUSTMENTS,AR5
;	BLT	VAALP4
;
;	LDI	R1,R0
;	POP	AR5
;	POP	AR2
;	POP	R1
;	POP	R0
;	RETS
;*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
*void	audit_inc(int index)
*
*PARAMETERS
*	AR2	INDEX
*RETURNS
*	R0	AUDIT VALUE
*
AUDIT_INC:
	LS	2,AR2
	ADDI	@CMOSI,AR2
	CALL	_rd_cw
	NOP	*AR2--(4)
	ADDI	1,R0
	LDI	R0,R2
	CALL	_wr_cw
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*void	audit_add(int index)
*
*PARAMETERS
*	AR2	INDEX
*	R2	VALUE
*RETURNS
*	R0	AUDIT VALUE
*
AUDIT_ADD:
	LS	2,AR2
	ADDI	@CMOSI,AR2
	CALL	_rd_cw
	NOP	*AR2--(4)
	ADDI	R0,R2
	CALL	_wr_cw
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*AUDIT_READ
*
*PARAMETERS
*	AR2	INDEX
*RETURNS
*	R0	AUDIT VALUE
*
ADJUSTMENT_READ:
AUDIT_READ:
	LS	2,AR2
	ADDI	@CMOSI,AR2
	CALL	_rd_cw
	NOP	*AR2--(4)
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
*
*
*
*PARAMETERS
*	AR2	INDEX
*	R2	VALUE
*RETURNS
*	R0	AUDIT VALUE
ADJUSTMENT_WRITE:
	CALL	AUDIT_WRITE_ADJ
	CALL	CHECKSUMGEN_ADJ
	LDI	R0,R2
	LDI	ADJ_CHECKSUM,AR2
	CALL	AUDIT_WRITE_ADJ
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*AUDIT_WRITE
*
*PARAMETERS
*	AR2	INDEX
*	R2	VALUE
*RETURNS
*	R0	AUDIT VALUE
*
AUDIT_WRITE:

	.if DEBUG
	CMPI	NUM_ADJUSTMENTS,AR2
	BLT	$	;AUDIT BEING USED TO WRITE ADJUSTMENT
	.endif

AUDIT_WRITE_ADJ:
	LS	2,AR2
	ADDI	@CMOSI,AR2
	CALL	_wr_cw
	NOP	*AR2--(4)
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*NOTE!!!:	MODIFICATIONS TO _rd_cw,_wr_cw,_rd_cwR,_wr_cwR
*NOTE!!!:	MODIFICATIONS TO _rd_cw,_wr_cw,_rd_cwR,_wr_cwR
*NOTE!!!:	MODIFICATIONS TO _rd_cw,_wr_cw,_rd_cwR,_wr_cwR
*
*
*THE REGISTER RULES ARE:
*
*	AR2 is incremented to next entry in CMOS
*	R0  holds RETURN VALUE
*
*	ALL OTHER REGS ARE PRESERVED!!!
*	ALL OTHER REGS ARE PRESERVED!!!
*	ALL OTHER REGS ARE PRESERVED!!!
*
*
*	These are the basic pieces for CMOS I/O.  No other routines
*	should directly access CMOS.
*
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*int	rd_cw(int addr);
*READ CMOS WORD
*
*PARAMETERS
*	AR2	ADDR
*RETURNS
*	R0	WORD
*	AR2	INCREMENTED TO NEXT ENTRY IN CMOS
_rd_cw:
	PUSH	R1
	CMOS_ON
	NOP			;DELAY FOR TIMING...

	LDI	*AR2++,R0
	RS	24,R0
	LS	8,R0

	LDI	*AR2++,R1
	RS	24,R1
	OR	R1,R0
	LS	8,R0

	LDI	*AR2++,R1
	RS	24,R1
	OR	R1,R0
	LS	8,R0

	LDI	*AR2++,R1
	RS	24,R1
	OR	R1,R0

	CMOS_OFF
	POP	R1
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*void	wr_cw(int addr, int value);
*WRITE CMOS WORD
*
*PARAMETERS
*	AR2	LOC
*	R2	WORD
*RETURNS
*	AR2	INCREMENTED TO NEXT ENTRY IN CMOS
*
_wr_cw:
	PUSH	R1
	PUSH	R2
	PUSH	R3
	CMOS_ON
	CMOS_WP_OFF
	NOP			;DELAY FOR TIMING...

	STI	R2,*AR2++
	LS	8,R2
	STI	R2,*AR2++
	LS	8,R2
	STI	R2,*AR2++
	LS	8,R2
	STI	R2,*AR2++
	CMOS_WP_ON
	CMOS_OFF
	POP	R3
	POP	R2
	POP	R1
	RETS
*----------------------------------------------------------------------------
	        


*----------------------------------------------------------------------------
*int	rd_cmR(int addr);
*READ CMOS WORD REVERSED  (MOTOROLA STYLE)
*
*PARAMETERS
*	AR2	LOC
*RETURNS
*	R0	WORD
*	AR2	INCREMENTED TO NEXT ENTRY IN CMOS
*
_rd_cwR:
	PUSH	R1
	CMOS_ON
	NOP			;DELAY FOR TIMING...

	LDI	*AR2++,R0
	RS	24,R0

	LDI	*AR2++,R1
	RS	24,R1
	LS	8,R1
	OR	R1,R0

	LDI	*AR2++,R1
	RS	24,R1
	LS	16,R1
	OR	R1,R0

	LDI	*AR2++,R1
	RS	24,R1
	LS	24,R1
	OR	R1,R0

	CMOS_OFF
	POP	R1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*void	wr_cmR(int addr, int value);
*WRITE CMOS WORD REVERSED
*
*PARAMETERS
*	AR2	LOC
*	R2	WORD
*RETURNS
*	AR2	INCREMENTED TO NEXT ENTRY IN CMOS
*
_wr_cwR:
	PUSH	R1
	PUSH	R2
	PUSH	R3
	LDI	R2,R3
	LS	24,R3
	CMOS_ON
	CMOS_WP_OFF

	NOP			;DELAY FOR TIMING...

	STI	R3,*AR2++
	LDI	R2,R3
	RS	8,R3
	LS	24,R3
	STI	R3,*AR2++

	LDI	R2,R3
	RS	16,R3
	LS	24,R3
	STI	R3,*AR2++

	RS	24,R2
	LS	24,R3
	STI	R2,*AR2++
	CMOS_WP_ON
	CMOS_OFF
	POP	R3
	POP	R2
	POP	R1
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TABLEENT	.MACRO	I1,I2,I3,MIN,SEC,POSTN
		.word	:MIN:*60*56+:SEC:*56
		.string	:I1:,:I2:,:I3:,:POSTN:
		.ENDM
DEFAULT_TABLE_SIZE	.set	2

DEFAULT_TABLE:
	TABLEENT	'T','V','G',2,01,3
	TABLEENT	'E','L','P',2,02,3
	TABLEENT	'E','P','J',2,03,3
	TABLEENT	'M','L',' ',2,04,3
	TABLEENT	'G','W','S',2,06,3
	TABLEENT	'S','X','C',2,08,3
	TABLEENT	'T','E','D',2,10,3
	TABLEENT	'M','E','Y',2,12,3
	TABLEENT	'M','M','V',2,14,3
	TABLEENT	'B','D','P',2,16,3


DEFAULT_TABLE_TOTALI	.word	DEFAULT_TABLE_TOTAL
DEFAULT_TABLE_TOTAL:
	TABLEENT	'T','V','G',28,00,3
	TABLEENT	'E','L','P',28,10,3
	TABLEENT	'E','P','J',28,20,3
	TABLEENT	'M','L',' ',28,30,3
	TABLEENT	'G','W','S',28,40,3
	TABLEENT	'S','X','C',28,50,3
	TABLEENT	'T','E','D',30,00,3
	TABLEENT	'M','E','Y',31,10,3
	TABLEENT	'M','M','V',32,20,3
	TABLEENT	'B','D','P',34,30,3
NUM_TABLES	.set	14



*INIT_LASTHS_TABLE
*CHECK_LASTHS
*----------------------------------------------------------------------------
*Initialize the LAST HS SET CMOS table
*
*This table is to keep track of the High Score entries set (if any at all)
*by the last player.
*There is one byte per Race location.
* -1 = not set by last player. 0-9 = Position in this table for that race
INIT_LASTHS_TABLE:
	LDI	NUM_TABLES+1,R6
	LDI	0,R7
	CALL	GET_TABLE_ADDR
	LDI	-1,R2
	LDI	14,AR5
ILT_LP
	CALL	_wr_cw
	DBU	AR5,ILT_LP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*	R6 = RACE NUMBER
*	R7 = ENTRY NUMBER
UPDATE_LASTHS:
	PUSH	AR2
	PUSH	R0
	PUSH	R2
	PUSH	R6
	PUSH	R7
	LDI	R6,R0
	LDI	NUM_TABLES+1,R6
	LDI	0,R7
	CALL	GET_TABLE_ADDR
	MPYI	4,R0		;4 bytes per word
	ADDI	R0,AR2
	POP	R7
	LDI	R7,R2
	CALL	_wr_cw

	POP	R6
	POP	R2
	POP	R0
	POP	AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*	R1 = RACE NUMBER
*
*Returns R0 = position in table of the last player that played. -1 = not in table

CHECK_LASTHS:
	LDI	NUM_TABLES+1,R6
	LDI	0,R7
	CALL	GET_TABLE_ADDR
	MPYI	4,R1		;4 bytes per word
	ADDI	R1,AR2
	CALL	_rd_cw
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*Initialize the CMOS tables
*
*ALL TABLES DEFAULT TO THE ABOVE TABLE
*
*Related routines for management of CMOS stuff
*
*	INIT_HSTD_TABLES
*	GET_TABLE_ADDR
*	TABLE_ENTRY_READ
*	TABLE_ENTRY_WRITE0
*	TABLE_ENTRY_WRITE
*	CHECK_RACE_TABLE
*	INSERT_TABLE_ENTRY
*
*
	.globl	INIT_HSTD_TABLES
INIT_HSTD_TABLES:
	CLRI	R6
	LDI	15-1,AR5
ITL1
	CLRI	R7
	LDI	10-1,AR4
	LDL	DEFAULT_TABLE,AR1
	CMPI	14,R6			;the 15th entry is the totals for the entire country
	LDIEQ	@DEFAULT_TABLE_TOTALI,AR1
ITL2
	CALL	GET_TABLE_ADDR
	CALL	TABLE_ENTRY_WRITE
	
	ADDI	DEFAULT_TABLE_SIZE,AR1
	INC	R7
	DBU	AR4,ITL2
	INC	R6
	DBU	AR5,ITL1

	CALL	INIT_LASTHS_TABLE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
	.globl	INIT_HSTD_TABLES
VALIDATE_HSTD_TABLES:
	CLRI	R6
	LDI	10-1,AR5
ITL1A
	CLRI	R7
	LDI	10-1,AR4
	LDL	DEFAULT_TABLE,AR1
ITL2A
	CALL	GET_TABLE_ADDR
	CALL	TABLE_ENTRY_READ

	CMPI	' ',R1
	BEQ	J1
	CMPI	'0',R1
	BLT	RESETALL
	CMPI	'Z',R1
	BGT	RESETALL
J1	CMPI	' ',R2
	BEQ	J2
	CMPI	'0',R2
	BLT	RESETALL
	CMPI	'Z',R2
	BGT	RESETALL
J2	CMPI	' ',R3
	BEQ	J3
	CMPI	'0',R3
	BLT	RESETALL
	CMPI	'Z',R3
	BGT	RESETALL

J3	CMPI	0,R4
	BLT	RESETALL
	CMPI	10,R4
	BGT	RESETALL

	CMPI	4*60*60,R0
	BGT	RESETALL
	CMPI	0,R0
	BLT	RESETALL

	ADDI	DEFAULT_TABLE_SIZE,AR1
	INC	R7
	DBU	AR4,ITL2A

	INC	R6
	DBU	AR5,ITL1A
	RETS

RESETALL:
	CALL	INIT_HSTD_TABLES
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*PARAMETERS
*	R6	RACE NUMBER
*	R7	ENTRY NUMBER
*
*RETURNS
*	AR2	ADDRESS
*
GET_TABLE_ADDR:
	PUSH	R6
	PUSH	R7

	MPYI	RACE_TABLE_SIZE,R6
	MPYI	TE_SIZE,R7
	ADDI	R6,R7,AR2
	ADDI	MAX_AUDITS*4,AR2

	ADDI	@CMOSI,AR2
	POP	R7
	POP	R6
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*WRITE ENTRY IN TABLE
*
*PARAMETER
*	AR2	ADDRESS OF ENTRY
*	AR1	TABLE ENTRY
*RETURNS
*	(AR2 INCREMENTED TO THE NEXT ENTRY)
*	
*
TABLE_ENTRY_WRITE:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3

	PUSH	AR1
	LDI	*AR1++,R0
	LDI	*AR1++,R1
	LDI	R1,R2
	RS	8,R2

	LDI	R1,R3
	RS	16,R3

	LDI	R1,R4
	RS	24,R4
	POP	AR1

	BU	TEWL1

*
*PARAMETERS
*	R0	TIME CODE
*	R1	Initial 1
*	R2	Initial 2
*	R3	Initial 3
*	R4	POSITION
*	AR2	ADDR
*
*
TABLE_ENTRY_WRITE0:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3

TEWL1
	PUSH	R2
	LDI	R0,R2
	CALL	_wr_cw
	POP	R2

	PUSH	R1
	CMOS_ON
	CMOS_WP_OFF
;	NOP			;DELAY FOR TIMING...
	POP	R1

	LS	24,R1
	STI	R1,*AR2++
	LS	24,R2
	STI	R2,*AR2++
	LS	24,R3
	STI	R3,*AR2++
	LS	24,R4
	STI	R4,*AR2++
	CMOS_WP_ON
	CMOS_OFF

	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*READ A TABLE ENTRY
*
*
*PARAMETERS
*	AR2	ADDR
*RETURNS
*	R0	TIME CODE
*	R1	Initial 1
*	R2	Initial 2
*	R3	Initial 3
*	R4	POSITION
*	(AR2 INCREMENTED TO THE NEXT ENTRY)
*
TABLE_ENTRY_READ:
	CALL	_rd_cw

	PUSH	R0

	CMOS_ON
	CMOS_WP_OFF

	LDI	*AR2++,R1
	RS	24,R1
	LDI	*AR2++,R2
	RS	24,R2
	LDI	*AR2++,R3
	RS	24,R3
	LDI	*AR2++,R4
	RS	24,R4

	PUSH	R1
	CMOS_WP_ON	;This trashes register R1
	CMOS_OFF
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CHECK_TABLE
*
*THIS ROUTINE CHECKS THE SPECIFIED TABLE TO SEE WHETHER OR NOT
*THE PLAYER CAN ENTER INTO THE TABLE
*
*PARAMETERS
*	R0	TIME CODE (TO CHECK)
*	R1	RACE INDEX
*RETURNS
*	R0	{-1}     = NO, MAY NOT ENTER
*	R0	{0...9}  = INDEX TO ENTER TABLE
*
CHECK_RACE_TABLE:
	PUSH	R0
	LDI	R1,R6
	CLRI	R7
	CALL	GET_TABLE_ADDR
	POP	R6

	CLRI	R5		;RETURN INDEX
NXTENT	CALL	TABLE_ENTRY_READ
	CMPI	R0,R6
	BLT	INSERT_HERE

	INC	R5
	CMPI	10,R5
	BLT	NXTENT

	LDI	-1,R0
	RETS

INSERT_HERE
	LDI	R5,R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
*PARAMETERS
*	R0	TIME CODE
*	R1	Initial 1
*	R2	Initial 2
*	R3	Initial 3
*	R4	POSITION
*	R5	INDEX #
*	R6	RACE #
*
*
*
INSERT_TABLE_ENTRY:

	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5

	LDI	NUM_ENTRIES_PER_RACE-2,R7	;Start at position 8
	CALL	GET_TABLE_ADDR

	CMPI	9,R5
	BGE	ITLX
	
ITEL	CALL	TABLE_ENTRY_READ
	CALL	TABLE_ENTRY_WRITE0	;This uses the registers as input instead of *AR1

	NOP	*AR2--(TE_SIZE*3)
	DEC	R7
	CMPI	R5,R7
	BGE	ITEL				;Copy down position including where inserting

ITLX	POP	R7
	CALL	GET_TABLE_ADDR			;Get the ADDR of the insert point
	POP	R4
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	CALL	TABLE_ENTRY_WRITE0	;This uses the registers as input instead of *AR1

	CALL	UPDATE_LASTHS
	RETS
*----------------------------------------------------------------------------
	.END
