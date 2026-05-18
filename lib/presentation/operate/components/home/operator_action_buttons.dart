import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/permission_provider.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../providers/settings_provider.dart';

class OperatorActionButtons extends ConsumerWidget {
  final String tournamentId;
  const OperatorActionButtons({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (!permissions.isReadOnly) ...[
          _buildHugeMenuButton(context, enableLiquidGlass, Icons.edit_note, '試合を作成', Colors.indigo, () => context.push('/setup-match/$tournamentId')),
          const SizedBox(height: 8),
        ],
        _buildHugeMenuButton(context, enableLiquidGlass, Icons.cast_connected, '観客席スクリーン (Viewer)', Colors.teal, () => context.push('/viewer-home/$tournamentId?role=viewer')),
        const SizedBox(height: 8),
        _buildHugeMenuButton(context, enableLiquidGlass, Icons.print, 'スコアの出力・印刷', Colors.blueGrey, () => context.push('/official-record/$tournamentId')),
        const SizedBox(height: 16),
        
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text('⚙️ 高度な管理メニュー', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            children: [
              Container(
                width: double.infinity, height: 50, margin: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/tournament/$tournamentId/programs'),
                  icon: Icon(Icons.picture_as_pdf, size: 20, color: isDark ? Colors.redAccent.shade100 : Colors.red.shade600),
                  label: Text(permissions.isReadOnly ? '大会プログラムを見る' : '大会プログラムの管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.grey.shade800)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300), backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              if (!permissions.isReadOnly)
                Container(
                  width: double.infinity, height: 50, margin: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/standings/$tournamentId'),
                    icon: Icon(Icons.military_tech, size: 20, color: Colors.amber.shade600),
                    label: Text('自チーム選手成績', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.grey.shade800)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300), backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHugeMenuButton(BuildContext context, bool enableLiquidGlass, IconData icon, String title, MaterialColor color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassButton(
      onPressed: onTap,
      color: color,
      icon: icon,
      label: title,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: enableLiquidGlass ? (isDark ? color.shade500 : color.shade300) : Colors.white70),
    );
  }
}