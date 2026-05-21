include loongarch_sc/src/Makefile.testcase

.PHONY: run clean gui clean-gui

ifndef INCLUDE_DIR
INCLUDE_DIR := ./temu/include
endif
ifndef SRC_DIR
SRC_DIR := ./temu/src
endif
ifndef BUILD_DIR
BUILD_DIR := build/
endif
DEBUG ?= false

# Compilation flags
CC := gcc
CFLAGS := -I$(INCLUDE_DIR) -I$(INCLUDE_DIR)/cpu -I$(INCLUDE_DIR)/memory -I$(INCLUDE_DIR)/monitor -Wall -Werror
LDFLAGS := -lreadline

# Files to be compiled
SRCS := $(wildcard $(SRC_DIR)/*.c) $(wildcard $(SRC_DIR)/memory/*.c) $(wildcard $(SRC_DIR)/cpu/*.c) $(wildcard $(SRC_DIR)/monitor/*.c)

TEMU_TARGET := temu

ifeq ($(DEBUG), true)
CFLAGS += -g
endif

export	INCLUDE_DIR
export	SRC_DIR
export	BUILD_DIR

# ********************
# Rules of Compilation
# ********************

$(BUILD_DIR)$(TEMU_TARGET): 
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LDFLAGS)

run: $(BUILD_DIR)$(TEMU_TARGET)
	@./$(BUILD_DIR)$(TEMU_TARGET) $(USER_PROGRAM)

clean-temu:
	rm -f -r $(BUILD_DIR)

clean:
	rm -f -r $(BUILD_DIR)
	rm -f -r ./loongarch_sc/build
	rm -f log.txt
	rm -f *.bin

# GUI build rules
GUI_DIR := gui
GUI_BUILD_DIR := $(GUI_DIR)/build
TEMU_OBJ_DIR := $(BUILD_DIR)temu_obj

# First compile TEMU core as object files
$(TEMU_OBJ_DIR):
	@mkdir -p $(TEMU_OBJ_DIR)

TEMU_OBJS := $(TEMU_OBJ_DIR)/monitor/monitor.o \
             $(TEMU_OBJ_DIR)/monitor/cpu-exec.o \
             $(TEMU_OBJ_DIR)/monitor/expr.o \
             $(TEMU_OBJ_DIR)/monitor/watchpoint.o \
             $(TEMU_OBJ_DIR)/cpu/reg.o \
             $(TEMU_OBJ_DIR)/cpu/exec.o \
             $(TEMU_OBJ_DIR)/cpu/i12-type.o \
             $(TEMU_OBJ_DIR)/cpu/i16-type.o \
             $(TEMU_OBJ_DIR)/cpu/i20-type.o \
             $(TEMU_OBJ_DIR)/cpu/3r-type.o \
             $(TEMU_OBJ_DIR)/cpu/special.o \
             $(TEMU_OBJ_DIR)/memory/memory.o \
             $(TEMU_OBJ_DIR)/memory/dram.o

# Compile TEMU source files to object files for GUI
$(TEMU_OBJ_DIR)/monitor/%.o: $(SRC_DIR)/monitor/%.c | $(TEMU_OBJ_DIR)
	@mkdir -p $(TEMU_OBJ_DIR)/monitor
	$(CC) $(CFLAGS) -fPIC -c $< -o $@

$(TEMU_OBJ_DIR)/cpu/%.o: $(SRC_DIR)/cpu/%.c | $(TEMU_OBJ_DIR)
	@mkdir -p $(TEMU_OBJ_DIR)/cpu
	$(CC) $(CFLAGS) -fPIC -c $< -o $@

$(TEMU_OBJ_DIR)/memory/%.o: $(SRC_DIR)/memory/%.c | $(TEMU_OBJ_DIR)
	@mkdir -p $(TEMU_OBJ_DIR)/memory
	$(CC) $(CFLAGS) -fPIC -c $< -o $@

gui: $(TEMU_OBJS)
	@echo "Building GUI version..."
	@echo "Checking for qmake..."
	@which qmake > /dev/null 2>&1 || \
		(echo "ERROR: qmake not found!" && \
		 echo "Please install Qt5 development packages:" && \
		 echo "  Ubuntu/Debian: sudo apt install qt5-qmake qtbase5-dev qtbase5-dev-tools" && \
		 echo "  See gui/INSTALL.md for detailed instructions" && \
		 exit 1)
	@echo "qmake found: $$(which qmake)"
	@echo "Checking for g++..."
	@which g++ > /dev/null 2>&1 || \
		(echo "ERROR: g++ not found!" && \
		 echo "Please install C++ compiler:" && \
		 echo "  Ubuntu/Debian: sudo apt install g++ build-essential" && \
		 exit 1)
	@echo "g++ found: $$(which g++)"
	@mkdir -p $(GUI_BUILD_DIR)
	@cd $(GUI_DIR) && qmake temu_gui.pro && make
	@echo "Linking with TEMU object files...";
	@cd $(GUI_DIR) && g++ -Wl,-O1 -o temu_gui main.o main_window.o register_view.o memory_view.o code_view.o control_panel.o watchpoint_dialog.o temu_wrapper.o moc_main_window.o moc_register_view.o moc_memory_view.o moc_code_view.o moc_control_panel.o moc_watchpoint_dialog.o \
		../build/temu_obj/monitor/monitor.o \
		../build/temu_obj/monitor/cpu-exec.o \
		../build/temu_obj/monitor/expr.o \
		../build/temu_obj/monitor/watchpoint.o \
		../build/temu_obj/cpu/reg.o \
		../build/temu_obj/cpu/exec.o \
		../build/temu_obj/cpu/i12-type.o \
		../build/temu_obj/cpu/i16-type.o \
		../build/temu_obj/cpu/i20-type.o \
		../build/temu_obj/cpu/3r-type.o \
		../build/temu_obj/cpu/special.o \
		../build/temu_obj/memory/memory.o \
		../build/temu_obj/memory/dram.o \
		-lreadline -lQt5Widgets -lQt5Gui -lQt5Core -lGL -lpthread
	@echo ""
	@if [ -f "$(GUI_DIR)/temu_gui" ]; then \
		echo "GUI build complete. Run with: ./gui/temu_gui"; \
	elif [ -f "$(GUI_BUILD_DIR)/temu_gui" ]; then \
		echo "GUI build complete. Run with: ./gui/build/temu_gui"; \
	else \
		echo "GUI build complete. Run with: cd gui && ./temu_gui"; \
	fi
	@echo ""
	@echo "Note: If GUI运行后Load崩溃，请参考 TEMU/GUI_DEVELOPMENT_SUMMARY.md 的问题与排查建议"

clean-gui:
	rm -f -r $(GUI_BUILD_DIR)
	rm -f -r $(TEMU_OBJ_DIR)
	cd $(GUI_DIR) && make clean 2>/dev/null || true

