`timescale 1ns / 1ps

module fulladder(
    input logic A,
    input logic B,
    input logic Cin,
    output logic S,
    output logic Cout
);
    // 全加器逻辑实现
    assign S = A ^ B ^ Cin;
    assign Cout = (A & B) | (A & Cin) | (B & Cin);
endmodule