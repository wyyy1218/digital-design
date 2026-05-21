#include "temu.h"
#include "expr.h"
#include "reg.h"

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <sys/types.h>
#include <regex.h>
#include <stdlib.h>
#include <stdio.h>

enum {
	NOTYPE = 256, 
	EQ, NE, LE, GE, AND, OR, DEREF, REG, HEX, DEC
};

static struct rule {
	char *regex;
	int token_type;
} rules[] = {
	{" +",	NOTYPE},				// spaces
	{"\\+", '+'},					// plus
	{"-", '-'},						// minus
	{"\\*", '*'},					// multiply or dereference
	{"/", '/'},						// divide
	{"==", EQ},						// equal
	{"!=", NE},						// not equal
	{"<=", LE},						// less or equal
	{">=", GE},						// greater or equal
	{"<", '<'},						// less than
	{">", '>'},						// greater than
	{"&&", AND},					// logical and
	{"\\|\\|", OR},					// logical or
	{"!", '!'},						// logical not
	{"\\(", '('},					// left parenthesis
	{"\\)", ')'},					// right parenthesis
	{"\\$[a-z0-9]+", REG},			// register ($s0, $a0, etc.)
	{"0x[0-9a-fA-F]+", HEX},		// hexadecimal number
	{"[0-9]+", DEC},				// decimal number
};

#define NR_REGEX (sizeof(rules) / sizeof(rules[0]) )

static regex_t re[NR_REGEX];

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
	int i;
	char error_msg[128];
	int ret;

	for(i = 0; i < NR_REGEX; i ++) {
		ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
		if(ret != 0) {
			regerror(ret, &re[i], error_msg, 128);
			Assert(ret == 0, "regex compilation failed: %s\n%s", error_msg, rules[i].regex);
		}
	}
}

typedef struct token {
	int type;
	char str[32];
} Token;

Token tokens[32];
int nr_token;

static bool make_token(char *e) {
	int position = 0;
	int i;
	regmatch_t pmatch;
	
	nr_token = 0;

	while(e[position] != '\0') {
		/* Try all rules one by one. */
		for(i = 0; i < NR_REGEX; i ++) {
			if(regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
				char *substr_start = e + position;
				int substr_len = pmatch.rm_eo;

				Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s", i, rules[i].regex, position, substr_len, substr_len, substr_start);
				
				/* Skip spaces */
				if(rules[i].token_type == NOTYPE) {
					position += substr_len;
					continue;
				}

				/* Record the token */
				if(nr_token >= 32) {
					printf("too many tokens\n");
					return false;
				}
				
				tokens[nr_token].type = rules[i].token_type;
				if(substr_len < 32) {
					strncpy(tokens[nr_token].str, substr_start, substr_len);
					tokens[nr_token].str[substr_len] = '\0';
				} else {
					strncpy(tokens[nr_token].str, substr_start, 31);
					tokens[nr_token].str[31] = '\0';
				}
				nr_token++;
				position += substr_len;
				break;
			}
		}

		if(i == NR_REGEX) {
			printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
			return false;
		}
	}

	return true; 
}

/* Helper function to find register index by name */
static int find_reg_index(const char *reg_name) {
	extern const char* regfile[];
	int i;
	
	/* Check for $pc first */
	if(strcmp(reg_name, "$pc") == 0) {
		return -1; /* Special case for PC */
	}
	
	/* Try exact match first */
	for(i = 0; i < 32; i++) {
		if(strcmp(regfile[i], reg_name) == 0) {
			return i;
		}
	}
	
	/* Try adding $ prefix if not present */
	if(reg_name[0] != '$') {
		char with_dollar[32];
		snprintf(with_dollar, sizeof(with_dollar), "$%s", reg_name);
		for(i = 0; i < 32; i++) {
			if(strcmp(regfile[i], with_dollar) == 0) {
				return i;
			}
		}
	}
	
	/* Try removing $ prefix if present */
	if(reg_name[0] == '$') {
		for(i = 0; i < 32; i++) {
			if(strcmp(regfile[i], reg_name + 1) == 0) {
				return i;
			}
		}
	}
	
	return -2; /* Not found */
}

/* Helper function to evaluate a token to a value */
static uint32_t eval_token(int token_idx, bool *success) {
	if(token_idx < 0 || token_idx >= nr_token) {
		*success = false;
		return 0;
	}

	switch(tokens[token_idx].type) {
		case HEX:
			*success = true;
			return strtoul(tokens[token_idx].str, NULL, 16);
		case DEC:
			*success = true;
			return strtoul(tokens[token_idx].str, NULL, 10);
		case REG: {
			int reg_idx = find_reg_index(tokens[token_idx].str);
			if(reg_idx == -1) {
				*success = true;
				return cpu.pc;
			} else if(reg_idx >= 0) {
				*success = true;
				return reg_w(reg_idx);
			} else {
				printf("Unknown register: %s\n", tokens[token_idx].str);
				*success = false;
				return 0;
			}
		}
		default:
			*success = false;
			return 0;
	}
}

/* Recursive descent parser for expressions */
static int pos = 0;

static uint32_t eval_expr(bool *success);

static uint32_t eval_primary(bool *success) {
	if(pos >= nr_token) {
		*success = false;
		return 0;
	}

	if(tokens[pos].type == '(') {
		pos++;
		uint32_t val = eval_expr(success);
		if(!*success) return 0;
		if(pos >= nr_token || tokens[pos].type != ')') {
			printf("missing closing parenthesis\n");
			*success = false;
			return 0;
		}
		pos++;
		return val;
	} else if(tokens[pos].type == '!') {
		pos++;
		uint32_t val = eval_primary(success);
		if(!*success) return 0;
		return !val;
	} else if(tokens[pos].type == '*' && (pos == 0 || (tokens[pos-1].type != REG && tokens[pos-1].type != DEC && tokens[pos-1].type != HEX && tokens[pos-1].type != ')'))) {
		/* Dereference operator */
		pos++;
		uint32_t addr = eval_primary(success);
		if(!*success) return 0;
		addr = addr & 0x7FFFFFFF; /* Map virtual address to physical */
		return mem_read(addr, 4);
	} else if(tokens[pos].type == '-' && (pos == 0 || (tokens[pos-1].type != REG && tokens[pos-1].type != DEC && tokens[pos-1].type != HEX && tokens[pos-1].type != ')'))) {
		/* Unary minus */
		pos++;
		uint32_t val = eval_primary(success);
		if(!*success) return 0;
		return -(int32_t)val;
	} else if(tokens[pos].type == REG || tokens[pos].type == HEX || tokens[pos].type == DEC) {
		uint32_t val = eval_token(pos, success);
		pos++;
		return val;
	} else {
		printf("unexpected token: %s\n", tokens[pos].str);
		*success = false;
		return 0;
	}
}

static uint32_t eval_mul(bool *success) {
	uint32_t val = eval_primary(success);
	if(!*success) return 0;

	while(pos < nr_token) {
		if(tokens[pos].type == '*') {
			pos++;
			uint32_t val2 = eval_primary(success);
			if(!*success) return 0;
			val = val * val2;
		} else if(tokens[pos].type == '/') {
			pos++;
			uint32_t val2 = eval_primary(success);
			if(!*success) return 0;
			if(val2 == 0) {
				printf("division by zero\n");
				*success = false;
				return 0;
			}
			val = (int32_t)val / (int32_t)val2;
		} else {
			break;
		}
	}
	return val;
}

static uint32_t eval_add(bool *success) {
	uint32_t val = eval_mul(success);
	if(!*success) return 0;

	while(pos < nr_token) {
		if(tokens[pos].type == '+') {
			pos++;
			uint32_t val2 = eval_mul(success);
			if(!*success) return 0;
			val = val + val2;
		} else if(tokens[pos].type == '-') {
			pos++;
			uint32_t val2 = eval_mul(success);
			if(!*success) return 0;
			val = val - val2;
		} else {
			break;
		}
	}
	return val;
}

static uint32_t eval_rel(bool *success) {
	uint32_t val = eval_add(success);
	if(!*success) return 0;

	while(pos < nr_token) {
		if(tokens[pos].type == '<') {
			pos++;
			uint32_t val2 = eval_add(success);
			if(!*success) return 0;
			val = (int32_t)val < (int32_t)val2;
		} else if(tokens[pos].type == '>') {
			pos++;
			uint32_t val2 = eval_add(success);
			if(!*success) return 0;
			val = (int32_t)val > (int32_t)val2;
		} else if(tokens[pos].type == LE) {
			pos++;
			uint32_t val2 = eval_add(success);
			if(!*success) return 0;
			val = (int32_t)val <= (int32_t)val2;
		} else if(tokens[pos].type == GE) {
			pos++;
			uint32_t val2 = eval_add(success);
			if(!*success) return 0;
			val = (int32_t)val >= (int32_t)val2;
		} else {
			break;
		}
	}
	return val;
}

static uint32_t eval_eq(bool *success) {
	uint32_t val = eval_rel(success);
	if(!*success) return 0;

	while(pos < nr_token) {
		if(tokens[pos].type == EQ) {
			pos++;
			uint32_t val2 = eval_rel(success);
			if(!*success) return 0;
			val = val == val2;
		} else if(tokens[pos].type == NE) {
			pos++;
			uint32_t val2 = eval_rel(success);
			if(!*success) return 0;
			val = val != val2;
		} else {
			break;
		}
	}
	return val;
}

static uint32_t eval_and(bool *success) {
	uint32_t val = eval_eq(success);
	if(!*success) return 0;

	while(pos < nr_token) {
		if(tokens[pos].type == AND) {
			pos++;
			uint32_t val2 = eval_eq(success);
			if(!*success) return 0;
			val = val && val2;
		} else {
			break;
		}
	}
	return val;
}

static uint32_t eval_or(bool *success) {
	uint32_t val = eval_and(success);
	if(!*success) return 0;

	while(pos < nr_token) {
		if(tokens[pos].type == OR) {
			pos++;
			uint32_t val2 = eval_and(success);
			if(!*success) return 0;
			val = val || val2;
		} else {
			break;
		}
	}
	return val;
}

static uint32_t eval_expr(bool *success) {
	return eval_or(success);
}

uint32_t expr(char *e, bool *success) {
	pos = 0;
	nr_token = 0;
	
	if(!make_token(e)) {
		*success = false;
		return 0;
	}

	if(nr_token == 0) {
		printf("empty expression\n");
		*success = false;
		return 0;
	}

	uint32_t result = eval_expr(success);
	
	if(*success && pos < nr_token) {
		printf("unexpected token at end: %s\n", tokens[pos].str);
		*success = false;
		return 0;
	}

	return result;
}

