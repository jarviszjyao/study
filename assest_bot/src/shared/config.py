"""Configuration loader."""
import os
from dataclasses import dataclass
from enum import Enum
from typing import Optional

from dotenv import load_dotenv

load_dotenv()


class LlmProvider(str, Enum):
    """LLM API provider - select one of two possible endpoints by config."""
    BEDROCK = "bedrock"
    BEDROCK_ALT = "bedrock_alt"  # Alternative Bedrock endpoint / model
    MOCK = "mock"


@dataclass
class DbConfig:
    host: str
    port: int
    name: str
    user: str
    password: str

    @classmethod
    def from_env(cls) -> "DbConfig":
        return cls(
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "5432")),
            name=os.getenv("DB_NAME", "cloud_resources"),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", ""),
        )


@dataclass
class LlmConfig:
    """LLM configuration. Select one of two API calls by LLM_PROVIDER."""
    region: str
    model_id: str
    provider: LlmProvider
    # Alternative endpoint (e.g. different Bedrock model or team API)
    alt_model_id: Optional[str] = None
    alt_region: Optional[str] = None

    @classmethod
    def from_env(cls) -> "LlmConfig":
        provider_str = os.getenv("LLM_PROVIDER", "mock").lower()
        if provider_str in ("bedrock", "1"):
            provider = LlmProvider.BEDROCK
        elif provider_str in ("bedrock_alt", "2", "alt"):
            provider = LlmProvider.BEDROCK_ALT
        else:
            provider = LlmProvider.MOCK

        return cls(
            region=os.getenv("AWS_REGION", "us-east-1"),
            model_id=os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-v2"),
            provider=provider,
            alt_model_id=os.getenv("BEDROCK_ALT_MODEL_ID"),
            alt_region=os.getenv("BEDROCK_ALT_REGION", os.getenv("AWS_REGION", "us-east-1")),
        )
