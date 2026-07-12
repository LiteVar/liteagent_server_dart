import 'package:liteagent_core_dart/liteagent_service.dart';

class HistoryTurnStatus {
  static const String running = 'running';
  static const String done = 'done';
  static const String error = 'error';
  static const String stopped = 'stopped';
}

class HistoryTurnSummaryDto {
  final String originalTaskId;
  final String sessionId;
  final AgentMessageDto? userMessage;
  final AgentMessageDto? finalMessage;
  final String status;
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final int? durationMs;
  final TokenUsageDto? usage;
  final int processMessageCount;

  const HistoryTurnSummaryDto({
    required this.originalTaskId,
    required this.sessionId,
    required this.userMessage,
    required this.finalMessage,
    required this.status,
    required this.error,
    required this.createdAt,
    required this.completedAt,
    required this.durationMs,
    required this.usage,
    required this.processMessageCount,
  });

  Map<String, dynamic> toJson() => {
    'originalTaskId': originalTaskId,
    'sessionId': sessionId,
    'userMessage': userMessage?.toJson(),
    'finalMessage': finalMessage?.toJson(),
    'status': status,
    'error': error,
    'createdAt': createdAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'durationMs': durationMs,
    'usage': usage == null
        ? null
        : {
            'promptTokens': usage!.promptTokens,
            'completionTokens': usage!.completionTokens,
            'totalTokens': usage!.totalTokens,
            'contextUsageRatio': usage!.contextUsageRatio ?? 0.0,
          },
    'processMessageCount': processMessageCount,
  };
}
