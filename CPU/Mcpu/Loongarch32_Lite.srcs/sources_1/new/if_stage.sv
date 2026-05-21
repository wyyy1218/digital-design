`include "defines.v"

module if_stage (
    input 					       cpu_clk_50M,
    input 					       cpu_rst_n,
    
    // 【新增】来自控制模块的暂停信号
    input  wire                 stall,
    
    // 【新增】来自 ID 阶段的分支信号
    input  wire                 br_taken,     // 分支跳转使能 (1:跳转, 0:不跳转)
    input  wire [`INST_ADDR_BUS] br_target,   // 跳转目标地址
    
    output logic [`INST_ADDR_BUS]  pc,
    output 	     [`INST_ADDR_BUS]  iaddr,
    output       [`INST_ADDR_BUS]  debug_wb_pc // 供调试使用的PC值，上板测试时务必删除该信号
    );
  
    wire [`INST_ADDR_BUS] pc_next; 
    //assign pc_next = pc + 4;  
    // =========================================================
    // 【核心修改】PC更新逻辑 (Next PC Logic)
    // =========================================================
    // 如果 br_taken 有效，下一条 PC 为跳转目标 br_target
    // 否则，下一条 PC 为顺序执行的 pc + 4
    assign pc_next = (br_taken) ? br_target : (pc + 4);         

    always @(posedge cpu_clk_50M) begin
        if (~cpu_rst_n) begin
            pc <= `PC_INIT;                   // 复位时 PC 处于初始值
        end
        else if (stall) begin
            // 【核心修改】如果暂停，保持 PC 不变
            pc <= pc;
        end
        else begin
            pc <= pc_next;                    // 指令存储器使能后，PC值每时钟周期加4 	
        end
    end
    
    assign iaddr = pc;    // 指令存储器地址使用当前PC（与该周期进入流水线的指令一致）
    
    // debug_wb_pc输出当前PC（WB阶段会再经流水线寄存器延迟到写回对应的PC）
    assign debug_wb_pc = pc;   // 上板测试时务必删除该语句
    
endmodule