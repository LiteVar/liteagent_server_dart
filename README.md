# LiteAgent Server for Dart

English · [中文](README-zh_CN.md)

A multi-session HTTP server based on [`liteagent_core`](https://pub.dev/packages/liteagent_core), streaming task events over SSE.

## Features

- SessionAgent, SimpleAgent, and inline sub-agents.
- OpenSpec tools for OpenAPI, OpenRPC, OpenModbus, OpenTool, MCP stdio, and MCP HTTP.
- Model function calling, task/tool pipeline strategies, and client callback tools.
- SQLite (Drift) persistence for session capability snapshots and message history, with completed-task context restoration.

## Usage

### Prepare

Install dependencies:

```shell
dart pub get
```

To run the example client, configure the model service in `example/.env`:

```properties
baseUrl = https://xxx.xxx.com
apiKey = sk-xxxxxxxxxxxxxxxxxxxx
```

For tool use, prepare an accessible tool service and its OpenSpec JSON description; see `example/json/`.

### Start the server

Run from the repository root:

```shell
dart run bin/server.dart
```

The default listener is `0.0.0.0:9527` with API prefix `/api/v1`. Local clients can use `http://127.0.0.1:9527/api/v1`. Change the listener, port, and prefix in `bin/config.json`.

### Run the interaction example

`example/single_agent_example.dart` demonstrates the current HTTP/SSE flow: create a session with `/initSession`, then submit a message to `/chat?sessionId=...` and consume SSE events. Start the server, then run from the repository root:

```shell
dart run example/single_agent_example.dart
```

See the [API documentation](API.md) for request fields and SSE event formats.

## Persistence and runtime paths

- SQLite stores session metadata, capability snapshots, and message history. SimpleAgent sessions are not stored in this persistence layer.
- Core's `timeoutSeconds` evicts only the in-memory runtime session; it does not delete the persisted session. A later `/chat` or `/session/subscribe` request can restore completed-task context.
- Incomplete tasks, partial tool calls, and stream chunks are not injected into restored context, although history endpoints can still return them.
- `/history`, `/history/summary`, and `/history/process` read from the database. There is no `/session/list` route.
- `/clear` removes runtime and persisted data for the root session and its inline sub-agent sessions.
- The server reads `bin/config.json` relative to its current working directory. When deploying the compiled CLI bundle, start it from the bundle root so `bin/config.json` is found.
- When set, `DB_PATH` is used as given. Otherwise, `server.dbPath` (default `agent.db`) is placed in the user data directory. On macOS/Linux this is `$HOME/.agentos/data/agent_server/`; on Windows the default is `%USERPROFILE%/.agentos/data/agent_server/`, then `%LOCALAPPDATA%/AgentOS/agent_server/` or `%APPDATA%/AgentOS/agent_server/`; the system temp directory is the final fallback.
- Logs default to the user log directory (`$HOME/.agentos/log/agent_server/` on macOS/Linux and `%USERPROFILE%/.agentos/log/agent_server/` on Windows). Set `LOG_DIR` to override it. Log files are named `agent_server_YYYY-MM-DD.log`.
- Database schema v5 automatically migrates older session and message tables.

Start the server first, then use the persistence example to verify conversation continuity across a server restart:

```shell
dart run example/persistent_session_example.dart create
# Keep the database and restart the server, then:
dart run example/persistent_session_example.dart continue
# Inspect history or remove the example session:
dart run example/persistent_session_example.dart history
dart run example/persistent_session_example.dart clear
```

The example reads `baseUrl` and `apiKey` from `example/.env`; `model` is optional. You can also start `example/mock/llm/mock_openai_server.dart` and pass `--llm-base-url`, `--api-key`, and `--model` to use the local mock.

## Build the CLI

```shell
dart build cli --target bin/server.dart --output build/cli
cp bin/config.json build/cli/bundle/bin/config.json
cp bin/model_mapping.json build/cli/bundle/bin/model_mapping.json
cd build/cli/bundle
./bin/server
```

Keep the bundle's `bin/` and `lib/` directories together when deploying. The default API base URL is `http://127.0.0.1:9527/api/v1`; set `DB_PATH` and `LOG_DIR` to choose persistent database and log locations.

## Docker

Build from the repository root:

```shell
docker build -t liteagent_server_dart .
```

Run the container with persistent database and log directories:

```shell
docker run -d -p 9527:9527 \
  -e DB_PATH=/data/agent.db \
  -e LOG_DIR=/app/log \
  -v ./data:/data \
  -v ./log:/app/log \
  liteagent_server_dart
```
