from __future__ import annotations
import hashlib
from datetime import timedelta
from . import racetracks
from .models import (ScheduleDocument, ChampionsMeeting, LeagueOfHeroes, PickupPeriod,
                     TrackCondition, EventPeriod, EventPhase, SupportCardPick)

# Event end-date rules (when the sheet gives only a start date):
#   챔미   : 종료 = 시작 + 6일   (5/15 → 5/21)
#   LoH    : 종료 = 시작 + 9일   (5/12 → 5/21)
#   픽업   : 종료 = 다음 픽업 시작일 (마지막 픽업은 직전 간격을 그대로 적용)
CM_DURATION_DAYS = 6
LOH_DURATION_DAYS = 9
PICKUP_LONE_FALLBACK_DAYS = 7  # only used if there is a single pickup


def _with_duration(per: EventPeriod, days: int) -> EventPeriod:
    """End = start + `days`, unless the sheet already provided an explicit end."""
    if per.end > per.start:
        return per
    return EventPeriod(start=per.start, end=per.start + timedelta(days=days), estimated=per.estimated)


def _with_end(per: EventPeriod, end) -> EventPeriod:
    return EventPeriod(start=per.start, end=end, estimated=per.estimated)


def _day(d: str) -> str:
    """'2026-07-14' or '2026-07-14T..' → 'YYYY-MM-DDT00:00:00Z'."""
    base = d[:10]
    return f"{base}T00:00:00Z"


def _eid(prefix: str, *parts: str) -> str:
    h = hashlib.sha1("|".join(parts).encode("utf-8")).hexdigest()[:10]
    return f"{prefix}-{h}"


def _period(p: dict) -> EventPeriod:
    return EventPeriod(start=_day(p["start"]), end=_day(p["end"]), estimated=bool(p.get("estimated", True)))


def _track(t: dict, race_name: str | None = None) -> TrackCondition:
    tc = TrackCondition(**{k: t.get(k) for k in
        ["racecourse","surface","distanceMeters","distanceClass","turn","courseSide","season","weather","ground","timeOfDay","imageURL","courseMap"]
        if k in t})
    if not tc.courseMap:  # resolve bundled course-map image from gametora data
        surface = tc.surface.value if hasattr(tc.surface, "value") else str(tc.surface)
        tc.courseMap = racetracks.course_image_name(
            tc.racecourse, surface, tc.distanceMeters, tc.courseSide, race_name=race_name)
    return tc


def _support(sc: dict) -> SupportCardPick:
    return SupportCardPick(**{k: sc.get(k) for k in ("rarity", "name", "type") if k in sc})


def _phases(period: EventPeriod) -> list[EventPhase]:
    return [EventPhase(kind="open", label="오픈", date=period.start),
            EventPhase(kind="ended", label="종료", date=period.end)]


def build_document(extracted: dict, *, source_post_no: int | None = None, now_iso: str) -> ScheduleDocument:
    """Build a validated ScheduleDocument from one consolidated extraction dict.
    Incomplete events (missing period; CM/LoH missing track) are skipped, not fatal —
    the review gate catches gaps, and one bad event shouldn't drop the whole run."""
    cms: dict[str, ChampionsMeeting] = {}
    for c in extracted.get("championsMeetings", []):
        if not c.get("period") or not c.get("track"):
            continue
        per = _with_duration(_period(c["period"]), CM_DURATION_DAYS)
        eid = _eid("cm", c.get("codeName", ""), c.get("raceName", ""), per.start.isoformat())
        cms.setdefault(eid, ChampionsMeeting(
            id=eid, codeName=c.get("codeName", ""), raceGrade=c.get("raceGrade"),
            raceName=c.get("raceName", ""), track=_track(c["track"], c.get("raceName")), period=per, phases=_phases(per)))

    lohs: dict[str, LeagueOfHeroes] = {}
    for l in extracted.get("leagueOfHeroes", []):
        if not l.get("period") or not l.get("track"):
            continue
        per = _with_duration(_period(l["period"]), LOH_DURATION_DAYS)
        eid = _eid("loh", l.get("round", ""), l.get("raceName", ""), per.start.isoformat())
        lohs.setdefault(eid, LeagueOfHeroes(
            id=eid, round=l.get("round", ""), raceName=l.get("raceName", ""),
            track=_track(l["track"], l.get("raceName")), period=per, phases=_phases(per)))

    # Pickups: end = next pickup's start (chained, in chronological order).
    parsed_pks = [(_period(p["period"]), p) for p in extracted.get("pickups", []) if p.get("period")]
    parsed_pks.sort(key=lambda t: t[0].start)
    pks: dict[str, PickupPeriod] = {}
    for i, (per, p) in enumerate(parsed_pks):
        if per.end > per.start:                       # explicit end from the sheet — keep
            end = per.end
        elif i + 1 < len(parsed_pks):                 # next pickup's start
            end = parsed_pks[i + 1][0].start
        elif i > 0:                                   # last: mirror the previous interval
            end = per.start + (per.start - parsed_pks[i - 1][0].start)
        else:                                         # only one pickup
            end = per.start + timedelta(days=PICKUP_LONE_FALLBACK_DAYS)
        per = _with_end(per, end)
        eid = _eid("pk", per.start.isoformat(), ",".join(p.get("trainees", [])))
        pks.setdefault(eid, PickupPeriod(
            id=eid, period=per, trainees=p.get("trainees", []),
            supportCards=[_support(sc) for sc in p.get("supportCards", [])],
            supportNote=p.get("supportNote")))

    return ScheduleDocument(
        version=2, updatedAt=now_iso, sourcePostNo=source_post_no, server="kr",
        championsMeetings=list(cms.values()),
        leagueOfHeroes=list(lohs.values()),
        pickups=list(pks.values()),
    )
