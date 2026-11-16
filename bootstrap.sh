#!/bin/sh
# bootstrap.sh — FAIL-OPEN workspace restore from Supabase REST.
#
# On ANY error, still exits 0 so the stock launcher starts.
# Requires $SUPABASE_URL + $SUPABASE_SERVICE_KEY in the environment.
# Never prints keys. Writes all agent_files rows to the workspace.

set +e  # FAIL-OPEN: never abort

WORKSPACE="${1:-$HOME/.picoclaw/workspace}"

# --- 1. Ensure prerequisites ---
apk add --no-cache curl gcompat libgcc libstdc++ >/dev/null 2>&1
command -v node >/dev/null 2>&1 || apk add --no-cache nodejs >/dev/null 2>&1

# --- 2. Validate env ---
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
  echo "bootstrap: SUPABASE_URL or SUPABASE_SERVICE_KEY not set; skipping restore" >&2
  exit 0
fi

# --- 3. Pull agent_files ---
RESP=$(curl -s -w "\n%{http_code}" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  "$SUPABASE_URL/rest/v1/agent_files?select=name,content")

CODE=$(printf '%s' "$RESP" | tail -n1)
BODY=$(printf '%s' "$RESP" | sed '$d')

if [ "$CODE" != "200" ]; then
  echo "bootstrap: Supabase returned HTTP $CODE; skipping restore" >&2
  exit 0
fi

# --- 4. Write files using node ---
command -v node >/dev/null 2>&1 || { echo "bootstrap: node not available; skipping restore" >&2; exit 0; }
node -e '
const fs = require("fs");
const path = require("path");
const data = JSON.parse(process.argv[1]);
const root = process.argv[2];
let n = 0;
for (const row of data) {
  const target = path.join(root, row.name);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, row.content || "");
  n++;
}
console.log("bootstrap: wrote " + n + " files to " + root);
' "$BODY" "$WORKSPACE"

# --- 5. Restore provider + Telegram config from agent_files if present ---
# (already written above; nothing extra needed)
echo "bootstrap: restore complete"
exit 0
