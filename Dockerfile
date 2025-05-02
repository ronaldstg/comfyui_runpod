FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
### Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3.10 \
    wget \
    net-tools \
    git \
### Install libs used for exporting mp4, for nodes like animatediff. can be removed if not required.
    ffmpeg \
    libpng-dev \
    libjpeg-dev \
    libgl1-mesa-glx 

### Clean up to reduce image size
RUN apt-get autoremove -y \
&& apt-get clean -y \
&& rm -rf /var/lib/apt/lists/* 

### Clone ComfyUI repository 
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

RUN rm -rf /comfyui/custom_nodes/comfyui-plus-integrations

# Install ComfyUI Manager (useful for managing other nodes)
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /comfyui/custom_nodes/ComfyUI-Manager

# Set up git to use the token
# RUN echo "https://${GIT_USERNAME}:${GIT_TOKEN}@github.com"

# RUN git config --global credential.helper store && \
#     echo "https://${GIT_USERNAME}:${GIT_TOKEN}@github.com" > /root/.git-credentials && \
#     chmod 600 /root/.git-credentials

# RUN git clone https://github.com/ronaldstg/comfyui-plus-integrations.git /comfyui/custom_nodes/comfyui-plus-integrations
# RUN git clone https://github.com/Acly/comfyui-tooling-nodes.git /comfyui/custom_nodes/comfyui-tooling-nodes

# Install PyTorch and required dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118

### Change working directory to ComfyUI
WORKDIR /comfyui

# Copy entrypoint scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY runpod_handler.py /runpod_handler.py
COPY requirements.txt /requirements.txt

RUN pip3 install --no-cache-dir -r requirements.txt

# Clean up after pip installs
RUN pip3 cache purge

# Optionally, remove credentials after cloning (for security)
# RUN rm /root/.git-credentials && \
#     git config --global --unset credential.helper

# Make scripts executable
RUN chmod +x /docker-entrypoint.sh

# Set the entry point
ENTRYPOINT ["/docker-entrypoint.sh"]