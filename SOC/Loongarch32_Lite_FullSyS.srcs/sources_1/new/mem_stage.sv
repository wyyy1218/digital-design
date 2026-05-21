`include "defines.v"

module mem_stage (

    
    input  wire [`ALUOP_BUS     ]       mem_aluop_i,
    input  wire [`REG_ADDR_BUS  ]       mem_wa_i,
    input  wire                         mem_wreg_i,
    input  wire [`REG_BUS       ]       mem_wd_i,
    
    // Memory address for byte selection in load operations
    input  wire [`REG_BUS       ]       mem_addr_i,
    
    // Store  ( reg)  Load  ( RAM)
    input  wire [`REG_BUS       ]       mem_rk_d_i,
    input  wire [`REG_BUS       ]       mem_rdata_i,
    
    
    output wire [`REG_ADDR_BUS  ]       mem_wa_o,
    output wire                         mem_wreg_o,
    output wire [`REG_BUS       ]       mem_dreg_o,
    
    output reg  [`REG_BUS       ]       ram_wdata_o
    );

    
    assign mem_wa_o     = mem_wa_i;
    assign mem_wreg_o   = mem_wreg_i;
    //assign mem_dreg_o   = mem_wd_i;
    
    /* -------------------------------------------
     * 1.  Load  (ȡ + չ)
     * ------------------------------------------- */
    reg [`REG_BUS] load_result;
    
    always @(*) begin
        case (mem_aluop_i)
            `LoongArch32_LD_W: begin
                load_result = mem_rdata_i;
            end
            `LoongArch32_LD_B: begin
                // Use memory address low 2 bits for byte selection
                // mem_addr_i is the actual memory address, mem_wd_i is ALU result (also address, but use mem_addr_i for clarity)
                case (mem_addr_i[1:0])
                    2'b00: load_result = {{24{mem_rdata_i[7]}},   mem_rdata_i[7:0]};
                    2'b01: load_result = {{24{mem_rdata_i[15]}},  mem_rdata_i[15:8]};
                    2'b10: load_result = {{24{mem_rdata_i[23]}},  mem_rdata_i[23:16]};
                    2'b11: load_result = {{24{mem_rdata_i[31]}},  mem_rdata_i[31:24]};
                    default: load_result = `ZERO_WORD;
                endcase
            end
            default: begin
                load_result = mem_wd_i;
            end
        endcase
    end
    
    
    assign mem_dreg_o = load_result;
    
    /* -------------------------------------------
     * 2.  Store  (׼д RAM)
     * ------------------------------------------- */
    always @(*) begin
        if (mem_aluop_i == `LoongArch32_ST_B) begin
             
             ram_wdata_o = {4{mem_rk_d_i[7:0]}};
        end else begin
             // ST.W
             ram_wdata_o = mem_rk_d_i;
        end
    end

endmodule