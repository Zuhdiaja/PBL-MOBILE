FROM oven/bun:1.4.3 AS dependencies
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
FROM dependencies AS build
ARG API_URL=http://api:5000
ARG MAX_UPLOAD_MB=512
ENV API_URL=$API_URL MAX_UPLOAD_MB=$MAX_UPLOAD_MB NEXT_TELEMETRY_DISABLED=1
COPY . .
RUN bun run build
FROM oven/bun:1.4.3-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 HOSTNAME=0.0.0.0 PORT=3000
COPY --from=build --chown=bun:bun /app/.next/standalone ./
COPY --from=build --chown=bun:bun /app/.next/static ./.next/static
COPY --from=build --chown=bun:bun /app/public ./public
USER bun
EXPOSE 3000
CMD ["bun", "server.js"]
