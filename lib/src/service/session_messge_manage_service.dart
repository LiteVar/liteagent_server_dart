import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import 'package:opentool_dart/opentool_dart.dart';
import '../db/agent_database.dart';

class SessionMessageManageServiceByDB extends SessionMessageManageService {
  AgentDatabase agentDB;

  SessionMessageManageServiceByDB(this.agentDB);

  @override
  Future<void> addMessage(SessionAgentMessageDto sessionAgentMessageDto) async {
    AgentMessageDto agentMessageDto = sessionAgentMessageDto.agentMessageDto;
    String message = "";
    if (agentMessageDto.type == ToolMessageType.TEXT)
      message = agentMessageDto.content as String;
    if (agentMessageDto.type == ToolMessageType.IMAGE_URL)
      message = agentMessageDto.content as String;
    if (agentMessageDto.type == ToolMessageType.TOOL_CALLS) {
      List<FunctionCall> functionCallList = agentMessageDto.content as List<FunctionCall>;
      message = jsonEncode(functionCallList);
    }
    if (agentMessageDto.type == ToolMessageType.TOOL_RETURN) {
      message = jsonEncode(agentMessageDto.content as ToolReturn);
    };
    if (agentMessageDto.type == AgentMessageType.CONTENT_LIST) {
      List<ContentDto> contentList = agentMessageDto.content as List<ContentDto>;
      message = jsonEncode(contentList);
    }
    if (agentMessageDto.type == AgentMessageType.TASK_STATUS) {
      message = jsonEncode(agentMessageDto.content as TaskStatusDto);
    }
    if (agentMessageDto.type == TextMessageType.REFLECTION) {
      message = jsonEncode(agentMessageDto.content as ReflectionDto);
    }

    SessionMessageDao sessionMessageDao = SessionMessageDao(
      originSessionId: sessionAgentMessageDto.sessionId,
      sessionId: sessionAgentMessageDto.agentMessageDto.sessionId,
      taskId: sessionAgentMessageDto.agentMessageDto.taskId,
      role: sessionAgentMessageDto.agentMessageDto.role,
      to: sessionAgentMessageDto.agentMessageDto.to,
      type: sessionAgentMessageDto.agentMessageDto.type,
      content: message,
      completions: jsonEncode(sessionAgentMessageDto.agentMessageDto.completions?.toJson()),
      createTime: sessionAgentMessageDto.agentMessageDto.createTime
    );
    await agentDB.addMessage(sessionMessageDao);
  }

  @override
  Future<List<SessionAgentMessageDto>> getMessages() async {
    return _convertList(await agentDB.getAllMessages());
  }

  Future<List<SessionAgentMessageDto>> getMessagesPaginated(int page, int pageSize) async {
    return _convertList(await agentDB.getMessagesPaginated(page, pageSize));
  }

  List<SessionAgentMessageDto> _convertList(List<SessionMessageDao> sessionMessageDaoList) {
    return sessionMessageDaoList.map((sessionMessageDao) => _convert(sessionMessageDao)).toList();
  }

  SessionAgentMessageDto _convert(SessionMessageDao sessionMessageDao) {
    dynamic content;
    if (sessionMessageDao.type == ToolMessageType.TEXT)
      content = sessionMessageDao.content;
    if (sessionMessageDao.type == ToolMessageType.IMAGE_URL)
      content = sessionMessageDao.content;
    if (sessionMessageDao.type == ToolMessageType.TOOL_CALLS) {
      List<dynamic> fcList = jsonDecode(sessionMessageDao.content);
      List<FunctionCall> functionCallList = fcList.map((fc) => FunctionCall.fromJson(fc)).toList();
      content = functionCallList;
    }
    if (sessionMessageDao.type == ToolMessageType.TOOL_RETURN) {
      Map<String, dynamic> tr = jsonDecode(sessionMessageDao.content);
      content = ToolReturn.fromJson(tr);
    };
    if (sessionMessageDao.type == AgentMessageType.CONTENT_LIST) {
      List<dynamic> ctList = jsonDecode(sessionMessageDao.content);
      List<ContentDto> contentList = ctList.map((ct) => ContentDto.fromJson(ct)).toList();
      content = contentList;
    }
    if (sessionMessageDao.type == AgentMessageType.TASK_STATUS) {
      Map<String, dynamic> ts = jsonDecode(sessionMessageDao.content);
      content = TaskStatusDto.fromJson(ts);
    }
    if (sessionMessageDao.type == TextMessageType.REFLECTION) {
      Map<String, dynamic> ts = jsonDecode(sessionMessageDao.content);
      content = ReflectionDto.fromJson(ts);
    }

    CompletionsDto? completionsDto;
    if (sessionMessageDao.completions != null) {
      completionsDto = CompletionsDto.fromJson(jsonDecode(sessionMessageDao.completions!));
    }

    return SessionAgentMessageDto(
        sessionId: sessionMessageDao.originSessionId,
        agentMessageDto: AgentMessageDto(
            sessionId: sessionMessageDao.sessionId,
            taskId: sessionMessageDao.taskId,
            role: sessionMessageDao.role,
            to: sessionMessageDao.to,
            type: sessionMessageDao.type,
            content: content,
            completions: completionsDto,
            createTime: sessionMessageDao.createTime
        )
    );
  }
}