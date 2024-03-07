	      INT   0, 28
	      SUP   0, main
	      RET   0, 0
strcmp:
	      INT   0, 20
L2:
	      LOD   1, 12
	     LDIB   0, 0
	      LOD   1, 16
	     LDIB   0, 0
	     EQLI   0, 0
	      JPC   0, L3
	      LOD   1, 12
	     LDIB   0, 0
	     LITI   0, 0
	     EQLI   0, 0
	      JPC   0, L4
	      LDA   1, -4
	     LITI   0, 0
	      STO   0, 1
	      RET   0, 0
L4:
	      LOD   1, 16
	      LDA   1, 16
	      LDX   0, 1
	     LITI   0, 1
	     ADDI   0, 0
	      STO   0, 1
	      POP   0, 1
L1:
	      LOD   1, 12
	      LDA   1, 12
	      LDX   0, 1
	     LITI   0, 1
	     ADDI   0, 0
	      STO   0, 1
	      POP   0, 1
	      JMP   0, L2
L3:
	      LDA   1, -4
	      LOD   1, 12
	     LDIB   0, 0
	      LOD   1, 16
	     LDIB   0, 0
	     SUBI   0, 0
	      STO   0, 1
	      RET   0, 0
	      RET   0, 0
main:
	      INT   0, 12
	      INT   0, 16
	      LDA   0, 12
	      LDA   0, 20
	      POP   0, 5
	     ADDR   0, strcmp
	      CAL   0, 0
	      POP   0, 1
	      LDA   1, -4
	     LITI   0, 0
	      STO   0, 1
	      RET   0, 0
	      RET   0, 0
.literal    12  "kim"
.literal    20  "lee"
