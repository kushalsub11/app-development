import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class HoroscopeService:
    BASE_URL = "https://www.hamropatro.com/rashifal"
    
    RASHI_MAP = [
        "Mesh", "Brush", "Mithun", "Karkat", 
        "Singha", "Kanya", "Tula", "Brischik", 
        "Dhanu", "Makar", "Kumbha", "Meen"
    ]

    @classmethod
    async def get_daily_horoscope(cls) -> Dict:
        """Scrape daily horoscope from Hamro Patro."""
        try:
            response = requests.get(cls.BASE_URL, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'lxml')
            
            # Extract date - usually in the header or specific class
            # On current Hamro Patro, the date is often in a specific div
            date_element = soup.select_one('.horoscope-tabs h2')
            current_date = date_element.text.strip() if date_element else "Today"
            
            # Extract descriptions
            # The npm package used '.desc p'
            descriptions = soup.select('.desc p')
            
            horoscopes = []
            for i, desc in enumerate(descriptions[:12]):
                horoscopes.append({
                    "rashi": i + 1,
                    "name": cls.RASHI_MAP[i],
                    "text": desc.text.strip()
                })
            
            return {
                "date": current_date,
                "horoscopes": horoscopes
            }
        except Exception as e:
            logger.error(f"Error scraping horoscope: {e}")
            return {
                "date": "Error",
                "horoscopes": [],
                "error": str(e)
            }

    @classmethod
    async def get_sign_horoscope(cls, sign_index: int) -> Optional[Dict]:
        """Get horoscope for a specific sign (1-indexed)."""
        data = await cls.get_daily_horoscope()
        for h in data.get("horoscopes", []):
            if h["rashi"] == sign_index:
                return {
                    "date": data["date"],
                    "rashi": h["name"],
                    "text": h["text"]
                }
        return None

    @classmethod
    async def get_calendar_info(cls) -> Dict[str, str]:
        """Scrape calendar/panchang info from Hamro Patro."""
        try:
            response = requests.get("https://www.hamropatro.com/", timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'lxml')
            date_element = soup.select_one('.date')
            if not date_element:
                raise ValueError("Could not find calendar .date element")
                
            date_parent = date_element.parent
            texts = list(date_parent.stripped_strings)
            
            if len(texts) >= 5:
                nepali_date = texts[0]
                tithi = texts[1] if len(texts) > 1 else ""
                
                panchang = ""
                eng_date = ""
                for i, t in enumerate(texts):
                    if "पञ्चाङ्ग:" in t and i + 1 < len(texts):
                        panchang = texts[i+1]
                    if "," in t and ("202" in t or "203" in t) and "२०" not in t:
                        eng_date = t
                
                if not eng_date and len(texts) > 0:
                    eng_date = texts[-1]

                return {
                    "nepali_date": nepali_date,
                    "tithi": tithi,
                    "panchang": panchang,
                    "english_date": eng_date
                }
            return {
                "nepali_date": "Date unavailable",
                "tithi": "",
                "panchang": "",
                "english_date": ""
            }
        except Exception as e:
            logger.error(f"Error scraping calendar: {e}")
            return {
                "nepali_date": "Error loading calendar",
                "tithi": "",
                "panchang": "",
                "english_date": str(e)
            }
