from sqlalchemy import (
    Column, Integer, String, Text, Boolean, DateTime, Enum, 
    Float, ForeignKey, Time, JSON
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from config.database import Base
import enum


# ---------- Enums ----------
class UserRole(str, enum.Enum):
    user = "user"
    advisor = "advisor"
    admin = "admin"


class BookingStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    completed = "completed"
    cancelled = "cancelled"


class ConsultationType(str, enum.Enum):
    chat = "chat"
    voice = "voice"
    video = "video"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"


class ReportStatus(str, enum.Enum):
    pending = "pending"
    reviewed = "reviewed"
    resolved = "resolved"
    dismissed = "dismissed"


class CallStatus(str, enum.Enum):
    initiated = "initiated"
    ongoing = "ongoing"
    completed = "completed"
    missed = "missed"


# ---------- Models ----------
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    full_name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=True)
    profile_image = Column(String(255), nullable=True)
    role = Column(Enum(UserRole), default=UserRole.user, nullable=False)
    is_active = Column(Boolean, default=True)
    is_email_verified = Column(Boolean, default=False)
    otp_code = Column(String(6), nullable=True)
    otp_expiry = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationships
    advisor_profile = relationship("AdvisorProfile", back_populates="user", uselist=False)
    bookings = relationship("Booking", back_populates="user", foreign_keys="Booking.user_id")
    payments = relationship("Payment", back_populates="user")
    reviews = relationship("Review", back_populates="user", foreign_keys="Review.user_id")
    reports_filed = relationship("Report", back_populates="reporter", foreign_keys="Report.reporter_id")


class AdvisorProfile(Base):
    __tablename__ = "advisor_profiles"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    bio = Column(Text, nullable=True)
    specialization = Column(String(200), nullable=True)
    experience_years = Column(Integer, default=0)
    hourly_rate = Column(Float, default=0.0)
    rating = Column(Float, default=0.0)
    total_reviews = Column(Integer, default=0)
    is_verified = Column(Boolean, default=False)
    verification_doc = Column(String(255), nullable=True)
    available_slots = Column(JSON, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="advisor_profile")
    bookings = relationship("Booking", back_populates="advisor", foreign_keys="Booking.advisor_id")
    reviews = relationship("Review", back_populates="advisor", foreign_keys="Review.advisor_id")
    reports = relationship("Report", back_populates="reported_advisor", foreign_keys="Report.reported_advisor_id")


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    advisor_id = Column(Integer, ForeignKey("advisor_profiles.id"), nullable=False)
    booking_date = Column(DateTime, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    status = Column(Enum(BookingStatus), default=BookingStatus.pending)
    consultation_type = Column(Enum(ConsultationType), default=ConsultationType.chat)
    amount = Column(Float, default=0.0)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="bookings", foreign_keys=[user_id])
    advisor = relationship("AdvisorProfile", back_populates="bookings", foreign_keys=[advisor_id])
    payment = relationship("Payment", back_populates="booking", uselist=False)
    review = relationship("Review", back_populates="booking", uselist=False)
    chat_room = relationship("ChatRoom", back_populates="booking", uselist=False)
    call_logs = relationship("CallLog", back_populates="booking")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    transaction_id = Column(String(255), nullable=True)
    status = Column(Enum(PaymentStatus), default=PaymentStatus.pending)
    payment_method = Column(String(50), default="khalti")
    paid_at = Column(DateTime, nullable=True)

    # Relationships
    booking = relationship("Booking", back_populates="payment")
    user = relationship("User", back_populates="payments")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    advisor_id = Column(Integer, ForeignKey("advisor_profiles.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    booking = relationship("Booking", back_populates="review")
    user = relationship("User", back_populates="reviews", foreign_keys=[user_id])
    advisor = relationship("AdvisorProfile", back_populates="reviews", foreign_keys=[advisor_id])


class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reported_advisor_id = Column(Integer, ForeignKey("advisor_profiles.id"), nullable=False)
    reason = Column(Text, nullable=False)
    description = Column(Text, nullable=True)
    status = Column(Enum(ReportStatus), default=ReportStatus.pending)
    admin_notes = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    resolved_at = Column(DateTime, nullable=True)

    # Relationships
    reporter = relationship("User", back_populates="reports_filed", foreign_keys=[reporter_id])
    reported_advisor = relationship("AdvisorProfile", back_populates="reports", foreign_keys=[reported_advisor_id])


class ChatRoom(Base):
    __tablename__ = "chat_rooms"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    advisor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    booking = relationship("Booking", back_populates="chat_room")


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
