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
