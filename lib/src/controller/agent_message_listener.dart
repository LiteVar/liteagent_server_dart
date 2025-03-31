import 'dart:async';
import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lite_agent_core_dart_server/lite_agent_core_dart_server.dart';
import 'package:logging/logging.dart';

class AgentMessageListener {
  Map<String, Map<String, AgentMessageSubscriber>> agentMessageSubscriberList = {};

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

  void listen(String sessionId, AgentMessageDto agentMessageDto) {
    if(agentMessageDto.type == AgentMessageType.FUNCTION_CALL){
      _listenClientFunctionCall(sessionId, agentMessageDto);
    } else {
      if (agentMessageSubscriberList.containsKey(sessionId)) {
        final taskId = agentMessageDto.taskId;

        if (agentMessageSubscriberList[sessionId]!.containsKey(taskId)) {
          final subscriber = agentMessageSubscriberList[sessionId]![taskId]!;
          subscriber.addMessage(agentMessageDto);
        }
      }
      if(agentMessageDto.type == AgentMessageType.TASK_STATUS) {
        TaskStatusDto taskStatusDto = agentMessageDto.content as TaskStatusDto;
        if(taskStatusDto.status == TaskStatusType.DONE || taskStatusDto.status == TaskStatusType.STOP || taskStatusDto.status == TaskStatusType.EXCEPTION ) {
          unsubscribe(sessionId, agentMessageDto.taskId);
        }
      }
    }
  }

  void listenChunk(String sessionId, AgentMessageChunkDto agentMessageChunkDto) {
    if (agentMessageSubscriberList.containsKey(sessionId)) {
      final taskId = agentMessageChunkDto.taskId;
      
      if (agentMessageSubscriberList[sessionId]!.containsKey(taskId)) {
        final subscriber = agentMessageSubscriberList[sessionId]![taskId]!;
        subscriber.addChunk(agentMessageChunkDto);
      }
    }
  }

  void _listenClientFunctionCall(String sessionId, AgentMessageDto agentMessageDto) {
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
      _pushData(SSEEventType.MESSAGE, jsonEncode(agentMessageDto.toJson()));
    }
  }

  @override
  void addChunk(AgentMessageChunkDto agentMessageChunkDto) {
    _pushData(SSEEventType.CHUNK, jsonEncode(agentMessageChunkDto.toJson()));
  }

  @override
  void addRemoteFunctionCall(AgentMessageDto agentMessageDto) {
    _pushData(SSEEventType.FUNCTION_CALL, jsonEncode(agentMessageDto.toJson()));
  }

  void _pushData(String eventType, String dataString) {
    String data = "event: $eventType\ndata: $dataString\n\n";
    logger.log(LogModule.sse, "SSE data", detail: data, level: Level.INFO);
    streamController.sink.add(utf8.encode(data));
  }

  @override
  close() {
    streamController.close();
  }
}

// class AgentMessageSubscriberBySSE2 implements AgentMessageSubscriber {
//   StreamController<List<int>> streamController;
//
//   AgentMessageSubscriberBySSE2(this.streamController) {
//     _sendInitialPing();
//   }
//
//   void _sendInitialPing() {
//     String initialPing = "event: ping\ndata: {}\n\n";
//     streamController.sink.add(utf8.encode(initialPing));
//   }
//
//   @override
//   void add(AgentMessageDto agentMessageDto) {
//     String agentMessageString = jsonEncode(agentMessageDto.toJson());
//     String data = "event: message\ndata: $agentMessageString\n\n";
//     print("PreAdd: " + data);
//
//     List<int> utf8Data = utf8.encode(data);
//     streamController.sink.add(utf8Data);
//   }
// }
//
// class AgentMessageSubscriberByWS extends AgentMessageSubscriber{
//   WebSocketChannel webSocketChannel;
//   void Function(String) onReceive;
//   String sessionId;
//
//   AgentMessageSubscriberByWS(this.webSocketChannel, this.sessionId, {required this.onReceive}) {
//     webSocketChannel.stream.listen((message) {
//       final payload = message as String;
//       if (payload == "ping") {
//         String pong = "pong";
//         webSocketChannel.sink.add(pong);
//       } else {
//         onReceive(payload);
//       }
//     },
//       onDone: () {},
//       onError: (e){
//         if(e is AgentNotFoundException) {
//           logger.log(LogModule.ws, "AgentNotFoundException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
//           webSocketChannel.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
//         } else if(e is StrategyNotExistException) {
//           logger.log(LogModule.ws, "StrategyNotExistException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
//           webSocketChannel.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
//         } else if(e is LLMException) {
//           logger.log(LogModule.ws, "LLMException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
//           webSocketChannel.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
//         } else {
//           logger.log(LogModule.http, "Exception: ${e}", detail: e.toString(), level: Level.WARNING);
//           webSocketChannel.sink.close(WebSocketStatus.internalServerError, "SessionId:${sessionId}; ${e.toString()}");
//         }
//       });
//   }
//
//   @override
//   void addMessage(AgentMessageDto agentMessageDto) {
//     webSocketChannel.sink.add(jsonEncode(agentMessageDto.toJson()));
//   }
//
//   @override
//   void addChunk(AgentMessageChunkDto agentMessageChunkDto) {
//     // TODO: implement addChunk
//   }
//
//   @override
//   void addRemoteFunctionCall(FunctionCall functionCall) {
//     // TODO: implement addRemoteFunctionCall
//   }
// }