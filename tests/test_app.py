from pathlib import Path

from fastapi import Response
from fastapi.responses import FileResponse

import main


def configure_local_state(tmp_path, monkeypatch):
    monkeypatch.setattr(main, "USERS_FILE", Path(tmp_path) / "users.json")
    monkeypatch.setattr(main, "MEMORY_FILE", Path(tmp_path) / "memory_store.json")
    monkeypatch.setattr(main, "user_store", main.LocalUserStore(main.USERS_FILE))
    monkeypatch.setattr(main, "local_store", main.LocalMemoryStore(main.MEMORY_FILE))
    monkeypatch.setattr(main, "client", None)
    monkeypatch.setattr(main, "use_hindsight", False)
    monkeypatch.setattr(main, "AUTOMATION_API_KEY", "")


def test_root_serves_index(tmp_path, monkeypatch):
    configure_local_state(tmp_path, monkeypatch)

    response = main.root()

    assert isinstance(response, FileResponse)
    assert Path(response.path) == main.INDEX_FILE


def test_status_reports_local_mode(tmp_path, monkeypatch):
    configure_local_state(tmp_path, monkeypatch)

    payload = main.runtime_status()

    assert payload["app"] == "kelsa.ai"
    assert payload["memory_mode"] == "local"
    assert payload["hindsight_enabled"] is False
    assert payload["automation_enabled"] is False


def test_signup_sets_session_and_returns_current_user(tmp_path, monkeypatch):
    configure_local_state(tmp_path, monkeypatch)
    response = Response()

    signup_payload = main.UserCreateInput(
        name="Test User",
        email="test@example.com",
        password="supersecure123",
    )
    signup_result = main.signup(signup_payload, response)

    assert signup_result["message"] == "Account created successfully."

    set_cookie_header = response.headers.get("set-cookie", "")
    assert main.SESSION_COOKIE_NAME in set_cookie_header

    session_token = response.headers["set-cookie"].split(f"{main.SESSION_COOKIE_NAME}=", 1)[1].split(";", 1)[0]
    current_user = main.get_current_user(session_token=session_token)
    me_payload = main.current_user(current_user)

    assert me_payload["user"]["email"] == "test@example.com"
    assert me_payload["user"]["name"] == "Test User"
