import httpx
from bs4 import BeautifulSoup
from typing import List, Dict, Any, Optional
import re

class PharmacyService:
    @staticmethod
    def slugify(text: str) -> str:
        text = text.lower()
        for suffix in [" ili", " province", " belediyesi", " valiliği"]:
            text = text.replace(suffix, "")
        text = text.strip()
        for old, new in {'ı': 'i', 'ş': 's', 'ç': 'c', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'İ': 'i'}.items():
            text = text.replace(old, new)
        text = ''.join(c for c in text if c.isalnum() or c == '-')
        return text

    @classmethod
    async def get_on_duty_pharmacies(cls, city: str, district: Optional[str] = None) -> List[Dict[str, Any]]:
        city_map = {
            "afyon": "afyonkarahisar",
            "icel": "mersin",
            "k.maras": "kahramanmaras",
        }

        city_slug = cls.slugify(city)
        city_slug = city_map.get(city_slug, city_slug)

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
            "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8",
        }

        # If district is known, try fetching only that district page — avoids timeout
        if district:
            district_slug = cls.slugify(district)
            district_url = f"https://www.eczaneler.gen.tr/nobetci-{city_slug}-{district_slug}"
            try:
                async with httpx.AsyncClient() as client:
                    res = await client.get(district_url, headers=headers, timeout=12.0)
                if res.status_code == 200:
                    soup = BeautifulSoup(res.text, "html.parser")
                    pharmacies = cls._extract_pharmacies(soup)
                    if pharmacies:
                        for p in pharmacies:
                            p.setdefault("district", district_slug)
                        return pharmacies
            except Exception:
                pass  # fall through to city-page approach

        # Fetch main city page
        url = f"https://www.eczaneler.gen.tr/nobetci-{city_slug}"
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, timeout=12.0)

        if response.status_code != 200:
            raise ValueError(
                f"Failed to fetch pharmacies from eczaneler.gen.tr. "
                f"Status: {response.status_code}"
            )

        soup = BeautifulSoup(response.text, "html.parser")

        pharmacies = cls._extract_pharmacies(soup)
        if pharmacies:
            return pharmacies

        # City page has district sub-pages — find links by URL pattern (reliable, selector-independent)
        district_prefix = f"/nobetci-{city_slug}-"
        district_hrefs = list(dict.fromkeys(
            a["href"] for a in soup.find_all("a", href=True)
            if a["href"].startswith(district_prefix)
        ))

        if district_hrefs:
            import asyncio
            links_to_fetch = [f"https://www.eczaneler.gen.tr{href}" for href in district_hrefs]

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

            sem = asyncio.Semaphore(10)

            async def fetch_with_sem(d_url):
                async with sem:
                    return await fetch_district(d_url)

            results = await asyncio.gather(*[fetch_with_sem(u) for u in links_to_fetch])
            all_pharmacies = [p for batch in results for p in batch]
            if all_pharmacies:
                return all_pharmacies

        raise ValueError(
            "No pharmacies parsed from eczaneler.gen.tr "
            f"for city={city!r}, url={url!r}, status={response.status_code}, "
            f"body_preview={response.text[:300]!r}"
        )

    @classmethod
    def _extract_pharmacies(cls, soup: BeautifulSoup) -> List[Dict[str, Any]]:
        pharmacies = []

        for row in soup.select("tr"):
            name_el = row.select_one("span.isim")
            if not name_el:
                continue

            name = name_el.get_text(" ", strip=True)
            address_el = row.select_one("div.col-lg-6")
            phone_el = row.select_one("div.col-lg-3.py-lg-2")
            badge_el = row.select_one("span.bg-secondary") or row.select_one("span.bg-info")

            address = address_el.get_text(" ", strip=True) if address_el else ""
            phone = phone_el.get_text(" ", strip=True) if phone_el else ""
            district = badge_el.get_text(" ", strip=True) if badge_el else ""

            if not phone:
                phone_match = re.search(
                    r"0?\s?\(?\s?[1-9]\d{2}\s?\)?\s?\d{3}\s?[-]?\s?\d{2}\s?[-]?\s?\d{2}",
                    row.get_text(" ", strip=True),
                )
                phone = phone_match.group(0).strip() if phone_match else ""

            if name and len(name) > 2:
                pharmacies.append({
                    "name": name,
                    "address": address,
                    "phone": phone,
                    "district": district,
                    "lat": 0.0,
                    "lng": 0.0,
                })

        return pharmacies
