from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from typing import List
import os
import uuid
import shutil
from config.database import get_db
from models.user import User
from schemas.user_schema import UserResponse, UserUpdate
from middleware.auth_middleware import get_current_user, require_role

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Get the current authenticated user's profile."""
    return UserResponse.model_validate(current_user)


@router.put("/me", response_model=UserResponse)
async def update_profile(
    user_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the current user's profile."""
    if user_data.full_name is not None:
        current_user.full_name = user_data.full_name
    if user_data.phone is not None:
        current_user.phone = user_data.phone
    if user_data.profile_image is not None:
        current_user.profile_image = user_data.profile_image

    db.commit()
    db.refresh(current_user)
    return UserResponse.model_validate(current_user)


@router.post("/upload-profile-image", response_model=UserResponse)
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload a profile image for the current user."""
    # Check extension
    ext = file.filename.split(".")[-1].lower()
    if ext not in ["jpg", "jpeg", "png"]:
        raise HTTPException(status_code=400, detail="Invalid file type. Only JPG, JPEG, and PNG are allowed.")

    # Create unique filename
    filename = f"{current_user.id}_{uuid.uuid4().hex}.{ext}"
    upload_dir = "static/profile_images"
    os.makedirs(upload_dir, exist_ok=True)
    filepath = os.path.join(upload_dir, filename)

    # Save file
    try:
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {e}")

    # Update user model
    # Note: On production this should be a full URL, but here we return a relative path or we can prefix it
    # For simplicity, returning the relative path
    current_user.profile_image = f"/static/profile_images/{filename}"
    db.commit()
    db.refresh(current_user)
    return UserResponse.model_validate(current_user)


@router.get("/", response_model=List[UserResponse])
async def get_all_users(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Get all users (Admin only)."""
    users = db.query(User).all()
    return [UserResponse.model_validate(u) for u in users]


@router.put("/{user_id}/toggle-active", response_model=UserResponse)
async def toggle_user_active(
    user_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Activate or deactivate a user (Admin only)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_active = not user.is_active
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)
