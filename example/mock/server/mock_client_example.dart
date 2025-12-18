import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:dotenv/dotenv.dart';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import '../../listener.dart';

Config config = initConfig();

/// [IMPORTANT] Prepare:
/// 1. HTTP Server, according to `/example/mock/server/mock_http_server`, which server is running.
/// 2. OneAPI JSON file, which is described the HTTP Server API.
/// 3. Add LLM baseUrl and apiKey to `.env` file
Future<void> main() async {
  String baseUrl =
      "http://127.0.0.1:${config.server.port}${config.server.apiPathPrefix}";

  Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // headers: {"Authorization": "Bearer <KEY>"}
    ),
  );

  String systemPrompt =
      "You play the role of a tool caller. You can help me decide which tool to call to complete the task according to my requirements. You can only call one tool at a time. \n\nYou support the following tools:\n\n 1. Translation\n 2. Add, delete, modify and query tools";
  String prompt = "Find the text with ID 0 and translate it into Chinese.";

  SessionDto? sessionDto1 = await _buildTextAgent(dio);
  SessionDto? sessionDto2 = await _buildToolAgent(dio);

  if (sessionDto1 == null || sessionDto2 == null) {
    print("Init sub session failed.");
    return;
  }

  CapabilityDto capabilityDto = CapabilityDto(
    llmConfig: _buildLLMConfigDto(),
    systemPrompt: systemPrompt,
    sessionList: [
      SessionNameDto(sessionId: sessionDto1.sessionId),
      SessionNameDto(sessionId: sessionDto2.sessionId),
    ],
  );

  SessionDto? sessionDto = await initChat(dio, capabilityDto);

  if (sessionDto != null) {
    print("[sessionDto] " + sessionDto.toJson().toString());

    Stream<String> sseStream = await sendUserMessage(
      baseUrl,
      sessionDto.sessionId,
      prompt,
    );

    _decodeSse(sseStream).listen(
      (event) {
        _onSseEvent(sessionDto.sessionId, event);
      },
      onDone: () {
        print("[sseDone]");
      },
      onError: (e) {
        print("[sseError] " + e.toString());
      },
    );

    print("[prompt] " + prompt);

    await sleep(30);

    SessionDto? stopSessionDto = await stopChat(dio, sessionDto.sessionId);
    print("[stopSessionDto] " + stopSessionDto!.toJson().toString());

    await sleep(5);

    SessionDto? clearSessionDto = await clearChat(dio, sessionDto.sessionId);
    print("[clearSessionDto] " + clearSessionDto!.toJson().toString());
  }
}

LLMConfigDto _buildLLMConfigDto() {
  DotEnv env = DotEnv();
  env.load(['example/.env']);
  return LLMConfigDto(
    baseUrl: env["baseUrl"]!,
    apiKey: env["apiKey"]!,
    model: "gpt-3.5-turbo",
  );
}

Future<SessionDto?> _buildTextAgent(Dio dio) async {
  String systemPrompt =
      "Playing as a translator, knowing how to translate between languages.";

  CapabilityDto capabilityDto = CapabilityDto(
    llmConfig: _buildLLMConfigDto(),
    systemPrompt: systemPrompt,
  );
  return await initChat(dio, capabilityDto);
}

Future<SessionDto?> _buildToolAgent(Dio dio) async {
  DotEnv env = DotEnv();
  env.load(['example/.env']);
  LLMConfigDto llmConfig = LLMConfigDto(
    baseUrl: env["baseUrl"]!,
    apiKey: env["apiKey"]!,
    model: "gpt-4o-mini",
  );

  String openAPIFolder =
      "${io.Directory.current.path}${io.Platform.pathSeparator}example${io.Platform.pathSeparator}mock${io.Platform.pathSeparator}server";
  List<String> openAPIFileNameList = ["mock_openapi.json"];

  List<OpenSpecDto> openSpecDtoList = [];
  for (String openAPIFileName in openAPIFileNameList) {
    String jsonPath =
        "$openAPIFolder${io.Platform.pathSeparator}$openAPIFileName";
    io.File file = io.File(jsonPath);
    String jsonString = await file.readAsString();
    OpenSpecDto openSpecDto = OpenSpecDto(
      openSpec: jsonString,
      protocol: Protocol.OPENAPI,
    );
    openSpecDtoList.add(openSpecDto);
  }

  String systemPrompt =
      "A storage management tool that knows how to add, delete, modify, and query my texts.";

  CapabilityDto capabilityDto = CapabilityDto(
    llmConfig: llmConfig,
    systemPrompt: systemPrompt,
    openSpecList: openSpecDtoList,
  );

  return await initChat(dio, capabilityDto);
}

Future<void> sleep(int seconds) async {
  for (int i = seconds; i > 0; i--) {
    print(i);
    await Future.delayed(Duration(seconds: 1));
  }
}

Future<SessionDto?> initChat(Dio dio, CapabilityDto capabilityDto) async {
  try {
    Response response = await dio.post(
      '/initSession',
      data: capabilityDto.toJson(),
    );
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    print("[initChat->RES] " + sessionDto.toJson().toString());
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<Stream<String>> chat(
  String baseUrl,
  String sessionId,
  UserTaskDto userTaskDto,
) async {
  Uri uri = Uri.parse('$baseUrl/chat?sessionId=$sessionId');
  io.HttpClient httpClient = io.HttpClient();

  io.HttpClientRequest request = await httpClient.postUrl(uri);

  request.headers.add(io.HttpHeaders.acceptHeader, 'text/event-stream');
  request.headers.add(io.HttpHeaders.contentTypeHeader, 'application/json');

  Map<String, dynamic> data = userTaskDto.toJson();

  request.add(utf8.encode(jsonEncode(data)));

  io.HttpClientResponse response = await request.close();

  Stream<String> stream = response.transform(utf8.decoder);
  return stream;
}

Future<Stream<String>> sendUserMessage(
  String baseUrl,
  String sessionId,
  String prompt,
) async {
  ContentDto userMessageDto = ContentDto(
    type: ContentType.TEXT,
    message: prompt,
  );
  UserTaskDto userTaskDto = UserTaskDto(content: [userMessageDto]);

  return await chat(baseUrl, sessionId, userTaskDto);
}

Future<SessionDto?> stopChat(Dio dio, String sessionId) async {
  try {
    Response response = await dio.get(
      '/stop',
      queryParameters: {"sessionId": sessionId},
    );
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<SessionDto?> clearChat(Dio dio, String sessionId) async {
  try {
    Response response = await dio.get(
      '/clear',
      queryParameters: {"sessionId": sessionId},
    );
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

class _SseEvent {
  final String? event;
  final String data;

  _SseEvent({required this.event, required this.data});
}

Stream<_SseEvent> _decodeSse(Stream<String> input) async* {
  var buffer = '';
  await for (final chunk in input) {
    buffer += chunk;

    while (true) {
      final separatorIndex = buffer.indexOf('\n\n');
      if (separatorIndex == -1) break;

      final frame = buffer.substring(0, separatorIndex);
      buffer = buffer.substring(separatorIndex + 2);

      final parsed = _parseSseFrame(frame);
      if (parsed != null) yield parsed;
    }
  }

  final trailing = _parseSseFrame(buffer);
  if (trailing != null) yield trailing;
}

_SseEvent? _parseSseFrame(String frame) {
  if (frame.trim().isEmpty) return null;

  final lines = frame.split(RegExp(r'\r?\n'));
  String? eventName;
  final dataLines = <String>[];

  for (final line in lines) {
    if (line.startsWith('event:')) {
      eventName = line.substring('event:'.length).trim();
      continue;
    }
    if (line.startsWith('data:')) {
      var value = line.substring('data:'.length);
      if (value.startsWith(' ')) value = value.substring(1);
      dataLines.add(value);
    }
  }

  if (dataLines.isEmpty) return null;
  return _SseEvent(event: eventName, data: dataLines.join('\n'));
}

Future<void> _onSseEvent(String sessionId, _SseEvent event) async {
  final eventName = event.event ?? SSEEventType.MESSAGE;
  final eventData = event.data;

  if (eventName == SSEEventType.MESSAGE ||
      eventName == SSEEventType.FUNCTION_CALL) {
    final agentMessageDto = AgentMessageDto.fromJson(jsonDecode(eventData));
    listen(sessionId, agentMessageDto);
    return;
  }

  if (eventName == SSEEventType.CHUNK) {
    final agentMessageChunkDto = AgentMessageChunkDto.fromJson(
      jsonDecode(eventData),
    );
    listenChunk(sessionId, agentMessageChunkDto);
    return;
  }
}
