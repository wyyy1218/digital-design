`timescale 1ns / 1ps

module decoder
(
    input  [3:0] in_data,
    input  [3:0] sel,
    output [7:0] out_data
);

assign out_data = 
    (sel     == 4'd8)  ? 8'b1111_1111 : // 第8个数码管不显示
    (in_data == 4'd0)  ? 8'b1100_0000 : // 0
    (in_data == 4'd1)  ? 8'b1111_1001 : // 1
    (in_data == 4'd2)  ? 8'b1010_0100 : // 2
    (in_data == 4'd3)  ? 8'b1011_0000 : // 3
    (in_data == 4'd4)  ? 8'b1001_1001 : // 4
    (in_data == 4'd5)  ? 8'b1001_0010 : // 5
    (in_data == 4'd6)  ? 8'b1000_0010 : // 6
    (in_data == 4'd7)  ? 8'b1111_1000 : // 7
    (in_data == 4'd8)  ? 8'b1000_0000 : // 8
    (in_data == 4'd9)  ? 8'b1001_0000 : // 9
    (in_data == 4'd10) ? 8'b1000_1000 : // 10
    (in_data == 4'd11) ? 8'b1000_0011 : // 11
    (in_data == 4'd12) ? 8'b1100_0110 : // 12
    (in_data == 4'd13) ? 8'b1010_0001 : // 13
    (in_data == 4'd14) ? 8'b1000_0110 : // 14
    8'b1000_1110;                       // 15
    
endmodule
