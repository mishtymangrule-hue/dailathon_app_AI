import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/login/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/dialer/screens/dialer_screen.dart';
import 'features/in_call/screens/screens.dart';
import 'features/call_log/screens/recents_screen.dart';
import 'features/contacts/screens/contacts_screen.dart';
import 'features/admission_calling/screens/degree_list_screen.dart';
import 'features/admission_calling/screens/response_list_screen.dart';
import 'features/admission_calling/screens/sub_response_list_screen.dart';
import 'features/admission_calling/screens/student_list_screen.dart';
import 'features/settings/screens/settings_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Error: ${state.error}'),
    ),
  ),
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
      name: 'login',
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      name: 'home',
    ),
    GoRoute(
      path: '/dialer',
      builder: (context, state) => const DialerScreen(),
      name: 'dialer',
    ),
    GoRoute(
      path: '/in-call',
      builder: (context, state) => const ActiveCallScreen(),
      name: 'in-call',
    ),
    GoRoute(
      path: '/incoming',
      builder: (context, state) => const IncomingCallScreen(),
      name: 'incoming',
    ),
    GoRoute(
      path: '/recents',
      builder: (context, state) => const RecentsScreen(),
      name: 'recents',
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
      name: 'contacts',
    ),
    GoRoute(
      path: '/admission',
      builder: (context, state) => const DegreeListScreen(),
      name: 'admission',
      routes: [
        GoRoute(
          path: ':degreeId/responses',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ResponseListScreen(
              degreeId: state.pathParameters['degreeId']!,
              degreeName: extra?['degreeName'] as String?,
            );
          },
          name: 'admission-responses',
          routes: [
            GoRoute(
              path: ':responseId/sub',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return SubResponseListScreen(
                  degreeId: state.pathParameters['degreeId']!,
                  responseId: state.pathParameters['responseId']!,
                  responseName: extra?['responseName'] as String?,
                );
              },
              name: 'admission-sub-responses',
              routes: [
                GoRoute(
                  path: ':subResponseId/students',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return StudentListScreen(
                      degreeId: state.pathParameters['degreeId']!,
                      responseId: state.pathParameters['responseId']!,
                      subResponseId: state.pathParameters['subResponseId']!,
                      subResponseName:
                          extra?['subResponseName'] as String?,
                    );
                  },
                  name: 'admission-students',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/tg',
      builder: (context, state) => const TgCallingScreen(),
      name: 'tg-calling',
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      name: 'settings',
    ),
  ],
);

/// Placeholder TG Calling screen for now
class TgCallingScreen extends StatelessWidget {
  const TgCallingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('TG Calling'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('TG Calling Module - Coming Soon'),
      ),
    );
}
