/*	HPmath.c
 *
 *	Copyright (C) 1994 by  TV Games, Inc.
 *	All Rights Reserved
 *
 *	These routines are for use only when a high degree of precision
 *	are nessesary.
 */



#define BITS	  23                 /* There are 23 bits in the mantissa     */
#define MAXX	  88.72283906        /* ln(HUGE_VAL)                          */
#define MAXH	  89.41598624	     /* ln(HUGE_VAL) + ln(2)                  */
#define TWO23	  8388608	     /* 2 ^ BITS                              */
#define XBIG	  8.664339757	     /* (BITS/2 + 1) * ln(2)                  */


/* macros used in sin and cos */

#define INVSPI	  0.31830988618379067154
#define HALFPI	  1.57079632679489661923

#define C1	  3.140625
#define C2	  9.67653589793e-4

#define R1	 -0.1666665668e+0
#define R2	  0.8333025139e-2
#define R3	 -0.1980741872e-3
#define R4	  0.2601903036e-5



/*	HPsin() - High Precision sine
 *
 *	Based on the algorithm from "Software Manual for the Elementary
 *	Functions", Cody and Waite, Prentice Hall 1980, chapter 8.
 *
 *	N = round(x / PI)
 *	f = x - N * PI
 *	g = f * f
 *	R = polynomial expansion
 *
 *	result = f + f * R
 *
 *	if x < 0, result = - result
 *	if N is even, result = - result
 *
 *	This will return the wrong result for x >= MAXINT * PI
 */
double	HPsin(double x)
{
	double	d,y,xn,f,g,rg;
	float	sgn = (x < 0) ? -1.0 : 1.0;
	int	n;

	x  = fabs(x);
	n  = (int) ((x * INVSPI) + 0.5);
	xn = (double) n;

	/*
	 * if n is odd, negate the sign
	 */
	if (n % 2) sgn = -sgn;

	/*
	 * f = x - xn * PI (but mathematically more stable)
	 */
	f = (x - xn * C1) - xn * C2;

	/*
	 * determine polynomial expression
	 */
	g = f * f;

	rg = (((R4 * g + R3) * g + R2) * g + R1) * g;

	return (sgn * (f + f * rg));
}



/*	HPcos() - High Precision Cosine
 *
 *	Based on the algorithm from "Software Manual for the Elementary
 *	Functions", Cody and Waite, Prentice Hall 1980, chapter 8.
 *
 *	N = round(x / PI + 1/2) - 0.5
 *	f = x - N * PI
 *	g = f * f
 *	R = polynomial expression
 *
 *	result = f + f * R
 *	if N is even, result = - result
 *
 *	This will return the wrong result for x >= MAXINT * PI
 */
double	HPcos(double x)
{
	float	sgn;           /* the sign of the result */
	double	xn,f,g,rg;
	int	n;

	/*
	 * cos(x) = cos(-x)
	 */
	x = fabs(x);

	/*
	 * n = round(x/PI + 1/2) (can be rounded this way, since positive number)
	 */
	n  = (int) (((x + HALFPI) * INVSPI) + 0.5);
	xn = (double) n - 0.5;

	/*
	 * if n is odd, negate the sign
	 */
	sgn = (n % 2) ? -1.0 : 1.0;

	/*
	 * f = x - xn * PI (but more mathematically stable)
	 */
	f = (x - xn * C1) - xn * C2;

	/*
	 * determine polynomial expression
	 */
	g = f * f;

	rg = (((R4 * g + R3) * g + R2) * g + R1) * g;
	return (sgn * (f + f * rg));
}
