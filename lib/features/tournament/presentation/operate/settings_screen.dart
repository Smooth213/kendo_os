import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ 追加: ログアウト処理用
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ★ ファイル上部に追加
import 'package:kendo_os/shared/widgets/liquid_background.dart'; // ★ 追加
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/infrastructure/services/web_notification_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _testMessage = '下のボタンをタップしてテスト';
  // ★ Phase 6-2修正: 未使用となった _tapCount フィールドを完全にパージ（クリーンアップ）

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
    final Color dynamicCardColor = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    // AppBarの文字色（ライト時はインディゴではなく黒に合わせるのがiOS風）
    final Color headerTextColor = isDark ? Colors.white : Colors.black;

    return LiquidBackground(
      // ★ 全体をLiquidBackgroundでラップ
      child: Scaffold(
        backgroundColor: Colors.transparent, // ★ 背景を透明にして下の光のオーブを透かす
        appBar: AppBar(
          title: GestureDetector(
            // ★ Phase 6-2: 内部ガバナンスモードへの裏ルート・タップ連打ギミックを完全に物理消滅化
            onTap: null,
            child: Text(
              'システム設定',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: headerTextColor,
              ),
            ),
          ),
          backgroundColor: enableLiquidGlass
              ? Colors.transparent
              : dynamicCardColor,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                children: [
                  // ==========================================
                  // 1. 表示と画面
                  // ==========================================
                  _buildSectionHeader(context, '表示と画面'),
                  _buildSettingsBlock(context, [
                    _buildListTile(
                      context,
                      title: 'ダークモード対応',
                      icon: Icons.dark_mode,
                      iconBgColor: Colors.blue,
                      trailing: DropdownButton<String>(
                        value: settings.themeMode,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: dynamicTextColor,
                        ),
                        style: TextStyle(
                          color: dynamicTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text('システム依存'),
                          ),
                          DropdownMenuItem(
                            value: 'light',
                            child: Text('常にライト'),
                          ),
                          DropdownMenuItem(value: 'dark', child: Text('常にダーク')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateField(themeMode: val);
                          }
                        },
                      ),
                    ),
                    _buildSwitchTile(
                      context,
                      'スリープ(画面消灯)防止',
                      settings.sleepPrevent,
                      (val) => notifier.updateField(sleepPrevent: val),
                      icon: Icons.lightbulb,
                      iconBgColor: Colors.orange,
                    ),
                    _buildSwitchTile(
                      context,
                      'iOS風すりガラス効果 (Liquid Glass)',
                      settings.enableLiquidGlass,
                      (val) => notifier.updateField(enableLiquidGlass: val),
                      icon: Icons.blur_on,
                      iconBgColor: Colors.tealAccent.shade400,
                    ),
                  ]),
                  _buildSectionFooter(
                    context,
                    'ダークモードは端末本体の設定に連動させることもできます。スリープ防止をオンにすると、長時間の試合記録中に画面が暗くなるのを防ぎます。\nすりガラス効果をOFFにすると軽量モードになり、古い端末でも快適に動作します。',
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 2. 音と振動・フィードバック
                  // ==========================================
                  _buildSectionHeader(context, '音と振動・フィードバック'),
                  _buildSettingsBlock(context, [
                    _buildListTile(
                      context,
                      title: '音声・サウンド設定',
                      icon: Icons.volume_up,
                      iconBgColor: Colors.pinkAccent,
                      trailing: DropdownButton<String>(
                        value: settings.audioFeedbackMode,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: dynamicTextColor,
                        ),
                        style: TextStyle(
                          color: dynamicTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'off', child: Text('OFF')),
                          DropdownMenuItem(value: 'effect', child: Text('効果音')),
                          DropdownMenuItem(
                            value: 'voice',
                            child: Text('音声読み上げ'),
                          ),
                        ],
                        onChanged: (val) =>
                            notifier.updateField(audioFeedbackMode: val),
                      ),
                    ),
                    if (settings.audioFeedbackMode != 'off')
                      _buildSwitchTile(
                        context,
                        'マナーモード時も強制的に鳴らす',
                        settings.ignoreMannerMode,
                        (val) => notifier.updateField(ignoreMannerMode: val),
                        icon: Icons.volume_off,
                        iconBgColor: Colors.pink,
                      ),
                    _buildSwitchTile(
                      context,
                      'システム操作の振動 (バイブ)',
                      settings.haptic,
                      (val) => notifier.updateField(haptic: val),
                      icon: Icons.vibration,
                      iconBgColor: Colors.purpleAccent,
                    ),
                    _buildSwitchTile(
                      context,
                      '打突入力時の振動 (バイブ)',
                      settings.strikeVib,
                      (val) => notifier.updateField(strikeVib: val),
                      icon: Icons.sports_martial_arts,
                      iconBgColor: Colors.deepPurple,
                    ),
                  ]),
                  _buildSectionFooter(context, 'ポイント入力時や試合終了時に音や振動で知らせます。'),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 2-2. プッシュ通知設定
                  // ==========================================
                  _buildSectionHeader(context, 'プッシュ通知設定 (iPhone/iPad/Web対応)'),
                  _buildSettingsBlock(context, [
                    _buildSwitchTile(
                      context,
                      '緊急連絡・本部アナウンスの通知',
                      settings.notifyOnEmergency,
                      (val) {
                        if (val) {
                          triggerWebNotificationPermission();
                        }
                        notifier.updateField(notifyOnEmergency: val);
                        if (val) {
                          ref
                              .read(notificationServiceProvider)
                              .initializeNotification();
                        }
                      },
                      icon: Icons.emergency_share,
                      iconBgColor: Colors.red,
                    ),
                    _buildSwitchTile(
                      context,
                      '新着試合追加の通知',
                      settings.notifyOnMatchAdded,
                      (val) {
                        if (val) {
                          triggerWebNotificationPermission();
                        }
                        notifier.updateField(notifyOnMatchAdded: val);
                        if (val) {
                          ref
                              .read(notificationServiceProvider)
                              .initializeNotification();
                        }
                      },
                      icon: Icons.add_alert,
                      iconBgColor: Colors.indigo,
                    ),
                    _buildSwitchTile(
                      context,
                      '試合開始の通知',
                      settings.notifyOnMatchStarted,
                      (val) {
                        if (val) {
                          triggerWebNotificationPermission();
                        }
                        notifier.updateField(notifyOnMatchStarted: val);
                        if (val) {
                          ref
                              .read(notificationServiceProvider)
                              .initializeNotification();
                        }
                      },
                      icon: Icons.play_circle_outline,
                      iconBgColor: Colors.green,
                    ),
                    _buildSwitchTile(
                      context,
                      '試合結果・終了の通知',
                      settings.notifyOnResult,
                      (val) {
                        if (val) {
                          triggerWebNotificationPermission();
                        }
                        notifier.updateField(notifyOnResult: val);
                        if (val) {
                          ref
                              .read(notificationServiceProvider)
                              .initializeNotification();
                        }
                      },
                      icon: Icons.emoji_events,
                      iconBgColor: Colors.amber,
                    ),
                  ]),
                  _buildSectionFooter(
                    context,
                    '※ iPhone/Safariで通知を受信するには、必ず「ホーム画面に追加」して起動し、通知スイッチをオンにして表示される「通知の許可」を承諾してください。',
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. ローカル保存と保護
                  // ==========================================
                  _buildSectionHeader(context, 'ローカル保存と保護'),
                  _buildSettingsBlock(context, [
                    _buildSwitchTile(
                      context,
                      '記録確定後の修正ロック',
                      settings.isLocked,
                      (val) => notifier.updateField(isLocked: val),
                      icon: Icons.lock,
                      iconBgColor: Colors.redAccent,
                    ),
                  ]),
                  _buildSectionFooter(
                    context,
                    '記録をロックすると後からスコアを修正できなくなり、ローカル保存されたデータの安全性を高めます。',
                  ),

                  // ==========================================
                  // 4. アカウント管理
                  // ==========================================
                  _buildSectionHeader(context, 'アカウント管理'),
                  _buildSettingsBlock(context, [
                    _buildListTile(
                      context,
                      title: 'ログアウト',
                      icon: Icons.logout,
                      iconBgColor: Colors.redAccent,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLogoutConfirmation(context, ref),
                    ),
                  ]),
                  _buildSectionFooter(
                    context,
                    'ログアウトすると現在のセッションが終了し、次回利用時に再ログインが必要になります。',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ==========================================
            // 6. テスト用インタラクティブエリア（画面下部固定）
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
                  borderRadius: enableLiquidGlass
                      ? BorderRadius.circular(24)
                      : BorderRadius.zero,
                  border: enableLiquidGlass
                      ? Border.all(
                          color: isDark
                              ? Colors.white30
                              : Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: enableLiquidGlass
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: enableLiquidGlass
                      ? BorderRadius.circular(24)
                      : BorderRadius.zero,
                  child: BackdropFilter(
                    filter: enableLiquidGlass
                        ? ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0)
                        : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            _testMessage,
                            style: TextStyle(
                              color: dynamicTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              if (settings.haptic) HapticFeedback.lightImpact();
                              if (settings.confirmBehavior == 'long') {
                                setState(() => _testMessage = '⚠️ 長押ししてください');
                              } else if (settings.confirmBehavior == 'double') {
                                setState(
                                  () => _testMessage = '⚠️ ダブルタップしてください',
                                );
                              } else {
                                setState(
                                  () => _testMessage = '✅ 確定しました (通常タップ)',
                                );
                                if (settings.haptic) {
                                  HapticFeedback.mediumImpact();
                                }
                              }
                            },
                            onDoubleTap: () {
                              if (settings.confirmBehavior == 'double') {
                                setState(
                                  () => _testMessage = '✅ 確定しました (ダブルタップ)',
                                );
                                if (settings.haptic) {
                                  HapticFeedback.heavyImpact();
                                }
                              }
                            },
                            onLongPress: () {
                              if (settings.confirmBehavior == 'long') {
                                setState(() => _testMessage = '✅ 確定しました (長押し)');
                                if (settings.haptic) {
                                  HapticFeedback.heavyImpact();
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: accentPink,
                                borderRadius: BorderRadius.circular(16),
                                // 影も少し控えめに調整
                                boxShadow: [
                                  BoxShadow(
                                    color: accentPink.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                // ★ 落ち着いたローズピンクには、純白の文字が最も美しく映えます
                                child: Text(
                                  'テスト用：試合終了ボタン',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
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

  // ignore: unused_element
  Widget _buildPresetCard(
    String title,
    String preset,
    IconData? icon,
    bool isActive,
    SettingsNotifier notifier, {
    String? customAsset,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicTextColor = isDark ? Colors.white : textIndigo;
    final Color dynamicCardColor = isDark
        ? const Color(0xFF161B22)
        : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact(); // ignore: deprecated_member_use
          notifier.applyPreset(preset);
          setState(() => _testMessage = 'プリセットを変更しました');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive
                ? accentPink.withValues(alpha: 0.15)
                : dynamicCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? accentPink : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                Icon(
                  icon,
                  color: isActive ? dynamicTextColor : Colors.grey.shade400,
                  size: 28,
                ),

              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? dynamicTextColor : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
    final Color dynamicCardColor = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(_buildDivider(context));
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dynamicCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: spacedChildren),
      ),
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

  Widget _buildListTile(
    BuildContext context, {
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
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: dynamicTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    bool value,
    Function(bool) onChanged, {
    required IconData icon,
    required Color iconBgColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildListTile(
      context,
      title: title,
      icon: icon,
      iconBgColor: iconBgColor,
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: Colors.green, // iOS風の緑
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: isDark
            ? const Color(0xFF38383A)
            : const Color(0xFFE9E9EA),
        onChanged: (val) {
          if (value != val) HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
      indent: 56,
      endIndent: 0,
    );
  }

  // ログアウト確認ダイアログ
  // ignore: unused_element
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
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ★ 隠蔽領域 (Hidden Features)
  // 過去のレガシー機能や、将来の復元に備えてウィジェットツリーから切り離されたコンポーネント群
  // ============================================================================

  // ignore: unused_element
  List<Widget> _buildHiddenAdminSections(BuildContext context) {
    final currentRole = ref.watch(currentUserRoleProvider);
    return [
      // ==========================================
      // 内部特権領域 (Admin専用機能)
      // ==========================================
      if (FeatureGate.canUseAI(currentRole) ||
          FeatureGate.canAccessMetrics(currentRole)) ...[
        _buildSectionHeader(context, '内部特権・開発機能 (Admin専用)'),
        _buildSettingsBlock(context, [
          if (FeatureGate.canUseAI(currentRole))
            _buildSwitchTile(
              context,
              'AI自動判定・ガバナンスエンジン',
              false,
              (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stage2 β版では設定固定されています')),
                );
              },
              icon: Icons.smart_toy,
              iconBgColor: Colors.deepPurple,
            ),
          if (FeatureGate.canAccessMetrics(currentRole))
            _buildSwitchTile(
              context,
              '内部メトリクス・ダッシュボード',
              false,
              (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stage2 β版では設定固定されています')),
                );
              },
              icon: Icons.analytics,
              iconBgColor: Colors.blueGrey,
            ),
        ]),
        _buildSectionFooter(
          context,
          'これらの機能はシステム管理者のみに解放されています。一般ユーザーや運用者の画面には表示されません。',
        ),
      ],
    ];
  }
}
