# 综合指令测试程序：覆盖所有指令，模拟Load-Use冒险
# 使用 regdef.h 中的寄存器定义，并为 x1~x12 提供宏映射到 $r1~$r12
#include "regdef.h"
#define x1   $r1
#define x2   $r2
#define x3   $r3
#define x4   $r4
#define x5   $r5
#define x6   $r6
#define x7   $r7
#define x8   $r8
#define x9   $r9
#define x10  $r10
#define x11  $r11
#define x12  $r12

.section .text
.global _start
_start:
    # 初始化寄存器
    li.w    x1, 0x80010000   # 数据存储器基地址
    li.w    x2, 0x0000000A   # 测试数据A
    li.w    x3, 0x00000005   # 测试数据B
    li.w    x4, 0x00000008   # 移位量

    # Load-Use冒险场景：ld.w后紧跟依赖指令
    st.w    x2, x1, 0        # 先存储数据到内存
    ld.w    x5, x1, 0        # 加载数据到x5（触发Load-Use冒险，流水线暂停1周期）
    add.w   x6, x5, x3       # 依赖x5，验证暂停后数据正确

    # 算术+逻辑+移位组合
    addi.w  x7, x6, 0x0002   # x7 = x6 + 2 = 15
    andi    x8, x7, 0x000F   # x8 = 15 & 0xF = 15
    sra.w   x9, x8, x4       # x9 = 15 >> 8 = 0

    # 分支+访存组合
    bne     x9, x3, label1   # x9=0 ≠ x3=5，跳转到label1
    nop                     # 不会执行
label1:
    st.b    x9, x1, 4        # 存储x9的低8位到内存
    ld.b    x10, x1, 4       # 加载验证

    # 特殊指令+逻辑组合
    lu12i.w x11, 0xABCD      # x11 = 0xABCD0000
    or      x12, x11, x10    # x12 = 0xABCD0000 | 0 = 0xABCD0000

    # 填充至20条指令
    nop
    nop
    nop
    nop
    nop

loop:
    b       loop             # 死循环