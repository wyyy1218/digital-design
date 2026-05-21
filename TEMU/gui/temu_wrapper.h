#ifndef TEMU_WRAPPER_H
#define TEMU_WRAPPER_H

#include <cstdint>
#include <cstddef>  // for size_t

// Note: CPU_state is defined in reg.h, which should be included
// in the implementation file (temu_wrapper.cpp)

// C++ wrapper structures
struct CPUStateWrapper {
    uint32_t pc;
    uint32_t registers[32];
};

// GUI-side watchpoint info (for displaying the list)
struct WatchpointInfo {
    int no;
    char expr[64];
    uint32_t value;
};

// C++ interface functions
#ifdef __cplusplus
extern "C" {
#endif

// Initialize TEMU
void temu_init(int argc, char *argv[]);

// Restart/Reset TEMU
void temu_restart();

// Get CPU state
void temu_get_cpu_state(struct CPUStateWrapper *state);

// Get register value
uint32_t temu_get_register(int index);

// Get PC value
uint32_t temu_get_pc();

// Execute instructions
void temu_execute(int n);

// Get memory value
uint32_t temu_get_memory(uint32_t addr, size_t size);

// Write memory value
void temu_write_memory(uint32_t addr, size_t size, uint32_t data);

// Set watchpoint
int temu_set_watchpoint(const char *expr);

// Delete watchpoint
void temu_delete_watchpoint(int no);

// Check watchpoints (returns 1 if triggered)
int temu_check_watchpoints();

// Evaluate expression
uint32_t temu_eval_expr(const char *expr, int *success);

// Get TEMU state (STOP, RUNNING, END)
int temu_get_state();

// Get instruction at PC
uint32_t temu_fetch_instruction(uint32_t pc);

// Get assembly string for instruction
const char* temu_get_assembly(uint32_t pc);

// Get register name
const char* temu_get_register_name(int index);

// Enumerate active watchpoints.
// Returns number of watchpoints filled into out (up to max_count).
int temu_list_watchpoints(struct WatchpointInfo *out, int max_count);

#ifdef __cplusplus
}
#endif

#endif // TEMU_WRAPPER_H
