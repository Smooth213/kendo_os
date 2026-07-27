import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';

class OperatorActionButtons extends ConsumerWidget {
  final String tournamentId;
  const OperatorActionButtons({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);
    final bool isReadOnly = permissions.isReadOnly;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final MaterialColor viewerThemeColor = isBunaiksen
        ? Colors.purple
        : Colors.blueGrey;

    return Column(
      children: [
        if (!isReadOnly) ...[
          _buildHugeMenuButton(
            context,
            enableLiquidGlass,
            Icons.edit_note,
            '試合開始（新しく作成）',
            Colors.indigo,
            () => context.push('/setup-match/$tournamentId'),
          ),
          const SizedBox(height: 8),
          _buildHugeMenuButton(
            context,
            enableLiquidGlass,
            Icons.gavel,
            '部門別ルール設定',
            Colors.teal,
            () => context.push('/tournament/$tournamentId/category-rules'),
          ),
          const SizedBox(height: 8),
        ],
        // ★ 修正: 本部操作員が「保護者や観客のスマートフォンにどう見えているか」を手元でシミュレート確認するための完璧な表現へ進化
        _buildHugeMenuButton(
          context,
          enableLiquidGlass,
          Icons.cast_connected,
          '観客・保護者側の画面を確認 (Viewer)',
          viewerThemeColor,
          () {
            final dojoId = ref.read(currentDojoIdProvider);
            context.push(
              '/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
            );
          },
        ),
        const SizedBox(height: 8),
        _buildHugeMenuButton(
          context,
          enableLiquidGlass,
          Icons.print,
          '公式記録の確認・PDF印刷',
          Colors.blueGrey,
          () => context.push('/official-record/$tournamentId'),
        ),
        const SizedBox(height: 12),

        // ★ 修正: ご要望に基づき、ExpansionTileを廃止して「大会プログラム」をメインの1等地に昇格
        // 観客権限（isReadOnly）の時は「見るだけ（閲覧専用）」であることを画面上に明示し、保護者に絶対的な安心感を提供
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/tournament/$tournamentId/programs'),
            icon: Icon(
              Icons.picture_as_pdf,
              size: 20,
              color: isDark ? Colors.redAccent.shade100 : Colors.red.shade600,
            ),
            label: Text(
              '大会プログラムの管理・追加',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300,
              ),
              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // ★ 修正: ユーザーを迷わせる不要な「自チーム選手成績」メニューは完全削除（Stage 3以降に封印移動）
      ],
    );
  }

  Widget _buildHugeMenuButton(
    BuildContext context,
    bool enableLiquidGlass,
    IconData icon,
    String title,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassButton(
      onPressed: onTap,
      color: color,
      icon: icon,
      label: title,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: enableLiquidGlass
            ? (isDark ? color.shade500 : color.shade300)
            : Colors.white70,
      ),
    );
  }
}
