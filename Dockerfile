FROM ghcr.io/actions/actions-runner:2.319.1
# for latest release, see https://github.com/actions/runner/releases

USER root

# install curl and jq
RUN apt-get update && apt-get install -y curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY scripts/entrypoint.sh ./entrypoint.sh
COPY scripts/app-token.sh ./app-token.sh
COPY scripts/token.sh ./token.sh
COPY scripts/jit-config.sh ./jit-config.sh
RUN chmod +x ./entrypoint.sh && \
    chmod +x ./app-token.sh && \
    chmod +x ./token.sh && \
    chmod +x ./jit-config.sh && \
    mkdir /_work && \
    chown runner:docker \
        ./entrypoint.sh \
        ./app-token.sh \
        ./token.sh \
        ./jit-config.sh \
        /_work

USER runner

ENTRYPOINT ["./entrypoint.sh"]
