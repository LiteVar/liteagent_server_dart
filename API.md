# API for LiteAgent core Dart Server

[中文](API-zh_CN.md) · English

## Contents
- HTTP API
    - [/version](#1-get-version): Retrieve the current version.
    - [/presetOpenSpecList](#2-set-preset-openspec-list): Set the preset OpenSpec list.
    - [/initSession](#3-initialize-sessionagent-session): Initialize a SessionAgent session and return a sessionId.
    - [/initSimple](#4-initialize-simpleagent-session): Initialize a SimpleAgent session.
    - [/chat](#5-start-session-stream): Start a task and stream SSE events.
    - [/chat/simple](#6-get-simpleagent-one-time-response): One-time response without SSE.
    - [/callback](#7-tool-callback): Return tool results for function calls.
    - [/streamCallback](#8-tool-stream-callback): Stream tool results for function calls.
    - [/history](#9-retrieve-message-history): Retrieve the history of messages for a session.
    - [/history/summary](#91-retrieve-history-turn-summaries): Retrieve one lightweight summary per task turn.
    - [/history/process](#92-retrieve-history-turn-process): Lazily retrieve process messages for one task turn.
    - [/stop](#10-stop-session): Stop a session or task.
    - [/clear](#11-clear-session-data): Clear session data for a session.
    - [/session/subscribe](#12-subscribe-session-events): Subscribe to session events via SSE.
- AgentMessage Explanation
    - [Message Structure Based on `type`](#1-type-fields-content-structure-in-different-types)
    - [Message Status Strings when `to` is `client`](#2-status-strings-in-content-when-to-is-client)

## HTTP API

### Base URL

```http request
https://api.example.com/v1
```

### 1. Get Version

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

### 2. Set Preset OpenSpec List

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

### 3. Initialize SessionAgent Session

**Request Method**: `POST`

**Path**: `/initSession`

**Description**: Initialize a SessionAgent session and return a sessionId.

#### Request Body: `CapabilityDto`

| Field                                     | Type      | Description                                                                                                                                                                                                                                                      |
|-------------------------------------------|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `llmConfig`                               | `object`  | Configuration for the language model, containing the following fields:                                                                                                                                                                                           |
| `llmConfig.provider`                      | `string`  | (Optional) LLM provider used by the server. Supported values are `openai` and `lite_oneapi`. If omitted, `lite_oneapi` is used.                                                                                                                             |
| `llmConfig.baseUrl`                       | `string`  | API endpoint of the language model provider, e.g., https://api.openai.com/v1                                                                                                                                                                                     |
| `llmConfig.apiKey`                        | `string`  | API Key of the language model provider, e.g., sk-xxxxxxxxxx                                                                                                                                                                                                      |
| `llmConfig.model`                         | `string`  | Name of the language model, e.g., gpt-3.5-turbo                                                                                                                                                                                                                  |
| `llmConfig.adapter`                       | `string`  | (Optional) Adapter name used when `provider=lite_oneapi` to choose which upstream protocol/provider adapter handles the request. Supported values are `openai`, `deepseek`, `glm`, `kimi`, `mimo`, `minimax`, and `qwen`. If omitted, the default is `openai`. |
| `llmConfig.temperature`                   | `number`  | (Optional) Temperature value, default is 0                                                                                                                                                                                                                       |
| `llmConfig.maxTokens`                     | `number`  | (Optional) Maximum token count, default is 4096                                                                                                                                                                                                                  |
| `llmConfig.topP`                          | `number`  | (Optional) Top-p value for sampling, default is 1                                                                                                                                                                                                                |
| `llmConfig.supportsToolCall`           | `boolean` | (Optional) Whether the model supports tool calling, default is true                                                                                                                                                                                              |
| `llmConfig.supportsReasoning`          | `boolean` | (Optional) Whether the model supports deep thinking, default is false                                                                                                                                                                                            |
| `systemPrompt`                            | `string`  | System prompt preset, e.g., role-playing instructions, abilities, or problem-solving tasks                                                                                                                                                                       |
| `skills`                                  | `array`   | (Optional) Skill reference list. Each item is a `string`. Referenced skills should follow the Agent Skills specification: https://agentskills.io/specification                                                                                                  |
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
| `subAgentList`                             | `array`  | (Optional) Inline sub-agent definitions; each item is an `AgentDto` and may recursively contain `subAgentList`. |
| `subAgentList.name`                        | `string` | Sub-agent name and function name. Must match `^[a-zA-Z0-9_-]{1,64}$`. |
| `subAgentList.capability`                  | `object` | Complete Capability configuration for the sub-agent. No sessionId is required; runtime session IDs are generated by core. |
| `timeoutSeconds`                          | `number`  | (Optional) Timeout duration, defaults to 3600 seconds.                                                                                                                                                                                                           |
| `taskPipelineStrategy`                    | `enum`    | (Optional) Strategy for handling new task instructions within the same session. Supports: `parallel`, `serial`, or `reject`. Defaults to `parallel`.                                                                                                            |
| `toolPipelineStrategy`                    | `enum`    | (Optional) Strategy for handling tool execution when function calling returns an array. Supports: `parallel`, `serial`, or `reject`.                                                                                                                             |
| `auto`                                    | `boolean` | (Optional) Whether to auto-run tasks                                                                                                                                                                                                                             |
| `llmConfigList`                           | `array`   | (Optional) List of `llmConfig` objects                                                                                                                                                                                                                            |
| `enableThinking`                          | `boolean` | (Optional) Enable reasoning output                                                                                                                                                                                                                                |
| `maxLlmRequests`                          | `number`  | (Optional) Maximum LLM requests per tool-enabled task. Defaults to 64. Non-positive values use the default.                                                                                                                                                       |
| `maxToolRounds`                           | `number`  | (Optional) Maximum function-calling rounds per task. Defaults to 16. Non-positive values use the default.                                                                                                                                                         |
| `maxToolCalls`                            | `number`  | (Optional) Maximum total tool calls per task. Defaults to 64. Non-positive values use the default.                                                                                                                                                                |
| `maxConsecutiveIdenticalToolRounds`       | `number`  | (Optional) Maximum consecutive rounds with identical tool names and canonical arguments. Defaults to 3. Non-positive values use the default.                                                                                                                     |
| `maxTaskDurationSeconds`                  | `number`  | (Optional) Maximum duration of a tool-enabled task in seconds. Defaults to 300. Non-positive values use the default.                                                                                                                                              |

`skills` follow the [Agent Skills Specification](https://agentskills.io/specification). In practice, each referenced skill should be a skill directory with a `SKILL.md` file containing YAML frontmatter plus Markdown instructions. The spec requires a lowercase-hyphenated `name` and a non-empty `description`.

The execution limits apply to `ToolAgent`, `MultiAgent`, and `AutoMultiAgent` tasks. A limit violation terminates the task with one `exception` task status. The status description contains `code: "tool_loop_limit_exceeded"` for request, round, call, or duplicate-round limits, and `code: "task_execution_timeout"` for the duration limit.

#### Request Example

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
  "systemPrompt": "Roleplay as someone with specific abilities to help solve certain problems",
  "skills": [
    "code-review",
    "release-notes"
  ],
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
  "subAgentList": [
    {
      "name": "someFunc1",
      "capability": {
        "systemPrompt": "Responsibilities of the first sub-agent"
      }
    },
    {
      "name": "some-func_2",
      "capability": {
        "systemPrompt": "Responsibilities of the second sub-agent"
      }
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

### 4. Initialize SimpleAgent Session

**Request Method**: `POST`

**Path**: `/initSimple`

**Description**: Initialize a SimpleAgent session. SimpleAgent does not require SSE streaming, and subsequent requests to [/chat/simple](#6-get-simpleagent-one-time-response) return a single response.

#### Request Body

| Field                             | Type      | Description                                                                                |
|-----------------------------------|-----------|--------------------------------------------------------------------------------------------|
| `llmConfig`                       | `object`  | Configuration for the language model, containing the following fields:                     |
| `llmConfig.provider`              | `string`  | (Optional) LLM provider used by the server. Supported values are `openai` and `lite_oneapi`. If omitted, `lite_oneapi` is used. |
| `llmConfig.baseUrl`               | `string`  | API endpoint of the language model provider, e.g., https://api.openai.com/v1               |
| `llmConfig.apiKey`                | `string`  | API Key of the language model provider, e.g., sk-xxxxxxxxxx                                |
| `llmConfig.model`                 | `string`  | Name of the language model, e.g., gpt-3.5-turbo                                            |
| `llmConfig.adapter`               | `string`  | (Optional) Adapter name used when `provider=lite_oneapi` to choose which upstream protocol/provider adapter handles the request. Supported values are `openai`, `deepseek`, `glm`, `kimi`, `mimo`, `minimax`, and `qwen`. If omitted, the default is `openai`. |
| `llmConfig.temperature`           | `number`  | (Optional) Temperature value, default is 0                                                 |
| `llmConfig.maxTokens`             | `number`  | (Optional) Maximum token count, default is 4096                                            |
| `llmConfig.topP`                  | `number`  | (Optional) Top-p value for sampling, default is 1                                          |
| `llmConfig.supportsToolCall`   | `boolean` | (Optional) Whether the model supports tool calling, default is true                        |
| `llmConfig.supportsReasoning`  | `boolean` | (Optional) Whether the model supports deep thinking, default is false                      |
| `systemPrompt`                    | `string`  | System prompt preset, e.g., role-playing instructions, abilities, or problem-solving tasks |
| `skills`                          | `array`   | (Optional) Skill reference list. Each item is a `string`. Referenced skills should follow the Agent Skills specification: https://agentskills.io/specification |

`skills` use the same specification as `/initSession`: [Agent Skills Specification](https://agentskills.io/specification).

#### Request Example

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
    "systemPrompt": "Roleplay as someone with specific abilities to help solve certain problems",
    "skills": [
        "code-review"
    ]
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

### 5. Start Session Stream

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
| `extraSystemPrompt` | `string` | (Optional) Extra system prompt appended to the agent's base system prompt for this session/task.                                                                                                           |

#### Request Example

```json
{
  "content": [
    {
      "type": "text",
      "message": "Give me a random number"
    }
  ],
  "isChunk": true,
  "extraSystemPrompt": "Respond with a single integer only."
}
```

#### Response Stream

- `Content-Type: text/event-stream`
- Event types: `message`, `chunk`, `functionCall`
- `message` and `functionCall` events carry `AgentMessageDto` JSON
- `chunk` events carry `AgentMessageChunkDto` JSON
- See [AgentMessage Explanation](#agentmessage-explanation) for payload structures.

### 6. Get SimpleAgent One-time Response

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
| `extraSystemPrompt` | `string` | (Optional) Extra system prompt appended to the agent's base system prompt for this session/task.                                                                                                                                                                           |

#### Request Example

```json
{
  "content": [
    {
      "type": "text",
      "message": "Give me a random number"
    }
  ],
  "extraSystemPrompt": "Respond with a single integer only."
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
| `completions.usage.contextUsageRatio`| number | Context usage ratio (0~1). Computed from `contextWindowSize`; may be `null` when not configured |
| `completions.id`                          | string | Message ID returned by the model                                                  |
| `completions.model`                       | string | Model name, e.g., gpt-3.5-turbo                                                   |
| `completions.limits`                      | object | (Optional) Completion limits from model config |
| `completions.limits.maxTokens`            | number | Max completion tokens configured for the model |
| `completions.limits.contextWindowSize`    | number | (Optional) Context window size used for ratio calculation |
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
```

### 7. Tool Callback

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

### 8. Tool Stream Callback

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

### 9. Retrieve Message History

**Request Method**: `GET`

**Path**: `/history`

**Description**: Retrieve persisted message history for a session. History remains available after core runtime eviction or a server restart. This API does not support SimpleAgent.

#### Query Parameters

| Field       | Type   | Description                                                |
|-------------|--------|------------------------------------------------------------|
| `sessionId` | string | Session ID used to read the history of the current session |
| `page` | int | (Optional) 1-based page number; must be supplied with `pageSize` |
| `pageSize` | int | (Optional) number of messages per page; must be supplied with `page` |

#### Path Example

```http request
GET /history?sessionId=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

Paginated example:

```http request
GET /history?sessionId=b2ac9280-70d6-4651-bd3a-45eb81cd8c30&page=1&pageSize=50
```

#### Response

**Status Code**: `200 OK`

**Response Body**: An `array` of objects with the following structure:

| Field Name                                | Type   | Description                                                                                           |
|-------------------------------------------|--------|-------------------------------------------------------------------------------------------------------|
| `sessionId`                               | string | Session ID used to identify the session                                                               |
| `originalTaskId`                          | string | Original task ID used to associate child tasks and tool calls                                          |
| `taskId`                                  | string | Task ID identifying the task                                                                          |
| `parentTaskId`                            | string | (Optional) parent task ID                                                                              |
| `role`                                    | string | Message source, possible values: `system`, `user`, `agent`, `llm`, `tool`                             |
| `to`                                      | string | Message target, possible values: `user`, `agent`, `llm`, `tool`, `client`                             |
| `type`                                    | string | Message type, possible values: `text`, `reasoning`, `imageUrl`, `contentList`, `functionCall`, `toolCalls`, `toolReturn`, `taskStatus` |
| `content`                                 | any    | Message content, its type depends on the `type` field                                                 |
| `reasoningContent`                        | string | (Optional) model reasoning content                                                                     |
| `completions`                             | object | Detailed information about the model completion, containing the following fields:                     |
| `completions.usage`                  | object | Token usage information                                                                               |
| `completions.usage.promptTokens`     | number | Number of prompt tokens                                                                               |
| `completions.usage.completionTokens` | number | Number of completion tokens                                                                           |
| `completions.usage.totalTokens`      | number | Total number of tokens                                                                                |
| `completions.usage.contextUsageRatio`| number | Context usage ratio (0~1). Computed from `contextWindowSize`; may be `null` when not configured      |
| `completions.id`                          | string | Message ID returned by the model                                                                      |
| `completions.model`                       | string | Model name, e.g., gpt-3.5-turbo                                                                       |
| `completions.limits`                      | object | (Optional) Completion limits from model config |
| `completions.limits.maxTokens`            | number | Max completion tokens configured for the model |
| `completions.limits.contextWindowSize`    | number | (Optional) Context window size used for ratio calculation |
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

### 9.1. Retrieve History Turn Summaries

**Request Method**: `GET`

**Path**: `/history/summary`

Returns one summary per `originalTaskId`, ordered by task creation time descending. Pagination is by task turn, not by message. `page` defaults to `1`, `pageSize` defaults to `30`, and `pageSize` must not exceed `200`.

```http request
GET /history/summary?sessionId=root-session&page=1&pageSize=30
```

The query `sessionId` is the authoritative root-session boundary. A root user message must have the same `sessionId`, role `user`, and type `text` or `contentList`. The final answer is the latest root-session message addressed to `user` with either content type. Only root-session `taskStatus` messages determine terminal state: root `exception`/`error`/`failed` becomes `error`; root `stop` becomes `stopped`; a root final answer or root `done`/`complete`/`finished` becomes `done`; otherwise the task is `running`. Child-agent terminal or error messages never change the root status or error.

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
      "content": "Summarize the report",
      "createTime": "2026-07-12T10:00:00.000Z"
    },
    "finalMessage": {
      "sessionId": "root-session",
      "originalTaskId": "root-task-id",
      "taskId": "root-task-id",
      "role": "agent",
      "to": "user",
      "type": "text",
      "content": "Here is the summary...",
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

`userMessage` and `finalMessage` retain the original `AgentMessageDto` JSON shape. Usage comes from the root final answer when present, otherwise from the latest root message with completion usage. `processMessageCount` excludes the selected root user and final messages.

### 9.2. Retrieve History Turn Process

**Request Method**: `GET`

**Path**: `/history/process`

Lazily returns process messages for one turn, including associated child-agent, tool-call, tool-return, reasoning, and task-status messages. The root user and final messages already present in the summary are excluded. Results use the unchanged `AgentMessageDto` JSON array, ordered by `createTime` ascending with persisted message ID as the stable tie-breaker.

```http request
GET /history/process?sessionId=root-session&originalTaskId=root-task-id&page=1&pageSize=50
```

`page` defaults to `1`, `pageSize` defaults to `50`, and `pageSize` must not exceed `200`. The task must contain at least one message whose actual `sessionId` is the queried root session and must be within that root session's configured session tree. A missing or foreign `originalTaskId` returns `200 OK` with `[]`; a missing root session returns `404`.

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

### 10. Stop Session

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

### 11. Clear Session Data

**Request Method**: `GET`

**Path**: `/clear`

**Description**: Clear the core runtime session, persisted session, and its messages. The session ID cannot be restored afterward. This API does not support SimpleAgent.

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

### 12. Subscribe Session Events

**Request Method**: `GET`

**Path**: `/session/subscribe`

**Description**: Subscribe to SSE events for an existing session without starting a new task.

#### Query Parameters

| Field       | Type     | Description                  |
|-------------|----------|------------------------------|
| `sessionId` | `string` | Session ID to subscribe to   |

#### Response Stream

- `Content-Type: text/event-stream`
- Event types: `message`, `chunk`
- `message` events carry `AgentMessageDto` JSON
- `chunk` events carry `AgentMessageChunkDto` JSON

## AgentMessage Explanation

### 1. `type` field's `content` structure in different types

| `type` or Element Field                                | Data Type of `content` or Element Field | Description                                                                                                                                                                                                                                                                                       |
|--------------------------------------------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1. `text`                                              | `string`                                | Plain text.                                                                                                                                                                                                                                                                                       |
| 2. `reasoning`                                         | `string`                                | A standalone reasoning message emitted before the corresponding text or tool-call message.                                                                                                                                                                                                       |
| 3. `imageUrl`                                          | `string`                                | Plain text, can be either an image URL or base64 format.                                                                                                                                                                                                                                          |
| 4. `functionCall`                                      | `object`                                | Single function call returned by the model.                                                                                                                                                                                                                                                       |
| `functionCall.id`                                      | `string`                                | The function call ID returned by the model.                                                                                                                                                                                                                                                       |
| `functionCall.name`                                    | `string`                                | The name of the `function`.                                                                                                                                                                                                                                                                       |
| `functionCall.arguments`                               | Map\[`string`, `dynamic`\]              | Argument map returned by the model.                                                                                                                                                                                                                                                               |
| 5. `toolCalls`                                         | `array`                                 | Array of function calls returned by the model.                                                                                                                                                                                                                                                    |
| `toolCalls.id`                                         | `string`                                | The function call ID returned by the model.                                                                                                                                                                                                                                                       |
| `toolCalls.name`                                       | `string`                                | The name of the `function`.                                                                                                                                                                                                                                                                       |
| `toolCalls.arguments`                                  | Map\[`string`, `dynamic`\]              | Argument map returned by the model.                                                                                                                                                                                                                                                               |
| 6. `toolReturn`                                        | `object`                                | Result returned by the tool.                                                                                                                                                                                                                                                                      |
| `toolReturn.id`                                        | `string`                                | Corresponds to `functionCall.id`.                                                                                                                                                                                                                                                                 |
| `toolReturn.result`                                    | Map\[`string`, `dynamic`\]              | Result returned by the tool.                                                                                                                                                                                                                                                                      |
| 7. `contentList`                                       | `array`                                 | User's message array, where each element is of `object` type.                                                                                                                                                                                                                                     |
| `contentList.type`                                     | `string`                                | Possible types are `text`, `imageUrl`.                                                                                                                                                                                                                                                            |
| `contentList.message`                                  | `string`                                | Message content, e.g., "Give me a random number"; <br/> If the message type is `imageUrl`, the message's String can be: <br/> 1. Image URL: "https://example.com/path/to/image.png", and ensure it's publicly accessible <br/> 2. Base64 format: "data:image/jpeg;base64,{Base64 encoded image}". |
| 8. `taskStatus`                                        | `object`                                | Task status payload.                                                                                                                                                                                                                                                                              |
| `taskStatus.status`                                    | `string`                                | Possible types: `start`, `stop`, `done`, `exception`.                                                                                                                                                                                                                                             |
| `taskStatus.taskId`                                    | `string`                                | Current Task ID                                                                                                                                                                                                                                                                                   |
| `taskStatus.description`                               | Map\[`string`, `dynamic`\]              | Description of the message, generally provided when the status is `exception`.                                                                                                                                                                                                                    |

**Example of `text` type message**

```text
"Feature result: PASS"
```

**Example of `reasoning` type message**

```text
"We need to compare the available options first."
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
