#!/usr/bin/env bash
set -euo pipefail
if command -v swiftformat >/dev/null; then
  swiftformat --lint LunaHearth LunaHearthTests
else
  echo "swiftformat not installed; skipping formatter lint. No formatter is required for the project."
fi
