from fastapi import APIRouter, HTTPException
from typing import Dict, Any, List
from services.horoscope_service import HoroscopeService

router = APIRouter(prefix="/horoscope", tags=["Horoscope"])

@router.get("/daily", response_model=Dict[str, Any])
async def get_all_horoscopes():
    """Get daily horoscopes for all 12 rashi (zodiac signs)."""
    return await HoroscopeService.get_daily_horoscope()

@router.get("/daily/{sign_index}", response_model=Dict[str, Any])
async def get_sign_horoscope(sign_index: int):
    """Get daily horoscope for a specific rashi (1-12)."""
    if not (1 <= sign_index <= 12):
        raise HTTPException(status_code=400, detail="Sign index must be between 1 and 12")
    
    data = await HoroscopeService.get_sign_horoscope(sign_index)
    if not data:
        raise HTTPException(status_code=404, detail="Horoscope not found for this sign")
    
    return data

@router.get("/summary", response_model=Dict[str, Any])
async def get_daily_insight():
    """Get daily calendar info (panchang, etc)."""
    data = await HoroscopeService.get_calendar_info()
    if not data:
         raise HTTPException(status_code=404, detail="Daily insight unavailable")
    return data
