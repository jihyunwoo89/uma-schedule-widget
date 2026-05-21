from umaingest.diff import changed, summarize

def test_changed_detects_difference():
    a = '{"version":2,"championsMeetings":[]}'
    b = '{"version":2,"championsMeetings":[{"id":"x"}]}'
    assert changed(a, b) is True
    assert changed(a, a) is False

def test_changed_ignores_updatedAt_only_change():
    a = '{"updatedAt":"2026-05-20T00:00:00Z","pickups":[]}'
    b = '{"updatedAt":"2026-05-21T00:00:00Z","pickups":[]}'
    assert changed(a, b) is False

def test_summarize_counts():
    s = summarize('{"championsMeetings":[1],"leagueOfHeroes":[],"pickups":[1,2]}')
    assert "CM 1" in s and "LoH 0" in s and "pickup 2" in s
