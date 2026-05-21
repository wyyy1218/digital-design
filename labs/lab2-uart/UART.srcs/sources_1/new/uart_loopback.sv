module uart_loopback // loopback
#(
    parameter   BAUD_RATE       = 9600, // 串口波特率
    parameter   CLK_HZ          = 100_000_000
)(
    input rxd,
    output logic txd,

    input clk // 100MHz
);

logic [7:0] ext_uart_rx;
logic  [7:0] ext_uart_buffer, ext_uart_tx;
logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
logic ext_uart_start, ext_uart_avai;

async_receiver #(.ClkFrequency(CLK_HZ),.Baud(BAUD_RATE)) // 接收模块，9600无检验位
    ext_uart_r(
        .clk(clk),                          // 系统时钟信号
        .RxD(rxd),                          // 串行输入
        .RxD_data_ready(ext_uart_ready),    // 数据有效标志
        .RxD_clear(ext_uart_clear),         // 数据清空标志
        .RxD_data(ext_uart_rx)              // 最终接收的并行数据
    );

/* -------------------- buffer --------------------*/
assign ext_uart_clear = ext_uart_ready; // 收到数据的同时，清除标志生效，因为数据已取到ext_uart_buffer中
always_ff @(posedge clk) begin // 接收到缓冲区ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always_ff @(posedge clk) begin // 将缓冲区ext_uart_buffer发送出去
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end
/* ------------------------------------------------*/

async_transmitter #(.ClkFrequency(CLK_HZ),.Baud(BAUD_RATE)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk),                      // 系统时钟
        .TxD(txd),                      // 串行输出
        .TxD_busy(ext_uart_busy),       // 发送端忙碌标志位
        .TxD_start(ext_uart_start),     // 发送端开始工作标志位
        .TxD_data(ext_uart_tx)          // 待发送的数据
    );
endmodule