////////////////////////////////////////////////////////
// RS-232 RX and TX module
// (c) fpga4fun.com & KNJN LLC - 2003 to 2016

// 仿真模式开关
`define SIMULATION   

////////////////////////////////////////////////////////
module async_receiver(
	input clk,
	input RxD,
	output logic RxD_data_ready,
	input  RxD_clear,
	output logic [7:0] RxD_data
);

parameter ClkFrequency = 100000000;	// 100MHz
parameter Baud = 9600;
parameter Oversampling = 8;  

// ============================================================
// 修复点1：RxD_state 必须在 ifdef 外面定义，否则仿真模式下找不到该变量
// ============================================================
logic [3:0] RxD_state = 0; 

/* -------------- 波特率时钟生成控制 & 输入处理 -------------- */
`ifdef SIMULATION
    // ================= 仿真模式 =================
    // 为了让仿真波形快速出来，直接透传 RxD，并且时刻采样
    logic RxD_bit; 
    assign RxD_bit = RxD;
    
    // 仿真时始终允许采样（配合 tb 里的时钟）
    logic sampleNow = 1'b1; 

`else
    // ================= 硬件上板模式 =================
    logic OversamplingTick;
    BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen(.clk(clk), .enable(1'b1), .tick(OversamplingTick));

    // 计算 log2(Oversampling)
    function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
    localparam l2o = log2(Oversampling);

    // 过采样计数器
    logic [l2o-2:0] OversamplingCnt = 0;
    always_ff @(posedge clk) if(OversamplingTick) OversamplingCnt <= (RxD_state==0) ? 1'd0 : OversamplingCnt + 1'd1;

    // 采样点判定
    logic sampleNow;
    assign sampleNow = OversamplingTick && (OversamplingCnt==Oversampling/2-1);

    // 同步
    logic [1:0] RxD_sync = 2'b11;
    always_ff @(posedge clk) if(OversamplingTick) RxD_sync <= {RxD_sync[0], RxD};

    // 滤波
    logic [1:0] Filter_cnt = 2'b11; 
    logic RxD_bit = 1'b1;   
    always_ff @(posedge clk)
    if(OversamplingTick) begin
        if(RxD_sync[1]==1'b1 && Filter_cnt!=2'b11) Filter_cnt <= Filter_cnt + 1'd1;
        else if(RxD_sync[1]==1'b0 && Filter_cnt!=2'b00) Filter_cnt <= Filter_cnt - 1'd1;
        
        if(Filter_cnt==2'b11) RxD_bit <= 1'b1;
        else if(Filter_cnt==2'b00) RxD_bit <= 1'b0;
    end
`endif

/* ----------------- 状态机 ----------------- */
always_ff @(posedge clk)
    case(RxD_state)
        // 仿真时检测到起始位直接跳到接收态，硬件时跳到0001确认态
        4'b0000: if(~RxD_bit) RxD_state <= `ifdef SIMULATION 4'b1000 `else 4'b0001 `endif;  
        4'b0001: if(sampleNow) RxD_state <= 4'b1000;  // 接收起始位
        4'b1000: if(sampleNow) RxD_state <= 4'b1001;  // Bit 0
        4'b1001: if(sampleNow) RxD_state <= 4'b1010;  // Bit 1
        4'b1010: if(sampleNow) RxD_state <= 4'b1011;  // Bit 2
        4'b1011: if(sampleNow) RxD_state <= 4'b1100;  // Bit 3
        4'b1100: if(sampleNow) RxD_state <= 4'b1101;  // Bit 4
        4'b1101: if(sampleNow) RxD_state <= 4'b1110;  // Bit 5
        4'b1110: if(sampleNow) RxD_state <= 4'b1111;  // Bit 6
        4'b1111: if(sampleNow) RxD_state <= 4'b0010;  // Bit 7 -> Stop
        4'b0010: if(sampleNow) RxD_state <= 4'b0000;  // Stop -> Idle
        default: if(sampleNow) RxD_state <= 4'b0000;
    endcase

/*-----------------移位寄存器-----------------*/
always_ff @(posedge clk)
begin
    if(sampleNow && RxD_state[3]) begin
        RxD_data <= {RxD_bit, RxD_data[7:1]}; 
    end
end
         
/*-----------------输出逻辑-----------------*/
always_ff @(posedge clk)
begin
    if(RxD_clear)
        RxD_data_ready <= 0;
    else begin
        RxD_data_ready <= RxD_data_ready | (sampleNow && RxD_state == 4'b0010 && RxD_bit);
    end
end

endmodule
