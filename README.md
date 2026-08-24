
# LiteAgent core Dart Server

English · [中文](README-zh_CN.md)

LLM `AI Agent` multi session HTTP/WebSocket service

## Feature

- Support pure text agent without JSON Spec.
- Support  [OpenAPI](https://github.com/djbird2046/openapi_dart)/[OpenRPC](https://github.com/djbird2046/openrpc_dart)/[OpenModbus](https://github.com/LiteVar/openmodbus_dart)/[OpenTool](https://github.com/LiteVar/opentool_dart) JSON Spec.
- Support LLM Function calling to `HTTP API`/`json-rpc 2.0 over HTTP`/`Modbus` and more custom tools.
- HTTP Server wrapper [Lite Agent core Dart](https://github.com/LiteVar/lite_agent_core_dart) 
- Base on [Lite Agent Core AgentService](https://github.com/LiteVar/lite_agent_core_dart/blob/master/lib/src/service/service.dart)(DTO included), add Controller、Router, wrapper to HTTP/WS API.

## Usage

### 1. Prepare

1. Some OpenSpec json file, according to `/example/json/open*/*.json`, which is callable.
2. Run your tool server, which is described in json file.
3. Add `.env` file in the `example` folder, and add below content in the `.env` file：
     ```properties
     baseUrl = https://xxx.xxx.com         # LLM API BaseURL
     apiKey = sk-xxxxxxxxxxxxxxxxxxxx      # LLM API ApiKey
     ```

### 2. Develop run server
1. `debug` or `run` mode run `/bin/server.dart` file `main()`

### 3. API Docs

See [API Docs](API.md)

#### 3.1 Typical Interaction

`/example/single_agent_example.dart` result：

```
[capabilityDto] {llmConfig: Instance of 'LLMConfigDto', systemPrompt: A storage management tool that knows how to add, delete, modify, and query my texts., openSpecList: [Instance of 'OpenSpecDto'], timeoutSeconds: 20, taskPipelineStrategy: parallel, toolPipelineStrategy: null}
[initChat->RES] {id: 2ed1687b-2d33-47ad-9875-fa83c7e7fb81}
[sessionDto] {id: 2ed1687b-2d33-47ad-9875-fa83c7e7fb81}
[webSocket] Instance of '_WebSocketImpl'
[prompt] Find the text with ID 0.
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 🔗CLIENT: [taskStatus] {"status":"start","taskId":"1aaa0560-876c-410c-a5b1-53cba70b4cab"}
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🖥SYSTEM -> 🤖AGENT: [text] 
A storage management tool that knows how to add, delete, modify, and query my texts.
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 👤USER -> 🤖AGENT: [contentList] [{"type":"text","message":"Find the text with ID 0."}]
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 💡LLM: [contentList] [{"type":"text","message":"Find the text with ID 0."}]
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 💡LLM -> 🤖AGENT: [functionCallList] [{"id":"call_vGlzIzILnlJ07yCL6UPWbJCL","name":"POST-read","parameters":{"id":0}}]
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 🔧TOOL: [functionCallList] [{"id":"call_vGlzIzILnlJ07yCL6UPWbJCL","name":"POST-read","parameters":{"id":0}}]
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 🔗CLIENT: [taskStatus] {"status":"toolsStart","taskId":"1aaa0560-876c-410c-a5b1-53cba70b4cab","description":{"functionCallIdList":["call_vGlzIzILnlJ07yCL6UPWbJCL"]}}
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🔧TOOL -> 🤖AGENT: [toolReturn] {"id":"call_vGlzIzILnlJ07yCL6UPWbJCL","result":{"statusCode":200,"body":"{\"text\":\"Hello\"}"}}
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 💡LLM: [toolReturn] {"id":"call_vGlzIzILnlJ07yCL6UPWbJCL","result":{"statusCode":200,"body":"{\"text\":\"Hello\"}"}}
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🔧TOOL -> 🤖AGENT: [taskStatus] {"status":"toolsDone","taskId":"1aaa0560-876c-410c-a5b1-53cba70b4cab","description":{"functionCallIdList":["call_vGlzIzILnlJ07yCL6UPWbJCL"]}}
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 🔗CLIENT: [taskStatus] {"status":"toolsDone","taskId":"1aaa0560-876c-410c-a5b1-53cba70b4cab","description":{"functionCallIdList":["call_vGlzIzILnlJ07yCL6UPWbJCL"]}}
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 💡LLM -> 🤖AGENT: [text] The text with ID 0 is "Hello".
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 👤USER: [text] The text with ID 0 is "Hello".
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 🔗CLIENT: [taskStatus] {"status":"done","taskId":"1aaa0560-876c-410c-a5b1-53cba70b4cab"}
[ping]
[pong]
#2ed1687b-2d33-47ad-9875-fa83c7e7fb81::1aaa0560-876c-410c-a5b1-53cba70b4cab# 🤖AGENT -> 🔗CLIENT: [taskStatus] {"status":"stop","taskId":""}
[stopSessionDto] {id: 2ed1687b-2d33-47ad-9875-fa83c7e7fb81}
[clearSessionDto] {id: 2ed1687b-2d33-47ad-9875-fa83c7e7fb81}
WebSocket connection closed
```

## Persistence

- This server uses SQLite (via Drift) to persist session metadata, capability snapshots, and complete message history.
- Core's `timeoutSeconds` only evicts the in-memory runtime session; it does not delete the persisted conversation. A later `/chat` or `/session/subscribe` request with the same session ID lazily restores completed-task context.
- Incomplete tasks, partial tool calls, and stream chunks are not injected into restored context, although persisted events remain available as history.
- `/history` reads directly from SQLite and does not depend on an in-memory core session.
- `/clear` removes both runtime state and the persisted session/messages.
- The database path uses `DB_PATH` when set; otherwise it uses `bin/config.json` → `server.dbPath`, resolved under the executable directory:
  - Running from source: `${PROJECT_ROOT}/bin/<dbPath>`
  - Running compiled binary: `<binary_dir>/<dbPath>`
- Database schema v5 automatically migrates existing session and legacy message tables, including removing the old session `agent_id` field.

Use the persistence example to verify conversation continuity across a server restart:

```bash
# Create a session and finish the first turn.
dart run example/persistent_session_example.dart create

# Restart the server without deleting agent.db, then continue the same session.
dart run example/persistent_session_example.dart continue

# Optional: inspect persisted history or remove the example session.
dart run example/persistent_session_example.dart history
dart run example/persistent_session_example.dart clear
```

The example reads `baseUrl` and `apiKey` from `example/.env`; `model` is optional. It stores the session ID in the Git-ignored `example/.persistent_session.json` and prints `PASS` when the continuation succeeds.

For a deterministic test without an external model, start the local OpenAI mock in a separate terminal:

```bash
dart run example/mock/llm/mock_openai_server.dart 19529
```

Then override the LLM settings when creating the session:

```bash
dart run example/persistent_session_example.dart create \
  --llm-base-url=http://127.0.0.1:19529/v1 \
  --api-key=test-key \
  --model=gpt-4o-mini
```

Restart the server and run `continue` normally. The mock returns the verification token only when the second request actually contains the first turn, directly validating restored-context injection.

## Build and Run
1. Build a CLI bundle including native assets:
    ```shell
    dart build cli --target bin/server.dart --output build/cli
    ```
2. The output is under `build/cli/bundle`; keep its `bin/` and `lib/` directory layout together when deploying.
3. Copy `bin/config.json` and `bin/model_mapping.json` to `build/cli/bundle/bin/`.
4. Run:
    ```shell
    ./build/cli/bundle/bin/server
    ```
5. Terminal will show:
    ```
    INFO: 2024-06-24 14:48:05.862057: PID 34567: [HTTP] Start Server - http://0.0.0.0:9527/api
    ```
6. After server running, will create `log` folder and `agent.log` file in the folder, to record server running logs.

## Docker
1. Pass both local path dependencies as named Docker build contexts:
   ```shell
    docker build \
      --build-context liteagent_core_dart=../liteagent_core_dart \
      --build-context llamadart_openai=../llamadart_openai \
      -t lite_agent_core_dart_server .
   ```
2. Run container:
   ```shell
   docker run -d -p 9527:9527 lite_agent_core_dart_server
   ```
   - Mount database and log directories to retain persistent data:
   ```shell
   docker run -d -p 9527:9527 \
     -e DB_PATH=/data/agent.db \
     -v ./data:/data \
     -v ./log:/app/log \
     lite_agent_core_dart_server
   ```
