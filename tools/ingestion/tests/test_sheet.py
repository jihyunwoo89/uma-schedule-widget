from umaingest.sheet import parse_csv, fetch_sheet_csv
from umaingest.assemble import build_document

CSV = """category,title,raceGrade,raceName,racecourse,surface,distanceMeters,turn,courseSide,season,weather,ground,timeOfDay,start,end,estimated,trainees,supportCards
championsMeeting,MILE,G1,벚꽃상,한신,잔디,1600,우,외측,봄,,,,2026-07-14,2026-07-20,TRUE,,
리그오브히어로즈,10회차,,스프린터즈 스테이크스,나카야마,turf,1200,clockwise,,겨울,,,낮,2026-06-07,,TRUE,,
픽업,,,,,,,,,,,,,2026-05-22,2026-05-28,FALSE,발렌타인 마짱; 발렌타인 제퍼,SSR|카렌짱|근성; SSR|이쿠노 딕터스|지능
"""

def test_parse_csv_maps_categories_and_normalizes():
    d = parse_csv(CSV)
    assert len(d["championsMeetings"]) == 1
    cm = d["championsMeetings"][0]
    assert cm["codeName"] == "MILE"
    assert cm["raceName"] == "벚꽃상"
    assert cm["track"]["surface"] == "turf"        # 잔디 → turf
    assert cm["track"]["turn"] == "clockwise"      # 우 → clockwise
    assert cm["track"]["distanceClass"] == "mile"  # 1600 → mile (auto)
    assert cm["track"]["season"] == "봄"
    assert cm["period"] == {"start":"2026-07-14","end":"2026-07-20","estimated":True}

    loh = d["leagueOfHeroes"][0]
    assert loh["round"] == "10회차"
    assert loh["track"]["distanceClass"] == "sprint"  # 1200
    assert loh["period"]["end"] == "2026-06-07"       # blank end → start

    pk = d["pickups"][0]
    assert pk["trainees"] == ["발렌타인 마짱","발렌타인 제퍼"]
    assert pk["supportCards"] == [{"rarity":"SSR","name":"카렌짱","type":"근성"},
                                  {"rarity":"SSR","name":"이쿠노 딕터스","type":"지능"}]
    assert pk["period"]["estimated"] is False

def test_parsed_csv_builds_valid_document():
    doc = build_document(parse_csv(CSV), now_iso="2026-05-21T00:00:00Z")
    assert len(doc.championsMeetings) == 1 and len(doc.leagueOfHeroes) == 1 and len(doc.pickups) == 1
    assert doc.pickups[0].supportCards[0].name == "카렌짱"

def test_distance_class_boundaries():
    from umaingest.sheet import _distance_class
    assert _distance_class(1400) == "sprint"
    assert _distance_class(1401) == "mile"
    assert _distance_class(1800) == "mile"
    assert _distance_class(2400) == "medium"
    assert _distance_class(2401) == "long"

def test_fetch_sheet_csv_uses_transport():
    captured = {}
    def fake(url, headers): captured["url"] = url; return (b"category\n", 200)
    txt = fetch_sheet_csv("https://docs.google.com/x/pub?output=csv", transport=fake)
    assert "category" in txt and "pub?output=csv" in captured["url"]
