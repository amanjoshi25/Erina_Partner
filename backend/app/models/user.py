import datetime
import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, Enum, UUID
from sqlalchemy.orm import relationship
from app.db.session import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    mobile_number = Column(String(15), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    role = Column(
        Enum("Driver", "Technician", "Partner", "Fleet Owner", "Operations", "Admin", name="user_role_enum"),
        nullable=False
    )
    status = Column(
        Enum("Active", "Pending", "Blocked", "Suspended", "Deleted", name="user_status_enum"),
        default="Active",
        nullable=False
    )
    # FCM token for push notifications
    fcm_token = Column(String(512), nullable=True)
    # Preferred language (ISO code: en, hi, ta, te, kn, mr)
    preferred_language = Column(String(10), default="en", nullable=False)

    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
        nullable=False
    )
    created_by = Column(UUID, nullable=True)
    updated_by = Column(UUID, nullable=True)
    deleted_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    sessions = relationship("UserSession", back_populates="user", cascade="all, delete-orphan")
    consents = relationship("UserConsent", back_populates="user", cascade="all, delete-orphan")
    driver_profile = relationship("Driver", back_populates="user", uselist=False, cascade="all, delete-orphan")
    technician_profile = relationship("Technician", back_populates="user", uselist=False, cascade="all, delete-orphan")
    partner_profile = relationship("Partner", back_populates="user", uselist=False, cascade="all, delete-orphan")
    fleet_profile = relationship("Fleet", back_populates="user", uselist=False, cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")


class OTPVerification(Base):
    __tablename__ = "otp_verifications"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    mobile_no = Column(String, nullable=False)
    otp_hash = Column(String, nullable=False)       # bcrypt hash — never store plain text
    otp_channel = Column(String(20), default="sms", nullable=False)  # sms / whatsapp
    expires_at = Column(DateTime, nullable=False)
    verified = Column(Boolean, default=False, nullable=False)
    attempts = Column(Integer, default=0, nullable=False)
    max_attempts = Column(Integer, default=5, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)


class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    refresh_token = Column(String, unique=True, index=True, nullable=False)
    device_info = Column(String, nullable=True)
    device_id = Column(String(256), nullable=True)   # Unique device fingerprint
    platform = Column(String(20), nullable=True)     # android / ios / web
    ip_address = Column(String, nullable=True)
    expires_at = Column(DateTime, nullable=False)
    is_revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="sessions")


class UserConsent(Base):
    """Records user acceptance of Terms, Privacy Policy, and Marketing consent."""
    __tablename__ = "user_consents"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    terms_version = Column(String(20), nullable=False)
    privacy_version = Column(String(20), nullable=False)
    terms_accepted = Column(Boolean, default=False, nullable=False)
    privacy_accepted = Column(Boolean, default=False, nullable=False)
    marketing_consent = Column(Boolean, default=False, nullable=False)
    accepted_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    ip_address = Column(String, nullable=True)
    device_info = Column(String, nullable=True)

    # Relationships
    user = relationship("User", back_populates="consents")
