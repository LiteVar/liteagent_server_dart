import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lite_agent_core_dart_server/src/service/agent_manage_service.dart';
import 'package:shelf/shelf.dart';

AgentManageService agentManageService = AgentManageServiceByDB();

class AgentManageController {

  Future<Response> listAgent(Request request) async {
    List<AgentInfoDto> agents = await agentManageService.getAgents();
    return Response.ok(jsonEncode(agents.map((e) => e.toJson()).toList()));
  }

  Future<Response> getAgent(Request request) async {
    String? agentId = request.url.queryParameters['agentId'];
    if (agentId == null) {
      return Response.notFound(FormatException('agentId is required'));
    }
    AgentDto agentDto = await agentManageService.getAgent(agentId);
    return Response.ok(jsonEncode(agentDto.toJson()));
  }

  Future<Response> createAgent(Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    try {
      AgentDto agentDto = AgentDto.fromJson(data);
      String agentId = await agentManageService.addAgent(agentDto);
      return Response.ok(jsonEncode(AgentIdDto(agentId: agentId).toJson()));
    } on FormatException catch (e) {
      return Response.badRequest(body: e);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
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
      String agentIdUpdated = await agentManageService.updateAgent(agentId, agentDto);
      return Response.ok(jsonEncode(AgentIdDto(agentId: agentIdUpdated).toJson()));
    }catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> deleteAgent(Request request) async {
    String? agentId = request.url.queryParameters['agentId'];
    if (agentId == null) {
      return Response.notFound(FormatException('agentId is required'));
    }
    try {
      String agentIdDeleted = await agentManageService.removeAgent(agentId);
      return Response.ok(jsonEncode(AgentIdDto(agentId: agentIdDeleted).toJson()));
    }catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
}