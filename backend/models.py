from pydantic import BaseModel, Field
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

class TopicBase(BaseModel):
    name: str
    subject_category: str
    difficulty_level: str  # Easy, Medium, Hard
    confidence_level: int = Field(ge=1, le=5)
    notes: Optional[str] = None
    is_ai_generated: bool = False # Identify if generated from notes

class TopicCreate(TopicBase):
    flashcards: Optional[List[FlashcardItem]] = None

class FlashcardItem(BaseModel):
    question: str
    answer: str

class TopicDB(TopicBase):
    id: str
    user_id: str
    creation_date: datetime
    last_revision_date: datetime
    next_revision_date: datetime
    memory_strength: float = 0.0 # 0-100
    revision_count: int = 0
    flashcards: Optional[List[FlashcardItem]] = None

class QuestionDB(BaseModel):
    id: str
    question: str
    options: List[str]
    correct_answer_index: int
    explanation: Optional[str] = None

class QuizDB(BaseModel):
    quiz_id: str
    topic_id: str
    questions: List[QuestionDB]
    generated_by_ai: bool = False
    created_at: datetime

class UploadedNotesDB(BaseModel):
    id: str
    user_id: str
    topic_id: Optional[str] = None
    file_path: str
    uploaded_at: datetime

class RevisionActivityParams(BaseModel):
    topic_id: str
    activity_type: str # mcq, flashcard, short_recall, fill_in_the_blanks

class RevisionResult(BaseModel):
    topic_id: str
    # accuracy: float # Removing accuracy from frontend input to calculate it properly on backend
    user_answers: List[int] # index of selected option for each question
    response_time_seconds: Optional[int] = None

class FlashcardRevisionResult(BaseModel):
    topic_id: str
    memory_strength: int = Field(ge=0, le=100)  # User-rated confidence converted to 0-100
