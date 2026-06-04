import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CorruptedMatchBanner extends ConsumerWidget {
  final String matchId;

  const CorruptedMatchBanner({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          // ★ Phase 7-1: ユーザー向け簡略文への縮退
          // 一般ユーザーや保護者の不安を完全に払拭するため、「破損」「Replay自動復旧」といったデバッグ文言や
          // 特権ボタンを完全にUIからパージし、ロードマップ指定の「データに問題が発生しました」のみに完全緊縛します。
          const Expanded(
            child: Text(
              'データに問題が発生しました',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
