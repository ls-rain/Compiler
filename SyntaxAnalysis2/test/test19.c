//구조체 전방참조, 불완전선언

struct s;
struct t {
	struct s *f;
};
struct s {
	int a;
}rm;
