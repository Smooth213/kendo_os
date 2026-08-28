import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_floating_action_bar.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// 📄 クイックガイドPDF表示タブビュー（純粋UIコンポーネント）
class ManualQuickGuideTabView extends StatelessWidget {
  final String assetPath;
  final String fileName;
  final VoidCallback onPrintPressed;
  final VoidCallback onSharePressed;
  final bool isDark;

  const ManualQuickGuideTabView({
    super.key,
    required this.assetPath,
    required this.fileName,
    required this.onPrintPressed,
    required this.onSharePressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SfPdfViewer.asset(
          assetPath,
          onDocumentLoadFailed: (details) {
            debugPrint('Asset load failed: ${details.description}');
          },
        ),
        Positioned(
          bottom: AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          child: ManualFloatingActionBar(
            primaryLabel: 'A4印刷',
            primaryIcon: Icons.print,
            onPrimaryPressed: onPrintPressed,
            secondaryLabel: '共有/保存',
            secondaryIcon: Icons.ios_share,
            onSecondaryPressed: onSharePressed,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
