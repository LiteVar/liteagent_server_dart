import 'dart:ffi';
import 'dart:io';
import 'package:liteagent_core/liteagent_service.dart';
import 'package:liteagent_server_dart/liteagent_server_dart.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/open.dart';

void main(List<String> args) async {
  try {
    _configureSqliteLibrary();

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
      String dataDir = Dir.userWritableDataDir();
      dbFullPath = '$dataDir${Platform.pathSeparator}$dbPath';
      stderr.writeln('[agent_server] DB path (user data dir): $dbFullPath');
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
    final sessionRuntimeService = SessionRuntimeService(
      agentService: agentService,
      sessionManageService: sessionManageService,
      messageManageService: messageManageService,
    );

    final agentController = AgentController(
      agentService,
      sessionRuntimeService,
    );

    apiRoutes(agentController);

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

void _configureSqliteLibrary() {
  final exeDir = p.dirname(Platform.resolvedExecutable);

  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () {
      final bundleLibPath = p.normalize(
        p.join(exeDir, '..', 'lib', 'sqlite3.dll'),
      );
      if (File(bundleLibPath).existsSync()) {
        return DynamicLibrary.open(bundleLibPath);
      }
      final sameDirPath = p.join(exeDir, 'sqlite3.dll');
      if (File(sameDirPath).existsSync()) {
        return DynamicLibrary.open(sameDirPath);
      }
      return DynamicLibrary.open('winsqlite3.dll');
    });
  } else if (Platform.isMacOS) {
    open.overrideFor(OperatingSystem.macOS, () {
      final bundleLibPath = p.normalize(
        p.join(exeDir, '..', 'lib', 'libsqlite3.dylib'),
      );
      if (File(bundleLibPath).existsSync()) {
        return DynamicLibrary.open(bundleLibPath);
      }
      final sameDirPath = p.join(exeDir, 'libsqlite3.dylib');
      if (File(sameDirPath).existsSync()) {
        return DynamicLibrary.open(sameDirPath);
      }
      return DynamicLibrary.open('libsqlite3.dylib');
    });
  } else if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      final bundleLibPath = p.normalize(
        p.join(exeDir, '..', 'lib', 'libsqlite3.so'),
      );
      if (File(bundleLibPath).existsSync()) {
        return DynamicLibrary.open(bundleLibPath);
      }
      final sameDirPath = p.join(exeDir, 'libsqlite3.so');
      if (File(sameDirPath).existsSync()) {
        return DynamicLibrary.open(sameDirPath);
      }
      return DynamicLibrary.open('libsqlite3.so');
    });
  }
}
