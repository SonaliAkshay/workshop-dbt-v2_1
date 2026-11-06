# Setup scripts

| Script | OS | Purpose |
| --- | --- | --- |
| `setup.sh` | macOS / Linux / Codespaces | Install the dbt Fusion binary to `~/.local/bin` if needed, then `deps` / `debug` / Compare baseline / `build` |
| `setup.ps1` | Windows PowerShell | Same as above (`-Install`) |
| `verify.sh` | macOS / Linux / Codespaces | Resolve dbt v2 + `debug` only |
| `verify.ps1` | Windows PowerShell | Same as above |
| `lib/resolve_dbt.sh` | bash | Prefer `dbtf`, then `dbt`, then `~/.local/bin/dbt` (must report 2.x) |

## macOS / Linux / Codespaces

```bash
chmod +x scripts/*.sh scripts/lib/*.sh
./scripts/setup.sh --install
./scripts/verify.sh
```

Codespaces runs `./scripts/setup.sh --install` automatically via `.devcontainer/devcontainer.json` `postCreateCommand`.

## Windows

```powershell
.\scripts\setup.ps1 -Install
.\scripts\verify.ps1
```

Scripts run from the repository root and use `profiles.yml` via `--profiles-dir .` (portable DuckDB; no `~/.dbt` required).
