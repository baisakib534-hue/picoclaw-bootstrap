# Custom PicoClaw launcher image with a self-healing entrypoint.
# FROM the stock image; the entrypoint restores the agent workspace from
# Supabase (bootstrap.sh) and then starts the launcher exactly as before.
FROM docker.io/sipeed/picoclaw:launcher
COPY bootstrap.sh /usr/local/bin/bootstrap.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/bootstrap.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
