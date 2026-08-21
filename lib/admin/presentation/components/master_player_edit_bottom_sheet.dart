import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 選手情報の新規登録・編集ボトムシート
class MasterPlayerEditBottomSheet extends ConsumerStatefulWidget {
  final PlayerModel? player;
  final String cloudDojoName;

  const MasterPlayerEditBottomSheet({
    super.key,
    this.player,
    required this.cloudDojoName,
  });

  static void show(
    BuildContext context, {
    PlayerModel? player,
    required String cloudDojoName,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => MasterPlayerEditBottomSheet(
        player: player,
        cloudDojoName: cloudDojoName,
      ),
    );
  }

  @override
  ConsumerState<MasterPlayerEditBottomSheet> createState() =>
      _MasterPlayerEditBottomSheetState();
}

class _MasterPlayerEditBottomSheetState
    extends ConsumerState<MasterPlayerEditBottomSheet> {
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameKanaController;
  late final TextEditingController _firstNameKanaController;

  late int _selectedGrade;
  late String _selectedGender;
  late bool _isBeginner;

  static const Map<int, String> _gradeOptions = {
    0: '未就学',
    1: '小学1年',
    2: '小学2年',
    3: '小学3年',
    4: '小学4年',
    5: '小学5年',
    6: '小学6年',
    7: '中学1年',
    8: '中学2年',
    9: '中学3年',
    10: '高校1年',
    11: '高校2年',
    12: '高校3年',
    13: '大学1年',
    14: '大学2年',
    15: '大学3年',
    16: '大学4年',
    99: '一般',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _lastNameController = TextEditingController(text: p?.lastName ?? '');
    _firstNameController = TextEditingController(text: p?.firstName ?? '');
    _lastNameKanaController = TextEditingController(
      text: p?.lastNameKana ?? '',
    );
    _firstNameKanaController = TextEditingController(
      text: p?.firstNameKana ?? '',
    );

    _selectedGrade = p?.grade ?? 1;
    _selectedGender = p?.gender ?? '男子';
    _isBeginner = p?.isBeginner ?? false;

    _setupAutoKana(_lastNameController, _lastNameKanaController);
    _setupAutoKana(_firstNameController, _firstNameKanaController);
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _lastNameKanaController.dispose();
    _firstNameKanaController.dispose();
    super.dispose();
  }

  void _setupAutoKana(
    TextEditingController nameCtrl,
    TextEditingController kanaCtrl,
  ) {
    String lastText = nameCtrl.text;
    String lastValidKana = '';
    DateTime lastClearedTime = DateTime.fromMillisecondsSinceEpoch(0);

    String keepKanaOnly(String s) {
      return s.replaceAll(RegExp(r'[^ぁ-んァ-ヶー]'), '');
    }

    String keepKanjiOnly(String s) {
      return s.replaceAll(RegExp(r'[^一-龠々]'), '');
    }

    void processChange(String fromText, String toText) {
      if (toText.isEmpty) {
        if (kanaCtrl.text.isNotEmpty) {
          lastValidKana = kanaCtrl.text;
          lastClearedTime = clock.now();
        }
        kanaCtrl.text = '';
        return;
      }

      final lastKana = keepKanaOnly(fromText);
      final currentKana = keepKanaOnly(toText);

      final lastKanjiCount = keepKanjiOnly(fromText).length;
      final currentKanjiCount = keepKanjiOnly(toText).length;

      // 1. かな文字が増加した場合
      if (currentKana.startsWith(lastKana) &&
          currentKana.length > lastKana.length) {
        final added = currentKana.substring(lastKana.length);
        kanaCtrl.text = kanaCtrl.text + added;
        lastValidKana = kanaCtrl.text;
      }
      // 2. 文字が純粋に削除された場合
      else if (toText.length < fromText.length &&
          currentKanjiCount <= lastKanjiCount) {
        final diffLen = fromText.length - toText.length;
        if (kanaCtrl.text.length >= diffLen) {
          kanaCtrl.text = kanaCtrl.text.substring(
            0,
            kanaCtrl.text.length - diffLen,
          );
        } else {
          kanaCtrl.text = '';
        }
        lastValidKana = kanaCtrl.text;
      }
      // 3. 全クリアやひらがなのみのコピペ時のフォールバック
      else if (RegExp(r'^[ぁ-んァ-ヶーa-zA-Z0-9]*$').hasMatch(toText)) {
        kanaCtrl.text = toText;
        lastValidKana = kanaCtrl.text;
      }
      // 4. Web等でIME確定時の自己修復
      else if (kanaCtrl.text.isEmpty &&
          lastValidKana.isNotEmpty &&
          currentKanjiCount > 0 &&
          clock.now().difference(lastClearedTime).inMilliseconds < 150) {
        kanaCtrl.text = lastValidKana;
      }
    }

    nameCtrl.addListener(() {
      final text = nameCtrl.text;
      if (text == lastText) return;

      Future.microtask(() {
        final finalText = nameCtrl.text;
        if (finalText == lastText) return;

        processChange(lastText, finalText);
        lastText = finalText;
      });
    });
  }

  Future<void> _handleSave() async {
    if (_lastNameController.text.trim().isEmpty) return;
    final dojoId = ref.read(currentDojoIdProvider);
    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
    FirebaseFirestore? firestore;
    try {
      firestore = ref.read(firestoreProvider);
    } catch (_) {}

    final pData = {
      'lastName': _lastNameController.text.trim(),
      'firstName': _firstNameController.text.trim(),
      'lastNameKana': _lastNameKanaController.text.trim(),
      'firstNameKana': _firstNameKanaController.text.trim(),
      'grade': _selectedGrade,
      'gender': _selectedGender,
      'isBeginner': _isBeginner,
      'organization': widget.cloudDojoName.isNotEmpty
          ? widget.cloudDojoName
          : 'テスト道場',
    };

    if (firestore != null) {
      if (widget.player != null) {
        await firestore
            .collection('organizations')
            .doc(safeDojoId)
            .collection('players')
            .doc(widget.player!.id)
            .set(pData, SetOptions(merge: true));
      } else {
        await firestore
            .collection('organizations')
            .doc(safeDojoId)
            .collection('players')
            .add(pData);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _buildGenderBtn({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSel,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final finalColor = isSel ? color : context.appColors.subTextColor;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSel
            ? color.withValues(alpha: isDark ? 0.2 : 0.1)
            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F7)),
        side: BorderSide(
          color: isSel
              ? color
              : (isDark
                    ? const Color(0xFFFFFFFF)
                    : context.appColors.separatorColor),
          width: isSel ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: finalColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
              color: finalColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final primaryColor = themeColors.primaryAccent;
    final dialogBgColor = themeColors.cardBackground;
    final inputBgColor = themeColors.inputBackground;
    final textColor = themeColors.textColor;

    final keyboardHeight = kIsWeb
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.9;

    final gapLarge = isKeyboardVisible ? 12.0 : 24.0;
    final gapMedium = isKeyboardVisible ? 8.0 : 16.0;
    final gapSmall = isKeyboardVisible ? 6.0 : 12.0;

    final isEdit = widget.player != null;

    final innerForm = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!kIsWeb)
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x33000000),
                borderRadius: AppRadius.medium,
              ),
            ),
          ),
        SizedBox(height: gapLarge),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEdit ? '選手情報を編集' : '新しい選手を登録',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: primaryColor,
                fontSize: AppFontSize.header,
              ),
            ),
            Row(
              children: [
                Text(
                  '🔰 初心者',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: _isBeginner
                        ? AppKendoColors.green
                        : AppKendoColors.grey,
                  ),
                ),
                Switch(
                  value: _isBeginner,
                  activeThumbColor: AppKendoColors.green,
                  onChanged: (val) => setState(() => _isBeginner = val),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: gapMedium),

        // よみがな入力欄
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _lastNameKanaController,
                style: TextStyle(color: textColor, fontSize: AppFontSize.small),
                decoration: InputDecoration(
                  labelText: 'よみがな (せい)',
                  labelStyle: const TextStyle(
                    fontSize: AppFontSize.badge,
                    color: AppKendoColors.grey,
                  ),
                  isDense: true,
                  contentPadding: isKeyboardVisible
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSpacing.compact,
                          vertical: AppSpacing.subValue,
                        )
                      : const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(borderRadius: AppRadius.small),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppTextField(
                controller: _firstNameKanaController,
                style: TextStyle(color: textColor, fontSize: AppFontSize.small),
                decoration: InputDecoration(
                  labelText: 'よみがな (めい)',
                  labelStyle: const TextStyle(
                    fontSize: AppFontSize.badge,
                    color: AppKendoColors.grey,
                  ),
                  isDense: true,
                  contentPadding: isKeyboardVisible
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSpacing.compact,
                          vertical: AppSpacing.subValue,
                        )
                      : const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(borderRadius: AppRadius.small),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gapSmall),

        // 漢字入力欄
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _lastNameController,
                style: TextStyle(
                  color: textColor,
                  fontWeight: AppFontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: '名字',
                  hintText: '例: 山田',
                  prefixIcon: isKeyboardVisible
                      ? null
                      : Icon(
                          Icons.person,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : AppKendoColors.grey,
                        ),
                  isDense: isKeyboardVisible,
                  contentPadding: isKeyboardVisible
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  filled: true,
                  fillColor: inputBgColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppTextField(
                controller: _firstNameController,
                style: TextStyle(
                  color: textColor,
                  fontWeight: AppFontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: '名前',
                  hintText: '例: 太郎',
                  isDense: isKeyboardVisible,
                  contentPadding: isKeyboardVisible
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: AppRadius.medium),
                  filled: true,
                  fillColor: inputBgColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gapLarge),

        Text(
          '性別',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: isDark ? const Color(0xFFFFFFFF) : AppKendoColors.grey,
          ),
        ),
        SizedBox(height: gapSmall),
        Row(
          children: [
            Expanded(
              child: _buildGenderBtn(
                title: '男子',
                icon: Icons.man,
                color: AppKendoColors.blue,
                isSel: _selectedGender == '男子',
                isDark: isDark,
                onTap: () => setState(() => _selectedGender = '男子'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildGenderBtn(
                title: '女子',
                icon: Icons.woman,
                color: AppKendoColors.pink,
                isSel: _selectedGender == '女子',
                isDark: isDark,
                onTap: () => setState(() => _selectedGender = '女子'),
              ),
            ),
          ],
        ),
        SizedBox(height: gapLarge),

        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: '学年・カテゴリ',
            prefixIcon: Icon(
              Icons.school,
              color: isDark ? const Color(0xFFFFFFFF) : AppKendoColors.grey,
            ),
            border: OutlineInputBorder(borderRadius: AppRadius.medium),
            filled: true,
            fillColor: inputBgColor,
          ),
          dropdownColor: dialogBgColor,
          style: TextStyle(color: textColor, fontSize: AppFontSize.subhead),
          initialValue: _selectedGrade,
          items: _gradeOptions.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedGrade = val);
          },
        ),
        SizedBox(height: isKeyboardVisible ? 16.0 : 32.0),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: isDark
                      ? context.appColors.subTextColor
                      : AppKendoColors.grey,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
              ),
              icon: const Icon(Icons.save, color: AppKendoColors.pureWhite),
              label: const Text(
                '保存して登録',
                style: TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (!kIsWeb && isKeyboardVisible) SizedBox(height: keyboardHeight),
      ],
    );

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: dialogBgColor,
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
      child: SingleChildScrollView(child: innerForm),
    );
  }
}
