import 'dart:async';
import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:lzstring/lzstring.dart';
import '../db/agent_database.dart';

class AgentManageServiceByDB extends AgentManageService {
  AgentDatabase agentDB;

  AgentManageServiceByDB(this.agentDB);

  @override
  Future<String> addAgent(AgentDto agentDto) async {
    String agentId = uniqueId();
    AgentDao agentDao = await _convertDao(agentId, agentDto);
    await agentDB.addAgent(agentDao);
    return agentId;
  }

  @override
  Future<AgentDto?> getAgent(String agentId) async {
    AgentDao? agentDao = await agentDB.getAgentById(agentId);
    if (agentDao == null) {
      throw AgentNotFoundException(agentId: agentId);
    } else {
      return await _convertDto(agentDao);
    }
  }

  @override
  Future<List<AgentInfoDto>> getAgents() async {
    List<AgentDao> agentDaoList = await agentDB.getAllAgents();
    List<AgentInfoDto> agentInfoDtoList = [];
    for(AgentDao agentDao in agentDaoList) {
      AgentInfoDto agentInfoDto = await _convertInfoDto(agentDao);
      agentInfoDtoList.add(agentInfoDto);
    }
    return agentInfoDtoList;
  }

  @override
  Future<String?> removeAgent(String agentId) async {
    await agentDB.deleteAgent(AgentDao(agentId: agentId, name: "", capability: ""));
    return agentId;
  }

  @override
  Future<String?> updateAgent(String agentId, AgentDto agentDto) async {
    AgentDao agentDao = await _convertDao(agentId, agentDto);
    await agentDB.updateAgent(agentDao);
    return agentId;
  }

  String _compressJson(String origin) {
    if(RegExp(r'[\n\r\t ]').hasMatch(origin)) {
      Map<String, dynamic> decoded = json.decode(origin);
      return json.encode(decoded);
    }
    return origin;
  }

  AgentDto _compressAgent(AgentDto agentDto) {
    List<OpenSpecDto>? openSpecList;
    if(agentDto.capability.openSpecList != null) {
      openSpecList = agentDto.capability.openSpecList!.map((openSpecDto){
        String newOpenSpec = _compressJson(openSpecDto.openSpec);
        openSpecDto.openSpec = newOpenSpec;
        return openSpecDto;
      }).toList();
    }

    ClientOpenToolDto? clientOpenToolDto = agentDto.capability.clientOpenTool;
    if(clientOpenToolDto != null) {
      clientOpenToolDto.opentool = _compressJson(clientOpenToolDto.opentool);
    }

    CapabilityDto newCapabilityDto = CapabilityDto(
        llmConfig: agentDto.capability.llmConfig,
        systemPrompt: agentDto.capability.systemPrompt,
        openSpecList: openSpecList,
        clientOpenTool: clientOpenToolDto,
        sessionList: agentDto.capability.sessionList,
        reflectPromptList: agentDto.capability.reflectPromptList,
        timeoutSeconds: agentDto.capability.timeoutSeconds,
        taskPipelineStrategy: agentDto.capability.taskPipelineStrategy,
        toolPipelineStrategy: agentDto.capability.toolPipelineStrategy
    );
    AgentDto newAgentDto = AgentDto(name: agentDto.name, capability: newCapabilityDto);
    return newAgentDto;
  }

  Future<AgentDao> _convertDao(String agentId, AgentDto agentDto) async {
    AgentDto newAgentDto = _compressAgent(agentDto);
    String capabilityOriginString = jsonEncode(newAgentDto.capability.toJson());
    String? compressedString = await LZString.compressToUTF16(capabilityOriginString);
    if(compressedString == null) throw FormatException("Agent: ${agentDto.name} capability string compress error.");
    return AgentDao(agentId: agentId, name: agentDto.name, capability: compressedString);
  }

  Future<AgentDto> _convertDto(AgentDao agentDao) async {
    String? decompressedString = await LZString.decompressFromUTF16(agentDao.capability);
    if(decompressedString == null) throw FormatException("Agent: ${agentDao.name} capability string decompress error.");
    return AgentDto(name: agentDao.name, capability: CapabilityDto.fromJson(jsonDecode(decompressedString)));
  }

  Future<AgentInfoDto> _convertInfoDto(AgentDao agentDao) async {
    String? decompressedString = await LZString.decompressFromUTF16(agentDao.capability);
    if(decompressedString == null) throw FormatException("Agent: ${agentDao.name} capability string decompress error.");
    return AgentInfoDto(agentId: agentDao.agentId, name: agentDao.name, capability: CapabilityDto.fromJson(jsonDecode(decompressedString)));
  }
}