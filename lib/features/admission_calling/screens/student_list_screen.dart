import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../../admission_calling/bloc/admission_calling_bloc.dart';

/// Neumorphic Student List — step 4, full card with Call/WhatsApp/SMS actions.
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({
    required this.degreeId,
    required this.responseId,
    required this.subResponseId,
    this.subResponseName,
    super.key,
  });
  final String degreeId;
  final String responseId;
  final String subResponseId;
  final String? subResponseName;

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late List<Map<String, dynamic>> _students;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _students = _mockStudents();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100) {
      // TODO: trigger BLoC pagination
    }
  }

  List<Map<String, dynamic>> _mockStudents() => List.generate(
        20,
        (i) => {
          'id': '$i',
          'name': [
            'Arjun Sharma', 'Priya Patel', 'Rahul Verma', 'Sneha Iyer',
            'Karan Singh', 'Neha Gupta', 'Vivek Nair', 'Pooja Mehta',
            'Amit Kumar', 'Ria Das',
          ][i % 10],
          'phone': '+91 ${9876540000 + i}',
          'course': ['B.Tech CSE', 'BCA', 'MBA', 'B.Sc IT'][i % 4],
          'lastCall': DateTime.now().subtract(Duration(days: i % 7, hours: i % 24)),
          'lastNote': i % 3 == 0 ? 'Interested, pending docs' : 'Called, no answer',
          'visited': i % 3 == 0,
          'docs': i % 2 == 0,
        },
      );

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _students;
    final q = _query.toLowerCase();
    return _students
        .where((s) =>
            (s['name'] as String).toLowerCase().contains(q) ||
            (s['phone'] as String).contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Text(widget.subResponseName ?? 'Students'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: NeuTextField(
              controller: _searchCtrl,
              hintText: 'Search by name or number ...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.textHint, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textHint, size: 18),
                    )
                  : null,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // ── Student count ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} students',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<AdmissionCallingBloc, AdmissionCallingState>(
              builder: (_, __) {
                final list = _filtered;
                if (list.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 64, color: AppTheme.textHint),
                        SizedBox(height: 12),
                        Text(
                          'No students found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentCard(
                      student: list[i],
                      onCall: () => _call(list[i]),
                      onWhatsApp: () => _whatsApp(list[i]),
                      onSms: () => _sms(list[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(Map<String, dynamic> s) async {
    context.read<AdmissionCallingBloc>().add(StudentCalled(studentId: s['id']));
    final uri = Uri(scheme: 'tel', path: (s['phone'] as String).replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp(Map<String, dynamic> s) async {
    final phone = (s['phone'] as String).replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sms(Map<String, dynamic> s) async {
    final uri = Uri(scheme: 'sms', path: (s['phone'] as String).replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onCall,
    required this.onWhatsApp,
    required this.onSms,
  });

  final Map<String, dynamic> student;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;

  @override
  Widget build(BuildContext context) {
    final initials = (student['name'] as String)
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${student['phone']}  ·  ${student['course']}',
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
          const SizedBox(height: 10),

          // ── Status row ────────────────────────────────────────────────
          Row(
            children: [
              _StatusDot(
                label: 'Visited',
                active: student['visited'] as bool,
                activeColor: AppTheme.catInterested,
              ),
              const SizedBox(width: 10),
              _StatusDot(
                label: 'Docs',
                active: student['docs'] as bool,
                activeColor: AppTheme.primary,
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded,
                  size: 12, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                _StudentListScreenState._ago(
                    student['lastCall'] as DateTime),
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          // ── Last note ─────────────────────────────────────────────────
          if ((student['lastNote'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              student['lastNote'] as String,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFD6DCE6)),
          const SizedBox(height: 10),

          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: AppTheme.catInterested,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: onWhatsApp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: AppTheme.info,
                  onTap: onSms,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.label,
    required this.active,
    required this.activeColor,
  });
  final String label;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? activeColor : AppTheme.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ${active ? '✓' : '○'}',
            style: TextStyle(
              color: active ? activeColor : AppTheme.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

