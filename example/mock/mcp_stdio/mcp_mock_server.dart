import 'package:mcp_dart/mcp_dart.dart';

import 'mock_util.dart';

void main() async {
  MockUtil mockUtil = MockUtil();

  final server = McpServer(
    Implementation(name: 'Mock CRUD Server', version: '1.0.0'),
    options: McpServerOptions(
      capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
    ),
  );

  server.registerTool(
    'count',
    description: 'Get storage size.',
    inputSchema: const JsonObject(properties: {}, additionalProperties: false),
    callback: (args, extra) async {
      int count = mockUtil.count();
      return CallToolResult.fromStructuredContent({"count": count});
    },
  );

  server.registerTool(
    'create',
    description: 'Create a text in storage',
    inputSchema: const JsonObject(
      properties: {"text": JsonString()},
      required: ["text"],
      additionalProperties: false,
    ),
    callback: (args, extra) async {
      String text = args['text'] as String;
      int id = mockUtil.create(text);
      return CallToolResult.fromStructuredContent({"id": id});
    },
  );

  server.registerTool(
    'read',
    description: 'Read text from storage by id',
    inputSchema: const JsonObject(
      properties: {"id": JsonInteger()},
      required: ["id"],
      additionalProperties: false,
    ),
    callback: (args, extra) async {
      int id = args["id"] as int;
      String text = mockUtil.read(id);
      return CallToolResult.fromStructuredContent({"text": text});
    },
  );

  server.registerTool(
    'update',
    description: 'Update a text in storage by id',
    inputSchema: const JsonObject(
      properties: {"id": JsonInteger(), "text": JsonString()},
      required: ["id", "text"],
      additionalProperties: false,
    ),
    callback: (args, extra) async {
      int id = args['id'] as int;
      String text = args['text'] as String;
      mockUtil.update(id, text);
      return CallToolResult.fromStructuredContent({
        "result": "Update successfully.",
      });
    },
  );

  server.registerTool(
    'delete',
    description: 'Delete a text in storage',
    inputSchema: const JsonObject(
      properties: {"id": JsonInteger()},
      required: ["id"],
      additionalProperties: false,
    ),
    callback: (args, extra) async {
      int id = args['id'] as int;
      mockUtil.delete(id);
      return CallToolResult.fromStructuredContent({
        "result": "Delete successfully.",
      });
    },
  );

  server.connect(StdioServerTransport());
}
