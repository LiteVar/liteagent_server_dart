import 'dart:io';
import 'package:logging/logging.dart';
import '../config.dart';
import 'dir.dart';

enum LogModule { http, ws, sse, db }

AgentLogger logger = AgentLogger(config.log.level);

class AgentLogger {
  static final AgentLogger _singleton = AgentLogger._internal();
  static Level _level = Level.INFO;

  factory AgentLogger(Level level) {
    _level = level;
    return _singleton;
  }

  Logger? _logger;
  IOSink? _logSink;

  AgentLogger._internal() {
    _logger = Logger('LiteAgentCoreServerLogger');
    Logger.root.level = _level;
    _initLogFile();

    Logger.root.onRecord.listen((record) {
      final message =
          '${record.level.name}: ${record.time}: PID $pid: ${record.message}';
      print(message);
      _logSink?.writeln(message);
    });
  }

  void _initLogFile() {
    final logDir = Dir.resolveLogDir();
    try {
      final logFile = File('$logDir${Platform.pathSeparator}agent.log');
      logFile.createSync(recursive: true);
      _logSink = logFile.openWrite(mode: FileMode.append);
      return;
    } catch (e) {
      stderr.writeln(
        '[AgentLogger] Failed to create log file in $logDir: $e, falling back to temp directory',
      );
    }

    // Fall back to system temp directory
    final fallbackDir =
        '${Directory.systemTemp.path}${Platform.pathSeparator}agentos${Platform.pathSeparator}log${Platform.pathSeparator}agent_server';
    try {
      final logFile = File('$fallbackDir${Platform.pathSeparator}agent.log');
      logFile.createSync(recursive: true);
      _logSink = logFile.openWrite(mode: FileMode.append);
      stderr.writeln('[AgentLogger] Fell back to temp directory: $fallbackDir');
    } catch (e) {
      stderr.writeln(
        '[AgentLogger] Temp directory also unavailable: $e, logging to console only',
      );
      _logSink = null;
    }
  }

  void log(
    LogModule module,
    String message, {
    String detail = "{}",
    Level level = Level.INFO,
  }) {
    _logger?.log(level, "[${module.name.toUpperCase()}] $message - $detail");
  }
}
