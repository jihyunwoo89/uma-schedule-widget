from __future__ import annotations
import json


def _normalize(doc_json: str) -> str:
    d = json.loads(doc_json)
    d.pop("updatedAt", None)  # timestamp churn shouldn't count as a change
    return json.dumps(d, sort_keys=True, ensure_ascii=False)


def changed(old_json: str, new_json: str) -> bool:
    return _normalize(old_json) != _normalize(new_json)


def summarize(doc_json: str) -> str:
    d = json.loads(doc_json)
    return (f"CM {len(d.get('championsMeetings', []))}, "
            f"LoH {len(d.get('leagueOfHeroes', []))}, "
            f"pickup {len(d.get('pickups', []))}")
