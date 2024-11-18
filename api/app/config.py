import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Qdrant configuration
    QDRANT_URL: str = os.getenv("QDRANT_URL", "http://localhost:6333")
    QDRANT_API_KEY: str = os.getenv("QDRANT_API_KEY", "")
    MESSAGES_COLLECTION: str = "choir"
    CHAT_THREADS_COLLECTION: str = "chat_threads"
    USERS_COLLECTION: str = "users"
    SEARCH_LIMIT: int = 80
    VECTOR_SIZE: int = 1536

    # API configuration
    API_URL: str = os.getenv('API_URL', 'http://localhost:8000')

    # CORS configuration
    ALLOWED_ORIGINS: list = [
        "http://localhost:3000",
        "https://choir-collective.onrender.com"
    ]

    # AI API configuration
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")

    # Azure configuration
    AZURE_API_KEY: str = os.getenv("AZURE_API_KEY", "")
    AZURE_API_BASE: str = os.getenv("AZURE_API_BASE", "")
    AZURE_API_VERSION: str = "2024-08-01-preview"

    # Model configuration
    EMBEDDING_MODEL: str = "text-embedding-ada-002"
    CHAT_MODEL: str = "anthropic/claude-3-5-haiku-20241022"
    SUMMARY_MODEL: str = "anthropic/claude-3-5-sonnet-20241022"
    CLAUDE_3_5_SONNET_NEW: str = "anthropic/claude-3-5-sonnet-20241022"
    AZURE_CHAT_MODEL: str = "azure/gpt-4o-2024-08-06"
    MAX_TOKENS: int = 4000
    TEMPERATURE: float = 0.7

    # Chunking configuration
    CHUNK_SIZE: int = 10000
    CHUNK_OVERLAP: int = 5000

    # Debug mode
    DEBUG: bool = os.getenv('DEBUG', 'False').lower() in ('true', '1', 't')

    @classmethod
    def from_env(cls):
        return cls()
