`timescale 1ns / 1ps

module ALU_32bits_tb();

    // 时钟和复位信号
    logic sys_clk;
    logic sys_rst_n;

    // ALU接口信号
    logic [31:0] A;
    logic [31:0] B;
    logic [3:0] aluop; 
    logic [31:0] alures;
    logic ZF;
    logic OF;
    
    // 测试期望值
    logic [31:0] expected_alures;
    logic expected_ZF;
    logic expected_OF;
    
    // 测试统计
    integer total_tests = 0;
    integer passed_tests = 0;
    integer failed_tests = 0;
    
    // 操作码定义
    localparam AND   = 4'b0000;
    localparam OR    = 4'b0001;
    localparam XOR   = 4'b0010;
    localparam NAND  = 4'b0011;
    localparam NOT   = 4'b0100;
    localparam SLL   = 4'b0101;
    localparam SRL   = 4'b0110;
    localparam SRA   = 4'b0111;
    localparam MULU  = 4'b1000;
    localparam MUL   = 4'b1001;
    localparam ADD   = 4'b1010;
    localparam ADDU  = 4'b1011;
    localparam SUB   = 4'b1100;
    localparam SUBU  = 4'b1101;
    localparam SLT   = 4'b1110;
    localparam SLTU  = 4'b1111;

    // 时钟生成（100MHz）
    initial begin
        sys_clk = 1'b0;
        forever #5 sys_clk = ~sys_clk;
    end

    // 复位信号
    initial begin
        sys_rst_n = 1'b0;
        #100 sys_rst_n = 1'b1;  // 100ns后释放复位
        $display("=== Reset released at time %0t ===", $time);
    end

    // 实例化被测ALU
    alu dut (
        .A(A),
        .B(B), 
        .aluop(aluop),  // 确保名称匹配
        .alures(alures),
        .ZF(ZF),
        .OF(OF)
    );

    // 自动化测试任务
    task automatic run_test(
        input [31:0] test_A,
        input [31:0] test_B,
        input [3:0] test_aluop, 
        input [31:0] test_expected_alures,
        input test_expected_ZF,
        input test_expected_OF,
        input string operation_name
    );
        begin
            @(posedge sys_clk);
            // 应用测试向量
            A <= test_A;
            B <= test_B;
            aluop <= test_aluop;
            expected_alures <= test_expected_alures;
            expected_ZF <= test_expected_ZF;
            expected_OF <= test_expected_OF;
            
            total_tests <= total_tests + 1;
            
            // 等待ALU计算完成
            repeat(3) @(posedge sys_clk);
            
            // 验证结果
            if (alures === expected_alures && ZF === expected_ZF && OF === expected_OF) begin
                passed_tests <= passed_tests + 1;
                $display("PASS: %-8s A=%8h B=%8h → Result=%8h ZF=%b OF=%b", 
                        operation_name, test_A, test_B, alures, ZF, OF);
            end else begin
                failed_tests <= failed_tests + 1;
                $display("FAIL: %s", operation_name);
                $display("  Expected: Result=%8h ZF=%b OF=%b", 
                        expected_alures, expected_ZF, expected_OF);
                $display("  Got:      Result=%8h ZF=%b OF=%b", alures, ZF, OF);
            end
        end
    endtask

    // 主测试流程
    initial begin
        // 初始化
        A = 32'b0;
        B = 32'b0; 
        aluop = 4'b0;
        expected_alures = 32'b0;
        expected_ZF = 1'b0;
        expected_OF = 1'b0;
        
        // 等待复位完成
        wait(sys_rst_n === 1'b1);
        #20;
        
        // 第一组：逻辑运算测试
        $display("--- Group 1: Logical Operations ---");
        run_test(32'hFFFF_FFFF, 32'h1234_5678, AND,  32'h1234_5678, 0, 0, "AND");
        run_test(32'hFFFF_0000, 32'h1234_5678, OR,   32'hFFFF_5678, 0, 0, "OR"); 
        run_test(32'hAAAA_AAAA, 32'h5555_5555, XOR,  32'hFFFF_FFFF, 0, 0, "XOR");
        run_test(32'hFFFF_FFFF, 32'hFFFF_FFFF, NAND, 32'h0000_0000, 1, 0, "NAND");
        run_test(32'h1234_5678, 32'h0000_0000, NOT,  32'hEDCB_A987, 0, 0, "NOT");
        
        // 第二组：移位运算测试  
        $display("\n--- Group 2: Shift Operations ---");
        run_test(32'h0000_0001, 32'h0000_0004, SLL, 32'h0000_0010, 0, 0, "SLL");
        run_test(32'h8000_0000, 32'h0000_0001, SRL, 32'h4000_0000, 0, 0, "SRL");
        run_test(32'h8000_0000, 32'h0000_0001, SRA, 32'hC000_0000, 0, 0, "SRA");
        run_test(32'h0000_000F, 32'h0000_0001, SLL, 32'h0000_001E, 0, 0, "SLL2");
        
        // 第三组：算术运算测试
        $display("\n--- Group 3: Arithmetic Operations ---");
        run_test(32'h0000_0003, 32'h0000_0002, ADD,  32'h0000_0005, 0, 0, "ADD");
        run_test(32'h7FFF_FFFF, 32'h0000_0001, ADD,  32'h8000_0000, 0, 1, "ADD_OVF");
        run_test(32'h0000_0005, 32'h0000_0003, SUB,  32'h0000_0002, 0, 0, "SUB");
        run_test(32'h8000_0000, 32'h0000_0001, SUB,  32'h7FFF_FFFF, 0, 1, "SUB_OVF");
        run_test(32'h0000_1000, 32'h0000_1000, MULU, 32'h0100_0000, 0, 0, "MULU");
        run_test(32'hFFFF_FFFF, 32'hFFFF_FFFF, MUL,  32'h0000_0001, 0, 0, "MUL_S");
        
        // 第四组：比较运算测试
        $display("\n--- Group 4: Comparison Operations ---");
        run_test(32'h0000_0001, 32'h0000_0002, SLT,  32'h0000_0001, 0, 0, "SLT_T");
        run_test(32'h0000_0003, 32'h0000_0002, SLT,  32'h0000_0000, 1, 0, "SLT_F");
        run_test(32'h0000_0001, 32'hFFFF_FFFF, SLTU, 32'h0000_0001, 0, 0, "SLTU_T");
        run_test(32'hFFFF_FFFF, 32'h0000_0001, SLTU, 32'h0000_0000, 1, 0, "SLTU_F");
        
        // 第五组：边界条件测试
        $display("\n--- Group 5: Boundary Conditions ---");
        run_test(32'h0000_0000, 32'h0000_0000, AND,  32'h0000_0000, 1, 0, "ZERO");
        run_test(32'hFFFF_FFFF, 32'h0000_0000, ADD,  32'hFFFF_FFFF, 0, 0, "MAX+0");
        run_test(32'h0000_0000, 32'h0000_0001, SUB,  32'hFFFF_FFFF, 0, 0, "0-1");
        
        // 完成测试
        #100;
        $display("Total Tests:  %0d", total_tests);
        $display("Passed:       %0d", passed_tests);
        $display("Failed:       %0d", failed_tests);
        $display("Success Rate: %0.1f%%", (real'(passed_tests) / real'(total_tests)) * 100.0);
        
        if (failed_tests == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** TEST FAILURES DETECTED ***");
        end
        
        $display("\n=== ALU Test Completion at time %0t ===", $time);
        $finish;
    end

    // 监控ALU行为
    always @(posedge sys_clk) begin
        if (sys_rst_n && total_tests > 0) begin
            $display("MONITOR: A=%8h B=%8h OP=%b → RES=%8h ZF=%b OF=%b", 
                    A, B, aluop, alures, ZF, OF);
        end
    end

endmodule