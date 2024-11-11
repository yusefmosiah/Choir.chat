from fastapi.testclient import TestClient
from main import app  # Use absolute import

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_log_click():
    response = client.post("/api/log-click")
    assert response.status_code == 200
    assert response.json() == {"status": "success", "message": "Click logged"}
