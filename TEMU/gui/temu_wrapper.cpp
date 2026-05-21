#include "temu_wrapper.h"
#include <cstring>
#include <cstdio>

// Workaround for bool type conflict between C and C++
// C code defines: typedef uint8_t bool;
// C++ has built-in bool type
// We'll use a wrapper approach

// Include C headers with extern "C"
extern "C" {
    // Save C++ bool type before including C headers
    #ifdef __cplusplus
    typedef bool cpp_bool;
    #undef bool
    #define bool uint8_t
    #endif

    #include "../temu/include/temu.h"
    #include "../temu/include/cpu/reg.h"  // This defines CPU_state
    #include "../temu/include/memory/memory.h"
    #include "../temu/include/monitor/monitor.h"
    #include "../temu/include/monitor/expr.h"
    #include "../temu/include/monitor/watchpoint.h"
    #include "../temu/include/cpu/helper.h"

    #ifdef __cplusplus
    #undef bool
    #define bool cpp_bool
    #endif

    // External variables - cpu is already declared in reg.h
    extern int temu_state;
    extern char assembly[80];
    extern uint8_t *hw_mem;

    // Function declarations - use uint8_t for bool parameters
    void init_monitor(int argc, char *argv[]);
    void restart();
    void cpu_exec(uint32_t n);

    // expr function signature in C uses uint8_t* (which is bool* in C)
    uint32_t expr(char *e, uint8_t *success);
    WP* new_wp(char *expr_str);
    void free_wp(int NO);
    uint8_t check_wp();  // Returns uint8_t (0 or 1)

    // Added for GUI: enumerate active watchpoints (implemented in watchpoint.c)
    int list_watchpoints(WP *out, int max_count);
}

void temu_init(int argc, char *argv[]) {
    init_monitor(argc, argv);
}

void temu_restart() {
    restart();
}

void temu_get_cpu_state(struct CPUStateWrapper *state) {
    if (state == nullptr) return;

    state->pc = cpu.pc;
    for (int i = 0; i < 32; i++) {
        state->registers[i] = cpu.gpr[i]._32;
    }
}

uint32_t temu_get_register(int index) {
    if (index < 0 || index >= 32) return 0;
    return cpu.gpr[index]._32;
}

uint32_t temu_get_pc() {
    return cpu.pc;
}

void temu_execute(int n) {
    ::cpu_exec(n);
}

uint32_t temu_get_memory(uint32_t addr, size_t size) {
    // Map virtual address to physical
    addr = addr & 0x7FFFFFFF;
    return mem_read(addr, size);
}

void temu_write_memory(uint32_t addr, size_t size, uint32_t data) {
    // Map virtual address to physical
    addr = addr & 0x7FFFFFFF;
    mem_write(addr, size, data);
}

int temu_set_watchpoint(const char *expr_str) {
    WP *wp = new_wp(const_cast<char*>(expr_str));
    if (wp == nullptr) return -1;
    return wp->NO;
}

void temu_delete_watchpoint(int no) {
    free_wp(no);
}

int temu_check_watchpoints() {
    return check_wp() ? 1 : 0;
}

uint32_t temu_eval_expr(const char *expr_str, int *success) {
    uint8_t success_val = 0;
    uint32_t result = ::expr(const_cast<char*>(expr_str), &success_val);
    if (success) {
        *success = success_val ? 1 : 0;
    }
    return result;
}

int temu_get_state() {
    return temu_state;
}

uint32_t temu_fetch_instruction(uint32_t pc) {
    // Map virtual address to physical
    pc = pc & 0x7FFFFFFF;
    return instr_fetch(pc, 4);
}

const char* temu_get_assembly(uint32_t pc) {
    static char buf[80];
    snprintf(buf, sizeof(buf), "[instruction at 0x%08x]", pc);
    return buf;
}

const char* temu_get_register_name(int index) {
    if (index < 0 || index >= 32) return "invalid";
    return regfile[index];
}

int temu_list_watchpoints(struct WatchpointInfo *out, int max_count) {
    if (out == nullptr || max_count <= 0) return 0;

    WP temp[32];
    int cap = (max_count > 32) ? 32 : max_count;

    int n = list_watchpoints(temp, cap);
    for (int i = 0; i < n; i++) {
        out[i].no = temp[i].NO;
        std::strncpy(out[i].expr, temp[i].expr, sizeof(out[i].expr) - 1);
        out[i].expr[sizeof(out[i].expr) - 1] = '\0';

        int success = 0;
        out[i].value = temu_eval_expr(out[i].expr, &success);
        if (!success) {
            out[i].value = 0;
        }
    }

    return n;
}
