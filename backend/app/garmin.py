import subprocess
import os
import aiosqlite
from typing import Optional, Dict, Any, List

GARMIN_DB_PATH = "/root/HealthData/DBs/garmin_activities.db"
DB_CONFIG_PATH = "/root/.GarminDb/GarminConnectConfig.json"

class GarminManager:
    def __init__(self):
        pass

    def check_auth(self) -> bool:
        """
        Checks if GarminDB is configured/authenticated.
        This is a heuristic check (existence of config/DB).
        """
        return os.path.exists(DB_CONFIG_PATH)

    def login(self, email: str, password: str) -> bool:
        """
        For GarminDB, programmatic login via this API is difficult because it often requires
        interactive flows or 2FA. 
        
        We will attempt to run the setup command, but in a headless environment this might fail
        if interaction is needed.
        """
        # TODO: Implement a way to pass credentials if GarminDB supports non-interactive setup
        # For now, we rely on the user having set up the volume or running the auth command manually.
        pass
        return self.check_auth()

    async def sync_data(self) -> Dict[str, Any]:
        """
        Runs the GarminDB sync command.
        """
        try:
            # Run GarminDB update command
            # This assumes 'GarminDB' is in the path after installation
            process = subprocess.run(
                ["garmindb_cli.py", "--monitoring", "--rhr", "--activities", "--download", "--import", "--analyze"],
                capture_output=True,
                text=True,
                check=True
            )
            return {"status": "success", "stdout": process.stdout}
        except subprocess.CalledProcessError as e:
            return {"status": "error", "message": str(e), "stderr": e.stderr}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def get_activities(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Reads activities directly from the generated SQLite database.
        """
        if not os.path.exists(GARMIN_DB_PATH):
            return []

        activities = []
        try:
            async with aiosqlite.connect(GARMIN_DB_PATH) as db:
                db.row_factory = aiosqlite.Row
                # Adjust table/column names based on GarminDB schema
                # Assuming 'activities' table exists with standard columns
                # We might need to inspect the schema first.
                async with db.execute(f"SELECT * FROM activities ORDER BY start_time DESC LIMIT {limit}") as cursor:
                    async for row in cursor:
                        activities.append(dict(row))
        except Exception as e:
            print(f"Error reading GarminDB: {e}")
            return []

        return activities
            
    async def get_activity_details(self, activity_id: str) -> Dict[str, Any]:
        """
        Fetches detailed records (like heart rate) for a specific activity.
        """
        if not os.path.exists(GARMIN_DB_PATH):
            return {}

        details = {"activity_id": activity_id, "records": []}
        try:
            async with aiosqlite.connect(GARMIN_DB_PATH) as db:
                db.row_factory = aiosqlite.Row
                # Fetch records sorted by timestamp
                query = "SELECT timestamp, hr FROM activity_records WHERE activity_id = ? ORDER BY timestamp"
                async with db.execute(query, (activity_id,)) as cursor:
                    async for row in cursor:
                        # Only include records with hear rate data
                        if row['hr'] is not None and row['hr'] > 0:
                            details["records"].append({
                                "timestamp": row['timestamp'],
                                "hr": row['hr']
                            })
        except Exception as e:
            print(f"Error fetching details for {activity_id}: {e}")
            return {}

        return details

garmin_service = GarminManager()
