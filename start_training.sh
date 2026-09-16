#!/bin/bash
# 一键检查并启动ECG-R1 SFT训练的主脚本

cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║         ECG-R1 SFT Training Reproduction Script          ║
║                    环境: ecg_r1                          ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
echo "📋 检查清单:"
echo "  1. Python环境 (ecg_r1)"
echo "  2. Qwen3-VL模型"
echo "  3. 训练数据 (30k CoT)"
echo "  4. ECG数据路径"
echo "  5. ECG-CoCa Checkpoint ⚠️"
echo ""

# 快速测试
cd /data1/buaa/lz/ECG-R1

# 运行环境测试
echo "🔍 运行环境测试..."
echo ""

if bash test_environment.sh; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  ✅ 所有检查通过！准备启动训练                            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    # 显示训练配置
    echo "📊 训练配置:"
    echo "  • 模型: Qwen3-VL-8B + ECG-CoCa"
    echo "  • 数据: 30,000 条 CoT 样本"
    echo "  • GPU: 8 卡训练"
    echo "  • Batch Size: 64 (effective)"
    echo "  • 学习率: 2e-5"
    echo "  • Epochs: 1"
    echo "  • 预计时长: 4-8 小时"
    echo ""

    read -p "🚀 是否立即开始训练? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "▶️  启动训练..."
        echo ""
        bash scripts/shells/sft_train_reproduction.sh
    else
        echo ""
        echo "取消训练。稍后可运行:"
        echo "  bash scripts/shells/sft_train_reproduction.sh"
        echo ""
    fi
else
    EXIT_CODE=$?
    echo ""
    if [ $EXIT_CODE -eq 1 ]; then
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  ⚠️  需要下载 ECG-CoCa Checkpoint                         ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""
        echo "📥 下载步骤:"
        echo "  1. 访问: https://drive.google.com/drive/folders/1-0lRJy7PAMZ7bflbOszwhy3_ZwfTlGYB"
        echo "  2. 下载: cpt_wfep_epoch_20.pt"
        echo "  3. 放置到: /data1/buaa/lz/ECG-R1/ecg_coca/open_clip/checkpoint/"
        echo ""
        echo "💡 下载完成后重新运行此脚本"
        echo ""
    else
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  ❌ 环境检查失败，请查看错误信息                          ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""
    fi
    exit $EXIT_CODE
fi
