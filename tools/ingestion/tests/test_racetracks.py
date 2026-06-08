from umaingest import racetracks as rt
from umaingest.assemble import build_document
from umaingest.sheet import parse_kr_rows


def test_known_courses_resolve_to_unique_images():
    cases = {
        ("한신", "turf", 1600): "course_10009_10903",
        ("교토", "turf", 3200): "course_10008_10811",
        ("도쿄", "turf", 2400): "course_10006_10606",
        ("한신", "turf", 2200): "course_10009_10906",
        ("나카야마", "turf", 1200): "course_10005_10501",
        ("오이", "dirt", 2000): "course_10101_11103",
    }
    for (kr, surf, m), expected in cases.items():
        assert rt.course_image_name(kr, surf, m) == expected


def test_ambiguous_kyoto_uses_course_side():
    inner = rt.course_image_name("교토", "turf", 1600, course_side="inner")
    outer = rt.course_image_name("교토", "turf", 1600, course_side="outer")
    assert inner != outer
    # verified: lower inout (10804) = 내(inner), higher (10805) = 외(outer)
    assert inner == "course_10008_10804"
    assert outer == "course_10008_10805"
    # deterministic default when no side given
    assert rt.course_image_name("교토", "turf", 1600) == "course_10008_10804"


def test_course_side_string_variants():
    for s in ("외", "외측", "외회", "바깥", "바깥쪽", "outer", "2"):
        assert rt.course_image_name("교토", "turf", 1600, course_side=s) == "course_10008_10805"
    for s in ("내", "내측", "내회", "안", "안쪽", "inner", "1"):
        assert rt.course_image_name("교토", "turf", 1600, course_side=s) == "course_10008_10804"


def test_race_name_resolves_exact_course():
    # authoritative race-name lookup (incl. grade-prefix / spacing normalization)
    assert rt.course_image_name_by_race("벚꽃상", "한신") == "course_10009_10903"
    assert rt.course_image_name_by_race("텐노상(봄)", "교토") == "course_10008_10811"
    assert rt.course_image_name_by_race("G1 재팬 더트 더비", "오이") == "course_10101_11103"


def test_race_name_resolves_inner_outer_ambiguity():
    # 마일 챔피언십 at kyoto is the OUTER 1600 (10805) — race name disambiguates
    assert rt.course_image_name("교토", "turf", 1600, race_name="마일 챔피언십") == "course_10008_10805"
    # without race name it defaults to the lower id (inner)
    assert rt.course_image_name("교토", "turf", 1600) == "course_10008_10804"


def test_race_name_miss_falls_back_to_terrain_length():
    # transliteration/abbrev mismatch → fall back; nakayama 1200 is unambiguous → correct
    assert rt.course_image_name_by_race("G1 스프린터즈 S", "나카야마") is None
    assert rt.course_image_name("나카야마", "turf", 1200, race_name="G1 스프린터즈 S") == "course_10005_10501"


def test_unknown_returns_none():
    assert rt.course_image_name("없는경기장", "turf", 1600) is None
    assert rt.course_image_name("한신", "turf", 9999) is None


def test_data_has_17_racecourses():
    assert len(rt.load_data()) == 17
    assert sum(1 for _ in rt.iter_courses()) == 138


def test_assemble_populates_course_map():
    doc = build_document({
        "championsMeetings": [{
            "codeName": "LONG", "raceGrade": "G1", "raceName": "벚꽃상",
            "track": {"racecourse": "한신", "surface": "turf",
                      "distanceMeters": 1600, "distanceClass": "mile"},
            "period": {"start": "2026-07-14", "end": "2026-07-20", "estimated": True},
        }],
        "leagueOfHeroes": [], "pickups": [],
    }, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    assert doc.championsMeetings[0].track.courseMap == "course_10009_10903"


def test_sheet_course_column_disambiguates_to_outer():
    rows = [{
        "날짜": "2026-08-01", "분류": "챔피언스 미팅", "제목": "「테스트」",
        "레이스": "G1 마일 챔피언십", "마장": "교토, 잔디 1600m(마일), 시계(우), 봄",
        "코스": "외",  # dedicated column → outer
    }]
    extracted = parse_kr_rows(rows)
    doc = build_document(extracted, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    cm = doc.championsMeetings[0]
    assert cm.track.courseSide == "외"
    assert cm.track.courseMap == "course_10008_10805"  # outer kyoto 1600
