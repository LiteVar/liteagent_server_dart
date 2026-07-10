// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_database.dart';

// ignore_for_file: type=lint
class $AgentsTable extends Agents with TableInfo<$AgentsTable, AgentDao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capabilityMeta = const VerificationMeta(
    'capability',
  );
  @override
  late final GeneratedColumn<String> capability = GeneratedColumn<String>(
    'capability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<DateTime> createTime = GeneratedColumn<DateTime>(
    'create_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updateTimeMeta = const VerificationMeta(
    'updateTime',
  );
  @override
  late final GeneratedColumn<DateTime> updateTime = GeneratedColumn<DateTime>(
    'update_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    agentId,
    name,
    capability,
    createTime,
    updateTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agents';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentDao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('capability')) {
      context.handle(
        _capabilityMeta,
        capability.isAcceptableOrUnknown(data['capability']!, _capabilityMeta),
      );
    } else if (isInserting) {
      context.missing(_capabilityMeta);
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_createTimeMeta);
    }
    if (data.containsKey('update_time')) {
      context.handle(
        _updateTimeMeta,
        updateTime.isAcceptableOrUnknown(data['update_time']!, _updateTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_updateTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {agentId};
  @override
  AgentDao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentDao(
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      capability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capability'],
      )!,
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}create_time'],
      )!,
      updateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}update_time'],
      )!,
    );
  }

  @override
  $AgentsTable createAlias(String alias) {
    return $AgentsTable(attachedDatabase, alias);
  }
}

class AgentDao extends DataClass implements Insertable<AgentDao> {
  final String agentId;
  final String name;
  final String capability;
  final DateTime createTime;
  final DateTime updateTime;
  const AgentDao({
    required this.agentId,
    required this.name,
    required this.capability,
    required this.createTime,
    required this.updateTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['agent_id'] = Variable<String>(agentId);
    map['name'] = Variable<String>(name);
    map['capability'] = Variable<String>(capability);
    map['create_time'] = Variable<DateTime>(createTime);
    map['update_time'] = Variable<DateTime>(updateTime);
    return map;
  }

  AgentsCompanion toCompanion(bool nullToAbsent) {
    return AgentsCompanion(
      agentId: Value(agentId),
      name: Value(name),
      capability: Value(capability),
      createTime: Value(createTime),
      updateTime: Value(updateTime),
    );
  }

  factory AgentDao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentDao(
      agentId: serializer.fromJson<String>(json['agentId']),
      name: serializer.fromJson<String>(json['name']),
      capability: serializer.fromJson<String>(json['capability']),
      createTime: serializer.fromJson<DateTime>(json['createTime']),
      updateTime: serializer.fromJson<DateTime>(json['updateTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'agentId': serializer.toJson<String>(agentId),
      'name': serializer.toJson<String>(name),
      'capability': serializer.toJson<String>(capability),
      'createTime': serializer.toJson<DateTime>(createTime),
      'updateTime': serializer.toJson<DateTime>(updateTime),
    };
  }

  AgentDao copyWith({
    String? agentId,
    String? name,
    String? capability,
    DateTime? createTime,
    DateTime? updateTime,
  }) => AgentDao(
    agentId: agentId ?? this.agentId,
    name: name ?? this.name,
    capability: capability ?? this.capability,
    createTime: createTime ?? this.createTime,
    updateTime: updateTime ?? this.updateTime,
  );
  AgentDao copyWithCompanion(AgentsCompanion data) {
    return AgentDao(
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      name: data.name.present ? data.name.value : this.name,
      capability: data.capability.present
          ? data.capability.value
          : this.capability,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      updateTime: data.updateTime.present
          ? data.updateTime.value
          : this.updateTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentDao(')
          ..write('agentId: $agentId, ')
          ..write('name: $name, ')
          ..write('capability: $capability, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(agentId, name, capability, createTime, updateTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentDao &&
          other.agentId == this.agentId &&
          other.name == this.name &&
          other.capability == this.capability &&
          other.createTime == this.createTime &&
          other.updateTime == this.updateTime);
}

class AgentsCompanion extends UpdateCompanion<AgentDao> {
  final Value<String> agentId;
  final Value<String> name;
  final Value<String> capability;
  final Value<DateTime> createTime;
  final Value<DateTime> updateTime;
  final Value<int> rowid;
  const AgentsCompanion({
    this.agentId = const Value.absent(),
    this.name = const Value.absent(),
    this.capability = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentsCompanion.insert({
    required String agentId,
    required String name,
    required String capability,
    required DateTime createTime,
    required DateTime updateTime,
    this.rowid = const Value.absent(),
  }) : agentId = Value(agentId),
       name = Value(name),
       capability = Value(capability),
       createTime = Value(createTime),
       updateTime = Value(updateTime);
  static Insertable<AgentDao> custom({
    Expression<String>? agentId,
    Expression<String>? name,
    Expression<String>? capability,
    Expression<DateTime>? createTime,
    Expression<DateTime>? updateTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (agentId != null) 'agent_id': agentId,
      if (name != null) 'name': name,
      if (capability != null) 'capability': capability,
      if (createTime != null) 'create_time': createTime,
      if (updateTime != null) 'update_time': updateTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentsCompanion copyWith({
    Value<String>? agentId,
    Value<String>? name,
    Value<String>? capability,
    Value<DateTime>? createTime,
    Value<DateTime>? updateTime,
    Value<int>? rowid,
  }) {
    return AgentsCompanion(
      agentId: agentId ?? this.agentId,
      name: name ?? this.name,
      capability: capability ?? this.capability,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (capability.present) {
      map['capability'] = Variable<String>(capability.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<DateTime>(createTime.value);
    }
    if (updateTime.present) {
      map['update_time'] = Variable<DateTime>(updateTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentsCompanion(')
          ..write('agentId: $agentId, ')
          ..write('name: $name, ')
          ..write('capability: $capability, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionDao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capabilityMeta = const VerificationMeta(
    'capability',
  );
  @override
  late final GeneratedColumn<String> capability = GeneratedColumn<String>(
    'capability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<DateTime> createTime = GeneratedColumn<DateTime>(
    'create_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updateTimeMeta = const VerificationMeta(
    'updateTime',
  );
  @override
  late final GeneratedColumn<DateTime> updateTime = GeneratedColumn<DateTime>(
    'update_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    agentId,
    capability,
    status,
    topic,
    createTime,
    updateTime,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionDao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    }
    if (data.containsKey('capability')) {
      context.handle(
        _capabilityMeta,
        capability.isAcceptableOrUnknown(data['capability']!, _capabilityMeta),
      );
    } else if (isInserting) {
      context.missing(_capabilityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_createTimeMeta);
    }
    if (data.containsKey('update_time')) {
      context.handle(
        _updateTimeMeta,
        updateTime.isAcceptableOrUnknown(data['update_time']!, _updateTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_updateTimeMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SessionDao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionDao(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      ),
      capability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capability'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}create_time'],
      )!,
      updateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}update_time'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionDao extends DataClass implements Insertable<SessionDao> {
  final String sessionId;
  final String? agentId;
  final String capability;
  final String status;
  final String? topic;
  final DateTime createTime;
  final DateTime updateTime;
  final DateTime? expiresAt;
  const SessionDao({
    required this.sessionId,
    this.agentId,
    required this.capability,
    required this.status,
    this.topic,
    required this.createTime,
    required this.updateTime,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    map['capability'] = Variable<String>(capability);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    map['create_time'] = Variable<DateTime>(createTime);
    map['update_time'] = Variable<DateTime>(updateTime);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      sessionId: Value(sessionId),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      capability: Value(capability),
      status: Value(status),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      createTime: Value(createTime),
      updateTime: Value(updateTime),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory SessionDao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionDao(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      capability: serializer.fromJson<String>(json['capability']),
      status: serializer.fromJson<String>(json['status']),
      topic: serializer.fromJson<String?>(json['topic']),
      createTime: serializer.fromJson<DateTime>(json['createTime']),
      updateTime: serializer.fromJson<DateTime>(json['updateTime']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'agentId': serializer.toJson<String?>(agentId),
      'capability': serializer.toJson<String>(capability),
      'status': serializer.toJson<String>(status),
      'topic': serializer.toJson<String?>(topic),
      'createTime': serializer.toJson<DateTime>(createTime),
      'updateTime': serializer.toJson<DateTime>(updateTime),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  SessionDao copyWith({
    String? sessionId,
    Value<String?> agentId = const Value.absent(),
    String? capability,
    String? status,
    Value<String?> topic = const Value.absent(),
    DateTime? createTime,
    DateTime? updateTime,
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => SessionDao(
    sessionId: sessionId ?? this.sessionId,
    agentId: agentId.present ? agentId.value : this.agentId,
    capability: capability ?? this.capability,
    status: status ?? this.status,
    topic: topic.present ? topic.value : this.topic,
    createTime: createTime ?? this.createTime,
    updateTime: updateTime ?? this.updateTime,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  SessionDao copyWithCompanion(SessionsCompanion data) {
    return SessionDao(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      capability: data.capability.present
          ? data.capability.value
          : this.capability,
      status: data.status.present ? data.status.value : this.status,
      topic: data.topic.present ? data.topic.value : this.topic,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      updateTime: data.updateTime.present
          ? data.updateTime.value
          : this.updateTime,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionDao(')
          ..write('sessionId: $sessionId, ')
          ..write('agentId: $agentId, ')
          ..write('capability: $capability, ')
          ..write('status: $status, ')
          ..write('topic: $topic, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    agentId,
    capability,
    status,
    topic,
    createTime,
    updateTime,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionDao &&
          other.sessionId == this.sessionId &&
          other.agentId == this.agentId &&
          other.capability == this.capability &&
          other.status == this.status &&
          other.topic == this.topic &&
          other.createTime == this.createTime &&
          other.updateTime == this.updateTime &&
          other.expiresAt == this.expiresAt);
}

class SessionsCompanion extends UpdateCompanion<SessionDao> {
  final Value<String> sessionId;
  final Value<String?> agentId;
  final Value<String> capability;
  final Value<String> status;
  final Value<String?> topic;
  final Value<DateTime> createTime;
  final Value<DateTime> updateTime;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.sessionId = const Value.absent(),
    this.agentId = const Value.absent(),
    this.capability = const Value.absent(),
    this.status = const Value.absent(),
    this.topic = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String sessionId,
    this.agentId = const Value.absent(),
    required String capability,
    this.status = const Value.absent(),
    this.topic = const Value.absent(),
    required DateTime createTime,
    required DateTime updateTime,
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       capability = Value(capability),
       createTime = Value(createTime),
       updateTime = Value(updateTime);
  static Insertable<SessionDao> custom({
    Expression<String>? sessionId,
    Expression<String>? agentId,
    Expression<String>? capability,
    Expression<String>? status,
    Expression<String>? topic,
    Expression<DateTime>? createTime,
    Expression<DateTime>? updateTime,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (agentId != null) 'agent_id': agentId,
      if (capability != null) 'capability': capability,
      if (status != null) 'status': status,
      if (topic != null) 'topic': topic,
      if (createTime != null) 'create_time': createTime,
      if (updateTime != null) 'update_time': updateTime,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String?>? agentId,
    Value<String>? capability,
    Value<String>? status,
    Value<String?>? topic,
    Value<DateTime>? createTime,
    Value<DateTime>? updateTime,
    Value<DateTime?>? expiresAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      agentId: agentId ?? this.agentId,
      capability: capability ?? this.capability,
      status: status ?? this.status,
      topic: topic ?? this.topic,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (capability.present) {
      map['capability'] = Variable<String>(capability.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<DateTime>(createTime.value);
    }
    if (updateTime.present) {
      map['update_time'] = Variable<DateTime>(updateTime.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('agentId: $agentId, ')
          ..write('capability: $capability, ')
          ..write('status: $status, ')
          ..write('topic: $topic, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionMessagesTable extends SessionMessages
    with TableInfo<$SessionMessagesTable, SessionMessageDao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _originSessionIdMeta = const VerificationMeta(
    'originSessionId',
  );
  @override
  late final GeneratedColumn<String> originSessionId = GeneratedColumn<String>(
    'origin_session_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTaskIdMeta = const VerificationMeta(
    'originalTaskId',
  );
  @override
  late final GeneratedColumn<String> originalTaskId = GeneratedColumn<String>(
    'original_task_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toMeta = const VerificationMeta('to');
  @override
  late final GeneratedColumn<String> to = GeneratedColumn<String>(
    'to',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningContentMeta = const VerificationMeta(
    'reasoningContent',
  );
  @override
  late final GeneratedColumn<String> reasoningContent = GeneratedColumn<String>(
    'reasoning_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionsMeta = const VerificationMeta(
    'completions',
  );
  @override
  late final GeneratedColumn<String> completions = GeneratedColumn<String>(
    'completions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<DateTime> createTime = GeneratedColumn<DateTime>(
    'create_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originSessionId,
    sessionId,
    originalTaskId,
    taskId,
    parentTaskId,
    role,
    to,
    type,
    payload,
    reasoningContent,
    completions,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionMessageDao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('origin_session_id')) {
      context.handle(
        _originSessionIdMeta,
        originSessionId.isAcceptableOrUnknown(
          data['origin_session_id']!,
          _originSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originSessionIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('original_task_id')) {
      context.handle(
        _originalTaskIdMeta,
        originalTaskId.isAcceptableOrUnknown(
          data['original_task_id']!,
          _originalTaskIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalTaskIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
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
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('reasoning_content')) {
      context.handle(
        _reasoningContentMeta,
        reasoningContent.isAcceptableOrUnknown(
          data['reasoning_content']!,
          _reasoningContentMeta,
        ),
      );
    }
    if (data.containsKey('completions')) {
      context.handle(
        _completionsMeta,
        completions.isAcceptableOrUnknown(
          data['completions']!,
          _completionsMeta,
        ),
      );
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_createTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionMessageDao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionMessageDao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_session_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      originalTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_task_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      to: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      reasoningContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning_content'],
      ),
      completions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completions'],
      ),
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}create_time'],
      )!,
    );
  }

  @override
  $SessionMessagesTable createAlias(String alias) {
    return $SessionMessagesTable(attachedDatabase, alias);
  }
}

class SessionMessageDao extends DataClass
    implements Insertable<SessionMessageDao> {
  final int id;
  final String originSessionId;
  final String sessionId;
  final String originalTaskId;
  final String taskId;
  final String? parentTaskId;
  final String role;
  final String to;
  final String type;
  final String payload;
  final String? reasoningContent;
  final String? completions;
  final DateTime createTime;
  const SessionMessageDao({
    required this.id,
    required this.originSessionId,
    required this.sessionId,
    required this.originalTaskId,
    required this.taskId,
    this.parentTaskId,
    required this.role,
    required this.to,
    required this.type,
    required this.payload,
    this.reasoningContent,
    this.completions,
    required this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['origin_session_id'] = Variable<String>(originSessionId);
    map['session_id'] = Variable<String>(sessionId);
    map['original_task_id'] = Variable<String>(originalTaskId);
    map['task_id'] = Variable<String>(taskId);
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    map['role'] = Variable<String>(role);
    map['to'] = Variable<String>(to);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || reasoningContent != null) {
      map['reasoning_content'] = Variable<String>(reasoningContent);
    }
    if (!nullToAbsent || completions != null) {
      map['completions'] = Variable<String>(completions);
    }
    map['create_time'] = Variable<DateTime>(createTime);
    return map;
  }

  SessionMessagesCompanion toCompanion(bool nullToAbsent) {
    return SessionMessagesCompanion(
      id: Value(id),
      originSessionId: Value(originSessionId),
      sessionId: Value(sessionId),
      originalTaskId: Value(originalTaskId),
      taskId: Value(taskId),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      role: Value(role),
      to: Value(to),
      type: Value(type),
      payload: Value(payload),
      reasoningContent: reasoningContent == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoningContent),
      completions: completions == null && nullToAbsent
          ? const Value.absent()
          : Value(completions),
      createTime: Value(createTime),
    );
  }

  factory SessionMessageDao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionMessageDao(
      id: serializer.fromJson<int>(json['id']),
      originSessionId: serializer.fromJson<String>(json['originSessionId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      originalTaskId: serializer.fromJson<String>(json['originalTaskId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      role: serializer.fromJson<String>(json['role']),
      to: serializer.fromJson<String>(json['to']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      reasoningContent: serializer.fromJson<String?>(json['reasoningContent']),
      completions: serializer.fromJson<String?>(json['completions']),
      createTime: serializer.fromJson<DateTime>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originSessionId': serializer.toJson<String>(originSessionId),
      'sessionId': serializer.toJson<String>(sessionId),
      'originalTaskId': serializer.toJson<String>(originalTaskId),
      'taskId': serializer.toJson<String>(taskId),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'role': serializer.toJson<String>(role),
      'to': serializer.toJson<String>(to),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'reasoningContent': serializer.toJson<String?>(reasoningContent),
      'completions': serializer.toJson<String?>(completions),
      'createTime': serializer.toJson<DateTime>(createTime),
    };
  }

  SessionMessageDao copyWith({
    int? id,
    String? originSessionId,
    String? sessionId,
    String? originalTaskId,
    String? taskId,
    Value<String?> parentTaskId = const Value.absent(),
    String? role,
    String? to,
    String? type,
    String? payload,
    Value<String?> reasoningContent = const Value.absent(),
    Value<String?> completions = const Value.absent(),
    DateTime? createTime,
  }) => SessionMessageDao(
    id: id ?? this.id,
    originSessionId: originSessionId ?? this.originSessionId,
    sessionId: sessionId ?? this.sessionId,
    originalTaskId: originalTaskId ?? this.originalTaskId,
    taskId: taskId ?? this.taskId,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    role: role ?? this.role,
    to: to ?? this.to,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    reasoningContent: reasoningContent.present
        ? reasoningContent.value
        : this.reasoningContent,
    completions: completions.present ? completions.value : this.completions,
    createTime: createTime ?? this.createTime,
  );
  SessionMessageDao copyWithCompanion(SessionMessagesCompanion data) {
    return SessionMessageDao(
      id: data.id.present ? data.id.value : this.id,
      originSessionId: data.originSessionId.present
          ? data.originSessionId.value
          : this.originSessionId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      originalTaskId: data.originalTaskId.present
          ? data.originalTaskId.value
          : this.originalTaskId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      role: data.role.present ? data.role.value : this.role,
      to: data.to.present ? data.to.value : this.to,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      reasoningContent: data.reasoningContent.present
          ? data.reasoningContent.value
          : this.reasoningContent,
      completions: data.completions.present
          ? data.completions.value
          : this.completions,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionMessageDao(')
          ..write('id: $id, ')
          ..write('originSessionId: $originSessionId, ')
          ..write('sessionId: $sessionId, ')
          ..write('originalTaskId: $originalTaskId, ')
          ..write('taskId: $taskId, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('role: $role, ')
          ..write('to: $to, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('reasoningContent: $reasoningContent, ')
          ..write('completions: $completions, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originSessionId,
    sessionId,
    originalTaskId,
    taskId,
    parentTaskId,
    role,
    to,
    type,
    payload,
    reasoningContent,
    completions,
    createTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionMessageDao &&
          other.id == this.id &&
          other.originSessionId == this.originSessionId &&
          other.sessionId == this.sessionId &&
          other.originalTaskId == this.originalTaskId &&
          other.taskId == this.taskId &&
          other.parentTaskId == this.parentTaskId &&
          other.role == this.role &&
          other.to == this.to &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.reasoningContent == this.reasoningContent &&
          other.completions == this.completions &&
          other.createTime == this.createTime);
}

class SessionMessagesCompanion extends UpdateCompanion<SessionMessageDao> {
  final Value<int> id;
  final Value<String> originSessionId;
  final Value<String> sessionId;
  final Value<String> originalTaskId;
  final Value<String> taskId;
  final Value<String?> parentTaskId;
  final Value<String> role;
  final Value<String> to;
  final Value<String> type;
  final Value<String> payload;
  final Value<String?> reasoningContent;
  final Value<String?> completions;
  final Value<DateTime> createTime;
  const SessionMessagesCompanion({
    this.id = const Value.absent(),
    this.originSessionId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.originalTaskId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.role = const Value.absent(),
    this.to = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.reasoningContent = const Value.absent(),
    this.completions = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  SessionMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String originSessionId,
    required String sessionId,
    required String originalTaskId,
    required String taskId,
    this.parentTaskId = const Value.absent(),
    required String role,
    required String to,
    required String type,
    required String payload,
    this.reasoningContent = const Value.absent(),
    this.completions = const Value.absent(),
    required DateTime createTime,
  }) : originSessionId = Value(originSessionId),
       sessionId = Value(sessionId),
       originalTaskId = Value(originalTaskId),
       taskId = Value(taskId),
       role = Value(role),
       to = Value(to),
       type = Value(type),
       payload = Value(payload),
       createTime = Value(createTime);
  static Insertable<SessionMessageDao> custom({
    Expression<int>? id,
    Expression<String>? originSessionId,
    Expression<String>? sessionId,
    Expression<String>? originalTaskId,
    Expression<String>? taskId,
    Expression<String>? parentTaskId,
    Expression<String>? role,
    Expression<String>? to,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? reasoningContent,
    Expression<String>? completions,
    Expression<DateTime>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originSessionId != null) 'origin_session_id': originSessionId,
      if (sessionId != null) 'session_id': sessionId,
      if (originalTaskId != null) 'original_task_id': originalTaskId,
      if (taskId != null) 'task_id': taskId,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (role != null) 'role': role,
      if (to != null) 'to': to,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (reasoningContent != null) 'reasoning_content': reasoningContent,
      if (completions != null) 'completions': completions,
      if (createTime != null) 'create_time': createTime,
    });
  }

  SessionMessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? originSessionId,
    Value<String>? sessionId,
    Value<String>? originalTaskId,
    Value<String>? taskId,
    Value<String?>? parentTaskId,
    Value<String>? role,
    Value<String>? to,
    Value<String>? type,
    Value<String>? payload,
    Value<String?>? reasoningContent,
    Value<String?>? completions,
    Value<DateTime>? createTime,
  }) {
    return SessionMessagesCompanion(
      id: id ?? this.id,
      originSessionId: originSessionId ?? this.originSessionId,
      sessionId: sessionId ?? this.sessionId,
      originalTaskId: originalTaskId ?? this.originalTaskId,
      taskId: taskId ?? this.taskId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      role: role ?? this.role,
      to: to ?? this.to,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      completions: completions ?? this.completions,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originSessionId.present) {
      map['origin_session_id'] = Variable<String>(originSessionId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (originalTaskId.present) {
      map['original_task_id'] = Variable<String>(originalTaskId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
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
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (reasoningContent.present) {
      map['reasoning_content'] = Variable<String>(reasoningContent.value);
    }
    if (completions.present) {
      map['completions'] = Variable<String>(completions.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<DateTime>(createTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionMessagesCompanion(')
          ..write('id: $id, ')
          ..write('originSessionId: $originSessionId, ')
          ..write('sessionId: $sessionId, ')
          ..write('originalTaskId: $originalTaskId, ')
          ..write('taskId: $taskId, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('role: $role, ')
          ..write('to: $to, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('reasoningContent: $reasoningContent, ')
          ..write('completions: $completions, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

abstract class _$AgentDatabase extends GeneratedDatabase {
  _$AgentDatabase(QueryExecutor e) : super(e);
  $AgentDatabaseManager get managers => $AgentDatabaseManager(this);
  late final $AgentsTable agents = $AgentsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionMessagesTable sessionMessages = $SessionMessagesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    agents,
    sessions,
    sessionMessages,
  ];
}

typedef $$AgentsTableCreateCompanionBuilder =
    AgentsCompanion Function({
      required String agentId,
      required String name,
      required String capability,
      required DateTime createTime,
      required DateTime updateTime,
      Value<int> rowid,
    });
typedef $$AgentsTableUpdateCompanionBuilder =
    AgentsCompanion Function({
      Value<String> agentId,
      Value<String> name,
      Value<String> capability,
      Value<DateTime> createTime,
      Value<DateTime> updateTime,
      Value<int> rowid,
    });

class $$AgentsTableFilterComposer
    extends Composer<_$AgentDatabase, $AgentsTable> {
  $$AgentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgentsTableOrderingComposer
    extends Composer<_$AgentDatabase, $AgentsTable> {
  $$AgentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgentsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $AgentsTable> {
  $$AgentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => column,
  );
}

class $$AgentsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $AgentsTable,
          AgentDao,
          $$AgentsTableFilterComposer,
          $$AgentsTableOrderingComposer,
          $$AgentsTableAnnotationComposer,
          $$AgentsTableCreateCompanionBuilder,
          $$AgentsTableUpdateCompanionBuilder,
          (AgentDao, BaseReferences<_$AgentDatabase, $AgentsTable, AgentDao>),
          AgentDao,
          PrefetchHooks Function()
        > {
  $$AgentsTableTableManager(_$AgentDatabase db, $AgentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> agentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> capability = const Value.absent(),
                Value<DateTime> createTime = const Value.absent(),
                Value<DateTime> updateTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentsCompanion(
                agentId: agentId,
                name: name,
                capability: capability,
                createTime: createTime,
                updateTime: updateTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String agentId,
                required String name,
                required String capability,
                required DateTime createTime,
                required DateTime updateTime,
                Value<int> rowid = const Value.absent(),
              }) => AgentsCompanion.insert(
                agentId: agentId,
                name: name,
                capability: capability,
                createTime: createTime,
                updateTime: updateTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $AgentsTable,
      AgentDao,
      $$AgentsTableFilterComposer,
      $$AgentsTableOrderingComposer,
      $$AgentsTableAnnotationComposer,
      $$AgentsTableCreateCompanionBuilder,
      $$AgentsTableUpdateCompanionBuilder,
      (AgentDao, BaseReferences<_$AgentDatabase, $AgentsTable, AgentDao>),
      AgentDao,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String sessionId,
      Value<String?> agentId,
      required String capability,
      Value<String> status,
      Value<String?> topic,
      required DateTime createTime,
      required DateTime updateTime,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> sessionId,
      Value<String?> agentId,
      Value<String> capability,
      Value<String> status,
      Value<String?> topic,
      Value<DateTime> createTime,
      Value<DateTime> updateTime,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AgentDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AgentDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get capability => $composableBuilder(
    column: $table.capability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $SessionsTable,
          SessionDao,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionDao,
            BaseReferences<_$AgentDatabase, $SessionsTable, SessionDao>,
          ),
          SessionDao,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AgentDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<String> capability = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<DateTime> createTime = const Value.absent(),
                Value<DateTime> updateTime = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                sessionId: sessionId,
                agentId: agentId,
                capability: capability,
                status: status,
                topic: topic,
                createTime: createTime,
                updateTime: updateTime,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<String?> agentId = const Value.absent(),
                required String capability,
                Value<String> status = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                required DateTime createTime,
                required DateTime updateTime,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                sessionId: sessionId,
                agentId: agentId,
                capability: capability,
                status: status,
                topic: topic,
                createTime: createTime,
                updateTime: updateTime,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $SessionsTable,
      SessionDao,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionDao, BaseReferences<_$AgentDatabase, $SessionsTable, SessionDao>),
      SessionDao,
      PrefetchHooks Function()
    >;
typedef $$SessionMessagesTableCreateCompanionBuilder =
    SessionMessagesCompanion Function({
      Value<int> id,
      required String originSessionId,
      required String sessionId,
      required String originalTaskId,
      required String taskId,
      Value<String?> parentTaskId,
      required String role,
      required String to,
      required String type,
      required String payload,
      Value<String?> reasoningContent,
      Value<String?> completions,
      required DateTime createTime,
    });
typedef $$SessionMessagesTableUpdateCompanionBuilder =
    SessionMessagesCompanion Function({
      Value<int> id,
      Value<String> originSessionId,
      Value<String> sessionId,
      Value<String> originalTaskId,
      Value<String> taskId,
      Value<String?> parentTaskId,
      Value<String> role,
      Value<String> to,
      Value<String> type,
      Value<String> payload,
      Value<String?> reasoningContent,
      Value<String?> completions,
      Value<DateTime> createTime,
    });

class $$SessionMessagesTableFilterComposer
    extends Composer<_$AgentDatabase, $SessionMessagesTable> {
  $$SessionMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originSessionId => $composableBuilder(
    column: $table.originSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTaskId => $composableBuilder(
    column: $table.originalTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get to => $composableBuilder(
    column: $table.to,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoningContent => $composableBuilder(
    column: $table.reasoningContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionMessagesTableOrderingComposer
    extends Composer<_$AgentDatabase, $SessionMessagesTable> {
  $$SessionMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originSessionId => $composableBuilder(
    column: $table.originSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTaskId => $composableBuilder(
    column: $table.originalTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get to => $composableBuilder(
    column: $table.to,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoningContent => $composableBuilder(
    column: $table.reasoningContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionMessagesTableAnnotationComposer
    extends Composer<_$AgentDatabase, $SessionMessagesTable> {
  $$SessionMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originSessionId => $composableBuilder(
    column: $table.originSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get originalTaskId => $composableBuilder(
    column: $table.originalTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get to =>
      $composableBuilder(column: $table.to, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get reasoningContent => $composableBuilder(
    column: $table.reasoningContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );
}

class $$SessionMessagesTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $SessionMessagesTable,
          SessionMessageDao,
          $$SessionMessagesTableFilterComposer,
          $$SessionMessagesTableOrderingComposer,
          $$SessionMessagesTableAnnotationComposer,
          $$SessionMessagesTableCreateCompanionBuilder,
          $$SessionMessagesTableUpdateCompanionBuilder,
          (
            SessionMessageDao,
            BaseReferences<
              _$AgentDatabase,
              $SessionMessagesTable,
              SessionMessageDao
            >,
          ),
          SessionMessageDao,
          PrefetchHooks Function()
        > {
  $$SessionMessagesTableTableManager(
    _$AgentDatabase db,
    $SessionMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> originSessionId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> originalTaskId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> to = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> reasoningContent = const Value.absent(),
                Value<String?> completions = const Value.absent(),
                Value<DateTime> createTime = const Value.absent(),
              }) => SessionMessagesCompanion(
                id: id,
                originSessionId: originSessionId,
                sessionId: sessionId,
                originalTaskId: originalTaskId,
                taskId: taskId,
                parentTaskId: parentTaskId,
                role: role,
                to: to,
                type: type,
                payload: payload,
                reasoningContent: reasoningContent,
                completions: completions,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String originSessionId,
                required String sessionId,
                required String originalTaskId,
                required String taskId,
                Value<String?> parentTaskId = const Value.absent(),
                required String role,
                required String to,
                required String type,
                required String payload,
                Value<String?> reasoningContent = const Value.absent(),
                Value<String?> completions = const Value.absent(),
                required DateTime createTime,
              }) => SessionMessagesCompanion.insert(
                id: id,
                originSessionId: originSessionId,
                sessionId: sessionId,
                originalTaskId: originalTaskId,
                taskId: taskId,
                parentTaskId: parentTaskId,
                role: role,
                to: to,
                type: type,
                payload: payload,
                reasoningContent: reasoningContent,
                completions: completions,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $SessionMessagesTable,
      SessionMessageDao,
      $$SessionMessagesTableFilterComposer,
      $$SessionMessagesTableOrderingComposer,
      $$SessionMessagesTableAnnotationComposer,
      $$SessionMessagesTableCreateCompanionBuilder,
      $$SessionMessagesTableUpdateCompanionBuilder,
      (
        SessionMessageDao,
        BaseReferences<
          _$AgentDatabase,
          $SessionMessagesTable,
          SessionMessageDao
        >,
      ),
      SessionMessageDao,
      PrefetchHooks Function()
    >;

class $AgentDatabaseManager {
  final _$AgentDatabase _db;
  $AgentDatabaseManager(this._db);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db, _db.agents);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionMessagesTableTableManager get sessionMessages =>
      $$SessionMessagesTableTableManager(_db, _db.sessionMessages);
}
