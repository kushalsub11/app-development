from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from config.database import get_db
from models.user import User, AdvisorProfile, Booking, Payment, Report
from middleware.auth_middleware import require_role

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/dashboard")
async def get_admin_dashboard(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get admin dashboard statistics."""
    total_users = db.query(func.count(User.id)).filter(User.role == "user").scalar()
    total_advisors = db.query(func.count(AdvisorProfile.id)).scalar()
    verified_advisors = db.query(func.count(AdvisorProfile.id)).filter(AdvisorProfile.is_verified == True).scalar()
    total_bookings = db.query(func.count(Booking.id)).scalar()
    total_revenue = db.query(func.coalesce(func.sum(Payment.amount), 0)).filter(Payment.status == "completed").scalar()
    pending_reports = db.query(func.count(Report.id)).filter(Report.status == "pending").scalar()

    return {
        "total_users": total_users,
        "total_advisors": total_advisors,
        "verified_advisors": verified_advisors,
        "unverified_advisors": total_advisors - verified_advisors,
        "total_bookings": total_bookings,
        "total_revenue": float(total_revenue),
        "pending_reports": pending_reports,
    }
