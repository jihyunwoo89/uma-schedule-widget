from __future__ import annotations
import re
from typing import Optional
from .fetch import Transport, _requests_transport

GUIDE_TITLE_PREFIX = "미래시가이드"
_ROW_RE = re.compile(r'data-no="(\d+)"[^>]*>.*?<a[^>]*>(.*?)</a>', re.DOTALL)


_TAG_RE = re.compile(r"<[^>]+>")


def find_latest_guide_post_no(list_html: str) -> Optional[int]:
    """Highest-numbered post whose title starts with 미래시가이드."""
    candidates: list[int] = []
    for no, title in _ROW_RE.findall(list_html):
        # Strip any inline tags (e.g. a leading icon <span>) before the prefix check.
        clean = _TAG_RE.sub("", title).strip()
        if clean.startswith(GUIDE_TITLE_PREFIX):
            candidates.append(int(no))
    return max(candidates) if candidates else None


def fetch_gallery_list_html(transport: Transport = _requests_transport) -> str:
    url = "https://gall.dcinside.com/mgallery/board/lists/?id=umamusu"
    body, status = transport(url, {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124.0 Safari/537.36",
        "Referer": "https://gall.dcinside.com/",
    })
    if status != 200:
        raise RuntimeError(f"gallery list fetch failed: HTTP {status}")
    return body.decode("utf-8", errors="replace")
