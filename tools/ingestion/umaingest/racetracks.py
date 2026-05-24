"""Racetrack course-map image mapping.

Source: gametora.com Umamusume racetracks data.

Pipeline (all plain HTTP, no scraping/headless browser):
  1. GET /data/manifests/umamusume.json        -> {key: hash}, key "racetracks"
  2. GET /data/umamusume/racetracks.<hash>.json -> per-racecourse course geometry
  3. Course-map image:
       {MEDIA_BASE}/{VERSION_SLUG}/simple/{lang}/{id1}/{id2}.png
     VERSION_SLUG is a constant cache/version folder ("pre_santa_anita"); the
     real course is fully determined by id1 (racecourse) + id2 (course).

A committed snapshot of the data lives at data/racetracks_data.json so the
ingestion + matcher are reproducible without re-fetching. Run
`refresh_snapshot()` to update it.

Course field semantics (from the gametora racetracks page bundle):
  terrain: 1 = turf (잔디), 2 = dirt (더트)
  turn:    1 = right / clockwise (시계우), 2 = left / counterclockwise (반시계좌),
           4 = special (straight / figure-eight)
  distance:1 = sprint, 2 = mile, 3 = medium, 4 = long
  length:  meters
  inout:   inner/outer course designation (disambiguates same-length courses)
"""
from __future__ import annotations

import json
import ssl
import time
import urllib.request
from pathlib import Path

try:  # use certifi's CA bundle when available (macOS system Python lacks one)
    import certifi
    SSL_CTX: ssl.SSLContext | None = ssl.create_default_context(cafile=certifi.where())
except Exception:  # pragma: no cover - fall back to unverified for public assets
    SSL_CTX = ssl._create_unverified_context()

# --- constants -------------------------------------------------------------
DATA_HOST = "https://gametora.com"
MEDIA_BASE = "https://media.gametora.com/umamusume/racetrack/history"
VERSION_SLUG = "pre_santa_anita"  # constant version/cache folder; id1/id2 carry content
_UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
       "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15")

_SNAPSHOT = Path(__file__).with_name("data") / "racetracks_data.json"

# gametora racecourse id (id1) -> english slug
SLUG_BY_ID: dict[str, str] = {
    "10001": "sapporo", "10002": "hakodate", "10003": "niigata",
    "10004": "fukushima", "10005": "nakayama", "10006": "tokyo",
    "10007": "chukyo", "10008": "kyoto", "10009": "hanshin",
    "10010": "kokura", "10101": "ooi", "10103": "kawasaki",
    "10104": "funabashi", "10105": "morioka", "10201": "longchamp",
    "10202": "santa_anita", "10203": "del_mar",
}

# Korean racecourse name (as used in the schedule sheet) -> id1
ID_BY_KR: dict[str, str] = {
    "삿포로": "10001", "하코다테": "10002", "니가타": "10003",
    "후쿠시마": "10004", "나카야마": "10005", "도쿄": "10006",
    "주쿄": "10007", "교토": "10008", "한신": "10009",
    "고쿠라": "10010", "오이": "10101", "가와사키": "10103",
    "후나바시": "10104", "모리오카": "10105", "롱샹": "10201",
    "산타아니타": "10202", "델마": "10203",
}

_TERRAIN = {"turf": 1, "dirt": 2}


# --- data access -----------------------------------------------------------
def _http_json(url: str) -> object:
    req = urllib.request.Request(url, headers={"User-Agent": _UA})
    with urllib.request.urlopen(req, timeout=30, context=SSL_CTX) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_remote_data() -> list:
    """Fetch the live racetracks data via the manifest hash. Network required."""
    manifest = _http_json(f"{DATA_HOST}/data/manifests/umamusume.json")
    h = manifest["racetracks"]
    return _http_json(f"{DATA_HOST}/data/umamusume/racetracks.{h}.json")


def refresh_snapshot() -> Path:
    """Re-fetch live data and overwrite the committed snapshot."""
    data = fetch_remote_data()
    _SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
    _SNAPSHOT.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    return _SNAPSHOT


def load_data() -> list:
    """Load the committed snapshot."""
    return json.loads(_SNAPSHOT.read_text(encoding="utf-8"))


# --- mapping ---------------------------------------------------------------
def image_name(id1: str, id2) -> str:
    """Stable bundled-asset base name for a course."""
    return f"course_{id1}_{id2}"


def image_url(id1: str, id2, lang: str = "ko") -> str:
    return f"{MEDIA_BASE}/{VERSION_SLUG}/simple/{lang}/{id1}/{id2}.png"


def iter_courses(data: list | None = None):
    """Yield (id1, course_dict) for every course in every racecourse."""
    data = data if data is not None else load_data()
    for rc in data:
        id1 = rc["id"]
        for c in rc.get("courses", []):
            yield id1, c


def course_image_name(racecourse_kr: str, surface: str, distance_m: int,
                      course_side: str | None = None,
                      data: list | None = None) -> str | None:
    """Resolve a schedule TrackCondition to a bundled course-map image name.

    Returns "course_{id1}_{id2}" or None if no racecourse/course matches.
    When multiple courses share (terrain, length) — kyoto/niigata inner-vs-outer —
    `course_side` ("inner"/"outer"/"내"/"외"/"1"/"2") disambiguates; otherwise the
    lowest course id is chosen deterministically.
    """
    id1 = ID_BY_KR.get(racecourse_kr)
    if id1 is None:
        return None
    terrain = _TERRAIN.get(surface)
    if terrain is None:
        return None
    data = data if data is not None else load_data()
    rc = next((r for r in data if r["id"] == id1), None)
    if rc is None:
        return None
    matches = [c for c in rc.get("courses", [])
               if c.get("terrain") == terrain and c.get("length") == distance_m]
    if not matches:
        return None
    if len(matches) > 1 and course_side:
        want = _course_side(course_side)  # 1 = inner (내), 2 = outer (외)
        if want is not None:
            # verified against gametora maps: lower `inout` == inner (내), higher == outer (외)
            matches_sorted = sorted(matches, key=lambda c: c.get("inout", 0))
            chosen = matches_sorted[0] if want == 1 else matches_sorted[-1]
            return image_name(id1, chosen["id"])
    chosen = min(matches, key=lambda c: c["id"])
    return image_name(id1, chosen["id"])


def _course_side(value: str | None) -> int | None:
    """Normalize an inner/outer hint to 1 (inner/내) or 2 (outer/외). Tolerant of
    내/내측/내회/안/안쪽/inner and 외/외측/외회/바깥/바깥쪽/outer; None if unrecognized."""
    if not value:
        return None
    s = str(value).strip().lower()
    if "외" in s or "바깥" in s or "outer" in s:
        return 2
    if "내" in s or "안" in s or "inner" in s:
        return 1
    if s == "2":
        return 2
    if s == "1":
        return 1
    return None
