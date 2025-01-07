import 'dart:io';
import 'package:lite_agent_core_dart/lite_agent_core.dart';
import 'package:lite_agent_core_dart_server/lite_agent_core_dart_server.dart';
import 'package:opentool_dart/opentool_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import '../example/mock/driver/mock_driver.dart';

List<ToolDriver> globalToolDriverList = [
  /// add GlobalToolDriver here, for all agent sessions
];

final AgentService agentService = AgentService(globalToolDriverList: globalToolDriverList);

Map<OpenToolDto, OpenToolDriver> openToolDriverInfoMap = {
  /// add openToolDriverMap here, for opentool spec usage
  OpenToolDto(openToolId: "mock-tool", description: "A Mock CRUD Sample Tools"): MockDriver()
};

final AgentController agentController = AgentController(agentService, openToolDriverInfoMap: openToolDriverInfoMap);

void main(List<String> args) async {
  apiRoutes(agentController);
  final Router mainRouter = Router();
  mainRouter.mount(config.server.apiPathPrefix, apiRouter);
  Handler handler = const Pipeline()
  //.addMiddleware(checkAuthorization("<ADD_YOUR_AUTHORIZATION_HERE>"))
    .addMiddleware(logRequest())
    .addHandler(mainRouter);

  HttpServer server = await serve(handler, config.server.ip, config.server.port);
  logger.log(LogModule.http, "Start Server", detail: "http://${server.address.host}:${server.port}${config.server.apiPathPrefix}");
}