	.FILE	"MATH.ASM"
*----------------------------------------------------------------------------
*MATH ROUTINES
*
*COPYRIGHT (C) 1994 BY TV GAMES,INC.
*ALL RIGHTS RESERVED
*
*See also:	ROUTS.ASM	Divide,Invert,Modulus
*		HPMATH.C	higher precision functions
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
	.include	DIRQ.EQU

	.text
*----------------------------------------------------------------------------
*	float	COSI(float theta)
*	float	SINE(float theta)
*COSINE FUNCTION
*
*PARAMETERS
*	R2	VALUE IN RADIANS 0-INFINITY
*	R0	RETURN VALUE
*
_COSI:	
	LDF	R2,R0
	ADDF	@HALFPII,R0	;offset for COS
	B	SINE0
*
*SINE FUNCTION
*
*PARAMETERS
*	R2	VALUE IN RADIANS 0-INFINITY
*	R0	RETURN VALUE
*
_SINE:
	LDF	R2,R0

SINE0	PUSH	AR0
	BGE	NOTNEG

	NEGF	R0		;fix negative case
	ADDF	@PII,R0

NOTNEG	MPYF	@FORMULA,R0
	ADDF	0.5,R0		;ROUND THE SUCKER
	FIX	R0		;get a raw index
	AND	3FFh,R0
	CMPI	512,R0
	BLT	ALLOK

	SUBI	512,R0
	CMPI	256,R0
	BLT	PERFECT2

	SUBI	512,R0
	NEGI	R0,R0

PERFECT2
	ADDI	@SINTABLEI,R0
	LDI	R0,AR0
	NEGF	*AR0,R0
	POP	AR0
	RETS

ALLOK
	CMPI	256,R0
	BLT	PERFECT

	SUBI	512,R0
	NEGI	R0,R0

PERFECT	ADDI	@SINTABLEI,R0
	LDI	R0,AR0
	LDF	*AR0,R0
	POP	AR0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
	.sect	"THEDATA"
SINTABLE	;257 entries
	.float	0.000000,0.006136,0.012272,0.018407,0.024541,0.030675,0.036807,0.042938
	.float	0.049068,0.055195,0.061321,0.067444,0.073565,0.079682,0.085797,0.091909
	.float	0.098017,0.104122,0.110222,0.116319,0.122411,0.128498,0.134581,0.140658
	.float	0.146730,0.152797,0.158858,0.164913,0.170962,0.177004,0.183040,0.189069
	.float	0.195090,0.201105,0.207111,0.213110,0.219101,0.225084,0.231058,0.237024
	.float	0.242980,0.248928,0.254866,0.260794,0.266713,0.272621,0.278520,0.284408
	.float	0.290285,0.296151,0.302006,0.307850,0.313682,0.319502,0.325310,0.331106
	.float	0.336890,0.342661,0.348419,0.354163,0.359895,0.365613,0.371317,0.377007
	.float	0.382683,0.388345,0.393992,0.399624,0.405241,0.410843,0.416429,0.422000
	.float	0.427555,0.433094,0.438616,0.444122,0.449611,0.455083,0.460538,0.465976
	.float	0.471396,0.476799,0.482183,0.487550,0.492898,0.498227,0.503538,0.508830
	.float	0.514102,0.519356,0.524589,0.529803,0.534997,0.540171,0.545325,0.550458
	.float	0.555570,0.560661,0.565732,0.570781,0.575808,0.580814,0.585798,0.590760
	.float	0.595699,0.600616,0.605511,0.610383,0.615232,0.620057,0.624860,0.629638
	.float	0.634393,0.639125,0.643832,0.648515,0.653173,0.657807,0.662416,0.667000
	.float	0.671559,0.676093,0.680601,0.685084,0.689541,0.693972,0.698376,0.702755
	.float	0.707107,0.711432,0.715731,0.720003,0.724247,0.728465,0.732655,0.736817
	.float	0.740951,0.745058,0.749137,0.753187,0.757209,0.761203,0.765168,0.769104
	.float	0.773011,0.776889,0.780738,0.784557,0.788347,0.792107,0.795837,0.799538
	.float	0.803208,0.806848,0.810458,0.814037,0.817585,0.821103,0.824590,0.828046
	.float	0.831470,0.834863,0.838225,0.841555,0.844854,0.848121,0.851356,0.854559
	.float	0.857729,0.860867,0.863973,0.867047,0.870088,0.873096,0.876071,0.879013
	.float	0.881922,0.884798,0.887640,0.890449,0.893225,0.895967,0.898675,0.901349
	.float	0.903990,0.906596,0.909169,0.911707,0.914210,0.916680,0.919114,0.921515
	.float	0.923880,0.926211,0.928507,0.930767,0.932993,0.935184,0.937340,0.939460
	.float	0.941545,0.943594,0.945608,0.947586,0.949529,0.951436,0.953307,0.955142
	.float	0.956941,0.958704,0.960431,0.962122,0.963777,0.965395,0.966977,0.968523
	.float	0.970032,0.971504,0.972940,0.974340,0.975703,0.977029,0.978318,0.979570
	.float	0.980786,0.981964,0.983106,0.984210,0.985278,0.986308,0.987302,0.988258
	.float	0.989177,0.990059,0.990903,0.991710,0.992480,0.993212,0.993907,0.994565
	.float	0.995185,0.995768,0.996313,0.996821,0.997291,0.997723,0.998118,0.998476
	.float	0.998796,0.999078,0.999322,0.999529,0.999699,0.999831,0.999925,0.999981
	.float	1.0
	.text

FORMULA	.float	162.9746617		;256/(PI/2)

SINTABLEI	.word	SINTABLE
HALFPII	.float	HALFPI
PII	.float	PI
TWOPII	.float	TWOPI
INVFORM	.float	0.012265625	;1/FORMULA
*----------------------------------------------------------------------------



RADFORM		.float	10430.37835	;65535/(2PI)
RADFORMI	.float	0.000095873	;1/(65535/(2PI))


*----------------------------------------------------------------------------
*PARAMETERS
*	R2	RADIANS
*OUTPUT
*	R2	IN RANGE -PI TO +PI
*	N,Z BITS SET FOR R2
*
NORMITS:
	MPYF	@RADFORM,R2
	FIX	R2
	LS	16,R2
	RS	16,R2
	CMPI	7FFFH,R2
	BLT	NMS1
	ADDI	8000H,R2
	ADDI	8000H,R2
NMS1
	FLOAT	R2
	MPYF	@RADFORMI,R2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PARAMETERS
*	R2	RADIANS
*OUTPUT
*	R2	IN RANGE 0 TO 2PI
*
NORMIT:
	MPYF	@RADFORM,R2
	FIX	R2
	LS	16,R2
	RS	16,R2
	FLOAT	R2
	MPYF	@RADFORMI,R2
NORMCHKL
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*ARCTANF - GET ARCTAN ( R3/R2) IN RADIANS
*float	arctanf(float x,float y)  <- not true C style
*
*PARAMETERS
*	R2	X (float)
*	R3	Y (float)
*RETURNS
*	R0	RADIANS (FLOAT)
*
ARCTANF:
_arctanf
	PUSH	R1
	PUSHF	R1
	PUSH	R4
	PUSH	AR0

	;GET QUADRANT 
	LDI	0,R1
	LDF	R2,R2
	LDIN	2,R1		;GET SIGN BITS
	LDI	0,R4
	LDF	R3,R3	
	LDIN	4,R4
	ADDI	R1,R4

	;CHECK Y>X
	ABSF	R2,R0
	ABSF	R3,R1
	CMPF	R0,R1
	BLT	ATF0

	BD	AT1
	LDF	R2,R0
	LDF	R3,R1
	ADDI 	1,R4 		;R4 = OCTANT
	;---->BD	AT1
ATF0
	LDF	R2,R1
	LDF	R3,R0

AT1
	CALL	DIV_F
	ABSF	R0
	LDF	128.0,R1
	MPYF	R1,R0
	FIX	R0,AR0

	ADDI	@ATTABV,AR0
	LDF	*AR0,R0
	LSH	1,R4

	LDI	@OFFTABV,AR0
	ADDI	R4,AR0
	MPYF	*AR0++,R0
	ADDF	*AR0,R0

	POP	AR0
	POP	R4
      	POPF	R1
      	POP	R1
	RETS





ATTABV	.word	ATTAB
OFFTABV	.word	ATOFFTAB
*
*OFFSET TABLE
*OFFSET, MULTIPLIER
*
	.sect	"THEDATA"
ATOFFTAB
	.float	1		;0-45
	.float	0		
	.float	-1		;45-90
	.float	1.5707
	.float	-1		;135-180
	.float	3.1416		
	.float	1		;90-135
	.float	1.5707
	.float	-1		;315-360
	.float	6.2831	       	
	.float	1		;270-315
	.float	4.7123		
	.float	1		;180-225
	.float	3.1416	      	
	.float	-1		;225-270
	.float	4.7123		

*
*ARCTAN TABLE 0-45
*
ATTAB
	.float	0.000000,0.007812,0.015624,0.023433,0.031240,0.039043,0.046841
	.float	0.054633,0.062419,0.070197,0.077967,0.085727,0.093477,0.101215
	.float	0.108942,0.116655,0.124355,0.132040,0.139709,0.147361,0.154997
	.float	0.162614,0.170212,0.177790,0.185348,0.192884,0.200399,0.207890
	.float	0.215358,0.222801,0.230220,0.237612,0.244979,0.252318,0.259630
	.float	0.266913,0.274167,0.281392,0.288587,0.295752,0.302885,0.309986
	.float	0.317056,0.324092,0.331096,0.338066,0.345002,0.351904,0.358771
	.float	0.365602,0.372398,0.379159,0.385883,0.392570,0.399221,0.405834
	.float	0.412410,0.418949,0.425450,0.431912,0.438337,0.444722,0.451070
	.float	0.457378,0.463648,0.469878,0.476069,0.482221,0.488334,0.494407
	.float	0.500441,0.506435,0.512389,0.518304,0.524180,0.530015,0.535811
	.float	0.541568,0.547284,0.552962,0.558599,0.564198,0.569756,0.575276
	.float	0.580756,0.586198,0.591600,0.596963,0.602287,0.607573,0.612820
	.float	0.618029,0.623199,0.628332,0.633426,0.638482,0.643501,0.648482
	.float	0.653426,0.658333,0.663203,0.668036,0.672833,0.677593,0.682317
	.float	0.687005,0.691657,0.696273,0.700854,0.705400,0.709912,0.714388
	.float	0.718830,0.723238,0.727611,0.731951,0.736257,0.740530,0.744770
	.float	0.748977,0.753151,0.757293,0.761403,0.765480,0.769526,0.773541
	.float	0.777524,0.781477,0.785398
	.text
*----------------------------------------------------------------------------


		fbss	LOCTEMPER_MAT2,12
LOCTEMPER_MAT2I	.word	LOCTEMPER_MAT2

*----------------------------------------------------------------------------
*FIND MATRIX
*
*PARAMETERS
*	AR2	DESTINATION 3X3
*	R2	SOURCE RADIANS 1X3
*
FIND_MATRIX:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSHF	R0
	PUSHF	R1
	PUSHF	R2
	PUSH	AR1
	PUSH	AR2
	PUSH	AR3

	;GET SINES AND COSINES
	LDI	@LOCTEMPER_MAT2I,AR1
	LDI	R2,AR3

	LDI	2,RC
	RPTB	FM1

	LDF	*AR3++,R2
	CALL	_SINE
	STF	R0,*+AR1(3)
	CALL	_COSI
FM1	STF	R0,*AR1++

	NOP	*--AR1(2)			;CENTER COSINE INDEX
	LDI	AR1,AR3
	ADDI	3,AR3				;CENTER SINE INDEX
	MPYF	*+AR1(1),*+AR1(0),R0		;CZ*CY
	STF	R0,*AR2++		 	;A(0,0)=CZ*CY
	MPYF	*+AR3(1),*+AR1(0),R0		;SZ*CY
	NEGF	*+AR3(0),R2			;-SY
 ||	STF	R0,*AR2++			;A(0,1)=SZ*CY
	MPYF	*-AR3(1),*+AR3(0),R0		;SX*SY
	MPYF	*+AR1(1),R0,R1			;SX*SY*CZ
 ||	STF	R2,*AR2++			;A(0,2)=-SY
	MPYF	*-AR1(1),*+AR3(1),R2		;CX*SZ
	SUBF	R2,R1
	MPYF	*+AR3(1),R0,R0			;SZ*(SX*SY)
 ||	STF	R1,*AR2++			;A(1,0)=SX*SY*SZ-CX*SZ
	MPYF	*-AR1(1),*+AR1(1),R1		;CX*CZ
	ADDF	R1,R0
	STF	R0,*AR2++			;A(1,1)= SX*SY*SZ+CX*CZ
	MPYF	*-AR3(1),*+AR1(0),R0	
	MPYF	*+AR3(0),R1,R1			;SY*(CX*CZ)
 ||	STF	R0,*AR2++			;A(1,2)= SX*CY
	MPYF	*-AR3(1),*+AR3(1),R0		;SX*SZ
	ADDF	R1,R0
	MPYF	*+AR3(0),R2,R2
 ||	STF	R0,*AR2++			;A(2,0)= CX*SY*CZ+SX*SZ
	MPYF	*-AR3(1),*+AR1(1),R0
	MPYF	*-AR1(1),*+AR1(0),R1		;CX*CY
 ||	SUBF	R0,R2				
	STF	R2,*AR2++			;A(2,1)= CX*SY*SZ-SX*CZ
	STF	R1,*AR2--(8)			;A(2,2)= CX*CY
	POP	AR3
	POP	AR2
	POP	AR1
	POPF	R3
	POPF	R2
	POPF	R1
	POP	R3
	POP	R2
	POP	R1
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*	    1  0  0
* Xrot = {  0  c  s }
*	    0 -s  c
*
*PARAMETERS
*	AR2	DESTINATION 3X3 MATRIX
*	R2	SOURCE RADIANS 
*
FIND_XMATRIX:
	PUSH	R0
	PUSHF	R0
	CALL	_COSI
	STF	R0,*+AR2(A11)
	STF	R0,*+AR2(A22)
	CALL	_SINE
	STF	R0,*+AR2(A12)
	NEGF	R0
	STF	R0,*+AR2(A21)
	LDF	1,R0
	STF	R0,*+AR2(A00)
	CLRF	R0
	STF	R0,*+AR2(A01)
	STF	R0,*+AR2(A02)
	STF	R0,*+AR2(A10)
	STF	R0,*+AR2(A20)
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*	    c  0 -s
* Yrot = {  0  1  0 }
*	    s  0  c
*
*PARAMETERS
*	AR2	DESTINATION 3X3 MATRIX
*	R2	SOURCE RADIANS 
*
FIND_YMATRIX:
_find_Ymatrix:
	PUSH	R0
	PUSHF	R0
	CALL	_COSI
	STF	R0,*+AR2(A00)
	STF	R0,*+AR2(A22)
	CALL	_SINE
	STF	R0,*+AR2(A20)
	NEGF	R0
	STF	R0,*+AR2(A02)
	LDF	1,R0
	STF	R0,*+AR2(A11)
	CLRF	R0
	STF	R0,*+AR2(A01)
	STF	R0,*+AR2(A10)
	STF	R0,*+AR2(A12)
	STF	R0,*+AR2(A21)
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*	    c  0 -s
* Yrot = {  0  1  0 }
*	    s  0  c
*
*PARAMETERS
*	AR2	DESTINATION 3X3 MATRIX
*	R2	SOURCE RADIANS 
*
HPFIND_YMATRIX:
	PUSH	R0
	PUSHF	R0
	PUSH	R1
	PUSHF	R1
	PUSH	R2
	PUSHF	R2
	PUSH	R3
	PUSHF	R3
	PUSH	R4
	PUSHF	R4


	PUSH	R2
	PUSHF	R2

	CALL	_HPcos
	STF	R0,*+AR2(A00)
	STF	R0,*+AR2(A22)

	POPF	R2
	POP	R2
	CALL	_HPsin
	STF	R0,*+AR2(A20)
	NEGF	R0
	STF	R0,*+AR2(A02)
	LDF	1,R0
	STF	R0,*+AR2(A11)
	CLRF	R0
	STF	R0,*+AR2(A01)
	STF	R0,*+AR2(A10)
	STF	R0,*+AR2(A12)
	STF	R0,*+AR2(A21)

	POPF	R4
	POP	R4
	POPF	R3
	POP	R3
	POPF	R2
	POP	R2
	POPF	R1
	POP	R1
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
* 	    c s 0
* Zrot = { -s c 0 }
* 	    0 0 1
*
*PARAMETERS
*	AR2	DESTINATION 3X3 MATRIX
*	R2	SOURCE RADIANS 
*
FIND_ZMATRIX:
	PUSH	R0
	PUSHF	R0
	CALL	_COSI
	STF	R0,*+AR2(A00)
	STF	R0,*+AR2(A11)
	CALL	_SINE
	STF	R0,*+AR2(A01)
	NEGF	R0
	STF	R0,*+AR2(A10)
	LDF	1,R0
	STF	R0,*+AR2(A22)
	CLRF	R0
	STF	R0,*+AR2(A02)
	STF	R0,*+AR2(A12)
	STF	R0,*+AR2(A20)
	STF	R0,*+AR2(A21)
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*INITIALIZE MATRIX TO IDENTITY
*
*PARAMETERS
*	AR0	POINTER TO MATRIX
*
INITMAT:
	POP	BK			;RETURN ADDRESS
	PUSH	R0
	PUSHF	R0
	LDF	1.0,R0
	STF	R0,*AR0
	STF	R0,*+AR0(4)
	STF	R0,*+AR0(8)
	LDF	0,R0
	STF	R0,*+AR0(1)
	STF	R0,*+AR0(2)
	STF	R0,*+AR0(3)
	STF	R0,*+AR0(5)
	STF	R0,*+AR0(6)
	BUD	BK
	STF	R0,*+AR0(7)
	POPF	R0
	POP	R0
	;---->	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*float	vectlen(VECTOR *);
*
*PARAMETERS
*	AR2	PTS TO VECTOR
*RETURNS
*	R0	LENGTH OF VECTOR
*CLOBBERS
*	R1,R2
*
VECTLEN:
	LDF	*AR2++,R2
	MPYF	R2,R2
	LDF	*AR2++,R1
	MPYF	R1,R1
	ADDF	R1,R2

	BUD	SQRT		;fall into SQRT
	LDF	*AR2--(2),R1
	MPYF	R1,R1
	ADDF	R1,R2
	;---->BU NOW INTO SQRT routine
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*void	cpymat(MATRIX *dst,MATRIX *src);
*
*PARAMETERS
*	AR2	DEST MATRIX
*	R2	SOURCE MATRIX
*
CPYMAT:
	PUSH	AR0
	PUSH	R0
	PUSHF	R0
	LDI	R2,AR0
	LDF	*AR0++,R0
	RPTS	7
	LDF	*AR0++,R0
 ||	STF	R0,*AR2++
	STF	R0,*AR2--(8)
	POPF	R0
	POP	R0
	POP	AR0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*void	cpyimat(MATRIX *d,MATRIX *s)
*
*
*PARAMETERS
*	AR2	DEST
*	R2	SOURCE
*RETURNS
*	AR2	INVERSE MATRIX (ROWS & COLUMNS XCHNGED)
*
*WARNING SOURCE CANNOT BE SAME AS DEST
CPYIMAT:
	PUSH	R0
	PUSHF	R0
	PUSH	AR0
	LDI	R2,AR0

	LDF	*AR0++(2),R0   	;0->0
	LDF	*+AR0(1),R0	;3->1
 ||	STF	R0,*AR2++
	STF	R0,*AR2++

	LDF	*+AR0(4),R0	;6->2
	LDF	*-AR0(1),R0	;1->3
 ||	STF	R0,*AR2++
	STF	R0,*AR2++

	LDF	*+AR0(2),R0	;4->4
	STF	R0,*AR2++

	LDF	*+AR0(5),R0	;7->5
	LDF	*+AR0(0),R0	;2->6
 ||	STF	R0,*AR2++
	STF	R0,*AR2++

	LDF	*+AR0(3),R0	;5->7
	STF	R0,*AR2++
	LDF	*+AR0(6),R0	;8->8
	STF	R0,*AR2--(8)

	POP	AR0
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CLEARS VECTOR A and RETURNS POINTER TO IT IN AR2
*
CLR_VECTORA:
	PUSH	R0
	PUSHF	R0
	LDI	@VECTORAI,AR2
	CLRF	R0
	STF	R0,*AR2
	STF	R0,*+AR2(1)
	STF	R0,*+AR2(2)
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*void	matrix_mul(VECTOR *src,MATRIX *m3x3,VECTOR *dst)
*
*PARAMETERS
*	AR2	SRC 1x3
*	R2	SRC 3x3
*	R3	DST 1x3
*RETURNS
*	*R3 modified, all regs saved
*
*NOTE SRC 1x3 and DST 1x3 may be equal
*
MATRIX_MUL:
	PUSH	R0
	PUSHF	R0
	PUSH	AR1
	LDI	R2,AR1	    		;AR1 IS 3X3 MATRIX
	PUSH	R2
	PUSHF	R2

	MPYF	*AR2++,*AR1++,R0
	MPYF	*AR2,*AR1++,R2
	MPYF	*+AR2(1),*AR1++,R0
 || 	ADDF	R0,R2

	MPYF	*-AR2(1),*AR1++,R0
 ||	ADDF	R0,R2
	PUSHF	R2
	MPYF	*AR2,*AR1++,R2
	MPYF	*+AR2(1),*AR1++,R0
 || 	ADDF	R0,R2

	MPYF	*-AR2(1),*AR1++,R0
 ||	ADDF	R0,R2
	PUSHF	R2
	MPYF	*+AR2(1),*+AR1(1),R2
	MPYF	*AR2--(1),*AR1,R0
 || 	ADDF	R0,R2

	LDI	R3,AR1
	ADDF	R2,R0
	POPF	R2
	STF	R0,*+AR1(2)

	POPF	R0
	STF	R0,*AR1
 ||	STF	R2,*+AR1(1)

	POPF	R2
	POP	R2
	POP	AR1
	POPF	R0
	POP	R0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*void	normalize(VECTOR *V)
NORMALIZE:
	PUSH	R0
	PUSH	R1
	PUSHF	R0
	PUSHF	R1

	CALL	VECTLEN
	CALL	INV_F30

	MPYF	*AR2,R0,R1
	STF	R1,*AR2++
	MPYF	*AR2,R0,R1
	STF	R1,*AR2++
	MPYF	*AR2,R0,R1
	STF	R1,*AR2--(2)

	POPF	R1
	POPF	R0
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*NORMAT		NORMALIZE MATRIX
*
*PARAMETERS
*	AR2	POINTS TO MATRIX
*
*AR0,AR1,R0,R1,R2 TRASHED
*
NORMAT:

	;NORMALIZE ROWS
	LDI	2,RC
	RPTB	NORMROW

	;GET LENGTH
	LDF	*AR2++(3),R2
	MPYF	R2,R2
	LDF	*AR2++(3),R1
	MPYF	R1,R1
	ADDF	R1,R2

	LDF	*AR2--(6),R1
	MPYF	R1,R1
	ADDF	R1,R2
	CALL	SQRT	 	;sqrt(R2)-->R0
	CALL	INV_F30		;INV(R0)-->R0

	MPYF	*AR2,R0,R1
	STF	R1,*AR2++(3)
	MPYF	*AR2,R0,R1
	STF	R1,*AR2++(3)
	MPYF	*AR2,R0,R1
NORMROW	STF	R1,*AR2--(5)

	NOP	*AR2--(3)	;RESTORE AR2 MATRIX POINTER

	;NORMALIZE COLUMNS
	CALL	NORMALIZE
	NOP	*AR2++(3)
	CALL	NORMALIZE
	NOP	*AR2++(3)
	CALL	NORMALIZE
	NOP	*AR2--(6)	;RESTORE AR2
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*void	gen_normal(VECTOR *A,VECTOR *B,VECTOR *C,VECTOR *N)
*
*PARAMETERS
*	AR2	PTS TO PTRA,PTRB,PTRC
*	AR0	PTS TO NORMAL VECTOR TO RETURN
*
*CLOBBERS
*	R0-R7,AR2
*
GEN_NORMAL:
	PUSH	AR0
	LDI	*+AR2(1),AR0		;B
	LDI	*+AR2(2),R3		;C
	LDI	*AR2,AR2		;A

	SUBF	*AR0++,*AR2++,R0	;D
	SUBF	*AR0,*AR2++,R1
	SUBF	*+AR0(1),*AR2++,R2

	LDI	R3,AR2			;C

	SUBF	*-AR0(1),*AR2++,R3	;E
	SUBF	*AR0,*AR2++,R4
	SUBF	*+AR0(1),*AR2++,R5
	POP	AR0

	MPYF	R1,R5,R6		;dy*ez
	MPYF	R2,R4,R7		;dz*ey
	SUBF	R7,R6
	STF	R6,*AR0

	MPYF	R2,R3,R6		;dz*ex
	MPYF	R0,R5,R7		;dx*ez
	SUBF	R7,R6
	STF	R6,*+AR0(1)

	MPYF	R0,R4,R6
	MPYF	R1,R3,R7
	SUBF	R7,R6
	STF	R6,*+AR0(2)
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*CONCATENATE MATRICES, VOLATILE
*void	concatmat(MATRIX *s1, MATRIX *s2, MATRIX *d);
*
*PARAMETERS
*	AR2	s1 SOURCE_1 MATRIX
*	R2	s2 SOURCE_2 MATRIX
*	R3	d  DEST MATRIX
*
*NOTE	__d can NOT be equal to either __s1 or __s2.
*
*
*
*__s1	   __s2	    		__d
*A B C	   J K L    AJ+DK+GL BJ+EK+HL CJ+FK+IL
*D E F	*  M N O  = AM+DN+GO BM+EN+HO CM+FN+IO
*G H I     P Q R    AP+DQ+GR BP+EQ+HR CP+FQ+IR
*
CONCATMATV:
	LDI	R2,AR0
	LDI	R3,AR1

CONCAT201:
	LDI	5,IR1
	LDI	3,IR0

	LDI	2,RC
	RPTB	INLP2

*LOOP THREE TIMES
	MPYF3	*AR0++,*AR2++(IR0),R0
	MPYF3	*AR0,*AR2++(IR0),R1
	MPYF3	*+AR0(1),*AR2--(IR1),R1
  ||	ADDF3	R0,R1,R2


	MPYF3	*-AR0(1),*AR2++(IR0),R0
  ||	ADDF3	R1,R2,R2
	MPYF3	*AR0,*AR2++(IR0),R1
	STF	R2,*AR1++(1)			;store MATij
	MPYF3	*+AR0(1),*AR2--(IR1),R1
  ||	ADDF3	R0,R1,R2


	MPYF3	*-AR0(1),*AR2++(IR0),R0
  ||	ADDF3	R1,R2,R2
	MPYF3	*AR0++,*AR2++(IR0),R1
	STF	R2,*AR1++(1)			;store MATij
	MPYF3	*AR0++,*AR2--(IR1),R1
  ||	ADDF3	R0,R1,R2
	ADDF	R1,R2

	STF	R2,*AR1++(1)			;store MATij
INLP2	SUBI	3,AR2
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CONCATENATE MATRICES
*
*this is the non-volatile concatmat,  if the destination is not the same as
*either source use concatmatv because it doesn't do the extra copy (for
*avoiding overwrites)
*
*void	concatmat(MATRIX *s1,MATRIX *s2,MATRIX *d);
*
*PARAMETERS
*	AR2	s1 SOURCE_1 MATRIX
*	R2	s2 SOURCE_2 MATRIX
*	R3	d  DEST MATRIX
*
*
CONCATMAT:
	PUSH	AR0
	PUSH	AR1
	PUSH	AR0
	PUSH	R1
	PUSH	R2
	PUSH	R3

	PUSH	R3
	LDI	@LOCTEMPER_MATI,R3	;from DIRQ
	CALL	CONCATMATV
	POP	AR2
	LDI	@LOCTEMPER_MATI,R2
	CALL	CPYMAT

	POP	R3
	POP	R2
	POP	R1
	POP	R0
	POP	AR1
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*GETTHETADIFF
*compute radY delta (as smallest possible turn)
*
*PARAMETERS
*	R0	DESIRED THETA (float)
*	R2	CURRENT THETA (float)
*RETURNS
*	R0	THETA DELTA (float)
*
GETTHETADIFF:
	PUSHF	R1
	SUBF	R2,R0
	ABSF	R0,R1

	CMPF	@PII,R1
	BLT	NONEG
	LDF	R0,R0
	BN	ISNEG

	SUBF	@TWOPII,R0
	POPF	R1
	RETS

ISNEG	ADDF	@TWOPII,R0
NONEG	POPF	R1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*	LDI	AR2,AR0
*	LDP	@VECTORBI
*	LDI	@VECTORBI,AR1
*	LDF	*+AR4(OPOSX),R0
*	STF	R0,*+AR1(X)
*	CLRF	R0
*	STF	R0,*+AR1(Y)
*	LDF	*+AR4(OPOSZ),R0
*	STF	R0,*+AR1(Z)
*
*	CALL	DIST_PT2LINE
*
*PARAMETERS
*	AR0	LINE EQUATION (2D) A B C
*	AR1	2D POINT [X Y]
*
*RETURNS
*	R0	FL	DISTANCE TO LINE (SIGNED)
*
*
DIST_PT2LINE:
	PUSH	R1
	PUSH	R2
	PUSHF	R1
	PUSHF	R2
	MPYF	*+AR1(X),*+AR0(A),R0
	MPYF	*+AR1(Y),*+AR0(B),R1
	ADDF	R0,R1
	ADDF	*+AR0(C),R1
	MPYF	*+AR0(A),*+AR0(A),R0
	MPYF	*+AR0(B),*+AR0(B),R2
	ADDF	R0,R2
	CALL	SQRT
	LDF	R0,R2
	LDF	R1,R0
	LDF	R2,R1
	CALL	DIV_F
	POPF	R2
	POPF	R1
	POP	R2
	POP	R1
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*	LDI	@VECTORAI,AR0
*	LDI	@VECTORBI,AR1
*	CALL	GETLINE_EQ
*
*PARAMETERS
*	AR0	P1
*	AR1	P2
*	AR2	SPACE FOR LINE EQUATION
*
*RETURNS
*	AR2	VECTOR AS A B C
*
GETLINE_EQ_2D:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSHF	R0
	PUSHF	R1
	PUSHF	R2
	PUSHF	R3

	SUBF	*+AR1(X),*+AR0(X),R0
	SUBF	*+AR1(Y),*+AR0(Y),R1
	MPYF	R0,*+AR1(X),R2
	MPYF	R1,*+AR1(Y),R3
	ADDF	R3,R2
	NEGF	R2
	STF	R0,*+AR2(A)
	STF	R1,*+AR2(B)
	STF	R2,*+AR2(C)

	POPF	R3
	POPF	R2
	POPF	R1
	POPF	R0
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*see Foley & van Damn 2ed pg215
*
*scale matrix	Sx  0   0
*		0   Sy  0
*		0   0   Sz
*
*Once a FIND_MATRIX is complete you can pump that matrix through this
*routine and the object will be scaled by R2.  (Obviously each of the
*X Y and Z elements can be scaled independantly, but this might be 
*cumbersome, and it would be better suited for a different routine.
*
*Note that a 3x3 x 3x3 -> 3x3 matrix by the scale would be:
*
* ASx BSy CSz
* DSx ESy FSz  (by eliminating all the multiply by zeros)
* GSx HSy ISz
*
*PARAMETERS
*	AR2	MATRIX to be scaled
*	R2	SCALE FACTOR
*
*
*RETURNS
*	AR2	MATRIX modified for scaling
*
*
SCALE_MATRIX:
	PUSH	R3
	PUSHF	R3


	LDF	*+AR2(A00),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A00)
	LDF	*+AR2(A01),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A01)
	LDF	*+AR2(A02),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A02)

	LDF	*+AR2(A10),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A10)
	LDF	*+AR2(A11),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A11)
	LDF	*+AR2(A12),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A12)

	LDF	*+AR2(A20),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A20)
	LDF	*+AR2(A21),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A21)
	LDF	*+AR2(A22),R3
	MPYF	R2,R3
	STF	R3,*+AR2(A22)

	POPF	R3
	POP	R3
	RETS
*----------------------------------------------------------------------------
	.END
