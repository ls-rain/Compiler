int strcmp(char *s, char*t){
	for(;*s==*t; s++){
		if(*s==0)
			return 0;
		t++;}
	return *s-*t;
}
int main(){
	strcmp("kim", "lee");
	return 0;
}
