from pydantic import BaseModel
from typing import Optional, List, Any

class GarminLoginRequest(BaseModel):
    email: str
    password: str

class GarminLoginResponse(BaseModel):
    success: bool
    message: str
    display_name: Optional[str] = None

class ActivitySyncRequest(BaseModel):
    limit: int = 10
