import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:logging/logging.dart';

import '../db/agent_database.dart';
import '../util/logger.dart';

class SessionMessageManageServiceByDB extends SessionMessageManageService {
  final AgentDatabase agentDB;
  Future<void> _writeTail = Future<void>.value();

  SessionMessageManageServiceByDB(this.agentDB);

  @override
  Future<void> addMessage(SessionAgentMessageDto sessionAgentMessageDto) {
    final operation = _writeTail.then(
      (_) => _insertMessage(sessionAgentMessageDto),
    );
    _writeTail = operation.catchError((Object error, StackTrace stackTrace) {
      logger.log(
        LogModule.db,
        'Persist session message failed',
        detail: '$error\n$stackTrace',
        level: Level.SEVERE,
      );
    });
    return operation;
  }

  Future<void> _insertMessage(
    SessionAgentMessageDto sessionAgentMessageDto,
  ) async {
    final dto = sessionAgentMessageDto.agentMessageDto;
    final completions = dto.completions;
    final originalTaskId = dto.originalTaskId.isEmpty
        ? dto.taskId
        : dto.originalTaskId;
    final payload = dto.toJson()..['originalTaskId'] = originalTaskId;
    await agentDB.addMessage(
      SessionMessagesCompanion.insert(
        originSessionId: sessionAgentMessageDto.sessionId,
        sessionId: dto.sessionId,
        originalTaskId: originalTaskId,
        taskId: dto.taskId,
        parentTaskId: Value(dto.parentTaskId),
        role: dto.role,
        to: dto.to,
        type: dto.type,
        payload: jsonEncode(payload),
        reasoningContent: Value(dto.reasoningContent),
        completions: Value(
          completions == null ? null : jsonEncode(completions.toJson()),
        ),
        createTime: dto.createTime,
      ),
      topic: _extractTopic(dto),
    );
  }

  Future<void> flush() => _writeTail;

  @override
  Future<List<SessionAgentMessageDto>> getMessages() async {
    await flush();
    return _convertList(await agentDB.getAllMessages());
  }

  Future<List<SessionAgentMessageDto>> getMessagesBySession(
    String sessionId, {
    int? page,
    int? pageSize,
  }) async {
    await flush();
    final rows = await agentDB.getMessagesBySession(
      sessionId,
      page: page,
      pageSize: pageSize,
    );
    return _convertList(rows);
  }

  Future<List<AgentMessage>> getCompletedContextMessages(
    String sessionId,
  ) async {
    final messages = await getMessagesBySession(sessionId);
    final completedOriginalTaskIds = <String>{};
    for (final message in messages) {
      final dto = message.agentMessageDto;
      if (dto.type != AgentMessageType.TASK_STATUS) continue;
      final status = _taskStatus(dto.content);
      if (status == TaskStatusType.DONE) {
        completedOriginalTaskIds.add(dto.originalTaskId);
      }
    }

    return messages
        .map((message) => message.agentMessageDto)
        .where((dto) => completedOriginalTaskIds.contains(dto.originalTaskId))
        .map((dto) => dto.toModel())
        .toList(growable: false);
  }

  List<SessionAgentMessageDto> _convertList(List<SessionMessageDao> rows) {
    return rows.map(_convert).toList(growable: false);
  }

  SessionAgentMessageDto _convert(SessionMessageDao row) {
    AgentMessageDto dto;
    try {
      final decoded = jsonDecode(row.payload);
      if (decoded is! Map) throw const FormatException('Not a DTO object');
      dto = AgentMessageDto.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      dto = _convertLegacyRow(row);
    }
    return SessionAgentMessageDto(
      sessionId: row.originSessionId,
      agentMessageDto: dto,
    );
  }

  AgentMessageDto _convertLegacyRow(SessionMessageDao row) {
    dynamic content = row.payload;
    if (row.type != AgentMessageType.TEXT &&
        row.type != AgentMessageType.IMAGE_URL) {
      try {
        final decoded = jsonDecode(row.payload);
        content = _legacyContentFromJson(row.type, decoded);
      } catch (_) {
        // Preserve malformed legacy payloads as their original text.
      }
    }

    CompletionsDto? completions;
    if (row.completions != null && row.completions != 'null') {
      final decoded = jsonDecode(row.completions!);
      if (decoded is Map) {
        completions = CompletionsDto.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    }

    return AgentMessageDto(
      sessionId: row.sessionId,
      originalTaskId: row.originalTaskId,
      taskId: row.taskId,
      parentTaskId: row.parentTaskId,
      role: row.role,
      to: row.to,
      type: row.type,
      content: content,
      reasoningContent: row.reasoningContent,
      completions: completions,
      createTime: row.createTime,
    );
  }

  dynamic _legacyContentFromJson(String type, dynamic decoded) {
    if (type == AgentMessageType.CONTENT_LIST && decoded is List) {
      return decoded
          .map(
            (item) =>
                ContentDto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
    if (type == AgentMessageType.TASK_STATUS && decoded is Map) {
      return TaskStatusDto.fromJson(Map<String, dynamic>.from(decoded));
    }
    return decoded;
  }

  String? _extractTopic(AgentMessageDto dto) {
    if (dto.role != SessionRoleType.USER) return null;
    final content = dto.content;
    String? text;
    if (content is String) {
      text = content;
    } else if (content is List) {
      for (final item in content) {
        if (item is ContentDto && item.type == ContentType.TEXT) {
          text = item.message;
          break;
        }
        if (item is Map && item['type'] == ContentType.TEXT) {
          text = item['message']?.toString();
          break;
        }
      }
    }
    final normalized = text?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.length > 50 ? normalized.substring(0, 50) : normalized;
  }

  String? _taskStatus(dynamic content) {
    if (content is TaskStatusDto) return content.status;
    if (content is TaskStatus) return content.status;
    if (content is Map) return content['status']?.toString();
    return null;
  }
}
