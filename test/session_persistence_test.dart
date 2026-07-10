import 'dart:io';

import 'package:drift/native.dart';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/src/db/agent_database.dart';
import 'package:liteagent_server_dart/src/service/session_manage_service.dart';
import 'package:liteagent_server_dart/src/service/session_message_manage_service.dart';
import 'package:liteagent_server_dart/src/service/session_runtime_service.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  late AgentDatabase database;
  late SessionManageServiceByDB sessionManageService;
  late SessionMessageManageServiceByDB messageManageService;

  setUp(() {
    database = AgentDatabase(NativeDatabase.memory());
    sessionManageService = SessionManageServiceByDB(database);
    messageManageService = SessionMessageManageServiceByDB(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('persists history and restores only completed context', () async {
    final capability = CapabilityDto(systemPrompt: 'persistent system');
    await sessionManageService.addSession(
      sessionId: 'session-1',
      agentId: 'agent-1',
      capability: capability,
    );

    await _persistTurn(
      messageManageService,
      sessionId: 'session-1',
      taskId: 'done-task',
      userText: 'remember this',
      answerText: 'remembered',
      done: true,
    );
    await _persistTurn(
      messageManageService,
      sessionId: 'session-1',
      taskId: 'incomplete-task',
      userText: 'ignore this partial turn',
      answerText: 'partial',
      done: false,
    );

    final restoredAgentService = AgentService(
      messageManageServiceList: [messageManageService],
    );
    final runtimeService = SessionRuntimeService(
      agentService: restoredAgentService,
      sessionManageService: sessionManageService,
      messageManageService: messageManageService,
    );

    await runtimeService.resolveSession('session-1');

    final restored = restoredAgentService.getSessionAgent('session-1');
    expect(restored, isNotNull);
    expect(restored!.agentSession.hasSystemMessage, isTrue);
    expect(
      restored.agentSession.taskDoneAgentMessageList
          .map((message) => message.originalTaskId)
          .toSet(),
      {'done-task'},
    );
    expect(
      restored.agentSession.taskDoneAgentMessageList.map(
        (message) => message.content.toString(),
      ),
      isNot(contains('partial')),
    );

    final history = await runtimeService.getHistory('session-1');
    expect(history, hasLength(10));
    expect(
      history.any((message) => message.taskId == 'incomplete-task'),
      isTrue,
    );

    final sessions = await runtimeService.getSessionsByAgentId('agent-1');
    expect(sessions, hasLength(1));
    expect(sessions.single.sessionId, 'session-1');
    expect(sessions.single.topic, 'remember this');
  });

  test(
    'coalesces concurrent restore calls and clears persistent data',
    () async {
      await sessionManageService.addSession(
        sessionId: 'session-2',
        capability: CapabilityDto(systemPrompt: 'system'),
      );

      final agentService = AgentService(
        messageManageServiceList: [messageManageService],
      );
      final runtimeService = SessionRuntimeService(
        agentService: agentService,
        sessionManageService: sessionManageService,
        messageManageService: messageManageService,
      );

      await Future.wait([
        runtimeService.resolveSession('session-2'),
        runtimeService.resolveSession('session-2'),
      ]);
      expect(agentService.getSessionAgent('session-2'), isNotNull);

      await runtimeService.clearSession('session-2');
      expect(agentService.getSessionAgent('session-2'), isNull);
      expect(await sessionManageService.getSession('session-2'), isNull);
      expect(
        await messageManageService.getMessagesBySession('session-2'),
        isEmpty,
      );
    },
  );

  test(
    'normalizes an empty original task id from runtime stop events',
    () async {
      await sessionManageService.addSession(
        sessionId: 'session-stop',
        capability: CapabilityDto(systemPrompt: 'system'),
      );
      await messageManageService.addMessage(
        SessionAgentMessageDto(
          sessionId: 'session-stop',
          agentMessageDto: AgentMessageDto(
            sessionId: 'session-stop',
            originalTaskId: '',
            taskId: 'stop-task',
            role: TextRoleType.AGENT,
            to: TextRoleType.CLIENT,
            type: AgentMessageType.TASK_STATUS,
            content: TaskStatusDto(status: TaskStatusType.STOP, taskId: ''),
            createTime: DateTime.utc(2026),
          ),
        ),
      );

      final history = await messageManageService.getMessagesBySession(
        'session-stop',
      );
      expect(history.single.agentMessageDto.originalTaskId, 'stop-task');
    },
  );

  test('rejects missing persisted sessions', () async {
    final runtimeService = SessionRuntimeService(
      agentService: AgentService(),
      sessionManageService: sessionManageService,
      messageManageService: messageManageService,
    );

    await expectLater(
      runtimeService.resolveSession('missing'),
      throwsA(isA<PersistedSessionNotFoundException>()),
    );
  });

  test('migrates schema v1 messages without dropping legacy history', () async {
    await database.close();
    final tempDirectory = await Directory.systemTemp.createTemp(
      'liteagent-server-migration-',
    );
    final databaseFile = File('${tempDirectory.path}/agent.db');
    final legacy = sqlite.sqlite3.open(databaseFile.path);
    legacy.execute('''
      CREATE TABLE agents (
        agent_id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        capability TEXT NOT NULL,
        create_time INTEGER NOT NULL,
        update_time INTEGER NOT NULL
      )
    ''');
    legacy.execute('''
      CREATE TABLE session_messages (
        origin_session_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        task_id TEXT NOT NULL,
        parent_task_id TEXT NULL,
        role TEXT NOT NULL,
        "to" TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        completions TEXT NULL,
        create_time INTEGER NOT NULL
      )
    ''');
    legacy.execute(
      '''
      INSERT INTO session_messages (
        origin_session_id, session_id, task_id, parent_task_id,
        role, "to", type, content, completions, create_time
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'legacy-session',
        'legacy-session',
        'legacy-task',
        null,
        SessionRoleType.AGENT,
        SessionRoleType.USER,
        SessionMessageType.TEXT,
        'legacy answer',
        'null',
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    legacy.execute('PRAGMA user_version = 1');
    legacy.dispose();

    final migratedDatabase = AgentDatabase(NativeDatabase(databaseFile));
    final migratedMessages = SessionMessageManageServiceByDB(migratedDatabase);
    final history = await migratedMessages.getMessagesBySession(
      'legacy-session',
    );

    expect(history, hasLength(1));
    expect(history.single.agentMessageDto.originalTaskId, 'legacy-task');
    expect(history.single.agentMessageDto.content, 'legacy answer');
    expect(migratedDatabase.schemaVersion, 2);
    final migratedSession = await migratedDatabase.getSessionById(
      'legacy-session',
    );
    expect(migratedSession, isNotNull);
    expect(migratedSession!.status, SessionPersistenceStatus.historyOnly);
    final migratedRuntime = SessionRuntimeService(
      agentService: AgentService(),
      sessionManageService: SessionManageServiceByDB(migratedDatabase),
      messageManageService: migratedMessages,
    );
    expect(await migratedRuntime.getHistory('legacy-session'), hasLength(1));
    await expectLater(
      migratedRuntime.resolveSession('legacy-session'),
      throwsA(isA<PersistedSessionExpiredException>()),
    );

    await migratedDatabase.close();
    await tempDirectory.delete(recursive: true);
    database = AgentDatabase(NativeDatabase.memory());
  });
}

Future<void> _persistTurn(
  SessionMessageManageServiceByDB service, {
  required String sessionId,
  required String taskId,
  required String userText,
  required String answerText,
  required bool done,
}) async {
  final now = DateTime.now();
  final messages = <AgentMessageDto>[
    if (taskId == 'done-task')
      AgentMessageDto(
        sessionId: sessionId,
        originalTaskId: taskId,
        taskId: taskId,
        role: SessionRoleType.SYSTEM,
        to: SessionRoleType.AGENT,
        type: SessionMessageType.TEXT,
        content: 'persistent system',
        createTime: now,
      ),
    AgentMessageDto(
      sessionId: sessionId,
      originalTaskId: taskId,
      taskId: taskId,
      role: SessionRoleType.USER,
      to: SessionRoleType.AGENT,
      type: SessionMessageType.CONTENT_LIST,
      content: [ContentDto(type: ContentType.TEXT, message: userText)],
      createTime: now,
    ),
    AgentMessageDto(
      sessionId: sessionId,
      originalTaskId: taskId,
      taskId: taskId,
      role: SessionRoleType.AGENT,
      to: AgentRoleType.LLM,
      type: SessionMessageType.CONTENT_LIST,
      content: [ContentDto(type: ContentType.TEXT, message: userText)],
      createTime: now,
    ),
    AgentMessageDto(
      sessionId: sessionId,
      originalTaskId: taskId,
      taskId: taskId,
      role: AgentRoleType.LLM,
      to: SessionRoleType.AGENT,
      type: SessionMessageType.TEXT,
      content: answerText,
      createTime: now,
    ),
    AgentMessageDto(
      sessionId: sessionId,
      originalTaskId: taskId,
      taskId: taskId,
      role: SessionRoleType.AGENT,
      to: SessionRoleType.USER,
      type: SessionMessageType.TEXT,
      content: answerText,
      createTime: now,
    ),
    if (done)
      AgentMessageDto(
        sessionId: sessionId,
        originalTaskId: taskId,
        taskId: taskId,
        role: SessionRoleType.AGENT,
        to: SessionRoleType.CLIENT,
        type: SessionMessageType.TASK_STATUS,
        content: TaskStatusDto(status: TaskStatusType.DONE, taskId: taskId),
        createTime: now,
      ),
  ];

  for (final message in messages) {
    await service.addMessage(
      SessionAgentMessageDto(sessionId: sessionId, agentMessageDto: message),
    );
  }
}
