from pathlib import Path
from umaingest import cli
from umaingest.vision import VisionResult

def test_run_pipeline_end_to_end_mocked(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "fetch_gallery_list_html", lambda transport=None: '<tr class="ub-content" data-no="1850737"><td class="gall_tit"><a>미래시가이드 2605-A</a></td></tr>')
    monkeypatch.setattr(cli, "fetch_post_html", lambda no, transport=None: '<img src="https://dcimg1.dcinside.com/viewimage.php?id=a&amp;no=S1"/>')
    monkeypatch.setattr(cli, "download_image", lambda url, no, transport=None: b"img")
    monkeypatch.setattr(cli, "png_bytes", lambda raw: b"png")
    monkeypatch.setattr(cli, "make_client", lambda: object())
    monkeypatch.setattr(cli, "extract_slide", lambda data, *, client, media_type="image/png": VisionResult(
        pickups=[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                  "trainees":["오르페브르"],"supportCards":[]}]))

    dest = tmp_path / "data" / "schedule.json"
    result = cli.run(dest=dest, now_iso="2026-05-20T00:00:00Z")
    assert result["post_no"] == 1850737
    assert result["wrote"] is True
    assert dest.exists()
    assert "오르페브르" in dest.read_text(encoding="utf-8")
