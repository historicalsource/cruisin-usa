	.FILE	"SETUPS.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
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
	.include	CORNOBJ.EQU


*----------------------------------------------------------------------------
CLEANUP_PALS:

	LDL	CORNPAL,AR2
	CALL	PAL_FIND_RAW
	BNC	DONTDEL
	
	LDL	CORNPAL,AR2
	CALL	PAL_DELETE_RAW
DONTDEL


	LDL	tunnel2_PALETTES,AR2
	CALL	dealloc_section
	LDL	tunnel_PALETTES,AR2
	CALL	dealloc_section

	LDL	thetrains_PALETTES,AR2
	CALL	dealloc_section
	LDL	deserts_PALETTES,AR2
	CALL	dealloc_section

	LDL	ggate_PALETTES,AR2
	CALL	dealloc_section
	LDL	h280_PALETTES,AR2
	CALL	dealloc_section
	LDL	bevhnred_PALETTES,AR2
	CALL	dealloc_section

	LDL	lafreeway_PALETTES,AR2
	CALL	dealloc_section
	LDL	deathvalley_PALETTES,AR2
	CALL	dealloc_section

	LDL	arizona_PALETTES,AR2
	CALL	dealloc_section
	LDL	mtrush_PALETTES,AR2
	CALL	dealloc_section

	LDL	mwest_PALETTES,AR2
	CALL	dealloc_section
	LDL	chicago_PALETTES,AR2
	CALL	dealloc_section

	LDL	appl_PALETTES,AR2
	CALL	dealloc_section
	LDL	dc_PALETTES,AR2
	CALL	dealloc_section
	LDL	dc_shared_PALETTES,AR2
	CALL	dealloc_section

	LDL	finale_PALETTES,AR2
	CALL	dealloc_section
	LDL	theheads_PALETTES,AR2
	CALL	dealloc_section


	LDL	press_PALETTES,AR2
	CALL	dealloc_section
	LDL	crace_PALETTES,AR2
	CALL	dealloc_section
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FULLSETUP_TABLEI
		.word	FULLSETUP_TABLE
		romdata
FULLSETUP_TABLE:
		.word	FULLSETUP_GGPARK
		.word	FULLSETUP_SANFRAN,FULLSETUP_H280,FULLSETUP_REDWOOD
		.word	FULLSETUP_BEVERLY,FULLSETUP_LAFREEWAY,FULLSETUP_DEATHVALLEY
		.word	FULLSETUP_ARIZONA,FULLSETUP_GCANYON,FULLSETUP_IOWA
		.word	FULLSETUP_CHICAGO,FULLSETUP_INDIANA,FULLSETUP_APPALACHIA
		.word	FULLSETUP_WASHINGTONDC
		.text


LOADSECTION_TABLEI	.word LOADSECTION_TABLE
	romdata
LOADSECTION_TABLE
	.word	LOADGGPARK,LOADSANFRAN,LOADALLH280,LOADREDWOOD,LOADBEVERLY,LOADLAFREEWAY
	.word	LOADDEATHVALLEY,LOADARIZONA,LOADGCANYON,LOADIOWA,LOADCHICAGO
	.word	LOADINDIANA,LOADAPPALACHIA,LOADWASHINGTONDC
	.text

	.include	cornobj.equ

LOADGGPARK:
	LDL	_SECggate,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECcorn,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADSANFRAN:
	CALL	LOAD_TUNNEL2
	LDL	_SECggate,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADALLH280:
	CALL	LOAD_TUNNEL2
LOADH280:
	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECh280,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADREDWOOD:
	CALL	LOADH280
	CALL	LOAD_TUNNEL
	RETS

LOADBEVERLY:
	CALL	LOADH280
	CALL	LOAD_TUNNEL
	LDL	_SECbevhnred,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADLAFREEWAY:
	CALL	LOAD_TUNNEL
	LDL	_SEClafreeway,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADDEATHVALLEY:
	CALL	LOAD_TUNNEL
	LDL	_SECdeathvalley,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECthetrains,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADARIZONA:
	CALL	LOAD_TUNNEL
	LDL	_SECarizona,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADGCANYON:	;(MOUNT RUSHMORE)
	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECmtrush,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADIOWA:
	LDL	_SECiowa_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECmwest,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADCHICAGO:

	LDL	_SECthetrains,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECiowa_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECchicago,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADINDIANA:
	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECmwest,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECmwest_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ
	RETS

LOADAPPALACHIA:
	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECmwest_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECappl,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOADWASHINGTONDC:
	LDL	_SECmwest_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECdc,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECdc_shared,AR2
	CALL	LOAD_SECTION_REQ
	RETS

LOAD_TUNNEL2:
	LDL	_SECtunnel2,AR2
	CALL	LOAD_SECTION_REQ
	LDL	tunnel2_PALETTES,AR2
	CALL	alloc_section
	RETS

WATERON:
	LDI	@_MODE,R0
	OR	MWATER,R0
	STI	R0,@_MODE
	RETS

WATEROFF:
	LDI	@_MODE,R0
	ANDN	MWATER,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_GGPARK:
	LDL	_SECggate,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECcorn,AR2
	CALL	LOAD_SECTION_REQ

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR


	LDL	ggate_PALETTES,AR2
	CALL	alloc_section

	LDL	CORNPAL,AR2
	CALL	PAL_ALLOC_RAW

	FLOAT	-15,R0
	STF	R0,@INFIN_CORRECT
	CALL	WATERON

	CALL	LEG_INIT
	LDI	1,AR0
	LDI	L_LEG1_END,AR1
	CALL	LEG_GENERATE_MAP

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FULLSETUP_SANFRAN:
	LDL	_SECggate,AR2
	CALL	LOAD_SECTION_REQ
	CALL	LOAD_TUNNEL2

	LDL	ggate_PALETTES,AR2
	CALL	alloc_section
	LDL	tunnel2_PALETTES,AR2
	CALL	alloc_section

	FLOAT	-15,R0
	STF	R0,@INFIN_CORRECT
	CALL	WATERON

	LDI	120,R0
	STI	R0,@DD_SLP
	LDI	120,R0
	STI	R0,@DD_VAR


	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	LDI	2,R0		;DISCO DUCK
	STI	R0,@TUNE_IDX

	LDL	shared_PALETTES,AR2
	CALL	dealloc_section
	LDL	shared_PALETTES,AR2
	CALL	alloc_section
	LDL	_SECshared,AR2
	CALL	LOAD_SECTION_REQ


	LDI	0,R0
	STI	R0,@CHALLENGE_RACE

	CALL	LEG_INIT
	LDI	L_LEG2_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG2_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_H280:
	CALL	LOAD_TUNNEL2
	LDL	_SECh280,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ

	LDI	3,R0		;SPAGETTI
	STI	R0,@TUNE_IDX

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE
	LDI	0,R0
	STI	R0,@NOLONG_VEHICLES

	LDL	deserts_PALETTES,AR2
	CALL	alloc_section
	LDL	h280_PALETTES,AR2
	CALL	alloc_section

	FLOAT	55,R0
	STF	R0,@INFIN_CORRECT
	LDI	@_MODE,R0
	ANDN	MWATER,R0
	STI	R0,@_MODE

	CALL	LEG_INIT
	LDI	L_LEG3_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG3_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_REDWOOD:
	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECh280,AR2
	CALL	LOAD_SECTION_REQ

	LDL	deserts_PALETTES,AR2
	CALL	alloc_section
	LDL	h280_PALETTES,AR2
	CALL	alloc_section
	LDL	_SECbevhnred,AR2
	CALL	LOAD_SECTION_REQ
	LDL	bevhnred_PALETTES,AR2
	CALL	alloc_section

	CALL	WATEROFF
	LDI	0,R0		;MONSTER SURF
	STI	R0,@TUNE_IDX

	LDI	1,R0
	STI	R0,@CHALLENGE_RACE
	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	LDI	120,R0
	STI	R0,@DD_SLP
	LDI	120,R0
	STI	R0,@DD_VAR


	FLOAT	50,R0
	STF	R0,@INFIN_CORRECT

	;load proper tunnel
	CALL	LOAD_TUNNEL

	CALL	LEG_INIT
	LDI	L_LEG4_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG4_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS

LOAD_TUNNEL:	;(ACTUAL)
	LDL	tunnel_PALETTES,AR2
	CALL	alloc_section
	LDL	_SECtunnel,AR2
	CALL	LOAD_SECTION_REQ
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_BEVERLY:
	CALL	LOAD_TUNNEL
	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECbevhnred,AR2
	CALL	LOAD_SECTION_REQ

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR


	LDL	bevhnred_PALETTES,AR2
	CALL	alloc_section
	LDL	deserts_PALETTES,AR2
	CALL	alloc_section
	CALL	WATEROFF
	LDI	5,R0		;STRAIGHT 2 4
	STI	R0,@TUNE_IDX

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE
	STI	R0,@COCONUT_COUNT

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	FLOAT	45,R0
	STF	R0,@INFIN_CORRECT

	CALL	LEG_INIT
	LDI	L_LEG5_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG5_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FULLSETUP_LAFREEWAY:
	CALL	LOAD_TUNNEL

	LDL	_SEClafreeway,AR2
	CALL	LOAD_SECTION_REQ

	CALL	WATEROFF
	LDI	2,R0		;DISCO DUCK
	STI	R0,@TUNE_IDX

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	FLOAT	35,R0
	STF	R0,@INFIN_CORRECT

	LDL	lafreeway_PALETTES,AR2
	CALL	alloc_section

	CALL	LEG_INIT
	LDI	L_LEG6_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG6_END,AR1
	CALL	LEG_GENERATE_MAP

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR


	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_DEATHVALLEY:
	LDL	_SECdeathvalley,AR2
	CALL	LOAD_SECTION_REQ

	LDL	_SECthetrains,AR2
	CALL	LOAD_SECTION_REQ
	CALL	LOAD_TUNNEL

	CALL	WATEROFF
	LDI	3,R0		;SPAGETTI
	STI	R0,@TUNE_IDX

	LDI	1,R0
	STI	R0,@CHALLENGE_RACE
	STI	R0,@NOLONG_VEHICLES

	FLOAT	55,R0
	STF	R0,@INFIN_CORRECT

	LDI	bottom2_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	bottom2_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE


;	LDL	lafreeway_PALETTES,AR2
;	CALL	dealloc_section
	LDL	deathvalley_PALETTES,AR2
	CALL	alloc_section

	LDL	thetrains_PALETTES,AR2
	CALL	alloc_section

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR


	CALL	LEG_INIT
	LDI	L_LEG7_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG7_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_ARIZONA:
	LDL	tunnel_PALETTES,AR2
	CALL	alloc_section
	CALL	WATEROFF

	LDL	deserts_PALETTES,AR2
	CALL	alloc_section
	CALL	LOAD_TUNNEL
	LDL	arizona_PALETTES,AR2
	CALL	alloc_section

	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECarizona,AR2
	CALL	LOAD_SECTION_REQ

	LDI	1,R0		;SHUFFLE DRIVE
	STI	R0,@TUNE_IDX

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	FLOAT	45,R0
	STF	R0,@INFIN_CORRECT


	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR


	CALL	LEG_INIT
	LDI	L_LEG8_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG8_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FULLSETUP_GCANYON:

	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECmtrush,AR2
	CALL	LOAD_SECTION_REQ

	CALL	WATEROFF
	LDL	deserts_PALETTES,AR2
	CALL	alloc_section
	LDL	_SECdeserts,AR2
	CALL	LOAD_SECTION_REQ

	;(MOUNT RUSHMORE)
	LDI	3,R0		;SPAGETTI
	STI	R0,@TUNE_IDX

	LDI	1,R0
	STI	R0,@CHALLENGE_RACE
	LDI	0,R0
	STI	R0,@NOLONG_VEHICLES

	FLOAT	55,R0
	STF	R0,@INFIN_CORRECT

	LDL	mtrush_PALETTES,AR2
	CALL	alloc_section


	LDI	75,R0
	STI	R0,@DD_SLP
	LDI	125,R0
	STI	R0,@DD_VAR

	CALL	LEG_INIT
	LDI	L_LEG9_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG9_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FULLSETUP_IOWA:
	CALL	WATEROFF
	LDI	7,R0		;BOGGIE
	STI	R0,@TUNE_IDX

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	FLOAT	45,R0
	STF	R0,@INFIN_CORRECT


	LDL	_SECiowa_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDL	_SECmwest,AR2
	CALL	LOAD_SECTION_REQ

	LDI	75,R0
	STI	R0,@DD_SLP
	LDI	125,R0
	STI	R0,@DD_VAR

	LDL	mwest_PALETTES,AR2
	CALL	alloc_section

	LDI	bottom_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	bottom3_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE

	LDI	bottom2_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	btomwt_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE

	CALL	LEG_INIT
	LDI	L_LEG10_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG10_END,AR1
	CALL	LEG_GENERATE_MAP

	CREATE	BUG_SPAWNER_PROC,SPAWNER_C
	CREATE	GEESE_SPAWNER,SPAWNER_C
	CREATE	DEER_SPAWNER_PROC,SPAWNER_C
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_CHICAGO:
	LDL	_SECthetrains,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECchicago,AR2
	CALL	LOAD_SECTION_REQ

	CALL	WATEROFF

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	LDI	2,R0		;DISCO DUCK
	STI	R0,@TUNE_IDX

	LDI	1,R0
	STI	R0,@CHALLENGE_RACE

	FLOAT	55,R0
	STF	R0,@INFIN_CORRECT

	LDL	thetrains_PALETTES,AR2
	CALL	alloc_section

	LDL	chicago_PALETTES,AR2
	CALL	alloc_section


	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR


	CALL	LEG_INIT
	LDI	L_LEG11_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG11_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
FULLSETUP_INDIANA:
	CALL	WATEROFF

	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ

	LDI	bottom2_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	btomwt_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE
	LDI	4,R0		;VENTURE
	STI	R0,@TUNE_IDX

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE

	LDI	1,R0
	STI	R0,@NOLONG_VEHICLES

	FLOAT	45,R0
	STF	R0,@INFIN_CORRECT

	LDL	mwest_PALETTES,AR2
	CALL	alloc_section

	LDL	_SECmwest_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ
	LDI	bottom_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	midwgras_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE

	LDL	_SECmwest,AR2
	CALL	LOAD_SECTION_REQ


	LDI	75,R0
	STI	R0,@DD_SLP
	LDI	125,R0
	STI	R0,@DD_VAR

	CALL	LEG_INIT
	LDI	L_LEG12_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG12_END,AR1
	CALL	LEG_GENERATE_MAP

	CREATE	BUG_SPAWNER_PROC,SPAWNER_C
	CREATE	GEESE_SPAWNER,SPAWNER_C
;	CREATE	DEER_SPAWNER_PROC,SPAWNER_C
	CREATE	COW_SPAWNER_PROC,SPAWNER_C

	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_APPALACHIA:
	CALL	WATEROFF

	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ
	LDI	bottom2_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	btomwt_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE

	LDL	_SECmwest_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ
	LDI	bottom_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	midwgras_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE
	LDI	5,R0		;STRAIGHT 2 4
	STI	R0,@TUNE_IDX

	LDI	1,R0
	STI	R0,@CHALLENGE_RACE
	LDI	0,R0
	STI	R0,@NOLONG_VEHICLES


	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR

	FLOAT	85,R0
	STF	R0,@INFIN_CORRECT

	LDL	appl_PALETTES,AR2
	CALL	alloc_section

	LDL	_SECappl,AR2
	CALL	LOAD_SECTION_REQ

	CALL	LEG_INIT
	LDI	L_LEG13_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG13_END,AR1
	CALL	LEG_GENERATE_MAP
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
FULLSETUP_WASHINGTONDC:
	CALL	WATEROFF

	LDL	_SECmwest_bottom,AR2	;in reality it just overwrites 'BOTTOM.GTM'
	CALL	LOAD_SECTION_REQ
	LDI	bottom_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	midwgras_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE


	LDL	_SECiowa_b2,AR2		;in reality it just overwrites 'BOTTOM2.GTM'
	CALL	LOAD_SECTION_REQ
	LDI	bottom2_gtmp_p,R0	;ONE TO OVERWRITE
	LDI	btomwt_gtmp_p,R1	;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE
	LDI	2,R0			;DISCO DUCK
	STI	R0,@TUNE_IDX

	LDI	0,R0
	STI	R0,@CHALLENGE_RACE
	STI	R0,@NOLONG_VEHICLES

	FLOAT	45,R0
	STF	R0,@INFIN_CORRECT

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR

	LDL	dc_PALETTES,AR2
	CALL	alloc_section
	LDL	dc_shared_PALETTES,AR2
	CALL	alloc_section

	LDL	_SECdc_shared,AR2
	CALL	LOAD_SECTION_REQ
	LDL	_SECdc,AR2
	CALL	LOAD_SECTION_REQ


	CALL	LEG_INIT
	LDI	L_LEG14_BEGIN,AR0
	LS	8,AR0
	STI	AR0,@FINISH_LINE
	RS	8,AR0
	LDI	L_LEG14_END,AR1
	CALL	LEG_GENERATE_MAP

	RETS
*----------------------------------------------------------------------------
	.END

