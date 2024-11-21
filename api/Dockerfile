FROM python:3.12-slim

WORKDIR /app

# Install system dependencies required for building Rust extensions
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libyaml-dev \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (required for pysui)
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Start command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
