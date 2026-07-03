import uuid
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field
import datetime

class DriverAddressBase(BaseModel):
    address_line1: str
    address_line2: Optional[str] = None
    city: str
    state: str
    postal_code: str
    country: str = "India"

class DriverAddressCreate(DriverAddressBase):
    pass

class DriverAddressResponse(DriverAddressBase):
    id: uuid.UUID
    driver_id: uuid.UUID
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = {
        "from_attributes": True
    }

class DriverBase(BaseModel):
    full_name: Optional[str] = None
    dob: Optional[datetime.date] = None
    sex: Optional[str] = None
    emergency_contact_no: Optional[str] = None

class DriverCreate(DriverBase):
    user_id: uuid.UUID

class DriverUpdate(BaseModel):
    full_name: str
    dob: datetime.date
    sex: str
    emergency_contact_no: str

class DriverResponse(DriverBase):
    id: uuid.UUID
    user_id: uuid.UUID
    driver_code: Optional[str] = None
    profile_photo: Optional[str] = None
    status: str
    verification_status: str
    created_at: datetime.datetime
    updated_at: datetime.datetime
    address: Optional[DriverAddressResponse] = None

    model_config = {
        "from_attributes": True
    }

class DriverDocumentResponse(BaseModel):
    id: uuid.UUID
    driver_id: uuid.UUID
    document_id: str
    document_no: Optional[str] = None
    firebase_url: str
    expiry_date: Optional[datetime.date] = None
    verification_status: str
    ocr_response: Optional[Dict[str, Any]] = None
    verified_at: Optional[datetime.datetime] = None
    verified_by: Optional[uuid.UUID] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    model_config = {
        "from_attributes": True
    }

class KYCStatusResponse(BaseModel):
    kyc_status: str
    documents: List[DriverDocumentResponse]

class AdminKYCVerifyRequest(BaseModel):
    document_id: uuid.UUID
    status: str = Field(..., description="approved or rejected")
    rejection_reason: Optional[str] = None
