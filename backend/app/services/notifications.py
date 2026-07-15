"""
Push Notification Service — supports mock (console log) and real (Firebase FCM) modes.

To switch to real FCM:
  1. Set FCM_MODE=real in .env
  2. Set FIREBASE_CREDENTIALS_PATH=/path/to/serviceAccountKey.json
"""
import logging
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
    image_url: Optional[str] = None
) -> bool:
    """
    Send a push notification to a device via FCM token.

    Args:
        fcm_token: Device FCM registration token
        title: Notification title
        body: Notification body text
        data: Optional key-value payload data
        image_url: Optional image to display in notification

    Returns:
        True if sent successfully
    """
    if settings.FCM_MODE == "real":
        return await _send_firebase_notification(fcm_token, title, body, data, image_url)
    return _send_mock_notification(fcm_token, title, body, data)


async def notify_kyc_status_change(fcm_token: Optional[str], new_status: str, rejection_reason: Optional[str] = None) -> bool:
    """Send notification when KYC status changes."""
    if not fcm_token:
        return False

    status_messages = {
        "pending_review": {
            "title": "Documents Under Review 📋",
            "body": "Your KYC documents have been received and are under review. We'll notify you within 24 hours."
        },
        "verified": {
            "title": "KYC Verified ✅",
            "body": "Congratulations! Your identity has been verified. You can now access all Erina services."
        },
        "rejected": {
            "title": "KYC Rejected ❌",
            "body": f"Your KYC was rejected. Reason: {rejection_reason or 'Please re-upload documents'}. Tap to re-submit."
        },
        "in_progress": {
            "title": "KYC In Progress ⏳",
            "body": "Your KYC verification is in progress. Please upload all required documents."
        }
    }

    msg = status_messages.get(new_status, {
        "title": "KYC Status Update",
        "body": f"Your KYC status has been updated to: {new_status}"
    })

    return await send_push_notification(
        fcm_token=fcm_token,
        title=msg["title"],
        body=msg["body"],
        data={"type": "kyc_update", "status": new_status}
    )


async def notify_otp_sent(fcm_token: Optional[str], mobile: str) -> bool:
    """Notify user that OTP has been sent (for locked-screen notification)."""
    if not fcm_token:
        return False
    return await send_push_notification(
        fcm_token=fcm_token,
        title="OTP Sent",
        body=f"A 6-digit OTP has been sent to {mobile[-4:].rjust(len(mobile), '*')}",
        data={"type": "otp_sent"}
    )


# ─── Mock Mode ─────────────────────────────────────────────────────────────────

def _send_mock_notification(fcm_token: str, title: str, body: str, data: Optional[dict]) -> bool:
    """Log notification to console in mock mode."""
    logger.info("=" * 60)
    logger.info(f"[FCM MOCK] Notification to token: {fcm_token[:20]}...")
    logger.info(f"[FCM MOCK] Title: {title}")
    logger.info(f"[FCM MOCK] Body: {body}")
    if data:
        logger.info(f"[FCM MOCK] Data: {data}")
    logger.info("=" * 60)
    print(f"\n🔔 [FCM MOCK] {title}: {body}\n")
    return True


# ─── Real Firebase FCM ─────────────────────────────────────────────────────────

async def _send_firebase_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict],
    image_url: Optional[str]
) -> bool:
    """Send real FCM notification via Firebase Admin SDK."""
    try:
        import firebase_admin
        from firebase_admin import messaging, credentials

        if not firebase_admin._apps:
            if not settings.FIREBASE_CREDENTIALS_PATH:
                logger.error("FIREBASE_CREDENTIALS_PATH not configured")
                return False
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)

        msg = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
                image=image_url
            ),
            data={k: str(v) for k, v in (data or {}).items()},
            token=fcm_token,
            android=messaging.AndroidConfig(
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#3B82F6",
                    sound="default"
                ),
                priority="high"
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default")
                )
            )
        )

        response = messaging.send(msg)
        logger.info(f"FCM notification sent: {response}")
        return True

    except Exception as e:
        logger.error(f"FCM send failed: {e}")
        return False
