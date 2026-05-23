from __future__ import annotations
import csv, io, re
from typing import Optional
from .fetch import Transport, _requests_transport

_SURFACE = {"잔디": "turf", "터프": "turf", "turf": "turf", "더트": "dirt", "dirt": "dirt"}
_TURN = {"우": "clockwise", "시계": "clockwise", "clockwise": "clockwise",
         "좌": "counterclockwise", "반시계": "counterclockwise", "counterclockwise": "counterclockwise",
         "직선": "straight", "straight": "straight"}
_CATEGORY = {
    "championsmeeting": "championsMeeting", "챔피언스미팅": "championsMeeting", "챔미": "championsMeeting", "cm": "championsMeeting",
    "leagueofheroes": "leagueOfHeroes", "리그오브히어로스": "leagueOfHeroes", "리그오브히어로즈": "leagueOfHeroes", "loh": "leagueOfHeroes",
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


# ---------------------------------------------------------------------------
# KR human-friendly sheet format
# Columns: 날짜, 분류, 제목, 레이스, 마장, 픽업(육성마), 픽업(서포트), 비고
# Values are packed Korean strings, e.g.:
#   마장 = "한신, 잔디 1600m(마일), 시계(우), 봄, 맑음, 양호, 낮"
#   레이스 = "G1 벚꽃상"   픽업(서포트) = "카렌짱 SSR(근성), 이쿠노 딕터스 SSR(지능)"
# ---------------------------------------------------------------------------

_SEASONS = {"봄", "여름", "가을", "겨울"}
_TIMES = {"낮", "밤"}
_SIDES = {"외측", "내측"}
_GROUNDS = {"양호", "약간 무거움", "약간무거움", "다습", "무거움", "불량"}
_GRADES = {"G1", "G2", "G3", "OP", "EX"}
_SUPPORT_RE = re.compile(r"^(?P<name>.+?)\s+(?P<rarity>SSR|SR|R)\((?P<type>.+?)\)\s*$")


def _strip_brackets(s: str) -> str:
    return (s or "").strip().strip("「」").strip()


def _parse_race(cell: str) -> tuple[Optional[str], str]:
    """'G1 벚꽃상' -> ('G1', '벚꽃상'); '재팬 더트 더비' -> (None, '재팬 더트 더비')."""
    s = (cell or "").strip()
    if not s:
        return None, ""
    head, _, rest = s.partition(" ")
    if head in _GRADES and rest:
        return head, rest.strip()
    return None, s


def _parse_track_packed(cell: str) -> dict:
    """'한신, 잔디 1600m(마일), 시계(우), 봄, 맑음, 양호, 낮' -> track dict.

    Positional: [racecourse, surface+distance, turn, *extras]. Extras are
    classified by vocabulary (season/time/courseSide/ground; else weather)
    so omitted/reordered fields don't break parsing.
    """
    parts = [p.strip() for p in (cell or "").split(",") if p.strip()]
    if not parts:
        return {}
    t: dict = {"racecourse": parts[0]}
    if len(parts) > 1:
        seg = parts[1]
        surface_word = seg.split()[0] if seg.split() else ""
        t["surface"] = _SURFACE.get(surface_word, surface_word.lower())
        m = re.search(r"(\d+)\s*m", seg)
        if m:
            dm = int(m.group(1))
            t["distanceMeters"] = dm
            t["distanceClass"] = _distance_class(dm)
    if len(parts) > 2:
        p = parts[2]
        if "반시계" in p or "좌" in p:
            t["turn"] = "counterclockwise"
        elif "시계" in p or "우" in p:
            t["turn"] = "clockwise"
        elif "직선" in p:
            t["turn"] = "straight"
    for extra in parts[3:]:
        if extra in _SEASONS:
            t["season"] = extra
        elif extra in _TIMES:
            t["timeOfDay"] = extra
        elif extra in _SIDES:
            t["courseSide"] = extra
        elif extra in _GROUNDS:
            t["ground"] = extra
        else:
            t["weather"] = extra
    return t


def _parse_trainees_kr(cell: str) -> list:
    return [t.strip() for t in (cell or "").split(",") if t.strip()]


def _parse_supports_kr(cell: str) -> list:
    out = []
    for part in (cell or "").split(","):
        m = _SUPPORT_RE.match(part.strip())
        if m:
            out.append({"rarity": m.group("rarity"), "name": m.group("name").strip(), "type": m.group("type").strip()})
    return out


def parse_kr_rows(rows: list[dict]) -> dict:
    doc = {"championsMeetings": [], "leagueOfHeroes": [], "pickups": []}
    for row in rows:
        date = (row.get("날짜") or "").strip()
        if not date:
            continue
        cat = _CATEGORY.get((row.get("분류") or "").strip().lower().replace(" ", ""))
        period = {"start": date, "end": date, "estimated": True}
        if cat == "championsMeeting":
            grade, name = _parse_race(row.get("레이스"))
            doc["championsMeetings"].append({
                "codeName": _strip_brackets(row.get("제목")),
                "raceGrade": grade, "raceName": name,
                "track": _parse_track_packed(row.get("마장")), "period": period})
        elif cat == "leagueOfHeroes":
            doc["leagueOfHeroes"].append({
                "round": _strip_brackets(row.get("제목")),
                "raceName": (row.get("레이스") or "").strip(),
                "track": _parse_track_packed(row.get("마장")), "period": period})
        elif cat == "gacha":
            raw_support = (row.get("픽업(서포트)") or "").strip()
            cards = _parse_supports_kr(raw_support)
            pickup = {
                "period": period,
                "trainees": _parse_trainees_kr(row.get("픽업(육성마)")),
                "supportCards": cards}
            # No parseable cards but the cell has text (e.g. "셀렉트 픽업") → keep as a note.
            if not cards and raw_support:
                pickup["supportNote"] = raw_support
            doc["pickups"].append(pickup)
    return doc


def parse_kr_csv(text: str) -> dict:
    return parse_kr_rows(list(csv.DictReader(io.StringIO(text))))


def parse_csv(text: str) -> dict:
    """Auto-detect: KR human-friendly layout (has a '날짜' column) vs the generic column layout."""
    reader = csv.DictReader(io.StringIO(text))
    rows = list(reader)
    if reader.fieldnames and "날짜" in reader.fieldnames:
        return parse_kr_rows(rows)
    return parse_rows(rows)


def fetch_sheet_csv(url: str, transport: Transport = _requests_transport) -> str:
    body, status = transport(url, {"User-Agent": "Mozilla/5.0"})
    if status != 200:
        raise RuntimeError(f"sheet fetch failed: HTTP {status}")
    return body.decode("utf-8", errors="replace")
