******************************************************
*    TMS320C30 C COMPILER     Version 4.50
******************************************************
;	C:\BIN\ac30.exe -mr -ic:\c30tools -x -q line.c e:\line.if 
;	C:\BIN\opt30.exe -m -r -a -q -O2 e:\line.if e:\line.opt 
;	C:\BIN\cg30.exe -o -n -b -m -p -a -c -q e:\line.opt line.asm e:\line.tmp 
	.version	30
FP	.set		AR3
	.file	"line.c"

	.sym	_rectangle,_rectangle,32,2,0
	.globl	_rectangle

	.func	8
******************************************************
* FUNCTION DEF : _rectangle
******************************************************
_rectangle:
	PUSH	FP
	LDI	SP,FP
	ADDI	3,SP
	PUSH	R4
	PUSH	R5
	.sym	_x1,10,4,17,32
	.sym	_y1,2,4,17,32
	.sym	_x2,3,4,17,32
	.sym	_y2,19,4,17,32
	.sym	_color,20,4,17,32
*
* R4	assigned to parameter y2
* R5	assigned to parameter y1
*
	.sym	_y2,4,4,4,32
	.sym	_y1,5,4,4,32
	.sym	_color,1,4,1,32
	.sym	_x1,2,4,1,32
	.sym	_x2,3,4,1,32
	.line	2
	STI	RS,*+FP(1)
	STI	R3,*+FP(3)
	STI	AR2,*+FP(2)
	LDI	R2,R5
	LDI	RC,R4
 PUSH DP
	.line	4
	LDI	R5,R2
	LDI	R5,RC
	CALL	_line
	.line	5
	LDI	*+FP(2),AR2
	LDI	R4,R2
	LDI	*+FP(3),R3
	LDI	R4,RC
	LDI	*+FP(1),RS
	CALL	_line
	.line	6
	LDI	*+FP(2),AR2
	LDI	R5,R2
	LDI	*+FP(2),R3
	LDI	R4,RC
	LDI	*+FP(1),RS
	CALL	_line
	.line	7
	LDI	*+FP(3),AR2
	LDI	R5,R2
	LDI	*+FP(3),R3
	LDI	R4,RC
	LDI	*+FP(1),RS
	CALL	_line
 POP DP
EPI0_1:
	.line	9
	LDI	*-FP(1),R1
	LDI	*FP,FP
	BD	R1
	POP	R5
	POP	R4
	SUBI	5,SP
***	B	R1	;BRANCH OCCURS
	.endfunc	16,000000030H,3

	.sym	_line,_line,32,2,0
	.globl	_line

	.func	19
******************************************************
* FUNCTION DEF : _line
******************************************************
_line:
	PUSH	FP
	LDI	SP,FP
	ADDI	3,SP
	PUSH	R4
	PUSH	R5
	PUSHF	R6
	PUSHF	R7
	.sym	_x1,10,4,17,32
	.sym	_y1,2,4,17,32
	.sym	_x2,3,4,17,32
	.sym	_y2,19,4,17,32
	.sym	_color,20,4,17,32
*
* R2	assigned to variable  t
* R3	assigned to variable  t
* R4	assigned to variable  i
* R6	assigned to variable  x
* R6	assigned to variable  y
* R7	assigned to variable  xd
* R7	assigned to variable  yd
* RC	assigned to parameter y2
* RS	assigned to parameter x2
*
	.sym	_i,4,4,4,32
	.sym	L$5,5,4,4,32
	.sym	L$6,5,4,4,32
	.sym	L$4,5,4,4,32
	.sym	L$3,5,4,4,32
	.sym	L$2,5,4,4,32
	.sym	L$1,5,4,4,32
	.sym	_y,6,6,4,32
	.sym	_x,6,6,4,32
	.sym	_xd,7,6,4,32
	.sym	_yd,7,6,4,32
	.sym	U$8,2,6,4,32
	.sym	U$6,3,6,4,32
	.sym	_y2,19,4,4,32
	.sym	_x2,20,4,4,32
	.sym	_t,2,4,4,32
	.sym	_t,3,4,4,32
	.sym	_t,2,4,4,32
	.sym	_t,2,4,4,32
	.sym	_t,2,4,4,32
	.sym	_t,2,4,4,32
	.sym	_color,1,4,1,32
	.sym	_x1,2,4,1,32
	.sym	_y1,3,4,1,32
	.line	2
	STI	RS,*+FP(1)
	STI	R2,*+FP(3)
	STI	AR2,*+FP(2)
	LDI	R3,RS
 PUSH DP
	.line	12
	CMPI	*+FP(2),RS
	BZ	L32
	.line	16
	CMPI	RC,R2
	BZ	L26
	.line	22
	SUBI	R2,RC,R0
	FLOAT	R0,R2
	LDF	R2,R0
	CALL	INV_F30
	RND	R0
	LDI	*+FP(2),R1
	SUBI	R1,RS,R1
	FLOAT	R1,R3
	MPYF	R0,R3,R7
	.line	24
	CMPF	1.0,R7
	BGT	L14
	CMPF	-1.0,R7
	BLT	L14
	.line	26
	CMPI	*+FP(3),RC
	BGE	L5
	.line	27
	LDI	*+FP(2),R2
	STI	RS,*+FP(2)
	.line	28
	LDI	*+FP(3),R3
	STI	RC,*+FP(3)
	LDI	R3,RC
	.line	29
	SUBI	*+FP(3),R3
	FLOAT	R3,R0
	CALL	INV_F30
	RND	R0
	SUBI	*+FP(2),R2
	FLOAT	R2,R7
	MPYF	R0,R7
L5:
	.line	31
	FLOAT	*+FP(2),R6
	.line	32
	CMPF	0,R7
	BGT	L10
	.line	39
	LDI	*+FP(3),R4
	CMPI	RC,R4
	BGT	L38
	SUBI	R4,RC,R5
L44:
	.line	40
	FIX	R6,AR2
	LDI	R4,R2
	LDI	*+FP(1),R3
	CALL	_pixel
	.line	41
	SUBI	1,R5
	BGED	L44
	ADDF	R7,R6
	NOP
	.line	39
	ADDI	1,R4
***	BGE	L44	;BRANCH OCCURS
	B	L38
L10:
	.line	33
	LDI	*+FP(3),R4
	CMPI	RC,R4
	BGT	L38
	SUBI	R4,RC,R5
L43:
	.line	34
	FIX	R6,AR2
	LDI	R4,R2
	LDI	*+FP(1),R3
	CALL	_pixel
	.line	35
	SUBI	1,R5
	BGED	L43
	ADDF	R7,R6
	NOP
	.line	33
	ADDI	1,R4
***	BGE	L43	;BRANCH OCCURS
	B	L38
L14:
	.line	45
	CMPI	*+FP(2),RS
	BLT	L16
	.line	51
	LDF	R3,R0
	CALL	INV_F30
	BD	L17
	RND	R0
	NOP
	MPYF	R0,R2,R7
***	B	L17	;BRANCH OCCURS
L16:
	.line	46
	LDI	*+FP(2),R2
	STI	RS,*+FP(2)
	LDI	R2,RS
	.line	47
	LDI	*+FP(3),R2
	STI	RC,*+FP(3)
	.line	48
	LDI	*+FP(2),R0
	SUBI	R0,RS,R1
	FLOAT	R1,R0
	CALL	INV_F30
	RND	R0
	SUBI	*+FP(3),R2
	FLOAT	R2,R7
	MPYF	R0,R7
L17:
	.line	53
	FLOAT	*+FP(3),R6
	.line	55
	CMPF	0,R7
	BGT	L22
	.line	62
	LDI	*+FP(2),R4
	CMPI	RS,R4
	BGT	L38
	SUBI	R4,RS,R5
L42:
	.line	63
	LDI	R4,AR2
	FIX	R6,R2
	LDI	*+FP(1),R3
	CALL	_pixel
	.line	64
	SUBI	1,R5
	BGED	L42
	ADDF	R7,R6
	NOP
	.line	62
	ADDI	1,R4
***	BGE	L42	;BRANCH OCCURS
	B	L38
L22:
	.line	56
	LDI	*+FP(2),R4
	CMPI	RS,R4
	BGT	L38
	SUBI	R4,RS,R5
L41:
	.line	57
	LDI	R4,AR2
	FIX	R6,R2
	LDI	*+FP(1),R3
	CALL	_pixel
	.line	58
	SUBI	1,R5
	BGED	L41
	ADDF	R7,R6
	NOP
	.line	56
	ADDI	1,R4
***	BGE	L41	;BRANCH OCCURS
	B	L38
L26:
	.line	17
	CMPI	*+FP(2),RS
	BGE	L28
	LDI	*+FP(2),R2
	STI	RS,*+FP(2)
	LDI	R2,RS
L28:
	.line	18
	LDI	*+FP(2),R4
	CMPI	RS,R4
	BGT	L38
	SUBI	R4,RS,R5
L40:
	.line	19
	LDI	R4,AR2
	LDI	*+FP(3),R2
	LDI	*+FP(1),R3
	CALL	_pixel
	.line	18
	ADDI	1,R4
	SUBI	1,R5
	BGE	L40
	B	L38
L32:
	.line	13
	CMPI	RC,R2
	BLE	L34
	STI	RC,*+FP(3)
	LDI	R2,RC
L34:
	.line	14
	LDI	*+FP(3),R4
	CMPI	RC,R4
	BGT	L38
	SUBI	R4,RC,R5
L39:
	.line	15
	LDI	*+FP(2),AR2
	LDI	R4,R2
	LDI	*+FP(1),R3
	CALL	_pixel
	.line	14
	ADDI	1,R4
	SUBI	1,R5
	BGE	L39
L38:
 POP DP
EPI0_2:
	.line	71
	LDI	*-FP(1),R1
	LDI	*FP,FP
	POPF	R7
	POPF	R6
	BD	R1
	POP	R5
	POP	R4
	SUBI	5,SP
***	B	R1	;BRANCH OCCURS
	.endfunc	89,0000000f0H,3
******************************************************
* UNDEFINED REFERENCES                               *
******************************************************
	.globl	INV_F30
	.globl	_pixel
	.end
