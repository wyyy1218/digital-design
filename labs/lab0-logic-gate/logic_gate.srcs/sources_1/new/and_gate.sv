`timescale 1ns / 1ps
module and_gate(
input A, input B, output ans_and
);
    assign ans_and = A & B;
endmodule