#!/bin/bash
# botmux on Railway. Never exits on a bad setting: botmux's dashboard, or a notice
# page when even that can't start, keeps answering the healthcheck on $PORT.
set -u
export HOME=/data
cd "$HOME"

# botmux refuses to run when its home is group- or other-writable (it holds the
# dashboard secret), and a fresh Railway volume can be.
chmod 700 "$HOME"

node /opt/botmux-railway/configure.mjs || echo "[railway] configure step failed; starting botmux with the files as they are"

# OPENAI_API_KEY set: save it as Codex's login on every boot, so a changed key takes
# effect. A ChatGPT login done in a shell (tokens in auth.json) wins and is kept.
if [ -n "${OPENAI_API_KEY:-}" ] && ! grep -q '"tokens"' "$HOME/.codex/auth.json" 2>/dev/null; then
  printenv OPENAI_API_KEY | codex login --with-api-key >/dev/null 2>&1 \
    && echo "[railway] codex signed in with OPENAI_API_KEY" || echo "[railway] codex login with OPENAI_API_KEY failed"
fi

# The app secret and dashboard token are in botmux's own files now; keep them out
# of the environment every agent session inherits.
unset FEISHU_APP_SECRET DASHBOARD_TOKEN

# Shells opened with `railway ssh` start in /data with the same settings.
cat > /etc/profile.d/botmux-railway.sh <<'SH'
export HOME=/data DISABLE_AUTOUPDATER=1 OPENCODE_DISABLE_AUTOUPDATE=1
cd /data 2>/dev/null || true
SH

# Railway counts the kernel's cache of files this container has read as the
# service's memory, and with no memory pressure it is never freed. Drop it for
# the volume and /tmp every 15 minutes.
( while sleep 900; do nice -n 19 drop-file-cache /data /tmp || true; done ) &

stop() { botmux stop >/dev/null 2>&1; exit 0; }
trap stop TERM INT

notice_pid=
start_fleet() {
  local out=/tmp/botmux-start.log
  if [ -n "$notice_pid" ]; then kill "$notice_pid" 2>/dev/null; wait "$notice_pid" 2>/dev/null; notice_pid=; fi
  # botmux prints login links with the dashboard token in them; neither the logs
  # nor the notice page are a place for it.
  botmux start >"$out" 2>&1; local rc=$?
  sed -i -E 's/([?&]t=)[A-Za-z0-9._~-]+/\1<DASHBOARD_TOKEN>/g' "$out"
  cat "$out"
  [ "$rc" = 0 ] && return 0
  echo "[railway] botmux start failed; serving a notice page on :${PORT} and retrying in 60 s"
  node /opt/botmux-railway/notice.mjs "$out" & notice_pid=$!
  return 1
}

until start_fleet; do sleep 60 & wait $!; done
echo "[railway] botmux $(botmux --version 2>/dev/null) is up: dashboard on :${PORT}"

# botmux's own logs (supervisor, dashboard, one daemon per bot) go to Railway's log view.
mkdir -p "$HOME/.botmux/logs"
logs= tail_pid=
follow_logs() {
  local now; now=$(ls "$HOME"/.botmux/logs/*.log 2>/dev/null | tr '\n' ' ')
  [ "$now" = "$logs" ] && return
  [ -n "$tail_pid" ] && kill "$tail_pid" 2>/dev/null
  logs=$now
  [ -n "$logs" ] && { tail -q -n 0 -F $logs & tail_pid=$!; }
}

# `botmux watchdog` restarts anything that died and does nothing after an
# explicit `botmux stop`, so a stop from a shell sticks until the next deploy.
while true; do
  follow_logs
  sleep 30 & wait $!
  botmux watchdog >/dev/null 2>&1 || true
done
