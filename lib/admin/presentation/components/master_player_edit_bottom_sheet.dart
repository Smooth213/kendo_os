import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/master_player_gender_selector.dart';
import 'package:kendo_os/admin/presentation/helpers/auto_kana_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';
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

    AutoKanaHelper.setupAutoKana(_lastNameController, _lastNameKanaController);
    AutoKanaHelper.setupAutoKana(
      _firstNameController,
      _firstNameKanaController,
    );
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _lastNameKanaController.dispose();
    _firstNameKanaController.dispose();
    super.dispose();
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
                AppSwitch(
                  value: _isBeginner,
                  activeColor: AppKendoColors.green,
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

        MasterPlayerGenderSelector(
          selectedGender: _selectedGender,
          onGenderChanged: (gender) => setState(() => _selectedGender = gender),
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
