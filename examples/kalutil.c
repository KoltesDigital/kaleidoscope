#include <stdio.h>

// receives input from user
double input(void) {
	double r;
	if (scanf("%lf", &r)) {
		return r;
	}
	return 0;
}

// print a number to the console
double print(double v) {
	printf("%g\n", v);
	return 0;
}
