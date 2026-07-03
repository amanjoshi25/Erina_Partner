import datetime
import uuid
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Enum, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.session import Base

class RSARequest(Base):
    __tablename__ = "rsa_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    driver_id = Column(UUID(as_uuid=True), ForeignKey("drivers.id", ondelete="CASCADE"), nullable=False)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    location_name = Column(String(200), nullable=True)
    issue_type = Column(String(100), nullable=False) # e.g. Flat Tyre, Battery Jump, Towing, Mechanical Break
    description = Column(Text, nullable=True)
    status = Column(
        Enum("Requested", "Dispatched", "In_Progress", "Completed", "Canceled", name="rsa_request_status_enum"),
        default="Requested",
        nullable=False
    )
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    driver = relationship("Driver", back_populates="rsa_requests")
    vehicle = relationship("Vehicle", back_populates="rsa_requests")
    tracking = relationship("RSATracking", back_populates="rsa_request", uselist=False, cascade="all, delete-orphan")
    feedbacks = relationship("RSAFeedback", back_populates="rsa_request", cascade="all, delete-orphan")
    dispatches = relationship("Dispatch", back_populates="rsa_request", cascade="all, delete-orphan")

class RSATracking(Base):
    __tablename__ = "rsa_tracking"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rsa_request_id = Column(UUID(as_uuid=True), ForeignKey("rsa_requests.id", ondelete="CASCADE"), unique=True, nullable=False)
    technician_id = Column(UUID(as_uuid=True), ForeignKey("technicians.id", ondelete="SET NULL"), nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    estimated_arrival = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    rsa_request = relationship("RSARequest", back_populates="tracking")
    technician = relationship("Technician", back_populates="trackings")

class RSAFeedback(Base):
    __tablename__ = "rsa_feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rsa_request_id = Column(UUID(as_uuid=True), ForeignKey("rsa_requests.id", ondelete="CASCADE"), nullable=False)
    rating = Column(Integer, nullable=False) # e.g. 1 to 5
    comments = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # Relationships
    rsa_request = relationship("RSARequest", back_populates="feedbacks")
