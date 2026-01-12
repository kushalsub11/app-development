from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from config.database import get_db
from models.user import User, Payment, Booking, BookingStatus, PaymentStatus
from schemas.user_schema import PaymentCreate, PaymentResponse
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
async def create_payment(
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Process a payment for a booking."""
    # Verify booking exists
    booking = db.query(Booking).filter(Booking.id == payment_data.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your booking")

    # Check if payment already exists
    existing = db.query(Payment).filter(Payment.booking_id == payment_data.booking_id).first()
    if existing and existing.status == PaymentStatus.completed:
        raise HTTPException(status_code=400, detail="Payment already completed")

    new_payment = Payment(
        booking_id=payment_data.booking_id,
        user_id=current_user.id,
        amount=payment_data.amount,
        transaction_id=payment_data.transaction_id,
        payment_method=payment_data.payment_method,
        status=PaymentStatus.completed,
        paid_at=datetime.utcnow(),
    )
    db.add(new_payment)

    # Update booking status to confirmed
    booking.status = BookingStatus.confirmed
    db.commit()
    db.refresh(new_payment)
    return PaymentResponse.model_validate(new_payment)


@router.get("/my-payments", response_model=List[PaymentResponse])
async def get_my_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get payments for the current user."""
    payments = db.query(Payment).filter(Payment.user_id == current_user.id).all()
    return [PaymentResponse.model_validate(p) for p in payments]


@router.get("/", response_model=List[PaymentResponse])
async def get_all_payments(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all payments (Admin only)."""
    payments = db.query(Payment).all()
    return [PaymentResponse.model_validate(p) for p in payments]
