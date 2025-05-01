FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
### Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3.10 \
    wget \
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

# Install ComfyUI Manager (useful for managing other nodes)
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /comfyui/custom_nodes/ComfyUI-Manager

# Install PyTorch and required dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
RUN pip3 install --no-cache-dir -r requirements.txt

### Change working directory to ComfyUI
WORKDIR /comfyui

### set comfyui to specific commit id (useful if they update and introduce bugs...)
# RUN git checkout 723847f6b3d5da21e5d712bc0139fb7197ba60a4

### Check for custom nodes 'requirements.txt' files and then run install
RUN for dir in /comfyui/custom_nodes/*/; do \
    if [ -f "$dir/requirements.txt" ]; then \
        pip3 install --no-cache-dir -r "$dir/requirements.txt"; \
    fi; \
done

### Go back to the root
WORKDIR /

### Add the src directory and example input
ADD src/ examples/test_input.json ./ 

### Install each of the defined requirements then make start.sh file executable
RUN pip3 install --no-cache-dir -r requirements.txt && chmod +x /start.sh

# Clean up after pip installs
RUN pip3 cache purge

# Copy entrypoint scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY runpod_handler.py /runpod_handler.py
COPY requirements.txt /requirements.txt

# Make scripts executable
RUN chmod +x /docker-entrypoint.sh

# Set the entry point
ENTRYPOINT ["/docker-entrypoint.sh"]