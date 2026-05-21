from __future__ import annotations
import re
from typing import Callable

_IMG_RE = re.compile(r'https://dcimg\d+\.dcinside\.com/viewimage\.php\?[^"\'\s]+')

# Transport: (url, headers) -> (body_bytes, status). Injectable for tests.
Transport = Callable[[str, dict], tuple[bytes, int]]


def extract_image_urls(html: str) -> list[str]:
    """All dcimg viewimage URLs in document order, &amp; decoded, de-duplicated."""
    seen: set[str] = set()
    out: list[str] = []
    for raw in _IMG_RE.findall(html):
        url = raw.replace("&amp;", "&")
        if url not in seen:
            seen.add(url)
            out.append(url)
    return out


def _requests_transport(url: str, headers: dict) -> tuple[bytes, int]:
    import requests
    r = requests.get(url, headers=headers, timeout=20)
    return r.content, r.status_code


def fetch_post_html(post_no: int, transport: Transport = _requests_transport) -> str:
    url = f"https://gall.dcinside.com/mgallery/board/view/?id=umamusu&no={post_no}"
    body, status = transport(url, {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124.0 Safari/537.36",
        "Referer": "https://gall.dcinside.com/",
    })
    if status != 200:
        raise RuntimeError(f"post fetch failed: HTTP {status}")
    return body.decode("utf-8", errors="replace")


def download_image(url: str, post_no: int, transport: Transport = _requests_transport) -> bytes:
    """Download a dcimg image; dcimg requires a board Referer (hotlink protection)."""
    body, status = transport(url, {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
        "Referer": f"https://gall.dcinside.com/mgallery/board/view/?id=umamusu&no={post_no}",
    })
    if status != 200:
        raise RuntimeError(f"image fetch failed: HTTP {status}")
    return body
