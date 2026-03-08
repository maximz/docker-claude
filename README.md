# docker-claude

Docker image for running Claude Code with development tools, firewall support, and headless Chrome.

## Quick Start

```bash
docker run \
  --cap-add=NET_ADMIN \
  --mount type=bind,source="$HOME/.claude",target=/home/node/.claude \
  --mount type=bind,source="$PWD",target="$PWD" \
  --workdir "$PWD" \
  -it cc claude --dangerously-skip-permissions
```

## With Dotfiles Integration

If you sync your Claude configuration via dotfiles (settings, skills, hooks, commands, agents, plugins), use overlay mounts:

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

The overlay mounts take precedence over the base `~/.claude` mount, so your dotfiles content is used directly in the container.

See [migration_claude_config_dir_to_dotfiles.md](migration_claude_config_dir_to_dotfiles.md) for setup instructions.

## Session Persistence

By mounting `$PWD` at its actual host path (instead of `/workspace/project`), Docker sessions are stored in the same location as native Claude sessions:

- Sessions stored in: `~/.claude/projects/-Users-yourname-code-projectname/`
- Use `claude --continue` to resume sessions from either Docker or native Claude
- All containers share session data via the `~/.claude` mount

## Marketplace Warning

When using the firewall (`--cap-add=NET_ADMIN`), you'll see:

```
Failed to install Anthropic marketplace · Will retry on next startup
```

This is expected. The firewall restricts outbound traffic to Anthropic's API endpoints only, blocking npm registry access needed to install MCP marketplace servers. Claude Code works normally without them—marketplace servers are optional integrations (PubMed, Asana, etc.).

To avoid this warning, either run without `--cap-add=NET_ADMIN` (disables firewall) or pre-configure any MCP servers you need in `~/.claude/settings.json`.

## Puppeteer / Headless Chrome

This image includes Google Chrome Stable and sets `PUPPETEER_EXECUTABLE_PATH` so Puppeteer uses it automatically. However, you **must** pass `--no-sandbox` in your Puppeteer launch args when running inside Docker:

```js
const browser = await puppeteer.launch({
  args: ['--no-sandbox'],
});
```

This is required because Docker containers lack the Linux namespace privileges that Chrome's sandbox needs. See [Puppeteer troubleshooting docs](https://pptr.dev/troubleshooting#setting-up-chrome-linux-sandbox) for details.
