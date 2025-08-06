import os
import secrets
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Qdrant configuration
    QDRANT_URL: str = os.getenv("QDRANT_URL", "http://localhost:6333")
    QDRANT_API_KEY: str = os.getenv("QDRANT_API_KEY", "")
    MESSAGES_COLLECTION: str = "choir"
    CHAT_THREADS_COLLECTION: str = "chat_threads"
    USERS_COLLECTION: str = "users"
    NOTIFICATIONS_COLLECTION: str = "notifications"
    DEVICE_TOKENS_COLLECTION: str = "device_tokens"
    SEARCH_LIMIT: int = 80
    VECTOR_SIZE: int = 1536

    # API configuration
    API_URL: str = os.getenv('API_URL', 'http://localhost:8000')

    # CORS configuration
    ALLOWED_ORIGINS: list = [
        "http://localhost:3000",
        "https://choir-collective.onrender.com"
    ]


    # SUI configuration
    SUI_PRIVATE_KEY: str = os.getenv("SUI_PRIVATE_KEY", "")

    # Authentication configuration
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", secrets.token_hex(32))
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours

    # AI API configuration
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")
    GOOGLE_API_KEY: str = os.getenv("GOOGLE_API_KEY", "")
    MISTRAL_API_KEY: str = os.getenv("MISTRAL_API_KEY", "")
    # AWS Bedrock configuration
    AWS_ACCESS_KEY_ID: str = os.getenv("AWS_ACCESS_KEY_ID", "")
    AWS_SECRET_ACCESS_KEY: str = os.getenv("AWS_SECRET_ACCESS_KEY", "")
    AWS_REGION: str = os.getenv("AWS_REGION", "us-east-1")

    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")

    # Azure configuration
    AZURE_API_KEY: str = os.getenv("AZURE_API_KEY", "")
    AZURE_API_BASE: str = os.getenv("AZURE_API_BASE", "")
    AZURE_API_VERSION: str = "2024-08-01-preview"

    # OpenRouter configuration
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")

    # Model configuration
    EMBEDDING_MODEL: str = "text-embedding-ada-002"

    # OpenAI models
    # OPENAI_GPT_45_PREVIEW: str = "gpt-4.5-preview"
    OPENAI_GPT_4O: str = "gpt-4o"
    OPENAI_GPT_4O_MINI: str = "gpt-4o-mini"
    OPENAI_O1: str = "o1"
    OPENAI_O3_MINI: str = "o3-mini"

    # Anthropic models
    ANTHROPIC_CLAUDE_37_SONNET: str = "claude-3-7-sonnet-latest"
    ANTHROPIC_CLAUDE_35_HAIKU: str = "claude-3-5-haiku-latest"

    # Google models
    GOOGLE_GEMINI_20_FLASH: str = "gemini-2.0-flash"
    GOOGLE_GEMINI_20_FLASH_LITE: str = "gemini-2.0-flash-lite"
    GOOGLE_GEMINI_20_PRO_EXP: str = "gemini-2.0-pro-exp-02-05"
    GOOGLE_GEMINI_20_FLASH_THINKING: str = "gemini-2.0-flash-thinking-exp-01-21"

    # Mistral models
    MISTRAL_PIXTRAL_12B: str = "pixtral-12b-2409"
    MISTRAL_SMALL_LATEST: str = "mistral-small-latest"
    MISTRAL_PIXTRAL_LARGE: str = "pixtral-large-latest"
    MISTRAL_LARGE_LATEST: str = "mistral-large-latest"
    MISTRAL_CODESTRAL: str = "codestral-latest"



    # AWS Bedrock models
    BEDROCK_CLAUDE_3_5_SONNET: str = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    BEDROCK_CLAUDE_3_5_HAIKU: str = "anthropic.claude-3-5-haiku-20241022-v1:0"
    BEDROCK_CLAUDE_3_OPUS: str = "anthropic.claude-3-opus-20240229-v1:0"
    BEDROCK_LLAMA_3_2_90B: str = "meta.llama3-2-90b-instruct-v1:0"
    BEDROCK_LLAMA_3_2_11B: str = "meta.llama3-2-11b-instruct-v1:0"

    # Groq models
    GROQ_LLAMA3_3_70B_VERSATILE: str = "llama-3.3-70b-versatile"
    GROQ_QWEN_QWQ_32B: str = "qwen-qwq-32b"
    GROQ_DEEPSEEK_R1_DISTILL_QWEN_32B: str = "deepseek-r1-distill-qwen-32b"
    GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B_SPECDEC: str = "deepseek-r1-distill-llama-70b-specdec"
    GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B: str = "deepseek-r1-distill-llama-70b"
    GROQ_LLAMA_3_1_8B_INSTANT: str = "llama-3.1-8b-instant"


    TEMPERATURE: float = 0.333

    # Chunking configuration
    CHUNK_SIZE: int = 10000
    CHUNK_OVERLAP: int = 5000

    # Debug mode
    DEBUG: bool = os.getenv('DEBUG', 'False').lower() in ('true', '1', 't')

    # Apple Push Notification service configuration
    APNS_KEY_ID: str = os.getenv("APNS_KEY_ID", "")
    APNS_TEAM_ID: str = os.getenv("APNS_TEAM_ID", "")
    APNS_AUTH_KEY: str = os.getenv("APNS_AUTH_KEY", "AuthKey_XXXXXXXXXX.p8")
    APNS_TOPIC: str = os.getenv("APNS_TOPIC", "com.choir.app")  # Bundle ID of your app

    @classmethod
    def from_env(cls):
        return cls()
