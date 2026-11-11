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
import 'package:kendo_os/features/viewer/presentation/screens/viewer_share_expired_screen.dart';
import 'package:kendo_os/security/dojo_join_access_storage.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/security/viewer_share_repository.dart';
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
    final currentDojoId = ref.watch(currentDojoIdProvider);
    final isFullDojoSession =
        session != null &&
        !session.isExpired &&
        !session.isShareScoped &&
        (session.dojoId.isEmpty || session.dojoId == currentDojoId);

    // 🌟 セッション先行判定：既に正規の道場入室・ロール認証を通過している場合は即座に表示
    // （1大会限定の共有リンクセッションは '/' へのアクセスを許可せず RoleSelectScreen へ誘導）
    if (isFullDojoSession) {
      return child;
    }
    if (session != null && session.isShareScoped) {
      return const RoleSelectScreen();
    }

    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return const RoleSelectScreen();
        }
        if (Firebase.apps.isNotEmpty &&
            currentDojoId.isNotEmpty &&
            currentDojoId != 'default_dojo_room' &&
            !DojoJoinAccessStorage.hasJoinProof(currentDojoId)) {
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
  final String? shareToken;

  const RoleInjector({
    super.key,
    required this.child,
    this.roleStr,
    this.dojoId,
    this.tournamentId,
    this.shareToken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDojoId = ref.read(currentDojoIdProvider);
    final currentTournamentId = ref.read(webCurrentTournamentIdProvider);

    if (dojoId != null && dojoId!.isNotEmpty && currentDojoId != dojoId) {
      Future.microtask(() {
        ref.read(currentDojoIdProvider.notifier).state = dojoId!;
        debugPrint('[Role Injector] テナントID($dojoId)確定');
      });
    }

    if (kIsWeb &&
        tournamentId != null &&
        tournamentId!.isNotEmpty &&
        currentTournamentId != tournamentId) {
      Future.microtask(() {
        ref.read(webCurrentTournamentIdProvider.notifier).state = tournamentId!;
        debugPrint('[Role Injector] 大会ID($tournamentId)確定');
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
        child: ViewerAuthGate(
          dojoId: dojoId ?? currentDojoId,
          tournamentId: tournamentId,
          shareToken: shareToken,
          child: child,
        ),
      );
    }

    return child;
  }
}

/// 🛡️ ビュアー用認証防壁ゲート
/// 未認証（request.auth == null）の状態で Firestore クエリが走るのを防ぎ、
/// 共有リンク（1大会限定・有効期限付き）のトークン検証も同時に執行する。
class ViewerAuthGate extends ConsumerStatefulWidget {
  final Widget child;
  final String? dojoId;
  final String? tournamentId;
  final String? shareToken;

  const ViewerAuthGate({
    super.key,
    required this.child,
    this.dojoId,
    this.tournamentId,
    this.shareToken,
  });

  @override
  ConsumerState<ViewerAuthGate> createState() => _ViewerAuthGateState();
}

class _ViewerAuthGateState extends ConsumerState<ViewerAuthGate> {
  bool _isReady = false;
  ViewerShareAccessStatus? _blockedStatus;

  @override
  void initState() {
    super.initState();
    _checkAndEnsureAuth();
  }

  Future<void> _checkAndEnsureAuth() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (mounted) setState(() => _isReady = true);
        return;
      }

      // 匿名認証を確立（最大4秒待機）
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: 4),
        );
      }

      final dojoId = widget.dojoId ?? '';
      final tournamentId = widget.tournamentId ?? '';
      final token = widget.shareToken ?? '';
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (dojoId.isNotEmpty &&
          dojoId != 'default_dojo_room' &&
          dojoId != 'default_org' &&
          uid != null) {
        final session = ref.read(authSessionProvider);
        final isFullDojoViewer =
            DojoJoinAccessStorage.hasJoinProof(dojoId) ||
            (session != null && session.isAuthorizedForDojo(dojoId));

        if (!isFullDojoViewer) {
          final shareRepo = ref.read(viewerShareRepositoryProvider);
          final secRepo = ref.read(dojoSecurityRepositoryProvider);

          if (token.isNotEmpty && shareRepo != null) {
            final res = await shareRepo.verifyAndActivateShareLink(
              dojoId: dojoId,
              tournamentId: tournamentId,
              token: token,
              uid: uid,
            );
            if (!res.isAllowed) {
              if (mounted) {
                setState(() {
                  _blockedStatus = res.status;
                  _isReady = true;
                });
              }
              return;
            }
            ref
                .read(authSessionProvider.notifier)
                .establishShareSession(
                  dojoId: dojoId,
                  tournamentId: tournamentId,
                  shareToken: token,
                );
          } else if (secRepo != null) {
            final roomStatus = await secRepo.inspectRoomStatus(dojoId);
            if (roomStatus == DojoJoinStatus.requiresPin) {
              if (mounted) {
                setState(() {
                  _blockedStatus = ViewerShareAccessStatus.invalid;
                  _isReady = true;
                });
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[WARN] [ViewerAuthGate] 認証・共有トークン検証エラー: $e');
    }

    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockedStatus != null) {
      return ViewerShareExpiredScreen(status: _blockedStatus!);
    }

    if (_isReady) {
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
