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

- 本服务使用 SQLite（Drift）持久化代理数据。
- 数据库文件路径来自 `bin/config.json` 的 `server.dbPath`，并相对于可执行目录解析：
  - 源码运行：`${PROJECT_ROOT}/bin/<dbPath>`
  - 编译二进制：`<binary_dir>/<dbPath>`
- 运行时会话状态在内存中，重启会丢失。

## 构建运行
1. 命令行在项目根目录运行如下命令：
    ```shell
    dart compile exe bin/server.dart -o build/lite_agent_core_dart_server
    ```
2. 在build文件夹下，有`lite_agent_core_dart_server`文件
3. 把项目根目录的`config`文件夹（带有`config.json`文件）复制到`lite_agent_core_dart_server`文件同一目录
4. 命令行运行，例如：
    ```shell
    ./lite_agent_core_dart_server
    ```
5. 命令行会有如下提示，即启动成功：
    ```
    INFO: 2024-06-24 14:48:05.862057: PID 34567: [HTTP] Start Server - http://0.0.0.0:9527/api
    ```
6. 运行启动后，同级目录将会出现`log`文件夹，文件夹中有`agent.log`文件，用以记录运行过程的日志

## Docker
1. 构建镜像，`cd`到项目根目录，并运行：
   ```shell
    docker build -t lite_agent_core_dart_server .
   ```
2. 运行容器：
   ```shell
   docker run -d -p 9527:9527 lite_agent_core_dart_server
   ```
   - 或挂载config和log文件，方便本地设置config和查看log
   ```shell
   docker run -d -p 9527:9527 -v ./log:/app/log -v ./config:/app/config  lite_agent_core_dart_server
   ```
