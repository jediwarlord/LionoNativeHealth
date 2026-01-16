
import json
import os
import shutil
import getpass

EXAMPLE_CONFIG_PATH = "/usr/local/lib/python3.11/site-packages/garmindb/GarminConnectConfig.json.example"
CONFIG_DIR = "/root/.GarminDb"
CONFIG_PATH = os.path.join(CONFIG_DIR, "GarminConnectConfig.json")

def configure():
    if not os.path.exists(CONFIG_DIR):
        print(f"Creating directory {CONFIG_DIR}")
        os.makedirs(CONFIG_DIR)

    if not os.path.exists(EXAMPLE_CONFIG_PATH):
        print(f"Error: Example config not found at {EXAMPLE_CONFIG_PATH}")
        return

    print("Please enter your Garmin Connect credentials.")
    email = input("Email: ").strip()
    password = getpass.getpass("Password: ").strip()

    try:
        with open(EXAMPLE_CONFIG_PATH, 'r') as f:
            config = json.load(f)
        
        if "data" in config:
            config["data"]["weight_start_date"] = "2026-01-01"
            config["data"]["sleep_start_date"] = "2026-01-01"
            config["data"]["rhr_start_date"] = "2026-01-01"
            config["data"]["monitoring_start_date"] = "2026-01-01"
        
        # Update credentials
        if "credentials" in config:
            config["credentials"]["user"] = email
            config["credentials"]["password"] = password
        else:
            # Fallback if structure is flat or different, checking keys
            config["user"] = email
            config["password"] = password
            
        print(f"Writing config to {CONFIG_PATH}...")
        with open(CONFIG_PATH, 'w') as f:
            json.dump(config, f, indent=4)
            
        print("Configuration saved successfully.")
        
    except Exception as e:
        print(f"Failed to configure: {e}")

if __name__ == "__main__":
    configure()
