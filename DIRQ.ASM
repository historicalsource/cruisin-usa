	.FILE	"DIRQ.ASM"
*v7.03
*----------------------------------------------------------------------------
*DISPLAY/TRANSFORMATION SYSTEM
*
*COPYRIGHT (C) 1994  BY TV GAMES, INC.
*ALL RIGHTS RESERVED
*
*
*	Eric L Pribyl
*	Eugene P. Jarvis
*	
*	1.0	JUL 91	ELP	Original version	May 30, 1991
*	2.00    NOV 91  EPJ     HEAVY OPTIMIZATIONS
*	2.01	DEC 91  ELP	PComp support
*	2.10	MAR 92  ELP/EPJ	Altering for target,Optimizations
*	3.00	MAY 92  ELP	Modification for Illumination models
*	3.01	MAY 92  ELP	POLYGON PLOT OPTIMIZATIONS
*	3.02	AUG 92  ELP	Mods for reality
*	3.03	AUG 92  ELP	Sorting removed
*	3.04	SEP 92  ELP	FIFO, single palette added, optimizations
*	3.05	OCT 92	ELP	no control panel,dithering,centroid remove
*	3.06	OCT 92	ELP	Dynamic objects added
*	4.00	DEC 92	EPJ/ELP	dynamic optimizations and data structure alterations
*	4.01	JAN 93	ELP	Illuminated, TMed Objects
*	5.00	JUL 93	ELP	DMA ASIC
*	5.01	JUL 93	ELP	Direct stuff to DMA
*	6.00	JUL 93	ELP	Removal of Direct Stuff to DMA (copy in 'dirqnfif.asm')
*				.	statistics added
*				.	optimization
*	6.01	AUG 93	ELP	Compressed Polygon Format & Compressed Vertex Format
*	7.00	OCT 93  ELP	test case for 2D rotations
*	7.01	NOV 93  ELP	full blown 2D rotations
*	7.02	APR 94	ELP	true operation for O_NOUROT
*	7.03	JUL 94  ELP	DPs removed, statistics optional
*	7.04	SEP 94  EPJ	GLITCH FIX
*
*IN ALL ROUTINES
*	AR0 - OBJECT BLOCK
*	AR1 - ROM POINTER
*
*


	.include	C30.EQU
	.include	VUNIT.EQU
	.include	MPROC.EQU
	.include	MACS.EQU
	.include	OBJ.EQU
	.include	SYS.EQU
	.include	DIRQ.EQU
	.include	SYSID.EQU
	.include	GLOBALS.EQU



	.text
*----------------------------------------------------------------------------
POSTERCLIP		.set	300
LOW_CLIP_LEVEL		.set	100
HIGH_CLIP_LEVEL		.set	(5000-1)		;ACTUAL # OF ENTRIES


OACTIVEI		.word	OACTIVE
IDLE_LISTI		.word	IDLE_LIST
OACTIVE_PRIORITYI	.word	OACTIVE_PRIORITY
OLOW_PRIORITYI		.word	OLOW_PRIORITY
	.globl	OHIGH_PRIORITYI
OHIGH_PRIORITYI		.word	OHIGH_PRIORITY

CAMERAPOSI		.word	_CAMERAPOS
CAMERARADI		.word	_CAMERARAD
CAMERAMATRIXI		.word	_CAMERAMATRIX

ASHADOW			.word	_ACNTL		;HEADS UP THE FIFO MIRROR
LIGHTIY			.word	_LIGHT+1

LOCTEMPER_MATI		.word	LOCTEMPER_MAT
transmatrixI		.word	ROTATION_MATRIX
transvectorYI		.word	TRANSVECTOR+1
POSTERMATI		.word	POSTERMATRIX
POSTERMAT2DI		.word	POSTERMATRIX2D

BLOWLISTI		.word	BLOWLIST
tmpmatI			.word	TMPMAT
tmpmatY			.word	TMPMAT+1
INVTABI			.word	INVTAB

SCRNHXI			.float	SCRNHX
SCRNHYI			.float	SCRNHY

HIGH_CLIP_LEV8		.word	80000		;MATHEMATICAL LIMIT


DRIVE_LISTI		.word	DRIVE_LIST
CAR_LISTI		.word	CAR_LIST
SIGN_LISTI		.word	SIGN_LIST
GROUND_LISTI		.word	GROUND_LIST

MATRIXAI		.word	_MATRIXA
MATRIXBI		.word	_MATRIXB
MATRIXCI		.word	_MATRIXC
VECTORAI		.word	_VECTORA
VECTORBI		.word	_VECTORB
VECTORCI		.word	_VECTORC
VECTORDI		.word	_VECTORD
VECTORAYI		.word	_VECTORA+1

_PALLISTI		.word	_PALLIST
FASTSTKI		.word	FASTSTK

	fbss	POSTERMATRIX2D,4


*----------------------------------------------------------------------------
*DIRQ
*
*This is the main display loop which queues up each object list to be sent
*to DISPLAY, and performs any nessesary leg work.
*
*	In essence:
*	for all objects		   <--|
*		trivial rejection  ---|
*		translate vectors
*		plot polygons  <---|
*			hsr    ----|
*			send to asic
*		next polygon
*	next object
*
DIRQ:
	PUSH	R4
	LDI	@SYSCNTL,R0		;if the system hangs and the LED
	OR	LED_OFF,R0		;is on we were in this routine
	STI	R0,@SYSCNTL		;when it happened
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR
	SETDP

	LDI	@POSTERMATI,AR2		;find the inverse Y rotation matrix "poster matrix"
	LDP	@_CAMERARAD+Y
	NEGF	@_CAMERARAD+Y,R2
	SETDP
	CALL	FIND_YMATRIX
	LDI	@POSTERMATI,AR2
	LDI	AR2,R3
	LDI	@CAMERAMATRIXI,R2
	CALL	CONCATMAT

	LDI	@POSTERMAT2DI,AR0
	LDF	*+AR2(A00),R0
	STF	R0,*+AR0(0)
	LDF	*+AR2(A02),R0
	STF	R0,*+AR0(1)
	LDF	*+AR2(A20),R0
	STF	R0,*+AR0(2)
	LDF	*+AR2(A22),R0
	STF	R0,*+AR0(3)


	.if	STATISTICS
	LDI	0,R1	      		;ZERO OUT YOUR STATS DUDES
	STI	R1,@ST_OBJECTS
	STI	R1,@ST_POLYGONS
	.endif

	LDI	@OLOW_PRIORITYI,AR0
	CALL	DISPLAY

	SETDP
	LDI	@OACTIVEI,AR0		;setup pointer
	CALL	DISPLAY

	SETDP
	LDI	@OACTIVE_PRIORITYI,AR0
	CALL	DISPLAY

	SETDP
	LDI	@OHIGH_PRIORITYI,AR0
	CALL	DISPLAY

	SETDP
	LDI	@SYSCNTL,R0
	ANDN	LED_OFF,R0
	STI	R0,@SYSCNTL
	LDP	@SYSCNTLR
	STI	R0,@SYSCNTLR
	SETDP

	POP	R4
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*DISPLAY
*
*This routine displays the linked list pointed to in AR0.  Almost all
*registers are clobbered.
*
*In general the following registers are dedicated
*AR0	OBJECT POINTER
*AR1	ROM POINTER
*
*
*
*	int	radius
*	int	number_of_vertices|(number_of_polygons<<16)
*	struct ROM_VERTEX  {
*		int	X|Y<<16
*		int	Z
*	} * number_of_vertices
*	struct ROM_POLYGON  {
*		int	palnum<<16|cntl
*		int	(v4<<24)|(v3<<16)|(v2<<8)|(v1)
*		int	IV[0]|(IV[1]<<16)
*		int	IV[2]|(IV[3]<<16)
*		int	*addr_to_TM;
*	}
*
*NOTE	entry point is near the bottom of the routine
*
	.bss	BREAKOBJ,1
NEXTOBJ:
	LDI	R0,AR0
	SETDP

	LDI	@BREAKOBJ,R1
	BZ	NOBREAK_CONTINUE
	CMPI	R1,R0
	BEQ	$
NOBREAK_CONTINUE

	.if	STATISTICS
	LDI	@ST_OBJECTS,R1
	INC	R1
	STI	R1,@ST_OBJECTS
	.endif

*GENERATE TRANSLATION VECTOR

	LDI	R0,AR3			;transform the objects position
	LDI	*+AR0(OFLAGS),R6	;holds the OBJECTS flags
	LDI	*+AR0(OROMDATA),AR1	;get the romptr

	TSTB	O_NOUNIV,R6		;has this object have an absolute distance from
	BZD	TRU_UNIV		;CAMERAPOS or is it a regular object
	ADDI	OPOSX,AR3		;for the CAMERAMATRIX
	LDI	@CAMERAPOSI,AR6		;universe_center
	LDI	@tmpmatI,AR4		;trans = object_pos + univ_pos
	;---->BZ TRU_UNIV

	BUD	TRANS_RET		;this object has an absolute distance from
	LDF	*AR3++,R3		;the cemeras position therefore its relative
	LDF	*AR3++,R4		;position in our calculations does not change
	LDF	*AR3++,R5		;

TRU_UNIV
	SUBF	*AR6++,*AR3++,R3	;*trans++ = *tp++ - *up++ 
	SUBF	*AR6++,*AR3++,R4	;*trans++ = *tp++ - *up++ 
	SUBF	*AR6++,*AR3++,R5	;*trans++ = *tp++ - *up++ 

TRANS_RET

	TSTB	O_NOUROT,R6		;is this object NOT rotatable by the CAMERAMATRIX?
	BZD	UNIV_ROT		;BR -> it is

	LDI	@CAMERAMATRIXI,AR5	;src 3x3
	LDI	@transvectorYI,AR6	;dst 1x3
	NOP
	;---->BZ UNIV_ROT

*SPECIAL CASE WHEN WE WANT SOMETHING NOT ROTATED BY THE
*UNIVMATRIX  (it has absolute coordinates)

	STF	R3,*-AR6(1)		;TRANSVECTOR.x
	BUD	TRIVIAL_REJECTION
	STF	R4,*AR6			;TRANSVECTOR.y
	LDF	R5,R2			;Z value
	ADDI	9,AR5
	;---->	BUD	TRIVIAL_REJECTION

;***	TRIVIAL REJECTION AND TRANSLATION VECTOR

	;AR4	objects position   X,Z
	;AR5	univmatrix   *SAVE*
	;AR6	TRANSLATION VECTOR FOR OBJECT

	;R3	x value of position
	;R4	y value of position
	;R5	z value of position
*
*ALTERNATE STRATEGY OPERATE ON X,Y,Z IN R3,R4,R5
*LOSE SOME PARALLEL MULTS (5 INST.), BUT GAIN ON NOT USING AR4 (4 INST.)
*MULTIPLY WOULD BECOME REPEAT BLOCK LOOP (RUN FASTER IF PROG NOT IN FAST RAM)

*
*ROTATE OBJECTS POSITION BY CAMERAS MATRIX
*
UNIV_ROT:				;COMPUTE  (TRANSVECTOR <- * CAMERAMATRIX)
	MPYF3	*AR5++,R3,R0
 ||	STF	R3,*AR4			;SAVE X VECTOR VALUE (TMPMAT.x)
	MPYF3	*AR5++,R4,R1
 ||	STF	R5,*+AR4(1)		;SAVE Z VECTOR VALUE (TMPMAT.z)
	MPYF3	*AR5++,*+AR4(1),R1
 ||	ADDF3	R0,R1,R2

	MPYF3	*AR5++,*AR4,R0
 ||	ADDF3	R1,R2,R2
	MPYF3	*AR5++,R4,R1
 ||	STF	R2,*-AR6(1)		;(TRANSVECTOR.x)
	MPYF3	*AR5++,*+AR4(1),R1
 ||	ADDF3	R0,R1,R2

	MPYF3	*AR5++,*AR4,R0
 ||	ADDF3	R1,R2,R2
	MPYF3	*AR5++,R4,R1
 ||	STF	R2,*AR6			;(TRANSVECTOR.y)
	MPYF3	*AR5++,*+AR4(1),R1
 ||	ADDF3	R0,R1,R2
	ADDF	R1,R2

*
*CHECK FOR TRIVIAL REJECTION
*
TRIVIAL_REJECTION:

	TSTB	O_DEGRADE,R6		;does this have a degrade model?
	BZD	NO_DEGRADE
	STF	R2,*+AR6(1)		;(TRANSVECTOR.z) R2 = Z value of object	
	FIX	R2			;convert Z distance to integer
	STI	R2,*+AR0(ODIST)
	;---->BZ NO_DEGRADE

	CMPI	DEGRADE_DIST,R2
	LDIGT	*+AR0(ODEGRADE_ROM),AR1	;if its far enough to degrade it

	TSTB	O_DEGRADE2,R6
	BZ	NO_DEGRADE		;LEVEL 2
	CMPI	DEGRADE_DIST_LEVEL2,R2
	LDIGT	*+AR0(ODEGRADE_ROM2),AR1	;if its far enough to degrade it to level 2

NO_DEGRADE
	LDI	*AR1++,R4		;get RADIUS of object
	ADDI	R2,R4,R3

	CMPI	LOW_CLIP_LEVEL,R3	;attempt to toss on Z distance
	BLTD	DISPLAY			;is it to close?

	SUBI	R4,R3
	SUBI	R4,R3
	CMPI	@HIGH_CLIP_LEV8,R3
	;----> BLTD	DISPLAY
	BGTD	DISPLAY

	ADDI	R4,R3
	LDIN	0,R3			;KEEP IT IN RANGE
	LSH	-4,R3			;quickly divide by 16
	;---->BGT DISPLAY

	CMPI	HIGH_CLIP_LEVEL,R3	;KEEP INDEX IN RANGE
	LDIGT	HIGH_CLIP_LEVEL,R3
	LDI	R3,AR3
	ADDI	@INVTABI,AR3

	FLOAT	R4			;RADIUS must be positive
	LDF	*AR3,R1			;get the inverse Z factor
	MPYF	R1,R4			;project RADIUS for distance
	
	MPYF	*AR6,R1,R3		;project Y position
	ADDF	R4,R3,R2
	ADDF	@SCRNHYI,R2
	BLTD	DISPLAY			;BR-> above the screen

	NOP				;PAD FOR DELAYED BRANCH
	SUBF	R4,R3
	CMPF	@SCRNHYI,R3
	;---->BLT DISPLAY
	BGTD	DISPLAY			;BR-> below the screen

	MPYF	*-AR6(1),R1,R3	   	;project X position
	ADDF	R4,R3,R2
	ADDF	@SCRNHXI,R2
	;---->BGT DISPLAY
	BLTD	DISPLAY			;BR-> too far to the left

	NOP			   	;PAD FOR DELAYED BRANCH
	SUBF	R4,R3
	CMPF	@SCRNHXI,R3
	;---->BLT DISPLAY
	BGTD	DISPLAY			;BR-> too far to the right

	;***
	;***	END TRIVIAL REJECTION, WE CAN PROBABLY SEE IT
	;***


	;
	;jump to 2D altering
	;
	LDI	OMATRIX,AR4
	ADDI	AR0,AR4
	LDI	*+AR0(OFLAGS),R0
	;---->BGT DISPLAY			;(object is not being seen)

	TSTB	O_DYNAMIC,R0
	BNZ	ROT3D
	TSTB	O_ILLUM,R0
	BNZ	ROT3D

	RS	(O_3DROT_B+1),R0
	BC	ROT3D

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MGAME,R0
	BNE	ROT3D

	LDI	@CAMVIEW,R0
	BNZ	TRANS2D
ROT3D


	;***
	;***	GENERATE ROTATION MATRIX
	;***


	;***
	;***	TEST FOR SPECIAL ROTATION CASES
	;***

	TSTB	O_NOUROT,R6		;is this object NOT rotatable by the CAMERAMATRIX?
	BZ	CHECKTHEREG

	TSTB	O_ILLUM,R6		;kludge for illuminated objects
	BNZ	CHECKTHEREG		;fix in next system

	LDI	AR0,AR5
	ADDI	OMATRIX,AR5
	BU	VT


CHECKTHEREG

*O_POSTER
*A poster matrix is oriented by the X/Z in the universe, but is not
*rotated by Y.  Simply put:  a poster is an object in the universe
*that is always facing the user. -> a poster.

	TSTB	O_POSTER,R6
	BZ	REGULAR

	FLOAT	POSTERCLIP,R0
	CMPF	*+AR6(1),R0		;CHECK IF TOO CLOSE
	
	BLED	VT		 	;CLIP OUT POSTERS IF TOO CLOSE
	NOP
	LDI	@POSTERMATI,AR5
	NOP
	;---> BLED VT
	B	DISPLAY


REGULAR
	LDI	@transmatrixI,AR3
	TSTB	O_NOROT,R6		;if this object is not self-orienting
	BZD	SELF_ORIENTING		;we can save on computations by skipping the concat

	LDI	5,IR1
	LDI	3,IR0
	NOP	*--AR5(9)		;RESTORE AR5 = UNIVMATRIX
	;---->BZ NOW

	TSTB	O_IROT,R6
	BNZ	IDENTITY_ROTATION

*O_IROT		IDENTITY_ROTATION
*THE OBJECT IS NOT SELF-ORIENTING, THEREFORE WE MAY SIMPLY COPY
*THE CAMERA MATRIX INTO THE GENERAL ROTATIONAL MATRIX

	BUD	VT
	NOP
	LDI	@CAMERAMATRIXI,AR5
	NOP
	;---->BU VT

*in this case identity rotation means that it CAN be self rotating, that is 
*entirely dependant on the matrix of the object
IDENTITY_ROTATION
	LDI	AR0,AR5
	ADDI	OMATRIX,AR5
	BU	VT



*STANDARD ROTATIONAL CASE
*
*Concatenate two 3x3 matrixes
*	AR4	- src1		(usually the objects matrix)
*	AR5	- src2		(usually the Cameras matrix)
*	AR3	- dst		(the GRM - general rotational matrix)
*
*A B C	   J K L    AJ+DK+GL BJ+EK+HL CJ+FK+IL
*D E F	*  M N O  = AM+DN+GO BM+EN+HO CM+FN+IO
*G H I     P Q R    AP+DQ+GR BP+EQ+HR CP+FQ+IR
*
SELF_ORIENTING:
	LDI	2,RC				;LOOP THREE TIMES
	RPTB	INLP1

	MPYF3	*AR5++(1),*AR4++(IR0),R0
	MPYF3	*AR5,*AR4++(IR0),R1
	MPYF3	*+AR5(1),*AR4--(IR1),R1
 ||	ADDF3	R0,R1,R2


	MPYF3	*-AR5(1),*AR4++(IR0),R0
 ||	ADDF3	R1,R2,R2
	MPYF3	*AR5,*AR4++(IR0),R1
	STF	R2,*AR3++(1)			;store MATij
	MPYF3	*+AR5(1),*AR4--(IR1),R1
 ||	ADDF3	R0,R1,R2


	MPYF3	*-AR5(1),*AR4++(IR0),R0
 ||	ADDF3	R1,R2,R2
	MPYF3	*AR5++,*AR4++(IR0),R1
	STF	R2,*AR3++(1)			;store MATij
	MPYF3	*AR5++,*AR4--(IR1),R1
 ||	ADDF3	R0,R1,R2
	ADDF	R1,R2

	STF	R2,*AR3++(1)			;store MATij
INLP1	NOP	*--AR4(3)




	;***
	;***	VECTOR ROTATION/TRANSLATION
	;***
VECTOR_TRANSFORMATION:

	LDI	*+AR0(OFLAGS),R0
	TSTB	O_DYNAMIC,R0
	BNZ	DYNAMIC_OBJECT


VECTORTRANSFULL				;return on dynamic objects

	LDI	@transmatrixI,AR5	;somewhat dedicated for matrix pointer
VT
	LDI	*AR1++,RC		;get number of vertices to translate-1
	PUSH	RC
	AND	0FFh,RC


	.if	STATISTICS
	LDI	@ST_VERTICES,R0
	ADDI	RC,R0
	ADDI	1,R0
	STI	R0,@ST_VERTICES
	.endif


	LDI	@BLOWLISTI,AR3		;blowlist pointer = AR3
	LDI	@tmpmatY,AR4		;TEMP VECTOR STORE
	LDI	@INVTABI,AR2		;inverse table dedicated ptr
	LDI	8,IR0
	FLOAT	SCREENHX,R6		;screen half x
	LDI	-16,BK


	BD	VTL
	FLOAT	SCREENHY,R7		;screen half x
	LDF	*-AR6(1),R4		;GET X TRANS
	LDF	*AR6,R5			;GET Y TRANS
	;---->BR 	VTL
	.align 
VTL
	RPTB	EOVCTR

	;;MATRIX MULTIPLY 1x3 * 3x3 -> blowspace
	;AR0	object ptr		PRELOADED *SAVE*
	;AR1	rom ptr			PRELOADED *INC*
	;AR2	inverse table
	;AR3	BLOWLIST ptr	
	;AR4	TEMP VERTEX STORE
	;AR5	rotation matrix ptr	PRELOADED *SAVE*
	;AR6	translation vector	PRELOADED *SAVE*
	;AR7	

	;R0,R1  TEMP
	;R2	y element/tmp value
	;R3	x element/tmp value
	;R4	X TRANS
	;R5	Y TRANS
	;R6	X SCREEN CENTER
	;R7	Y SCREEN CENTER

	;
	;  A	   D E F       AD+BE+CF
	;[ B ] * [ G H I ] = [ AG+BH+CI	]
	;  C	   J K L       AJ+BK+CL
	;



*FOR PACKED INT
	LDI	*AR1++,R3
	ASH	BK,R3,R2    		;BK=16
	LS	16,R3
	ASH	BK,R3
	FLOAT	R3			; x element			
	FLOAT	R2			; y element
	STF	R3,*-AR4(1)		;store secondary access A
	FLOAT	*AR1++,R0		;C	get z element of source 1
 ||	STF	R2,*AR4			;store secondary access B


	;
	;MULTIPLY BY ROTATION MATRIX
	;
	MPYF3	*AR5++,R3,R0		;AD
 ||	STF	R0,*+AR4(1)  		;store secondary access C
	MPYF3	*AR5++,R2,R1		;BE
	MPYF3	*AR5++,*+AR4(1),R1	;CF
 ||	ADDF3	R0,R1,R3		;AD+BE

	MPYF3	*AR5++,*-AR4(1),R0	;AG
 ||	ADDF3	R1,R3,R3		;AD+BE+CF
	MPYF3	*AR5++,R2,R1		;BH
 ||	STF	R3,*AR3++ 		;*BLOWLIST++ = [AD+BE+CF];STORE ROTATED X

	MPYF3	*AR5++,*+AR4(1),R1	;CI
 ||	ADDF3	R0,R1,R3		;AG+BH

	MPYF3	*AR5++,*-AR4(1),R0	;AJ
 ||	ADDF3	R1,R3,R3		;AG+BH+CI

	MPYF3	*AR5++,*AR4,R1		;BK

	MPYF3	*AR5--(IR0),*+AR4(1),R1	;CL
 ||	ADDF3	R0,R1,R2		;AJ+BK
	ADDF	R1,R2			;AJ+BK+CL
	ADDF	*+AR6(1),R2		;add in translation into [AJ+BK+CL]

	LDF	*-AR3(1),R1		;GET BACK NEW X
 ||	STF	R2,*+AR3(1)		;SAVE NEW Z

	FIX	R2,IR1			;find z distance for inverse lookup

	ASH	-4,IR1			;quickly divide by 16

	CMPI	HIGH_CLIP_LEVEL,IR1   	;compare against highest clip level
	LDIGE	HIGH_CLIP_LEVEL,IR1    	;max it at highest clip level

	CMPI	-80,IR1
	LDILT	-80,IR1

	ADDF	R4,R1			;ADD X TRANSLATION
	ADDF	R5,R3			;add Y translation 

	MPYF	*+AR2(IR1),R1,R0    	;x = (x * inverse [z])
	ADDF	R6,R0			;    + SCRNHX 	       ;(screen half x)

	MPYF	*+AR2(IR1),R3,R0	;y = (y * inverse [z])
 ||	STF	R0,*-AR3(1)

	MPYF	1.04,R0			; below 1.0 shrinks Y, above expands Y
	ADDF	R7,R0			;    + SCRNHY	       ;(screen half y)
EOVCTR	STF	R0,*AR3++(2)
	;34 Instructions

POLYPOLY_ENTER

	POP	BK
	RS	16,BK
	CALL	PLOTPOLY

DISPLAY:
	LDI	*AR0,R0
	BNZ	NEXTOBJ

DISPLAYX
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
TRANS2D:
	;***
	;***	GENERATE ROTATION MATRIX
	;***
	ADDI	1,AR4
	LDI	@transmatrixI,AR3
	NOP	*--AR5(8)		;RESTORE AR5 = UNIVMATRIX


	TSTB	O_POSTER,R6
	BZ	REGULAR1

	FLOAT	POSTERCLIP,R0
	CMPF	*+AR6(1),R0		;CHECK IF TOO CLOSE
	
	BLED	VT2		 	;CLIP OUT POSTERS IF TOO CLOSE
	NOP
	LDI	@POSTERMAT2DI,AR5
	NOP
	;---> BLED VT2
	B	DISPLAY

REGULAR1

*STANDARD ROTATIONAL CASE
*	AR4	- src1		(usually the objects matrix)
*	AR5	- src2		(usually the Cameras matrix)
*	AR3	- dst		(the GRM - general rotational matrix)
*
*We generate a 2D matrix (packed) via two psuedo-2d matrices
*
*A x C	   J x L    AJ+GL  CJ+IL
*x x x	*  x x x  = 
*G x I     P x R    AP+GR  CP+IR
*
*		1 offset
*00 = 0		-1
*20 = 6		 5
*02 = 2		 1
*22 = 8		 7
*
SELF_ORIENTING2:
	LDI	5,IR0
	LDI	7,IR1

	MPYF	*-AR5(1),*-AR4(1),R0	;(AJ)
	MPYF	*+AR5(IR0),*+AR4(1),R1	;(GL)
	ADDF	R0,R1			;(AJ+GL)
	STF	R1,*AR3++

	MPYF	*+AR5(1),*-AR4(1),R0	;(CJ)
	MPYF	*+AR5(IR1),*+AR4(1),R1	;(IL)
	ADDF	R0,R1			;(CJ+IL)
	STF	R1,*AR3++

	MPYF	*-AR5(1),*+AR4(IR0),R0	;(AP)
	MPYF	*+AR5(IR0),*+AR4(IR1),R1 ;(GR)
	ADDF	R0,R1			;(AP+GR)
	STF	R1,*AR3++

	MPYF	*+AR5(1),*+AR4(IR0),R0	;(CP)
	MPYF	*+AR5(IR1),*+AR4(IR1),R1 ;(IR)
	ADDF	R0,R1			;(CP+IR)
	STF	R1,*AR3++
	;END MATRIX MULTIPLY


	;***
	;***	VECTOR ROTATION/TRANSLATION
	;***
VECTOR_TRANSFORMATION2:

	LDI	@transmatrixI,AR5	;somewhat dedicated for matrix pointer
VT2
	LDI	*AR1++,RC		;get number of vertices to translate-1
	PUSH	RC
	AND	0FFh,RC			;NUM VERTICES

	LDI	@BLOWLISTI,AR3		;blowlist pointer = AR3
	LDI	@tmpmatY,AR4		;TEMP VECTOR STORE
	LDI	@INVTABI,AR2		;inverse table dedicated ptr

	BD	VTL2
	FLOAT	SCREENHX,R6		;screen half x
	LDI	3,IR0
	LDI	-16,BK
	;---->BR 	VTL2
	.align 
VTL2
	RPTB	EOVCTR2

	LDI	*AR1++,R3
	ASH	BK,R3,R7    		;
	LS	16,R3
	ASH	BK,R3
	FLOAT	R3			;(A)  R3 <- X element
	FLOAT	R7			;     R2 <- Y element  (TRANSLATED ONLY)
	FLOAT	*AR1++,R0		;(B)  R0 <- z element

	;
	;MULTIPLY BY 2x2 ROTATION MATRIX
	;
	MPYF	*AR5++,R3,R2		;(AD)
	MPYF	*AR5++,R0,R1		;(BE)
 ||	ADDF	*-AR6(1),R2		;add in translation into [AJ+BK+CL]
	ADDF	R2,R1

	MPYF	*AR5++,R3,R3		;(AD)
 ||	STF	R1,*AR3++ 		;*BLOWLIST++ = ROTATED X (skip Y element)
	MPYF	*AR5--(IR0),R0		;(BE)
 ||	ADDF	*+AR6(1),R3		;add in Z translation
	ADDF	R3,R0
	ADDF	*AR6,R7			;add in Y translation into [AJ+BK+CL]
 ||	STF	R0,*+AR3(1) 		;*BLOWLIST++ = ROTATED Z

	FIX	R0,IR1			;find z distance for inverse lookup
	ASH	-4,IR1			;quickly divide by 16

	CMPI	HIGH_CLIP_LEVEL,IR1   	;compare against highest clip level
	LDIGE	HIGH_CLIP_LEVEL,IR1    	;max it at highest clip level

	CMPI	-80,IR1
	LDILT	-80,IR1

	MPYF	*+AR2(IR1),R1,R0    	;x = (x * inverse [z])
	ADDF	R6,R0			;    + SCRNHX 	       ;(screen half x)

	MPYF	*+AR2(IR1),R7,R0	;y = (y * inverse [z])
 ||	STF	R0,*-AR3(1)

	MPYF	1.04,R0			; below 1.0 shrinks Y, above expands Y
	ADDF	@SCRNHYI,R0		;    + SCRNHY	       ;(screen half y)
EOVCTR2	STF	R0,*AR3++(2)

	BU	POLYPOLY_ENTER
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*DYNAMIC OBJECT
*
DYNAMIC_OBJECT:

;	LDI	*+AR0(OFLAGS),R0
;	TSTB	O_DEGRADE,R0
;	BZ	NOTDEGRADEPOSS

	LDI	*+AR0(ODIST),R0		;FORGET CLOSE DYNAMICS
	CMPI	250,R0
	BLTD	DISPLAY

	LDI	*+AR0(ODEGRADE_ROM),R0
	INC	R0
	CMPI	AR1,R0
	BZD	VECTORTRANSFULL

	LDI	*+AR0(ODEGRADE_ROM2),R0
	INC	R0
	CMPI	AR1,R0
	;---->BZD	VECTORTRANSFULL

	BEQ	VECTORTRANSFULL
	
;NOTDEGRADEPOSS


	;AR0	OBJECT POINTER/DYNA POINTER
	;AR1	rom ptr			*INC*
	;AR2	tmp pointer for inverse list
	;AR3	BLOWLIST ptr		*INC*
	;AR4	objects position   X,Z
	;AR5	rotation matrix ptr	*SAVE*
	;AR6	OBJ translation vector	*SAVE*
	;AR7	DYNA translation vector	*SAVE*

	;AR5	univmatrix   *SAVE*

	;R0	tmp value
	;R1	tmp value
	;R2	X element/tmp value
	;R3	Y element/tmp value
	;R4	Z element/tmp value
	;R5	inverse tab location	*SAVE*
	;R6	screen half x
	;R7	screen half y

	PUSH	AR0
	LDI	*+AR0(ODYNALIST),AR0

	LDI	@BLOWLISTI,AR3		;blowlist pointer = AR3
;	LDI	@transvectorYI,AR6	;dst 1x3
	LDI	@VECTORAYI,AR7


	LDI	*AR1++,BK		;VERTEX CNT & POLYGON CNT

	.if	STATISTICS
	LDI	BK,R0
	AND	0FFh,R0
	ADDI	@ST_VERTICES,R0
	ADDI	1,R0
	STI	R0,@ST_VERTICES
	.endif

;	LDI	*AR1++,R0		;VERTEX CNT & POLYGON CNT
;	PUSH	R0


;	LDI	@INVTABI,R5		;inverse table dedicated ptr
	FLOAT	SCREENHX,R6		;screen half x
	FLOAT	SCREENHY,R7		;screen half x
DYNALOOP

	LDI	*+AR0(DYNAFLAG),R0


	BND	DYNASHD			;GO DO A SHADOW...	

DYNREG
	LDI	@tmpmatI,AR4		;trans = object_pos + univ_pos
	LDI	@transmatrixI,AR5	;somewhat dedicated for matrix pointer
	LDF	*+AR0(DYNATRANSX),R2	
	;------>BND	DYNASHD		;GO DO A SHADOW...	
	LDF	*+AR0(DYNATRANSY),R3	
	LDF	*+AR0(DYNATRANSZ),R4	

*
*ROTATE TRANSLATION VECTOR BY OBJ-UNIV MATRIX AND ADD TO OBJECT TRANSLATION
*
	MPYF	*AR5++,R2,R0
  ||	STF	R2,*AR4			;SAVE X VECTOR VALUE (TMPMAT.x)
	MPYF	*AR5++,R3,R1
  ||	STF	R4,*+AR4(1)		;SAVE Z VECTOR VALUE (TMPMAT.z)
	MPYF	*AR5++,*+AR4(1),R1
  ||	ADDF	R0,R1,R2

	MPYF	*AR5++,*AR4,R0
  ||	ADDF	R1,R2,R2
	MPYF	*AR5++,R3,R1
  ||	ADDF	*-AR6(1),R2
  	STF	R2,*-AR7(1)		;(TRANSVECTOR.x)
	MPYF	*AR5++,*+AR4(1),R1
  ||	ADDF	R0,R1,R2

	MPYF	*AR5++,*AR4,R0
  ||	ADDF	R1,R2,R2
	MPYF	*AR5++,R3,R1
  ||	ADDF	*AR6,R2
	ADDF	R0,*+AR6(1),R2
  ||	STF	R2,*AR7			;(TRANSVECTOR.y)
	MPYF	*AR5++,*+AR4(1),R1
  ||	ADDF	R1,R2,R2
	ADDF	R1,R2
	STF	R2,*+AR7(1)		;(TRANSVECTOR.z) R2 = Z value of object	
	SUBI	9,AR5	       		;RESTORE AR5 OBJ-UNIV MAT

*CONCAT UNIV*OBJ MATRIX WITH DYNAMIC MATRIX
	LDI	@MATRIXAI,AR2
	LDI	AR0,AR4
	ADDI	DYNAMATRIX,AR4

*	AR4	- src1		(usually the objects matrix)
*	AR5	- src2		(usually the Cameras matrix)
*	AR2	- dst		(the GRM - general rotational matrix)
*
*A B C	   J K L    AJ+DK+GL BJ+EK+HL CJ+FK+IL
*D E F	*  M N O  = AM+DN+GO BM+EN+HO CM+FN+IO
*G H I     P Q R    AP+DQ+GR BP+EQ+HR CP+FQ+IR

	LDI	5,IR1
	LDI	3,IR0

	LDI	2,RC				;LOOP THREE TIMES
	RPTB	DYNLP1

	MPYF3	*AR5++(1),*AR4++(IR0),R0
	MPYF3	*AR5,*AR4++(IR0),R1
	MPYF3	*+AR5(1),*AR4--(IR1),R1
 ||	ADDF3	R0,R1,R2


	MPYF3	*-AR5(1),*AR4++(IR0),R0
 ||	ADDF3	R1,R2,R2
	MPYF3	*AR5,*AR4++(IR0),R1
	STF	R2,*AR2++(1)			;store MATij
	MPYF3	*+AR5(1),*AR4--(IR1),R1
 ||	ADDF3	R0,R1,R2


	MPYF3	*-AR5(1),*AR4++(IR0),R0
 ||	ADDF3	R1,R2,R2
	MPYF3	*AR5++,*AR4++(IR0),R1
	STF	R2,*AR2++(1)			;store MATij
	MPYF3	*AR5++,*AR4--(IR1),R1
 ||	ADDF3	R0,R1,R2
	ADDF	R1,R2

	STF	R2,*AR2++(1)			;store MATij
DYNLP1	NOP	*--AR4(3)


	LDI	@tmpmatY,AR4		;TEMP VECTOR STORE
	LDI	@INVTABI,AR2		;inverse table dedicated ptr
	LDI	8,IR0
	LDI	@MATRIXAI,AR5

	FLOAT	SCREENHX,R6		;screen half x
	FLOAT	SCREENHY,R7		;screen half x
	BD	DYNALP
	LDF	*-AR7(1),R4		;GET X TRANS
	LDF	*AR7,R5			;GET Y TRANS
	LDI	*+AR0(DYNANVERTS),RC	;number of vertices to process -1
	;------>BD	DYNALP

	;;MATRIX MULTIPLY 1x3 * 3x3 -> blowspace
	;AR0	object ptr		PRELOADED *SAVE*
	;AR1	rom ptr			PRELOADED *INC*
	;AR2	inverse table
	;AR3	BLOWLIST ptr	
	;AR4	TEMP VERTEX STORE
	;AR5	rotation matrix ptr	PRELOADED *SAVE*
	;AR6	translation vector	PRELOADED *SAVE*
	;AR7	

	;R0,R1  TEMP
	;R2	y element/tmp value
	;R3	x element/tmp value
	;R4	X TRANS
	;R5	Y TRANS
	;R6	X SCREEN CENTER
	;R7	Y SCREEN CENTER


	.align
DYNALP
	RPTB	EODVCTR

	LDI	*AR1++,R3
	LDI	R3,R2
	ASH	-16,R2
	FLOAT	R2		;y element
	LS	16,R3
	ASH	-16,R3
	FLOAT	R3		;x element

	SUBF	*+AR0(DYNACENTERX),R3

	STF	R3,*-AR4(1)		;store secondary access A
	SUBF	*+AR0(DYNACENTERY),R2


;	FLOAT	*AR1++,R3		;get x element of source 1
;	SUBF	*+AR0(DYNACENTERX),R3
;
;	FLOAT	*AR1++,R2		;B	get y element of source 1
;||	STF	R3,*-AR4(1)		;store secondary access A
;	SUBF	*+AR0(DYNACENTERY),R2

	FLOAT	*AR1++,R0		;C	get z element of source 1
 ||	STF	R2,*AR4			;store secondary access B
	SUBF	*+AR0(DYNACENTERZ),R0
	;
	;MULTIPLY BY ROTATION MATRIX
	;
	MPYF3	*AR5++,R3,R0		;AD
 ||	STF	R0,*+AR4(1)  		;store secondary access C
	MPYF3	*AR5++,R2,R1		;BE
	MPYF3	*AR5++,*+AR4(1),R1	;CF
 ||	ADDF3	R0,R1,R3		;AD+BE

	MPYF3	*AR5++,*-AR4(1),R0	;AG
 ||	ADDF3	R1,R3,R3		;AD+BE+CF
	MPYF3	*AR5++,R2,R1		;BH
 ||	STF	R3,*AR3++ 		;*BLOWLIST++ = [AD+BE+CF];STORE ROTATED X

	MPYF3	*AR5++,*+AR4(1),R1	;CI
 ||	ADDF3	R0,R1,R3		;AG+BH

	MPYF3	*AR5++,*-AR4(1),R0	;AJ
 ||	ADDF3	R1,R3,R3		;AG+BH+CI

	MPYF3	*AR5++,*AR4,R1		;BK

	MPYF3	*AR5--(IR0),*+AR4(1),R1	;CL
 ||	ADDF3	R0,R1,R2		;AJ+BK
	ADDF	R1,R2			;AJ+BK+CL
	ADDF	*+AR7(1),R2		;add in translation into [AJ+BK+CL]
;	LDFLT	0,R2			;it will always be positive

	LDF	*-AR3(1),R1		;GET BACK NEW X
 ||	STF	R2,*+AR3(1)		;SAVE NEW Z

	FIX	R2,IR1			;find z distance for inverse lookup

	ASH	-4,IR1			;quickly divide by 16

	CMPI	HIGH_CLIP_LEVEL,IR1   	;compare against highest clip level
	LDIGE	HIGH_CLIP_LEVEL,IR1    	;max it at highest clip level

	CMPI	-80,IR1
	LDILT	-80,IR1

	ADDF	R4,R1			;ADD X TRANSLATION
	ADDF	R5,R3			;add Y translation 

	MPYF	*+AR2(IR1),R1,R0    	;x = (x * inverse [z])

	ADDF	R6,R0			;    + SCRNHX 	       ;(screen half x)

	MPYF	*+AR2(IR1),R3,R0	;y = (y * inverse [z])
 ||	STF	R0,*-AR3(1)

	MPYF	1.04,R0			; below 1.0 shrinks Y, above expands Y
	ADDF	R7,R0			;    + SCRNHY	       ;(screen half y)
EODVCTR	STF	R0,*AR3++(2)

DYNALPX
	LDI	*AR0,AR0
	LDI	AR0,R0
	BNZ	DYNALOOP

;	POP	BK

	POP	AR0
	RS	16,BK
	CALL	PLOTPOLY
	LDI	*AR0,R0
	BNZ	NEXTOBJ
	RETS

	.GLOBL	CARVSIZ,DELTA_CAR

*DYNAMIC OBJECT SHADOW
	;AR0	OBJECT POINTER/DYNA POINTER
	;AR1	rom ptr			*INC*
	;AR2	tmp pointer for inverse list
	;AR3	BLOWLIST ptr		*INC*
	;AR4	objects position   X,Z
	;AR5	rotation matrix ptr	*SAVE*
	;AR6	OBJ translation vector	*SAVE*
	;AR7	DYNA translation vector	*SAVE*

	;AR5	univmatrix   *SAVE*

	;R0	tmp value
	;R1	tmp value
	;R2	X element/tmp value
	;R3	Y element/tmp value
	;R4	Z element/tmp value
	;R5	inverse tab location	*SAVE*
	;R6	screen half x
	;R7	screen half y

DYNASHD		
	LDI	@CAMERAMATRIXI,AR5	;CAMERA ROTATION MATRIX
	LDI	@INVTABI,R5		;inverse table dedicated ptr

*FIND CAR STRUCT IN PROCESS	
	LDI	*+AR0(DYNAPARENT),AR4	;GET POINTER TO PARENT
	LDI	*+AR4(OCARBLK),AR4
	ADDI	CARVSIZ,AR4



*CHECK SHADOW TYPE

	LDI	*+AR4(CARSHAD-CARVSIZ),R0	;SHADOW ACTIVE
	BZ	NOSHAD				;NO...BLOW IT OUT

*IF NOT AIRBORNE DO REGULAR

	LDI	*+AR4(CAR_AIRF-CARVSIZ),R0	
	OR	*+AR4(CAR_AIRB-CARVSIZ),R0
	BZ	DYNREG

	LDI	@_MODE,R4	       	;NO FLYING SHADOWS IN TUNNEL
	TSTB	MINTUNNEL,R4
	BNZ	DYNREG

	LDI	8,IR0

;	LDI	*+AR0(DYNANVERTS),RC	;number of vertices to process -1
;	LDI	RC,R0
;	ADDI	1,R0
;	MPYI	2,R0
;	ADDI	R0,AR1			;ADJUST AR1 TO SKIP VERTICES

	LDI	3,RC
	ADDI	8,AR1			;SKIP 4 SHADOW VERTICES
	RPTB	EOSVCTR

*GET COORDS IN ORDER, ADD IN ROAD DIFF

	LDI	@CAMERAPOSI,AR2
	LDF	*AR4++,R3		;GET X COORD OF CAR POINT
	SUBF	*AR2,R3			;GET RELATIVE TO CAMERA
	LDF	*AR4++,R4		;GET Y COORD OF CAR POINT
 ||	STF	R3,*-AR7(1)		;SAVE X

	SUBF	*+AR2(1),R4		;GET RELATIVE TO CAMERA

	ADDF	*+AR4(1),R4		;ADD IN ROAD DIFFERENTIAL TO Y

	LDF	*AR4++,R2		;GET Z COORD OF CAR POINT
 ||	STF	R4,*AR7			;STORE Y
	SUBF	*+AR2(2),R2		;GET RELATIVE TO CAMERA
	

*RETURN TO DYNAMIC OBJECT LOOP WITH REG INTACT

*MULTIPLY BY CAMERA ROTATION MATRIX

	MPYF3	*AR5++,R3,R0		;AD
 ||	STF	R2,*+AR7(1)  		;STORE Z
	MPYF3	*AR5++,R4,R1		;BE
	MPYF3	*AR5++,*+AR7(1),R1	;CF
 ||	ADDF3	R0,R1,R2		;AD+BE

	MPYF3	*AR5++,*-AR7(1),R0	;AG
 ||	ADDF3	R1,R2,R2		;AD+BE+CF
;	ADDF	*-AR6(1),R2		;add translation into [AD+BE+CF]
	MPYF3	*AR5++,R4,R1		;BH
 ||	STF	R2,*AR3++ 		;*BLOWLIST++ = [AD+BE+CF];STORE ROTATED X
	MPYF3	*AR5++,*+AR7(1),R1	;CI
 ||	ADDF3	R0,R1,R2		;AG+BH

	MPYF3	*AR5++,*-AR7(1),R0	;AJ
 ||	ADDF3	R1,R2,R3		;AG+BH+CI
;	ADDF	*AR6,R3			;add translation into [AG+BH+CI]
	MPYF3	*AR5++,R4,R1		;BK
 ||	STF	R3,*AR3++		;*BLOWLIST++ = [AG+BH+CI]
	MPYF3	*AR5--(IR0),*+AR7(1),R1	;CL
 ||	ADDF3	R0,R1,R2		;AJ+BK
	ADDF	R1,R2			;AJ+BK+CL
;	ADDF	*+AR6(1),R2		;add in translation into [AJ+BK+CL]

	STF	R2,*AR3--(2)		;(TRANSVECTOR.z) R2 = Z value of object	
	FIX	R2,R0			;find z distance for inverse lookup

;	LDILT	0,R0			;it will always be positive

	ADDI	CARVSIZ-3,AR4		;ADDRESS NEXT WHEEL ENTRY

	ASH	-4,R0			;quickly divide by 16

	CMPI	HIGH_CLIP_LEVEL,R0   	;compare against highest clip level
	LDIGE	HIGH_CLIP_LEVEL,R0    	;max it at highest clip level

	CMPI	-80,R0
	LDILT	-80,R0

	ADDI	R5,R0,AR2		;add in start of inverse table
	MPYF	*AR2,*AR3,R0		;x = (x * inverse [z])
	ADDF	R6,R0			;    + SCRNHX 	       ;(screen half x)
	STF	R0,*AR3++

	MPYF	*AR2,*AR3,R0		;y = (y * inverse [z])
	MPYF	1.04,R0	; below 1.0 shrinks Y, above expands Y
	ADDF	R7,R0			;    + SCRNHY	       ;(screen half y)
EOSVCTR	STF	R0,*AR3++(2)

	LDI	@transmatrixI,AR5	;RESTORE MATRIX POINTER
	BU	DYNALPX

*NO SHADOW KLUDGE
NOSHAD
	LDF	0,R0
	FLOAT	-1000,R0

	LDI	3,RC
	ADDI	8,AR1			;SKIP 4 SHADOW VERTICES

	RPTS	11
	STF	R0,*AR3++    		;STORE NULL X,Y,Z

	LDI	@transmatrixI,AR5	;RESTORE MATRIX POINTER
	BU	DYNALPX
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*	PLOTPOLY
*
*	Polygons are already transformed, now just preform HSR,
*	and stuff the fifo with appropriate data.
*	Note also that this only renders a block of polygons.
*
*	struct ROM_POLYGON  {
*		int	palnum<<16|cntl
*		int	(v4<<24)|(v3<<16)|(v2<<8)|(v1)
*		int	IV[0]|(IV[1]<<16)
*		int	IV[2]|(IV[3]<<16)
*		int	*addr_to_TM;
*	}
*
*
PLOTPOLY:

	.if	STATISTICS
	LDI	BK,R0			;# of polygons-1
	ADDI	1,R0
	ADDI	@ST_POLYGONS,R0
	STI	R0,@ST_POLYGONS
	.endif

	LDI	*+AR0(OFLAGS),R6	;test for illuminated object
	TSTB	O_1PAL,R6
	BNZD	PLOT1PAL		;BR-> if it is a one palette object

	LDI	*+AR0(ODIST),R0		;CHECK IF DISTANT
	SUBI	*+AR0(ORAD),R0		;FAR AWAY
	LDI	BK,RC			;# of polygons-1
	;---->BZD	PLOT1PAL

	TSTB	O_ILLUM,R6
	BNZD	PLOTILLUM		;BR-> if it is a one palette object

	LDI	@BLOWLISTI,IR0
	LDI	IR0,IR1
	ADDI	1,IR1
	;---->BNZD	PLOTILLUM	;BR-> if it is a one palette object

*----------------------------------------------------------------------------
PLOTPOLY0
	CMPI	1000,R0
	BGTD	PLTPOLY			;YES, NO CLIP LOOP

	LDI	@_PALLISTI,BK
	LDI	0FFH,R7			;GET MASK
	LDI	-16,R6			;SHIFT COUNT
	;---->BGTD	PLTPOLY		;YES, NO CLIP LOOP

	PUSH 	AR0
	LDI	@CLIPRAMI,AR0
 	LDI	RC,AR6			;GET POLY COUNT

	BUD	PLOTPOLYLP
	LDP	@FIFO_STATUS
	LDI	FIFO_ADDR>>16,AR7
	LSH	16,AR7
	;------->BD	PLTPOLYLP
	.align 
PLOTPOLYLP

*GET EXTERNAL VERTEX INDICIES
	LDI	*+AR1(1),R3		;read internal vertices (v4|v3|v2|v1)
	AND	R7,R3,AR4

PLOTPOLYLP1
	ADDI	1,IR1

	MPYI	3,AR4			;V1

	LSH	-8,R3
	AND	R7,R3,AR5
	MPYI	3,AR5			;V2

	LSH	-8,R3
	AND	R7,R3,AR2
	MPYI	3,AR2			;V3

	LSH	-8,R3			
	AND	R7,R3,AR3
	MPYI	3,AR3			;V4

*CHECK ALL Z'S <=0
	LDF	*+AR4(IR1),R0
	BGED	INBNDS

	AND	*+AR5(IR1),*+AR2(IR1),R0
	AND	*+AR3(IR1),R0
	SUBI	1,IR1
	;------->BGED	INBNDS

	LSH	8,R0
	BND	POLYLP
	NOP

*CHECK FIFO FULL

INBNDS
	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	;---->BND	POLYLP_1
	BNZD	INBNDS

*CHECK HIDDEN SURFACE REMOVAL

	SUBF	*+AR4(IR0),*+AR5(IR0),R1	;dx = ax - bx
	SUBF	*+AR4(IR1),*+AR5(IR1),R3	;dy = ay - by
	SUBF	*+AR5(IR0),*+AR2(IR0),R0	;ex = cx - bx
	;------->BNZD	INBNDS

	MPYF	R3,R0				;ex = dy * ex
  ||	SUBF	*+AR5(IR1),*+AR2(IR1),R2	;ey = cy - by

	MPYF	R2,R1				;ey = dx * ey

	SUBF	R1,R0				;ey = ey - ex
	BGTD	POLYLP				;if back facing DONT PLOT

*GLITCH FIX

	SUBF	*+AR2(IR1),*+AR3(IR1),R0
	MPYF	R3,R0
||	SUBF	*+AR3(IR1),*+AR4(IR1),R3
	CMPI	AR2,AR3
	;------>BGTD	POLYLP			;if back facing DONT PLOT

	BZD	LOF1X

	MPYF	R3,R2
	OR	R2,R0
	LDF	R0,R0

	BGT	POLYLP
LOF1X

*AR4,AR5,AR2,AR3 = FOUR VERTICES
*IR1=PALETTE
*
	CALL	CLIPCK
	BNZD	CLIPIT			;GO CLIP IT DUDES
	LDI	*AR1++(2),R2		;get control word/palette
	LSH	R6,R2,R0		;SHIFT 16 TO RIGHT
	ADDI	R0,BK,AR4
	;------->BNZD	CLIPIT	  	;YES SPLIT IT UP...

	LSH	R6,*AR4,R0		;PALETTE->R0
 ||	STI	R2,*AR7
 	LSH	8,R0			;not a good way to do this fix l8r -7/14/93

*NO CLIP, BLOW IT OUT

BLOWOUT

	RPTS	7
	LDI	*AR0++,R0
 ||	STI	R0,*AR7

	NOP	*AR0--(8)		;READJUST INDEX DUDES...

	LDI	*AR1++,R0		;2 AIV packed format Y2:X2:Y1:X1
 ||	STI	R0,*AR7

	STI	R0,*AR7
	LSH	-16,R0

	LDI	*AR1++,R0		;GET Y4:X4:Y3:X3
 ||	STI	R0,*AR7

	STI	R0,*AR7
	LSH	-16,R0

	DBUD	AR6,PLOTPOLYLP

	LDI	*AR1++,R0
 ||	STI	R0,*AR7

	STI	R0,*AR7			;STORE THE ADDR
	LDI	@FIFO_INC,R0
;	LDI	*AR7,R0		 	;FIFO_INC
	;----> DBUD AR6,PLOTPOLYLP

	POP	AR0			;RESTORE OBJECT POINTER
	RETS
POLYLP
	DBUD	AR6,PLOTPOLYLP1
	LDI	*++AR1(6),R3		;read internal vertices (v4|v3|v2|v1)
	SUBI	1,AR1
	AND	R7,R3,AR4
	;----> DBUD AR6,PLOTPOLYLP1

	POP	AR0
	RETS
*CLIP IT
CLIPIT
	LSH	R6,*AR4,R0		;PALETTE->R0
 	LSH	8,R0			;not a good way to do this fix l8r -7/14/93
	CALL 	CLIP
	DBU	AR6,PLOTPOLYLP
	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*CHECK THE CLIP AND DUMP VERTICES INTO INTERNAL RAM
*
*
*RETURN
*	R5 NZ=CLIP, Z=NOCLIP
*
CLIPCK:

	;***	PRELIM CHECK

	FIX	*+AR4(IR0),R0		;read X value
	FIX	*+AR4(IR1),R0
 ||	STI	R0,*AR0++

	FIX	*+AR5(IR0),R0
 ||	STI	R0,*AR0++
	FIX	*+AR5(IR1),R0
 ||	STI	R0,*AR0++

	FIX	*+AR2(IR0),R0
 ||	STI	R0,*AR0++
	FIX	*+AR2(IR1),R0
 ||	STI	R0,*AR0++

	FIX	*+AR3(IR0),R0
 ||	STI	R0,*AR0++
	FIX	*+AR3(IR1),R0
 ||	STI	R0,*AR0++


	STI	R0,*AR0
	ABSI	R0,R5

	LDI	6,RC
	RPTB	LPP2

	ABSI	*--AR0,R1
LPP2	OR	R1,R5

	LSH	-10,R5
	RETSZ


	;***	STRICT CHECK

	LDI	0,R5

	LDI	*AR0++,R0		;XMAX
 ||	LDI	*AR0,R1			;XMIN

	LDI	*AR0,R2			;YMAX
 ||	LDI	*AR0,R3			;YMIN
	LDI	2,RC

	RPTB	CKLP

	CMPI	*++AR0,R0
	LDILT	*AR0,R0
	CMPI	*AR0,R1
	LDIGT	*AR0,R1

	CMPI	*++AR0,R2
	LDILT	*AR0,R2
	CMPI	*AR0,R3
CKLP	LDIGT	*AR0,R3

	NOP	*AR0--(7)

	SUBI	R1,R0 		;FIND XMAX-XMIN
	CMPI	2047,R0
	LDIGT	1,R5

	SUBI	R3,R2		;FIND YMAX-YMIN
	CMPI	2047,R2
	LDIGT	1,R5
	LDI	R5,R5
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*CLIP THE SUCKER
*SPLIT INTO 4 POLYGONS UL,UR,LL,LR
*	AR0	4 EXTERNAL VERTICES (INTS)
*	R0 	PALETTE
*	R2      FLAGS
*
CLIP:
	PUSH	IR0
	PUSH	IR1

	LDI	2,IR0
	LDI	3,IR1

	LDI	R2,AR3		     	;SAVE FLAGS
	LDI	R0,R4			;SAVE PALETTE


;	LDIL	CLIPRAM,R0		;LOAD UP SCRATCH AREA
;	CMPI	R0,AR0
;	BNE	$




*CHECK TRIVIAL REJECTION
*X ALL NEGATIVE CASE	
*
	AND	*AR0,*+AR0(IR0),R0
	AND	*+AR0(4),R0
	AND	*+AR0(6),R0
	BND	CLIPX	    		;ALL X <0 REJECT

*X ALL POSTIVE CASE

	LDI	511,R1
	SUBI	*AR0,R1,R2
	SUBI	*+AR0(IR0),R1,R3
	;------->BND	CLIPX	    	;ALL X <0 REJECT
	AND	R3,R2
	LDI	511,R3
	SUBI	*+AR0(4),R3
	AND	R3,R2
	SUBI	*+AR0(6),R1
	AND	R1,R2
	BND	CLIPX			;ALL X >511 REJECT		

*Y ALL POSTIVE CASE

	LDI	399,R1
	SUBI	*+AR0(1),R1,R2
	SUBI	*+AR0(IR1),R1,R3
	;------->BND	CLIPX	    	;ALL X >511 REJECT
	AND	R3,R2
	LDI	511,R3
	SUBI	*+AR0(5),R3
	AND	R3,R2
	SUBI	*+AR0(7),R1
	AND	R1,R2
	BND	CLIPX			;ALL Y >511 REJECT

*Y ALL NEGATIVE CASE

	AND	*+AR0(1),*+AR0(IR1),R0
	AND	*+AR0(5),R0
	AND	*+AR0(7),R0
	;------->BND	CLIPX	    	;ALL X >511 REJECT
	BN	CLIPX			;ALL Y >511 REJECT
*	
*COMPUTE YOUR INTERNAL VERTICES
*AR0-POINTER TO POLY STACK
*AR1=ROM POINTER
*UNPACK THE SUCKERS
*
	LDI	*AR1++,R0		;UNPACK THE SUCKERS
	LDI	0FFH,R2

	AND	R2,R0,R1
	STI	R1,*+AR0(8)

	LSH	-8,R0
	AND	R2,R0,R1
	STI	R1,*+AR0(9)

	LSH	-8,R0
	AND	R2,R0,R1
	STI	R1,*+AR0(10)

	LSH	-8,R0
	AND	R2,R0,R1
	STI	R1,*+AR0(11)

	LDI	*AR1++,R0		;UNPACK THE SUCKERS

	AND	R2,R0,R1
	STI	R1,*+AR0(12)

	LSH	-8,R0
	AND	R2,R0,R1
	STI	R1,*+AR0(13)

	LSH	-8,R0
	AND	R2,R0,R1
	STI	R1,*+AR0(14)

	LSH	-8,R0
	AND	R2,R0,R1
	STI	R1,*+AR0(15)

	LDI	AR0,R6
 	BD	BUSTUP
	LDI	R6,R7
	ADDI	CLIPRAML-80,R7	     	;GET LENGTH LIMIT
	LDI	*AR1++,R5		;GET TEXTURE MAP ADDR
 	;------->BD	BUSTUP
*
*POP STACK
*
*AR0 POINTS TO CURRENT TOP OF STACK
*0-7  XY EXT VERTS INT
*8-15 XY INT VERTS INT
*	AR0	4 EXTERNAL VERTICES (INTS)
*	AR1	ROM INDEX
*	AR3 	PALETTE
*	R4      FLAGS
*	R5	TEXTURE MAP ADDR
CLIPOP	
	NOP	*AR0--(16)		;POP OFF OLD ENTRY
;	LDI	AR0,R1
;	AND	0FH,R1
;	CMPI	0DH,R1
;	BNE	$


CLIP0
	CMPI	AR0,R6			;ARE WE DONE
	BGT	CLIPDONE		;YES...WERE OUTTA HERE
;	BGTD	CLIPDONE		;YES...WERE OUTTA HERE

;	LDI	AR0,R1
;	AND	0FH,R1
;	CMPI	0DH,R1
;	BNE	$


;	LDIL	CLIPRAM,R0		;LOAD UP SCRATCH AREA
;	LDIL	CLIPLIM,R1		;LOAD UP SCRATCH AREA

;	CMPI	R0,AR0
;	BLT	$

;	CMPI	R1,AR0
;	BGT	$


*
*CHECK TRIVIAL REJECTION
*
*X ALL NEGATIVE CASE	
*
	AND	*AR0,*+AR0(IR0),R0
	AND	*+AR0(4),R0
	AND	*+AR0(6),R0
	;-------->BGTD	CLIPDONE  	;YES...EXIT
	BND	CLIPOP	    		;ALL X <0 REJECT

*X ALL POSTIVE CASE

	LDI	511,R1
	SUBI	*AR0,R1,R2
	SUBI	*+AR0(IR0),R1,R3
	;------->BND	CLIPOP	    	;ALL X <0 REJECT
	AND	R3,R2
	LDI	511,R3
	SUBI	*+AR0(4),R3
	AND	R3,R2
	SUBI	*+AR0(6),R1
	AND	R1,R2
	BND	CLIPOP			;ALL X >511 REJECT		

*Y ALL POSTIVE CASE

	LDI	399,R1
	SUBI	*+AR0(1),R1,R2
	SUBI	*+AR0(IR1),R1,R3
	;------->BND	CLIPOP	    	;ALL X >511 REJECT
	AND	R3,R2
	LDI	511,R3
	SUBI	*+AR0(5),R3
	AND	R3,R2
	SUBI	*+AR0(7),R1
	AND	R1,R2
	BND	CLIPOP			;ALL Y >511 REJECT

*Y ALL NEGATIVE CASE

	AND	*+AR0(1),*+AR0(IR1),R0
	AND	*+AR0(5),R0
	AND	*+AR0(7),R0
	;------->BND	CLIPOP	    	;ALL X >511 REJECT
	BND	CLIPOP		    	;ALL Y <0 REJECT

*CHECK OVERSIZE OBJECT

	LDI	*AR0,R0			;XMAX
 ||	LDI	*AR0,R1			;XMIN

	LDI	*+AR0(1),R2		;YMAX
 ||	LDI	*+AR0(1),R3		;YMIN
	LDI	2,RC
	;------->BND	CLIPOP	    	;Y ALL NEGATIVE	REJECT

	RPTB	CLCKLP

	CMPI	*++AR0(IR0),R0
	LDILT	*AR0,R0
	CMPI	*AR0,R1
	LDIGT	*AR0,R1

	CMPI	*+AR0(1),R2
	LDILT	*+AR0(1),R2
	CMPI	*+AR0(1),R3
CLCKLP	LDIGT	*+AR0(1),R3

	SUBI	R1,R0
	CMPI	2047,R0
	BGTD	BUSTUP

	NOP	*AR0--(6)  		;RESET VERTEX INDEX 
	SUBI	R3,R2
	CMPI	2047,R2
	;------->BGTD	BUSTUP
	BGT	BUSTUP

*POLYGON IS O.K. OUTPUT IT

PCOUT
PCWT
	LDI	@FIFO_STATUS,R0		;WAIT FOR YOUR FIFO
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZ	PCWT

	LDI	R4,R0			;GET PALETTE READY
	STI	AR3,*AR7		;STORE YOUR FLAGS

	RPTS	7
	LDI	*AR0++,R0		;GET EXTERNALS
 ||	STI	R0,*AR7			;STORE EXTERNALS

 	STI	R0,*AR7

	LDI	*AR0++(IR0),R0	 	;GET YX INTERNAL 1
 ||	LDI	*+AR0(1),R1	

	LSH	8,R1
	ADDI	R1,R0
 	STI	R0,*AR7

	LDI	*AR0++(IR0),R0		;GET YX INTERNAL 2
 ||	LDI	*+AR0(1),R1	

	LSH	8,R1
	ADDI	R1,R0
 	STI	R0,*AR7

	LDI	*AR0++(IR0),R0	  	;GET YX INTERNAL 3
 ||	LDI	*+AR0(1),R1	

	LSH	8,R1
	ADDI	R1,R0
 	STI	R0,*AR7

	LDI	*AR0++(IR0),R0	  	;GET YX INTERNAL 4
 ||	LDI	*+AR0(1),R1	

	LSH	8,R1
	ADDI	R1,R0
 	STI	R0,*AR7

	STI	R5,*AR7 		;STORE TEXTURE MAP ADDR

	LDI	@FIFO_INC,R0		;INC YOUR FIFO
	NOP	*AR0--(32)		;READJUST INDEX

 ;	LDI	AR0,R1
 ;	AND	0FH,R1
 ;	CMPI	0DH,R1
 ;	BNE	$

	B 	CLIP0			;GET NEXT POLYGON

*BUSTUP A POLYGON INTO 4 OTHERS, PUT ON STACK
*AR0=CURRENT STACK ENTRY

BUSTUP
;	LDI	AR0,R1
;	AND	0FH,R1
;	CMPI	0DH,R1
;	BNE	$


;	LDIL	CLIPRAM,R0		;LOAD UP SCRATCH AREA
;	LDIL	CLIPLIM,R1		;LOAD UP SCRATCH AREA

;	CMPI	R0,AR0
;	BLT	$

;	CMPI	R1,AR0
;	BGT	$

	CMPI	R7,AR0			;STACK TOO HIGH?
	BLT	BUSTUP0
	B	PCOUT			;YES, JUST DO IT...

*COMPUTE YOUR EXTERNAL VERTICES

BUSTUP0
	LDI	AR0,AR2	

	LDI	*+AR0(IR0),R0		;X2
 ||	LDI	*+AR0(IR1),R1		;Y2

	STI	R0,*+AR2(12H)
	STI	R1,*+AR2(13H)

	LDI	*+AR0(4),R0		;X3
	STI	R0,*+AR2(24H)

	LDI	*+AR0(5),R0		;Y3
	STI	R0,*+AR2(25H)

	LDI	*+AR0(6),R0		;X4
	STI	R0,*+AR2(36H)

	LDI	*+AR0(7),R0		;Y4
	STI	R0,*+AR2(37H)

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;X1+X2/2=X5
	STI	R0,*+AR2(42H)	     	
	STI	R0,*+AR2(10H)	     	
	
	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;Y1+Y2/2=Y5
	STI	R0,*+AR2(43H)	     	
	STI	R0,*+AR2(11H)	     	

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0		       	;X2+X3/2=X6
	STI	R0,*+AR2(14H)	     	
	STI	R0,*+AR2(22H)	     	
	
	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;Y2+Y3/2=Y6
	STI	R0,*+AR2(15H)	     	
	STI	R0,*+AR2(23H)	     	

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;X3+X4/2=X7
	STI	R0,*+AR2(26H)	     	
	STI	R0,*+AR2(34H)	     	

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;Y3+Y4/2=Y7
	STI	R0,*+AR2(27H)	     	
	STI	R0,*+AR2(35H)	     	

	LDI	*--AR0(6),R0
	ADDI	*+AR0(6),R0
	ASH	-1,R0			;X1+X4/2=X8
	STI	R0,*+AR2(46H)	     	
	STI	R0,*+AR2(30H)	     	
	
	LDI	*+AR0(1),R0
	ADDI	*+AR0(7),R0
	ASH	-1,R0			;Y1+Y4/2=Y8
	STI	R0,*+AR2(47H)	     	
	STI	R0,*+AR2(31H)	     	

	ADDI	*AR0,*+AR0(IR0),R0    	
	ADDI	*+AR0(4),R0
	ADDI	*+AR0(6),R0
	ASH	-2,R0			;X1+X2+X3+X4/4=X9
	STI	R0,*+AR2(44H)	     	
	STI	R0,*+AR2(16H)	     	
	STI	R0,*+AR2(20H)	     	
	STI	R0,*+AR2(32H)	     	

	LDI	*+AR0(1),R0
	ADDI	*+AR0(3),R0
	ADDI	*+AR0(5),R0
	ADDI	*+AR0(7),R0
	ASH	-2,R0			;Y1+Y2+Y3+Y4/4=Y9
	STI	R0,*+AR2(45H)	     	
	STI	R0,*+AR2(17H)	     	
	STI	R0,*+AR2(21H)	     	
	STI	R0,*+AR2(33H)	     	

*COMPUTE YOUR INTERNAL VERTICES

	NOP	*AR0++(8)

	LDI	*AR0,R0			;X1
 ||	LDI	*+AR0(1),R1    		;Y1

	STI	R0,*+AR2(48H)
	STI	R1,*+AR2(49H)

	LDI	*+AR0(IR0),R0		;X2
 ||	LDI	*+AR0(IR1),R1		;Y2

	STI	R0,*+AR2(1AH)
	STI	R1,*+AR2(1BH)

	LDI	*+AR0(4),R0		;X3
	STI	R0,*+AR2(2CH)

	LDI	*+AR0(5),R0		;Y3
	STI	R0,*+AR2(2DH)

	LDI	*+AR0(6),R0		;X4
	STI	R0,*+AR2(3EH)

	LDI	*+AR0(7),R0		;Y4
	STI	R0,*+AR2(3FH)

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;X1+X2/2=X5
	STI	R0,*+AR2(4AH)	     	
	STI	R0,*+AR2(18H)	     	
	
	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;Y1+Y2/2=Y5
	STI	R0,*+AR2(4BH)	     	
	STI	R0,*+AR2(19H)	     	

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0		       	;X2+X3/2=X6
	STI	R0,*+AR2(1CH)	     	
	STI	R0,*+AR2(2AH)	     	
	
	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;Y2+Y3/2=Y6
	STI	R0,*+AR2(1DH)	     	
	STI	R0,*+AR2(2BH)	     	

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;X3+X4/2=X7
	STI	R0,*+AR2(2EH)	     	
	STI	R0,*+AR2(3CH)	     	

	ADDI	*AR0++,*+AR0(IR0),R0    	
	ASH	-1,R0			;Y3+Y4/2=Y7
	STI	R0,*+AR2(2FH)	     	
	STI	R0,*+AR2(3DH)	     	

	LDI	*--AR0(6),R0
	ADDI	*+AR0(6),R0
	ASH	-1,R0			;X1+X4/2=X8
	STI	R0,*+AR2(4EH)	     	
	STI	R0,*+AR2(38H)	     	
	
	LDI	*+AR0(1),R0
	ADDI	*+AR0(7),R0
	ASH	-1,R0			;Y1+Y4/2=Y8
	STI	R0,*+AR2(4FH)	     	
	STI	R0,*+AR2(39H)	     	

	ADDI	*AR0,*+AR0(IR0),R0    	
	ADDI	*+AR0(4),R0
	ADDI	*+AR0(6),R0
	ASH	-2,R0			;X1+X2+X3+X4/4=X9
	STI	R0,*+AR2(4CH)	     	
	STI	R0,*+AR2(1EH)	     	
	STI	R0,*+AR2(28H)	     	
	STI	R0,*+AR2(3AH)	     	

	LDI	*+AR0(1),R0
	ADDI	*+AR0(3),R0
	ADDI	*+AR0(5),R0
	ADDI	*+AR0(7),R0
	ASH	-2,R0			;Y1+Y2+Y3+Y4/4=Y9
	STI	R0,*+AR2(4DH)	     	
	STI	R0,*+AR2(1FH)	     	
	STI	R0,*+AR2(29H)	     	
	STI	R0,*+AR2(3BH)	     	

*TRANSFER LAST ENTRY INTO FIRST ONE
	
	NOP	*AR2++(42H)
	NOP	*AR0--(6)		;POINT TO X2,Y2
	
	LDI	*AR2++,R0		;GET FIRST

	RPTS	12
	LDI	*AR2++,R0
 ||	STI	R0,*AR0++

	STI	R0,*AR0++(31H)		;STORE LAST ONE, RESET INDEX TO TOS

;	LDI	AR0,R1
;	AND	0FH,R1
;	CMPI	0DH,R1
;	BNE	$

	B	CLIPOP
CLIPX
	NOP	*AR0--(16)		;RESTORE AR0
	ADDI	3,AR1			;SKIP THE INTERNAL VERTS AND TM CRAP
CLIPDONE
	LDI	-16,R6			;RESTORE R6
	LDI	0FFH,R7			;RESTORE R7
	NOP	*AR0++(16)		;RESTORE AR0

	LDIL	CLIPRAM,R0		;LOAD UP SCRATCH AREA
	.if	DEBUG
	CMPI	R0,AR0
	BNE	$
	.endif

	POP	IR1
	POP	IR0
	RETS

*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*PLOT A DISTANT POLYGON
*
*R7=0FFH
*IR0=BLOWLIST
*IR1=BLOWLIST+1
*RC=POLYGON COUNT
*
PLTPOLY:

;	PUSH	AR0
;	LDI	AR6,RC

	BUD	PLTPOLYLP
	LDP	@FIFO_STATUS
	LDI	FIFO_ADDR>>16,AR7
	LSH	16,AR7
	;------->BD	PLTPOLYLP

	.align 
PLTPOLYLP
	RPTB	PLTPOLL
	LDI	*+AR1(1),R3		;read internal vertices (v4|v3|v2|v1)
	AND	R7,R3,AR4
PLTPOLYLP1
	MPYI	3,AR4			;V1

	LSH	-8,R3
	AND	R7,R3,AR5
	MPYI	3,AR5			;V2

	LSH	-8,R3
	AND	R7,R3,AR2
	MPYI	3,AR2			;V3
PLTWT
	;CHECK FIFO FULL

	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZD	PLTWT

	;CHECK HIDDEN SURFACE REMOVAL

	SUBF	*+AR4(IR0),*+AR5(IR0),R1	;dx = ax - bx
	SUBF	*+AR4(IR1),*+AR5(IR1),R2	;dy = ay - by
	SUBF	*+AR2(IR0),*+AR5(IR0),R0	;ex = cx - bx
	;------->BNZD	PLTWT

	MPYF	R2,R0,R0			;ex = dy * ex
  ||	SUBF	*+AR2(IR1),*+AR5(IR1),R2	;ey = cy - by

	MPYF	R1,R2			;ey = dx * ey

	SUBF	R0,R2			;ey = ey - ex
	BGTD	PLTLP1			;if back facing DONT PLOT

	LSH	-8,R3			;START GETTING V4
	LDI	3,R1
	NOP
	;------->BGTD	PLTLP1

	LDI	*AR1++(2),R2		;get control word

	LSH	R6,R2,R0		;SHIFT 16 TO RIGHT
	MPYI	R1,R3,AR3		;GET LAST VERTEX  V4
	ADDI	R0,BK,AR6
	
	LSH	R6,*AR6,R0		;PALETTE->R0
 ||	STI	R2,*AR7

 	LSH	8,R0			;not a good way to do this fix l8r -7/14/93

	FIX	*+AR4(IR0),R0		;READ X1
 ||	STI	R0,*AR7			;STUFF the PALETTE

	FIX	*+AR4(IR1),R0		;READ X1
 ||	STI	R0,*AR7

	FIX	*+AR5(IR0),R0		;READ X2
 ||	STI	R0,*AR7
	FIX	*+AR5(IR1),R0		;READ Y2
 ||	STI	R0,*AR7

	FIX	*+AR2(IR0),R0		;READ X3
 ||	STI	R0,*AR7
	FIX	*+AR2(IR1),R0		;READ Y3
 ||	STI	R0,*AR7

	FIX	*+AR3(IR0),R0		;READ X4
 ||	STI	R0,*AR7
	FIX	*+AR3(IR1),R0		;READ Y4
 ||	STI	R0,*AR7
 	STI	R0,*AR7

	LDI	*AR1++,R0
	LDI	*AR1++,R1
	LDI	*AR1++,R2
 ||	STI	R0,*AR7

	LSH	-16,R0
	STI	R0,*AR7

 	STI	R1,*AR7
	LSH	-16,R1
	STI	R1,*AR7
 	STI	R2,*AR7

PLTPOLL
	LDI	@FIFO_INC,R0

;	POP	AR0
	RETS

PLTLP1	
	SUBI	1,RC
	LDI	RC,R0
	BNND	PLTPOLYLP1
	LDI	*++AR1(6),R3		;read internal vertices (v4|v3|v2|v1)
	SUBI	1,AR1
	AND	R7,R3,AR4
	;----> BNND PLTPOLYLP1
PLTXX
;	POP	AR0
	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
*
*PLOT POLYGONS FOR A ONE PALETTE TEXTURE MAP OBJECT
*
*R0=ODIST-ORAD
*RC=POLYGON COUNT
*
PLOT1PAL:
	CMPI	1000,R0
	BGTD	PLT1PAL			;YES, NO CLIP LOOP

	LDI	@BLOWLISTI,IR0
	LDI	IR0,IR1
	ADDI	1,IR1
	;---->BGTD	PLT1PAL			;YES, NO CLIP LOOP

	PUSH 	AR0

	LDI	RC,AR6
	LDI	0FFH,R7			;GET MASK
	LDI	-16,R6			;SHIFT COUNT

	LDI	*+AR0(OPAL),BK

	LDI	@CLIPRAMI,AR0

	BUD	PLOTPOLYLP_1
	LDP	@FIFO_STATUS
	LDI	FIFO_ADDR>>16,AR7
	LSH	16,AR7
	;------->BD	PLTPOLYLP_1

	.align 
PLOTPOLYLP_1

*GET EXTERNAL VERTEX INDICIES
	LDI	*+AR1(1),R3		;read internal vertices (v4|v3|v2|v1)
	AND	R7,R3,AR4

PLOTPOLYLP1_1
	ADDI	1,IR1

	MPYI	3,AR4			;V1

	LSH	-8,R3
	AND	R7,R3,AR5
	MPYI	3,AR5			;V2

	LSH	-8,R3
	AND	R7,R3,AR2
	MPYI	3,AR2			;V3

	LSH	-8,R3			
	AND	R7,R3,AR3
	MPYI	3,AR3			;V4

*CHECK ALL Z'S <=0

	LDF	*+AR4(IR1),R0
	BGED	INBNDS_1

	AND	*+AR5(IR1),*+AR2(IR1),R0
	AND	*+AR3(IR1),R0
	SUBI	1,IR1
	;------->BGED	INBNDS_1

	LSH	8,R0
	BND	POLYLP_1
	NOP


*CHECK FIFO FULL

INBNDS_1
	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	;---->BCD	POLYLP_1

	BNZD	INBNDS_1

*CHECK HIDDEN SURFACE REMOVAL

	SUBF	*+AR4(IR0),*+AR5(IR0),R1	;dx = ax - bx
	SUBF	*+AR4(IR1),*+AR5(IR1),R3	;dy = ay - by
	SUBF	*+AR5(IR0),*+AR2(IR0),R0	;ex = cx - bx
	;------->BNZD	INBNDS_1

	MPYF	R3,R0				;ex = dy * ex
  ||	SUBF	*+AR5(IR1),*+AR2(IR1),R2	;ey = cy - by

	MPYF	R2,R1				;ey = dx * ey

	SUBF	R1,R0				;ey = ey - ex
	BGTD	POLYLP_1				;if back facing DONT PLOT

*GLITCH FIX

	SUBF	*+AR2(IR1),*+AR3(IR1),R0
	MPYF	R3,R0
||	SUBF	*+AR3(IR1),*+AR4(IR1),R3
	CMPI	AR2,AR3
	;------>BGTD	POLYLP_1			;if back facing DONT PLOT

	BZD	LOF2X

	MPYF	R3,R2
	OR	R2,R0
	LDF	R0,R0

	BGT	POLYLP_1
LOF2X

*
*AR4,AR5,AR2,AR3 = FOUR VERTICES
*IR1=PALETTE
*
	CALL	CLIPCK
	BNZD	CLIPIT_1		;GO CLIP IT DUDES
	LDI	*AR1++(2),R2		;get control word/palette
	LSH	R6,R2,R0		;SHIFT 16 TO RIGHT
	LDI	BK,R0
	;------->BNZD	CLIPIT_1	;YES SPLIT IT UP...

	STI	R2,*AR7

;	LSH	R6,*AR4,R0		;PALETTE->R0
; 	LSH	8,R0			;not a good way to do this fix l8r -7/14/93

*NO CLIP, BLOW IT OUT

BLOWOUT_1

	RPTS	7
	LDI	*AR0++,R0
 ||	STI	R0,*AR7

	NOP	*AR0--(8)		;READJUST INDEX DUDES...

	LDI	*AR1++,R0		;2 AIV packed format Y2:X2:Y1:X1
 ||	STI	R0,*AR7

	STI	R0,*AR7
	LSH	-16,R0

	LDI	*AR1++,R0		;GET Y4:X4:Y3:X3
 ||	STI	R0,*AR7

	STI	R0,*AR7
	LSH	-16,R0

	DBUD	AR6,PLOTPOLYLP_1

	LDI	*AR1++,R0
 ||	STI	R0,*AR7

	STI	R0,*AR7			;STORE THE ADDR
	LDI	@FIFO_INC,R0
	;----> DBUD AR6,PLOTPOLYLP_1

	POP	AR0			;RESTORE OBJECT POINTER
	RETS

POLYLP_1
	DBUD	AR6,PLOTPOLYLP1_1
	LDI	*++AR1(6),R3		;read internal vertices (v4|v3|v2|v1)
	SUBI	1,AR1
	AND	R7,R3,AR4
	;----> DBUD AR6,PLOTPOLYLP1_1

	POP	AR0
	RETS
*CLIP IT
CLIPIT_1
	CALL 	CLIP
	DBU	AR6,PLOTPOLYLP_1

	POP	AR0
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*PLOT A DISTANT 1 PALETTE POLYGON
*
*IR0=BLOWLIST
*IR1=BLOWLIST+1
*RC=POLYGON COUNT
*
PLT1PAL:

	CMPI	50,RC			;BIG OBJECT?
	BLTD	PLT1PAL1
	LDI	0FFH,R7			;GET MASK
	LDI	*+AR0(OPAL),R6
	LDI	*+AR0(ODIST),R0		
	;------>BLTD	PLT1PAL1

	CMPI	DEGRADE_DIST,R0		;CHECK IF DISTANT
	BGT	PLT1PAL1		;YES, FORGET IT

	LDI	*+AR0(OID),R0		;CHECK FOR CAR
	CMPI	484H,R0	   		;OPENING FERRARI?
	BZ	PLTG1PAL		;YES...

	AND	CLASS_M,R0
	CMPI	DRONE_C,R0

	BGT	PLT1PAL1		;NOT A CAR
	CMPI	PLYR_C,R0
	BGE	PLTG1PAL		;ITS A CAR...

PLT1PAL1
	BUD	PLTPOLYLP_2
	LDP	@FIFO_STATUS
	LDI	FIFO_ADDR>>16,AR7
	LSH	16,AR7
	;------->BD	PLTPOLYLP_2

	.align 
PLTPOLYLP_2
	RPTB	PLTPOLL_2
	LDI	*+AR1(1),R3		;read internal vertices (v4|v3|v2|v1)
	AND	R7,R3,AR4
PLTPOLYLP1_2
	MPYI	3,AR4			;V1

	LSH	-8,R3
	AND	R7,R3,AR5
	MPYI	3,AR5			;V2

	LSH	-8,R3
	AND	R7,R3,AR2
	MPYI	3,AR2			;V3
PLTWT_2
	;CHECK FIFO FULL

	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZD	PLTWT_2

	;CHECK HIDDEN SURFACE REMOVAL

	SUBF	*+AR4(IR0),*+AR5(IR0),R1	;dx = ax - bx
	SUBF	*+AR4(IR1),*+AR5(IR1),R2	;dy = ay - by
	SUBF	*+AR2(IR0),*+AR5(IR0),R0	;ex = cx - bx
	;------->BNZD	PLTWT_2

	MPYF	R2,R0,R0			;ex = dy * ex
  ||	SUBF	*+AR2(IR1),*+AR5(IR1),R2	;ey = cy - by

	MPYF	R1,R2			;ey = dx * ey

	SUBF	R0,R2			;ey = ey - ex
	BGTD	PLTLP1_2		;if back facing DONT PLOT

	LSH	-8,R3			;START GETTING V4
	LDI	3,R1
	NOP
	;------->BGTD	PLTLP1_2

	LDI	*AR1++(2),R2		;get control word

	LDI	R2,R0			;SHIFT 16 TO RIGHT
	RS	16,R0
	MPYI	R1,R3,AR3		;GET LAST VERTEX  V4
	
	STI	R2,*AR7


	FIX	*+AR4(IR0),R0		;READ X1
 ||	STI	R6,*AR7			;STUFF the PALETTE

	FIX	*+AR4(IR1),R0		;READ X1
 ||	STI	R0,*AR7

	FIX	*+AR5(IR0),R0		;READ X2
 ||	STI	R0,*AR7
	FIX	*+AR5(IR1),R0		;READ Y2
 ||	STI	R0,*AR7

	FIX	*+AR2(IR0),R0		;READ X3
 ||	STI	R0,*AR7
	FIX	*+AR2(IR1),R0		;READ Y3
 ||	STI	R0,*AR7

	FIX	*+AR3(IR0),R0		;READ X4
 ||	STI	R0,*AR7
	FIX	*+AR3(IR1),R0		;READ Y4
 ||	STI	R0,*AR7
 	STI	R0,*AR7

	LDI	*AR1++,R0
	LDI	*AR1++,R1
	LDI	*AR1++,R2
 ||	STI	R0,*AR7

	LSH	-16,R0
	STI	R0,*AR7

 	STI	R1,*AR7
	LSH	-16,R1
	STI	R1,*AR7
 	STI	R2,*AR7

PLTPOLL_2
	LDI	@FIFO_INC,R0
	RETS

PLTLP1_2
	SUBI	1,RC
	LDI	RC,R0
	BNND	PLTPOLYLP1_2
	LDI	*++AR1(6),R3		;read internal vertices (v4|v3|v2|v1)
	SUBI	1,AR1
	AND	R7,R3,AR4
	;----> BNND PLTPOLYLP1_2
	RETS

*****************************
*PLOT A DISTANT 1 PALETTE POLYGON GLITCH FIX
*
PLTG1PAL

	BUD	PLTGPOLYLP_2
	LDP	@FIFO_STATUS
	LDI	FIFO_ADDR>>16,AR7
	LSH	16,AR7
	;------->BD	PLTGPOLYLP_2

	.align 
PLTGPOLYLP_2
	RPTB	PLTGPOLL_2
	LDI	*+AR1(1),R3		;read internal vertices (v4|v3|v2|v1)
	AND	R7,R3,AR4
PLTGPOLYLP1_2
	MPYI	3,AR4			;V1

	LSH	-8,R3
	AND	R7,R3,AR5
	MPYI	3,AR5			;V2

	LSH	-8,R3
	AND	R7,R3,AR2
	MPYI	3,AR2			;V3

	LSH	-8,R3
	AND	R7,R3,AR3
	MPYI	3,AR3			;V4

PLTGWT_2
	;CHECK FIFO FULL

	LDI	@FIFO_STATUS,R0
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZD	PLTGWT_2

	;CHECK HIDDEN SURFACE REMOVAL

	SUBF	*+AR4(IR0),*+AR5(IR0),R1	;dx = ax - bx
	SUBF	*+AR4(IR1),*+AR5(IR1),R3	;dy = ay - by
	SUBF	*+AR5(IR0),*+AR2(IR0),R0	;ex = bx - cx
	;------->BNZD	PLTGWT_2

	MPYF	R3,R0				;ex = dy * ex
  ||	SUBF	*+AR5(IR1),*+AR2(IR1),R2	;ey = by - cy

	MPYF	R2,R1				;ey = dx * ey

	SUBF	R1,R0				;ey = ey - ex
	BGTD	PLTGLP1_2			;if back facing DONT PLOT

*LOF KLUDGE - CHECK FOR NON-PLANAR

	SUBF	*+AR2(IR1),*+AR3(IR1),R0
	MPYF	R3,R0
||	SUBF	*+AR3(IR1),*+AR4(IR1),R3
	CMPI	AR2,AR3
	BZD	LOF4X

	MPYF	R3,R2
	OR	R2,R0
	LDF	R0,R0

	BGT	PLTGLP1_2
LOF4X

	LDI	*AR1++(2),R2		;get control word

	LDI	R2,R0			;SHIFT 16 TO RIGHT
	RS	16,R0
	
	STI	R2,*AR7

	FIX	*+AR4(IR0),R0		;READ X1
 ||	STI	R6,*AR7			;STUFF the PALETTE

	FIX	*+AR4(IR1),R0		;READ X1
 ||	STI	R0,*AR7

	FIX	*+AR5(IR0),R0		;READ X2
 ||	STI	R0,*AR7
	FIX	*+AR5(IR1),R0		;READ Y2
 ||	STI	R0,*AR7

	FIX	*+AR2(IR0),R0		;READ X3
 ||	STI	R0,*AR7
	FIX	*+AR2(IR1),R0		;READ Y3
 ||	STI	R0,*AR7

	FIX	*+AR3(IR0),R0		;READ X4
 ||	STI	R0,*AR7
	FIX	*+AR3(IR1),R0		;READ Y4
 ||	STI	R0,*AR7
 	STI	R0,*AR7

	LDI	*AR1++,R0
	LDI	*AR1++,R1
	LDI	*AR1++,R2
 ||	STI	R0,*AR7

	LSH	-16,R0
	STI	R0,*AR7

 	STI	R1,*AR7
	LSH	-16,R1
	STI	R1,*AR7
 	STI	R2,*AR7

PLTGPOLL_2
	LDI	@FIFO_INC,R0
	RETS
PLTGLP1_2
	SUBI	1,RC
	LDI	RC,R0
	BNND	PLTGPOLYLP1_2
	LDI	*++AR1(6),R3		;read internal vertices (v4|v3|v2|v1)
	SUBI	1,AR1
	AND	R7,R3,AR4
	;----> BNND PLTGPOLYLP1_2

	RETS
*----------------------------------------------------------------------------
*PLOTILLUM
*
*For most purposes this routine mirrors what PLOTPOLY does,
*except that it has been streamlined for use with ILLUMINATED
*objects
*
*v4.00:	THIS IS THE ONLY SUBSYSTEM WHICH ACCEPTS NORMALS IN THE POLYGON
*	DATA BLOCK.
*
*	struct ROM_ILLUM_POLYGON  {
*		int	cntl
*		float	Nx,Ny,Nz
*		int	(v4<<24)|(v3<<16)|(v2<<8)|(v1)
*	}
*
*
PLOTILLUM:
	PUSH	AR0
;	LDI	*+AR0(OFLAGS),R6
	LSH	-16,R6
	AND	0FFh,R6			;get the color field out of the object flags

;	LDIL	BLOWLIST,IR0
;	LDI	IR0,IR1
;	INC	IR1

	LDIL	FIFO_STATUS,AR0		;FIFO EMPTY STATUS
	LDI	FIFO_ADDR>>16,AR7	;FIFO ADDRESS
	LS	16,AR7

	LDI	BK,AR6			;# of polygons-1

ILLUM_PLOTPOLYLP

	;CHECK HIDDEN SURFACE REMOVAL
	LDI	*+AR1(4),R0		;read vertex (v4|v3|v2|v1)
	LDI	R0,AR4			;
	AND	0FFh,AR4		;v1
	MPYI	3,AR4
	LDI	R0,AR5			;
	RS	8,AR5			;
	AND	0FFh,AR5		;v2
	MPYI	3,AR5
	LDI	R0,AR2			;
	RS	16,AR2			;
	AND	0FFh,AR2		;v3
	MPYI	3,AR2

	SUBF	*+AR4(IR0),*+AR5(IR0),R1	;dx = ax - bx
	SUBF	*+AR4(IR1),*+AR5(IR1),R5	;dy = ay - by
	SUBF	*+AR2(IR0),*+AR5(IR0),R0	;ex = cx - bx

	MPYF	R5,R0,R0			;ex = dy * ex
  ||	SUBF	*+AR2(IR1),*+AR5(IR1),R2	;ey = cy - by

	MPYF	R1,R2			;ey = dx * ey

	SUBF	R0,R2			;ey = ey - ex
	BGT	ZCLIP		;if back facing DONT PLOT


*
*GET ILLUMINATION PALETTE TO BE USED
*ROTATE NORMAL VECTOR BY OBJECT/UNIVERSE RAOTATION MATRIX
*
ILLUM1
	LDI	*AR1++,R7			;get control word
;	LDP	@tmpmatY			;DP loaded with low memory area
	LDI	@tmpmatY,AR3			;
	LDI	@transmatrixI,AR5		;these are in same memory area

	LDF	*AR1++,R3			;get the NORMAL.x
	LDF	*AR1++,R4			;	       .y
 ||	STF	R3,*-AR3(1)
	LDF	*AR1++,R5			;	       .z
 ||	STF	R4,*AR3

	NOP 	*AR5++(8)		   	;FAST ADD TO AR5
	MPYF	*AR5--,R5,R0
 ||	STF	R5,*+AR3(1)
	MPYF	*AR5--,*AR3,R1
	MPYF	*AR5--,*-AR3(1),R0
 ||	ADDF	R0,R1,R2
	ADDF	R0,R2,R1
; 	BND	ZCLIP1			     	;BLOW OUT OF HERE, Z NEG IS BACKFACER


	MPYF	*AR5--,R5,R0
	MPYF	*AR5--,R4,R2
	MPYF	*AR5--,*-AR3(1),R0
 ||	ADDF	R0,R2,R2

	MPYF	*AR5--,*+AR3(1),R0
 ||	ADDF	R0,R2,R2
	MPYF	*AR5--,R4,R3
	MPYF	*AR5--,*-AR3(1),R0
 ||	ADDF	R0,R3,R3
	ADDF	R0,R3,R3


	;R1=Z, R2=Y, R3=X ROTATED NORMAL
	;GENERATE ILLUMINATION DOT PRODUCT
	;
	LDI	@LIGHTIY,AR5			;again, DP in same memory area

	MPYF	*-AR5(1),R3,R3			;generate dot product to get
	MPYF	*AR5,R2,R2			;illumination level
	MPYF	*+AR5(1),R1,R1
	ADDF	R2,R1,R5
	ADDF	R3,R5


	MPYF	-8,R5				;actually:  R1 = (int) ((R1*.-5)+.5)*16
	ADDF	8,R5				;the 2 is because illum pals begin at PAL2
	FIX	R5				;R1 now has illumintation level index (0-15)
	LDI	FASTCC,R7				;fake it out
;	OR	R6,R7				;or in the illum color
	OR	R5,R7		;or in color spec
	LDI	200h,R5		;second palette

ILLUMFF	LDI	*AR0,R0				;FIFO_WT replacement
	AND	FIFO_STATUS_MAX_FLAG,R0
	BNZ	ILLUMFF				;ILLUM FIFO WAIT

	STI	R7,*AR7				;CONTROL WORD from above
;	LSH	8,R5	;fix l8r
	STI	R5,*AR7				;PALETTE

	LDI	*AR1++,AR2
	CLRI	R3

	LDI	3,RC
	RPTB	LP1

	LDI	AR2,AR3
	LSH	R3,AR3
	AND	0FFh,AR3
	MPYI	3,AR3
	SUBI	8,R3
	FIX	*+AR3(IR0),R0
	FIX	*+AR3(IR1),R0
 ||	STI	R0,*AR7				;x[n]
LP1	STI	R0,*AR7				;y[n]

	LDI	*+AR0(FIFO_INC-FIFO_STATUS),R0	;FIFO_INC replacement

ILLUM_POLYLP
	DBU	AR6,ILLUM_PLOTPOLYLP

	POP	AR0
	RETS
ZCLIP
	ADDI	5,AR1
	DBU	AR6,ILLUM_PLOTPOLYLP
	POP	AR0
	RETS
ZCLIP1
	ADDI	5,AR1
	DBU	AR6,ILLUM_PLOTPOLYLP
	POP	AR0
	RETS
*----------------------------------------------------------------------------
*warning moving this to top of file will crash program ask ti why

CLIPRAMI	     	.WORD	CLIPRAM

	.END
