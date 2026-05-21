`include "defines.v"

module id_stage(

    // 从取指阶段获得的PC值
    input  wire [`INST_ADDR_BUS]    id_pc_i,
    input  wire [`INST_ADDR_BUS]    id_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 从指令存储器读出的指令字
    input  wire [`INST_BUS     ]    id_inst_i,
    
    // 从通用寄存器堆读出的数据 
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,     
    
    // 【新增】来自 EXE 阶段的信息 (用于 Load-Use 检测)
    input  wire [`ALUOP_BUS    ]    exe_aluop_i,
    input  wire [`REG_ADDR_BUS ]    exe_wa_i,
    input  wire                     exe_wreg_i,
    
    // 【新增】暂停请求信号
    output wire                     stall_req,   
    
    // 送至执行阶段的译码信息
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire [`REG_ADDR_BUS ]    id_wa_o,
    output wire                     id_wreg_o,

    // 送至执行阶段的源操作数1、源操作数2
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
    
    // 【新增】Store 指令专用的数据输出 (原始 rd2)
    output wire [`REG_BUS       ]   id_rk_d_o,
    
    // 【新增】分支相关信号
    output wire                     br_taken,     // 分支是否跳转
    output wire [`INST_ADDR_BUS]    br_target,    // 跳转目标地址
    
    // 送至读通用寄存器堆端口地址
    output wire [`REG_ADDR_BUS ]    ra1,
    output wire [`REG_ADDR_BUS ]    ra2,
    
    output       [`INST_ADDR_BUS] 	debug_wb_pc  // 供调试使用的PC值，上板测试时务必删除该信号
    );
    
    // 根据小端模式组织指令字（COE文件是小端存储，inst_rom输出也是小端格式，需要字节交换）
    wire [`INST_BUS     ]    inst;
    assign inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};
    
    // 提取指令字中各个字段的信息
    /*
    //原本代码
    wire [16:0] op17  = inst[31:15];
    wire [4 :0] rd    = inst[4 : 0];
    wire [4 :0] rj    = inst[9 : 5];
    wire [11:0] imm12 = inst[21:10];
    
    // 涉及立即数判定的信号
    wire        id_immsel;
    wire        id_sext;
    */
    
    // 提取不同格式的指令码段
    // 注意：opcode字段可以从交换后的inst中提取，因为只用于指令识别
    wire [31:26] op_31_26 = inst[31:26];
    wire [31:22] op_31_22 = inst[31:22];
    wire [31:15] op_31_15 = inst[31:15];

    // 提取寄存器索引和立即数
    // 注意：由于字节交换，字段位置发生了变化
    // opcode识别使用inst（交换后的），所以字段也应该从inst中提取以保持一致性
    wire [4:0]  rd      = inst[4:0];
    wire [4:0]  rj      = inst[9:5];
    wire [4:0]  rk      = inst[14:10];
    wire [11:0] imm12   = inst[21:10];       // 12位立即数
    wire [15:0] imm16   = inst[25:10];       // 16位立即数 (分支用)
    wire [19:0] imm20   = inst[24:5];        // 20位立即数 (lu12i/pcaddu12i)

    /*-------------------- 第一级译码逻辑：确定当前需要译码的指令 --------------------*/
    // 以 andi.w 指令为例 其余指令需要自行完成
    //wire inst_andi  = ~|op17[16:11] & ~(~|op17[16:6]) &  op17[10] &  op17[9] & ~op17[8] &  op17[7];
    
    // 3R型 (3个寄存器)
    wire inst_add_w  = (op_31_15 == 17'h00020);
    wire inst_or     = (op_31_15 == 17'h0002a);
    wire inst_xor    = (op_31_15 == 17'h0002b); // 修复：XOR的opcode是0x0002b
    wire inst_sra_w  = (op_31_15 == 17'h00030); // 算术右移
    
    // 2RI12型 (2寄存器+12位立即数)
    wire inst_addi_w = (op_31_22 == 10'h00a);
    wire inst_ld_b   = (op_31_22 == 10'h0a0);
    wire inst_ld_w   = (op_31_22 == 10'h0a2);
    wire inst_st_b   = (op_31_22 == 10'h0a4);
    wire inst_st_w   = (op_31_22 == 10'h0a6);
    wire inst_andi   = (op_31_22 == 10'h00d);
    wire inst_ori    = (op_31_22 == 10'h00e);
    wire inst_sltui  = (op_31_22 == 10'h003); // 无符号比较
    
    // 1RI20型 (1寄存器+20位立即数)
    wire inst_lu12i_w    = (inst[31:25] == 7'h0a);
    wire inst_pcaddu12i  = (inst[31:25] == 7'h0e);

    // 分支指令 (Opcode 31:26)
    wire inst_beq    = (op_31_26 == 6'h16);
    wire inst_bne    = (op_31_26 == 6'h17);
    wire inst_bge    = (op_31_26 == 6'h19);
    
    /*--------------------- 第二级译码逻辑：生成具体控制信号 -------------------------*/
    // 操作类型alutype
    /*
    //原本代码
    assign id_alutype_o[2] = 1'b0;
    assign id_alutype_o[1] = inst_andi;
    assign id_alutype_o[0] = 1'b0; 
    
    // 内部操作码aluop
    assign id_aluop_o[7]   = 1'b0;
    assign id_aluop_o[6]   = 1'b0;
    assign id_aluop_o[5]   = 1'b0;
    assign id_aluop_o[4]   = inst_andi;
    assign id_aluop_o[3]   = inst_andi;
    assign id_aluop_o[2]   = inst_andi;
    assign id_aluop_o[1]   = 1'b0;
    assign id_aluop_o[0]   = 1'b0;
    
    // 写通用寄存器使能信号
    // assign id_wreg_o = inst_andi;  // 已注释：这是andi指令的旧代码，现在使用通用的id_wreg_o逻辑
    // 确定第二个操作数来源的信号（寄存器or立即数）
    assign id_immsel = inst_andi;
    // 对立即数进行符号扩展或者零扩展的信号
    assign id_sext   = 1'b0;

    // 读通用寄存器2个堆端口的地址确认
    assign ra1   = rj;
    assign ra2   = 5'b0;
    
    // 获得待写入目的寄存器的地址
    assign id_wa_o      = rd;
    
    // 获得位移后立即数，如果sext有效则符号拓展，如果sext无效则零拓展
    wire [31:0] imm32;
    assign imm32 = (id_sext  == `TRUE_V) ? ({ {20{imm12[11]} } , imm12}) : ({20'b0 , imm12});

    // 获得源操作数1。如果shift信号有效，则源操作数1为移位位数；否则为从读通用寄存器堆端口1获得的数据
    assign id_src1_o =  rd1;

    // 获得源操作数2。如果immsel信号有效，则源操作数1为立即数；否则为从读通用寄存器堆端口2获得的数据
    assign id_src2_o = (id_immsel == `READ_ENABLE) ? imm32 : rd2;           
    
    assign debug_wb_pc = id_debug_wb_pc;    // 上板测试时务必删除该语句 
    */
    
    // 1. 生成 aluop
    assign id_aluop_o = 
        inst_add_w ? `LoongArch32_ADD_W :
        inst_addi_w? `LoongArch32_ADDI_W:
        inst_or    ? `LoongArch32_OR    :
        inst_ori   ? `LoongArch32_ORI   :
        inst_xor   ? `LoongArch32_XOR   :
        inst_andi  ? `LoongArch32_ANDI  :
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
        inst_bge   ? `LoongArch32_BGE   : `NOP;
        
    // 2. 生成 alutype
    assign id_alutype_o = 
        (inst_add_w | inst_addi_w | inst_sltui | inst_lu12i_w | inst_pcaddu12i) ? `ARITH :
        (inst_or | inst_ori | inst_xor | inst_andi) ? `LOGIC :
        (inst_sra_w) ? `SHIFT :
        (inst_beq | inst_bne | inst_bge) ? `BRANCH :
        (inst_ld_w | inst_st_w | inst_ld_b | inst_st_b) ? `LOAD_STORE : `NOP;
    
    /*--------------------- 信号选择逻辑 -------------------------*/
    
    // 是否需要立即数 (Immediate Selection)
    // 算术/逻辑的立即数版本，以及Load/Store都需要立即数
    wire src2_is_imm = inst_addi_w | inst_ld_b | inst_ld_w | inst_st_b | inst_st_w | 
                       inst_sltui | inst_andi | inst_ori | inst_lu12i_w | inst_pcaddu12i;

    // 立即数符号扩展 (Sign Extension)
    // 逻辑指令(andi/ori)和sltui通常是零扩展，其他算术和访存是符号扩展
    wire imm_sext = ~(inst_andi | inst_ori | inst_sltui); // andi, ori, sltui 使用零扩展

    // 写回寄存器使能 (Write Enable)
    // 分支指令和Store指令不写回寄存器，其他都写回
    assign id_wreg_o = ~(inst_beq | inst_bne | inst_bge | inst_st_w | inst_st_b);

    // 目的寄存器地址 (Write Address)
    // 普通3R指令写到rd，2RI指令写到rd，BL指令(这里没涉及BL)写到r1
    assign id_wa_o = rd;

    // 读寄存器地址 (Read Address)
    assign ra1 = rj;
    // 如果是Store或Branch，需要读rd作为源操作数2；如果是3R指令，读rk
    assign ra2 = (inst_st_w | inst_st_b | inst_beq | inst_bne | inst_bge) ? rd : rk;

    /*--------------------- 操作数准备 -------------------------*/
    
    // 立即数生成
    wire [31:0] imm_ext;
    // 处理20位立即数 (lu12i, pcaddu12i) 和 12位立即数
    assign imm_ext = (inst_lu12i_w | inst_pcaddu12i) ? {imm20, 12'b0} :
                     (imm_sext ? {{20{imm12[11]}}, imm12} : {20'b0, imm12});

    // 源操作数1
    // pcaddu12i 需要 PC 作为源操作数1
    assign id_src1_o = (inst_pcaddu12i) ? id_pc_i : rd1;

    // 源操作数2
    assign id_src2_o = src2_is_imm ? imm_ext : rd2;

    assign debug_wb_pc = id_debug_wb_pc;      // 上板测试时务必删除该语句 
    
    /* ----------------------------------------------------
     * 【新增】分支跳转逻辑 与 Store数据透传
     * ---------------------------------------------------- */
     
    // 1. Store 数据透传 (将 rd2 的值直接传给后续阶段)
    assign id_rk_d_o = rd2;

    // 2. 分支判断
    wire [31:0] rj_eq_rd = (rd1 == rd2);                  // 相等
    wire [31:0] rj_lt_rd = ($signed(rd1) < $signed(rd2)); // 小于 (有符号)
    
    // bge (大于等于) 等价于 !(小于)
    assign br_taken = (inst_beq  &  rj_eq_rd) |
                      (inst_bne  & !rj_eq_rd) |
                      (inst_bge  & !rj_lt_rd);

    // 3. 计算跳转目标 (PC + offset)
    // 分支立即数是 imm16，需要符号扩展并左移2位
    wire [31:0] br_offset = {{14{imm16[15]}}, imm16, 2'b00};
    assign br_target = id_pc_i + br_offset;
    
    // ==========================================================
    // 【核心新增】Load-Use 冒险检测逻辑
    // ==========================================================
    
    // 1. 判断上一条指令 (现在在 EXE 阶段) 是否是 Load
    wire pre_inst_is_load = (exe_aluop_i == `LoongArch32_LD_W) || 
                            (exe_aluop_i == `LoongArch32_LD_B);
    
    // 2. 判断是否有冲突
    // 条件：(上一条是Load) && (上一条要写回) && (上一条写回地址 != 0) &&
    //       (上一条写回地址 == 当前指令源寄存器1 || 上一条写回地址 == 当前指令源寄存器2)
    assign stall_req = pre_inst_is_load && exe_wreg_i && (exe_wa_i != 5'b0) &&
                       ((exe_wa_i == ra1) || (exe_wa_i == ra2));
    
endmodule
