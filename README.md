# cursor-dotfiles

Personal Cursor Agent CLI configuration for reusable subagents and deletion-tool guidance.

## Managed configuration

### Subagents

| Agent | Model | Access | Background |
|---|---|---|---|
| `explore` | `cursor-grok-4.5-medium` | read-only | yes |
| `plan` | `cursor-grok-4.5-medium` | read-only | yes |
| `general-purpose` | `cursor-grok-4.5-medium` | read/write | yes |
| `worker` | `cursor-grok-4.6-high` | read/write | yes |

### Delete-via-Shell rule

The always-applied rule tells Cursor Agent not to use its built-in `Delete` tool when deletion was explicitly requested. It instead selects a bounded platform-native shell command with an exact path and verifies that the target no longer exists.

This is prompt-level guidance, not a permission bypass. Shell commands still pass through Cursor's permission rules and Auto-review.

- macOS/Linux: bounded `rm`/`rmdir` commands
- Windows PowerShell: `Remove-Item -LiteralPath` and `Test-Path -LiteralPath`

## Install on macOS or Linux

```sh
git clone https://github.com/larryboiNEUQ/cursor-dotfiles.git
cd cursor-dotfiles
chmod +x scripts/install.sh
./scripts/install.sh
```

The default destination is `~/.cursor`. Override it for testing with:

```sh
CURSOR_CONFIG_HOME=/tmp/cursor-config-test ./scripts/install.sh
```

## Install on Windows

```powershell
git clone https://github.com/larryboiNEUQ/cursor-dotfiles.git
Set-Location cursor-dotfiles
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The default destination is `%USERPROFILE%\.cursor`. Override it for testing with:

```powershell
$env:CURSOR_CONFIG_HOME = Join-Path $env:TEMP 'cursor-config-test'
.\scripts\install.ps1
```

## Update an existing machine

```sh
git pull
./scripts/install.sh
```

Or on Windows:

```powershell
git pull
.\scripts\install.ps1
```

The installers manage only the files represented under `config/`. Existing differing files are copied to adjacent timestamped backups before replacement. Other Cursor settings are untouched.

Restart Cursor CLI after installation or updates. Cursor loads these files from:

```text
~/.cursor/agents/*.md
~/.cursor/rules/*.mdc
```

On Windows, `~` corresponds to `%USERPROFILE%`.

## Direct invocation

```text
/explore <task>
/plan <task>
/general-purpose <task>
/worker <task>
```

Cursor may also select a subagent automatically from its description.

## Cross-platform CI

[![Install configuration](https://github.com/larryboiNEUQ/cursor-dotfiles/actions/workflows/install.yml/badge.svg)](https://github.com/larryboiNEUQ/cursor-dotfiles/actions/workflows/install.yml)

Every push to `main` and pull request runs the actual platform installers on:

- Ubuntu and macOS: `scripts/install.sh`
- Windows PowerShell 5.1 and PowerShell 7: `scripts/install.ps1`

Tests require Python 3 but no Cursor account. They use an isolated
`CURSOR_CONFIG_HOME` with spaces and Unicode in its path and invoke the scripts
from outside the repository. They verify exact installed file contents (including
the platform-specific rule), repeat-install idempotence, backup contents, and
preservation of unrelated configuration.

Run locally with Python 3:

```sh
python3 tests/test_install.py --installer sh -v
```

```powershell
python tests/test_install.py --installer powershell -v
python tests/test_install.py --installer pwsh -v
```

CI verifies file deployment, not Cursor's runtime rule loading, model availability,
or Auto-review decisions. Those still require a real Cursor session on the target
machine. The default home-directory destination is not exercised: CI uses the
explicit destination override to avoid altering runner configuration.
