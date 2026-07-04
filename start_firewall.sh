#!/usr/bin/env bash
set -e

# Try to init firewall; on failure apply deny-all egress (fail closed) instead
# of leaving the container with open egress.
if command -v sudo >/dev/null 2>&1; then
  if ! sudo /usr/local/bin/init-firewall.sh; then
    echo "ERROR: init-firewall.sh failed — applying fail-closed egress policy" >&2
    sudo /usr/local/bin/firewall-fail-closed.sh || true
  fi
else
  if ! /usr/local/bin/init-firewall.sh; then
    echo "ERROR: init-firewall.sh failed — applying fail-closed egress policy" >&2
    /usr/local/bin/firewall-fail-closed.sh || true
  fi
fi

exec "$@"
