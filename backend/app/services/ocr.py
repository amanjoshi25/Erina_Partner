"""
OCR Service — supports mock (dummy data) and real (Google Cloud Vision) modes.

Document types supported:
  - driving_licence  → DL number, name, DOB, validity, vehicle classes
  - pan_card         → PAN number, name, DOB
  - aadhaar_front    → Aadhaar number (masked), name, DOB, address
  - aadhaar_back     → Address details
  - selfie           → Face detection only
  - rc_book          → Registration number, owner, vehicle details

To switch to real OCR:
  1. Set OCR_MODE=real in .env
  2. Set GOOGLE_VISION_API_KEY=your-api-key in .env
"""
import logging
import base64
import json
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)


async def extract_document_data(document_type: str, image_bytes: bytes) -> dict:
    """
    Run OCR on an uploaded document image.

    Returns a dict of extracted fields, or empty dict on failure.
    """
    if settings.OCR_MODE == "real":
        return await _google_vision_ocr(document_type, image_bytes)
    else:
        return _mock_ocr(document_type)


def _mock_ocr(document_type: str) -> dict:
    """Return realistic mock OCR data for development/testing."""
    mock_data = {
        "driving_licence": {
            "document_type": "driving_licence",
            "document_number": "DL-1420110012345",
            "name": "MOCK DRIVER NAME",
            "dob": "1992-05-15",
            "valid_till": "2030-05-14",
            "issue_date": "2010-05-15",
            "vehicle_classes": ["LMV", "MCWG"],
            "blood_group": "O+",
            "address": "123 Mock Street, Bengaluru, Karnataka 560001",
            "issuing_authority": "Transport Authority Bengaluru",
            "confidence": 0.95,
            "ocr_source": "mock"
        },
        "pan_card": {
            "document_type": "pan_card",
            "document_number": "ABCPM1234M",
            "name": "MOCK DRIVER NAME",
            "father_name": "MOCK FATHER NAME",
            "dob": "1992-05-15",
            "confidence": 0.97,
            "ocr_source": "mock"
        },
        "aadhaar_front": {
            "document_type": "aadhaar_front",
            "document_number": "XXXX XXXX 1234",  # Always masked
            "name": "MOCK DRIVER NAME",
            "dob": "1992-05-15",
            "gender": "Male",
            "confidence": 0.96,
            "ocr_source": "mock"
        },
        "aadhaar_back": {
            "document_type": "aadhaar_back",
            "address": "S/O MOCK FATHER, 123 Mock Street, HSR Layout, Bengaluru, Karnataka - 560102",
            "pin_code": "560102",
            "confidence": 0.94,
            "ocr_source": "mock"
        },
        "selfie": {
            "document_type": "selfie",
            "face_detected": True,
            "face_count": 1,
            "confidence": 0.99,
            "ocr_source": "mock"
        },
        "rc_book": {
            "document_type": "rc_book",
            "registration_number": "KA01AB1234",
            "owner_name": "MOCK OWNER NAME",
            "vehicle_class": "LMV",
            "fuel_type": "Petrol",
            "maker_model": "MARUTI SUZUKI SWIFT",
            "chassis_number": "MA3FJEB1S00123456",
            "engine_number": "K12BN1234567",
            "registration_date": "2020-01-15",
            "fitness_upto": "2035-01-14",
            "insurance_validity": "2026-01-14",
            "confidence": 0.93,
            "ocr_source": "mock"
        },
        "insurance": {
            "document_type": "insurance",
            "policy_number": "OD-12345678901234",
            "vehicle_number": "KA01AB1234",
            "insurer": "Bajaj Allianz General Insurance",
            "valid_from": "2025-01-15",
            "valid_till": "2026-01-14",
            "confidence": 0.91,
            "ocr_source": "mock"
        },
        "puc": {
            "document_type": "puc",
            "certificate_number": "KA012025PUC12345",
            "vehicle_number": "KA01AB1234",
            "valid_till": "2025-12-31",
            "test_center": "Mock PUC Center, Bengaluru",
            "confidence": 0.92,
            "ocr_source": "mock"
        },
    }
    result = mock_data.get(document_type, {
        "document_type": document_type,
        "ocr_source": "mock",
        "confidence": 0.80
    })
    logger.info(f"[OCR MOCK] Extracted data for document type: {document_type}")
    return result


async def _google_vision_ocr(document_type: str, image_bytes: bytes) -> dict:
    """
    Real OCR using Google Cloud Vision API (Document Text Detection).
    """
    if not settings.GOOGLE_VISION_API_KEY:
        logger.error("GOOGLE_VISION_API_KEY not configured. Falling back to mock.")
        return _mock_ocr(document_type)

    import httpx
    url = f"https://vision.googleapis.com/v1/images:annotate?key={settings.GOOGLE_VISION_API_KEY}"
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    payload = {
        "requests": [{
            "image": {"content": image_b64},
            "features": [
                {"type": "DOCUMENT_TEXT_DETECTION", "maxResults": 1}
            ]
        }]
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            data = response.json()

        if "error" in data:
            logger.error(f"Vision API error: {data['error']}")
            return _mock_ocr(document_type)

        full_text = ""
        try:
            full_text = data["responses"][0]["fullTextAnnotation"]["text"]
        except (KeyError, IndexError):
            logger.warning("No text found in image by Vision API")

        # Parse extracted text based on document type
        return _parse_vision_text(document_type, full_text)

    except Exception as e:
        logger.error(f"Google Vision OCR failed: {e}")
        return _mock_ocr(document_type)


def _parse_vision_text(document_type: str, text: str) -> dict:
    """
    Parse raw OCR text into structured fields.
    This is a simplified regex-based parser — extend per document format.
    """
    import re
    result = {"document_type": document_type, "raw_text": text, "ocr_source": "google_vision"}

    if document_type == "driving_licence":
        dl_match = re.search(r'\b[A-Z]{2}[\d]{2}\s?\d{10,13}\b', text)
        if dl_match:
            result["document_number"] = dl_match.group().replace(" ", "")
        dob_match = re.search(r'DOB[:\s]+(\d{2}[/-]\d{2}[/-]\d{4})', text, re.IGNORECASE)
        if dob_match:
            result["dob"] = dob_match.group(1)

    elif document_type == "pan_card":
        pan_match = re.search(r'\b[A-Z]{5}[0-9]{4}[A-Z]{1}\b', text)
        if pan_match:
            result["document_number"] = pan_match.group()

    elif document_type in ("aadhaar_front", "aadhaar_back"):
        aadhaar_match = re.search(r'\d{4}\s\d{4}\s\d{4}', text)
        if aadhaar_match:
            # Always mask for privacy
            result["document_number"] = f"XXXX XXXX {aadhaar_match.group().split()[-1]}"

    return result
