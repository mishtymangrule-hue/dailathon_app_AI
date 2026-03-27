import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';

/// Neumorphic Sub-response list — step 3 of Admission Calling drill.
class SubResponseListScreen extends StatelessWidget {
  const SubResponseListScreen({
    required this.degreeId,
    required this.responseId,
    this.responseName,
    super.key,
  });
  final String degreeId;
  final String responseId;
  final String? responseName;

  @override
  Widget build(BuildContext context) {
    final items = _getSubResponses(responseId);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Text(responseName ?? 'Sub-Categories'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeuCard(
              onTap: () => ctx.push(
                '/admission/$degreeId/responses/$responseId/${item['id']}/students',
                extra: {'subResponseName': item['name']},
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['count']} students',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuBadge(
                    label: '${item['count']}',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
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

  static List<Map<String, dynamic>> _getSubResponses(String id) {
    switch (id) {
      case 'interested':
        return [
          {'id': 'docs_submitted', 'name': 'Documents Submitted', 'count': 15, 'icon': Icons.assignment_turned_in_rounded},
          {'id': 'docs_pending',   'name': 'Documents Pending',   'count': 18, 'icon': Icons.assignment_outlined},
          {'id': 'fee_paid',       'name': 'Fee Paid',            'count': 9,  'icon': Icons.payment_rounded},
          {'id': 'visit_scheduled','name': 'Visit Scheduled',     'count': 6,  'icon': Icons.event_rounded},
        ];
      case 'followup':
        return [
          {'id': 'same_day',  'name': 'Same Day',  'count': 5,  'icon': Icons.access_time_rounded},
          {'id': 'next_day',  'name': 'Next Day',  'count': 7,  'icon': Icons.calendar_today_rounded},
          {'id': 'scheduled', 'name': 'Scheduled', 'count': 3,  'icon': Icons.event_available_rounded},
        ];
      case 'not_interested':
        return [
          {'id': 'fee_issue',  'name': 'Fee Issue',        'count': 12, 'icon': Icons.money_off_rounded},
          {'id': 'location',   'name': 'Location Problem', 'count': 8,  'icon': Icons.location_off_rounded},
          {'id': 'other_clg',  'name': 'Joined Elsewhere', 'count': 8,  'icon': Icons.school_rounded},
        ];
      default:
        return [
          {'id': 'all', 'name': 'All', 'count': 0, 'icon': Icons.list_rounded},
        ];
    }
  }
}

