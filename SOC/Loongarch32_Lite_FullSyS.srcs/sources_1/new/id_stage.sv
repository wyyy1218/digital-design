`include "defines.v"

module id_stage(

    // ID stage: decode instruction and generate control/operand signals
    input  wire [`INST_ADDR_BUS]    id_pc_i,

    // Forwarding inputs for branch compare (EXE/MEM/WB -> ID)
    input  wire                     exe_fwd_wreg,
    input  wire [`REG_ADDR_BUS ]    exe_fwd_wa,
    input  wire [`REG_BUS      ]    exe_fwd_wd,

    input  wire                     mem_fwd_wreg,
    input  wire [`REG_ADDR_BUS ]    mem_fwd_wa,
    input  wire [`REG_BUS      ]    mem_fwd_wd,

    input  wire                     wb_fwd_wreg,
    input  wire [`REG_ADDR_BUS ]    wb_fwd_wa,
    input  wire [`REG_BUS      ]    wb_fwd_wd,
    
    // instruction to decode
    input  wire [`INST_BUS     ]    id_inst_i,
    
    // regfile read data
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,     
    
    // EXE-stage information for load-use hazard detection
    input  wire [`ALUOP_BUS    ]    exe_aluop_i,
    input  wire [`REG_ADDR_BUS ]    exe_wa_i,
    input  wire                     exe_wreg_i,
    
    // stall request to pipeline controller
    output wire                     stall_req,   
    
    // decode outputs
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire [`REG_ADDR_BUS ]    id_wa_o,
    output wire                     id_wreg_o,

    // decode operand outputs
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
    
    // store data passthrough (from rd2)
    output wire [`REG_BUS       ]   id_rk_d_o,
    
    // branch decision/result
    output wire                     br_taken,
    output wire [`INST_ADDR_BUS]    br_target,
    
    // regfile read addresses
    output wire [`REG_ADDR_BUS ]    ra1,
    output wire [`REG_ADDR_BUS ]    ra2,
    
    // Debug signals for instruction decoding
    output wire                     debug_inst_st_b,
    output wire [4:0]               debug_rd,
    output wire [4:0]               debug_rj,
    output wire [4:0]               debug_rk,
    output wire [9:0]               debug_op_31_22,
    output wire                     debug_is_store_or_branch,
    output wire                     debug_src2_is_imm,
    // Additional debug signals for immediate and register values
    output wire [31:0]              debug_imm_ext,
    output wire [31:0]              debug_rd1,
    output wire [31:0]              debug_rd2,
    // Debug signals for branch target calculation (for jirl)
    output wire [31:0]              debug_br_op1,      // br_op1 value (with forwarding)
    output wire [31:0]              debug_br_target,   // br_target value
    output wire [4:0]               debug_ra1,        // ID stage ra1 (for forwarding check)
    output wire [4:0]               debug_ra2,        // ID stage ra2 (for forwarding check)
    output wire [31:0]              debug_br_op1_raw, // br_op1_raw value (before forwarding)
    output wire                     debug_exe_fwd_match, // EXE forwarding match
    output wire                     debug_mem_fwd_match, // MEM forwarding match
    output wire                     debug_wb_fwd_match, // WB forwarding match
    output wire [31:0]              debug_exe_fwd_wd,   // EXE forwarding data
    output wire [31:0]              debug_mem_fwd_wd,   // MEM forwarding data
    output wire [31:0]              debug_wb_fwd_wd      // WB forwarding data
    );
    
    // endianness handling: inst_rom/data is little-endian, swap bytes for decode
    wire [`INST_BUS     ]    inst;
    assign inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};
    
    // (legacy comment removed)
    /*
    // (legacy comment removed)
    wire [16:0] op17  = inst[31:15];
    wire [4 :0] rd    = inst[4 : 0];
    wire [4 :0] rj    = inst[9 : 5];
    wire [11:0] imm12 = inst[21:10];
    
    // (legacy comment removed)
    wire        id_immsel;
    wire        id_sext;
    */
    
    // (legacy comment removed)
    wire [31:26] op_31_26 = inst[31:26];
    wire [31:22] op_31_22 = inst[31:22];
    wire [31:15] op_31_15 = inst[31:15];

    // (legacy comment removed)
    wire [4:0]  rd      = inst[4:0];
    wire [4:0]  rj      = inst[9:5];
    wire [4:0]  rk      = inst[14:10];
    wire [11:0] imm12   = inst[21:10];       // 12-bit immediate
    wire [15:0] imm16   = inst[25:10];       // 16-bit immediate (branch/jirl)
    wire [19:0] imm20   = inst[24:5];        // 20-bit immediate (lu12i/pcaddu12i)

    /*-------------------- Instruction decode --------------------*/
    //wire inst_andi  = ~|op17[16:11] & ~(~|op17[16:6]) &  op17[10] &  op17[9] & ~op17[8] &  op17[7];
    
    // 3R instructions
    wire inst_add_w  = (op_31_15 == 17'h00020);
    wire inst_or     = (op_31_15 == 17'h0002a);
    wire inst_and    = (op_31_15 == 17'h0002c);  // AND指令编码
    wire inst_xor    = (op_31_15 == 17'h0002e) || (op_31_15 == 17'h0002b);  // XOR指令编码：支持0x0002e和0x0002b两种编码
    wire inst_slt    = (op_31_15 == 17'h00024);  // SLT指令编码
    wire inst_sltu   = (op_31_15 == 17'h00025);  // SLTU指令编码
    wire inst_sra_w  = (op_31_15 == 17'h00030);
    
    // 2RI12 instructions (imm12)
    wire inst_addi_w = (op_31_22 == 10'h00a);
    wire inst_ld_b   = (op_31_22 == 10'h0a0);
    wire inst_ld_w   = (op_31_22 == 10'h0a2);
    wire inst_st_b   = (op_31_22 == 10'h0a4);
    wire inst_st_w   = (op_31_22 == 10'h0a6);
    wire inst_andi   = (op_31_22 == 10'h00d);
    wire inst_ori    = (op_31_22 == 10'h00e);
    wire inst_sltui  = (op_31_22 == 10'h009);  // SLTUI指令编码：op_31_22 = 0x009
    wire inst_slti   = (op_31_22 == 10'h008);  // SLTI指令编码
    
    // 1RI20 instructions (imm20)
    wire inst_lu12i_w    = (inst[31:25] == 7'h0a);
    wire inst_pcaddu12i  = (inst[31:25] == 7'h0e);

    // Branch instructions (opcode[31:26])
    wire inst_beq    = (op_31_26 == 6'h16);
    wire inst_bne    = (op_31_26 == 6'h17);
    wire inst_bge    = (op_31_26 == 6'h19);
    wire inst_b      = (op_31_26 == 6'h14);  // b offs26: PC=PC+SignExtend({offs26,2'b0},32) (unconditional branch, no return address)
    wire inst_bl     = (op_31_26 == 6'h15);  // bl offs26: GR[1]=PC+4, PC=PC+SignExtend({offs26,2'b0},32)
    wire inst_jirl   = (op_31_26 == 6'h13);  // jirl rd, rj, offs16: GR[rd]=PC+4, PC=GR[rj]+SignExtend({offs16,2'b0},32)
    
    /*--------------------- Control generation -------------------------*/
    /*
    // (legacy comment removed)
    assign id_alutype_o[2] = 1'b0;
    assign id_alutype_o[1] = inst_andi;
    assign id_alutype_o[0] = 1'b0; 
    
    // (legacy comment removed)
    assign id_aluop_o[7]   = 1'b0;
    assign id_aluop_o[6]   = 1'b0;
    assign id_aluop_o[5]   = 1'b0;
    assign id_aluop_o[4]   = inst_andi;
    assign id_aluop_o[3]   = inst_andi;
    assign id_aluop_o[2]   = inst_andi;
    assign id_aluop_o[1]   = 1'b0;
    assign id_aluop_o[0]   = 1'b0;
    
    // (legacy comment removed)
    assign id_wreg_o = inst_andi;
    // (legacy comment removed)
    assign id_immsel = inst_andi;
    // (legacy comment removed)
    assign id_sext   = 1'b0;

    // (legacy comment removed)
    assign ra1   = rj;
    assign ra2   = 5'b0;
    
    // (legacy comment removed)
    assign id_wa_o      = rd;
    
    // (legacy comment removed)
    wire [31:0] imm32;
    assign imm32 = (id_sext  == `TRUE_V) ? ({ {20{imm12[11]} } , imm12}) : ({20'b0 , imm12});

    // (legacy comment removed)
    assign id_src1_o =  rd1;

    // (legacy comment removed)
    assign id_src2_o = (id_immsel == `READ_ENABLE) ? imm32 : rd2;           
    
    */
    
    // 1. aluop
    assign id_aluop_o = 
        inst_add_w ? `LoongArch32_ADD_W :
        inst_addi_w? `LoongArch32_ADDI_W:
        inst_or    ? `LoongArch32_OR    :
        inst_ori   ? `LoongArch32_ORI   :
        inst_and   ? `LoongArch32_AND   :
        inst_xor   ? `LoongArch32_XOR   :
        inst_andi  ? `LoongArch32_ANDI  :
        inst_slt   ? `LoongArch32_SLT   :
        inst_sltu  ? `LoongArch32_SLTU  :
        inst_slti  ? `LoongArch32_SLTI  :
        inst_sltui ? `LoongArch32_SLTUI :
        inst_sra_w ? `LoongArch32_SRA_W :
        inst_lu12i_w   ? `LoongArch32_LU12I_W :
        inst_pcaddu12i ? `LoongArch32_PCADDU12I :
        inst_ld_w  ? `LoongArch32_LD_W  :
        inst_st_w  ? `LoongArch32_ST_W  :
        inst_ld_b  ? `LoongArch32_LD_B  :
        inst_st_b  ? `LoongArch32_ST_B  :
        inst_beq   ? `LoongArch32_BEQ   :
        inst_bne   ? `LoongArch32_BNE   :
        inst_bge   ? `LoongArch32_BGE   :
        inst_b     ? `LoongArch32_B     :
        inst_bl    ? `LoongArch32_BL    :
        inst_jirl  ? `LoongArch32_JIRL  : `NOP;
        
    // 2. alutype
    assign id_alutype_o = 
        (inst_add_w | inst_addi_w | inst_slt | inst_sltu | inst_slti | inst_sltui | inst_lu12i_w | inst_pcaddu12i) ? `ARITH :
        (inst_or | inst_ori | inst_xor | inst_andi | inst_and) ? `LOGIC :
        (inst_sra_w) ? `SHIFT :
        (inst_beq | inst_bne | inst_bge | inst_b | inst_bl | inst_jirl) ? `BRANCH :
        (inst_ld_w | inst_st_w | inst_ld_b | inst_st_b) ? `LOAD_STORE : `NOP;
    
    /*--------------------- Operand selection -------------------------*/
    
    // Immediate selection for src2
    wire src2_is_imm = inst_addi_w | inst_ld_b | inst_ld_w | inst_st_b | inst_st_w | 
                       inst_slt | inst_sltu | inst_slti | inst_sltui | inst_andi | inst_ori | inst_lu12i_w | inst_pcaddu12i | inst_jirl;

    // Sign extension control: andi/ori/sltui are zero-extended; others are sign-extended
    wire imm_sext = ~(inst_andi | inst_ori | inst_sltui);

    // Write enable: branches and stores do not write back to regfile
    // bl and jirl write return address to register, so they need write enable
    // b instruction does not write back (unconditional branch, no return address)
    assign id_wreg_o = ~(inst_beq | inst_bne | inst_bge | inst_b | inst_st_w | inst_st_b);

    // 目标寄存器地址 (Write Address)
    // 普通3R指令写入rd，2RI指令写入rd，BL指令写入r1，jirl写入rd
    assign id_wa_o = inst_bl ? 5'd1 : rd;  // bl writes to r1 (ra), jirl writes to rd

    // 读寄存器地址 (Read Address)
    // For jirl: ra1 should be rj (for jump target calculation), not PC
    // PC is used for return address calculation (id_src1_o), but rj value is needed for br_target
    assign ra1 = rj;
    // 对于Store和Branch指令需要将rd作为源操作数2
    // 对于立即数指令，ra2应该为0（不使用寄存器，源操作数2从立即数获取）
    // 对于3R指令，使用rk作为源操作数2
    wire is_store_or_branch = inst_st_w | inst_st_b | inst_beq | inst_bne | inst_bge;
    assign ra2 = is_store_or_branch ? rd :
                 (src2_is_imm) ? 5'b0 : rk;
    
    // Debug signal assignments
    assign debug_inst_st_b = inst_st_b;
    assign debug_rd = rd;
    assign debug_rj = rj;
    assign debug_rk = rk;
    assign debug_op_31_22 = op_31_22;
    assign debug_is_store_or_branch = is_store_or_branch;
    assign debug_src2_is_imm = src2_is_imm;
    assign debug_imm_ext = imm_ext;
    assign debug_rd1 = rd1;
    assign debug_rd2 = rd2;
    assign debug_ra1 = ra1;
    assign debug_ra2 = ra2;
    assign debug_exe_fwd_match = exe_fwd_match;
    assign debug_mem_fwd_match = mem_fwd_match;
    assign debug_wb_fwd_match = wb_fwd_match;

    /*--------------------- 立即数扩展 -------------------------*/
    
    // 立即数扩展
    wire [31:0] imm_ext;
    // 20位立即数: lu12i.w 使用非符号扩展 (参考 TEMU 实现)，pcaddu12i 使用符号扩展
    wire [31:0] imm20_sext = {{12{imm20[19]}}, imm20};

    // lu12i.w: rd = imm20 << 12
    // pcaddu12i: rd = PC + (sext(imm20) << 12)
    // jirl: src2 = SignExtend({offs16, 2'b0}, 32) for address calculation
    // 参考 TEMU 的 i20-type.c 中 pcaddu12i 的具体实现，以及自己查阅 ISA 规范
    assign imm_ext =
        inst_pcaddu12i ? (imm20_sext << 12) :
        inst_lu12i_w   ? {imm20, 12'b0} :
        inst_jirl      ? {{14{imm16[15]}}, imm16, 2'b00} :  // jirl offset: SignExtend({offs16, 2'b0}, 32)
        (imm_sext ? {{20{imm12[11]}}, imm12} : {20'b0, imm12});

    // 源操作数1
    // pcaddu12i 需要 PC 作为源操作数1
    // jirl 需要 rj 作为源操作数1 (for jump target calculation: GR[rj] + offset, handled in br_target)
    // jirl 也需要 PC 作为源操作数1 (for return address: PC + 4)
    // bl 需要 PC 作为源操作数1 (for return address: PC + 4)
    assign id_src1_o = (inst_pcaddu12i) ? id_pc_i : 
                        (inst_jirl) ? id_pc_i :  // jirl uses PC for return address calculation
                        (inst_bl) ? id_pc_i :  // bl uses PC for return address calculation
                        rd1;

    // 源操作数2
    // For bl: src2 should be 4 (PC+4 for return address)
    // For jirl: src2 should be 4 (PC+4 for return address)
    // For other instructions: use imm_ext or rd2
    assign id_src2_o = (inst_bl | inst_jirl) ? 32'd4 :  // bl/jirl: return address = PC + 4
                       (src2_is_imm ? imm_ext : rd2);

    
    /* ----------------------------------------------------
     * 分支跳转逻辑 和 Store数据透传
     * ---------------------------------------------------- */
     
    // 1. Store 数据透传 (将 rd2 的值直接传递到执行阶段)
    // 对于st.w/st.b指令，rd2是需要存储的数据，应该使用前递后的值
    // 前递优先级：EXE > MEM > WB > 原始值
    wire [`REG_BUS] rd2_fwd = 
        (exe_fwd_wreg && (exe_fwd_wa != 5'b0) && (exe_fwd_wa == ra2)) ? exe_fwd_wd :
        (mem_fwd_wreg && (mem_fwd_wa != 5'b0) && (mem_fwd_wa == ra2)) ? mem_fwd_wd :
        (wb_fwd_wreg  && (wb_fwd_wa  != 5'b0) && (wb_fwd_wa  == ra2)) ? wb_fwd_wd  :
        rd2;
    assign id_rk_d_o = rd2_fwd;

    // 2. 分支判断
    // 注意：LoongArch 的 BEQ/BNE/BGE 使用 rj 与 rd 作为比较源。
    // benchtest 中大量出现"上条指令刚写回，本条立刻分支比较"的模式，
    // 因此 ID 阶段需要具备 EXE/MEM/WB -> ID 的前递能力。

    wire [`REG_BUS] br_op1_raw = rd1;
    wire [`REG_BUS] br_op2_raw = rd2;

    // Forward priority: EXE (result just computed) > MEM (load result / ALU result) > WB
    wire exe_fwd_match = exe_fwd_wreg && (exe_fwd_wa != 5'b0) && (exe_fwd_wa == ra1);
    wire mem_fwd_match = mem_fwd_wreg && (mem_fwd_wa != 5'b0) && (mem_fwd_wa == ra1);
    wire wb_fwd_match  = wb_fwd_wreg  && (wb_fwd_wa  != 5'b0) && (wb_fwd_wa  == ra1);
    
    // Use explicit priority logic to ensure correct forwarding
    // Priority: EXE > MEM > WB > raw register read
    // Direct assignment to avoid X propagation issues
    // For jirl instruction, we need rj value (from rd1) with forwarding
    // Note: fwd_match already includes wreg check, so we don't need to check again
    wire [`REG_BUS] br_op1 = exe_fwd_match ? exe_fwd_wd :
                             mem_fwd_match ? mem_fwd_wd :
                             wb_fwd_match  ? wb_fwd_wd  :
                             br_op1_raw;

    wire [`REG_BUS] br_op2 =
        (exe_fwd_wreg && (exe_fwd_wa != 5'b0) && (exe_fwd_wa == ra2)) ? exe_fwd_wd :
        (mem_fwd_wreg && (mem_fwd_wa != 5'b0) && (mem_fwd_wa == ra2)) ? mem_fwd_wd :
        (wb_fwd_wreg  && (wb_fwd_wa  != 5'b0) && (wb_fwd_wa  == ra2)) ? wb_fwd_wd  :
        br_op2_raw;

    wire rj_eq_rd = (br_op1 == br_op2);                  // 相等
    wire rj_lt_rd = ($signed(br_op1) < $signed(br_op2)); // 小于 (有符号)

    // bge (大于等于) 等价于 !(小于)
    // b, bl and jirl are unconditional jumps
    assign br_taken = (inst_beq  &  rj_eq_rd) |
                      (inst_bne  & !rj_eq_rd) |
                      (inst_bge  & !rj_lt_rd) |
                      inst_b | inst_bl | inst_jirl;  // b, bl, jirl always jump

    // 3. 计算跳转目标
    // b: PC + SignExtend(offs26, 32) << 2, where offs26 = inst[25:10] (16-bit signed) - same as bl but no return address
    // bl: PC + SignExtend(offs26, 32) << 2, where offs26 = inst[25:10] (16-bit signed)
    // jirl: GR[rj] + SignExtend({offs16, 2'b0}, 32)
    // beq/bne/bge: PC + SignExtend({offs16, 2'b0}, 32)
    wire [15:0] bl_offs16 = inst[25:10];  // bl/b指令的16位立即数（指令偏移）
    wire [31:0] bl_offset = {{14{bl_offs16[15]}}, bl_offs16, 2'b00};  // SignExtend(offs16, 32) << 2
    wire [31:0] jirl_offset = {{14{imm16[15]}}, imm16, 2'b00};  // SignExtend({offs16, 2'b0}, 32)
    wire [31:0] branch_offset = {{14{imm16[15]}}, imm16, 2'b00};  // SignExtend({offs16, 2'b0}, 32)
    
    // For jirl, we need rj value (from rd1) for jump target calculation
    // br_op1 already has forwarding applied, so use it for jirl
    // b and bl use the same offset calculation
    assign br_target = (inst_b | inst_bl) ? (id_pc_i + bl_offset) :
                       inst_jirl ? (br_op1 + jirl_offset) :  // jirl uses rj (from rd1 with forwarding) + offset
                       (id_pc_i + branch_offset);
    
    // Debug signal assignments (after br_op1 and br_target are defined)
    assign debug_br_op1_raw = br_op1_raw;
    assign debug_br_op1 = br_op1;
    assign debug_br_target = br_target;
    assign debug_exe_fwd_wd = exe_fwd_wd;
    assign debug_mem_fwd_wd = mem_fwd_wd;
    assign debug_wb_fwd_wd = wb_fwd_wd;
    
    // ==========================================================
    // 流水线暂停Load-Use 冒险检测逻辑
    // ==========================================================
    
    // 1. 判断上一条指令 (正在执行 EXE 阶段) 是否是 Load
    wire pre_inst_is_load = (exe_aluop_i == `LoongArch32_LD_W) || 
                            (exe_aluop_i == `LoongArch32_LD_B);
    
    // 2. 判断是否有冲突
    // 只有当ID阶段指令确实需要读取对应源寄存器时，才参与load-use冒险判断。
    // 否则（例如NOP/不使用源寄存器的指令），可能出现stall_req被错误持续拉高导致前端永久停住。
    wire id_uses_ra1 = (ra1 != 5'b0);
    wire id_uses_ra2 = (ra2 != 5'b0);

    assign stall_req = pre_inst_is_load && exe_wreg_i && (exe_wa_i != 5'b0) &&
                       ((id_uses_ra1 && (exe_wa_i == ra1)) || (id_uses_ra2 && (exe_wa_i == ra2)));
    
endmodule
