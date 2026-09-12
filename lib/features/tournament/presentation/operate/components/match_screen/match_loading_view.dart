import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

class MatchLoadingView extends StatelessWidget {
  const MatchLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: '試合読み込み中...'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            const Text('試合データを取得しています...'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
