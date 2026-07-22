FROM ghcr.io/shopify/toxiproxy:2.12.0
# Add static busybox for the healthcheck HTTP probe (base image is FROM scratch — no shell).
COPY --from=busybox:1.38-musl /bin/busybox /bin/busybox
COPY toxiproxy.json /config/toxiproxy.json
