import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileSystemService {
  // ── Permissions ───────────────────────────────────────────────────
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      // Fallback to basic read/write
      final r = await Permission.storage.request();
      return r.isGranted;
    }
    return true;
  }

  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      return await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted;
    }
    return true;
  }

  // ── Open file picker ─────────────────────────────────────────────
  Future<OpenFileResult?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return null;

    try {
      final content = await File(path).readAsString();
      return OpenFileResult(
        path: path,
        name: file.name,
        content: content,
      );
    } catch (e) {
      // Binary file — can't edit
      return null;
    }
  }

  /// Pick multiple files
  Future<List<OpenFileResult>> pickMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result == null) return [];

    final files = <OpenFileResult>[];
    for (final f in result.files) {
      if (f.path == null) continue;
      try {
        final content = await File(f.path!).readAsString();
        files.add(OpenFileResult(path: f.path!, name: f.name, content: content));
      } catch (_) {}
    }
    return files;
  }

  // ── Read a file by path ──────────────────────────────────────────
  Future<String?> readFile(String path) async {
    try {
      return await File(path).readAsString();
    } catch (e) {
      return null;
    }
  }

  // ── Write / save a file ──────────────────────────────────────────
  Future<bool> writeFile(String path, String content) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content, flush: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Save to a new file via picker ────────────────────────────────
  Future<String?> saveAs(String fileName, String content) async {
    try {
      // On Android, we save to the Downloads folder or Documents
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final path = '${dir.path}/$fileName';
      final success = await writeFile(path, content);
      return success ? path : null;
    } catch (e) {
      return null;
    }
  }

  // ── App internal storage ─────────────────────────────────────────
  Future<Directory> getAppStorageDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final vsDir = Directory('${dir.path}/VScoder');
    await vsDir.create(recursive: true);
    return vsDir;
  }

  Future<bool> fileExists(String path) => File(path).exists();

  Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}

class OpenFileResult {
  final String path;
  final String name;
  final String content;
  OpenFileResult({
    required this.path,
    required this.name,
    required this.content,
  });
}
