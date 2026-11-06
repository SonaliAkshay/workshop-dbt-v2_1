#!/usr/bin/env bash
# Cross-platform (macOS / Linux / GitHub Codespaces) setup: dbt v2 + DuckDB.
# Usage:
#   ./scripts/setup.sh              # install Fusion binary if needed, then deps + debug + build
#   ./scripts/setup.sh --install    # same (install is the default)
#   ./scripts/setup.sh --skip-install # use an existing dbt v2 on PATH
#   ./scripts/setup.sh --skip-build # stop after debug
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT="$ROOT"
# shellcheck source=lib/resolve_dbt.sh
source "$ROOT/scripts/lib/resolve_dbt.sh"

DO_INSTALL=1
SKIP_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --install) DO_INSTALL=1 ;;
    --skip-install) DO_INSTALL=0 ;;
    --skip-build) SKIP_BUILD=1 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

PROJECT="$ROOT"
if [[ ! -f "$PROJECT/dbt_project.yml" ]]; then
  echo "Missing $PROJECT/dbt_project.yml" >&2
  exit 1
fi
if [[ ! -f "$PROJECT/profiles.yml" ]]; then
  echo "Missing $PROJECT/profiles.yml (portable DuckDB profile required)" >&2
  exit 1
fi

install_dbt_v2() {
  echo "Installing dbt v2 (Fusion) as a standalone binary. Python is not required."
  curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
  export PATH="${HOME}/.local/bin:${PATH}"
  link_dbtf
}

# Official installer puts dbt in ~/.local/bin. Workshop commands use dbtf.
link_dbtf() {
  mkdir -p "$HOME/.local/bin"
  if [[ -x "$HOME/.local/bin/dbt" && ! -e "$HOME/.local/bin/dbtf" ]]; then
    ln -sfn dbt "$HOME/.local/bin/dbtf"
  fi
}

# macOS bash 3.2 + set -u treats an empty array as unbound.
resolve_dbt_safe() {
  set +u
  resolve_dbt
  local st=$?
  set -u
  return "$st"
}

if ! resolve_dbt_safe; then
  if [[ "$DO_INSTALL" -eq 1 ]]; then
    install_dbt_v2
    if ! resolve_dbt_safe; then
      echo "dbt v2 still not found after the standalone install (~/.local/bin/dbt)." >&2
      exit 1
    fi
  else
    echo "dbt v2 not found on PATH." >&2
    echo "Install with:  ./scripts/setup.sh --install" >&2
    exit 1
  fi
elif [[ "$DO_INSTALL" -eq 1 && ! -x "$HOME/.local/bin/dbt" ]]; then
  install_dbt_v2
  if ! resolve_dbt_safe; then
    echo "dbt v2 still not found after the standalone install (~/.local/bin/dbt)." >&2
    exit 1
  fi
fi

link_dbtf

export PATH="${HOME}/.local/bin:${PATH}"
if [[ -x "$HOME/.local/bin/dbtf" ]]; then
  DBT_BIN="$HOME/.local/bin/dbtf"
  DBT_VERSION_LINE="$("$DBT_BIN" --version 2>/dev/null | head -n 1 || true)"
elif [[ -x "$HOME/.local/bin/dbt" ]]; then
  DBT_BIN="$HOME/.local/bin/dbt"
  DBT_VERSION_LINE="$("$DBT_BIN" --version 2>/dev/null | head -n 1 || true)"
else
  # dbt v2 found elsewhere on PATH (resolve_dbt already set DBT_BIN)
  DBT_VERSION_LINE="$("$DBT_BIN" --version 2>/dev/null | head -n 1 || true)"
fi

if [[ ! "$DBT_VERSION_LINE" =~ ^dbt[[:space:]]+2\. ]]; then
  echo "Fusion check failed. Expected dbt 2.x from ${DBT_BIN:-dbtf}, got: ${DBT_VERSION_LINE:-nothing}" >&2
  exit 1
fi

echo "Using: $DBT_BIN ($DBT_VERSION_LINE)"
cd "$PROJECT"

echo "==> deps"
"$DBT_BIN" deps --profiles-dir .

echo "==> debug"
"$DBT_BIN" debug --profiles-dir .

if [[ "$SKIP_BUILD" -eq 1 ]]; then
  echo "Skipping build (--skip-build)."
  exit 0
fi

echo "==> dbtf build (compare baseline)"
# The VS Code Compare feature diffs your dev models against this baseline.
# .vscode/settings.json points the extension at target/compare_state.
"$DBT_BIN" build --target compare_baseline --target-path target/compare_baseline --profiles-dir . --quiet
mkdir -p target/compare_state
cp target/compare_baseline/manifest.json target/compare_state/manifest.json

echo "==> dbtf build"
"$DBT_BIN" build --profiles-dir .

echo
echo "Fusion check passed: dbtf build ($DBT_VERSION_LINE)"
echo "Setup OK. DuckDB file: $PROJECT/jaffle_shop.duckdb"

find_code_cli() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return 0
  fi
  local candidate
  for candidate in \
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
    "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
    "/usr/share/code/bin/code" \
    "$HOME/.local/bin/code" \
    "$HOME/.local/share/vscode/bin/code"
  do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "curl or wget is required to download VS Code." >&2
    return 1
  fi
}

install_vscode() {
  if [[ -n "${CODESPACES:-}" || -n "${REMOTE_CONTAINERS:-}" ]]; then
    echo "Codespaces already provides VS Code. Skipping desktop install."
    return 0
  fi

  echo "VS Code not found. Downloading Visual Studio Code..."
  case "$(uname -s)" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        brew install --cask visual-studio-code
        return 0
      fi
      local tmp
      tmp="$(mktemp -d)"
      download_file "https://update.code.visualstudio.com/latest/darwin-universal/stable" "$tmp/vscode.zip"
      mkdir -p "$tmp/extract"
      unzip -q "$tmp/vscode.zip" -d "$tmp/extract"
      local dest="/Applications"
      if [[ ! -w /Applications ]]; then
        dest="$HOME/Applications"
        mkdir -p "$dest"
      fi
      rm -rf "$dest/Visual Studio Code.app"
      mv "$tmp/extract/Visual Studio Code.app" "$dest/"
      export PATH="$dest/Visual Studio Code.app/Contents/Resources/app/bin:${PATH}"
      ;;
    Linux)
      local tmp os="linux-x64"
      tmp="$(mktemp -d)"
      case "$(uname -m)" in
        aarch64|arm64) os="linux-arm64" ;;
      esac
      download_file "https://update.code.visualstudio.com/latest/${os}/stable" "$tmp/vscode.tar.gz"
      mkdir -p "$HOME/.local/share/vscode" "$HOME/.local/bin"
      tar -xzf "$tmp/vscode.tar.gz" -C "$HOME/.local/share/vscode" --strip-components=1
      ln -sfn "$HOME/.local/share/vscode/bin/code" "$HOME/.local/bin/code"
      export PATH="$HOME/.local/bin:${PATH}"
      ;;
    *)
      echo "Cannot download VS Code on $(uname -s). Install it from https://code.visualstudio.com" >&2
      return 1
      ;;
  esac
  rm -rf "$tmp"
}

echo "==> VS Code"
CODE_CLI="$(find_code_cli || true)"
if [[ -z "$CODE_CLI" ]]; then
  if ! install_vscode; then
    echo "Could not install VS Code. Skipping dbtLabsInc.dbt."
  else
    CODE_CLI="$(find_code_cli || true)"
  fi
fi
if [[ -z "${CODE_CLI:-}" ]]; then
  echo "VS Code is not available. Skipping dbtLabsInc.dbt."
else
  echo "==> dbt VS Code extension"
  "$CODE_CLI" --uninstall-extension dbt-labs.dbt-prime >/dev/null 2>&1 || true
  if "$CODE_CLI" --install-extension dbtLabsInc.dbt --force; then
    echo "Installed official dbt VS Code extension (dbtLabsInc.dbt)."
  else
    echo "Could not install dbtLabsInc.dbt. Install it from Extensions in VS Code."
  fi
fi
