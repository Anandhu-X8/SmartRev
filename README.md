# AI/ML Based Smart Revision System

An intelligent Flutter-based mobile application backed by Python FastAPI that utilizes spaced repetition and generative AI (Gemini) to optimize your learning and long-term knowledge retention.

## Features Built
- **Authentication**: Flutter UI ready (Firebase placeholder).
- **Dashboard**: Track your topics, strengths, and daily streaks.
- **Spaced Repetition Engine**: Adaptive memory strength tracking algorithm implemented in Python backend.
- **AI Quiz Generation**: Generates automated revision MCQs using Google Gemini API based on topic details.
- **Analytics Visualization**: Integrated `fl_chart` for monitoring progress.
- **Modern UI**: Polished "Royal Blue" academic theme with smooth, clean designs.

## Tech Stack
- Frontend: Flutter (Dart)
- Backend: Python FastAPI
- Database: Firebase Firestore
- AI Integration: Google Gemini API

## Setup Instructions

### 1. Prerequisites
- Flutter SDK installed
- Python 3.9+ installed
- Firebase Project configured (with Firestore and Authentication)
- Google Gemini API Key

### 2. Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Export your Gemini key and Firebase credentials path
export GEMINI_API_KEY="your-gemini-key"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/firebase-adminsdk.json"

uvicorn main:app --reload
```

### 3. Frontend Setup
```bash
cd frontend
flutter pub get

# To run the app (ensure emulator is running or device connected)
flutter run
```

## Deployment Notes
- **Backend Deployment**: Recommended to deploy FastAPI on Google Cloud Run, Heroku, or Render.
- **Database**: Ensure Firestore Security Rules are updated for production.
- **Flutter Build**: Follow the standard `flutter build apk` or `flutter build appbundle` for Android deployment.
