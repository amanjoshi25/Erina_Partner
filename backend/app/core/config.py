import os
from typing import Any, Dict, Optional
from pydantic import PostgresDsn, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Erina Assistance Platform"

    # PostgreSQL Configuration
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "erina_admin"
    POSTGRES_PASSWORD: str = "erina_secure_password"
    POSTGRES_DB: str = "erina_db"
    POSTGRES_PORT: str = "5432"
    
    SQLALCHEMY_DATABASE_URI: Optional[str] = None

    @field_validator("SQLALCHEMY_DATABASE_URI", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: Optional[str], info: Any) -> Any:
        if isinstance(v, str) and v:
            return v
        
        # Accessing settings from the inputs/values dict
        data = info.data
        return f"postgresql://{data.get('POSTGRES_USER')}:{data.get('POSTGRES_PASSWORD')}@{data.get('POSTGRES_SERVER')}:{data.get('POSTGRES_PORT')}/{data.get('POSTGRES_DB')}"

    # JWT Config
    SECRET_KEY: str = "super_secret_temporary_key_for_dev_change_me_in_prod"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days

    # Firebase Config
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None

    model_config = SettingsConfigDict(
        case_sensitive=True,
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
