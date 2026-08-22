import 'dart:async';
import 'dart:convert';
import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:lzstring/lzstring.dart';
import 'package:unique_id_dart/unique_id_dart.dart';
import '../db/agent_database.dart';

class AgentManageServiceByDB extends AgentManageService {
  AgentDatabase agentDB;

  AgentManageServiceByDB(this.agentDB);

  @override
  Future<String> addAgent(AgentDto agentDto) async {
    _normalizeAndValidateAgent(agentDto);
    String agentId = uniqueId();
    final now = DateTime.now();
    AgentDao agentDao = await _convertDao(
      agentId,
      agentDto,
      createTime: now,
      updateTime: now,
    );
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
    for (AgentDao agentDao in agentDaoList) {
      AgentInfoDto agentInfoDto = await _convertInfoDto(agentDao);
      agentInfoDtoList.add(agentInfoDto);
    }
    return agentInfoDtoList;
  }

  @override
  Future<String?> removeAgent(String agentId) async {
    final now = DateTime.now();
    await agentDB.deleteAgent(
      AgentDao(
        agentId: agentId,
        name: "",
        capability: "",
        createTime: now,
        updateTime: now,
      ),
    );
    return agentId;
  }

  @override
  Future<String?> updateAgent(String agentId, AgentDto agentDto) async {
    _normalizeAndValidateAgent(agentDto);
    AgentDao? existingAgent = await agentDB.getAgentById(agentId);
    final createTime = existingAgent?.createTime ?? DateTime.now();
    final updateTime = DateTime.now();
    AgentDao agentDao = await _convertDao(
      agentId,
      agentDto,
      createTime: createTime,
      updateTime: updateTime,
    );
    await agentDB.updateAgent(agentDao);
    return agentId;
  }

  String _compressJson(String origin) {
    if (RegExp(r'[\n\r\t ]').hasMatch(origin)) {
      Map<String, dynamic> decoded = json.decode(origin);
      return json.encode(decoded);
    }
    return origin;
  }

  AgentDto _compressAgent(AgentDto agentDto) {
    final newCapabilityDto = _compressCapability(agentDto.capability);
    return AgentDto(name: agentDto.name, capability: newCapabilityDto);
  }

  CapabilityDto _compressCapability(CapabilityDto capability) {
    _applyServerProviderDefaults(capability);
    List<OpenSpecDto>? openSpecList;
    if (capability.openSpecList != null) {
      openSpecList = capability.openSpecList!.map((openSpecDto) {
        String newOpenSpec = _compressJson(openSpecDto.openSpec);
        openSpecDto.openSpec = newOpenSpec;
        return openSpecDto;
      }).toList();
    }

    CallbackOpenToolDto? callbackOpenToolDto = capability.callbackOpenTool;
    if (callbackOpenToolDto != null) {
      callbackOpenToolDto.opentool = _compressJson(
        callbackOpenToolDto.opentool,
      );
    }

    final subAgentList = capability.subAgentList
        ?.map(_compressAgent)
        .toList(growable: false);

    return CapabilityDto(
      llmConfig: capability.llmConfig,
      systemPrompt: capability.systemPrompt,
      skills: capability.skills,
      openSpecList: openSpecList,
      callbackOpenTool: callbackOpenToolDto,
      subAgentList: subAgentList,
      timeoutSeconds: capability.timeoutSeconds,
      taskPipelineStrategy: capability.taskPipelineStrategy,
      toolPipelineStrategy: capability.toolPipelineStrategy,
      auto: capability.auto,
      llmConfigList: capability.llmConfigList,
      enableThinking: capability.enableThinking,
      toolReturnPackMinLength: capability.toolReturnPackMinLength,
      maxLlmRequests: capability.maxLlmRequests,
      maxToolRounds: capability.maxToolRounds,
      maxToolCalls: capability.maxToolCalls,
      maxConsecutiveIdenticalToolRounds:
          capability.maxConsecutiveIdenticalToolRounds,
      maxTaskDurationSeconds: capability.maxTaskDurationSeconds,
    );
  }

  Future<AgentDao> _convertDao(
    String agentId,
    AgentDto agentDto, {
    required DateTime createTime,
    required DateTime updateTime,
  }) async {
    AgentDto newAgentDto = _compressAgent(agentDto);
    String capabilityOriginString = jsonEncode(newAgentDto.capability.toJson());
    String? compressedString = await LZString.compressToUTF16(
      capabilityOriginString,
    );
    if (compressedString == null)
      throw FormatException(
        "Agent: ${agentDto.name} capability string compress error.",
      );
    return AgentDao(
      agentId: agentId,
      name: agentDto.name,
      capability: compressedString,
      createTime: createTime,
      updateTime: updateTime,
    );
  }

  Future<AgentDto> _convertDto(AgentDao agentDao) async {
    String? decompressedString = await LZString.decompressFromUTF16(
      agentDao.capability,
    );
    if (decompressedString == null)
      throw FormatException(
        "Agent: ${agentDao.name} capability string decompress error.",
      );
    final agentDto = AgentDto(
      name: agentDao.name,
      capability: CapabilityDto.fromJson(jsonDecode(decompressedString)),
    );
    _applyServerProviderDefaults(agentDto.capability);
    return agentDto;
  }

  Future<AgentInfoDto> _convertInfoDto(AgentDao agentDao) async {
    String? decompressedString = await LZString.decompressFromUTF16(
      agentDao.capability,
    );
    if (decompressedString == null)
      throw FormatException(
        "Agent: ${agentDao.name} capability string decompress error.",
      );
    final capability = CapabilityDto.fromJson(jsonDecode(decompressedString));
    _applyServerProviderDefaults(capability);
    return AgentInfoDto(
      agentId: agentDao.agentId,
      name: agentDao.name,
      capability: capability,
      createTime: agentDao.createTime,
      updateTime: agentDao.updateTime,
    );
  }

  void _normalizeAndValidateAgent(AgentDto agentDto) {
    _normalizeAndValidateCapability(agentDto.capability);
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

  void _applyServerProviderDefaults(CapabilityDto capabilityDto) {
    _applyServerProviderDefaultToLLMConfig(capabilityDto.llmConfig);
    for (final llmConfig
        in capabilityDto.llmConfigList ?? const <LLMConfigDto>[]) {
      _applyServerProviderDefaultToLLMConfig(llmConfig);
    }
    for (final subAgent in capabilityDto.subAgentList ?? const <AgentDto>[]) {
      _applyServerProviderDefaults(subAgent.capability);
    }
  }

  void _applyServerProviderDefaultToLLMConfig(LLMConfigDto? llmConfig) {
    if (llmConfig == null) {
      return;
    }

    llmConfig.provider = LLMProviderType.normalize(
      llmConfig.provider ?? LLMProviderType.liteOneApi,
    );
  }
}
