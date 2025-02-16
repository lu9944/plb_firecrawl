# worker.Dockerfile
FROM node:lts AS base
# 设置 CNPM_HOME 环境变量，不过 cnpm 通常不需要特殊的 HOME 路径设置，这里仅为形式上统一
ENV CNPM_HOME="/cnpm"
# 将 CNPM_HOME 添加到系统 PATH 中，同样 cnpm 一般不需要此步骤，为形式保留
ENV PATH="$CNPM_HOME:$PATH"
LABEL fly_launch_runtime="Node.js"
# 安装 cnpm
RUN npm install -g cnpm --registry=https://registry.npmmirror.com

COPY . /app
WORKDIR /app

FROM base AS prod-deps
# 安装生产依赖
RUN cnpm install --prod --frozen-lockfile

FROM base AS build
# 安装所有依赖
RUN cnpm install --frozen-lockfile
# 执行构建命令
RUN cnpm run build

FROM base
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y chromium chromium-sandbox && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app /app

EXPOSE 8080
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium"
CMD [ "cnpm", "run", "worker:production" ]
