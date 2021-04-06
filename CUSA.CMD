/*	Cruisin USA
 *
 *	Copyright (C) 1994  by TV Games, Inc.
 *	All Rights Reserved
 *
 *	LNK_OPTIONS=-q -ic:\c30tools
 */

-o e:cusa.out
-m e:cusa.map


e:bssstart.obj

			/* SYSTEM MODULES	*/
e:dirq.obj		/* transformation system THIS MUST BE THE FIRST .OBJ */
e:cusa.obj		/* main loop, inits.	*/
e:mproc.obj		/* multi-processor	*/
e:obj.obj		/* object system	*/
e:pall.obj		/* pallette system	*/
e:util.obj		/* general utilities	*/
e:infin.obj		/* infinity roiutines 	*/

/*e:audits.obj*/

e:attrdrne.obj
e:attracta.obj
e:backgrnd.obj		/* background system	*/
e:bonus.obj


e:chopper.obj
e:coin.obj
e:colla.obj		/* Collision system	*/
e:comm.obj		/* Communications	*/
e:commdrne.obj
e:commq.obj		/* Communications Queue	*/
e:comp.obj		/* memory		*/
e:cornobj.obj
e:delta.obj		/* DELTA drone		*/
e:drones.obj
e:effects.obj
e:error.obj
e:flame.obj
e:heads.obj
e:hottub.obj
e:hpmath.obj		/* High Precision Math	*/
e:hstdp.obj
e:hud.obj		/* heads up display	*/
e:intro.obj
e:invtab30.obj		/* inverse 1/Z table	*/
e:leg.obj
e:line.obj
e:map.obj
e:math.obj		/* Math functions	*/
e:overlay.obj
e:plyr.obj
e:racer.obj		/* RACER drone		*/
e:rho.obj		/* RHO drone		*/
e:rroad.obj
e:roadblck.obj
e:roadkill.obj
e:routs.obj		/* C runtime routines	*/
e:setups.obj
e:sigma.obj		/* SIGMA drone		*/
e:snd.obj		/* sound system		*/
e:sndtaba.obj		/* sound data base	*/
e:smoke.obj
e:text.obj		/* DMA text display	*/
e:texttab.obj		/* DMA text tables	*/
e:trans.obj		/* choose transmission	*/
e:tracksel.obj		/* choose race		*/
e:totala.obj
e:wave.obj		/* wave routines	*/
e:wheel.obj


e:h2hobj.obj


/*	PCOMP Modules
 */
e:objects.obj

e:font.obj		/* CPU font		*/
e:font1a.obj		/* CPU text display	*/

/*	CMOS related stuff	
 */
e:cmos.obj
e:cointab.obj
e:memtest.obj
e:motion.obj
e:diag.obj


MEMORY
{
    VECTOR  : org = 0x000000, len = 0x040
    FASTRAM : org = 0x000040, len = 0x1EFC0
    PFASTRAM: org = 0x01F000, len = 0x007FF
    FRAM    : org = 0x8099DB, len = 0x200
    THEROM  : org = 0xC10000, len = 0x7FFF
}


SECTIONS
{
	.text   : {} > FASTRAM
	.data   : {} > FASTRAM
	.cinit  : {} > FASTRAM
	.const  : {} > FASTRAM
	pbsss	: {} > FASTRAM
	pbss	: {} > FASTRAM	/* Protected bss (only clr'd at powerup) */
	pbsse	: {} > FASTRAM
	lobss	: {} > FASTRAM
	.bss    : {} > FASTRAM	/* must start at a known location */
	hibss	: {} > FASTRAM	/* DP doesn't care */

	phibss	: {} > PFASTRAM	/* protected hi bss  (commq buffers) */

	oncram  : {} > FRAM

	THECODE : {} > THEROM
	THEDATA : {} > THEROM
	TWODATA : {} > THEROM
}

