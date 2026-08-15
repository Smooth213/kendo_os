import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合画面における操作履歴一覧と取り消し（巻き戻し）ダイアログ（純粋UIコンポーネント）
class MatchSnapshotHistoryDialog extends StatelessWidget {
  final List<ScoreEvent> validEvents;
  final bool isDark;
  final void Function(int targetVersion, int eventIndex) onSelectRewind;
  final VoidCallback onClose;

  const MatchSnapshotHistoryDialog({
    super.key,
    required this.validEvents,
    required this.isDark,
    required this.onSelectRewind,
    required this.onClose,
  });

  String _formatPointType(PointType type) {
    switch (type) {
      case PointType.men:
        return 'メン';
      case PointType.kote:
        return 'コテ';
      case PointType.doIdo:
        return 'ドウ';
      case PointType.tsuki:
        return 'ツキ';
      case PointType.hansoku:
        return '反則(▲)';
      case PointType.fusen:
        return '不戦勝';
      case PointType.hantei:
        return '判定';
      default:
        return 'ポイント';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '操作履歴と取り消し',
      content: SizedBox(
        width: double.maxFinite,
        child: validEvents.isEmpty
            ? const Text('取り消し可能な操作履歴がありません')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: validEvents.length,
                itemBuilder: (context, index) {
                  // 新しい順（最新が一番上）に表示
                  final eventIndex = validEvents.length - 1 - index;
                  final event = validEvents[eventIndex];

                  final sideStr = event.side == Side.red
                      ? '赤'
                      : (event.side == Side.white ? '白' : '');
                  final typeStr = _formatPointType(event.type);
                  final titleText = sideStr.isNotEmpty
                      ? '$sideStr $typeStr'
                      : typeStr;

                  return ListTile(
                    leading: Icon(
                      Icons.history,
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0x8A000000),
                    ),
                    title: Text(
                      titleText,
                      style: const TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('HH:mm:ss').format(event.timestamp),
                    ),
                    trailing: Text(
                      '${eventIndex + 1}本目まで戻る',
                      style: const TextStyle(
                        fontSize: AppFontSize.small,
                        color: AppKendoColors.blue,
                      ),
                    ),
                    onTap: () => onSelectRewind(eventIndex + 1, eventIndex),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text(
            '閉じる',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
      ],
    );
  }
}
