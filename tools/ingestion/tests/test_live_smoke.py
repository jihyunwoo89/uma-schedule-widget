import os, pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_LIVE_INGEST") != "1" or not os.getenv("ANTHROPIC_API_KEY"),
    reason="live ingest smoke disabled (set RUN_LIVE_INGEST=1 + ANTHROPIC_API_KEY)",
)

def test_live_against_known_post(tmp_path):
    from umaingest import cli
    res = cli.run(dest=tmp_path / "schedule.json", now_iso="2026-05-20T00:00:00Z")
    assert res["post_no"] is not None
    assert (tmp_path / "schedule.json").exists()
