
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

```
[/init request] {llmConfig: ..., systemPrompt:..., openSpecList: [...]}
[/init response SessionId] {id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a}
[After /chat connect ws, send userTaskDto] {taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a, contentList: [{type: text, message: Get some tool status}]}
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TASK_START]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 👤USER -> 🤖AGENT: [text] Get some tool status
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 💡LLM: [text] Get some tool status
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 💡LLM -> 🤖AGENT: [functionCallList] [{"id":"call_73xLVZDe70QgLHsURgY5BNT0","name":"SomeFunction","parameters":{"operation":"result"}}]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔧TOOL: [functionCallList] [{"id":"call_73xLVZDe70QgLHsURgY5BNT0","name":"SomeFunction","parameters":{"operation":"result"}}]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TOOLS_START]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🔧TOOL -> 🤖AGENT: [toolReturn] {"id":"call_73xLVZDe70QgLHsURgY5BNT0","result":{"statusCode":200,"body":"{\"code\":200,\"message\":\"FAIL\"}"}}
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 💡LLM: [toolReturn] {"id":"call_73xLVZDe70QgLHsURgY5BNT0","result":{"statusCode":200,"body":"{\"code\":200,\"message\":\"FAIL\"}"}}
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🔧TOOL -> 🤖AGENT: [text] [TOOLS_DONE]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TOOLS_DONE]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 💡LLM -> 🤖AGENT: [text] Tool status: FAIL.
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 👤USER: [text] Tool status: FAIL.
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TASK_DONE]
[ws push] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TASK_STOP]
[/stop request] {id: eccdacc8-a1a8-463f-b0af-7aebc278c842}
[/clear request] {id: eccdacc8-a1a8-463f-b0af-7aebc278c842}
[ws close] WebSocket connection closed
```

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