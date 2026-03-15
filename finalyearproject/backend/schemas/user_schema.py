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
    location: Optional[str] = None
    pob: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None


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


class ChangePassword(BaseModel):
    old_password: str
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
    location: Optional[str] = None
    dob: Optional[str] = None
    tob: Optional[str] = None
    pob: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    birth_chart_svg: Optional[str] = None
    planet_details: Optional[dict] = None

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None
    location: Optional[str] = None
    dob: Optional[str] = None
    tob: Optional[str] = None
    pob: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None
    birth_chart_svg: Optional[str] = None
    planet_details: Optional[dict] = None


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
    verification_doc: Optional[str] = None
    verification_status: Optional[str] = "pending"
    location: Optional[str] = None
    birthday: Optional[str] = None
    contact_number: Optional[str] = None
    certificate_pdf: Optional[str] = None
    is_blocked: Optional[bool] = False
    is_physical_available: bool = False
    is_virtual_available: bool = True
    is_online: bool = True
    office_address: Optional[str] = None
    religion: Optional[str] = None
    available_slots: Optional[dict] = None
    user: Optional[UserResponse] = None

    class Config:
        from_attributes = True


class AdvisorProfileUpdate(BaseModel):
    bio: Optional[str] = None
    specialization: Optional[str] = None
    experience_years: Optional[int] = None
    hourly_rate: Optional[float] = None
    available_slots: Optional[dict] = None
    verification_doc: Optional[str] = None
    location: Optional[str] = None
    birthday: Optional[str] = None
    contact_number: Optional[str] = None
    is_physical_available: Optional[bool] = None
    is_virtual_available: Optional[bool] = None
    is_online: Optional[bool] = None
    office_address: Optional[str] = None
    religion: Optional[str] = None


# ---------- Booking Schemas ----------
class BookingCreate(BaseModel):
    advisor_id: int
    booking_date: str
    start_time: str
    end_time: str
    consultation_type: str = "chat"
    amount: float = 0.0
    meeting_location: Optional[str] = None


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
    meeting_location: Optional[str] = None
    user_name: Optional[str] = None
    user_image: Optional[str] = None
    advisor_name: Optional[str] = None
    advisor_image: Optional[str] = None
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
    advisor_reply: Optional[str] = None
    replied_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    user: Optional[UserResponse] = None

    class Config:
        from_attributes = True


class ReviewReply(BaseModel):
    reply: str = Field(..., min_length=1)


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
    reporter_name: Optional[str] = None
    reported_advisor_name: Optional[str] = None
    room_id: Optional[int] = None
    booking_id: Optional[int] = None

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
    message_type: str = "text"
    content: str
    timestamp: datetime
    is_read: bool

    class Config:
        from_attributes = True


class ChatRoomResponse(BaseModel):
    id: int
    booking_id: Optional[int] = None
    user_id: int
    advisor_id: int
    is_active: bool
    created_at: datetime
    user_name: Optional[str] = None
    user_image: Optional[str] = None
    advisor_name: Optional[str] = None
    advisor_image: Optional[str] = None
    messages: Optional[list[ChatMessageResponse]] = []

    class Config:
        from_attributes = True


# ---------- Payout Schemas ----------
class PayoutRequestCreate(BaseModel):
    amount: float = Field(..., ge=500)
    payment_details: str

class PayoutRequestResponse(BaseModel):
    id: int
    advisor_id: int
    amount: float
    payment_details: str
    status: str
    admin_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    advisor: Optional[AdvisorProfileResponse] = None

    class Config:
        from_attributes = True

class PayoutStatusUpdate(BaseModel):
    status: str
    admin_notes: Optional[str] = None


# ---------- Notification Schemas ----------
class NotificationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


