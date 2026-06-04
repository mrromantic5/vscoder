import 'dart:io';
import 'dart:convert';

enum ExecutionType { webView, localServer, process, unsupported }

class ExecutionResult {
  final bool success;
  final String? output;
  final String? error;
  final ExecutionType type;
  final String? serverUrl;

  const ExecutionResult({
    required this.success,
    this.output,
    this.error,
    required this.type,
    this.serverUrl,
  });
}

class ExecutionEngine {
  static ExecutionType typeFor(String language) {
    switch (language.toLowerCase()) {
      case 'html':
      case 'jsx':
      case 'tsx':
      case 'css':
      case 'scss':
      case 'sass':
      case 'markdown':
      case 'md':
      case 'javascript':
      case 'js':
      case 'typescript':
      case 'ts':
      case 'json':
      case 'xml':
        return ExecutionType.webView;
      default:
        return ExecutionType.unsupported;
    }
  }

  static Future<ExecutionResult> runProcess(
    String executable,
    List<String> args, {
    String? workingDir,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final process = await Process.start(
        executable, args,
        workingDirectory: workingDir,
        runInShell: true,
      );

      final outputBuf = StringBuffer();
      final errorBuf  = StringBuffer();

      process.stdout.transform(utf8.decoder).listen(outputBuf.write);
      process.stderr.transform(utf8.decoder).listen(errorBuf.write);

      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () { process.kill(); return -1; },
      );

      return ExecutionResult(
        success: exitCode == 0,
        output:  outputBuf.toString(),
        error:   errorBuf.isNotEmpty ? errorBuf.toString() : null,
        type:    ExecutionType.process,
      );
    } on ProcessException catch (e) {
      return ExecutionResult(
        success: false,
        error:   'Process error: ${e.message}',
        type:    ExecutionType.process,
      );
    } catch (e) {
      return ExecutionResult(
        success: false, error: e.toString(), type: ExecutionType.process,
      );
    }
  }

  static String buildRunnerJs(String language, String content) {
    final lang = language.toLowerCase();
    switch (lang) {
      case 'javascript':
      case 'js':
        return 'try { window.vsRunner.run("", "", ${_jsEsc(content)}); } '
            'catch(e) { window.flutter_inappwebview?.callHandler("onRunnerLog","error",e.toString()); }';
      case 'html':
        return 'window.vsRunner.runHtml(${_jsEsc(content)});';
      case 'css':
        return 'window.vsRunner.run("", ${_jsEsc(content)}, "");';
      case 'json':
        return r'''
          try {
            const obj = JSON.parse(''' + _jsEsc(content) + r''');
            document.getElementById("vs-user-root").innerHTML =
              "<pre style='font-family:monospace;color:#E6EDF3;background:#0D1117;padding:16px;font-size:13px'>"
              + JSON.stringify(obj, null, 2) + "</pre>";
            document.body.style.background="#0D1117";
          } catch(e) {
            window.flutter_inappwebview?.callHandler("onRunnerLog","error","JSON Error: "+e.message);
          }''';
      case 'markdown':
      case 'md':
        return '''
          (function(){
            var md = ${_jsEsc(content)};
            var h = md
              .replace(/^### (.*$)/gim,"<h3>\$1</h3>")
              .replace(/^## (.*$)/gim,"<h2>\$1</h2>")
              .replace(/^# (.*$)/gim,"<h1>\$1</h1>")
              .replace(/\\*\\*(.+?)\\*\\*/g,"<strong>\$1</strong>")
              .replace(/\\*(.+?)\\*/g,"<em>\$1</em>")
              .replace(/`([^`]+)`/g,"<code style='background:#161B22;padding:2px 6px;border-radius:4px'>\$1</code>")
              .replace(/^- (.+)/gm,"<li>\$1</li>")
              .replace(/\\n/g,"<br>");
            document.getElementById("vs-user-root").innerHTML =
              "<div style='font-family:system-ui;color:#E6EDF3;background:#0D1117;padding:24px;max-width:800px;margin:0 auto;line-height:1.7'>" + h + "</div>";
            document.body.style.background="#0D1117";
          })();''';
      default:
        return 'window.flutter_inappwebview?.callHandler("onRunnerLog","warn",'
            '"Direct execution not supported for $language. Use Terminal for compiled languages.");';
    }
  }

  static String _jsEsc(String s) {
    final esc = s
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$');
    return '`$esc`';
  }
}
