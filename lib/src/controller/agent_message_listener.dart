import 'dart:async';
import 'dart:convert';
import 'package:liteagent_core/liteagent_core.dart';
import 'package:liteagent_core/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import 'package:logging/logging.dart';

class AgentMessageListener {
  Map<String, Map<String, AgentMessageSubscriber>> agentMessageSubscriberList =
      {}; // sessionId & taskId -> subscriber, for Push messages to task

  Map<String, List<AgentMessageSubscriber>> sessionSubscribers =
      {}; // sessionId -> List<AgentMessageSubscriber>

  void subscribe(
    String sessionId,
    String taskId,
    AgentMessageSubscriber subscriber,
  ) {
    if (!agentMessageSubscriberList.containsKey(sessionId)) {
      agentMessageSubscriberList[sessionId] = {};
    }
    agentMessageSubscriberList[sessionId]![taskId] = subscriber;
  }

  void unsubscribe(String sessionId, String taskId) {
    agentMessageSubscriberList[sessionId]?[taskId]?.close();
    agentMessageSubscriberList[sessionId]?.remove(taskId);
    if (agentMessageSubscriberList.containsKey(sessionId) &&
        agentMessageSubscriberList[sessionId]!.isEmpty) {
      agentMessageSubscriberList.remove(sessionId);
    }
  }

  void subscribeSession(String sessionId, AgentMessageSubscriber subscriber) {
    sessionSubscribers.putIfAbsent(sessionId, () => []);
    sessionSubscribers[sessionId]!.add(subscriber);
  }

  void unsubscribeSession(String sessionId, AgentMessageSubscriber subscriber) {
    sessionSubscribers[sessionId]?.remove(subscriber);
    subscriber.close();
    if (sessionSubscribers[sessionId]?.isEmpty ?? false) {
      sessionSubscribers.remove(sessionId);
    }
  }

  int getSessionSubscriberCount(String sessionId) {
    return sessionSubscribers[sessionId]?.length ?? 0;
  }

  void listen(
    String originalSessionId,
    String taskId,
    AgentMessageDto agentMessageDto,
  ) {
    if (agentMessageDto.type == AgentMessageType.FUNCTION_CALL) {
      _listenClientFunctionCall(originalSessionId, taskId, agentMessageDto);
    } else {
      if (agentMessageSubscriberList.containsKey(originalSessionId) &&
          agentMessageSubscriberList[originalSessionId]!.containsKey(taskId)) {
        final subscriber =
            agentMessageSubscriberList[originalSessionId]![taskId]!;
        subscriber.addMessage(agentMessageDto);
      }
      if (agentMessageSubscriberList.containsKey(originalSessionId) &&
          agentMessageSubscriberList[originalSessionId]!.containsKey(
            agentMessageDto.taskId,
          )) {
        if (agentMessageDto.type == AgentMessageType.TASK_STATUS) {
          TaskStatusDto taskStatusDto =
              agentMessageDto.content as TaskStatusDto;
          if (taskStatusDto.status == TaskStatusType.DONE ||
              taskStatusDto.status == TaskStatusType.STOP ||
              taskStatusDto.status == TaskStatusType.EXCEPTION) {
            unsubscribe(originalSessionId, taskId);
          }
        }
      }

      _broadcastToSessionSubscribers(originalSessionId, agentMessageDto);
    }
  }

  void listenChunk(
    String originalSessionId,
    String taskId,
    AgentMessageChunkDto agentMessageChunkDto,
  ) {
    if (agentMessageSubscriberList.containsKey(originalSessionId) &&
        agentMessageSubscriberList[originalSessionId]!.containsKey(taskId)) {
      final subscriber =
          agentMessageSubscriberList[originalSessionId]![taskId]!;
      subscriber.addChunk(agentMessageChunkDto);
    }

    _broadcastChunkToSessionSubscribers(
      originalSessionId,
      agentMessageChunkDto,
    );
  }

  void _broadcastToSessionSubscribers(
    String sessionId,
    AgentMessageDto agentMessageDto,
  ) {
    final subscribers = sessionSubscribers[sessionId];
    if (subscribers != null && subscribers.isNotEmpty) {
      for (final subscriber in subscribers) {
        subscriber.addMessage(agentMessageDto);
      }
    }
  }

  void _broadcastChunkToSessionSubscribers(
    String sessionId,
    AgentMessageChunkDto agentMessageChunkDto,
  ) {
    final subscribers = sessionSubscribers[sessionId];
    if (subscribers != null && subscribers.isNotEmpty) {
      for (final subscriber in subscribers) {
        subscriber.addChunk(agentMessageChunkDto);
      }
    }
  }

  void _listenClientFunctionCall(
    String sessionId,
    String taskId,
    AgentMessageDto agentMessageDto,
  ) {
    bool deliveredToTaskSubscriber = false;
    final subscribersByTaskId = agentMessageSubscriberList[sessionId];
    final candidateTaskIds = <String>{
      if (agentMessageDto.parentTaskId != null &&
          agentMessageDto.parentTaskId!.isNotEmpty)
        agentMessageDto.parentTaskId!,
      if (agentMessageDto.taskId.isNotEmpty) agentMessageDto.taskId,
      if (taskId.isNotEmpty) taskId,
    };

    if (subscribersByTaskId != null) {
      for (final candidateTaskId in candidateTaskIds) {
        final subscriber = subscribersByTaskId[candidateTaskId];
        if (subscriber != null) {
          subscriber.addRemoteFunctionCall(agentMessageDto);
          deliveredToTaskSubscriber = true;
          break;
        }
      }
    }

    logger.log(
      LogModule.sse,
      "Route functionCall",
      detail:
          "sessionId: $sessionId, parentTaskId: ${agentMessageDto.parentTaskId}, taskId: ${agentMessageDto.taskId}, subscribedTaskIds: ${candidateTaskIds.join(',')}, taskSubscriberDelivered: $deliveredToTaskSubscriber, sessionSubscriberCount: ${getSessionSubscriberCount(sessionId)}",
      level: Level.FINEST,
    );

    _broadcastToSessionSubscribers(sessionId, agentMessageDto);
  }
}

abstract class AgentMessageSubscriber {
  void addMessage(AgentMessageDto agentMessageDto);
  void addChunk(AgentMessageChunkDto agentMessageChunkDto);
  void addRemoteFunctionCall(AgentMessageDto agentMessageDto);
  void close();
}

class AgentMessageSubscriberBySSE implements AgentMessageSubscriber {
  StreamController<List<int>> streamController;

  AgentMessageSubscriberBySSE(this.streamController);

  @override
  void addMessage(AgentMessageDto agentMessageDto) {
    if (!streamController.isClosed) {
      _pushData(
        SSEEventType.MESSAGE,
        jsonEncode(_sanitizeAgentMessage(agentMessageDto)),
      );
    }
  }

  @override
  void addChunk(AgentMessageChunkDto agentMessageChunkDto) {
    if (!streamController.isClosed) {
      _pushData(SSEEventType.CHUNK, jsonEncode(agentMessageChunkDto.toJson()));
    }
  }

  @override
  void addRemoteFunctionCall(AgentMessageDto agentMessageDto) {
    if (!streamController.isClosed) {
      _pushData(
        SSEEventType.FUNCTION_CALL,
        jsonEncode(_sanitizeAgentMessage(agentMessageDto)),
      );
    }
  }

  static Map<String, dynamic> _sanitizeAgentMessage(AgentMessageDto dto) {
    final json = dto.toJson();
    final content = json['content'];
    if (content is List) {
      json['content'] = content.map((item) {
        final Map<String, dynamic> map;
        if (item is ContentDto) {
          map = item.toJson();
        } else if (item is Map<String, dynamic>) {
          map = item;
        } else {
          return item;
        }
        if (map['type'] == AgentMessageType.IMAGE_URL &&
            map['message'] is String &&
            (map['message'] as String).contains(';base64,')) {
          final msg = map['message'] as String;
          final prefix = msg.substring(0, msg.indexOf(';base64,') + 8);
          return {...map, 'message': '${prefix}...'};
        }
        return map;
      }).toList();
    }
    return json;
  }

  void _pushData(String eventType, String dataString) {
    String data = "event:$eventType\ndata:$dataString\n\n";
    logger.log(LogModule.sse, "SSE data", detail: data, level: Level.FINEST);
    streamController.sink.add(utf8.encode(data));
  }

  @override
  void close() {
    if (!streamController.isClosed) {
      streamController.close();
    }
  }
}
