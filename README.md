# wt - Git Worktree CLI Tool

A minimalist command-line interface for git worktree management, designed to work like standard git commands with subcommands and clean output formatting.

## Overview

`wt` is a CLI tool that simplifies git worktree management through an intuitive interface similar to git itself. It provides fast, reliable worktree operations with clean output and smart defaults.

## Core Philosophy

- **CLI-first**: Clean command-line interface like `git`
- **Git-like**: Familiar subcommand structure (`wt list`, `wt new`, `wt rm`)
- **Minimal**: Clean, readable output with good alignment
- **Fast**: Quick operations, no interactive menus unless needed
- **Consistent**: Predictable behavior and output formatting

## Commands

### `wt list` (alias: `ls`)

Display all worktrees in a clean table format:

```
BRANCH               PATH                    HEAD     STATUS
──────────────────────────────────────────────────────────────
main                 .                       502893cb  
feat/auth-system     _wt/feat-auth-system    b2c3d4e   locked
feat/ui-redesign     _wt/feat-ui-redesign    c3d4e5f   prunable
```

**Features:**
- Auto-aligned columns based on content width
- Current worktree indicated clearly (path = ".")
- HEAD commit short hash (8 characters)
- Clean branch names (removes `refs/heads/` prefix)
- Status indicators: `locked`, `prunable` with color coding *(planned)*
- Color support with automatic terminal detection

### `wt new [branch_name] [options]`

Create new worktree with automatic directory naming and interactive prompting:

```bash
$ wt new feat/user-profile
Creating worktree 'feat/user-profile' at '_wt/feat-user-profile' from 'origin/main'...
✓ Created worktree feat/user-profile at _wt/feat-user-profile

$ wt new
Branch name: feat/user-profile
Creating worktree 'feat/user-profile' at '_wt/feat-user-profile' from 'origin/main'...
✓ Created worktree feat/user-profile at _wt/feat-user-profile
```

**Options:**
- `--base <ref>`: Base branch/commit (default: origin/main)
- `--dir <path>`: Custom directory (default: auto-generated)
- `--no-checkout`: Create worktree without checking out files *(planned)*
- `--force`: Force creation even if directory exists *(planned)*

**Directory Naming:**
- `feat/auth-system` → `_wt/feat-auth-system`
- `fix/bug-123` → `_wt/fix-bug-123`
- `hotfix/security` → `_wt/hotfix-security`
- Conflicts resolved with `-2`, `-3` suffix

### `wt rm [branch_name] [options]`

Remove worktree by branch name with interactive selection:

```bash
$ wt rm feat/auth-system
Remove worktree 'feat/auth-system' at '_wt/feat-auth-system'? [y/N]: y
✓ Removed worktree feat/auth-system

$ wt rm
Select worktree to remove:
  1. feat/auth-system (_wt/feat-auth-system)
  2. feat/ui-redesign (_wt/feat-ui-redesign)
Choice [1-2]: 1
```

**Options:**
- `-f, --force`: Skip confirmation prompt
- `--keep-dir`: Remove worktree but keep directory *(planned)*

**Smart Branch Matching:**
- Exact match: `test-branch` matches `claude/test-branch`
- Partial match: `test` matches `feat/test-one`, `feat/test-two`
- Multiple matches show selection menu

### `wt sync`

Sync worktrees with remote:

```bash
$ wt sync
Syncing worktrees...
✓ Synced worktrees
```

### `wt prune`

Remove stale worktree administrative files:

```bash
$ wt prune
Pruning worktrees...
✓ Pruned worktrees
```

## Color Support

`wt` provides rich color output with automatic terminal detection:

**Color Mapping:**
- **Green**: Success messages (✓), `ahead N` status *(planned)*
- **Blue**: Informational status (`behind N`) *(planned)*
- **Yellow**: Warning messages (⚠), `dirty` status *(planned)*
- **Red**: Error messages (✗), `locked` status *(planned)*
- **Gray/Dim**: `prunable` status *(planned)*, commit hashes

**Environment Variables:**
- `NO_COLOR=1` - Disable all color
- `FORCE_COLOR=1` - Force color even when piped
- `WT_COLOR=never` - wt-specific color control

## Configuration

### `.wtconfig` file format:

```ini
[wt]
base_ref = origin/main
worktree_dir_prefix = _wt/
auto_name_directories = true
name_transform = slash_to_dash

[formatting]
color = auto
show_head_hashes = true
status_indicators = true
```

### Environment Variables:

```bash
WT_BASE_REF=origin/develop
WT_DIR_PREFIX=worktrees/
WT_COLOR=auto
NO_COLOR=1
```

## Installation

### Homebrew (macOS) *(planned)*

```bash
brew install wt
```

### Direct Download *(planned)*

```bash
curl -fsSL https://raw.githubusercontent.com/user/wt/main/install.sh | sh
```

### Python Package *(planned)*

```bash
pip install wt-git-worktree
```

## Shell Integration

### Aliases

Add to your shell configuration:

```bash
alias wtl='wt list'
alias wtn='wt new'
alias wtr='wt rm'

# Change directory to worktree *(requires `wt cd` command - planned)*
wtcd() {
    local path=$(wt cd "$1" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$path" ]; then
        cd "$path"
    fi
}
```

## Example Workflows

### Creating a new feature branch:

```bash
$ wt new feat/user-dashboard
✓ Created worktree feat/user-dashboard at _wt/feat-user-dashboard

$ cd _wt/feat-user-dashboard
# Work on feature...

$ wt list
BRANCH               PATH                      HEAD     STATUS
──────────────────────────────────────────────────────────────
main                 .                         a1b2c3d  
feat/user-dashboard  _wt/feat-user-dashboard   c3d4e5f  ahead 3 *(status display planned)*
```

### Cleanup when done:

```bash
$ wt rm feat/user-dashboard
Remove worktree 'feat/user-dashboard' at '_wt/feat-user-dashboard'? [y/N]: y
✓ Removed worktree feat/user-dashboard
```

## Implementation Status

### ✅ Completed Features

- Core commands (`list`, `new`, `rm`, `sync`, `prune`)
- Interactive prompting and validation
- Smart branch matching and color support
- Configuration system with `.wtconfig` files
- Cross-platform support (macOS, Linux, Windows WSL)

### 🚧 Planned Features

- `wt status` - Detailed worktree information
- `wt rebase` - Rebase operations
- `wt cd` - Shell integration for directory changes
- `wt code` - VS Code integration
- `wt config` - Configuration management
- Advanced status indicators (`ahead`/`behind`, `dirty`, `locked`, `prunable`)
- Shell completion scripts
- Package distribution (Homebrew, pip, etc.)

## Benefits

1. **Familiar**: Uses git command patterns developers already know
2. **Scriptable**: Easy integration into scripts and automation
3. **Fast**: No UI overhead, direct command execution
4. **Composable**: Works well with other command-line tools
5. **Accessible**: Works in any terminal, no special requirements

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions welcome! Please see CONTRIBUTING.md for guidelines.