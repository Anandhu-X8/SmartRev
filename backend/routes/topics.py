from fastapi import APIRouter, HTTPException, Depends
from typing import List
from models import TopicCreate, TopicDB, FlashcardItem
from firebase import get_db
from auth import get_current_user_id
import uuid
from datetime import datetime, timedelta
from mistralai.client import Mistral
import os
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/", response_model=TopicDB)
def create_topic(topic: TopicCreate, ui: str = Depends(get_current_user_id)):
    db = get_db()
    topic_id = str(uuid.uuid4())
    now = datetime.utcnow()
    
    # Initial next_revision date is today (so it appears in today's queue immediately)
    next_rev = now
    
    new_topic = TopicDB(
        id=topic_id,
        user_id=ui,
        creation_date=now,
        last_revision_date=now,
        next_revision_date=next_rev,
        memory_strength=50.0, # initial baseline
        revision_count=0,
        flashcards=topic.flashcards,
        **topic.dict(exclude={'flashcards'})
    )
    
    doc_ref = db.collection("topics").document(topic_id)
    # Pydantic dict to json-compatible dict
    doc_ref.set(new_topic.dict()) # Use dict instead of json() string

    # --- Generate Quiz via Mistral immediately ---
    api_key = os.getenv("MISTRAL_API_KEY")
    if not api_key:
        logger.error("MISTRAL_API_KEY not found in environment variables")
    
    generated_questions = []
    try:
        client = Mistral(api_key=api_key)
        
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

        response = client.chat.complete(model="mistral-small-latest", messages=[{"role": "user", "content": prompt}])
        raw_text = response.choices[0].message.content.strip()
        
        # Clean up potential markdown formatting
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
        logger.error(f"Failed to generate quiz automatically: {e}")
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
