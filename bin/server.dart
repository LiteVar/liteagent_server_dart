import 'dart:io';
import 'package:liteagent_core_dart/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  try {
    stderr.writeln('[agent_server] Starting...');
    stderr.writeln('[agent_server] CWD: ${Directory.current.path}');
    stderr.writeln('[agent_server] Executable: ${Platform.resolvedExecutable}');

    String dbFullPath;
    final envDbPath = Platform.environment['DB_PATH'];
    if (envDbPath != null && envDbPath.isNotEmpty) {
      dbFullPath = envDbPath;
      stderr.writeln('[agent_server] DB path (from env): $dbFullPath');
    } else {
      String dbPath = config.server.dbPath ?? "agent.db";
      String exeDir = Dir.executableDir();
      dbFullPath = '$exeDir${Platform.pathSeparator}$dbPath';
      stderr.writeln('[agent_server] DB path (from config): $dbFullPath');
    }

    final dbDir = File(dbFullPath).parent;
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
      stderr.writeln('[agent_server] Created DB directory: ${dbDir.path}');
    }

    final database = AgentDatabaseFactory.getInstance(File(dbFullPath));
    final messageManageService = SessionMessageManageServiceByDB(database);
    final sessionManageService = SessionManageServiceByDB(database);
    final agentService = AgentService(
      messageManageServiceList: [messageManageService],
    );
    final agentManageService = AgentManageServiceByDB(database);
    final sessionRuntimeService = SessionRuntimeService(
      agentService: agentService,
      sessionManageService: sessionManageService,
      messageManageService: messageManageService,
    );

    final agentController = AgentController(
      agentService,
      agentManageService,
      sessionRuntimeService,
    );
    final agentManageController = AgentManageController(agentManageService);

    apiRoutes(agentController, agentManageController);

    final Router mainRouter = Router();
    mainRouter.mount(config.server.apiPathPrefix, apiRouter);
    Handler handler = const Pipeline()
        //.addMiddleware(checkAuthorization("<ADD_YOUR_AUTHORIZATION_HERE>"))
        .addMiddleware(logRequest())
        .addHandler(mainRouter);

    HttpServer server = await serve(
      handler,
      config.server.ip,
      config.server.port,
    );
    logger.log(
      LogModule.http,
      "Start Server",
      detail:
          "http://${server.address.host}:${server.port}${config.server.apiPathPrefix}",
    );
  } catch (e, stackTrace) {
    stderr.writeln('[agent_server] FATAL: $e');
    stderr.writeln('[agent_server] StackTrace: $stackTrace');
    exit(1);
  }
}
