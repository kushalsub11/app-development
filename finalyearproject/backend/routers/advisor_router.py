from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
import os
import uuid
import shutil
from config.database import get_db
from models.user import User, AdvisorProfile, VerificationStatus
from schemas.user_schema import (
    AdvisorProfileResponse, AdvisorProfileUpdate, UserResponse,
    ReviewResponse, ReviewReply
)
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/advisors", tags=["Advisors"])


@router.get("", response_model=List[AdvisorProfileResponse])
async def get_all_advisors(
    location: Optional[str] = None,
    specialization: Optional[str] = None,
    religion: Optional[str] = None,
    is_physical: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """Get all verified and non-blocked advisors with optional filtering."""
    query = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.is_verified == True, AdvisorProfile.is_blocked == False, AdvisorProfile.is_online == True)
    )

    if location:
        query = query.filter(AdvisorProfile.location.ilike(f"%{location}%") | AdvisorProfile.office_address.ilike(f"%{location}%"))
    if specialization:
        query = query.filter(AdvisorProfile.specialization.ilike(f"%{specialization}%"))
    if religion:
        query = query.filter(AdvisorProfile.religion.ilike(f"%{religion}%"))
    if is_physical is not None:
        query = query.filter(AdvisorProfile.is_physical_available == is_physical)

    advisors = query.all()
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
    """Get a specific advisor's profile (hides blocked)."""
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.id == advisor_id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")
        
    if advisor.is_blocked:
        raise HTTPException(status_code=404, detail="Advisor profile is no longer available")
        
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
    if profile_data.location is not None:
        advisor.location = profile_data.location
    if profile_data.birthday is not None:
        advisor.birthday = profile_data.birthday
    if profile_data.contact_number is not None:
        advisor.contact_number = profile_data.contact_number
    if profile_data.is_physical_available is not None:
        advisor.is_physical_available = profile_data.is_physical_available
    if profile_data.is_virtual_available is not None:
        advisor.is_virtual_available = profile_data.is_virtual_available
    if profile_data.is_online is not None:
        advisor.is_online = profile_data.is_online
    if profile_data.office_address is not None:
        advisor.office_address = profile_data.office_address
    if profile_data.religion is not None:
        advisor.religion = profile_data.religion

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


@router.post("/me/upload-certificate", response_model=AdvisorProfileResponse)
async def upload_certificate(
    file: UploadFile = File(...),
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Upload a certificate PDF for verification. Resets verification status to pending."""
    advisor = (
        db.query(AdvisorProfile)
        .filter(AdvisorProfile.user_id == current_user.id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor profile not found")

    # Validate file type
    ext = file.filename.split(".")[-1].lower() if file.filename else ""
    if ext not in ["jpg", "jpeg", "png", "webp"]:
        raise HTTPException(status_code=400, detail="Only image files (jpg, jpeg, png, webp) are allowed.")

    # Save file
    filename = f"cert_{current_user.id}_{uuid.uuid4().hex}.{ext}"
    upload_dir = "static/certificates"
    os.makedirs(upload_dir, exist_ok=True)
    filepath = os.path.join(upload_dir, filename)

    try:
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {e}")

    # Update advisor profile: set PDF path + reset verification to pending
    advisor.certificate_pdf = f"/static/certificates/{filename}"
    advisor.verification_status = VerificationStatus.pending
    advisor.is_verified = False
    db.commit()
    db.refresh(advisor)

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
    """Verify an advisor (Admin only). Sets is_verified=True and verification_status=approved."""
    advisor = (
        db.query(AdvisorProfile)
        .options(joinedload(AdvisorProfile.user))
        .filter(AdvisorProfile.id == advisor_id)
        .first()
    )
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")

    # Toggle: if currently verified -> unverify, else verify
    if advisor.is_verified:
        advisor.is_verified = False
        advisor.verification_status = VerificationStatus.rejected
    else:
        advisor.is_verified = True
        advisor.verification_status = VerificationStatus.approved

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
    total_revenue = float(db.query(func.sum(Payment.amount)).join(Booking).filter(Booking.advisor_id == advisor.id).scalar() or 0.0)
    
    # 30% Commission Logic
    commission_rate = 0.30
    commission_cut = total_revenue * commission_rate
    net_revenue = total_revenue - commission_cut
    
    # Withdrawal Logic
    from models.user import PayoutRequest, PayoutStatus
    total_withdrawn = float(db.query(func.sum(PayoutRequest.amount)).filter(
        PayoutRequest.advisor_id == advisor.id,
        PayoutRequest.status.in_([PayoutStatus.approved, PayoutStatus.completed])
    ).scalar() or 0.0)

    available_balance = net_revenue - total_withdrawn

    return {
        "total_bookings": total_bookings,
        "rating": advisor.rating,
        "total_reviews": advisor.total_reviews,
        "total_revenue": total_revenue,
        "commission_cut": commission_cut,
        "net_revenue": net_revenue,
        "withdrawn_amount": total_withdrawn,
        "available_balance": available_balance,
    }


@router.get("/me/reviews", response_model=List[ReviewResponse])
async def get_my_reviews(
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Get all reviews for the current advisor."""
    from models.user import Review
    
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == current_user.id).first()
    if not advisor:
         raise HTTPException(status_code=404, detail="Advisor not found")

    reviews = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.advisor_id == advisor.id)
        .order_by(Review.created_at.desc())
        .all()
    )
    return [ReviewResponse.model_validate(r) for r in reviews]


@router.post("/me/reviews/{review_id}/reply", response_model=ReviewResponse)
async def reply_to_review(
    review_id: int,
    reply_data: ReviewReply,
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Add a reply to a review."""
    from models.user import Review
    from datetime import datetime
    
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == current_user.id).first()
    if not advisor:
         raise HTTPException(status_code=404, detail="Advisor not found")

    review = db.query(Review).filter(
        Review.id == review_id, 
        Review.advisor_id == advisor.id
    ).first()
    
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    review.advisor_reply = reply_data.reply
    review.replied_at = datetime.now()
    
    db.commit()
    db.refresh(review)
    
    # Reload with user relationship
    review = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.id == review.id)
        .first()
    )
    return ReviewResponse.model_validate(review)
