from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from config.database import get_db
from models.user import User, Booking, BookingStatus, ConsultationType, AdvisorProfile
from schemas.user_schema import BookingCreate, BookingResponse, BookingStatusUpdate
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.post("/", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new booking (User only)."""
    # Verify advisor exists
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.id == booking_data.advisor_id).first()
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")
    if not advisor.is_verified:
        raise HTTPException(status_code=400, detail="Advisor is not verified")

    # Parse date and time
    try:
        booking_date = datetime.strptime(booking_data.booking_date, "%Y-%m-%d")
        start_time = datetime.strptime(booking_data.start_time, "%H:%M").time()
        end_time = datetime.strptime(booking_data.end_time, "%H:%M").time()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date/time format")

    # Check for duplicate booking
    existing = (
        db.query(Booking)
        .filter(
            Booking.advisor_id == booking_data.advisor_id,
            Booking.booking_date == booking_date,
            Booking.start_time == start_time,
            Booking.status.in_([BookingStatus.pending, BookingStatus.confirmed]),
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="This time slot is already booked")

    new_booking = Booking(
        user_id=current_user.id,
        advisor_id=booking_data.advisor_id,
        booking_date=booking_date,
        start_time=start_time,
        end_time=end_time,
        consultation_type=ConsultationType(booking_data.consultation_type),
        amount=booking_data.amount,
    )
    db.add(new_booking)
    db.commit()
    db.refresh(new_booking)
    return _format_booking(new_booking)


@router.get("/my-bookings", response_model=List[BookingResponse])
async def get_my_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get bookings for the current user."""
    bookings = db.query(Booking).filter(Booking.user_id == current_user.id).order_by(Booking.created_at.desc()).all()
    return [_format_booking(b) for b in bookings]


@router.get("/advisor-bookings", response_model=List[BookingResponse])
async def get_advisor_bookings(
    current_user: User = Depends(require_role("advisor")),
    db: Session = Depends(get_db),
):
    """Get bookings for the current advisor."""
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == current_user.id).first()
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor profile not found")

    bookings = db.query(Booking).filter(Booking.advisor_id == advisor.id).order_by(Booking.created_at.desc()).all()
    return [_format_booking(b) for b in bookings]


@router.put("/{booking_id}/status", response_model=BookingResponse)
async def update_booking_status(
    booking_id: int,
    status_data: BookingStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update booking status (confirm, cancel, complete)."""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    booking.status = BookingStatus(status_data.status)
    db.commit()
    db.refresh(booking)
    return _format_booking(booking)


@router.get("/all", response_model=List[BookingResponse])
async def get_all_bookings(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all bookings (Admin only)."""
    bookings = db.query(Booking).order_by(Booking.created_at.desc()).all()
    return [_format_booking(b) for b in bookings]


def _format_booking(booking: Booking) -> BookingResponse:
    """Format booking response with string time fields."""
    return BookingResponse(
        id=booking.id,
        user_id=booking.user_id,
        advisor_id=booking.advisor_id,
        booking_date=booking.booking_date,
        start_time=str(booking.start_time),
        end_time=str(booking.end_time),
        status=booking.status.value,
        consultation_type=booking.consultation_type.value,
        amount=booking.amount,
        created_at=booking.created_at,
    )
