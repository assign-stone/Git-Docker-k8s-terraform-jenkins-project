# Multi-stage build for a small Python Flask app

# Builder stage
FROM python:3.11-slim AS builder
WORKDIR /app

# Install build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN python -m pip install --upgrade pip
RUN pip install --prefix=/install -r requirements.txt

# Final image
FROM python:3.11-slim
WORKDIR /app

# Create a non-root user
RUN useradd -m appuser

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy app
COPY . /app

# Change ownership and set small memory-friendly settings
RUN chown -R appuser:appuser /app
USER appuser

ENV PORT=8080
EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app", "--workers", "2", "--threads", "2"]
