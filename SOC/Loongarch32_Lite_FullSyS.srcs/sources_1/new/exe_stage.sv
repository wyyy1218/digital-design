`include "defines.v"

module exe_stage (

    
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    
    // from idexe_reg
    input  wire [`REG_ADDR_BUS  ]   exe_ra1_i,
    input  wire [`REG_ADDR_BUS  ]   exe_ra2_i,
    
    input  wire [`REG_BUS       ]   exe_rk_d_i, 

    input  wire                     mem_wreg_i,
    input  wire [`REG_ADDR_BUS  ]   mem_wa_i,
    input  wire [`REG_BUS       ]   mem_wd_i,

    input  wire                     wb_wreg_i,
    input  wire [`REG_ADDR_BUS  ]   wb_wa_i,
    input  wire [`REG_BUS       ]   wb_wd_i,

    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    
    // Debug signals for forwarding
    output wire [`REG_ADDR_BUS ]   debug_exe_ra1,
    output wire [`REG_ADDR_BUS ]   debug_exe_ra2,
    output wire                    debug_forward_a_mem,
    output wire                    debug_forward_a_wb,
    output wire [`REG_BUS]         debug_final_src1,
    output wire [`REG_BUS]         debug_final_src2,     // Final source 2 value
    output wire [`REG_BUS]         debug_exe_src2_i,     // EXE stage source 2 (before forwarding)
    output wire                    debug_forward_b_mem,  // Forward from MEM for src2
    output wire                    debug_forward_b_wb,   // Forward from WB for src2
    output wire                    debug_mem_wreg_i,
    output wire [`REG_ADDR_BUS]    debug_mem_wa_i,
    output wire [`REG_BUS]         debug_mem_wd_i,
    output wire                    debug_wb_wreg_i,
    output wire [`REG_ADDR_BUS]    debug_wb_wa_i,
    output wire [`REG_BUS]         debug_wb_wd_i,
    output wire [`REG_BUS]         debug_exe_src1_i,
    // Debug signals for module input values (internal)
    output wire                    debug_exe_wb_wreg_i_internal,
    output wire [`REG_ADDR_BUS]    debug_exe_wb_wa_i_internal,
    output wire [`REG_BUS]         debug_exe_wb_wd_i_internal,
    // Debug signals for forwarding condition calculations
    output wire                    debug_forward_a_wb_condition,
    output wire                    debug_forward_b_wb_condition,
    // Debug signals for MEM stage forwarding condition
    output wire                    debug_forward_a_mem_condition,
    output wire                    debug_forward_b_mem_condition,
    // Debug signals for forwarding condition components
    output wire                    debug_wb_wreg_i_value,
    output wire [`REG_ADDR_BUS]    debug_wb_wa_i_value,
    output wire                    debug_wb_wa_i_not_zero,
    output wire                    debug_wb_wa_i_eq_ra1,
    output wire                    debug_wb_wa_i_eq_ra2,
    output wire                    debug_mem_wreg_i_value,
    output wire [`REG_ADDR_BUS]    debug_mem_wa_i_value,
    output wire                    debug_mem_wa_i_not_zero,
    output wire                    debug_mem_wa_i_eq_ra1,
    output wire                    debug_mem_wa_i_eq_ra2,
    output wire [`REG_ADDR_BUS]    debug_exe_ra1_i_value,
    output wire [`REG_ADDR_BUS]    debug_exe_ra2_i_value,
    // Detailed debug signals for forward_a_mem calculation
    output wire                    debug_forward_a_mem_calc_mem_wreg_i,  // mem_wreg_i value used in forward_a_mem calculation
    output wire [`REG_ADDR_BUS]    debug_forward_a_mem_calc_mem_wa_i,    // mem_wa_i value used in forward_a_mem calculation
    output wire                    debug_forward_a_mem_calc_mem_wa_i_not_zero, // (mem_wa_i != 0) result in forward_a_mem calculation
    output wire [`REG_ADDR_BUS]    debug_forward_a_mem_calc_exe_ra1_i,   // exe_ra1_i value used in forward_a_mem calculation
    output wire                    debug_forward_a_mem_calc_mem_wa_i_eq_ra1,   // (mem_wa_i == exe_ra1_i) result in forward_a_mem calculation
    output wire                    debug_forward_a_mem_calc_result,       // forward_a_mem calculation result
    output wire [`REG_ADDR_BUS]    debug_mem_wa_i_at_assign,             // mem_wa_i value at assign debug_mem_wa_i
    output wire [`REG_ADDR_BUS]    debug_mem_wa_i_at_forward_calc,       // mem_wa_i value at forward_a_mem calculation
    
    // Store data to pass to MEM
    output wire [`REG_BUS       ]   exe_rk_d_o
    );

    
    assign exe_aluop_o = exe_aluop_i;
    /*
    
    wire [`REG_BUS       ]      logicres;       
    
    assign logicres = (exe_aluop_i == `LoongArch32_ANDI )  ? (exe_src1_i & exe_src2_i) : `ZERO_WORD;

    assign exe_wa_o   = exe_wa_i;
    assign exe_wreg_o = exe_wreg_i;
    
    assign exe_wd_o = (exe_alutype_i == `LOGIC    ) ? logicres  : `ZERO_WORD;
    
    */
    assign exe_wa_o    = exe_wa_i;
    assign exe_wreg_o  = exe_wreg_i;
    
     /* ---------------------------------------------------------
     * 前递单元 (Forwarding Unit)
     * --------------------------------------------------------- */
    
    wire forward_a_mem = (mem_wreg_i && (mem_wa_i != 0) && (mem_wa_i == exe_ra1_i));
    wire forward_a_wb  = (wb_wreg_i  && (wb_wa_i  != 0) && (wb_wa_i  == exe_ra1_i));

    wire forward_b_mem = (mem_wreg_i && (mem_wa_i != 0) && (mem_wa_i == exe_ra2_i));
    wire forward_b_wb  = (wb_wreg_i  && (wb_wa_i  != 0) && (wb_wa_i  == exe_ra2_i));

    wire [`REG_BUS] final_src1 = forward_a_mem ? mem_wd_i : 
                                 forward_a_wb  ? wb_wd_i  : exe_src1_i;
                                 
    wire [`REG_BUS] temp_src2  = forward_b_mem ? mem_wd_i : 
                                 forward_b_wb  ? wb_wd_i  : exe_src2_i;

    /* ---------------------------------------------------------
     * ALU 源操作数选择 (立即数/寄存器冲突处理)
     * --------------------------------------------------------- */
    
    reg [`REG_BUS] final_src2_alu;
    reg [`REG_BUS] final_store_data;

    always @(*) begin
        final_src2_alu = temp_src2;
        final_store_data = temp_src2;

        case (exe_aluop_i)
            `LoongArch32_ADDI_W, `LoongArch32_LD_W, `LoongArch32_LD_B, 
            `LoongArch32_SLT, `LoongArch32_SLTU, `LoongArch32_SLTI, `LoongArch32_SLTUI, 
            `LoongArch32_ORI, `LoongArch32_ANDI, 
            `LoongArch32_SRA_W,
            `LoongArch32_PCADDU12I, `LoongArch32_LU12I_W: begin
                 final_src2_alu = exe_src2_i;
            end
            
            `LoongArch32_ST_W, `LoongArch32_ST_B: begin
                 final_src2_alu = exe_src2_i;
                 
                 if (forward_b_mem || forward_b_wb) 
                     final_store_data = temp_src2; 
                 else 
                     final_store_data = exe_rk_d_i;
            end
            
            default: begin 
                final_src2_alu = temp_src2; 
            end
        endcase
    end

    assign exe_rk_d_o = final_store_data;

    /* ---------------------------------------------------------
     * ALU  (? final_src1  final_src2_alu)
     * --------------------------------------------------------- */
    reg [`REG_BUS] alu_res;

    always @(*) begin
        case (exe_aluop_i)
            // 
            `LoongArch32_ADD_W, `LoongArch32_ADDI_W, 
            `LoongArch32_LD_W, `LoongArch32_ST_W, 
            `LoongArch32_LD_B, `LoongArch32_ST_B: begin
                alu_res = final_src1 + final_src2_alu; 
            end
            `LoongArch32_PCADDU12I: begin
                alu_res = final_src1 + final_src2_alu; 
            end
            `LoongArch32_LU12I_W: begin
                alu_res = final_src2_alu; 
            end
            `LoongArch32_BL: begin
                // bl: return address = PC + 4, already computed in id_stage as src1 + src2
                alu_res = final_src1 + final_src2_alu;  // PC + 4
            end
            `LoongArch32_JIRL: begin
                // jirl: return address = PC + 4, but PC is not in exe_stage
                // We need to pass PC through pipeline or compute it in id_stage
                // For now, assume src1 contains PC (set in id_stage)
                alu_res = final_src1 + final_src2_alu;  // PC + 4 (if src1=PC, src2=4)
            end

            
            `LoongArch32_OR, `LoongArch32_ORI: begin
                alu_res = final_src1 | final_src2_alu;
            end
            `LoongArch32_AND, `LoongArch32_ANDI: begin
                alu_res = final_src1 & final_src2_alu;
            end
            `LoongArch32_XOR: begin
                alu_res = final_src1 ^ final_src2_alu;
            end

            
            `LoongArch32_SRA_W: begin
                alu_res = $signed(final_src1) >>> final_src2_alu[4:0];
            end

            // SLT: Set Less Than (signed comparison)
            `LoongArch32_SLT: begin
                alu_res = ($signed(final_src1) < $signed(final_src2_alu)) ? 32'd1 : 32'd0;
            end
            
            // SLTU: Set Less Than (unsigned comparison)
            `LoongArch32_SLTU: begin
                alu_res = (final_src1 < final_src2_alu) ? 32'd1 : 32'd0;
            end
            
            // SLTI: Set Less Than Immediate (signed comparison)
            `LoongArch32_SLTI: begin
                alu_res = ($signed(final_src1) < $signed(final_src2_alu)) ? 32'd1 : 32'd0;
            end
            
            // SLTUI: Set Less Than Unsigned Immediate
            `LoongArch32_SLTUI: begin
                alu_res = (final_src1 < final_src2_alu) ? 32'd1 : 32'd0;
            end

            default: alu_res = `ZERO_WORD;
        endcase
    end
    
    assign exe_wd_o = alu_res;
    
    // Debug signal assignments
    assign debug_exe_ra1 = exe_ra1_i;
    assign debug_exe_ra2 = exe_ra2_i;
    assign debug_forward_a_mem = forward_a_mem;
    assign debug_forward_a_wb = forward_a_wb;
    assign debug_forward_b_mem = forward_b_mem;
    assign debug_forward_b_wb = forward_b_wb;
    assign debug_final_src1 = final_src1;
    // Ensure debug signals always have valid values (not x)
    assign debug_final_src2 = final_src2_alu;
    assign debug_exe_src2_i = exe_src2_i;
    assign debug_mem_wreg_i = mem_wreg_i;
    assign debug_mem_wa_i = mem_wa_i;
    assign debug_mem_wd_i = mem_wd_i;
    assign debug_wb_wreg_i = wb_wreg_i;
    assign debug_wb_wa_i = wb_wa_i;
    assign debug_wb_wd_i = wb_wd_i;
    assign debug_exe_src1_i = exe_src1_i;
    
    // Debug signals for module input values (to compare with PASSED_TO_EXE)
    assign debug_exe_wb_wreg_i_internal = wb_wreg_i;
    assign debug_exe_wb_wa_i_internal   = wb_wa_i;
    assign debug_exe_wb_wd_i_internal   = wb_wd_i;
    
    // Debug signals for forwarding logic intermediate calculations
    assign debug_forward_a_wb_condition = (wb_wreg_i && (wb_wa_i != 0) && (wb_wa_i == exe_ra1_i));
    assign debug_forward_b_wb_condition = (wb_wreg_i && (wb_wa_i != 0) && (wb_wa_i == exe_ra2_i));
    assign debug_forward_a_mem_condition = (mem_wreg_i && (mem_wa_i != 0) && (mem_wa_i == exe_ra1_i));
    assign debug_forward_b_mem_condition = (mem_wreg_i && (mem_wa_i != 0) && (mem_wa_i == exe_ra2_i));
    
    // Debug signals for forwarding condition components
    assign debug_wb_wreg_i_value = wb_wreg_i;
    assign debug_wb_wa_i_value = wb_wa_i;
    assign debug_wb_wa_i_not_zero = (wb_wa_i != 0);
    assign debug_wb_wa_i_eq_ra1 = (wb_wa_i == exe_ra1_i);
    assign debug_wb_wa_i_eq_ra2 = (wb_wa_i == exe_ra2_i);
    
    assign debug_mem_wreg_i_value = mem_wreg_i;
    assign debug_mem_wa_i_value = mem_wa_i;
    assign debug_mem_wa_i_not_zero = (mem_wa_i != 0);
    assign debug_mem_wa_i_eq_ra1 = (mem_wa_i == exe_ra1_i);
    assign debug_mem_wa_i_eq_ra2 = (mem_wa_i == exe_ra2_i);
    
    // Debug signals for exe_ra1_i and exe_ra2_i values
    assign debug_exe_ra1_i_value = exe_ra1_i;
    assign debug_exe_ra2_i_value = exe_ra2_i;
    
    // Detailed debug signals for forward_a_mem calculation
    // Capture values at the exact point where forward_a_mem is calculated
    assign debug_forward_a_mem_calc_mem_wreg_i = mem_wreg_i;
    assign debug_forward_a_mem_calc_mem_wa_i = mem_wa_i;
    assign debug_forward_a_mem_calc_mem_wa_i_not_zero = (mem_wa_i != 0);
    assign debug_forward_a_mem_calc_exe_ra1_i = exe_ra1_i;
    assign debug_forward_a_mem_calc_mem_wa_i_eq_ra1 = (mem_wa_i == exe_ra1_i);
    assign debug_forward_a_mem_calc_result = forward_a_mem;
    assign debug_mem_wa_i_at_assign = mem_wa_i;  // Same as mem_wa_i, captured at assign point
    assign debug_mem_wa_i_at_forward_calc = mem_wa_i;  // Same as mem_wa_i, captured at forward calculation point

endmodule