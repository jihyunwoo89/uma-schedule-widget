#!/usr/bin/env python3
"""Apply the event end-date rules to an existing schedule.json in place.

Mirrors umaingest.assemble (CM +6d, LoH +9d, pickup -> next pickup start). Used to
migrate already-published JSON; future sheet regenerations apply the rules natively.

    python3 migrate_end_dates.py path/to/schedule.json [more.json ...]
"""
from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta

from umaingest.assemble import CM_DURATION_DAYS, LOH_DURATION_DAYS, PICKUP_LONE_FALLBACK_DAYS


def _parse(s: str) -> datetime:
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def _fmt(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%dT00:00:00Z")  # UTC date, TZ-stable


def _track_period(e: dict) -> dict:
    return e["period"]


def _set_end(e: dict, end: datetime) -> None:
    e["period"]["end"] = _fmt(end)
    for ph in e.get("phases", []):
        if ph.get("kind") == "ended":
            ph["date"] = _fmt(end)


def migrate(doc: dict) -> int:
    n = 0
    for cm in doc.get("championsMeetings", []):
        start = _parse(cm["period"]["start"])
        _set_end(cm, start + timedelta(days=CM_DURATION_DAYS)); n += 1
    for loh in doc.get("leagueOfHeroes", []):
        start = _parse(loh["period"]["start"])
        _set_end(loh, start + timedelta(days=LOH_DURATION_DAYS)); n += 1
    pks = sorted(doc.get("pickups", []), key=lambda p: _parse(p["period"]["start"]))
    for i, p in enumerate(pks):
        start = _parse(p["period"]["start"])
        if i + 1 < len(pks):
            end = _parse(pks[i + 1]["period"]["start"])
        elif i > 0:
            end = start + (start - _parse(pks[i - 1]["period"]["start"]))
        else:
            end = start + timedelta(days=PICKUP_LONE_FALLBACK_DAYS)
        p["period"]["end"] = _fmt(end); n += 1
    return n


def main(paths: list[str]) -> int:
    for path in paths:
        doc = json.load(open(path, encoding="utf-8"))
        n = migrate(doc)
        json.dump(doc, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"{path}: updated end dates on {n} events")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:] or ["../../data/schedule.json"]))
