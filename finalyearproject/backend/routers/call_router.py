from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from config.database import get_db
from models.user import User, Booking, CallLog, CallStatus, ConsultationType, ChatRoom, ChatMessage
from middleware.auth_middleware import get_current_user
from services.agora_service import agora_service
from config.settings import settings
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

router = APIRouter(prefix="/call", tags=["Calls"])

class CallInitiateRequest(BaseModel):
    booking_id: int
    call_type: str  # "voice" or "video"

class CallEndRequest(BaseModel):
    call_log_id: int
    duration_seconds: int

@router.post("/initiate")
async def initiate_call(
    payload: CallInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initiate a call and get an Agora token."""
    booking = db.query(Booking).filter(Booking.id == payload.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Verify authorization (Support both User ID and Advisor's User ID)
    is_authorized = (booking.user_id == current_user.id or booking.advisor.user_id == current_user.id)
    if not is_authorized:
        raise HTTPException(status_code=403, detail=f"Not authorized. User ID: {current_user.id}")

    # Automatically clear any active calls for this booking to allow instant retries
    active_call = db.query(CallLog).filter(
        CallLog.booking_id == payload.booking_id,
        CallLog.status.in_([CallStatus.initiated, CallStatus.ongoing])
    ).first()
    
    if active_call:
        active_call.status = CallStatus.missed
        active_call.ended_at = datetime.utcnow()
        db.commit()

    # Determine caller/receiver correctly
    receiver_id = booking.advisor.user_id if booking.user_id == current_user.id else booking.user_id

    # Generate Token
    channel_name = f"booking_{booking.id}"
    token = agora_service.generate_rtc_token(channel_name)
    
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Agora credentials (APP_CERTIFICATE) are missing in the backend .env file. Please check your Agora Dashboard."
        )

    # Create Call Log
    call_log = CallLog(
        booking_id=booking.id,
        caller_id=current_user.id,
        receiver_id=receiver_id,
        call_type=ConsultationType(payload.call_type),
        status=CallStatus.initiated,
        started_at=datetime.utcnow()
    )
    db.add(call_log)
    db.commit()
    db.refresh(call_log)
    
    # 2. Add message to chat room for history
    if booking.chat_room:
        chat_msg = ChatMessage(
            room_id=booking.chat_room.id,
            sender_id=current_user.id,
            content=f"📞 {payload.call_type.capitalize()} call started"
        )
        db.add(chat_msg)
        db.commit()

    return {
        "call_log_id": call_log.id,
        "token": token,
        "channel_name": channel_name,
        "app_id": settings.AGORA_APP_ID
    }

@router.post("/end")
async def end_call(
    payload: CallEndRequest,
    db: Session = Depends(get_db)
):
    """Log the end of a call."""
    call_log = db.query(CallLog).filter(CallLog.id == payload.call_log_id).first()
    if not call_log:
        raise HTTPException(status_code=404, detail="Call log not found")

    call_log.duration_seconds = payload.duration_seconds
    call_log.status = CallStatus.completed
    call_log.ended_at = datetime.utcnow()
    db.commit()
    
    # 2. Add message to chat room for history
    booking = call_log.booking
    if booking and booking.chat_room:
        mins = payload.duration_seconds // 60
        secs = payload.duration_seconds % 60
        duration_str = f"{mins}m {secs}s" if mins > 0 else f"{secs}s"
        
        chat_msg = ChatMessage(
            room_id=booking.chat_room.id,
            sender_id=call_log.caller_id, # Attribute ending to the room
            content=f"📞 Call ended ({duration_str})"
        )
        db.add(chat_msg)
        db.commit()
    
    return {"message": "Call log updated successfully"}
