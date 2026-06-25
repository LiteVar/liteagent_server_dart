import 'dart:io';
import 'package:logging/logging.dart';
import '../config.dart';

enum LogModule { http, ws, sse }

AgentLogger logger = AgentLogger(config.log.level);

class AgentLogger {
  static final AgentLogger _singleton = AgentLogger._internal();
  static Level _level = Level.INFO;

  factory AgentLogger(Level level) {
    _level = level;
    return _singleton;
  }

  Logger? _logger;
  late IOSink _logSink;

  AgentLogger._internal() {
    _logger = Logger('LiteAgentCoreServerLogger');
    Logger.root.level = _level;
    final logDir = Platform.environment['LOG_DIR'] ?? 
        '${Directory.current.path}${Platform.pathSeparator}log';
    final logFile = File('$logDir${Platform.pathSeparator}agent.log');
    logFile.createSync(recursive: true);
    _logSink = logFile.openWrite(mode: FileMode.append);

    Logger.root.onRecord.listen((record) {
      final message =
          '${record.level.name}: ${record.time}: PID $pid: ${record.message}';
      print(message);
      _logSink.writeln(message);
    });
  }

  void log(LogModule module, String message, {String detail = "{}", Level level = Level.INFO}) {
    _logger?.log(level, "[${module.name.toUpperCase()}] $message - $detail");
  }
}
