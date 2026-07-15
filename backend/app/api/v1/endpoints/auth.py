import datetime
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User, OTPVerification, UserSession, UserConsent
from app.models.driver import Driver
from app.schemas.user import LoginRequest, OTPVerifyRequest, TokenResponse, TokenRefreshRequest, UserResponse
from app.core import security
from app.core.dependencies import get_current_user
from app.core.config import settings
from app.services import sms as sms_service
from app.services import notifications as fcm_service

router = APIRouter()

MAX_OTP_ATTEMPTS = 5


@router.post("/login", status_code=status.HTTP_200_OK)
async def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    """
    Step 1 of Auth: Receive mobile number, generate 6-digit OTP,
    hash and store it, then send via SMS gateway.
    Returns debug_code only in mock mode.
    """
    mobile = payload.mobile_number.strip()
    if not mobile:
        raise HTTPException(status_code=400, detail="Mobile number is required")

    # Invalidate any existing unexpired OTPs for this mobile
    db.query(OTPVerification).filter(
        OTPVerification.mobile_no == mobile,
        OTPVerification.verified == False,
        OTPVerification.expires_at > datetime.datetime.utcnow()
    ).update({"verified": True})  # Mark old OTPs as used
    db.commit()

    otp_code = security.generate_otp()
    otp_hash = security.hash_otp(otp_code)
    expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=5)

    otp_record = OTPVerification(
        mobile_no=mobile,
        otp_hash=otp_hash,
        otp_channel="sms",
        expires_at=expiry,
        verified=False,
        attempts=0,
        max_attempts=MAX_OTP_ATTEMPTS
    )
    db.add(otp_record)
    db.commit()

    # Send OTP (mock or real SMS)
    sent = await sms_service.send_otp_sms(mobile, otp_code)
    if not sent:
        raise HTTPException(status_code=503, detail="Failed to send OTP. Please try again.")

    response = {
        "message": "OTP sent successfully",
        "mobile_number": mobile,
        "expires_in_seconds": 300,
    }

    # Only return OTP code in mock mode for development testing
    if settings.OTP_MODE == "mock":
        response["debug_code"] = otp_code

    return response


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(payload: OTPVerifyRequest, request: Request, db: Session = Depends(get_db)):
    """
    Step 2 of Auth: Verify the 6-digit OTP. On success, get/create user,
    create role profile, issue JWT tokens, and create session.
    """
    mobile = payload.mobile_number.strip()
    otp_code = payload.otp.strip()

    # Check master bypass code (dev only — remove in production)
    is_master_code = (settings.OTP_MODE == "mock" and otp_code == "123456")

    if not is_master_code:
        # Find the most recent valid OTP record
        otp_record = db.query(OTPVerification).filter(
            OTPVerification.mobile_no == mobile,
            OTPVerification.verified == False,
            OTPVerification.expires_at > datetime.datetime.utcnow()
        ).order_by(OTPVerification.created_at.desc()).first()

        if not otp_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid OTP found. Please request a new OTP."
            )

        # Check attempt limit
        if otp_record.attempts >= otp_record.max_attempts:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many incorrect attempts. Please request a new OTP."
            )

        # Verify OTP hash
        if not security.verify_otp_hash(otp_code, otp_record.otp_hash):
            otp_record.attempts += 1
            db.commit()
            remaining = otp_record.max_attempts - otp_record.attempts
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid OTP. {remaining} attempt(s) remaining."
            )

        # Mark OTP as verified
        otp_record.verified = True
        db.commit()

    # ── Get or Create User ──────────────────────────────────────────────────────
    user = db.query(User).filter(User.mobile_number == mobile).first()
    is_new_user = False

    if not user:
        is_new_user = True
        user_role = payload.role if payload.role else "Driver"
        role_map = {"fleet": "Fleet Owner", "fleet_owner": "Fleet Owner", "admin": "Admin"}
        user_role = role_map.get(user_role.lower(), user_role)

        user = User(
            mobile_number=mobile,
            role=user_role,
            status="Active",
            is_active=True,
            preferred_language=payload.preferred_language or "en"
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # Update FCM token if provided
    if payload.fcm_token:
        user.fcm_token = payload.fcm_token
        db.commit()

    # ── Link OTP record to user ─────────────────────────────────────────────────
    if not is_master_code and otp_record and not otp_record.user_id:
        otp_record.user_id = user.id
        db.commit()

    # ── Create Role Profiles ────────────────────────────────────────────────────
    is_profile_complete = False
    is_kyc_verified = False
    terms_accepted = False
    onboarding_step = 0

    if user.role == "Driver":
        driver = db.query(Driver).filter(Driver.user_id == user.id).first()
        if not driver:
            drv_suffix = str(uuid.uuid4().int)[:6]
            driver_code = f"DRV-{datetime.datetime.now().year}-{drv_suffix}"
            driver = Driver(
                user_id=user.id,
                driver_code=driver_code,
                status="Active",
                verification_status="pending",
                onboarding_step=1  # Start at terms step
            )
            db.add(driver)
            db.commit()
            db.refresh(driver)

        is_profile_complete = bool(driver.full_name and driver.dob and driver.sex)
        is_kyc_verified = (driver.verification_status == "verified")
        terms_accepted = driver.terms_accepted
        onboarding_step = driver.onboarding_step

    elif user.role == "Partner":
        from app.models.partner import Partner
        partner = db.query(Partner).filter(Partner.user_id == user.id).first()
        if not partner:
            partner_code = f"PRT-{datetime.datetime.now().year}-{str(uuid.uuid4().int)[:6]}"
            partner = Partner(
                user_id=user.id,
                partner_code=partner_code,
                status="Active",
                commission_percentage=10.00
            )
            db.add(partner)
            db.commit()
        is_profile_complete = True
        is_kyc_verified = True
        terms_accepted = True
        onboarding_step = 4

    elif user.role == "Fleet Owner":
        from app.models.fleet import Fleet
        fleet = db.query(Fleet).filter(Fleet.user_id == user.id).first()
        if not fleet:
            fleet = Fleet(user_id=user.id, name="New Fleet Company", status="Active")
            db.add(fleet)
            db.commit()
        is_profile_complete = True
        is_kyc_verified = True
        terms_accepted = True
        onboarding_step = 4

    else:
        is_profile_complete = True
        is_kyc_verified = True
        terms_accepted = True
        onboarding_step = 4

    # ── Issue JWT Tokens ────────────────────────────────────────────────────────
    access_token = security.create_access_token(subject=user.id)
    refresh_token = security.create_refresh_token(subject=user.id)

    client_ip = request.client.host if request.client else None
    session_expiry = datetime.datetime.utcnow() + datetime.timedelta(days=security.REFRESH_TOKEN_EXPIRE_DAYS)

    session = UserSession(
        user_id=user.id,
        refresh_token=refresh_token,
        device_info=payload.device_info,
        device_id=payload.device_id,
        platform=payload.platform,
        ip_address=client_ip,
        expires_at=session_expiry,
        is_revoked=False
    )
    db.add(session)

    user.last_login = datetime.datetime.utcnow()
    db.commit()

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "role": user.role,
        "is_new_user": is_new_user,
        "is_profile_complete": is_profile_complete,
        "is_kyc_verified": is_kyc_verified,
        "terms_accepted": terms_accepted,
        "onboarding_step": onboarding_step,
        "preferred_language": user.preferred_language,
    }


@router.post("/refresh-token", response_model=TokenResponse)
def refresh_token(payload: TokenRefreshRequest, db: Session = Depends(get_db)):
    """Renew authentication tokens using a valid refresh token."""
    token = payload.refresh_token.strip()
    session = db.query(UserSession).filter(
        UserSession.refresh_token == token,
        UserSession.is_revoked == False,
        UserSession.expires_at > datetime.datetime.utcnow()
    ).first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session"
        )

    token_data = security.verify_token(token)
    if not token_data or token_data.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_id = uuid.UUID(token_data.get("sub"))
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or disabled")

    new_access_token = security.create_access_token(subject=user.id)
    new_refresh_token = security.create_refresh_token(subject=user.id)

    # Rotate session — revoke old, create new
    session.is_revoked = True
    session_expiry = datetime.datetime.utcnow() + datetime.timedelta(days=security.REFRESH_TOKEN_EXPIRE_DAYS)
    new_session = UserSession(
        user_id=user.id,
        refresh_token=new_refresh_token,
        device_info=session.device_info,
        device_id=session.device_id,
        platform=session.platform,
        ip_address=session.ip_address,
        expires_at=session_expiry,
        is_revoked=False
    )
    db.add(new_session)

    driver = db.query(Driver).filter(Driver.user_id == user.id).first()
    is_profile_complete = bool(driver and driver.full_name and driver.dob and driver.sex)
    is_kyc_verified = bool(driver and driver.verification_status == "verified")
    terms_accepted = bool(driver and driver.terms_accepted)
    onboarding_step = driver.onboarding_step if driver else 0

    db.commit()

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "role": user.role,
        "is_new_user": False,
        "is_profile_complete": is_profile_complete,
        "is_kyc_verified": is_kyc_verified,
        "terms_accepted": terms_accepted,
        "onboarding_step": onboarding_step,
        "preferred_language": user.preferred_language,
    }


@router.post("/logout", status_code=status.HTTP_200_OK)
def logout(payload: TokenRefreshRequest, db: Session = Depends(get_db)):
    """Revoke a specific session (logout from current device)."""
    session = db.query(UserSession).filter(
        UserSession.refresh_token == payload.refresh_token.strip()
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    session.is_revoked = True
    db.commit()
    return {"message": "Logged out successfully"}


@router.post("/logout-all", status_code=status.HTTP_200_OK)
def logout_all_devices(
    payload: TokenRefreshRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Revoke ALL active sessions for the current user (logout from all devices)."""
    db.query(UserSession).filter(
        UserSession.user_id == current_user.id,
        UserSession.is_revoked == False
    ).update({"is_revoked": True})
    db.commit()
    return {"message": "Logged out from all devices successfully"}


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Get the currently authenticated user details."""
    return current_user


@router.post("/device/fcm-token", status_code=status.HTTP_200_OK)
def register_fcm_token(
    fcm_token: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Register or update FCM device token for push notifications."""
    current_user.fcm_token = fcm_token
    db.commit()
    return {"message": "FCM token registered successfully"}
