`include "defines.v"

module wb_stage(

    
	input  wire [`REG_ADDR_BUS  ] wb_wa_i,
	input  wire                   wb_wreg_i,
	input  wire [`REG_BUS       ] wb_dreg_i,

    
    output wire [`REG_ADDR_BUS  ] wb_wa_o,
	output wire                   wb_wreg_o,
    output wire [`WORD_BUS      ] wb_wd_o
    );

    assign wb_wa_o      = wb_wa_i;
    assign wb_wreg_o    = wb_wreg_i;
    assign wb_wd_o      = wb_dreg_i;
endmodule
