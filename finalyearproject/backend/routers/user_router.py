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
from services.astro_service import AstroService

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
    
    # New profile fields
    if user_data.location is not None:
        current_user.location = user_data.location
    if user_data.dob is not None:
        current_user.dob = user_data.dob
    if user_data.tob is not None:
        current_user.tob = user_data.tob
    if user_data.pob is not None:
        current_user.pob = user_data.pob
    if user_data.lat is not None:
        current_user.lat = user_data.lat
    if user_data.lon is not None:
        current_user.lon = user_data.lon
    if user_data.birth_chart_svg is not None:
        current_user.birth_chart_svg = user_data.birth_chart_svg
    if user_data.planet_details is not None:
        current_user.planet_details = user_data.planet_details

    # Auto-generate and cache birth chart if all required fields are present
    if current_user.dob and current_user.tob and current_user.lat and current_user.lon:
        try:
            # We assume NPT (+5.75) for now as default, or we can calculate based on location
            tz = 5.75
            chart_svg = await AstroService.get_chart_image(
                dob=current_user.dob, 
                tob=current_user.tob, 
                lat=current_user.lat, 
                lon=current_user.lon, 
                tz=tz
            )
            planet_details = await AstroService.get_birth_details(
                dob=current_user.dob, 
                tob=current_user.tob, 
                lat=current_user.lat, 
                lon=current_user.lon, 
                tz=tz
            )
            
            if chart_svg:
                current_user.birth_chart_svg = chart_svg
            if planet_details:
                current_user.planet_details = planet_details
                
        except Exception as e:
            # Log error but don't fail the profile update
            print(f"Failed to auto-generate cached birth chart: {str(e)}")

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


# ---------- Favorites ----------

@router.post("/me/favorites/{advisor_id}")
async def toggle_favorite(
    advisor_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Toggle an advisor in the user's favorites list."""
    from models.user import FavoriteAdvisor, AdvisorProfile
    
    # Check if advisor exists
    advisor = db.query(AdvisorProfile).filter(AdvisorProfile.id == advisor_id).first()
    if not advisor:
        raise HTTPException(status_code=404, detail="Advisor not found")

    # Check if favorite already exists
    existing_fav = db.query(FavoriteAdvisor).filter(
        FavoriteAdvisor.user_id == current_user.id,
        FavoriteAdvisor.advisor_id == advisor_id
    ).first()

    if existing_fav:
        # Remove favorite
        db.delete(existing_fav)
        db.commit()
        return {"status": "removed", "advisor_id": advisor_id}
    else:
        # Add favorite
        new_fav = FavoriteAdvisor(user_id=current_user.id, advisor_id=advisor_id)
        db.add(new_fav)
        db.commit()
        return {"status": "added", "advisor_id": advisor_id}


@router.get("/me/favorites")
async def get_favorites(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a list of all advisor_ids that the current user has favorited."""
    from models.user import FavoriteAdvisor
    
    favs = db.query(FavoriteAdvisor).filter(FavoriteAdvisor.user_id == current_user.id).all()
    return {"favorite_advisor_ids": [f.advisor_id for f in favs]}

