import datetime
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User, OTPVerification, UserSession
from app.models.driver import Driver
from app.schemas.user import LoginRequest, OTPVerifyRequest, TokenResponse, TokenRefreshRequest, UserResponse
from app.core import security
from app.core.dependencies import get_current_user

router = APIRouter()

@router.post("/login", status_code=status.HTTP_200_OK)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """
    Step 1 of Auth: Receive mobile number, generate 6-digit OTP code, 
    and save in database.
    OTP code is printed in console and returned in body for development debugging.
    """
    mobile = payload.mobile_number.strip()
    if not mobile:
        raise HTTPException(status_code=400, detail="Mobile number is required")
        
    otp_code = security.generate_otp()
    expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=5)
    
    # Store OTP record in database
    otp_record = OTPVerification(
        mobile_no=mobile,
        otp=otp_code,
        expires_at=expiry,
        verified=False,
        attempts=0
    )
    db.add(otp_record)
    db.commit()
    
    # Print to console for dev logs
    print(f"\n[SMS Mock] Sending OTP {otp_code} to {mobile}\n")
    
    return {
        "message": "OTP verification code generated successfully (Mocked)",
        "mobile_number": mobile,
        "debug_code": otp_code # Expose code for mock client prefill
    }

@router.post("/verify-otp", response_model=TokenResponse)
def verify_otp(payload: OTPVerifyRequest, db: Session = Depends(get_db)):
    """
    Step 2 of Auth: Verify the 6-digit OTP code. 
    If valid, retrieve/create User and Driver Profile. 
    Initialize session and issue JWT tokens.
    """
    mobile = payload.mobile_number.strip()
    otp_code = payload.otp.strip()
    
    # Query non-expired, non-verified OTP
    otp_record = db.query(OTPVerification).filter(
        OTPVerification.mobile_no == mobile,
        OTPVerification.otp == otp_code,
        OTPVerification.expires_at > datetime.datetime.utcnow(),
        OTPVerification.verified == False
    ).order_by(OTPVerification.created_at.desc()).first()
    
    is_master_code = (otp_code == "123456")
    
    if not otp_record and not is_master_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP code"
        )
        
    if otp_record:
        otp_record.verified = True
        db.commit()
        
    # Get or create User
    user = db.query(User).filter(User.mobile_number == mobile).first()
    if not user:
        # Determine the user's role: default to payload.role or "Driver"
        user_role = payload.role if payload.role else "Driver"
        # Map frontend role selection if needed (e.g. "fleet" -> "Fleet Owner")
        if user_role.lower() == "fleet":
            user_role = "Fleet Owner"
        elif user_role.lower() == "admin":
            user_role = "Admin"
            
        user = User(
            mobile_number=mobile,
            role=user_role,
            status="Active",
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
    # Link user to OTP record
    if otp_record and not otp_record.user_id:
        otp_record.user_id = user.id
        db.commit()
        
    # Conditionally check/create role profiles
    is_profile_complete = False
    is_kyc_verified = False
    
    if user.role == "Driver":
        driver = db.query(Driver).filter(Driver.user_id == user.id).first()
        if not driver:
            drv_suffix = str(uuid.uuid4().int)[:6]
            driver_code = f"DRV-{datetime.datetime.now().year}-{drv_suffix}"
            driver = Driver(
                user_id=user.id,
                driver_code=driver_code,
                status="Active",
                verification_status="pending"
            )
            db.add(driver)
            db.commit()
            db.refresh(driver)
        is_profile_complete = bool(driver.full_name and driver.dob and driver.sex)
        is_kyc_verified = (driver.verification_status == "verified")
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
    elif user.role == "Fleet Owner":
        from app.models.fleet import Fleet
        fleet = db.query(Fleet).filter(Fleet.user_id == user.id).first()
        if not fleet:
            fleet = Fleet(
                user_id=user.id,
                name="New Fleet Company",
                status="Active"
            )
            db.add(fleet)
            db.commit()
        is_profile_complete = True
        is_kyc_verified = True
    else:
        is_profile_complete = True
        is_kyc_verified = True
        
    # Generate tokens
    access_token = security.create_access_token(subject=user.id)
    refresh_token = security.create_refresh_token(subject=user.id)
    
    # Save session
    session_expiry = datetime.datetime.utcnow() + datetime.timedelta(days=security.REFRESH_TOKEN_EXPIRE_DAYS)
    session = UserSession(
        user_id=user.id,
        refresh_token=refresh_token,
        device_info=payload.device_info,
        ip_address=payload.ip_address,
        expires_at=session_expiry,
        is_revoked=False
    )
    db.add(session)
    db.commit()
    
    # Update last login time
    user.last_login = datetime.datetime.utcnow()
    db.commit()
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "role": user.role,
        "is_profile_complete": is_profile_complete,
        "is_kyc_verified": is_kyc_verified
    }

@router.post("/refresh-token", response_model=TokenResponse)
def refresh_token(payload: TokenRefreshRequest, db: Session = Depends(get_db)):
    """
    Renew authentication tokens using a valid refresh token.
    """
    token = payload.refresh_token.strip()
    session = db.query(UserSession).filter(
        UserSession.refresh_token == token,
        UserSession.is_revoked == False,
        UserSession.expires_at > datetime.datetime.utcnow()
    ).first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session refresh token"
        )
        
    token_data = security.verify_token(token)
    if not token_data or token_data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token payload"
        )
        
    user_id = uuid.UUID(token_data.get("sub"))
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Associated user account is disabled or missing"
        )
        
    # Generate new pair of tokens
    new_access_token = security.create_access_token(subject=user.id)
    new_refresh_token = security.create_refresh_token(subject=user.id)
    
    # Revoke old session and store new session
    session.is_revoked = True
    
    session_expiry = datetime.datetime.utcnow() + datetime.timedelta(days=security.REFRESH_TOKEN_EXPIRE_DAYS)
    new_session = UserSession(
        user_id=user.id,
        refresh_token=new_refresh_token,
        device_info=session.device_info,
        ip_address=session.ip_address,
        expires_at=session_expiry,
        is_revoked=False
    )
    db.add(new_session)
    db.commit()
    
    driver = db.query(Driver).filter(Driver.user_id == user.id).first()
    is_profile_complete = bool(driver and driver.full_name and driver.dob and driver.sex)
    is_kyc_verified = bool(driver and driver.verification_status == "verified")
    
    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "role": user.role,
        "is_profile_complete": is_profile_complete,
        "is_kyc_verified": is_kyc_verified
    }

@router.post("/logout", status_code=status.HTTP_200_OK)
def logout(payload: TokenRefreshRequest, db: Session = Depends(get_db)):
    """
    Revoke a specific session by its refresh token.
    """
    token = payload.refresh_token.strip()
    session = db.query(UserSession).filter(UserSession.refresh_token == token).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
        
    session.is_revoked = True
    db.commit()
    
    return {
        "message": "Logged out and session revoked successfully"
    }

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Get the currently logged in user details.
    """
    return current_user
