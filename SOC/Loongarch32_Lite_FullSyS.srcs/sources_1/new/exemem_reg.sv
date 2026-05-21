`include "defines.v"

module exemem_reg (
    input  wire 				cpu_clk_50M,
    input  wire 				cpu_rst_n,

    
    input  wire [`ALUOP_BUS   ] exe_aluop,
    input  wire [`REG_ADDR_BUS] exe_wa,
    input  wire                 exe_wreg,
    input  wire [`REG_BUS 	  ] exe_wd,
    
    // Store 数据
    input  wire [`REG_BUS     ] exe_rk_d,
    
    output reg  [`ALUOP_BUS   ] mem_aluop,
    output reg  [`REG_ADDR_BUS] mem_wa,
    output reg                  mem_wreg,
    output reg  [`REG_BUS 	  ] mem_wd,
    
    // MEM 阶段的 Store 数据
    output reg  [`REG_BUS     ] mem_rk_d
    );

    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            //mem_aluop              <= `LoongArch32_SLL;
            // SLL 未实现，这里用 ADD_W 作为占位
            mem_aluop              <= `LoongArch32_ADD_W;
            mem_wa 				   <= `REG_NOP;
            mem_wreg   			   <= `WRITE_DISABLE;
            mem_wd   			   <= `ZERO_WORD;
            mem_rk_d           <= `ZERO_WORD;
        end
        else begin
            mem_aluop              <= exe_aluop;
            mem_wa 				   <= exe_wa;
            mem_wreg 			   <= exe_wreg;
            mem_wd 		    	   <= exe_wd;
            // 
            mem_rk_d           <= exe_rk_d;
        end
    end

endmodule