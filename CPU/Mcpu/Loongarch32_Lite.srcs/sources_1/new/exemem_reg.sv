`include "defines.v"

module exemem_reg (
    input  wire 				cpu_clk_50M,
    input  wire 				cpu_rst_n,

    // 来自执行阶段的信息
    input  wire [`ALUOP_BUS   ] exe_aluop,
    input  wire [`REG_ADDR_BUS] exe_wa,
    input  wire                 exe_wreg,
    input  wire [`REG_BUS 	  ] exe_wd,
    input  wire [`INST_ADDR_BUS]  exe_debug_wb_pc, // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 【新增】来自上一级的 Store 数据
    input  wire [`REG_BUS     ] exe_rk_d,
    
    // 送到访存阶段的信息 
    output reg  [`ALUOP_BUS   ] mem_aluop,
    output reg  [`REG_ADDR_BUS] mem_wa,
    output reg                  mem_wreg,
    output reg  [`REG_BUS 	  ] mem_wd,
    output reg  [`INST_ADDR_BUS]  mem_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 【新增】送至 MEM 阶段的 Store 数据
    output reg  [`REG_BUS     ] mem_rk_d
    );

    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            //mem_aluop              <= `LoongArch32_SLL;
            mem_aluop              <= `LoongArch32_ADD_W; // 【修改处】原SLL未定义，改为ADD_W
            mem_wa 				   <= `REG_NOP;
            mem_wreg   			   <= `WRITE_DISABLE;
            mem_wd   			   <= `ZERO_WORD;
            mem_debug_wb_pc        <= `PC_INIT;   // 上板测试时务必删除该语句
            // 【新增】复位
            mem_rk_d           <= `ZERO_WORD;
        end
        else begin
            mem_aluop              <= exe_aluop;
            mem_wa 				   <= exe_wa;
            mem_wreg 			   <= exe_wreg;
            mem_wd 		    	   <= exe_wd;
            mem_debug_wb_pc        <= exe_debug_wb_pc;   // 上板测试时务必删除该语句
            // 【新增】传递
            mem_rk_d           <= exe_rk_d;
        end
    end

endmodule