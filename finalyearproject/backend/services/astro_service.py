import requests
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class AstroService:
    BASE_URL = "https://api.vedicastroapi.com/v3-json/"
    API_KEY = "358c335c-e22b-5bb0-82eb-bbe91d2e8eae"

    @classmethod
    async def get_chart_image(cls, dob: str, tob: str, lat: float, lon: float, tz: float, div: str = "D1", style: str = "north") -> Optional[str]:
        """
        Generate a birth chart image URL.
        dob: DD/MM/YYYY
        tob: HH:MM
        tz: e.g. 5.5 for IST, 5.75 for NPT
        """
        params = {
            "dob": dob,
            "tob": tob,
            "lat": lat,
            "lon": lon,
            "tz": tz,
            "div": div,
            "style": style,
            "format": "url",
            "api_key": cls.API_KEY,
            "lang": "en"
        }
        try:
            url = f"{cls.BASE_URL}horoscope/chart-image"
            response = requests.get(url, params=params, timeout=15)
            response.raise_for_status()
            data = response.json()
            
            if data.get("status") == 200:
                return data.get("response") # This should be the SVG URL
            return None
        except Exception as e:
            logger.error(f"Error fetching chart image: {e}")
            return None

    @classmethod
    async def get_birth_details(cls, dob: str, tob: str, lat: float, lon: float, tz: float) -> Optional[Dict]:
        """
        Get detailed birth info (Ascendant, Nakshatra, etc.)
        """
        params = {
            "dob": dob,
            "tob": tob,
            "lat": lat,
            "lon": lon,
            "tz": tz,
            "api_key": cls.API_KEY,
            "lang": "en"
        }
        try:
            # We can use the 'horoscope/basic-details' or 'horoscope/planet-details'
            url = f"{cls.BASE_URL}horoscope/planet-details"
            response = requests.get(url, params=params, timeout=15)
            response.raise_for_status()
            data = response.json()
            
            if data.get("status") == 200:
                return data.get("response")
            return None
        except Exception as e:
            logger.error(f"Error fetching birth details: {e}")
            return None
