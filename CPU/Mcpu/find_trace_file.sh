#!/bin/bash
# 查找trace_dut.log文件的脚本

echo "正在查找trace_dut.log文件..."
echo ""

# 在工程目录下查找
find /home/wyyy/digital-design/CPU/Mcpu -name "trace_dut.log" -type f 2>/dev/null | while read file; do
    echo "找到文件: $file"
    echo "文件大小: $(ls -lh "$file" | awk '{print $5}')"
    echo "前10行内容:"
    head -10 "$file"
    echo "---"
done

# 在仿真目录下查找
find /home/wyyy/digital-design/CPU/Mcpu/Loongarch32_Lite.sim -name "trace_dut.log" -type f 2>/dev/null | while read file; do
    echo "找到文件: $file"
    echo "文件大小: $(ls -lh "$file" | awk '{print $5}')"
    echo "前10行内容:"
    head -10 "$file"
    echo "---"
done

echo ""
echo "查找完成！"
