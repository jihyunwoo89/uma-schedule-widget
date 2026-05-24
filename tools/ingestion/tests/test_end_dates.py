from datetime import date
from umaingest.assemble import build_document

NOW = "2026-05-01T00:00:00Z"


def _doc(cms=None, lohs=None, pickups=None):
    return build_document(
        {"championsMeetings": cms or [], "leagueOfHeroes": lohs or [], "pickups": pickups or []},
        source_post_no=1, now_iso=NOW)


def _cm(start):
    return {"codeName": "X", "raceName": "벚꽃상",
            "track": {"racecourse": "한신", "surface": "turf", "distanceMeters": 1600, "distanceClass": "mile"},
            "period": {"start": start, "end": start, "estimated": True}}


def _loh(start):
    return {"round": "1", "raceName": "스프린터즈 S",
            "track": {"racecourse": "나카야마", "surface": "turf", "distanceMeters": 1200, "distanceClass": "sprint"},
            "period": {"start": start, "end": start, "estimated": True}}


def _pk(start, trainees):
    return {"period": {"start": start, "end": start, "estimated": True}, "trainees": trainees, "supportCards": []}


def test_champions_meeting_ends_6_days_after_start():
    doc = _doc(cms=[_cm("2026-05-15")])
    cm = doc.championsMeetings[0]
    assert cm.period.end.date() == date(2026, 5, 21)          # 5/15 + 6
    assert cm.phases[-1].kind == "ended"
    assert cm.phases[-1].date == cm.period.end                # 종료 phase tracks end


def test_league_of_heroes_ends_9_days_after_start():
    doc = _doc(lohs=[_loh("2026-05-12")])
    loh = doc.leagueOfHeroes[0]
    assert loh.period.end.date() == date(2026, 5, 21)          # 5/12 + 9


def test_pickup_ends_at_next_pickup_start():
    doc = _doc(pickups=[_pk("2026-05-10", ["A"]), _pk("2026-05-17", ["B"]), _pk("2026-05-24", ["C"])])
    pks = sorted(doc.pickups, key=lambda p: p.period.start)
    assert pks[0].period.end.date() == date(2026, 5, 17)       # → next start
    assert pks[1].period.end.date() == date(2026, 5, 24)       # → next start
    # last pickup mirrors the previous interval (7 days)
    assert pks[2].period.end.date() == date(2026, 5, 31)


def test_pickup_chaining_is_order_independent():
    # input reversed → still chains chronologically
    doc = _doc(pickups=[_pk("2026-05-24", ["C"]), _pk("2026-05-10", ["A"]), _pk("2026-05-17", ["B"])])
    pks = sorted(doc.pickups, key=lambda p: p.period.start)
    assert pks[0].period.end.date() == date(2026, 5, 17)
    assert pks[1].period.end.date() == date(2026, 5, 24)


def test_explicit_sheet_end_is_preserved():
    cm = _cm("2026-05-15"); cm["period"]["end"] = "2026-05-18"   # explicit, non-default
    doc = _doc(cms=[cm])
    assert doc.championsMeetings[0].period.end.date() == date(2026, 5, 18)
