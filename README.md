# dnb-dbt-v2-workshop

Local **dbt v2 (Fusion)** workshop using **DuckDB**. No warehouse credentials.

## Standard setup: git clone

**macOS / Linux**

```bash
git clone https://github.com/dbt-labs/dnb-dbt-v2-workshop.git
cd dnb-dbt-v2-workshop
chmod +x scripts/*.sh scripts/lib/*.sh
./scripts/setup.sh --install
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/dbt-labs/dnb-dbt-v2-workshop.git
cd dnb-dbt-v2-workshop
.\scripts\setup.ps1 -Install
```

The script installs the standalone dbt Fusion binary (Rust; no Python), runs `dbtf build`, downloads VS Code if it is missing, and installs the official **dbt** extension (`dbtLabsInc.dbt`). GitHub Codespaces already has the editor, so it does not download a desktop copy there. Success: `Fusion check passed` and **48 success**.

From that same folder:

```bash
dbtf build
```

Reload VS Code. Confirm the status bar shows **dbt Extension**. Follow [Quickstart for dbt v2](https://docs.getdbt.com/guides/dbt.md) from **Explore with the dbt VS Code extension**. Do not run `dbt init`. Use `dbtf` for the commands in that guide. `dbt_project.yml` is in the repository root.

## GitHub Codespaces

1. Open https://github.com/dbt-labs/dnb-dbt-v2-workshop
2. **Code → Codespaces → Create codespace on main**
3. Wait until the terminal shows `Fusion check passed` and **48 success**.

The Codespace runs `./scripts/setup.sh --install` for you. That installs dbt Fusion and runs `dbtf build` in the repository root. It also installs the **dbt** extension from **dbt Labs, LLC**. The extension is required. Confirm the status bar shows **dbt Extension**.

4. From the repository root, `dbtf build` should show **48 success**. Follow [Quickstart for dbt v2](https://docs.getdbt.com/guides/dbt.md) from **Explore with the dbt VS Code extension**. Do not run `dbt init`. Use `dbtf` for the commands in that guide.

## Download ZIP (no Git)

1. Open https://github.com/dbt-labs/dnb-dbt-v2-workshop
2. Click **Code**, then **Download ZIP**
3. Unzip it. The folder is `dnb-dbt-v2-workshop-main`

**macOS / Linux**

```bash
cd ~/Downloads/dnb-dbt-v2-workshop-main
chmod +x scripts/*.sh scripts/lib/*.sh
./scripts/setup.sh --install
```

**Windows (PowerShell)**

```powershell
cd $env:USERPROFILE\Downloads\dnb-dbt-v2-workshop-main
powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1 -Install
```

Success: `Fusion check passed` and **48 success**. Then run `dbtf build` from that same folder.
