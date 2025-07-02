import 'dart:io';
import 'package:opentool_dart/opentool_dart.dart';
import 'dart:convert';

Future<void> main() async {
  String mcpFileName = "example.json";
  File file = File("${Directory.current.path}${Platform.pathSeparator}example${Platform.pathSeparator}mock${Platform.pathSeparator}mcp${Platform.pathSeparator}$mcpFileName");
  String jsonString = await file.readAsString();
  Map<String, dynamic> mcpServers = jsonDecode(jsonString);
  Map<String, dynamic> mcpServer = mcpServers.values.first as Map<String, dynamic>;
  McpStdioDriver mcpStdioDriver = McpStdioDriver.fromOpenMCPString(jsonEncode(mcpServer));
  await mcpStdioDriver.init();

  Map<String, dynamic> args = {
    "text": "test"
  };
  FunctionCall functionCall = FunctionCall(
    id: "callId-2",
    name: "create",
    arguments: args
  );

  try {
    ToolReturn toolReturn = await mcpStdioDriver.call(functionCall);
    print("toolReturn: ${toolReturn.toJson()}");
  } catch (e) {
    print("Error: $e");
  }
}