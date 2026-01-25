# API for LiteAgent core Dart Server

[中文](API-zh_CN.md) · English

## Contents
- HTTP API
    - [/agent/list](#1-list-agents): List saved agents.
    - [/agent](#2-get-agent): Retrieve a saved agent by agentId.
    - [/agent/create](#3-create-agent): Create and persist an agent.
    - [/agent/update](#4-update-agent): Update an existing agent.
    - [/agent/delete](#5-delete-agent): Delete an agent.
    - [/version](#6-get-version): Retrieve the current version.
    - [/presetOpenSpecList](#7-set-preset-openspec-list): Set the preset OpenSpec list.
    - [/initSession](#8-initialize-sessionagent-session): Initialize a SessionAgent session and return a sessionId.
    - [/initSimple](#9-initialize-simpleagent-session): Initialize a SimpleAgent session.
    - [/chat](#10-start-session-stream): Start a task and stream SSE events.
    - [/chat/simple](#11-get-simpleagent-one-time-response): One-time response without SSE.
    - [/callback](#12-tool-callback): Return tool results for function calls.
    - [/streamCallback](#13-tool-stream-callback): Stream tool results for function calls.
    - [/history](#14-retrieve-message-history): Retrieve the history of messages for a session.
    - [/stop](#15-stop-session): Stop a session or task.
    - [/clear](#16-clear-session-data): Clear session data for a session.
    - [/opentool-list](#17-get-available-opentool-list): Retrieve the list of available OpenTools.
- AgentMessage Explanation
    - [Message Structure Based on `type`](#1-type-fields-content-structure-in-different-types)
    - [Message Status Strings when `to` is `client`](#2-status-strings-in-content-when-to-is-client)

## HTTP API

### Base URL

```http request
https://api.example.com/v1
```

### 1. List Agents

**Request Method**: `GET`

**Path**: `/agent/list`

**Description**: List saved agents.

#### Request Parameters

None

#### Response

**Status Code**: `200 OK`

**Response Body**: `array` of objects with the following fields:

| Field        | Type     | Description                                                             |
|--------------|----------|-------------------------------------------------------------------------|
| `agentId`    | `string` | Agent ID                                                                 |
| `name`       | `string` | Agent name                                                               |
| `capability` | `object` | Agent capability, same schema as the `/initSession` request body fields. |

#### Response Example

```json
[
  {
    "agentId": "671763aae989ec22357fea88",
    "name": "Agent Example",
    "capability": {
      "llmConfig": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "sk-xxxxxxxxxx",
        "model": "gpt-4o-mini"
      },
      "systemPrompt": "Roleplay as someone with specific abilities"
    }
  }
]
```

### 2. Get Agent

**Request Method**: `GET`

**Path**: `/agent`

**Description**: Retrieve a saved agent by agentId.

#### Query Parameters

| Field     | Type     | Description |
|-----------|----------|-------------|
| `agentId` | `string` | Agent ID    |

#### Example Request

```http request
GET /agent?agentId=671763aae989ec22357fea88
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field        | Type     | Description                                                             |
|--------------|----------|-------------------------------------------------------------------------|
| `name`       | `string` | Agent name                                                               |
| `capability` | `object` | Agent capability, same schema as the `/initSession` request body fields. |

#### Response Example

```json
{
  "name": "Agent Example",
  "capability": {
    "llmConfig": {
      "baseUrl": "https://api.openai.com/v1",
      "apiKey": "sk-xxxxxxxxxx",
      "model": "gpt-4o-mini"
    },
    "systemPrompt": "Roleplay as someone with specific abilities"
  }
}
```

### 3. Create Agent

**Request Method**: `POST`

**Path**: `/agent/create`

**Description**: Create and persist an agent.

#### Request Body

| Field        | Type     | Description                                                             |
|--------------|----------|-------------------------------------------------------------------------|
| `name`       | `string` | Agent name                                                               |
| `capability` | `object` | Agent capability, same schema as the `/initSession` request body fields. |

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field     | Type     | Description           |
|-----------|----------|-----------------------|
| `agentId` | `string` | Generated agent ID    |

#### Response Example

```json
{
  "agentId": "671763aae989ec22357fea88"
}
```

### 4. Update Agent

**Request Method**: `POST`

**Path**: `/agent/update`

**Description**: Update an existing agent.

#### Query Parameters

| Field     | Type     | Description |
|-----------|----------|-------------|
| `agentId` | `string` | Agent ID    |

#### Request Body

| Field        | Type     | Description                                                             |
|--------------|----------|-------------------------------------------------------------------------|
| `name`       | `string` | Agent name                                                               |
| `capability` | `object` | Agent capability, same schema as the `/initSession` request body fields. |

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field     | Type     | Description           |
|-----------|----------|-----------------------|
| `agentId` | `string` | Updated agent ID      |

#### Response Example

```json
{
  "agentId": "671763aae989ec22357fea88"
}
```

### 5. Delete Agent

**Request Method**: `GET`

**Path**: `/agent/delete`

**Description**: Delete an agent.

#### Query Parameters

| Field     | Type     | Description |
|-----------|----------|-------------|
| `agentId` | `string` | Agent ID    |

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field     | Type     | Description        |
|-----------|----------|--------------------|
| `agentId` | `string` | Deleted agent ID   |

#### Response Example

```json
{
  "agentId": "671763aae989ec22357fea88"
}
```

### 6. Get Version

**Request Method**: `GET`

**Endpoint**: `/version`

**Description**: Retrieve the current version.

#### Request Parameters

None

#### Request Example

None

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field     | Type     | Description                      |
|-----------|----------|----------------------------------|
| `version` | `string` | Version number in "a.b.c" format |

#### Response Example

```json
{
    "version": "0.3.0"
}
```

### 7. Set Preset OpenSpec List

**Request Method**: `POST`

**Path**: `/presetOpenSpecList`

**Description**: Set the server-wide preset OpenSpec list. Presets apply to subsequent `initSession` and `initSimple` calls: each `systemPrompt` is appended to the session system prompt, and each `openSpec` is loaded as tools.

#### Request Body

**Body**: `array` of objects (or a single object), each with:

| Field         | Type     | Description                                                                 |
|---------------|----------|-----------------------------------------------------------------------------|
| `systemPrompt`| `string` | Required. System prompt fragment to append.                                 |
| `openSpec`    | `object` | (Optional) OpenSpec definition. Same schema as `/initSession` `openSpecList` items. |

#### Request Example

```json
[
  {
    "systemPrompt": "Always respond in concise bullets."
  },
  {
    "systemPrompt": "You can call the Weather API when needed.",
    "openSpec": {
      "openSpec": "<OpenAPI JSON string>",
      "protocol": "openapi"
    }
  }
]
```

#### Response

**Status Code**: `200 OK`

**Response Body**: `{}`

### 8. Initialize SessionAgent Session

**Request Method**: `POST`

**Path**: `/initSession`

**Description**: Initialize a SessionAgent session and return a sessionId. Provide either `agentId` or a request body with `CapabilityDto`.

#### Query Parameters

| Field     | Type     | Description                                                         |
|-----------|----------|---------------------------------------------------------------------|
| `agentId` | `string` | (Optional) Use a saved agent configuration for this session.        |

#### Request Body (when `agentId` is not provided)

| Field                                     | Type      | Description                                                                                                                                                                                                                                                      |
|-------------------------------------------|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `llmConfig`                               | `object`  | Configuration for the language model, containing the following fields:                                                                                                                                                                                           |
| `llmConfig.baseUrl`                       | `string`  | API endpoint of the language model provider, e.g., https://api.openai.com/v1                                                                                                                                                                                     |
| `llmConfig.apiKey`                        | `string`  | API Key of the language model provider, e.g., sk-xxxxxxxxxx                                                                                                                                                                                                      |
| `llmConfig.model`                         | `string`  | Name of the language model, e.g., gpt-3.5-turbo                                                                                                                                                                                                                  |
| `llmConfig.temperature`                   | `number`  | (Optional) Temperature value, default is 0                                                                                                                                                                                                                       |
| `llmConfig.maxTokens`                     | `number`  | (Optional) Maximum token count, default is 4096                                                                                                                                                                                                                  |
| `llmConfig.topP`                          | `number`  | (Optional) Top-p value for sampling, default is 1                                                                                                                                                                                                                |
| `llmConfig.supportsToolCalling`           | `boolean` | (Optional) Whether the model supports tool calling, default is true                                                                                                                                                                                              |
| `llmConfig.supportsDeepThinking`          | `boolean` | (Optional) Whether the model supports deep thinking, default is false                                                                                                                                                                                            |
| `systemPrompt`                            | `string`  | System prompt preset, e.g., role-playing instructions, abilities, or problem-solving tasks                                                                                                                                                                       |
| `openSpecList`                            | `array`   | (Optional) List of specifications, each element being an `object`                                                                                                                                                                                                |
| `openSpecList.openSpec`                   | `string`  | JSON description of the spec                                                                                                                                                                                                                                     |
| `openSpecList.protocol`                   | `string`  | Supports `openapi`, `jsonrpcHttp`, `opentool`, `mcpStdio`, `mcpHttp`                                                                                                                                                                                              |
| `openSpecList.serverUrl`                  | `string`  | (Optional) Override server URL for the spec                                                                                                                                                                                                                      |
| `openSpecList.apiKey`                     | `object`  | (Optional) API Key for third-party services                                                                                                                                                                                                                      |
| `openSpecList.apiKey.type`                | `string`  | Either `basic` or `bearer`                                                                                                                                                                                                                                       |
| `openSpecList.apiKey.apiKey`              | `string`  | API Key value                                                                                                                                                                                                                                                    |
| `callbackOpenTool`                        | `object`  | (Optional) Client callback tool definition                                                                                                                                                                                                                       |
| `callbackOpenTool.opentool`               | `string`  | OpenTool JSON definition                                                                                                                                                                                                                                         |
| `callbackOpenTool.timeout`                | `number`  | (Optional) Callback timeout in seconds                                                                                                                                                                                                                           |
| `sessionList`                             | `array`   | (Optional) List of sessions, each element being an `object`                                                                                                                                                                                                      |
| `sessionList.sessionId`                   | `string`  | sessionId of a sub-agent                                                                                                                                                                                                                                         |
| `sessionList.name`                        | `string`  | (Optional) Sub Agent custom name. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.                                                                                                                                         |
| `sessionList.description`                 | `string`  | (Optional) Sub Agent description                                                                                                                                                                                                                                 |
| `reflectPromptList`                       | `array`   | (Optional) List of ReflectPrompt, where each element in the array is an `object`. **if `openSpecList` is null, reflect LLM text, else reflect Function Calling**                                                                                                 |
| `reflectPromptList.llmConfig`             | `object`  | `ReflectAgent`'s `llmConfig`, used for requesting large models.                                                                                                                                                                                                  |
| `reflectPromptList.prompt`                | `string`  | System Prompt of `ReflectAgent`, used to describe the evaluation criteria for reflection scores.                                                                                                                                                                 |
| `timeoutSeconds`                          | `number`  | (Optional) Timeout duration, defaults to 3600 seconds.                                                                                                                                                                                                           |
| `taskPipelineStrategy`                    | `enum`    | (Optional) Strategy for handling new task instructions within the same session. Supports: `parallel`, `serial`, or `reject`. Defaults to `parallel`.                                                                                                            |
| `toolPipelineStrategy`                    | `enum`    | (Optional) Strategy for handling tool execution when function calling returns an array. Supports: `parallel`, `serial`, or `reject`.                                                                                                                             |
| `auto`                                    | `boolean` | (Optional) Whether to auto-run tasks                                                                                                                                                                                                                             |
| `llmConfigList`                           | `array`   | (Optional) List of `llmConfig` objects                                                                                                                                                                                                                            |
| `enableThinking`                          | `boolean` | (Optional) Enable reasoning output                                                                                                                                                                                                                                |

#### Request Example

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
  "systemPrompt": "Roleplay as someone with specific abilities to help solve certain problems",
  "openSpecList": [
    {
      "openSpec": "<JSON description of the spec, supports openapi, jsonrpcHttp, opentool>",
      "apiKey": {
        "type": "bearer",
        "apiKey": "sk-xxxxxxxxxxxxxxxx"
      },
      "protocol": "openapi"
    },
    {
      "openSpec": "<Another spec's JSON description, different types can be mixed>",
      "protocol": "jsonrpcHttp"
    }
  ],
  "sessionList": [
    {
      "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
      "name": "someFunc1"
    },
    {
      "sessionId": "a20245f2-e9f0-416c-9191-8ed3afeac46b",
      "name": "some-func_2"
    }
  ],
  "timeoutSeconds": 7200
}
 ```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field       | Type     | Description                                             |
|-------------|----------|---------------------------------------------------------|
| `sessionId` | `string` | Session ID, a unique identifier generated by the system |

#### Response Example

```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 9. Initialize SimpleAgent Session

**Request Method**: `POST`

**Path**: `/initSimple`

**Description**: Initialize a SimpleAgent session. SimpleAgent does not require SSE streaming, and subsequent requests to [/chat/simple](#11-get-simpleagent-one-time-response) return a single response.

#### Request Body

| Field                             | Type      | Description                                                                                |
|-----------------------------------|-----------|--------------------------------------------------------------------------------------------|
| `llmConfig`                       | `object`  | Configuration for the language model, containing the following fields:                     |
| `llmConfig.baseUrl`               | `string`  | API endpoint of the language model provider, e.g., https://api.openai.com/v1               |
| `llmConfig.apiKey`                | `string`  | API Key of the language model provider, e.g., sk-xxxxxxxxxx                                |
| `llmConfig.model`                 | `string`  | Name of the language model, e.g., gpt-3.5-turbo                                            |
| `llmConfig.temperature`           | `number`  | (Optional) Temperature value, default is 0                                                 |
| `llmConfig.maxTokens`             | `number`  | (Optional) Maximum token count, default is 4096                                            |
| `llmConfig.topP`                  | `number`  | (Optional) Top-p value for sampling, default is 1                                          |
| `llmConfig.supportsToolCalling`   | `boolean` | (Optional) Whether the model supports tool calling, default is true                        |
| `llmConfig.supportsDeepThinking`  | `boolean` | (Optional) Whether the model supports deep thinking, default is false                      |
| `systemPrompt`                    | `string`  | System prompt preset, e.g., role-playing instructions, abilities, or problem-solving tasks |

#### Request Example

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
    "systemPrompt": "Roleplay as someone with specific abilities to help solve certain problems"
}
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field       | Type     | Description                                             |
|-------------|----------|---------------------------------------------------------|
| `sessionId` | `string` | Session ID, a unique identifier generated by the system |

#### Response Example

```json
{
    "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 10. Start Session Stream

**Request Method**: `POST`

**Path**: `/chat`

**Description**: Submit a user task and stream Agent messages via SSE.

#### Query Parameters

| Field       | Type     | Description                                              |
|-------------|----------|----------------------------------------------------------|
| `sessionId` | `string` | Session ID used to start the corresponding SessionAgent. |

#### Request Body

| Field             | Type      | Description                                                                                                                                                                                                 |
|-------------------|-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `content`         | `array`   | List of message contents. Each element in the array is an `object`.                                                                                                                                         |
| `content.type`    | `string`  | Message type, can be `text` or `imageUrl`.                                                                                                                                                                  |
| `content.message` | `string`  | Message content, e.g., "Give me a random number"; <br/>If the message type is imageUrl, the message string can be:<br/>1. Image link (publicly accessible)<br/>2. Base64 format: "data:image/jpeg;base64,{base64 encoded image}" |
| `isChunk`         | `boolean` | (Optional) When true, the server emits `chunk` events for streamed assistant output.                                                                                                                        |

#### Request Example

```json
{
  "content": [
    {
      "type": "text",
      "message": "Give me a random number"
    }
  ],
  "isChunk": true
}
```

#### Response Stream

- `Content-Type: text/event-stream`
- Event types: `message`, `chunk`, `functionCall`
- `message` and `functionCall` events carry `AgentMessageDto` JSON
- `chunk` events carry `AgentMessageChunkDto` JSON
- See [AgentMessage Explanation](#agentmessage-explanation) for payload structures.

### 11. Get SimpleAgent One-time Response

**Request Method**: `POST`

**Path**: `/chat/simple`

**Description**: Obtain a one-time response from a large model by sending a request-response.

#### Query Parameters

| Field       | Type   | Description                                              |
|-------------|--------|----------------------------------------------------------|
| `sessionId` | string | Session ID used to trigger the corresponding SimpleAgent |

#### Path Example

```http request
POST /chat/simple?sessionId=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Request Body

| Field             | Type      | Description                                                                                                                                                                                                                                                               |
|-------------------|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `content`         | `array`   | List of message contents. Each element in the array is an `object`.                                                                                                                                                                                                       |
| `content.type`    | `string`  | Message type, can be `text` or `imageUrl`.                                                                                                                                                                                                                                |
| `content.message` | `string`  | Message content, e.g., "Give me a random number"; <br/>If the message type is imageUrl, the message string can be:<br/>1. Image link (publicly accessible)<br/>2. Base64 format: "data:image/jpeg;base64,{base64 encoded image}" |
| `isChunk`         | `boolean` | (Optional) When true, the server emits `chunk` events for streamed assistant output.                                                                                                                                                                                      |

#### Request Example

```json
{
  "content": [
    {
      "type": "text",
      "message": "Give me a random number"
    }
  ]
}
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field Name                                | Type   | Description                                                                       |
|-------------------------------------------|--------|-----------------------------------------------------------------------------------|
| `sessionId`                               | string | Session ID, a unique identifier generated by the system                           |
| `taskId`                                  | string | Task ID, identifies the task                                                      |
| `role`                                    | string | Message source role                                                               |
| `to`                                      | string | Message target, fixed as `agent`                                                  |
| `type`                                    | string | Message type, fixed as `text`                                                     |
| `content`                                 | string | The returned message content                                                      |
| `completions`                             | object | Detailed information about the model completion, containing the following fields: |
| `completions.usage`                  | object | Token usage information                                                           |
| `completions.usage.promptTokens`     | number | Number of prompt tokens                                                           |
| `completions.usage.completionTokens` | number | Number of completion tokens                                                       |
| `completions.usage.totalTokens`      | number | Total number of tokens                                                            |
| `completions.id`                          | string | Message ID returned by the model                                                  |
| `completions.model`                       | string | Model name, e.g., gpt-3.5-turbo                                                   |
| `createTime`                              | string | Message creation time in the format yyyy-MM-ddTHH:mm:ss.SSSZ                      |

#### Response Example

```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
  "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
  "role": "llm",
  "to": "agent",
  "type": "text",
  "content": "message info",
  "completions": {
    "usage": {
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

### 12. Tool Callback

**Request Method**: `POST`

**Path**: `/callback`

**Description**: Submit tool results for a function call in a session.

#### Query Parameters

| Field       | Type     | Description                  |
|-------------|----------|------------------------------|
| `sessionId` | `string` | Session ID for the callback  |

#### Request Body

| Field     | Type                         | Description                                      |
|-----------|------------------------------|--------------------------------------------------|
| `id`      | `string`                     | Function call ID to match the original request   |
| `result`  | Map\[`string`, `dynamic`\]   | Tool execution result payload                    |

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field       | Type     | Description       |
|-------------|----------|-------------------|
| `sessionId` | `string` | Session ID        |

#### Response Example

```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 13. Tool Stream Callback

**Request Method**: `POST`

**Path**: `/streamCallback`

**Description**: Stream tool results for a function call in a session.

#### Query Parameters

| Field       | Type     | Description                                  |
|-------------|----------|----------------------------------------------|
| `sessionId` | `string` | Session ID for the stream callback           |

#### Request Body

| Field         | Type      | Description                                              |
|---------------|-----------|----------------------------------------------------------|
| `event`       | `string`  | Stream event name (e.g., `data`, `done`, `error`)         |
| `toolReturn`  | `object`  | Tool return payload containing `id` and `result` fields  |

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field       | Type     | Description       |
|-------------|----------|-------------------|
| `sessionId` | `string` | Session ID        |

#### Response Example

```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 14. Retrieve Message History

**Request Method**: `GET`

**Path**: `/history`

**Description**: Retrieve the history of messages for a specific session. This API does not support SimpleAgent.

#### Query Parameters

| Field       | Type   | Description                                                |
|-------------|--------|------------------------------------------------------------|
| `sessionId` | string | Session ID used to read the history of the current session |

#### Path Example

```http request
GET /history?sessionId=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Response

**Status Code**: `200 OK`

**Response Body**: An `array` of objects with the following structure:

| Field Name                                | Type   | Description                                                                                           |
|-------------------------------------------|--------|-------------------------------------------------------------------------------------------------------|
| `sessionId`                               | string | Session ID used to identify the session                                                               |
| `taskId`                                  | string | Task ID identifying the task                                                                          |
| `role`                                    | string | Message source, possible values: `system`, `user`, `agent`, `llm`, `tool`                             |
| `to`                                      | string | Message target, possible values: `user`, `agent`, `llm`, `tool`, `client`                             |
| `type`                                    | string | Message type, possible values: `text`, `imageUrl`, `contentList`, `functionCall`, `toolCalls`, `toolReturn`, `reflection`, `taskStatus` |
| `content`                                 | any    | Message content, its type depends on the `type` field                                                 |
| `completions`                             | object | Detailed information about the model completion, containing the following fields:                     |
| `completions.usage`                  | object | Token usage information                                                                               |
| `completions.usage.promptTokens`     | number | Number of prompt tokens                                                                               |
| `completions.usage.completionTokens` | number | Number of completion tokens                                                                           |
| `completions.usage.totalTokens`      | number | Total number of tokens                                                                                |
| `completions.id`                          | string | Message ID returned by the model                                                                      |
| `completions.model`                       | string | Model name, e.g., gpt-3.5-turbo                                                                       |
| `createTime`                              | string | Message creation time in the format yyyy-MM-ddTHH:mm:ss.SSSZ                                          |

#### Response Example

```json
[
  {
    "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
    "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
    "role": "system",
    "to": "user",
    "type": "text",
    "content": "This is an example message",
    "completions": {
      "usage": {
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

### 15. Stop Session

**Request Method**: `GET`

**Path**: `/stop`

**Description**: Stops the specified session by sessionId. This API does not support SimpleAgent.

#### Query Parameters

| Field       | Type     | Description                                                                                                         |
|-------------|----------|---------------------------------------------------------------------------------------------------------------------|
| `sessionId` | `string` | Session ID to identify the session to stop                                                                          |
| `taskId`    | `string` | (Optional) Task ID to identify the task to stop. If not provided, all tasks of the current session will be stopped. |

#### Example Request

```http request
GET /stop?sessionId=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field       | Type     | Description                                  |
|-------------|----------|----------------------------------------------|
| `sessionId` | `string` | Session ID to confirm the stopped session    |
| `taskId`    | `string` | (Optional) Task ID if a specific task was stopped |

#### Example Response

```json
{
    "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 16. Clear Session Data

**Request Method**: `GET`

**Path**: `/clear`

**Description**: Clear the session data, returning the corresponding sessionId. This API does not support SimpleAgent.

#### Query Parameters

| Field       | Type     | Description                                  |
|-------------|----------|----------------------------------------------|
| `sessionId` | `string` | Session ID to identify the session to clear  |

#### Example Request

```http request
GET /clear?sessionId=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field       | Type     | Description                                  |
|-------------|----------|----------------------------------------------|
| `sessionId` | `string` | Session ID to confirm the cleared session    |

#### Example Response

```json
{
    "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 17. Get Available OpenTool List

**Request Method**: `GET`

**Path**: `/opentool-list`

**Description**: Retrieve the list of currently supported OpenTools.

#### Request Parameters

None

#### Response

**Status Code**: `200 OK`

**Response Body**: Type `array`, where each element is an `object` with the following fields:

| Field Name    | Type     | Description                                                                                                      |
|---------------|----------|------------------------------------------------------------------------------------------------------------------|
| `openToolId`  | `string` | The ID of the callable OpenTool, used in `/initSession` with an `opentool` spec.                                  |
| `description` | `string` | Description of the OpenTool.                                                                                     |

#### Response Example

```json
  [
    {
      "openToolId": "mock-tool",
      "description": "A Mock CRUD Sample Tool"
    }
  ]
```

## AgentMessage Explanation

### 1. `type` field's `content` structure in different types

| `type` or Element Field                                | Data Type of `content` or Element Field | Description                                                                                                                                                                                                                                                                                       |
|--------------------------------------------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1. `text`                                              | `string`                                | Plain text.                                                                                                                                                                                                                                                                                       |
| 2. `imageUrl`                                          | `string`                                | Plain text, can be either an image URL or base64 format.                                                                                                                                                                                                                                          |
| 3. `functionCall`                                      | `object`                                | Single function call returned by the model.                                                                                                                                                                                                                                                       |
| `functionCall.id`                                      | `string`                                | The function call ID returned by the model.                                                                                                                                                                                                                                                       |
| `functionCall.name`                                    | `string`                                | The name of the `function`.                                                                                                                                                                                                                                                                       |
| `functionCall.arguments`                               | Map\[`string`, `dynamic`\]              | Argument map returned by the model.                                                                                                                                                                                                                                                               |
| 4. `toolCalls`                                         | `array`                                 | Array of function calls returned by the model.                                                                                                                                                                                                                                                    |
| `toolCalls.id`                                         | `string`                                | The function call ID returned by the model.                                                                                                                                                                                                                                                       |
| `toolCalls.name`                                       | `string`                                | The name of the `function`.                                                                                                                                                                                                                                                                       |
| `toolCalls.arguments`                                  | Map\[`string`, `dynamic`\]              | Argument map returned by the model.                                                                                                                                                                                                                                                               |
| 5. `toolReturn`                                        | `object`                                | Result returned by the tool.                                                                                                                                                                                                                                                                      |
| `toolReturn.id`                                        | `string`                                | Corresponds to `functionCall.id`.                                                                                                                                                                                                                                                                 |
| `toolReturn.result`                                    | Map\[`string`, `dynamic`\]              | Result returned by the tool.                                                                                                                                                                                                                                                                      |
| 6. `contentList`                                       | `array`                                 | User's message array, where each element is of `object` type.                                                                                                                                                                                                                                     |
| `contentList.type`                                     | `string`                                | Possible types are `text`, `imageUrl`.                                                                                                                                                                                                                                                            |
| `contentList.message`                                  | `string`                                | Message content, e.g., "Give me a random number"; <br/> If the message type is `imageUrl`, the message's String can be: <br/> 1. Image URL: "https://example.com/path/to/image.png", and ensure it's publicly accessible <br/> 2. Base64 format: "data:image/jpeg;base64,{Base64 encoded image}". |
| 7. `reflection`                                        | `object`                                | Reflection result.                                                                                                                                                                                                                                                                                |
| `reflection.isPass`                                    | `boolean`                               | Indicates whether the reflection passed.                                                                                                                                                                                                                                                          |
| `reflection.messageScore`                              | `object`                                | The original content and score of the current reflection.                                                                                                                                                                                                                                         |
| `reflection.messageScore.contentList`                  | `array`                                 | Same as point 5, records the user's original messages.                                                                                                                                                                                                                                            |
| `reflection.messageScore.messageType`                  | `string`                                | Possible types: `text`, `functionCalling`.                                                                                                                                                                                                                                                        |
| `reflection.messageScore.message`                      | `string`                                | Content varies based on `messageType`.                                                                                                                                                                                                                                                            |
| `reflection.messageScore.reflectScoreList`             | `array`                                 | Array of scores obtained from different reflection agents, each element is an `object`.                                                                                                                                                                                                           |
| `reflection.messageScore.reflectScoreList.score`       | `int`                                   | The score.                                                                                                                                                                                                                                                                                        |
| `reflection.messageScore.reflectScoreList.description` | `string`                                | (Optional) Score description.                                                                                                                                                                                                                                                                     |
| `reflection.passScore`                                 | `int`                                   | Passing score, defaults to 8.                                                                                                                                                                                                                                                                     |
| `reflection.count`                                     | `int`                                   | The current iteration count of reflection.                                                                                                                                                                                                                                                        |
| `reflection.maxCount`                                  | `int`                                   | The maximum allowed iteration count for reflection, defaults to 10.                                                                                                                                                                                                                               |
| 8. `taskStatus`                                        | `object`                                | Task status payload.                                                                                                                                                                                                                                                                              |
| `taskStatus.status`                                    | `string`                                | Possible types: `start`, `stop`, `done`, `exception`.                                                                                                                                                                                                                                             |
| `taskStatus.taskId`                                    | `string`                                | Current Task ID                                                                                                                                                                                                                                                                                   |
| `taskStatus.description`                               | Map\[`string`, `dynamic`\]              | Description of the message, generally provided when the status is `exception`.                                                                                                                                                                                                                    |

**Example of `text` type message**

```text
"Feature result: PASS"
```

**Example of `imageUrl` type message**

- Example 1, image URL:

```text
"https://example.com/path/to/image.png"
```

- Example 2, base64 format:

```
"data:image/jpeg;base64,{Base64 encoded image}"
```

**Example of `toolCalls` type message**

```json
[
    {
      "id":"call_z5FK2dAfU8TXzn61IJXzRl5I",
      "name":"SomeFunction",
      "arguments": {
        "operation":"result"
      }
    }
]
```

**Example of `toolReturn` type message**

```json
{
    "id":"call_z5FK2dAfU8TXzn61IJXzRl5I",
    "result": {
      "statusCode":200,
      "body":"{\"code\":200,\"message\":\"PASS\"}"
    }
}
```

**Example of `contentList` type message**

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

### 2. Status Strings in `content` when `to` is `client`

in `taskStatus.status`:

- `"start"`: Agent receives the user message and prepares to process it.
- `"toolsStart"`: Preparing to submit Tools for execution.
- `"toolsDone"`: Tools execution completed.
- `"stop"`: Agent receives a stop or clear command and stops the task.
- `"done"`: Agent has completed processing.
- `"exception"`: An exception occurred during processing.
