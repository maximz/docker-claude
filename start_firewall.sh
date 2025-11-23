#!/usr/bin/env bash
set -e

# Try to init firewall; if it fails, print a warning instead of killing the shell
if command -v sudo >/dev/null 2>&1; then
  sudo /usr/local/bin/init-firewall.sh || echo "WARNING: init-firewall.sh failed"
else
  /usr/local/bin/init-firewall.sh || echo "WARNING: init-firewall.sh failed"
fi

exec "$@"
