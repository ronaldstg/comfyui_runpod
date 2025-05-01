# Troubleshooting GitHub Actions Build Issues

If you're encountering "No space left on device" errors when building your Docker image on GitHub Actions, follow these steps to resolve the issue.

## Understanding the Problem

GitHub-hosted runners have limited disk space (approximately 14GB free), which can be quickly exhausted when building large Docker images with multiple model downloads. This is particularly common with AI applications like ComfyUI that contain large model files.

## Solution: Use a Slim Docker Image With Post-Deployment Model Downloads

We've provided a solution that splits the process into two parts:

1. Build a slim Docker image without large model files
2. Download models to your RunPod network volume after deployment

## Implementation Steps

### 1. Use the Slim Dockerfile

The repository includes a `Dockerfile.slim` that doesn't download large model files during the build process. This file is now used by default in the GitHub Actions workflow.

### 2. Update Network Volume Setup

After creating and deploying your network volume on RunPod, you'll need to download the models to it:

```bash
# SSH into your temporarily deployed network volume pod
# Download the model download script
wget -O /tmp/download_models.sh https://raw.githubusercontent.com/yourusername/your-repo/main/download_models.sh
chmod +x /tmp/download_models.sh

# Run the script
/tmp/download_models.sh
```

This script will download all necessary models to your network volume, which will be mounted to your serverless ComfyUI instance when deployed.

### 3. Update Container Start Command in RunPod

When creating your serverless endpoint, use the following container start command to ensure proper linking of models:

```
sh -c "ln -sf /runpod-volume/additional_models/controlnet/* /comfyui/models/controlnet/ && ln -sf /runpod-volume/additional_models/ip_adapter/* /comfyui/models/ip_adapter/ && ln -sf /runpod-volume/additional_models/insightface/* /comfyui/models/insightface/ && ln -sf /runpod-volume/custom_nodes/* /comfyui/custom_nodes/ && /docker-entrypoint.sh"
```

## Alternative Approaches

If you still encounter disk space issues, consider these alternatives:

### 1. Self-Hosted GitHub Runner

Set up a self-hosted GitHub runner with more disk space to build your image:

```yaml
jobs:
  build-and-push:
    runs-on: self-hosted  # Use self-hosted runner instead of GitHub-hosted
```

### 2. Use a Multi-Stage Build

Create a multi-stage Dockerfile that separates the build process:

```dockerfile
# Build stage - compile any dependencies
FROM timpietruskyblibla/runpod-worker-comfy:3.1.0-sd3 AS builder
# Build dependencies here...

# Final slim image
FROM timpietruskyblibla/runpod-worker-comfy:3.1.0-sd3
COPY --from=builder /path/to/built/files /destination/path
# Rest of your Dockerfile...
```

### 3. Use External CI/CD Services

Consider using alternative CI/CD services with more generous disk space allocations, such as:
- CircleCI
- GitLab CI
- Jenkins

## Other Common Issues

### Image Pull Rate Limits

If you encounter Docker Hub rate limits, authenticate with Docker Hub in your workflow:

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v2
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

### GHCR Permission Issues

Ensure your repository has proper permissions to publish packages:
1. Go to repository Settings → Actions → General
2. Under "Workflow permissions," select "Read and write permissions"

For more help, check GitHub's documentation on [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).
