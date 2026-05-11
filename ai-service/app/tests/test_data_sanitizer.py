"""Test DataSanitizer — Section 10.4."""
from __future__ import annotations

from app.services.data_sanitizer import MAX_TABLE_ROWS, sanitize_for_llm


def test_sanitizer_strips_forbidden_keys():
    raw = {
        "summary": {"total": 100},
        "connection_string": "Server=...;Pwd=secret",
        "password": "leaked",
        "api_key": "sk-xxx",
        "raw_sql": "SELECT * FROM users",
        "schema": "AspNetUsers, AspNetRoles, ...",
        "rows": [],
    }
    cleaned = sanitize_for_llm(raw)
    cleaned_str = str(cleaned)

    assert "secret" not in cleaned_str
    assert "leaked" not in cleaned_str
    assert "sk-xxx" not in cleaned_str
    assert "SELECT * FROM" not in cleaned_str
    assert "AspNetUsers" not in cleaned_str
    assert cleaned["summary"] == {"total": 100}


def test_sanitizer_limits_rows_to_20():
    rows = [{"id": i} for i in range(50)]
    cleaned = sanitize_for_llm({"summary": {}, "rows": rows})
    assert len(cleaned["top_items"]) == MAX_TABLE_ROWS


def test_sanitizer_handles_nested_secrets():
    raw = {
        "rows": [
            {"id": 1, "name": "foo", "user_password": "abc123"},
            {"id": 2, "name": "bar", "token": "tk-456"},
        ],
    }
    cleaned = sanitize_for_llm(raw)
    assert "abc123" not in str(cleaned)
    assert "tk-456" not in str(cleaned)


def test_sanitizer_handles_non_dict_input():
    cleaned = sanitize_for_llm("just a string")  # type: ignore[arg-type]
    assert cleaned == {"data": "just a string"}
