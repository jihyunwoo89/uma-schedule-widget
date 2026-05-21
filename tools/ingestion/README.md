# Uma schedule ingestion

Reads the latest DCinside `미래시가이드` post and produces `data/schedule.json` (schema v2)
for the app to fetch. Two modes:

- **Free / manual (default)** — no API key, no cost. See "Free mode" below.
- **Automated (optional)** — a weekly GitHub Action calls Claude vision and opens a
  review-gated PR. Needs `ANTHROPIC_API_KEY`. See "Automated mode".

## Free mode (no API key)

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
