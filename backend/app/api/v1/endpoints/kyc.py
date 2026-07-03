import os
import uuid
import shutil
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver
from app.models.driver import Driver, DriverDocument, KYCRequest
from app.schemas.driver import (
    DriverDocumentResponse, KYCStatusResponse, AdminKYCVerifyRequest
)
from app.services.ocr import mock_ocr_extract

router = APIRouter()

UPLOAD_DIR = os.path.join(os.getcwd(), "static", "uploads")

def _handle_document_upload(
    document_type: str,
    document_no: Optional[str],
    expiry_date: Optional[datetime.date],
    file: UploadFile,
    db: Session,
    driver: Driver
) -> DriverDocument:
    valid_types = ["driving_licence", "pan_card", "selfie"]
    if document_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid document type. Must be one of: {', '.join(valid_types)}"
        )
        
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    
    # Save the file with a unique name
    file_ext = os.path.splitext(file.filename)[1]
    if not file_ext:
        file_ext = ".jpg"
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    dest_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    try:
        with open(dest_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")
        
    # Generate static media URL (maps to firebase_url field)
    firebase_url = f"/static/uploads/{unique_filename}"
    
    # Extract OCR data
    ocr_result = mock_ocr_extract(document_type, unique_filename)
    
    # If document_no is not provided, use OCR extracted document number
    final_doc_no = document_no if document_no else ocr_result.get("document_number")
    
    # Check if document already exists
    existing_doc = db.query(DriverDocument).filter(
        DriverDocument.driver_id == driver.id,
        DriverDocument.document_id == document_type
    ).first()
    
    if existing_doc:
        # Clean up old file locally if possible
        old_filename = os.path.basename(existing_doc.firebase_url)
        old_path = os.path.join(UPLOAD_DIR, old_filename)
        if os.path.exists(old_path) and old_filename != unique_filename:
            try:
                os.remove(old_path)
            except Exception:
                pass
                
        existing_doc.firebase_url = firebase_url
        existing_doc.document_no = final_doc_no
        existing_doc.ocr_response = ocr_result
        existing_doc.verification_status = "pending"  # Reset verification status
        if expiry_date:
            existing_doc.expiry_date = expiry_date
        elif ocr_result.get("valid_till"):
            try:
                existing_doc.expiry_date = datetime.datetime.strptime(ocr_result["valid_till"], "%Y-%m-%d").date()
            except ValueError:
                pass
        doc_record = existing_doc
    else:
        # Resolve expiry
        final_expiry = expiry_date
        if not final_expiry and ocr_result.get("valid_till"):
            try:
                final_expiry = datetime.datetime.strptime(ocr_result["valid_till"], "%Y-%m-%d").date()
            except ValueError:
                pass
                
        doc_record = DriverDocument(
            driver_id=driver.id,
            document_id=document_type,
            document_no=final_doc_no,
            firebase_url=firebase_url,
            expiry_date=final_expiry,
            verification_status="pending",
            ocr_response=ocr_result
        )
        db.add(doc_record)
        
    db.commit()
    db.refresh(doc_record)
    
    # Recalculate driver state: if all 3 uploaded, transition to 'pending_review'
    docs_uploaded = db.query(DriverDocument).filter(DriverDocument.driver_id == driver.id).all()
    uploaded_types = {d.document_id for d in docs_uploaded}
    
    if len(uploaded_types) == 3:
        driver.verification_status = "pending_review"
        db.commit()
        
    return doc_record

@router.post("/upload", response_model=DriverDocumentResponse)
def upload_kyc_document(
    document_type: str = Form(..., description="driving_licence, pan_card, selfie"),
    document_no: Optional[str] = Form(None),
    expiry_date: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Upload a new verification document (DL, PAN, or selfie).
    Save the file, run the mock OCR service, and update/create the document logs.
    """
    parsed_expiry = None
    if expiry_date:
        try:
            parsed_expiry = datetime.datetime.strptime(expiry_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
            
    return _handle_document_upload(
        document_type=document_type,
        document_no=document_no,
        expiry_date=parsed_expiry,
        file=file,
        db=db,
        driver=driver
    )

@router.post("/resubmit", response_model=DriverDocumentResponse)
def resubmit_kyc_document(
    document_type: str = Form(..., description="driving_licence, pan_card, selfie"),
    document_no: Optional[str] = Form(None),
    expiry_date: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Resubmit a rejected document. Re-runs OCR and updates status back to pending.
    """
    parsed_expiry = None
    if expiry_date:
        try:
            parsed_expiry = datetime.datetime.strptime(expiry_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
            
    return _handle_document_upload(
        document_type=document_type,
        document_no=document_no,
        expiry_date=parsed_expiry,
        file=file,
        db=db,
        driver=driver
    )

@router.get("/status", response_model=KYCStatusResponse)
def get_kyc_status(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Query the overall Driver verification status and details for each uploaded document.
    """
    docs = db.query(DriverDocument).filter(DriverDocument.driver_id == driver.id).all()
    return {
        "kyc_status": driver.verification_status,
        "documents": docs
    }

@router.post("/admin/verify", status_code=status.HTTP_200_OK)
def admin_verify_document(
    payload: AdminKYCVerifyRequest,
    db: Session = Depends(get_db)
):
    """
    Admin verification endpoint (manual verification bypass). Approve or reject a document.
    Updates the overall Driver verification status.
    """
    doc = db.query(DriverDocument).filter(DriverDocument.id == payload.document_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
        
    new_status = payload.status.lower().strip()
    if new_status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Status must be 'approved' or 'rejected'")
        
    doc.verification_status = new_status
    db.commit()
    
    # Recalculate overall Driver verification status
    driver = db.query(Driver).filter(Driver.id == doc.driver_id).first()
    if driver:
        all_docs = db.query(DriverDocument).filter(DriverDocument.driver_id == driver.id).all()
        doc_statuses = {d.document_id: d.verification_status for d in all_docs}
        
        required_types = ["driving_licence", "pan_card", "selfie"]
        all_present = all(t in doc_statuses for t in required_types)
        
        if any(status == "rejected" for status in doc_statuses.values()):
            driver.verification_status = "rejected"
        elif all_present and all(status == "approved" for status in doc_statuses.values()):
            driver.verification_status = "verified"
        else:
            driver.verification_status = "pending_review"
            
        # Log KYCRequest audit entry
        kyc_req = KYCRequest(
            driver_id=driver.id,
            status=driver.verification_status,
            rejection_reason=payload.rejection_reason if driver.verification_status == "rejected" else None,
            verified_at=datetime.datetime.utcnow()
        )
        db.add(kyc_req)
        db.commit()
        
    return {
        "message": f"Document status updated to {new_status}",
        "document_id": doc.id,
        "driver_verification_status": driver.verification_status if driver else "unknown"
    }
