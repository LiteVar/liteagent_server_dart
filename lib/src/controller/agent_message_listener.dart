import 'dart:async';
import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lite_agent_core_dart_server/lite_agent_core_dart_server.dart';
import 'package:logging/logging.dart';
import 'package:opentool_dart/opentool_dart.dart';

class AgentMessageListener {
  Map<String, AgentMessageSubscriber> agentMessageSubscriberList = {};

  void subscribe(String sessionId,  AgentMessageSubscriber subscriber) {
    agentMessageSubscriberList[sessionId] = subscriber;
  }

  void listen(String sessionId, AgentMessageDto agentMessageDto) {
    if (agentMessageSubscriberList.containsKey(sessionId)) {
      agentMessageSubscriberList[sessionId]!.addMessage(agentMessageDto);
    }
  }

  void listenChunk(String sessionId, AgentMessageChunkDto agentMessageChunkDto) {
    if (agentMessageSubscriberList.containsKey(sessionId)) {
      agentMessageSubscriberList[sessionId]!.addChunk(agentMessageChunkDto);
    }
  }

  void listenClientFunctionCall(String sessionId, FunctionCall remoteFunctionCall) {
    if (agentMessageSubscriberList.containsKey(sessionId)) {
      agentMessageSubscriberList[sessionId]!.addRemoteFunctionCall(remoteFunctionCall);
    }
  }
}

abstract class AgentMessageSubscriber {
  void addMessage(AgentMessageDto agentMessageDto);
  void addChunk(AgentMessageChunkDto agentMessageChunkDto);
  void addRemoteFunctionCall(FunctionCall functionCall);
}

class AgentMessageSubscriberBySSE implements AgentMessageSubscriber {
  StreamController<List<int>> streamController;

  AgentMessageSubscriberBySSE(this.streamController);

  @override
  void addMessage(AgentMessageDto agentMessageDto) {
    if(agentMessageDto.to == AgentRoleType.CLIENT && agentMessageDto.type == AgentMessageType.TASK_STATUS) {
      TaskStatusDto taskStatusDto = agentMessageDto.message as TaskStatusDto;
      if(!streamController.isClosed && (taskStatusDto.status == TaskStatusType.DONE || taskStatusDto.status == TaskStatusType.STOP || taskStatusDto.status == TaskStatusType.EXCEPTION )) {
        _pushData(SSEEventType.MESSAGE, jsonEncode(agentMessageDto.toJson()));
        streamController.close();
      }
    }
    if(!streamController.isClosed) {
      _pushData(SSEEventType.MESSAGE, jsonEncode(agentMessageDto.toJson()));
    }
  }

  @override
  void addChunk(AgentMessageChunkDto agentMessageChunkDto) {
    _pushData(SSEEventType.CHUNK, jsonEncode(agentMessageChunkDto.toJson()));
  }

  @override
  void addRemoteFunctionCall(FunctionCall functionCall) {
    _pushData(SSEEventType.FUNCTION_CALL, jsonEncode(functionCall.toJson()));
  }

  void _pushData(String eventType, String dataString) {
    String data = "event: $eventType\ndata: $dataString\n\n";
    logger.log(LogModule.sse, "SSE data", detail: data, level: Level.INFO);
    streamController.sink.add(utf8.encode(data));
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