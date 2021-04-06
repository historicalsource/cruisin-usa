	.FILE	"COINTAB.ASM"
*----------------------------------------------------------------------------
*COINTAB.ASM
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
*

	.include	vunit.equ
	.include	c30.equ
	.include	cmos.equ
	.include	macs.equ
	.include	sys.equ
	.include	GLOBALS.EQU


	.def	COIN_TABLEI,COIN_TABLEENDI,COUNTRY_DEFAULTSI
	.def	COUNTRY_TABI,COINMSGC_TABI
	.def	COUNTRY_DEFAULTS_ENDI


	.def	MSGC_USA1,MSGC_USA2,MSGC_USA3,MSGC_USA4,MSGC_USA5
	.def	MSGC_USA6,MSGC_USA7,MSGC_USA8,MSGC_USA9,MSGC_USA10,MSGC_USA11,MSGC_USA12
	.def	MSGC_GERMAN1,MSGC_GERMAN2,MSGC_GERMAN3,MSGC_GERMAN4,MSGC_GERMAN5
	.def	MSGC_GERMAN6,MSGC_GERMAN7,MSGC_GERMAN8
	.def	MSGC_FRENCH1,MSGC_FRENCH2,MSGC_FRENCH3,MSGC_FRENCH4,MSGC_FRENCH5,MSGC_FRENCH6
	.def	MSGC_FRENCH7,MSGC_FRENCH8,MSGC_FRENCH9,MSGC_FRENCH10,MSGC_FRENCH11
	.def	MSGC_CANADA1,MSGC_CANADA2,MSGC_CANADA3
	.def	MSGC_SWISS1,MSGC_SWISS2,MSGC_SWISS3
	.def	MSGC_ITALY1,MSGC_ITALY2,MSGC_ITALY3
	.def	MSGC_UK1,MSGC_UK2,MSGC_UK3
	.def	MSGC_SPAIN1,MSGC_SPAIN2,MSGC_SPAIN3,MSGC_SPAIN4,MSGC_SPAIN5,MSGC_SPAIN6
	.def	MSGC_AUSTRALIA1,MSGC_AUSTRALIA2,MSGC_AUSTRALIA3,MSGC_AUSTRALIA4
	.def	MSGC_JAPAN1,MSGC_JAPAN2,MSGC_JAPAN3
	.def	MSGC_TAIWAN1,MSGC_TAIWAN2,MSGC_TAIWAN3
	.def	MSGC_AUSTRIA1,MSGC_AUSTRIA2,MSGC_AUSTRIA3,MSGC_AUSTRIA4
	.def	MSGC_BELGIUM1,MSGC_BELGIUM2,MSGC_BELGIUM3
	.def	MSGC_SWEDEN1,MSGC_FINLAND1,MSGC_NETHERLAND1,MSGC_NETHERLAND2,MSGC_NORWAY1,MSGC_DENMARK1
	.def	MSGC_GENERAL1,MSGC_GENERAL2,MSGC_GENERAL3,MSGC_GENERAL4,MSGC_GENERAL5
	.def	MSGC_HUNGARY1
	.def	MSGC_GENERAL6,MSGC_GENERAL7,MSGC_GENERAL8
;	.def	MSGC_HONGKONG1,MSGC_HONGKONG2,MSGC_HONGKONG3


COIN_TABLEI		.word	COIN_TABLE
COIN_TABLEENDI		.word	COIN_TABLEEND
COUNTRY_TABI		.word	COUNTRY_TAB
COUNTRY_DEFAULTSI	.word	COUNTRY_DEFAULTS
COINMSGC_TABI		.word	COINMSGC_TAB

COUNTRY_DEFAULTS_ENDI	.word	COUNTRY_DEFAULTS_END


	romdata

COINMSGC_TAB
	.word	MSGC_USA1,MSGC_USA2,MSGC_USA3,MSGC_USA4,MSGC_USA5
	.word	MSGC_USA6,MSGC_USA7,MSGC_USA8,MSGC_USA9,MSGC_USA10,MSGC_USA11,MSGC_USA12
	.word	MSGC_GERMAN1,MSGC_GERMAN2,MSGC_GERMAN3,MSGC_GERMAN4,MSGC_GERMAN5
	.word	MSGC_GERMAN6,MSGC_GERMAN7,MSGC_GERMAN8
	.word	MSGC_FRENCH1,MSGC_FRENCH2,MSGC_FRENCH3,MSGC_FRENCH4,MSGC_FRENCH5,MSGC_FRENCH6
	.word	MSGC_FRENCH7,MSGC_FRENCH8,MSGC_FRENCH9,MSGC_FRENCH10,MSGC_FRENCH11
	.word	MSGC_CANADA1,MSGC_CANADA2,MSGC_CANADA3
	.word	MSGC_SWISS1,MSGC_SWISS2,MSGC_SWISS3
	.word	MSGC_ITALY1,MSGC_ITALY2,MSGC_ITALY3
	.word	MSGC_UK1,MSGC_UK2,MSGC_UK3
	.word	MSGC_SPAIN1,MSGC_SPAIN2,MSGC_SPAIN3,MSGC_SPAIN4,MSGC_SPAIN5,MSGC_SPAIN6
	.word	MSGC_AUSTRALIA1,MSGC_AUSTRALIA2,MSGC_AUSTRALIA3,MSGC_AUSTRALIA4
	.word	MSGC_JAPAN1,MSGC_JAPAN2,MSGC_JAPAN3
	.word	MSGC_TAIWAN1,MSGC_TAIWAN2,MSGC_TAIWAN3
	.word	MSGC_AUSTRIA1,MSGC_AUSTRIA2,MSGC_AUSTRIA3,MSGC_AUSTRIA4
	.word	MSGC_BELGIUM1,MSGC_BELGIUM2,MSGC_BELGIUM3
	.word	MSGC_SWEDEN1,MSGC_FINLAND1,MSGC_NETHERLAND1,MSGC_NETHERLAND2,MSGC_NORWAY1,MSGC_DENMARK1
	.word	MSGC_HUNGARY1
	.word	MSGC_GENERAL1,MSGC_GENERAL2,MSGC_GENERAL3,MSGC_GENERAL4,MSGC_GENERAL5
	.word	MSGC_GENERAL6,MSGC_GENERAL7,MSGC_GENERAL8
;	.word	MSGC_HONGKONG1,MSGC_HONGKONG2,MSGC_HONGKONG3



MSG_NULL	.string "",0
MSG_41	.string	"4 CREDITS / 1 COIN",0
MSG_32D	.string	"3 CREDITS / 2 DOLLARS",0
MSG_31	.string	"3 CREDITS / 1 COIN",0
MSG_21D	.string	"2 CREDITS / 1 DOLLAR",0
MSG_21	.string	"2 CREDITS / 1 COIN",0

MSG_11		.string	"1 COIN / 1 CREDIT",0
MSG_11D		.string	"1 DOLLAR / 1 CREDIT",0
MSG_11DM	.string	"1DM / 1 CREDIT",0
MSG_1150D	.string	"1 50 DOLLAR / 1 CREDIT",0
MSG_12		.string	"2 COINS / 1 CREDIT",0
MSG_12D		.string	"2 DOLLARS / 1 CREDIT",0
MSG_12DM	.string	"2DM / 1 CREDIT",0
MSG_13		.string	"3 COINS / 1 CREDIT",0
MSG_13D		.string	"3 DOLLARS / 1 CREDIT",0
MSG_13DM	.string	"3DM / 1 CREDIT",0
MSG_14		.string	"4 COINS / 1 CREDIT",0
MSG_15		.string	"5 COINS / 1 CREDIT",0
MSG_15X20C	.string	"5 X 2O CENTS / 1 CREDIT",0
MSG_110X20C	.string	"1O X 2O CENTS / 1 CREDIT",0
MSG_16		.string	"6 COINS / 1 CREDIT",0
MSG_18		.string	"8 COINS / 1 CREDIT",0
MSG_25DM	.string	"5DM / 2 CREDITS",0
MSG_35D		.string	"5 DOLLARS / 3 CREDITS",0
MSG_35DM	.string	"5DM / 3 CREDITS",0
MSG_45D		.string	"5 DOLLARS / 4 CREDITS",0
MSG_65D		.string	"5 DOLLARS / 6 CREDITS",0
MSG_65DM	.string	"5DM / 6 CREDITS",0

MSG_11F		.string	"1F / 1 CREDIT",0
MSG_12F		.string	"2F / 1 CREDIT",0
MSG_13F		.string	"3F / 1 CREDIT",0
MSG_15F		.string	"5F / 1 CREDIT",0
MSG_13X5F	.string	"3 X 5F / 1 CREDIT",0
MSG_110F	.string	"1OF / 1 CREDIT",0
MSG_120F	.string	"2OF / 1 CREDIT",0
MSG_12X20F	.string	"2 X 2OF / 1 CREDIT",0
MSG_25F		.string	"5F / 2 CREDITS",0
MSG_210F	.string	"1OF / 2 CREDITS",0
MSG_220F	.string	"2OF / 2 CREDITS",0
MSG_35F		.string	"5F / 3 CREDITS",0
MSG_310F	.string	"1OF / 3 CREDITS",0
MSG_320F	.string	"2OF / 3 CREDITS",0
MSG_350F	.string	"5OF / 3 CREDITS",0
MSG_430F	.string	"3OF / 4 CREDITS",0
MSG_450F	.string	"5OF / 4 CREDITS",0
MSG_55F		.string	"5F / 5 CREDITS",0
MSG_520F	.string	"2OF / 5 CREDITS",0
MSG_540F	.string	"4OF / 5 CREDITS",0
MSG_720F	.string	"2OF / 7 CREDITS",0
MSG_740F	.string	"4OF / 7 CREDITS",0

MSG_1500L	.string	"5OO LIRE / 1 CREDIT",0
MSG_12X500L	.string	"2 X 5OO LIRE / 1 CREDIT",0
MSG_14X500L	.string	"4 X 5OO LIRE / 1 CREDIT",0

MSG_150P	.string	"5OP / 1 CREDIT",0
MSG_13X20P	.string	"3 X 2OP / 1 CREDIT",0
MSG_1100P	.string	"1OOP / 1 CREDIT",0

MSG_1100PESETA		.string	"1OOPESETA / 1 CREDIT",0
MSG_12X100PESETA	.string	"2 X 1OOPESETA / 1 CREDIT",0
MSG_2100PESETA		.string	"1OOPESETA / 2 CREDITS",0
MSG_32X100PESETA	.string	"2 X 1OOPESETA / 3 CREDITS",0
MSG_3500PESETA		.string	"5OOPESETA / 3 CREDITS",0
MSG_5500PESETA		.string	"5OOPESETA / 5 CREDITS",0
MSG_6500PESETA		.string	"5OOPESETA / 6 CREDITS",0
MSG_7500PESETA		.string	"5OOPESETA / 7 CREDITS",0
MSG_10500PESETA		.string	"5OOPESETA / 1O CREDITS",0

MSG_1100YEN		.string	"1OO YEN / 1 CREDIT",0
MSG_3500YEN		.string	"5OO YEN / 3 CREDITS",0

MSG_1NT10		.string	"NT1O / 1 CREDIT",0

MSG_15SCHIL		.string	"5 SCHILLING / 1 CREDIT",0
MSG_12X5SCHIL		.string	"2 X 5 SCHILLING / 1 CREDIT",0
MSG_12X10SCHIL		.string	"2 X 10 SCHILLING / 1 CREDIT",0
MSG_110SCHIL		.string	"1O SCHILLING / 1 CREDIT",0
MSG_210SCHIL		.string	"1O SCHILLING / 2 CREDITS",0
MSG_230SCHIL		.string	"3O SCHILLING / 2 CREDITS",0
MSG_320SCHIL		.string	"2O SCHILLING / 3 CREDITS",0

MSG_15KRONA		.string	"5 KRONA / 1 CREDIT",0
MSG_15MARKKA		.string	"5 MARKKA / 1 CREDIT",0
MSG_15KRONE		.string	"5 KRONE / 1 CREDIT",0

MSG_11HFI		.string	"1 HFI / 1 CREDIT",0
MSG_1250HFI		.string	"2 5O HFI / 1 CREDIT",0
MSG_3250HFI		.string	"2 5O HFI / 3 CREDITS",0

MSG_14X20FORINT		.string	"4 X 2O FORINT / 1 CREDIT",0
MSG_2140FORINT		.string	"14O FORINT / 2 CREDITS",0

MSG_25C		.string	".25",0
MSG_20C		.string	".2O",0
MSG_100D	.string	"1.OO",0
MSG_200D	.string	"2.OO",0

MSG_1DM		.string	"1 DM",0
MSG_2DM		.string	"2 DM",0
MSG_5DM		.string	"5 DM",0

MSG_1F		.string	"1 F",0
MSG_5F		.string	"5 F",0
MSG_10F		.string	"1O F",0
MSG_20F		.string	"2O F",0
MSG_50F		.string	"5O F",0

MSG_500L	.STRING	"5OO LIRE",0

MSG_10P		.string	"1OP",0
MSG_20P		.string	"2OP",0
MSG_25P		.string	"25P",0
MSG_50P		.string	"5OP",0
MSG_100P	.string	"1OOP",0
MSG_200P	.string	"2OOP",0
MSG_500P	.string	"5OOP",0

MSG_100YEN	.string	"1OO YEN",0
MSG_500YEN	.string	"5OO YEN",0

MSG_NT10	.string	"NT1O",0
MSG_1COIN	.string	"1 COIN",0
MSG_4COINS	.string	"4 COINS",0

MSG_5SCHIL	.string	"5 SCHIL",0
MSG_10SCHIL	.string	"1O SCHIL",0
MSG_20SCHIL	.string	"2O SCHIL",0

MSG_1KRONA	.string	"1 KRONA",0
MSG_5KRONA	.string	" 5KRONA",0
MSG_10KRONA	.string	"1OKRONA",0

MSG_1MARKKA	.string	"1MARKKA",0
MSG_5MARKKA	.string	"  5MARKKA",0
MSG_10MARKKA	.string	"1OMARKKA",0

MSG_1HFI	.string	"1HFI",0
MSG_250HFI	.string	"2.5O HFI",0

MSG_1KRONE	.string	"1KRON",0
MSG_5KRONE	.string	"5KRON",0
MSG_10KRONE	.string	"1OKRON",0
MSG_20KRONE	.string	"2OKRON",0

MSG_20FORINT	.string	"2OFORINT",0
MSG_100FORINT	.string	"1OOFORINT",0

MSGC_USA1	.string	"USA1",0
MSGC_USA2	.string	"USA2",0
MSGC_USA3	.string	"USA3",0
MSGC_USA4	.string	"USA4",0
MSGC_USA5	.string	"USA5",0
MSGC_USA6	.string	"USA6",0
MSGC_USA7	.string	"USA7",0
MSGC_USA8	.string	"USA8",0
MSGC_USA9	.string	"USA9",0
MSGC_USA10	.string	"USA10",0
MSGC_USA11	.string	"USA11",0
MSGC_USA12	.string	"USA12",0

MSGC_GERMAN1	.string	"GERMAN1",0
MSGC_GERMAN2	.string	"GERMAN2",0
MSGC_GERMAN3	.string	"GERMAN3",0
MSGC_GERMAN4	.string	"GERMAN4",0
MSGC_GERMAN5	.string	"GERMAN5",0
MSGC_GERMAN6	.string	"GERMAN6",0
MSGC_GERMAN7	.string	"GERMAN7",0
MSGC_GERMAN8	.string	"GERMAN8",0

MSGC_FRENCH1	.string "FRENCH1",0
MSGC_FRENCH2	.string "FRENCH2",0
MSGC_FRENCH3	.string "FRENCH3",0
MSGC_FRENCH4	.string "FRENCH4",0
MSGC_FRENCH5	.string "FRENCH5",0
MSGC_FRENCH6	.string "FRENCH6",0
MSGC_FRENCH7	.string "FRENCH7",0
MSGC_FRENCH8	.string "FRENCH8",0
MSGC_FRENCH9	.string "FRENCH9",0
MSGC_FRENCH10	.string "FRENCH10",0
MSGC_FRENCH11	.string "FRENCH11",0

MSGC_CANADA1	.string	"CANADA1",0
MSGC_CANADA2	.string	"CANADA2",0
MSGC_CANADA3	.string	"CANADA3",0

MSGC_SWISS1	.string	"SWISS1",0
MSGC_SWISS2	.string	"SWISS2",0
MSGC_SWISS3	.string	"SWISS3",0


MSGC_ITALY1	.string	"ITALY1",0
MSGC_ITALY2	.string	"ITALY2",0
MSGC_ITALY3	.string	"ITALY3",0

MSGC_UK1	.string	"UK1",0
MSGC_UK2	.string	"UK2",0
MSGC_UK3	.string	"UK3",0

MSGC_SPAIN1	.string	"SPAIN1",0
MSGC_SPAIN2	.string	"SPAIN2",0
MSGC_SPAIN3	.string	"SPAIN3",0
MSGC_SPAIN4	.string	"SPAIN4",0
MSGC_SPAIN5	.string	"SPAIN5",0
MSGC_SPAIN6	.string	"SPAIN6",0

MSGC_AUSTRALIA1	.string	"AUSTRALIA1",0
MSGC_AUSTRALIA2	.string	"AUSTRALIA2",0
MSGC_AUSTRALIA3	.string	"AUSTRALIA3",0
MSGC_AUSTRALIA4	.string	"AUSTRALIA4",0

MSGC_JAPAN1	.string	"JAPAN1",0
MSGC_JAPAN2	.string	"JAPAN2",0
MSGC_JAPAN3	.string	"JAPAN3",0

MSGC_TAIWAN1	.string "TAIWAN1",0
MSGC_TAIWAN2	.string "TAIWAN2",0
MSGC_TAIWAN3	.string "TAIWAN3",0

MSGC_AUSTRIA1	.string	"AUSTRIA1",0
MSGC_AUSTRIA2	.string	"AUSTRIA2",0
MSGC_AUSTRIA3	.string	"AUSTRIA3",0
MSGC_AUSTRIA4	.string	"AUSTRIA4",0

MSGC_BELGIUM1	.string	"BELGIUM1",0
MSGC_BELGIUM2	.string	"BELGIUM2",0
MSGC_BELGIUM3	.string	"BELGIUM3",0

MSGC_SWEDEN1		.string	"SWEDEN1",0
MSGC_FINLAND1		.string	"FINLAND1",0
MSGC_NETHERLAND1	.string	"NETHERLAND1",0
MSGC_NETHERLAND2	.string	"NETHERLAND2",0
MSGC_NORWAY1		.string	"NORWAY1",0
MSGC_DENMARK1		.string	"DENMARK1",0
MSGC_HUNGARY1		.string	"HUNGARY1",0

MSGC_GENERAL1		.string "GENERAL1",0
MSGC_GENERAL2		.string "GENERAL2",0
MSGC_GENERAL3		.string "GENERAL3",0
MSGC_GENERAL4		.string "GENERAL4",0
MSGC_GENERAL5		.string "GENERAL5",0
MSGC_GENERAL6		.string "GENERAL6",0
MSGC_GENERAL7		.string "GENERAL7",0
MSGC_GENERAL8		.string "GENERAL8",0

MSGC_HONGKONG1	.string	"HONGKONG1",0
MSGC_HONGKONG2	.string	"HONGKONG2",0
MSGC_HONGKONG3	.string	"HONGKONG3",0


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


COIN_TABLE
;1/3X25
USA1	.string	1,1,4,4		;coin1,coin2,coin3,coin4
	.string	3,0,0,1		;units per credit,units for bonus,min units,credits to start
	.string	1,1,0,0		;credits to continue,show partial credits,NOT USED,NOT USED
	.word	MSG_13		;message_string line 1;Must have at lease one message
	.word	0		;message_string line 2;	0 = no message on line 2 or 3
	.word	0		;message_string line 3;	0 = no message on line 3
	.word	MSG_25C		;message_string coin 1 denaomination	NOTE: NULL$ = NOT USED
	.word	MSG_25C		;message_string coin 2 denaomination	NOTE: NULL$ = NOT USED
	.word	MSG_100D	;message_string coin 3 denaomination	NOTE: NULL$ = NOT USED
	.word	MSG_100D	;message_string coin 4 denaomination	NOTE: NULL$ = NOT USED
	.string	1,1,4,4		;coin1,coin2,coin3,coin4 denominations

;1/2X25
USA2	.string	1,1,4,4
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/4X25
USA3
	.string	1,1,4,4
	.string	4,0,0,1
	.string	1,1,0,0
	.word	MSG_14
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/5X25
USA4
	.string	1,1,4,4
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_15
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/6X25
USA5
	.string	1,1,4,4
	.string	6,0,0,1
	.string	1,1,0,0
	.word	MSG_16
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/8X25
USA6
	.string	1,1,4,4
	.string	8,0,0,1
	.string	1,1,0,0
	.word	MSG_18
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4


;1/8X25, 1/2X100, 3/1X500
USA7
	.string	1,1,4,4
	.string	8,20,0,1
	.string	1,1,0,0
	.word	MSG_12D
	.word	MSG_35D
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/25, 3X25/START, 2X25 CONTINUE
USA8
	.string	1,1,4,4
	.string	1,0,0,3
	.string	2,0,0,0
	.word	MSG_11
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/25, 2X25/START, 1X25 CONTINUE
USA9
	.string	1,1,4,4
	.string	1,0,0,2
	.string	1,0,0,0
	.word	MSG_11
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/2X100 START, 1/150 CONTINUE
USA10
	.string	1,1,4,4
	.string	2,0,0,4
	.string	3,1,0,0
	.word	MSG_12
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/6X25, 4/5X100
USA11
	.string	1,1,4,4
	.string	6,20,0,1
	.string	1,1,0,0
	.word	MSG_1150D
	.word	MSG_45D
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/100 START, 1/3X25 CONTINUE
USA12
	.string	1,1,4,4
	.string	1,0,0,4
	.string	3,1,0,0
	.word	MSG_11
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_100D
	.string	1,1,4,4

;1/3X1DM, 2/5DM
GERMAN1
	.string	1,5,0,0
	.string	1,5,0,3
	.string	3,1,0,0
	.word	MSG_11DM
	.word	MSG_65DM
	.word	0
	.word	MSG_1DM
	.word	MSG_5DM
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/1DM, 5/5DM
GERMAN2
	.string	1,5,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_11DM
	.word	0
	.word	0
	.word	MSG_1DM
	.word	MSG_5DM
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/2X1DM, 3/5DM
GERMAN3
	.string	1,5,0,0
	.string	1,5,0,2
	.string	2,1,0,0
	.word	MSG_11DM
	.word	MSG_65DM
	.word	0
	.word	MSG_1DM
	.word	MSG_5DM
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;2/5DM, 1/3X1DM ECA
GERMAN4
	.string	5,2,1,0
	.string	3,5,0,1
	.string	1,1,0,0
	.word	MSG_13DM
	.word	MSG_25DM
	.word	0
	.word	MSG_5DM
	.word	MSG_2DM
	.word	MSG_1DM
	.word	MSG_NULL
	.string	5,2,1,0

;3/5DM, 1/2DM, 1/2X1DM ECA
GERMAN5
	.string	5,2,1,0
	.string	2,5,0,1
	.string	1,1,0,0
	.word	MSG_12DM
	.word	MSG_35DM
	.word	0
	.word	MSG_5DM
	.word	MSG_2DM
	.word	MSG_1DM
	.word	MSG_NULL
	.string	5,2,1,0

;1/3X1DM, 2/5DM NO BONUS
GERMAN6
	.string	1,6,0,0
	.string	3,0,0,1
	.string	1,1,0,0
	.word	MSG_13DM
	.word	MSG_25DM
	.word	0
	.word	MSG_1DM
	.word	MSG_5DM
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/2X1DM, 3/5DM NO BONUS
GERMAN7
	.string	1,6,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12DM
	.word	MSG_35DM
	.word	0
	.word	MSG_1DM
	.word	MSG_5DM
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/1DM, 6/5DM NO BONUS 2 start 1 continue
GERMAN8
	.string	1,6,0,0
	.string	1,0,0,2
	.string	1,1,0,0
	.word	MSG_11DM
	.word	MSG_65DM
	.word	0
	.word	MSG_1DM
	.word	MSG_5DM
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0



;1/10F, 2/20F, 4/30
FRENCH1
	.string	1,2,0,0
	.string	1,3,0,1
	.string	1,0,0,0
	.word	MSG_110F
	.word	MSG_220F
	.word	MSG_430F
	.word	MSG_10F
	.word	MSG_20F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,2,0,0

;1/10F, 2/20F, 5/40F
FRENCH2
	.string	1,2,0,0
	.string	1,4,0,1
	.string	1,0,0,0
	.word	MSG_110F
	.word	MSG_220F
	.word	MSG_540F
	.word	MSG_10F
	.word	MSG_20F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,2,0,0

;1/10F, 3/20F, 7/40F
FRENCH3
	.string	3,6,0,0
	.string	2,12,0,1
	.string	1,0,0,0
	.word	MSG_110F
	.word	MSG_320F
	.word	MSG_740F
	.word	MSG_10F
	.word	MSG_20F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,2,0,0

;1/5F, 2/10F, 5/20F
FRENCH4
	.string	1,2,0,0
	.string	1,4,0,1
	.string	1,0,0,0
	.word	MSG_15F
	.word	MSG_210F
	.word	MSG_520F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,2,0,0

;1/5F, 3/10F, 7/20F
FRENCH5
	.string	3,6,0,0
	.string	2,12,0,1
	.string	1,0,0,0
	.word	MSG_15F
	.word	MSG_310F
	.word	MSG_720F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,2,0,0

;1F, 5F, 10F, 20F ECA
;1/10F 2/20F, 4/30F
FRENCH6
	.string	1,5,10,20
	.string	10,30,0,1
	.string	1,1,0,0
	.word	MSG_110F
	.word	MSG_220F
	.word	MSG_430F
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_20F
	.string	1,5,10,20

;1F, 5F, 10F, 20F ECA
;1/10F 2/20F, 5/40F
FRENCH7
	.string	1,5,10,20
	.string	10,40,0,1
	.string	1,1,0,0
	.word	MSG_110F
	.word	MSG_220F
	.word	MSG_540F
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_20F
	.string	1,5,10,20

;1F, 5F, 10F, 20F ECA
;1/10F 3/20F, 7/40F
FRENCH8
	.string	1,5,10,30
	.string	10,40,0,1
	.string	1,1,0,0
	.word	MSG_110F
	.word	MSG_320F
	.word	MSG_740F
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_20F
	.string	1,5,10,20

;1F, 5F, 10F, 20F ECA
;1/5F 2/10F, 5/20F
FRENCH9
	.string	1,5,10,20
	.string	5,20,0,1
	.string	1,1,0,0
	.word	MSG_15F
	.word	MSG_210F
	.word	MSG_520F
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_20F
	.string	1,5,10,20

;1F, 5F, 10F, 20F ECA
;1/5F 3/10F, 7/20F
FRENCH10
	.string	1,5,15,30
	.string	5,30,0,1
	.string	1,1,0,0
	.word	MSG_15F
	.word	MSG_310F
	.word	MSG_720F
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_20F
	.string	1,5,10,20

;1/3X5F, 4/50F
FRENCH11
	.string	1,2,0,0
	.string	3,10,0,1
	.string	1,1,0,0
	.word	MSG_13X5F
	.word	MSG_450F
	.word	0
	.word	MSG_5F
	.word	MSG_10F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,2,0,0


;1/2X25, 2/100,
CANADA1
	.string	1,4,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12
	.word	MSG_21D
	.word	0
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,4,0,0

;1/4X25, 1/100,
CANADA2
	.string	1,4,0,0
	.string	4,0,0,1
	.string	1,1,0,0
	.word	MSG_11D
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,4,0,0

;1/4X25, 1/100, 3/2X100
CANADA3
	.string	1,4,0,0
	.string	4,8,0,1
	.string	1,1,0,0
	.word	MSG_11D
	.word	MSG_32D
	.word	0
	.word	MSG_25C
	.word	MSG_100D
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,4,0,0


;1/3X1F, 2/5F
SWISS1
	.string	1,6,0,0
	.string	3,0,0,1
	.string	1,1,0,0
	.word	MSG_13F
	.word	MSG_25F
	.word	0
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/1F, 5/5F
SWISS2
	.string	1,5,0,0
	.string	1,0,0,1
	.string	1,1,0,0
	.word	MSG_11F
	.word	MSG_55F
	.word	0
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/2X1F, 3/5F
SWISS3
	.string	1,6,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12F
	.word	MSG_35F
	.word	0
	.word	MSG_1F
	.word	MSG_5F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0


;1/500LIRE
ITALY1
	.string	1,1,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_1500L
	.word	0
	.word	0
	.word	MSG_500L
	.word	MSG_500L
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,1,0,0

;1/2X500LIRE
ITALY2
	.string	1,1,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12X500L
	.word	0
	.word	0
	.word	MSG_500L
	.word	MSG_500L
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,1,0,0

;1/4X500LIRE
ITALY3
	.string	1,1,0,0
	.string	4,0,0,1
	.string	1,1,0,0
	.word	MSG_14X500L
	.word	0
	.word	0
	.word	MSG_500L
	.word	MSG_500L
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,1,0,0


;2/100P, 1/50P, ECA
UK1
	.string	10,5,2,1
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_150P
	.word	0
	.word	0
	.word	MSG_100P
	.word	MSG_50P
	.word	MSG_20P
	.word	MSG_10P
	.string	10,5,2,1

;1/100P, 1/2X50P, ECA
UK2
	.string	10,5,2,1
	.string	10,0,0,1
	.string	1,1,0,0
	.word	MSG_1100P
	.word	0
	.word	0
	.word	MSG_100P
	.word	MSG_50P
	.word	MSG_20P
	.word	MSG_10P
	.string	10,5,2,1

;1/3X20P, 1/50P
UK3
	.string	1,3,0,0
	.string	3,0,0,1
	.string	1,1,0,0
	.word	MSG_13X20P
	.word	MSG_150P
	.word	0
	.word	MSG_20P
	.word	MSG_50P
	.word	MSG_NULL
	.word	MSG_NULL
	.string	2,5,0,0


;1/100PESETA, 6/500PESETA
SPAIN1
	.string	1,5,0,0
	.string	1,5,0,1
	.string	1,0,0,0
	.word	MSG_1100PESETA
	.word	MSG_6500PESETA
	.word	0
	.word	MSG_100P
	.word	MSG_500P
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;3/2X100PESETA, 7/500PESETA
SPAIN2
	.string	3,14,0,0
	.string	2,0,0,1
	.string	1,0,0,0
	.word	MSG_32X100PESETA
	.word	MSG_7500PESETA
	.word	0
	.word	MSG_100P
	.word	MSG_500P
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;100PESETA, 5/500PESETA
SPAIN3
	.string	1,5,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_1100PESETA
	.word	MSG_5500PESETA
	.word	0
	.word	MSG_100P
	.word	MSG_500P
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/2X100PESETA, 3/500PESETA
SPAIN4
	.string	1,6,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12X100PESETA
	.word	MSG_3500PESETA
	.word	0
	.word	MSG_100P
	.word	MSG_500P
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;2/100PESETA, 10/500PESETA
SPAIN5
	.string	2,10,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_2100PESETA
	.word	MSG_10500PESETA
	.word	0
	.word	MSG_100P
	.word	MSG_500P
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,5,0,0

;1/100PESETA ECA
SPAIN6
	.string	1,4,8,20
	.string	4,0,0,1
	.string	1,1,0,0
	.word	MSG_1100PESETA
	.word	0
	.word	0
	.word	MSG_25P
	.word	MSG_100P
	.word	MSG_200P
	.word	MSG_500P
	.string	1,4,8,20


;1/5X20, 1/100
AUSTRALIA1
	.string 1,5,0,0
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_15X20C
	.word	MSG_11D
	.word	0
	.word	MSG_20C
	.word	MSG_100D
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,5,0,0

;1/10X20, 1/2X100
AUSTRALIA2
	.string 1,5,0,0
	.string	10,0,0,1
	.string	1,1,0,0
	.word	MSG_110X20C
	.word	MSG_12D
	.word	0
	.word	MSG_20C
	.word	MSG_100D
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,5,0,0

;1/2X100
AUSTRALIA3
	.string 1,2,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12D
	.word	0
	.word	0
	.word	MSG_100D
	.word	MSG_200D
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,2,0,0

;1/3X100
AUSTRALIA4
	.string 1,2,0,0
	.string	3,0,0,1
	.string	1,1,0,0
	.word	MSG_13D
	.word	0
	.word	0
	.word	MSG_100D
	.word	MSG_200D
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,2,0,0


;1/100
JAPAN1
	.string 1,1,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_11
	.word	0
	.word	0
	.word	MSG_100YEN
	.word	MSG_100YEN
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,1,0,0

;1/2X100
JAPAN2
	.string 1,1,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12
	.word	0
	.word	0
	.word	MSG_100YEN
	.word	MSG_100YEN
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,1,0,0

;1/100, 3/500
JAPAN3
	.string 1,3,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_1100YEN
	.word	MSG_3500YEN
	.word	0
	.word	MSG_100YEN
	.word	MSG_500YEN
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,5,0,0


;1/NT10 
TAIWAN1
	.string 1,1,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_1NT10
	.word	0
	.word	0
	.word	MSG_NT10
	.word	MSG_NT10
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,1,0,0

;1/2XUS25 
TAIWAN2
	.string 1,1,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12
	.word	0
	.word	0
	.word	MSG_25C
	.word	MSG_25C
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,1,0,0

;2/1 1 COIN = 2 PLAYS 
TAIWAN3
	.string 2,2,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_21
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,1,0,0


;1/5SCHIL, 2/10SCHIL
AUSTRIA1
	.string 1,2,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_15SCHIL
	.word	MSG_210SCHIL
	.word	0
	.word	MSG_5SCHIL
	.word	MSG_10SCHIL
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,2,0,0

;1/10SCHIL, 3/20SCHIL
AUSTRIA2
	.string 1,2,0,0
	.string	1,2,0,1
	.string	1,0,0,0
	.word	MSG_110SCHIL
	.word	MSG_320SCHIL
	.word	0
	.word	MSG_10SCHIL
	.word	MSG_20SCHIL
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,2,0,0

;1/2X5SCHIL, 1/10SCHIL
AUSTRIA3
	.string 1,2,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12X5SCHIL
	.word	MSG_110SCHIL
	.word	0
	.word	MSG_5SCHIL
	.word	MSG_10SCHIL
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,2,0,0

;1/2X10SCHIL, 2/30SCHIL
AUSTRIA4
	.string 1,2,0,0
	.string	2,3,0,1
	.string	1,1,0,0
	.word	MSG_12X10SCHIL
	.word	MSG_230SCHIL
	.word	0
	.word	MSG_10SCHIL
	.word	MSG_20SCHIL
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,2,0,0


;1/20F
BELGIUM1
	.string	1,1,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_120F
	.word	0
	.word	0
	.word	MSG_20F
	.word	MSG_20F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,1,0,0

;1/2X20F
BELGIUM2
	.string	1,1,0,0
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12X20F
	.word	0
	.word	0
	.word	MSG_20F
	.word	MSG_20F
	.word	MSG_NULL
	.word	MSG_NULL
	.string	1,1,0,0

;1/20FB 3/50FB ECA
BELGIUM3
	.string	1,4,10,0
	.string	4,10,0,1
	.string	1,1,0,0
	.word	MSG_120F
	.word	MSG_350F
	.word	0
	.word	MSG_5F
	.word	MSG_20F
	.word	MSG_50F
	.word	MSG_NULL
	.string	1,4,10,0


;1/5KRONA ECA
SWEDEN1
	.string 1,5,10,0
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_15KRONA
	.word	0
	.word	0
	.word	MSG_1KRONA
	.word	MSG_5KRONA
	.word	MSG_10KRONA
	.word	MSG_NULL
	.string 1,5,10,0

;1/5MARKA
FINLAND1
	.string 1,5,10,0
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_15MARKKA
	.word	0
	.word	0
	.word	MSG_1MARKKA
	.word	MSG_5MARKKA
	.word	MSG_10MARKKA
	.word	MSG_NULL
	.string 1,5,10,0

;1/2.50HFI
NETHERLAND1
	.string 1,1,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_1250HFI
	.word	0
	.word	0
	.word	MSG_250HFI
	.word	MSG_250HFI
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,1,0,0

;1/1HFI, 3/1X2.50HFI
NETHERLAND2
	.string 1,3,0,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_11HFI
	.word	MSG_3250HFI
	.word	0
	.word	MSG_1HFI
	.word	MSG_250HFI
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,3,0,0

;1/5KRONE ECA
NORWAY1
	.string 1,2,4,0
	.string	1,0,0,1
	.string	1,0,0,0
	.word	MSG_15KRONE
	.word	0
	.word	0
	.word	MSG_5KRONE
	.word	MSG_10KRONE
	.word	MSG_20KRONE
	.word	MSG_NULL
	.string 1,2,4,0

;1/5DKR ECA
DENMARK1
	.string 1,5,10,20
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_15KRONE
	.word	0
	.word	0
	.word	MSG_1KRONE
	.word	MSG_5KRONE
	.word	MSG_10KRONE
	.word	MSG_20KRONE
	.string 1,5,10,20

;1/4X20 FORINT, 2/140 FORINT
HUNGARY1
	.string 1,5,0,0
	.string	4,7,0,1
	.string	1,1,0,0
	.word	MSG_14X20FORINT
	.word	MSG_2140FORINT
	.word	0
	.word	MSG_20FORINT
	.word	MSG_100FORINT
	.word	MSG_NULL
	.word	MSG_NULL
	.string 1,5,0,0


;GENERAL COIN MODES
;1 CREDIT/1 COIN
GENERAL1
	.string	1,1,1,4
	.string	1,0,0,1
	.string	1,1,0,0
	.word	MSG_11
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;1 CREDIT/2 COINS
GENERAL2
	.string	1,1,1,4
	.string	2,0,0,1
	.string	1,1,0,0
	.word	MSG_12
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;1 CREDIT/3 COINS
GENERAL3
	.string	1,1,1,4
	.string	3,0,0,1
	.string	1,1,0,0
	.word	MSG_13
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;1 CREDIT/4 COINS
GENERAL4
	.string	1,1,1,4
	.string	4,0,0,1
	.string	1,1,0,0
	.word	MSG_14
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;1 CREDIT/5 COINS
GENERAL5
	.string	1,1,1,4
	.string	5,0,0,1
	.string	1,1,0,0
	.word	MSG_15
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;1 CREDIT/6 COINS
GENERAL6
	.string	1,1,1,4
	.string	6,0,0,1
	.string	1,1,0,0
	.word	MSG_16
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;2 CREDITS/1 COIN
GENERAL7
	.string	2,2,2,8
	.string	1,0,0,1
	.string	1,1,0,0
	.word	MSG_21
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4

;3 CREDITS/1 COIN
GENERAL8
	.string	3,3,3,12
	.string	1,0,0,1
	.string	1,1,0,0
	.word	MSG_31
	.word	0
	.word	0
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_1COIN
	.word	MSG_4COINS
	.string	1,1,1,4


;;5 COINS / 1 CREDIT, 4 COINS / 1 CREDIT
;HONGKONG1
;	.string	3,3,3,12
;	.string	1,0,0,1
;	.string	1,1,0,0
;	.word	MSG_31
;	.word	0
;	.word	0
;	.word	MSG_1COIN
;	.word	MSG_1COIN
;	.word	MSG_1COIN
;	.word	MSG_4COINS


COIN_TABLEEND



USA_OFF		.set (USA1-COIN_TABLE)/COIN_ENTRY_SIZE
GERMAN_OFF	.set (GERMAN1-COIN_TABLE)/COIN_ENTRY_SIZE
FRENCH_OFF	.set (FRENCH1-COIN_TABLE)/COIN_ENTRY_SIZE
CANADA_OFF	.set (CANADA1-COIN_TABLE)/COIN_ENTRY_SIZE
SWISS_OFF	.set (SWISS1-COIN_TABLE)/COIN_ENTRY_SIZE
ITALY_OFF	.set (ITALY1-COIN_TABLE)/COIN_ENTRY_SIZE
UK_OFF		.set (UK1-COIN_TABLE)/COIN_ENTRY_SIZE
SPAIN_OFF	.set (SPAIN1-COIN_TABLE)/COIN_ENTRY_SIZE
AUSTRALIA_OFF	.set (AUSTRALIA1-COIN_TABLE)/COIN_ENTRY_SIZE
JAPAN_OFF	.set (JAPAN1-COIN_TABLE)/COIN_ENTRY_SIZE
TAIWAN_OFF	.set (TAIWAN1-COIN_TABLE)/COIN_ENTRY_SIZE
AUSTRIA_OFF	.set (AUSTRIA1-COIN_TABLE)/COIN_ENTRY_SIZE
BELGIUM_OFF	.set (BELGIUM1-COIN_TABLE)/COIN_ENTRY_SIZE
SWEDEN_OFF	.set (SWEDEN1-COIN_TABLE)/COIN_ENTRY_SIZE
FINLAND_OFF	.set (FINLAND1-COIN_TABLE)/COIN_ENTRY_SIZE
NETHERLAND_OFF	.set (NETHERLAND1-COIN_TABLE)/COIN_ENTRY_SIZE
NORWAY_OFF 	.set (NORWAY1-COIN_TABLE)/COIN_ENTRY_SIZE
DENMARK_OFF	.set (DENMARK1-COIN_TABLE)/COIN_ENTRY_SIZE
HUNAGRY_OFF	.set (HUNGARY1-COIN_TABLE)/COIN_ENTRY_SIZE
GENERAL_OFF	.set (GENERAL1-COIN_TABLE)/COIN_ENTRY_SIZE
;HONGKONG_OFF	.set (HONGKONG1-COIN_TABLE)/COIN_ENTRY_SIZE






COUNTRY_TAB
	.word	USA_OFF		;1
	.word	GERMAN_OFF	;2
	.word	FRENCH_OFF	;3
	.word	CANADA_OFF	;4
	.word	SWISS_OFF	;5
	.word	ITALY_OFF	;6
	.word	UK_OFF		;7
	.word	SPAIN_OFF	;8
	.word	AUSTRALIA_OFF	;9
	.word	JAPAN_OFF	;10
	.word	TAIWAN_OFF	;11
	.word	AUSTRIA_OFF	;12
	.word	BELGIUM_OFF	;13
	.word	SWEDEN_OFF	;14	OTHER COUNTRYS
	.word	GENERAL_OFF	;15
;	.word	HONGKONG_OFF	;16

;The COUNTRY_DEFAULTS TABLE is used for the dip switch settings
;The COUNTRY_DEFAULTS table is needed because the COUNTRY_TAB is used for the menu system
;in diag and differs from the dipswitch settings. It also alows us to insert countrys without
;altering the dufault dip switch settings

;format OF TABLE ENTRY PER COUNTRY
;	.word	mode_offset0,mode_offset1,mode_offset2,mode_offset3
COUNTRY_DEFAULTS
	.word	USA1,USA3,USA7,USA8				;0
	.word	GERMAN1,GERMAN2,GERMAN3,GERMAN4			;1
	.word	FRENCH1,FRENCH2,FRENCH3,FRENCH4			;2
	.word	CANADA1,CANADA2,CANADA3,CANADA1			;3
	.word	SWISS1,SWISS2,SWISS3,SWISS1			;4
	.word	ITALY1,ITALY2,ITALY3,ITALY1			;5
	.word	UK1,UK2,UK3,UK1					;6
	.word	SPAIN1,SPAIN2,SPAIN3,SPAIN4			;7
	.word	AUSTRALIA1,AUSTRALIA2,AUSTRALIA3,AUSTRALIA4	;8
	.word	JAPAN1,JAPAN2,JAPAN3,JAPAN1			;9
	.word	TAIWAN1,TAIWAN2,TAIWAN3,TAIWAN1			;10
	.word	AUSTRIA1,AUSTRIA2,AUSTRIA3,AUSTRIA4		;11
	.word	BELGIUM1,BELGIUM2,BELGIUM3,BELGIUM1		;12
	.word	SWEDEN1,SWEDEN1,SWEDEN1,SWEDEN1			;13
	.word	FINLAND1,FINLAND1,FINLAND1,FINLAND1		;14
	.word	NETHERLAND1,NETHERLAND2,NETHERLAND1,NETHERLAND2	;15
	.word	NORWAY1,NORWAY1,NORWAY1,NORWAY1 		;16
	.word	DENMARK1,DENMARK1,DENMARK1,DENMARK1		;17
	.word	HUNGARY1,HUNGARY1,HUNGARY1,HUNGARY1		;18
	.word	GENERAL1,GENERAL3,GENERAL5,GENERAL7		;19
;	.word	HONGKONG1,HONGKONG2,HONGKONG3,HONGKONG1		;20
COUNTRY_DEFAULTS_END




	.text
	.END

