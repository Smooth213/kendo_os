import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_markdown_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_markdown_loader_service.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 📖 ヘルプ・マニュアル用ボトムシート（全画面化ボタン付き）
class ManualBottomSheet extends ConsumerStatefulWidget {
  final bool isViewerMode;
  final String? initialFilePath;

  const ManualBottomSheet({
    super.key,
    required this.isViewerMode,
    this.initialFilePath,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isViewerMode,
    String? initialFilePath,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
      builder: (context) => ManualBottomSheet(
        isViewerMode: isViewerMode,
        initialFilePath: initialFilePath,
      ),
    );
  }

  @override
  ConsumerState<ManualBottomSheet> createState() => _ManualBottomSheetState();
}

class _ManualBottomSheetState extends ConsumerState<ManualBottomSheet> {
  final ManualMarkdownLoaderService _loader =
      const ManualMarkdownLoaderService();
  late String _currentFilePath;
  final List<String> _history = [];
  String _markdownContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentFilePath =
        widget.initialFilePath ??
        (widget.isViewerMode
            ? 'docs/manuals/faq/viewer_faq.md'
            : 'docs/manuals/manual_index.md');
    _loadContent(_currentFilePath);
  }

  Future<void> _loadContent(String path) async {
    setState(() => _isLoading = true);
    try {
      final content = await _loader.loadMarkdownContent(
        path: path,
        searchQuery: '',
      );
      if (mounted) {
        setState(() {
          _markdownContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _markdownContent =
              '### マニュアルの読み込みに失敗しました\n\n全画面ボタンからPDFまたは詳細マニュアルをご確認ください。';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateTo(String path) {
    _history.add(_currentFilePath);
    _currentFilePath = path;
    _loadContent(path);
  }

  void _popHistory() {
    if (_history.isNotEmpty) {
      _currentFilePath = _history.removeLast();
      _loadContent(_currentFilePath);
    }
  }

  void _openFullScreen() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EmbeddedManualScreen(initialFilePath: _currentFilePath),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final title = widget.isViewerMode ? '観戦ガイド・FAQ' : '操作マニュアル・ヘルプ';

    return DockDraggableSheet(
      backgroundColor: themeColors.scaffoldBackground,
      builder: (context, scrollController) => Column(
        children: [
          DockBottomSheetHeader(
            title: title,
            icon: Icons.help_outline_rounded,
            iconColor: AppKendoColors.teal,
            onFullScreen: _openFullScreen,
            extraActions: _history.isNotEmpty
                ? [
                    IconButton(
                      tooltip: '前のページへ戻る',
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: _popHistory,
                    ),
                  ]
                : null,
          ),
          Expanded(
            child: ManualMarkdownView(
              markdownContent: _markdownContent,
              currentFilePath: _currentFilePath,
              isLoading: _isLoading,
              onLinkTapped: (path) => _navigateTo(path),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: themeColors.cardBackground,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  label: const Text(
                    '全画面で開く（PDF・目次検索・印刷対応）',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppKendoColors.teal,
                    foregroundColor: AppKendoColors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
