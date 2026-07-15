import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver, get_current_user
from app.models.driver import Driver, DriverAddress
from app.models.user import User
from app.services.storage import upload_document
from app.schemas.driver import DriverResponse, DriverAddressBase, DriverAddressResponse

router = APIRouter()


class DriverProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    dob: Optional[str] = None           # YYYY-MM-DD
    sex: Optional[str] = None
    email: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_no: Optional[str] = None
    emergency_contact_relation: Optional[str] = None
    preferred_language: Optional[str] = None


class DeleteAccountRequest(BaseModel):
    reason: Optional[str] = None


@router.get("/profile")
def get_driver_profile(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Get the authenticated driver's full profile including address."""
    address = driver.address
    return {
        "id": str(driver.id),
        "driver_code": driver.driver_code,
        "full_name": driver.full_name,
        "dob": driver.dob.isoformat() if driver.dob else None,
        "sex": driver.sex,
        "email": driver.email,
        "profile_photo": driver.profile_photo,
        "emergency_contact_name": driver.emergency_contact_name,
        "emergency_contact_no": driver.emergency_contact_no,
        "emergency_contact_relation": driver.emergency_contact_relation,
        "preferred_language": driver.preferred_language,
        "onboarding_step": driver.onboarding_step,
        "terms_accepted": driver.terms_accepted,
        "verification_status": driver.verification_status,
        "status": driver.status,
        "address": {
            "address_line1": address.address_line1,
            "address_line2": address.address_line2,
            "city": address.city,
            "state": address.state,
            "postal_code": address.postal_code,
            "country": address.country
        } if address else None,
        "created_at": driver.created_at.isoformat()
    }


@router.put("/profile")
def update_driver_profile(
    payload: DriverProfileUpdate,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Update driver personal details. Advances onboarding_step to 3 (KYC)
    when core required fields (full_name, dob, sex) are all provided.
    """
    if payload.full_name is not None:
        driver.full_name = payload.full_name
    if payload.dob is not None:
        try:
            driver.dob = datetime.datetime.strptime(payload.dob, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    if payload.sex is not None:
        driver.sex = payload.sex
    if payload.email is not None:
        driver.email = payload.email
    if payload.emergency_contact_name is not None:
        driver.emergency_contact_name = payload.emergency_contact_name
    if payload.emergency_contact_no is not None:
        driver.emergency_contact_no = payload.emergency_contact_no
    if payload.emergency_contact_relation is not None:
        driver.emergency_contact_relation = payload.emergency_contact_relation
    if payload.preferred_language is not None:
        driver.preferred_language = payload.preferred_language

    # Advance onboarding if core profile is complete
    is_profile_complete = bool(driver.full_name and driver.dob and driver.sex)
    if is_profile_complete and driver.onboarding_step < 3:
        driver.onboarding_step = 3  # Move to KYC step

    # Advance verification status from pending → in_progress
    if is_profile_complete and driver.verification_status == "pending":
        driver.verification_status = "in_progress"

    db.commit()
    db.refresh(driver)

    return {
        "message": "Profile updated successfully",
        "onboarding_step": driver.onboarding_step,
        "is_profile_complete": is_profile_complete,
        "next_step": "kyc_upload" if is_profile_complete else "complete_profile"
    }


@router.post("/profile/photo")
async def upload_profile_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Upload a profile photo. Stores in Firebase Storage (or local in mock mode)."""
    file_bytes = await file.read()

    # Basic size check (max 5MB for profile photo)
    size_mb = len(file_bytes) / (1024 * 1024)
    if size_mb > 5:
        raise HTTPException(status_code=400, detail="Profile photo must be under 5MB")

    # Validate image
    from PIL import Image
    import io
    try:
        img = Image.open(io.BytesIO(file_bytes))
        img.verify()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file")

    photo_url = await upload_document(
        file_bytes=file_bytes,
        original_filename=file.filename or "profile.jpg",
        folder=f"profile/{driver.id}",
        content_type=file.content_type or "image/jpeg"
    )

    # Delete old photo if exists
    if driver.profile_photo and driver.profile_photo != photo_url:
        from app.services.storage import delete_document
        await delete_document(driver.profile_photo)

    driver.profile_photo = photo_url
    db.commit()

    return {"message": "Profile photo updated", "photo_url": photo_url}


@router.get("/address")
def get_driver_address(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Get the driver's address."""
    if not driver.address:
        raise HTTPException(status_code=404, detail="Address not found")
    return driver.address


@router.post("/address")
def create_or_update_driver_address(
    payload: DriverAddressBase,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Create or update driver address."""
    if driver.address:
        addr = driver.address
        addr.address_line1 = payload.address_line1
        addr.address_line2 = payload.address_line2
        addr.city = payload.city
        addr.state = payload.state
        addr.postal_code = payload.postal_code
        addr.country = payload.country
    else:
        addr = DriverAddress(
            driver_id=driver.id,
            address_line1=payload.address_line1,
            address_line2=payload.address_line2,
            city=payload.city,
            state=payload.state,
            postal_code=payload.postal_code,
            country=payload.country
        )
        db.add(addr)
    db.commit()
    db.refresh(addr)
    return addr


@router.post("/account/delete-request")
def request_account_deletion(
    payload: DeleteAccountRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver),
    current_user: User = Depends(get_current_user)
):
    """
    Soft-delete request: marks account as Deleted and deactivates it.
    Data is retained for legal/audit purposes.
    """
    current_user.status = "Deleted"
    current_user.is_active = False
    current_user.deleted_at = datetime.datetime.utcnow()
    driver.status = "Inactive"

    # Revoke all active sessions
    from app.models.user import UserSession
    db.query(UserSession).filter(
        UserSession.user_id == current_user.id,
        UserSession.is_revoked == False
    ).update({"is_revoked": True})

    db.commit()
    return {"message": "Account deletion request submitted. Your account will be deactivated within 24 hours."}
