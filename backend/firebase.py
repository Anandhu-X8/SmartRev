import os
import json
import firebase_admin
from firebase_admin import credentials, firestore

# Project root is one level up from backend/
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

# Initialize Firebase Admin
def init_firebase():
    if not firebase_admin._apps:
        try:
            # Option 1: JSON string in env var (for Vercel / cloud deployments)
            service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
            # Option 2: File path in env var (for local development)
            cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

            if service_account_json:
                service_info = json.loads(service_account_json)
                cred = credentials.Certificate(service_info)
                project_id = service_info.get("project_id")
                firebase_admin.initialize_app(cred, options={"projectId": project_id})
            elif cred_path:
                # Resolve relative paths from project root and normalize to absolute path
                if not os.path.isabs(cred_path):
                    cred_path = os.path.abspath(os.path.join(_PROJECT_ROOT, cred_path))
                else:
                    cred_path = os.path.abspath(cred_path)
                cred = credentials.Certificate(cred_path)
                # Read the file to extract project_id
                with open(cred_path, 'r') as f:
                    service_info = json.load(f)
                project_id = service_info.get("project_id")
                firebase_admin.initialize_app(cred, options={"projectId": project_id})
            else:
                raise Exception(
                    "Firebase credentials not found. "
                    "Please set FIREBASE_SERVICE_ACCOUNT_JSON "
                    "or GOOGLE_APPLICATION_CREDENTIALS."
                )
        except Exception as e:
            import traceback
            print(f"Warning: Firebase initialization failed. Database operations will not work. Error: {e}")
            traceback.print_exc()

def get_db():
    return firestore.client()
