from __future__ import annotations
import argparse, datetime, io
from pathlib import Path
from .discover import find_latest_guide_post_no, fetch_gallery_list_html
from .fetch import fetch_post_html, extract_image_urls, download_image
from .vision import extract_document, make_client
from .assemble import build_document
from .publish import write_if_changed
from .sheet import fetch_sheet_csv, parse_csv


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


def run_from_sheet(*, url: str, dest: Path, now_iso: str | None = None) -> dict:
    now_iso = now_iso or datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    extracted = parse_csv(fetch_sheet_csv(url))
    doc = build_document(extracted, source_post_no=None, now_iso=now_iso)
    wrote = write_if_changed(Path(dest), doc.to_json())
    return {"source": "sheet", "wrote": wrote,
            "events": len(doc.championsMeetings) + len(doc.leagueOfHeroes) + len(doc.pickups)}


def download_slides(out_dir: Path) -> dict:
    """Free mode: download the latest guide's slides (PNG) to out_dir. No vision/API call."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    post_no = find_latest_guide_post_no(fetch_gallery_list_html())
    if post_no is None:
        return {"post_no": None, "saved": 0}
    urls = extract_image_urls(fetch_post_html(post_no))
    for i, u in enumerate(urls):
        (out_dir / f"slide_{i:02d}.png").write_bytes(png_bytes(download_image(u, post_no)))
    return {"post_no": post_no, "saved": len(urls), "dir": str(out_dir)}


def main(argv=None):
    ap = argparse.ArgumentParser(description="Ingest Umamusume schedule → schedule.json")
    ap.add_argument("--dest", default="data/schedule.json")
    ap.add_argument("--from-sheet", metavar="CSV_URL", default=None,
                    help="Build schedule.json from a published Google Sheet CSV URL (recommended).")
    ap.add_argument("--download-only", metavar="DIR", default=None,
                    help="(DCinside path) download the latest guide's slides to DIR.")
    args = ap.parse_args(argv)
    if args.from_sheet:
        print(run_from_sheet(url=args.from_sheet, dest=Path(args.dest)))
    elif args.download_only:
        print(download_slides(Path(args.download_only)))
    else:
        print(run(dest=Path(args.dest)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
