"""Security Guard — Layer 3 trong defense-in-depth (Section 13.1)."""
from __future__ import annotations

from dataclasses import dataclass

from .prompt_injection import find_pattern

# Response chuẩn khi câu hỏi bị từ chối — Section 13.2.
BLOCK_MESSAGE = (
    "Tôi không thể thực hiện yêu cầu này vì vượt quá phạm vi bảo mật của hệ thống."
)


@dataclass(frozen=True, slots=True)
class GuardDecision:
    allowed: bool
    risk_level: str | None = None
    matched_pattern: str | None = None
    block_reason: str | None = None


class SecurityException(Exception):
    """Raise từ node `security_guard` để FallbackHandler bọc và trả block message."""

    def __init__(self, decision: GuardDecision):
        super().__init__(decision.block_reason or "Security block")
        self.decision = decision


class SecurityGuard:
    """Pure logic check Phase 1B — không gọi LLM (Phase 1B doc note: Logic + LLM,
    LLM phần để Phase 2+). Pattern match tham khảo Section 13.2.
    """

    def check(self, text: str) -> GuardDecision:
        if not text or not text.strip():
            return GuardDecision(
                allowed=False,
                risk_level="low",
                block_reason="Câu hỏi rỗng.",
            )

        match = find_pattern(text)
        if match is not None:
            pattern, risk = match
            return GuardDecision(
                allowed=False,
                risk_level=risk,
                matched_pattern=pattern,
                block_reason=BLOCK_MESSAGE,
            )

        return GuardDecision(allowed=True)
