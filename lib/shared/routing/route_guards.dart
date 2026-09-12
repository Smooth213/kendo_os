import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isSessionValid = session != null && !session.isExpired;

    // 🌟 セッション先行判定：既にPIN認証またはViewer選択を通過している場合は、
    // Firebase AuthのStream初期化遅延に関わらず即座にchildを表示し、強制送還ループを防ぐ
    if (isSessionValid) {
      return child;
    }

    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return const RoleSelectScreen();
        }
        return child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('エラー: $e'))),
    );
  }
}

class RoleInjector extends ConsumerWidget {
  final Widget child;
  final String? roleStr;
  final String? dojoId;
  final String? tournamentId;

  const RoleInjector({
    super.key,
    required this.child,
    this.roleStr,
    this.dojoId,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDojoId = ref.read(currentDojoIdProvider);
    final currentTournamentId = ref.read(webCurrentTournamentIdProvider);

    if (dojoId != null && dojoId!.isNotEmpty && currentDojoId != dojoId) {
      Future.microtask(() {
        ref.read(currentDojoIdProvider.notifier).state = dojoId!;
        debugPrint('🏢 [Role Injector] テナントID($dojoId)確定');
      });
    }

    if (kIsWeb &&
        tournamentId != null &&
        tournamentId!.isNotEmpty &&
        currentTournamentId != tournamentId) {
      Future.microtask(() {
        ref.read(webCurrentTournamentIdProvider.notifier).state = tournamentId!;
        debugPrint('🎯 [Role Injector] 大会ID($tournamentId)確定');
      });
    }

    if (roleStr == 'viewer') {
      return ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.viewer),
          activeRoleProvider.overrideWithValue(Role.viewer),
          permissionProvider.overrideWithValue(
            const PermissionState(role: UserRole.viewer, isReadOnly: true),
          ),
        ],
        child: child,
      );
    }

    return child;
  }
}
