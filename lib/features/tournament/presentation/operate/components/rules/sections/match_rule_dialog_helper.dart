import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 ルール設定用ダイアログヘルパー
class MatchRuleDialogHelper {
  static void showCustomTimeDialog(
    BuildContext context, {
    required String title,
    required double currentTime,
    required ValueChanged<double> onConfirmed,
  }) {
    final int initialMin = currentTime.toInt();
    final int initialSec = ((currentTime % 1) * 60).round();
    final minCtrl = TextEditingController(text: initialMin.toString());
    final secCtrl = TextEditingController(text: initialSec.toString());

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: SizedBox(
          width: 220,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                child: AppTextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(labelText: '分'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 70,
                child: AppTextField(
                  controller: secCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(labelText: '秒'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: context.appColors.subTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(minCtrl.text) ?? 0;
              final s = int.tryParse(secCtrl.text) ?? 0;
              final totalMins = m + (s / 60.0);
              if (totalMins > 0) {
                onConfirmed(totalMins);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  static void showCustomMinutesDialog(
    BuildContext context, {
    required String title,
    required int currentMinutes,
    required ValueChanged<int> onConfirmed,
  }) {
    final ctrl = TextEditingController(text: currentMinutes.toString());

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: AppTextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(labelText: '全体の制限時間（分）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: context.appColors.subTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(ctrl.text) ?? 0;
              if (m > 0) {
                onConfirmed(m);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  static void showCustomPointDialog(
    BuildContext context, {
    required String title,
    required double currentPoint,
    required ValueChanged<double> onConfirmed,
  }) {
    final ctrl = TextEditingController(text: currentPoint.toString());

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: AppTextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: '点数'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: context.appColors.subTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final p = double.tryParse(ctrl.text);
              if (p != null) {
                onConfirmed(p);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }
}
