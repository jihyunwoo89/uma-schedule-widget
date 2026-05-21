from __future__ import annotations
import csv, io
from typing import Optional
from .fetch import Transport, _requests_transport

_SURFACE = {"잔디": "turf", "터프": "turf", "turf": "turf", "더트": "dirt", "dirt": "dirt"}
_TURN = {"우": "clockwise", "시계": "clockwise", "clockwise": "clockwise",
         "좌": "counterclockwise", "반시계": "counterclockwise", "counterclockwise": "counterclockwise",
         "직선": "straight", "straight": "straight"}
_CATEGORY = {
    "championsmeeting": "championsMeeting", "챔피언스미팅": "championsMeeting", "챔미": "championsMeeting", "cm": "championsMeeting",
    "leagueofheroes": "leagueOfHeroes", "리그오브히어로즈": "leagueOfHeroes", "loh": "leagueOfHeroes",
    "gacha": "gacha", "픽업": "gacha", "가챠": "gacha", "pickup": "gacha",
}


def _opt(s) -> Optional[str]:
    s = (s or "").strip()
    return s or None


def _distance_class(m: int) -> str:
    if m <= 1400: return "sprint"
    if m <= 1800: return "mile"
    if m <= 2400: return "medium"
    return "long"


def _bool(s) -> bool:
    return (s or "").strip().lower() in ("true", "1", "y", "yes", "예", "o")


def _track(row: dict) -> dict:
    surface_raw = (row.get("surface") or "").strip().lower()
    dm = int(float(row["distanceMeters"]))
    t: dict = {
        "racecourse": (row.get("racecourse") or "").strip(),
        "surface": _SURFACE.get(surface_raw, surface_raw),
        "distanceMeters": dm,
        "distanceClass": _distance_class(dm),
    }
    turn_raw = (row.get("turn") or "").strip().lower()
    if turn_raw:
        t["turn"] = _TURN.get(turn_raw, turn_raw)
    for k in ("courseSide", "season", "weather", "ground", "timeOfDay"):
        v = _opt(row.get(k))
        if v:
            t[k] = v
    return t


def _period(row: dict) -> dict:
    start = (row.get("start") or "").strip()
    end = (row.get("end") or "").strip() or start
    return {"start": start, "end": end, "estimated": _bool(row.get("estimated"))}


def _trainees(cell) -> list:
    return [t.strip() for t in (cell or "").split(";") if t.strip()]


def _supports(cell) -> list:
    out = []
    for part in (cell or "").split(";"):
        part = part.strip()
        if not part:
            continue
        bits = [b.strip() for b in part.split("|")]
        if len(bits) >= 3:
            out.append({"rarity": bits[0], "name": bits[1], "type": bits[2]})
    return out


def parse_rows(rows: list[dict]) -> dict:
    doc = {"championsMeetings": [], "leagueOfHeroes": [], "pickups": []}
    for row in rows:
        key = (row.get("category") or "").strip().lower().replace(" ", "")
        cat = _CATEGORY.get(key)
        if cat == "championsMeeting":
            doc["championsMeetings"].append({
                "codeName": (row.get("title") or "").strip(),
                "raceGrade": _opt(row.get("raceGrade")),
                "raceName": (row.get("raceName") or "").strip(),
                "track": _track(row), "period": _period(row)})
        elif cat == "leagueOfHeroes":
            doc["leagueOfHeroes"].append({
                "round": (row.get("title") or "").strip(),
                "raceName": (row.get("raceName") or "").strip(),
                "track": _track(row), "period": _period(row)})
        elif cat == "gacha":
            doc["pickups"].append({
                "period": _period(row),
                "trainees": _trainees(row.get("trainees")),
                "supportCards": _supports(row.get("supportCards"))})
    return doc


def parse_csv(text: str) -> dict:
    return parse_rows(list(csv.DictReader(io.StringIO(text))))


def fetch_sheet_csv(url: str, transport: Transport = _requests_transport) -> str:
    body, status = transport(url, {"User-Agent": "Mozilla/5.0"})
    if status != 200:
        raise RuntimeError(f"sheet fetch failed: HTTP {status}")
    return body.decode("utf-8", errors="replace")
