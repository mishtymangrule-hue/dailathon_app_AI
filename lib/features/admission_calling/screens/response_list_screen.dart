import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ResponseListScreen displays response categories within a degree.
class ResponseListScreen extends StatelessWidget {

  const ResponseListScreen({
    required this.degreeId, Key? key,
    this.degreeName,
  }) : super(key: key);
  final String degreeId;
  final String? degreeName;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(degreeName ?? 'Responses'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _ResponseCategoryTile(
            category: 'Interested',
            count: 42,
            color: Colors.green,
            onTap: () {
              context.push(
                '/admission/$degreeId/responses/interested/sub',
                extra: {
                  'responseName': 'Interested',
                  'responseId': 'interested',
                },
              );
            },
          ),
          _ResponseCategoryTile(
            category: 'Not Interested',
            count: 28,
            color: Colors.red,
            onTap: () {
              context.push(
                '/admission/$degreeId/responses/not_interested/sub',
                extra: {
                  'responseName': 'Not Interested',
                  'responseId': 'not_interested',
                },
              );
            },
          ),
          _ResponseCategoryTile(
            category: 'Call Back',
            count: 15,
            color: Colors.orange,
            onTap: () {
              context.push(
                '/admission/$degreeId/responses/callback/sub',
                extra: {
                  'responseName': 'Call Back',
                  'responseId': 'callback',
                },
              );
            },
          ),
          _ResponseCategoryTile(
            category: 'Not Reachable',
            count: 8,
            color: Colors.grey,
            onTap: () {
              context.push(
                '/admission/$degreeId/responses/unreachable/sub',
                extra: {
                  'responseName': 'Not Reachable',
                  'responseId': 'unreachable',
                },
              );
            },
          ),
        ],
      ),
    );
}

/// Response category tile.
class _ResponseCategoryTile extends StatelessWidget {

  const _ResponseCategoryTile({
    required this.category,
    required this.count,
    required this.color,
    required this.onTap,
  });
  final String category;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(
                  Icons.category,
                  color: color,
                ),
              ),
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
