enum ee {
	zero,
	one,
	seven = 2 + 5
} kim;

enum ee lee;

int main(int argc, char *argv[])
{
	lee = zero;
	printf("lee = %d\n", lee);	
	return 0;
}
