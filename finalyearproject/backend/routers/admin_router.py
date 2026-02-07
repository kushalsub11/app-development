from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from config.database import get_db
from models.user import (
    User, AdvisorProfile, Booking, Payment, Report,
    UserRole, PaymentStatus, ReportStatus, VerificationStatus
)
from schemas.user_schema import AdvisorProfileResponse, ReportResponse
from middleware.auth_middleware import require_role
from typing import List

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/dashboard")
async def get_admin_dashboard(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get admin dashboard statistics."""
    total_users = db.query(func.count(User.id)).filter(User.role == UserRole.user).scalar()
    total_advisors = db.query(func.count(AdvisorProfile.id)).scalar()
    verified_advisors = db.query(func.count(AdvisorProfile.id)).filter(AdvisorProfile.is_verified == True).scalar()
    total_bookings = db.query(func.count(Booking.id)).scalar()
    total_revenue = db.query(func.coalesce(func.sum(Payment.amount), 0)).filter(Payment.status == PaymentStatus.completed).scalar()
    pending_reports = db.query(func.count(Report.id)).filter(Report.status == ReportStatus.pending).scalar()

    total_revenue_gross = float(db.query(func.coalesce(func.sum(Payment.amount), 0)).filter(Payment.status == PaymentStatus.completed).scalar())
    commission_rate = 0.30
    admin_earnings = total_revenue_gross * commission_rate
    advisor_earnings = total_revenue_gross - admin_earnings
    return {
        "total_users": total_users,
        "total_advisors": total_advisors,
        "verified_advisors": verified_advisors,
        "unverified_advisors": total_advisors - verified_advisors,
        "total_bookings": total_bookings,
        "total_revenue": total_revenue_gross,
        "admin_earnings": admin_earnings,
        "advisor_earnings": advisor_earnings,
        "pending_reports": pending_reports,
    }


@router.put("/advisors/{advisor_id}/block", response_model=AdvisorProfileResponse)
async def block_advisor(
    advisor_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Block or unblock an advisor (Admin only)."""
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.id == advisor_id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")

    # Toggle block status
    advisor.is_blocked = not advisor.is_blocked
    # If blocking, also unverify
    if advisor.is_blocked:
        advisor.is_verified = False
        advisor.verification_status = VerificationStatus.rejected

    db.commit()
    db.refresh(advisor)
    return AdvisorProfileResponse.model_validate(advisor)


@router.get("/reports", response_model=List[ReportResponse])
async def get_all_reports_admin(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all reports with detailed info (Admin only)."""
    reports = db.query(Report).order_by(Report.created_at.desc()).all()
    return [ReportResponse.model_validate(r) for r in reports]
