module x7seg(
    input clk,          // 100Mhz
    input [3:0] seg_wdata[0:8],
    output logic [3:0] seg_cs,
    output logic [7:0] seg_data
);
    logic [3:0]   scan_sel    = 4'd0;
    // 50MHz 时，1ms 扫描周期
    parameter   SCAN_DELAY  = 50_000;
    logic [16:0]  scan_cnt    = 17'd0;
    wire        scan_en     = (scan_cnt == SCAN_DELAY - 1'b1);
    
    
    always @(posedge clk)
    begin
        if (scan_en)
            scan_cnt <= 17'd0;
        else
            scan_cnt <= scan_cnt + 1'b1;
    end
    
    
    always @(posedge clk)
    begin
        if (scan_en)
            if (scan_sel == 4'd8)
                scan_sel <= 4'd0;
            else
                scan_sel <= scan_sel + 1'b1;
    end

    logic [7:0] digit[0:8];
    seg_decoder seg_decoder0(.in_data(seg_wdata[0][3:0]), .out_data(digit[0][6:0])); // 0ֵ
    seg_decoder seg_decoder1(.in_data(seg_wdata[1][3:0]), .out_data(digit[1][6:0])); // 1ֵ
    seg_decoder seg_decoder2(.in_data(seg_wdata[2][3:0]), .out_data(digit[2][6:0])); // 2ֵ
    seg_decoder seg_decoder3(.in_data(seg_wdata[3][3:0]), .out_data(digit[3][6:0])); // 3ֵ
    seg_decoder seg_decoder4(.in_data(seg_wdata[4][3:0]), .out_data(digit[4][6:0])); // 4ֵ
    seg_decoder seg_decoder5(.in_data(seg_wdata[5][3:0]), .out_data(digit[5][6:0])); // 5ֵ
    seg_decoder seg_decoder6(.in_data(seg_wdata[6][3:0]), .out_data(digit[6][6:0])); // 6ֵ
    seg_decoder seg_decoder7(.in_data(seg_wdata[7][3:0]), .out_data(digit[7][6:0])); // 7ֵ
    seg_decoder seg_decoder8(.in_data(seg_wdata[8][3:0]), .out_data(digit[8][6:0])); // 8ֵ
    assign digit[0][7] = 1'b1; // 0С㣬ʾС
    assign digit[1][7] = 1'b1; // 1С㣬ʾС
    assign digit[2][7] = 1'b1; // 2С㣬ʾС
    assign digit[3][7] = 1'b1; // 3С㣬ʾС
    assign digit[4][7] = 1'b1; // 4С㣬ʾС
    assign digit[5][7] = 1'b1; // 5С㣬ʾС
    assign digit[6][7] = 1'b1; // 6С㣬ʾС
    assign digit[7][7] = 1'b1; // 7С㣬ʾС
    assign digit[8][7] = 1'b1; // 8С㣬ʾС
    
    assign seg_data = digit[scan_sel];
    assign seg_cs = scan_sel;
    
endmodule

module seg_decoder(
    input   [3:0]   in_data, 
    output logic [6:0]   out_data  
);

    /*
    segment map
        a
       ---
    f |   | b
      | g |
       ---
    e |   | c
      |   |
       ---  . h
        d
    
    sequence: hgfe_dcba
    */

    assign out_data =  (in_data == 4'h0) ? 7'b100_0000 : // 0
                        (in_data == 4'h1) ? 7'b111_1001 : // 1
                        (in_data == 4'h2) ? 7'b010_0100 : // 2
                        (in_data == 4'h3) ? 7'b011_0000 : // 3
                        (in_data == 4'h4) ? 7'b001_1001 : // 4
                        (in_data == 4'h5) ? 7'b001_0010 : // 5
                        (in_data == 4'h6) ? 7'b000_0010 : // 6
                        (in_data == 4'h7) ? 7'b111_1000 : // 7
                        (in_data == 4'h8) ? 7'b000_0000 : // 8
                        (in_data == 4'h9) ? 7'b001_0000 : // 9
                        (in_data == 4'ha) ? 7'b000_1000 : // A
                        (in_data == 4'hb) ? 7'b000_0011 : // b
                        (in_data == 4'hc) ? 7'b100_0110 : // C
                        (in_data == 4'hd) ? 7'b010_0001 : // d
                        (in_data == 4'he) ? 7'b000_0110 : // E
                        (in_data == 4'hf) ? 7'b000_1110 : // F
                        7'h7f; // no display

endmodule