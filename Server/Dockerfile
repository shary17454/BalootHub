FROM node:24-bullseye-slim AS node
FROM swift:6.0.3-jammy AS builder
WORKDIR /app
COPY Packages/BalootEngine ./Packages/BalootEngine
COPY Server/EngineWorker ./Server/EngineWorker
RUN swift build -c release --package-path Server/EngineWorker

FROM swift:6.0.3-jammy-slim
WORKDIR /app
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=builder /app/Server/EngineWorker/.build/release/BalootWorker /app/BalootWorker
COPY Server/server.mjs /app/Server/server.mjs
ENV PORT=8080 BALOOT_ENGINE_WORKER=/app/BalootWorker
RUN useradd --create-home --uid 10001 baloot
USER baloot
EXPOSE 8080
CMD ["node","Server/server.mjs"]
