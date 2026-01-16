from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
import os
from typing import List

app = FastAPI(title="LionoNativeHealth API")

# Environment variables
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "lionhealth_db")

@app.on_event("startup")
async def startup_db_client():
    app.mongodb_client = AsyncIOMotorClient(MONGODB_URL)
    app.mongodb = app.mongodb_client[DB_NAME]
    print(f"Connected to MongoDB at {MONGODB_URL}")

@app.on_event("shutdown")
async def shutdown_db_client():
    app.mongodb_client.close()

@app.get("/health")
async def check_health():
    return {"status": "ok", "database": "connected"}

@app.get("/")
async def root():
    return {"message": "Welcome to LionoNativeHealth Backend (GarminDB Edition)"}

# --- Garmin Routes ---
from app.models import GarminLoginRequest, GarminLoginResponse, ActivitySyncRequest
from app.garmin import garmin_service

@app.post("/garmin/auth/status")
async def garmin_auth_status():
    """Checks if GarminDB is configured."""
    is_configured = garmin_service.check_auth()
    return {"configured": is_configured, "message": "GarminDB configured" if is_configured else "GarminDB not configured. Please run setup manually."}

@app.post("/garmin/sync")
async def garmin_sync(request: ActivitySyncRequest):
    """Triggers GarminDB sync."""
    result = await garmin_service.sync_data()
    return result

@app.get("/garmin/activities")
async def get_stored_activities(limit: int = 50):
    """
    Retrieves activities directly from the GarminDB SQLite file.
    """
    activities = await garmin_service.get_activities(limit=limit)
    return activities

@app.get("/garmin/activities/{activity_id}")
async def get_activity_details(activity_id: str):
    """
    Retrieves detailed records (HR series) for an activity.
    """
    details = await garmin_service.get_activity_details(activity_id)
    if not details or not details.get("records"):
        raise HTTPException(status_code=404, detail="Activity details not found or no HR data")
    return details
