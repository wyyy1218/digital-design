`include "defines.v"

module if_stage (
    input 					       cpu_clk_50M,
    input 					       cpu_rst_n,
    
    // Stall request from hazard detection / SoC (hold PC when asserted)
    input  wire                 stall,
    
    // Branch control from ID stage
    input  wire                 br_taken,     // 1: take branch, 0: no branch
    input  wire [`INST_ADDR_BUS] br_target,   // branch target PC
    
    output logic [`INST_ADDR_BUS]  pc,
    output 	     [`INST_ADDR_BUS]  iaddr
    );
  
    wire [`INST_ADDR_BUS] pc_next; 
    //assign pc_next = pc + 4;  
    // =========================================================
    // Next PC logic
    // =========================================================
    // If branch is taken, next PC is br_target; otherwise sequential PC+4.
    assign pc_next = (br_taken) ? br_target : (pc + 4);         

    always @(posedge cpu_clk_50M) begin
        if (~cpu_rst_n) begin
            pc <= `PC_INIT;                   // reset PC
        end
        else if (stall) begin
            // stall: hold PC
            pc <= pc;
        end
        else begin
            pc <= pc_next;                    // update PC
        end
    end
    
    // inst_rom address uses current PC
    assign iaddr = (~cpu_rst_n) ? `PC_INIT : pc;
    
endmodule