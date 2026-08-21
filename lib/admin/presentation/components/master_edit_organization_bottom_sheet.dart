import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 所属名（道場名）一括変更ボトムシート
class MasterEditOrganizationBottomSheet extends ConsumerStatefulWidget {
  final String currentName;
  final List<PlayerModel> players;

  const MasterEditOrganizationBottomSheet({
    super.key,
    required this.currentName,
    required this.players,
  });

  static void show(
    BuildContext context, {
    required String currentName,
    required List<PlayerModel> players,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => MasterEditOrganizationBottomSheet(
        currentName: currentName,
        players: players,
      ),
    );
  }

  @override
  ConsumerState<MasterEditOrganizationBottomSheet> createState() =>
      _MasterEditOrganizationBottomSheetState();
}

class _MasterEditOrganizationBottomSheetState
    extends ConsumerState<MasterEditOrganizationBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final newName = TextSanitizer.clean(_controller.text);
    if (newName.isEmpty) return;

    Navigator.pop(context);
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dojoId = ref.read(currentDojoIdProvider);
      final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
      FirebaseFirestore? firestore;
      try {
        firestore = ref.read(firestoreProvider);
      } catch (_) {}

      if (firestore != null) {
        await firestore.collection('organizations').doc(safeDojoId).set({
          'name': newName,
        }, SetOptions(merge: true));

        final batch = firestore.batch();
        for (var p in widget.players) {
          final docRef = firestore
              .collection('organizations')
              .doc(safeDojoId)
              .collection('players')
              .doc(p.id);
          batch.set(docRef, {'organization': newName}, SetOptions(merge: true));
        }
        await batch.commit();
      }

      if (mounted) {
        Navigator.pop(context); // close progress
        AppSnackBar.showSuccess(context, '所属名を一括更新しました！');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close progress
        AppSnackBar.showError(context, 'エラーが発生しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppKendoColors.purpleAccent
        : context.appColors.primaryAccent;

    final keyboardHeight = kIsWeb
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // つまみバー
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              '所属名の変更',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: primaryColor,
                fontSize: AppFontSize.header,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '登録されている全選手の所属名を一括で書き換えます。',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              controller: _controller,
              autofocus: false,
              decoration: InputDecoration(
                labelText: '新しい道場名・学校名',
                prefixIcon: const Icon(
                  Icons.account_balance,
                  color: AppKendoColors.grey,
                ),
                border: OutlineInputBorder(borderRadius: AppRadius.medium),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(
                      color: AppKendoColors.grey,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: AppKendoColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  onPressed: _handleUpdate,
                  label: const Text(
                    '一括更新',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ],
            ),
            if (!kIsWeb && isKeyboardVisible) SizedBox(height: keyboardHeight),
          ],
        ),
      ),
    );
  }
}
