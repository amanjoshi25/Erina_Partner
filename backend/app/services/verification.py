"""
RC/DL/PAN Verification Service — supports mock and real (Surepass) modes.

Surepass API docs: https://docs.surepass.io/
Supported verifications:
  - Driving Licence (DL)
  - Vehicle RC (Registration Certificate)
  - PAN Card

To switch to real verification:
  1. Set VERIFICATION_MODE=real in .env
  2. Set SUREPASS_API_KEY=your-token in .env
"""
import logging
import httpx
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)


async def verify_driving_licence(dl_number: str, dob: str) -> dict:
    """
    Verify a Driving Licence number against government records.

    Args:
        dl_number: DL number e.g. "DL-1420110012345"
        dob: Date of birth in YYYY-MM-DD format

    Returns:
        dict with verification_status, name, dob, validity, vehicle_classes
    """
    if settings.VERIFICATION_MODE == "real":
        return await _surepass_verify_dl(dl_number, dob)
    return _mock_verify_dl(dl_number)


async def verify_rc(registration_number: str) -> dict:
    """
    Verify a Vehicle Registration Certificate (RC) number.

    Args:
        registration_number: Vehicle reg number e.g. "KA01AB1234"

    Returns:
        dict with owner_name, vehicle details, insurance validity, fitness date
    """
    if settings.VERIFICATION_MODE == "real":
        return await _surepass_verify_rc(registration_number)
    return _mock_verify_rc(registration_number)


async def verify_pan(pan_number: str, name: str, dob: str) -> dict:
    """
    Verify a PAN card number.

    Returns:
        dict with verification_status, name match result
    """
    if settings.VERIFICATION_MODE == "real":
        return await _surepass_verify_pan(pan_number, name, dob)
    return _mock_verify_pan(pan_number)


# ─── Mock Responses ────────────────────────────────────────────────────────────

def _mock_verify_dl(dl_number: str) -> dict:
    logger.info(f"[VERIFY MOCK] DL verification for {dl_number}")
    return {
        "verification_status": "valid",
        "dl_number": dl_number,
        "name": "MOCK DRIVER NAME",
        "dob": "1992-05-15",
        "issue_date": "2010-05-15",
        "expiry_date": "2030-05-14",
        "vehicle_classes": ["LMV", "MCWG"],
        "blood_group": "O+",
        "transport": False,
        "hazardous_valid_till": None,
        "hill_valid_till": None,
        "issuing_rto": "Bengaluru Central RTO",
        "source": "mock"
    }


def _mock_verify_rc(registration_number: str) -> dict:
    logger.info(f"[VERIFY MOCK] RC verification for {registration_number}")
    return {
        "verification_status": "valid",
        "registration_number": registration_number,
        "owner_name": "MOCK OWNER NAME",
        "father_name": "MOCK FATHER NAME",
        "mobile_number": None,
        "vehicle_class": "LMV",
        "maker_model": "MARUTI SUZUKI SWIFT",
        "maker_description": "MARUTI SUZUKI",
        "body_type": "Saloon",
        "fuel_type": "Petrol",
        "color": "White",
        "norms_type": "BS-VI",
        "seating_capacity": 5,
        "chassis_number": "MA3FJEB1S00123456",
        "engine_number": "K12BN1234567",
        "cubic_capacity": 1197,
        "registration_date": "2020-01-15",
        "registration_upto": "2035-01-14",
        "fitness_upto": "2035-01-14",
        "insurance_company": "Bajaj Allianz General Insurance",
        "insurance_policy_number": "OD-12345678901234",
        "insurance_upto": "2026-01-14",
        "permit_type": None,
        "permit_validity_from": None,
        "permit_validity_upto": None,
        "puc_number": "KA012025PUC12345",
        "puc_upto": "2025-12-31",
        "financer": None,
        "source": "mock"
    }


def _mock_verify_pan(pan_number: str) -> dict:
    logger.info(f"[VERIFY MOCK] PAN verification for {pan_number}")
    return {
        "verification_status": "valid",
        "pan_number": pan_number,
        "name": "MOCK DRIVER NAME",
        "category": "P",  # P = Person
        "last_updated": "2024-01-01",
        "source": "mock"
    }


# ─── Real Surepass API ─────────────────────────────────────────────────────────

def _surepass_headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.SUREPASS_API_KEY}",
        "Content-Type": "application/json"
    }


async def _surepass_verify_dl(dl_number: str, dob: str) -> dict:
    """Call Surepass DL verification endpoint."""
    url = f"{settings.SUREPASS_BASE_URL}/driving-license"
    payload = {"id_number": dl_number, "dob": dob}
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload, headers=_surepass_headers())
            data = resp.json()
        if resp.status_code == 200 and data.get("success"):
            d = data.get("data", {})
            return {
                "verification_status": "valid" if d.get("status") == "VALID" else "invalid",
                "dl_number": dl_number,
                "name": d.get("name"),
                "dob": d.get("dob"),
                "expiry_date": d.get("validity", {}).get("non_transport"),
                "vehicle_classes": d.get("vehicle_classes", []),
                "source": "surepass"
            }
        else:
            return {"verification_status": "failed", "error": data.get("message"), "source": "surepass"}
    except Exception as e:
        logger.error(f"Surepass DL verification error: {e}")
        return {"verification_status": "error", "error": str(e), "source": "surepass"}


async def _surepass_verify_rc(registration_number: str) -> dict:
    """Call Surepass RC verification endpoint."""
    url = f"{settings.SUREPASS_BASE_URL}/rc/rc-full"
    payload = {"id_number": registration_number}
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload, headers=_surepass_headers())
            data = resp.json()
        if resp.status_code == 200 and data.get("success"):
            d = data.get("data", {})
            return {
                "verification_status": "valid",
                "registration_number": registration_number,
                "owner_name": d.get("owner_name"),
                "vehicle_class": d.get("vehicle_class"),
                "fuel_type": d.get("fuel_type"),
                "fitness_upto": d.get("fit_up_to"),
                "insurance_upto": d.get("insurance_validity"),
                "puc_upto": d.get("pucc_upto"),
                "source": "surepass"
            }
        else:
            return {"verification_status": "failed", "error": data.get("message"), "source": "surepass"}
    except Exception as e:
        logger.error(f"Surepass RC verification error: {e}")
        return {"verification_status": "error", "error": str(e), "source": "surepass"}


async def _surepass_verify_pan(pan_number: str, name: str, dob: str) -> dict:
    """Call Surepass PAN verification endpoint."""
    url = f"{settings.SUREPASS_BASE_URL}/pan/pan"
    payload = {"id_number": pan_number}
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload, headers=_surepass_headers())
            data = resp.json()
        if resp.status_code == 200 and data.get("success"):
            d = data.get("data", {})
            return {
                "verification_status": "valid" if d.get("valid") else "invalid",
                "pan_number": pan_number,
                "name": d.get("first_name", "") + " " + d.get("last_name", ""),
                "category": d.get("category"),
                "source": "surepass"
            }
        else:
            return {"verification_status": "failed", "error": data.get("message"), "source": "surepass"}
    except Exception as e:
        logger.error(f"Surepass PAN verification error: {e}")
        return {"verification_status": "error", "error": str(e), "source": "surepass"}
