from fastapi import APIRouter, HTTPException, Depends
from typing import List
from models import TopicCreate, TopicDB
from firebase import get_db
import uuid
from datetime import datetime, timedelta
import google.generativeai as genai
import os
import json

router = APIRouter()

# Dummy dependency for user integration
def get_current_user_id():
    return "test_user_id" # Replace with actual Firebase Auth verification

@router.post("/", response_model=TopicDB)
def create_topic(topic: TopicCreate, ui: str = Depends(get_current_user_id)):
    db = get_db()
    topic_id = str(uuid.uuid4())
    now = datetime.utcnow()
    
    # Initial next_revision date is tomorrow
    next_rev = now + timedelta(days=1)
    
    new_topic = TopicDB(
        id=topic_id,
        user_id=ui,
        creation_date=now,
        last_revision_date=now,
        next_revision_date=next_rev,
        memory_strength=50.0, # initial baseline
        revision_count=0,
        **topic.dict()
    )
    
    doc_ref = db.collection("topics").document(topic_id)
    # Pydantic dict to json-compatible dict
    doc_ref.set(new_topic.dict()) # Use dict instead of json() string

    # --- Generate Quiz via Gemini immediately ---
    api_key = os.getenv("GEMINI_API_KEY", "DUMMY_KEY_FOR_NOW")
    genai.configure(api_key=api_key)
    
    prompt = (
        f"Create exactly 5 multiple choice questions (MCQs) for the topic '{topic.name}' "
        f"in the subject '{topic.subject_category}'. "
        f"Difficulty level: {topic.difficulty_level}. "
    )
    if topic.notes:
        prompt += f"Here are notes to base it on: '{topic.notes}'. "
        
    prompt += (
        "Return ONLY valid JSON format. It must be a dict with a 'questions' key containing a list of 5 objects. "
        "Each object must have 'question' (string), 'options' (list of 4 strings), 'correct_answer_index' (integer 0-3), "
        "and 'explanation' (string). Do not add any markdown formatting like ```json"
    )

    generated_questions = []
    try:
        model = genai.GenerativeModel("gemini-1.5-pro")
        response = model.generate_content(prompt)
        raw_text = response.text.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3].strip()
        elif raw_text.startswith("```"):
            raw_text = raw_text[3:-3].strip()
            
        quiz_data = json.loads(raw_text)
        
        for q in quiz_data.get("questions", []):
            generated_questions.append({
                "id": str(uuid.uuid4()),
                "question": q["question"],
                "options": q["options"],
                "correct_answer_index": q["correct_answer_index"],
                "explanation": q.get("explanation", "")
            })
    except Exception as e:
        print(f"Failed to generate quiz automatically: {e}")
        # Could provide fallback dummy questions here, but leaving empty for now if fails
        pass

    quiz_id = str(uuid.uuid4())
    quiz_db_data = {
        "quiz_id": quiz_id,
        "topic_id": topic_id,
        "questions": generated_questions
    }
    db.collection("quizzes").document(quiz_id).set(quiz_db_data)

    return new_topic

@router.get("/", response_model=List[TopicDB])
def get_topics(ui: str = Depends(get_current_user_id)):
    db = get_db()
    topics_ref = db.collection("topics").where("user_id", "==", ui)
    docs = topics_ref.stream()
    return [doc.to_dict() for doc in docs]
