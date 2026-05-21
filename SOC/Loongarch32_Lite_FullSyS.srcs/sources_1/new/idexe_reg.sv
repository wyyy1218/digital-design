`include "defines.v"

module idexe_reg (
    input  wire 				  cpu_clk_50M,
    input  wire 				  cpu_rst_n,
    
    // Load-Use 冲突时用于 Flush：置 1 时将 EXE 阶段插入 NOP
    input  wire                   next_stall,

    
    input  wire [`ALUTYPE_BUS  ]  id_alutype,
    input  wire [`ALUOP_BUS    ]  id_aluop,
    input  wire [`REG_BUS      ]  id_src1,
    input  wire [`REG_BUS      ]  id_src2,
    input  wire [`REG_ADDR_BUS ]  id_wa,
    input  wire                   id_wreg,
    
    // ID 阶段的 Store 数据
    input  wire [`REG_BUS      ]  id_rk_d,
    
    // 用于前递（forwarding）的寄存器地址
    input  wire [`REG_ADDR_BUS ]  id_ra1,
    input  wire [`REG_ADDR_BUS ]  id_ra2,
    
    
    output reg  [`ALUTYPE_BUS  ]  exe_alutype,
    output reg  [`ALUOP_BUS    ]  exe_aluop,
    output reg  [`REG_BUS      ]  exe_src1,
    output reg  [`REG_BUS      ]  exe_src2,
    output reg  [`REG_ADDR_BUS ]  exe_wa,
    output reg                    exe_wreg,
    // Store 数据
    output reg  [`REG_BUS      ]  exe_rk_d,
    
    // 传递到 EXE 阶段的源寄存器地址（用于前递）
    output reg  [`REG_ADDR_BUS ]  exe_ra1,
    output reg  [`REG_ADDR_BUS ]  exe_ra2
    );

    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE || next_stall ) begin
            exe_alutype 	   <= `NOP;
            //exe_aluop 		   <= `LoongArch32_SLL;
            // SLL 未实现，这里用 ADD_W 作为占位 NOP
            exe_aluop          <= `LoongArch32_ADD_W;
            exe_src1 		   <= `ZERO_WORD;
            exe_src2 		   <= `ZERO_WORD;
            exe_wa 			   <= `REG_NOP;
            exe_wreg    	   <= `WRITE_DISABLE;
            
            exe_rk_d           <= `ZERO_WORD;
            
            
            exe_ra1            <= `REG_NOP;
            exe_ra2            <= `REG_NOP;
        end
        
        else begin
            exe_alutype 	   <= id_alutype;
            exe_aluop 		   <= id_aluop;
            exe_src1 		   <= id_src1;
            exe_src2 		   <= id_src2;
            exe_wa 			   <= id_wa;
            exe_wreg		   <= id_wreg;
            // 
            exe_rk_d           <= id_rk_d;
            
            // 
            exe_ra1            <= id_ra1;
            exe_ra2            <= id_ra2;
        end
    end

endmodule