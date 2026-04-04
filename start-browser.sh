#!/bin/bash
# Start Chromium for agent-browser CDP connection.
# agent-browser's own Chrome launch doesn't reliably pass --no-sandbox in containers,
# so we pre-launch Chromium and agent-browser connects via --cdp 9222.
#
# Usage from entrypoint:  start-browser.sh
# Usage from CLI/prompt:  agent-browser --cdp 9222 open <url>
#                          agent-browser --cdp 9222 snapshot -i

set -e

CDP_PORT="${BROWSER_CDP_PORT:-9222}"

# Check if already running
if curl -s "http://localhost:${CDP_PORT}/json/version" >/dev/null 2>&1; then
    exit 0
fi

chromium \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --headless \
    --ignore-certificate-errors \
    --remote-debugging-port="${CDP_PORT}" \
    --remote-debugging-address=127.0.0.1 \
    &>/tmp/chromium.log &

# Wait for CDP to be ready
for i in $(seq 1 30); do
    if curl -s "http://localhost:${CDP_PORT}/json/version" >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.2
done

echo "ERROR: Chromium failed to start. Log:" >&2
cat /tmp/chromium.log >&2
exit 1
