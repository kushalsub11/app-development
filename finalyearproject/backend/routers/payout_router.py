from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from typing import List
from datetime import datetime

from config.database import get_db
from models.user import User, AdvisorProfile, Booking, Payment, PayoutRequest, PayoutStatus, BookingStatus
from schemas.user_schema import PayoutRequestCreate, PayoutRequestResponse, PayoutStatusUpdate
from middleware.auth_middleware import get_current_user, require_role
from services.notification_service import create_notification

router = APIRouter(prefix="/payouts", tags=["Payouts"])


@router.post("", response_model=PayoutRequestResponse)
async def create_payout_request(
    request_data: PayoutRequestCreate,
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Advisor creates a payout request."""
    # 1. Get advisor profile
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == current_user.id).first()
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor profile not found")

    # 2. Calculate Available Balance
    # Total Net Revenue (70% of completed bookings)
    total_revenue = db.query(func.sum(Payment.amount)).join(Booking).filter(
        Booking.advisor_id == advisor.id
    ).scalar() or 0.0
    
    net_revenue = total_revenue * 0.70
    
    # Total Withdrawals (Approved or Completed payout requests)
    total_withdrawn = db.query(func.sum(PayoutRequest.amount)).filter(
        PayoutRequest.advisor_id == advisor.id,
        PayoutRequest.status.in_([PayoutStatus.approved, PayoutStatus.completed])
    ).scalar() or 0.0
    
    available_balance = net_revenue - total_withdrawn

    # 3. Validations
    if request_data.amount < 500:
        raise HTTPException(status_code=400, detail="Minimum cashout amount is 500 RS")
    
    if request_data.amount > available_balance:
        raise HTTPException(
            status_code=400, 
            detail=f"Insufficient balance. Available: {available_balance:.2f} RS"
        )

    # 4. Create request
    new_request = PayoutRequest(
        advisor_id=advisor.id,
        amount=request_data.amount,
        payment_details=request_data.payment_details,
        status=PayoutStatus.pending
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request


@router.get("/me", response_model=List[PayoutRequestResponse])
async def get_my_payout_requests(
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Get all payout requests for the current advisor."""
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == current_user.id).first()
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor profile not found")
        
    return db.query(PayoutRequest).filter(PayoutRequest.advisor_id == advisor.id).order_by(PayoutRequest.created_at.desc()).all()


@router.get("/admin/all", response_model=List[PayoutRequestResponse])
async def get_all_payout_requests_admin(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all payout requests (Admin only)."""
    return (
        db.query(PayoutRequest)
        .options(joinedload(PayoutRequest.advisor).joinedload(AdvisorProfile.user))
        .order_by(PayoutRequest.created_at.desc())
        .all()
    )


@router.put("/admin/{payout_id}/status", response_model=PayoutRequestResponse)
async def update_payout_status(
    payout_id: int,
    status_data: PayoutStatusUpdate,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Approve or Reject a payout request (Admin only)."""
    payout = db.query(PayoutRequest).filter(PayoutRequest.id == payout_id).first()
    if not payout:
        raise HTTPException(status_code=404, detail="Payout request not found")
        
    payout.status = status_data.status
    if status_data.admin_notes:
        payout.admin_notes = status_data.admin_notes
        
    db.commit()
    db.refresh(payout)

    db.refresh(payout)

    # Get advisor's user_id
    advisor_user_id = db.query(AdvisorProfile.user_id).filter(AdvisorProfile.id == payout.advisor_id).scalar()
    
    if advisor_user_id:
        title = "Payout Status Update"
        message = f"Your payout request of ₹{payout.amount:.2f} has been {status_data.status}."
        if status_data.admin_notes:
            message += f"\nNote: {status_data.admin_notes}"
            
        create_notification(
            db,
            user_id=advisor_user_id,
            title=title,
            message=message,
            notification_type="payment",
            reference_id=str(payout.id)
        )

    return payout
