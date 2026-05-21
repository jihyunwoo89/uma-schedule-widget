#!/usr/bin/env bash
# Refresh the bundled fallback from the live remote schedule JSON.
# Usage: ./scripts/generate-fallback.sh
set -euo pipefail
URL="https://raw.githubusercontent.com/damienjee/uma-schedule-data/main/schedule.json"
DEST="Core/Sources/UmaCore/Resources/schedule_fallback.json"
echo "Fetching $URL ..."
curl -fsSL "$URL" -o "$DEST"
echo "Wrote $DEST"
