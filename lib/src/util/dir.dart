import 'dart:io';

class Dir {
  static String? _executableDir;

  static executableDir() {
    if (_executableDir == null) {
      String scriptPath;
      if (Platform.script.scheme == 'file') {
        scriptPath = "${Directory.current.path}${Platform.pathSeparator}bin";
        _executableDir = scriptPath;
      } else {
        scriptPath = Platform.resolvedExecutable;
        _executableDir = File(scriptPath).parent.path;
      }
      return _executableDir;
    }
    return _executableDir;
  }

  /// Returns a user-writable data directory, avoiding read-only install
  /// locations such as Program Files on Windows.
  ///
  /// Resolution order:
  /// 1. HOME / USERPROFILE -> $home/.agentos/data/agent_server
  /// 2. Windows: LOCALAPPDATA -> $LOCALAPPDATA/AgentOS/agent_server
  /// 3. Windows: APPDATA -> $APPDATA/AgentOS/agent_server
  /// 4. Fallback: systemTemp/agentos/data/agent_server
  static String userWritableDataDir() {
    final sep = Platform.pathSeparator;

    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir != null && homeDir.isNotEmpty) {
      return '$homeDir${sep}.agentos${sep}data${sep}agent_server';
    }

    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        return '$localAppData${sep}AgentOS${sep}agent_server';
      }
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return '$appData${sep}AgentOS${sep}agent_server';
      }
    }

    return '${Directory.systemTemp.path}${sep}agentos${sep}data${sep}agent_server';
  }

  /// Returns a user-writable log directory.
  ///
  /// Resolution order:
  /// 1. LOG_DIR environment variable (used as-is)
  /// 2. HOME / USERPROFILE -> $home/.agentos/log/agent_server
  /// 3. Windows: LOCALAPPDATA -> $LOCALAPPDATA/AgentOS/log/agent_server
  /// 4. Windows: APPDATA -> $APPDATA/AgentOS/log/agent_server
  /// 5. Fallback: systemTemp/agentos/log/agent_server
  static String resolveLogDir() {
    final envLogDir = Platform.environment['LOG_DIR'];
    if (envLogDir != null && envLogDir.isNotEmpty) {
      return envLogDir;
    }

    final sep = Platform.pathSeparator;

    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir != null && homeDir.isNotEmpty) {
      return '$homeDir${sep}.agentos${sep}log${sep}agent_server';
    }

    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        return '$localAppData${sep}AgentOS${sep}log${sep}agent_server';
      }
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return '$appData${sep}AgentOS${sep}log${sep}agent_server';
      }
    }

    return '${Directory.systemTemp.path}${sep}agentos${sep}log${sep}agent_server';
  }
}
