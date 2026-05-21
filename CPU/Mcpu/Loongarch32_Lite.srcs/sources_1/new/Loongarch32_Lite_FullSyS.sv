module Loongarch32_Lite_FullSyS(
    input sys_clk,
    input sys_rst_n
    );
    
    logic cpu_clk;
    logic cpu_rst_n;
    logic locked;
    
    // 时钟分频
    clkdiv clocking0 (
    // Clock out ports
    .clk_out(cpu_clk),     // output clk_out
    // Status and control signals
    .resetn(sys_rst_n), // input resetn
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in(sys_clk ));      // input clk_in
    
    // 将locked信号转为后级电路的复位信号rst_n
    // 注意：在仿真中，locked信号可能需要较长时间才能拉高，这里简化处理
    // 对于仿真，直接使用sys_rst_n；对于综合，使用locked信号
    initial begin
        cpu_rst_n = 1'b0;  // 初始复位
        #500;              // 等待500ns让时钟稳定
        cpu_rst_n = 1'b1;  // 释放复位
    end
    
    // 综合时使用locked信号（注释掉initial，使用always_ff）
    // always_ff @(posedge cpu_clk or negedge locked) begin
    //     if(~locked) cpu_rst_n = 1'b0; 
    //     else        cpu_rst_n = 1'b1;
    // end
    
    wire [31:0] debug_wb_pc;       // 供调试使用的PC值，上板测试时务必删除该信号 
    wire        debug_wb_rf_wen;   // 供调试使用的PC值，上板测试时务必删除该信号 
    wire [ 4:0] debug_wb_rf_wnum;  // 供调试使用的PC值，上板测试时务必删除该信号 
    wire [31:0] debug_wb_rf_wdata;  // 供调试使用的PC值，上板测试时务必删除该信号 
    
     /* ---------TODO---------
     * 添加 data_ram 相关信号
     * 实例化 Loongarch32_Lite 中连接 data_ram 相关信号
     * ---------------------- */
    
    /* --------------------------------------
     * 新增 data_ram 相关连线
     * -------------------------------------- */
    wire        data_we;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    
    logic [31:0] iaddr;
    logic [31:0] inst;
    
    Loongarch32_Lite Loongarch32_Lite0(
        .cpu_clk_50M(cpu_clk),
        .cpu_rst_n(cpu_rst_n),
        
        .iaddr(iaddr),
        .inst(inst),
        
        // 【新增】连接访存接口
        .mem_we(data_we),
        .mem_addr(data_addr),
        .mem_wdata(data_wdata),
        .mem_rdata(data_rdata),
        
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        
        // 阶段一暂不需要SoC的stall信号，固定为0
        .stall_if_from_soc(1'b0)
    );
    
    inst_rom inst_rom0 (
      .a(iaddr[15:2]),      // input wire [13 : 0] a
      .spo(inst)  // output wire [31 : 0] spo
    );
    
    /* ---------TODO---------
     * 实例化 data_ram
     * ---------------------- */
     data_ram data_ram0 (
      .clk(cpu_clk),        // input wire clk
      .we(data_we),         // input wire [0 : 0] we
      .a(data_addr[15:2]),  // input wire [13 : 0] a (字节地址转字地址)
      .d(data_wdata),       // input wire [31 : 0] d
      .spo(data_rdata)      // output wire [31 : 0] spo
    );
     
endmodule