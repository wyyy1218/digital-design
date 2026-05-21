`timescale 1ns / 1ps
module logic_gates_top(
    input [ 7 : 0] btn, 
    output [31 : 0] leds
);
logic_gates logic_gates(
    .A(btn[7]),
    .B(btn[3]),
    .leds(leds)
);
endmodule