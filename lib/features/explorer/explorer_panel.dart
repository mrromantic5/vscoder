import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/models/vfile.dart';
import '../../core/services/file_system_service.dart';
import '../../core/services/language_detector.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/language_colors.dart';
import 'new_file_dialog.dart';

class ExplorerPanel extends StatelessWidget {
  const ExplorerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _ExplorerHeader(),
          const Divider(height: 1, color: AppColors.border),
          const Expanded(child: _FileTree()),
        ],
      ),
    );
  }
}

class _ExplorerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProjectProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          const Icon(Icons.folder_open_rounded, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pp.activeProject?.name ?? 'Explorer',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // New file
          _ExplorerBtn(
            icon: Icons.note_add_outlined,
            tooltip: 'New File',
            onTap: () => _showNewFileDialog(context, null),
          ),
          // New folder
          _ExplorerBtn(
            icon: Icons.create_new_folder_outlined,
            tooltip: 'New Folder',
            onTap: () => _showNewDirDialog(context, null),
          ),
          // Open from device
          _ExplorerBtn(
            icon: Icons.folder_open_rounded,
            tooltip: 'Open from Device',
            onTap: () => _openFromDevice(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewFileDialog(BuildContext ctx, String? parentDirId) async {
    final pp = ctx.read<ProjectProvider>();
    if (pp.activeProject == null) return;
    final result = await showDialog<Map<String, String>>(
      context: ctx,
      builder: (_) => const NewFileDialog(),
    );
    if (result == null) return;
    await pp.createFile(
      projectId:   pp.activeProject!.id,
      name:        result['name']!,
      parentDirId: parentDirId,
    );
  }

  Future<void> _showNewDirDialog(BuildContext ctx, String? parentId) async {
    final pp = ctx.read<ProjectProvider>();
    if (pp.activeProject == null) return;
    final name = await _promptName(ctx, 'New Folder');
    if (name == null) return;
    await pp.createDirectory(
      projectId: pp.activeProject!.id,
      name:      name,
      parentId:  parentId,
    );
  }

  Future<String?> _promptName(BuildContext ctx, String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: title.toLowerCase()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFromDevice(BuildContext ctx) async {
    final fss = FileSystemService();
    final perm = await fss.requestStoragePermission();
    if (!perm) return;

    final files = await fss.pickMultipleFiles();
    if (files.isEmpty || !ctx.mounted) return;

    final ep = ctx.read<EditorProvider>();
    for (final f in files) {
      ep.openDeviceFile(
        path:     f.path,
        name:     f.name,
        language: LanguageDetector.fromFileName(f.name),
        content:  f.content,
      );
    }
  }
}

// ── File Tree ─────────────────────────────────────────────────────────────────
class _FileTree extends StatelessWidget {
  const _FileTree();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (ctx, pp, _) {
        if (pp.activeProject == null) {
          return const Center(
            child: Text('No project open',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ..._buildDirChildren(context, pp, null),
          ],
        );
      },
    );
  }

  List<Widget> _buildDirChildren(
      BuildContext ctx, ProjectProvider pp, String? parentId) {
    final dirs  = pp.dirsInParent(parentId);
    final files = pp.filesInDir(parentId);
    return [
      ...dirs.map((d) => _DirTile(dir: d)),
      ...files.map((f) => _FileTile(file: f)),
    ];
  }
}

class _DirTile extends StatefulWidget {
  final VDirectory dir;
  const _DirTile({required this.dir});
  @override
  State<_DirTile> createState() => _DirTileState();
}

class _DirTileState extends State<_DirTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProjectProvider>();
    final children = [
      ...pp.dirsInParent(widget.dir.id),
      ...pp.filesInDir(widget.dir.id),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExplorerRow(
          leading: Icon(
            _expanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          icon: Icon(
            _expanded ? Icons.folder_open_rounded : Icons.folder_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          name: widget.dir.name,
          onTap: () => setState(() => _expanded = !_expanded),
          onDelete: () async {
            await context.read<ProjectProvider>().deleteDirectory(
              widget.dir.id, widget.dir.projectId,
            );
          },
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                ...pp.dirsInParent(widget.dir.id).map((d) => _DirTile(dir: d)),
                ...pp.filesInDir(widget.dir.id).map((f) => _FileTile(file: f)),
              ],
            ),
          ),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  final VFile file;
  const _FileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    final ep   = context.watch<EditorProvider>();
    final spec = LanguageColors.get(file.language);
    final isOpen = ep.tabs.any((t) => t.id == file.id);
    final isActive = ep.activeTab?.id == file.id;

    return _ExplorerRow(
      leading: const SizedBox(width: 16),
      icon: Container(
        width: 16, height: 16,
        alignment: Alignment.center,
        child: Text(
          spec.icon,
          style: TextStyle(color: spec.color, fontSize: 7, fontWeight: FontWeight.w800),
        ),
      ),
      name: file.name,
      isActive: isActive,
      hasUnsaved: ep.isTabDirty(file.id),
      onTap: () {
        context.read<EditorProvider>().openFile(file);
      },
      onDelete: () async {
        context.read<EditorProvider>().closeTabById(file.id);
        await context.read<ProjectProvider>().deleteFile(file.id, file.projectId);
      },
    );
  }
}

class _ExplorerRow extends StatelessWidget {
  final Widget leading;
  final Widget icon;
  final String name;
  final bool isActive;
  final bool hasUnsaved;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ExplorerRow({
    required this.leading,
    required this.icon,
    required this.name,
    this.isActive = false,
    this.hasUnsaved = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete == null ? null : () => _showContextMenu(context),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceHov : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 4),
            icon,
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnsaved)
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ExplorerBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
