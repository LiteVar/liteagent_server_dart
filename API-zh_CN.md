# API for LiteAgent core Dart Server

[English](API.md) · 中文

版本：`1.0.1`

## 目录
- HTTP API
  - [/version](#1-获取版本)：获取当前服务器版本。
  - [/presetOpenSpecList](#2-设置预置openspec列表)：设置预置 OpenSpec 列表。
  - [/initSession](#3-初始化agent会话)：初始化SessionAgent会话，返回SessionId。
  - [/initSimple](#4-初始化simpleagent会话)：初始化SimpleAgent会话，返回SessionId。
  - [/chat](#5-提交用户消息订阅会话执行过程)：提交用户消息，订阅会话执行过程。
  - [/chat/simple](#6-获取simpleagent一次性响应)：发送一次请求获取SimpleAgent返回。
  - [/callback](#7-响应functioncall结果)：客户端接收到FunctionCall要求后，调用此接口返回结果。
  - [/streamCallback](#8-响应functioncall流式结果)：客户端以流式方式返回FunctionCall结果。
  - [/history](#9-获取历史消息)：取某个会话的历史消息列表。
  - [/history/summary](#91-获取历史任务摘要)：按任务分页获取轻量摘要。
  - [/history/process](#92-获取任务过程消息)：按需分页获取单个任务的过程消息。
  - [/stop](#10-停止会话)：通过指定 sessionId 停止对应的会话操作。
  - [/clear](#11-清除会话数据)：清除会话数据，返回对应的 sessionId。
  - [/session/subscribe](#12-订阅会话事件)：订阅指定会话的 SSE 事件。
- AgentMessage说明
  - [`type`在不同类型下的`content`结构](#1-type在不同类型下的content结构)
  - [`to`为`client`时`content`的几个状态字符串](#2-to为client时content的几个状态字符串)

## HTTP API

### Base URL

```http request
https://api.example.com/v1
```

### 1. 获取版本

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
      "version": "1.0.1"
  }
```

### 2. 设置预置OpenSpec列表

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

### 3. 初始化Agent会话

**请求方法**: `POST`

**路径**: `/initSession`

**功能说明**: 初始化SessionAgent会话，返回SessionId。

#### 请求参数

请求体为 `CapabilityDto`。

其中 `skills` 字段遵循 [Agent Skills Specification](https://agentskills.io/specification)。实践上，每个 skill 应是一个包含 `SKILL.md` 的目录，`SKILL.md` 由 YAML frontmatter 和 Markdown 正文组成；其中 `name` 要求为小写加连字符格式，`description` 为必填且非空。

执行限制字段适用于 `ToolAgent`、`MultiAgent` 和 `AutoMultiAgent`。超过大模型请求次数、工具轮数、工具调用总数或连续相同工具轮数限制时，任务以一个 `exception` 状态结束，状态描述中的 `code` 为 `tool_loop_limit_exceeded`；超过任务时长限制时，`code` 为 `task_execution_timeout`。

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

### 4. 初始化SimpleAgent会话

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

### 5. 提交用户消息，订阅会话执行过程

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
| `llmConfig`       | `object`  | （可选）本次请求使用的大模型配置。传入后仅覆盖本次请求，不会修改当前 session 的默认大模型配置。字段与 `/initSession` 的 `llmConfig` 相同，请传入完整配置，而不是只传需要修改的字段。 |
| `llmConfig.provider` | `string` | （可选）大模型 provider，目前支持 `openai` 和 `lite_oneapi`。 |
| `llmConfig.baseUrl` | `string` | 大模型厂商的 API 入口。 |
| `llmConfig.apiKey` | `string` | 大模型厂商的 API Key。 |
| `llmConfig.model` | `string` | 本次请求使用的大模型名称，例如：`gpt-4o-mini`。 |
| `llmConfig.adapter` | `string` | （可选）当 `provider=lite_oneapi` 时使用的上游协议/厂商适配器。 |
| `llmConfig.temperature` | `number` | （可选）温度值，默认为 0。 |
| `llmConfig.maxTokens` | `number` | （可选）最大 token 数，默认为 4096。 |
| `llmConfig.topP` | `number` | （可选）概率抽样的 p 值，默认为 1。 |
| `llmConfig.supportsToolCall` | `boolean` | （可选）模型是否支持工具调用，默认为 true。 |
| `llmConfig.supportsReasoning` | `boolean` | （可选）模型是否支持深度思考，默认为 false。 |

#### 请求示例

```json
{
  "content": [
    { "type": "text", "message":"你是谁？" }
  ],
  "isChunk": true,
  "extraSystemPrompt": "只回复一个整数即可。",
  "llmConfig": {
    "provider": "lite_oneapi",
    "baseUrl": "https://your-oneapi-server/v1",
    "apiKey": "sk-xxxxxxxxxx",
    "model": "qwen-plus",
    "adapter": "qwen"
  }
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
| `role`                               | `string`  | 角色，可选值包括： `developer`、`user`、`agent`、`assistant`、`tool`、`client`                     |
| `to`                                 | `string`  | 消息发送的目标，可选值包括与`role`一致                                                                            |
| `type`                               | `string`  | 消息类型，可能包含的值有:`text`、`reasoning`、`imageUrl`、`contentList`、`toolCalls`、`toolReturn`、`functionCall` |
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

### 6. 获取SimpleAgent一次性响应

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
| `llmConfig`       | `object`  | （可选）本次请求使用的大模型配置。传入后仅覆盖本次请求，不会修改当前 session 的默认大模型配置。字段与 `/initSimple` 的 `llmConfig` 相同，请传入完整配置，而不是只传需要修改的字段。 |
| `llmConfig.provider` | `string` | （可选）大模型 provider，目前支持 `openai` 和 `lite_oneapi`。 |
| `llmConfig.baseUrl` | `string` | 大模型厂商的 API 入口。 |
| `llmConfig.apiKey` | `string` | 大模型厂商的 API Key。 |
| `llmConfig.model` | `string` | 本次请求使用的大模型名称，例如：`gpt-4o-mini`。 |
| `llmConfig.adapter` | `string` | （可选）当 `provider=lite_oneapi` 时使用的上游协议/厂商适配器。 |
| `llmConfig.temperature` | `number` | （可选）温度值，默认为 0。 |
| `llmConfig.maxTokens` | `number` | （可选）最大 token 数，默认为 4096。 |
| `llmConfig.topP` | `number` | （可选）概率抽样的 p 值，默认为 1。 |
| `llmConfig.supportsToolCall` | `boolean` | （可选）模型是否支持工具调用，默认为 true。 |
| `llmConfig.supportsReasoning` | `boolean` | （可选）模型是否支持深度思考，默认为 false。 |

#### 请求示例

```json
{
  "content": [
    { "type": "text", "message":"你是谁？" }
  ],
  "extraSystemPrompt": "只回复一个整数即可。",
  "llmConfig": {
    "provider": "lite_oneapi",
    "baseUrl": "https://your-oneapi-server/v1",
    "apiKey": "sk-xxxxxxxxxx",
    "model": "qwen-plus",
    "adapter": "qwen"
  }
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名                                   | 类型       | 说明                                                                                                |
|--------------------------------------|----------|---------------------------------------------------------------------------------------------------|
| `sessionId`                          | `string` | 会话id                                                                                              |
| `taskId`                             | `string` | 任务id                                                                                              |
| `role`                               | `string` | 角色，可选值包括： `developer`、`user`、`agent`、`assistant`、`tool`、`client`                     |
| `to`                                 | `string` | 消息发送的目标，可选值包括与`role`一致                                                                            |
| `type`                               | `string` | 消息类型，可能包含的值有:`text`、`reasoning`、`imageUrl`、`contentList`、`toolCalls`、`toolReturn`、`functionCall` |
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

### 7. 响应FunctionCall结果

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

### 8. 响应FunctionCall流式结果

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

### 9. 获取历史消息

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
| `role`                               | `string` | 消息来源，可能的值包括：`developer`、`user`、`agent`、`assistant`、`tool`、`client`                  |
| `to`                                 | `string` | 消息目标，可能的值与`role`一致                                                                               |
| `type`                               | `string` | 消息类型，可能的值包括：`text`、`reasoning`、`imageUrl`、`contentList`、`toolCalls`、`toolReturn`、`functionCall` |
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

### 9.1. 获取历史任务摘要

**请求方法**：`GET`

**路径**：`/history/summary`

按 `originalTaskId` 聚合，每个任务返回一条摘要，并按任务创建时间倒序排列。分页单位是任务 turn，而不是单条消息。`page` 默认 `1`，`pageSize` 默认 `30`，且 `pageSize` 最大为 `200`。

```http request
GET /history/summary?sessionId=root-session&page=1&pageSize=30
```

查询参数 `sessionId` 是唯一可信的根会话边界。根用户消息必须具有相同 `sessionId`、`role=user`，且 `type` 为 `text` 或 `contentList`；最终回复取同一任务中时间最晚、发往 `user` 的根会话文本消息。终态只读取根会话的 `taskStatus`：根 `exception`/`error`/`failed` 为 `error`，根 `stop` 为 `stopped`，存在根最终回复或根 `done`/`complete`/`finished` 为 `done`，否则为 `running`。子 Agent 的完成或异常不会改变根任务状态和错误信息。

```json
[
  {
    "originalTaskId": "root-task-id",
    "sessionId": "root-session",
    "userMessage": {
      "sessionId": "root-session",
      "originalTaskId": "root-task-id",
      "taskId": "root-task-id",
      "role": "user",
      "to": "agent",
      "type": "text",
      "content": "总结报告",
      "createTime": "2026-07-12T10:00:00.000Z"
    },
    "finalMessage": {
      "sessionId": "root-session",
      "originalTaskId": "root-task-id",
      "taskId": "root-task-id",
      "role": "agent",
      "to": "user",
      "type": "text",
      "content": "报告摘要如下……",
      "createTime": "2026-07-12T10:00:05.000Z"
    },
    "status": "done",
    "error": null,
    "createdAt": "2026-07-12T10:00:00.000Z",
    "completedAt": "2026-07-12T10:00:05.000Z",
    "durationMs": 5000,
    "usage": {
      "promptTokens": 120,
      "completionTokens": 30,
      "totalTokens": 150,
      "contextUsageRatio": 0.12
    },
    "processMessageCount": 8
  }
]
```

`userMessage` 和 `finalMessage` 保留原始 `AgentMessageDto` JSON 结构。usage 优先取根最终回复，没有时取该任务最后一条包含 usage 的根消息。`processMessageCount` 不包含摘要中选中的根 user/final 消息。

### 9.2. 获取任务过程消息

**请求方法**：`GET`

**路径**：`/history/process`

按需返回单个任务的过程消息，包括关联子 Agent、工具调用、`toolReturn`、`reasoning` 和 `taskStatus`。摘要已经携带的根 user/final 消息不会重复返回。响应继续使用未改变的 `AgentMessageDto` JSON 数组，按 `createTime` 正序排列；时间相同时使用持久化消息 ID 作为稳定排序条件。

```http request
GET /history/process?sessionId=root-session&originalTaskId=root-task-id&page=1&pageSize=50
```

`page` 默认 `1`，`pageSize` 默认 `50`，且 `pageSize` 最大为 `200`。指定任务必须在查询根会话配置的会话树内，并且至少存在一条实际 `sessionId` 等于该根会话的消息。任务不存在或属于其他根会话时返回 `200 OK` 和空数组 `[]`；根会话不存在时返回 `404`。

```json
[
  {
    "sessionId": "child-session",
    "originalTaskId": "root-task-id",
    "taskId": "child-task-id",
    "role": "agent",
    "to": "client",
    "type": "taskStatus",
    "content": {"status": "start", "taskId": "child-task-id"},
    "createTime": "2026-07-12T10:00:01.000Z"
  }
]
```

### 10. 停止会话

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

### 11. 清除会话数据

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

### 12. 订阅会话事件

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
