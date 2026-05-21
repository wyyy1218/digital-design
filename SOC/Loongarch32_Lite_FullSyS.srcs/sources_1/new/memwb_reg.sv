`include "defines.v"

module memwb_reg (
    input  wire                     cpu_clk_50M,
	input  wire                     cpu_rst_n,

	
	input  wire [`REG_ADDR_BUS  ]   mem_wa,
	input  wire                     mem_wreg,
	input  wire [`REG_BUS       ] 	mem_dreg,

	 
	output reg  [`REG_ADDR_BUS  ]   wb_wa,
	output reg                      wb_wreg,
	output reg  [`REG_BUS       ]   wb_dreg
    );

    always @(posedge cpu_clk_50M) begin
		if (cpu_rst_n == `RST_ENABLE) begin
			wb_wa                 <= `REG_NOP;
			wb_wreg               <= `WRITE_DISABLE;
			wb_dreg               <= `ZERO_WORD;
		end
		
		else begin
			wb_wa 	              <= mem_wa;
			wb_wreg               <= mem_wreg;
			wb_dreg               <= mem_dreg;
		end
	end

endmodule