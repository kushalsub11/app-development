from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from config.database import get_db
from models.user import User, Booking, BookingStatus, ConsultationType, AdvisorProfile
from schemas.user_schema import BookingCreate, BookingResponse, BookingStatusUpdate
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
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
    if advisor.is_blocked:
        raise HTTPException(status_code=400, detail="Advisor is currently unavailable for new bookings")

    # Parse date and time
    try:
        booking_date = datetime.strptime(booking_data.booking_date, "%Y-%m-%d")
        start_time = datetime.strptime(booking_data.start_time, "%H:%M").time()
        end_time = datetime.strptime(booking_data.end_time, "%H:%M").time()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date/time format")

    # Validate booking is not in the past
    from datetime import date as date_type, time as time_type
    booking_datetime = datetime.combine(booking_date.date(), start_time)
    now = datetime.utcnow()
    # Use Nepal timezone offset (+5:45 = 345 minutes) for local comparison
    from datetime import timedelta
    nepal_offset = timedelta(hours=5, minutes=45)
    local_now = datetime.utcnow() + nepal_offset
    local_booking_dt = datetime.combine(booking_date.date(), start_time)
    if local_booking_dt < local_now:
        raise HTTPException(status_code=400, detail="Cannot book a past date or time. Please select a future slot.")

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

    # Validate against Advisor's Available Slots
    if advisor.available_slots:
        # Get weekday name
        days_of_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        weekday_name = days_of_week[booking_date.weekday()]
        
        day_slots = advisor.available_slots.get(weekday_name)
        if not day_slots:
            raise HTTPException(status_code=400, detail=f"Advisor is not available on {weekday_name}")
        
        # Check if requested time is within any slot
        is_within_availability = False
        requested_start_str = start_time.strftime("%H:%M")
        requested_end_str = end_time.strftime("%H:%M")
        
        for slot in day_slots:
            slot_start = slot.get('start')
            slot_end = slot.get('end')
            if slot_start and slot_end:
                # Simple string comparison works for HH:MM format
                if requested_start_str >= slot_start and requested_end_str <= slot_end:
                    is_within_availability = True
                    break
        
        if not is_within_availability:
            raise HTTPException(
                status_code=400, 
                detail=f"Requested time {requested_start_str}-{requested_end_str} is outside the advisor's working hours for {weekday_name}"
            )

    # Validate time range
    if end_time <= start_time:
        raise HTTPException(status_code=400, detail="End time must be after start time")

    # Calculate Duration and Amount
    # Convert to minutes for easier calculation
    start_minutes = start_time.hour * 60 + start_time.minute
    end_minutes = end_time.hour * 60 + end_time.minute
    duration_minutes = end_minutes - start_minutes
    duration_hours = duration_minutes / 60.0
    
    # Billing Logic: Minimum 1 hour charge, then proportional
    # user said: "minimum booking amount should be the amount with is per hr set by adviser"
    billing_hours = max(1.0, duration_hours)
    calculated_amount = billing_hours * advisor.hourly_rate

    new_booking = Booking(
        user_id=current_user.id,
        advisor_id=booking_data.advisor_id,
        booking_date=booking_date,
        start_time=start_time,
        end_time=end_time,
        consultation_type=ConsultationType(booking_data.consultation_type),
        amount=calculated_amount,
        meeting_location=booking_data.meeting_location,
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
    """Get bookings for the current user (hides blocked advisors)."""
    bookings = (
        db.query(Booking)
        .join(AdvisorProfile, Booking.advisor_id == AdvisorProfile.id)
        .filter(Booking.user_id == current_user.id, AdvisorProfile.is_blocked == False)
        .order_by(Booking.created_at.desc())
        .all()
    )
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
        meeting_location=booking.meeting_location,
        created_at=booking.created_at,
    )
