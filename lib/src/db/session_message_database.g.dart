// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_message_database.dart';

// ignore_for_file: type=lint
class $SessionMessagesTable extends SessionMessages
    with TableInfo<$SessionMessagesTable, SessionMessageDao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _originSessionIdMeta =
      const VerificationMeta('originSessionId');
  @override
  late final GeneratedColumn<String> originSessionId = GeneratedColumn<String>(
      'origin_session_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _toMeta = const VerificationMeta('to');
  @override
  late final GeneratedColumn<String> to = GeneratedColumn<String>(
      'to', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 16),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1, maxTextLength: 2048),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _completionsMeta =
      const VerificationMeta('completions');
  @override
  late final GeneratedColumn<String> completions = GeneratedColumn<String>(
      'completions', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1, maxTextLength: 2048),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _createTimeMeta =
      const VerificationMeta('createTime');
  @override
  late final GeneratedColumn<DateTime> createTime = GeneratedColumn<DateTime>(
      'create_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        originSessionId,
        sessionId,
        taskId,
        role,
        to,
        type,
        message,
        completions,
        createTime
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_messages';
  @override
  VerificationContext validateIntegrity(Insertable<SessionMessageDao> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('origin_session_id')) {
      context.handle(
          _originSessionIdMeta,
          originSessionId.isAcceptableOrUnknown(
              data['origin_session_id']!, _originSessionIdMeta));
    } else if (isInserting) {
      context.missing(_originSessionIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('to')) {
      context.handle(_toMeta, to.isAcceptableOrUnknown(data['to']!, _toMeta));
    } else if (isInserting) {
      context.missing(_toMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('completions')) {
      context.handle(
          _completionsMeta,
          completions.isAcceptableOrUnknown(
              data['completions']!, _completionsMeta));
    }
    if (data.containsKey('create_time')) {
      context.handle(
          _createTimeMeta,
          createTime.isAcceptableOrUnknown(
              data['create_time']!, _createTimeMeta));
    } else if (isInserting) {
      context.missing(_createTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SessionMessageDao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionMessageDao(
      originSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_session_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      to: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      completions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}completions']),
      createTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}create_time'])!,
    );
  }

  @override
  $SessionMessagesTable createAlias(String alias) {
    return $SessionMessagesTable(attachedDatabase, alias);
  }
}

class SessionMessageDao extends DataClass
    implements Insertable<SessionMessageDao> {
  final String originSessionId;
  final String sessionId;
  final String taskId;
  final String role;
  final String to;
  final String type;
  final String message;
  final String? completions;
  final DateTime createTime;
  const SessionMessageDao(
      {required this.originSessionId,
      required this.sessionId,
      required this.taskId,
      required this.role,
      required this.to,
      required this.type,
      required this.message,
      this.completions,
      required this.createTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['origin_session_id'] = Variable<String>(originSessionId);
    map['session_id'] = Variable<String>(sessionId);
    map['task_id'] = Variable<String>(taskId);
    map['role'] = Variable<String>(role);
    map['to'] = Variable<String>(to);
    map['type'] = Variable<String>(type);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || completions != null) {
      map['completions'] = Variable<String>(completions);
    }
    map['create_time'] = Variable<DateTime>(createTime);
    return map;
  }

  SessionMessagesCompanion toCompanion(bool nullToAbsent) {
    return SessionMessagesCompanion(
      originSessionId: Value(originSessionId),
      sessionId: Value(sessionId),
      taskId: Value(taskId),
      role: Value(role),
      to: Value(to),
      type: Value(type),
      message: Value(message),
      completions: completions == null && nullToAbsent
          ? const Value.absent()
          : Value(completions),
      createTime: Value(createTime),
    );
  }

  factory SessionMessageDao.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionMessageDao(
      originSessionId: serializer.fromJson<String>(json['originSessionId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      role: serializer.fromJson<String>(json['role']),
      to: serializer.fromJson<String>(json['to']),
      type: serializer.fromJson<String>(json['type']),
      message: serializer.fromJson<String>(json['message']),
      completions: serializer.fromJson<String?>(json['completions']),
      createTime: serializer.fromJson<DateTime>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'originSessionId': serializer.toJson<String>(originSessionId),
      'sessionId': serializer.toJson<String>(sessionId),
      'taskId': serializer.toJson<String>(taskId),
      'role': serializer.toJson<String>(role),
      'to': serializer.toJson<String>(to),
      'type': serializer.toJson<String>(type),
      'message': serializer.toJson<String>(message),
      'completions': serializer.toJson<String?>(completions),
      'createTime': serializer.toJson<DateTime>(createTime),
    };
  }

  SessionMessageDao copyWith(
          {String? originSessionId,
          String? sessionId,
          String? taskId,
          String? role,
          String? to,
          String? type,
          String? message,
          Value<String?> completions = const Value.absent(),
          DateTime? createTime}) =>
      SessionMessageDao(
        originSessionId: originSessionId ?? this.originSessionId,
        sessionId: sessionId ?? this.sessionId,
        taskId: taskId ?? this.taskId,
        role: role ?? this.role,
        to: to ?? this.to,
        type: type ?? this.type,
        message: message ?? this.message,
        completions: completions.present ? completions.value : this.completions,
        createTime: createTime ?? this.createTime,
      );
  SessionMessageDao copyWithCompanion(SessionMessagesCompanion data) {
    return SessionMessageDao(
      originSessionId: data.originSessionId.present
          ? data.originSessionId.value
          : this.originSessionId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      role: data.role.present ? data.role.value : this.role,
      to: data.to.present ? data.to.value : this.to,
      type: data.type.present ? data.type.value : this.type,
      message: data.message.present ? data.message.value : this.message,
      completions:
          data.completions.present ? data.completions.value : this.completions,
      createTime:
          data.createTime.present ? data.createTime.value : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionMessageDao(')
          ..write('originSessionId: $originSessionId, ')
          ..write('sessionId: $sessionId, ')
          ..write('taskId: $taskId, ')
          ..write('role: $role, ')
          ..write('to: $to, ')
          ..write('type: $type, ')
          ..write('message: $message, ')
          ..write('completions: $completions, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(originSessionId, sessionId, taskId, role, to,
      type, message, completions, createTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionMessageDao &&
          other.originSessionId == this.originSessionId &&
          other.sessionId == this.sessionId &&
          other.taskId == this.taskId &&
          other.role == this.role &&
          other.to == this.to &&
          other.type == this.type &&
          other.message == this.message &&
          other.completions == this.completions &&
          other.createTime == this.createTime);
}

class SessionMessagesCompanion extends UpdateCompanion<SessionMessageDao> {
  final Value<String> originSessionId;
  final Value<String> sessionId;
  final Value<String> taskId;
  final Value<String> role;
  final Value<String> to;
  final Value<String> type;
  final Value<String> message;
  final Value<String?> completions;
  final Value<DateTime> createTime;
  final Value<int> rowid;
  const SessionMessagesCompanion({
    this.originSessionId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.role = const Value.absent(),
    this.to = const Value.absent(),
    this.type = const Value.absent(),
    this.message = const Value.absent(),
    this.completions = const Value.absent(),
    this.createTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionMessagesCompanion.insert({
    required String originSessionId,
    required String sessionId,
    required String taskId,
    required String role,
    required String to,
    required String type,
    required String message,
    this.completions = const Value.absent(),
    required DateTime createTime,
    this.rowid = const Value.absent(),
  })  : originSessionId = Value(originSessionId),
        sessionId = Value(sessionId),
        taskId = Value(taskId),
        role = Value(role),
        to = Value(to),
        type = Value(type),
        message = Value(message),
        createTime = Value(createTime);
  static Insertable<SessionMessageDao> custom({
    Expression<String>? originSessionId,
    Expression<String>? sessionId,
    Expression<String>? taskId,
    Expression<String>? role,
    Expression<String>? to,
    Expression<String>? type,
    Expression<String>? message,
    Expression<String>? completions,
    Expression<DateTime>? createTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (originSessionId != null) 'origin_session_id': originSessionId,
      if (sessionId != null) 'session_id': sessionId,
      if (taskId != null) 'task_id': taskId,
      if (role != null) 'role': role,
      if (to != null) 'to': to,
      if (type != null) 'type': type,
      if (message != null) 'message': message,
      if (completions != null) 'completions': completions,
      if (createTime != null) 'create_time': createTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionMessagesCompanion copyWith(
      {Value<String>? originSessionId,
      Value<String>? sessionId,
      Value<String>? taskId,
      Value<String>? role,
      Value<String>? to,
      Value<String>? type,
      Value<String>? message,
      Value<String?>? completions,
      Value<DateTime>? createTime,
      Value<int>? rowid}) {
    return SessionMessagesCompanion(
      originSessionId: originSessionId ?? this.originSessionId,
      sessionId: sessionId ?? this.sessionId,
      taskId: taskId ?? this.taskId,
      role: role ?? this.role,
      to: to ?? this.to,
      type: type ?? this.type,
      message: message ?? this.message,
      completions: completions ?? this.completions,
      createTime: createTime ?? this.createTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (originSessionId.present) {
      map['origin_session_id'] = Variable<String>(originSessionId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (to.present) {
      map['to'] = Variable<String>(to.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (completions.present) {
      map['completions'] = Variable<String>(completions.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<DateTime>(createTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionMessagesCompanion(')
          ..write('originSessionId: $originSessionId, ')
          ..write('sessionId: $sessionId, ')
          ..write('taskId: $taskId, ')
          ..write('role: $role, ')
          ..write('to: $to, ')
          ..write('type: $type, ')
          ..write('message: $message, ')
          ..write('completions: $completions, ')
          ..write('createTime: $createTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SessionMessageDatabase extends GeneratedDatabase {
  _$SessionMessageDatabase(QueryExecutor e) : super(e);
  $SessionMessageDatabaseManager get managers =>
      $SessionMessageDatabaseManager(this);
  late final $SessionMessagesTable sessionMessages =
      $SessionMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessionMessages];
}

typedef $$SessionMessagesTableCreateCompanionBuilder = SessionMessagesCompanion
    Function({
  required String originSessionId,
  required String sessionId,
  required String taskId,
  required String role,
  required String to,
  required String type,
  required String message,
  Value<String?> completions,
  required DateTime createTime,
  Value<int> rowid,
});
typedef $$SessionMessagesTableUpdateCompanionBuilder = SessionMessagesCompanion
    Function({
  Value<String> originSessionId,
  Value<String> sessionId,
  Value<String> taskId,
  Value<String> role,
  Value<String> to,
  Value<String> type,
  Value<String> message,
  Value<String?> completions,
  Value<DateTime> createTime,
  Value<int> rowid,
});

class $$SessionMessagesTableFilterComposer
    extends Composer<_$SessionMessageDatabase, $SessionMessagesTable> {
  $$SessionMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get originSessionId => $composableBuilder(
      column: $table.originSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get to => $composableBuilder(
      column: $table.to, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completions => $composableBuilder(
      column: $table.completions, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createTime => $composableBuilder(
      column: $table.createTime, builder: (column) => ColumnFilters(column));
}

class $$SessionMessagesTableOrderingComposer
    extends Composer<_$SessionMessageDatabase, $SessionMessagesTable> {
  $$SessionMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get originSessionId => $composableBuilder(
      column: $table.originSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get to => $composableBuilder(
      column: $table.to, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completions => $composableBuilder(
      column: $table.completions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createTime => $composableBuilder(
      column: $table.createTime, builder: (column) => ColumnOrderings(column));
}

class $$SessionMessagesTableAnnotationComposer
    extends Composer<_$SessionMessageDatabase, $SessionMessagesTable> {
  $$SessionMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get originSessionId => $composableBuilder(
      column: $table.originSessionId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get to =>
      $composableBuilder(column: $table.to, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get completions => $composableBuilder(
      column: $table.completions, builder: (column) => column);

  GeneratedColumn<DateTime> get createTime => $composableBuilder(
      column: $table.createTime, builder: (column) => column);
}

class $$SessionMessagesTableTableManager extends RootTableManager<
    _$SessionMessageDatabase,
    $SessionMessagesTable,
    SessionMessageDao,
    $$SessionMessagesTableFilterComposer,
    $$SessionMessagesTableOrderingComposer,
    $$SessionMessagesTableAnnotationComposer,
    $$SessionMessagesTableCreateCompanionBuilder,
    $$SessionMessagesTableUpdateCompanionBuilder,
    (
      SessionMessageDao,
      BaseReferences<_$SessionMessageDatabase, $SessionMessagesTable,
          SessionMessageDao>
    ),
    SessionMessageDao,
    PrefetchHooks Function()> {
  $$SessionMessagesTableTableManager(
      _$SessionMessageDatabase db, $SessionMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> originSessionId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> to = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String?> completions = const Value.absent(),
            Value<DateTime> createTime = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionMessagesCompanion(
            originSessionId: originSessionId,
            sessionId: sessionId,
            taskId: taskId,
            role: role,
            to: to,
            type: type,
            message: message,
            completions: completions,
            createTime: createTime,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String originSessionId,
            required String sessionId,
            required String taskId,
            required String role,
            required String to,
            required String type,
            required String message,
            Value<String?> completions = const Value.absent(),
            required DateTime createTime,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionMessagesCompanion.insert(
            originSessionId: originSessionId,
            sessionId: sessionId,
            taskId: taskId,
            role: role,
            to: to,
            type: type,
            message: message,
            completions: completions,
            createTime: createTime,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionMessagesTableProcessedTableManager = ProcessedTableManager<
    _$SessionMessageDatabase,
    $SessionMessagesTable,
    SessionMessageDao,
    $$SessionMessagesTableFilterComposer,
    $$SessionMessagesTableOrderingComposer,
    $$SessionMessagesTableAnnotationComposer,
    $$SessionMessagesTableCreateCompanionBuilder,
    $$SessionMessagesTableUpdateCompanionBuilder,
    (
      SessionMessageDao,
      BaseReferences<_$SessionMessageDatabase, $SessionMessagesTable,
          SessionMessageDao>
    ),
    SessionMessageDao,
    PrefetchHooks Function()>;

class $SessionMessageDatabaseManager {
  final _$SessionMessageDatabase _db;
  $SessionMessageDatabaseManager(this._db);
  $$SessionMessagesTableTableManager get sessionMessages =>
      $$SessionMessagesTableTableManager(_db, _db.sessionMessages);
}
