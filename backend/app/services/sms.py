"""
SMS OTP Service — supports mock (dev) and real MSG91 (prod) modes.

To switch to real SMS:
  1. Set OTP_MODE=real in .env
  2. Set MSG91_API_KEY and MSG91_TEMPLATE_ID in .env
"""
import logging
import httpx
from app.core.config import settings

logger = logging.getLogger(__name__)

MSG91_SEND_OTP_URL = "https://control.msg91.com/api/v5/otp"


async def send_otp_sms(mobile: str, otp: str) -> bool:
    """
    Send OTP to mobile number.
    
    In mock mode: logs OTP to console (safe for dev/test).
    In real mode: sends via MSG91 SMS gateway.
    
    Args:
        mobile: Mobile number with country code e.g. "+917080057430"
        otp: 6-digit OTP string
    
    Returns:
        True if sent successfully, False on failure
    """
    if settings.OTP_MODE == "mock":
        return await _send_mock_otp(mobile, otp)
    else:
        return await _send_msg91_otp(mobile, otp)


async def _send_mock_otp(mobile: str, otp: str) -> bool:
    """Mock OTP sender — prints to console for development."""
    logger.info("=" * 50)
    logger.info(f"[SMS MOCK] OTP for {mobile}: {otp}")
    logger.info("=" * 50)
    print(f"\n{'='*50}")
    print(f"  📱 OTP for {mobile}: {otp}")
    print(f"{'='*50}\n")
    return True


async def _send_msg91_otp(mobile: str, otp: str) -> bool:
    """
    Real MSG91 SMS OTP sender.
    Docs: https://docs.msg91.com/reference/send-otp
    """
    if not settings.MSG91_API_KEY:
        logger.error("MSG91_API_KEY not configured. Set OTP_MODE=mock or provide MSG91_API_KEY.")
        return False

    # MSG91 expects mobile without +
    mobile_clean = mobile.replace("+", "").replace(" ", "")

    payload = {
        "template_id": settings.MSG91_TEMPLATE_ID,
        "mobile": mobile_clean,
        "authkey": settings.MSG91_API_KEY,
        "otp": otp,
        "otp_length": 6,
        "otp_expiry": 5,  # minutes
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(MSG91_SEND_OTP_URL, json=payload)
            data = response.json()
            if response.status_code == 200 and data.get("type") == "success":
                logger.info(f"OTP sent successfully to {mobile} via MSG91")
                return True
            else:
                logger.error(f"MSG91 OTP send failed: {data}")
                return False
    except httpx.RequestError as e:
        logger.error(f"MSG91 request error: {e}")
        return False
