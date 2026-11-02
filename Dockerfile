# syntax=docker/dockerfile:1.7
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root
WORKDIR /workspace

COPY . /workspace/liteagent_server_dart

WORKDIR /workspace/liteagent_server_dart
RUN dart pub get
RUN dart build cli --target bin/server.dart --output build/cli

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /workspace/liteagent_server_dart/build/cli/bundle /app
COPY --from=build /workspace/liteagent_server_dart/bin/config.json /app/bin/config.json
COPY --from=build /workspace/liteagent_server_dart/bin/model_mapping.json /app/bin/model_mapping.json

EXPOSE 9527
ENTRYPOINT ["/app/bin/server"]
