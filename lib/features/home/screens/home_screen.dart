import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../bloc/home_bloc.dart';
import '../../notifications/bloc/notifications_bloc.dart';

/// Home / Modules Screen — stats dashboard + CRM module cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const CheckDefaultDialerRequested());
  }

  void _openAdmission() {
    if (AuthService.instance.isLoggedIn) {
      context.push('/admission');
    } else {
      context.push('/login?returnTo=%2Fadmission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Dailathon'),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (ctx, state) {
              final count =
                  state is NotificationsLoaded ? state.unreadCount : 0;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: AuthService.instance,
            builder: (_, __) {
              if (!AuthService.instance.isLoggedIn) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign out',
                onPressed: () {
                  AuthService.instance.logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────────────────────
            ListenableBuilder(
              listenable: AuthService.instance,
              builder: (_, __) {
                final auth = AuthService.instance;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.isLoggedIn
                          ? 'Welcome, ${auth.displayName.split(' ').first} 👋'
                          : 'Welcome back 👋',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.isLoggedIn ? auth.role : 'Telecom Dialer',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Today's stats ──────────────────────────────────────────────
            const Text(
              "Today's Activity",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: const [
                NeuStatCard(
                  label: 'Calls Made',
                  value: '47',
                  icon: Icons.phone_rounded,
                  color: AppTheme.primary,
                ),
                NeuStatCard(
                  label: 'Interested Leads',
                  value: '12',
                  icon: Icons.thumb_up_alt_rounded,
                  color: AppTheme.catInterested,
                ),
                NeuStatCard(
                  label: 'Visits',
                  value: '5',
                  icon: Icons.directions_walk_rounded,
                  color: AppTheme.warning,
                ),
                NeuStatCard(
                  label: 'Conversions',
                  value: '3',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Default dialer status banner ───────────────────────────────
            BlocBuilder<HomeBloc, HomeState>(
              builder: (ctx, state) {
                final isDefault =
                    state is HomeLoaded && state.isDefaultDialer;
                return NeuCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (isDefault
                                  ? AppTheme.success
                                  : AppTheme.info)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDefault
                              ? Icons.verified_rounded
                              : Icons.info_rounded,
                          color: isDefault
                              ? AppTheme.success
                              : AppTheme.info,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDefault
                                  ? 'Default Dialer Active'
                                  : 'Not Default Dialer',
                              style: TextStyle(
                                color: isDefault
                                    ? AppTheme.success
                                    : AppTheme.info,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              isDefault
                                  ? 'Receiving all incoming calls'
                                  : 'Tap Settings → Set as default dialer',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── CRM modules ────────────────────────────────────────────────
            const Text(
              'CRM Modules',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.school_rounded,
              title: 'Admission Calling',
              description:
                  'Manage student admissions, track leads and follow-ups',
              accentColor: AppTheme.primary,
              stats: const [
                _ModuleStat(label: 'Pending', value: '42'),
                _ModuleStat(label: 'Done Today', value: '18'),
                _ModuleStat(label: 'Interested', value: '9'),
              ],
              requiresLogin: true,
              onTap: _openAdmission,
            ),
            const SizedBox(height: 14),
            _ModuleCard(
              icon: Icons.people_rounded,
              title: 'TG Calling',
              description: 'Targeted group calling campaigns',
              accentColor: const Color(0xFF9C27B0),
              stats: const [
                _ModuleStat(label: 'Campaigns', value: '3'),
                _ModuleStat(label: 'Contacts', value: '218'),
                _ModuleStat(label: 'Done', value: '47'),
              ],
              requiresLogin: false,
              onTap: () => context.push('/tg'),
            ),
            const SizedBox(height: 28),

            // ── Quick access ──────────────────────────────────────────────
            const Text(
              'Quick Access',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => context.push('/settings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ModuleStat {
  const _ModuleStat({required this.label, required this.value});
  final String label;
  final String value;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.stats,
    required this.onTap,
    this.requiresLogin = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final List<_ModuleStat> stats;
  final VoidCallback onTap;
  final bool requiresLogin;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (requiresLogin) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_outline_rounded,
                              size: 14,
                              color: AppTheme.textHint),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textHint),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFD6DCE6)),
          const SizedBox(height: 14),
          Row(
            children: stats
                .map(
                  (s) => Expanded(
                    child: Column(
                      children: [
                        Text(
                          s.value,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.label,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NeuCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}


