import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/permission_provider.dart';
import '../../shared/widgets/liquid_background.dart'; // ★ 追加
import '../../shared/widgets/glass_button.dart';

// ★ シンプルなConsumerWidgetに戻りました（波紋アニメーションはFlutter標準に任せます）
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  // ★ 内部画面の「カード」と同じデザイン言語で作られたアクションボタン
  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // iOS Native: ダークモード時の色調整
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;

    return GlassButton.custom(
      onPressed: onTap,
      color: color,
      surfaceColor: Colors.white, // 背景のベースを白にする
      glassAlpha: isDark ? 0.08 : 0.5, // ライトモード時は白を強めに、ダークモード時はうっすらと白を入れる
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1), // ダーク時は少しアイコン背景を明るくして視認性を上げる
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor, height: 1.3)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // iOS Native: ダークモード時はヘッダーのグラデーションを深みのある色に
    final headerStartColor = isDark ? Colors.indigo.shade900 : Colors.indigo.shade700;
    final headerEndColor = isDark ? const Color(0xFF1A237E) : Colors.blue.shade500;

    return LiquidBackground( // ★ 全体をLiquidBackgroundでラップ
      child: Scaffold(
        backgroundColor: Colors.transparent, // ★ 背景を透明にして下の光のオーブを透かす
        body: Column(
          children: [
            // ★ 内部画面（home_screen等）のAppBarと完全にリンクする、美しいグラデーションの巨大ヘッダー
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 32, // ノッチやステータスバーを避ける
                bottom: 48,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerStartColor, headerEndColor], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kendo Sync', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                      // ★ 設定アイコンはここに配置
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                        onPressed: () {
                          context.push('/settings');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('大会の作成・管理をここから始めましょう', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
                  // ★ 追加：部内戦・申し合わせへの特急ガラスボタン（ホーム画面を経由）
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/bunaiksen-home'),
                      icon: const Icon(Icons.local_fire_department, color: Colors.white),
                      label: const Text('部内戦をはじめる', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
  
            // ★ 2x2の美しいカードグリッドと、余白を引き締めるアンカー（フッター）
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -24), // 上に24pxずらして重ねる
                child: CustomScrollView( // ★ ListViewからCustomScrollViewへ変更し、余白を完全に制御
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            children: [
                              // ★ Phase 8: 記録係（Scorer）には大会作成ボタンを見せない
                              if (permissions.canManageTournament) ...[
                                Expanded(
                                  // ★ 直感UX改修：オレンジから「Emerald Green (Teal)」へ変更し、ウィザードへの入り口を色彩でリンクさせる
                                  child: _buildActionCard(context, icon: Icons.add_circle, title: '新しい大会\nを作る', subtitle: '大会・錬成会', color: Colors.teal.shade600, onTap: () => context.push('/create-tournament')),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: _buildActionCard(context, icon: Icons.list_alt, title: '今日の試合\nを作る・見る', subtitle: '試合進行・記録', color: Colors.indigo.shade600, onTap: () => context.push('/tournament-list', extra: false)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(context, icon: Icons.history, title: '過去の大会\nを見る', subtitle: 'アーカイブ', color: Colors.blueGrey.shade600, onTap: () => context.push('/tournament-list', extra: true)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(context, icon: Icons.manage_accounts, title: '選手名簿\n(マスタ) 管理', subtitle: '道場生データ', color: Colors.purple.shade600, onTap: () => context.push('/master')),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                    // ★ 修正：LayoutBuilderの複雑な計算を廃止し、確実に描画される安全な固定サイズ＋フレックス余白を採用
                    SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 48), // Transformのズレを吸収するために下部余白を厚めにする
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/kendo_icon.png', 
                              width: 72,
                              height: 72, 
                              color: Colors.grey.shade400.withValues(alpha: 0.2), 
                            ),
                            const SizedBox(height: 12), 
                            Text(
                              'Kendo Sync v1.0.0', 
                              style: TextStyle(
                                color: Colors.grey.shade400, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.5 
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}