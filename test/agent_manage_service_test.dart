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

    test('normalizes lite_oneapi aliases and preserves adapter', () async {
      final service = AgentManageServiceByDB(
        AgentDatabaseFactory.getInstance(null),
      );
      final agentDto = AgentDto(
        name: 'oneapi_agent',
        capability: CapabilityDto(
          llmConfig: LLMConfigDto(
            provider: 'oneapi',
            baseUrl: 'https://example.com/v1',
            apiKey: 'test-key',
            model: 'deepseek-chat',
            adapter: 'openai',
          ),
          systemPrompt: 'Route requests through oneapi.',
        ),
      );

      final agentId = await service.addAgent(agentDto);
      final stored = await service.getAgent(agentId);

      expect(stored, isNotNull);
      expect(stored!.capability.llmConfig?.provider, 'lite_oneapi');
      expect(stored.capability.llmConfig?.adapter, 'openai');
    });

    test('defaults provider to lite_oneapi when omitted', () async {
      final service = AgentManageServiceByDB(
        AgentDatabaseFactory.getInstance(null),
      );
      final agentDto = AgentDto(
        name: 'default_provider_agent',
        capability: CapabilityDto(
          llmConfig: LLMConfigDto(
            baseUrl: 'https://example.com/v1',
            model: 'gpt-4o-mini',
          ),
          systemPrompt: 'Use server default provider.',
        ),
      );

      final agentId = await service.addAgent(agentDto);
      final stored = await service.getAgent(agentId);

      expect(stored, isNotNull);
      expect(stored!.capability.llmConfig?.provider, 'lite_oneapi');
    });

    test('rejects unsupported provider for server agents', () {
      final service = AgentManageServiceByDB(
        AgentDatabaseFactory.getInstance(null),
      );
      final agentDto = AgentDto(
        name: 'cactus_agent',
        capability: CapabilityDto(
          llmConfig: LLMConfigDto(provider: 'cactus', model: 'mobile-model'),
          systemPrompt: 'This should be rejected on server.',
        ),
      );

      expect(
        () => service.addAgent(agentDto),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid llmConfig.provider'),
          ),
        ),
      );
    });

    test('rejects providerOptions for server agents', () {
      final service = AgentManageServiceByDB(
        AgentDatabaseFactory.getInstance(null),
      );
      final agentDto = AgentDto(
        name: 'provider_options_agent',
        capability: CapabilityDto(
          llmConfig: LLMConfigDto(
            provider: 'openai',
            model: 'gpt-4o-mini',
            providerOptions: {'showLogs': true},
          ),
          systemPrompt: 'This should be rejected on server.',
        ),
      );

      expect(
        () => service.addAgent(agentDto),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid llmConfig.providerOptions'),
          ),
        ),
      );
    });
  });
}
