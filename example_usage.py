#!/usr/bin/env python3
"""
Example script demonstrating how to call the RunPod ComfyUI API
"""
import json
import requests
import time
import argparse
import base64
from pathlib import Path

# Parse arguments
parser = argparse.ArgumentParser(description='Call RunPod ComfyUI API')
parser.add_argument('--endpoint', required=True, help='RunPod endpoint URL')
parser.add_argument('--api-key', required=True, help='RunPod API key')
parser.add_argument('--workflow', default='sample_workflow.json', help='Path to workflow JSON file')
parser.add_argument('--output-dir', default='./output', help='Directory to save output images')
args = parser.parse_args()

# Create output directory if it doesn't exist
output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

# Load workflow JSON
with open(args.workflow, 'r') as f:
    workflow = json.load(f)

# Prepare request payload
payload = {
    "input": {
        "prompt": workflow,
        "client_id": "example-client"
    }
}

# Set headers with API key
headers = {
    "Authorization": f"Bearer {args.api_key}",
    "Content-Type": "application/json"
}

# Define RunPod API URLs
run_url = f"{args.endpoint}/run"
status_url = f"{args.endpoint}/status"

# Submit job to RunPod
print(f"Submitting job to RunPod: {run_url}")
response = requests.post(run_url, headers=headers, json=payload)
response.raise_for_status()
job_id = response.json()["id"]
print(f"Job submitted successfully. Job ID: {job_id}")

# Poll for job status
print(f"Polling for job status...")
while True:
    status_response = requests.get(f"{status_url}/{job_id}", headers=headers)
    status_data = status_response.json()
    
    if status_data["status"] == "COMPLETED":
        print("Job completed successfully!")
        break
    elif status_data["status"] == "FAILED":
        print(f"Job failed: {status_data.get('error', 'Unknown error')}")
        exit(1)
    else:
        print(f"Job status: {status_data['status']}")
        time.sleep(5)

# Process and save output images
output = status_data.get("output", {})
if "images" in output:
    for i, image_data in enumerate(output["images"]):
        if "base64" in image_data:
            # Decode base64 image
            img_bytes = base64.b64decode(image_data["base64"])
            
            # Save image
            filename = image_data.get("filename", f"image_{i}.png")
            output_path = output_dir / filename
            
            with open(output_path, "wb") as img_file:
                img_file.write(img_bytes)
            
            print(f"Saved image: {output_path}")
            
            # Print S3 URL if available
            if "s3_url" in image_data and image_data["s3_url"]:
                print(f"S3 URL: {image_data['s3_url']}")
else:
    print("No images found in job output")
