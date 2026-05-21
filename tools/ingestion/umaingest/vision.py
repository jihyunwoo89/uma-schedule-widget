from __future__ import annotations
import base64, json, re
from . import prompts

MODEL = "claude-opus-4-7"  # vision-capable; swap if needed

_FENCE_RE = re.compile(r"```(?:json)?\s*(\{.*\})\s*```", re.DOTALL)


def _parse_json(text: str) -> dict:
    m = _FENCE_RE.search(text)
    raw = m.group(1) if m else text.strip()
    return json.loads(raw)


def make_client():
    import anthropic
    return anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env


def extract_document(images: list[bytes], *, client, media_type: str = "image/png") -> dict:
    """Send ALL slides in ONE request so the model cross-references conditions+dates
    into complete events. Returns a dict with championsMeetings/leagueOfHeroes/pickups."""
    content: list[dict] = []
    for img in images:
        b64 = base64.standard_b64encode(img).decode("ascii")
        content.append({"type": "image", "source": {"type": "base64", "media_type": media_type, "data": b64}})
    content.append({"type": "text", "text": prompts.MULTI_EXTRACT})
    msg = client.messages.create(
        model=MODEL, max_tokens=8000, system=prompts.MULTI_SYSTEM,
        messages=[{"role": "user", "content": content}],
    )
    data = _parse_json(msg.content[0].text)
    return {
        "championsMeetings": data.get("championsMeetings", []),
        "leagueOfHeroes": data.get("leagueOfHeroes", []),
        "pickups": data.get("pickups", []),
    }
