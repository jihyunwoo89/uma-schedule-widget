from __future__ import annotations
import base64, json, re
from dataclasses import dataclass, field
from . import prompts

MODEL = "claude-opus-4-7"  # vision-capable; swap if needed

_FENCE_RE = re.compile(r"```(?:json)?\s*(\{.*\})\s*```", re.DOTALL)


@dataclass
class VisionResult:
    championsMeetings: list = field(default_factory=list)
    leagueOfHeroes: list = field(default_factory=list)
    pickups: list = field(default_factory=list)


def _parse_json(text: str) -> dict:
    m = _FENCE_RE.search(text)
    raw = m.group(1) if m else text.strip()
    return json.loads(raw)


def make_client():
    import anthropic
    return anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env


def extract_slide(image_bytes: bytes, *, client, media_type: str = "image/png") -> VisionResult:
    b64 = base64.standard_b64encode(image_bytes).decode("ascii")
    msg = client.messages.create(
        model=MODEL,
        max_tokens=2000,
        system=prompts.SYSTEM,
        messages=[{
            "role": "user",
            "content": [
                {"type": "image", "source": {"type": "base64", "media_type": media_type, "data": b64}},
                {"type": "text", "text": prompts.EXTRACT},
            ],
        }],
    )
    data = _parse_json(msg.content[0].text)
    return VisionResult(
        championsMeetings=data.get("championsMeetings", []),
        leagueOfHeroes=data.get("leagueOfHeroes", []),
        pickups=data.get("pickups", []),
    )
