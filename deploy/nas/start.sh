#!/bin/sh
set -eu
export AUTH_URL="$NEXT_PUBLIC_BASE_URL"
npx --no-install prisma migrate deploy --config=./prisma.config.ts
exec node apps/web/server.js
