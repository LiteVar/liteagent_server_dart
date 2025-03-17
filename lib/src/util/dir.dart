import 'dart:io';

class Dir {
  static String? _executableDir;

  static executableDir() {
    if(_executableDir == null) {
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
}