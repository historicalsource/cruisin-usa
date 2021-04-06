	.FILE	"OVERLAY.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	C30.EQU
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
	.include	DIRQ.EQU



*----------------------------------------------------------------------------
*When a section is loaded (from the tyco track)and the SC_ROUTINE field
*is not zero, the entry is used as an index, and executed from this table.
*
*Note that the call is made not when loading, but when the point has been
*hit.
*
*PARAMETERS
*	AR0	ROUTINE INDEX
*
*CLOBBERS	AR0
*
SECTION_ROUTINE:
	CMPI	0,AR0
	RETSEQ
	ADDI	@ROUTINE_TABLEI,AR0
	LDI	*AR0,AR0
	CALLU	AR0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
ROUTINE_TABLEI	.word	ROUTINE_TABLE
ROUTINE_TABLE:					;routine
	.word	0				;0 none leave blank
	.word	CHECKPOINT_HIT			;1
	.word	WATERON				;2
	.word	WATEROFF			;3
	.word	SET_BGNDCOL2BROWN		;4
	.word	TURNOFF_INFINITY		;5
	.word	TURNON_INFINITY			;6
	.word	RR_UNFREEZE			;7
	.word	RAILPRIME			;8
	.word	HELISTART			;9
	.word	HELIEND				;10
	.word	BOFFNC				;11
	.word	TOWER_PAL_LD			;12
	.word	TOWER_PAL_RESTORE		;13
	.word	TUNNEL_ON			;14
	.word	TUNNEL_OFF			;15
	.word	BRIDGE_ON			;16
	.word	BRIDGE_OFF			;17
	.word	CHANGE_TUNE			;18
	.word	END_OF_GAME			;19
	.word	LOOK_HOLLYWOOD			;20
	.word	LOOK_GCANYON			;21
	.word	LOOK_DEATHVALLEY		;22
	.word	LOOK_MTRUSHMORE			;23
	.word	LOOK_MIDWEST			;24
	.word	LOOK_REDWOOD			;25
	.word	LOOK_SANFRANCISCO		;26
	.word	START_SANFRAN			;27
	.word	REDWOOD_START			;28
	.word	BEACHON				;29
	.word	RAMPDOWNTRAINSND		;30
	.word	OL				;31***
	.word	BONUS1				;32
	.word	BONUS2				;33
	.word	BONUS3				;34
	.word	BONUS4				;35
	.word	BONUS5				;36
	.word	BONUS6				;37
	.word	BONUS7				;38
	.word	BONUS8				;39
	.word	BONUS9				;40
	.word	BONUS10				;41
	.word	BONUS11				;42
	.word	BONUS12				;43
	.word	BONUS13				;44
	.word	BONUS14				;45
	.if	DEBUG
	.word	OVERLOCK
	.endif

OL
OVERLOCK:
	.if	DEBUG
	BU	$
	.endif
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
	.bss	CHECKPOINT_TIME_BONUS,1


	.bss	REAL_CHECKPOINTS,1

CHECKPOINT_HIT_R:
	PUSH	R0
	PUSH	AR2
	BU	JJGH


CHECKPOINT_HIT:
	PUSH	R0
	PUSH	AR2

	INCM	@REAL_CHECKPOINTS
	CMPI	@CHECKPOINT_NUM,R0
	BLE	CPHX

JJGH
	CALL	SEND_CHECKPOINT		;not really send, but setup variables

	INCM	@CHECKPOINT_NUM

	LDI	@_countdown,R0
	ADDI	@CHECKPOINT_TIME_BONUS,R0
	STI	R0,@_countdown

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MGAME,R0
	BNE	CPHX

	SONDFX	CHECKPT

CPHX
	POP	AR2
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
WATERON:
	LDI	@_MODE,R0
	OR	MWATER,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
WATEROFF:
	LDI	@_MODE,R0
	ANDN	MWATER,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------

*----------------------------------------------------------------------------
HELISTART:
	CREATE	CHOPPER,DRONE_C|VEHICLE_T|DRNE_SIGMA
	CLRI	R0
	STI	R0,@HELI_ABORT
	RETS

HELIEND:
	LDI	1,R0
	STI	R0,@HELI_ABORT
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
RAILPRIME:
	CLRI	R0
	STI	R0,@DD_MAX_DRONES
	STI	R0,@FREEZE_IT
	RETS
RR_UNFREEZE:
	LDI	1,R0
	STI	R0,@FREEZE_IT
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
BRIDGE_OFF:	;#39
	LDI	@_MODE,R0
	ANDN	MBRIDGE,R0
	STI	R0,@_MODE
	RETS
BRIDGE_ON:	;#38
	LDI	@_MODE,R0
	OR	MBRIDGE,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
BOFFNC:	;#40
	CALL	BRIDGE_OFF
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TUNNEL_ON:	;#36
	LDI	@_MODE,R0
	OR	MINTUNNEL,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TUNNEL_OFF:
	LDI	@_MODE,R0
	ANDN	MINTUNNEL,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
START_SANFRAN:	;#35
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
BEACHON:	;#29
	LDI	@_MODE,R0
	OR	MWATER,R0
	STI	R0,@_MODE
	LDI	MAX_DRONES,R0
	STI	R0,@DD_MAX_DRONES

	LDI	60,R0
	STI	R0,@DD_SLP
	LDI	100,R0
	STI	R0,@DD_VAR
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
REDWOOD_START:	;#28
	LDF	10,R0
	STF	R0,@VAR_ROAD_KFACTOR			;pixels UNDER (overshoot)
	FLOAT	75,R0	;75
	STF	R0,@INFIN_CORRECT
	LDI	4,R0
	STI	R0,@DD_MAX_DRONES

	LDI	120,R0
	STI	R0,@DD_SLP
	LDI	120,R0
	STI	R0,@DD_VAR
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
LOOK_SANFRANCISCO:	;#26
	SONDFX	ER_SANFRANCISCO
	RETS
LOOK_REDWOOD:
	SONDFX	ER_REDWOOD
	RETS
LOOK_MIDWEST:
	SONDFX	ER_MIDWEST
	RETS
LOOK_MTRUSHMORE:
	SONDFX	ER_MTRUSHMORE
	RETS
LOOK_DEATHVALLEY:
	SONDFX	ER_DEATHVALLEY
	RETS
LOOK_GCANYON:
	SONDFX	ER_GRANDCANYON
	RETS
LOOK_HOLLYWOOD:
	SONDFX	ER_HOLLYWOOD
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
CHANGE_TUNE:
	CALL	CHANGE_STATION
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
SET_BGNDCOL2BROWN:
	CALL	CHECKPOINT_HIT
	LDIL	0984900h,R0		;want blue sky
	STI	R0,@BGNDCOLA

	LDI	1,R0
	STI	R0,@NOAERASE
	RETS

TURNOFF_INFINITY:
	LDI	@_MODE,R0
	ANDN	MINFIN,R0
	STI	R0,@_MODE
	RETS

TURNON_INFINITY:
	LDI	@_MODE,R0
	OR	MINFIN,R0
	STI	R0,@_MODE
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
TOWER_PAL_LD:		;#12
	;find the pal which tower is in
	;do a palset with the new palette

	LDI	tower_p,AR2
	CALL	PAL_FIND
	LDL	tower_bgrey,AR2
	LDI	R0,R2
	LDI	*AR2++,R3		;GET COUNT
	CALL	PAL_SET
	RETS
TOWER_PAL_RESTORE:
	PUSH	AR2
	PUSH	R2
	;not so much a restore as a validate it is set
	;
	LDI	tower_p,R0		;ONE TO OVERWRITE
	LDI	R0,R1			;WHAT TO OVERWRITE IT WITH
	CALL	PAL_OVERWRITE
	POP	R2
	POP	AR2
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
END_OF_GAME:
	LDI	1,R0
	STI	R0,@END_OF_GAMEP
	RETS
*----------------------------------------------------------------------------
	.END
