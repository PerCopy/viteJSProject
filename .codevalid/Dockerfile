FROM node:22-bookworm-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        bash \
        netcat-openbsd \
        jq \
        python3 \
        python-is-python3 \
    && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm i --ignore-scripts; fi
COPY . .
ENV PORT=6713
EXPOSE 6713
COPY .codevalid/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "backend/server.js"]
