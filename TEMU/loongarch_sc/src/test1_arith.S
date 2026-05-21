# 算术/逻辑指令测试程序：覆盖add.w、addi.w、andi、or、ori、xor、sltui
# 使用 regdef.h 中的寄存器定义，并为 x0~x15 提供宏映射到 $r0~$r15
# 便于和课程材料中的“x寄存器命名”保持一致
#include "regdef.h"
#define x0  $r0
#define x1  $r1
#define x2  $r2
#define x3  $r3
#define x4  $r4
#define x5  $r5
#define x6  $r6
#define x7  $r7
#define x8  $r8
#define x9  $r9
#define x10 $r10
#define x11 $r11
#define x12 $r12
#define x13 $r13
#define x14 $r14
#define x15 $r15

.section .text
.global _start
_start:
    # 初始化寄存器
    li.w    x0, 0x00000000   # x0恒为0，验证零寄存器特性
    li.w    x1, 0x00001111   # x1 = 0x1111
    li.w    x2, 0x00002222   # x2 = 0x2222
    li.w    x3, 0x0000FFFF   # x3 = 0xFFFF
    li.w    x4, 0x000000FF   # x4 = 0xFF

    # 3R型算术指令：add.w
    add.w   x5, x1, x2       # x5 = 0x1111 + 0x2222 = 0x3333
    add.w   x6, x3, x4       # x6 = 0xFFFF + 0xFF = 0x100FE

    # 2RI12型算术指令：addi.w
    addi.w  x7, x5, 0x0001   # x7 = 0x3333 + 1 = 0x3334
    addi.w  x8, x6, -0x0002  # x8 = 0x100FE - 2 = 0x100FC

    # 逻辑指令：or（3R型）
    or      x9, x1, x2       # x9 = 0x1111 | 0x2222 = 0x3333

    # 逻辑指令：ori（2RI12型，零扩展）
    ori     x10, x3, 0x000F  # x10 = 0xFFFF | 0xF = 0xFFFF
    ori     x15, x1, 0x00F0  # 额外一条ori，验证立即数与不同源寄存器组合

    # 逻辑指令：andi（2RI12型，零扩展）
    andi    x11, x3, 0x00F0  # x11 = 0xFFFF & 0xF0 = 0xF0

    # 逻辑指令：xor（3R型）
    xor     x12, x1, x2      # x12 = 0x1111 ^ 0x2222 = 0x3333

    # 比较指令：sltui（无符号小于，2RI12型），立即数需在 12 位范围内
    sltui   x13, x1, 0x0222  # x1=0x1111 < 0x0222? 这里主要测试无符号比较路径
    sltui   x14, x2, 0x0111  # 使用较小立即数，避免超出 ui12 范围

    # 填充至20条指令，避免程序跑飞
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

loop:
    b       loop             # 死循环，保持程序运行