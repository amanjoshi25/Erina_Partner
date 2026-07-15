import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.db.session import engine, Base
from app.api.v1.api import api_router

# Import all SQLAlchemy models to register them on Base before create_all
from app.models.user import User, OTPVerification, UserSession, UserConsent
from app.models.driver import Driver, DriverAddress, DriverDocument, KYCRequest
from app.models.vehicle import Vehicle
from app.models.subscription import SubscriptionPlan, Subscription
from app.models.payment import Payment, Invoice
from app.models.rsa import RSARequest, RSATracking, RSAFeedback
from app.models.dispatch import Dispatch, DispatchLog
from app.models.technician import Technician, TechnicianInventory
from app.models.partner import Partner, PartnerCustomer
from app.models.fleet import Fleet, FleetVehicle, FleetDriver
from app.models.notification import Notification
from app.models.report import Report
from app.models.audit import AuditLog
from app.models.setting import Setting

# Automatically create tables in local development
try:
    print("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables initialized successfully.")
except Exception as e:
    print(f"Error initializing database: {e}")

# Ensure local upload directories exist
os.makedirs("static/uploads", exist_ok=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    description="Backend API for Erina Assistance Driver & Vehicle Subscription Platform"
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static folder for uploading and serving driver KYC documents
app.mount("/static", StaticFiles(directory="static"), name="static")

# Include the API router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "docs_url": "/docs"
    }

@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME
    }
