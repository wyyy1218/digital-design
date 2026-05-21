`timescale 1ns / 1ps

module tb_SOC_benchtest();
    // ==========================================================
    // Clock and Reset Generation
    // ==========================================================
    logic clk = 0;
    logic locked = 0;
    
    // 50MHz system clock (20ns period)
    initial forever #10 clk = ~clk;
    
    // Clock locked signal: goes high after reset sequence
    initial begin
        locked = 0;
        #1000;  // Wait 1us for clock to stabilize
        locked = 1;
        $display("[%t] Clock locked signal asserted", $time);
    end
    
    // ==========================================================
    // UART Signals
    // ==========================================================
    logic rxd = 1;  // UART RX (idle high)
    logic txd;      // UART TX
    
    // ==========================================================
    // Board Peripherals (not used in simulation, but required)
    // ==========================================================
    logic [31:0] sw_1 = 32'h0;
    logic [31:0] sw_2 = 32'h0;
    logic [31:0] led;
    logic [3:0]  seg_cs;
    logic [7:0]  seg_data;
    logic [7:0]  btn = 8'h0;
    
    // ==========================================================
    // Debug Signals (declared before use)
    // ==========================================================
    logic [31:0] debug_wb_pc;
    logic        debug_wb_rf_wen;
    logic [4:0]  debug_wb_rf_wnum;
    logic [31:0] debug_wb_rf_wdata;
    logic [31:0] debug_if_pc;
    logic [31:0] debug_id_pc;
    logic [31:0] debug_exe_pc;
    logic [31:0] debug_mem_pc;
    logic        debug_stall;
    logic        debug_br_taken;
    logic [31:0] debug_cpu_mem_addr;
    logic        debug_cpu_mem_we;
    logic [31:0] debug_cpu_mem_wdata;
    logic [31:0] debug_cpu_mem_rdata;
    logic        debug_uart_busy;
    logic        debug_uart_tx_pending;
    logic [1:0]  debug_uart_status;
    logic        debug_cpu_write_uart_data;
    logic        debug_ext_uart_start;
    logic [7:0]  debug_uart_tx_buffer;
    logic [7:0]  debug_byte_to_send;
    logic        debug_sel_uart;
    logic [31:0] debug_inst_rom_addr;
    logic [31:0] debug_inst_rom_rdata;
    logic [31:0] debug_inst_rom_rdata_swapped;
    // UART RX debug signals
    logic        debug_uart_rx_ready;
    logic [7:0]  debug_uart_rx_data;
    logic        debug_uart_rx_avai;
    logic [7:0]  debug_uart_rx_buffer;
    logic        debug_uart_rx_clear;
    logic        debug_cpu_read_uart_data;
    
    // Forwarding debug signals
    logic [4:0]  debug_exe_ra1;
    logic [4:0]  debug_exe_ra2;
    logic        debug_forward_a_mem;
    logic        debug_forward_a_wb;
    logic        debug_forward_b_mem;
    logic        debug_forward_b_wb;
    logic [31:0] debug_final_src1;
    logic [31:0] debug_final_src2;
    logic [31:0] debug_exe_src2_i;
    logic        debug_mem_wreg_i;
    logic [4:0]  debug_mem_wa_i;
    logic [31:0] debug_mem_wd_i;
    logic        debug_wb_wreg_i;
    logic [4:0]  debug_wb_wa_i;
    logic [31:0] debug_wb_wd_i;
    logic [31:0] debug_exe_src1_i;
    logic        debug_mem_wreg;
    logic [4:0]  debug_mem_wa;
    logic [31:0] debug_mem_wd;
    logic        debug_wb_wreg;
    logic [4:0]  debug_wb_wa;
    logic [31:0] debug_wb_wd;
    // MEMWB_REG debug signals
    logic        debug_memwb_wreg;
    logic [4:0]  debug_memwb_wa;
    logic [31:0] debug_memwb_wd;
    logic        debug_memwb_wreg_in;
    logic [4:0]  debug_memwb_wa_in;
    logic [31:0] debug_memwb_wd_in;
    // EXEMEM_REG debug signals
    logic        debug_exemem_wreg;
    logic [4:0]  debug_exemem_wa;
    logic [31:0] debug_exemem_wd;
    logic        debug_exemem_wreg_in;
    logic [4:0]  debug_exemem_wa_in;
    logic [31:0] debug_exemem_wd_in;
    // EXEMEM_REG output to EXE_STAGE debug signals (for forwarding)
    logic        debug_exemem_to_exe_wreg;
    logic [4:0]  debug_exemem_to_exe_wa;
    logic [31:0] debug_exemem_to_exe_wd;
    // Signal trace debug signals for mem_wa_i
    logic [4:0]  debug_exemem_reg_mem_wa;
    logic [4:0]  debug_mem_wa_i_wire;
    logic [4:0]  debug_exe_stage_mem_wa_i;
    // Delayed memwb_reg debug signals (for forwarding)
    logic        debug_wb_wreg_i_delayed;
    logic [4:0]  debug_wb_wa_i_delayed;
    logic [31:0] debug_wb_wd_i_delayed;
    // IDEXE_REG debug signals
    logic [4:0]  debug_idexe_ra1_in;
    logic [4:0]  debug_idexe_ra2_in;
    logic [4:0]  debug_idexe_ra1_out;
    logic [4:0]  debug_idexe_ra2_out;
    // Debug signals for values passed to exe_stage
    logic        debug_exe_wb_wreg_i;
    logic [4:0]  debug_exe_wb_wa_i;
    logic [31:0] debug_exe_wb_wd_i;
    // Debug signals for exe_stage internal input values
    logic        debug_exe_wb_wreg_i_internal;
    logic [4:0]  debug_exe_wb_wa_i_internal;
    logic [31:0] debug_exe_wb_wd_i_internal;
    // Debug signals for forwarding condition calculations
    logic        debug_forward_a_wb_condition;
    logic        debug_forward_b_wb_condition;
    logic        debug_forward_a_mem_condition;
    logic        debug_forward_b_mem_condition;
    // Debug signals for forwarding condition components
    logic        debug_wb_wreg_i_value;
    logic [4:0]  debug_wb_wa_i_value;
    logic        debug_wb_wa_i_not_zero;
    logic        debug_wb_wa_i_eq_ra1;
    logic        debug_wb_wa_i_eq_ra2;
    logic        debug_mem_wreg_i_value;
    logic [4:0]  debug_mem_wa_i_value;
    logic        debug_mem_wa_i_not_zero;
    logic        debug_mem_wa_i_eq_ra1;
    logic        debug_mem_wa_i_eq_ra2;
    logic [4:0]  debug_exe_ra1_i_value;
    logic [4:0]  debug_exe_ra2_i_value;
    // Detailed debug signals for forward_a_mem calculation
    logic        debug_forward_a_mem_calc_mem_wreg_i;
    logic [4:0]  debug_forward_a_mem_calc_mem_wa_i;
    logic        debug_forward_a_mem_calc_mem_wa_i_not_zero;
    logic [4:0]  debug_forward_a_mem_calc_exe_ra1_i;
    logic        debug_forward_a_mem_calc_mem_wa_i_eq_ra1;
    logic        debug_forward_a_mem_calc_result;
    logic [4:0]  debug_mem_wa_i_at_assign;
    logic [4:0]  debug_mem_wa_i_at_forward_calc;
    
    // ==========================================================
    // SoC Instance
    // ==========================================================
    Loongarch32_Lite_FullSyS u_soc (
        .clk      (clk),
        .locked   (locked),
        .rxd      (rxd),
        .txd      (txd),
        .sw_1     (sw_1),
        .sw_2     (sw_2),
        .led      (led),
        .seg_cs   (seg_cs),
        .seg_data (seg_data),
        .btn      (btn),
        
        // Debug signals
        .debug_wb_pc      (debug_wb_pc),
        .debug_wb_rf_wen  (debug_wb_rf_wen),
        .debug_wb_rf_wnum (debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        .debug_if_pc      (debug_if_pc),
        .debug_id_pc      (debug_id_pc),
        .debug_exe_pc     (debug_exe_pc),
        .debug_mem_pc     (debug_mem_pc),
        .debug_stall      (debug_stall),
        .debug_br_taken   (debug_br_taken),
        
        // Additional debug signals for memory interface
        .debug_cpu_mem_addr (debug_cpu_mem_addr),
        .debug_cpu_mem_we   (debug_cpu_mem_we),
        .debug_cpu_mem_wdata(debug_cpu_mem_wdata),
        .debug_cpu_mem_rdata(debug_cpu_mem_rdata),
        .debug_uart_busy     (debug_uart_busy),
        .debug_uart_tx_pending(debug_uart_tx_pending),
        .debug_uart_status   (debug_uart_status),
        .debug_cpu_write_uart_data(debug_cpu_write_uart_data),
        .debug_ext_uart_start(debug_ext_uart_start),
        .debug_uart_tx_buffer(debug_uart_tx_buffer),
        .debug_byte_to_send  (debug_byte_to_send),
        .debug_sel_uart      (debug_sel_uart),
        .debug_inst_rom_addr (debug_inst_rom_addr),
        .debug_inst_rom_rdata(debug_inst_rom_rdata),
        .debug_inst_rom_rdata_swapped(debug_inst_rom_rdata_swapped),
        .debug_uart_rx_ready(debug_uart_rx_ready),
        .debug_uart_rx_data(debug_uart_rx_data),
        .debug_uart_rx_avai(debug_uart_rx_avai),
        .debug_uart_rx_buffer(debug_uart_rx_buffer),
        .debug_uart_rx_clear(debug_uart_rx_clear),
        .debug_cpu_read_uart_data(debug_cpu_read_uart_data),
        .debug_exe_ra1(debug_exe_ra1),
        .debug_exe_ra2(debug_exe_ra2),
        .debug_forward_a_mem(debug_forward_a_mem),
        .debug_forward_a_wb(debug_forward_a_wb),
        .debug_forward_b_mem(debug_forward_b_mem),
        .debug_forward_b_wb(debug_forward_b_wb),
        .debug_final_src1(debug_final_src1),
        .debug_final_src2(debug_final_src2),
        .debug_exe_src2_i(debug_exe_src2_i),
        .debug_mem_wreg_i(debug_mem_wreg_i),
        .debug_mem_wa_i(debug_mem_wa_i),
        .debug_mem_wd_i(debug_mem_wd_i),
        .debug_wb_wreg_i(debug_wb_wreg_i),
        .debug_wb_wa_i(debug_wb_wa_i),
        .debug_wb_wd_i(debug_wb_wd_i),
        .debug_exe_src1_i(debug_exe_src1_i),
        .debug_mem_wreg(debug_mem_wreg),
        .debug_mem_wa(debug_mem_wa),
        .debug_mem_wd(debug_mem_wd),
        .debug_wb_wreg(debug_wb_wreg),
        .debug_wb_wa(debug_wb_wa),
        .debug_wb_wd(debug_wb_wd),
        .debug_memwb_wreg(debug_memwb_wreg),
        .debug_memwb_wa(debug_memwb_wa),
        .debug_memwb_wd(debug_memwb_wd),
        .debug_memwb_wreg_in(debug_memwb_wreg_in),
        .debug_memwb_wa_in(debug_memwb_wa_in),
        .debug_memwb_wd_in(debug_memwb_wd_in),
        .debug_exemem_wreg(debug_exemem_wreg),
        .debug_exemem_wa(debug_exemem_wa),
        .debug_exemem_wd(debug_exemem_wd),
        .debug_exemem_wreg_in(debug_exemem_wreg_in),
        .debug_exemem_wa_in(debug_exemem_wa_in),
        .debug_exemem_wd_in(debug_exemem_wd_in),
        .debug_exemem_to_exe_wreg(debug_exemem_to_exe_wreg),
        .debug_exemem_to_exe_wa(debug_exemem_to_exe_wa),
        .debug_exemem_to_exe_wd(debug_exemem_to_exe_wd),
        .debug_exemem_reg_mem_wa(debug_exemem_reg_mem_wa),
        .debug_mem_wa_i_wire(debug_mem_wa_i_wire),
        .debug_exe_stage_mem_wa_i(debug_exe_stage_mem_wa_i),
        .debug_wb_wreg_i_delayed(debug_wb_wreg_i_delayed),
        .debug_wb_wa_i_delayed(debug_wb_wa_i_delayed),
        .debug_wb_wd_i_delayed(debug_wb_wd_i_delayed),
        .debug_idexe_ra1_in(debug_idexe_ra1_in),
        .debug_idexe_ra2_in(debug_idexe_ra2_in),
        .debug_idexe_ra1_out(debug_idexe_ra1_out),
        .debug_idexe_ra2_out(debug_idexe_ra2_out),
        .debug_exe_wb_wreg_i(debug_exe_wb_wreg_i),
        .debug_exe_wb_wa_i(debug_exe_wb_wa_i),
        .debug_exe_wb_wd_i(debug_exe_wb_wd_i),
        .debug_exe_wb_wreg_i_internal(debug_exe_wb_wreg_i_internal),
        .debug_exe_wb_wa_i_internal(debug_exe_wb_wa_i_internal),
        .debug_exe_wb_wd_i_internal(debug_exe_wb_wd_i_internal),
        .debug_forward_a_wb_condition(debug_forward_a_wb_condition),
        .debug_forward_b_wb_condition(debug_forward_b_wb_condition),
        .debug_forward_a_mem_condition(debug_forward_a_mem_condition),
        .debug_forward_b_mem_condition(debug_forward_b_mem_condition),
        .debug_wb_wreg_i_value(debug_wb_wreg_i_value),
        .debug_wb_wa_i_value(debug_wb_wa_i_value),
        .debug_wb_wa_i_not_zero(debug_wb_wa_i_not_zero),
        .debug_wb_wa_i_eq_ra1(debug_wb_wa_i_eq_ra1),
        .debug_wb_wa_i_eq_ra2(debug_wb_wa_i_eq_ra2),
        .debug_mem_wreg_i_value(debug_mem_wreg_i_value),
        .debug_mem_wa_i_value(debug_mem_wa_i_value),
        .debug_mem_wa_i_not_zero(debug_mem_wa_i_not_zero),
        .debug_mem_wa_i_eq_ra1(debug_mem_wa_i_eq_ra1),
        .debug_mem_wa_i_eq_ra2(debug_mem_wa_i_eq_ra2),
        .debug_exe_ra1_i_value(debug_exe_ra1_i_value),
        .debug_exe_ra2_i_value(debug_exe_ra2_i_value),
        .debug_forward_a_mem_calc_mem_wreg_i(debug_forward_a_mem_calc_mem_wreg_i),
        .debug_forward_a_mem_calc_mem_wa_i(debug_forward_a_mem_calc_mem_wa_i),
        .debug_forward_a_mem_calc_mem_wa_i_not_zero(debug_forward_a_mem_calc_mem_wa_i_not_zero),
        .debug_forward_a_mem_calc_exe_ra1_i(debug_forward_a_mem_calc_exe_ra1_i),
        .debug_forward_a_mem_calc_mem_wa_i_eq_ra1(debug_forward_a_mem_calc_mem_wa_i_eq_ra1),
        .debug_forward_a_mem_calc_result(debug_forward_a_mem_calc_result),
        .debug_mem_wa_i_at_assign(debug_mem_wa_i_at_assign),
        .debug_mem_wa_i_at_forward_calc(debug_mem_wa_i_at_forward_calc)
    );
    
    // ==========================================================
    // Log File Handles
    // ==========================================================
    integer trace_wb_fd;
    integer trace_pipeline_fd;
    integer trace_memory_fd;
    integer trace_uart_fd;
    integer trace_bus_fd;
    integer trace_hazard_fd;
    integer trace_summary_fd;
    
    // ==========================================================
    // Test Control Variables
    // ==========================================================
    integer cycle_count = 0;
    integer inst_count = 0;
    integer uart_tx_count = 0;
    integer uart_rx_count = 0;
    
    // UART output buffer for string detection
    reg [7:0] uart_output_buffer [0:99];  // Buffer for last 100 characters
    integer uart_buffer_index = 0;
    logic fib_finish_detected = 0;
    logic all_pass_detected = 0;
    logic uart_t_triggered = 0;
    logic trigger_uart_t = 0;
    logic trigger_finish = 0;
    
    // Variables for string detection (declared outside always blocks)
    integer str_detect_i;
    logic   str_match_found;
    integer str_idx1, str_idx2, str_idx3, str_idx4, str_idx5, str_idx6, str_idx7, str_idx8, str_idx9, str_idx10, str_idx11;
    
    // For UART monitoring (declared outside always blocks)
    logic [7:0] uart_char;
    integer     buf_idx;
    
    // Event for string detection
    event uart_char_received;
    
    // Timeout: 10 million cycles (200ms at 50MHz)
    localparam integer TIMEOUT_CYCLES = 10_000_000;
    
    // ==========================================================
    // Initialize Log Files
    // ==========================================================
    initial begin
        trace_wb_fd = $fopen("trace_wb.log", "w");
        trace_pipeline_fd = $fopen("trace_pipeline.log", "w");
        trace_memory_fd = $fopen("trace_memory.log", "w");
        trace_uart_fd = $fopen("trace_uart.log", "w");
        trace_bus_fd = $fopen("trace_bus.log", "w");
        trace_hazard_fd = $fopen("trace_hazard.log", "w");
        trace_summary_fd = $fopen("trace_summary.log", "w");
        
        if (trace_wb_fd == 0 || trace_pipeline_fd == 0 || trace_memory_fd == 0 ||
            trace_uart_fd == 0 || trace_bus_fd == 0 || trace_hazard_fd == 0 || trace_summary_fd == 0) begin
            $display("ERROR: Failed to open one or more log files");
            $finish;
        end
        
        $display("==========================================");
        $display("SOC Benchtest Simulation Started");
        $display("==========================================");
        $fdisplay(trace_summary_fd, "SOC Benchtest Simulation Log");
        $fdisplay(trace_summary_fd, "Started at: %t", $time);
        $fdisplay(trace_summary_fd, "");
    end
    
    // ==========================================================
    // Cycle Counter
    // ==========================================================
    always @(posedge clk) begin
        if (locked) begin
            cycle_count <= cycle_count + 1;
            
            // Timeout check
            if (cycle_count > TIMEOUT_CYCLES) begin
                $display("ERROR: Simulation timeout after %d cycles", TIMEOUT_CYCLES);
                $fdisplay(trace_summary_fd, "ERROR: Simulation timeout after %d cycles", TIMEOUT_CYCLES);
                $finish;
            end
        end
    end
    
    // ==========================================================
    // WB Stage Trace Logging (for golden trace comparison)
    // ==========================================================
    always @(posedge clk) begin
        if (locked && debug_wb_rf_wen && debug_wb_rf_wnum != 5'd0) begin
            inst_count <= inst_count + 1;
            
            // Write to trace_wb.log (format: PC WE RD WDATA)
            $fdisplay(trace_wb_fd, "%08x %1d %02d %08x",
                     debug_wb_pc, debug_wb_rf_wen,
                     debug_wb_rf_wnum, debug_wb_rf_wdata);
            $fflush(trace_wb_fd);
            
            // Console output
            if (inst_count % 100 == 0) begin
                $display("[Cycle %d] Instruction %d: PC=0x%08x, WNUM=%02d, WDATA=0x%08x",
                         cycle_count, inst_count, debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
            end
        end
    end
    
    // ==========================================================
    // Pipeline Stage Logging
    // ==========================================================
    always @(posedge clk) begin
        if (locked) begin
            // Log pipeline stages
            $fdisplay(trace_pipeline_fd, "[Cycle %d] IF: PC=0x%08x, STALL=%b, BR_TAKEN=%b",
                     cycle_count, debug_if_pc, debug_stall, debug_br_taken);
            $fdisplay(trace_pipeline_fd, "[Cycle %d] ID: PC=0x%08x", cycle_count, debug_id_pc);
            $fdisplay(trace_pipeline_fd, "[Cycle %d] EXE: PC=0x%08x, RA1=%02d, RA2=%02d, FORWARD_A_MEM=%b, FORWARD_A_WB=%b, FORWARD_B_MEM=%b, FORWARD_B_WB=%b, FINAL_SRC1=0x%08x, FINAL_SRC2=0x%08x, EXE_SRC2_I=0x%08x, MEM_WA=%02d, MEM_WD=0x%08x, WB_WA=%02d, WB_WD=0x%08x",
                     cycle_count, debug_exe_pc, debug_exe_ra1, debug_exe_ra2, 
                     debug_forward_a_mem, debug_forward_a_wb, debug_forward_b_mem, debug_forward_b_wb,
                     debug_final_src1, debug_final_src2, debug_exe_src2_i,
                     debug_mem_wa_i, debug_mem_wd_i, debug_wb_wa_i, debug_wb_wd_i);
            $fdisplay(trace_pipeline_fd, "[Cycle %d] EXE_FORWARD: SRC1_REG=0x%08x, MEM_WREG=%b, MEM_WA=%02d, MEM_WD=0x%08x, WB_WREG=%b, WB_WA=%02d, WB_WD=0x%08x, WB_WREG_DELAYED=%b, WB_WA_DELAYED=%02d, WB_WD_DELAYED=0x%08x",
                     cycle_count, debug_exe_src1_i, debug_mem_wreg_i, debug_mem_wa_i, debug_mem_wd_i,
                     debug_wb_wreg_i, debug_wb_wa_i, debug_wb_wd_i,
                     debug_wb_wreg_i_delayed, debug_wb_wa_i_delayed, debug_wb_wd_i_delayed);
            // Enhanced forwarding debug: compare memwb_reg, wb_stage, passed to exe_stage, exe_stage internal, and exe_stage inputs
            if (debug_memwb_wreg && debug_memwb_wa != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_PATH: MEMWB_REG[WREG=%b,WA=%02d,WD=0x%08x] -> WB_STAGE[WREG=%b,WA=%02d,WD=0x%08x] -> PASSED_TO_EXE[WREG=%b,WA=%02d,WD=0x%08x] -> EXE_INPUT_INTERNAL[WREG=%b,WA=%02d,WD=0x%08x] -> EXE_INPUT[WREG=%b,WA=%02d,WD=0x%08x] -> FORWARD_A_WB_COND=%b, DELAYED[WREG=%b,WA=%02d,WD=0x%08x]",
                         cycle_count,
                         debug_memwb_wreg, debug_memwb_wa, debug_memwb_wd,
                         debug_wb_wreg, debug_wb_wa, debug_wb_wd,
                         debug_exe_wb_wreg_i, debug_exe_wb_wa_i, debug_exe_wb_wd_i,
                         debug_exe_wb_wreg_i_internal, debug_exe_wb_wa_i_internal, debug_exe_wb_wd_i_internal,
                         debug_wb_wreg_i, debug_wb_wa_i, debug_wb_wd_i,
                         debug_forward_a_wb_condition,
                         debug_wb_wreg_i_delayed, debug_wb_wa_i_delayed, debug_wb_wd_i_delayed);
                // Detailed forwarding condition breakdown
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_COND_DETAIL: WB_WREG_I=%b, WB_WA_I=%02d, WB_WA_I_NOT_ZERO=%b, EXE_RA1_I=%02d, WB_WA_I_EQ_RA1=%b, FORWARD_A_WB=%b",
                         cycle_count,
                         debug_wb_wreg_i_value,
                         debug_wb_wa_i_value,
                         debug_wb_wa_i_not_zero,
                         debug_exe_ra1_i_value,
                         debug_wb_wa_i_eq_ra1,
                         debug_forward_a_wb_condition);
                // Detailed MEM stage forwarding condition breakdown
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_COND_DETAIL_MEM: MEM_WREG_I=%b, MEM_WA_I=%02d, MEM_WA_I_NOT_ZERO=%b, EXE_RA1_I=%02d, MEM_WA_I_EQ_RA1=%b, FORWARD_A_MEM=%b",
                         cycle_count,
                         debug_mem_wreg_i_value,
                         debug_mem_wa_i_value,
                         debug_mem_wa_i_not_zero,
                         debug_exe_ra1_i_value,
                         debug_mem_wa_i_eq_ra1,
                         debug_forward_a_mem_condition);
                // Forwarding timing debug: show all input signals used in forwarding calculation
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_TIMING: MEMWB_REG_OUT[WREG=%b,WA=%02d,WD=0x%08x] -> WB_STAGE_OUT[WREG=%b,WA=%02d,WD=0x%08x] -> EXE_RA1_I=%02d, EXE_RA2_I=%02d",
                         cycle_count,
                         debug_memwb_wreg, debug_memwb_wa, debug_memwb_wd,
                         debug_wb_wreg, debug_wb_wa, debug_wb_wd,
                         debug_exe_ra1_i_value, debug_exe_ra2_i_value);
            end
            if (debug_mem_wreg && debug_mem_wa != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] MEM: PC=0x%08x, WREG=%b, WA=%02d, WD=0x%08x, EXE_PC=0x%08x",
                         cycle_count, debug_mem_pc, debug_mem_wreg, debug_mem_wa, debug_mem_wd, debug_exe_pc);
            end else begin
            $fdisplay(trace_pipeline_fd, "[Cycle %d] MEM: PC=0x%08x", cycle_count, debug_mem_pc);
            end
            if (debug_wb_rf_wen && debug_wb_rf_wnum != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] WB: PC=0x%08x, WEN=%b, WNUM=%02d, WDATA=0x%08x",
                         cycle_count, debug_wb_pc, debug_wb_rf_wen, debug_wb_rf_wnum, debug_wb_rf_wdata);
            end
            // Additional forwarding debug info
            // MEMWB_REG timing (input and output)
            if (debug_memwb_wreg_in && debug_memwb_wa_in != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] MEMWB_REG_TIMING: INPUT[WREG=%b,WA=%02d,WD=0x%08x] -> OUTPUT[WREG=%b,WA=%02d,WD=0x%08x], DELAYED[WREG=%b,WA=%02d,WD=0x%08x]",
                         cycle_count,
                         debug_memwb_wreg_in, debug_memwb_wa_in, debug_memwb_wd_in,
                         debug_memwb_wreg, debug_memwb_wa, debug_memwb_wd,
                         debug_wb_wreg_i_delayed, debug_wb_wa_i_delayed, debug_wb_wd_i_delayed);
            end
            // EXEMEM_REG timing debug: show input and output of exemem_reg
            if (debug_exemem_wreg_in && debug_exemem_wa_in != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] EXEMEM_REG_TIMING: INPUT[WREG=%b,WA=%02d,WD=0x%08x] -> OUTPUT[WREG=%b,WA=%02d,WD=0x%08x]",
                         cycle_count,
                         debug_exemem_wreg_in, debug_exemem_wa_in, debug_exemem_wd_in,
                         debug_exemem_wreg, debug_exemem_wa, debug_exemem_wd);
            end
            // EXEMEM_REG to EXE_STAGE debug: show exemem_reg output and exe_stage input
            if (debug_exemem_to_exe_wreg && debug_exemem_to_exe_wa != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] EXEMEM_TO_EXE: EXEMEM_REG_OUT[WREG=%b,WA=%02d,WD=0x%08x] -> EXE_STAGE_INPUT[WREG=%b,WA=%02d,WD=0x%08x]",
                         cycle_count,
                         debug_exemem_to_exe_wreg, debug_exemem_to_exe_wa, debug_exemem_to_exe_wd,
                         debug_mem_wreg_i, debug_mem_wa_i, debug_mem_wd_i);
            end
            // Signal trace for mem_wa_i: show exemem_reg output, mem_wa_i wire, and exe_stage input
            if (debug_exemem_reg_mem_wa != 5'd0 || debug_mem_wa_i_wire != 5'd0 || debug_exe_stage_mem_wa_i != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] SIGNAL_TRACE_MEM_WA: EXEMEM_REG_MEM_WA=%02d, MEM_WA_I_WIRE=%02d, EXE_STAGE_MEM_WA_I=%02d",
                         cycle_count,
                         debug_exemem_reg_mem_wa, debug_mem_wa_i_wire, debug_exe_stage_mem_wa_i);
            end
            // Forward calculation detail: show complete forward_a_mem calculation process
            if (debug_forward_a_mem_calc_result || debug_forward_a_mem_calc_mem_wreg_i) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_CALC_DETAIL: MEM_WREG_I=%b, MEM_WA_I=%02d, MEM_WA_I_NOT_ZERO=%b, EXE_RA1_I=%02d, MEM_WA_I_EQ_RA1=%b, FORWARD_A_MEM=%b, MEM_WA_I_AT_ASSIGN=%02d, MEM_WA_I_AT_FORWARD_CALC=%02d",
                         cycle_count,
                         debug_forward_a_mem_calc_mem_wreg_i,
                         debug_forward_a_mem_calc_mem_wa_i,
                         debug_forward_a_mem_calc_mem_wa_i_not_zero,
                         debug_forward_a_mem_calc_exe_ra1_i,
                         debug_forward_a_mem_calc_mem_wa_i_eq_ra1,
                         debug_forward_a_mem_calc_result,
                         debug_mem_wa_i_at_assign,
                         debug_mem_wa_i_at_forward_calc);
            end
            // MEM_WA_I trace: show mem_wa_i values at different locations
            if (debug_mem_wa_i_at_assign != 5'd0 || debug_mem_wa_i_at_forward_calc != 5'd0 || debug_mem_wa_i != 5'd0 || debug_exe_stage_mem_wa_i != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] MEM_WA_I_TRACE: AT_ASSIGN=%02d, AT_FORWARD_CALC=%02d, DEBUG_MEM_WA_I=%02d, EXE_STAGE_MEM_WA_I=%02d, EXEMEM_REG_MEM_WA=%02d, MEM_WA_I_WIRE=%02d",
                         cycle_count,
                         debug_mem_wa_i_at_assign,
                         debug_mem_wa_i_at_forward_calc,
                         debug_mem_wa_i,
                         debug_exe_stage_mem_wa_i,
                         debug_exemem_reg_mem_wa,
                         debug_mem_wa_i_wire);
            end
            // Timing comparison: compare mem_wa_i values at different time points
            if (debug_forward_a_mem_calc_result || (debug_mem_wa_i_at_assign != debug_mem_wa_i_at_forward_calc) || (debug_mem_wa_i != debug_exe_stage_mem_wa_i)) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] TIMING_COMPARISON: MEM_WA_I_AT_ASSIGN=%02d, MEM_WA_I_AT_FORWARD_CALC=%02d, DEBUG_MEM_WA_I=%02d, EXE_STAGE_MEM_WA_I=%02d, MATCH_ASSIGN_CALC=%b, MATCH_DEBUG_EXE=%b",
                         cycle_count,
                         debug_mem_wa_i_at_assign,
                         debug_mem_wa_i_at_forward_calc,
                         debug_mem_wa_i,
                         debug_exe_stage_mem_wa_i,
                         (debug_mem_wa_i_at_assign == debug_mem_wa_i_at_forward_calc),
                         (debug_mem_wa_i == debug_exe_stage_mem_wa_i));
            end
            // IDEXE_REG timing (input and output for ra1/ra2)
            if (debug_idexe_ra1_in != 5'd0 || debug_idexe_ra2_in != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] IDEXE_REG_TIMING: INPUT[RA1=%02d,RA2=%02d] -> OUTPUT[RA1=%02d,RA2=%02d]",
                         cycle_count,
                         debug_idexe_ra1_in, debug_idexe_ra2_in,
                         debug_idexe_ra1_out, debug_idexe_ra2_out);
            end
            // WB_STAGE output (wb_stage output, should match FORWARD_WB)
            if (debug_wb_wreg && debug_wb_wa != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_WB: WREG=%b, WA=%02d, WD=0x%08x",
                         cycle_count, debug_wb_wreg, debug_wb_wa, debug_wb_wd);
            end
            if (debug_mem_wreg && debug_mem_wa != 5'd0) begin
                $fdisplay(trace_pipeline_fd, "[Cycle %d] FORWARD_MEM: WREG=%b, WA=%02d, WD=0x%08x",
                         cycle_count, debug_mem_wreg, debug_mem_wa, debug_mem_wd);
            end
            $fflush(trace_pipeline_fd);
        end
    end
    
    // ==========================================================
    // Memory Access Logging (monitor CPU memory interface)
    // ==========================================================
    logic [31:0] prev_mem_addr = 32'h0;
    logic        prev_mem_we = 1'b0;
    logic [31:0] prev_cpu_mem_addr = 32'h0;
    logic        prev_cpu_mem_we = 1'b0;
    localparam logic [31:0] UART_STAT_ADDR_MON = 32'hBFD0_03FC;
    localparam logic [31:0] UART_DATA_ADDR_MON = 32'hBFD0_03F8;
    
    always @(posedge clk) begin
        if (locked) begin
            // Monitor CPU memory interface (need to access internal signals)
            // Note: This is a simplified version. In real implementation,
            // you may need to add debug ports to access mem_addr, mem_we, etc.
            
            // Log inst_rom access (IF stage)
            if (debug_if_pc != prev_mem_addr) begin
                $fdisplay(trace_memory_fd, "[Cycle %d] INST_ROM: ADDR=0x%04x (IF stage fetch)",
                         cycle_count, debug_if_pc[15:2]);
                $fflush(trace_memory_fd);
            end
            
            // Log all memory reads (especially byte loads from .text)
            if (!debug_cpu_mem_we && (debug_cpu_mem_addr >= 32'h80000000) && (debug_cpu_mem_addr < 32'h80010000)) begin
                // This is a read from .text segment (instruction ROM)
                if ((prev_cpu_mem_addr != debug_cpu_mem_addr) || (prev_cpu_mem_we && !debug_cpu_mem_we)) begin
                    $fdisplay(trace_memory_fd, "[Cycle %d] TEXT_READ: ADDR=0x%08x, ROM_ADDR=0x%08x, ROM_RDATA_BE=0x%08x, ROM_RDATA_LE=0x%08x, CPU_RDATA=0x%08x, BYTE[1:0]=%b",
                             cycle_count, debug_cpu_mem_addr, debug_inst_rom_addr, debug_inst_rom_rdata, 
                             debug_inst_rom_rdata_swapped, debug_cpu_mem_rdata, debug_cpu_mem_addr[1:0]);
                    // If this is a byte load, show which byte would be selected
                    if (debug_cpu_mem_addr[1:0] == 2'b00) begin
                        $fdisplay(trace_memory_fd, "  -> Byte selected from CPU_RDATA[7:0]: 0x%02x ('%c')", 
                                 debug_cpu_mem_rdata[7:0], 
                                 (debug_cpu_mem_rdata[7:0] >= 32 && debug_cpu_mem_rdata[7:0] < 127) ? debug_cpu_mem_rdata[7:0] : 63);
                        $fdisplay(trace_memory_fd, "  -> ROM word (BE): 0x%08x, bytes: [7:0]=0x%02x, [15:8]=0x%02x, [23:16]=0x%02x, [31:24]=0x%02x",
                                 debug_inst_rom_rdata, debug_inst_rom_rdata[7:0], debug_inst_rom_rdata[15:8],
                                 debug_inst_rom_rdata[23:16], debug_inst_rom_rdata[31:24]);
                        $fdisplay(trace_memory_fd, "  -> ROM word (LE): 0x%08x, bytes: [7:0]=0x%02x, [15:8]=0x%02x, [23:16]=0x%02x, [31:24]=0x%02x",
                                 debug_inst_rom_rdata_swapped, debug_inst_rom_rdata_swapped[7:0], debug_inst_rom_rdata_swapped[15:8],
                                 debug_inst_rom_rdata_swapped[23:16], debug_inst_rom_rdata_swapped[31:24]);
                    end else if (debug_cpu_mem_addr[1:0] == 2'b01) begin
                        $fdisplay(trace_memory_fd, "  -> Byte selected from CPU_RDATA[15:8]: 0x%02x ('%c')", 
                                 debug_cpu_mem_rdata[15:8], 
                                 (debug_cpu_mem_rdata[15:8] >= 32 && debug_cpu_mem_rdata[15:8] < 127) ? debug_cpu_mem_rdata[15:8] : 63);
                    end else if (debug_cpu_mem_addr[1:0] == 2'b10) begin
                        $fdisplay(trace_memory_fd, "  -> Byte selected from CPU_RDATA[23:16]: 0x%02x ('%c')", 
                                 debug_cpu_mem_rdata[23:16], 
                                 (debug_cpu_mem_rdata[23:16] >= 32 && debug_cpu_mem_rdata[23:16] < 127) ? debug_cpu_mem_rdata[23:16] : 63);
                    end else begin
                        $fdisplay(trace_memory_fd, "  -> Byte selected from CPU_RDATA[31:24]: 0x%02x ('%c')", 
                                 debug_cpu_mem_rdata[31:24], 
                                 (debug_cpu_mem_rdata[31:24] >= 32 && debug_cpu_mem_rdata[31:24] < 127) ? debug_cpu_mem_rdata[31:24] : 63);
                    end
                    $fflush(trace_memory_fd);
                end
            end
            
            // Log UART status register reads - detect when address matches and it's a read operation
            // Check if this is a new read operation (address changed or we->!we transition)
            if (!debug_cpu_mem_we && (debug_cpu_mem_addr == UART_STAT_ADDR_MON) &&
                ((prev_cpu_mem_addr != UART_STAT_ADDR_MON) || (prev_cpu_mem_we && !debug_cpu_mem_we))) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_STAT_READ: ADDR=0x%08x, RDATA=0x%08x, STATUS[1:0]=%b, BUSY=%b, PENDING=%b, STATUS_BIT0=%b, STATUS_BIT1=%b, PC=0x%08x, EXE_PC=0x%08x",
                         cycle_count, debug_cpu_mem_addr, debug_cpu_mem_rdata, 
                         debug_uart_status, debug_uart_busy, debug_uart_tx_pending,
                         debug_uart_status[0], debug_uart_status[1], debug_wb_pc, debug_exe_pc);
                $fflush(trace_uart_fd);
            end
            
            // Log UART data register reads (if any)
            if (!debug_cpu_mem_we && 
                ((debug_cpu_mem_addr & 32'hFFFFFFFC) == (UART_DATA_ADDR_MON & 32'hFFFFFFFC)) &&
                ((prev_cpu_mem_addr != debug_cpu_mem_addr) || (prev_cpu_mem_we && !debug_cpu_mem_we))) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_DATA_READ: ADDR=0x%08x, RDATA=0x%08x",
                         cycle_count, debug_cpu_mem_addr, debug_cpu_mem_rdata);
                $fflush(trace_uart_fd);
            end
            
            // Log all memory reads to UART address range for debugging
            if (!debug_cpu_mem_we && 
                ((debug_cpu_mem_addr & 32'hFFFF0000) == 32'hBFD00000) &&
                ((prev_cpu_mem_addr != debug_cpu_mem_addr) || (prev_cpu_mem_we && !debug_cpu_mem_we))) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_REGION_READ: ADDR=0x%08x, RDATA=0x%08x",
                         cycle_count, debug_cpu_mem_addr, debug_cpu_mem_rdata);
                $fflush(trace_uart_fd);
            end
            
            prev_mem_addr <= debug_if_pc;
            prev_mem_we <= debug_cpu_mem_we;
            prev_cpu_mem_addr <= debug_cpu_mem_addr;
            prev_cpu_mem_we <= debug_cpu_mem_we;
        end
    end
    
    // ==========================================================
    // UART Monitoring and Simulation
    // ==========================================================
    // Monitor CPU memory writes to UART data register (0xBFD0_03F8)
    // This is more reliable than monitoring UART internal signals
    // Note: UART_DATA_ADDR_MON and prev_cpu_mem_we are already declared in Memory Access Logging section
    
    // UART TX monitoring: detect when CPU writes to UART data register
    logic prev_uart_busy = 1'b0;
    logic prev_uart_tx_pending = 1'b0;
    logic [1:0] prev_uart_status = 2'b0;
    logic prev_cpu_write_uart_data = 1'b0;
    logic prev_ext_uart_start = 1'b0;
    // UART RX monitoring
    logic prev_uart_rx_ready = 1'b0;
    logic prev_uart_rx_avai = 1'b0;
    logic [7:0] prev_uart_rx_buffer = 8'h0;
    logic prev_uart_rx_clear = 1'b0;
    logic prev_cpu_read_uart_data = 1'b0;
    
    always @(posedge clk) begin
        if (locked) begin
            // Log UART state changes
            if (debug_uart_busy != prev_uart_busy || 
                debug_uart_tx_pending != prev_uart_tx_pending ||
                debug_uart_status != prev_uart_status ||
                debug_ext_uart_start != prev_ext_uart_start) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_STATE_CHANGE: BUSY=%b->%b, PENDING=%b->%b, STATUS=%b->%b, START=%b->%b",
                         cycle_count, prev_uart_busy, debug_uart_busy,
                         prev_uart_tx_pending, debug_uart_tx_pending,
                         prev_uart_status, debug_uart_status,
                         prev_ext_uart_start, debug_ext_uart_start);
                $fflush(trace_uart_fd);
            end
            
            // Log all CPU memory writes for debugging
            if (!prev_cpu_mem_we && debug_cpu_mem_we) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] CPU_MEM_WRITE: ADDR=0x%08x, DATA=0x%08x, SEL_UART=%b, CPU_WRITE_UART_DATA=%b, PC=0x%08x, EXE_PC=0x%08x",
                         cycle_count, debug_cpu_mem_addr, debug_cpu_mem_wdata, 
                         debug_sel_uart, debug_cpu_write_uart_data, debug_wb_pc, debug_exe_pc);
                $fflush(trace_uart_fd);
            end
            
            // Log all CPU memory reads for debugging (especially UART-related)
            if (prev_cpu_mem_we && !debug_cpu_mem_we && 
                ((debug_cpu_mem_addr & 32'hFFFF0000) == 32'hBFD00000)) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] CPU_MEM_READ: ADDR=0x%08x, RDATA=0x%08x, SEL_UART=%b, PC=0x%08x, EXE_PC=0x%08x",
                         cycle_count, debug_cpu_mem_addr, debug_cpu_mem_rdata, 
                         debug_sel_uart, debug_wb_pc, debug_exe_pc);
                $fflush(trace_uart_fd);
            end
            
            // Log UART send logic details when CPU writes to UART
            if (debug_cpu_write_uart_data && !prev_cpu_write_uart_data) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_WRITE_LOGIC: CPU_WRITE=1, BYTE_TO_SEND=0x%02x, BUSY=%b, START=%b, PENDING=%b, BUFFER=0x%02x, ADDR=0x%08x",
                         cycle_count, debug_byte_to_send, debug_uart_busy, 
                         debug_ext_uart_start, debug_uart_tx_pending, debug_uart_tx_buffer, debug_cpu_mem_addr);
                $fflush(trace_uart_fd);
            end
            
            // Log when pending data is sent
            if (debug_uart_tx_pending != prev_uart_tx_pending && !debug_uart_tx_pending && prev_uart_tx_pending) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_PENDING_SENT: PENDING cleared, BUFFER=0x%02x, BUSY=%b, START=%b",
                         cycle_count, debug_uart_tx_buffer, debug_uart_busy, debug_ext_uart_start);
                $fflush(trace_uart_fd);
            end
            
            // Detect CPU write to UART data register (on rising edge of write enable)
            // Support byte-aligned writes (ST.B to 0xBFD003F8/9/FA/FB)
            if (!prev_cpu_mem_we && debug_cpu_mem_we && 
                ((debug_cpu_mem_addr & 32'hFFFFFFFC) == (UART_DATA_ADDR_MON & 32'hFFFFFFFC))) begin
                uart_tx_count <= uart_tx_count + 1;
                
                // Capture the data being written - select correct byte based on address[1:0]
                case (debug_cpu_mem_addr[1:0])
                    2'b00: uart_char = debug_cpu_mem_wdata[7:0];
                    2'b01: uart_char = debug_cpu_mem_wdata[15:8];
                    2'b10: uart_char = debug_cpu_mem_wdata[23:16];
                    2'b11: uart_char = debug_cpu_mem_wdata[31:24];
                    default: uart_char = debug_cpu_mem_wdata[7:0];
                endcase
                
                // Log UART TX with current state
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_TX: DATA=0x%02x ('%c'), ADDR=0x%08x, BUSY=%b, PENDING=%b, STATUS=%b",
                         cycle_count, uart_char, (uart_char >= 32 && uart_char < 127) ? uart_char : 63, 
                         debug_cpu_mem_addr, debug_uart_busy, debug_uart_tx_pending, debug_uart_status);
                $fflush(trace_uart_fd);
                
                // Update output buffer for string detection (use blocking assignment for immediate use)
                uart_output_buffer[uart_buffer_index] = uart_char;
                uart_buffer_index = (uart_buffer_index + 1) % 100;
                
                // Trigger string detection immediately
                -> uart_char_received;
            end
            
            prev_cpu_mem_we <= debug_cpu_mem_we;
            prev_uart_busy <= debug_uart_busy;
            prev_uart_tx_pending <= debug_uart_tx_pending;
            prev_uart_status <= debug_uart_status;
            prev_cpu_write_uart_data <= debug_cpu_write_uart_data;
            prev_ext_uart_start <= debug_ext_uart_start;
            
            // UART RX monitoring: log state changes
            if (debug_uart_rx_ready != prev_uart_rx_ready) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_READY: %b->%b, RX_DATA=0x%02x ('%c')",
                         cycle_count, prev_uart_rx_ready, debug_uart_rx_ready,
                         debug_uart_rx_data, (debug_uart_rx_data >= 32 && debug_uart_rx_data < 127) ? debug_uart_rx_data : 63);
                $fflush(trace_uart_fd);
            end
            
            if (debug_uart_rx_avai != prev_uart_rx_avai) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_AVAI: %b->%b, BUFFER=0x%02x ('%c')",
                         cycle_count, prev_uart_rx_avai, debug_uart_rx_avai,
                         debug_uart_rx_buffer, (debug_uart_rx_buffer >= 32 && debug_uart_rx_buffer < 127) ? debug_uart_rx_buffer : 63);
                $fflush(trace_uart_fd);
            end
            
            if (debug_uart_rx_buffer != prev_uart_rx_buffer && debug_uart_rx_avai) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_BUFFER_CHANGE: 0x%02x->0x%02x ('%c'->'%c')",
                         cycle_count, prev_uart_rx_buffer, debug_uart_rx_buffer,
                         (prev_uart_rx_buffer >= 32 && prev_uart_rx_buffer < 127) ? prev_uart_rx_buffer : 63,
                         (debug_uart_rx_buffer >= 32 && debug_uart_rx_buffer < 127) ? debug_uart_rx_buffer : 63);
                $fflush(trace_uart_fd);
            end
            
            if (debug_uart_rx_clear != prev_uart_rx_clear && debug_uart_rx_clear) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_CLEAR: Asserted, BUFFER=0x%02x, AVAI=%b",
                         cycle_count, debug_uart_rx_buffer, debug_uart_rx_avai);
                $fflush(trace_uart_fd);
            end
            
            if (debug_cpu_read_uart_data != prev_cpu_read_uart_data && debug_cpu_read_uart_data) begin
                $fdisplay(trace_uart_fd, "[Cycle %d] CPU_READ_UART_DATA: ADDR=0x%08x, RDATA=0x%08x, BUFFER=0x%02x ('%c'), AVAI=%b->%b",
                         cycle_count, debug_cpu_mem_addr, debug_cpu_mem_rdata,
                         debug_uart_rx_buffer, (debug_uart_rx_buffer >= 32 && debug_uart_rx_buffer < 127) ? debug_uart_rx_buffer : 63,
                         prev_uart_rx_avai, debug_uart_rx_avai);
                $fflush(trace_uart_fd);
            end
            
            prev_uart_rx_ready <= debug_uart_rx_ready;
            prev_uart_rx_avai <= debug_uart_rx_avai;
            prev_uart_rx_buffer <= debug_uart_rx_buffer;
            prev_uart_rx_clear <= debug_uart_rx_clear;
            prev_cpu_read_uart_data <= debug_cpu_read_uart_data;
        end
    end
    
    // String detection process (triggered when UART character received)
    always @(uart_char_received) begin
        // Wait a bit for non-blocking assignment to complete
        #10;
        
        // Debug: print buffer contents
        if (uart_buffer_index > 0) begin
            integer j;
            $display("[Cycle %d] UART buffer (last 20 chars):", cycle_count);
            for (j = 0; (j < 20) && (j < uart_buffer_index); j = j + 1) begin
                buf_idx = (uart_buffer_index - 20 + j + 100) % 100;
                $write("0x%02x ", uart_output_buffer[buf_idx]);
            end
            $display("");
        end
        
        // Pattern: 'F'=0x46, 'i'=0x69, 'b'=0x62, ' '=0x20, 'F'=0x46, 'i'=0x69, 'n'=0x6e, 'i'=0x69, 's'=0x73, 'h'=0x68, '.'=0x2e
        if (!$test$plusargs("NO_FIB_CHECK") && !fib_finish_detected) begin
            // Check last 20 characters for pattern
            str_match_found = 0;
            for (str_detect_i = 0; str_detect_i < 20; str_detect_i = str_detect_i + 1) begin
                str_idx1 = (uart_buffer_index - 11 - str_detect_i + 100) % 100;
                str_idx2 = (uart_buffer_index - 10 - str_detect_i + 100) % 100;
                str_idx3 = (uart_buffer_index - 9 - str_detect_i + 100) % 100;
                str_idx4 = (uart_buffer_index - 8 - str_detect_i + 100) % 100;
                str_idx5 = (uart_buffer_index - 7 - str_detect_i + 100) % 100;
                str_idx6 = (uart_buffer_index - 6 - str_detect_i + 100) % 100;
                str_idx7 = (uart_buffer_index - 5 - str_detect_i + 100) % 100;
                str_idx8 = (uart_buffer_index - 4 - str_detect_i + 100) % 100;
                str_idx9 = (uart_buffer_index - 3 - str_detect_i + 100) % 100;
                str_idx10 = (uart_buffer_index - 2 - str_detect_i + 100) % 100;
                str_idx11 = (uart_buffer_index - 1 - str_detect_i + 100) % 100;
                
                if (uart_output_buffer[str_idx1] == 8'h46 &&  // 'F'
                    uart_output_buffer[str_idx2] == 8'h69 &&  // 'i'
                    uart_output_buffer[str_idx3] == 8'h62 &&  // 'b'
                    uart_output_buffer[str_idx4] == 8'h20 &&  // ' '
                    uart_output_buffer[str_idx5] == 8'h46 &&  // 'F'
                    uart_output_buffer[str_idx6] == 8'h69 &&  // 'i'
                    uart_output_buffer[str_idx7] == 8'h6e &&  // 'n'
                    uart_output_buffer[str_idx8] == 8'h69 &&  // 'i'
                    uart_output_buffer[str_idx9] == 8'h73 &&  // 's'
                    uart_output_buffer[str_idx10] == 8'h68 && // 'h'
                    uart_output_buffer[str_idx11] == 8'h2e) begin // '.'
                    str_match_found = 1;
                    str_detect_i = 20;  // Exit loop
                end
            end
            
            if (str_match_found) begin
                fib_finish_detected <= 1;
                trigger_uart_t <= 1;
                $display("==========================================");
                $display("SUCCESS: 'Fib Finish.' detected at cycle %d", cycle_count);
                $display("==========================================");
                $fdisplay(trace_summary_fd, "SUCCESS: 'Fib Finish.' detected at cycle %d", cycle_count);
                $fdisplay(trace_uart_fd, "[Cycle %d] FIB_FINISH_DETECTED: Triggering UART 'T' send", cycle_count);
                $fflush(trace_uart_fd);
            end
        end
        
        // Detect "All PASS!" pattern
        // Pattern: 'A'=0x41, 'l'=0x6c, 'l'=0x6c, ' '=0x20, 'P'=0x50, 'A'=0x41, 'S'=0x53, 'S'=0x53, '!'=0x21
        if (!$test$plusargs("NO_PASS_CHECK") && !all_pass_detected) begin
            // Check last 20 characters for pattern
            str_match_found = 0;
            for (str_detect_i = 0; str_detect_i < 20; str_detect_i = str_detect_i + 1) begin
                str_idx1 = (uart_buffer_index - 9 - str_detect_i + 100) % 100;
                str_idx2 = (uart_buffer_index - 8 - str_detect_i + 100) % 100;
                str_idx3 = (uart_buffer_index - 7 - str_detect_i + 100) % 100;
                str_idx4 = (uart_buffer_index - 6 - str_detect_i + 100) % 100;
                str_idx5 = (uart_buffer_index - 5 - str_detect_i + 100) % 100;
                str_idx6 = (uart_buffer_index - 4 - str_detect_i + 100) % 100;
                str_idx7 = (uart_buffer_index - 3 - str_detect_i + 100) % 100;
                str_idx8 = (uart_buffer_index - 2 - str_detect_i + 100) % 100;
                str_idx9 = (uart_buffer_index - 1 - str_detect_i + 100) % 100;
                
                if (uart_output_buffer[str_idx1] == 8'h41 &&  // 'A'
                    uart_output_buffer[str_idx2] == 8'h6c &&  // 'l'
                    uart_output_buffer[str_idx3] == 8'h6c &&  // 'l'
                    uart_output_buffer[str_idx4] == 8'h20 &&  // ' '
                    uart_output_buffer[str_idx5] == 8'h50 &&  // 'P'
                    uart_output_buffer[str_idx6] == 8'h41 &&  // 'A'
                    uart_output_buffer[str_idx7] == 8'h53 &&  // 'S'
                    uart_output_buffer[str_idx8] == 8'h53 &&  // 'S'
                    uart_output_buffer[str_idx9] == 8'h21) begin // '!'
                    str_match_found = 1;
                    str_detect_i = 20;  // Exit loop
                end
            end
            
            if (str_match_found) begin
                all_pass_detected <= 1;
                trigger_finish <= 1;
                $display("==========================================");
                $display("SUCCESS: 'All PASS!' detected at cycle %d", cycle_count);
                $display("==========================================");
                $fdisplay(trace_summary_fd, "SUCCESS: 'All PASS!' detected at cycle %d", cycle_count);
            end
        end
    end
    
    // ==========================================================
    // UART RX: Send character function
    // ==========================================================
    task automatic send_uart_char(logic [7:0] char);
        integer i;
        `ifdef SIMULATION
        // In simulation mode, send one bit per clock cycle (20ns at 50MHz)
        integer bit_delay = 20;  // 1 clock cycle = 20ns
        `else
        integer baud_delay = 104167;  // 1 bit time at 9600 baud (1/9600 * 1e9 ns)
        `endif
        
        $display("[%t] Sending UART character: 0x%02x ('%c')", $time, char, char);
        $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_SEND: Starting transmission of DATA=0x%02x ('%c')",
                 cycle_count, char, char);
        $fflush(trace_uart_fd);
        
        `ifdef SIMULATION
        // Start bit
        rxd = 0;
        $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_SEND: Start bit (rxd=0)", cycle_count);
        $fflush(trace_uart_fd);
        #(bit_delay);
        
        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rxd = char[i];
            $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_SEND: Bit %d = %b (rxd=%b)", 
                     cycle_count, i, char[i], rxd);
            $fflush(trace_uart_fd);
            #(bit_delay);
        end
        
        // Stop bit
        rxd = 1;
        $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_SEND: Stop bit (rxd=1)", cycle_count);
        $fflush(trace_uart_fd);
        #(bit_delay);
        `else
        // Start bit
        rxd = 0;
        #(baud_delay);
        
        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rxd = char[i];
            #(baud_delay);
        end
        
        // Stop bit
        rxd = 1;
        #(baud_delay);
        `endif
        
        uart_rx_count = uart_rx_count + 1;
        uart_t_triggered = 1;
        $fdisplay(trace_uart_fd, "[Cycle %d] UART_RX_SEND: Transmission complete, RX_COUNT=%d", 
                 cycle_count, uart_rx_count);
        $fflush(trace_uart_fd);
    endtask
    
    // ==========================================================
    // Handle UART 'T' trigger and finish trigger
    // ==========================================================
    // Handle UART 'T' character sending
    // Use always block to monitor trigger_uart_t changes
    always @(posedge trigger_uart_t) begin
        if (fib_finish_detected && !uart_t_triggered) begin
            uart_t_triggered <= 1;
            #10000;  // Wait 10us (10000ns) for simulation
            $display("[%t] Triggering UART 'T' send after Fib Finish", $time);
            $fdisplay(trace_uart_fd, "[Cycle %d] TRIGGER_UART_T: Sending 'T' character", cycle_count);
            $fflush(trace_uart_fd);
            send_uart_char(8'h54);  // 'T' = 0x54
        end
    end
    
    // Handle test finish
    initial begin
        @(posedge trigger_finish);
        #100000;
        $display("Test completed successfully!");
        $fdisplay(trace_summary_fd, "Test completed successfully!");
        $finish;
    end
    
    // ==========================================================
    // Hazard and Stall Logging
    // ==========================================================
    logic prev_stall = 0;
    logic prev_br_taken = 0;
    
    always @(posedge clk) begin
        if (locked) begin
            if (debug_stall && !prev_stall) begin
                $fdisplay(trace_hazard_fd, "[Cycle %d] STALL asserted", cycle_count);
                $fflush(trace_hazard_fd);
            end
            
            if (debug_br_taken && !prev_br_taken) begin
                $fdisplay(trace_hazard_fd, "[Cycle %d] BRANCH TAKEN: EXE_PC=0x%08x -> IF_PC=0x%08x, FINAL_SRC1=0x%08x, RA1=%02d, RA2=%02d",
                         cycle_count, debug_exe_pc, debug_if_pc, 
                         debug_final_src1, debug_exe_ra1, debug_exe_ra2);
                $fflush(trace_hazard_fd);
                
                // Also log to UART trace if this is related to UART wait loop
                if (debug_exe_pc == 32'h80000094 || debug_exe_pc == 32'h80000098) begin
                    $fdisplay(trace_uart_fd, "[Cycle %d] BRANCH_AT_UART_LOOP: EXE_PC=0x%08x -> IF_PC=0x%08x, FINAL_SRC1=0x%08x, RA1=%02d, RA2=%02d",
                             cycle_count, debug_exe_pc, debug_if_pc, 
                             debug_final_src1, debug_exe_ra1, debug_exe_ra2);
                    $fflush(trace_uart_fd);
                end
            end
            
            prev_stall <= debug_stall;
            prev_br_taken <= debug_br_taken;
        end
    end
    
    // ==========================================================
    // Final Summary
    // ==========================================================
    final begin
        $display("==========================================");
        $display("Simulation Summary");
        $display("==========================================");
        $display("Total Cycles: %d", cycle_count);
        $display("Total Instructions: %d", inst_count);
        $display("UART TX Count: %d", uart_tx_count);
        $display("UART RX Count: %d", uart_rx_count);
        $display("Fib Finish Detected: %b", fib_finish_detected);
        $display("All PASS Detected: %b", all_pass_detected);
        $display("==========================================");
        
        $fdisplay(trace_summary_fd, "");
        $fdisplay(trace_summary_fd, "==========================================");
        $fdisplay(trace_summary_fd, "Simulation Summary");
        $fdisplay(trace_summary_fd, "==========================================");
        $fdisplay(trace_summary_fd, "Total Cycles: %d", cycle_count);
        $fdisplay(trace_summary_fd, "Total Instructions: %d", inst_count);
        $fdisplay(trace_summary_fd, "UART TX Count: %d", uart_tx_count);
        $fdisplay(trace_summary_fd, "UART RX Count: %d", uart_rx_count);
        $fdisplay(trace_summary_fd, "Fib Finish Detected: %b", fib_finish_detected);
        $fdisplay(trace_summary_fd, "All PASS Detected: %b", all_pass_detected);
        $fdisplay(trace_summary_fd, "Ended at: %t", $time);
        $fdisplay(trace_summary_fd, "==========================================");
        
        // Close all log files
        if (trace_wb_fd != 0) $fclose(trace_wb_fd);
        if (trace_pipeline_fd != 0) $fclose(trace_pipeline_fd);
        if (trace_memory_fd != 0) $fclose(trace_memory_fd);
        if (trace_uart_fd != 0) $fclose(trace_uart_fd);
        if (trace_bus_fd != 0) $fclose(trace_bus_fd);
        if (trace_hazard_fd != 0) $fclose(trace_hazard_fd);
        if (trace_summary_fd != 0) $fclose(trace_summary_fd);
        
        $display("All log files closed.");
    end
    
endmodule
