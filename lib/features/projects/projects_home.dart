import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/models/project.dart';
import '../../core/services/file_system_service.dart';
import '../../core/services/language_detector.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/language_colors.dart';
import 'new_project_dialog.dart';

class ProjectsHome extends StatefulWidget {
  const ProjectsHome({super.key});
  @override
  State<ProjectsHome> createState() => _ProjectsHomeState();
}

class _ProjectsHomeState extends State<ProjectsHome> {
  final _fss = FileSystemService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
                  ),
                ),
                child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'VScoder',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // Open device file
              _HeaderBtn(
                icon: Icons.folder_open_outlined,
                tooltip: 'Open File',
                onTap: _openDeviceFile,
              ),
              const SizedBox(width: 4),
              _HeaderBtn(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Projects',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your workspace',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ProjectProvider>(
      builder: (ctx, pp, _) {
        if (pp.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        if (pp.projects.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: pp.loadProjects,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: pp.projects.length,
            itemBuilder: (_, i) => _ProjectCard(
              project: pp.projects[i],
              onOpen: () => _openProject(pp.projects[i]),
              onDelete: () => _deleteProject(pp.projects[i]),
            ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.1),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.folder_open_rounded,
                color: AppColors.textMuted, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Projects Yet',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first project or open a file\nfrom your device to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Project'),
            onPressed: _showCreateDialog,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Open device file FAB
        FloatingActionButton.small(
          heroTag: 'open_file',
          backgroundColor: AppColors.surfaceAlt,
          onPressed: _openDeviceFile,
          child: const Icon(Icons.folder_open_rounded, color: AppColors.accent, size: 20),
        ),
        const SizedBox(height: 12),
        // New project FAB
        FloatingActionButton.extended(
          heroTag: 'new_project',
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('New Project',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          onPressed: _showCreateDialog,
        ),
      ],
    );
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const NewProjectDialog(),
    );
    if (result == null || !mounted) return;
    final pp = context.read<ProjectProvider>();
    await pp.createProject(
      name: result['name']!,
      description: result['description'],
      language: result['language'] ?? 'javascript',
    );
  }

  Future<void> _openProject(Project project) async {
    final pp = context.read<ProjectProvider>();
    await pp.setActiveProject(project);
    if (mounted) Navigator.pushNamed(context, '/editor');
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Delete "${project.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ProjectProvider>().deleteProject(project.id);
    }
  }

  Future<void> _openDeviceFile() async {
    final perm = await _fss.requestStoragePermission();
    if (!perm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required')),
        );
      }
      return;
    }
    final file = await _fss.pickFile();
    if (file == null || !mounted) return;

    final ep = context.read<EditorProvider>();
    ep.openDeviceFile(
      path:     file.path,
      name:     file.name,
      language: LanguageDetector.fromFileName(file.name),
      content:  file.content,
    );
    Navigator.pushNamed(context, '/editor');
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onDelete,
  });

  Color get _color {
    try {
      return Color(int.parse('FF${project.colorHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageColors.get(project.language);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.accent.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Language icon
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _color.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lang.icon,
                      style: TextStyle(
                        color: _color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project.description != null && project.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            project.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lang.name,
                            style: TextStyle(
                              color: _color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textMuted, size: 20),
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                      if (v == 'open') onOpen();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'open', child: Text('Open')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}
