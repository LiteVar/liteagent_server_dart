
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

- This server uses SQLite (via Drift) for agent storage.
- The database file path is `bin/config.json` → `server.dbPath`, and it is resolved under the executable directory:
  - Running from source: `${PROJECT_ROOT}/bin/<dbPath>`
  - Running compiled binary: `<binary_dir>/<dbPath>`
- Runtime session state is in-memory and will be lost on restart.

## Build and Run
1. Build in shell script:
    ```shell
    dart compile exe bin/server.dart -o build/lite_agent_core_dart_server
    ```
2. Then the `lite_agent_core_dart_server` file will be in `build` folder
3. Copy `config`(within `config.json`) folder to `lite_agent_core_dart_server` same folder
4. Run in shell script:
    ```shell
    ./lite_agent_core_dart_server
    ```
5. Terminal will show:
    ```
    INFO: 2024-06-24 14:48:05.862057: PID 34567: [HTTP] Start Server - http://0.0.0.0:9527/api
    ```
6. After server running, will create `log` folder and `agent.log` file in the folder, to record server running logs.

## Docker
1. Build image, `cd`to project root directory, then run: 
   ```shell
    docker build -t lite_agent_core_dart_server .
   ```
2. Run container:
   ```shell
   docker run -d -p 9527:9527 lite_agent_core_dart_server
   ```
   - Or mount config and log folder to update config and get log info
   ```shell
   docker run -d -p 9527:9527 -v ./log:/app/log -v ./config:/app/config  lite_agent_core_dart_server
   ```
