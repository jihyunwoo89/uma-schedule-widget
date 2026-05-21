from pathlib import Path
from umaingest.sheet import parse_csv, fetch_sheet_csv, parse_kr_csv, _parse_track_packed, _parse_race
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


# --- KR human-friendly sheet format ---

def _kr_fixture() -> str:
    return (Path(__file__).parent / "fixtures" / "kr_sheet.csv").read_text(encoding="utf-8")

def test_parse_track_packed_full_and_partial():
    full = _parse_track_packed("한신, 잔디 1600m(마일), 시계(우), 봄, 맑음, 양호, 낮")
    assert full == {"racecourse":"한신","surface":"turf","distanceMeters":1600,"distanceClass":"mile",
                    "turn":"clockwise","season":"봄","weather":"맑음","ground":"양호","timeOfDay":"낮"}
    partial = _parse_track_packed("나카야마, 잔디 1200m(단거리), 시계(우), 겨울, 낮")
    assert partial["distanceClass"] == "sprint" and partial["season"] == "겨울" and partial["timeOfDay"] == "낮"
    assert "weather" not in partial and "ground" not in partial

def test_parse_race_grade_split():
    assert _parse_race("G1 벚꽃상") == ("G1", "벚꽃상")
    assert _parse_race("재팬 더트 더비") == (None, "재팬 더트 더비")

def test_parse_kr_fixture_counts_and_fields():
    d = parse_kr_csv(_kr_fixture())
    assert len(d["championsMeetings"]) == 4   # 벚꽃상, 텐노상, 오크스, 타카라즈카
    assert len(d["leagueOfHeroes"]) == 2       # 스프린터즈, 재팬 더트 더비
    assert len(d["pickups"]) == 18             # 24 rows - 4 CM - 2 LoH

    cm = d["championsMeetings"][0]
    assert cm["codeName"] == "MILE" and cm["raceGrade"] == "G1" and cm["raceName"] == "벚꽃상"
    assert cm["track"]["racecourse"] == "한신" and cm["track"]["distanceClass"] == "mile"

    loh = d["leagueOfHeroes"][0]
    assert loh["round"] == "10회차" and "스프린터즈" in loh["raceName"]

    # pickup with structured supports
    pk = d["pickups"][0]
    assert pk["trainees"] == ["발렌타인 애스턴 마짱 3★", "발렌타인 야마닌 제퍼 3★"]
    assert pk["supportCards"] == [{"rarity":"SSR","name":"카렌짱","type":"근성"},
                                  {"rarity":"SSR","name":"이쿠노 딕터스","type":"지능"}]
    # "셀렉트 픽업" pickup -> no structured cards
    select = d["pickups"][1]
    assert select["supportCards"] == []

def test_parse_csv_autodetects_kr():
    d = parse_csv(_kr_fixture())   # parse_csv should route to KR parser via the 날짜 header
    assert len(d["championsMeetings"]) == 4

def test_kr_fixture_builds_valid_document():
    doc = build_document(parse_kr_csv(_kr_fixture()), now_iso="2026-05-21T00:00:00Z")
    assert len(doc.championsMeetings) == 4 and len(doc.leagueOfHeroes) == 2 and len(doc.pickups) == 18
