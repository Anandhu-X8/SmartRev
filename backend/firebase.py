import os
import firebase_admin
from firebase_admin import credentials, firestore

# Project root is one level up from backend/
_PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..')

# Initialize Firebase Admin
def init_firebase():
    if not firebase_admin._apps:
        try:
            cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
            if cred_path:
                # Resolve relative paths from project root
                if not os.path.isabs(cred_path):
                    cred_path = os.path.join(_PROJECT_ROOT, cred_path)
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            else:
                firebase_admin.initialize_app()
        except Exception as e:
            print(f"Warning: Firebase initialization failed. Database operations will not work. Error: {e}")

def get_db():
    return firestore.client()
