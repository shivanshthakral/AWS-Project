from pathlib import Path
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app
from extensions import db
from models import User


@pytest.fixture
def app():
    app = create_app(
        {
            "TESTING": True,
            "SECRET_KEY": "test-secret",
            "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        }
    )

    with app.app_context():
        db.drop_all()
        db.create_all()
        user = User(username="demo", email="demo@example.com")
        user.set_password("password123")
        db.session.add(user)
        db.session.commit()

    yield app


@pytest.fixture
def client(app):
    return app.test_client()


def test_login_success_redirects_to_dashboard(client):
    response = client.post(
        "/login",
        data={"username": "demo", "password": "password123"},
        follow_redirects=False,
    )
    assert response.status_code == 302
    assert "/dashboard" in response.headers["Location"]


def test_login_failure_returns_401(client):
    response = client.post(
        "/login",
        data={"username": "demo", "password": "wrong-password"},
        follow_redirects=False,
    )
    assert response.status_code == 401


def test_api_requires_authentication(client):
    response = client.get("/api/resources")
    assert response.status_code == 302
    assert "/login" in response.headers["Location"]
