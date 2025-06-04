import os
import requests
import json
from concurrent.futures import ThreadPoolExecutor
import uuid
import sys

def get_access_token():
    auth_url = "https://api-qa.express-scripts.io/v1/auth/oauth2/token"
    params = {
        "grant_type": "client_credentials",
        "client_id": os.getenv("CLIENT_ID"),
        "client_secret": os.getenv("CLIENT_SECRET")
    }
    
    try:
        response = requests.post(auth_url, params=params)
        response.raise_for_status()
        token_data = response.json()
        return token_data["access_token"]
    except requests.RequestException as e:
        print(f"Error fetching access token: {e}")
        return None

def make_post_request(access_token, request_id):
    url = "https://api-qa.express-scripts.io/benefitsinsight/v1/bridge/account-structure/entity/count"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    payload = {
        "requestId": request_id,
        "asOfDate": "2025-05-06",
        "carrierList": ["KU5", "SMT"],
        "exclusionTypeCodeList": ["WG", "GR"],
        "entityList": [],
        "isActiveEntity": 1
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        return {"requestId": request_id, "status": "success", "response": response.json()}
    except requests.RequestException as e:
        return {"requestId": request_id, "status": "error", "error": str(e)}

def run_parallel_requests(num_requests=100):
    access_token = get_access_token()
    if not access_token:
        print("Failed to obtain access token. Exiting.")
        return
    
    request_ids = [str(uuid.uuid4()) for _ in range(num_requests)]
    
    results = []
    with ThreadPoolExecutor() as executor:
        future_to_request = {executor.submit(make_post_request, access_token, req_id): req_id for req_id in request_ids}
        for future in future_to_request:
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                results.append({"requestId": future_to_request[future], "status": "error", "error": str(e)})
    
    success_count = sum(1 for r in results if r["status"] == "success")
    error_count = len(results) - success_count
    print(f"Completed {len(results)} requests: {success_count} successful, {error_count} failed")
    
    for result in results:
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    # Ensure environment variables are set
    if not os.getenv("CLIENT_ID") or not os.getenv("CLIENT_SECRET"):
        print("Please set CLIENT_ID and CLIENT_SECRET environment variables.")
    else:
        # Get number of parallel requests from command-line argument (default 100)
        try:
            num_requests = int(sys.argv[1]) if len(sys.argv) > 1 else 100
            if num_requests <= 0:
                raise ValueError("Number of requests must be positive.")
            run_parallel_requests(num_requests)
        except ValueError as e:
            print(f"Invalid input: {e}. Using default of 100 requests.")
            run_parallel_requests()
