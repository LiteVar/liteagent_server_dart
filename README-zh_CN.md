# LiteAgent core Dart Server 

[English](README.md) · 中文

大模型`AI Agent`的多会话HTTP/WebSocket服务

## 功能

- 支持纯文本的agent，无需JSON Spec
- 支持 [OpenAPI](https://github.com/djbird2046/openapi_dart)/[OpenRPC](https://github.com/djbird2046/openrpc_dart)/[OpenModbus](https://github.com/LiteVar/openmodbus_dart)/[OpenTool](https://github.com/LiteVar/opentool_dart) 等`OpenSpec`的JSON文本描述
- 支持 大模型的Function calling 到`HTTP API`/`json-rpc 2.0 over HTTP`/`Modbus`以及自定义工具的执行
- [Dart版本Lite Agent core](https://github.com/LiteVar/lite_agent_core_dart)的HTTP Server封装
- [Lite Agent Core的AgentService](https://github.com/LiteVar/lite_agent_core_dart/blob/master/lib/src/service/service.dart)（包括DTO）基础上，增加Controller、Router等，封装成HTTP/WS API

## 使用

### 1. 准备

1. 准备OpenSpec的JSON文件，可参照 `/example/json/open*/*.json` 作为样例，并且文件描述的接口真实可调用
2. 启动你的工具服务，对应的服务描述即为步骤1的JSON文件描述
3. 如果需要运行`/example/single_agent_example.dart`，在 `example` 文件夹增加 `.env` 文件，并且`.env`文件需要增加如下内容：
     ```properties
     baseUrl = https://xxx.xxx.com         # 大模型接口的BaseURL
     apiKey = sk-xxxxxxxxxxxxxxxxxxxx      # 大模型接口的ApiKey
     ```

### 2. 开发环境运行server
1. `debug`或者`run`模式运行`/bin/server.dart`文件的`main()`

### 3. API文档

参考[API文档](API-zh_CN.md)

#### 3.1 典型的交互例子

`/example/single_agent_example.dart`的运行结果：

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

## 持久化

- 本服务使用 SQLite（Drift）持久化 Agent 定义、Session 元数据、Capability 快照和完整消息历史。
- core 的 `timeoutSeconds` 只负责淘汰内存中的运行态 Session，不会删除数据库会话。旧 sessionId 再次调用 `/chat` 或 `/session/subscribe` 时，server 会按需恢复已完成任务的上下文。
- 未完成任务、半截工具调用和流式 chunk 不会注入恢复上下文；它们仍可作为历史记录查询。
- `/history` 和 `/session/list` 直接读取数据库，因此不受 core 内存 Session 是否存在影响。
- `/clear` 会同时清除运行态 Session、持久化 Session 和对应消息。
- 数据库文件路径优先使用环境变量 `DB_PATH`，否则读取 `bin/config.json` 的 `server.dbPath`，并相对于可执行目录解析：
  - 源码运行：`${PROJECT_ROOT}/bin/<dbPath>`
  - 编译二进制：`<binary_dir>/<dbPath>`
- 数据库 schema v2 会自动迁移原有 Agent 和旧消息表。

可通过持久化恢复示例验证 Server 重启后的连续对话：

```bash
# 首次创建会话并完成第一轮对话
dart run example/persistent_session_example.dart create

# 重启 Server，但不要删除 agent.db，然后继续同一个会话
dart run example/persistent_session_example.dart continue

# 可选：查看持久化历史或清理示例会话
dart run example/persistent_session_example.dart history
dart run example/persistent_session_example.dart clear
```

示例使用 `example/.env` 中的 `baseUrl`、`apiKey`，可选配置 `model`。它会将 sessionId 暂存到被 Git 忽略的 `example/.persistent_session.json`，`continue` 成功时输出 `PASS`。

如需不依赖外部模型的确定性验证，可先在独立终端启动本地 OpenAI mock：

```bash
dart run example/mock/llm/mock_openai_server.dart 19529
```

然后创建会话时覆盖 LLM 配置：

```bash
dart run example/persistent_session_example.dart create \
  --llm-base-url=http://127.0.0.1:19529/v1 \
  --api-key=test-key \
  --model=gpt-4o-mini
```

重启 Server 后照常运行 `continue`。mock 只会在第二轮请求确实包含第一轮消息时返回验证码，因此可直接验证恢复上下文是否已注入。

## 构建运行
1. 命令行在项目根目录运行如下命令（`dart build cli` 会同时打包 native assets）：
    ```shell
    dart build cli --target bin/server.dart --output build/cli
    ```
2. 产物位于 `build/cli/bundle`，部署时必须保留其中的 `bin/` 与 `lib/` 目录结构。
3. 将 `bin/config.json` 和 `bin/model_mapping.json` 复制到 `build/cli/bundle/bin/`。
4. 命令行运行：
    ```shell
    ./build/cli/bundle/bin/server
    ```
5. 命令行会有如下提示，即启动成功：
    ```
    INFO: 2024-06-24 14:48:05.862057: PID 34567: [HTTP] Start Server - http://0.0.0.0:9527/api
    ```
6. 运行启动后，同级目录将会出现`log`文件夹，文件夹中有`agent.log`文件，用以记录运行过程的日志

## Docker
1. Docker 构建需要把两个本地 path dependency 作为命名上下文传入：
   ```shell
    docker build \
      --build-context liteagent_core_dart=../liteagent_core_dart \
      --build-context llamadart_openai=../llamadart_openai \
      -t lite_agent_core_dart_server .
   ```
2. 运行容器：
   ```shell
   docker run -d -p 9527:9527 lite_agent_core_dart_server
   ```
   - 挂载数据库和日志目录以保留持久化数据：
   ```shell
   docker run -d -p 9527:9527 \
     -e DB_PATH=/data/agent.db \
     -v ./data:/data \
     -v ./log:/app/log \
     lite_agent_core_dart_server
   ```
