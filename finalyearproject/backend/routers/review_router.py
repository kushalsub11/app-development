from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List
from config.database import get_db
from models.user import User, Review, AdvisorProfile, Booking
from schemas.user_schema import ReviewCreate, ReviewResponse
from middleware.auth_middleware import get_current_user

router = APIRouter(prefix="/reviews", tags=["Reviews"])


@router.post("/", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    review_data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Submit a review for a completed booking."""
    # Verify booking exists and belongs to user
    booking = db.query(Booking).filter(Booking.id == review_data.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your booking")

    # Check if review already exists
    existing = db.query(Review).filter(Review.booking_id == review_data.booking_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Review already submitted for this booking")

    new_review = Review(
        booking_id=review_data.booking_id,
        user_id=current_user.id,
        advisor_id=review_data.advisor_id,
        rating=review_data.rating,
        comment=review_data.comment,
    )
    db.add(new_review)

    # Update advisor rating
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.id == review_data.advisor_id).first()
    if advisor:
        total = advisor.rating * advisor.total_reviews + review_data.rating
        advisor.total_reviews += 1
        advisor.rating = round(total / advisor.total_reviews, 2)

    db.commit()
    db.refresh(new_review)
    return ReviewResponse.model_validate(new_review)


@router.get("/advisor/{advisor_id}", response_model=List[ReviewResponse])
async def get_advisor_reviews(advisor_id: int, db: Session = Depends(get_db)):
    """Get all reviews for a specific advisor."""
    reviews = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.advisor_id == advisor_id)
        .order_by(Review.created_at.desc())
        .all()
    )
    return [ReviewResponse.model_validate(r) for r in reviews]
