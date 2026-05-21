`timescale 1ns / 1ps

module rca(
    input logic [31:0] A,
    input logic [31:0] B,
    input logic Cin,
    output logic [31:0] S,
    output logic Cout
);
    logic [32:0] carry;
    assign carry[0] = Cin;
    
    // 实例化32个全加器
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : adder_chain
            fulladder fa(
                .A(A[i]),
                .B(B[i]),
                .Cin(carry[i]),
                .S(S[i]),
                .Cout(carry[i+1])
            );
        end
    endgenerate
    
    assign Cout = carry[32];
endmodule