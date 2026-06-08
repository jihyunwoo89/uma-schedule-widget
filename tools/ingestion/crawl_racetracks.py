#!/usr/bin/env python3
"""Download all gametora course-map PNGs into the app's asset catalog.

Bundles each course as a single-scale imageset `course_{id1}_{id2}` under
Core/.../Media.xcassets/Racetracks/ so it is loadable via
`Image("course_{id1}_{id2}", bundle: .module)` in both the app and the widget.

Polite: sequential, short delay, retries, skips already-downloaded images.

Usage:
    python3 crawl_racetracks.py            # download missing
    python3 crawl_racetracks.py --force    # re-download all
    python3 crawl_racetracks.py --refresh  # refresh data snapshot first
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

from umaingest import racetracks as rt

REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "Core/Sources/UmaCore/Resources/Media.xcassets/Racetracks"

_IMAGESET_INFO = {"author": "xcode", "version": 1}
_DELAY = 0.15      # seconds between requests
_RETRIES = 3


def _download(url: str) -> bytes:
    last = None
    for attempt in range(_RETRIES):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": rt._UA})
            with urllib.request.urlopen(req, timeout=30, context=rt.SSL_CTX) as r:
                data = r.read()
            if not data.startswith(b"\x89PNG"):
                raise ValueError("not a PNG")
            return data
        except (urllib.error.URLError, ValueError, TimeoutError) as e:
            last = e
            time.sleep(0.5 * (attempt + 1))
    raise RuntimeError(f"failed after {_RETRIES} tries: {url} ({last})")


def _write_imageset(name: str, png: bytes) -> None:
    d = ASSETS / f"{name}.imageset"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.png").write_bytes(png)
    contents = {
        "images": [{"filename": f"{name}.png", "idiom": "universal"}],
        "info": _IMAGESET_INFO,
    }
    (d / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="re-download existing")
    ap.add_argument("--refresh", action="store_true", help="refresh data snapshot first")
    args = ap.parse_args()

    if args.refresh:
        print("refreshing data snapshot...")
        rt.refresh_snapshot()

    ASSETS.mkdir(parents=True, exist_ok=True)
    # folder Contents.json (no namespace -> flat asset names)
    (ASSETS / "Contents.json").write_text(
        json.dumps({"info": _IMAGESET_INFO, "properties": {"provides-namespace": False}}, indent=2),
        encoding="utf-8")

    courses = list(rt.iter_courses())
    total = len(courses)
    done = skipped = failed = 0
    for i, (id1, c) in enumerate(courses, 1):
        name = rt.image_name(id1, c["id"])
        target = ASSETS / f"{name}.imageset" / f"{name}.png"
        if target.exists() and not args.force:
            skipped += 1
            continue
        url = rt.image_url(id1, c["id"])
        try:
            png = _download(url)
            _write_imageset(name, png)
            done += 1
            print(f"[{i}/{total}] {name}  ({len(png)} B)")
        except RuntimeError as e:
            failed += 1
            print(f"[{i}/{total}] FAIL {name}: {e}", file=sys.stderr)
        time.sleep(_DELAY)

    print(f"\ndone={done} skipped={skipped} failed={failed} total={total}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
