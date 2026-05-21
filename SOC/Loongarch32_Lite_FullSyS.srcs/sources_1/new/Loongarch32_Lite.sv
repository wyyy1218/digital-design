`include "defines.v"

module Loongarch32_Lite(
    input  wire                  cpu_clk_50M,
    input  wire                  cpu_rst_n,
    
    // inst_rom
    output wire [`INST_ADDR_BUS] iaddr,
    input  wire [`INST_BUS]      inst,
    
    // data_ram interface
    output wire                 mem_we,    
    output wire [`REG_BUS]      mem_addr,  
    output wire [`REG_BUS]      mem_wdata, 
    input  wire [`REG_BUS]      mem_rdata, 
    
    // stall IF from SoC when MEM accesses .text
    input  wire                  stall_if_from_soc,
    
    // Debug signals (for simulation only, remove for board build)
    output wire [`INST_ADDR_BUS] debug_wb_pc,        // WB stage PC
    output wire                  debug_wb_rf_wen,     // WB stage register write enable
    output wire [`REG_ADDR_BUS]  debug_wb_rf_wnum,    // WB stage register write number
    output wire [`REG_BUS]       debug_wb_rf_wdata,   // WB stage register write data
    output wire [`INST_ADDR_BUS] debug_if_pc,         // IF stage PC
    output wire [`INST_ADDR_BUS] debug_id_pc,         // ID stage PC
    output wire [`INST_ADDR_BUS] debug_exe_pc,        // EXE stage PC
    output wire [`INST_ADDR_BUS] debug_mem_pc,        // MEM stage PC
    output wire                  debug_stall,          // Pipeline stall signal
    output wire                  debug_br_taken,       // Branch taken signal
    
    // Forwarding debug signals
    output wire [`REG_ADDR_BUS] debug_exe_ra1,        // EXE stage source register 1
    output wire [`REG_ADDR_BUS] debug_exe_ra2,        // EXE stage source register 2
    output wire                  debug_forward_a_mem,  // Forward from MEM for src1
    output wire                  debug_forward_a_wb,   // Forward from WB for src1
    output wire [`REG_BUS]       debug_final_src1,     // Final source 1 value
    output wire [`REG_BUS]       debug_final_src2,     // Final source 2 value
    output wire [`REG_BUS]       debug_exe_src2_i,     // EXE stage source 2 (before forwarding)
    output wire                  debug_forward_b_mem,  // Forward from MEM for src2
    output wire                  debug_forward_b_wb,    // Forward from WB for src2
    output wire                  debug_mem_wreg_i,     // MEM stage write enable (for forwarding)
    output wire [`REG_ADDR_BUS]  debug_mem_wa_i,       // MEM stage write address (for forwarding)
    output wire [`REG_BUS]       debug_mem_wd_i,       // MEM stage write data (for forwarding)
    output wire                  debug_wb_wreg_i,       // WB stage write enable (for forwarding)
    output wire [`REG_ADDR_BUS]  debug_wb_wa_i,        // WB stage write address (for forwarding)
    output wire [`REG_BUS]       debug_wb_wd_i,        // WB stage write data (for forwarding)
    output wire [`REG_BUS]       debug_exe_src1_i,      // EXE stage source 1 (before forwarding)
    // Debug signals for exe_stage internal input values
    output wire                  debug_exe_wb_wreg_i_internal, // exe_stage internal wb_wreg_i
    output wire [`REG_ADDR_BUS]  debug_exe_wb_wa_i_internal,    // exe_stage internal wb_wa_i
    output wire [`REG_BUS]       debug_exe_wb_wd_i_internal,     // exe_stage internal wb_wd_i
    // Debug signals for forwarding condition calculations
    output wire                  debug_forward_a_wb_condition,     // forward_a_wb condition result
    output wire                  debug_forward_b_wb_condition,     // forward_b_wb condition result
    output wire                  debug_forward_a_mem_condition,    // forward_a_mem condition result
    output wire                  debug_forward_b_mem_condition,    // forward_b_mem condition result
    // Debug signals for forwarding condition components
    output wire                  debug_wb_wreg_i_value,             // wb_wreg_i value used in forwarding
    output wire [`REG_ADDR_BUS]  debug_wb_wa_i_value,              // wb_wa_i value used in forwarding
    output wire                  debug_wb_wa_i_not_zero,           // (wb_wa_i != 0) result
    output wire                  debug_wb_wa_i_eq_ra1,             // (wb_wa_i == exe_ra1_i) result
    output wire                  debug_wb_wa_i_eq_ra2,             // (wb_wa_i == exe_ra2_i) result
    output wire                  debug_mem_wreg_i_value,            // mem_wreg_i value used in forwarding
    output wire [`REG_ADDR_BUS]  debug_mem_wa_i_value,             // mem_wa_i value used in forwarding
    output wire                  debug_mem_wa_i_not_zero,          // (mem_wa_i != 0) result
    output wire                  debug_mem_wa_i_eq_ra1,            // (mem_wa_i == exe_ra1_i) result
    output wire                  debug_mem_wa_i_eq_ra2,            // (mem_wa_i == exe_ra2_i) result
    output wire [`REG_ADDR_BUS]  debug_exe_ra1_i_value,            // exe_ra1_i value
    output wire [`REG_ADDR_BUS]  debug_exe_ra2_i_value,            // exe_ra2_i value
    // Detailed debug signals for forward_a_mem calculation
    output wire                  debug_forward_a_mem_calc_mem_wreg_i,  // mem_wreg_i value used in forward_a_mem calculation
    output wire [`REG_ADDR_BUS]  debug_forward_a_mem_calc_mem_wa_i,    // mem_wa_i value used in forward_a_mem calculation
    output wire                  debug_forward_a_mem_calc_mem_wa_i_not_zero, // (mem_wa_i != 0) result in forward_a_mem calculation
    output wire [`REG_ADDR_BUS]  debug_forward_a_mem_calc_exe_ra1_i,   // exe_ra1_i value used in forward_a_mem calculation
    output wire                  debug_forward_a_mem_calc_mem_wa_i_eq_ra1,   // (mem_wa_i == exe_ra1_i) result in forward_a_mem calculation
    output wire                  debug_forward_a_mem_calc_result,       // forward_a_mem calculation result
    output wire [`REG_ADDR_BUS]  debug_mem_wa_i_at_assign,             // mem_wa_i value at assign debug_mem_wa_i
    output wire [`REG_ADDR_BUS]  debug_mem_wa_i_at_forward_calc,       // mem_wa_i value at forward_a_mem calculation
    // MEM and WB stage debug signals for forwarding analysis
    output wire                  debug_mem_wreg,       // MEM stage write enable
    output wire [`REG_ADDR_BUS]  debug_mem_wa,         // MEM stage write address
    output wire [`REG_BUS]       debug_mem_wd,         // MEM stage write data
    output wire                  debug_wb_wreg,       // WB stage write enable
    output wire [`REG_ADDR_BUS]  debug_wb_wa,         // WB stage write address
    output wire [`REG_BUS]       debug_wb_wd,         // WB stage write data
    // MEMWB_REG debug signals (memwb_reg input and output)
    output wire                  debug_memwb_wreg,    // memwb_reg write enable output
    output wire [`REG_ADDR_BUS]  debug_memwb_wa,      // memwb_reg write address output
    output wire [`REG_BUS]       debug_memwb_wd,      // memwb_reg write data output
    output wire                  debug_memwb_wreg_in, // memwb_reg write enable input (from MEM stage)
    output wire [`REG_ADDR_BUS]  debug_memwb_wa_in,   // memwb_reg write address input (from MEM stage)
    output wire [`REG_BUS]       debug_memwb_wd_in,   // memwb_reg write data input (from MEM stage)
    // EXEMEM_REG debug signals (exemem_reg input and output)
    output wire                  debug_exemem_wreg,    // exemem_reg write enable output
    output wire [`REG_ADDR_BUS]  debug_exemem_wa,      // exemem_reg write address output
    output wire [`REG_BUS]       debug_exemem_wd,      // exemem_reg write data output
    output wire                  debug_exemem_wreg_in, // exemem_reg write enable input (from EXE stage)
    output wire [`REG_ADDR_BUS]  debug_exemem_wa_in,   // exemem_reg write address input (from EXE stage)
    output wire [`REG_BUS]       debug_exemem_wd_in,   // exemem_reg write data input (from EXE stage)
    // EXEMEM_REG output to EXE_STAGE debug signals (for forwarding)
    output wire                  debug_exemem_to_exe_wreg, // exemem_reg output mem_wreg_i (passed to exe_stage)
    output wire [`REG_ADDR_BUS]  debug_exemem_to_exe_wa,   // exemem_reg output mem_wa_i (passed to exe_stage)
    output wire [`REG_BUS]       debug_exemem_to_exe_wd,    // exemem_reg output mem_wd_i (passed to exe_stage)
    // Signal trace debug signals for mem_wa_i
    output wire [`REG_ADDR_BUS]  debug_exemem_reg_mem_wa,  // exemem_reg module output mem_wa (from exemem_reg instance)
    output wire [`REG_ADDR_BUS]  debug_mem_wa_i_wire,      // mem_wa_i wire value (before connecting to exe_stage)
    output wire [`REG_ADDR_BUS]  debug_exe_stage_mem_wa_i, // exe_stage sees mem_wa_i value (from exe_stage debug output)
    // Delayed memwb_reg debug signals (for forwarding)
    output wire                  debug_wb_wreg_i_delayed, // delayed wb_wreg_i (used in forwarding)
    output wire [`REG_ADDR_BUS]  debug_wb_wa_i_delayed,  // delayed wb_wa_i (used in forwarding)
    output wire [`REG_BUS]       debug_wb_wd_i_delayed,  // delayed wb_dreg_i (used in forwarding)
    // IDEXE_REG debug signals (idexe_reg input and output for ra1/ra2)
    output wire [`REG_ADDR_BUS]  debug_idexe_ra1_in,  // idexe_reg ra1 input (from ID stage)
    output wire [`REG_ADDR_BUS]  debug_idexe_ra2_in,  // idexe_reg ra2 input (from ID stage)
    output wire [`REG_ADDR_BUS]  debug_idexe_ra1_out, // idexe_reg ra1 output (to EXE stage)
    output wire [`REG_ADDR_BUS]  debug_idexe_ra2_out, // idexe_reg ra2 output (to EXE stage)
    // Debug signals for values passed to exe_stage
    output wire                  debug_exe_wb_wreg_i, // WB write enable passed to exe_stage
    output wire [`REG_ADDR_BUS]  debug_exe_wb_wa_i,   // WB write address passed to exe_stage
    output wire [`REG_BUS]       debug_exe_wb_wd_i,   // WB write data passed to exe_stage
    // ID stage instruction decode debug signals
    output wire                  debug_id_inst_st_b,  // ID stage inst_st_b signal
    output wire [4:0]            debug_id_rd,        // ID stage rd field
    output wire [4:0]            debug_id_rj,        // ID stage rj field
    output wire [4:0]            debug_id_rk,        // ID stage rk field
    output wire [9:0]            debug_id_op_31_22,  // ID stage op_31_22 field
    output wire                  debug_id_is_store_or_branch, // ID stage is_store_or_branch signal
    output wire                  debug_id_src2_is_imm, // ID stage src2_is_imm signal
    // Additional ID stage debug signals
    output wire [31:0]           debug_id_imm_ext,     // ID stage immediate extension
    output wire [31:0]           debug_id_rd1,         // ID stage rd1 (register read 1)
    output wire [31:0]           debug_id_rd2,         // ID stage rd2 (register read 2)
    output wire [31:0]           debug_id_br_op1,      // ID stage br_op1 (with forwarding)
    output wire [31:0]           debug_id_br_target,   // ID stage br_target
    output wire [4:0]            debug_id_ra1,         // ID stage ra1 (for forwarding check)
    output wire [4:0]            debug_id_ra2,        // ID stage ra2 (for forwarding check)
    output wire [31:0]           debug_id_br_op1_raw,  // ID stage br_op1_raw (before forwarding)
    output wire                  debug_id_exe_fwd_match, // ID stage EXE forwarding match
    output wire                  debug_id_mem_fwd_match, // ID stage MEM forwarding match
    output wire                  debug_id_wb_fwd_match, // ID stage WB forwarding match
    output wire [31:0]           debug_id_exe_fwd_wd,   // ID stage EXE forwarding data
    output wire [31:0]           debug_id_mem_fwd_wd,   // ID stage MEM forwarding data
    output wire [31:0]           debug_id_wb_fwd_wd,    // ID stage WB forwarding data
    // Store data debug signals
    output wire [`REG_BUS]       debug_exe_rk_d_o,     // EXE stage store data output
    output wire [`REG_BUS]       debug_exe_rk_d_i,     // EXE stage store data input (from ID)
    output wire [`REG_BUS]       debug_id_rk_d_o       // ID stage store data output (with forwarding)
    );
    // IF/ID pipeline: IF stage to ID stage
    wire [`WORD_BUS      ] pc;
     
    wire [`WORD_BUS      ] id_pc_i;
    wire [`INST_BUS      ] id_inst_i;
    
    // ID stage + regfile
    wire [`REG_ADDR_BUS  ] ra1;
    wire [`REG_BUS       ] rd1;
    wire [`REG_ADDR_BUS  ] ra2;
    wire [`REG_BUS       ] rd2;
    
    // ID/EXE pipeline: ID stage to EXE stage
    wire [`ALUOP_BUS     ] id_aluop_o;
    wire [`ALUTYPE_BUS   ] id_alutype_o;
    wire [`REG_BUS 	     ] id_src1_o;
    wire [`REG_BUS 	     ] id_src2_o;
    wire 				   id_wreg_o;
    wire [`REG_ADDR_BUS  ] id_wa_o;
    wire [`ALUOP_BUS     ] exe_aluop_i;
    wire [`ALUTYPE_BUS   ] exe_alutype_i;
    wire [`REG_BUS 	     ] exe_src1_i;
    wire [`REG_BUS 	     ] exe_src2_i;
    wire 				   exe_wreg_i;
    wire [`REG_ADDR_BUS  ] exe_wa_i;
    
    // EXE/MEM pipeline: EXE stage to MEM stage
    wire [`ALUOP_BUS     ] exe_aluop_o;
    wire 				   exe_wreg_o;
    wire [`REG_ADDR_BUS  ] exe_wa_o;
    wire [`REG_BUS 	     ] exe_wd_o;
    wire [`ALUOP_BUS     ] mem_aluop_i;
    wire 				   mem_wreg_i;
    wire [`REG_ADDR_BUS  ] mem_wa_i;
    wire [`REG_BUS 	     ] mem_wd_i;
    
    // MEM/WB pipeline: MEM stage to WB stage
    wire 				   mem_wreg_o;
    wire [`REG_ADDR_BUS  ] mem_wa_o;
    wire [`REG_BUS 	     ] mem_dreg_o;
    wire 				   wb_wreg_i;
    wire [`REG_ADDR_BUS  ] wb_wa_i;
    wire [`REG_BUS       ] wb_dreg_i;
    
    // WB stage + regfile write-back
    wire 				   wb_wreg_o;
    wire [`REG_ADDR_BUS  ] wb_wa_o;
    wire [`REG_BUS       ] wb_wd_o;
    
    // Store data path
    wire [`REG_BUS       ] id_rk_d;
    wire [`REG_BUS       ] exe_rk_d;       // ID/EXE pipeline
    
    // Delayed memwb_reg output for forwarding (one cycle delay)
    // This is needed because forwarding logic needs the previous cycle's memwb_reg output
    // In Cycle N, memwb_reg updates to Cycle N-1's MEM stage value, but forwarding needs Cycle N-1's memwb_reg output
    reg [`REG_ADDR_BUS] wb_wa_i_delayed;
    reg                 wb_wreg_i_delayed;
    reg [`REG_BUS]      wb_dreg_i_delayed;
    wire [`REG_BUS       ] exe_rk_d_out;   // EXE stage store data
    wire [`REG_BUS       ] mem_rk_d;       // EXE/MEM pipeline
    wire [`REG_BUS       ] ram_wdata;      // data written to RAM in MEM stage
    
    // register source addrs passed to EXE for forwarding logic
    wire [`REG_ADDR_BUS  ] exe_ra1;
    wire [`REG_ADDR_BUS  ] exe_ra2;
    // branch signals
    wire                   br_taken;
    wire [`INST_ADDR_BUS]  br_target;
    
    // Debug signals from exe_stage (internal wires)
    wire                   exe_debug_exe_wb_wreg_i_internal;
    wire [`REG_ADDR_BUS]   exe_debug_exe_wb_wa_i_internal;
    wire [`REG_BUS]        exe_debug_exe_wb_wd_i_internal;
    wire                   exe_debug_forward_a_wb_condition;
    wire                   exe_debug_forward_b_wb_condition;
    wire                   exe_debug_forward_a_mem_condition;
    wire                   exe_debug_forward_b_mem_condition;
    wire                   exe_debug_wb_wreg_i_value;
    wire [`REG_ADDR_BUS]   exe_debug_wb_wa_i_value;
    wire                   exe_debug_wb_wa_i_not_zero;
    wire                   exe_debug_wb_wa_i_eq_ra1;
    wire                   exe_debug_wb_wa_i_eq_ra2;
    wire                   exe_debug_mem_wreg_i_value;
    wire [`REG_ADDR_BUS]   exe_debug_mem_wa_i;
    wire [`REG_ADDR_BUS]   exe_debug_mem_wa_i_value;
    wire                   exe_debug_mem_wa_i_not_zero;
    wire                   exe_debug_mem_wa_i_eq_ra1;
    wire                   exe_debug_mem_wa_i_eq_ra2;
    wire [`REG_ADDR_BUS]   exe_debug_exe_ra1_i_value;
    wire [`REG_ADDR_BUS]   exe_debug_exe_ra2_i_value;
    // Detailed debug signals for forward_a_mem calculation
    wire                   exe_debug_forward_a_mem_calc_mem_wreg_i;
    wire [`REG_ADDR_BUS]   exe_debug_forward_a_mem_calc_mem_wa_i;
    wire                   exe_debug_forward_a_mem_calc_mem_wa_i_not_zero;
    wire [`REG_ADDR_BUS]   exe_debug_forward_a_mem_calc_exe_ra1_i;
    wire                   exe_debug_forward_a_mem_calc_mem_wa_i_eq_ra1;
    wire                   exe_debug_forward_a_mem_calc_result;
    wire [`REG_ADDR_BUS]   exe_debug_mem_wa_i_at_assign;
    wire [`REG_ADDR_BUS]   exe_debug_mem_wa_i_at_forward_calc;
    
    // PC propagation through pipeline stages (for debug)
    wire [`INST_ADDR_BUS] exe_pc_i;
    wire [`INST_ADDR_BUS] mem_pc_i;
    wire [`INST_ADDR_BUS] wb_pc_i;
    
    // debug PC through pipeline (removed for board build)
    wire stall_req;

    // IMPORTANT:
    // - stall_ifid: freeze IF/ID (and PC) when there is a load-use hazard OR SoC requests IF stall
    // - flush_idexe: insert a bubble (NOP) into EXE when stalling, to prevent re-issuing the same ID instruction
    wire stall_ifid   = stall_req | stall_if_from_soc;
    wire flush_idexe  = stall_req | stall_if_from_soc;

    if_stage if_stage0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .pc(pc), .iaddr(iaddr),
        .br_taken(br_taken),   
        .br_target(br_target),
        
        .stall(stall_ifid)
    );
    
    ifid_reg ifid_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .inst(inst), .if_pc(pc),
        .id_inst(id_inst_i), .id_pc(id_pc_i),
        .stall(stall_ifid),
        // flush IF/ID when branch taken
        .flush(br_taken)
    );

    // Debug signals from id_stage (internal wires with different names)
    wire id_debug_inst_st_b;
    wire [4:0] id_debug_rd;
    wire [4:0] id_debug_rj;
    wire [4:0] id_debug_rk;
    wire [9:0] id_debug_op_31_22;
    wire id_debug_is_store_or_branch;
    wire id_debug_src2_is_imm;
    wire [31:0] id_debug_imm_ext;
    wire [31:0] id_debug_rd1;
    wire [31:0] id_debug_rd2;
    wire [31:0] id_debug_br_op1;
    wire [31:0] id_debug_br_target;
    wire [4:0]  id_debug_ra1;
    wire [4:0]  id_debug_ra2;
    wire [31:0] id_debug_br_op1_raw;
    wire        id_debug_exe_fwd_match;
    wire        id_debug_mem_fwd_match;
    wire        id_debug_wb_fwd_match;
    wire [31:0] id_debug_exe_fwd_wd;
    wire [31:0] id_debug_mem_fwd_wd;
    wire [31:0] id_debug_wb_fwd_wd;
    
    id_stage id_stage0(.id_pc_i(id_pc_i),
        // Forwarding inputs for branch compare (EXE/MEM/WB -> ID)
        .exe_fwd_wreg(exe_wreg_o),
        .exe_fwd_wa(exe_wa_o),
        .exe_fwd_wd(exe_wd_o),
        .mem_fwd_wreg(mem_wreg_o),
        .mem_fwd_wa(mem_wa_o),
        .mem_fwd_wd(mem_dreg_o),
        .wb_fwd_wreg(wb_wreg_o),
        .wb_fwd_wa(wb_wa_o),
        .wb_fwd_wd(wb_wd_o),

        .id_inst_i(id_inst_i),
        .rd1(rd1), .rd2(rd2),
        .ra1(ra1), .ra2(ra2),
        .id_aluop_o(id_aluop_o), .id_alutype_o(id_alutype_o),
        .id_src1_o(id_src1_o), .id_src2_o(id_src2_o),
        .id_wa_o(id_wa_o), .id_wreg_o(id_wreg_o),

        .id_rk_d_o(id_rk_d),
        .br_taken(br_taken),
        .br_target(br_target),
        // Load-Use hazard needs EXE-stage information
        .exe_aluop_i(exe_aluop_i),
        .exe_wa_i(exe_wa_i),
        .exe_wreg_i(exe_wreg_i),
        .stall_req(stall_req),
        // Debug signals
        .debug_inst_st_b(id_debug_inst_st_b),
        .debug_rd(id_debug_rd),
        .debug_rj(id_debug_rj),
        .debug_rk(id_debug_rk),
        .debug_op_31_22(id_debug_op_31_22),
        .debug_is_store_or_branch(id_debug_is_store_or_branch),
        .debug_src2_is_imm(id_debug_src2_is_imm),
        .debug_imm_ext(id_debug_imm_ext),
        .debug_rd1(id_debug_rd1),
        .debug_rd2(id_debug_rd2),
        .debug_br_op1(id_debug_br_op1),
        .debug_br_target(id_debug_br_target),
        .debug_ra1(id_debug_ra1),
        .debug_ra2(id_debug_ra2),
        .debug_br_op1_raw(id_debug_br_op1_raw),
        .debug_exe_fwd_match(id_debug_exe_fwd_match),
        .debug_mem_fwd_match(id_debug_mem_fwd_match),
        .debug_wb_fwd_match(id_debug_wb_fwd_match),
        .debug_exe_fwd_wd(id_debug_exe_fwd_wd),
        .debug_mem_fwd_wd(id_debug_mem_fwd_wd),
        .debug_wb_fwd_wd(id_debug_wb_fwd_wd)
    );
    
    regfile regfile0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .we(wb_wreg_o), .wa(wb_wa_o), .wd(wb_wd_o),
        .ra1(ra1), .rd1(rd1),
        .ra2(ra2), .rd2(rd2)
    );
    
    // PC propagation: ID -> EXE
    reg [`INST_ADDR_BUS] exe_pc;
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE || flush_idexe) begin
            exe_pc <= `PC_INIT;
        end else begin
            exe_pc <= id_pc_i;
        end
    end
    assign exe_pc_i = exe_pc;
    
    idexe_reg idexe_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n), 
        .id_alutype(id_alutype_o), .id_aluop(id_aluop_o),
        .id_src1(id_src1_o), .id_src2(id_src2_o),
        .id_wa(id_wa_o), .id_wreg(id_wreg_o),
        .exe_alutype(exe_alutype_i), .exe_aluop(exe_aluop_i),
        .exe_src1(exe_src1_i), .exe_src2(exe_src2_i), 
        .exe_wa(exe_wa_i), .exe_wreg(exe_wreg_i),
        
        .id_rk_d(id_rk_d),
        .exe_rk_d(exe_rk_d),
        .id_ra1(ra1),  // pass ID-stage ra1 to EXE
        .id_ra2(ra2),  // pass ID-stage ra2 to EXE
        .exe_ra1(exe_ra1),
        .exe_ra2(exe_ra2),
        .next_stall(flush_idexe)  // when stall asserted, flush ID/EXE (insert NOP)
    );
    
    exe_stage exe_stage0(
        .exe_alutype_i(exe_alutype_i), .exe_aluop_i(exe_aluop_i),
        .exe_src1_i(exe_src1_i), .exe_src2_i(exe_src2_i),
        .exe_wa_i(exe_wa_i), .exe_wreg_i(exe_wreg_i),
        .exe_aluop_o(exe_aluop_o),
        .exe_wa_o(exe_wa_o), .exe_wreg_o(exe_wreg_o), .exe_wd_o(exe_wd_o),
        
        
        .exe_ra1_i(exe_ra1),
        .exe_ra2_i(exe_ra2),
        .exe_rk_d_i(exe_rk_d),
        .exe_rk_d_o(exe_rk_d_out),  // store data
        
        // MEM-stage information for forwarding
        // Use exemem_reg output (current cycle MEM stage input) instead of mem_stage output
        // This ensures forwarding uses the correct timing: EXE stage output from previous cycle
        .mem_wreg_i(mem_wreg_i),  // exemem_reg output (current cycle MEM stage input)
        .mem_wa_i(mem_wa_i),      // exemem_reg output (current cycle MEM stage input)
        .mem_wd_i(mem_wd_i),      // exemem_reg output (current cycle MEM stage input, i.e., EXE stage output)
        
        // WB-stage information for forwarding
        .wb_wreg_i(wb_wreg_o),
        .wb_wa_i(wb_wa_o),
        .wb_wd_i(wb_wd_o),
        
        // Debug signals for forwarding
        .debug_exe_ra1(debug_exe_ra1),
        .debug_exe_ra2(debug_exe_ra2),
        .debug_forward_a_mem(debug_forward_a_mem),
        .debug_forward_a_wb(debug_forward_a_wb),
        .debug_forward_b_mem(debug_forward_b_mem),
        .debug_forward_b_wb(debug_forward_b_wb),
        .debug_final_src1(debug_final_src1),
        .debug_final_src2(debug_final_src2),
        .debug_exe_src2_i(debug_exe_src2_i),
        .debug_mem_wreg_i(debug_mem_wreg_i),
        .debug_mem_wa_i(exe_debug_mem_wa_i),
        .debug_mem_wd_i(debug_mem_wd_i),
        .debug_wb_wreg_i(debug_wb_wreg_i),
        .debug_wb_wa_i(debug_wb_wa_i),
        .debug_wb_wd_i(debug_wb_wd_i),
        .debug_exe_src1_i(debug_exe_src1_i),
        .debug_exe_wb_wreg_i_internal(exe_debug_exe_wb_wreg_i_internal),
        .debug_exe_wb_wa_i_internal(exe_debug_exe_wb_wa_i_internal),
        .debug_exe_wb_wd_i_internal(exe_debug_exe_wb_wd_i_internal),
        .debug_forward_a_wb_condition(exe_debug_forward_a_wb_condition),
        .debug_forward_b_wb_condition(exe_debug_forward_b_wb_condition),
        .debug_forward_a_mem_condition(exe_debug_forward_a_mem_condition),
        .debug_forward_b_mem_condition(exe_debug_forward_b_mem_condition),
        .debug_wb_wreg_i_value(exe_debug_wb_wreg_i_value),
        .debug_wb_wa_i_value(exe_debug_wb_wa_i_value),
        .debug_wb_wa_i_not_zero(exe_debug_wb_wa_i_not_zero),
        .debug_wb_wa_i_eq_ra1(exe_debug_wb_wa_i_eq_ra1),
        .debug_wb_wa_i_eq_ra2(exe_debug_wb_wa_i_eq_ra2),
        .debug_mem_wreg_i_value(exe_debug_mem_wreg_i_value),
        .debug_mem_wa_i_value(exe_debug_mem_wa_i_value),
        .debug_mem_wa_i_not_zero(exe_debug_mem_wa_i_not_zero),
        .debug_mem_wa_i_eq_ra1(exe_debug_mem_wa_i_eq_ra1),
        .debug_mem_wa_i_eq_ra2(exe_debug_mem_wa_i_eq_ra2),
        .debug_exe_ra1_i_value(exe_debug_exe_ra1_i_value),
        .debug_exe_ra2_i_value(exe_debug_exe_ra2_i_value),
        .debug_forward_a_mem_calc_mem_wreg_i(exe_debug_forward_a_mem_calc_mem_wreg_i),
        .debug_forward_a_mem_calc_mem_wa_i(exe_debug_forward_a_mem_calc_mem_wa_i),
        .debug_forward_a_mem_calc_mem_wa_i_not_zero(exe_debug_forward_a_mem_calc_mem_wa_i_not_zero),
        .debug_forward_a_mem_calc_exe_ra1_i(exe_debug_forward_a_mem_calc_exe_ra1_i),
        .debug_forward_a_mem_calc_mem_wa_i_eq_ra1(exe_debug_forward_a_mem_calc_mem_wa_i_eq_ra1),
        .debug_forward_a_mem_calc_result(exe_debug_forward_a_mem_calc_result),
        .debug_mem_wa_i_at_assign(exe_debug_mem_wa_i_at_assign),
        .debug_mem_wa_i_at_forward_calc(exe_debug_mem_wa_i_at_forward_calc)
    );
        
    // PC propagation: EXE -> MEM
    reg [`INST_ADDR_BUS] mem_pc;
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            mem_pc <= `PC_INIT;
        end else begin
            mem_pc <= exe_pc_i;
        end
    end
    assign mem_pc_i = mem_pc;
    
    exemem_reg exemem_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .exe_aluop(exe_aluop_o),
        .exe_wa(exe_wa_o), .exe_wreg(exe_wreg_o), .exe_wd(exe_wd_o),
        .mem_aluop(mem_aluop_i),
        .mem_wa(mem_wa_i), .mem_wreg(mem_wreg_i), .mem_wd(mem_wd_i),
        // exe_stage output store data
        .exe_rk_d(exe_rk_d_out),
        .mem_rk_d(mem_rk_d)
    );

    mem_stage mem_stage0(.mem_aluop_i(mem_aluop_i),
        .mem_wa_i(mem_wa_i), .mem_wreg_i(mem_wreg_i), .mem_wd_i(mem_wd_i),
        .mem_addr_i(mem_addr),  // Pass memory address for byte selection
        .mem_wa_o(mem_wa_o), .mem_wreg_o(mem_wreg_o), .mem_dreg_o(mem_dreg_o),
        
        .mem_rk_d_i(mem_rk_d),
        .mem_rdata_i(mem_rdata), // RAM read data
        .ram_wdata_o(ram_wdata)  // RAM write data
    );
    	
    // PC propagation: MEM -> WB
    reg [`INST_ADDR_BUS] wb_pc;
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            wb_pc <= `PC_INIT;
        end else begin
            wb_pc <= mem_pc_i;
        end
    end
    assign wb_pc_i = wb_pc;
    
    memwb_reg memwb_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .mem_wa(mem_wa_o), .mem_wreg(mem_wreg_o), .mem_dreg(mem_dreg_o),
        .wb_wa(wb_wa_i), .wb_wreg(wb_wreg_i), .wb_dreg(wb_dreg_i)
    );
    
    // Update delayed wb_stage output for forwarding
    // Use wb_stage output (wb_wa_o, wb_wreg_o, wb_wd_o) instead of memwb_reg output
    // This ensures the delayed register contains the previous cycle's WB stage output
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            wb_wa_i_delayed   <= `REG_NOP;
            wb_wreg_i_delayed <= `WRITE_DISABLE;
            wb_dreg_i_delayed <= `ZERO_WORD;
        end else begin
            wb_wa_i_delayed   <= wb_wa_o;
            wb_wreg_i_delayed <= wb_wreg_o;
            wb_dreg_i_delayed <= wb_wd_o;
        end
    end

    wb_stage wb_stage0(
        .wb_wa_i(wb_wa_i), .wb_wreg_i(wb_wreg_i), .wb_dreg_i(wb_dreg_i),
        .wb_wa_o(wb_wa_o), .wb_wreg_o(wb_wreg_o), .wb_wd_o(wb_wd_o)
    );
    
    // ==========================================================
    
    // ==========================================================
    
    // 1. Memory write enable: valid when instruction is ST.W or ST.B
    assign mem_we = (mem_aluop_i == `LoongArch32_ST_W) || (mem_aluop_i == `LoongArch32_ST_B);

    // 2. Memory address: ALU result (mem_wd_i)
    assign mem_addr = mem_wd_i;

    // 3. Memory write data:
    assign mem_wdata = ram_wdata;
    
    // ==========================================================
    // Debug signal assignments
    // ==========================================================
    assign debug_wb_pc      = wb_pc_i;
    assign debug_wb_rf_wen  = wb_wreg_o;
    assign debug_wb_rf_wnum = wb_wa_o;
    assign debug_wb_rf_wdata = wb_wd_o;
    assign debug_if_pc      = pc;
    assign debug_id_pc      = id_pc_i;
    assign debug_exe_pc     = exe_pc_i;
    assign debug_mem_pc      = mem_pc_i;
    assign debug_stall       = stall_ifid;
    assign debug_br_taken    = br_taken;
    
    // Forwarding debug signals
    assign debug_mem_wreg   = mem_wreg_o;
    assign debug_mem_wa     = mem_wa_o;
    assign debug_mem_wd     = mem_dreg_o;
    assign debug_wb_wreg    = wb_wreg_o;
    assign debug_wb_wa      = wb_wa_o;
    assign debug_wb_wd      = wb_wd_o;
    
    // MEMWB_REG debug signals (memwb_reg input and output)
    assign debug_memwb_wreg = wb_wreg_i;  // memwb_reg 的输出
    assign debug_memwb_wa   = wb_wa_i;
    assign debug_memwb_wd   = wb_dreg_i;
    assign debug_memwb_wreg_in = mem_wreg_o;  // memwb_reg 的输入（来自 MEM 阶段）
    assign debug_memwb_wa_in   = mem_wa_o;
    assign debug_memwb_wd_in   = mem_dreg_o;
    // EXEMEM_REG debug signals (exemem_reg input and output)
    assign debug_exemem_wreg = mem_wreg_i;  // exemem_reg 的输出
    assign debug_exemem_wa   = mem_wa_i;
    assign debug_exemem_wd   = mem_wd_i;
    assign debug_exemem_wreg_in = exe_wreg_o;  // exemem_reg 的输入（来自 EXE 阶段）
    assign debug_exemem_wa_in   = exe_wa_o;
    assign debug_exemem_wd_in   = exe_wd_o;
    // EXEMEM_REG output to EXE_STAGE debug signals (for forwarding)
    assign debug_exemem_to_exe_wreg = mem_wreg_i;  // exemem_reg 输出传递给 exe_stage 的 mem_wreg_i
    assign debug_exemem_to_exe_wa   = mem_wa_i;    // exemem_reg 输出传递给 exe_stage 的 mem_wa_i
    assign debug_exemem_to_exe_wd   = mem_wd_i;    // exemem_reg 输出传递给 exe_stage 的 mem_wd_i
    // Signal trace debug signals for mem_wa_i
    // Note: exemem_reg output mem_wa is directly connected to mem_wa_i wire
    assign debug_exemem_reg_mem_wa  = mem_wa_i;     // exemem_reg module output mem_wa (same as mem_wa_i since directly connected)
    assign debug_mem_wa_i_wire      = mem_wa_i;     // mem_wa_i wire value
    assign debug_exe_stage_mem_wa_i = exe_debug_mem_wa_i; // exe_stage sees mem_wa_i value (from exe_stage debug output)
    assign debug_mem_wa_i = exe_debug_mem_wa_i;     // Connect exe_stage debug output to module output port
    // IDEXE_REG debug signals (idexe_reg input and output for ra1/ra2)
    assign debug_idexe_ra1_in  = ra1;      // idexe_reg 的输入（来自 ID 阶段）
    assign debug_idexe_ra2_in  = ra2;
    assign debug_idexe_ra1_out = exe_ra1;  // idexe_reg 的输出（传递给 EXE 阶段）
    assign debug_idexe_ra2_out = exe_ra2;
    
    // Debug signals for values passed to exe_stage
    // Use delayed register values since forwarding logic uses delayed registers
    assign debug_exe_wb_wreg_i = wb_wreg_i_delayed;  // 传递给 exe_stage 的值（延迟寄存器）
    assign debug_exe_wb_wa_i   = wb_wa_i_delayed;
    assign debug_exe_wb_wd_i   = wb_dreg_i_delayed;
    
    // Debug signals for forwarding condition calculations
    assign debug_forward_a_wb_condition = exe_debug_forward_a_wb_condition;
    assign debug_forward_b_wb_condition = exe_debug_forward_b_wb_condition;
    assign debug_forward_a_mem_condition = exe_debug_forward_a_mem_condition;
    assign debug_forward_b_mem_condition = exe_debug_forward_b_mem_condition;
    assign debug_wb_wreg_i_value = exe_debug_wb_wreg_i_value;
    assign debug_wb_wa_i_value = exe_debug_wb_wa_i_value;
    assign debug_wb_wa_i_not_zero = exe_debug_wb_wa_i_not_zero;
    assign debug_wb_wa_i_eq_ra1 = exe_debug_wb_wa_i_eq_ra1;
    assign debug_wb_wa_i_eq_ra2 = exe_debug_wb_wa_i_eq_ra2;
    assign debug_mem_wreg_i_value = exe_debug_mem_wreg_i_value;
    assign debug_mem_wa_i_value = exe_debug_mem_wa_i_value;
    assign debug_mem_wa_i_not_zero = exe_debug_mem_wa_i_not_zero;
    assign debug_mem_wa_i_eq_ra1 = exe_debug_mem_wa_i_eq_ra1;
    assign debug_mem_wa_i_eq_ra2 = exe_debug_mem_wa_i_eq_ra2;
    assign debug_exe_ra1_i_value = exe_debug_exe_ra1_i_value;
    assign debug_exe_ra2_i_value = exe_debug_exe_ra2_i_value;
    // Detailed debug signals for forward_a_mem calculation
    assign debug_forward_a_mem_calc_mem_wreg_i = exe_debug_forward_a_mem_calc_mem_wreg_i;
    assign debug_forward_a_mem_calc_mem_wa_i = exe_debug_forward_a_mem_calc_mem_wa_i;
    assign debug_forward_a_mem_calc_mem_wa_i_not_zero = exe_debug_forward_a_mem_calc_mem_wa_i_not_zero;
    assign debug_forward_a_mem_calc_exe_ra1_i = exe_debug_forward_a_mem_calc_exe_ra1_i;
    assign debug_forward_a_mem_calc_mem_wa_i_eq_ra1 = exe_debug_forward_a_mem_calc_mem_wa_i_eq_ra1;
    assign debug_forward_a_mem_calc_result = exe_debug_forward_a_mem_calc_result;
    assign debug_mem_wa_i_at_assign = exe_debug_mem_wa_i_at_assign;
    assign debug_mem_wa_i_at_forward_calc = exe_debug_mem_wa_i_at_forward_calc;
    
    // Debug signals from exe_stage (connect internal wires to output ports)
    assign debug_exe_wb_wreg_i_internal = exe_debug_exe_wb_wreg_i_internal;
    assign debug_exe_wb_wa_i_internal   = exe_debug_exe_wb_wa_i_internal;
    assign debug_exe_wb_wd_i_internal   = exe_debug_exe_wb_wd_i_internal;
    assign debug_forward_a_wb_condition = exe_debug_forward_a_wb_condition;
    assign debug_forward_b_wb_condition = exe_debug_forward_b_wb_condition;
    assign debug_wb_wreg_i_value = exe_debug_wb_wreg_i_value;
    assign debug_wb_wa_i_value   = exe_debug_wb_wa_i_value;
    assign debug_wb_wa_i_not_zero = exe_debug_wb_wa_i_not_zero;
    assign debug_wb_wa_i_eq_ra1  = exe_debug_wb_wa_i_eq_ra1;
    assign debug_wb_wa_i_eq_ra2  = exe_debug_wb_wa_i_eq_ra2;
    assign debug_exe_ra1_i_value = exe_debug_exe_ra1_i_value;
    assign debug_exe_ra2_i_value = exe_debug_exe_ra2_i_value;
    
    // Delayed register debug signals
    assign debug_wb_wreg_i_delayed = wb_wreg_i_delayed;
    assign debug_wb_wa_i_delayed   = wb_wa_i_delayed;
    assign debug_wb_wd_i_delayed   = wb_dreg_i_delayed;
    
    // ID stage instruction decode debug signals (connect internal wires to output ports)
    assign debug_id_inst_st_b = id_debug_inst_st_b;
    assign debug_id_rd = id_debug_rd;
    assign debug_id_rj = id_debug_rj;
    assign debug_id_rk = id_debug_rk;
    assign debug_id_op_31_22 = id_debug_op_31_22;
    assign debug_id_is_store_or_branch = id_debug_is_store_or_branch;
    assign debug_id_src2_is_imm = id_debug_src2_is_imm;
    assign debug_id_imm_ext = id_debug_imm_ext;
    assign debug_id_rd1 = id_debug_rd1;
    assign debug_id_rd2 = id_debug_rd2;
    assign debug_id_br_op1 = id_debug_br_op1;
    assign debug_id_br_target = id_debug_br_target;
    assign debug_id_ra1 = id_debug_ra1;
    assign debug_id_ra2 = id_debug_ra2;
    assign debug_id_br_op1_raw = id_debug_br_op1_raw;
    assign debug_id_exe_fwd_match = id_debug_exe_fwd_match;
    assign debug_id_mem_fwd_match = id_debug_mem_fwd_match;
    assign debug_id_wb_fwd_match = id_debug_wb_fwd_match;
    assign debug_id_exe_fwd_wd = id_debug_exe_fwd_wd;
    assign debug_id_mem_fwd_wd = id_debug_mem_fwd_wd;
    assign debug_id_wb_fwd_wd = id_debug_wb_fwd_wd;
    
    // Store data debug signals
    assign debug_exe_rk_d_o = exe_rk_d_out;
    assign debug_exe_rk_d_i = exe_rk_d;
    assign debug_id_rk_d_o = id_rk_d;

endmodule
