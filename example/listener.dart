import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:opentool_dart/opentool_dart.dart';

void listen(String sessionId, AgentMessageDto agentMessageDto) {
  String system = "🖥SYSTEM";
  String user = "👤USER";
  String agent = "🤖AGENT";
  String llm = "💡LLM";
  String tool = "🔧TOOL";
  String client = "🔗CLIENT";
  String reflection = "🎯REFLECTION";

  String message = "";
  if (agentMessageDto.type == ToolMessageType.TEXT)
    message = agentMessageDto.message as String;
  if (agentMessageDto.type == ToolMessageType.IMAGE_URL)
    message = agentMessageDto.message as String;
  if (agentMessageDto.type == ToolMessageType.FUNCTION_CALL_LIST) {
    List<dynamic> originalFunctionCallList = agentMessageDto.message as List<dynamic>;
    List<FunctionCall> functionCallList = originalFunctionCallList.map((dynamic json) {
      return FunctionCall.fromJson(json);
    }).toList();
    message = jsonEncode(functionCallList);
  }
  if (agentMessageDto.type == ToolMessageType.TOOL_RETURN) {
    message = jsonEncode(ToolReturn.fromJson(agentMessageDto.message));
  }
  if (agentMessageDto.type == ToolMessageType.CONTENT_LIST) {
    List<dynamic> originalContentList = agentMessageDto.message as List<dynamic>;
    List<ContentDto> contentList = originalContentList.map((dynamic json) {
      return ContentDto.fromJson(json);
    }).toList();
    message = jsonEncode(contentList);
  }
  if (agentMessageDto.type == AgentMessageType.TASK_STATUS) {
    message = jsonEncode(TaskStatusDto.fromJson(agentMessageDto.message));
  }
  if (agentMessageDto.type == TextMessageType.REFLECTION) {
    message = jsonEncode(ReflectionDto.fromJson(agentMessageDto.message));
  }

  String from = "";
  if (agentMessageDto.from == ToolRoleType.SYSTEM) {
    from = system;
    message = "\n$message";
  }
  if (agentMessageDto.from == ToolRoleType.USER) from = user;
  if (agentMessageDto.from == ToolRoleType.AGENT) from = agent;
  if (agentMessageDto.from == ToolRoleType.LLM) from = llm;
  if (agentMessageDto.from == ToolRoleType.TOOL) from = tool;
  if (agentMessageDto.from == ToolRoleType.CLIENT) from = client;
  if (agentMessageDto.from == ToolRoleType.REFLECTION) from = reflection;

  String to = "";
  if (agentMessageDto.to == ToolRoleType.SYSTEM) to = system;
  if (agentMessageDto.to == ToolRoleType.USER) to = user;
  if (agentMessageDto.to == ToolRoleType.AGENT) to = agent;
  if (agentMessageDto.to == ToolRoleType.LLM) to = llm;
  if (agentMessageDto.to == ToolRoleType.TOOL) to = tool;
  if (agentMessageDto.to == ToolRoleType.CLIENT) to = client;
  if (agentMessageDto.to == ToolRoleType.REFLECTION) to = reflection;

  if (from.isNotEmpty && to.isNotEmpty) {
    print("#${sessionId}::${agentMessageDto.taskId}# $from -> $to: [${agentMessageDto.type}] $message");
  }
}