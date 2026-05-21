#include "helper.h"
#include "monitor.h"
#include "reg.h"

extern uint32_t instr;
extern char assembly[80];

/* decode I20-type instrucion with signed immediate */
static void decode_i20_type(uint32_t instr) {

	
	op_src2->type = OP_TYPE_IMM;
	op_src2->imm = (instr >> 5) & 0x000FFFFF;
	op_src2->val = op_src2->imm;

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = instr & 0x0000001F;
}

make_helper(lu12i_w) {

	decode_i20_type(instr);
	reg_w(op_dest->reg) = (op_src2->val << 12);
	sprintf(assembly, "lu12i.w\t%s,\t0x%04x", REG_NAME(op_dest->reg), op_src2->imm);
}

// 新增A
make_helper(pcaddu12i) {
    decode_i20_type(instr);
    
    // 符号扩展20位立即数
    int32_t imm = op_src2->imm;
    if (imm & 0x80000) {
        imm |= 0xfff00000;
    }
    
    // 计算：rd = PC + (imm << 12)
    // 注意：这里的 cpu.pc 是当前指令地址
    uint32_t result = cpu.pc + (imm << 12);
    
    // 写入目标寄存器
    reg_w(op_dest->reg) = result;
    
    // // 打印汇编
    // sprintf(assembly, "pcaddu12i\t%s,\t0x%04x", REG_NAME(op_dest->reg), op_src2->imm);
    
}
