import 'package:flutter/material.dart';

/// 🔍 マニュアル検索AppBarアクションボタン群（純粋UIコンポーネント）
class ManualSearchAppBarActions extends StatelessWidget {
  final bool showSearch;
  final bool isSearching;
  final bool isPdfMode;
  final String searchQuery;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final VoidCallback onClearPressed;
  final VoidCallback onStartSearchPressed;

  const ManualSearchAppBarActions({
    super.key,
    required this.showSearch,
    required this.isSearching,
    required this.isPdfMode,
    required this.searchQuery,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onClearPressed,
    required this.onStartSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!showSearch) return const SizedBox.shrink();

    if (!isSearching) {
      return IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'マニュアル内を検索',
        onPressed: onStartSearchPressed,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPdfMode && searchQuery.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.navigate_before),
            tooltip: '前へ',
            onPressed: onPreviousPressed,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: '次へ',
            onPressed: onNextPressed,
          ),
        ],
        if (searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'テキストをクリア',
            onPressed: onClearPressed,
          ),
      ],
    );
  }
}
