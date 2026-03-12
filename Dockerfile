# Claude Code base: same as Anthropic's devcontainer image
FROM node:20

# Optional: time zone support
ARG TZ
ENV TZ="$TZ"

# Claude Code version (can pin to a specific version later)
ARG CLAUDE_CODE_VERSION=latest

# Base tools + firewall bits + Python + curl/wget
RUN set -eux; \
    # Use HTTPS for Debian mirrors
    sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list || true; \
    sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources || true; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    nano \
    vim \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Install Google Chrome Stable for Puppeteer
# This allows running headless Chrome via Puppeteer inside the container.
# See: https://stackoverflow.com/a/78466930/130164
RUN curl --location --silent https://dl-ssl.google.com/linux/linux_signing_key.pub \
        -o /usr/share/keyrings/google-chrome.pub \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.pub] https://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Skip bundled Chromium download - we use the system-installed Chrome instead
# Puppeteer will use PUPPETEER_EXECUTABLE_PATH automatically at launch time
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

# Let the node user own a global npm directory
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share/npm-global

ARG USERNAME=node

# Persist shell history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory

# Mark as devcontainer-style image (some tools look at this)
ENV DEVCONTAINER=true

# Workspace and Claude config dir
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# Install git-delta (nice diff viewer) - same as Anthropic's devcontainer
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Switch to non-root for normal work
USER node

# Node/npm config and defaults
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV SHELL=/bin/zsh
ENV EDITOR=nano
ENV VISUAL=nano

# Install zsh setup
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Back to root to install firewall script + sudo rule and uv
USER root

# Install uv globally in /usr/local/bin (no shell profile hacks)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh

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

# Default back to non-root user for work
USER node

COPY start_firewall.sh /usr/local/bin/start_firewall.sh
ENTRYPOINT ["/usr/local/bin/start_firewall.sh"]
CMD ["zsh"]
