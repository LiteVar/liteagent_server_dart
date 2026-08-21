import 'dart:convert';

import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';

import '../history_dto.dart';
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
  }) async {
    final runtimeTree = agentService.getSessionTree(sessionId);
    if (runtimeTree.isEmpty) {
      await sessionManageService.addSession(
        sessionId: sessionId,
        capability: capability,
        agentId: agentId,
      );
      return;
    }

    final pathBySessionId = _buildRuntimePaths(runtimeTree);
    try {
      for (final runtimeInfo in runtimeTree) {
        await sessionManageService.addSession(
          sessionId: runtimeInfo.sessionId,
          capability: runtimeInfo.capability,
          agentId: runtimeInfo.sessionId == sessionId ? agentId : null,
          rootSessionId: sessionId,
          inlinePath: pathBySessionId[runtimeInfo.sessionId],
        );
      }
    } catch (_) {
      await sessionManageService.deleteSessionTree(sessionId);
      rethrow;
    }
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

    final restoredRuntimeTree = agentService.getSessionTree(sessionId);
    final restoredPathBySessionId = _buildRuntimePaths(restoredRuntimeTree);
    final persistedTree = await sessionManageService.getSessionTree(
      persistedSession.rootSessionId,
    );
    final persistedByPath = <String, PersistedSession>{
      for (final item in persistedTree)
        if (item.inlinePath != null) item.inlinePath!: item,
    };

    for (final runtimeInfo in restoredRuntimeTree) {
      if (runtimeInfo.sessionId == sessionId) continue;
      final path = restoredPathBySessionId[runtimeInfo.sessionId];
      if (path == null) continue;
      final oldSession = persistedByPath[path];
      if (oldSession == null) continue;
      final childAgent = agentService.getSessionAgent(runtimeInfo.sessionId);
      if (childAgent == null) continue;
      final childContext = await messageManageService
          .getCompletedContextMessages(oldSession.sessionId);
      childAgent.agentSession.restore(
        SessionRestoreState(
          sessionId: runtimeInfo.sessionId,
          contextMessages: childContext,
        ),
      );
    }

    await _rotatePersistedInlineTree(
      rootSessionId: sessionId,
      runtimeTree: restoredRuntimeTree,
      pathBySessionId: restoredPathBySessionId,
      expiresAt: persistedSession.expiresAt,
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
    final historySessionIds = await _collectHistorySessionIds(sessionId);
    final messages = await messageManageService.getMessagesBySessions(
      historySessionIds,
      page: page,
      pageSize: pageSize,
    );
    return messages
        .map((message) => message.agentMessageDto)
        .toList(growable: false);
  }

  Future<List<HistoryTurnSummaryDto>> getHistorySummary(
    String sessionId, {
    required int page,
    required int pageSize,
  }) async {
    await _requirePersistedSession(sessionId);
    final historySessionIds = await _collectHistorySessionIds(sessionId);
    final turns = await messageManageService.getHistoryTurnPage(
      sessionId,
      historySessionIds,
      page: page,
      pageSize: pageSize,
    );
    if (turns.isEmpty) return const [];

    final candidates = await messageManageService.getHistorySummaryCandidates(
      sessionId,
      historySessionIds,
      turns.map((turn) => turn.originalTaskId).toList(growable: false),
    );
    final candidatesByTask = <String, List<PersistedAgentMessage>>{};
    for (final candidate in candidates) {
      candidatesByTask
          .putIfAbsent(candidate.message.originalTaskId, () => [])
          .add(candidate);
    }

    return turns
        .map((turn) {
          final selection = _selectSummary(
            candidatesByTask[turn.originalTaskId] ?? const [],
          );
          final createdAt =
              selection.user?.message.createTime ?? turn.createdAt;
          final completedAt = selection.completedAt;
          return HistoryTurnSummaryDto(
            originalTaskId: turn.originalTaskId,
            sessionId: sessionId,
            userMessage: selection.user?.message,
            finalMessage: selection.finalMessage?.message,
            status: selection.status,
            error: selection.error,
            createdAt: createdAt,
            completedAt: completedAt,
            durationMs: completedAt == null
                ? null
                : completedAt.difference(createdAt).inMilliseconds,
            usage: selection.usage,
            processMessageCount:
                turn.messageCount - selection.summaryMessageIds.length,
          );
        })
        .toList(growable: false);
  }

  Future<List<AgentMessageDto>> getHistoryProcess(
    String sessionId,
    String originalTaskId, {
    required int page,
    required int pageSize,
  }) async {
    await _requirePersistedSession(sessionId);
    final historySessionIds = await _collectHistorySessionIds(sessionId);
    final belongs = await messageManageService.historyTaskBelongsToRoot(
      sessionId,
      historySessionIds,
      originalTaskId,
    );
    if (!belongs) return const [];

    final candidates = await messageManageService.getHistorySummaryCandidates(
      sessionId,
      historySessionIds,
      [originalTaskId],
    );
    final selection = _selectSummary(candidates);
    return messageManageService.getHistoryProcessMessages(
      historySessionIds,
      originalTaskId,
      page: page,
      pageSize: pageSize,
      excludedMessageIds: selection.summaryMessageIds,
    );
  }

  Future<void> _requirePersistedSession(String sessionId) async {
    if (await sessionManageService.getSession(sessionId) == null) {
      throw PersistedSessionNotFoundException(sessionId);
    }
  }

  _HistorySummarySelection _selectSummary(
    List<PersistedAgentMessage> candidates,
  ) {
    PersistedAgentMessage? user;
    PersistedAgentMessage? finalMessage;
    PersistedAgentMessage? errorStatus;
    PersistedAgentMessage? stopStatus;
    PersistedAgentMessage? doneStatus;
    PersistedAgentMessage? lastUsage;

    for (final candidate in candidates) {
      final message = candidate.message;
      final isSummaryContent =
          message.type == AgentMessageType.TEXT ||
          message.type == AgentMessageType.CONTENT_LIST;
      if (user == null &&
          message.role == SessionRoleType.USER &&
          isSummaryContent) {
        user = candidate;
      }
      if (message.to == SessionRoleType.USER && isSummaryContent) {
        finalMessage = candidate;
      }
      if (message.completions?.usage != null) lastUsage = candidate;
      if (message.type != AgentMessageType.TASK_STATUS) continue;
      final status = _taskStatus(message.content)?.toLowerCase();
      if (status == TaskStatusType.EXCEPTION ||
          status == 'error' ||
          status == 'failed') {
        errorStatus = candidate;
      } else if (status == TaskStatusType.STOP) {
        stopStatus = candidate;
      } else if (status == TaskStatusType.DONE ||
          status == 'complete' ||
          status == 'finished') {
        doneStatus = candidate;
      }
    }

    final String status;
    final DateTime? completedAt;
    String? error;
    if (errorStatus != null) {
      status = HistoryTurnStatus.error;
      completedAt = errorStatus.message.createTime;
      error = _taskError(errorStatus.message.content);
    } else if (stopStatus != null) {
      status = HistoryTurnStatus.stopped;
      completedAt = stopStatus.message.createTime;
    } else if (finalMessage != null || doneStatus != null) {
      status = HistoryTurnStatus.done;
      completedAt = _latestTime(
        finalMessage?.message.createTime,
        doneStatus?.message.createTime,
      );
    } else {
      status = HistoryTurnStatus.running;
      completedAt = null;
    }

    return _HistorySummarySelection(
      user: user,
      finalMessage: finalMessage,
      status: status,
      error: error,
      completedAt: completedAt,
      usage:
          finalMessage?.message.completions?.usage ??
          lastUsage?.message.completions?.usage,
    );
  }

  String? _taskStatus(dynamic content) {
    if (content is TaskStatusDto) return content.status;
    if (content is TaskStatus) return content.status;
    if (content is Map) return content['status']?.toString();
    return null;
  }

  String? _taskError(dynamic content) {
    dynamic description;
    if (content is TaskStatusDto) {
      description = content.description;
    } else if (content is TaskStatus) {
      description = content.description;
    } else if (content is Map) {
      description = content['description'];
    }
    if (description == null) return null;
    if (description is String) return description;
    if (description is Map) {
      for (final key in const ['message', 'error', 'description']) {
        final value = description[key];
        if (value != null) return value.toString();
      }
    }
    return jsonEncode(description);
  }

  DateTime? _latestTime(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }

  Future<List<String>> _collectHistorySessionIds(String rootSessionId) async {
    final persistedTree = await sessionManageService.getSessionTree(
      rootSessionId,
    );
    if (persistedTree.isNotEmpty) {
      return persistedTree
          .map((session) => session.sessionId)
          .toSet()
          .toList(growable: false);
    }

    final runtimeTree = agentService.getSessionTree(rootSessionId);
    if (runtimeTree.isNotEmpty) {
      return runtimeTree
          .map((session) => session.sessionId)
          .toSet()
          .toList(growable: false);
    }
    return [rootSessionId];
  }

  Future<List<SessionInfoDto>> getSessionsByAgentId(String agentId) =>
      sessionManageService.getSessionsByAgentId(agentId);

  Future<void> clearSession(String sessionId) async {
    final persistedSession = await sessionManageService.getSession(sessionId);
    if (persistedSession == null) {
      throw PersistedSessionNotFoundException(sessionId);
    }
    final rootSessionId = persistedSession.rootSessionId;
    if (agentService.getSessionAgent(rootSessionId) != null) {
      await agentService.clearSession(rootSessionId);
    }
    await messageManageService.flush();
    await sessionManageService.deleteSessionTree(rootSessionId);
  }

  Map<String, String> _buildRuntimePaths(
    List<SessionAgentRuntimeInfo> runtimeTree,
  ) {
    final pathBySessionId = <String, String>{};
    for (final runtimeInfo in runtimeTree) {
      final parentSessionId = runtimeInfo.parentSessionId;
      if (parentSessionId == null) {
        pathBySessionId[runtimeInfo.sessionId] = '';
        continue;
      }

      final parentPath = pathBySessionId[parentSessionId];
      final name = runtimeInfo.name;
      if (parentPath == null || name == null || name.isEmpty) {
        throw FormatException(
          'Invalid inline runtime tree at session ${runtimeInfo.sessionId}',
        );
      }
      pathBySessionId[runtimeInfo.sessionId] = parentPath.isEmpty
          ? name
          : '$parentPath/$name';
    }
    return pathBySessionId;
  }

  Future<void> _rotatePersistedInlineTree({
    required String rootSessionId,
    required List<SessionAgentRuntimeInfo> runtimeTree,
    required Map<String, String> pathBySessionId,
    required DateTime? expiresAt,
  }) async {
    final inlineNodes = runtimeTree.where(
      (runtimeInfo) => runtimeInfo.sessionId != rootSessionId,
    );
    if (inlineNodes.isEmpty) return;

    await sessionManageService.markInlineSessionTreeHistoryOnly(rootSessionId);
    for (final runtimeInfo in inlineNodes) {
      await sessionManageService.addSession(
        sessionId: runtimeInfo.sessionId,
        capability: runtimeInfo.capability,
        rootSessionId: rootSessionId,
        inlinePath: pathBySessionId[runtimeInfo.sessionId],
        expiresAt: expiresAt,
      );
    }
  }
}

class _HistorySummarySelection {
  final PersistedAgentMessage? user;
  final PersistedAgentMessage? finalMessage;
  final String status;
  final String? error;
  final DateTime? completedAt;
  final TokenUsageDto? usage;

  const _HistorySummarySelection({
    required this.user,
    required this.finalMessage,
    required this.status,
    required this.error,
    required this.completedAt,
    required this.usage,
  });

  Set<int> get summaryMessageIds => {
    if (user != null) user!.id,
    if (finalMessage != null) finalMessage!.id,
  };
}
