from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver
from app.models.driver import Driver, DriverAddress
from app.schemas.driver import DriverResponse, DriverUpdate, DriverAddressBase, DriverAddressResponse

router = APIRouter()

@router.get("/profile", response_model=DriverResponse)
def get_driver_profile(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Get the authenticated driver's profile, including address if it exists.
    """
    return driver

@router.put("/profile", response_model=DriverResponse)
def update_driver_profile(
    payload: DriverUpdate,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Update driver personal details: full_name, dob, sex, emergency_contact_no.
    If verification_status is 'pending', transition to 'in_progress'.
    """
    driver.full_name = payload.full_name
    driver.dob = payload.dob
    driver.sex = payload.sex
    driver.emergency_contact_no = payload.emergency_contact_no
    
    if driver.verification_status == "pending":
        driver.verification_status = "in_progress"
        
    db.commit()
    db.refresh(driver)
    return driver

@router.get("/address", response_model=DriverAddressResponse)
def get_driver_address(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Get the address details for the current driver.
    """
    if not driver.address:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Address details not found for this driver"
        )
    return driver.address

@router.post("/address", response_model=DriverAddressResponse)
def create_or_update_driver_address(
    payload: DriverAddressBase,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Create or update driver address details.
    """
    if driver.address:
        # Update existing
        driver.address.address_line1 = payload.address_line1
        driver.address.address_line2 = payload.address_line2
        driver.address.city = payload.city
        driver.address.state = payload.state
        driver.address.postal_code = payload.postal_code
        driver.address.country = payload.country
        addr = driver.address
    else:
        # Create new
        addr = DriverAddress(
            driver_id=driver.id,
            address_line1=payload.address_line1,
            address_line2=payload.address_line2,
            city=payload.city,
            state=payload.state,
            postal_code=payload.postal_code,
            country=payload.country
        )
        db.add(addr)
        
    db.commit()
    db.refresh(addr)
    return addr
