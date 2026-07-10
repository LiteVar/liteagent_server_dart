import 'dart:convert';
import 'dart:io';

const _verificationToken = 'PERSIST-7319';

/// Deterministic OpenAI-compatible server for the persistence example.
///
/// It returns the verification token on the second turn only when the request
/// contains the first turn, making it useful for testing restored context.
Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 19529 : int.parse(args.first);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('[mock-openai] listening on http://127.0.0.1:$port/v1');

  await for (final request in server) {
    if (request.method != 'POST' ||
        request.uri.path != '/v1/chat/completions') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }

    final body = jsonDecode(await utf8.decoder.bind(request).join());
    final data = (body as Map).cast<String, dynamic>();
    final messages = (data['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final texts = messages.map(_messageText).toList();
    final asksForCode = texts.any(
      (text) => text.contains('What verification code'),
    );
    final containsStoredTurn =
        asksForCode &&
        texts.any(
          (text) => text.contains(
            'Remember this verification code: $_verificationToken',
          ),
        );
    final answer = asksForCode
        ? (containsStoredTurn ? _verificationToken : 'MISSING_CONTEXT')
        : 'STORED';

    stdout.writeln(
      '[mock-openai] messages=${messages.length}, asksForCode=$asksForCode, '
      'restoredTurn=$containsStoredTurn, answer=$answer',
    );

    if (data['stream'] == true) {
      await _writeStream(
        request.response,
        data['model'] as String? ?? 'mock',
        answer,
      );
    } else {
      await _writeResponse(
        request.response,
        data['model'] as String? ?? 'mock',
        answer,
      );
      continue;
    }

    await request.response.close();
  }
}

String _messageText(Map<String, dynamic> message) {
  final content = message['content'];
  if (content is String) return content;
  if (content is List<dynamic>) {
    return content
        .map((part) {
          if (part is Map<String, dynamic>) {
            return part['text']?.toString() ?? '';
          }
          return '';
        })
        .join('\n');
  }
  return '';
}

Future<void> _writeStream(
  HttpResponse response,
  String model,
  String answer,
) async {
  response.headers.contentType = ContentType(
    'text',
    'event-stream',
    charset: 'utf-8',
  );
  response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

  final chunk = {
    'id': 'chatcmpl-persistence-example',
    'object': 'chat.completion.chunk',
    'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'model': model,
    'choices': [
      {
        'index': 0,
        'delta': {'role': 'assistant', 'content': answer},
        'finish_reason': null,
      },
    ],
  };
  final done = {
    'id': 'chatcmpl-persistence-example',
    'object': 'chat.completion.chunk',
    'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'model': model,
    'choices': [
      {'index': 0, 'delta': <String, dynamic>{}, 'finish_reason': 'stop'},
    ],
  };
  response.write('data: ${jsonEncode(chunk)}\n\n');
  response.write('data: ${jsonEncode(done)}\n\n');
  response.write('data: [DONE]\n\n');
}

Future<void> _writeResponse(
  HttpResponse response,
  String model,
  String answer,
) async {
  response.headers.contentType = ContentType.json;
  response.write(
    jsonEncode({
      'id': 'chatcmpl-persistence-example',
      'object': 'chat.completion',
      'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'model': model,
      'choices': [
        {
          'index': 0,
          'message': {'role': 'assistant', 'content': answer},
          'finish_reason': 'stop',
        },
      ],
      'usage': {'prompt_tokens': 1, 'completion_tokens': 1, 'total_tokens': 2},
    }),
  );
  await response.close();
}
