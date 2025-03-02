# Cache bust: 2025-03-02
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies and Rust in a single layer
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libyaml-dev \
    curl \
    build-essential \
    && curl https://sh.rustup.rs -sSf | bash -s -- -y \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.cargo/bin:${PATH}"

# Create and activate virtual environment
ENV VIRTUAL_ENV=/app/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install latest build tools
COPY api/requirements.txt requirements.txt
RUN pip install --no-cache-dir --upgrade wheel setuptools pip

# Create a filtered requirements file excluding packages we'll install separately
RUN grep -v -E "^(fastapi|pydantic|pydantic-settings|httpx|gunicorn|python-dotenv|PyYAML|pysui)" requirements.txt > filtered_requirements.txt

# Install packages in stages to help with dependency resolution
# 1. Core dependencies (web framework and basic utilities)
RUN pip install --no-cache-dir fastapi pydantic pydantic-settings httpx gunicorn python-dotenv PyYAML

# 2. Install pysui separately because of Rust dependencies
RUN pip install --no-cache-dir pysui

# 3. Install remaining dependencies from filtered requirements file
RUN pip install --no-cache-dir -r filtered_requirements.txt

# Copy application code
COPY api/ .

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
