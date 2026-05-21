# 1. TEMU工程目录介绍

· 目录结构：

	+--loongarch_sc/        	: 测试程序目录
	|        
	|--temu/		        	: temu源程序目录
	|
	|--gui/                     : GUI图形界面目录（新增）
	|
	|--Makefile			        : make脚本

· 目录"loongarch_sc"用于保存测试程序，并对其进行编译，包含build和src文件夹，convert.c，default.ld， Makefile文件。
目前测试程序仅支持汇编形式。

# 2. TEMU的使用步骤

## 2.1 控制台模式（命令行界面）

· (1). 在终端进入目录"loongarch_sc"，输入"make"，编译测试程序。此时，在TEMU工程根目录下生成两个可加载的二进制文件"inst.bin"和"data.bin"，分别对应测试程序的指令段和数据段。

· (2). 在终端退回TEMU工程根目录，输入"make run"，编译temu指令集仿真器并启动。

· (3). 如果需要重新编译测试程序和temu仿真器源代码，请在TEMU工程根目录下输入"make clean"，然后重复前两步。

· (4). 如果只想编译temu仿真器源代码，请在TEMU工程根目录下输入"make clean-temu"，然后再输入"make run"即可。

## 2.2 图形界面模式（GUI）

### 2.2.1 环境要求

- Qt 5.x 或更高版本
- qmake 工具
- C++ 编译器（g++）

**安装依赖（Ubuntu/Debian）：**
```bash
sudo apt update
sudo apt install qt5-qmake qtbase5-dev qtbase5-dev-tools g++ build-essential
```

### 2.2.2 编译GUI版本

```bash
# 在TEMU工程根目录下
make gui
```

这将编译GUI版本的TEMU仿真器，生成的可执行文件位于 `gui/temu_gui`

### 2.2.3 运行GUI版本

```bash
# 确保已编译测试程序（生成inst.bin和data.bin）
cd loongarch_sc
make

# 返回根目录，运行GUI
cd ..

# 方法1：直接运行（需要图形界面环境）
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.LCW9H3
./gui/temu_gui

# 方法2：使用启动脚本（推荐，会设置DISPLAY）
./start_gui
```

### 2.2.4 GUI功能说明
![输入图片说明](%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-12-28%20174701.png)
**主窗口布局：**
- **左侧面板**：寄存器视图，显示32个通用寄存器和PC的值
- **右上区域**：代码视图，显示加载的指令代码，高亮当前PC位置
- **右下区域**：内存视图，显示代码段和数据段的内存内容
- **底部**：控制面板，包含运行控制按钮

**主要功能：**
1. **加载程序**：点击"Load"按钮或菜单 File → Load Program 加载inst.bin和data.bin
2. **运行控制**：
   - **Run**：连续执行程序（对应控制台的`c`命令）
   - **Pause**：暂停执行
   - **Step**：单步执行一条指令（对应`si`命令）
   - **Reset**：重置仿真器状态
3. **调试功能**：
   - **Watchpoints**：菜单 Debug → Watchpoints 打开监视点管理对话框
   - **Evaluate Expression**：菜单 Debug → Evaluate Expression 计算表达式值
4. **视图更新**：所有视图会实时更新，显示当前CPU状态

**快捷键：**
- F5: Run
- F6: Pause
- F10: Step
- F9: Reset
- Ctrl+E: Evaluate Expression

### 2.2.5 清理GUI构建文件

```bash
make clean-gui
```

这将清理GUI相关的构建文件。
