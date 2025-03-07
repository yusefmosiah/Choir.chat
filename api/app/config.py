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


    # SUI configuration
    SUI_PRIVATE_KEY: str = os.getenv("SUI_PRIVATE_KEY", "")

    # AI API configuration
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")
    GOOGLE_API_KEY: str = os.getenv("GOOGLE_API_KEY", "")
    MISTRAL_API_KEY: str = os.getenv("MISTRAL_API_KEY", "")
    FIREWORKS_API_KEY: str = os.getenv("FIREWORKS_API_KEY", "")
    COHERE_API_KEY: str = os.getenv("COHERE_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")

    # Azure configuration
    AZURE_API_KEY: str = os.getenv("AZURE_API_KEY", "")
    AZURE_API_BASE: str = os.getenv("AZURE_API_BASE", "")
    AZURE_API_VERSION: str = "2024-08-01-preview"

    # OpenRouter configuration
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")

    # Model configuration
    EMBEDDING_MODEL: str = "text-embedding-ada-002"
    CHAT_MODEL: str = "anthropic/claude-3-5-haiku-20241022"
    SUMMARY_MODEL: str = "anthropic/claude-3-5-sonnet-20241022"

    # OpenRouter models
    OPENROUTER_CLAUDE_3_5_HAIKU: str = "openrouter/anthropic/claude-3.5-haiku"
    OPENROUTER_CLAUDE_3_5_SONNET: str = "openrouter/anthropic/claude-3.5-sonnet"

    # Azure models
    AZURE_CHAT_MODEL: str = "azure/gpt-4o-2024-08-06"

    # OpenAI models
    OPENAI_GPT_45_PREVIEW: str = "gpt-4.5-preview"
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

    # Cohere models
    COHERE_COMMAND_R7B: str = "command-r7b-12-2024"

    # Fireworks models (without prefix)
    FIREWORKS_DEEPSEEK_R1: str = "deepseek-r1"
    FIREWORKS_DEEPSEEK_V3: str = "deepseek-v3"
    FIREWORKS_QWEN25_CODER: str = "qwen2p5-coder-32b-instruct"
    FIREWORKS_QWEN_QWQ_32B: str = "qwen-qwq-32b"

    # Groq models
    GROQ_LLAMA3_3_70B_VERSATILE: str = "llama-3.3-70b-versatile"
    GROQ_QWEN_QWQ_32B: str = "qwen-qwq-32b"
    GROQ_DEEPSEEK_R1_DISTILL_QWEN_32B: str = "deepseek-r1-distill-qwen-32b"
    GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B_SPECDEC: str = "deepseek-r1-distill-llama-70b-specdec"
    GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B: str = "deepseek-r1-distill-llama-70b"


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
