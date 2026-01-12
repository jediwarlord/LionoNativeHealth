from fastapi import FastAPI
from motor.motor_asyncio import AsyncIOMotorClient
import os

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
    return {"message": "Welcome to LionoNativeHealth Backend"}

# --- Garmin Routes ---
from app.models import GarminLoginRequest, GarminLoginResponse, ActivitySyncRequest
from app.garmin import garmin_service

@app.post("/garmin/login", response_model=GarminLoginResponse)
async def garmin_login(request: GarminLoginRequest):
    success = garmin_service.login(request.email, request.password)
    if success:
        return GarminLoginResponse(success=True, message="Login successful", display_name=garmin_service.get_user_profile())
    else:
        return GarminLoginResponse(success=False, message="Invalid credentials")

@app.post("/garmin/sync")
async def garmin_sync(request: ActivitySyncRequest):
    try:
        activities = garmin_service.get_activities(limit=request.limit)
        
        # Save to MongoDB
        if activities:
            collection = app.mongodb["activities"]
            for activity in activities:
                # Use activityId as unique index to prevent duplicates
                await collection.update_one(
                    {"activityId": activity["activityId"]},
                    {"$set": activity},
                    upsert=True
                )
            
        return {
            "status": "success", 
            "synced_count": len(activities),
            "total_in_db": await app.mongodb["activities"].count_documents({})
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/garmin/activities")
async def get_stored_activities():
    activities = []
    cursor = app.mongodb["activities"].find({}).sort("startTimeLocal", -1).limit(50)
    async for document in cursor:
        document["_id"] = str(document["_id"]) # Convert ObjectId to string
        activities.append(document)
    return activities
