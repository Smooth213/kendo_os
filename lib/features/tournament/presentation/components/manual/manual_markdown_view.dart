import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:documentation_runtime/manual_routes.dart';

/// 📖 マニュアルMarkdownレンダリングビュー（純粋UIコンポーネント）
class ManualMarkdownView extends StatelessWidget {
  final String markdownContent;
  final String currentFilePath;
  final bool isLoading;
  final ValueChanged<String> onLinkTapped;

  const ManualMarkdownView({
    super.key,
    required this.markdownContent,
    required this.currentFilePath,
    required this.isLoading,
    required this.onLinkTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return md.Markdown(
      data: markdownContent,
      selectable: false,
      onTapLink: (text, href, title) {
        if (href == null || href.startsWith('http') || href.startsWith('#')) {
          return;
        }

        if (href.startsWith('manual://')) {
          final id = href.replaceFirst('manual://', '');
          final route = ManualRoute.fromId(id);
          if (route != null) {
            onLinkTapped(route.path);
            return;
          }
        }

        final dirSegments = currentFilePath.split('/');
        dirSegments.removeLast();

        final hrefSegments = href.split('/');
        for (final segment in hrefSegments) {
          if (segment == '.') continue;
          if (segment == '..') {
            if (dirSegments.isNotEmpty) dirSegments.removeLast();
          } else {
            final fileOnly = segment.split('#').first;
            if (fileOnly.isNotEmpty) {
              dirSegments.add(fileOnly);
            }
          }
        }

        final targetPath = dirSegments.join('/');
        onLinkTapped(targetPath);
      },
      styleSheet: md.MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: AppFontSize.hero,
          fontWeight: AppFontWeight.bold,
          color: AppKendoColors.blueAccent,
        ),
        h2: const TextStyle(
          fontSize: AppFontSize.titleLarge,
          fontWeight: AppFontWeight.bold,
          color: AppKendoColors.teal,
          decoration: TextDecoration.underline,
        ),
        p: const TextStyle(fontSize: AppFontSize.subhead, height: 1.7),
        code: TextStyle(
          backgroundColor: isDark
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
              : const Color(0xFF000000).withValues(alpha: 0.12),
        ),
        a: const TextStyle(
          color: AppKendoColors.blueAccent,
          decoration: TextDecoration.underline,
        ),
        em: TextStyle(
          backgroundColor: AppKendoColors.yellow.withValues(alpha: 0.5),
          color: context.appColors.textColor,
          fontStyle: FontStyle.normal,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}
