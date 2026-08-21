import 'package:drift/native.dart';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/src/db/agent_database.dart';
import 'package:liteagent_server_dart/src/history_dto.dart';
import 'package:liteagent_server_dart/src/service/session_manage_service.dart';
import 'package:liteagent_server_dart/src/service/session_message_manage_service.dart';
import 'package:liteagent_server_dart/src/service/session_runtime_service.dart';
import 'package:test/test.dart';

void main() {
  late AgentDatabase database;
  late SessionManageServiceByDB sessions;
  late SessionMessageManageServiceByDB messages;
  late SessionRuntimeService runtime;

  setUp(() {
    database = AgentDatabase(NativeDatabase.memory());
    sessions = SessionManageServiceByDB(database);
    messages = SessionMessageManageServiceByDB(database);
    runtime = SessionRuntimeService(
      agentService: AgentService(messageManageServiceList: [messages]),
      sessionManageService: sessions,
      messageManageService: messages,
    );
  });

  tearDown(() => database.close());

  test(
    'single agent summary contains root user, final answer, and done',
    () async {
      await _addRoot(sessions, 'root');
      await _add(
        messages,
        origin: 'root',
        message: _text(
          'root',
          'task',
          SessionRoleType.USER,
          SessionRoleType.AGENT,
          'do it',
          1,
        ),
      );
      await _add(
        messages,
        origin: 'root',
        message: _text(
          'root',
          'task',
          SessionRoleType.AGENT,
          SessionRoleType.USER,
          'done answer',
          2,
          completions: CompletionsDto(
            usage: TokenUsageDto(
              promptTokens: 10,
              completionTokens: 4,
              totalTokens: 14,
              contextUsageRatio: 0.25,
            ),
            id: 'completion',
            model: 'test',
          ),
        ),
      );
      await _add(
        messages,
        origin: 'root',
        message: _status('root', 'task', 'done', 3),
      );

      final summary = (await runtime.getHistorySummary(
        'root',
        page: 1,
        pageSize: 30,
      )).single;
      expect(summary.userMessage?.content, 'do it');
      expect(summary.finalMessage?.content, 'done answer');
      expect(summary.status, HistoryTurnStatus.done);
      expect(summary.usage?.totalTokens, 14);
      expect(summary.processMessageCount, 1);
    },
  );

  test('child start and done cannot override a successful root task', () async {
    await _addRoot(sessions, 'root', child: 'child');
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'user', 'agent', 'ask', 1),
    );
    await _add(
      messages,
      origin: 'child',
      message: _status('child', 'task', 'start', 2),
    );
    await _add(
      messages,
      origin: 'child',
      message: _status('child', 'task', 'done', 3),
    );
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'agent', 'user', 'answer', 4),
    );

    final summary = (await runtime.getHistorySummary(
      'root',
      page: 1,
      pageSize: 30,
    )).single;
    expect(summary.status, HistoryTurnStatus.done);
    expect(summary.error, isNull);
  });

  test('child exception cannot override root final answer and done', () async {
    await _addRoot(sessions, 'root', child: 'child');
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'user', 'agent', 'ask', 1),
    );
    await _add(
      messages,
      origin: 'child',
      message: _status('child', 'task', 'exception', 2, error: 'child failed'),
    );
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'agent', 'user', 'recovered', 3),
    );
    await _add(
      messages,
      origin: 'root',
      message: _status('root', 'task', 'done', 4),
    );

    final summary = (await runtime.getHistorySummary(
      'root',
      page: 1,
      pageSize: 30,
    )).single;
    expect(summary.status, HistoryTurnStatus.done);
    expect(summary.error, isNull);
  });

  test('root exception produces error and root error description', () async {
    await _addRoot(sessions, 'root', child: 'child');
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'user', 'agent', 'ask', 1),
    );
    await _add(
      messages,
      origin: 'child',
      message: _status('child', 'task', 'exception', 2, error: 'child failed'),
    );
    await _add(
      messages,
      origin: 'root',
      message: _status('root', 'task', 'error', 3, error: 'root failed'),
    );

    final summary = (await runtime.getHistorySummary(
      'root',
      page: 1,
      pageSize: 30,
    )).single;
    expect(summary.status, HistoryTurnStatus.error);
    expect(summary.error, 'root failed');
  });

  test('older root user wins over a newer child user message', () async {
    await _addRoot(sessions, 'root', child: 'child');
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'user', 'agent', 'root request', 1),
    );
    await _add(
      messages,
      origin: 'child',
      message: _text('child', 'task', 'user', 'agent', 'child request', 9),
    );
    await _add(
      messages,
      origin: 'root',
      message: _text('root', 'task', 'agent', 'user', 'answer', 10),
    );

    final summary = (await runtime.getHistorySummary(
      'root',
      page: 1,
      pageSize: 30,
    )).single;
    expect(summary.userMessage?.content, 'root request');
  });

  test(
    'task without final answer or root terminal status is running',
    () async {
      await _addRoot(sessions, 'root');
      await _add(
        messages,
        origin: 'root',
        message: _text('root', 'task', 'user', 'agent', 'wait', 1),
      );
      await _add(
        messages,
        origin: 'root',
        message: _status('root', 'task', 'start', 2),
      );

      final summary = (await runtime.getHistorySummary(
        'root',
        page: 1,
        pageSize: 30,
      )).single;
      expect(summary.status, HistoryTurnStatus.running);
      expect(summary.completedAt, isNull);
    },
  );

  test('summary pagination uses turns and returns newest turn first', () async {
    await _addRoot(sessions, 'root');
    for (var turn = 1; turn <= 3; turn++) {
      final task = 'task-$turn';
      await _add(
        messages,
        origin: 'root',
        message: _text(
          'root',
          task,
          'user',
          'agent',
          'request $turn',
          turn * 10,
        ),
      );
      await _add(
        messages,
        origin: 'root',
        message: _text(
          'root',
          task,
          'agent',
          'user',
          'answer $turn',
          turn * 10 + 1,
        ),
      );
      await _add(
        messages,
        origin: 'root',
        message: _status('root', task, 'done', turn * 10 + 2),
      );
    }

    final first = await runtime.getHistorySummary('root', page: 1, pageSize: 2);
    final second = await runtime.getHistorySummary(
      'root',
      page: 2,
      pageSize: 2,
    );
    expect(first.map((item) => item.originalTaskId), ['task-3', 'task-2']);
    expect(second.map((item) => item.originalTaskId), ['task-1']);
  });

  test(
    'process returns only one task, includes child messages, and paginates stably',
    () async {
      await _addRoot(sessions, 'root', child: 'child');
      await _add(
        messages,
        origin: 'root',
        message: _text('root', 'task', 'user', 'agent', 'ask', 1),
      );
      await _add(
        messages,
        origin: 'child',
        message: _status('child', 'task', 'start', 2),
      );
      await _add(
        messages,
        origin: 'child',
        message: _text(
          'child',
          'task',
          'agent',
          'agent',
          'reasoning',
          2,
          type: AgentMessageType.REASONING,
        ),
      );
      await _add(
        messages,
        origin: 'root',
        message: _status('root', 'task', 'done', 3),
      );
      await _add(
        messages,
        origin: 'root',
        message: _text('root', 'task', 'agent', 'user', 'answer', 4),
      );
      await _add(
        messages,
        origin: 'root',
        message: _status('root', 'other', 'start', 5),
      );

      final page1 = await runtime.getHistoryProcess(
        'root',
        'task',
        page: 1,
        pageSize: 2,
      );
      final page2 = await runtime.getHistoryProcess(
        'root',
        'task',
        page: 2,
        pageSize: 2,
      );
      expect(page1.map((message) => message.type), [
        AgentMessageType.TASK_STATUS,
        AgentMessageType.REASONING,
      ]);
      expect(page2.map((message) => message.type), [
        AgentMessageType.TASK_STATUS,
      ]);
      expect(
        [
          ...page1,
          ...page2,
        ].every((message) => message.originalTaskId == 'task'),
        isTrue,
      );
      expect(page1.first.sessionId, 'child');
    },
  );

  test('process task lookup is isolated by root session', () async {
    await _addRoot(sessions, 'session-a');
    await _addRoot(sessions, 'session-b');
    await _add(
      messages,
      origin: 'session-b',
      message: _text('session-b', 'task-b', 'user', 'agent', 'secret', 1),
    );
    await _add(
      messages,
      origin: 'session-b',
      message: _status('session-b', 'task-b', 'start', 2),
    );

    expect(
      await runtime.getHistoryProcess(
        'session-a',
        'task-b',
        page: 1,
        pageSize: 50,
      ),
      isEmpty,
    );
  });
}

Future<void> _addRoot(
  SessionManageServiceByDB sessions,
  String root, {
  String? child,
}) async {
  if (child != null) {
    await sessions.addSession(
      sessionId: child,
      capability: CapabilityDto(systemPrompt: 'child'),
      rootSessionId: root,
      inlinePath: 'worker',
    );
  }
  await sessions.addSession(
    sessionId: root,
    capability: CapabilityDto(
      systemPrompt: 'root',
      subAgentList: child == null
          ? null
          : [
              AgentDto(
                name: 'worker',
                capability: CapabilityDto(systemPrompt: 'child'),
              ),
            ],
    ),
  );
}

Future<void> _add(
  SessionMessageManageServiceByDB messages, {
  required String origin,
  required AgentMessageDto message,
}) => messages.addMessage(
  SessionAgentMessageDto(sessionId: origin, agentMessageDto: message),
);

AgentMessageDto _text(
  String sessionId,
  String taskId,
  String role,
  String to,
  String content,
  int second, {
  String type = AgentMessageType.TEXT,
  CompletionsDto? completions,
}) => AgentMessageDto(
  sessionId: sessionId,
  originalTaskId: taskId,
  taskId: '$taskId-$second',
  role: role,
  to: to,
  type: type,
  content: content,
  completions: completions,
  createTime: DateTime.utc(2026, 7, 12, 0, 0, second),
);

AgentMessageDto _status(
  String sessionId,
  String taskId,
  String status,
  int second, {
  String? error,
}) => AgentMessageDto(
  sessionId: sessionId,
  originalTaskId: taskId,
  taskId: '$taskId-$second',
  role: SessionRoleType.AGENT,
  to: SessionRoleType.CLIENT,
  type: AgentMessageType.TASK_STATUS,
  content: TaskStatusDto(
    status: status,
    taskId: taskId,
    description: error == null ? null : {'message': error},
  ),
  createTime: DateTime.utc(2026, 7, 12, 0, 0, second),
);
