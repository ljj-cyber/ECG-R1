#!/bin/bash
# 后台训练启动脚本
# 使用nohup在后台运行训练

cd /data1/buaa/lz/ECG-R1

# 创建日志目录
LOGDIR="logs"
mkdir -p ${LOGDIR}

# 生成日志文件名
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="${LOGDIR}/sft_training_${TIMESTAMP}.log"

echo "=========================================="
echo "启动ECG-R1 SFT训练"
echo "=========================================="
echo "训练脚本: scripts/shells/sft_train_reproduction.sh"
echo "日志文件: ${LOGFILE}"
echo "=========================================="
echo ""
echo "后台训练即将启动..."
echo "使用以下命令查看日志:"
echo "  tail -f ${LOGFILE}"
echo ""
echo "使用以下命令监控GPU:"
echo "  watch -n 1 nvidia-smi"
echo ""
echo "=========================================="
echo ""

# 后台启动训练
nohup bash scripts/shells/sft_train_reproduction.sh > ${LOGFILE} 2>&1 &

# 获取进程ID
PID=$!

echo "✅ 训练已启动！"
echo "   进程ID: ${PID}"
echo "   日志文件: ${LOGFILE}"
echo ""
echo "查看日志:"
echo "  tail -f ${LOGFILE}"
echo ""
echo "停止训练:"
echo "  kill ${PID}"
echo "  或: pkill -f sft_train_reproduction"
echo ""

# 等待2秒后显示初始日志
sleep 2
echo "=========================================="
echo "初始日志输出:"
echo "=========================================="
tail -20 ${LOGFILE} 2>/dev/null || echo "等待日志生成..."
echo ""
echo "=========================================="
echo "继续查看日志: tail -f ${LOGFILE}"
echo "=========================================="
