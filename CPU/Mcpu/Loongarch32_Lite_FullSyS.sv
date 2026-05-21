module Loongarch32_Lite_FullSys(
    input sys_clk,
    input sys_rst_n
    );
    
    logic cpu_clk;
    logic cpu_rst_n;
    logic locked;
    
    // 时钟分频（原有代码，无需修改）
    clkdiv clocking0 (
        .clk_out(cpu_clk),     // output clk_out
        .resetn(sys_rst_n),    // input resetn
        .locked(locked),       // output locked
        .clk_in(sys_clk)       // input clk_in
    );
    
    // 复位信号同步（原有代码，无需修改）
    always_ff @(posedge cpu_clk or negedge locked) begin
        if(~locked) cpu_rst_n = 1'b0; 
        else        cpu_rst_n = 1'b1;
    end
    
    // 调试信号（原有代码，上板时删除）
    wire [31:0] debug_wb_pc;
    wire        debug_wb_rf_wen;
    wire [ 4:0] debug_wb_rf_wnum;
    wire [31:0] debug_wb_rf_wdata;
    
    // CPU核与存储器/外设的交互信号（原有信号保留）
    wire        data_we;         // CPU写使能
    wire [31:0] data_addr;       // CPU访存地址
    wire [31:0] data_wdata;      // CPU写入数据
    wire [31:0] data_rdata;      // CPU读出数据
    logic [31:0] iaddr;          // 指令地址
    logic [31:0] inst;           // 指令数据
    
    /* ----------------------------------------------------------------------
     * 第一步：新增存储空间映射宏定义（关键！统一地址分配）
     * 参考实验PPT的存储空间划分，适配benchtest测试程序
     * ---------------------------------------------------------------------- */
    `define TEXT_ADDR_START 32'h80000000  // 指令存储器（.text段）起始地址
    `define TEXT_ADDR_END   32'h8000FFFF  // 指令存储器结束地址（64KB）
    `define DATA_ADDR_START 32'h80010000  // 数据存储器（.data段）起始地址
    `define DATA_ADDR_END   32'h8001FFFF  // 数据存储器结束地址（64KB）
    `define UART_DATA_ADDR  32'hBFD003F8  // UART数据寄存器地址（读=接收，写=发送）
    `define UART_STAT_ADDR  32'hBFD003FC  // UART状态寄存器地址（只读）
    `define LED_ADDR        32'h80020000  // 自定义LED外设地址（可选，非串口外设）
    
    /* ----------------------------------------------------------------------
     * 第二步：新增总线与外设相关信号
     * ---------------------------------------------------------------------- */
    // 片选信号（选中对应设备）
    reg inst_rom_cs;  // 指令存储器片选（访存阶段访问.text段时有效）
    reg data_ram_cs;  // 数据存储器片选（访问.data段时有效）
    reg uart_cs;      // UART外设片选（访问UART地址时有效）
    reg led_cs;       // LED外设片选（访问LED地址时有效）
    
    // UART接口寄存器（核心外设，必须实现）
    reg [7:0]  uart_data_reg;  // UART数据寄存器（8位，1字节）
    reg [1:0]  uart_stat_reg;  // UART状态寄存器（2位有效）：bit0=发送空闲，bit1=接收就绪
    wire       uart_data_we;   // UART数据寄存器写使能
    wire       uart_stat_we;   // UART状态寄存器写使能（只读，故恒为0）
    
    // LED接口寄存器（可选，非串口外设，用于自选测试程序）
    reg [31:0] led_reg;        // LED状态寄存器（32位，每bit对应1个LED）
    wire       led_we;         // LED写使能
    
    // 总线读数据（汇总所有设备的读出数据，反馈给CPU）
    reg [31:0] bus_rdata;
    
    /* ----------------------------------------------------------------------
     * 第三步：实例化CPU核（原有代码，无需修改）
     * ---------------------------------------------------------------------- */
    Loongarch32_Lite Loongarch32_Lite0(
        .cpu_clk_50M(cpu_clk),
        .cpu_rst_n(cpu_rst_n),
        .iaddr(iaddr),
        .inst(inst),
        .mem_we(data_we),
        .mem_addr(data_addr),
        .mem_wdata(data_wdata),
        .mem_rdata(data_rdata),
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );
    
    /* ----------------------------------------------------------------------
     * 第四步：实例化指令存储器（原有代码，补充访存阶段访问逻辑）
     * 关键修改：支持取指阶段和访存阶段同时访问，访存阶段优先
     * ---------------------------------------------------------------------- */
    reg if_en;  // 取指使能（访存阶段访问指令存储器时，禁止取指）
    inst_rom inst_rom0 (
        .a(iaddr[15:2] & {14{if_en}}),  // 地址屏蔽：if_en=0时地址为0，停止取指
        .spo(inst)
    );
    
    // 取指与访存冲突处理逻辑
    always @(*) begin
        if (inst_rom_cs) begin
            if_en = 1'b0;  // 访存阶段访问指令存储器，取指优先让渡
        end else begin
            if_en = 1'b1;  // 无冲突，允许取指
        end
    end
    
    /* ----------------------------------------------------------------------
     * 第五步：实例化数据存储器（原有代码，无需修改）
     * 注意：地址位宽[15:2]对应64KB（字节地址转字地址，32位=4字节，右移2位）
     * ---------------------------------------------------------------------- */
    data_ram data_ram0 (
        .clk(cpu_clk),
        .we(data_we & data_ram_cs),  // 仅数据存储器片选有效时，写使能才生效
        .a(data_addr[15:2]),
        .d(data_wdata),
        .spo(data_rdata)
    );
    
    /* ----------------------------------------------------------------------
     * 第六步：实现地址译码逻辑（总线核心功能1）
     * 根据CPU访存地址，选中对应的设备（存储器/外设）
     * ---------------------------------------------------------------------- */
    always @(*) begin
        // 默认所有片选置0（避免误选）
        inst_rom_cs = 1'b0;
        data_ram_cs = 1'b0;
        uart_cs     = 1'b0;
        led_cs      = 1'b0;
        
        if ((data_addr >= `TEXT_ADDR_START) && (data_addr <= `TEXT_ADDR_END)) begin
            // 访存阶段访问指令存储器（.text段，如读取全局数据）
            inst_rom_cs = 1'b1;
        end else if ((data_addr >= `DATA_ADDR_START) && (data_addr <= `DATA_ADDR_END)) begin
            // 访问数据存储器（.data段）
            data_ram_cs = 1'b1;
        end else if (data_addr == `UART_DATA_ADDR || data_addr == `UART_STAT_ADDR) begin
            // 访问UART外设
            uart_cs = 1'b1;
        end else if (data_addr == `LED_ADDR) begin
            // 访问LED外设（可选）
            led_cs = 1'b1;
        end
    end
    
    /* ----------------------------------------------------------------------
     * 第七步：实现总线写操作逻辑（总线核心功能2）
     * 仅向被选中的设备发送写数据和写使能
     * ---------------------------------------------------------------------- */
    // UART数据寄存器写使能（仅写数据寄存器时有效，状态寄存器只读）
    assign uart_data_we = uart_cs & (data_addr == `UART_DATA_ADDR) & data_we;
    assign uart_stat_we = 1'b0;  // 状态寄存器只读，禁止写操作
    // LED写使能（仅LED片选和CPU写使能同时有效）
    assign led_we = led_cs & data_we;
    
    // UART数据寄存器写逻辑（CPU发送数据）
    always @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            uart_data_reg <= 8'h00;
        end else if (uart_data_we) begin
            uart_data_reg <= data_wdata[7:0];  // UART为8位，取CPU写入数据的低8位
        end
    end
    
    // LED寄存器写逻辑（CPU控制LED亮灭）
    always @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            led_reg <= 32'h00000000;  // 复位时LED全灭
        end else if (led_we) begin
            led_reg <= data_wdata;  // CPU写入数据直接控制LED状态（bit=1亮，bit=0灭）
        end
    end
    
    /* ----------------------------------------------------------------------
     * 第八步：实现总线读操作逻辑（总线核心功能3）
     * 从被选中的设备读取数据，反馈给CPU
     * ---------------------------------------------------------------------- */
    always @(*) begin
        case (1'b1)
            inst_rom_cs:  // 读指令存储器（访存阶段）
                bus_rdata = inst_rom0.spo;
            data_ram_cs:  // 读数据存储器
                bus_rdata = data_ram0.spo;
            uart_cs: begin  // 读UART外设
                if (data_addr == `UART_DATA_ADDR) begin
                    // 读UART数据寄存器（接收数据），高位补0
                    bus_rdata = {24'h000000, uart_data_reg};
                end else begin
                    // 读UART状态寄存器，高位补0（仅bit0和bit1有效）
                    bus_rdata = {30'h00000000, uart_stat_reg};
                end
            end
            led_cs:  // 读LED状态（可选）
                bus_rdata = led_reg;
            default:  // 无设备选中，返回0
                bus_rdata = 32'h00000000;
        endcase
    end
    
    // 将总线读数据反馈给CPU核（关键连接！）
    assign data_rdata = bus_rdata;
    
    /* ----------------------------------------------------------------------
     * 第九步：UART状态寄存器更新（适配benchtest测试程序）
     * 模拟串口硬件逻辑：bit0=1表示发送空闲（可发送数据），bit1=1表示接收就绪
     * 注：实际FPGA平台需与硬件UART控制器对接，此处为仿真+上板兼容逻辑
     * ---------------------------------------------------------------------- */
    always @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            uart_stat_reg <= 2'b00;
        end else begin
            // bit0：TX_IDLE（发送空闲），简化为始终空闲（实际需根据硬件修改）
            uart_stat_reg[0] <= 1'b1;
            // bit1：RX_READY（接收就绪），仿真时可手动置1，上板时对接硬件接收信号
            // 此处简化：当CPU读数据寄存器后，状态位清0（模拟数据被取走）
            if (uart_cs && (data_addr == `UART_DATA_ADDR) && !data_we) begin
                uart_stat_reg[1] <= 1'b0;
            end else begin
                // 上板时替换为：uart_stat_reg[1] = 硬件UART的接收就绪信号;
                uart_stat_reg[1] <= 1'b0;  // 仿真时默认无接收数据，需测试时手动修改
            end
        end
    end
    
    /* ----------------------------------------------------------------------
     * （可选）LED外设输出信号（上板时需添加约束文件绑定FPGA引脚）
     * ---------------------------------------------------------------------- */
    wire [31:0] led_out;
    assign led_out = led_reg;
    
endmodule