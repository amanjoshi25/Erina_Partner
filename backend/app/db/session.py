from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import OperationalError
from app.core.config import settings

# Attempt to create the engine using PostgreSQL configuration
try:
    print("Attempting to connect to PostgreSQL database...")
    engine = create_engine(
        settings.SQLALCHEMY_DATABASE_URI,
        pool_pre_ping=True,
        echo=True
    )
    # Test connection immediately to trigger any connection/auth errors
    with engine.connect() as conn:
        pass
    print("Successfully connected to PostgreSQL.")
except OperationalError as e:
    print(f"\n[DATABASE WARNING] Could not connect to PostgreSQL: {e}")
    print("Falling back to local SQLite database (erina_db.sqlite) for development convenience.\n")
    
    # SQLite fallback
    engine = create_engine(
        "sqlite:///./erina_db.sqlite",
        connect_args={"check_same_thread": False},
        echo=True
    )

# Create sessionmaker
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Declarative base class for models
Base = declarative_base()

# DB Dependency generator
def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
