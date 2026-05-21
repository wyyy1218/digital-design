# digital-design

数字设计课程实验代码：逻辑门与 ALU、UART、LoongArch32 Lite 五级流水 CPU、SoC 集成与 TEMU 指令集仿真器。

开发环境：Vivado 2018.3，龙芯实验箱（cg_fpga），交叉工具链 `loongarch32r-linux-gnusf-`。

## 目录结构

```
digital-design/
├── labs/
│   ├── lab0-logic-gate/     # 实验0：逻辑门
│   ├── lab1-alu/            # 实验1：32 位 ALU
│   └── lab2-uart/           # 实验2：UART
├── CPU/                     # 实验4 阶段一：CPU 核（Mcpu 流水线 / Scpu 单周期）
├── SOC/                     # 实验4 阶段二：SoC 与 FPGA 综合
├── TEMU/                    # 实验3/4：指令集仿真器
├── tests/trace/             # Golden trace 基准
└── tools/trace_diff.py      # trace 对比脚本
```

前期实验工程在 `labs/` 下；实验 3、4 与课程仓库布局一致，模块位于仓库根目录。

## 实验 0–2（Vivado）

1. 用 Vivado 打开对应工程，例如 `labs/lab0-logic-gate/logic_gate.xpr`。
2. 若提示源文件路径变化，在 Flow Navigator 中对缺失文件执行 **Reset Project** 或手动 **Add Sources**（保持 `.xpr` 与 `*.srcs` 同级）。
3. 综合 → 实现 → 生成 bitstream → 下载到实验箱。

| 实验 | 工程文件 |
|------|----------|
| Lab0 | `labs/lab0-logic-gate/logic_gate.xpr` |
| Lab1 | `labs/lab1-alu/ALU_32bits.xpr` |
| Lab2 | `labs/lab2-uart/UART.xpr` |

## 实验 4：CPU

1. 打开 `CPU/Mcpu/Loongarch32_Lite.xpr`（流水线）或 `CPU/Scpu/Loongarch32_Lite.xpr`（单周期）。
2. 行为仿真：在 Vivado 中运行 `tb_Loongarch_Lite_FullSyS`。
3. Trace 对比（Mcpu 目录下）：

```bash
cd CPU/Mcpu
./run_trace_compare.sh
```

仿真输出 trace 与 `tests/trace/golden_*.trace` 可用 `tools/trace_diff.py` 比对。

## 实验 4：SoC

1. 在 `SOC/` 下编译测试程序并生成 COE（需已安装 `loongarch32r-linux-gnusf-` 工具链）：

```bash
cd SOC
make USER_PROGRAM=custom_test
```

输出在 `SOC/build/`（已 gitignore，本地生成）。

2. 在 Vivado 中打开 `SOC/Loongarch32_Lite_FullSyS.xpr`，将 `inst_rom`、`data_ram` IP 的初始化文件指向 `build/` 下对应 `.coe`。
3. 综合、实现、生成 bitstream 并下板。
4. 仿真 testbench：`Loongarch32_Lite_FullSyS.srcs/sim_1/new/tb_SOC_benchtest.sv`、`tb_SOC_custom_test.sv`。

## TEMU 仿真器

```bash
cd TEMU
make run          # 命令行模式
make gui          # 图形界面（需 Qt5 + qmake）
make clean        # 清理后重新编译
```

测试程序目录：`TEMU/loongarch_sc/`。编译后在工程根目录生成 `inst.bin`、`data.bin` 供仿真加载。

## Trace 验证

Golden 文件位于 `tests/trace/`。对比示例：

```bash
python3 tools/trace_diff.py tests/trace/golden_test1.trace <your_trace.txt>
```

## 参考

历史备份：[Gitee jiyi127/digital-design](https://gitee.com/jiyi127/digital-design)（本仓库为整理后的完整版本）。
