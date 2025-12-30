#!/bin/bash

# Activate virtual environment
source /venv/bin/activate

# Default values
MODEL_NAME=${MODEL_NAME:-"microsoft/DialoGPT-medium"}
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-8000}
GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION:-0.9}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-""}
TENSOR_PARALLEL_SIZE=${TENSOR_PARALLEL_SIZE:-1}
PIPELINE_PARALLEL_SIZE=${PIPELINE_PARALLEL_SIZE:-1}
DTYPE=${DTYPE:-"auto"}
QUANTIZATION=${QUANTIZATION:-""}
SERVED_MODEL_NAME=${SERVED_MODEL_NAME:-""}
TRUST_REMOTE_CODE=${TRUST_REMOTE_CODE:-"false"}
MAX_NUM_SEQS=${MAX_NUM_SEQS:-256}
MAX_NUM_BATCHED_TOKENS=${MAX_NUM_BATCHED_TOKENS:-""}
BLOCK_SIZE=${BLOCK_SIZE:-16}
SWAP_SPACE=${SWAP_SPACE:-4}
DISABLE_LOG_STATS=${DISABLE_LOG_STATS:-"false"}
DISABLE_LOG_REQUESTS=${DISABLE_LOG_REQUESTS:-"false"}
ENGINE_USE_RAY=${ENGINE_USE_RAY:-"false"}
WORKER_USE_RAY=${WORKER_USE_RAY:-"false"}
ENABLE_PREFIX_CACHING=${ENABLE_PREFIX_CACHING:-"false"}
DISABLE_SLIDING_WINDOW=${DISABLE_SLIDING_WINDOW:-"false"}
ENABLE_CHUNKED_PREFILL=${ENABLE_CHUNKED_PREFILL:-"false"}
CPU_OFFLOAD_GB=${CPU_OFFLOAD_GB:-0}
KV_CACHE_MEMORY_SIZE__GPU=${KV_CACHE_MEMORY_SIZE__GPU:-""}
KV_CACHE_MEMORY_SIZE__CPU=${KV_CACHE_MEMORY_SIZE__CPU:-""}

# Check if NVIDIA GPU is available
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    echo "NVIDIA GPU detected"
    GPU_AVAILABLE=true
else
    echo "No NVIDIA GPU detected, running on CPU"
    GPU_AVAILABLE=false
fi

# Build vLLM command
CMD_ARGS="--model $MODEL_NAME --host $HOST --port $PORT"

# Add GPU-specific options if GPU is available
if [ "$GPU_AVAILABLE" = true ]; then
    CMD_ARGS="$CMD_ARGS --gpu-memory-utilization $GPU_MEMORY_UTILIZATION"
    CMD_ARGS="$CMD_ARGS --tensor-parallel-size $TENSOR_PARALLEL_SIZE"
    CMD_ARGS="$CMD_ARGS --pipeline-parallel-size $PIPELINE_PARALLEL_SIZE"
fi

# Add optional parameters if they are set
if [ -n "$MAX_MODEL_LEN" ]; then
    CMD_ARGS="$CMD_ARGS --max-model-len $MAX_MODEL_LEN"
fi

if [ -n "$DTYPE" ] && [ "$DTYPE" != "auto" ]; then
    CMD_ARGS="$CMD_ARGS --dtype $DTYPE"
fi

if [ -n "$QUANTIZATION" ]; then
    CMD_ARGS="$CMD_ARGS --quantization $QUANTIZATION"
fi

if [ -n "$CPU_OFFLOAD_GB" ]; then
    CMD_ARGS="$CMD_ARGS --cpu-offload-gb $CPU_OFFLOAD_GB"
fi

if [ -n "$SERVED_MODEL_NAME" ]; then
    CMD_ARGS="$CMD_ARGS --served-model-name $SERVED_MODEL_NAME"
fi

if [ "$TRUST_REMOTE_CODE" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --trust-remote-code"
fi

if [ -n "$MAX_NUM_SEQS" ]; then
    CMD_ARGS="$CMD_ARGS --max-num-seqs $MAX_NUM_SEQS"
fi

if [ -n "$MAX_NUM_BATCHED_TOKENS" ]; then
    CMD_ARGS="$CMD_ARGS --max-num-batched-tokens $MAX_NUM_BATCHED_TOKENS"
fi

if [ -n "$BLOCK_SIZE" ]; then
    CMD_ARGS="$CMD_ARGS --block-size $BLOCK_SIZE"
fi

if [ -n "$SWAP_SPACE" ]; then
    CMD_ARGS="$CMD_ARGS --swap-space $SWAP_SPACE"
fi

if [ "$DISABLE_LOG_STATS" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --disable-log-stats"
fi

if [ "$DISABLE_LOG_REQUESTS" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --disable-log-requests"
fi

if [ "$ENGINE_USE_RAY" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --engine-use-ray"
fi

if [ "$WORKER_USE_RAY" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --worker-use-ray"
fi

if [ "$ENABLE_PREFIX_CACHING" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --enable-prefix-caching"
fi

if [ "$DISABLE_SLIDING_WINDOW" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --disable-sliding-window"
fi

if [ "$ENABLE_CHUNKED_PREFILL" = "true" ]; then
    CMD_ARGS="$CMD_ARGS --enable-chunked-prefill"
fi

if [ -n "$KV_CACHE_MEMORY_SIZE__GPU" ]; then
    CMD_ARGS="$CMD_ARGS --kv-cache-memory-bytes $KV_CACHE_MEMORY_SIZE__GPU"
fi

if [ -n "$KV_CACHE_MEMORY_SIZE__CPU" ]; then
  export VLLM_CPU_KVCACHE_SPACE="$KV_CACHE_MEMORY_SIZE__CPU"
fi

echo "CMD ARGS: $CMD_ARGS"

# Start vLLM server
echo -n "Starting vLLM server with command: "
echo "python3 -m vllm.entrypoints.openai.api_server $CMD_ARGS"
exec python3 -m vllm.entrypoints.openai.api_server $CMD_ARGS