import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 BANDグループ追加・編集ダイアログ
class BandGroupEditDialog extends ConsumerStatefulWidget {
  final BandGroupModel? initialGroup;

  const BandGroupEditDialog({super.key, this.initialGroup});

  static Future<bool?> show(
    BuildContext context, {
    BandGroupModel? initialGroup,
  }) {
    return showAppDialog<bool>(
      context: context,
      builder: (_) => BandGroupEditDialog(initialGroup: initialGroup),
    );
  }

  @override
  ConsumerState<BandGroupEditDialog> createState() =>
      _BandGroupEditDialogState();
}

class _BandGroupEditDialogState extends ConsumerState<BandGroupEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialGroup?.name ?? '',
    );
    _urlController = TextEditingController(
      text: widget.initialGroup?.url ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.show(context, 'グループ名を入力してください');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(bandRepositoryProvider);
      final model = widget.initialGroup != null
          ? widget.initialGroup!.copyWith(name: name, url: url)
          : BandGroupModel(
              id: '',
              name: name,
              url: url,
              createdAt: DateTime.now(),
            );

      await repo.saveBandGroup(model);
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackBar.showSuccess(
          context,
          widget.initialGroup != null ? '「$name」を更新しました' : '「$name」を追加しました',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '保存に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.initialGroup == null) return;
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: '削除の確認',
        content: Text('「${widget.initialGroup!.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppKendoColors.hansokuRed,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(bandRepositoryProvider);
      await repo.deleteBandGroup(widget.initialGroup!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackBar.show(context, '「${widget.initialGroup!.name}」を削除しました');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '削除に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGroup != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AppDialog(
      title: isEditing ? 'BANDグループの編集' : '新しいBANDグループを追加',
      titleIcon: Icons.group_add,
      iconColor: const Color(0xFF00C73C),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '道場の全員で共有されます。BANDアプリでグループの招待/共有リンクをコピーして貼り付けてください。',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: themeColors.subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _nameController,
              labelText: 'グループ名（例: 低学年チーム）',
              hintText: '例: 低学年チーム、〇〇剣友会',
              prefixIcon: const Icon(Icons.label_outline),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _urlController,
              labelText: 'BANDグループのURL / 招待リンク',
              hintText: '例: https://band.us/@dojo_low',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                tooltip: 'クリップボードから貼り付け',
                onPressed: _pasteFromClipboard,
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: AppKendoColors.hansokuRed,
            ),
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00C73C),
            foregroundColor: AppKendoColors.pureWhite,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppKendoColors.pureWhite,
                  ),
                )
              : Text(isEditing ? '更新' : '追加'),
        ),
      ],
    );
  }
}
