# worker.Dockerfile
FROM node:lts AS base
# 添加 corepack_npm_registry 环境变量，你可以根据需要修改其值
ENV COREPACK_NPM_REGISTRY=https://registry.npmjs.org
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
LABEL fly_launch_runtime="Node.js"
RUN corepack enable
COPY . /app
WORKDIR /app

FROM base AS prod-deps
RUN corepack prepare pnpm@latest --activate
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build
RUN corepack prepare pnpm@latest --activate
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

RUN corepack prepare pnpm@latest --activate
RUN pnpm install
RUN corepack prepare pnpm@latest --activate
RUN pnpm run build

FROM base
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y chromium chromium-sandbox && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app /app

EXPOSE 8080
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium"
CMD [ "pnpm", "run", "worker:production" ]
