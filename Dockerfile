# Custom PicoClaw launcher image with a self-healing entrypoint.
# FROM the stock image; the entrypoint restores the agent workspace from
# Supabase (bootstrap.sh) and then starts the launcher exactly as before.
FROM docker.io/sipeed/picoclaw:launcher
# python3 is required by tools/markdown_utils.py and tools/edit_telegram.py
# (the escaping-fix send/edit tools). Install at build time so it survives
# container restarts — apk installs at boot would not.
RUN apk add --no-cache python3
COPY bootstrap.sh /usr/local/bin/bootstrap.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/bootstrap.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
