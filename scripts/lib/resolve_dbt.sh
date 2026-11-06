#!/usr/bin/env bash
# Resolve a dbt v2 (Fusion) binary. Prefers `dbtf`, then `dbt`, then the
# standalone installer location (~/.local/bin).
# Usage: source this file, then call resolve_dbt → sets DBT_BIN

resolve_dbt() {
  local candidate version path
  local -a candidates=()

  command -v dbtf >/dev/null 2>&1 && candidates+=("$(command -v dbtf)")
  command -v dbt >/dev/null 2>&1 && candidates+=("$(command -v dbt)")

  for path in \
    "${HOME}/.local/bin/dbt" \
    "${HOME}/.local/bin/dbtf" \
    /usr/local/bin/dbt \
    /opt/homebrew/bin/dbt
  do
    [[ -x "$path" ]] && candidates+=("$path")
  done

  # macOS bash 3.2 + set -u errors on "${candidates[@]}" when the array is empty.
  if [[ ${#candidates[@]} -eq 0 ]]; then
    DBT_BIN=""
    DBT_VERSION_LINE=""
    return 1
  fi

  for candidate in "${candidates[@]}"; do
    version="$("$candidate" --version 2>/dev/null | head -n 1 || true)"
    # dbt v2: "dbt 2.0.9"  |  Cloud CLI: "dbt Cloud CLI - 0.40.17 ..."
    if [[ "$version" =~ ^dbt[[:space:]]+2\. ]]; then
      DBT_BIN="$candidate"
      DBT_VERSION_LINE="$version"
      return 0
    fi
  done
  DBT_BIN=""
  DBT_VERSION_LINE=""
  return 1
}
