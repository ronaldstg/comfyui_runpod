'''
RunPod handler for ComfyUI serverless deployment
'''
import os
import time
import json
import requests
import runpod
import base64
from io import BytesIO

# ComfyUI API endpoints
COMFY_HOST = "127.0.0.1:8188"
COMFY_QUEUE_PROMPT_URL = f"http://{COMFY_HOST}/prompt"
COMFY_QUEUE_STATUS_URL = f"http://{COMFY_HOST}/queue"
COMFY_HISTORY_URL = f"http://{COMFY_HOST}/history"

# Configure S3 if available
s3_endpoint = os.environ.get("BUCKET_ENDPOINT_URL")
s3_access_key = os.environ.get("BUCKET_ACCESS_KEY_ID")
s3_secret_key = os.environ.get("BUCKET_SECRET_ACCESS_KEY")

def upload_to_s3(image_data, filename, bucket_name="comfyui-outputs"):
    """Upload an image to S3 bucket"""
    if not all([s3_endpoint, s3_access_key, s3_secret_key]):
        print("S3 credentials not configured, skipping upload")
        return None
    
    try:
        import boto3
        from botocore.client import Config
        
        s3_client = boto3.client(
            's3',
            endpoint_url=s3_endpoint,
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            config=Config(signature_version='s3v4')
        )
        
        file_obj = BytesIO(image_data)
        s3_client.upload_fileobj(
            file_obj, 
            bucket_name, 
            filename,
            ExtraArgs={'ContentType': 'image/png'}
        )
        
        url = f"{s3_endpoint}/{bucket_name}/{filename}"
        return url
    except Exception as e:
        print(f"Error uploading to S3: {e}")
        return None

def poll_status(prompt_id, timeout=300):
    """Poll the ComfyUI queue status until the job is done or timeout"""
    start_time = time.time()
    
    while time.time() - start_time < timeout:
        try:
            response = requests.get(COMFY_QUEUE_STATUS_URL)
            if response.status_code == 200:
                queue_data = response.json()
                
                # If queue is empty and prompt not executing, check history
                if not queue_data["queue_running"] and len(queue_data["queue_pending"]) == 0:
                    history_response = requests.get(f"{COMFY_HISTORY_URL}/{prompt_id}")
                    if history_response.status_code == 200:
                        return history_response.json()
            
            # Wait before polling again
            time.sleep(1)
        except Exception as e:
            print(f"Error polling status: {e}")
            time.sleep(1)
    
    return {"error": "Timeout waiting for ComfyUI to process the prompt"}

def parse_output(history_data):
    """Parse the ComfyUI history data to get output images"""
    if not history_data or "outputs" not in history_data:
        return {"error": "No outputs found in history data"}
    
    result = {"images": []}
    
    for node_id, output_data in history_data["outputs"].items():
        if "images" in output_data:
            for image in output_data["images"]:
                image_path = f"http://{COMFY_HOST}/view?filename={image['filename']}"
                
                try:
                    # Download the image
                    image_response = requests.get(image_path)
                    if image_response.status_code == 200:
                        image_data = image_response.content
                        
                        # Base64 encode for response
                        base64_image = base64.b64encode(image_data).decode('utf-8')
                        
                        # Upload to S3 if configured
                        s3_url = None
                        if all([s3_endpoint, s3_access_key, s3_secret_key]):
                            s3_url = upload_to_s3(image_data, image['filename'])
                        
                        result["images"].append({
                            "filename": image['filename'],
                            "subfolder": image.get('subfolder', ''),
                            "type": image.get('type', 'output'),
                            "base64": base64_image,
                            "s3_url": s3_url
                        })
                except Exception as e:
                    print(f"Error processing image {image['filename']}: {e}")
    
    return result

def handler(event):
    """
    RunPod handler function for ComfyUI
    
    Event structure:
    {
        "prompt": {...},  # ComfyUI workflow
        "client_id": "optional client id"
    }
    """
    try:
        if not event or "input" not in event:
            return {"error": "No input provided"}
        
        input_data = event["input"]
        
        # Check if workflow is provided
        if "prompt" not in input_data:
            return {"error": "No ComfyUI workflow provided in input"}
        
        prompt = input_data["prompt"]
        client_id = input_data.get("client_id", "runpod-handler")
        
        # Submit prompt to ComfyUI
        data = {
            "prompt": prompt,
            "client_id": client_id
        }
        
        response = requests.post(COMFY_QUEUE_PROMPT_URL, json=data)
        
        if response.status_code != 200:
            return {"error": f"Failed to submit prompt: {response.text}"}
        
        prompt_id = response.json()["prompt_id"]
        
        response_data = {
            "prompt_id": prompt_id,
            "client_id": client_id
        }
        
        return response_data
    
    except Exception as e:
        return {"error": f"Error in handler: {str(e)}"}

# Start the RunPod handler
runpod.serverless.start({"handler": handler})
