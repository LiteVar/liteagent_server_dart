# LiteAgent Server for Dart

[English](README.md) · 中文

基于 [`liteagent_core`](https://pub.dev/packages/liteagent_core) 的多会话 HTTP 服务，通过 SSE 推送任务事件。

## 功能

- 支持 SessionAgent、SimpleAgent 和 inline 子 Agent。
- 支持 OpenAPI、OpenRPC、OpenModbus、OpenTool、MCP stdio 和 MCP HTTP 等 OpenSpec 工具。
- 支持模型 Function Calling、任务/工具流水线策略和客户端回调工具。
- 使用 SQLite（Drift）保存 Session 配置快照和消息历史，并支持完成任务的上下文恢复。

## 使用

### 准备

需要 Dart SDK 3.13 或更高版本。安装依赖：

```shell
dart pub get
```

如需运行示例客户端，在 `example/.env` 中配置模型服务：

```properties
baseUrl = https://xxx.xxx.com
apiKey = sk-xxxxxxxxxxxxxxxxxxxx
```

需要调用工具时，请准备可访问的工具服务和对应 OpenSpec JSON；样例见 `example/json/`。

### 启动 Server

在项目根目录启动：

```shell
dart run bin/server.dart
```

默认监听 `0.0.0.0:9527`，API 前缀为 `/api/v1`，本机客户端可使用 `http://127.0.0.1:9527/api/v1`。监听地址、端口和前缀可在 `bin/config.json` 修改。

### 运行交互示例

`example/single_agent_example.dart` 展示当前 HTTP/SSE 交互：通过 `/initSession` 创建会话，再向 `/chat?sessionId=...` 发送消息并读取 SSE 事件。启动 Server 后，在项目根目录运行：

```shell
dart run example/single_agent_example.dart
```

完整接口、请求字段和 SSE 事件格式见 [API 文档](API-zh_CN.md)。

## 持久化与运行目录

- SQLite 保存 Session 元数据、Capability 快照和消息历史。SimpleAgent 会话不写入此持久化存储。
- core 的 `timeoutSeconds` 只会淘汰内存运行态，不会删除持久化会话；再次调用 `/chat` 或 `/session/subscribe` 时可恢复已完成任务的上下文。
- 未完成任务、半截工具调用和流式 chunk 不会注入恢复上下文，但仍可从历史接口查询。
- `/history`、`/history/summary`、`/history/process` 从数据库读取；当前没有 `/session/list` 接口。
- `/clear` 会清除该会话所属根会话及其 inline 子会话的运行态、持久化配置和消息。
- Server 从当前工作目录的 `bin/config.json` 读取配置。运行编译后的 CLI bundle 时，请从 bundle 根目录启动，以便找到 `bin/config.json`。
- `DB_PATH` 环境变量设置后按给定路径使用；未设置时，`server.dbPath`（默认 `agent.db`）放在用户数据目录。macOS/Linux 默认是 `$HOME/.agentos/data/agent_server/`；Windows 默认使用 `%USERPROFILE%/.agentos/data/agent_server/`，再尝试 `%LOCALAPPDATA%/AgentOS/agent_server/` 或 `%APPDATA%/AgentOS/agent_server/`；最后回退到系统临时目录。
- 日志默认放在用户日志目录，macOS/Linux 为 `$HOME/.agentos/log/agent_server/`，Windows 为 `%USERPROFILE%/.agentos/log/agent_server/`。可用 `LOG_DIR` 指定目录；文件名为 `agent_server_YYYY-MM-DD.log`。
- 数据库 schema v5 会自动迁移旧版会话和消息表。

先启动 Server，再通过持久化示例验证重启后的连续对话：

```shell
dart run example/persistent_session_example.dart create
# 保留数据库并重启 Server 后：
dart run example/persistent_session_example.dart continue
# 查看历史或清理示例会话：
dart run example/persistent_session_example.dart history
dart run example/persistent_session_example.dart clear
```

示例从 `example/.env` 读取 `baseUrl`、`apiKey`，可选读取 `model`。也可启动 `example/mock/llm/mock_openai_server.dart`，通过示例的 `--llm-base-url`、`--api-key` 和 `--model` 参数使用本地 mock。

## 构建 CLI

```shell
dart build cli --target bin/server.dart --output build/cli
cp bin/config.json build/cli/bundle/bin/config.json
cp bin/model_mapping.json build/cli/bundle/bin/model_mapping.json
cd build/cli/bundle
./bin/server
```

部署时保留 bundle 中的 `bin/` 和 `lib/` 目录。默认 API 地址为 `http://127.0.0.1:9527/api/v1`；可用 `DB_PATH` 和 `LOG_DIR` 指定数据库及日志位置。

## Docker

从项目根目录构建：

```shell
docker build -t liteagent_server_dart .
```

运行容器并持久化数据库和日志：

```shell
docker run -d -p 9527:9527 \
  -e DB_PATH=/data/agent.db \
  -e LOG_DIR=/app/log \
  -v ./data:/data \
  -v ./log:/app/log \
  liteagent_server_dart
```
