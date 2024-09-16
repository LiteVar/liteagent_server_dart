# API for LiteAgent core Dart Server

[English](API.md) · 中文

## 目录
- HTTP API
    - [/version](#1-获取版本)：获取当前版本。
    - [/init](#2-初始化sessionagent会话)：初始化SessionAgent会话，返回SessionId。
    - [/init/simple](#3-初始化simpleagent会话)：初始化一个SimpleAgent会话。SimpleAgent无需websocket，后续通过请求 `/chat/simple`，直接响应LLM返回的文本消息。
    - [/chat/simple](#4-获得SimpleAgent一次性响应)：通过发送一次性的请求-响应来获得大模型返回，无需订阅 WebSocket 消息。
    - [/history](#5-获取历史消息)：取某个会话的历史消息列表。该接口不支持 SimpleAgent。
    - [/stop](#6-停止会话)：通过指定 sessionId 停止对应的会话操作，此接口不支持 SimpleAgent。
    - [/clear](#7-清除会话数据)：清除会话数据，返回对应的 sessionId，不支持 SimpleAgent。
- WebSocket API
    - [客户端消息](#客户端消息)
      - [保持连接](#1-保持连接)
      - [用户消息](#2-用户消息)
    - [服务端消息](#服务端消息)
      - [保持连接的响应](#1-保持连接的响应)
      - [Agent消息](#2-agent消息)
- AgentMessage说明
  - [`type`在不同类型下的`message`结构](#1-type在不同类型下的message结构-)
  - [`to`为`client`时`message`的几个状态字符串](#2-to为client时message的几个状态字符串)

## HTTP API

### Base URL

```http request
https://api.example.com/v1
```

### 1. 获取版本

**请求方法**: `GET`

**路径**: `/version`

**功能说明**: 获取当前版本。

#### 请求参数

无

#### 请求示例

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
      "version": "0.3.0"
  }
```

### 2. 初始化SessionAgent会话

**请求方法**: `POST`

**路径**: `/init`

**功能说明**: 初始化SessionAgent会话，返回SessionId。

#### 请求参数

| 字段名                     | 类型       | 说明                                                         |
|-------------------------|----------|------------------------------------------------------------|
| `llmConfig`             | `object` | 大模型配置，包含以下字段：                                              |
| `llmConfig.baseUrl`     | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1                 |
| `llmConfig.apiKey`      | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx                            |
| `llmConfig.model`       | `string` | 大模型名称，例如：gpt-3.5-turbo                                     |
| `llmConfig.temperature` | `number` | （可选）温度值，默认为 0                                              |
| `llmConfig.maxTokens`   | `number` | （可选）最大 token 数，默认为 4096                                    |
| `llmConfig.topP`        | `number` | （可选）概率抽样的 p 值，默认为 1                                        |
| `systemPrompt`          | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题                    |
| `openSpecList`          | `array`  | （可选）Spec 列表，数组中每个元素为 `object`                              |
| `openSpecList.openSpec` | `string` | spec 的 JSON 描述文本，目前支持的类型是 `openapi`、`openmodbus`、`openrpc` |
| `openSpecList.apiKey`   | `object` | （可选）第三方服务的 API Key                                         |
| `openSpecList.type`     | `string` | `basic` 或 `bearer` 二选一                                     |
| `openSpecList.apiKey`   | `string` | 第三方服务的 API Key                                             |
| `openSpecList.protocol` | `string` | 目前支持 `openapi`、`openmodbus`、`jsonrpcHttp`                  |
| `sessionList`           | `array`  | （可选）Session 列表，数组中每个元素为 `object`                           |
| `sessionList.id`        | `string` | Sub Agent 的 sessionId                                      |
| `timeoutSeconds`        | `number` | （可选）超时时间，默认为3600，以秒为单位                                     |

#### 请求示例

```json
  {
    "llmConfig": {
      "baseUrl": "https://api.openai.com/v1",
      "apiKey": "sk-xxxxxxxxxx",
      "model": "gpt-4o-mini",
      "temperature": 0,
      "maxTokens": 4096,
      "topP": 1
    },
    "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决某某问题",
    "openSpecList": [
      {
        "openSpec": "<spec的json描述文本，目前支持的类型是openapi、openmodbus、openrpc>",
        "apiKey": {
          "type": "bearer",
          "apiKey": "sk-xxxxxxxxxxxxxxxx"
        },
        "protocol": "openapi"
      },
      {
        "openSpec": "<另一段spec的json描述，可以不同类型混用>",
        "protocol": "openmodbus"
      }
    ],
    "sessionList": [
      {
        "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
      },
      {
        "id": "a20245f2-e9f0-416c-9191-8ed3afeac46b"
      }
    ],
    "timeoutSeconds": 7200
  }
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名  | 类型       | 说明                                               |
|------|----------|--------------------------------------------------|
| `id` | `string` | 会话ID，系统生成的唯一标识符。用以后续对于该session的消息订阅、stop、clear操作 |

#### 响应示例

```json
{
  "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

## 3. 初始化SimpleAgent会话

**请求方法**: `POST`

**路径**: `/init/simple`

**功能说明**: 初始化一个SimpleAgent会话。SimpleAgent无需websocket，通过请求 [/chat/simple](#4-获得simpleagent一次性响应)，直接响应LLM返回的文本消息。

#### 请求参数

| 字段名                     | 类型       | 说明                                         |
|-------------------------|----------|--------------------------------------------|
| `llmConfig`             | `object` | 大模型配置，包含以下字段：                              |
| `llmConfig.baseUrl`     | `string` | 大模型厂商的 API 入口，例如：https://api.openai.com/v1 |
| `llmConfig.apiKey`      | `string` | 大模型厂商的 API Key，例如：sk-xxxxxxxxxx            |
| `llmConfig.model`       | `string` | 大模型名称，例如：gpt-3.5-turbo                     |
| `llmConfig.temperature` | `number` | （可选）温度值，默认为 0                              |
| `llmConfig.maxTokens`   | `number` | （可选）最大 token 数，默认为 4096                    |
| `llmConfig.topP`        | `number` | （可选）概率抽样的 p 值，默认为 1                        |
| `systemPrompt`          | `string` | 预置的系统提示词，例如扮演什么角色，具有什么能力，需要帮助用户解决哪一类的问题    |

#### 请求示例

```json
{
    "llmConfig": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "sk-xxxxxxxxxx",
        "model": "gpt-4o-mini",
        "temperature": 0,
        "maxTokens": 4096,
        "topP": 1
    },
    "systemPrompt": "扮演某某角色，具有某某能力，需要帮助用户解决某某问题"
}
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名  | 类型       | 说明                                   |
|------|----------|--------------------------------------|
| `id` | `string` | 会话ID，系统生成的唯一标识符。用以后续对于该session发送请求消息 |

#### 响应示例

```json
{
    "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 4. 获得SimpleAgent一次性响应

**请求方法**: `POST`

**路径**: `/chat/simple`

**功能说明**: 通过发送一次性的请求-响应来获得大模型返回，无需订阅 WebSocket 消息。

#### 路径参数

| 字段名      | 类型       | 说明                         |
|----------|----------|----------------------------|
| `id`     | `string` | 会话 ID，用于触发对应SimpleAgent的调用 |

#### 路径示例

```http request
POST /chat/simple?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### 请求参数

| 字段名                   | 类型       | 说明                                                                                                                                                                              |
|-----------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `taskId`              | `string` | （可选）用于识别 AgentMessage 来自于哪个任务，若不设置，则系统自行生成。                                                                                                                                     |
| `contentList`         | `array`  | 消息内容列表，数组中每个元素为 `object`                                                                                                                                                        |
| `contentList.type`    | `string` | 消息类型，可选为 `text` `imageUrl`                                                                                                                                                      |
| `contentList.message` | `string` | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接："https://example.com/path/to/image.png" ，且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |

#### 请求示例

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

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名                                       | 类型       | 说明                                  |
|-------------------------------------------|----------|-------------------------------------|
| `sessionId`                               | `string` | 会话 ID，系统生成的唯一标识符                    |
| `taskId`                                  | `string` | 任务 ID，识别该任务                         |
| `from`                                    | `string` | 消息来源，固定为 `llm`                      |
| `to`                                      | `string` | 消息目标，固定为 `agent`                    |
| `type`                                    | `string` | 消息类型，固定为 `text`                     |
| `message`                                 | `string` | 返回的消息内容                             |
| `completions`                             | `object` | 大模型完成的详细信息，包含以下字段：                  |
| `completions.tokenUsage`                  | `object` | Token 使用信息                          |
| `completions.tokenUsage.promptTokens`     | `number` | 提示符 token 数                         |
| `completions.tokenUsage.completionTokens` | `number` | 生成 token 数                          |
| `completions.tokenUsage.totalTokens`      | `number` | 总 token 数                           |
| `completions.id`                          | `string` | 大模型返回的消息 ID                         |
| `completions.model`                       | `string` | 大模型名称，例如 gpt-3.5-turbo              |
| `createTime`                              | `string` | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ |

#### 响应示例

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

### 5. 获取历史消息

**请求方法**: `GET`

**路径**: `/history`

**功能说明**: 获取某个会话的历史消息列表。该接口不支持 SimpleAgent。

#### 路径参数

| 字段名      | 类型       | 说明                     |
|----------|----------|------------------------|
| `id`     | `string` | 会话 ID，读取对应Agent的当前会话历史 |

#### 路径示例

```http request
GET /history?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### 响应

**状态码**: `200 OK`

**响应体**: `array`类型，对应的`ojbect`为：

| 字段名                                       | 类型       | 说明                                                                             |
|-------------------------------------------|----------|--------------------------------------------------------------------------------|
| `sessionId`                               | `string` | 会话 ID，用于标识对应会话                                                                 |
| `taskId`                                  | `string` | 任务 ID，识别该任务                                                                    |
| `from`                                    | `string` | 消息来源，可能的值包括：`system`、`user`、`agent`、`llm`、`tool`                               |
| `to`                                      | `string` | 消息目标，可能的值包括：`user`、`agent`、`llm`、`tool`、`client`                               |
| `type`                                    | `string` | 消息类型，可能的值包括：`text`、`imageUrl`、`functionCallList`、`toolReturn`、`contentList` 之一 |
| `message`                                 | `any`    | 消息内容，具体类型需根据 `type` 字段解析                                                       |
| `completions`                             | `object` | 大模型完成的详细信息，包含以下字段：                                                             |
| `completions.tokenUsage`                  | `object` | Token 使用信息                                                                     |
| `completions.tokenUsage.promptTokens`     | `number` | 提示符 token 数                                                                    |
| `completions.tokenUsage.completionTokens` | `number` | 生成 token 数                                                                     |
| `completions.tokenUsage.totalTokens`      | `number` | 总 token 数                                                                      |
| `completions.id`                          | `string` | 大模型返回的消息 ID                                                                    |
| `completions.model`                       | `string` | 大模型名称，例如 gpt-3.5-turbo                                                         |
| `createTime`                              | `string` | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ                                            |

#### 响应示例

```json
[
  {
    "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
    "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
    "from": "system",
    "to": "user",
    "type": "text",
    "message": "This is an example message",
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

### 6. 停止会话

**请求方法**: `GET`

**路径**: `/stop`

**功能说明**: 通过指定 sessionId 停止对应的会话操作，此接口不支持 SimpleAgent。

#### 路径参数

| 字段名      | 类型       | 说明                                     |
|----------|----------|----------------------------------------|
| `id`     | `string` | 会话 ID，用于标识需要停止的会话                      |
| `taskId` | `string` | （可选）任务 ID，用于标识需要停止的任务，不传入责默认停止当前会话所有任务 |

#### 路径示例

```http request
GET /stop?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名  | 类型       | 说明              |
|------|----------|-----------------|
| `id` | `string` | 会话 ID，用于确认停止的会话 |

#### 响应示例

```json
{
    "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 7. 清除会话数据

**请求方法**: `GET`

**路径**: `/clear`

**功能说明**: 清除会话数据，返回对应的 sessionId，不支持 SimpleAgent。

#### 路径参数

| 字段名      | 类型       | 说明                   |
|----------|----------|----------------------|
| `id`     | `string` | 会话 ID，用于标识需要清除上下文的会话 |

#### 路径示例

```http request
GET /clear?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### 响应

**状态码**: `200 OK`

**响应体**:

| 字段名  | 类型       | 说明              |
|------|----------|-----------------|
| `id` | `string` | 会话 ID，用于确认清除的会话 |

#### 响应示例

```json
{
    "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

## WebSocket API

### Endpoint

```http request
ws://127.0.0.1:9527/api/chat?id=<sessionId>
```

### 客户端消息

### 1. 保持连接

**功能说明**: 客户端向服务器发送保持连接请求，保持 WebSocket 通道。

**消息格式**: 纯文本`ping`

```text
"ping"
```

### 2. 用户消息

**功能说明**: 客户端向Agent服务发送用户消息请求

**消息格式**:

| 字段名                   | 类型       | 说明                                                                                                                                                                              |
|-----------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `taskId`              | `string` | 可选，用于识别AgentMessage来自于哪个任务，若不设置，则系统自行生成；不超过36个字符                                                                                                                                |
| `contentList`         | `array`  | 用户的消息数组，元素类型为`object`                                                                                                                                                           |
| `contentList.type`    | `string` | 消息类型，可能的值包括：`text`、`imageUrl`                                                                                                                                                   |
| `contentList.message` | `string` | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接："https://example.com/path/to/image.png" ，且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |

**消息示例**：

```json
{
  "taskId": "25afe7d5-998b-41cf-aebe-34950bd91f84",
  "contentList": [
    {
      "type": "text",
      "message": "帮我运行某某功能"
    }
  ]
}
```

### 服务端消息

### 1. 保持连接的响应

**功能说明**: 服务端向客户端发送保持连接的响应，保持 WebSocket 通道。

**消息格式**: 纯文本`pong`

```text
"pong"
```

### 2. Agent消息

**功能说明**: Agent系统持续推送当前会话生成的消息给客户端

**消息格式**:

| 字段名                                       | 类型       | 说明                                                                             |
|-------------------------------------------|----------|--------------------------------------------------------------------------------|
| `sessionId`                               | `string` | 会话 ID，用于标识对应会话                                                                 |
| `taskId`                                  | `string` | 任务 ID，识别该任务                                                                    |
| `from`                                    | `string` | 消息来源，可能的值包括：`system`、`user`、`agent`、`llm`、`tool`                               |
| `to`                                      | `string` | 消息目标，可能的值包括：`user`、`agent`、`llm`、`tool`、`client`                               |
| `type`                                    | `string` | 消息类型，可能的值包括：`text`、`imageUrl`、`functionCallList`、`toolReturn`、`contentList` 之一 |
| `message`                                 | `any`    | 消息内容，具体类型需根据 `type` 字段解析                                                       |
| `completions`                             | `object` | 大模型完成的详细信息，包含以下字段：                                                             |
| `completions.tokenUsage`                  | `object` | Token 使用信息                                                                     |
| `completions.tokenUsage.promptTokens`     | `number` | 提示符 token 数                                                                    |
| `completions.tokenUsage.completionTokens` | `number` | 生成 token 数                                                                     |
| `completions.tokenUsage.totalTokens`      | `number` | 总 token 数                                                                      |
| `completions.id`                          | `string` | 大模型返回的消息 ID                                                                    |
| `completions.model`                       | `string` | 大模型名称，例如 gpt-3.5-turbo                                                         |
| `createTime`                              | `string` | 消息创建时间，格式为 yyyy-MM-ddTHH:mm:ss.SSSZ                                            |

**消息示例**：

```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
  "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
  "from": "agent",
  "to": "llm",
  "type": "text",
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

## AgentMessage说明

### 1. `type`在不同类型下的`message`结构 

| `type` 或 元素字段                 | message或元素字段的数据类型          | 说明                                                                                                                                                                              |
|-------------------------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1. `text`                     | `string`                   | 纯文本                                                                                                                                                                             |
| 2. `imageUrl`                 | `string`                   | 纯文本，可以为 图片链接格式 或 base64格式                                                                                                                                                       |
| 3. `functionCallList`         | `array`                    | 大模型 `function calling` 返回的内容，元素类型为`object`                                                                                                                                      |
| `functionCallList.id`         | `string`                   | 大模型返回的 `function calling` 的id                                                                                                                                                   |
| `functionCallList.name`       | `string`                   | `function`的名称                                                                                                                                                                   |
| `functionCallList.parameters` | Map\[`string`, `dynamic`\] | 大模型返回的参数map                                                                                                                                                                     |
| 4. `toolReturn`               | `object`                   | 工具执行的返回                                                                                                                                                                         |
| `toolReturn.id`               | `string`                   | 对应`functionCallList.id`                                                                                                                                                         |
| `toolReturn.result`           | Map\[`string`, `dynamic`\] | 工具返回的结果                                                                                                                                                                         |
| 5. `contentList`              | `array`                    | 用户的消息数组，元素类型为`object`                                                                                                                                                           |
| `contentList.type`            | `string`                   | 可选类型为`text`、`imageUrl`                                                                                                                                                          |
| `contentList.message`         | `string`                   | 消息内容，例如："给我一个随机数"; <br/>如果消息类型为imageUrl，message的String可选为：<br/>1. 图片链接："https://example.com/path/to/image.png" ，且确保公网可访问<br/>2. base64格式："data:image/jpeg;base64,{图片的base64编码}" |

**`text`类型消息示例**

```text
"功能运行结果：PASS"
```

**`imageUrl`类型消息示例**

- 示例1，图片链接：

```text
"https://example.com/path/to/image.png"
```

- 示例2，base64格式文本：

```
"data:image/jpeg;base64,{图片的base64编码}"
```

**`functionCallList`类型消息示例**

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

**`toolReturn`类型消息示例**

```json
{
    "id":"call_z5FK2dAfU8TXzn61IJXzRl5I",
    "result": {
      "statusCode":200,
      "body":"{\"code\":200,\"message\":\"PASS\"}"
    }
}
```
**`contentList`类型消息示例**

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

### 2. `to`为`client`时，message的几个状态字符串：

- `"[TASK_START]"`：agent接收到user message，准备处理
- `"[TOOLS_START]"`: 准备提交Tools执行
- `"[TOOLS_DONE]"`: Tools执行完毕
- `"[TASK_STOP]"`：agent接收到stop或者clear指令，停止任务
- `"[TASK_DONE]"`：agent处理完成
