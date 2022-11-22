#include <stdlib.h>
#include <stdio.h>
#include <windows.h>

main(int argc, char *argv[])
{
	int count;
	long te, ts;

	if (argc = 0)
	{
		printf("benchmark <name of executable to benchmark>");
	}

	ts = GetTickCount();
	printf("Benchmarking  : %s\n", argv[1]);
	for (count=0; count < 10; count++)
		system(argv[1]);
	te = GetTickCount();

	printf("Total execution time was %d (%d) ms\n", te - ts,(te - ts)/10);

	return 0;
}
