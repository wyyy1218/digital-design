`include "defines.v"

module ifid_reg (
	input  wire 						cpu_clk_50M,
	input  wire 						cpu_rst_n,
	
	
    input  wire                         stall,
    
    // Flush：置 1 时将 IF/ID 插入 NOP
    input  wire                   flush,

	  
	input  wire [`INST_ADDR_BUS]       if_pc,
	input  wire [`INST_BUS     ]       inst,  

	  
	output reg  [`INST_ADDR_BUS]        id_pc,
	output reg  [`INST_BUS     ]        id_inst
	);

	always @(posedge cpu_clk_50M) begin
		if (cpu_rst_n == `RST_ENABLE) begin
			id_pc 	<= `PC_INIT;
			id_inst <= `ZERO_WORD;
		end
		else if (stall) begin
            id_pc   <= id_pc;
            id_inst <= id_inst;
        end
		else if (flush) begin
            id_pc   <= `PC_INIT;  // inst 置为 NOP
            id_inst <= `ZERO_WORD; // NOP 指令
        end
		
		else begin
    	    id_pc	<= if_pc;
            id_inst <= inst;
		end
	end

endmodule