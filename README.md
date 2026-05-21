# 우마 스케줄 위젯 (Uma Schedule Widget)

Korean-server Umamusume schedule on your iOS home & lock screen — Champions Meeting,
League of Heroes, and gacha pickups with d-day countdowns.

## Build
```
xcodegen generate
open UmaSchedule.xcodeproj
```
Core logic tests: `cd Core && swift test`.

## Data
Schedule is fetched from a hand-maintained remote JSON (see `ScheduleEndpoint.url`),
cached in the App Group, and falls back to the bundled `schedule_fallback.json`.
Refresh the bundled copy with `./scripts/generate-fallback.sh`.

## Disclaimer
Unofficial. Not affiliated with Kakao Games / Cygames.
