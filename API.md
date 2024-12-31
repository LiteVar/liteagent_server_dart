# API for LiteAgent core Dart Server

[中文](API-zh_CN.md) · English

## Contents
- HTTP API
    - [/version](#1-get-version): Retrieve the current version.
    - [/init](#2-initialize-sessionagent-session): Initialize a SessionAgent session and return a SessionId.
    - [/init/simple](#3-initialize-simpleagent-session): Initialize a SimpleAgent session. SimpleAgent does not require WebSocket, and subsequent requests to `/chat/simple` directly respond with text messages from the LLM.
    - [/chat/simple](#4-get-simpleagent-one-time-response): Obtain a one-time response from a large model by sending a request-response, without subscribing to WebSocket messages.
    - [/history](#5-retrieve-message-history): Retrieve the history of messages for a specific session. This API does not support SimpleAgent.
    - [/stop](#6-stop-session): Stops the specified session by sessionId. This API does not support SimpleAgent.
    - [/clear](#7-clear-session-data): Clear the session data, returning the corresponding sessionId. This API does not support SimpleAgent.
- WebSocket API
    - [Client Messages](#client-messages)
        - [Keep Connection Alive](#1-keep-connection)
        - [User Messages](#2-user-message)
    - [Server Messages](#server-messages)
        - [Keep Connection Response](#1-keep-connection-response)
        - [Agent Messages](#2-agent-message)
- AgentMessage Explanation
    - [Message Structure Based on `type`](#1-type-fields-message-structure-in-different-types)
    - [Message Status Strings when `to` is `client`](#2-status-strings-in-message-when-to-is-client)

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

### 2. Initialize SessionAgent Session

**Request Method**: `POST`

**Endpoint**: `/init`

**Description**: Initialize a SessionAgent session and return a SessionId.

#### Request Parameters

| Field                                     | Type     | Description                                                                                                                                                                                                                                                      |
|-------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `llmConfig`                               | `object` | Configuration for the language model, containing the following fields:                                                                                                                                                                                           |
| `llmConfig.baseUrl`                       | `string` | API endpoint of the language model provider, e.g., https://api.openai.com/v1                                                                                                                                                                                     |
| `llmConfig.apiKey`                        | `string` | API Key of the language model provider, e.g., sk-xxxxxxxxxx                                                                                                                                                                                                      |
| `llmConfig.model`                         | `string` | Name of the language model, e.g., gpt-3.5-turbo                                                                                                                                                                                                                  |
| `llmConfig.temperature`                   | `number` | (Optional) Temperature value, default is 0                                                                                                                                                                                                                       |
| `llmConfig.maxTokens`                     | `number` | (Optional) Maximum token count, default is 4096                                                                                                                                                                                                                  |
| `llmConfig.topP`                          | `number` | (Optional) Top-p value for sampling, default is 1                                                                                                                                                                                                                |
| `systemPrompt`                            | `string` | System prompt preset, e.g., role-playing instructions, abilities, or problem-solving tasks                                                                                                                                                                       |
| `openSpecList`                            | `array`  | (Optional) List of specifications, each element being an `object`                                                                                                                                                                                                |
| `openSpecList.openSpec`                   | `string` | JSON description of the spec, currently supports `openapi`, `openmodbus`, `openrpc`, `opentool`                                                                                                                                                                  |
| `openSpecList.apiKey`                     | `object` | (Optional) API Key for third-party services                                                                                                                                                                                                                      |
| `openSpecList.type`                       | `string` | Either `basic` or `bearer`                                                                                                                                                                                                                                       |
| `openSpecList.protocol`                   | `string` | Currently supports `openapi`, `openmodbus`, `jsonrpcHttp`, `opentool`                                                                                                                                                                                            |
| `openSpecList.openToolId`                 | `array`  | (Optional) Valid when `protocol` is set to `opentool`, specifies which opentools to use as specs. Each element in the array is a `string`.                                                                                                                       |
| `sessionList`                             | `array`  | (Optional) List of sessions, each element being an `object`                                                                                                                                                                                                      |
| `sessionList.id`                          | `string` | sessionId of a sub-agent                                                                                                                                                                                                                                         |
| `sessionList.name`                        | `string` | (Optional) Sub Agent custom name. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.                                                                                                                                         |
| `reflectPromptList`                       | `array`  | (Optional) List of ReflectPrompt, where each element in the array is an `object`. **if `openSpecList` is null, reflect LLM text, else reflect Function Calling**                                                                                                 |
| `reflectPromptList.llmConfig`             | `object` | `ReflectAgent`'s `llmConfig`, used for requesting large models.                                                                                                                                                                                                  |
| `reflectPromptList.llmConfig.baseUrl`     | `string` | The API endpoint of the large model provider, e.g., https://api.openai.com/v1                                                                                                                                                                                    |
| `reflectPromptList.llmConfig.apiKey`      | `string` | The API key of the large model provider, e.g., sk-xxxxxxxxxx                                                                                                                                                                                                     |
| `reflectPromptList.llmConfig.model`       | `string` | The name of the large model, e.g., gpt-4o-mini                                                                                                                                                                                                                   |
| `reflectPromptList.llmConfig.temperature` | `number` | (Optional) Temperature value, defaults to 0.                                                                                                                                                                                                                     |
| `reflectPromptList.llmConfig.maxTokens`   | `number` | (Optional) Maximum token count, defaults to 4096.                                                                                                                                                                                                                |
| `reflectPromptList.llmConfig.topP`        | `number` | (Optional) Probability sampling `p` value, defaults to 1.                                                                                                                                                                                                        |
| `reflectPromptList.prompt`                | `string` | System Prompt of `ReflectAgent`, used to describe the evaluation criteria for reflection scores.                                                                                                                                                                 |
| `timeoutSeconds`                          | `number` | (Optional) Timeout duration, defaults to 3600 seconds.                                                                                                                                                                                                           |
| `taskPipelineStrategy`                    | `enum`   | (Optional) Strategy for handling new task instructions within the same session. Supports: `parallel` (allows parallel execution), `serial` (queues tasks), or `reject` (rejects new tasks if one is already in progress). Defaults to `parallel`.                |
| `toolPipelineStrategy`                    | `enum`   | (Optional) Strategy for handling tool execution when function calling returns an array. Supports: `parallel` (allows parallel execution), `serial` (queues execution), or `reject` (rejects execution if a task is already in progress). Defaults to `parallel`. |

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
      "openSpec": "<JSON description of the spec, supports openapi, openmodbus, openrpc>",
      "apiKey": {
        "type": "bearer",
        "apiKey": "sk-xxxxxxxxxxxxxxxx"
      },
      "protocol": "openapi"
    },
    {
      "openSpec": "<Another spec's JSON description, different types can be mixed>",
      "protocol": "openmodbus"
    }
  ],
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
 ```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field | Type     | Description                                             |
|-------|----------|---------------------------------------------------------|
| `id`  | `string` | Session ID, a unique identifier generated by the system |

#### Response Example

```json
{
  "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 3. Initialize SimpleAgent Session

**Request Method**: `POST`

**Endpoint**: `/init/simple`

**Description**: Initialize a SimpleAgent session. SimpleAgent does not require WebSocket, and subsequent requests to [/chat/simple](#4-get-simpleagent-one-time-response) will directly respond with text messages from the LLM.

#### Request Parameters

| Field                   | Type     | Description                                                                                |
|-------------------------|----------|--------------------------------------------------------------------------------------------|
| `llmConfig`             | `object` | Configuration for the language model, containing the following fields:                     |
| `llmConfig.baseUrl`     | `string` | API endpoint of the language model provider, e.g., https://api.openai.com/v1               |
| `llmConfig.apiKey`      | `string` | API Key of the language model provider, e.g., sk-xxxxxxxxxx                                |
| `llmConfig.model`       | `string` | Name of the language model, e.g., gpt-3.5-turbo                                            |
| `llmConfig.temperature` | `number` | (Optional) Temperature value, default is 0                                                 |
| `llmConfig.maxTokens`   | `number` | (Optional) Maximum token count, default is 4096                                            |
| `llmConfig.topP`        | `number` | (Optional) Top-p value for sampling, default is 1                                          |
| `systemPrompt`          | `string` | System prompt preset, e.g., role-playing instructions, abilities, or problem-solving tasks |

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

| Field | Type     | Description                                             |
|-------|----------|---------------------------------------------------------|
| `id`  | `string` | Session ID, a unique identifier generated by the system |

#### Response Example

```json
{
    "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```


### 4. Get SimpleAgent One-time Response

**Request Method**: `POST`

**Path**: `/chat/simple`

**Description**: Obtain a one-time response from a large model by sending a request-response, without subscribing to WebSocket messages.

#### Path Parameters

| Field Name | Type   | Description                                              |
|------------|--------|----------------------------------------------------------|
| `id`       | string | Session ID used to trigger the corresponding SimpleAgent |

#### Path Example

```http request
POST /chat/simple?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Request Parameters

| Field Name            | Type   | Description                                                                                                                                                                                                                                                               |
|-----------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `taskId`              | string | (Optional) Used to identify which task the AgentMessage belongs to. If not set, the system will generate it automatically.                                                                                                                                                |
| `contentList`         | array  | List of message contents. Each element in the array is an `object`.                                                                                                                                                                                                       |
| `contentList.type`    | string | Message type, can be `text` or `imageUrl`.                                                                                                                                                                                                                                |
| `contentList.message` | string | Message content, e.g., "Give me a random number"; <br/>If the message type is imageUrl, the message string can be:<br/>1. Image link: "https://example.com/path/to/image.png" (publicly accessible)<br/>2. Base64 format: "data:image/jpeg;base64,{base64 encoded image}" |

#### Request Example

```json
{
  "taskId": "25afe7d5-998b-41cf-aebe-34950bd91f84",
  "contentList": [
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
| `from`                                    | string | Message source, fixed as `llm`                                                    |
| `to`                                      | string | Message target, fixed as `agent`                                                  |
| `type`                                    | string | Message type, fixed as `text`                                                     |
| `message`                                 | string | The returned message content                                                      |
| `completions`                             | object | Detailed information about the model completion, containing the following fields: |
| `completions.tokenUsage`                  | object | Token usage information                                                           |
| `completions.tokenUsage.promptTokens`     | number | Number of prompt tokens                                                           |
| `completions.tokenUsage.completionTokens` | number | Number of completion tokens                                                       |
| `completions.tokenUsage.totalTokens`      | number | Total number of tokens                                                            |
| `completions.id`                          | string | Message ID returned by the model                                                  |
| `completions.model`                       | string | Model name, e.g., gpt-3.5-turbo                                                   |
| `createTime`                              | string | Message creation time in the format yyyy-MM-ddTHH:mm:ss.SSSZ                      |

#### Response Example

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

### 5. Retrieve Message History

**Request Method**: `GET`

**Path**: `/history`

**Description**: Retrieve the history of messages for a specific session. This API does not support SimpleAgent.

#### Path Parameters

| Field Name | Type   | Description                                                |
|------------|--------|------------------------------------------------------------|
| `id`       | string | Session ID used to read the history of the current session |

#### Path Example

```http request
GET /history?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Response

**Status Code**: `200 OK`

**Response Body**: An `array` of objects with the following structure:

| Field Name                                | Type   | Description                                                                                           |
|-------------------------------------------|--------|-------------------------------------------------------------------------------------------------------|
| `sessionId`                               | string | Session ID used to identify the session                                                               |
| `taskId`                                  | string | Task ID identifying the task                                                                          |
| `from`                                    | string | Message source, possible values: `system`, `user`, `agent`, `llm`, `tool`                             |
| `to`                                      | string | Message target, possible values: `user`, `agent`, `llm`, `tool`, `client`                             |
| `type`                                    | string | Message type, possible values: `text`, `imageUrl`, `functionCallList`, `toolReturn`, or `contentList` |
| `message`                                 | any    | Message content, its type depends on the `type` field                                                 |
| `completions`                             | object | Detailed information about the model completion, containing the following fields:                     |
| `completions.tokenUsage`                  | object | Token usage information                                                                               |
| `completions.tokenUsage.promptTokens`     | number | Number of prompt tokens                                                                               |
| `completions.tokenUsage.completionTokens` | number | Number of completion tokens                                                                           |
| `completions.tokenUsage.totalTokens`      | number | Total number of tokens                                                                                |
| `completions.id`                          | string | Message ID returned by the model                                                                      |
| `completions.model`                       | string | Model name, e.g., gpt-3.5-turbo                                                                       |
| `createTime`                              | string | Message creation time in the format yyyy-MM-ddTHH:mm:ss.SSSZ                                          |

#### Response Example

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

### 6. Stop Session

**Request Method**: `GET`

**Path**: `/stop`

**Description**: Stops the specified session by sessionId. This API does not support SimpleAgent.

#### Path Parameters

| Field Name | Type     | Description                                                                                                         |
|------------|----------|---------------------------------------------------------------------------------------------------------------------|
| `id`       | `string` | Session ID to identify the session to stop                                                                          |
| `taskId`   | `string` | (Optional) Task ID to identify the task to stop. If not provided, all tasks of the current session will be stopped. |

#### Example Request

```http request
GET /stop?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field Name | Type     | Description                                  |
|------------|----------|----------------------------------------------|
| `id`       | `string` | Session ID to confirm the stopped session    |

#### Example Response

```json
{
    "id": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30"
}
```

### 7. Clear Session Data

**Request Method**: `GET`

**Path**: `/clear`

**Description**: Clear the session data, returning the corresponding sessionId. This API does not support SimpleAgent.

#### Path Parameters

| Field Name | Type     | Description                                  |
|------------|----------|----------------------------------------------|
| `id`       | `string` | Session ID to identify the session to clear  |

#### Example Request

```http request
GET /clear?id=b2ac9280-70d6-4651-bd3a-45eb81cd8c30
```

#### Response

**Status Code**: `200 OK`

**Response Body**:

| Field Name | Type     | Description                                  |
|------------|----------|----------------------------------------------|
| `id`       | `string` | Session ID to confirm the cleared session    |

#### Example Response

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

### Client Messages

### 1. Keep Connection

**Description**: The client sends a keep-alive request to the server to maintain the WebSocket channel.

**Message Format**: Plain text `ping`

```text
"ping"
```

### 2. User Message

**Description**: The client sends a user message request to the Agent service.

**Message Format**:

| Field Name            | Type     | Description                                                                                                                                                                                                                                                                                       |
|-----------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `taskId`              | `string` | Optional, used to identify which task the AgentMessage belongs to. If not set, the system generates it automatically; no more than 36 characters.                                                                                                                                                 |
| `contentList`         | `array`  | An array of user messages, where each element is of `object` type.                                                                                                                                                                                                                                |
| `contentList.type`    | `string` | The message type, possible values include: `text`, `imageUrl`.                                                                                                                                                                                                                                    |
| `contentList.message` | `string` | Message content, e.g., "Give me a random number"; <br/> If the message type is `imageUrl`, the message's String can be: <br/> 1. Image URL: "https://example.com/path/to/image.png", and ensure it's publicly accessible <br/> 2. Base64 format: "data:image/jpeg;base64,{Base64 encoded image}". |

**Message Example**:

```json
{
  "taskId": "25afe7d5-998b-41cf-aebe-34950bd91f84",
  "contentList": [
    {
      "type": "text",
      "message": "Run a specific feature for me"
    }
  ]
}
```

### Server Messages

### 1. Keep Connection Response

**Description**: The server sends a response to the client to maintain the WebSocket channel.

**Message Format**: Plain text `pong`

```text
"pong"
```

### 2. Agent Message

**Description**: The Agent system continuously pushes messages generated in the current session to the client.

**Message Format**:

| Field Name                                | Type     | Description                                                                                                                                                                 |
|-------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `sessionId`                               | `string` | Session ID, used to identify the corresponding session.                                                                                                                     |
| `taskId`                                  | `string` | Task ID, identifies the task.                                                                                                                                               |
| `from`                                    | `string` | Message source, possible values include: `system`, `user`, `agent`, `llm`, `tool`.                                                                                          |
| `to`                                      | `string` | Message target, possible values include: `user`, `agent`, `llm`, `tool`, `client`.                                                                                          |
| `type`                                    | `string` | Message type, possible values include: `text`, `imageUrl`, `functionCallList`, `toolReturn`, `contentList`.                                                                 |
| `message`                                 | `any`    | Message content, the specific type should be parsed based on the `type` field. See [Message Structure Based on `type`](#1-type-fields-message-structure-in-different-types) |
| `completions`                             | `object` | Detailed information about model completions, containing the following fields:                                                                                              |
| `completions.tokenUsage`                  | `object` | Token usage information.                                                                                                                                                    |
| `completions.tokenUsage.promptTokens`     | `number` | Number of prompt tokens.                                                                                                                                                    |
| `completions.tokenUsage.completionTokens` | `number` | Number of completion tokens.                                                                                                                                                |
| `completions.tokenUsage.totalTokens`      | `number` | Total number of tokens.                                                                                                                                                     |
| `completions.id`                          | `string` | The ID of the message returned by the large model.                                                                                                                          |
| `completions.model`                       | `string` | Model name, e.g., gpt-3.5-turbo.                                                                                                                                            |
| `createTime`                              | `string` | Message creation time in the format yyyy-MM-ddTHH:mm:ss.SSSZ.                                                                                                               |

**Message Example**:

```json
{
  "sessionId": "b2ac9280-70d6-4651-bd3a-45eb81cd8c30",
  "taskId": "0b127f1d-4667-4a52-bbcb-0b636f9a471a",
  "from": "agent",
  "to": "llm",
  "type": "text",
  "message": "<Generic type, needs to be parsed according to type>",
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

## AgentMessage Explanation

### 1. `type` field's `message` structure in different types

| `type` or Element Field                                | Data Type of `message` or Element Field | Description                                                                                                                                                                                                                                                                                       |
|--------------------------------------------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1. `text`                                              | `string`                                | Plain text.                                                                                                                                                                                                                                                                                       |
| 2. `imageUrl`                                          | `string`                                | Plain text, can be either an image URL or base64 format.                                                                                                                                                                                                                                          |
| 3. `functionCallList`                                  | `array`                                 | Content returned by the large model's `function calling`, each element is of `object` type.                                                                                                                                                                                                       |
| `functionCallList.id`                                  | `string`                                | The `function calling` ID returned by the large model.                                                                                                                                                                                                                                            |
| `functionCallList.name`                                | `string`                                | The name of the `function`.                                                                                                                                                                                                                                                                       |
| `functionCallList.parameters`                          | Map\[`string`, `dynamic`\]              | Parameter map returned by the large model.                                                                                                                                                                                                                                                        |
| 4. `toolReturn`                                        | `object`                                | Result returned by the tool.                                                                                                                                                                                                                                                                      |
| `toolReturn.id`                                        | `string`                                | Corresponds to `functionCallList.id`.                                                                                                                                                                                                                                                             |
| `toolReturn.result`                                    | Map\[`string`, `dynamic`\]              | Result returned by the tool.                                                                                                                                                                                                                                                                      |
| 5. `contentList`                                       | `array`                                 | User's message array, where each element is of `object` type.                                                                                                                                                                                                                                     |
| `contentList.type`                                     | `string`                                | Possible types are `text`, `imageUrl`.                                                                                                                                                                                                                                                            |
| `contentList.message`                                  | `string`                                | Message content, e.g., "Give me a random number"; <br/> If the message type is `imageUrl`, the message's String can be: <br/> 1. Image URL: "https://example.com/path/to/image.png", and ensure it's publicly accessible <br/> 2. Base64 format: "data:image/jpeg;base64,{Base64 encoded image}". |
| 6. `reflection`                                        | `object`                                | Reflection result.                                                                                                                                                                                                                                                                                |
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
| 7. `taskStatus`                                        | `object`                                | Array of user messages, each element is an `object`.                                                                                                                                                                                                                                              |
| `taskStatus.status`                                    | `string`                                | Possible types: `start`, `stop`, `done`, `exception`.                                                                                                                                                                                                                                             |
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

**Example of `functionCallList` type message**

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

### 2. Status Strings in `message` when `to` is `client`:

- `"[TASK_START]"`: Agent receives the user message and prepares to process it.
- `"[TOOLS_START]"`: Preparing to submit Tools for execution.
- `"[TOOLS_DONE]"`: Tools execution completed.
- `"[TASK_STOP]"`: Agent receives a stop or clear command and stops the task.
- `"[TASK_DONE]"`: Agent has completed processing.
