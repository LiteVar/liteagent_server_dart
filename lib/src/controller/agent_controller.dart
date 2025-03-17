import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:logging/logging.dart';
import 'package:opentool_dart/opentool_dart.dart';
import 'package:shelf/shelf.dart';
import '../dto.dart';
import '../config.dart';
import '../util/logger.dart';
import 'agent_message_listener.dart';

class AgentController {
  final AgentService agentService;
  final AgentManageService agentManageService;
  final Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = {};
  final AgentMessageListener agentMessageListener = AgentMessageListener();
  final Map<String, String> jsonHeaders = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.connectionHeader: 'keep-alive',
  };
  final Map<String, String> streamHeaders = {
    HttpHeaders.contentTypeHeader: 'text/event-stream',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.connectionHeader: 'keep-alive',
    'Cache-Control': 'no-store',
  };

  AgentController(this.agentService, this.agentManageService, {Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = const {}}) {
    this.openToolDriverInfoMap.addAll(openToolDriverInfoMap);
  }

  Future<Response> getVersion(Request request) async {
    logger.log(LogModule.http, "Request getVersion");
    VersionDto versionDto = VersionDto(version: config.version);
    logger.log(LogModule.http, "Response getVersion", detail: jsonEncode(versionDto.toJson()));
    return Response.ok(jsonEncode(versionDto.toJson()), headers: jsonHeaders);
  }

  Future<Response> initSession(Request request) async {
    Map<String, String> queryParameters = request.url.queryParameters;
    final payload = await request.readAsString();
    String? agentId = queryParameters['agentId'];
    CapabilityDto capabilityDto;
    try {
      if (agentId != null) {
        AgentDto? agentDto = await agentManageService.getAgent(agentId);
        if (agentDto == null)  return Response.notFound("Agent not found");
        capabilityDto = agentDto.capability;
      } else {
        final data = jsonDecode(payload);
        capabilityDto = CapabilityDto.fromJson(data);
        logger.log(LogModule.http, "Request initSession", detail: payload, level: Level.FINEST);
        logger.log(LogModule.http, "Request initSession",
          detail: "baseUrl: ${capabilityDto.llmConfig.baseUrl}, " +
            "model: ${capabilityDto.llmConfig.model}, " +
            "systemMessageLength: ${capabilityDto.systemPrompt.length}," +
            "openSpecListLength: ${capabilityDto.openSpecList == null ?"null": capabilityDto.openSpecList!.length}," +
            "sessionListLength: ${capabilityDto.sessionList == null ?"null": capabilityDto.sessionList!.length}"
        );
      }

      Map<String, OpenToolDriver>? openToolDriverMap = {};

      openToolDriverInfoMap.forEach((openToolDto, openToolDriver) {
        openToolDriverMap[openToolDto.openToolId] = openToolDriver;
      });

      SessionDto sessionDto = await agentService.initSession(
          capabilityDto, _listen,
          opentoolDriverMap: openToolDriverMap,
          listenChunk: _listenChunk,
          listenClientFunctionCall: _listenClientFunctionCall
      );

      logger.log(LogModule.http, "Response initSession", detail: jsonEncode(sessionDto.toJson()));
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on AgentNameException catch (e) {
      logger.log(LogModule.http, "Response initSession AgentNameException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } on OpenToolIdNotFoundException catch (e) {
      logger.log(LogModule.http, "Response initSession OpenToolIdNotFoundException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response initSession FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(LogModule.http, "Response initSession Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
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
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response initSimple FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(LogModule.http, "Response initSimple Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> startStream(Request request) async {
    Map<String, String> queryParameters = request.url.queryParameters;
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final SessionDto sessionDto = SessionDto.fromJson(queryParameters);
      UserTaskDto userTaskDto = UserTaskDto.fromJson(data);

      StreamController<List<int>> streamController = StreamController<List<int>>.broadcast();
      AgentMessageSubscriber agentMessageSubscriber = AgentMessageSubscriberBySSE(streamController);
      this.agentMessageListener.subscribe(sessionDto.sessionId, agentMessageSubscriber);

      await agentService.startSession(sessionDto.sessionId, userTaskDto);

      logger.log(LogModule.http, "Response startStream", detail: jsonEncode(sessionDto.toJson()) + " & " + jsonEncode(userTaskDto.toJson()));
      return Response.ok(streamController.stream, headers: streamHeaders, context: {'shelf.io.buffer_output': false});
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response startStream FormatException: ${e}", detail: jsonEncode(queryParameters), level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(LogModule.http, "Response startStream Exception: ${e}", detail: jsonEncode(queryParameters), level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> startSimple(Request request) async {
    Map<String, String> queryParam = request.url.queryParameters;
    logger.log(LogModule.http, "Request startSession", detail: jsonEncode(queryParam));
    final SessionDto sessionDto = SessionDto.fromJson(queryParam);

    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final UserTaskDto userTaskDto = UserTaskDto.fromJson(data);
      AgentMessageDto agentMessageDto = await agentService.startSimple(sessionDto.sessionId, userTaskDto);

      logger.log(LogModule.http, "Response startSimple", detail: payload);
      return Response.ok(jsonEncode(agentMessageDto.toJson()), headers: jsonHeaders);
    } on LLMException catch (e) {
      logger.log(LogModule.http, "Response startSimple LLMException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response startSimple AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response startSimple FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(LogModule.http, "Response startSimple Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> history(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request history", detail: jsonEncode(data));
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);

      List<AgentMessageDto>? agentMessageDtoList = await agentService.getCacheHistory(sessionDto.sessionId);
      if(agentMessageDtoList == null) {
        logger.log(LogModule.http, "Response history NotFoundException: ", detail: "sessionId: ${sessionDto.sessionId} history not found", level: Level.WARNING);
        return Response.notFound("sessionId: ${sessionDto.sessionId} history not found");
      }
      logger.log(LogModule.http, "Response get history", detail: "agent message list size: ${agentMessageDtoList.length}");
      List<Map<String, dynamic>> agentMessageDtoJsonList = agentMessageDtoList.map((agentMessageDto)=>agentMessageDto.toJson()).toList();
      return Response.ok(jsonEncode(agentMessageDtoJsonList), headers: jsonHeaders);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response history FormatException: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(LogModule.http, "Response history Exception: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> stopSession(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request stopSession", detail: jsonEncode(data));
    try {
      final SessionTaskDto sessionTaskDto = SessionTaskDto.fromJson(data);

      await agentService.stopSession(sessionTaskDto);
      logger.log(LogModule.http, "Response stopSession", detail: jsonEncode(sessionTaskDto.toJson()));
      return Response.ok(jsonEncode(sessionTaskDto.toJson()), headers: jsonHeaders);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response stopSession FormatException: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response stopSession AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on Exception catch (e) {
      logger.log(LogModule.http, "Response stopSession Exception: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> clearSession(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request clearSession", detail: jsonEncode(data));
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);

      await agentService.clearSession(sessionDto.sessionId);
      logger.log(LogModule.http, "Response clearSession", detail: jsonEncode(sessionDto.toJson()));
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response clearSession AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response clearSession FormatException: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } on Exception catch (e) {
      logger.log(LogModule.http, "Response clearSession Exception: ${e}", detail: jsonEncode(data), level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }

  void _listen(String sessionId, AgentMessageDto agentMessageDto) {
    agentMessageListener.listen(sessionId, agentMessageDto);
  }

  void _listenChunk(String sessionId, AgentMessageChunkDto agentMessageChunkDto) {
    agentMessageListener.listenChunk(sessionId, agentMessageChunkDto);
  }

  void _listenClientFunctionCall(String sessionId, FunctionCall functionCall) {
    agentMessageListener.listenClientFunctionCall(sessionId, functionCall);
  }

  Future<Response> getOpenToolList(Request request) async {
    logger.log(LogModule.http, "Request getOpenToolList");
    List<Map<String, dynamic>> openToolDtoJsonList = openToolDriverInfoMap.keys.map((openToolDto) => openToolDto.toJson()).toList();
    logger.log(LogModule.http, "Response getOpenToolList", detail: jsonEncode(openToolDtoJsonList));
    return Response.ok(jsonEncode(openToolDtoJsonList), headers: jsonHeaders);
  }

  Future<Response> callback(Request request) async {
    Map<String, String> queryParameters = await request.url.queryParameters;
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      SessionDto sessionDto = SessionDto.fromJson(queryParameters);
      final ToolReturn toolReturn = ToolReturn.fromJson(data);
      logger.log(LogModule.http, "Request callback", detail: jsonEncode(data));
      agentService.clientDriverCallback(sessionDto.sessionId, toolReturn);

      logger.log(LogModule.http, "Response callback", detail: payload);
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on LLMException catch (e) {
      logger.log(LogModule.http, "Response callback LLMException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(LogModule.http, "Response callback AgentNotFoundException: ${e.toJson()}", detail: jsonEncode(e.toJson()), level: Level.WARNING);
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(LogModule.http, "Response callback FormatException: ${e}", detail: payload, level: Level.WARNING);
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(LogModule.http, "Response callback Exception: ${e}", detail: payload, level: Level.WARNING);
      return Response.internalServerError(body: e.toString());
    }
  }
}
