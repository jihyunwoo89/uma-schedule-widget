from pathlib import Path
from umaingest import cli

def test_run_pipeline_end_to_end_mocked(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "fetch_gallery_list_html", lambda transport=None: '<tr class="ub-content" data-no="1850737"><td class="gall_tit"><a>미래시가이드 2605-A</a></td></tr>')
    monkeypatch.setattr(cli, "fetch_post_html", lambda no, transport=None: '<img src="https://dcimg1.dcinside.com/viewimage.php?id=a&amp;no=S1"/><img src="https://dcimg1.dcinside.com/viewimage.php?id=a&amp;no=S2"/>')
    monkeypatch.setattr(cli, "download_image", lambda url, no, transport=None: b"img")
    monkeypatch.setattr(cli, "png_bytes", lambda raw, max_width=1280: b"png")
    monkeypatch.setattr(cli, "make_client", lambda: object())
    # one consolidated extraction returned for ALL images together
    captured = {}
    def fake_extract(images, *, client, media_type="image/png"):
        captured["n"] = len(images)
        return {"championsMeetings": [], "leagueOfHeroes": [],
                "pickups": [{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                             "trainees":["오르페브르"],"supportCards":[]}]}
    monkeypatch.setattr(cli, "extract_document", fake_extract)

    dest = tmp_path / "data" / "schedule.json"
    result = cli.run(dest=dest, now_iso="2026-05-20T00:00:00Z")
    assert result["post_no"] == 1850737
    assert result["wrote"] is True
    assert result["events"] == 1
    assert captured["n"] == 2          # both slides sent in ONE extract call
    assert dest.exists()
    assert "오르페브르" in dest.read_text(encoding="utf-8")


def test_download_only_saves_slides(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "fetch_gallery_list_html", lambda transport=None: '<tr data-no="1850737"><td class="gall_tit"><a>미래시가이드 X</a></td></tr>')
    monkeypatch.setattr(cli, "fetch_post_html", lambda no, transport=None: '<img src="https://dcimg1.dcinside.com/viewimage.php?id=a&amp;no=S1"/>')
    monkeypatch.setattr(cli, "download_image", lambda url, no, transport=None: b"img")
    monkeypatch.setattr(cli, "png_bytes", lambda raw, max_width=1280: b"png")
    out = tmp_path / "slides"
    res = cli.download_slides(out)
    assert res["saved"] == 1 and res["post_no"] == 1850737
    assert (out / "slide_00.png").exists()
