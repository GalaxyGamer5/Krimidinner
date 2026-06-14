import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/account_screen.dart';
import '../screens/case_detail_screen.dart';
import '../screens/cases_screen.dart';
import '../screens/home_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/lobbies_screen.dart';
import '../screens/lobby_room_screen.dart';
import '../screens/roles_screen.dart';
import '../widgets/mystery_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: '/join/:code',
        redirect: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return '/lobbies?invite=$code';
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MysteryShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/hub',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/cases',
            builder: (context, state) => const CasesScreen(),
            routes: [
              GoRoute(
                path: ':caseId',
                builder: (context, state) => CaseDetailScreen(
                  caseId: state.pathParameters['caseId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/lobbies',
            builder: (context, state) => LobbiesScreen(
              prefilledCode: state.uri.queryParameters['invite'],
            ),
            routes: [
              GoRoute(
                path: 'room/:code',
                builder: (context, state) => LobbyRoomScreen(
                  code: state.pathParameters['code'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/roles',
            builder: (context, state) => const RolesScreen(),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
});
