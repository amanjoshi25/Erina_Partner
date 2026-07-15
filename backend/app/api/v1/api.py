from fastapi import APIRouter
from app.api.v1.endpoints import auth, driver, kyc, subscription, vehicle, rsa, consent, verification

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(driver.router, prefix="/drivers", tags=["Driver Management"])
api_router.include_router(kyc.router, prefix="/kyc", tags=["KYC & Documents"])
api_router.include_router(consent.router, prefix="/consent", tags=["Consent & Terms"])
api_router.include_router(verification.router, prefix="/verify", tags=["Identity Verification"])
api_router.include_router(subscription.router, prefix="/subscriptions", tags=["Subscriptions"])
api_router.include_router(vehicle.router, prefix="/vehicles", tags=["Vehicle Management"])
api_router.include_router(rsa.router, prefix="/rsa", tags=["RSA Incident Journey"])
