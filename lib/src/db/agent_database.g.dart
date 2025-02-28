// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_database.dart';

// ignore_for_file: type=lint
class $AgentsTable extends Agents with TableInfo<$AgentsTable, AgentDao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _agentIdMeta =
      const VerificationMeta('agentId');
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
      'agent_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _capabilityMeta =
      const VerificationMeta('capability');
  @override
  late final GeneratedColumn<String> capability = GeneratedColumn<String>(
      'capability', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1, maxTextLength: 2048),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [agentId, name, capability];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agents';
  @override
  VerificationContext validateIntegrity(Insertable<AgentDao> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('agent_id')) {
      context.handle(_agentIdMeta,
          agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta));
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('capability')) {
      context.handle(
          _capabilityMeta,
          capability.isAcceptableOrUnknown(
              data['capability']!, _capabilityMeta));
    } else if (isInserting) {
      context.missing(_capabilityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AgentDao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentDao(
      agentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      capability: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}capability'])!,
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
  const AgentDao(
      {required this.agentId, required this.name, required this.capability});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['agent_id'] = Variable<String>(agentId);
    map['name'] = Variable<String>(name);
    map['capability'] = Variable<String>(capability);
    return map;
  }

  AgentsCompanion toCompanion(bool nullToAbsent) {
    return AgentsCompanion(
      agentId: Value(agentId),
      name: Value(name),
      capability: Value(capability),
    );
  }

  factory AgentDao.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentDao(
      agentId: serializer.fromJson<String>(json['agentId']),
      name: serializer.fromJson<String>(json['name']),
      capability: serializer.fromJson<String>(json['capability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'agentId': serializer.toJson<String>(agentId),
      'name': serializer.toJson<String>(name),
      'capability': serializer.toJson<String>(capability),
    };
  }

  AgentDao copyWith({String? agentId, String? name, String? capability}) =>
      AgentDao(
        agentId: agentId ?? this.agentId,
        name: name ?? this.name,
        capability: capability ?? this.capability,
      );
  AgentDao copyWithCompanion(AgentsCompanion data) {
    return AgentDao(
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      name: data.name.present ? data.name.value : this.name,
      capability:
          data.capability.present ? data.capability.value : this.capability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentDao(')
          ..write('agentId: $agentId, ')
          ..write('name: $name, ')
          ..write('capability: $capability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(agentId, name, capability);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentDao &&
          other.agentId == this.agentId &&
          other.name == this.name &&
          other.capability == this.capability);
}

class AgentsCompanion extends UpdateCompanion<AgentDao> {
  final Value<String> agentId;
  final Value<String> name;
  final Value<String> capability;
  final Value<int> rowid;
  const AgentsCompanion({
    this.agentId = const Value.absent(),
    this.name = const Value.absent(),
    this.capability = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentsCompanion.insert({
    required String agentId,
    required String name,
    required String capability,
    this.rowid = const Value.absent(),
  })  : agentId = Value(agentId),
        name = Value(name),
        capability = Value(capability);
  static Insertable<AgentDao> custom({
    Expression<String>? agentId,
    Expression<String>? name,
    Expression<String>? capability,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (agentId != null) 'agent_id': agentId,
      if (name != null) 'name': name,
      if (capability != null) 'capability': capability,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentsCompanion copyWith(
      {Value<String>? agentId,
      Value<String>? name,
      Value<String>? capability,
      Value<int>? rowid}) {
    return AgentsCompanion(
      agentId: agentId ?? this.agentId,
      name: name ?? this.name,
      capability: capability ?? this.capability,
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AgentDatabase extends GeneratedDatabase {
  _$AgentDatabase(QueryExecutor e) : super(e);
  $AgentDatabaseManager get managers => $AgentDatabaseManager(this);
  late final $AgentsTable agents = $AgentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [agents];
}

typedef $$AgentsTableCreateCompanionBuilder = AgentsCompanion Function({
  required String agentId,
  required String name,
  required String capability,
  Value<int> rowid,
});
typedef $$AgentsTableUpdateCompanionBuilder = AgentsCompanion Function({
  Value<String> agentId,
  Value<String> name,
  Value<String> capability,
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
      column: $table.agentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get capability => $composableBuilder(
      column: $table.capability, builder: (column) => ColumnFilters(column));
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
      column: $table.agentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get capability => $composableBuilder(
      column: $table.capability, builder: (column) => ColumnOrderings(column));
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
      column: $table.capability, builder: (column) => column);
}

class $$AgentsTableTableManager extends RootTableManager<
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
    PrefetchHooks Function()> {
  $$AgentsTableTableManager(_$AgentDatabase db, $AgentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> agentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> capability = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentsCompanion(
            agentId: agentId,
            name: name,
            capability: capability,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String agentId,
            required String name,
            required String capability,
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentsCompanion.insert(
            agentId: agentId,
            name: name,
            capability: capability,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AgentsTableProcessedTableManager = ProcessedTableManager<
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
    PrefetchHooks Function()>;

class $AgentDatabaseManager {
  final _$AgentDatabase _db;
  $AgentDatabaseManager(this._db);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db, _db.agents);
}
