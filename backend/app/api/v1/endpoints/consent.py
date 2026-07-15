import datetime
from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.core.config import settings
from app.models.user import User, UserConsent
from app.models.driver import Driver

router = APIRouter()


class ConsentRequest(BaseModel):
    terms_accepted: bool
    privacy_accepted: bool
    marketing_consent: bool = False


class ConsentStatusResponse(BaseModel):
    terms_accepted: bool
    privacy_accepted: bool
    marketing_consent: bool
    terms_version: str
    privacy_version: str
    is_current_version: bool
    accepted_at: datetime.datetime | None = None


@router.post("/accept", status_code=status.HTTP_200_OK)
def accept_consent(
    payload: ConsentRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Record user's acceptance of Terms & Conditions, Privacy Policy, and optional
    marketing consent. Advances Driver onboarding_step to 2 (profile setup).
    """
    if not payload.terms_accepted or not payload.privacy_accepted:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You must accept both Terms & Conditions and Privacy Policy to continue."
        )

    client_ip = request.client.host if request.client else None

    # Save consent record
    consent = UserConsent(
        user_id=current_user.id,
        terms_version=settings.TERMS_VERSION,
        privacy_version=settings.PRIVACY_VERSION,
        terms_accepted=payload.terms_accepted,
        privacy_accepted=payload.privacy_accepted,
        marketing_consent=payload.marketing_consent,
        accepted_at=datetime.datetime.utcnow(),
        ip_address=client_ip,
        device_info=request.headers.get("User-Agent")
    )
    db.add(consent)

    # Advance Driver onboarding step
    if current_user.role == "Driver":
        driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
        if driver:
            driver.terms_accepted = True
            driver.marketing_consent = payload.marketing_consent
            if driver.onboarding_step < 2:
                driver.onboarding_step = 2  # Move to profile setup step

    db.commit()
    return {
        "message": "Consent recorded successfully",
        "terms_version": settings.TERMS_VERSION,
        "privacy_version": settings.PRIVACY_VERSION,
        "next_step": "profile_setup"
    }


@router.get("/status", response_model=ConsentStatusResponse)
def get_consent_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Check if the user has accepted the current version of Terms & Privacy Policy.
    """
    latest_consent = db.query(UserConsent).filter(
        UserConsent.user_id == current_user.id,
        UserConsent.terms_accepted == True,
        UserConsent.privacy_accepted == True
    ).order_by(UserConsent.accepted_at.desc()).first()

    if not latest_consent:
        return ConsentStatusResponse(
            terms_accepted=False,
            privacy_accepted=False,
            marketing_consent=False,
            terms_version=settings.TERMS_VERSION,
            privacy_version=settings.PRIVACY_VERSION,
            is_current_version=False
        )

    is_current = (
        latest_consent.terms_version == settings.TERMS_VERSION and
        latest_consent.privacy_version == settings.PRIVACY_VERSION
    )

    return ConsentStatusResponse(
        terms_accepted=latest_consent.terms_accepted,
        privacy_accepted=latest_consent.privacy_accepted,
        marketing_consent=latest_consent.marketing_consent,
        terms_version=latest_consent.terms_version,
        privacy_version=latest_consent.privacy_version,
        is_current_version=is_current,
        accepted_at=latest_consent.accepted_at
    )
