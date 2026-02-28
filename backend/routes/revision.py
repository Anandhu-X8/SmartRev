from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Any
from models import TopicDB, RevisionActivityParams, RevisionResult
from firebase import get_db
import google.generativeai as genai
import os
import json
from datetime import datetime
from services.spaced_repetition import calculate_next_revision
import uuid

router = APIRouter()

# Dummy dependency for user integration
def get_current_user_id():
    return "test_user_id" # Replace with actual Firebase Auth verification

# Configure Gemini
api_key = os.getenv("GEMINI_API_KEY", "DUMMY_KEY_FOR_NOW")
genai.configure(api_key=api_key)

@router.get("/quiz/{topic_id}")
def get_quiz_for_topic(topic_id: str, ui: str = Depends(get_current_user_id)):
    """Fetch the pre-generated quiz for a topic"""
    db = get_db()
    quizzes_ref = db.collection("quizzes").where("topic_id", "==", topic_id).limit(1)
    docs = list(quizzes_ref.stream())
    
    if not docs:
        raise HTTPException(status_code=404, detail="Quiz not found for this topic")
        
    return docs[0].to_dict()

@router.get("/queue", response_model=List[TopicDB])
def get_revision_queue(ui: str = Depends(get_current_user_id)):
    """Fetch user's daily revision queue"""
    db = get_db()
    now = datetime.utcnow()
    
    # Query: Next revision date <= today
    topics_ref = db.collection("topics").where("user_id", "==", ui).where("next_revision_date", "<=", now)
    docs = topics_ref.stream()
    
    queue = [doc.to_dict() for doc in docs]
    
    # Sort queue by priority: lowest memory strength first
    queue.sort(key=lambda t: t.get("memory_strength", 100))
    return queue

@router.post("/activity")
def generate_revision_activity(params: RevisionActivityParams, ui: str = Depends(get_current_user_id)):
    """Generate dynamic revision activity via Gemini API"""
    db = get_db()
    topic_doc = db.collection("topics").document(params.topic_id).get()
    if not topic_doc.exists:
        raise HTTPException(status_code=404, detail="Topic not found")
        
    topic = topic_doc.to_dict()
    topic_name = topic.get("name")
    subject = topic.get("subject_category")
    notes = topic.get("notes", "")
    
    # Generate prompt based on activity type
    prompt = f"Create a short revision activity of type '{params.activity_type}' for the topic '{topic_name}' in the subject '{subject}'. "
    if notes:
        prompt += f"Here are my notes to base it on: '{notes}'. "
        
    prompt += "Return ONLY valid JSON format with questions and answers. For MCQs, provide 'question', 'options' (list of 4), and 'correct_answer_index' (0-3). For Flashcards, provide 'front' and 'back'."
    
    try:
        model = genai.GenerativeModel("gemini-1.5-pro")
        response = model.generate_content(prompt)
        # Parse the JSON string
        raw_text = response.text.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3]
        
        activity_data = json.loads(raw_text)
        return {"activity": activity_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate revision activity: {str(e)}")


@router.post("/complete")
def complete_activity(result: RevisionResult, ui: str = Depends(get_current_user_id)):
    """Update topic based on true performance (user_answers)"""
    db = get_db()
    doc_ref = db.collection("topics").document(result.topic_id)
    topic_doc = doc_ref.get()
    
    if not topic_doc.exists:
        raise HTTPException(status_code=404, detail="Topic not found")
        
    topic = topic_doc.to_dict()
    current_memory = topic.get("memory_strength", 0.0)
    current_revision_count = topic.get("revision_count", 0)
    
    # 1. Fetch Quiz and evaluate answers
    quizzes_ref = db.collection("quizzes").where("topic_id", "==", result.topic_id).limit(1)
    quiz_docs = list(quizzes_ref.stream())
    
    if not quiz_docs:
        raise HTTPException(status_code=404, detail="Quiz not found for evaluation")
        
    quiz_data = quiz_docs[0].to_dict()
    questions = quiz_data.get("questions", [])
    
    correct_count = 0
    total_questions = len(questions)
    
    for i, ans_idx in enumerate(result.user_answers):
        if i < total_questions:
            if questions[i]["correct_answer_index"] == ans_idx:
                correct_count += 1
                
    accuracy = correct_count / total_questions if total_questions > 0 else 0.0
    
    # Calculate new data
    new_strength, interval_days = calculate_next_revision(current_memory, accuracy, current_revision_count)
    
    now = datetime.utcnow()
    next_rev = now + timedelta(days=interval_days)
    
    update_data = {
        "memory_strength": new_strength,
        "revision_count": current_revision_count + 1,
        "last_revision_date": now,
        "next_revision_date": next_rev
    }
    
    doc_ref.update(update_data)
    
    # Log history
    history_id = str(uuid.uuid4())
    db.collection("revision_history").document(history_id).set({
        "topic_id": result.topic_id,
        "user_id": ui,
        "accuracy": accuracy,
        "correct_answers": correct_count,
        "total_questions": total_questions,
        "timestamp": now,
        "response_time_seconds": result.response_time_seconds
    })
    
    return {
        **update_data,
        "correct_answers": correct_count,
        "total_questions": total_questions,
        "accuracy": accuracy
    }
