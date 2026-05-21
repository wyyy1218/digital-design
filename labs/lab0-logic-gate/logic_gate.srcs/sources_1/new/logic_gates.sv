`timescale 1ns / 1ps
module logic_gates(
input A, input B, output [31 : 0] leds
);
    logic ans_and;
    logic ans_or;
    logic ans_not;
and_gate and_gate(
    .A(A),
    .B(B),
    .ans_and(ans_and)
);
or_gate or_gate(
    .A(A),
    .B(B),
    .ans_or(ans_or)
);
not_gate not_gate(
    .A(A),
    .ans_not(ans_not)
);
    assign leds = {29'b0, ans_and, ans_or, ans_not};
endmodule
