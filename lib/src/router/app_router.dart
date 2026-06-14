import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/account_screen.dart';
import '../screens/case_detail_screen.dart';
import '../screens/cases_screen.dart';
import '../screens/game_session_screen.dart';
import '../screens/home_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/invitation_screen.dart';
import '../screens/lobbies_screen.dart';
import '../screens/lobby_room_screen.dart';
import '../screens/role_dossier_screen.dart';
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
          final inviteId = state.uri.queryParameters['invite'];
          if (inviteId != null && inviteId.isNotEmpty) {
            return '/invite/$inviteId?code=$code';
          }
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
                routes: [
                  GoRoute(
                    path: 'role/:roleId',
                    builder: (context, state) => RoleDossierScreen(
                      code: state.pathParameters['code'] ?? '',
                      roleId: state.pathParameters['roleId'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'play',
                    builder: (context, state) => GameSessionScreen(
                      code: state.pathParameters['code'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/invite/:invitationId',
            builder: (context, state) => InvitationScreen(
              invitationId: state.pathParameters['invitationId'] ?? '',
              lobbyCode: state.uri.queryParameters['code'] ?? '',
            ),
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
