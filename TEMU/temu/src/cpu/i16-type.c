#include "helper.h"
#include "monitor.h"
#include "reg.h"

extern uint32_t instr;
extern char assembly[80];

/* decode I16-type instrucion with signed immediate */
static void decode_i16_type(uint32_t instr) {

	op_src1->type = OP_TYPE_REG;
	op_src1->reg = (instr >> 5) & 0x0000001F;
	op_src1->val = reg_w(op_src1->reg); // 源寄存器src1

	op_src2->type = OP_TYPE_IMM;
	op_src2->imm = (instr >> 10) & 0x0000FFFF;
	op_src2->val = op_src2->imm; //立即数是src2,offs16

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = instr & 0x0000001F;//后5位是目标寄存器
    op_dest->val = reg_w(op_dest->reg); 
}

//TODO:添加指令beq bne bge

make_helper(bne) {
    decode_i16_type(instr);
    
    // 保存当前PC
    uint32_t current_pc = cpu.pc;
    
    if(op_src1->val != op_dest->val) {
        uint32_t temp;
        if(op_src2->val >> 15) { // 符号扩展1
            temp = (op_src2->val << 2) + 0xFFFC0000;
        } else { // 符号扩展0
            temp = op_src2->val << 2;
        }
        
        // 关键：由于框架会自动加4，我们需要减去4来抵消
        // 跳转目标 = 当前PC + 偏移量
        // 但框架会加4，所以我们设置为：当前PC + 偏移量 - 4
        cpu.pc = current_pc + temp - 4;
        
        // printf("[BNE] Jump from 0x%08x to 0x%08x (offset=%d, actual target=0x%08x)\n", 
        //        current_pc, cpu.pc, (int32_t)temp, current_pc + temp);
    } else {
        // // 不跳转，让框架正常加4
        // printf("[BNE] No jump from 0x%08x\n", current_pc);
    }
    
    // sprintf(assembly, "bne\t%s,\t%s,\t0x%08x", 
    //         REG_NAME(op_src1->reg), 
    //         REG_NAME(op_dest->reg), 
    //         op_src2->imm);
}

make_helper(beq) {
    decode_i16_type(instr);
    
    uint32_t current_pc = cpu.pc;
    
    if(op_src1->val == op_dest->val) {
        uint32_t temp;
        if(op_src2->val >> 15) // 符号扩展1
            temp = (op_src2->val << 2) + 0xFFFC0000;
        else // 符号扩展0
            temp = op_src2->val << 2; 
        
        // 同样减去4抵消框架的自动加4
        cpu.pc = current_pc + temp - 4;
    }
    
    // sprintf(assembly, "beq\t%s,\t%s,\t0x%08x", 
    //         REG_NAME(op_src1->reg), 
    //         REG_NAME(op_dest->reg), 
    //         op_src2->imm);
}

make_helper(bge) {
    decode_i16_type(instr);
    
    uint32_t current_pc = cpu.pc;
    
    // 有符号比较
    int32_t rs_val = (int32_t)op_src1->val;
    int32_t rt_val = (int32_t)op_dest->val;
    
    if(rs_val >= rt_val) {
        uint32_t temp;
        if(op_src2->val >> 15) // 符号扩展1
            temp = (op_src2->val << 2) + 0xFFFC0000;
        else // 符号扩展0
            temp = op_src2->val << 2;
        
        // 同样减去4抵消框架的自动加4
        cpu.pc = current_pc + temp - 4;
    }
    
    // sprintf(assembly, "bge\t%s,\t%s,\t0x%08x", 
    //         REG_NAME(op_src1->reg), 
    //         REG_NAME(op_dest->reg), 
    //         op_src2->imm);
}