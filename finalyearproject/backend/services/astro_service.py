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
        Generate a birth chart image SVG using jyotichart.
        """
        try:
            import jyotichart
            
            # 1. Fetch planet details first to get positions
            details = await cls.get_birth_details(dob, tob, lat, lon, tz)
            if not details:
                return None
            
            # 2. Extract Ascendant (Lagna) sign index (1-12)
            asc_sign = 1
            planets_to_add = []
            
            # Standardize details to a list if it's a map (for numeric keys like "0", "1"...)
            details_list = []
            if isinstance(details, dict):
                try:
                    # Sort by numeric key if possible, else just take values
                    sorted_keys = sorted(details.keys(), key=lambda x: int(x) if x.isdigit() else 999)
                    details_list = [details[k] for k in sorted_keys]
                except:
                    details_list = list(details.values())
            else:
                details_list = details

            for p in details_list:
                if not isinstance(p, dict): continue
                name = p.get("full_name") or p.get("name", "")
                sign_num = p.get("rasi_no") or p.get("sign_id", 1) 
                house_num = p.get("house", 1)
                
                if name.lower() in ["ascendant", "as", "asc"]:
                    asc_sign = sign_num
                else:
                    # Map planet name to short symbol used in jyotichart
                    symbols = {"Sun": "Su", "Moon": "Mo", "Mars": "Ma", "Mercury": "Me", "Jupiter": "Ju", "Venus": "Ve", "Saturn": "Sa", "Rahu": "Ra", "Ketu": "Ke"}
                    symbol = symbols.get(name, name[:2])
                    planets_to_add.append((name, symbol, house_num))

            # 3. Create the chart using jyotichart
            import os
            import uuid
            
            # Using a unique filename to avoid collisions during concurrent requests
            fileId = str(uuid.uuid4())[:8]
            location = "."
            filename = f"chart_{fileId}"
            
            # Mapping sign IDs (1-12) to strings expected by jyotichart
            signs_list = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Saggitarius', 'Capricorn', 'Aquarius', 'Pisces']
            asc_sign_name = signs_list[asc_sign - 1] if 1 <= asc_sign <= 12 else "Aries"
            
            chart_obj = jyotichart.NorthChart(filename, "User", IsFullChart=False)
            chart_obj.set_ascendantsign(asc_sign_name)
            
            # Add planets to their respective houses
            for name, sym, house in planets_to_add:
                chart_obj.add_planet(name, sym, house)
            
            # Draw saves to {location}/{filename}.svg
            chart_obj.draw(location, filename)
            
            svg_path = os.path.join(location, f"{filename}.svg")
            svg_content = None
            
            if os.path.exists(svg_path):
                with open(svg_path, "r", encoding="utf-8") as f:
                    svg_content = f.read()
                os.remove(svg_path) # Clean up
                
            return svg_content

        except Exception as e:
            logger.error(f"Error generating jyotichart: {e}")
            # Fallback to external API if local generation fails
            return await cls._get_external_chart_image(dob, tob, lat, lon, tz, div, style)

    @classmethod
    async def _get_external_chart_image(cls, dob: str, tob: str, lat: float, lon: float, tz: float, div: str = "D1", style: str = "north") -> Optional[str]:
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
            endpoints = ["horoscope/chart-image", "horoscope/chart_image"]
            for endpoint in endpoints:
                url = f"{cls.BASE_URL}{endpoint}"
                logger.info(f"Fetching external chart image from {url}")
                response = requests.get(url, params=params, timeout=15)
                if response.status_code == 200 and "<svg" in response.text:
                    return response.text
                
                # Check for URL format too (some v3 endpoints return JSON with a URL)
                if response.status_code == 200:
                    try:
                        data = response.json()
                        if data.get("status") == 200 and data.get("response"):
                            resp = data.get("response")
                            if isinstance(resp, str) and "<svg" in resp:
                                return resp
                    except:
                        pass

            return None
        except Exception as e:
            logger.error(f"Error fetching external chart image: {e}")
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
            # Vedic Astro API v3 has multiple detail endpoints. Let's try planet-details first.
            endpoints = ["horoscope/planet-details", "horoscope/basic-details"]
            
            for endpoint in endpoints:
                url = f"{cls.BASE_URL}{endpoint}"
                logger.info(f"Fetching birth details from {url}")
                response = requests.get(url, params=params, timeout=15)
                
                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == 200:
                        return data.get("response")
                    else:
                        logger.warning(f"API Error from {endpoint}: {data.get('msg') or data.get('message')}")
                else:
                    logger.error(f"HTTP Error {response.status_code} from {endpoint}")
            
            return None
        except Exception as e:
            logger.error(f"Critical error fetching birth details: {e}")
            return None
