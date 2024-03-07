	      INT   0, 32
	      SUP   0, main
	      RET   0, 0
main:
	      INT   0, 12
	      INT   0, 12
	      LDA   0, 16
	      LOD   0, 12
	      POP   0, 5
	     ADDR   0, printf
	      CAL   0, 0
	      RET   0, 0
.literal    16  "aaa = %d\n"
