from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    user = "user"
    advisor = "advisor"
    admin = "admin"


# ---------- Auth Schemas ----------
class UserRegister(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., max_length=150)
    password: str = Field(..., min_length=6)
    phone: Optional[str] = None
    role: UserRole = UserRole.user


class UserLogin(BaseModel):
    email: str
    password: str


class EmailRequest(BaseModel):
    email: EmailStr


class VerifyOTP(BaseModel):
    email: EmailStr
    otp: str


class ResetPassword(BaseModel):
    email: EmailStr
    otp: str
    new_password: str = Field(..., min_length=6)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class TokenData(BaseModel):
    user_id: int
    email: str
    role: str


# ---------- User Response Schemas ----------
class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone: Optional[str] = None
    profile_image: Optional[str] = None
    role: str
    is_active: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None


# ---------- Advisor Schemas ----------
class AdvisorProfileCreate(BaseModel):
    bio: Optional[str] = None
    specialization: Optional[str] = None
    experience_years: int = 0
    hourly_rate: float = 0.0


class AdvisorProfileResponse(BaseModel):
    id: int
    user_id: int
    bio: Optional[str] = None
    specialization: Optional[str] = None
    experience_years: int
    hourly_rate: float
    rating: float
    total_reviews: int
    is_verified: bool
    user: Optional[UserResponse] = None

    class Config:
        from_attributes = True


class AdvisorProfileUpdate(BaseModel):
    bio: Optional[str] = None
    specialization: Optional[str] = None
    experience_years: Optional[int] = None
    hourly_rate: Optional[float] = None
    available_slots: Optional[dict] = None


# ---------- Booking Schemas ----------
class BookingCreate(BaseModel):
    advisor_id: int
    booking_date: str
    start_time: str
    end_time: str
    consultation_type: str = "chat"
    amount: float = 0.0


class BookingResponse(BaseModel):
    id: int
    user_id: int
    advisor_id: int
    booking_date: datetime
    start_time: str
    end_time: str
    status: str
    consultation_type: str
    amount: float
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class BookingStatusUpdate(BaseModel):
    status: str


# ---------- Review Schemas ----------
class ReviewCreate(BaseModel):
    booking_id: int
    advisor_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class ReviewResponse(BaseModel):
    id: int
    booking_id: int
    user_id: int
    advisor_id: int
    rating: int
    comment: Optional[str] = None
    created_at: Optional[datetime] = None
    user: Optional[UserResponse] = None

    class Config:
        from_attributes = True


# ---------- Report Schemas ----------
class ReportCreate(BaseModel):
    reported_advisor_id: int
    reason: str
    description: Optional[str] = None


class ReportResponse(BaseModel):
    id: int
    reporter_id: int
    reported_advisor_id: int
    reason: str
    description: Optional[str] = None
    status: str
    admin_notes: Optional[str] = None
    created_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ReportUpdate(BaseModel):
    status: Optional[str] = None
    admin_notes: Optional[str] = None


# ---------- Payment Schemas ----------
class PaymentCreate(BaseModel):
    booking_id: int
    amount: float
    transaction_id: Optional[str] = None
    payment_method: str = "khalti"


class PaymentResponse(BaseModel):
    id: int
    booking_id: int
    user_id: int
    amount: float
    transaction_id: Optional[str] = None
    status: str
    payment_method: str
    paid_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ---------- Chat Schemas ----------
class ChatMessageResponse(BaseModel):
    id: int
    room_id: int
    sender_id: int
    content: str
    timestamp: datetime
    is_read: bool

    class Config:
        from_attributes = True


class ChatRoomResponse(BaseModel):
    id: int
    booking_id: int
    user_id: int
    advisor_id: int
    is_active: bool
    created_at: datetime
    messages: Optional[list[ChatMessageResponse]] = []

    class Config:
        from_attributes = True
