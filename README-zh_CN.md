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
3. 如果需要运行`/example/client_example.dart`，在 `example` 文件夹增加 `.env` 文件，并且`.env`文件需要增加如下内容：
     ```properties
     baseUrl = https://xxx.xxx.com         # 大模型接口的BaseURL
     apiKey = sk-xxxxxxxxxxxxxxxxxxxx      # 大模型接口的ApiKey
     ```

### 2. 开发环境运行server
1. `debug`或者`run`模式运行`/bin/server.dart`文件的`main()`

### 3. HTTP/WS API
- [HTTP API](#31-http命令)
- [WebSocket交互](#32-websocket交互)
- [典型的交互例子](#33-典型的交互例子)

#### 3.1 HTTP命令
- 用于session会话的控制指令，包括：
  - [/version](#get-version)：版本号，用于确认server在运行
  - [/init](#post-init)：初始化一个会话，server会返回一个id
  - [/init/simple](#post-initsimple): 初始化一个SimpleAgent的会话，SimpleAgent 无需websocket，通过请求[/chat/simple](#post-chatsimpleidsessionid)，直接响应LLM返回的文本消息
  - [/chat/simple](#post-chatsimpleidsessionid): 通过发送一次过的 请求-响应 获得大模型返回，无需订阅websocket消息
  - [/history](#get-historyidsessionid)：返回当前会话的所有message历史
  - [/stop](#get-stopidsessionid)：中止会话，传入一个id，正在进行的message处理完后停止，后续的message不执行
  - [/clear](#get-clearidsessionid)：清空会话，传入一个id，会清空会话的上下文和关闭websocket连接

##### BaseURL
- `http://127.0.0.1:9527/api`

##### [GET] /version
- 功能：版本号，一般用于确认server在运行
- 请求参数：无
- 返回样例：

  ```json
  {
      "version": "0.3.0"
  }
  ```

##### [POST] /init
- 功能：初始化Agent会话
- 请求参数：
  - 大模型设置：大模型的链接、key、模型名称
  - 预置提示词：角色、能力、目标描述
  - 能力细节描述：（可选）openapi、openrpc、openmodbus文档描述。其中apiKey根据实际需要可选填写
  - Session列表：（可选）对多Agent做支持。先初始化其他Agent，获得SessionId后，传入这个字段。
  - 超时时间：默认3600秒，停止交互后，超过时间则清空上下文
- 请求样例
  ```json
  {
    "llmConfig": {
      "baseUrl": "<大模型厂商的api入口，例如：https://api.openai.com/v1>",
      "apiKey": "<大模型厂商的api的Key，例如：sk-xxxxxxxxxx>",
      "model": "<厂商支持的大模型名称，例如：gpt-3.5-turbo，下方的temperature、maxTokens、topP可选传入，下方为默认值>",
      "temperature": 0,
      "maxTokens": 4096,
      "topP": 1
    },
    "systemPrompt": "<预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题>",
    "openSpecList": [
      {
        "openSpec": "<（可选）spec的json描述文本，目前支持的类型是openapi、openmodbus、openrpc>",
        "apiKey": {
          "type": "<basic或bearer二选一>",
          "apiKey": "<第三方服务的apiKey>"
        },
        "protocol": "目前支持openapi、openmodbus、jsonrpcHttp"
      },
      {
        "openSpec": "<（可选）另一段spec的json描述，可以不同类型混用>",
        "protocol": "目前支持openapi、openmodbus、jsonrpcHttp"
      }
    ],
    "sessionList": [
      {
        "id": "<Sub Agent sessionId 1>"
      },
      {
        "id": "<Sub Agent sessionId 2>"
      }
    ],
    "timeoutSeconds": 3600
  }
  ```

- 返回：
  - sessionId，用以后续对于该session的消息订阅、stop、clear操作
  - 返回样例
    ```json
    {
        "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
    }
    ```

##### [POST] /init/simple
- 功能：初始化一个SimpleAgent的会话，SimpleAgent 无需websocket，通过请求[/chat/simple](#post-chatsimpleidsessionid)，直接响应LLM返回的文本消息
- 请求参数：
  - 大模型设置：大模型的链接、key、模型名称
  - 预置提示词：角色、能力、目标描述
  - 请求样例
  ```json
  {
    "llmConfig": {
      "baseUrl": "<大模型厂商的api入口，例如：https://api.openai.com/v1>",
      "apiKey": "<大模型厂商的api的Key，例如：sk-xxxxxxxxxx>",
      "model": "<厂商支持的大模型名称，例如：gpt-3.5-turbo，下方的temperature、maxTokens、topP可选传入，下方为默认值>",
      "temperature": 0,
      "maxTokens": 4096,
      "topP": 1
    },
    "systemPrompt": "<预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题>"
  }
  ```

- 返回：
  - sessionId，用以后续对于该session发送请求消息
  - 返回样例
    ```json
    {
        "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
    }
    ```

##### [POST] /chat/simple?id=\<sessionId\>
- 功能：通过发送一次过的 请求-响应 获得大模型返回，无需订阅websocket消息
- 请求参数：
  - 请求样例
  ```json
  {
    "taskId": "可选，用于识别AgentMessage来自于哪个任务，若不设置，则系统自行生成",
    "contentList": [
      {
        "type": "text",
        "message": "给我一个随机数"
      }
    ]
  }
  ```

- 返回样例
  ```json
  {
    "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
    "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
    "from": "llm",
    "to": "agent",
    "type": "text",
    "message": "message info",
    "completions": {
      "tokenUsage": {
        "promptTokens": 100,
        "completionTokens": 522,
        "totalTokens": 622
      },
      "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
      "model": "gpt-3.5-turbo"
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```
    
##### [GET] /history?id=\<sessionId\>

- 返回：
  - agent message的list上下文，不支持SimpleAgent
  - 返回样例
  ```json
  [
    {
        "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
        "from": "system、user、agent、llm、tool，五选一",
        "to": "user、agent、llm、tool、client，五选一",
        "type": "text、imageUrl、functionCallList、toolReturn、contentList，四选一",
        "message": "<泛类型，需要根据type来解析>",
        "completions": {
            "tokenUsage": {
              "promptTokens": 100,
              "completionTokens": 522,
              "totalTokens": 622
            },
            "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
            "model": "gpt-3.5-turbo"
         },
        "createTime": "2023-06-18T15:45:30.000+0800"
    }
  ]
  ```

##### [GET] /stop?id=\<sessionId\>

- 返回：
  - sessionId，用以确认该操作对应的session，不支持SimpleAgent
  - 样例：
  ```json
  {
      "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
  }
  ```

##### [GET] /clear?id=\<sessionId\>

- 返回：
  - sessionId，用以确认该操作对应的session，不支持SimpleAgent
  - 样例：
  ```json
  {
      "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
  }
  ```

#### 3.2 WebSocket交互
- 用于session会话的消息发送和订阅

##### Endpoint
- `ws://127.0.0.1:9527/api/chat?id=<sessionId>`

##### 3.2.1 保持连接
- client(ping) -> server: 发送`"ping"`给server
- client <- server(pong): 响应`"pong"`给client

##### 3.2.2 client发送 用户消息数组 到server
- client(UserTaskDto) -> server ：包装用户的消息给server
- 样例：
```json
{
  "taskId": "可选，用于识别AgentMessage来自于哪个任务，若不设置，则系统自行生成",
  "contentList": [
    {
      "type": "text",
      "message": "帮我运行某某功能"
    }
  ]
}
```

##### 3.2.3 server回复 Agent消息 给client
- client <- server(AgentMessage) ：Agent系统持续推送消息给client
- 样例：
```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
  "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
  "from": "system、user、agent、llm、tool，五选一",
  "to": "user、agent、llm、tool、client，五选一",
  "type": "text、imageUrl、functionCallList、toolReturn, contentList，五选一",
  "message": "<泛类型，需要根据type来解析>",
  "completions": {
    "tokenUsage": {
      "promptTokens": 100,
      "completionTokens": 522,
      "totalTokens": 622
    },
    "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
    "model": "gpt-3.5-turbo"
  },
  "createTime": "2023-06-18T15:45:30.000+0800"
}
```
- `type`在不同类型下的`message`结构
  - text、imageUrl：
    - 直接就是String
    - 样例：`"功能运行结果：PASS"`
  - functionCallList：
    - 结构：
    ```json
    [
        {
            "id":"<大模型返回的function call的id>",
            "name":"<function的名称>",
            "parameters": "<大模型返回的参数map>"
        }
    ]
    ```
    - 样例：
    ```json
    [
      {
        "id":"call_z5FK2dAfU8TXzn61IJXzRl5I",
        "name":"SomeFunction",
        "parameters": {
          "operation":"result"
        }
      }
    ]
    ```
  - toolReturn：
    - 结构：
    ``` json
    {
        "id":"<llm给出的call的id>",
        "result": <JSON Map，根据不同工具的不同情况返回不一样>
    }
    ```
    - 样例：
    ``` json
    {
      "id":"call_z5FK2dAfU8TXzn61IJXzRl5I",
      "result": {
        "statusCode":200,
        "body":"{\"code\":200,\"message\":\"PASS\"}"
      }
    }
    ```
  - contentList:
    - 结构：
    ```json
    [
      {
         "type":"text、imageUrl，二选一",
         "message":"String"
      }
    ]
    ```
    - 样例：
    ```json
    [
      {
        "type":"text",
        "message":"What’s in this image?"
      },
      {
        "type":"imageUrl",
        "message":"https://www.xxx.com/xxx.jpg"
      }
    ]
    ```
- to=Client时，message有如下几个状态：
  - `"[TASK_START]"`：agent接收到user message，准备处理
  - `"[TOOLS_START]"`: 准备提交Tools执行
  - `"[TOOLS_DONE]"`: Tools执行完毕
  - `"[TASK_STOP]"`：agent接收到stop或者clear指令，停止任务
  - `"[TASK_DONE]"`：agent处理完成

#### 3.3 典型的交互例子

```
[/init请求] {llmConfig: ..., systemPrompt:..., openSpecList: [...]}
[/init返回SessionId] {id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a}
[/chat建立ws连接后，发送userMessage] {taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a, contentList: [{type: text, message: 查询某功能运行结果}]}
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TASK_START]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 👤USER -> 🤖AGENT: [text] 查询某功能运行结果
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 💡LLM: [text] 查询某功能运行结果
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 💡LLM -> 🤖AGENT: [functionCallList] [{"id":"call_73xLVZDe70QgLHsURgY5BNT0","name":"SomeFunction","parameters":{"operation":"result"}}]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔧TOOL: [functionCallList] [{"id":"call_73xLVZDe70QgLHsURgY5BNT0","name":"SomeFunction","parameters":{"operation":"result"}}]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TOOLS_START]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🔧TOOL -> 🤖AGENT: [toolReturn] {"id":"call_73xLVZDe70QgLHsURgY5BNT0","result":{"statusCode":200,"body":"{\"code\":200,\"message\":\"FAIL\"}"}}
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 💡LLM: [toolReturn] {"id":"call_73xLVZDe70QgLHsURgY5BNT0","result":{"statusCode":200,"body":"{\"code\":200,\"message\":\"FAIL\"}"}}
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🔧TOOL -> 🤖AGENT: [text] [TOOLS_DONE]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TOOLS_DONE]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 💡LLM -> 🤖AGENT: [text] 功能运行结果为FAIL。
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 👤USER: [text] 功能运行结果为FAIL。
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TASK_DONE]
[ws推送] id: eccdacc8-a1a8-463f-b0af-7aebc278c842, taskId: 0b127f1d-4667-4a52-bbcb-0b636f9a471a# 🤖AGENT -> 🔗CLIENT: [text] [TASK_STOP]
[/stop请求] {id: eccdacc8-a1a8-463f-b0af-7aebc278c842}
[/clear请求] {id: eccdacc8-a1a8-463f-b0af-7aebc278c842}
[ws关闭] WebSocket connection closed
```

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