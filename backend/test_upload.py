from fastapi.testclient import TestClient
from main import app
import traceback

client = TestClient(app)
try:
    response = client.post('/api/notes/upload', data={'topic_name': 'test'}, files={'file': ('file.txt', b'hello')})
    print(response.status_code)
    print(response.json())
except Exception as e:
    traceback.print_exc()
