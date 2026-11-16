# picoclaw-bootstrap

Self-healing boot for the PicoClaw agent on Render. The PicoClaw service runs on a free Render plan with no persistent disk, so every container restart wipes the agent workspace. This repo makes the service restore itself at boot — no manual restore step.

## How it works

- `bootstrap.sh` — POSIX sh, fail-open. At container start it installs `curl` / `gcompat` / `nodejs` if missing, pulls every row of the Supabase `agent_files` table using `$SUPABASE_URL` + `$SUPABASE_SERVICE_KEY` from the environment (never hardcoded, never printed), and writes the workspace files (SOUL, skills, tools, configs, crons, state) to `$HOME/.picoclaw/workspace`. On any error it still exits 0 so the launcher starts.
- `entrypoint.sh` — runs `bootstrap.sh`, then starts the launcher exactly as the stock image does (`picoclaw-launcher -console -public -no-browser`).
- `Dockerfile` — builds on the stock image (`docker.io/sipeed/picoclaw:launcher`), copies in `bootstrap.sh` and `entrypoint.sh`, and sets the entrypoint. No start-command trickery is needed: Render's Docker Command cannot chain shell commands — it execs the first word directly, with no shell, so `sh -c "..."` wrappers and `;` chains both fail there.
- `.github/workflows/docker.yml` — on every push to `main` that touches these files, builds the image and pushes it to GHCR as `ghcr.io/baisakib534-hue/picoclaw-bootstrap:latest` (public).

## Render setup

- Service: `picoclaw` (srv-dbsr2nu1egvs73ekp660), image `ghcr.io/baisakib534-hue/picoclaw-bootstrap:latest`, Docker Command empty (the image entrypoint runs).
- Environment variables (persist across restarts): `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `BOOTSTRAP_URL` (raw URL of this repo's `bootstrap.sh`), `TELEGRAM_BOT_TOKEN`.
- Deploy logs show `bootstrap: wrote 29 files to /root/.picoclaw/workspace` then `bootstrap: restore complete` when the restore runs.

## What does NOT survive a redeploy (known limits)

- The dashboard password (stored in `.security.yml`, outside the workspace; the launcher has no password env var). Re-set it on `/launcher-setup` after a redeploy.
- The launcher model config (stored in `/root/.picoclaw/config.json`, outside the workspace). Re-add the default model on the Models page after a redeploy.
- The agent chat history. The workspace (SOUL, skills, tools, configs, crons, state) DOES survive — that is what this repo restores.

## Revert

To go back to the stock image: in the Render dashboard, Settings → Image → Update Source → set the Image URL to `docker.io/sipeed/picoclaw:launcher` and leave the Docker Command empty. The service then runs the stock image with no bootstrap.
