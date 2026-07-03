import datetime
import uuid
import random
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver
from app.models.driver import Driver
from app.models.rsa import RSARequest, RSATracking, RSAFeedback
from app.models.dispatch import Dispatch, DispatchLog
from app.models.technician import Technician
from pydantic import BaseModel

router = APIRouter()

class RSACreateRequest(BaseModel):
    latitude: float
    longitude: float
    location_name: Optional[str] = "HSR Layout, Bengaluru"
    issue_type: str # e.g. Flat Tyre, Battery Jump, Towing
    description: Optional[str] = None
    vehicle_id: Optional[str] = None

class FeedbackCreateRequest(BaseModel):
    rating: int
    comments: Optional[str] = None

@router.post("/requests", status_code=status.HTTP_201_CREATED)
def raise_rsa_request(
    payload: RSACreateRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Step 1: Driver raises a new RSA (SOS) request.
    Automatically assigns a mock technician and sets up tracking ETA logs.
    """
    # Check if there is already an active request
    active = db.query(RSARequest).filter(
        RSARequest.driver_id == driver.id,
        RSARequest.status.in_(["Requested", "Dispatched", "In_Progress"])
    ).first()
    if active:
        raise HTTPException(status_code=400, detail="You already have an active roadside assistance request in progress")
        
    v_id = None
    if payload.vehicle_id:
        v_id = uuid.UUID(payload.vehicle_id)
        
    request = RSARequest(
        driver_id=driver.id,
        vehicle_id=v_id,
        latitude=payload.latitude,
        longitude=payload.longitude,
        location_name=payload.location_name,
        issue_type=payload.issue_type,
        description=payload.description,
        status="Requested"
    )
    db.add(request)
    db.commit()
    db.refresh(request)
    
    # Mock Assign a Technician (Create technician if none exists)
    tech = db.query(Technician).filter(Technician.status == "Online").first()
    if not tech:
        # Create a dummy technician
        user_uuid = uuid.uuid4()
        tech = Technician(
            user_id=user_uuid, # Mock link
            full_name=random.choice(["Amit Sharma", "Suresh Kumar", "Rahul Verma", "Vikram Singh"]),
            phone_number=f"+9198{random.randint(10000000, 99999999)}",
            status="Online",
            latitude=payload.latitude + 0.015, # 1.5km away
            longitude=payload.longitude - 0.012
        )
        db.add(tech)
        db.commit()
        db.refresh(tech)
        
    # Mark tech as busy
    tech.status = "Busy"
    
    # Create active dispatch
    dispatch = Dispatch(
        rsa_request_id=request.id,
        technician_id=tech.id,
        status="Assigned"
    )
    db.add(dispatch)
    db.commit()
    
    # Log starting action
    log = DispatchLog(
        dispatch_id=dispatch.id,
        action="Dispatch Assigned",
        details=f"Technician {tech.full_name} has been assigned to help."
    )
    db.add(log)
    
    # Setup live tracking record
    eta = datetime.datetime.utcnow() + datetime.timedelta(minutes=random.randint(12, 25))
    tracking = RSATracking(
        rsa_request_id=request.id,
        technician_id=tech.id,
        latitude=tech.latitude,
        longitude=tech.longitude,
        estimated_arrival=eta
    )
    db.add(tracking)
    
    # Progress state to Dispatched
    request.status = "Dispatched"
    db.commit()
    db.refresh(request)
    
    return {
        "message": "SOS roadside help request successfully created!",
        "request_id": str(request.id),
        "status": request.status,
        "technician": {
            "name": tech.full_name,
            "phone": tech.phone_number,
            "latitude": tech.latitude,
            "longitude": tech.longitude
        },
        "estimated_arrival": tracking.estimated_arrival
    }

@router.get("/requests/active")
def get_active_rsa_request(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Retrieve the current driver's active RSA ticket details (and mock route simulation).
    """
    request = db.query(RSARequest).filter(
        RSARequest.driver_id == driver.id,
        RSARequest.status.in_(["Requested", "Dispatched", "In_Progress"])
    ).first()
    
    if not request:
        return {"active": False}
        
    tracking = db.query(RSATracking).filter(RSATracking.rsa_request_id == request.id).first()
    dispatch = db.query(Dispatch).filter(Dispatch.rsa_request_id == request.id).first()
    tech = db.query(Technician).filter(Technician.id == tracking.technician_id).first() if tracking else None
    
    # Dynamic Simulation: move technician closer
    if tracking and tech:
        # Move tech 20% closer to request coordinates for simulation
        lat_diff = request.latitude - tracking.latitude
        lon_diff = request.longitude - tracking.longitude
        
        # Shift coords slightly
        tracking.latitude += lat_diff * 0.25
        tracking.longitude += lon_diff * 0.25
        
        # Check if arrived
        dist_sq = (tracking.latitude - request.latitude)**2 + (tracking.longitude - request.longitude)**2
        if dist_sq < 0.0001: # extremely close (approx. ~100m)
            request.status = "In_Progress"
            if dispatch and dispatch.status == "Assigned":
                dispatch.status = "Accepted"
                
        db.commit()
        db.refresh(tracking)
        db.refresh(request)
        
    return {
        "active": True,
        "id": str(request.id),
        "issue_type": request.issue_type,
        "location_name": request.location_name,
        "status": request.status,
        "created_at": request.created_at,
        "technician": {
            "name": tech.full_name if tech else "Dispatched Helper",
            "phone": tech.phone_number if tech else "+919876543210",
            "latitude": tracking.latitude if tracking else request.latitude,
            "longitude": tracking.longitude if tracking else request.longitude
        } if tech else None,
        "estimated_arrival": tracking.estimated_arrival if tracking else None
    }

@router.post("/requests/{request_id}/cancel")
def cancel_rsa_request(
    request_id: str,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Cancel an active request.
    """
    req_uuid = uuid.UUID(request_id)
    request = db.query(RSARequest).filter(
        RSARequest.id == req_uuid,
        RSARequest.driver_id == driver.id,
        RSARequest.status.in_(["Requested", "Dispatched", "In_Progress"])
    ).first()
    
    if not request:
        raise HTTPException(status_code=404, detail="Active roadside assistance request not found")
        
    request.status = "Canceled"
    
    # Restore technician status to Online
    tracking = db.query(RSATracking).filter(RSATracking.rsa_request_id == request.id).first()
    if tracking and tracking.technician_id:
        tech = db.query(Technician).filter(Technician.id == tracking.technician_id).first()
        if tech:
            tech.status = "Online"
            
    db.commit()
    return {"message": "Roadside assistance request successfully canceled"}

@router.post("/requests/{request_id}/feedback")
def submit_rsa_feedback(
    request_id: str,
    payload: FeedbackCreateRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Submit completed ticket rating and comments feedback. Marks active request as completed.
    """
    req_uuid = uuid.UUID(request_id)
    request = db.query(RSARequest).filter(
        RSARequest.id == req_uuid,
        RSARequest.driver_id == driver.id
    ).first()
    
    if not request:
        raise HTTPException(status_code=404, detail="Assistance request record not found")
        
    # Save feedback
    feedback = RSAFeedback(
        rsa_request_id=request.id,
        rating=payload.rating,
        comments=payload.comments
    )
    db.add(feedback)
    
    # Complete Request and Dispatch
    request.status = "Completed"
    
    dispatch = db.query(Dispatch).filter(Dispatch.rsa_request_id == request.id).first()
    if dispatch:
        dispatch.status = "Completed"
        dispatch.completed_at = datetime.datetime.utcnow()
        
    tracking = db.query(RSATracking).filter(RSATracking.rsa_request_id == request.id).first()
    if tracking and tracking.technician_id:
        tech = db.query(Technician).filter(Technician.id == tracking.technician_id).first()
        if tech:
            tech.status = "Online"
            
    db.commit()
    return {"message": "Thank you for your feedback! Roadside ticket marked as completed."}
