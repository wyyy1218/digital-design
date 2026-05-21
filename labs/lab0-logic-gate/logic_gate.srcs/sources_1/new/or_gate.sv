`timescale 1ns / 1ps
module or_gate(
    input A, input B, output ans_or
);
    assign ans_or = A | B;
endmodule