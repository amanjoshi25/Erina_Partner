from fastapi import APIRouter
from app.api.v1.endpoints import auth, driver, kyc

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(driver.router, prefix="/drivers", tags=["Driver Management"])
api_router.include_router(kyc.router, prefix="/kyc", tags=["KYC Operations"])
