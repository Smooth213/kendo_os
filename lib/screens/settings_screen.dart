import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _testMessage = '下のボタンをタップしてテスト';
  
  // ★ カラーパレットの定義（目立ちすぎない、上品で落ち着いたローズピンクへ調整）
  static const Color accentPink = Color(0xFFE06287); 
  static const Color textIndigo = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // iOS Native: True Black & Elevation
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // iOS Native カラーパレット
    final Color dynamicTextColor = isDark ? Colors.white : Colors.black;
    final Color dynamicBgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color dynamicCardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    
    // AppBarの文字色（ライト時はインディゴではなく黒に合わせるのがiOS風）
    final Color headerTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: dynamicBgColor,
      appBar: AppBar(
        title: Text('システム設定', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: headerTextColor)),
        backgroundColor: Colors.transparent, // 透かしに変更
        foregroundColor: headerTextColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: headerTextColor),
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
                Text('用途に合わせて一括セット', style: TextStyle(color: dynamicTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPresetCard('公式大会', 'official', Icons.emoji_events, settings.confirmBehavior == 'long' && settings.isLocked, notifier),
                    const SizedBox(width: 8),
                    // ★ アイコンの代わりにカスタム画像パスを渡すため、Icons.sports_martial_arts を null にし、カスタム画像を有効にする
                    _buildPresetCard('大会・錬成会', 'renseikai', null, settings.confirmBehavior == 'double' && !settings.sound, notifier, customAsset: 'assets/kendo_icon.png'),
                    const SizedBox(width: 8),
                    _buildPresetCard('練習・道場', 'practice', Icons.home, settings.confirmBehavior == 'single' && !settings.haptic, notifier),
                  ],
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 2. 操作・安全設定セクション
                // ==========================================
                Text('操作・安全設定', style: TextStyle(color: dynamicTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildSettingsBlock([
                  _buildListTile(
                    title: '確定ボタンの挙動',
                    trailing: DropdownButton<String>(
                      value: settings.confirmBehavior,
                      underline: const SizedBox(),
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
                  _buildDivider(),
                  _buildSwitchTile('最終確定時の確認ダイアログ', settings.showConfirmDialog, (val) => notifier.updateField(showConfirmDialog: val)), // ★ 追加
                  _buildDivider(),
                  _buildSwitchTile('記録確定後の修正ロック', settings.isLocked, (val) => notifier.updateField(isLocked: val)),
                ]),
                const SizedBox(height: 24),

                // ==========================================
                // 3. フィードバックセクション
                // ==========================================
                Text('フィードバック', style: TextStyle(color: dynamicTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildSettingsBlock([
                  _buildSwitchTile('触覚フィードバック (システム)', settings.haptic, (val) => notifier.updateField(haptic: val)),
                  _buildDivider(),
                  _buildSwitchTile('打突時の振動 (コッ)', settings.strikeVib, (val) => notifier.updateField(strikeVib: val)),
                  _buildDivider(),
                  _buildSwitchTile('操作サウンド (ピッ)', settings.sound, (val) => notifier.updateField(sound: val)),
                ]),
                const SizedBox(height: 24),

                // ==========================================
                // 4. システム・表示セクション
                // ==========================================
                Text('システム・表示', style: TextStyle(color: dynamicTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildSettingsBlock([
                  _buildSwitchTile('スリープ(画面消灯)防止', settings.sleepPrevent, (val) => notifier.updateField(sleepPrevent: val)),
                  _buildDivider(),
                  _buildSwitchTile('左利きモード (赤白ボタン反転)', settings.leftHanded, (val) => notifier.updateField(leftHanded: val)),
                  _buildDivider(),
                  // ★ ダークモード設定の追加
                  _buildListTile(
                    title: 'ダークモード対応',
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
                        if (val != null) {
                          // ★ 正しいメソッド名と引数で呼び出し
                          ref.read(settingsProvider.notifier).updateField(themeMode: val);
                        }
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // ==========================================
          // 5. テスト用インタラクティブエリア（画面下部固定）
          // ==========================================
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dynamicCardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
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
        ],
      ),
    );
  }

  // --- UI構築用ヘルパーメソッド ---

  // ★ customAsset 引数を追加し、IconDataがnullの場合は画像を読み込むように拡張
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
              // ★ customAsset が指定されていれば画像を、そうでなければ標準アイコンを描画
              if (customAsset != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0), // 上下のバランス調整
                  child: Image.asset(
                    customAsset,
                    width: 34, // ★ 28から34へ拡大し、他2つのアイコンとボリューム感を合わせる
                    height: 34,
                    // 選択状態に応じて色を変える（薄いグレーか、深いインディゴか）
                    color: isActive ? dynamicTextColor : Colors.grey.shade400,
                  ),
                )
              else if (icon != null)
                Icon(icon, color: isActive ? dynamicTextColor : Colors.grey.shade400, size: 28),
              
              const SizedBox(height: 8),
              Text(
                title, 
                style: TextStyle(color: isActive ? dynamicTextColor : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 1, // 文字が溢れないように1行に制限
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsBlock(List<Widget> children) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicCardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: dynamicCardColor,
        borderRadius: BorderRadius.circular(12), // iOS標準の角丸
        // iOS Native はカードに影をつけない
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required String title, required Widget trailing}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicTextColor = isDark ? Colors.white : Colors.black; // textIndigo廃止

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: dynamicTextColor, fontSize: 16, fontWeight: FontWeight.w500)), // iOS風に少しフォント調整
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildListTile(
      title: title,
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.white, 
        activeTrackColor: accentPink, 
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: isDark ? const Color(0xFF38383A) : Colors.grey.shade200, // iOS風の非アクティブ色
        onChanged: (val) {
          if (value != val) HapticFeedback.lightImpact();
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildDivider() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // iOS標準の区切り線の色と細さ
    return Divider(height: 1, thickness: 0.5, color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8), indent: 16, endIndent: 0);
  }
}