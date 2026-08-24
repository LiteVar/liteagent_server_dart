import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:logging/logging.dart';
import 'package:opentool_dart/opentool_client.dart' show ToolReturn;
import 'package:shelf/shelf.dart';
import '../dto.dart';
import '../config.dart';
import '../util/logger.dart';
import '../service/session_runtime_service.dart';
import 'agent_message_listener.dart';

class AgentController {
  final AgentService agentService;
  final SessionRuntimeService sessionRuntimeService;
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

  AgentController(this.agentService, this.sessionRuntimeService);

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
        presetOpenSpecList = data
            .map((item) => PresetOpenSpecDto.fromJson(item))
            .toList();
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
    final payload = await request.readAsString();
    CapabilityDto capabilityDto;
    try {
      if (request.url.queryParameters.containsKey('agentId')) {
        return Response.badRequest(body: "agentId is no longer supported");
      }

      final data = jsonDecode(payload);
      capabilityDto = CapabilityDto.fromJson(data);
      _normalizeAndValidateCapability(capabilityDto);
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
            "baseUrl: ${capabilityDto.llmConfig?.baseUrl}, " +
            "model: ${capabilityDto.llmConfig?.model}, " +
            "systemMessageLength: ${capabilityDto.systemPrompt.length}," +
            "openSpecListLength: ${capabilityDto.openSpecList == null ? "null" : capabilityDto.openSpecList!.length}," +
            "subAgentListLength: ${capabilityDto.subAgentList == null ? "null" : capabilityDto.subAgentList!.length}",
      );

      SessionDto sessionDto = await agentService.initSession(capabilityDto);
      try {
        await sessionRuntimeService.persistNewSession(
          sessionId: sessionDto.sessionId,
          capability: capabilityDto,
        );
      } catch (_) {
        await agentService.clearSession(sessionDto.sessionId);
        rethrow;
      }

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
      _normalizeAndValidateSimpleCapability(simpleCapabilityDto);
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
            "baseUrl: ${simpleCapabilityDto.llmConfig?.baseUrl}, " +
            "model: ${simpleCapabilityDto.llmConfig?.model}, " +
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
      await sessionRuntimeService.resolveSession(sessionDto.sessionId);

      StreamController<List<int>> streamController =
          StreamController<List<int>>();
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
    } on PersistedSessionNotFoundException catch (e) {
      return Response.notFound(e.toString());
    } on PersistedSessionExpiredException catch (e) {
      return Response(410, body: e.toString());
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
    final data = request.url.queryParameters;
    logger.log(LogModule.http, "Request history", detail: jsonEncode(data));
    try {
      final SessionDto sessionDto = SessionDto.fromJson(data);
      final page = _optionalPositiveInt(data['page'], 'page');
      final pageSize = _optionalPositiveInt(data['pageSize'], 'pageSize');
      if ((page == null) != (pageSize == null)) {
        throw const FormatException(
          'page and pageSize must be provided together',
        );
      }

      final agentMessageDtoList = await sessionRuntimeService.getHistory(
        sessionDto.sessionId,
        page: page,
        pageSize: pageSize,
      );
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
    } on PersistedSessionNotFoundException catch (e) {
      return Response.notFound(e.toString());
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

  Future<Response> historySummary(Request request) async {
    final data = request.url.queryParameters;
    logger.log(
      LogModule.http,
      'Request history summary',
      detail: jsonEncode(data),
    );
    try {
      final sessionDto = SessionDto.fromJson(data);
      final page = _optionalPositiveInt(data['page'], 'page') ?? 1;
      final pageSize = _boundedPageSize(data['pageSize'], 30);
      final summaries = await sessionRuntimeService.getHistorySummary(
        sessionDto.sessionId,
        page: page,
        pageSize: pageSize,
      );
      return Response.ok(
        jsonEncode(summaries.map((summary) => summary.toJson()).toList()),
        headers: jsonHeaders,
      );
    } on PersistedSessionNotFoundException catch (e) {
      return Response.notFound(e.toString());
    } on FormatException catch (e) {
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        'Response history summary Exception: $e',
        detail: jsonEncode(data),
        level: Level.WARNING,
      );
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> historyProcess(Request request) async {
    final data = request.url.queryParameters;
    logger.log(
      LogModule.http,
      'Request history process',
      detail: jsonEncode(data),
    );
    try {
      final sessionDto = SessionDto.fromJson(data);
      final originalTaskId = data['originalTaskId']?.trim();
      if (originalTaskId == null || originalTaskId.isEmpty) {
        throw const FormatException('originalTaskId is required');
      }
      final page = _optionalPositiveInt(data['page'], 'page') ?? 1;
      final pageSize = _boundedPageSize(data['pageSize'], 50);
      final messages = await sessionRuntimeService.getHistoryProcess(
        sessionDto.sessionId,
        originalTaskId,
        page: page,
        pageSize: pageSize,
      );
      return Response.ok(
        jsonEncode(messages.map((message) => message.toJson()).toList()),
        headers: jsonHeaders,
      );
    } on PersistedSessionNotFoundException catch (e) {
      return Response.notFound(e.toString());
    } on FormatException catch (e) {
      return Response.badRequest(body: e.toString());
    } catch (e) {
      logger.log(
        LogModule.http,
        'Response history process Exception: $e',
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

      await sessionRuntimeService.clearSession(sessionDto.sessionId);
      logger.log(
        LogModule.http,
        "Response clearSession",
        detail: jsonEncode(sessionDto.toJson()),
      );
      return Response.ok(jsonEncode(sessionDto.toJson()), headers: jsonHeaders);
    } on PersistedSessionNotFoundException catch (e) {
      return Response.notFound(e.toString());
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
      await sessionRuntimeService.resolveSession(sessionId);

      StreamController<List<int>> streamController =
          StreamController<List<int>>();

      AgentMessageSubscriber subscriber = AgentMessageSubscriberBySSE(
        streamController,
      );

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
        detail:
            "sessionId: $sessionId, subscriberCount: ${agentMessageListener.getSessionSubscriberCount(sessionId)}",
      );

      return Response.ok(
        streamController.stream,
        headers: streamHeaders,
        context: {'shelf.io.buffer_output': false},
      );
    } on PersistedSessionNotFoundException catch (e) {
      return Response.notFound(e.toString());
    } on PersistedSessionExpiredException catch (e) {
      return Response(410, body: e.toString());
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

  void _normalizeAndValidateCapability(CapabilityDto capabilityDto) {
    _normalizeAndValidateLLMConfig(capabilityDto.llmConfig);
    for (final llmConfig
        in capabilityDto.llmConfigList ?? const <LLMConfigDto>[]) {
      _normalizeAndValidateLLMConfig(llmConfig);
    }
    for (final subAgent in capabilityDto.subAgentList ?? const <AgentDto>[]) {
      _normalizeAndValidateCapability(subAgent.capability);
    }
  }

  int? _optionalPositiveInt(String? value, String name) {
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      throw FormatException('$name must be a positive integer');
    }
    return parsed;
  }

  int _boundedPageSize(String? value, int defaultValue) {
    final pageSize = _optionalPositiveInt(value, 'pageSize') ?? defaultValue;
    if (pageSize > 200) {
      throw const FormatException('pageSize must not exceed 200');
    }
    return pageSize;
  }

  void _normalizeAndValidateSimpleCapability(
    SimpleCapabilityDto simpleCapabilityDto,
  ) {
    _normalizeAndValidateLLMConfig(simpleCapabilityDto.llmConfig);
  }

  void _normalizeAndValidateLLMConfig(LLMConfigDto? llmConfig) {
    if (llmConfig == null) {
      return;
    }

    final normalizedProvider = LLMProviderType.normalize(
      llmConfig.provider ?? LLMProviderType.liteOneApi,
    );
    if (normalizedProvider != LLMProviderType.openai &&
        normalizedProvider != LLMProviderType.liteOneApi) {
      throw FormatException(
        'Invalid llmConfig.provider: ${llmConfig.provider}',
      );
    }
    if (llmConfig.providerOptions != null &&
        llmConfig.providerOptions!.isNotEmpty) {
      throw const FormatException('Invalid llmConfig.providerOptions');
    }

    llmConfig.provider = normalizedProvider;
  }
}
