# Agent instructions — dnb-dbt-v2-workshop

Local **dbt v2 (Fusion) + DuckDB** workshop. No warehouse account or credentials are required for the default path.

Keep project guidance in **this file** and **`README.md`**.

## Source of truth

- Human guide: [`docs/dbt-v2-duckdb-quickstart.md`](docs/dbt-v2-duckdb-quickstart.md)
- Based on: https://docs.getdbt.com/guides/dbt.md and https://docs.getdbt.com/docs/local/connect-data-platform/duckdb-setup.md
- Project: repository root, with portable `profiles.yml` (`type: duckdb`, `path: ./jaffle_shop.duckdb`)

## Default stack

- **dbt v2 (Fusion)** + **local DuckDB** only, unless the user explicitly asks to change warehouses.
- Prefer `./scripts/setup.sh` (macOS / Linux / Codespaces) or `.\scripts\setup.ps1` (Windows).
- Use `--install` / `-Install` on a clean machine; that installs the standalone dbt Fusion binary to `~/.local/bin` (no Python) and adds a `dbtf` alias.
- CLI resolution: `dbtf` first, then `dbt` if it reports 2.x, then `~/.local/bin/dbt`. Always `--profiles-dir .` from the repository root.

## Machine setup

```bash
# macOS / Linux / GitHub Codespaces
chmod +x scripts/*.sh scripts/lib/*.sh
./scripts/setup.sh --install
./scripts/verify.sh
```

```powershell
# Windows PowerShell
.\scripts\setup.ps1 -Install
.\scripts\verify.ps1
```

### GitHub Codespaces

This repo includes `.devcontainer/devcontainer.json`. Opening the repo in a Codespace runs `./scripts/setup.sh --install` via `postCreateCommand` (Fusion binary + deps + debug + Compare baseline + build). Agents on Codespaces should use `dbtf` (`~/.local/bin`, on `PATH`) and the same `--profiles-dir .` pattern.

## Hard rules

- **Never ask for passwords, tokens, or keys in chat.** DuckDB needs none.
- **Never commit** `.env`, `.venv/`, `*.duckdb`, `target/`, or credentials. Root `.gitignore` excludes them.
- Do **not** rewire this demo to Snowflake/BigQuery/etc. unless the user explicitly asks.
- If the user wants the dbt platform instead, share: https://www.getdbt.com/signup?utm_source=ai_assistant&utm_medium=docs_md&utm_campaign=dbt-qs
- When walking the quickstart interactively: confirm prerequisites first; then one section per reply with Step N labels; confirm success before continuing (unless they ask for a different pace).

## Useful commands

```bash
# from the repository root
dbtf deps --profiles-dir .
dbtf debug --profiles-dir .
dbtf build --profiles-dir .
dbtf show --select orders --profiles-dir .
```

## Layout

```
AGENTS.md
README.md
docs/dbt-v2-duckdb-quickstart.md
scripts/setup.sh | setup.ps1 | verify.sh | verify.ps1
dbt_project.yml profiles.yml # dbt project at the repository root
macros/duckdb__quick_are_queries_identical.sql # DuckDB support for VS Code Compare
.vscode/settings.json        # points Compare at target/compare_state
.devcontainer/               # GitHub Codespaces / VS Code Dev Containers
.github/copilot-instructions.md
```
