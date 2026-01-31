# Migration Guide: Dotfiles Integration for Docker Claude

This guide walks you through setting up your Claude configuration to sync via dotfiles, enabling seamless sharing between native Claude and Docker Claude.

## Overview

After migration:
- **Synced via dotfiles**: `settings.json`, `skills/`, `hooks/`, `commands/`, `agents/`, `plugins/installed_plugins.json`
- **Machine-local**: `.credentials.json`, `projects/` (sessions), `history.jsonl`, cache, etc.

## Pre-flight Checks

Before starting, verify:

```bash
# Check current ~/.claude structure
ls -la ~/.claude/

# Verify dotfiles location exists
ls -la ~/dotfiles/

# Check if skills are already symlinked
ls -la ~/.claude/skills
```

## Step 1: Full Backup

**Critical**: Back up your entire `~/.claude` directory before making any changes.

```bash
# Create timestamped backup
tar -czvf ~/claude-backup-$(date +%Y%m%d-%H%M%S).tar.gz ~/.claude/

# Verify backup
tar -tzvf ~/claude-backup-*.tar.gz | head -20
```

## Step 2: Set Up Dotfiles Structure

Create the directory structure in your dotfiles:

```bash
# Create directories
mkdir -p ~/dotfiles/claude/{skills,hooks,commands,agents,plugins}

# Verify
ls -la ~/dotfiles/claude/
```

## Step 3: Migrate Settings

Move `settings.json` to dotfiles and create symlink:

```bash
# Check if settings.json exists and isn't already a symlink
ls -la ~/.claude/settings.json

# Copy to dotfiles (use cp first to preserve original)
cp ~/.claude/settings.json ~/dotfiles/claude/settings.json

# Verify the copy
cat ~/dotfiles/claude/settings.json

# Remove original and create symlink
rm ~/.claude/settings.json
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json

# Verify symlink works
ls -la ~/.claude/settings.json
cat ~/.claude/settings.json
```

## Step 4: Migrate Skills

Move skills to dotfiles (or verify existing setup):

```bash
# Check current skills state
ls -la ~/.claude/skills

# If skills is a directory (not symlink), move contents
if [ -d ~/.claude/skills ] && [ ! -L ~/.claude/skills ]; then
    cp -r ~/.claude/skills/* ~/dotfiles/claude/skills/ 2>/dev/null || true
    rm -rf ~/.claude/skills
fi

# Create symlink
ln -sf ~/dotfiles/claude/skills ~/.claude/skills

# Verify
ls -la ~/.claude/skills
ls -la ~/.claude/skills/
```

## Step 5: Set Up Hooks, Commands, Agents

Create symlinks for hooks, commands, and agents (these may not exist yet):

```bash
# Remove any existing directories and create symlinks
rm -rf ~/.claude/hooks ~/.claude/commands ~/.claude/agents

ln -sf ~/dotfiles/claude/hooks ~/.claude/hooks
ln -sf ~/dotfiles/claude/commands ~/.claude/commands
ln -sf ~/dotfiles/claude/agents ~/.claude/agents

# Verify
ls -la ~/.claude/hooks ~/.claude/commands ~/.claude/agents
```

## Step 6: Migrate Plugins List

Move the installed plugins list to dotfiles:

```bash
# Check if plugins directory and file exist
ls -la ~/.claude/plugins/

# Create plugins directory in dotfiles if needed
mkdir -p ~/dotfiles/claude/plugins

# Copy installed_plugins.json if it exists
if [ -f ~/.claude/plugins/installed_plugins.json ]; then
    cp ~/.claude/plugins/installed_plugins.json ~/dotfiles/claude/plugins/
    rm ~/.claude/plugins/installed_plugins.json
    ln -sf ~/dotfiles/claude/plugins/installed_plugins.json ~/.claude/plugins/installed_plugins.json
fi

# Verify
ls -la ~/.claude/plugins/installed_plugins.json
```

## Verification Checklist

Run these commands to verify the migration:

```bash
echo "=== Checking symlinks ==="
ls -la ~/.claude/settings.json
ls -la ~/.claude/skills
ls -la ~/.claude/hooks
ls -la ~/.claude/commands
ls -la ~/.claude/agents
ls -la ~/.claude/plugins/installed_plugins.json

echo ""
echo "=== Checking dotfiles content ==="
cat ~/dotfiles/claude/settings.json
ls -la ~/dotfiles/claude/skills/
ls -la ~/dotfiles/claude/hooks/
ls -la ~/dotfiles/claude/commands/
ls -la ~/dotfiles/claude/agents/
cat ~/dotfiles/claude/plugins/installed_plugins.json 2>/dev/null || echo "(no plugins file)"

echo ""
echo "=== Testing symlinks resolve correctly ==="
cat ~/.claude/settings.json > /dev/null && echo "settings.json: OK"
ls ~/.claude/skills/ > /dev/null && echo "skills/: OK"
ls ~/.claude/hooks/ > /dev/null && echo "hooks/: OK"
ls ~/.claude/commands/ > /dev/null && echo "commands/: OK"
ls ~/.claude/agents/ > /dev/null && echo "agents/: OK"
```

## Test Docker Integration

Test that Docker picks up the configuration:

```bash
# Run container with overlay mounts
docker run \
  --cap-add=NET_ADMIN \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$HOME/dotfiles/claude/settings.json",target=/home/node/.claude/settings.json \
  --mount type=bind,source="$HOME/dotfiles/claude/skills",target=/home/node/.claude/skills \
  --mount type=bind,source="$HOME/dotfiles/claude/hooks",target=/home/node/.claude/hooks \
  --mount type=bind,source="$HOME/dotfiles/claude/commands",target=/home/node/.claude/commands \
  --mount type=bind,source="$HOME/dotfiles/claude/agents",target=/home/node/.claude/agents \
  --mount type=bind,source="$HOME/dotfiles/claude/plugins/installed_plugins.json",target=/home/node/.claude/plugins/installed_plugins.json \
  --mount type=bind,source="$PWD",target="$PWD" \
  --workdir "$PWD" \
  -it cc sh -c "ls -la /home/node/.claude/skills/ && cat /home/node/.claude/settings.json"
```

You should see your skills and settings from dotfiles.

## Rollback Procedure

If something goes wrong, restore from backup:

```bash
# Remove current ~/.claude
rm -rf ~/.claude

# Find your backup
ls -la ~/claude-backup-*.tar.gz

# Restore (extracts to ~/.claude)
cd ~
tar -xzvf claude-backup-YYYYMMDD-HHMMSS.tar.gz

# Verify restoration
ls -la ~/.claude/
```

## Session Backup (Optional)

To backup your session history separately:

```bash
# Backup all sessions
tar -czvf ~/claude-sessions-$(date +%Y%m%d).tar.gz ~/.claude/projects/

# List sessions by project
ls -la ~/.claude/projects/
```

## Troubleshooting

### Symlink points to wrong location

```bash
# Check where symlink points
readlink ~/.claude/settings.json

# Fix by recreating with correct path
rm ~/.claude/settings.json
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
```

### Permission denied errors

```bash
# Check file permissions
ls -la ~/dotfiles/claude/

# Fix if needed
chmod 644 ~/dotfiles/claude/settings.json
chmod 755 ~/dotfiles/claude/skills
```

### Docker can't read mounted files

Ensure the files exist at the paths specified in the docker run command:

```bash
# Verify all mount sources exist
ls -la ~/dotfiles/claude/settings.json
ls -la ~/dotfiles/claude/skills
ls -la ~/dotfiles/claude/hooks
ls -la ~/dotfiles/claude/commands
ls -la ~/dotfiles/claude/agents
ls -la ~/dotfiles/claude/plugins/installed_plugins.json
```

If a file doesn't exist, either create it or remove that mount from the docker command.
