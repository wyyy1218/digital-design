`timescale 1ns / 1ps
`define SIM

module ALU_32bits(
        input             sys_clk,
        input             sys_rst_n,
        input  [7  : 0]   btn,
        input  [31 : 0]   A,
        input  [31 : 0]   B,
        output [7  : 0]   seg,
        output [3  : 0]   sel,
        output [1  : 0]   led
    );
    
    logic [31 : 0] alures;
    logic          OF;
    logic          ZF;

    alu U0(
        .A          (A),
        .B          (B),
        .aluop      (btn[7 : 4]),
        .alures     (alures),
        .OF         (OF),
        .ZF         (ZF)
    );
    
    seg_made U1(
        .a    (alures),
        .seg  (seg),
        .sel  (sel),
        .clk  (sys_clk)
    );  
    
    assign led = {OF, ZF};
    
endmodule


