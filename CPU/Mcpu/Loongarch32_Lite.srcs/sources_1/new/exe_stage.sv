`include "defines.v"

module exe_stage (

    // 从译码阶段获得的信息
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    input  wire [`INST_ADDR_BUS]    exe_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 【新增】源操作数寄存器号 (来自 idexe_reg)
    input  wire [`REG_ADDR_BUS  ]   exe_ra1_i,
    input  wire [`REG_ADDR_BUS  ]   exe_ra2_i,
    
    // 【新增】Store 数据输入 (需要前推)
    input  wire [`REG_BUS       ]   exe_rk_d_i, 

    // 【新增】来自 MEM 阶段的前推信息
    input  wire                     mem_wreg_i,
    input  wire [`REG_ADDR_BUS  ]   mem_wa_i,
    input  wire [`REG_BUS       ]   mem_wd_i, // MEM 阶段的 ALU 结果 (或 Load 结果)

    // 【新增】来自 WB 阶段的前推信息
    input  wire                     wb_wreg_i,
    input  wire [`REG_ADDR_BUS  ]   wb_wa_i,
    input  wire [`REG_BUS       ]   wb_wd_i,  // WB 阶段的最终数据

    // 送至执行阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    
    // 【新增】处理过前推的 Store 数据
    output wire [`REG_BUS       ]   exe_rk_d_o,
    
    output wire [`INST_ADDR_BUS] 	debug_wb_pc  // 供调试使用的PC值，上板测试时务必删除该信号
    );

    // 直接传到下一阶段
    assign exe_aluop_o = exe_aluop_i;
    /*
    //原本代码
    wire [`REG_BUS       ]      logicres;       // 保存逻辑运算的结果
    
    // 根据内部操作码aluop进行逻辑运算
    assign logicres = (exe_aluop_i == `LoongArch32_ANDI )  ? (exe_src1_i & exe_src2_i) : `ZERO_WORD;

    assign exe_wa_o   = exe_wa_i;
    assign exe_wreg_o = exe_wreg_i;
    
    // 根据操作类型alutype确定执行阶段最终的运算结果（既可能是待写入目的寄存器的数据，也可能是访问数据存储器的地址）
    assign exe_wd_o = (exe_alutype_i == `LOGIC    ) ? logicres  : `ZERO_WORD;
    
    assign debug_wb_pc = exe_debug_wb_pc;    // 上板测试时务必删除该语句 
    */
    assign exe_wa_o    = exe_wa_i;
    assign exe_wreg_o  = exe_wreg_i;
    assign debug_wb_pc = exe_debug_wb_pc;   // 上板测试时务必删除该语句 
    
     /* ---------------------------------------------------------
     * 数据前推逻辑 (Forwarding Unit)
     * --------------------------------------------------------- */
    
    // 1. 判断源操作数 1 是否需要前推
    // 如果 MEM 阶段写寄存器，且不为0，且与当前源1相同 -> 借用 MEM 数据
    wire forward_a_mem = (mem_wreg_i && (mem_wa_i != 0) && (mem_wa_i == exe_ra1_i));
    // 如果 WB 阶段写寄存器 ... (且 MEM 阶段没有前推，MEM 优先级更高)
    // 注意：这里不需要!forward_a_mem，因为final_src1的选择逻辑已经处理了优先级
    wire forward_a_wb  = (wb_wreg_i  && (wb_wa_i  != 0) && (wb_wa_i  == exe_ra1_i));

    // 2. 判断源操作数 2 是否需要前推
    wire forward_b_mem = (mem_wreg_i && (mem_wa_i != 0) && (mem_wa_i == exe_ra2_i));
    // 注意：这里不需要!forward_b_mem，因为temp_src2的选择逻辑已经处理了优先级
    wire forward_b_wb  = (wb_wreg_i  && (wb_wa_i  != 0) && (wb_wa_i  == exe_ra2_i));

    // 3. 选择最终的操作数
    // 如果发生前推，优先用 MEM 阶段的数据 (最新)，否则用 WB，否则用原值
    wire [`REG_BUS] final_src1 = forward_a_mem ? mem_wd_i : 
                                 forward_a_wb  ? wb_wd_i  : exe_src1_i;
                                 
    wire [`REG_BUS] temp_src2  = forward_b_mem ? mem_wd_i : 
                                 forward_b_wb  ? wb_wd_i  : exe_src2_i;

    /* ---------------------------------------------------------
     * ALU 操作数选择逻辑 (解决 Imm 和 Reg 的冲突)
     * --------------------------------------------------------- */
    
    reg [`REG_BUS] final_src2_alu;  // 给 ALU 用的 Src2
    reg [`REG_BUS] final_store_data; // 给 Store 用的数据

    always @(*) begin
        // 默认情况下，ALU 使用 temp_src2 (即前推后的值)
        final_src2_alu = temp_src2;
        // 默认 Store 数据也是前推后的值
        final_store_data = temp_src2;

        case (exe_aluop_i)
            // ?? 立即数指令：addi.w, ld.w, st.w 等
            // 这些指令的 operand 2 是立即数，不能被前推值覆盖！
            `LoongArch32_ADDI_W, `LoongArch32_LD_W, `LoongArch32_LD_B, 
            `LoongArch32_SLTUI, `LoongArch32_ORI, `LoongArch32_ANDI, 
            //`LoongArch32_XOR, // 注意：XOR 在 defines.v 里通常是寄存器版，如果是 XORI 则是立即数
            `LoongArch32_SRA_W, // 移位量也是立即数或 src2
            `LoongArch32_PCADDU12I, `LoongArch32_LU12I_W: begin
                 // 如果是 I 型指令，ALU 的 Src2 必须强制使用原始的立即数 (exe_src2_i)
                 final_src2_alu = exe_src2_i;
            end
            
            // ?? Store 指令特殊处理
            // ST.W: ALU Src2 是立即数(offset), 但 Store Data (rd2) 是寄存器
            `LoongArch32_ST_W, `LoongArch32_ST_B: begin
                 final_src2_alu = exe_src2_i; // ALU 地址计算用立即数
                 
                 // Store 的数据来自 rd2，需要检查是否前推 (rk_d_i 是原始 rd2)
                 // 如果 exe_ra2_i (即 rd) 匹配了前推，则用 temp_src2，否则用 rk_d
                 if (forward_b_mem || forward_b_wb) 
                     final_store_data = temp_src2; 
                 else 
                     final_store_data = exe_rk_d_i;
            end
            
            default: begin 
                // R 型指令 (add.w, sub.w, or, etc.)
                // ALU 使用前推后的寄存器值
                final_src2_alu = temp_src2; 
            end
        endcase
    end

    // 将处理好的 Store 数据传给下一级
    assign exe_rk_d_o = final_store_data;

    /* ---------------------------------------------------------
     * ALU 运算 (使用 final_src1 和 final_src2_alu)
     * --------------------------------------------------------- */
    reg [`REG_BUS] alu_res;

    always @(*) begin
        case (exe_aluop_i)
            // 算术运算
            `LoongArch32_ADD_W, `LoongArch32_ADDI_W, 
            `LoongArch32_LD_W, `LoongArch32_ST_W, 
            `LoongArch32_LD_B, `LoongArch32_ST_B: begin
                alu_res = final_src1 + final_src2_alu; // 使用处理后的操作数
            end
            `LoongArch32_PCADDU12I: begin
                alu_res = final_src1 + final_src2_alu; 
            end
            `LoongArch32_LU12I_W: begin
                alu_res = final_src2_alu; 
            end

            // 逻辑运算
            `LoongArch32_OR, `LoongArch32_ORI: begin
                alu_res = final_src1 | final_src2_alu;
            end
            `LoongArch32_ANDI: begin
                alu_res = final_src1 & final_src2_alu;
            end
            `LoongArch32_XOR: begin
                alu_res = final_src1 ^ final_src2_alu;
            end

            // 移位运算
            `LoongArch32_SRA_W: begin
                alu_res = $signed(final_src1) >>> final_src2_alu[4:0];
            end

            // 比较 (sltui)
            `LoongArch32_SLTUI: begin
                alu_res = (final_src1 < final_src2_alu) ? 32'd1 : 32'd0;
            end

            default: alu_res = `ZERO_WORD;
        endcase
    end
    
    assign exe_wd_o = alu_res;
endmodule