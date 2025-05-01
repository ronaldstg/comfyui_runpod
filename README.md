# ComfyUI RunPod Deployment

This repository contains everything needed to deploy a custom ComfyUI image on RunPod's serverless platform using GitHub Container Registry (GHCR).

## Features

- Custom ComfyUI Docker image with popular nodes pre-installed
- GitHub Actions workflow for automatic building and publishing to GHCR
- Support for modular node and model installation
- Ready for deployment on RunPod serverless

## Included ComfyUI Nodes

- ComfyUI-Manager - Node management utility
- ComfyUI_Noise - Noise generation nodes
- comfyui_controlnet_aux - ControlNet auxiliaries
- ComfyUI_IPAdapter_plus - IP-Adapter integration
- efficiency-nodes-comfyui - Efficiency enhancing nodes
- ComfyUI-Custom-Scripts - Various quality of life scripts
- stable-diffusion-webui-forge - SD WebUI Forge integration

## Included Models

- ControlNet Canny
- IP-Adapter Plus models
- InsightFace models

## Important Note About GitHub Actions

This repository includes both full and slim Dockerfile configurations. Due to GitHub Actions disk space limitations, the workflow is configured to use the slim version (`Dockerfile.slim`) by default. The slim version excludes large model downloads, which should be added to your RunPod network volume after deployment using the included `download_models.sh` script.

If you encounter build errors with "No space left on device", please see the `TROUBLESHOOTING.md` file for solutions.

## Getting Started

### Prerequisites

- GitHub account
- Docker (for local testing)
- RunPod account

### Setup Instructions

1. **Fork/Clone this Repository**

   Clone this repository to your GitHub account.

2. **Configure GitHub Container Registry**

   Make sure your repository has the necessary permissions to publish packages.

3. **Build the Docker Image**

   The image will be built automatically by GitHub Actions when you push to the main branch or create a tag.

   To build locally:

   ```bash
   docker build -t comfyui-custom .
   ```

4. **Run Locally for Testing**

   ```bash
   docker-compose up
   ```

   Then navigate to `http://localhost:8188` in your browser.

5. **Deploy on RunPod**

   - Create a Network Volume on RunPod
   - Create a Serverless Endpoint with your GHCR image: `ghcr.io/yourusername/comfyui-custom:latest`
   - Add Container Start Command (if using custom nodes in volume):
     ```
     sh -c "ln -sf /runpod-volume/custom_nodes/* /comfyui/custom_nodes && /start.sh"
     ```
   - Configure environment variables for S3 if needed

### Using Your Own Custom Nodes

1. **Edit the `custom_nodes.json` file**

   Add your custom nodes to the JSON file:

   ```json
   {
     "nodes": [
       {
         "name": "your-custom-node",
         "repo": "https://github.com/yourusername/your-custom-node.git",
         "branch": "main",
         "description": "Description of your node",
         "requirements": ["package1", "package2"]
       }
     ]
   }
   ```

2. **Rebuild the Docker Image**

   The next push to your repository will trigger a rebuild with your custom nodes.

## Customizing the Image

### Using the Modular Dockerfile

For a more modular approach, use `Dockerfile.modular` which loads nodes and models from the `custom_nodes.json` file:

```bash
docker build -f Dockerfile.modular -t comfyui-custom-modular .
```

### Adding More Models

Add models to the `custom_nodes.json` file under the `models` section:

```json
{
  "models": [
    {
      "name": "your-model.safetensors",
      "type": "checkpoints",
      "url": "https://example.com/your-model.safetensors",
      "description": "Your custom model"
    }
  ]
}
```

## RunPod Deployment Details

### Network Volume Setup

1. Create a Network Volume on RunPod
2. Deploy it temporarily to configure
3. Access the terminal and create a folder structure:
   ```bash
   cd /workspace
   mkdir -p custom_nodes additional_models
   ```
4. Add any additional custom nodes or models that weren't included in the Docker image

### Serverless Endpoint Configuration

1. Create a new Serverless Endpoint on RunPod
2. Select your desired GPU
3. Use your GHCR image: `ghcr.io/yourusername/comfyui-custom:latest`
4. Add environment variables for S3 storage if needed:
   ```
   BUCKET_ENDPOINT_URL=https://bucket.s3.region.amazonaws.com
   BUCKET_ACCESS_KEY_ID=your-access-key
   BUCKET_SECRET_ACCESS_KEY=your-secret-key
   ```
5. Add container disk space (at least 20GB recommended)

## Troubleshooting

### Image Pull Issues

If RunPod can't pull your image, check:
1. Repository visibility settings
2. Container registry credentials in RunPod
3. Image tag is correct

### Missing Nodes

If nodes are missing:
1. Check the logs in RunPod
2. Verify the node installation in the Dockerfile
3. Make sure requirements are properly installed

## License

This project is licensed under the MIT License - see the LICENSE file for details.
