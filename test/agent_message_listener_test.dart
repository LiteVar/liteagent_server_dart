import 'dart:async';
import 'dart:convert';

import 'package:liteagent_core/liteagent_core.dart';
import 'package:liteagent_core/liteagent_service.dart';
import 'package:liteagent_server_dart/src/controller/agent_message_listener.dart';
import 'package:test/test.dart';

void main() {
  test('SSE forwards standalone reasoning messages unchanged', () async {
    final controller = StreamController<List<int>>();
    final subscriber = AgentMessageSubscriberBySSE(controller);
    final event = controller.stream.first;

    subscriber.addMessage(
      AgentMessageDto(
        sessionId: 'session-1',
        originalTaskId: 'task-1',
        taskId: 'task-1',
        role: AgentRoleType.LLM,
        to: AgentRoleType.AGENT,
        type: AgentMessageType.REASONING,
        content: 'reasoning details',
        createTime: DateTime.utc(2026, 7, 11),
      ),
    );

    final payload = utf8.decode(await event);
    expect(payload, startsWith('event:message\ndata:'));
    final data = payload.substring(
      payload.indexOf('data:') + 'data:'.length,
      payload.length - 2,
    );
    final json = jsonDecode(data) as Map<String, dynamic>;
    expect(json['type'], AgentMessageType.REASONING);
    expect(json['content'], 'reasoning details');

    await controller.close();
  });
}
