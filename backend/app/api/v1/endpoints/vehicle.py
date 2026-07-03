import os
import uuid
import shutil
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver
from app.models.driver import Driver
from app.models.vehicle import Vehicle
from pydantic import BaseModel, Field

router = APIRouter()

UPLOAD_DIR = os.path.join(os.getcwd(), "static", "uploads")

class VehicleBase(BaseModel):
    registration_number: str
    make: str
    model: str
    year: int
    color: str

class VehicleResponse(BaseModel):
    id: str
    registration_number: str
    make: str
    model: str
    year: int
    color: str

    class Config:
        from_attributes = True

@router.get("/", response_model=List[VehicleResponse])
def get_vehicles(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Get all vehicles assigned to the current driver.
    """
    return db.query(Vehicle).filter(Vehicle.driver_id == driver.id).all()

@router.post("/", response_model=VehicleResponse)
def add_vehicle(
    payload: VehicleBase,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Add a new vehicle for the driver.
    """
    # Check duplicate registration number
    dup = db.query(Vehicle).filter(Vehicle.registration_number == payload.registration_number.strip().upper()).first()
    if dup:
        raise HTTPException(status_code=400, detail="Vehicle with this registration number is already registered")
        
    vehicle = Vehicle(
        driver_id=driver.id,
        registration_number=payload.registration_number.strip().upper(),
        make=payload.make.strip(),
        model=payload.model.strip(),
        year=payload.year,
        color=payload.color.strip()
    )
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle

@router.get("/active", response_model=Optional[VehicleResponse])
def get_active_vehicle(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Get the driver's active vehicle (defaulting to the first registered one).
    """
    return db.query(Vehicle).filter(Vehicle.driver_id == driver.id).first()

@router.post("/{vehicle_id}/upload-document")
def upload_vehicle_document(
    vehicle_id: str,
    document_type: str = Form(..., description="rc_card, insurance, puc, fitness_certificate"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Upload a vehicle document (RC, Insurance, PUC, etc.) and save file path. Runs mock OCR analysis on RC.
    """
    vehicle_uuid = uuid.UUID(vehicle_id)
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_uuid, Vehicle.driver_id == driver.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found or not owned by driver")
        
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    file_ext = os.path.splitext(file.filename)[1]
    if not file_ext:
        file_ext = ".jpg"
    unique_filename = f"veh_{uuid.uuid4()}{file_ext}"
    dest_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    try:
        with open(dest_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save document: {str(e)}")
        
    doc_url = f"/static/uploads/{unique_filename}"
    
    # Return mock status update
    return {
        "message": f"Vehicle document '{document_type}' uploaded successfully!",
        "vehicle_id": vehicle_id,
        "document_type": document_type,
        "firebase_url": doc_url,
        "verification_status": "pending",
        "ocr_extracted_data": {
            "registration_number": vehicle.registration_number,
            "owner_name": driver.full_name or "Ramesh Kumar",
            "ocr_confidence": 0.98
        }
    }
