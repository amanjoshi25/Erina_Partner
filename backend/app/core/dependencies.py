import uuid
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.security import verify_token
from app.models.user import User
from app.models.driver import Driver

security_scheme = HTTPBearer(auto_error=False)

def get_current_user(
    db: Session = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security_scheme)
) -> User:
    """
    FastAPI dependency that extracts the JWT token from the Authorization header,
    verifies it, and returns the current active User object.
    """
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    payload = verify_token(token.credentials)
    if not payload or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id_str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token subject",
        )
        
    try:
        user_id = uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token subject UUID format",
        )
        
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user",
        )
    return user


def get_current_driver(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Driver:
    """
    FastAPI dependency that ensures the authenticated user is a driver
    and has a driver profile. Returns the Driver object.
    """
    if current_user.role.lower() != "driver":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User does not have driver privileges",
        )
    
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        # Create a blank driver profile if it somehow doesn't exist yet
        driver = Driver(user_id=current_user.id, kyc_status="pending")
        db.add(driver)
        db.commit()
        db.refresh(driver)
        
    return driver
