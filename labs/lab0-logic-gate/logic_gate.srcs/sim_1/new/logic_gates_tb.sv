`timescale 1ns / 1ps
module logic_gates_tb();
logic [ 7 : 0] btn;
logic [31 : 0] leds;
logic_gates_top udt(
.btn(btn),
.leds(leds)
);
initial begin
btn = 8'b00000000;
#20;
btn = 8'b10000000;
#20;
btn = 8'b00001000;
#20;
btn = 8'b10001000;
#20;
$stop;
end;
initial begin
$timeformat(-9, 0, "ns", 5);
$monitor("At time %t: btn = %b, leds = %b", $time, btn, leds);
end
endmodule