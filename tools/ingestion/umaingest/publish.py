from __future__ import annotations
from pathlib import Path
from .diff import changed


def write_if_changed(dest: Path, new_json: str) -> bool:
    """Write new_json to dest only if it differs (ignoring updatedAt). Returns True if written."""
    dest = Path(dest)
    if dest.exists():
        if not changed(dest.read_text(encoding="utf-8"), new_json):
            return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(new_json, encoding="utf-8")
    return True
