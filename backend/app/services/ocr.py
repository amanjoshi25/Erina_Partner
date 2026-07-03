import random
import time
from typing import Dict, Any

def mock_ocr_extract(document_type: str, filename: str) -> Dict[str, Any]:
    """
    Simulate OCR processing on an uploaded file.
    Returns a dictionary of mock extracted fields depending on the document type.
    """
    # Simulate processing latency (e.g. 0.5s to 1s)
    time.sleep(0.8)
    
    extracted_data = {}
    
    if document_type == "driving_licence":
        # Generate a random Indian DL format (e.g. KA51 20201234567)
        state_code = random.choice(["DL", "KA", "MH", "HR", "UP", "TN"])
        rto_code = f"{random.randint(1, 99):02d}"
        year = f"{random.randint(2010, 2025)}"
        serial = f"{random.randint(1000000, 9999999)}"
        dl_number = f"{state_code}{rto_code}{year}{serial}"
        
        extracted_data = {
            "document_number": dl_number,
            "document_type": "driving_licence",
            "name": "RAMESH KUMAR",
            "date_of_birth": "1992-08-14",
            "valid_till": "2037-08-13",
            "issuing_authority": f"RTO {state_code}-{rto_code}",
            "ocr_confidence": round(random.uniform(0.92, 0.99), 2)
        }
        
    elif document_type == "pan_card":
        # Generate a random PAN number format (e.g. ABCDE1234F)
        letters_1 = "".join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ", k=3))
        category = "P" # P for individual
        letter_last = random.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        digits = "".join(random.choices("0123456789", k=4))
        pan_number = f"{letters_1}{category}{letter_last}{digits}{random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}"
        
        extracted_data = {
            "document_number": pan_number,
            "document_type": "pan_card",
            "name": "RAMESH KUMAR",
            "father_name": "SURESH KUMAR",
            "date_of_birth": "1992-08-14",
            "ocr_confidence": round(random.uniform(0.94, 0.99), 2)
        }
        
    elif document_type == "selfie":
        # Selfies don't have document numbers, we mock face matching verification confidence
        extracted_data = {
            "document_type": "selfie",
            "face_detected": True,
            "liveness_check": "passed",
            "face_match_confidence": round(random.uniform(0.95, 0.99), 2),
            "ocr_confidence": 1.0
        }
        
    else:
        extracted_data = {
            "document_type": "unknown",
            "error": "Unsupported document type for OCR"
        }
        
    return extracted_data
