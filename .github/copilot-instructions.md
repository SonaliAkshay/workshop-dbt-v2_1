# Copilot / coding-agent instructions

Follow **`AGENTS.md`** and **`README.md`**.

This repository is a **dbt v2 + DuckDB** workshop.

- Setup: `./scripts/setup.sh --install` or `.\scripts\setup.ps1 -Install` (installs the standalone dbt Fusion binary to `~/.local/bin`; no Python).
- Codespaces: `.devcontainer/devcontainer.json` runs setup on create.
- Run dbt from the repository root with `--profiles-dir .` (use `dbtf`; plain `dbt` may be the dbt Cloud CLI).
- Do not request or embed secrets; DuckDB needs none for the default path.
