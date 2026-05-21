////////////////////////////////////////////////////////
// RS-232 RX and TX module
// (c) fpga4fun.com & KNJN LLC - 2003 to 2016

// The RS-232 settings are fixed
// TX: 8-bit data, 2 stop, no-parity

`define SIMULATION   // in this mode, TX outputs one bit per clock cycle

////////////////////////////////////////////////////////
module async_transmitter(
	input clk,
	input TxD_start,
	input [7:0] TxD_data,
	output logic TxD,
	output logic TxD_busy
);

parameter ClkFrequency = 100000000;	// 100MHz
parameter Baud = 9600;

/* -------------- 波特率时钟生成控制 -------------- */
`ifdef SIMULATION
// 仿真环境下：为加速仿真，每个时钟周期输出一个位
logic BitTick = 1'b1;  // output one bit per clock cycle
`else
// 实际硬件：使用精确的波特率发生器，按目标波特率生成标记信号
logic BitTick;
BaudTickGen #(ClkFrequency, Baud) tickgen(.clk(clk), .enable(TxD_busy), .tick(BitTick));
`endif
/* ------------------------------------------------ */

/* -------------- 发送端状态机控制逻辑 -------------- */
// 功能描述：
//   - TxD_state: 发送状态机寄存器，定义串行传输的各个阶段
//   - TxD_ready: 状态机就绪标志，指示可接收新数据传输请求
//   - TxD_busy:  发送忙标志，指示当前正处于数据传输状态
// 状态机特性：
//   - 空闲状态(IDLE): 等待TxD_start启动信号，准备接收新数据, 编码为4'b0000
//   - 起始状态(START): 空闲状态下TxD_start有效时更新，编码为4'b0100;
//   - 状态转移条件: 在BitTick有效时推进传输状态，确保波特率同步
//   - 同步设计: TxD_start为同步信号，在时钟上升沿采样有效
logic [3:0] TxD_state = 4'b0;  // 发送状态机状态寄存器
logic TxD_ready;               // 发送器就绪标志
assign TxD_ready = (TxD_state == 4'b0);  // 状态0为空闲就绪状态
assign TxD_busy  = ~TxD_ready;           // 非空闲状态均为忙状态
always_ff @(posedge clk)
begin
    case(TxD_state)
        4'b0000: if(TxD_start) TxD_state <= 4'b0100;  // 空闲->起始
        4'b0100: if(BitTick) TxD_state <= 4'b1000;    // 起始->数据位0
        4'b1000: if(BitTick) TxD_state <= 4'b1001;    // 数据位0->1
        4'b1001: if(BitTick) TxD_state <= 4'b1010;    // 数据位1->2
        4'b1010: if(BitTick) TxD_state <= 4'b1011;    // 数据位2->3
        4'b1011: if(BitTick) TxD_state <= 4'b1100;    // 数据位3->4
        4'b1100: if(BitTick) TxD_state <= 4'b1101;    // 数据位4->5
        4'b1101: if(BitTick) TxD_state <= 4'b1110;    // 数据位5->6
        4'b1110: if(BitTick) TxD_state <= 4'b1111;    // 数据位6->7
        4'b1111: if(BitTick) TxD_state <= 4'b0010;    // 数据位7->停止
        4'b0010: if(BitTick) TxD_state <= 4'b0000;    // 停止->空闲
        default: if(BitTick) TxD_state <= 4'b0000;
    endcase
end
/* ------------------------------------------------- */
/*--------------发送数据帧缓存与位计数器--------------*/
logic [2:0] bit_cnt;  // 3位计数器，可以表示0-7
logic [7:0] TxD_data_reg;  // 数据寄存器

// 数据寄存器和计数器更新
always_ff @(posedge clk)
begin
    if(TxD_ready && TxD_start) begin
        TxD_data_reg <= TxD_data;  // 锁存待发送数据
        bit_cnt <= 3'd0;            // 复位计数器
    end
    else if(TxD_state[3] && BitTick) begin  // 在数据位状态且BitTick有效时
        bit_cnt <= bit_cnt + 3'd1;          // 计数器递增
    end
end

// 串行输出逻辑
always_comb
begin
    case(TxD_state)
        4'b0000: TxD = 1'b1;              // 空闲状态输出1
        4'b0100: TxD = 1'b0;              // 起始位输出0
        4'b1000,4'b1001,4'b1010,4'b1011,
        4'b1100,4'b1101,4'b1110,4'b1111:  // 数据位状态
            TxD = TxD_data_reg[bit_cnt];  // 输出对应数据位
        4'b0010: TxD = 1'b1;              // 停止位输出1
        default: TxD = 1'b1;
    endcase
end

/* -------------------------------------- */
endmodule