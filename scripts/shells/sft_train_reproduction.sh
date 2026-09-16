#!/bin/bash
# SFT Training Script for ECG-R1 Reproduction
# 使用ecg_r1环境和提供的数据路径

set -e  # Exit on error

# Cleanup function to release resources on exit
cleanup() {
    echo "Cleaning up resources..."
    pkill -9 -f "torch.distributed.*ecg_r1" 2>/dev/null || true
    pkill -9 -f "swift.*sft.*ecg_r1" 2>/dev/null || true
    echo "Cleanup completed"
}

# Register cleanup on script exit
trap cleanup EXIT INT TERM

# Kill any existing training processes before starting
echo "Checking for existing training processes..."
ps aux | grep -E "torch.distributed|swift.*sft" | grep lz | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null || true
sleep 2

# Activate conda environment
source /opt/miniconda/etc/profile.d/conda.sh
conda activate ecg_r1

# Cache directories - 统一使用/data1/buaa/lz/.cache避免权限问题
export HF_HOME="/data1/buaa/lz/.cache/huggingface"
export HF_DATASETS_CACHE="${HF_HOME}/datasets"
export TRANSFORMERS_CACHE="${HF_HOME}/transformers"
export MODELSCOPE_CACHE="/data1/buaa/lz/.cache/modelscope"

# Temp directory - 使用数据盘避免系统盘爆满
export TMPDIR=/data2/lz/training_tmp
mkdir -p $TMPDIR

# Check and find available port
check_port() {
    netstat -tuln 2>/dev/null | grep -q ":$1 " && return 1 || return 0
}

MASTER_PORT=29800
while ! check_port $MASTER_PORT; do
    echo "Port $MASTER_PORT is in use, trying next port..."
    MASTER_PORT=$((MASTER_PORT + 1))
done
echo "Using port: $MASTER_PORT"

export NPROC_PER_NODE=8
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export MASTER_PORT=$MASTER_PORT
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Image and ECG configuration
export IMAGE_MAX_TOKEN_NUM=768
export ECG_SEQ_LENGTH=5000
export ECG_PATCH_SIZE=50
export INTERLEAVE_PROB=0.1
export MODALITY_DROPOUT_PROB=0.5

# Data paths - 使用MMECG/data下的数据
export ROOT_ECG_DIR='/data1/buaa/lz/MMECG/data/ecgr1_share/ecg_timeseries'
export ROOT_IMAGE_DIR='/data1/buaa/lz/MMECG/data/ecgr1_share/ecg_images'

# ECG Tower configuration - 使用/tmp/local_models/ECG-CoCa中的checkpoint
export ECG_TOWER_PATH='/tmp/local_models/ECG-CoCa/cpt_wfep_epoch_20.pt'
export ECG_PROJECTOR_TYPE='mlp2x_gelu'
export ECG_MODEL_CONFIG='coca_ViT-B-32'
export FREEZE_ECG_TOWER=True
export FREEZE_ECG_PROJECTOR=False

# Cache configuration - 使用自己的缓存目录避免权限问题
export HF_HOME="/data1/buaa/lz/.cache/huggingface"
export HF_DATASETS_CACHE="/data1/buaa/lz/.cache/huggingface/datasets"
export TRANSFORMERS_CACHE="/data1/buaa/lz/.cache/huggingface/transformers"

# Proxy configuration
export http_proxy=http://127.0.0.1:7892
export https_proxy=http://127.0.0.1:7892
export all_proxy=socks5://127.0.0.1:7892
export HTTP_PROXY=http://127.0.0.1:7892
export HTTPS_PROXY=http://127.0.0.1:7892
export ALL_PROXY=socks5://127.0.0.1:7892
export no_proxy=localhost,127.0.0.1

# Model path - 使用qwen3vl模型
MODEL_PATH="/tmp/local_models/qwen3vl"

# Training data - 使用官方的两个数据集（Swift会自动合并）
ECGINSTRUCT="/data1/buaa/lz/MMECG/data/ecg_protocol_grounding_cot/ecg_jsons/train_set/ECGInstruct.jsonl"
COT_30K="/data1/buaa/lz/MMECG/data/ecg_protocol_grounding_cot/ecg_jsons/train_set/ECG-Protocol-Guided-Grounding-CoT-30k.jsonl"

# Output directory
OUTPUT_DIR="output/ecg-r1-8b-sft-reproduction-$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "ECG-R1 SFT Training Reproduction"
echo "=========================================="
echo "Model: ${MODEL_PATH}"
echo "Training data:"
echo "  - ECGInstruct: ${ECGINSTRUCT}"
echo "  - CoT-30k: ${COT_30K}"
echo "Output: ${OUTPUT_DIR}"
echo "=========================================="

swift sft \
    --model "${MODEL_PATH}" \
    --model_type ecg_r1 \
    --template ecg_r1 \
    --dataset "${ECGINSTRUCT}" "${COT_30K}" \
    --custom_register_path 'ecg_r1/register.py' \
    --load_from_cache_file true \
    --split_dataset_ratio 0 \
    --train_type full \
    --torch_dtype bfloat16 \
    --num_train_epochs 1 \
    --per_device_train_batch_size 4 \
    --per_device_eval_batch_size 4 \
    --learning_rate 2e-5 \
    --freeze_vit true \
    --freeze_aligner false \
    --gradient_accumulation_steps 2 \
    --eval_steps 5000 \
    --save_steps 5000 \
    --save_total_limit 2 \
    --logging_steps 1 \
    --max_length 4096 \
    --output_dir "${OUTPUT_DIR}" \
    --warmup_ratio 0.03 \
    --dataloader_num_workers 32 \
    --dataset_num_proc 32 \
    --deepspeed zero2 \
    --attn_impl flash_attention_2 \
    --device_map null \
    --dataset_shuffle True \
    --train_dataloader_shuffle True \
    --weight_decay 0. \
    --use_hf true

# Remove trap to allow training to continue in background
trap - EXIT INT TERM

echo "=========================================="
echo "Training completed!"
echo "Output saved to: ${OUTPUT_DIR}"
echo "=========================================="
