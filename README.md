# ellipsis

Automated dotfile management and syncing. A single-file CLI that adds scheduled auto-commit, auto-push, and pre-commit validation on top of [yadm](https://yadm.io/).

## What it does

ellipsis watches your yadm-tracked dotfiles and automatically commits and pushes changes to your remote repository on a schedule. It also installs a pre-commit hook that blocks commits containing secrets or syntax errors.

- Runs every 15 minutes (configurable) via a macOS LaunchAgent or Linux systemd timer
- Builds descriptive commit messages from the changed files
- Handles offline gracefully (skips push, retries next cycle)
- Validates shell config syntax before committing
- Scans for accidentally staged API tokens and credentials
- Works with SSH and HTTPS git remotes

## Installation

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/kapowaz/ellipsis/main/install.sh | bash
```

### Manual install

Download the `ellipsis` script and put it somewhere in your `PATH`:

```bash
curl -O https://raw.githubusercontent.com/kapowaz/ellipsis/main/ellipsis
chmod +x ellipsis
mv ellipsis ~/bin/  # or /usr/local/bin/
```

### Prerequisites

- [yadm](https://yadm.io/) (`brew install yadm` on macOS)
- git
- An initialised yadm repo with a remote

## Getting started

1. Set up yadm if you haven't already:

   ```bash
   brew install yadm
   yadm init
   yadm remote add origin git@github.com:you/dotfiles.git
   ```

2. Run the interactive setup:

   ```bash
   ellipsis init
   ```

   This will:
   - Auto-detect your remote, shell, and OS
   - Write a config file to `~/.config/ellipsis/config.sh`
   - Install a pre-commit validation hook
   - Set up a scheduler (LaunchAgent on macOS, systemd timer or cron on Linux)

3. Verify everything is working:

   ```bash
   ellipsis doctor
   ```

## Usage

```
ellipsis init          # first-time setup
ellipsis sync          # manually trigger a sync cycle
ellipsis log           # show recent sync log entries
ellipsis log -f        # follow the log
ellipsis log -n 50     # show last 50 entries
ellipsis log --clear   # clear the log
ellipsis doctor        # check setup health
ellipsis uninstall     # remove ellipsis config (keeps yadm and dotfiles)
ellipsis version       # print version
ellipsis help          # show help
```

### How sync works

Each sync cycle (whether triggered by the scheduler or manually):

1. Acquires a lock to prevent overlapping runs
2. Checks network connectivity to the git remote
3. Adds new files from configured auto-add directories
4. Stages modifications to already-tracked files (`yadm add -u`)
5. Commits with a descriptive message (e.g. `auto: update .zshrc`)
6. Pushes to the remote

If the network is unreachable, the cycle is skipped. If push fails, the commit is preserved locally and retried on the next cycle.

### Pre-commit validation

The hook installed by `ellipsis init` runs on every commit (including auto-sync commits) and checks for:

- **Shell syntax errors** -- validates `.zshrc`, `.bashrc`, or `config.fish` with the appropriate syntax checker
- **Inline secrets** -- detects patterns like `PASSWORD="..."`, `TOKEN=...` in shell config files
- **API tokens** -- scans all staged files for common token formats (npm, GitHub, GitLab, AWS, Slack, OpenAI)
- **Duplicate PATH entries** -- warns about repeated path components (does not block)

## Configuration

Config file: `~/.config/ellipsis/config.sh` (created by `ellipsis init`)

All settings have sensible defaults. Only override what you need.

| Variable | Default | Description |
|---|---|---|
| `ELLIPSIS_AUTO_ADD_DIRS` | `""` | Space-separated directories to auto-add new files from (e.g. `"$HOME/.claude/skills/ $HOME/bin/"`) |
| `ELLIPSIS_SYNC_INTERVAL` | `900` | Seconds between sync cycles (900 = 15 minutes) |
| `ELLIPSIS_COMMIT_PREFIX` | `"auto"` | Prefix for auto-generated commit messages |
| `ELLIPSIS_REMOTE_HOST` | *(auto-detected)* | Git remote hostname |
| `ELLIPSIS_REMOTE_TRANSPORT` | *(auto-detected)* | `ssh` or `https` |
| `ELLIPSIS_SHELL_CONFIGS` | *(auto-detected)* | Shell config files to validate (e.g. `.zshrc`) |
| `ELLIPSIS_EXTRA_SECRET_PATTERNS` | `""` | Additional regex patterns for secret scanning (pipe-separated) |
| `ELLIPSIS_LAUNCHD_LABEL` | `io.github.ellipsis.sync` | macOS LaunchAgent identifier |
| `ELLIPSIS_LOGFILE` | `~/.local/share/ellipsis/sync.log` | Sync log file path |
| `ELLIPSIS_LOCK` | `/tmp/ellipsis-sync.lock` | Lock file path |

### Example config

```bash
# ~/.config/ellipsis/config.sh
ELLIPSIS_REMOTE_HOST="github.com"
ELLIPSIS_REMOTE_TRANSPORT="ssh"
ELLIPSIS_SHELL_CONFIGS=".zshrc"
ELLIPSIS_SYNC_INTERVAL=900
ELLIPSIS_AUTO_ADD_DIRS="$HOME/.claude/skills/ $HOME/bin/"
ELLIPSIS_EXTRA_SECRET_PATTERNS="my_custom_prefix_[a-zA-Z0-9]{32}"
```

## Cross-platform support

| OS | Scheduler | Detected by |
|---|---|---|
| macOS | LaunchAgent | `uname -s` = Darwin |
| Linux (systemd) | systemd user timer | `systemctl` in PATH |
| Linux (no systemd) | cron | fallback |

## Checking sync status

```bash
# Recent activity
ellipsis log

# Follow in real time
ellipsis log -f

# Full health check
ellipsis doctor
```

Example `doctor` output:

```
[OK] yadm installed (yadm 3.5.0)
[OK] yadm repo initialized
[OK] Remote: git@github.com:you/dotfiles.git
[OK] Network: github.com reachable via ssh
[OK] Config: ~/.config/ellipsis/config.sh
[OK] Pre-commit hook installed
[OK] Scheduler: LaunchAgent loaded (io.github.ellipsis.sync)
[OK] ellipsis in PATH: /Users/you/bin/ellipsis
[OK] No stale lock file
[OK] Log file writable

All checks passed.
```

## Uninstalling

```bash
ellipsis uninstall
```

This removes the scheduler, pre-commit hook, config, and logs. It does **not** touch yadm, your repo, or any dotfiles.

## License

MIT
