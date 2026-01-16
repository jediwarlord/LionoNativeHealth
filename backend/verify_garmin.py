
import requests
import json
import sys

BASE_URL = "http://localhost:8000"

def test_health():
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Health Check: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health Check Failed: {e}")
        return False

def test_auth_status():
    print("\nTesting Auth Status...")
    try:
        response = requests.post(f"{BASE_URL}/garmin/auth/status")
        print(f"Auth Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Auth Status Request Failed: {e}")

def test_sync_dry_run():
    print("\nTesting Sync (expecting failure or empty if not auth'd)...")
    payload = {"limit": 5}
    try:
        response = requests.post(f"{BASE_URL}/garmin/sync", json=payload)
        print(f"Sync Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Sync Request Failed: {e}")

def main():
    if test_health():
        test_auth_status()
        test_sync_dry_run()
    else:
        print("Backend not healthy, skipping other tests.")

if __name__ == "__main__":
    main()
