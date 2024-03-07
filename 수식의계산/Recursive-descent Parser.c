#include <stdio.h>
#include <stdlib.h>

// 토큰 타입 정의
enum { NUMBER, PLUS, MINUS, STAR, SLASH, LP, RP, END } token;
// 값의 종류를 나타내는 열거형
typedef enum { INT, FLT } kind;

// 값의 구조체 정의
typedef struct {
    kind t;
    union {
        int i;
        float f;
    } val;
} Value;

// 현재 값을 저장할 변수
Value num;

// 함수 선언
Value expression();
Value term();
Value factor();
void get_token();
void error(int i);

int main() {
    get_token();
    Value result = expression();
    if (token != END)
        error(3);
    else {
        if (result.t == INT)
            printf("Result: %d\n", result.val.i);
        else if (result.t == FLT)
            printf("Result: %.6f\n", result.val.f);
    }
}

// 수식을 계산하는 함수
Value expression() {
    Value result = term();
    while (token == PLUS || token == MINUS) {
        int op = token;
        get_token();
        Value operand2 = term();

        // 정수 연산
        if (result.t == INT && operand2.t == INT) {
            if (op == PLUS)
                result.val.i += operand2.val.i;
            else
                result.val.i -= operand2.val.i;
        }
        // 정수와 실수 연산 혹은 실수와 정수 연산
        else if ((result.t == INT && operand2.t == FLT) || (result.t == FLT && operand2.t == INT)) {
            printf("Warning: Mixing integer and float operands\n");
            result.t = FLT;
            if (result.t == INT)
                result.val.f = (float)result.val.i;
            if (operand2.t == INT)
                operand2.val.f = (float)operand2.val.i;

            if (op == PLUS)
                result.val.f += operand2.val.f;
            else
                result.val.f -= operand2.val.f;
        }
        // 실수 연산
        else {
            result.t = FLT;
            if (result.t == INT)
                result.val.f = (float)result.val.i;
            if (operand2.t == INT)
                operand2.val.f = (float)operand2.val.i;

            if (op == PLUS)
                result.val.f += operand2.val.f;
            else
                result.val.f -= operand2.val.f;
        }
    }
    return result;
}

// 항을 계산하는 함수
Value term() {
    Value result = factor();
    while (token == STAR || token == SLASH) {
        int op = token;
        get_token();
        Value operand2 = factor();

        // 정수 연산
        if (result.t == INT && operand2.t == INT) {
            if (op == STAR)
                result.val.i *= operand2.val.i;
            else if (operand2.val.i != 0)
                result.val.i /= operand2.val.i;
            else {
                printf("Error: Division by zero\n");
                exit(1);
            }
        }
        // 정수와 실수 연산 혹은 실수와 정수 연산
        else if ((result.t == INT && operand2.t == FLT) || (result.t == FLT && operand2.t == INT)) {
            printf("Warning: Mixing integer and float operands\n");
            result.t = FLT;
            if (result.t == INT)
                result.val.f = (float)result.val.i;
            if (operand2.t == INT)
                operand2.val.f = (float)operand2.val.i;

            if (op == STAR)
                result.val.f *= operand2.val.f;
            else if (operand2.val.f != 0)
                result.val.f /= operand2.val.f;
            else {
                printf("Error: Division by zero\n");
                exit(1);
            }
        }
        // 실수 연산
        else {
            result.t = FLT;
            if (result.t == INT)
                result.val.f = (float)result.val.i;
            if (operand2.t == INT)
                operand2.val.f = (float)operand2.val.i;

            if (op == STAR)
                result.val.f *= operand2.val.f;
            else if (operand2.val.f != 0)
                result.val.f /= operand2.val.f;
            else {
                printf("Error: Division by zero\n");
                exit(1);
            }
        }
    }
    return result;
}

// 인수를 계산하는 함수
Value factor() {
    Value result;
    if (token == NUMBER) {
        result = num;
        get_token();
    }
    else if (token == LP) {
        get_token();
        result = expression();
        if (token == RP)
            get_token();
        else
            error(2);
    }
    else
        error(1);
    return result;
}

// 토큰을 얻는 함수
void get_token() {
    char ch;
    while ((ch = getchar()) == ' ')
        ;
    switch (ch) {
    case '+':
        token = PLUS;
        break;
    case '-':
        token = MINUS;
        break;
    case '*':
        token = STAR;
        break;
    case '/':
        token = SLASH;
        break;
    case '(':
        token = LP;
        break;
    case ')':
        token = RP;
        break;
    case '\n':
    case EOF:
        token = END;
        break;
    default:
        if (ch >= '0' && ch <= '9') {
            num.t = INT;
            num.val.i = ch - '0';
            while ((ch = getchar()) >= '0' && ch <= '9')
                num.val.i = num.val.i * 10 + ch - '0';
            if (ch == '.') {
                num.t = FLT;
                num.val.f = (float)num.val.i;
                float divisor = 10.0;
                while ((ch = getchar()) >= '0' && ch <= '9') {
                    num.val.f += (ch - '0') / divisor;
                    divisor *= 10.0;
                }
            }
            ungetc(ch, stdin);
            token = NUMBER;
        }
        else
            error(1);
        break;
    }
}

// 오류 메시지 출력 함수
void error(int i) {
    switch (i) {
    case 1:
        printf("Error: Invalid character in input\n");
        break;
    case 2:
        printf("Error: Unmatched parentheses\n");
        break;
    case 3:
        printf("Error: Unexpected end of input\n");
        break;
    }
    exit(1);
}
