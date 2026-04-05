# docker-claude

Docker images for running Claude Code in containers.

## Images

- **cc-open**: Full-featured base -- system tools, shell niceties, agent-browser + Chromium, Claude Code CLI, uv. No firewall.
- **cc**: Derives from cc-open, adds network firewall (egress allowlist).

## Building

```bash
# Build both images (cc-open first, then cc)
./build.sh
```

## Quick Start

```bash
docker run \
  --cap-add=NET_ADMIN \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$PWD",target="$PWD" \
  --workdir "$PWD" \
  -it cc claude --dangerously-skip-permissions
```

### Volume Mounts

| Mount | Purpose |
|-------|---------|
| `~/.claude` -> `/home/node/.claude` | OAuth credentials, session data, config |

We intentionally do **not** mount `~/.claude.json`. While it's needed for interactive mode, concurrent access from host and container Claude instances corrupts it. Headless `-p` (print) mode works without it.

## With Dotfiles Integration

If you sync your Claude configuration via dotfiles (settings, skills, hooks, commands, agents, plugins), use overlay mounts to resolve broken symlinks inside the container:

```bash
docker run \
  --cap-add=NET_ADMIN \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$HOME/dotfiles/claude/settings.json",target=/home/node/.claude/settings.json \
  --mount type=bind,source="$HOME/dotfiles/claude/CLAUDE.md",target=/home/node/.claude/CLAUDE.md \
  --mount type=bind,source="$HOME/dotfiles/claude/statusline.sh",target=/home/node/.claude/statusline.sh \
  --mount type=bind,source="$HOME/dotfiles/claude/skills",target=/home/node/.claude/skills \
  --mount type=bind,source="$HOME/dotfiles/claude/hooks",target=/home/node/.claude/hooks \
  --mount type=bind,source="$HOME/dotfiles/claude/commands",target=/home/node/.claude/commands \
  --mount type=bind,source="$HOME/dotfiles/claude/agents",target=/home/node/.claude/agents \
  --mount type=bind,source="$HOME/dotfiles/claude/plugins",target=/home/node/.claude/plugins \
  --mount type=bind,source="$PWD",target="$PWD" \
  --workdir "$PWD" \
  -it cc claude --dangerously-skip-permissions
```

See [migration_claude_config_dir_to_dotfiles.md](migration_claude_config_dir_to_dotfiles.md) for setup instructions.

## Using cc-open (no firewall)

For containers that need unrestricted internet access (e.g. web search agents):

```bash
docker run \
  --shm-size=2g \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$PWD",target="$PWD" \
  --workdir "$PWD" \
  -it cc-open claude -p "search the web for recent news"
```

`--shm-size=2g` is needed if using agent-browser/Chromium (Chrome's shared memory requirements exceed Docker's default 64MB).

## Browser: agent-browser + Chromium

Both images include [agent-browser](https://github.com/vercel-labs/agent-browser) (Vercel's CLI browser tool) and system Chromium.

There are two workarounds in place, both documented in `Dockerfile.open` and `start-browser.sh`:

**1. System Chromium instead of Chrome for Testing.** `agent-browser install` downloads Chrome for Testing, but it has no ARM64 Linux builds. We install Debian's `chromium` package instead.

**2. Pre-launched Chromium via CDP instead of agent-browser's own launch.** Chrome in Docker needs `--no-sandbox` (no Linux namespace privileges). agent-browser documents `AGENT_BROWSER_ARGS` and `--args` for passing Chrome flags, but neither works reliably in containers -- we tested comma-separated env vars, newline-separated env vars, CLI `--args` flag, and `~/.agent-browser/config.json`, all producing "CDP response channel closed" errors. The root cause is likely Chrome crashing before CDP connects due to insufficient `/dev/shm` (Docker defaults to 64MB) combined with the flags not being passed correctly. Pre-launching Chromium ourselves with the right flags and having agent-browser connect to it via `--cdp 9222` works reliably.

Usage:

```bash
# Start Chromium (included helper script, idempotent)
start-browser.sh

# Use agent-browser via CDP connection
agent-browser --cdp 9222 open https://example.com
agent-browser --cdp 9222 snapshot -i
```

Containers using agent-browser should set `shm_size: '2g'` in compose (or `--shm-size=2g` on `docker run`) and call `start-browser.sh` from their entrypoint.

## Session Persistence

By mounting `$PWD` at its actual host path (instead of `/workspace/project`), Docker sessions are stored in the same location as native Claude sessions:

- Sessions stored in: `~/.claude/projects/-Users-yourname-code-projectname/`
- Use `claude --continue` to resume sessions from either Docker or native Claude
- All containers share session data via the `~/.claude` mount

## Firewall (cc only)

The cc image includes a network firewall that restricts outbound traffic to approved domains (GitHub, npm, Anthropic API, etc.). Requires `--cap-add=NET_ADMIN`.

**Host access**: Automatically allows `host.docker.internal` for host-side services.

**Customizing allowed domains**: Edit `init-firewall.sh` to add domains to the allowlist.

### Marketplace Warning

With the firewall enabled, you'll see:

```
Failed to install Anthropic marketplace · Will retry on next startup
```

This is expected -- the firewall blocks npm registry access needed for MCP marketplace servers. Claude Code works normally without them.
