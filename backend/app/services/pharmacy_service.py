import httpx
from bs4 import BeautifulSoup
from typing import List, Dict, Any
import re
import unicodedata

class PharmacyService:
    @staticmethod
    def slugify(text: str) -> str:
        text = text.lower()
        replacements = {'ı': 'i', 'ş': 's', 'ç': 'c', 'ğ': 'g', 'ü': 'u', 'ö': 'o'}
        for old, new in replacements.items():
            text = text.replace(old, new)
        text = ''.join(c for c in text if c.isalnum() or c == '-')
        return text

    @classmethod
    async def get_on_duty_pharmacies(cls, city: str) -> List[Dict[str, Any]]:
        city_slug = cls.slugify(city)
        url = f"https://www.eczaneler.gen.tr/nobetci-{city_slug}"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
            "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, timeout=12.0)
            
        if response.status_code != 200:
            raise ValueError(f"Failed to fetch pharmacies from eczaneler.gen.tr. Status: {response.status_code}")
            
        soup = BeautifulSoup(response.text, "html.parser")
        
        district_links = soup.select('div.well ul.list-unstyled li a.aok')
        # If there are district links on the main page, fetch them all concurrently
        if district_links:
            import asyncio
            links_to_fetch = [f"https://www.eczaneler.gen.tr{a['href']}" for a in district_links]
            
            async def fetch_district(d_url: str):
                try:
                    async with httpx.AsyncClient() as c:
                        res = await c.get(d_url, headers=headers, timeout=10.0)
                        if res.status_code == 200:
                            s = BeautifulSoup(res.text, "html.parser")
                            district_from_url = d_url.split('-')[-1].lower()
                            pharms = cls._extract_pharmacies(s)
                            for p in pharms:
                                p["district"] = district_from_url
                            return pharms
                except Exception:
                    pass
                return []
            
            # Using semaphore to avoid hitting the rate limit
            sem = asyncio.Semaphore(10)
            async def fetch_with_sem(d_url):
                async with sem:
                    return await fetch_district(d_url)
            # For demonstration and performance, let's process all of them
            results = await asyncio.gather(*[fetch_with_sem(u) for u in links_to_fetch])
            all_pharmacies = []
            for r in results:
                all_pharmacies.extend(r)
            return all_pharmacies
        else:
            return cls._extract_pharmacies(soup)

    @classmethod
    def _extract_pharmacies(cls, soup: BeautifulSoup) -> List[Dict[str, Any]]:
        pharmacies = []
        
        rows = soup.select('div.card')
        if not rows:
            rows = soup.select('table tr')
            if not rows:
                 rows = soup.find_all('div', attrs={'class': re.compile(r'eczane', re.I)})
                 
        if not rows:
            titles = soup.find_all(['h5', 'h4', 'span'], string=re.compile(r'Eczane', re.I))
            for title in titles:
                name = title.text.strip()
                container = title.find_parent('div')
                if not container:
                    continue
                
                text_blocks = container.get_text(separator='|', strip=True).split('|')
                phone_match = re.search(r'0?\s?\(?\s?[1-9]\d{2}\s?\)?\s?\d{3}\s?[-]?\s?\d{2}\s?[-]?\s?\d{2}', container.text)
                phone = phone_match.group(0).strip() if phone_match else ""
                
                # Try map link
                lat, lng = 0.0, 0.0
                map_link = container.find('a', href=re.compile(r'google\.com/maps|yandex\.com/maps'))
                if map_link:
                    coords = re.search(r'(@|query=)([0-9.-]+),([0-9.-]+)', map_link.get('href', ''))
                    if coords:
                        lat, lng = float(coords.group(2)), float(coords.group(3))

                address_str = text_blocks[1] if len(text_blocks) > 1 else ""
                if phone:
                    address_str = address_str.replace(phone, "").strip()

                if name and len(name) > 3:
                    pharmacies.append({
                        "name": name,
                        "address": address_str,
                        "phone": phone,
                        "district": "",
                        "lat": lat,
                        "lng": lng,
                    })
            return pharmacies

        for row in rows:
            text = row.text.strip()
            if not text:
                continue
            
            name_el = row.select_one('.card-title, h5, strong, .eczane-isim, .title')
            name = name_el.text.strip() if name_el else ""
            if not name or ("Eczane" not in name and "eczane" not in name.lower()):
                # Sometimes name is inside a link
                if row.find('a') and row.find('a').text:
                    name = row.find('a').text.strip()
                else:
                    name = text.split('\n')[0].strip()
                
            content_desc = text.replace(name, "").strip()
            phone_match = re.search(r'0?\s?\(?\s?[1-9]\d{2}\s?\)?\s?\d{3}\s?[-]?\s?\d{2}\s?[-]?\s?\d{2}', text)
            phone = phone_match.group(0) if phone_match else ""
            if phone:
                content_desc = content_desc.replace(phone, "").strip()
            
            map_link = row.select_one('a[href*="google.com/maps"], a[href*="yandex"]')
            lat, lng = 0.0, 0.0
            if map_link:
                href = map_link.get('href', '')
                coords = re.search(r'(@|query=)([0-9.-]+),([0-9.-]+)', href)
                if coords:
                    lat, lng = float(coords.group(2)), float(coords.group(3))
            
            if len(name) > 2:
                pharmacies.append({
                    "name": name,
                    "address": content_desc[:150].replace('\n', ' ').strip(),
                    "phone": phone.strip(),
                    "district": "",
                    "lat": lat,
                    "lng": lng,
                })
            
        return pharmacies
