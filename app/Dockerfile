# Pinned by digest for reproducible builds; bump tag and digest together.
ARG NODE_IMAGE=public.ecr.aws/docker/library/node:24-alpine@sha256:116b800c3754b440ee0aa3ed2f20f5bf3d99a554bfd9adeea09ea8017f6e85f5

FROM ${NODE_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# Built only with --target test; CI runs lint and unit tests here so no Node install is needed on the runner.
FROM ${NODE_IMAGE} AS test
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run lint && npm run format:check && npm test

FROM ${NODE_IMAGE} AS runtime
ARG APP_COMMIT=local
ENV NODE_ENV=production \
    APP_COMMIT=${APP_COMMIT} \
    PORT=3000
WORKDIR /app
# Package managers are not needed at runtime and are the main source of base image CVEs.
RUN apk upgrade --no-cache \
    && rm -rf /usr/local/lib/node_modules /usr/local/bin/npm /usr/local/bin/npx \
       /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn-*
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:'+process.env.PORT+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
CMD ["node", "src/server.js"]
