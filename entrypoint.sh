#!/bin/sh
# entrypoint.sh — self-healing container start for the PicoClaw agent.
#
# Runs the Supabase workspace restore (bootstrap.sh), then starts the
# launcher exactly as the stock sipeed/picoclaw image does.
# FAIL-OPEN: a bootstrap failure must never stop the launcher.
set +e

if [ -f /usr/local/bin/bootstrap.sh ]; then
  sh /usr/local/bin/bootstrap.sh || true
fi

exec picoclaw-launcher -console -public -no-browser
