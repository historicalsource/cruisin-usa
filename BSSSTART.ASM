	.FILE	"BSSSTART.ASM"
*----------------------------------------------------------------------------
*
*
*COPYRIGHT (C) 1994 BY  TV GAMES, INC.
*ALL RIGHTS RESERVED
*

	.include	MACS.EQU

	.globl	BSSSTART
	lobss	BSSSTART,0	;THIS MUST BE THE FIRST SYMBOL IN BSS
