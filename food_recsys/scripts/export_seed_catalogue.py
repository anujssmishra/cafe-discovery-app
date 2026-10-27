"""Build the bundled public catalogue from the repository's PHP seed (no database access)."""

import argparse
import csv
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "food_recsys"))
from app.mock.restaurants import CAFE_APP_SEEDS


def build_export(sql: str) -> dict:
    tables = {}
    for match in re.finditer(r"INSERT INTO `(\w+)` \((.*?)\) VALUES\n(.*?)(?=ON DUPLICATE)", sql, re.S):
        table, columns, rows = match.groups()
        names = re.findall(r"`(\w+)`", columns)
        tables[table] = []
        for row in rows.strip().splitlines():
            values = next(csv.reader([row.strip().rstrip(",;")[1:-1]],
                                    quotechar="'", escapechar="\\", skipinitialspace=True))
            if len(values) != len(names):
                raise ValueError(f"Malformed {table} seed row")
            tables[table].append(dict(zip(names, values)))
    areas = {a["id"]: a for a in tables["area"]}
    cuisine_enrichment = {r["id"]: r.get("cuisines", []) for r in CAFE_APP_SEEDS}
    restaurants = []
    for cafe in tables["cafe"]:
        area = areas[cafe["area_id"]]
        record = {key: cafe.get(key) for key in
                  ("id", "name", "address", "price_band", "photo_url", "hero_image_url", "checked_on")}
        record.update(city=area["city"], area=area["name"], source="cafe_app",
                      is_active=cafe["is_active"] == "1" and area["is_active"] == "1",
                      latitude=float(cafe["latitude"]), longitude=float(cafe["longitude"]),
                      cuisines=cuisine_enrichment.get(cafe["id"], []),
                      avg_rating=None,
                      vibe_tags=[v.strip() for v in cafe.get("vibe_tags", "").split(",") if v.strip()],
                      food_highlights=[v.strip() for v in cafe.get("food_highlights", "").split(",") if v.strip()],
                      website=None, offerings=[])
        for offering in tables.get("cafe_offering", []):
            if offering["cafe_id"] == cafe["id"]:
                record["offerings"].append({
                    key: float(offering[key]) if key == "price" else offering[key]
                    for key in ("drink_type", "brewing_method", "price", "currency", "checked_on", "source")
                })
        for website, predicate in re.findall(r"UPDATE `cafe` SET `website` = '([^']+)' WHERE `id` (.*?);", sql):
            if cafe["id"] in re.findall(r"'([^']+)'", predicate):
                record["website"] = website
        restaurants.append(record)
    return {"schema_version": 1, "source_sha256": hashlib.sha256(sql.encode()).hexdigest(),
            "restaurants": restaurants}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    target = ROOT / "food_recsys/app/catalogue/cafes.json"
    output = json.dumps(build_export((ROOT / "php_app/schema/lucknow_cafes.sql").read_text()),
                        indent=2, ensure_ascii=False) + "\n"
    if args.check:
        if target.read_text() != output:
            raise SystemExit("Bundled catalogue is stale; run scripts/export_seed_catalogue.py")
    else:
        target.write_text(output)
