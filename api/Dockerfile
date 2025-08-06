# Cache bust: 2025-08-06
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies and uv
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libyaml-dev \
    curl \
    build-essential \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

# Add uv to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Copy dependency files
COPY api/pyproject.toml api/uv.lock* ./

# Install dependencies with uv (much faster than pip)
RUN uv sync --frozen --no-dev

# Copy application code
COPY api/ .

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

# Use uv to run the application
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
