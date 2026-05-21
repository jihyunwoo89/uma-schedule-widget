import json
from umaingest.models import ScheduleDocument, ChampionsMeeting, TrackCondition, EventPeriod, EventPhase

def _track():
    return TrackCondition(racecourse="한신", surface="turf", distanceMeters=1600, distanceClass="mile",
                          turn="clockwise", courseSide="외측", season="봄")

def test_round_trip_and_iso_z():
    doc = ScheduleDocument(
        version=2, updatedAt="2026-05-20T00:00:00Z", sourcePostNo=1850737, server="kr",
        championsMeetings=[ChampionsMeeting(
            id="cm", codeName="LONG", raceGrade="G1", raceName="벚꽃상", track=_track(),
            period=EventPeriod(start="2026-07-14T00:00:00Z", end="2026-07-20T00:00:00Z", estimated=True),
            phases=[EventPhase(kind="open", label="오픈", date="2026-07-14T00:00:00Z")])],
        leagueOfHeroes=[], pickups=[])
    s = doc.to_json()
    parsed = json.loads(s)
    assert parsed["version"] == 2
    assert parsed["championsMeetings"][0]["codeName"] == "LONG"
    assert parsed["championsMeetings"][0]["period"]["start"] == "2026-07-14T00:00:00Z"
    assert parsed["updatedAt"].endswith("Z")

def test_validation_rejects_bad_enum():
    import pytest
    with pytest.raises(Exception):
        TrackCondition(racecourse="x", surface="grass", distanceMeters=1, distanceClass="mile")

def test_optional_fields_serialize_as_null_or_value():
    t = TrackCondition(racecourse="도쿄", surface="dirt", distanceMeters=2000, distanceClass="medium")
    d = json.loads(ScheduleDocument(version=2, updatedAt="2026-05-20T00:00:00Z", server="kr",
        championsMeetings=[], leagueOfHeroes=[], pickups=[]).to_json())
    assert d["sourcePostNo"] is None
    assert t.turn is None
