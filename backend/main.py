import os
from dotenv import load_dotenv

# Load environment variables as the very first step
env_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '.env'))
load_dotenv(dotenv_path=env_path, override=True)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import topics, revision, analytics, notes, notifications
from firebase import init_firebase

init_firebase()

app = FastAPI(title="Smart Revision System API")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Smart Revision System API"}

app.include_router(topics.router, prefix="/api/topics", tags=["topics"])
app.include_router(revision.router, prefix="/api/revision", tags=["revision"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["analytics"])
app.include_router(notes.router, prefix="/api/notes", tags=["notes"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
