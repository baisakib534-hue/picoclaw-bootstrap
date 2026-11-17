#!/bin/sh
# entrypoint.sh — self-healing container start for the PicoClaw agent.
#
# v2 (2026-11-17): the launcher's first-run initialisation overwrites the
# bootstrap-restored SOUL.md (14,234 bytes) with its 351-byte default
# AFTER bootstrap runs. This entrypoint therefore (a) restores the
# workspace before the launcher starts (v1 behaviour) and (b) runs a
# background SOUL guard for the life of the container: whenever the
# workspace SOUL.md is missing or has shrunk to the launcher default
# (< 1000 bytes), it re-runs bootstrap.sh so the full restored SOUL
# (and the rest of the workspace file set) wins. The guard never
# touches a healthy workspace and never blocks the launcher.
# FAIL-OPEN: a bootstrap failure must never stop the launcher.
set +e

WORKSPACE="${WORKSPACE:-$HOME/.picoclaw/workspace}"
SOUL="$WORKSPACE/SOUL.md"

if [ -f /usr/local/bin/bootstrap.sh ]; then
  sh /usr/local/bin/bootstrap.sh || true
fi

picoclaw-launcher -console -public -no-browser &
LAUNCHER_PID=$!

# Background SOUL guard: fast checks while first-run init runs, then
# a once-a-minute check for the rest of the container's life. A
# re-apply is logged; a healthy SOUL is left alone.
(
  checks=0
  while kill -0 "$LAUNCHER_PID" 2>/dev/null; do
    SIZE=0
    if [ -f "$SOUL" ]; then
      SIZE=$(wc -c < "$SOUL" 2>/dev/null || echo 0)
    fi
    if [ "$SIZE" -lt 1000 ]; then
      echo "bootstrap-guard: SOUL.md is $SIZE bytes (launcher default); re-applying workspace"
      sh /usr/local/bin/bootstrap.sh || true
      echo "bootstrap-guard: re-apply complete"
    fi
    checks=$((checks + 1))
    # First 3 minutes: check every 5s (first-run init window).
    # Afterwards: check every 60s.
    if [ "$checks" -lt 36 ]; then
      sleep 5
    else
      sleep 60
    fi
  done
) &

wait $LAUNCHER_PID
