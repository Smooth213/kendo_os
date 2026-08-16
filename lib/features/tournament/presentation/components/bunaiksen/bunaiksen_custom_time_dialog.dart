import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 部内戦の任意試合時間（分・秒）を設定する純粋UIダイアログコンポーネント
class BunaiksenCustomTimeDialog extends StatefulWidget {
  final double currentTime;
  final bool isDark;
  final Color primaryAccent;
  final Color? subTextColor;
  final Color? hintColor;
  final Color? inputBackground;
  final Color? separatorColor;

  const BunaiksenCustomTimeDialog({
    super.key,
    required this.currentTime,
    required this.isDark,
    required this.primaryAccent,
    this.subTextColor,
    this.hintColor,
    this.inputBackground,
    this.separatorColor,
  });

  /// ダイアログを表示して結果の分（double）を取得するヘルパー
  static Future<double?> show(
    BuildContext context, {
    required double currentTime,
    required bool isDark,
    required Color primaryAccent,
    Color? subTextColor,
    Color? hintColor,
    Color? inputBackground,
    Color? separatorColor,
  }) {
    return showAppDialog<double>(
      context: context,
      builder: (ctx) => BunaiksenCustomTimeDialog(
        currentTime: currentTime,
        isDark: isDark,
        primaryAccent: primaryAccent,
        subTextColor: subTextColor,
        hintColor: hintColor,
        inputBackground: inputBackground,
        separatorColor: separatorColor,
      ),
    );
  }

  @override
  State<BunaiksenCustomTimeDialog> createState() =>
      _BunaiksenCustomTimeDialogState();
}

class _BunaiksenCustomTimeDialogState extends State<BunaiksenCustomTimeDialog> {
  late final TextEditingController _minController;
  late final TextEditingController _secController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.currentTime.toInt().toString(),
    );
    _secController = TextEditingController(
      text: ((widget.currentTime % 1) * 60).toInt().toString(),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  InputDecoration _buildTextFieldDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: widget.subTextColor),
      hintStyle: TextStyle(color: widget.hintColor),
      filled: true,
      fillColor: widget.inputBackground,
      border: OutlineInputBorder(borderRadius: AppRadius.medium),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(
          color: widget.separatorColor ?? AppKendoColors.grey,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: widget.primaryAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '任意の試合時間',
      content: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _minController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: widget.isDark
                    ? const Color(0xFFFFFFFF)
                    : context.appColors.textColor,
              ),
              decoration: _buildTextFieldDecoration(labelText: '分'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: AppFontSize.display,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: AppTextField(
              controller: _secController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: widget.isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF000000),
              ),
              decoration: _buildTextFieldDecoration(labelText: '秒'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            'キャンセル',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryAccent,
            foregroundColor: AppKendoColors.pureWhite,
          ),
          onPressed: () {
            final m = int.tryParse(_minController.text) ?? 0;
            final s = int.tryParse(_secController.text) ?? 0;
            final total = m + (s / 60.0);
            Navigator.pop(context, total);
          },
          child: const Text(
            '設定する',
            style: TextStyle(fontWeight: AppFontWeight.bold),
          ),
        ),
      ],
    );
  }
}
