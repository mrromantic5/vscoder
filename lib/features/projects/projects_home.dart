import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final _fss           = FileSystemService();
  final _searchCtrl    = TextEditingController();
  bool  _searchVisible = false;
  bool  _gridView      = false;
  String _query        = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_searchVisible) _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Consumer<ProjectProvider>(
      builder: (_, pp, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo
                _AppLogo(size: 36),
                const SizedBox(width: 12),
                const Text(
                  'VScoder',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!pp.loading && pp.projects.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pp.projects.length}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                _IconBtn(icon: Icons.search_rounded,   tooltip: 'Search',   onTap: _toggleSearch),
                _IconBtn(icon: Icons.folder_open_outlined, tooltip: 'Open File', onTap: _openDeviceFile),
                _IconBtn(
                  icon: _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  tooltip: _gridView ? 'List View' : 'Grid View',
                  onTap: () => setState(() => _gridView = !_gridView),
                ),
                _SortButton(
                  current: pp.sort,
                  onSelected: pp.setSort,
                ),
                _IconBtn(icon: Icons.settings_outlined, tooltip: 'Settings', onTap: () => Navigator.pushNamed(context, '/settings')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your workspace',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                if (!pp.loading && pp.projects.isNotEmpty)
                  _StatsChip(projects: pp.projects),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search projects…',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2);
  }

  // ── Body ────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Consumer<ProjectProvider>(
      builder: (ctx, pp, _) {
        if (pp.loading) {
          return const _LoadingState();
        }
        if (pp.error != null && pp.projects.isEmpty) {
          return _ErrorState(message: pp.error!, onRetry: pp.loadProjects);
        }
        final filtered = _query.isEmpty
            ? pp.projects
            : pp.projects.where((p) =>
                p.name.toLowerCase().contains(_query) ||
                (p.description?.toLowerCase().contains(_query) ?? false) ||
                p.language.toLowerCase().contains(_query),
              ).toList();

        if (filtered.isEmpty) {
          return _query.isNotEmpty
              ? _NoResultsState(query: _query)
              : _EmptyState(onCreate: _showCreateDialog, onOpenFile: _openDeviceFile);
        }

        return _gridView
            ? _GridList(projects: filtered, onOpen: _openProject, onDelete: _deleteProject, onDuplicate: _duplicateProject, onRename: _renameProject)
            : _ProjectList(projects: filtered, onOpen: _openProject, onDelete: _deleteProject, onDuplicate: _duplicateProject, onRename: _renameProject);
      },
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'open_file',
          backgroundColor: AppColors.surfaceAlt,
          onPressed: _openDeviceFile,
          tooltip: 'Open device file',
          child: const Icon(Icons.folder_open_rounded, color: AppColors.accent, size: 20),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'new_project',
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('New Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          onPressed: _showCreateDialog,
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) { _query = ''; _searchCtrl.clear(); }
    });
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
        backgroundColor: AppColors.surface,
        title: const Text('Delete Project'),
        content: Text('Delete "${project.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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

  Future<void> _duplicateProject(Project project) async {
    await context.read<ProjectProvider>().duplicateProject(project);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${project.name}" duplicated'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _renameProject(Project project) async {
    final ctrl = TextEditingController(text: project.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rename Project'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Project name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Rename')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      await context.read<ProjectProvider>().renameProject(project.id, name);
    }
    ctrl.dispose();
  }

  Future<void> _openDeviceFile() async {
    final perm = await _fss.requestStoragePermission();
    if (!perm) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission required')));
      return;
    }
    final file = await _fss.pickFile();
    if (file == null || !mounted) return;
    context.read<EditorProvider>().openDeviceFile(
      path: file.path, name: file.name,
      language: LanguageDetector.fromFileName(file.name), content: file.content,
    );
    Navigator.pushNamed(context, '/editor');
  }
}

// ── App Logo Widget ─────────────────────────────────────────────────────────
class _AppLogo extends StatelessWidget {
  final double size;
  const _AppLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/logo.png',
        width: size, height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size, height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF58A6FF), Color(0xFF1F6FEB)],
            ),
          ),
          child: Icon(Icons.code_rounded, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

// ── Sort button ─────────────────────────────────────────────────────────────
class _SortButton extends StatelessWidget {
  final ProjectSort current;
  final ValueChanged<ProjectSort> onSelected;
  const _SortButton({required this.current, required this.onSelected});

  String get _label => switch (current) {
    ProjectSort.dateDesc  => 'Newest',
    ProjectSort.dateAsc   => 'Oldest',
    ProjectSort.nameAsc   => 'A→Z',
    ProjectSort.nameDesc  => 'Z→A',
    ProjectSort.language  => 'Lang',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final v = await showMenu<ProjectSort>(
          context: context,
          position: RelativeRect.fromLTRB(1000, 60, 0, 0),
          color: AppColors.surface,
          items: [
            _item(ProjectSort.dateDesc, 'Newest first',   Icons.arrow_downward_rounded),
            _item(ProjectSort.dateAsc,  'Oldest first',   Icons.arrow_upward_rounded),
            _item(ProjectSort.nameAsc,  'Name A→Z',       Icons.sort_by_alpha_rounded),
            _item(ProjectSort.nameDesc, 'Name Z→A',       Icons.sort_by_alpha_rounded),
            _item(ProjectSort.language, 'By language',    Icons.code_rounded),
          ],
        );
        if (v != null) onSelected(v);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(_label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ProjectSort> _item(ProjectSort v, String label, IconData icon) =>
      PopupMenuItem(
        value: v,
        child: Row(
          children: [
            Icon(icon, size: 16, color: current == v ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: current == v ? AppColors.accent : AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      );
}

// ── Stats chip ───────────────────────────────────────────────────────────────
class _StatsChip extends StatelessWidget {
  final List<Project> projects;
  const _StatsChip({required this.projects});

  @override
  Widget build(BuildContext context) {
    final langs = projects.map((p) => p.language).toSet().length;
    return Row(
      children: [
        _Chip(label: '${projects.length} projects', icon: Icons.folder_rounded),
        const SizedBox(width: 6),
        _Chip(label: '$langs lang${langs == 1 ? '' : 's'}', icon: Icons.code_rounded),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text('Loading workspace…', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No projects match "$query"', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onOpenFile;
  const _EmptyState({required this.onCreate, required this.onOpenFile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF58A6FF), Color(0xFF1F6FEB)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF58A6FF).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.code_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('Start Building', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Create a project or open a file\nfrom your device to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('New Project'),
                      onPressed: onCreate,
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Open File'),
                      onPressed: onOpenFile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text('Start with a template',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ..._templates.map((t) => _TemplateCard(template: t, onCreate: onCreate)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  static const _templates = [
    _Template('Web App', 'HTML, CSS & JS starter', Icons.web_rounded, 'html', Color(0xFFE34F26)),
    _Template('JavaScript', 'Node-style JS module', Icons.javascript_rounded, 'javascript', Color(0xFFF7DF1E)),
    _Template('Python', 'Python 3 script', Icons.terminal_rounded, 'python', Color(0xFF3572A5)),
  ];
}

class _Template {
  final String name, desc, language;
  final IconData icon;
  final Color color;
  const _Template(this.name, this.desc, this.icon, this.language, this.color);
}

class _TemplateCard extends StatelessWidget {
  final _Template template;
  final VoidCallback onCreate;
  const _TemplateCard({required this.template, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCreate,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(template.icon, color: template.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(template.desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── List view ────────────────────────────────────────────────────────────────
class _ProjectList extends StatelessWidget {
  final List<Project> projects;
  final ValueChanged<Project> onOpen, onDelete, onDuplicate, onRename;
  const _ProjectList({required this.projects, required this.onOpen, required this.onDelete, required this.onDuplicate, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<ProjectProvider>().loadProjects(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: projects.length,
        itemBuilder: (_, i) => _ProjectCard(
          project: projects[i],
          onOpen: () => onOpen(projects[i]),
          onDelete: () => onDelete(projects[i]),
          onDuplicate: () => onDuplicate(projects[i]),
          onRename: () => onRename(projects[i]),
        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 300.ms).slideY(begin: 0.08),
      ),
    );
  }
}

// ── Grid view ────────────────────────────────────────────────────────────────
class _GridList extends StatelessWidget {
  final List<Project> projects;
  final ValueChanged<Project> onOpen, onDelete, onDuplicate, onRename;
  const _GridList({required this.projects, required this.onOpen, required this.onDelete, required this.onDuplicate, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<ProjectProvider>().loadProjects(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0,
        ),
        itemCount: projects.length,
        itemBuilder: (_, i) => _GridCard(
          project: projects[i],
          onOpen: () => onOpen(projects[i]),
          onDelete: () => onDelete(projects[i]),
          onDuplicate: () => onDuplicate(projects[i]),
          onRename: () => onRename(projects[i]),
        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 300.ms).scale(begin: const Offset(0.92, 0.92)),
      ),
    );
  }
}

// ── Project card (list) ───────────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen, onDelete, onDuplicate, onRename;
  const _ProjectCard({required this.project, required this.onOpen, required this.onDelete, required this.onDuplicate, required this.onRename});

  Color get _color {
    try { return Color(int.parse('FF${project.colorHex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return AppColors.accent; }
  }

  @override
  Widget build(BuildContext context) {
    final lang    = LanguageColors.get(project.language);
    final timeAgo = _timeAgo(project.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          splashColor: _color.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Language badge
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _color.withOpacity(0.25)),
                  ),
                  alignment: Alignment.center,
                  child: Text(lang.icon, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (project.description != null && project.description!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(project.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MiniTag(label: lang.name, color: _color),
                          const SizedBox(width: 6),
                          Text(timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                _ProjectMenu(onOpen: onOpen, onDelete: onDelete, onDuplicate: onDuplicate, onRename: onRename),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid card ─────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen, onDelete, onDuplicate, onRename;
  const _GridCard({required this.project, required this.onOpen, required this.onDelete, required this.onDuplicate, required this.onRename});

  Color get _color {
    try { return Color(int.parse('FF${project.colorHex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return AppColors.accent; }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageColors.get(project.language);
    return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(lang.icon, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    const Spacer(),
                    _ProjectMenu(onOpen: onOpen, onDelete: onDelete, onDuplicate: onDuplicate, onRename: onRename),
                  ],
                ),
                const Spacer(),
                Text(project.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _MiniTag(label: lang.name, color: _color),
                const SizedBox(height: 4),
                Text(_timeAgo(project.updatedAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Project context menu ─────────────────────────────────────────────────────
class _ProjectMenu extends StatelessWidget {
  final VoidCallback onOpen, onDelete, onDuplicate, onRename;
  const _ProjectMenu({required this.onOpen, required this.onDelete, required this.onDuplicate, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
      onSelected: (v) {
        switch (v) {
          case 'open':      onOpen();
          case 'rename':    onRename();
          case 'duplicate': onDuplicate();
          case 'delete':    onDelete();
        }
      },
      itemBuilder: (_) => [
        _menuItem('open',      'Open',      Icons.open_in_new_rounded,     AppColors.textPrimary),
        _menuItem('rename',    'Rename',    Icons.drive_file_rename_outline_rounded, AppColors.textPrimary),
        _menuItem('duplicate', 'Duplicate', Icons.copy_all_rounded,        AppColors.textPrimary),
        const PopupMenuDivider(),
        _menuItem('delete',    'Delete',    Icons.delete_outline_rounded,  AppColors.danger),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon, Color color) =>
      PopupMenuItem(
        value: value,
        height: 38,
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );
}

// ── Mini tag ─────────────────────────────────────────────────────────────────
class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Icon button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34, height: 34,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textSecondary, size: 19),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)   return '${diff.inHours}h ago';
  if (diff.inDays < 7)     return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(dt);
}
