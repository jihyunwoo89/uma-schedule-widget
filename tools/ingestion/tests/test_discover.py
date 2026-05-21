from pathlib import Path
from umaingest.discover import find_latest_guide_post_no

def test_picks_highest_numbered_guide_post():
    html = (Path(__file__).parent / "fixtures" / "gallery_list.html").read_text()
    assert find_latest_guide_post_no(html) == 1850999

def test_returns_none_when_no_guide():
    assert find_latest_guide_post_no("<html><body>nothing</body></html>") is None
