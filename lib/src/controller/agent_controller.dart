import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:logging/logging.dart';
import 'package:opentool_dart/opentool_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import '../dto.dart';
import '../config.dart';
import '../util/logger.dart';

class AgentController {
  final AgentService agentService;
  final Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = {};

  AgentController(this.agentService, {Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = const {}}) {
    this.openToolDriverInfoMap.addAll(openToolDriverInfoMap);
  }

  Future<Response> getVersion(Request request) async {
    logger.log(LogModule.http, "Request getVersion");
    VersionDto versionDto = VersionDto(version: config.version);
    logger.log(LogModule.http, "Response getVersion", detail: jsonEncode(versionDto.toJson()));
    return Response.ok(jsonEncode(versionDto.toJson()));
  }

  Future<Response> initSession(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final CapabilityDto capabilityDto = CapabilityDto.fromJson(data);
      logger.log(LogModule.http, "Request initSession", detail: payload, level: Level.FINEST);
      logger.log(LogModule.http, "Request initSession",
          detail: "baseUrl: ${capabilityDto.llmConfig.baseUrl}, " +
              "model: ${capabilityDto.llmConfig.model}, " +
              "systemMessageLength: ${capabilityDto.systemPrompt.length}," +
              "openSpecListLength: ${capabilityDto.openSpecList == null ?"null": capabilityDto.openSpecList!.length}," +
              "sessionListLength: ${capabilityDto.sessionList == null ?"null": capabilityDto.sessionList!.length}"
      );

      Map<String, OpenToolDriver>? openToolDriverMap = {};

      openToolDriverInfoMap.forEach((openToolDto, openToolDriver) {
        openToolDriverMap[openToolDto.openToolId] = openToolDriver;
      });

      SessionDto sessionDto = await agentService.initSession(capabilityDto, listen, opentoolDriverMap: openToolDriverMap);

      logger.log(LogModule.http, "Response initSession", detail: jsonEncode(sessionDto.toJson()));
      return Response.ok(jsonEncode(sessionDto.toJson()));
    } on AgentNameException catch (e) {
      logger.log(LogModule.http, "Response initSession AgentNameException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e);
    } on OpenToolIdNotFoundException catch (e) {
      logger.log(LogModule.http, "Response initSession OpenToolIdNotFoundException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response initSession FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e);
    } catch (e) {
      logger.log(LogModule.http, "Response initSession Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e);
    }
  }

  Future<Response> initSimple(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final SimpleCapabilityDto simpleCapabilityDto = SimpleCapabilityDto.fromJson(data);
      logger.log(LogModule.http, "Request initSimple", detail: payload, level: Level.FINEST);
      logger.log(LogModule.http, "Request initSimple",
          detail: "baseUrl: ${simpleCapabilityDto.llmConfig.baseUrl}, " +
              "model: ${simpleCapabilityDto.llmConfig.model}, " +
              "systemMessageLength: ${simpleCapabilityDto.systemPrompt.length}"
      );

      SessionDto sessionDto = await agentService.initSimple(simpleCapabilityDto);

      logger.log(LogModule.http, "Response initSimple", detail: jsonEncode(sessionDto.toJson()));
      return Response.ok(jsonEncode(sessionDto.toJson()));
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response initSimple FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e);
    } catch (e) {
      logger.log(LogModule.http, "Response initSimple Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e);
    }
  }

  FutureOr<Response> startSession(Request request) {
    Map<String, String> data = request.url.queryParameters;
    logger.log(LogModule.http, "Request startSession", detail: jsonEncode(data));

    String? sessionId = data["id"];
    if(sessionId == null) return Response.badRequest(body: "Session `id` missing in query parameters.");
    final SessionDto sessionDto = SessionDto.fromJson(data);

    return webSocketHandler((WebSocketChannel webSocket) {
      webSocketSessions[sessionDto.id] = webSocket;
      webSocket.stream.listen((message) {
        final payload = message as String;
        if (payload == "ping") {
          logger.log(LogModule.ws, "Receive message", detail: payload, level: Level.FINER);
          WebSocketChannel? webSocketChannel = webSocketSessions[sessionDto.id];
          String pong = "pong";
          logger.log(LogModule.ws, "Send message", detail: pong, level: Level.FINER);
          webSocketChannel?.sink.add(pong);
        } else {
          final data = jsonDecode(payload);
          UserTaskDto userTaskDto = UserTaskDto.fromJson(data);
          logger.log(LogModule.ws, "Receive message", detail: payload);
          agentService.startSession(sessionDto.id, userTaskDto);
        }
      }, onDone: () {
        logger.log(LogModule.ws, "onDone", detail: jsonEncode(data));
      }, onError: (e){
        if(e is AgentNotFoundException) {
          logger.log(LogModule.ws, "AgentNotFoundException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
          webSocket.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
        } else if(e is StrategyNotExistException) {
          logger.log(LogModule.ws, "StrategyNotExistException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
          webSocket.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
        } else if(e is LLMException) {
          logger.log(LogModule.ws, "LLMException: ${e}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
          webSocket.sink.close(WebSocketStatus.unsupportedData, jsonEncode(e.toJson()));
        } else {
          logger.log(LogModule.http, "Exception: ${e}", detail: e.toString(), level: Level.WARNING);
          webSocket.sink.close(WebSocketStatus.internalServerError, "SessionId:${sessionDto.id}; ${e.toString()}");
        }
      });
    })(request);
  }

  Future<Response> startSimple(Request request) async {
    Map<String, String> queryParam = request.url.queryParameters;
    logger.log(LogModule.http, "Request startSession", detail: jsonEncode(queryParam));
    final SessionDto sessionDto = SessionDto.fromJson(queryParam);

    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final UserTaskDto userTaskDto = UserTaskDto.fromJson(data);
      AgentMessageDto agentMessageDto = await agentService.startSimple(sessionDto.id, userTaskDto);

      logger.log(LogModule.http, "Response startSimple", detail: payload);
      return Response.ok(jsonEncode(agentMessageDto.toJson()));
    } on LLMException catch (e) {
      logger.log(LogModule.http, "Response startSimple LLMException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.badRequest(body: e);
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response startSimple AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response startSimple FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e);
    } catch (e) {
      logger.log(LogModule.http, "Response startSimple Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e);
    }
  }

  Future<Response> history(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request history", detail: jsonEncode(data));
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);

      List<AgentMessageDto>? agentMessageDtoList = await agentService.getCacheHistory(sessionDto.id);
      if(agentMessageDtoList == null) {
        logger.log(LogModule.http, "Response history NotFoundException: ", detail: "sessionId: ${sessionDto.id} history not found", level: Level.WARNING);
        return Response.notFound("sessionId: ${sessionDto.id} history not found");
      }
      logger.log(LogModule.http, "Response get history", detail: "agent message list size: ${agentMessageDtoList.length}");
      List<Map<String, dynamic>> agentMessageDtoJsonList = agentMessageDtoList.map((agentMessageDto)=>agentMessageDto.toJson()).toList();
      return Response.ok(jsonEncode(agentMessageDtoJsonList));
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response history FormatException: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.badRequest(body: e);
    } catch (e) {
      logger.log(LogModule.http, "Response history Exception: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.internalServerError(body: e);
    }
  }

  Future<Response> stopSession(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request stopSession", detail: jsonEncode(data));
    try {
      final SessionTaskDto sessionTaskDto = SessionTaskDto.fromJson(data);

      await agentService.stopSession(sessionTaskDto);
      logger.log(LogModule.http, "Response stopSession", detail: jsonEncode(sessionTaskDto.toJson()));
      return Response.ok(jsonEncode(sessionTaskDto.toJson()));
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response stopSession FormatException: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.badRequest(body: e);
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response stopSession AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on Exception catch (e) {
      logger.log(LogModule.http, "Response stopSession Exception: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.internalServerError(body: e);
    }
  }

  Future<Response> clearSession(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request clearSession", detail: jsonEncode(data));
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);

      await agentService.clearSession(sessionDto.id);
      logger.log(LogModule.http, "Response clearSession", detail: jsonEncode(sessionDto.toJson()));
      return Response.ok(jsonEncode(sessionDto.toJson()));
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response clearSession AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response clearSession FormatException: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.badRequest(body: e);
    } on Exception catch (e) {
      logger.log(LogModule.http, "Response clearSession Exception: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.internalServerError(body: e);
    }
  }

  void listen(String sessionId, AgentMessageDto agentMessageDto) {
    WebSocketChannel? webSocketChannel = webSocketSessions[sessionId];
    logger.log(LogModule.ws, "Send message", detail: jsonEncode(agentMessageDto.toJson()));
    webSocketChannel?.sink.add(jsonEncode(agentMessageDto.toJson()));
  }

  Future<Response> getOpenToolList(Request request) async {
    logger.log(LogModule.http, "Request getOpenToolList");
    List<Map<String, dynamic>> openToolDtoJsonList = openToolDriverInfoMap.keys.map((openToolDto) => openToolDto.toJson()).toList();
    logger.log(LogModule.http, "Response getOpenToolList", detail: jsonEncode(openToolDtoJsonList));
    return Response.ok(jsonEncode(openToolDtoJsonList));
  }
// void pushException(String sessionId, ExceptionMessageDto exceptionMessageDto) {
//   WebSocketChannel? webSocketChannel = webSocketSessions[sessionId];
//   webSocketChannel?.sink.add(jsonEncode(exceptionMessageDto.toJson()));
// }
}
