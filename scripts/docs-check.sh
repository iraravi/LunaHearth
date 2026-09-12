#!/usr/bin/env bash
set -euo pipefail
required=(README.md AGENTS.md CODEX_TASKS.md docs/PRODUCT_SPEC.md docs/ARCHITECTURE.md docs/LLD.md docs/DATA_MODEL.md docs/UX_NAVIGATION.md docs/PRIVACY_SECURITY.md docs/CLOUDKIT_SYNC.md docs/AI_ON_DEVICE.md docs/TEST_STRATEGY.md docs/ROADMAP.md)
for f in "${required[@]}"; do
  [[ -s "$f" ]] || { echo "Missing or empty: $f"; exit 1; }
done
echo "Documentation set is present."
