from garminconnect import Garmin
from garminconnect import GarminConnectAuthenticationError
from typing import Optional, Dict, Any

class GarminManager:
    def __init__(self):
        self.client: Optional[Garmin] = None

    def login(self, email: str, password: str) -> bool:
        try:
            self.client = Garmin(email, password)
            self.client.login()
            return True
        except (GarminConnectAuthenticationError, Exception) as e:
            print(f"Login failed: {e}")
            return False

    def get_activities(self, limit: int = 10) -> list[Dict[str, Any]]:
        if not self.client:
            raise Exception("Client not authenticated")
        
        # 0 is start, limit is count
        activities = self.client.get_activities(0, limit)
        return activities

    def get_user_profile(self):
        if not self.client:
            return None
        return self.client.get_full_name()
        
garmin_service = GarminManager()
