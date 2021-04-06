	.FILE	"INFIN.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	MACS.EQU
	.include	OBJ.EQU
	.include	OBJECTS.EQU
	.include	GLOBALS.EQU
	.include	SYS.EQU
	.include	VUNIT.EQU
	.include	PALL.EQU


	.bss	CAMRADY,1  	;NORMALIZED 0-2PI CAMERA RAD



*----------------------------------------------------------------------------
*SEARCH THE ROAD OBJECTS AND FIND THE HIGHEST POSITIONED OBJECT.
*
*Note that the case of the player being inverted can not happen because the
*infinity plane would freak out, and who knows what would happen then, so we
*assume that this case is not present. Therefore we can simply say the the 
*highest valued Y position of the objects is the highest Y position, and then
*only that value must be projected in Y.
*
*
HIGH_CLIP_LEVEL		.set	(5000-1)		;ACTUAL # OF ENTRIES

	.bss	HIGHEST_ROADY,1		;FL	CLIP LEVEL IN Y
	.bss	HIGHEST_ROADY_X,1	;FL	CLIP LEVEL IN Y

	.bss	VAR_ROAD_KFACTOR,1	;FL	CLIPPING OVERSHOOT FACTOR

FIND_HIGHEST_ROADY:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R6
	PUSH	R7
	PUSH	AR2


	FLOAT	512,R6
	STPF	R6,@HIGHEST_ROADY

	CLRF	R7			;CORRESPONDING Z POS

	LDI	@DYNALIST_BEGIN,AR2
	CMPI	0,AR2
	BEQ	FHRY_X

FHRYLP
	LDI	*+AR2(OFLAGS),R0
	AND	O_LIST_M,R0
	CMPI	O_LIST1,R0		;OACTIVE ONLY!
	BNE	NOCHANCE



	;use leftover CAMERAMATRIX
	;
	LDI	@VECTORAI,AR1

	LDP	@_CAMERAPOS+X
	LDF	*+AR2(OPOSX),R0
	SUBF	@_CAMERAPOS+X,R0
	STF	R0,*+AR1(X)

	LDF	*+AR2(OPOSY),R0
	SUBF	@_CAMERAPOS+Y,R0
	STF	R0,*+AR1(Y)

	LDF	*+AR2(OPOSZ),R0
	SUBF	@_CAMERAPOS+Z,R0
	STF	R0,*+AR1(Z)
	SETDP

	LDI	AR1,AR0
	LDI	@CAMERAMATRIXI,AR1	;AR1 IS 3X3 MATRIX

	;matrix mul  really only concerned with Y
	;
 	MPYF	*AR0++,*AR1++,R0
	MPYF	*AR0,*AR1++,R2
	MPYF	*+AR0(1),*AR1++,R0
 || 	ADDF	R0,R2

	MPYF	*-AR0(1),*AR1++,R0
 ||	ADDF	R0,R2
	PUSHF	R2

	MPYF	*AR0,*AR1++,R2
	MPYF	*+AR0(1),*AR1++,R0
 || 	ADDF	R0,R2

	ADDF	R0,R2
	;


	POPF	R3
	LDI	*+AR2(ODIST),AR1
	CMPI	0,AR1
	BLE	NOCHANCE
	RS	4,AR1			;/16
	CMPI	HIGH_CLIP_LEVEL,AR1
	BGE	NOCHANCE

	ADDI	@INVTABI,AR1
	MPYF	*AR1,R3
	ADDF	@SCRNHXI,R3		;this is the clip level (in Y)
	CMPF	0,R3
	BLT	NOCHANCE

	FLOAT	512,R0
	CMPF	R0,R3
	BGT	NOCHANCE

	MPYF	*AR1,R2
	ADDF	@SCRNHYI,R2		;this is the clip level (in Y)

	CMPF	R2,R6
	LDFGT	R2,R6
	LDFGT	R3,R7			;SAVE X VALUE

NOCHANCE
	LDI	*+AR2(OLINK4),AR2
	CMPI	0,AR2
	BNE	FHRYLP

;no kludge factor nessesary



	ADDF	@VAR_ROAD_KFACTOR,R6			;pixels UNDER (overshoot)

	CMPF	0,R6
	LDFLT	0,R6
	STPF	R6,@HIGHEST_ROADY
	STPF	R7,@HIGHEST_ROADY_X	;SAVE X VALUE

FHRY_X

	POP	AR2
	POP	R7
	POP	R6
	POP	R3
	POP	R2
	POP	R1
	POP	R0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PLOT INFINITY PLANE
*
*VERTICES TRANSFORMED AS
*     1	 3  5
*
*     0	 2  4  etc.
*
*
		.bss	AMOUNT_CLIPPED,1

FORMULA		.float	-244.4619926	;(6*256)/2PI  (convert radians to length of infinity plane)

LOWVAL		.float	-1536
HIGHVAL		.float	1536

LOIVAL		.word	-768
HIGHIVAL	.word	1536

INFPROJ		.float	0.0064
INFVAL		.float  80000
*
*
*
INFINITY:
	LDI	@_MODE,R0
	TSTB	MINTUNNEL,R0
	RETSNZ
	AND	MMODE,R0
	CMPI	MGAME,R0
	CALLEQ	FIND_HIGHEST_ROADY


	;KEEP CAMERARAD Y IN RANGE +-2 PI
	LDP	@_CAMERARAD
	LDF	@_CAMERARAD+Y,R2
	SETDP
	BLT	INFF0

	CMPF	@TWOPII,R2
	BLT	INFF1
INFF0
	SETDP
	CALL	NORMIT		     	;SAVE TRUNCATED VERSION
	LDP	@_CAMERARAD
	STF	R2,@_CAMERARAD+Y
	SETDP
INFF1
	STF	R2,@CAMRADY
	;



	;FIND HORIZON X OFFSET
	MPYF	@FORMULA,R2
	FIX	R2
	CMPI	@HIGHIVAL,R2
	BLT	OK23
	SUBI	@HIGHIVAL,R2
OK23

	CMPI	@LOIVAL,R2
	BGT	OK554
	ADDI	@HIGHIVAL,R2
OK554
	FLOAT	R2,R6		    	;R6 = HORIZON X OFFSET




	;REMOVE Y AXIS ROTATION FROM CAMERA MATRIX
	;
	;
	LDI	@MATRIXAI,AR2		;find_Ymatrix(&MATRIXA, -CAMERARAD.y);
	NEGF	@CAMRADY,R2		;concatmat(&MATRIXA, &CAMERAMATRIX, &MATRIXA);
	CALL	FIND_YMATRIX

	LDI	AR2,R3
	LDI	@CAMERAMATRIXI,R2
	CALL	CONCATMAT


	;GET Y HEIGHT OF CLIP ELEMENT
	LDF	@HIGHEST_ROADY,R0
	ADDF	25,R0
	LDF	@INFIN_CORRECT,R1
	ADDF	@SCRNHYI,R1
	SUBF	R1,R0
	LDFLT	0,R0

	LDI	@_MODE,R1
	AND	MMODE,R1
	CMPI	MGAME,R1
	LDFNE	0,R0
	STF	R0,@AMOUNT_CLIPPED

	;
	;a2c =  hsy - hy
	;0 - amount to clip


	;ROTATE INFINITY PLANE COORDS
	LDI	@INFINITY_POINTS,AR5
	LDI	@BLOWLISTI,AR6
	LDI	33,AR4
	CALL	TRANS_PTS



	LDI	sky1_p,AR2
	CALL	PAL_FIND
	LDI	R0,AR2

	LDP	@FIFO_ADDR,AR5
	LS	16,AR5
	LDI	@INFIN_POLYGONSI,AR0


	LDI	0FE00h,R4			;AIVI[0] = 0xff00
	LDI	00000h,R5			;AIVI[1] = 0x3800
	LDI	000FFh,R6			;AIVI[2] = 0x38FF
	LDI	0FEFFh,R7			;AIVI[3] = 0xffFF

	FIX	@AMOUNT_CLIPPED,R3


	LDI	11,AR4
	LDI	@BLOWLISTI,AR6

	LDI	0,AR1				;ML FIX
	LDP	@FIFO_STATUS
LOOP	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZ	LOOP
	SETDP


	LDI	TM,R0
	STI	R0,*AR5				;ACNTL = 0x900;

;optimize this, its the same palette ALWAYS
;
;
	LDI	*AR0++,AR2
	CALL	PAL_FIND
	STI	R0,*AR5       			;ACMAP


	;ORDER:  0,1,3,2

	LDI	@_MODE,R0
	TSTB	MWATER,R0
	BNZ	NOCLIPPING

	AND	MMODE,R0
	CMPI	MGAME,R0
	BNE	NOCLIPPING


	;
	;clip to horizon plane
	;
	;	A   B
	;	       e
	;	D   C
	;
	;
	;1.  find line equation for DC
	;
	PUSH	AR0
	PUSH	AR1
	PUSH	BK

	LDI	AR6,AR0			;C
	ADDI	9,AR0
	LDI	AR6,AR1			;D
	ADDI	6,AR1
	LDI	@VECTORAI,AR2
	CALL	GETLINE_EQ_2D

	;
	;2.  distance to line
	;
	LDI	AR2,AR0
	LDI	@VECTORCI,AR1
	LDF	@HIGHEST_ROADY_X,R0
	STF	R0,*+AR1(X)
	LDF	@HIGHEST_ROADY,R0
	STF	R0,*+AR1(Y)
	CALL	DIST_PT2LINE

	POP	BK
	POP	AR1
	POP	AR0

	;
	;3.  abort clipping attempt if no collision exists
	;

	LDF	R0,R0
	BLT	NOCLIPPING


	FIX	R0,R3		;amount to clip off each line

	;
	;compute BA slope
	;
	LDF	*+AR6(3),R0
	SUBF	*+AR6(0),R0
	LDF	*+AR6(4),R1
	SUBF	*+AR6(1),R1

	CMPF	0,R0
	BEQ	II33
	CMPF	0,R1
	BNE	II
II33	CLRF	R0
	BU	III44
II	CALL	DIV_F
III44	FIX	R0,R4


	FIX	*AR6,R0
	SUBI	R4,R0
	STI	R0,*AR5				;ARPS[0][0]
	FIX	*+AR6(1),R0
	SUBI	R3,R0
	STI	R0,*AR5				;ARPS[0][1]

	FIX	*+AR6(3),R0
	STI	R0,*AR5				;ARPS[1][0]
	FIX	*+AR6(4),R0
	STI	R0,*AR5				;ARPS[1][1]

	FIX	*+AR6(9),R0
	STI	R0,*AR5				;ARPS[2][0]
	FIX	*+AR6(10),R0
	STI	R0,*AR5				;ARPS[2][1]

	FIX	*+AR6(6),R0
	SUBI	R4,R0
	STI	R0,*AR5				;ARPS[3][0]
	FIX	*+AR6(7),R0
	SUBI	R3,R0
	STI	R0,*AR5				;ARPS[3][1]

	NOP	*AR6++(6)


	LDI	0FE00h,R4			;AIVI[0] = 0xff00

	LDI	R4,R0
	RS	8,R0
	SUBI	R3,R0
	LDI	R4,R1
	AND	0FFh,R1
	LS	8,R0
	OR	R0,R1
	STI	R1,*AR5				;AIV0

	STI	R5,*AR5				;AIV1
	STI	R6,*AR5				;AIV2


	LDI	R7,R0
	RS	8,R0
	SUBI	R3,R0
	LDI	R7,R1
	AND	0FFh,R1
	LS	8,R0
	OR	R0,R1
	STI	R1,*AR5				;AIV3
	LDI	*AR0++,R0
	STI	R0,*AR5				;ADDR

	LDP	@FIFO_INC
	LDI	@FIFO_INC,R0
	LDI	*AR1,R0	  		;ML FIX
	RPTS	4
	NOP
	SETDP
	DBU	AR4,LOOP

	BU	PLOT_CONSTANTS

*
*
*

NOCLIPPING
	;DUMP X
	FIX	*AR6,R0
	STI	R0,*AR5				;ARPS[0][0]
	FIX	*+AR6(1),R0
	STI	R0,*AR5				;ARPS[0][1]

	FIX	*+AR6(3),R0
	STI	R0,*AR5				;ARPS[1][0]
	FIX	*+AR6(4),R0
	STI	R0,*AR5				;ARPS[1][1]

	FIX	*+AR6(9),R0
	STI	R0,*AR5				;ARPS[2][0]
	FIX	*+AR6(10),R0
	STI	R0,*AR5				;ARPS[2][1]

	FIX	*+AR6(6),R0
	STI	R0,*AR5				;ARPS[3][0]
	FIX	*+AR6(7),R0
	STI	R0,*AR5				;ARPS[3][1]

	NOP	*AR6++(6)

	STI	R4,*AR5				;AIV0
	STI	R5,*AR5				;AIV1
	STI	R6,*AR5				;AIV2
	STI	R7,*AR5				;AIV3

	LDI	*AR0++,R0
	STI	R0,*AR5				;ADDR

	LDP	@FIFO_INC
	LDI	@FIFO_INC,R0
	LDI	*AR1,R0	  		;ML FIX
	RPTS	4
	NOP
	SETDP
	DBU	AR4,LOOP

PLOT_CONSTANTS

	;
	;CONSTANT COLOR POLYGONS
	;
	LDI	sky1_p,AR2
	CALL	PAL_FIND
	LDI	R0,AR2

	LDI	@INFIN_POLYGONSI,AR0
	LDI	2,AR4
	LDI	@BLOWLISTI,AR6
	ADDI	26*3,AR6

	LDI	0,AR1				;ML FIX

LOOP1A	LDP	@FIFO_STATUS
LOOP1	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZ	LOOP1
	SETDP

	LDI	30,R0			;CONSTANT COLOR = 1
	STI	R0,*AR5			;ACNTL 
	STI	AR2,*AR5   		;ACMAP

	;0,1,3,2

	;DUMP X
	FIX	*AR6,R0
	STI	R0,*AR5			;ARPS[0][0]
	FIX	*+AR6(1),R0
	STI	R0,*AR5			;ARPS[0][1]

	FIX	*+AR6(3),R1
	STI	R1,*AR5			;ARPS[1][0]
	FIX	*+AR6(4),R1
	STI	R1,*AR5			;ARPS[1][1]

	FIX	*+AR6(9),R2
	STI	R2,*AR5			;ARPS[2][0]
	FIX	*+AR6(10),R2
	STI	R2,*AR5			;ARPS[2][1]

	FIX	*+AR6(6),R3
	STI	R3,*AR5			;ARPS[3][0]
	FIX	*+AR6(7),R3
	STI	R3,*AR5			;ARPS[3][1]

	NOP	*AR6++(6)


	STI	R4,*AR5			;AIV0
	STI	R5,*AR5			;AIV1
	STI	R6,*AR5			;AIV2
	STI	R7,*AR5			;AIV3
	LDI	*AR0++,R0
	STI	R0,*AR5			;ADDR

	LDP	@FIFO_INC
	LDI	@FIFO_INC,R0
	LDI	*AR1,R0	  		;ML FIX
	SETDP
	DBU	AR4,LOOP1A


	LDI	@_MODE,R0
	TSTB	MWATER,R0
	CALLNZ	WATER_INFINITY

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
INFINITY_POINTS	.word	INFINPOINTS
INFINPOINTS
	.float	-1280,0,0
	.float	-1280,-255,0
	.float	-1024,0,0
	.float	-1024,-255,0
	.float	-768,0,0
	.float	-768,-255,0
	.float	-512,0,0
	.float	-512,-255,0
	.float	-256,0,0
	.float	-256,-255,0
	.float	0,0,0
	.float	0,-255,0
	.float	256,0,0
	.float	256,-255,0
	.float	512,0,0
	.float	512,-255,0
	.float	768,0,0
	.float	768,-255,0
	.float	1024,0,0
	.float	1024,-255,0
	.float	1280,0,0
	.float	1280,-255,0
	.float	1536,0,0
	.float	1536,-255,0
	.float	1792,0,0
	.float	1792,-255,0


	.float	-1280,-253,0
	.float	-1280,-1250,0

	.float	-300,-253,0
	.float	-300,-1250,0

	.float	700,-253,0
	.float	700,-1250,0

	.float	1700,-253,0
	.float	1700,-1250,0


INFIN_POLYGONSI	.word	BLUESKY
BLUESKY	.word	sky1_p,sky1_I,sky1_p,sky2_I,sky1_p,sky3_I,sky1_p,sky4_I,sky1_p,sky5_I,sky1_p,sky6_I
	.word	sky1_p,sky1_I,sky1_p,sky2_I,sky1_p,sky3_I,sky1_p,sky4_I,sky1_p,sky5_I,sky1_p,sky6_I
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*
*PARAMETERS
*	AR4	NUMBER OF VERTICES
*	AR5	POINTERS [X Y Z]
*	AR6	RAM BUFFER
*
*
*
	.bss	INFIN_CORRECT,1
TRANS_PTS:
;	LDF	@AMOUNT_CLIPPED,R4
	LDF	@INFIN_CORRECT,R7

;	FLOAT	8000,R0
;	MPYF	10,R0
;	LDP	@_CAMERARAD
;	LDF	@_CAMERARAD+X,R2
;	SETDP
;
;	CALL	DISTANCE_2D
;	LDLF	0.006401,R2
;	MPYF	R2,R0
;	ADDF	R0,R7
;	;R1 is distance


TRANS_LP
	LDI	@VECTORAI,AR2
	LDF	*AR5++,R0			;load src [X Y Z]
	ADDF	R6,R0				;add in X offset

	LDP	@HIGHVAL
	CMPF	@HIGHVAL,R0
	BLT	LKJ2
	SUBF	@HIGHVAL,R0
LKJ2
	STF	R0,*AR2++
	ADDF	R7,*AR5++,R0	 		;ADD IN HEIGHT DUDES !!!
	STF	R0,*AR2++
	LDF	*AR5++,R0
	STF	R0,*AR2--(2)

	LDI	AR6,R3
	LDP	@MATRIXAI
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

	LDF	*AR6,R0
	LDP	@SCRNHXI
	ADDF	@SCRNHXI,R0
	STF	R0,*AR6++
	LDF	*AR6,R0
	MPYF	1.04,R0
	LDP	@SCRNHYI
	ADDF	@SCRNHYI,R0

	STF	R0,*AR6++(2)
	DEC	AR4

	LDI	@VECTORAI,AR2
	LDF	*AR5++,R0			;load src [X Y Z]
	ADDF	R6,R0				;add in module offset

	LDP	@HIGHVAL
	CMPF	@HIGHVAL,R0
	BLT	LKJ25
	SUBF	@HIGHVAL,R0

LKJ25
	STF	R0,*AR2++
	ADDF	R7,*AR5++,R0	 		;ADD IN HEIGHT DUDES !!!
	STF	R0,*AR2++
	LDF	*AR5++,R0
	STF	R0,*AR2--(2)

	LDI	AR6,R3
	LDP	@MATRIXAI
	LDI	@MATRIXAI,R2
	CALL	MATRIX_MUL

	LDF	*AR6,R0
	LDP	@SCRNHXI
	ADDF	@SCRNHXI,R0
	STF	R0,*AR6++
	LDF	*AR6,R0
	MPYF	1.04,R0
	LDP	@SCRNHYI
	ADDF	@SCRNHYI,R0

	STF	R0,*AR6++(2)


	DBU	AR4,TRANS_LP

	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*DISPLAY THE WATER TO THE SCREEN
*
*THIS MUST BE CALLED AFTER INFINITY
*
WATER_INFINITY:

	LDF	@CAMRADY,R2

	;FIND HORIZON X OFFSET
	MPYF	@FORMULA,R2

	FIX	R2
	LDP	@HIGHIVAL
	CMPI	@HIGHIVAL,R2
	BLT	ok23a
	SUBI	@HIGHIVAL,R2
ok23a

	LDP	@LOIVAL
	CMPI	@LOIVAL,R2
	BGT	ok24a
	ADDI	@HIGHIVAL,R2
ok24a

	FLOAT	R2,R6		    	;R6 = HORIZON X OFFSET


	;REMOVE Y AXIS ROTATION FROM CAMERAERSE MATRIX
	;
	;
	LDI	@MATRIXAI,AR2		
	NEGF	@CAMRADY,R2		;find_Ymatrix(&MATRIXA, -CAMERARAD.y);
	PUSH	AR2			;concatmat(&MATRIXA, &CAMERAMATRIX, &MATRIXA);
	CALL	FIND_YMATRIX
	POP	AR2
	LDI	AR2,R3
	LDP	@CAMERAMATRIXI
	LDI	@CAMERAMATRIXI,R2
	CALL	CONCATMAT


	;GET Y HEIGHT OF INFINITY PLANE
	LDP	@_MATRIXA			;GET HEIGHT OF HORIZON AT INFINITY
	LDF	@_MATRIXA+5,R7		
	MPYF	64,R7				;MULTIPLY X 512
	MPYF	8,R7				;A7 = HEIGHT

	LDP	@_CAMERAMATRIX
	LDF	@_CAMERAMATRIX+7,R2  		;GET ZVECT(Y)
	LDF	@_CAMERAMATRIX+4,R1  		;GET YVECT(Y)
	SETDP
	LDP	@INFVAL
	MPYF	@INFVAL,R0
	CALL	DIV_F

	LDP	@INFPROJ
	MPYF	@INFPROJ,R0
	LDF	R0,R7
	NEGF	R7


	;ROTATE INFINITY PLANE COORDS
	LDI	@WATERPOSI,AR5
	LDI	@BLOWLISTI,AR6
	LDI	26,AR4
	CALL	TRANS_PTS




	LDI	wtra_p,AR2
	CALL	PAL_FIND
	LDI	R0,AR2

	LDP	@FIFO_ADDR,AR5
	LS	16,AR5

	LDI	0AD00h,R4			;AIVI[0] = 0xff00
	LDI	00100h,R5			;AIVI[1] = 0x3800
	LDI	001FFh,R6			;AIVI[2] = 0x38FF
	LDI	0ADFFh,R7			;AIVI[3] = 0xffFF

	LDI	11,AR4
	LDI	@BLOWLISTI,AR6


	LDP	@FIFO_STATUS
	LDI	0,AR1				;ML FIX (BOGUS READ)
LOOPA	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZ	LOOPA
	SETDP


	LDI	TM,R0
	STI	R0,*AR5				;ACNTL = 0x900;
	STI	AR2,*AR5       			;ACMAP


	;0,1,3,2

	;DUMP X
	FIX	*AR6,R0
	STI	R0,*AR5				;ARPS[0][0]
	FIX	*+AR6(1),R0
	LDI	400,R0
	STI	R0,*AR5				;ARPS[0][1]

	FIX	*+AR6(3),R0
	STI	R0,*AR5				;ARPS[1][0]
	FIX	*+AR6(4),R0
	STI	R0,*AR5				;ARPS[1][1]

	FIX	*+AR6(9),R0
	STI	R0,*AR5				;ARPS[2][0]
	FIX	*+AR6(10),R0
	STI	R0,*AR5				;ARPS[2][1]

	FIX	*+AR6(6),R0
	STI	R0,*AR5				;ARPS[3][0]
	FIX	*+AR6(7),R0
	LDI	400,R0
	STI	R0,*AR5				;ARPS[3][1]
	NOP	*AR6++(6)

	STI	R4,*AR5				;AIV0
	STI	R5,*AR5				;AIV1
	STI	R6,*AR5				;AIV2
	STI	R7,*AR5				;AIV3
	LDIL	wtra_I,R0
	STI	R0,*AR5				;ADDR

	LDP	@FIFO_INC
	LDI	@FIFO_INC,R0
	LDI	*AR1,R0	  			;ML FIX (BOGUS READ)
	SETDP

	RPTS	4
	NOP

	DBU	AR4,LOOPA
	RETS



WATERPOSI	.word	WATERPOS
WATERPOS

	.float	-1280,128,0
	.float	-1280,0,0
	.float	-1024,128,0
	.float	-1024,0,0
	.float	-768,128,0
	.float	-768,0,0
	.float	-512,128,0
	.float	-512,0,0
	.float	-256,128,0
	.float	-256,0,0
	.float	0,128,0
	.float	0,0,0
	.float	256,128,0
	.float	256,0,0
	.float	512,128,0
	.float	512,0,0
	.float	768,128,0
	.float	768,0,0
	.float	1024,128,0
	.float	1024,0,0
	.float	1280,128,0
	.float	1280,0,0
	.float	1536,128,0
	.float	1536,0,0
	.float	1792,128,0
	.float	1792,0,0
*----------------------------------------------------------------------------
	.END
