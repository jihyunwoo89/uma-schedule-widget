from __future__ import annotations
import argparse, datetime, io
from pathlib import Path
from .discover import find_latest_guide_post_no, fetch_gallery_list_html
from .fetch import fetch_post_html, extract_image_urls, download_image
from .vision import extract_slide, make_client
from .assemble import assemble_document
from .publish import write_if_changed


def png_bytes(raw: bytes) -> bytes:
    """Convert a downloaded image (often WebP) to PNG for the vision API."""
    from PIL import Image
    im = Image.open(io.BytesIO(raw)).convert("RGB")
    out = io.BytesIO()
    im.save(out, format="PNG")
    return out.getvalue()


def run(*, dest: Path, now_iso: str | None = None) -> dict:
    now_iso = now_iso or datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    list_html = fetch_gallery_list_html()
    post_no = find_latest_guide_post_no(list_html)
    if post_no is None:
        return {"post_no": None, "wrote": False, "reason": "no guide post found"}

    post_html = fetch_post_html(post_no)
    urls = extract_image_urls(post_html)
    client = make_client()
    slides = []
    for url in urls:
        raw = download_image(url, post_no)
        slides.append(extract_slide(png_bytes(raw), client=client))

    doc = assemble_document(slides, source_post_no=post_no, now_iso=now_iso)
    wrote = write_if_changed(Path(dest), doc.to_json())
    return {"post_no": post_no, "wrote": wrote, "slides": len(slides)}


def main(argv=None):
    ap = argparse.ArgumentParser(description="Ingest DCinside 미래시가이드 → schedule.json")
    ap.add_argument("--dest", default="data/schedule.json")
    args = ap.parse_args(argv)
    result = run(dest=Path(args.dest))
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
