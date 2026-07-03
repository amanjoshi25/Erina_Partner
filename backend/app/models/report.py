import datetime
import uuid
from sqlalchemy import Column, String, DateTime, JSON
from sqlalchemy.dialects.postgresql import UUID
from app.db.session import Base

class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(200), nullable=False)
    report_type = Column(String(100), nullable=False) # e.g. Sales, Dispatch, Partner Commission
    parameters = Column(JSON, nullable=True) # filters and query criteria used
    file_url = Column(String(500), nullable=True) # generated PDF / Excel URL path
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
