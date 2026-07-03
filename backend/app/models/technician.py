import datetime
import uuid
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.session import Base

class Technician(Base):
    __tablename__ = "technicians"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    full_name = Column(String(200), nullable=False)
    phone_number = Column(String(20), nullable=False)
    status = Column(
        Enum("Online", "Offline", "Busy", name="technician_status_enum"),
        default="Offline",
        nullable=False
    )
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="technician_profile")
    trackings = relationship("RSATracking", back_populates="technician")
    dispatches = relationship("Dispatch", back_populates="technician")
    inventory = relationship("TechnicianInventory", back_populates="technician", cascade="all, delete-orphan")

class TechnicianInventory(Base):
    __tablename__ = "technician_inventory"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    technician_id = Column(UUID(as_uuid=True), ForeignKey("technicians.id", ondelete="CASCADE"), nullable=False)
    item_name = Column(String(200), nullable=False)
    quantity = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    technician = relationship("Technician", back_populates="inventory")
