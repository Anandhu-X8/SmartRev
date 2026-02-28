from fastapi import APIRouter, Depends
from typing import Dict, Any, List
from firebase import get_db
from datetime import datetime, timedelta

router = APIRouter()

# Dummy dependency for user integration
def get_current_user_id():
    return "test_user_id" # Replace with actual Firebase Auth verification

@router.get("/dashboard", response_model=Dict[str, Any])
def get_dashboard_stats(ui: str = Depends(get_current_user_id)):
    """Fetch analytics for the user dashboard"""
    db = get_db()
    
    topics_ref = db.collection("topics").where("user_id", "==", ui)
    docs = topics_ref.stream()
    
    total_topics = 0
    strong_topics = 0
    moderate_topics = 0
    weak_topics = 0
    
    topics_list = []
    
    for doc in docs:
        topic = doc.to_dict()
        topics_list.append(topic)
        
        total_topics += 1
        mem = topic.get("memory_strength", 0)
        if mem > 70:
            strong_topics += 1
        elif mem > 40:
            moderate_topics += 1
        else:
            weak_topics += 1
            
    # Calculate streak (simplified: just check if there's revision history from yesterday/today)
    now = datetime.utcnow()
    streak = calculate_user_streak(ui, db, now)
    
    return {
        "total_topics": total_topics,
        "strong_topics": strong_topics,
        "moderate_topics": moderate_topics,
        "weak_topics": weak_topics,
        "revision_streak": streak
    }

def calculate_user_streak(user_id: str, db, current_time: datetime) -> int:
    """Calculate the user's current revision streak in days"""
    # Fetch user's revision history ordered by timestamp descending
    history_docs = db.collection("revision_history")\
        .where("user_id", "==", user_id)\
        .order_by("timestamp", direction="DESCENDING")\
        .stream()
        
    dates_with_activity = set()
    for doc in history_docs:
        ts = doc.to_dict().get("timestamp")
        # Handle timestamp format depending on how firestore returns it (datetime or Timestamp)
        if hasattr(ts, 'timestamp'): 
            # It's a firestore Timestamp
            dt = datetime.fromtimestamp(ts.timestamp())
        else:
            dt = ts
        
        dates_with_activity.add(dt.date())

    if not dates_with_activity:
        return 0
        
    sorted_dates = sorted(list(dates_with_activity), reverse=True)
    
    # Check if the most recent activity is today or yesterday
    today = current_time.date()
    yesterday = today - timedelta(days=1)
    
    if sorted_dates[0] != today and sorted_dates[0] != yesterday:
        return 0
        
    streak = 1
    current_check_date = sorted_dates[0]
    
    for i in range(1, len(sorted_dates)):
        expected_prev_date = current_check_date - timedelta(days=1)
        if sorted_dates[i] == expected_prev_date:
            streak += 1
            current_check_date = expected_prev_date
        else:
            break
            
    return streak
        
