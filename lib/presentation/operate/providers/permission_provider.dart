import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'role_provider.dart';

class AppPermissions {
  final bool canManageTournament;
  final bool canCreateMatch;
  final bool isReadOnly;

  const AppPermissions({
    required this.canManageTournament,
    required this.canCreateMatch,
    required this.isReadOnly,
  });
}

final permissionProvider = Provider<AppPermissions>((ref) {
  final role = ref.watch(activeRoleProvider);

  switch (role) {
    case Role.admin:
      return const AppPermissions(canManageTournament: true, canCreateMatch: true, isReadOnly: false);
    case Role.scorer:
      return const AppPermissions(
        canManageTournament: false, // ★ 大会作成はNG
        canCreateMatch: true,      // ★ 試合作成はOK
        isReadOnly: false,
      );
    case Role.editor:
      return const AppPermissions(canManageTournament: false, canCreateMatch: false, isReadOnly: false);
    default:
      return const AppPermissions(canManageTournament: false, canCreateMatch: false, isReadOnly: true);
  }
});