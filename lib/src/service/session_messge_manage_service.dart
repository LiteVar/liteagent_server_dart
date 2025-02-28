import 'dart:convert';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart/lite_agent_service.dart';
import '../db/agent_database.dart';

class SessionMessageManageServiceByDB extends SessionMessageManageService {
  AgentDatabase agentDB;

  SessionMessageManageServiceByDB(this.agentDB);

  @override
  Future<void> addMessage(SessionAgentMessageDto sessionAgentMessageDto) async {
    AgentMessageDto agentMessageDto = sessionAgentMessageDto.agentMessageDto;
    String message = "";
    if (agentMessageDto.type == ToolMessageType.TEXT)
      message = agentMessageDto.message as String;
    if (agentMessageDto.type == ToolMessageType.IMAGE_URL)
      message = agentMessageDto.message as String;
    if (agentMessageDto.type == ToolMessageType.FUNCTION_CALL_LIST) {
      List<FunctionCallDto> functionCallList = agentMessageDto.message as List<FunctionCallDto>;
      message = jsonEncode(functionCallList);
    }
    if (agentMessageDto.type == ToolMessageType.TOOL_RETURN) {
      message = jsonEncode(agentMessageDto.message as ToolReturnDto);
    };
    if (agentMessageDto.type == AgentMessageType.CONTENT_LIST) {
      List<ContentDto> contentList = agentMessageDto.message as List<ContentDto>;
      message = jsonEncode(contentList);
    }
    if (agentMessageDto.type == AgentMessageType.TASK_STATUS) {
      message = jsonEncode(agentMessageDto.message as TaskStatusDto);
    }
    if (agentMessageDto.type == TextMessageType.REFLECTION) {
      message = jsonEncode(agentMessageDto.message as ReflectionDto);
    }

    SessionMessageDao sessionMessageDao = SessionMessageDao(
      originSessionId: sessionAgentMessageDto.sessionId,
      sessionId: sessionAgentMessageDto.agentMessageDto.sessionId,
      taskId: sessionAgentMessageDto.agentMessageDto.taskId,
      role: sessionAgentMessageDto.agentMessageDto.role,
      to: sessionAgentMessageDto.agentMessageDto.to,
      type: sessionAgentMessageDto.agentMessageDto.type,
      message: message,
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
    dynamic message;
    if (sessionMessageDao.type == ToolMessageType.TEXT)
      message = sessionMessageDao.message;
    if (sessionMessageDao.type == ToolMessageType.IMAGE_URL)
      message = sessionMessageDao.message;
    if (sessionMessageDao.type == ToolMessageType.FUNCTION_CALL_LIST) {
      List<dynamic> fcList = jsonDecode(sessionMessageDao.message);
      List<FunctionCallDto> functionCallList = fcList.map((fc) => FunctionCallDto.fromJson(fc)).toList();
      message = functionCallList;
    }
    if (sessionMessageDao.type == ToolMessageType.TOOL_RETURN) {
      Map<String, dynamic> tr = jsonDecode(sessionMessageDao.message);
      message = ToolReturnDto.fromJson(tr);
    };
    if (sessionMessageDao.type == AgentMessageType.CONTENT_LIST) {
      List<dynamic> ctList = jsonDecode(sessionMessageDao.message);
      List<ContentDto> contentList = ctList.map((ct) => ContentDto.fromJson(ct)).toList();
      message = contentList;
    }
    if (sessionMessageDao.type == AgentMessageType.TASK_STATUS) {
      Map<String, dynamic> ts = jsonDecode(sessionMessageDao.message);
      message = TaskStatusDto.fromJson(ts);
    }
    if (sessionMessageDao.type == TextMessageType.REFLECTION) {
      Map<String, dynamic> ts = jsonDecode(sessionMessageDao.message);
      message = ReflectionDto.fromJson(ts);
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
            message: message,
            completions: completionsDto,
            createTime: sessionMessageDao.createTime
        )
    );
  }
}