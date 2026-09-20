import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

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
      final overrides = <Override>[
        currentUserRoleProvider.overrideWithValue(UserRole.viewer),
        activeRoleProvider.overrideWithValue(Role.viewer),
        permissionProvider.overrideWithValue(
          const PermissionState(role: UserRole.viewer, isReadOnly: true),
        ),
      ];

      return ProviderScope(
        overrides: overrides,
        child: ViewerAuthGate(child: child),
      );
    }

    return child;
  }
}

/// 🛡️ ビュアー用認証防壁ゲート
/// 未認証（request.auth == null）の状態で Firestore クエリが走るのを防ぐため、
/// 匿名認証または既存認証が確立するまでスピナーを表示して保護する。
class ViewerAuthGate extends StatefulWidget {
  final Widget child;

  const ViewerAuthGate({super.key, required this.child});

  @override
  State<ViewerAuthGate> createState() => _ViewerAuthGateState();
}

class _ViewerAuthGateState extends State<ViewerAuthGate> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAndEnsureAuth();
  }

  Future<void> _checkAndEnsureAuth() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (mounted) {
          setState(() => _isAuthenticated = true);
        }
        return;
      }

      // 既に認証済みなら即座に描画許可
      if (FirebaseAuth.instance.currentUser != null) {
        if (mounted) {
          setState(() => _isAuthenticated = true);
        }
        return;
      }

      // 匿名認証を確立（最大4秒待機）
      await FirebaseAuth.instance.signInAnonymously().timeout(
        const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('⚠️ [ViewerAuthGate] 匿名認証試行エラー/タイムアウト: $e');
    }

    // タイムアウトやエラーが発生した場合でも、後続のリカバリに委ねるため描画許可
    if (mounted) {
      setState(() => _isAuthenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasUser = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        hasUser = FirebaseAuth.instance.currentUser != null;
      }
    } catch (_) {}

    if (_isAuthenticated || hasUser) {
      return widget.child;
    }

    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppKendoColors.deepOrange,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              '大会データを読み込み中...',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: AppFontSize.body,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
