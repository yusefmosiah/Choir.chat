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

# Install packages in stages to help with dependency resolution
# 1. Core dependencies
RUN pip install --no-cache-dir "pydantic>=2.0.0,<3.0.0" "pydantic-settings>=2.0.0,<3.0.0" "fastapi>=0.110.0,<0.116.0" "httpx>=0.24.0,<0.28.0" "gunicorn==20.1.0" "python-dotenv==1.0.0" "PyYAML==6.0.1"

# 2. Install pysui separately because of Rust dependencies
RUN pip install --no-cache-dir "pysui==0.72.0"

# 3. Install AI model tools
RUN pip install --no-cache-dir "litellm==1.52.3" "openai==1.65.0" "tiktoken==0.8.0" "tokenizers==0.15.2"

# 4. Install LangChain ecosystem
RUN pip install --no-cache-dir "langchain==0.3.0" "langchain-core==0.3.0" "langgraph==0.3.0" "langserve==0.3.0" "langchain-community==0.3.0"

# 5. Install provider-specific packages
RUN pip install --no-cache-dir "langchain-openai==0.3.0" "langchain-anthropic==0.3.0" "langchain-google-genai==2.0.0" "langchain-mistralai==0.2.0" "langchain-fireworks==0.2.0" "langchain-cohere==0.4.0"

# 6. Install remaining tools
RUN pip install --no-cache-dir "qdrant-client==1.12.1" "duckduckgo-search==7.0.0" "pytest==8.0.0" "pytest-asyncio==0.23.5" "uvicorn[standard]==0.27.1"

# Copy application code
COPY api/ .

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
