from fastapi import APIRouter, HTTPException, Depends
from firebase import get_db
from auth import get_current_user_id
from firebase_admin import messaging
from datetime import datetime

router = APIRouter()


@router.post("/send-reminder")
def send_revision_reminder(ui: str = Depends(get_current_user_id)):
    """Send a push notification reminder to the current user."""
    db = get_db()

    # Get user's FCM token
    token_doc = db.collection("fcm_tokens").document(ui).get()
    if not token_doc.exists:
        raise HTTPException(status_code=404, detail="No FCM token found for user")

    token_data = token_doc.to_dict()
    fcm_token = token_data.get("token")
    if not fcm_token:
        raise HTTPException(status_code=404, detail="FCM token is empty")

    # Count topics due for revision
    now = datetime.utcnow()
    topics_due = list(
        db.collection("topics")
        .where("user_id", "==", ui)
        .where("next_revision_date", "<=", now)
        .stream()
    )
    count = len(topics_due)

    if count == 0:
        return {"message": "No topics due for revision", "sent": False}

    # Build notification
    title = "Time to Revise!"
    body = (
        f"You have {count} topic{'s' if count > 1 else ''} waiting for revision. "
        f"Keep your memory strong!"
    )

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            "type": "revision_reminder",
            "topics_due": str(count),
        },
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        return {"message": "Notification sent", "sent": True, "fcm_response": response}
    except messaging.UnregisteredError:
        raise HTTPException(status_code=410, detail="FCM token is no longer valid")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send notification: {str(e)}")


@router.post("/send-topic-reminder/{topic_id}")
def send_topic_reminder(topic_id: str, ui: str = Depends(get_current_user_id)):
    """Send a push notification for a specific topic revision."""
    db = get_db()

    # Get user's FCM token
    token_doc = db.collection("fcm_tokens").document(ui).get()
    if not token_doc.exists:
        raise HTTPException(status_code=404, detail="No FCM token found for user")

    fcm_token = token_doc.to_dict().get("token")
    if not fcm_token:
        raise HTTPException(status_code=404, detail="FCM token is empty")

    # Get topic
    topic_doc = db.collection("topics").document(topic_id).get()
    if not topic_doc.exists:
        raise HTTPException(status_code=404, detail="Topic not found")

    topic = topic_doc.to_dict()
    if topic.get("user_id") != ui:
        raise HTTPException(status_code=403, detail="Not authorized")

    # Determine memory label
    strength = topic.get("memory_strength", 0)
    if strength <= 40:
        label = "Weak"
    elif strength <= 70:
        label = "Moderate"
    else:
        label = "Strong"

    message = messaging.Message(
        notification=messaging.Notification(
            title=f"Revise: {topic.get('name', 'Topic')}",
            body=f"Memory strength: {label} ({int(strength)}%). Tap to start revising!",
        ),
        data={
            "type": "topic_reminder",
            "topic_id": topic_id,
        },
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        return {"message": "Notification sent", "sent": True, "fcm_response": response}
    except messaging.UnregisteredError:
        raise HTTPException(status_code=410, detail="FCM token is no longer valid")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send notification: {str(e)}")
