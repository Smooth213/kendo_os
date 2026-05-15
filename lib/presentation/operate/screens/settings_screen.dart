import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../providers/settings_provider.dart';
import '../providers/role_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ 追加: ログアウト処理用
import '../../shared/widgets/manual_help_button.dart'; // ★ ファイル上部に追加
import '../../shared/widgets/liquid_background.dart'; // ★ 追加

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _testMessage = '下のボタンをタップしてテスト';
  int _tapCount = 0; // ★ Phase 0: イースターエッグ用のタップカウンタ
  
  // ★ カラーパレットの定義（目立ちすぎない、上品で落ち着いたローズピンクへ調整）
  static const Color accentPink = Color(0xFFE06287); 
  static const Color textIndigo = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final enableLiquidGlass = settings.enableLiquidGlass;

    // iOS Native: True Black & Elevation
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // iOS Native カラーパレット
    final Color dynamicTextColor = isDark ? Colors.white : Colors.black;
    final Color dynamicCardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    
    // AppBarの文字色（ライト時はインディゴではなく黒に合わせるのがiOS風）
    final Color headerTextColor = isDark ? Colors.white : Colors.black;

    return LiquidBackground( // ★ 全体をLiquidBackgroundでラップ
      child: Scaffold(
        backgroundColor: Colors.transparent, // ★ 背景を透明にして下の光のオーブを透かす
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              _tapCount++;
              if (_tapCount >= 7) {
                _tapCount = 0;
                final current = settings.experimentalFeatures;
                ref.read(settingsProvider.notifier).updateField(experimentalFeatures: !current);
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(!current ? '🛠️ 内部ガバナンスモードが解放されました' : '🔒 内部モードをロックしました')),
                );
              }
            },
            child: Text('システム設定', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: headerTextColor)),
          ),
          backgroundColor: enableLiquidGlass ? Colors.transparent : dynamicCardColor,
          foregroundColor: headerTextColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: headerTextColor),
          actions: const [
            // ★ パスコード復旧手順などが載っている「設定マニュアル」へ直行
            ManualHelpButton(manualPath: 'docs/manuals/operator/settings.md'),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  // ==========================================
                  // 1. プリセット（一括設定）セクション
                  // ==========================================
                  _buildSectionHeader(context, '用途に合わせて一括セット'),
                  Row(
                    children: [
                      _buildPresetCard('公式大会', 'official', Icons.emoji_events, settings.confirmBehavior == 'long' && settings.isLocked, notifier),
                      const SizedBox(width: 8),
                      // ★ 修正：audioFeedbackMode が 'off' かどうかで判定
                      _buildPresetCard('大会・錬成会', 'renseikai', null, settings.confirmBehavior == 'double' && settings.audioFeedbackMode == 'off', notifier, customAsset: 'assets/kendo_icon.png'),
                      const SizedBox(width: 8),
                      _buildPresetCard('練習・道場', 'practice', Icons.home, settings.confirmBehavior == 'single' && !settings.haptic, notifier),
                    ],
                  ),
                  const SizedBox(height: 24),
  
                  // ==========================================
                  // 2. 表示と画面
                  // ==========================================
                  _buildSectionHeader(context, '表示と画面'),
                  _buildSettingsBlock(context, [
                    _buildListTile(context,
                      title: 'ダークモード対応',
                      icon: Icons.dark_mode, iconBgColor: Colors.blue,
                      trailing: DropdownButton<String>(
                        value: settings.themeMode,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(Icons.arrow_drop_down, color: dynamicTextColor),
                        style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'system', child: Text('システム依存')),
                          DropdownMenuItem(value: 'light', child: Text('常にライト')),
                          DropdownMenuItem(value: 'dark', child: Text('常にダーク')),
                        ],
                        onChanged: (val) {
                          if (val != null) ref.read(settingsProvider.notifier).updateField(themeMode: val);
                        },
                      ),
                    ),
                    _buildSwitchTile(context, 'スリープ(画面消灯)防止', settings.sleepPrevent, (val) => notifier.updateField(sleepPrevent: val),
                      icon: Icons.lightbulb, iconBgColor: Colors.orange,
                    ),
                    // ★ 追加: Liquid Glass (すりガラス) モード
                    _buildSwitchTile(context, 'iOS風すりガラス効果 (Liquid Glass)', settings.enableLiquidGlass, (val) => notifier.updateField(enableLiquidGlass: val),
                      icon: Icons.blur_on, iconBgColor: Colors.tealAccent.shade400,
                    ),
                  ]),
                  _buildSectionFooter(context, 'ダークモードは端末本体の設定に連動させることもできます。スリープ防止をオンにすると、長時間の試合記録中に画面が暗くなるのを防ぎます。\nすりガラス効果をOFFにすると軽量モードになり、古い端末でも快適に動作します。'),
                  const SizedBox(height: 24),
  
                  // ==========================================
                  // 3. 試合の操作・UI
                  // ==========================================
                  _buildSectionHeader(context, '試合の操作・UI'),
                  _buildSettingsBlock(context, [
                    _buildSwitchTile(context, '左利きモード (赤白ボタン反転)', settings.leftHanded, (val) => notifier.updateField(leftHanded: val),
                      icon: Icons.pan_tool, iconBgColor: Colors.indigo,
                    ),
                    _buildListTile(context,
                      title: '確定ボタンの挙動',
                      icon: Icons.touch_app, iconBgColor: Colors.teal,
                      trailing: DropdownButton<String>(
                        value: settings.confirmBehavior,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(Icons.arrow_drop_down, color: dynamicTextColor),
                        style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'single', child: Text('通常タップ')),
                          DropdownMenuItem(value: 'double', child: Text('ダブルタップ')),
                          DropdownMenuItem(value: 'long', child: Text('長押し (推奨)')),
                        ],
                        onChanged: (val) => notifier.updateField(confirmBehavior: val),
                      ),
                    ),
                    _buildSwitchTile(context, '最終確定時の確認ダイアログ', settings.showConfirmDialog, (val) => notifier.updateField(showConfirmDialog: val),
                      icon: Icons.domain_verification, iconBgColor: Colors.green,
                    ),
                    _buildSwitchTile(context, '記録確定後の修正ロック', settings.isLocked, (val) => notifier.updateField(isLocked: val),
                      icon: Icons.lock, iconBgColor: Colors.redAccent,
                    ),
                  ]),
                  _buildSectionFooter(context, '左利きモードにすると赤白の入力ボタンが反転します。確定ボタンを長押しやダブルタップにすることで誤操作を防ぎます。記録をロックすると後からスコアを修正できなくなります。'),
                  const SizedBox(height: 24),
  
                  // ==========================================
                  // 4. 音と振動・フィードバック
                  // ==========================================
                  _buildSectionHeader(context, '音と振動・フィードバック'),
                  _buildSettingsBlock(context, [
                    _buildListTile(context,
                      title: '音声・サウンド設定',
                      icon: Icons.volume_up, iconBgColor: Colors.pinkAccent,
                      trailing: DropdownButton<String>(
                        value: settings.audioFeedbackMode,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(Icons.arrow_drop_down, color: dynamicTextColor),
                        style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.bold, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'off', child: Text('OFF')),
                          DropdownMenuItem(value: 'effect', child: Text('効果音')),
                          DropdownMenuItem(value: 'voice', child: Text('音声読み上げ')),
                        ],
                        onChanged: (val) => notifier.updateField(audioFeedbackMode: val),
                      ),
                    ),
                    if (settings.audioFeedbackMode != 'off')
                      _buildSwitchTile(context, 'マナーモード時も強制的に鳴らす', settings.ignoreMannerMode, (val) => notifier.updateField(ignoreMannerMode: val),
                        icon: Icons.volume_off, iconBgColor: Colors.pink,
                      ),
                    _buildSwitchTile(context, 'システム操作の振動 (バイブ)', settings.haptic, (val) => notifier.updateField(haptic: val),
                      icon: Icons.vibration, iconBgColor: Colors.purpleAccent,
                    ),
                    _buildSwitchTile(context, '打突入力時の振動 (バイブ)', settings.strikeVib, (val) => notifier.updateField(strikeVib: val),
                      icon: Icons.sports_martial_arts, iconBgColor: Colors.deepPurple,
                    ),
                  ]),
                  _buildSectionFooter(context, 'ポイント入力時や試合終了時に音や振動で知らせます。マナーモード時も強制的に音を鳴らす設定は、大会本部のiPad等で周りに音を響かせたい場合に便利です。'),
                  const SizedBox(height: 24),
  
                  // ==========================================
                  // 5. セキュリティ・権限セクション
                  // ==========================================
                  _buildSectionHeader(context, 'セキュリティ・権限管理'),
                  _buildSettingsBlock(context, [
                    _buildListTile(context,
                      title: 'セキュリティレベル',
                      icon: Icons.security, iconBgColor: Colors.blueGrey,
                      trailing: DropdownButton<int>(
                        value: settings.securityLevel,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Lv.1 自由')),
                          DropdownMenuItem(value: 2, child: Text('Lv.2 標準')),
                          DropdownMenuItem(value: 3, child: Text('Lv.3 厳格')),
                        ],
                        onChanged: (val) => _handleSecurityChange(context, ref, val!),
                      ),
                    ),
                    _buildListTile(context,
                      title: '端末の役割設定',
                      subtitle: '現在の設定: ${ref.watch(persistentRoleProvider).label}',
                      icon: Icons.person, iconBgColor: Colors.blueGrey,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () => _handleRoleSwitch(context, ref),
                    ),
                  ]),
                  _buildSectionFooter(context, 
                    'パスコードを設定することで、一般ユーザーによる設定の変更を制限できます。\n\n'
                    '・Lv.1 (自由): パスコードなしで誰でも端末の役割を変更できます。\n'
                    '・Lv.2 (標準): 「記録係」から「管理者」に変更する際にパスコードを要求します。\n'
                    '・Lv.3 (厳格): アプリの重要な設定を変更する際など、より厳格にパスコードを要求します。'
                  ),
                  
                  // ==========================================
                  // ★ Phase 6: Stage 2 限定化
                  // 内部監査・ガバナンスメニューへの導線を一般UIから完全に削除します。
                  // (将来の Stage 3 で Advanced Menu として復活させます)
                  // ==========================================
                  /*
                  if (ref.watch(persistentRoleProvider) == Role.admin && settings.experimentalFeatures) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, '管理者・内部統治メニュー'),
                    _buildSettingsBlock(context, [
                      _buildListTile(context,
                        title: 'システム監査ログ',
                        subtitle: '誰が・いつ・何を変更したかを追跡します',
                        icon: Icons.policy, iconBgColor: Colors.grey,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () => context.push('/audit-log'),
                      ),
                    ]),
                    _buildSectionFooter(context, 'システムの詳細な操作履歴（監査ログ）を確認できます。'),
                  ],
                  */
                  
                  // ==========================================
                  // 6. アカウントセクション
                  // ==========================================
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'アカウント'),
                  _buildSettingsBlock(context, [
                    // ★ 追加: ログイン中のアカウント表示
                    _buildListTile(context,
                      title: 'ログイン中のアカウント',
                      subtitle: FirebaseAuth.instance.currentUser?.email ?? '取得できませんでした',
                      icon: Icons.account_circle, iconBgColor: Colors.blueAccent,
                      trailing: const SizedBox.shrink(), // タップアクションがないため空のウィジェット
                    ),
                    _buildListTile(context,
                      title: 'ログアウト',
                      icon: Icons.logout, iconBgColor: Colors.red,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () => _showLogoutConfirmation(context, ref),
                    ),
                  ]),
                  _buildSectionFooter(context, '現在ログインしているアカウントからサインアウトします。'),
                  const SizedBox(height: 48), // 下部に十分な余白を確保
                ],
              ),
            ),
  
            // ==========================================
            // 5. テスト用インタラクティブエリア（画面下部固定）
            // ==========================================
            SafeArea(
              top: false,
              child: Container(
                margin: enableLiquidGlass 
                    ? const EdgeInsets.fromLTRB(16, 0, 16, 16) 
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: enableLiquidGlass 
                      ? dynamicCardColor.withValues(alpha: isDark ? 0.3 : 0.6) 
                      : dynamicCardColor,
                  borderRadius: enableLiquidGlass ? BorderRadius.circular(24) : BorderRadius.zero,
                  border: enableLiquidGlass 
                      ? Border.all(color: isDark ? Colors.white30 : Colors.white.withValues(alpha: 0.6), width: 1.5) 
                      : null,
                  boxShadow: enableLiquidGlass 
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))] 
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: ClipRRect(
                  borderRadius: enableLiquidGlass ? BorderRadius.circular(24) : BorderRadius.zero,
                  child: BackdropFilter(
                    filter: enableLiquidGlass 
                        ? ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0) 
                        : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(_testMessage, style: TextStyle(color: dynamicTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        if (settings.haptic) HapticFeedback.lightImpact();
                        if (settings.confirmBehavior == 'long') {
                          setState(() => _testMessage = '⚠️ 長押ししてください');
                        } else if (settings.confirmBehavior == 'double') {
                          setState(() => _testMessage = '⚠️ ダブルタップしてください');
                        } else {
                          setState(() => _testMessage = '✅ 確定しました (通常タップ)');
                          if (settings.haptic) HapticFeedback.mediumImpact();
                        }
                      },
                      onDoubleTap: () {
                        if (settings.confirmBehavior == 'double') {
                          setState(() => _testMessage = '✅ 確定しました (ダブルタップ)');
                          if (settings.haptic) HapticFeedback.heavyImpact();
                        }
                      },
                      onLongPress: () {
                        if (settings.confirmBehavior == 'long') {
                          setState(() => _testMessage = '✅ 確定しました (長押し)');
                          if (settings.haptic) HapticFeedback.heavyImpact();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: accentPink, 
                          borderRadius: BorderRadius.circular(16),
                          // 影も少し控えめに調整
                          boxShadow: [BoxShadow(color: accentPink.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: const Center(
                          // ★ 落ち着いたローズピンクには、純白の文字が最も美しく映えます
                          child: Text('テスト用：試合終了ボタン', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }

  // --- UI構築用ヘルパーメソッド ---

  Widget _buildPresetCard(String title, String presetKey, IconData? icon, bool isActive, SettingsNotifier notifier, {String? customAsset}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicTextColor = isDark ? Colors.white : textIndigo;
    final Color dynamicCardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          notifier.applyPreset(presetKey);
          setState(() => _testMessage = 'プリセットを変更しました');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? accentPink.withValues(alpha: 0.15) : dynamicCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? accentPink : Colors.transparent, width: 2),
            boxShadow: isActive ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              if (customAsset != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Image.asset(
                    customAsset,
                    width: 34,
                    height: 34,
                    color: isActive ? dynamicTextColor : Colors.grey.shade400,
                  ),
                )
              else if (icon != null)
                Icon(icon, color: isActive ? dynamicTextColor : Colors.grey.shade400, size: 28),
              
              const SizedBox(height: 8),
              Text(
                title, 
                style: TextStyle(color: isActive ? dynamicTextColor : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, 
          fontSize: 13, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsBlock(BuildContext context, List<Widget> children) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicCardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(_buildDivider(context));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: dynamicCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: spacedChildren),
    );
  }

  Widget _buildSectionFooter(BuildContext context, String text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {
    required String title,
    required Widget trailing,
    required IconData icon,
    required Color iconBgColor,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicTextColor = isDark ? Colors.white : Colors.black;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: TextStyle(color: dynamicTextColor, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, bool value, Function(bool) onChanged, {
    required IconData icon,
    required Color iconBgColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildListTile(
      context,
      title: title,
      icon: icon, iconBgColor: iconBgColor,
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.white, 
        activeTrackColor: Colors.green, // iOS風の緑
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: isDark ? const Color(0xFF38383A) : const Color(0xFFE9E9EA),
        onChanged: (val) {
          if (value != val) HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, thickness: 0.5, color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8), indent: 56, endIndent: 0);
  }

  // ★ Phase 8: 英数混在8文字以上のバリデーション
  bool _isValidPasscode(String code) {
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(code);
    final hasDigit = RegExp(r'[0-9]').hasMatch(code);
    return code.length >= 8 && hasLetter && hasDigit;
  }

  // 立場（Role）を切り替える際のガード処理
  void _handleRoleSwitch(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final currentRole = ref.read(persistentRoleProvider);

    // すでに管理者なら、記録係へのダウングレードは自由
    if (currentRole == Role.admin) {
      _showRolePicker(context, ref);
      return;
    }

    // 記録係から管理者へ昇格する場合
    if (settings.securityLevel >= 2) {
      _showPasscodeDialog(context, ref, onSuccess: () => _showRolePicker(context, ref));
    } else {
      _showRolePicker(context, ref);
    }
  }

  // セキュリティレベル変更時のガード
  void _handleSecurityChange(BuildContext context, WidgetRef ref, int newLevel) {
    final settings = ref.read(settingsProvider);
    // すでにパスコードが設定されている場合のみガード
    if (settings.adminPasscode != null && settings.adminPasscode!.isNotEmpty) {
      _showPasscodeDialog(context, ref, onSuccess: () {
        ref.read(settingsProvider.notifier).updateField(securityLevel: newLevel);
      });
    } else {
      // 初回設定時（Lv.1 -> Lv.2等）はパスコード作成へ
      _showPasscodeCreationDialog(context, ref, newLevel);
    }
  }

  void _showPasscodeDialog(BuildContext context, WidgetRef ref, {required VoidCallback onSuccess}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('管理者パスコードを入力'),
        content: TextField(controller: controller, obscureText: true, decoration: const InputDecoration(hintText: '英数8文字以上')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              if (controller.text == ref.read(settingsProvider).adminPasscode) {
                Navigator.pop(ctx);
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスコードが正しくありません')));
              }
            },
            child: const Text('照合'),
          ),
        ],
      ),
    );
  }

  void _showPasscodeCreationDialog(BuildContext context, WidgetRef ref, int targetLevel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新規パスコードの設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('英字と数字を両方含む、8文字以上で設定してください。', style: TextStyle(fontSize: 12)),
            TextField(controller: controller, obscureText: true, decoration: const InputDecoration(hintText: '英数8文字以上')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_isValidPasscode(controller.text)) {
                ref.read(settingsProvider.notifier).updateField(securityLevel: targetLevel, adminPasscode: controller.text);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ルール（英数8文字以上）に合致しません')));
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showRolePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
              title: const Text('管理者（すべて）'),
              onTap: () {
                // ★ persistentRoleProvider を更新して永続化させる
                ref.read(persistentRoleProvider.notifier).state = Role.admin;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.teal),
              title: const Text('記録係（入力）'),
              onTap: () {
                ref.read(persistentRoleProvider.notifier).state = Role.scorer;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16), // 下部に余白を追加
          ],
        ),
      ),
    );
  }

  // ログアウト確認ダイアログ
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('ログアウトすると、次回の利用時に再度ログインが必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // FirebaseAuthを直接呼び出してサインアウト
              await FirebaseAuth.instance.signOut();
              // authStateProviderが検知し、自動的にLoginScreenへ遷移します
            },
            child: const Text('ログアウト', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}