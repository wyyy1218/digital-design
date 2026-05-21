`timescale 1ns / 1ps

module ALU_32bits_top(
        input             sys_clk,
        input             sys_rst_n,
        input  [7  : 0]   btn,
        input  [31 : 0]   A,
        input  [31 : 0]   B,
        output [7  : 0]   seg,
        output [3  : 0]   sel,
        output [1  : 0]   led
    );
    
    ALU_32bits ALU_32bits(
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .btn(btn),
        .A(A),
        .B(B),
        .seg(seg),
        .sel(sel),
        .led(led)
    );
        
endmodule
