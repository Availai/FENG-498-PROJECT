import os
import httpx
from typing import Optional

PERENUAL_API_KEY = os.getenv("PERENUAL_API_KEY", "")

async def fetch_plant_details_from_perenual(query: str) -> Optional[dict]:
    """
    Fetches detailed agricultural requirements for a plant from the Perenual API.
    query: Common name or scientific name
    Returns a processed dictionary suitable for database insertion, or None if not found.
    """
    if not PERENUAL_API_KEY:
        print("Warning: PERENUAL_API_KEY not set.")
        # Proceeding anyways in case the key is not strictly needed for some endpoints, 
        # but realistically we expect it to be injected.

    search_url = f"https://perenual.com/api/v2/species-list?key={PERENUAL_API_KEY}&q={query}"
    
    async with httpx.AsyncClient() as client:
        try:
            search_res = await client.get(search_url, timeout=10.0)
            if search_res.status_code != 200:
                print(f"Perenual search failed: {search_res.status_code}")
                return None
                
            search_data = search_res.json()
            data_list = search_data.get('data', [])
            
            if not data_list:
                print(f"No species found for {query}")
                return None
                
            species_id = data_list[0]['id']
            
            detail_url = f"https://perenual.com/api/v2/species/details/{species_id}?key={PERENUAL_API_KEY}"
            detail_res = await client.get(detail_url, timeout=10.0)
            
            if detail_res.status_code != 200:
                print(f"Perenual detail failed: {detail_res.status_code}")
                return None
                
            d = detail_res.json()
            
            hardiness_min = d.get('hardiness', {}).get('min')
            hardiness_max = d.get('hardiness', {}).get('max')
            if isinstance(hardiness_min, str):
                try: hardiness_min = int(hardiness_min)
                except: hardiness_min = None
            if isinstance(hardiness_max, str):
                try: hardiness_max = int(hardiness_max)
                except: hardiness_max = None

            ideal_temp_min = 10.0
            ideal_temp_max = 35.0
            
            return {
                "scientific_name": d.get('scientific_name', [query])[0] if isinstance(d.get('scientific_name'), list) else d.get('scientific_name', query),
                "common_name": d.get('common_name', query),
                "family": d.get('family', 'Unknown'),
                "cycle": d.get('cycle', 'Unknown'),
                "watering": d.get('watering', 'Average'),
                "sunlight": ", ".join(d.get('sunlight', [])) if isinstance(d.get('sunlight'), list) else str(d.get('sunlight', 'Full sun')),
                "hardiness_min": hardiness_min,
                "hardiness_max": hardiness_max,
                "ideal_ph_min": 5.5, 
                "ideal_ph_max": 7.5,
                "ideal_temp_min": ideal_temp_min,
                "ideal_temp_max": ideal_temp_max,
                "care_level": d.get('care_level', 'Medium'),
                "disease_risks": ", ".join(d.get('pest_susceptibility', [])) if isinstance(d.get('pest_susceptibility'), list) else str(d.get('pest_susceptibility', 'Unknown'))
            }
        except Exception as e:
            print(f"Error fetching Perenual data: {e}")
            return None
