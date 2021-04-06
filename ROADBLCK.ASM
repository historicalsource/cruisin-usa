	.FILE	"ROADBLCK.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	MACS.EQU
	.include	OBJ.EQU
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


*----------------------------------------------------------------------------
*RDDEBRIS_C
*
*THIS FILE HANDLES THE RDDEBRIS (Road Debris) CLASS
*OF OBJECTS.
*
*
*This Class has the following properties:
*
*	o	associated with a road piece
*	o	single point collision
*	o	has reaction to this collision
*
*
*Association assertions:
*
*In this class all objects are pulled from the object
*list and then sorted as normal (ala DRONES).  The objects
*are then reinserted onto the object list (exactly in front
*of the road piece it is associated with.
*
*
*


ROAD_DEBRISI	.word	ROAD_DEBRIS
		.bss	ROAD_DEBRIS,1	;linked list head

*----------------------------------------------------------------------------
INIT_RDDEBRIS:
	CLRI	R0
	STPI	R0,@ROAD_DEBRIS
	RETS
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*INSERT OBJECT ONTO THE ROAD DEBRIS LIST
*
*take object and insert on list and insert the closest
*road object to it
*
*OBJECT STRUCTURE ENTRIES USED:
*	OLINK3	list link
*	OUSR1	linked object
*
*PARAMETERS
*	AR4	OBJECT
*
*
ADD_RDDEBRIS:
	PUSH	R0
	LDI	@ROAD_DEBRIS,R0

	.if	DEBUG
	CMPI	AR4,R0
	BEQ	$			;Linking to ones self is not good
	.endif

	STI	R0,*+AR4(OLINK3)
	STI	AR4,@ROAD_DEBRIS

	LDI	1,R0
	LS	O_DEBRIS_B,R0
	OR	*+AR4(OFLAGS),R0
	STI	R0,*+AR4(OFLAGS)

	LDI	RDDEBRIS_C|TSC_FLYING,R0
	STI	R0,*+AR4(OID)
	LDI	0,R0
	STI	R0,*+AR4(OUSR1)

	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*PULL OBJECT FROM ROAD DEBRIS LIST
*
*PARAMETERS
*	AR2	OBJECT
*
FREE_RDDEBRIS:
	PUSH	R0
	PUSH	AR1

	LDPI	@ROAD_DEBRISI,R0
	SUBI	OLINK3,R0		;(we are offset pointing)

FREELP	LDI	R0,AR1
	LDI	*+AR1(OLINK3),R0
	.if	DEBUG
	BZ	$			;lockup on end of list found
	.endif
	BZ	FREEDR_X

	CMPI	R0,AR2
	BNE	FREELP

	LDI	*+AR2(OLINK3),R0
	STI	R0,*+AR1(OLINK3)	;LINK AROUND
FREEDR_X
	POP	AR1
	POP	R0
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SORT YOUR DEBRIS IN THE WORLD
*
*PARAMETERS
*	AR4	PULL LIST HEADER
*
*
MAXDIST	.FLOAT	9999999999.0  		;A VERY LARGE NUMBER
*
DEBRIS_SORT:

	;PULL FLYING DEBRIS FROM THE LIST
	;
	BUD	DSORTNXT     		
	NOP
	LDI	0,AR4			;INIT DRONE LIST HEADER
	LDI	@OACTIVEI,AR1		;GET OBJECT LIST POINTER
	;---->	BD DSORTNXT     	;GO GET FIRST ELEMENT 
DSORTL

	AND	CLASS_M,R1
	CMPI	RDDEBRIS_C,R1
	BNE	DSORTNXT

*FOUND DEBRIS, DELINK IT

	LDI	*AR1,R0			;GET POINTER TO NEXT ELEMENT
	STI	R0,*AR0			;LINK AROUND DUDE

	STI	AR4,*AR1		;LINK HIM INTO TEMP LIST
	LDI	AR1,AR4
	LDI	AR0,AR1
DSORTNXT
	LDI	*AR1,R0
	BNZD	DSORTL
	LDI	AR1,AR0			;AR4=PREVIOUS-1 LINK
	LDI	R0,AR1
	LDI	*+AR1(OID),R1
	;------>BNZD	DSORTL
DSORTX

*INSERT DEBRIS ON OBJECT LIST

	LDPI	@DYNALIST_BEGIN,R5	;ANY ROAD LIST?
	BNZD	IDB1

	LDI	OPOSZ,IR0  		;GET Z INDEX
	LDI	AR4,R0	   		;GET HEADER
	NOP
	;---->	BNZD	IDB1		;GO LOOP...
	B	IDBX			;WERE DONE, NULL LIST

DBINSLP
	LDI	*+AR4(OUSR1),R0		;DO WE HAVE A LINK
	LDI	R0,AR5
	BZ	GETRK0			;NO, GET A NEW ONE
	LDI	*+AR5(OFLAGS),R1	;BELIEVE THAT WE ARE 
	AND	O_LIST_M,R1		;CHECK VALID LIST..
	BNZ	GETLINK			;ON A REAL LIST
GETRK0
	LDF	*+AR4(OPOSX),R3		
	LDF	*+AR4(OPOSZ),R4		
GETRK
	SUBF	*+AR2(OPOSX),R3,R0
	MPYF	R0,R0

	SUBF	*+AR2(IR0),R4,R1
	MPYF	R1,R1
	ADDF	R0,R1

	CMPF	R1,R2
	LDIGT	AR2,AR5
	LDFGT	R1,R2
GETRKL
	LDI	*+AR2(OLINK4),R0
	BNZD	GETRK

	LDI	R0,AR2
	NOP		     
	NOP
	;---->	BNZ	GETRK

	STI	AR5,*+AR4(OUSR1)	;SAVE LINK

	LDI	*+AR5(OFLAGS),R1	;BELIEVE THAT WE ARE 
	AND	O_LIST_M,R1		;ON THE SAME LIST
GETLINK
	LDI	*+AR4(OFLAGS),R2	;CHANGE LIST STATUS IF NECESSARY
	ANDN	O_LIST_M,R2
	OR	R2,R1
	STI	R1,*+AR4(OFLAGS)

*
*SORT PAST SHOULDER PIECES

	LDI	@_MODE,R0
	AND	MMODE,R0
	CMPI	MBONUS,R0
	BNE	SHDONE

	LDI	AR5,AR1	     		
SHLOOP
	LDI	AR1,AR5
	LDI	*AR5,R0
	LDI	R0,AR1
	BZ	SHDONE

	LDI	*+AR1(OID),R0
	CMPI	310H,R0
	BZ	SHLOOP
	CMPI	400H,R0
	BZ	SHLOOP
	CMPI	40AH,R0
	BZ	SHLOOP
SHDONE


	LDI	*AR5,R1			;GET HIS LINK
	LDI	*AR4,R0			;GET OUR LINK
	STI	AR4,*AR5		;HE LINKS TO US
	STI	R1,*AR4			;WE LINK TO IT

	LDI	R0,AR4
IDB1
	BNED	DBINSLP
	LDI	R5,AR2			;GET ROAD LIST HEADER
	LDI	R5,AR5			;INITIAL CLOSEST CANDIDATE
	LDF	@MAXDIST,R2    		;INITIAL DISTANCE (INFINITY)
	;---->	BNED	DBINSLP
IDBX
	RETS
*----------------------------------------------------------------------------
	.END
