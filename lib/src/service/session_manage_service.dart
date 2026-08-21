import 'dart:convert';

import 'package:liteagent_core_dart/liteagent_service.dart';

import '../db/agent_database.dart';

class PersistedSession {
  final String sessionId;
  final String rootSessionId;
  final String? inlinePath;
  final String? agentId;
  final CapabilityDto capability;
  final String status;
  final String? topic;
  final DateTime createTime;
  final DateTime updateTime;
  final DateTime? expiresAt;

  const PersistedSession({
    required this.sessionId,
    required this.rootSessionId,
    required this.inlinePath,
    required this.agentId,
    required this.capability,
    required this.status,
    required this.topic,
    required this.createTime,
    required this.updateTime,
    required this.expiresAt,
  });

  bool get isExpired =>
      status != SessionPersistenceStatus.active ||
      (expiresAt != null && !DateTime.now().isBefore(expiresAt!));
}

class SessionPersistenceStatus {
  static const String active = 'active';
  static const String expired = 'expired';
  static const String historyOnly = 'history_only';
}

class SessionManageServiceByDB {
  final AgentDatabase agentDB;

  SessionManageServiceByDB(this.agentDB);

  Future<void> addSession({
    required String sessionId,
    required CapabilityDto capability,
    String? agentId,
    String? rootSessionId,
    String? inlinePath,
    DateTime? expiresAt,
  }) async {
    final now = DateTime.now();
    await agentDB.addSession(
      SessionDao(
        sessionId: sessionId,
        rootSessionId: rootSessionId ?? sessionId,
        inlinePath: inlinePath,
        agentId: agentId,
        capability: jsonEncode(capability.toJson()),
        status: SessionPersistenceStatus.active,
        topic: null,
        createTime: now,
        updateTime: now,
        expiresAt: expiresAt,
      ),
    );
  }

  Future<PersistedSession?> getSession(String sessionId) async {
    final row = await agentDB.getSessionById(sessionId);
    return row == null ? null : _convert(row);
  }

  Future<List<PersistedSession>> getSessionTree(String rootSessionId) async {
    final rows = await agentDB.getSessionsByRootSessionId(rootSessionId);
    return rows.map(_convert).toList(growable: false);
  }

  Future<List<SessionInfoDto>> getSessionsByAgentId(String agentId) async {
    final rows = await agentDB.getSessionsByAgentId(agentId);
    final now = DateTime.now();
    return rows
        .where(
          (row) =>
              row.status == SessionPersistenceStatus.active &&
              (row.expiresAt == null || now.isBefore(row.expiresAt!)),
        )
        .map(
          (row) => SessionInfoDto(
            sessionId: row.sessionId,
            agentId: row.agentId,
            createTime: row.createTime,
            topic: row.topic,
          ),
        )
        .toList(growable: false);
  }

  Future<void> touchSession(String sessionId) =>
      agentDB.touchSession(sessionId, DateTime.now());

  Future<void> deleteSession(String sessionId) =>
      agentDB.deleteSessionAndMessages(sessionId);

  Future<void> markInlineSessionTreeHistoryOnly(String rootSessionId) =>
      agentDB.markInlineSessionTreeHistoryOnly(rootSessionId);

  Future<void> deleteSessionTree(String rootSessionId) =>
      agentDB.deleteSessionTreeAndMessages(rootSessionId);

  PersistedSession _convert(SessionDao row) {
    return PersistedSession(
      sessionId: row.sessionId,
      rootSessionId: row.rootSessionId,
      inlinePath: row.inlinePath,
      agentId: row.agentId,
      capability: CapabilityDto.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.capability) as Map),
      ),
      status: row.status,
      topic: row.topic,
      createTime: row.createTime,
      updateTime: row.updateTime,
      expiresAt: row.expiresAt,
    );
  }
}
