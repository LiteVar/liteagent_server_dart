import 'package:drift/drift.dart';

part 'agent_database.g.dart';

@DataClassName('AgentDao')
class Agents extends Table {
  TextColumn get agentId => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  TextColumn get capability => text()();
  DateTimeColumn get createTime => dateTime()();
  DateTimeColumn get updateTime => dateTime()();

  @override
  Set<Column> get primaryKey => {agentId};
}

@DataClassName('SessionDao')
class Sessions extends Table {
  TextColumn get sessionId => text().withLength(min: 1, max: 64)();
  TextColumn get agentId => text().withLength(min: 1, max: 64).nullable()();
  TextColumn get capability => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get topic => text().nullable()();
  DateTimeColumn get createTime => dateTime()();
  DateTimeColumn get updateTime => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId};
}

@DataClassName('SessionMessageDao')
class SessionMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get originSessionId => text().withLength(min: 1, max: 64)();
  TextColumn get sessionId => text().withLength(min: 1, max: 64)();
  TextColumn get originalTaskId => text().withLength(min: 1, max: 64)();
  TextColumn get taskId => text().withLength(min: 1, max: 64)();
  TextColumn get parentTaskId =>
      text().withLength(min: 1, max: 64).nullable()();
  TextColumn get role => text().withLength(min: 1, max: 32)();
  TextColumn get to => text().withLength(min: 1, max: 32)();
  TextColumn get type => text().withLength(min: 1, max: 32)();
  TextColumn get payload => text()();
  TextColumn get reasoningContent => text().nullable()();
  TextColumn get completions => text().nullable()();
  DateTimeColumn get createTime => dateTime()();
}

@DriftDatabase(tables: [Agents, Sessions, SessionMessages])
class AgentDatabase extends _$AgentDatabase {
  AgentDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE session_messages RENAME TO session_messages_legacy',
        );
        await migrator.createTable(sessions);
        await migrator.createTable(sessionMessages);
        await customStatement('''
              INSERT INTO sessions (
                session_id,
                agent_id,
                capability,
                status,
                topic,
                create_time,
                update_time,
                expires_at
              )
              SELECT
                origin_session_id,
                NULL,
                '{"systemPrompt":""}',
                'history_only',
                NULL,
                MIN(create_time),
                MAX(create_time),
                NULL
              FROM session_messages_legacy
              GROUP BY origin_session_id
            ''');
        await customStatement('''
              INSERT INTO session_messages (
                origin_session_id,
                session_id,
                original_task_id,
                task_id,
                parent_task_id,
                role,
                "to",
                type,
                payload,
                reasoning_content,
                completions,
                create_time
              )
              SELECT
                origin_session_id,
                session_id,
                task_id,
                task_id,
                parent_task_id,
                role,
                "to",
                type,
                content,
                NULL,
                CASE WHEN completions = 'null' THEN NULL ELSE completions END,
                create_time
              FROM session_messages_legacy
            ''');
        await customStatement('DROP TABLE session_messages_legacy');
        await _createIndexes();
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS sessions_agent_id_idx '
      'ON sessions (agent_id, update_time)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS session_messages_origin_idx '
      'ON session_messages (origin_session_id, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS session_messages_task_idx '
      'ON session_messages (origin_session_id, original_task_id, id)',
    );
  }

  Future<int> addAgent(AgentDao agent) => into(agents).insert(agent);

  Future<List<AgentDao>> getAllAgents() => select(agents).get();

  Future<AgentDao?> getAgentById(String agentId) => (select(
    agents,
  )..where((table) => table.agentId.equals(agentId))).getSingleOrNull();

  Future<bool> updateAgent(AgentDao agent) => update(agents).replace(agent);

  Future<int> deleteAgent(AgentDao agent) => delete(agents).delete(agent);

  Future<void> addSession(SessionDao session) => into(sessions).insert(session);

  Future<SessionDao?> getSessionById(String sessionId) => (select(
    sessions,
  )..where((table) => table.sessionId.equals(sessionId))).getSingleOrNull();

  Future<List<SessionDao>> getSessionsByAgentId(String agentId) {
    final query = select(sessions)
      ..where((table) => table.agentId.equals(agentId))
      ..orderBy([(table) => OrderingTerm.desc(table.updateTime)]);
    return query.get();
  }

  Future<void> touchSession(String sessionId, DateTime updateTime) async {
    await (update(sessions)
          ..where((table) => table.sessionId.equals(sessionId)))
        .write(SessionsCompanion(updateTime: Value(updateTime)));
  }

  Future<void> deleteSessionAndMessages(String sessionId) async {
    await transaction(() async {
      await (delete(
        sessionMessages,
      )..where((table) => table.originSessionId.equals(sessionId))).go();
      await (delete(
        sessions,
      )..where((table) => table.sessionId.equals(sessionId))).go();
    });
  }

  Future<int> addMessage(
    SessionMessagesCompanion message, {
    String? topic,
  }) async {
    return transaction(() async {
      final id = await into(sessionMessages).insert(message);
      final originSessionId = message.originSessionId.value;
      final createTime = message.createTime.value;
      final existingSession = await getSessionById(originSessionId);
      if (existingSession != null) {
        final shouldSetTopic = existingSession.topic == null && topic != null;
        await (update(
          sessions,
        )..where((table) => table.sessionId.equals(originSessionId))).write(
          SessionsCompanion(
            topic: shouldSetTopic ? Value(topic) : const Value.absent(),
            updateTime: Value(createTime),
          ),
        );
      }
      return id;
    });
  }

  Future<List<SessionMessageDao>> getAllMessages() => (select(
    sessionMessages,
  )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();

  Future<List<SessionMessageDao>> getMessagesBySession(
    String sessionId, {
    int? page,
    int? pageSize,
  }) {
    final query = select(sessionMessages)
      ..where((table) => table.originSessionId.equals(sessionId))
      ..orderBy([(table) => OrderingTerm.asc(table.id)]);
    if (page != null && pageSize != null) {
      query.limit(pageSize, offset: (page - 1) * pageSize);
    }
    return query.get();
  }
}
