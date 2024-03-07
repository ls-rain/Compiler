void func(int, float);

int main()
{
	int a;
	float b;
	func(a, b);

	return 0;
}

void func(int a, float b) {
	func(a, b);
}
