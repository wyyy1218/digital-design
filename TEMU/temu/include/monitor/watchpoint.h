#ifndef __WATCHPOINT_H__
#define __WATCHPOINT_H__

#include "common.h"

typedef struct watchpoint {
	int NO;
	struct watchpoint *next;
	char expr[64];
	uint32_t old_val;
} WP;

void init_wp_pool();
WP* new_wp(char *expr_str);
void free_wp(int NO);
bool check_wp();
void print_wp();

#endif
