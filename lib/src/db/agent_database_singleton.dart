import 'dart:io';
import 'package:drift/native.dart';

import 'agent_database.dart';

class AgentDatabaseFactory {
  static Map<File?, AgentDatabase> _dbs = {};

  static late final  AgentDatabase _instance;

  static AgentDatabase getInstance(File? dbFile) {
    if(_dbs.containsKey(dbFile)) {
      return _dbs[dbFile]!;
    } else {
      if(dbFile == null) {
        _instance = AgentDatabase(NativeDatabase.memory());
        _dbs[dbFile] = _instance;
        return _instance;
      }
      _instance = AgentDatabase(NativeDatabase(dbFile));
      _dbs[dbFile] = _instance;
      return _instance;
    }
  }

}