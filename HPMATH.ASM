******************************************************
*    TMS320C30 C COMPILER     Version 4.50
******************************************************
;	C:\BIN\ac30.exe -mr -ic:\c30tools -x -q hpmath.c e:\hpmath.if 
;	C:\BIN\opt30.exe -m -r -a -q -O2 e:\hpmath.if e:\hpmath.opt 
;	C:\BIN\cg30.exe -o -n -b -m -p -a -c -q e:\hpmath.opt hpmath.asm e:\hpmath.tmp 
	.version	30
FP	.set		AR3
	.file	"hpmath.c"

	.sym	_HPsin,_HPsin,38,2,0
	.globl	_HPsin

	.func	51
******************************************************
* FUNCTION DEF : _HPsin
******************************************************
_HPsin:
	PUSH	R4
	.sym	_x,2,6,17,32
*
* R2	assigned to parameter x
* R3	assigned to variable  sgn
* R4	assigned to variable  xn
*
	.sym	_x,2,6,4,32
	.sym	_sgn,3,6,4,32
	.sym	C$2,2,6,4,32
	.sym	C$1,4,6,4,32
	.sym	_xn,4,6,4,32
	.sym	C$3,19,4,4,32
	.line	2
	.line	4
	CMPF	0,R2
	LDFLT	-1.0,R3
	LDFGE	1.0,R3
	ABSF	R2
	.line	9
	LDP	@CONST+0
	LDF	@CONST+0,R0
	MPYF	R0,R2,R1
	ADDF	5.0e-1,R1
	FIX	R1,RC
	FLOAT	RC,R4
	.line	14
	LDI	RC,R0
	LDI	2,R1
	CALL	MOD_I30
	BZ	LL3
	NEGF	R3
LL3:
	LDF	3.140625,R0
	MPYF	R0,R4,R1
	SUBF	R1,R2,R1
	LDP	@CONST+1
	MPYF	@CONST+1,R4
	SUBF	R4,R1,R4
	.line	28
	MPYF	R4,R4,R2
	LDP	@CONST+2
	LDF	@CONST+2,R1
	MPYF	R1,R2,R0
	LDP	@CONST+3
	ADDF	@CONST+3,R0
	MPYF	R2,R0
	LDP	@CONST+4
	ADDF	@CONST+4,R0
	MPYF	R2,R0
	LDP	@CONST+5
	ADDF	@CONST+5,R0
	MPYF	R2,R0
	MPYF	R4,R0
	ADDF	R4,R0
	MPYF	R3,R0
EPI0_1:
	.line	29
	POP	R4
	RETS

	.endfunc	79,000000010H,0

	.sym	_HPcos,_HPcos,38,2,0
	.globl	_HPcos

	.func	98
******************************************************
* FUNCTION DEF : _HPcos
******************************************************
_HPcos:
	PUSH	R4
	.sym	_x,2,6,17,32
*
* R2	assigned to variable  xn
* R3	assigned to variable  x
* R4	assigned to variable  sgn
*
	.sym	C$2,2,6,4,32
	.sym	C$1,3,6,4,32
	.sym	_xn,2,6,4,32
	.sym	_x,3,6,4,32
	.sym	C$3,19,4,4,32
	.sym	_sgn,4,6,4,32
	.sym	C$4,2,6,4,32
	.line	2
	ABSF	R2,R3
	.line	16
	LDP	@CONST+6
	LDF	@CONST+6,R0
	ADDF	R0,R3,R1
	LDP	@CONST+0
	MPYF	@CONST+0,R1
	LDF	5.0e-1,R2
	ADDF	R2,R1
	FIX	R1,RC
	FLOAT	RC,R1
	SUBF	R2,R1,R2
	.line	21
	LDI	RC,R0
	LDI	2,R1
	CALL	MOD_I30
	LDFNZ	-1.0,R4
	LDFZ	1.0,R4
	LDF	3.140625,R0
	MPYF	R0,R2,R1
	SUBF	R1,R3
	LDP	@CONST+1
	MPYF	@CONST+1,R2
	SUBF	R2,R3
	.line	34
	MPYF	R3,R3,R2
	LDP	@CONST+2
	LDF	@CONST+2,R1
	MPYF	R1,R2,R0
	LDP	@CONST+3
	ADDF	@CONST+3,R0
	MPYF	R2,R0
	LDP	@CONST+4
	ADDF	@CONST+4,R0
	MPYF	R2,R0
	LDP	@CONST+5
	ADDF	@CONST+5,R0
	MPYF	R2,R0
	MPYF	R3,R0
	ADDF	R3,R0
	MPYF	R4,R0
EPI0_2:
	.line	35
	POP	R4
	RETS

	.endfunc	132,000000010H,0
******************************************************
* DEFINE CONSTANTS                                   *
******************************************************
	.sect	".const"
CONST:
	.float	3.1830988618379067154e-1;0
	.float	9.67653589793e-4 ;1
	.float	2.601903036e-6   ;2
	.float	-1.980741872e-4  ;3
	.float	8.333025139e-3   ;4
	.float	-1.666665668e-1  ;5
	.float	1.57079632679489661923;6
******************************************************
* UNDEFINED REFERENCES                               *
******************************************************
	.globl	MOD_I30
	.end
