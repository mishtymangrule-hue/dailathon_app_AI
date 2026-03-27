import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/models/call_info.dart';
import 'core/theme/app_theme.dart';
import 'features/admission_calling/screens/degree_list_screen.dart';
import 'features/admission_calling/screens/response_list_screen.dart';
import 'features/admission_calling/screens/student_list_screen.dart';
import 'features/admission_calling/screens/sub_response_list_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/call_log/screens/recents_screen.dart';
import 'features/contacts/screens/contacts_screen.dart';
import 'features/dialer/screens/dialer_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/in_call/screens/screens.dart';
import 'features/notifications/screens/notification_centre_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/shell/screens/main_shell.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Error: ${state.error}')),
  ),
  routes: [
    // ── Full-screen routes (no bottom nav shell) ───────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final returnTo = state.uri.queryParameters['returnTo'];
        return LoginScreen(returnTo: returnTo);
      },
    ),
    GoRoute(
      path: '/in-call',
      name: 'in-call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final callInfo = extra?['callInfo'] as CallInfo?;
        if (callInfo == null) {
          return const Scaffold(
            body: Center(child: Text('No active call')),
          );
        }
        return ActiveCallScreen(callInfo: callInfo);
      },
    ),
    GoRoute(
      path: '/incoming',
      name: 'incoming',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final phoneNumber = extra?['phoneNumber'] as String? ?? '';
        return IncomingCallScreen(
          phoneNumber: phoneNumber,
          displayName: extra?['displayName'] as String?,
          callId: extra?['callId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationCentreScreen(),
    ),
    GoRoute(
      path: '/tg',
      name: 'tg-calling',
      builder: (context, state) => const TgCallingScreen(),
    ),
    // Admission Calling — full screen flow (login-gated)
    GoRoute(
      path: '/admission',
      name: 'admission',
      builder: (context, state) => const DegreeListScreen(),
      routes: [
        GoRoute(
          path: ':degreeId/responses',
          name: 'admission-responses',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ResponseListScreen(
              degreeId: state.pathParameters['degreeId']!,
              degreeName: extra?['degreeName'] as String?,
            );
          },
          routes: [
            GoRoute(
              path: ':responseId/sub',
              name: 'admission-sub-responses',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return SubResponseListScreen(
                  degreeId: state.pathParameters['degreeId']!,
                  responseId: state.pathParameters['responseId']!,
                  responseName: extra?['responseName'] as String?,
                );
              },
              routes: [
                GoRoute(
                  path: ':subResponseId/students',
                  name: 'admission-students',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return StudentListScreen(
                      degreeId: state.pathParameters['degreeId']!,
                      responseId: state.pathParameters['responseId']!,
                      subResponseId:
                          state.pathParameters['subResponseId']!,
                      subResponseName:
                          extra?['subResponseName'] as String?,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Bottom-nav shell (4 persistent tabs) ──────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dialer',
            name: 'dialer',
            builder: (context, state) => const DialerScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/contacts',
            name: 'contacts',
            builder: (context, state) => const ContactsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/recents',
            name: 'recents',
            builder: (context, state) => const RecentsScreen(),
          ),
        ]),
      ],
    ),
  ],
);

/// Placeholder TG Calling screen.
class TgCallingScreen extends StatelessWidget {
  const TgCallingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('TG Calling')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bg,
                shape: BoxShape.circle,
                boxShadow: AppTheme.raisedShadow(distance: 6, blur: 18),
              ),
              child: const Icon(Icons.people_outline_rounded,
                  color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('TG Calling', style: TextStyle(
              color: AppTheme.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Module coming soon',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
}
