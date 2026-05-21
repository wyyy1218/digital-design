module tb_Loongarch32_Lite_FullSyS();
    // 时钟与复位信号
    logic sys_clk = 0;
    logic sys_rst_n = 1;
    initial forever #5 sys_clk = ~sys_clk;
    
    // 复位序列：确保系统正确初始化
    initial begin
        sys_rst_n = 1;      // 初始为高（复位无效）
        #100;               // 等待100ns
        sys_rst_n = 0;      // 拉低复位（复位有效）
        #500;               // 保持复位500ns（给clkdiv足够时间锁定）
        sys_rst_n = 1;      // 释放复位
        $display("Reset sequence completed at %t", $time);
    end
    
    // Trace文件句柄
    integer trace_fd;
    
    // 初始化：打开trace文件
    initial begin
        trace_fd = $fopen("trace_dut.log", "w");
        if (trace_fd == 0) begin
            $display("ERROR: cannot open trace_dut.log for writing");
            // 不停止仿真，继续运行（trace文件可能生成在其他位置）
        end else begin
            $display("Trace file opened: trace_dut.log, fd=%0d", trace_fd);
        end
    end
    
    // 仿真结束时关闭文件
    final begin
        if (trace_fd != 0) begin
            $fclose(trace_fd);
            $display("Trace file closed: trace_dut.log");
        end
    end
    
    // SoC
    Loongarch32_Lite_FullSyS SoC(
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n)
    );
    
    // CPU 调试信号
    logic        cpu_clk, cpu_rst_n;
    logic [31:0] debug_wb_pc;        // 供调试使用的 PC 值，上板测试时务必删除该信号
    logic        debug_wb_rf_wen;    // 供调试使用的寄存器写回使能，上板测试时务必删除该信号
    logic [ 4:0] debug_wb_rf_wnum;   // 供调试使用的寄存器写回号，上板测试时务必删除该信号
    logic [31:0] debug_wb_rf_wdata;  // 供调试使用的寄存器写回数据，上板测试时务必删除该信号
    
    assign cpu_clk           = SoC.cpu_clk;
    assign cpu_rst_n         = SoC.cpu_rst_n;
    assign debug_wb_pc       = SoC.debug_wb_pc;      
    assign debug_wb_rf_wen   = SoC.debug_wb_rf_wen;  
    assign debug_wb_rf_wnum  = SoC.debug_wb_rf_wnum; 
    assign debug_wb_rf_wdata = SoC.debug_wb_rf_wdata;
    
    // 在每个CPU时钟上升沿，当发生寄存器写回时，输出trace信息
    always @(posedge cpu_clk) begin
        if(debug_wb_rf_wen && debug_wb_rf_wnum != 5'd0) begin
            // 控制台输出（保留原有功能）
            $display("--------------------------------------------------------------");
            $display("[%t]ns",$time/1000);
            $display("reference: PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h",
                      debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
            $display("--------------------------------------------------------------");
            
            // 写入trace文件（格式：PC WE RD WDATA）
            if (trace_fd != 0) begin
                $fdisplay(trace_fd, "%08x %1d %02d %08x",
                         debug_wb_pc, debug_wb_rf_wen,
                         debug_wb_rf_wnum, debug_wb_rf_wdata);
                $fflush(trace_fd);  // 强制刷新缓冲区，确保数据立即写入
            end else begin
                $display("WARNING: trace_fd is 0, cannot write trace!");
            end
        end
    end
endmodule
