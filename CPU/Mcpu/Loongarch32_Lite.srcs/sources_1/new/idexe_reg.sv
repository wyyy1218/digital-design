`include "defines.v"

module idexe_reg (
    input  wire 				  cpu_clk_50M,
    input  wire 				  cpu_rst_n,
    
    // 【新增】气泡插入信号 (Flush)
    // 当发生 Load-Use 冒险时，该信号置 1，强制在 EXE 阶段插入 NOP
    input  wire                   next_stall,

    // 来自译码阶段的信息
    input  wire [`ALUTYPE_BUS  ]  id_alutype,
    input  wire [`ALUOP_BUS    ]  id_aluop,
    input  wire [`REG_BUS      ]  id_src1,
    input  wire [`REG_BUS      ]  id_src2,
    input  wire [`REG_ADDR_BUS ]  id_wa,
    input  wire                   id_wreg,
    input  wire [`INST_ADDR_BUS]  id_debug_wb_pc, // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 【新增】来自ID阶段的 Store 数据
    input  wire [`REG_BUS      ]  id_rk_d,
    
    // 【新增】源寄存器地址 (用于前推判断)
    input  wire [`REG_ADDR_BUS ]  id_ra1,
    input  wire [`REG_ADDR_BUS ]  id_ra2,
    
    // 送至执行阶段的信息
    output reg  [`ALUTYPE_BUS  ]  exe_alutype,
    output reg  [`ALUOP_BUS    ]  exe_aluop,
    output reg  [`REG_BUS      ]  exe_src1,
    output reg  [`REG_BUS      ]  exe_src2,
    output reg  [`REG_ADDR_BUS ]  exe_wa,
    output reg                    exe_wreg,
    output reg  [`INST_ADDR_BUS]  exe_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    // 【新增】送至下一阶段的 Store 数据
    output reg  [`REG_BUS      ]  exe_rk_d,
    
    // 【新增】送至 EXE 阶段的源寄存器地址
    output reg  [`REG_ADDR_BUS ]  exe_ra1,
    output reg  [`REG_ADDR_BUS ]  exe_ra2
    );

    always @(posedge cpu_clk_50M) begin
        // 复位的时候将送至执行阶段的信息清0
        if (cpu_rst_n == `RST_ENABLE || next_stall ) begin
            exe_alutype 	   <= `NOP;
            //exe_aluop 		   <= `LoongArch32_SLL;
            exe_aluop          <= `LoongArch32_ADD_W;  // 【修改处】原SLL未定义，改为ADD_W
            exe_src1 		   <= `ZERO_WORD;
            exe_src2 		   <= `ZERO_WORD;
            exe_wa 			   <= `REG_NOP;
            exe_wreg    	   <= `WRITE_DISABLE;
            exe_debug_wb_pc    <= `PC_INIT;   // 上板测试时务必删除该语句
            // 【新增】复位
            exe_rk_d           <= `ZERO_WORD;
            
            // 【新增】复位
            exe_ra1            <= `REG_NOP;
            exe_ra2            <= `REG_NOP;
        end
        // 将来自译码阶段的信息寄存并送至执行阶段
        else begin
            exe_alutype 	   <= id_alutype;
            exe_aluop 		   <= id_aluop;
            exe_src1 		   <= id_src1;
            exe_src2 		   <= id_src2;
            exe_wa 			   <= id_wa;
            exe_wreg		   <= id_wreg;
            exe_debug_wb_pc    <= id_debug_wb_pc;   // 上板测试时务必删除该语句
            // 【新增】传递
            exe_rk_d           <= id_rk_d;
            
            // 【新增】传递
            exe_ra1            <= id_ra1;
            exe_ra2            <= id_ra2;
        end
    end

endmodule