# Uma schedule ingestion

Reads the latest DCinside `미래시가이드` post, extracts schedule facts with Claude vision, and writes `data/schedule.json` (schema v2). A GitHub Action runs weekly and opens a PR — **merging the PR is the review gate**; the app only consumes data after merge.

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
