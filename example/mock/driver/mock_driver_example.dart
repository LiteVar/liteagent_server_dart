import 'dart:convert';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:dotenv/dotenv.dart';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lite_agent_core_dart_server/lite_agent_core_dart_server.dart';
import '../../listener.dart';

String prompt = "Find the text with ID 0.";
String prompt1 = "Find the text with ID 1.";

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

  CapabilityDto capabilityDto = CapabilityDto(
    llmConfig: _buildLLMConfigDto(),
    systemPrompt: _buildSystemPrompt(),
    openSpecList: await _buildOpenSpecList(),
    timeoutSeconds: 20
  );

  print("[capabilityDto] " + capabilityDto.toJson().toString());

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

    Stream<String> sseStream2 = await sendUserMessage(baseUrl, sessionDto.sessionId, prompt1);

    sseStream2.listen((sseString) {
      _onData(sessionDto.sessionId, sseString);
    },
        onDone: () {
          print("[sseDone2]");
        },
        onError: (e) {
          print("[sseError2] " + e.toString());
        }
    );

    print("[prompt] " + prompt);

    await sleep(25);

    SessionDto? stopSessionDto = await stopChat(dio, sessionDto.sessionId);
    print("[stopSessionDto] " + stopSessionDto!.toJson().toString());

    await sleep(5);

    SessionDto? clearSessionDto = await clearChat(dio, sessionDto.sessionId);
    print("[clearSessionDto] " + clearSessionDto!.toJson().toString());
  }
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
  ContentDto userMessageDto = ContentDto(type: ContentType.TEXT, message: prompt);
  UserTaskDto userTaskDto = UserTaskDto(content: [userMessageDto], stream: true);

  return await chat(baseUrl, sessionId, userTaskDto);
}

Future<SessionDto?> stopChat(Dio dio, String sessionId) async {
  try {
    Response response = await dio.get('/stop', queryParameters: {"sessionId": sessionId});
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

Future<SessionDto?> clearChat(Dio dio, String sessionId) async {
  try {
    Response response = await dio.get('/clear', queryParameters: {"sessionId": sessionId});
    SessionDto sessionDto = SessionDto.fromJson(response.data);
    return sessionDto;
  } catch (e) {
    print(e);
  }
  return null;
}

LLMConfigDto _buildLLMConfigDto() {
  DotEnv env = DotEnv();
  env.load(['example/.env']);
  return LLMConfigDto(
      baseUrl: env["baseUrl"]!, apiKey: env["apiKey"]!, model: "gpt-3.5-turbo");
}

/// Use Prompt engineering to design SystemPrompt
/// https://platform.openai.com/docs/guides/prompt-engineering
String _buildSystemPrompt() {
  return 'A storage management tool that knows how to add, delete, modify, and query my texts.';
}

Future<List<OpenSpecDto>> _buildOpenSpecList() async {
  String opentoolFolder = "${io.Directory.current.path}${io.Platform.pathSeparator}example${io.Platform.pathSeparator}mock${io.Platform.pathSeparator}driver";
  List<String> opentoolFileNameList = [
    "mock-tool.json"
  ];

  List<OpenSpecDto> openSpecDtoList = [];

  for (String opentoolFileName in opentoolFileNameList) {
    String jsonPath = "$opentoolFolder${io.Platform.pathSeparator}$opentoolFileName";
    io.File file = io.File(jsonPath);
    String jsonString = await file.readAsString();
    OpenSpecDto openSpecDto = OpenSpecDto(openSpec: jsonString, protocol: Protocol.OPENTOOL, openToolId: "mock-tool");
    openSpecDtoList.add(openSpecDto);
  }

  return openSpecDtoList;
}

Future<void> _onData(String sessionId, String data) async {
  // final eventRegex = RegExp(r"^(?:event:\s*(?<event>.+?)\r?\n)?data:\s*(?<data>\{.*\})$");
  final eventRegex = RegExp(r'event: (\w+)\ndata: (.*?)\n\n');
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