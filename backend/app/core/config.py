import os
from typing import Any, Dict, Literal, Optional
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
        data = info.data
        return f"postgresql://{data.get('POSTGRES_USER')}:{data.get('POSTGRES_PASSWORD')}@{data.get('POSTGRES_SERVER')}:{data.get('POSTGRES_PORT')}/{data.get('POSTGRES_DB')}"

    # JWT Config
    SECRET_KEY: str = "super_secret_temporary_key_for_dev_change_me_in_prod"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days

    # ─── OTP Service ───────────────────────────────────────────────────────────
    # "mock" → print to console (dev/test)
    # "real" → call MSG91 SMS gateway
    OTP_MODE: Literal["mock", "real"] = "mock"
    MSG91_API_KEY: Optional[str] = None
    MSG91_TEMPLATE_ID: Optional[str] = None
    MSG91_SENDER_ID: str = "ERINAA"

    # ─── OCR Service ───────────────────────────────────────────────────────────
    # "mock" → return dummy extracted data
    # "real" → call Google Cloud Vision API
    OCR_MODE: Literal["mock", "real"] = "mock"
    GOOGLE_VISION_API_KEY: Optional[str] = None

    # ─── RC/DL Verification ────────────────────────────────────────────────────
    # "mock" → return dummy verified data
    # "real" → call Surepass API
    VERIFICATION_MODE: Literal["mock", "real"] = "mock"
    SUREPASS_API_KEY: Optional[str] = None
    SUREPASS_BASE_URL: str = "https://kyc-api.surepass.io/api/v1"

    # ─── Firebase ──────────────────────────────────────────────────────────────
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_STORAGE_BUCKET: Optional[str] = None
    # "mock" → store files locally in /static/uploads/
    # "real" → upload to Firebase Storage
    STORAGE_MODE: Literal["mock", "real"] = "mock"
    # "mock" → print FCM payload to console
    # "real" → send via Firebase Admin SDK
    FCM_MODE: Literal["mock", "real"] = "mock"

    # ─── Rate Limiting ─────────────────────────────────────────────────────────
    RATE_LIMIT_ENABLED: bool = True
    OTP_REQUEST_LIMIT: str = "5/10minutes"   # per IP per 10 minutes
    OTP_VERIFY_LIMIT: str = "10/10minutes"   # per IP per 10 minutes
    UPLOAD_LIMIT: str = "20/hour"            # per user per hour

    # ─── App Config ────────────────────────────────────────────────────────────
    TERMS_VERSION: str = "1.0"
    PRIVACY_VERSION: str = "1.0"
    DEBUG: bool = True

    model_config = SettingsConfigDict(
        case_sensitive=True,
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
