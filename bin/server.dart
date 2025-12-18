import 'dart:io';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// List<ToolDriver> globalToolDriverList = [
//   /// add GlobalToolDriver here, for all agent sessions
// ];

final AgentService agentService = AgentService();//globalToolDriverList: globalToolDriverList);

// Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = {
//   /// add openToolDriverMap here, for opentool spec usage
//   OpenToolDto(openToolId: "mock-tool", description: "A Mock CRUD Sample Tools"): MockDriver()
// };

void main(List<String> args) async {
  String dbPath = config.server.dbPath??"agent.db";
  String exeDir = Dir.executableDir();
  String dbFullPath = '$exeDir${Platform.pathSeparator}$dbPath';
  AgentManageService agentManageService = AgentManageServiceByDB(AgentDatabaseFactory.getInstance(File(dbFullPath)));
  
  final AgentController agentController = AgentController(agentService, agentManageService);//, openToolDriverInfoMap: openToolDriverInfoMap);
  final AgentManageController agentManageController = AgentManageController(agentManageService);
  
  apiRoutes(agentController, agentManageController);
  
  final Router mainRouter = Router();
  mainRouter.mount(config.server.apiPathPrefix, apiRouter);
  Handler handler = const Pipeline()
  //.addMiddleware(checkAuthorization("<ADD_YOUR_AUTHORIZATION_HERE>"))
    .addMiddleware(logRequest())
    .addHandler(mainRouter);

  HttpServer server = await serve(handler, config.server.ip, config.server.port);
  logger.log(LogModule.http, "Start Server", detail: "http://${server.address.host}:${server.port}${config.server.apiPathPrefix}");
}