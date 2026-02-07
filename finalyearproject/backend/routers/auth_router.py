from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from config.database import get_db
from models.user import User, AdvisorProfile, UserRole
from schemas.user_schema import UserRegister, UserLogin, Token, UserResponse, EmailRequest, VerifyOTP, ResetPassword, ChangePassword
from services.auth_service import hash_password, verify_password, create_access_token
from services.email_service import generate_otp, send_otp_email
from middleware.auth_middleware import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """Register a new user, generating an OTP instead of immediate JWT access."""
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        if existing_user.is_email_verified:
            raise HTTPException(status_code=400, detail="Email already registered and verified.")
        else:
            # Reusing existing unverified row
            new_user = existing_user
            new_user.full_name = user_data.full_name
            new_user.password_hash = hash_password(user_data.password)
            new_user.phone = user_data.phone
            new_user.role = UserRole(user_data.role.value)
            new_user.location = user_data.location
            new_user.pob = user_data.pob
            new_user.lat = user_data.lat
            new_user.lon = user_data.lon
    else:
        new_user = User(
            full_name=user_data.full_name,
            email=user_data.email,
            password_hash=hash_password(user_data.password),
            phone=user_data.phone,
            role=UserRole(user_data.role.value),
            location=user_data.location,
            pob=user_data.pob,
            lat=user_data.lat,
            lon=user_data.lon,
            is_email_verified=False
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

    # Generate an OTP
    otp = generate_otp()
    new_user.otp_code = otp
    new_user.otp_expiry = datetime.utcnow() + timedelta(minutes=10)
    db.commit()

    # Dispatch email sending to background process
    background_tasks.add_task(send_otp_email, new_user.email, otp)
    
    return {"success": True, "message": f"An OTP has been sent to {user_data.email}. Please verify your account."}

@router.post("/verify-registration", response_model=Token)
async def verify_registration(data: VerifyOTP, db: Session = Depends(get_db)):
    """Verify the registration OTP."""
    user = db.query(User).filter(User.email == data.email).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    if user.is_email_verified:
        raise HTTPException(status_code=400, detail="User is already verified. Please login.")
    if user.otp_code != data.otp or user.otp_expiry < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invalid or expired OTP.")

    # Mark as verified and clear OTP
    user.is_email_verified = True
    user.otp_code = None
    user.otp_expiry = None
    
    # Generate Profile for Advisor if applicable
    if user.role == UserRole.advisor:
        existing_profile = db.query(AdvisorProfile).filter(AdvisorProfile.user_id == user.id).first()
        if not existing_profile:
            advisor_profile = AdvisorProfile(user_id=user.id)
            db.add(advisor_profile)
    
    db.commit()
    db.refresh(user)

    # Verification successful -> Login and return JWT
    access_token = create_access_token(data={"user_id": user.id, "email": user.email, "role": user.role.value})
    return Token(access_token=access_token, user=UserResponse.model_validate(user))

@router.post("/login", response_model=Token)
async def login(credentials: UserLogin, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """Login with email and password. Raises error if OTP is required for verification."""
    user = db.query(User).filter(User.email == credentials.email).first()

    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password.")
    
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated.")

    if not user.is_email_verified:
        # Re-send OTP automatically and alert user
        otp = generate_otp()
        user.otp_code = otp
        user.otp_expiry = datetime.utcnow() + timedelta(minutes=10)
        db.commit()
        background_tasks.add_task(send_otp_email, user.email, otp)
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Email is not verified. A new OTP has been sent to your email.")

    # Everything checks out -> Login and return JWT
    access_token = create_access_token(data={"user_id": user.id, "email": user.email, "role": user.role.value})
    return Token(access_token=access_token, user=UserResponse.model_validate(user))

@router.post("/forgot-password")
async def forgot_password(data: EmailRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """Generate and dispatch an OTP to reset the user's password."""
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        return {"success": True, "message": "If that email exists, an OTP has been sent."} # Soft fail for security

    otp = generate_otp()
    user.otp_code = otp
    user.otp_expiry = datetime.utcnow() + timedelta(minutes=10)
    db.commit()

    background_tasks.add_task(send_otp_email, user.email, otp)
    return {"success": True, "message": "An OTP has been sent to your email."}

@router.post("/reset-password")
async def reset_password(data: ResetPassword, db: Session = Depends(get_db)):
    """Using an OTP, reset a password without being logged in."""
    user = db.query(User).filter(User.email == data.email).first()

    if not user or user.otp_code != data.otp or user.otp_expiry < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invalid or expired OTP.")

    # Authorized: Overwrite password hash
    user.password_hash = hash_password(data.new_password)
    user.otp_code = None
    user.otp_expiry = None
    db.commit()

    return {"success": True, "message": "Your password has been reset successfully. Please login."}

@router.post("/change-password")
async def change_password(
    data: ChangePassword,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Change password for a logged-in user."""
    if not verify_password(data.old_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect old password.")
    
    current_user.password_hash = hash_password(data.new_password)
    db.commit()
    
    return {"success": True, "message": "Password updated successfully."}
