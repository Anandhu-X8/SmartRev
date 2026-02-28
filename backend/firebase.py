import os
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin
def init_firebase():
    if not firebase_admin._apps:
        try:
            # User will need to provide their own service account key
            # For now, we rely on application default credentials or a path in .env
            cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
            if cred_path:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            else:
                firebase_admin.initialize_app()
        except Exception as e:
            print(f"Warning: Firebase initialization failed. Database operations will not work. Error: {e}")

def get_db():
    return firestore.client()
