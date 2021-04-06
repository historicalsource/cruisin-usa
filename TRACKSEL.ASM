	.FILE	"TRACKSEL.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	OBJ.EQU
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
	.include	DELTA.EQU
	.include	ERROR.EQU
	.include	COMM.EQU


	.bss	TURNOBJ,1


*----------------------------------------------------------------------------
*
*
*
SMALL_CURSOR		.set	PDATA+0
BIG_CURSOR		.set	PDATA+1
OLD_INDEX		.set	PDATA+2
ROM_SMALL_CURSOR	.set	PDATA+3
ROM_BIG_CURSOR		.set	PDATA+4
LAST_HIDDEN_TRACK	.set	PDATA+5

	.bss	RAW_CHOOSENTRK,1	;BEFORE CONVERTING

CRUISE	SPTR	"CRUISE THE USA"
CRUISE2	SPTR	"JAM WITH THE PRESIDENT"
CRUISE3	SPTR	"IN THE WHITE HOUSE HOT TUB"


*----------------------------------------------------------------------------
*
*
*
*
TRACK_SELECTION:
	CLRI	R0
	STI	R0,@NOAERASE
	STI	R0,@START_HIT



	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	LDI	1,R0
	STI	R0,@CLEARRDY	  	;READY FOR INTERRUPT
KK5	LDI	@CLEARRDY,R0
	BNZ	KK5

;	CALL	PAL_INIT
	CALL	LOAD_FIXED_PALETTES


	LDI	-1,R0	
	STI	R0,*+AR7(OLD_INDEX)
	STI	R0,*+AR7(LAST_HIDDEN_TRACK)

;	CALL	CLEANUP_PALS
	LDL	crace_PALETTES,AR2
	CALL	alloc_section
	SLEEP	1

	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	CALL	FIFO_RESET

	LDL	_SECcrace,AR2
	CALL	LOAD_SECTION_REQ
HOLD4LOAD
	SLEEP	1
	LDI	@DECOMP_ACTIVE,R0
	BNZ	HOLD4LOAD



	LDL	shared_PALETTES,AR2
	CALL	dealloc_section
	LDL	shared_PALETTES,AR2
	CALL	alloc_section
	LDL	_SECshared,AR2
	CALL	LOAD_SECTION_REQ

	CALL	OBJ_INIT
	CALL	BOILERPLATE_INIT


	LDI	@FIRST_RACE,R0
	BZ	NOT_RACE1

	LDL	_SECctrans,AR2
	CALL	LOAD_SECTION_REQ
	LDL	ctrans_PALETTES,AR2
	CALL	alloc_section
NOT_RACE1

	LDP	@_CAMERAPOS
	CLRF	R0
	STF	R0,@_CAMERAPOS+X
	STF	R0,@_CAMERAPOS+Y

	FLOAT	-368,R0
	STF	R0,@_CAMERAPOS+Z
	SETDP

	LDI	TRACK_SELECTION_LIST_LEN+1,R0
	STI	R0,@POSES

	LDI	RM_SINGLE,R0
	STI	R0,@RACE_MODE


	LDL	racemap_grp,AR2
	CALL	LOAD_SINGLE_SECTION
	CALL	FIX_TRACK_SCREEN


	SONDFX	VIEW2IN

	LDI	6,R0
	STI	R0,@POSE

	JSRP	ZOOMINP

	READAUD	AUD_RESET_TOTALLY
	CMPI	0,R0
	BEQ	JAJAD

	.globl	MOTION_SCREWED
MOTION_SCREWED:

	.data
LLG1	.word	L4A
LLG2	.word	L5A
LLG3	.word	L5B
L88	.word	IBOIBOJ

	romdata
L4A	.string	"MOTION RECALIBRATION",0
L5A	.string	"REMAIN SEATED",0
L5B	.string	"DO NOT TOUCH MATS",0
	.text

	.bss	IBOIBOJ,2


	CALL	OBJ_INIT

	LDI	10,AR5
LLKJ
	LDI	@LLG1,AR2
	FLOAT	256,R2
	FLOAT	50,R3
	LDI	60,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET40FONTDS

	LDI	@LLG2,AR2
	FLOAT	256,R2
	FLOAT	120,R3
	LDI	60,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET40FONTDS

	LDI	@LLG3,AR2
	FLOAT	256,R2
	FLOAT	190,R3
	LDI	60,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SET40FONTDS


	LDI	AR5,R2
	LDI	@L88,AR2
	CALL	_itoa
	LDI	@L88,AR2
	FLOAT	256,R2
	FLOAT	260,R3
	LDI	60,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)
	CALL	SETN43FONTDS

	SONDFX	BASICBEEPH
	
	SLEEP	60
	DBU	AR5,LLKJ
	SLEEP	70
	BU	DIAG_RETURN
JAJAD


	;******
	;******
	;******  NORMAL GAME MODE...
	;******
	;******


	LDI	@FIRST_RACE,R0
	BNZ	NOBUYIN77

	LDI	@DID_TIMED_OUT,R0		;IF TIMED OUT THEN YOU MAY NOT GET A FREE RACE
	BNZ	NOT1ST

	LDI	@POSITION,R0
	CMPI	1,R0
	BNE	NOT1ST

	READAUD	ADJ_FREEGAME
	CMPI	0,R0
	BEQ	NOT1ST

	LDI	@BONUS_WAVE,AR2
	DEC	AR2
	ADDI	AUD_WIN_GGATE,AR2
	CALL	AUDIT_INC

	INCAUD	AUD_GAMES_CONTINUES
	INCAUD	AUD_TOTAL_FREEGAMES
	CALL	HSTDEC
	BU	TOJOIN
	;Has the player made Pole Position?  (1)
	;T-> Branch over this Coin Grab
	;F-> Get more coin to continue
	;
NOT1ST

	CALL	BOILERPLATE
	JSRP	INSMORE
	CALL	BOILERPLATE_DELETE

	CMPI	1,AR6
	BNE	ENDPLAYER
	INCAUD	AUD_GAMES_CONTINUES
	CALL	HSTDEC
TOJOIN
	JSRP	ISSUE_STARTGAME_TSEL
NOBUYIN77

	LDI	@_MODE,R0
	ANDN	MBRIDGE|MINTUNNEL|MHUD|MWATER|MINFIN|MHS|MSLINE|MMODE,R0
	OR	MINTRO|MGO,R0
	STI	R0,@_MODE

	LDI	12,R0
	STI	R0,@_countdown
	CALL	INIT_PEDALCHK

	CLRI	R0
	STI	R0,@START_HIT

	LDI	@HEAD2HEAD_ON,R0
	BZ	PRAPA

	LDI	@OM_CHOSEN_RACE,R0
	CMPI	-1,R0
	BNE	PRAJHFS
PRAPA

	LDI	8,AR5
BABO
	CALL	GET_RACE_IDX
	CALL	TRACK_SEL_CURSOR
	SLEEP	1
	DBU	AR5,BABO
PRAJHFS


	CLRI	R0
	STI	R0,@START_HIT


	;*************************************************************
	;*************************************************************
	;SELECT TRACK MAIN LOOP
	;*************************************************************
	;*************************************************************
TRACK_SEL_LP

	;are we linked?
	LDI	@HEAD2HEAD_ON,R0
	BZ	NOWAY

	;has the other player chosen a game
	;
	LDI	@OM_CHOSEN_RACE,R0
	CMPI	-1,R0
	BEQ	NOWAY

	LDI	@OM_HIDDEN_ON,R1
	STI	R1,*+AR7(LAST_HIDDEN_TRACK)

	STI	R0,@CHOSEN_RACE

	LDI	@OM_RACE_MODE,R0
	STI	R0,@RACE_MODE
	BU	TSLPX
NOWAY



	LDI	@START_HIT,R0
	BNZ	TSLPX

	CALL	HIDDEN_TRACKS
	CALL	GET_RACE_IDX
	CALL	TRACK_SEL_CURSOR


	;-------time remaining
	;
	LDL	time,AR2
	LDI	242,R2			;R2	POS X
	LDI	240,R3			;R3	POS Y
	LDI	TM|ZS,R4
	CALL	BLTMOD2D


	LDI	@CRUISE,AR2
	FLOAT	256,R2
	FLOAT	30,R3
	LDI	1,RC
	CALL	TEXT_ADDDS
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	ORM	TXT_CENTER,*+AR1(TEXT_COLOR)



	;HEAD2HEAD
	;
	;are we in linked game?
	;	F -> continue
	;has the other machine chosen the game?
	;	T->  accept the game
	;

	CALL	PEDALCHK
	BC	TSLPX
	CALL	RACESEL_TIMER
	SLEEP	1
	LDI	@_countdown,R0
	BGT	TRACK_SEL_LP
TSLPX


	;HEAD2HEAD
	;
	;NOW TELL OTHER MACHINE:
	;
	;	that we are finished with selecting the race
	;	if we are subordinate dont???
	;
	;
	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
	STI	R0,@HIDDEN_ON
	CALL	SEND_RACENUM


	;IF we are a slave, then we must wait
	;for master to tell us what we chose

	LDI	@HEAD2HEAD_ON,R0
	BZ	NOTYETLNKD

	LDI	@DIPRAM,R0
	TSTB	CMDP_MASTER,R0
	BZ	NOTYETLNKD	;actually: is master therefore IGNORE


	LDI	20,AR5
FEEDBACKLP
	SLEEP	1
	DEC	AR5
	CMPI	0,AR5
	.if	CDEBUG
	BEQ	$
	.endif
	BEQ	NOTYETLNKD
	LDI	@OM_CHOSEN_RACE,R0
	CMPI	-1,R0
	BEQ	FEEDBACKLP

	LDI	@OM_HIDDEN_ON,R1
	STI	R1,*+AR7(LAST_HIDDEN_TRACK)

	LDI	@OM_CHOSEN_RACE,R0
	STI	R0,@CHOSEN_RACE

	LDI	@OM_RACE_MODE,R0
	STI	R0,@RACE_MODE
NOTYETLNKD


	;THIS IS NOW MEANINGLESS
	;CLEAR THIS FOR FUTURE USE
	;	
	CLRI	R0
	STI	R0,@OM_HIDDEN_ON


	;\\\  \\\  \\\  \\\  \\\  \\\
	;    \\\  \\\  \\\  \\\  \\\  \\\

	SONDFX	TRANS


;	;HEAD2HEAD
;	;
;	;NOW TELL OTHER MACHINE:
;	;
;	;	that we are finished with selecting the race
;	;	if we are subordinate dont???
;	;
;	;
;	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
;	STI	R0,@HIDDEN_ON
;	CALL	SEND_RACENUM


	;delete cursor
	;
	LDI	*+AR7(SMALL_CURSOR),AR4
	LDI	*+AR4(OLINK2),AR5

	LDI	@TSEL_HEAD,R0
	BU	LKGGA
JJKKA	LDI	*+AR0(OLINK2),R0
	.if	DEBUG
	BZ	$
	.endif
	BZ	ALLDNA
LKGGA	LDI	R0,AR0
	CMPI	*+AR0(OLINK2),AR4
	BNE	JJKKA
	STI	AR5,*+AR0(OLINK2)
ALLDNA
	.globl	TSEL_HEAD

	LDI	*+AR7(SMALL_CURSOR),AR2
	CALL	OBJ_DELETE




	;********************************************************************
	;WAIT FOR DUAL PLAYER GAME HERE
	;except with the first game
	;
	;********************************************************************
	;
	LDI	@FIRST_RACE,R0
	BNZ	KAKAF
	JSRP	WAIT_FOR_CHALLENGER
KAKAF
	;
	;********************************************************************
	;********************************************************************


	;OM race mode == RM_SINGLE <=> 
	;	not racing across the USA already
	;else
	;	we have bought into an ongoing
	;	race game
	LDI	@RACE_MODE,R0
	CMPI	RM_USA,R0
	BEQ	BOUGHRAU
;	BNE	NBIRAU
;	BU	NOHID1
;NBIRAU



	LDI	@CHOSEN_RACE,R0
	CMPI	5,R0
	LDIEQ	RM_USA,R1
	LDINE	RM_SINGLE,R1
	STI	R1,@RACE_MODE

	CMPI	RM_USA,R1
	BNE	NOTUSA_RACE

	INCAUD	AUD_START_GGATE
	INCAUD	AUD_FS_USA

	LDI	0,AR2
	BU	JJ2
NOTUSA_RACE



	;Translate race index into an actual
	;useable value.
	;
	;
	.bss	HIDDEN_ON,1


	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
	STI	R0,@HIDDEN_ON
	CMPI	-1,R0
	BEQ	NO_HID1

	LDI	@CHOSEN_RACE,AR2
	STI	AR2,@RAW_CHOOSENTRK


	LDI	RACE_GG,AR2
	LDI	AUD_FS_HID_GG,AR3
	CMPI	2,R0
	LDIEQ	RACE_IN,AR2
	LDIEQ	AUD_FS_HID_IN,AR3
	CMPI	3,R0
	LDIEQ	RACE_SF,AR2
	LDIEQ	AUD_FS_HID_SF,AR3

	PUSH	AR2
	LDI	AR3,AR2
	CALL	AUDIT_INC
	POP	AR2

	BU	JJ2

NO_HID1
	;this must happen before translation
	;
	LDI	@CHOSEN_RACE,AR2
	STI	AR2,@RAW_CHOOSENTRK
	ADDI	AUD_FS_AZ,AR2
	CALL	AUDIT_INC


	LDI	@CHOSEN_RACE,AR2
	MPYI	TS_SIZE,AR2
	ADDI	@TRACK_SELECTION_LISTI,AR2
	LDI	*AR2,AR2
JJ2	STI	AR2,@CHOSEN_RACE


BOUGHRAU


	JSRP	TSEL_ZOOMOUTP


	CLRI	R0
	STI	R0,@NOAERASE
	CALL	OBJ_INIT
	SLEEP	2
	CALL	CLEANUP_TRACKSEL_PALS

	CALL	CLEANUP_PALS

	LDI	@CHOSEN_RACE,AR0
	ADDI	@RACE_STARTING_POINTSI,AR0
	LDI	*AR0,R0
	STI	R0,@STARTSECTION
	CALL	FIND_STARTING_VALUES


	LDI	UTIL_C|CHOOSERACE_T,R0
	LDI	-1,R1
	CALL	PRC_KILLALL

	LDI	@CHOSEN_RACE,R0
	STI	R0,@BONUS_WAVE		;Set bonus wave 'cause noby else does until you finish a wave
	RETP
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CLEANUP_TRACKSEL_PALS:
	LDL	crace_PALETTES,AR2
	CALL	dealloc_section
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
*V1+V2 = GOLDEN GATE PARK  not 
*V1+V3 = SAN FRANCISCO
*V2+V3 = INDIANA
*
*
*

*
*
*	R0	IDX {1,2,3}
*
RESTORE_HIDDEN:
	CMPI	-1,R0
	RETSEQ
	PUSH	AR0
	PUSH	AR2
	LDI	401h,AR2
	CMPI	2,R0
	LDIEQ	406h,AR2
	CMPI	3,R0
	LDIEQ	409h,AR2
	CALL	OBJ_FIND_FIRST
	LDI	*+AR0(OCARBLK),R0
	STI	R0,*+AR0(OROMDATA)
	POP	AR2
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
HIDDEN_TRACKS:
	LDI	@SWITCHBUTS,R0
	RS	16,R0
	AND	SW_VIEW0_H|SW_VIEW1_H|SW_VIEW2_H,R0

	CMPI	SW_VIEW0_H|SW_VIEW1_H,R0
	BNE	NHT1

	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
	CMPI	1,R0
	BEQ	HIDDTX

	CALL	RESTORE_HIDDEN

	LDI	1,R0
	STI	R0,*+AR7(LAST_HIDDEN_TRACK)
	;replace
	LDI	401h,AR2
	CALL	OBJ_FIND_FIRST
	LDI	*+AR0(OFLAGS),R0
	ANDN	O_1PAL,R0
	STI	R0,*+AR0(OFLAGS)

	LDI	*+AR0(OROMDATA),R0
	STI	R0,*+AR0(OCARBLK)

	LDL	mpcesy,R0
	STI	R0,*+AR0(OROMDATA)

	BU	HIDDTX


NHT1	CMPI	SW_VIEW0_H|SW_VIEW2_H,R0
	BNE	NHT2

	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
	CMPI	2,R0
	BEQ	HIDDTX
	CALL	RESTORE_HIDDEN
	LDI	2,R0
	STI	R0,*+AR7(LAST_HIDDEN_TRACK)
	;replace
	LDI	406h,AR2
	CALL	OBJ_FIND_FIRST

	LDI	*+AR0(OFLAGS),R0
	ANDN	O_1PAL,R0
	STI	R0,*+AR0(OFLAGS)

	LDI	*+AR0(OROMDATA),R0
	STI	R0,*+AR0(OCARBLK)
	LDL	mpcmed,R0
	STI	R0,*+AR0(OROMDATA)
	BU	HIDDTX


NHT2	CMPI	SW_VIEW1_H|SW_VIEW2_H,R0
	BNE	NHT3

	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
	CMPI	3,R0
	BEQ	HIDDTX
	CALL	RESTORE_HIDDEN
	LDI	3,R0
	STI	R0,*+AR7(LAST_HIDDEN_TRACK)
	;replace
	LDI	409h,AR2
	CALL	OBJ_FIND_FIRST
	LDI	*+AR0(OFLAGS),R0
	ANDN	O_1PAL,R0
	STI	R0,*+AR0(OFLAGS)

	LDI	409h,AR2
	CALL	OBJ_FIND_FIRST
	LDI	*+AR0(OROMDATA),R0
	STI	R0,*+AR0(OCARBLK)
	LDL	mpcexp,R0
	STI	R0,*+AR0(OROMDATA)
	BU	HIDDTX

NHT3

	LDI	*+AR7(LAST_HIDDEN_TRACK),R0
	CMPI	-1,R0
	BEQ	HIDDTX
	CALL	RESTORE_HIDDEN
	LDI	-1,R0
	STI	R0,*+AR7(LAST_HIDDEN_TRACK)
HIDDTX

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*GET THE RACE INDEX (POINTED TO BY WHEEL)
*
*
GET_RACE_IDX:
	CALL	GETCHOICE

	LDI	@POSE,R0
	CMPI	5,R0
	BLE	NDDR
	DEC	R0
NDDR	CMPI	@CHOSEN_RACE,R0
	BEQ	NSND

	PUSH	R0
	SONDFX	TRANS
	POP	R0


NSND	STI	R0,@CHOSEN_RACE

	LDI	*+AR7(LAST_HIDDEN_TRACK),R1
	CMPI	-1,R1
	BEQ	NH

	CMPI	1,R0
	BNE	R55
	CMPI	1,R1		;Hidden golden gate
	LDIEQ	11,AR3
	BNE	NH
	BU	R66

R55
	CMPI	6,R0
	BNE	R56
	CMPI	2,R1
	LDIEQ	12,AR3
	BNE	NH
	BU	R66
R56

	CMPI	9,R0
	BNE	NH
	CMPI	3,R1
	LDIEQ	13,AR3
	BNE	NH

R66
	LDI	@CHOSEN_RACE,R0
	LDI	R0,AR2
	BU	KK88

NH


	LDI	@CHOSEN_RACE,AR2
	LDI	AR2,AR3
KK88	ADDI	400h,AR2
	CALL	OBJ_FIND_FIRST
	LDF	*+AR0(OPOSX),R2
	FLOAT	256,R0
	ADDF	R0,R2
	LDF	*+AR0(OPOSY),R3
	FLOAT	180,R0
	ADDF	R0,R3


	LDI	AR3,R0
	MPYI	TS_SIZE,R0
	LDI	R0,AR0
	ADDI	@TRACK_SELECTION_LISTI,AR0
	LDI	*AR0,AR2
	ADDI	@LEG_NAMESI,AR2
	LDI	*AR2,AR2

	LDI	1,RC
	CALL	TEXT_ADD
	CALL	SET12FONT
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)

	CMPI	5,AR3
	BNE	NOTTHEWH


	READAUD	ADJ_CLINTON
	CMPI	1,R0
	BNE	NOTTHEWH

	LDI	@CRUISE2,AR2
	FLOAT	256,R2
	FLOAT	120,R3
	LDI	1,RC
	CALL	TEXT_ADD
	CALL	SET12FONT
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)

	LDI	@CRUISE3,AR2
	FLOAT	256,R2
	FLOAT	135,R3
	LDI	1,RC
	CALL	TEXT_ADD
	CALL	SET12FONT
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)

NOTTHEWH

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
ZOOMINP:
	LDI	20,AR4
ZITSP	CALL	ZOOMIN_TSEL

	LDI	@OM_CHOSEN_RACE,R0
	CMPI	-1,R0
	BNE	NOWAY543
	CALL	GET_RACE_IDX
	CALL	TRACK_SEL_CURSOR
NOWAY543

	SLEEP	1
	DBU	AR4,ZITSP
	RETP
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
ZOOMIN_TSEL:
	LDI	@OACTIVE,AR5

ZISL	LDI	AR5,R0
	BZ	ZIX
	LDI	R0,AR0
	LDI	*AR0,AR5

	LDF	*+AR0(OVELZ),R0
	SUBF	*+AR0(OPOSZ),R0
	MPYF	0.42,R0	;.15
	CMPF	-5,R0
	BGT	JJDD

	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)
	BU	HGF
JJDD
	LDF	*+AR0(OVELZ),R0
	STF	R0,*+AR0(OPOSZ)
	CLRF	R2
	STF	R2,*+AR0(ORADZ)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_ZMATRIX
	BU	HHFFD
HGF


	LDF	*+AR0(ORADZ),R2
	MPYF	0.65,R2
	STF	R2,*+AR0(ORADZ)
	LDI	AR0,AR2
	ADDI	OMATRIX,AR2
	CALL	FIND_ZMATRIX
HHFFD
	BU	ZISL
ZIX

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*DO THE NESSESARY MUMBO JUMBO, *AND* LINKEM _ALL_
*TOGETHER VIA OLINK2
*
*
*
FIX_TRACK_SCREEN:

	CLRI	R0
	STI	R0,@TSEL_HEAD

	LDI	-1,R6

	LDI	@OACTIVE,AR5
FTSL	LDI	AR5,R0
	BZ	FTSLX
	LDI	R0,AR0
	LDI	*AR0,AR5		;NEXT OBJECT


	LDF	*+AR0(OPOSX),R0
	STF	R0,*+AR0(OVELX)
	LDF	*+AR0(OPOSY),R0
	STF	R0,*+AR0(OVELY)
	LDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OVELZ)

	RANDN	28000
	FLOAT	R0
	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	LDF	6,R0
	CALL	SFRAND
	STF	R0,*+AR0(ORADZ)


	LDI	*+AR0(OID),R0

	CMPI	040Ch,R0	;SMALL CURSOR
	BNE	NSC
	STI	AR0,*+AR7(SMALL_CURSOR)
	LDI	*+AR0(OROMDATA),R0
	STI	R0,*+AR7(ROM_SMALL_CURSOR)
	

	CMPI	-1,R6
	LDIEQ	AR0,R6
	STI	AR5,*+AR0(OLINK2)
	BU	FTSL
NSC
	CMPI	8A1h,R0
	BNE	NTRM1

	LDI	AR0,AR4
	CREATE	CYCLE_PUSH,UTIL_C|CHOOSERACE_T
	LDI	AR4,AR0


	CMPI	-1,R6
	LDIEQ	AR0,R6
	STI	AR5,*+AR0(OLINK2)
	BU	FTSL
NTRM1
	CMPI	8A2h,R0
	BNE	NWHEL1

	LDI	AR0,AR4
	CREATE	TURNTO_SELECT,UTIL_C|CHOOSERACE_T
	LDI	AR4,AR0


	CMPI	-1,R6
	LDIEQ	AR0,R6
	STI	AR5,*+AR0(OLINK2)
	BU	FTSL
NWHEL1

	CMPI	0410h,R0
	BNE	NBC
	STI	AR0,*+AR7(BIG_CURSOR)
	LDI	*+AR0(OROMDATA),R0
	STI	R0,*+AR7(ROM_BIG_CURSOR)

	LDI	AR0,AR2
	CALL	OBJ_DELETE

	CMPI	-1,R6
	LDIEQ	AR0,R6
	STI	AR5,*+AR0(OLINK2)
	BU	FTSL
NBC

	CMPI	0405h,R0
	BNE	NAS
	PUSH	AR0
	LDI	AR0,AR4
	CREATE	ANIMATE_MAP,UTIL_C|CHOOSERACE_T
	POP	AR0

	CMPI	-1,R6
	LDIEQ	AR0,R6
	STI	AR5,*+AR0(OLINK2)
	BU	FTSL
NAS
	CMPI	40Eh,R0
	BNE	NN77
	LDI	AR0,AR2
	CALL	OBJ_DELETE
	BU	FTSL
NN77
	CMPI	40Fh,R0
	BNE	NN88

	LDI	AR0,AR2
	CALL	OBJ_DELETE
	BU	FTSL
NN88
	CMPI	-1,R6
	LDIEQ	AR0,R6
	STI	AR5,*+AR0(OLINK2)
	BU	FTSL
FTSLX
	STI	R6,@TSEL_HEAD
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
	.bss	TSEL_HEAD,1
	.bss	TSEL_THEONE,1
TSEL_ZOOMOUTP:

	SONDFX	VIEW2IN

	LDI	@RACE_MODE,R0
	CMPI	RM_USA,R0
	BNE	JJKKD
	LDI	5,AR2
	BU	LLGF

JJKKD	LDI	@RAW_CHOOSENTRK,AR2
LLGF	LDI	AR2,AR3
	ADDI	400h,AR2
	CALL	OBJ_FIND_FIRST
	STI	AR0,@TSEL_THEONE

	CREATEC	CENTER_THEONE,UTIL_C

	LDI	30,AR5
TSLLP	CALL	TSEL_ZOOMOUT
	SLEEP	1
	DBU	AR5,TSLLP
	RETP
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
CENTER_THEONE:
	LDI	@TSEL_THEONE,AR4

	LDI	15,AR5
CTOLP	LDF	*+AR4(OPOSX),R0
	MPYF	0.8,R0
	STF	R0,*+AR4(OPOSX)

	LDF	*+AR4(OPOSY),R0
	MPYF	0.8,R0
	STF	R0,*+AR4(OPOSY)

	CALL	CENTER_SUB1

	SLEEP	1
	DBU	AR5,CTOLP


	LDI	15,AR5
CTOLPB	LDF	*+AR4(OPOSZ),R0
	MPYF	0.08,R0
	CMPF	50,R0
	LDFLT	50,R0
	ADDF	*+AR4(OPOSZ),R0
	STF	R0,*+AR4(OPOSZ)

	CALL	CENTER_SUB1

	SLEEP	1
	DBU	AR5,CTOLPB
	DIE

CENTER_SUB1:
	LDF	*+AR4(OPOSX),R2
	FLOAT	256,R0
	ADDF	R0,R2
	LDF	*+AR4(OPOSY),R3
	FLOAT	180,R0
	ADDF	R0,R3

	LDI	@RACE_MODE,R0
	CMPI	RM_USA,R0
	BNE	K89
	LDI	14,AR2
	BU	K99

K89	LDI	@CHOSEN_RACE,AR2
K99	ADDI	@LEG_NAMESI,AR2
	LDI	*AR2,AR2

	LDI	1,RC
	CALL	TEXT_ADD
	CALL	SET12FONT
	ORM	TXT_CENTER,*+AR0(TEXT_COLOR)
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TSEL_ZOOMOUT:
	LDI	@TSEL_HEAD,R0
	BU	LKGG

JJKK	LDI	*+AR0(OLINK2),R0
	BZ	ALLDN
LKGG	LDI	R0,AR0

	CMPI	@TSEL_THEONE,R0
	BEQ	JJKK			;skip our choice

	LDF	*+AR0(OPOSX),R0
	MPYF	0.1,R0
	ADDF	*+AR0(OPOSX),R0
	STF	R0,*+AR0(OPOSX)

	LDF	*+AR0(OPOSY),R0
	MPYF	0.1,R0
	ADDF	*+AR0(OPOSY),R0
	STF	R0,*+AR0(OPOSY)

	LDF	*+AR0(OPOSZ),R0
	MPYF	0.08,R0
	CMPF	50,R0
	LDFLT	50,R0

	ADDF	*+AR0(OPOSZ),R0
	STF	R0,*+AR0(OPOSZ)

	BU	JJKK
ALLDN
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*
*
ANIMATE_MAP_TABI	.word	ANIMATE_MAP_TAB
ANIMATE_MAP_TAB		.word	mhop1,mhop2,mhop3,mhop4,-1
*
ANIMATE_MAP:
	LDI	@ANIMATE_MAP_TABI,AR5
AMLP
	LDI	*AR5++,R0
	BN	ANIMATE_MAP
	STI	R0,*+AR4(OROMDATA)

	SLEEP	4
	BU	AMLP
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*
*
*
TRACK_SEL_CURSOR:
	LDI	*+AR7(OLD_INDEX),R0

	LDI	@CHOSEN_RACE,AR0
	CMPI	R0,AR0
	RETSEQ

	STI	AR0,*+AR7(OLD_INDEX)

	LDI	AR0,AR3
	LDI	AR0,AR2
	ADDI	400h,AR2
	CALL	OBJ_FIND_FIRST


	CMPI	5,AR3
	LDIEQ	*+AR7(ROM_BIG_CURSOR),R0
	LDINE	*+AR7(ROM_SMALL_CURSOR),R0

	LDI	*+AR7(SMALL_CURSOR),AR1
	STI	R0,*+AR1(OROMDATA)

	LDF	*+AR0(OPOSX),R0
	STF	R0,*+AR1(OPOSX)
	LDF	*+AR0(OPOSY),R0
	STF	R0,*+AR1(OPOSY)
	LDF	*+AR0(OPOSZ),R0
	SUBF	8,R0
	STF	R0,*+AR1(OPOSZ)
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
TURNANI	.word	whel1,whel2,whel3,whel4,whel3,whel2,-1

*	R6	X
*	R7	Y
*	AR5	Z
*
GET_TURNOBJ:
	FLOAT	AR5,R5
	LDL	TURNANI,AR5
	CALL	OBJ_GET
	LDI	AR0,AR4

	STF	R6,*+AR4(OPOSX)
	STF	R7,*+AR4(OPOSY)
	STF	R5,*+AR4(OPOSZ)


	LDI	AR0,AR2
	CALL	OBJ_INSERTP
GETTOLP
	LDI	@_MODE,R0
	AND	MMODE,R0	;<-this mode
	CMPI	MINTRO,R0
	BNE	SUICIDE

	LDI	*AR5++,R0
	BNN	JIJI
	LDL	TURNANI,AR5
	LDI	*AR5++,R0
JIJI	STI	R0,*+AR4(OROMDATA)

	SLEEP	7
	BU	GETTOLP
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
TRACK_SELECTION_LIST_LEN	.set	11
TRACK_SELECTION_LISTI	.word	TRACK_SELECTION_LIST
TRACK_SELECTION_LIST
	.word	RACE_AZ
	.word	RACE_US101
	.word	RACE_LA
	.word	RACE_IOWA
	.word	RACE_DV

	.word	RACE_USA

;	.word	RACE_DC
	.word	RACE_BH

	.word	RACE_APPL
	.word	RACE_RW
	.word	RACE_GC
	.word	RACE_CH

	;hidden races
	.word	RACE_GG
	.word	RACE_IN
	.word	RACE_SF

*----------------------------------------------------------------------------

	.globl	BOILEROBJ
	.globl	BOILERPLATE_INIT


*----------------------------------------------------------------------------
BOILERPLATE_INIT:
	LDL	next,AR2
	LDI	0,R2
	LDI	0,R3
	LDI	0,RC
	CALL	OBJ_QMAKE
	STI	AR0,@BOILEROBJ
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
BOILERPLATE:
	LDI	*+AR7(SMALL_CURSOR),AR2
	LDF	*+AR2(OPOSX),R0
	STF	R0,*+AR2(OCARBLK)
	FLOAT	-6000,R0
	STF	R0,*+AR2(OPOSX)

	LDI	@BOILEROBJ,AR2
	CALL	OBJ_INSERTP
	RETS
*----------------------------------------------------------------------------
	.bss	BOILEROBJ,1

*----------------------------------------------------------------------------
BOILERPLATE_DELETE:
	LDI	@BOILEROBJ,AR2
	CALL	OBJ_DELETE

	LDI	*+AR7(SMALL_CURSOR),AR2
	LDF	*+AR2(OCARBLK),R0
	STF	R0,*+AR2(OPOSX)
	RETS
*----------------------------------------------------------------------------
	.END
