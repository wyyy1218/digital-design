`timescale 1ns / 1ps
module not_gate(
    input A, output ans_not
);
    assign ans_not = ~A;
endmodule