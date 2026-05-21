# 移位/分支指令测试程序：覆盖sra.w、beq、bne、bge
# 直接使用 LoongArch 工具链推荐的 $寄存器命名

.section .text
.global _start
_start:
    # 初始化寄存器
    li.w    $r1, 0x80000000   # r1 = 0x80000000（负数，最高位1）
    li.w    $r2, 0x00000004   # r2 = 4（移位量）
    li.w    $r3, 0x00000001   # r3 = 1
    li.w    $r4, 0x00000001   # r4 = 1
    li.w    $r5, 0x00000002   # r5 = 2

    # 移位指令：sra.w（算术右移，3R型）
    sra.w   $r6, $r1, $r2     # r6 = 0x80000000 >> 4
    sra.w   $r7, $r6, $r2     # r7 继续右移

    # 分支指令：beq（相等则跳转）
    beq     $r3, $r4, label1  # r3=r4，跳转到label1
    nop                       # 不会执行
label1:
    add.w   $r8, $r3, $r4     # r8 = 1 + 1 = 2
    beq     $r8, $r5, label1_not_taken # 构造一次“可能不跳”的场景
    nop                       # 若发生跳转则执行，用于观测
label1_not_taken:

    # 分支指令：bne（不等则跳转）
    bne     $r3, $r5, label2  # r3≠r5，跳转到label2
    nop                       # 不会执行
label2:
    add.w   $r9, $r4, $r5     # r9 = 1 + 2 = 3

    # 分支指令：bge（大于等于则跳转，有符号）
    bge     $r5, $r3, label3  # 2≥1，跳转到label3
    nop                       # 不会执行
label3:
    add.w   $r10, $r5, $r3    # r10 = 2 + 1 = 3
    bge     $r3, $r5, label3_not_taken # 1≥2 为假，不跳转
    nop
label3_not_taken:

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

loop:
    b       loop             # 死循环