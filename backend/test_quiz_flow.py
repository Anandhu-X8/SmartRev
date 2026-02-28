import requests
import json
import time

BASE_URL = "http://127.0.0.1:8000/api"

def test_quiz_flow():
    print("Testing Quiz Flow...")
    
    # 1. Create a Topic (Trigger immediate quiz generation)
    print("\n1. Creating Topic...")
    topic_data = {
        "name": "Testing Spaced Repetition",
        "subject_category": "Computer Science",
        "difficulty_level": "Medium",
        "confidence_level": 3,
        "notes": "Need to understand how intervals grow based on accuracy."
    }
    create_resp = requests.post(f"{BASE_URL}/topics/", json=topic_data)
    
    if create_resp.status_code != 200:
        print(f"Failed to create topic: {create_resp.text}")
        return
        
    topic = create_resp.json()
    topic_id = topic['id']
    print(f"Topic created successfully. ID: {topic_id}")
    
    print("Waiting 5 seconds for Gemini to generate the quiz...")
    time.sleep(5)
    
    # 2. Fetch the generated Quiz
    print("\n2. Fetching Generated Quiz...")
    quiz_resp = requests.get(f"{BASE_URL}/revision/quiz/{topic_id}")
    
    if quiz_resp.status_code != 200:
        print(f"Failed to fetch quiz: {quiz_resp.text}")
        return
        
    quiz = quiz_resp.json()
    questions = quiz.get("questions", [])
    print(f"Successfully fetched {len(questions)} questions!")
    
    if len(questions) != 5:
        print(f"WARNING: Expected 5 questions, got {len(questions)}")
        
    # Simulate answering (let's say we get 4 correct)
    print("\n3. Simulating 4 Correct Answers...")
    user_answers = []
    for i in range(len(questions)):
        if i < 4:
            # Correct answer
            user_answers.append(questions[i]['correct_answer_index'])
        else:
            # Wrong answer (just pick another index)
            correct_idx = questions[i]['correct_answer_index']
            user_answers.append((correct_idx + 1) % 4)
            
    # 4. Submit answers for evaluation
    eval_payload = {
        "topic_id": topic_id,
        "user_answers": user_answers,
        "response_time_seconds": 45
    }
    
    eval_resp = requests.post(f"{BASE_URL}/revision/complete", json=eval_payload)
    if eval_resp.status_code != 200:
        print(f"Evaluation Failed: {eval_resp.text}")
        return
        
    eval_result = eval_resp.json()
    print("\nEvaluation Results:")
    print(f"Total Questions: {eval_result.get('total_questions')}")
    print(f"Correct Answers: {eval_result.get('correct_answers')}")
    print(f"Accuracy: {eval_result.get('accuracy') * 100}%")
    print(f"New Memory Strength: {eval_result.get('memory_strength')}")
    print(f"Next Revision Date: {eval_result.get('next_revision_date')}")

if __name__ == "__main__":
    try:
        requests.get(BASE_URL)
        test_quiz_flow()
    except requests.exceptions.ConnectionError:
        print("Backend is not running. Start the backend with 'uvicorn main:app --reload'")
