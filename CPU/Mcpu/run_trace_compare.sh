#!/bin/bash
# 快速运行trace对比脚本
# 使用方法: ./run_trace_compare.sh <test_number>
# 例如: ./run_trace_compare.sh 1

if [ $# -ne 1 ]; then
    echo "用法: $0 <test_number>"
    echo "例如: $0 1  (对比test1_arith)"
    exit 1
fi

TEST_NUM=$1
PROJECT_ROOT="/home/wyyy/digital-design"
TRACE_DIR="${PROJECT_ROOT}/CPU/Mcpu"
GOLDEN_TRACE="${PROJECT_ROOT}/tests/trace/golden_test${TEST_NUM}.trace"

# 尝试多个可能的trace文件位置
TRACE_FILE1="${TRACE_DIR}/trace_dut_test${TEST_NUM}.log"
TRACE_FILE2="${TRACE_DIR}/Loongarch32_Lite.sim/sim_1/behav/xsim/trace_dut_test${TEST_NUM}.log"
TRACE_FILE3="${TRACE_DIR}/trace_dut.log"

# 查找trace文件
if [ -f "$TRACE_FILE1" ]; then
    DUT_TRACE="$TRACE_FILE1"
elif [ -f "$TRACE_FILE2" ]; then
    DUT_TRACE="$TRACE_FILE2"
elif [ -f "$TRACE_FILE3" ]; then
    DUT_TRACE="$TRACE_FILE3"
    echo "警告: 使用默认trace_dut.log，建议重命名为trace_dut_test${TEST_NUM}.log"
else
    echo "错误: 找不到trace文件"
    echo "请检查以下位置:"
    echo "  - $TRACE_FILE1"
    echo "  - $TRACE_FILE2"
    echo "  - $TRACE_FILE3"
    exit 1
fi

# 检查golden trace文件
if [ ! -f "$GOLDEN_TRACE" ]; then
    echo "错误: 找不到golden trace文件: $GOLDEN_TRACE"
    exit 1
fi

# 运行对比
echo "=========================================="
echo "对比 test${TEST_NUM} 的trace文件"
echo "=========================================="
echo "Golden Trace: $GOLDEN_TRACE"
echo "DUT Trace:    $DUT_TRACE"
echo ""

cd "$PROJECT_ROOT"
python tools/trace_diff.py "$GOLDEN_TRACE" "$DUT_TRACE"

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ test${TEST_NUM} 通过！"
else
    echo ""
    echo "❌ test${TEST_NUM} 失败！请检查波形定位问题。"
fi

exit $EXIT_CODE
