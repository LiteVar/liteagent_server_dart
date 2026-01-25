import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:logging/logging.dart';
import 'package:opentool_dart/opentool_client.dart';
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

  AgentController(
      this.agentService,
      this.agentManageService, {
        Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = const {},
      }) {
    this.openToolDriverInfoMap.addAll(openToolDriverInfoMap);
  }

  Future<Response> getVersion(Request request) async {
    logger.log(LogModule.http, "Request getVersion");
    VersionDto versionDto = VersionDto(version: config.version);
    logger.log(
      LogModule.http,
      "Response getVersion",
      detail: jsonEncode(versionDto.toJson()),
    );
    return Response.ok(jsonEncode(versionDto.toJson()), headers: jsonHeaders);
  }

  Future<Response> setPresetOpenSpecList(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      List<PresetOpenSpecDto> presetOpenSpecList;
      if (data is List) {
        presetOpenSpecList =
            data.map((item) => PresetOpenSpecDto.fromJson(item)).toList();
      } else if (data is Map<String, dynamic>) {
        presetOpenSpecList = [PresetOpenSpecDto.fromJson(data)];
      } else {
        throw const FormatException("Invalid presetOpenSpec payload");
      }
      agentService.setPresetOpenSpecList(presetOpenSpecList);
      return Response.ok("{}");
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response initSession FormatException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response initSession Exception: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> initSession(Request request) async {
    Map<String, String> queryParameters = request.url.queryParameters;
    final payload = await request.readAsString();
    String? agentId = queryParameters['agentId'];
    CapabilityDto capabilityDto;
    try {
      if (agentId != null) {
        AgentDto? agentDto = await agentManageService.getAgent(agentId);
        if (agentDto == null) return Response.notFound("Agent not found");
        capabilityDto = agentDto.capability;
      } else {
        final data = jsonDecode(payload);
        capabilityDto = CapabilityDto.fromJson(data);
        logger.log(
          LogModule.http,
          "Request initSession",
          detail: payload,
          level: Level.FINEST,
        );
        logger.log(
          LogModule.http,
          "Request initSession",
          detail:
          "baseUrl: ${capabilityDto.llmConfig.baseUrl}, " +
              "model: ${capabilityDto.llmConfig.model}, " +
              "systemMessageLength: ${capabilityDto.systemPrompt.length}," +
              "openSpecListLength: ${capabilityDto.openSpecList == null ? "null" : capabilityDto.openSpecList!.length}," +
              "sessionListLength: ${capabilityDto.sessionList == null ? "null" : capabilityDto.sessionList!.length}",
        );
      }

      Map<String, OpenToolDriver>? openToolDriverMap = {};

      openToolDriverInfoMap.forEach((openToolDto, openToolDriver) {
        openToolDriverMap[openToolDto.openToolId] = openToolDriver;
      });

      SessionDto sessionDto = await agentService.initSession(
        capabilityDto,
        agentId: agentId,
        opentoolDriverMap: openToolDriverMap,
      );

      logger.log(
        LogModule.http,
        "Response initSession",
        detail: jsonEncode(sessionDto.toJson()),
      );
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on AgentNameException catch (e) {
      logger.log(
        LogModule.http,
        "Response initSession AgentNameException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on OpenToolIdNotFoundException catch (e) {
      logger.log(
        LogModule.http,
        "Response initSession OpenToolIdNotFoundException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response initSession FormatException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response initSession Exception: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> initSimple(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final SimpleCapabilityDto simpleCapabilityDto =
      SimpleCapabilityDto.fromJson(data);
      logger.log(
        LogModule.http,
        "Request initSimple",
        detail: payload,
        level: Level.FINEST,
      );
      logger.log(
        LogModule.http,
        "Request initSimple",
        detail:
        "baseUrl: ${simpleCapabilityDto.llmConfig.baseUrl}, " +
            "model: ${simpleCapabilityDto.llmConfig.model}, " +
            "systemMessageLength: ${simpleCapabilityDto.systemPrompt.length}",
      );

      SessionDto sessionDto = await agentService.initSimple(
        simpleCapabilityDto,
      );

      logger.log(
        LogModule.http,
        "Response initSimple",
        detail: jsonEncode(sessionDto.toJson()),
      );
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response initSimple FormatException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response initSimple Exception: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
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

      StreamController<List<int>> streamController =
      StreamController<List<int>>.broadcast();
      AgentMessageSubscriber agentMessageSubscriber =
      AgentMessageSubscriberBySSE(streamController);

      void Function(String taskId) getTaskId = (String taskId) async {
        this.agentMessageListener.subscribe(
          sessionDto.sessionId,
          taskId,
          agentMessageSubscriber,
        );
      };

      await agentService.startSession(
        sessionDto.sessionId,
        userTaskDto,
        _listen,
        listenChunk: _listenChunk,
        getTaskId: getTaskId,
      );

      logger.log(
        LogModule.http,
        "Response startStream",
        detail:
        jsonEncode(sessionDto.toJson()) +
            " & " +
            jsonEncode(userTaskDto.toJson()),
      );
      return Response.ok(
        streamController.stream,
        headers: streamHeaders,
        context: {'shelf.io.buffer_output': false},
      );
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response startStream FormatException: ${e}",
        detail: jsonEncode(queryParameters),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response startStream Exception: ${e}",
        detail: jsonEncode(queryParameters),
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> startSimple(Request request) async {
    Map<String, String> queryParam = request.url.queryParameters;
    logger.log(
      LogModule.http,
      "Request startSession",
      detail: jsonEncode(queryParam),
    );
    final SessionDto sessionDto = SessionDto.fromJson(queryParam);

    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final UserTaskDto userTaskDto = UserTaskDto.fromJson(data);
      AgentMessageDto agentMessageDto = await agentService.startSimple(
        sessionDto.sessionId,
        userTaskDto,
      );

      logger.log(LogModule.http, "Response startSimple", detail: payload);
      return Response.ok(
        jsonEncode(agentMessageDto.toJson()),
        headers: jsonHeaders,
      );
    } on LLMException catch (e) {
      logger.log(
        LogModule.http,
        "Response startSimple LLMException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(
        LogModule.http,
        "Response startSimple AgentNotFoundException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response startSimple FormatException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response startSimple Exception: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> history(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request history", detail: jsonEncode(data));
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);

      List<AgentMessageDto>? agentMessageDtoList = await agentService
          .getCacheHistory(sessionDto.sessionId);
      if (agentMessageDtoList == null) {
        logger.log(
          LogModule.http,
          "Response history NotFoundException: ",
          detail: "sessionId: ${sessionDto.sessionId} history not found",
          level: Level.WARNING,
        );
        return Response.notFound(
          "sessionId: ${sessionDto.sessionId} history not found",
        );
      }
      logger.log(
        LogModule.http,
        "Response get history",
        detail: "agent message list size: ${agentMessageDtoList.length}",
      );
      List<Map<String, dynamic>> agentMessageDtoJsonList = agentMessageDtoList
          .map((agentMessageDto) => agentMessageDto.toJson())
          .toList();
      return Response.ok(
        jsonEncode(agentMessageDtoJsonList),
        headers: jsonHeaders,
      );
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response history FormatException: ${e}",
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response history Exception: ${e}",
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> stopSession(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(LogModule.http, "Request stopSession", detail: jsonEncode(data));
    try {
      final SessionTaskDto sessionTaskDto = SessionTaskDto.fromJson(data);

      await agentService.stopSession(sessionTaskDto);
      logger.log(
        LogModule.http,
        "Response stopSession",
        detail: jsonEncode(sessionTaskDto.toJson()),
      );
      return Response.ok(
        jsonEncode(sessionTaskDto.toJson()),
        headers: jsonHeaders,
      );
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response stopSession FormatException: ${e}",
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(
        LogModule.http,
        "Response stopSession AgentNotFoundException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.notFound(e);
    } on Exception catch (e) {
      logger.log(
        LogModule.http,
        "Response stopSession Exception: ${e}",
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> clearSession(Request request) async {
    final data = await request.url.queryParameters;
    logger.log(
      LogModule.http,
      "Request clearSession",
      detail: jsonEncode(data),
    );
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);

      await agentService.clearSession(sessionDto.sessionId);
      logger.log(
        LogModule.http,
        "Response clearSession",
        detail: jsonEncode(sessionDto.toJson()),
      );
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on AgentNotFoundException catch (e) {
      logger.log(
        LogModule.http,
        "Response clearSession AgentNotFoundException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response clearSession FormatException: ${e}",
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on Exception catch (e) {
      logger.log(
        LogModule.http,
        "Response clearSession Exception: ${e}",
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  void _listen(
      String sessionId,
      String taskId,
      AgentMessageDto agentMessageDto,
      ) {
    agentMessageListener.listen(sessionId, taskId, agentMessageDto);
  }

  void _listenChunk(
      String sessionId,
      String taskId,
      AgentMessageChunkDto agentMessageChunkDto,
      ) {
    agentMessageListener.listenChunk(sessionId, taskId, agentMessageChunkDto);
  }

  Future<Response> getOpenToolList(Request request) async {
    logger.log(LogModule.http, "Request getOpenToolList");
    List<Map<String, dynamic>> openToolDtoJsonList = openToolDriverInfoMap.keys
        .map((openToolDto) => openToolDto.toJson())
        .toList();
    logger.log(
      LogModule.http,
      "Response getOpenToolList",
      detail: jsonEncode(openToolDtoJsonList),
    );
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
      logger.log(
        LogModule.http,
        "Response callback LLMException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(
        LogModule.http,
        "Response callback AgentNotFoundException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response callback FormatException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response callback Exception: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> streamCallback(Request request) async {
    final queryParameters = await request.url.queryParameters;
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      final sessionDto = SessionDto.fromJson(queryParameters);
      if (data is! Map<String, dynamic>) {
        return Response.badRequest(body: "Invalid body: expected object");
      }
      final event = data['event'];
      if (event is! String || event.isEmpty) {
        return Response.badRequest(body: "Missing body field: event");
      }
      final toolReturnJson = data['toolReturn'];
      if (toolReturnJson is! Map) {
        return Response.badRequest(body: "Missing body field: toolReturn");
      }

      final toolReturn = ToolReturn.fromJson(
        Map<String, dynamic>.from(toolReturnJson),
      );
      logger.log(
        LogModule.http,
        "Request streamCallback",
        detail: "event: $event, data: ${jsonEncode(toolReturnJson)}",
        level: Level.FINEST,
      );

      agentService.clientDriverStreamCallback(
        sessionDto.sessionId,
        event,
        toolReturn,
      );

      logger.log(
        LogModule.http,
        "Response streamCallback",
        detail: payload,
        level: Level.FINEST,
      );
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on LLMException catch (e) {
      logger.log(
        LogModule.http,
        "Response streamCallback LLMException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } on AgentNotFoundException catch (e) {
      logger.log(
        LogModule.http,
        "Response streamCallback AgentNotFoundException: ${e.toJson()}",
        detail: jsonEncode(e.toJson()),
        level: Level.WARNING,
      );
      return Response.notFound(e);
    } on FormatException catch (e) {
      logger.log(
        LogModule.http,
        "Response streamCallback FormatException: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response streamCallback Exception: ${e}",
        detail: payload,
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> listSessions(Request request) async {
    final queryParameters = request.url.queryParameters;
    final agentId = queryParameters['agentId'];

    logger.log(
      LogModule.http,
      "Request listSessions",
      detail: "agentId: $agentId",
    );

    if (agentId == null || agentId.isEmpty) {
      logger.log(
        LogModule.http,
        "Response listSessions BadRequest: agentId is required",
        level: Level.WARNING,
      );
      return Response.badRequest(body: "agentId is required");
    }

    try {
      List<SessionInfoDto> sessionList = agentService.getSessionsByAgentId(agentId);

      logger.log(
        LogModule.http,
        "Response listSessions",
        detail: "agentId: $agentId, sessionCount: ${sessionList.length}",
      );

      List<Map<String, dynamic>> sessionListJson = sessionList
          .map((sessionInfoDto) => sessionInfoDto.toJson())
          .toList();

      return Response.ok(jsonEncode(sessionListJson), headers: jsonHeaders);
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response listSessions Exception: ${e}",
        detail: "agentId: $agentId",
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> subscribeSession(Request request) async {
    final queryParameters = request.url.queryParameters;
    final sessionId = queryParameters['sessionId'];

    logger.log(
      LogModule.http,
      "Request subscribeSession",
      detail: "sessionId: $sessionId",
    );

    if (sessionId == null || sessionId.isEmpty) {
      logger.log(
        LogModule.http,
        "Response subscribeSession BadRequest: sessionId is required",
        level: Level.WARNING,
      );
      return Response.badRequest(body: "sessionId is required");
    }

    try {
      final sessionAgent = agentService.getSessionAgent(sessionId);
      if (sessionAgent == null) {
        logger.log(
          LogModule.http,
          "Response subscribeSession NotFound: session not found",
          detail: "sessionId: $sessionId",
          level: Level.WARNING,
        );
        return Response.notFound("Session not found: $sessionId");
      }

      StreamController<List<int>> streamController =
      StreamController<List<int>>.broadcast();

      AgentMessageSubscriber subscriber =
      AgentMessageSubscriberBySSE(streamController);

      agentMessageListener.subscribeSession(sessionId, subscriber);

      streamController.onCancel = () {
        logger.log(
          LogModule.http,
          "subscribeSession: client disconnected",
          detail: "sessionId: $sessionId",
        );
        agentMessageListener.unsubscribeSession(sessionId, subscriber);
      };

      logger.log(
        LogModule.http,
        "Response subscribeSession: SSE stream started",
        detail: "sessionId: $sessionId, subscriberCount: ${agentMessageListener.getSessionSubscriberCount(sessionId)}",
      );

      return Response.ok(
        streamController.stream,
        headers: streamHeaders,
        context: {'shelf.io.buffer_output': false},
      );
    } catch (e) {
      logger.log(
        LogModule.http,
        "Response subscribeSession Exception: ${e}",
        detail: "sessionId: $sessionId",
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }
}
