# botmux on Railway: the Feishu/Lark daemon and dashboard, plus the coding CLIs it drives.
# upgrade: skip
FROM node:24.22.3-trixie-slim

# botmux ships one self-contained binary per platform as an npm package; the main
# `botmux` package only adds a launcher and unused JS dependencies, so the binary
# package is installed on its own.
# upgrade: npm botmux
ARG BOTMUX_VERSION=3.59.19
# upgrade: npm @anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.327
# upgrade: npm @openai/codex
ARG CODEX_VERSION=0.169.1
# OpenCode 1.x is botmux's supported `opencode` adapter (OpenCode 2 is its beta `opencode2`).
# upgrade: npm opencode-ai
ARG OPENCODE_VERSION=1.19.6

# Everything stateful lives on the one Railway volume at /data, used as HOME:
# botmux's ~/.botmux (bots, sessions, schedules, dashboard token), the CLIs'
# logins and histories (~/.claude, ~/.codex, ~/.local/share/opencode) and the
# projects the agents work in (~/projects).
ENV HOME=/data \
    LANG=C.UTF-8 \
    PORT=7891 \
    DISABLE_AUTOUPDATER=1 \
    OPENCODE_DISABLE_AUTOUPDATE=1

# tmux is botmux's session backend; the fonts are what it renders terminal
# screenshots for Lark cards with (otherwise it downloads them on first boot).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client tmux tini procps less nano jq ripgrep \
      unzip python3 python3-venv fonts-noto-cjk fonts-dejavu-core fonts-noto-color-emoji \
  && npm install -g --no-fund --no-audit \
       "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" "@openai/codex@${CODEX_VERSION}" \
       "opencode-ai@${OPENCODE_VERSION}" \
  && mkdir -p /tmp/bmx && cd /tmp/bmx \
  && npm pack --silent "botmux-linux-x64@${BOTMUX_VERSION}" \
  && tar xzf botmux-linux-x64-*.tgz \
  && install -m 755 package/botmux /usr/local/bin/botmux \
  && cd / && rm -rf /tmp/bmx /root/.npm \
  && botmux --version && claude --version && codex --version && opencode --version \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY configure.mjs notice.mjs /opt/botmux-railway/
COPY drop-file-cache /usr/local/bin/drop-file-cache
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/drop-file-cache

EXPOSE 7891
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
