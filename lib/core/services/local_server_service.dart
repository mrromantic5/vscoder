import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class LocalServerService {
  HttpServer? _server;
  int _port = 8080;
  String? _rootPath;

  int get port => _port;
  bool get isRunning => _server != null;
  String get url => 'http://localhost:$_port';

  /// Start serving a directory
  Future<String?> serve(String dirPath) async {
    await stop();
    _rootPath = dirPath;

    // Find a free port starting at 8080
    _port = await _findFreePort(8080);

    try {
      final handler = const Pipeline()
          .addMiddleware(_corsMiddleware())
          .addMiddleware(logRequests())
          .addHandler(
            createStaticHandler(
              dirPath,
              defaultDocument: 'index.html',
              serveFilesOutsidePath: false,
              listDirectories: true,
            ),
          );

      _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, _port);
      _server!.autoCompress = true;
      return url;
    } catch (e) {
      return null;
    }
  }

  /// Serve a single HTML file (creates temp dir)
  Future<String?> serveHtml(String htmlContent, {
    String? cssContent,
    String? jsContent,
  }) async {
    await stop();
    _port = await _findFreePort(8080);

    // Build combined HTML
    final combined = _buildHtml(htmlContent, cssContent, jsContent);

    try {
      final handler = (Request req) {
        return Response.ok(
          combined,
          headers: {
            'Content-Type': 'text/html; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
          },
        );
      };

      _server = await shelf_io.serve(
        const Pipeline().addMiddleware(_corsMiddleware()).addHandler(handler),
        InternetAddress.loopbackIPv4,
        _port,
      );
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<int> _findFreePort(int startPort) async {
    for (var port = startPort; port < startPort + 100; port++) {
      try {
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
        await server.close();
        return port;
      } catch (_) {}
    }
    return startPort;
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  String _buildHtml(String html, String? css, String? js) {
    if (html.contains('<html') || html.contains('<!DOCTYPE')) {
      return html;
    }
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>VScoder Preview</title>
  ${css != null && css.isNotEmpty ? '<style>\n$css\n</style>' : ''}
</head>
<body>
$html
${js != null && js.isNotEmpty ? '<script>\n$js\n</script>' : ''}
</body>
</html>''';
  }
}
