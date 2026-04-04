# cc: Firewalled Claude Code image
# Derives from cc-open and adds network firewall (egress allowlist).
FROM cc-open

USER root

# Firewall packages (not in cc-open -- only needed for firewalled containers)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Firewall script: download from pinned upstream commit, verify, and patch
ARG FIREWALL_COMMIT=53a5f3ee0703c2ab1b6d1dd18d8ab65187f9b8ad
ARG FIREWALL_SHA256=711bc435138f14778e753706c4985145bb196045830807131841057d890ecfda
RUN curl -fsSL "https://raw.githubusercontent.com/anthropics/claude-code/${FIREWALL_COMMIT}/.devcontainer/init-firewall.sh" \
      -o /usr/local/bin/init-firewall.sh && \
    echo "${FIREWALL_SHA256}  /usr/local/bin/init-firewall.sh" | sha256sum -c - && \
    # Apply local modifications: header comments + host.docker.internal support
    patch /usr/local/bin/init-firewall.sh <<'PATCH'
--- a/init-firewall.sh
+++ b/init-firewall.sh
@@ -1,4 +1,7 @@
 #!/bin/bash
+# Upstream source: https://github.com/anthropics/claude-code/blob/main/.devcontainer/init-firewall.sh
+# Local modifications: Added Docker Desktop for Mac gateway support (host.docker.internal)
+
 set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
 IFS=$'\n\t'       # Stricter word splitting

@@ -88,6 +91,16 @@
         echo "Adding $ip for $domain"
         ipset add allowed-domains "$ip"
     done < <(echo "$ips")
 done
+
+# Allow access to Docker host (host.docker.internal)
+# Required for containers to reach host-side services
+HOST_DOCKER_INTERNAL_IP=$(getent ahosts host.docker.internal 2>/dev/null | grep STREAM | awk '{print $1}' | head -1)
+if [ -n "$HOST_DOCKER_INTERNAL_IP" ]; then
+    echo "Adding host.docker.internal ($HOST_DOCKER_INTERNAL_IP)"
+    ipset add allowed-domains "$HOST_DOCKER_INTERNAL_IP"
+else
+    echo "WARNING: Could not resolve host.docker.internal"
+fi

 # Get host IP from default route
 HOST_IP=$(ip route | grep default | cut -d" " -f3)
PATCH
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

USER node

COPY start_firewall.sh /usr/local/bin/start_firewall.sh
ENTRYPOINT ["/usr/local/bin/start_firewall.sh"]
CMD ["zsh"]
