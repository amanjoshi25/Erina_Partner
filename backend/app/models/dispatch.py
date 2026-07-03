import datetime
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.session import Base

class Dispatch(Base):
    __tablename__ = "dispatches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rsa_request_id = Column(UUID(as_uuid=True), ForeignKey("rsa_requests.id", ondelete="CASCADE"), nullable=False)
    technician_id = Column(UUID(as_uuid=True), ForeignKey("technicians.id", ondelete="CASCADE"), nullable=False)
    status = Column(
        Enum("Assigned", "Accepted", "Rejected", "Completed", name="dispatch_status_enum"),
        default="Assigned",
        nullable=False
    )
    assigned_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    rsa_request = relationship("RSARequest", back_populates="dispatches")
    technician = relationship("Technician", back_populates="dispatches")
    logs = relationship("DispatchLog", back_populates="dispatch", cascade="all, delete-orphan")

class DispatchLog(Base):
    __tablename__ = "dispatch_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dispatch_id = Column(UUID(as_uuid=True), ForeignKey("dispatches.id", ondelete="CASCADE"), nullable=False)
    action = Column(String(100), nullable=False) # e.g. Dispatch Assigned, Accepted, Started Trip, Arrived, Finished
    details = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # Relationships
    dispatch = relationship("Dispatch", back_populates="logs")
