FROM node:24-slim@sha256:c86ecead9e55a5210ac1727de38a4ca840bf03dcaf34dc9749addbf383b1920c AS base
ENV PNPM_HOME=/pnpm
ENV PATH=/pnpm/bin:$PATH
ENV NEXT_TELEMETRY_DISABLED=1
RUN corepack enable && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates openssl curl \
    && rm -rf /var/lib/apt/lists/*

FROM base AS pruner
WORKDIR /src
COPY . .
RUN pnpm dlx turbo@2.11.10 prune --scope=@rallly/web --docker

FROM base AS dependencies
WORKDIR /app
COPY --from=pruner /src/out/json/ .
COPY --from=pruner /src/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN --mount=type=cache,id=rallly-pnpm,target=/pnpm/store pnpm install --frozen-lockfile

FROM dependencies AS builder
COPY --from=pruner /src/out/full/ .
COPY --from=pruner /src/turbo.json ./turbo.json
ARG APP_VERSION=4.16.4-community
ENV NEXT_PUBLIC_APP_VERSION=$APP_VERSION
ENV NEXT_PUBLIC_SELF_HOSTED=true
ENV NODE_OPTIONS=--max-old-space-size=4096
RUN pnpm db:generate
RUN SKIP_ENV_VALIDATION=1 pnpm build

FROM base AS runner
WORKDIR /app
RUN npm install --omit=dev prisma@7.8.0 \
    && groupadd --system nodejs \
    && useradd --system --gid nodejs --home-dir /app --shell /usr/sbin/nologin nextjs
COPY --from=pruner /src/packages/database/prisma ./prisma
COPY --from=pruner /src/packages/database/prisma.config.ts ./prisma.config.ts
COPY --from=pruner /src/deploy/nas/start.sh ./start.sh
COPY --chown=nextjs:nodejs --from=builder /app/apps/web/.next/standalone ./
COPY --chown=nextjs:nodejs --from=builder /app/apps/web/.next/static ./apps/web/.next/static
COPY --chown=nextjs:nodejs --from=builder /app/apps/web/public ./apps/web/public
RUN chmod 755 start.sh
USER nextjs
ENV NODE_ENV=production
ENV NEXT_PUBLIC_SELF_HOSTED=true
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
ENV LOG_LEVEL=warn
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=12 CMD curl --fail --noproxy '*' http://127.0.0.1:3000/api/status || exit 1
CMD ["./start.sh"]
