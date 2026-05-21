module BaudTickGen(
	input clk, enable,
	output logic tick
);
// 参数定义，以下为默认值
parameter ClkFrequency = 100000000; // 时钟频率
parameter Baud = 9600; // 波特率
parameter Oversampling = 1; // 过采样倍数

// 定义 log2(x) 函数，结果向上取整
function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction

// 计算波特率发生器计数器 (Acc) 位宽 (AccWidth)
// 基础位宽：log2(ClkFrequency/Baud) 确保能覆盖完整的波特率周期
// 额外8位：提高时序精度
localparam AccWidth = log2(ClkFrequency/Baud)+8;
logic [AccWidth:0] Acc = 0; // 定义计数器并初始化为0

// 计算计数器递增量 (Inc)
// 计算公式为 Inc = ((Baud * Oversampling) * 2^AccWidth) / ClkFrequency
// 为防止 ((Baud * Oversampling) << AccWidth) 溢出，首先计算一个安全的右移位数
// 原理：通过预先右移 (31 - AccWidth) 位，确保 (Baud * Oversampling) 在放大前被缩小，
//       从而为后续左移 (AccWidth - ShiftLimiter) 位留出足够的位宽空间。
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));
// 采用缩放法避免除法溢出：将分子分母同比例缩放后再进行整数除法
// "+(ClkFrequency>>(ShiftLimiter+1))"目的是实现四舍五入以减少误差
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);

// 计数器，enable信号有效时才更新计数器
// tick赋值为计数器的最高位
always_ff @(posedge clk) if(enable) Acc <= Acc[AccWidth-1:0] + Inc[AccWidth-1:0]; else Acc <= Inc[AccWidth-1:0];
assign tick = Acc[AccWidth];
endmodule