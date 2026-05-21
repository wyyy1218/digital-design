#include "common.h"

uint32_t dram_read(uint32_t, size_t);
void dram_write(uint32_t, size_t, uint32_t);

/* Memory accessing interfaces */

uint32_t mem_read(uint32_t addr, size_t len) {
#ifdef DEBUG
	assert(len == 1 || len == 2 || len == 4);
#endif
	/* 固定地址映射：最高位清零，把 0x8xxx_xxxx 映射到物理内存
	 * 与 monitor.c 中 load_entry 时使用的 (ENTRY_START & 0x7fffffff) 规则保持一致。
	 */
	addr &= 0x7fffffff;
	return dram_read(addr, len) & (~0u >> ((4 - len) << 3));
}

void mem_write(uint32_t addr, size_t len, uint32_t data) {
#ifdef DEBUG
	assert(len == 1 || len == 2 || len == 4);
#endif
	/* 写入同样需要做统一编址映射 */
	addr &= 0x7fffffff;
	dram_write(addr, len, data);
}

