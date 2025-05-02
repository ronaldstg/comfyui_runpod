#!/bin/bash
# This script helps set up the RunPod environment for ComfyUI

# Create necessary directories in the network volume
mkdir -p /workspace/custom_nodes
mkdir -p /workspace/additional_models/checkpoints
mkdir -p /workspace/additional_models/loras
mkdir -p /workspace/additional_models/controlnet
mkdir -p /workspace/additional_models/vae
mkdir -p /workspace/additional_models/clip
mkdir -p /workspace/outputs

# Clone any additional custom nodes not included in the Docker image
git clone https://github.com/ronaldstg/comfyui-plus-integrations.git /workspace/custom_nodes/comfyui-plus-integrations

echo "RunPod environment setup completed!"
echo "Your network volume is now ready for use with ComfyUI."
echo ""
echo "You can now add custom models to /workspace/additional_models/"
echo "and custom nodes to /workspace/custom_nodes/"
echo ""
echo "Once you're finished, you can terminate this temporary pod and"
echo "create your serverless endpoint with your GHCR image."
