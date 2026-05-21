from __future__ import annotations
import argparse, datetime, io
from pathlib import Path
from .discover import find_latest_guide_post_no, fetch_gallery_list_html
from .fetch import fetch_post_html, extract_image_urls, download_image
from .vision import extract_document, make_client
from .assemble import build_document
from .publish import write_if_changed


def png_bytes(raw: bytes, max_width: int = 1280) -> bytes:
    """Convert a downloaded image (often WebP) to PNG, downscaled to bound vision token cost."""
    from PIL import Image
    im = Image.open(io.BytesIO(raw)).convert("RGB")
    if im.width > max_width:
        h = round(im.height * max_width / im.width)
        im = im.resize((max_width, h))
    out = io.BytesIO()
    im.save(out, format="PNG")
    return out.getvalue()


def run(*, dest: Path, now_iso: str | None = None) -> dict:
    now_iso = now_iso or datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    post_no = find_latest_guide_post_no(fetch_gallery_list_html())
    if post_no is None:
        return {"post_no": None, "wrote": False, "reason": "no guide post found"}

    urls = extract_image_urls(fetch_post_html(post_no))
    images = [png_bytes(download_image(u, post_no)) for u in urls]
    client = make_client()
    extracted = extract_document(images, client=client)
    doc = build_document(extracted, source_post_no=post_no, now_iso=now_iso)
    wrote = write_if_changed(Path(dest), doc.to_json())
    return {
        "post_no": post_no, "wrote": wrote, "slides": len(images),
        "events": len(doc.championsMeetings) + len(doc.leagueOfHeroes) + len(doc.pickups),
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Ingest DCinside 미래시가이드 → schedule.json")
    ap.add_argument("--dest", default="data/schedule.json")
    args = ap.parse_args(argv)
    print(run(dest=Path(args.dest)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
