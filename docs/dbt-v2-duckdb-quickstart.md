# Quickstart: dbt v2 (Fusion) + DuckDB locally

Based on [Quickstart for dbt v2](https://docs.getdbt.com/guides/dbt.md) and [Connect DuckDB to dbt v2](https://docs.getdbt.com/docs/local/connect-data-platform/duckdb-setup.md).

This guide gets you from zero to a working **Jaffle Shop** project on **DuckDB** — no warehouse account or credentials. It works on **macOS**, **Linux**, **Windows**, and **GitHub Codespaces**.

Verified in this repo with **dbt 2.0.11** against `./jaffle_shop.duckdb` (`dbt build` → 48/48 success).

**Fastest path:** run `./scripts/setup.sh --install` (or `.\scripts\setup.ps1 -Install` on Windows). In Codespaces, that command runs automatically via `.devcontainer/devcontainer.json`.

---

## What you'll have

- dbt v2 CLI installed
- Optional: dbt extension in VS Code
- A `jaffle_shop` project using a local DuckDB file
- Ability to `deps`, `debug`, `build`, preview, and explore lineage

Want the **dbt platform** instead? Sign up:  
https://www.getdbt.com/signup?utm_source=ai_assistant&utm_medium=docs_md&utm_campaign=dbt-qs

---

## Prerequisites

| Requirement | Notes |
| --- | --- |
| OS | macOS, Linux, Windows, or GitHub Codespaces |
| Privileges | Ability to install software on the machine |
| Editor (optional) | VS Code for the dbt extension |
| DuckDB | Built into dbt v2 — no separate DuckDB install for basic use |

**Connection path:** local DuckDB file (`path: './jaffle_shop.duckdb'`). No passwords or API keys.

DuckDB with dbt v2 is **CLI / local IDE only** (not a dbt platform warehouse target).

---

## 1. Install dbt v2

dbt v2 is the engine. The editor extension needs it. Prefer the command `dbt`. If another dbt CLI already owns that name (for example dbt Cloud CLI), use the unambiguous alias **`dbtf`**.

dbt v2 ships as a standalone binary. Python is not required. The setup scripts run these installers for you.

**macOS / Linux / Codespaces**

```bash
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
```

**Windows PowerShell**

```powershell
irm https://public.cdn.getdbt.com/fs/install/install.ps1 | iex
```

The binary lands in `~/.local/bin` (Windows: `%USERPROFILE%\.local\bin`). The setup scripts also add a `dbtf` alias next to it.

### Verify

Open a **new** terminal, then:

```bash
dbt --version
# if that is not v2.x on your machine:
dbtf --version
```

**Success check:** output includes a `2.x` version (for example `dbt 2.0.11`).

> **On this machine (`dnb_demo`):** `dbt` is aliased to the dbt Cloud CLI; use **`dbtf`** for dbt v2. On a clean machine where only dbt v2 is installed, `dbt` is enough. Below, `dbt` means “your dbt v2 binary” (`dbt` or `dbtf`).

---

## 2. Install the dbt extension (VS Code)

1. Open Extensions (`Cmd+Shift+X` on macOS, `Ctrl+Shift+X` on Windows/Linux).
2. Search for `dbt` → install **dbt Labs, LLC**.
3. Skip dbt platform sign-in if prompted (not required for local DuckDB).
4. Confirm the status bar shows **dbt Extension**.

**Success check:** status bar shows **dbt Extension**.

---

## 3. Create or use the Jaffle Shop project

### Already in this repo

The dbt project is the repository root. A portable DuckDB `profiles.yml` lives next to `dbt_project.yml`. Always pass `--profiles-dir .` (or set `DBT_PROFILES_DIR` to the project folder) so the same profile works on every machine without editing `~/.dbt`.

### Fresh machine / empty folder

```bash
# create sample project (interactive profile prompts can be skipped)
dbt init --project-name jaffle_shop --sample jaffle-shop --skip-profile-setup
cd jaffle_shop
```

Create `profiles.yml` in the project directory:

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "./jaffle_shop.duckdb"
      schema: main
      threads: 4
```

Ensure `dbt_project.yml` has:

```yaml
name: jaffle_shop
profile: jaffle_shop
```

**In-memory alternative** (data does not persist):

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: duckdb
```

---

## 4. Install packages, debug, and build

From the repository root (the folder that contains `dbt_project.yml`):

**macOS / Linux**

```bash
dbt deps --profiles-dir .
dbt debug --profiles-dir .
dbt build --profiles-dir .
```

**Windows (PowerShell or CMD)** — same commands; paths use the project-local `profiles.yml` and `.\jaffle_shop.duckdb`.

Optional env var (any OS) so you can omit `--profiles-dir`:

```bash
# macOS / Linux
export DBT_PROFILES_DIR="$PWD"

# Windows PowerShell
$env:DBT_PROFILES_DIR = (Get-Location).Path
```

**Success checks**

- `debug`: `Debugging connection test: OK` / all checks passed; adapter `duckdb`
- `build`: seeds, models, and tests succeed (this repo: **48 success**)

Confirm the database file exists:

```bash
# macOS / Linux
ls -lah *.duckdb

# Windows PowerShell
Get-ChildItem *.duckdb
```

---

## 5. Explore in the editor

1. Open the repository root (the folder that contains `dbt_project.yml`). That is the dbt project.
2. Open `models/marts/orders.sql`.
3. Use **Preview File**, **Compile File**, and the **Lineage** panel.
4. Run commands from the dbt icon or Command Palette (`>dbt:`).

**Success check:** Lineage and Query Results panels appear; preview/compile work on a model.

### Try Compare with a local baseline

The dbt extension's Compare feature needs a state manifest for a built schema distinct from your dev schema. This project provides a `compare_baseline` DuckDB target in the same local database, so no dbt platform sign-in or credentials are needed. The workspace config points the extension to `target/compare_state`; generated state stays local and is ignored by Git. The setup scripts create this baseline for you, and `macros/duckdb__quick_are_queries_identical.sql` adds the DuckDB support Compare needs.

To refresh the baseline by hand, from the project root:

```bash
dbtf build --target compare_baseline --target-path target/compare_baseline --profiles-dir .
mkdir -p target/compare_state
cp target/compare_baseline/manifest.json target/compare_state/manifest.json
dbtf build --profiles-dir .
```

In VS Code, save a change to a model, build that model in the default `dev` target, then run the extension's **Compare** action. Refresh the baseline by repeating the first two commands when you want a new comparison point. The baseline uses the same local seed data; Compare validates the feature and schema-to-schema comparison workflow, not a production data environment.

---

## Cross-machine checklist

| Step | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Install | `./scripts/setup.sh --install` | same | `.\scripts\setup.ps1 -Install` |
| Verify | `dbt --version` / `dbtf --version` | same | same |
| Profile | project `profiles.yml` + `--profiles-dir .` | same | same |
| Build | `dbt build --profiles-dir .` | same | same |
| DuckDB file | `./jaffle_shop.duckdb` next to `profiles.yml` | same | same |

Clone the repo, or copy the repository root. Do **not** commit `.env`, `*.duckdb`, or `target/`. Recipients only need dbt v2 + the project files.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `dbt --version` shows Cloud CLI / v1 | Use `dbtf`, or put `~/.local/bin` first on `PATH` |
| `dbt-fusion binary not found` | Set `dbt.dbtPath` to `~/.local/bin/dbt` in editor settings, or re-run the setup script |
| Compare: `quick_are_queries_identical() is not implemented for adapter 'duckdb'` | Pull the latest repo; `macros/duckdb__quick_are_queries_identical.sql` and the `dispatch` block in `dbt_project.yml` fix it. Then reload the window |
| Connection / lock errors on `.duckdb` | Close other sessions (DBeaver, second dbt process); last resort: delete `*.duckdb` and rebuild |
| LSP / “not running in this workspace” | Add the **project root** (folder with `dbt_project.yml`) to the workspace |
| Extensions (`httpfs`, `parquet`, …) | Bundled DuckDB driver may not load extensions; see [DuckDB setup](https://docs.getdbt.com/docs/local/connect-data-platform/duckdb-setup.md) for the system driver via `dbc` |

---

## Useful commands

```bash
dbt build --profiles-dir .          # seeds + models + tests
dbt run --profiles-dir .            # models only
dbt test --profiles-dir .           # tests only
dbt show --select orders --profiles-dir .
dbt build --write-catalog --profiles-dir .   # local docs metadata
```

More: [About dbt v2](https://docs.getdbt.com/docs/fusion/about-fusion), [DuckDB setup](https://docs.getdbt.com/docs/local/connect-data-platform/duckdb-setup.md), [dbt command reference](https://docs.getdbt.com/reference/dbt-commands).
