`include "defines.v"

module mem_stage (

    // 从执行阶段获得的信息
    input  wire [`ALUOP_BUS     ]       mem_aluop_i,
    input  wire [`REG_ADDR_BUS  ]       mem_wa_i,
    input  wire                         mem_wreg_i,
    input  wire [`REG_BUS       ]       mem_wd_i,
    input  wire [`INST_ADDR_BUS]        mem_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 【新增】Store 数据 (来自 reg) 和 Load 数据 (来自 RAM)
    input  wire [`REG_BUS       ]       mem_rk_d_i,
    input  wire [`REG_BUS       ]       mem_rdata_i,
    
    // 送至写回阶段的信息
    output wire [`REG_ADDR_BUS  ]       mem_wa_o,
    output wire                         mem_wreg_o,
    output wire [`REG_BUS       ]       mem_dreg_o,
    
    // 【新增】发送给 Data RAM 的写数据
    output reg  [`REG_BUS       ]       ram_wdata_o,
    
    output wire [`INST_ADDR_BUS] 	    debug_wb_pc  // 供调试使用的PC值，上板测试时务必删除该信号
    );

    // 如果当前不是访存指令，则只需要把从执行阶段获得的信息直接输出
    assign mem_wa_o     = mem_wa_i;
    assign mem_wreg_o   = mem_wreg_i;
    //assign mem_dreg_o   = mem_wd_i;
    
    assign debug_wb_pc = mem_debug_wb_pc;    // 上板测试时务必删除该语句
     
    /* -------------------------------------------
     * 1. 处理 Load 数据 (读取 + 扩展)
     * ------------------------------------------- */
    reg [`REG_BUS] load_result;
    
    always @(*) begin
        case (mem_aluop_i)
            `LoongArch32_LD_W: begin
                load_result = mem_rdata_i;
            end
            `LoongArch32_LD_B: begin
                // 根据地址低2位选择字节 (Assuming Little Endian)
                case (mem_wd_i[1:0])
                    2'b00: load_result = {{24{mem_rdata_i[7]}},   mem_rdata_i[7:0]};
                    2'b01: load_result = {{24{mem_rdata_i[15]}},  mem_rdata_i[15:8]};
                    2'b10: load_result = {{24{mem_rdata_i[23]}},  mem_rdata_i[23:16]};
                    2'b11: load_result = {{24{mem_rdata_i[31]}},  mem_rdata_i[31:24]};
                    default: load_result = `ZERO_WORD;
                endcase
            end
            default: begin
                // 非 Load 指令，透传 ALU 结果 (例如 add.w 的结果)
                load_result = mem_wd_i;
            end
        endcase
    end
    
    // 将处理后的数据送往写回阶段
    assign mem_dreg_o = load_result;
    
    /* -------------------------------------------
     * 2. 处理 Store 数据 (准备写入 RAM)
     * ------------------------------------------- */
    always @(*) begin
        if (mem_aluop_i == `LoongArch32_ST_B) begin
             // 对于字节存储，我们将低8位复制到所有字节位置。
             // 如果 Data RAM IP 支持字节掩码(wea)，则配合使用；
             // 如果不支持，这里只是为了演示逻辑，实际会写入整个字。
             ram_wdata_o = {4{mem_rk_d_i[7:0]}};
        end else begin
             // ST.W
             ram_wdata_o = mem_rk_d_i;
        end
    end

endmodule