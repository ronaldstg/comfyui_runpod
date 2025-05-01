#!/bin/bash

# Create necessary directories
mkdir -p /comfyui/custom_nodes
mkdir -p /comfyui/models/controlnet
mkdir -p /comfyui/models/ip_adapter
mkdir -p /comfyui/models/insightface

# Read the configuration file
NODES_CONFIG="/tmp/custom_nodes.json"

# Install custom nodes
echo "Installing custom nodes..."
for node in $(jq -c ".nodes[]" $NODES_CONFIG); do
  NAME=$(echo $node | jq -r ".name")
  REPO=$(echo $node | jq -r ".repo")
  BRANCH=$(echo $node | jq -r ".branch // \"main\"")
  
  echo "Installing $NAME from $REPO"
  git clone --branch $BRANCH $REPO /comfyui/custom_nodes/$NAME
  
  if [[ $(echo $node | jq "has(\"requirements\")") == "true" ]]; then
    REQS=$(echo $node | jq -r ".requirements[]" | tr "\n" " ")
    echo "Installing requirements: $REQS"
    pip install $REQS
  fi
done

# Download models
echo "Downloading models..."
for model in $(jq -c ".models[]" $NODES_CONFIG); do
  NAME=$(echo $model | jq -r ".name")
  TYPE=$(echo $model | jq -r ".type")
  URL=$(echo $model | jq -r ".url")
  EXTRACT=$(echo $model | jq -r ".extract // false")
  
  echo "Downloading $NAME from $URL"
  
  # Create destination path
  DEST="/comfyui/models/$TYPE/$NAME"
  
  # Download the model
  wget -O $DEST $URL
  
  # Extract if needed
  if [[ "$EXTRACT" == "true" ]]; then
    echo "Extracting $NAME"
    EXTRACT_DIR="/comfyui/models/$TYPE/"
    unzip -o $DEST -d $EXTRACT_DIR
    rm $DEST
  fi
done

echo "Installation completed!"
