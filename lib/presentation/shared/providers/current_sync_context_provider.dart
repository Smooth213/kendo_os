import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/sync/current_sync_context.dart';
import '../../../domain/entities/user_role.dart';
import '../../../core/security/pwa_storage_bridge.dart';
import 'auth_session_provider.dart';

String _getOrCreateDeviceId() {
  try {
    final saved = PwaStorage.getItem('kendo_os_device_id');
    if (saved != null && saved.isNotEmpty) return saved;

    final randomStr = List.generate(4, (_) => Random().nextInt(1000000).toString().padLeft(6, '0')).join('-');
    final newId = 'dev-$randomStr';
    PwaStorage.setItem('kendo_os_device_id', newId);
    return newId;
  } catch (_) {
    return 'dev-memory-${Random().nextInt(999999)}';
  }
}

final currentDojoIdProvider = StateProvider<String>((ref) {
  try {
    final saved = PwaStorage.getItem('kendo_os_active_dojo_id');
    return (saved != null && saved.isNotEmpty) ? saved : 'default_dojo_room';
  } catch (_) {
    return 'default_dojo_room';
  }
});

final currentSyncContextProvider = Provider<CurrentSyncContext>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final session = ref.watch(authSessionProvider);
  final UserRole activeRole = (session != null && !session.isExpired) ? session.role : UserRole.viewer;
  final deviceId = _getOrCreateDeviceId();

  return CurrentSyncContext(
    organizationId: dojoId,
    role: activeRole,
    deviceId: deviceId,
  );
});