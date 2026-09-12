# IronForge backend — hardened two-stage build
FROM node:22-bookworm-slim AS build
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev
COPY schema.sql ./
COPY src ./src
COPY web ./web
COPY downloads ./downloads
COPY media ./media

FROM node:22-bookworm-slim
ENV NODE_ENV=production \
    PORT=8420 \
    BIND=0.0.0.0 \
    DATA_DIR=/data
WORKDIR /app
RUN groupadd -g 10001 ironforge && useradd -u 10001 -g ironforge -m ironforge \
  && mkdir -p /data && chown ironforge:ironforge /data
COPY --from=build --chown=ironforge:ironforge /build ./
USER ironforge
EXPOSE 8420
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD node -e "fetch('http://127.0.0.1:8420/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/index.js"]
