from umaingest.assemble import build_document
from umaingest.models import ScheduleDocument

def _cm(start, with_track=True):
    d = {"codeName":"LONG","raceGrade":"G1","raceName":"벚꽃상",
         "period":{"start":start,"end":"2026-07-20","estimated":True}}
    if with_track:
        d["track"] = {"racecourse":"한신","surface":"turf","distanceMeters":1600,"distanceClass":"mile"}
    return d

def test_build_adds_ids_and_phases():
    extracted = {"championsMeetings":[_cm("2026-07-14")], "leagueOfHeroes":[],
                 "pickups":[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                             "trainees":["오르페브르","푸리오소"],
                             "supportCards":[{"rarity":"SSR","name":"아몬드 아이","type":"스피드"}]}]}
    doc = build_document(extracted, source_post_no=1850737, now_iso="2026-05-20T00:00:00Z")
    assert isinstance(doc, ScheduleDocument)
    assert doc.sourcePostNo == 1850737
    cm = doc.championsMeetings[0]
    assert cm.id and cm.phases[0].kind == "open" and cm.phases[-1].kind == "ended"
    assert doc.pickups[0].trainees == ["오르페브르","푸리오소"]

def test_build_skips_event_missing_track_or_period():
    extracted = {"championsMeetings":[_cm("2026-07-14", with_track=False)],  # no track → skip
                 "leagueOfHeroes":[], "pickups":[]}
    doc = build_document(extracted, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    assert doc.championsMeetings == []  # skipped, not a crash

def test_build_tolerates_extra_support_keys():
    extracted = {"championsMeetings":[], "leagueOfHeroes":[],
                 "pickups":[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                             "trainees":["오르페브르"],
                             "supportCards":[{"rarity":"SSR","name":"아몬드 아이","type":"스피드","level":3}]}]}
    doc = build_document(extracted, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    assert doc.pickups[0].supportCards[0].name == "아몬드 아이"

def test_build_dedups_by_id():
    extracted = {"championsMeetings":[_cm("2026-07-14"), _cm("2026-07-14")],
                 "leagueOfHeroes":[], "pickups":[]}
    doc = build_document(extracted, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    assert len(doc.championsMeetings) == 1
