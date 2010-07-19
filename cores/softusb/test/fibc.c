/* test for Navre core - compute Fibonacci numbers recursively, C version */

char fib(char n)
{
	if(n == 0) return 1;
	if(n == 1) return 1;
	return fib(n-1) + fib(n-2);
}

