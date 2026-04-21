import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/permission_provider.dart';

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
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200, width: 1.5), 
      ),
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1), 
        highlightColor: color.withValues(alpha: 0.05),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.grey.shade50;
    
    // iOS Native: ダークモード時はヘッダーのグラデーションを深みのある色に
    final headerStartColor = isDark ? Colors.indigo.shade900 : Colors.indigo.shade700;
    final headerEndColor = isDark ? const Color(0xFF1A237E) : Colors.blue.shade500;

    return Scaffold(
      backgroundColor: bgColor, 
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
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      onPressed: () {
                        context.push('/settings');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('大会の作成・管理をここから始めましょう', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
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
                                child: _buildActionCard(context, icon: Icons.add_circle, title: '新しい大会\nを作る', subtitle: '新規トーナメント', color: Colors.teal.shade600, onTap: () => context.push('/create-tournament')),
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
                  // ★ 残った下半分の「巨大な余白」を埋め尽くし、一番下にフッターを固定する魔法のウィジェット
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(), // 上部のカードとの間を可能な限り押し広げる
                        
                        // ★ 直感UX改修：タコ化問題を完全解決！
                        // サイズを大きくして「面」のディテール（面金）を視認可能にしつつ、
                        // 透明度を下げて背景に溶け込む「高級なウォーターマーク（透かし）」へと昇華！
                        Image.asset(
                          'assets/kendo_icon.png', 
                          width: 120,  // ★ 48 -> 120 へ思い切って拡大（面金が見えるサイズ）
                          height: 120, 
                          color: Colors.grey.shade400.withValues(alpha: 0.25), // ★ 透明度をかけて上品に背景へ沈ませる
                        ),
                        const SizedBox(height: 16), // アイコンとテキストの余白を少し広げる
                        Text(
                          'Kendo Sync v1.0.0', 
                          style: TextStyle(
                            color: Colors.grey.shade400, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1.5 // ★ 文字間隔を開けてよりスタイリッシュに
                          )
                        ),
                        const SizedBox(height: 40), // 画面一番下からの美しい余白
                      ],
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
}