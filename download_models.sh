#!/bin/bash
# Script to download models to the RunPod network volume
# Run this after setting up your network volume

set -e

echo "Creating model directories..."
mkdir -p /workspace/additional_models/controlnet
mkdir -p /workspace/additional_models/ip_adapter
mkdir -p /workspace/additional_models/insightface
mkdir -p /workspace/additional_models/checkpoints
mkdir -p /workspace/additional_models/loras
mkdir -p /workspace/additional_models/vae

echo "Downloading ControlNet models..."
wget -O /workspace/additional_models/controlnet/control_v11p_sd15_canny.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth

echo "Downloading IP-Adapter models..."
wget -O /workspace/additional_models/ip_adapter/ip-adapter-plus_sd15.bin https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15.bin
wget -O /workspace/additional_models/ip_adapter/ip-adapter-plus_sd15_light.bin https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15_light.bin

echo "Downloading InsightFace models..."
wget -O /workspace/additional_models/insightface/buffalo_l.zip https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip
unzip -o /workspace/additional_models/insightface/buffalo_l.zip -d /workspace/additional_models/insightface/
rm /workspace/additional_models/insightface/buffalo_l.zip

echo "All models downloaded successfully!"
echo "Remember to terminate this temporary pod after completion."
