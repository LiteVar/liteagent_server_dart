import 'package:drift/drift.dart';

part 'session_message_database.g.dart';

@DataClassName("SessionMessageDao")
class SessionMessages extends Table {
  TextColumn get originSessionId => text().withLength(min: 1, max: 64)();
  TextColumn get sessionId => text().withLength(min: 1, max: 64)();
  TextColumn get taskId => text().withLength(min: 1, max: 64)();
  TextColumn get role => text().withLength(min: 1, max: 16)();
  TextColumn get to => text().withLength(min: 1, max: 16)();
  TextColumn get type => text().withLength(min: 1, max: 16)();
  TextColumn get message => text().withLength(min: 1, max: 2048)();
  TextColumn get completions => text().withLength(min: 1, max: 2048).nullable()();
  DateTimeColumn get createTime => dateTime()();
}

@DriftDatabase(tables: [SessionMessages])
class SessionMessageDatabase extends _$SessionMessageDatabase {
  SessionMessageDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<int> addMessage(SessionMessageDao message) => into(sessionMessages).insert(message);

  Future<List<SessionMessageDao>> getAllMessages() => select(sessionMessages).get();

  Future<List<SessionMessageDao>> getMessagesPaginated(int page, int pageSize) {
    final query = select(sessionMessages)
      ..limit(pageSize, offset: (page - 1) * pageSize);
    return query.get();
  }
}