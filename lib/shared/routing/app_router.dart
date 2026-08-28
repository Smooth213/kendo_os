import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/auth/presentation/screens/pin_auth_screen.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/court_status_board_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/create_tournament_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/tournament_list_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/screens/standings_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/routing/match_router.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = ref.watch(authSessionProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          if (session != null && session.role == UserRole.viewer) {
            return child;
          }
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

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/role-select',
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('ページが見つかりません: ${state.uri}'))),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGuard(child: StartScreen()),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/pin-auth',
      builder: (context, state) {
        final roleStr = state.uri.queryParameters['role'] ?? 'viewer';
        final role = UserRole.values.firstWhere(
          (e) => e.name == roleStr,
          orElse: () => UserRole.viewer,
        );
        return PinAuthScreen(role: role);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/master',
      builder: (context, state) => const MasterManagementScreen(),
    ),
    GoRoute(
      path: '/tournament-list',
      builder: (context, state) {
        final isArchive = state.extra as bool? ?? false;
        final screen = TournamentListScreen(isArchive: isArchive);
        if (isArchive) {
          return AppThemeModeWrapper(mode: 'normal_viewer', child: screen);
        }
        return screen;
      },
    ),
    GoRoute(
      path: '/viewer/:id',
      builder: (context, state) => AppThemeModeWrapper(
        mode: 'normal_viewer',
        child: ViewerMatchScreen(matchId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: HomeScreen(tournamentId: state.pathParameters['tournamentId']!),
      ),
    ),
    GoRoute(
      path: '/tournament/:id/programs',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['id']!,
        child: ProgramManagementScreen(
          tournamentId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/program-viewer',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return RoleInjector(
          roleStr: state.uri.queryParameters['role'],
          dojoId: state.uri.queryParameters['dojoId'],
          tournamentId: state.uri.queryParameters['tournamentId'],
          child: ProgramViewerScreen(
            programs: args['programs'] as List<ProgramModel>,
            initialIndex: args['index'] as int,
          ),
        );
      },
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: MatchRouter(matchId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/team-scoreboard/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: TeamScoreboardScreen(
          groupName: state.pathParameters['groupName']!,
        ),
      ),
    ),
    GoRoute(
      path: '/court-status',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: CourtStatusBoardScreen(
          tournamentId: state.uri.queryParameters['tournamentId'],
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerHomeScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-record/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerOfficialRecordScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-team/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerTeamScoreboardScreen(
            groupName: state.pathParameters['groupName']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/viewer-kachinuki/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: AppThemeModeWrapper(
          mode: 'normal_viewer',
          child: ViewerKachinukiScoreboardScreen(
            groupName: state.pathParameters['groupName']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/kachinuki-scoreboard/:groupName',
      builder: (context, state) => RoleInjector(
        roleStr: state.uri.queryParameters['role'],
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.uri.queryParameters['tournamentId'],
        child: KachinukiScoreboardScreen(
          groupName: state.pathParameters['groupName']!,
        ),
      ),
    ),
    GoRoute(
      path: '/create-tournament',
      builder: (context, state) => const CreateTournamentScreen(),
    ),
    GoRoute(
      path: '/setup-match/:id',
      builder: (context, state) =>
          SetupMatchFormatScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/order-setup/:id',
      builder: (context, state) =>
          OrderSetupScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/team-registration/:id',
      builder: (context, state) =>
          TeamRegistrationScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/standings/:id',
      builder: (context, state) =>
          StandingsScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/official-record/:id',
      builder: (context, state) =>
          OfficialRecordScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/tournament/:id/category-rules',
      builder: (context, state) {
        final isFromSetup = state.uri.queryParameters['isFromSetup'] == 'true';
        return CategoryRulesScreen(
          tournamentId: state.pathParameters['id']!,
          isFromSetup: isFromSetup,
        );
      },
    ),
    GoRoute(
      path: '/bunaiksen-home',
      builder: (context, state) => const AppThemeModeWrapper(
        mode: 'bunaiksen',
        child: BunaiksenHomeScreen(),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-setup',
      builder: (context, state) => const AppThemeModeWrapper(
        mode: 'bunaiksen',
        child: BunaiksenSetupScreen(),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-record',
      builder: (context, state) => const AppThemeModeWrapper(
        mode: 'bunaiksen',
        child: BunaiksenOfficialRecordScreen(),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-viewer-home/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: 'viewer',
        dojoId: state.uri.queryParameters['dojoId'],
        tournamentId: state.pathParameters['tournamentId']!,
        child: AppThemeModeWrapper(
          mode: 'bunaiksen_viewer',
          child: ViewerBunaiksenHomeScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/bunaiksen-viewer-record/:tournamentId',
      builder: (context, state) => RoleInjector(
        roleStr: 'viewer',
        dojoId: state.uri.queryParameters['dojoId'],
        child: AppThemeModeWrapper(
          mode: 'bunaiksen_viewer',
          child: ViewerBunaiksenOfficialRecordScreen(
            tournamentId: state.pathParameters['tournamentId']!,
          ),
        ),
      ),
    ),
  ],
);

final routeObserverProvider = Provider<void>((ref) {
  void listener() {
    final location = appRouter.routeInformationProvider.value.uri.path;
    final targetMode = location.contains('master')
        ? OperationMode.local
        : OperationMode.tournament;
    if (ref.read(operationModeProvider) != targetMode) {
      Future.microtask(() {
        ref.read(operationModeProvider.notifier).state = targetMode;
      });
    }
  }

  listener();
  appRouter.routerDelegate.addListener(listener);
  ref.onDispose(() => appRouter.routerDelegate.removeListener(listener));
});
