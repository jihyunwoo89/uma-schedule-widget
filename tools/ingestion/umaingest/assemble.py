from __future__ import annotations
import hashlib
from .models import (ScheduleDocument, ChampionsMeeting, LeagueOfHeroes, PickupPeriod,
                     TrackCondition, EventPeriod, EventPhase, SupportCardPick)
from .vision import VisionResult


def _day(d: str) -> str:
    """'2026-07-14' or '2026-07-14T..' → 'YYYY-MM-DDT00:00:00Z'."""
    base = d[:10]
    return f"{base}T00:00:00Z"


def _eid(prefix: str, *parts: str) -> str:
    h = hashlib.sha1("|".join(parts).encode("utf-8")).hexdigest()[:10]
    return f"{prefix}-{h}"


def _period(p: dict) -> EventPeriod:
    return EventPeriod(start=_day(p["start"]), end=_day(p["end"]), estimated=bool(p.get("estimated", True)))


def _track(t: dict) -> TrackCondition:
    return TrackCondition(**{k: t.get(k) for k in
        ["racecourse","surface","distanceMeters","distanceClass","turn","courseSide","season","weather","ground","timeOfDay","imageURL"]
        if k in t})


def _support(sc: dict) -> SupportCardPick:
    # Filter to known keys so an extra vision-hallucinated field (e.g. "level") doesn't abort the run.
    return SupportCardPick(**{k: sc.get(k) for k in ("rarity", "name", "type") if k in sc})


def _phases(period: EventPeriod) -> list[EventPhase]:
    return [EventPhase(kind="open", label="오픈", date=period.start),
            EventPhase(kind="ended", label="종료", date=period.end)]


def assemble_document(slides: list[VisionResult], *, source_post_no: int, now_iso: str) -> ScheduleDocument:
    cms: dict[str, ChampionsMeeting] = {}
    lohs: dict[str, LeagueOfHeroes] = {}
    pks: dict[str, PickupPeriod] = {}

    for s in slides:
        for c in s.championsMeetings:
            per = _period(c["period"])
            eid = _eid("cm", c.get("codeName",""), c.get("raceName",""), per.start.isoformat())
            cms.setdefault(eid, ChampionsMeeting(
                id=eid, codeName=c.get("codeName",""), raceGrade=c.get("raceGrade"),
                raceName=c.get("raceName",""), track=_track(c["track"]), period=per, phases=_phases(per)))
        for l in s.leagueOfHeroes:
            per = _period(l["period"])
            eid = _eid("loh", l.get("round",""), l.get("raceName",""), per.start.isoformat())
            lohs.setdefault(eid, LeagueOfHeroes(
                id=eid, round=l.get("round",""), raceName=l.get("raceName",""),
                track=_track(l["track"]), period=per, phases=_phases(per)))
        for p in s.pickups:
            per = _period(p["period"])
            eid = _eid("pk", per.start.isoformat(), ",".join(p.get("trainees", [])))
            pks.setdefault(eid, PickupPeriod(
                id=eid, period=per, trainees=p.get("trainees", []),
                supportCards=[_support(sc) for sc in p.get("supportCards", [])]))

    return ScheduleDocument(
        version=2, updatedAt=now_iso, sourcePostNo=source_post_no, server="kr",
        championsMeetings=list(cms.values()),
        leagueOfHeroes=list(lohs.values()),
        pickups=list(pks.values()),
    )
