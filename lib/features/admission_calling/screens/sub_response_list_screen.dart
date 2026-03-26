import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// SubResponseListScreen displays sub-categories within a response.
class SubResponseListScreen extends StatelessWidget {

  const SubResponseListScreen({
    Key? key,
    required this.degreeId,
    required this.responseId,
    this.responseName,
  }) : super(key: key);
  final String degreeId;
  final String responseId;
  final String? responseName;

  @override
  Widget build(BuildContext context) {
    final mockSubResponses = _getMockSubResponses(responseId);

    return Scaffold(
      appBar: AppBar(
        title: Text(responseName ?? 'Sub-Categories'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: mockSubResponses.length,
        itemBuilder: (context, index) {
          final subResponse = mockSubResponses[index];
          return _SubResponseTile(
            category: subResponse['name'] as String,
            count: subResponse['count'] as int,
            icon: subResponse['icon'] as IconData,
            onTap: () {
              context.push(
                '/admission/$degreeId/responses/$responseId/${subResponse['id']}/students',
                extra: {
                  'subResponseName': subResponse['name'],
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getMockSubResponses(String responseId) {
    switch (responseId) {
      case 'interested':
        return [
          {
            'id': 'docs_submitted',
            'name': 'Documents Submitted',
            'count': 15,
            'icon': Icons.assignment_turned_in,
          },
          {
            'id': 'docs_pending',
            'name': 'Documents Pending',
            'count': 18,
            'icon': Icons.assignment,
          },
          {
            'id': 'fee_paid',
            'name': 'Fee Paid',
            'count': 9,
            'icon': Icons.payment,
          },
        ];
      case 'callback':
        return [
          {
            'id': 'same_day',
            'name': 'Same Day',
            'count': 5,
            'icon': Icons.access_time,
          },
          {
            'id': 'next_day',
            'name': 'Next Day',
            'count': 7,
            'icon': Icons.calendar_today,
          },
          {
            'id': 'scheduled',
            'name': 'Scheduled',
            'count': 3,
            'icon': Icons.event,
          },
        ];
      default:
        return [
          {
            'id': 'default',
            'name': 'All',
            'count': 0,
            'icon': Icons.list,
          },
        ];
    }
  }
}

/// Sub-response category tile.
class _SubResponseTile extends StatelessWidget {

  const _SubResponseTile({
    required this.category,
    required this.count,
    required this.icon,
    required this.onTap,
  });
  final String category;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$count students',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
}
