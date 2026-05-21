# Workstream B — DCinside Ingestion Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a review-gated pipeline that reads the DCinside "미래시가이드" schedule images, extracts a schema-v2 `schedule.json` via Claude vision, and opens a PR for human approval before the app consumes it.

**Architecture:** A self-contained Python package at `tools/ingestion/`. Deterministic units (HTML→image-URL parsing, latest-post discovery, document assembly, JSON-Schema validation, date serialization, diff) are pure and TDD'd with fixtures. The network fetch and the Claude vision call sit behind injectable clients so unit tests never hit the network or the API. A GitHub Actions workflow runs it on a weekly cron + manual dispatch; on a content change it opens a PR (the review gate). The published `schedule.json` matches the Swift v2 `ScheduleDocument` exactly (the app already fetches it via `ScheduleEndpoint.url`).

**Tech Stack:** Python 3.11+, `requests`, `anthropic` (Claude vision), `pydantic` v2 (model + validation), `pytest`, GitHub Actions.

**Reference spec:** `docs/superpowers/specs/2026-05-21-uma-widget-v2-rich-schema-and-ingestion-design.md` (§5).

## Locked decisions
- **Language: Python 3.11+.** Package dir: `tools/ingestion/` inside this repo (version-controlled with the app). The workflow can later be copied to a dedicated data repo; the code is repo-agnostic.
- **Publish target = the repo the workflow runs in**, at `data/schedule.json`, via a PR (review gate). The user points `ScheduleEndpoint.url` (in Swift) at that file's raw URL once the repo/remote exists. (Open item until the repo is created.)
- **Names in Korean** (as the guide presents them).
- **Date wire format**: ISO-8601 with a `Z` suffix (e.g. `2026-07-14T00:00:00Z`) to match the bundled fallback and Swift's `.iso8601` decoder.
- **Source**: latest post whose title starts with `미래시가이드` in the `umamusu` minor gallery.
- Secrets/setup the USER provides later: a GitHub repo with Actions, `ANTHROPIC_API_KEY` secret, and (for the PR step) default `GITHUB_TOKEN` (auto-provided by Actions).

## Conventions
- Working dir for commands: `/Users/damienjee/Desktop/claude_dev/uma_schedule_widget/tools/ingestion`
- Set up once: `python3 -m venv .venv && . .venv/bin/activate && pip install -e ".[dev]"`
- Run tests: `. .venv/bin/activate && pytest -q`
- Single test: `pytest tests/test_foo.py::test_bar -q`
- TDD: failing test → confirm fail → implement → confirm pass → commit. Commit per task.
- Unit tests MUST NOT hit the network or the Anthropic API. Live integration is behind env flags and is not run in CI unit gates.

## File Structure
```
tools/ingestion/
  pyproject.toml                 # package + deps + pytest config
  umaingest/
    __init__.py
    models.py                    # pydantic v2 models == Swift v2 schema; iso-Z serialization
    discover.py                  # find latest "미래시가이드" post no from gallery list HTML
    fetch.py                     # post HTML → dcimg image URLs; image download (Referer)
    vision.py                    # Claude vision client: slides → extracted dicts (injectable)
    assemble.py                  # merge slide extractions → ScheduleDocument; validate
    diff.py                      # compare two schedule docs → changed? + summary
    publish.py                   # write data/schedule.json; (CI) git branch + PR
    cli.py                       # orchestration entrypoint: discover→fetch→vision→assemble→diff→publish
    prompts.py                   # vision prompt templates (classification + extraction)
  tests/
    fixtures/                    # saved HTML + a recorded vision response JSON
    test_models.py
    test_discover.py
    test_fetch.py
    test_vision.py
    test_assemble.py
    test_diff.py
    test_cli.py
  .github/workflows/ingest.yml   # (created under repo root .github/, see Task B6.2)
  README.md
```

---

# Phase B0 — Project scaffold

### Task B0.1: Python package + pytest
**Files:** Create `tools/ingestion/pyproject.toml`, `tools/ingestion/umaingest/__init__.py`, `tools/ingestion/tests/__init__.py`

- [ ] **Step 1: Verify the parent dir exists**
Run: `ls /Users/damienjee/Desktop/claude_dev/uma_schedule_widget` (expect App/ Core/ Widgets/ docs/ ...). Then `mkdir -p tools/ingestion/umaingest tools/ingestion/tests/fixtures`.

- [ ] **Step 2: Write `tools/ingestion/pyproject.toml`**
```toml
[project]
name = "umaingest"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31",
    "anthropic>=0.40",
    "pydantic>=2.6",
]

[project.optional-dependencies]
dev = ["pytest>=8.0"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools]
packages = ["umaingest"]
```

- [ ] **Step 3: Write `tools/ingestion/umaingest/__init__.py`**
```python
"""Umamusume KR schedule ingestion pipeline (DCinside 미래시가이드 → schedule.json)."""
__version__ = "0.1.0"
```
And empty `tools/ingestion/tests/__init__.py`:
```python
```

- [ ] **Step 4: Create venv + install + confirm pytest runs (no tests yet)**
Run: `cd tools/ingestion && python3 -m venv .venv && . .venv/bin/activate && pip install -e ".[dev]" && pytest -q`
Expected: pytest reports "no tests ran" (exit code 5) — acceptable; confirms install works. If `pip install` fails (offline), report BLOCKED with the error.

- [ ] **Step 5: Add `.venv` to ignore**
Append to the repo-root `.gitignore`: `tools/ingestion/.venv/` and `__pycache__/` and `*.egg-info/`.

- [ ] **Step 6: Commit**
```bash
git add tools/ingestion/pyproject.toml tools/ingestion/umaingest/__init__.py tools/ingestion/tests/__init__.py .gitignore
git commit -m "chore(ingest): scaffold Python pipeline package"
```

---

# Phase B1 — Models & schema (the contract)

### Task B1.1: pydantic models matching Swift v2 + iso-Z serialization
**Files:** Create `tools/ingestion/umaingest/models.py`; Test `tools/ingestion/tests/test_models.py`

- [ ] **Step 1: Write the failing test**
```python
import json
from umaingest.models import ScheduleDocument, ChampionsMeeting, TrackCondition, EventPeriod, EventPhase

def _track():
    return TrackCondition(racecourse="한신", surface="turf", distanceMeters=1600, distanceClass="mile",
                          turn="clockwise", courseSide="외측", season="봄")

def test_round_trip_and_iso_z():
    doc = ScheduleDocument(
        version=2, updatedAt="2026-05-20T00:00:00Z", sourcePostNo=1850737, server="kr",
        championsMeetings=[ChampionsMeeting(
            id="cm", codeName="LONG", raceGrade="G1", raceName="벚꽃상", track=_track(),
            period=EventPeriod(start="2026-07-14T00:00:00Z", end="2026-07-20T00:00:00Z", estimated=True),
            phases=[EventPhase(kind="open", label="오픈", date="2026-07-14T00:00:00Z")])],
        leagueOfHeroes=[], pickups=[])
    s = doc.to_json()
    parsed = json.loads(s)
    assert parsed["version"] == 2
    assert parsed["championsMeetings"][0]["codeName"] == "LONG"
    # dates must serialize with a trailing Z (Swift .iso8601 contract)
    assert parsed["championsMeetings"][0]["period"]["start"] == "2026-07-14T00:00:00Z"
    assert parsed["updatedAt"].endswith("Z")

def test_validation_rejects_bad_enum():
    import pytest
    with pytest.raises(Exception):
        TrackCondition(racecourse="x", surface="grass", distanceMeters=1, distanceClass="mile")

def test_optional_fields_serialize_as_null_or_value():
    t = TrackCondition(racecourse="도쿄", surface="dirt", distanceMeters=2000, distanceClass="medium")
    d = json.loads(ScheduleDocument(version=2, updatedAt="2026-05-20T00:00:00Z", server="kr",
        championsMeetings=[], leagueOfHeroes=[], pickups=[]).to_json())
    assert d["sourcePostNo"] is None
    assert t.turn is None
```

- [ ] **Step 2: Run** `cd tools/ingestion && . .venv/bin/activate && pytest tests/test_models.py -q` — FAIL (no module).

- [ ] **Step 3: Implement `umaingest/models.py`**
```python
from __future__ import annotations
from datetime import datetime, timezone
from typing import Literal, Optional
from pydantic import BaseModel, field_serializer

Surface = Literal["turf", "dirt"]
DistanceClass = Literal["sprint", "mile", "medium", "long"]
Turn = Literal["clockwise", "counterclockwise", "straight"]
PhaseKind = Literal["open", "round1", "round2", "ended"]


def _iso_z(value) -> str:
    """Serialize a datetime/str to ISO-8601 with a 'Z' suffix (Swift .iso8601 contract)."""
    if isinstance(value, str):
        # Accept already-formatted strings; normalize +00:00 → Z.
        return value.replace("+00:00", "Z")
    dt = value.astimezone(timezone.utc).replace(microsecond=0)
    return dt.isoformat().replace("+00:00", "Z")


class _Base(BaseModel):
    model_config = {"extra": "forbid"}


class EventPeriod(_Base):
    start: datetime
    end: datetime
    estimated: bool = False

    @field_serializer("start", "end")
    def _ser(self, v): return _iso_z(v)


class EventPhase(_Base):
    kind: PhaseKind
    label: str
    date: datetime

    @field_serializer("date")
    def _ser(self, v): return _iso_z(v)


class TrackCondition(_Base):
    racecourse: str
    surface: Surface
    distanceMeters: int
    distanceClass: DistanceClass
    turn: Optional[Turn] = None
    courseSide: Optional[str] = None
    season: Optional[str] = None
    weather: Optional[str] = None
    ground: Optional[str] = None
    timeOfDay: Optional[str] = None
    imageURL: Optional[str] = None


class ChampionsMeeting(_Base):
    id: str
    codeName: str
    raceGrade: Optional[str] = None
    raceName: str
    track: TrackCondition
    period: EventPeriod
    phases: list[EventPhase]


class LeagueOfHeroes(_Base):
    id: str
    round: str
    raceName: str
    track: TrackCondition
    period: EventPeriod
    phases: list[EventPhase]


class SupportCardPick(_Base):
    rarity: str
    name: str
    type: str


class PickupPeriod(_Base):
    id: str
    period: EventPeriod
    trainees: list[str]
    supportCards: list[SupportCardPick]


class ScheduleDocument(_Base):
    version: int = 2
    updatedAt: datetime
    sourcePostNo: Optional[int] = None
    server: str = "kr"
    championsMeetings: list[ChampionsMeeting]
    leagueOfHeroes: list[LeagueOfHeroes]
    pickups: list[PickupPeriod]

    @field_serializer("updatedAt")
    def _ser(self, v): return _iso_z(v)

    def to_json(self) -> str:
        return self.model_dump_json(indent=2)
```

- [ ] **Step 4: Run** `pytest tests/test_models.py -q` — PASS (3 tests).

- [ ] **Step 5: Commit**
```bash
git add tools/ingestion/umaingest/models.py tools/ingestion/tests/test_models.py
git commit -m "feat(ingest): pydantic v2 models matching Swift schema (iso-Z dates)"
```

---

# Phase B2 — Fetch & discovery (HTML parsing)

### Task B2.1: image-URL extraction from post HTML
**Files:** Create `tools/ingestion/umaingest/fetch.py`; fixture `tools/ingestion/tests/fixtures/post.html`; Test `tools/ingestion/tests/test_fetch.py`

- [ ] **Step 1: Create the fixture** `tools/ingestion/tests/fixtures/post.html` (minimal HTML mimicking a DCinside post body with dcimg images; the real markup wraps images in the write content div):
```html
<!DOCTYPE html><html><body>
<div class="write_div">
  <img src="https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&amp;no=AAA111" />
  <img src="https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&amp;no=BBB222" />
  <img src="https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&amp;no=AAA111" />
  <img src="https://nope.example.com/not-a-dcimg.png" />
</div>
</body></html>
```

- [ ] **Step 2: Write the failing test** `tools/ingestion/tests/test_fetch.py`
```python
from pathlib import Path
from umaingest.fetch import extract_image_urls

def test_extract_dedups_and_decodes_amp():
    html = (Path(__file__).parent / "fixtures" / "post.html").read_text()
    urls = extract_image_urls(html)
    assert urls == [
        "https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&no=AAA111",
        "https://dcimg1.dcinside.com/viewimage.php?id=38b0d12bf0c12d&no=BBB222",
    ]
    # non-dcimg images excluded; order preserved; duplicates removed
```

- [ ] **Step 3: Run** `pytest tests/test_fetch.py -q` — FAIL (no module).

- [ ] **Step 4: Implement `umaingest/fetch.py`** (extraction is pure; download uses an injectable transport)
```python
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
```

- [ ] **Step 5: Run** `pytest tests/test_fetch.py -q` — PASS.

- [ ] **Step 6: Add a download test** (injected transport, no network) — append to `test_fetch.py`:
```python
from umaingest.fetch import fetch_post_html, download_image

def test_fetch_post_html_uses_transport():
    calls = {}
    def fake(url, headers): calls["url"] = url; calls["ref"] = headers["Referer"]; return (b"<html>ok</html>", 200)
    html = fetch_post_html(1850737, transport=fake)
    assert "ok" in html
    assert "no=1850737" in calls["url"]

def test_download_image_sends_post_referer():
    seen = {}
    def fake(url, headers): seen["ref"] = headers["Referer"]; return (b"\x00\x01", 200)
    data = download_image("https://dcimg1.dcinside.com/viewimage.php?id=x&no=y", 1850737, transport=fake)
    assert data == b"\x00\x01"
    assert "no=1850737" in seen["ref"]
```
Run `pytest tests/test_fetch.py -q` — PASS (3 tests).

- [ ] **Step 7: Commit**
```bash
git add tools/ingestion/umaingest/fetch.py tools/ingestion/tests/test_fetch.py tools/ingestion/tests/fixtures/post.html
git commit -m "feat(ingest): post HTML fetch + dcimg URL extraction + image download"
```

### Task B2.2: latest "미래시가이드" post discovery
**Files:** Create `tools/ingestion/umaingest/discover.py`; fixture `tools/ingestion/tests/fixtures/gallery_list.html`; Test `tools/ingestion/tests/test_discover.py`

- [ ] **Step 1: Create fixture** `tools/ingestion/tests/fixtures/gallery_list.html` (mimics the gallery list rows; real DCinside rows carry `data-no` and a title link):
```html
<!DOCTYPE html><html><body>
<table class="gall_list"><tbody>
  <tr class="ub-content" data-no="1850500"><td class="gall_tit"><a href="/x">잡담글</a></td></tr>
  <tr class="ub-content" data-no="1850737"><td class="gall_tit"><a href="/x">미래시가이드 2605-A</a></td></tr>
  <tr class="ub-content" data-no="1850999"><td class="gall_tit"><a href="/x">미래시가이드 2606-A</a></td></tr>
  <tr class="ub-content" data-no="1851000"><td class="gall_tit"><a href="/x">공지글</a></td></tr>
</tbody></table>
</body></html>
```

- [ ] **Step 2: Write the failing test** `tools/ingestion/tests/test_discover.py`
```python
from pathlib import Path
from umaingest.discover import find_latest_guide_post_no

def test_picks_highest_numbered_guide_post():
    html = (Path(__file__).parent / "fixtures" / "gallery_list.html").read_text()
    # two 미래시가이드 posts (1850737, 1850999); pick the largest post no
    assert find_latest_guide_post_no(html) == 1850999

def test_returns_none_when_no_guide():
    assert find_latest_guide_post_no("<html><body>nothing</body></html>") is None
```

- [ ] **Step 3: Run** `pytest tests/test_discover.py -q` — FAIL.

- [ ] **Step 4: Implement `umaingest/discover.py`**
```python
from __future__ import annotations
import re
from typing import Optional
from .fetch import Transport, _requests_transport

GUIDE_TITLE_PREFIX = "미래시가이드"
_ROW_RE = re.compile(r'data-no="(\d+)"[^>]*>.*?<a[^>]*>(.*?)</a>', re.DOTALL)


def find_latest_guide_post_no(list_html: str) -> Optional[int]:
    """Highest-numbered post whose title starts with 미래시가이드."""
    candidates: list[int] = []
    for no, title in _ROW_RE.findall(list_html):
        if title.strip().startswith(GUIDE_TITLE_PREFIX):
            candidates.append(int(no))
    return max(candidates) if candidates else None


def fetch_gallery_list_html(transport: Transport = _requests_transport) -> str:
    url = "https://gall.dcinside.com/mgallery/board/lists/?id=umamusu"
    body, status = transport(url, {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124.0 Safari/537.36",
        "Referer": "https://gall.dcinside.com/",
    })
    if status != 200:
        raise RuntimeError(f"gallery list fetch failed: HTTP {status}")
    return body.decode("utf-8", errors="replace")
```

- [ ] **Step 5: Run** `pytest tests/test_discover.py -q` — PASS.

- [ ] **Step 6: Commit**
```bash
git add tools/ingestion/umaingest/discover.py tools/ingestion/tests/test_discover.py tools/ingestion/tests/fixtures/gallery_list.html
git commit -m "feat(ingest): discover latest 미래시가이드 post"
```

---

# Phase B3 — Vision extraction (Claude)

### Task B3.1: vision prompts
**Files:** Create `tools/ingestion/umaingest/prompts.py`; Test `tools/ingestion/tests/test_vision.py` (prompt presence portion)

- [ ] **Step 1: Write `umaingest/prompts.py`**
```python
"""Prompts for Claude vision extraction of the 미래시가이드 slides.

The guide is community-made and may change layout; the model classifies each
slide then extracts only factual schedule data into our schema shape.
"""

SYSTEM = (
    "You extract Korean-server Umamusume schedule facts from community guide images. "
    "Return ONLY valid minified JSON, no prose. Use Korean text exactly as shown in the image. "
    "Unknown/absent fields → null. Never invent dates or names."
)

# One call per slide. The model returns a partial document with any of the three arrays.
EXTRACT = """이 이미지는 한국 서버 우마무스메 '미래시가이드' 슬라이드입니다.
다음 JSON 스키마로 보이는 정보만 추출하세요(없으면 빈 배열):

{
  "championsMeetings": [{
    "codeName": "「」 안의 코드명 또는 분류 (예: LONG)",
    "raceGrade": "G1 등 등급 또는 null",
    "raceName": "레이스명 (예: 벚꽃상)",
    "track": {"racecourse":"경마장","surface":"turf|dirt","distanceMeters":1600,
              "distanceClass":"sprint|mile|medium|long",
              "turn":"clockwise|counterclockwise|straight|null","courseSide":"외측|내측|null",
              "season":"봄|여름|가을|겨울|null","weather":"맑음 등|null","ground":"양호 등|null","timeOfDay":"낮|밤|null"},
    "period": {"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":true}
  }],
  "leagueOfHeroes": [{"round":"「」 안 회차","raceName":"레이스명","track":{...위와 동일...},
                      "period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":true}}],
  "pickups": [{"period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":false},
               "trainees":["육성마명",...],
               "supportCards":[{"rarity":"SSR","name":"이름","type":"스피드|스태미나|파워|근성|지능"}]}]
}

규칙: 날짜는 YYYY-MM-DD. 한국 서버 미확정 일정이면 estimated=true. 표지/안내/캐릭터 로스터만 있는 슬라이드는 모든 배열을 비웁니다."""
```

- [ ] **Step 2: Write a presence test** in `tools/ingestion/tests/test_vision.py`
```python
from umaingest import prompts

def test_prompts_have_schema_keys():
    assert "championsMeetings" in prompts.EXTRACT
    assert "supportCards" in prompts.EXTRACT
    assert "estimated" in prompts.EXTRACT
    assert prompts.SYSTEM  # non-empty
```

- [ ] **Step 3: Run** `pytest tests/test_vision.py -q` — PASS (after Task B3.2 adds the client, run again).

- [ ] **Step 4: Commit**
```bash
git add tools/ingestion/umaingest/prompts.py tools/ingestion/tests/test_vision.py
git commit -m "feat(ingest): vision extraction prompts"
```

### Task B3.2: vision client (injectable; mocked in tests)
**Files:** Create `tools/ingestion/umaingest/vision.py`; extend `tools/ingestion/tests/test_vision.py`

- [ ] **Step 1: Write the failing test** (append to `test_vision.py`)
```python
import base64
from umaingest.vision import extract_slide, VisionResult

def test_extract_slide_parses_model_json():
    # Fake "Anthropic-like" client: returns an object with .content[0].text
    class FakeBlock: 
        def __init__(self, t): self.text = t
    class FakeMsg:
        def __init__(self, t): self.content = [FakeBlock(t)]
    class FakeClient:
        def __init__(self, payload): self._p = payload
        class _Messages:
            def __init__(self, outer): self._o = outer
            def create(self, **kw):
                FakeClient.last_kwargs = kw
                return FakeMsg(self._o._p)
        @property
        def messages(self): return FakeClient._Messages(self)

    payload = '{"championsMeetings":[],"leagueOfHeroes":[],"pickups":[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":false},"trainees":["오르페브르"],"supportCards":[]}]}'
    res = extract_slide(b"\x00fakeimage", client=FakeClient(payload))
    assert isinstance(res, VisionResult)
    assert res.pickups[0]["trainees"] == ["오르페브르"]
    assert res.championsMeetings == []
    # image was sent base64-encoded
    sent = FakeClient.last_kwargs["messages"][0]["content"]
    assert any(b.get("type") == "image" for b in sent)

def test_extract_slide_tolerates_codefenced_json():
    class FakeBlock: 
        def __init__(self, t): self.text = t
    class FakeMsg:
        def __init__(self, t): self.content = [FakeBlock(t)]
    class FakeClient:
        class _M:
            def create(self, **kw): return FakeMsg("```json\n{\"championsMeetings\":[],\"leagueOfHeroes\":[],\"pickups\":[]}\n```")
        @property
        def messages(self): return FakeClient._M()
    res = extract_slide(b"x", client=FakeClient())
    assert res.pickups == []
```

- [ ] **Step 2: Run** `pytest tests/test_vision.py -q` — FAIL (no `extract_slide`).

- [ ] **Step 3: Implement `umaingest/vision.py`**
```python
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
```

- [ ] **Step 4: Run** `pytest tests/test_vision.py -q` — PASS.

- [ ] **Step 5: Commit**
```bash
git add tools/ingestion/umaingest/vision.py tools/ingestion/tests/test_vision.py
git commit -m "feat(ingest): Claude vision client (injectable, code-fence tolerant)"
```

---

# Phase B4 — Assemble & validate

### Task B4.1: assemble slide results → ScheduleDocument
**Files:** Create `tools/ingestion/umaingest/assemble.py`; Test `tools/ingestion/tests/test_assemble.py`

- [ ] **Step 1: Write the failing test**
```python
from umaingest.vision import VisionResult
from umaingest.assemble import assemble_document
from umaingest.models import ScheduleDocument

def _cm(period_start):
    return {"codeName":"LONG","raceGrade":"G1","raceName":"벚꽃상",
            "track":{"racecourse":"한신","surface":"turf","distanceMeters":1600,"distanceClass":"mile"},
            "period":{"start":period_start,"end":"2026-07-20","estimated":True}}

def test_assemble_merges_slides_and_adds_ids_phases():
    slides = [
        VisionResult(championsMeetings=[_cm("2026-07-14")]),
        VisionResult(pickups=[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                               "trainees":["오르페브르","푸리오소"],
                               "supportCards":[{"rarity":"SSR","name":"아몬드 아이","type":"스피드"}]}]),
    ]
    doc = assemble_document(slides, source_post_no=1850737, now_iso="2026-05-20T00:00:00Z")
    assert isinstance(doc, ScheduleDocument)
    assert doc.sourcePostNo == 1850737
    assert len(doc.championsMeetings) == 1
    cm = doc.championsMeetings[0]
    # period dates expanded to ISO-Z datetimes; phases derived (open=start, ended=end)
    assert cm.id  # non-empty deterministic id
    assert cm.phases[0].kind == "open"
    assert cm.phases[-1].kind == "ended"
    assert doc.pickups[0].trainees == ["오르페브르","푸리오소"]

def test_assemble_dedups_by_id():
    slides = [VisionResult(championsMeetings=[_cm("2026-07-14")]),
              VisionResult(championsMeetings=[_cm("2026-07-14")])]  # same event twice
    doc = assemble_document(slides, source_post_no=1, now_iso="2026-05-20T00:00:00Z")
    assert len(doc.championsMeetings) == 1
```

- [ ] **Step 2: Run** `pytest tests/test_assemble.py -q` — FAIL.

- [ ] **Step 3: Implement `umaingest/assemble.py`**
```python
from __future__ import annotations
import hashlib
from .models import (ScheduleDocument, ChampionsMeeting, LeagueOfHeroes, PickupPeriod,
                     TrackCondition, EventPeriod, EventPhase, SupportCardPick)
from .vision import VisionResult


def _day(d: str) -> str:
    """'2026-07-14' or '2026-07-14T..' → 'YYYY-MM-DDT00:00:00Z'."""
    base = d[:10]
    return f"{base}T00:00:00Z"


def _eid(prefix: str, *parts: str) -> str:
    h = hashlib.sha1("|".join(parts).encode("utf-8")).hexdigest()[:10]
    return f"{prefix}-{h}"


def _period(p: dict) -> EventPeriod:
    return EventPeriod(start=_day(p["start"]), end=_day(p["end"]), estimated=bool(p.get("estimated", True)))


def _track(t: dict) -> TrackCondition:
    return TrackCondition(**{k: t.get(k) for k in
        ["racecourse","surface","distanceMeters","distanceClass","turn","courseSide","season","weather","ground","timeOfDay","imageURL"]
        if k in t})


def _phases(period: EventPeriod) -> list[EventPhase]:
    return [EventPhase(kind="open", label="오픈", date=period.start),
            EventPhase(kind="ended", label="종료", date=period.end)]


def assemble_document(slides: list[VisionResult], *, source_post_no: int, now_iso: str) -> ScheduleDocument:
    cms: dict[str, ChampionsMeeting] = {}
    lohs: dict[str, LeagueOfHeroes] = {}
    pks: dict[str, PickupPeriod] = {}

    for s in slides:
        for c in s.championsMeetings:
            per = _period(c["period"])
            eid = _eid("cm", c.get("codeName",""), c.get("raceName",""), per.start.isoformat())
            cms.setdefault(eid, ChampionsMeeting(
                id=eid, codeName=c.get("codeName",""), raceGrade=c.get("raceGrade"),
                raceName=c.get("raceName",""), track=_track(c["track"]), period=per, phases=_phases(per)))
        for l in s.leagueOfHeroes:
            per = _period(l["period"])
            eid = _eid("loh", l.get("round",""), l.get("raceName",""), per.start.isoformat())
            lohs.setdefault(eid, LeagueOfHeroes(
                id=eid, round=l.get("round",""), raceName=l.get("raceName",""),
                track=_track(l["track"]), period=per, phases=_phases(per)))
        for p in s.pickups:
            per = _period(p["period"])
            eid = _eid("pk", per.start.isoformat(), ",".join(p.get("trainees", [])))
            pks.setdefault(eid, PickupPeriod(
                id=eid, period=per, trainees=p.get("trainees", []),
                supportCards=[SupportCardPick(**sc) for sc in p.get("supportCards", [])]))

    return ScheduleDocument(
        version=2, updatedAt=now_iso, sourcePostNo=source_post_no, server="kr",
        championsMeetings=list(cms.values()),
        leagueOfHeroes=list(lohs.values()),
        pickups=list(pks.values()),
    )
```

- [ ] **Step 4: Run** `pytest tests/test_assemble.py -q` — PASS. (pydantic validates enums/required fields during construction — invalid vision data raises here, which is the desired fail-fast.)

- [ ] **Step 5: Commit**
```bash
git add tools/ingestion/umaingest/assemble.py tools/ingestion/tests/test_assemble.py
git commit -m "feat(ingest): assemble+validate slides into ScheduleDocument (ids, phases)"
```

---

# Phase B5 — Diff & publish

### Task B5.1: diff
**Files:** Create `tools/ingestion/umaingest/diff.py`; Test `tools/ingestion/tests/test_diff.py`

- [ ] **Step 1: Write the failing test**
```python
from umaingest.diff import changed, summarize

def test_changed_detects_difference():
    a = '{"version":2,"championsMeetings":[]}'
    b = '{"version":2,"championsMeetings":[{"id":"x"}]}'
    assert changed(a, b) is True
    assert changed(a, a) is False

def test_changed_ignores_updatedAt_only_change():
    a = '{"updatedAt":"2026-05-20T00:00:00Z","pickups":[]}'
    b = '{"updatedAt":"2026-05-21T00:00:00Z","pickups":[]}'
    assert changed(a, b) is False  # only the timestamp moved → not a real change

def test_summarize_counts():
    s = summarize('{"championsMeetings":[1],"leagueOfHeroes":[],"pickups":[1,2]}')
    assert "CM 1" in s and "LoH 0" in s and "pickup 2" in s
```

- [ ] **Step 2: Run** `pytest tests/test_diff.py -q` — FAIL.

- [ ] **Step 3: Implement `umaingest/diff.py`**
```python
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
```

- [ ] **Step 4: Run** `pytest tests/test_diff.py -q` — PASS.

- [ ] **Step 5: Commit**
```bash
git add tools/ingestion/umaingest/diff.py tools/ingestion/tests/test_diff.py
git commit -m "feat(ingest): schedule diff (timestamp-insensitive) + summary"
```

### Task B5.2: publish (write file; PR helper)
**Files:** Create `tools/ingestion/umaingest/publish.py`; Test `tools/ingestion/tests/test_publish.py`

- [ ] **Step 1: Write the failing test**
```python
from pathlib import Path
from umaingest.publish import write_if_changed

def test_write_if_changed_writes_new(tmp_path):
    dest = tmp_path / "data" / "schedule.json"
    wrote = write_if_changed(dest, '{"version":2,"pickups":[],"updatedAt":"2026-05-20T00:00:00Z"}')
    assert wrote is True
    assert dest.exists()

def test_write_if_changed_skips_when_same_modulo_timestamp(tmp_path):
    dest = tmp_path / "schedule.json"
    write_if_changed(dest, '{"version":2,"pickups":[],"updatedAt":"2026-05-20T00:00:00Z"}')
    wrote = write_if_changed(dest, '{"version":2,"pickups":[],"updatedAt":"2026-05-21T00:00:00Z"}')
    assert wrote is False  # only timestamp differs
```

- [ ] **Step 2: Run** `pytest tests/test_publish.py -q` — FAIL.

- [ ] **Step 3: Implement `umaingest/publish.py`**
```python
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
```

- [ ] **Step 4: Run** `pytest tests/test_publish.py -q` — PASS.

- [ ] **Step 5: Commit**
```bash
git add tools/ingestion/umaingest/publish.py tools/ingestion/tests/test_publish.py
git commit -m "feat(ingest): write schedule.json only on real change"
```

---

# Phase B6 — Orchestration & CI

### Task B6.1: CLI orchestration
**Files:** Create `tools/ingestion/umaingest/cli.py`; Test `tools/ingestion/tests/test_cli.py`

- [ ] **Step 1: Write the failing test** (fully mocked — no network/API)
```python
from pathlib import Path
from umaingest import cli
from umaingest.vision import VisionResult

def test_run_pipeline_end_to_end_mocked(tmp_path, monkeypatch):
    # Stub each external boundary
    monkeypatch.setattr(cli, "fetch_gallery_list_html", lambda transport=None: '<tr class="ub-content" data-no="1850737"><td class="gall_tit"><a>미래시가이드 2605-A</a></td></tr>')
    monkeypatch.setattr(cli, "fetch_post_html", lambda no, transport=None: '<img src="https://dcimg1.dcinside.com/viewimage.php?id=a&amp;no=S1"/>')
    monkeypatch.setattr(cli, "download_image", lambda url, no, transport=None: b"img")
    monkeypatch.setattr(cli, "png_bytes", lambda raw: b"png")  # skip real webp→png
    monkeypatch.setattr(cli, "make_client", lambda: object())
    monkeypatch.setattr(cli, "extract_slide", lambda data, *, client, media_type="image/png": VisionResult(
        pickups=[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":False},
                  "trainees":["오르페브르"],"supportCards":[]}]))

    dest = tmp_path / "data" / "schedule.json"
    result = cli.run(dest=dest, now_iso="2026-05-20T00:00:00Z")
    assert result["post_no"] == 1850737
    assert result["wrote"] is True
    assert dest.exists()
    assert "오르페브르" in dest.read_text(encoding="utf-8")
```

- [ ] **Step 2: Run** `pytest tests/test_cli.py -q` — FAIL.

- [ ] **Step 3: Implement `umaingest/cli.py`**
```python
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
    from PIL import Image  # Pillow; add to deps if used
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
```

- [ ] **Step 4: Add Pillow to deps** — in `pyproject.toml` `dependencies`, add `"pillow>=10.0"`. Re-run `pip install -e ".[dev]"`.

- [ ] **Step 5: Run** `pytest tests/test_cli.py -q` — PASS (the test stubs `png_bytes`/network/vision, so Pillow isn't exercised in the unit test).

- [ ] **Step 6: Commit**
```bash
git add tools/ingestion/umaingest/cli.py tools/ingestion/tests/test_cli.py tools/ingestion/pyproject.toml
git commit -m "feat(ingest): pipeline orchestration CLI"
```

### Task B6.2: GitHub Actions workflow (review gate) + README
**Files:** Create `.github/workflows/ingest.yml` (repo root); Create `tools/ingestion/README.md`

- [ ] **Step 1: Write `.github/workflows/ingest.yml`**
```yaml
name: Ingest schedule
on:
  schedule:
    - cron: "0 0 * * 1"   # weekly, Monday 00:00 UTC
  workflow_dispatch: {}

permissions:
  contents: write
  pull-requests: write

jobs:
  ingest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - name: Install
        run: |
          cd tools/ingestion
          pip install -e ".[dev]"
      - name: Run ingestion
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          cd tools/ingestion
          python -m umaingest.cli --dest "$GITHUB_WORKSPACE/data/schedule.json"
      - name: Open PR if changed
        uses: peter-evans/create-pull-request@v6
        with:
          add-paths: data/schedule.json
          branch: ingest/schedule-update
          title: "data: schedule.json update (review)"
          body: |
            Automated ingestion from the latest DCinside 미래시가이드.
            **Review the diff before merging** — dates are 미래시(예상) and vision-extracted.
          commit-message: "data: update schedule.json from ingestion"
```
> The `create-pull-request` action no-ops when there's no diff, so an unchanged run opens nothing. Merging the PR is the human review gate; the app only sees data after merge.

- [ ] **Step 2: Write `tools/ingestion/README.md`**
```markdown
# Uma schedule ingestion

Reads the latest DCinside `미래시가이드` post, extracts schedule facts with Claude vision,
and writes `data/schedule.json` (schema v2). A GitHub Action runs weekly and opens a PR —
**merging the PR is the review gate**; the app only consumes data after merge.

## Local run
```
cd tools/ingestion
python3 -m venv .venv && . .venv/bin/activate
pip install -e ".[dev]"
export ANTHROPIC_API_KEY=sk-...
python -m umaingest.cli --dest ../../data/schedule.json
```

## Tests (no network / no API key needed)
```
. .venv/bin/activate && pytest -q
```

## Setup checklist (user)
1. Host this repo on GitHub with Actions enabled.
2. Add repo secret `ANTHROPIC_API_KEY`.
3. Point the app's `ScheduleEndpoint.url` (Swift) at the raw URL of `data/schedule.json`.

## Notes / risk
- The guide is community-made; we extract only factual data (dates/conditions/names), never redistribute images.
- Fetch is infrequent (weekly) and review-gated. KR dates are 미래시(예상) → events carry `estimated: true`.
- If the guide layout changes and extraction degrades, the PR diff is where you catch it.
```

- [ ] **Step 3: Run the full unit suite** `cd tools/ingestion && . .venv/bin/activate && pytest -q` — all pass.

- [ ] **Step 4: Commit**
```bash
git add .github/workflows/ingest.yml tools/ingestion/README.md
git commit -m "feat(ingest): weekly GitHub Action with review-gated PR + README"
```

### Task B6.3: optional live smoke (manual, not in CI)
**Files:** Create `tools/ingestion/tests/test_live_smoke.py`

- [ ] **Step 1: Write a gated live test** (skipped unless both env flags set; costs API + network)
```python
import os, pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_LIVE_INGEST") != "1" or not os.getenv("ANTHROPIC_API_KEY"),
    reason="live ingest smoke disabled (set RUN_LIVE_INGEST=1 + ANTHROPIC_API_KEY)",
)

def test_live_against_known_post(tmp_path):
    from umaingest import cli
    res = cli.run(dest=tmp_path / "schedule.json", now_iso="2026-05-20T00:00:00Z")
    assert res["post_no"] is not None
    assert (tmp_path / "schedule.json").exists()
```

- [ ] **Step 2: Run** `pytest tests/test_live_smoke.py -q` — should report SKIPPED (flags unset). Confirm it skips cleanly.

- [ ] **Step 3: Commit**
```bash
git add tools/ingestion/tests/test_live_smoke.py
git commit -m "test(ingest): gated live smoke (manual)"
```

---

## Self-Review Notes (planner)
- **Spec §5 coverage:** discovery (B2.2), fetch+image URLs (B2.1), vision extract (B3), assemble+validate against schema (B1+B4), diff (B5.1), review-gated PR publish (B5.2+B6.2), weekly cron + manual dispatch (B6.2), estimated flag (carried through assemble/models), source post tracking (sourcePostNo in B1/B4).
- **Schema match:** `models.py` field names are the exact camelCase Swift keys; dates serialize with `Z`. The bundled Swift fallback (`Core/Sources/UmaCore/Resources/schedule_fallback.json`) is the reference shape — an integration check is that its structure equals `ScheduleDocument(...).to_json()` output shape.
- **No network/API in unit tests:** every boundary (`fetch_*`, `download_image`, `extract_slide`, `make_client`, `png_bytes`) is injectable or monkeypatched; only the gated `test_live_smoke` touches the world.
- **Placeholder scan:** none — every step has runnable code/commands. `MODEL = "claude-opus-4-7"` is a concrete current vision-capable model id (swap if a newer one is preferred).
- **Type consistency:** `VisionResult` fields (championsMeetings/leagueOfHeroes/pickups) consumed by `assemble_document`; `write_if_changed`/`changed` share the timestamp-insensitive normalization; CLI wires the real function names from each module.
- **Open items:** publish repo location / `ScheduleEndpoint.url` final value (needs the user's repo); whether to also pre-seed structured data from JP references (out of scope here — this plan ingests the KR guide as the single source).
