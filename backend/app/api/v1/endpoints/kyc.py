import os
import uuid
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from PIL import Image
import io

from app.db.session import get_db
from app.core.dependencies import get_current_driver, get_current_user
from app.core.rbac import require_role
from app.models.driver import Driver, DriverDocument, KYCRequest
from app.models.user import User
from app.services.storage import upload_document, delete_document, get_document_url
from app.services.ocr import extract_document_data
from app.services import notifications as fcm_service

router = APIRouter()

ALLOWED_DOC_TYPES = [
    "driving_licence", "pan_card", "aadhaar_front", "aadhaar_back", "selfie",
    "rc_book", "insurance", "puc", "fitness_cert", "permit"
]
IDENTITY_DOCS = {"driving_licence", "pan_card", "aadhaar_front", "selfie"}
MAX_FILE_SIZE_MB = 10


def _validate_image(file_bytes: bytes) -> None:
    """Validate that uploaded file is a valid image and within size limit."""
    size_mb = len(file_bytes) / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        raise HTTPException(
            status_code=400,
            detail=f"File size {size_mb:.1f}MB exceeds maximum {MAX_FILE_SIZE_MB}MB"
        )
    try:
        img = Image.open(io.BytesIO(file_bytes))
        img.verify()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file. Please upload a JPEG or PNG image.")


async def _handle_document_upload(
    document_type: str,
    document_no: Optional[str],
    expiry_date: Optional[datetime.date],
    file: UploadFile,
    db: Session,
    driver: Driver
) -> DriverDocument:
    """
    Core document upload handler:
    1. Validate file (image check, size limit)
    2. Run OCR to extract document data
    3. Upload to storage (local or Firebase)
    4. Create/update DriverDocument record
    5. Recalculate driver verification status
    """
    if document_type not in ALLOWED_DOC_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid document_type. Must be one of: {', '.join(ALLOWED_DOC_TYPES)}"
        )

    file_bytes = await file.read()
    _validate_image(file_bytes)

    # Run OCR
    ocr_data = await extract_document_data(document_type, file_bytes)
    final_doc_no = document_no or ocr_data.get("document_number")

    # Upload to storage
    file_url = await upload_document(
        file_bytes=file_bytes,
        original_filename=file.filename or f"{document_type}.jpg",
        folder=f"kyc/{driver.id}",
        content_type=file.content_type or "image/jpeg"
    )

    # Resolve expiry from OCR if not provided
    final_expiry = expiry_date
    if not final_expiry and ocr_data.get("valid_till"):
        try:
            final_expiry = datetime.datetime.strptime(ocr_data["valid_till"], "%Y-%m-%d").date()
        except ValueError:
            pass

    # Check if document already exists
    existing_doc = db.query(DriverDocument).filter(
        DriverDocument.driver_id == driver.id,
        DriverDocument.document_type == document_type
    ).first()

    if existing_doc:
        # Delete old file from storage
        if existing_doc.firebase_url and existing_doc.firebase_url != file_url:
            await delete_document(existing_doc.firebase_url)

        existing_doc.firebase_url = file_url
        existing_doc.document_no = final_doc_no
        existing_doc.ocr_data = ocr_data
        existing_doc.verification_status = "pending"
        existing_doc.rejection_reason = None
        existing_doc.document_id = document_type  # Legacy compat
        if final_expiry:
            existing_doc.expiry_date = final_expiry
        doc_record = existing_doc
    else:
        doc_record = DriverDocument(
            driver_id=driver.id,
            document_type=document_type,
            document_id=document_type,  # Legacy compat
            document_no=final_doc_no,
            firebase_url=file_url,
            expiry_date=final_expiry,
            verification_status="pending",
            ocr_data=ocr_data
        )
        db.add(doc_record)

    db.commit()
    db.refresh(doc_record)

    # Recalculate overall KYC status
    _recalculate_kyc_status(driver, db)

    return doc_record


def _recalculate_kyc_status(driver: Driver, db: Session) -> None:
    """Recalculate driver verification status based on uploaded identity documents."""
    identity_docs = db.query(DriverDocument).filter(
        DriverDocument.driver_id == driver.id,
        DriverDocument.document_type.in_(list(IDENTITY_DOCS))
    ).all()

    uploaded_types = {d.document_type for d in identity_docs}
    statuses = {d.document_type: d.verification_status for d in identity_docs}

    if any(s == "rejected" for s in statuses.values()):
        new_status = "rejected"
    elif IDENTITY_DOCS.issubset(uploaded_types) and all(s == "approved" for s in statuses.values()):
        new_status = "verified"
    elif uploaded_types:
        new_status = "pending_review" if len(uploaded_types) >= 3 else "in_progress"
    else:
        new_status = "pending"

    if driver.verification_status != new_status:
        driver.verification_status = new_status
        db.commit()


@router.post("/upload", status_code=status.HTTP_200_OK)
async def upload_kyc_document(
    document_type: str = Form(..., description=f"One of: {', '.join(ALLOWED_DOC_TYPES)}"),
    document_no: Optional[str] = Form(None),
    expiry_date: Optional[str] = Form(None, description="Format: YYYY-MM-DD"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Upload a KYC or vehicle document. Runs OCR and uploads to storage."""
    parsed_expiry = None
    if expiry_date:
        try:
            parsed_expiry = datetime.datetime.strptime(expiry_date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    doc = await _handle_document_upload(
        document_type=document_type,
        document_no=document_no,
        expiry_date=parsed_expiry,
        file=file,
        db=db,
        driver=driver
    )

    return {
        "id": str(doc.id),
        "document_type": doc.document_type,
        "document_no": doc.document_no,
        "verification_status": doc.verification_status,
        "expiry_date": doc.expiry_date.isoformat() if doc.expiry_date else None,
        "file_url": doc.firebase_url,
        "ocr_data": doc.ocr_data,
        "uploaded_at": doc.created_at.isoformat()
    }


@router.get("/documents", status_code=status.HTTP_200_OK)
async def get_document_wallet(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Get the driver's complete document wallet with status and metadata.
    Returns all uploaded documents plus which required docs are missing.
    """
    docs = db.query(DriverDocument).filter(
        DriverDocument.driver_id == driver.id
    ).order_by(DriverDocument.created_at.asc()).all()

    required_identity = ["driving_licence", "pan_card", "aadhaar_front", "selfie"]
    uploaded_types = {d.document_type for d in docs}

    doc_list = []
    for doc in docs:
        doc_list.append({
            "id": str(doc.id),
            "document_type": doc.document_type,
            "document_no": doc.document_no,
            "verification_status": doc.verification_status,
            "rejection_reason": doc.rejection_reason,
            "expiry_date": doc.expiry_date.isoformat() if doc.expiry_date else None,
            "is_expired": (
                doc.expiry_date and doc.expiry_date < datetime.date.today()
            ),
            "uploaded_at": doc.created_at.isoformat(),
            "ocr_data": doc.ocr_data,
            "verification_data": doc.verification_data
        })

    return {
        "kyc_status": driver.verification_status,
        "onboarding_step": driver.onboarding_step,
        "documents": doc_list,
        "required_identity_docs": required_identity,
        "missing_docs": [d for d in required_identity if d not in uploaded_types],
        "completion_percentage": int(len([d for d in required_identity if d in uploaded_types]) / len(required_identity) * 100)
    }


@router.get("/documents/{document_type}/download-url", status_code=status.HTTP_200_OK)
async def get_document_download_url(
    document_type: str,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Get a time-limited signed URL to view/download a specific document."""
    doc = db.query(DriverDocument).filter(
        DriverDocument.driver_id == driver.id,
        DriverDocument.document_type == document_type
    ).first()

    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_type}' not found")

    signed_url = await get_document_url(doc.firebase_url, expiry_hours=1)
    return {"document_type": document_type, "download_url": signed_url, "expires_in_seconds": 3600}


@router.get("/status", status_code=status.HTTP_200_OK)
def get_kyc_status(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """Get overall KYC status for the driver."""
    docs = db.query(DriverDocument).filter(DriverDocument.driver_id == driver.id).all()
    return {
        "kyc_status": driver.verification_status,
        "onboarding_step": driver.onboarding_step,
        "documents": [
            {
                "document_type": d.document_type,
                "verification_status": d.verification_status,
                "rejection_reason": d.rejection_reason,
                "expiry_date": d.expiry_date.isoformat() if d.expiry_date else None
            }
            for d in docs
        ]
    }


@router.post("/admin/verify", status_code=status.HTTP_200_OK)
async def admin_verify_document(
    document_id: str,
    new_status: str,
    rejection_reason: Optional[str] = None,
    db: Session = Depends(get_db),
    admin_user: User = Depends(require_role("Admin", "Operations"))
):
    """
    Admin: Approve or reject a KYC document. RBAC protected (Admin/Operations only).
    Sends FCM notification to driver on status change.
    """
    try:
        doc_uuid = uuid.UUID(document_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid document ID format")

    doc = db.query(DriverDocument).filter(DriverDocument.id == doc_uuid).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    if new_status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="Status must be 'approved' or 'rejected'")

    doc.verification_status = new_status
    doc.verified_at = datetime.datetime.utcnow()
    doc.verified_by = admin_user.id
    if new_status == "rejected":
        doc.rejection_reason = rejection_reason

    db.commit()

    driver = db.query(Driver).filter(Driver.id == doc.driver_id).first()
    if driver:
        _recalculate_kyc_status(driver, db)

        # Log KYC audit entry
        kyc_req = KYCRequest(
            driver_id=driver.id,
            status=driver.verification_status,
            rejection_reason=rejection_reason if new_status == "rejected" else None,
            verified_by=admin_user.id,
            verified_at=datetime.datetime.utcnow()
        )
        db.add(kyc_req)
        db.commit()

        # Send FCM notification to driver
        if driver.user and driver.user.fcm_token:
            await fcm_service.notify_kyc_status_change(
                fcm_token=driver.user.fcm_token,
                new_status=driver.verification_status,
                rejection_reason=rejection_reason
            )

    return {
        "message": f"Document {new_status}",
        "document_id": document_id,
        "driver_kyc_status": driver.verification_status if driver else "unknown"
    }
