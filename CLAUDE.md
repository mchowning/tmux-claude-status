# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tmux plugin that provides real-time Claude AI status monitoring across tmux sessions. It uses Claude Code's official hooks system to track when Claude is working vs idle, and displays this information in an enhanced tmux session switcher.

## Architecture

### Core Components

1. **Hook System** (`hooks/better-hook.sh`): Integrates with Claude Code's hooks to track status
   - Responds to `PreToolUse` and `Stop` events from Claude Code
   - Writes status files to `~/.cache/tmux-claude-status/{session_name}.status`
   - Handles both local tmux sessions and SSH remote sessions

2. **Session Switcher** (`scripts/hook-based-switcher.sh`): Enhanced tmux session picker
   - Groups sessions by Claude status (Working/Done/No Claude)
   - Provides live preview of session content
   - Supports vim-style navigation and manual refresh
   - Integrates with fzf for interactive selection

3. **Smart Monitor** (`smart-monitor.sh`): Background daemon for SSH session monitoring
   - Auto-starts when SSH sessions are detected
   - Polls remote status files over SSH
   - Auto-stops when no SSH sessions exist
   - Caches remote status in local files

4. **Main Plugin** (`tmux-claude-status.tmux`): tmux plugin entry point
   - Binds the session switcher to configurable key (default: prefix + s)
   - Configurable via tmux option `@claude-status-key`

### SSH Support Architecture

The plugin maps remote hostnames to local session names:
- `setup-server.sh` configures hostname mappings in the hook
- Remote Claude instances write status files on the remote machine
- Smart monitor polls these files and caches them locally
- Session switcher reads cached status for display

## Common Development Tasks

### Testing the Plugin

Install and test locally:
```bash
# Link to tmux plugins directory
ln -sf $(pwd) ~/.config/tmux/plugins/tmux-claude-status

# Load in tmux
tmux run-shell ~/.config/tmux/plugins/tmux-claude-status/tmux-claude-status.tmux

# Test session switcher
tmux prefix + s
```

### Testing SSH Integration

Set up SSH server monitoring:
```bash
./setup-server.sh <session-name> <ssh-host>
```

Test remote status:
```bash
# Check smart monitor status
./smart-monitor.sh status

# Manually update SSH status
./smart-monitor.sh update

# View cached remote status
cat ~/.cache/tmux-claude-status/reachgpu-remote.status
```

### Debugging Hook Integration

Check Claude Code hooks setup:
```bash
# View current hooks config
cat ~/.claude/settings.json

# Test hook manually
echo '{}' | ./hooks/better-hook.sh PreToolUse

# Check status files
ls -la ~/.cache/tmux-claude-status/
```

## Key Design Patterns

### Status File Pattern
- Status files are simple text files containing "working" or "done"
- Local sessions: `{session_name}.status`
- Remote sessions: `{session_name}-remote.status`

### Hostname Mapping Pattern
The hook uses a case statement to map remote hostnames to local session names:
```bash
case $(hostname -s) in
    instance-*) TMUX_SESSION="reachgpu" ;;
    specific-host) TMUX_SESSION="custom-name" ;;
    *) TMUX_SESSION=$(hostname -s) ;;
esac
```

### Smart Daemon Pattern
The smart monitor uses PID files and process detection to:
- Only run when SSH sessions exist
- Auto-cleanup when no longer needed
- Prevent multiple instances

## Configuration

### Tmux Options
- `@claude-status-key`: Key binding for session switcher (default: "s")

### File Locations
- Status cache: `~/.cache/tmux-claude-status/`
- Plugin installation: `~/.config/tmux/plugins/tmux-claude-status/`
- Claude hooks config: `~/.claude/settings.json`