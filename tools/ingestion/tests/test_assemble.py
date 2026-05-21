from umaingest.vision import VisionResult
from umaingest.assemble import assemble_document
from umaingest.models import ScheduleDocument

def _cm(period_start):
    return {"codeName":"LONG","raceGrade":"G1","raceName":"벚꽃상",
            "track":{"racecourse":"한신","surface":"turf","distanceMeters":1600,"distanceClass":"mile"},
            "period":{"start":period_start,"end":"2026-07-20","estimated":True}}

def test_assemble_merges_slides_and_adds_ids_phases():
    slides = [
        VisionResult(championsMeetings=[_cm("2026-07-14")]),
        VisionResult(pickups=[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                               "trainees":["오르페브르","푸리오소"],
                               "supportCards":[{"rarity":"SSR","name":"아몬드 아이","type":"스피드"}]}]),
    ]
    doc = assemble_document(slides, source_post_no=1850737, now_iso="2026-05-20T00:00:00Z")
    assert isinstance(doc, ScheduleDocument)
    assert doc.sourcePostNo == 1850737
    assert len(doc.championsMeetings) == 1
    cm = doc.championsMeetings[0]
    assert cm.id
    assert cm.phases[0].kind == "open"
    assert cm.phases[-1].kind == "ended"
    assert doc.pickups[0].trainees == ["오르페브르","푸리오소"]

def test_assemble_dedups_by_id():
    slides = [VisionResult(championsMeetings=[_cm("2026-07-14")]),
              VisionResult(championsMeetings=[_cm("2026-07-14")])]
    doc = assemble_document(slides, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    assert len(doc.championsMeetings) == 1
