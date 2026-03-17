from fastapi import APIRouter, HTTPException, Query
from typing import Dict, Any, Optional
from services.astro_service import AstroService

router = APIRouter(prefix="/astro", tags=["Astro"])

@router.get("/birth-chart")
async def generate_birth_chart(
    dob: str = Query(..., description="DD/MM/YYYY"),
    tob: str = Query(..., description="HH:MM"),
    lat: float = Query(...),
    lon: float = Query(...),
    tz: float = Query(5.75, description="Timezone, default is NPT +5.75"),
    div: str = "D1",
    style: str = "north"
):
    """Generate birth chart image and basic details."""
    
    chart_svg = await AstroService.get_chart_image(dob, tob, lat, lon, tz, div, style)
    planet_details = await AstroService.get_birth_details(dob, tob, lat, lon, tz)
    
    if not chart_svg and not planet_details:
        raise HTTPException(status_code=500, detail="Unable to fetch birth data. Please check your details and try again.")
        
    return {
        "success": True,
        "chart_svg": chart_svg,
        "details": planet_details,
        "error": None if (chart_svg and planet_details) else "Partial data: Some chart elements could not be generated."
    }
