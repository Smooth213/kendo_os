import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';

class MatchFloatingDockEntry extends StatelessWidget {
  final String? tournamentId;
  final bool isViewOnly;

  const MatchFloatingDockEntry({
    super.key,
    required this.tournamentId,
    required this.isViewOnly,
  });

  @override
  Widget build(BuildContext context) {
    if (DockSheetScope.of(context) != null) return const SizedBox.shrink();
    final tid = tournamentId;
    if (tid == null || tid.isEmpty) return const SizedBox.shrink();

    if (tid.startsWith('bunaiksen_')) {
      return BunaiksenDockButton(tournamentId: tid, isViewerMode: isViewOnly);
    }

    return FloatingProgramDockButton(
      tournamentId: tid,
      isViewerMode: isViewOnly,
    );
  }
}
