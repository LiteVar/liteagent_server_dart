import 'dart:convert';
import 'dart:async';
import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:dotenv/dotenv.dart';
import 'package:liteagent_core/liteagent_core.dart';
import 'package:liteagent_core/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import 'package:opentool_dart/opentool_client.dart' as ot;

import 'listener.dart';
import 'mock/driver/mock_driver.dart';

/// StreamCall example (client tool callback -> server ToolAgent streamCall).
///
/// Prepare:
/// 1) Start server:
///    `dart run bin/server.dart`
/// 2) Add LLM `baseUrl` and `apiKey` to `example/.env`
/// 3) Run:
///    `dart run example/stream_call_example.dart`
///
/// You should see TOOL_RETURN events like:
/// - `{"start":"sequentiallyRead","data":{}}`
/// - `{"data":{"data":"Hello"}}`
/// - `{"data":{"data":"World"}}`
/// - `{"done":{}}`
final String prompt =
    "Use tool function `sequentiallyRead` to read all items from storage, then summarize.";

Config config = initConfig();

Future<void> main() async {
  final baseUrl =
      "http://127.0.0.1:${config.server.port}${config.server.apiPathPrefix}";

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // headers: {"Authorization": "Bearer <KEY>"}
    ),
  );

  // Optional: set server-wide preset OpenSpec list.
  await setPresetOpenSpecList(dio);

  final mockDriver = await _buildMockDriver();
  final callbackOpenTool = await _loadMockOpenToolJson();

  final capabilityDto = CapabilityDto(
    llmConfig: _buildLLMConfigDto(),
    systemPrompt: _buildSystemPrompt(),
    callbackOpenTool: CallbackOpenToolDto(
      opentool: callbackOpenTool,
      timeout: 120,
    ),
    timeoutSeconds: 60,
  );

  final sessionDto = await initChat(dio, capabilityDto);
  if (sessionDto == null) return;

  print("[sessionDto] ${sessionDto.toJson()}");
  print("[prompt] $prompt");

  final done = Completer<void>();

  final sseStream = await sendUserMessage(
    baseUrl,
    sessionDto.sessionId,
    prompt,
  );
  _decodeSse(sseStream).listen(
    (event) => _onSseEvent(
      dio: dio,
      sessionId: sessionDto.sessionId,
      event: event,
      mockDriver: mockDriver,
    ),
    onDone: () {
      print("[sseDone]");
      if (!done.isCompleted) done.complete();
    },
    onError: (e) {
      print("[sseError] $e");
      if (!done.isCompleted) done.completeError(e);
    },
  );

  try {
    await done.future.timeout(const Duration(seconds: 90));
  } catch (_) {
    // If the stream does not end, stop the session to unblock local runs.
    await stopChat(dio, sessionDto.sessionId);
  }

  await clearChat(dio, sessionDto.sessionId);
}

LLMConfigDto _buildLLMConfigDto() {
  final env = DotEnv()..load(['example/.env']);
  return LLMConfigDto(
    baseUrl: env["baseUrl"]!,
    apiKey: env["apiKey"]!,
    model: "gpt-4o-mini",
  );
}

String _buildSystemPrompt() {
  return 'You are a tools caller who can call tools to help me manage my storage.';
}

Future<void> setPresetOpenSpecList(Dio dio) async {
  try {
    final presetList = [
      PresetOpenSpecDto(
        systemPrompt: "Respond with concise bullet points by default.",
      ),
    ];
    await dio.post(
      '/presetOpenSpecList',
      data: presetList.map((preset) => preset.toJson()).toList(),
    );
  } catch (e) {
    print("[setPresetOpenSpecList] $e");
  }
}

Future<MockDriver> _buildMockDriver() async {
  final jsonPath = [
    io.Directory.current.path,
    'example',
    'mock',
    'driver',
    'mock-tool.json',
  ].join(io.Platform.pathSeparator);
  final openTool = await ot.OpenToolJsonLoader().loadFromFile(jsonPath);
  return MockDriver(openTool);
}

Future<String> _loadMockOpenToolJson() async {
  final jsonPath = [
    io.Directory.current.path,
    'example',
    'mock',
    'driver',
    'mock-tool.json',
  ].join(io.Platform.pathSeparator);
  return io.File(jsonPath).readAsString();
}

Future<SessionDto?> initChat(Dio dio, CapabilityDto capabilityDto) async {
  try {
    final response = await dio.post(
      '/initSession',
      data: capabilityDto.toJson(),
    );
    final sessionDto = SessionDto.fromJson(response.data);
    print("[initChat->RES] ${sessionDto.toJson()}");
    return sessionDto;
  } catch (e) {
    print("[initChat->ERR] $e");
  }
  return null;
}

Future<Stream<String>> sendUserMessage(
  String baseUrl,
  String sessionId,
  String prompt,
) async {
  final contentDto = ContentDto(type: ContentType.TEXT, message: prompt);
  final userTaskDto = UserTaskDto(content: [contentDto], isChunk: true);
  return await _chat(baseUrl, sessionId, userTaskDto);
}

Future<Stream<String>> _chat(
  String baseUrl,
  String sessionId,
  UserTaskDto userTaskDto,
) async {
  final uri = Uri.parse('$baseUrl/chat?sessionId=$sessionId');
  final httpClient = io.HttpClient();
  final request = await httpClient.postUrl(uri);

  request.headers.add(io.HttpHeaders.acceptHeader, 'text/event-stream');
  request.headers.add(io.HttpHeaders.contentTypeHeader, 'application/json');

  request.add(utf8.encode(jsonEncode(userTaskDto.toJson())));

  final response = await request.close();
  return response.transform(utf8.decoder);
}

Future<SessionDto?> stopChat(Dio dio, String sessionId) async {
  try {
    final response = await dio.get(
      '/stop',
      queryParameters: {"sessionId": sessionId},
    );
    return SessionDto.fromJson(response.data);
  } catch (e) {
    print("[stopChat->ERR] $e");
  }
  return null;
}

Future<SessionDto?> clearChat(Dio dio, String sessionId) async {
  try {
    final response = await dio.get(
      '/clear',
      queryParameters: {"sessionId": sessionId},
    );
    final sessionDto = SessionDto.fromJson(response.data);
    print("[clearSessionDto] ${sessionDto.toJson()}");
    return sessionDto;
  } catch (e) {
    print("[clearChat->ERR] $e");
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

Future<void> _onSseEvent({
  required Dio dio,
  required String sessionId,
  required _SseEvent event,
  required MockDriver mockDriver,
}) async {
  final eventName = event.event ?? SSEEventType.MESSAGE;
  final json = jsonDecode(event.data);

  if (eventName == SSEEventType.MESSAGE) {
    final agentMessageDto = AgentMessageDto.fromJson(json);
    listen(sessionId, agentMessageDto);
    return;
  }

  if (eventName == SSEEventType.CHUNK) {
    final agentMessageChunkDto = AgentMessageChunkDto.fromJson(json);
    listenChunk(sessionId, agentMessageChunkDto);
    return;
  }

  if (eventName == SSEEventType.FUNCTION_CALL) {
    final agentMessageDto = AgentMessageDto.fromJson(json);
    listen(sessionId, agentMessageDto);

    if (agentMessageDto.type != ToolMessageType.FUNCTION_CALL) return;
    if (agentMessageDto.content is! Map<String, dynamic>) return;

    final functionCall = ot.FunctionCall.fromJson(
      (agentMessageDto.content as Map<String, dynamic>).cast<String, dynamic>(),
    );

    await mockDriver.streamCall(functionCall, (streamEvent, toolReturn) async {
      await _streamCallback(
        dio: dio,
        sessionId: sessionId,
        event: streamEvent,
        toolReturn: toolReturn,
      );
    });
  }
}

Future<void> _streamCallback({
  required Dio dio,
  required String sessionId,
  required String event,
  required ot.ToolReturn toolReturn,
}) async {
  await dio.post(
    '/streamCallback',
    queryParameters: {"sessionId": sessionId},
    data: {"event": event, "toolReturn": toolReturn.toJson()},
  );
}
