`include "defines.v"

module Loongarch32_Lite(
    input  wire                  cpu_clk_50M,
    input  wire                  cpu_rst_n,
    
    // inst_rom
    output wire [`INST_ADDR_BUS] iaddr,
    input  wire [`INST_BUS]      inst,
    
    // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½data_ram ï¿½Ó¿ï¿½
    output wire                 mem_we,    // ï¿½Ã´ï¿½Ð´Ê¹ï¿½ï¿½
    output wire [`REG_BUS]      mem_addr,  // ï¿½Ã´ï¿½ï¿½Ö·
    output wire [`REG_BUS]      mem_wdata, // ï¿½Ã´ï¿½Ð´ï¿½ï¿½ï¿½ï¿½
    input  wire [`REG_BUS]      mem_rdata, // ï¿½Ã´ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
    
    output wire [`INST_ADDR_BUS]  debug_wb_pc,       // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ê¹ï¿½Ãµï¿½PCÖµï¿½ï¿½ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    output wire                   debug_wb_rf_wen,   // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ê¹ï¿½Ãµï¿½PCÖµï¿½ï¿½ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    output wire [`REG_ADDR_BUS  ] debug_wb_rf_wnum,  // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ê¹ï¿½Ãµï¿½PCÖµï¿½ï¿½ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    output wire [`WORD_BUS      ] debug_wb_rf_wdata, // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ê¹ï¿½Ãµï¿½PCÖµï¿½ï¿½ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    
    // ï¿½ï¿½ï¿½Ú²ï¿½ SoC ï¿½ï¿½ï¿½Üµï¿½ IF ï¿½ï¿½Í£ï¿½ÅºÅ£ï¿½MEM ï¿½Ú¶ï¿½ .text Ê±ï¿½ï¿½Í£È¡Ö¸
    input  wire                  stall_if_from_soc
    );
    
    
    wire [`WORD_BUS      ] pc;
     
    // ï¿½ï¿½ï¿½ï¿½IF/IDÄ£ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½×¶ï¿½IDÄ£ï¿½ï¿½Ä±ï¿½ï¿½ï¿½
    wire [`WORD_BUS      ] id_pc_i;
    wire [`INST_BUS      ] id_inst_i;
    
    // ï¿½ï¿½ï¿½ï¿½IDÄ£ï¿½ï¿½ï¿½ï¿½Í¨ï¿½Ã¼Ä´ï¿½ï¿½ï¿½RegfileÄ£ï¿½ï¿½Ä±ï¿½ï¿½ï¿½;
    wire [`REG_ADDR_BUS  ] ra1;
    wire [`REG_BUS       ] rd1;
    wire [`REG_ADDR_BUS  ] ra2;
    wire [`REG_BUS       ] rd2;
    
    // ï¿½ï¿½ï¿½ï¿½ID/EXEÄ£ï¿½ï¿½ï¿½ï¿½Ö´ï¿½Ð½×¶ï¿½EXEÄ£ï¿½ï¿½Ä±ï¿½ï¿½ï¿½
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
    
    // ï¿½ï¿½ï¿½ï¿½EXE/MEMÄ£ï¿½ï¿½ï¿½ï¿½Ã´ï¿½×¶ï¿½MEMÄ£ï¿½ï¿½Ä±ï¿½ï¿½ï¿½
    wire [`ALUOP_BUS     ] exe_aluop_o;
    wire 				   exe_wreg_o;
    wire [`REG_ADDR_BUS  ] exe_wa_o;
    wire [`REG_BUS 	     ] exe_wd_o;
    wire [`ALUOP_BUS     ] mem_aluop_i;
    wire 				   mem_wreg_i;
    wire [`REG_ADDR_BUS  ] mem_wa_i;
    wire [`REG_BUS 	     ] mem_wd_i;
    
    // ï¿½ï¿½ï¿½ï¿½MEM/WBÄ£ï¿½ï¿½ï¿½ï¿½Ð´ï¿½Ø½×¶ï¿½WBÄ£ï¿½ï¿½Ä±ï¿½ï¿½ï¿½
    wire 				   mem_wreg_o;
    wire [`REG_ADDR_BUS  ] mem_wa_o;
    wire [`REG_BUS 	     ] mem_dreg_o;
    wire 				   wb_wreg_i;
    wire [`REG_ADDR_BUS  ] wb_wa_i;
    wire [`REG_BUS       ] wb_dreg_i;
    
    // ï¿½ï¿½ï¿½ï¿½WBÄ£ï¿½ï¿½ï¿½ï¿½Í¨ï¿½Ã¼Ä´ï¿½ï¿½ï¿½RegfileÄ£ï¿½ï¿½Ä±ï¿½ï¿½ï¿½
    wire 				   wb_wreg_o;
    wire [`REG_ADDR_BUS  ] wb_wa_o;
    wire [`REG_BUS       ] wb_wd_o;
    
    // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Store ï¿½ï¿½ï¿½ï¿½Í¨Â·ï¿½Åºï¿½
    wire [`REG_BUS       ] id_rk_d;
    wire [`REG_BUS       ] exe_rk_d; // ï¿½ï¿½ ID/EXE ï¿½ï¿½ï¿½ï¿½
    wire [`REG_BUS       ] exe_rk_d_out; // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ EXE ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ store data
    wire [`REG_BUS       ] mem_rk_d; // ï¿½ï¿½ EXE/MEM ï¿½ï¿½ï¿½ï¿½
    wire [`REG_BUS       ] ram_wdata; // MEM ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ RAM ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
    
    // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ô´ï¿½Ä´ï¿½ï¿½ï¿½ï¿½ï¿½Ö· (ï¿½ï¿½ï¿½ï¿½Ç°ï¿½ï¿½)
    wire [`REG_ADDR_BUS  ] exe_ra1;
    wire [`REG_ADDR_BUS  ] exe_ra2;
    
    // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ö§ï¿½Åºï¿½
    wire                   br_taken;
    wire [`INST_ADDR_BUS]  br_target;
    
    wire [`INST_ADDR_BUS]  if_debug_wb_pc;         // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]  id_debug_wb_pc_i;       // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]  id_debug_wb_pc_o;       // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]  exe_debug_wb_pc_i;      // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]  exe_debug_wb_pc_o;      // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]  mem_debug_wb_pc_i;      // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]  mem_debug_wb_pc_o;      // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    wire [`INST_ADDR_BUS]   wb_debug_wb_pc_i;      // ï¿½Ï°ï¿½ï¿½ï¿½ï¿½Ê±ï¿½ï¿½ï¿½É¾ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
    
    // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Í£ï¿½Åºï¿½
    wire stall_req;
    // ï¿½Úºï¿½Ñ¹ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ SoC ï¿½ï¿½ï¿½ï¿½ï¿½ stall_if ï¿½ï¿½MEM ï¿½Ú¶ï¿½ .text Ê±ï¿½ï¿½Í£ IF/ID
    wire stall = stall_req | stall_if_from_soc; // ID ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Í£Ê±ï¿½ï¿½È«ï¿½ï¿½ï¿½ï¿½Í£ IF ï¿½ï¿½ IDï¿½ï¿½ï¿½ï¿½ Flush EXE

    if_stage if_stage0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .pc(pc), .iaddr(iaddr), .debug_wb_pc(if_debug_wb_pc),
        .br_taken(br_taken),   
        .br_target(br_target),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .stall(stall)
    );
    
    ifid_reg ifid_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .inst(inst), .if_pc(pc), .if_debug_wb_pc(if_debug_wb_pc),
        .id_inst(id_inst_i), .id_pc(id_pc_i), .id_debug_wb_pc(id_debug_wb_pc_i),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .stall(stall),
        
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Þ¸Ä¡ï¿½ï¿½ï¿½ br_taken ï¿½ï¿½ï¿½Óµï¿½ flush
        // ï¿½ï¿½ ID ï¿½×¶ï¿½ï¿½Ð¶ï¿½ï¿½ï¿½Òªï¿½ï¿½×ªÊ±ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ë¢ï¿½ï¿½ IF/ID ï¿½Ä´ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ò»ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ö¸ï¿½ï¿½
        .flush(br_taken)
    );

    id_stage id_stage0(.id_pc_i(id_pc_i), 
        .id_inst_i(id_inst_i),
        .id_debug_wb_pc(id_debug_wb_pc_i),
        .rd1(rd1), .rd2(rd2), 	  
        .ra1(ra1), .ra2(ra2), 
        .id_aluop_o(id_aluop_o), .id_alutype_o(id_alutype_o),
        .id_src1_o(id_src1_o), .id_src2_o(id_src2_o),
        .id_wa_o(id_wa_o), .id_wreg_o(id_wreg_o),
        .debug_wb_pc(id_debug_wb_pc_o),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .id_rk_d_o(id_rk_d),
        .br_taken(br_taken),
        .br_target(br_target),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½Îªï¿½Ë¼ï¿½ï¿½ Load-Useï¿½ï¿½ï¿½ï¿½Òª EXE ï¿½×¶Îµï¿½ï¿½ï¿½Ï¢
        .exe_aluop_i(exe_aluop_i),
        .exe_wa_i(exe_wa_i),
        .exe_wreg_i(exe_wreg_i),
        .stall_req(stall_req)
    );
    
    regfile regfile0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .we(wb_wreg_o), .wa(wb_wa_o), .wd(wb_wd_o),
        .ra1(ra1), .rd1(rd1),
        .ra2(ra2), .rd2(rd2)
    );
    
    idexe_reg idexe_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n), 
        .id_alutype(id_alutype_o), .id_aluop(id_aluop_o),
        .id_src1(id_src1_o), .id_src2(id_src2_o),
        .id_wa(id_wa_o), .id_wreg(id_wreg_o),
        .id_debug_wb_pc(id_debug_wb_pc_o),
        .exe_alutype(exe_alutype_i), .exe_aluop(exe_aluop_i),
        .exe_src1(exe_src1_i), .exe_src2(exe_src2_i), 
        .exe_wa(exe_wa_i), .exe_wreg(exe_wreg_i),
        .exe_debug_wb_pc(exe_debug_wb_pc_i),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .id_rk_d(id_rk_d),
        .exe_rk_d(exe_rk_d),
        
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .id_ra1(ra1), // ï¿½ï¿½ ID ï¿½×¶Îµï¿½ ra1 ï¿½ï¿½ï¿½ï¿½ EXE
        .id_ra2(ra2), // ï¿½ï¿½ ID ï¿½×¶Îµï¿½ ra2 ï¿½ï¿½ï¿½ï¿½ EXE
        .exe_ra1(exe_ra1),
        .exe_ra2(exe_ra2),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .next_stall(stall) // ï¿½ï¿½ stall ï¿½ï¿½Ð§Ê±ï¿½ï¿½Flush ID/EXE (ï¿½ï¿½ï¿½ï¿½ NOP)
    );
    
    exe_stage exe_stage0(
        .exe_alutype_i(exe_alutype_i), .exe_aluop_i(exe_aluop_i),
        .exe_src1_i(exe_src1_i), .exe_src2_i(exe_src2_i),
        .exe_wa_i(exe_wa_i), .exe_wreg_i(exe_wreg_i),
        .exe_debug_wb_pc(exe_debug_wb_pc_i),
        .exe_aluop_o(exe_aluop_o),
        .exe_wa_o(exe_wa_o), .exe_wreg_o(exe_wreg_o), .exe_wd_o(exe_wd_o),
        .debug_wb_pc(exe_debug_wb_pc_o),
        
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½Ç°ï¿½ï¿½ï¿½ï¿½ï¿½
        .exe_ra1_i(exe_ra1),
        .exe_ra2_i(exe_ra2),
        .exe_rk_d_i(exe_rk_d),
        .exe_rk_d_o(exe_rk_d_out), // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ store data
        
        // ï¿½ï¿½ï¿½ï¿½ MEM ï¿½×¶Îµï¿½Ç°ï¿½ï¿½ï¿½ï¿½Ï¢
        .mem_wreg_i(mem_wreg_o), // ×¢ï¿½â£ºï¿½ï¿½ï¿½ï¿½ï¿½Ãµï¿½ï¿½ï¿½ MEM ï¿½×¶Î´ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Åºï¿½
        .mem_wa_i(mem_wa_o),
        .mem_wd_i(mem_dreg_o),   // Ê¹ï¿½ï¿½ MEM ï¿½×¶Îµï¿½ï¿½ï¿½ï¿½Õ½ï¿½ï¿½(ALUï¿½ï¿½ï¿½/Loadï¿½ï¿½ï¿½)
        
        // ï¿½ï¿½ï¿½ï¿½ WB ï¿½×¶Îµï¿½Ç°ï¿½ï¿½ï¿½ï¿½Ï¢
        .wb_wreg_i(wb_wreg_o),
        .wb_wa_i(wb_wa_o),
        .wb_wd_i(wb_wd_o)
    );
        
    exemem_reg exemem_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .exe_aluop(exe_aluop_o),
        .exe_wa(exe_wa_o), .exe_wreg(exe_wreg_o), .exe_wd(exe_wd_o),
        .exe_debug_wb_pc(exe_debug_wb_pc_o),
        .mem_aluop(mem_aluop_i),
        .mem_wa(mem_wa_i), .mem_wreg(mem_wreg_i), .mem_wd(mem_wd_i),
        .mem_debug_wb_pc(mem_debug_wb_pc_i),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        //.exe_rk_d(exe_rk_d),
        // ï¿½ï¿½ï¿½Þ¸ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½ï¿½ï¿½ï¿½ï¿½Òªï¿½ï¿½ï¿½ï¿½ exe_stage ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ store data
        .exe_rk_d(exe_rk_d_out),
        .mem_rk_d(mem_rk_d)
    );

    mem_stage mem_stage0(.mem_aluop_i(mem_aluop_i),
        .mem_wa_i(mem_wa_i), .mem_wreg_i(mem_wreg_i), .mem_wd_i(mem_wd_i),
        .mem_debug_wb_pc(mem_debug_wb_pc_i),
        .mem_wa_o(mem_wa_o), .mem_wreg_o(mem_wreg_o), .mem_dreg_o(mem_dreg_o),
        .debug_wb_pc(mem_debug_wb_pc_o),
        // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ó¡ï¿½
        .mem_rk_d_i(mem_rk_d),
        .mem_rdata_i(mem_rdata), // RAM ï¿½ï¿½ï¿½ï¿½
        .ram_wdata_o(ram_wdata)  // RAM Ð´ï¿½ï¿½
    );
    	
    memwb_reg memwb_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .mem_wa(mem_wa_o), .mem_wreg(mem_wreg_o), .mem_dreg(mem_dreg_o),
        .mem_debug_wb_pc(mem_debug_wb_pc_o),
        .wb_wa(wb_wa_i), .wb_wreg(wb_wreg_i), .wb_dreg(wb_dreg_i),
        .wb_debug_wb_pc(wb_debug_wb_pc_i)
    );

    wb_stage wb_stage0(
        .wb_wa_i(wb_wa_i), .wb_wreg_i(wb_wreg_i), .wb_dreg_i(wb_dreg_i), 
        .wb_debug_wb_pc(wb_debug_wb_pc_i),
        .wb_wa_o(wb_wa_o), .wb_wreg_o(wb_wreg_o), .wb_wd_o(wb_wd_o),
        .debug_wb_pc(debug_wb_pc),       
        .debug_wb_rf_wen(debug_wb_rf_wen),   
        .debug_wb_rf_wnum(debug_wb_rf_wnum),  
        .debug_wb_rf_wdata(debug_wb_rf_wdata)  
    );
    
    // ==========================================================
    // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ß¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½É¶ï¿½ï¿½ï¿½Ã´ï¿½ï¿½Åºï¿½
    // ==========================================================
    
    // 1. ï¿½Ã´ï¿½Ð´Ê¹ï¿½ï¿½: ï¿½ï¿½Ö¸ï¿½ï¿½Îª ST.W (0x41) ï¿½ï¿½ ST.B (0x43) Ê±ï¿½ï¿½Ð§
    assign mem_we = (mem_aluop_i == `LoongArch32_ST_W) || (mem_aluop_i == `LoongArch32_ST_B);

    // 2. ï¿½Ã´ï¿½ï¿½Ö·: ALUï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ (mem_wd_i) ï¿½ï¿½Îªï¿½ï¿½Ö·
    assign mem_addr = mem_wd_i;

    // 3. ï¿½Ã´ï¿½Ð´ï¿½ï¿½ï¿½ï¿½: 
    assign mem_wdata = ram_wdata;

endmodule
