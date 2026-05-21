from pathlib import Path
from umaingest.discover import find_latest_guide_post_no

def test_picks_highest_numbered_guide_post():
    html = (Path(__file__).parent / "fixtures" / "gallery_list.html").read_text()
    assert find_latest_guide_post_no(html) == 1850999

def test_returns_none_when_no_guide():
    assert find_latest_guide_post_no("<html><body>nothing</body></html>") is None

def test_title_with_leading_icon_span_still_matches():
    html = '<tr data-no="1860000"><td class="gall_tit"><a href="/x"><span class="ico"></span>미래시가이드 2607-A</a></td></tr>'
    assert find_latest_guide_post_no(html) == 1860000
