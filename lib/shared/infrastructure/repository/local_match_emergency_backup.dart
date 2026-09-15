import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveEmergencyBackupWithRotation(MatchModel match) async {
  await TwinMatchPersistenceHelper.saveSnapshot(match);
  if (kIsWeb) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final backupFiles =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('twin_snapshot_${match.id}_'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    if (backupFiles.length > 3) {
      for (final oldFile in backupFiles.sublist(3)) {
        try {
          oldFile.deleteSync();
        } catch (_) {}
      }
    }
  } catch (_) {}
}
