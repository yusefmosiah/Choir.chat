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

# Install build dependencies first
COPY api/requirements.txt requirements.txt
RUN pip install --no-cache-dir wheel setuptools pip

# Split requirements into two steps - compile heavy ones first
RUN pip install --no-cache-dir pysui

# Install remaining requirements
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY api/ .

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
