#include "monitor.h"
#include "temu.h"
#include "expr.h"
#include "watchpoint.h"

#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <string.h>
#include <stdio.h>

void cpu_exec(uint32_t);

void display_reg();

/* We use the `readline' library to provide more flexibility to read from stdin. */
char* rl_gets() {
	static char *line_read = NULL;

	if (line_read) {
		free(line_read);
		line_read = NULL;
	}

	line_read = readline("(temu) ");

	if (line_read && *line_read) {
		add_history(line_read);
	}

	return line_read;
}

static int cmd_c(char *args) {
	cpu_exec(-1);
	return 0;
}

static int cmd_q(char *args) {
	return -1;
}

static int cmd_si(char *args) {
	int n = 1;
	if(args != NULL && args[0] != '\0') {
		n = atoi(args);
		if(n <= 0) {
			printf("Invalid number of steps: %s\n", args);
			return 0;
		}
	}
	cpu_exec(n);
	return 0;
}

static int cmd_info(char *args) {
	if(args == NULL || args[0] == '\0') {
		printf("Usage: info <r|w>\n");
		return 0;
	}
	
	char *subcmd = strtok(args, " ");
	if(subcmd == NULL) {
		printf("Usage: info <r|w>\n");
		return 0;
	}
	
	if(strcmp(subcmd, "r") == 0) {
		display_reg();
	} else if(strcmp(subcmd, "w") == 0) {
		print_wp();
	} else {
		printf("Unknown subcommand: %s\n", subcmd);
		printf("Usage: info <r|w>\n");
	}
	return 0;
}

static int cmd_p(char *args) {
	if(args == NULL || args[0] == '\0') {
		printf("Usage: p <EXPR>\n");
		return 0;
	}
	
	bool success;
	uint32_t val = expr(args, &success);
	if(success) {
		printf("0x%08x\n", val);
	} else {
		printf("Expression evaluation failed\n");
	}
	return 0;
}

static int cmd_x(char *args) {
	if(args == NULL || args[0] == '\0') {
		printf("Usage: x <N> <EXPR>\n");
		return 0;
	}
	
	char *n_str = strtok(args, " ");
	if(n_str == NULL) {
		printf("Usage: x <N> <EXPR>\n");
		return 0;
	}
	
	int n = atoi(n_str);
	if(n <= 0) {
		printf("Invalid number: %s\n", n_str);
		return 0;
	}
	
	char *expr_str = strtok(NULL, "");
	if(expr_str == NULL || expr_str[0] == '\0') {
		printf("Usage: x <N> <EXPR>\n");
		return 0;
	}
	
	bool success;
	uint32_t addr = expr(expr_str, &success);
	if(!success) {
		printf("Expression evaluation failed\n");
		return 0;
	}
	
	addr = addr & 0x7FFFFFFF; /* Map virtual address to physical */
	
	int i;
	for(i = 0; i < n; i++) {
		if(i % 4 == 0) {
			if(i > 0) printf("\n");
			printf("0x%08x: ", addr + i * 4);
		}
		uint32_t val = mem_read(addr + i * 4, 4);
		printf("0x%08x ", val);
	}
	printf("\n");
	return 0;
}

static int cmd_w(char *args) {
	if(args == NULL || args[0] == '\0') {
		printf("Usage: w <EXPR>\n");
		return 0;
	}
	
	WP *wp = new_wp(args);
	if(wp == NULL) {
		return 0;
	}
	return 0;
}

static int cmd_d(char *args) {
	if(args == NULL || args[0] == '\0') {
		printf("Usage: d <N>\n");
		return 0;
	}
	
	int n = atoi(args);
	if(n < 0) {
		printf("Invalid watchpoint number: %s\n", args);
		return 0;
	}
	
	free_wp(n);
	return 0;
}

static int cmd_help(char *args);

static struct {
	char *name;
	char *description;
	int (*handler) (char *);
} cmd_table [] = {
	{ "help", "Display informations about all supported commands", cmd_help },
	{ "c", "Continue the execution of the program", cmd_c },
	{ "q", "Exit TEMU", cmd_q },
	{ "si", "Single step execution N instructions", cmd_si },
	{ "info", "Print program status (r: registers, w: watchpoints)", cmd_info },
	{ "p", "Evaluate expression", cmd_p },
	{ "x", "Scan memory", cmd_x },
	{ "w", "Set watchpoint", cmd_w },
	{ "d", "Delete watchpoint", cmd_d }
};

#define NR_CMD (sizeof(cmd_table) / sizeof(cmd_table[0]))

static int cmd_help(char *args) {
	/* extract the first argument */
	char *arg = strtok(NULL, " ");
	int i;

	if(arg == NULL) {
		/* no argument given */
		for(i = 0; i < NR_CMD; i ++) {
			printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
		}
	}
	else {
		for(i = 0; i < NR_CMD; i ++) {
			if(strcmp(arg, cmd_table[i].name) == 0) {
				printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
				return 0;
			}
		}
		printf("Unknown command '%s'\n", arg);
	}
	return 0;
}

void ui_mainloop() {
	while(1) {
		char *str = rl_gets();
		char *str_end = str + strlen(str);

		/* extract the first token as the command */
		char *cmd = strtok(str, " ");
		if(cmd == NULL) { continue; }

		/* treat the remaining string as the arguments,
		 * which may need further parsing
		 */
		char *args = cmd + strlen(cmd) + 1;
		if(args >= str_end) {
			args = NULL;
		}

		int i;
		for(i = 0; i < NR_CMD; i ++) {
			if(strcmp(cmd, cmd_table[i].name) == 0) {
				if(cmd_table[i].handler(args) < 0) { return; }
				break;
			}
		}

		if(i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
	}
}
