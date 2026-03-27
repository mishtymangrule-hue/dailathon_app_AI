import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../../call_log/bloc/call_log_bloc.dart';

/// Neumorphic Recents / Call Log screen with 4-tab filter.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallLogBloc>().add(const CallLogRequested());
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final type = const ['all', 'missed', 'outgoing', 'incoming'][_tabController.index];
    context.read<CallLogBloc>().add(CallLogTypeFiltered(type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Recents'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                boxShadow: AppTheme.insetShadow(),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: AppTheme.raisedShadow(distance: 3, blur: 8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Missed'),
                  Tab(text: 'Out'),
                  Tab(text: 'In'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<CallLogBloc, CallLogState>(
        builder: (_, state) {
          if (state is CallLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CallLogLoaded) {
            final log = state.entries;
            if (log.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 64, color: AppTheme.textHint),
                    SizedBox(height: 12),
                    Text(
                      'No call history',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: log.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CallLogTile(
                  entry: log[i],
                  onDelete: () => context
                      .read<CallLogBloc>()
                      .add(CallLogEntryDeleted(log[i].id)),
                ),
              ),
            );
          }
          return const Center(
              child: Text('Error loading call log',
                  style: TextStyle(color: AppTheme.textSecondary)));
        },
      ),
    );
  }
}

class _CallLogTile extends StatelessWidget {
  const _CallLogTile({required this.entry, required this.onDelete});
  final dynamic entry;
  final VoidCallback onDelete;

  static IconData _icon(int type) => const {
        1: Icons.call_received_rounded,
        2: Icons.call_made_rounded,
        3: Icons.call_missed_rounded,
      }[type] ??
      Icons.call_rounded;

  static Color _color(int type) => const {
        1: AppTheme.catInterested,
        2: AppTheme.primary,
        3: AppTheme.catNotInterested,
      }[type] ??
      AppTheme.textSecondary;

  static String _time(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(entry.type as int);
    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(entry.type as int), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (entry.name ?? entry.phoneNumber) as String,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entry.phoneNumber as String,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _time(entry.timestamp as int),
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 11,
                ),
              ),
              if ((entry.duration as int) > 0)
                Text(
                  '${(entry.duration as int) ~/ 60}:${((entry.duration as int) % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

