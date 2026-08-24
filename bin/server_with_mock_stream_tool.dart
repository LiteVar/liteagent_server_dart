import 'dart:io';

import 'package:liteagent_core_dart/liteagent_core.dart';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import 'package:opentool_dart/opentool_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../example/mock/driver/mock_driver.dart';

/// Development entrypoint that registers a local mock OpenTool driver
/// (including a `stream` function: `sequentiallyRead`) so you can test
/// ToolDriver.streamCall through the HTTP/SSE server.
///
/// Run:
/// - `dart run bin/server_with_mock_stream_tool.dart`
/// Then:
/// - `dart run example/stream_call_example.dart`
Future<void> main(List<String> args) async {
  final toolDrivers = await _buildMockToolDrivers();

  final dbPath = config.server.dbPath ?? "agent.db";
  final exeDir = Dir.executableDir();
  final dbFullPath = '$exeDir${Platform.pathSeparator}$dbPath';
  final database = AgentDatabaseFactory.getInstance(File(dbFullPath));
  final messageManageService = SessionMessageManageServiceByDB(database);
  final sessionManageService = SessionManageServiceByDB(database);
  final agentService = AgentService(
    globalToolDriverList: toolDrivers,
    messageManageServiceList: [messageManageService],
  );
  final sessionRuntimeService = SessionRuntimeService(
    agentService: agentService,
    sessionManageService: sessionManageService,
    messageManageService: messageManageService,
  );

  final agentController = AgentController(agentService, sessionRuntimeService);

  apiRoutes(agentController);

  final mainRouter = Router();
  mainRouter.mount(config.server.apiPathPrefix, apiRouter);
  final handler = const Pipeline()
      // .addMiddleware(checkAuthorization("<ADD_YOUR_AUTHORIZATION_HERE>"))
      .addMiddleware(logRequest())
      .addHandler(mainRouter);

  final server = await serve(handler, config.server.ip, config.server.port);
  logger.log(
    LogModule.http,
    "Start Server (mock stream tool enabled)",
    detail:
        "http://${server.address.host}:${server.port}${config.server.apiPathPrefix}",
  );
}

Future<List<ToolDriver>> _buildMockToolDrivers() async {
  final jsonPath = [
    Directory.current.path,
    'example',
    'mock',
    'driver',
    'mock-tool.json',
  ].join(Platform.pathSeparator);

  final openTool = await OpenToolJsonLoader().loadFromFile(jsonPath);
  return [MockDriver(openTool)];
}
