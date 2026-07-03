from fastapi import APIRouter
from app.api.v1.endpoints import auth, driver, kyc, subscription, vehicle, rsa

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(driver.router, prefix="/drivers", tags=["Driver Management"])
api_router.include_router(kyc.router, prefix="/kyc", tags=["KYC Operations"])
api_router.include_router(subscription.router, prefix="/subscriptions", tags=["Subscription Operations"])
api_router.include_router(vehicle.router, prefix="/vehicles", tags=["Vehicle Management"])
api_router.include_router(rsa.router, prefix="/rsa", tags=["RSA Incident Journey"])
