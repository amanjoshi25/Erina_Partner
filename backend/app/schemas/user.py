import uuid
from typing import Optional
from pydantic import BaseModel, Field, EmailStr
import datetime

class UserBase(BaseModel):
    mobile_number: str = Field(..., description="Mobile number with country code")
    role: str = "Driver"
    status: str = "Active"

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: uuid.UUID
    email: Optional[str] = None
    is_active: bool
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = {
        "from_attributes": True
    }

class LoginRequest(BaseModel):
    mobile_number: str = Field(..., description="Mobile number (e.g. +919876543210)")

class OTPVerifyRequest(BaseModel):
    mobile_number: str = Field(...)
    otp: str = Field(..., description="6-digit verification code")
    role: Optional[str] = None
    device_info: Optional[str] = None
    ip_address: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
    is_profile_complete: bool
    is_kyc_verified: bool

class TokenRefreshRequest(BaseModel):
    refresh_token: str
