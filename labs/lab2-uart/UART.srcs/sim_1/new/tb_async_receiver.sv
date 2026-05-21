`timescale 1ns / 1ps
`define SIMULATION
module tb_async_receiver();
    logic         sys_clk;
    logic         rx;
    
    logic        [7:0]   rx_data;
    logic                rx_flag;
    logic                rx_clear;
    
    initial begin
        sys_clk     = 1'b1;
        rx          = 1'b1;
    end
    
    initial begin
        #50
        rx_bit(8'd0);
        rx_bit(8'd1);
        rx_bit(8'd2);
        rx_bit(8'd3);
        rx_bit(8'd4);
        rx_bit(8'd5);
        rx_bit(8'd6);
        rx_bit(8'd7);
    end
    
    always #5 sys_clk = ~sys_clk;
    task rx_bit(
        input   [7:0]   data
    );
        integer i;
        for(i = 0; i<11; i=i+1)begin
            case(i)
                1: rx <= 1'b0;
                2: rx <= data[0];
                3: rx <= data[1];
                4: rx <= data[2];
                5: rx <= data[3];
                6: rx <= data[4];
                7: rx <= data[5];
                8: rx <= data[6];
                9: rx <= data[7];
                10: rx <= 1'b1;
            endcase
            `ifdef SIMULATION
            #(10); // a cycle
            `else
            #(104167); // 1e9/9600
            `endif
        end
    endtask
    
    assign rx_clear = rx_flag; // 数据有效后，立即清空
    async_receiver async_receiver_inst(
        .clk(sys_clk),
        .RxD(rx),
        .RxD_data_ready(rx_flag),
        .RxD_clear(rx_clear),
        .RxD_data(rx_data)
    );
    logic [7:0] ref_data = 0;
    always_ff @(posedge sys_clk) begin
        if(rx_flag == 1'b1) begin
            $display("reference: 0x%2h, yours: 0x%2h", ref_data, rx_data);
            if(ref_data != rx_data) begin
                $display("Error!");
                $stop;
            end
            if(ref_data == 8'd7) begin
                $display("RX Test Pass!");
                $finish;
            end
            ref_data = ref_data + 1;
        end
    end
endmodule
