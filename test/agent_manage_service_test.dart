import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/src/db/agent_database_singleton.dart';
import 'package:liteagent_server_dart/src/service/agent_manage_service.dart';
import 'package:test/test.dart';

void main() {
  group('AgentManageServiceByDB', () {
    test('preserves skills when agent is stored and loaded', () async {
      final service = AgentManageServiceByDB(
        AgentDatabaseFactory.getInstance(null),
      );
      final agentDto = AgentDto(
        name: 'skill_agent',
        capability: CapabilityDto(
          llmConfig: LLMConfigDto(
            baseUrl: 'https://example.com/v1',
            model: 'gpt-test',
          ),
          systemPrompt: 'Use the provided skills.',
          skills: const ['skill://planner', 'skill://reviewer'],
          auto: true,
          llmConfigList: [
            LLMConfigDto(
              baseUrl: 'https://example.com/v1',
              model: 'gpt-test-2',
            ),
          ],
          enableThinking: true,
          toolReturnPackMinLength: 1200,
        ),
      );

      final agentId = await service.addAgent(agentDto);
      final stored = await service.getAgent(agentId);

      expect(stored, isNotNull);
      final storedAgent = stored!;
      expect(storedAgent.name, agentDto.name);
      expect(storedAgent.capability.skills, agentDto.capability.skills);
      expect(storedAgent.capability.auto, isTrue);
      expect(storedAgent.capability.enableThinking, isTrue);
      expect(storedAgent.capability.toolReturnPackMinLength, 1200);
      expect(storedAgent.capability.llmConfigList?.length, 1);
      expect(storedAgent.capability.llmConfigList?.first.model, 'gpt-test-2');
    });
  });
}
