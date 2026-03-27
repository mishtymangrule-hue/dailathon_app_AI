import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';

/// Neumorphic Response Categories — step 2 of Admission Calling drill.
class ResponseListScreen extends StatelessWidget {
  const ResponseListScreen({
    required this.degreeId,
    this.degreeName,
    super.key,
  });
  final String degreeId;
  final String? degreeName;

  static const _categories = [
    {
      'id': 'interested',
      'name': 'Interested',
      'icon': Icons.thumb_up_alt_rounded,
      'color': AppTheme.catInterested,
      'count': 42,
    },
    {
      'id': 'followup',
      'name': 'Follow Up / Call Back',
      'icon': Icons.schedule_rounded,
      'color': AppTheme.catFollowUp,
      'count': 35,
    },
    {
      'id': 'not_interested',
      'name': 'Not Interested',
      'icon': Icons.thumb_down_alt_rounded,
      'color': AppTheme.catNotInterested,
      'count': 28,
    },
    {
      'id': 'unreachable',
      'name': 'Not Reachable',
      'icon': Icons.phone_disabled_rounded,
      'color': AppTheme.catNotReachable,
      'count': 18,
    },
    {
      'id': 'no_response',
      'name': 'No Response',
      'icon': Icons.do_not_disturb_alt_rounded,
      'color': AppTheme.catNoResponse,
      'count': 24,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final total = _categories.fold<int>(
        0, (sum, c) => sum + (c['count'] as int));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Text(degreeName ?? 'Responses'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final count = cat['count'] as int;
          final color = cat['color'] as Color;
          final pct = total == 0 ? 0.0 : count / total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeuCard(
              onTap: () => ctx.push(
                '/admission/$degreeId/responses/${cat['id']}/sub',
                extra: {
                  'responseName': cat['name'],
                  'responseId': cat['id'],
                },
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat['icon'] as IconData,
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        NeuProgressBar(
                          value: pct,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeuBadge(label: '$count', color: color),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textHint, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

