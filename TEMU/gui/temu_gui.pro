QT += core widgets
CONFIG += c++11

TARGET = temu_gui
TEMPLATE = app

SOURCES += \
    main.cpp \
    main_window.cpp \
    register_view.cpp \
    memory_view.cpp \
    code_view.cpp \
    control_panel.cpp \
    watchpoint_dialog.cpp \
    temu_wrapper.cpp

HEADERS += \
    main_window.h \
    register_view.h \
    memory_view.h \
    code_view.h \
    control_panel.h \
    watchpoint_dialog.h \
    temu_wrapper.h

INCLUDEPATH += ../temu/include \
               ../temu/include/cpu \
               ../temu/include/memory \
               ../temu/include/monitor

# Link against TEMU core object files (built by top-level Makefile)
TEMU_OBJ_DIR = ../build/temu_obj

LIBS += \
    $$TEMU_OBJ_DIR/monitor/monitor.o \
    $$TEMU_OBJ_DIR/monitor/cpu-exec.o \
    $$TEMU_OBJ_DIR/monitor/expr.o \
    $$TEMU_OBJ_DIR/monitor/watchpoint.o \
    $$TEMU_OBJ_DIR/cpu/reg.o \
    $$TEMU_OBJ_DIR/cpu/exec.o \
    $$TEMU_OBJ_DIR/cpu/i12-type.o \
    $$TEMU_OBJ_DIR/cpu/i16-type.o \
    $$TEMU_OBJ_DIR/cpu/i20-type.o \
    $$TEMU_OBJ_DIR/cpu/3r-type.o \
    $$TEMU_OBJ_DIR/cpu/special.o \
    $$TEMU_OBJ_DIR/memory/memory.o \
    $$TEMU_OBJ_DIR/memory/dram.o

# Link against readline
LIBS += -lreadline

# Debug flags
CONFIG(debug, debug|release) {
    QMAKE_CXXFLAGS += -g
}

CONFIG(release, debug|release) {
    QMAKE_CXXFLAGS += -O2
}
