`include "defines.v"

module ifid_reg (
	input  wire 						cpu_clk_50M,
	input  wire 						cpu_rst_n,
	
	// 【新增】来自控制模块的暂停信号
    input  wire                         stall,
    
    // 【新增】刷新信号 (Flush)
    // 当分支发生跳转时，清除当前正在取指的错误指令
    input  wire                   flush,

	// 来自取指阶段的信息  
	input  wire [`INST_ADDR_BUS]       if_pc,
	input  wire [`INST_ADDR_BUS]       if_debug_wb_pc, // 供调试使用的PC值，上板测试时务必删除该信号
	
	// 来自指令存储器的信息
	input  wire [`INST_BUS     ]       inst,  

	// 送至译码阶段的信息  
	output reg  [`INST_ADDR_BUS]        id_pc,
	output reg  [`INST_BUS     ]        id_inst,
    output reg  [`INST_ADDR_BUS] 	    id_debug_wb_pc  // 供调试使用的PC值，上板测试时务必删除该信号
	);

	always @(posedge cpu_clk_50M) begin
	    // 复位的时候将送至译码阶段的信息清0
		if (cpu_rst_n == `RST_ENABLE) begin
			id_pc 	<= `PC_INIT;
			id_debug_wb_pc <= `PC_INIT;   // 上板测试时务必删除该语句
			id_inst <= `ZERO_WORD;
		end
		else if (flush) begin
            id_pc   <= `PC_INIT; // 或者保持不变，关键是 inst 要变 NOP
            id_debug_wb_pc <= `PC_INIT;
            id_inst <= `ZERO_WORD; // 变成 NOP 指令
        end
		else if (stall) begin
            // 【核心修改】如果暂停，保持当前数据，不做任何操作
            // id_pc <= id_pc; 
            // id_inst <= id_inst;
        end
		// 将来自取指阶段的信息寄存并送至译码阶段
		else begin
    	    id_pc	<= if_pc;
            id_debug_wb_pc <= if_debug_wb_pc;   // 上板测试时务必删除该语句
            id_inst <= inst;
		end
	end

endmodule