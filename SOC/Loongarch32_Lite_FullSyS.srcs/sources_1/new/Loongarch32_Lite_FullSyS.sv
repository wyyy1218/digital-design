// Top-level SoC for Loongarch32_Lite CPU core
// Integrates: CPU + inst_rom + data_ram + UART + simple board peripherals
module Loongarch32_Lite_FullSyS(
    input  logic        clk,      // 50MHz system clock
    input  logic        locked,   // clock stable indicator

    input  logic        rxd,      // UART RX pin
    output logic        txd,      // UART TX pin

    input  logic [31:0] sw_1,     // first switch group
    input  logic [31:0] sw_2,     // second switch group
    output logic [31:0] led,      // LEDs
    output logic [3:0]  seg_cs,   // 7-seg select
    output logic [7:0]  seg_data, // 7-seg data
    input  logic [7:0]  btn,      // buttons
    
    // Debug signals (for simulation only, remove for board build)
    output logic [31:0] debug_wb_pc,        // WB stage PC
    output logic        debug_wb_rf_wen,     // WB stage register write enable
    output logic [4:0]  debug_wb_rf_wnum,    // WB stage register write number
    output logic [31:0] debug_wb_rf_wdata,   // WB stage register write data
    output logic [31:0] debug_if_pc,         // IF stage PC
    output logic [31:0] debug_id_pc,         // ID stage PC
    output logic [31:0] debug_exe_pc,        // EXE stage PC
    output logic [31:0] debug_mem_pc,        // MEM stage PC
    output logic        debug_stall,          // Pipeline stall signal
    output logic        debug_br_taken,       // Branch taken signal
    
    // Additional debug signals for memory interface monitoring (simulation only)
    output logic [31:0] debug_cpu_mem_addr,   // CPU memory address
    output logic        debug_cpu_mem_we,     // CPU memory write enable
    output logic [31:0] debug_cpu_mem_wdata, // CPU memory write data
    output logic [31:0] debug_cpu_mem_rdata,  // CPU memory read data
    output logic        debug_uart_busy,       // UART busy signal
    output logic        debug_uart_tx_pending, // UART TX pending signal
    output logic [1:0]  debug_uart_status,     // UART status register
    output logic        debug_cpu_write_uart_data, // CPU write to UART data register
    output logic        debug_ext_uart_start,  // UART start signal
    output logic [7:0]  debug_uart_tx_buffer,  // UART TX buffer
    output logic [7:0]  debug_byte_to_send,    // Byte to send
    output logic        debug_sel_uart,        // UART address select signal
    output logic [31:0] debug_inst_rom_addr,   // inst_rom address (reconstructed)
    output logic [31:0] debug_inst_rom_rdata,  // inst_rom read data (big-endian)
    output logic [31:0] debug_inst_rom_rdata_swapped,  // inst_rom read data (little-endian, swapped)
    // UART RX debug signals
    output logic        debug_uart_rx_ready,    // UART RX data ready signal
    output logic [7:0]  debug_uart_rx_data,     // UART RX received data
    output logic        debug_uart_rx_avai,     // UART RX available flag
    output logic [7:0]  debug_uart_rx_buffer,   // UART RX buffer (latched data)
    output logic        debug_uart_rx_clear,    // UART RX clear signal
    output logic        debug_cpu_read_uart_data, // CPU read UART data register signal
    // UART TX state machine debug signal
    output logic [3:0]  debug_uart_txd_state,    // UART TX state machine state

    // TB compatibility debug ports
    output logic        debug_stall_if,
    output logic        debug_mem_read_text,
    
    // Forwarding debug signals
    output logic [4:0]  debug_exe_ra1,         // EXE stage source register 1
    output logic [4:0]  debug_exe_ra2,         // EXE stage source register 2
    output logic        debug_forward_a_mem,   // Forward from MEM for src1
    output logic        debug_forward_a_wb,    // Forward from WB for src1
    output logic [31:0] debug_final_src1,      // Final source 1 value
    output logic [31:0] debug_final_src2,      // Final source 2 value
    output logic [31:0] debug_exe_src2_i,      // EXE stage source 2 (before forwarding)
    output logic        debug_forward_b_mem,   // Forward from MEM for src2
    output logic        debug_forward_b_wb,    // Forward from WB for src2
    output logic        debug_mem_wreg_i,      // MEM stage write enable (for forwarding)
    output logic [4:0]  debug_mem_wa_i,         // MEM stage write address (for forwarding)
    output logic [31:0] debug_mem_wd_i,        // MEM stage write data (for forwarding)
    output logic        debug_wb_wreg_i,       // WB stage write enable (for forwarding)
    output logic [4:0]  debug_wb_wa_i,         // WB stage write address (for forwarding)
    output logic [31:0] debug_wb_wd_i,         // WB stage write data (for forwarding)
    output logic [31:0] debug_exe_src1_i,      // EXE stage source 1 (before forwarding)
    // Debug signals for exe_stage internal input values
    output logic        debug_exe_wb_wreg_i_internal, // exe_stage internal wb_wreg_i
    output logic [4:0]  debug_exe_wb_wa_i_internal,    // exe_stage internal wb_wa_i
    output logic [31:0] debug_exe_wb_wd_i_internal,     // exe_stage internal wb_wd_i
    // Debug signals for forwarding condition calculations
    output logic        debug_forward_a_wb_condition,     // forward_a_wb condition result
    output logic        debug_forward_b_wb_condition,     // forward_b_wb condition result
    output logic        debug_forward_a_mem_condition,    // forward_a_mem condition result
    output logic        debug_forward_b_mem_condition,    // forward_b_mem condition result
    // Debug signals for forwarding condition components
    output logic        debug_wb_wreg_i_value,             // wb_wreg_i value used in forwarding
    output logic [4:0]  debug_wb_wa_i_value,               // wb_wa_i value used in forwarding
    output logic        debug_wb_wa_i_not_zero,            // (wb_wa_i != 0) result
    output logic        debug_wb_wa_i_eq_ra1,              // (wb_wa_i == exe_ra1_i) result
    output logic        debug_wb_wa_i_eq_ra2,              // (wb_wa_i == exe_ra2_i) result
    output logic        debug_mem_wreg_i_value,            // mem_wreg_i value used in forwarding
    output logic [4:0]  debug_mem_wa_i_value,              // mem_wa_i value used in forwarding
    output logic        debug_mem_wa_i_not_zero,          // (mem_wa_i != 0) result
    output logic        debug_mem_wa_i_eq_ra1,            // (mem_wa_i == exe_ra1_i) result
    output logic        debug_mem_wa_i_eq_ra2,             // (mem_wa_i == exe_ra2_i) result
    output logic [4:0]  debug_exe_ra1_i_value,             // exe_ra1_i value
    output logic [4:0]  debug_exe_ra2_i_value,             // exe_ra2_i value
    output logic        debug_mem_wreg,        // MEM stage write enable
    output logic [4:0]  debug_mem_wa,          // MEM stage write address
    output logic [31:0] debug_mem_wd,          // MEM stage write data
    output logic        debug_wb_wreg,         // WB stage write enable
    output logic [4:0]  debug_wb_wa,           // WB stage write address
    output logic [31:0] debug_wb_wd,           // WB stage write data
    // MEMWB_REG debug signals (memwb_reg input and output)
    output logic        debug_memwb_wreg,      // memwb_reg write enable output
    output logic [4:0]  debug_memwb_wa,        // memwb_reg write address output
    output logic [31:0] debug_memwb_wd,        // memwb_reg write data output
    output logic        debug_memwb_wreg_in,   // memwb_reg write enable input (from MEM stage)
    output logic [4:0]  debug_memwb_wa_in,     // memwb_reg write address input (from MEM stage)
    output logic [31:0] debug_memwb_wd_in,     // memwb_reg write data input (from MEM stage)
    // EXEMEM_REG debug signals (exemem_reg input and output)
    output logic        debug_exemem_wreg,      // exemem_reg write enable output
    output logic [4:0]  debug_exemem_wa,        // exemem_reg write address output
    output logic [31:0] debug_exemem_wd,        // exemem_reg write data output
    output logic        debug_exemem_wreg_in,   // exemem_reg write enable input (from EXE stage)
    output logic [4:0]  debug_exemem_wa_in,     // exemem_reg write address input (from EXE stage)
    output logic [31:0] debug_exemem_wd_in,     // exemem_reg write data input (from EXE stage)
    // EXE stage output signals (for forwarding debug)
    output logic        debug_exe_wreg_i,       // EXE stage write enable (output from EXE stage)
    output logic [4:0]  debug_exe_wa_i,         // EXE stage write address (output from EXE stage)
    output logic [31:0] debug_exe_wd_i,        // EXE stage write data (output from EXE stage)
    // EXEMEM_REG output to EXE_STAGE debug signals (for forwarding)
    output logic        debug_exemem_to_exe_wreg, // exemem_reg output mem_wreg_i (passed to exe_stage)
    output logic [4:0]  debug_exemem_to_exe_wa,   // exemem_reg output mem_wa_i (passed to exe_stage)
    output logic [31:0] debug_exemem_to_exe_wd,    // exemem_reg output mem_wd_i (passed to exe_stage)
    // Signal trace debug signals for mem_wa_i
    output logic [4:0]  debug_exemem_reg_mem_wa,  // exemem_reg module output mem_wa (from exemem_reg instance)
    output logic [4:0]  debug_mem_wa_i_wire,      // mem_wa_i wire value (before connecting to exe_stage)
    output logic [4:0]  debug_exe_stage_mem_wa_i, // exe_stage sees mem_wa_i value (from exe_stage debug output)
    // Delayed memwb_reg debug signals (for forwarding)
    output logic        debug_wb_wreg_i_delayed, // delayed wb_wreg_i (used in forwarding)
    output logic [4:0]  debug_wb_wa_i_delayed,   // delayed wb_wa_i (used in forwarding)
    output logic [31:0] debug_wb_wd_i_delayed,   // delayed wb_dreg_i (used in forwarding)
    // IDEXE_REG debug signals (idexe_reg input and output for ra1/ra2)
    output logic [4:0]  debug_idexe_ra1_in,    // idexe_reg ra1 input (from ID stage)
    output logic [4:0]  debug_idexe_ra2_in,    // idexe_reg ra2 input (from ID stage)
    output logic [4:0]  debug_idexe_ra1_out,   // idexe_reg ra1 output (to EXE stage)
    output logic [4:0]  debug_idexe_ra2_out,  // idexe_reg ra2 output (to EXE stage)
    // Debug signals for values passed to exe_stage
    output logic        debug_exe_wb_wreg_i,  // WB write enable passed to exe_stage
    output logic [4:0]  debug_exe_wb_wa_i,     // WB write address passed to exe_stage
    output logic [31:0] debug_exe_wb_wd_i,     // WB write data passed to exe_stage
    // Detailed debug signals for forward_a_mem calculation
    output logic        debug_forward_a_mem_calc_mem_wreg_i,  // mem_wreg_i value used in forward_a_mem calculation
    output logic [4:0]  debug_forward_a_mem_calc_mem_wa_i,    // mem_wa_i value used in forward_a_mem calculation
    output logic        debug_forward_a_mem_calc_mem_wa_i_not_zero, // (mem_wa_i != 0) result in forward_a_mem calculation
    output logic [4:0]  debug_forward_a_mem_calc_exe_ra1_i,   // exe_ra1_i value used in forward_a_mem calculation
    output logic        debug_forward_a_mem_calc_mem_wa_i_eq_ra1,   // (mem_wa_i == exe_ra1_i) result in forward_a_mem calculation
    output logic        debug_forward_a_mem_calc_result,       // forward_a_mem calculation result
    output logic [4:0]  debug_mem_wa_i_at_assign,             // mem_wa_i value at assign debug_mem_wa_i
    output logic [4:0]  debug_mem_wa_i_at_forward_calc,        // mem_wa_i value at forward_a_mem calculation
    // ID stage instruction decode debug signals
    output logic        debug_id_inst_st_b,                   // ID stage inst_st_b signal
    output logic [4:0]  debug_id_rd,                          // ID stage rd field
    output logic [4:0]  debug_id_rj,                          // ID stage rj field
    output logic [4:0]  debug_id_rk,                          // ID stage rk field
    output logic [9:0]  debug_id_op_31_22,                    // ID stage op_31_22 field
    output logic        debug_id_is_store_or_branch,          // ID stage is_store_or_branch signal
    output logic        debug_id_src2_is_imm,                 // ID stage src2_is_imm signal
    // Additional ID stage debug signals
    output logic [31:0] debug_id_imm_ext,                     // ID stage immediate extension
    output logic [31:0] debug_id_rd1,                         // ID stage rd1 (register read 1)
    output logic [31:0] debug_id_rd2,                         // ID stage rd2 (register read 2)
    output logic [31:0] debug_id_br_op1,                      // ID stage br_op1 (with forwarding)
    output logic [31:0] debug_id_br_target,                   // ID stage br_target
    output logic [4:0]  debug_id_ra1,                         // ID stage ra1 (for forwarding check)
    output logic [4:0]  debug_id_ra2,                         // ID stage ra2 (for forwarding check)
    output logic [31:0] debug_id_br_op1_raw,                  // ID stage br_op1_raw (before forwarding)
    output logic        debug_id_exe_fwd_match,               // ID stage EXE forwarding match
    output logic        debug_id_mem_fwd_match,              // ID stage MEM forwarding match
    output logic        debug_id_wb_fwd_match,               // ID stage WB forwarding match
    output logic [31:0] debug_id_exe_fwd_wd,                 // ID stage EXE forwarding data
    output logic [31:0] debug_id_mem_fwd_wd,                 // ID stage MEM forwarding data
    output logic [31:0] debug_id_wb_fwd_wd,                  // ID stage WB forwarding data
    // Store data debug signals
    output logic [31:0] debug_exe_rk_d_o,                     // EXE stage store data output
    output logic [31:0] debug_exe_rk_d_i,                     // EXE stage store data input (from ID)
    output logic [31:0] debug_id_rk_d_o                       // ID stage store data output (with forwarding)
);

    // ------------------------------------------------------------------
    // Reset generation: locked -> synchronous active-low reset
    // ------------------------------------------------------------------
    logic rst_n;
    always_ff @(posedge clk or negedge locked) begin
        if (!locked)
            rst_n <= 1'b0;
        else
            rst_n <= 1'b1;
    end

    // ------------------------------------------------------------------
    // Simple board peripherals: LED (memory-mapped) and 7-seg display
    // ------------------------------------------------------------------
    // LED register will be memory-mapped (see LED_ADDR below)
    logic [31:0] led_reg;
    assign led = led_reg;

    // Seven-seg display data: 9 digits (0..8)
    logic [3:0] seg_wdata[0:8];

    // UART receive buffer will be defined below (ext_uart_buffer)
    logic [7:0] ext_uart_buffer;

    // Show last received UART byte on digits 0..1 (low/high nibble)
    logic [31:0] sw_2_ff;
    logic [7:0]  btn_ff;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_2_ff <= 32'h0;
            btn_ff  <= 8'h00;
        end else begin
            sw_2_ff <= sw_2;
            btn_ff  <= btn;
        end
    end

    assign seg_wdata[0] = ext_uart_buffer[3:0];
    assign seg_wdata[1] = ext_uart_buffer[7:4];

    // Show sw_2 on digits 2..6
    assign seg_wdata[2] = sw_2_ff[3:0];
    assign seg_wdata[3] = sw_2_ff[7:4];
    assign seg_wdata[4] = sw_2_ff[11:8];
    assign seg_wdata[5] = sw_2_ff[15:12];
    assign seg_wdata[6] = sw_2_ff[19:16];

    // Show btn on digits 7..8
    assign seg_wdata[7] = btn_ff[3:0];
    assign seg_wdata[8] = btn_ff[7:4];

    // Instantiate 7-seg driver
    x7seg seg_cs_data_gen0 (
        .clk      (clk),
        .seg_wdata(seg_wdata),
        .seg_cs   (seg_cs),
        .seg_data (seg_data)
    );

    // ------------------------------------------------------------------
    // External UART: async RX/TX, connected to board pins
    // ------------------------------------------------------------------
    logic [7:0] ext_uart_rx;
    logic [7:0] ext_uart_tx;
    logic       ext_uart_ready;
    logic       ext_uart_clear;
    logic       ext_uart_busy;
    logic       ext_uart_start;
    logic       ext_uart_avai;

    // Receive path
    async_receiver #(
        .ClkFrequency(50000000),
        .Baud       (9600)
    ) ext_uart_r (
        .clk           (clk),
        .RxD           (rxd),
        .RxD_data_ready(ext_uart_ready),
        .RxD_clear     (ext_uart_clear),
        .RxD_data      (ext_uart_rx)
    );

    // Clear UART receiver only when CPU reads the UART data register.
    // This makes RX behavior stable on board: once a byte is received, status[1] stays high
    // until CPU actually reads it.
    assign ext_uart_clear = cpu_read_uart_data;

    // Simple receive buffer and "available" flag for CPU
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_uart_buffer <= 8'h00;
            ext_uart_avai   <= 1'b0;
        end else begin
            // Priority: clear on read > latch new data
            // This ensures that if CPU reads and new data arrives in the same cycle,
            // we clear the flag first, then set it again with new data
            if (cpu_read_uart_data) begin
                // Clear available flag when CPU reads
                ext_uart_avai <= 1'b0;
            end else if (ext_uart_ready) begin
                // Latch every received byte (benchtest only needs the latest byte)
                ext_uart_buffer <= ext_uart_rx;
                ext_uart_avai   <= 1'b1;
            end
        end
    end

    // Transmit path
    logic [3:0] uart_txd_state;  // Internal signal for UART TX state
    async_transmitter #(
        .ClkFrequency(50000000),
        .Baud       (9600)
    ) ext_uart_t (
        .clk      (clk),
        .TxD_start(ext_uart_start),
        .TxD_data (ext_uart_tx),
        .TxD      (txd),
        .TxD_busy (ext_uart_busy),
        .debug_txd_state(uart_txd_state)
    );
    
    // UART transmit buffer: queue next byte when UART is busy
    logic [7:0] uart_tx_buffer;
    logic       uart_tx_pending;
    logic       uart_start_ack;  // Track if UART has acknowledged the start signal
    
    // Byte selection logic (combinational)
    logic [7:0] byte_to_send;  // Selected byte from cpu_mem_wdata based on address[1:0]

    // ------------------------------------------------------------------
    // SoC core: CPU + inst_rom + data_ram + UART memory-mapped registers
    // ------------------------------------------------------------------
    // Address map
    localparam logic [31:0] TEXT_ADDR_START = 32'h8000_0000;  // .text start
    localparam logic [31:0] TEXT_ADDR_END   = 32'h8000_FFFF;  // .text end   (64KB)
    localparam logic [31:0] DATA_ADDR_START = 32'h8001_0000;  // .data start
    localparam logic [31:0] DATA_ADDR_END   = 32'h8001_FFFF;  // .data end   (64KB)
    // benchtest may also use an additional RAM window at 0x8040_0000
    localparam logic [31:0] DATA2_ADDR_START = 32'h8040_0000;
    localparam logic [31:0] DATA2_ADDR_END   = 32'h8040_FFFF;
    localparam logic [31:0] UART_DATA_ADDR  = 32'hBFD0_03F8;  // UART data
    localparam logic [31:0] UART_STAT_ADDR  = 32'hBFD0_03FC;  // UART status
    localparam logic [31:0] LED_ADDR        = 32'h8002_0000;  // LED register (non-UART peripheral)

    // CPU <-> memory bus signals
    logic [31:0] cpu_iaddr;
    logic [31:0] cpu_inst;
    logic        cpu_mem_we;
    logic [31:0] cpu_mem_addr;
    logic [31:0] cpu_mem_wdata;
    logic [31:0] cpu_mem_rdata;

    // inst_rom / data_ram read data
    logic [31:0] inst_rom_rdata;
    logic [31:0] data_ram_rdata;
    logic [31:0] data_ram_rdata_swapped;
    logic [31:0] data_ram_wdata_swapped;

    // Address decoding
    logic sel_text;
    logic sel_data;
    logic sel_uart;
    logic sel_led;

    // MEM reads from .text
    logic       mem_read_text;
    logic [13:0] inst_rom_addr;  // [15:2]

    // UART status: bit0 = TX idle, bit1 = RX ready
    logic [1:0] uart_status;

    // ------------------------------------------------------------------
    // 1) Instantiate CPU core (pipeline with stall input from SoC)
    // ------------------------------------------------------------------
    logic stall_if;
    assign stall_if = mem_read_text;

    // CPU debug signals
    logic [31:0] cpu_debug_wb_pc;
    logic        cpu_debug_wb_rf_wen;
    logic [4:0]  cpu_debug_wb_rf_wnum;
    logic [31:0] cpu_debug_wb_rf_wdata;
    logic [31:0] cpu_debug_if_pc;
    logic [31:0] cpu_debug_id_pc;
    logic [31:0] cpu_debug_exe_pc;
    logic [31:0] cpu_debug_mem_pc;
    logic        cpu_debug_stall;
    logic        cpu_debug_br_taken;
    
    // Forwarding debug signals
    logic [4:0]  cpu_debug_exe_ra1;
    logic [4:0]  cpu_debug_exe_ra2;
    logic        cpu_debug_forward_a_mem;
    logic        cpu_debug_forward_a_wb;
    logic [31:0] cpu_debug_final_src1;
    logic [31:0] cpu_debug_final_src2;
    logic [31:0] cpu_debug_exe_src2_i;
    logic        cpu_debug_forward_b_mem;
    logic        cpu_debug_forward_b_wb;
    logic        cpu_debug_mem_wreg_i;
    logic [4:0]  cpu_debug_mem_wa_i;
    logic [31:0] cpu_debug_mem_wd_i;
    logic        cpu_debug_wb_wreg_i;
    logic [4:0]  cpu_debug_wb_wa_i;
    logic [31:0] cpu_debug_wb_wd_i;
    logic [31:0] cpu_debug_exe_src1_i;
    logic        cpu_debug_mem_wreg;
    logic [4:0]  cpu_debug_mem_wa;
    logic [31:0] cpu_debug_mem_wd;
    logic        cpu_debug_wb_wreg;
    logic [4:0]  cpu_debug_wb_wa;
    logic [31:0] cpu_debug_wb_wd;
    logic        cpu_debug_memwb_wreg;
    logic [4:0]  cpu_debug_memwb_wa;
    logic [31:0] cpu_debug_memwb_wd;
    logic        cpu_debug_wb_wreg_i_delayed;
    logic [4:0]  cpu_debug_wb_wa_i_delayed;
    logic [31:0] cpu_debug_wb_wd_i_delayed;
    logic        cpu_debug_memwb_wreg_in;
    logic [4:0]  cpu_debug_memwb_wa_in;
    logic [31:0] cpu_debug_memwb_wd_in;
    logic        cpu_debug_exemem_wreg;
    logic [4:0]  cpu_debug_exemem_wa;
    logic [31:0] cpu_debug_exemem_wd;
    logic        cpu_debug_exemem_wreg_in;
    logic [4:0]  cpu_debug_exemem_wa_in;
    logic [31:0] cpu_debug_exemem_wd_in;
    logic        cpu_debug_exemem_to_exe_wreg;
    logic [4:0]  cpu_debug_exemem_to_exe_wa;
    logic [31:0] cpu_debug_exemem_to_exe_wd;
    logic [4:0]  cpu_debug_exemem_reg_mem_wa;
    logic [4:0]  cpu_debug_mem_wa_i_wire;
    logic [4:0]  cpu_debug_exe_stage_mem_wa_i;
    logic [4:0]  cpu_debug_idexe_ra1_in;
    logic [4:0]  cpu_debug_idexe_ra2_in;
    logic [4:0]  cpu_debug_idexe_ra1_out;
    logic [4:0]  cpu_debug_idexe_ra2_out;
    logic        cpu_debug_exe_wb_wreg_i;
    logic [4:0]  cpu_debug_exe_wb_wa_i;
    logic [31:0] cpu_debug_exe_wb_wd_i;
    logic        cpu_debug_exe_wb_wreg_i_internal;
    logic [4:0]  cpu_debug_exe_wb_wa_i_internal;
    logic [31:0] cpu_debug_exe_wb_wd_i_internal;
    logic        cpu_debug_forward_a_wb_condition;
    logic        cpu_debug_forward_b_wb_condition;
    logic        cpu_debug_forward_a_mem_condition;
    logic        cpu_debug_forward_b_mem_condition;
    logic        cpu_debug_wb_wreg_i_value;
    logic [4:0]  cpu_debug_wb_wa_i_value;
    logic        cpu_debug_wb_wa_i_not_zero;
    logic        cpu_debug_wb_wa_i_eq_ra1;
    logic        cpu_debug_wb_wa_i_eq_ra2;
    logic        cpu_debug_mem_wreg_i_value;
    logic [4:0]  cpu_debug_mem_wa_i_value;
    logic        cpu_debug_mem_wa_i_not_zero;
    logic        cpu_debug_mem_wa_i_eq_ra1;
    logic        cpu_debug_mem_wa_i_eq_ra2;
    logic [4:0]  cpu_debug_exe_ra1_i_value;
    logic [4:0]  cpu_debug_exe_ra2_i_value;
    // Detailed debug signals for forward_a_mem calculation
    logic        cpu_debug_forward_a_mem_calc_mem_wreg_i;
    logic [4:0]  cpu_debug_forward_a_mem_calc_mem_wa_i;
    logic        cpu_debug_forward_a_mem_calc_mem_wa_i_not_zero;
    logic [4:0]  cpu_debug_forward_a_mem_calc_exe_ra1_i;
    logic        cpu_debug_forward_a_mem_calc_mem_wa_i_eq_ra1;
    logic        cpu_debug_forward_a_mem_calc_result;
    logic [4:0]  cpu_debug_mem_wa_i_at_assign;
    logic [4:0]  cpu_debug_mem_wa_i_at_forward_calc;
    // ID stage instruction decode debug signals
    logic        cpu_debug_id_inst_st_b;
    logic [4:0]  cpu_debug_id_rd;
    logic [4:0]  cpu_debug_id_rj;
    logic [4:0]  cpu_debug_id_rk;
    logic [9:0]  cpu_debug_id_op_31_22;
    logic        cpu_debug_id_is_store_or_branch;
    logic        cpu_debug_id_src2_is_imm;
    logic [31:0] cpu_debug_id_imm_ext;
    logic [31:0] cpu_debug_id_rd1;
    logic [31:0] cpu_debug_id_rd2;
    logic [31:0] cpu_debug_id_br_op1;
    logic [31:0] cpu_debug_id_br_target;
    logic [4:0]  cpu_debug_id_ra1;
    logic [4:0]  cpu_debug_id_ra2;
    logic [31:0] cpu_debug_id_br_op1_raw;
    logic        cpu_debug_id_exe_fwd_match;
    logic        cpu_debug_id_mem_fwd_match;
    logic        cpu_debug_id_wb_fwd_match;
    logic [31:0] cpu_debug_id_exe_fwd_wd;
    logic [31:0] cpu_debug_id_mem_fwd_wd;
    logic [31:0] cpu_debug_id_wb_fwd_wd;
    // Store data debug signals
    logic [31:0] cpu_debug_exe_rk_d_o;
    logic [31:0] cpu_debug_exe_rk_d_i;
    logic [31:0] cpu_debug_id_rk_d_o;

    Loongarch32_Lite u_cpu (
        .cpu_clk_50M      (clk),
        .cpu_rst_n        (rst_n),

        // inst_rom interface
        .iaddr            (cpu_iaddr),
        .inst             (cpu_inst),

        // data bus
        .mem_we           (cpu_mem_we),
        .mem_addr         (cpu_mem_addr),
        .mem_wdata        (cpu_mem_wdata),
        .mem_rdata        (cpu_mem_rdata),

        // stall IF when MEM needs to read .text
        .stall_if_from_soc(stall_if),
        
        // Debug signals
        .debug_wb_pc      (cpu_debug_wb_pc),
        .debug_wb_rf_wen (cpu_debug_wb_rf_wen),
        .debug_wb_rf_wnum(cpu_debug_wb_rf_wnum),
        .debug_wb_rf_wdata(cpu_debug_wb_rf_wdata),
        .debug_if_pc      (cpu_debug_if_pc),
        .debug_id_pc      (cpu_debug_id_pc),
        .debug_exe_pc     (cpu_debug_exe_pc),
        .debug_mem_pc     (cpu_debug_mem_pc),
        .debug_stall      (cpu_debug_stall),
        .debug_br_taken   (cpu_debug_br_taken),
        
        // Forwarding debug signals
        .debug_exe_ra1    (cpu_debug_exe_ra1),
        .debug_exe_ra2    (cpu_debug_exe_ra2),
        .debug_forward_a_mem(cpu_debug_forward_a_mem),
        .debug_forward_a_wb (cpu_debug_forward_a_wb),
        .debug_forward_b_mem(cpu_debug_forward_b_mem),
        .debug_forward_b_wb (cpu_debug_forward_b_wb),
        .debug_final_src1 (cpu_debug_final_src1),
        .debug_final_src2 (cpu_debug_final_src2),
        .debug_exe_src2_i (cpu_debug_exe_src2_i),
        .debug_mem_wreg_i (cpu_debug_mem_wreg_i),
        .debug_mem_wa_i   (cpu_debug_mem_wa_i),
        .debug_mem_wd_i   (cpu_debug_mem_wd_i),
        .debug_wb_wreg_i  (cpu_debug_wb_wreg_i),
        .debug_wb_wa_i    (cpu_debug_wb_wa_i),
        .debug_wb_wd_i    (cpu_debug_wb_wd_i),
        .debug_exe_src1_i (cpu_debug_exe_src1_i),
        .debug_mem_wreg   (cpu_debug_mem_wreg),
        .debug_mem_wa     (cpu_debug_mem_wa),
        .debug_mem_wd     (cpu_debug_mem_wd),
        .debug_wb_wreg    (cpu_debug_wb_wreg),
        .debug_wb_wa      (cpu_debug_wb_wa),
        .debug_wb_wd      (cpu_debug_wb_wd),
        .debug_memwb_wreg (cpu_debug_memwb_wreg),
        .debug_memwb_wa   (cpu_debug_memwb_wa),
        .debug_memwb_wd   (cpu_debug_memwb_wd),
        .debug_memwb_wreg_in (cpu_debug_memwb_wreg_in),
        .debug_memwb_wa_in   (cpu_debug_memwb_wa_in),
        .debug_memwb_wd_in   (cpu_debug_memwb_wd_in),
        .debug_exemem_wreg (cpu_debug_exemem_wreg),
        .debug_exemem_wa   (cpu_debug_exemem_wa),
        .debug_exemem_wd   (cpu_debug_exemem_wd),
        .debug_exemem_wreg_in (cpu_debug_exemem_wreg_in),
        .debug_exemem_wa_in   (cpu_debug_exemem_wa_in),
        .debug_exemem_wd_in   (cpu_debug_exemem_wd_in),
        .debug_exemem_to_exe_wreg (cpu_debug_exemem_to_exe_wreg),
        .debug_exemem_to_exe_wa   (cpu_debug_exemem_to_exe_wa),
        .debug_exemem_to_exe_wd   (cpu_debug_exemem_to_exe_wd),
        .debug_exemem_reg_mem_wa  (cpu_debug_exemem_reg_mem_wa),
        .debug_mem_wa_i_wire      (cpu_debug_mem_wa_i_wire),
        .debug_exe_stage_mem_wa_i (cpu_debug_exe_stage_mem_wa_i),
        .debug_idexe_ra1_in  (cpu_debug_idexe_ra1_in),
        .debug_idexe_ra2_in  (cpu_debug_idexe_ra2_in),
        .debug_idexe_ra1_out (cpu_debug_idexe_ra1_out),
        .debug_idexe_ra2_out (cpu_debug_idexe_ra2_out),
        .debug_exe_wb_wreg_i (cpu_debug_exe_wb_wreg_i),
        .debug_exe_wb_wa_i   (cpu_debug_exe_wb_wa_i),
        .debug_exe_wb_wd_i   (cpu_debug_exe_wb_wd_i),
        .debug_exe_wb_wreg_i_internal (cpu_debug_exe_wb_wreg_i_internal),
        .debug_exe_wb_wa_i_internal   (cpu_debug_exe_wb_wa_i_internal),
        .debug_exe_wb_wd_i_internal   (cpu_debug_exe_wb_wd_i_internal),
        .debug_forward_a_wb_condition (cpu_debug_forward_a_wb_condition),
        .debug_forward_b_wb_condition (cpu_debug_forward_b_wb_condition),
        .debug_forward_a_mem_condition (cpu_debug_forward_a_mem_condition),
        .debug_forward_b_mem_condition (cpu_debug_forward_b_mem_condition),
        .debug_wb_wreg_i_value        (cpu_debug_wb_wreg_i_value),
        .debug_wb_wa_i_value          (cpu_debug_wb_wa_i_value),
        .debug_wb_wa_i_not_zero       (cpu_debug_wb_wa_i_not_zero),
        .debug_wb_wa_i_eq_ra1         (cpu_debug_wb_wa_i_eq_ra1),
        .debug_wb_wa_i_eq_ra2         (cpu_debug_wb_wa_i_eq_ra2),
        .debug_mem_wreg_i_value       (cpu_debug_mem_wreg_i_value),
        .debug_mem_wa_i_value         (cpu_debug_mem_wa_i_value),
        .debug_mem_wa_i_not_zero      (cpu_debug_mem_wa_i_not_zero),
        .debug_mem_wa_i_eq_ra1        (cpu_debug_mem_wa_i_eq_ra1),
        .debug_mem_wa_i_eq_ra2       (cpu_debug_mem_wa_i_eq_ra2),
        .debug_exe_ra1_i_value        (cpu_debug_exe_ra1_i_value),
        .debug_exe_ra2_i_value        (cpu_debug_exe_ra2_i_value),
        .debug_forward_a_mem_calc_mem_wreg_i(cpu_debug_forward_a_mem_calc_mem_wreg_i),
        .debug_forward_a_mem_calc_mem_wa_i(cpu_debug_forward_a_mem_calc_mem_wa_i),
        .debug_forward_a_mem_calc_mem_wa_i_not_zero(cpu_debug_forward_a_mem_calc_mem_wa_i_not_zero),
        .debug_forward_a_mem_calc_exe_ra1_i(cpu_debug_forward_a_mem_calc_exe_ra1_i),
        .debug_forward_a_mem_calc_mem_wa_i_eq_ra1(cpu_debug_forward_a_mem_calc_mem_wa_i_eq_ra1),
        .debug_forward_a_mem_calc_result(cpu_debug_forward_a_mem_calc_result),
        .debug_mem_wa_i_at_assign(cpu_debug_mem_wa_i_at_assign),
        .debug_mem_wa_i_at_forward_calc(cpu_debug_mem_wa_i_at_forward_calc),
        .debug_wb_wreg_i_delayed      (cpu_debug_wb_wreg_i_delayed),
        .debug_wb_wa_i_delayed        (cpu_debug_wb_wa_i_delayed),
        .debug_wb_wd_i_delayed        (cpu_debug_wb_wd_i_delayed),
        // ID stage instruction decode debug signals
        .debug_id_inst_st_b           (cpu_debug_id_inst_st_b),
        .debug_id_rd                  (cpu_debug_id_rd),
        .debug_id_rj                  (cpu_debug_id_rj),
        .debug_id_rk                  (cpu_debug_id_rk),
        .debug_id_op_31_22            (cpu_debug_id_op_31_22),
        .debug_id_is_store_or_branch  (cpu_debug_id_is_store_or_branch),
        .debug_id_src2_is_imm         (cpu_debug_id_src2_is_imm),
        .debug_id_imm_ext             (cpu_debug_id_imm_ext),
        .debug_id_rd1                 (cpu_debug_id_rd1),
        .debug_id_rd2                 (cpu_debug_id_rd2),
        .debug_id_br_op1              (cpu_debug_id_br_op1),
        .debug_id_br_target            (cpu_debug_id_br_target),
        .debug_id_ra1                  (cpu_debug_id_ra1),
        .debug_id_ra2                  (cpu_debug_id_ra2),
        .debug_id_br_op1_raw            (cpu_debug_id_br_op1_raw),
        .debug_id_exe_fwd_match        (cpu_debug_id_exe_fwd_match),
        .debug_id_mem_fwd_match        (cpu_debug_id_mem_fwd_match),
        .debug_id_wb_fwd_match         (cpu_debug_id_wb_fwd_match),
        .debug_id_exe_fwd_wd           (cpu_debug_id_exe_fwd_wd),
        .debug_id_mem_fwd_wd           (cpu_debug_id_mem_fwd_wd),
        .debug_id_wb_fwd_wd            (cpu_debug_id_wb_fwd_wd),
        // Store data debug signals
        .debug_exe_rk_d_o             (cpu_debug_exe_rk_d_o),
        .debug_exe_rk_d_i             (cpu_debug_exe_rk_d_i),
        .debug_id_rk_d_o              (cpu_debug_id_rk_d_o)
    );
    
    // Connect debug signals to top-level outputs
    // COMMENTED OUT FOR FPGA DEPLOYMENT - debug signals are for simulation only
    // assign debug_wb_pc      = cpu_debug_wb_pc;
    // assign debug_wb_rf_wen  = cpu_debug_wb_rf_wen;
    // assign debug_wb_rf_wnum = cpu_debug_wb_rf_wnum;
    // assign debug_wb_rf_wdata = cpu_debug_wb_rf_wdata;
    // assign debug_if_pc      = cpu_debug_if_pc;
    // assign debug_id_pc      = cpu_debug_id_pc;
    // assign debug_exe_pc     = cpu_debug_exe_pc;
    // assign debug_mem_pc     = cpu_debug_mem_pc;
    // assign debug_stall      = cpu_debug_stall;
    // assign debug_br_taken   = cpu_debug_br_taken;
    
    // Forwarding debug signals
    // assign debug_exe_ra1    = cpu_debug_exe_ra1;
    // assign debug_exe_ra2    = cpu_debug_exe_ra2;
    // assign debug_forward_a_mem = cpu_debug_forward_a_mem;
    // assign debug_forward_a_wb  = cpu_debug_forward_a_wb;
    // assign debug_forward_b_mem = cpu_debug_forward_b_mem;
    // assign debug_forward_b_wb  = cpu_debug_forward_b_wb;
    // assign debug_final_src1 = cpu_debug_final_src1;
    // assign debug_final_src2 = cpu_debug_final_src2;
    // assign debug_exe_src2_i = cpu_debug_exe_src2_i;
    // assign debug_mem_wreg_i = cpu_debug_mem_wreg_i;
    // assign debug_mem_wa_i   = cpu_debug_mem_wa_i;
    // assign debug_mem_wd_i   = cpu_debug_mem_wd_i;
    // assign debug_wb_wreg_i  = cpu_debug_wb_wreg_i;
    // assign debug_wb_wa_i    = cpu_debug_wb_wa_i;
    // assign debug_wb_wd_i    = cpu_debug_wb_wd_i;
    // assign debug_exe_src1_i = cpu_debug_exe_src1_i;
    // assign debug_mem_wreg   = cpu_debug_mem_wreg;
    // assign debug_mem_wa     = cpu_debug_mem_wa;
    // assign debug_mem_wd     = cpu_debug_mem_wd;
    // assign debug_wb_wreg    = cpu_debug_wb_wreg;
    // assign debug_wb_wa      = cpu_debug_wb_wa;
    // assign debug_wb_wd      = cpu_debug_wb_wd;
    // assign debug_exe_wb_wreg_i = cpu_debug_exe_wb_wreg_i;
    // assign debug_exe_wb_wa_i   = cpu_debug_exe_wb_wa_i;
    // assign debug_exe_wb_wd_i   = cpu_debug_exe_wb_wd_i;
    // assign debug_exe_wb_wreg_i_internal = cpu_debug_exe_wb_wreg_i_internal;
    // assign debug_exe_wb_wa_i_internal   = cpu_debug_exe_wb_wa_i_internal;
    // assign debug_exe_wb_wd_i_internal   = cpu_debug_exe_wb_wd_i_internal;
    // assign debug_forward_a_wb_condition = cpu_debug_forward_a_wb_condition;
    // assign debug_forward_b_wb_condition = cpu_debug_forward_b_wb_condition;
    // assign debug_forward_a_mem_condition = cpu_debug_forward_a_mem_condition;
    // assign debug_forward_b_mem_condition = cpu_debug_forward_b_mem_condition;
    // assign debug_wb_wreg_i_value        = cpu_debug_wb_wreg_i_value;
    // assign debug_wb_wa_i_value          = cpu_debug_wb_wa_i_value;
    // assign debug_wb_wa_i_not_zero       = cpu_debug_wb_wa_i_not_zero;
    // assign debug_wb_wa_i_eq_ra1         = cpu_debug_wb_wa_i_eq_ra1;
    // assign debug_wb_wa_i_eq_ra2         = cpu_debug_wb_wa_i_eq_ra2;
    // assign debug_mem_wreg_i_value       = cpu_debug_mem_wreg_i_value;
    // assign debug_mem_wa_i_value         = cpu_debug_mem_wa_i_value;
    // assign debug_mem_wa_i_not_zero      = cpu_debug_mem_wa_i_not_zero;
    // assign debug_mem_wa_i_eq_ra1        = cpu_debug_mem_wa_i_eq_ra1;
    // assign debug_mem_wa_i_eq_ra2        = cpu_debug_mem_wa_i_eq_ra2;
    // assign debug_exe_ra1_i_value        = cpu_debug_exe_ra1_i_value;
    // assign debug_exe_ra2_i_value        = cpu_debug_exe_ra2_i_value;
    // Detailed debug signals for forward_a_mem calculation
    // assign debug_forward_a_mem_calc_mem_wreg_i = cpu_debug_forward_a_mem_calc_mem_wreg_i;
    // assign debug_forward_a_mem_calc_mem_wa_i = cpu_debug_forward_a_mem_calc_mem_wa_i;
    // assign debug_forward_a_mem_calc_mem_wa_i_not_zero = cpu_debug_forward_a_mem_calc_mem_wa_i_not_zero;
    // assign debug_forward_a_mem_calc_exe_ra1_i = cpu_debug_forward_a_mem_calc_exe_ra1_i;
    // assign debug_forward_a_mem_calc_mem_wa_i_eq_ra1 = cpu_debug_forward_a_mem_calc_mem_wa_i_eq_ra1;
    // assign debug_forward_a_mem_calc_result = cpu_debug_forward_a_mem_calc_result;
    // assign debug_mem_wa_i_at_assign = cpu_debug_mem_wa_i_at_assign;
    // assign debug_mem_wa_i_at_forward_calc = cpu_debug_mem_wa_i_at_forward_calc;
    // ID stage instruction decode debug signals
    // assign debug_id_inst_st_b = cpu_debug_id_inst_st_b;
    // assign debug_id_rd = cpu_debug_id_rd;
    // assign debug_id_rj = cpu_debug_id_rj;
    // assign debug_id_rk = cpu_debug_id_rk;
    // assign debug_id_op_31_22 = cpu_debug_id_op_31_22;
    // assign debug_id_is_store_or_branch = cpu_debug_id_is_store_or_branch;
    // assign debug_id_src2_is_imm = cpu_debug_id_src2_is_imm;
    // assign debug_id_imm_ext = cpu_debug_id_imm_ext;
    // assign debug_id_rd1 = cpu_debug_id_rd1;
    // assign debug_id_rd2 = cpu_debug_id_rd2;
    // assign debug_id_br_op1 = cpu_debug_id_br_op1;
    // assign debug_id_br_target = cpu_debug_id_br_target;
    // assign debug_id_ra1 = cpu_debug_id_ra1;
    // assign debug_id_ra2 = cpu_debug_id_ra2;
    // assign debug_id_br_op1_raw = cpu_debug_id_br_op1_raw;
    // assign debug_id_exe_fwd_match = cpu_debug_id_exe_fwd_match;
    // assign debug_id_mem_fwd_match = cpu_debug_id_mem_fwd_match;
    // assign debug_id_wb_fwd_match = cpu_debug_id_wb_fwd_match;
    // assign debug_id_exe_fwd_wd = cpu_debug_id_exe_fwd_wd;
    // assign debug_id_mem_fwd_wd = cpu_debug_id_mem_fwd_wd;
    // assign debug_id_wb_fwd_wd = cpu_debug_id_wb_fwd_wd;
    // assign debug_exe_rk_d_o = cpu_debug_exe_rk_d_o;
    // assign debug_exe_rk_d_i = cpu_debug_exe_rk_d_i;
    // assign debug_id_rk_d_o = cpu_debug_id_rk_d_o;
    // assign debug_memwb_wreg = cpu_debug_memwb_wreg;
    // assign debug_memwb_wa   = cpu_debug_memwb_wa;
    // assign debug_memwb_wd   = cpu_debug_memwb_wd;
    // assign debug_memwb_wreg_in = cpu_debug_memwb_wreg_in;
    // assign debug_memwb_wa_in   = cpu_debug_memwb_wa_in;
    // assign debug_memwb_wd_in   = cpu_debug_memwb_wd_in;
    // assign debug_exemem_wreg = cpu_debug_exemem_wreg;
    // assign debug_exemem_wa   = cpu_debug_exemem_wa;
    // assign debug_exemem_wd   = cpu_debug_exemem_wd;
    // assign debug_exemem_wreg_in = cpu_debug_exemem_wreg_in;
    // assign debug_exemem_wa_in   = cpu_debug_exemem_wa_in;
    // assign debug_exemem_wd_in   = cpu_debug_exemem_wd_in;
    // EXE stage output signals (same as exemem_reg input)
    // assign debug_exe_wreg_i = cpu_debug_exemem_wreg_in;
    // assign debug_exe_wa_i   = cpu_debug_exemem_wa_in;
    // assign debug_exe_wd_i   = cpu_debug_exemem_wd_in;
    // assign debug_exemem_to_exe_wreg = cpu_debug_exemem_to_exe_wreg;
    // assign debug_exemem_to_exe_wa   = cpu_debug_exemem_to_exe_wa;
    // assign debug_exemem_to_exe_wd   = cpu_debug_exemem_to_exe_wd;
    // assign debug_exemem_reg_mem_wa  = cpu_debug_exemem_reg_mem_wa;
    // assign debug_mem_wa_i_wire      = cpu_debug_mem_wa_i_wire;
    // assign debug_exe_stage_mem_wa_i = cpu_debug_exe_stage_mem_wa_i;
    // assign debug_wb_wreg_i_delayed = cpu_debug_wb_wreg_i_delayed;
    // assign debug_wb_wa_i_delayed   = cpu_debug_wb_wa_i_delayed;
    // assign debug_wb_wd_i_delayed   = cpu_debug_wb_wd_i_delayed;
    // assign debug_idexe_ra1_in  = cpu_debug_idexe_ra1_in;
    // assign debug_idexe_ra2_in  = cpu_debug_idexe_ra2_in;
    // assign debug_idexe_ra1_out = cpu_debug_idexe_ra1_out;
    // assign debug_idexe_ra2_out = cpu_debug_idexe_ra2_out;
    
    // Additional debug signals for memory interface
    // assign debug_cpu_mem_addr = cpu_mem_addr;
    // assign debug_cpu_mem_we   = cpu_mem_we;
    // assign debug_cpu_mem_wdata = cpu_mem_wdata;

    // ------------------------------------------------------------------
    // 2) inst_rom: shared between IF and MEM (.text read)
    // ------------------------------------------------------------------
    always_comb begin
        if (mem_read_text) begin
            // MEM accessing .text: use MEM address
            inst_rom_addr = cpu_mem_addr[15:2];
        end else begin
            // Normal IF stage fetch
            inst_rom_addr = cpu_iaddr[15:2];
        end
    end

    inst_rom u_inst_rom (
        .a   (inst_rom_addr),
        .spo (inst_rom_rdata)
    );

    // inst_rom returns data in big-endian format (as seen in id_stage.sv byte swap)
    // For instruction fetch, bytes are swapped in id_stage
    // For data read (ld.b), we need to swap bytes here to get little-endian format
    logic [31:0] inst_rom_rdata_swapped;
    assign inst_rom_rdata_swapped = {inst_rom_rdata[7:0], inst_rom_rdata[15:8], 
                                      inst_rom_rdata[23:16], inst_rom_rdata[31:24]};

    assign cpu_inst = inst_rom_rdata;

    // ------------------------------------------------------------------
    // 3) data_ram: .data segment storage
    // Also used for stack storage in TEXT section (writes to TEXT section go to data_ram)
    // ------------------------------------------------------------------
    // Allow writes to TEXT section to go to data_ram (for stack support)
    // Read from TEXT section: use inst_rom for instructions/strings, data_ram for stack area
    // Write to TEXT section: use data_ram (writable)
    logic data_ram_we;
    logic [13:0] data_ram_addr;
    assign data_ram_we = cpu_mem_we & (sel_data || sel_text);  // Allow writes to TEXT section for stack
    assign data_ram_addr = cpu_mem_addr[15:2];  // Use same address bits for both DATA and TEXT sections
    
    data_ram u_data_ram (
        .clk (clk),
        .we  (data_ram_we),
        .a   (data_ram_addr),
        .d   (data_ram_wdata_swapped),
        .spo (data_ram_rdata)
    );

    // data_ram also returns words in big-endian byte order; swap to little-endian
    assign data_ram_rdata_swapped = {data_ram_rdata[7:0], data_ram_rdata[15:8],
                                    data_ram_rdata[23:16], data_ram_rdata[31:24]};
    assign data_ram_wdata_swapped = {cpu_mem_wdata[7:0], cpu_mem_wdata[15:8],
                                    cpu_mem_wdata[23:16], cpu_mem_wdata[31:24]};

    // ------------------------------------------------------------------
    // 4) Address decoding: .text / .data / UART
    // Note: CPU may output addresses with or without the high bit set
    // Virtual address 0x80000fcc may appear as 0x08000fcc (physical) or 0x80000fcc (virtual)
    // We need to handle both cases for TEXT section
    // ------------------------------------------------------------------
    always_comb begin
        sel_text = 1'b0;
        sel_data = 1'b0;
        sel_uart = 1'b0;
        sel_led  = 1'b0;

        // Check if address is in TEXT section (with or without high bit)
        // Virtual: 0x80000000-0x8000FFFF, Physical: 0x00000000-0x0000FFFF (but we use lower 16 bits)
        // Also check if address[15:0] is in TEXT range when high bits are 0x0800xxxx
        if ((cpu_mem_addr >= TEXT_ADDR_START) && (cpu_mem_addr <= TEXT_ADDR_END)) begin
            sel_text = 1'b1;
        end else if ((cpu_mem_addr[31:16] == 16'h0800) && (cpu_mem_addr[15:0] <= 16'hFFFF)) begin
            // Handle case where address is 0x0800xxxx (physical address format)
            // This is TEXT section with high bit cleared
            sel_text = 1'b1;
        end else if (((cpu_mem_addr >= DATA_ADDR_START) && (cpu_mem_addr <= DATA_ADDR_END)) ||
                     ((cpu_mem_addr >= DATA2_ADDR_START) && (cpu_mem_addr <= DATA2_ADDR_END))) begin
            sel_data = 1'b1;
        end else if (((cpu_mem_addr & 32'hFFFFFFFC) == (UART_DATA_ADDR & 32'hFFFFFFFC)) || 
                     (cpu_mem_addr == UART_STAT_ADDR)) begin
            // UART data register: support byte-aligned writes (ST.B to 0xBFD003F8/9/FA/FB)
            sel_uart = 1'b1;
        end else if (cpu_mem_addr == LED_ADDR) begin
            sel_led = 1'b1;
        end
    end

    assign mem_read_text = sel_text && !cpu_mem_we;

    // Byte selection logic: extract byte from cpu_mem_wdata based on address[1:0]
    always_comb begin
        case (cpu_mem_addr[1:0])
            2'b00: byte_to_send = cpu_mem_wdata[7:0];
            2'b01: byte_to_send = cpu_mem_wdata[15:8];
            2'b10: byte_to_send = cpu_mem_wdata[23:16];
            2'b11: byte_to_send = cpu_mem_wdata[31:24];
            default: byte_to_send = cpu_mem_wdata[7:0];
        endcase
    end

    // ------------------------------------------------------------------
    // 5) UART memory-mapped registers: DATA / STAT
    // ------------------------------------------------------------------
    // UART data register: support byte-aligned writes (ST.B to 0xBFD003F8/9/FA/FB)
    // Declare these early so they can be used in UART receiver logic
    wire cpu_write_uart_data;
    wire cpu_read_uart_data;
    wire cpu_read_uart_stat;
    
    assign cpu_write_uart_data = sel_uart && cpu_mem_we && 
                               ((cpu_mem_addr & 32'hFFFFFFFC) == (UART_DATA_ADDR & 32'hFFFFFFFC));
    assign cpu_read_uart_data  = sel_uart && !cpu_mem_we && 
                               ((cpu_mem_addr & 32'hFFFFFFFC) == (UART_DATA_ADDR & 32'hFFFFFFFC));
    // Support byte-aligned reads for status register (ld.b can read from any byte offset)
    assign cpu_read_uart_stat  = sel_uart && !cpu_mem_we && 
                               ((cpu_mem_addr & 32'hFFFFFFFC) == (UART_STAT_ADDR & 32'hFFFFFFFC));

    // LED register write enable
    wire led_we = sel_led && cpu_mem_we;

    // CPU -> UART transmit: write lower 8 bits to ext_uart_tx when not busy
    // async_transmitter requires TxD_start to be asserted for at least one clock cycle
    // when TxD_ready (i.e., !TxD_busy) is true
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_uart_tx     <= 8'h00;
            ext_uart_start  <= 1'b0;
            led_reg         <= 32'h0000_0000;
            uart_tx_buffer  <= 8'h00;
            uart_tx_pending <= 1'b0;
            uart_start_ack  <= 1'b0;
        end else begin
            // Handle LED write
            if (led_we) begin
                led_reg <= cpu_mem_wdata;
            end
            
            // Handle UART transmit: queue data if busy, send immediately if idle
            // For ST.B, select the correct byte based on address[1:0]
            // Note: ext_uart_start must be held for at least one clock cycle when UART is ready.
            // The UART state machine detects TxD_start on the clock edge (posedge clk).
            // async_transmitter: when TxD_state==0 and TxD_start==1, state changes to 4'b0100
            // This happens on the same clock edge, so ext_uart_busy becomes 1 in the next cycle.
            
            // Clear ext_uart_start after it has been held for one cycle
            // The async_transmitter latches TxD_start on posedge, so one cycle is enough
            // We use uart_start_ack to track that we've held it for one cycle
            // Once UART becomes busy (ext_uart_busy=1), we know it has started, so we can clear ext_uart_start
            if (ext_uart_start) begin
                // If UART has become busy, it has started transmission, safe to clear
                if (ext_uart_busy) begin
                    ext_uart_start <= 1'b0;
                    uart_start_ack <= 1'b0;
                end else if (uart_start_ack) begin
                    // We've held it for one cycle and UART hasn't started yet (shouldn't happen normally)
                    // Clear it anyway to avoid getting stuck
                    ext_uart_start <= 1'b0;
                    uart_start_ack <= 1'b0;
                end else begin
                    // Mark that we've held it for one cycle
                    uart_start_ack <= 1'b1;
                end
            end else begin
                // Reset ack flag when not starting
                uart_start_ack <= 1'b0;
            end
            
            // Then, handle new writes or pending data
            // Note: byte_to_send is now computed in combinational logic above
            if (cpu_write_uart_data) begin
                // Only start if UART is ready (not busy) and not already starting
                if (!ext_uart_busy && !ext_uart_start) begin
                    // UART is ready, send immediately
                    ext_uart_tx <= byte_to_send;
                    ext_uart_start <= 1'b1;
                    uart_tx_pending <= 1'b0;
                end else begin
                    // UART is busy or starting, queue the byte
                    uart_tx_buffer <= byte_to_send;
                    uart_tx_pending <= 1'b1;
                end
            end else if (uart_tx_pending && !ext_uart_busy && !ext_uart_start) begin
                // Send queued byte when UART is ready and not starting
                ext_uart_tx <= uart_tx_buffer;
                ext_uart_start <= 1'b1;
                uart_tx_pending <= 1'b0;
            end
        end
    end

    // UART status: bit0 = TX idle (UART hardware is ready to accept new data), bit1 = RX ready
    // TX idle means UART hardware is not busy (pending data will be sent automatically)
    // Note: Even if there's pending data in buffer, if UART hardware is idle, we report idle
    // because the pending data will be sent automatically in the next cycle
    always_comb begin
        // TX ready should mean "CPU can safely write a new byte now".
        // If UART is busy, starting, or we have a pending byte queued, the CPU should keep waiting.
        // Include ext_uart_start in the check: if UART is starting, it's not ready for new data
        uart_status[0] = (~ext_uart_busy) & (~uart_tx_pending) & (~ext_uart_start);
        uart_status[1] = ext_uart_avai;
    end

    // ------------------------------------------------------------------
    // 6) Bus read data mux back to CPU
    // ------------------------------------------------------------------
    always_comb begin
        cpu_mem_rdata = 32'h0000_0000;

        if (sel_data) begin
            cpu_mem_rdata = data_ram_rdata_swapped;
        end else if (sel_text) begin
            if (cpu_mem_we) begin
                // Write to TEXT section: read from data_ram (where we write stack data)
                cpu_mem_rdata = data_ram_rdata_swapped;
            end else begin
                // Read from TEXT section: use inst_rom for instructions/strings
                // But if address is in stack area, read from data_ram
                // Stack typically starts around 0x80000fcc (or 0x08000fcc) and grows downward
                // Check both virtual (0x80000f00-0x8000ffff) and physical (0x08000f00-0x0800ffff) formats
                if ((cpu_mem_addr >= 32'h80000f00 && cpu_mem_addr <= 32'h8000ffff) ||
                    (cpu_mem_addr[31:16] == 16'h0800 && cpu_mem_addr[15:0] >= 16'h0f00 && cpu_mem_addr[15:0] <= 16'hffff)) begin
                    cpu_mem_rdata = data_ram_rdata_swapped;
                end else begin
                    // inst_rom returns big-endian, swap to little-endian for data reads
                    cpu_mem_rdata = inst_rom_rdata_swapped;
                end
            end
        end else if (sel_uart) begin
            if (cpu_read_uart_data) begin
                // Replicate received byte into all byte lanes so both ld.w and ld.b (any addr[1:0]) work.
                cpu_mem_rdata = {ext_uart_buffer, ext_uart_buffer, ext_uart_buffer, ext_uart_buffer};
            end else if (cpu_read_uart_stat) begin
                // Replicate status into all byte lanes so both ld.w and ld.b (any addr[1:0]) work.
                cpu_mem_rdata = {{6'h0, uart_status}, {6'h0, uart_status}, {6'h0, uart_status}, {6'h0, uart_status}};
            end else begin
                // Unmapped UART address space: return 0
                cpu_mem_rdata = 32'h0000_0000;
            end
        end else if (sel_led && !cpu_mem_we) begin
            cpu_mem_rdata = led_reg;
        end
    end
    
    // Debug signal assignments
    // COMMENTED OUT FOR FPGA DEPLOYMENT - debug signals are for simulation only
    // assign debug_cpu_mem_rdata = cpu_mem_rdata;
    // assign debug_uart_busy = ext_uart_busy;
    // UART RX debug signals
    // assign debug_uart_rx_ready = ext_uart_ready;
    // assign debug_uart_rx_data = ext_uart_rx;
    // assign debug_uart_rx_avai = ext_uart_avai;
    // assign debug_uart_rx_buffer = ext_uart_buffer;
    // assign debug_uart_rx_clear = ext_uart_clear;
    // assign debug_cpu_read_uart_data = cpu_read_uart_data;
    // assign debug_uart_txd_state = uart_txd_state;  // UART TX state machine state

    // TB compatibility debug ports
    // assign debug_stall_if      = stall_if;
    // assign debug_mem_read_text = mem_read_text;
    // assign debug_uart_tx_pending = uart_tx_pending;
    // assign debug_uart_status = uart_status;
    // assign debug_cpu_write_uart_data = cpu_write_uart_data;
    // assign debug_ext_uart_start = ext_uart_start;
    // assign debug_uart_tx_buffer = uart_tx_buffer;
    // assign debug_sel_uart = sel_uart;
    // Calculate byte_to_send using combinational logic for immediate debug output
    // always_comb begin
    //     case (cpu_mem_addr[1:0])
    //         2'b00: debug_byte_to_send = cpu_mem_wdata[7:0];
    //         2'b01: debug_byte_to_send = cpu_mem_wdata[15:8];
    //         2'b10: debug_byte_to_send = cpu_mem_wdata[23:16];
    //         2'b11: debug_byte_to_send = cpu_mem_wdata[31:24];
    //         default: debug_byte_to_send = cpu_mem_wdata[7:0];
    //     endcase
    // end
    
    // Additional debug signals for inst_rom access (already declared in port list)
    // When mem_read_text, use cpu_mem_addr directly for debug (more accurate)
    // Otherwise, reconstruct from inst_rom_addr for IF stage fetches
    // assign debug_inst_rom_addr = mem_read_text ? cpu_mem_addr : {18'h0, inst_rom_addr, 2'b00};
    // assign debug_inst_rom_rdata = inst_rom_rdata;  // Big-endian from inst_rom
    // assign debug_inst_rom_rdata_swapped = inst_rom_rdata_swapped;  // Little-endian after swap

endmodule