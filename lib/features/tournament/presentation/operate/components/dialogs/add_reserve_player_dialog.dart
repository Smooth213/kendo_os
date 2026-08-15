import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 控え選手追加ダイアログ（所属名簿からの選択またはマスタ外手動追加）
class AddReservePlayerDialog extends StatefulWidget {
  final List<String> availablePlayers;
  const AddReservePlayerDialog({super.key, required this.availablePlayers});

  @override
  State<AddReservePlayerDialog> createState() => _AddReservePlayerDialogState();
}

class _AddReservePlayerDialogState extends State<AddReservePlayerDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      titleWidget: const Text('控え選手の追加'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '助っ人（マスタ外）の名前を入力',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    onSubmitted: (val) {
                      final name = val.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(context, name);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    final name = _textController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context, name);
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '所属名簿から選択：',
              style: TextStyle(
                fontSize: AppFontSize.small,
                color: AppKendoColors.grey,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.availablePlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  '未出場の所属選手はいません。',
                  style: TextStyle(
                    color: AppKendoColors.grey,
                    fontSize: AppFontSize.bodySmall,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availablePlayers.length,
                  itemBuilder: (context, index) {
                    final name = widget.availablePlayers[index];
                    return ListTile(
                      title: Text(name),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.pop(context, name),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
