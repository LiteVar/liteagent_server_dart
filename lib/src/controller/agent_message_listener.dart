import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../util/logger.dart';

class AgentMessageListener {
  Map<String, AgentMessageSubscriber> agentMessageSubscriberList = {};

  void subscribe(String sessionId,  AgentMessageSubscriber subscriber) {
    agentMessageSubscriberList[sessionId] = subscriber;
  }

  void listen(String sessionId, AgentMessageDto agentMessageDto) {
    if (agentMessageSubscriberList.containsKey(sessionId)) {
      agentMessageSubscriberList[sessionId]!.add(agentMessageDto);
    }
  }
}

abstract class AgentMessageSubscriber {
  void add(AgentMessageDto agentMessageDto);
}

class AgentMessageSubscriberBySSE extends AgentMessageSubscriber {
  StreamController<List<int>> streamController;
  AgentMessageSubscriberBySSE(this.streamController);

  @override
  void add(AgentMessageDto agentMessageDto) {
    Map<String, dynamic> data = agentMessageDto.toJson();
    List<int> utf8Data = utf8.encode(jsonEncode(data));
    streamController.add(utf8Data);
  }
}

class AgentMessageSubscriberByWS extends AgentMessageSubscriber{
  WebSocketChannel webSocketChannel;
  void Function(String) onReceive;
  String sessionId;

  AgentMessageSubscriberByWS(this.webSocketChannel, this.sessionId, {required this.onReceive}) {
    webSocketChannel.stream.listen((message) {
      final payload = message as String;
      if (payload == "ping") {
        String pong = "pong";
        webSocketChannel.sink.add(pong);
      } else {
        onReceive(payload);
      }
    },
      onDone: () {},
      onError: (e){
        if(e is AgentNotFoundException) {
          logger.log(LogModule.ws, "AgentNotFoundException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
          webSocketChannel.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
        } else if(e is StrategyNotExistException) {
          logger.log(LogModule.ws, "StrategyNotExistException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
          webSocketChannel.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
        } else if(e is LLMException) {
          logger.log(LogModule.ws, "LLMException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
          webSocketChannel.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
        } else {
          logger.log(LogModule.http, "Exception: ${e}", detail: e.toString(), level: Level.WARNING);
          webSocketChannel.sink.close(WebSocketStatus.internalServerError, "SessionId:${sessionId}; ${e.toString()}");
        }
      });
  }

  @override
  void add(AgentMessageDto agentMessageDto) {
    webSocketChannel.sink.add(jsonEncode(agentMessageDto.toJson()));
  }
}