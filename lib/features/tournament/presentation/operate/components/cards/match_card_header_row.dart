import 'package:flutter/material.dart';

/// 試合カード最上部のヘッダー行（アクションボタングループ ＋ ステータスバッジ）を描画する純粋UIコンポーネント
class MatchCardHeaderRow extends StatelessWidget {
  final Widget actionButtons;
  final Widget statusBadge;
  final Widget? leading;

  const MatchCardHeaderRow({
    super.key,
    required this.actionButtons,
    required this.statusBadge,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [?leading, const Spacer(), actionButtons, statusBadge],
    );
  }
}
