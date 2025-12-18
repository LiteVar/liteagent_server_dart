import 'dart:convert';
import 'dart:io';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:shelf/shelf.dart';

class AgentManageController {
  AgentManageService agentManageService;

  final jsonHeaders = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.connectionHeader: 'keep-alive',
  };

  AgentManageController(this.agentManageService);

  Future<Response> listAgent(Request request) async {
    try {
      List<AgentInfoDto> agents = await agentManageService.getAgents();
      return Response.ok(jsonEncode(agents.map((e) => e.toJson()).toList()), headers: jsonHeaders);
    } catch(e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> getAgent(Request request) async {
    try {
      String? agentId = request.url.queryParameters['agentId'];
      if (agentId == null) {
        return Response.notFound(AgentNotFoundException(agentId: "NULL").toJson());
      }
      AgentDto? agentDto = await agentManageService.getAgent(agentId);
      if (agentDto == null) {
        return Response.notFound(AgentNotFoundException(agentId: agentId).toJson());
      }
      return Response.ok(jsonEncode(agentDto.toJson()), headers: jsonHeaders);
    } catch(e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> createAgent(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      AgentDto agentDto = AgentDto.fromJson(data);

      String agentId = await agentManageService.addAgent(agentDto);
      return Response.ok(jsonEncode(AgentIdDto(agentId: agentId).toJson()), headers: jsonHeaders);
    } on FormatException catch (e) {
      return Response.badRequest(body: e.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> updateAgent(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    String? agentId = request.url.queryParameters['agentId'];
    if (agentId == null) {
      return Response.notFound(FormatException('agentId is required'));
    }

    try {
      AgentDto agentDto = AgentDto.fromJson(data);
      String? agentIdUpdated = await agentManageService.updateAgent(agentId, agentDto);
      if (agentIdUpdated == null) {
        return Response.notFound(AgentNotFoundException(agentId: agentId).toJson());
      }
      return Response.ok(jsonEncode(AgentIdDto(agentId: agentIdUpdated).toJson()), headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> deleteAgent(Request request) async {
    String? agentId = request.url.queryParameters['agentId'];
    if (agentId == null) {
      return Response.notFound(FormatException('agentId is required'));
    }
    try {
      String? agentIdDeleted = await agentManageService.removeAgent(agentId);
      if (agentIdDeleted == null) {
        return Response.notFound(AgentNotFoundException(agentId: agentId).toJson());
      }
      return Response.ok(jsonEncode(AgentIdDto(agentId: agentIdDeleted).toJson()), headers: jsonHeaders);
    }catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }
}