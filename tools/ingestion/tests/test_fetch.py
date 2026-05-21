from pathlib import Path
from umaingest.fetch import extract_image_urls

def test_extract_dedups_and_decodes_amp():
    html = (Path(__file__).parent / "fixtures" / "post.html").read_text()
    urls = extract_image_urls(html)
    assert urls == [
        "https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&no=AAA111",
        "https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&no=BBB222",
    ]

from umaingest.fetch import fetch_post_html, download_image

def test_fetch_post_html_uses_transport():
    calls = {}
    def fake(url, headers): calls["url"] = url; calls["ref"] = headers["Referer"]; return (b"<html>ok</html>", 200)
    html = fetch_post_html(1850737, transport=fake)
    assert "ok" in html
    assert "no=1850737" in calls["url"]

def test_download_image_sends_post_referer():
    seen = {}
    def fake(url, headers): seen["ref"] = headers["Referer"]; return (b"\x00\x01", 200)
    data = download_image("https://dcimg1.dcinside.com/viewimage.php?id=x&no=y", 1850737, transport=fake)
    assert data == b"\x00\x01"
    assert "no=1850737" in seen["ref"]
