import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dotenv/dotenv.dart';
import 'package:liteagent_core/liteagent_core.dart';
import 'package:liteagent_core/liteagent_service.dart';

const _defaultBaseUrl = 'http://127.0.0.1:9527/api/v1';
const _defaultStatePath = 'example/.persistent_session.json';
const _defaultToken = 'PERSIST-7319';

/// Demonstrates that a session keeps its context after the server process is
/// restarted.
///
/// Run these commands from the repository root:
///
/// 1. `dart run example/persistent_session_example.dart create`
/// 2. Restart `dart run bin/server.dart` without deleting its database.
/// 3. `dart run example/persistent_session_example.dart continue`
///
/// Optional commands:
/// - `dart run example/persistent_session_example.dart history`
/// - `dart run example/persistent_session_example.dart clear`
Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final command = args.first;
  final options = _parseOptions(args.skip(1));
  final stateFile = File(options['state'] ?? _defaultStatePath);

  try {
    switch (command) {
      case 'create':
        await _createSession(
          stateFile: stateFile,
          baseUrl: options['base-url'] ?? _defaultBaseUrl,
          token: options['token'] ?? _defaultToken,
          llmBaseUrlOverride: options['llm-base-url'],
          apiKeyOverride: options['api-key'],
          modelOverride: options['model'],
          force: options.containsKey('force'),
        );
      case 'continue':
        await _continueSession(stateFile, options['base-url']);
      case 'history':
        await _showHistory(stateFile, options['base-url']);
      case 'clear':
        await _clearSession(stateFile, options['base-url']);
      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        exitCode = 64;
    }
  } on Object catch (error) {
    stderr.writeln('[persistent-session] ERROR: $error');
    exitCode = 1;
  }
}

Future<void> _createSession({
  required File stateFile,
  required String baseUrl,
  required String token,
  required String? llmBaseUrlOverride,
  required String? apiKeyOverride,
  required String? modelOverride,
  required bool force,
}) async {
  if (stateFile.existsSync() && !force) {
    throw StateError(
      '${stateFile.path} already exists. Run clear first or pass --force.',
    );
  }

  final env = DotEnv();
  if (File('example/.env').existsSync()) {
    env.load(['example/.env']);
  }
  final llmBaseUrl = llmBaseUrlOverride ?? env['baseUrl'];
  final apiKey = apiKeyOverride ?? env['apiKey'];
  if (llmBaseUrl == null || llmBaseUrl.isEmpty) {
    throw StateError('Missing baseUrl in example/.env');
  }
  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('Missing apiKey in example/.env');
  }

  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  final capability = CapabilityDto(
    llmConfig: LLMConfigDto(
      baseUrl: llmBaseUrl,
      apiKey: apiKey,
      model: modelOverride ?? env['model'] ?? 'gpt-3.5-turbo',
      temperature: 0,
    ),
    systemPrompt:
        'Remember facts supplied by the user across turns. Follow exact-output '
        'instructions and do not add explanations.',
    timeoutSeconds: 20,
  );

  final response = await dio.post<dynamic>(
    '/initSession',
    data: capability.toJson(),
  );
  final session = SessionDto.fromJson(
    (response.data as Map).cast<String, dynamic>(),
  );

  final answer = await _sendMessage(
    baseUrl,
    session.sessionId,
    'Remember this verification code: $token. Reply only STORED.',
  );

  await stateFile.parent.create(recursive: true);
  await stateFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sessionId': session.sessionId,
      'token': token,
      'baseUrl': baseUrl,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    }),
  );

  stdout.writeln('[create] sessionId: ${session.sessionId}');
  stdout.writeln('[create] assistant: $answer');
  stdout.writeln('[create] state: ${stateFile.path}');
  stdout.writeln(
    '[create] Now restart the server without deleting its database, then run '
    '`dart run example/persistent_session_example.dart continue`.',
  );
}

Future<void> _continueSession(File stateFile, String? baseUrlOverride) async {
  final state = await _readState(stateFile);
  final sessionId = state['sessionId'] as String;
  final token = state['token'] as String;
  final baseUrl = baseUrlOverride ?? state['baseUrl'] as String;

  final answer = await _sendMessage(
    baseUrl,
    sessionId,
    'What verification code did I ask you to remember? Reply only with the '
    'exact code.',
  );

  stdout.writeln('[continue] sessionId: $sessionId');
  stdout.writeln('[continue] assistant: $answer');
  if (!answer.contains(token)) {
    throw StateError('Restore verification failed: expected "$token".');
  }
  stdout.writeln('[continue] PASS: restored context contains $token');
}

Future<void> _showHistory(File stateFile, String? baseUrlOverride) async {
  final state = await _readState(stateFile);
  final sessionId = state['sessionId'] as String;
  final baseUrl = baseUrlOverride ?? state['baseUrl'] as String;
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  final response = await dio.get<dynamic>(
    '/history',
    queryParameters: {'sessionId': sessionId},
  );
  final history = response.data as List<dynamic>;
  stdout.writeln(
    '[history] sessionId: $sessionId, messages: ${history.length}',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(history));
}

Future<void> _clearSession(File stateFile, String? baseUrlOverride) async {
  final state = await _readState(stateFile);
  final sessionId = state['sessionId'] as String;
  final baseUrl = baseUrlOverride ?? state['baseUrl'] as String;
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  await dio.get<dynamic>('/clear', queryParameters: {'sessionId': sessionId});
  await stateFile.delete();
  stdout.writeln('[clear] removed session $sessionId and ${stateFile.path}');
}

Future<Map<String, dynamic>> _readState(File stateFile) async {
  if (!stateFile.existsSync()) {
    throw StateError(
      '${stateFile.path} does not exist. Run the create command first.',
    );
  }
  final decoded = jsonDecode(await stateFile.readAsString());
  if (decoded is! Map<String, dynamic> ||
      decoded['sessionId'] is! String ||
      decoded['token'] is! String ||
      decoded['baseUrl'] is! String) {
    throw const FormatException('Invalid persistent-session state file.');
  }
  return decoded;
}

Future<String> _sendMessage(
  String baseUrl,
  String sessionId,
  String prompt,
) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(
      '$baseUrl/chat',
    ).replace(queryParameters: {'sessionId': sessionId});
    final request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.write(
      jsonEncode(
        UserTaskDto(
          content: [ContentDto(type: ContentType.TEXT, message: prompt)],
          isChunk: false,
        ).toJson(),
      ),
    );

    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      final body = await utf8.decoder.bind(response).join();
      throw HttpException(
        'POST $uri returned ${response.statusCode}: $body',
        uri: uri,
      );
    }

    String? assistantAnswer;
    await for (final event in _decodeSse(utf8.decoder.bind(response))) {
      if (event.event != 'message') continue;
      final json = jsonDecode(event.data);
      if (json is! Map<String, dynamic>) continue;
      final content = json['content'];
      if (json['type'] == AgentMessageType.TASK_STATUS &&
          content is Map<String, dynamic> &&
          content['status'] == TaskStatusType.EXCEPTION) {
        throw StateError('Agent task failed: ${content['description']}');
      }
      final message = AgentMessageDto.fromJson(json);
      if (message.role == TextRoleType.ASSISTANT &&
          message.type == AgentMessageType.TEXT &&
          message.content is String) {
        assistantAnswer = message.content as String;
      }
    }

    if (assistantAnswer == null || assistantAnswer.trim().isEmpty) {
      throw StateError('The SSE stream ended without an assistant response.');
    }
    return assistantAnswer.trim();
  } finally {
    client.close(force: true);
  }
}

Stream<_SseEvent> _decodeSse(Stream<String> input) async* {
  var buffer = '';
  await for (final chunk in input) {
    buffer += chunk.replaceAll('\r\n', '\n');
    while (true) {
      final separator = buffer.indexOf('\n\n');
      if (separator < 0) break;
      final event = _parseSseFrame(buffer.substring(0, separator));
      buffer = buffer.substring(separator + 2);
      if (event != null) yield event;
    }
  }
  final trailing = _parseSseFrame(buffer);
  if (trailing != null) yield trailing;
}

_SseEvent? _parseSseFrame(String frame) {
  if (frame.trim().isEmpty) return null;
  String? event;
  final data = <String>[];
  for (final line in frame.split('\n')) {
    if (line.startsWith('event:')) {
      event = line.substring('event:'.length).trim();
    } else if (line.startsWith('data:')) {
      data.add(line.substring('data:'.length).trimLeft());
    }
  }
  if (data.isEmpty) return null;
  return _SseEvent(event ?? 'message', data.join('\n'));
}

Map<String, String> _parseOptions(Iterable<String> arguments) {
  final options = <String, String>{};
  for (final argument in arguments) {
    if (!argument.startsWith('--')) {
      throw FormatException('Invalid option: $argument');
    }
    final option = argument.substring(2);
    final separator = option.indexOf('=');
    if (separator < 0) {
      options[option] = 'true';
    } else {
      options[option.substring(0, separator)] = option.substring(separator + 1);
    }
  }
  return options;
}

void _printUsage() {
  stdout.writeln('''
Persistent session restore example

Usage:
  dart run example/persistent_session_example.dart create [options]
  dart run example/persistent_session_example.dart continue [options]
  dart run example/persistent_session_example.dart history [options]
  dart run example/persistent_session_example.dart clear [options]

Options:
  --base-url=URL  Server API root (default: $_defaultBaseUrl)
  --state=PATH    Local session state file (default: $_defaultStatePath)
  --token=TEXT    Verification token used by create (default: $_defaultToken)
  --llm-base-url=URL  Override example/.env baseUrl for create
  --api-key=KEY       Override example/.env apiKey for create
  --model=NAME        Override example/.env model for create
  --force         Overwrite an existing state file when creating
''');
}

class _SseEvent {
  final String event;
  final String data;

  const _SseEvent(this.event, this.data);
}
