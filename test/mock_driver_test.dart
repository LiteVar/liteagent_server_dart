import 'dart:async';

import 'package:opentool_dart/opentool_client.dart';
import 'package:test/test.dart';

import '../example/mock/driver/mock_driver.dart';

void main() {
  test('mock streaming driver stops emitting after cancellation', () async {
    final openTool = await OpenToolJsonLoader().loadFromFile(
      'example/mock/driver/mock-tool.json',
    );
    final driver = MockDriver(openTool);
    final functionCall = FunctionCall(
      id: 'cancel-stream-call',
      name: 'sequentiallyRead',
      arguments: const {},
    );
    final events = <String>[];

    await driver
        .streamCall(functionCall, (event, _) {
          events.add(event);
          if (event == EventType.DATA) {
            unawaited(driver.cancel(functionCall.id));
          }
        })
        .timeout(const Duration(seconds: 1));

    expect(events, [EventType.DATA]);
  });
}
