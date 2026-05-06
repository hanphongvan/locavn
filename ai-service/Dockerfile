FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install deps trước để tận dụng layer cache khi code thay đổi.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root user.
RUN useradd --create-home --uid 10001 ai && chown -R ai:ai /app
USER ai

COPY --chown=ai:ai app ./app

EXPOSE 8001

# Production: bỏ --reload, ép 1 worker để giữ in-memory cache nhất quán Phase 1B.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--workers", "1"]
