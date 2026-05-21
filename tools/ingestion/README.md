# Uma schedule ingestion

Produces `data/schedule.json` (schema v2) for the app. **Primary method: a hand-maintained Google Sheet published as CSV** — no API key, fully free. (A DCinside-image + Claude-vision path also exists as an alternative; see lower sections.)

## Sheet mode (recommended)

The converter **auto-detects two layouts** (by header row):

### KR human-friendly layout (used by the live sheet)

Columns: `날짜, 분류, 제목, 레이스, 마장, 픽업(육성마), 픽업(서포트), 비고`. One row per event; values are packed Korean strings.

| Column | Notes |
|---|---|
| `날짜` | `YYYY-MM-DD` (used as both start and end; events are treated as 미래시 → `estimated: true`) |
| `분류` | `챔미` / `LoH` / `픽업` |
| `제목` | `「MILE」`/`「LONG」`/`「CLASSIC」` (CM codeName) or `10회차` (LoH round) — 「」 stripped automatically |
| `레이스` | `G1 벚꽃상` → grade `G1` + name `벚꽃상` (CM splits; LoH keeps the whole string) |
| `마장` | packed: `경마장, 잔디 1600m(마일), 시계(우), 봄, 맑음, 양호, 낮` — racecourse, surface+distance, turn, then any of season/날씨/마장상태/시간대 (order-flexible, omittable). `distanceClass` auto from distance. |
| `픽업(육성마)` | comma-separated trainee names (ratings like `3★` kept verbatim) |
| `픽업(서포트)` | comma-separated `이름 SSR(타입)`, e.g. `카렌짱 SSR(근성), 이쿠노 딕터스 SSR(지능)`. `셀렉트 픽업` / non-matching → no structured card. |
| `비고` | free note (ignored by the converter) |

Rows with a blank `날짜` are skipped (use for headers/notes). To use it:
```bash
cd tools/ingestion && . .venv/bin/activate
python -m umaingest.cli --from-sheet "<published CSV URL>" --dest ../../data/schedule.json
```

### Generic column layout (alternative)

| Column | Notes |
|---|---|
| `category` | `championsMeeting` / `leagueOfHeroes` / `gacha` — also accepts Korean synonyms: `챔미`/`챔피언스미팅`→CM, `리그오브히어로즈`/`LoH`→LoH, `픽업`/`가챠`→gacha |
| `title` | CM → `codeName` (e.g. `MILE`); LoH → `round` (e.g. `10회차`); pickup → blank |
| `raceGrade` | e.g. `G1` |
| `raceName` | race name |
| `racecourse` | track name |
| `surface` | `잔디` or `turf` → turf; `더트` or `dirt` → dirt |
| `distanceMeters` | numeric metres (e.g. `1600`) |
| `turn` | `우`/`clockwise` → clockwise; `좌`/`counterclockwise` → counterclockwise; `직선`/`straight` → straight |
| `courseSide` | optional (e.g. `외측`) |
| `season` | optional (e.g. `봄`) |
| `weather` | optional |
| `ground` | optional |
| `timeOfDay` | optional (e.g. `낮`) |
| `start` | ISO date `YYYY-MM-DD` |
| `end` | ISO date; if blank, same as `start` |
| `estimated` | `TRUE`/`FALSE` (also `true`/`1`/`y`/`예`) |
| `trainees` | Pickup: semicolon-separated trainee names, e.g. `발렌타인 마짱; 발렌타인 제퍼` |
| `supportCards` | Pickup: semicolon-separated, each `등급\|이름\|타입`, e.g. `SSR\|카렌짱\|근성; SSR\|이쿠노 딕터스\|지능` |

**Auto-derived:** `distanceClass` is computed from `distanceMeters` (≤1400 → sprint, ≤1800 → mile, ≤2400 → medium, else long) — do not add a column for it.

Rows whose `category` is blank or unrecognised are silently skipped, so you can keep notes or blank separator rows freely.

### Steps

1. In Google Sheets: **파일 → 공유 → 웹에 게시 → CSV**
2. Copy the published CSV URL.
3. Run:

```bash
cd tools/ingestion && . .venv/bin/activate
python -m umaingest.cli --from-sheet "<published CSV URL>" --dest ../../data/schedule.json
```

4. Commit `data/schedule.json` to a free GitHub repo (or update the app's bundled fallback) and point `ScheduleEndpoint.url` (Swift) at its raw URL.

---

## Alternative: DCinside image guide (no API key)

The deterministic steps cost nothing (just HTTP + image decode):

```bash
cd tools/ingestion && . .venv/bin/activate
# Download the latest guide's slides to a folder (no API key needed):
python -m umaingest.cli --download-only /tmp/umaslides
```

Then the schedule is produced human-in-the-loop, because the guide splits a single
event's **conditions** and **dates** across different slides and renders names on
stylized banner art:

1. Ask Claude (in chat) to read the downloaded slides and draft the consolidated
   extraction, **or** just tell Claude the upcoming events you already know.
2. Claude builds + validates them via `umaingest.assemble.build_document` → `schedule.json`.
3. You confirm uncertain dates/names; commit `schedule.json` to a **free** GitHub repo
   (or update the app's bundled `Core/Sources/UmaCore/Resources/schedule_fallback.json`).

Hosting is free (GitHub raw). The only thing that would cost money is the automated
vision call, which this mode does not use.

## Automated mode (optional, needs API key)

## Local run

```bash
cd tools/ingestion
python3 -m venv .venv && . .venv/bin/activate
pip install -e ".[dev]"
export ANTHROPIC_API_KEY=sk-...
python -m umaingest.cli --dest ../../data/schedule.json
```

## Tests (no network / no API key needed)

```bash
. .venv/bin/activate && pytest -q
```

## Setup checklist (user)

1. Host this repo on GitHub with Actions enabled.
2. Add repo secret `ANTHROPIC_API_KEY`.
3. Point the app's `ScheduleEndpoint.url` (Swift) at the raw URL of `data/schedule.json`.

## Notes / risk

- Guide is community-made — extract only factual data, never redistribute images.
- Fetch is weekly + review-gated.
- KR dates are 미래시(예상) → `estimated: true`.
- If the guide layout changes the PR diff is where you catch it.
