import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦 チーム別（赤/白）メンバー配置リストWidget（DragTarget対応）
class BunaiksenTeamMemberList extends StatelessWidget {
  final int teamSize;
  final List<String?> teamMembers;
  final List<String> positions;
  final Color teamColor;
  final bool isDark;
  final void Function(int index, String playerName) onMemberAssigned;
  final void Function(int index) onMemberCleared;

  const BunaiksenTeamMemberList({
    super.key,
    required this.teamSize,
    required this.teamMembers,
    required this.positions,
    required this.teamColor,
    required this.isDark,
    required this.onMemberAssigned,
    required this.onMemberCleared,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: teamSize,
      itemBuilder: (context, index) {
        return DragTarget<String>(
          onAcceptWithDetails: (details) =>
              onMemberAssigned(index, details.data),
          builder: (context, candidateData, rejectedData) {
            return Card(
              color: candidateData.isNotEmpty
                  ? teamColor.withValues(alpha: 0.2)
                  : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC)),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: teamColor,
                  width: candidateData.isNotEmpty ? 2 : 1,
                ),
                borderRadius: AppRadius.large,
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: teamColor,
                  radius: 14,
                  child: Text(
                    positions[index].substring(0, 1),
                    style: const TextStyle(
                      color: AppKendoColors.pureWhite,
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  teamMembers[index] ?? '未定',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: teamMembers[index] == null
                        ? (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B))
                        : (context.appColors.textColor),
                  ),
                ),
                onTap: () => onMemberCleared(index),
              ),
            );
          },
        );
      },
    );
  }
}
