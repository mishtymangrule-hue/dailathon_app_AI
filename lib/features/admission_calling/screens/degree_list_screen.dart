import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../../admission_calling/bloc/admission_calling_bloc.dart';

/// Neumorphic Degree List — entry point of Admission Calling 4-level drill.
class DegreeListScreen extends StatelessWidget {
  const DegreeListScreen({super.key});

  static const _degrees = [
    {'id': '1', 'name': 'B.Tech',  'icon': '🎓', 'total': 150, 'done': 122, 'pending': 28},
    {'id': '2', 'name': 'BCA',    'icon': '💻', 'total': 120, 'done': 105, 'pending': 15},
    {'id': '3', 'name': 'MBA',    'icon': '📊', 'total': 80,  'done': 72,  'pending': 8},
    {'id': '4', 'name': 'B.Sc',   'icon': '🔬', 'total': 200, 'done': 158, 'pending': 42},
    {'id': '5', 'name': 'M.Tech', 'icon': '⚙️', 'total': 60,  'done': 48,  'pending': 12},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Admission Calling'),
        elevation: 0,
      ),
      body: BlocBuilder<AdmissionCallingBloc, AdmissionCallingState>(
        builder: (_, state) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: _degrees.length,
            itemBuilder: (ctx, i) {
              final d = _degrees[i];
              final total = d['total'] as int;
              final done  = d['done']  as int;
              final pending = d['pending'] as int;
              final pct = done / total;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NeuCard(
                  onTap: () => ctx.push(
                    '/admission/${d['id']}/responses',
                    extra: {'degreeName': d['name']},
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            d['icon'] as String,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['name'] as String,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$total students',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NeuBadge(
                            label: '$pending pending',
                            color: pending > 20
                                ? AppTheme.catNotInterested
                                : AppTheme.catFollowUp,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: NeuProgressBar(
                              value: pct,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(pct * 100).round()}%',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
