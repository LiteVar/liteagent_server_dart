import 'dart:async';

class MockUtil {
  List<String> storage = ["Hello", "World"];

  int count() {
    return storage.length;
  }

  int create(String text) {
    storage.add(text);
    return storage.length - 1;
  }

  String read(int id) {
    return storage[id];
  }

  Future<void> sequentiallyRead(
    void Function(String data) onData, {
    required Future<void> cancellation,
    required bool Function() isCancelled,
  }) async {
    for (final data in storage) {
      if (isCancelled()) return;
      onData(data);
      await Future.any<void>([
        Future<void>.delayed(const Duration(milliseconds: 2000)),
        cancellation,
      ]);
    }
  }

  void update(int id, String text) {
    storage[id] = text;
  }

  void delete(int id) {
    storage.removeAt(id);
  }

  void run() {
    throw Exception("A fatal error to break this tool.");
  }
}
