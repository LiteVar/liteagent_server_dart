import 'package:drift/drift.dart';

part 'agent_database.g.dart';

@DataClassName("AgentDao")
class Agents extends Table {
  TextColumn get agentId => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  TextColumn get capability => text().withLength(min: 1, max: 2048)();
}

@DriftDatabase(tables: [Agents])
class AgentDatabase extends _$AgentDatabase {
  AgentDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<int> addAgent(AgentDao agent) => into(agents).insert(agent);

  Future<List<AgentDao>> getAllAgents() => select(agents).get();

  Future<AgentDao?> getAgentById(String agentId) => (select(agents)..where((t) => t.agentId.equals(agentId))).getSingle();

  Future<bool> updateAgent(AgentDao agent) => update(agents).replace(agent);

  Future<int> deleteAgent(AgentDao agent) => delete(agents).delete(agent);
}