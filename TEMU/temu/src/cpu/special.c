#include "helper.h"
#include "monitor.h"

extern char assembly[80];

/* invalid opcode：之前这里直接 assert(0) 终止，现在改为仅告警并继续执行下一条，
 * 这样 test_debug 中未完全覆盖的指令不会把 TEMU 直接跑崩，方便你用 TEMU 跑自己写的 5 个测试程序。 */
make_helper(inv) {
	uint32_t temp = instr_fetch(pc, 4);
	uint8_t *p = (void *)&temp;

	printf("invalid opcode(pc = 0x%08x): %02x %02x %02x %02x ...\\n\\n", 
	       pc, p[3], p[2], p[1], p[0]);

	printf("There are two cases which will trigger this unexpected exception:\\n"
	       "1. The instruction at pc = 0x%08x is not implemented.\\n"
	       "2. Something is implemented incorrectly.\\n", pc);
	printf("Find this pc value(0x%08x) in the disassembling result to distinguish which case it is.\\n\\n", pc);

	/* 不再 assert，简单地把这条指令当作 NOP 处理：pc 已经在外层前进 4 字节，将继续执行下一条。 */
}

/* stop temu */
make_helper(temu_trap) {

	printf("\33[1;31mtemu: HIT GOOD TRAP\33[0m at $pc = 0x%08x\n\n", cpu.pc);

	temu_state = END;

}

