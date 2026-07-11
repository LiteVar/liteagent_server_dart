# API for LiteAgent core Dart Server

[English](API.md) · 中文

版本：`1.0.0`

## 目录
- HTTP API
  - [/agent/list](#1-列出系统所有agent)：获取已经保存过的Agent信息列表。
  - [/agent](#2-获取agent的信息)：根据AgentId获取已经保存过的Agent信息。
  - [/agent/create](#3-创建agent)：创建Agent并保存到数据库中。
  - [/agent/update](#4-更新agent)：更新Agent信息。
  - [/agent/delete](#5-删除agent)：删除Agent信息。
  - [/version](#6-获取版本)：获取当前服务器版本。
  - [/presetOpenSpecList](#7-设置预置openspec列表)：设置预置 OpenSpec 列表。
  - [/initSession](#8-初始化agent会话)：初始化SessionAgent会话，返回SessionId。
  - [/initSimple](#9-初始化simpleagent会话)：初始化SimpleAgent会话，返回SessionId。
  - [/chat](#10-提交用户消息订阅会话执行过程)：提交用户消息，订阅会话执行过程。
  - [/chat/simple](#11-获取simpleagent一次性响应)：发送一次请求获取SimpleAgent返回。
  - [/callback](#12-响应functioncall结果)：客户端接收到FunctionCall要求后，调用此接口返回结果。
  - [/streamCallback](#13-响应functioncall流式结果)：客户端以流式方式返回FunctionCall结果。
  - [/history](#14-获取历史消息)：取某个会话的历史消息列表。
  - [/stop](#15-停止会话)：通过指定 sessionId 停止对应的会话操作。
  - [/clear](#16-清除会话数据)：清除会话数据，返回对应的 sessionId。
  - [/session/list](#17-获取会话列表)：根据 agentId 获取会话列表。
  - [/session/subscribe](#18-订阅会话事件)：订阅指定会话的 SSE 事件。
- AgentMessage说明
  - [`type`在不同类型下的`content`结构](#1-type在不同类型下的content结构)
  - [`to`为`client`时`content`的几个状态字符串](#2-to为client时content的几个状态字符串)

## HTTP API

### Base URL

```http request
https://api.example.com/v1
```

### 1. 列出系统所有Agent

**请求方法**: `GET`

**路径**: `/agent/list`

**功能说明**: 获取已经保存过的Agent信息列表。

#### 请求

无

#### 响应

**状态码**: `200 OK`

**响应体**: `array`类型，对应的`ojbect`为：

| 字段名                                                  | 类型       | 说明                                                                                                                 |
|------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|
| `name`                                               | `string` | Agent的名称                                                                                                           |
| `capability`                                         | `object` | Agent配置，包含以下字段：                                                                                                    |
| `capability.llmConfig`                               | `object` | 大模型配置，包含以下字段：                                                                                                      |
| `capability.llmConfig.provider`                      | `string` | （可选）服务端使用的大模型 provider，仅支持 `openai` 和 `lite_oneapi`。不传时默认为 `lite_oneapi`。 |
| `capability.llmConfig.baseUrl`                       | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.llmConfig.apiKey`                        | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.llmConfig.model`                         | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.llmConfig.adapter`                       | `string` | （可选）当 `provider=lite_oneapi` 时，用于指定请求应走哪一种上游协议/厂商适配器。可选值为 `openai`、`deepseek`、`glm`、`kimi`、`mimo`、`minimax`、`qwen`；不传时默认值为 `openai`。 |
| `capability.llmConfig.temperature`                   | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.llmConfig.maxTokens`                     | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.llmConfig.topP`                          | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.llmConfig.supportsToolCall`           | `boolean` | （可选）模型是否支持工具调用，默认为true                                                                                       |
| `capability.llmConfig.supportsReasoning`          | `boolean` | （可选）模型是否支持深度思考，默认为false                                                                                      |
| `capability.systemPrompt`                            | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题                                                                            |
| `capability.skills`                                  | `array`  | （可选）技能引用列表，数组中每个元素为 `string`。被引用的技能内容应遵循 Agent Skills 规范：https://agentskills.io/specification |
| `capability.openSpecList`                            | `array`  | （可选）Spec 列表，数组中每个元素为 `object`                                                                                      |
| `capability.openSpecList.openSpec`                   | `string` | spec 的 JSON 描述文本，目前支持的类型是 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                              |
| `capability.openSpecList.apiKey`                     | `object` | （可选）第三方服务的 API Key                                                                                                 |
| `capability.openSpecList.apiKey.type`                | `string` | `basic` 或 `bearer` 二选一                                                                                             |
| `capability.openSpecList.apiKey.apiKey`              | `string` | 第三方服务的 API Key                                                                                                     |
| `capability.openSpecList.protocol`                   | `string` | 目前支持 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                                               |
| `capability.openSpecList.serverUrl`                  | `string` | （可选）Spec对应的服务地址，用于覆盖openSpec内的地址                                                                    |
| `capability.callbackOpenTool`                          | `object` | （可选）第三方客户端回调的工具调用                                                                                                  |
| `capability.callbackOpenTool.opentool`                 | `string` | 第三方客户端回调的工具调用的JSON文字，支持`opentool`格式                                                                                |
| `capability.callbackOpenTool.timeout`                  | `int`    | （可选）第三方客户端回调工具超时时间，默认为60秒                                                                                          |
| `capability.sessionList`                             | `array`  | （可选）Session 列表，数组中每个元素为 `object`                                                                                   |
| `capability.sessionList.sessionId`                          | `string` | Sub Agent 的 sessionId                                                                                              |
| `capability.sessionList.name`                        | `string` | （可选）Sub Agent 的自定义名称，必须由 a-z、A-Z、0-9 组成，或包含下划线和破折号，最大长度为 64。                                                       |
| `capability.sessionList.description`                 | `string` | （可选）Sub Agent 的描述，如果为`null`，则使用Sub Agent的`system prompt`截取前1024字符作为。                                               |
| `capability.reflectPromptList`                       | `array`  | （可选）ReflectPrompt 列表，数组中每个元素为 `object`; **若`openSpecList`为空则反思LLM的text，否则反思LLM的Function Calling**                  |
| `capability.reflectPromptList.llmConfig`             | `object` | `ReflectAgent` 的 `llmConfig`，用于请求大模型                                                                               |
| `capability.reflectPromptList.llmConfig.baseUrl`     | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.reflectPromptList.llmConfig.apiKey`      | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.reflectPromptList.llmConfig.model`       | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.reflectPromptList.llmConfig.temperature` | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.reflectPromptList.llmConfig.maxTokens`   | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.reflectPromptList.llmConfig.topP`        | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.reflectPromptList.prompt`                | `string` | `ReflectAgent`的 System Prompt，用以描述reflection分数的判断标准。                                                               |
| `capability.timeoutSeconds`                          | `number` | （可选）超时时间，默认为3600，以秒为单位                                                                                             |
| `capability.taskPipelineStrategy`                    | `enum`   | （可选）同一会话下，新的任务指令，执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel`                      |
| `capability.toolPipelineStrategy`                    | `enum`   | （可选）同一任务下，若function calling返回为数组时，tool执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel` |
| `capability.auto`                                    | `boolean`| （可选）是否自动执行任务                                                                                                                     |
| `capability.llmConfigList`                           | `array`  | （可选）备用模型配置列表，元素结构同`llmConfig`                                                                                                   |
| `capability.enableThinking`                          | `boolean`| （可选）是否开启思考输出                                                                                                                       |

#### 响应示例

```json
[
  {
    "agentId": "671763aae989ec22357fea88",
    "name": "Agent例子",
    "capability": {
      "llmConfig": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "sk-xxxxxxxxxx",
        "model": "gpt-4o-mini",
        "temperature": 0,
        "maxTokens": 4096,
        "topP": 1
      },
      "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决某某问题",
      "skills": [
        "code-review",
        "release-notes"
      ],
      "openSpecList": [
        {
          "openSpec": "<spec的json描述文本，目前支持的类型是openapi、jsonrpcHttp、opentool、mcpStdio、mcpHttp>",
          "apiKey": {
            "type": "bearer",
            "apiKey": "sk-xxxxxxxxxxxxxxxx"
          },
          "protocol": "openapi"
        },
        {
          "openSpec": "<另一段spec的json描述，可以不同类型混用>",
          "protocol": "jsonrpcHttp"
        }
      ],
      "callbackOpenTool": "<spec的json描述文本，目前支持的类型是opentool>",
      "sessionList": [
        {
          "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
          "name": "someFunc1"
        },
        {
          "id": "a20245f2-e9f0-416c-9191-8ed3afeac46b",
          "name": "some-func_2"
        }
      ],
      "timeoutSeconds": 7200
    }
  }
]
```

### 2. 获取Agent的信息

**请求方法**: `GET`

**路径**: `/agent`

**功能说明**: 根据AgentId获取已经保存过的Agent信息。

#### 路径参数

| 字段名       | 类型       | 说明         |
|-----------|----------|------------|
| `agentId` | `string` | Agent对应的ID |

#### 路径示例

```http request
GET /agent?agentId=671763aae989ec22357fea88
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名                                                  | 类型       | 说明                                                                                                                 |
|------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|
| `agentId`                                            | `string` | Agent的Id                                                                                                           |
| `name`                                               | `string` | Agent的名称                                                                                                           |
| `capability`                                         | `object` | Agent配置，包含以下字段：                                                                                                    |
| `capability.llmConfig`                               | `object` | 大模型配置，包含以下字段：                                                                                                      |
| `capability.llmConfig.provider`                      | `string` | （可选）服务端使用的大模型 provider，仅支持 `openai` 和 `lite_oneapi`。不传时默认为 `lite_oneapi`。 |
| `capability.llmConfig.baseUrl`                       | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.llmConfig.apiKey`                        | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.llmConfig.model`                         | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.llmConfig.adapter`                       | `string` | （可选）当 `provider=lite_oneapi` 时，用于指定请求应走哪一种上游协议/厂商适配器。可选值为 `openai`、`deepseek`、`glm`、`kimi`、`mimo`、`minimax`、`qwen`；不传时默认值为 `openai`。 |
| `capability.llmConfig.temperature`                   | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.llmConfig.maxTokens`                     | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.llmConfig.topP`                          | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.llmConfig.supportsToolCall`           | `boolean` | （可选）模型是否支持工具调用，默认为true                                                                                       |
| `capability.llmConfig.supportsReasoning`          | `boolean` | （可选）模型是否支持深度思考，默认为false                                                                                      |
| `capability.systemPrompt`                            | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题                                                                            |
| `capability.skills`                                  | `array`  | （可选）技能引用列表，数组中每个元素为 `string`。被引用的技能内容应遵循 Agent Skills 规范：https://agentskills.io/specification |
| `capability.openSpecList`                            | `array`  | （可选）Spec 列表，数组中每个元素为 `object`                                                                                      |
| `capability.openSpecList.openSpec`                   | `string` | spec 的 JSON 描述文本，目前支持的类型是 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                              |
| `capability.openSpecList.apiKey`                     | `object` | （可选）第三方服务的 API Key                                                                                                 |
| `capability.openSpecList.apiKey.type`                | `string` | `basic` 或 `bearer` 二选一                                                                                             |
| `capability.openSpecList.apiKey.apiKey`              | `string` | 第三方服务的 API Key                                                                                                     |
| `capability.openSpecList.protocol`                   | `string` | 目前支持 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                                               |
| `capability.openSpecList.serverUrl`                  | `string` | （可选）Spec对应的服务地址，用于覆盖openSpec内的地址                                                                    |
| `capability.callbackOpenTool`                          | `object` | （可选）第三方客户端回调的工具调用                                                                                                  |
| `capability.callbackOpenTool.opentool`                 | `string` | 第三方客户端回调的工具调用的JSON文字，支持`opentool`格式                                                                                |
| `capability.callbackOpenTool.timeout`                  | `int`    | （可选）第三方客户端回调工具超时时间，默认为60秒                                                                                          |
| `capability.sessionList`                             | `array`  | （可选）Session 列表，数组中每个元素为 `object`                                                                                   |
| `capability.sessionList.sessionId`                          | `string` | Sub Agent 的 sessionId                                                                                              |
| `capability.sessionList.name`                        | `string` | （可选）Sub Agent 的自定义名称，必须由 a-z、A-Z、0-9 组成，或包含下划线和破折号，最大长度为 64。                                                       |
| `capability.sessionList.description`                 | `string` | （可选）Sub Agent 的描述，如果为`null`，则使用Sub Agent的`system prompt`截取前1024字符作为。                                               |
| `capability.reflectPromptList`                       | `array`  | （可选）ReflectPrompt 列表，数组中每个元素为 `object`; **若`openSpecList`为空则反思LLM的text，否则反思LLM的Function Calling**                  |
| `capability.reflectPromptList.llmConfig`             | `object` | `ReflectAgent` 的 `llmConfig`，用于请求大模型                                                                               |
| `capability.reflectPromptList.llmConfig.baseUrl`     | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.reflectPromptList.llmConfig.apiKey`      | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.reflectPromptList.llmConfig.model`       | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.reflectPromptList.llmConfig.temperature` | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.reflectPromptList.llmConfig.maxTokens`   | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.reflectPromptList.llmConfig.topP`        | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.reflectPromptList.prompt`                | `string` | `ReflectAgent`的 System Prompt，用以描述reflection分数的判断标准。                                                               |
| `capability.timeoutSeconds`                          | `number` | （可选）超时时间，默认为3600，以秒为单位                                                                                             |
| `capability.taskPipelineStrategy`                    | `enum`   | （可选）同一会话下，新的任务指令，执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel`                      |
| `capability.toolPipelineStrategy`                    | `enum`   | （可选）同一任务下，若function calling返回为数组时，tool执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel` |
| `capability.auto`                                    | `boolean`| （可选）是否自动执行任务                                                                                                                     |
| `capability.llmConfigList`                           | `array`  | （可选）备用模型配置列表，元素结构同`llmConfig`                                                                                                   |
| `capability.enableThinking`                          | `boolean`| （可选）是否开启思考输出                                                                                                                       |

#### 响应示例

```json
{
  "name": "Agent例子",
  "capability": {
    "llmConfig": {
      "baseUrl": "https://api.openai.com/v1",
      "apiKey": "sk-xxxxxxxxxx",
      "model": "gpt-4o-mini",
      "temperature": 0,
      "maxTokens": 4096,
      "topP": 1
    },
    "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决某某问题",
    "skills": [
      "code-review",
      "release-notes"
    ],
    "openSpecList": [
      {
        "openSpec": "<spec的json描述文本，目前支持的类型是openapi、jsonrpcHttp、opentool、mcpStdio、mcpHttp>",
        "apiKey": {
          "type": "bearer",
          "apiKey": "sk-xxxxxxxxxxxxxxxx"
        },
        "protocol": "openapi"
      },
      {
        "openSpec": "<另一段spec的json描述，可以不同类型混用>",
        "protocol": "jsonrpcHttp"
      }
    ],
    "callbackOpenTool": "<spec的json描述文本，目前支持的类型是opentool>",
    "sessionList": [
      {
        "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
        "name": "someFunc1"
      },
      {
        "id": "a20245f2-e9f0-416c-9191-8ed3afeac46b",
        "name": "some-func_2"
      }
    ],
    "timeoutSeconds": 7200
  }
}
```

### 3. 创建Agent

**请求方法**: `POST`

**路径**: `/agent/create`

**功能说明**: 创建Agent并保存到数据库中。

#### 请求参数

| 字段名                                                  | 类型       | 说明                                                                                                                 |
|------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|
| `name`                                               | `string` | Agent的名称                                                                                                           |
| `capability`                                         | `object` | Agent配置，包含以下字段：                                                                                                    |
| `capability.llmConfig`                               | `object` | 大模型配置，包含以下字段：                                                                                                      |
| `capability.llmConfig.provider`                      | `string` | （可选）服务端使用的大模型 provider，仅支持 `openai` 和 `lite_oneapi`。不传时默认为 `lite_oneapi`。 |
| `capability.llmConfig.baseUrl`                       | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.llmConfig.apiKey`                        | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.llmConfig.model`                         | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.llmConfig.adapter`                       | `string` | （可选）当 `provider=lite_oneapi` 时，用于指定请求应走哪一种上游协议/厂商适配器。可选值为 `openai`、`deepseek`、`glm`、`kimi`、`mimo`、`minimax`、`qwen`；不传时默认值为 `openai`。 |
| `capability.llmConfig.temperature`                   | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.llmConfig.maxTokens`                     | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.llmConfig.topP`                          | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.llmConfig.supportsToolCall`           | `boolean` | （可选）模型是否支持工具调用，默认为true                                                                                       |
| `capability.llmConfig.supportsReasoning`          | `boolean` | （可选）模型是否支持深度思考，默认为false                                                                                      |
| `capability.systemPrompt`                            | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题                                                                            |
| `capability.openSpecList`                            | `array`  | （可选）Spec 列表，数组中每个元素为 `object`                                                                                      |
| `capability.openSpecList.openSpec`                   | `string` | spec 的 JSON 描述文本，目前支持的类型是 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                              |
| `capability.openSpecList.apiKey`                     | `object` | （可选）第三方服务的 API Key                                                                                                 |
| `capability.openSpecList.apiKey.type`                | `string` | `basic` 或 `bearer` 二选一                                                                                             |
| `capability.openSpecList.apiKey.apiKey`              | `string` | 第三方服务的 API Key                                                                                                     |
| `capability.openSpecList.protocol`                   | `string` | 目前支持 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                                               |
| `capability.openSpecList.serverUrl`                  | `string` | （可选）Spec对应的服务地址，用于覆盖openSpec内的地址                                                                    |
| `capability.callbackOpenTool`                          | `object` | （可选）第三方客户端回调的工具调用                                                                                                  |
| `capability.callbackOpenTool.opentool`                 | `string` | 第三方客户端回调的工具调用的JSON文字，支持`opentool`格式                                                                                |
| `capability.callbackOpenTool.timeout`                  | `int`    | （可选）第三方客户端回调工具超时时间，默认为60秒                                                                                          |
| `capability.sessionList`                             | `array`  | （可选）Session 列表，数组中每个元素为 `object`                                                                                   |
| `capability.sessionList.sessionId`                          | `string` | Sub Agent 的 sessionId                                                                                              |
| `capability.sessionList.name`                        | `string` | （可选）Sub Agent 的自定义名称，必须由 a-z、A-Z、0-9 组成，或包含下划线和破折号，最大长度为 64。                                                       |
| `capability.sessionList.description`                 | `string` | （可选）Sub Agent 的描述，如果为`null`，则使用Sub Agent的`system prompt`截取前1024字符作为。                                               |
| `capability.reflectPromptList`                       | `array`  | （可选）ReflectPrompt 列表，数组中每个元素为 `object`; **若`openSpecList`为空则反思LLM的text，否则反思LLM的Function Calling**                  |
| `capability.reflectPromptList.llmConfig`             | `object` | `ReflectAgent` 的 `llmConfig`，用于请求大模型                                                                               |
| `capability.reflectPromptList.llmConfig.baseUrl`     | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.reflectPromptList.llmConfig.apiKey`      | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.reflectPromptList.llmConfig.model`       | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.reflectPromptList.llmConfig.temperature` | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.reflectPromptList.llmConfig.maxTokens`   | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.reflectPromptList.llmConfig.topP`        | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.reflectPromptList.prompt`                | `string` | `ReflectAgent`的 System Prompt，用以描述reflection分数的判断标准。                                                               |
| `capability.timeoutSeconds`                          | `number` | （可选）超时时间，默认为3600，以秒为单位                                                                                             |
| `capability.taskPipelineStrategy`                    | `enum`   | （可选）同一会话下，新的任务指令，执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel`                      |
| `capability.toolPipelineStrategy`                    | `enum`   | （可选）同一任务下，若function calling返回为数组时，tool执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel` |
| `capability.auto`                                    | `boolean`| （可选）是否自动执行任务                                                                                                                     |
| `capability.llmConfigList`                           | `array`  | （可选）备用模型配置列表，元素结构同`llmConfig`                                                                                                   |
| `capability.enableThinking`                          | `boolean`| （可选）是否开启思考输出                                                                                                                       |

#### 请求示例

```json
{
  "name": "Agent例子",
  "capability": {
    "llmConfig": {
      "provider": "lite_oneapi",
      "baseUrl": "https://your-oneapi-server/v1",
      "apiKey": "sk-xxxxxxxxxx",
      "model": "gpt-4o-mini",
      "adapter": "openai",
      "temperature": 0,
      "maxTokens": 4096,
      "topP": 1
    },
    "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决某某问题",
    "openSpecList": [
      {
        "openSpec": "<spec的json描述文本，目前支持的类型是openapi、jsonrpcHttp、opentool、mcpStdio、mcpHttp>",
        "apiKey": {
          "type": "bearer",
          "apiKey": "sk-xxxxxxxxxxxxxxxx"
        },
        "protocol": "openapi"
      },
      {
        "openSpec": "<另一段spec的json描述，可以不同类型混用>",
        "protocol": "jsonrpcHttp"
      }
    ],
    "callbackOpenTool": "<spec的json描述文本，目前支持的类型是opentool>",
    "sessionList": [
      {
        "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
        "name": "someFunc1"
      },
      {
        "id": "a20245f2-e9f0-416c-9191-8ed3afeac46b",
        "name": "some-func_2"
      }
    ],
    "timeoutSeconds": 7200
  }
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名       | 类型       | 说明         |
|-----------|----------|------------|
| `agentId` | `string` | Agent对应的ID |

#### 响应示例

```json
{
  "agentId": "671763aae989ec22357fea88"
}
```

### 4. 更新Agent

**请求方法**: `POST`

**路径**: `/agent/update`

**功能说明**: 更新Agent信息。

#### 路径参数

| 字段名       | 类型       | 说明         |
|-----------|----------|------------|
| `agentId` | `string` | Agent对应的ID |

#### 路径示例

```http request
GET /agent/update?agentId=671763aae989ec22357fea88
```

#### 请求参数

| 字段名                                                  | 类型       | 说明                                                                                                                 |
|------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|
| `name`                                               | `string` | Agent的名称                                                                                                           |
| `capability`                                         | `object` | Agent配置，包含以下字段：                                                                                                    |
| `capability.llmConfig`                               | `object` | 大模型配置，包含以下字段：                                                                                                      |
| `capability.llmConfig.provider`                      | `string` | （可选）服务端使用的大模型 provider，仅支持 `openai` 和 `lite_oneapi`。不传时默认为 `lite_oneapi`。 |
| `capability.llmConfig.baseUrl`                       | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.llmConfig.apiKey`                        | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.llmConfig.model`                         | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.llmConfig.adapter`                       | `string` | （可选）当 `provider=lite_oneapi` 时，用于指定请求应走哪一种上游协议/厂商适配器。可选值为 `openai`、`deepseek`、`glm`、`kimi`、`mimo`、`minimax`、`qwen`；不传时默认值为 `openai`。 |
| `capability.llmConfig.temperature`                   | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.llmConfig.maxTokens`                     | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.llmConfig.topP`                          | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.llmConfig.supportsToolCall`           | `boolean` | （可选）模型是否支持工具调用，默认为true                                                                                       |
| `capability.llmConfig.supportsReasoning`          | `boolean` | （可选）模型是否支持深度思考，默认为false                                                                                      |
| `capability.systemPrompt`                            | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题                                                                            |
| `capability.openSpecList`                            | `array`  | （可选）Spec 列表，数组中每个元素为 `object`                                                                                      |
| `capability.openSpecList.openSpec`                   | `string` | spec 的 JSON 描述文本，目前支持的类型是 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                              |
| `capability.openSpecList.apiKey`                     | `object` | （可选）第三方服务的 API Key                                                                                                 |
| `capability.openSpecList.apiKey.type`                | `string` | `basic` 或 `bearer` 二选一                                                                                             |
| `capability.openSpecList.apiKey.apiKey`              | `string` | 第三方服务的 API Key                                                                                                     |
| `capability.openSpecList.protocol`                   | `string` | 目前支持 `openapi`、`jsonrpcHttp`、`opentool`、`mcpStdio`、`mcpHttp`                                                               |
| `capability.openSpecList.serverUrl`                  | `string` | （可选）Spec对应的服务地址，用于覆盖openSpec内的地址                                                                    |
| `capability.callbackOpenTool`                          | `object` | （可选）第三方客户端回调的工具调用                                                                                                  |
| `capability.callbackOpenTool.opentool`                 | `string` | 第三方客户端回调的工具调用的JSON文字，支持`opentool`格式                                                                                |
| `capability.callbackOpenTool.timeout`                  | `int`    | （可选）第三方客户端回调工具超时时间，默认为60秒                                                                                          |
| `capability.sessionList`                             | `array`  | （可选）Session 列表，数组中每个元素为 `object`                                                                                   |
| `capability.sessionList.sessionId`                          | `string` | Sub Agent 的 sessionId                                                                                              |
| `capability.sessionList.name`                        | `string` | （可选）Sub Agent 的自定义名称，必须由 a-z、A-Z、0-9 组成，或包含下划线和破折号，最大长度为 64。                                                       |
| `capability.sessionList.description`                 | `string` | （可选）Sub Agent 的描述，如果为`null`，则使用Sub Agent的`system prompt`截取前1024字符作为。                                               |
| `capability.reflectPromptList`                       | `array`  | （可选）ReflectPrompt 列表，数组中每个元素为 `object`; **若`openSpecList`为空则反思LLM的text，否则反思LLM的Function Calling**                  |
| `capability.reflectPromptList.llmConfig`             | `object` | `ReflectAgent` 的 `llmConfig`，用于请求大模型                                                                               |
| `capability.reflectPromptList.llmConfig.baseUrl`     | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                                                                         |
| `capability.reflectPromptList.llmConfig.apiKey`      | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                                                                                    |
| `capability.reflectPromptList.llmConfig.model`       | `string` | 大模型名称，例如：gpt-4o-mini                                                                                               |
| `capability.reflectPromptList.llmConfig.temperature` | `number` | （可选）温度值，默认为 0                                                                                                      |
| `capability.reflectPromptList.llmConfig.maxTokens`   | `number` | （可选）最大 token 数，默认为 4096                                                                                            |
| `capability.reflectPromptList.llmConfig.topP`        | `number` | （可选）概率抽样的 p 值，默认为 1                                                                                                |
| `capability.reflectPromptList.prompt`                | `string` | `ReflectAgent`的 System Prompt，用以描述reflection分数的判断标准。                                                               |
| `capability.timeoutSeconds`                          | `number` | （可选）超时时间，默认为3600，以秒为单位                                                                                             |
| `capability.taskPipelineStrategy`                    | `enum`   | （可选）同一会话下，新的任务指令，执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel`                      |
| `capability.toolPipelineStrategy`                    | `enum`   | （可选）同一任务下，若function calling返回为数组时，tool执行的策略，目前支持 `parallel`允许并行、`serial`排队执行、`reject`如有任务正在执行则拒绝新任务，默认为 `parallel` |
| `capability.auto`                                    | `boolean`| （可选）是否自动执行任务                                                                                                                     |
| `capability.llmConfigList`                           | `array`  | （可选）备用模型配置列表，元素结构同`llmConfig`                                                                                                   |
| `capability.enableThinking`                          | `boolean`| （可选）是否开启思考输出                                                                                                                       |

#### 请求示例

```json
{
  "name": "Agent例子",
  "capability": {
    "llmConfig": {
      "provider": "lite_oneapi",
      "baseUrl": "https://your-oneapi-server/v1",
      "apiKey": "sk-xxxxxxxxxx",
      "model": "gpt-4o-mini",
      "adapter": "openai",
      "temperature": 0,
      "maxTokens": 4096,
      "topP": 1
    },
    "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决某某问题",
    "openSpecList": [
      {
        "openSpec": "<spec的json描述文本，目前支持的类型是openapi、jsonrpcHttp、opentool、mcpStdio、mcpHttp>",
        "apiKey": {
          "type": "bearer",
          "apiKey": "sk-xxxxxxxxxxxxxxxx"
        },
        "protocol": "openapi"
      },
      {
        "openSpec": "<另一段spec的json描述，可以不同类型混用>",
        "protocol": "jsonrpcHttp"
      }
    ],
    "callbackOpenTool": "<spec的json描述文本，目前支持的类型是opentool>",
    "sessionList": [
      {
        "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
        "name": "someFunc1"
      },
      {
        "id": "a20245f2-e9f0-416c-9191-8ed3afeac46b",
        "name": "some-func_2"
      }
    ],
    "timeoutSeconds": 7200
  }
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名       | 类型       | 说明             |
|-----------|----------|----------------|
| `agentId` | `string` | 确认更新Agent对应的ID |

#### 响应示例

```json
{
    "agentId": "671763aae989ec22357fea88"
}
```

### 5. 删除Agent

**请求方法**: `GET`

**路径**: `/agent/delete`

**功能说明**: 删除Agent信息。

#### 路径参数

| 字段名       | 类型       | 说明         |
|-----------|----------|------------|
| `agentId` | `string` | Agent对应的ID |

#### 路径示例

```http request
GET /agent/delete?agentId=671763aae989ec22357fea88
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名       | 类型       | 说明             |
|-----------|----------|----------------|
| `agentId` | `string` | 确认删除Agent对应的ID |

#### 响应示例

```json
{
  "agentId": "671763aae989ec22357fea88"
}
```

### 6. 获取版本

**请求方法**: `GET`

**路径**: `/version`

**功能说明**: 获取当前服务器版本。

#### 请求参数

无

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名       | 类型       | 说明              |
|-----------|----------|-----------------|
| `version` | `string` | 版本号，采用"a.b.c"格式 |

#### 响应示例

```json
  {
      "version": "0.0.0"
  }
```

### 7. 设置预置OpenSpec列表

**请求方法**: `POST`

**路径**: `/presetOpenSpecList`

**功能说明**: 设置服务端全局的预置 OpenSpec 列表。该列表会在后续 `initSession` / `initSimple` 时生效：每个 `systemPrompt` 会追加到会话系统提示词中；每个 `openSpec` 会作为工具加载。

#### 请求体

**请求体**: `array` 或单个 `object`，每个元素字段如下：

| 字段名          | 类型     | 说明                                                                 |
|-----------------|----------|----------------------------------------------------------------------|
| `systemPrompt`  | `string` | 必填。要追加的系统提示词片段。                                         |
| `openSpec`      | `object` | （可选）OpenSpec 定义。结构同 `/initSession` 的 `openSpecList` 元素。 |

#### 请求示例

```json
[
  {
    "systemPrompt": "请使用简洁要点回复。"
  },
  {
    "systemPrompt": "需要时可调用天气工具。",
    "openSpec": {
      "openSpec": "<OpenAPI JSON 字符串>",
      "protocol": "openapi"
    }
  }
]
```

#### 响应

**状态码**: `200 OK`

**响应体**: `{}`

### 8. 初始化Agent会话

**请求方法**: `POST`

**路径**: `/initSession`

**功能说明**: 初始化SessionAgent会话，返回SessionId。

#### 路径参数

| 字段名       | 类型       | 说明                   |
|-----------|----------|----------------------|
| `agentId` | `string` | 预先储存Agent后获取的AgentId |

#### 路径示例

```http request
POST /initSession?agentId=671763aae989ec22357fea88
```

#### 请求参数

当不传 `agentId` 时，请求体为 `CapabilityDto`，字段与创建Agent接口一致。

其中 `skills` 字段遵循 [Agent Skills Specification](https://agentskills.io/specification)。实践上，每个 skill 应是一个包含 `SKILL.md` 的目录，`SKILL.md` 由 YAML frontmatter 和 Markdown 正文组成；其中 `name` 要求为小写加连字符格式，`description` 为必填且非空。

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名         | 类型       | 说明                                               |
|-------------|----------|--------------------------------------------------|
| `sessionId` | `string` | 会话ID，系统生成的唯一标识符。用以后续对于该session的消息订阅、stop、clear操作 |

#### 响应示例

```json
{
  "sessionId": "1901883204734947328"
}
```

### 9. 初始化SimpleAgent会话

**请求方法**: `POST`

**路径**: `/initSimple`

**功能说明**: 初始化SimpleAgent会话，返回SessionId。SimpleAgent不需要SSE连接，后续通过`/chat/simple`获取一次性回复。

#### 请求参数

| 字段名                             | 类型       | 说明                                                                 |
|----------------------------------|----------|--------------------------------------------------------------------|
| `llmConfig`                      | `object` | 大模型配置，包含以下字段：                                                   |
| `llmConfig.provider`             | `string` | （可选）服务端使用的大模型 provider，仅支持 `openai` 和 `lite_oneapi`。不传时默认为 `lite_oneapi`。 |
| `llmConfig.baseUrl`              | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                      |
| `llmConfig.apiKey`               | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                               |
| `llmConfig.model`                | `string` | 大模型名称，例如：gpt-4o-mini                                          |
| `llmConfig.adapter`              | `string` | （可选）当 `provider=lite_oneapi` 时，用于指定请求应走哪一种上游协议/厂商适配器。可选值为 `openai`、`deepseek`、`glm`、`kimi`、`mimo`、`minimax`、`qwen`；不传时默认值为 `openai`。 |
| `llmConfig.temperature`          | `number` | （可选）温度值，默认为 0                                               |
| `llmConfig.maxTokens`            | `number` | （可选）最大 token 数，默认为 4096                                     |
| `llmConfig.topP`                 | `number` | （可选）概率抽样的 p 值，默认为 1                                         |
| `llmConfig.supportsToolCall`  | `boolean`| （可选）模型是否支持工具调用，默认为 true                                   |
| `llmConfig.supportsReasoning` | `boolean`| （可选）模型是否支持深度思考，默认为 false                                  |
| `systemPrompt`                   | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题         |
| `skills`                         | `array`  | （可选）技能引用列表，数组中每个元素为 `string`。被引用的技能内容应遵循 Agent Skills 规范：https://agentskills.io/specification |

`skills` 与 `/initSession` 使用同一规范来源：[Agent Skills Specification](https://agentskills.io/specification)。

#### 请求示例

```json
{
  "llmConfig": {
    "provider": "lite_oneapi",
    "baseUrl": "https://your-oneapi-server/v1",
    "apiKey": "sk-xxxxxxxxxx",
    "model": "gpt-4o-mini",
    "adapter": "openai",
    "temperature": 0,
    "maxTokens": 4096,
    "topP": 1
  },
  "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决哪一类的问题",
  "skills": [
    "code-review"
  ]
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名         | 类型       | 说明                                               |
|-------------|----------|--------------------------------------------------|
| `sessionId` | `string` | 会话ID，系统生成的唯一标识符。用以后续对该session的操作             |

#### 响应示例

```json
{
  "sessionId": "1901883204734947328"
}
```

### 10. 提交用户消息，订阅会话执行过程

**请求方法**: `POST`

**路径**: `/chat`

**功能说明**: 提交用户消息，订阅会话执行过程。需通过此接口建立`SSE`连接,后续产生的消息数据都将通过流的形式推送给客户端.

#### 路径参数

| 字段名         | 类型       | 说明                        |
|-------------|----------|---------------------------|
| `sessionId` | `string` | 通过`initSession`接口获取到的临时会话 |

#### 路径示例

```http request
POST /chat?sessionId=1901883204734947328
```

#### 请求参数

| 字段名               | 类型        | 说明                                                                                                                                                                              |
|-------------------|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `content`         | `array`   | 消息内容列表，数组中每个元素为 `object`                                                                                                                                                        |
| `content.type`    | `string`  | 消息类型，可选为 `text` `imageUrl`                                                                                                                                                      |
| `content.message` | `string`  | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接："https://example.com/path/to/image.png" ，且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |
| `isChunk`         | `boolean` | （可选）是否启用分片输出，默认为`false`                                                                                                                                                           |
| `extraSystemPrompt` | `string` | （可选）追加到 Agent 基础 system prompt 的额外系统提示词（当前会话/任务生效）。                                                                                                             |

#### 请求示例

```json
{
  "content": [
    { "type": "text", "message":"你是谁？" }
  ],
  "isChunk": true,
  "extraSystemPrompt": "只回复一个整数即可。"
}
```

#### 响应流

- 采用SSE，`Content-Type: text/event-stream`

- 消息类型`event`有3种类型:`message`、`chunk`与`functionCall`。其中，`chunk`类型只有`isChunk`为`true`时，且`role`为`assistant`有效。

当`event`为`message`时，`data`类型为`object`类型，`data`结构如下:

| 字段                                   | 类型        | 说明                                                                                                |
|--------------------------------------|-----------|---------------------------------------------------------------------------------------------------|
| `sessionId`                          | `string`  | 会话id                                                                                              |
| `taskId`                             | `string`  | 任务id                                                                                              |
| `role`                               | `string`  | 角色，可选值包括： `developer`、`user`、`agent`、`assistant`、`reflection`、`tool`、`client`                     |
| `to`                                 | `string`  | 消息发送的目标，可选值包括与`role`一致                                                                            |
| `type`                               | `string`  | 消息类型，可能包含的值有:`text`、`reasoning`、`imageUrl`、`contentList`、`toolCalls`、`reflection`、`toolReturn`、`functionCall` |
| `content`                            | `dynamic` | 见以下示例定义，详情定义见 [`type`在不同类型下的`content`结构](#1-type在不同类型下的content结构)                                 |
| `completions`                        | `object`  | （可选）大模型完成的详细信息，包含以下字段：                                                                            |
| `completions.usage`                  | `object`  | token 使用信息                                                                                        |
| `completions.usage.promptTokens`     | `number`  | 提示符 token 数                                                                                       |
| `completions.usage.completionTokens` | `number`  | 生成 token 数                                                                                        |
| `completions.usage.totalTokens`      | `number`  | 总 token 数                                                                                         |
| `completions.usage.contextUsageRatio` | `number` | 上下文占用比例（0~1），基于 `contextWindowSize` 计算；未配置时可能为 `null` |
| `completions.id`                     | `string`  | 大模型返回的消息 ID                                                                                       |
| `completions.model`                  | `string`  | 大模型名称，例如 gpt-4o-mini                                                                              |
| `completions.limits`                      | `object` | （可选）模型返回的限制信息（来自配置） |
| `completions.limits.maxTokens`            | `number` | 模型配置的最大输出 token 数 |
| `completions.limits.contextWindowSize`    | `number` | （可选）上下文窗口大小，用于计算上下文占用比例 |
| `createTime`                         | `string`  | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ                                                               |

#### `event`为`message`的`data`示例

- 用户发送的消息：`type`为`contentList`
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"user",
    "to":"agent",
    "type": "contentList",
    "content":[
      { "type": "text", "message":"你是谁？" }
    ],
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

- 当LLM有functionCalling时的消息：`type`=`toolCalls`
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"assistant",
    "to":"agent",
    "type": "toolCalls",
    "content":[
      { "id":"call_abc123", "name":"_ip_local_geo_v1_district", "arguments":{} }
    ],
    "completions": {
      "usage": {
        "promptTokens": 199,
        "completionTokens": 12,
        "totalTokens": 211,
        "contextUsageRatio": 0.15
      },
      "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
      "model": "gpt-4o-mini",
      "limits": {
        "maxTokens": 4096,
        "contextWindowSize": 128000
      }
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

- `tool`执行完后，响应给LLM：`type`=`toolReturn`
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"tool",
    "to":"agent",
    "type": "toolReturn",
    "content":{ 
      "id":"functionCallId", 
      "result":{} 
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

- 反思请求：`type`=`reflection`
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"reflection",
    "to":"agent",
    "type": "reflection",
    "content": {
      "isPass":"",
      "agentId": "xxx", 
      "name": "MyAgent",
      "messageScore": {
        "content": [
          { "type": "text", "message":"查询IP" }
        ],
        "messageType": "text",
        "message": "查询IP的结果为192.168.31.123",
        "reflectScoreList": [
          {"score": 10, "description": "返回数据包含IP信息"}
        ] 
      },
      "passScore":"8",
      "count": "1", 
      "maxCount": "10"
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

- 当`isChunk`=`false`，LLM返回的结果
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"assistant",
    "to":"agent",
    "type": "text",
    "content": "查询得到的IP地址为192.168.31.123",
    "completions": {
      "usage": {
        "promptTokens": 199,
        "completionTokens": 12,
        "totalTokens": 211,
        "contextUsageRatio": 0.15
      },
      "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
      "model": "gpt-4o-mini",
      "limits": {
        "maxTokens": 4096,
        "contextWindowSize": 128000
      }
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

- `agent`告知`client`当前状态
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"agent",
    "to":"client",
    "type": "taskStatus",
    "content": {
      "status": "start",
      "description": {}
    },
    "completions": {
      "usage": {
        "promptTokens": 199,
        "completionTokens": 12,
        "totalTokens": 211,
        "contextUsageRatio": 0.15
      },
      "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
      "model": "gpt-4o-mini",
      "limits": {
        "maxTokens": 4096,
        "contextWindowSize": 128000
      }
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

当`isChunk`=`true`时，LLM的消息返回`event`为`chunk`，`role`为`agent` `assistant`。`data`类型为`object`类型，`data`结构如下:

| 字段                                   | 类型       | 说明                                  |
|--------------------------------------|----------|-------------------------------------|
| `sessionId`                          | `string` | 会话id                                |
| `taskId`                             | `string` | 任务id                                |
| `role`                               | `string` | 角色，可选值包括： `agent`、`assistant`       |
| `to`                                 | `string` | 消息目标，可选值包括与`role`一致                 |
| `type`                               | `string` | 消息类型，可能包含的值有:`text`、`taskStatus`    |
| `part`                               | `string` | LLM返回信息的片段                          |
| `completions`                        | `object` | （可选）大模型完成的详细信息，包含以下字段：              |
| `completions.usage`                  | `object` | token 使用信息                          |
| `completions.usage.promptTokens`     | `number` | 提示符 token 数                         |
| `completions.usage.completionTokens` | `number` | 生成 token 数                          |
| `completions.usage.totalTokens`      | `number` | 总 token 数                           |
| `completions.usage.contextUsageRatio` | `number` | 上下文占用比例（0~1），基于 `contextWindowSize` 计算；未配置时可能为 `null` |
| `completions.id`                     | `string` | 大模型返回的消息 ID                         |
| `completions.model`                  | `string` | 大模型名称，例如 gpt-4o-mini                |
| `completions.limits`                      | `object` | （可选）模型返回的限制信息（来自配置） |
| `completions.limits.maxTokens`            | `number` | 模型配置的最大输出 token 数 |
| `completions.limits.contextWindowSize`    | `number` | （可选）上下文窗口大小，用于计算上下文占用比例 |
| `createTime`                         | `string` | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ |

#### `data`为`chunk`示例：
  
- `chunk`文本片段
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"assistant",
    "to":"agent",
    "type": "text",
    "part": "您的",
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```
- `chunk`文本片段响应结束
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"assistant",
    "to":"agent",
    "type": "taskStatus",
    "part": {
      "status": "chunkDone",
      "taskId": "1901883415867822080"
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

- `chunk`过程的token使用信息
  ```json
  {
    "sessionId":"1901883204734947328",
    "taskId":"1901883415867822080",
    "role":"assistant",
    "to":"agent",
    "type": "text",
    "content": "",
    "completions": {
      "usage": {
        "promptTokens": 199,
        "completionTokens": 12,
        "totalTokens": 211,
        "contextUsageRatio": 0.15
      },
      "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
      "model": "gpt-4o-mini",
      "limits": {
        "maxTokens": 4096,
        "contextWindowSize": 128000
      }
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
  ```

当`event`为`functionCall`时，`data`类型为`object`类型，`data`结构如下:

| `type`       | content数据类型                | 说明                            |
|--------------|----------------------------|-------------------------------|
| `id`         | `string`                   | 大模型返回的 `function calling` 的id |
| `name`       | `string`                   | `function`的名称                 |
| `arguments`  | Map\[`string`, `dynamic`\] | 大模型返回的参数map                   |

#### `event`为`functionCall`的`data`示例

- 对第三方opentool推送的`data`结构如下
  ```json
  { 
    "id":"call_abc123", 
    "name":"_ip_local_geo_v1_district", 
    "arguments":{} 
  }
  ```

### 11. 获取SimpleAgent一次性响应

**请求方法**: `POST`

**路径**: `/chat/simple`

**功能说明**: 发送一次请求获取SimpleAgent回复，不建立SSE连接。

#### 路径参数

| 字段名         | 类型       | 说明                                   |
|-------------|----------|--------------------------------------|
| `sessionId` | `string` | 通过`initSimple`接口获取到的会话ID           |

#### 路径示例

```http request
POST /chat/simple?sessionId=1901883204734947328
```

#### 请求参数

| 字段名               | 类型        | 说明                                                                                                                                                                              |
|-------------------|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `content`         | `array`   | 消息内容列表，数组中每个元素为 `object`                                                                                                                                                        |
| `content.type`    | `string`  | 消息类型，可选为 `text` `imageUrl`                                                                                                                                                      |
| `content.message` | `string`  | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |
| `isChunk`         | `boolean` | （可选）是否启用分片返回（对SimpleAgent一般不使用）                                                                                                                                                |
| `extraSystemPrompt` | `string` | （可选）追加到 Agent 基础 system prompt 的额外系统提示词（当前会话/任务生效）。                                                                                                             |

#### 请求示例

```json
{
  "content": [
    { "type": "text", "message":"你是谁？" }
  ],
  "extraSystemPrompt": "只回复一个整数即可。"
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名                                   | 类型       | 说明                                                                                                |
|--------------------------------------|----------|---------------------------------------------------------------------------------------------------|
| `sessionId`                          | `string` | 会话id                                                                                              |
| `taskId`                             | `string` | 任务id                                                                                              |
| `role`                               | `string` | 角色，可选值包括： `developer`、`user`、`agent`、`assistant`、`reflection`、`tool`、`client`                     |
| `to`                                 | `string` | 消息发送的目标，可选值包括与`role`一致                                                                            |
| `type`                               | `string` | 消息类型，可能包含的值有:`text`、`reasoning`、`imageUrl`、`contentList`、`toolCalls`、`reflection`、`toolReturn`、`functionCall` |
| `content`                            | `dynamic` | 消息内容                                                                                             |
| `completions`                        | `object` | （可选）大模型完成的详细信息，包含以下字段：                                                                            |
| `completions.usage`                  | `object` | token 使用信息                                                                                        |
| `completions.usage.promptTokens`     | `number` | 提示符 token 数                                                                                       |
| `completions.usage.completionTokens` | `number` | 生成 token 数                                                                                        |
| `completions.usage.totalTokens`      | `number` | 总 token 数                                                                                         |
| `completions.usage.contextUsageRatio` | `number` | 上下文占用比例（0~1），基于 `contextWindowSize` 计算；未配置时可能为 `null` |
| `completions.id`                     | `string` | 大模型返回的消息 ID                                                                                       |
| `completions.model`                  | `string` | 大模型名称，例如 gpt-4o-mini                                                                              |
| `completions.limits`                      | `object` | （可选）模型返回的限制信息（来自配置） |
| `completions.limits.maxTokens`            | `number` | 模型配置的最大输出 token 数 |
| `completions.limits.contextWindowSize`    | `number` | （可选）上下文窗口大小，用于计算上下文占用比例 |
| `createTime`                         | `string` | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ                                                               |

#### 响应示例

```json
{
  "sessionId":"1901883204734947328",
  "taskId":"1901883415867822080",
  "role":"assistant",
  "to":"agent",
  "type":"text",
  "content":"你好，我是LiteAgent。",
  "createTime":"2023-06-18T15:45:30.000+0800"
}
```

### 12. 响应FunctionCall结果

**请求方法**: `POST`

**路径**: `/callback`

**功能说明**: 客户端接收到FunctionCall要求后，调用此接口返回结果。

#### 路径参数

| 字段名         | 类型       | 说明        |
|-------------|----------|-----------|
| `sessionId` | `string` | 会话ID      |

#### 请求参数

| 字段名      | 类型                         |   | 说明                                      |
|----------|----------------------------|:--|-----------------------------------------|
| `id`     | `string`                   |   | 来自FunctionCall.id，用于对应返回的FunctionCall结果 |
| `result` | Map\[`string`, `dynamic`\] |   | 工具返回的结果map                              |


#### 请求示例

```json
{
  "id":"call_z5FK2dAfU8TXzn61IJXzRl5I",
  "result": {
    "status":"operate successfully."
  }
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名         | 类型       | 说明   |
|-------------|----------|------|
| `sessionId` | `string` | 会话ID |

### 13. 响应FunctionCall流式结果

**请求方法**: `POST`

**路径**: `/streamCallback`

**功能说明**: 客户端以流式方式返回FunctionCall结果。

#### 路径参数

| 字段名         | 类型       | 说明                                  |
|-------------|----------|-------------------------------------|
| `sessionId` | `string` | 会话ID                                |

#### 请求参数

| 字段名         | 类型       |   | 说明                                          |
|-------------|----------|:--|---------------------------------------------|
| `event`     | `string` |   | 流式事件名（如 `data`、`done`、`error`）        |
| `toolReturn` | `object` |   | 工具返回的结果，包含 `id` 和 `result` 字段         |

#### 请求示例

```json
{
  "event": "data",
  "toolReturn": {
    "id": "call_z5FK2dAfU8TXzn61IJXzRl5I",
    "result": {
      "status": "operate successfully."
    }
  }
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名         | 类型       | 说明   |
|-------------|----------|------|
| `sessionId` | `string` | 会话ID |

### 14. 获取历史消息

**请求方法**: `GET`

**路径**: `/history`

**功能说明**: 从持久化数据库获取某个会话的历史消息列表。即使 core 中的运行态 Session 已超时释放或 server 已重启，历史仍可查询。

#### 路径参数

| 字段名         | 类型       | 说明                     |
|-------------|----------|------------------------|
| `sessionId` | `string` | 会话 ID，读取对应Agent的当前会话历史 |
| `page` | `int` | （可选）分页页码，从 1 开始；必须与 `pageSize` 同时传入 |
| `pageSize` | `int` | （可选）每页条数；必须与 `page` 同时传入 |

#### 路径示例

```http request
GET /history?sessionId=1901883204734947328
```

分页示例：

```http request
GET /history?sessionId=1901883204734947328&page=1&pageSize=50
```

#### 响应

**状态码**: `200 OK`

**响应体**: `array`类型，对应的`ojbect`为：

| 字段名                                  | 类型       | 说明                                                                                               |
|--------------------------------------|----------|--------------------------------------------------------------------------------------------------|
| `sessionId`                          | `string` | 会话 ID，用于标识对应会话                                                                                   |
| `originalTaskId`                     | `string` | 原始任务 ID，用于关联子任务和工具调用                                                                          |
| `taskId`                             | `string` | 任务 ID，识别该任务                                                                                      |
| `parentTaskId`                       | `string` | （可选）父任务 ID                                                                                         |
| `role`                               | `string` | 消息来源，可能的值包括：`developer`、`user`、`agent`、`assistant`、`reflection`、`tool`、`client`                  |
| `to`                                 | `string` | 消息目标，可能的值与`role`一致                                                                               |
| `type`                               | `string` | 消息类型，可能的值包括：`text`、`reasoning`、`imageUrl`、`contentList`、`toolCalls`、`reflection`、`toolReturn`、`functionCall` |
| `content`                            | `any`    | 消息内容，具体类型需根据 `type` 字段解析                                                                         |
| `reasoningContent`                   | `string` | （可选）模型推理内容                                                                                         |
| `completions`                        | `object` | 大模型完成的详细信息，包含以下字段：                                                                               |
| `completions.usage`                  | `object` | Token 使用信息                                                                                       |
| `completions.usage.promptTokens`     | `number` | 提示符 token 数                                                                                      |
| `completions.usage.completionTokens` | `number` | 生成 token 数                                                                                       |
| `completions.usage.totalTokens`      | `number` | 总 token 数                                                                                        |
| `completions.usage.contextUsageRatio` | `number` | 上下文占用比例（0~1），基于 `contextWindowSize` 计算；未配置时可能为 `null` |
| `completions.id`                     | `string` | 大模型返回的消息 ID                                                                                      |
| `completions.model`                  | `string` | 大模型名称，例如 gpt-3.5-turbo                                                                           |
| `completions.limits`                      | `object` | （可选）模型返回的限制信息（来自配置） |
| `completions.limits.maxTokens`            | `number` | 模型配置的最大输出 token 数 |
| `completions.limits.contextWindowSize`    | `number` | （可选）上下文窗口大小，用于计算上下文占用比例 |
| `createTime`                         | `string` | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ                                                              |

#### 响应示例

```json
[
  {
    "sessionId": "1901883204734947328",
    "taskId": "1901883415867822080",
    "role": "developer",
    "to": "user",
    "type": "text",
    "content": "This is an example message",
    "completions": {
      "usage": {
        "promptTokens": 100,
        "completionTokens": 522,
        "totalTokens": 622,
        "contextUsageRatio": 0.15
      },
      "id": "chatcmpl-9bgYkOjpdtLV0o0JugSmnNzGrRFMG",
      "model": "gpt-3.5-turbo",
      "limits": {
        "maxTokens": 4096,
        "contextWindowSize": 128000
      }
    },
    "createTime": "2023-06-18T15:45:30.000+0800"
  }
]
```

### 15. 停止会话

**请求方法**: `GET`

**路径**: `/stop`

**功能说明**: 通过指定 `sessionId` 停止对应的会话操作。

#### 路径参数

| 字段名         | 类型       | 说明                                     |
|-------------|----------|----------------------------------------|
| `sessionId` | `string` | 会话 ID，用于标识需要停止的会话                      |
| `taskId`    | `string` | （可选）任务 ID，用于标识需要停止的任务，不传入责默认停止当前会话所有任务 |

#### 路径示例

- 停止整个会话
```http request
GET /stop?sessionId=1901883204734947328
```

- 停止会话中某个任务
```http request
GET /stop?sessionId=1901883204734947328&taskId=1901883415867822080
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名         | 类型       | 说明                   |
|-------------|----------|----------------------|
| `sessionId` | `string` | 会话 ID，用于确认停止的会话      |
| `taskId`    | `string` | 任务 ID， 如果停止的是任务，才会返回 |

#### 响应示例

```json
{
  "sessionId": "1901883204734947328",
  "taskId": "1901883415867822080"
}
```

### 16. 清除会话数据

**请求方法**: `GET`

**路径**: `/clear`

**功能说明**: 清除 core 运行态会话、持久化 Session 和对应消息，返回 sessionId，不支持 SimpleAgent。清除后该 sessionId 无法再恢复。

#### 路径参数

| 字段名         | 类型       | 说明                   |
|-------------|----------|----------------------|
| `sessionId` | `string` | 会话 ID，用于标识需要清除上下文的会话 |

#### 路径示例

```http request
GET /clear?sessionId=1901883204734947328
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名         | 类型       | 说明              |
|-------------|----------|-----------------|
| `sessionId` | `string` | 会话 ID，用于确认清除的会话 |

#### 响应示例

```json
{
    "sessionId": "1901883204734947328"
}
```

### 17. 获取会话列表

**请求方法**: `GET`

**路径**: `/session/list`

**功能说明**: 从持久化数据库根据 agentId 获取会话列表。列表不会因 core 空闲超时或 server 重启而消失。

#### 路径参数

| 字段名       | 类型       | 说明                     |
|-------------|----------|--------------------------|
| `agentId`   | `string` | Agent ID，用于筛选会话列表 |

#### 路径示例

```http request
GET /session/list?agentId=671763aae989ec22357fea88
```

#### 响应

**状态码**: `200 OK`

**响应体**: `array` 类型，对应的 `object` 为：

| 字段名        | 类型       | 说明                               |
|-------------|----------|----------------------------------|
| `sessionId` | `string` | 会话 ID                            |
| `agentId`   | `string` | （可选）Agent ID                   |
| `createTime`| `string` | 会话创建时间，ISO 8601 格式         |
| `topic`     | `string` | （可选）会话主题                    |

#### 响应示例

```json
[
  {
    "sessionId": "1901883204734947328",
    "agentId": "671763aae989ec22357fea88",
    "createTime": "2024-06-24T06:48:05.862057Z",
    "topic": "storage assistant"
  }
]
```

### 18. 订阅会话事件

**请求方法**: `GET`

**路径**: `/session/subscribe`

**功能说明**: 订阅指定会话的 SSE 事件，不会触发新的任务执行。

#### 路径参数

| 字段名       | 类型       | 说明                   |
|-------------|----------|------------------------|
| `sessionId` | `string` | 会话 ID，用于订阅事件    |

#### 响应流

- `Content-Type: text/event-stream`
- 事件类型：`message`、`chunk`
- `message` 事件携带 `AgentMessageDto` JSON
- `chunk` 事件携带 `AgentMessageChunkDto` JSON

## AgentMessage说明

### 1. `type`在不同类型下的`content`结构

- `type`为`text`、`reasoning`或`imageUrl`

| `type`     | content数据类型 | 说明  |
|------------|-------------|-----|
| `text`     | `string`    | 纯文本 |
| `reasoning` | `string`   | 在对应正文或工具调用消息之前发送的独立推理消息 |
| `imageUrl` | `string`    | 纯文本 |

- `type`为`functionCall`，类型为`object`，元素结构为：

| `type`       | content数据类型                | 说明                            |
|--------------|----------------------------|-------------------------------|
| `id`         | `string`                   | 大模型返回的 `function calling` 的id |
| `name`       | `string`                   | `function`的名称                 |
| `arguments`  | Map\[`string`, `dynamic`\] | 大模型返回的参数map                   |

- `type`为`toolCalls`，类型为`array`，元素结构为：

| `type`       | content数据类型                | 说明                            |
|--------------|----------------------------|-------------------------------|
| `id`         | `string`                   | 大模型返回的 `function calling` 的id |
| `name`       | `string`                   | `function`的名称                 |
| `arguments`  | Map\[`string`, `dynamic`\] | 大模型返回的参数map                   |

- `type`为`toolReturn`，类型为`object`，元素结构为：

| `type`   | content数据类型                | 说明                  |
|----------|----------------------------|---------------------|
| `id`     | `string`                   | 对应`functionCall.id` |
| `result` | Map\[`string`, `dynamic`\] | 工具返回的结果             |

- `type`为`contentList`，类型为`array`，元素结构为：

| `type`    | content数据类型 | 说明                                                                                                                                                                              |
|-----------|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`    | `string`    | 可选类型为`text`、`imageUrl`                                                                                                                                                          |
| `message` | `string`    | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接："https://example.com/path/to/image.png" ，且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |

- `type`为`reflection`，类型为`object`，元素结构为：

| `type`                                      | content数据类型 | 说明                                                                                                                                                                              |
|---------------------------------------------|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `isPass`                                    | `boolean`   | 反思是否通过                                                                                                                                                                          |
| `messageScore`                              | `object`    | 当次反思的原文及分数                                                                                                                                                                      |
| `messageScore.contentList`                  | `array`     | 记录用户的原始消息                                                                                                                                                                       |
| `messageScore.contentList.type`             | `string`    | 可选类型为`text`、`imageUrl`                                                                                                                                                          |
| `messageScore.contentList.message`          | `string`    | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接："https://example.com/path/to/image.png" ，且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |
| `messageScore.messageType`                  | `string`    | 可选类型为`text`、`functionCalling`                                                                                                                                                   |
| `messageScore.message`                      | `string`    | 根据messageType不同而不同                                                                                                                                                              |
| `messageScore.reflectScoreList`             | `array`     | 不同反思agent得到的分数的数组，元素类型为`object`                                                                                                                                                 |
| `messageScore.reflectScoreList.score`       | `int`       | 分数                                                                                                                                                                              |
| `messageScore.reflectScoreList.description` | `string`    | （可选）得分描述                                                                                                                                                                        |
| `passScore`                                 | `int`       | 合格的分数，默认为8                                                                                                                                                                      |
| `count`                                     | `int`       | 当前反思的迭代次数                                                                                                                                                                       |
| `maxCount`                                  | `int`       | 最大允许的反思迭代次数，默认为10                                                                                                                                                               |

- `type`为`taskStatus`，类型为`object`，元素结构为：

| `type`        | content数据类型                | 说明                                                              |
|---------------|----------------------------|-----------------------------------------------------------------|
| `status`      | `string`                   | 可选类型为`start`、`stop`、`done`、`toolsStart`、`toolsDone`、`exception` |
| `description` | Map\[`string`, `dynamic`\] | 消息的描述，一般为functionCall时、`exception`时有值                           |

### 2. `to`为`client`时，content的几个状态字符串

在`taskStatus.status`中：

- `"start"`: agent接收到来自`user`的`contentList`，准备处理
- `"stop"`: agent接收到`stop`或者`clear`指令，停止任务
- `"done"`: agent处理完成
- `"exception"`: 处理过程中发生异常
- `"toolsStart"`: 准备提交Tools执行
- `"toolsDone"`: Tools执行完毕
