from sqlalchemy import Column, Integer, ForeignKey, Enum, DateTime
from sqlalchemy.orm import relationship
from config.database import Base

# Import enums and related models from user module
from .user import ConsultationType, CallStatus, Booking

class CallLog(Base):
    __tablename__ = "call_logs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    caller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    call_type = Column(Enum(ConsultationType), nullable=False)
    duration_seconds = Column(Integer, default=0)
    status = Column(Enum(CallStatus), default=CallStatus.initiated)
    started_at = Column(DateTime, nullable=True)
    ended_at = Column(DateTime, nullable=True)

    # Relationships
    booking = relationship("Booking", back_populates="call_logs")
