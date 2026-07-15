import datetime
import uuid
from sqlalchemy import Column, String, Date, DateTime, ForeignKey, Enum, JSON, UUID, Boolean, Integer
from sqlalchemy.orm import relationship
from app.db.session import Base


class Driver(Base):
    __tablename__ = "drivers"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    driver_code = Column(String, nullable=True)
    full_name = Column(String, nullable=True)
    dob = Column(Date, nullable=True)
    sex = Column(String, nullable=True)
    profile_photo = Column(String, nullable=True)       # Firebase Storage URL
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_no = Column(String, nullable=True)
    emergency_contact_relation = Column(String, nullable=True)

    # Profile fields added per PRD Phase 1.4
    email = Column(String(255), nullable=True)
    preferred_language = Column(String(10), default="en", nullable=False)
    onboarding_step = Column(Integer, default=0, nullable=False)  # 0=phone,1=terms,2=profile,3=kyc,4=done
    terms_accepted = Column(Boolean, default=False, nullable=False)
    marketing_consent = Column(Boolean, default=False, nullable=False)

    status = Column(
        Enum("Active", "Inactive", "Suspended", name="driver_status_enum"),
        default="Active",
        nullable=False
    )
    verification_status = Column(
        Enum("pending", "in_progress", "pending_review", "verified", "rejected", name="driver_verification_status_enum"),
        default="pending",
        nullable=False
    )
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
        nullable=False
    )

    # Relationships
    user = relationship("User", back_populates="driver_profile")
    address = relationship("DriverAddress", back_populates="driver", uselist=False, cascade="all, delete-orphan")
    documents = relationship("DriverDocument", back_populates="driver", cascade="all, delete-orphan")
    kyc_requests = relationship("KYCRequest", back_populates="driver", cascade="all, delete-orphan")
    vehicles = relationship("Vehicle", back_populates="driver")
    subscriptions = relationship("Subscription", back_populates="driver")
    payments = relationship("Payment", back_populates="driver")
    rsa_requests = relationship("RSARequest", back_populates="driver")
    fleet_drivers = relationship("FleetDriver", back_populates="driver")


class DriverAddress(Base):
    __tablename__ = "driver_addresses"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    driver_id = Column(UUID, ForeignKey("drivers.id", ondelete="CASCADE"), unique=True, nullable=False)
    address_line1 = Column(String, nullable=False)
    address_line2 = Column(String, nullable=True)
    city = Column(String, nullable=False)
    state = Column(String, nullable=False)
    postal_code = Column(String, nullable=False)
    country = Column(String, default="India", nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
        nullable=False
    )

    # Relationships
    driver = relationship("Driver", back_populates="address")


class DriverDocument(Base):
    __tablename__ = "driver_documents"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    driver_id = Column(UUID, ForeignKey("drivers.id", ondelete="CASCADE"), nullable=False)
    document_type = Column(
        Enum(
            "driving_licence",
            "pan_card",
            "aadhaar_front",
            "aadhaar_back",
            "selfie",
            # Vehicle documents
            "rc_book",
            "insurance",
            "puc",
            "fitness_cert",
            "permit",
            name="document_type_enum"
        ),
        nullable=False
    )
    # Legacy alias kept for compatibility
    document_id = Column(String, nullable=True)
    document_no = Column(String, nullable=True)
    firebase_url = Column(String, nullable=False)       # Storage URL (local or Firebase)
    expiry_date = Column(Date, nullable=True)
    verification_status = Column(
        Enum("pending", "approved", "rejected", "expired", name="kyc_verification_status_enum"),
        default="pending",
        nullable=False
    )
    rejection_reason = Column(String, nullable=True)
    ocr_data = Column(JSON, nullable=True)             # Structured OCR extracted fields
    verification_data = Column(JSON, nullable=True)    # External API verification result
    verified_at = Column(DateTime, nullable=True)
    verified_by = Column(UUID, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
        nullable=False
    )

    # Relationships
    driver = relationship("Driver", back_populates="documents")


class KYCRequest(Base):
    __tablename__ = "kyc_requests"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    driver_id = Column(UUID, ForeignKey("drivers.id", ondelete="CASCADE"), nullable=False)
    status = Column(String, default="pending", nullable=False)
    rejection_reason = Column(String, nullable=True)
    verified_by = Column(UUID, nullable=True)
    verified_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
        nullable=False
    )

    # Relationships
    driver = relationship("Driver", back_populates="kyc_requests")
