import uuid
import datetime
from typing import Optional
from pydantic import BaseModel, Field


class UserBase(BaseModel):
    mobile_number: str = Field(..., description="Mobile number with country code")
    role: str = "Driver"
    status: str = "Active"


class UserCreate(UserBase):
    pass


class UserResponse(UserBase):
    id: uuid.UUID
    email: Optional[str] = None
    fcm_token: Optional[str] = None
    preferred_language: str = "en"
    is_active: bool
    last_login: Optional[datetime.datetime] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = {"from_attributes": True}


class LoginRequest(BaseModel):
    mobile_number: str = Field(..., description="Mobile number with country code e.g. +919876543210")


class OTPVerifyRequest(BaseModel):
    mobile_number: str = Field(...)
    otp: str = Field(..., description="6-digit OTP code")
    role: Optional[str] = None                      # Role selected by user (Driver/Partner/Fleet Owner)
    device_info: Optional[str] = None               # Device model/OS info
    device_id: Optional[str] = None                 # Unique device fingerprint
    platform: Optional[str] = None                  # android / ios / web
    fcm_token: Optional[str] = None                 # FCM push token
    preferred_language: Optional[str] = "en"        # Language preference


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
    is_new_user: bool = False
    is_profile_complete: bool
    is_kyc_verified: bool
    terms_accepted: bool = False
    onboarding_step: int = 0
    preferred_language: str = "en"


class TokenRefreshRequest(BaseModel):
    refresh_token: str
