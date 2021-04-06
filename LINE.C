/*	line.c
 *
 *	Copyright (C) 1994 by  TV Games, Inc.
 *	All Rights Reserved
 */


void	rectangle(int x1,int y1,int x2,int y2,int color)
{
	asm(" PUSH DP");
	line(x1,y1,x2,y1,color);
	line(x1,y2,x2,y2,color);
	line(x1,y1,x1,y2,color);
	line(x2,y1,x2,y2,color);
	asm(" POP DP");
}


void	line(int x1,int y1,int x2,int y2,int color)
{
	int	i;
	float	yd,xd;
	float	x,y;

	asm(" PUSH DP");

#define	swap(a,b)	{ int t; t = a; a = b; b = t; }


	if (x1 == x2)  {
		if (y1 > y2) swap(y1,y2);
		for (i = y1; i <= y2; i++)
			pixel(x1,i,color);
	} else if (y1 == y2)  {
		if (x1 > x2) swap(x1,x2);
		for (i = x1; i <= x2; i++)
			pixel(i,y1,color);
	} else {

		xd = (float)((float)(x2-x1)/(float)(y2-y1));

		if (xd <= 1 && xd >= -1)  {

			if (y1 > y2)  {
				swap(x1,x2);
				swap(y1,y2);
				xd = (float)((float)(x2-x1)/(float)(y2-y1));
			}
			x = (float) x1;
			if (xd > 0)  {
				for (i = y1; i <= y2; i++)  {
					pixel((int)x,i,color);
					x += xd;
				}
			}
			else  {
				for (i = y1; i <= y2; i++)  {
					pixel((int)x,i,color);
					x += xd;
				}
			}
		} else  {
			if (x1 > x2)  {
				swap(x1,x2);
				swap(y1,y2);
				yd = (float)((float)(y2-y1)/(float)(x2-x1));
			}
			else
				yd = (float)((float)(y2-y1)/(float)(x2-x1));

			y = (float) y1;

			if (yd > 0)  {
				for (i = x1; i <= x2; i++)  {
					pixel(i,(int)y,color);
					y += yd;
				}
			}
			else  {
				for (i = x1; i <= x2; i++)  {
					pixel(i,(int)y,color);
					y += yd;
				}
			}
		}
	}

	asm(" POP DP");
}
