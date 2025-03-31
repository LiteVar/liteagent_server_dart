import 'package:drift/drift.dart';
part 'agent_database.g.dart';

@DataClassName("AgentDao")
class Agents extends Table {
  TextColumn get agentId => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  TextColumn get capability => text().withLength(min: 1, max: 65536)();
}

@DataClassName("SessionMessageDao")
class SessionMessages extends Table {
  TextColumn get originSessionId => text().withLength(min: 1, max: 64)();
  TextColumn get sessionId => text().withLength(min: 1, max: 64)();
  TextColumn get taskId => text().withLength(min: 1, max: 64)();
  TextColumn get role => text().withLength(min: 1, max: 16)();
  TextColumn get to => text().withLength(min: 1, max: 16)();
  TextColumn get type => text().withLength(min: 1, max: 16)();
  TextColumn get content => text().withLength(min: 1, max: 2048)();
  TextColumn get completions => text().withLength(min: 1, max: 2048).nullable()();
  DateTimeColumn get createTime => dateTime()();
}

@DriftDatabase(tables: [Agents, SessionMessages])
class AgentDatabase extends _$AgentDatabase {
  AgentDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<int> addAgent(AgentDao agent) => into(agents).insert(agent);

  Future<List<AgentDao>> getAllAgents() => select(agents).get();

  Future<AgentDao?> getAgentById(String agentId) => (select(agents)..where((t) => t.agentId.equals(agentId))).getSingle();

  Future<bool> updateAgent(AgentDao agent) => update(agents).replace(agent);

  Future<int> deleteAgent(AgentDao agent) => delete(agents).delete(agent);

  Future<int> addMessage(SessionMessageDao message) => into(sessionMessages).insert(message);

  Future<List<SessionMessageDao>> getAllMessages() => select(sessionMessages).get();

  Future<List<SessionMessageDao>> getMessagesPaginated(int page, int pageSize) {
    final query = select(sessionMessages)
      ..limit(pageSize, offset: (page - 1) * pageSize);
    return query.get();
  }
}