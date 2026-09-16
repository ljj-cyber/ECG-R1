#!/bin/bash
# 创建一个简化的验证和启动脚本

set -e

echo "=========================================="
echo "ECG-R1 SFT训练 - 环境检查和启动"
echo "=========================================="
echo ""

# Python路径
PYTHON_PATH="/data1/buaa/lz/conda_envs/ecg_r1/bin/python"

# 检查关键组件
echo "1. 检查Python环境..."
$PYTHON_PATH --version
echo ""

echo "2. 检查关键依赖..."
$PYTHON_PATH -c "import torch; print('PyTorch:', torch.__version__)"
$PYTHON_PATH -c "import transformers; print('Transformers:', transformers.__version__)"
$PYTHON_PATH -c "import ms_swift; print('MS-Swift:', ms_swift.__version__)"
echo ""

echo "3. 检查Qwen3VL模型..."
if [ -d "/tmp/local_models/qwen3vl" ]; then
    echo "✓ 模型路径存在: /tmp/local_models/qwen3vl"
else
    echo "✗ 模型路径不存在"
    exit 1
fi
echo ""

echo "4. 检查训练数据..."
TRAIN_DATA="/data1/buaa/lz/MMECG/data/ecg_protocol_grounding_cot/ecg_jsons/train_set/ECG-Protocol-Guided-Grounding-CoT-30k.jsonl"
if [ -f "$TRAIN_DATA" ]; then
    LINES=$(wc -l < "$TRAIN_DATA")
    echo "✓ 训练数据存在: $LINES 条样本"
else
    echo "✗ 训练数据不存在"
    exit 1
fi
echo ""

echo "5. 检查ECG-CoCa checkpoint..."
CHECKPOINT_PATH="/data1/buaa/lz/ECG-R1/ecg_coca/open_clip/checkpoint/cpt_wfep_epoch_20.pt"
if [ -f "$CHECKPOINT_PATH" ]; then
    echo "✓ Checkpoint存在"
    ls -lh "$CHECKPOINT_PATH"
else
    echo "⚠️  Checkpoint不存在: $CHECKPOINT_PATH"
    echo ""
    echo "请下载checkpoint:"
    echo "  1. 访问 https://drive.google.com/drive/folders/1-0lRJy7PAMZ7bflbOszwhy3_ZwfTlGYB"
    echo "  2. 下载 cpt_wfep_epoch_20.pt"
    echo "  3. 放置到 $CHECKPOINT_PATH"
    echo ""
    read -p "是否已下载checkpoint? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "请下载checkpoint后重新运行"
        exit 1
    fi
fi
echo ""

echo "=========================================="
echo "✓ 环境检查完成，准备开始训练"
echo "=========================================="
echo ""

# 询问是否开始训练
read -p "是否开始训练? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消训练"
    exit 0
fi

echo ""
echo "开始训练..."
echo "=========================================="
echo ""

# 执行训练脚本
bash /data1/buaa/lz/ECG-R1/scripts/shells/sft_train_reproduction.sh
