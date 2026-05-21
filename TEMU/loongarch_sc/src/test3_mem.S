# 访存指令测试程序：覆盖ld.w、st.w、ld.b、st.b
# 使用 regdef.h 中的寄存器定义，并为 x1~x6 提供宏映射到 $r1~$r6
#include "regdef.h"
#define x1  $r1
#define x2  $r2
#define x3  $r3
#define x4  $r4
#define x5  $r5
#define x6  $r6

.section .text
.global _start
_start:
    # 初始化基地址和数据
    li.w    x1, 0x80010000   # x1 = 数据存储器基地址（.data段）
    li.w    x2, 0x11223344   # x2 = 32位测试数据
    li.w    x3, 0x55         # x3 = 8位测试数据（低8位）

    # 存储指令：st.w（32位存储）
    st.w    x2, x1, 0        # 将x2写入地址0x80010000

    # 加载指令：ld.w（32位加载）
    ld.w    x4, x1, 0        # 从0x80010000加载数据到x4（应等于x2）

    # 存储指令：st.b（8位存储）
    st.b    x3, x1, 4        # 将x3的低8位写入地址0x80010004

    # 加载指令：ld.b（8位加载，符号扩展）
    ld.b    x5, x1, 4        # 从0x80010004加载数据到x5（应等于0x00000055）

    # 验证加载结果
    add.w   x6, x4, x5       # x6 = 0x11223344 + 0x55 = 0x11223399

    # 填充至20条指令
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
    nop
    nop
    nop
    nop
    nop

loop:
    b       loop             # 死循环