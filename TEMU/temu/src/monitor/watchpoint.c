#include "watchpoint.h"
#include "expr.h"
#include <stdio.h>
#include <string.h>

#define NR_WP 32

static WP wp_pool[NR_WP];
static WP *head, *free_;

void init_wp_pool() {
	int i;
	for(i = 0; i < NR_WP; i ++) {
		wp_pool[i].NO = i;
		wp_pool[i].next = &wp_pool[i + 1];
		wp_pool[i].expr[0] = '\0';
		wp_pool[i].old_val = 0;
	}
	wp_pool[NR_WP - 1].next = NULL;

	head = NULL;
	free_ = wp_pool;
}

WP* new_wp(char *expr_str) {
	if(free_ == NULL) {
		printf("No free watchpoint available\n");
		return NULL;
	}

	/* Evaluate the expression first to get initial value */
	bool success;
	uint32_t val = expr(expr_str, &success);
	if(!success) {
		printf("Invalid expression for watchpoint\n");
		return NULL;
	}

	/* Allocate a watchpoint from free list */
	WP *wp = free_;
	free_ = free_->next;
	
	/* Initialize the watchpoint */
	strncpy(wp->expr, expr_str, 63);
	wp->expr[63] = '\0';
	wp->old_val = val;
	
	/* Add to head of active list */
	wp->next = head;
	head = wp;

	printf("Watchpoint %d: %s (initial value: 0x%08x)\n", wp->NO, wp->expr, wp->old_val);
	return wp;
}

void free_wp(int NO) {
	WP *wp, *prev = NULL;
	
	/* Find the watchpoint */
	for(wp = head; wp != NULL; prev = wp, wp = wp->next) {
		if(wp->NO == NO) {
			/* Remove from active list */
			if(prev == NULL) {
				head = wp->next;
			} else {
				prev->next = wp->next;
			}
			
			/* Add back to free list */
			wp->next = free_;
			free_ = wp;
			wp->expr[0] = '\0';
			wp->old_val = 0;
			
			printf("Watchpoint %d deleted\n", NO);
			return;
		}
	}
	
	printf("Watchpoint %d not found\n", NO);
}

bool check_wp() {
	WP *wp;
	bool triggered = false;
	
	for(wp = head; wp != NULL; wp = wp->next) {
		bool success;
		uint32_t new_val = expr(wp->expr, &success);
		
		if(success && new_val != wp->old_val) {
			printf("Watchpoint %d: %s\n", wp->NO, wp->expr);
			printf("Old value = 0x%08x\n", wp->old_val);
			printf("New value = 0x%08x\n", new_val);
			wp->old_val = new_val;
			triggered = true;
		}
	}
	
	return triggered;
}

void print_wp() {
	WP *wp;
	
	if(head == NULL) {
		printf("No watchpoints\n");
		return;
	}
	
	printf("Num\tExpression\n");
	for(wp = head; wp != NULL; wp = wp->next) {
		printf("%d\t%s\n", wp->NO, wp->expr);
	}
}

// Enumerate active watchpoints for GUI.
// Returns number of entries copied into out (<= max_count).
int list_watchpoints(WP *out, int max_count) {
	if (out == NULL || max_count <= 0) return 0;
	int n = 0;
	for (WP *wp = head; wp != NULL && n < max_count; wp = wp->next) {
		out[n++] = *wp; // shallow copy is fine (no dynamic members)
	}
	return n;
}
