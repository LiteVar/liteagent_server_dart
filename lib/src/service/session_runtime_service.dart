import 'package:liteagent_core_dart/liteagent_service.dart';

import 'session_manage_service.dart';
import 'session_message_manage_service.dart';

class PersistedSessionNotFoundException implements Exception {
  final String sessionId;

  const PersistedSessionNotFoundException(this.sessionId);

  @override
  String toString() => 'Persisted session not found: $sessionId';
}

class PersistedSessionExpiredException implements Exception {
  final String sessionId;

  const PersistedSessionExpiredException(this.sessionId);

  @override
  String toString() => 'Persisted session expired: $sessionId';
}

class SessionRuntimeService {
  final AgentService agentService;
  final SessionManageServiceByDB sessionManageService;
  final SessionMessageManageServiceByDB messageManageService;
  final Map<String, Future<void>> _restoreOperations = {};

  SessionRuntimeService({
    required this.agentService,
    required this.sessionManageService,
    required this.messageManageService,
  });

  Future<void> persistNewSession({
    required String sessionId,
    required CapabilityDto capability,
    String? agentId,
  }) {
    return sessionManageService.addSession(
      sessionId: sessionId,
      capability: capability,
      agentId: agentId,
    );
  }

  Future<void> resolveSession(String sessionId) {
    final inProgress = _restoreOperations[sessionId];
    if (inProgress != null) return inProgress;

    final operation = _restoreSession(sessionId);
    _restoreOperations[sessionId] = operation;
    return operation.whenComplete(() {
      if (identical(_restoreOperations[sessionId], operation)) {
        _restoreOperations.remove(sessionId);
      }
    });
  }

  Future<void> _restoreSession(String sessionId) async {
    final persistedSession = await sessionManageService.getSession(sessionId);
    if (persistedSession == null) {
      throw PersistedSessionNotFoundException(sessionId);
    }
    if (persistedSession.isExpired) {
      if (agentService.getSessionAgent(sessionId) != null) {
        await agentService.clearSession(sessionId);
      }
      throw PersistedSessionExpiredException(sessionId);
    }
    if (agentService.getSessionAgent(sessionId) != null) {
      await sessionManageService.touchSession(sessionId);
      return;
    }

    for (final child
        in persistedSession.capability.sessionList ??
            const <SessionNameDto>[]) {
      if (child.sessionId == sessionId) {
        throw FormatException(
          'Session $sessionId cannot restore itself as a child session',
        );
      }
      await resolveSession(child.sessionId);
    }

    final contextMessages = await messageManageService
        .getCompletedContextMessages(sessionId);
    if (agentService.getSessionAgent(sessionId) != null) return;

    await agentService.initSession(
      persistedSession.capability,
      agentId: persistedSession.agentId,
      restoreState: SessionRestoreState(
        sessionId: sessionId,
        contextMessages: contextMessages,
      ),
    );
    await sessionManageService.touchSession(sessionId);
  }

  Future<List<AgentMessageDto>> getHistory(
    String sessionId, {
    int? page,
    int? pageSize,
  }) async {
    final persistedSession = await sessionManageService.getSession(sessionId);
    if (persistedSession == null) {
      throw PersistedSessionNotFoundException(sessionId);
    }
    final messages = await messageManageService.getMessagesBySession(
      sessionId,
      page: page,
      pageSize: pageSize,
    );
    return messages
        .map((message) => message.agentMessageDto)
        .toList(growable: false);
  }

  Future<List<SessionInfoDto>> getSessionsByAgentId(String agentId) =>
      sessionManageService.getSessionsByAgentId(agentId);

  Future<void> clearSession(String sessionId) async {
    final persistedSession = await sessionManageService.getSession(sessionId);
    if (persistedSession == null) {
      throw PersistedSessionNotFoundException(sessionId);
    }
    if (agentService.getSessionAgent(sessionId) != null) {
      await agentService.clearSession(sessionId);
    }
    await messageManageService.flush();
    await sessionManageService.deleteSession(sessionId);
  }
}
