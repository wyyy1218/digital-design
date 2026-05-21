#include "helper.h"
#include "monitor.h"
#include "reg.h"

extern uint32_t instr;
extern char assembly[80];

/* decode 3R-type instrucion */
static void decode_3r_type(uint32_t instr) {

	op_src1->type = OP_TYPE_REG;
	op_src1->reg = (instr >> 5) & 0x0000001F;
	op_src1->val = reg_w(op_src1->reg);
	
	op_src2->type = OP_TYPE_REG;
	op_src2->imm = (instr >> 10) & 0x0000001F;
	op_src2->val = reg_w(op_src2->reg);

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = instr & 0x0000001F;
}

make_helper(or) {

	decode_3r_type(instr);
	reg_w(op_dest->reg) = (op_src1->val | op_src2->val);
	sprintf(assembly, "or\t%s,\t%s,\t%s", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), REG_NAME(op_src2->reg));
}

//新增A
make_helper(add_w) {
    decode_3r_type(instr);
    if (op_dest->reg != 0) {
        reg_w(op_dest->reg) = op_src1->val + op_src2->val;
        sprintf(assembly, "add.w\t%s,\t%s,\t%s", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                REG_NAME(op_src2->reg));
        if (trace_fp != NULL) {
            fprintf(trace_fp, "%08x %d %08x\n", 
                    pc, op_dest->reg, reg_w(op_dest->reg));
            fflush(trace_fp);
        }
    } else {
        sprintf(assembly, "add.w\t%s,\t%s,\t%s", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                REG_NAME(op_src2->reg));
    }
}

make_helper(xor) {
    decode_3r_type(instr);
    if (op_dest->reg != 0) {
        reg_w(op_dest->reg) = op_src1->val ^ op_src2->val;
        sprintf(assembly, "xor\t%s,\t%s,\t%s", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                REG_NAME(op_src2->reg));
        if (trace_fp != NULL) {
            fprintf(trace_fp, "%08x %d %08x\n", 
                    pc, op_dest->reg, reg_w(op_dest->reg));
            fflush(trace_fp);
        }
    } else {
        sprintf(assembly, "xor\t%s,\t%s,\t%s", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                REG_NAME(op_src2->reg));
    }
}

make_helper(sra_w) {
    decode_3r_type(instr);
    if (op_dest->reg != 0) {
        // 龙芯 sra.w：算术右移，符号位填充
        int32_t src_val = (int32_t)op_src1->val;
        uint32_t shift_amount = op_src2->val & 0x1F; // 只取低5位
        reg_w(op_dest->reg) = (uint32_t)(src_val >> shift_amount);
        sprintf(assembly, "sra.w\t%s,\t%s,\t%s", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                REG_NAME(op_src2->reg));
        if (trace_fp != NULL) {
            fprintf(trace_fp, "%08x %d %08x\n", 
                    pc, op_dest->reg, reg_w(op_dest->reg));
            fflush(trace_fp);
        }
    } else {
        sprintf(assembly, "sra.w\t%s,\t%s,\t%s", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                REG_NAME(op_src2->reg));
    }
}