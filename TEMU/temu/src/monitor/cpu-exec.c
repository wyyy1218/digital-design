#include "monitor.h"
#include "helper.h"
#include "watchpoint.h"

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
#define MAX_INSTR_TO_PRINT 10

int temu_state = STOP;

void exec(uint32_t);

char assembly[80];
char asm_buf[128];

void print_bin_instr(uint32_t pc) {
	int i;
	int l = sprintf(asm_buf, "%8x:   ", pc);
	for(i = 3; i >= 0; i --) {
		l += sprintf(asm_buf + l, "%02x ", instr_fetch(pc + i, 1));
	}
	sprintf(asm_buf + l, "%*.s", 8, "");
}

/* Simulate how the MiniMIPS32 CPU works. */
void cpu_exec(volatile uint32_t n) {
	
	uint32_t pc;
	if(temu_state == END) {
		printf("Program execution has ended. To restart the program, exit TEMU and run again.\n");
		return;
	}
	temu_state = RUNNING;

	volatile uint32_t n_temp = n;
	bool should_print = (n > 0 && n <= MAX_INSTR_TO_PRINT);

	/* Handle infinite execution (n = -1) */
	if(n == (uint32_t)-1) {
		n = 0xFFFFFFFF; /* Set to max value, but check watchpoints in loop */
		should_print = false;
	}

	for(; n > 0; n --) {

		pc = cpu.pc & 0x7FFFFFFF;  //map the virtual address to the physical address, e.g. the highest bit in cpu.pc are cleared
		
		if(should_print || (n_temp == (uint32_t)-1 && n <= MAX_INSTR_TO_PRINT)) {
			print_bin_instr(pc);
		}

		/* Execute one instruction, including instruction fetch,
		 * instruction decode, and the actual execution. */
		exec(pc);

		cpu.pc += 4;

		if(should_print || (n_temp == (uint32_t)-1 && n <= MAX_INSTR_TO_PRINT)) {
			strcat(asm_buf, assembly);
			printf("%s\n", asm_buf);
		}

		/* Check watchpoints */
		if(check_wp()) {
			temu_state = STOP;
			return;
		}

		if(temu_state != RUNNING) { return; }
	}

	if(temu_state == RUNNING) { temu_state = STOP; }
}
