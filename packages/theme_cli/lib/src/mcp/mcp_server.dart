import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Protocol versions this server speaks, newest first.
const supportedProtocolVersions = ['2025-06-18', '2025-03-26', '2024-11-05'];

/// An image a tool returns next to its text.
class ToolImage {
  const ToolImage(this.bytes, {this.mimeType = 'image/png'});

  final Uint8List bytes;
  final String mimeType;
}

class ToolResult {
  const ToolResult(this.text, {this.images = const [], this.isError = false});

  final String text;
  final List<ToolImage> images;

  /// The call ran but did not succeed; the model should read [text] and react.
  final bool isError;

  Map<String, Object?> toJson() => {
    'content': [
      {'type': 'text', 'text': text},
      for (final i in images)
        {
          'type': 'image',
          'data': base64Encode(i.bytes),
          'mimeType': i.mimeType,
        },
    ],
    if (isError) 'isError': true,
  };
}

/// Bad arguments from the model; reported as an error result it can act on.
class ToolException implements Exception {
  const ToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef ProgressReporter = void Function(num done, num total, String message);

class McpTool {
  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
    this.readOnly = false,
  });

  final String name;
  final String description;
  final Map<String, Object?> inputSchema;
  final bool readOnly;
  final Future<ToolResult> Function(
    Map<String, dynamic> args,
    ProgressReporter progress,
  )
  handler;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
    'annotations': {'readOnlyHint': readOnly},
  };
}

/// A Model Context Protocol server over newline-delimited JSON-RPC, exposing
/// tools only.
class McpServer {
  McpServer({
    required this.name,
    required this.version,
    required this.tools,
    this.instructions,
    this.log,
  });

  final String name;
  final String version;
  final String? instructions;
  final List<McpTool> tools;

  /// Diagnostics; must not write to stdout, which carries the protocol.
  final void Function(String message)? log;

  /// Reads one JSON message per line from [lines] and passes every reply to
  /// [send]. Finishes once the input ends and the open requests are answered.
  Future<void> serve(
    Stream<String> lines,
    void Function(Map<String, Object?> message) send,
  ) async {
    final open = <Future<void>>[];
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final Object? message;
      try {
        message = jsonDecode(line);
      } on FormatException catch (e) {
        send(_error(null, -32700, 'Parse error: ${e.message}'));
        continue;
      }
      open.add(_dispatch(message, send));
    }
    await Future.wait(open);
  }

  Future<void> _dispatch(
    Object? message,
    void Function(Map<String, Object?>) send,
  ) async {
    if (message is! Map || message['jsonrpc'] != '2.0') {
      send(_error(null, -32600, 'Invalid request'));
      return;
    }
    final method = message['method'];
    final id = message['id'];
    // Replies to requests we never made, and notifications, get no answer.
    if (method is! String || id == null) return;

    final params = message['params'];
    try {
      final result = await _call(
        method,
        params is Map ? params.cast<String, dynamic>() : const {},
        send,
      );
      send({'jsonrpc': '2.0', 'id': id, 'result': result});
    } on _RpcError catch (e) {
      send(_error(id, e.code, e.message));
    } catch (e, stack) {
      log?.call('Internal error in $method: $e\n$stack');
      send(_error(id, -32603, 'Internal error: $e'));
    }
  }

  Future<Object?> _call(
    String method,
    Map<String, dynamic> params,
    void Function(Map<String, Object?>) send,
  ) async {
    switch (method) {
      case 'initialize':
        final asked = params['protocolVersion'];
        return {
          'protocolVersion': supportedProtocolVersions.contains(asked)
              ? asked
              : supportedProtocolVersions.first,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': name, 'version': version},
          if (instructions != null) 'instructions': instructions,
        };
      case 'ping':
        return <String, Object?>{};
      case 'tools/list':
        return {
          'tools': [for (final t in tools) t.toJson()],
        };
      case 'tools/call':
        return _callTool(params, send);
    }
    throw _RpcError(-32601, 'Method not found: $method');
  }

  Future<Object?> _callTool(
    Map<String, dynamic> params,
    void Function(Map<String, Object?>) send,
  ) async {
    final name = params['name'];
    final tool = tools.where((t) => t.name == name).firstOrNull;
    if (tool == null) throw _RpcError(-32602, 'Unknown tool: $name');
    final args = params['arguments'] ?? <String, dynamic>{};
    if (args is! Map) {
      throw _RpcError(-32602, 'arguments must be an object');
    }

    final meta = params['_meta'];
    final token = meta is Map ? meta['progressToken'] : null;
    void progress(num done, num total, String message) {
      if (token == null) return;
      send({
        'jsonrpc': '2.0',
        'method': 'notifications/progress',
        'params': {
          'progressToken': token,
          'progress': done,
          'total': total,
          'message': message,
        },
      });
    }

    try {
      return (await tool.handler(
        args.cast<String, dynamic>(),
        progress,
      )).toJson();
    } on ToolException catch (e) {
      return ToolResult(e.message, isError: true).toJson();
    } catch (e, stack) {
      log?.call('Tool ${tool.name} failed: $e\n$stack');
      return ToolResult('${tool.name} failed: $e', isError: true).toJson();
    }
  }

  static Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}

class _RpcError implements Exception {
  _RpcError(this.code, this.message);

  final int code;
  final String message;
}
