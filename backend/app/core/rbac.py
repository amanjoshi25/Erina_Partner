from functools import wraps
from typing import Callable
from fastapi import Depends, HTTPException, status
from app.core.dependencies import get_current_user
from app.models.user import User


def require_role(*allowed_roles: str) -> Callable:
    """
    FastAPI dependency factory for Role-Based Access Control.
    
    Usage:
        @router.get("/admin-only")
        def admin_endpoint(user = Depends(require_role("Admin", "Operations"))):
            ...
    """
    def dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required role(s): {', '.join(allowed_roles)}. "
                       f"Your role: {current_user.role}"
            )
        return current_user
    return dependency


def require_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Ensure the user account is active and not blocked."""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been deactivated. Please contact support."
        )
    if current_user.status in ("Blocked", "Suspended", "Deleted"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Your account is {current_user.status.lower()}. Please contact support."
        )
    return current_user


# ─── Convenience role aliases ──────────────────────────────────────────────────
def require_admin(current_user: User = Depends(get_current_user)) -> User:
    return require_role("Admin")(current_user)

def require_driver(current_user: User = Depends(get_current_user)) -> User:
    return require_role("Driver")(current_user)

def require_operations(current_user: User = Depends(get_current_user)) -> User:
    return require_role("Admin", "Operations")(current_user)
