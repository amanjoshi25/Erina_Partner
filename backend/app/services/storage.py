"""
Firebase Storage Service — supports mock (local files) and real (Firebase Storage) modes.

To switch to real Firebase Storage:
  1. Set STORAGE_MODE=real in .env
  2. Set FIREBASE_CREDENTIALS_PATH=/path/to/serviceAccountKey.json
  3. Set FIREBASE_STORAGE_BUCKET=your-project.appspot.com
"""
import os
import uuid
import logging
import shutil
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)

LOCAL_UPLOAD_DIR = os.path.join(os.getcwd(), "static", "uploads")


def _init_firebase():
    """Initialize Firebase Admin SDK (lazy initialization)."""
    try:
        import firebase_admin
        from firebase_admin import credentials, storage

        if not firebase_admin._apps:
            if not settings.FIREBASE_CREDENTIALS_PATH:
                raise ValueError("FIREBASE_CREDENTIALS_PATH not set")
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred, {
                "storageBucket": settings.FIREBASE_STORAGE_BUCKET
            })
        return storage.bucket()
    except Exception as e:
        logger.error(f"Firebase init failed: {e}")
        raise


async def upload_document(
    file_bytes: bytes,
    original_filename: str,
    folder: str = "kyc",
    content_type: str = "image/jpeg"
) -> str:
    """
    Upload a document to storage.

    Returns:
        URL/path to the uploaded file.
        In mock mode: local static path like "/static/uploads/kyc/uuid.jpg"
        In real mode: Firebase public URL
    """
    if settings.STORAGE_MODE == "real":
        return await _upload_to_firebase(file_bytes, original_filename, folder, content_type)
    else:
        return await _upload_to_local(file_bytes, original_filename, folder)


async def delete_document(file_url: str) -> bool:
    """Delete a document from storage."""
    if settings.STORAGE_MODE == "real":
        return await _delete_from_firebase(file_url)
    else:
        return _delete_from_local(file_url)


async def get_document_url(file_url: str, expiry_hours: int = 1) -> str:
    """
    Get a viewable URL for a stored document.
    In mock mode: returns the static path as-is.
    In real mode: generates a signed Firebase URL valid for expiry_hours.
    """
    if settings.STORAGE_MODE == "real":
        return await _get_firebase_signed_url(file_url, expiry_hours)
    else:
        return file_url


# ─── Mock Storage (Local Files) ────────────────────────────────────────────────

async def _upload_to_local(file_bytes: bytes, original_filename: str, folder: str) -> str:
    """Save file to local /static/uploads/{folder}/ directory."""
    dest_dir = os.path.join(LOCAL_UPLOAD_DIR, folder)
    os.makedirs(dest_dir, exist_ok=True)

    ext = os.path.splitext(original_filename)[1] or ".jpg"
    unique_name = f"{uuid.uuid4()}{ext}"
    dest_path = os.path.join(dest_dir, unique_name)

    with open(dest_path, "wb") as f:
        f.write(file_bytes)

    logger.info(f"[STORAGE MOCK] Saved file to {dest_path}")
    return f"/static/uploads/{folder}/{unique_name}"


def _delete_from_local(file_url: str) -> bool:
    """Delete local file given its static URL path."""
    try:
        # Strip leading slash and join with cwd
        relative = file_url.lstrip("/")
        full_path = os.path.join(os.getcwd(), relative)
        if os.path.exists(full_path):
            os.remove(full_path)
            logger.info(f"[STORAGE MOCK] Deleted {full_path}")
        return True
    except Exception as e:
        logger.error(f"[STORAGE MOCK] Delete failed: {e}")
        return False


# ─── Real Firebase Storage ─────────────────────────────────────────────────────

async def _upload_to_firebase(
    file_bytes: bytes, original_filename: str, folder: str, content_type: str
) -> str:
    """Upload file to Firebase Storage bucket."""
    try:
        bucket = _init_firebase()
        ext = os.path.splitext(original_filename)[1] or ".jpg"
        blob_name = f"{folder}/{uuid.uuid4()}{ext}"
        blob = bucket.blob(blob_name)
        blob.upload_from_string(file_bytes, content_type=content_type)
        blob.make_public()
        logger.info(f"[STORAGE FIREBASE] Uploaded to {blob.public_url}")
        return blob.public_url
    except Exception as e:
        logger.error(f"Firebase upload failed: {e}")
        raise


async def _delete_from_firebase(file_url: str) -> bool:
    """Delete a blob from Firebase Storage given its public URL."""
    try:
        bucket = _init_firebase()
        # Extract blob name from URL
        bucket_name = settings.FIREBASE_STORAGE_BUCKET
        blob_name = file_url.split(f"{bucket_name}/o/")[-1].split("?")[0]
        blob_name = blob_name.replace("%2F", "/")
        blob = bucket.blob(blob_name)
        blob.delete()
        return True
    except Exception as e:
        logger.error(f"Firebase delete failed: {e}")
        return False


async def _get_firebase_signed_url(file_url: str, expiry_hours: int) -> str:
    """Generate a time-limited signed URL from Firebase Storage."""
    import datetime
    try:
        bucket = _init_firebase()
        bucket_name = settings.FIREBASE_STORAGE_BUCKET
        blob_name = file_url.split(f"{bucket_name}/o/")[-1].split("?")[0]
        blob_name = blob_name.replace("%2F", "/")
        blob = bucket.blob(blob_name)
        url = blob.generate_signed_url(
            expiration=datetime.timedelta(hours=expiry_hours),
            method="GET"
        )
        return url
    except Exception as e:
        logger.error(f"Firebase signed URL generation failed: {e}")
        return file_url  # Fallback to public URL
