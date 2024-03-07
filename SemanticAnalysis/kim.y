%{
	#define YYSTYPE_IS_DECLARED 1
	#define YYSTYPE long long

	#include "type.h"
	#include "func.h"
	#include "semantic.h"
	#include <stdio.h>
	#include <stdlib.h>

	extern int line_no, syntax_err, semantic_err;
	extern A_NODE *root;
	extern A_ID *current_id;
	extern int current_level;
	extern A_TYPE *int_type, *float_type, *char_type, *void_type, *string_type;

	extern char * node_name[];
	extern char *type_kind_name[];
	extern char *id_kind_name[];
	extern char *spec_name[];
	extern A_LITERAL literal_table[];

	int yyerror(char *s);
	int yylex();
	void print_ast(A_NODE *);
	void prt_program(A_NODE *, int);
	void prt_initializer(A_NODE *, int);
	void prt_arg_expr_list(A_NODE *, int);
	void prt_statement(A_NODE *, int);
	void prt_statement_list(A_NODE *, int);
	void prt_for_expression(A_NODE *, int);
	void prt_expression(A_NODE *, int);
	void prt_A_TYPE(A_TYPE *, int);
	void prt_A_ID_LIST(A_ID *, int);
	void prt_A_ID(A_ID *, int);
	void prt_A_ID_NAME(A_ID *, int);
	void prt_STRING(char *, int);
	void prt_integer(int, int);
	void print_node(A_NODE *,int);
	void print_space(int);
	
	
	
	void print_sem_ast(A_NODE *);
	void prt_sem_program(A_NODE *, int);
	void prt_sem_initializer(A_NODE *, int);
	void prt_sem_arg_expr_list(A_NODE *, int);
	void prt_sem_statement(A_NODE *, int);
	void prt_sem_statement_list(A_NODE *, int);
	void prt_sem_for_expression(A_NODE *, int);
	void prt_sem_expression(A_NODE *, int);
	void prt_sem_A_TYPE(A_TYPE *, int);
	void prt_sem_A_ID_LIST(A_ID *, int);
	void prt_sem_A_ID(A_ID *, int);
	void prt_sem_A_ID_NAME(A_ID *, int);
	void prt_sem_LITERAL(int, int);
	void prt_sem_integer(int, int);

%}

%start program

%token IDENTIFIER TYPE_IDENTIFIER CHARACTER_CONSTANT STRING_LITERAL FLOAT_CONSTANT INTEGER_CONSTANT ASSIGN MINUS PLUS SEMICOLON AMP
%token PERCENT SLASH STAR EXCL COMMA PERIOD COLON RR LR RB LB RP LP DOTDOTDOT BARBAR AMPAMP NEQ EQL GEQ LEQ GTR LSS ARROW MINUSMINUS
%token PLUSPLUS WHILE_SYM UNION_SYM TYPEDEF_SYM SWITCH_SYM STRUCT_SYM STATIC_SYM SIZEOF_SYM RETURN_SYM IF_SYM FOR_SYM ENUM_SYM ELSE_SYM
%token DO_SYM DEFAULT_SYM CONTINUE_SYM CASE_SYM BREAK_SYM AUTO_SYM

%%

program
	: translation_unit
	{root=makeNode(N_PROGRAM,NIL,$1,NIL); checkForwardReference();}
	;

translation_unit
	: external_declaration {$$=$1;}
	| translation_unit external_declaration {$$=linkDeclaratorList($1,$2);}
	;

external_declaration
	: function_definition {$$=$1;}
	| declaration {$$=$1;}
	;

function_definition
	: declaration_specifiers declarator {$$=setFunctionDeclaratorSpecifier($2,$1);}
	compound_statement{$$=setFunctionDeclaratorBody($3,$4);current_id=$2;}
	| declarator {$$=setFunctionDeclaratorSpecifier($1,makeSpecifier(int_type,0));}
	compound_statement{$$=setFunctionDeclaratorBody($2,$3);current_id=$1;}
	;

declaration_list_opt
	: {$$=NIL;}
	| declaration_list {$$=$1;}
	;

declaration_list
	: declaration {$$=$1;}
	| declaration_list declaration {$$=linkDeclaratorList($1,$2);}
	;

declaration
	: declaration_specifiers init_declarator_list_opt SEMICOLON
	{$$=setDeclaratorListSpecifier($2,$1);}
	;

declaration_specifiers
	: type_specifier {$$=makeSpecifier($1,0);}
	| storage_class_specifier {$$=makeSpecifier(0,$1);}
	| type_specifier declaration_specifiers {$$=updateSpecifier($2,$1,0);}
	| storage_class_specifier declaration_specifiers
	{$$=updateSpecifier($2,0,$1);}
	;

storage_class_specifier
	: AUTO_SYM {$$=S_AUTO;}
	| STATIC_SYM {$$=S_STATIC;}
	| TYPEDEF_SYM {$$=S_TYPEDEF;}
	;

init_declarator_list_opt
	: {$$=makeDummyIdentifier();}
	| init_declarator_list {$$=$1;}
	;

init_declarator_list
	: init_declarator {$$=$1;}
	| init_declarator_list COMMA init_declarator
	{$$=linkDeclaratorList($1,$3);}
	;

init_declarator
	: declarator {$$=$1;}
	| declarator ASSIGN initializer {$$=setDeclaratorInit((A_ID*)$1,(A_NODE*)$3);}
	;

initializer
	: constant_expression {$$=(A_NODE*)makeNode(N_INIT_LIST_ONE,NIL,$1,NIL);}
	| LR initializer_list RR {$$=$2;}
	;

initializer_list
	: initializer
	{$$=makeNode(N_INIT_LIST,$1,NIL,makeNode(N_INIT_LIST_NIL,NIL,NIL,NIL));}
	| initializer_list COMMA initializer {$$=makeNodeList(N_INIT_LIST,$1,$3);}
	;

type_specifier
	: struct_type_specifier {$$ = $1;}
	| enum_type_specifier {$$ = $1;}
	| TYPE_IDENTIFIER {$$ = $1;}
	;

struct_type_specifier
	: struct_or_union IDENTIFIER
	{$$=setTypeStructOrEnumIdentifier($1,$2,ID_STRUCT);}
	LR { $$=current_id;current_level++;} struct_declaration_list RR
	{checkForwardReference();$$=setTypeField($3,$6);current_level--;
	current_id=$5;}
	| struct_or_union {$$=makeType($1);} LR {$$=current_id;current_level++;}
	struct_declaration_list RR {checkForwardReference();$$=setTypeField($2,$5);
	current_level--;current_id=$4;}
	| struct_or_union IDENTIFIER
	{$$=getTypeOfStructOrEnumRefIdentifier($1,$2,ID_STRUCT);}
	;

struct_or_union
	: STRUCT_SYM {$$=T_STRUCT;}
	| UNION_SYM {$$=T_UNION;}
	;

struct_declaration_list
	: struct_declaration {$$=$1;}
	| struct_declaration_list struct_declaration {$$=linkDeclaratorList($1,$2);}
	;

struct_declaration
	: type_specifier struct_declarator_list SEMICOLON
	{$$=setStructDeclaratorListSpecifier($2,$1);}
	;

struct_declarator_list
	: struct_declarator {$$=$1;}
	| struct_declarator_list COMMA struct_declarator
	{$$=linkDeclaratorList($1,$3);}
	;

struct_declarator
	: declarator {$$=$1;}
	;

enum_type_specifier
	: ENUM_SYM IDENTIFIER
	{$$=setTypeStructOrEnumIdentifier(T_ENUM,$2,ID_ENUM);}
	LR enumerator_list RR {$$=setTypeField($3,$5);}
	| ENUM_SYM {$$=makeType(T_ENUM);}
	LR enumerator_list RR {$$=setTypeField($2,$4);}
	| ENUM_SYM IDENTIFIER
	{$$=getTypeOfStructOrEnumRefIdentifier(T_ENUM,$2,ID_ENUM);}
	;

enumerator_list
	: enumerator {$$=$1;}
	| enumerator_list COMMA enumerator {$$=linkDeclaratorList($1,$3);}
	;

enumerator
	: IDENTIFIER
	{$$=setDeclaratorKind(makeIdentifier($1),ID_ENUM_LITERAL);}
	| IDENTIFIER
	{$$=setDeclaratorKind(makeIdentifier($1),ID_ENUM_LITERAL);}
	ASSIGN expression {$$=setDeclaratorInit($2,$4);}
	;

declarator
	: pointer direct_declarator {$$=setDeclaratorElementType($2,$1);}
	| direct_declarator {$$=$1;}
	;

pointer
	: STAR {$$=makeType(T_POINTER);}
	| STAR pointer {$$=setTypeElementType($2,makeType(T_POINTER));}
	;

direct_declarator
	: IDENTIFIER {$$=makeIdentifier($1);}
	| LP declarator RP {$$=$2;}
	| direct_declarator LB constant_expression_opt RB
	{$$=setDeclaratorElementType($1,setTypeExpr(makeType(T_ARRAY),$3));}
	| direct_declarator LP {$$=current_id;current_level++;}
	parameter_type_list_opt RP
	{checkForwardReference();current_id=$3;current_level--;
	$$=setDeclaratorElementType($1,setTypeField(makeType(T_FUNC),$4));}
	;

parameter_type_list_opt
	: {$$=NIL;}
	| parameter_type_list {$$=$1;}
	;

parameter_type_list
	: parameter_list {$$=$1;}
	| parameter_list COMMA DOTDOTDOT {$$=linkDeclaratorList(
	$1,setDeclaratorKind(makeDummyIdentifier(),ID_PARM));}
	;

parameter_list
	: parameter_declaration {$$=$1;}
	| parameter_list COMMA parameter_declaration
	{$$=linkDeclaratorList($1,$3);}
	;

parameter_declaration
	: declaration_specifiers declarator
	{$$=setParameterDeclaratorSpecifier($2,$1);}
	| declaration_specifiers abstract_declarator_opt
	{$$=setParameterDeclaratorSpecifier(setDeclaratorType(
	makeDummyIdentifier(),$2),$1);}
	;

abstract_declarator_opt
	: {$$=NIL;}
	| abstract_declarator {$$=$1;}
	;

abstract_declarator
	: direct_abstract_declarator {$$=$1;}
	| pointer {$$=makeType(T_POINTER);}
	| pointer direct_abstract_declarator
	{$$=setTypeElementType($2,makeType(T_POINTER));}
	;

direct_abstract_declarator
	: LP abstract_declarator RP {$$=$2;}
	| LB constant_expression_opt RB
	{$$=setTypeExpr(makeType(T_ARRAY),$2);}
	| direct_abstract_declarator LB constant_expression_opt RB
	{$$=setTypeElementType($1,setTypeExpr(makeType(T_ARRAY),$3));}
	| LP parameter_type_list_opt RP
	{$$=setTypeExpr(makeType(T_FUNC),$2);}
	| direct_abstract_declarator LP parameter_type_list_opt RP
	{$$=setTypeElementType($1,setTypeExpr(makeType(T_FUNC),$3));}
	;

statement_list_opt
	: {$$=makeNode(N_STMT_LIST_NIL,NIL,NIL,NIL);}
	| statement_list {$$=$1;}
	;

statement_list
	: statement {$$=makeNode(N_STMT_LIST,$1,NIL,
	makeNode(N_STMT_LIST_NIL,NIL,NIL,NIL));}
	| statement_list statement {$$=makeNodeList(N_STMT_LIST,$1,$2);}
	;

statement
	: labeled_statement {$$=$1;}
	| compound_statement {$$=$1;}
	| expression_statement {$$=$1;}
	| selection_statement {$$=$1;}
	| iteration_statement {$$=$1;}
	| jump_statement {$$=$1;}
	;

labeled_statement
	: CASE_SYM constant_expression COLON statement
	{$$=makeNode(N_STMT_LABEL_CASE, $2,NIL,$4);}
	| DEFAULT_SYM COLON statement
	{$$=makeNode(N_STMT_LABEL_DEFAULT,NIL,$3,NIL);}
	;

compound_statement
	: LR {$$=current_id;current_level++;} declaration_list_opt
	statement_list_opt RR {checkForwardReference();
	$$=makeNode(N_STMT_COMPOUND,$3,NIL,$4); current_id=$2;
	current_level--;}
	;

expression_statement
	: SEMICOLON {$$=makeNode(N_STMT_EMPTY,NIL,NIL,NIL);}
	| expression SEMICOLON {$$=makeNode(N_STMT_EXPRESSION,NIL,$1,NIL);}
	;

selection_statement
	: IF_SYM LP expression RP statement
	{$$=makeNode(N_STMT_IF,$3,NIL,$5);}
	| IF_SYM LP expression RP statement ELSE_SYM statement
	{$$=makeNode(N_STMT_IF_ELSE,$3,$5,$7);}
	| SWITCH_SYM LP expression RP statement
	{$$=makeNode(N_STMT_SWITCH,$3,NIL,$5);}
	;

iteration_statement
	: WHILE_SYM LP expression RP statement
	{$$=makeNode(N_STMT_WHILE,$3,NIL,$5);}
	| DO_SYM statement WHILE_SYM LP expression RP SEMICOLON
	{$$=makeNode(N_STMT_DO,$2,NIL,$5);}
	| FOR_SYM LP for_expression RP statement
	{$$=makeNode(N_STMT_FOR,$3,NIL,$5);}
	;

for_expression
	: expression_opt SEMICOLON expression_opt SEMICOLON expression_opt
	{$$=makeNode(N_FOR_EXP,$1,$3,$5);}
	;

expression_opt
	: /* empty */ {$$=NIL;}
	| expression {$$=$1;}
	;

jump_statement
	: RETURN_SYM expression_opt SEMICOLON
	{$$=makeNode(N_STMT_RETURN,NIL,$2,NIL);}
	| CONTINUE_SYM SEMICOLON
	{$$=makeNode(N_STMT_CONTINUE,NIL,NIL,NIL);}
	| BREAK_SYM SEMICOLON
	{$$=makeNode(N_STMT_BREAK,NIL,NIL,NIL);}
	;

arg_expression_list_opt
	: {$$=makeNode(N_ARG_LIST_NIL,NIL,NIL,NIL);}
	| arg_expression_list {$$=$1;}
	;

arg_expression_list
	: assignment_expression
	{$$=makeNode(N_ARG_LIST,$1,NIL,makeNode(N_ARG_LIST_NIL,NIL,NIL,NIL));}
	| arg_expression_list COMMA assignment_expression
	{$$=makeNodeList(N_ARG_LIST,$1,$3);}
	;

constant_expression_opt
	: {$$=NIL;}
	| constant_expression {$$=$1;}
	;

constant_expression
	: expression {$$=$1;}
	;

expression
	: comma_expression {$$=$1;}
	;

comma_expression
	: assignment_expression {$$=$1;}
	;

assignment_expression
	: conditional_expression {$$=$1;}
	| unary_expression ASSIGN assignment_expression
	{$$=makeNode(N_EXP_ASSIGN,$1,NIL,$3);}
	;

conditional_expression
	: logical_or_expression {$$=$1;}
	;

logical_or_expression
	: logical_and_expression {$$=$1;}
	| logical_or_expression BARBAR logical_and_expression
	{$$=makeNode(N_EXP_OR,$1,NIL,$3);}
	;

logical_and_expression
	: bitwise_or_expression {$$=$1;}
	| logical_and_expression AMPAMP bitwise_or_expression
	{$$=makeNode(N_EXP_AND,$1,NIL,$3);}
	;

bitwise_or_expression
	: bitwise_xor_expression {$$=$1;}
	;

bitwise_xor_expression
	: bitwise_and_expression {$$=$1;}
	;

bitwise_and_expression
	: equality_expression {$$=$1;}
	;

equality_expression
	: relational_expression {$$=$1;}
	| equality_expression EQL relational_expression
	{$$=makeNode(N_EXP_EQL,$1,NIL,$3);}
	| equality_expression NEQ relational_expression
	{$$=makeNode(N_EXP_NEQ,$1,NIL,$3);}
	;

relational_expression
	: shift_expression {$$=$1;}
	| relational_expression LSS shift_expression
	{$$=makeNode(N_EXP_LSS,$1,NIL,$3);}
	| relational_expression GTR shift_expression
	{$$=makeNode(N_EXP_GTR,$1,NIL,$3);}
	| relational_expression LEQ shift_expression
	{$$=makeNode(N_EXP_LEQ,$1,NIL,$3);}
	| relational_expression GEQ shift_expression
	{$$=makeNode(N_EXP_GEQ,$1,NIL,$3);}
	;

shift_expression
	: additive_expression {$$=$1;}
	;

additive_expression
	: multiplicative_expression {$$=$1;}
	| additive_expression PLUS multiplicative_expression
	{$$=makeNode(N_EXP_ADD,$1,NIL,$3);}
	| additive_expression MINUS multiplicative_expression
	{$$=makeNode(N_EXP_SUB,$1,NIL,$3);}
	;

multiplicative_expression
	: cast_expression {$$=$1;}
	| multiplicative_expression STAR cast_expression
	{$$=makeNode(N_EXP_MUL,$1,NIL,$3);}
	| multiplicative_expression SLASH cast_expression
	{$$= makeNode(N_EXP_DIV,$1,NIL,$3);}
	| multiplicative_expression PERCENT cast_expression
	{$$= makeNode(N_EXP_MOD,$1,NIL,$3);}
	;

cast_expression
	: unary_expression {$$=$1;}
	| LP type_name RP cast_expression
	{$$=makeNode(N_EXP_CAST,$2,NIL,$4);}
	;

unary_expression
	: postfix_expression {$$=$1;}
	| PLUSPLUS unary_expression
	{$$=makeNode(N_EXP_PRE_INC,NIL,$2,NIL);}
	| MINUSMINUS unary_expression
	{$$=makeNode(N_EXP_PRE_DEC,NIL,$2,NIL);}
	| AMP cast_expression {$$=makeNode(N_EXP_AMP,NIL,$2,NIL);}
	| STAR cast_expression {$$=makeNode(N_EXP_STAR,NIL,$2,NIL);}
	| EXCL cast_expression {$$=makeNode(N_EXP_NOT,NIL,$2,NIL);}
	| MINUS cast_expression {$$=makeNode(N_EXP_MINUS,NIL,$2,NIL);}
	| PLUS cast_expression {$$=makeNode(N_EXP_PLUS,NIL,$2,NIL);}
	| SIZEOF_SYM unary_expression
	{$$=makeNode(N_EXP_SIZE_EXP,NIL,$2,NIL);}
	| SIZEOF_SYM LP type_name RP
	{$$=makeNode(N_EXP_SIZE_TYPE,NIL,$3,NIL);}
	;

postfix_expression
	: primary_expression {$$=$1;}
	| postfix_expression LB expression RB
	{$$=makeNode(N_EXP_ARRAY,$1,NIL,$3);}
	| postfix_expression LP arg_expression_list_opt RP
	{$$=makeNode(N_EXP_FUNCTION_CALL,$1,NIL,$3);}
	| postfix_expression PERIOD IDENTIFIER
	{$$=makeNode(N_EXP_STRUCT,$1,NIL,$3);}
	| postfix_expression ARROW IDENTIFIER
	{$$=makeNode(N_EXP_ARROW,$1,NIL,$3);}
	| postfix_expression PLUSPLUS
	{$$=makeNode(N_EXP_POST_INC,NIL,$1,NIL);}
	| postfix_expression MINUSMINUS
	{$$=makeNode(N_EXP_POST_DEC,NIL,$1,NIL);}
	;

primary_expression
	: IDENTIFIER
	{$$=makeNode(N_EXP_IDENT,NIL,getIdentifierDeclared($1),NIL);}
	| INTEGER_CONSTANT {$$=makeNode(N_EXP_INT_CONST,NIL,$1,NIL);}
	| FLOAT_CONSTANT {$$=makeNode(N_EXP_FLOAT_CONST,NIL,$1,NIL);}
	| CHARACTER_CONSTANT{$$=makeNode(N_EXP_CHAR_CONST,NIL,$1,NIL);}
	| STRING_LITERAL {$$=makeNode(N_EXP_STRING_LITERAL,NIL,$1,NIL);}
	| LP expression RP {$$=$2;}
	;

type_name
	: declaration_specifiers abstract_declarator_opt
	{$$=setTypeNameSpecifier($2,$1);}
	;

%%
extern char *yytext;

void print_current_id_list () {
	
	A_ID *id;
	id = current_id;
	printf("(current_id) ");
	while (id != NIL) {
		printf("%s > ", id -> name);
		id = id -> prev;
	}
	printf("NULL\n");
}

int yyerror(char *s) 
{
	printf("line %d: %s near %s \n", line_no, s, yytext);
	exit(1);
}

char * node_name[] = {
	"N_NULL",
	"N_PROGRAM",
	"N_EXP_IDENT",
	"N_EXP_INT_CONST",
	"N_EXP_FLOAT_CONST",
	"N_EXP_CHAR_CONST",
	"N_EXP_STRING_LITERAL",
	"N_EXP_ARRAY",
	"N_EXP_FUNCTION_CALL",
	"N_EXP_STRUCT",
	"N_EXP_ARROW",
	"N_EXP_POST_INC",
	"N_EXP_POST_DEC",
	"N_EXP_PRE_INC",
	"N_EXP_PRE_DEC",
	"N_EXP_AMP",
	"N_EXP_STAR",
	"N_EXP_NOT",
	"N_EXP_PLUS",
	"N_EXP_MINUS",
	"N_EXP_SIZE_EXP",
	"N_EXP_SIZE_TYPE",
	"N_EXP_CAST",
	"N_EXP_MUL",
	"N_EXP_DIV",
	"N_EXP_MOD",
	"N_EXP_ADD",
	"N_EXP_SUB",
	"N_EXP_LSS",
	"N_EXP_GTR",
	"N_EXP_LEQ",
	"N_EXP_GEQ",
	"N_EXP_NEQ",
	"N_EXP_EQL",
	"N_EXP_AND",
	"N_EXP_OR",
	"N_EXP_ASSIGN",
	"N_ARG_LIST",
	"N_ARG_LIST_NIL",
	"N_STMT_LABEL_CASE",
	"N_STMT_LABEL_DEFAULT",
	"N_STMT_COMPOUND",
	"N_STMT_EMPTY",
	"N_STMT_EXPRESSION",
	"N_STMT_IF",
	"N_STMT_IF_ELSE",
	"N_STMT_SWITCH",
	"N_STMT_WHILE",
	"N_STMT_DO",
	"N_STMT_FOR",
	"N_STMT_RETURN",
	"N_STMT_CONTINUE",
	"N_STMT_BREAK",
	"N_FOR_EXP",
	"N_STMT_LIST",
	"N_STMT_LIST_NIL",
	"N_INIT_LIST",
	"N_INIT_LIST_ONE",
	"N_INIT_LIST_NIL"
};


void print_node(A_NODE *node, int s)
{
	print_space(s);
	printf("%s (%x,%d)\n", node_name[node->name],node->type,node->value);
}
void print_space(int s)
{
	int i;
	for(i=1; i<=s; i++) printf("| ");
}
void print_ast(A_NODE *node)
{
	printf("======= syntax tree ==========\n");
	prt_program(node,0);
}
void prt_program(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) { case N_PROGRAM:
		prt_A_ID_LIST(node->clink, s+1);
		break; default :
			printf("****syntax tree error******");
	}
}
void prt_initializer(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) { case N_INIT_LIST:
		prt_initializer(node->llink, s+1);
		prt_initializer(node->rlink, s+1);
		break; case N_INIT_LIST_ONE:
			prt_expression(node->clink, s+1);
		break; case N_INIT_LIST_NIL:
			break; default :
			printf("****syntax tree error******");
	}
}
void prt_expression(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) { case N_EXP_IDENT :
		prt_A_ID_NAME(node->clink, s+1);
		break; case N_EXP_INT_CONST :
			prt_integer(node->clink, s+1);
		break; case N_EXP_FLOAT_CONST :
			prt_STRING(node->clink, s+1);
		break; case N_EXP_CHAR_CONST :
			prt_integer(node->clink, s+1);
		break; case N_EXP_STRING_LITERAL :
			prt_STRING(node->clink, s+1);
		break; case N_EXP_ARRAY :
			prt_expression(node->llink, s+1);
		prt_expression(node->rlink, s+1);
		break; case N_EXP_FUNCTION_CALL : 
			prt_expression(node->llink, s+1);
		prt_arg_expr_list(node->rlink, s+1);
		break; case N_EXP_STRUCT :
		case N_EXP_ARROW :
			prt_expression(node->llink, s+1);
			prt_STRING(node->rlink, s+1);
			break; case N_EXP_POST_INC : case N_EXP_POST_DEC : case N_EXP_PRE_INC : case N_EXP_PRE_DEC : case N_EXP_AMP : case N_EXP_STAR : case N_EXP_NOT : case N_EXP_PLUS : case N_EXP_MINUS : case N_EXP_SIZE_EXP :
				prt_expression(node->clink, s+1); break; case N_EXP_SIZE_TYPE :
				prt_A_TYPE(node->clink, s+1); break; case N_EXP_CAST :
				prt_A_TYPE(node->llink, s+1);
			prt_expression(node->rlink, s+1); break; case N_EXP_MUL : case N_EXP_DIV : case N_EXP_MOD : case N_EXP_ADD : case N_EXP_SUB :
		case N_EXP_LSS : case N_EXP_GTR :
		case N_EXP_LEQ : case N_EXP_GEQ : case N_EXP_NEQ : case N_EXP_EQL : case N_EXP_AND : case N_EXP_OR : case N_EXP_ASSIGN :
				prt_expression(node->llink, s+1);
				prt_expression(node->rlink, s+1); break; default :
					printf("****syntax tree error******");
	}
}
void prt_arg_expr_list(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) { case N_ARG_LIST :
		prt_expression(node->llink, s+1);
		prt_arg_expr_list(node->rlink, s+1);
		break; case N_ARG_LIST_NIL :
			break; default :
			printf("****syntax tree error******");
	}
}
void prt_statement(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) { case N_STMT_LABEL_CASE :
		prt_expression(node->llink, s+1);
		prt_statement(node->rlink, s+1);
		break; case N_STMT_LABEL_DEFAULT :
			prt_statement(node->clink, s+1);
		break; case N_STMT_COMPOUND:
			if(node->llink)
				prt_A_ID_LIST(node->llink, s+1);
		prt_statement_list(node->rlink, s+1);
		break; case N_STMT_EMPTY:
			break; case N_STMT_EXPRESSION:
			prt_expression(node->clink, s+1);
		break; case N_STMT_IF_ELSE:
			prt_expression(node->llink, s+1);
		prt_statement(node->clink, s+1);
		prt_statement(node->rlink, s+1);
		break; case N_STMT_IF: case N_STMT_SWITCH:
			prt_expression(node->llink, s+1);
		prt_statement(node->rlink, s+1);
		break; case N_STMT_WHILE:
			prt_expression(node->llink, s+1);
		prt_statement(node->rlink, s+1);
		break; case N_STMT_DO:
			prt_statement(node->llink, s+1);
		prt_expression(node->rlink, s+1);
		break;
		case N_STMT_FOR:
		prt_for_expression(node->llink, s+1);
		prt_statement(node->rlink, s+1);
		break; case N_STMT_CONTINUE:
			break; case N_STMT_BREAK:
			break; case N_STMT_RETURN:
			if(node->clink)
				prt_expression(node->clink, s+1);
		break; default :
			printf("****syntax tree error******");
	}
}
void prt_statement_list(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_STMT_LIST:
			prt_statement(node->llink, s+1);
			prt_statement_list(node->rlink, s+1);
			break;
		case N_STMT_LIST_NIL:
			break;
		default :
			printf("****syntax tree error******");
	}
}
void prt_for_expression(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_FOR_EXP :
			if(node->llink)
				prt_expression(node->llink, s+1);
			if(node->clink)
				prt_expression(node->clink, s+1);
			if(node->rlink)
				prt_expression(node->rlink, s+1);
			break; default :
				printf("****syntax tree error******");
	}
}
void prt_integer(int a, int s)
{
	print_space(s);
	printf("%d\n", a);
}
void prt_STRING(char *str, int s) {
	print_space(s);
	printf("%s\n", str);
}

char *type_kind_name[]={"NULL","ENUM","ARRAY","STRUCT","UNION","FUNC","POINTER","VOID"};

void prt_A_TYPE(A_TYPE *t, int s)
{
	print_space(s);
	if (t==int_type)
		printf("(int)\n");
	else if (t==float_type) 
		printf("(float)\n");
	else if (t==char_type)
		printf("(char %d)\n",t->size);
	else if (t==void_type)
		printf("(void)");
	else if (t->kind==T_NULL)
		printf("(null)");
	else if (t->prt)
		printf("(DONE:%x)\n",t);
	else
		switch (t->kind) {
			case T_ENUM:
				t->prt=TRUE;
				printf("ENUM\n");
				print_space(s); printf("| ENUMERATORS\n");
				prt_A_ID_LIST(t->field,s+2);
				break;
			case T_POINTER:
				t->prt=TRUE;
				printf("POINTER\n");
				print_space(s); printf("| ELEMENT_TYPE\n");
				prt_A_TYPE(t->element_type,s+2);
				break;
			case T_ARRAY:
				t->prt=TRUE;
				printf("ARRAY\n");
				print_space(s); printf("| INDEX\n");
				if (t->expr)
					prt_expression(t->expr,s+2);
				else
					print_space(s+2); printf("(none)\n");
				print_space(s); printf("| ELEMENT_TYPE\n");
				prt_A_TYPE(t->element_type,s+2);
				break;
			case T_STRUCT:
				t->prt=TRUE;
				printf("STRUCT\n");
				print_space(s); printf("| FIELD\n");
				prt_A_ID_LIST(t->field,s+2);
				break;
			case T_UNION:
				t->prt=TRUE;
				printf("UNION\n");
				print_space(s); printf("| FIELD\n");
				prt_A_ID_LIST(t->field,s+2);
				break;
			case T_FUNC:
				t->prt=TRUE;
				printf("FUNCTION\n");
				print_space(s); printf("| PARAMETER\n");
				prt_A_ID_LIST(t->field,s+2);
				print_space(s); printf("| TYPE\n");
				prt_A_TYPE(t->element_type,s+2);
				if (t->expr) {
					print_space(s); printf("| BODY\n");
					prt_statement(t->expr,s+2);
				}
		}
}
void prt_A_ID_LIST(A_ID *id, int s)
{
	while (id) {
		prt_A_ID(id,s);
		id=id->link;
	}
}
char *id_kind_name[]={"NULL","VAR","FUNC","PARM","FIELD","TYPE","ENUM",
	"STRUCT","ENUM_LITERAL"};
char *spec_name[]={"NULL","AUTO","STATIC","TYPEDEF"};
void prt_A_ID_NAME(A_ID *id, int s)
{
	print_space(s);
	printf("(ID=\"%s\") TYPE:%x KIND:%s SPEC=%s LEV=%d VAL=%d ADDR=%d \n",
	id->name, id->type, id_kind_name[id->kind], spec_name[id->specifier], id->level, id->value, id->address);
}
void prt_A_ID(A_ID *id, int s)
{
	print_space(s);
	printf("(ID=\"%s\") TYPE:%x KIND:%s SPEC=%s LEV=%d VAL=%d ADDR=%d \n", 
		id->name, id->type, id_kind_name[id->kind], spec_name[id->specifier], id->level, id->value, id->address);
	if (id->type) {
		print_space(s);
		printf("| TYPE\n");
		prt_A_TYPE(id->type,s+2);}
	if (id->init) {
		print_space(s);
		printf("| INIT\n");
		if (id->kind==ID_ENUM_LITERAL)
			prt_expression(id->init,s+2);
		else
			prt_initializer(id->init,s+2); 
	}
}

void print_sem_ast(A_NODE *node)
{
	printf("======= semantic tree ==========\n");
	prt_sem_program(node,0);
}

void prt_sem_program(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_PROGRAM:
			prt_sem_A_ID_LIST(node->clink, s+1);
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_initializer(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_INIT_LIST:
			prt_sem_initializer(node->llink, s+1);
			prt_sem_initializer(node->rlink, s+1);
			break;
		case N_INIT_LIST_ONE:
			prt_sem_expression(node->clink, s+1);
			break;
		case N_INIT_LIST_NIL:
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_expression(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_EXP_IDENT :
			prt_sem_A_ID_NAME(node->clink, s+1);
			break;
		case N_EXP_INT_CONST :
			prt_sem_integer(node->clink, s+1);
			break;
		case N_EXP_FLOAT_CONST :
			prt_sem_LITERAL(node->clink, s+1);
			break;
		case N_EXP_CHAR_CONST :
			prt_sem_integer(node->clink, s+1);
			break;
		case N_EXP_STRING_LITERAL :
			prt_sem_LITERAL(node->clink, s+1);
			break;
		case N_EXP_ARRAY :
			prt_sem_expression(node->llink, s+1);
			prt_sem_expression(node->rlink, s+1);
			break;
		case N_EXP_FUNCTION_CALL : 
			prt_sem_expression(node->llink, s+1);
			prt_sem_arg_expr_list(node->rlink, s+1);
			break;
		case N_EXP_STRUCT :
			prt_sem_expression(node->llink, s+1);
			prt_sem_A_ID_NAME(node->rlink, s+1);
			break;
		case N_EXP_ARROW :
			prt_sem_expression(node->llink, s+1);
			prt_sem_A_ID_NAME(node->rlink, s+1);
			break;
		case N_EXP_POST_INC :
		case N_EXP_POST_DEC :
		case N_EXP_PRE_INC :
		case N_EXP_PRE_DEC :
		case N_EXP_AMP :
		case N_EXP_STAR :
		case N_EXP_NOT :
		case N_EXP_PLUS :
		case N_EXP_MINUS :
			prt_sem_expression(node->clink, s+1);
			break;
		case N_EXP_SIZE_EXP :
		case N_EXP_SIZE_TYPE :
			prt_sem_integer(node->clink, s+1);
			break;
		case N_EXP_CAST :
			prt_sem_A_TYPE(node->llink, s+1);
			prt_sem_expression(node->rlink, s+1);
			break;
		case N_EXP_MUL :
		case N_EXP_DIV :
		case N_EXP_MOD :
		case N_EXP_ADD :
		case N_EXP_SUB :
		case N_EXP_LSS :
		case N_EXP_GTR :
		case N_EXP_LEQ :
		case N_EXP_GEQ :
		case N_EXP_NEQ :
		case N_EXP_EQL :
		case N_EXP_AND :
		case N_EXP_OR :
		case N_EXP_ASSIGN :
			prt_sem_expression(node->llink, s+1);
			prt_sem_expression(node->rlink, s+1);
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_arg_expr_list(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_ARG_LIST :
			prt_sem_expression(node->llink, s+1);
			prt_sem_arg_expr_list(node->rlink, s+1);
			break;
		case N_ARG_LIST_NIL :
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_statement(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_STMT_LABEL_CASE :
			prt_sem_integer(node->llink, s+1);
			prt_sem_statement(node->rlink, s+1);
			break;
		case N_STMT_LABEL_DEFAULT :
			prt_sem_statement(node->clink, s+1);
			break;
		case N_STMT_COMPOUND:
			if(node->llink) prt_sem_A_ID_LIST(node->llink, s+1);
			prt_sem_statement_list(node->rlink, s+1);
			break;
		case N_STMT_EMPTY:
			break;
		case N_STMT_EXPRESSION:
			prt_sem_expression(node->clink, s+1);
			break;
		case N_STMT_IF:
			prt_sem_expression(node->llink, s+1);
			prt_sem_statement(node->rlink, s+1);
			break;
		case N_STMT_IF_ELSE:
			prt_sem_expression(node->llink, s+1);
			prt_sem_statement(node->clink, s+1);
			prt_sem_statement(node->rlink, s+1);
			break;
		case N_STMT_SWITCH:
			prt_sem_expression(node->llink, s+1);
			prt_sem_statement(node->rlink, s+1);
			break;
		case N_STMT_WHILE:
			prt_sem_expression(node->llink, s+1);
			prt_sem_statement(node->rlink, s+1);
			break;
		case N_STMT_DO:
			prt_sem_statement(node->llink, s+1);
			prt_sem_expression(node->rlink, s+1);
			break;
		case N_STMT_FOR:
			prt_sem_for_expression(node->llink, s+1);
			prt_sem_statement(node->rlink, s+1);
			break;
		case N_STMT_CONTINUE:
			break;
		case N_STMT_BREAK:
			break;
		case N_STMT_RETURN:
			if(node->clink) prt_sem_expression(node->clink, s+1);
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_statement_list(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_STMT_LIST:
			prt_sem_statement(node->llink, s+1);
			prt_sem_statement_list(node->rlink, s+1);
			break;
		case N_STMT_LIST_NIL:
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_for_expression(A_NODE *node, int s)
{
	print_node(node,s);
	switch(node->name) {
		case N_FOR_EXP :
			if(node->llink) prt_sem_expression(node->llink, s+1);
			if(node->clink) prt_sem_expression(node->clink, s+1);
			if(node->rlink) prt_sem_expression(node->rlink, s+1);
			break;
		default :
			printf("****syntax tree error******");
	}
}

void prt_sem_integer(int a, int s)
{
	print_space(s);
	printf("INT=%d\n", a);
}

void prt_sem_LITERAL(int lit, int s)
{
	print_space(s);
	printf("LITERAL: ");
	if (literal_table[lit].type==int_type)
		printf("%d\n", literal_table[lit].value.i);
	if (literal_table[lit].type==float_type)
		printf("%f\n", literal_table[lit].value.f);
	else if (literal_table[lit].type==string_type)
		printf("%s\n", literal_table[lit].value.s);
}

void prt_sem_A_TYPE(A_TYPE *t, int s)
{
	print_space(s);
	if (t==int_type)
		printf("(int)\n");
	else if (t==float_type)
		printf("(float)\n");
	else if (t==char_type)
		printf("(char %d)\n",t->size);
	else if (t==void_type)
		printf("(void)\n");
	else if (t->kind==T_NULL)
		printf("(null)\n");
	else if (t->prt==FALSE)
		printf("(DONE:%x)\n",t);
	else
		switch (t->kind) {
			case T_ENUM:
				t->prt=FALSE;
				printf("ENUM\n");
				print_space(s); printf("| ENUMERATORS\n");
				prt_sem_A_ID_LIST(t->field,s+2);
				break;
			case T_POINTER:
				t->prt=FALSE;
				printf("POINTER\n");
				print_space(s); printf("| ELEMENT_TYPE\n");
				prt_sem_A_TYPE(t->element_type,s+2);
				break;
			case T_ARRAY:
				t->prt=FALSE;
				printf("ARRAY\n");
				print_space(s); printf("| INDEX\n");
				prt_sem_integer(t->expr,s+2);
				print_space(s); printf("| ELEMENT_TYPE\n");
				prt_sem_A_TYPE(t->element_type,s+2);
				break;
			case T_STRUCT:
				t->prt=FALSE;
				printf("STRUCT\n");
				print_space(s); printf("| FIELD\n");
				prt_sem_A_ID_LIST(t->field,s+2);
				break;
			case T_UNION:
				t->prt=FALSE;
				printf("UNION\n");
				print_space(s); printf("| FIELD\n");
				prt_sem_A_ID_LIST(t->field,s+2);
				break;
			case T_FUNC:
				t->prt=FALSE;
				printf("FUNCTION\n");
				print_space(s); printf("| PARAMETER\n");
				prt_sem_A_ID_LIST(t->field,s+2);
				print_space(s); printf("| TYPE\n");
				prt_sem_A_TYPE(t->element_type,s+2);
				if (t->expr) {
					print_space(s); printf("| BODY\n");
					prt_sem_statement(t->expr,s+2);
				}
		}
}

void prt_sem_A_ID_LIST(A_ID *id, int s)
{
	while (id) {
		prt_sem_A_ID(id,s);
		id=id->link;
	}
}

void prt_sem_A_ID_NAME(A_ID *id, int s)
{
	print_space(s);
	printf("(ID=\"%s\") TYPE:%x KIND:%s SPEC=%s LEV=%d VAL=%d ADDR=%d\n", id->name, id->type,
			id_kind_name[id->kind], spec_name[id->specifier],id->level,
			id->value, id->address);
}

void prt_sem_A_ID(A_ID *id, int s)
{
	print_space(s);
	printf("(ID=\"%s\") TYPE:%x KIND:%s SPEC=%s LEV=%d VAL=%d ADDR=%d\n", id->name, id->type,
			id_kind_name[id->kind], spec_name[id->specifier],id->level,
			id->value, id->address);
	if (id->type) {
		print_space(s);
		printf("| TYPE\n");
		prt_sem_A_TYPE(id->type,s+2);
	}
	if (id->init) {
		print_space(s);
		printf("| INIT\n");
		if (id->kind==ID_ENUM_LITERAL)
			if (id->init)
				prt_sem_integer(id->init,s+2);
			else ;
		else
			prt_sem_initializer(id->init,s+2); 
	}
}

int main(){
    initialize();
    printf("syntax 검사 시작!\n");
    yyparse();
    	
    if (syntax_err) 
        exit(1);
    
    printf("syntax 검사완료\n");
    print_ast(root); // "print.c" function
    
    printf("semantic 검사 시작!\n");
    semantic_analysis(root);
    
    if(semantic_err)
        exit(1);
        
    printf("semantic 검사 완료\n");
    print_sem_ast(root); // "print_sem.c" function
    
    exit(0);
    
}

int yywrap()
{
	return(1);
}
