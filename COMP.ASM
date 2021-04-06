	.FILE	"COMP.ASM"
*----------------------------------------------------------------------------
*DECOMPRESSION SYSTEM
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	C30.EQU
	.include	MACS.EQU
	.include	MPROC.EQU
	.include	VUNIT.EQU
	.include	SYSID.EQU
	.include	SYS.EQU
	.include	GLOBALS.EQU
	.include	OBJECTS.EQU
	.include	TEXT.EQU


	.bss	PADDING,50


	.bss	DECOMP_ACTIVE,1
	.bss	HARD_SECTION_LOAD,1
	.bss	FLUSH_COUNT,1


	.bss	PACIFY_COUNT,1	
PACIFY_MOMENT	.set	2048
;PACIFY_MOMENT	.set	512


*----------------------------------------------------------------------------
*REGISTER ALLOCATION
*
*AR0	SADDR	(source addr or bitstream)
*AR1	DADDR	(dest addr)
*AR2	scratch
*AR3	DICTI
*AR4	scratch
*AR5	scratch
*AR6	CURRENT_CODE_BITS
*AR7	BIT_ADDR
*
*R0	scratch
*R1	scratch
*R2	scratch
*R3	PUTC_SH
*R4	new_code
*R5	old_code
*R6	character
*R7	BUFCNT
*
*
*IR0	CHARACTER (offset)
*IR1	PUTC_BUF
*BK	NEXT_CODE
*
*RC	count
*RS
*RE
*
*


PUTC_SH		EQU	R3
PUTC_BUF	EQU	IR1

new_code	EQU	R4
old_code	EQU	R5
character	EQU	R6
bufcnt		EQU	R7


count		EQU	RC

retval		EQU	R0

BIT_ADDR		EQU	AR7
CURRENT_CODE_BITS	EQU	AR6
NEXT_CODE		EQU	BK



*
*
BITS		.set	12
MAX_CODE	.set	(( 1 << BITS) -1 )
TABLE_SIZE	.set	4421

END_OF_STREAM	.set	256
BUMP_CODE	.set	257
FLUSH_CODE	.set	258
FIRST_CODE	.set	259
UNUSED		.set	-1
*
*

*STRUCT	dictionary
PARENT_CODE	.set	0	;UH	LOWER HALF
CODE_VALUE	.set	0	;UH	UPPER HALF
CHARACTER	.set	TABLE_SIZE	;UH	LOWER 8 (bitchen jive techn.)
DICT_SIZ	.set	2	;SIZ
*ENDSTRUCT


CPU_WSI		.word	CPU_WS


DICTI		.word	DICT
DECODE_STACKI	.word	DECODE_STACK


		hibss	DICT,TABLE_SIZE*DICT_SIZ
		hibss	DECODE_STACK,TABLE_SIZE
		.bss	NEXT_BUMP_CODE,1

LINEBUFFERI	.word	LINEBUFFER
	lobss	LINEBUFFER,64




*----------------------------------------------------------------------------
*
*BIT_ADDR
*SADDR
*CURRENT_CODE_BITS
*
*
*
INPUT_BITS:
	ADDI	CURRENT_CODE_BITS,BIT_ADDR,R0
	IFI	R0,GT,31,MULTIWORD

	LDI	*AR0,R0				;get data
	LSH	BIT_ADDR,R0
	LDI	CURRENT_CODE_BITS,R1
	SUBI	32,R1
	LSH	R1,R0
	ADDI	CURRENT_CODE_BITS,BIT_ADDR
	RETS

MULTIWORD

	LDI	*AR0++,R1

	LSH	BIT_ADDR,R1		;left justify
	LDI	32,R0
	SUBI	BIT_ADDR,R0		;how many bits in 1st word

	LDI	CURRENT_CODE_BITS,R2
	SUBI	R0,R2			;bits remaining in second word
	LDI	R2,BIT_ADDR

	LDI	*AR0,R0
	SUBI	32,R2
	LSH	R2,R0			;second word now is right justified w/proper bits

	LDI	CURRENT_CODE_BITS,R2
	SUBI	32,R2
	LSH	R2,R1
	OR	R1,R0

	RETS
*----------------------------------------------------------------------------





*----------------------------------------------------------------------------
*PARAMETERS
*	R0	CHARACTER (BYTE) TO OUTPUT
*	AR1	DADDR
*
*
PUTC:
	LDI	@LINEBUFFERI,AR2
	ADDI	bufcnt,AR2
	INC	bufcnt

	STI	PUTC_BUF,*AR2		;for AR timing
	CLRI	PUTC_BUF
	CLRI	PUTC_SH

	CMPI	64,bufcnt
	RETSLT

;	LDP	@_newbut
;	NOT	@_newbut,R0
;	TSTB	SW_DIAG,R0
;	BNZ	ENTER_DIAG
;	LDP	@DIPRAM
;	NOT	@DIPRAM,R0
;	TSTB	DIP_DIAG,R0
;	BNZ	ENTER_DIAG


	.if	DEBUG
	LDI	0A0h,AR2
	LS	16,AR2
	CMPI	AR2,AR1

	SLOCKON	LT,"COMP\PUTC   ATTEMPT UNDER WRITE OF WAVERAM"

	LDI	0BFh,AR2
	LS	16,AR2
	CMPI	AR2,AR1

	SLOCKON	GT,"COMP\PUTC  ATTEMPT OVER WRITE OF WAVERAM"
	.endif


	;PACIFY
	LDI	@PACIFY_COUNT,R0
	ADDI	64,R0
	STI	R0,@PACIFY_COUNT
	;


	CLRI	bufcnt
	PUSH	AR4
	LDI	@LINEBUFFERI,AR4
	CLRI	AR2			;for dummy read

	PUSH	ST			;this push must be here
	PUSH	RC
	PUSH	RE
	PUSH	RS
	PUSH	R7

	PUSH	IE
	LDP	@COMMINTM
	LDI	@COMMINTM,IE
	SETDP

;	PUSH	IE			;disable interrupts
;	LDI	0,IE			;watch for pipeline conflicts
	LDI	HARD_WS,R0
	LDI	SOFT_WS,R1
;	AND	0DFFFh,ST		;turn off GIE.
;	POP	IE


	LDP	@CPU_WS
	STI	R0,@CPU_WS		;set hard wait states

	LDI	63,RC
	LDI	-16,R7
	RPTB	WVWRLP2
	LDI	*AR4,R2			;read from the buffer
    	STI	R2,*AR1++		;write to wave ram
 	LSH	R7,*AR4++,R2		;read/shift right
WVWRLP2	STI	R2,*AR1++		;write to wave ram


	LDI	*AR4,R2			;DUMMY READ TO CLEAR THE LINE
	STI	R1,@CPU_WS		;set soft wait states
	SETDP

	POP	IE

	POP	R7			;this pop sequence must be here
	POP	RS
	POP	RE
	POP	RC
	POP	ST

	BUD	ENABLEGIE
	POP	AR4
	CLRI	PUTC_BUF
	CLRI	PUTC_SH
	;---->	BUD	ENABLEGIE
*----------------------------------------------------------------------------




*----------------------------------------------------------------------------
*
*PARAMETERS
*	AR4	SADDR
*	AR5	DADDR
*
*
DECOMPRESS:
	CALL	PUSHALL


	;
	;NEW ADDITION.  DONT F*CK THE WAVERAM
	;
	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	CALL	FIFO_RESET
	;
	;


	LDI	1,R0
	STPI	R0,@DECOMP_ACTIVE
	CLRI	R0
	STPI	R0,@FLUSH_COUNT




	LDI	AR4,AR0				;SADDR
	LDI	AR5,AR1				;DADDR

	CLRI	bufcnt

	LDI	@DICTI,AR3
	LDI	CHARACTER,IR0
	CLRI	BIT_ADDR

	CLRI	PUTC_BUF
	CLRI	PUTC_SH

	CALL	SAVE_DECOMP_REGS

	LDI	@HARD_SECTION_LOAD,R0
	BZ	NOHARDLOAD
	CALL	DECOMPRESS_PROC

NOHARDLOAD

	CALL	POPALL
	RETS




DECOMPRESS_TOPLP

;	LDI	@FLUSH_COUNT,R0
;	INC	R0
;	STPI	R0,@FLUSH_COUNT
;	IFI	R0,LT,3,DECOMPRESS_TOPLP3
;	CLRI	R0
;	STPI	R0,@FLUSH_COUNT


	CALL	FEED_WATCHDOG

	;
	LDI	@PACIFY_COUNT,R0
	CMPI	PACIFY_MOMENT,R0
	BLT	DECOMPRESS_TOPLP3
	;


	LDI	@HARD_SECTION_LOAD,R0
	BZ	CONT

	LDI	@BOOT_PACIFY_SCREEN_P,R0
	CALLNZ	BOOT_PACIFY_SCREEN

	BU	DECOMPRESS_TOPLP3
CONT


	CALL	SAVE_DECOMP_REGS
	CALL	POPALL

;	CALL	ENABLEGIE
	RETS


DECOMPRESS_PROC:

	LDI	@DECOMP_ACTIVE,R0
	RETSZ


	;
	;NEW ADDITION.  DONT F*CK THE WAVERAM
	;
	FIFO_CLRP	R0		;IS THE FIFO CLEAR
	DMA_WT		R0
	CALL	FIFO_RESET
	;
	;
	



	;PACIFIER
	CLRI	R0
	STPI	R0,@PACIFY_COUNT
	;

;	PUSH	IE			;disable interrupts
;	LDI	0,IE			;watch for pipeline conflicts
;	LDI	HARD_WS,R0
;	LDI	SOFT_WS,R1
;	AND	0DFFFh,ST		;turn off GIE.
;	POP	IE




DECOMPRESS_TOPLP2
	CALL	PUSHALL
	CALL	RESTORE_DECOMP_REGS
;	CALL	FEED_WATCHDOG

DECOMPRESS_TOPLP3
	LDI	FIRST_CODE,NEXT_CODE
	LDI	9,CURRENT_CODE_BITS
	LDI	511,R0
	STPI	R0,@NEXT_BUMP_CODE


	CALL	INPUT_BITS		;returns in R0
	LDI	R0,old_code		;old_code = INPUTBITS()
	IFI	old_code,EQ,END_OF_STREAM,DECOMPRESSX
	LDI	old_code,character	;character = old_code

	;redun	LDI	old_code,R0

	LSH	PUTC_SH,R0		;this is inlined!
	OR	R0,PUTC_BUF		;
	ADDI	8,PUTC_SH		;
	CMPI	32,PUTC_SH		;
	CALLGE	PUTC


;	CALL	PUTC			;


DECOMPRESSLP

	CALL	INPUT_BITS
	LDI	retval,new_code
	CMPI	END_OF_STREAM,new_code
	BEQ	DECOMPRESSX

	CMPI	FLUSH_CODE,new_code
	BEQ	DECOMPRESS_TOPLP

	CMPI	BUMP_CODE,new_code
	BNE	NOBUMP

	INC	CURRENT_CODE_BITS
	BU	DECOMPRESSLP
NOBUMP

	CMPI	NEXT_CODE,new_code
	BLTD	NODS

	LDP	@DECODE_STACKI
	LDI	@DECODE_STACKI,AR4
	CLRI	count
;	NOP
	;---->	BLTD	NODS

	BUD	NODSRT
	STI	character,*AR4++		;decode_stack[0] = character
	LDI	1,count				;count
	LDI	old_code,AR5			;code
	;---->	BUD	NODSRT
NODS
;	CLRI	count
	LDI	new_code,AR5
NODSRT



	IFI	AR5,LE,255,DECODEL1i		;while( code > 255)  {
DECODEL3i
	ADDI	AR3,AR5
	LDI	*+AR5(IR0),R0			;CHARACTER
	STI	R0,*AR4++			;decode_stack[ count++] = DICT[ code].character
	INC	count				;must keep counter correct
	LDI	*+AR5(PARENT_CODE),AR5		;code = DICT[code].parent_code
	CMPI	255,AR5
	BGT	DECODEL3i

DECODEL1i

	LDI	AR5,character
	LDI	AR5,R0				;setup the first write

	RPTB	BLOOPER
	LSH	PUTC_SH,R0		;this is inlined!
	OR	R0,PUTC_BUF		;
	ADDI	8,PUTC_SH		;
	CMPI	32,PUTC_SH		;
	CALLGE	PUTC

	;CALL	PUTC
BLOOPER	LDI	*--AR4,R0			;and this becomes a pre-decrement

	ADDI	NEXT_CODE,AR3,AR2
	STI	old_code,*+AR2(PARENT_CODE)	;DICT[next_code].parent = old_code

	BUD	DECOMPRESSLP
	STI	character,*+AR2(IR0)		;DICT[next_code].character = character
	INC	NEXT_CODE
	LDI	new_code,old_code
	;---->	BUD	DECOMPRESSLP

DECOMPRESSX

	CLRI	R0
	STPI	R0,@DECOMP_ACTIVE
	STPI	R0,@HARD_SECTION_LOAD
	CALL	POPALL
	RETS
*----------------------------------------------------------------------------


SAVESPCI	.word	SAVESPC+1
	.bss	SAVESPC,25
*----------------------------------------------------------------------------
SAVE_DECOMP_REGS:
	LDP	@SAVESPC
	STI	AR0,@SAVESPC

	LDI	@SAVESPCI,AR0
	STI	AR1,*AR0++
	STI	AR2,*AR0++
	STI	AR3,*AR0++
	STI	AR4,*AR0++
	STI	AR5,*AR0++
	STI	AR6,*AR0++
	STI	AR7,*AR0++

	STI	R1,*AR0++
	STI	R2,*AR0++
	STI	R3,*AR0++
	STI	R4,*AR0++
	STI	R5,*AR0++
	STI	R6,*AR0++
	STI	R7,*AR0++

	STI	RC,*AR0++
	STI	RE,*AR0++
	STI	RS,*AR0++
	STI	IR0,*AR0++
	STI	IR1,*AR0++
	STI	BK,*AR0++

	RETS
*----------------------------------------------------------------------------



*----------------------------------------------------------------------------
RESTORE_DECOMP_REGS:

	LDI	@SAVESPCI,AR0
	LDI	*AR0++,AR1
	LDI	*AR0++,AR2
	LDI	*AR0++,AR3
	LDI	*AR0++,AR4
	LDI	*AR0++,AR5
	LDI	*AR0++,AR6
	LDI	*AR0++,AR7

	LDI	*AR0++,R1
	LDI	*AR0++,R2
	LDI	*AR0++,R3
	LDI	*AR0++,R4
	LDI	*AR0++,R5
	LDI	*AR0++,R6
	LDI	*AR0++,R7

	LDI	*AR0++,RC
	LDI	*AR0++,RE
	LDI	*AR0++,RS
	LDI	*AR0++,IR0
	LDI	*AR0++,IR1
	LDI	*AR0++,BK

	LDP	@SAVESPC
	LDI	@SAVESPC,AR0

	RETS
*----------------------------------------------------------------------------


MIN_X	.set	240	;if this changes modify CUSA.ASM
MAX_X	.set	300

BOOT_PACIFY_SCREEN_P	.word	1

	.bss	PREVX,1
	.bss	DELTA,1

;PREVX		.word	MIN_X
;DELTA		.word	1

*----------------------------------------------------------------------------
BOOT_PACIFY_SCREEN:

	CALL	SAVE_DECOMP_REGS

	LDI	@PREVX,R6

	LDI	R6,AR2
	LDI	R6,R3
	LDI	111,R2
	LDI	116,RC

;	LDI	@DELTA,R0
;	LDILT	0,RS
;	LDIGT	11,RS
	LDI	0,RS
	CALL	_line

	LDI	@PREVX,R6
	LDI	@DELTA,R7
	ADDI	R7,R6
	STI	R6,@PREVX

	LDI	R6,AR2
	LDI	R6,R3
	LDI	111,R2
	LDI	116,RC
	LDI	3,RS
	CALL	_line


	LDI	@PREVX,R6
	CMPI	MIN_X,R6
	BGT	LL
	LDI	1,R7
	STPI	R7,@DELTA
LL
	CMPI	MAX_X,R6
	BLT	LLL
	LDI	-1,R7
	STPI	R7,@DELTA
LLL

	CALL	RESTORE_DECOMP_REGS
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
*SECTION LOAD REQUEST
*	IF ACTIVE THEN REQUEST IS QUEUED BY CREATING A PROCESS
*
*
*PARAMETERS
*	AR2	POINTER TO SECTION CONTROL
*
	.bss	LASTLOAD,1	;CACHE THE LAST LOAD

LOAD_SECTION_REQ:
	PUSH	AR4
	PUSH	AR5

	LDI	@DECOMP_ACTIVE,R0
	BZ	NOWTLD

	;a decompression is executing, queue the request
	;
	;
	PUSH	R2
	PUSH	AR0
	PUSH	AR4
	LDI	AR2,AR4
	CREATE	REQWAIT,SPAWNER_C|LOAD_REQ_T
	POP	AR4
	POP	AR0
	POP	R2
	BU	NOLOAD
NOWTLD
;	LDI	@LASTLOAD,AR0
;	CMPI	AR0,AR2
;	BEQ	NOLOAD
;	STI	AR2,@LASTLOAD




	LDI	*AR2++,AR4
	LDI	*AR2++,AR5
	CALL	DECOMPRESS
NOLOAD
	POP	AR5
	POP	AR4
	RETS
*----------------------------------------------------------------------------


*----------------------------------------------------------------------------
REQWAIT:
	SLEEP	1
	LDI	@DECOMP_ACTIVE,R0
	BNZ	REQWAIT

	LDI	AR4,AR2
	CALL	LOAD_SECTION_REQ
	DIE
*----------------------------------------------------------------------------
	.END
