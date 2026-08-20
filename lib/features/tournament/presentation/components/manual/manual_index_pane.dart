import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 📖 マニュアル目次・キーワード検索インデックスペイン（純粋UIコンポーネント）
class ManualIndexPane extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<dynamic> indexList;
  final String currentFilePath;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<String> onFileSelected;
  final bool isWideScreen;

  const ManualIndexPane({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.indexList,
    required this.currentFilePath,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onFileSelected,
    this.isWideScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final results = indexList.where((item) {
      if (searchQuery.isEmpty) return true;
      final title = item['title']?.toString().toLowerCase() ?? '';
      final headings = (item['headings'] as List? ?? [])
          .join(' ')
          .toLowerCase();
      final tags = (item['tags'] as List? ?? []).join(' ').toLowerCase();
      return title.contains(searchQuery) ||
          headings.contains(searchQuery) ||
          tags.contains(searchQuery);
    }).toList();

    return SafeArea(
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
        child: Container(
          width: isWideScreen ? 320 : null,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: isDark
                    ? context.appColors.textColor.withValues(alpha: 0.12)
                    : context.appColors.cardBackground.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppTextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'タイトル、見出し、キーワード検索...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            tooltip: '検索をクリアして一覧に戻る',
                            onPressed: onSearchCleared,
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                        : const Color(0xFF000000).withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.small,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                        : const Color(0xFF000000).withValues(alpha: 0.12),
                  ),
                  itemBuilder: (ctx, i) {
                    final path = results[i]['path'] as String? ?? '';
                    final title = results[i]['title'] as String? ?? '無題';
                    final headings = results[i]['headings'] as List? ?? [];
                    final isSelected = path == currentFilePath;
                    return ListTile(
                      dense: true,
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? AppFontWeight.bold
                              : AppFontWeight.regular,
                          color: isSelected ? AppKendoColors.blueAccent : null,
                        ),
                      ),
                      subtitle: searchQuery.isNotEmpty
                          ? Text(
                              headings.take(2).join(' / '),
                              style: const TextStyle(
                                fontSize: AppFontSize.badge,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => onFileSelected(path),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
