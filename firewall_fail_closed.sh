#!/usr/bin/env bash
# Applied when init-firewall.sh fails: better no egress than open egress.
set -u
iptables -F OUTPUT 2>/dev/null || true
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-port-unreachable
ip6tables -F OUTPUT 2>/dev/null || true
ip6tables -A OUTPUT -o lo -j ACCEPT 2>/dev/null || true
ip6tables -A OUTPUT -j REJECT 2>/dev/null || true
echo "[fail-closed] egress locked down (loopback + established only)" >&2
