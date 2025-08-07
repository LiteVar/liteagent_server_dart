import 'dart:async';
import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lite_agent_core_dart_server/lite_agent_core_dart_server.dart';

class AgentMessageListener {
  Map<String, Map<String, AgentMessageSubscriber>> agentMessageSubscriberList = {}; // sessionId & taskId -> subscriber, for Push messages to task

  void subscribe(String sessionId, String taskId, AgentMessageSubscriber subscriber) {
    if (!agentMessageSubscriberList.containsKey(sessionId)) {
      agentMessageSubscriberList[sessionId] = {};
    }
    agentMessageSubscriberList[sessionId]![taskId] = subscriber;
  }

  void unsubscribe(String sessionId, String taskId) {
    agentMessageSubscriberList[sessionId]?[taskId]?.close();
    agentMessageSubscriberList[sessionId]?.remove(taskId);
    if(agentMessageSubscriberList.containsKey(sessionId) && agentMessageSubscriberList[sessionId]!.isEmpty) {
      agentMessageSubscriberList.remove(sessionId);
    }
  }

  void listen(String originalSessionId, String taskId, AgentMessageDto agentMessageDto) {
    if(agentMessageDto.type == AgentMessageType.FUNCTION_CALL) {
      _listenClientFunctionCall(originalSessionId, taskId, agentMessageDto);
    } else {
      if (agentMessageSubscriberList.containsKey(originalSessionId) && agentMessageSubscriberList[originalSessionId]!.containsKey(taskId)) {
        final subscriber = agentMessageSubscriberList[originalSessionId]![taskId]!;
        subscriber.addMessage(agentMessageDto);
      }
      if (agentMessageSubscriberList.containsKey(originalSessionId) && agentMessageSubscriberList[originalSessionId]!.containsKey(agentMessageDto.taskId)) {
        if(agentMessageDto.type == AgentMessageType.TASK_STATUS) {
          TaskStatusDto taskStatusDto = agentMessageDto.content as TaskStatusDto;
          if(taskStatusDto.status == TaskStatusType.DONE || taskStatusDto.status == TaskStatusType.STOP || taskStatusDto.status == TaskStatusType.EXCEPTION ) {
            unsubscribe(originalSessionId, taskId);
          }
        }
      }
    }
  }

  void listenChunk(String originalSessionId, String taskId, AgentMessageChunkDto agentMessageChunkDto) {
    if (agentMessageSubscriberList.containsKey(originalSessionId) && agentMessageSubscriberList[originalSessionId]!.containsKey(taskId)) {
        final subscriber = agentMessageSubscriberList[originalSessionId]![taskId]!;
        subscriber.addChunk(agentMessageChunkDto);
    }
  }

  void _listenClientFunctionCall(String sessionId, String taskId, AgentMessageDto agentMessageDto) {
    if (agentMessageSubscriberList.containsKey(sessionId)) {
      final taskId = agentMessageDto.taskId;
      if (agentMessageSubscriberList[sessionId]!.containsKey(taskId)) {
        final subscriber = agentMessageSubscriberList[sessionId]![taskId]!;
        // FunctionCall functionCall = agentMessageDto.content as FunctionCall;
        subscriber.addRemoteFunctionCall(agentMessageDto);
      }
    }
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
    if(!streamController.isClosed) {
      // print(agentMessageDto.toJson());
      _pushData(SSEEventType.MESSAGE, jsonEncode(agentMessageDto.toJson()));
    }
  }

  @override
  void addChunk(AgentMessageChunkDto agentMessageChunkDto) {
    // print(agentMessageChunkDto.toJson());
    _pushData(SSEEventType.CHUNK, jsonEncode(agentMessageChunkDto.toJson()));
  }

  @override
  void addRemoteFunctionCall(AgentMessageDto agentMessageDto) {
    // print(agentMessageDto.toJson());
    _pushData(SSEEventType.FUNCTION_CALL, jsonEncode(agentMessageDto.toJson()));
  }

  void _pushData(String eventType, String dataString) {
    String data = "event:$eventType\ndata:$dataString\n\n";
    logger.log(LogModule.sse, "SSE data", detail: data, level: config.log.level);
    streamController.sink.add(utf8.encode(data));
  }

  @override
  void close() {
    streamController.close();
  }
}