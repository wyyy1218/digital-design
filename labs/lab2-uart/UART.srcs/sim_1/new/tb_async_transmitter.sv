`timescale 1ns / 1ps
`define SIMULATION
module tb_async_transmitter();
    logic             sys_clk;
    logic     [7:0]   tx_data;
    
    logic            tx;
    logic            tx_start;
    logic            tx_busy;
    
    initial begin
        sys_clk     = 1'b1;
    end
    always #5    sys_clk = ~sys_clk;
    
    async_transmitter async_transmitter_inst(
        .clk(sys_clk),
        .TxD_start(tx_start),
        .TxD_data(tx_data),
        .TxD(tx),
        .TxD_busy(tx_busy)
    );
    
    task tx_bit(
        input [7:0] data
    );
        tx_data     <= data;
        tx_start    <= 1'd1;
        #10;
        tx_start    <= 1'd0;
        `ifdef SIMULATION
        #(100); // ten cycle
        `else
        #(1041667); // 1e9/9600 * 10
        `endif
    endtask
    
    initial begin
        tx_data     <= 8'd0;
        tx_start    <= 1'd0;
        #50;
        tx_bit(8'd0);
        tx_bit(8'd1);
        tx_bit(8'd2);
        tx_bit(8'd3);
        tx_bit(8'd4);
        tx_bit(8'd5);
        tx_bit(8'd6);
        tx_bit(8'd7);
        `ifdef SIMULATION
        #(100); // ten cycle
        `else
        #(1041667); // 1e9/9600 * 10
        `endif
        $finish;
    end
    `ifdef SIMULATION
    logic [7:0] rx_data;
    logic rx_done;
    
    logic [3:0] bit_count = 0;
    logic [7:0] shift_reg = 0;
    logic receiving = 0;
    logic [7:0] expected_data;
    always @(posedge tx_start) begin
        expected_data <= tx_data;
    end
    always @(posedge sys_clk) begin
        if (!receiving && tx === 1'b0) begin // 检测起始位
            receiving <= 1'b1;
            bit_count <= 0;
            shift_reg <= 0;
        end else if (receiving) begin
            if (bit_count < 8) begin
                shift_reg[bit_count] <= tx;
                bit_count <= bit_count + 1;
            end else begin
                if (tx === 1'b1) begin
                    rx_data <= shift_reg;
                    rx_done <= 1'b1;
                end else begin
                    $display("Error: Stop bit not detected!");
                end
                receiving <= 0;
                rx_done <= 1'b0;
            end
        end
    end
    
    // 显示接收到的数据
    always @(posedge rx_done) begin
        $display("Time: %0t ns | Expected: %h | Received: %h | %s", 
                 $time, expected_data, rx_data, (expected_data === rx_data) ? "PASS" : "FAIL");
    end
    `endif
endmodule