FROM timpietruskyblibla/runpod-worker-comfy:3.1.0-sd3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    rembg[gpu] \
    opencv-python-headless \
    ultralytics \
    insightface \
    onnxruntime-gpu \
    transformers

# Create directories
RUN mkdir -p /comfyui/custom_nodes
RUN mkdir -p /comfyui/models/controlnet
RUN mkdir -p /comfyui/models/ip_adapter
RUN mkdir -p /comfyui/models/insightface

# Install ComfyUI Manager (useful for managing other nodes)
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /comfyui/custom_nodes/ComfyUI-Manager

# Install popular nodes
RUN git clone https://github.com/BlenderNeko/ComfyUI_Noise.git /comfyui/custom_nodes/ComfyUI_Noise
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git /comfyui/custom_nodes/comfyui_controlnet_aux
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git /comfyui/custom_nodes/ComfyUI_IPAdapter_plus
RUN git clone https://github.com/jags111/efficiency-nodes-comfyui.git /comfyui/custom_nodes/efficiency-nodes-comfyui
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git /comfyui/custom_nodes/ComfyUI-Custom-Scripts
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /comfyui/custom_nodes/stable-diffusion-webui-forge

# Download ControlNet models
RUN wget -O /comfyui/models/controlnet/control_v11p_sd15_canny.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth

# Download IP-Adapter models
RUN wget -O /comfyui/models/ip_adapter/ip-adapter-plus_sd15.bin https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15.bin && \
    wget -O /comfyui/models/ip_adapter/ip-adapter-plus_sd15_light.bin https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15_light.bin

# Download insightface models
RUN wget -O /comfyui/models/insightface/buffalo_l.zip https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip && \
    unzip /comfyui/models/insightface/buffalo_l.zip -d /comfyui/models/insightface/ && \
    rm /comfyui/models/insightface/buffalo_l.zip

# Copy entrypoint scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY runpod_handler.py /runpod_handler.py
COPY requirements.txt /requirements.txt

# Make scripts executable
RUN chmod +x /docker-entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
