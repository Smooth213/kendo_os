import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🏆 プログラムビューア: 材料データ（URL未生成・オフライン保護）プレースホルダーカード
class ProgramViewerMaterialPlaceholder extends StatelessWidget {
  final ProgramModel program;
  final bool isDark;

  const ProgramViewerMaterialPlaceholder({
    super.key,
    required this.program,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: AppRadius.large,
          border: Border.all(color: context.appColors.separatorColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              program.fileType == 'pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_not_supported_outlined,
              size: 64,
              color: context.appColors.primaryAccent,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              program.title,
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '【材料データ同期済み】\nオフラインファースト最適化の規約に基づき、通信帯域を圧迫する実ファイル（バイナリ）の自動ロードは行われません。プログラムの構成情報は安全に保護されています。',
              style: TextStyle(
                fontSize: AppFontSize.small,
                color: context.appColors.subTextColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
