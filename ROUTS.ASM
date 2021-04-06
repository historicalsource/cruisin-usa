	.FILE	"ROUTS.ASM"
*----------------------------------------------------------------------------
*RUNTIME SYSTEM ROUTINES
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
*
*THIS FILE CONTAINS THE RUNTIME SOURCE CODE TO C ORIENTED OPERATIONS
*
*CONTAINED IN THIS FILE ARE THE FOLLOWING FUNCTIONS
*
*	DIV_F		divide floating
*	DIV_I		divide integer
*	DIV_U30		divide unsigned
*	INV_F30		inverse floating
*	MOD_I30		modulus integer
*	MOD_U30		modulus unsigned
*	SQRT		C callable sqrt()
*
*

	.globl	SQRT
	.globl	DIV_F,DIV_F30
	.globl	DIV_I,DIV_I30
	.globl	DIV_U30
        .globl	INV_F30
	.globl	MOD_I30
	.globl	MOD_U30




*----------------------------------------------------------------------------
*DIVF	Floating point divide function
*
*PARAMETERS	u in R0, v in R1
*	R0	FL u
*	R1	FL v
*RETURNS	
*	R0	FL R0/R1
*STATUS		Set from result in R0
*OPERATION	Result = (1/v) * u.
*
*CLOBBERS	R0,R1,BK
*
*----------------------------------------------------------------------------
*	DIV_F - Floating point division
*
*	Algorithm:
*	Given v = a * 2**e
*	x[0] = 1.0 * 2**(-e-1)
*	for (i = 1; i <= 5; i++)
*	 x[i] = x[i-1] * (2.0 - v * x[i-1])
*
*	The single-precision floating-point format is accurate to 6.9 
*	decimal places.	The single-precision format is accurate to 
*	2**-23 = 1.192E-7, so we would like to have that much accuracy 
*	in the final result.
*
*	The algorithm's error at an iteration i (e[i]) is defined as
*		e[i] = 1 - v * x[i]
*	It can also be shown that e[i+1] = e[i] * e[i].
*
*	Cycles: 40
*
DIV_F:
DIV_F30
	POP	BK	;Pop return address
	PUSH	R2	;Save R2: integer part
	PUSHF	R2	;Save R2: floating point part

	PUSHF	R1	;SAVE THE SIGN
	PUSHF	R0	;Save u (dividend) 
;	LDI	R1,AR0	;Save mantissa of v to remember sign
	ABSF	R1	;The algorithm uses v = |v|.


	;
	;	Extract the exponent of v.
	;
	PUSHF	R1
	POP	R2
	ASH	-24,R2	;The 8 LSBs of R2 contain the exponent of v.
;
;A few comments on boundary conditions.	If e = -128, then v = 0.  The
;following x[0] calculation yields R2 = --128 - 1 = 127 and the algorithm will
;overflow and saturate since x[0] is large.  This seems reasonable.  If e =
;127, the R2 = -127 - 1 = -128.	Thus x[0] = 0 and this will cause the
;algorithm to yield zero.  Since the mantissa of v is always between 1 and 2,
;this is also reasonable.  As a result, boundary conditions are handled
;automatically in a reasonable fashion.
;
;	x[0] formation given the exponent of v.
;
	NEGI	R2
	SUBI	1,R2		;Now we have -e-1, the exponent of x[0].
	ASH	24,R2
	PUSH	R2
	POPF	R2		;Now R2 = x[0] = 1.0 * 2**(-e-1).

	;
	;Now the iterations begin.
	;
	MPYF	R2,R1,R0	;R0 = v * x[0]
	SUBRF	2.0,R0		;R0 = 2.0 - v * x[0]
	MPYF	R0,R2		;R2 = x[1] = x[0] * (2.0 - v * x[0])
 
	MPYF	R2,R1,R0	;R0 = v * x[1]
	SUBRF	2.0,R0		;R0 = 2.0 - v * x[1]
	MPYF	R0,R2		;R2 = x[2] = x[1] * (2.0 - v * x[1])
 
	MPYF	R2,R1,R0	;R0 = v * x[2]
	SUBRF	2.0,R0		;R0 = 2.0 - v * x[2]
	MPYF	R0,R2		;R2 = x[3] = x[2] * (2.0 - v * x[2])
 
	MPYF	R2,R1,R0	;R0 = v * x[3]
	SUBRF	2.0,R0		;R0 = 2.0 - v * x[3]
	MPYF	R0,R2		;R2 = x[4] = x[3] * (2.0 - v * x[3])
 
	RND	R2		;This minimizes error in the LSBs.


	;
	;For the last iteration we use the formulation:
	;x[5] = (x[4] * (1.0 - (v * x[4]))) + x[4]
	;
	MPYF	R2,R1,R0	;R0 = v * x[4] = 1.0..01.. => 1
	SUBRF	1.0,R0		;R0 = 1.0 - v * x[4] = 0.0..01... => 0
	MPYF	R2,R0		;R0 = x[4] * (1.0 - v * x[4])
	ADDF	R0,R2,R1	;R0 = x[5] = (x[4]*(1.0-(v*x[4])))+x[4]

	;
	;R1 contains 1/v.	Multiply by u to get result.
	;
	RND	R1		;Round since this is follow by a MPYF.
	POPF	R0		;Pop u
	MPYF	R1,R0		;Result = u * (1/v)

	;
	;Branch (delayed) return.	Use delay slots to negate the result if v < 0.
	;

	NEGF	R0,R1		;R1 = -(1/|v|)
	POPF	R2		;CHECK ORIGINAL SIGN DUDES... (SETS SIGN FLAG)

	BD	BK		;Delayed branch to return
	LDFN	R1,R0		;If v < 0, then R1 = -R1 (BASED ON POPF R2)
	POPF	R2		;Restore R2: floating point part
	POP	R2		;Restore R2: integer part
	;---->B	BK		;BRANCH OCCURS (RETURN)
*----------------------------------------------------------------------------






*----------------------------------------------------------------------------
*DIVI	Integer divide routine (signed)
*
*
*PARAMETERS
*	R0	Signed integer dividend in R0
*	R1 	Signed integer divisor in R1
*
*OUTPUT		R0 / R1 into R0.
*STATUS		Set from result in R0.
*Registers used	R0, R1, AR0, AR1, RC, RS, RE
*
*Operation	1. Normalize divisor with dividend
*		2. Repeat SUBC
*		3. Quotient is in LSBs of result
*
*Cycles		31-62 (depends on amount of normalization)
*
*
	.asg	AR1,V		;divisor
	.asg	R1,TEMP		;float value of operands
	.asg	R1,COUNT	;repeat/shift count 
	.asg	AR0,SIGN	;sign of quotient
	.asg	RC,EXP		;divisor exponent 

DIV_I:
DIV_I30

	;
	;Determine sign of result.	Get absolute value of operands.
	;
	XOR	R0,R1,SIGN	;get the sign
	ABSI	R0		;make dividend positive
	BVD	div_32	 	;if still negative, escape
	ABSI	R1		;make divisor positive
	LDI	R1,V		;save in V
	CMPI	R0,V		;divisor > dividend ? 
	BHID	zero		; if so, return 0

	;
	;Normalize operands.	Use difference in exponents as shift count
	;for divisor, and as repeat count for SUBC.
	;
	FLOAT	R1,TEMP		;normalize divisor
	PUSHF	TEMP		;push as float 
	POP	EXP		;pop as int

	FLOAT	R0,TEMP		;normalize dividend
	PUSHF	TEMP		;push as float
	POP	COUNT		;pop as int 

	LSH	-24,EXP		;divisor exponent
	LSH	-24,COUNT	;dividend exponent
	SUBI	EXP,COUNT	;get difference in exponents
	LSH	COUNT,V		;align divisor with dividend
	;
	;Do COUNT+1 subtract & shifts.
	;
	RPTS	COUNT 
	SUBC	V,R0
	;
	; Mask off the lower COUNT+1 bits of R0
	;
	SUBRI	31,COUNT	;shift count is (32 - (COUNT+1))
	LSH	COUNT,R0	;shift left
	NEGI	COUNT
	LSH	COUNT,R0	;shift right to get result



	;Check sign and negate result if necessary.
return
	POP	RC		;return address
	NEGI	R0,TEMP		;negate result
	BD	RC		;delayed branch to return
	CMPI	0,SIGN		;check sign 
	LDIN	TEMP,R0		;if set, use negative result
	CMPI	0,R0		;set status from result
	;---->	B	RC		;BRANCH OCCURS (RETURN)


	;The following code handles cases of a full 32-bit dividend.	This occurs
	;when R0 = abs(R0) = 080000000h.	Handle this by calling the unsigned divide
	;function, then negating the result if necessary.
div_32
	PUSH	SIGN		;remember sign
	CALL	DIV_U30		;do divide
	POP	SIGN		;restore sign
	B	return		;return

	;***Return zero.
zero
	LDI	0,R0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*DIVU	Integer divide routine (unsigned)
*
*
*PARAMETERS		Unsigned dividend in R0, 
*			unsigned divisor in R1.
*
*	Output:		R0 / R1 into R0.
*	Status:		Set from result in R0.
*	Registers used:	R0, R1, AR0, AR1, RC, RS, RE
*	Operation:	1. Normalize divisor with dividend
*			2. Repeat SUBC
*			3. Quotient is in LSBs of result 
*
*	Cycles:		31-65
*
	.asg	AR1,V		;divisor
	.asg	R1, TEMP	;float value of operands
	.asg	R1, MSBQ	;MSQ of quotient
	.asg	AR0,QMASK	;mask for quotient
	.asg	AR0,COUNT	;repeat/shift count
	.asg	RC, EXP		;divisor exponent

DIV_U30:

	CMPI	R0,R1		;divisor > dividend ? 
	BHI	zerob		;	if so, return 0
	LDI	R1,V		;move divisor to AR1

	;
	;If top bit of dividend is set, handle specially.
	;
	CMPI	0,R0 		;check top bit
	BLTD	div_32b	 	;get divisor exponent, then jump.
	;
	;Get divisor exponent by converting to float.
	;
	FLOAT	V,TEMP	 	;normalize divisor
	PUSHF	TEMP		;push as float
	POP	EXP		;pop as int to get exponent
	;
	;31 or less bits in dividend.	Get dividend exponent.
	;
	FLOAT	R0,TEMP		;normalize dividend
	PUSHF	TEMP		;push as float
	POP	COUNT		;pop as int to get exponent
	;
	;Use difference in exponents as shift count to line up MSBs.
	;
	LSH	-24,COUNT	;divisor exponent
	LSH	-24,EXP		;dividend exponent
	SUBI	EXP,COUNT	;difference
	LSH	COUNT,V		;shift divisor up
	;
	;Do COUNT+1 subtract & shifts.
	;
	RPTS	COUNT
	SUBC	V,R0	
	;
	; Mask off the lower COUNT+1 bits of U and return.
	;
	POP	RC		;return address
	SUBRI	31,COUNT	;shift count is (32 - (COUNT+1))
	BD	RC		;delayed branch to return
	LSH	COUNT,R0	;shift left
	NEGI	COUNT
	LSH	COUNT,R0	;shift right to get result
	;---->	B	RC		;BRANCH OCCURS (RETURN)

;
;The following code handles cases of a full 32-bit dividend.	Before
;SUBC can be used, the top bit must be cleared (otherwise SUBC can
;possibly shift a significant 1 out the top of the dividend).	This
;is accomplished by first doing a normal subtraction, then proceeding
;with SUBCs. 
;
div_32b
;
;If the top bit of the divisor is set too, the quotient is 1.	
;Otherwise, shift the divisor up to line up the MSBs. 
;
	CMPI	0,V		;check divisor
	BLTD	one		;if top bit set, quotient is 1
	LSH	-24,EXP		;divisor exponent
	SUBRI	31,EXP		;shift count 
	LSH	EXP,V		;shift up to line up MSBs

	;
	;Now MSBs are aligned.	Do first SUBC by hand, and save off the first
	;quotient digit.	Then, shift divisor right rather than shifting dividend
	;left.	This leaves a 0 in the top bit of the dividend.
	;
	LDI	1,QMASK		;initialize MSB of quotient
	LSH	EXP,QMASK	;create a mask for the MSBs
	SUBI	1,QMASK		;mask is (2 << COUNT) - 1

	SUBI	V,R0,TEMP	;subtract 
	LDIHS	TEMP,R0		;if positive, replace dividend
	LDIHS	1,MSBQ		;	and set quotient to 1
	LDILO	0,MSBQ		;if negative, set quotient to 0
	LSH	EXP,MSBQ	;shift MSB into position

	LSH	-1,V		;shift divisor down
	SUBI	1,EXP		;first iteration is done

	;
	;Do EXP subtract & shifts.
	;
	RPTS	EXP	
	SUBC	V,R0

	;
	;MSB of the quotient is in MSBQ.	LSBs are in the lower COUNT bits of
	;R0.
	;
	POP	RC		;return address
	BD	RC		;delayed branch to return
	AND	QMASK,R0	;mask off LSBs
	OR	MSBQ,R0		;MSB of quotient
	NOP
	;---->	B	RC		;BRANCH OCCURS (RETURN)

	;
	; Return one.
	;
one	LDI	1,R0
	RETS

	;
	; Return zero.
	;
zerob	LDI	0,R0
	RETS
*----------------------------------------------------------------------------






*----------------------------------------------------------------------------
*INVF	Floating point inverse function
*
*
*PARAMETERS		v in R0
*RETURNS		1/v in R0
*Status			Not set from result (!!!)
*Registers used		R0, R1, BK
*
*	Algorithm:
*	Given v = a * 2**e
*	x[0] = 1.0 * 2**(-e-1)
*	for (i = 1;i <= 5;i++)
*	 x[i] = x[i-1] * (2.0 - v * x[i-1])
*
*	The single-precision floating-point format is accurate to 6.9 
*	Given v = a * 2**e
*	x[0] = 1.0 * 2**(-e-1)
*	for (i = 1;i <= 5;i++)
*	 x[i] = x[i-1] * (2.0 - v * x[i-1])
*
*	The single-precision floating-point format is accurate to 6.9 
*	decimal places.	The single-precision format is accurate to 
*	2**-23 = 1.192E-7, so we would like to have that much accuracy 
*	in the final result.
*
*	The algorithm's error at an iteration i (e[i]) is defined as
*		e[i] = 1 - v * x[i]
*	It can also be shown that e[i+1] = e[i] * e[i].
*	Cycles: 36
*
INV_F30:
	POP	BK		;Pop return address

	PUSH	R2		;Save R2: integer part
	PUSHF	R2		;Save R2: floating point part

	PUSHF	R0
	ABSF	R0		;The algorithm uses v = |v|.

	;
	;	Extract the exponent of v.
	;
	PUSHF	R0
	POP	R1
	ASH	-24,R1		;The 8 LSBs of R1 contain the exponent of v.
;
;A few comments on boundary conditions.	If e = -128, then v = 0.	The
;following x[0] calculation yields R1 = --128 - 1 = 127 and the algorithm will
;overflow and saturate since x[0] is large.	This seems reasonable.	If e =
;127, the R1 = -127 - 1 = -128.	Thus x[0] = 0 and this will cause the
;algorithm to yield zero.	Since the mantissa of v is always between 1 and 2,
;this is also reasonable.	As a result, boundary conditions are handled
;automatically in a reasonable fashion.
;
;	x[0] formation given the exponent of v.
;
	NEGI	R1
	SUBI	1,R1		;Now we have -e-1, the exponent of x[0].
	ASH	24,R1
	PUSH	R1
	POPF	R1		;Now R1 = x[0] = 1.0 * 2**(-e-1).
	;
	;Now the iterations begin.
	;
	MPYF	R1,R0,R2	;R2 = v * x[0]
	SUBRF	2.0,R2		;R2 = 2.0 - v * x[0]
	MPYF	R2,R1		;R1 = x[1] = x[0] * (2.0 - v * x[0])
 
	MPYF	R1,R0,R2	;R2 = v * x[1]
	SUBRF	2.0,R2		;R2 = 2.0 - v * x[1]
	MPYF	R2,R1		;R1 = x[2] = x[1] * (2.0 - v * x[1])
 
	MPYF	R1,R0,R2	;R2 = v * x[2]
	SUBRF	2.0,R2		;R2 = 2.0 - v * x[2]
	MPYF	R2,R1		;R1 = x[3] = x[2] * (2.0 - v * x[2])
 
	MPYF	R1,R0,R2	;R2 = v * x[3]
	SUBRF	2.0,R2		;R2 = 2.0 - v * x[3]
	MPYF	R2,R1		;R1 = x[4] = x[3] * (2.0 - v * x[3])
 
	RND	R1		;This minimizes error in the LSBs.
	;
	;For the last iteration we use the formulation:
	;x[5] = (x[4] * (1.0 - (v * x[4]))) + x[4]
	;
	MPYF	R1,R0,R2	;R2 = v * x[4] = 1.0..01.. => 1
	SUBRF	1.0,R2		;R2 = 1.0 - v * x[4] = 0.0..01... => 0
	MPYF	R1,R2		;R2 = x[4] * (1.0 - v * x[4])
	ADDF	R2,R1,R0	;R0 = x[5] = (x[4]*(1.0-(v*x[4])))+x[4]
	;
	;Return (delayed). Use delay slots to negate the result if v < 0.
	;

	NEGF	R0,R1		;R1 = -(1/|v|)
	POPF	R2		;CHECK ORIGINAL SIGN DUDES... (SETS SIGN FLAG)

	BD	BK		;Delayed branch to return
	LDFN	R1,R0		;If v < 0, then R1 = -R1 (BASED ON POPF R2)
	POPF	R2		;Restore R2: floating point part
	POP	R2		;Restore R2: integer part
	;---->B	BK		;BRANCH OCCURS (RETURN)
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*MODI	Integer modulo (signed)
*
*PARAMETERS		Signed integer dividend in R0, 
*			Signed integer divisor in R1.
*Output			R0 % R1 into R0.
*Status			Set from result in R0.
*Registers used		R0, R1, AR0, AR1, IR0, IR1
*
*Operation	1. Normalize divisor with dividend
*		2. Repeat SUBC
*		3. Remainder is in MSBs of result
*
*	Cycles:		31-62 (depends on normalization)
*
	.asg	AR1,V		;divisor
	.asg	R1,TEMP		;float value of operands
	.asg	R1,COUNT	;repeat/shift count 
	.asg	AR0,SIGN	;sign of result
	.asg	RC,EXP	 	;divisor exponent 

MOD_I30:

	;
	;Determine sign of result.	Get absolute value of operands.
	;
	LDI	R0,SIGN		;sign of result same as dividend
	ABSI	R0		;make dividend positive
	BVD	mod_32	 	;if still negative, escape
	ABSI	R1		;make divisor positive
	LDI	R1,V		;save in V	
	CMPI	R0,V		;divisor > dividend ? 
	BHID	returnc	 	; if so, return dividend
	;
	;Normalize operands.	Use difference in exponents as shift count
	;for divisor, and as repeat count for SUBC.
	;
	FLOAT	R1,TEMP		;normalize divisor
	PUSHF	TEMP		;push as float 
	POP	EXP		;pop as int

	FLOAT	R0,TEMP		;normalize dividend
	PUSHF	TEMP		;push as float
	POP	COUNT		;pop as int 

	LSH	-24,EXP		;get divisor exponent
	LSH	-24,COUNT	;get dividend exponent
	SUBI	EXP,COUNT	;get difference in exponents
	LSH	COUNT,V		;align divisor with dividend
	;
	;Do COUNT+1 subtract & shifts.
	;
	RPTS	COUNT
	SUBC	V,R0
	;
	; Remainder is in upper bits of R0
	;
	ADDI	1,COUNT		;shift count is -(COUNT+1)
	NEGI	COUNT 
	LSH	COUNT,R0	;shift right
	;
	; Check sign and negate result if necessary.
	;
returnc
	POP	RC		;return address
	NEGI	R0,TEMP		;negate result
	BD	RC		;delayed branch to return
	CMPI	0,SIGN	 	;check sign
	LDIN	TEMP,R0		;if set, use negative result
	CMPI	0,R0		;set status on result
	;---->	B	RC		;BRANCH OCCURS (RETURN)
;
;The following code handles cases of a full 32-bit dividend.	This occurs
;when R0 = abs(R0) = 080000000h.	Handle this by calling the unsigned mod
;function, then negating the result if necessary.
;
mod_32
	PUSH	SIGN		;remember sign
	CALL	MOD_U30		;do divide
	POP	SIGN		;restore sign
	B	return	 	;return
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*MODU	Integer modulo (unsigned)
*
*PARAMETERS		Unsigned dividend in R0, 
*			unsigned divisor in R1.
*
*Output			R0 % R1 into R0.
*Status			Set from result in R0.
*Registers used		R0, R1, AR0, AR1, RC, RS, RE
*Operation	1. Normalize divisor with dividend
*		2. Repeat SUBC
*		3. Remainder is in MSBs of result
*
*Cycles		31-60
*
	.asg	AR1,V		;divisor
	.asg	R1,TEMP		;float value of operands
	.asg	AR0,COUNT	;repeat/shift count
	.asg	RC,EXP	 	;divisor exponent

MOD_U30:

	CMPI	R0,R1		;divisor > dividend ? 
	BHI	zerob		;	if so, return dividend
	LDI	R1,V		;load divisor
	;
	;If top bit of dividend is set, handle specially.
	;
	CMPI	0,R0 		;check top bit
	BLTD	mod_32c	 	;get divisor exponent, then jump.
	;
	;Get divisor exponent by converting to float.
	;
	FLOAT	V,TEMP	 	;normalize divisor
	PUSHF	TEMP		;push as float
	POP	EXP		;pop as int to get exponent
	;
	;31 or less bits in dividend.	Get dividend exponent.
	;
	FLOAT	R0,TEMP		;normalize dividend
	PUSHF	TEMP		;push as float
	POP	COUNT		;pop as int to get exponent
	;
	;Use difference in exponents as shift count to line up MSBs.
	;
	LSH	-24,EXP		;divisor exponent
	LSH	-24,COUNT	;dividend exponent
	SUBI	EXP,COUNT	;difference
	LSH	COUNT,V		;shift divisor up
	;
	;Do COUNT+1 subtract & shifts.
	;
	RPTS	COUNT
	SUBC	V,R0	
	;
	; Remainder is in upper 31-COUNT bits.
	;
	POP	RC		;return address
	BD	RC		;delayed branch to return
	ADDI	1,COUNT		;shift count is COUNT+1
	NEGI	COUNT		;negate for right shift
	LSH	COUNT,R0	;shift to get result
	;---->	B	RC	;BRANCH OCCURS (RETURN)

;
;The following code handles cases of a full 32-bit dividend.	Before
;SUBC can be used, the top bit must be cleared (otherwise SUBC can
;possibly shift a significant 1 out the top of the dividend).	This
;is accomplished by first doing a normal subtraction, then proceeding
;with SUBCs. 
;
mod_32c
;
;If the top bit of the divisor is set too, the remainder is simply
;the difference between the dividend and divisor.	Otherwise, shift 
;the divisor up to line up the MSBs.
;
	CMPI	0,V		;check divisor
	BLTD	onec		;if negative, remainder is diff

	LSH	-24,EXP		;divisor exponent
	SUBRI	31,EXP	 	;shift count = 31 - exp
	NEGI	EXP,COUNT	;used later as shift count
	LSH	EXP,V		;shift up to line up MSBs

	;
	;Now MSBs are aligned.	Do first SUBC by hand using a plain subtraction.
	;Then, shift divisor right rather than shifting dividend left.	This leaves
	;a 0 in the top bit of the dividend.
	;
	SUBI	V,R0,TEMP	;subtract 
	LDIHS	TEMP,R0		;if positive, replace dividend
	SUBI	1,EXP		;first iteration is done
	LSH	-1,V		;shift divisor down

	;
	;Do EXP subtract & shifts.
	;
	RPTS	EXP	
	SUBC	V,R0

	;
	;Quotient is in EXP+1 LSBs;shift remainder (in MSBs) down.
	;
	LSH	COUNT,R0	;COUNT contains -(EXP+1)
	RETS

	;
	; Return (dividend - divisor).
	;
onec	SUBI	R1,R0	
	RETS

	;
	; Return dividend.
	;
zeroc	CMPI	0,R0		;set status from result
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*double sqrt(double x)
*SQRT	Square Root
*
*PARAMETERS
*	R2	float	x
*
*RETURNS
*	R0	float square root of x
*		If x <= 0 returns x
*
*CLOBBERS
*	R0,R1,R2,R3
*
*The algorithm is from the TMS320C30 User's Guide, p. 11-30
*
*This has been modified from the C version such that _errno
*is not set (nor does it exist).
*
*
*CYCLES	
*	52 (64 OUT OF CACHE  (PUSHES))
*


SQRT:
	LDF	R2,R0
	RETSLE			;return the value if <= 0

	PUSH	R1
	PUSHF	R1
	PUSH	R2
	PUSHF	R2
 
	MPYF	2.0,R2		;add a rounding bit in exponent
	PUSHF	R2		;push x as float
	POP	R1		;pop as int
	ASH	-25,R1		;e = exponent(x) / 2

	;
	;determine initial estimate .25 * 2**(-e/2)
	;
	NEGI	R1		;negate exponent 
	ASH	24,R1	 	;shift into place
	PUSH	R1		;push as int 
	POPF	R1		;pop as float
	MPYF	0.25,R2		;remove rounding bit

	;
	;iterate 5 times
	;
	MPYF	R1,R1,R0	;R0 = x[0] * x[0]
	MPYF	R2,R0	 	;R0 = (v/2) * x[0] * x[0]
	SUBRF	1.5,R0		;R0 = 1.5 - (v/2) * x[0] * x[0]
	MPYF	R0,R1		;x[1] = x[0] * (1.5 - v/2 * x[0] * x[0])

	;2
	RND	R1
	MPYF	R1,R1,R0	;R0 = x[1] * x[1]
	MPYF	R2,R0	 	;R0 = (v/2) * x[1] * x[1]
	SUBRF	1.5,R0		;R0 = 1.5 - (v/2) * x[1] * x[1]
	MPYF	R0,R1		;x[2] = x[1] * (1.5 - v/2 * x[1] * x[1])

	;3
	RND	R1
	MPYF	R1,R1,R0	;R0 = x[2] * x[2]
	MPYF	R2,R0	 	;R0 = (v/2) * x[2] * x[2]
	SUBRF	1.5,R0		;R0 = 1.5 - (v/2) * x[2] * x[2]
	MPYF	R0,R1		;x[3] = x[2] * (1.5 - v/2 * x[2] * x[2])

	;4
	RND	R1
	MPYF	R1,R1,R0	;R0 = x[3] * x[3]
	MPYF	R2,R0	 	;R0 = (v/2) * x[3] * x[3]
	SUBRF	1.5,R0		;R0 = 1.5 - (v/2) * x[3] * x[3]
	MPYF	R0,R1		;x[4] = x[3] * (1.5 - v/2 * x[3] * x[3])

	;5
	RND	R1
	MPYF	R1,R1,R0	;R0 = x[4] * x[4]
	MPYF	R2,R0	 	;R0 = (v/2) * x[4] * x[4]
	SUBRF	1.5,R0		;R0 = 1.5 - (v/2) * x[4] * x[4]
	MPYF	R0,R1		;x[5] = x[4] * (1.5 - v/2 * x[4] * x[4])

	RND	R1

	POPF	R2
	POP	R2

	MPYF	R2,R1,R0	;sqrt(x) = x * sqrt(1/x)

	POPF	R1
	POP	R1
	RETS
*----------------------------------------------------------------------------
	.END

