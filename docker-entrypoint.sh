#!/bin/bash
set -e

# Create symbolic links to network volume if available
if [ -d "/runpod-volume" ]; then
    echo "RunPod volume detected, creating symbolic links..."
    
    # Link custom nodes directory
    if [ -d "/runpod-volume/custom_nodes" ]; then
        echo "Linking custom nodes from network volume..."
        find /runpod-volume/custom_nodes -mindepth 1 -maxdepth 1 -type d -exec ln -sf {} /comfyui/custom_nodes/ \;
    fi
    
    # Link additional models if they exist
    if [ -d "/runpod-volume/additional_models" ]; then
        echo "Linking additional models from network volume..."
        
        # Link checkpoints
        if [ -d "/runpod-volume/additional_models/checkpoints" ]; then
            find /runpod-volume/additional_models/checkpoints -type f -exec ln -sf {} /comfyui/models/checkpoints/ \;
        fi
        
        # Link loras
        if [ -d "/runpod-volume/additional_models/loras" ]; then
            find /runpod-volume/additional_models/loras -type f -exec ln -sf {} /comfyui/models/loras/ \;
        fi
        
        # Link VAEs
        if [ -d "/runpod-volume/additional_models/vae" ]; then
            find /runpod-volume/additional_models/vae -type f -exec ln -sf {} /comfyui/models/vae/ \;
        fi
        
        # Link ControlNet models
        if [ -d "/runpod-volume/additional_models/controlnet" ]; then
            find /runpod-volume/additional_models/controlnet -type f -exec ln -sf {} /comfyui/models/controlnet/ \;
        fi
        
        # Link CLIP models
        if [ -d "/runpod-volume/additional_models/clip" ]; then
            find /runpod-volume/additional_models/clip -type f -exec ln -sf {} /comfyui/models/clip/ \;
        fi
    fi
    
    # Make output directory in network volume
    mkdir -p /runpod-volume/outputs
    
    # Create a link to the network volume outputs
    if [ -d "/runpod-volume/outputs" ] && [ -d "/comfyui/output" ]; then
        # Create a link from ComfyUI output to runpod volume
        rm -rf /comfyui/output
        ln -sf /runpod-volume/outputs /comfyui/output
    fi
fi

# Check for serverless mode
if [ "$RUNPOD_SERVERLESS" = "1" ]; then
    echo "Running in serverless mode, starting RunPod handler..."
    
    # Install needed packages for handler
    pip install -r /requirements.txt
    
    # Start ComfyUI in the background
    nohup python /comfyui/main.py --listen 0.0.0.0 --port 8188 > /comfyui.log 2>&1 &
    
    # Wait for ComfyUI to start
    echo "Waiting for ComfyUI to start..."
    until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:8188); do
        echo -n "."
        sleep 1
    done
    echo "ComfyUI started successfully!"
    
    # Start the RunPod handler
    python /runpod_handler.py
else
    # Start ComfyUI normally
    echo "Starting ComfyUI in regular mode..."
    python /comfyui/main.py --listen 0.0.0.0 --port 8188
fi
