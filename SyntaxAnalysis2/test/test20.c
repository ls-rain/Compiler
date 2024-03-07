//함수 전방참조, 프로토타입

void func(int, float);

int main(int argc, char *argv[])
{
	int a;
	float b;
	func(a, b);

	return 0;
}

void func(int a, float b) {
	func(a, b);
}
