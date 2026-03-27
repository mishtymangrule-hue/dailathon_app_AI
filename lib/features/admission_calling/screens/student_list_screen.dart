import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../admission_calling/bloc/admission_calling_bloc.dart';

/// StudentListScreen displays students with pagination, search, and actions.
class StudentListScreen extends StatefulWidget {

  const StudentListScreen({
    required this.degreeId, required this.responseId, required this.subResponseId, Key? key,
    this.subResponseName,
  }) : super(key: key);
  final String degreeId;
  final String responseId;
  final String subResponseId;
  final String? subResponseName;

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _students = _generateMockStudents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more when reaching end
      _loadMore();
    }
  }

  void _loadMore() {
    // TODO: Load more students via Bloc
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading more students...')),
    );
  }

  List<Map<String, dynamic>> _generateMockStudents() => List.generate(
      25,
      (index) => {
        'id': '$index',
        'name': 'Student ${index + 1}',
        'phone': '+91 ${9000000000 + index}',
        'email': 'student${index + 1}@example.com',
        'lastCall': DateTime.now().subtract(Duration(days: index % 7)),
        'lastNote': 'Follow up soon',
        'visited': index % 3 == 0,
        'documentsCollected': index % 2 == 0,
      },
    );

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(widget.subResponseName ?? 'Students'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Student List
          Expanded(
            child: BlocBuilder<AdmissionCallingBloc, AdmissionCallingState>(
              builder: (context, state) {
                var filteredStudents = _students;
                if (_searchController.text.isNotEmpty) {
                  filteredStudents = _students
                      .where(
                        (s) =>
                            s['name']
                                .toString()
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase()) ||
                            s['phone']
                                .toString()
                                .contains(_searchController.text),
                      )
                      .toList();
                }

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _StudentTile(
                      student: student,
                      onTap: () {
                        _showStudentDetail(context, student);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

  void _showStudentDetail(BuildContext context, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          student['name'][0].toUpperCase(),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'],
                              style: Theme.of(ctx).textTheme.titleLarge,
                            ),
                            Text(
                              student['phone'],
                              style: Theme.of(ctx).textTheme.bodyMedium,
                            ),
                            Text(
                              student['email'],
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status Badges
                  Wrap(
                    spacing: 8,
                    children: [
                      if (student['visited'])
                        Chip(
                          avatar: const Icon(Icons.check),
                          label: const Text('Visited'),
                          backgroundColor: Colors.green.shade100,
                        ),
                      if (student['documentsCollected'])
                        Chip(
                          avatar: const Icon(Icons.folder),
                          label: const Text('Documents'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Last Interaction
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Interaction',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _formatDateTime(student['lastCall']),
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Note',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        student['lastNote'],
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Notes Input
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Add notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const Divider(),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AdmissionCallingBloc>().add(
                            StudentCalled(studentId: student['id']),
                          );
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call Now'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // TODO: Send SMS
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Send SMS'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // TODO: Open WhatsApp
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('WhatsApp'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Student list tile.
class _StudentTile extends StatelessWidget {

  const _StudentTile({
    required this.student,
    required this.onTap,
  });
  final Map<String, dynamic> student;
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
                child: Text(student['name'][0].toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      student['phone'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    Text(
                      'Last call: 2d ago',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: () {
                  // TODO: Quick call
                },
              ),
            ],
          ),
        ),
      ),
    );
}
