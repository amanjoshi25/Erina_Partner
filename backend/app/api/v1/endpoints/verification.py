from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver
from app.models.driver import Driver
from app.services.verification import verify_driving_licence, verify_rc, verify_pan

router = APIRouter()


class DLVerifyRequest(BaseModel):
    dl_number: str
    dob: str  # YYYY-MM-DD


class RCVerifyRequest(BaseModel):
    registration_number: str


class PANVerifyRequest(BaseModel):
    pan_number: str
    name: str
    dob: str  # YYYY-MM-DD


@router.post("/dl", status_code=status.HTTP_200_OK)
async def verify_dl(
    payload: DLVerifyRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Verify a Driving Licence number against government records (Surepass or mock).
    Stores the verification result on the matching document record.
    """
    result = await verify_driving_licence(payload.dl_number, payload.dob)

    # If valid, store verification data on the DL document record
    if result.get("verification_status") == "valid":
        from app.models.driver import DriverDocument
        doc = db.query(DriverDocument).filter(
            DriverDocument.driver_id == driver.id,
            DriverDocument.document_type == "driving_licence"
        ).first()
        if doc:
            doc.verification_data = result
            doc.document_no = payload.dl_number
            db.commit()

    return {
        "dl_number": payload.dl_number,
        "verification_result": result,
        "message": "DL verified successfully" if result.get("verification_status") == "valid" else "DL verification failed"
    }


@router.post("/rc", status_code=status.HTTP_200_OK)
async def verify_rc_number(
    payload: RCVerifyRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Verify a Vehicle Registration Certificate (RC) number.
    Stores verification result on the matching rc_book document.
    """
    result = await verify_rc(payload.registration_number)

    if result.get("verification_status") == "valid":
        from app.models.driver import DriverDocument
        doc = db.query(DriverDocument).filter(
            DriverDocument.driver_id == driver.id,
            DriverDocument.document_type == "rc_book"
        ).first()
        if doc:
            doc.verification_data = result
            doc.document_no = payload.registration_number
            db.commit()

    return {
        "registration_number": payload.registration_number,
        "verification_result": result,
        "message": "RC verified successfully" if result.get("verification_status") == "valid" else "RC verification failed"
    }


@router.post("/pan", status_code=status.HTTP_200_OK)
async def verify_pan_number(
    payload: PANVerifyRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Verify a PAN card number against government records.
    """
    result = await verify_pan(payload.pan_number, payload.name, payload.dob)

    if result.get("verification_status") == "valid":
        from app.models.driver import DriverDocument
        doc = db.query(DriverDocument).filter(
            DriverDocument.driver_id == driver.id,
            DriverDocument.document_type == "pan_card"
        ).first()
        if doc:
            doc.verification_data = result
            doc.document_no = payload.pan_number
            db.commit()

    return {
        "pan_number": payload.pan_number,
        "verification_result": result,
        "message": "PAN verified successfully" if result.get("verification_status") == "valid" else "PAN verification failed"
    }
