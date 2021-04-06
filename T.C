main()
{

	char	bits1= '\x2a';
	char	bits2= '\x0f';
	char	result;


	printf("a %X\n", bits1 & bits2);
	printf("b %X\n", bits1 | bits2);
	printf("c %X\n", bits1 ^ bits2);
	printf("d %X\n", ~ bits2);
	printf("e %X\n", 5 <<3 );
}
