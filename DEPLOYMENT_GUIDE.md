# ComfyUI RunPod Deployment Guide

This guide provides step-by-step instructions for deploying your customized ComfyUI Docker image on RunPod serverless using GitHub Container Registry (GHCR).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [GitHub Repository Setup](#github-repository-setup)
3. [Building and Publishing the Docker Image](#building-and-publishing-the-docker-image)
4. [RunPod Network Volume Setup](#runpod-network-volume-setup)
5. [RunPod Serverless Deployment](#runpod-serverless-deployment)
6. [Testing Your Deployment](#testing-your-deployment)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- GitHub account
- Docker installed locally (for testing)
- RunPod account with credits
- Basic knowledge of Git and Docker

## GitHub Repository Setup

1. **Create a New GitHub Repository**

   Create a new repository on GitHub and clone it to your local machine.

2. **Copy the Project Files**

   Copy all the files from this directory to your local repository:

   ```bash
   cp -r /path/to/comfyui_runpod/* /path/to/your/repo/
   ```

3. **Customize the Configuration**

   Edit the following files to customize your deployment:

   - `custom_nodes.json`: Add or remove custom nodes
   - `Dockerfile` or `Dockerfile.modular`: Modify if you need additional dependencies
   - `README.md`: Update with your project information

4. **Push to GitHub**

   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

## Building and Publishing the Docker Image

### Option 1: Automatic Build using GitHub Actions

1. **Enable GitHub Actions**

   Go to your repository on GitHub, click on the "Actions" tab, and enable GitHub Actions.

2. **Configure Package Access**

   Ensure that your repository has permissions to publish packages:
   - Go to your repository settings
   - Navigate to "Actions" > "General"
   - Under "Workflow permissions", select "Read and write permissions"
   - Save changes

3. **Trigger a Workflow Run**

   Either push changes to the `main` branch or create a tag to trigger the workflow:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **Verify the Image**

   After the workflow completes, check your GitHub repository's "Packages" section to verify your image was published successfully.

### Option 2: Manual Building and Publishing

If you prefer to build and push the image manually:

1. **Login to GitHub Container Registry**

   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
   ```

2. **Build the Docker Image**

   ```bash
   docker build -t ghcr.io/yourusername/comfyui-custom:latest .
   ```

3. **Push the Image to GHCR**

   ```bash
   docker push ghcr.io/yourusername/comfyui-custom:latest
   ```

## RunPod Network Volume Setup

Network volumes allow for persistent storage of custom nodes, models, and outputs.

1. **Create a Network Volume**

   - Go to RunPod dashboard and select "Storage" in the sidebar
   - Click "New Network Volume"
   - Choose a data center location (preferably the same as where you'll deploy your serverless instance)
   - Set a name for the volume (e.g., "comfyui-data")
   - Choose a storage size (20-50GB recommended)
   - Create the volume

2. **Configure the Network Volume**

   - Deploy your new volume temporarily to set it up
   - Choose a small/cheap GPU as this is temporary
   - Connect to the terminal through web interface
   - Run the setup script you copied to the repo:

   ```bash
   # Copy setup script to the instance
   wget -O /tmp/setup_runpod.sh https://raw.githubusercontent.com/yourusername/your-repo/main/setup_runpod.sh
   chmod +x /tmp/setup_runpod.sh
   
   # Run the setup script
   /tmp/setup_runpod.sh
   ```

3. **Add Custom Files (Optional)**

   If you want to add models or nodes that aren't included in your Docker image:

   ```bash
   # Example: Add a custom checkpoint model
   cd /workspace/additional_models/checkpoints
   wget https://example.com/path/to/your-model.safetensors
   
   # Example: Add a custom node
   cd /workspace/custom_nodes
   git clone https://github.com/username/custom-node.git
   ```

4. **Terminate the Temporary Deployment**

   Once you've set up the network volume, go back to the Pods section and terminate the temporary pod.

## RunPod Serverless Deployment

1. **Create a Serverless Endpoint**

   - Go to RunPod dashboard and select "Serverless" in the sidebar
   - Click "New Endpoint"
   - Select GPU type (recommend at least 16GB VRAM for good performance)
   - Enter endpoint name (e.g., "comfyui-serverless")

2. **Configure the Container**

   - For Container Image, enter your GHCR image URL:
     ```
     ghcr.io/yourusername/comfyui-custom:latest
     ```
   
   - If your repository is private, add Container Registry Credentials:
     - Registry URL: `ghcr.io`
     - Username: Your GitHub username
     - Password: Your GitHub Personal Access Token with `read:packages` scope

   - For Container Disk, set at least 20GB
   
   - Add environment variables to enable S3 storage (optional):
     ```
     BUCKET_ENDPOINT_URL=https://bucket.s3.region.amazonaws.com
     BUCKET_ACCESS_KEY_ID=your-access-key
     BUCKET_SECRET_ACCESS_KEY=your-secret-key
     ```

   - Set RUNPOD_SERVERLESS environment variable:
     ```
     RUNPOD_SERVERLESS=1
     ```

3. **Choose Network Volume**

   - Select the network volume you created earlier
   - Volume Mount Path: `/runpod-volume`

4. **Advanced Settings**

   - Idle timeout: Set based on your needs (10-30 minutes recommended)
   - Max Workers: Set based on your needs and budget
   - Leave other settings at default values

5. **Deploy the Endpoint**

   Click "Deploy" to create your serverless endpoint.

6. **Create an API Key**

   - Go to Settings in the sidebar
   - Create a new API Key with an appropriate name
   - Save the API key securely, as you'll need it to make API calls

## Testing Your Deployment

### Using the Example Script

The repository includes an example Python script for testing your deployment:

```bash
# Install required packages
pip install requests

# Run the example script
python example_usage.py \
  --endpoint "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID" \
  --api-key "YOUR_API_KEY" \
  --workflow sample_workflow.json \
  --output-dir "./output"
```

### Manual Testing with cURL

You can also test the API using cURL:

```bash
# Submit a job
curl -X POST "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/run" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @- << EOF
{
  "input": {
    "prompt": $(cat sample_workflow.json),
    "client_id": "test-client"
  }
}
EOF

# Check status
curl -X GET "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/status/JOB_ID" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## Troubleshooting

### Common Issues and Solutions

1. **Image Pull Failures**
   - Check your repository permissions
   - Verify Container Registry Credentials in RunPod
   - Ensure image tag is correct

2. **Container Startup Failures**
   - Check RunPod logs for error messages
   - Verify entrypoint script permissions
   - Check network volume mounting

3. **RunPod API Errors**
   - Verify API key is correct
   - Check endpoint ID is correct
   - Ensure workflow JSON is valid

4. **Missing Custom Nodes**
   - Check Docker build logs
   - Verify symlinks are created correctly
   - Check network volume structure

### Debugging

1. **Check Container Logs**
   - Go to your serverless endpoint in RunPod
   - Click "Logs" to view container logs

2. **SSH into the Worker**
   - If your worker is running, you can SSH into it
   - Go to the worker and click "Connect"
   - Select "Terminal" to access the container shell

3. **Test Locally First**
   - Build and run your Docker image locally before deploying:
     ```bash
     docker build -t comfyui-test .
     docker run -p 8188:8188 comfyui-test
     ```
   - Access ComfyUI at http://localhost:8188

## Next Steps

- Integrate your ComfyUI endpoint with your applications
- Create custom workflows for different use cases
- Monitor usage and optimize costs by adjusting worker settings

For further assistance, check the RunPod documentation or reach out to the community forums.
