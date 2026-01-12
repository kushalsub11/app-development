from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
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
