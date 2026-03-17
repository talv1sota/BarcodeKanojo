"""API response wrapper matching the Android ResponseParser format.

The Android client expects JSON responses in this format:
{
    "code": 200,
    "message": "...",
    "user": { ... },
    "kanojo": { ... },
    ...
}
"""
from typing import Any


def api_response(code: int = 200, message: str = "OK", **kwargs: Any) -> dict:
    """Build a response dict matching the Android client's expected format."""
    response = {"code": code, "message": message}
    response.update(kwargs)
    return response


def error_response(code: int = 400, message: str = "Error") -> dict:
    return {"code": code, "message": message}
