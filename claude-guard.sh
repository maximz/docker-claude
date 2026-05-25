#!/usr/bin/env bash
# Hard no-MCP guard for Claude Code in this container.
#
# --dangerously-skip-permissions auto-approves tool calls, including first-party
# MCP connectors (Linear/Gmail/Asana/Google/...). Those are reached via
# api.anthropic.com -- the same channel Claude needs -- so the egress firewall
# and settings.json `deny` rules CANNOT block them. The only reliable block is
# removing MCP at the CLI. This wrapper injects that guard into every `claude`
# call so it can't be forgotten.
exec /usr/local/share/npm-global/bin/claude \
  --strict-mcp-config \
  --mcp-config '{"mcpServers":{}}' \
  "$@"
