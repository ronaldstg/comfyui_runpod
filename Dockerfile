FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /comfyui

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI .

# Create and activate virtual environment
RUN python3 -m venv venv
ENV PATH="/comfyui/venv/bin:$PATH"

# Install PyTorch and required dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
RUN pip3 install --no-cache-dir -r requirements.txt

# Create directories for models
RUN mkdir -p /comfyui/models/checkpoints
RUN mkdir -p /comfyui/models/vae
RUN mkdir -p /comfyui/models/loras
RUN mkdir -p /comfyui/models/controlnet
RUN mkdir -p /comfyui/models/clip
RUN mkdir -p /comfyui/models/clip_vision
RUN mkdir -p /comfyui/models/gligen
RUN mkdir -p /comfyui/models/upscale_models
RUN mkdir -p /comfyui/models/embeddings
RUN mkdir -p /comfyui/models/unet
RUN mkdir -p /comfyui/input
RUN mkdir -p /comfyui/output

# Install ComfyUI Manager (useful for managing other nodes)
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /comfyui/custom_nodes/ComfyUI-Manager

# Copy entrypoint scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY runpod_handler.py /runpod_handler.py
COPY requirements.txt /requirements.txt

# Make scripts executable
RUN chmod +x /docker-entrypoint.sh

# Set the entry point
ENTRYPOINT ["/docker-entrypoint.sh"]