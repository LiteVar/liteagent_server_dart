import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import '../db/agent_database.dart';

class AgentManageServiceByDB extends AgentManageService {
  AgentDatabase agentDB;

  AgentManageServiceByDB(this.agentDB);

  @override
  Future<String> addAgent(AgentDto agentDto) async {
    String agentId = uniqueId();
    AgentDao agentDao = AgentDao(agentId: agentId, name: agentDto.name, capability: jsonEncode(agentDto.capability.toJson()));
    await agentDB.addAgent(agentDao);
    return agentId;
  }

  @override
  Future<AgentDto> getAgent(String agentId) async {
    AgentDao? agentDao = await agentDB.getAgentById(agentId);
    if (agentDao == null) {
      throw AgentNotFoundException(agentId: agentId);
    } else {
      return AgentDto(name: agentDao.name, capability: CapabilityDto.fromJson(jsonDecode(agentDao.capability)));
    }
  }

  @override
  Future<List<AgentInfoDto>> getAgents() async {
    List<AgentDao> agentDaoList = await agentDB.getAllAgents();
    return agentDaoList.map((agentDao) => AgentInfoDto(agentId: agentDao.agentId, name: agentDao.name, capability: CapabilityDto.fromJson(jsonDecode(agentDao.capability)))).toList();
  }

  @override
  Future<String> removeAgent(String agentId) async {
    await agentDB.deleteAgent(AgentDao(agentId: agentId, name: "", capability: ""));
    return agentId;
  }

  @override
  Future<String> updateAgent(String agentId, AgentDto agentDto) async {
    AgentDao agentDao = AgentDao(agentId: agentId, name: agentDto.name, capability: jsonEncode(agentDto.capability.toJson()));
    await agentDB.updateAgent(agentDao);
    return agentId;
  }

}