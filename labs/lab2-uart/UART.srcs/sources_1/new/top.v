module top(
    input rxd,
    output txd,
    input clk
    );
    uart_loopback U0(.txd(txd), .rxd(rxd), .clk(clk));
endmodule
