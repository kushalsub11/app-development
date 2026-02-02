from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List
from config.database import get_db
from models.user import User, AdvisorProfile
from schemas.user_schema import (
    AdvisorProfileResponse, AdvisorProfileUpdate, UserResponse
)
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/advisors", tags=["Advisors"])


@router.get("", response_model=List[AdvisorProfileResponse])
async def get_all_advisors(db: Session = Depends(get_db)):
    """Get all verified advisors (public endpoint)."""
    advisors = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.is_verified == True)
        .all()
    )
    return [AdvisorProfileResponse.model_validate(a) for a in advisors]


@router.get("/all", response_model=List[AdvisorProfileResponse])
async def get_all_advisors_admin(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all advisors including unverified (Admin only)."""
    advisors = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .all()
    )
    return [AdvisorProfileResponse.model_validate(a) for a in advisors]


@router.get("/{advisor_id}", response_model=AdvisorProfileResponse)
async def get_advisor_detail(advisor_id: int, db: Session = Depends(get_db)):
    """Get a specific advisor's profile."""
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.id == advisor_id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")
    return AdvisorProfileResponse.model_validate(advisor)


@router.get("/me/profile", response_model=AdvisorProfileResponse)
async def get_my_advisor_profile(
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Get the current advisor's own profile."""
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.user_id == current_user.id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor profile not found")
    return AdvisorProfileResponse.model_validate(advisor)


@router.put("/me/profile", response_model=AdvisorProfileResponse)
async def update_advisor_profile(
    profile_data: AdvisorProfileUpdate,
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Update the current advisor's profile."""
    advisor = (
        db.query(AdvisorProfile)
        .filter(AdvisorProfile.user_id == current_user.id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor profile not found")

    if profile_data.bio is not None:
        advisor.bio = profile_data.bio
    if profile_data.specialization is not None:
        advisor.specialization = profile_data.specialization
    if profile_data.experience_years is not None:
        advisor.experience_years = profile_data.experience_years
    if profile_data.hourly_rate is not None:
        advisor.hourly_rate = profile_data.hourly_rate
    if profile_data.available_slots is not None:
        advisor.available_slots = profile_data.available_slots

    db.commit()
    db.refresh(advisor)

    # Reload with user relationship
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.id == advisor.id)
        .first()
    )
    return AdvisorProfileResponse.model_validate(advisor)


@router.put("/{advisor_id}/verify", response_model=AdvisorProfileResponse)
async def verify_advisor(
    advisor_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Verify or unverify an advisor (Admin only)."""
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.id == advisor_id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")

    advisor.is_verified = not advisor.is_verified
    db.commit()
    db.refresh(advisor)
    return AdvisorProfileResponse.model_validate(advisor)


@router.get("/me/stats")
async def get_advisor_stats(
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Get statistics for the current advisor."""
    from models.user import Booking, Payment, Review
    from sqlalchemy import func

    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == current_user.id).first()
    if not advisor:
         raise HTTPException(status_code=404, detail="Advisor not found")

    total_bookings = db.query(Booking).filter(Booking.advisor_id == advisor.id).count()
    
    # Calculate revenue from successful payments
    total_revenue = db.query(func.sum(Payment.amount)).join(Booking).filter(Booking.advisor_id == advisor.id).scalar() or 0.0

    return {
        "total_bookings": total_bookings,
        "rating": advisor.rating,
        "total_reviews": advisor.total_reviews,
        "total_revenue": total_revenue,
    }
