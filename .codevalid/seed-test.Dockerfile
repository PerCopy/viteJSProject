FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        jq \
        ca-certificates \
        python3 \
        python-is-python3 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
COPY seed_test_cases ./seed_test_cases
