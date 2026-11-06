#!/usr/bin/env bash
# Quick health check (no build). macOS / Linux / Codespaces.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT="$ROOT"
# shellcheck source=lib/resolve_dbt.sh
source "$ROOT/scripts/lib/resolve_dbt.sh"

set +u
resolve_dbt
st=$?
set -u
if [[ "$st" -ne 0 ]]; then
  echo "FAIL: dbt v2 not found (try ./scripts/setup.sh --install)" >&2
  exit 1
fi

echo "OK: $DBT_BIN ($DBT_VERSION_LINE)"
cd "$ROOT"
"$DBT_BIN" debug --profiles-dir .
echo "OK: DuckDB connection"
