import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:dotenv/dotenv.dart';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lite_agent_core_dart_server/lite_agent_core_dart_server.dart';
import 'listener.dart';

Config config = initConfig();

/// [IMPORTANT] Prepare:
/// 1. HTTP Server, according to `/example/mock/server/mock_http_server`, which server is running.
/// 2. OneAPI JSON file, which is described the HTTP Server API.
/// 3. Add LLM baseUrl and apiKey to `.env` file
Future<void> main() async {
  String baseUrl = "http://127.0.0.1:${config.server.port}${config.server.apiPathPrefix}";

  Dio dio = Dio(BaseOptions(baseUrl: baseUrl,
    // headers: {"Authorization": "Bearer <KEY>"}
  ));

  String systemPrompt = "You play the role of a tool caller. You can help me decide which tool to call to complete the task according to my requirements. You can only call one tool at a time. \n\nYou support the following tools:\n\n 1. Translation\n 2. Add, delete, modify and query tools";
  String prompt = "Find the text with ID 0 and translate it into Chinese.";

  SessionDto? sessionDto1 = await _buildTextAgent(dio);
  SessionDto? sessionDto2 = await _buildToolAgent(dio);

  if(sessionDto1 == null || sessionDto2 == null) {
    print("Init sub session failed.");
    return;
  }

  CapabilityDto capabilityDto = CapabilityDto(
    llmConfig: _buildLLMConfigDto(),
    systemPrompt: systemPrompt,
    sessionList: [
      SessionNameDto(sessionId: sessionDto1.sessionId, name: "translator"),
      SessionNameDto(sessionId: sessionDto2.sessionId, name: "CRUDTools")
    ]
  );

  SessionDto? sessionDto = await initChat(dio, capabilityDto);

  if (sessionDto != null) {
    print("[sessionDto] " + sessionDto.toJson().toString());

    Stream<String> sseStream = await sendUserMessage(baseUrl, sessionDto.sessionId, prompt);

    sseStream.listen((sseString) {
      _onData(sessionDto.sessionId, sseString);
    },
      onDone: () {
        print("[sseDone]");
      },
      onError: (e) {
        print("[sseError] " + e.toString());
      }
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
  return LLMConfigDto(baseUrl: env["baseUrl"]!, apiKey: env["apiKey"]!, model: "gpt-3.5-turbo");
}

Future<SessionDto?> _buildTextAgent(Dio dio) async {
  String systemPrompt = "Playing as a translator, knowing how to translate between languages.";

  CapabilityDto capabilityDto = CapabilityDto(llmConfig: _buildLLMConfigDto(), systemPrompt: systemPrompt);
  return await initChat(dio, capabilityDto);
}

Future<SessionDto?> _buildToolAgent(Dio dio) async {
  DotEnv env = DotEnv();env.load(['example/.env']);LLMConfigDto llmConfig = LLMConfigDto(baseUrl: env["baseUrl"]!, apiKey: env["apiKey"]!, model: "gpt-4o-mini");

  String openAPIFolder = "${io.Directory.current.path}${io.Platform.pathSeparator}example${io.Platform.pathSeparator}mock${io.Platform.pathSeparator}server";
  List<String> openAPIFileNameList = [
    "mock_openapi.json"
  ];

  List<OpenSpecDto> openSpecDtoList = [];
  for (String openAPIFileName in openAPIFileNameList) {
    String jsonPath = "$openAPIFolder${io.Platform.pathSeparator}$openAPIFileName";
    io.File file = io.File(jsonPath);
    String jsonString = await file.readAsString();
    OpenSpecDto openSpecDto = OpenSpecDto(openSpec: jsonString, protocol: Protocol.OPENAPI);
    openSpecDtoList.add(openSpecDto);
  }

  String systemPrompt = "A storage management tool that knows how to add, delete, modify, and query my texts.";

  CapabilityDto capabilityDto = CapabilityDto(llmConfig: llmConfig, systemPrompt: systemPrompt, openSpecList: openSpecDtoList);

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
    Response response = await dio.post('/initSession', data: capabilityDto.toJson());
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    print("[initChat->RES] " + sessionDto.toJson().toString());
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<Stream<String>> chat(String baseUrl, String sessionId, UserTaskDto userTaskDto) async {
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

Future<Stream<String>> sendUserMessage(String baseUrl, String sessionId, String prompt) async {
  ContentDto contentDto = ContentDto(type: ContentType.TEXT, message: prompt);
  UserTaskDto userTaskDto = UserTaskDto(content: [contentDto]);
  return await chat(baseUrl, sessionId, userTaskDto);
}

Future<SessionDto?> stopChat(Dio dio, String sessionId) async {
  try {
    Response response =
    await dio.get('/stop', queryParameters: {"sessionId": sessionId});
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<SessionDto?> clearChat(Dio dio, String sessionId) async {
  try {
    Response response =
    await dio.get('/clear', queryParameters: {"sessionId": sessionId});
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<void> _onData(String sessionId, String data) async {
  // final eventRegex = RegExp(r"^(?:event:\s*(?<event>.+?)\r?\n)?data:\s*(?<data>\{.*\})$");
  final eventRegex = RegExp(r'event:(\w+)\ndata:(.*?)\n\n');
  final matches = eventRegex.allMatches(data);

  for (var match in matches) {
    final eventName = match.group(1);
    final eventData = match.group(2);

    if (eventName == SSEEventType.MESSAGE) {
      AgentMessageDto agentMessageDto = AgentMessageDto.fromJson(jsonDecode(eventData!));
      listen(sessionId, agentMessageDto);
    } else if (eventName == SSEEventType.CHUNK) {
      AgentMessageChunkDto agentMessageChunkDto = AgentMessageChunkDto.fromJson(jsonDecode(eventData!));
      listenChunk(sessionId, agentMessageChunkDto);
    }
  }
}
