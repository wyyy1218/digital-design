# 特殊指令测试程序：覆盖lu12i.w、pcaddu12i
# 使用 regdef.h 中的寄存器定义，并为 x1~x7 提供宏映射到 $r1~$r7
#include "regdef.h"
#define x1  $r1
#define x2  $r2
#define x3  $r3
#define x4  $r4
#define x5  $r5
#define x6  $r6
#define x7  $r7

.section .text
.global _start
_start:
    # lu12i.w（1RI20型，加载12位立即数到高20位）
    lu12i.w x1, 0x1234       # x1 = 0x1234 << 12 = 0x12340000
    lu12i.w x2, 0x0FFF       # x2 = 0x0FFF << 12 = 0x0FFF0000

    # 组合测试：lu12i.w + ori（拼接32位立即数）
    ori     x3, x1, 0x678    # x3 ≈ 0x12340000 | 0x678

    # pcaddu12i（PC+12位立即数左移12位）
    pcaddu12i x4, 0x10       # x4 = PC + (0x10 << 12)
                             # PC初始为0x80000000 → x4 约为 0x80010000
    pcaddu12i x6, 0x0001     # 额外一条pcaddu12i，偏移较小用于对比

    # 验证结果
    add.w   x5, x3, x4       # x5 = 0x12345678 + 0xD6780000 = 0xE8AC5678
    add.w   x7, x3, x6       # 使用第二个pcaddu12i结果，检查PC相关偏移是否一致

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