import os
import sys
import unittest
import uuid
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add current path to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__))))

from app.db.session import Base, get_db
from app.main import app

# SQLite database for tests
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

class TestAuthAndKYCWorkflow(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)
        cls.phone = "+919876543210"
        cls.headers = {}
        cls.refresh_token = ""
        cls.driving_licence_doc_id = None

    @classmethod
    def tearDownClass(cls):
        if os.path.exists("./test.db"):
            try:
                os.remove("./test.db")
            except Exception:
                pass

    def test_01_request_otp(self):
        """Test Login OTP generation request (Module 1/4 spec)"""
        response = self.client.post(
            "/api/v1/auth/login",
            json={"mobile_number": self.phone}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("debug_code", data)
        self.assertEqual(data["mobile_number"], self.phone)
        self.__class__.otp_code = data["debug_code"]

    def test_02_verify_otp_new_user(self):
        """Test OTP verification to register user and obtain tokens (UUIDs)"""
        response = self.client.post(
            "/api/v1/auth/verify-otp",
            json={
                "mobile_number": self.phone,
                "otp": self.otp_code,
                "device_info": "Integration Test Runner"
            }
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("access_token", data)
        self.assertIn("refresh_token", data)
        self.assertEqual(data["role"], "Driver")
        self.assertFalse(data["is_profile_complete"])
        self.assertFalse(data["is_kyc_verified"])

        self.__class__.access_token = data["access_token"]
        self.__class__.refresh_token = data["refresh_token"]
        self.__class__.headers = {"Authorization": f"Bearer {data['access_token']}"}

    def test_03_get_auth_me(self):
        """Test retrieving authenticated user details via /auth/me"""
        response = self.client.get("/api/v1/auth/me", headers=self.headers)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mobile_number"], self.phone)
        self.assertEqual(data["role"], "Driver")
        self.assertEqual(data["status"], "Active")
        # Verify user ID is a valid UUID
        self.assertIsNotNone(uuid.UUID(data["id"]))

    def test_04_get_blank_profile(self):
        """Test retrieving initial blank profile details"""
        response = self.client.get("/api/v1/drivers/profile", headers=self.headers)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["verification_status"], "pending")
        self.assertEqual(data["status"], "Active")
        self.assertIsNone(data["full_name"])
        self.assertIsNone(data["address"])

    def test_05_update_profile(self):
        """Test updating profile information (consolidated fields)"""
        payload = {
            "full_name": "Ramesh Kumar",
            "dob": "1992-08-14",
            "sex": "Male",
            "emergency_contact_no": "+919876543211"
        }
        response = self.client.put("/api/v1/drivers/profile", headers=self.headers, json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["full_name"], "Ramesh Kumar")
        self.assertEqual(data["sex"], "Male")
        self.assertEqual(data["verification_status"], "in_progress")

    def test_06_update_address(self):
        """Test creating driver address details"""
        payload = {
            "address_line1": "Flat 102, Green Meadows Apartment",
            "address_line2": "HSR Layout Sector 3",
            "city": "Bengaluru",
            "state": "Karnataka",
            "postal_code": "560102",
            "country": "India"
        }
        response = self.client.post("/api/v1/drivers/address", headers=self.headers, json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["city"], "Bengaluru")
        self.assertEqual(data["postal_code"], "560102")
        self.assertIsNotNone(uuid.UUID(data["id"]))
        self.assertIsNotNone(uuid.UUID(data["driver_id"]))

        # Verify address is linked to profile
        profile_res = self.client.get("/api/v1/drivers/profile", headers=self.headers)
        self.assertEqual(profile_res.status_code, 200)
        self.assertIsNotNone(profile_res.json()["address"])

    def test_07_upload_documents(self):
        """Test uploading documents to /kyc/upload and mock OCR extraction"""
        # 1. Upload Driving Licence
        dl_file = ("driving_licence.jpg", b"mock_driving_licence_data", "image/jpeg")
        response = self.client.post(
            "/api/v1/kyc/upload",
            headers=self.headers,
            data={"document_type": "driving_licence"},
            files={"file": dl_file}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["document_id"], "driving_licence")
        self.assertEqual(data["verification_status"], "pending")
        self.assertIsNotNone(data["document_no"])
        self.assertIn("/static/uploads/", data["firebase_url"])
        
        # Save DL Document ID (UUID string)
        self.__class__.driving_licence_doc_id = data["id"]

        # 2. Upload PAN Card
        pan_file = ("pan_card.jpg", b"mock_pan_data", "image/jpeg")
        response = self.client.post(
            "/api/v1/kyc/upload",
            headers=self.headers,
            data={"document_type": "pan_card"},
            files={"file": pan_file}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["document_id"], "pan_card")
        self.assertEqual(data["verification_status"], "pending")
        self.__class__.pan_doc_id = data["id"]

        # 3. Upload Selfie
        self_file = ("selfie.jpg", b"mock_selfie_data", "image/jpeg")
        response = self.client.post(
            "/api/v1/kyc/upload",
            headers=self.headers,
            data={"document_type": "selfie"},
            files={"file": self_file}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["document_id"], "selfie")
        self.assertEqual(data["verification_status"], "pending")
        self.__class__.selfie_doc_id = data["id"]

        # Check overall verification_status transitioned to pending_review
        status_response = self.client.get("/api/v1/kyc/status", headers=self.headers)
        self.assertEqual(status_response.status_code, 200)
        status_data = status_response.json()
        self.assertEqual(status_data["kyc_status"], "pending_review")
        self.assertEqual(len(status_data["documents"]), 3)

    def test_08_admin_kyc_verification_flow(self):
        """Test admin verify endpoint for UUID approvals/rejections"""
        # Reject DL
        reject_payload = {
            "document_id": self.driving_licence_doc_id,
            "status": "rejected",
            "rejection_reason": "Blured details"
        }
        response = self.client.post("/api/v1/kyc/admin/verify", json=reject_payload, headers=self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["driver_verification_status"], "rejected")

        # Approve all
        approve_payloads = [
            {"document_id": self.driving_licence_doc_id, "status": "approved"},
            {"document_id": self.pan_doc_id, "status": "approved"},
            {"document_id": self.selfie_doc_id, "status": "approved"},
        ]
        for p in approve_payloads:
            self.client.post("/api/v1/kyc/admin/verify", json=p, headers=self.headers)

        # Check status is now verified
        status_response = self.client.get("/api/v1/kyc/status", headers=self.headers)
        self.assertEqual(status_response.json()["kyc_status"], "verified")

    def test_09_token_refresh(self):
        """Test token refresh rotation (/auth/refresh-token)"""
        response = self.client.post(
            "/api/v1/auth/refresh-token",
            json={"refresh_token": self.refresh_token}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("access_token", data)
        self.assertIn("refresh_token", data)
        self.assertTrue(data["is_profile_complete"])
        self.assertTrue(data["is_kyc_verified"])

        self.__class__.new_refresh_token = data["refresh_token"]

    def test_10_logout_revokes_token(self):
        """Test logout and token revocation"""
        response = self.client.post(
            "/api/v1/auth/logout",
            json={"refresh_token": self.new_refresh_token}
        )
        self.assertEqual(response.status_code, 200)

        response_fail = self.client.post(
            "/api/v1/auth/refresh-token",
            json={"refresh_token": self.new_refresh_token}
        )
        self.assertEqual(response_fail.status_code, 401)

if __name__ == "__main__":
    unittest.main()
