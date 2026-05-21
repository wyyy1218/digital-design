#include "helper.h"
#include "monitor.h"
#include "reg.h"
#include "memory/memory.h"
#include "debug.h"

extern uint32_t instr;
extern char assembly[80];

/* 解码无符号12位立即数的I12型指令 */
static void decode_ui12_type(uint32_t instr) {

	op_src1->type = OP_TYPE_REG;
	op_src1->reg = (instr >> 5) & 0x0000001F;
	op_src1->val = reg_w(op_src1->reg);

	op_src2->type = OP_TYPE_IMM;
	op_src2->imm = (instr >> 10) & 0x00000FFF;
	op_src2->val = op_src2->imm;

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = instr & 0x0000001F;
}

/* 解码有符号12位立即数的I12型指令 */
static void decode_si12_type(uint32_t instr) {
    op_src1->type = OP_TYPE_REG;
    op_src1->reg = (instr >> 5) & 0x0000001F;
    op_src1->val = reg_w(op_src1->reg);

    op_src2->type = OP_TYPE_IMM;
    /* 提取bits [21:10]并符号扩展至32位 */
    op_src2->imm = (instr >> 10) & 0x00000FFF;
    
    // 符号扩展：将12位有符号数扩展到32位
    if (op_src2->imm & 0x800) {  // 检查第11位（0-based）
        op_src2->simm = (int32_t)(op_src2->imm | 0xFFFFF000);
    } else {
        op_src2->simm = (int32_t)op_src2->imm;
    }
    
    op_src2->val = op_src2->simm;
    
    op_dest->type = OP_TYPE_REG;
    op_dest->reg = instr & 0x0000001F;
    
    // // 调试信息
    // printf("[DECODE_SI12 DEBUG] imm=0x%03x, simm=%d (0x%08x)\n",
    //        op_src2->imm, op_src2->simm, op_src2->simm);
}

make_helper(ori) {
	decode_ui12_type(instr);
	reg_w(op_dest->reg) = op_src1->val | op_src2->val;
	sprintf(assembly, "ori\t%s,\t%s,\t0x%03x", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->imm);
	if (op_dest->reg != 0 && trace_fp != NULL) {
		fprintf(trace_fp, "%08x %d %08x\n", pc, op_dest->reg, reg_w(op_dest->reg));
		fflush(trace_fp);
	}
}

make_helper(addi_w) {
    decode_si12_type(instr);
    
    // // 添加详细调试信息
    // printf("[ADDI.W DEBUG] pc=0x%08x\n", pc);
    // printf("  rs=%s(0x%08x) imm=0x%03x simm=%d rd=%s\n",
    //        REG_NAME(op_src1->reg), op_src1->val,
    //        op_src2->imm, op_src2->simm,
    //        REG_NAME(op_dest->reg));
    
    if (op_dest->reg != 0) {
        // uint32_t old_val = reg_w(op_dest->reg);
        reg_w(op_dest->reg) = op_src1->val + op_src2->val;
        
        // printf("  Result: 0x%08x + %d = 0x%08x\n", 
        //        old_val, op_src2->simm, reg_w(op_dest->reg));
        
        sprintf(assembly, "addi.w\t%s,\t%s,\t%d", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                op_src2->simm);
        
        if (trace_fp != NULL) {
            fprintf(trace_fp, "%08x %d %08x\n", pc, op_dest->reg, reg_w(op_dest->reg));
            fflush(trace_fp);
        }
    } else {
        sprintf(assembly, "addi.w\t%s,\t%s,\t%d", 
                REG_NAME(op_dest->reg), 
                REG_NAME(op_src1->reg), 
                op_src2->simm);
    }
}

make_helper(andi) {

	decode_ui12_type(instr);
	if (op_dest->reg != 0) {
		reg_w(op_dest->reg) = op_src1->val & op_src2->val;
		sprintf(assembly, "andi\t%s,\t%s,\t0x%03x", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->imm);
		if (trace_fp != NULL) {
			fprintf(trace_fp, "%08x %d %08x\n", pc, op_dest->reg, reg_w(op_dest->reg));
			fflush(trace_fp);
		}
	} else {
		sprintf(assembly, "andi\t%s,\t%s,\t0x%03x", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->imm);
	}
}

make_helper(sltui) {

	decode_si12_type(instr);
	if (op_dest->reg != 0) {
		/* 无符号比较: rj < 立即数 */
		uint32_t imm_unsigned = (uint32_t)op_src2->simm;
		reg_w(op_dest->reg) = ((uint32_t)op_src1->val < imm_unsigned) ? 1 : 0;
		sprintf(assembly, "sltui\t%s,\t%s,\t%d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
		if (trace_fp != NULL) {
			fprintf(trace_fp, "%08x %d %08x\n", pc, op_dest->reg, reg_w(op_dest->reg));
			fflush(trace_fp);
		}
	} else {
		sprintf(assembly, "sltui\t%s,\t%s,\t%d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
	}
}

make_helper(ld_w) {

	decode_si12_type(instr);
	uint32_t addr = op_src1->val + op_src2->val;
	if (op_dest->reg != 0) {
		reg_w(op_dest->reg) = mem_read(addr, 4);
		sprintf(assembly, "ld.w\t%s,\t%s,\t%d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
		if (trace_fp != NULL) {
			fprintf(trace_fp, "%08x %d %08x\n", pc, op_dest->reg, reg_w(op_dest->reg));
			fflush(trace_fp);
		}
	} else {
		sprintf(assembly, "ld.w\t%s,\t%s,\t%d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
	}
}

make_helper(st_w) {

	decode_si12_type(instr);
	uint32_t addr = op_src1->val + op_src2->val;
	/* st.w使用rd作为源寄存器 */
	uint32_t rd = op_dest->reg;
	uint32_t data = reg_w(rd);
	mem_write(addr, 4, data);
	sprintf(assembly, "st.w\t%s,\t%s,\t%d", REG_NAME(rd), REG_NAME(op_src1->reg), op_src2->simm);
}

make_helper(ld_b) {

	decode_si12_type(instr);
	uint32_t addr = op_src1->val + op_src2->val;
	if (op_dest->reg != 0) {
		/* 加载字节并符号扩展至32位 */
		uint32_t byte_val = mem_read(addr, 1);
		int8_t signed_byte = (int8_t)byte_val;
		reg_w(op_dest->reg) = (int32_t)signed_byte;
		sprintf(assembly, "ld.b\t%s,\t%s,\t%d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
		if (trace_fp != NULL) {
			fprintf(trace_fp, "%08x %d %08x\n", pc, op_dest->reg, reg_w(op_dest->reg));
			fflush(trace_fp);
		}
	} else {
		sprintf(assembly, "ld.b\t%s,\t%s,\t%d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
	}
}

make_helper(st_b) {

	decode_si12_type(instr);
	uint32_t addr = op_src1->val + op_src2->val;
	/* st.b使用rd作为源寄存器 */
	uint32_t rd = op_dest->reg;
	uint32_t data = reg_w(rd) & 0xFF;
	mem_write(addr, 1, data);
	sprintf(assembly, "st.b\t%s,\t%s,\t%d", REG_NAME(rd), REG_NAME(op_src1->reg), op_src2->simm);
}
