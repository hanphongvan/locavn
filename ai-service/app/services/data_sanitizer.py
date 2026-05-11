"""DataSanitizer — Section 10.4. Loại bỏ trường nhạy cảm trước khi gửi cloud LLM."""
from __future__ import annotations

from typing import Any

# Field names cấm gửi lên LLM (Section 10.4 "KHÔNG được gửi").
_FORBIDDEN_KEYS = frozenset({
    "connection_string", "connectionstring", "conn_str",
    "password", "passwords", "user_password", "user_passwords",
    "api_key", "apikey", "secret", "secrets", "token", "tokens",
    "raw_sql", "rawsql", "sql_query", "sqlquery",
    "schema", "full_schema", "database_schema",
    "user_list", "users", "user_emails", "phone_numbers",
})

# Tối đa 20 hàng bảng số liệu (Section 10.4 "Chỉ được gửi").
MAX_TABLE_ROWS = 20


def _scrub_dict(d: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in d.items():
        if key.lower() in _FORBIDDEN_KEYS:
            continue
        out[key] = _scrub(value)
    return out


def _scrub(value: Any) -> Any:
    if isinstance(value, dict):
        return _scrub_dict(value)
    if isinstance(value, list):
        return [_scrub(item) for item in value]
    return value


def sanitize_for_llm(tool_result: dict[str, Any]) -> dict[str, Any]:
    """Trả về dict an toàn để đưa vào LLM prompt.

    - Strip trường nhạy cảm (connection_string, passwords, raw_sql, schema, ...).
    - Giới hạn list rows ≤ 20.
    - Giữ structure summary/kpi/notes để LLM vẫn hiểu data.
    """
    if not isinstance(tool_result, dict):
        return {"data": tool_result}

    cleaned = _scrub_dict(tool_result)

    # Giới hạn rows — bất kể tên field (rows / table / top_items / ...).
    for key in ("rows", "table", "top_items"):
        if key in cleaned and isinstance(cleaned[key], list):
            cleaned[key] = cleaned[key][:MAX_TABLE_ROWS]

    # Section 10.4 ưu tiên trả summary + kpi + top_items + notes.
    return {
        "summary": cleaned.get("summary"),
        "kpi": cleaned.get("kpi"),
        "top_items": cleaned.get("top_items") or cleaned.get("rows") or cleaned.get("table") or [],
        "notes": cleaned.get("notes"),
    }
