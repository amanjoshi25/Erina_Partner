import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.core.dependencies import get_current_driver
from app.models.driver import Driver
from app.models.subscription import SubscriptionPlan, Subscription
from app.models.payment import Payment, Invoice
from pydantic import BaseModel, Field

router = APIRouter()

# Pydantic schemas
class SubscribeRequest(BaseModel):
    plan_id: str
    payment_method: str = "Razorpay"
    transaction_id: str

class SubscriptionPlanResponse(BaseModel):
    id: str
    name: str
    description: str
    price: float
    duration_days: int
    is_active: bool

    class Config:
        from_attributes = True

class ActiveSubscriptionResponse(BaseModel):
    id: str
    plan_name: str
    status: str
    start_date: datetime.datetime
    end_date: datetime.datetime

@router.get("/plans", response_model=List[SubscriptionPlanResponse])
def get_plans(db: Session = Depends(get_db)):
    """
    Get all active subscription plans. If empty, seeding default plans.
    """
    plans = db.query(SubscriptionPlan).filter(SubscriptionPlan.is_active == True).all()
    if not plans:
        # Seed default plans
        default_plans = [
            SubscriptionPlan(
                name="Bronze Plan",
                description="Basic roadside assistance covers towing up to 10km and battery jumpstart.",
                price=999.00,
                duration_days=90,
                is_active=True
            ),
            SubscriptionPlan(
                name="Silver Plan",
                description="Premium roadside assistance includes flat tyre support, towing up to 50km, and fuel delivery.",
                price=1999.00,
                duration_days=180,
                is_active=True
            ),
            SubscriptionPlan(
                name="Gold Plan",
                description="Ultimate vehicle protection. Unlimited towing, flat tyre, key replacement, medical coordination, and priority dispatcher support.",
                price=2999.00,
                duration_days=365,
                is_active=True
            )
        ]
        db.add_all(default_plans)
        db.commit()
        plans = db.query(SubscriptionPlan).filter(SubscriptionPlan.is_active == True).all()
        
    return plans

@router.post("/subscribe", status_code=status.HTTP_200_OK)
def purchase_subscription(
    payload: SubscribeRequest,
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Purchase a subscription plan. Mock payment verification and create active subscription logs.
    """
    plan = db.query(SubscriptionPlan).filter(SubscriptionPlan.id == payload.plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Subscription plan not found")
        
    # Check if has active subscription, if yes, mark as canceled/superseded
    active_sub = db.query(Subscription).filter(
        Subscription.driver_id == driver.id,
        Subscription.status == "Active"
    ).first()
    if active_sub:
        active_sub.status = "Expired"
        
    # Create new subscription
    start = datetime.datetime.utcnow()
    end = start + datetime.timedelta(days=plan.duration_days)
    
    sub = Subscription(
        driver_id=driver.id,
        plan_id=plan.id,
        status="Active",
        start_date=start,
        end_date=end
    )
    db.add(sub)
    db.commit()
    db.refresh(sub)
    
    # Log payment
    payment = Payment(
        driver_id=driver.id,
        subscription_id=sub.id,
        amount=plan.price,
        payment_method=payload.payment_method,
        transaction_id=payload.transaction_id,
        status="Success"
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    
    # Generate mock invoice
    invoice_num = f"INV-{datetime.datetime.now().year}-{str(uuid_hash(payment.transaction_id))[:6].upper()}"
    invoice = Invoice(
        payment_id=payment.id,
        invoice_number=invoice_num,
        amount=plan.price,
        tax_amount=float(plan.price) * 0.18, # 18% GST
        pdf_url=f"/static/invoices/{invoice_num}.pdf"
    )
    db.add(invoice)
    db.commit()
    
    return {
        "message": "Subscription plan purchased successfully!",
        "subscription_id": sub.id,
        "plan_name": plan.name,
        "expiry_date": sub.end_date
    }

@router.get("/history")
def get_billing_history(
    db: Session = Depends(get_db),
    driver: Driver = Depends(get_current_driver)
):
    """
    Get billing history and payments list for this driver.
    """
    payments = db.query(Payment).filter(Payment.driver_id == driver.id).order_by(Payment.created_at.desc()).all()
    history = []
    
    for p in payments:
        invoice = db.query(Invoice).filter(Invoice.payment_id == p.id).first()
        sub = db.query(Subscription).filter(Subscription.id == p.subscription_id).first()
        plan_name = sub.plan.name if sub and sub.plan else "N/A"
        
        history.append({
            "id": str(p.id),
            "amount": float(p.amount),
            "payment_method": p.payment_method,
            "transaction_id": p.transaction_id,
            "status": p.status,
            "plan_name": plan_name,
            "created_at": p.created_at,
            "invoice_number": invoice.invoice_number if invoice else None,
            "tax_amount": float(invoice.tax_amount) if invoice else 0.0,
            "pdf_url": invoice.pdf_url if invoice else None
        })
        
    return history

def uuid_hash(text: str) -> str:
    import hashlib
    return hashlib.md5(text.encode()).hexdigest()
