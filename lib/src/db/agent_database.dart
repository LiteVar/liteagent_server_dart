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
  TextColumn get rootSessionId => text().withLength(min: 1, max: 64)();
  TextColumn get inlinePath => text().nullable()();
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

class HistoryTurnRecord {
  final String originalTaskId;
  final DateTime createdAt;
  final int messageCount;

  const HistoryTurnRecord({
    required this.originalTaskId,
    required this.createdAt,
    required this.messageCount,
  });
}

@DriftDatabase(tables: [Agents, Sessions, SessionMessages])
class AgentDatabase extends _$AgentDatabase {
  AgentDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 5;

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
                root_session_id,
                inline_path,
                capability,
                status,
                topic,
                create_time,
                update_time,
                expires_at
              )
              SELECT
                origin_session_id,
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
      } else if (from < 4) {
        await customStatement(
          "ALTER TABLE sessions ADD COLUMN root_session_id TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          'ALTER TABLE sessions ADD COLUMN inline_path TEXT',
        );
        await customStatement(
          'UPDATE sessions SET root_session_id = session_id '
          "WHERE root_session_id = ''",
        );
      }
      if (from >= 2 && from < 5) {
        await customStatement('DROP INDEX IF EXISTS sessions_agent_id_idx');
        await customStatement('ALTER TABLE sessions DROP COLUMN agent_id');
      }
      if (from < 5) await _createIndexes();
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS sessions_root_idx '
      'ON sessions (root_session_id, inline_path, update_time)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS session_messages_origin_idx '
      'ON session_messages (origin_session_id, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS session_messages_task_idx '
      'ON session_messages (origin_session_id, original_task_id, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS session_messages_root_turn_idx '
      'ON session_messages (session_id, original_task_id, create_time, id)',
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

  Future<List<SessionDao>> getSessionsByRootSessionId(String rootSessionId) {
    final query = select(sessions)
      ..where((table) => table.rootSessionId.equals(rootSessionId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.inlinePath),
        (table) => OrderingTerm.asc(table.createTime),
      ]);
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

  Future<void> markInlineSessionTreeHistoryOnly(String rootSessionId) async {
    await transaction(() async {
      final rows = await getSessionsByRootSessionId(rootSessionId);
      for (final row in rows) {
        if (row.sessionId == rootSessionId) continue;
        await (update(sessions)
              ..where((table) => table.sessionId.equals(row.sessionId)))
            .write(const SessionsCompanion(status: Value('history_only')));
      }
    });
  }

  Future<void> deleteSessionTreeAndMessages(String rootSessionId) async {
    await transaction(() async {
      final rows = await getSessionsByRootSessionId(rootSessionId);
      final sessionIds = rows.map((row) => row.sessionId).toList();
      if (!sessionIds.contains(rootSessionId)) sessionIds.add(rootSessionId);
      await (delete(
        sessionMessages,
      )..where((table) => table.originSessionId.isIn(sessionIds))).go();
      await (delete(
        sessions,
      )..where((table) => table.sessionId.isIn(sessionIds))).go();
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
  }) => getMessagesBySessions([sessionId], page: page, pageSize: pageSize);

  Future<List<SessionMessageDao>> getMessagesBySessions(
    List<String> sessionIds, {
    int? page,
    int? pageSize,
  }) async {
    if (sessionIds.isEmpty) return const [];
    final query = select(sessionMessages)
      ..where((table) => table.originSessionId.isIn(sessionIds))
      ..orderBy([
        (table) => page != null && pageSize != null
            ? OrderingTerm.desc(table.id)
            : OrderingTerm.asc(table.id),
      ]);
    if (page != null && pageSize != null) {
      query.limit(pageSize, offset: (page - 1) * pageSize);
    }
    final rows = await query.get();
    return page != null && pageSize != null
        ? rows.reversed.toList(growable: false)
        : rows;
  }

  Future<List<HistoryTurnRecord>> getHistoryTurnPage(
    String rootSessionId,
    List<String> historySessionIds, {
    required int page,
    required int pageSize,
  }) async {
    if (historySessionIds.isEmpty) return const [];

    final rootTurns = selectOnly(sessionMessages)
      ..addColumns([
        sessionMessages.originalTaskId,
        sessionMessages.createTime.min(),
        sessionMessages.id.min(),
      ])
      ..where(
        sessionMessages.originSessionId.isIn(historySessionIds) &
            sessionMessages.sessionId.equals(rootSessionId),
      )
      ..groupBy([sessionMessages.originalTaskId])
      ..orderBy([
        OrderingTerm.desc(sessionMessages.createTime.min()),
        OrderingTerm.desc(sessionMessages.id.min()),
        OrderingTerm.desc(sessionMessages.originalTaskId),
      ])
      ..limit(pageSize, offset: (page - 1) * pageSize);
    final turnRows = await rootTurns.get();
    if (turnRows.isEmpty) return const [];

    final taskIds = turnRows
        .map((row) => row.read(sessionMessages.originalTaskId)!)
        .toList(growable: false);
    final counts = selectOnly(sessionMessages)
      ..addColumns([sessionMessages.originalTaskId, sessionMessages.id.count()])
      ..where(
        sessionMessages.originSessionId.isIn(historySessionIds) &
            sessionMessages.originalTaskId.isIn(taskIds),
      )
      ..groupBy([sessionMessages.originalTaskId]);
    final countRows = await counts.get();
    final countByTask = {
      for (final row in countRows)
        row.read(sessionMessages.originalTaskId)!: row.read(
          sessionMessages.id.count(),
        )!,
    };

    return turnRows
        .map(
          (row) => HistoryTurnRecord(
            originalTaskId: row.read(sessionMessages.originalTaskId)!,
            createdAt: row.read(sessionMessages.createTime.min())!,
            messageCount:
                countByTask[row.read(sessionMessages.originalTaskId)!] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<List<SessionMessageDao>> getHistorySummaryCandidates(
    String rootSessionId,
    List<String> historySessionIds,
    List<String> originalTaskIds,
  ) {
    if (historySessionIds.isEmpty || originalTaskIds.isEmpty) {
      return Future.value(const []);
    }
    final isSummaryText = sessionMessages.type.isIn(['text', 'contentList']);
    final query = select(sessionMessages)
      ..where(
        (table) =>
            table.originSessionId.isIn(historySessionIds) &
            table.sessionId.equals(rootSessionId) &
            table.originalTaskId.isIn(originalTaskIds) &
            ((table.role.equals('user') & isSummaryText) |
                (table.to.equals('user') & isSummaryText) |
                table.type.equals('taskStatus') |
                table.completions.isNotNull()),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.createTime),
        (table) => OrderingTerm.asc(table.id),
      ]);
    return query.get();
  }

  Future<bool> historyTaskBelongsToRoot(
    String rootSessionId,
    List<String> historySessionIds,
    String originalTaskId,
  ) async {
    if (historySessionIds.isEmpty) return false;
    final query = selectOnly(sessionMessages)
      ..addColumns([sessionMessages.id])
      ..where(
        sessionMessages.originSessionId.isIn(historySessionIds) &
            sessionMessages.sessionId.equals(rootSessionId) &
            sessionMessages.originalTaskId.equals(originalTaskId),
      )
      ..limit(1);
    return (await query.getSingleOrNull()) != null;
  }

  Future<List<SessionMessageDao>> getHistoryProcessMessages(
    List<String> historySessionIds,
    String originalTaskId, {
    required int page,
    required int pageSize,
    Set<int> excludedMessageIds = const {},
  }) async {
    if (historySessionIds.isEmpty) return const [];
    final query = select(sessionMessages)
      ..where((table) {
        var predicate =
            table.originSessionId.isIn(historySessionIds) &
            table.originalTaskId.equals(originalTaskId);
        if (excludedMessageIds.isNotEmpty) {
          predicate = predicate & table.id.isNotIn(excludedMessageIds);
        }
        return predicate;
      })
      ..orderBy([
        (table) => OrderingTerm.asc(table.createTime),
        (table) => OrderingTerm.asc(table.id),
      ])
      ..limit(pageSize, offset: (page - 1) * pageSize);
    return query.get();
  }
}
