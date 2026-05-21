`timescale 1ns / 1ps

module seg_made
(
    input  [31 : 0] a,    // a 为 alu 计算结果（32位）
    output [7  : 0] seg,  // 数码管显示段选信号
    output [3  : 0] sel,  // 数码管显示片选信号
    input           clk
);
    
/********************** 以下为扫描信号部分 **********************/
    // 扫描信号
    reg [3:0] scan_sel = 4'd0;
    parameter SCAN_DELAY = 100_000; // 时钟频率为100MHz，1ms更新一次扫描信号
    reg [16:0] scan_cnt = 17'd0;
    wire scan_en = (scan_cnt == SCAN_DELAY - 1);
    
    // 扫描计数器
    always @(posedge clk)
    begin
        if (scan_en)
            scan_cnt <= 17'd0;
        else
            scan_cnt <= scan_cnt + 1'b1;
    end
    
    // 更新扫描信号
    always @(posedge clk)
    begin
        if (scan_en)
            if (scan_sel == 4'd8)
                scan_sel <= 4'd0;
            else
                scan_sel <= scan_sel + 1'b1;
    end
    
/********************** 以下为数码管部分 **********************/
    reg [3:0] dec_reg [0:8]; // 寄存9个十进制数据
    
    always @(posedge clk)
    begin
        dec_reg[0] <= a[3  :  0];
        dec_reg[1] <= a[7  :  4];
        dec_reg[2] <= a[11 :  8];
        dec_reg[3] <= a[15 : 12]; 
        dec_reg[4] <= a[19 : 16];
        dec_reg[5] <= a[23 : 20];
        dec_reg[6] <= a[27 : 24];
        dec_reg[7] <= a[31 : 28];
        dec_reg[8] <= 4'hf;
    end
    
/********************** 以下为输出部分 **********************/
    // 数码管译码器
    wire [7:0] seg_out;
    
    // 译码器实例化
    decoder DECODER_inst
    (
        .in_data(dec_reg[scan_sel]), // 译码器输入为当前扫描的十进制数据
        .sel(scan_sel),
        .out_data(seg_out)
    );
    
    // 将扫描信号输出
    assign sel = scan_sel;
    // 将译码器输出赋给数码管
    assign seg = seg_out;
    
endmodule