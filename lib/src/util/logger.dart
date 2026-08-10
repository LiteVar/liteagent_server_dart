import 'dart:io';
import 'package:logging/logging.dart';
import '../config.dart';
import 'dir.dart';

enum LogModule { http, ws, sse, db }

AgentLogger logger = AgentLogger(config.log.level);

class AgentLogger {
  static final AgentLogger _singleton = AgentLogger._internal();
  static Level _level = Level.INFO;
  static const int _retentionDays = 30;

  factory AgentLogger(Level level) {
    _level = level;
    return _singleton;
  }

  Logger? _logger;
  IOSink? _logSink;
  String? _currentLogDate;
  String? _logDirPath;
  Future<void> _writeChain = Future.value();

  AgentLogger._internal() {
    _logger = Logger('LiteAgentCoreServerLogger');
    Logger.root.level = _level;
    _initLogDir();

    Logger.root.onRecord.listen((record) {
      final message =
          '${record.level.name}: ${record.time}: PID $pid: ${record.message}';
      print(message);
      _writeToFile(message);
    });
  }

  void _initLogDir() {
    _logDirPath = Dir.resolveLogDir();
    try {
      Directory(_logDirPath!).createSync(recursive: true);
      _rotateSinkIfNeeded();
      _cleanOldLogs();
    } catch (e) {
      stderr.writeln(
        '[AgentLogger] Failed to init log dir $_logDirPath: $e, falling back to temp directory',
      );
      _logDirPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}agentos${Platform.pathSeparator}log${Platform.pathSeparator}agent_server';
      try {
        Directory(_logDirPath!).createSync(recursive: true);
        _rotateSinkIfNeeded();
        _cleanOldLogs();
      } catch (e) {
        stderr.writeln(
          '[AgentLogger] Temp directory also unavailable: $e, logging to console only',
        );
        _logDirPath = null;
      }
    }
  }

  void _rotateSinkIfNeeded() {
    if (_logDirPath == null) return;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    if (dateStr != _currentLogDate) {
      _logSink?.flush();
      _logSink?.close();
      final logFile = File(
        '$_logDirPath${Platform.pathSeparator}agent_server_$dateStr.log',
      );
      logFile.createSync(recursive: true);
      _logSink = logFile.openWrite(mode: FileMode.append);
      _currentLogDate = dateStr;
    }
  }

  void _writeToFile(String logLine) {
    if (_logDirPath == null) return;
    _writeChain = _writeChain.then((_) async {
      _rotateSinkIfNeeded();
      _logSink?.writeln(logLine);
    }).catchError((Object error, StackTrace stackTrace) {
      stderr.writeln('[AgentLogger] File logging failed: $error');
    });
  }

  void _cleanOldLogs() {
    if (_logDirPath == null) return;
    try {
      final dir = Directory(_logDirPath!);
      if (!dir.existsSync()) return;
      final cutoff = DateTime.now().subtract(Duration(days: _retentionDays));
      final logFilePattern = RegExp(r'agent_server_(\d{4}-\d{2}-\d{2})\.log$');
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final match = logFilePattern.firstMatch(entity.path);
        if (match == null) continue;
        final dateStr = match.group(1)!;
        final fileDate = DateTime.tryParse(dateStr);
        if (fileDate != null && fileDate.isBefore(cutoff)) {
          entity.deleteSync();
        }
      }
    } catch (_) {}
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
